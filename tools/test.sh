#!/usr/bin/env bash
# Headless test run: imports the project, runs tests/unit, fails on any failed assert
# or any GDScript error printed by the engine.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
GAME="$HERE/../game"
"$HERE/sync_data.sh"
"$HERE/godot.sh" --headless --path "$GAME" --import >/dev/null 2>&1
LOG="$(mktemp)"
"$HERE/godot.sh" --headless --path "$GAME" -s res://tests/run_tests.gd -- "$@" 2>&1 | tee "$LOG"
code=${PIPESTATUS[0]}
# "String formatting error": a bad `%` in a message ("5% ×" needs "%%"; GDScript has no %g).
# "Unicode parsing error": a NUL or broken UTF-8 in a script or string (leaders.gd's old "\u0000" key).
if grep -qE "SCRIPT ERROR|Parse Error|Invalid call|Invalid access|Nonexistent function|String formatting error|Unicode parsing error" "$LOG"; then
  echo "tools/test.sh: engine reported script errors" >&2
  code=1
fi
rm -f "$LOG"
exit $code
