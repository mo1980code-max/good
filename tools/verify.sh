#!/usr/bin/env bash
# Sparkle Nail Spa — verification script.
#
# Runs everything that could not be executed inside the sandbox (which has no
# Flutter SDK) and writes a report to docs/verification-result.txt.
#
# Usage:  bash tools/verify.sh
set -uo pipefail

REPORT="docs/verification-result.txt"
FLUTTER="${FLUTTER:-flutter}"

if ! command -v "$FLUTTER" >/dev/null 2>&1; then
  echo "❌ Flutter not found on PATH. Install the SDK first:" >&2
  echo "   https://docs.flutter.dev/get-started/install" >&2
  exit 127
fi

{
  echo "Sparkle Nail Spa — verification report"
  echo "date   : $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
  echo "flutter: $("$FLUTTER" --version 2>&1 | head -1)"
  echo "dart   : $("$FLUTTER" --version --machine 2>/dev/null | head -c 200)"
  echo "=========================================================="

  run() {
    echo
    echo "--- \$ $*"
    "$@" 2>&1
    echo "--- exit code: $?"
  }

  run "$FLUTTER" pub get
  run "$FLUTTER" analyze
  run "$FLUTTER" test

  echo
  echo "=========================================================="
  echo "Structure checks (no SDK needed):"
  echo "  dart files: $(find lib -name '*.dart' | wc -l)"
  echo "  test files: $(find test -name '*.dart' | wc -l)"
  echo "  audio files: $(find assets/audio -name '*.mp3' | wc -l)"
  echo "  image files: $(find assets/images -name '*.png' | wc -l)"
  echo "  assets size: $(du -sh assets | cut -f1)"
} | tee "$REPORT"

echo
echo "Report saved to $REPORT"
echo "Then, on a device:  $FLUTTER run"
