/// 앱내앱(사용자 지시 2026-11-08): 영어유니버스 · 토익 · 토익스피킹 · OPIc — 한 저장소·한 빌드 구조, 출시는 따로, 앱 안에서 서로 이동.
/// 빌드 때 `--dart-define=APP=<id>` 로 고른다(없으면 english). Android 는 같은 이름의 productFlavor(`--flavor`),
/// iOS 는 `tools/select_app.sh <id>` 가 쓰는 `ios/Flutter/App.xcconfig`(번들 ID·표시 이름·URL 스킴) — 스크립트 `tools/ios_release.sh <id>` 가 둘 다 맞춘다.
library;

enum AppFlavor {
  english('english', '영어유니버스', 'English Universe', 'talkverse-english', 'com.talkverse.english_universe', 'com.talkverse.englishUniverse', '영어 유니버스'),
  toeic('toeic', '토익유니버스', 'TOEIC Universe', 'talkverse-toeic', 'com.talkverse.toeic', 'com.talkverse.toeic', '토익 유니버스'),
  toeicSpeaking('toeic_speaking', '토익스피킹유니버스', 'TOEIC Speaking Universe', 'talkverse-toeicspeaking', 'com.talkverse.toeic_speaking', 'com.talkverse.toeicSpeaking', '토익스피킹 유니버스'),
  opic('opic', 'OPIc유니버스', 'OPIc Universe', 'talkverse-opic', 'com.talkverse.opic', 'com.talkverse.opic', 'OPIc 유니버스');

  /// id = dart-define 값 = Android productFlavor 이름 = `tools/select_app.sh` 인자.
  final String id;
  final String nameKo;
  final String nameEn;
  /// 앱 사이 이동용 URL 스킴(`<scheme>://open`). Android `<queries>`·iOS `LSApplicationQueriesSchemes` 에 넷 다 등록돼 있다.
  final String scheme;
  final String androidId;
  final String iosBundleId;
  /// Zealot 앱이름(고정 — 바꾸면 Zealot 에 다른 앱이 새로 생긴다).
  final String zealotName;
  const AppFlavor(this.id, this.nameKo, this.nameEn, this.scheme, this.androidId, this.iosBundleId, this.zealotName);

  /// 짧은 소개 한 줄(앱 가족 목록·앱 소개).
  String get tagline => switch (this) {
        AppFlavor.english => '절벽 단어 · 회화 · 뿌리 단어',
        AppFlavor.toeic => '토익 단어 익히기 · RC',
        AppFlavor.toeicSpeaking => '토익스피킹 답변 틀 · 말하기 연습',
        AppFlavor.opic => 'OPIc 주제별 답변 · 표현',
      };

  static const String _define = String.fromEnvironment('APP', defaultValue: 'english');

  /// 지금 빌드된 앱.
  static final AppFlavor current = AppFlavor.values.firstWhere((f) => f.id == _define, orElse: () => AppFlavor.english);

  /// 이 앱에서 건너갈 수 있는 나머지 앱들.
  static List<AppFlavor> get others => AppFlavor.values.where((f) => f != current).toList();
}
