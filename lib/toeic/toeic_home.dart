import 'package:flutter/material.dart';

import '../core/app_flavor.dart';
import '../core/l10n.dart';
import '../core/pane.dart';
import '../core/theme.dart';
import '../screens/dialogue_screen.dart' show DialogueHomeScreen;
import '../screens/main_screen.dart' show EmptyNote, MainScreen, MeTab, NavRow, sectionTitle;
import '../services/achievement_service.dart';
import '../widgets/app_family.dart';
import '../widgets/english_decor.dart';
import 'toeic_words_screen.dart';

/// 토익유니버스 홈 — 영어앱과 같은 껍데기(MainScreen)에 토익 탭을 끼운다(앱내앱, 사용자 지시 2026-11-08).
/// 지금은 「토익 단어 익히기」만. RC·LC 는 전자책 세션의 판독본이 오면.
class ToeicHome extends StatelessWidget {
  const ToeicHome({super.key});

  @override
  Widget build(BuildContext context) => MainScreen(
        title: tr(AppFlavor.current.nameKo),
        tabs: [
          (Icons.menu_book_outlined, Icons.menu_book, tr('배우기'), const _ToeicLearnTab()),
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
