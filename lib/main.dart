import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'embed.dart';

/// 단독 앱(영어·토익·토익스피킹·OPIc 유니버스). 초기화와 화면은 embed.dart — 통합 앱(Talkverse)도 같은 두 함수를 쓴다.
void main() async {
  await embedInit(standalone: true);
  await _setOrientations(); // 폰은 세로 고정, 태블릿·폴드 펼침(짧은 변 600 이상)은 회전 허용
  runApp(embedApp(onOrientation: _setOrientations));
}

bool? _wide;

/// 짧은 변 600 이상(아이패드·태블릿·폴드 펼침)이면 가로 회전 허용, 아니면 세로 고정. 폴드를 접고 펼 때마다 다시 계산한다.
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
