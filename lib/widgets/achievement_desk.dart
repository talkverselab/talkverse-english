import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;

import '../core/l10n.dart';
import '../core/theme.dart';
import '../services/achievement_service.dart';
import '../services/dialogue_service.dart';
import '../widgets/english_decor.dart';

/// 「나」 탭 성과 데스크 — 시안 02 §5·wire_02. 큰 숫자 대신 문장 + 작은 진행 막대. 경쟁·순위·포인트·스트릭 없음.
class AchievementDesk extends StatefulWidget {
  const AchievementDesk({super.key});
  @override
  State<AchievementDesk> createState() => _AchievementDeskState();
}

class _AchievementDeskState extends State<AchievementDesk> {
  final _a = AchievementService.instance;

  @override
  void initState() {
    super.initState();
    _a.changes.addListener(_reload);
    _reload();
  }

  @override
  void dispose() {
    _a.changes.removeListener(_reload);
    super.dispose();
  }

  Future<void> _reload() async {
    await _a.load();
    await DialogueService.instance.ensureLoaded();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // 자기 칸 너비 기준(아이패드 「나」 탭은 왼쪽 좁은 칸에 들어간다): 700 이상이면 좌우 2단, 아니면 세로 1단
    return LayoutBuilder(builder: (context, c) {
      final twoCol = c.maxWidth >= 700;
      final left = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _WeekLine(a: _a),
        const SizedBox(height: 12),
        _WeekDots(a: _a),
      ]);
      final right = _IslandGrid(a: _a, columns: c.maxWidth >= 900 ? 4 : (c.maxWidth >= 380 ? 2 : 1));
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        twoCol
            ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 5, child: left), const SizedBox(width: 14), Expanded(flex: 7, child: right)])
            : Column(children: [left, const SizedBox(height: 12), right]),
        const SizedBox(height: 6),
        Text(tr('센다: 편 완주 · 핵심 표현  /  안 센다: 앱 오픈 · 스트릭 · 포인트 · 순위'),
            style: const TextStyle(fontSize: 10.5, color: AppColors.muted, height: 1.4)),
      ]);
    });
  }
}

Widget _card({required Widget child, Color? border}) => Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.washi, border: Border.all(color: border ?? AppColors.line), borderRadius: BorderRadius.circular(14), boxShadow: kCardShadow),
      child: child,
    );

Widget _label(String t) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(t, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.muted, letterSpacing: 1)));

class _WeekLine extends StatelessWidget {
  final AchievementService a;
  const _WeekLine({required this.a});
  @override
  Widget build(BuildContext context) {
    final w = a.thisWeek;
    final e = w['episodes'] ?? 0, c = w['cards'] ?? 0;
    final island = a.weekSentence();
    final line = e == 0 && c == 0
        ? tr('이번 주는 아직 조용해요. 편 하나를 끝까지 들어 보세요.')
        : (island.isNotEmpty ? trf('이번 주엔 {0} 주제를 가장 많이 읽었어요', [tr(DialogueService.islandKo[island] ?? island)]) : tr('이번 주도 한 걸음씩 가고 있어요'));
    return _card(
      border: AppColors.beni.withValues(alpha: 0.5),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _label(tr('이번 주 한 줄')),
        Text(line, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.sumi, height: 1.4)),
        const SizedBox(height: 4),
        Text(trf('편 {0} 완주 · 핵심 표현 {1} 맞음', [e, c]), style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
      ]),
    );
  }
}

class _WeekDots extends StatelessWidget {
  final AchievementService a;
  const _WeekDots({required this.a});
  @override
  Widget build(BuildContext context) {
    const names = ['월', '화', '수', '목', '금', '토', '일'];
    final week = a.week();
    return _card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _label(tr('이번 주 되돌아보기')),
        Row(children: [
          for (final (d, n) in week)
            Expanded(
              child: Column(children: [
                Container(
                  height: 32,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: n > 0 ? AppColors.beni.withValues(alpha: 0.14) : AppColors.washi, border: Border.all(color: n > 0 ? AppColors.beni : AppColors.line), borderRadius: BorderRadius.circular(8)),
                  child: Text(tr(names[DateTime.parse(d).weekday - 1]), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.sumi)),
                ),
                const SizedBox(height: 3),
                Text(n > 0 ? trf('{0}편', [n]) : ' ', style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: AppColors.beni)),
              ]),
            ),
        ]),
      ]),
    );
  }
}

