import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/l10n.dart';
import 'core/theme.dart';
import 'screens/main_screen.dart';
import 'services/achievement_service.dart';
import 'services/learner_prefs.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LearnerPrefs.load();
  await AchievementService.instance.load();
  await _setOrientations(); // 폰은 세로 고정, 태블릿·폴드 펼침(짧은 변 600 이상)은 회전 허용
  runApp(const EnglishUniverseApp());
}

bool? _wide;

/// 짧은 변 600 이상(아이패드·태블릿·폴드 펼침)이면 가로 회전 허용, 아니면 세로 고정.
/// 폴드를 접고 펼 때마다 builder 에서 다시 계산한다.
Future<void> _setOrientations([double? shortest]) async {
  shortest ??= () {
    final v = WidgetsBinding.instance.platformDispatcher.views.first;
    return v.physicalSize.shortestSide / v.devicePixelRatio;
  }();
  final wide = shortest >= 600;
  if (wide == _wide && shortest != 0) return;
  _wide = wide;
  await SystemChrome.setPreferredOrientations(wide ? DeviceOrientation.values : [DeviceOrientation.portraitUp]);
}

class EnglishUniverseApp extends StatelessWidget {
  const EnglishUniverseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: tr('영어유니버스'),
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.light,
      home: const MainScreen(),
      // 아이폰 Dynamic Type·갤럭시 글자 크기 설정이 커도 타일이 깨지지 않게 1.2배까지만
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        WidgetsBinding.instance.addPostFrameCallback((_) => _setOrientations(mq.size.shortestSide));
        return MediaQuery(
          data: mq.copyWith(textScaler: mq.textScaler.clamp(maxScaleFactor: 1.2)),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
