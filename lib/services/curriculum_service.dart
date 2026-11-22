import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../core/prefs.dart';
import 'dialogue_service.dart';
import 'learner_prefs.dart';

/// 토크버스 커리큘럼(전 언어 공통 기준 ~/talkverse/CURRICULUM_SPEC.md, 2026-11-22).
/// 회화 레벨에서 편을 골라 코스 → 편마다 연습·확인 문제 → 간격 반복 복습(1·3·7일) → 코스 시험 80% 이상이면 통과.
/// 저장 = 기기(Prefs 키 `curriculum_v1`, 형식은 문서 §7 + 하루 기록 `day`).

/// 확인 문제 한 개. lineId = `<편id>#<줄번호>`.
class CurQuestion {
  final String lineId;
  final String kind; // meaning(뜻 고르기) · blank(빈칸 낱말 고르기)
  final String prompt; // 문제 문장(빈칸은 ____)
  final String hint; // 보조(빈칸 문제의 한국어 뜻)
  final List<String> options;
  final int answer;
  const CurQuestion({required this.lineId, required this.kind, required this.prompt, this.hint = '', required this.options, required this.answer});
  String get dialogueId => lineId.split('#').first;
}

class CurReview {
  final String lineId;
  final String due; // yyyy-MM-dd
  final int step; // 0=1일 · 1=3일 · 2=7일
  const CurReview(this.lineId, this.due, this.step);
  Map<String, dynamic> toJson() => {'lineId': lineId, 'due': due, 'step': step};
  factory CurReview.fromJson(Map<String, dynamic> j) => CurReview('${j['lineId']}', '${j['due']}', (j['step'] as num?)?.toInt() ?? 0);
}

class CurCourse {
  final String id;
  final List<String> dialogueIds;
  final List<String> practiced;
  final List<int> examScores;
  final String? passedAt;
  const CurCourse({required this.id, required this.dialogueIds, this.practiced = const [], this.examScores = const [], this.passedAt});
  bool get allPracticed => dialogueIds.every(practiced.contains);
  CurCourse copyWith({List<String>? practiced, List<int>? examScores, String? passedAt}) =>
      CurCourse(id: id, dialogueIds: dialogueIds, practiced: practiced ?? this.practiced, examScores: examScores ?? this.examScores, passedAt: passedAt ?? this.passedAt);
  Map<String, dynamic> toJson() => {'id': id, 'dialogueIds': dialogueIds, 'practiced': practiced, 'examScores': examScores, 'passedAt': passedAt};
  factory CurCourse.fromJson(Map<String, dynamic> j) => CurCourse(
        id: '${j['id']}',
        dialogueIds: [for (final x in (j['dialogueIds'] as List? ?? const [])) '$x'],
        practiced: [for (final x in (j['practiced'] as List? ?? const [])) '$x'],
        examScores: [for (final x in (j['examScores'] as List? ?? const [])) (x as num).toInt()],
        passedAt: j['passedAt'] as String?,
      );
}

/// 시험 결과.
class CurExamResult {
  final int score; // 0~100(소수점 버림)
  final bool passed;
  final List<String> wrongDialogues;
  final String? openedLevel; // 이 시험으로 레벨을 다 통과해 새로 열린 레벨
  const CurExamResult(this.score, this.passed, this.wrongDialogues, this.openedLevel);
}

class CurriculumService {
  CurriculumService._();
  static final CurriculumService instance = CurriculumService._();
  static const prefKey = 'curriculum_v1';
  static const intervals = [1, 3, 7];
  static const passScore = 80;
  static const courseSizes = [3, 5, 10];
  static const goals = {1: '가볍게', 2: '보통', 3: '집중'};

  /// 화면이 다시 그려질 때 쓰는 신호(저장할 때마다 오름).
  final ValueNotifier<int> changed = ValueNotifier(0);

  /// 오늘 날짜(시험에서 바꿈).
  @visibleForTesting
  DateTime Function() now = DateTime.now;

  String? level;
  int dailyGoal = 2;
  CurCourse? course;
  List<String> passedDialogues = [];
  List<CurReview> review = [];
  int streakCount = 0;
  String? streakLastDay;
  String dayDate = '';
  int dayNew = 0;
  int dayReview = 0;
  bool _loaded = false;

  static String dayOf(DateTime t) => '${t.year.toString().padLeft(4, '0')}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
  String get today => dayOf(now());
  static String addDays(String day, int n) {
    final p = day.split('-').map(int.parse).toList();
    return dayOf(DateTime(p[0], p[1], p[2] + n));
  }