class _IslandGrid extends StatelessWidget {
  final AchievementService a;
  final int columns;
  const _IslandGrid({required this.a, required this.columns});
  @override
  Widget build(BuildContext context) {
    final svc = DialogueService.instance;
    final islands = DialogueService.islands.where((i) => ['R0', 'R1', 'R2', 'R3'].any((r) => svc.list(region: r, island: i).isNotEmpty)).toList();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns, mainAxisSpacing: 10, crossAxisSpacing: 10, mainAxisExtent: 182),
      itemCount: islands.length,
      itemBuilder: (context, i) {
        final isl = islands[i];
        final rows = <Widget>[];
        var exprRight = 0, exprTotal = 0;
        for (final r in ['R0', 'R1', 'R2', 'R3']) {
          final (done, all) = a.progress(island: isl, region: r);
          if (all == 0) continue;
          for (final d in svc.list(region: r, island: isl)) {
            final c = a.cardsOf(d.id);
            if (c != null) {
              exprRight += c[0];
              exprTotal += c[1];
            }
          }
          rows.add(Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(children: [
              SizedBox(width: 38, child: Text(tr(DialogueService.levelKo[r] ?? r), style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppColors.muted))),
              Expanded(
                child: Stack(children: [
                  Container(height: 7, decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(4))),
                  FractionallySizedBox(widthFactor: all == 0 ? 0 : done / all, child: Container(height: 7, decoration: BoxDecoration(color: AppColors.beni, borderRadius: BorderRadius.circular(4)))),
                ]),
              ),
              const SizedBox(width: 6),
              Text('$done/$all', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: done > 0 ? AppColors.beni : AppColors.muted)),
            ]),
          ));
        }
        return _card(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${DialogueService.islandEmoji[isl]} ${tr(DialogueService.islandKo[isl] ?? isl)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.sumi)),
            const SizedBox(height: 8),
            ...rows,
            const Spacer(),
            Text(exprTotal > 0 ? trf('핵심 표현 {0}/{1} 기억', [exprRight, exprTotal]) : tr('그림 카드로 표현을 확인해 보세요'), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.ai)),
          ]),
        );
      },
    );
  }
}

/// 편 끝 순간 연출(시안 02): 장면 컷 살짝 확대 + 구리빛 한 번 + 짧은 진동, 「한 장면을 마쳤어요」. 폭죽 없음.
class EpisodeDoneOverlay extends StatefulWidget {
  final Dialogue dialogue;
  final bool firstTime;
  final VoidCallback onCards;
  final VoidCallback onClose;
  const EpisodeDoneOverlay({super.key, required this.dialogue, required this.firstTime, required this.onCards, required this.onClose});
  @override
  State<EpisodeDoneOverlay> createState() => _EpisodeDoneOverlayState();
}

class _EpisodeDoneOverlayState extends State<EpisodeDoneOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));

  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.dialogue;
    final cards = AchievementService.instance.cardsOf(d.id);
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final glow = Curves.easeOut.transform(_c.value);
        final fade = 1 - Curves.easeIn.transform(_c.value);
        return Stack(fit: StackFit.expand, children: [
          IgnorePointer(child: Container(color: AppColors.beni.withValues(alpha: 0.18 * fade))),
          Center(
            child: Transform.scale(
              scale: 0.96 + 0.04 * glow,
              child: Container(
                width: 360,
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppColors.washi, border: Border.all(color: AppColors.beni, width: 1.4), borderRadius: BorderRadius.circular(18), boxShadow: kCardShadow),
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Text('🌟', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 8),
                    Expanded(child: GradText(tr('한 장면을 마쳤어요'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900))),
                  ]),
                  const SizedBox(height: 8),
                  Text('${d.emoji} ${d.title}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.sumi)),
                  const SizedBox(height: 4),
                  Text(
                    widget.firstTime ? trf('{0} {1} 첫 완주 · 핵심 표현 {2}개', [tr(DialogueService.islandKo[d.island] ?? d.island), d.region, d.expressions.length]) : tr('다시 들었어요 — 핵심 표현이 더 또렷해져요'),
                    style: const TextStyle(fontSize: 12, color: AppColors.sumiLight, height: 1.4),
                  ),
                  if (cards != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text(trf('그림 카드 {0}/{1} 기억', [cards[0], cards[1]]), style: const TextStyle(fontSize: 12, color: AppColors.ai, fontWeight: FontWeight.w700))),
                  const SizedBox(height: 10),
                  const BrushDivider(height: 2),
                  const SizedBox(height: 10),
                  Wrap(spacing: 6, runSpacing: 6, children: [for (final e in d.expressions) Chip(label: Text(e, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.beniDeep)), backgroundColor: AppColors.beni.withValues(alpha: 0.08), side: BorderSide(color: AppColors.beni.withValues(alpha: 0.4)), visualDensity: VisualDensity.compact)]),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: widget.onCards,
                        style: FilledButton.styleFrom(backgroundColor: AppColors.beni, foregroundColor: Colors.white, shape: const StadiumBorder()),
                        icon: const Icon(Icons.style_outlined, size: 18),
                        label: Text(tr('그림 카드로'), style: const TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(onPressed: widget.onClose, style: OutlinedButton.styleFrom(shape: const StadiumBorder(), side: const BorderSide(color: AppColors.line)), child: Text(tr('닫기'), style: const TextStyle(color: AppColors.sumi, fontWeight: FontWeight.w700))),
                  ]),
                ]),
              ),
            ),
          ),
        ]);
      },
    );
  }
}
