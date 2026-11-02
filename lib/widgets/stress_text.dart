import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme.dart';

/// 강세 표시 켬/끔(사용자 지시 2026-11-03 "영어 악센트 표시 도구, 표시·안 표시").
/// 리더 하단 「강세」 칩·카드 화면에서 바꾸고, 기기에 기억한다.
class StressPrefs {
  StressPrefs._();
  static const _key = 'stress_marks_on';
  static final ValueNotifier<bool> on = ValueNotifier(true);

  static Future<void> load() async {
    try {
      on.value = (await SharedPreferences.getInstance()).getBool(_key) ?? true;
    } catch (_) {}
  }

  static Future<void> toggle() async {
    on.value = !on.value;
    try {
      (await SharedPreferences.getInstance()).setBool(_key, on.value);
    } catch (_) {}
  }
}

/// 문장 강세 규칙(데이터 없이 글자만 보고) — UX 시안 01 ①.
/// - 내용어(명사·동사·형용사·부사·의문사·부정어)는 또렷하게 → 굵게
/// - 기능어(관사·전치사·대명사·조동사·be·접속사)는 약해진다 → 옅게
/// - 자음으로 끝난 낱말 + 모음으로 시작하는 낱말 → 이어 말하기 ‿
/// 사전·강세 데이터가 생기면 낱말 안의 강세 음절까지 바꿀 수 있게 이 파일 하나에 모아 둔다.
class EnglishStress {
  EnglishStress._();

  static const weak = <String>{
    'a', 'an', 'the',
    'to', 'of', 'for', 'at', 'in', 'on', 'by', 'from', 'with', 'as', 'into', 'about', 'than',
    'and', 'but', 'or', 'so', 'if', 'that', 'because',
    'i', 'you', 'he', 'she', 'it', 'we', 'they', 'me', 'him', 'her', 'us', 'them',
    'my', 'your', 'his', 'its', 'our', 'their',
    'is', 'am', 'are', 'was', 'were', 'be', 'been', 'being',
    'do', 'does', 'did', 'have', 'has', 'had',
    'can', 'could', 'will', 'would', 'shall', 'should', 'may', 'might', 'must',
    "i'm", "you're", "he's", "she's", "it's", "we're", "they're", "i'll", "you'll", "we'll", "they'll",
    "i've", "you've", "we've", "they've", "i'd", "you'd", "that's", 'gonna', 'wanna', 'gotta',
    'some', 'just', 'there',
  };

  /// 낱말 하나가 약해지는가(구두점 뗀 소문자 기준).
  static bool isWeak(String word) {
    if (RegExp(r'[0-9]').hasMatch(word)) return false; // 숫자는 또렷하게
    final w = word.toLowerCase().replaceAll(RegExp(r"[^a-z']"), '').replaceAll('’', "'");
    if (w.isEmpty) return true;
    return weak.contains(w);
  }

  static bool _endsConsonant(String word) {
    final w = word.toLowerCase().replaceAll(RegExp(r"[^a-z]"), '');
    if (w.isEmpty || RegExp(r'[^a-z]$').hasMatch(word.trimRight())) return false; // 쉼표·마침표 뒤는 끊어 읽기
    final last = w[w.length - 1];
    if (last == 'e' && w.length > 2 && !'aeiou'.contains(w[w.length - 2])) return true; // made·love: 묵음 e
    return !'aeiouyw'.contains(last);
  }

  static bool _startsVowel(String word) {
    final w = word.toLowerCase().replaceAll(RegExp(r"^[^a-z]+"), '');
    if (w.isEmpty) return false;
    if (w.startsWith('u') && (w.startsWith('use') || w.startsWith('usu') || w.startsWith('uni'))) return false; // you 소리
    if (w.startsWith('one') || w.startsWith('once')) return false;
    if (w.startsWith('hour') || w.startsWith('honest')) return true;
    return 'aeiou'.contains(w[0]);
  }

  /// 문장을 (낱말, 약함 여부, 뒤에 ‿ 여부) 목록으로.
  static List<({String word, bool weak, bool link})> analyze(String text) {
    final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    return [
      for (var i = 0; i < words.length; i++)
        (
          word: words[i],
          weak: isWeak(words[i]),
          link: i + 1 < words.length && _endsConsonant(words[i]) && _startsVowel(words[i + 1]),
        ),
    ];
  }
}

/// 영어 문장 — 강세 표시가 켜져 있으면 내용어 굵게 · 기능어 옅게 · 이어 말하기 ‿, 꺼져 있으면 그냥 글자.
class StressText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final TextAlign? textAlign;
  const StressText(this.text, {super.key, required this.style, this.textAlign});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: StressPrefs.on,
      builder: (context, on, _) {
        if (!on) return Text(text, style: style, textAlign: textAlign);
        final strong = style.copyWith(fontWeight: FontWeight.w900);
        final faint = style.copyWith(fontWeight: FontWeight.w500, color: AppColors.muted);
        final link = style.copyWith(fontWeight: FontWeight.w700, color: AppColors.kinDeep);
        final spans = <InlineSpan>[];
        final parts = EnglishStress.analyze(text);
        for (var i = 0; i < parts.length; i++) {
          final p = parts[i];
          spans.add(TextSpan(text: p.word, style: p.weak ? faint : strong));
          if (i + 1 < parts.length) spans.add(TextSpan(text: p.link ? '‿' : ' ', style: p.link ? link : style));
        }
        return Text.rich(TextSpan(children: spans), textAlign: textAlign);
      },
    );
  }
}
