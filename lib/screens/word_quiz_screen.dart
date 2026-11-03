import 'dart:math';

import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/theme.dart';
import '../services/achievement_service.dart';
import '../services/art_service.dart';
import '../services/tts_service.dart';
import '../widgets/english_decor.dart';
import '../widgets/word_art_thumb.dart';
import 'word_freq_screen.dart';

/// 그림 단어 퀴즈 — 그림을 보고 영어 낱말을 고른다(4지선다, 한 판 10문제). 2026-11-03.
/// 풀 = 절벽 단어 목록(`en_words.csv`) 중 **그림으로 그릴 수 있는 낱말(picturable=Y)** 이면서 단어 그림(`art/en/manifest`)이 있는 것.
/// (here·once 같은 추상어는 그림이 있어도 뺀다 — 그림만 보고 맞힐 수 있어야 한다.)
/// 맞으면 그 낱말을 고른 발음으로 읽어 주고, 틀리면 정답과 뜻을 보여 준다. 끝나면 성과(단어 그림 맞음)에 기록하고
/// 틀린 낱말은 복습 탭 「틀린 단어 다시」에 쌓인다.
class WordQuizScreen extends StatefulWidget {
  /// 처음 고른 구간(R1~R4·ALL). [words] 가 있으면 그 낱말만으로 바로 시작(복습 「틀린 단어 다시」).
  final String level;
  final List<String>? words;
  const WordQuizScreen({super.key, this.level = 'R1', this.words});

  static const roundSize = 10;
  static const choices = 4;

  @override
  State<WordQuizScreen> createState() => _WordQuizScreenState();
}

/// 한 문제: 정답 낱말 + 보기(정답 포함, 섞음).
class QuizQuestion {
  final EnWord answer;
  final List<EnWord> options;
  const QuizQuestion({required this.answer, required this.options});
}

/// 풀에서 한 판을 만든다(순수 함수 — 테스트용으로 밖에 둔다).
/// 보기는 같은 품사의 낱말을 먼저 쓰고 모자라면 아무 낱말로 채운다.
List<QuizQuestion> buildRound(List<EnWord> pool, {List<EnWord>? all, int size = WordQuizScreen.roundSize, int choices = WordQuizScreen.choices, Random? rng}) {
  final r = rng ?? Random();
  final distractorPool = (all == null || all.length < pool.length) ? pool : all;
  if (pool.isEmpty || distractorPool.length < 2) return const [];
  final picked = List<EnWord>.of(pool)..shuffle(r);
  final out = <QuizQuestion>[];
  for (final ans in picked.take(size)) {
    final same = distractorPool.where((w) => w.word != ans.word && w.pos == ans.pos).toList()..shuffle(r);
    final others = distractorPool.where((w) => w.word != ans.word && w.pos != ans.pos).toList()..shuffle(r);
    final opts = <EnWord>[ans, ...same.take(choices - 1)];
    for (final w in others) {
      if (opts.length >= choices) break;
      opts.add(w);
    }
    opts.shuffle(r);
    out.add(QuizQuestion(answer: ans, options: opts));
  }
  return out;
}

class _WordQuizScreenState extends State<WordQuizScreen> {
  static const _levels = ['R1', 'R2', 'R3', 'R4', 'ALL'];
  List<EnWord> _all = const []; // 그림 있는 낱말 전부
  bool _loading = true;
  late String _level = widget.level;

  List<QuizQuestion> _round = const [];
  int _pos = 0;
  int? _picked; // 이번 문제에서 고른 보기 번호
  int _right = 0;
  final List<EnWord> _missed = [];
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final words = await WordList.load();
    await ArtService.instance.ensureLoaded();
    final withArt = words.where((w) => w.picturable && ArtService.instance.hasArt(w.word, rank: w.rank)).toList();
    if (!mounted) return;
    setState(() {
      _all = withArt;
      _loading = false;
    });
    if (widget.words != null) _start(only: widget.words);
  }

  @override
  void dispose() {
    TtsService.instance.stop();
    super.dispose();
  }

  List<EnWord> _pool({List<String>? only}) {
    if (only != null) {
      final set = only.toSet();
      return _all.where((w) => set.contains(w.word)).toList();
    }
    return _all.where((w) => _level == 'ALL' || w.level == _level).toList();
  }

  void _start({List<String>? only}) {
    final pool = _pool(only: only);
    setState(() {
      _round = buildRound(pool, all: _all);
      _pos = 0;
      _picked = null;
      _right = 0;
      _missed.clear();
      _finished = false;
    });
  }

  void _pick(int i) {
    if (_picked != null) return;
    final q = _round[_pos];
    final ok = q.options[i].word == q.answer.word;
    setState(() => _picked = i);
    if (ok) {
      _right++;
    } else {
      _missed.add(q.answer);
    }
    TtsService.instance.speak(q.answer.word);
  }

  Future<void> _next() async {
    if (_pos < _round.length - 1) {
      setState(() {
        _pos++;
        _picked = null;
      });
      return;
    }
    final rightWords = [for (final q in _round) if (!_missed.contains(q.answer)) q.answer.word];
    await AchievementService.instance.markWordQuiz(_right, _round.length, missed: [for (final w in _missed) w.word], right: rightWords);
    if (mounted) setState(() => _finished = true);
  }

  @override
  Widget build(BuildContext context) {
    final inRound = _round.isNotEmpty && !_finished;
    return Scaffold(
      backgroundColor: AppColors.washi,
      appBar: AppBar(
        title: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(tr('그림 단어 퀴즈'), style: const TextStyle(color: AppColors.sumi, fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(
            inRound ? '${_pos + 1} / ${_round.length}' : tr('그림 보고 낱말 고르기'),
            style: const TextStyle(color: AppColors.sumiLight, fontSize: 10, letterSpacing: 1),
          ),
        ]),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.beni))
          : _finished
              ? _Result(right: _right, total: _round.length, missed: _missed, onRetry: _missed.isEmpty ? null : () => _start(only: [for (final w in _missed) w.word]), onAgain: () => _start(only: widget.words), onClose: () => Navigator.of(context).maybePop())
              : inRound
                  ? _Question(q: _round[_pos], picked: _picked, onPick: _pick, onNext: _next, last: _pos == _round.length - 1)
                  : _Start(levels: _levels, level: _level, count: _pool().length, onLevel: (lv) => setState(() => _level = lv), onStart: _pool().length >= 2 ? () => _start() : null),
    );
  }
}

