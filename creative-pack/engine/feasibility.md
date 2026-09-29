# "עוד סבב": engine feasibility review

**Owner:** Game Developer · **Pack:** `artifacts/creative-pack/od-sevev` · **Date:** 2026-09-28 · **Stage:** pitch (a review, not an implementation plan)

**Runtime reviewed against:** the Monkey Bananas fork at `~/monkey-bananas`, branch `godot-v2`, commit `e33422d` (tag `v2.1.0` plus 2 commits). It is a Godot 4.7.2 web export. I only read it; nothing in it was changed.

**Specs reviewed:**
- `audio/sonic-brief.md` v1.0
- `ux/first-minute.md`
- The Hebrew pixel font. `art/style-guide.md` is not written yet, so I reviewed the font plan in `art/src/hebfont.py` and `art/proofs/font-specimen.png`.

## 0. Three facts about the fork that reframe the specs

1. **Audio is rendered offline, not synthesised live.**
   - Sources: ADR 0002 and ADR 0003 in the fork. `tools/lib_dsp.gd` renders every cue to WAV and the music to QOA stems (`.res`). `game/scripts/autoload/audio.gd` only *plays* those files. It never changes pitch through `pitch_scale`, so every pitch is its own file.
   - **What this means for the brief:**
     - The number of synth voices costs nothing, because it is only a question of how many channels the render mixes.
     - Anything that must change *continuously at runtime* has to be either a Godot bus effect or a pre-rendered file.
     - Every new tempo, key or arrangement is a new set of stems. Measured on the fork, one stem layer costs about **12.2 KB per second** (15.57 MB of music across 21 stems of 60.95 s each).
   - The brief says it could not find `music.json` or `cues.json`. They exist in the fork as `audio/music.json` and `audio/cues.json` (the v1 schema), with `game/assets/audio/cues_v2.json` merged on top.
2. **There is no DOM.**
   - Every UI element is drawn into one canvas. Browser APIs are reached through `JavaScriptBridge` and `game/web/shell.html`.
   - All on-screen text today goes through `PxText` (`game/scripts/ui/px_text.gd`). It draws a monospace bitmap font left to right in logical order, so it has **no bidi**.
   - Hebrew therefore needs Godot's TextServer, through a `Label` or `RichTextLabel` with a bitmap `FontFile`. TextServerAdvanced provides ICU bidi, including isolates.
3. **The web payload is already large.** Measured on `build/web/`:

   | File | Raw | Brotli | Gzip | Notes |
   |---|---|---|---|---|
   | `index.wasm` | 39.5 MB | 6.9 MB | 10.1 MB | |
   | `index.pck` | 19.3 MB | — | — | Almost all QOA audio, which does not compress further |

## 1. Verdicts

**Key:**
- ✅ fine
- ✅* fine with a note
- ⛔ objection (see §2)

### 1.1 Audio (`audio/sonic-brief.md`)

