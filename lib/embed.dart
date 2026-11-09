import 'package:flutter/material.dart';

import 'core/app_flavor.dart';
import 'core/embed_env.dart';
import 'core/l10n.dart';
import 'core/theme.dart';
import 'screens/main_screen.dart';
import 'screens/sync_screen.dart';
import 'services/achievement_service.dart';
import 'services/content_sync.dart';
import 'services/data_version.dart';
import 'services/learner_prefs.dart';
import 'services/tts_service.dart';
import 'toeic/toeic_home.dart';
import 'widgets/stress_text.dart';

export 'core/embed_env.dart' show embedded;

/// 통합 앱(Talkverse) 연결점 — 2026-11-09 `~/talkverse/talkverse-app/EMBED_GUIDE.md`(일본어앱 d0da8b6 와 같은 틀).
/// 단독 앱 `main()` 도 이 두 함수를 쓴다: `await embedInit(standalone: true)` → `runApp(embedApp(...))`.
/// 통합 앱: `await embedInit()` → 이 언어 화면을 열 때 `embedApp(onSwitchLanguage: …)`. 통합 앱에서는 영어(english) 화면만 쓴다.

bool _inited = false;
bool _syncFirst = false;

/// 「다른 언어 배우기」 — 통합 앱이 넘긴 콜백(없으면 메뉴를 안 보인다).
VoidCallback? switchLanguage;

/// 초기화 전부(화면 방향·runApp 제외). 여러 번 불러도 한 번만 한다.
Future<void> embedInit({bool standalone = false}) async {
  if (_inited) return;
  _inited = true;
  embedded = !standalone;
  WidgetsFlutterBinding.ensureInitialized();
  await LearnerPrefs.load();
  await StressPrefs.load();
  await AccentPrefs.load();
  await AchievementService.instance.load();
  await DataVersion.applyIfChanged(); // 데이터 업데이트 번호(version.json db)가 바뀌면 기기 캐시 갱신
  // 그림(장면 컷·단어 그림) 기기 내려받기: 버전이 다르면 로딩 화면에서 받고 시작(2026-11-04)
  final v = WidgetsBinding.instance.platformDispatcher.views.first;
  final wide = v.physicalSize.shortestSide / v.devicePixelRatio >= 600;
  _syncFirst = await ContentSync.instance.init(large: wide);
}

/// runApp 에 넘기는 위젯. [onSwitchLanguage] 가 있으면 프로필 맨 위에 「다른 언어 배우기」.
/// [onOrientation] = 단독 앱이 화면 방향을 다시 계산할 때(통합 앱은 넘기지 않는다).
Widget embedApp({VoidCallback? onSwitchLanguage, void Function(double shortest)? onOrientation}) {
  switchLanguage = onSwitchLanguage;
  return EnglishUniverseApp(syncFirst: _syncFirst, onOrientation: onOrientation);
}

class EnglishUniverseApp extends StatelessWidget {
  final bool syncFirst;
  final void Function(double shortest)? onOrientation;
  const EnglishUniverseApp({super.key, this.syncFirst = false, this.onOrientation});

  /// 앱내앱(2026-11-08): 빌드된 앱(--dart-define=APP)에 따라 첫 화면이 다르다. 통합 앱에서는 english.
  static Widget get _home => switch (embedded ? AppFlavor.english : AppFlavor.current) {
        AppFlavor.english => const MainScreen(),
        AppFlavor.toeic || AppFlavor.toeicSpeaking || AppFlavor.opic => const ToeicHome(),
      };

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: tr(AppFlavor.current.nameKo),
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.light,
      home: syncFirst ? SyncScreen(next: _home) : _home,
      // 아이폰 Dynamic Type·갤럭시 글자 크기 설정이 커도 타일이 깨지지 않게 1.2배까지만
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        if (onOrientation != null) WidgetsBinding.instance.addPostFrameCallback((_) => onOrientation!(mq.size.shortestSide));
        return MediaQuery(
          data: mq.copyWith(textScaler: mq.textScaler.clamp(maxScaleFactor: 1.2)),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
