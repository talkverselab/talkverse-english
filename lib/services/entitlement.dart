import '../core/app_flavor.dart';
import 'curriculum_plan.dart';
import 'purchase.dart';

/// 무료/유료 구분(PAYWALL_SPEC §2, 2026-11-23). 잠금 값은 서버 커리큘럼 JSON(단계 free·freeSenseLevels)이 정한다.
/// - 무료: 커리큘럼 1단계, 회화 R0·R1, 단어·발음 기본, 언어감각 1급.
/// - 유료: 커리큘럼 2단계 이상, 회화 R2 이상, 언어감각 2급 이상.
/// 이용권 상품은 영어(english)만 판다 — 토익·토익스피킹·OPIc 앱은 잠그지 않는다.
class Entitlement {
  Entitlement._();

  static bool get sells => AppFlavor.current == AppFlavor.english;
  static bool get premium => !sells || Purchase.active;

  /// 커리큘럼 단계(1~5, 또는 서버 목록이 없을 때의 R 코드).
  static bool stageOpen(String n) {
    if (premium) return true;
    for (final s in CurriculumPlan.instance.stages) {
      if (s.n == n) return s.free;
    }
    return n == '1' || n == 'R0' || n == 'R1';
  }

  /// 회화 편 — R0·R1 은 무료.
  static bool regionOpen(String region) => premium || region == 'R0' || region == 'R1';

  /// 언어감각 급(0 부터 센 순서) — 앞 freeSenseLevels 급만 무료.
  static bool senseOpen(int levelIndex) => premium || levelIndex < CurriculumPlan.instance.freeSenseLevels;
}
