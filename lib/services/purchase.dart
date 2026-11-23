import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/prefs.dart';

/// 판매 상품 하나 — 가격은 스토어가 정한다(코드에 원화·할인을 두지 않음, PAYWALL_SPEC §3).
class Plan {
  final String id;
  final int months; // 0 = 평생
  final bool bundle;
  const Plan(this.id, this.months, {this.bundle = false});
  bool get lifetime => months == 0;
}

/// 앱 안 결제(이용권) — 결제는 스토어(iOS StoreKit · Android Play Billing), 결과는 기기에 저장(PAYWALL_SPEC §4).
/// 일본어앱 lib/services/purchase.dart 를 옮기고 계정 연결(로그인)만 뺐다 — 영어앱엔 로그인이 없다. 서버 검증은 나중에 uk.
/// - 언어 상품 `lang_en_1m`·`_3m`·`_1y`(자동 갱신 구독)·`_life`(평생), 종합 `all_1y`·`all_life`.
/// - 구독은 「구매 시각 + 기간 + 3일」까지 열어 둔다. 자동 갱신되면 스토어가 새 거래를 보내 기한이 늘어난다.
/// - 저장: Prefs `entitlement_v1`(= `en_entitlement_v1`), 종합 상품은 22개 언어 공통 `all_entitlement_v1` 에도.
class Purchase {
  Purchase._();

  static const lang = 'en';
  static const plans = [
    Plan('lang_en_1m', 1),
    Plan('lang_en_3m', 3),
    Plan('lang_en_1y', 12),
    Plan('lang_en_life', 0),
    Plan('all_1y', 12, bundle: true),
    Plan('all_life', 0, bundle: true),
  ];
  static const _key = 'entitlement_v1';
  static const allKey = 'all_entitlement_v1'; // 접두 없음 — 통합 앱의 모든 언어가 같이 본다

  /// 상품 ID → 만료 시각(ms, 평생이면 0)
  static final owned = ValueNotifier<Map<String, int>>(const {});
  static final products = ValueNotifier<Map<String, ProductDetails>>(const {});
  /// 상품 불러오기: 'loading' · 'ok' · 'fail'(스토어 연결 실패 — 결제 화면은 「잠시 뒤 다시 시도」).
  static final load = ValueNotifier<String>('loading');
  /// 구매 진행: null · 'pending' · 'error' · 'done' · 'restored' · 'nothing'
  static final status = ValueNotifier<String?>(null);
  static StreamSubscription<List<PurchaseDetails>>? _sub;

  /// 통합 앱이면 false — 통합 앱의 공용 결제가 스트림 하나를 듣고 [onPurchaseUpdates] 로 넘긴다(일본어앱과 같은 연결).
  static bool ownStream = true;
  static bool _restoring = false, _restoredAny = false;

  static Plan? plan(String id) => plans.where((p) => p.id == id).firstOrNull;

  /// 이 언어를 열 수 있는가 — `lang_en_*` 또는 `all_*` 중 기한이 남은 것이 있으면.
  static bool get active {
    final now = DateTime.now().millisecondsSinceEpoch;
    return owned.value.entries.any((e) => (e.key.startsWith('lang_${lang}_') || e.key.startsWith('all_')) && (e.value == 0 || e.value > now));
  }

  static Map<String, int> _read(String? raw) {
    if (raw == null) return {};
    try {
      return (jsonDecode(raw) as Map).map((k, v) => MapEntry('$k', (v as num).toInt()));
    } catch (_) {
      return {};
    }
  }

  /// 기기 저장을 읽고(종합 이용권 공통 키 포함), 스토어 상품·스트림을 연다. 앱 시작 때 한 번.
  static Future<void> configure() async {
    final p = await Prefs.getInstance();
    final raw = await SharedPreferences.getInstance();
    owned.value = {..._read(raw.getString(allKey)), ..._read(p.getString(_key))};
    if (kIsWeb || !(Platform.isIOS || Platform.isAndroid)) {
      load.value = 'fail';
      return;
    }
    if (ownStream) _sub ??= InAppPurchase.instance.purchaseStream.listen(onPurchaseUpdates, onError: (_) => status.value = 'error');
    await reloadProducts();
    // 시작 때 복원 조회는 안드로이드만(조용히). iOS 는 restorePurchases 가 Apple ID 암호 창을 띄울 수 있어
    // 미완료 거래 자동 수신(purchaseStream) + 사용자가 누르는 「구매 복원」 단추만(uk 기준 통일 2026-11-23).
    if (Platform.isAndroid) {
      try {
        await InAppPurchase.instance.restorePurchases();
      } catch (_) {}
    }
  }

