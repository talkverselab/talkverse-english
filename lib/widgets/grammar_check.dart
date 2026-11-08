import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/theme.dart';
import '../services/dialogue_service.dart';
import 'gram_note.dart';

/// 토익 회화 끝의 문법 카드 — 이 편의 문법 포인트(빨간 글씨) + 대사에서 뽑은 빈칸 문제 1개(Part 5 식 4지선다).
/// 회화를 읽으며 익힌 문법을 바로 확인한다(사용자 지시 2026-11-08 "회화를 하면서 자연스럽게 토익 문법을 익히는 거야").
class GrammarCheckCard extends StatefulWidget {
  final Dialogue dialogue;
  const GrammarCheckCard({super.key, required this.dialogue});

  @override
  State<GrammarCheckCard> createState() => _GrammarCheckCardState();
}

class _GrammarCheckCardState extends State<GrammarCheckCard> {
  int? _picked;

  @override
  Widget build(BuildContext context) {
    final g = widget.dialogue.grammar;
    final c = widget.dialogue.check;
    if (g == null && c == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: GramNote.red.withValues(alpha: 0.04), border: Border.all(color: GramNote.red.withValues(alpha: 0.5)), borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (g != null) ...[
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: GramNote.red, borderRadius: BorderRadius.circular(6)),
              child: Text(tr('이 편의 문법'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white)),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(g.point, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: GramNote.red))),
          ]),
          if (g.ko.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text(g.ko, style: const TextStyle(fontSize: 12, color: GramNote.red, height: 1.45))),
        ],
        if (c != null) ...[
          const SizedBox(height: 10),
          Text(tr('빈칸에 알맞은 것은?'), style: const TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(c.q, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.sumi, height: 1.4)),
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (var i = 0; i < c.options.length; i++)
              ChoiceChip(
                label: Text('${'ABCD'[i]}  ${c.options[i]}'),
                selected: _picked == i,
                onSelected: _picked == null ? (_) => setState(() => _picked = i) : null,
                showCheckmark: false,
                selectedColor: (i == c.answer ? AppColors.matcha : GramNote.red).withValues(alpha: 0.15),
                side: BorderSide(color: _picked == null ? AppColors.line : (i == c.answer ? AppColors.matcha : (_picked == i ? GramNote.red : AppColors.line))),
                labelStyle: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: _picked != null && i == c.answer ? AppColors.matcha : AppColors.sumi),
                visualDensity: VisualDensity.compact,
              ),
          ]),
          if (_picked != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _picked == c.answer ? tr('정답! 회화에서 본 그 자리예요.') : trf('정답은 {0}. 회화의 그 줄을 다시 보세요.', ['ABCD'[c.answer]]),
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _picked == c.answer ? AppColors.matcha : GramNote.red),
              ),
            ),
        ],
      ]),
    );
  }
}
