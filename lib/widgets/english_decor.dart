import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';

/// 落款 (らっかん) — 사각 인장. 기본은 「영어」 워드마크 그라데이션(진한 인디고 → 옅은 인디고), 색을 주면 그 단색.
class SealStamp extends StatelessWidget {
  final String text;
  final double size;
  final Color? color;
  final bool vertical;

  const SealStamp({
    super.key,
    required this.text,
    this.size = 56,
    this.color,
    this.vertical = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.beni;
    final isOne = text.runes.length == 1;
    final fontSize = isOne ? size * 0.6 : size * 0.32;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color == null ? null : c,
        gradient: color == null ? AppColors.wordmark : null,
        borderRadius: BorderRadius.circular(size * 0.18),
        boxShadow: [
          BoxShadow(
            color: c.withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: FittedBox(
          fit: BoxFit.contain,
          child: vertical
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: text.runes
                      .map((r) => Text(
                            String.fromCharCode(r),
                            style: TextStyle(
                              color: AppColors.washi,
                              fontSize: fontSize,
                              fontWeight: FontWeight.w900,
                              height: 1,
                            ),
                          ))
                      .toList(),
                )
              : Text(
                  text,
                  style: TextStyle(
                    color: AppColors.washi,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
        ),
      ),
    );
  }
}

/// 青海波 (せいがいは) — 파도 문양 배경 (장식용)
class SeigaihaPattern extends StatelessWidget {
  final Color color;
  final double opacity;

  const SeigaihaPattern({
    super.key,
    this.color = AppColors.kinDeep,
    this.opacity = 0.07,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SeigaihaPainter(color: color.withValues(alpha: opacity)),
      child: const SizedBox.expand(),
    );
  }
}

class _SeigaihaPainter extends CustomPainter {
  final Color color;
  _SeigaihaPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    const r = 26.0;
    const rowH = r * 0.5;
    var row = 0;
    for (var y = 0.0; y < size.height + r; y += rowH, row++) {
      final offsetX = row.isOdd ? r : 0.0;
      for (var x = -r + offsetX; x < size.width + r; x += r * 2) {
        for (var k = 1; k <= 3; k++) {
          final rr = r * k / 3;
          canvas.drawArc(
            Rect.fromCircle(center: Offset(x, y), radius: rr),
            math.pi,
            math.pi,
            false,
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

/// 麻の葉 스타일 지그재그 디바이더 (수평 패턴)
class AsanohaDivider extends StatelessWidget {
  final double height;
  final Color color;
  const AsanohaDivider({super.key, this.height = 16, this.color = AppColors.kin});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _AsanohaPainter(color: color)),
    );
  }
}

class _AsanohaPainter extends CustomPainter {
  final Color color;
  _AsanohaPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    final h = size.height;
    final unit = h * 0.9;
    final path = Path()..moveTo(0, h * 0.85);
    var up = true;
    for (var x = 0.0; x <= size.width + unit; x += unit) {
      path.lineTo(x, up ? h * 0.15 : h * 0.85);
      up = !up;
    }
    canvas.drawPath(path, paint);
    // 하단 얇은 기준선
    canvas.drawLine(Offset(0, h * 0.95), Offset(size.width, h * 0.95),
        paint..strokeWidth = 0.5);
  }

  @override
  bool shouldRepaint(_) => false;
}

/// 붓 분리선 — 붓터치 느낌 그라데이션 라인
class BrushDivider extends StatelessWidget {
  final double height;
  final Color? color; // null 이면 워드마크 그라데이션(구리 → 황갈)
  const BrushDivider({super.key, this.height = 3, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color;
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: c == null
            ? AppColors.wordmark
            : LinearGradient(
                colors: [
                  c.withValues(alpha: 0),
                  c.withValues(alpha: 0.6),
                  c,
                  c.withValues(alpha: 0.6),
                  c.withValues(alpha: 0),
                ],
              ),
        borderRadius: BorderRadius.circular(height),
      ),
    );
  }
}

/// 「영어」 워드마크처럼 인디고 그라데이션으로 칠한 글자(사이트 `.hero h1 .grad`).
class GradText extends StatelessWidget {
  final String text;
  final TextStyle style;
  const GradText(this.text, {super.key, required this.style});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (r) => AppColors.wordmark.createShader(Rect.fromLTWH(0, 0, r.width, r.height)),
      child: Text(text, style: style.copyWith(color: Colors.white)),
    );
  }
}

