# How to run: "עוד סבב" (fork of Monkey Bananas v2)

Godot **4.7.2** project in `game/`. Always run Godot through `tools/godot.sh`: it finds a 4.7.x
binary even when an older `godot` is first on `PATH`.

## Commands

| Command | What it does |
|---|---|
| `tools/test.sh` | Headless unit tests (`game/tests/unit/`): economy, save v2, formatter, meta, story, audio |
| `tools/balance.sh` | Pacing bench: plays whole one-hour sessions through the real economy and checks the gates (about 2 minutes) |
| `tools/sync_data.sh` | Copies `design/content.json` and `ux/ui-strings.json` into `game/data/` (the tests fail when they drift). The audio needs no copy; the Monkey Bananas audio specs are in `audio/legacy/` |
| `node art/tools/export-godot-data.mjs` | Rebuilds `game/data/art.json` from `art/sprites.ts`, `pipeline/` and `art/v2-sprites.json` |
| `tools/audio.sh` | Regenerates every עוד סבב sound into `game/assets/audio/od/` with `tools/gen_od_sevev.gd` (`--check` proves two runs are byte-identical). The fork's `gen_audio.gd`/`gen_music.gd` are retired (`MB_LEGACY_AUDIO=1` still runs them) |
| `tools/icon.sh` | Regenerates the app icons from the Big Banana sprite |
| `tools/build_web.sh` | Web export into `build/web/` |
| `tools/deploy_web.sh` | Deploys `build/web/` to Vercel (`MB_VERCEL_PROJECT=monkey-bananas` for the live URL; the default `monkey-bananas-v2` is the test copy) |
| `tools/webtest.sh [url]` | Headless Chromium check: canvas fills the window, no page errors, sound after the first tap (needs Playwright) |
| `tools/build_android.sh` | Android APK into `build/` (signed with a throwaway sideload key; set `MB_BUILD_CACHE` to reuse an SDK cache) |
| `tools/release_ios.sh --sim` | iOS Simulator build (no Apple account needed); `--archive` / `--upload` need Bar's team ID |
| `tools/export_ios.sh` | Xcode project for a Personal Team device build |

Git pushes do **not** deploy (`vercel.json` turns git deployments off); the web build ships
only through `tools/deploy_web.sh`.

## Controls

| Input | Action |
|---|---|
| Tap the Big Banana | Harvest (capped at 16 registered taps a second across all fingers and keys) |
| Tap the Golden Banana | Catch: Lucky Bunch, Banana Frenzy, or Tap Frenzy |
| Tap a shop row | Buy (commits on release; drag to scroll; hold a producer row to repeat-buy) |
| Tap the Thumbs line, or the thumb button on the stage | Thumb Perks |
| Tap the book button on the stage | Troop Book: trophies, stats, story |
| `Space` / `E` / `T` / `P` / `O` / `B` / `1`-`9` / `Esc` | Tap / Evolution / switch tab / Perks / Troop Book / buy mode / buy tier / Settings |
| Android back, `Esc` | Close the top overlay |

## Dev URL params (web build, all ignored without `?dev=1`)

