import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/pane.dart';
import '../core/theme.dart';
import '../services/curriculum_service.dart';
import '../services/dialogue_service.dart';
import '../services/learner_prefs.dart';
import '../services/tts_service.dart';
import '../widgets/english_decor.dart';

/// 토크버스 커리큘럼(~/talkverse/CURRICULUM_SPEC.md) — 레벨 고르기 → 편 고르기(코스) → 편 연습·확인 문제 → 복습 → 코스 시험 80%.
CurriculumService get _cur => CurriculumService.instance;

/// 배우기 탭의 커리큘럼 카드 — 「오늘: 복습 N · 새 편 N」 + 진행 막대.
class CurriculumCard extends StatefulWidget {
  const CurriculumCard({super.key});
  @override
  State<CurriculumCard> createState() => _CurriculumCardState();
}

class _CurriculumCardState extends State<CurriculumCard> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    Future.wait([_cur.load(), DialogueService.instance.ensureLoaded()]).then((_) {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: _cur.changed,
      builder: (context, _, _) {
        String sub;
        double? progress;
        if (!_ready) {
          sub = '';
        } else if (_cur.level == null || _cur.course == null) {
          sub = tr('레벨에서 회화를 골라 코스를 시작해요');
        } else if (_cur.todayDone) {
          sub = '${tr('오늘 분량 끝')} · ${tr('연속')} ${_cur.streakCount}${tr('일')}';
          progress = 1;
        } else {
          final left = (_cur.dailyGoal - _cur.todayNewDone).clamp(0, 3);
          sub = '${tr('오늘')}: ${tr('복습')} ${_cur.dueReviews.length} · ${tr('새 편')} $left';
          progress = _cur.todayProgress;
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: AppColors.washi,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              key: const Key('curriculum-card'),
              borderRadius: BorderRadius.circular(12),
              onTap: () => openPane(context, (_) => const CurriculumScreen()),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.line),
                  boxShadow: kCardShadow,
                ),
                child: Row(
                  children: [
                    const SealStamp(text: 'Path', size: 40, color: AppColors.beni),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tr('토크버스 커리큘럼'), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.sumi)),
                          const SizedBox(height: 2),
                          Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
                          if (progress != null) ...[
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(value: progress, minHeight: 5, backgroundColor: AppColors.washiDeep, color: progress >= 1 ? AppColors.matcha : AppColors.beni),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.muted, size: 20),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 커리큘럼 본 화면.
class CurriculumScreen extends StatefulWidget {
  const CurriculumScreen({super.key});
  @override
  State<CurriculumScreen> createState() => _CurriculumScreenState();
}

class _CurriculumScreenState extends State<CurriculumScreen> {
  bool _ready = false;
  bool _pickLevel = false;
  bool _askDrop = false; // 새 코스 — 지금 코스를 버릴지(화면 안에서 묻기)
  bool _newCourse = false;
  int _size = 5;
  final Set<String> _picked = {};

  @override
  void initState() {
    super.initState();
    Future.wait([_cur.load(), DialogueService.instance.ensureLoaded()]).then((_) {
      if (mounted) setState(() => _ready = true);
    });
  }

  List<String> get _levels => DialogueService.levels.where((l) => DialogueService.instance.count(l) > 0).toList();

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (!_ready) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_levels.isEmpty) {
      body = Center(child: Text(tr('회화가 들어오면 커리큘럼이 열려요'), style: const TextStyle(color: AppColors.muted)));
    } else if (_cur.level == null || _pickLevel) {
      body = _levelPicker();
    } else if (_cur.course == null || _cur.course!.passedAt != null || _newCourse) {
      body = _coursePicker();
    } else {
      body = _courseView();
    }
    return Scaffold(
      appBar: AppBar(title: Text(tr('토크버스 커리큘럼'))),
      body: ValueListenableBuilder<int>(valueListenable: _cur.changed, builder: (_, _, _) => body),
    );
  }

  EdgeInsets _pad(BuildContext c) => EdgeInsets.fromLTRB(16, 12, 16, 24 + MediaQuery.paddingOf(c).bottom);

  // ── 레벨 고르기 ──
  Widget _levelPicker() {
    final lv = _levels;
    return ListView(
      padding: _pad(context),
      children: [
        Text(tr('회화 레벨을 고르세요'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.sumi)),
        const SizedBox(height: 4),
        Text(tr('처음이라면 가장 낮은 레벨부터 권해요'), style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
        const SizedBox(height: 12),
        for (final l in lv)
          _tile(
            key: Key('cur-level-$l'),
            title: '$l · ${DialogueService.levelKo[l] ?? l}${l == lv.first && _cur.level == null ? '  ·  ${tr('추천')}' : ''}',
            subtitle: '${tr('회화')} ${DialogueService.instance.count(l)}${tr('편')} · ${tr('통과')} ${DialogueService.instance.list(region: l).where((d) => _cur.passedDialogues.contains(d.id)).length}',
            selected: l == _cur.level,
            onTap: () async {
              if (l != _cur.level) {
                _picked.clear();
                if (_cur.course != null && _cur.course!.passedAt == null) await _cur.dropCourse();
              }
              await _cur.setLevel(l);
              setState(() => _pickLevel = false);
            },
          ),
      ],
    );
  }

  Widget _tile({Key? key, required String title, required String subtitle, bool selected = false, Widget? trailing, VoidCallback? onTap}) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: selected ? AppColors.beniLight.withValues(alpha: 0.25) : AppColors.washi,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            key: key,
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: selected ? AppColors.beni : AppColors.line)),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.sumi)),
                    if (subtitle.isNotEmpty) Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
                  ]),
                ),
                ?trailing,
              ]),
            ),
          ),
        ),
      );

  Widget _levelBar() => Row(children: [
        Expanded(child: Text('${_cur.level} · ${DialogueService.levelKo[_cur.level] ?? ''}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.sumi))),
        TextButton(onPressed: () => setState(() => _pickLevel = true), child: Text(tr('레벨 바꾸기'))),
      ]);

  // ── 코스 만들기(편 고르기) ──
  Widget _coursePicker() {
    final list = DialogueService.instance.list(region: _cur.level);
    final done = _cur.course?.passedAt != null && !_newCourse;
    return ListView(
      padding: _pad(context),
      children: [
        _levelBar(),
        if (done)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.matcha.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
            child: Text('${tr('코스 통과')} · ${_cur.course!.examScores.last}${tr('점')} — ${tr('다음 코스를 골라요')}', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.matcha)),
          ),
        Text(tr('이번 코스에서 연습할 회화를 고르세요'), style: const TextStyle(fontSize: 13, color: AppColors.sumiLight)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
          for (final n in CurriculumService.courseSizes)
            ChoiceChip(
              label: Text('$n${tr('편')}'),
              selected: _size == n,
              onSelected: (_) => setState(() {
                _size = n;
                while (_picked.length > n) {
                  _picked.remove(_picked.last);
                }
              }),
            ),
          OutlinedButton(
            key: const Key('cur-recommend'),
            onPressed: () => setState(() {
              _picked
                ..clear()
                ..addAll(_cur.recommend(_cur.level!, _size).map((d) => d.id));
            }),
            child: Text(tr('추천으로 채우기')),
          ),
        ]),
        const SizedBox(height: 10),
        for (final d in list)
          _tile(
            key: Key('cur-pick-${d.id}'),
            title: '${d.emoji} ${d.title}',
            subtitle: '${DialogueService.islandKo[d.island] ?? d.island}${_cur.passedDialogues.contains(d.id) ? ' · ${tr('통과함')}' : ''}',
            selected: _picked.contains(d.id),
            trailing: Icon(_picked.contains(d.id) ? Icons.check_circle : Icons.circle_outlined, color: _picked.contains(d.id) ? AppColors.beni : AppColors.muted),
            onTap: () => setState(() {
              if (!_picked.remove(d.id) && _picked.length < _size) _picked.add(d.id);
            }),
          ),
        const SizedBox(height: 8),
        Row(children: [
          if (_newCourse) TextButton(onPressed: () => setState(() => _newCourse = false), child: Text(tr('돌아가기'))),
          const Spacer(),
          FilledButton(
            key: const Key('cur-start'),
            onPressed: _picked.isEmpty
                ? null
                : () async {
                    final ids = [for (final d in list) if (_picked.contains(d.id)) d.id];
                    await _cur.startCourse(ids);
                    setState(() {
                      _picked.clear();
                      _newCourse = false;
                    });
                  },
            child: Text('${tr('코스 시작')} (${_picked.length}/$_size)'),
          ),
        ]),
      ],
    );
  }

  // ── 진행 중 코스 ──
  Widget _courseView() {
    final c = _cur.course!;
    final due = _cur.dueReviews.length;
    return ListView(
      padding: _pad(context),
      children: [
        _levelBar(),
        // 오늘 분량
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.washiDeep, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.line)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              _cur.todayDone ? '${tr('오늘 분량 끝')} · ${tr('연속')} ${_cur.streakCount}${tr('일')}' : '${tr('오늘')}: ${tr('복습')} $due · ${tr('새 편')} ${(_cur.dailyGoal - _cur.todayNewDone).clamp(0, 3)}',
              style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.sumi),
            ),
            const SizedBox(height: 6),
            ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: _cur.todayProgress, minHeight: 6, backgroundColor: AppColors.washi, color: _cur.todayDone ? AppColors.matcha : AppColors.beni)),
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (final g in CurriculumService.goals.entries)
                ChoiceChip(label: Text('${tr(g.value)} · ${tr('새 편')} ${g.key}'), selected: _cur.dailyGoal == g.key, onSelected: (_) => _cur.setDailyGoal(g.key)),
            ]),
            if (due > 0) ...[
              const SizedBox(height: 8),
              FilledButton.icon(
                key: const Key('cur-review'),
                onPressed: () async {
                  final qs = _cur.reviewQuestions();
                  await openFull(context, (_) => CurQuizScreen(title: tr('복습'), questions: qs, onFinish: (a) async {
                    await _cur.finishReview(a);
                    return null;
                  }));
                  setState(() {});
                },
                icon: const Icon(Icons.replay),
                label: Text('${tr('복습 먼저')} ($due)'),
              ),
            ],
          ]),
        ),
        const SizedBox(height: 14),
        Text('${tr('이번 코스')} · ${tr('연습')} ${c.practiced.length}/${c.dialogueIds.length}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.muted)),
        const SizedBox(height: 8),
        for (final id in c.dialogueIds)
          if (DialogueService.instance.byId(id) case final d?)
            _tile(
              key: Key('cur-course-$id'),
              title: '${d.emoji} ${d.title}',
              subtitle: c.practiced.contains(id) ? tr('연습 끝') : tr('듣기 · 확인 문제'),
              trailing: Icon(c.practiced.contains(id) ? Icons.check_circle : Icons.play_circle_outline, color: c.practiced.contains(id) ? AppColors.matcha : AppColors.beni),
              onTap: () async {
                await openFull(context, (_) => CurPracticeScreen(dialogue: d));
                setState(() {});
              },
            ),
        const SizedBox(height: 8),
        if (c.examScores.isNotEmpty) Text('${tr('지난 시험')}: ${c.examScores.map((s) => '$s${tr('점')}').join(' · ')} — ${tr('80점 이상이면 통과')}', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        const SizedBox(height: 8),
        FilledButton(
          key: const Key('cur-exam'),
          onPressed: c.allPracticed
              ? () async {
                  final qs = _cur.examQuestions();
                  await openFull(context, (_) => CurQuizScreen(title: tr('코스 시험'), questions: qs, onFinish: (a) async {
                    final r = await _cur.finishExam(qs, a);
                    return r;
                  }));
                  setState(() {});
                }
              : null,
          child: Text(c.allPracticed ? tr('코스 시험 보기') : tr('모든 편을 연습하면 코스 시험이 열려요')),
        ),
        const SizedBox(height: 16),
        if (!_askDrop)
          Align(alignment: Alignment.centerLeft, child: TextButton(key: const Key('cur-new'), onPressed: () => setState(() => _askDrop = true), child: Text(tr('새 코스 시작'))))
        else
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.beniLight.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tr('지금 코스를 그만두고 새 코스를 고를까요? 연습 기록은 복습에 남아요.'), style: const TextStyle(color: AppColors.sumi)),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton(onPressed: () => setState(() => _askDrop = false), child: Text(tr('취소'))),
                FilledButton(
                  key: const Key('cur-drop'),
                  onPressed: () async {
                    await _cur.dropCourse();
                    setState(() {
                      _askDrop = false;
                      _newCourse = false;
                    });
                  },
                  child: Text(tr('그만두고 새로 고르기')),
                ),
              ]),
            ]),
          ),
      ],
    );
  }
}

