import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/theme.dart';
import '../screens/word_freq_screen.dart' show EnWord, WordList;
import '../services/dialogue_service.dart';
import 'word_sheet.dart';

/// 문장의 내용어(레마) 칩 — 단어장(절벽 단어 2,494어)에 있는 말은 누르면 단어 시트, 없는 말은 회색
/// (사용자 지시 2026-11-04 "문장 레마별로 단어장이랑 연결"). 같은 기본형은 한 번만.
/// 레마는 `tools/add_lemmas.py` 가 편 JSON 의 턴에 `lemmas: [[표면형, 기본형, 읽기]]` 로 넣고,
/// 단어장에 없는 레마는 `data/review/write/missing_lemmas.csv` 로 uk 세션에 넘긴다(단어·그림 제작).
class LemmaChips extends StatelessWidget {
  final DialogueTurn turn;
  final bool compact;
  const LemmaChips({super.key, required this.turn, this.compact = false});

  /// 기본형(소문자) → 단어장 항목(빈도 높은 것). 테스트에서도 쓴다.
  static Map<String, EnWord> lookup(List<EnWord> words, Iterable<String> bases) {
    final want = {for (final b in bases) b.toLowerCase().trim()}..remove('');
    final out = <String, EnWord>{};
    for (final w in words) {
      final k = w.word.toLowerCase();
      if (want.contains(k) && !out.containsKey(k)) out[k] = w; // CSV 는 빈도순이라 처음 것이 가장 흔한 뜻
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final seen = <String>{};
    final lemmas = [
      for (final l in turn.lemmas)
        if (seen.add(l.base.toLowerCase())) l,
    ];
    if (lemmas.isEmpty) return const SizedBox.shrink();
    return FutureBuilder<List<EnWord>>(
      key: ValueKey('${turn.num}:${turn.tl}'),
      future: WordList.load(),
      builder: (context, snap) {
        final found = snap.data == null ? const <String, EnWord>{} : lookup(snap.data!, lemmas.map((l) => l.base));
        return Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final l in lemmas) _Chip(label: l.base, gloss: found[l.base.toLowerCase()]?.ko, compact: compact, onTap: found[l.base.toLowerCase()] == null ? null : () => showWordSheet(context, found[l.base.toLowerCase()]!)),
            if (snap.connectionState == ConnectionState.done && found.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(tr('단어장에 없는 말'), style: const TextStyle(fontSize: 10, color: AppColors.muted)),
              ),
          ],
        );
      },
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final String? gloss;
  final bool compact;
  final VoidCallback? onTap;
  const _Chip({required this.label, this.gloss, this.compact = false, this.onTap});
  @override
  Widget build(BuildContext context) {
    final on = onTap != null;
    // 회색 칩도 탭을 삼킨다 — 안 그러면 바깥 카드의 탭(뒤집기)으로 넘어간다.
    return GestureDetector(
      onTap: on ? null : () {},
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: compact ? 7 : 9, vertical: compact ? 3 : 4),
          decoration: BoxDecoration(
            color: on ? AppColors.washi : AppColors.washiDeep,
            border: Border.all(color: on ? AppColors.beni.withValues(alpha: 0.7) : AppColors.line),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: compact ? 12 : 13.5, fontWeight: FontWeight.w800, color: on ? AppColors.sumi : AppColors.muted),
              ),
              if (gloss != null && gloss!.isNotEmpty) ...[
                const SizedBox(width: 5),
                Text(
                  gloss!.split(RegExp(r'[,;·/]')).first.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: compact ? 10 : 11, color: AppColors.sumiLight),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