  /// 점수 = 정답 수 / 문제 수 ×100, 소수점 버림.
  static int scoreOf(int correct, int total) => total == 0 ? 0 : (correct * 100) ~/ total;
  static bool isPass(int score) => score >= passScore;

  /// 간격 반복 다음 상태 — 맞히면 다음 간격(7일 단계까지 맞히면 졸업 = null), 틀리면 1일로.
  static CurReview? nextReview(CurReview r, bool correct, String today) {
    if (!correct) return CurReview(r.lineId, addDays(today, intervals[0]), 0);
    final step = r.step + 1;
    if (step >= intervals.length) return null;
    return CurReview(r.lineId, addDays(today, intervals[step]), step);
  }

  Future<void> load({bool force = false}) async {
    if (_loaded && !force) return;
    final p = await Prefs.getInstance();
    final raw = p.getString(prefKey);
    level = null;
    dailyGoal = 2;
    course = null;
    passedDialogues = [];
    review = [];
    streakCount = 0;
    streakLastDay = null;
    dayDate = '';
    dayNew = 0;
    dayReview = 0;
    if (raw != null) {
      try {
        final j = json.decode(raw) as Map<String, dynamic>;
        level = j['level'] as String?;
        dailyGoal = ((j['dailyGoal'] as num?)?.toInt() ?? 2).clamp(1, 3);
        course = j['course'] is Map ? CurCourse.fromJson((j['course'] as Map).cast<String, dynamic>()) : null;
        passedDialogues = [for (final x in (j['passedDialogues'] as List? ?? const [])) '$x'];
        review = [for (final x in (j['review'] as List? ?? const [])) if (x is Map) CurReview.fromJson(x.cast<String, dynamic>())];
        final s = (j['streak'] as Map?) ?? const {};
        streakCount = (s['count'] as num?)?.toInt() ?? 0;
        streakLastDay = s['lastDay'] as String?;
        final d = (j['day'] as Map?) ?? const {};
        dayDate = '${d['date'] ?? ''}';
        dayNew = (d['newDone'] as num?)?.toInt() ?? 0;
        dayReview = (d['reviewDone'] as num?)?.toInt() ?? 0;
      } catch (_) {}
    }
    _loaded = true;
  }

  Future<void> _save() async {
    final p = await Prefs.getInstance();
    await p.setString(
      prefKey,
      json.encode({
        'level': level,
        'dailyGoal': dailyGoal,
        'course': course?.toJson(),
        'passedDialogues': passedDialogues,
        'review': [for (final r in review) r.toJson()],
        'streak': {'count': streakCount, 'lastDay': streakLastDay},
        'day': {'date': dayDate, 'newDone': dayNew, 'reviewDone': dayReview},
      }),
    );
    changed.value++;
  }

  void _rollDay() {
    if (dayDate != today) {
      dayDate = today;
      dayNew = 0;
      dayReview = 0;
    }
  }

  // ── 오늘 분량 ──
  List<CurReview> get dueReviews => [for (final r in review) if (r.due.compareTo(today) <= 0) r];
  int get todayNewDone => dayDate == today ? dayNew : 0;
  int get todayReviewDone => dayDate == today ? dayReview : 0;
  bool get todayDone => course != null && dueReviews.isEmpty && todayNewDone >= dailyGoal;
  /// 진행 막대(0~1) = (한 복습 + 한 새 편) / (오늘 복습 전체 + 목표 새 편).
  double get todayProgress {
    final due = dueReviews.length;
    final total = todayReviewDone + due + dailyGoal;
    final done = todayReviewDone + min(todayNewDone, dailyGoal);
    return total == 0 ? 1 : (done / total).clamp(0, 1).toDouble();
  }

  Future<void> _touchStreak() async {
    if (!todayDone || streakLastDay == today) return;
    streakCount = streakLastDay == addDays(today, -1) ? streakCount + 1 : 1;
    streakLastDay = today;
  }

  // ── 설정 ──
  Future<void> setLevel(String lv) async {
    level = lv;
    await _save();
  }

  Future<void> setDailyGoal(int g) async {
    dailyGoal = g.clamp(1, 3);
    await _touchStreak();
    await _save();
  }

