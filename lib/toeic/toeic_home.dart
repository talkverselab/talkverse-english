import 'package:flutter/material.dart';

import '../core/app_flavor.dart';
import '../core/l10n.dart';
import '../core/pane.dart';
import '../core/theme.dart';
import '../screens/dialogue_screen.dart' show DialogueHomeScreen;
import '../screens/main_screen.dart' show EmptyNote, MainScreen, MeTab, NavRow, RootsNavRow, sectionTitle;
import '../services/achievement_service.dart';
import '../widgets/app_family.dart';
import '../widgets/english_decor.dart';
import '../screens/word_freq_screen.dart' show WordList, kWordCap;
import '../widgets/flashcards.dart';
import 'toeic_words.dart';
import 'toeic_words_screen.dart';

/// 토익·토익스피킹·OPIc 홈 — 영어앱과 같은 껍데기(MainScreen)에 앱별 탭을 끼운다(앱내앱, 사용자 지시 2026-11-08).
/// 플래시카드·뿌리 단어는 네 앱이 같은 엔진(`widgets/flashcards.dart`·`screens/roots_screen.dart`)을 쓴다.
class ToeicHome extends StatelessWidget {
  const ToeicHome({super.key});

  @override
  Widget build(BuildContext context) => MainScreen(
        title: tr(AppFlavor.current.nameKo),
        tabs: [
          (Icons.menu_book_outlined, Icons.menu_book, tr('배우기'), AppFlavor.current == AppFlavor.toeic ? const _ToeicLearnTab() : const _SpeakingLearnTab()),
          (Icons.style_outlined, Icons.style, tr('복습'), const _ToeicReviewTab()),
          (Icons.apps_outlined, Icons.apps, tr('앱 가족'), const _FamilyTab()),
          (Icons.person_outline, Icons.person, tr('프로필'), const MeTab()),
        ],
      );
}

class _ToeicLearnTab extends StatelessWidget {
  const _ToeicLearnTab();

  @override
  Widget build(BuildContext context) => ListView(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 24 + MediaQuery.paddingOf(context).bottom),
        children: [
          const SizedBox(height: 6),
          const GradText('TOEIC', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          const SizedBox(height: 2),
          Text(tr('단어부터 — 매일 한 단원 20어'), style: const TextStyle(fontSize: 13, color: AppColors.sumiLight, fontWeight: FontWeight.w500)),
          sectionTitle(tr('단어')),
          NavRow(
            seal: 'Voca',
            sealColor: AppColors.matcha,
            title: tr('토익 단어 익히기'),
            subtitle: tr('1,330어 · 20어 단원 · 명사·동사·형용사·부사·관용표현 → 기본 빈도어'),
            onTap: () => openPane(context, (_) => const ToeicWordsScreen()),
          ),
          NavRow(
            seal: 'Quiz',
            sealColor: AppColors.beni,
            title: tr('뜻 고르기 퀴즈'),
            subtitle: tr('낱말 보고 뜻 4지선다 · 한 판 10문제'),
            onTap: () => openFull(context, (_) => const ToeicQuizScreen()),
          ),
          NavRow(
            seal: 'Card',
            sealColor: AppColors.kinDeep,
            title: tr('토익 단어 플래시카드'),
            subtitle: tr('알아요 / 몰라요 · 모르는 카드는 다시 · 한 판 20장'),
            onTap: () => openFull(context, (_) => FlashcardDeck(title: tr('토익 단어 플래시카드'), deckId: 'toeic', loader: ToeicWords.load)),
          ),
          const RootsNavRow(),
          sectionTitle(tr('비즈니스 회화 — 회화로 익히는 토익 문법')),
          NavRow(
            seal: 'Talk',
            sealColor: AppColors.sakuraDeep,
            title: tr('사무실 회화 8턴'),
            subtitle: tr('편마다 문법 하나 · 밑줄·빨간 글씨 · 끝에 빈칸 문제'),
            onTap: () => openPane(context, (_) => const DialogueHomeScreen()),
          ),
          sectionTitle(tr('독해 · 듣기')),
          const EmptyNote(icon: Icons.article_outlined, text: 'RC · LC 는 준비 중입니다. 들어오면 여기에서 Part 별로 풀어요.'),
        ],
      );
}

/// 토익스피킹·OPIc 배우기 — 말하기 내용은 준비 중, 지금은 공용 엔진(플래시카드·뿌리 단어)으로 어휘부터.
class _SpeakingLearnTab extends StatelessWidget {
  const _SpeakingLearnTab();

  @override
  Widget build(BuildContext context) {
    final speaking = AppFlavor.current == AppFlavor.toeicSpeaking;
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 24 + MediaQuery.paddingOf(context).bottom),
      children: [
        const SizedBox(height: 6),
        GradText(speaking ? 'TOEIC Speaking' : 'OPIc', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        const SizedBox(height: 2),
        Text(tr(speaking ? '답변 틀 · 말하기 연습 — 어휘부터 다져요' : '주제별 답변 · 표현 — 어휘부터 다져요'), style: const TextStyle(fontSize: 13, color: AppColors.sumiLight, fontWeight: FontWeight.w500)),
        sectionTitle(tr('단어')),
        NavRow(
          seal: 'Card',
          sealColor: AppColors.kinDeep,
          title: tr('말하기 기본 단어 플래시카드'),
          subtitle: tr('빈도 2,000위 · 알아요 / 몰라요 · 한 판 20장'),
          onTap: () => openFull(context, (_) => FlashcardDeck(title: tr('말하기 기본 단어'), deckId: 'cliff', loader: () async => (await WordList.load()).where((w) => w.rank <= kWordCap).toList())),
        ),
        const RootsNavRow(),
        sectionTitle(tr(speaking ? '말하기 — 문항 유형별' : '말하기 — 주제별')),
        EmptyNote(icon: Icons.mic_none, text: speaking ? '토익스피킹 문항 유형별 답변 틀과 연습은 준비 중입니다.' : 'OPIc 주제별 답변과 표현은 준비 중입니다.'),
      ],
    );
  }
}

class _ToeicReviewTab extends StatelessWidget {
  const _ToeicReviewTab();

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
              const EmptyNote(icon: Icons.style_outlined, text: '뜻 고르기 퀴즈에서 틀린 낱말이 여기에 쌓여요.')
            else
              NavRow(
                seal: 'Re',
                sealColor: AppColors.sakuraDeep,
                title: tr('틀린 단어 다시'),
                subtitle: trf('{0}개 · 맞히면 빠져요', [missed.length]),
                onTap: () => openFull(context, (_) => ToeicQuizScreen(words: missed)),
              ),
            sectionTitle(tr('복습')),
            NavRow(
              seal: 'Quiz',
              sealColor: AppColors.beni,
              title: tr('뜻 고르기 퀴즈'),
              subtitle: tr('묶음을 골라 한 판 10문제'),
              onTap: () => openFull(context, (_) => const ToeicQuizScreen()),
            ),
          ],
        );
      },
    );
  }
}

class _FamilyTab extends StatelessWidget {
  const _FamilyTab();

  @override
  Widget build(BuildContext context) => ListView(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 24 + MediaQuery.paddingOf(context).bottom),
        children: [
          sectionTitle(tr('앱 가족 — 깔려 있으면 바로 열려요')),
          const AppFamilyList(),
        ],
      );
}
