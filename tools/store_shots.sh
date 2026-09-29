#!/usr/bin/env bash
# Store screenshots into store/screenshots/: each preset (main.gd _shot_state) rendered in a real
# window at the phone size, animated for a few seconds, then saved. Never touches the save file.
#   tools/store_shots.sh                 6.9-inch iPhone portrait (1320 x 2868)
#   RES=1080x2400 tools/store_shots.sh   a Play Store phone set
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
RES="${RES:-1320x2868}"
OUT="$HERE/../store/screenshots/$RES"
mkdir -p "$OUT"
"$HERE/godot.sh" --headless --path "$HERE/../game" --import >/dev/null 2>&1 || true
n=1
# era0/era2/era3 = the first, third and last content eras (main.gd _shot_state), by index.
for shot in era0 era2 era3 perks book story; do
  "$HERE/godot.sh" --path "$HERE/../game" --resolution 360x782 --position 0,0 -- --shot=$shot --out="$OUT/$n-$shot.png" --frames=180 --target="$RES" 2>&1 | grep -E "^SHOT|ERROR" || echo "FAILED $shot"
  n=$((n + 1))
done
ls -la "$OUT" | awk 'NR>1 {print "  " $5 "  " $9}'
