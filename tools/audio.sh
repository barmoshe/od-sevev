#!/usr/bin/env bash
# Regenerates every sound of עוד סבב into game/assets/audio/od/ (audio/od/cue-spec.md):
#   tools/gen_od_sevev.gd  audio/od/music.json + audio/od/cues.json -> od/*.res (QOA, loops built in,
#                          one file per pitch) + od/od_manifest.json (every runtime number)
# About a minute. Deterministic: run it twice, same bytes (tools/audio.sh --check does exactly that
# and compares every file with shasum). A generator that fails or prints a script error fails the run.
#
# Retired from the build path at the od cut-over (2026-09-29, game-developer audio): the fork's
# tools/gen_audio.gd (sfx_*.wav) and tools/gen_music.gd (music_*.res, amb_*.res). Their files stay in
# tools/, and their last renders in game/assets/audio/legacy/ (.gdignore: never imported or exported).
# MB_LEGACY_AUDIO=1 tools/audio.sh still runs them, into game/assets/audio/ (move them back out after).
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/lib/platform.sh"
GAME="$HERE/../game"
AUDIO="$GAME/assets/audio"

# runs one generator; prints its summary line, fails on a non-zero exit or any script error
run_gen() {
  local log
  log="$(mktemp)"
  if ! "$HERE/godot.sh" --headless --path "$GAME" -s "$HERE/$1" >"$log" 2>&1 \
      || grep -qE "SCRIPT ERROR|Parse Error|Invalid call|Invalid access|Nonexistent function" "$log"; then
    cat "$log" >&2
    rm -f "$log"
    echo "audio.sh: $1 failed" >&2
    exit 1
  fi
  grep -E "^gen_" "$log" | tail -n 1
  rm -f "$log"
}

generate() {
  "$HERE/sync_data.sh"
  "$HERE/godot.sh" --headless --path "$GAME" --import >/dev/null 2>&1 || true
  if [ "${MB_LEGACY_AUDIO:-0}" = "1" ]; then
    run_gen gen_audio.gd
    run_gen gen_music.gd
  fi
  # עוד סבב (Audio Director, 2026-09-28): audio/od/*.json -> game/assets/audio/od/*.res + od_manifest.json
  run_gen gen_od_sevev.gd
  "$HERE/godot.sh" --headless --path "$GAME" --import >/dev/null 2>&1 || true
}

snapshot() {
  (cd "$AUDIO" && find ./od -maxdepth 1 -type f \( -name '*.res' -o -name 'od_manifest.json' \) | LC_ALL=C sort | xargs shasum -a 256)
}

generate
if [ "${1:-}" = "--check" ]; then
  A="$(mktemp)"; B="$(mktemp)"
  snapshot > "$A"
  generate
  snapshot > "$B"
  if diff -q "$A" "$B" >/dev/null; then
    echo "audio.sh: deterministic ($(wc -l < "$A" | tr -d ' ') files identical across two runs)"
    rm -f "$A" "$B"
  else
    echo "audio.sh: NOT deterministic:" >&2
    diff "$A" "$B" >&2 || true
    rm -f "$A" "$B"
    exit 1
  fi
fi
mb() { cat "$@" | wc -c | awk '{ printf "%.2f MB", $1 / 1048576 }'; }
echo "audio.sh: od-sevev $(ls "$AUDIO"/od/*.res | wc -l | tr -d ' ') files ($(mb "$AUDIO"/od/*.res))"
