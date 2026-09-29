# audio-cue-spec — Monkey Bananas

Owner: Audio Director. Consumer: **Game Developer (Wave 4)**. Also relevant to the Game Designer (event list, section 4) and the UX Designer (settings, section 5).
Machine-readable source of truth: [`cues.json`](cues.json) (SFX, events map, mix block) and [`music.json`](music.json) (music). If this page and the JSON disagree, **the JSON wins**. Reference implementation: [`preview.html`](preview.html) (`ChipAudio`, `MusicPlayer`). You can port it to TypeScript nearly line for line.
Related: [`sonic-brief.md`](sonic-brief.md) (identity), [`mix-bus-topology.md`](mix-bus-topology.md) (buses, gains, limiter, loudness).

**Zero audio files.** Everything is synthesized with standard Web Audio nodes: `OscillatorNode` (including a `PeriodicWave` for pulse), `AudioBufferSourceNode` (a pre-generated LFSR noise buffer), `GainNode`, `BiquadFilterNode`, `WaveShaperNode` and one `DynamicsCompressorNode`. **No AudioWorklet is required** (`audioworklet_required: false`).

---

## 1. Runtime architecture (what to build)

```
AudioEngine (singleton, outside Phaser scenes; owns ONE AudioContext)
 ├─ ChipAudio      play(cueId, {semis}), event(name, arg), duck/release, setEnabled(group, on), flags, keyOffset
 └─ MusicPlayer    lookahead scheduler, setFrenzy(on), setEvolutions(n), command('start'|'restart'|'fadeOutStop:400'|...)
```
- **Recommendation for Phaser 4:** set `audio: { noAudio: true }` in the game config and let `AudioEngine` own its own `AudioContext({ latencyHint: 'interactive' })`. Phaser's sound manager plays files, and there are none. Running two contexts would double the unlock handling.
- Gameplay code emits **named events** only (`audio.event('tap')`, `audio.event('goldenCatch', 'frenzy')`). The `events` map in cues.json turns each event into a cue plus music commands plus flag changes, so gameplay code never touches synthesis details.
- **Latency:** play cues at `ctx.currentTime` (no added offset) inside the same frame handler that awards the tap. That keeps the SFX within feel-spec's 1-frame target plus the device's `outputLatency`.

## 2. Synthesis contract (per layer)

The fields are documented in `cues.json → _schema`. The implementation rules are these (preview.html `_layer()` is the reference):

| Topic | Rule |
|---|---|
| Pulse waves | `wave:'pulse'` with `duty` 0.125 or 0.25. Build **one `PeriodicWave` per duty** at startup: `real[n] = (2/(nπ))·sin(nπ·duty)`, `imag[n] = 0` for n = 1..64, with normalization **on**. Use native `'square'` for 50 %. Normalization makes every duty peak at 1.0. RMS: square 0 dB, 25 % −4.8 dB, 12.5 % −8.4 dB. The layer gains already account for this. |
| Noise | Generate a 15-bit LFSR buffer **once per context**. Long mode uses feedback bit0⊕bit1 (period 32767 samples); `noiseMetal` uses short mode, bit0⊕bit6. Seed 1, output `bit0 ? −1 : +1`, one step per sample, buffer length = one period, `loop = true`, and start each voice at a random offset. `playbackRate = clockHz / ctx.sampleRate`. |
| Crush | `crush: 4` puts a `WaveShaperNode` between the oscillator and the envelope. The curve is a mid-tread staircase: `curve[i] = round(x·8)/8` (17 levels), `oversample 'none'`. Cache one curve per bit depth. |
| Envelope | One `GainNode` per layer: `setValueAtTime(0,t)`, `linearRamp(peak, t+attack)`, then a ramp to `peak·sustain` at `t+attack+decay` (exponential with a 0.0001 floor, or linear if `envCurve:'lin'`), `setValueAtTime(level, t+duration)`, a ramp to the floor at `t+duration+release`, and `setValueAtTime(0)`. Stop the source at end + 20 ms. `duration ≥ attack + decay` always holds (validated). |
| Sweeps | `freqStart → freqEnd` over `glide` (default `duration`), with a curve of exp, lin or step. |
| Arpeggio | `setValueAtTime(f0·2^(semi/12), t + i/arpRateHz)` for each step. It loops by default; `arpLoop:false` plays once and holds. An arpeggio and a sweep are mutually exclusive. |
| Vibrato | A sine LFO into `detune` (cents). Its depth ramps in over 50 ms after `vibrato.delay`. |
| Pitch offset | `semis = (followsKey ? keyOffset : 0) + opts.semis + randomPitch(+streak)`. It multiplies every layer with `followPitch` (true by default for tonal layers, false for noise and for the drum-like "thump" layers). |

