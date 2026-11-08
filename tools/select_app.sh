#!/bin/bash
# 앱내앱 고르기(iOS 쪽): ios/Flutter/App.xcconfig 에 번들 ID·표시 이름·URL 스킴·아이콘을 쓴다(lib/core/app_flavor.dart 와 같은 값).
#   bash tools/select_app.sh english|toeic|toeic_speaking|opic
# Android 는 productFlavor(--flavor), Dart 는 --dart-define=APP — tools/ios_release.sh 와 tools/apk_build.sh 가 함께 넘긴다.
# 기본값(저장소에 커밋된 App.xcconfig)은 english. 다른 앱을 빌드한 뒤에는 english 로 되돌려 둘 것(커밋에 섞이지 않게).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="${1:-english}"
case "$APP" in
  english)        BID=com.talkverse.englishUniverse; NAME=영어유니버스;       SCHEME=talkverse-english;       ICON=AppIcon ;;
  toeic)          BID=com.talkverse.toeic;           NAME=토익유니버스;       SCHEME=talkverse-toeic;         ICON=AppIcon ;;
  toeic_speaking) BID=com.talkverse.toeicSpeaking;   NAME=토익스피킹유니버스; SCHEME=talkverse-toeicspeaking; ICON=AppIcon ;;
  opic)           BID=com.talkverse.opic;            NAME=OPIc유니버스;       SCHEME=talkverse-opic;          ICON=AppIcon ;;
  *) echo "모르는 앱: $APP (english|toeic|toeic_speaking|opic)" >&2; exit 1 ;;
esac
# 아이콘: 앱별 세트(AppIcon-toeic 등)가 ios/Runner/Assets.xcassets 에 생기면 그걸 쓴다(uk 세션이 만든다)
[ -d "$ROOT/ios/Runner/Assets.xcassets/AppIcon-$APP.appiconset" ] && ICON="AppIcon-$APP"
cat > "$ROOT/ios/Flutter/App.xcconfig" <<X
// tools/select_app.sh 가 쓴다 — 손으로 고치지 말 것. 지금 앱: $APP
APP_ID = $APP
APP_BUNDLE_ID = $BID
APP_DISPLAY_NAME = $NAME
APP_SCHEME = $SCHEME
APP_ICON = $ICON
X
echo "iOS 앱 = $APP ($BID · $NAME · $SCHEME:// · $ICON)"
