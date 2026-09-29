# mix-bus-topology — Monkey Bananas

Owner: Audio Director. Consumer: Game Developer (mixer abstraction).
Machine-readable copy: `cues.json → mix` (the developer reads the numbers from there; this page gives the rationale). Reference implementation: `preview.html → ChipAudio._buildGraph()`.

## 1. Graph

```
 per cue instance                         settings toggle        level              master
 [layers]─►instGain(dB, steal fade)─►cueGroup[id]─►busUser.sfx (0|1)─►bus.sfx  (0 dB)──┐
 [layers]─►instGain──────────────────►cueGroup[id]─►busUser.ui  (0|1)─►bus.ui  (0 dB)───┤
                                     (duck target)  (driven by settings.sfx)            │
 music channels─►chGain─►layerGain[base|evolved|frenzy]─►musicMix─►musicState─►musicDuck─►busUser.music─►bus.music (−12.5 dB)─┤
                                  (quantized layer fades)          (evolve fade) (ducks)  (settings.music)                     │
                                                                                                                              ▼
                                         master pre-gain (−1.7 dB) ─► DynamicsCompressorNode ─► outputTrim (0 dB) ─► destination
```

Everything is **mono**. Sources are mono and the destination up-mixes to both speakers. There is no panning, by design (sonic-brief no-go: no stereo tricks; phones have one driver).

## 2. Buses

| Bus | Gain dB | Linear | Toggle | Content | Priority vs others | Polyphony |
|---|---|---|---|---|---|---|
| `music` | **−12.5** (was −10.5) | 0.237 | `settings.music` | 6 channels, never more than 6 simultaneous voices | Lowest: it gets ducked, never ducks others | fixed by the arrangement |
| `sfx` | **0** | 1.000 | `settings.sfx` | Gameplay cues (tap, buy, golden, evolve, headline, offline) | Highest | per cue (1–3), global cap 20 instances |
| `ui` | **0** (was −2) | 1.000 | `settings.sfx` (UI shares the SFX toggle, because settings has only `{sfx, music}`) | Clicks, toggles, panel open/close | Above music | per cue (1–2), inside the global 20 |
| master pre-gain | **−1.7** | 0.822 | — | Sum of the three buses | — | — |

Per-cue levels (`gainDb`, −24 to −6 dB) live in cues.json. The 2026-09-27 rebalance (section 7) changed the music and UI buses and seven cue levels. Layer gains are linear (0–1) and relative inside each cue.

## 3. Ducking rules

Ducks are applied to a **target** GainNode: `bus:music` = `musicDuck`, and `cue:<id>` = that cue's `cueGroup`. When ducks overlap on one target, **the deepest one wins** (the minimum dB). Ramps use `setTargetAtTime` with a time constant of ms/3, so a ramp reaches 95 % in the stated time.

| Trigger cue | Target | Depth | Attack | Hold | Release | Why |
|---|---|---|---|---|---|---|
| `goldenCatch*` (all 3) | bus:music | −6 dB | 30 ms | 500 ms | 400 ms | The biggest reward in normal play gets the room to itself |
| `goldenCatch*` | cue:tap | −4 dB | 10 ms | 400 ms | 200 ms | The player is often mid-streak when catching |
| `goldenSpawn` | cue:tap | −6 dB | 10 ms | 300 ms | 200 ms | The spawn shares the tap's band (1.3–2 kHz); the attention cue must win |
| `offlineCollect` | bus:music | −6 dB | 40 ms | 700 ms | 400 ms | The welcome-back beat |
| `evolveReady` | bus:music | −4 dB | 30 ms | 500 ms | 400 ms | The gate opening is a headline moment |
| `milestoneHeadline` | bus:music | −3 dB | 20 ms | 350 ms | 300 ms | A light dip so the bell reads |
| `evolveOpen` | bus:music | −8 dB | 80 ms | **until** `evolveClose` or `evolveConfirm` | 300 ms | A contemplative screen; the music steps back while the player decides |
| `evolveConfirm` | (music state) | → silence | linear 400 ms | — | restart +1500 ms, fade-in 300 ms | The fanfare owns the transition; the new key starts clean |

