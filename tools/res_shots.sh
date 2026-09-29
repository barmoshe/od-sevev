#!/usr/bin/env bash
# Resolution check (integer art scaling, core/display.gd): renders the game at real device pixel
# sizes (the phone's CSS size × DPR = the web canvas's backing store) and reports how wide each
# art pixel is drawn. A crisp frame has one width only (k); the fork's stretch shows two (4 and 5).
#   tools/res_shots.sh [preset]       after  (integer scaling)
#   FORK=1 tools/res_shots.sh         before (the fork's fractional stretch)
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
SHOT="${1:-era1}"
TAG="after"; EXTRA=""
if [ "${FORK:-0}" = "1" ]; then TAG="before"; EXTRA="--fork-scale"; fi
OUT="$HERE/../build/shots/res"
mkdir -p "$OUT"
for dev in 390x844 390x664 375x812 360x800 428x926; do
  w=${dev%x*}; h=${dev#*x}
  for dpr in 2 3; do
    size="$((w * dpr))x$((h * dpr))"
    f="$OUT/$TAG-${dev}@${dpr}x.png"
    "$HERE/godot.sh" --path "$HERE/../game" --resolution 360x640 --position 0,0 -- --shot="$SHOT" --device="$size" --out="$f" --frames=60 $EXTRA 2>&1 | grep -E "^SHOT" | sed "s|^|$TAG $dev@${dpr}x |"
    python3 "$HERE/lib/pixel_runs.py" "$f"
  done
done
