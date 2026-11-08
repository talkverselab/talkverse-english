import 'package:flutter/material.dart';

import '../services/dialogue_service.dart';

/// 토익 회화 줄 아래 문법 메모 — 빨간 글씨(사용자 지시 2026-11-08 "문법 내용은 회화문 밑에 적어주고 빨간색 표시").
class GramNote extends StatelessWidget {
  final GramMark? gram;
  final double size;
  const GramNote(this.gram, {super.key, this.size = 11.5});

  static const red = Color(0xFFD12F2F);

  @override
  Widget build(BuildContext context) {
    final n = gram?.note ?? '';
    if (n.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text('§ $n', style: TextStyle(fontSize: size, color: red, fontWeight: FontWeight.w700, height: 1.35)),
    );
  }
}