| # | Claim | Verdict | Note or evidence |
|---|---|---|---|
| A1 | Seven voices: P1, P2 (25/12.5/50% duty), TRI, NOI-L, NOI-S, OUT (tri+noise, low-passed), BLIP | ✅* | **All seven can be rendered.**<br>• `lib_dsp.gd` has a pulse at any duty, a triangle, the 15-bit LFSR in long mode (NOI-L) and metal mode (NOI-S), Web Audio-formula biquads, sweeps, delayed vibrato and echo.<br>• Voices are render channels, so seven costs the same as three.<br>• What costs frames on web is the number of *streams playing at once*. Budget for this game: about 14 (4 layers, 1 ambience bed, 4 taps, about 5 other cues), which is inside what the fork already plays. |
| A2 | Band-limited oscillators (PeriodicWave, ≤ 32 harmonics); pulse leads stop at A6 | ✅ | `lib_dsp` already uses band-limited wavetables with one partial table per octave, chosen per 32-sample block. That is stricter than a single PeriodicWave. |
| A3 | Each tap's pitch walks up the era's hijaz scale from degree 5 (8 steps, wrapping; resets after 400 ms idle); duty alternates 25/12.5% | ✅* | **Files:** one WAV per pitch, so 8 steps × 4 era keys × 2 duty variants = 64 small files.<br>**Code change:** the fork's `_scale_pick` chooses randomly inside a window and avoids repeats. It needs a strict "walk and wrap" mode. The 400 ms reset is the existing `streak.gapMs`. |
| A4 | Four eras: D / E / G / F hijaz or Mixolydian at 116 / 132 / 88 / 144 BPM | ✅* | **Sample rates:** each era renders at its own rate so that a 16th note is a whole number of samples. That is the fork's own trick (it uses 31.5 kHz at 126 BPM). The rates are 31,900 / 32,032 / 31,944 / 31,968 Hz.<br>**Size:** 4 eras × 3 layers × 32 bars comes to about **9.7 MB**. |
| A5 | Layers L0–L2 fade over 1 bar at bar lines; L2 plays while the last tap was under 3 s ago | ✅* | The fork does this already (base, evolved and frenzy layers). Fades are stepped once per frame, so they can start up to 16 ms late (ADR 0002). |
| A6 | Anti-fatigue: an alternate B-section every 2nd loop | ⛔ **O-A1** | It doubles every stem. |
| A7 | Anti-fatigue: a "breather" (L0 only) every 4th loop | ✅ | This is a runtime layer mute with a loop counter. It costs no bytes. |
| A8 | Court day: the current era at 0.75× tempo from the next bar line, with L2 muted | ⛔ **O-A2** | — |
| A9 | OUT sub-bus: LPF at 800 Hz, pan −0.3, rising up to +6 dB; Pink Front sweeps the LPF to 4 kHz and tap-to-beat judges against OUT | ✅* | **Implementation:** an "Outside" bus with `AudioEffectLowPassFilter` and `AudioEffectPanner`, with the cutoff scripted every frame.<br>**Constraint:** bus effects only work because the fork uses *Stream* playback on web (`default_playback_type.web=0`). **Keep it that way:** Sample mode is lower latency but drops bus effects.<br>**Size:** the 2-bar OUT loop is under 0.1 MB.<br>**Precision:** beat judging reads the song clock at frame precision (±16 ms), which is fine for a tap-to-beat window. |
| A10 | Courthouse slapback (180 ms, −12 dB) | ✅ | It is baked into the Courthouse stems offline (`lib_dsp` has echo). If SFX should also get it, enable an `AudioEffectDelay` on the SFX bus for that era only. |
| A11 | Suitcase zipper panned to the suitcase's x (±0.4) | ✅* | The rendered files are mono. Pan them with a Panner on a dedicated bus, set at spawn. Only one Suitcase is ever on screen, so a single bus is enough. |
| A12 | Fanfare in the incoming era's key; each round adds a half-bar tag, capped at +4 | ✅* | **Pre-render** 5 lengths × 4 keys (20 stingers, about 1 MB).<br>**Don't** append the tag at runtime: joins are frame-timed and can land 16 ms late, which is audible on a cadence. The fork's era flourish, which holds the music restart until it ends, already does "the next loop's downbeat is the resolution". |
| A13 | Dubi babble: one blip per ~2 letters, pitched on era-mode degrees in octaves 5–6; canned lines have fixed contours | ✅* | **New blip bank:** 5 degrees × 2 octaves × 4 keys = 40 blips, about 0.2 MB. It replaces the fork's F-pentatonic bank, which ignores the key (a gap ADR 0003 already lists).<br>**Canned contours:** a lookup inside `Audio.babble_plan`, which is a pure function. |
| A14 | Latency of 1 frame or less from the trigger | ✅* | **What holds:** the play call is issued on the trigger frame.<br>**What is added on top:** the audible delay includes Godot's web output buffer (`audio/driver/output_latency.web`, about 50 ms by default) plus the browser's `outputLatency`.<br>**Consequence:** tap feel has to come from the squash that lands on the same frame, as the fork's feel-spec already accepts. Read "≤ 1 frame" as *scheduling*, not as what the ear hears. |
| A15 | Nothing plays before the first tap; the first sound is the motif on P1 | ✅* | The fork already holds cues until audio is unlocked (`audioUnlock`, with one held cue flushed if it is at most 180 ms old).<br>**iOS:** audio unlocks on *touchend*, so the motif lands on release.<br>**Seam with UX:** UX makes the disclaimer button the unlocking tap. If the disclaimer moves to the DOM (O-U1), the engine may not exist yet at that tap. The first sound then comes on the first Magician tap, which is exactly what the brief's §4 asks. |
| A16 | `navigator.audioSession.type = 'ambient'` (respects the silent switch) | ✅ | Already in `game/web/shell.html:174`. |
| A17 | Suspend audio while the page is hidden | ✅ | The fork calls `set_paused` on `APPLICATION_PAUSED` and `FOCUS_OUT`, and the shell resumes every context when the page becomes visible again. |
| A18 | Buses, ducks, and a master DynamicsCompressor (knee 0, ratio 20) holding ≤ −1 dBTP; −16 LUFS | ✅* | These are specified in Web Audio terms.<br>**Godot mapping:** Godot's compressor has no knee. The fork's chain (a compressor, then an `AudioEffectHardLimiter` at −1 dB) meets the ≤ −1 dBTP ceiling. Ducks are scripted in `audio.gd`.<br>**Loudness:** LUFS is measured on the offline renders. |

