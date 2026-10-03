# event-markers (hit-frame-data) — Monkey Bananas

Owner: Animator. Consumers: Audio Director (cue alignment), Game Developer (event wiring).
Shape: gamestudio `combat-telegraphs-and-reactions/tools/hit-frame-marker-schema.md`, adapted. There are no attacks here; each sequence lists `frame` / `ms` from its trigger (f0), the motion beat on that frame, the cue, and the dev action.
Cue ids and buses are the Audio Director's (`audio/cues.json`). `null` means no cue by design.

**Conventions**
- f0 is the frame the trigger is processed on: pointer-down for the tap and the Golden catch, pointer-up inside bounds for buy/commit, a state edge for everything else. fN = N × 16.67 ms at 60 fps. Timelines are time-based, so at 120 Hz the ms values hold and the frame numbers double.
- **Start SFX as soon as possible** (`start(0)` / `currentTime`). Never quantize an SFX to the music grid. Web Audio output latency (`baseLatency + outputLatency`, typically 10-40 ms) lands the sound 1-3 frames after the visual f0. The feel-spec's touch note already accepts this. Only music-layer entrances wait for the beat (the AD's rule).
- The visual contact frame is always f0. The AD's attacks (1-3 ms) sit on it.

---

## 1. Big Banana

```yaml
sequence: tap                 # registered tap only; dropped (over-cap) taps have no marker at all
events:
  - { frame: 0,  ms: 0,   kind: contact,   cue_id: tap, bus: sfx, motion: "body → pressed, frame 1 (squash 0.94)", dev: "award, bank snap + bank pop, floater spawn, 3 chips at pointer" }
  - { frame: 1,  ms: 17,  kind: pose,      cue_id: null, motion: "frame 2 (squash 0.88), held f1-f2" }
  - { frame: 6,  ms: 100, kind: pose,      cue_id: null, motion: "frame 4 (stretch), f6-f8" }
  - { frame: 11, ms: 180, kind: settle,    cue_id: null, motion: "squashComplete → idle", dev: "bob resume timer (600 ms) starts" }
restart: "a tap on any frame restarts at its own f0 (the cue fires again; the AD's tap polyphony is 3 with oldest-steal)"
```

```yaml
sequence: tapCrit
events:
  - { frame: 0, ms: 0,  kind: contact, cue_id: tapCrit, bus: sfx, note: "REPLACES tap for this pointer-down (cues.json)", motion: "body → crit, frame 1; flash (fill-tint) f0-f1; camera shake +3 -3 +2 -2 +1 -1 0 over f0-f6; crit floater at ×8", dev: "award ×critMult, 10 chips" }
  - { frame: 1, ms: 17, kind: pose,    cue_id: null, motion: "frame 3 (deep squash 0.84), f1-f2" }
  - { frame: 1, ms: 17, kind: pose,    cue_id: null, motion: "crit floater ×7 (f1-f3), ×6 from f4" }
  - { frame: 6, ms: 100, kind: settle, cue_id: null, motion: "shake ends at 0" }
```

## 2. Shop

```yaml
sequence: buy                  # f0 = commit (pointer-up inside bounds, moved ≤ buyDragCancelPx)
events:
  - { frame: 0, ms: 0,   kind: commit, cue_id: "buy | buyBulk", bus: sfx, motion: "row flash 0.6 → 0 (f0-f5); owned count ×5 (f0-f2) then ×4; icon hop 0,-4,-8,-8,-4,0 (f0-f6)", dev: "deduct, autosave" }
  - { frame: 0, ms: 0,   kind: spawn,  cue_id: null, motion: "critter plop starts 32 px above its slot (if the diorama is below cap)" }
  - { frame: 7, ms: 120, kind: land,   cue_id: null, motion: "critter lands: frame 1 for 100 ms + 2 dust puffs", note: "NO plop cue by design: at 10 buys/s it would double the buy density. The AD may add a quiet one for the first unit of a type only." }
hold_to_repeat: "the first repeat is at +400 ms (holdRepeatDelayMs), then every 100 ms. Each tick is its own f0 with buy + flash + pop + hop; the press visual stays held"
```

```yaml
sequence: cantAfford
events:
  - { frame: 0,  ms: 0,   kind: reject, cue_id: cantAfford, bus: sfx, motion: "shake +4,+4,-4,-4,+4,+4,-4,-4,+4,-4,-4 (f0-f10)" }
  - { frame: 11, ms: 180, kind: settle, cue_id: null, motion: "x back to 0" }
```

```yaml
sequence: upgradeBuy
events:
  - { frame: 0,  ms: 0,   kind: commit, cue_id: upgradeBuy, bus: sfx, motion: "icon ×5 → ×4 (f5) → ×3 (f7) → ×2 (f9) → ×1 (f11) → hidden (f12)" }
  - { frame: 12, ms: 200, kind: reflow, cue_id: null, motion: "shelf reflow 150 ms Cubic.Out" }
```