  /// 상품 정보를 다시 받는다(결제 화면의 「다시 시도」). 끝없이 기다리지 않게 12초 제한.
  static Future<void> reloadProducts() async {
    load.value = 'loading';
    try {
      if (!await InAppPurchase.instance.isAvailable().timeout(const Duration(seconds: 8))) {
        load.value = 'fail';
        return;
      }
      final r = await InAppPurchase.instance.queryProductDetails({for (final x in plans) x.id}).timeout(const Duration(seconds: 12));
      products.value = {for (final d in r.productDetails) d.id: d};
      load.value = products.value.isEmpty ? 'fail' : 'ok';
    } catch (_) {
      load.value = 'fail';
    }
  }

  /// 스토어 표시 가격. 상품을 못 받았으면 null.
  static String? price(String id) => products.value[id]?.price;

  static Future<bool> buy(String id) async {
    final d = products.value[id];
    if (d == null) {
      status.value = 'error';
      return false;
    }
    status.value = 'pending';
    return InAppPurchase.instance.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: d));
  }

  /// 구매 복원(스토어 심사 요구). 결과는 [status] 로: 'restored' 또는 'nothing'.
  static Future<void> restore() async {
    _restoring = true;
    _restoredAny = false;
    status.value = 'pending';
    try {
      await InAppPurchase.instance.restorePurchases();
    } catch (_) {}
    // 복원할 것이 없으면 스트림에 아무것도 안 오는 플랫폼이 있다 — 잠시 뒤 결과를 정한다
    Future.delayed(const Duration(seconds: 4), () {
      if (_restoring) {
        _restoring = false;
        status.value = _restoredAny ? 'restored' : 'nothing';
      }
    });
  }

  static String? _known(String id) => id.startsWith('lang_${lang}_') || id.startsWith('all_') ? id : null;

  /// 구매 갱신 처리. 단독 앱은 스토어 스트림이 직접 부르고, 통합 앱은 공용 결제가 이 언어 상품(lang_en_*·all_*)만 골라 부른다.
  static Future<void> onPurchaseUpdates(List<PurchaseDetails> list) async {
    for (final pd in list) {
      final id = _known(pd.productID);
      switch (pd.status) {
        case PurchaseStatus.pending:
          if (!_restoring) status.value = 'pending';
        case PurchaseStatus.error:
          status.value = 'error';
        case PurchaseStatus.canceled:
          status.value = null;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (id != null) {
            await grant(id, int.tryParse(pd.transactionDate ?? ''));
            _restoredAny = true;
            if (status.value == 'pending' || _restoring) status.value = pd.status == PurchaseStatus.restored ? 'restored' : 'done';
            _restoring = false;
          }
      }
      if (ownStream && pd.pendingCompletePurchase) await InAppPurchase.instance.completePurchase(pd);
    }
  }

  static int expiry(String id, int? txMs) {
    final months = plan(id)?.months ?? (id.endsWith('_1m') ? 1 : id.endsWith('_3m') ? 3 : id.endsWith('_1y') ? 12 : 0);
    if (months == 0) return 0;
    final t = DateTime.fromMillisecondsSinceEpoch(txMs ?? DateTime.now().millisecondsSinceEpoch);
    return DateTime(t.year, t.month + months, t.day + 3, t.hour, t.minute).millisecondsSinceEpoch;
  }

  /// 이용권 기록(기한이 더 긴 것이 있으면 유지).
  @visibleForTesting
  static Future<void> grant(String id, int? txMs) async {
    final exp = expiry(id, txMs);
    final cur = owned.value[id];
    final keep = cur != null && (cur == 0 || (exp != 0 && cur > exp));
    if (!keep) owned.value = {...owned.value, id: exp};
    final p = await Prefs.getInstance();
    await p.setString(_key, jsonEncode(owned.value));
    if (id.startsWith('all_')) {
      final raw = await SharedPreferences.getInstance();
      final all = _read(raw.getString(allKey))..[id] = owned.value[id]!;
      await raw.setString(allKey, jsonEncode(all));
    }
  }

  @visibleForTesting
  static void debugReset() {
    owned.value = const {};
    products.value = const {};
    load.value = 'loading';
    status.value = null;
  }
}
