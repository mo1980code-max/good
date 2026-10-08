#!/usr/bin/env bash
# Sparkle Nail Spa — verification script.
#
# Runs everything that could not be executed inside the sandbox (which has no
# Flutter SDK) and writes a report to docs/verification-result.txt.
#
# Usage:
#   bash tools/verify.sh          # doctor + pub get + analyze + test
#   bash tools/verify.sh --apk    # ... and then the release APK build
#
set -uo pipefail

REPORT="docs/verification-result.txt"
FLUTTER="${FLUTTER:-flutter}"
WANT_APK=0
for arg in "$@"; do
  case "$arg" in
    --apk|--release) WANT_APK=1 ;;
    -h|--help) echo "usage: bash tools/verify.sh [--apk]"; exit 0 ;;
    *) echo "unknown option: $arg (try --apk)" >&2; exit 2 ;;
  esac
done

if ! command -v "$FLUTTER" >/dev/null 2>&1; then
  echo "❌ Flutter not found on PATH. Install the SDK first:" >&2
  echo "   https://docs.flutter.dev/get-started/install" >&2
  exit 127
fi

{
  echo "Sparkle Nail Spa — release verification report"
  echo "date    : $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
  echo "flutter : $("$FLUTTER" --version 2>&1 | head -1)"
  echo "dart    : $("$FLUTTER" --version --machine 2>/dev/null | tr -d '\n' | head -c 300)"
  echo "commit  : $(git rev-parse --short HEAD 2>/dev/null || echo 'n/a')  ($(git branch --show-current 2>/dev/null || echo 'n/a'))"
  echo "apk     : $([ "$WANT_APK" = 1 ] && echo 'requested' || echo 'skipped (pass --apk)')"
  echo "=========================================================="

  run() {
    echo
    echo "--- \$ $*"
    "$@" 2>&1
    echo "--- exit code: $?"
  }

  # Step 1 — the machine itself.
  run "$FLUTTER" doctor -v

  # Step 2 — the project.
  run "$FLUTTER" pub get
  run "$FLUTTER" analyze
  run "$FLUTTER" test

  # Step 3 — only when asked (slow, and only worth it after steps 1-2 pass).
  if [ "$WANT_APK" = 1 ]; then
    run "$FLUTTER" build apk --release
  fi

  echo
  echo "=========================================================="
  echo "Structure checks (no SDK needed):"
  echo "  dart files : $(find lib -name '*.dart' | wc -l)"
  echo "  test files : $(find test -name '*.dart' | wc -l)"
  echo "  audio files: $(find assets/audio -name '*.mp3' | wc -l)"
  echo "  image files: $(find assets/images -name '*.png' | wc -l)"
  echo "  assets size: $(du -sh assets | cut -f1)"
  echo
  echo "Next:"
  echo "  1. $FLUTTER run            # on a device or emulator"
  echo "  2. walk the 30-point checklist in docs/verification.md"
  echo "  3. bash tools/verify.sh --apk   # when everything above is green"
} | tee "$REPORT"

echo
echo "Report saved to $REPORT"
echo "Then: $FLUTTER run  →  docs/verification.md checklist  →  bash tools/verify.sh --apk"