### 1.2 UX (`ux/first-minute.md`)

| # | Claim | Verdict | Note or evidence |
|---|---|---|---|
| U1 | N0 loader in ≤ 3 s on 4G | ⛔ **O-U1** | — |
| U2 | Every overlay or tall tab pushes a history entry; Android back, browser back and the iOS edge swipe pop one layer | ✅* | **Needs a JS bridge:** `pushState`, plus a `popstate` listener created with `JavaScriptBridge.create_callback`. The fork's `NOTIFICATION_WM_GO_BACK_REQUEST` handler (`main.gd:769`) fires only on native Android, never on web.<br>**Two rules:**<br>• When a layer is closed by a button, call `history.back()` and ignore the `popstate` that comes back.<br>• Chromium's back button skips history entries that were added before the user had interacted with the page. So O1, O11 or O12 opening on its own at a cold launch would make back *leave the page*. Push those entries on the first `pointerdown` instead. |
| U3 | A clock that can't be rewound: `max(device clock, HTTP Date of the page load, build timestamp)` | ✅* | **The problem:** JavaScript cannot read the `Date` header of the page's own document.<br>**Fix:**<br>• Read the date from a same-origin `fetch(location.href, {method:'HEAD', cache:'no-store'})`.<br>• Take the max of that, the device clock, a build timestamp baked in at export, and a saved high-water mark. When the device is online, clamp the high-water mark to the server time.<br>**Backstop:** the publisher deploys a build with the blackout flag set on 22.10. The fork has no service worker, so a reload picks it up. |
| U4 | Bars fill from the right | ✅ | The bars are drawn rects anchored to the right. |
| U5 | The ticker crawls left → right | ✅* | This is a sign flip at `ticker.gd:202`. The Hebrew line itself has to use the Label route (U6). |
| U6 | Numbers stay LTR inside Hebrew (LRI…PDI) | ✅* | **Works:** TextServerAdvanced (ICU bidi, which supports isolates) in a `Label` or `RichTextLabel`, with a bitmap `FontFile` built at boot from the same pixel-font data.<br>**Doesn't work:** `PxText` has no bidi, so it may draw only strings that are *purely numeric*.<br>**Leave `include_text_server_data` off:** it adds about 4 MB, and it is needed only for dictionary line breaking (Thai, CJK), not for Hebrew. |
| U7 | A 390×844 portrait layout with safe areas | ✅* | **Canvas:** the fork's canvas is 720 logical px wide with aspect `expand`, so 390×844 becomes 720×1558 logical.<br>**Conversion:** 1 CSS px = 1.846 logical px. The `hud-layout` numbers have to be restated on the fork's 4-px logical grid.<br>**Safe areas:** they come from `window.mbSafeArea`.<br>**Desktop:** the "centred 390-wide phone frame" needs `shell.html` to cap the canvas width, because the fork currently fills the window. |
| U8 | Touch targets ≥ 44 pt | ✅ | 44 CSS px is 81 logical px. The fork's rows are already 96 logical px (about 52 pt). |
| U9 | Receipt and result cards rendered in-engine; shared through `navigator.share` with a download fallback | ✅* | **Render when the sheet opens,** not when the player taps Share. The sheet shows the preview anyway. Steps:<br>• `SubViewport` with `UPDATE_ONCE`;<br>• `get_image()`;<br>• `save_png_to_buffer()`, which takes 100–300 ms on a phone;<br>• pass it to JS as base64 and keep a `File` object ready.<br>**Why:** the Share tap reaches GDScript on the next frame, which is still inside the browser's user-activation window. Encoding *on* the tap could miss Safari's window.<br>**Fallback:** if `canShare({files})` is false, use `JavaScriptBridge.download_buffer`.<br>**iOS:** WhatsApp drops the share text when a file is attached. The fiction label therefore has to be on the image itself, and §5 already puts it there. |
| U10 | 20 ms vibration where supported; the toggle is hidden on iOS | ✅* | **Current bug:** the fork's `_haptic` checks `OS.has_feature("mobile")`, which is false on web. So today it never vibrates in the browser. Check the `web_android` feature, or `'vibrate' in navigator`, instead.<br>**Chrome:** it blocks `vibrate()` until the first tap. The C1 ping comes about 40 s later, so this is fine. |
| U11 | Rendering and accessibility assume a DOM ("DOM overlay", `ctx.direction`, and "disclaimer, About, settings and share sheets are DOM and screen-reader readable") | ⛔ **O-U2** | — |
| U12 | Labels overflow by auto-shrinking to 85%, then ellipsis | ⛔ **O-U3** | — |
| U13 | Large text is ×1.25 | ✅* | The pixel font scales only in whole steps, so this is scale 3 → 4, which is ×1.33. The cell grows from 14.6 to 19.5 CSS px, which meets the ≥ 17.5 px ask. |
| U14 | Autosave on `visibilitychange` and `pagehide`; timers pause while hidden | ✅* | The fork flushes on `FOCUS_OUT` and `PAUSED`. `user://` on web is IndexedDB, which syncs asynchronously, so a save at `pagehide` can be lost. Also save on every purchase and payment, as the fork already does on its own events. |