/// 시작 칸 — 구간 고르기 + 풀 크기 + 시작.
class _Start extends StatelessWidget {
  final List<String> levels;
  final String level;
  final int count;
  final ValueChanged<String> onLevel;
  final VoidCallback? onStart;
  const _Start({required this.levels, required this.level, required this.count, required this.onLevel, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + MediaQuery.paddingOf(context).bottom),
      children: [
        EnglishCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(tr('그림을 보고 영어 낱말을 고르세요'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.sumi)),
            const SizedBox(height: 6),
            Text(tr('한 판 10문제 · 보기 4개 · 맞으면 고른 발음으로 읽어 줘요. 틀린 낱말은 복습 탭에 쌓여요.'),
                style: const TextStyle(fontSize: 12.5, color: AppColors.sumiLight, height: 1.5)),
            const SizedBox(height: 14),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final lv in levels)
                ChoiceChip(
                  label: Text(lv == 'ALL' ? tr('전체') : lv),
                  selected: level == lv,
                  onSelected: (_) => onLevel(lv),
                  selectedColor: AppColors.beni.withValues(alpha: 0.18),
                  labelStyle: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: level == lv ? AppColors.beni : AppColors.sumi),
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                ),
            ]),
            const SizedBox(height: 10),
            Text(count == 0 ? tr('이 구간엔 아직 그림 단어가 없어요(그림을 받는 중이면 잠시 뒤 다시).') : trf('그림 단어 {0}개', [count]),
                style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(tr('시작')),
              style: FilledButton.styleFrom(backgroundColor: AppColors.beni, padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12)),
            ),
          ]),
        ),
      ],
    );
  }
}

/// 문제 한 장 — 위 그림, 아래 보기 4개. 고르면 정답 초록·오답 빨강, 뜻 한 줄, 「다음」.
class _Question extends StatelessWidget {
  final QuizQuestion q;
  final int? picked;
  final ValueChanged<int> onPick;
  final VoidCallback onNext;
  final bool last;
  const _Question({required this.q, required this.picked, required this.onPick, required this.onNext, required this.last});

  @override
  Widget build(BuildContext context) {
    final answered = picked != null;
    final correct = answered && q.options[picked!].word == q.answer.word;
    return LayoutBuilder(builder: (context, c) {
      final wide = c.maxWidth >= 700;
      final artSize = min(wide ? c.maxHeight - 160 : c.maxWidth - 48, 360.0).clamp(160.0, 360.0);
      final art = Center(
        child: WordArtThumb(
          key: ValueKey('quiz:${q.answer.rank}'),
          word: q.answer.word,
          rank: q.answer.rank,
          size: artSize,
          fit: BoxFit.contain,
          fallback: Container(
            width: artSize,
            height: artSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.washiDeep, borderRadius: BorderRadius.circular(artSize * 0.25)),
            child: const Icon(Icons.image_not_supported_outlined, color: AppColors.line, size: 48),
          ),
        ),
      );
      final options = Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(tr('이 그림은 무엇일까요?'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.muted)),
        const SizedBox(height: 10),
        for (var i = 0; i < q.options.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _Choice(
              key: ValueKey('choice_$i'),
              word: q.options[i].word,
              state: !answered
                  ? _ChoiceState.idle
                  : q.options[i].word == q.answer.word
                      ? _ChoiceState.right
                      : (i == picked ? _ChoiceState.wrong : _ChoiceState.dim),
              onTap: answered ? null : () => onPick(i),
            ),
          ),
        const SizedBox(height: 4),
        AnimatedOpacity(
          opacity: answered ? 1 : 0,
          duration: const Duration(milliseconds: 200),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(
              answered ? '${correct ? tr('맞았어요!') : tr('정답은')} ${q.answer.word} · ${q.answer.ko}' : ' ',
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: correct ? AppColors.matcha : AppColors.sakuraDeep, height: 1.4),
            ),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              OutlinedButton.icon(
                onPressed: answered ? () => TtsService.instance.speak(q.answer.word) : null,
                icon: const Icon(Icons.volume_up, size: 18),
                label: Text(tr('다시 듣기')),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: answered ? onNext : null,
                icon: Icon(last ? Icons.flag_rounded : Icons.arrow_forward_rounded, size: 18),
                label: Text(last ? tr('결과 보기') : tr('다음')),
                style: FilledButton.styleFrom(backgroundColor: AppColors.beni),
              ),
            ]),
          ]),
        ),
      ]);
      return SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + MediaQuery.paddingOf(context).bottom),
        child: wide
            ? Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                Expanded(flex: 5, child: art),
                const SizedBox(width: 20),
                Expanded(flex: 6, child: options),
              ])
            : Column(children: [art, const SizedBox(height: 16), options]),
      );
    });
  }
}

