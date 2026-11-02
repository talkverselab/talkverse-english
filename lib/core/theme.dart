import 'package:flutter/material.dart';

/// 컬러 팔레트 — talkverse.uk 영어 페이지 톤(일본어앱 구조 복제, 2026-11-03).
///
/// 사이트 https://talkverse.uk/talkverse/lang/en 의 강조 `--a: #635bff`·`--a2: #bebbfb`.
/// `--a` 가 공용 토큰 인디고(`ai`)와 같아서 포인트(`beni`)는 글자 대비를 위해 한 단계 진한 `#4F46E5`.
/// 이름(beni·ai·kin·sumi·washi…)은 일본어앱 화면 코드가 그대로 쓰는 별칭이고, 값만 영어앱 것이다.
class AppColors {
  // 포인트 — 사이트 `--a` 를 한 단계 진하게
  static const Color beni = Color(0xFF4F46E5);
  static const Color beniDeep = Color(0xFF3730A3);
  static const Color beniLight = Color(0xFFBEBBFB); // 사이트 `--a2`

  // 副色 — 옛 藍 자리. 사이트 `--accent` 인디고(링크·보조 강조·화자 A)
  static const Color ai = Color(0xFF635BFF);
  static const Color aiDeep = Color(0xFF4B44D6);
  static const Color aiLight = Color(0xFFA9A4FF);

  // 옛 金 자리 — 테두리는 사이트 `--line` 계열, 밝은 강조는 `--a2` 금빛, 진한 쪽은 워드마크 황갈
  static const Color kin = Color(0xFFDDE3EC);
  static const Color kinBright = Color(0xFFF5C07A);
  static const Color kinDeep = Color(0xFF8B85FF);

  // 墨 — 사이트 `--ink` / `--body`
  static const Color sumi = Color(0xFF0A2540);
  static const Color sumiLight = Color(0xFF425466);

  // 和紙 — 흰 바탕 / `--soft`
  static const Color washi = Color(0xFFFFFFFF);
  static const Color washiDeep = Color(0xFFF6F9FC);

  // 抹茶 — 완료·학습됨(사이트 `--ok`)
  static const Color matcha = Color(0xFF0E6245);

  // 桜 — 보조 강조(사이트 메시 분홍 / `--danger` 장미색)
  static const Color sakura = Color(0xFFF5B8E6);
  static const Color sakuraDeep = Color(0xFFCD3D64);

  // 사이트 토큰 그대로
  static const Color line = Color(0xFFE6EBF1);
  static const Color muted = Color(0xFF6B7C93);


  // brand alias
  static const Color brand = beni;

  /// 「영어」 워드마크 그라데이션(왼쪽 진한 인디고 → 오른쪽 옅은 인디고). 제목 글자·도장·구분선에 쓴다.
  static const LinearGradient wordmark = LinearGradient(colors: [beni, kinDeep]);
}

/// 카드·타일 공통 그림자(사이트 `0 2px 5px -1px rgba(50,50,93,.1), 0 1px 3px -1px rgba(0,0,0,.1)`)
const List<BoxShadow> kCardShadow = [
  BoxShadow(color: Color(0x1A32325D), blurRadius: 5, offset: Offset(0, 2)),
  BoxShadow(color: Color(0x1A000000), blurRadius: 3, offset: Offset(0, 1)),
];

class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.beni,
        onPrimary: Colors.white,
        primaryContainer: const Color(0xFFEDEBFF),
        onPrimaryContainer: AppColors.sumi,
        secondary: AppColors.ai,
        onSecondary: Colors.white,
        secondaryContainer: const Color(0xFFEFEEFE),
        onSecondaryContainer: AppColors.sumi,
        tertiary: AppColors.matcha,
        onTertiary: Colors.white,
        tertiaryContainer: const Color(0xFFD5EADF),
        onTertiaryContainer: AppColors.sumi,
        error: AppColors.sakuraDeep,
        onError: Colors.white,
        surface: AppColors.washi,
        onSurface: AppColors.sumi,
        surfaceContainerHighest: AppColors.washiDeep,
        onSurfaceVariant: AppColors.sumiLight,
        outline: AppColors.muted,
        outlineVariant: AppColors.line,
      ),
      scaffoldBackgroundColor: AppColors.washi,
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.washi,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.sumi,
        shape: Border(bottom: BorderSide(color: AppColors.line)),
        titleTextStyle: TextStyle(
          color: AppColors.sumi,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.washi,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.line),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.washi,
        surfaceTintColor: Colors.transparent,
        indicatorColor: const Color(0xFFEDEBFF),
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? AppColors.beni : AppColors.muted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.beniDeep : AppColors.muted,
            size: 24,
          );
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.washiDeep,
        labelStyle: const TextStyle(color: AppColors.sumiLight, fontWeight: FontWeight.w600),
        side: BorderSide.none,
        shape: const StadiumBorder(),
        selectedColor: const Color(0xFFEDEBFF),
        secondaryLabelStyle: const TextStyle(color: AppColors.beniDeep),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.beni,
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.sumi,
          side: const BorderSide(color: AppColors.line),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.line, thickness: 1),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.beni,
        textColor: AppColors.sumi,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.washi,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.beni,
        brightness: Brightness.dark,
      ),
    );
  }
}

/// 두 화면(왼쪽 목록 | 오른쪽 내용) 기준 — 가로 720 논리픽셀 이상: 아이패드(세로·가로)·안드로이드 태블릿·
/// 갤럭시/아이폰 폴드 펼침(세로 ≈740 포함). 접은 폴드·일반 폰은 한 화면. 한자유니버스와 같은 기준(사용자 지시 2026-11-01).
const wideMin = 720.0;
bool isWide(BuildContext context) => MediaQuery.sizeOf(context).width >= wideMin;
