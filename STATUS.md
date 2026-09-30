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
- 2026-09-29 · game-designer · **sources before ship**: all 13 shipping facts now have URLs (9 verified, 4 corrected: gotliv not formally a defector, brawl on 18 Jan not 19, bibist was a creators' skit Netanyahu posted, cottage source re-dated). Quote Hebrew: Trump (as N12 reported it) and Gotliv verified; the brawl's Netanyahu line and Illouz unverified, both already reported speech. No in-game copy changed. The About page (which renders `facts.json` `text`) now has source links and the corrected texts, and Gotliv's "covert officer" guardrail moved out of the public `text`. 1 objection (brawl `script[6]` → "צאו החוצה ותמשיכו להתווכח שם."). Checked through search results only (the sandbox blocks page fetches), so a human should open each `url` once before ship. Content lint 0 errors, and the URL-needed warnings are gone · `design/facts.json`, `design/facts-verification.md`
- 2026-09-29 · game-developer (engine), wave 3 · the sim hooks, the audio asks, `view_rules.gd`, the ticker anchor. **Closed:** sim → engine asks 1, 2, 4, 6 (3 and 5 were already in or stay open, below); audio-director's collapse, `achievement` and legacy-move items; views dev (T3) item 3; O-A3's leftover "collapse still plays the motif".
  - **Spin pill:** `Shop.spin_card()` reads `Spins.card` + `Economy.can_buy_upgrade`, so the price is `Economy.upgrade_price`: S07's costBpsSeconds price, S08's next level. Gold only when the sim would sell, so a tap never does nothing silently. A line level-up keeps the card: a flash and a hop, no pop-out or reflow.
  - **Card extras and buff views:** the plate's bottom stamp shows "שחוק" (worn) or a line's "1/5". S08's two bars are one 2-art-px split track under line 2 (public from the right). The buff chip shows the live spin that ends first (`SPIN_ACTIVE`, the timer bar, the last-3 s blink); a Suitcase frenzy still wins it. The rate line reads 0 while S07 pours. S10 shows a "+15%" floater on each flight catch. S08's ticker line is its level's own `flavor`.
  - **Also wired:** `Politics.tick` gets `hour` + `weekday` (device local). Ambient `trophiesAtLeast` = `Meta.trophy_count`. `view_rules.gd` compiles (`earned: bool`).
  - **Audio:** `_collapse()` fades the bed over 1 bar with no stinger. `achievement` → `milestone`; `trophy` stays the album's.
  - **Legacy move, done in one step:** `sync_data.sh` and `test_data_sync` `PAIRS` dropped `cues`/`music`. `audio/{cues,music}.json`, `audio-cue-spec.md`, `mix-bus-topology.md`, `sonic-brief.md`, `preview.html` and their two tools are now in `audio/legacy/`; `game/data/{cues,music}.json` are deleted (nothing read them). A new test pins it.
  - **Ticker (rtl-map §5.1):** the plate grows to hug the measured "מבזק" (text right at x 700), Dubi's whole frame stands 4 px left of it, and the crawl ends 4 px before Dubi (`Ticker.anchor_layout`). At ×4: plate 604-708, Dubi 520-600, crawl 192-516. Objection to UX below. **The band under the stage is intended:** it is the Suitcase lane (§4.1, S−116…S−4), drawn with the stage art's flat floor, empty until 2 sources are owned. It is not integer-scaling padding (the extra height goes to `padTop`).
  - **Checks:** `tools/test.sh` **186/186** (+9 `test_spin_card`, +2 `test_ticker_anchor`, +1 `test_audio`, +1 `test_data_sync`), no SCRIPT ERROR. The strict `tools/build_web.sh` is green (lint 499/0).
  - **Chromium, 390×844 @2 (`?dev=1&grant=100000&evo=1`):** S08 bought by touch. Pill 60.0K gold "0/5" → 600K "1/5", bar 80/20. `res_web.mjs` @2 and @3 passes; @3 needed a rerun, because a 967 ms SwiftShader frame put O-A3's check 1 ms over its one-frame tolerance. 0 page errors.
  - **Still open for the engine:** sim ask 5 (Dubi's word salad); `spinsEnded` has no view beyond the chip leaving.
  - **Files:** `game/scripts/{main,ui/shop,ui/buff_views,ui/ticker,ui/layout,core/ambient,ui/views/view_rules,autoload/audio}.gd`, `game/tests/unit/{test_spin_card,test_ticker_anchor}.gd` (new), `test_{audio,data_sync}.gd`, `tools/{sync_data,audio}.sh`, `audio/legacy/` (moved), `audio/od/cue-spec.md` (one line), `ux/screen-graph.md` (a path), `HOW-TO-RUN.md`.
- 2026-09-29 · game-developer (views B) · **O3b Dubi's news flash, the cottage cup, the desktop phone frame** (rtl-map §2, §7.2, §1; first-minute §1.3).
  - **Flash** (`ui/views/view_flash.gd`, `FlashCard`; `Overlays.StoryOverlay` is now a subclass, so every caller gets it; `main.show_flash(n, archive)`): the kit `sheet_modal`, the beat title in its band, a "news screen" (the round's stage art cropped behind `chars["dubi-mic"]`, feet under a lower third: `ticker_bar` + red `ticker_flash_plate` with HEADLINE_TITLE + TITLE_ROUND), the beat lines (modal.body 560, staggered in), FLASH_NEXT over FLASH_SKIP (§7.1 stacked; back/backdrop = skip; an archive replay has SYS_CLOSE only). Dubi is at an integer art scale read from the manifest: the largest of ×4/×3/×2 that fits the visible band and makes a sprite px whole device px (k 4 → ×3, k 6 → ×4, k 8 → ×3; k 2/7 → the largest that fits, "aa"). Beak: talk.f1 60 ms per Audio `dubi_blip`, idle 250 ms after. Audio: `storyCard` + `babble(lines shown)` sent by the card when it is on screen.
  - **Word salad:** every Dubi talking point shown (his quoted beat line, and every `Toasts.say` squawk via a `dubi_line` hook) goes through `FlashCard.dubi_says` → `Story.roll_word_salad` (counts `wordSaladSeen`) → `Story.word_salad(last three points)`. Archive replays do not roll. No sim change.
  - **Cottage** (`ui/views/view_cottage.gd`, in `_top`): hit 88×88 at (624, 4), kit cup ×4 at (636, 12), frame = `ViewRules.cottage_frame`, hidden until Q1; 50% at rest, 100% for 3 s on appear / pixel loss / tap; motion cottage-pixel-loss (pixel particle from the diffed hole, "−1", RM variant); Audio `cottagePixel` (unassigned, silent). Tap → HUD_COTTAGE_TIP toast (one per 4 s).
  - **Phone frame** (`game/web/shell.html`): the shell owns the canvas (`canvasResizePolicy` 0, `odFit`): a phone keeps the whole window; a window ≥ 600 CSS with a fine pointer gets a centred 390 × min(844, h − 48) CSS canvas in a bezel. Backing store = CSS × DPR exactly, box on whole device px, so display.gd's k holds (1440×900 @1 → k 2, @1.25 → 2, @1.5 → 3, @2 → 4). `?frame=1|0` forces it; `window.odFrame`; `mbSafeArea` is 0 inside the frame.
  - **→ ux-designer:** new key `HUD_COTTAGE_MINUS` "−1" (pxtext, new box `rowA.cottageMinus` 88) added in `ux/tools/gen_strings.py` and regenerated (lint 0). Please confirm or replace. Also seen in the shots, not mine: the toast's right-aligned text touches the toast plate's right accent stripe.
  - **→ game-developer (engine/dossier), FYI:** `view_rules.gd` did not compile (`var earned :=` untyped inference in `trophy_model`); fixed to `var earned: bool =`. `ViewRules.frame_sides` (in-engine side panels) is unused: the frame is the shell's. T4 can replay a flash with `show_flash(n, true)`.
  - **Deviation:** the task named the Audio's `headline(text)`; the card uses `babble(text)`, the Audio's flash kind (after the dubiFlash head, a 'down' squawk). `headline` is the ticker's kind, rationed to 1 per 20 s with an 'up' squawk, so a flash right after a milestone headline would be mute.
  - **Checks:** `tools/test.sh` 186/186 (+13: `test_flash_view` 8, `test_cottage_view` 3, `test_phone_frame` 2); strict `tools/build_web.sh` green (lint 500 strings, 0 failures). Browser (`node tools/web/views_web.mjs <url> <dir>`): 390×844 @2/@3 and 1440×900 @1/@2, flash open (×3/×4/×4/×3), dubiFlash played, FLASH_NEXT closes, cup tip, frame on/off, canvas 1:1 on whole device px, 0 page errors. `res_web.mjs` knows the frame; its O-A3 timing check is SwiftShader-noisy (one 2.463 s run, then 2.370 / 2.367 s passes).
- 2026-09-29 · game-developer (views) · the investigation cluster: T4 dossier, suspicion thermometer + sweat, O2 court card + ticker chip, O15 pardon desk, aide-drop confirm. `courtStart` / `courtEnd(reason)` reach the Audio with the sim's reason; `courtEnd("postponed")` is routed from `postpone()`'s events on the "נדחה" stamp's impact (+90 ms; f0 under reduced motion).
  - **Thermometer:** the kit's tube geometry comes from `sprites.json ui.thermo_tube.liquid/pivot`. It shows the floor hatch, fill, meniscus, the magnifier → gavel icon swap and bubbles, and the word `HUD_SUSP*`. Tap → T4. The sweat is `sweat_drop` on Bibi's per-frame `temple`, through `SpriteStrip.point` (artScale/density from the manifest), per the Animator's magician-sweat graph, including the summons gulp and the reduced-motion bead.
  - **T4:** the stat rows `DOS_*`, the aide row, `PARDON_ROW` (O15 desk: `Investigation.request_pardon`, paper stamps, the `stamp` cue on the impact), `BOOK_STORY` (the fork's book on its story page), and `BOOK_TROPHIES` with the kit's `trophy_plate_*` / `trophy_<icon>` art. K2 is derived from state: the slot appears 5 s after the case opens, with `TOAST_DOSSIER`. T3 and T4 are one layer.
  - **Court card:** it is bottom-anchored on the tab bar and flows by line count. Its buttons call `Investigation.postpone` / `testify` / the aide confirm → `drop_aide`. It collapses into the ticker chip (`Ticker.set_court_chip`, the clip starts after it). The court tint is steady at 0.18. H-court pre-empts the ticker. The tap-burst guard holds the card 1 s.
  - **main.gd hooks:** build, relayout, reduced motion, per-frame updates, input routing, Esc/back, slot 4, the `stage_unobstructed` guard, and a zero-cost `audio_sent` signal for tests. The dev params `&susp=N` / `&aide=N` are documented in HOW-TO-RUN.
  - **Tests:** `tools/test.sh` 185/185 (+`test_court_view.gd` 7, +`test_dossier_view.gd` 5); strict `tools/build_web.sh` green (lint 499 strings, 0 failures). The web build was driven by touch at 390×844 @2 and @3 with 0 page errors.
  - **Files:** `game/scripts/ui/views/{view_thermo,view_dossier,view_court}.gd`, `game/scripts/{main,ui/shop,ui/ticker}.gd`, `game/tests/unit/{test_court_view,test_dossier_view}.gd`, `HOW-TO-RUN.md`.
  - **Deviations, stated:**
    - The card text flows by real line count: `COURT_BODY` wraps to 2 lines at 624, so the fixed y 96/140/184 would collide.
    - The court chip grows past 212 when its title needs it (`COURT_CHIP_TITLE` is 160 px beside the 36-px gavel).
    - The excuse reveals as the previous step, then the full line with the 1-ap hop, not sentence by sentence (a wrapped paragraph).
    - `SHARE_RECEIPT_TITLE` / `SHARE_RESULT_BTN` show only once the controller has `open_receipt` / `open_result_card` (O4/O5 are not built).
    - The aide button lives on the summons card and in T4 (no spec named a home).
    - The pardon desk uses the `_paper` stamps (it is a paper modal); the court card uses `_dark`.
  - **Open:**
    - **→ 2d-artist:** `thermo_tube_short` (S < 560) is still missing. The full tube is drawn there.
    - **→ game-developer (engine):** the Magician's court-day body graph (exit / zip / hat prop, state-graph-magician §5) and the `court_window` stage echo are not wired.
    - **Every modal's scrim is invisible:** `overlay.gd` creates it with colour alpha 0 and animates only `modulate`. This is queued as a separate task.
    - **No new strings.**
- 2026-09-29 · technical-artist · **Bibi's d 2 alternate + the frameMap** (the engine's two asks; data only, no `game/scripts/**` change):
  - **d 2 Bibi:** `chars.bibi.densities["2"]` in exactly the shape `pick_variant` merges: `frameW` 135, `frameH` 218, `anchor` [80, 217], `density` 2, and `anims` idle/tap/crit → `cast/bibi_{idle,tap,crit}_d2.png`. It is a first-generation render from the ref at 192 px (the showcase `magician(d)`), not a resample. Its `hatMouth` and `temple` come from its own geometry and agree with the d 3 to ≤ 0.5 art px from the feet; `frames`, `fps`, `loop` and `events` are identical (the pipeline fails otherwise). The d 3 render is unchanged: 0 drift.
    - **What it gets:** k 2, 4 and 8 draw it: every DPR-2 phone is crisp at 2 dp per sprite px. k 7 stays on "aa".
    - **VRAM: none added.** SpriteStrip loads only the picked render, so a device holds 4.4 MB (d 2) *or* 9.7 MB (d 3) of Bibi, not +4.9 MB. It costs download only: +106 KB `.pck`.
  - **frameMap shipped** where it shrinks a texture: 36 anims, including Bibi's tap (8 → 7 cells) and crit (14 → 10) at both densities. A still-armed idle is 6 cells of 20. Grids now hold the fewest cells within 2048 (Lapid's idle 7×3 → 5×4). Every frame is read back through its cell and must match the render pixel for pixel.
    - **Cast VRAM:** 150.2 → 105.0 MB (−30%, the dedupe floor; my earlier 37% was the idle strips alone), 109.3 MB with the d 2.
    - **Resident:** 11.9 MB at k 6/7 (was 13.2), 6.5 MB at k 2/4/8. A partner on demand is 1.8-7.0 MB (median 4.5, was 6.1).
    - **Web `.pck` art:** 3.30 → 3.12 MB.
  - **Checks:** `tools/test.sh` 173 passed, 0 failed; strict `tools/build_web.sh` green.
    - **Chromium, 390×844:** at @2 (k 4) Bibi is the d 2 render, at @3 (k 6) the d 3. At both, 100% of Bibi's opaque device px equal their texel at 2 dp per sprite px (template-matched per frame; one match is crit f12 through frameMap cell 9), and every 2×2 block is uniform.
    - **Animation at k 4, streamed:** tap = the hat hops and coins leave the hat mouth; crit = coins, the rabbit rises from the hat on its `rabbit` event (the `rabbitCrit` cue fires), the wink, back to idle.
    - **Proof:** `pipeline/od-sevev/proofs/stage-x4-bibi-d2.png`.
  - **Test touch (flagged):** `test_display.gd` pinned the old data ("k 4 = d 3 on aa"; the shipped idle has no frameMap). It now expects the d 2 at k 4 and tests the aa path at k 7; `_d1_manifest` drops `densities`/`frameMap`; a new check asserts every shipped frameMap fits its grid and texture.
  - **→ game-developer (engine):**
    - `HOW-TO-RUN.md`'s k table still says the cast is "aa" at k 4: Bibi is crisp there now, the partners are not.
    - The partner card (`view_chat.gd` `PartnerCard.build`) sizes from `chars[slug].density` and `frameH`, not from the picked variant: fine today (no partner has an alternate), wrong the day one does. Read `_strip.density` / `_strip.frame_size()` instead.
  - **Files:** creative-pack `art/showcase/src/build.py` (`magician(d)` + `ALT_DENSITIES`), `art/showcase/out/{bibi_*_d2.png,atlas.json}`; `pipeline/od-sevev/{sprites.py,build.py,README.md,budget.json,proofs/*}`; `game/assets/sprites/**` + `CONTRACT.md` §1, §3, §4, §7; `game/tests/unit/test_display.gd`
- 2026-09-29 · game-designer · **resolved the sim developer's pacing objection** (its alternative, accepted by the orchestrator). The pacing check is now only `tools/balance.sh`; `design/sim/economy-sim.mjs` is retired as non-authoritative.
  - **Bench:** a `median` profile (1.5 taps/s). The fork's "first Evolve 9:30-15" gate is replaced by the pitch's gates S0-S7 + Q3, each with its source line, in `design/progression-curve.md` §0.
  - **Bench clock fix:** a purchase frame ticked the economy without advancing `t`, so bench times ran about 5% short of play time. Also fixed `fmt_t`, which printed 179.75 s as "2:00".
  - **First election (seed 7), before → after:** median 5:00 → 8:01 · engaged 3:15 → 7:28 · casual 4:10 → 7:35 · idle 7:44 → 10:07. Median rounds 2-5: 4:30, 5:37, 4:05, 4:50 (was 1:30-2:36). Seeds 1-9 put the median at 7:34-8:25.
  - **Content (tuning fields only):**
    - `ownSeats` 20/2/36 → 21/1/28 (C1 still 34/61).
    - The 8 late partners' `runBananasAtLeast` ×4.9-49.5: goldknopf 16K → 225K … almog 80K → 562.5K.
    - New `runSecAtLeast` 240-420 on the late partners, plus `unlockTimeScalePerElection` 0.9.
  - **Checks:** `tools/balance.sh` 5/0 (G1-G4 still pass). `tools/test.sh` 167/1 (the known `test_input.gd::test_buy_a_producer_by_touch`). Content lint and `Politics.validate()` 0 errors.
  - **Open finding:** the clean route's first round is 21:19 (the default's is 7:21), against pitch §10.3's "about 40% slower". It was already 2.3× before this change, and no gate covers it.
  - **Files:** `design/content.json` (+ `game/data/`), `design/progression-curve.md` §0, `design/sim/economy-sim.mjs` (retired banner), `game/scripts/sim/pacing_sim.gd`, `game/tests/bench/test_session.gd`
- 2026-09-30 · orchestrator (studio) · session 4 stopped by Bar: four wave-A slices (2D Artist+TA; Game Developer ceremony+settings; UX+Dev pre-tap; UX+Dev pane) checkpointed as `handoff-wip/*.commits.patch`, not merged; lock released · `HANDOFF.md`, `HANDOFF-LIVE.md`, `handoff-wip/`
- 2026-09-30 · 2D Artist · A1: the plaza and the lane redrawn as one Jerusalem-stone paving per era (`wave5.Paving`): random-length slabs in 2-3 tones, short broken mortar joints (never black), chisel flecks, big stones, far-apart repairs; the ink press cable (the "worms" and the black line above the ticker) is gone; plaza 128x96 → 192x192, lane 32x28 → 192x28; +0.47 MB VRAM, +10 KB .pck · `art/od-sevev/src/{wave5,wave7}.py`, `art/od-sevev/out/ui/stage/{lane,plaza}_*.png`, `art/od-sevev/ui-kit.json`, `art/od-sevev/proofs/kit-w{2-stage-ceremony,7-mobile}.png`, `game/assets/sprites/{lane,plaza}_*.png`, `game/assets/sprites/sprites.json`, `pipeline/od-sevev/budget.json`
- 2026-09-30 · 2D Artist · B13: `booth_frame` (and `booth_frame_tall`) redrawn as a kraft cardboard folding screen: a printed flag-blue band on the back panel, lower wings with creases, the back panel opaque behind the grid, a shelf; same size, 9-slice and content box (no engine change) · `art/od-sevev/src/{wave8,wave10}.py`, `art/od-sevev/out/ui/picker/booth_frame{,_tall}.png`, `game/assets/sprites/booth_frame{,_tall}.png`, `art/od-sevev/proofs/kit-w10-review2.png`
- 2026-09-30 · 2D Artist · docs + shots: style guide §17.4 (the paving and booth rules with contrast figures), §2.4 updated; after-shots at 390x844@3 and 375x667@2 plus a before/after sheet; `tools/test.sh` 393/393, strict `tools/build_web.sh` green, `mobile_web.mjs` PASS on both phones · `art/od-sevev/style-guide.md`, `ux/manual-test-2026-09-30/fixes/art-*.png`
- 2026-09-30 · Game Developer (pane) · D19 the ticker strip is never empty: root cause = the pager rolled an empty page in when nothing was queued, and the first minute never refills it (`ambientFrom: "C1"`); now a one-page headline holds (≤ 15 s), a multi-page one, an FTUE line or a spent hold roll to the standing line `TICKER_IDLE` "מהדורה מיוחדת" (also the row before its first headline); `test_ticker_idle.gd` samples every frame; `mobile_web.mjs` checks the strip at card 1 / bought / C1 via `odDev.ticker` · `game/scripts/ui/ticker.gd`, `game/scripts/ui/dev_probe.gd` (one line), `game/tests/unit/test_ticker_idle.gd`, `tools/web/mobile_web.mjs`, `ux/tools/gen_strings.py` (+ generated `ux/ui-strings.json`, `ux/string-budgets.json`, `game/data/ui-strings.json`)
- 2026-09-30 · Game Developer (pane) · D20 the white field is a ruled margin: a flag-blue 1-art rule on each canvas edge + 3 art of white, the cards keep their 4-art gutter (the `mobile_web` width rule unchanged, commented), the scroll thumb rides the left rule and hides when idle; D21 the tab bar is always four slots: the kit plate from its divider-free column, three engine dividers on the slot boundaries, an unrevealed slot draws its icon as a quiet ui_bubble silhouette with the kit padlock where the label goes (not a target); B9 the teasers: the first carries the hint `ROW_TEASER_HINT` "עוד מקורות ייפתחו", the rest are wordless slips fading down (×0.62 a row, floor 0.2, so the pane keeps no empty band) · `game/scripts/ui/shop.gd`, `game/tests/unit/test_lower_pane.gd`, `tools/web/mobile_web.mjs`, `ux/tools/gen_strings.py` (+ generated)
- 2026-09-30 · Game Developer (pane) · B11 the chat: a short thread starts under the pinned bar with the "היום" day chip (`CHAT_TODAY`), then the stick-to-bottom scroll once it overflows; the player's reply is headed by the round's leader's short name, so it reads as a message row · `game/scripts/ui/views/view_chat.gd`, `game/tests/unit/test_lower_pane.gd`
- 2026-09-30 · UX Designer + Game Developer (pane) · the lower-pane decisions as a UX artifact: mobile-first §5.2.2 (the strip is never empty), §5.3.1 (four slots, always), §5.4 B9 (the teaser fade), §5.4.1 (the ruled margin), §5.5.1 (a short thread starts at the top), deviations D55-D59 with the DOG check (hud-design, IA, localization-aware-layout); rtl-map §6.3 thread row; after-shots `ux/manual-test-2026-09-30/fixes/dev3-{card1,c1-tabs,chat}-{390,se}.png` · `ux/mobile-first-layout.md`, `ux/rtl-map.md`, `ux/manual-test-2026-09-30/fixes/`
- 2026-09-30 · Game Developer (pre-tap+HUD) · A2: the pre-tap screen is the round's screen before its first tap: Row A and card 1 (dim) over the teaser rows are up from the pick (`Ftue.picked`), the plaza is one 84-px strip in the free ticker slot, the ticker fades into it at H1; U3's "white field with card 1" superseded (UX decision D51, ux/mobile-first-layout.md §3.3/§5.9, ux/ftue.md rev 5) · `game/scripts/ui/ftue.gd`, `game/scripts/main.gd`, `game/tests/unit/test_review2_engine.gd`, `game/tests/unit/test_review_engine.gd`
- 2026-09-30 · Game Developer (pre-tap+HUD) · A7/B10: Row A's identity chip (the leader's pick-avatar medallion at 64 logical, the densest head that is whole device px, + the short name, R-anchored at the right end) from the pick on; the round-start `LEADER_PICK_PLATE` toast over the stage is gone; the name yields to the Cottage Index once the round has started (state predicate) and to a wide counter (width guard); the cup moves one slot left (hit 536-624); mute and settings work before tap 1 (D52, mobile-first §5.1.1, rtl-map §2/§4.3/§8.6) · `game/scripts/ui/top_bar.gd`, `game/scripts/ui/layout.gd`, `game/scripts/main.gd`, `game/tests/unit/test_cottage_view.gd`
- 2026-09-30 · Game Developer (pre-tap+HUD) · B12: the pre-tap undo chip sits centred in a full-bleed navy bar (the ticker's #072a7a) in the free ticker slot, its timer along the bar's bottom edge; after an election it stays in the lane (D54, mobile-first §5.9, rtl-map §8.6) · `game/scripts/main.gd`
- 2026-09-30 · Game Developer (pre-tap+HUD) · A3: the picker's caption strip on a full-bleed navy plate that hugs its text (44·lines + 24; 11.8:1); `odPick.strip` / `stripText` (D53, mobile-first §5.8.1) · `game/scripts/ui/views/view_pick.gd`
- 2026-09-30 · Game Developer (pre-tap+HUD) · checks: `test_pretap_hud.gd` (9 tests: card 1 from the pick, the chip in Row A clear of the leader's hit, whole-px face, the width guard, the name/cup hand-over, the undo bar, Row A input before tap 1, the caption plate); `mobile_web.mjs` S13-S16 (A3 plate, the name plate clear of the hit pre-tap and at card 1, the pre-tap screen, the undo bar); `window.odDev.hud`; `tools/web/pretap_shots.mjs`; shots `ux/manual-test-2026-09-30/fixes/dev2-*` · `game/tests/unit/test_pretap_hud.gd`, `tools/web/mobile_web.mjs`, `game/scripts/ui/dev_probe.gd`, `tools/web/pretap_shots.mjs`
- 2026-09-30 · Game Developer (ceremony+settings) · A4 + A5: the old leader walks out first, on the OLD stage (EVOLVE_TX `leadMs` = walk 560 + 80 ms beat; RM 150 + 80); the card dims over the empty stage, the new era swaps under the fully opaque page (seam at 910), the lines step out while the page is still opaque and the page lifts empty (no ceremony line over the ticker); state graph §9 rev 2; shots `ux/manual-test-2026-09-30/fixes/dev1-ceremony-*` · `game/scripts/ui/{evolve_tx,leader_walk}.gd`, `game/scripts/main.gd` (`_start_evolve`, trick cue guard), `game/tests/unit/test_leader_walk.gd`, `motion/state-graph-magician.md`, `tools/web/motion_web.mjs`
- 2026-09-30 · Game Developer (ceremony+settings; Game Designer for B15) · B15: all 8 leaders already had their own post-election cards (Bibi 5 beats, the others 3, then the shared encore); gaps filled: the T4 story archive replayed Bibi's beats for every election, it now rebuilds each election's card from `story_seen` (`Story.archive`); the quote lint now covers every story card (a quote only in Dubi's mouth; no "<real name> (ענה/אמר…):" line) and three lines became reported speech ("בלשכה מסרו שאין שום כובע.", "ביבי לא חשוד.", Bennett's "התשובה נמצאה ברשימה: במקום השני."); `content-lint --strict` 0/0, no October 7 content · `design/content.json` (+ `game/data/`), `design/sim/content-lint.mjs` §6b, `game/scripts/sim/story.gd`, `game/scripts/ui/overlays.gd` (BookOverlay), `game/tests/unit/test_story_leaders.gd`
- 2026-09-30 · Game Developer (ceremony+settings) · A6 + A8 finished (session 5, on `restore-s4`): O7 settings may rise to Row A's bottom, tightens its group headers 48 → 36 only where the roomy rows would overflow (375×548), and past that scrolls with a left-edge thumb (large text at 375×548: scroll 180, `reset` in reach); the switch is `SettingSwitch` (ON flag track + knob left per rtl-map §7.4 + "פועל" in flag; OFF grey + knob right + "כבוי" in slate; 3 cues, text ≥ 6.9:1); mobile-first D60, D61, §9.1 S17; checks: `tools/test.sh` 421/421 (incl. `test_settings_sheet.gd` 5), content-lint --strict 0/0, strict build green, `mobile_web.mjs` full matrix PASS (9 devices, 0/0/0; settings 6/6 rows on screen on every device); open: HANDOFF A8 said ON knob "on the right", kept left per §7.4/R6 (orchestrator call) · `game/scripts/ui/{overlays,overlay,dev_probe}.gd`, `game/scripts/main.gd` (`sheet_rect(.., tall)`), `game/tests/unit/test_settings_sheet.gd`, `tools/web/mobile_web.mjs`, `ux/mobile-first-layout.md`, `ux/manual-test-2026-09-30/fixes/dev1-settings-*`

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
- **→ ux-designer, from game-developer (engine), wave 3: OBJECTION (ticker anchor):**
  ```yaml
  objection:
    skill_or_agent: game-developer (engine)
    against_artifact: ux/rtl-map.md §5.1 (ticker anchor)
    reason: |
      §5.1 puts TICKER_TAG right-aligned at x 700 and Dubi's 16×16 head at (576, 10), inside
      Rect2(560, 0, 160, 84), with the crawl ending at 552. Your own budget (string-budgets
      ticker.tag) measures the tag at 88 px at ×4 (110 at ×5), so it spans 612-700 and overlaps a
      head at 576-640. What shipped is the 2D Artist's full-body small Dubi, 20×23 art = 80×92,
      not a head. At the old placement (feet 580) he covered the tag's last letter and 12 px of
      the crawl (the 390×844 shot). 88 + 16 padding + 80 does not fit in 160.
    proposed_alternative: |
      Size the anchor from its contents, right → left: the plate hugs the tag (8 px padding, text
      right at 700), Dubi's whole frame goes 4 px left of it, and the crawl ends 4 px before Dubi.
      At ×4 that is plate 604-708, Dubi 520-600, crawl 192-516 (324 px, the same width §5.1
      already accepts on court day). Built this way in `Ticker.anchor_layout` (one data table,
      L.TICKER), so a revision is a data edit.
      Please ratify it in §5.1, or give the numbers you prefer. Two related asks:
        (a) the budget says the tag steps down to ×4 under large text, but PxText has no
            step-down, so it draws at ×5 and the crawl drops to 302 px;
        (b) Dubi is 92 px tall in an 84-px row, so his head pokes 8 px into the Suitcase lane.
      If you want a head-only Dubi instead, that is a 2D Artist crop (16×16), and the crawl then
      gets back 16 px.
  ```
  Also, not objections: (1) keys for S08's bar labels ("שידור ציבורי" / "ערוץ ידידותי"; the bars ship unlabeled) and for S10's flight bonus (the floater is the numeral "+15%" today); (2) the S08 split bar under line 2 (`Shop.SPIN_BARS`) and the spin tag on the plate's bottom edge (`Shop.SPIN_TAG`) are my reading of §6.1 "Spin card"; correct them freely.
- **→ technical-artist / 2d-artist, from game-developer (engine):** (1) Balfour's `padBottom` `#2f3042` doesn't match the art's floor `#2a2340`, so on wide phones a grey strip shows beside the column in the Suitcase lane (the 390×844 @3 shot). (2) The lane is the art's flat floor, and it reads as an empty band before the Suitcase unlocks; a ground texture there would help. (3) The spin cards show the "?" placeholder: no `icon_s01`…`icon_s15` in the kit.
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

- **Orchestrator, 2026-09-29: the brawl-line objection (game-designer, against `events.brawl.copy.script[6]`) is accepted and resolved.** Netanyahu's line is now "צאו החוצה ותמשיכו להתווכח שם.", still reported speech (no quote marks), `verifyHebrew` kept. Synced; content lint 0 errors; tests 173/173.

- **Orchestrator, 2026-09-29: the invisible overlay scrim is fixed (`9a41068`).** `Ui.rect(..., 0.0)` baked alpha 0 into the colour, and colour alpha multiplies `modulate.a`, so the modal scrim, the shop's can't-afford dim and the ticker's headline flash never drew. New `Ui.fade_rect` (opaque colour, modulate starts at 0) is used for all three; `test_input.gd::test_modal_scrim_is_visible_once_open` checks the drawn alpha reaches `backdropAlpha` (it fails on the old code with 0.00). Web check at 1440×900: under Settings, `#140c24` becomes `#2b1753`, which is exactly the grape at 60%. **Open, → 2d-artist / ux-designer:** the scrim is still the fork's grape `U #3a1e72` from `art.json` `uiTheme.scrim`; the kit's modal note says "outline swatch at 60%" (`#0b0a12`). Confirm which, and regenerate `art.json` if it changes (the spin tag plate shares the role).

- 2026-09-29 · 2d-artist · wave 5, the reported art gaps (engine + views asks).
  - **Spin icons:** `spin_s01`…`s15` are redrawn at 24×24, d = 1, the shop-icon size, so they fill `card_plate` like the money-source icons. Each shows its spin's joke: the "0.30" deposit tag, a melting pistachio cone, the monitor in the top hat, the bubble stamped "0", the empty net, the lit window seat, the Spartan finger, the one big button, the gift pager, the laundry sack, the carrot mic, the cobwebbed committee, the heart mug, 999 views and 1 like, and the cigar between two armchairs. The source is `art/od-sevev/src/icons24.py`; the 15×15 grids stay for `icon_plane` and `laundry_bag`.
    - **Data fix, no engine change:** the shop resolves `u.icon`, else `icon_<id>`, and no `icon_s*` ever existed. `design/content.json` `upgrades[].icon` is now `spin_<id>`, and I synced it. Content lint reports no errors.
  - **`thermo_tube_short`:** 14×58. It is the full tube with 30 column rows removed: the bulb, neck, glint and ticks are the same, and the travel is 40 rows (`liquid` yBottom 43). `thermo_tube` is bit-identical to before.
    - **Reader, flagged (`view_thermo.gd`):** it picks the short tube when S < 560 and re-picks it on relayout, and the fill keeps its %. The icon sits 52 px above the tube top. The hit runs from the icon to S−140. On the full tube these give exactly the old S−544 and 404.
    - **→ ux-designer:** on the short tube this gives an icon at S−424 and a hit of `Rect2(12, S−424, 120, 284)`. Your rtl-map §4 says S−452/312, but that doesn't match the full tube's rule (icon = hit top). Please ratify one or correct it.
  - **padBottom:** it was the apron's 1-row bottom rule (row 319), so it was wrong in all four eras: Balfour `#2f3042` → `#2a2340`, Knesset → `#55331f`, Courthouse → `#1b1426`, Washington → `#1f2b63`. Fixed in `pipeline/od-sevev/sprites.py`: the mode of art rows 240-318. One line added to CONTRACT §3.
  - **Suitcase lane:** new kit tiles `lane_{balfour,knesset,courthouse,washington}`, 2×28, horizontal only. Each has the apron lip, its shadow, and course seams spaced 4-5-6-7 rows (paving, boards, tiles, carpet), and no swatch is lighter than the era's apron, so the Suitcase rim keeps its contrast.
    - **Reader, flagged (`diorama.gd` `_place_lane`, ~20 lines):** it tiles the lane across the full canvas width from art row 230, so the side bands of a wide phone match the column.
    - Style guide §17 amends v1 §8 "230-320 flat" to "one colour family, horizontal-only structure".
  - **Not done (item 5, a 3× hat and rabbit for Bibi):** the hat isn't a separate sprite. It is baked into Bibi's approved render, every idle, tap and crit frame at d 3 and d 2. A 3× hat means re-rendering the locked cast (the drift gate, Bar's call) and re-deriving `hatMouth`/`temple` at both densities. A 3× rabbit alone would jump out of a 1× hat: two pixel densities in one gesture. **Proposal:** if Bar approves a cast re-render, the TA swaps the 1× hat/rabbit in the showcase rig for 3× paint-overs, which I'll draw, and the loose `prop_rabbit` gets `density` in `sprites.json.props` plus a divide in `prop_fx.gd`.
  - **Open:**
    - **→ game-developer (engine):** above the lane, the side bands still show `padTop` down to the sky bands' end, then `padBottom`. The Knesset and Washington lawns and the floor rows therefore still meet a flat pad at the column edge. That was true before, and it is not the lane. A cheap full fix: extend the stage art's own edge columns sideways (two 1-px region sprites scaled to the band width).
    - **Scrim (orchestrator's question):** the kit's scrim is `outline` at 60%, as the `sheet_modal` note says. `art.json` isn't regenerated here.
    - `build_all.py`'s keyart and proofs step needs the studio-layout showcase path, so kit proofs aren't regenerated in this worktree.
  - **Checks:**
    - `tools/test.sh`: 212/212.
    - Strict `tools/build_web.sh`: green, lint 500 strings / 0 failures.
    - `build.py --no-render --godot`: web `.pck` 3.12 MB.
    - Every new PNG is binary alpha; the ids are stable.
    - Web: spins tab at 390×844 @3, thermometer at 375×548 @2 and 390×664 @2, wide phone at 430×932 @3; 0 page or script errors.
  - **Files:** `art/od-sevev/src/{icons24,wave5}.py` (new), `art/od-sevev/src/{ui_meters,wave2,build_all}.py`, `art/od-sevev/{out/ui/**,ui-kit.json,style-guide.md}`, `design/content.json` (+ synced copy), `pipeline/od-sevev/{sprites.py,budget.json}`, `game/assets/sprites/**` + CONTRACT §3, `game/scripts/ui/{diorama,views/view_thermo}.gd`.
- 2026-09-29 · ux-designer · **build review + the §5.1 answer** (`ux/review-2026-09-29.md`, R1-R26; played in Chromium at 390×844 @2/@3 and 1440×900 @1/@2, N1 → FTUE → C1/T3/T4/court/flash/settings/large text/reduced motion; O3 not reached at runtime, R8 is from the code).
  - **→ game-developer (engine), §5.1 objection: ACCEPTED as built.** rtl-map §5.1 now carries your numbers (plate 604-708, the full Dubi 520-600, crawl 192-516); (a) the tag stays ×4 under large text by the new §0.2 step-down rule; (b) Dubi's 8-px rise over the lane is accepted (the Suitcase sprite bottoms at S−12, he is not a target). One bug: `set_court_chip` resets the clip to 552, under Dubi (R11).
  - **Blocker R1 → engine:** Dubi's bubble text #1b1426 on #2e2250 is 1.24:1; make `_btext` white.
  - **Major → engine/views:** R2 About prints internal notes (render_shell filter + `aboutHe` from the designer), R3 large text has no step-down (§0.2), R4 K3 fires at 300 ₪ inside C1 (`ftue.gd:155`, spec 1,500 after C1), R5 chat toasts lack avatar + sender, R7 O10 fork overlay (ellipsised body, destructive button first), R8 O3/O1 fork overlays, R9 no history entries (back leaves the game), R10 summons card shows testimony text/timer. Minors R6, R11-R26 in the file with exact fixes.
  - **→ 2d-artist / TA:** scrim decided = outline `#0b0a12` at 60% (R15, `uiTheme.scrim` + re-export); "?" source on stage (R18); trash icon / ✕ style (R26). **→ game-designer:** `facts[].aboutHe` public Hebrew line (R2); slot rows off the thermometer column (R17).
  - **Strings (0 errors; lint 515/0):** CHAT_CEREMONY(+_CUTTING), PARTNER_UPKEEP, FLOATER_FLIGHT, SPIN_BARS_LINE, SPIN_BAR_PUBLIC/FRIENDLY, TOAST_CHAT_HEAD, COURT_SUMMONS_TITLE/BODY/EFFECT/TIMER, COURT_CHIP_SUMMONS, HUD_BPS_POUR, IMP_PROMPT; HUD_COTTAGE_MINUS "−1" confirmed; toast box 644 (x 32-676). **Wired (one line each):** the ceremony thread pill (`view_chat.gd`) and the S10 floater (`main.gd`); PARTNER_UPKEEP lands through the existing `Strings.has` slot.
  - **Checks:** `tools/test.sh` 212/212; strict `tools/build_web.sh` green; `views_web` PASS at 390×844 @2/@3, 1440×900 @1/@2 · `ux/{review-2026-09-29.md,rtl-map.md,README.md,ui-strings.json,string-budgets.json,tools/gen_strings.py}`, `game/data/ui-strings.json`, `game/scripts/{main.gd,ui/views/view_chat.gd}`
- 2026-09-29 · game-designer · **R2 About page, designer side** (`design/facts.json`, `design/sim/content-lint.mjs`, `design/redlines.json`).
  - **`aboutHe` on 44 of 51 facts:** one neutral Hebrew sentence each, never stronger than the source, with the corrected claims from `facts-verification.md` (Gotliv not declared a defector; brawl 18.1.2026; bibist = creators' skit Netanyahu posted; cottage = concept). Unverified Hebrew (brawl, Illouz) and English-only quotes (Trump, witch hunt, Bugs Bunny) are reported speech without quote marks. The public line keeps out שב״כ, seat numbers (the page stays up in the blackout) and the bibist creators' names.
  - **Skipped (7, `notUsed: true`):** threshold-lists, nameless-party, emigration-2025, eisenkot-quote, kaia, travel-expenses, electricity-water. `notUsed` is now a boolean on every fact (reason moved to `notUsedWhy`); truthiness is unchanged for `render_shell.py` (not edited; the views developer owns it).
  - **Lint:** requires `aboutHe` on every launch fact and a boolean `notUsed`; checks Hebrew only (no Latin letters), no production-note words, one sentence, red lines, the poll-number rule, and no quote marks where `heStatus` is unverified. One allow entry `facts.gotliv` ("סיכול ממוקד", her verified term). Fixed a boundary bug: a maqaf before a term ("ב־7 באוקטובר") used to skip the red-line match. Result: 0 errors, 0 warnings (a mutated fixture trips every new check).
  - **Docs:** `creative-pack/references.md` rows 12, 15, 34-40, 42-44, 46 now link the `facts.json` sources (rows 34/35/43/44 corrected); rows 7, 41, 45, 47-49 say "URL needed before the feature is enabled". `brief-round2.md` no longer calls the bibist video a campaign video.

- **Orchestrator, 2026-09-29 (Bar): no mention of October 7 anywhere in the game.** The shipped text was already clean (the only near-hits: the election date 27.10 and the submarine affair's state commission). Enforcement is now total: the content lint's red lines scan `ux/ui-strings.json` and every `facts[].aboutHe` as well as `content.json`; `oct7-hostages` gained השבת השחורה, (מלחמת) חרבות ברזל, שמחת תורה, Swords of Iron, Oct 7 / October 7th, massacre; the date written as 7.10 / 07.10 / 7/10 (any year) is an error while 27.10 passes; and `tools/build_web.sh` now fails on any content-lint error (no override). Probed with injected strings: all caught. Art sources checked for ribbons/posters: none. **→ all roles:** treat this as a hard rule for new copy, art (no yellow ribbons, posters, empty chairs read as hostages) and audio.
- 2026-09-29 · 2d-artist (+ technical-artist item) · wave 6: the UX review's art items (R7, R15, R18, R26).
  - **R7 `button_danger_{default,pressed,disabled}`:** the O10 "למחוק הכול" commit, the primary button's construction on the red ramp; white 4.7:1 default, 8.1:1 pressed; the shared disabled. **→ game-developer (views):** `PxButton._kit_kind("button_danger")` beside `kit_secondary`; commit left, the focused `button_secondary` cancel right.
  - **R26:** `icon_trash` 9×9 (settings danger row, leading `SET_RESET` on the right) and `icon_close` redrawn as the 16×16 round ✕ (same id; the modals' round ✕ silhouette in kit swatches, white ✕ 8.6:1). The court card picks it up with no code change (shot). **→ game-developer (engine), with the R15 theme edit:** `UI_THEME.close.sprite = "icon_close"` in `art/sprites.ts`, then re-export `art.json`, so every modal draws the same kit piece (64×64 visual, unchanged rects).
  - **R18 (TA):** the "?" was not a source strip. `vat` and `washington` have `setPiece: "lob"`, which throws `icon_<currency.icon>` = `icon_coin`, an id that never existed, so the placeholder card flew over the stage. **Fix (data):** `design/content.json` `currency.icon` = `coin9` (the kit's 9×9 shekel; synced; content lint 0 errors); the lobbed coin now draws (`shots/art3/390x844@2-lob-coin-x3crop.png`). **Also:** the hand-drawn three's `source_*_icon_sil` were in `sprites.json` but never shipped (the locked shop card drew "?"); now drawn by the rendered sources' rule (it reproduces those five pixel for pixel). **Pipeline check:** `sprites.check_content_sources`, run by `build.py`: every `producers[]` entry must resolve to a `sources` strip, a shipped icon and silhouette, and its `lob` coin; it fails on HEAD's content (vat, washington) and on a missing silhouette.
  - **R15:** style guide §2.1 / §11.2 / §11.4 and the `sheet_modal` note say `outline` #0b0a12 at 60%. On it: white text 17.7:1 (dark ground) / 4.7:1 (the brightest possible ground), the spin tag plate 17.4:1, cream cards 17.8:1. **Open (F9, → views/UX):** a dark kit sheet's edge on the scrimmed dark is 1.1-2.1:1; proposal: a 1 px `suit_hi` line outside the sheet's outline (3.6:1) when the modals move to `sheet_modal`.
  - **Checks:** `tools/test.sh` 212/212; strict `tools/build_web.sh` green (lint 515 / 0 failures); `build.py --no-render --godot`: 209 kit pieces, web `.pck` 3.12 MB; binary alpha, stable ids. Web 390×844 @2: all eight sources owned by touch on the stage, 0 placeholder pixels (the UX shot had 1,744), 0 page errors. Shots: `scratchpad/shots/art3/` (`kit-wave4.png`, `390x844@2-stage-all-sources.png`, `390x844@2-court-card-round-x.png`).
  - **Files:** `art/od-sevev/src/{ui_controls,wave2,sources,proofs,build_all}.py`, `src/wave6.py` (new, proof), `art/od-sevev/{out/ui/**,ui-kit.json,style-guide.md,proofs/*}`, `design/content.json` (+ synced), `pipeline/od-sevev/{build.py,sprites.py,README.md,budget.json}`, `game/assets/sprites/**` + CONTRACT §4b. No `game/scripts/**` change.
- **Bar, 2026-09-29: spin s12 keeps its name "הוחלט להקים ועדה"** (the old "bury it in a committee" joke about the criminal case; read as not an October 7 reference). Only its icon changes: the three empty chairs go (a hostage symbol); the 2D artist is redrawing it.

- 2026-09-29 · 2d-artist · Bar's no-October-7 rule, visual echoes included: `spin_s12` redrawn + a sweep of every shipped image.
  - **`spin_s12` "הוחלט להקים ועדה"** was three empty chairs at a table. Now: a fat teal lever-arch binder with a "ועדה"-shaped spine label (4 ink micro glyphs, RTL), frost and three icicles on its top edge, a gavel lying unused on it, a cobweb (top right) and a snowflake (top left). 24×24, d = 1, v2 swatches only (13), binary alpha, same id; teal is a new dominant hue in the spin row. `icons15.py`'s unshipped 15×15 chairs grid is removed; `s12.visualHook` updated (synced, content lint 0 errors); style guide §17 + do/don't 13 (no empty chairs at a table, yellow ribbons, posters, day counters, sirens, rockets, uniforms, border fence).
  - **Sweep** (spins, sources, trophies, UI kit, chat, meters, events, props, the four stages and lanes, 25 avatars, every cast strip's first frame, icon, OG): no yellow ribbon, poster, portrait grid, siren, rocket, uniform or army green, border imagery. **Ambiguous, → Bar / orchestrator** (sheet `scratchpad/shots/art4/sweep-findings.png`): A1 `stage_courthouse` three empty high-back chairs behind the bench under a wall clock (approved, drift-locked stage; alternative: a judge's robe over each chair back, or case binders on the seats); A2 `spin_s15` two empty armchairs (alternative: one armchair taken by a hat and a coat, or the two leaders' shoes under a low table); A3 the gold `hop` ring framing faces on 7 avatars incl. Eisenkot (`showcase/src/build.py`; alternative: `sky` for `hop`); A4 `spin_s09` gold pager (the gift's origin is war-adjacent; content call, → game-designer); A5 `spin_s07` Spartan helmet (ancient, not IDF; keep); A6 `trophy_moon` crescent + star reads as an emblem (not Oct 7; alternative: drop the star for a "z"); A7 `depboard` 06:10/06:25/06:40 (alternative: 09:10/09:25/09:40). **Side find (not Oct 7):** `art/od-sevev/out/key/og-1200x630.*` in the repo is a broken composite (keyart.py crops 71×125 frames from the 3× cast); the shipped `game/web/og.jpg` is the good one. Do not run `keyart.build()` until its `frame()` reads `cols/rows`.
  - **Checks:** `build.py --no-render --godot` (spin_s12 + sprites.json + budget only; web `.pck` 3,124,750 B); `tools/test.sh` 212 passed, 0 failed; strict `tools/build_web.sh` green (content lint 0 errors, text lint pass). Shots: `scratchpad/shots/art4/s12-before-after-x4.png`, `s12-in-family-x4-and-d1.png`, `sweep-findings.png`.
- **Orchestrator, 2026-09-29: October 7 art sweep closed.** s12 redrawn (frozen committee binder, no chairs). Bar kept s09 "פייג׳ר זהב" as is. Kept on review: the courthouse's judges' chairs (a bench with the case numbers, reads as court), s15's armchairs (a lounge), the gold avatar rings, s07's Spartan helmet. Changed: the Ben Gurion departure board now shows 09:10 / 09:25 / 09:40 instead of 06:10-06:40 (no early-morning times near 06:29). Left: `trophy_moon`'s crescent + star (an emblem echo, not October 7; 2D artist's call). Also open for the 2D artist/TA: `art/od-sevev/out/key/og-1200x630.*` is broken by the 3× cast (keyart cuts 1× frames); the game's `game/web/og.jpg` is fine; don't re-run `keyart.build()` until fixed.
- 2026-09-29 · 2d-artist + technical-artist · **Sevev 9 @2, the sharp reading cut** (Bar's "sharper text"; `pipeline/od-sevev/font/sevev9@2.glyphs` → `game/assets/fonts/sevev9@2.fnt` + `fonts.json`, `density: 2`).
  - **What:** all 120 drawn glyphs (171 code points with aliases, zero-widths and space) redrawn on a 2× grid (18-row cell), drawn at half the scale into the same box: at ×4 on a k 4 phone a font px is 2×2 device px instead of 4×4. Stroke model: horizontals 2 @2 px (Sevev 9's weight), stems 1 @2 px, 2-px diagonals, chamfered round corners; the ב/כ, ד/ר/ך, ה/ח/ת, ו/ז/ן, ס/ם, ע/צ and ׳/י distinctions all redrawn; digits share one height and shoulder set; ₪ 14×12; pictograms from EPX, ⬅ redrawn filled. Binary alpha.
  - **Metric rule (build fails on any break, `font.check_companion`):** every xadvance, ink box, the line height (22) and baseline (16) exactly 2× Sevev 9's, same code points, same (no) kerning: PASS for 171/171. `--godot` also shapes the proof lines in TextServer: @2 = 2× Sevev 9 on all 10, identical wrapping. Layouts, budgets and the lint are unchanged.
  - **Not used yet:** `px_text.gd` untouched. **→ game-developer (engine):** shape at size 18, scale `eff_px()/2`, and pick @2 only when device px per Sevev 9 px is even (k 7/9 and large text ×5 at k 4 fall back to Sevev 9; the metrics make the swap layout-free). Role split in CONTRACT §6.1: @2 for chat, toasts, card descriptions, ticker crawl, settings, modal/court bodies, About; Sevev 9 for counter, prices, titles, tabs, ticker tag, chips, buttons, badges, dimmed text and anything over art.
  - **Checks:** `tools/test.sh` 212/212 (one earlier run 211/212, not reproduced in 3 reruns); strict `tools/build_web.sh` green, lint 515/0; `.pck` +11 KB, +128 KB VRAM. Proof `pipeline/od-sevev/proofs/font-density2.png`. Docs: CONTRACT §1/§6.1/§7, pipeline README, style-guide §7 + do/don't 12.
- 2026-09-29 · game-developer (engine) · **UX review engine slice: R1, R3, R4, R6, R9, R11, R14, R15, R16, R19, R20, R24 closed** (plus the kit ✕ for every modal, orchestrator ask).
  - **R3:** the §0.2 step-down is central in `PxText` (`fit_width` for one-line labels, `max_lines_large` for wrapped text; ×5 only when the filled string fits, else ×4, never ellipsised by the step). The settings sheet measures its rows and rebuilds in place on toggle. **Deviation:** shop cards keep their 120 pitch, so a name that needs 2 lines at ×5 steps down to ×4 instead of growing the card.
  - **R9:** `scripts/core/layer_history.gd` + `shell.html` popstate; Android back and Esc share `main.back_layer()`, which also closes the expanded court card first (R21's Esc half). `window.odLayers` for web checks.
  - **R15:** `z` #0b0a12 added to the palette in `art/tools/build-sprites.mjs`; `uiTheme.scrim` = z at 60%, `uiTheme.close` = `icon_close`; `art.json` re-exported.
  - **Open → game-designer (R17, not engine):** `L.DIORAMA.xs` puts F0/F1/B0/S0/S1 inside the thermometer column (x 12-132) and F2-F6/B2-B5 inside the Magician's hit (x 172-548); only B6 (568) and F7 (608) sit right of him. Re-place `producers[].slot`; if more right-hand slots are needed, name the x values and the engine adds them.
  - **Open → views dev:** `ChatView._update_rows` reads `r["y"]` on a row without it when T3 opens on a state whose group has not opened (script error, found by a test; not reachable from the UI before C1). `toasts.gd` (R5) and `shell.html` (R2) carry small edits of mine (R1/R6 constants, the popstate handler).
  - **Checks:** `tools/test.sh` 228/228 (16 new in `test_review_engine.gd`); strict `tools/build_web.sh` green (content lint no errors, text lint 515/0); `res_web` PASS, `views_web` PASS at 390×844 @2/@3 and 1440×900 @1/@2; browser back/About/Esc history check PASS. Shots: `scratchpad/shots/fix-engine/390x844@2-{before,after}-*.png`.
- 2026-09-29 · technical-artist · **d 2 alternates for every rendered character and money source** (Bar: "sharp characters on every phone").
  - **What:** the render-down is generalised: every rig in `creative-pack/art/showcase/src/build.py` (`magician`, `sara`, `bennett`, `generic`, `dubi_mic`, `source_at`) is a function of the density d, and `render_char` / `source` render `DENSITIES = (3, 2)` from the same function; the avatars and 1× icons still come from the main render. 24 characters (Bibi, Sara, Bennett, the 20 partners incl. May Golan, the mic Dubi) and the 5 rendered sources now ship a first-generation d 2 render (96·d px from the ref, not a resample): same frames/fps/loop/events, own frame size, anchor, `hatMouth`/`temple`/`points`, frameMaps emitted, binary alpha, edge-clean, widest grid 1960. The pipeline fails if an alternate's timing or point names differ, or a landmark sits > 0.5 art px from the d 3's (measured max 0.5). Full render: **0 changed, 0 new** vs the approved `out/` (the d 3 strips and atlas entries did not move; 51 new `*_d2.png` promoted into it).
  - **The rule** (CONTRACT §3, read from `SpriteStrip.pick_variant`): the largest density dividing k wins, else the main d 3 on "aa". With d 2 + d 3, **every k that is a multiple of 2 or 3 is crisp**; only k 5 and 7 stay on "aa". **→ game-developer (engine):** restricting k to that set (k 5 → 4, k 7 → 6) makes every rendered sprite crisp everywhere.
  - **Objection resolved in place (engine touch, please review):** `pick_variant` keyed on `Display.k` is right only at the stage's ×4. The partner card set `scale_px = 3 / chars[c].density` (the main d 3) on a strip that had picked the d 2 at k 4, so with partner alternates it would have drawn the figure at 2/3 size; the cameo and Dubi's flash would have gone soft (1.5 dp); the diorama never picked a source variant. Fix: `SpriteStrip.set_art_px(s)` picks the variant for the view's own device px per art px (s · f) and `refresh_all` keeps it; the card, the cameo and the flash call it; `FlashCard.pick_art_scale` takes all the figure's densities; `Art.source` returns the picked source variant and `Diorama._repick_density` re-points critters on a k change. Tests: `test_display.gd` (every rendered asset crisp at k 2/3/4/6/8/9/12, same timing; `set_art_px` per view scale; sources d 2 at k 4, d 3 at k 6, "aa" at k 7), `test_flash_view.gd`.
  - **Budget:** web `.pck` art 3.14 → **4.50 MB** (+1.33 MB; a partner's d 2 is 23-78 KB, median 60 KB, about half its d 3; sources +2-3 KB each). Resident VRAM (one render per figure is loaded): **k 4 6.4 MB** (was 6.7: the sources drop to d 2), **k 6 12.0 MB** (unchanged); a partner body where a view picks the d 2: 0.8-3.1 MB (median 2.0) vs 1.8-7.0 (median 4.5) on the d 3. Everything-resident would be 155 MB (was 112): never preload the cast, never both renders.
  - **Checks:** `tools/test.sh` 230 passed, 0 failed; strict `tools/build_web.sh` green; `xvfb-run -a build.py --godot` full render 0 drift. Web 390×844 @2 (k 4), pixel-matched against the textures: Dubi's flash now picks ×4 on the d 2 = **exact 2×2 blocks** (100% of the visible texels); the stage's Bibi and the vat/hitech sources d 2 exact 2×2 (100% / 92%, the rest occluded); the partner card (art ×3 = 3 dp per art px) correctly draws the **d 3 at exact 1×1**, not the d 2: 2×2 there would need the card at ×4. Shots + the d 2 contact sheet: `scratchpad/shots/ta3/`, proof `pipeline/od-sevev/proofs/sprites-contact-k4.png`.
  - **Open:** the partner card and cameo at ×3 are soft at k 2 and k 6 (4.5 dp per art px: no density divides it); → views/UX: pick the card's art scale per k like the flash (`pick_art_scale`), e.g. ×4 at k 6 (d 3 at 2 dp) and ×4 at k 4 (d 2 at 2 dp).
- 2026-09-29 · game-developer (views) · **views wave: R2, R5, R7, R8, R10, R12, R13, R21, R22, R23 closed** (R26's settings trash icon placed; R25 left hidden).
  - **The 44/61 stall, two causes, neither a sim-rule bug.** (1) The review script paid only the gold pills at the bottom of the thread: the pending partners' join demands (open forever, never escalating) scrolled above the fold while May Golan's demand → ultimatum → leave → rejoin kept the bottom busy (its last shot: 3 in the group, badge 9, 216M ₪). (2) Found by replaying the round in Chromium with a driver that pays *every* pill, scrolling to it: 194 pills paid, 100 min of play, still 42-50/61. **A brawl freezes its two rows (out of the 61) until "צאו החוצה"**, a button inside T3 only; with the chat closed nothing said so (the badge counted payable pills only, no toast). `test_progression.gd` pins it on the shipped content through the real Economy + Politics: paying every pill every 30 s without ending the brawl stays at 46 for 25 min (seed 11), ending it opens the gate at 7:30; a slow payer who does end brawls opens it at 8:40-8:50 (every 130 s, or only the newest pill every 10 s). **Fix (view, the smallest):** the T3 tab badge counts an open brawl and a brawl posted while T3 is closed shows CHAT_SYS_BRAWL as a chat toast (a tap opens T3). The sim rule (freeze until pressed, deck §E) is unchanged. With the fix the replay (`tools/web/round_web.mjs`, which also presses "צאו החוצה") reaches 68/61 at 34:24 of play (the driver is a slow, pay-everything player: 51 pills), opens O3 from the "עוד סבב!" CTA, calls the election and lands on the round-1 flash in round 2, 0 page errors.
  - **Open → ux-designer:** (a) T3 opens at the newest message and nothing points to an open pill or a brawl above the viewport; proposal: a "{n} ממתינים ↑" chip on the thread's top edge while one is above (tap = scroll to the oldest). (b) A brawl has no stage cue beyond the toast and badge (the ultimatum has its cameo); consider the brawl cloud as a cameo while it is open.
  - **Open → game-developer (engine), `ftue.gd`:** C1 opens the group at 3 sources owned in total (`Conditions.sources_owned`), but the קואליציה tab slot appears at 3 *kinds* (`Ftue._sources`): 3 taxpayers ping C1 with no tab (seen in Chromium); make `"tabs"` count `owned_total(s)` like the sim. **Also seen in Chromium, not reproduced headless:** the first tap into T3 after Esc folded the court card over it was not taken once (the second was); worth a look with R9's history sync.
  - **Open → technical-artist:** Almog Cohen's chat avatar draws the neutral "?" (no `avatar_<slug>` resolves for `almog`).
  - **R8:** O3 is `ElectionCard` (`ui/views/view_election.gd`): ELECT_TITLE (round n), the MOOD line, EVO_MULT, ELECT_RESET/KEEP/KEEP_CASES, ELECT_GO stacked over ELECT_CANCEL, EVO_NEED + a disabled GO while the gate is shut. The transition reads EVOTX_LINE over ELECT_TITLE (the new round), EVO_MULT (RTL order, not the fork's "×a → ×b") and EVO_THUMBS_GAIN at ×4. O1 is `ReturnCard` (RET_* by absence band, RET_GAIN, RET_CHAT, RET_CAP, one gold RET_BTN; every exit still collects). **R7:** O10 is `ResetCard`: the whole RST_* copy at ×4, "התחרטתי" right and focused, "למחוק הכול" left on the kit `button_danger` (`kit_danger`), no backdrop dismiss; stacked under large text (×5 is 260 > 224). All three share `SheetCard` (`sheet_modal`, 624, centred in the band, bodies that wrap and grow the card, the §7.1 button rule); `Overlays.{Evolution,Offline,Reset}Overlay` are thin subclasses. **→ 2d-artist, F9:** the modals are on `sheet_modal` now, so the 1 px `suit_hi` edge redraw is unblocked.
  - **R5:** `Toasts.show_chat_toast`: the 16×16-art face crop at x 612-676, TOAST_CHAT_HEAD over a one-line preview right-aligned at 596, 132 tall (grows under large text); own nodes beside the engine's plate_h/text box. **R12/R13:** partner-card values 16 px left of their labels in the body colour; the card draws the thread's own pill, so a ceremony reads "לגזור סרט ✂" → "גוזרים…" in the thread and on the card and paying from the card keeps it open; the card's figure now picks ×4/×3/×2 per k as the flash does (×4 at k 4 and k 6, the TA's ask; the cameo keeps §4.2's ×3/×2). **R22:** "{n} משתתפים" = members + pending + the Magician. **R23:** a spent ultimatum chip is grey at 50%. **R10:** the court card and chip use COURT_SUMMONS_* / COURT_CHIP_SUMMONS during the summons (its timer counts down to the testimony) and the court keys during testimony. **R21:** the expanded court card pads T3's thread (above the composer) and T4's list; Esc/back folding it first is the engine's `back_layer()` (my duplicate dropped at the merge). T3 opened before the group exists no longer throws in `_update_rows`.
  - **R2:** `render_shell.py` prints only `aboutHe` of facts without `notUsed: true` (44 listed; 7 left out, 0 without aboutHe, printed by the build); `<ul dir="rtl">`, links #9fc3ff, ABOUT_BACK in a sticky top-left bar; checked in Chromium on the real data.
  - **Also:** kit gold buttons take the kit's ink label (white on gold was unreadable: O1's "לאסוף", the ticker's "עוד סבב!"). Dev only: `window.odDev` (`ui/dev_probe.gd`) + `window.odModal` for `tools/web/round_web.mjs` and `modals_web.mjs` (HOW-TO-RUN).
  - **R25:** not cheap (O4/O5 are image share cards): the rows stay hidden until that wave.
  - **Checks (after merging 6b84530):** `tools/test.sh` 249/249; strict `tools/build_web.sh` green; `views_web` PASS (390×844 @2/@3, 1440×900 @1); `modals_web` PASS; `round_web` PASS (390×844 @2, speed 10; the transition itself ran between two screenshots, its texts are checked in `test_modals`). Shots: `scratchpad/shots/fix-views/`.
- 2026-09-29 · game-developer (engine) · **Bar's "sharp characters on every phone" + "sharper text": the crisp k rule, Sevev 9 @2 in PxText, two views-dev items.**
  - **Crisp k (`core/display.gd`):** k = the largest multiple of 2 or 3 ≤ the k that fits (`crisp_k`; 5 → 4, 7 → 6, 11 → 10; 1 stays 1), the remainder letterboxed into the expand area. 430×932 @3 / 428×926 @3 go k 7 → **6** (Bibi d 3 at 2 dp, was 2.33 dp "aa"); every other phone in the table is unchanged (390 @2 k 4, @3 k 6, 412 @3.5 k 8, desktop frame @1 k 2). The ultimatum cameo's ×3/×2 is lowered to the largest scale whole on one of its densities (`SpriteStrip.crisp_art_px`: ×3 at k 6 → ×8/3 = the d 2 at 2 dp); the partner card and flash already pick per k (`pick_art_scale`). HOW-TO-RUN scale table rewritten; `res_web`/`views_web` check the crisp k.
  - **Sevev 9 @2 (`PxText.reading`, `HeFont.sharp()`):** a reading text shapes `sevev9@2.fnt` at 18 and draws at `eff_px()/2` only where a Sevev 9 px is an even number of device px (k 2/4/6/8 at ×4; large text ×5 at k 6/8), else Sevev 9 (k 3/9, ×5 at k 4, outline, the fallback surface). Boxes are floored in Sevev 9 px × 2, centring floors in Sevev 9 px, so layout never moves: `test_sharp.gd` lays out all 492 UI strings + chat samples both ways at k 4 and 6 in 5 boxes (4,960 layouts) and compares width, line ranges/widths and ellipsis: identical. **Reading:** chat bubbles, system lines, transfer line, the chat toast's line, card line 2, the ticker crawl, settings labels + captions, modal bodies (`Overlay.body_text`, `SheetCard.para` non-centred), court-card excuse/body/effect, stage toasts + Dubi's bubble, the flash's lines. **Display (Sevev 9):** counter, rate, prices/pills, titles, tabs, ticker tag + date chip, chips/timers/badges/buttons, names, dimmed (expired/deleted bubbles, the court prefix) and over-art text. Web dev `?dev=1&sharp=0` = before.
  - **Ftue `tabs`** counts sources owned in total (`Conditions.sources_owned`, as C1 does): 3 taxpayers now show the קואליציה slot with the C1 ping.
  - **"First tap into T3 after Esc folded the court card":** two causes. (1) Engine bug, fixed: during the ~200 ms fold the card's hit was still the expanded rect, so a press there was eaten (`CourtView.folding()`, a folding card takes no press; reproduced headless, fails without the fix). (2) The one seen in Chromium (traced with an instrumented build at 430×932 @3): the tap *did* reach the thread, 16 px off the avatar, because the live group had just posted and T3 followed the newest message; the driver aimed from a stale `odDev` snapshot. `modals_web` now waits for a settled thread; R9 history sync was correct (depth drops on the fold's first frame, one `history.go(-1)`, echo ignored).
  - **Checks:** `tools/test.sh` 256/256 (249 + 7 in `test_sharp.gd`; `test_display.gd` updated); strict `tools/build_web.sh` green (text lint 515/0); `res_web` PASS (390×844 @2/@3, 430×932 @3, 1280×800), `views_web` PASS (390×844 @2/@3, 430×932 @3, 1440×900 @1), `modals_web` PASS (390×844 @2, 390×844 @3, 430×932 @3). Pixel-measured (before → after): chat body font px at k 4 **4 → 2 dp**, 390 @3 6 → 3, 430 @3 7 → 3, desktop 2 → 1; Bibi at 430 @3 1-dp "aa" (3,594 colours, 29% of 2×2 blocks uniform) → **100% 2×2 blocks** (73 colours); k 4 / k 6 stay 100% 2×2; the chat avatar (d 1) is whole k-blocks everywhere. Shots: `scratchpad/shots/sharp/` (`{before,after}-{390x844@2,390x844@3,430x932@3,1440x900@1}-{main,chat,cards,settings}.png`, `crops/cmp-*-{bubble,avatar,bibi}.png`, `measure.json`).
  - **Open → technical-artist:** CONTRACT §3's pick table still lists k 5/7 on "aa" and §6.1 says "PxText today shapes at 9": both are now engine fact the other way (k is never 5/7; @2 is wired); please refresh on your next pass. **→ UX:** the settings captions and the chat toast line on @2 read lighter (1 @2-px stems by design); if a caption on cream wants more weight, that is a role call, one flag.
- **Bar, 2026-09-29: the player character is called "ביבי", never "הקוסם".** Every shipped string changed (content.json 10, ui-strings via `ux/tools/gen_strings.py` 9, the web shell's og/twitter alt). Two ticker lines that became invented quotes of a real person (the lint's quote rule) were reworded as reported speech: g12 "בלשכה מסרו שהכובע הוא עניין פרטי. הכובע: אין תגובה." and w03 "נחיתה בוושינגטון. במכס שאלו אם יש מה להצהיר. אין כלום.". Kept on purpose: the tap-frenzy banner "ידיים של קוסם!" (an idiom, not his name) and the internal code name `magician`. **→ all roles:** new copy says ביבי; anything he "says" in quote marks needs a real [Q] source, otherwise reported speech.
- 2026-09-29 · 2d-artist (+ technical-artist items) · **wave 6 polish: the no-photo stand-in, `trophy_moon`, @2 pictograms, the key-art script, F9.**
  - **No-photo stand-in (Almog Cohen has no ref; no likeness drawn without one):** `avatar_nophoto` 32, `avatar24_nophoto` 24 (the avatars' ring + disc, a featureless head and shoulders, slate on silver) and `nophoto_idle` 40×97 d 1, anchor [20, 96] (a featureless figure in a suit). **Wiring (data, no engine change):** the pipeline joins them as the hand-drawn character `chars.nophoto` (`standIn`) and aliases every content partner without a character to it (`sprites.standin_aliases`; today `almog → nophoto`), so `ChatView.avatar_art`, the chat toast, the partner card and the ultimatum cameo draw it instead of "?". Test added in `test_chat_view.gd`. **Refs still wanted (`asset-requests/REQUESTS.md`):** `almog`, `aide`, `mk-generic`; when `almog`'s render lands its `chars` entry wins and the alias drops on the rerun.
  - **`trophy_moon`:** the star beside the crescent (read as an emblem) is two white z's rising right (a nap).
  - **Sevev 9 @2 pictograms:** 11 of 12 were an EPX pass of Sevev 9 (all but ⬅); all 11 hand-redrawn on the @2 grid in the letters' stroke model (📺 ☕ ⭐ ⏳ ⚖ ✂ 🔥 👻 📈 🔇 💸). Each ink box is exactly 2× its Sevev 9 twin's; `font.check_companion` PASS (171/171), TextServer @2 = 2× on all 10 proof lines.
  - **Key art (TA):** `keyart.py` read 1× frames out of the 3× strips. It now reads frame data and density from the showcase `atlas.json` (`frame(anim, i, d)`) and composes on a fine grid of d px per art px, pasting the render 1:1: OG 200×105 art ×6 with the d 3 Bibi (2 px per sprite px; ×5 has no crisp density), icon 64 art at d 2 ×16 (master now `out/key/icon-128-art.png`; `sprites.ICON_MASTER` updated; old `icon-64-art.png`, `og-240x126-art.png` removed). `mock.py` shared the bug (proof-only; now samples the d 3 at 1/3). **`game/web/og.jpg` replaced** (123 KB): same composition as the shipped one (curtained stage, the wordmark, DOHA Suitcase, hat and shekels) with the current 3× Bibi, crisper face; no in-image text but the wordmark and DOHA, nothing that echoes October 7; `og:image:alt` already says ביבי. **App icons regenerated too** (`game/assets/icon/*`): same framing from the d 2 render (the old master was the pre-3× 1× Bibi); revert `icon-128-art.png` if Bar prefers the old one.
  - **F9 closed:** `sheet_modal` has a 1 px `suit_hi` edge outside its outline, following the chamfer (38×38, slice [7,23,7,7], content +1): 3.6:1 on the scrimmed dark. **→ game-developer (views), optional:** draw `SheetCard` / the flash frame at `panel_rect.grow(4)` to keep the title band and body exactly where they were (today they sit 4 logical px further in; `HEADER_H` 88 still clears the band).
  - **Not committed on purpose:** `build_all.py` also regenerates ~18 art proofs that were already stale at HEAD (pre-3× Bibi, earlier waves); I kept only the proofs my pieces touch.
  - **Checks:** `tools/test.sh` 256 passed, 0 failed; strict `tools/build_web.sh` green (content lint no errors, text lint 515/0); `xvfb-run -a build.py --no-render --godot`: 212 kit pieces, 26 characters, @2 metric PASS, web `.pck` 4,496,257 B; binary alpha, stable ids. Godot renderer (xvfb, opengl3) at 780×1688 = 390×844 @2 (k 4): Almog's bubbles carry the stand-in avatar, his partner card the stand-in figure. Shots: `scratchpad/shots/wave6-art/` (`wave6-art.png`, `sevev9at2-pictograms-proof.png`, `og-new-1200x630.jpg` vs `og-old-shipped.jpg`, `chat-almog-nophoto-{member,removed}.png`, `partner-card-almog-nophoto-{member,removed}.png`).
  - **Files:** `art/od-sevev/src/{wave6,icons15,wave2,keyart,mock,proofs}.py`, `art/od-sevev/{ui-kit.json,style-guide.md,out/ui/{nophoto,sheet,trophies}/**,out/key/*,proofs/*}`, `pipeline/od-sevev/{sprites.py,font/sevev9@2.glyphs,README.md,budget.json,proofs/*}`, `game/assets/{sprites/**,fonts/sevev9@2.png,icon/*}` + CONTRACT §1/§4, `game/web/og.jpg`, `game/tests/unit/test_chat_view.gd`, `asset-requests/REQUESTS.md`, `tools/{icon.sh,build_web.sh}` (comments).
- 2026-09-29 · game-developer (views, wave 6) · **R25 share cards O4/O5, Bar's WhatsApp share, the pending chip, the brawl cue, the spin-end toast.**
  - **O4 / O5 (`ui/views/view_share.gd`, `ui/share_kit.gd`):** T4's SHARE_RECEIPT_TITLE / SHARE_RESULT_BTN rows are unhidden and open 0.8·vs.y sheets. Each card is the 2D Artist's kit piece (`share_receipt_bg` / `share_result_frame` and its zones) plus engine text at 5 card px per art px (`PxText.exact`), rendered once into a 1080×1350 SubViewport and read back to a PNG when the sheet opens (U9: the tap only hands over bytes). The preview is that PNG at whole device px (a = 3 at k 4, 8/3 at k 6). ביבי stands on the result stage as his d 2 idle frame 0 at 2 card px per sprite px, so the figure is whole-pixel in the PNG at 0.8 of stage size. The receipt amounts follow §5.1: the round's income by source share, fuel/Wing 60/40, coalition = the round's paid lines, pistachio 0. The result card shows no seat numbers.
  - **Sharing:** "לשתף" uses `navigator.share({files, text})` and falls back to a download plus text+URL on the clipboard. "לשמור תמונה" downloads. The new "לשתף בוואטסאפ" opens `https://wa.me/?text=` + encodeURIComponent(SHARE_TEXT_*), which ends with the URL: a new tab on desktop, in place on a phone. About's invite gets ABOUT_SHARE plus a wa.me link. The one URL constant is `ShareKit.SITE_URL` = https://od-sevev.vercel.app/. `build_web.sh` defaults OD_SITE_URL to it and writes absolute `og:url` (new), `og:image` and `twitter:image`. The shell passes the value to the engine as `window.odSiteUrl`.
  - **T3 chip / brawl cue (`view_chat.gd`):** when open pills or an open brawl sit above the viewport, a "{n} ממתינים ↑" chip (kit button_secondary, engine ↑ icon) shows at the thread's top edge, and a tap scrolls the nearest one in. An open brawl with T3 closed puts the brawl cloud (×2) in a chat_bubble_in plate under Row B. A tap opens T3 at the brawl. The cue gives way to the toast dock and to modals.
  - **Timed spins:** when one ends, TOAST_SPIN_END "הספין ״{NAME}״ ירד מהכותרות." shows and `spinEnd(id)` goes to the Audio. The cue-spec names no cue for it (§4: spin/frenzy ends are silent), so it is a hook only.
  - **Strings (gen_strings, 0 errors):** SHARE_WA, ABOUT_SHARE_WA, CHAT_PENDING_ONE/_OTHER (box chat.pending), TOAST_SPIN_END. The worst-case `{url}` is now the real host. Fixes: the share-text "≤ N + URL" count now leaves the URL out, as §5.3 says (it had counted the placeholder URL). RESULT_FOOT is now "משחק סאטירה · {url}", since with the real host the old line measured 209 px in the 200-px band and the wordmark already carries the name.
  - **Checks:** `tools/test.sh` 270/270 (256 + `test_share_view.gd` 10 + `test_views_wave6.gd` 4); strict `tools/build_web.sh` green (content lint 0, text lint 520/0); `views_web` PASS, `modals_web` PASS, new `share_web` PASS at 390×844 @2 and @3 (PNG 1080×1350, the clipboard text, the wa.me text round trip, the chip, the cue, absolute OG), 0 page errors. Shots: `scratchpad/shots/wave6-views/`.
  - **Open → game-designer / UX:** `design/redlines.json` `emblems-and-brands` forbids "וואטסאפ". Bar asked for the label, so `allow` covers SHARE_WA and ABOUT_SHARE_WA only (a functional label; the chat stays unbranded and the icon uses no green). Please ratify. **→ UX:** confirm the RESULT_FOOT cut and the 2-line wrap of RECEIPT_HEAD. SHARE_RESULT_BTN is not also offered after O3b (rtl-map has no slot there). **→ 2d-artist:** the engine draws stand-ins for `icon_share_wa` (a 9×9 speech-bubble handset in white/ink) and `chat_icon_up` (7×9). A 26×20 `brawl_cloud` cut drawn at ×4 would replace the ×2 cue. **→ audio:** `spinEnd(id)` arrives if you want a cue. **Risk:** Godot delivers the tap one frame after the DOM event. Chrome's 5 s user activation covers that; iOS Safari's `navigator.share` is untested on a device (the fallback path is covered).
- **Orchestrator, 2026-09-29: the WhatsApp label exception is ratified.** `emblems-and-brands` keeps WhatsApp's look (colours, ticks, marks) out of the game's chat; a functional "לשתף בוואטסאפ" button that opens wa.me is what Bar asked for. The `allow` stays scoped to `SHARE_WA` and `ABOUT_SHARE_WA`, the icon stays kit white/ink (no green).
- 2026-09-29 · technical-artist · **Yair Golan re-rendered from Bar's better ref (`refs/golan.png`; the old one is `refs-rejected/golan-v1.png`).** New landmarks in `showcase/src/cast.py` (content id and slug stay `golan`; May Golan untouched): neck 460 (under the chin), waist 910 (under the belt), eyes (408,250,26,12)/(505,240,29,12), an explicit lid skin (242,160,122) because the midpoint sample hits the nose shadow, react `hop`, no arm, avatar head box (280,30,700,450). Imported frames: d 3 119×310 (anchor 59,309), d 2 81×206; idle 20 f (6 unique cells) 714×310 / 486×206, react 8 f (7 cells) 833×310 / 567×206, avatars 32/24. Binary alpha, edge check, frameMaps, same_motion and ≤2048 all pass; Golan VRAM d3 2.68→1.92 MB, d2 1.20→0.87 MB.
  - **Drift proof:** full render with `--allow-drift`: 6 changed (only `golan_{idle,idle_d2,react,react_d2,avatar,avatar24}.png`), 0 new, 0 only-in-approved: the other 24 characters, 5 sources, props and stages pixel-exact. Golan then approved into `showcase/out/`, and a strict full render (no flag) gave 0 changed, 0 new. Imported with `--no-render --godot` from the approved out/ so no other file churns bytes.
  - **Checks:** `tools/test.sh` 270/270; strict `tools/build_web.sh` green. Before/after sheet: `scratchpad/shots/golan/golan-before-after.png`.
  - **Groundwork for per-leader tap/signature (not started):** the Magician's `tap`/`crit` rig is Bibi-only (hat, rabbit, `hatMouth`/`temple` tracks). Making it generic means a `tap`/`sig` recipe per `cast.py` entry (the tap squash-stretch table plus an optional arm swing and an optional prop anchor exported as a named per-frame point track), and generalising the two hard-coded track names (`build.py` `same_motion`, `sprites.py` `POINT_TRACKS`) to any named track; `big_banana.gd` already plays `tap` and falls back from `crit` when a leader has none. About a day of rig work, then per-leader landmarks as content.
- 2026-09-29 · game-designer · **Leader select: a different leader every round (Bar: "too much emphasis on Bibi").** Spec: `design/leader-select-spec.md`.
  - **Roster, 8 (4 per side):**
    - ביבי, בן גביר, סמוטריץ׳, דרעי;
    - בנט (ביחד, with לפיד as his No. 2: Lapid is not a party head in 2026, fact `beyachad-list`), אייזנקוט, ליברמן, גולן.
    - Not at launch (Bar's call): גנץ (everyone's stand-in), עבאס (review first), יהדות התורה (who heads).
  - **The pick:** it comes before the first tap (it replaces TITLE and is the audio-unlock gesture), then after every election. There are no locks, the order is shuffled, and a הפתעה tile picks at random.
  - **Equal footing:** every number is shared. Leaders differ in words, art and **one rule** each:
    - Bennett's own pledge card;
    - Ben Gvir: partners threaten ×0.5;
    - Liberman: a "לא יושב" pill that declines a demand.
  - **Bloc logic:**
    - lineups deal shared coalition slots to people; seats are shuffled per round outside Bibi's round;
    - the other side appears as rival cards;
    - the court stays Bibi's, and everyone else gets the press skin (כותרות / יום תחקיר);
    - Dubi learns each leader's lines;
    - the base is shared, and a new face adds +10% base for the round.
  - **Content (`design/content.json` `leaderSelect` + `leaders[]`, additive, not read by the current build):**
    - full kits for ביבי (re-keyed), בנט, בן גביר, ליברמן, ≈100 strings each;
    - 9 cast profiles (3 generic no-photo MKs), 4 rival cards, a coalition-side leak, a rival ticker, `bibiOnly` lists and `neutralCopy`;
    - 502 new Hebrew strings in all;
    - wave 2 (אייזנקוט, סמוטריץ׳, דרעי, גולן) is a per-leader backlog in the spec §11.
  - **Facts:** 12 new facts in `design/facts.json`, all `launchWith: leaderSelect` (notUsed until ship), and a table in `facts-verification.md`.
  - **Lint:** `content-lint.mjs` §9 checks kit completeness, refs, lineups (Bibi's lineup must equal the shipped partners), capacity and leader ticker rules; strict 0/0. `tools/test.sh` 270/270. `game/data/content.json` is synced.
  - **→ game-developer (sim + views):** spec §9.6 and the §10 checklist.
  - **→ technical-artist:** `propMouth`/`temple` tracks and the `source_advisers` recolour.
  - **→ 2d-artist:**
    - props (pen, phone, chair);
    - `source_donor`, `source_funds`, `suitcase_plain`;
    - 8 `spin_slot_*` icons;
    - the picker kit;
    - lineup key art.
  - **→ animator:** the prop tap, the react crit, the picker, and the swap in EVOLVE_TX.
  - **→ UX:** the `LEADER_PICK` node, strings and the §10.3 neutral rewrites.
  - **→ audio:** a `leaderPick` sting and crit cues by react event; no leader motifs (the leitmotif stays non-partisan).
  - **→ Bar:** spec §12.
- **Bar, 2026-09-29, leader select (spec §12):** (1) the 8 launch leaders are approved (ביבי, בן גביר, סמוטריץ׳, דרעי · בנט, אייזנקוט, ליברמן, גולן), including בן גביר as playable; Lapid rides inside Bennett's round; Gantz, Abbas and UTJ stay out. (2) The picker comes before the first tap and replaces the title. (3) Keep the +10% base for switching leaders. (4) Replace the Bibi-with-hat key art, OG image and app icon with a lineup of the leaders. Orchestrator default for §12.4: Bibi's lineup keeps today's partner numbers (no reshuffle), since the lint pins it.
- 2026-09-29 · game-designer · **Leader select wave 2: full kits for אייזנקוט, סמוטריץ׳, דרעי, גולן; all 8 leaders are content-ready.**
  - **Kits** (`design/content.json` `leaders[]`, same schema as wave 1; lint: eisenkot 104, smotrich 104, deri 103, golan 106 strings): pick, rule, tap prop/verb/crit, t4-t8 source skins, 8 spin skins, the press hazard with 6 growing excuses, Dubi, the Suitcase, 3 story beats, 12 ticker lines and a trophy each, plus lineups and rivals (capacity 50 / 51 / 51 / 50). `contentReady` lists all 8; `backlog` is empty.
  - **Rules and taps:**
    - אייזנקוט **ישר**: crits off and every tap is paid the crits' expected value up front (×1.18 base, ×1.63 with slot E). That is EV-neutral by construction; it replaces the plan's flat ×2 (+69% tap value). Ruler · יישור קו; tap 7 shows "בלי קסמים. רק ישר.".
    - סמוטריץ׳ **שר האוצר**: VAT ×1.18 from t 0 and demands −10% (the p_deal knob). Calculator · חישוב · אין כסף! (not העברה, which is Ben Gvir's verb).
    - דרעי **ידידי**: rejoins at 1.0× and each paid demand gives a 30 s ☕ tap ×1.2. Coffee · קפה · ידידי.
    - גולן **איחוד**: merges two 60 s+ members (seats and upkeep summed, one demand stream at the higher price, a walkout takes both; 2 per round). Stapler · איחוד · עוד איחוד.
  - **Facts:** 9 new, found by web search, `launchWith: leaderSelect` (notUsed until ship), with `aboutHe` linted and a table in `facts-verification.md`: eisenkot-quit-unity, yashar-founded, yashar-horowitz, smotrich-feiglin, coalition-funds-2025, deri-tax-plea (label F, worded as a plea conviction), deri-law, golan-labor-primary, democrats-merger-2026. None is left unverified. The guardrails hold: no October 7, war or army material; nothing personal or pre-politics for Eisenkot or Golan; no community is the punchline; no poll numbers; no quotes of real people.
  - **Spec:** §2.1 rows, the wave-2 lineups in §5.5, the knobs in §5.1/§9.6, `merges` in the per-leader stats, and the tunables and predictions in §7 are updated. §11 is done.
  - **Checks:** `content-lint --strict` 0 errors, 0 warnings. `tools/sync_data.sh` ran. `tools/test.sh` 270/270.
  - **→ game-developer (sim):** new knobs `straightTaps` and `mergeMembers` (`Coalition.merge`), and `leaderEffects` (`producerMult` + `demandDiscountPct`; `coalition.rejoinMult` + `onDemandPaid: tapBuff`). The per-leader stat is `merges`. Each rule's `_note` is the contract. **→ UX:** Golan's "לאחד" pill and pair prompt, Deri's ☕ chip, Eisenkot's tap-7 floater (strings are in each `rule.copy`).
  - **→ Bar:** (1) the Deri kit uses his 2022 tax plea and the Basic Law amendment (both public record, label F, worded exactly as the sources say), and the backlog asked for a legal read of that wording before ship. (2) Eisenkot's rule changed from a flat ×2 to EV-neutral taps.
- 2026-09-29 · ux-designer · **Leader select: the `LEADER_PICK` screen, the per-leader HUD, the press skin and the strings.** Spec: `ux/rtl-map.md` §8 (the picker, replacing the title state) and §4.3 (the per-leader stage, HUD and press skin), `ux/screen-graph.md` §0 (live), `ux/ftue.md` §8; deviations D26-D35.
  - **The picker:**
    - **Layout:** a full-screen stage mode; the HUD is hidden and the economy frozen. Wave 1 is a 2 × 2 grid with a הפתעה bar under it. Eight leaders are a 3 × 3 with הפתעה in the centre, so the centre cell is no leader's.
    - **Order:** shuffled on every open and **bloc-balanced**: diagonals in the 2 × 2, a checkerboard in the 3 × 3, so the right and left columns always hold the same bloc mix. No bloc is named or coloured.
    - **Tiles:** avatar, `short` and `party`. The blurb goes to a caption strip on press, focus or hover; long-press or `I` opens a leader card with the rule.
    - **Avatar sizes:** L 128, M 96 or S 64, all crisp, chosen by a fit rule. Resolved: 390×844 L, 375×548 M on first launch and S after an election.
    - **Commit on release:** that tap is the audio unlock.
    - **After an election:** "עוד סבב עם {short}" is the foot button and the Esc/back default. The flow is `EVOLVE_TX` → O3b flash → picker.
    - **The +10%:** one chip under the title, never on a tile (a percent beside a face reads as a poll).
    - **Undo:** a "להחליף ראש רשימה" chip for 5 s, until the first tap, after every pick. It reopens the same order and seat seed.
  - **FTUE:** the clocks start at the pick. P0 taps the leader (the prop pulses). At the pick Dubi says only `DUBI_LEARNED`; the firsttap squawk waits for the leader's first tap (H1L). `F9_PICK` is the strip line on the first after-election picker (`ftue.lp`).
  - **HUD:**
    - **Name:** no persistent label on the HUD (a name beside the seat numeral reads as a poll). The name shows in the round's lower third, the T4 header, O3 and the share cards.
    - **Bibi-only surfaces** (aide, pardon, Sara, the DOHA sticker, s07/s09/s10/s14/s15) are hidden in other rounds.
    - **The press skin** mirrors the court key by key; its chip widens to 220 for "יום תחקיר".
    - **Liberman:** a "לא יושב" pill under the pay pill.
  - **Strings (`gen_strings.py`, shipping-font widths):**
    - **54 new keys:**
      - `LEADER_PICK_*` (13), `F9_PICK`, `DUBI_LEARNED`;
      - `PRESS_*` (21);
      - `ELECT_LEADER`, `DOS_STATUS_LEADER`, `DOS_LEADERS`, `DOS_LEADER_*` (4);
      - `CHAT_PILL_DECLINE(_CD)`, `CHAT_SYS_DECLINED`;
      - `_LEADER` forms (5): the tap-frenzy chip and banner, spin effects s01/s02/s11;
      - `_NEXT` forms (3): the invite and the OG description/alt, which describe the picker or the lineup art, so they ship with them.
    - **Rewritten now to neutral, parameter-free text** (the engine calls these without `{verb}` today, and `Strings.s` would print it):
      - `SET_KEYS`, `EVO_RULE_2`, `OFF_NOTE_1(_PCT)`, `RET_CAP`, `SYS_OFFLINE`, `LOAD_2`, `SPLASH_LOADING`, `F1_TAP(_IDLE)`;
      - `ST_ALLTIME`/`ST_TAPS`/`ST_CRITS`, `DOS_TOTAL`, `SYS_ROTATE_CAP`, `SYS_ERA_PACK_LATE`, `CHAT_REPLY_3`;
      - `CHAT_SYS_CREATED`/`CLEARED` in the second person ("יצרת", "ניקית").
    - **Kept as Bibi-only, with notes:** `COURT_*`, `HUD_BPS_POUR` (s07), `AIDE_*`, `PARDON_ROW`, `DUBI_FIRSTTAP`.
    - **Lint additions:** worst-case `{short}`, `{party}`, `{verb}`, … are measured from `content.json` and exported to `worstCasePlaceholders`. The roster's short, party, blurb, rule text, kit words and squawks are linted against the new boxes (57 checks). 26 UI keys that mirror the designer's copy are drift-checked.
  - **Checks:** `gen_strings` 0 errors / 0 warnings (551 keys); `content-lint --strict` no errors; `tools/lint_text.sh` 574 checked, 0 failures; `tools/test.sh` 270/270; strict `tools/build_web.sh` green.
  - **→ game-developer (engine):** `test_share_view.gd:99` pins "ביבי" in the invite, so `SHARE_TEXT_INVITE` keeps its text; on picker ship day switch it to `SHARE_TEXT_INVITE_NEXT` and update the test. Swap the `_LEADER` / `_NEXT` keys at ship. Use a new sim key for the leader's own chat lines if any (never `CHAT_SYS_CREATED_M`: `sys_text` would pick it up today).
  - **→ game-designer:**
    - **(objection)** Bennett's `rule.text` "הרוב עולה ל־62" puts a seat count on the picker's leader card and T4, including during the 23.10-27.10 blackout, when the game removes its own seat numeral. Suggested: "…לרגע צריך עוד מנדט לרוב, ואז היא מתהפכת ומוסיפה לבסיס." (no digit).
    - A one-line `rule` for ביבי, so every leader card has the same shape.
    - Release wave-2 kits in bloc pairs (`shipRule`), so the balanced order always has a solution.
    - `DAYS_*` "ימי משפט" on the result card and deep link counts Bibi's court across mixed rounds: give it a leader-neutral count.
    - `PRESS_DAYS` needs a press-day stat.
  - **→ 2d-artist:** `pick_tile` (idle, pressed, focus, selected rim), `pick_random`, `thermo_icon_press` 11×11 and `chip_icon_press` 9×9 (a folded newspaper). Confirm the party grey on the tile fill is ≥ 4.5:1.
  - **→ animator:** the walk-in moves from `EVOLVE_TX` to the pick (D30); the walk-out stays.
  - **→ audio:** the `leaderPick` sting is now the game's first sound.
- **Orchestrator, 2026-09-29: UX's objection against `leaders.bennett.rule.text` is accepted and resolved.** The rule no longer puts a seat count on the picker card or T4 (a digit by "רוב"/"מנדט" reads as a poll, and it survived the blackout). New text: "…לרגע צריך עוד מנדט לרוב, ואז היא מתהפכת ומוסיפה לבסיס." The 62 stays in the rule's `_note`. **Open → game-designer:** extend the poll-number lint to "רוב"; a one-line `rule` for ביבי; a leader-neutral count for the result card's `DAYS_*`; **→ sim:** a press-day stat for `PRESS_DAYS`.

- 2026-09-29 · technical-artist + 2d-artist · **Leader select art: the generic tap rig, every leader's tap, the kit pieces and the lineup key art** (spec §9.1-9.3, Bar's §12.4).
  - **Rig:** an optional `tap` recipe per cast entry (`showcase/src/cast.py` `TAP_DOC`: hand or `beside`, arm swing, head lean, region nudges, prop path, `baked`) renders an 8-frame `tap` (15 fps, `coins` on 3) from Bibi's squash table (`build.py` `TAP_SQUASH`), and exports `propMouth` + `temple` on every anim (idle, the react that is the crit, tap) at d 3 and d 2. Point tracks are found by shape, not name (`same_motion`, `sprites.is_track`); the trimmed frame grows to hold every point; an alternate's point past ½ art px is snapped to the main render's (`snap_tracks`, worst 0.50). `chars[c].prop` = `{id, baked, track, path}`; Bibi's `propMouth` = `hatMouth`. CONTRACT §4c.
  - **Taps:** Bennett (pen, signing stroke), Ben Gvir (phone, thumb), Smotrich (calculator jolt, baked), Deri (cup lift, baked), Eisenkot (ruler floating at the chest line, hops), Liberman (the chair stands on the floor beside him, pushed away: a floating chair read wrong), Golan (stapler in the hanging hand). Bibi's tap is unchanged. Frame sizes and per-leader VRAM: CONTRACT §4c.
  - **Drift:** full render 0 changed; `atlas.json` only gained keys. New in `out/`: 14 tap strips, `source_advisers` (qatari with a slate folder: `rig.py` `recolor`), 16 neutral-ring picker avatars.
  - **2D pieces (`art/od-sevev/src/leaders.py`, proof `proofs/kit-leaders.png`):** 7 tap props (`prop_{pen,phone,chair,ruler,calculator,coffee,stapler}`, ≤ 20×20, rest + squash, `pivot` on `propMouth`, `points.mouth`), `source_donor`, `source_funds` (+ icons, silhouettes), `suitcase_plain`, `spin_slot_{A,B,C,D,E,G,H,I}`, and the picker to UX §8.3-8.4: `pick_tile_{idle,pressed,focus,selected}` (party grey 5.2:1 on the face) and `pick_random`, plus UX's `thermo_icon_press` / `chip_icon_press` (a folded newspaper). The chat avatars' react-coloured rings read as party or bloc colours on a picker, so the tiles get `avatar_pick_<c>` / `avatar24_pick_<c>` (one neutral ring).
  - **Key art:** the 8 leaders in Hebrew-alphabetical order read right to left, the seam between the 4th and 5th on the centre line (nobody centred), the wordmark on top, Dubi, coins and blank slips. A loose prop is drawn only where it covers no neighbour. `game/web/og.jpg` is 1200×630, 203 KB. The icon is the 8 heads in a ring around the gold loop; the app icons are re-imported. Checked for October 7 echoes: none.
  - **Budget:** the resident body is the round's leader (`budget.json` `vramLeaderByK`); Bibi is still the heaviest. Typical VRAM is 12.30 MB (k 3/6/7/9) and 6.64 MB (k 2/4/8), was 12.05 / 6.45. Web `.pck` art is 5.29 MB (was 4.48): the tap strips are +0.77 MB.
  - **Checks:** `tools/test.sh` 270/270; strict `tools/build_web.sh` green. Shots: `scratchpad/shots/leaders-art/`.
  - **→ game-designer:** set `kit.tap.anim` = `"tap"` for the seven (it is `null`); mark `sourceTiers.genericSprites` t4-t6 and `suitcase.plainStatus` shipped.
  - **→ UX:** the live `OG_IMAGE_ALT` still describes Bibi with the hat, and `OG_IMAGE_ALT_NEXT` has "קלפי באמצע", which the art leaves out on purpose. Suggested: "שמונה ראשי רשימות בפיקסלים עומדים בשורה על במה, מעליהם הכיתוב עוד סבב".
  - **→ game-developer (views):** draw the kit prop at `propMouth` unless `prop.baked`, using frame 1 on pointer-down; coins spawn from `points.mouth` or `propMouth`; the picker uses `avatarPick` / `avatar24Pick`; the press skin uses `thermo_icon_press` / `chip_icon_press`; outside Bibi's round use `suitcase_plain`. No `game/scripts` change here: `SpriteStrip.point()` already reads any track by name.

- **Audio Director, 2026-09-29: cue-spec v1.3, covering leader select and the session-2 views (`audio/od/cue-spec.md` §2.6, §3.1, §4.1, §4.2, §7).**
  - **Coverage audit:** every session-2 view and modal now has a cue or is silent on purpose (`Audio.SILENT`). A test scans `res://scripts` and fails on any sent event that is neither.
  - **New cues** (own families, so no shipped file changed):
    - `leaderPick`: fanfare material (roll, C#-D lift, downbeat on i), 843 ms, burst −15 LUFS;
    - `critReact` whoosh / shout / no / land;
    - `decline` and `merge`;
    - `suspicionHot`, at the 75 % crossing;
    - `chatPing:brawl`.
  - **Behaviour:**
    - `firstSound` cues (`leaderPick`, `returnAway`) play before the first-tap gate and are held through a locked iOS context. The first tap still plays the motif.
    - `returnAway` was silent after every reload; it is fixed.
    - Press day opens with the shutter.
    - `gameReset` fades the music over a bar and closes the gate.
    - Every leader's squawks have canned contours.
  - **API:**
    - `Audio.event("leaderPick", id)`, `set_leader(id)` and `crit_for(id)`, which returns `{event, cue, variant, delayMs, …}`, for all 8 leaders;
    - `event("heroEvent", ev)`, `squawk_text(id, kind)` / `event("squawk", kind)`, and `route(name)`.
  - **Hooks** (shared files):
    - `main.gd` `_do_reset`: 1 line;
    - `view_chat.gd`: 2 lines (brawl → `chatBrawl`);
    - `view_thermo.gd`: 3 lines (`suspicionHot`).
  - **Size:** `index.pck` +207,520 B (+1.1 %); the audio folder is 11.06 MB, under the 11.3 budget.
  - **Checks:**
    - `tools/test.sh` 309/309;
    - strict `tools/build_web.sh` green;
    - `tools/audio.sh --check` deterministic.
  - **→ game-developer (views):**
    - call `leaderPick` on the commit;
    - call `decline` / `merge` on the new pills;
    - send the leader's react event through `heroEvent`, and `set_leader` on install and load;
    - switch the first-tap babble to `squawk_text(leader, "firsttap")`.
- 2026-09-29 · animator · slice 1 of the re-run (court day, the view motion audit, the brawl boil) · `game/scripts/ui/court_motion.gd`, `court_echo.gd`, `leader_walk.gd`, `big_banana.gd`, `toasts.gd`, `views/view_chat.gd`, `views/view_thermo.gd`, `main.gd`, `motion/motion-audit-2026-09-29.md`, `tools/web/motion_web.mjs`
  - **Court day (Bibi only):**
    - The exit and return are built to `state-graph-magician.md` §1.3/§3/§5 in `CourtMotion`, a pure timeline read by `BigBanana`: the startle, the zip left with smears and dust, and the hat hovering on his mark and taking the taps (hop and coins; a crit raises the rabbit). Then the fetch, the empty beat, the zip back and the land. There are early and quick returns, and a reset cuts him home.
    - It is polled from the sim's phase and gated on `Leaders.has_court()`. The summons flinches him.
    - The sweat no longer beads on the empty stage.
    - The `court_window` echo: lit at ≥ 75 %, a steady halo at ≥ 95 %, and while the summons or the court day is open the window breathes 100 → 60 → 100 % every 1.6 s (0.63 Hz). It is lowered under the toast dock where the flex rule crops the art's top rows.
  - **Audit:** the table is in `motion/motion-audit-2026-09-29.md`.
    - Fixed: the pending chip and the brawl cue ease in instead of popping; toasts ease in and fade out on scene time; the brawl cloud boils (8 fps plus a whole-px 1-ap ring with a rest).
    - **Bug fixed:** the web game never followed `prefers-reduced-motion`. The 4.7 bridge returns `1`, and `== true` is false (`MainController.js_bool`).
  - **Prepared, not wired:** `LeaderWalk`, a walk that takes a leader id (560 ms out, 640 ms in, stepped bob; reduced motion fades), for the EVOLVE_TX swap.
  - **Dev params:** `&court=N` (a court day at boot) and `&slow=N` (Engine.time_scale), for `tools/web/motion_web.mjs`.
  - **Checks:** `tools/test.sh` 323/323 (+14); strict `tools/build_web.sh` green; `motion_web.mjs` PASS (390×844@2, motion and reduced motion). Shots: `scratchpad/shots/motion/`.
  - **→ game-developer:** `view_court.gd` is untouched. The court-day stage follows `Leaders.has_court()`. Call `LeaderWalk` from EVOLVE_TX when the picker lands (the Animator's slice 2).
  - **→ 2d-artist:** the kit's `court_window` spots sit in art rows the flex rule crops on phones. A spot at or below art row 110 would keep it in place. The ×2 brawl cue still wants a 26×20 cut at ×4.

- **Game Developer (views and engine), 2026-09-29: the leader picker is real (`LEADER_PICK`, spec §3 / §10, rtl-map §8, screen-graph §0).**
  - **The picker** (`ui/views/view_pick.gd`): the 3 × 3 face grid with הפתעה in the centre, the bloc checkerboard shuffle, the caption strip, the again button and the fresh chip after an election, the long-press / `I` leader card, the keyboard, Esc/back and reduced-motion paths, and the 5 s undo chip. It replaces the title on a fresh game and after a reset. It follows O3 → EVOLVE_TX → the flash, and it comes back after a reload mid-pick. One rule in `main.gd` `_check_pick` covers all of these: open whenever `Leaders.pick_pending` holds and nothing else is up. The economy is frozen while the pick is pending, and the pick is saved before the stage returns.
  - **Per leader** (`ui/leader_ui.gd`): the stage figure and its tap prop at `propMouth` (only the round's leader is resident), the crit word and react, and the press skin for everyone but Bibi. The pardon row, aide and DOHA sticker are hidden outside his round. Source and spin skins, the leader's own story beat and first-tap squawk, Liberman's "לא יושב" pill, and Golan's "לאחד" pair prompt.
  - **Strings:** the `_LEADER` keys are drawn. `SHARE_TEXT_INVITE`, `OG_DESCRIPTION` and `OG_IMAGE_ALT` take their `_NEXT` texts (through `gen_strings.py`), and the shell reads the OG keys. New keys `CHAT_PILL_MERGE`, `CHAT_PILL_MERGE_CD`, `MERGE_PICK_TITLE` and `CHAT_SYS_MERGED` mirror `leaders.golan.rule.copy`.
  - **Audio v1.3 hooks:** `leaderPick(id)`, `set_leader`, `heroEvent`, `squawk_text`, and the `decline` / `merge` cues.
  - **Checks (after merging audio v1.3 and the Animator's court-day slice):** `tools/test.sh` 337/337 (`test_leader_pick.gd` +14); strict `tools/build_web.sh` green. `tools/web/picker_web.mjs` covers the first picker, the card, a pick of בנט, tap 1, the election, the picker after it and a reload mid-pick, then a pick of ליברמן. It passes at 390×844, and the first picker at 375×548 draws the M avatars. Shots are in `scratchpad/shots/picker/`.
  - **Still open in spec §10:** the sim line (the sim developer's; Next 2 verifies it), plus §10.2 `neutralCopy` and the facts' `notUsed` flip (both Designer content).
  - **→ Animator:** the walk-in/out and Dubi's fly-in are placeholders: the leader fades in over 250 ms, and Dubi's line is a bubble at (644, S−232). `LeaderWalk` stays unwired, because `_apply_court_pose` sets `hero.position` every frame and would override a walk. `set_leader` now rebuilds your court nodes for each figure.
  - **→ Game Designer:** Liberman's `pick.blurb` puts "61" on the picker, which spec §3.2 says should show no numbers.
  - **→ UX:** Golan's pill is on the partner card with a pair prompt, because §6.3 has no layout for it; the result card's sub-line names the leader.

- **UX Designer, 2026-09-29: the mobile-first layout spec (`ux/mobile-first-layout.md`).** Bar: "the mobile layout isn't good; it must be mobile first."
  - **Verified** at build `af18f9e` plus the picker, on the pixels:
    - Row B's empty slot (25 art);
    - the Suitcase lane (a 2×28 stripe tile, 24 art);
    - the empty pane plus the unrevealed tab slot (up to 73 art at 430);
    - the SE's cut card (86 px, half a pill);
    - the ticker crawl cutting words (no headline fits its 324 clip);
    - the 720 column leaving side bands;
    - the picker's 65-art band under a centred grid (my own rtl-map §8.2);
    - the pre-tap floor (45% of H).
    - "Only 4 rows" is content, not a cap.
  - **Rules:**
    - k is unchanged. The layout fills `floor(W/k) × floor(H/k)` art. Chrome is fluid with anchors; the stage is a centred column.
    - The bottom-up split: the tab bar is pinned, the pane holds whole cards plus a 40-px peek, and the stage stays near 160 art. A reach guard keeps the leader's hit bottom at ≥ 40% of H.
    - Reserved slots never show empty: Row B shows the sky until C2, the pane covers the tab slot until C1, and dim silhouettes fill the pane.
    - The ticker shows 2-line pages of whole words.
    - The counter goes to ×6, and the pill grows with a ×5 price.
    - The picker grid is bottom-anchored, with fluid tiles and 192 avatars.
    - Modals sit at 55%. The share sheet gets the full height, with WhatsApp nearest the thumb.
    - Per-device tables for 12 viewports.
  - **Golan's "לאחד":** the partner card is right as the second entry. Add a merge-ready system pill in the thread (§5.5).
  - **Tools:**
    - `tools/web/mobile_web.mjs`: baseline + spec checks over the 9-device matrix. Today: `PASS (baseline; 108 spec checks open)`.
    - `ux/tools/mobile_layout.py`: the reference numbers.
    - `ux/tools/mobile_mockup.py`, which writes `ux/mockups/mobile-first-*.png`.
  - **→ game-developer:** implement §8 (display.gd `cols`/`rows`/`cw()`, `L.split`, anchors, pager, picker, silhouettes, `odDisplay.cw/ticker`, `odPick.tile/grid`). Done = `mobile_web.mjs` green.
  - **→ 2d-artist:** A1 textured lane + plaza apron (Balfour first), A2 stage wings, A3 d3 96×96 pick avatars.
  - **→ game-designer:** G1 `producerReveal.fillSilhouettes`.
  - **→ animator:** M1 the ticker page push, replacing the crawl cadence.
  - No objection outstanding.
- 2026-09-29 · game-designer · **leader-sim review, balance, the 34-vs-8 gap, R17, Bibi's rule, the רוב lint, neutral DAYS_*, G1 fill, the picker blurb.**
  - **Sim core review (`leaders.gd` + 31 tests):** install per leader, knobs, filters, save v4 migration, the +10% switch and Bibi's shipped lineup all hold to the spec. Defects: (1) the cache key `"\u0000"` printed "Unicode parsing error" on every run: now `""`, and `tools/test.sh` fails on that error; (2) Liberman's rounds 2+ had no seat that unlocks after election 1 (own 28 + 40 < 61 without L6), so his median hour's round 2 ran 9:09 after a 7:09 round 1 (S5 fail): a fourth generic MK "ח״כ שחזר הביתה" on SK (capacity 46, 44 in round 1; round 1 untouched); (3) implementing the p_deal perk in `demand_price` (it did nothing before) changed Bibi's later rounds and flipped `test_politics_balance` G1 on its single seed (aide dropper +52% on seed 11, −8% on seed 12; before the change it was −42% / +38% on seeds 11 / 13): G1 is now the median per-seed ratio over seeds 11-15 (aide dropper 1.02, always-postpone 1.02), G2-G4 unchanged.
  - **Balance** (`tools/balance.sh` suites, all green): first election, median of seeds 1-9: ביבי 8:01 · בנט 8:08 · בן גביר 8:19 · ליברמן 7:51 · אייזנקוט 8:50 · סמוטריץ׳ 8:06 · דרעי 8:05 · גולן 8:30; Bibi's `test_session` 4/4 (median 8:01, engaged 7:28, casual 7:35, idle 10:07), leaders 4/4, politics 1/1, mixed hour pass. Table and levers in `design/leader-select-spec.md` §7.2.1. Watch: Eisenkot (8:50, casual 9:00) and the worst Bennett / Ben Gvir deals (> 10:00).
  - **34 vs 8 min:** neither the game nor the bench is wrong. `round_web.mjs` acts in wall-clock time while `?speed=10` runs the game 10× faster; measured in game time it taps 0.037/s (median player 1.5), buys every ~138 s, looks at the chat every ~300 s, never buys a spin or catches the Suitcase. The driver now prints that cadence; `PacingSim` takes optional cadence keys (defaults unchanged) and `tests/bench/test_web_driver.gd` replays it: bench 30:18 vs browser 25:16 (today's run), median player 8:01.
  - **R17:** `producers[].slot` re-placed (12 slots, 2 for tiers 1-4, 1 for 5-8): no sky row (it put 88 px of a source under Row B), nothing under the thermometer column, the shared tiers' first critters right of the Magician, the first taxpayer clear of his hit (x 188-564 in `L.MAGICIAN`, not the review's 172-548). `test_diorama_slots.gd` checks it with every leader's generic sprite. Objection below on the rest of R17.
  - **Also:** `leaders.bibi.rule` "המשפט" (lint: every leader has rule name + text); poll-number rule on "רוב" as a whole word (61 / 120 pass; קרוב, סירובים never match), About page included; DAYS_* = "ימים בכותרות", counting court + press days (`Investigation.hazard_days`); G1 `producerReveal.fillSilhouettes` + `Economy.producer_rows(s).fill`; Liberman's blurb "צריך 61" → "צריך רוב", and the lint fails any digit on a picker tile.
  - **Objection → game-developer (engine) / UX, R17:** sources are 101-200 logical wide; right of the hit is 156 px and between the thermometer and the hit 56 px, so one critter at most clears both. **Alternative:** accept back-row critters behind the Magician (they are drawn behind him and take no input); clamp `Diorama._add_crowd` x (24-632 today) to the thermometer column's right edge + the sprite's half-width; for more clear room, anchor the rows to the stage bottom or add right-wing xs, and I re-place the slots.
  - **Checks:** `tools/test.sh` 340/340; `node design/sim/content-lint.mjs --strict` 0/0; strict `tools/build_web.sh` green (text lint 575/0); `round_web` PASS (390×844 @2, speed 10).

- 2026-09-29 · 2d-artist + technical-artist · **the art the mobile-first layout needs** (`ux/mobile-first-layout.md` §10 A1-A3, the Animator's two asks) · `art/od-sevev/src/wave7.py` (new), `wave5.py`, `wave2.py`, `creative-pack/art/showcase/src/build.py`, `pipeline/od-sevev/sprites.py`, `game/scripts/ui/diorama.gd`, `court_echo.gd`, `main.gd` (1 line), `game/assets/sprites/CONTRACT.md`, `art/od-sevev/style-guide.md` §17.1
  - **A1:** `lane_<era>` redrawn 32×28 (same ids; joints, the press cable, a flyer; every swatch ≥ 4.5:1 vs the Suitcase rim). New `plaza_<era>` 128×96 tile from art row 258 down, over the flat apron. No lane or plaza row is one colour.
  - **A2:** `wing_<era>_l` / `_r`, W×230 (art rows 0-229; W: balfour 20, knesset 22, courthouse 60, washington 36), seam-exact against the art's edge and themselves.
  - **A3:** `avatar_pick_<c>_d3` 96×96 and `avatar_pick_<c>_d2` 64×64 for the 8 leaders (`chars[c].avatarPickXL`, the key the picker WIP already reads, / `avatarPick64`), drawn at 2 logical per sprite px (A 192 / A 128). Full render: drift 0 changed.
  - **Animator:** `brawl_cloud_cue` 26×20 ×4 frames (draw at ×4). `court_window` spots are now kit data (`ui.court_window.spots`): Balfour (167, 167), Knesset (158, 166), Washington (162, 152), house tops at art rows 146 / 145 / 131.
  - **Engine (data-driven readers only):** `diorama.gd` `_place_wings` / `_place_plaza` (no piece: nothing drawn) + `floor_reach()`; `main.gd` starts `_title_floor` below the plaza; `CourtEcho.spot` reads the kit spots (SPOTS stays the fallback). Tests updated: `test_motion_court` (spots from data, ≥ row 110), `test_review_engine` R16 (the plaza is the floor).
  - **Budget:** web `.pck` art 5.34 MB (+44 KB); `budget.json` typical 13.20 MB at k 3/6/7/9, 7.54 MB at k 2/4/8 (+0.90 MB) (it counts every kit piece and avatar resident; really one era's lane + plaza + wings ≤ 0.2 MB, and one XL avatar size only while picking).
  - **Checks:** `tools/test.sh` 340/340; strict `tools/build_web.sh` green (content lint 0 errors, text lint 0 failures); `mobile_web.mjs` (baseline) PASS at 430×932@3 and 375×667@2, and S8 "pre-tap" now passes at the SE (at 430 only the flat sky above the art's row 0, under the hidden Row A, is left). Sheets: `scratchpad/shots/mobile-art/`.
  - **→ game-developer:** keep `diorama.extend(…)` feeding `_extend_x` (the wings and plaza fill to ±_extend_x from the stage column; with `stage_ox = floor4(dx/2)` pass the column's own offset). Your WIP (handoff-wip mobile patch) has two interim stand-ins for A1 to drop now: the lane-joints overlay in `_place_lane` (it would double my joints) and the procedural paving `_title_floor` (it sits above `_stage` and would cover the plaza): start it at `stage bottom + diorama.floor_reach()` or hide it when that is > 0. The `_title_floor` line in `main.gd` is my only main.gd change (1 line), so the conflict is trivial. Picker: A 192 → `chars[c].avatarPickXL` (your WIP key; the file id is `avatar_pick_<c>_d3`, not `avatar_pick_xl_<c>`) at ×2 logical/px; A 128 → `avatarPick64` at ×2; A 96/64 → the 32 as today. Brawl cue: swap `Art.sprite_or("brawl_cloud")` ×2 for `"brawl_cloud_cue"` ×4 in `view_chat.gd` (same 104×80 box, same frame count).
  - **Flag:** `stage_washington` has 277 transparent px (rows 154-169 beside the trees) since the approved render; the padTop sky shows there. The wings match it. Not changed (it would be stage drift).

- 2026-09-29 · 2d-artist + technical-artist · **palette v3: Israel's blue and white** (Bar: "the design should be more in Israel's palette, with blue and white") · `art/od-sevev/src/palette.py` (+ `creative-pack/art/src/palette.py`), `ui_controls.py`, `ui_chat.py`, `wave2.py`, `icons24.py`, `leaders.py`, `proofs.py`, `art/sprites.ts` → `game/data/art.json`, `design/content.json` (Balfour skyBands), `game/web/shell.html`, `art/od-sevev/palette-v3-map.json` + `tools/apply_palette_map.py` (new), style guide §2.2, §2.3 (new), §11.4, §16 F10-F13
  - **Palette:** 7 ids re-valued in place from plum/violet to a navy family at v2's luminance (±.015): `ui_scrim` #061029, `ui_panel` #0a1a42, `night` #0f2350, `ui_bubble` #112a64, `ui_bub_hi` #26499c, `plum` #16357a (velvet-blue curtain), `plum_hi` #2a57a6; new `ui_mute` #a3b3d3, `ui_rule` #1c3876. 64 swatches. Gold (money, the buy pill), red (alerts), flag/sky/white, `ink`, `outline`, `rim` and stamp violet unchanged.
  - **Art:** the kit re-rendered (255 pieces, same ids and sizes): the modal title band in flag blue with a white stripe; white-over-flag stripes on the tab bar, the ticker (was red) and the chat header; pink UI accents → blue. Balfour's sky is navy (`stage_balfour`; `stage_washington` a 1-row rule); icon and OG on the velvet-blue stage (`game/web/og.jpg` 209 KB). The fork letters (settings' cream card): grape/violet/lavender/pink → navy/flag/pale blue/sky. Full render: **0 drift** (the two stages were regenerated from source first; the cast untouched).
  - **Code map:** 17 pairs; 28 literals on 26 lines in 13 `game/scripts` files listed in `_sites`, **not applied** (the mobile-first rewrite). Applied to the shell (19 literals + the gate/About heading rule, load bar fill → flag_hi). **→ orchestrator:** after the mobile merge, `python3 tools/apply_palette_map.py`, then `--write`, then `--check`; `game/project.godot` (boot splash, clear colour) is listed in `_alsoElsewhere`.
  - **Contrast:** all 45 kit pairs pass (0 fails); white on flag 8.5, on ui_bubble 12.4, red_hi on ui_bubble 4.7, ui_mute on ui_bubble 6.5, sky crawl on ui_scrim 10.0, flag on cream 8.5; gold on white 1.48 (needs its outline, 17.9). Rule: never blue text on navy (flag 1.6-1.8, flag_hi 4.4).
  - **Buy pill tested:** stays gold (10.4:1 vs ui_panel, the only warm hue; a flag pill would be 1.47 on ui_bubble). No objection.
  - **Mock-ups:** `scratchpad/shots/palette-v3/` (main, picker, settings modal, chat, gate, phone frame; before / data-only / + code map at 390×844@3).
  - **Checks:** `tools/test.sh` 340/340; strict `tools/build_web.sh` green; `mobile_web.mjs` baseline PASS at 390×844@3.

- 2026-09-30 · 2d-artist + technical-artist · **palette v4: the flag's layout and Israeli election material culture** (Bar on v3: "More Israel theme and palette") · `art/od-sevev/src/palette.py`, `ui_controls.py`, `wave2.py`, `wave5.py`, `wave7.py`, `wave8.py` (new), `keyart.py`, `proofs.py`, `art/od-sevev/palette-v4-map.json` (replaces the never-applied v3 map), `tools/apply_palette_map.py` (perFile), `game/web/shell.html`, `game/tests/unit/test_modals.gd` (the About link colour), style guide §2.4, F14-F15
  - **Layout (kit + map):** HUD = a flag-blue band; the stage on Jerusalem-stone lanes/plaza; the ticker = a blue news strip; the card pane = the white field; cards flag blue (`ui_bubble` #1045b5, white text 7.5:1, gold pills 5.1:1) with the icon on a white ballot slip; the tab bar deep flag blue. Navy only for wells and behind the stage.
  - **Palette v4 (66 swatches):** `ui_panel` #072a7a, `ui_bubble` #1045b5, `ui_bub_hi` #4f82e8, `ui_mute` #c9d6f2, `ui_rule` #2a5cc4, `stamp_lt` #d8ccff, new `ui_dim` #b4c3e8, `alert_lt` #ffaa9f.
  - **Material culture:** `sheet_modal` = the blue envelope (a pointed flap); `card_plate` = a blank ballot slip; new `hemicycle_track`/`_fill` (120 seats, RTL fill order, goal 61), `booth_frame` (the picker's cardboard booth), `envelope_blue`; the gate and About = white notices ruled in flag blue; primary button with a white edge.
  - **Key art:** the icon's flag-blue disc in a white ring; the OG on a stone floor with white/flag rules and blank blue envelopes among the slips. Stages and cast untouched (full render 0 drift).
  - **Rejected, with evidence (sheets):** light cards (gold pill 1.48:1 on white, the slip merges, and it needs per-view text flips); v3's navy; a white HUD (gold 1.5:1); blue or slip buy pills; the desktop page as the flag (the phone where the star sits).
  - **Map:** 17 pairs + perFile roles (main.gd, ticker.gd, view_share.gd); 38 literals in 15 `game/scripts` files, **not applied**. **→ orchestrator:** the v4 kit must land with the map (without it the scripts' text is 2.2-3.5:1 on the new blues): after the mobile merge run `tools/apply_palette_map.py`, `--write`, `--check`. **→ UX / engine:** place the hemicycle, the booth frame and the envelope (F15); never put text straight on the white pane.
  - **Mock-ups:** `scratchpad/shots/palette-v4/` (main with the rejected light-card test, picker, settings, chat, gate; v2 / v4 build / v4 + code map as a labelled pixel re-value).
  - **Checks:** `tools/test.sh` 340/340; strict `tools/build_web.sh` green; `mobile_web.mjs` baseline PASS at 390×844@3 (one run flaked, the rerun passed).

- 2026-09-30 · game-developer · **the mobile-first layout, implemented; Bar's width rule; palette v4 landed** (`ux/mobile-first-layout.md` §8 1-7, screens §3-§7 and §5.1-§5.13; §9.2 ticked). Bar: "the mobile layout isn't good; it must be mobile first" and "make sure the UX/UI fills the phone's width".
  - **Engine:** `Display.cols/rows/cw()` (k unchanged); `L.split()` (whole cards + a 40-px peek, the reach guard) replaces the flex rule; `L.cw/dx`, `L.canvas_w`, the anchors `ra/ca/sa/rx/cx`, `sox()`. The chrome sits at the canvas origin (`_ox` 0 on a phone), the stage column at `_sx = floor4(dx/2)`. The tab bar is pinned to the safe bottom and slides up at C1; before C1 the pane runs under its slot; Row B's fill only from C2. `odDisplay` gains `cw/S/P/rows/sx/ticker`, `odPick` `tile/grid`, `odDev` the card span and the top overlay's rect.
  - **Views:** Row A counter ×6 in stretched boxes, the cottage and Row B label R; the ticker pages (2 lines, whole words, dwell 3.5 s / 55 ms a char; the cross-fade until M1 — the push is built behind `PAGE_PUSH`); cards 688 + dx with the R side, the pill + min(dx, 40), the price ×5 where it fits, teaser rows from `producer_rows().fill`, four floor4(cw/4) tab slots; toasts stretched, no toast hit during a tap burst; the Suitcase band; T3/T4 full width (incoming R, replies L, system pills centred); the court card 688 + dx; the thermometer L; modal cards at 55% of a tall band, ≥ 24 over the tab bar; settings and share full-bleed sheets (share: the whole safe height, WhatsApp nearest the thumb); the O3b flash bottom-anchored; EVOLVE_TX centred; the picker bottom-anchored (fluid tiles, A 192 on even k, the title on the grid).
  - **Width rule (Bar):** modal cards and the flash are ≥ 92% of the canvas (a floor4(3.5%) margin; body text keeps the ≤ 624 measure). `mobile_web.mjs` runs the game with a sentinel clear colour (dev `&clear=1`) and a sentinel page background and fails any shot whose left or right 3% shows it; it also checks the card gutter (≤ 4 art px), the settings sheet and the picker grid (≥ 92%). It keys on "not the background", so it holds under v4.
  - **Golan (§5.5):** `CHAT_SYS_MERGE_READY` "{a} ו{b} יכולים להתאחד" + the לאחד pill (536 × 88) in the thread, once per ready stretch (≥ 120 s apart), opening the MergeCard with that pair first.
  - **2D art wired:** the lane, plaza and wings (the engine's lane joints are gone; its paving floor only backs the plaza past `floor_reach()`), `avatarPickXL` at A 192 and `avatarPick64` at A 128, `brawl_cloud_cue` ×4.
  - **Palette v4:** merged `worktree-agent-a5e8cafeb35582361`; `tools/apply_palette_map.py --write` (38 literals, 15 files, per-file roles), `--check` clean. Beyond the map, by role: the chat/dossier scroll thumbs (lavender → ui_mute); the '?' placeholder's slate fill as `Color8` (a fill, not the slate-text role the map lifts); teaser rows as the locked card at full opacity on the white pane (F14). Generators re-run: no diffs.
  - **R17 engine items:** `Diorama._add_crowd` clamps x so a crowd sprite (+16 when it wanders) clears the thermometer column; the ground rows (B, F and their crowd) are anchored to the stage bottom (design y at S 640, moved by S − 640). No right-wing xs: the wings are scenery outside the 720 stage art, and the anchoring was what the split needed (at S 460-512 the F row fell under the ticker).
  - **F15, room only (not placed):** the hemicycle (72×38) fits Row B (84) only at ×2 (seats 2 CSS px); at ×4 it needs a 38-art row (T3's header area, or a C2 band costing 152 logical of stage). The booth frame (9-slice margins 24/40/24/16) fits around the picker grid on tall phones (176-268 of sky) and costs the SE / toolbar viewports ~20 px of tile height and 16 px of tile width. `envelope_blue` (14×10) fits anywhere.
  - **Deviations (engine):** the pill grows from the built 168 (the spec assumed 184), so big prices step to ×4 below 8.88mm; the coalition agreement (Perks) and the fixed-rect overlays (partner card, pardon desk, confirms) stay 624, centred; a landscape window keeps a ≤ 0.75·H canvas, centred. **Spec error fixed in the engine:** §5.8's `avail` omits the 12 above the strip and counts 12 (not 16) under the title, so where tiles fill avail (the SE, toolbar viewports) the title rode into the wordmark; the tiles give back those px (SE th 320, not 328).
  - **Web checks updated:** res/views failed since the picker merged (they tapped the Magician through the grid; same on the pre-mobile build): they pick הפתעה first. share_web picks ביבי (one context, one save; a random leader had no brawl) and accepts the leader-neutral invite. modals_web: About's links are v4 flag blue. picker_web re-checks the live gate around the election confirm. Tabs aim at floor4(cw/4) slots, the cottage at 668 + dx, motion's stage rect at `sx`.
  - **Checks:** `tools/test.sh` 353/353 (new `test_mobile_layout.gd`: grid, width, split, tab slots, picker plan, ticker clip, pager, modal and share scale against `ux/tools/mobile_layout.py --json` for all 12 devices, plus the scene booted at 4 phones; `test_leader_pick` covers the merge-ready line); strict `tools/build_web.sh` green; `mobile_web.mjs` **PASS on the whole matrix, 0 baseline / 0 layout / 0 width failures, in v4**; res, views, modals, share, motion PASS; `round_web` PASS on the mobile build before the palette (b827500); on v4 three runs lost the gate to the driver (a walkout at ×10 under the election card, a random leader's round out of budget, one page navigation), not the layout, and the driver now retries the gate; `picker_web` passes the pick, the leader card, the undo and tap 1, then its Bennett round never holds 61 at ×12 in the driver's budget (the same stall on the pre-palette build), so the after-election steps stay unverified in the browser (the unit tests cover them)
  - **Before/after:** `scratchpad/shots/mobile-after/compare.png` (v4; `compare-v2-palette.png` is the same pass before the palette): 375×667@2, 390×844@3, 430×932@3, 412×915@2.625 × pick, pre-tap, card 1, C1, T3, settings.
  - No objection outstanding.

## 2026-09-30, Animator wave B: the leader walk wired, M1 (the ticker roll), the slip stamp
- **LeaderWalk wired** (`motion/state-graph-magician.md` §9):
  - **Walk-out:** the old leader walks off screen-right (560 ms Sine.In, 1-ap bob) as the EVOLVE_TX card lifts (new `walk` cue at t 1200), before the flash or the picker. Input stays locked until he is off (t 1760; +260 ms on the 1.5 s ceremony, and the music cue is still on time). Reduced motion: a 150 ms fade on the mark at t 1000, no tail.
  - **Walk-in:** after the pick, from screen-left to the feet point (640 ms Sine.Out). It replaces the 250 ms placeholder fade. Dubi's line follows the landing (+120 ms, 1280 ms after the commit). The undo mid-walk and "again" both walk in from off-stage.
  - **The conflict is resolved:** `BigBanana._apply_figure` is the one writer of the figure's position, visibility and alpha (mark + court offset + walk offset). The court yields while a walk runs (courtStart latches until the landing), and a walk-out cuts a court day home.
  - The swap is 1.2 s of leader motion, within the 1.5 s budget.
  - The seam drops the old round's pending pick lines and Dubi's bubble.
  - Dev: `window.odDevElect = 1` forces the ceremony (no 61 gate) for the strips.
- **M1, the ticker:**
  - **A roll, not UX's push:** the next page rises as the old one lifts, 240 ms Cubic.Out, 4-px steps, the pages locked one row apart. The x never moves, so no Hebrew prefix fragment ever shows at a clip edge (a deviation from §5.2's push, argued in the audit). Reduced motion keeps the 200 ms cross-fade.
  - **The dwell is per page by length:** a first page 1.2 s + 70 ms a character, a continuation 0.5 s + 70 ms, 2.0-5.5 s; FTUE 1.5 s + 85 ms, 4.5-7.0 s. A median headline now takes 4-6 s (was 7.0; every page sat on the old 3.5 s floor). Measured on 275 lines by `game/tests/dev/ticker_pages.gd`.
- **The v4 slip stamp:** a spin card's tag on the `card_plate` slip slams in at ×6 → ×5 → ×4 over 90 ms when it appears or changes on the same card; reduced motion cuts.
- **Envelope flap:** not built; it needs art. The ask to the 2D Artist is a 3-frame `sheet_modal_flap`, in the audit.
- **Checks:**
  - `tools/test.sh` 368/368 (new `test_leader_walk` 9, `test_ticker_roll` 4, `test_slip_stamp` 2; the mobile-layout dwell check retuned);
  - strict `tools/build_web.sh` green;
  - `tools/web/motion_web.mjs` (new walk + ticker sections, duration-based strips) PASS at 390×844@2;
  - `mobile_web.mjs` PASS at 390×844@3 and 375×667@2 (one C1 probe race on the first 390 run under load; the rerun passed).
- **Strips:** `scratchpad/shots/motion-b/`: walk-in/out (+ `-rm`), the browser ticker (+ `-rm`), and `ticker-strip-{roll,rm}` (the engine, 16 ms steps).
- **Asks:**
  - 2D Artist: the flap strip.
  - Audio: a cue for the slip stamp at its f0.
  - Dev/UX: the pager wraps "10,000 ₪." before the ₪; bind the sign to its number.
- No objection outstanding. A deviation is logged: the roll replaces §5.2's push. UX may counter-object with an alternative.

## 2026-09-30, 2D Artist + Audio Director: the envelope flap and the slip stamp's cue (Animator wave B asks)
- **The flap (2D, `art/od-sevev/src/wave9.py`, style guide §17.2, CONTRACT §5):** `sheet_modal_body` (38×38, 9-slice [7, 23, 7, 7], the envelope without its flap) and `sheet_modal_flap` (3 frames of 38×24, 3-slice [7, 0, 7, 0], pivot [0, 0]). f0 is sealed (a V from the corners to the point), f1 is lifting, and f2 is open (= the title band). Body + f2 = `sheet_modal` pixel for pixel, and the build asserts it. `sheet_modal` is unchanged.
  - **Wiring:** the body where `sheet_modal` is drawn today, then the flap at the same x, width and top, 96 logical tall. Draw order: body → flap → title and ✕. Frames 0/1/2 at 0/40/80 ms of the open, then hold 2; the title and ✕ show from f2. Reduced motion: f2 at once.
  - **Deviation:** "open" is the band, not a flap pointing up, so that the rest look stays the approved v4.
  - **Why 24 rows:** the point's shadow is on art row 23, the stretched centre's first row. Inside the 9-slice it becomes a ~190×45 dark slab under the point on every modal today (seen in the engine). The flap path draws it as one row. **→ Game Developer:** moving the modals to body + flap removes the slab.
  - The pipeline re-import has 0 cast drift and 261 kit pieces. VRAM +16,720 B.
- **`slipStamp` (Audio v1.4, cue-spec §3.2 and §4):**
  - A dry rubber-on-paper thunk: a slap, a pad, a rubber knock and a thud, staggered over 12 ms, then a lift-off tick. UI bus, 89 ms, one unpitched file.
  - Burst −20.5 LUFS, 2 dB under the stamp's heard −18.5 and 4.5 under `buy`. play_db −5.17. True peak −6.2 dBTP. Centroid 0.69 kHz. It is not Herzog's stamp (§5.6).
  - **Hook:** one line in `shop.gd` where `tagSlam` starts, to main 3 levels up. It is a no-op without the host or the cue.
  - **Tests:** `test_audio` adds the scan entry, a cue test and a host-path test. Renders are deterministic (317 files).
- **Checks:** `tools/test.sh` 370/370; strict `tools/build_web.sh` green.
- **Sheets:** the scratchpad `shots/flap/`: `flap-contact.png` (Python, 4 sizes), `flap-engine.png` (Godot, Ui.nine + set_nine_frame) and `flap-strip-x8.png`.
- No objection outstanding.

- 2026-09-30 · ux-designer · **UX review 2 of the full build** (the picker, mobile-first, v4, the walk, the roll) + **F15 placement** + **rulings on the roll and the pager** · `ux/review-2026-09-30.md` (new), `ux/mobile-first-layout.md` (§5.2, new §5.2.1, new §5.14, §10, §11), `ux/rtl-map.md` §2, `ux/tools/gen_strings.py` → strings, `game/scripts/ui/top_bar.gd`, `game/scripts/ui/views/view_share.gd`
  - **Played:**
    - touch-only in Chromium at 390×844@3 and 375×667@2, spot-checked at 430×932@3;
    - the gate, the picker, the first minute, C1, T3, a forced election, the flash and the picker again;
    - `round_web` PASS (a full round to O3 and round 2's picker);
    - `mobile_web` PASS on the three sizes;
    - `share_web` PASS at @2 (its @3 pending-chip probes are timing);
    - `modals_web`: all shots taken, but its "C1: the group opened" step fails at @2 and at @3 (6 buys × 2.6 s on a court day at ×0.5 income; C1 opens at 42-48 s in touch-only play). That is a driver question for the Game Developer.
  - **Findings U1-U16, no blockers.** Majors:
    - **U1** (TA + engine): `sheet_modal`'s flap shadow row 23 falls in the stretched centre slice, and paints a slab behind the first line of every SheetCard (O3, O10, O1, the leader card). Fix: slice top 24, `HEADER_H` 96.
    - **U2** (2D + engine): primary and secondary buttons are the same blue (1.13:1). Fix: a white-face primary with a flag label; O3's commit takes the gold CTA skin.
    - **U3** (engine): a blank white field fills 45% of the screen between tap 1 and card 1. Fix: keep the plaza until card 1.
    - **U4 / U5** (fixed here): the rate line at 60% on flag blue was 2.9:1 → alpha 0.9, 4.9:1; the share status line in `ui_mute` on cream was 1.3:1 → flag, 8.5:1.
  - **Minors:**
    - the SE peek shows a pill's top (the S7 check misses pills);
    - the slate silhouettes and system pills are off-palette;
    - the "61" in the coalition tab icon reads as an unread count;
    - Dubi's pick line sits over the leader pre-tap;
    - EVOLVE_TX is a blank cream page;
    - the WhatsApp button's bubble-with-tick icon;
    - the stale reduced-motion caption (fixed);
    - the owned badge covers the portrait;
    - the WhatsApp row is not full width.
  - **Roll (M1): accepted, no counter-objection** (D47, D48). A push shows Hebrew prefix fragments; a roll cuts glyph rows and keeps x. Conditions: a roll always completes; a tap mid-roll opens the incoming headline; reduced motion keeps the cross-fade.
  - **Pager: the no-break rule, §5.2.1** (D49):
    - strong glue (₪ with its number, punctuation with its word) and weak glue (a number with its magnitude word);
    - NBSP at display time, in `PxText` and `Ticker.paginate`; all three fonts have U+00A0 at the space's advance;
    - the bad breaks on the content go from 18/20/14/11 to 1/0/0/0 at the 280/324/384/464 clips.
  - **F15, §5.14** (D50):
    - **the hemicycle goes on O3 only** (×4 as the card's hero, `seats[0:n]` RTL, drawn in the blackout; left out if the card exceeds the modal band). **Not Row B** (the bar stays on every device). **Not the result card:** a filled arc beside a leader is the TV poll graphic on a forwarded image (style guide §13 and the `poll-number` red line; this overrides the dispatch suggestion);
    - **the booth goes on the picker wherever it is free:** tiles unchanged, 44 px from the sky, the columns at 20. On at 390, 393, 430, 360, 412 and the frame; off at the SE and the toolbar viewports;
    - **the envelope goes on O5's stage floor and on the share sheet's "sent" line**, never on blue (1.1:1).
  - **Checks:** `tools/test.sh` 368/368; strict `tools/build_web.sh` green (the text lint is 0).
  - **→ game-developer:** §10 D1 (§5.2.1, §5.14), U3, U6, U9, U11, U13, U14; U1 and U2 with the TA and the 2D Artist.
  - **→ technical-artist:** T1 (`sheet_modal` slice top 24).
  - **→ 2d-artist:** A4 (the white primary button), U7 (the silhouette row), U8 (the tab icon), U10 (EVOLVE_TX as a notice); A5 is optional.
  - **→ animator:** M3 (optional: the hemicycle fill).
  - **→ game-designer:** G2 (the ticker units lint).
  - No objection outstanding.

## 2026-09-30, 2D Artist + Technical Artist: the art side of UX review 2 (U1, U2, U7, U8, U10, A5)
- **Kit (`art/od-sevev/src/wave10.py`, style guide §17.3, CONTRACT §5):** new ids beside the old ones.
  - **U2 / A4:** `button_white_{default,pressed,disabled}` (24×20, `button_primary_*`'s slices): white face, a flag-blue lip, label `flag` 8.46:1 (pressed 6.40); 7.52:1 vs the secondary (was 1.13). O3's `ELECT_GO` → `kit_gold` (`button_gold_*` is the CTA's own full-width skin; no new id; UX's `ui_button_evolve` is the fork's blue sprite).
  - **U7:** `card_row_silhouette` (ui_mute slip, ui_rule edge 5.58:1 on the pane, name ui_panel 8.87:1); `chat_system_pill_navy` (ui_scrim well, ui_rule edge, label ui_mute 12.91:1); the pipeline writes `<silhouette>_pale` for all 11 sources (`sources[id].silhouettePale`).
  - **U8:** `tabicon_coalition_*` redrawn in place: two bubbles, three dots, no digits; the badge sits over the back bubble.
  - **U10:** `notice_frame` (the gate's ruled white card, 9-slice [3, 7, 3, 5], `colors` page/title flag, text night 13.88:1). A card on the flag-blue page, not full-bleed rules: a white screen striped top and bottom is the flag's layout (§2.4).
  - **A5:** `booth_frame_tall` (40×46, a 12-row header, `titleBox`).
  - **U1 / T1:** `sheet_modal` slice top 23 → 24 (pixels unchanged), for any modal that keeps drawing it alone (the kit says to keep it where the flap does not animate; the flash does today).
- **→ Game Developer (wiring, no `game/scripts` edits here):** `kit_primary` → `button_white` with the label char `"u"` (flag); `_kit_kind` maps every non-ink label to white today, which would draw white on white. `_card_sprite` teaser/silhouette → `card_row_silhouette` + the `_pale` icon unmodulated; `view_chat` pill → `chat_system_pill_navy` + ui_mute text; EVOLVE_TX → `notice_frame`; `HEADER_H` 96.
- **Checks:** full pipeline render 0 cast drift, 268 kit pieces, contrast table 0 fails; `tools/test.sh` 370/370; strict `tools/build_web.sh` green. Sheet: scratchpad `shots/review2-art/sheet-review2-art.png` (+ `contrast.md`).
- No objection outstanding.
- 2026-09-30 · ux-designer · **Merge review of session 4 (restore-s4 at a5963bc)**: M1-M8 in `ux/review-2026-09-30-merge.md`. Two must-fix before the redeploy, both for the Game Developer: M1, toasts hide the leader's head on the first screen of a round (short stages and round 2 on the SE; D62/S18 specced in `mobile-first-layout.md` §5.9); M2, a round started with under 7.5 ₪ shows a locked card 1 and an empty pane. Three polish items (M3 teaser floor, M4 the P0 hand's target, M5 the post-election undo chip). HANDOFF verdicts: 14 closed, 4 partly (A2, A7, B9, B12), 0 open. `dev2-*` after-shots regenerated and committed; evidence in `ux/manual-test-2026-09-30/review/`; spec hygiene in `mobile-first-layout.md` (§11 order, pane revision line, §10 M1), `rtl-map.md` §8.6, `ftue.md` rev 6. No objection.
- 2026-09-30 · game-developer · **Merge review M1-M5 built** (restore-s4): M1/D62, toasts dock in the lane band under the leader's feet until the round starts, and `LEADER_PICK_FRESH` waits for the undo chip, then docks there; D63 holds the whole toast queue while the after-election chip holds the lane. M2, `producers[0].revealAtRunEarned: 0`, and the teaser fill keys on card 1 being shown. M3, teaser rows j ≥ 3 draw only the plate at 0.2 (D57). M4, the P0 hand points at `BigBanana.pulse_point()`. M5, the after-election chip sits on a navy `#072a7a` tab from x 0. Checks: `tools/test.sh` 429/429 (was 421), content-lint --strict 0 errors / 0 warnings, strict build green. `mobile_web.mjs` now has S18 (round 1: the pick to tap 1; round 2: the pick to 7 s) and a second page per device that starts round 2 with 3 ₪ (M2/S15 + S8). It was green on all 9 devices across two runs: 6 in the full run; 430×932, 375×548 and 360×780 in a rerun, after a timing fix to the sampler and a 2-row-pane fix to the M2 check. PRETAP_SHOTS: PASS. Pacing: 0 delta (bank ≤ runBananas within a run, so the old 7.5 ₪ gate never blocked a buy); the bench was 11/11 before the change and was not rerun (95 min on this machine). Open, out of this slice: the first picker's caption plate can fail S8 when the random caption's second line is one short word (360×780, logical y 1504-1544, #072a7a). Shots: `ux/manual-test-2026-09-30/fixes/dev2-*`, after-crops `review/m1..m5-*-after.png`.
- 2026-09-30 · game-developer · **D64, the picker caption breaks balanced** (the S8 flake found in the M1-M5 verification): `PickView.balance_wrap` narrows the caption's wrap box until line 2 is ≥ 40% of line 1, and the plate still hugs the text. A new test in `test_pretap_hud.gd` runs every caption at every (f, cw) of the matrix: 38 of 48 two-line cases were under 40% before, 0 after. `tools/test.sh` 430/430, strict build green, and `mobile_web.mjs` on 360×780@3 and 375×548@2 PASS, with the pick screen's S8 and A3 plus S18 and M2/S15. The full matrix is left to the orchestrator.
- 2026-09-30 · orchestrator (studio) · session 5 stopped by Bar ("create a handoff for another agent, not within the studio"): the session-4 slices are merged, A6/A8 and M1-M5 plus D64 are done, the full mobile_web matrix PASSES in one run, motion_web PASSES; round/picker ×3 and balance.sh were not run; not deployed. B14 D' and Mordechai David are in handoff-wip/ as patches (s5-art, s5-design). See HANDOFF.md session 5.
- 2026-09-30 · 2d-artist + technical-artist · **B14 D' (Bar's pick): the Balfour protest signs are handmade kraft cardboard.** `locations.kraft_sign` (stage) and `wave7._kraft_sign` (wings, verbatim copy, same (k, side)): `stone` / `stone_sh` boards with a hand-cut corner, two right-aligned 1-px marker rows in `ink` / `flag_hi` (never centred, never red, never a letter or a face). `stage_balfour.png` 624 px changed (art rows 177-188), Bar-approved drift: the approved `showcase/out/` was updated, then a full render gives 0 drift; both Balfour wings re-rendered (seam rows unchanged); `locations.png` + its two proofs regenerated (they also catch up the v3 night/plum re-value the overview had missed). `pink`'s role drops "the protest's signs" (both `palette.py`); style guides: creative-pack Balfour row, `art/od-sevev` §2.4 sign rule. Checks: `tools/test.sh` 421/421; pipeline full render 0 drift, `--no-render --godot` import green. No objection.
- 2026-09-30 · 2d-artist + technical-artist · **Mordechai David, the protest blocker (Bar's call; legal-reads list).** Bar's ref → `creative-pack/art/refs/mordechai-david.png`; a custom render-down rig (`showcase/src/mordechai.py`, registered in `build.py`): arms (with sleeves) and legs cut and posed at ref resolution, shoulder caps and a shaded tee kept under the arms, one palette locked from idle 0, 96·d px at d 3 + d 2. Anims: `idle` 20, `walk` 8 (≈ 31 art px/s), `block_in` 4 (`plant`), `block` 3-frame hold (outer arm 42°, leader-side arm 12°), `glance` 10 (`smirk`). Faces right as drawn; `flip_h` for the left. Placement on Balfour (CONTRACT §4): feet row 221, x 150 (right crowd) or x 28 flipped (left), drawn behind the leader, never stopping in x 66-114. The orange stays (his signature; clear of the v4 blue chrome). Checks: the showcase and pipeline full renders give 0 changed for every existing character (0 cast drift), `--no-render --godot` import green (27 characters), `tools/test.sh` 421/421. Sheet: scratchpad `s5-art/sheet.png`. **→ game-developer:** wire the walk-on / block / glance per `design/mordechai-david-spec.md` (s5-design) and CONTRACT §4. No objection.
- 2026-09-30 · direct agent (session 6, no studio; the repo is now the bar_builds sibling `~/od-sevev`) · **Mordechai David built and on** (branch `s5-mordechai`, off `claude/magical-ride-ntn3u5` + the s5-art/s5-design patches): the `blockade` effect (§7.1, in `SEAT_COSTS`), `StreetFigure` (§7.2/§9: walk-in with flip_h, plant, hold, one glance, walk-out timed to the end; a diorama layer behind the sources and the leader), his toasts in the lane band (face + two lines; a top-dock toast covered the leader on the SE in the forced-event look), the ticker headline, the lint (§7.4), `flags.mordechaiDavid: true` and the three md-* facts live. Spec §2's facing line fixed to the sprite (faces screen-right as drawn). Checks: `tools/test.sh` 437/437 (+7: test_events blockade ×3, test_street_figure ×4), content-lint --strict 0/0, strict build green, forced-event look at 390×844@3 and 375×667@2 PASS, no page errors. Open: spec §6 bench, full `mobile_web` matrix, deploy #2.
- 2026-09-30 · direct agent (session 7) · **The tap plays HaTikva** (Bar, ADR 0004): one note per tap on a bell, streaks open on alternating phrases, restart after a 400 ms pause and on an election. Bars 1-4 from the Wikipedia score (via anthem-scores); the second section waits for a verified source. `compose_od.py` (TAP_ANTHEM + check), `gen_od_sevev.gd` (`semis` pitch type, melody in the manifest), `od_audio.gd` / `audio.gd` (melody_step), `test_audio.gd`. Audio 11.23 MB; tests 439/439.
- 2026-09-30 · direct agent (session 7) · **Deployed `de5cc82`** (the HaTikva tap, on top of `ae77427`): web-dist `ba422bb`, Vercel `dpl_GDj4snZUQt9X6cyJZdkj2QKzTpnN`, production alias od-sevev.vercel.app; the live index.html reports `mbBuild = 'de5cc82'`.
- 2026-09-30 · direct agent (session 7) · **Mix pass v1.6 + HaTikva section B** (Bar, ADR 0005): -3 dBFS files with DC block and de-click fade on one-shots, master HPF + glue + limiter +2 dB, L2 at -6 dB under the bell, section B written from the anthem as sung (unverified, flagged). Recorded mix -16.5 LUFS / -0.2 dBTP; audio 11.26 MB; tests 439/439.
- 2026-09-30 · direct agent (session 7) · **Deployed `cc514f9`** (mix pass v1.6 + HaTikva section B): web-dist `930f70f`, Vercel `dpl_4YPWaXmjiUBXrQsEx1eWxMnngcJq`, od-sevev.vercel.app reports `mbBuild = 'cc514f9'`.
- 2026-09-30 · direct agent (session 7) · **Music refinement v1.7** (Bar): Music bus EQ6 (-2.5 dB @3.2 kHz, -2 dB @10 kHz) + small room (wet 0.1), music target -18.3 LUFS. Recorded session: -16.4 LUFS, highs -1.1 dB, width +2 dB. Tests 439/439.
- 2026-09-30 · direct agent (session 7) · **Deployed `68ecace`** (music refinement v1.7): web-dist `1558a8f`, Vercel `dpl_AyK1bYczWqLYVYdkoan41oV2RhE6`; live reports `mbBuild = '68ecace'`.
- 2026-09-30 · direct agent (session 7) · **Deployed `68ecace`** (music refinement v1.7): web-dist `1558a8f`, Vercel `dpl_AyK1bYczWqLYVYdkoan41oV2RhE6`, READY on od-sevev.vercel.app. **Gameplay reel** `store/gameplay/od-sevev-gameplay.mp4` (68 s, Ben Gvir's round captured with Movie Maker, Mordechai David hosting, Bar's soundtrack).
- 2026-09-30 · direct agent (session 7) · **Home Screen icon fixed + a new icon and logo (Bar: "fix it, be creative, make an icon and a logo").** The bug: iPhone "Add to Home Screen" showed Godot's robot, because the web export renders `index.apple-touch-icon.png` from `application/config/icon` and that was never set. Fixed twice over: `config/icon` → `icon_1024.png`, and `tools/build_web.sh` copies the pipeline's `pwa_180.png` over the engine's apple-touch file. The art (`art/od-sevev/src/logo.py`, graphic tier, 64 art px x16): **the round comes out of the hat and goes back in**: the Magician's top hat, a gold "again" loop rising out of it and diving back in arrowhead first, a blank ballot slip and a shekel flying up inside it (no faces, text, flag or star; §2.4 party-neutral; slips fly up, v1 do/don't 6). It replaces the ring of eight heads, which read as dots at 60 px (`keyart.icon()` kept, not called). **Logo:** the v2 wordmark with the ס drawn as the same loop arrow, as `out/key/logo-{horizontal,stacked}.png` + `mark.png` + `wordmark-loop.png` (x8/x16, and `-art` at 1x). The boot splash is now the stacked logo (`game/assets/icon/splash.png`) on `flag_dk`, the manifest's colours moved off the fork's plum. Pipeline: icon sizes that aren't a multiple of 64 (180/144/192/432) are LANCZOS from the 1024. The in-game title wordmark is unchanged. Checks: strict `tools/build_web.sh` green, the export writes the new icon to `index.apple-touch-icon.png` + `index.icon.png`. Needs a deploy to reach the phone; an icon already on the Home Screen must be removed and added again.
- 2026-09-30 · direct agent (session 7) · **Merged to `main` and deployed `70bf3c3`** (Bar: "merge everything to main"): `main` fast-forwarded to `tap-hatikva` (which already held `s5-mordechai`, `claude/magical-ride-ntn3u5`, `instagram-profile`), then the icon branch merged in (STATUS.md conflict resolved by keeping both logs). Tests 439/439, strict build green. web-dist `81aa520`, Vercel `dpl_DbnzW2cKPLS5yWGCmYmNtkukezXH`, READY on od-sevev.vercel.app (the live manifest carries the new colours).
