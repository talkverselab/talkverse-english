import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/l10n.dart';
import '../core/theme.dart';
import '../services/purchase.dart';

/// 이용권 결제 시트(PAYWALL_SPEC §3, 일본어앱 paywall_screen 을 옮김).
/// 스토어 규정: 가격은 스토어 값만, 기간·자동 갱신·해지 방법을 구매 단추 가까이, 평생은 「서비스 운영 기간 동안」,
/// 구매 복원, 미리 고른 상품 없음, 이용약관·개인정보처리방침 링크. iOS 는 App Store 문구만, 안드로이드는 Google Play 문구만.
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  static const terms = 'https://talkverse.uk/terms/';
  static const privacy = 'https://talkverse.uk/talkverse/en/privacy/';

  static Future<void> show(BuildContext context) {
    Purchase.status.value = null;
    if (Purchase.load.value == 'fail') Purchase.reloadProducts();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.washi,
      constraints: const BoxConstraints(maxWidth: 640),
      builder: (_) => const PaywallScreen(),
    );
  }

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  String? _sel; // 미리 고르지 않는다

  static bool get _ios => Platform.isIOS || Platform.isMacOS;

  String _title(Plan p) => switch ((p.bundle, p.months)) {
        (false, 1) => tr('1개월'),
        (false, 3) => tr('3개월'),
        (false, 12) => tr('1년'),
        (false, _) => tr('평생 이용권(서비스 운영 기간 동안)'),
        (true, 12) => tr('종합 패키지 1년 — 모든 언어'),
        (true, _) => tr('종합 패키지 평생 — 모든 언어(서비스 운영 기간 동안)'),
      };

  String _terms(Plan p) => p.lifetime ? tr('한 번 결제 · 자동 갱신 없음') : trf('{0}마다 자동 갱신 · 언제든 해지', [p.months == 12 ? tr('1년') : trf('{0}개월', [p.months])]);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: Purchase.status,
      builder: (c, st, _) {
        if (st == 'done' || st == 'restored') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (c.mounted && Navigator.canPop(c)) Navigator.pop(c);
          });
        }
        final busy = st == 'pending';
        return ValueListenableBuilder<String>(
          valueListenable: Purchase.load,
          builder: (c, load, _) {
            final sel = _sel == null ? null : Purchase.plan(_sel!);
            final selPrice = sel == null ? null : Purchase.price(sel.id);
            return SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 16 + MediaQuery.paddingOf(context).bottom),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text(tr('이용권이 필요한 내용이에요'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.beni)),
                  Text(tr('이용권 선택'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.sumi)),
                  const SizedBox(height: 10),
                  _row(Icons.check_circle, tr('토크버스 커리큘럼 2단계 이상')),
                  _row(Icons.check_circle, tr('주제별 회화 R2~R4 전체')),
                  _row(Icons.check_circle, tr('언어감각 익히기 2급 이상')),
                  _row(Icons.check_circle_outline, tr('커리큘럼 1단계·회화 R0·R1·단어·발음은 계속 무료'), muted: true),
                  const SizedBox(height: 10),
                  if (load == 'fail')
                    _failBox(c)
                  else if (load == 'loading')
                    const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: CircularProgressIndicator()))
                  else ...[
                    Text(tr('영어'), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.sumiLight)),
                    const SizedBox(height: 6),
                    for (final p in Purchase.plans.where((x) => !x.bundle && Purchase.price(x.id) != null)) _planTile(p, busy),
                    const SizedBox(height: 8),
                    Text(tr('종합 패키지 — Talkverse 모든 언어'), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.sumiLight)),
                    const SizedBox(height: 6),
                    for (final p in Purchase.plans.where((x) => x.bundle && Purchase.price(x.id) != null)) _planTile(p, busy),
                    const SizedBox(height: 10),
                    if (st == 'error') Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(tr('결제를 마치지 못했습니다. 다시 시도해 주세요.'), style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700))),
                    if (st == 'nothing') Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(tr('복원할 구매가 없습니다.'), style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700))),
                    if (sel != null && selPrice != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          sel.lifetime
                              ? trf('{0} · {1} · 한 번 결제, 자동 갱신 없음', [_title(sel), selPrice])
                              : trf('{0} · {1} · 기간이 끝나면 같은 가격으로 자동 갱신됩니다. 갱신 24시간 전까지 해지하면 다음 결제가 되지 않습니다.', [_title(sel), selPrice]),
                          style: const TextStyle(fontSize: 12, color: AppColors.sumi, height: 1.45, fontWeight: FontWeight.w600),
                        ),
                      ),
                    FilledButton(
                      key: const Key('paywall-buy'),
                      style: FilledButton.styleFrom(backgroundColor: AppColors.beni, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(54), textStyle: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w900), shape: const StadiumBorder()),
                      onPressed: busy || sel == null || selPrice == null ? null : () => Purchase.buy(sel.id),
                      child: busy
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                          : Text(sel == null || selPrice == null ? tr('이용권을 골라 주세요') : '${tr('구매')} · $selPrice'),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _ios
                          ? tr('구독 해지: 아이폰 설정 → 내 이름(Apple ID) → 구독 → Talkverse → 구독 취소')
                          : tr('구독 해지: Google Play → 프로필 → 결제 및 정기 결제 → 정기 결제 → Talkverse → 해지'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11.5, color: AppColors.sumiLight, height: 1.4),
                    ),
                  ],
                  const SizedBox(height: 6),
                  OutlinedButton(
                    key: const Key('paywall-restore'),
                    style: OutlinedButton.styleFrom(shape: const StadiumBorder(), side: const BorderSide(color: AppColors.line)),
                    onPressed: busy ? null : () => Purchase.restore(),
                    child: Text(tr('이전 구매 복원'), style: const TextStyle(color: AppColors.sumi, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _ios
                        ? tr('결제는 App Store 에서 처리됩니다. 표시 가격은 스토어 가격을 따르며 세금이 포함될 수 있습니다.')
                        : tr('결제는 Google Play 에서 처리됩니다. 표시 가격은 스토어 가격을 따르며 세금이 포함될 수 있습니다.'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11, color: AppColors.muted, height: 1.4),
                  ),
                  Wrap(alignment: WrapAlignment.center, children: [
                    TextButton(onPressed: () => _open(PaywallScreen.terms), child: Text(tr('이용약관'), style: const TextStyle(fontSize: 12, color: AppColors.ai))),
                    TextButton(onPressed: () => _open(PaywallScreen.privacy), child: Text(tr('개인정보처리방침'), style: const TextStyle(fontSize: 12, color: AppColors.ai))),
                  ]),
                ]),
              ),
            );
          },
        );
      },
    );
  }

  static Future<void> _open(String url) => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  // 상품을 못 불러오면 끝없이 돌지 않고 다시 시도·닫기(§3)
  Widget _failBox(BuildContext c) => Container(
        key: const Key('paywall-fail'),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.washiDeep, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.line)),
        child: Column(children: [
          Text(tr('스토어에 연결하지 못했어요. 잠시 뒤 다시 시도해 주세요.'), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.sumi)),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            TextButton(onPressed: () => Navigator.pop(c), child: Text(tr('닫기'))),
            const SizedBox(width: 8),
            FilledButton(onPressed: Purchase.reloadProducts, child: Text(tr('다시 시도'))),
          ]),
        ]),
      );

  Widget _planTile(Plan p, bool busy) {
    final on = _sel == p.id;
    final price = Purchase.price(p.id)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Semantics(
        selected: on,
        button: true,
        label: '${_title(p)} $price ${_terms(p)}',
        child: InkWell(
          key: Key('plan-${p.id}'),
          borderRadius: BorderRadius.circular(12),
          onTap: busy ? null : () => setState(() => _sel = p.id),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: on ? AppColors.beni.withValues(alpha: 0.08) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: on ? AppColors.beni : AppColors.line, width: on ? 2 : 1),
            ),
            child: Row(children: [
              Icon(on ? Icons.radio_button_checked : Icons.radio_button_off, size: 20, color: on ? AppColors.beni : AppColors.muted),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_title(p), style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.sumi)),
                  Text(_terms(p), style: const TextStyle(fontSize: 11.5, color: AppColors.sumiLight)),
                ]),
              ),
              Text(price, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.sumi)),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _row(IconData icon, String text, {bool muted = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 18, color: muted ? AppColors.muted : AppColors.matcha),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(fontSize: 13.5, height: 1.35, color: muted ? AppColors.muted : AppColors.sumi, fontWeight: FontWeight.w600))),
        ]),
      );
}

/// 잠긴 곳에 붙는 자물쇠 표시.
class LockBadge extends StatelessWidget {
  const LockBadge({super.key});
  @override
  Widget build(BuildContext context) => const Icon(Icons.lock_outline, size: 18, color: AppColors.muted, key: Key('lock'));
}