### 1.3 Font (`art/src/hebfont.py`; the style guide is pending)

| # | Claim | Verdict | Note or evidence |
|---|---|---|---|
| F1 | A 5×9 cell (2 rows ascender, 5 body, 2 descender), baseline at row 6, line height 11 | ✅* | **Same data format:** the glyphs use the same `#`-row format as `game/data/art.json`, and the same baseline row 6 as the fork's 5×7 Latin. Latin capitals fill rows 0–6, which is the same band as Hebrew ascenders.<br>**Change needed:** set `glyphH` to 9 (from 7) and `lineHeight` to 11 (from 9) in the metrics. The baker in `art.gd` already reads the width of each glyph row. |
| F2 | Advance is glyph width + 1: 6 for most letters, narrower for ו ז י ן נ and some punctuation; a space is 3 | ✅* | **Blocked today:** `PxText._draw` and `Art.measure` use one global advance (`6·s·n − s`).<br>**Fix:** use a per-glyph advance, which is `set_glyph_advance` on the `FontFile` route (U6). The UX character budgets become conservative, which is safe. |
| F3 | `visual_order()` in `hebfont.py` | ✅* | Use it for proofs only; **do not port it to the runtime.** It has no isolates, and it reorders before wrapping, so any line that wraps comes out wrong. At runtime, use TextServer. |
| F4 | Glyph coverage against the UX list in §3.5 | ✅* | **Missing from the draft:**<br>• `K M B T` (compact numbers);<br>• `+` and `−` (U+2212);<br>• `…`;<br>• the Hebrew marks ־ ״ ׳ (the draft uses ASCII `'` and `"` instead);<br>• `←`, `×`, `–` and `—`.<br>**Why it matters:** `Art.font_text` silently swaps any missing glyph for a fallback box.<br>**Can't borrow Latin:** the fork's 7-row Latin `K` sits badly next to the draft's 5-row digits.<br>**Hand-off to the 2D Artist:** draw these glyphs at body height. |
| F5 | Crisp integer scaling | ✅* | **Sizes:** at scale 3 the cell is 27 logical px (14.6 CSS px), which meets the UX ≥ 14 px body minimum.<br>**Inherited limit:** at DPR 3 one logical px maps to 1.625 device px, which is not a whole number, so strokes come out 4 or 5 device px wide. The fork already ships with this. No change requested. |

