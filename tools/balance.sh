#!/usr/bin/env bash
# Pacing bench: plays whole sessions through the real economy (PacingSim.session) and checks the
# v2 pacing gates (game/tests/bench/test_session.gd). Slower than tools/test.sh (about a minute).
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
"$HERE/test.sh" --dir=bench "$@"
