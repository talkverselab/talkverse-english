import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../core/theme.dart';
import '../screens/word_freq_screen.dart' show EnWord;
import '../core/embed_env.dart';

/// 토익 단어 목록 — `assets/data/toeic/toeic_words.json`(`tools/toeic_words.py`). 앱내앱 「토익」 첫 기능(사용자 지시 2026-11-08).
/// 절벽 단어 화면의 EnWord 로 바꿔 같은 타일·단어 시트·퀴즈 부품을 쓴다: rank = 토익 번호, level = 묶음(A·N·V·ADJ·ADV).
class ToeicWords {
  static Future<List<EnWord>>? _cache;

  static const labels = {'A': '기본 빈도어', 'N': '명사', 'V': '동사', 'ADJ': '형용사', 'ADV': '부사', 'I': '관용표현'};
  static const colors = {'A': AppColors.beni, 'N': AppColors.ai, 'V': AppColors.matcha, 'ADJ': AppColors.kinDeep, 'ADV': AppColors.sakuraDeep, 'I': AppColors.kinBright};
  static const groups = ['N', 'V', 'ADJ', 'ADV', 'I', 'A'];

  static Future<List<EnWord>> load() => _cache ??= _load();

  static Future<List<EnWord>> _load() async {
    final raw = await rootBundle.loadString(assetPath('assets/data/toeic/toeic_words.json'));
    final j = json.decode(raw) as Map<String, dynamic>;
    return [
      for (final e in (j['words'] as List).cast<Map<String, dynamic>>())
        EnWord(rank: e['n'] as int, word: e['w'] as String, ko: e['ko'] as String, pos: e['pos'] as String, level: e['grp'] as String, picturable: false),
    ];
  }
}
