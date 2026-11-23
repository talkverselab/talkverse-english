import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:english_universe/screens/curriculum_screen.dart';
import 'package:english_universe/services/curriculum_service.dart';
import 'package:english_universe/services/curriculum_plan.dart';
import 'dart:convert';
import 'dart:io';
import 'package:english_universe/services/dialogue_service.dart';

Dialogue _d(String id, String island, int n) => Dialogue.fromJson({
      'id': id,
      'region': 'R1',
      'island': island,
      'turns': [
        for (var i = 1; i <= n; i++) {'num': i, 'speaker': i.isOdd ? 'A' : 'B', 'tl': 'Line $id number $i', 'ko': '뜻$id$i'}
      ],
    });

void main() {
  group('점수 80% 경계', () {
    test('소수점 버림', () {
      expect(scorePercent(7, 9), 77);
      expect(scorePercent(2, 3), 66);
      expect(scorePercent(0, 0), 0);
    });
    test('80% 이상만 통과', () {
      expect(isPass(8, 10), isTrue);
      expect(isPass(79, 100), isFalse);
      expect(isPass(4, 5), isTrue);
      expect(isPass(23, 29), isFalse); // 79.3 → 79
      expect(isPass(24, 30), isTrue);
    });
    test('시험 기록 — 통과면 편 통과, 아니면 틀린 편 연습 다시', () {
      final st = CurriculumState(course: Course('c', ['a', 'b'], practiced: ['a', 'b']));
      expect(st.recordExam(7, 10, {'b'}, '2026-11-22'), isFalse);
      expect(st.course!.practiced, ['a']);
      expect(st.passedDialogues, isEmpty);
      st.course!.practiced.add('b');
      expect(st.recordExam(8, 10, {}, '2026-11-23'), isTrue);
      expect(st.course!.passedAt, '2026-11-23');
      expect(st.passedDialogues, ['a', 'b']);
      expect(st.course!.examScores, [70, 80]);
    });
  });

  group('간격 반복 날짜', () {
    test('1일 → 3일 → 7일 → 졸업', () {
      final st = CurriculumState();
      st.enqueue('x#1', '2026-11-22');
      expect(st.review.single.due, '2026-11-23');
      st.grade('x#1', true, '2026-11-23');
      expect(st.review.single.due, '2026-11-26');
      st.grade('x#1', true, '2026-11-26');
      expect(st.review.single.due, '2026-12-03');
      st.grade('x#1', true, '2026-12-03');
      expect(st.review, isEmpty);
    });
    test('틀리면 1일 뒤 처음 간격으로', () {
      final st = CurriculumState();
      st.enqueue('x#1', '2026-11-22');
      st.grade('x#1', true, '2026-11-23');
      st.grade('x#1', false, '2026-11-26');
      expect(st.review.single.step, 0);
      expect(st.review.single.due, '2026-11-27');
    });
    test('달·해 넘김', () {
      expect(addDays('2026-12-30', 3), '2027-01-02');
      expect(addDays('2028-02-28', 1), '2028-02-29');
    });
  });

  group('하루 분량·연속', () {
    test('새 편 목표를 채우고 복습이 없으면 끝, 연속 일수', () {
      final st = CurriculumState(dailyGoal: 1, course: Course('c', ['a', 'b']));
      expect(st.dayDone('2026-11-22'), isFalse);
      st.markPracticed('a', [1, 2], '2026-11-22');
      expect(st.dayDone('2026-11-22'), isTrue);
      expect(st.streakShown('2026-11-22'), 1);
      // 다음 날: 복습 2줄 + 새 편 1
      expect(st.dueReview('2026-11-23').length, 2);
      st.grade('a#1', true, '2026-11-23');
      st.grade('a#2', true, '2026-11-23');
      st.markPracticed('b', [1], '2026-11-23');
      expect(st.todayReview, 2);
      expect(st.streakShown('2026-11-23'), 2);
      expect(st.streakShown('2026-11-25'), 0);
    });
    test('저장 형식 왕복', () {
      final st = CurriculumState(level: 'R1', course: Course('c', ['a']));
      st.markPracticed('a', [1], '2026-11-22');
      final back = CurriculumState.fromJson(st.toJson());
      expect(back.toJson(), st.toJson());
      expect(st.toJson().keys, containsAll(['level', 'dailyGoal', 'course', 'passedDialogues', 'review', 'streak']));
    });
  });

  group('문제·추천', () {
    test('편마다 줄 수만큼, 최대 10, 보기 4개 중 정답 1', () {
      final a = _d('a', 'friends', 12), b = _d('b', 'life', 4);
      final qs = buildQuestions(a, limit: 10, pool: [b]);
      expect(qs.length, 10);
      for (final q in qs) {
        expect(q.choices.length, 4);
        expect(q.choices.toSet().length, 4);
        expect(q.choices[q.answer], '뜻a${q.turn}');
      }
      expect(buildQuestions(b, limit: 10, pool: [a]).length, 4);
    });
    test('시험 문제 수: 편당 최소 3, 전체 최대 30', () {
      expect(examPerDialogue(3), 10);
      expect(examPerDialogue(5), 6);
      expect(examPerDialogue(10), 3);
    });
    test('추천 = 안 한 편, 주제 겹치지 않게', () {
      final list = [_d('f1', 'friends', 2), _d('f2', 'friends', 2), _d('l1', 'life', 2), _d('w1', 'work', 2)];
      final r = recommend(list, {'l1'}, {}, 3);
      expect(r, ['f1', 'w1', 'f2']);
    });
  });

  testWidgets('시험 화면 — 고르고 결과까지', (t) async {
    final a = _d('a', 'friends', 5);
    final qs = buildQuestions(a, limit: 2);
    await t.pumpWidget(MaterialApp(home: CurriculumQuizScreen(title: 'T', questions: qs, mode: QuizMode.exam)));
    for (var i = 0; i < 2; i++) {
      await t.tap(find.text(qs[i].choices[qs[i].answer]));
      await t.pump();
      await t.tap(find.byType(FilledButton).last);
      await t.pump();
    }
    expect(find.textContaining('100'), findsOneWidget);
  });

  test('영어 빈칸 — 낱말 단위로 비우고(부분 일치 아님), 보기 4개에 정답', () {
    final d = Dialogue.fromJson({
      'id': 'en_b', 'region': 'R1', 'island': 'life',
      'turns': [
        for (var i = 1; i <= 6; i++) {'num': i, 'speaker': 'A', 'tl': 'I want coffee and a cake number$i.', 'ko': '뜻$i', 'lemmas': [['coffee', 'coffee'], ['want', 'want'], ['cake', 'cake'], ['and', 'and']]}
      ],
    });
    final qs = buildQuestions(d, limit: 6, seed: 3);
    final blanks = qs.where((q) => q.kind == 'blank').toList();
    expect(blanks, isNotEmpty);
    for (final q in blanks) {
      expect(q.prompt, contains('____'));
      expect(q.choices.toSet(), hasLength(4));
      expect(q.prompt.replaceFirst('____', q.choices[q.answer]), startsWith('I want coffee and a cake'));
    }
  });

  for (final w in const [300.0, 390.0]) {
    testWidgets('코스 고르기 폭 $w — 3·5·10 칩·추천 줄이 넘치지 않음', (t) async {
      SharedPreferences.setMockInitialValues({'en_curriculum_v1': '{"level":"R1"}'});
      t.view.physicalSize = Size(w, 800);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final svc = DialogueService.instance;
      await t.runAsync(() => svc.ensureLoaded());
      for (final (i, id) in ['zz_w1', 'zz_w2', 'zz_w3'].indexed) {
        svc.debugAdd(Dialogue.fromJson({
          'id': id, 'region': 'R1', 'island': 'isle$i', 'title': 'T $id',
          'turns': [for (var n = 1; n <= 4; n++) {'num': n, 'speaker': 'A', 'tl': 'Line $id number $n', 'ko': '뜻 $id $n'}],
        }));
      }
      await t.pumpWidget(const MaterialApp(home: CurriculumScreen()));
      for (var i = 0; i < 60 && find.text('추천으로 채우기').evaluate().isEmpty; i++) {
        await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
        await t.pump();
      }
      expect(find.text('추천으로 채우기'), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  }

  group('§12 단계 목록(서버·묶음 JSON)', () {
    late Directory dir;
    setUp(() {
      dir = Directory.systemTemp.createTempSync('cur_plan');
      CurriculumPlan.instance
        ..debugReset()
        ..dir = dir;
    });
    tearDown(() {
      CurriculumPlan.instance
        ..debugReset()
        ..fetch = null
        ..dir = null;
      dir.deleteSync(recursive: true);
    });

    test('묶음 JSON 의 편 id 가 모두 앱 편 — 단계 1~5 안, 앱에 없는 id 는 건너뜀·편 0개 단계는 숨김', () async {
      final d = json.decode(File('assets/curriculum_en.json').readAsStringSync()) as Map;
      final st = CurriculumPlan.parse(d);
      expect(st, isNotEmpty);
      expect(st.every((s) => int.parse(s.n) >= 1 && int.parse(s.n) <= 5), isTrue);
      final svc = DialogueService.instance;
      await svc.ensureLoaded();
      CurriculumPlan.instance.fetch = (_) async => json.encode({
            'rev': 99,
            'stages': [
              {'n': 1, 'title': '1단계', 'dialogueIds': ['zz_none', st.first.dialogueIds.first]},
              {'n': 2, 'title': '2단계', 'dialogueIds': ['zz_none']},
            ],
          });
      await CurriculumPlan.instance.ensureLoaded();
      await CurriculumPlan.instance.refresh(); // 뒤에서 받는 서버 판을 기다리지 않고 직접(시간에 기대지 않게)
      expect(CurriculumPlan.instance.rev, 99);
      final cur = CurriculumService.instance;
      expect(cur.levels, ['1']); // 2단계는 앱에 있는 편이 없어 숨김
      expect(cur.levelList('1').map((d) => d.id), [st.first.dialogueIds.first]);
      expect(cur.levelName('1'), '1단계');
      // 받아 둔 판은 다음 실행에도 쓴다(서버 못 받아도)
      CurriculumPlan.instance
        ..debugReset()
        ..fetch = (_) async => null;
      await CurriculumPlan.instance.ensureLoaded();
      expect(CurriculumPlan.instance.rev, 99);
    });

    test('서버 rev 가 같거나 낮으면 묶음 그대로 · JSON 이 없으면 회화 레벨(R) 동작', () async {
      CurriculumPlan.instance.fetch = (_) async => json.encode({'rev': 0, 'stages': [{'n': 1, 'dialogueIds': []}]});
      await CurriculumPlan.instance.ensureLoaded();
      await CurriculumPlan.instance.refresh();
      expect(CurriculumPlan.instance.stages.length, greaterThanOrEqualTo(4));
      CurriculumPlan.instance.stages = const [];
      expect(CurriculumService.instance.levels.first, startsWith('R'));
      expect(CurriculumService.instance.levelName('R1'), contains('R1'));
    });
  });
}
