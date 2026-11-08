import 'dart:convert';

import 'package:english_universe/core/theme.dart';
import 'package:english_universe/services/dialogue_service.dart';
import 'package:english_universe/toeic/toeic_words.dart';
import 'package:english_universe/toeic/toeic_words_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show AssetManifest, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 토익 단어 — 목록이 읽히고 묶음이 맞는지, 단어 화면·퀴즈가 뜨는지.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => SharedPreferences.setMockInitialValues({}));
  toeicDialogueTests();

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

/// 토익 비즈니스 회화 — 10편, 8턴, 문법 표시·문법 포인트·빈칸 문제가 다 있는지(파일 직접 읽기 — DialogueService 는 빌드된 앱에 따라 고른다).
void toeicDialogueTests() {
  test('toeic office dialogues', () async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final paths = manifest.listAssets().where((p) => p.startsWith('assets/data/toeic/dialogues/T1/office/')).toList();
    expect(paths.length, 10);
    for (final p in paths) {
      final d = Dialogue.fromJson(json.decode(await rootBundle.loadString(p)) as Map<String, dynamic>);
      expect(d.turns.length, 8, reason: d.id);
      expect(d.grammar, isNotNull, reason: d.id);
      expect(d.check!.options.length, 4, reason: d.id);
      expect(d.turns.any((t) => t.gram != null && t.gram!.underline.isNotEmpty), isTrue, reason: d.id);
      for (final t in d.turns) {
        for (final u in t.gram?.underline ?? const <String>[]) {
          expect(t.tl.toLowerCase(), contains(u.toLowerCase()), reason: '${d.id} ${t.num}');
        }
      }
    }
  });
}
