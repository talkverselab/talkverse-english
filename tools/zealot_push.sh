#!/bin/bash
# 가장 최근 release APK 를 Zealot 에 올린다(맥미니 전용). 빌드는 하지 않는다.
#
#   tools/zealot_push.sh ["변경 내용 한 줄"]        로컬에서 빌드한 APK
#   tools/zealot_push.sh --ci ["변경 내용 한 줄"]   GitHub latest 릴리스의 APK(CI 빌드)를 받아서
#
# 변경 내용을 안 주면 최근 커밋 제목을 쓴다. 앱이름은 CLAUDE.md 의 「Zealot 앱이름」과 같아야 한다.
set -euo pipefail

APP_NAME="영어 유니버스"
REPO="talkverselab/talkverse-english"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [ "${1:-}" = "--ci" ]; then
  shift
  mkdir -p build/zealot
  gh release download latest -R "$REPO" -p 'app-latest.apk' -D build/zealot --clobber
  APK="build/zealot/app-latest.apk"
else
  # 로컬 빌드 산출물 중 가장 최근 것
  APK="$(ls -t build/app/outputs/flutter-apk/app-release.apk \
               build/app/outputs/apk/release/*.apk 2>/dev/null | head -1 || true)"
  if [ -z "$APK" ]; then
    echo "release APK 가 없습니다. 먼저 빌드하거나(flutter build apk --release --build-number=<번호>) --ci 를 쓰세요." >&2
    exit 1
  fi
fi

NOTE="${1:-$(git log -1 --pretty=%s)}"

echo "올릴 파일: $APK ($(date -r "$APK" '+%Y-%m-%d %H:%M'))"
exec "$HOME/bin/zealot-upload" "$APK" "$APP_NAME" -c "$NOTE"