/// 편 연습: 1) 듣기·읽기(전체 재생·줄마다 듣기·뜻 보기) → 2) 확인 문제.
class CurPracticeScreen extends StatefulWidget {
  final Dialogue dialogue;
  const CurPracticeScreen({super.key, required this.dialogue});
  @override
  State<CurPracticeScreen> createState() => _CurPracticeScreenState();
}

class _CurPracticeScreenState extends State<CurPracticeScreen> {
  bool _showKo = true;
  int _playing = -1;
  int _session = 0;

  Dialogue get d => widget.dialogue;

  @override
  void dispose() {
    _session++;
    TtsService.instance.stop();
    super.dispose();
  }

  Future<void> _say(DialogueTurn t) => TtsService.instance.speakAs(CurriculumService.lineText(t), gender: LearnerPrefs.voiceGender(t.speaker));

  Future<void> _playAll() async {
    final my = ++_session;
    for (var i = 0; i < d.turns.length; i++) {
      if (!mounted || my != _session) return;
      setState(() => _playing = i);
      await _say(d.turns[i]);
      await Future.delayed(const Duration(milliseconds: 650));
    }
    if (mounted && my == _session) setState(() => _playing = -1);
  }

  void _stop() {
    _session++;
    TtsService.instance.stop();
    setState(() => _playing = -1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${d.emoji} ${d.title}', maxLines: 1, overflow: TextOverflow.ellipsis)),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 24 + MediaQuery.paddingOf(context).bottom),
        children: [
          Text('1. ${tr('듣고 읽기')}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.muted)),
          const SizedBox(height: 6),
          Wrap(spacing: 8, runSpacing: 8, children: [
            FilledButton.icon(
              key: const Key('cur-play-all'),
              onPressed: _playing >= 0 ? _stop : _playAll,
              icon: Icon(_playing >= 0 ? Icons.stop : Icons.play_arrow),
              label: Text(_playing >= 0 ? tr('멈춤') : tr('전체 듣기')),
            ),
            FilterChip(label: Text(tr('뜻 보기')), selected: _showKo, onSelected: (v) => setState(() => _showKo = v)),
          ]),
          const SizedBox(height: 8),
          for (var i = 0; i < d.turns.length; i++)
            InkWell(
              onTap: () => _say(d.turns[i]),
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _playing == i ? AppColors.beniLight.withValues(alpha: 0.25) : AppColors.washi,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.line),
                ),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SizedBox(width: 56, child: Text(d.speakerName(d.turns[i].speaker), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.ai))),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(CurriculumService.lineText(d.turns[i]), style: const TextStyle(fontSize: 14.5, color: AppColors.sumi)),
                      if (_showKo && d.turns[i].ko.isNotEmpty) Text(LearnerPrefs.fill(d.turns[i].ko, ko: true), style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                    ]),
                  ),
                  const Icon(Icons.volume_up_outlined, size: 18, color: AppColors.muted),
                ]),
              ),
            ),
          const SizedBox(height: 4),
          Text(tr('줄을 누르면 그 줄만 다시 들어요 — 따라 말해 보세요'), style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
          const SizedBox(height: 16),
          Text('2. ${tr('확인 문제')}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.muted)),
          const SizedBox(height: 6),
          FilledButton(
            key: const Key('cur-check'),
            onPressed: () async {
              _stop();
              final qs = CurriculumService.questionsFor(d, others: DialogueService.instance.list(region: d.region));
              final nav = Navigator.of(context);
              await nav.push(MaterialPageRoute(
                builder: (_) => CurQuizScreen(title: tr('확인 문제'), questions: qs, onFinish: (a) async {
                  await CurriculumService.instance.finishPractice(d.id, a);
                  return null;
                }),
              ));
              if (mounted) nav.pop();
            },
            child: Text(tr('확인 문제 풀기')),
          ),
        ],
      ),
    );
  }
}