```yaml
sequence: stateEdges
events:
  - { trigger: becameAffordable, frame: 0, cue_id: affordGlint, bus: sfx, motion: "glint band sweep 250 ms (per-row 5 s cooldown; AD adds a global 2.5 s)" }
  - { trigger: producerReveal,   frame: 0, cue_id: producerReveal, bus: sfx, motion: "silhouette → real (cut + 2-frame tint), icon hop; next silhouette slides in at +120 ms" }
  - { trigger: buyModeCycle,     frame: 0, cue_id: uiToggleOn, bus: ui, note: "semis by mode per cues.json", motion: "button press cut; cost labels relabel on the same frame" }
```

## 3. Golden Banana

```yaml
sequence: goldenSpawn
events:
  - { frame: 0,  ms: 0,   kind: spawn,  cue_id: goldenSpawn, bus: sfx, motion: "render ×2, opacity ~0; hit radius live", note: "the cue leads the visual by ~2 frames; that helps the eye find it" }
  - { frame: 1,  ms: 17,  kind: pose,   cue_id: null, motion: "×3" }
  - { frame: 8,  ms: 132, kind: pose,   cue_id: null, motion: "×4 (final size)" }
  - { frame: 18, ms: 300, kind: settle, cue_id: null, motion: "spawnComplete → idle: bob, tilt, drift start" }
```

```yaml
sequence: goldenWarning       # f0 = remaining lifetime ≤ goldenBlinkLastMs (2000)
events:
  - { frame: 0, ms: 0, kind: telegraph, cue_id: null, motion: "blink 1 ↔ 0.35 at 6 Hz; flare suppressed", note: "visual-only by design (sonic brief: a miss costs nothing, so no alarm)" }
```

```yaml
sequence: goldenCatch         # f0 = pointer-down within goldenHitRadiusPx
events:
  - { frame: 0,   ms: 0,    kind: contact, cue_id: "goldenCatchBunch | goldenCatchFrenzy | goldenCatchTapFrenzy", bus: sfx, motion: "frame 1 (flare) at ×5, opacity 1; 16-chip burst; camera shake 4,4,3,3,2,2,1,1,0 (f0-f8); banner enter starts", dev: "roll outcome BEFORE f0 renders (the cue depends on it); award / buff start; Lucky Bunch starts the bank roll (500 ms)" }
  - { frame: 5,   ms: 75,   kind: pose,    cue_id: null, motion: "×6" }
  - { frame: 9,   ms: 150,  kind: settle,  cue_id: null, motion: "popComplete → gone (opacity 0), returned to the pool" }
  - { frame: 12,  ms: 200,  kind: pose,    cue_id: null, motion: "banner fully in" }
  - { frame: 30,  ms: 500,  kind: settle,  cue_id: null, motion: "Lucky Bunch bank roll ends (gold text → normal)" }
  - { frame: 108, ms: 1800, kind: exit,    cue_id: null, motion: "banner exit starts" }
  - { frame: 120, ms: 2000, kind: settle,  cue_id: null, motion: "banner gone" }
music: "frenzyStart / tapFrenzyStart: cue null; the music frenzy layer enters on the next beat (AD)"
```

```yaml
sequence: goldenDespawn       # f0 = lifetime expired (missed)
events:
  - { frame: 0,  ms: 0,   kind: exit,   cue_id: goldenDespawn, bus: sfx, motion: "opacity current → 0 (Quad.In); taps pass through" }
  - { frame: 12, ms: 200, kind: settle, cue_id: null, motion: "fadeComplete → gone" }
```

```yaml
sequence: buffEnd             # f0 = frenzy or tapFrenzy timer reaches 0
events:
  - { frame: -180, ms: -3000, kind: telegraph, cue_id: null, motion: "timer bar blinks at 2 Hz" }
  - { frame: 0,    ms: 0,     kind: exit,      cue_id: buffEnd, bus: sfx, motion: "edge glow / halo opacity → 0 over 300 ms; bps readout un-golds (cut); critter rate back to ×1" }
```

## 4. Meta

```yaml
sequence: milestoneHeadline
events:
  - { frame: 0, ms: 0, kind: flash, cue_id: milestoneHeadline, bus: sfx, motion: "ticker flash 0.8 → 0 over 120 ms; milestone text enters" }
```

