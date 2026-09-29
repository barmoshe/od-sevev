# object-motion — Monkey Bananas

Owner: Animator. Consumers: Game Developer (wiring), 2D Artist (the frame requests in §6), Technical Artist (fx anchors), Audio Director (see `event-markers.md`).
Numbers written as `<tunable>` are read from `src/core/tuning.ts` (feel-spec §8). Values marked **MC** are Animator motion constants and go in `src/core/motion.ts`. The global snap and quantize rules are in `motion-spec.yaml` doc `_globals`.

**Pixel snap (every movement in this file):** a rendered position is `snap(v, g) = Math.round(v / g) * g`, where g is the sprite's texel size in logical px: **g = 4** for ×4 sprites (Golden, critters, icons, chips), **g = 5** for the Big Banana (drawn ×5). Float positions are kept internally; only the rendered value is snapped. Nothing is drawn at a fractional scale except the transients listed in `_globals` (all under 180 ms).

**Attention tiers** (object-and-environmental-animation DOG: a lower tier never out-moves a higher one while both are active):

| Tier | Object | Loudest motion |
|---|---|---|
| T1 (the "character") | Big Banana | Tap squash, 5 frames, up to 16 restarts/s |
| T2 (active prop, time-limited) | Golden Banana | ±1 art-px bob at 1.2 Hz, tilt frames at 0.8 Hz, 6 Hz blink in its last 2 s |
| T4 (ambient) | Critters, clouds | A 2-frame idle at 1-4 fps, a 1-2 art-px hop every 4-9 s |

The Golden out-moves the Big Banana's *idle* on purpose: it is the attention reward. It never out-moves the Big Banana while the player is tapping.

---

## 1. Big Banana (T1). 48×49 canvas, drawn ×5 (rest silhouette 140×225 px), pivot bottom-centre (0.5, 1)

### 1.1 Frame set (delivered by the 2D Artist: `SPRITE_META.bigBanana`, canvas 48×49, shared bottom baseline on row 48)

| Frame | Pose | Visible W×H (art px) | heightRatio | Quantize band (driver Y) |
|---|---|---|---|---|
| 4 | stretch 1.02 (overshoot) | 26×46 | 1.022 | Y ≥ 1.011 |
| 0 | rest | 28×45 | 1.000 | 0.9667 ≤ Y < 1.011 |
| 1 | squash 0.94 | 28×42 | 0.933 | 0.900 ≤ Y < 0.9667 |
| 2 | squash 0.88 (happy squint) | 30×39 | 0.867 | 0.8555 ≤ Y < 0.900 |
| 3 | deep squash 0.84 / crit | 32×38 | 0.844 | Y < 0.8555 |

