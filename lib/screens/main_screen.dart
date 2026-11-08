import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/pane.dart';
import '../core/theme.dart';
import '../services/achievement_service.dart';
import '../services/dialogue_service.dart';
import '../widgets/english_decor.dart';
import '../widgets/today_mission.dart';
import 'about_screen.dart';
import 'dialogue_screen.dart';
import 'profile_screen.dart';
import 'roots_screen.dart';
import 'sound_chart_screen.dart';
import 'word_freq_screen.dart';
import 'word_quiz_screen.dart';
import '../widgets/flashcards.dart';

/// 메인 — 탭 4개: 배우기(오늘의 학습·기초·회화·단어) · 복습 · 탐색 · 프로필(성과·설정). 넓은 화면 레일 맨 아래 「앱 소개」.
/// 일본어앱 구조 그대로(공통 프롬프터 §5, 2026-11-03). 회화·단어 데이터는 아직 없어 빈 안내를 보인다.
/// 넓은 화면(isWide): 앱바 아래 왼쪽 = 탭 레일 + 그 탭의 목록, 오른쪽 = 고른 내용(자기 Navigator). 폰: 하단 탭 + 내용 전체 화면.
/// 학습(에피소드·카드 세션·퀴즈)은 어느 쪽이든 openFull 로 목록을 감추고 전체 화면.
class MainScreen extends StatefulWidget {
  /// 탭(아이콘·선택 아이콘·이름·내용). 비우면 영어유니버스 탭. 토익 등 앱내앱은 자기 탭을 넣어 같은 껍데기를 쓴다(2026-11-08).
  final List<(IconData, IconData, String, Widget)>? tabs;
  final String? title;
  const MainScreen({super.key, this.tabs, this.title});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;
  final _pane = GlobalKey<NavigatorState>();

  List<(IconData, IconData, String, Widget)> get _tabs => widget.tabs ?? [
    (Icons.menu_book_outlined, Icons.menu_book, tr('배우기'), const LearnTab()),
    (Icons.style_outlined, Icons.style, tr('복습'), const ReviewTab()),
    (Icons.explore_outlined, Icons.explore, tr('탐색'), const ExploreTab()),
    (Icons.person_outline, Icons.person, tr('프로필'), const MeTab()),
  ];