**Not ducked, on purpose:** tap, crit, buy, UI. They fire up to 16/s, and ducking at that rate would pump the music. They win by **frequency slot** instead (sonic-brief §7): the music never plays above 587 Hz except the quiet frenzy arp, while the SFX tonal content sits at 880–2800 Hz and the noise transients at 4–10 kHz.

## 4. Master dynamics (a safety net, not a loudness tool)

`DynamicsCompressorNode`: **threshold −14 dB, knee 8 dB, ratio 6, attack 0.002 s, release 0.2 s.** Output trim 0 dB.

Web Audio's compressor applies **automatic makeup gain** (about 0.6 × the full-scale gain reduction, per the spec's algorithm). I measured the static curve through the actual chain (a 997 Hz sine into `bus.sfx`, rendered offline):

| Into a bus (dBFS) | −40 | −20 | −14 | −10 | −6 | −3 | 0 | +3 | +6 |
|---|---|---|---|---|---|---|---|---|---|
| Out (dBFS) | −36.4 | −16.4 | −10.4 | −6.7 | −4.8 | −4.2 | −3.7 | −3.1 | −2.6 |

So normal material passes with a flat **+3.6 dB** net gain (pre-gain −1.7 plus makeup about +5.3). Anything that sums above about −10 dBFS at a bus is squeezed into a **soft ceiling around −3 to −2.6 dBFS**, even at +6 dBFS of overload. That gives about 1.5–2 dB of margin to a −1 dBTP true-peak line. The compressor also adds about 6 ms of lookahead delay, which is inside the 1-frame latency budget.

## 5. Loudness: target, and how it is approximated

**Target intent:** web **−16 LUFS integrated ±1 LU** for the *reference active-play condition* (music plus taps at 4/s with 5 % crits, the designed human tap rate of 2–4/s). The music bed alone sits about 4 LU below (−20.1 LUFS since the section 7 rebalance), so the feedback layer carries the mix. Sample peak stays at or below −3 dBFS at the reference and at or below −2 dBFS in the autoclicker worst case.

**Why it cannot simply be "measured":** procedural audio has no master file. Loudness depends on the player's tap rate, buffs and game state, and there is no static render to meter. The studio approximates it instead:
1. **Gain staging by construction.** Normalized oscillators peak at 1.0. Layer gains are relative, cue gains are in dB, and bus gains are fixed. The worst-case sum is bounded by the polyphony caps (tap 3, global 20) and limited by the compressor ceiling.
2. **Offline scenario renders.** `preview.html → "Offline loudness"` renders defined scenarios through the **real engine** in an `OfflineAudioContext` at 48 kHz. It applies the BS.1770-4 K-weighting biquads and gating (400 ms blocks, 75 % overlap, −70 LUFS absolute and −10 LU relative gates) and sums both channels, because the mono signal plays on L and R. That is a true ITU measurement of each scenario.
3. **Live approximation.** The preview's meter K-weights with two BiquadFilters (a +4 dB shelf at 1681 Hz and a 38 Hz high-pass), feeds an AnalyserNode of about 340 ms (momentary-like), and smooths over about 3 s for short-term. Treat it as ±1 LU.

**Measured (gains after the 2026-09-27 rebalance, preview.html offline render, 16 bars = sections A A2 B B2; v1 values in brackets):**

