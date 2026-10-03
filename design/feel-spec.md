> **Status (2026-09-28): still the feel reference, re-skinned.** The `feel-tunables` block keeps applying to the same verbs (Big Banana → the Magician's hat, Golden Banana → the Suitcase; the Suitcase flight times in `content.json` `golden.flight` follow UX §3.4). Names below are the fork's.

# feel-spec — Monkey Bananas

Owner: Game Designer. Consumers: Game Developer (mirrors §8 verbatim into `src/core/tuning.ts`), Animator (motion co-spec on the polish rows), Audio Director (cue impact frames), 2D Artist and Technical Artist (readability of squash on pixel art).
Target: 60 fps. Logical canvas 720×1280, portrait, `Scale.FIT`, `pixelArt: true`. All `px` values are **logical** px. At a typical 390 pt-wide phone, 1 logical px ≈ 0.54 pt.

**Economy values are not feel tunables.** Crit chance (`tap.critChance`, 5%), crit multiplier (`tap.critMult`, ×10), the tap cap (`tap.maxRegisteredTapsPerSec`, 16/s), and the Golden spawn timing, lifetime and rewards (`golden.*`: first spawn 75 s, interval 90–180 s, lifetime 10 s, Bunch 60 s of bps, Frenzy ×5 for 15 s, Tap Frenzy ×10 for 12 s) are canonical in [`content.json`](content.json). The §8 blocks deliberately exclude them so that no number has two sources of truth. Code reads them from content.json.

Reference anchors used below:
- **Swink-GameFeel**: Steve Swink, *Game Feel* (2008). About 100 ms is the ceiling for a response to feel instant; about 50 ms or less reads as "part of me".
- **CookieClicker-bigCookie**: the big cookie shrinks on press and springs back, and a "+N" number floats up and fades at the cursor. This is a behavioral anchor; our numbers are authored here.
- **CookieClicker-goldenCookie**: a randomly placed, short-lived bonus object whose click rolls a buff (the original is on screen for about 13 s). A contrast anchor: ours is more frequent and much weaker.
- **Vlambeer-screenshake**: Jan Willem Nijman, "The Art of Screenshake" (2013). Short, small, decaying shakes on high-value events only.
- **Disney-squash-stretch**: squash preserves volume. 1.12 × 0.88 ≈ 0.99 area.
- **AppleHIG-44pt / Material-48dp**: minimum touch target sizes.
- **WCAG-2.3.1**: Three Flashes or Below Threshold. Nothing may flash more than 3 times in any 1 s.
- **AdCap-buy-toggle**: the AdVenture Capitalist ×1 / ×10 / ×100 / MAX buy toggle convention.

---

## 1. Verb: tap (Big Banana)

### Latency
| | Frames @60 | ms | Anchor |
|---|---|---|---|
| Target: pointer-down → squash, floater, bank update and SFX visible | 1 | 17 | Swink-GameFeel |
| Ceiling | 2 | 33 | Swink-GameFeel (touch adds about 2 frames of OS latency, which we accept) |

Everything fires on **pointer-down**, never on pointer-up.

### Juice budget (frame 0 = pointer-down frame)
| Component | Fires | Numbers |
|---|---|---|
| Award plus bank counter pop | f0 | Counter scale 1.06 → 1 over 80 ms |
| Squash | f0 | **Drawn-frame squash, not a scale tween** (revised after Animator objection O1; see motion/object-motion.md §1). A virtual Y driver runs down to 0.88 (X 1.12) over 40 ms, then back to 1.0 over 140 ms with a Back-out overshoot of 2.2, so the stretch pose holds for about 3 frames per tap. The driver selects one of 5 drawn frames: rest, 0.94, 0.88, 0.84 (deep squash, also the crit pose), 1.02 stretch. The sprite always renders at its integer ×5 scale. A tap during a squash restarts the driver from its current value, clamped so that Y never drops below 0.84. The pivot is bottom-center, so the banana squashes into its "ground" |
| Floater "+N" | f0 | Spawns at the pointer position with a random X jitter of ±24 px. Rises 88 px (a whole number of art pixels) over 700 ms (cubic ease-out) and fades out from 400 ms to 700 ms. Text height 28 px. At most 24 floaters at once (pooled; the oldest is recycled) |
| Tap chips | f0 | 3 pixel chips (banana-yellow, 2×2 art px), speed 220 px/s in the upper 180° arc, gravity 600 px/s², life 350 ms |
| Tap SFX | f0 | Audio Director owns the sound; the frame is fixed here |
| Hit-stop | none | **0 frames by design.** Freezing would drop feedback at 16 taps/s and make the tap feel sticky |
| Hover (mouse only) | on hover | No scale change (`magicianHoverScale` 1.0, which keeps the banana at an integer scale; Animator O2). A halo sprite fades to alpha 0.3 over 100 ms, and the cursor becomes a hand |

### Crit tap (a variant of the tap; chance and multiplier come from content.json)
| Component | Fires | Numbers |
|---|---|---|
| Crit floater "+N!" | f0 | Text height 42 px (a 7 px font drawn ×6), a distinct crit color (the 2D Artist picks it; it must not be the normal floater color). Pops to 1.3 over 120 ms, rises 120 px over 900 ms |
| Screen shake | f0–f6 | 3 px amplitude, integer px offsets only (pixel grid), 100 ms, linear decay. Vlambeer-screenshake |
| Crit burst | f0 | 10 chips, speed 320 px/s, life 450 ms |
| Crit SFX | f0 | Layered over the tap SFX. The Audio Director may duck the tap layer |

Reduced-motion setting (UX owns the toggle): shake amplitude drops to 0 and chip counts are halved. The floaters stay.

### Forgiveness
The Big Banana's hit area is its sprite bounds plus 16 px of padding on every side, so a tap on the banana's edge always counts. There is no buffer or coyote window, because the verb is stateless. Taps beyond 16/s are dropped silently (content.json), with no squash and no floater, so feedback never shows income that did not happen.

### Per-modality
| Modality | Event | Latency budget | Forgiveness | Notes |
|---|---|---|---|---|
| Touch | pointer-down | 1 target / 2 ceiling frames (the OS adds about 2) | +16 px pad | Multi-touch allowed, capped globally |
| Mouse | left pointer-down | 1 / 2 frames | +16 px pad | Hover halo at alpha 0.3, no scale |
| Keyboard | Space keydown, no repeat | 1 / 2 frames | n/a | The floater spawns at the banana center with jitter |

---

## 2. Verb: catch (Golden Banana)

### Readability and motion
| Parameter | Value | Anchor |
|---|---|---|
| Spawn area | The center must lie in x ∈ [0.12, 0.88] of W and y ∈ [0.20, 0.50] of H, and at least 0.25 W (180 px) from the Big Banana center at (360, 416). Positions are **rejection-sampled**: up to 20 tries, and if all fail, a random corner of the spawn rectangle (every corner is at least 317 px from the banana center). About 52% of the rectangle is valid, so the fallback is practically never used. The bottom bound keeps the hit circle at y ≤ 696, above the shop at 712 (UX OBJ-1) | CookieClicker-goldenCookie (random placement), constrained to ux/hud-layout.md |
| Hit radius | 56 px, a 112 px diameter, about 60 pt on a phone (above AppleHIG-44pt) | AppleHIG-44pt |
| Spawn | Fades in over 300 ms while scaling 0.6 → 1.0. Spawn SFX at f0 | — |
| Idle motion | Bobs 8 px at 1.2 Hz. Wobbles by stepping between **two drawn tilt frames** (−8° / +8°) at 0.8 Hz; there is no runtime rotation, so pixels do not crawl (Animator O3). Setting `goldenWobbleDeg` to 0 disables the tilt frames. It drifts 18 px/s in a random direction and reflects off both the spawn-area edges and the exclusion circle (reflect the velocity about the circle normal), so it never drifts over the banana | — |
| Despawn warning | Blinks in the last 2,000 ms, alpha 1 ↔ 0.35 at 6 Hz | — |
| Despawn (missed) | Fades out over 200 ms with a soft SFX. No penalty | — |
| Modal open | The spawn timer and the on-screen Golden's remaining lifetime both **pause** while any modal or scrim is open (Settings, Evolution, Offline). Production and buffs keep running (UX OBJ-4) | — |

### Latency and juice (frame 0 = pointer-down on the Golden)
| Component | Fires | Numbers |
|---|---|---|
| Award or buff start | f0 | — |
| Pop | f0 | Scale 1.0 → 1.5 over 150 ms while fading to 0 |
| Burst | f0 | 16 gold chips, speed 360 px/s, life 600 ms |
| Banner | f0 | "LUCKY BUNCH! +N" / "BANANA FRENZY ×5!" / "TAP FRENZY ×10!", held for 1,600 ms, 200 ms fade in and out |
| Shake | f0 | 4 px, 150 ms (reduced motion: 0) |
| Buff presence (Frenzy) | while active | The bps readout turns gold, a depleting timer bar shows, and the screen-edge glow pulses at 2 Hz |
| Buff presence (Tap Frenzy) | while active | The Big Banana glow pulses at 3 Hz, the WCAG 2.3.1 three-flashes-per-second limit (UX OBJ-2). Under reduced motion the glow is static. Floaters take the crit color |

Latency target 1 frame, ceiling 2 frames (the same `tapLatencyTargetFrames` / `tapLatencyCeilingFrames` budget applies). Input priority: the two hit areas can still overlap slightly. The Golden's 56 px hit circle, 180 px from the banana center, reaches 124 px from it, while the banana's hit square extends 136 px on each axis. **Resolution rule:** a tap inside both hit areas goes to the Golden only if it lands inside the Golden's drawn bounds (64×64 px); otherwise it goes to the Big Banana. At 180 px the drawn Golden never enters the banana's on-axis hit square, so rapid banana taps cannot catch a Golden by accident. A tap outside the banana's hit area uses the full 56 px circle.

Per-modality: touch and mouse behave the same (a 56 px radius already exceeds the touch minimum). Keyboard has no path to catch a Golden in the MVP. This is accepted, because Goldens are optional (mechanic-spec D4 and the §8 audit).

---

## 3. Verb: buy (producer row / upgrade)

| Component | Fires | Numbers | Anchor |
|---|---|---|---|
| Press state | pointer-down f0 | Scale 0.95 over 60 ms; restores over 80 ms on release | Swink-GameFeel |
| Commit | pointer-up inside the bounds | Cancelled if the pointer moved more than 10 px (the list may scroll) | — |
| Success | commit f0 | The row flashes white from alpha 0.6 to 0 over 80 ms. The owned count pops 1.25 → 1 over 150 ms. The row icon hops 8 px (2 art pixels at ×4) over 120 ms. The bank decrements the same frame. Buy SFX at f0 | — |
| Upgrade success | commit f0 | The icon pops 1.3 → 0 over 200 ms and the shelf reflows over 150 ms | — |
| Can't afford | commit f0 | Horizontal shake of ±4 px, 3 cycles over 180 ms, dull SFX, nothing deducted | — |
| Hold to repeat | while held | Starts after 400 ms and buys every 100 ms. Each repeat is a full "success" (Audio may throttle). Stops at the first can't-afford | AdCap-buy-toggle convention |
| Became affordable | state edge | One glint sweep, 250 ms. At most one glint per row per 5 s, so a bank hovering around the cost does not flicker | — |
| Buy-mode toggle | tap | Cycles ×1 → ×10 → MAX. Costs relabel within 1 frame | AdCap-buy-toggle |

Latency target: press state within `tapLatencyTargetFrames` (1) of pointer-down, and commit within 1 frame of pointer-up. Minimum row height is 96 px (about 52 pt, above Material-48dp); the UX Designer owns the layout.

---

## 4. Meta beats (Evolve, offline, ticker)

| Beat | Numbers |
|---|---|
| Evolve transition | At most 1,500 ms in total: fade to white over 400 ms, species-title card for 800 ms, fade in over 300 ms. Input is locked throughout, and the save completes before the transition starts |
| Offline collect | The modal counter rolls 0 → award over 800 ms (cubic ease-out). Collect SFX when the roll ends |
| Milestone headline | The ticker scrolls at 90 px/s. A new milestone pre-empts ambient text with a 120 ms flash |

---

## 8. Tuning surface: `feel-tunables`

Mirror these blocks verbatim into `src/core/tuning.ts`. Every key must be read by code (presence is not consumption; see `feel-tunables-block.md` rule 6). The keys are already unique across the four blocks, so no verb prefix is needed.

```yaml
feel-tunables:
  verb: tap
  params:
    - { param: tapLatencyTargetFrames,   value: 1,    unit: frames, source_ref: Swink-GameFeel,          range: [1, 1],       frozen: true }
    - { param: tapLatencyCeilingFrames,  value: 2,    unit: frames, source_ref: Swink-GameFeel,          range: [2, 2],       frozen: true }
    - { param: squashScaleX,             value: 1.12, unit: ratio,  source_ref: Disney-squash-stretch,   range: [1.06, 1.16], frozen: false }
    - { param: squashScaleY,             value: 0.88, unit: ratio,  source_ref: Disney-squash-stretch,   range: [0.84, 0.94], frozen: false }
    - { param: squashMinScaleY,          value: 0.84, unit: ratio,  source_ref: Disney-squash-stretch,   range: [0.80, 0.88], frozen: false }
    - { param: squashDownMs,             value: 40,   unit: ms,     source_ref: CookieClicker-bigCookie, range: [30, 60],     frozen: false }
    - { param: squashReturnMs,           value: 140,  unit: ms,     source_ref: CookieClicker-bigCookie, range: [100, 200],   frozen: false }
    - { param: squashReturnOvershoot,    value: 2.2 ,  unit: ratio,  source_ref: Disney-squash-stretch,   range: [1.0, 2.5],   frozen: false }
    - { param: magicianHitPadPx,        value: 16,   unit: px,     source_ref: AppleHIG-44pt,           range: [8, 24],      frozen: false }
    - { param: magicianHoverScale,      value: 1.0 , unit: ratio,  source_ref: CookieClicker-bigCookie, range: [1.0, 1.06],  frozen: false }
    - { param: magicianHoverHaloAlpha,  value: 0.3,  unit: ratio,  source_ref: CookieClicker-bigCookie, range: [0.0, 0.5],   frozen: false }
    - { param: magicianHoverMs,         value: 100,  unit: ms,     source_ref: CookieClicker-bigCookie, range: [60, 150],    frozen: false }
    - { param: bankPopScale,             value: 1.06, unit: ratio,  source_ref: CookieClicker-bigCookie, range: [1.0, 1.10],  frozen: false }
    - { param: bankPopMs,                value: 80,   unit: ms,     source_ref: CookieClicker-bigCookie, range: [50, 120],    frozen: false }
    - { param: floaterJitterXPx,         value: 24,   unit: px,     source_ref: CookieClicker-bigCookie, range: [0, 40],      frozen: false }
    - { param: floaterRisePx,            value: 88,   unit: px,     source_ref: CookieClicker-bigCookie, range: [60, 140],    frozen: false }
    - { param: floaterRiseMs,            value: 700,  unit: ms,     source_ref: CookieClicker-bigCookie, range: [500, 1000],  frozen: false }
    - { param: floaterFadeStartMs,       value: 400,  unit: ms,     source_ref: CookieClicker-bigCookie, range: [200, 600],   frozen: false }
    - { param: floaterTextHeightPx,      value: 28,   unit: px,     source_ref: AppleHIG-44pt,           range: [24, 36],     frozen: false }
    - { param: floaterMaxConcurrent,     value: 24,   unit: count,  source_ref: CookieClicker-bigCookie, range: [12, 32],     frozen: false }
    - { param: tapChipCount,             value: 3,    unit: count,  source_ref: Vlambeer-screenshake,    range: [0, 6],       frozen: false }
    - { param: tapChipArcDeg,            value: 180,  unit: deg,    source_ref: Vlambeer-screenshake,    range: [90, 180],    frozen: false }
    - { param: tapChipSpeed,             value: 220,  unit: px/s,   source_ref: Vlambeer-screenshake,    range: [120, 320],   frozen: false }
    - { param: chipGravity,              value: 600,  unit: px/s2,  source_ref: Vlambeer-screenshake,    range: [300, 900],   frozen: false }
    - { param: tapChipLifeMs,            value: 350,  unit: ms,     source_ref: Vlambeer-screenshake,    range: [200, 500],   frozen: false }
    - { param: tapHitStopFrames,         value: 0,    unit: frames, source_ref: Swink-GameFeel,          range: [0, 0],       frozen: true }
    - { param: critFloaterTextHeightPx,  value: 42,   unit: px,     source_ref: CookieClicker-bigCookie, range: [36, 56],     frozen: false }
    - { param: critFloaterPopScale,      value: 1.3,  unit: ratio,  source_ref: Disney-squash-stretch,   range: [1.1, 1.5],   frozen: false }
    - { param: critFloaterPopMs,         value: 120,  unit: ms,     source_ref: Disney-squash-stretch,   range: [80, 180],    frozen: false }
    - { param: critFloaterRisePx,        value: 120,  unit: px,     source_ref: CookieClicker-bigCookie, range: [90, 180],    frozen: false }
    - { param: critFloaterRiseMs,        value: 900,  unit: ms,     source_ref: CookieClicker-bigCookie, range: [700, 1200],  frozen: false }
    - { param: critShakePx,              value: 3,    unit: px,     source_ref: Vlambeer-screenshake,    range: [0, 5],       frozen: false }
    - { param: critShakeMs,              value: 100,  unit: ms,     source_ref: Vlambeer-screenshake,    range: [60, 160],    frozen: false }
    - { param: critChipCount,            value: 10,   unit: count,  source_ref: Vlambeer-screenshake,    range: [6, 16],      frozen: false }
    - { param: critChipSpeed,            value: 320,  unit: px/s,   source_ref: Vlambeer-screenshake,    range: [200, 420],   frozen: false }
    - { param: critChipLifeMs,           value: 450,  unit: ms,     source_ref: Vlambeer-screenshake,    range: [300, 600],   frozen: false }
    - { param: reducedMotionChipFactor,  value: 0.5,  unit: ratio,  source_ref: AppleHIG-44pt,           range: [0.5, 0.5],   frozen: true }
```

```yaml
feel-tunables:
  verb: catch
  params:
    - { param: goldenSpawnXMin,          value: 0.12, unit: frac-W, source_ref: CookieClicker-goldenCookie, range: [0.08, 0.20], frozen: false }
    - { param: goldenSpawnXMax,          value: 0.88, unit: frac-W, source_ref: CookieClicker-goldenCookie, range: [0.80, 0.92], frozen: false }
    - { param: goldenSpawnYMin,          value: 0.20, unit: frac-H, source_ref: CookieClicker-goldenCookie, range: [0.15, 0.30], frozen: false }
    - { param: goldenSpawnYMax,          value: 0.50, unit: frac-H, source_ref: CookieClicker-goldenCookie, range: [0.50, 0.68], frozen: false }
    - { param: goldenMagicianExclusion, value: 0.25, unit: frac-W, source_ref: CookieClicker-goldenCookie, range: [0.16, 0.30], frozen: false }
    - { param: goldenSpawnMaxTries,      value: 20,   unit: count,  source_ref: CookieClicker-goldenCookie, range: [10, 40],    frozen: false }
    - { param: goldenHitRadiusPx,        value: 56,   unit: px,     source_ref: AppleHIG-44pt,             range: [44, 72],     frozen: false }
    - { param: goldenFadeInMs,           value: 300,  unit: ms,     source_ref: CookieClicker-goldenCookie, range: [150, 500],  frozen: false }
    - { param: goldenSpawnStartScale,    value: 0.6,  unit: ratio,  source_ref: Disney-squash-stretch,     range: [0.4, 1.0],   frozen: false }
    - { param: goldenBobPx,              value: 8,    unit: px,     source_ref: CookieClicker-goldenCookie, range: [4, 12],     frozen: false }
    - { param: goldenBobHz,              value: 1.2,  unit: hz,     source_ref: CookieClicker-goldenCookie, range: [0.8, 1.6],  frozen: false }
    - { param: goldenWobbleDeg,          value: 8,    unit: deg,    source_ref: CookieClicker-goldenCookie, range: [0, 12],     frozen: false }  # drawn tilt-frame angle (not a runtime rotation); 0 disables the tilt frames
    - { param: goldenWobbleHz,           value: 0.8,  unit: hz,     source_ref: CookieClicker-goldenCookie, range: [0.5, 1.2],  frozen: false }
    - { param: goldenDriftSpeed,         value: 18,   unit: px/s,   source_ref: CookieClicker-goldenCookie, range: [0, 30],     frozen: false }
    - { param: goldenBlinkLastMs,        value: 2000, unit: ms,     source_ref: CookieClicker-goldenCookie, range: [1500, 3000], frozen: false }
    - { param: goldenBlinkHz,            value: 6,    unit: hz,     source_ref: CookieClicker-goldenCookie, range: [4, 8],      frozen: false }
    - { param: goldenBlinkMinAlpha,      value: 0.35, unit: ratio,  source_ref: CookieClicker-goldenCookie, range: [0.2, 0.5],  frozen: false }
    - { param: goldenDespawnFadeMs,      value: 200,  unit: ms,     source_ref: CookieClicker-goldenCookie, range: [100, 300],  frozen: false }
    - { param: goldenCatchPopScale,      value: 1.5,  unit: ratio,  source_ref: Disney-squash-stretch,     range: [1.2, 1.8],   frozen: false }
    - { param: goldenCatchPopMs,         value: 150,  unit: ms,     source_ref: Disney-squash-stretch,     range: [100, 250],   frozen: false }
    - { param: goldenBurstCount,         value: 16,   unit: count,  source_ref: Vlambeer-screenshake,      range: [8, 24],      frozen: false }
    - { param: goldenBurstSpeed,         value: 360,  unit: px/s,   source_ref: Vlambeer-screenshake,      range: [240, 480],   frozen: false }
    - { param: goldenBurstLifeMs,        value: 600,  unit: ms,     source_ref: Vlambeer-screenshake,      range: [400, 800],   frozen: false }
    - { param: goldenCatchShakePx,       value: 4,    unit: px,     source_ref: Vlambeer-screenshake,      range: [0, 6],       frozen: false }
    - { param: goldenCatchShakeMs,       value: 150,  unit: ms,     source_ref: Vlambeer-screenshake,      range: [80, 220],    frozen: false }
    - { param: buffBannerHoldMs,         value: 1600, unit: ms,     source_ref: CookieClicker-goldenCookie, range: [1000, 2500], frozen: false }
    - { param: buffBannerFadeMs,         value: 200,  unit: ms,     source_ref: CookieClicker-goldenCookie, range: [100, 300],  frozen: false }
    - { param: frenzyEdgePulseHz,        value: 2,    unit: hz,     source_ref: CookieClicker-goldenCookie, range: [1, 3],      frozen: false }
    - { param: tapFrenzyGlowStaticUnderReducedMotion, value: true, unit: bool, source_ref: WCAG-2.3.1, range: [true, true], frozen: true }
    - { param: tapFrenzyGlowPulseHz,     value: 3,    unit: hz,     source_ref: CookieClicker-goldenCookie, range: [2, 6],      frozen: false }
```

```yaml
feel-tunables:
  verb: buy
  params:
    - { param: buyPressScale,            value: 0.95, unit: ratio,  source_ref: Swink-GameFeel,     range: [0.90, 0.98], frozen: false }
    - { param: buyPressMs,               value: 60,   unit: ms,     source_ref: Swink-GameFeel,     range: [40, 100],    frozen: false }
    - { param: buyReleaseMs,             value: 80,   unit: ms,     source_ref: Swink-GameFeel,     range: [50, 120],    frozen: false }
    - { param: buyDragCancelPx,          value: 10,   unit: px,     source_ref: AppleHIG-44pt,      range: [6, 16],      frozen: false }
    - { param: buyFlashAlpha,            value: 0.6,  unit: ratio,  source_ref: Swink-GameFeel,     range: [0.3, 0.8],   frozen: false }
    - { param: buyFlashMs,               value: 80,   unit: ms,     source_ref: Swink-GameFeel,     range: [50, 150],    frozen: false }
    - { param: ownedPopScale,            value: 1.25, unit: ratio,  source_ref: Disney-squash-stretch, range: [1.1, 1.4], frozen: false }
    - { param: ownedPopMs,               value: 150,  unit: ms,     source_ref: Disney-squash-stretch, range: [100, 220], frozen: false }
    - { param: iconHopPx,                value: 8,    unit: px,     source_ref: Disney-squash-stretch, range: [0, 10],    frozen: false }
    - { param: iconHopMs,                value: 120,  unit: ms,     source_ref: Disney-squash-stretch, range: [80, 180],  frozen: false }
    - { param: upgradePopScale,          value: 1.3,  unit: ratio,  source_ref: Disney-squash-stretch, range: [1.1, 1.5], frozen: false }
    - { param: upgradePopMs,             value: 200,  unit: ms,     source_ref: Disney-squash-stretch, range: [120, 300], frozen: false }
    - { param: shelfReflowMs,            value: 150,  unit: ms,     source_ref: Swink-GameFeel,     range: [100, 250],   frozen: false }
    - { param: cantAffordShakePx,        value: 4,    unit: px,     source_ref: Vlambeer-screenshake, range: [2, 6],     frozen: false }
    - { param: cantAffordShakeCycles,    value: 3,    unit: count,  source_ref: Vlambeer-screenshake, range: [2, 4],     frozen: false }
    - { param: cantAffordShakeMs,        value: 180,  unit: ms,     source_ref: Vlambeer-screenshake, range: [120, 260], frozen: false }
    - { param: holdRepeatDelayMs,        value: 400,  unit: ms,     source_ref: AdCap-buy-toggle,   range: [300, 600],   frozen: false }
    - { param: holdRepeatIntervalMs,     value: 100,  unit: ms,     source_ref: AdCap-buy-toggle,   range: [60, 200],    frozen: false }
    - { param: affordGlintMs,            value: 250,  unit: ms,     source_ref: Swink-GameFeel,     range: [150, 400],   frozen: false }
    - { param: affordGlintCooldownMs,    value: 5000, unit: ms,     source_ref: Swink-GameFeel,     range: [2000, 10000], frozen: false }
    - { param: minRowHeightPx,           value: 96,   unit: px,     source_ref: Material-48dp,      range: [88, 120],    frozen: false }
```

```yaml
feel-tunables:
  verb: meta
  params:
    - { param: evolveFadeOutMs,          value: 400,  unit: ms,     source_ref: Swink-GameFeel,     range: [250, 600],   frozen: false }
    - { param: evolveTitleCardMs,        value: 800,  unit: ms,     source_ref: Swink-GameFeel,     range: [500, 1200],  frozen: false }
    - { param: evolveFadeInMs,           value: 300,  unit: ms,     source_ref: Swink-GameFeel,     range: [200, 500],   frozen: false }
    - { param: offlineRollMs,            value: 800,  unit: ms,     source_ref: Swink-GameFeel,     range: [400, 1500],  frozen: false }
    - { param: tickerScrollSpeed,        value: 90,   unit: px/s,   source_ref: Swink-GameFeel,     range: [60, 140],    frozen: false }
    - { param: headlineFlashMs,          value: 120,  unit: ms,     source_ref: Swink-GameFeel,     range: [80, 200],    frozen: false }
```

## Handoffs
- **Game Developer.** Mirror §8 verbatim and read every key. Read economy values from content.json. Render floaters and banners with pooled objects.
- **Animator.** Owns the curve shapes inside these durations (squash Back-out, Golden bob and wobble, the Evolve card). Push back if 40 ms for the squash going down reads as a pop on 8× pixel art.
- **2D Artist / Technical Artist.** The squash is drawn frames (rest, 0.94, 0.88, 0.84, 1.02 stretch), and the Golden wobble is two drawn tilt frames (±8°). Nothing gameplay-persistent renders at a fractional scale. The remaining fractional scales are transients under 180 ms, listed in motion/motion-spec.yaml `_globals`. The Golden must be at most 0.35× the Big Banana's on-screen size and must never share its hue.
- **Audio Director.** Every "Fires f0" row is a cue impact frame. The tap and buy cues can fire 16/s and 10/s respectively, so plan polyphony and variation for that rate.
