import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'english_decor.dart';

/// 오늘의 학습 카드 — 현재 진행 중인 에피소드 (후지산 일러스트 + progress).
class TodayMissionCard extends StatelessWidget {
  final String level;
  final String lessonTitle;
  final String lessonSubtitle;
  final int progress;
  final int total;
  final VoidCallback? onTap;

  const TodayMissionCard({
    super.key,
    required this.level,
    required this.lessonTitle,
    required this.lessonSubtitle,
    required this.progress,
    required this.total,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.beniDeep, AppColors.beni],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: AppColors.kin, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.beni.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: 0,
              bottom: 0,
              child: CustomPaint(
                size: const Size(170, 100),
                painter: _FujiPainter(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.kinBright,
                          border: Border.all(color: AppColors.kinDeep, width: 0.6),
                        ),
                        child: Text(
                          level,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.sumi,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const SealStamp(text: '今', size: 24, color: AppColors.sumi),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    lessonTitle,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.washi,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lessonSubtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.washi.withValues(alpha: 0.85),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    '$progress / $total',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.kinBright,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Stack(
                    children: [
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.washi.withValues(alpha: 0.25),
                          border: Border.all(color: AppColors.kin, width: 0.6),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: total > 0 ? (progress / total).clamp(0.0, 1.0) : 0,
                        child: Container(height: 8, color: AppColors.kinBright),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 富士山 — 설산 실루엣 + 붉은 태양
class _FujiPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // 태양
    canvas.drawCircle(
      Offset(w * 0.28, h * 0.32),
      h * 0.16,
      Paint()..color = AppColors.kinBright.withValues(alpha: 0.9),
    );
    // 산 몸체
    final body = Paint()..color = AppColors.beniDeep;
    final mountain = Path()
      ..moveTo(0, h)
      ..lineTo(w * 0.62, h * 0.18)
      ..lineTo(w * 0.7, h * 0.18)
      ..lineTo(w, h * 0.55)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(mountain, body);
    // 설관 (雪冠)
    final snow = Paint()..color = AppColors.washi.withValues(alpha: 0.9);
    final cap = Path()
      ..moveTo(w * 0.52, h * 0.34)
      ..lineTo(w * 0.62, h * 0.18)
      ..lineTo(w * 0.7, h * 0.18)
      ..lineTo(w * 0.8, h * 0.34)
      ..lineTo(w * 0.75, h * 0.38)
      ..lineTo(w * 0.7, h * 0.32)
      ..lineTo(w * 0.66, h * 0.4)
      ..lineTo(w * 0.61, h * 0.33)
      ..lineTo(w * 0.57, h * 0.39)
      ..close();
    canvas.drawPath(cap, snow);
  }

  @override
  bool shouldRepaint(_) => false;
}

/// 🔥 연속 학습 칩
class StreakChip extends StatelessWidget {
  final int days;
  const StreakChip({super.key, required this.days});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.beniDeep,
        border: Border.all(color: AppColors.kinBright, width: 1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            '$days',
            style: const TextStyle(
              color: AppColors.kinBright,
              fontWeight: FontWeight.w900,
              fontSize: 13,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