## 3. The tap cue: fatigue and clipping plan (16 triggers/s)

The tap is the most-played sound in the game (120–960 per minute). Six mechanisms keep it pleasant and inside headroom:

| # | Mechanism | Numbers | Why |
|---|---|---|---|
| 1 | **Scale-quantized pitch pool** | Each tap picks one of `window: 3` adjacent degrees from `scaleSemis [0,3,5,8,10,12,15,17]` above root A5 (F-major pentatonic A C D F G A C D), with **`noRepeat`** so the same degree never plays twice in a row. The spread is about ±2.5 semitones around the window centre. | Continuous random detune clashes with the music. A pentatonic pool can never be out of key, so a tap stream becomes a melody. No two consecutive taps are identical. |
| 2 | **Streak climb** | Taps less than `gapMs: 350` apart form a streak. The window base rises by 1 degree every `tapsPerStep: 6` taps, up to `maxSteps: 4` (top window G6–A6–C7). A 350 ms gap resets it immediately. | It rewards rhythm (Guitar Hero rising pitch). At 16/s the climb takes about 1.5 s, then plateaus instead of going shrill. |
| 3 | **Rate compensation** | `rate` = taps in the last 1000 ms. Gain is cut by `6 dB × clamp((rate−6)/(16−6), 0, 1)` (was 4 dB from 8/s before the 2026-09-27 rebalance). | Temporal loudness integration: a 16/s stream carries 4× the energy of a 4/s one. With the tap 4.5 dB hotter after the rebalance, the deeper cut keeps the 16/s stream within about 2 LU of the reference mix and keeps it off the compressor. |
| 4 | **Polyphony 3, steal oldest** | `polyphony: 3`, `steal: 'oldest'`: the stolen instance fades over `stealFadeMs: 6` (a ramp on its instance gain; no `cancelAndHold`, which Firefox lacks). | The voice lasts 81 ms, so at 16/s (every 62.5 ms) at most 2 overlap. The cap of 3 is a hard ceiling that also covers multi-touch "piano" (mechanic-spec E9). The newest tap always sounds, because feedback must never lie about income. |
| 5 | **Short, pitched, low-crest voice** | A triangle "plink" (pure, 70 ms decay) plus a 12 ms high-passed noise click (5 kHz+ presence) plus a 45 ms pitch-drop thump (420→150 Hz body). ±1.5 dB gain jitter. The thump gets ±1 semitone of its own jitter. | The triangle's weak harmonics avoid the 2–4 kHz harshness of square waves. The click carries identification on phone speakers (it survives a 300 Hz high-pass). |
| 6 | **Band ownership** | Tap tonal band 880–2100 Hz (up to 2800 Hz at key +5). **The music never plays above 587 Hz** (the lead tops out at D5; only the quiet frenzy arpeggio reaches 932 Hz). | Taps stay on top without ducking the music. |

**Crit:** `tapCrit` **replaces** `tap` for that pointer-down (do not play both). Call `touch('tap')` so the crit still counts toward the tap streak and the rate window. Its polyphony is 2 (at most 1.6 crits/s at 10 % × 16/s).
**Tap Frenzy:** while `flags.tapFrenzyActive` is set, every tap adds the `frenzySparkle` layer (a 12.5 % pulse an octave up), so the buff is audible on every tap.
**Taps dropped by the 16/s cap** (mechanic-spec rule 2) must not call `audio.event('tap')` at all.

**Measured result** (after the 2026-09-27 rebalance; preview.html offline render, BS.1770; full table in `mix-bus-topology.md` §5 and §7): a 16/s tap stream with 10 % crits measures −14.2 LUFS on its own. Music plus 16/s taps is −14.2 LUFS with a −2.4 dBFS sample peak, so there is no clipping, and compressor gain reduction stays at or below 2.5 dB (p10). The reference mix (music plus 4 taps/s) is −16.2 LUFS over a −20.1 LUFS bed. A single tap now peaks +3.9 LU over the bed's median in 100 ms windows through the 300 Hz phone proxy (v1: −1.7 LU).

