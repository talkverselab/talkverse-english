import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/theme.dart';
import '../screens/word_freq_screen.dart' show EnWord;
import '../toeic/toeic_words.dart' show ToeicWords;
import '../services/tts_service.dart';
import 'english_decor.dart';
import 'word_art_thumb.dart';

/// 단어 시트 열기 — 문장 레마 칩·단어 목록에서 쓴다(2026-11-04).
Future<void> showWordSheet(BuildContext context, EnWord word) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.washi,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
    builder: (_) => WordSheet(word: word),
  );
}

/// 단어 1개 — 그림 · 낱말 · 품사 · 뜻 · 절벽 구간 · 순위, 듣기(고른 발음).
class WordSheet extends StatelessWidget {
  final EnWord word;
  const WordSheet({super.key, required this.word});

  @override
  Widget build(BuildContext context) {
    final w = word;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 14),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            WordArtThumb(
              word: w.word,
              rank: w.rank,
              size: 92,
              fallback: Container(
                width: 92,
                height: 92,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: AppColors.washiDeep, borderRadius: BorderRadius.circular(23)),
                child: Text(w.word.isEmpty ? '' : w.word[0].toUpperCase(), style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: AppColors.line)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Flexible(child: GradText(w.word, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, height: 1.1))),
                  const SizedBox(width: 8),
                  Padding(padding: const EdgeInsets.only(bottom: 4), child: Text(w.pos, style: const TextStyle(fontSize: 12, color: AppColors.muted, fontStyle: FontStyle.italic))),
                ]),
                const SizedBox(height: 6),
                Text(w.ko, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.sumi, height: 1.4)),
                const SizedBox(height: 8),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.beni.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                    child: Text(ToeicWords.labels[w.level] ?? w.level, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: AppColors.beni)),
                  ),
                  const SizedBox(width: 8),
                  Text(w.level.startsWith('R') || w.level == 'C' ? trf('빈도 {0}위', [w.rank]) : trf('토익 {0}번', [w.rank]), style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                ]),
              ]),
            ),
          ]),
          const SizedBox(height: 16),
          const BrushDivider(height: 2),
          const SizedBox(height: 12),
          Row(children: [
            ValueListenableBuilder<EnAccent>(
              valueListenable: AccentPrefs.accent,
              builder: (_, a, _) => FilledButton.icon(
                onPressed: () => TtsService.instance.speak(w.word),
                icon: const Icon(Icons.volume_up, size: 18),
                label: Text(trf('{0} 발음 듣기', [a.label])),
                style: FilledButton.styleFrom(backgroundColor: AppColors.beni),
              ),
            ),
            const SizedBox(width: 10),
            ActionChip(label: Text(tr('발음 바꾸기')), onPressed: AccentPrefs.next, visualDensity: VisualDensity.compact),
          ]),
        ]),
      ),
    );
  }
}
