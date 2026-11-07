import 'package:english_universe/core/theme.dart';
import 'package:english_universe/screens/main_screen.dart';
import 'package:english_universe/services/art_service.dart';
import 'package:english_universe/services/learner_prefs.dart';
import 'package:english_universe/services/tts_service.dart';
import 'package:english_universe/widgets/stress_text.dart';
import 'package:english_universe/screens/word_freq_screen.dart';
import 'package:english_universe/screens/word_quiz_screen.dart';
import 'package:english_universe/services/achievement_service.dart';
import 'package:english_universe/services/content_sync.dart';
import 'package:english_universe/services/data_version.dart';
import 'package:english_universe/services/dialogue_service.dart';
import 'package:english_universe/screens/about_screen.dart';
import 'package:english_universe/widgets/lemma_chips.dart';
import 'package:english_universe/widgets/lemma_text.dart';
import 'package:english_universe/widgets/word_sheet.dart';
import 'dart:convert';
import 'dart:math';
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

  test('단어 목록 CSV: 따옴표 안 쉼표', () {
    expect(parseCsvLine('5,a,,"하나의, 어떤",a,det,R1,N'), ['5', 'a', '', '하나의, 어떤', 'a', 'det', 'R1', 'N']);
  });

  testWidgets('절벽 단어: 2,494어 읽고 R1 은 189개', (t) async {
    final words = await t.runAsync(WordList.load);
    expect(words!.length, 2494);
    expect(words.where((w) => w.level == 'R1').length, 189);
    expect(words.first.word, 'the');
  });

  EnWord w(int rank, String word, String pos, [String level = 'R1']) => EnWord(rank: rank, word: word, ko: '$word 뜻', pos: pos, level: level, picturable: true);

  test('그림 단어 퀴즈: 한 판 10문제, 보기 4개에 정답 1개·중복 없음·같은 품사 먼저', () {
    final pool = [for (var i = 0; i < 12; i++) w(i, 'n$i', 'noun'), for (var i = 12; i < 20; i++) w(i, 'v$i', 'verb')];
    final round = buildRound(pool, rng: Random(1));
    expect(round.length, 10);
    expect(round.map((q) => q.answer.word).toSet().length, 10);
    for (final q in round) {
      expect(q.options.length, 4);
      expect(q.options.where((o) => o.word == q.answer.word).length, 1);
      expect(q.options.map((o) => o.word).toSet().length, 4);
      expect(q.options.every((o) => o.pos == q.answer.pos), isTrue); // 품사별 12·8개라 같은 품사로 채워진다
    }
    expect(buildRound([w(1, 'a', 'noun')]), isEmpty); // 낱말 하나로는 보기를 못 만든다
    expect(buildRound([w(1, 'a', 'noun'), w(2, 'b', 'noun')], all: pool).first.options.length, 4); // 틀린 것만 다시: 보기는 전체에서
  });

  test('성과: 단어 그림 맞음 집계, 틀린 낱말은 쌓이고 맞히면 빠진다', () async {
    final a = AchievementService.instance;
    await a.load();
    await a.markWordQuiz(8, 10, missed: ['coffee', 'bridge'], right: ['apple']);
    expect(a.wordsRight, 8);
    expect(a.thisWeek['words'], 8);
    expect(a.missedWords, containsAll(['coffee', 'bridge']));
    await a.markWordQuiz(1, 1, right: ['coffee']);
    expect(a.missedWords, ['bridge']);
  });

  testWidgets('그림 단어 퀴즈 화면: 시작 → 문제 → 보기 고르면 정답 표시·다음', (t) async {
    // 그림 매니페스트를 기기 캐시에 넣어 둔 것처럼(네트워크 없이)
    final items = [for (var i = 0; i < 189; i++) {'rank': i + 1, 'word': 'pic$i', 'key_512': 'k/$i.webp'}];
    SharedPreferences.setMockInitialValues({
      'art_manifest_en_v1': json.encode({'base': 'https://example.invalid/', 'items': items}),
      'art_manifest_en_at': DateTime.now().millisecondsSinceEpoch,
    });
    t.view.physicalSize = const Size(1024 * 2, 768 * 2);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(theme: AppTheme.light(), home: const WordQuizScreen()));
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await t.pump();
    expect(find.text('시작'), findsOneWidget);
    expect(find.text('그림 단어 31개'), findsOneWidget); // R1 picturable=Y 31개(매니페스트는 순위로도 맞춘다)
    await t.tap(find.text('시작'));
    await t.pump();
    expect(find.text('1 / 10'), findsOneWidget);
    expect(find.text('이 그림은 무엇일까요?'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('choice_0')));
    await t.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('맞았어요!').evaluate().isNotEmpty || find.textContaining('정답은').evaluate().isNotEmpty, isTrue);
    await t.tap(find.text('다음'));
    await t.pump();
    expect(find.text('2 / 10'), findsOneWidget);
  });

  test('회화 턴: lemmas [[표면형, 기본형, 읽기]] 읽기', () {
    final t = DialogueTurn.fromJson({'num': 1, 'speaker': 'A', 'tl': 'Wanna grab a coffee?', 'ko': '커피 한잔할래?', 'lemmas': [['Wanna', 'want', ''], ['grab', 'grab', ''], ['coffee', 'coffee']]});
    expect(t.lemmas.length, 3);
    expect(t.lemmas[0].base, 'want');
    expect(t.lemmas[2].reading, '');
  });

  testWidgets('레마 칩: 단어장에 있으면 뜻 붙은 칩, 없으면 회색', (t) async {
    final words = await t.runAsync(WordList.load);
    final found = LemmaChips.lookup(words!, ['coffee', 'grab', 'zzzz']);
    expect(found['coffee']?.ko, isNotEmpty);
    expect(found.containsKey('zzzz'), isFalse);
    final turn = DialogueTurn.fromJson({'num': 1, 'speaker': 'A', 'tl': 'coffee zzzz', 'ko': '', 'lemmas': [['coffee', 'coffee', ''], ['zzzz', 'zzzz', '']]});
    await t.pumpWidget(MaterialApp(theme: AppTheme.light(), home: Scaffold(body: LemmaChips(turn: turn))));
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await t.pump();
    expect(find.text('coffee'), findsOneWidget);
    expect(find.text('zzzz'), findsOneWidget);
    expect(find.text(found['coffee']!.ko.split(RegExp(r'[,;·/]')).first.trim()), findsOneWidget);
  });

  testWidgets('레마 칩: 회색 칩 탭은 바깥(카드 뒤집기)으로 새지 않고, 단어장 칩은 시트를 연다', (t) async {
    final turn = DialogueTurn.fromJson({'num': 1, 'speaker': 'A', 'tl': 'coffee zzzz', 'ko': '', 'lemmas': [['coffee', 'coffee', ''], ['zzzz', 'zzzz', '']]});
    var flips = 0;
    await t.pumpWidget(MaterialApp(theme: AppTheme.light(), home: Scaffold(body: GestureDetector(onTap: () => flips++, child: LemmaChips(turn: turn)))));
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await t.pump();
    await t.tap(find.text('zzzz'));
    await t.pump();
    expect(flips, 0);
    expect(find.byType(WordSheet), findsNothing);
    await t.tap(find.text('coffee'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    expect(flips, 0);
    expect(find.byType(WordSheet), findsOneWidget);
  });

  test('절벽 단어: 20어 단원, 회화 단어는 단어장에 있는 것만 레벨 C', () {
    final ws = [for (var i = 1; i <= 45; i++) EnWord(rank: i, word: 'w$i', ko: '', pos: '', level: 'R1', picturable: false)];
    expect(wordUnits(ws).map((u) => u.length).toList(), [20, 20, 5]);
    final conv = WordList.convFrom(ws, '{"words":[{"word":"W3","n":2},{"word":"none","n":1}]}');
    expect(conv.map((w) => (w.word, w.level, w.rank)).toList(), [('w3', 'C', 3)]);
  });

  test('앱 소개 구간표: 영어 값, R4 는 2,000위 끝', () {
    final r = AboutScreen.rows();
    expect(r.map((x) => x.$2).toList(), ['1-189', '190-318', '319-825', '826-2,000']);
    expect(r.map((x) => x.$3).toList(), ['189', '129', '507', '1,175']);
  });

  test('강세 표시는 기본 미표시, 저장값을 따른다', () async {
    SharedPreferences.setMockInitialValues({});
    await StressPrefs.load();
    expect(StressPrefs.on.value, isFalse);
    SharedPreferences.setMockInitialValues({'stress_marks_on': true});
    await StressPrefs.load();
    expect(StressPrefs.on.value, isTrue);
    StressPrefs.on.value = false;
  });

  test('문장 낱말: 구두점을 떼고 단어장 레마만 잇는다', () {
    expect(LemmaText.bare('"Wraps,'), 'wraps');
    const ws = [EnWord(rank: 1, word: 'wrap', ko: '싸다', pos: 'verb', level: 'R1', picturable: false)];
    final m = LemmaText.linked(ws, const [Lemma('Wraps', 'wrap', ''), Lemma('zzz', 'zzz', '')]);
    expect(m.keys.toList(), ['wraps']);
  });

  testWidgets('문장 낱말을 누르면 단어 시트, 바깥 탭으로 새지 않는다', (t) async {
    var flips = 0;
    await t.pumpWidget(MaterialApp(theme: AppTheme.light(), home: Scaffold(body: GestureDetector(onTap: () => flips++, child: const LemmaText('coffee', lemmas: [Lemma('coffee', 'coffee', '')], style: TextStyle(fontSize: 20))))));
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await t.pump();
    await t.tap(find.byType(RichText).first);
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    expect(flips, 0);
    expect(find.byType(WordSheet), findsOneWidget);
  });

  test('그림 기기 내려받기: 색인이 없으면 네트워크 그림, 추정치 0', () {
    expect(artProvider('https://example.invalid/a.webp'), isA<NetworkImage>());
    expect(ContentSync.instance.localFile('scene/x.webp'), isNull);
    expect(ContentSync.instance.estimate.$1, 0);
  });

  test('데이터 업데이트 번호: 번들 db 와 다르면 그림 매니페스트 캐시를 지우고 번호 저장', () async {
    SharedPreferences.setMockInitialValues({'art_manifest_en_v1': '{}', 'db_version': 0});
    expect(await DataVersion.bundled(), greaterThanOrEqualTo(1));
    expect(await DataVersion.applyIfChanged(), isTrue);
    final p = await SharedPreferences.getInstance();
    expect(p.getString('art_manifest_en_v1'), isNull);
    expect(await DataVersion.applyIfChanged(), isFalse); // 같은 번호면 그대로
  });
}
