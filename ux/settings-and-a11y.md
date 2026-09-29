> **Superseded for "עוד סבב" (2026-09-28):** this is the Monkey Bananas v2 record the fork inherited. Implement from rtl-map.md (layout) and ftue.md (prompts). Kept for engine history only.

# settings-spec + accessibility-spec — Monkey Bananas

Owner: UX Designer. Consumers: Game Developer (settings persistence, reduced-motion switches, keyboard), 2D Artist (palette contrast pairs), Animator (reduced-motion variants), Audio Director (preview cue).
The layout is in [`hud-layout.md`](hud-layout.md) §11. Strings are in [`number-and-copy.md`](number-and-copy.md).

## Part A — settings-spec

Settings live in `save.settings` and persist in localStorage. They **survive Evolve and RESET SAVE**: reset wipes progress, not preferences.

| Group | Option | Control | Default | Default rationale | Who wants it / cost | Live preview |
|---|---|---|---|---|---|---|
| SOUND | Sound effects | ON/OFF toggle (whole row is the target) | **ON** | Tap feedback is half audio; the median player on phone speakers wants it | Players in shared spaces. Cost: 1 row | Turning ON plays the `buy` cue once immediately |
| SOUND | Music | ON/OFF toggle | **ON** | A procedural chiptune loop sets the absurd tone; web players who dislike it mute in one tap | Podcast and background-audio listeners. Cost: 1 row | ON: music starts immediately (fade-in is the Audio Director's call); OFF: stops within 100 ms |
| ACCESSIBILITY | Reduced motion | ON/OFF toggle | **Follows `matchMedia('(prefers-reduced-motion: reduce)')` on first launch**, then stored as an explicit choice | OS preference is the best signal of need; defaulting OFF otherwise keeps the intended juice for the median player | Vestibular sensitivity, migraine, attention. Cost: the Part B §4 variants | Applies instantly behind the scrim (the ticker switches to paged and the diorama freezes) |
| GAME | Fullscreen | ON/OFF toggle, **row shown only if `document.fullscreenEnabled`** | OFF | Browser chrome is expected by default; fullscreen needs a gesture anyway | Mobile Android and desktop players who want immersion. Absent on iPhone Safari (no API), so no dead row | Enters or exits immediately (Phaser `scale.startFullscreen()` / `stopFullscreen()`). Syncs if the user exits with Esc or the system UI |
| GAME | Reset save | Button → `RESET_CONFIRM` | — | Destructive, so it has a two-step confirm with no backdrop dismiss and CANCEL as default focus | Players starting over; also the QA path back to first launch. Cost: 1 row + 1 modal | n/a |

- **Why no volume sliders:** sliders miss the 104-px touch rule on their thumb, and Hick's-law cost is non-zero. Two binary toggles cover the MVP need. The Audio Director sets bus levels.
- **Why no language picker:** English only (MVP). The copy file is built for later extraction.
- **Why no colour-blind mode:** no signal depends on hue (Part B §3), so a filter would fix nothing.
- **Depth:** group → option only, 1 level. Accessibility is a top-level group, not buried.
- **Informational line** (not a setting): "KEYS: SPACE = TAP, ESC = MENU". Mechanic-spec §7 says settings mentions the keyboard.
- **Group sizes** are 2 / 1 / 2 options. They are below Miller's 3–7 band on purpose, because the option count is the MVP minimum. The labels exist for scanning.

## Part B — accessibility-spec

### 1. Commitment matrix

| Category | Tier | What we do / why deferred |
|---|---|---|
| Low vision | **A** | Text ≥ ×3 (≥ 9 CSS px glyph height at the worst scale; ≥ 10.5 CSS px at 0.5×); contrast floor 4.5:1 on all text; 104-px targets. Browser zoom is not usable on a FIT canvas; Tier C for >200% magnification (canvas game) |
| Colour blindness | **A** | Colour is never the sole channel (§3); deuteranopia, protanopia and tritanopia pass on the §3 table |
| Blindness | **C** | A canvas idle game with no DOM mirror. Screen-reader support would need a full parallel DOM (`canvas-screen-reader-seam`). Out of MVP scope |
| Deaf / hard of hearing | **A** | No information is audio-only: every cue has a visual twin (floaters, banners, glint, the Golden sparkle). No speech, so captions are n/a |
| Limited dexterity | **A** | 104-px targets; tapping is never required (idle income + offline); ×10 and MAX replace hold-to-repeat; the Golden has no drift or bob under reduced motion |
| One-handed | **A** | Portrait; all frequent targets (banana, rows, tabs) sit in the lower 75%; only low-frequency Evolve and gear sit top-right |
| Switch / keyboard-only | **B** | Space taps; overlays are fully keyboard-operable (§5). Shop purchasing by keyboard is Tier B (the optional digit keys in §5); Golden catching by keyboard is Tier C (optional reward, per feel-spec) |
| Cognitive: memory, attention | **A** | One prompt at a time; state-driven hints; the Evolve preview explains before commit; nothing is lost for inattention (a missed Golden is free, offline credit is capped at 8 h) |
| Cognitive: language | **B** | Short all-caps lines ≤ 31 chars; absurdist jokes live only in non-critical ticker lines, and every critical label is plain ("BUY", "NEED", "EVOLVE") |
| Photosensitive | **A** | No element flashes > 3 Hz over a large area (§4); reduced motion removes the white-flash transition and slows all blinks to ≤ 2 Hz |
| Vestibular | **A** | Reduced motion zeroes shake, stops scroll auto-motion and freezes ambient idles |

### 2. Contrast (v1.1 "sunny toy box" theme, independently re-verified by UX)

**Rule (unchanged):** every text pair is **≥ 4.5:1** at any size (at phone scale even ×4 pixel text is about 12–16 CSS px, below WCAG's large-text line, and 1-font-px strokes read as thin). The target for the bank and the pill cost is **≥ 7:1**. Non-text UI is **≥ 3:1**. "Dim" is done with size or position, never below 4.5:1.

UX recomputed these ratios from `UI_THEME` hex values (WCAG relative luminance). They match the 2D Artist's style-guide §11.6 to 2 decimals. **All pass.**

| ID | Pair (foreground / background) | Ratio | Min / target | Result |
|---|---|---|---|---|
| C1 | bank `Y` #ffd23a / stat window `U` #3a1e72 · Golden roll `O` / `U` | 9.03 · 5.72 | 4.5 / 7 | ✓ (target met) |
| C2 | bps `v` / `U` · Frenzy bps `O` / `U` · thumbs `e` / `U` | 8.05 · 5.72 · 6.94 | 4.5 | ✓ |
| C3 | Evolve ready `w` / grape `u` · not ready `k` / lavender `I` | 5.44 · 7.37 | 4.5 | ✓ |
| C4 | row name `k` / cream `c`, mint `m`, lilac-grey `i` · line 2 `U` / `c`, `m`, `i` | 15.00, 14.16, 12.28 · 11.98, 11.31, 9.81 | 4.5 | ✓ |
| C5 | pill label and cost `k` / BUY lime `v` · NEED lavender `I` | 10.08 · 7.37 | 4.5 / 7 | ✓ (target met) |
| C6 | tab `k` / selected `c` · unselected `j` · badge digit `k` / pink `q` | 15.00 · 6.44 · 6.76 | 4.5 | ✓ |
| C7 | ticker `w` / `U` · NEWS `k` / `q` · milestone tint `q` / `U` | 12.36 · 6.76 · 5.40 | 4.5 | ✓ |
| C8 | floater `w` / its `k` outline · crit `Y` / `r` outline | 15.48 · 5.73 | 4.5 | ✓ |
| C9 | banner `Y` / `U` · buff chip `k` / `c` | 9.03 · 15.00 | 4.5 | ✓ |
| C10 | modal text `k` / card `c` · group labels `u` / `c` · notes `U` / `c` · primary button `k` / `v` · disabled `k` / `I` · toggle ON `k` / `v`, OFF `k` / `I` · RESET `k` / coral `x` | 15.00 · 5.27 · 11.98 · 10.08 · 7.37 · 10.08, 7.37 · 6.02 | 4.5 | ✓ |
| C11 | EVOLVE_TX `k` / `w` · reduced motion `w` / `U` | 15.48 · 12.36 | 4.5 | ✓ |
| C12 | juice tint `q` / `U` only · `Q` / `c`, `m` · empty state `k` / tray `e` | 5.40 · 4.84, **4.57** · 8.69 | 4.5 | ✓ (mint is the tightest pair in the UI) |
| N1 | control ink `k` / `c`, `m`, `i`, top bar `q`, tray `e` | 15.00, 14.16, 12.28, 6.76, 8.69 | 3 | ✓ |
| N2 | bar fill `v` / track `U` (lower row `G` 3.95) · golden fill `O` / `U` · track `U` / `c`, `I` | 8.05 · 5.72 · 11.98, 5.88 | 3 | ✓ |
| N3 | focus ring outer `Q` / `c` · inner `q` / `k` | 4.84 · 6.76 | 3 | ✓ |
| N4 | Big Banana `k` / sky `T`, `t`, `G` · `Y` / `T`, `t` | 3.43, 3.56, 4.94 · 3.29, 3.18 | 3 | ✓ (tight; stage art unchanged in v1.1) |
| N5 | Golden halo `w` / `D`, `T`, `t`, `U` | 6.91, 4.51, 4.35, 12.36 | 3 | ✓ |
| N6 | silhouette `U` / row `i` · plate `I` | 9.81 · 5.88 | 3 | ✓ |
| N7 | pointer `k` / `T` · `w` / `D` · `k` / `c` | 3.43 · 6.91 · 15.00 | 3 | ✓ |

**Forbidden pairs.** These fail, and the theme must never produce them:

| Pair | Ratio |
|---|---|
| `q` text on cream | 2.22 |
| `Y` on cream | 1.33 |
| `Y` on the pink bar | 1.67 |
| `k` on `U` | 1.25 |

Any new pair must be added to this table before shipping. Thresholds are exact: 4.499 fails.

**Readability at 0.5×.** The font scales are unchanged (×3 minimum), so the glyph-height table in `hud-layout.md` §1 still holds. v1.1 raises the worst text pair from 4.5 to 4.57 and puts all HUD numerals on the dark stat window (5.7–9.0:1). Net legibility improves over v1.0.

### 3. Colour is never the sole channel

| Signal | Colour cue (artist's) | Redundant non-colour channel(s) |
|---|---|---|
| Row can afford / can't | lime vs lavender pill (only 1.37:1, so hue and value alone are **not** sufficient); cream/mint vs lilac-grey row (1.15–1.22:1, weak) | "BUY" vs "NEED" **text** (primary); raised (lip + gloss) vs sunken (inner shadow) **shape**; icon 100% vs 50% **luminance**; pill hello nudge and glint **motion** (off under reduced motion). Deuteranopia mock: lime → khaki, lavender → grey-violet; still apart by label, bevel and value (0.60 vs 0.42) ✓. Greyscale mock ✓ |
| Selected tab | tab tint | raised, connected to the panel, plus a 4-px underline (**shape**) |
| Evolve disabled / enabled | button tint | sunken vs raised; "EVOLVE" vs "EVOLVE!"; bar vs "+N" (**text, shape**) |
| Banana Frenzy active | gold bps text, gold edge glow | "×5" suffix on bps; buff chip "FRENZY ×5 12S" plus a depleting bar (**text, size**) |
| Tap Frenzy active | Big Banana glow | buff chip "TAP FRENZY ×10 12S"; floaters grow to ×6 (**text, size**) |
| Crit tap | crit floater colour | ×6 instead of ×4 **size**; "!" suffix **text**; shake (off under reduced motion; size and text remain) |
| Golden vs Big Banana | gold vs yellow | ≤ 0.35× the size; sparkle **shape**; motion (off under reduced motion; size and sparkle remain) |
| Destructive RESET | red fill | the word "RESET", a separate confirm step, CANCEL as default focus |
| Toggles | ON tint | the words "ON" / "OFF" |

Simulation check (falsifiable): render each state in deuteranopia, protanopia, tritanopia and grayscale. Every pair in this table must remain distinguishable **with the colour column ignored**.

### 4. Reduced-motion mode

Its essential motions are kept (Swink: feedback must still happen). Only the non-essential motion is removed.

| Feature | Default | Reduced motion |
|---|---|---|
| Crit shake (3 px) and Golden-catch shake (4 px) | on | **0 px** (feel-spec) |
| Tap and crit chips | 3 / 10 | halved (feel-spec `reducedMotionChipFactor`) |
| Floaters "+N" | rise 90 px / 700 ms, up to 24 at once | **Static:** pop in place, no rise, fade out over 500 ms, up to 8 at once (the oldest recycled). The number still appears, because it is information |
| Crit floater pop to 1.3 | on | no scale pop; static ×6 text, fade out over 700 ms |
| Big Banana squash | on | **kept** (essential tap feedback, small amplitude) |
| Ticker | marquee at 90 px/s | **Paged:** the headline is word-wrapped into ≤ 33-char pages (the 600-px clip at ×3), each shown for 3 s with an instant swap; milestone pre-emption is kept without the flash |
| Diorama critter 2-frame idle | on | frozen on frame 0 |
| Critter arrival and exit on Evolve | Animator motion | 150 ms fade |
| Golden bob, wobble, drift | 8 px, ±8°, 18 px/s | **none: static target** (also a motor benefit) |
| Golden despawn blink | 6 Hz | **2 Hz** |
| Frenzy edge glow pulse | 2 Hz | static glow |
| Tap Frenzy banana glow pulse | 4 Hz (see OBJ-2: 3 Hz default) | static glow |
| Buy success (row flash, owned pop, icon hop) | on | flash kept (alpha only); pop and hop off |
| Affordability glint sweep | on | off (the raised pill and "BUY" carry the state) |
| Upgrade pop and shelf reflow | 200 / 150 ms | instant reflow |
| List momentum and reveal auto-scroll | on | momentum kept (user-driven); **auto-scroll off** |
| Overlay enter and exit | Animator | ≤ 150 ms fade, no scale or slide |
| EVOLVE_TX | fade to white 400 → card 800 → fade in 300 | **200 ms crossfade to a dark card** → card 800 → 200 ms crossfade |
| Title CTA pulse, FTUE hand bob, P1/P2 border pulse | on | static |
| Evolve button enabled glint | on | off |

**v1.1 juice coverage (`motion/ui-juice.yaml`, reviewed by UX).** All 8 entries declare a reduced-motion variant, and none flashes above 2 Hz. **Coverage: complete.**

| Entry | Reduced motion |
|---|---|
| J1 pill squish | disabled; the press-frame cut and label drop stay |
| J2 stat gain | reduced to an instant `q`-on-`U` tint held 300 ms |
| J3 hop cascade | disabled |
| J4 pill hello (one pill every 8 s) | disabled |
| J5 badge pop | disabled (cut) |
| J6 drop-in | reduced to a 120 ms fade |
| J7 tab bounce | reduced to a cut plus a 100 ms cross-fade |
| J8 ticker letter hop | disabled (paged ticker) |

Each entry is either a one-shot event (J1–J3, J5–J8) or sparse (J4, gated by the 8-s round-robin), so the peripheral-fade rule holds. No juice touches the stage or any hit area.

**Flash safety (WCAG 2.3.1).** Default mode: the only element above 3 Hz is the Golden blink (6 Hz). It covers ≤ 84 logical px, which is about 67 CSS px even at 0.8× (iPad), far below the general-flash area threshold, and it is gold rather than saturated red. The Tap Frenzy glow on the 240-px banana is the large-area case, so OBJ-2 moves it to 3 Hz. EVOLVE_TX is a single flash to white (1 flash, under 3 per second), which is allowed, and reduced motion removes it anyway.

### 5. Keyboard

| Key | Context | Action |
|---|---|---|
| **Space** | `MAIN`, no overlay | Tap the Big Banana (no key-repeat; counts toward the 16/s cap; floater at the banana centre ±24 px) |
| **Space / Enter** | `TITLE` | Start (does **not** award a tap; only a pointer-down on the banana does) |
| **Esc** | `MAIN` | Open `SETTINGS` |
| **Esc** | any overlay | Close the top overlay (= its cancel path; `OFFLINE` collects; `RESET_CONFIRM` cancels) |
| **Tab / Shift+Tab**, **↑↓←→** | overlays | Move focus among that overlay's controls in reading order; focus **stays inside** the top modal (no escape to Main), and Esc always exits |
| **Enter / Space** | overlays | Activate the focused control (toggle, button) |
| **1–8** (Tier B, SHOULD) | `MAIN`, PRODUCERS tab | Buy producer tier N if revealed (current buy mode). Silent no-op when unrevealed; the can't-afford feedback plays if unaffordable |
| **B** (Tier B, SHOULD) | `MAIN` | Cycle the buy mode (once revealed) |

**Focus ring.** A 4-px (1 art px) outline, 4 px outside the control's visual rect, ≥ 3:1 (N3). It is shown only after the first keyboard event of the session (the focus-visible heuristic), so pointer users never see it.

**Default focus.**

| Overlay | Default focus |
|---|---|
| SETTINGS | the SOUND EFFECTS row |
| RESET_CONFIRM | CANCEL |
| EVOLUTION `ready` | EVOLVE! |
| EVOLUTION `preview` | BACK |
| OFFLINE | COLLECT |

### 6. Touch targets

The policy is in `hud-layout.md` §1: **every hit area ≥ 104×104 logical px, which is ≥ 44 CSS px at any visible viewport ≥ 305×542 CSS px.** Audit list (hit rects):

| Control | w×h | Worst scale 0.432 → CSS px |
|---|---|---|
| Big Banana | 272×272 | 117 |
| Golden (Ø) | 112 | 48 |
| Shop row | 688×104 | 297×45 |
| Tabs | 252 / 260 × 104 | 45 tall |
| Buy toggle | 184×104 | 45 tall |
| Gear | 104×104 | 45 |
| Evolve | 216×104 | 45 tall |
| Every ✕ | 104×104 | 45 |
| Settings rows | 592×104 | 45 tall |
| Modal buttons | 232–296 × 104 | 45 tall |

Adjacent hit areas tile without overlap. FTUE hands and callouts are non-interactive, so they never steal a target.

### 7. Sustained-input and timing alternates

| Mechanic | Sustained / timed? | Alternate |
|---|---|---|
| Tap the banana | repeated tapping | Optional by design: producers plus offline income progress with zero taps (the sim's idle profile reaches first Evolve at 16:41). Space key; multi-touch; nothing requires speed |
| Hold-to-repeat buy | hold 400 ms, repeats every 100 ms | ×10 / MAX buy modes (single tap); keys 1–8 (Tier B) |
| Golden catch | 10-s window, moving target | Optional reward (a miss costs nothing); reduced motion makes it static; hit Ø 112 px. A configurable timer multiplier is Tier C (it would change the economy, which is the GD's call) |
| Evolve | none | — |

**Assumption for the Game Designer to confirm:** reduced-motion Goldens are static and therefore easier to catch. At most this raises Golden income toward the designed "catch every one" ceiling (+35%), never beyond it, so the economy stays within the GD's stated ≤ +50% bound.