| Scenario | Integrated LUFS | Short-term max | Momentary max | Sample peak dBFS |
|---|---|---|---|---|
| Music only | **−20.1** [−18.1] | −19.8 | −19.1 | −9.3 |
| Music, frenzy layer, key +5 | −19.3 (+0.8 LU layer delta) [−17.3] | −18.8 | −17.7 | −6.7 |
| **Music + tap 4/s, 5 % crit (reference)** | **−16.2** [−16.2] | −11.1 | −9.7 | −2.9 |
| Music + tap 16/s, 10 % crit (worst case) | −14.2 [−14.5] | −9.9 | −9.4 | −2.4 |
| Tap 16/s alone, 10 % crit | −14.2 [−15.9] | −9.8 | −8.9 | −2.7 |
| Tap 16/s alone, Tap Frenzy sparkle | −14.3 [−16.0] | −9.9 | −9.4 | −2.8 |
| `evolveConfirm` alone (music is faded out) | — | — | −10.5 | −3.7 |
| `goldenCatchFrenzy` alone | — | — | −11.2 | −4.2 |

Reading the table:
- The reference condition still lands at −16.2 LUFS, inside ±0.5 LU of the −16 web target. The rebalance moved loudness from the bed to the feedback layer; it did not make the game louder overall.
- **Deviation, stated plainly (reversed from v1):** the music bed alone is now −20.1 LUFS, 1 LU *under* the studio's −19 LUFS short-term guideline for exploration music. v1 ran the bed 1 LU hot (−18.1) to keep the idle room alive. That put the tap about 6 LU under the bed in the ear's short-window terms (section 7) and fed the "there is no sound" perception. The feedback layer is the product; the bed yields.
- The worst case (autoclicker-rate 16/s with 10 % crits over music) is −14.2 LUFS with a −2.4 dBFS sample peak. That is inside the −16 to −14 web window and about 1.4 dB from a −1 dBTP line, which is thinner than v1's −3.3 dBFS but still held by the compressor's soft ceiling (section 4).
- Adding the frenzy layer costs +0.8 LU (the adaptive ceiling is ≤ 4 LU).
- The deeper rate compensation (6 dB, from 6/s to 16/s) holds a 16/s tap stream about 2 LU above the reference mix.

**Phone-speaker translation** (`preview.html → "Phone-speaker translation"`: each cue rendered alone through a 300 Hz Butterworth high-pass): every one of the 24 cues keeps **at least −3.5 dB** of its energy above 300 Hz (tap −0.2 dB, cantAfford −3.3, evolveConfirm −3.5). Every onset reaches half of the cue's peak within **12 ms** (tap 0.4 ms). The one exception is evolveConfirm, whose loudest moment is its downbeat at 720 ms; its pickup starts at 0 ms. Music bass translates through the 4-bit triangle's step harmonics and the 12.5 % "growl" layer, not through fundamentals below 300 Hz.

**Codec survivability:** not applicable. Nothing is encoded; the audio is synthesized at the output sample rate. The one sample-rate dependency, LFSR noise pitch, is removed by `playbackRate = clockHz / ctx.sampleRate`.

## 6. Settings and lifecycle mapping (summary; full rules in audio-cue-spec.md §5, U1 to U10)

- `settings.sfx` false → `busUser.sfx = busUser.ui = 0` (30 ms ramp). `settings.music` false → `busUser.music = 0`, the scheduler stops, and on iOS the audio session drops from `playback` to `ambient` (U7).
- Tab hidden → `ctx.suspend()`. Visible again, if the context has run before → `ctx.resume()`. A failed attempt is retried by the next gesture (U6).
- Every activation-capable gesture (`pointerdown`, `pointerup`, `touchend`, `click`, `keydown`) retries `ctx.resume()` until the state is `running`. The first transition to `running` flushes the one deferred cue (at most 180 ms old) and then emits `audioUnlock`, which starts the music (U2, U3, U8).

## 7. Rebalance, 2026-09-27 ("There is no sound")

**Why.** The primary cause of the report was the broken unlock (audio-cue-spec §5). A level check then showed the feedback layer was genuinely under-mixed as well. Peak-to-peak comparisons can't answer this: the tap and the music both peak at about −7 to −9 dBFS alone. And 400 ms momentary loudness under-reads an 81 ms tap by about 6 LU. So I measured on the time scale the ear integrates short sounds over.

