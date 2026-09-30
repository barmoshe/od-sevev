# Motion audit: the views added in session 2 (animator, 2026-09-29)

Every view from the session-2 build, checked against the motion rules in `README.md`:
- **Entry and exit.** An entry is ≤ 300 ms with ease-out; an exit is ≤ 200 ms with ease-in or a cut. Anything over 400 ms drags.
- **Easing.** Named curves only.
- **Whole pixels.** Offsets land on the 4-logical grid (one stage art px, which is whole device px at every crisp k), snapped after easing. Pixel art never gets a non-integer scale, except a transient of 180 ms or less.
- **Reduced motion.** `settings.reducedMotion` (the OS query or the in-game toggle) must change parameters, never routing.

**Verdicts:** **OK** means it meets every rule. **Fixed** means this change fixed a gap. **Noted** means a known minor deviation, kept, with the reason given.

| View | Entry / exit | Easing | Whole px | Reduced motion | Verdict |
|---|---|---|---|---|---|
| Coalition chat T3 (tall tab) | 280 ms up / 200 ms down | Cubic.Out / Quad.In | panel and thread scroll snapped to 4 | 150 / 120 ms fade | OK |
| Chat bubble arrival | 180 ms, 16 px in from its side (the ultimatum adds a 1-ap thud) | Quad.Out | snapped to 4 | 120 ms fade | OK |
| Pay-pill stamp slam, can't-afford shake | stamp at integer scale 6 → 5 → 4 over 90 ms; shake ±4 px every 45 ms for 180 ms | Stepped | integer scale, a transient of ≤ 180 ms | cut, no shake | OK |
| Seat pips | 450 ms along a Bézier, 50 ms stagger | Quad.In | snapped to 4 | none fly | OK |
| Ultimatum chip | the digits cut; a 1-ap nudge of 100 ms per tick | Quad.Out | snapped to 4 | no nudge; the clock is static | OK |
| Partner card | Overlay: 240 ms Juice drop table (every entry is a multiple of 4) with the squish; exit 160 ms, 32 px | table / Quad.In | the figure is at a crisp art scale (`pick_art_scale`) | 120 / 100 ms fades; a partner who left holds on f0 | OK |
| Dossier T4 | the same tall tab | Cubic.Out / Quad.In | scroll snapped to 4 | fades | OK |
| Pardon desk | Overlay; the stamp's root scale is 1.5 → 1.25 → 1 at 33 / 67 ms, with a 1-ap jolt and 4 snapped specks | Stepped | at k 3 the ×1.25 frame sits on half device px for 34 ms | the cue at f0, no slam | Noted: a legal transient under 180 ms |
| Thermometer | reveal 280 ms from the left; fill 300 ms rounded to art rows; icon hop 1 ap for 100 ms; bubbles | Back.Out / Quad.Out / Linear | snapped to 4 or rows | 150 ms fade, the fill cuts, one static bubble | OK |
| Thermometer opacity, court tint | 60 ↔ 100 % over 200 ms; tint 0 → 0.18 over 400 ms (`move_toward`) | Linear; the spec says Quad/Sine.InOut | alpha only | 200 ms | Noted: alpha-only, and a linear ramp is reversible mid-way; the difference is not perceptible at 0.18 |
| Sweat (drops, bead, summons gulp) | slide 300 ms, fall 250 ms | Quad.In | snapped to ap | one static bead | **Fixed:** court day now takes Bibi off the stage, and drops, the bead and the gulp no longer appear on an empty stage (`bb.on_stage()`) |
| Court card O2 | in 280 ms from 24 px with a 1-ap jolt at 180; out 180 ms; collapse 200 / expand 240 | Back.Out / Quad.In / Quad.In / Quad.Out | snapped to 4 | 150 / 120 ms fades | OK |
| Court chip | its entry is the card's collapse, which lands in it; it cuts out on the expand's f0 | – | – | – | OK by design |
| **Court day on the stage** | did not exist | – | – | – | **Fixed:** new (`ui/court_motion.gd`, `BigBanana.court_*`); see below |
| **Court-window echo** | not wired | – | – | – | **Fixed:** new (`ui/court_echo.gd`); see below |
| Dubi's news flash | Overlay; the lines stagger 150 ms and fade in over 120 ms; Dubi at a crisp art scale, talk frames per blip | Linear alpha | snapped to 4 | lines at once | OK |
| Cottage cup | appears in 200 ms; a 1-ap hop that cuts; the pixel particle and the "−1" snapped | Quad.Out / Cubic.Out | snapped to 4 | a cut, and a static "−1" fading | OK |
| Election, return and reset modals | Overlay (as above); the return's count-up | table / Cubic.Out | – | fades; the count-up is a number, not motion | OK |
| Share cards | Overlay; the preview is static | table | the preview snapped to 4 | fades | OK |
| **Pending chip** "{n} ממתינים ↑" | was a cut in; now **120 ms fade with a 1-ap drop**; the exit stays a cut (it leaves the moment nothing is above, < 100 ms reads as instant) | Quad.Out | snapped to 4 | the fade only | **Fixed** |
| **Brawl stage cue** | was a cut in with a flat 150 ms frame loop; now a **150 ms fade in** and **the boil**; the exit is a cut (the brawl resolved, or T3 opened on it) | Quad.Out; Stepped | the ring steps 4 logical (one stage ap; one ×2-cloud ap would be 1.5 device px at k 3) | frame 0, still | **Fixed** (the ×2 cloud itself is 1.5 device px per texel at k 3; that is the chat's stated deviation, and a 26×20 cut from the 2D Artist is still open) |
| **Brawl cloud in T3** | was a flat 150 ms frame loop; now **the boil** | Stepped | a 4-px ring at ×4 | frame 0, still | **Fixed** |
| **Toasts** (the spin-end toast and every stage toast) | the entry was a real-time Tween, Linear, 180 ms; the exit was a hard pop at 3 s. Now **180 ms in, 120 ms out inside the 3 s**, on scene time (it pauses with the page) | Quad.Out / Quad.In | – | cuts | **Fixed** |

**The biggest gap was global: the web game never followed the OS preference.**
- **Symptom:** `prefers-reduced-motion: reduce` read as false.
- **Cause:** the 4.7 web bridge returns a JS boolean as the int `1`, and `MainController._os_reduced_motion()` compared it with `== true`, which is false for an int in GDScript.
- **Consequence:** every reduced-motion path above was reachable only through the in-game toggle.
- **Fix:** `MainController.js_bool`, with a unit test.
- **Verified:** in Chromium, `tools/web/motion_web.mjs` checks `odDisplay.reducedMotion` under each emulated preference.

## New motion in this change

### Bibi's court-day exit and return (`state-graph-magician.md` §1.3, §2, §3, §5)
- **Scope:** Bibi only (`BigBanana.wants_court` requires `Leaders.has_court()`). A press-day leader never leaves the stage.
- **Exit:** the `tap.f1` startle; `tap.f2` at 180 ms with a 1-ap lean; at 330 ms a 200 ms Quad.In zip screen-left, with 2 after-images and dust. At 780 ms `prop_hat` zips back (300 ms Quad.Out) and hovers on his mark (idle f0 `hatMouth`), bobbing 0 → −2 ap every 1.6 s. The rabbit peeks every 6-9 s.
- **Taps:** they hit the hat. The hop is −4 ap (80 + 120 ms), with coins at the peak (2 + the merged taps, max 4). A crit brings the rabbit up 12 ap with 6 coins. A paused tap gets the ears and a wiggle, with no coins.
- **Return:** the hat fetches him (150 ms, or 120 quick), 150 ms of empty stage, then a 220 ms Quad.Out zip back on `tap.f2` and the land (tap from f1, coins suppressed, dust).
- **Early returns:** a courtEnd during the startle cuts him back to the mark. A courtEnd mid-zip reverses (150 ms). An election makes it quick. A reset cuts him home.
- **Reduced motion:** the body fades 150 ms, then the hat fades in; no bob, peek or hop; three coins per tap.
- **Whole px:** every offset is whole art px (×4 logical).
- **Summons flinch:** `land` from f1, no coins.
- **Wiring:** driven by the sim's phase every frame, so a load, an election or an aide drop can't strand him off stage.

### The court-window echo (motion-spec `courthouse_window`)
- **Placement:** `court_window` on the 2D Artist's era spot, lowered on the art grid to just under the toast dock where the flex rule crops the art's top rows.
- **Levels:**
  - it fades in with the thermometer;
  - its window lights at ≥ 75 % (400 ms, Sine.InOut);
  - the checker halo is steady at ≥ 95 %;
  - **while the window is open** (the summons and court day), the lit window breathes 100 → 60 → 100 % every 1.6 s (0.63 Hz, never dark, never a strobe).
- **Reduced motion:** 200 ms fades, held lit.
- **Where it shows:** Bibi's rounds only. The courthouse era has none.

### The brawl boil (motion-spec `brawl-cloud`)
- **Frames:** the kit's 4 frames at 8 fps.
- **Offset:** the whole cloud steps around a 1-ap ring every 100 ms, then rests 300 ms at the end of each 1.2 s period.
- **Reduced motion:** frame 0, still.

### Prepared for slice 2 (not wired): `ui/leader_walk.gd`
A walk that takes a leader id, `LeaderWalk.make(parent, id, feet)`. It carries the leader's idle strip across the stage with a stepped 1-ap bob every other 125 ms beat:
- walk-out: 560 ms, Sine.In, screen-right;
- walk-in: 640 ms, Sine.Out, landing flat on the feet point.

Out and in fit the 1.5 s swap budget. Reduced motion: a 150 ms fade on the mark.

Whoever wires EVOLVE_TX calls `walk_out()` on the fade and `walk_in()` on the fade-in.

---

# Wave B (animator, 2026-09-30): the leader swap, the ticker pager, the slip stamp

**Update to "Prepared for slice 2":** `LeaderWalk` is now wired. The state graph, the timelines and the interplay with
the court day are in [`state-graph-magician.md` §9](state-graph-magician.md). The API changed: it is now a pose
provider (`advance`, `dx_ap`, `dy_ap`, `alpha`, `shows`), and `BigBanana._apply_figure` is the one writer of the
figure's position.

| Piece | Entry / exit | Easing | Whole px | Reduced motion | Verdict |
|---|---|---|---|---|---|
| **Walk-out** (EVOLVE_TX) | 560 ms from the card's lift (t 1200) to gone (t 1760); input held until then | Sine.In, 1-ap bob every other 125 ms beat | every offset is whole ap, snapped after easing; the sum with the court offset is whole ap | 150 ms fade on the mark (t 1000-1150), no tail | **New** |
| **Walk-in** (after the pick) | 640 ms from `on_done` (520 ms after the commit); replaces the 250 ms placeholder fade of the whole stage node | Sine.Out, bob, flat last beat | as above | 150 ms fade on the mark | **New** |
| Dubi's pick line | the landing + 120 ms (1280 ms after the commit; it was 900, over an empty mark); the leader's own line 1.7 s later | – | – | the 150 ms fade + 120 ms | **Fixed** |
| **Ticker page change** (M1) | 240 ms roll: the next page rises from under the 84-px row as the old one lifts out, locked one row apart | Cubic.Out (80 % of the travel in the first 100 ms: the eye lands on still text fast) | 4-px steps; x never moves | the 200 ms cross-fade (unchanged) | **New** (replaces the push, which was off) |
| **Ticker dwell** (M1) | per page, by length (below) | – | – | same | **Retuned** |
| **The slip stamp** (v4 `card_plate`, the spin tag) | a tag that appears or changes on the same card ("1/5" → "2/5", "שחוק") slams: text ×6 → ×5 → ×4, 30 ms each, the backing growing round its centre | Stepped (the pay-pill stamp's language) | integer text scale, the backing on the 4-px grid; a 60 ms transient | a cut | **New** |
| Envelope flap on modal open | not built | – | – | – | **Open:** see the ask below |

## The ticker pager (M1)

**Why a roll and not UX's push (§5.2).** With a sideways push, the entering page shows its first letters at the
clip's left edge for about 300 ms, and the leaving page shows its last ones at the right edge. In Hebrew a word's first
letters are often a word of their own (ה, ו, ב, ל, ש are prefixes), so the fragments read as other words. That fails
the "no word ever cut" rule on every page change.

A roll keeps every glyph's x fixed, so every visible word keeps all its letters on every frame. Only whole glyph rows
cross the row's top and bottom edges, which reads as a mask, like a split-flap board, not as a fragment.

The roll also keeps UX's intent: a short news-strip move under 300 ms, and still text while it is read. The crawl's
"first word enters first" metaphor is the only thing lost, and it no longer applies to still pages.
- **Tests:** `test_ticker_roll.gd`. At every step x == 0 for both pages, every line's ink lies inside the clip's
  width, the pages are one row apart, and the steps are on the 4-px grid.

**The dwell by page length** (`Ticker.dwell_ms`). It replaces max(3.5 s, 55 ms × chars), under which every page in
the content sat on the 3.5 s floor: the longest page is 49 characters, and 49 × 55 ms is only 2.7 s.

| Page | Rule | Clamp |
|---|---|---|
| a headline's first page | 1.2 s (find the strip, first fixation) + 70 ms a character | 2.0-5.5 s |
| a continuation page | 0.5 s (the eye is already on the row) + 70 ms a character | 2.0-5.5 s |
| an FTUE line | 1.5 s + 85 ms a character (continuations 0.5 s + 85 ms) | 4.5-7.0 s (UX's 4.5 s floor kept) |

- **70 ms a character** is about 14 characters a second. That is under the 17 cps adult subtitle rate, because the
  ticker is read in glances between taps.
- **The 2.0 s floor:** a one-word tail page still reads as a beat, not a flicker.
- **The 5.5 s cap:** the longest page at the widest clip (49 characters) gets 4.6 s, so the cap is never reached by
  today's content.

**Measured** (`game/tests/dev/ticker_pages.gd`, 275 ticker lines in `content.json`, including the leader kits):

| Clip (px) | Pages / headline, mean (max) | Characters / page, p10 / p50 / p90 / max | Dwell / page, p10 / p50 / p90 / max | Headline, p50 / p90 (was) |
|---|---|---|---|---|
| 280 (press or court day, 360 phones) | 1.96 (3) | 7 / 20 / 26 / 32 | 2.0 / 2.2 / 3.0 / 3.3 s | 5.1 / 7.3 s (7.0 / 10.5) |
| 324 (360 wide) | 1.73 (3) | 9 / 23 / 30 / 35 | 2.0 / 2.3 / 3.3 / 3.6 s | 5.3 / 5.7 s (7.0 / 7.0) |
| 392 (390 wide) | 1.60 (2) | 7 / 21 / 37 / 43 | 2.0 / 2.2 / 3.8 / 4.2 s | 5.7 / 6.0 s (7.0 / 7.0) |
| 464 (430 wide) | 1.38 (2) | 7 / 33 / 44 / 49 | 2.0 / 3.5 / 4.3 / 4.6 s | 4.1 / 6.5 s (3.5 / 7.0) |

The headline times include the 240 ms rolls between pages. A median headline now takes 4-6 s instead of 7. The long
pages get more time than before (up to 4.6 s instead of 3.5), and the short tails less (2.0 s instead of 3.5).

## Asks and notes

- **2D Artist: the envelope flap.** `sheet_modal`'s title band is the v4 envelope flap, but it is baked into a
  9-slice, so there is no flap to move.
  - A flap that opens can't be faked with transforms: a vertical flip or scale of pixel art is a non-integer or
    mirrored-light transient.
  - The ask is a 3-frame `sheet_modal_flap` strip, 38 art wide and 23 rows (closed pointing down, half, open
    pointing up), with the same 9-slice columns.
  - Its motion would be the band's 3 frames at 40 ms on the sheet's open (120 ms, inside the 240 ms drop), with no
    flap under reduced motion.
- **Audio Director: the slip stamp** has no cue. The chat's `stamp` variants would fit, and the frame to mark is the
  slam's f0 (the ×6 frame).
- **The court's zip** still exits screen-left while the walk-out goes screen-right, per spec §9.3.4. They never
  share a frame: the walk-out cuts a court day home under the card.

## Verified (wave B)

- **Unit tests:** `test_leader_walk.gd`, 9 cases:
  - the state machine, and reduced motion;
  - the TX cue: at the card's lift, and ≤ 260 ms past the card;
  - the pick walk-in, with Dubi after the landing;
  - a tap during the walk-in;
  - the undo mid-walk and the re-pick;
  - the election, with the lock held until the stage is clear;
  - the court yielding: one owner of the position;
  - reduced motion on the stage.
- **More unit tests:** `test_ticker_roll.gd` (4) and `test_slip_stamp.gd` (2).
- **Browser:** `tools/web/motion_web.mjs` has a `walk` and a `ticker` section, and `MOTION_VARIANTS` / `MOTION_SLOW_*`
  for a loaded machine.
  - On this 4-core container, shared with the other agents, a stage screenshot costs 2-4 s of wall time. The walk runs
    at `slow=100`, which gives ~35 ms of game time per frame.
  - The ticker's 240 ms roll is too short to catch reliably that way, so `game/tests/dev/ticker_strip.gd` renders it
    in the engine in 16 ms steps (under `xvfb-run`).
- **Looked at** (scratchpad `shots/motion-b/`):
  - The walk-in comes from off screen-left once the picker has faded and lands on the feet point; Dubi's bubble
    follows the landing.
  - The walk-out starts as the stepped card lifts, crosses the new era's stage and clears the right edge, the pen
    last. The flash (O3b) follows on an empty stage.
  - The roll: the two pages move locked, the words are whole, and 90 % of the travel is done by 100 ms.
  - Reduced motion: fades on the mark, and the ticker's cross-fade.