enum _ChoiceState { idle, right, wrong, dim }

class _Choice extends StatelessWidget {
  final String word;
  final _ChoiceState state;
  final VoidCallback? onTap;
  const _Choice({super.key, required this.word, required this.state, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      _ChoiceState.right => AppColors.matcha,
      _ChoiceState.wrong => AppColors.sakuraDeep,
      _ChoiceState.dim => AppColors.line,
      _ChoiceState.idle => AppColors.line,
    };
    final textColor = state == _ChoiceState.dim ? AppColors.muted : AppColors.sumi;
    return Material(
      color: state == _ChoiceState.right
          ? AppColors.matcha.withValues(alpha: 0.08)
          : state == _ChoiceState.wrong
              ? AppColors.sakuraDeep.withValues(alpha: 0.08)
              : AppColors.washi,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(border: Border.all(color: color, width: state == _ChoiceState.idle || state == _ChoiceState.dim ? 1 : 2), borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            Expanded(child: Text(word, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: textColor))),
            if (state == _ChoiceState.right) const Icon(Icons.check_circle, color: AppColors.matcha, size: 20),
            if (state == _ChoiceState.wrong) const Icon(Icons.cancel, color: AppColors.sakuraDeep, size: 20),
          ]),
        ),
      ),
    );
  }
}

/// 결과 — 맞음 n/10 문장, 틀린 낱말 목록(그림·뜻), 「틀린 것만 다시」·「한 판 더」·「닫기」.
class _Result extends StatelessWidget {
  final int right;
  final int total;
  final List<EnWord> missed;
  final VoidCallback? onRetry;
  final VoidCallback onAgain;
  final VoidCallback onClose;
  const _Result({required this.right, required this.total, required this.missed, required this.onRetry, required this.onAgain, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final line = right == total
        ? tr('전부 맞았어요. 그림이 낱말로 바로 떠오르네요.')
        : right >= total * 0.7
            ? tr('거의 다 맞았어요. 틀린 것만 한 번 더 보면 돼요.')
            : tr('처음 보는 낱말이 많았죠? 틀린 것만 다시 풀어 보세요.');
    return ListView(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + MediaQuery.paddingOf(context).bottom),
      children: [
        EnglishCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(trf('맞음 {0} / {1}', [right, total]), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.beni)),
            const SizedBox(height: 6),
            Text(line, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.sumi, height: 1.4)),
            const SizedBox(height: 14),
            Wrap(spacing: 10, runSpacing: 8, children: [
              if (onRetry != null)
                FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.replay_rounded, size: 18), label: Text(trf('틀린 것만 다시 ({0})', [missed.length])), style: FilledButton.styleFrom(backgroundColor: AppColors.beni)),
              OutlinedButton.icon(onPressed: onAgain, icon: const Icon(Icons.shuffle_rounded, size: 18), label: Text(tr('한 판 더'))),
              TextButton(onPressed: onClose, child: Text(tr('닫기'))),
            ]),
          ]),
        ),
        if (missed.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(tr('틀린 낱말'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.muted, letterSpacing: 1)),
          const SizedBox(height: 8),
          for (final w in missed)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => TtsService.instance.speak(w.word),
                borderRadius: BorderRadius.circular(12),
                child: Row(children: [
                  WordArtThumb(word: w.word, rank: w.rank, size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(w.word, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.sumi)),
                      Text(w.ko, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, color: AppColors.sumiLight)),
                    ]),
                  ),
                  const Icon(Icons.volume_up, size: 18, color: AppColors.beni),
                ]),
              ),
            ),
          const BrushDivider(height: 2),
        ],
      ],
    );
  }
}
