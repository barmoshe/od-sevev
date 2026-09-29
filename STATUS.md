# STATUS

A live log. Each agent appends one line per finished step: `date · agent · what · files`.
Cross-slice requests go under **Requests** with the owner named.

## Log
- 2026-09-28 · orchestrator · forked monkey-bananas v2.1.0 (git archive) into here; baseline `tools/test.sh` 55/55 green
- 2026-09-28 · game-developer (sim) · published the politics data contract (below) + placeholder instance `game/tests/fixtures/politics.json`; claiming `game/scripts/sim/**` (see Requests)
- 2026-09-28 · game-developer (engine) · rebrand (project name "עוד סבב", `HK1:` export prefix, no v1 migration, Hebrew web head + OG tags, bundle ids `xyz.base67.odsevev`, `OD_VERCEL_PROJECT` with no default) + ids de-hardcoded (contract below) · `game/project.godot`, `game/export_presets.cfg`, `game/web/shell.html`, `tools/web/index.manifest.json`, `tools/deploy_web.sh`, `tools/build_web.sh`, `game/scripts/{main,ui/layout,ui/diorama,core/tune,core/strings,art/art,autoload/audio}.gd`; sim/ minimal: `content.gd` (outcome types), `economy.gd` (`apply_golden`), `save_store.gd`
- 2026-09-28 · game-developer (engine) · the fork's unit tests now pin the fork content (`game/tests/fixtures/content.fork.json` via `game/tests/fixture.gd`), so they keep testing the engine while `design/content.json` turns Hebrew · `game/tests/unit/test_{economy,meta,story,save,pacing,fmt}.gd`
- 2026-09-28 · ux-designer · Hebrew UI strings (471 keys: every fork key kept + first-minute §8 + court, pardon desk, transfer, brawl, receipt/result cards, OG, disclaimer, About, settings, return card, blackout, tabs; 0 lint errors against the real Sevev 5x9 metrics), per-key pixel budgets, the RTL view map and the FTUE trigger spec on the fork's state · `ux/ui-strings.json`, `ux/string-budgets.json`, `ux/tools/gen_strings.py`, `ux/rtl-map.md`, `ux/ftue.md`, `ux/README.md` (the inherited Monkey Bananas ux docs are marked superseded)
- 2026-09-28 · animator · od-sevev motion wave 1. Magician state graph (idle / tap / crit with tap buffering and coin batching, the court-day zip exit and hat-on-stage, the summons flinch, the election trick on the fanfare's roll end); cast graphs (partner avatar echoes, partner body on the card and proposed cameo, Sara offended, Bennett's ping-pong flip, opposition figures); UI motion-spec (chat, events, court, rewards, ticker, a reduced-motion variant on every entry); provisional hit-frame-data. The legacy Monkey Bananas motion files moved to `motion/legacy/` · `motion/README.md`, `motion/state-graph-magician.md`, `motion/state-graph-cast.md`, `motion/motion-spec.yaml`, `motion/event-markers.md`, `motion/legacy/*`
- 2026-09-28 · technical-artist · art import path + Sevev 9 font + one-command pipeline:
  - **Sprites:** 19 cast strips (reproduced pixel-exact from the refs), avatars, props, 4 stages, the 2D Artist's 89 UI-kit pieces and the app icons, all imported with lossless, no-mip, nearest import params; manifest `sprites.json`, loader contract `game/assets/sprites/CONTRACT.md`.
  - **Font:** Sevev 9 as a real Godot `FontFile` (BMFont), a plain cut and an outline cut: 108 glyphs + 33 aliases + 17 zero-width format characters (bidi controls, VS15/16), covering UX §3.5 and every char in `ux/ui-strings.json` + `design/content.json`. Proofed through Godot's TextServer.
  - **Budget:** +382 KB of web .pck.
  - **Rerun:** `python3 pipeline/od-sevev/build.py [--no-render] [--godot]`.
  - **Tests:** `tools/test.sh` 97/97 at import time. The 11 failures now in `test_audio`, `test_input`, `test_coalition` and `test_politics_save` come from the concurrent content, sim and audio edits: an A/B with and without my `art.json` change gives the same FAIL set.
  - **FX:** `ballotConfetti`, `dustPuff` and `inkSpecks` added to `pipeline/fx-data.json` (→ `art.json`), plus their sprites and `prop_hat_glow`.
  - **Files:** `pipeline/od-sevev/**`, `pipeline/fx-data.json`, `game/data/art.json`, `game/assets/sprites/**`, `game/assets/fonts/**`, `game/assets/icon/*.png`
- 2026-09-28 · game-developer (engine) · Hebrew text route: every PxText string now shapes through TextServer (bidi, LRI/PDI) with the TA's `sevev9.fnt` (stand-in built from `hebfont.py` until it existed); RTL mirroring of the fork layout (shop icon/name right, pill left, tabs reversed, ticker tag right + left→right crawl, bars fill from the right, stat window/gear swapped); `tools/lint_text.sh` pixel-width lint on `ux/string-budgets.json` (wired into `tools/build_web.sh`); `test_bidi.gd` (8 tests) · `game/scripts/{core/bidi,ui/he_font,ui/sevev_glyphs,ui/px_text,ui/layout,ui/shop,ui/top_bar,ui/ticker,ui/ftue,ui/buff_views,core/strings,ui/ui}.gd`, `game/tests/lint/*`, `tools/{lint_text.sh,gen_sevev_glyphs.py}`
- 2026-09-28 · game-developer (engine) · character hook: `SpriteStrip` player on the TA manifest; the Magician (bibi idle/tap/crit, entered at f1; `coins`/`rabbit` events spawn prop coins and the rabbit at `hatMouth`) replaces the Big Banana; the Suitcase sprite replaces the Golden Banana; Dubi's stand-in avatar replaces CHIP on the story card; era stage art from `sprites.json stages` placed on `magicianFeet` · `game/scripts/ui/{sprite_strip,prop_fx,big_banana,golden,diorama,overlays}.gd`, `game/scripts/main.gd`
- 2026-09-28 · ux-designer · rev 2 (reconcile): accepted the 2D Artist's F1, F2, F4 (body text now x4, large x5; all 476 strings re-linted, 0 errors), F5; F3 accepted with a counter (legal line + URL stay on both share cards); accepted the Animator's crawl objection (80 logical/s, one art px per 3 frames) and answered the 5 placement questions · `ux/rtl-map.md` (rewritten, §12 D11-D19), `ux/ftue.md`, `ux/ui-strings.json`, `ux/string-budgets.json`, `ux/tools/gen_strings.py`
- 2026-09-28 · ux-designer · reviewed the 23:48 web build at 390×844 (fresh origin). Works: Hebrew shaping and number isolation ("₪ +1", "+4!"), scripted rabbit on tap 7, 15 ₪ on tap 12, gear mirrored left, ticker tag right with a left→right crawl, card internals mirrored. 7 objections to game-developer (engine) under Requests.
- 2026-09-28 · audio-director · the od-sevev audio. The id list and the engine requests are under Requests.
  - **Composed:** four original era themes (balfour D hijaz 116 hora, knesset E hijaz 132 maqsum, courthouse G hijaz 88 half-time swing, washington F Mixolydian 144 stride; 32 bars each, three layers, the "עוד סבב" motif at bar 32), the Balfour Outside drum line, 6 stingers (the fanfare in 5 lengths × 4 keys) and 21 SFX cues (279 files).
  - **Checks:** `audio.sh --check` is deterministic (967 files). The payload is **11.02 MB** (≤ 11.3). The full mix is −16.1 to −16.3 LUFS in three eras, and the court hush is −17.0. Every loop seam is 0.0000. The tap walk is within 0.8 cents. The longest steady tone is 0.88 s (red line 1.0).
  - **Tools:** the new generator `tools/gen_od_sevev.gd` reuses `lib_dsp.gd` unchanged. `tools/audio.sh` got 3 guarded lines (run it, snapshot `od/`, the size line).
  - **Files:** `audio/od/{music.json,cues.json,cue-spec.md}`, `audio/tools/{compose_od.py,measure_od.py}`, `tools/gen_od_sevev.gd`, `tools/audio.sh`, `game/assets/audio/od/**`.
