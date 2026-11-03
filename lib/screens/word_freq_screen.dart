import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../core/l10n.dart';
import '../core/pane.dart';
import '../core/theme.dart';
import '../services/tts_service.dart';
import '../widgets/english_decor.dart';
import '../widgets/word_art_thumb.dart';
import 'word_quiz_screen.dart';

/// 절벽 단어 R1~R4 — 일본어앱 `word_freq_screen.dart` 를 영어앱에 맞춤(2026-11-03).
/// 데이터 = `assets/data/words/en_words.csv`(2,494어, 그림 단어 목록과 같은 순위·뜻).
/// R1 ≤189 · R2 ≤318 · R3 ≤825 · R4 나머지(누적 55·60·70·80%). 줄을 누르면 고른 발음(미국·영국·호주)으로 읽는다.
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
    final raw = await rootBundle.loadString('assets/data/words/en_words.csv');
    final out = <EnWord>[];
    for (final line in raw.split('\n').skip(1)) {
      if (line.trim().isEmpty) continue;
      final c = parseCsvLine(line.trimRight());
      if (c.length < 8) continue;
      out.add(EnWord(rank: int.tryParse(c[0]) ?? 0, word: c[1], ko: c[3], pos: c[5], level: c[6], picturable: c[7] == 'Y'));
    }
    return _cache = out;
  }
}

class _WordFreqScreenState extends State<WordFreqScreen> {
  List<EnWord> _words = const [];
  bool _loading = true;
  String _filter = 'R1';
  bool _pictureOnly = false;

  static const _levels = ['R1', 'R2', 'R3', 'R4', 'ALL'];
  static const _levelColor = {
    'R1': AppColors.beni,
    'R2': AppColors.ai,
    'R3': AppColors.kinDeep,
    'R4': AppColors.matcha,
  };

  @override
  void initState() {
    super.initState();
    WordList.load().then((w) {
      if (!mounted) return;
      setState(() {
        _words = w;
        _loading = false;
      });
    });
  }

  String _label(String lv) => lv == 'ALL' ? tr('전체') : lv;

  @override
  Widget build(BuildContext context) {
    final list = _words.where((w) => (_filter == 'ALL' || w.level == _filter) && (!_pictureOnly || w.picturable)).toList();
    return Scaffold(
      backgroundColor: AppColors.washi,
      appBar: AppBar(
        title: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(tr('절벽 단어 R1~R4'), style: const TextStyle(color: AppColors.sumi, fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(tr('많이 쓰는 순서 · 누르면 발음'), style: const TextStyle(color: AppColors.sumiLight, fontSize: 10, letterSpacing: 1)),
        ]),
        actions: [
          IconButton(
            tooltip: tr('그림 단어 퀴즈'),
            icon: const Icon(Icons.quiz_outlined, color: AppColors.beni),
            onPressed: () => openFull(context, (_) => WordQuizScreen(level: _filter)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.beni))
          : Column(children: [
              Container(
                color: AppColors.washiDeep,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                  for (final lv in _levels)
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
                child: ListView.separated(
                  padding: EdgeInsets.only(bottom: 24 + MediaQuery.paddingOf(context).bottom),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const Divider(height: 1, indent: 16, endIndent: 16),
                  itemBuilder: (context, i) => _WordRow(w: list[i], color: _levelColor[list[i].level] ?? AppColors.muted),
                ),
              ),
            ]),
    );
  }
}

class _WordRow extends StatelessWidget {
  final EnWord w;
  final Color color;
  const _WordRow({required this.w, required this.color});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => TtsService.instance.speak(w.word),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          WordArtThumb(
            word: w.word,
            rank: w.rank,
            size: 52,
            fallback: Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: AppColors.washiDeep, borderRadius: BorderRadius.circular(13)),
              child: Text(w.word.isEmpty ? '' : w.word[0].toUpperCase(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.line)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(child: Text(w.word, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.sumi))),
                const SizedBox(width: 6),
                Text(w.pos, style: const TextStyle(fontSize: 10.5, color: AppColors.muted, fontStyle: FontStyle.italic)),
              ]),
              const SizedBox(height: 2),
              Text(w.ko, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: AppColors.sumiLight, height: 1.3)),
            ]),
          ),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
              child: Text(w.level, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color)),
            ),
            const SizedBox(height: 4),
            Text('#${w.rank}', style: const TextStyle(fontSize: 10, color: AppColors.muted)),
          ]),
          const SizedBox(width: 4),
          const Icon(Icons.volume_up, size: 18, color: AppColors.beni),
        ]),
      ),
    );
  }
}
