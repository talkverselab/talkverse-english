import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/platform.dart';
import '../core/pane.dart';
import '../core/theme.dart';
import '../widgets/lemma_text.dart';
import '../widgets/stress_toggle.dart';
import '../services/dialogue_service.dart';
import '../services/learner_prefs.dart';
import '../services/tts_service.dart';
import '../widgets/episode_play_pane.dart';
import '../widgets/english_decor.dart';
import 'dialogue_card_screen.dart';
import '../widgets/gram_note.dart';

/// 회화(R0~R4) 주제 목록 → 편 목록 → 편 화면 — Grok UXUI 시안 02 「만화책 읽기형」(사용자 확정 2026-11-02).
/// 아이패드: 홈 맨 위 「오늘의 컷」, 편 화면 = 왼쪽 대화 스크립트 + 오른쪽 큰 장면 컷(말풍선) + 하단 재생 컨트롤.
/// 폰: 각 단계가 push, 재생은 전체 화면(컷 위·스크립트 아래).
class DialogueHomeScreen extends StatefulWidget {
  const DialogueHomeScreen({super.key});
  @override
  State<DialogueHomeScreen> createState() => _DialogueHomeScreenState();
}

class _DialogueHomeScreenState extends State<DialogueHomeScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    DialogueService.instance.ensureLoaded().then((_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final svc = DialogueService.instance;
    final level = svc.level; // R0 왕초보 / R1 초보
    return Scaffold(
      backgroundColor: AppColors.washi,
      appBar: AppBar(
        title: Text(tr('회화'), style: const TextStyle(color: AppColors.sumi, fontWeight: FontWeight.w800, fontSize: 16)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.beni))
          : ListView(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 24 + bottomInset(context)),
              children: [
                _TodayCut(level: level),
                if (svc.all.isEmpty) _empty(),
                const SizedBox(height: 10),
                // 왕초보/초보 전환은 R0 구조가 생긴 뒤에(공통 프롬프터 §5) — 지금은 레벨별로 모두 보인다.
                for (final lv in DialogueService.levels)
                  if (svc.count(lv) > 0) ...[
                    _LevelHeader(lv: lv, count: svc.count(lv)),
                    for (final isl in svc.islandsOf(lv))
                      _IslandRow(
                        lv: lv,
                        island: isl,
                        count: svc.list(region: lv, island: isl).length,
                        onTap: () => openPane(context, (_) => DialogueListScreen(region: lv, island: isl)),
                      ),
                    const SizedBox(height: 10),
                  ],
              ],
            ),
    );
  }

  Widget _empty() => Container(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
        decoration: BoxDecoration(color: AppColors.washiDeep, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.line)),
        child: Column(children: [
          const Icon(Icons.auto_stories_outlined, color: AppColors.beni, size: 30),
          const SizedBox(height: 8),
          Text(tr('회화가 곧 들어옵니다'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.sumi)),
          const SizedBox(height: 4),
          Text(tr('들어오면 레벨(R1~R4) · 주제별로 여기에 보이고, 맨 위에 「오늘의 컷」이 열려요.'),
              textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: AppColors.sumiLight, height: 1.4)),
        ]),
      );
}

/// 「오늘의 컷」 — 마지막으로 열었던 편(없으면 현재 레벨 첫 편)의 장면 컷 + 읽기 시작(시안 02 홈).
class _TodayCut extends StatelessWidget {
  final String level;
  const _TodayCut({required this.level});

  @override
  Widget build(BuildContext context) {
    final svc = DialogueService.instance;
    final last = svc.lastOpenedId != null ? svc.byId(svc.lastOpenedId!) : null;
    final d = last ?? (svc.list(region: level).isNotEmpty ? svc.list(region: level).first : null);
    if (d == null) return const SizedBox.shrink();
    final wide = isWide(context);
    final t = d.turns.first;
    final info = Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Text(tr(last == null ? '오늘의 컷' : '이어서 읽기'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.beni, letterSpacing: 1)),
      const SizedBox(height: 4),
      Text('${d.emoji} ${d.title}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.sumi)),
      const SizedBox(height: 2),
      Text('${d.region} · ${tr(DialogueService.islandKo[d.island] ?? d.island)} · ${trf('{0}턴', [d.turns.length])}', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
      const SizedBox(height: 6),
      Text(d.scene, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.sumiLight, height: 1.4)),
      const SizedBox(height: 10),
      FilledButton.icon(
        onPressed: () => openPane(context, (_) => DialogueScreen(dialogue: d)),
        style: FilledButton.styleFrom(backgroundColor: AppColors.beni, foregroundColor: Colors.white, shape: const StadiumBorder(), visualDensity: VisualDensity.compact),
        icon: const Icon(Icons.menu_book_rounded, size: 18),
        label: Text(tr('읽기 시작'), style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
    ]);
    final cut = SizedBox(height: wide ? 230 : 196, child: SceneCut(dialogue: d, turn: t, bubble: true)); // 그림 + 아래 대사 띠(그림을 덮지 않음)
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.washi, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(16), boxShadow: kCardShadow),
      child: wide
          ? Row(crossAxisAlignment: CrossAxisAlignment.center, children: [Expanded(flex: 5, child: cut), const SizedBox(width: 14), Expanded(flex: 6, child: info)])
          : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [cut, const SizedBox(height: 10), info]),
    );
  }
}