  @override
  Widget build(BuildContext context) {
    final appBar = AppBar(
      centerTitle: false,
      // 「영어」 워드마크 그라데이션(인디고) — talkverse.uk 영어 페이지 기준
      title: GradText(
        widget.title ?? tr('영어유니버스'),
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),
    );
    final stack = IndexedStack(
      index: _index,
      children: [for (final t in _tabs) t.$4],
    );
    // 폰(한 화면): 하단 탭 + 내용 전체 화면
    if (!isWide(context)) {
      return Scaffold(
        appBar: appBar,
        body: stack,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: [
            for (final t in _tabs)
              NavigationDestination(
                icon: Icon(t.$1),
                selectedIcon: Icon(t.$2),
                label: t.$3,
              ),
          ],
        ),
      );
    }
    // 넓은 화면(아이패드·안드로이드 태블릿·폴드 펼침): 레일 + 왼쪽 칸(탭 목록) | 오른쪽 칸(연 화면). 두 칸까지만.
    final w = MediaQuery.sizeOf(context).width;
    final left = (w * 0.34).clamp(
      300.0,
      440.0,
    ); // 폴드 펼침(≈740) 은 300, 아이패드는 더 넓게
    return Pane(
      navKey: _pane,
      child: NavigatorPopHandler(
        onPopWithResult: (_) => _pane.currentState?.maybePop(),
        child: Scaffold(
          appBar: appBar,
          body: Row(
            children: [
              NavigationRail(
                selectedIndex: _index,
                onDestinationSelected: (i) => setState(() => _index = i),
                labelType: w >= 900
                    ? NavigationRailLabelType.all
                    : NavigationRailLabelType.selected,
                backgroundColor: AppColors.washiDeep,
                indicatorColor: const Color(0xFFEDEBFF),
                selectedIconTheme: const IconThemeData(
                  color: AppColors.beniDeep,
                ),
                unselectedIconTheme: const IconThemeData(
                  color: AppColors.muted,
                ),
                selectedLabelTextStyle: const TextStyle(
                  color: AppColors.beni,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelTextStyle: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                trailing: widget.tabs != null ? null : Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Builder(
                        builder: (context) => InkWell(
                          onTap: () => openPane(context, (_) => const AboutScreen()),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            child: Column(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.info_outline, color: AppColors.muted),
                              const SizedBox(height: 2),
                              Text(tr('앱 소개'), style: const TextStyle(color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.w600)),
                            ]),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                destinations: [
                  for (final t in _tabs)
                    NavigationRailDestination(
                      icon: Icon(t.$1),
                      selectedIcon: Icon(t.$2),
                      label: Text(t.$3),
                    ),
                ],
              ),
              const VerticalDivider(
                width: 1,
                thickness: 1,
                color: AppColors.line,
              ),
              SizedBox(width: left, child: stack),
              const VerticalDivider(
                width: 1,
                thickness: 1,
                color: AppColors.line,
              ),
              Expanded(
                child: ClipRect(
                  child: Navigator(
                    key: _pane,
                    onGenerateInitialRoutes: (_, _) => [
                      MaterialPageRoute(
                        builder: (_) => const _PanePlaceholder(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 오른쪽 칸이 비어 있을 때.
class _PanePlaceholder extends StatelessWidget {
  const _PanePlaceholder();

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.washi,
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SealStamp(text: 'En', size: 56),
          const SizedBox(height: 14),
          Text(
            tr('왼쪽에서 고르면 여기에 열립니다 · 회화 읽기·카드는 전체 화면'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}

/// 탭 안의 한 줄(카드) — 도장 + 제목·부제 + 꺾쇠. 누르면 오른쪽 칸(넓은 화면) 또는 push.
class NavRow extends StatelessWidget {
  final String seal;
  final Color? sealColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  const NavRow({super.key, 
    required this.seal,
    this.sealColor,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.washi,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.line),
          boxShadow: kCardShadow,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  SealStamp(text: seal, size: 40, color: sealColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.sumi,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onTap == null)
                    Text(
                      tr('준비 중'),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.muted),
                    )
                  else
                    const Icon(
                      Icons.chevron_right,
                      color: AppColors.muted,
                      size: 20,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 탭 안 소제목(토익 등 앱내앱 탭도 쓴다).
Widget sectionTitle(String title) => Padding(
  padding: const EdgeInsets.fromLTRB(2, 14, 2, 8),
  child: Text(
    title,
    style: const TextStyle(
      fontSize: 12.5,
      fontWeight: FontWeight.w700,
      color: AppColors.muted,
      letterSpacing: 0.5,
    ),
  ),
);

// ────────── 배우기 ──────────

/// 배우기: 인사 → 오늘의 학습(이어서 읽기 / 첫 편) → 기초(소리 배우기) → 회화 → 단어.
/// 소리 층(§6-B) = 강세·이어 말하기·약해지는 소리 — 콘텐츠는 사용자 지시 뒤라 지금은 「준비 중」.
class LearnTab extends StatefulWidget {
  const LearnTab({super.key});

  @override
  State<LearnTab> createState() => _LearnTabState();
}

class _LearnTabState extends State<LearnTab> {
  Dialogue? _today;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final svc = DialogueService.instance;
    await svc.ensureLoaded();
    Dialogue? today;
    final last = svc.lastOpenedId;
    if (last != null) today = svc.byId(last);
    if (today == null) {
      final list = svc.list();
      if (list.isNotEmpty) today = list.first;
    }
    if (mounted) {
      setState(() {
        _today = today;
        _loaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = _today;
    return Stack(
      children: [
        // 사이트 첫 화면처럼 위쪽만 파스텔 메시, 아래는 흰 바탕
        const Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 260,
          child: MeshBackdrop(),
        ),
        ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            24 + MediaQuery.paddingOf(context).bottom,
          ),
          children: [
            const GradText(
              'Hello!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              tr('한국 학습자, 오늘도 시작해요'),
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.sumiLight,
                fontWeight: FontWeight.w500,
              ),
            ),
            sectionTitle(tr('오늘의 학습')),
            if (!_loaded)
              const SizedBox(height: 120)
            else if (today == null)
              const EmptyNote(
                icon: Icons.auto_stories_outlined,
                text: '회화가 곧 들어옵니다. 들어오면 여기에서 오늘 읽을 편이 열려요.',
              )
            else
              TodayMissionCard(
                level: DialogueService.levelKo[today.region] ?? today.region,
                lessonTitle: '${today.emoji} ${today.title}',
                lessonSubtitle: DialogueService.islandKo[today.island] ?? today.island,
                progress: 0,
                total: today.turns.length,
                onTap: () async {
                  await openPane(context, (_) => DialogueScreen(dialogue: today));
                  _load();
                },
              ),
            sectionTitle(tr('기초')),
            const SoundChartNavRow(),
            sectionTitle(tr('회화')),
            NavRow(
              seal: 'Talk',
              sealColor: AppColors.beni,
              title: tr('주제별 회화'),
              subtitle: tr('모든 문장 듣기 · 그림 카드 · 장면 컷'),
              onTap: () => openPane(context, (_) => const DialogueHomeScreen()),
            ),
            sectionTitle(tr('단어')),
            NavRow(
              seal: 'Word',
              sealColor: AppColors.kinDeep,
              title: tr('절벽 단어 R1~R4'),
              subtitle: tr('빈도 2,000위 · 20어 단원 · 그림 · 미국/영국/호주 발음'),
              onTap: () => openPane(context, (_) => const WordFreqScreen()),
            ),
            NavRow(
              seal: 'Card',
              sealColor: AppColors.kinDeep,
              title: tr('단어 플래시카드'),
              subtitle: tr('절벽 단어 2,000위 · 알아요 / 몰라요 · 한 판 20장'),
              onTap: () => openFull(context, (_) => FlashcardDeck(title: tr('단어 플래시카드'), deckId: 'cliff', loader: () async => (await WordList.load()).where((w) => w.rank <= kWordCap).toList())),
            ),
            const RootsNavRow(),
          ],
        ),
      ],
    );
  }
}

/// 데이터가 아직 없을 때의 안내 카드.
class EmptyNote extends StatelessWidget {
  final IconData icon;
  final String text;
  const EmptyNote({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.washi,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.line),
      boxShadow: kCardShadow,
    ),
    child: Row(
      children: [
        Icon(icon, color: AppColors.beni, size: 26),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            tr(text),
            style: const TextStyle(fontSize: 13, color: AppColors.sumiLight, height: 1.4),
          ),
        ),
      ],
    ),
  );
}

// ────────── 복습 ──────────

/// 복습: 그림 단어 퀴즈(지금 데이터로 가능) + 틀린 낱말 다시. 문장 플래시카드는 회화 데이터가 들어오면.
class ReviewTab extends StatelessWidget {
  const ReviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    final a = AchievementService.instance;
    return ValueListenableBuilder<int>(
      valueListenable: a.changes,
      builder: (context, _, _) {
        final missed = a.missedWords;
        return ListView(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 24 + MediaQuery.paddingOf(context).bottom),
          children: [
            sectionTitle(tr('오늘의 복습')),
            if (missed.isEmpty)
              const EmptyNote(
                icon: Icons.style_outlined,
                text: '그림 단어 퀴즈에서 틀린 낱말과 회화의 그림 카드가 여기에 쌓여요.',
              )
            else
              NavRow(
                seal: 'Re',
                sealColor: AppColors.sakuraDeep,
                title: tr('틀린 단어 다시'),
                subtitle: trf('{0}개 · 맞히면 빠져요', [missed.length]),
                onTap: () => openFull(context, (_) => WordQuizScreen(words: missed)),
              ),
            sectionTitle(tr('복습')),
            NavRow(
              seal: 'Pic',
              sealColor: AppColors.beni,
              title: tr('그림 단어 퀴즈'),
              subtitle: tr('그림 보고 낱말 고르기 · R1~R4'),
              onTap: () => openFull(context, (_) => const WordQuizScreen()),
            ),
            NavRow(
              seal: 'Card',
              sealColor: AppColors.kinDeep,
              title: tr('문장 플래시카드'),
              subtitle: tr('읽은 회화에서 랜덤 20'),
            ),
          ],
        );
      },
    );
  }
}

// ────────── 탐색 ──────────

/// 탐색: 단어·표현 참고 자료(데이터가 들어오면 연다).
class ExploreTab extends StatelessWidget {
  const ExploreTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 24 + MediaQuery.paddingOf(context).bottom),
      children: [
        sectionTitle(tr('회화')),
        NavRow(
          seal: 'Talk',
          sealColor: AppColors.beni,
          title: tr('주제별 회화'),
          subtitle: tr('레벨 · 주제 · 편 목록'),
          onTap: () => openPane(context, (_) => const DialogueHomeScreen()),
        ),
        sectionTitle(tr('단어')),
        NavRow(
          seal: 'Word',
          title: tr('단어 빈도'),
          subtitle: 'Vocabulary · R1~R4',
          onTap: () => openPane(context, (_) => const WordFreqScreen()),
        ),
        NavRow(
          seal: 'Root',
          sealColor: AppColors.matcha,
          title: tr('뿌리 단어 패밀리'),
          subtitle: tr('라틴·그리스 어근 · 가족별로 뜻 풀기'),
          onTap: () => openPane(context, (_) => const RootsScreen()),
        ),
        NavRow(
          seal: 'Aa',
          sealColor: AppColors.ai,
          title: tr('소리 사전'),
          subtitle: tr('강세 위치 · 약해지는 소리'),
        ),
      ],
    );
  }
}

// ────────── 프로필 ──────────

/// 프로필: 성과 · 기록 · 학습자 프로필 · 설정 · 정보.
class MeTab extends StatelessWidget {
  const MeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 24 + MediaQuery.paddingOf(context).bottom),
      children: const [ProfileScreen(embedded: true)],
    );
  }
}

/// 「뿌리 단어 패밀리」 메뉴 한 줄 — 네 앱 공용(같은 화면·같은 데이터).
class RootsNavRow extends StatelessWidget {
  const RootsNavRow({super.key});
  @override
  Widget build(BuildContext context) => NavRow(
        seal: 'Root',
        sealColor: AppColors.matcha,
        title: tr('뿌리 단어 패밀리'),
        subtitle: tr('라틴·그리스 어근 → 앞가지·어근·뒷가지로 뜻 풀기'),
        onTap: () => openPane(context, (_) => const RootsScreen()),
      );
}

/// 「알파벳과 발음」 메뉴 한 줄 — 배우기 탭 「기초」 첫 줄, 네 앱 공용(공통 프롬프터 §5-3).
class SoundChartNavRow extends StatelessWidget {
  const SoundChartNavRow({super.key});
  @override
  Widget build(BuildContext context) => NavRow(
        seal: 'Aa',
        sealColor: AppColors.ai,
        title: tr('알파벳과 발음'),
        subtitle: tr('알파벳 26 · 모음·자음 · r/l·f/p·th · 입 모양·한국어 비교'),
        onTap: () => openPane(context, (_) => const SoundChartScreen()),
      );
}
