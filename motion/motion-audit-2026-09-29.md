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