## 4. Cue list: trigger mapping

The **Event** column holds the mechanic-spec §9 event IDs. **Added** events are ones Audio needs that are not in §9; their derivations are listed so the developer can emit them without a design change.

| Event | Cue | Bus | Gain dB | Prio | Poly / steal | Cooldown | Length | Trigger (who and when) |
|---|---|---|---|---|---|---|---|---|
| `tap` | `tap` | sfx | −7.5 | 3 | 3 / oldest | 0 | 81 ms | Registered Big Banana pointer-down (or Space keydown, no repeat), **on the pointer-down frame**, after the 16/s cap check |
| `tapCrit` | `tapCrit` | sfx | −6.5 | 2 | 2 / oldest | 0 | 231 ms | The crit roll succeeded on that tap. Plays **instead of** `tap` |
| `buy` | `buy` | sfx | −8 | 3 | 3 / oldest | 0 | 127 ms | Commit bought exactly 1 unit (including each hold-to-repeat tick at 10/s, which climbs the scale; see the streak) |
| `buyBulk` | `buyBulk` | sfx | −8 | 3 | 2 / oldest | 0 | 270 ms | Commit bought more than 1 unit (×10, or MAX ≥ 2) |
| `cantAfford` | `cantAfford` | sfx | −13 | 3 | 1 / oldest | 120 ms | 210 ms | Commit on an unaffordable row, or MAX with 0 affordable |
| `upgradeBuy` | `upgradeBuy` | sfx | −10 | 2 | 2 / oldest | 0 | 301 ms | Upgrade purchased |
| `goldenSpawn` | `goldenSpawn` | sfx | −9 | 2 | 1 / oldest | 0 | 450 ms | Golden appears (f0 of its 300 ms fade-in). Ducks `cue:tap` by −6 dB for 300 ms |
| `goldenCatch` (bunch) | `goldenCatchBunch` | sfx | −6 | 1 | 1 | 0 | 490 ms | Golden tapped, outcome Lucky Bunch. Ducks music −6 dB (hold 500, release 400) and tap −4 dB |
| `goldenCatch` (frenzy) | `goldenCatchFrenzy` | sfx | −6 | 1 | 1 | 0 | 570 ms | Outcome Banana Frenzy; then `frenzyStart` |
| `goldenCatch` (tapFrenzy) | `goldenCatchTapFrenzy` | sfx | −6 | 1 | 1 | 0 | 420 ms | Outcome Tap Frenzy; then `tapFrenzyStart` |
| `goldenDespawn` | `goldenDespawn` | sfx | −21 | 4 | 1 | 0 | 280 ms | Missed Golden begins its 200 ms fade-out. Soft by design |
| `frenzyStart` | none | — | — | — | — | — | — | Sets `frenzyActive`; music `layerOn:frenzy` (next beat). The catch cue is the audible start |
| `frenzyEnd` | `buffEnd` | sfx | −14 | 2 | 1 | 0 | 400 ms | Banana Frenzy timer reaches 0; music `layerOff:frenzy` (next bar) |
| `tapFrenzyStart` | none | — | — | — | — | — | — | Sets `tapFrenzyActive`; music `layerOn:frenzy` |
| `tapFrenzyEnd` | `buffEnd` | sfx | −14 | 2 | 1 | 0 | 400 ms | Tap Frenzy timer reaches 0; clears the flag; `layerOff:frenzy` |
| `milestoneHeadline` | `milestoneHeadline` | sfx | −14 | 2 | 1 / none | 1500 ms | 571 ms | A once-ever headline pre-empts the ticker (at the 120 ms flash). **Not** for ambient headlines. Ducks music −3 dB |
| `evolveOpen` | `evolveOpen` | sfx | −10 | 2 | 1 | 300 ms | 700 ms | Evolution screen opens. Ducks music −8 dB **until** `evolveClose` or `evolveConfirm` |
| `evolveConfirm` | `evolveConfirm` | sfx | −8 | 1 | 1 / none | 0 | 1470 ms | Confirm pressed, at the start of the 1500 ms transition. Music `fadeOutStop:400` |
| `offlineCollect` | `offlineCollect` | sfx | −7 | 1 | 1 / none | 0 | 880 ms | See **Objection** (section 7). It must fire on a user gesture. Ducks music −6 dB |
| **added** `evolveReady` | `evolveReady` | sfx | −10 | 2 | 1 / none | 0 | 700 ms | Rising edge of the derived `evolveEnabled` (false→true), **once per run**. Ducks music −4 dB |
| **added** `evolveClose` | `panelClose` | ui | −14 | 3 | 1 | 60 ms | 122 ms | Evolution screen dismissed without evolving. Releases the evolveOpen duck |
| **added** `evolveTransitionEnd` | none | — | — | — | — | — | — | When input unlocks: `evolveConfirm` + 1500 ms, or + 1200 ms under reduced motion. Music `restart`, **scheduled at max(now, evolveConfirm + 1470 ms)** (see §6) |
| **added** `producerReveal` | `producerReveal` | sfx | −12 | 2 | 1 | 300 ms | 340 ms | A producer row changes from silhouette "???" to revealed (mechanic-spec rule 6), not on load |
| **added** `becameAffordable` | `affordGlint` | sfx | −24 | 4 | 1 / none | **2500 ms global** | 101 ms | feel-spec "Became affordable" glint edge (already limited to 1 per row per 5 s). Audio adds a global 2.5 s cooldown |
| **added** `uiClick` | `uiClick` | ui | −13 | 3 | 2 / oldest | 40 ms | 37 ms | Any generic button press (close, collect, settings rows) on pointer-up commit |
| **added** `uiToggle` | `uiToggleOn` / `uiToggleOff` | ui | −13 | 3 | 2 | 40 ms | 81 ms | Settings toggle by new value. Turning SFX **on** plays `uiToggleOn` after unmuting; turning SFX off plays nothing |
| **added** `buyModeCycle` | `uiToggleOn` | ui | −13 | 3 | 2 | 40 ms | 81 ms | Buy-mode toggle; `semis` = 0 / +4 / +7 for ×1 / ×10 / MAX |
| **added** `panelOpen` / `panelClose` | `panelOpen` / `panelClose` | ui | −14 | 3 | 1 | 60 ms | 122 ms | Any overlay opens or closes (settings, stats, offline modal) |
| **added** `audioUnlock` | none | — | — | — | — | — | — | Exactly once per page session, on the first transition of the context to `running` (section 5, U3/U4). Music `start` |