`&speed=N` multiplies game time, `&grant=N` adds bananas at boot, `&evo=N` sets the evolution
count (to look at the eras). Example: `/?dev=1&grant=2000000`. `&susp=N` reveals the suspicion
thermometer at N% (100 = a court summons on the first step), `&aide=N` puts N ₪ of suitcase money
on an aide (the "אני לא מכיר אותו" button): `/?dev=1&grant=50000&susp=100&aide=300`.
`&flash=N` opens Dubi's news flash for round N on the first tap. `?frame=1` / `?frame=0` (no `dev`
needed) force the desktop phone frame on or off (the shell's `odFit`: a window ≥ 600 CSS with a
mouse gets a centred 390-CSS canvas; `window.odFrame`). `node tools/web/views_web.mjs <url> <dir>
[WxH@DPR,...]` screenshots the flash, the cottage cup and the frame in Chromium.
`node tools/web/round_web.mjs <url> <dir> [WxH@DPR] [speed] [budget s]` plays a whole first round to
the election through the real UI at `?dev=1&speed=N` (touches only: the Magician, the source cards,
every chat pill including those scrolled above the fold, "להעיד", the "עוד סבב!" CTA, O3's "לפזר את
הכנסת") and screenshots the CTA, O3, the transition and the flash. `node tools/web/modals_web.mjs
<url> <dir>` screenshots the summons card and chip, the court card over T3, a partner card, O10,
About and O1 (a cold load 3 h later). Both read `window.odDev` (dev only, `ui/dev_probe.gd`: the
targets in viewport logical px) and `window.odModal` (the open sheet card's buttons).
`&chat=N` opens the coalition group at boot with N join lines after the first demand and an open
Amsalem–Smotrich brawl (the brawl cue under Row B, the "{n} ממתינים ↑" chip in T3). `node
tools/web/share_web.mjs <url> <dir> [WxH@DPR]` opens O4 and O5 from T4, saves the exported PNGs
("לשמור תמונה" downloads them), checks "לשתף" (headless Chromium has no `navigator.share`: download
+ clipboard) and "לשתף בוואטסאפ" (a desktop opens `wa.me/?text=` in a new tab; the text must decode
back), the brawl cue, the pending chip, About's WhatsApp invite and the absolute OG tags.

**Sharing (O4 / O5, the invite).** `ui/share_kit.gd` holds the model and the one site URL
(`ShareKit.SITE_URL`); `ui/views/view_share.gd` renders the card once when the sheet opens (the kit
piece + engine text at 5 card px per art px in a 1080×1350 SubViewport, read back to a PNG) and
shows that image as the preview. The shell's `window.odShare` does the platform work (file share →
text share → download + clipboard; wa.me in a new tab on a desktop, in place on a phone) and answers
through `window.odShareDone`; `window.odShareLog` records every result.

## Source map

```
game/
  project.godot            portrait 720x1280, stretch canvas_items + aspect expand (the boot default;
                           main.gd switches to integer art scaling, see below), Mobile renderer
  data/                    copies of the specs (synced) + art.json (exported)
  scripts/sim/             pure rules, no nodes: content, game_state, economy, meta, story,
                           save_store, fmt, tap_limiter, pacing_sim
  scripts/art/art.gd       Art autoload: bakes sprites, the pixel font and FX from art.json
  scripts/autoload/audio.gd Audio autoload: plays assets/audio/od/ from od_manifest.json (audio/od/cue-spec.md)
  scripts/audio/od_audio.gd OdAudio: the pure audio rules (file lookup, tap walk, mute cycle, babble plan, slider law)
  scripts/ui/              the views (top bar, stage, shop, overlays, ticker, diorama, ...)
  scripts/main.gd          the controller: fixed-step economy, input router, layout, saves
  tests/unit, tests/bench  headless tests and the pacing bench
tools/                     build, test, deploy and generator scripts
decisions/                 the v2 ADRs
```

## od-sevev engine notes (game-developer, wave 1)

| Command / switch | What it does |
|---|---|
| `tools/lint_text.sh` | Pixel-width lint: every `ux/ui-strings.json` key (plus producer/upgrade names and the story beats) measured with the shipped font against its `ux/string-budgets.json` box. `tools/build_web.sh` runs it first and **fails the build** on an overflow or a missing glyph |
| `OD_LINT=warn tools/build_web.sh` | Interim build while a string fix is pending with its owner: the lint reports and the export continues |
| `OD_SITE_URL=https://…/ tools/build_web.sh` | The deployed origin: absolute `og:url` / `og:image` / `twitter:image` (WhatsApp's preview needs them), the link on the share cards and texts (`window.odSiteUrl`). Defaults to `ShareKit.SITE_URL` (`https://od-sevev.vercel.app/`); `OD_SITE_URL=` (empty) keeps the tags relative for a throwaway host |
| `OD_VERCEL_PROJECT=<name> tools/deploy_web.sh` | Deploy target. **No default**: the deploy is Bar's gated call (studio I5) |
| `python3 tools/gen_sevev_glyphs.py` | Regenerates the engine's stand-in Hebrew font (`game/scripts/ui/sevev_glyphs.gd`) from the creative pack's `hebfont.py`. Only used when `game/assets/fonts/sevev9.fnt` is absent |
| `godot --path game -- --content=res://tests/fixtures/content.fork.json` | Desktop dev run on another content file (the web build never reads it) |
| `tools/icon.sh` | Retired: the icons come from the Technical Artist's pipeline |

**Text.** Every visible string goes through `PxText`, which shapes it with TextServer
(TextServerAdvanced, ICU bidi, LRI/PDI honoured) and draws the Technical Artist's `sevev9.fnt` at
size 9 scaled by an integer (the pixel grid holds). Numbers shape too, so their digits match the
Hebrew font (`PxText.BITMAP_ROUTE` brings back the fork's 5x7 digits). `Strings.s` never adds an
isolate inside one the string already has; `Strings.plural` / `Strings.gendered` pick the
`_ONE/_TWO/_OTHER/_ZERO` and `_M/_F` siblings.

**Large text (rtl-map §0.2).** `PxText` owns the step-down: under large text a body text (×4) draws
×5 only when its filled string fits its box there (`wrap_width` + `max_lines_large`, or `fit_width`
for a one-line label that never wraps), else ×4, where `tools/lint_text.sh` proves it fits. A view
gives each text its `string-budgets.json` box; rows that stack text measure `line_count()` ×
`eff_px()`. Toggling large text re-runs the controller's relayout and rebuilds an open settings sheet.

**Back button (rtl-map §7.1, `scripts/core/layer_history.gd`).** Web: one `history.pushState` per
open layer (overlays, the partner card, T3/T4, the expanded court card); `popstate` closes the top
layer as ✕/Esc does, About keeps its own entry, and with nothing open back leaves the page.
`window.odLayers` is the open-layer count (web debug). Android back and Esc share `back_layer()`.

**RTL.** `L.RTL` (from `Bidi.UI_RTL`) mirrors the fork's layout tables once at startup: the shop
icon and name on the right, the price pill on the left, tabs reversed, the ticker tag on the right
with a left-to-right crawl, bars filling from the right, the stat window and gear swapped. The full
`ux/rtl-map.md` HUD (Row A/B, bottom tab bar, the flex rule) is the next engine wave.

**Art.** `SpriteStrip` plays the cast strips from `game/assets/sprites/sprites.json`; the Magician
(`bibi`) stands in for the Big Banana, the Suitcase sprite for the Golden Banana, Dubi's stand-in for
the narrator, and each era draws its `stage_<era>` art aligned on `magicianFeet`. Missing art never
crashes: `Art.sprite_or()` draws a neutral "?" card (and the stage simply leaves an artless
producer's slots empty).

**Documented assumptions (wave 1).**
- The save file schema stays the fork's version 2; only the export prefix changed (`HK1:`). A version-1
  file is kept aside as corrupt (there are no Monkey Bananas v1 saves to migrate in this game).
- The fork's unit tests pin the fork content (`game/tests/fixtures/content.fork.json`) so they keep
  testing the engine while `design/content.json` is rewritten; the Hebrew content boots in the web
  build and is checked by the sim's own tests and `tools/balance.sh`.
- The Suitcase keeps the fork's drift for now (the art is swapped); its band flight from
  `ux/rtl-map.md` §4.1 is the next wave.

## Integer art scaling (game-developer engine, 2026-09-29)

Bar's decision: one art px (the 180-wide art grid, 4 logical px) is always a whole number **k** of
device px, `fit = min(floor(W / 180), floor(H / 267))` with W × H the backing store (CSS × DPR), and
**k = the largest multiple of 2 or 3 ≤ fit** (`Display.crisp_k`; fit 5 → 4, 7 → 6, 11 → 10; 1 stays
1), so every rendered figure has a density (d 2 or d 3) drawing whole device px: "sharp characters on
every phone" (Bar, 2026-09-29). The remainder is letterboxed into the aspect-`expand` area like any
other leftover. The stage and the UI stay 1× chunky (k device px per art px).

**Where it lives: the host viewport's own stretch transform** (`main.gd _apply_display`,
`scripts/core/display.gd`). On the window (the web canvas, desktop, a phone) the stretch mode is
switched to `disabled` with `content_scale_factor = k/4`, so the logical viewport is W/f × H/f and
the extra width and height go to the aspect-`expand` area (the centred 720 column, the extended
backdrops, the stage's `padTop` / `padBottom`). A scene hosted in a SubViewport (`--device` shots,
the scaled-input tests) gets `size_2d_override = W/f × H/f` instead. Why not the alternatives:
- Godot's `canvas_items` + `scale_mode = integer` floors the scale against the 720 base, so it can
  only give k = 4, 8, … (a 1170-px iPhone would get k 4 and 450 px of padding, not k 6).
- A SubViewport + TextureRect costs a full-screen render target and copy per frame on phones and
  needs the input re-mapped by hand. The window transform is free, and Godot maps every input event
  back to logical px through it, so hit tests never see device px
  (`tests/unit/test_display.gd` pushes device-px touches through a scaled viewport at DPR 2 and 3).

| Phone (CSS, DPR) | Backing store | fit → **k** (was) | Stage/UI | Rendered cast + sources at ×4 | Body text (×4): Sevev 9 @2 |
|---|---|---|---|---|---|
| 390×844, 393×852, 412×915, 430×932 @2 | 780-860 wide | 4 → **4** (4) | 4 dp | **d 2 at 2 dp** | **@2 at 2 dp** |
| 390×844 @3, 393×852 @3, 360×800 @3 | 1080-1179 | 6 → **6** (6) | 6 dp | **d 3 at 2 dp** | **@2 at 3 dp** |
| 412×915 @2.625 (Pixel), 412 @3 | 1081, 1236 | 6 → **6** (6) | 6 dp | **d 3 at 2 dp** | **@2 at 3 dp** |
| 430×932 @3, 428×926 @3 (Pro Max / Plus) | 1284-1290 | 7 → **6** (7, "aa") | 6 dp | **d 3 at 2 dp** (was 2.33 dp "aa") | **@2 at 3 dp** (was Sevev 9 at 7) |
| 412×915 @3.5 (QHD Android) | 1442 | 8 → **8** (8) | 8 dp | **d 2 at 4 dp** | **@2 at 4 dp** |
| a 900×1600 surface (tablet split, 5-fit) | 900 | 5 → **4** (5, "aa") | 4 dp | **d 2 at 2 dp** | **@2 at 2 dp** |
| 1440×900 desktop @1 (the phone frame, 390×844) | 390×844 | 2 → **2** (2) | 2 dp | **d 2 at 1 dp** | **@2 at 1 dp** |
| 1440×900 desktop @2 (the phone frame) | 780×1688 | 4 → **4** (4) | 4 dp | **d 2 at 2 dp** | **@2 at 2 dp** |
| 960×600 desktop @1.5 (the phone frame) | 585×828 | 3 → **3** (3) | 3 dp | **d 3 at 1 dp** | Sevev 9 at 3 dp |

Every rendered character and money source ships a d 2 alternate beside its main d 3 (CONTRACT §3),
and k is always a multiple of 2 or 3 now, so **every figure on the stage is whole-block at every
size** ("aa" is left only for a view scale nothing divides, e.g. a card forced to ×3 at k 6). A view
that draws a figure at its own art scale picks the variant for ITS device px per art px
(`SpriteStrip.set_art_px`): the partner card and Dubi's flash pick ×4/×3/×2 per k
(`FlashCard.pick_art_scale`: ×4 at k 4 = the d 2 at 2 dp, ×4 at k 6 = the d 3 at 2 dp); the
ultimatum cameo's ×3/×2 is lowered to the largest scale whole on one of its densities
(`SpriteStrip.crisp_art_px`: ×3 at k 6 is 4.5 dp, so ×8/3 = 4 dp, the d 2 at 2 dp).

**Sevev 9 @2, the reading cut (CONTRACT §6.1).** `PxText.reading = true` marks body copy: the chat
bubbles, system lines and chat toasts' line, card descriptions (line 2), the ticker crawl, settings
labels and captions, modal and court-card bodies (`Overlay.body_text`, `SheetCard.para`), toasts
and Dubi's bubble, and the flash's lines. Such a text shapes with `sevev9@2.fnt` at 18 and draws at
`eff_px() / 2` **only where one Sevev 9 px is an even number of device px** (k 2, 4, 6, 8 at ×4;
large text ×5 at k 6 and 8), else Sevev 9 (k 3, 9, and ×5 at k 4). Every @2 metric is exactly 2×
Sevev 9's, so the swap never moves layout (`tests/unit/test_sharp.gd` lays out the whole UI deck
both ways at k 4 and 6 in five boxes and compares widths, line breaks and ellipsis). Display text
keeps Sevev 9: the counter and rate line, prices and pay pills, titles (outline cut), tab labels,
the ticker tag, chips, timers, badges, buttons, names, and anything dimmed or over art. Web dev:
`?dev=1&sharp=0` draws every reading text on Sevev 9 (the before/after).

- **Density comes from the data:** `SpriteStrip.density_of()` reads `density` on the char (or its
  picked `densities` alternate), then the manifest top level, else 1; `scale_of()` = artScale /
  density. The diorama's money sources use the same (`Diorama._scale_of`, `_scale_sprite`). A d = 1
  and a d = 3 manifest both work; so does a mix.
- **Filter:** nearest whenever k/4 · scale is a whole number of device px; otherwise
  `SpriteStrip.fractional_filter` ("aa" = even texels with a one-device-px blended seam; "nearest";
  "linear"). A `densities` alternate that divides k wins over the main render.
- **Fallback:** a surface under 180×267 device px (the 64×64 headless test window) cannot hold the
  layout at any integer k, so it keeps the fork's `canvas_items` + `expand` stretch at 720×1280
  (`Display.integer` false, everything nearest, no snapping).
- **Before/after on the web:** `?dev=1&forkscale=1` shows the fork's fractional stretch on the same
  build. `window.odDisplay` = `{k, f, integer, logical, ox, stageY, lowerY, hat}` (logical px).
- **Runtime-origin check:** `node tools/web/res_web.mjs <url> build/shots [before|after]
  [WxH@DPR,...]` serves nothing itself (run `python3 -m http.server --directory build/web`):
  headless Chromium at each size passes the disclaimer, taps the Magician, checks O-A3 on the
  Audio clock (`window.odCueLogMs`), buys card 1 by touch and saves title/main/bought screenshots.
  `python3 tools/lib/pixel_runs.py <png>` reports the art-px widths.
- **Headless Chromium note:** SwiftShader draws a 1170×2532 frame in 150-450 ms. Godot then
  advances game time by at most 8/60 s a frame, so wall-clock timings stretch there; read the
  Audio clock, not the wall.

## od-sevev audio notes (game-developer audio, 2026-09-29)

| What | Where |
|---|---|
| The spec (behaviour) | `audio/od/cue-spec.md` (Audio Director) |
| Every runtime number | `game/assets/audio/od/od_manifest.json` (written by `tools/gen_od_sevev.gd`); the runtime hard-codes no pitch, scale or level |
| Buses | `game/default_bus_layout.tres`: Master = HardLimiter −1 dB only; Music → Outside (LPF 800 Hz, pan −0.3); SFX-Critical → Suitcase (panner); SFX-Frequent; UI; Voice; all 0 dB |
| Web debug | `window.odCueLog` (the last 24 files played) and `window.odCueLogMs` (when each played, Audio clock ms), `window.odAudioKey`, `window.mbMusicTrack` (`<era>:L0+L1+L2`), `window.mbMusicPeak` |

**Behaviour you will notice.**
- Nothing sounds until the first Magician tap. That tap plays the motif, and the era's music starts at bar 1 where the motif resolves (about 2.3 s later in D).
- Dubi never speaks over the motif (O-A3): tap 1's "אין כלום!" starts at the motif's `musicalSeconds` (2.33 s in D); its toast shows at f0. A headline that arrives meanwhile does not cut that waiting line.
- Taps walk the era's scale, one step per tap, and the walk resets after 400 ms.
- The lead (L2) follows your tapping at the bar lines. L1 comes in with the first money source.

**Documented assumptions.**
- **The Outside drum line is a separate player on the Outside bus,** started on the same frame and position as the Balfour stems.
- **General trophies play `milestone`** (the brass 1-2-♭3, Audio Director v1.2); the album trophy keeps `trophy`.
- **Coalition collapse** fades the music out over one bar, then silence, with no stinger (cue-spec §2.6); the next tap restarts it at bar 1.
- **Pink Front tap-to-beat** counts a hit within ±120 ms of a judge beat, measured after the output latency.
- **The fork's renders** are kept in `game/assets/audio/legacy/`. Its `.gdignore` keeps them out of every import and export.