**Tally:**
- 37 claims reviewed.
- 32 pass (7 ✅, 25 ✅*).
- 5 are objections.

## 2. Objections

```yaml
objection:
  skill_or_agent: game-developer
  id: O-A1
  against_artifact: sonic-brief (od-sevev v1.0) §5 "Anti-fatigue: every 2nd loop swaps in an alternate B-section"
  reason: |
    The fork renders music offline into looping QOA stems (ADR 0002). It plays
    one AudioStreamSynchronized per track, loop 0→end. A loop-counter-driven
    alternate B means each era's stems must hold 64 bars instead of 32. That
    doubles the music from ~9.7 MB to ~19.4 MB (12.2 KB/s per layer, measured on
    the fork). It lands directly in the first-load payload that O-U1 is already
    fighting. Re-sequencing sections at runtime (AudioStreamInteractive clips
    nested with synchronized layers) would replace the fork's proven layer
    machinery for one variation.
  proposed_alternative: |
    1. The "breather" every 4th loop stays as specced. It is a runtime mute of
       L1 and L2 for 8 bars at bar lines, so it costs 0 bytes.
    2. Drop the alt-B swap and write the variety into the 32-bar form: A, A′, B
       and T already differ.
    3. If alt-B is kept, ship it as a 4th synchronized layer ("L1-alt", 32 bars,
       silent outside bars 17–24). On odd loops the runtime crossfades L1 to
       L1-alt for bars 17–24. Cost: +~3.2 MB across 4 eras, instead of +9.7 MB.
```

```yaml
objection:
  skill_or_agent: game-developer
  id: O-A2
  against_artifact: sonic-brief (od-sevev v1.0) §5 "Court day (any era): the current era at 0.75× tempo from the next bar line"
  reason: |
    With offline stems there are three ways to get 0.75× tempo, and all three
    break something.
    (a) pitch_scale 0.75 also drops the pitch by 4.98 semitones. That is a new
        key 2 cents off 12-TET. The tap blips and followsKey cues, which are
        rendered per key, then clash with it. It also breaks the brief's
        "12-TET, no quarter-tones" rule.
    (b) Real-time time-stretch (AudioEffectPitchShift on the Music bus) smears
        the 0 ms chip attacks that pillar 1 and the §2 no-pads rule protect. It
        also runs FFTs on the web main thread (the build has no threads).
    (c) Pre-rendering an L0+L1 court-day set per era costs ~8.6 MB
        (4 eras × 2 layers × 353 s × 12.2 KB/s).
  proposed_alternative: |
    Court day crossfades, at the next bar line, to the Courthouse track (G
    hijaz, 88 BPM) with L2 muted. It uses the fork's existing set_era path: an
    equal-power crossfade at the bar onto the same bar of the new track. The
    taps already follow whichever key is playing.
    - From Balfour, Knesset and Washington, this is a bigger mock-solemn drop
      than 0.75×: 116→88, 132→88 and 144→88.
    - Inside the Courthouse era itself, court day is just the L2 mute plus the
      §4 augmented TRI motif stinger.
    Cost: 0 extra MB. The augmented TRI motif stays as specced (one stinger per
    key).
```