class _LevelHeader extends StatelessWidget {
  final String lv;
  final int count;
  const _LevelHeader({required this.lv, required this.count});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 10, 4, 6),
        child: Row(children: [
          GradText(lv, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(width: 8),
          Text(tr(DialogueService.levelKo[lv] ?? lv), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.sumi)),
          const SizedBox(width: 8),
          Text(trf('{0}편', [count]), style: const TextStyle(fontSize: 11, color: AppColors.muted)),
        ]),
      );
}

class _IslandRow extends StatelessWidget {
  final String lv;
  final String island;
  final int count;
  final VoidCallback onTap;
  const _IslandRow({required this.lv, required this.island, required this.count, required this.onTap});
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(color: AppColors.washi, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(14), boxShadow: kCardShadow),
        child: Material(
          color: Colors.transparent,
          child: ListTile(
            onTap: onTap,
            leading: Text(DialogueService.islandEmoji[island] ?? '💬', style: const TextStyle(fontSize: 26)),
            title: Text(tr(DialogueService.islandKo[island] ?? island), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.sumi)),
            subtitle: Text(trf('{0}편', [count]), style: const TextStyle(fontSize: 11, color: AppColors.muted)),
            trailing: const Icon(Icons.chevron_right, color: AppColors.muted),
          ),
        ),
      );
}

/// 주제의 편 목록.
class DialogueListScreen extends StatelessWidget {
  final String region;
  final String island;
  const DialogueListScreen({super.key, required this.region, required this.island});

  @override
  Widget build(BuildContext context) {
    final list = DialogueService.instance.list(region: region, island: island);
    return Scaffold(
      backgroundColor: AppColors.washi,
      appBar: AppBar(
        title: Text('${DialogueService.islandEmoji[island] ?? ''} ${tr(DialogueService.islandKo[island] ?? island)} · $region',
            style: const TextStyle(color: AppColors.sumi, fontWeight: FontWeight.w800, fontSize: 15)),
      ),
      body: ListView.separated(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 24 + bottomInset(context)),
        itemCount: list.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final d = list[i];
          return Container(
            decoration: BoxDecoration(color: AppColors.washi, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(14), boxShadow: kCardShadow),
            child: Material(
              color: Colors.transparent,
              child: ListTile(
                onTap: () => openPane(context, (_) => DialogueScreen(dialogue: d)),
                leading: Text(d.emoji, style: const TextStyle(fontSize: 24)),
                title: Text(d.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.sumi)),
                subtitle: Text('${d.isChat ? '💬 ' : ''}${d.scene}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: AppColors.muted, height: 1.3)),
                trailing: Text(trf('{0}턴', [d.turns.length]), style: const TextStyle(fontSize: 11, color: AppColors.muted)),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 편 화면 — 시안 02 만화책 읽기형. 아이패드: 왼쪽 대화 스크립트 + 오른쪽 큰 장면 컷(같은 패널, ▶ 로 순차 재생).
/// 폰: 버블 목록 + 맨 위 「▶ 모든 문장 듣기」(전체 화면 재생).
class DialogueScreen extends StatefulWidget {
  final Dialogue dialogue;
  const DialogueScreen({super.key, required this.dialogue});
  @override
  State<DialogueScreen> createState() => _DialogueScreenState();
}

class _DialogueScreenState extends State<DialogueScreen> {
  Dialogue get d => widget.dialogue;

  @override
  void initState() {
    super.initState();
    DialogueService.instance.setLastOpened(d.id);
  }

  @override
  void dispose() {
    TtsService.instance.stop();
    super.dispose();
  }

  void _openPlay({int at = 0}) => openFull(context, (_) => _PlayFull(dialogue: d, at: at));

  @override
  Widget build(BuildContext context) {
    final wide = isWide(context);
    return Scaffold(
      backgroundColor: AppColors.washi,
      appBar: AppBar(
        title: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('${d.emoji} ${d.title}', style: const TextStyle(color: AppColors.sumi, fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 2),
          Text('${d.region} · ${tr(DialogueService.islandKo[d.island] ?? d.island)} · ${d.turns.length}${tr('턴')}',
              style: const TextStyle(color: AppColors.muted, fontSize: 10, letterSpacing: 1)),
        ]),
        actions: [
          const StressToggleAction(),
          IconButton(
            tooltip: tr('그림 카드(글자 없이)'),
            icon: const Icon(Icons.style_outlined, color: AppColors.ai),
            onPressed: () => openFull(context, (_) => DialogueCardScreen(dialogue: d)),
          ),
        ],
      ),
      body: wide
          ? EpisodePlayPane(key: ValueKey(d.id), dialogue: d, autoPlay: false)
          : Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                child: Row(children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _openPlay(),
                      style: FilledButton.styleFrom(backgroundColor: AppColors.beni, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), shape: const StadiumBorder()),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(tr('모든 문장 듣기'), style: const TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                child: Text(d.scene, style: const TextStyle(fontSize: 12, color: AppColors.sumiLight, height: 1.4)),
              ),
              const BrushDivider(height: 2),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 24 + bottomInset(context)),
                  itemCount: d.turns.length,
                  itemBuilder: (context, i) => _Bubble(d: d, t: d.turns[i], onPlayFrom: () => _openPlay(at: i)),
                ),
              ),
            ]),
    );
  }
}