  /// 그 레벨에서 아직 통과 안 한 편 중 주제가 겹치지 않게 n개.
  List<Dialogue> recommend(String lv, int n) {
    final pool = DialogueService.instance.list(region: lv).where((d) => !passedDialogues.contains(d.id)).toList();
    final out = <Dialogue>[];
    final used = <String>{};
    for (final d in pool) {
      if (out.length >= n) break;
      if (used.add(d.island)) out.add(d);
    }
    for (final d in pool) {
      if (out.length >= n) break;
      if (!out.contains(d)) out.add(d);
    }
    return out;
  }

  Future<void> startCourse(List<String> ids) async {
    course = CurCourse(id: 'c${now().millisecondsSinceEpoch}', dialogueIds: ids);
    await _save();
  }

  Future<void> dropCourse() async {
    course = null;
    await _save();
  }

  // ── 문제 만들기 ──
  static final _wordRe = RegExp(r"[A-Za-z][A-Za-z'’-]{2,}");
  static String lineText(DialogueTurn t) => LearnerPrefs.fill(t.tl).replaceAll(RegExp(r'\([^)]*\)'), '').trim();

  /// 줄 하나로 문제 하나. 보기가 4개를 못 채우면 null.
  static CurQuestion? questionFor(Dialogue d, DialogueTurn t, {required bool blank, required Random rng, List<Dialogue> others = const []}) {
    final lineId = '${d.id}#${t.num}';
    final text = lineText(t);
    if (text.isEmpty) return null;
    final pool = [d, ...others.where((o) => o.id != d.id)];
    List<String>? opts;
    String prompt = text;
    String answerText;
    String hint = '';
    if (blank) {
      final words = _wordRe.allMatches(text).map((m) => m.group(0)!).toList();
      if (words.isEmpty) return questionFor(d, t, blank: false, rng: rng, others: others);
      final lem = t.lemmas.map((l) => l.surface).where(words.contains).toList();
      answerText = (lem.isNotEmpty ? lem : words)[rng.nextInt((lem.isNotEmpty ? lem : words).length)];
      prompt = text.replaceFirst(RegExp('\\b${RegExp.escape(answerText)}\\b'), '____');
      hint = LearnerPrefs.fill(t.ko, ko: true);
      final cand = <String>{};
      for (final o in pool) {
        for (final ot in o.turns) {
          for (final m in _wordRe.allMatches(lineText(ot))) {
            final w = m.group(0)!;
            if (w.toLowerCase() != answerText.toLowerCase()) cand.add(w);
          }
        }
        if (cand.length >= 12) break;
      }
      opts = (cand.toList()..shuffle(rng)).take(3).toList();
    } else {
      answerText = LearnerPrefs.fill(t.ko, ko: true);
      if (answerText.isEmpty) return null;
      final cand = <String>{};
      for (final o in pool) {
        for (final ot in o.turns) {
          final k = LearnerPrefs.fill(ot.ko, ko: true);
          if (k.isNotEmpty && k != answerText) cand.add(k);
        }
        if (cand.length >= 8) break;
      }
      opts = (cand.toList()..shuffle(rng)).take(3).toList();
    }
    if (opts.length < 3) return null;
    final at = rng.nextInt(4);
    opts.insert(at, answerText);
    return CurQuestion(lineId: lineId, kind: blank ? 'blank' : 'meaning', prompt: prompt, hint: hint, options: opts, answer: at);
  }

  /// 편 확인 문제: 줄 수만큼, 최대 [max]개 — 뜻 고르기·빈칸을 번갈아.
  static List<CurQuestion> questionsFor(Dialogue d, {int max = 10, Random? rng, List<Dialogue> others = const []}) {
    final r = rng ?? Random();
    final turns = d.turns.where((t) => lineText(t).isNotEmpty).toList();
    if (turns.length > max) {
      turns.shuffle(r);
      turns.length = max;
      turns.sort((a, b) => a.num.compareTo(b.num));
    }
    final out = <CurQuestion>[];
    for (var i = 0; i < turns.length; i++) {
      final q = questionFor(d, turns[i], blank: i.isOdd, rng: r, others: others);
      if (q != null) out.add(q);
    }
    return out;
  }

  /// 코스 시험 편당 문제 수: 최소 3, 합계 최대 30.
  static int examPerDialogue(int n) => n == 0 ? 0 : max(3, min(10, 30 ~/ n));

  List<Dialogue> get _levelPool => DialogueService.instance.list(region: level);

