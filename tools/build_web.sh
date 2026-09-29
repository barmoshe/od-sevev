#!/usr/bin/env bash
# Builds the web version (single-threaded, runs in iPhone Safari) into build/web/.
#   tools/build_web.sh           export build/web/index.html (+ .wasm, .pck, PWA files)
# The Godot web export templates are fetched on first use into the local template folder
# (outside the repo). Hosting: Vercel, static, no build step (tools/deploy_web.sh).
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/lib/platform.sh"
mkdir -p "$HERE/../build"
GAME="$HERE/../game"
OUT="$HERE/../build/web"
VER="4.7.2"
TPL_DIR="$GODOT_TPL_ROOT/${VER}.stable"
CACHE="${MB_BUILD_CACHE:-$HOME/.cache/monkey-bananas-build}"   # shared with the fork: same Godot templates

log() { echo "[build_web] $*"; }

if [ ! -f "$TPL_DIR/web_nothreads_release.zip" ]; then
  log "downloading the Godot ${VER} export templates (web only are kept)"
  mkdir -p "$CACHE/tpl" "$TPL_DIR"
  curl -sSfL -o "$CACHE/templates.tpz" "https://github.com/godotengine/godot/releases/download/${VER}-stable/Godot_v${VER}-stable_export_templates.tpz"
  unzip -o -q "$CACHE/templates.tpz" 'templates/web_*' 'templates/version.txt' -d "$CACHE/tpl"
  cp "$CACHE"/tpl/templates/web_* "$CACHE"/tpl/templates/version.txt "$TPL_DIR/"
  rm -f "$CACHE/templates.tpz"
fi

# The content lint gates the build: the red lines (October 7, the hostages, fallen soldiers,
# the military; Bar: no mention of October 7 anywhere) over content.json, the UI strings and the
# About page, plus sources and the poll-number rule. No override: a red line never ships.
if ! node "$HERE/../design/sim/content-lint.mjs" > "$HERE/../build/content-lint.log" 2>&1; then
  sed -n '/^ERROR/,$p' "$HERE/../build/content-lint.log" | sed 's/^/[build_web] /'
  log "content lint failed (build/content-lint.log)."
  exit 1
fi

# The pixel-width lint gates the build (engine/feasibility.md O-U3): any string that overflows its
# box, or a glyph the font lacks, fails it. OD_LINT=warn reports and continues (interim builds only,
# while a string fix is pending with its owner).
if ! "$HERE/lint_text.sh" > "$HERE/../build/lint-text.log" 2>&1; then
  grep -E "FAIL|lint_text\]" "$HERE/../build/lint-text.log" | sed 's/^/[build_web] /'
  if [ "${OD_LINT:-strict}" = "warn" ]; then
    log "text lint FAILED; continuing because OD_LINT=warn"
  else
    log "text lint failed (build/lint-text.log). Fix the strings, or OD_LINT=warn for an interim build."
    exit 1
  fi
fi

rm -rf "$OUT"
mkdir -p "$OUT"
"$HERE/godot.sh" --headless --path "$GAME" --import >/dev/null 2>&1 || true
log "exporting to $OUT"
"$HERE/godot.sh" --headless --path "$GAME" --export-release "Web" "$OUT/index.html" 2>&1 | tee "$OUT/../web-export.log" | grep -E "ERROR|error" || true
[ -f "$OUT/index.html" ] && [ -f "$OUT/index.wasm" ] || { log "export failed, see build/web-export.log"; exit 1; }

# Home Screen app files (the engine's PWA export is off: no service worker) and the build
# stamp the settings screen shows. Icons come from tools/icon.sh once it has run.
# (privacy.html / support.html are the fork's Monkey Bananas store pages: not shipped. The
# game's About page (O8) is its own HTML surface, a later wave.)
cp "$HERE/web/index.manifest.json" "$OUT/"
for n in 144 180 512; do
  [ -f "$GAME/assets/icon/pwa_$n.png" ] && cp "$GAME/assets/icon/pwa_$n.png" "$OUT/index.${n}x${n}.png"
done
STAMP="$(git -C "$HERE" rev-parse --short HEAD 2>/dev/null || echo dev)"
git -C "$HERE" diff --quiet HEAD -- "$GAME" 2>/dev/null || STAMP="$STAMP+"
sed_inplace "s|__MB_BUILD__|$STAMP|" "$OUT/index.html"
# Link previews need absolute og:url / og:image URLs (WhatsApp, the main share channel, skips a
# relative one): OD_SITE_URL (with a trailing slash) is the deployed origin. It defaults to the
# game's one constant, ShareKit.SITE_URL (game/scripts/ui/share_kit.gd), which is also the link on
# the share cards and in the share texts (the shell hands the same value to the engine as
# window.odSiteUrl). OD_SITE_URL= (empty) keeps the tags relative for a throwaway preview host.
SITE_DEFAULT="$(sed -n 's/^const SITE_URL := "\(.*\)"$/\1/p' "$GAME/scripts/ui/share_kit.gd")"
SITE="${OD_SITE_URL-$SITE_DEFAULT}"
case "$SITE" in ""|*/) ;; *) SITE="$SITE/" ;; esac
sed_inplace "s|__OD_SITE_URL__|${SITE}|g" "$OUT/index.html"
log "site url: ${SITE:-(relative)}"
# the HTML surfaces (N1, N0, hand-off bar, About) take their Hebrew from ux/ui-strings.json
python3 "$HERE/lib/render_shell.py" "$OUT/index.html"
cp "$GAME/assets/sprites/wordmark.png" "$OUT/wordmark.png"
[ -f "$GAME/web/og.jpg" ] && cp "$GAME/web/og.jpg" "$OUT/og.jpg"   # the 2D Artist's 1200x630 link preview (art/od-sevev/out/key/og-1200x630.jpg, 120 KB)
grep -q "mbBuild = '$STAMP'" "$OUT/index.html" || { log "build stamp missing from index.html"; exit 1; }
log "build stamp: $STAMP"
log "done:"
ls -la "$OUT" | awk 'NR>1 {printf "  %10s  %s\n", $5, $9}'
