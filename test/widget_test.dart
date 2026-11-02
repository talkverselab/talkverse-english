import 'package:english_universe/core/theme.dart';
import 'package:english_universe/screens/main_screen.dart';
import 'package:english_universe/services/art_service.dart';
import 'package:english_universe/services/learner_prefs.dart';
import 'package:english_universe/services/tts_service.dart';
import 'package:english_universe/widgets/stress_text.dart';
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

  test('강세 규칙: 내용어 굵게 · 기능어 옅게 · 자음+모음 이어 말하기', () {
    final a = EnglishStress.analyze('Wanna grab a coffee?');
    expect(a.map((e) => e.weak).toList(), [true, false, true, false]);
    expect(a[1].link, isTrue); // grab‿a
    expect(a[2].link, isFalse);
    final b = EnglishStress.analyze('I made it, okay?');
    expect(b[1].link, isTrue); // made‿it (묵음 e)
    expect(b[2].link, isFalse); // 쉼표 뒤는 끊는다
    expect(EnglishStress.analyze("I can't go")[1].weak, isFalse); // 부정은 또렷
    expect(EnglishStress.isWeak('5'), isFalse); // 숫자는 또렷
  });

  testWidgets('강세 칩을 끄면 그냥 글자', (t) async {
    StressPrefs.on.value = true;
    await t.pumpWidget(const MaterialApp(home: StressText('grab a coffee', style: TextStyle(fontSize: 16))));
    expect(find.textContaining('‿'), findsOneWidget);
    StressPrefs.on.value = false;
    await t.pump();
    expect(find.text('grab a coffee'), findsOneWidget);
  });

  test('발음 지역: 미국 → 영국 → 호주 → 미국, 기기에 기억', () async {
    await AccentPrefs.load();
    expect(AccentPrefs.accent.value, EnAccent.us);
    await AccentPrefs.next();
    expect(AccentPrefs.accent.value.locale, 'en-GB');
    await AccentPrefs.next();
    expect(AccentPrefs.accent.value.locale, 'en-AU');
    await AccentPrefs.next();
    expect(AccentPrefs.accent.value, EnAccent.us);
    await AccentPrefs.set(EnAccent.au);
    AccentPrefs.accent.value = EnAccent.us;
    await AccentPrefs.load();
    expect(AccentPrefs.accent.value, EnAccent.au);
  });
}
