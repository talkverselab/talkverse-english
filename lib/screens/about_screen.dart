import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/theme.dart';
import '../widgets/english_decor.dart';
import 'word_freq_screen.dart' show kWordCap;

/// 앱 소개 — 이 앱의 뼈대인 **절벽구간**을 설명한다(사용자 지시 2026-11-07, 일본어앱 `about_screen.dart` 구조).
/// 숫자 출처: `assets/data/words/en_words.csv` 의 구간(R1 ≤189 · R2 ≤318 · R3 ≤825, 그 뒤 R4).
/// 영어 목록은 R4 끝의 누적 %가 없어서 표에 적지 않는다(산출값이 들어오면 채운다).
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const cliffs = [189, 318, 825];
  static const _pct = ['55%', '60%', '70%', '—'];
  static const _colors = [AppColors.beni, AppColors.ai, AppColors.kinDeep, AppColors.matcha];

  static String _n(int v) => v.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+$)'), (_) => ',');

  /// 표 줄 — (구간, 순위 범위, 개수, 누적).
  static List<(String, String, String, String)> rows() {
    final ends = [...cliffs, kWordCap];
    return [
      for (var i = 0; i < ends.length; i++)
        ('R${i + 1}', '${_n(i == 0 ? 1 : ends[i - 1] + 1)}-${_n(ends[i])}', _n(ends[i] - (i == 0 ? 0 : ends[i - 1])), _pct[i]),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.washi,
      appBar: AppBar(
        title: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(tr('앱 소개'), style: const TextStyle(color: AppColors.sumi, fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(tr('절벽구간 — 이 앱이 단어를 나누는 기준'), style: const TextStyle(color: AppColors.sumiLight, fontSize: 10, letterSpacing: 1)),
        ]),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 24 + MediaQuery.paddingOf(context).bottom),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.washiDeep, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(8)),
            child: Text(
              tr('자주 쓰는 말은 아주 적습니다. 처음 189개 단어가 말뭉치 전체의 55%를 차지하고, 825개면 70%입니다. 그 뒤로는 단어를 더 외워도 알아듣는 비율이 조금씩만 오릅니다 — 이 급한 경사를 「절벽」이라 부르고, 경사가 바뀌는 자리마다 구간을 나눕니다.'),
              style: const TextStyle(color: AppColors.sumi, fontSize: 14, height: 1.6),
            ),
          ),
          const SizedBox(height: 18),
          _H(tr('1. 단어 기준')),
          const _CliffTable(),
          const SizedBox(height: 8),
          _Para(tr('낱말의 기본형 1개 = 단어 1개. 앱은 2,000위까지 보여 줍니다.')),
          const SizedBox(height: 10),
          _H(tr('2. 산출 방식')),
          _Para(tr('빈도 — 각 단어의 등장 횟수 ÷ 전체 등장 횟수. 가중치 없음.')),
          _Para(tr('구간 — 빈도순으로 누적해 55%·60%·70%·80%에 처음 닿는 순위가 R1·R2·R3·R4 의 끝입니다. 이 네 비율은 Talkverse 언어앱 공통 기준입니다.')),
          const SizedBox(height: 10),
          _H(tr('3. 앱에서 쓰는 곳')),
          _Para(tr('절벽 단어 — R1→R4 순서로 20어씩 한 단원. 「회화 단어 포함」을 누르면 회화에 나오는 단어가 「회화」 구간으로 뒤에 붙습니다.')),
          _Para(tr('회화 — 문장의 밑줄 친 낱말을 누르면 단어 시트가 열립니다.')),
          _Para(tr('그림 단어 퀴즈 — 구간별로 그림을 보고 낱말을 고릅니다.')),
          const SizedBox(height: 24),
          const BrushDivider(),
        ],
      ),
    );
  }
}

class _H extends StatelessWidget {
  final String text;
  const _H(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(color: AppColors.sumi, fontSize: 16, fontWeight: FontWeight.w800)),
      );
}

class _Para extends StatelessWidget {
  final String text;
  const _Para(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(color: AppColors.sumiLight, fontSize: 13, height: 1.55)),
      );
}

/// 구간표 — 등폭 막대 + 구간별 순위 범위 · 개수 · 누적 %.
class _CliffTable extends StatelessWidget {
  const _CliffTable();

  @override
  Widget build(BuildContext context) {
    final rows = AboutScreen.rows();
    Widget cell(String s, {bool head = false}) => Expanded(
          child: Text(s, textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, color: head ? AppColors.muted : AppColors.sumi, fontWeight: head ? FontWeight.w700 : FontWeight.w600)),
        );
    return Container(
      decoration: BoxDecoration(border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(8)),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
          child: Row(children: [
            for (var i = 0; i < rows.length; i++)
              Expanded(
                child: Container(
                  height: 10,
                  margin: EdgeInsets.only(right: i < rows.length - 1 ? 2 : 0),
                  decoration: BoxDecoration(color: AboutScreen._colors[i], borderRadius: BorderRadius.circular(2)),
                ),
              ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(children: [const SizedBox(width: 34), cell(tr('순위'), head: true), cell(tr('개수'), head: true), cell(tr('누적'), head: true)]),
        ),
        for (var i = 0; i < rows.length; i++)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.line, width: 0.6))),
            child: Row(children: [
              Container(
                width: 34,
                padding: const EdgeInsets.symmetric(vertical: 2),
                alignment: Alignment.center,
                decoration: BoxDecoration(color: AboutScreen._colors[i], borderRadius: BorderRadius.circular(3)),
                child: Text(rows[i].$1, style: const TextStyle(color: AppColors.washi, fontSize: 10, fontWeight: FontWeight.w800)),
              ),
              cell(rows[i].$2),
              cell(trf('{0}어', [rows[i].$3])),
              cell(rows[i].$4),
            ]),
          ),
      ]),
    );
  }
}
