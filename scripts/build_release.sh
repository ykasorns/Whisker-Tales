#!/usr/bin/env bash
# Release build from the command line only (T-030, D-035).
#
#   scripts/build_release.sh            # Play upload: app bundle (.aab)
#   scripts/build_release.sh --apk      # phone test: arm64 APK
#   scripts/build_release.sh --arm64-only   # bundle for 64-bit ARM phones only
#   scripts/build_release.sh --skip-tests
#
# Release values (none are committed):
#   app/android/key.properties   upload keystore (see RELEASE_CHECKLIST.md)
#   app/android/gradle.properties: admobAppId=…  pgsProjectId=…
#   env ADMOB_REWARDED_ID=ca-app-pub-…/…   rewarded ad unit
# Anything missing is reported; the build still runs with test values so a
# test build never needs the real keys.
#
# 8 GB Macs: if the build dies with "Killed: 9" / exit 137 (the Dart AOT
# compiler ran out of memory), close Chrome and other big apps and retry,
# or use --apk (one ABI). gradle.properties already runs one compile at a time.
#
# A bundle hangs forever with no CPU use: macOS has not yet allowed Flutter's
# AOT compiler for that ABI to run (it is still quarantined from the
# download). Check with `xattr -l` on …/engine/android-*-release/darwin-x64/
# gen_snapshot; allow it once yourself, or build with --arm64-only.
set -euo pipefail
cd "$(dirname "$0")/.."

MODE=aab
TESTS=1
ABIS=
for a in "$@"; do
  case "$a" in
    --apk) MODE=apk ;;
    --skip-tests) TESTS=0 ;;
    --arm64-only) ABIS=--target-platform=android-arm64 ;;
    *) echo "unknown option: $a" >&2; exit 2 ;;
  esac
done

warn() { printf '\033[33m! %s\033[0m\n' "$*"; }
step() { printf '\033[36m== %s\033[0m\n' "$*"; }

command -v flutter >/dev/null || { echo "flutter is not on PATH" >&2; exit 1; }

step "release values"
RELEASE_READY=1
if [[ ! -f app/android/key.properties ]]; then
  warn "no app/android/key.properties → signed with the DEBUG key (Play will refuse it)"
  RELEASE_READY=0
fi
if ! grep -qs '^admobAppId=' app/android/gradle.properties; then
  warn "no admobAppId in app/android/gradle.properties → Google's sample app id (test ads only)"
  RELEASE_READY=0
fi
if [[ -z "${ADMOB_REWARDED_ID:-}" ]]; then
  warn "ADMOB_REWARDED_ID not set → Google's sample rewarded unit (test ads only)"
  RELEASE_READY=0
fi
if ! grep -qs '^pgsProjectId=' app/android/gradle.properties; then
  warn "no pgsProjectId → cloud save stays off (the game is fully offline)"
fi

step "game data → app bundle"
bash tools/sync_content.sh

if [[ $TESTS == 1 ]]; then
  step "analyze + tests (wt_core)"
  (cd packages/wt_core && flutter pub get >/dev/null && flutter analyze && flutter test)
  step "analyze + tests (app)"
  (cd app && flutter pub get >/dev/null && flutter analyze && flutter test)
fi

DEFINES=()
[[ -n "${ADMOB_REWARDED_ID:-}" ]] && DEFINES+=("--dart-define=ADMOB_REWARDED_ID=$ADMOB_REWARDED_ID")

step "build ($MODE)"
cd app
if [[ $MODE == aab ]]; then
  flutter build appbundle --release $ABIS ${DEFINES[@]+"${DEFINES[@]}"}
  OUT=build/app/outputs/bundle/release/app-release.aab
else
  flutter build apk --release --split-per-abi --target-platform android-arm64 ${DEFINES[@]+"${DEFINES[@]}"}
  OUT=build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
fi
ls -l "$OUT"

# the Families checks Play cares about, on the merged manifest
M=$(find build/app/intermediates/merged_manifest/release -name AndroidManifest.xml | head -1)
if grep -q 'permission.AD_ID\|ACCESS_ADSERVICES' "$M"; then
  echo "advertising-ID permission found in the merged manifest (D-033)" >&2
  exit 1
fi
grep -q 'targetSdkVersion="3[6-9]"' "$M" || warn "targetSdk below 36 (Play needs 36 since 2026-08-31)"

if [[ $RELEASE_READY == 1 ]]; then
  step "ready to upload: app/$OUT"
else
  warn "built with test values — fine for testing, not for Play (see warnings above)"
fi
