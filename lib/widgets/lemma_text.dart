import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../screens/word_freq_screen.dart' show EnWord, WordList;
import '../services/dialogue_service.dart';
import 'lemma_chips.dart';
import 'stress_text.dart';
import 'word_sheet.dart';

/// 회화 문장 — 낱말을 누르면 단어 시트(사용자 지시 2026-11-07, 일본어앱 문장 레마 탭과 같은 구조).
/// 단어장에 있는 레마만 밑줄(ai)·탭. 강세 표시 켬/끔은 [StressText] 와 같다. 레마가 없으면 그냥 [StressText].
class LemmaText extends StatefulWidget {
  final String text;
  final List<Lemma> lemmas;
  final TextStyle style;
  const LemmaText(this.text, {super.key, required this.lemmas, required this.style});

  /// 문장 낱말에서 앞뒤 구두점을 뗀 소문자(레마 표면형과 비교용).
  static String bare(String word) => word.replaceAll('’', "'").replaceAll(RegExp(r"^[^A-Za-z']+|[^A-Za-z']+$"), '').toLowerCase();

  /// 표면형(소문자) → 단어장 항목.
  static Map<String, EnWord> linked(List<EnWord> words, List<Lemma> lemmas) {
    final found = LemmaChips.lookup(words, lemmas.map((l) => l.base));
    return {
      for (final l in lemmas)
        if (found[l.base.toLowerCase()] != null) bare(l.surface): found[l.base.toLowerCase()]!,
    };
  }

  @override
  State<LemmaText> createState() => _LemmaTextState();
}

class _LemmaTextState extends State<LemmaText> {
  Map<String, EnWord> _linked = const {};
  final _taps = <TapGestureRecognizer>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(LemmaText old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text || old.lemmas != widget.lemmas) _load();
  }

  Future<void> _load() async {
    if (widget.lemmas.isEmpty) return;
    final words = await WordList.load();
    if (mounted) setState(() => _linked = LemmaText.linked(words, widget.lemmas));
  }

  void _clearTaps() {
    for (final r in _taps) {
      r.dispose();
    }
    _taps.clear();
  }

  @override
  void dispose() {
    _clearTaps();
    super.dispose();
  }

  TextSpan _word(String word, TextStyle s) {
    final w = _linked[LemmaText.bare(word)];
    if (w == null) return TextSpan(text: word, style: s);
    final tap = TapGestureRecognizer()..onTap = () => showWordSheet(context, w);
    _taps.add(tap);
    return TextSpan(
      text: word,
      style: s.copyWith(decoration: TextDecoration.underline, decorationColor: AppColors.ai, decorationThickness: 1.6),
      recognizer: tap,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.lemmas.isEmpty) return StressText(widget.text, style: widget.style);
    return ValueListenableBuilder<bool>(
      valueListenable: StressPrefs.on,
      builder: (context, on, _) {
        _clearTaps();
        return Text.rich(TextSpan(children: StressText.spans(widget.text, widget.style, on, word: _word)));
      },
    );
  }
}
