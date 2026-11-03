// 아이패드 두 화면 확인용 스크린샷 흐름 — 일본어앱 dialogue_pane_test 를 영어앱에 맞춤(2026-11-03).
// 실행: python3 tools/pane_shots.py <아이패드 UDID> <출력폴더> integration_test/dialogue_pane_test.dart
// 회화 데이터가 아직 없어서, 리더·카드 배치는 테스트 안에서만 만든 자리표시 편(「Sample line」)으로 본다 — 앱 데이터가 아니다.
import 'package:english_universe/main.dart';
import 'package:english_universe/services/achievement_service.dart';
import 'package:english_universe/services/dialogue_service.dart';
import 'package:english_universe/services/learner_prefs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

Dialogue _fixture() => Dialogue(
      id: 'test_layout_a1',
      region: 'R1',
      island: 'friends',
      kind: 'short',
      title: 'Layout sample',
      emoji: '🧪',
      scene: 'Placeholder scene for layout check.',
      speakers: const {'A': '{name}', 'B': 'B'},
      register: '',
      twist: 0,
      expressions: const [],
      turns: [
        for (var i = 1; i <= 8; i++)
          DialogueTurn(
            num: i,
            speaker: i.isOdd ? 'A' : 'B',
            tl: 'Sample line $i for checking how a longer sentence wraps in the script.',
            reading: '',
            rd: '',
            ko: '배치 확인용 자리표시 문장 $i',
            note: '',
            tags: const [],
            newWords: const [],
          ),
      ],
    );

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  Future<void> wait(WidgetTester t, int ms) async {
    final end = DateTime.now().add(Duration(milliseconds: ms));
    while (DateTime.now().isBefore(end)) {
      await t.pump(const Duration(milliseconds: 100));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }

  Future<void> shot(WidgetTester t, String name) async {
    await wait(t, 2000);
    // ignore: avoid_print
    print('SHOT:$name');
    await wait(t, 3000);
  }

  Finder rail(String label) => find.descendant(of: find.byType(NavigationRail), matching: find.text(label));

  testWidgets('dialogue pane', timeout: const Timeout(Duration(minutes: 10)), (t) async {
    await LearnerPrefs.load();
    await AchievementService.instance.load();
    await t.pumpWidget(const EnglishUniverseApp());
    await wait(t, 1500);
    await shot(t, '10_learn_empty');

    await t.tap(find.text('주제별 회화').first);
    await wait(t, 2000);
    await shot(t, '11_dialogue_home_empty');

    await t.tap(find.text('절벽 단어 R1~R4').first);
    await wait(t, 4000);
    await shot(t, '11b_words_r1');
    await t.tap(find.text('그림 단어만'));
    await wait(t, 3000);
    await shot(t, '11c_words_picture_only');

    await t.tap(rail('복습'));
    await wait(t, 800);
    await shot(t, '12_review_tab');
    await t.tap(rail('탐색'));
    await wait(t, 800);
    await shot(t, '13_explore_tab');
    await t.tap(rail('나'));
    await wait(t, 1200);
    await shot(t, '14_me_tab');

    // 자리표시 편으로 리더 배치 확인
    await DialogueService.instance.ensureLoaded();
    DialogueService.instance.debugAdd(_fixture());
    await t.tap(rail('배우기'));
    await wait(t, 800);
    await t.tap(find.text('주제별 회화').first);
    await wait(t, 2000);
    await shot(t, '15_dialogue_home_fixture');
    await t.tap(find.text('친구').first);
    await wait(t, 1200);
    await shot(t, '16_island_list');
    await t.tap(find.text('Layout sample').last);
    await wait(t, 1500);
    await shot(t, '17_reader');
    await t.tap(find.text('재생').first);
    await wait(t, 4000);
    await shot(t, '18_reader_playing');

    await t.tap(find.byTooltip('그림 카드(글자 없이)'));
    await wait(t, 1500);
    await shot(t, '19_card_front');
    await t.tap(find.text('탭해서 확인'));
    await wait(t, 800);
    await shot(t, '20_card_back');
  });
}
