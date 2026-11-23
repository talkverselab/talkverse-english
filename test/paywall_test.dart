import 'dart:convert';

import 'package:english_universe/screens/dialogue_screen.dart';
import 'package:english_universe/screens/paywall_screen.dart';
import 'package:english_universe/services/curriculum_plan.dart';
import 'package:english_universe/services/dialogue_service.dart';
import 'package:english_universe/services/entitlement.dart';
import 'package:english_universe/services/purchase.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 이용권 잠금 경계(PAYWALL_SPEC §2·§5): 1단계 열림 · 2단계 잠김 · 이용권 있으면 열림.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Purchase.debugReset();
    CurriculumPlan.instance.stages = CurriculumPlan.parse({
      'stages': [
        {'n': 1, 'dialogueIds': ['a'], 'free': true},
        {'n': 2, 'dialogueIds': ['b'], 'free': false},
        {'n': 3, 'dialogueIds': ['c']}, // free 없음 → 1단계가 아니면 잠김
      ]
    });
    CurriculumPlan.instance.freeSenseLevels = 1;
  });
  tearDown(() {
    Purchase.debugReset();
    CurriculumPlan.instance.debugReset();
  });

  test('이용권 없음 — 1단계·R0·R1·언어감각 1급만 열림', () {
    expect(Entitlement.premium, isFalse);
    expect(Entitlement.stageOpen('1'), isTrue);
    expect(Entitlement.stageOpen('2'), isFalse);
    expect(Entitlement.stageOpen('3'), isFalse);
    expect((Entitlement.regionOpen('R0'), Entitlement.regionOpen('R1'), Entitlement.regionOpen('R2'), Entitlement.regionOpen('R4')), (true, true, false, false));
    expect((Entitlement.senseOpen(0), Entitlement.senseOpen(1)), (true, false));
  });

  test('이용권(영어·종합, 기한 안) 있으면 모두 열림 · 기한 지난 구독은 닫힘 · 다른 언어 상품은 무관', () async {
    await Purchase.grant('lang_en_1y', DateTime.now().millisecondsSinceEpoch);
    expect(Entitlement.stageOpen('2') && Entitlement.regionOpen('R3') && Entitlement.senseOpen(5), isTrue);
    Purchase.owned.value = {'lang_en_1m': DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch};
    expect(Entitlement.premium, isFalse);
    Purchase.owned.value = {'lang_ja_life': 0};
    expect(Entitlement.premium, isFalse);
    await Purchase.grant('all_life', null);
    expect(Entitlement.premium, isTrue);
    // 종합 이용권은 전 언어 공통 키에도
    final p = await SharedPreferences.getInstance();
    expect((jsonDecode(p.getString(Purchase.allKey)!) as Map).containsKey('all_life'), isTrue);
    expect(p.getString('en_entitlement_v1'), isNotNull);
  });

  test('구독 기한 = 구매 시각 + 기간 + 3일, 평생 = 0', () {
    final t = DateTime(2026, 11, 23, 10).millisecondsSinceEpoch;
    expect(Purchase.expiry('lang_en_1m', t), DateTime(2026, 12, 26, 10).millisecondsSinceEpoch);
    expect(Purchase.expiry('lang_en_life', t), 0);
  });

  testWidgets('R2 편은 자물쇠 화면 → 「이용권 보기」 결제 시트(상품을 못 받으면 다시 시도·닫기)', (t) async {
    final d = Dialogue.fromJson({
      'id': 'zz_r2', 'region': 'R2', 'island': 'life', 'title': 'Locked',
      'turns': [{'num': 1, 'speaker': 'A', 'tl': 'Hello there.', 'ko': '안녕.'}],
    });
    await t.pumpWidget(MaterialApp(home: DialogueScreen(dialogue: d)));
    await t.pump();
    expect(find.byKey(const Key('unlock')), findsOneWidget);
    expect(find.text('Hello there.'), findsNothing);
    Purchase.load.value = 'fail';
    await t.tap(find.byKey(const Key('unlock')));
    await t.pumpAndSettle();
    expect(find.byType(PaywallScreen), findsOneWidget);
    expect(find.byKey(const Key('paywall-fail')), findsOneWidget);
    expect(find.byKey(const Key('paywall-restore')), findsOneWidget);
    expect(find.text('이용약관'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
