import 'dart:math';

import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/pane.dart';
import '../core/theme.dart';
import '../screens/word_freq_screen.dart' show EnWord, UnitBlock, kUnit, wordUnits;
import '../screens/word_quiz_screen.dart' show QuizQuestion, buildRound;
import '../services/achievement_service.dart';
import '../services/tts_service.dart';
import '../widgets/english_decor.dart';
import '../widgets/word_sheet.dart';
import 'toeic_words.dart';

/// 토익 단어 익히기 — 1,330어를 20어 단원 타일로(절벽 단어 화면과 같은 부품). 묶음: 기본 빈도어 · 명사 · 동사 · 형용사 · 부사.
/// 타일을 누르면 발음, 길게 누르면 단어 시트. 오른쪽 위 퀴즈 = 뜻 고르기 4지선다.
class ToeicWordsScreen extends StatefulWidget {
  const ToeicWordsScreen({super.key});

  @override
  State<ToeicWordsScreen> createState() => _ToeicWordsScreenState();
}

class _ToeicWordsScreenState extends State<ToeicWordsScreen> {
  List<EnWord> _words = const [];
  bool _loading = true;
  String _filter = 'ALL';

  @override
  void initState() {
    super.initState();
    ToeicWords.load().then((w) {
      if (!mounted) return;
      setState(() {
        _words = w;
        _loading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final list = _filter == 'ALL' ? _words : _words.where((w) => w.level == _filter).toList();
    final units = wordUnits(list);
    return Scaffold(
      backgroundColor: AppColors.washi,
      appBar: AppBar(
        title: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(tr('토익 단어'), style: const TextStyle(color: AppColors.sumi, fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(trf('{0}어 · {1}어 단원 · 탭하면 발음', [_n(_words.length), kUnit]), style: const TextStyle(color: AppColors.sumiLight, fontSize: 10, letterSpacing: 1)),
        ]),
        actions: [
          IconButton(
            tooltip: tr('뜻 고르기 퀴즈'),
            icon: const Icon(Icons.quiz_outlined, color: AppColors.beni),
            onPressed: _words.isEmpty ? null : () => openFull(context, (_) => ToeicQuizScreen(group: _filter)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.beni))
          : Column(children: [
              Container(
                color: AppColors.washiDeep,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final g in ['ALL', ...ToeicWords.groups])
                      ChoiceChip(
                        label: Text(g == 'ALL' ? tr('전체') : '${tr(ToeicWords.labels[g]!)} ${_words.where((w) => w.level == g).length}'),
                        selected: _filter == g,
                        onSelected: (_) => setState(() => _filter = g),
                        selectedColor: (ToeicWords.colors[g] ?? AppColors.sumi).withValues(alpha: 0.18),
                        labelStyle: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: ToeicWords.colors[g] ?? AppColors.sumi),
                        showCheckmark: false,
                        visualDensity: VisualDensity.compact,
                      ),
                  ]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Row(children: [
                  Text(trf('{0}개 · {1}단원', [_n(list.length), units.length]), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.sumi)),
                  const Spacer(),
                  ValueListenableBuilder<EnAccent>(
                    valueListenable: AccentPrefs.accent,
                    builder: (_, a, _) => ActionChip(
                      avatar: const Icon(Icons.record_voice_over, size: 16, color: AppColors.beni),
                      label: Text(trf('{0} 발음', [a.label])),
                      onPressed: AccentPrefs.next,
                      visualDensity: VisualDensity.compact,
                      labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ]),
              ),
              const BrushDivider(height: 2),
              Expanded(
                child: LayoutBuilder(builder: (context, c) {
                  final cols = (c.maxWidth / 112).floor().clamp(3, 8);
                  return ListView.builder(
                    padding: EdgeInsets.fromLTRB(12, 8, 12, 24 + MediaQuery.paddingOf(context).bottom),
                    itemCount: units.length,
                    itemBuilder: (context, i) => UnitBlock(index: i + 1, offset: i * kUnit, convFrom: list.length, words: units[i], cols: cols, colors: ToeicWords.colors, labels: {for (final e in ToeicWords.labels.entries) e.key: tr(e.value)}),
                  );
                }),
              ),
            ]),
    );
  }

  static String _n(int v) => v.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
}

/// 뜻 고르기 퀴즈 — 영어 낱말을 보고 한국어 뜻 4개 중 고른다(한 판 10문제). 틀린 낱말은 성과에 쌓인다.
class ToeicQuizScreen extends StatefulWidget {
  final String group;
  /// 있으면 그 낱말만으로 바로 시작(복습 「틀린 단어 다시」).
  final List<String>? words;
  const ToeicQuizScreen({super.key, this.group = 'ALL', this.words});

  @override
  State<ToeicQuizScreen> createState() => _ToeicQuizScreenState();
}

class _ToeicQuizScreenState extends State<ToeicQuizScreen> {
  List<EnWord> _all = const [];
  List<QuizQuestion> _round = const [];
  int _pos = 0;
  int? _picked;
  int _right = 0;
  final List<EnWord> _missed = [];
  bool _finished = false;
  late String _group = widget.group;

  @override
  void initState() {
    super.initState();
    ToeicWords.load().then((w) {
      if (!mounted) return;
      _all = w;
      _start();
    });
  }

  @override
  void dispose() {
    TtsService.instance.stop();
    super.dispose();
  }

  void _start() {
    final only = widget.words?.toSet();
    final pool = only != null ? _all.where((w) => only.contains(w.word)).toList() : (_group == 'ALL' ? _all : _all.where((w) => w.level == _group).toList());
    setState(() {
      _round = buildRound(pool, all: _all, rng: Random());
      _pos = 0;
      _picked = null;
      _right = 0;
      _missed.clear();
      _finished = false;
    });
    if (_round.isNotEmpty) TtsService.instance.speak(_round.first.answer.word);
  }

  Future<void> _pick(int i) async {
    if (_picked != null) return;
    final q = _round[_pos];
    final ok = q.options[i].word == q.answer.word;
    setState(() {
      _picked = i;
      if (ok) {
        _right++;
      } else {
        _missed.add(q.answer);
      }
    });
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    if (_pos + 1 >= _round.length) {
      await AchievementService.instance.markWordQuiz(_right, _round.length, missed: _missed.map((w) => w.word).toList(), right: [for (final x in _round) if (!_missed.contains(x.answer)) x.answer.word]);
      if (mounted) setState(() => _finished = true);
      return;
    }
    setState(() {
      _pos++;
      _picked = null;
    });
    TtsService.instance.speak(_round[_pos].answer.word);
  }

  @override
  Widget build(BuildContext context) {
    final q = _round.isEmpty ? null : _round[_pos];
    return Scaffold(
      backgroundColor: AppColors.washi,
      appBar: AppBar(
        title: Text(tr('뜻 고르기 퀴즈'), style: const TextStyle(color: AppColors.sumi, fontSize: 16, fontWeight: FontWeight.w800)),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.tune, color: AppColors.beni),
            onSelected: (g) {
              _group = g;
              _start();
            },
            itemBuilder: (_) => [
              for (final g in ['ALL', ...ToeicWords.groups]) PopupMenuItem(value: g, child: Text(g == 'ALL' ? tr('전체') : tr(ToeicWords.labels[g]!))),
            ],
          ),
        ],
      ),
      body: q == null
          ? Center(child: _all.isEmpty ? const CircularProgressIndicator(color: AppColors.beni) : Text(tr('문제를 만들 낱말이 모자라요')))
          : _finished
              ? _Result(right: _right, total: _round.length, missed: _missed, onAgain: _start)
              : Padding(
                  padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + MediaQuery.paddingOf(context).bottom),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Text('${_pos + 1} / ${_round.length}', style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 18),
                    Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Flexible(child: GradText(q.answer.word, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, height: 1.1))),
                      const SizedBox(width: 8),
                      Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(q.answer.pos, style: const TextStyle(fontSize: 13, color: AppColors.muted, fontStyle: FontStyle.italic))),
                      IconButton(icon: const Icon(Icons.volume_up, color: AppColors.beni), onPressed: () => TtsService.instance.speak(q.answer.word)),
                    ]),
                    const SizedBox(height: 22),
                    for (var i = 0; i < q.options.length; i++) ...[
                      _Option(
                        text: q.options[i].ko,
                        state: _picked == null ? 0 : (q.options[i].word == q.answer.word ? 1 : (_picked == i ? 2 : 0)),
                        onTap: () => _pick(i),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ]),
                ),
    );
  }
}

