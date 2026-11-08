import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../services/english_phonetics.dart';
import '../widgets/sound_sheet.dart';

/// 「알파벳과 발음」 — 일본어앱 「50음도와 발음」과 같은 틀(공통 프롬프터 §5-3, 사용자 지시 2026-11-08).
/// 묶음 칩(알파벳 · 모음 · 이중모음 · 자음 · 한국인이 어려운 소리) + 격자 + 보조 표기 토글(예시 낱말 ↔ 한글 근사).
/// 칸을 누르면 발음 시트(1초 뒤 자동 재생 · 다시 듣기 · IPA · 입 모양 · 모음 위치 · 조음 위치 그림 · 한국어 비교 · 헷갈리는 짝).
class SoundChartScreen extends StatefulWidget {
  const SoundChartScreen({super.key});
  @override
  State<SoundChartScreen> createState() => _SoundChartScreenState();
}

class _SoundChartScreenState extends State<SoundChartScreen> {
  String _group = 'alphabet';
  bool _korean = false; // 보조 표기: false = 예시 낱말, true = 한글 근사

  static const _groups = ['alphabet', 'vowel', 'diphthong', 'consonant', 'hard'];
  static const _label = {'alphabet': '알파벳', 'vowel': '모음', 'diphthong': '이중모음', 'consonant': '자음', 'hard': '한국인이 어려운 소리'};
  static const _color = {'alphabet': AppColors.beni, 'vowel': AppColors.ai, 'diphthong': AppColors.kinDeep, 'consonant': AppColors.matcha, 'hard': AppColors.sakuraDeep};

  List<EnSound> get _sounds => _group == 'hard' ? enSounds.where((s) => s.hard).toList() : enSounds.where((s) => s.group == _group).toList();

  @override
  Widget build(BuildContext context) {
    final c = _color[_group]!;
    return Scaffold(
      backgroundColor: AppColors.washi,
      appBar: AppBar(
        title: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(tr('알파벳과 발음'), style: const TextStyle(color: AppColors.sumi, fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(trf('알파벳 26 · 소리 {0} · 미국 발음 기준', [enSounds.length]), style: const TextStyle(color: AppColors.sumiLight, fontSize: 10, letterSpacing: 1)),
        ]),
      ),
      body: Column(children: [
        Container(
          color: AppColors.washiDeep,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final g in _groups)
                ChoiceChip(
                  label: Text(tr(_label[g]!)),
                  selected: _group == g,
                  onSelected: (_) => setState(() => _group = g),
                  selectedColor: _color[g]!.withValues(alpha: 0.18),
                  labelStyle: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: _color[g]),
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                ),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              Text(tr('보조 표기'), style: const TextStyle(fontSize: 12, color: AppColors.sumiLight, fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              SegmentedButton<bool>(
                segments: [ButtonSegment(value: false, label: Text(tr('예시 낱말'))), ButtonSegment(value: true, label: Text(tr('한글 근사')))],
                selected: {_korean},
                onSelectionChanged: (v) => setState(() => _korean = v.first),
                showSelectedIcon: false,
                style: SegmentedButton.styleFrom(visualDensity: VisualDensity.compact, textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
              ),
            ]),
          ]),
        ),
        if (_group == 'hard')
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Text(tr('한국어에 없거나 한국어 소리로 내면 다른 낱말이 되는 소리 — 시트의 「헷갈리는 짝」을 번갈아 들어 보세요.'), style: const TextStyle(fontSize: 12, color: AppColors.sumiLight, height: 1.4)),
          ),
        Expanded(
          child: LayoutBuilder(builder: (context, box) {
            final cols = (box.maxWidth / (_group == 'alphabet' ? 96 : 120)).floor().clamp(3, 8);
            final items = _group == 'alphabet' ? enLetters.length : _sounds.length;
            return GridView.builder(
              padding: EdgeInsets.fromLTRB(12, 12, 12, 24 + bottomInset(context)),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: cols, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 0.92),
              itemCount: items,
              itemBuilder: (context, i) {
                if (_group == 'alphabet') {
                  final l = enLetters[i];
                  final s = soundOf(l.sound)!;
                  return _Tile(big: '${l.upper}${l.lower}', small: _korean ? s.korSim : l.word, tiny: '/${l.name}/', color: c, onTap: () => showSoundSheet(context, s, letter: l, color: c));
                }
                final s = _sounds[i];
                return _Tile(big: '/${s.sym}/', small: _korean ? s.korSim : s.word, tiny: s.hard ? '★' : '', color: c, onTap: () => showSoundSheet(context, s, color: c));
              },
            );
          }),
        ),
      ]),
    );
  }
}

class _Tile extends StatelessWidget {
  final String big, small, tiny;
  final Color color;
  final VoidCallback onTap;
  const _Tile({required this.big, required this.small, required this.tiny, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.washi,
        shape: RoundedRectangleBorder(side: BorderSide(color: color.withValues(alpha: 0.4)), borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
            child: Column(children: [
              Align(alignment: Alignment.centerRight, child: Text(tiny, style: TextStyle(fontSize: 9.5, color: color, fontWeight: FontWeight.w800))),
              Expanded(child: Center(child: FittedBox(fit: BoxFit.scaleDown, child: Text(big, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: color))))),
              FittedBox(fit: BoxFit.scaleDown, child: Text(small, maxLines: 1, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.sumi))),
            ]),
          ),
        ),
      );
}
