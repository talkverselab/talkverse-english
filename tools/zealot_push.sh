#!/bin/bash
# 가장 최근 release APK 를 Zealot 에 올린다(맥미니 전용). 빌드는 하지 않는다.
#
#   tools/zealot_push.sh [--app <id>] ["변경 내용 한 줄"]        로컬에서 빌드한 APK
#   tools/zealot_push.sh [--app <id>] --ci ["변경 내용 한 줄"]   GitHub 릴리스(latest / latest-<id>)의 APK(CI 빌드)를 받아서
# --app = english(기본)|toeic|toeic_speaking|opic (앱내앱 2026-11-08). 변경 내용을 안 주면 최근 커밋 제목을 쓴다.
# 앱이름은 CLAUDE.md 의 「Zealot 앱이름」과 같아야 한다(lib/core/app_flavor.dart zealotName).
set -euo pipefail

FLAVOR=english
if [ "${1:-}" = "--app" ]; then FLAVOR="$2"; shift 2; fi
case "$FLAVOR" in
  english) APP_NAME="영어 유니버스"; TAG=latest ;;
  toeic) APP_NAME="토익 유니버스"; TAG=latest-toeic ;;
  toeic_speaking) APP_NAME="토익스피킹 유니버스"; TAG=latest-toeic_speaking ;;
  opic) APP_NAME="OPIc 유니버스"; TAG=latest-opic ;;
  *) echo "모르는 앱: $FLAVOR" >&2; exit 1 ;;
esac
REPO="talkverselab/talkverse-english"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [ "${1:-}" = "--ci" ]; then
  shift
  mkdir -p build/zealot
  gh release download "$TAG" -R "$REPO" -p 'app-latest.apk' -D "build/zealot/$FLAVOR" --clobber
  APK="build/zealot/$FLAVOR/app-latest.apk"
else
  # 로컬 빌드 산출물 중 가장 최근 것
  APK="$(ls -t build/app/outputs/flutter-apk/app-$FLAVOR-release.apk 2>/dev/null | head -1 || true)"
  if [ -z "$APK" ]; then
    echo "release APK 가 없습니다. 먼저 빌드하거나(tools/apk_build.sh $FLAVOR) --ci 를 쓰세요." >&2
    exit 1
  fi
fi

NOTE="${1:-$(git log -1 --pretty=%s)}"

echo "올릴 파일: $APK ($(date -r "$APK" '+%Y-%m-%d %H:%M'))"
exec "$HOME/bin/zealot-upload" "$APK" "$APP_NAME" -c "$NOTE"
