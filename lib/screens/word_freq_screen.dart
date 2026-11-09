import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../core/l10n.dart';
import '../core/pane.dart';
import '../core/theme.dart';
import '../services/tts_service.dart';
import '../widgets/english_decor.dart';
import '../widgets/word_art_thumb.dart';
import 'word_quiz_screen.dart';
import '../core/embed_env.dart';

/// 화면에 보이는 빈도 순위 끝(사용자 지시 2026-11-07 — 2,000위에서 끊는다). 단어장 자체는 2,494어 그대로.
const kWordCap = 2000;

/// 한 단원 = 20어.
const kUnit = 20;

/// 절벽 단어 — 일본어앱 `word_freq_screen.dart` 구조(2026-11-07 개편): 20어 단원 + 네모 타일 + 회화 단어 포함 버튼.
/// 데이터 = `assets/data/words/en_words.csv`. R1 ≤189 · R2 ≤318 · R3 ≤825 · R4 ≤2,000(영어 목록에는 R5 가 없다).
/// 타일을 누르면 고른 발음(미국·영국·호주)으로 읽는다.
class WordFreqScreen extends StatefulWidget {
  const WordFreqScreen({super.key});

  @override
  State<WordFreqScreen> createState() => _WordFreqScreenState();
}

class EnWord {
  final int rank;
  final String word;
  final String ko;
  final String pos;
  final String level;
  final bool picturable;
  const EnWord({required this.rank, required this.word, required this.ko, required this.pos, required this.level, required this.picturable});
}

/// CSV 한 줄 → 칸(따옴표 안 쉼표 처리).
List<String> parseCsvLine(String line) {
  final out = <String>[];
  final buf = StringBuffer();
  var quoted = false;
  for (var i = 0; i < line.length; i++) {
    final c = line[i];
    if (quoted) {
      if (c == '"') {
        if (i + 1 < line.length && line[i + 1] == '"') {
          buf.write('"');
          i++;
        } else {
          quoted = false;
        }
      } else {
        buf.write(c);
      }
    } else if (c == '"') {
      quoted = true;
    } else if (c == ',') {
      out.add(buf.toString());
      buf.clear();
    } else {
      buf.write(c);
    }
  }
  out.add(buf.toString());
  return out;
}

class WordList {
  WordList._();
  static List<EnWord>? _cache;

  static Future<List<EnWord>> load() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString(assetPath('assets/data/words/en_words.csv'));
    final out = <EnWord>[];
    for (final line in raw.split('\n').skip(1)) {
      if (line.trim().isEmpty) continue;
      final c = parseCsvLine(line.trimRight());
      if (c.length < 8) continue;
      out.add(EnWord(rank: int.tryParse(c[0]) ?? 0, word: c[1], ko: c[3], pos: c[5], level: c[6], picturable: c[7] == 'Y'));
    }
    return _cache = out;
  }

  /// 「회화 단어 포함」 목록 — 레벨 'C'. 빈도표와 화면에서만 합친다(`tools/conv_words.py`).
  static Future<List<EnWord>> loadConv() async {
    try {
      return convFrom(await load(), await rootBundle.loadString(assetPath('assets/data/freq/conv_words_en.json')));
    } catch (_) {
      return const [];
    }
  }

  static List<EnWord> convFrom(List<EnWord> all, String raw) {
    final byWord = {for (final w in all.reversed) w.word.toLowerCase(): w};
    final out = <EnWord>[];
    for (final e in ((json.decode(raw) as Map<String, dynamic>)['words'] as List).cast<Map<String, dynamic>>()) {
      final w = byWord[(e['word'] as String).toLowerCase()];
      if (w != null) out.add(EnWord(rank: w.rank, word: w.word, ko: w.ko, pos: w.pos, level: 'C', picturable: w.picturable));
    }
    return out;
  }
}

/// 순서대로 [kUnit] 개씩 묶는다.
List<List<EnWord>> wordUnits(List<EnWord> words) => [
      for (var i = 0; i < words.length; i += kUnit) words.sublist(i, (i + kUnit).clamp(0, words.length)),
    ];

class _WordFreqScreenState extends State<WordFreqScreen> {
  List<EnWord> _words = const [];
  List<EnWord> _conv = const [];
  bool _loading = true;
  bool _withConv = false;
  String _filter = 'ALL';
  bool _pictureOnly = false;

  static const _levelColor = {
    'R1': AppColors.beni,
    'R2': AppColors.ai,
    'R3': AppColors.kinDeep,
    'R4': AppColors.matcha,
    'C': AppColors.sakuraDeep,
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await WordList.load();
    final conv = await WordList.loadConv();
    if (!mounted) return;
    setState(() {
      _words = all.where((w) => w.rank <= kWordCap).toList();
      _conv = conv;
      _loading = false;
    });
  }

  String _label(String lv) => switch (lv) { 'ALL' => tr('전체'), 'C' => tr('회화'), _ => lv };

