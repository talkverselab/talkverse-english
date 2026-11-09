import 'package:english_universe/core/embed_env.dart';
import 'package:english_universe/core/prefs.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 통합 앱 연결(EMBED_GUIDE) — 에셋 접두, 설정 키 접두와 단독 앱 옛 키 1회 이전.
void main() {
  test('asset path prefix', () {
    embedded = false;
    expect(assetPath('assets/data/version.json'), 'assets/data/version.json');
    embedded = true;
    expect(assetPath('assets/data/version.json'), 'packages/english_universe/assets/data/version.json');
    expect(stripAssetPrefix('packages/english_universe/assets/x.json'), 'assets/x.json');
    embedded = false;
  });

  test('prefs prefix and one-time migration', () async {
    SharedPreferences.setMockInitialValues({'accent': 'us', 'ja_level': 'R1'});
    embedded = false;
    final p = await Prefs.getInstance();
    expect(p.getString('accent'), 'us'); // 옛 키가 en_accent 로 옮겨짐
    final raw = await SharedPreferences.getInstance();
    expect(raw.getString('en_accent'), 'us');
    expect(raw.containsKey('accent'), isFalse);
    // 이전은 단독 앱에서만 한 번(단독 영어앱 저장소엔 이 앱 키만 있다). 통합 앱(embedded)에서는 옮기지 않는다.
    expect(raw.getBool('en__migrated_v1'), isTrue);
  });
}