```yaml
sequence: evolveButton
events:
  - { trigger: "allTimeBananas crosses 250,000 (once ever)", frame: 0,  cue_id: producerReveal, bus: sfx, note: "proposed reuse; the AD may set null", motion: "pop 0.6 → 1.0 (Back.Out, 170 ms)" }
  - { trigger: "(same)",                                     frame: 18, ms: 300, cue_id: null, motion: "glint sweep 250 ms" }
  - { trigger: "evolveEnabled false → true",                 frame: 0,  cue_id: evolveReady, bus: sfx, motion: "unlock beat: frame cut + 2-frame tint + hop 0,-4,-8,-4,0 (160 ms); ready pulse every 3000 ms after" }
  - { trigger: "Evolve button commit",                       frame: 0,  cue_id: evolveOpen, bus: sfx, motion: "modal-enter 240 ms", note: "AD: starts the music duck" }
  - { trigger: "Evolution screen dismissed without evolving", frame: 0, cue_id: panelClose, bus: ui, motion: "modal-exit 160 ms", note: "AD event evolveClose" }
```

```yaml
sequence: evolveCeremony      # f0 = Confirm commit; save done, input locked. Beats sit on the evolveConfirm fanfare's layer onsets.
events:
  - { frame: 0,  ms: 0,    kind: commit,  cue_id: evolveConfirm, bus: sfx, audio_onset: "p1 (C5)",           motion: "overlay 0.25; Evolve modal exits; Big Banana crit-depth squash; critter poofs begin (staggered 0-180 ms)", dev: "body → locked; music fadeOutStop 400 (AD)" }
  - { frame: 5,  ms: 90,   kind: step,    cue_id: null,          audio_onset: "p2 (C5)",           motion: "overlay 0.50" }
  - { frame: 11, ms: 180,  kind: step,    cue_id: null,          audio_onset: "p3 (C5)",           motion: "overlay 0.75" }
  - { frame: 16, ms: 270,  kind: peak,    cue_id: null,          audio_onset: "leadA + bass1",     motion: "overlay 1.00 (full white)", dev: "RESET SEAM 270-400 ms: reset the run, clear the diorama, despawn the Golden with no FX, aura → plain" }
  - { frame: 22, ms: 360,  kind: settle,  cue_id: null,          motion: "last poof ends (hidden under white)" }
  - { frame: 24, ms: 400,  kind: card,    cue_id: null,          motion: "'EVOLUTION N' + species title appear; title drops -32 → 0 (Quad.In, 170 ms)" }
  - { frame: 34, ms: 570,  kind: impact,  cue_id: null,          audio_onset: "leadF (F5)",        motion: "TITLE LANDS; 4 px bounce over 120 ms" }
  - { frame: 43, ms: 720,  kind: impact,  cue_id: null,          audio_onset: "leadC + kick + crash", motion: "NEW MULTIPLIER pops ×6 → ×5 → ×4 (gold); old value, arrow and +Thumbs cut in" }
  - { frame: 72, ms: 1200, kind: exit,    cue_id: null,          motion: "overlay 0.67, fade-in starts (0.33 at 1300, 0 at 1400)" }
  - { frame: 78, ms: 1300, kind: pose,    cue_id: null,          motion: "Big Banana 'hello' stretch frame, 50 ms" }
  - { frame: 90, ms: 1500, kind: unlock,  cue_id: null, event: evolveTransitionEnd, motion: "input unlocked; body → idle", dev: "AD: music restarts at bar 1 (new key), 300 ms fade-in" }
  - { frame: 108, ms: 1800, kind: flash,  cue_id: milestoneHeadline, bus: sfx, motion: "h_evolve_* headline (deferred ≥ 300 ms after unlock)" }
```

Reduced motion (ux/settings-and-a11y.md §4): the dark 1200 ms crossfade variant keeps `evolveConfirm` at t=0 and the multiplier cut-in at 720 ms (still on leadC + crash). The title cuts in at 200 ms, the reset seam is 200-400 ms, and input unlock + `evolveTransitionEnd` are at **1200 ms** instead of 1500. See `motion-spec.yaml` `evolve-ceremony`.

```yaml
sequence: offline             # f0 = offline modal opens (load, or tab return after > 60 s)
events:
  - { frame: 0,  ms: 0,    kind: open,   cue_id: panelOpen, bus: ui, motion: "modal-enter 240 ms" }
  - { frame: 14, ms: 240,  kind: roll,   cue_id: null, motion: "count-up 0 → award, 800 ms Cubic.Out" }
  - { frame: 62, ms: 1040, kind: settle, cue_id: offlineCollect, bus: sfx, motion: "roll ends; number ×5 for 60 ms", note: "if Collect is tapped mid-roll: snap to the award + offlineCollect at that tap instead; never twice" }
```

