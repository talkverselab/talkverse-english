import 'package:english_universe/core/theme.dart';
import 'package:english_universe/screens/main_screen.dart';
import 'package:english_universe/services/art_service.dart';
import 'package:english_universe/services/learner_prefs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('{name} 자리표시는 이름이 없으면 ○○', () async {
    await LearnerPrefs.load();
    expect(LearnerPrefs.fill('Hi, {name}!'), 'Hi, ○○!');
    await LearnerPrefs.setName('Min');
    expect(LearnerPrefs.fill('Hi, {name}!'), 'Hi, Min!');
  });

  testWidgets('폰 폭: 하단 탭 4개, 회화 없으면 안내', (t) async {
    t.view.physicalSize = const Size(390 * 3, 844 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(theme: AppTheme.light(), home: const MainScreen()));
    await t.pump(const Duration(milliseconds: 300));
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('배우기'), findsWidgets);
    expect(find.textContaining('회화가 곧 들어옵니다'), findsOneWidget);
  });

  testWidgets('아이패드 폭: 레일 + 두 칸', (t) async {
    t.view.physicalSize = const Size(1024 * 2, 1366 * 2);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(theme: AppTheme.light(), home: const MainScreen()));
    await t.pump(const Duration(milliseconds: 300));
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.textContaining('왼쪽에서 고르면'), findsOneWidget);
  });

  test('ArtService 는 영어 매니페스트를 본다', () {
    expect(ArtService.manifestUrl, contains('/art/en/'));
  });
}