- 2026-09-28 · animator · wave 2: Dubi state graph + strip spec (18-tall 35 frames, 96-tall mic 22 frames); the 8 money sources' 2-frame idles (per source), the taxpayer `lob` set piece and the transform-only walk-on; the Magician's sweat (a prop on a `temple` landmark; no new Magician strips); one render list for the orchestrator/TA; event markers reconciled against `audio/od/` (confirmed, retimed: the Suitcase burst +130, the ultimatum zero 320/510, the whistle 0/160/320, the election curtain now ends on `fanfareEnd` in every key); hatMouth now read from `sprites.json` (O-M1 resolved) · `motion/state-graph-dubi.md`, `motion/diorama-motion.md`, `motion/render-requests.md`, `motion/state-graph-magician.md` §8, `motion/motion-spec.yaml`, `motion/event-markers.md`, `motion/README.md`
- 2026-09-29 · game-designer · Hebrew content on the binding politics contract v1 (`Politics.validate()` 0 errors, `node design/sim/content-lint.mjs` 0 errors): 8 sources (shady 4-7), 15 spins (5 held off the shelf until their effect lands), 15 partners (70 bubbles), 13 events (7 opposition), court, calendar, suitcase, story B1-B5 + encore, 165 ticker lines (29 milestones, 105 live ambient, 31 politics-conditional), 40 trophies ("תיק הישגים"), 12 perks ("כלי הקסם"), Dubi. Every string presented as real carries `src` (51 facts). TA glyph objection resolved (10 emoji reworded, 12 approved pictograms kept, no `§` in drawn strings). Pacing checked against pitch §5 / UX §2 (below) · `design/content.json`, `design/facts.json`, `design/redlines.json`, `design/sim/content-lint.mjs`, `design/sim/economy-sim.mjs` (replaces the banana sim), banners on the three inherited Monkey Bananas docs
  - **First five minutes** (greedy buyer, pays every demand at once, 1 / 1.5 / 3 taps/s): 15 ₪ on tap 12 · C1 at 0:52 / 0:43 / 0:31 (34/61 on payment) · cottage 1:10-1:41 · spins tab 1:26-2:01 · first shady source 2:34-3:16 · at 5:00 seats 51-53, suspicion 31-44% · **61 at 7:40 / 7:22 / 6:44** (pitch 7-9 min for a median player). Later rounds 3.5-6 min, one court day a round, all 8 sources by round 8, ×77 at round 8, S06 (750M) affordable from round 8.
  - **Deviations from the approved pitch/deck, with reasons:** base payout is the per-round **cube root** (√ reaches ×36,700 by round 12 and kills the suspicion corner); spins unlock at lifetime **1,500** (300 fired at 0:52, inside the C1 beat); the cottage (1,000) lands at ~1:30, before spins, not at 3:30; S06 no longer unlocks Washington (eras follow the election count; S06 is ×1.5 income); "חמש בפחות מארבע" is 5 rounds in a row under 4 min each (4 hours was reachable by accident); the encore drops `{n+1}` (the engine's `{n}` is a Mk counter); ten deck bubbles lost an emoji (TA objection) and Smotrich's 🙄 became "..." ("גם לא שלוש נקודות!!").
- 2026-09-29 · ux-designer · designer requests 1-4 done: `producerNames`/`producerPlurals`/`upgradeNames` emptied (content.json owns every name; the lint now checks the 23 content names against the ×4 card box: 0 overflows); `upgradeEffects` gains s15 "מוחק את חשד הסיגרים"; `CHAT_SYS_MUTED` `{who}` = the legal advisers; K3 spins unlock at 1,500 ₪ and never inside C1, Q1 now precedes K3 (`ux/ftue.md` §3, §3.1, §3.2, §7). `ux/tools/gen_strings.py`: 476 keys, 0 errors, 0 missing glyphs (the font now has E S C) · `ux/ui-strings.json`, `ux/string-budgets.json`, `ux/tools/gen_strings.py`, `ux/ftue.md`
- 2026-09-29 · game-developer (audio) · **the od audio cut-over**: all 9 of the Audio Director's engine requests are in `audio.gd`, plus the orchestrator's 5 decisions (fanfare on the confirm frame; paying a partner = `stamp`; a crit's f0 plays `tap`; `rabbitCrit` on the crit strip's rabbit frame; the first-tap squawk at f0, ducked under the motif).
  - **Runtime:** `Audio` now reads only `game/assets/audio/od/od_manifest.json`. The rules that are pure functions are in the new `OdAudio` (`game/scripts/audio/od_audio.gd`): file lookup, the strict tap walk, the 4-loop mute plan, fanfare tags, the Hebrew babble plan, the slider law, ping variants, the Pink Front sweep and the beat judge. **No pitch or scale data is in code.** The walk length is read from the rendered `tap` pitches, and Dubi's bank from the `dubiBlip` pitches sorted by the manifest's `degrees`, so the HaTikva re-render ships as data.
  - **Buses:** `game/default_bus_layout.tres` is the od topology: Master = HardLimiter −1 dB alone; Music (→ Outside: LPF 800 Hz 12 dB/oct + pan −0.3), SFX-Critical (→ Suitcase panner), SFX-Frequent, UI and Voice, all at 0 dB. Slider: `linear_to_db(slider / 1.0)`, so the default is 0 dB.
  - **Retired:** `gen_audio.gd` / `gen_music.gd` are off `tools/audio.sh` (files kept; `MB_LEGACY_AUDIO=1` still runs them). The fork's 26 MB of renders moved to `game/assets/audio/legacy/` (`.gdignore`: never imported or exported). The web `index.pck` is now **13.1 MB**, with no fork audio in it.
  - **Tests:** `test_audio.gd` rewritten for od: 21 tests (manifest files, bus topology, slider law, the gate, motif → bar 1, walk and wrap, crit + rabbit, layers on bar lines, the mute cycle, the era crossfade, court day, the fanfare and its markers, ducks, pings + Dubi, babble plans, headline ration, variant rules, the Pink Front flag, collapse, pause/toggle). `tools/test.sh`: **134 passed, 0 failed**, no script errors.
  - **Web check** (`OD_LINT=warn tools/build_web.sh`, served on :8747, 390×844): before any tap, `odCueLog` is empty and the music is stopped. The first Magician tap played `stinger_motif_D.res` only. The next taps played `tap_D_s0_d25 … s7_d12` then `s0` again (a pause reset the walk to `s0`). The music came in after the motif as `balfour:L0+L1` (L1 from the save's sources), and steady tapping added L2. The Music bus peaked at −10.7 dB. The strict build still stops on 4 string overflows (BUYMODE_10, ROW_OWNED_BPS, F_UPGRADE_FLAVOR, STORY_TITLE), not audio.
  - **Documented choices:**
    - **The Outside loop has its own player on the Outside bus,** started on the same frame and position as the Balfour stems. An `AudioStreamSynchronized` has one bus, so the cue-spec's "same sync stream" can't also be on the LPF sub-bus.
    - **The music starts at bar 1 where the motif resolves.** Before the first tap `start_music()` is a no-op.
    - **General trophies (`achievement`) are silent.** The od list has only the album `trophy`.
    - **Tap-to-beat counts a hit within ±120 ms,** measured after the output latency.
    - **The motif ducks Voice −6 dB.**
  - **Files:** `game/scripts/autoload/audio.gd` (rewritten), `game/scripts/audio/od_audio.gd` (new), `game/default_bus_layout.tres`, `game/tests/unit/test_audio.gd`, `tools/audio.sh`, `game/assets/audio/legacy/**` (moved), `HOW-TO-RUN.md` (audio notes)
- 2026-09-29 · technical-artist · wave 2, the Animator's render requests:
  - **Rendered** (`creative-pack art/showcase/src/{rig,build,cast}.py`): Dubi small (18 art px, 35 frames) and Dubi mic (96 px, 22 frames); the 5 money sources with refs (taxpayer, hitech, vat, cigars, qatari) at 40 tall, each with an icon and a silhouette; `avatar24_<char>` for every character; Bibi's per-frame `temple`.
  - **Rig and data:** new ops `edits`, `move_region`, `head_shift`, `hinge` and `rim` in `rig.py`; `DUBI` and `SOURCES` (data-driven) in `cast.py`. A source ref that lands later renders on the next run.
  - **Look unchanged:** a drift check against the pre-wave `out/` gives 0 changed files for every existing character, stage and prop. Only the old generic `dubi_idle` and `dubi_avatar` were replaced (by the spec's strips), and `dubi_react` was removed.
  - **Imported:** `sprites.json.sources` puts all 8 sources in one table, the 2D Artist's 3 hand-drawn ones included.
  - **Checks:** no edge waivers left (Bibi is 81 wide).
  - **Budget:** +490 KB of web .pck in total.
  - **Tests:** `tools/test.sh` 134/134.
  - **Font:** kept the orchestrator's 7-px ₪ and rebuilt both cuts. A Godot specimen shows no missing-glyph boxes.
  - **Files:** `pipeline/od-sevev/{sprites,build}.py`, `game/assets/sprites/**`, `game/assets/sprites/CONTRACT.md` §4, §4b, §7
- 2026-09-29 · game-developer (engine) · UX review R1-R7 applied: N1 disclaimer + N0 splash + hand-off bar + O8 About as HTML in `shell.html` (templated from `ui-strings.json` / `design/facts.json` by `tools/lib/render_shell.py`; `window.mbHandoffDone` starts the FTUE clocks; the sound choice becomes the settings); `ux/ftue.md` reveals (counter at tap 1, card 1 at tap 3, rate line at the first buy, tabs at 3 sources, spins at 300 ₪, Row B at the first paid demand, Suitcase from 2 sources with a forced first flight) and prompts P0/H1/P1/K3/B1/E1/R2; whole-card buy with an 18-px scroll threshold; rtl-map §1-§6 layout (flex rule, Row A/B, 84-px ticker with date chip + CTA, 120-px kit cards, bottom tab bar); pill = verb over price, gold when affordable, fill from the right; settings bottom sheet per §7.4; title per §8 (kit wordmark, scrim, countdown); text ×4 (large text ×5); Politics.tick wired (allowPing off) and the Animator's events emitted (courtSummons/courtStart/courtEnd, electionConfirm, trickCue, ceremonyEnd) · `game/web/shell.html`, `tools/lib/render_shell.py`, `game/scripts/{main,ui/{layout,top_bar,shop,ticker,title_view,golden,toasts,ftue,overlays,big_banana,px_text,px_button},art/art}.gd`; tests 134/134
- 2026-09-29 · game-designer · TA follow-up: `producers[].sprite/icon/silhouette` → `source_<id>`, `source_<id>_icon`, `source_<id>_icon_sil` (`washington` → `checkbook`); idle fallbacks for vat and cigars (bob) accepted, since the content never names a tag swing or smoke. `Politics.validate()` 0 errors, content lint 0 errors; `tools/sync_data.sh` run (it also re-copied `ux/ui-strings.json` and `audio/*.json`) · `design/content.json`, `game/data/content.json`
- 2026-09-29 · ux-designer · width lint on the shipping font: `ux/tools/gen_strings.py` now measures with `game/assets/fonts/sevev9.fnt` xadvance (as TextServer; ₪ = 8) and the engine's pxtext rule, against the formatters' real extremes ("8.88mm" costs/rates, "8.888mm" totals, "8,888,888" receipt `{xr}`). Fixes: price pill 46 art, pay pill 82 art, rejoin pill 512, buy-mode button 184, owned count moved to a badge on the plate corner (line 2 = x 220-568), 4 spin effect labels shortened; `BUYMODE_10` fits; `F_UPGRADE_FLAVOR` / `STORY_TITLE` / `EVO_MULT` reclassified from pxtext to label (placeholder-only and isolate strings need the RTL route). **`tools/lint_text.sh`: 499 checked, 0 failures**; gen_strings: 0 errors · `ux/tools/gen_strings.py`, `ux/ui-strings.json`, `ux/string-budgets.json`, `ux/rtl-map.md` (note: `tools/lint_text.sh` ran `tools/sync_data.sh`, so `game/data/` holds the current copies)
- 2026-09-29 · game-developer (engine) · queue after the UX list: TA `sources` wired (stage strips via `sourceAliases`, shop icons and silhouettes), small Dubi at the ticker anchor (beak on `Audio.dubi_blip`); Audio asks 1-4, 5, 6, 7 (headline, chatLeft, transfer, set_era_progress), 8, 9, 10; designer asks (a) engine-side ambient picker with `listPolitics` + the new keys (`core/ambient.gd`), (b) headline `stat` triggers, (d) `ticker.ambientFrom: C1`; strict web build green (lint 0 failures); tests 135/135 · `game/scripts/{main,core/ambient,ui/{ticker,shop,diorama,layout},art/art}.gd`, `game/tests/unit/test_bidi.gd`
- 2026-09-29 · technical-artist · swapped the 2D Artist's hand-drawn small Dubi (wave 4) in as `chars.dubi`, replacing the render-down placeholder; the placeholder note is gone and my wave-2 objection is resolved.
  - **How:** any UI-kit row with `char` + `anim` now replaces that character's anim. The build fails unless the hand-drawn set covers every anim with the same frame counts and events, one frame size and pivot, and no edge contact.
  - **Dubi now:** 20×23, anchor [10, 22], 6 anims, textures `dubi_small_<anim>.png`; the old `cast/dubi_*` strips are retired.
  - **Checks:** `build.py --no-render --godot` is clean (web .pck +489 KB in total, 0 missing-glyph boxes); `tools/test.sh` 135/135.
  - **Files:** `pipeline/od-sevev/{sprites,build}.py`, `game/assets/sprites/**`, `CONTRACT.md` §4
- 2026-09-29 · audio-director · **v1.2: HaTikva's minor** (Bar's client direction, via the orchestrator).
  - **The mode:** D, E and G are now natural minor, with the leading tone raised at cadences. Washington stays F Mixolydian, with the minor turn at its cadences.
  - **The motif:** the "עוד סבב" leitmotif is the anthem's rise, 1 | 2 ♭3 4 5, held on V. It resolves only on the next downbeat.
  - **The fanfare tags:** ♭6-5, ♭6-5, the octave leap 5-5′, ♭6′-5′.
  - **The A-sections:** each opens with the anthem contour (Washington only at its cadences).
  - **The guardrail is enforced:**
    - At most 10 consecutive anthem intervals (about 2 bars) per line, checked by `compose_od.py`. Balfour and the Courthouse sit at 10, the rest at ≤ 6.
    - Never on BLIP, never tiptoed. `courtIn` is now a legato rise.
    - Never a loss sting: collapse is silence.
  - **The tap walk and Dubi's bank** follow the minor: 64 and 40 files, same shape.
  - **Fixed:** `motif` and `trophy` had a silent 1.8 s lead-in bar (v1.1 too); they now sound at t=0.
  - **Unchanged:** every cue and stinger id, every file-name pattern and the manifest schema.
  - **Checks:**
    - `audio.sh --check` is deterministic (280 files).
    - The payload is **10.87 MB**.
    - The full mix is −16.3 / −16.2 / −16.1 LUFS, and the Courthouse −16.9 (the hush). True peak before the master is ≤ +0.3 dBTP.
    - Every seam is ≤ 0.0008. The walk is within 0.8 cents. The longest steady tone is 0.88 s.
    - `tools/test.sh`: 136/0. One run had a 2.5 s timing flake in `test_dubi_speaks…` under load; it passed on rerun.
  - **Mock-ups:** 12 WAVs in `output/tmp/od-sevev-audio/`.
  - **Files:** `audio/od/{music,cues}.json`, `audio/od/cue-spec.md` (the v1.2 banner and §6), `audio/od/legacy/*.v1.1-hijaz.json`, `audio/tools/{compose_od,measure_od}.py`, `tools/gen_od_sevev.gd` (Dubi's degrees now count mode steps), creative-pack `audio/sonic-brief.md` (the v1.2 amendment).
- 2026-09-29 · technical-artist · **the 3× cast landed** (Bar's density decision) + **May Golan** (Bar picked opt1):
  - **Rendered at d = 3** (288-px source, `density: 3` in `sprites.json`): all 23 rendered characters (Bibi, Sara, Bennett, 20 partner/opposition figures incl. May Golan) + the mic Dubi, idle + signature react, and the 5 rendered sources' stage strips (120 sprite px). Frames trimmed: 123-210 × 289-326 sprite px (Bibi 201×326, anchor [120, 325]). `hatMouth`/`temple`/events re-derived by the render; binary alpha, edge check (no waivers) and 2048 limit all pass; grids are now balanced (e.g. Bibi crit 7×2), widest texture 2040, tallest 930.
  - **Kept d = 1:** stages, props (hat/rabbit/coins), FX, UI kit, hand-drawn sources, small Dubi, 32/24-px avatars, and the shop icons/silhouettes (rendered from a 1× rig, pixel-identical to the approved ones; `sources[id].iconDensity: 1`).
  - **May Golan:** `refs/may-golan.png` = opt1; landmarks in `cast.py` (cuts below each ghost so a breath never splits one), `hop` react; the content id `maygolan` resolves via `aliases`.
  - **Checks:** a full render gives 0 drift vs the new approved `out/` (25 chars); `tools/test.sh` 135 passed, 1 failed (the known `test_input.gd::test_buy_a_producer_by_touch`).
  - **Budget:** web `.pck` art 3.30 MB (was 489 KB; cast 3.18 MB). VRAM typical resident 13.2 MB (Bibi 11.0 MB), a partner on demand 4.3-7.6 MB, all-resident 153 MB: never preload the cast (CONTRACT §7).
  - **Engine touch (data-driven reader fix, flagged):** `diorama.gd` critters and the `launch` set piece now scale by `4 / sources[id].density` (`_scale_of`); without it the d = 3 strips drew 3× too big. Nothing else in `game/scripts/**`.
  - **Pipeline:** Python 3.11-compatible f-string, numpy ints cast for JSON, source icon/frameH checks.
  - **Files:** creative-pack `art/showcase/src/{build,cast}.py`, `art/showcase/out/**` (+ `atlas.json`), `art/refs/may-golan.png`, `art/refs/candidates/README.md`; `pipeline/od-sevev/{sprites.py,README.md,budget.json,proofs/*}`; `game/assets/sprites/**` + `CONTRACT.md` §1, §3, §4, §4b, §7; `game/scripts/ui/diorama.gd`; `asset-requests/REQUESTS.md`
- 2026-09-29 · game-developer (sim) · the sim's open asks, all live; engine hooks under Requests.
  - **Format bug:** `test_investigation.gd:128` had a bare `5% ×` in a `%`-formatted message (GDScript reads `% ×` as a spec; there was no `%g` left). Fixed to `%%`; a scan of every `.gd` for unsupported specs is clean; `tools/test.sh` now fails on "String formatting error".
  - **The 5 held spins are live** (new `spins.gd`): kinds `consumable` (rebuyable, timer, fatigue^n, off the shelf while live) and `line` (levels in order), `costBpsSeconds` pricing; S02 `tapBuff`, S05 `basePerOppositionCard`, S07 `idleToTap`, S08 `karhiLine` (+2 % base, +4 suspicion per level, the card's two bars), S10 `flightIncome`. Holds removed from `design/content.json`; `pendingEngine: true` is the hold now (lint + `Politics.validate` agree).
  - **Designer asks:** `linesVariants` rotate in order per partner and line (saved; C1 stays variant 0); Gotliv's `pollLike` hides only her card in the blackout (`roster[].cardHidden`); the title reads "… מס׳ N" (`prestige.speciesNumber`); all 17 trophy stat keys in `GameState.stats` (persist, old saves seeded), counted in the sim, `countEvent`/`countUpgrade`/`countPartnerPaid` in the triggers; `neverAwarded` never counts.
  - **Engine ask:** `courtStart`/`courtEnd` carry `reason` testified | served, `postpone()` returns courtEnd postponed.
  - **Checks:** tests 158/159 (+23 sim tests; the 1 is the engine's `test_input`), `Politics.validate()` 0, content lint 0 errors. Balance: see Requests (the first-election gate was already red).
  - **Files:** `game/scripts/sim/{spins(new),economy,game_state,coalition,investigation,events,meta,story,content,politics,pacing_sim}.gd`, `sim/README.md`, `game/tests/unit/{test_spins,test_trophy_stats}.gd` (new), `test_{coalition,investigation}.gd`, `design/content.json` (+ `game/data/`), `design/sim/content-lint.mjs` (effect/condition sets mirror the sim), `tools/test.sh`
- 2026-09-29 · game-developer (views) · **T3 "קואליציה 61", the coalition chat** (rtl-map §6.3), a tall tab over stage + ticker + panel, a view of `state.coalition.chat` (no sim rule changed, no sim accessor added).
  - **Thread:** header (chevron, title + lock, status members / threats / "{name} מקליד…"), pinned bar (after round 1 it opens the agreement, `!` badge), bubbles with run grouping (avatar `avatar_<char>` 32 art at artScale/density = 128 and the name on the first of a run), forwarded threat, hatched ultimatum bubble with `chip_ultimatum` timer, `pay_pill_*` (gold / sunken track + fill from the right / "שולם" stamp slam), replies, system pills with the rejoin / poach pill, transfer banner, brawl cloud + "צאו החוצה", "ההודעה נמחקה", disabled composer. Drag scroll with momentum and wheel; newest at the bottom; arrival tweens, seat pips to Row B's fill head, reduced-motion variants.
  - **Reveal:** a partner bubble posted while T3 is open waits 1.2 s behind the typing telegraph; C1's first open plays the cascade (sys lines 250 ms apart); messages that landed while closed show at once.
  - **Entry points:** tab slot 3 (`Shop.tall_tab_requested`; re-tap closes), all of Row B, a chat toast (`Toasts.show_toast(text, "chat")` + `on_tap`), key 3, the cameo. Esc / back / chevron / a list tab close it. While open: no Magician taps, no Suitcase, no FTUE prompt.
  - **Partner card** (avatar or name): an `Overlay` with the idle figure at art ×3 (greyed at f0 when gone), seats, the open demand's pay pill, ✕ + "סגור".
  - **Ultimatum cameo** (§4.2): the newest open ultimatum's partner in the right column with the timer chip above the head; tap → T3 at that message.
  - **Audio:** `chatPing(partner)` on landing (open) or with the toast (closed); `ultimatumTick(sec)` once per displayed second; `ultimatumZero` when a timer runs out (replaces `chatLeft` for that case; `chatLeft` otherwise, moved from `main.gd` into the view); `stamp` + `ultimatumPaid` on paying; `panelOpen/Close`.
  - **allowPing is live:** `not modal and last buy ≥ 2 s and Toasts.idle() and not Toasts.saying()`, so C1 opens the group now. Slot 3's badge = open payable messages while T3 is closed.
  - **Fixed in passing (engine, one line in `shop.gd`):** a card hidden by the FTUE's single-card phase kept its row `key`, so on return it never re-read its model and could not be bought (on the web only card 1 bought). The row key now resets when a row hides.
  - **Deviations, stated:** the timer digits stay white on the red chip (the spec's alert red would not read on it); the cameo draws at art ×3 when body + chip fit between the toast dock and S − 140, else ×2 (at S 640 ×3 fits the body but not the chip), else it is skipped; a ceremony (Regev) pays after a 3 s "ribbon" fill on its pill.
  - **Checks:** `tools/test.sh` **144 passed, 1 failed** (the known `test_input.gd::test_buy_a_producer_by_touch`: headless lays out P = 0, so the card is off-screen; unrelated). New `test_chat_view.gd` (9): run grouping, content lines / gendered system lines / Distel's `{who}`, the avatar size from the manifest, three Ben Gvir bubbles = one avatar, a pill tap pays through `Coalition.pay` (+ stamp), no money = no payment, the ultimatum chip's timer + urgency + paying it deletes it, Row B / slot 3 / Esc / a list tab, C1 opens with allowPing live, the typing telegraph rule. Web build (`OD_LINT=warn`) at 390×844 DPR 2 in Chromium: C1 toast, cascade, pay → stamp + reply + thanks + Row B 33/61, ultimatum with a running timer, cameo, partner card; no page errors.
  - **Files:** `game/scripts/ui/views/view_chat.gd` (new), `game/tests/unit/test_chat_view.gd` (new), `game/scripts/main.gd` (a `_build_chat()` hook + input / key / allowPing lines), `game/scripts/ui/shop.gd` (tall-tab signal + active slot + the row-key fix), `game/scripts/ui/toasts.gd` (toast tag + `on_tap`).
- 2026-09-29 · game-developer (engine) · **integer art scaling landed, the input test is fixed, O-A3 resolved; the 3× cast is merged and verified in Chromium:**
  - **The failing test:** the half-landed scaling fed the 64×64 headless window to `Display` → k 1, f 0.25, a 256×256 canvas and a 0-px shop panel. Now a surface under 180×267 device px keeps the fork's `canvas_items` + `expand` stretch (`Display.integer` false). `test_buy_a_producer_by_touch` is unchanged and passes.
  - **Scaling:** `k = min(floor(W/180), floor(H/267))`, applied as the host viewport's stretch (window: stretch `disabled` + `content_scale_factor k/4`; SubViewport: `size_2d_override`). Input maps back through the same transform. The reasons are in HOW-TO-RUN "Integer art scaling".
  - **Density from the data:** `SpriteStrip.density_of/scale_of/apply_filter`. The TA's `Diorama._scale_of` is kept and reads `scale_of`; every critter, crowd and launch sprite gets the filter via `_scale_sprite`. Nearest when k/4·scale is whole, else `fractional_filter` ("aa").
  - **Measured in Chromium** (`tools/web/res_web.mjs`, headless, SwiftShader; horizontal runs on the stage art beside the Magician). Before is the same build with `?dev=1&forkscale=1`.
    - **390×844 @2:** before, art px 4.33 dp (runs 4 and 5, 6% whole); after k 4, 4 dp, 100% whole.
    - **@3:** before 6.5 dp (6/7); after k 6, 6 dp, 100%.
    - **430×932 @3:** before 7.17 (7/8); after k 7, 100%.
    - **1280×800 desktop:** before 2.5 (2/3); after k 2, 100%.
    - **393/412 @2 and @3:** 100% at k 4 / 6.
    - **The 3× cast:** crisp at k 6 (2 dp per sprite px, 100% whole). At k 4, k 7 and on desktop it is on the "aa" fallback: even texels with a one-dp blended seam, where before they were uneven 1/2 dp.
  - **Core verb in the browser, every size:** passed the disclaimer, tapped the Magician (motif), bought card 1 by touch (`buy_D_d25`), 0 page errors.
  - **O-A3:** Dubi never speaks over the motif. Tap 1's line starts at `musicalSeconds` (unit test: ±1 frame; browser, Audio clock: 2.332-2.457 s against 2.328). A headline does not cut the waiting line. `main.gd` now sends the line *after* the tap: before, it arrived while the gate was closed and was silently dropped. The motif's Voice duck is gone (nothing sits under it). The toast stays at f0.
  - **Tests:** `tools/test.sh` 141/141 (+4 `test_display.gd`, +1 `test_audio.gd`); strict web build green (lint 0 failures).
  - **Files:** `game/scripts/{core/display,main,ui/sprite_strip,ui/diorama,autoload/audio}.gd`, `game/tests/unit/{test_display,test_audio}.gd`, `tools/web/res_web.mjs`, `HOW-TO-RUN.md`. Shots: `build/shots/` (untracked).

## Data contract: politics content (game-developer sim → game-designer) — v1 BINDING, v2 withdrawn

**v1 is binding; the v2 I posted at ~23:45 is withdrawn.** The Designer had already mirrored v1
(`design/content.json` at 23:50: flags, coalition, partners, court, eventsConfig, events, calendar),
and v2 would have sent them back. Nothing to change for the Designer: the file lints clean against
v1 (`test_coalition.gd::test_game_content_passes_the_lint`).

Field reference: `game/scripts/sim/README.md`. Worked instance with the bench-tuned numbers:
`game/tests/fixtures/politics.json`. There, `"@4"` means "money source #4" (a test shorthand);
content uses real ids.

**The Designer's pending requests, now live in the sim:**
- `prestige.payout {scope: "round", rootDegree, divisor, epsilon}` + `prestige.gate {type: "seats"}`:
  base paid = floor(cbrt(runEarned / divisor) + ε) × (1 + basePctThisRound / 100), gated on the seats
  only (the legacy `multPerThumb` / `minPending*` keys are still read when `payout` is absent).
- `coalition.unlockScalePerElection`: a partner's `runBananasAtLeast` × scale^evolutions.
- `tap.pctOfBpsBase`, `tap.firstCrit {atTap, mult, randomCritsFromTap}`.
- `golden.firstOutcome`; outcomes' `era` (e.g. laundry, washington only) and `aide: true`; the
  fork's type names are also accepted (`bunch`, `frenzy`).
- `producers[].revealAtRunEarned`.
- Upgrade `unlock` keys now take the whole condition vocabulary (`era`, `shadyOwnedAtLeast`,
  `suspicionAtLeast`, `critsLifetimeAtLeast`, …).
- Effects: `tapAdd`, `offlineMult`, `basePctThisRound`, `suspicionGainMult`, `critChance {add}`,
  plus the buy-time effects `suspicionFreeze` and `wipeSourceSuspicion`.
- `upgrades[].followUp.fallbackAfterSec`: S13's invoice.
- The events effect `interview` now adds to the round's base **payout** (`basePctThisRound`), per
  the prestige formula, not to income. A new effect, `pledge {gatePlus, sec, baseAdd}`: Bennett
  raises the seat gate while up, then flips for +base. Swap his `none` for it when ready.

**Not yet implemented (spins slice, not plan step 5):** the effect types `tapBuff`, `idleToTap`,
`karhiLine`, `unlockEra`, `flightIncome`, `basePerOppositionCard` (partly: see sim/README) and the
upgrade kinds `consumable` / `line` / `fatigue`. The sim warns once per type at runtime
(`push_warning`), and the bench prints the list. See Requests.

## Data contract: engine content fields (game-developer engine → game-designer, technical-artist)

**Status: v1, live in the engine now.** Every field is optional; content without it keeps the
fork's behaviour, and an unknown id never crashes the stage (missing art draws a neutral "?"
placeholder).

`producers[]` (the money sources):

```jsonc
{ "id": "taxpayer",                 // any id; nothing in the engine names producers any more
  "name": "משלם המסים",              // display name (ui-strings producerNames[id] still overrides)
  "slot": ["F4", "F3", "B3"],        // or a tier index 0-7 (that tier's fork placement). Codes = diorama slots for the
                                     //   1st / 10th / 25th owned: row F (front, 8 slots 0-7),
                                     //   B (back, 7 slots 0-6) or S (sky, 9 slots 0-8) + index. Absent: the first
                                     //   free slots in producer order (front row first)
  "sprite": "critter_taxpayer",      // stage sprite (art.json id, or a PNG res://assets/sprites/<id>.png). Default critter_<id>
  "icon": "icon_taxpayer",           // shop row icon. Default icon_<id>
  "silhouette": "sil_taxpayer",      // the locked "מקור עלום" row icon. Default sil_<id>
  "idleFrameMs": 500,                // 2-frame idle period. Default 500
  "wander": true,                    // hops around its slot. Default false
  "setPiece": "lob" }                // lob | launch | blink | bob | absent. lob throws the currency icon across the sky,
                                     //   launch rises out of frame, blink flickers and reappears, bob floats
```

`eras.list[]` (the four locations):

```jsonc
{ "id": "balfour", "name": "בלפור", "fromEvolutions": 0,   // the era for n elections = the last with fromEvolutions <= n
  "skyBands": ["#…", "#…", "#…"],
  "background": "stage_balfour",     // full-stage 180x320 art key (PNG in res://assets/sprites/); hides the fork's palms/clouds
  "props": [ "prop_hut",             // a string = a fork prop with its fork placement
             { "sprite": "prop_flag", "xs": [60, 540], "anchor": "ground", "dy": -56,   // or an object: any sprite
               "scale": 4, "tint": "#d9d9f2", "scatter": 0, "twinkle": false, "hideClouds": false } ] }
```
The music follows the era id through `game/assets/audio/music_manifest.json` `"eras"` (the audio
data's map); an era id missing there plays the base track.

`golden` (the Suitcase):

```jsonc
"outcomes": [ { "id": "any", "type": "instant",  "weight": 0.4, "bunchBpsSeconds": 60, "bunchMinTaps": 30 },
              { "id": "any", "type": "bpsFrenzy", "weight": 0.4, "mult": 5, "durationSec": 15 },
              { "id": "any", "type": "tapFrenzy", "weight": 0.2, "mult": 10, "durationSec": 12 } ]
```
`type` is required for new ids (instant | bpsFrenzy | tapFrenzy; the fork ids bunch/frenzy/tapFrenzy
map implicitly). The buff multipliers read the first outcome of each type. The audio cue variants
keep the fork's names (the engine maps instant→bunch, bpsFrenzy→frenzy).

Internal state names stay the fork's (`bananas` = shekels, `thumbs` = the prestige currency,
`evolutions` = election rounds, `golden` = the Suitcase); they are code names only.
- 2026-09-28 · 2d-artist · UI kit (89 pieces, 1x, 9-slice manifest), wordmark v2, icon 1024/60, OG 1200x630, share-card frames, hand-drawn Suitcase, Dubi placeholders, style guide v2 + proofs; 3 ChatGPT rows filed (dubi-mic, photobomber-grey, photobomber-white) · `art/od-sevev/**`, `asset-requests/REQUESTS.md`
- 2026-09-28 · 2d-artist · wave 2: +96 kit pieces (sheet/modal, ticker bar + מבזק plate, source-card states, spin card + 15 spin icons + שחוק tag, opposition card front/back/timer, 17 trophy icons + plates, gear/sound, FTUE hand + ring, toast, 9px coin, courthouse-window echo, sweat drop, 8 pre-rotated stamps, cottage cup 13 states, laundry pieces, election curtain); 12 pictograms in Sevev 9; share cards refit to UX's 19+3 with full disclaimer + URL (UX objection accepted) · `art/od-sevev/**`, `pipeline/od-sevev/font/sevev9.glyphs`
- 2026-09-29 · 2d-artist · wave 3: the three object money sources hand-drawn (submarine, poison machine, gold chequebook), 40 ap tall incl. rim, 2-frame idles per motion/diorama-motion.md §1, + 24x24 shop icons cropped 1:1 from f0 · `art/od-sevev/out/ui/sources/`, `art/od-sevev/src/sources.py`, `ui-kit.json` (191 pieces)
- 2026-09-29 · 2d-artist · wave 4: small Dubi hand-drawn as layered grids, 35 frames (idle 16@8, talk 2, squawk 4, fly 4, land 3, peck 6), 20x23, anchor [10,22], events unchanged; qatari-folder maroon waiver logged in style guide §2.2 · `art/od-sevev/out/ui/dubi/`, `art/od-sevev/src/dubi_small.py`, `ui-kit.json` (197 pieces)

## Requests
- **From game-developer (views), T3:**
  - **→ ux-designer:** (1) a key for the ceremony pill (Regev); today it reads `CHAT_PAY` "סגרנו · 0 ₪" and fills over the 3 s ribbon. (2) A label for the partner card's upkeep (`PARTNER_UPKEEP`, e.g. "דמי אחזקה"); the card shows the value "−2%" unlabeled until it exists (the code already uses the key when present). (3) C1's fallbacks F1/F2 (badge bounce, bold label) are not built: `ftue.gd` has no C1 state.
  - **→ game-developer (engine):** (1) my one-line `shop.gd` fix (the row `key` reset in `refresh`) is in your file; please keep it in your merge. (2) `test_buy_a_producer_by_touch` fails because the headless window lays out P = 0 (`list_rect` height 0), not because of input. (3) `game/scripts/ui/views/view_rules.gd` does not compile once something references it ("Cannot infer the type of `earned`" in `trophy_model`); T3 does not use it.
  - **→ technical-artist / game-designer:** `maygolan`'s content avatar is `may-golan_avatar` but the cast slug is `golan`; the view resolves it (alias, then the avatar id, then its last part), but `sprites.json.aliases` `maygolan → golan` would make it explicit. `almog` has no art yet: its bubbles show the neutral card.
- **→ engine developer (from game-developer sim):** I'm now editing `game/scripts/sim/**`
  (`economy.gd`, `game_state.gd`, `save_store.gd`, `meta.gd`, `pacing_sim.gd`, `content.gd`,
  plus new files). I've seen and kept your wave-1 changes there (typed golden outcomes, `HK1:`
  prefix, no v1 migration). Please route any further `sim/` change through a note here. I'll add
  one line to `game/tests/fixture.gd` (an `use_politics_content()` helper) and leave the rest of
  it alone. The module APIs you'll wire follow here when they land.

- **→ game-developer (engine), from ux-designer:** (1) run `tools/sync_data.sh`: `ux/ui-strings.json` is now Hebrew, so `test_data_sync` stays red until `game/data/` is re-copied. (2) Until Hebrew goes through `Label`/`RichTextLabel` + the bitmap `FontFile` (engine review U6), every `PxText` showing a Hebrew key draws fallback boxes; `ux/string-budgets.json` marks the 15 keys that may stay `PxText` (`surface: "pxtext"`). (3) The strings already contain LRI/PDI isolates and U+00A0 before ₪; don't add or strip them. (4) Key rule for the sim's dotted message keys: `key = id.upper().replace('.', '_')` + `_M`/`_F` (gender, from `partners[].g`) or `_ONE`/`_TWO`/`_OTHER`/`_ZERO` (plural); every first-minute §8 id resolves. Placeholders: `{name}` = the partner's display name (but `chat.sys.muted`'s `{who}` = `partners[distel].copy.mutedWho`, "היועצים המשפטיים", never Distel's name), `{to}`, `{a}`, `{b}`, `{n}`, `{price}`. The poach pill on `chat.sys.removed` is `CHAT_SYS_POACH`. (5) `ux/rtl-map.md` §1.2 replaces the 40/60 extra-height split: at 390×664 (Safari with toolbars, the WhatsApp entry) the fork overflows by 54 px and would cut off the bottom tab bar. (6) Touch-target floor is 88 logical px (44 CSS at 360 wide), not 81. (7) `ux/ftue.md` replaces `ftue.gd`'s P1-P7 and needs a `window.mbHandoffDone` flag from `shell.html` to start the FTUE clocks.
- **→ technical-artist / 2d-artist, from ux-designer:** the pixel font (`art/od-sevev/src/hebfont.py`, v2 now has `*`) still lacks Latin `E S C` (the desktop key legend "S", "ESC"); draw them at body height like K M B T. The full set is `requiredGlyphs` in `ux/ui-strings.json` (67 glyphs, U+00A0 maps to the space glyph).
- **→ game-designer, from ux-designer:** `ux/ui-strings.json` `producerNames` mirrors copy deck §C keyed by the fork ids in the pitch §4 order (`intern` … `moon`), and `upgradeNames`/`upgradeEffects` use the deck's spin ids `s01`-`s14`. The engine lets `producerNames[id]` override `content.json` names, so if you rename producer ids, tell me and I re-key (or your content names win automatically, because stale keys no longer match). The short spin effect labels are derived from your deck §D effect column; correct any number there and I regenerate.
- **→ technical-artist / orchestrator (from 2d-artist):** `showcase/out/ben-gvir_avatar.png` and `gotliv_avatar.png` have a maroon ring (maroon is reserved for the Suitcase). Fix in `showcase/src/build.py`: the 'jab' ring `(138,21,56)` → `(208,42,54)` (`red`). Style guide v2 §16 F6.
- **→ ux-designer (from 2d-artist):** the art-side text capacities for your 720x1280 layout (28 glyphs per full-width line at the 5x9 cut, 17 per chat-bubble line, receipt 25x22) and flags F1-F5 are in `art/od-sevev/style-guide.md` §16.

- **→ technical-artist, from animator:**
  - **(1) OBJECTION O-M1.** The approved `bibi_idle/tap/crit` strips clip the hat's left brim at the frame edge. Column x=0 is opaque in 35 of 42 frames, up to 12 px (tap f1, crit f1). Pad the frames 3 px on the left in `build.py`: `frameW` 71 → 74, anchor [38, 124], every `hatMouth` x + 3. This changes no timing and no look.
  - **(2)** Emit exact `hatMouth` tables for `bibi.crit` and `bibi.idle` from `hat_anchor` (mine are derived from the outline bbox, ±1 ap: `motion/state-graph-magician.md` top).
  - **(3)** Generate a `hatGlow` sprite (a 1-ap outline of the hat mask, lightest palette colour).
  - **(4)** Add fx-data ids for od-sevev: `dustPuff`, `ballotConfetti` (24 slips, 900 ms), `inkSpecks`, and the coin budget (≤ 36 coins alive; `motion-spec.yaml` coin-burst).
  - **(5)** The chat avatar in UX rtl-map §6 is 48 logical px, which is ×1.5 of the 32-px avatar strips and so a fractional pixel scale. Render it at 24 art px ×2, or 32 art px ×1 or ×2.
- **→ audio-director, from animator:**
  - **(1)** Please start the election fanfare **on the confirm f0**, not on the next bar line. It replaces the bed, and the darbuka roll is the bridge.
  - **(2)** Publish per-variant `markers` in `cues.json`: `rollEnd`, `tagOnsets[]`, `fanfareEnd` (the visual IMPACT, the tag hops and the curtain uncover are anchored to them), plus the transfer whistle's `w1/w2/w3` and the Suitcase catch's reversed-zipper length.
  - **(3)** When your cue list lands, run the checklist in `motion/event-markers.md` §6. Recommendations: a crit tap still plays the tap blip at f0, and #2 rabbit fires at `crit.rabbit` (+250 ms).
  - **(4)** Adopt, rename or null each "proposed" cue.
- **→ ux-designer, from animator:**
  - **(1) OBJECTION O-M2.** The ticker crawl in rtl-map §5.2 (`v = 74`, `snap(v·t, 3)`) steps at 24.7 texels/s, an uneven 2-3-2-3 frame cadence that visibly stutters at 60 Hz. The alternative: `tickerStepHz` 20, one step every 3 frames, so the speed is 20 × fontScale (60 logical = 32.5 CSS px/s at ×3, 80 = 43.3 at ×4 large text). If faster is wanted: 30 steps/s = 90 logical (48.8 CSS).
  - **(2)** Please confirm the partner-card entry point (tap an avatar or name in the thread).
  - **(3)** Please accept or decline the **stage cameo** for an open ultimatum (`motion/state-graph-cast.md` §2b).
  - **(4)** The brawl-cloud slot: I propose inline in the thread above "צאו החוצה".
  - **(5)** The optional `idleInvite` coin peek after 20 s without a tap.
  - **(6)** Sara's mark on the Balfour stage.
  - The hat pulse (1 Hz / 2 Hz), the seats rim (1 Hz), the Suitcase bob (±8 px) and the first flight (760 → −80, 6.0 s) now match `ux/ftue.md` and `ux/rtl-map.md`.
- **→ game-designer, from animator:**
  - **(1)** `court.courtPausesTaps: true` (the sim placeholder) removes the paying verb for 30 s. I recommend `false`, with taps at `courtBpsMult`. The motion supports both: the hat left on stage hops and pays (`hatTap`), or hushes with the rabbit's ears (`hatHush`).
  - **(2)** Crits during court day: I recommend live, shown as `hatCrit` (the rabbit pops up, sees the court and ducks: H-court's line).
  - **(3)** Sara's `offended` triggers are proposed as the S01 bottle-deposit purchase, plus the pistachio spin if you want it. She has a cooldown of 8 s and is never a tap target.
  - **(4)** `cast.py` gives Gafni `react: 'sneak'`, but `build.py` renders it as a hop. There is no sneak strip for launch.
- **→ 2d-artist, from animator:** motion needs these art assets:
  - the Suitcase sprite, ≥ 20×16 ap;
  - the stamps, drawn **pre-rotated** about −8° (no runtime rotation of pixel text);
  - the receipt's zig-zag tear edge;
  - the Cottage cup, ≥ 12 states;
  - Washington laundry pieces;
  - Dubi with a beak-open frame;
  - the curtain for the election ceremony (ticker maroon plus a ballot-slot motif);
  - optional: a sweat drop plus a temple landmark for the thermometer's diegetic echo.
- **→ game-developer (engine), from animator:**
  - The legacy motion docs are now in `motion/legacy/*.monkey-bananas.*`, so code comments that point at the old paths should read them there.
  - Mirror `motion-spec.yaml` `motion-constants` into `Tune.MC`.
  - Emit `courtSummons` / `courtStart` / `courtEnd(reason)` / `electionConfirm` / `trickCue` / `ceremonyEnd` as defined in `motion/state-graph-magician.md` §2.1.
  - **Every action strip is entered at f1, never f0.** Measured: f0 of every action strip equals `idle.f0` pixel for pixel, so it is pure latency.

- **→ orchestrator (owner of creative-pack `art/showcase/src/build.py`), from technical-artist:**
  thanks for the Bibi re-render and the avatar ring fix; both are imported.
  - **The hat is still clipped.** At `frameW` 75 it is cut by up to 2 px at x=0 in idle f2-8, tap f1
    and crit f1.
  - **Measured:** with `Rig('bibi', H, pad=(0.30, 0.30))` → `frameW` 81, the leftmost hat texel lands
    on column 1 in *every* frame, including the squished tap f1.
  - **Proposed:** pad 0.30 (`frameW` 81, anchor [40, 124]).
    - Anything narrower keeps some frames clipped, and a post-pad can't restore texels the render
      already cut.
    - The look doesn't change. The manifest carries `frameW`, `anchor` and `hatMouth`, so the engine is
      unaffected.
    - When it lands, I drop the waiver in `pipeline/od-sevev/sprites.py`, and any edge contact fails the
      build again.
  - **Critters:** see my note under the money-sources row in `asset-requests/REQUESTS.md`: render them
    at 40 art px tall, not 64-96, for the engine's 20-art-px diorama pitch. I agree with the 2D Artist:
    drop the ChatGPT suitcase row.
  - **24-px chat avatars:** for the animator's (5), add a size parameter to `avatar()` and emit
    `<char>_avatar24.png` from the refs. The pipeline imports it as `avatar24_<char>`, drawn at ×2 =
    the UX's 48 logical px.
- **→ game-developer (engine), from technical-artist:** the full contract is
  `game/assets/sprites/CONTRACT.md`.
  1. **SpriteStrip:** it reads `res://assets/sprites/sprites.json`:
     - `chars[id]`: `frameW`/`frameH`/`anchor`, and per anim `texture`/`frames`/`fps`/`loop`/`events`,
       plus Bibi's per-frame `hatMouth` for idle, tap and crit.
     - `aliases`: `bengvir → ben-gvir`.
     - Draw origin = feet − anchor·4.
  2. **Single-frame art** follows your rule `res://assets/sprites/<id>.png`: `stage_<era>`,
     `prop_<name>`, `avatar_<char>`, and every UI-kit id. 9-slice, frames and pivots are in
     `sprites.json.ui[id]`.
  3. **Hebrew *and* numbers** go through a `Label` with `res://assets/fonts/sevev9.fnt`
     (`sevev9_outline.fnt` over art). **Retire `PxText` for visible text:** its 5×7 digits don't
     match Sevev's.
     - `font_size` must be a multiple of 9 (18, 27, 36, 45, 54).
     - Set `font_color` explicitly (the default is 0.875 grey).
     - `outline_size` does nothing on a bitmap font; use the outline cut.
  4. **Aspect expand:** fill above and below the 180×320 stage with `stages[era].padTop` /
     `padBottom`. The Magician's feet go at `magicianFeet` = (94, 219) art px.
  5. **Diorama rows:** `layout.gd` `DIORAMA` puts critter feet at art y ≈ 150-162, which is inside the
     new stages' landmark band and the Magician's slot (y 150-216, style-guide stage skeleton). The
     rows need re-placing with the design and UX roles.
  6. **Icons:** `game/assets/icon/*.png` now come from the 2D Artist's master through my pipeline.
     **Don't run `tools/icon.sh`**, which would restore the banana; retire it or point it at
     `art/od-sevev/out/key/icon-64-art.png`. The boot splash still uses the fork's purple `bg_color`;
     the icon field is `#4a2552`.
  7. **OG image:** `art/od-sevev/out/key/og-1200x630.jpg` is ready for `game/web/`.
- **→ ux-designer, from technical-artist:**
  - `*` and Latin `E S C` are in: every Latin capital is now drawn at body height, and a-z draw them.
  - **`T` is now 5 px wide** (advance 6, was 4). The draft's 3-px T was pixel-identical to ז, and the
    pipeline's pair-collapse guard refuses that.
  - **Re-run your width lint against `game/assets/fonts/sevev9.fnt` `xadvance`**, the shipped truth.
    Every character in `ux/ui-strings.json` is covered.
- **→ 2d-artist, from technical-artist:** your `art/od-sevev/ui-kit.json` imports as-is. The pipeline
  validates size, binary alpha, 9-slice margins and frames×frameW; add a row and it ships on the next
  run.
  - **Flat UI the game still needs** (not in the kit yet):
    1. A generic sheet/modal 9-slice: settings O7, About O8, the return card O1, the "לפזר את הכנסת"
       election modal, the round card.
    2. The ticker bar (Dubi's lower third) and the red "מבזק" label plate.
    3. The money-source card (shop row) with locked / affordable / owned states. The price pill can
       reuse `pay_pill_*`.
    4. The spin card, 14 spin icons at 15×15 (deck §D s01-s14) and the "שחוק" tag.
    5. The opposition event-card template (8 cards).
    6. 5 trophy icons ("תיק הישגים").
    7. ⚙ and 🔊 on/off icons.
    8. The FTUE pixel hand (tap loop, UX F2).
    9. The toast/banner ("נפתח לך תיק").
    10. A 9×9 coin icon for the shekel counter.
    11. The courthouse-window light-up overlay (the diegetic echo of suspicion ≥ 75%).
- **→ animator, from technical-artist:** anims that exist only as needs, so the render owner can't
  render them yet:
  - the Magician's sweat (suspicion ≥ 75%), court-day and "עוד סבב!" celebration;
  - Dubi's squawk, fly-in and hat-peck (FTUE F1);
  - each money source's 2-frame idle, plus the taxpayer's walk-on-and-drop (FTUE beat 11).

  Spec them in `motion/**` (frames, fps, event frames); the render-down rig and my pipeline carry
  `events` through unchanged.
- **→ animator, re your requests to technical-artist:**
  1. **O-M1:** agreed; see my request to the orchestrator. 75 px is still 2 px short; 81 clears it.
  2. **Exact `hatMouth`:** in `sprites.json` `chars.bibi.anims.{idle,tap,crit}.hatMouth`, per frame,
     in frame px.
     - `tap` comes from the render.
     - `idle` and `crit` are found in each frame's pixels by an exact match on the hat's lower 8
       rows.
     - The matcher agrees with the render's `tap` table in every unsquished frame, and the build
       fails if it ever doesn't.
  3. **`hatGlow`:** `prop_hat_glow` is 24×18, a 1-ap `white` ring outside the hat mask. Draw it at
     the hat's top-left − (1, 1).
  4. **fx-data:** `ballotConfetti` (24 slips, 900 ms), `dustPuff` and `inkSpecks` are in
     `pipeline/fx-data.json`.
     - The coin burst stays an engine tween capped at 36 alive, per your spec. The particle player
       can't spin a particle's frames, so it can't carry the 16 fps coin spin.
     - A true x-sine flutter for the slips needs a small player feature. I approximate it with two
       slip orientations and low gravity.
  5. **Chat avatar:** 48 logical px = 24 art px at ×2. That size is requested of the orchestrator as
     a render option, above. Don't scale the 32-px avatar by 1.5.
- **→ game-designer (+ ux-designer), OBJECTION from technical-artist (font-and-bitmap-text-pipeline):**
  ```yaml
  objection:
    skill_or_agent: font-and-bitmap-text-pipeline
    against_artifact: design/content.json (partner lines, leaked chat, events)
    reason: |
      22 emoji (🔥 🙏 💸 👍 ☕ 🚻 👌 ⚖ 🎀 ✂ 📸 🤝 📈 👻 📺 ⬅ ⭐ 🔇 🖊 🙄 💪 ⏳, listed by
      `python3 pipeline/od-sevev/build.py`) are in strings the canvas draws through the Sevev 9 bitmap
      FontFile. A bitmap font has no colour emoji and no system fallback on web, so each one
      renders as a missing-glyph box. That breaks the UX rule "in-game icons are pixel icons, not
      emoji" (first-minute §3.5), and it breaks the joke lines that lean on them
      (Karhi's "📺⬅️📺").
    proposed_alternative: |
      Keep a closed list of at most 12 pictograms that still read as 7-row monochrome glyphs:
      📺 ⬅ ☕ ⭐ ⏳ ⚖ ✂ 🔥 👻 📈 🔇 💸. The 2D Artist draws them as blocks in
      pipeline/od-sevev/font/sevev9.glyphs; it is a content edit, and the pipeline builds them into
      both cuts. Reword or drop the rest (🙏 👍 👌 🤝 💪 🙄 🚻 🖊 📸 🎀), because they don't
      survive 7 px. Emoji stay unrestricted in share text and the OG card. U+FE0F is already a
      zero-width glyph.
  ```

- **→ game-developer (sim), from game-developer (engine):**
  1. **The game does not boot on the current `design/content.json`.** `Economy.derive` reads
     `prestige.multPerThumb` and `evolve_visible` reads `prestige.showEvolveButtonAtAllTimeBananas`; the
     new prestige block (`payout`, `gate`) has neither, so `d` is null and every frame errors
     (`tools/godot.sh --headless --path game --quit-after 240` shows it). The engine side is ready; the
     web build I screenshot needs this path green.
  2. The designer's outcomes use `"type": "bunch"`. `Content.outcome_type` (your file now) asserts on it.
     Either the content says `instant` (contract above) or `content.gd` maps the fork names
     (`bunch → instant`, `frenzy → bpsFrenzy`) as aliases. I'd take the alias: it is one line in
     `_LEGACY_OUTCOME_TYPE` lookup order (`type` first through the map).
  3. I pinned the fork's unit tests (and `test_audio`, `test_input`) to `tests/fixtures/content.fork.json`
     via `TestFixture.use_fork_content()`; your politics tests are untouched. `Audio` now reads eras
     through `Content.data()` (one source) instead of re-reading the file.
- **→ game-designer, from game-developer (engine):** (1) golden `type` must be `instant | bpsFrenzy |
  tapFrenzy` (you have `bunch`); (2) `producers[].slot` as an int works (a tier index → that tier's fork
  placement), but the TA notes the fork's diorama rows sit inside the new stages' Magician band: the
  slot rows need re-placing with UX (wave 2); (3) `eras[].music` is not read by the engine: the music
  follows `game/assets/audio/music_manifest.json` `"eras"` keyed by era id (→ audio-director);
  (4) `narrator.sprite` (optional) picks Dubi's art; `hero.char` (optional, default `bibi`) the Magician.
- **→ ux-designer, from game-developer (engine):** `tools/lint_text.sh` runs your `ux/string-budgets.json`
  against the shipped `sevev9.fnt` (space xadvance 4, T 5 px wide; the budgets assumed space 3). Today:
  **5 failures**, the build fails on them (`OD_LINT=warn tools/build_web.sh` only for interim builds):
  - `ROW_OWNED_BPS` 219 px in `card.line2` (216);
  - `HUD_SUSP_HOT` "מבעבע" 90 px in `stage.thermo` (88);
  - `upgradeEffects.s10` 354 px in `card.line2wide` (352);
  - `F_UPGRADE_FLAVOR` and `STORY_TITLE` are `surface: "pxtext"` but hold Hebrew.
  Also: please add `IMP_PROMPT` (the paste-your-save-code prompt; the engine falls back to
  "הדביקו את קוד השמירה (HK1:…)"). Your points (2)(3) are done: all text shapes through TextServer,
  isolates are never added inside an already-isolated placeholder. rtl-map's full HUD rebuild
  (Row A/B, bottom tab bar, the flex rule, 88-px targets, ftue.md) is the next engine wave; this wave
  mirrors the fork's existing layout.
- **→ technical-artist, from game-developer (engine):** consumed: `sprites.json` (SpriteStrip, stages,
  `magicianFeet`, props, `suitcase`, `dubi_placeholder_avatar`), `sevev9.fnt` + `sevev9_outline.fnt` (the
  outline variant uses your cut), icons (`tools/icon.sh` is retired), OG image copied to `game/web/og.jpg`.
  One deviation, stated: text nodes draw the FontFile with TextServer at size 9 scaled by the integer
  text scale through the canvas transform, not a `Label` at `font_size` 27; same glyphs, same advances.
- **→ audio-director, from game-developer (engine):** the Magician's crit strip fires a `sting` event on
  f5 (and the TA lists `huff`, `whoosh`, `bang`, `land`, `shout`, `step` for the cast). No cue exists; the
  engine ignores them until `cues.json` names one. The music follows `music_manifest.json "eras"` by
  content era id (`balfour`, `knesset`, `courthouse`, `washington` now); unknown ids play the base track.
- **→ 2d-artist, from ux-designer (rev 2):** F1, F2 (option b: the chip shows 27.10; the day count moves to the title state and the daily ticker line), F4, F5 accepted; see `ux/rtl-map.md` §12. **F3 accepted with a counter:** both share-card sample proofs drop the URL, and the receipt drops "או מועמד" from the disclaimer. Please keep the full line "סאטירה. לא קשור לאף מפלגה או מועמד." (2 lines) and a URL line on both cards: iOS WhatsApp strips the share text when an image is attached, so the image is the only carrier. The fitted receipt is in `ux/string-budgets.json` (receipt boxes; 19 text lines + 3 rules = 21.7 of 22). Also needed: (a) `thermo_tube_short` 14×58 art for stages under 560 logical; (b) a 16×16 Dubi head for the ticker anchor; (c) 16×16 avatar crops for chat toasts; (d) the card price pill is the `pay_pill` 9-slice stretched to 42×22 art (two lines), not 54 wide; (e) count badges at the icon's top-left (RTL trailing corner).
- **→ animator, from ux-designer (rev 2):** crawl objection accepted (`ux/rtl-map.md` §5.2). Placements: partner card opens from the avatar or sender name in the thread (§6.3); **stage cameo accepted** with the right-column slot, an ultimatum timer chip above the head, and tap → chat (§4.2); brawl cloud inline in the thread, 208×160 centred, between the system line and the button (§6.3); idle coin-peek invite accepted only while `evolutions == 0 and owned_total < 3` (§4.2, `ux/ftue.md` I0); Sara's mark = right column, feet (652, S−140), art ×2, fades out while a cameo is on stage.
- **→ technical-artist, from ux-designer (rev 2):** canvas text is now **x4 base, x5 large** (`ux/rtl-map.md` §0). Please also build a 7-row numeral cut (digits . , + − K M B T ₪) for the Row A counter and modal big numbers at x4.
- **→ game-developer (engine), from ux-designer (build review, 23:48 web build, 390×844, fresh origin):** (R1, **blocker, legal**) no N1 disclaimer: a first launch lands straight on the title state; implement it in `shell.html` per `ux/rtl-map.md` §9 with the `DISC_*` keys, no bypass, engine loading behind it. (R2) the first minute reveals everything at tap 1: rate line "+0.0 ₪ לשנייה", both tabs incl. ספינים, card 1 as "מקור עלום" then card 2, the stage book button; the hand appears the instant 15 ₪ is reached; `F2_HIRE` crawls in the ticker; a Suitcase flew mid-stage before any source was owned. Implement `ux/ftue.md` §1.1 flags and §3 predicates (and retire the fork's P1-P7 text). (R3) the card body is not a buy target (tapping the name area did not buy; only the pill does); make the whole card the hit, `rtl-map.md` §6.1. (R4) layout is still the fork's: tabs at the top of the shop, no Row B, a 26-CSS ticker (below the 88-logical floor), the pink stat window; apply `rtl-map.md` §1-§6 including the flex rule. (R5) pill semantics: unaffordable reads "חסר / 15 ₪" (the price, not the 5 ₪ actually missing) and affordable turns green; use verb + price with the fill from the right, gold when affordable (kit `pay_pill`); "חסר {n}" only with the true missing amount. (R6) settings: ✕ top-right, no bottom "סגור", centred card instead of a bottom sheet, rows are notation + save code instead of טקסט גדול + אודות ומקורות, ON knob on the right; `rtl-map.md` §7.1, §7.4. (R7) title state: the round line sits on the busy Balfour facade with no scrim and crosses the hat; the wordmark is text, not the kit `wordmark`; no countdown line; `rtl-map.md` §8. Note: the build predates UX rev 2 (text ×4 base); `tools/lint_text.sh` will pick up the new scales from `ux/string-budgets.json`.
- **→ game-developer (engine), from audio-director (od-sevev audio, published):**
  - **The spec and the numbers:**
    - The spec is `audio/od/cue-spec.md`.
    - Every runtime number is in `game/assets/audio/od/od_manifest.json` (files, `play_db`, bars, loops, ducks, priorities, markers, `babbleContours`).
    - Files load straight from `res://assets/audio/od/`: QOA `.res` files with the loops built in and no import step. There is one file per pitch; never use `pitch_scale`.
  - **The ids to wire:**
    - **Eras / tracks:** `balfour`, `knesset`, `courthouse`, `washington`. The stems are `music_<era>_L0|L1|L2.res`, plus `music_balfour_outside.res` on a new Outside sub-bus.
    - **Layers** (they replace base/evolved/frenzy):
      - L0 is always on.
      - L1 turns on at `sources_owned >= 1`.
      - L2 plays while the last tap was < 3 s ago. It is forced off during court day and during an ultimatum's last 3 s.
      - All of them switch at the next bar and fade over 1 bar.
      - The 4-loop mute cycle is `antiFatigue`.
    - **Stingers:** `fanfare` (per key × tags 0-4), `courtIn` (G), `motif`, `milestone`, `dubiFlash`, `trophy`.
    - **Cues:** `tap`, `rabbitCrit`, `suitcaseSpawn`, `suitcaseCatch`, `suitcaseMiss`, `chatPing`, `ultimatumTick`, `ultimatumZero`, `gavel`, `gavelWeak`, `courtOut`, `stamp`, `transferWhistle`, `shutter`, `dubiSquawk`, `dubiBlip`, `returnAway`, `buy`, `cantAfford`, `uiClick`, `coin`.
    - **`chatPing` variants:** `default`, `benGvir`, `smotrich`, `deri`, `goldknopf`, `gafni`, `levin`, `regev`, `gotliv`, `left`, `burst`.
    - **Keys:** D (Balfour), E (Knesset), G (Courthouse, and court day in any era), F (Washington).
  - **Requests (all in `audio.gd` / the bus layout; the data and the files are done):**
    1. **The cut-over.** Point `Audio` at `od_manifest.json` in place of `music_manifest.json` / `sfx_manifest.json` / `cues.json` / `cues_v2.json`. Then retire `gen_audio.gd` and `gen_music.gd` from `tools/audio.sh`, which saves the fork's 16.1 MB of stems and 1.7 MB of SFX.
       - After that I move `audio/{cues,music}.json` and the MB docs to `audio/legacy/`, and promote `audio/od/*` to their places.
       - Until then I left them alone, so `test_audio` and `test_data_sync` stay green. (`tools/test.sh`: 107 passed; the 6 failures are coalition, events and politics_save, not audio.)
    2. **The strict tap walk (A3).** Step = streak mod 8, with the streak resetting after 400 ms. Alternate d25/d12 per tap, with ±1.5 dB jitter. **The first Magician tap (the unlock) plays the `motif` stinger instead,** and Dubi's first squawk follows it.
    3. **The master chain:** the HardLimiter alone (ceiling −1 dB). Remove the Amplify −1.7 and the compressor (−14 dB 6:1, +5.3 makeup): `play_db` is calibrated with unity buses.
       - Buses: Music (→ Outside: LPF 800 + Panner −0.3), SFX-Critical (→ Suitcase: a panner set at spawn), SFX-Frequent, UI, Voice, all at 0 dB.
       - The settings slider law: the default position = 0 dB.
    4. **Ducks from `cues.<id>.ducks`:** Voice −6 dB (30/250 ms), SFX-Critical −4 dB (50/200 ms). The deepest duck wins. Taps and UI duck nothing.
    5. **Court day:** the gavel, then at the next bar a crossfade (the existing `set_era` path) to `courthouse` with L2 off, with `courtIn` on that bar line. On exit, crossfade back plus `courtOut`.
    6. **The fanfare:** on the election-confirm frame, stop the bed (30 ms) and play `fanfare[incoming key][min(round-1, 4)]`. Start the new era at bar 1 after exactly `musicalSamples`, not at the file's end.
    7. **Chat pings:** ≤ 1 per 700 ms, coalescing into `burst`. Never during Dubi: queue them until 300 ms after he stops.
    8. **Dubi's babble:** 8 blips/s from the 10-blip era bank (`dubiBlip_<key>_<degree>_<octave>`), a final "!" one degree up, a 1.6 s cap, ≤ 1 ticker headline per 20 s. Canned lines follow `babbleContours`.
    9. **Pink Front:** the Outside LPF sweeps 800 → 4000 Hz over 2 bars with +8 dB. Tap-to-beat judges against `outside.judgeSamples`.
  - **Your crit `sting` event and the TA's cast events** (`huff`, `whoosh`, `bang`, `land`, `shout`, `step`) are null, except `bang` / `bang2` (Levin) → `gavelWeak`. See cue-spec §5.
  - **`tools/audio.sh`:** I added 3 guarded lines: run `gen_od_sevev.gd` if it is present, include `od/` in the `--check` snapshot, and print the od size line. Nothing else in `tools/` changed.
- **→ animator, from audio-director:** your §6 checklist is answered in `audio/od/cue-spec.md` §5.
  - The markers are in the manifest: `stingers.fanfare.files[key][tags].markers` = `{pickup, rollEnd, tagOnsets[], fanfareEnd}`.
  - The cue markers are in `cues.<id>.markers`: transfer whistle w1/w2/w3 = 0/160/320 ms; the catch's cha-ching at 130 ms; the gavel's knock2 at 180 ms.
  - **Your fanfare request is accepted:** it starts on confirm f0.
  - The crit tap plays `tap` at f0, and `rabbitCrit` at +250 ms (+83 in reduced motion).
  - The postponement is `gavelWeak` alone.
  - Adopted: `coinArrive` → `coin`, `electionReady` → `milestone`, Levin → `gavelWeak`. Every other proposed cue is null.
- **→ ux-designer, from audio-director:** your "music on, at 60% of the SFX level" is built into the mix.
  - The tap bursts sit at −16.6 LUFS in their own 1.5-4 kHz slot, over music at −17.3 LUFS integrated.
  - So I asked the engine for a slider law where the default position = 0 dB. If the 60% is applied as a −4.4 dB gain on top, the music drops under its calibration.
  - Your ping-vs-Dubi rule (queue ≥ 300 ms) is in the spec.

- **→ orchestrator (render owner), from animator (wave 2):** everything to render is in **`motion/render-requests.md`**:
  - Dubi: 6 strips at 18 tall, plus 2 on the 96-tall mic pose;
  - the 8 money sources' f1 recipes at 40 tall;
  - `prop_sweat` and the `temple` landmark.
  - **No walk cycles, and no new Magician strips.**
  - The landmarks each recipe needs are listed per row, for `cast.py`.
- **→ audio-director, OBJECTION O-M3 from animator (ui-and-screen-motion):**
  ```yaml
  objection:
    skill_or_agent: ui-and-screen-motion (animator)
    against_artifact: cue-spec (audio/od/cue-spec.md §2.4, election fanfare start)
    reason: |
      The fanfare waits for the next bar line after the confirm (the bed stops, then the fanfare). That puts 0 to 1 bar
      (up to 2069 ms in D, 2727 ms in G) of dead wait between the player's biggest decision and the drum roll, and then
      the roll adds another bar before the IMPACT. Worst case, the sting lands 4.1 s (D) to 5.5 s (G) after the tap.
      That is well past the 400 ms Doherty threshold for the first perceived response to an action (ui-and-screen-motion
      DOG). The music needs no bar alignment here: the incoming era restarts at bar 1 anyway, after musicalSamples.
    proposed_alternative: |
      Start the fanfare on the confirm frame, with the 30 ms bed fade you already specify. The darbuka roll's crescendo
      masks a mid-bar stop of the old bed, and the bar-1 restart is unaffected. If a grid is required, quantize to the
      next BEAT (≤ 517 ms in D, ≤ 682 ms in G). Motion already tolerates either: the anticipate crouch absorbs any wait,
      and every visual beat reads the derived markers.
  ```
  - **Also OPEN:**
    - Paying a partner (the "שולם" stamp) has **no cue** in your list. I propose `stamp`.
    - Does a crit's f0 still play `tap`? I recommend yes.
    - Please acknowledge `rabbitCrit` on the `crit.rabbit` marker (+250 from entry).
    - The first-tap Dubi squawk: UX puts it at f0, your spec after the 4.1 s motif. Please settle it with UX; motion is
      anchored to the `dubiSquawk` event either way.
  - The rest is reconciled in `motion/event-markers.md` §6.
- **→ game-designer, from animator (wave 2):** for `design/content.json` `producers[]`, from `motion/diorama-motion.md`
  §1:
  - `idleFrameMs` per source: taxpayer 700, hitech 300, vat 600, cigars 500, submarine 800, qatari 1000, poison 400,
    washington 700.
  - `setPiece`: taxpayer `lob` (retargeted at the hat), submarine `bob`, qatari `blink`, the rest `absent`.
  - `wander: false` for all.
- **→ ux-designer, from animator (wave 2):**
  - Dubi renders **18 art px tall** (72 logical), not 16. Please widen the ticker's Dubi box (rtl-map §5.1) to about
    20×18 art px.
  - The Dubi fly-in, peck and card-hop follow `ux/ftue.md` P0 F1 / P1 F1 exactly. Under reduced motion he "appears", as
    you specified.
- **→ 2d-artist, from animator (wave 2):** `prop_sweat` is 3×4 ap, 2 frames (a bead, then falling). The spec is in
  `motion/render-requests.md` §B.
- **→ game-developer (engine), from animator (wave 2):**
  - Read `hatMouth` (and `temple`, when it lands) from `sprites.json`. Never copy them.
  - Dubi's beak is driven by the `dubiBlip` onsets.
  - The diorama idles are desynced per instance (`motion/diorama-motion.md` §1).
  - The election curtain timing is re-derived so the uncover ends on `fanfareEnd` in every key (`motion-spec.yaml`
    `election-ceremony`).
- **→ animator (from 2d-artist):** your wave-1 art asks are in the kit (style guide §17): `stamp_*_rot` (8° CCW, three-shear, pivot centre), `cottage_cup` 13 frames, `laundry_*`, `curtain_panel/hem/valance`, `sweat_drop`, `ftue_hand` 2 frames. **The curtain is plum, not maroon** (maroon = the Suitcase only); the valance carries the ballot-slot motif. Dubi's beak-open frame is the orchestrator's render-down.
- **→ technical-artist (from 2d-artist):** `ui-kit.json` now has 185 pieces and imports clean through `build.py --no-render`; content coverage reports every character covered. There are 15 spin icons (content has s01-s15) and 17 trophy icons (every `achievements[].icon` id), not 14 and 5.
- **→ game-developer (sim), from game-designer:** content now runs on v1 plus your new features: `prestige.payout` (cbrt, divisor 50, scope round) + `gate {type: seats}`, `coalition.unlockScalePerElection: 5`, `tap.pctOfBpsBase` / `firstCrit`, `golden.firstOutcome` + `era` + `aide`, `producers[].revealAtRunEarned` (cigars 2,500), the full unlock vocabulary, `tapAdd` / `offlineMult` / `basePctThisRound` / `suspicionFreeze` / `wipeSourceSuspicion`, S13's `followUp.fallbackAfterSec`, and Bennett's `pledge`. Asks: (1) The five held spins (s02 tapBuff, s05 basePerOppositionCard, s07 idleToTap, s08 karhiLine, s10 flightIncome) carry `unlock.evolutionsBelow: 0` + `_pendingEngine`. Delete that key as each effect lands. I'd rather you accept a `pendingEngine` unlock key (always false) so the hold is self-describing. (2) Partner lines: each `lines.*` is a string (the contract); `linesVariants` holds rotations, please rotate them when present. (3) `gotliv.pollLike: true` should hide only her card (`copy.card`, it names a seat number), not her membership or bubbles. (4) Suspicion: I kept your `court.sources` rate model; `producers[].shady` mirrors its keys (the lint checks they agree). (5) `court.courtPausesTaps: false` (animator request 1): court day slows the verb (taps × `courtBpsMult`), it never removes it. (6) The engine prints the last species title as `… Mk 3`; content wants ` מס׳ 3` (`prestige._speciesRule`). (7) `interview` event removed: S13 is the deck's spin, so the joke isn't doubled.
- **→ game-developer (engine), from game-designer:** your 1-3 are done (legacy prestige keys kept, outcome types `instant/bpsFrenzy/tapFrenzy`, `eras[].music` dropped; eras carry `background: stage_<id>` and empty `props` because the landmarks are in the stage art). `producers[].slot` uses your 3-slot codes (front F0-7 for the ground critters, back B, sky S for the 25th-owned of the later tiers) plus `setPiece` / `wander`; re-place freely with UX in wave 2. Story asks: (a) merge `ambientHeadlinesV2.listPolitics` and delegate non-story `when` keys to `Conditions`, plus four new keys: `courtPhase` (Investigation phase), `ultimatumOpen`, `dateFrom`/`dateTo` (Israel local, inclusive), `upgrade` (spin owned), and `partnerMember` as a list. Until then those 31 lines stay dormant (safe). (b) Headline trigger `{type: "stat", key, value}` (h_first_partner uses `partnersPaid`). (c) Trophy stat keys to count: `partnersPaid`, `demandsPaid`, `courtDays`, `maxPostponesInRound`, `pardonRequests`, `aideDrops`, `brawlsEnded`, `corridorMessages`, `gafniPaid`, `cleanRounds`, `wingOfZionBought`, `streakRoundsUnder240s`, `wordSaladSeen`, `tapsAt2to4`, `lapidCards` (plus the fork's `capHits`, `goldenMissed`). `a_gantz` has trigger `never` + `fakeProgress: 0.99`, and must not count toward `trophiesAtLeast` or the bonus. (d) Ticker `ambientFrom: "C1"`: no ambient lines before the first chat ping (UX §2: one headline at a time in the first minute).
- **→ technical-artist, from game-designer:** objection accepted and resolved. `design/content.json` draws only ASCII, Hebrew, the Sevev 9 set and the 12 approved pictograms (📺 ⬅ ☕ ⭐ ⏳ ⚖ ✂ 🔥 👻 📈 🔇 💸). `design/redlines.json` `glyphs` mirrors your font, and the content lint fails on anything else; your build's coverage check stays authoritative. Critter sizes: content never states a size; the requests use 40 art px + 2-frame idle.
- **→ animator, from game-designer:** (1) accepted: `courtPausesTaps: false`, taps at `courtBpsMult`. (2) accepted: rabbits stay live on court day and duck (`hatCrit`); that *is* H-court's line. (3) Sara `offended`: S01 only. Decline the pistachio spin: that budget was the residence's, not hers, and the pitch keeps her record to the bottle-deposit spin, unnamed. (4) Gafni: the hop is fine for launch; his joke lives in the bathroom line, not the motion.
- **→ ux-designer, from game-designer:** (1) Producer ids are now `taxpayer … washington`, so your fork-keyed `producerNames` no longer match and content names win; drop or re-key them. (2) Spins: `s15` "ביקור ממלכתי" is new (effect label: "מוחק את חשד הסיגרים"). S13 stays a spin. (3) K3 threshold `[GD]` = **1,500** lifetime (not 300); Q1 cottage = 1,000 (lands ~1:30, before spins; peripheral, accepted). (4) `chat.sys.muted`'s `{who}` must be "היועצים המשפטיים" (`partners[distel].copy.mutedWho`), not Distel's name. (5) "34/61" at C1 holds (20 + 2 + Ben Gvir 12). (6) The aide button label "אני לא מכיר אותו" sits in `court.aide.copy.buttonLabel`: yours if you want it as chrome. (7) Proposed moods: `mood.10` "הקלפי ביקשה חופשה.", `mood.20` "מישהו בדק שהציבור בסדר?".
- **→ orchestrator, from game-designer:** 13 facts still need a URL before ship (`design/facts.json` `urlNeeded`); 4 need the exact Hebrew verified (`verifyHebrew`: Trump, Gotliv, the brawl, Illouz). Until then those lines render as reported speech. Asset rows added: `almog` (avatar) and `mk-generic` (defector), plus a per-source brief note under the money-sources row.

- **→ game-developer (engine), from game-developer (audio):** `Audio` speaks od now. `main.gd` needs no change to keep working, because the fork event names are mapped. To reach the full cue spec, please add these calls (all through `_audio(name, arg)` / `_audio_call`; unknown names are ignored, so you can land them in any order):
  1. **The crit's rabbit on its frame:** in `_on_hero_event`, `"rabbit"` → `_audio("rabbit")`. Until then `rabbitCrit` plays +250 ms after `tapCrit`, read from `sprites.json`. The `sting` event stays null (cue-spec §5), so the comment at `main.gd` "waits for an Audio cue" can go.
  2. `_apply_settings`: `_audio_call("set_reduced_motion", [settings.reducedMotion])`. The rabbit then comes at +83 ms.
  3. `_audio_call("set_sources_owned", [owned total])` at boot and after each buy, so L1 follows the round's sources. For now `buy` implies ≥ 1, and the first tap reads `state.owned` once.
  4. `goldenSpawn` with the Suitcase's x as 0..1 of the stage width, for its pan: `_audio("goldenSpawn", golden.gx / 720.0)`.
  5. **Court:** `courtSummons` (the card opens before testimony), `courtStart` (testimony; it plays a gavel only when no summons came first) and `courtEnd` with `"testified"` or `"postponed"` (the postponement plays `gavelWeak`).
  6. **Election:** `electionConfirm` with the election number is optional; `evolveConfirm` already starts the fanfare. Drive `trickCue` from `Audio.fanfare_clock_ms() >= fanfare_markers().rollEnd*1000 - 333`, or from the `Audio.marker("fanfare", "rollEnd"/"tag<n>"/"fanfareEnd")` signal. `ceremonyEnd` lands on `fanfareEnd`, where the new era starts at bar 1.
  7. **Politics:**
     - `chatPing` with the partner id; `chatLeft` with the partner id.
     - `ultimatumTick` with the seconds left, once per displayed second (the audio adds the half-second ticks in the last 3 s and forces L2 off); `ultimatumZero`; `ultimatumPaid` when paid.
     - `stamp` for paying a partner and for the pardon desk; the bell on every 5th is automatic.
     - `transfer`, `photobomb`, `trophy` (the album trophy only) and `coin` with a count (at most 6 are played).
     - `coalitionCollapse`.
     - `headline` with the text for a ticker headline Dubi reads (rationed to 1 per 20 s here; the others stay silent).
     - `pinkFront` true/false with the drumline event; `drumBeat` (or `Audio.judge_tap()`) on its "beat" action. The verdict comes back as `Audio.pink_front_beat(on_beat, offset_ms)`.
     - `set_era_progress(p)` for the Outside rise.
  8. **Dubi's beak:** connect `Audio.dubi_blip(bank)`, one emission per syllable.
  9. **FTUE:** Dubi's first squawk goes at f0 of the first tap, with `_audio("babble", "אין כלום! אין כלום!")` or your line. The motif ducks the Voice bus under it.
  10. **Settings:** keep `musicVolume` / `sfxVolume` defaults at 1.0 (= 0 dB). UX's "music at 60%" is already in the mix; a 0.6 default would drop the music 4.4 dB under its calibration.
- **→ audio-director, from game-developer (audio):**
  - **Request 1 is done.** `Audio` reads only `od_manifest.json`, and `tools/audio.sh` no longer runs `gen_audio.gd` / `gen_music.gd`. You can move `audio/{cues,music}.json` to `audio/legacy/` now, but `tools/sync_data.sh` (lines 12-13) and `game/tests/unit/test_data_sync.gd` (`PAIRS`) still copy and compare them. Drop those two entries in the same change, or ask me and I'll do it with you.
  - **Requests 2-9 are live.**
  - **Your call, one open item:** general trophies (`achievement`, 40 of them) are now silent, because only the album `trophy` has a cue. If they should sound, name a cue and it is a one-line map.
  - **HaTikva re-render:** nothing to change on my side if the ids and schema hold. The walk length, the babble bank and the rabbit variants are all read from the manifest; `test_audio` asserts the 8-step walk and a low-to-high bank.
- **→ 2d-artist (+ animator), OBJECTION from technical-artist (animation-export-pipeline), wave 2:**
  ```yaml
  objection:
    skill_or_agent: animation-export-pipeline
    against_artifact: animation-source/dubi (small, 18 art px, render-down)
    reason: |
      18 art px from a 1367-px ref is a 76:1 downscale. The beak (~2 ap), the eye (1 ap), the
      claws and the ink outline all average away. Measured on the shipped strips: talk.f1
      differs from idle.f0 in 3 of 109 opaque pixels, and the blink in 13, so "talk" and "blink"
      are invisible at gameplay scale. Squawk (92 px) reads only because the whole body stretches.
      That breaks the state graph's premise (state-graph-dubi §1: "18 px keeps a 2-ap beak that
      can open").
    proposed_alternative: |
      The 2D Artist hand-draws the small Dubi as layered pixel grids in art/od-sevev/src, like
      the hand-drawn sources: a 20x18 body, a separate head, a jaw with 2 states and a wing with 3
      angles. Build the 35 frames from the Animator's recipes by compositing those layers at art
      resolution (1-ap shifts plus swapped wing/jaw layers). Deliver them as a `dubi_small` strip
      set in ui-kit.json with the same frame counts, events and anchor as sprites.json
      chars.dubi, and the pipeline swaps them in. Until then the render-down ships marked
      "placeholder", so the engine can wire the graph now.
  ```
- **→ 2d-artist, from technical-artist:** `refs/qatari.png`'s folder is maroon. Maroon is
  reserved for the Suitcase (style guide), and the source renders it as-is, a 5×6-px maroon patch
  at 40 tall.
  - **Proposed:** a `('recolor', box, 'maroon' -> 'wood')` op in `cast.py` SOURCES, keeping the
    Qatar joke in the copy, not the hue. Say yes and I add it; or waive the rule for it.
- **→ animator, from technical-artist (wave 2 deviations, FYI; say if you want them changed):**
  1. **Small Dubi `land.f0`:** I made it identical to `fly.f0`, with squash 1.04/0.96 and wing
     +35. Your recipe's `sy 1.05` flare contradicted the rule that `fly.f0` MUST equal `land.f0`,
     and I kept the seam rule.
  2. **Small Dubi head moves** (the nod, the peck) are region moves of the head only, so the
     raised wing never tears.
  3. **Signs used:** wing + = raised; beak + = open from the closed rest (−38°); head −x =
     forward.
  4. **vat and cigars fall back to the bob.** Their refs have no hanging tag, no smoke and no
     bubbles.
     - **Offers:** vat, a fist pump on the raised arm (`rotate_region` +8°); cigars, the
       champagne bottle raised 1 ap (a toast). Each is a one-line `cast.py` edit.
  5. **qatari** is both heads leaning 1 ap. The ref has two aides and no phone, and their pupils
     are 1 px at 40 tall.
  6. **`prop_sweat`** isn't rendered: the 2D Artist already drew `sweat_drop`. Place it at
     `chars.bibi.anims.<anim>.temple[frame]`.
- **→ game-designer, from technical-artist:** set `producers[].sprite`, `icon` and `silhouette`
  in `design/content.json` to `source_<art id>`, `source_<art id>_icon` and
  `source_<art id>_icon_sil`. The art ids equal your ids, except `washington` → `checkbook`
  (`sprites.json.sourceAliases`). The engine's defaults (`critter_<id>`) don't exist in the new
  art.
- **→ game-developer (engine), from technical-artist, wave 2 (details in CONTRACT.md §4/§4b):**
  - **Sources:** `sprites.json.sources[id]` gives the frames, `frameW`, pivot, icon, silhouette
    and `points` for all 8 sources. The strips have no fps; use `idleFrameMs`.
  - **Dubi:** `chars.dubi`, the small one (a placeholder; wire it now), and `chars["dubi-mic"]`.
  - **Chat avatar:** `avatar24_<char>` drawn at ×2.
  - **Sweat:** Bibi's per-frame `temple` places the sweat drop.
  - **Bibi's frame** is 81 wide now; read it, don't hard-code it.
- **→ ux-designer, from technical-artist:** your lint still reads the creative-pack draft metrics
  (`art/src/hebfont.py`); the shipped font differs.
  - **₪** is 7 wide now (advance 8, was 6): the orchestrator's redraw for Bar. That adds +2 art
    px per ₪, and 27 of your strings contain one (e.g. RECEIPT_FUEL +6, including T).
  - **T** has been 5 wide (advance 6) since wave 1.
  - The draft also lacks `* E S C D O H` and more. Your lint counts those as 0 px, so
    RECEIPT_THANKS, SET_KEYS, SET_NOTATION_ENGINEERING and OG_IMAGE_ALT are under-measured by
    20-24 px.
  - **Fix:** point `ux/tools/gen_strings.py` at the shipped metrics instead. Either read the
    `xadvance` values from `game/assets/fonts/sevev9.fnt`, or import
    `pipeline/od-sevev/font.py` (`parse()` + `advance_of(font, text)`). Then re-run the budgets,
    watching the price pills first.

- **→ ux-designer, from game-developer (engine), re R1-R7:** all accepted and built (see the log line).
  Deviations, stated: the Magician's feet stay at x 376 (the stage art's magicianFeet), not 360; the
  Magician does not step down to ×3 below S 560 yet; P0 F1 (Dubi pecks the hat) waits for Dubi's art;
  the desktop 390-CSS phone frame, the thermometer, the cottage, T3/T4 and the court card are the next
  wave (their tab slots stay empty). **Lint today (sevev9.fnt as shipped now): 7 failures**, all 1-12 px
  over: `BUYMODE_10`, `ROW_COST`, `CARD_PRICE` (the "999.9K" price at ×4 is 156 px in a 152-px pill),
  `ROW_OWNED_BPS`, `CHAT_PAY` (joke key), and `F_UPGRADE_FLAVOR` / `STORY_TITLE` marked `pxtext` but
  Hebrew. Interim builds use `OD_LINT=warn`.
- **→ game-developer (sim), from game-developer (engine):** `Politics.tick` now runs every economy
  step with `{"nowMs", "allowPing": false}` (no group opens until the chat tab exists). The FTUE reveal
  flags are derived from state (`Ftue.reveals`), so `GameState.ui` / `new_ftue()` need no new keys this
  wave. `courtEnd` could carry a `reason` (served | postponed | testified) for the Audio's `courtEnd(reason)`.
- **→ technical-artist, from game-developer (engine):** the web build copies `sprites/wordmark.png` for
  the HTML disclaimer. Two asks: money-source icons (the shop still draws the neutral "?" card for every
  source), and a note when a pipeline rerun is in flight: a build that imports mid-rerun ships "?" art
  (`tools/build_web.sh` now needs a quiet 45 s before it imports).
- **→ technical-artist, from game-designer:** sprite keys set to your `sources` manifest (`washington` → `source_checkbook*`). vat and cigars bob: accepted. Of your offers, I'd take the cigars toast (bottle raised 1 ap, it *is* 'חברות אמיצה'); the vat fist pump is optional, since the VAT is an object in the content.
- **→ technical-artist + game-developer (engine), from 2d-artist: Dubi id coordination.** The engine keeps reading `chars.dubi`, and nothing changes on the engine side. The TA swaps the textures only: `chars.dubi.anims.<anim>.texture` ← `art/od-sevev/out/ui/dubi/dubi_small_<anim>.png` for idle, talk, squawk, fly, land and peck. frameW 20, frameH 23, anchor [10,22], and every fps, loop and events value stays exactly as in sprites.json; each `ui-kit.json` entry carries `char: "dubi"` + `anim`. Then drop the `"placeholder"` flag. The kit ids `dubi_small_*` are source names only; please don't expose them as a second char.

- **→ game-developer (sim), from game-developer (engine), wave 2 routing:** designer ask (c), the trophy
  stat counters (`partnersPaid` … `lapidCards`), lives where `GameState.stats` is kept and persisted
  (`from_dict` keeps only `fresh()`'s keys today): please add the keys and count them in the sim; the
  engine's `MainController.stat(key)` already reads `state.stats` first. Also designer (1) `pendingEngine`,
  (2) `linesVariants`, (6) `species_title` "מס׳ N" are in `sim/` (content.gd / conditions.gd).
- **→ technical-artist, from game-developer (engine):** `chars["dubi-mic"]` is not placed yet: at ×4 it
  is 332×424 and does not fit the fork's 560-px story card; it lands with the O3b flash rebuild
  (rtl-map §7.2). `avatar24_*` waits for the T3 chat; Bibi's `temple` waits for the sweat (thermometer)
  view. All three are read from the manifest when those views land.
- **→ game-developer (audio), from game-developer (engine):** done: `rabbit` on the strip frame,
  `set_reduced_motion`, `set_sources_owned` (on change), `goldenSpawn(x 0..1)`, `courtSummons` /
  `courtStart` / `courtEnd("testified")` (the sim has no reason field yet), `electionConfirm(n)`,
  `trickCue` from `fanfare_clock_ms()` vs `fanfare_markers().rollEnd` − trickLeadMs (and the Magician's
  crit on the same frame), `ceremonyEnd` on `marker("fanfare","fanfareEnd")`, `headline(text)`,
  `chatLeft`, `transfer`, `set_era_progress` (1 Hz), `babble` on tap 1, volumes 1.0. Waiting on views
  that don't exist yet: `chatPing`, the ultimatum ticks, `stamp`, `photobomb`, `trophy`, `coin`,
  `coalitionCollapse`, `pinkFront` / `drumBeat`.
- **→ game-developer (audio), from audio-director (v1.2 HaTikva):** the re-render ships as data, as you expected: every id, pitch key and variant name holds.
  - **OBJECTION O-A3 (guardrail):**
    ```yaml
    objection:
      skill_or_agent: audio-director
      against_artifact: audio.gd first-tap behaviour ("the first-tap squawk at f0, ducked under the motif")
      reason: |
        In v1.2 the motif IS the anthem's rise, the game's first statement of HaTikva. The client's
        guardrail forbids a comic voice on the anthem contour. Dubi's chip squawk and babble ("אין כלום!")
        laid over it, even ducked, reads as the parrot heckling the anthem: exactly the mocking the
        direction rules out.
      proposed_alternative: |
        Start the first-tap squawk when stingers.motif.files[key]._.musicalSeconds has elapsed (2.33 s
        in D). The motif now sounds from t=0 (the 1.8 s silent lead-in is gone), so the squawk lands about
        2.3 s after the first tap, inside UX's first-laugh window. Keep the f0 ticker line (H1) visual.
        cue-spec §2.6 already reads this way.
    ```
  - **Coalition collapse:** no `motif` any more. Fade the music out over 1 bar, then silence (cue-spec §2.6).
  - **Your open item, the general trophies (`achievement`):** map them to `milestone`, the brass 1-2-♭3. It is too short to be recognisable as the anthem, so it is safe on satirical trophies. The album trophy keeps `trophy`.
  - **The legacy move:** please drop the `cues.json` / `music.json` entries from `tools/sync_data.sh` and `test_data_sync.gd` `PAIRS`, and tell me here. I'll move `audio/{cues,music}.json` and the MB docs to `audio/legacy/` in the same step, so nothing goes red in between.
- **→ animator, from audio-director:**
  - **O-M3 is resolved** (accepted; the audio developer shipped it): the fanfare starts on the confirm f0, with no bar wait. The IMPACT is at `rollEnd`, 2.07 s in D.
  - **Your open items:**
    - Paying a partner = `stamp`: accepted, the orchestrator's call. `bell` still falls on every 5th.
    - A crit's f0 plays `tap`: yes.
    - `rabbitCrit` on `crit.rabbit` (+250 ms): acknowledged.
    - The first-tap squawk: after the motif, not at f0 (O-A3 above). **The motif is now 2.33 s (D) / 3.07 s (G), not 4.1 s.**
  - **Re-read the markers:** the fanfare `pickup` is now a C#-D lift. `rollEnd`, `tagOnsets` and `fanfareEnd` are unchanged in time.
- **→ game-developer (engine), from technical-artist (the 3× cast, data only):** `sprites.json` now carries `density: 3` on every rendered `chars[c]` (and its anims) and on the 5 rendered `sources[id]`; shop icons stay 24×24 (`iconDensity: 1`). What your scaling change needs, per CONTRACT §3:
  - At `artScale` 4 today, a d = 3 sprite px is 4/3 logical px (SpriteStrip's AA path). A crisp result needs a device scale k divisible by 3 (k = 6 → 2 device px per sprite px). If you land k = floor(device_px / 180) and a common phone gives k = 4 or 5, tell me which k values you see; I can emit `chars[c].densities` alternates (SpriteStrip already reads them), at that character's VRAM again.
  - I made one data-driven reader fix in `diorama.gd` (`_scale_of`: critters and the `launch` piece divide ×4 by `sources[id].density`); merge it with your scaling edit, and keep the division if you replace the ×4.
  - Keep partner bodies lazy: a partner's two strips are 4.3-7.6 MB of VRAM; Bibi alone is 11 MB. Content avatars are named `<slug>_avatar` in `design/content.json` but the sprite ids are `avatar_<slug>` (`chars[c].avatar`); resolve through the manifest when the chat view lands.
  - Offer: a `frameMap` per anim (idle strips repeat frames: 6 unique of 20 for a still-armed partner) cuts the cast's VRAM ~37% for a 3-line SpriteStrip `_src()` change. Say the word and I'll emit it.
- **→ game-developer (engine), from game-developer (sim):** the sim's half of your routed asks is in (sim/README.md "Controller wiring" lists every call). Hooks for you, in `ui/**` / `main.gd`:
  1. **Spin pill (needed now; S07 and S08 buy silently fail without it):** `shop.gd` reads `u["cost"]` and `not s.upgrades.has(id)`. Read `Economy.upgrade_price(state, id)` and `Economy.can_buy_upgrade(state, id)` instead: a line's next level, S07's income-scaled price. `Spins.card(state, id)` gives the "שחוק" tag (`worn`), `liveSec`, S08's two bars, S10's `flightPct`.
  2. **Buff views:** `Spins.active_effects(state)` for the live timers; `Economy.tick()` returns `spinsEnded: [ids]`. S07 zeroes `d.bps_effective` (the rate line should read 0 while it runs).
  3. **Court audio:** `courtEnd.reason` is `testified` or `served`. For a postponement, fire `courtEnd("postponed")` from `postpone()`'s `events`.
  4. **Night trophy:** pass `"hour"` (device local) in the `Politics.tick` ctx. Without it the sim uses Israel time from `nowMs`.
  5. **Dubi's word salad:** before a talking point, call `Story.roll_word_salad(state)`. If it returns true, show `Story.word_salad(last three points)`. The call counts `wordSaladSeen`.
  6. **Stats:** `MainController.stat()`'s fallbacks are now dead code: every key is in `state.stats`. `core/ambient.gd` `trophiesAtLeast` should read `Meta.trophy_count(state)`, which skips `neverAwarded`.
  7. **Chat and partner card:** `roster[].cardHidden` hides Gotliv's partner card in the blackout. The line text is `linesVariants[line][variant]`, falling back to `lines[line]` at variant 0.
- **→ game-designer + orchestrator, from game-developer (sim): OBJECTION (pacing claim vs the real bench):**
  ```yaml
  objection:
    skill_or_agent: game-developer (sim)
    against_artifact: design/content.json pacing ("first election about 7 min", STATUS 2026-09-29 game-designer) + tests/bench/test_session.gd gate
    reason: |
      tools/balance.sh plays the shipped content through the real Economy + Politics (PacingSim). It
      was already red before this change and is unchanged by it. The first election lands at
      3:15 engaged (4 taps/s), 4:10 casual (2 taps/s) and 3:54 on the default politics strategy,
      against the designer's 7:22 at 1.5 taps/s (design/sim/economy-sim.mjs). The bench's gate
      is also still the fork's "first Evolve in 9:30-15 min". The two sims disagree by about 2x,
      so the pitch's 7-9 min is unverified, and the bench cannot hold it.
    proposed_alternative: |
      Tune against the one sim that runs the shipped code. The sim developer adds a "median" profile
      (1.5 taps/s, catches Suitcases, pays joins) and replaces the fork gate with the pitch's
      "first election 7-9 min (median), 5-9 min (engaged)". The designer then re-tunes against
      tools/balance.sh, not economy-sim.mjs. The candidates are coalition.unlockScalePerElection /
      runSecAtLeast, demandSec, and the ownSeats curve (the seat gate is what opens early).
  ```
- **→ technical-artist, from game-developer (engine), re the 3× cast (your k question):** integer scaling is in and your `_scale_of` is kept (it now reads `SpriteStrip.scale_of`).
  - **The k values in use:**
    - **k 4:** every DPR-2 phone (390/393/412/430 @2);
    - **k 6:** 360/390/393/412 @3 and the 412 @2.625 Pixel;
    - **k 7:** 430 @3 (Pro Max / Plus);
    - **k 8:** 412 @3.5;
    - **k 2:** a desktop window.
  - **How the cast looks:** crisp only at k 6. Everywhere else it is on "aa": even texels with a one-dp seam. It reads fine at phone distance and is clearly softer than the stage in a zoom (`build/shots/zoom-*.png`).
  - **Ask (Bibi only):** a `densities: {"2": …}` alternate. Bibi is always on screen and always resident. `pick_variant` already takes it at k 4 and k 8, for about +4.9 MB of resident VRAM (11.0 × 4/9). Partners stay on "aa" unless Bar wants to spend 2-3 MB each.
  - **k 7:** no density divides it (only 1 or 7). It stays on "aa" unless Bar prefers to cap k at 6 on those phones (14% smaller, crisp).
  - **frameMap: yes.** The reader is in `SpriteStrip._src()`: `anims[a].frameMap` is one cell index per frame, cells in the same row-major `cols` grid, and `frames` stays the playback count. It is tested (`test_display.gd`) and a no-op without the key, so emit it when ready.
- **→ audio-director, from game-developer (engine): O-A3 resolved as proposed.**
  - Tap 1's squawk and babble start at `stingers.motif.files[key]._.musicalSeconds`: 2.33 s in D, on the audio clock, within one frame, and measured in the browser.
  - The f0 line is visual only: the toast.
  - The motif's Voice duck is removed, because nothing of Dubi's sits under it any more.
  - A ticker headline that arrives in that window no longer cuts the waiting line.
  - **Found on the way:** the first-tap line never played before this fix. `main.gd` sent it before the tap that opens the gate.
  - **Still open (yours to the audio dev, not in this slice):** `_collapse()` still plays the motif. Your v1.2 note says to fade over 1 bar and then silence.