Band edges are the midpoints of adjacent `heightRatio` values. Compare retunes against `heightRatio`, not against 48 rows (per the artist's note). Driver targets land where they should: `<squashScaleY>` 0.88 → frame 2, `<squashMinScaleY>` 0.84 → frame 3, and the overshoot-2.2 peak Y 1.0185 → frame 4. **Hit area** = `restBounds` (28×45 art at canvas x10-37, y4-48, which is 140×225 px at ×5) + `<bigBananaHitPadPx>` (16) on every side. It is fixed and never follows the animated frame.

### 1.2 Idle (state `idle`)
- **Bob:** a parent container's y toggles between 0 and −5 px (1 art-px at ×5) every **1600 ms** (MC `bbBobHalfMs`). The period is 3200 ms (at least 3 s, the ambient-fatigue floor). Use a looped `TimerEvent` toggle; do **not** use a yoyo 'Stepped' tween (see `_globals.stepped_ease_warning`). Pixel-snapped (g = 5).
- **Bob pause:** a registered tap sets the bob to 0 at once. The bob restarts **600 ms** (MC `bbBobResumeMs`) after the body returns to `idle`, with no tap in between.
- **Idle fidget (fatigue breaker):** every U(6000, 9000) ms (MC) while idle, `particle_sparkle` drawn ×5 at the peel highlight plays frames 0 → 1 → 0 at 80 ms each (240 ms total). It is skipped outside idle.
- **Banana Frenzy:** the bob half-period becomes 800 ms (MC `bbBobHalfFrenzyMs`).
- Reduced motion: no bob; the fidget is kept (a 3×3 texel swap in place).

### 1.3 Hover (mouse only; graph `big-banana-hover`)
- The halo sprite (behind the banana, §6) goes from opacity 0 → 0.3 over `<bigBananaHoverMs>` (100 ms), 'Quad.Out'. Pointer-out reverses it over 100 ms. `<bigBananaHoverScale>` is 1.0 (O2 accepted), so no scale is ever applied. The hand cursor is set on pointer-over.
- The halo is a separate sprite, so it never has to match the squash frames.

### 1.4 Tap squash (state `pressed`): the quantized driver
A Phaser tween drives an invisible number **Y**. The renderer calls `setFrame(bandOf(Y))` every frame (table 1.1). The X ratio is coupled to the frame (`<squashScaleX>` sets the authored widths, §6). **No `setScale` is ever applied to the Big Banana.**

- **Down phase** (`<squashDownMs>` = 40 ms): frames are set directly, time-based. Frame 1 for t < 0.4 × down (the f0 commit, synchronous in pointerdown; this meets `<tapLatencyTargetFrames>` = 1), then the target frame until t = down. Normal target Y_t = `<squashScaleY>` (0.88 → frame 2).
- **Return phase** (`<squashReturnMs>` = 140 ms): Y tweens Y_t → 1.0 with ease `'Back.Out'`, easeParams [`<squashReturnOvershoot>`], quantized every frame.
- **Frames at 60 fps, normal tap from rest** (`<squashReturnOvershoot>` 2.2, accepted; the band edges are from table 1.1):

  | f | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
  |---|---|---|---|---|---|---|---|---|---|---|---|
  | ms | 0 | 17 | 33 | 50 | 67 | 83 | 100 | 117 | 133 | 150 | 167 |
  | frame | 1 | 2 | 2 | 1 | 0 | 0 | **4** | **4** | **4** | 0 | 0 |

  That reads as squish (3 frames), rebound, stretch (3 frames), settle, ending at 180 ms.
- **Restart (tap during `pressed` or `crit`): it restarts and never stacks.** The down phase restarts from the current Y with Y_t = `max(<squashMinScaleY>, min(<squashScaleY>, Y_now − (1 − <squashScaleY>) / 3))`. So a tap caught while still compressed pushes about 2 art rows deeper, and never below 0.84 (frame 3). The f0 frame = the band of the midpoint (Y_now + Y_t)/2, forced at least one band deeper than the frame currently showing, when a deeper band exists. At 16 taps/s the banana pumps between frames 1, 2 and 3 and never shows a fractional scale.
- **Dropped taps** (over the 16/s cap): no restart, no frame change (feedback never shows income that did not happen).

### 1.5 Crit (state `crit`)
- The same driver with Y_t = `<squashMinScaleY>` (frame 3). Down phase: frame 1 at f0, frame 3 at f1 and f2. The return from 0.84 overshoots to Y 1.025, so frame 4 holds about 4 frames.
- **Impact flash:** fill-tint the sprite to the palette's lightest colour on f0-f1 (33 ms). In Phaser 4 that is `setTint(c)` plus tint mode FILL; baked flash variants are also fine. The flash is an overlay timer, independent of body state, so a following tap does not cancel it.
- **Camera shake** `<critShakePx>` 3 / `<critShakeMs>` 100 ms, integer offsets with linear decay and alternating x sign: **+3, −3, +2, −2, +1, −1, 0** (f0-f6). The y offset takes the same magnitude with a random sign. Reduced motion: 0.
- Crit floater and chips: `motion-spec.yaml` `crit-floater`; chips are the TA's fx-data, anchored at the pointer (keyboard: banana centre).

### 1.6 Tap Frenzy aura (graph `big-banana-aura`)
- Halo sprite (`bigBanana_halo`, 44×56, drawn ×5 behind the banana, origin (0.5, 0.5) at bigBanana canvas px (24, 26.5) per `SPRITE_META.alignTo`) opacity 0.35 ↔ 0.85, 'Sine.InOut' yoyo, half-period = 1000 / (2 × `<tapFrenzyGlowPulseHz>`), gold palette index. **I support UX OBJ-2's 3 Hz** (half-period 167 ms): it is the only large-area pulse (≈ 220×280 px), so 3 Hz keeps it at the WCAG 2.3.1 limit rather than over it. It still reads faster than the Frenzy edge pulse (2 Hz) and below the Golden blink (6 Hz), so the tier order holds. At 4 Hz it would be 125 ms. The code reads the tunable either way. On end, opacity → 0 over 300 ms 'Quad.In'. Reduced motion: static at 0.5.

---

## 2. Golden Banana (T2). 16×16 art, drawn ×4 (64 px), pivot centre

Frames (delivered): 0 = idle upright with sparkle, 1 = sparkle flare (upright), 2 = tilt −8° (counter-clockwise), 3 = tilt +8° (clockwise). Tilt sequence = frames **0, 3, 0, 2** (up, +8, up, −8). At ×4 the Golden is 64/240 = 0.27× the Big Banana (the rule is ≤ 0.35×).

| Phase | Motion (all positions snapped, g = 4) | Duration |
|---|---|---|
| **Spawn** (`spawning`) | Fixed position. Opacity 0 → 1 'Quad.Out'. Scale driver `<goldenSpawnStartScale>` 0.6 → 1.0 'Quad.Out', rendered as **integer** scale `round(driver × 4)`: **×2 at f0 → ×3 from f1 → ×4 from 132 ms** (a pop-in through whole texel sizes). The hit radius `<goldenHitRadiusPx>` (56) is live from f0. | `<goldenFadeInMs>` 300 |
| **Idle** (`idle`) | **Bob:** `y = snap(−4 · sin(2π · <goldenBobHz> · t), 4)`, so the offsets are {−4, 0, +4} = `<goldenBobPx>` 8 px peak-to-peak. **Tilt:** frame sequence up, +8°, up, −8°, 312.5 ms each (`1 / (<goldenWobbleHz> × 4)` = 3.2 fps). If `<goldenWobbleDeg>` = 0, only the upright frame plays. **Sparkle:** frame 1 (flare) replaces every 2nd "up" frame, so it flares once every 2500 ms (the DOG allows a shimmer at most once per 2-4 s). **Drift:** float position at `<goldenDriftSpeed>` 18 px/s in a random direction, rendered snapped (a 4 px step about every 222 ms). It reflects off the spawn-area edges and off the Big Banana exclusion circle (mirror the velocity about the radial normal). | until 2000 ms before the end of life |
| **Warning** (`warning`) | Idle motion continues and the flare is suppressed. Opacity square wave between 1 and `<goldenBlinkMinAlpha>` 0.35 at `<goldenBlinkHz>` 6 Hz (83 ms on, 83 ms off), starting in the "on" half. | `<goldenBlinkLastMs>` 2000 |
| **Caught** (`caught`) | f0: bob, drift and tilt stop; frame 1 (flare). Scale driver 1.0 → `<goldenCatchPopScale>` 1.5 'Quad.Out' as integer render scale: **×5 at f0 (forced) → ×6 from 75 ms**. Opacity 1 → 0 'Linear'. Burst `<goldenBurstCount>` 16 chips (TA fx-data) at the Golden centre. Camera shake `<goldenCatchShakePx>` 4 / `<goldenCatchShakeMs>` 150 ms, integer linear decay **4, 4, 3, 3, 2, 2, 1, 1, 0** (f0-f8). The buff banner starts (motion-spec `buff-banner`). | `<goldenCatchPopMs>` 150 |
| **Despawn** (`despawning`) | Opacity from its current value → 0, 'Quad.In'. Bob and drift continue (it fades where it floats). Taps pass through. | `<goldenDespawnFadeMs>` 200 |

The ×6 catch pop is 96 px (0.40× the Big Banana) for at most 75 ms while fading out, so it cannot be mistaken for the Big Banana.

Reduced motion (UX §4, a static target): spawn fades at ×4 with no scale steps; **no drift, no bob, no tilt** (frame 0; the in-place flare swap every 2500 ms is kept, since it does not move the target); the despawn-warning blink is **2 Hz** (250 ms on / 250 ms off, 1 ↔ 0.35); the catch fades over 150 ms at ×4; chips × `<reducedMotionChipFactor>`; shake 0.

---

## 3. Critters (T4). 16×16 art, drawn ×4, pivot bottom-centre, 2-frame idle

| Type | Idle frame duration | Wanders? | Frenzy idle |
|---|---|---|---|
| intern, hardhat, bureaucrat, timechimp (monkeys) | 500 ms (2 fps) | yes | 250 ms |
| tree | 667 ms (1.5 fps) | no | 333 ms |
| catapult, moon | 1000 ms (1 fps) | no | 500 ms |
| rocket (exhaust flicker) | 250 ms (4 fps) | no | 125 ms |

- **Desync (per instance):** play with `startFrame` = random 0 or 1, `delay` = U(0, frameMs), and `anims.timeScale` = U(0.9, 1.1). On every `animationrepeat`, re-roll timeScale from U(0.85, 1.15). This way no two critters stay in phase, and a 1-hour session never settles into a visible unison beat. Frenzy multiplies each instance's timeScale by 2 on start and divides by 2 on end.
- **Wander (monkeys only):** every U(4000, 9000) ms per critter (Frenzy: U(2000, 4500)). Globally at most one hop starts per 250 ms. A hop is dx ∈ {−8, −4, +4, +8} (1-2 art-px). The y arc is **0, −4, −8, −8, −4, 0** over 200 ms ('Quad.Out' up, 'Quad.In' down). x moves 'Linear' over the same 200 ms, snapped. `flipX` faces the hop direction. Clamp to the critter's diorama zone inset by 8 art-px: if the landing point is outside it, invert dx; if it is still outside, hop in place.
- **Tap Frenzy:** monkeys set `flipX` to face the Big Banana (a cut); the zoo stares at the banana.
- **Spawn plop (on buy):** the new sprite appears 32 px (8 art-px) above its slot and falls 'Quad.In' over 120 ms, snapped (−32, −28, −20, −8, 0). On landing, frame 1 holds 100 ms (the compressed pose; intern frame 1 is one row shorter), plus 2 dust puffs at the feet (TA fx-data). Then the idle starts at a random phase. Throttle: at most 1 plop per 100 ms (matches `<holdRepeatIntervalMs>`), and a ×10/MAX buy staggers its plops 60 ms apart up to the diorama's visible cap. **At cap:** no new sprite; a random critter of that type does a cheer hop in place (0, −4, 0 over 120 ms).
- **Budget:** the motion is sized for **≤ 24 animated critters** (UX and the 2D Artist own the diorama capacity). Worst case is about 50 frame swaps/s in Frenzy, which is negligible.
- **Evolve:** poof (motion-spec `evolve-ceremony`).
- Reduced motion (UX §4): **idles frozen on frame 0**, no wander, no cheer hop, no Tap Frenzy facing flip. Arrival (plop) = opacity 0 → 1 over 150 ms in place; Evolve exit = opacity 1 → 0 over 150 ms. The Frenzy rate-up does not apply (the idles are frozen).

## 4. Environment (T4)
- **env_cloud:** drifts +1 art-px (4 px) every 750 ms (about 5.3 px/s), wraps off-screen, 2-3 clouds, each with a random phase. No other environment motion: the palm and foliage stay static, so the diorama's ambient budget goes to the critters.

## 5. Frenzy: what visibly changes

| | Banana Frenzy (bps ×5, 15 s) | Tap Frenzy (tap ×10, 12 s) |
|---|---|---|
| Screen | Gold edge band pulses at `<frenzyEdgePulseHz>` 2 Hz (opacity 0.2 ↔ 0.6) | none |
| Big Banana | Bob half-period 1600 → 800 ms | Halo pulses at `<tapFrenzyGlowPulseHz>` (3 Hz if OBJ-2 lands) |
| Critters | Idle ×2, hop interval halved | Monkeys face the banana |
| HUD | bps readout gold + depleting timer bar | Floaters in the crit colour + timer bar |
| Last 3 s | Timer bar blinks at 2 Hz | same |

**No sky tint pulse.** The edge band already owns the full-screen signal; a second full-screen pulse would double the peripheral motion for 15 s and compete with the Golden's blink, which is also a T2 signal.

## 6. Art status (round 2): all requested frames delivered

`bigBanana` has 5 frames on a 48×49 canvas (§1.1), `bigBanana_halo` is 44×56, and `goldenBanana` has 4 frames (§2); all come from `art/sprites.ts`. The boot-resample fallback is no longer needed. Dev-mode check: warn if `heightRatio[2]` or `heightRatio[3]` differs from `<squashScaleY>` / `<squashMinScaleY>` by more than 0.03 after a retune, so the art cannot silently drift from the tunables.
