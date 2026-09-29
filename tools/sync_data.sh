#!/usr/bin/env bash
# Copies the engine-agnostic spec data into the Godot project (res://data/), which Godot can
# only read from inside game/. The specs stay canonical: edit design/, ux/, audio/, then run
# this. tools/test.sh runs it first, and test_data_sync.gd fails if the copies drift.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$HERE/.."
DATA="$ROOT/game/data"
mkdir -p "$DATA"
cp "$ROOT/design/content.json" "$DATA/content.json"
cp "$ROOT/ux/ui-strings.json" "$DATA/ui-strings.json"
cp "$ROOT/audio/cues.json" "$DATA/cues.json"
cp "$ROOT/audio/music.json" "$DATA/music.json"