**Metric** (`cues.json → mix.balance`; `preview.html → "Balance vs music bed"`): the cue's maximum K-weighted loudness in any **100 ms** window, minus the **median** 100 ms K-weighted loudness of the base music bed (sections A A2 B B2, 0 evolutions). Both are rendered through the full engine chain with `randomize.gainDb` off. **phone** = both renders through a 300 Hz Butterworth high-pass, the small-speaker design baseline. **full** = no filter (headphones). Positive values mean the cue stands above the bed. The tap's pitch pool moves its value by about ±0.5 LU from run to run.

| Cue | v1 phone / full (LU) | Now phone / full (LU) | Floor phone / full | Band ownership (why it can sit near the bed and still read) |
|---|---|---|---|---|
| `tap` | **−1.7 / −6.3** | **+3.9 / −0.6** | +3 / −1 | 880–2800 Hz tonal plus 5 kHz click; the music stays ≤ 587 Hz |
| `tapCrit` | +3.1 / −0.6 | +5.4 / +2.2 | +5 / +1 | Same band, longer (231 ms), so it stays above the tap |
| `buy` | +1.0 / −4.0 | +5.9 / +0.8 | +3 / −1 | 1–2.5 kHz |
| `uiClick` | −5.8 / −10.7 | +0.2 / −4.7 | −1 / −6 | 37 ms, 2–6 kHz; confirms a press and must not compete with gameplay |
| `uiToggleOn` | −6.9 / −11.9 | −0.9 / −5.9 | −3 / −9 | Settings and buy-mode ticks |

**Changes** (all in cues.json):

| Item | Before | After | Δ |
|---|---|---|---|
| `mix.buses.music.gainDb` | −10.5 dB | −12.5 dB | −2.0 dB |
| `mix.buses.ui.gainDb` | −2 dB | 0 dB | +2.0 dB |
| `cues.tap.gainDb` | −12 dB | −7.5 dB | +4.5 dB (+6.5 dB relative to the music) |
| `cues.tapCrit.gainDb` | −9 dB | −6.5 dB | +2.5 dB |
| `cues.buy.gainDb` | −11 dB | −8 dB | +3.0 dB |
| `cues.buyBulk.gainDb` | −10 dB | −8 dB | +2.0 dB |
| `cues.uiClick.gainDb` | −15 dB | −13 dB | +2.0 dB (+4.0 dB with the UI bus) |
| `cues.uiToggleOn` / `uiToggleOff` `.gainDb` | −15 dB | −13 dB | +2.0 dB (+4.0 dB with the UI bus) |
| `cues.panelOpen` / `panelClose` `.gainDb` | −16 dB | −14 dB | +2.0 dB (+4.0 dB with the UI bus) |
| `cues.tap.rateComp` | cut 4 dB from 8/s to 16/s | cut 6 dB from 6/s to 16/s | Keeps the hotter tap's 16/s stream within about 2 LU of the reference |
| master pre-gain, compressor, all other cues | — | unchanged | Goldens, evolve, headline and offline were already 2–10 LU over the bed |

**Compressor activity (the cost, measured).** A 20 Hz pilot tone at −34 dBFS was injected at the master input and its level tracked in 250 ms windows. At the reference condition (music plus taps at 4/s), gain reduction went from median −0.2 dB / 10th percentile −0.7 dB to **median −0.7 dB / 10th percentile −1.5 dB**. At 16/s it is median −0.7 / p10 −2.5 dB; music alone is unchanged (p10 −0.3 dB). Up to 1.5 dB of dip during active play is below the level where bus compression reads as pumping on a steady bed. The compressor is still a safety net, not a loudness tool. If on-device listening finds audible breathing at 4/s, the fallback is to trim `tap` by 1 dB (to −8.5), which puts phone at about +3, still at its floor.

**Unchanged by design:** phone-speaker translation (a gain change does not alter spectrum: tap keeps −0.2 dB above 300 Hz, onset 0.4 ms), no ducking on taps, crits, buys or UI (section 3), and mono.
