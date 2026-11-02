# CLAUDE.md — talkverselab/talkverse-english (영어유니버스)

이 폴더에서 작업하는 모든 세션이 먼저 읽는 규칙. 구조는 일본어앱(`~/talkverse/ja`)을 그대로 따른다 —
공통 순서·완성 기준은 `~/talkverse/LANG_APP_REPLICATE_PROMPT.md`, 세부 규칙은 `~/talkverse/ja/docs/REPLICATE_FOR_OTHER_LANGS.md`.
**Grab(`~/talkverse/en`)과는 별개 앱**이다 — 이 저장소에서 Grab 코드를 고치지 않는다.

## 0. 지금 상태에서 지킬 것
- **회화·단어·예문 같은 학습 콘텐츠는 사용자 지시 전까지 만들지 않는다.** 데이터가 없으면 화면은 빈 안내를 보인다.
- 공개 저장소: 자막·말뭉치·책·영상·브랜드 이름, 실존 인물 이름을 코드·에셋·문서·커밋 어디에도 넣지 않는다.
- 커밋은 바꾼 파일만 경로를 지정해서(`git add -A` 금지). 빌드 도구가 바꾸는 파일(`ios/Podfile*`, pbxproj 의 Pods·SPM 줄, xcscheme, xcworkspace, `**/swiftpm/`)은 되돌린다.
- 문서만 바꾼 푸시는 빌드가 안 돈다(`**.md` paths-ignore). 앱 코드가 아닌 것(그림·요청문)은 커밋 제목에 `[skip ci]`.

## 1. 서명 — 새 키를 만들지 말 것
- Android 키 = 맥미니6 `~/.android/debug.keystore`(alias `androiddebugkey`, 비밀번호는 Android debug 기본값).
  SHA-1 `72:08:02:58:F3:B8:EB:AC:2C:92:93:FB:7D:BE:E3:37:7E:77:E7:BB` · SHA-256 `A2:7F:9B:30:…:E4:00`.
  백업 = Doppler `keys/prd` 의 `ANDROID_DEBUG_KEYSTORE_B64`. CI 는 리포 시크릿 `ANDROID_DEBUG_KEYSTORE_BASE64`(같은 키)로 서명한다.
- 로컬 릴리스 빌드: `cp ~/.android/debug.keystore android/app/signing-key.jks` + `android/key.properties`
  (`storePassword`·`keyPassword`·`keyAlias=androiddebugkey`·`storeFile=signing-key.jks`). 둘 다 커밋 금지(.gitignore).
- CI 의 `Restore signing key` 단계와 `build.gradle.kts` 의 release 서명을 지우지 말 것(러너는 debug 키를 매번 새로 만든다).
- 설치가 `INSTALL_FAILED_UPDATE_INCOMPATIBLE` 이면 앱을 지우기 전에 `apksigner verify --print-certs` 로 SHA-1 비교.

## 2. 배포
- `master` 푸시 → `.github/workflows/release.yml` 이 서명된 APK 와 `latest.json` 을 `latest` 릴리스에 올린다(빌드 번호 = 실행 번호).
  앱 「나 → 앱 업데이트」(Android)가 이 릴리스를 본다(`lib/services/update_service.dart`).
- 앱 ID: Android `com.talkverse.english_universe` · iOS 번들 `com.talkverse.englishUniverse` · 팀 `QP8QRMA9CC`.

### 2-1. Zealot
- **Zealot 앱이름: 영어 유니버스** (고정 — 바꾸면 Zealot 에 다른 앱이 새로 생긴다)
- `tools/zealot_push.sh --ci ["변경 한 줄"]` — CI 의 `latest` APK 를 받아 올린다. 로컬 빌드는 버전 코드가 작아 다운그레이드 거부.

### 2-2. iOS TestFlight
- 사용자가 먼저 App Store Connect 앱 레코드(번들 ID `com.talkverse.englishUniverse`)와 TestFlight 내부 그룹을 만든다.
- `bash tools/ios_release.sh` 를 백그라운드로(8~12분, 빌드 번호 = KST yymmddHHMM). 레코드가 없으면 업로드가 `missingApp`.

## 3. 확인
- **M6 부하(2026-11-03)**: 빌드 전 `pgrep -f flutter_tools.snapshot | wc -l` 이 3 이상이면 1분씩 기다린다. 시뮬레이터는 쓰고 바로 끈다.
- 리포 시크릿을 Windows 에서 넣을 때는 파이프(`|`) 말고 `$v = …; gh secret set … --body $v` (파이프는 값이 비거나 깨졌다).
- `flutter analyze` · `flutter test` 통과 뒤 커밋.
- 아이패드 스크린샷: 자기 시뮬레이터 1대만(`en-shots iPad Air 11`, iOS 26.5) →
  `python3 tools/pane_shots.py <UDID> <스크래치 폴더> integration_test/dialogue_pane_test.dart` → 로그 `overflowed by` 0 → 사진을 직접 본다 → `xcrun simctl shutdown <UDID>`.

## 4. 그림
- 캐릭터·UX 시안 요청은 한자 세션 경유(공통 프롬프터 §9). 결과 `data/review/art/`·`data/review/uxui/`.
- 단어 그림 `https://auth.talkverse.uk/art/en/manifest`(2026-11-03 현재 0개 → 이모지 카드), 장면 컷 `…/art/en/scene/manifest?episode=<편id>`.
  영어는 라틴 문자라 그림 단어 매칭(`ArtService.urlInText`)을 낱말 단위로 한다.
