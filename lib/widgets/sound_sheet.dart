import 'dart:async';

import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../services/english_phonetics.dart';
import '../services/tts_service.dart';

/// 소리 탭 → 발음 상세 시트(일본어앱 kana_sound_sheet 와 같은 틀, 공통 프롬프터 §5-3).
/// 열리면 1초 뒤 예시 낱말 자동 재생 · 다시 듣기 · IPA · 소리 나는 곳 · 모음 위치(영어 vs 한국어) · 조음 위치 그림 · 한국어 화자 비교 · 헷갈리는 짝.
/// [letter] 가 있으면 알파벳 글자 시트(글자 이름 → 대표 소리).
Future<void> showSoundSheet(BuildContext context, EnSound sound, {EnLetter? letter, Color color = AppColors.beni}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.washi,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (_) => _SoundSheet(sound: sound, letter: letter, color: color),
  );
}

class _SoundSheet extends StatefulWidget {
  final EnSound sound;
  final EnLetter? letter;
  final Color color;
  const _SoundSheet({required this.sound, this.letter, required this.color});
  @override
  State<_SoundSheet> createState() => _SoundSheetState();
}

class _SoundSheetState extends State<_SoundSheet> {
  Timer? _auto;
  bool _showChart = false;

  String get _say => widget.letter != null ? widget.letter!.word : widget.sound.word;

  @override
  void initState() {
    super.initState();
    _auto = Timer(const Duration(seconds: 1), () {
      final l = widget.letter;
      if (l != null) {
        TtsService.instance.speak(l.upper); // 글자 이름 먼저
        Future<void>.delayed(const Duration(milliseconds: 900), () => TtsService.instance.speak(l.word));
      } else {
        TtsService.instance.speak(_say);
      }
    });
  }

  @override
  void dispose() {
    _auto?.cancel();
    TtsService.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.sound;
    final l = widget.letter;
    final c = widget.color;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (context, scroll) => SafeArea(
        top: false,
        child: ListView(
          controller: scroll,
          padding: EdgeInsets.fromLTRB(20, 12, 20, 32 + bottomInset(context)),
          children: [
            Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Row(children: [
              Container(
                width: 84,
                height: 84,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(14)),
                child: FittedBox(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(l != null ? '${l.upper}${l.lower}' : '/${s.sym}/', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Colors.white)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (l != null) Text(trf('글자 이름 /{0}/', [l.name]), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: c)),
                  Text('IPA /${s.sym}/', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.sumi)),
                  const SizedBox(height: 4),
                  _WordWithMark(word: l?.word ?? s.word, mark: l == null ? s.mark : '', color: c),
                ]),
              ),
              IconButton(iconSize: 44, color: c, tooltip: tr('다시 듣기'), icon: const Icon(Icons.play_circle_fill), onPressed: () => TtsService.instance.speak(_say)),
            ]),
            const SizedBox(height: 18),
            _box(tr('👄 소리 나는 곳 · 입 모양'), s.place, c),
            if (s.vowel != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.washiDeep, borderRadius: BorderRadius.circular(10), border: Border.all(color: c.withValues(alpha: 0.35))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(tr('📍 모음 위치 — 영어 vs 한국어'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: c)),
                  const SizedBox(height: 10),
                  VowelChart(en: (s.sym, s.vowel!.$1, s.vowel!.$2), ko: s.korVowels),
                ]),
              ),
            ],
            if (s.group == 'consonant') ...[
              const SizedBox(height: 6),
              InkWell(
                onTap: () => setState(() => _showChart = !_showChart),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(children: [
                    Icon(_showChart ? Icons.expand_less : Icons.expand_more, size: 18, color: c),
                    Text(tr('자음 조음 위치 그림 보기'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c)),
                  ]),
                ),
              ),
              if (_showChart) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(color: Colors.white, padding: const EdgeInsets.all(8), child: Image.asset('assets/images/ipa/places_of_articulation.png', fit: BoxFit.contain)),
                ),
              ],
            ],
            const SizedBox(height: 12),
            _box(tr('🇰🇷 한국어와 비교'), trf('비슷한 소리: {0}\n\n{1}', [s.korSim, s.korDiff]), c),
            const SizedBox(height: 12),
            _box(tr('✏️ 흔한 철자'), s.spell, c),
            if (s.pair.length == 2) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.washiDeep, borderRadius: BorderRadius.circular(10), border: Border.all(color: c.withValues(alpha: 0.35))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(tr('👂 헷갈리는 짝 — 번갈아 들어 보세요'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: c)),
                  const SizedBox(height: 10),
                  Row(children: [
                    for (final w in s.pair) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => TtsService.instance.speak(w),
                          icon: const Icon(Icons.volume_up, size: 18),
                          label: Text(w, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                          style: OutlinedButton.styleFrom(foregroundColor: c, side: BorderSide(color: c.withValues(alpha: 0.5)), padding: const EdgeInsets.symmetric(vertical: 12)),
                        ),
                      ),
                      if (w != s.pair.last) const SizedBox(width: 10),
                    ],
                  ]),
                ]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _box(String title, String body, Color c) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.washiDeep, borderRadius: BorderRadius.circular(10), border: Border.all(color: c.withValues(alpha: 0.35))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: c)),
          const SizedBox(height: 8),
          Text(body, style: const TextStyle(fontSize: 13.5, height: 1.55, color: AppColors.sumi)),
        ]),
      );
}

