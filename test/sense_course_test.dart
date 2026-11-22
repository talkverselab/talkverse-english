import 'dart:convert';
import 'dart:io';

import 'package:english_universe/screens/sense_course_screen.dart';
import 'package:english_universe/services/script_sync.dart';
import 'package:crypto/crypto.dart';
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
    // 영상 주소가 비어 있으면 영상 칸을 그리지 않는다
    expect(find.byKey(const ValueKey('memorize-video')), findsNothing);
    expect(find.text('영상 준비 중'), findsNothing);
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

  test('급 틀 — 빈 급·빈 회차는 숨기고(「준비 중」 없음), 내용이 생기면 나타남 · 묶음 파일은 10급 모두 보임', () {
    Map<String, dynamic> lv(String id, List<Map<String, dynamic>> ls) => {'id': id, 'title': id, 'lessons': ls};
    final memo = {'id': 'm', 'kind': 'memorize', 'title': 't', 'sentences': [{'en': 'Hi.', 'ko': '안녕.'}]};
    final emptyMemo = {'id': 'e', 'kind': 'memorize', 'title': 't', 'sentences': []};
    final ref = {'id': 'r', 'kind': 'ref', 'title': 't', 'points': ['p']};
    final d = {
      'levels': [
        lv('L1', [memo, ref]),
        lv('L2', [emptyMemo, ref]), // 참고만 남음 → 숨김
        lv('L3', []), // 빈 급 → 숨김
        {'id': 'L4', 'title': 'L4'}, // lessons 없음 → 숨김
      ]
    };
    final v = SenseCourse.visible(d);
    expect((v['levels'] as List).map((l) => l['id']), ['L1']);
    expect(((v['levels'] as List).first['lessons'] as List).length, 2);
    // 서버 파일에 L3 내용이 생기면 그대로 나타난다
    (d['levels'] as List)[2] = lv('L3', [memo]);
    expect((SenseCourse.visible(d)['levels'] as List).map((l) => l['id']), ['L1', 'L3']);
    final real = json.decode(File('assets/data/grammar/sense_course.json').readAsStringSync()) as Map<String, dynamic>;
    expect(SenseCourse.visible(real)['levels'] as List, hasLength(10));
  });

  test('급 목록은 서버 파일을 따름 — 빠지면 안 보임 · 더해지면 보임 · 서버 못 받으면 묶음 목록', () async {
    const rel = 'grammar/sense_course.json';
    final bundled = json.decode(File('assets/data/$rel').readAsStringSync()) as Map<String, dynamic>;
    final levels = (bundled['levels'] as List).cast<Map<String, dynamic>>();
    final keep = ScriptSync.instance;
    addTearDown(() {
      ScriptSync.instance = keep;
      SenseCourse.debugClear();
    });
    Future<List<String>> shown(String? server) async {
      final dir = Directory.systemTemp.createTempSync('sense_sync');
      addTearDown(() => dir.deleteSync(recursive: true));
      final sha = server == null ? '' : sha1.convert(utf8.encode(server)).toString().substring(0, 12);
      ScriptSync.instance = ScriptSync.forTest(
        dir: dir,
        baseline: {'rev': 1, 'files': {rel: 'bundled'}},
        fetch: (url) async {
          if (server == null) return null; // 서버를 못 받음
          if (url.endsWith('/index.json')) return json.encode({'rev': 2, 'files': {rel: sha}});
          return url.contains(rel) ? server : null;
        },
      );
      await ScriptSync.instance.refresh();
      SenseCourse.debugClear();
      return [for (final l in (await SenseCourse.load())['levels'] as List) '${l['id']}'];
    }

    final all = [for (final l in levels) '${l['id']}'];
    expect(await shown(null), all);
    // 서버에서 앞 두 급을 빼면 그만큼 사라진다
    expect(await shown(json.encode({...bundled, 'levels': levels.skip(2).toList()})), all.skip(2).toList());
    // 서버에서 급을 더하면 나타난다(개수 상한 없음)
    final extra = {...levels.first, 'id': 'L99', 'title': 'new'};
    expect(await shown(json.encode({...bundled, 'levels': [...levels, extra]})), [...all, 'L99']);
  });
}