**Global voice cap:** `maxCueInstances: 20` across the sfx and ui buses. When full, steal the instance with the highest priority number (lowest importance) that is at least as unimportant as the new cue, oldest first; otherwise drop the new cue. Critical (priority 1) cues are never dropped for normal cues.

**Hit-frame alignment:** there are no animation-authored hit frames in this game. Every cue is impact-aligned to feel-spec's "Fires f0" rows (pointer-down or commit frame). The Golden spawn cue aligns to f0 of the fade-in, and the Evolve fanfare's downbeat (C6 + crash at +720 ms) lands during the title card.

## 5. Platform behaviour (unlock, audio session, settings, hidden tab)

**Revised 2026-09-27 after the "There is no sound" report.** The v1 rule called `ctx.resume()` once, on the first `pointerdown`/`touchend`/`keydown`, then removed its listeners and never retried. A touch `pointerdown` does not grant user activation, so on phones that single call never started the context and the whole session stayed silent. The rules below replace v1 entirely. The numbers live in `cues.json → unlock`, and the reference implementation is `preview.html → class AudioUnlock`: port it, don't reinvent it.

**What grants user activation** (HTML spec, "activation triggering input event"): `keydown` (except Esc and browser-reserved keys), `mousedown`, `pointerdown` with `pointerType "mouse"`, `pointerup` with any other `pointerType`, and `touchend`. On a touch screen the activation therefore arrives when the finger **lifts**, not when it lands.

### Unlock contract (rules U1 to U10)

