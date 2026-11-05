import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

/// 데이터(단어·회화) 업데이트 번호 — 번들 `assets/data/version.json` 의 `db`(사용자 지시 2026-11-04, 모든 언어앱 공통).
///
/// 영어앱은 아직 기기 DB 에 데이터를 넣지 않고(단어 = CSV 에셋, 회화 = JSON 에셋) 매니페스트 캐시만 기기에 둔다.
/// 번들 번호 ≠ 저장 번호면 기기에 남은 데이터 캐시(단어 그림 매니페스트)를 지워 새 데이터가 바로 보이게 하고 번호를 저장한다.
/// 나중에 기기 DB(SeedLoader)가 생기면 같은 번호로 "전부 다시 채움"을 판단한다. 데이터를 바꿀 때 이 번호만 올린다.
class DataVersion {
  DataVersion._();
  static const _kDbVersion = 'db_version';
  static const _resetKeys = ['art_manifest_en_v1', 'art_manifest_en_at'];

  static Future<int> bundled() async {
    try {
      final j = json.decode(await rootBundle.loadString('assets/data/version.json')) as Map<String, dynamic>;
      return (j['db'] as num).toInt();
    } catch (_) {
      return 0;
    }
  }

  /// 시작 때 한 번. 번호가 바뀌었으면 true.
  static Future<bool> applyIfChanged() async {
    final bundledV = await bundled();
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getInt(_kDbVersion) == bundledV) return false;
    for (final k in _resetKeys) {
      await prefs.remove(k);
    }
    await prefs.setInt(_kDbVersion, bundledV);
    debugPrint('DataVersion: db=$bundledV 로 갱신');
    return true;
  }
}
