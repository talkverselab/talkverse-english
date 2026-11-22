import 'dart:math';

import 'package:english_universe/screens/curriculum_screen.dart';
import 'package:english_universe/services/curriculum_service.dart';
import 'package:english_universe/services/dialogue_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Dialogue fake(String id, String island, int n) => Dialogue.fromJson({
      'id': id,
      'region': 'R1',
      'island': island,
      'title': 'T $id',
      'turns': [
        for (var i = 1; i <= n; i++) {'num': i, 'speaker': i.isOdd ? 'A' : 'B', 'tl': 'Sentence number$i about coffee$i today.', 'ko': '$id 문장 $i 뜻'},
      ],
    });

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('점수 80% 경계 — 소수점 버림, 80 이상 통과', () {
    expect(CurriculumService.scoreOf(8, 10), 80);
    expect(CurriculumService.isPass(CurriculumService.scoreOf(8, 10)), isTrue);
    expect(CurriculumService.scoreOf(23, 29), 79); // 79.3
    expect(CurriculumService.isPass(79), isFalse);
    expect(CurriculumService.scoreOf(4, 5), 80);
    expect(CurriculumService.scoreOf(0, 0), 0);
  });

  test('간격 반복 1·3·7일 — 맞히면 다음 간격, 7일 단계 맞히면 졸업, 틀리면 1일', () {
    const day = '2026-11-30';
    final a = CurriculumService.nextReview(const CurReview('x#1', day, 0), true, day)!;
    expect((a.step, a.due), (1, '2026-12-03'));
    final b = CurriculumService.nextReview(a, true, day)!;
    expect((b.step, b.due), (2, '2026-12-07'));
    expect(CurriculumService.nextReview(b, true, day), isNull);
    final c = CurriculumService.nextReview(b, false, day)!;
    expect((c.step, c.due), (0, '2026-12-01'));
  });

  test('시험 편당 문제 수 — 최소 3, 합계 30 이하', () {
    expect(CurriculumService.examPerDialogue(10), 3);
    expect(CurriculumService.examPerDialogue(5), 6);
    expect(CurriculumService.examPerDialogue(3), 10);
  });

  test('연습 → 복습 대기열(내일) → 오늘 분량 · 시험 통과로 레벨 통과', () async {
    final svc = DialogueService.instance;
    await svc.ensureLoaded();
    final ids = ['zz_a1', 'zz_a2', 'zz_a3'];
    for (final (i, id) in ids.indexed) {
      svc.debugAdd(fake(id, 'isle$i', 6));
    }
    final cur = CurriculumService.instance;
    cur.debugReset();
    cur.now = () => DateTime(2026, 11, 23, 9);
    await cur.load(force: true);
    await cur.setLevel('R1');
    await cur.startCourse(ids);
    final qs = CurriculumService.questionsFor(svc.byId('zz_a1')!, rng: Random(1));
    expect(qs, hasLength(6));
    expect(qs.every((q) => q.options.length == 4 && q.options.toSet().length == 4), isTrue);
    await cur.finishPractice('zz_a1', {for (final q in qs) q.lineId: true});
    expect(cur.todayNewDone, 1);
    expect(cur.review.where((r) => r.lineId.startsWith('zz_a1#')).every((r) => r.due == '2026-11-24'), isTrue);
    expect(cur.dueReviews, isEmpty);
    cur.now = () => DateTime(2026, 11, 24, 9);
    expect(cur.dueReviews.length, greaterThanOrEqualTo(6));
    for (final id in ids.skip(1)) {
      await cur.finishPractice(id, const {});
    }
    expect(cur.course!.allPracticed, isTrue);
    final ex = cur.examQuestions(rng: Random(2));
    expect(ex.length, lessThanOrEqualTo(30));
    // 정답 79% → 실패, 틀린 편 연습 표시 지움
    final fail = <String, bool>{for (final q in ex) q.lineId: true};
    final wrongN = ex.length - (ex.length * 79 ~/ 100);
    for (final q in ex.take(wrongN)) {
      fail[q.lineId] = false;
    }
    final r1 = await cur.finishExam(ex, fail);
    expect(r1.passed, isFalse);
    expect(cur.course!.allPracticed, isFalse);
    final r2 = await cur.finishExam(ex, {for (final q in ex) q.lineId: true});
    expect((r2.passed, r2.score), (true, 100));
    expect(cur.passedDialogues, containsAll(ids));
    // 저장 키 이름
    final p = await SharedPreferences.getInstance();
    expect(p.getKeys().any((k) => k.endsWith('curriculum_v1')), isTrue);
  });

  for (final w in const [320.0, 900.0]) {
    testWidgets('커리큘럼 화면 폭 $w — 레벨 고르기 → 추천 → 코스 시작, 넘침 없음', (t) async {
      t.view.physicalSize = Size(w, 800);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final svc = DialogueService.instance;
      await t.runAsync(() => svc.ensureLoaded());
      for (final (i, id) in ['zz_w1', 'zz_w2', 'zz_w3', 'zz_w4'].indexed) {
        svc.debugAdd(fake(id, 'isle$i', 5));
      }
      CurriculumService.instance.debugReset();
      await t.runAsync(() => CurriculumService.instance.load(force: true));
      await t.pumpWidget(const MaterialApp(home: CurriculumScreen()));
      for (var i = 0; i < 50 && find.byKey(const Key('cur-level-R1')).evaluate().isEmpty; i++) {
        await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
        await t.pump();
      }
      await t.tap(find.byKey(const Key('cur-level-R1')));
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await t.pump();
      await t.tap(find.byKey(const Key('cur-recommend')));
      await t.pump();
      await t.scrollUntilVisible(find.byKey(const Key('cur-start')), 200, scrollable: find.byType(Scrollable).first);
      await t.tap(find.byKey(const Key('cur-start')));
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await t.pump();
      expect(find.byKey(const Key('cur-exam')), findsOneWidget);
      expect(CurriculumService.instance.course!.dialogueIds, hasLength(5));
      expect(t.takeException(), isNull);
    });
  }
}
