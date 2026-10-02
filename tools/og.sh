#!/usr/bin/env bash
# The share platform's link-preview images (game/tests/og/gen_cards.gd): one 1200×630 JPEG per
# /s/<variant>/ stub into game/web/og/ (committed; tools/build_web.sh copies them and writes the
# stubs). Needs a renderer: a desktop session, or xvfb-run on a headless Linux (picked here).
#   tools/og.sh                     every stub's og:image (≈ 64 JPEGs, ≤ 250 KB each)
#   tools/og.sh preview <dir> [id]  every card kind × square / story × as-is / family-safe as PNGs
#                                   into <dir> (the design loop; [id] = the leader, default bibi)
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
GAME="$HERE/../game"
MODE="${1:-og}"
OUT="${2:-$GAME/web/og}"
ONLY="${3:-}"
mkdir -p "$OUT"
OUT="$(cd "$OUT" && pwd)"
"$HERE/godot.sh" --headless --path "$GAME" --import >/dev/null 2>&1 || true
RUN=()
if [ "$(uname)" = "Linux" ] && [ -z "${DISPLAY:-}" ] && [ -z "${WAYLAND_DISPLAY:-}" ]; then
  command -v xvfb-run >/dev/null || { echo "[og] no display and no xvfb-run: install xvfb (or run on a desktop)" >&2; exit 1; }
  RUN=(xvfb-run -a -s "-screen 0 1600x1200x24")
fi
"${RUN[@]}" "$HERE/godot.sh" --rendering-driver opengl3 --path "$GAME" -s res://tests/og/gen_cards.gd -- \
  --mode="$MODE" --out="$OUT/" ${ONLY:+--only="$ONLY"} 2>&1 | grep -vE "^(WARNING: All audio|     at: |ALSA|$)" | grep -E "gen_cards|ERROR|SCRIPT" || true
ls "$OUT" | wc -l | sed 's/^/[og] files: /'