class _PlayFull extends StatelessWidget {
  final Dialogue dialogue;
  final int at;
  const _PlayFull({required this.dialogue, required this.at});
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.washi,
        appBar: AppBar(title: Text('${dialogue.emoji} ${dialogue.title}', style: const TextStyle(color: AppColors.sumi, fontWeight: FontWeight.w800, fontSize: 15))),
        body: EpisodePlayPane(dialogue: dialogue, initialIndex: at),
      );
}

class _Bubble extends StatelessWidget {
  final Dialogue d;
  final DialogueTurn t;
  final VoidCallback onPlayFrom;
  const _Bubble({required this.d, required this.t, required this.onPlayFrom});

  @override
  Widget build(BuildContext context) {
    final me = t.speaker == 'A';
    final name = d.speakerName(t.speaker);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: me ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!me) _avatar(name),
          Flexible(
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              decoration: BoxDecoration(
                color: me ? AppColors.beni.withValues(alpha: 0.08) : AppColors.washi,
                border: Border.all(color: AppColors.line),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(me ? 16 : 4),
                  bottomRight: Radius.circular(me ? 4 : 16),
                ),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('$name${t.at != null ? ' · ${t.at}' : ''}', style: const TextStyle(fontSize: 10, color: AppColors.muted)),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => TtsService.instance.speakAs(LearnerPrefs.fill(t.tl).replaceAll(RegExp(r'\([^)]*\)'), ''), gender: LearnerPrefs.voiceGender(t.speaker)),
                    child: const Icon(Icons.volume_up, size: 16, color: AppColors.beni),
                  ),
                  const SizedBox(width: 4),
                  InkWell(onTap: onPlayFrom, child: const Icon(Icons.play_circle_outline, size: 16, color: AppColors.ai)),
                ]),
                const SizedBox(height: 4),
                LemmaText(LearnerPrefs.fill(t.tl), lemmas: t.lemmas, gram: t.gram, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.sumi, height: 1.4)),
                if (t.reading.isNotEmpty && t.reading != t.tl) Text(LearnerPrefs.fill(t.reading), style: const TextStyle(fontSize: 12, color: AppColors.ai, fontWeight: FontWeight.w700)),
                if (t.rd.isNotEmpty) Text(LearnerPrefs.fill(t.rd, ko: true), style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                const SizedBox(height: 3),
                Text(LearnerPrefs.fill(t.ko, ko: true), style: const TextStyle(fontSize: 13, color: AppColors.sumiLight, height: 1.35)),
                if (t.note.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('💡 ${t.note}', style: const TextStyle(fontSize: 11, color: AppColors.beniDeep, height: 1.35)),
                ],
                GramNote(t.gram, size: 11),
                if (t.stamp != null) Text(t.stamp!, style: const TextStyle(fontSize: 28)),
              ]),
            ),
          ),
          if (me) _avatar(name),
        ],
      ),
    );
  }

  Widget _avatar(String name) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: CircleAvatar(
          radius: 14,
          backgroundColor: AppColors.washiDeep,
          child: Text(name.isEmpty ? '?' : name.characters.first, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.sumi)),
        ),
      );
}
