import 'dart:convert';
import 'dart:io';

import 'package:english_universe/screens/sense_course_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 에셋 읽기가 실제 비동기로 돈다 — pumpAndSettle 대신 실제 시간으로 기다린다(일본어앱 시험과 같음).
Future<void> settle(WidgetTester t, Finder until) async {
  for (var i = 0; i < 100 && until.evaluate().isEmpty; i++) {
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await t.pump();
  }
  await t.pump(const Duration(milliseconds: 300));
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('과정 데이터 — 10급, 급마다 외울 대화 + 참고, 색 번호가 영어·한국어에서 같다', () {
    final d = json.decode(File('assets/data/grammar/sense_course.json').readAsStringSync()) as Map<String, dynamic>;
    final levels = (d['levels'] as List).cast<Map<String, dynamic>>();
    expect(levels, hasLength(10));
    final mark = RegExp(r'\{([^|}]+)\|(\d+)\}');
    for (final lv in levels) {
      final ls = (lv['lessons'] as List).cast<Map<String, dynamic>>();
      expect(ls.map((l) => l['kind']), ['memorize', 'ref'], reason: lv['id'] as String);
      final talk = (ls[0]['sentences'] as List).cast<Map<String, dynamic>>();
      expect(talk.length, inInclusiveRange(8, 12));
      for (final s in talk) {
        Set<String> nums(String x) => mark.allMatches(x).map((m) => m.group(2)!).toSet();
        expect(nums(s['en'] as String), nums(s['ko'] as String), reason: s['en'] as String);
      }
      expect((ls[1]['points'] as List), isNotEmpty);
    }
  });

  for (final w in const [320.0, 900.0]) {
    testWidgets('언어감각 목록 폭 $w — L1 은 외울 대화 1회 + 참고, 넘침 없음', (t) async {
      t.view.physicalSize = Size(w, 6000);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(const MaterialApp(home: SenseCourseScreen()));
      await settle(t, find.text('L1  관사 익히기 (a · the)'));
      expect(t.takeException(), isNull);
      expect(find.byKey(const ValueKey('sense-L1-talk')), findsOneWidget);
      expect(find.byKey(const ValueKey('sense-L1-ref')), findsOneWidget);
      expect(find.byKey(const ValueKey('sense-L10-talk')), findsOneWidget);
      expect(find.text('0/10회 마침'), findsOneWidget);
    });
  }

  testWidgets('외울 대화 — 영상 자리·안내, 색 표시가 글자에 안 남음, 마침 → 참고 건너뛰고 L2', (t) async {
    t.view.physicalSize = const Size(320, 3000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(const MaterialApp(home: SenseLessonScreen(index: 0)));
    await settle(t, find.byKey(const ValueKey('sense-finish')));
    expect(t.takeException(), isNull);
    expect(find.byKey(const ValueKey('memorize-video')), findsOneWidget);
    expect(find.text('영상 준비 중'), findsOneWidget);
    expect(find.textContaining('{', findRichText: true), findsNothing);
    expect(plainMarked('I\'ll get {a|1} coffee.'), 'I\'ll get a coffee.');
    await t.tap(find.byKey(const ValueKey('sense-finish')));
    await t.pump(const Duration(milliseconds: 500));
    await t.pump(const Duration(milliseconds: 500));
    expect(await SenseCourse.done(), contains('L1-talk'));
    await settle(t, find.textContaining('Meet me', findRichText: true));
    expect(find.textContaining('Meet me', findRichText: true), findsWidgets);
  });

  testWidgets('참고 — 닫기는 기록 안 함', (t) async {
    t.view.physicalSize = const Size(320, 6000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(const MaterialApp(home: SenseLessonScreen(index: 1)));
    await settle(t, find.text('닫기'));
    expect(t.takeException(), isNull);
    expect(find.textContaining('a / an'), findsWidgets);
    await t.tap(find.byKey(const ValueKey('sense-finish')));
    await t.pump(const Duration(milliseconds: 300));
    expect(await SenseCourse.done(), isNot(contains('L1-ref')));
  });
}