| # | Rule | Detail |
|---|---|---|
| **U1** | **Boot order** | In `init()`: create the one `AudioContext({ latencyHint: 'interactive' })`, apply the persisted settings to `busUser` (a muted player never hears a first note), set the audio session (U7), install the gesture listeners (U2), install the `statechange`, `visibilitychange` and `pageshow` handlers, then check U4. A context that is `suspended` at creation is normal, not an error. |
| **U2** | **Retry on every gesture** | Listen on `window` for `pointerdown`, `pointerup`, `touchend`, `click` and `keydown` with `{ capture: true, passive: true }`. Never call `preventDefault`. Install the listeners **once, for the life of the page**. The handler: (a) returns if `document.hidden`; (b) starts the legacy silent element if U7 needs it; (c) returns if `ctx.state === 'running'`; (d) calls `ctx.resume()` **synchronously in the handler**, with no `await`, timer or promise continuation before it, attaching `.then(onRunning)` and a no-op `.catch`; (e) starts a 1-sample silent `AudioBufferSource` into `ctx.destination`, because older WebKit unlocks only when a source starts inside the gesture. The handler never sets an "unlocked" flag and never detaches. |
| **U3** | **Confirm by state, not by the call** | One idempotent `onRunning()` runs from the context's `statechange` event and from every `resume()` resolution. It does nothing unless `ctx.state === 'running'`. Otherwise it (1) flushes the first-cue slot (U8), then (2) if `everRan` is false, sets it and emits `audioUnlock` (music `start` if `settings.music`). **`audioUnlock` fires exactly once per page session.** Once running, the listeners stay installed but idle, because step (c) returns immediately. |
| **U4** | **Created running** | If `ctx.state === 'running'` right after construction (the browser already allows autoplay: sticky activation carried over from a same-origin navigation, Chrome's Media Engagement Index, or an installed PWA): when the document is visible, call `onRunning()` on the next microtask, so the **music starts at boot with no gesture**. In both cases set `autoplayAllowed = true`. When it is hidden, take the U6 hidden path (suspend); because `autoplayAllowed` is set, the first visible resume (U6) needs no gesture and runs `onRunning()`, so the music starts on first view. *Decision:* start immediately rather than wait for the first gesture. The browser has already decided sound is welcome, and one code path (`onRunning`) is simpler than a special "wait anyway" branch. |
| **U5** | **Losing `running` while visible** | When `statechange` reports anything other than `running` that we did not request (`'suspended'`, or `'interrupted'` in WebKit for a phone call, Siri, an alarm or another app taking the audio session), and `everRan` is true, then: do not suspend and do not stop the music (the scheduler freezes with `currentTime`). Call `ctx.resume()` once without a gesture; it often succeeds once the interruption ends and is harmless otherwise. The still-installed U2 listeners retry on the next gesture. The return to `running` goes through `onRunning()`: the slot flushes, but `audioUnlock` does not fire again. **Always test `state !== 'running'`**; never treat `=== 'suspended'` as meaning "not running", because `'interrupted'` is a real value in Safari. |
| **U6** | **Hidden tab and bfcache** | On `visibilitychange` to hidden: set `selfSuspended = true`, clear the first-cue slot, call `ctx.suspend()`, and pause the legacy silent element. On visible, and on `pageshow` with `persisted === true`: set `selfSuspended = false`, `play()` the legacy element if music is on, and if `everRan || autoplayAllowed` (U4) and the context is not running, call `ctx.resume()`. On iOS that attempt can fail without a gesture; the U2 listeners cover it. Offline credit on return stays silent (mechanic-spec rule 9). If UX shows a modal, it uses `panelOpen`. |
| **U7** | **iOS ringer switch and audio session** | Where `navigator.audioSession` exists (Safari 16.4 and later), set `navigator.audioSession.type = settings.music ? 'playback' : 'ambient'` at init, before any resume, and again on every `settings.music` change. Where it does not exist, on iOS/iPadOS WebKit only (`/iP(hone\|ad\|od)/` in the UA, or `platform === 'MacIntel'` with `maxTouchPoints > 1`) and only while `settings.music` is on: inside a gesture (U2 b), `play()` a looping silent `<audio>` element. Its source is an in-memory WAV blob URL (0.5 s, 8 kHz, 16-bit mono; the spec is in `cues.json → unlock.legacySilentElement`), with `playsinline`, `loop` and `disableRemotePlayback`. Pause it on hidden and when music is turned off; `play()` it again on visible and when music is turned back on. |
| **U8** | **The unlocking gesture sounds its own cue** | While the context exists and is not running and the document is visible, an `event()` that maps to a cue (a) applies its flags immediately, as before, and (b) stores `{ name, arg, t: performance.now() }` in a **one-slot** queue, where the newest replaces any older entry. `touch()` is not queued. Events whose music command is `start` or `restart` are not queued, because `audioUnlock` owns the first start. In `onRunning()`, before `audioUnlock`: if the slot is at most **180 ms** old (`unlock.firstCueDeferMaxMs`), dispatch that event through the normal path at `ctx.currentTime` with no offset; otherwise discard it. Clear the slot either way, and clear it on hidden. |
| **U9** | **Debug surface** | The existing debug hook reports `ctx.state`, `unlocked` (which now means `everRan`), `sessionType` (`navigator.audioSession.type`, `'legacy-playback'` or `'default'`) and the name of the pending slot cue. That is what on-device review reads. |
| **U10** | **Never** | Set an unlocked flag at call time. Detach the gesture listeners. Call `resume()` only once. Make a timer, rAF or promise continuation the *only* resume attempt. Treat `=== 'suspended'` as "not running". Start music anywhere except `audioUnlock` and the settings toggle. Create a second `AudioContext` (Phaser stays `noAudio`). |

**Why five events (U2).** Mouse `pointerdown` and `keydown` grant activation at press time, which is the earliest possible desktop unlock. `pointerup` and `touchend` grant it for touch and pen. `click` is the backstop for synthesized activations, such as assistive technology or Enter/Space on a focused button. Calls from events that do not grant activation (a touch `pointerdown`, Esc) are harmless: the promise either stays pending or rejects.

**Why the listeners are never detached (U2, U3).** The orchestrator's brief said to detach them once running. I kept them installed but idle instead. Every loss case (U5 interruption, U6 tab return on iOS, bfcache restore) needs them back, and re-arming logic is exactly where the v1 bug lived. The cost is five capture listeners that each return after one property read.

**Why 180 ms (U8).** ITU-R BT.1359-1 puts the acceptability limit for sound lagging picture at about 185 ms (it becomes detectable at about 125 ms). Measured in `preview.html` in desktop Chrome on 2026-09-27: mouse `pointerdown` to `running` took 56 ms, so the first click always sounds. On touch, activation waits for the finger to lift, so the delay is the contact time (typically 60–120 ms) plus the resume (10–50 ms). Most first taps therefore sound; a long first press drops its cue rather than play it late enough to read as lag. The queue has one slot because replaying a burst would stack voices and misrepresent timing.

**Why the session follows the Music setting (U7). This reverses the v1 rule** ("respect the ringer switch, never force `playback`"). The `'playback'` type makes the game play with the ringer switch on silent, which is what players expect from a browser tab (web video does the same). Its cost is that it pauses the player's own audio app. That trade is right exactly when our music is on, because two songs at once is a clash anyway. With Music off, the player is telling us they are listening to something else or want quiet, so `'ambient'` mixes the SFX under their audio and obeys the switch (Apple's HIG convention for non-essential game sound). Desktop and Android have no audio session to set, so nothing else is needed there. For UX: turning Music off on an iPhone also makes SFX obey the silent switch. No settings UI change is needed.