  @override
  Widget build(BuildContext context) {
    final pool = _withConv ? [..._words, ..._conv] : _words;
    final list = pool.where((w) => (_filter == 'ALL' || w.level == _filter) && (!_pictureOnly || w.picturable)).toList();
    final units = wordUnits(list);
    final convFrom = list.where((w) => w.level != 'C').length; // 회화 구간이 시작하는 자리
    final levels = ['ALL', 'R1', 'R2', 'R3', 'R4', if (_withConv) 'C'];
    return Scaffold(
      backgroundColor: AppColors.washi,
      appBar: AppBar(
        title: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(tr('절벽 단어'), style: const TextStyle(color: AppColors.sumi, fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(trf('빈도 {0}위 · {1}어 단원 · 탭하면 발음', ['2,000', kUnit]), style: const TextStyle(color: AppColors.sumiLight, fontSize: 10, letterSpacing: 1)),
        ]),
        actions: [
          IconButton(
            tooltip: tr('그림 단어 퀴즈'),
            icon: const Icon(Icons.quiz_outlined, color: AppColors.beni),
            onPressed: () => openFull(context, (_) => WordQuizScreen(level: _filter == 'ALL' || _filter == 'C' ? 'R1' : _filter)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.beni))
          : Column(children: [
              Container(
                color: AppColors.washiDeep,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(children: [
                  Row(children: [
                    _ModeButton(
                      label: tr('절벽구간 단어만'),
                      selected: !_withConv,
                      onTap: () => setState(() {
                        _withConv = false;
                        if (_filter == 'C') _filter = 'ALL';
                      }),
                    ),
                    const SizedBox(width: 8),
                    _ModeButton(label: trf('회화 단어 포함 (+{0})', [_conv.length]), selected: _withConv, onTap: () => setState(() => _withConv = true)),
                  ]),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                      for (final lv in levels)
                        ChoiceChip(
                          label: Text(_label(lv)),
                          selected: _filter == lv,
                          onSelected: (_) => setState(() => _filter = lv),
                          selectedColor: (_levelColor[lv] ?? AppColors.sumi).withValues(alpha: 0.18),
                          labelStyle: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: _levelColor[lv] ?? AppColors.sumi),
                          showCheckmark: false,
                          visualDensity: VisualDensity.compact,
                        ),
                      FilterChip(
                        label: Text(tr('그림 단어만')),
                        selected: _pictureOnly,
                        onSelected: (v) => setState(() => _pictureOnly = v),
                        showCheckmark: false,
                        visualDensity: VisualDensity.compact,
                        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                    ]),
                  ),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Row(children: [
                  Text(trf('{0}개', [list.length]), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.sumi)),
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
                // 칸 수는 이 화면이 받은 너비로(두 화면이면 오른쪽 칸 너비)
                child: LayoutBuilder(builder: (context, c) {
                  final cols = (c.maxWidth / 112).floor().clamp(3, 8);
                  return ListView.builder(
                    padding: EdgeInsets.fromLTRB(12, 8, 12, 24 + MediaQuery.paddingOf(context).bottom),
                    itemCount: units.length,
                    itemBuilder: (context, i) => UnitBlock(index: i + 1, offset: i * kUnit, convFrom: convFrom, words: units[i], cols: cols, colors: _levelColor),
                  );
                }),
              ),
            ]),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ModeButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppColors.sumi : AppColors.washi,
              border: Border.all(color: selected ? AppColors.sumi : AppColors.line),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(label, style: TextStyle(color: selected ? AppColors.washi : AppColors.sumi, fontWeight: FontWeight.w700, fontSize: 12)),
          ),
        ),
      );
}

/// 한 단원 = 20어. 머리줄(단원 번호·순위 범위·구간) + 네모 타일 격자.
class UnitBlock extends StatelessWidget {
  final int index;
  final int offset;
  final int convFrom;
  final List<EnWord> words;
  final int cols;
  final Map<String, Color> colors;
  /// [labels] = 구간 코드 → 배지 글(없으면 코드 그대로). 토익 단어 화면도 쓴다.
  final Map<String, String> labels;
  const UnitBlock({super.key, required this.index, required this.offset, required this.convFrom, required this.words, required this.cols, required this.colors, this.labels = const {}});

  @override
  Widget build(BuildContext context) {
    final first = words.first;
    final conv = first.level == 'C';
    final color = colors[first.level] ?? AppColors.muted;
    final range = conv ? trf('회화 {0}-{1}', [offset - convFrom + 1, offset - convFrom + words.length]) : '#${first.rank}-${words.last.rank}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 6, 2, 6),
          child: Row(children: [
            Text(trf('{0}단원', [index]), style: const TextStyle(color: AppColors.sumi, fontSize: 14, fontWeight: FontWeight.w800)),
            const SizedBox(width: 8),
            Text(range, style: const TextStyle(color: AppColors.sumiLight, fontSize: 11)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
              child: Text(conv ? tr('회화') : (labels[first.level] ?? first.level), style: const TextStyle(color: AppColors.washi, fontSize: 10, fontWeight: FontWeight.w800)),
            ),
          ]),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: cols, mainAxisSpacing: 6, crossAxisSpacing: 6),
          itemCount: words.length,
          itemBuilder: (context, i) => WordTile(w: words[i], color: colors[words[i].level] ?? AppColors.muted),
        ),
      ]),
    );
  }
}

/// 네모 타일 — 순위 · 그림(있으면) · 단어 · 뜻 한 줄. 누르면 발음.
class WordTile extends StatelessWidget {
  final EnWord w;
  final Color color;
  const WordTile({super.key, required this.w, required this.color});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.washi,
      shape: RoundedRectangleBorder(side: BorderSide(color: color.withValues(alpha: 0.35)), borderRadius: BorderRadius.circular(10)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => TtsService.instance.speak(w.word),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(5, 4, 5, 5),
          child: Column(children: [
            Align(alignment: Alignment.centerLeft, child: Text(w.level == 'C' ? tr('회화') : '#${w.rank}', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color))),
            Expanded(
              child: Center(child: FittedBox(child: WordArtThumb(word: w.word, rank: w.rank, size: 46, fallback: const SizedBox(width: 46, height: 8)))),
            ),
            FittedBox(fit: BoxFit.scaleDown, child: Text(w.word, maxLines: 1, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.sumi))),
            Text(w.ko.split(RegExp(r'[,;·/]')).first.trim(), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: AppColors.sumiLight)),
          ]),
        ),
      ),
    );
  }
}