```yaml
objection:
  skill_or_agent: game-developer
  id: O-U1
  against_artifact: ux/first-minute.md §2.1 row 2 "N0 loader ≤ 3 s on 4G"
  reason: |
    The engine alone cannot load that fast. Measured on the fork's web build:
    - index.wasm: 6.9 MB brotli (10.1 MB gzip, 39.5 MB raw);
    - index.pck: 19.3 MB, mostly QOA audio, which does not compress.
    This game's pck at the §1 audio scope is ~12.5 MB (9.7 MB music, plus SFX,
    blips and fanfares). That is ~19 MB on the wire. At 10–20 Mbps it takes
    8–16 s, plus 1–3 s for wasm compile and instantiate on a mid-range phone.
    The 3 s budget is missed by 3–5×, before any art. A loader that long
    breaks the FTUE's premise that the player reaches first agency 1.5–3 s
    after t=0 with nothing in between.
  proposed_alternative: |
    Hide the download behind the reading the player has to do anyway.
    1. N1 (the disclaimer) is rendered as DOM in shell.html. It is HTML, CSS
       and one webfont or system Hebrew, which paints in about 1.5 s on 4G.
       The engine downloads while the player reads (~6 s).
       - Both buttons are live immediately. If the engine isn't ready, the
         tapped button shows a thin progress bar and the stage appears the
         moment the engine is ready.
       - t=0 and the FTUE beat sheet are unchanged.
    2. Split the pck.
       - The boot pck holds Balfour's music, all SFX and the art data (~4 MB).
       - Eras 2–4 are a second pck, fetched after C1 (~minute 1) with
         HTTPRequest and ProjectSettings.load_resource_pack. Era 2 is
         unreachable before then.
    3. Optional: build a lean custom web template (3D and unused modules off;
       TextServerAdvanced kept) to shrink the wasm. Measure it; don't assume.
    Revised budgets:
    - Disclaimer painted: ≤ 1.5 s cold on 4G.
    - Engine ready: ≤ 10 s cold (overlapped with reading).
    - Engine ready on a warm cache: ≤ 2 s.
```

```yaml
objection:
  skill_or_agent: game-developer
  id: O-U2
  against_artifact: ux/first-minute.md §3.5 "Rendering" and "Direction" rows, and §7.3 commitment matrix "Blindness: C … disclaimer, About, settings and share sheets are DOM and screen-reader readable"
  reason: |
    A Godot web export draws every Control into one WebGL canvas. The fork has
    no DOM UI and no accessibility wiring, so nothing in the canvas reaches a
    screen reader. `dir="rtl"` on DOM overlays, `ctx.direction`, and "canvas
    Text vs BitmapText" are HTML and Phaser mechanisms with no Godot
    equivalent. As written, the blindness row promises four readable surfaces
    and the build would deliver none.
  proposed_alternative: |
    1. Make N1 (the disclaimer) and O8 (About, with the inline sources list and
       real "למקור" links) DOM in shell.html. This is the same asset as O-U1.
       - They open over the canvas and use the same history rule (U2).
       - They are static legal text, so DOM also makes them selectable,
         translatable by the browser, and readable by crawlers.
    2. Settings, the share sheets and the chat stay in the canvas.
    3. Restate the blindness row: "C. The disclaimer, About and sources are DOM
       and screen-reader readable. The play surface, settings and share sheets
       are canvas."
    4. Replace the rendering rule with:
       - Hebrew and mixed text: a Godot Label or RichTextLabel with the bitmap
         FontFile (TextServer bidi, LRI/PDI honoured).
       - Purely numeric strings only: PxText.
```

```yaml
objection:
  skill_or_agent: game-developer
  id: O-U3
  against_artifact: ux/first-minute.md §8 overflow strategy "auto-shrink to 85%, then ellipsis" for labels
  reason: |
    The pixel font renders only at whole-number scales (PxText's integer px;
    FontFile fixed_size with integer-only scaling).
    - 85% of scale 3 is 2.55. Drawn with nearest filtering, that gives uneven
      stroke widths and breaks the 2D Artist's pixel grid.
    - Snapping it drops to scale 2 (67%). That is a 9.8 CSS px cell, below the
      spec's own ≥ 14 px body minimum.
    There is no 85% step to shrink to.
  proposed_alternative: |
    Move overflow to build time.
    1. A lint measures every string in pixels with the real proportional font
       against its box, including the large-text scale, and fails the build on
       overflow. It runs next to the §6.3 poll-number lint.
    2. At runtime:
       - Body copy: wrap-2-line, then ellipsis.
       - Labels: ellipsis only.
       - A label drawn at scale ≥ 4 may step down one whole scale (4→3 = 75%).
    3. The character budgets in the §8 table stay as the writers' guide.
       Proportional widths make them conservative.
```