/// 홈 상단 파스텔 메시 — 사이트 첫 화면의 번진 원(복숭아·금빛·라벤더·하늘)을 따뜻한 쪽으로, 아래로 갈수록 흰 바탕에 녹는다.
class MeshBackdrop extends StatelessWidget {
  const MeshBackdrop({super.key});

  static const _blobs = <(Alignment, Color)>[
    (Alignment(-0.9, -0.4), Color(0xFFFFD39B)),
    (Alignment(-0.1, -1.0), Color(0xFFF5C07A)),
    (Alignment(0.5, -0.5), Color(0xFFF5B8E6)),
    (Alignment(1.0, 0.1), Color(0xFFA9A4FF)),
  ];

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: Color(0xFFFFF4EA)),
          for (final (align, color) in _blobs)
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: align,
                  radius: 0.9,
                  colors: [color.withValues(alpha: 0.8), color.withValues(alpha: 0)],
                ),
              ),
            ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x26FFFFFF), Color(0x8CFFFFFF), Colors.white],
                stops: [0, 0.6, 1],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 和風 카드 — 紅 헤더 + 金 테두리
class EnglishCard extends StatelessWidget {
  final Widget child;
  final String? title;
  final String? sealText;
  final VoidCallback? onTap;
  final Color? accent;
  final EdgeInsetsGeometry padding;

  const EnglishCard({
    super.key,
    required this.child,
    this.title,
    this.sealText,
    this.onTap,
    this.accent,
    this.padding = const EdgeInsets.all(14),
  });

  @override
  Widget build(BuildContext context) {
    final a = accent ?? AppColors.beni;
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.washi,
          border: Border.all(color: AppColors.line, width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.sumi.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null) ...[
              Container(
                color: a,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  children: [
                    if (sealText != null) ...[
                      SealStamp(text: sealText!, size: 22, color: AppColors.sumi),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        title!,
                        style: const TextStyle(
                          color: AppColors.washi,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    if (onTap != null)
                      const Icon(Icons.chevron_right, color: AppColors.washi, size: 18),
                  ],
                ),
              ),
            ],
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}

/// 鳥居 — 작은 토리이 아이콘 (장식)
class ToriiIcon extends StatelessWidget {
  final double size;
  final Color color;
  const ToriiIcon({super.key, this.size = 20, this.color = AppColors.beni});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size(size, size), painter: _ToriiPainter(color));
  }
}

class _ToriiPainter extends CustomPainter {
  final Color color;
  _ToriiPainter(this.color);

  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = color
      ..strokeWidth = s.width * 0.11
      ..strokeCap = StrokeCap.round;
    final w = s.width;
    final h = s.height;
    // 상단 가사기 (笠木) — 살짝 휨
    final top = Path()
      ..moveTo(w * 0.02, h * 0.22)
      ..quadraticBezierTo(w * 0.5, h * 0.1, w * 0.98, h * 0.22);
    canvas.drawPath(top, p..style = PaintingStyle.stroke);
    // 누키 (貫)
    canvas.drawLine(Offset(w * 0.15, h * 0.42), Offset(w * 0.85, h * 0.42), p);
    // 기둥
    canvas.drawLine(Offset(w * 0.25, h * 0.2), Offset(w * 0.22, h * 0.95), p);
    canvas.drawLine(Offset(w * 0.75, h * 0.2), Offset(w * 0.78, h * 0.95), p);
  }

  @override
  bool shouldRepaint(_) => false;
}

/// 桜 — 벚꽃 5장 (장식)
class SakuraIcon extends StatelessWidget {
  final double size;
  final Color color;
  const SakuraIcon({super.key, this.size = 18, this.color = AppColors.sakuraDeep});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size(size, size), painter: _SakuraPainter(color));
  }
}

class _SakuraPainter extends CustomPainter {
  final Color color;
  _SakuraPainter(this.color);

  @override
  void paint(Canvas canvas, Size s) {
    final paint = Paint()..color = color;
    final c = Offset(s.width / 2, s.height / 2);
    final r = s.shortestSide * 0.28;
    for (var i = 0; i < 5; i++) {
      final a = -math.pi / 2 + i * 2 * math.pi / 5;
      final pc = Offset(c.dx + math.cos(a) * r, c.dy + math.sin(a) * r);
      canvas.drawCircle(pc, s.shortestSide * 0.22, paint);
    }
    canvas.drawCircle(c, s.shortestSide * 0.12, Paint()..color = AppColors.kinBright);
  }

  @override
  bool shouldRepaint(_) => false;
}