  List<CurQuestion> examQuestions({Random? rng}) {
    final c = course;
    if (c == null) return const [];
    final r = rng ?? Random();
    final per = examPerDialogue(c.dialogueIds.length);
    final out = <CurQuestion>[];
    for (final id in c.dialogueIds) {
      final d = DialogueService.instance.byId(id);
      if (d != null) out.addAll(questionsFor(d, max: per, rng: r, others: _levelPool));
    }
    out.shuffle(r);
    return out.take(30).toList();
  }

  List<CurQuestion> reviewQuestions({int limit = 20, Random? rng}) {
    final r = rng ?? Random();
    final out = <CurQuestion>[];
    for (final rv in dueReviews.take(limit)) {
      final parts = rv.lineId.split('#');
      final d = DialogueService.instance.byId(parts.first);
      final t = d?.turns.where((t) => '${t.num}' == (parts.length > 1 ? parts[1] : '')).firstOrNull;
      if (d == null || t == null) {
        review.removeWhere((x) => x.lineId == rv.lineId); // 원고에서 빠진 줄
        continue;
      }
      final q = questionFor(d, t, blank: r.nextBool(), rng: r, others: _levelPool);
      if (q != null) out.add(q);
    }
    return out;
  }

  // ── 결과 기록 ──
  /// 편 연습 끝: 연습 표시, 그 편의 줄을 복습 대기열에(1일 뒤), 새 편이면 오늘 새 편 +1.
  Future<void> finishPractice(String dialogueId, Map<String, bool> answers) async {
    _rollDay();
    final c = course;
    if (c != null && c.dialogueIds.contains(dialogueId) && !c.practiced.contains(dialogueId)) {
      course = c.copyWith(practiced: [...c.practiced, dialogueId]);
      dayNew++;
    }
    final d = DialogueService.instance.byId(dialogueId);
    final ids = {for (final t in d?.turns ?? const <DialogueTurn>[]) '${d!.id}#${t.num}', ...answers.keys};
    final tomorrow = addDays(today, 1);
    for (final id in ids) {
      final i = review.indexWhere((r) => r.lineId == id);
      final wrong = answers[id] == false;
      if (i < 0) {
        review.add(CurReview(id, tomorrow, 0));
      } else if (wrong) {
        review[i] = CurReview(id, tomorrow, 0);
      }
    }
    await _touchStreak();
    await _save();
  }

  Future<void> finishReview(Map<String, bool> answers) async {
    _rollDay();
    for (final e in answers.entries) {
      final i = review.indexWhere((r) => r.lineId == e.key);
      if (i < 0) continue;
      final next = nextReview(review[i], e.value, today);
      if (next == null) {
        review.removeAt(i);
      } else {
        review[i] = next;
      }
      dayReview++;
    }
    await _touchStreak();
    await _save();
  }

  /// 시험 끝: 80% 이상이면 코스 통과(편들을 통과 목록에), 레벨 편을 다 통과하면 다음 레벨을 연다.
  /// 미만이면 틀린 편의 연습 표시를 지워 다시 연습하게 한다.
  Future<CurExamResult> finishExam(List<CurQuestion> qs, Map<String, bool> answers) async {
    final c = course!;
    var correct = 0;
    final wrongD = <String>{};
    for (final q in qs) {
      if (answers[q.lineId] == true) {
        correct++;
      } else {
        wrongD.add(q.dialogueId);
      }
    }
    final score = scoreOf(correct, qs.length);
    final pass = isPass(score);
    String? opened;
    if (pass) {
      course = c.copyWith(examScores: [...c.examScores, score], passedAt: today);
      for (final id in c.dialogueIds) {
        if (!passedDialogues.contains(id)) passedDialogues.add(id);
      }
      final lv = level;
      if (lv != null && _levelPool.isNotEmpty && _levelPool.every((d) => passedDialogues.contains(d.id))) {
        final levels = DialogueService.levels.where((l) => DialogueService.instance.count(l) > 0).toList();
        final i = levels.indexOf(lv);
        if (i >= 0 && i + 1 < levels.length) {
          opened = levels[i + 1];
          level = opened;
        }
      }
    } else {
      course = c.copyWith(examScores: [...c.examScores, score], practiced: c.practiced.where((id) => !wrongD.contains(id)).toList());
    }
    await _save();
    return CurExamResult(score, pass, wrongD.toList(), opened);
  }

  /// 시험 전용 — 저장 상태를 비운다.
  @visibleForTesting
  void debugReset() {
    _loaded = false;
    now = DateTime.now;
  }
}