class _Option extends StatelessWidget {
  final String text;
  final int state; // 0 보통 · 1 정답 · 2 내가 고른 오답
  final VoidCallback onTap;
  const _Option({required this.text, required this.state, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final c = switch (state) { 1 => AppColors.matcha, 2 => AppColors.sakuraDeep, _ => AppColors.line };
    return Material(
      color: state == 0 ? AppColors.washi : c.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(side: BorderSide(color: c, width: state == 0 ? 1 : 1.6), borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.sumi, height: 1.3)),
        ),
      ),
    );
  }
}

class _Result extends StatelessWidget {
  final int right, total;
  final List<EnWord> missed;
  final VoidCallback onAgain;
  const _Result({required this.right, required this.total, required this.missed, required this.onAgain});
  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(child: GradText('$right / $total', style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w900))),
          const SizedBox(height: 6),
          Center(child: Text(missed.isEmpty ? tr('다 맞혔어요!') : trf('틀린 낱말 {0}개 — 눌러서 다시 보기', [missed.length]), style: const TextStyle(fontSize: 13, color: AppColors.sumiLight))),
          const SizedBox(height: 16),
          for (final w in missed)
            ListTile(
              dense: true,
              title: Text(w.word, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.sumi)),
              subtitle: Text(w.ko, maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: const Icon(Icons.volume_up, size: 18, color: AppColors.beni),
              onTap: () => showWordSheet(context, w),
            ),
          const SizedBox(height: 16),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: AppColors.beni), onPressed: onAgain, child: Text(tr('한 판 더'))),
        ],
      );
}