## 3. Hand-offs (these are notes, not objections)

- **Audio Director:**
  - Confirm A12: fanfares pre-rendered by length.
  - Confirm A13: a new era-keyed blip bank.
  - Accept A14: "≤ 1 frame" means scheduling.
- **UX Designer:**
  - U2: Chromium skips history entries pushed before the first interaction.
  - U7: `hud-layout` coordinates ×1.846 on the 720-logical grid.
  - U13: large text is ×1.33.
- **2D Artist:** F4 is the missing glyphs, drawn at body height, before the style guide locks.
- **Game Developer (me, at build time):**
  - A3: the strict tap-walk mode.
  - U2: the history bridge.
  - U3: the clock sources.
  - U10: the web haptics gate.
  - F2: per-glyph advance, plus the `FontFile` route for Hebrew.

## Resolution (Audio)

**Owner:** Audio Director · **Date:** 2026-09-28 · **Brief revised to:** `audio/sonic-brief.md` v1.1

### O-A1: resolved (accepted, option 2)
- **No alternate-section stems.** The 4-layer "L1-alt" option (+3.2 MB) is declined too.
- **Variety at 0 bytes:** a 4-loop cycle of runtime layer mutes at bar lines, driven by a loop counter.
  - Loop 1: full.
  - Loop 2: L2 muted for bars 17–24. The B-section is carried by P2 alone.
  - Loop 3: full.
  - Loop 4: the A′ breather, bars 9–16, L0 only.
- **Composer constraint:** L1's B-section must stand alone as a melody.
- **Music stays at about 9.7 MB** (4 eras × 3 layers × 32 bars).

### O-A2: resolved (accepted as proposed)
- Court day triggers an equal-power crossfade, at the next bar line, to the Courthouse track (G hijaz, 88 BPM) with L2 muted. It goes through the existing `set_era` path.
- The augmented TRI motif stinger (one per key) plays on entry.
- Inside the Courthouse era, court day is only the L2 mute plus the stinger.
- **Cost:** 0 MB.
- Taps and Dubi's blips follow the key that is playing, so court day uses the G files.

### A3: the tap walk survives pre-rendering (confirmed)
- **Count:** 8 scale steps × 4 keys (D hijaz, E hijaz, G hijaz, F Mixolydian) × 2 duties (25/12.5%) = **64 WAV files**.
- **Size:** each file is 80 ms, with the 15 ms NOI-S puff baked into the 40 ms blip, so one tap is one stream. At 16-bit mono and ≤ 32 kHz each is about 5.1 KB (2,560 samples × 2 B + a 44 B header). **About 330 KB in total.**
- **Code:** the strict walk-and-wrap mode on `_scale_pick` is still needed, as in A3.

### Other hand-offs (confirmed)
- **A12:** fanfares are pre-rendered by length, 5 × 4 = 20 stingers, about 1 MB.
- **A13:** a new era-keyed blip bank of 40 blips, about 0.2 MB.
- **A14:** "≤ 1 frame" means scheduling. Tap feel comes from the squash on the same frame.
- **A18:** the master chain is the fork's compressor followed by the HardLimiter at -1 dB.

### Audio's share of the payload, and an offer for O-U1
- **Audio total at this scope:** about 11.3 MB.
  - Music: 9.7 MB.
  - Taps, blips, fanfares and the OUT loop: about 1.6 MB.
  - Other SFX (one-offs): small.
- **If the O-U1 pck split still misses its budget,** Audio will accept rendering the stems for eras 2–4 at 22,050 Hz (or the nearest rate that keeps 16th notes on whole samples), which saves about 30% of those stems.
  - It must stay on the fork's band-limited wavetables, so nothing aliases.
  - On phone speakers the loss above about 11 kHz is inaudible.
  - Measure it before committing.
- **Balfour and every SFX stay at the fork's rate.**

**No Audio objection is outstanding.**

## Resolution (UX)

