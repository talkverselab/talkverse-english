import 'package:english_universe/core/theme.dart';
import 'package:english_universe/toeic/toeic_words.dart';
import 'package:english_universe/toeic/toeic_words_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 토익 단어 — 목록이 읽히고 묶음이 맞는지, 단어 화면·퀴즈가 뜨는지.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => SharedPreferences.setMockInitialValues({}));

  Future<void> waitFor(WidgetTester t, Finder f) async {
    for (var i = 0; i < 50 && f.evaluate().isEmpty; i++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await t.pump(const Duration(milliseconds: 100));
    }
    await t.pump(const Duration(milliseconds: 300));
  }

  test('toeic word list', () async {
    final w = await ToeicWords.load();
    expect(w.length, greaterThan(1300));
    expect(w.map((x) => x.level).toSet(), ToeicWords.groups.toSet());
    expect(w.where((x) => x.ko.isEmpty), isEmpty);
    expect(w.map((x) => x.word).toSet().length, w.length); // 중복 없음
  });

  testWidgets('toeic words screen and quiz', (t) async {
    t.view.physicalSize = const Size(780, 1688);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(theme: AppTheme.light(), home: const ToeicWordsScreen()));
    await waitFor(t, find.text('1단원'));
    expect(find.text('1단원'), findsOneWidget);
    expect(find.textContaining('1,330개'), findsOneWidget);
    await t.pumpWidget(MaterialApp(theme: AppTheme.light(), home: const ToeicQuizScreen(group: 'I')));
    await waitFor(t, find.text('1 / 10'));
    expect(find.text('1 / 10'), findsOneWidget);
  });
}
