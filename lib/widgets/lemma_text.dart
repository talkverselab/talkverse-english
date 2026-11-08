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
  /// 토익 문법 표시(사용자 지시 2026-11-08): [GramMark.underline] 구간은 빨간 밑줄, [GramMark.red] 레마는 빨간 글자. 단어장 밑줄(파랑)보다 우선.
  final GramMark? gram;
  const LemmaText(this.text, {super.key, required this.lemmas, required this.style, this.gram});

  /// 문법 밑줄 구간의 글자 범위(대소문자 무시, 같은 구간이 여러 번이면 전부).
  static List<(int, int)> gramRanges(String text, GramMark? g) {
    if (g == null) return const [];
    final low = text.toLowerCase();
    final out = <(int, int)>[];
    for (final u in g.underline) {
      final needle = u.toLowerCase();
      if (needle.isEmpty) continue;
      var from = 0;
      while (true) {
        final i = low.indexOf(needle, from);
        if (i < 0) break;
        out.add((i, i + needle.length));
        from = i + needle.length;
      }
    }
    return out;
  }

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

  static const _red = Color(0xFFD12F2F);
  List<(int, int)> _ranges = const [];
  Set<String> _reds = const {};
  int _cursor = 0; // 낱말이 문장에서 나온 자리를 차례로 따라간다(StressText.spans 가 왼쪽부터 부른다)

  TextSpan _word(String word, TextStyle s) {
    final w = _linked[LemmaText.bare(word)];
    final at = widget.text.indexOf(word, _cursor);
    if (at >= 0) _cursor = at + word.length;
    final inGram = at >= 0 && _ranges.any((r) => at >= r.$1 && at < r.$2);
    final isRed = _reds.contains(LemmaText.bare(word)) && (inGram || _ranges.isEmpty);
    var style = s;
    if (isRed) style = style.copyWith(color: _red, fontWeight: FontWeight.w900);
    if (inGram) {
      style = style.copyWith(decoration: TextDecoration.underline, decorationColor: _red, decorationThickness: 2.2);
    } else if (w != null) {
      style = style.copyWith(decoration: TextDecoration.underline, decorationColor: AppColors.ai, decorationThickness: 1.6);
    }
    if (w == null) return TextSpan(text: word, style: style);
    final tap = TapGestureRecognizer()..onTap = () => showWordSheet(context, w);
    _taps.add(tap);
    return TextSpan(text: word, style: style, recognizer: tap);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.lemmas.isEmpty && (widget.gram == null || widget.gram!.isEmpty)) return StressText(widget.text, style: widget.style);
    return ValueListenableBuilder<bool>(
      valueListenable: StressPrefs.on,
      builder: (context, on, _) {
        _clearTaps();
        _ranges = LemmaText.gramRanges(widget.text, widget.gram);
        _reds = {for (final r in widget.gram?.red ?? const <String>[]) for (final w in r.split(' ')) LemmaText.bare(w)}; // 'not only' 처럼 여러 낱말이면 낱말마다
        _cursor = 0;
        return Text.rich(TextSpan(children: StressText.spans(widget.text, widget.style, on, word: _word)));
      },
    );
  }
}
