#!/bin/bash
# 로컬 APK 빌드(앱내앱): bash tools/apk_build.sh [english|toeic|toeic_speaking|opic] [빌드번호]
# 서명 = android/key.properties(CLAUDE.md §1). 산출물 build/app/outputs/flutter-apk/app-<앱>-release.apk
set -euo pipefail
cd "$(dirname "$0")/.."
APP="${1:-english}"; BUILD="${2:-$(TZ=Asia/Seoul date +%y%m%d%H)}"   # Android 상한 2,100,000,000 → 8자리(yymmddHH)
flutter build apk --release --flavor "$APP" --dart-define=APP="$APP" --build-number="$BUILD"
ls -la "build/app/outputs/flutter-apk/app-$APP-release.apk"