/// 예시 낱말 — 그 소리를 내는 글자만 굵게·색으로.
class _WordWithMark extends StatelessWidget {
  final String word, mark;
  final Color color;
  const _WordWithMark({required this.word, required this.mark, required this.color});
  @override
  Widget build(BuildContext context) {
    final i = mark.isEmpty ? -1 : word.indexOf(mark);
    const base = TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.sumi);
    if (i < 0) return Text(word, style: base);
    return Text.rich(TextSpan(style: base, children: [
      TextSpan(text: word.substring(0, i)),
      TextSpan(text: mark, style: TextStyle(fontWeight: FontWeight.w900, color: color, decoration: TextDecoration.underline, decorationColor: color)),
      TextSpan(text: word.substring(i + mark.length)),
    ]));
  }
}

/// 모음 사다리꼴 — 영어 모음(파랑 ●) 하나와 비교할 한국어 모음(빨강 ●)을 한 그림에.
class VowelChart extends StatelessWidget {
  final (String, double, double) en;
  final List<(String, double, double)> ko;
  const VowelChart({super.key, required this.en, required this.ko});

  static const koColor = Color(0xFFD12F2F);

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AspectRatio(
          aspectRatio: 1.45,
          child: Container(
            decoration: BoxDecoration(color: AppColors.washi, border: Border.all(color: AppColors.line)),
            padding: const EdgeInsets.fromLTRB(30, 22, 14, 14),
            child: CustomPaint(painter: _VowelPainter(en, ko), size: Size.infinite),
          ),
        ),
        const SizedBox(height: 6),
        Row(children: [
          _dot(AppColors.ai, tr('영어')),
          const SizedBox(width: 12),
          _dot(koColor, tr('한국어')),
          const Spacer(),
          Text(tr('왼쪽 = 혀 앞 · 위 = 입 닫힘'), style: const TextStyle(fontSize: 10, color: AppColors.muted)),
        ]),
      ]);

  Widget _dot(Color c, String label) => Row(children: [
        Container(width: 9, height: 9, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: c)),
      ]);
}

class _VowelPainter extends CustomPainter {
  final (String, double, double) en;
  final List<(String, double, double)> ko;
  _VowelPainter(this.en, this.ko);

  // 사다리꼴: 위는 넓고 아래는 왼쪽이 안쪽으로 들어간다(IPA 모음도).
  Offset _pt(Size s, double x, double y) {
    final left = s.width * 0.3 * y; // 열릴수록 앞쪽이 뒤로
    return Offset(left + (s.width - left) * x, s.height * y);
  }

  @override
  void paint(Canvas canvas, Size s) {
    final line = Paint()
      ..color = AppColors.line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()
      ..moveTo(_pt(s, 0, 0).dx, 0)
      ..lineTo(s.width, 0)
      ..lineTo(s.width, s.height)
      ..lineTo(_pt(s, 0, 1).dx, s.height)
      ..close();
    canvas.drawPath(path, line);
    canvas.drawLine(_pt(s, 0, 0.5), Offset(s.width, s.height * 0.5), line..strokeWidth = 0.8);
    canvas.drawLine(Offset(s.width * 0.5, 0), _pt(s, 0.5, 1), line);
    for (final k in ko) {
      _mark(canvas, _pt(s, k.$2, k.$3), k.$1, VowelChart.koColor, s);
    }
    _mark(canvas, _pt(s, en.$2, en.$3), '/${en.$1}/', AppColors.ai, s, big: true);
  }

  void _mark(Canvas canvas, Offset p, String label, Color c, Size s, {bool big = false}) {
    canvas.drawCircle(p, big ? 7 : 5.5, Paint()..color = c);
    final tp = TextPainter(text: TextSpan(text: label, style: TextStyle(color: c, fontSize: big ? 13 : 11.5, fontWeight: FontWeight.w900)), textDirection: TextDirection.ltr)..layout();
    var o = p + const Offset(9, -8);
    if (o.dx + tp.width > s.width + 10) o = p + Offset(-tp.width - 9, -8);
    tp.paint(canvas, o);
  }

  @override
  bool shouldRepaint(covariant _VowelPainter old) => old.en != en || old.ko != ko;
}