**Settings → buses.** The UX Designer owns the toggles; audio defines what they do. `settings.sfx` sets `busUser.sfx` **and** `busUser.ui` to 1 or 0. `settings.music` sets `busUser.music` to 1 or 0 **and re-applies U7**. Ramp with `setTargetAtTime(v, now, 0.010)` (toggleRampMs 30), never an instant jump (that clicks). With music off, also `stop()` the scheduler to save CPU. Turning it back on restarts at bar 1.

**Hidden tab and the scheduler.** No special handling is needed: `currentTime` freezes while suspended, and `tick()` skips any steps it fell behind on (it never crams them). This matches the Golden timer, which also runs only while visible.

**On-device review** (craft verification, not an automated test; read the U9 debug surface):
1. iPhone, ringer switch on silent, Music on: the first TITLE tap plays its own tap cue, the music starts, and `sessionType` reads `playback`.
2. Android Chrome: the first tap sounds (deferred by less than 180 ms), and `unlocked` becomes true on that tap's finger lift.
3. Desktop: the first click and the first Space press both sound.
4. Background the tab, then return: the music resumes where it froze. On iOS, if it has not resumed, the next tap brings it back.
5. iPhone: take a call or trigger Siri mid-play, then return. The state passes through `interrupted` and the next tap resumes it; `audioUnlock` is not re-fired and the music does not restart at bar 1.
6. iPhone, Music off, ringer switch on silent: silence, by design. Spotify playing: the SFX mix under it.

## 6. Music playback (see music.json)

