#!/usr/bin/env bash
# Build-time pixel-width lint for every player-facing string (game/tests/lint/lint_text.gd):
# ux/string-budgets.json boxes, measured with the real text route (TextServer + the Hebrew pixel
# font). Exits non-zero on any overflow or missing glyph. tools/build_web.sh runs it first.
#   tools/lint_text.sh            lint (prints failures and notes)
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
GAME="$HERE/../game"
"$HERE/sync_data.sh"
"$HERE/godot.sh" --headless --path "$GAME" --import >/dev/null 2>&1
LOG="$(mktemp)"
"$HERE/godot.sh" --headless --path "$GAME" -s res://tests/lint/run_lint.gd 2>&1 | tee "$LOG"
code=${PIPESTATUS[0]}
if grep -qE "SCRIPT ERROR|Parse Error" "$LOG"; then
  echo "tools/lint_text.sh: engine reported script errors" >&2
  code=1
fi
rm -f "$LOG"
exit $code