```yaml
sequence: ui                  # generic buttons and panels
events:
  - { trigger: "button commit (pointer-up inside)", frame: 0, cue_id: uiClick,    bus: ui, motion: "pressed frame was shown from pointer-down; release cut after max(up, 60 ms)" }
  - { trigger: "shop drawer open / close",          frame: 0, cue_id: "panelOpen | panelClose", bus: ui, motion: "240 ms Cubic.Out / 180 ms Quad.In" }
  - { trigger: "settings or other modal close",     frame: 0, cue_id: panelClose, bus: ui, motion: "modal-exit 160 ms" }
  - { trigger: "tab switch",                        frame: 0, cue_id: uiClick,    bus: ui, motion: "tab frame cut; list out 60 / in 140 (J7 overshoot)" }
```

## 5. v1.1 UI juice (`ui-juice.yaml`)

The juice layer asks for **no new cues**. Every juice beat either rides a frame that already has a cue (listed so the AD can check alignment) or is silent by design. In the rows below, `cue_id` is only an existing id from `audio/cues.json`, or `null`.

```yaml
sequence: juice
events:
  - { id: J1, trigger: "press (pointerdown)",            frame: 0, cue_id: null,        motion: "pill squish w+8 / h-8 (standalone) or h-8 centred (cost pill)", note: "the commit cue (uiClick / buy / cantAfford) stays on pointer-up, unchanged" }
  - { id: J1, trigger: "release R",                      frame: 0, cue_id: null,        motion: "rubbery rebound R+f0-f3, rest at R+f4 (67 ms)" }
  - { id: J2, trigger: "Lucky Bunch award",              frame: 0, cue_id: goldenCatchBunch, bus: sfx, motion: "bank ×5 pop f0-f2, squash f3-f4, stretch f5-f6", note: "already fired by goldenCatch; do not re-fire" }
  - { id: J2, trigger: "Offline Collect HUD snap",       frame: 0, cue_id: offlineCollect,   bus: sfx, motion: "same bank pop", note: "already fired by the offline sequence; never twice" }
  - { id: J2, trigger: "bps value increases",            frame: 0, cue_id: null,        motion: "bps hop f0-f5 (100 ms) + juiceGain tint", note: "the cause (buy / upgradeBuy) already sounds" }
  - { id: J3, trigger: "fresh or bulk buy commit",       frame: 0, cue_id: "buy | buyBulk", bus: sfx, motion: "bought-row hop unchanged; neighbours ±1 at f3 (50 ms), ±2 at f6 (100 ms)", note: "no per-neighbour blips: 4 extra onsets inside 170 ms would smear the buy transient" }
  - { id: J3, trigger: "upgrade shelf lands",            frame: 21, ms: 350, cue_id: null, motion: "reflow land bump -4 (2 frames) + icon ripple, 40 ms stagger" }
  - { id: J4a, trigger: "NEED → BUY edge",               frame: 0, cue_id: affordGlint, bus: sfx, motion: "pill hello 167 ms", note: "the same cue afford-glint already fires; one onset, not two" }
  - { id: J4b, trigger: "idle nudge tick (≤ 1 per 4 s)", frame: 0, cue_id: null,        motion: "pill hello 167 ms", note: "ambient motion is silent" }
  - { id: J5, trigger: "UPGRADES badge count up / appear", frame: 0, cue_id: null,      motion: "badge pop 100 / 117 ms", note: "a badge cue would double the affordGlint that usually causes it" }
  - { id: J5, trigger: "Evolve !-badge appear",          frame: 0, cue_id: evolveReady, bus: sfx, motion: "badge appear pop, on the evolve-button-ready unlock beat", note: "already fired by the unlock beat" }
  - { id: J6, trigger: "modal open",                     frame: 0, cue_id: "evolveOpen | panelOpen", motion: "panel starts its fall from -64", note: "unchanged onset" }
  - { id: J6, trigger: "modal LANDS",                    frame: 6, ms: 100, cue_id: null, motion: "squash w+16 / h-8 (f6-f7)", note: "marker for the AD: panelOpen's body or thump can be shaped to peak at +100 ms if wanted. No new cue" }
  - { id: J6, trigger: "buff banner LANDS",              frame: 4, ms: 67, cue_id: null, motion: "squash w+16 / h-8 (f4-f5)", note: "sits under the goldenCatch* cue tail; no new cue" }
  - { id: J7, trigger: "tab switch",                     frame: 0, cue_id: uiClick, bus: ui, motion: "list overshoot peak at in-phase f5-f7 (143-177 ms after commit)", note: "unchanged onset" }
  - { id: J8, trigger: "milestone glyph enters the ticker", frame: 0, cue_id: null,    motion: "glyph hop f0-f4 (83 ms), about one every 200 ms", note: "milestoneHeadline at the headline f0 is the only cue; per-letter blips would fight the music" }
```

Reduced motion: J1, J3, J4, J5 and J8 motion is off, J2 is an instant colour change only, and J6/J7 fall back to their v1.0 fades. No cue changes under reduced motion.