/// 4지선다 문제 화면(편 확인 문제·복습·코스 시험 공용). onFinish 가 시험 결과를 돌려주면 결과 화면에 통과 여부를 보인다.
class CurQuizScreen extends StatefulWidget {
  final String title;
  final List<CurQuestion> questions;
  final Future<CurExamResult?> Function(Map<String, bool> answers) onFinish;
  const CurQuizScreen({super.key, required this.title, required this.questions, required this.onFinish});
  @override
  State<CurQuizScreen> createState() => _CurQuizScreenState();
}

class _CurQuizScreenState extends State<CurQuizScreen> {
  int _i = 0;
  int? _chosen;
  final Map<String, bool> _answers = {};
  bool _finished = false;
  CurExamResult? _result;

  List<CurQuestion> get qs => widget.questions;

  Future<void> _next() async {
    if (_i + 1 < qs.length) {
      setState(() {
        _i++;
        _chosen = null;
      });
      return;
    }
    final r = await widget.onFinish(_answers);
    if (mounted) {
      setState(() {
        _finished = true;
        _result = r;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    if (qs.isEmpty) WidgetsBinding.instance.addPostFrameCallback((_) => _next());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text(widget.title)), body: _finished || qs.isEmpty ? _done() : _question());
  }

  Widget _question() {
    final q = qs[_i];
    final correct = _chosen != null && _chosen == q.answer;
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 24 + MediaQuery.paddingOf(context).bottom),
      children: [
        Text('${_i + 1} / ${qs.length} · ${q.kind == 'blank' ? tr('빈칸에 들어갈 낱말') : tr('알맞은 뜻')}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.muted)),
        const SizedBox(height: 8),
        Text(q.prompt, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.sumi)),
        if (q.hint.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(q.hint, style: const TextStyle(fontSize: 13, color: AppColors.muted))),
        const SizedBox(height: 14),
        for (var k = 0; k < q.options.length; k++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OutlinedButton(
              key: Key('cur-opt-$k'),
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                backgroundColor: _chosen == null
                    ? null
                    : k == q.answer
                        ? AppColors.matcha.withValues(alpha: 0.12)
                        : (k == _chosen ? AppColors.beni.withValues(alpha: 0.10) : null),
              ),
              onPressed: _chosen != null
                  ? null
                  : () {
                      setState(() => _chosen = k);
                      _answers[q.lineId] = k == q.answer;
                    },
              child: Text(q.options[k], style: const TextStyle(fontSize: 14.5, color: AppColors.sumi)),
            ),
          ),
        if (_chosen != null) ...[
          Text(correct ? tr('맞았어요') : tr('틀렸어요 — 복습에 넣어 둘게요'), style: TextStyle(fontWeight: FontWeight.w800, color: correct ? AppColors.matcha : AppColors.beni)),
          const SizedBox(height: 8),
          FilledButton(key: const Key('cur-next'), onPressed: _next, child: Text(_i + 1 < qs.length ? tr('다음') : tr('끝내기'))),
        ],
      ],
    );
  }

  Widget _done() {
    final ok = _answers.values.where((v) => v).length;
    final r = _result;
    final score = r?.score ?? CurriculumService.scoreOf(ok, qs.length);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(qs.isEmpty ? tr('풀 문제가 없어요') : '$ok / ${qs.length} · $score${tr('점')}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.sumi)),
          const SizedBox(height: 8),
          if (r != null)
            Text(
              r.passed
                  ? '${tr('코스 통과!')}${r.openedLevel != null ? ' ${r.openedLevel} ${tr('레벨이 열렸어요')}' : ''}'
                  : tr('80점이 안 됐어요 — 틀린 편을 다시 연습하고 시험을 봐요'),
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w700, color: r.passed ? AppColors.matcha : AppColors.beni),
            ),
          const SizedBox(height: 16),
          FilledButton(key: const Key('cur-close'), onPressed: () => Navigator.of(context).pop(), child: Text(tr('닫기'))),
        ]),
      ),
    );
  }
}