- **Scheduler:** the lookahead pattern from Chris Wilson's "A Tale of Two Clocks". A `setInterval` every **25 ms** schedules every step whose time is before `currentTime + 0.100` s, using `start(when)` on each voice. Never use `setTimeout` per note. Step = one 8th-note triplet = 60/126/3 = **0.1587 s**, and one bar is 12 steps.
- **Data:** 6 channels (`lead`, `bass`, `drums`, `comp`, `perc`, `arpFrenzy`), each with 4-bar strings per section. The form is `A A2 B B2 A A2 C A2` = **32 bars = 60.95 s**, and it loops seamlessly. The C4 pickup on the last step of bar 32 leads into bar 1's motif, so the seam falls inside a phrase.
- **Adaptive layers** (vertical re-orchestration only; no horizontal branching):
  - `base` = lead, bass and drums, always on.
  - `evolved` = comp (off-beat 12.5 % stabs). On when `evolutions ≥ 1` and frenzy is off.
  - `frenzy` = bongo/shaker triplets plus a 12.5 % arpeggio. On while `frenzyActive || tapFrenzyActive`. It enters on the **next beat** (40 ms fade), leaves on the **next bar** (200 ms fade) and forces `evolved` off while active.
- **Key lift after Evolve:** `keyOffset = [0, 2, 4, 5][evolutions % 4]` semitones. It applies to every tonal music note **and** every cue with `followsKey`, so taps stay in the song's key.
- **Evolve sequence:** `evolveConfirm` → music state gain falls linearly to 0 over 400 ms, then the scheduler stops, while the fanfare plays (1.47 s). `evolveTransitionEnd` (+1500 ms) → `setEvolutions(n)`, restart at bar 1 in the new key, fading in over 300 ms.
- **Decision (reduced motion, 1,200 ms transition):** the music restart is scheduled at `max(evolveTransitionEnd, evolveConfirm + 1470 ms)`, i.e. never before the fanfare ends (`cues.json → events.evolveTransitionEnd.restartNotBefore`). Why not accept the overlap: the fanfare holds C6 over an F chord in the *old* key from 720 to 1470 ms, and the restart plays the motif in the *new* key (+2 st), which would clash for about 270 ms. The cost is at most 270 ms of silence after input unlocks, and it is masked by the fanfare's release tail and the 300 ms fade-in. Input and visuals are not delayed.

## 7. Objection

```yaml
objection:
  skill_or_agent: audio-director (cue-specification-and-handoff)
  against_artifact: feel-spec/meta-beats (Offline collect: "Collect SFX when the roll ends")
  reason: |
    On a cold page load, the offline modal appears and its 800 ms counter roll finishes before
    the player has touched anything. Every browser keeps the AudioContext suspended until a user
    gesture (autoplay policy), so the offlineCollect cue, the game's welcome-back reward beat, is
    silently dropped on 100% of cold loads, which is exactly when it matters. Queuing it until the
    unlock would play a "roll finished" sound seconds after the visual roll, which desyncs the beat.
  proposed_alternative: |
    Tie the beat to the gesture. The offline modal opens with the counter at 0 and a Collect
    button. Pressing Collect (the gesture that also unlocks audio) starts the 800 ms roll, plays
    offlineCollect at press time (its coin roll is 470 ms, then the ka-ching), and awards on roll
    end. If UX keeps an auto-roll, the fallback is: when the modal's Collect/close press
    is the unlocking gesture, play offlineCollect on that press. For in-session returns (tab was
    hidden) the context is already unlocked and the spec works as written.
```

## 8. Handoff checklist for the developer

1. Port `ChipAudio` and `MusicPlayer` from preview.html. Load `cues.json` and `music.json` as imports; do not hand-copy any number.
2. Wire the events from the section 4 table, including the **added** ones.
3. Implement **unlock rules U1 to U10** and the settings mapping from section 5, porting `preview.html → class AudioUnlock`. Route every cue trigger through the U8 one-slot deferral. Then run the section 5 on-device review.
4. Self-check (craft verification, not an automated test): open `audio/preview.html` served locally (`python3 -m http.server` in `audio/`). The validator panel must show `OK: 0 errors`, and "Tap 16/s" must sound even and unclipped. In the game, the peak meter must never approach 0 dBFS with music, 16/s taps and a golden catch together.
5. Data edits: change `tools/gen_music.py` → run it, then `tools/build_preview.py` (which re-inlines both JSONs into the preview).