**Owner:** UX Designer · **Date:** 2026-09-28. All three objections are **accepted**; there are no counter-objections. Every revision is applied in `ux/first-minute.md`.

| Objection | Resolution | Where in `ux/first-minute.md` |
|---|---|---|
| **O-U1:** the ≤ 3 s loader | **Accepted.** This improves the first 10 seconds.<br>• **Surface:** N1, the disclaimer, is HTML in `shell.html`, painted in ≤ 1.5 s cold. The engine (wasm plus a ~4 MB boot pack) downloads behind it while the player reads. The first laugh, "…או מזוודה", now lands ~1.5-3 s after page open, *during* the load.<br>• **t=0:** the tap on a disclaimer button. It stores the sound choice but no longer unlocks audio; audio unlocks on the first Magician tap (A15), so the first sound is the motif.<br>• **If the engine isn't ready:** a hand-off bar fills right to left, with rotating loading lines ("מקפל מזוודות…"). Budget: ≤ 4 s cold, 0 warm.<br>• **Returning players** get an HTML N0 splash, ≤ 2 s warm.<br>• **Split pack:** eras 2-4 load after C1. If that pack is late at the first election, the game stays in Balfour art, with a `[GD]` ticker cover line and no modal.<br>• **Time to first agency:** ≤ 7 s cold on 4G, and ≤ 16 s in the worst case with fallbacks. That is inside the 30 s web budget. | §2.1 (new pre-gameplay table), §2.2 beats −7.5 s to 0.3, the time-to-agency line, §1.1 N0/N1, §1.3 entries, §8 load.* and load.bar.label |
| **O-U2:** DOM assumptions | **Accepted.**<br>• **HTML:** N0, N1, the hand-off bar and O8 (About with the inline sources and real "למקור" links).<br>• **Canvas:** settings, the share sheets, the chat and the HUD.<br>• **Rendering rule restated:** Hebrew and mixed text go through a Godot `Label` / `RichTextLabel` with the bitmap `FontFile` (TextServer bidi, LRI/PDI honoured). `PxText` is for purely numeric strings only. `layout_direction = RTL` on canvas Controls.<br>• **Blindness row restated honestly:** C. HTML surfaces are readable; the canvas is not. An `aria-live` bridge is deferred, not promised.<br>• **Keyboard:** native focus on HTML, Godot focus neighbours on the canvas. | §3.5 Direction and Rendering rows, glyph row (+ F4 missing glyphs), §6.1 layout, §6.2, §7.3 Blindness row, §7.4, §9 developer hand-off |
| **O-U3:** 85% auto-shrink | **Accepted.**<br>• **Build time:** a pixel-width lint at both text scales (3 and 4), next to the poll-number lint.<br>• **Runtime:** body copy wraps to 2 lines, then ellipsis. Labels use ellipsis only. A label at scale 4 may step to scale 3 (75%).<br>• **One addition:** a ★ string may never ship truncated, because its punchline is last. The lint enforces it.<br>• **Large text** is restated as ×1.33 (scale 3 → 4), per U13. | §8 overflow paragraph, §7.2 large-text row |

**Notes also taken:**

- **U2 (history).** The layers that open on their own at launch (O1, O11, O12) push their history entry on the first `pointerdown`. Because back may leave the page before that first touch:
  - O1 credits the offline money **when it opens**;
  - O11 and O12 count as seen when shown.

  A layer closed by its own button calls `history.back()` and ignores the echo. (§1.1, §1.2 rule 1)
- **U3 (clock).** `now = max(device clock, Date header of a same-origin HEAD fetch, build timestamp, saved high-water mark)`. When online, the high-water mark is clamped to server time. Plus the publisher's 22.10 flag-build backstop. (§6.3 item 1)
- **U7 (units).** The spec stays in CSS px. ×1.846 gives the fork's 720-logical grid; hit areas round up. (§3.1)
- **U9 (share).** The card renders when the sheet opens. The preview shows "מדפיס…" while it renders, and "לשתף" is disabled until the file is ready. The fiction label is always on the image, because iOS WhatsApp drops the text. (§5.1)
- **U10, U14:** implementation notes for the Game Developer. No UX change is needed.
