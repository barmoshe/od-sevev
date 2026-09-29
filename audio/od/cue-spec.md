# עוד סבב: cue-spec and mix-bus-topology

**Artifacts:** `cue-spec`, `mix-bus-topology`, `music-stem`, `sfx-asset`.
**Owner:** Audio Director. **Consumer:** Game Developer (the engine). **Date:** 2026-09-28, rev v1.2 and v1.3 on 2026-09-29.

> **v1.2 (2026-09-29), a client direction from Bar:** the music now alludes to HaTikva.
>
> **What changed:**
> - The shared mode moved from hijaz to HaTikva's minor: natural minor, with the leading tone raised at cadences.
> - The leitmotif is now the anthem's rise, 1-2-♭3-4-5, to the held 5, sung in the "עוד סבב" speech rhythm.
> - The fanfare's tags carry the ♭6-5 / ♭6-5 neighbour and the leap to the octave.
> - Each era's A-section opens with the contour. Washington gets it only at its cadences, in the minor.
>
> **What did not change:** every cue id, every stinger id, every file name pattern and the manifest schema. The integration can load v1.2 with no code change.
>
> **Behaviour changes for the engine:**
> - §2.6: coalition collapse no longer plays `motif`.
> - The keys' `mode` values in the manifest now read `minor` (D, E, G) and `mixolydian` (F).
> **v1.3 (2026-09-29), the Audio Director: leader select and the session-2 views.**
>
> **What changed:**
> - A cue coverage audit of every view and modal added in session 2 (§4.1). Each event now has a cue or is listed as silent on purpose (`Audio.SILENT`), and a test fails on any event the game sends that is neither.
> - New cues: `leaderPick`, `critReact` (whoosh, shout, no, land), `decline`, `merge`, `suspicionHot`, plus `chatPing`'s new `brawl` variant (§4, §4.2). No shipped file changed: each new cue is its own family, and `brawl` stays under the ping family's peak and burst.
> - A crit is keyed by the leader's react event (the manifest's `crits` table, spec §9.5). Bibi keeps `rabbitCrit`.
> - First sounds: `leaderPick` and `returnAway` play before the first-tap gate (§2.6).
> - Press day (every leader but Bibi) opens with the shutter, not the gavel (§2.3).
> - `gameReset` restarts the audio like a new game.
> - Canned Dubi contours for every leader's squawks.
> - The mix pass is in §3.1 and the payload in §7.
>
> **What did not change:** every v1.2 id, file, level and rule, the anthem guardrail (§6), and the music.

**Brief:** `sonic-brief` v1.1 (`artifacts/creative-pack/od-sevev/audio/sonic-brief.md`), with the resolutions in `engine/feasibility.md` (O-A1, O-A2, A3, A12, A13, A14, A18).

## Sources of truth

| What | Where | Who writes it |
|---|---|---|
| The score and the cue recipes | `audio/tools/compose_od.py` → `audio/od/music.json`, `audio/od/cues.json` | Audio Director |
| The renders | `tools/gen_od_sevev.gd` (run by `tools/audio.sh`) → `game/assets/audio/od/*.res` | the generator (a new file; `lib_dsp.gd` is unchanged) |
| **Every runtime number** | `game/assets/audio/od/od_manifest.json` | the generator |
| Behaviour (this page) | `audio/od/cue-spec.md` | Audio Director |

- **Where the numbers live:** this page gives behaviour only. File names, `play_db`, sample counts, bar lengths and loop lengths are all read from the manifest. If this page and the manifest disagree, **the manifest wins**.
- **The Monkey Bananas specs:** moved to `audio/legacy/` at the cut-over (2026-09-29): `cues.json`, `music.json`, `audio-cue-spec.md`, `mix-bus-topology.md`, `sonic-brief.md`, `preview.html` and their `tools/`. Nothing syncs or reads them any more.

---

## 1. Playback rules (every file)

**File format:**
- Every file is an `AudioStreamWAV` resource (QOA) with its loop built in.
- Music stems loop forward over (0, `loopSamples`]. Each stem carries one guard sample, as in ADR 0002.
- Cues and stingers are one-shots.
- Load a file with `load(OUT + file)`. No import step is needed.

**Volume and pitch:**
- The player's `volume_db` is the entry's `play_db`, plus any jitter the entry gives, plus fades and ducks.
- **Never** use `pitch_scale`. Every pitch is its own file.

**Keys:**
- **The key follows the track that is playing:**
  - D in Balfour;
  - E in the Knesset;
  - G in the Courthouse, and during court day in any era;
  - F in Washington.
- Taps, pings, Dubi and every keyed cue pick that key's files.

**Manifest file trees:**
- **Cues:** a cue's files are in `cues.<id>.files[<key>][<pitch>][<variant>]`.
  - `_` means "not used".
  - Examples: `files["D"]["s3"]["d25"]`, `files["_"]["_"]["g28"]`, `files["G"]["_"]["left"]`.
- **Stingers:** the files are in `stingers.<id>.files[<key>][<tags or _>]`, each as `{file, rate, musicalSamples}`.
  - `musicalSamples` is where the next music starts; the file rings a little past it.

**Latency (A14):**
- Issue `play()` on the trigger frame.
- The ear hears the web output buffer on top of that.
- The feel of a tap comes from the squash on the same frame.

## 2. Music

### 2.1 Tracks and layers
- **Stems:** each era has three stems, `music_<era>_L0|L1|L2.res`.
- **Playback:** the three stems play together, in one `AudioStreamSynchronized` per era, at the era's `play_db`.
- **The eras:**

  | Era | Key and mode | Tempo | Groove |
  |---|---|---|---|
  | balfour | D minor | 116 BPM | hora |
  | knesset | E minor | 132 BPM | maqsum |
  | courthouse | G minor | 88 BPM | half-time swing, 180 ms slapback baked in |
  | washington | F Mixolydian, with a minor turn at the cadences | 144 BPM | stride |

- **Form:** every era is 32 bars, A(1-8) A′(9-16) B(17-24) T(25-32). Bar 32 is the motif.
  - The motif rises 1-2-♭3-4 to a held 5 over V. That 5 resolves onto the i chord at the downbeat of the loop's own bar 1, so the seam is a cadence.
- **Measured seams:** every seam, on all 13 loops, has a 0.0000 step at the wrap.

**Layers.** Each layer switches on or off at the **next bar line** and ramps linearly over **one bar** (`barSamples`).

| Layer | Voices | On when |
|---|---|---|
| L0 | TRI bass, darbuka | always, while music plays |
| L1 | P2: stabs and comp in A/A′/T, **the complete B melody** | `sources_owned >= 1` (the first money source is bought); it then stays on |
| L2 | P1 lead | the last Magician tap was < 3000 ms ago |

**L2 is forced off:**
- during court day;
- during the last 3 s of an ultimatum;
- for the anti-fatigue mutes below.

### 2.2 Anti-fatigue (0 bytes, O-A1)
**The loop counter:**
- It counts completed passes of bar 32 → bar 1, and starts at 1.
- It resets when the track changes.

**Mute plan by loop, `(loop - 1) % 4`:**

| Loop | Mutes |
|---|---|
| 1 | none |
| 2 | L2 muted for bars 17-24 |
| 3 | none |
| 4 | L1 and L2 muted for bars 9-16 (the A′ breather: L0 only) |

**Timing:** the mutes use the normal bar-line fades, which start on the bar line before the muted bars.

**The loop-2 B-section:**
- In loop 2, P2 carries the B-section alone.
- P2's B is a complete eight-bar melody, measured at −22.3 to −23.5 LUFS against the bed's −20.

### 2.3 Era change and court day (O-A2)
**Era change:** use the fork's existing `set_era` path. At the next bar line, a 400 ms equal-power crossfade moves onto the **same bar** of the new track.

**Court day:**
1. **Gavel:** play `gavel`.
2. **Crossfade in:** at the next bar line, crossfade to `courthouse` with L2 forced off, and start `stinger_courtIn_G` on that same bar line.
   - While court day lasts, keyed cues use the G files.
3. **Exit:** at the next bar line, crossfade back to the era's track and play `courtOut` in the era's key.

**Court day inside the Courthouse era:** only the L2 mute, plus `courtIn` at the next bar line.

**Press day (v1.3):** every leader but Bibi has the press hazard skin (leader-select spec §5.6).
- Its day opens with `shutter` (a random variant) in place of `gavel`. The cameras are the press; a judge's gavel would be Bibi's trial.
- Everything after that is shared: the courthouse hush, `courtIn`, `gavelWeak` on a postponement, and `courtOut`.
- The skin comes from the leader's `kit.hazard.skin`. `event("courtSummons", "press" | "court")` overrides it.

**The court hush:** the courthouse sits 1 LU under the other eras (−18.3 against −17.3 LUFS). This is intended: the drop is the mock-solemn hush.

### 2.4 Election fanfare
**File:** `stingers.fanfare.files[<incoming key>][<tags>]`, where `tags = min(round_number - 1, 4)`.
- Round 1 has 0 tags.
- Each later round adds a half-bar P2 "ta-da", up to 4.

**Playback:**
1. **Start:** on the **election-confirm frame (f0)**, stop the bed (a 30 ms fade) and play the fanfare at `play_db`.
   - This accepts the animator's request: the darbuka roll is the bridge, so no bar-line wait.
2. **Restart:** after exactly `musicalSamples`, start the incoming era at **bar 1** (the fork's era-flourish hold).
   - The fanfare hangs on 5 over V, and bar 1's downbeat (i) is the resolution.
   - **Don't** start the music at the file's end: the file rings about 0.2 s past `musicalSamples` on purpose.

The fanfare replaces the bed: it ducks nothing and is not ducked.

### 2.5 The Outside drum line (Balfour only)
**Setup:**
- `music_balfour_outside.res` is a 2-bar loop on the **Outside** sub-bus (→ Music).
- The bus has `AudioEffectLowPassFilter` at 800 Hz and `AudioEffectPanner` at −0.3.
- It is started sample-locked to the Balfour stems. Add it to the same `AudioStreamSynchronized`: 2 bars divide the 32-bar loop exactly.

**Level:**
- The base level is `eras.balfour.outside.play_db`, which is 14 LU under L0 *after* the 800 Hz filter.
- It rises by up to +6 dB with the era's progress, 0..1.

**Pink Front (Saturday night, by the device clock):**
- The cutoff sweeps from 800 to 4000 Hz over 2 bars (exponential), with +8 dB.
- Tap-to-beat judges taps against `outside.judgeSamples`, the song-clock sample positions of beats 1 and 3 inside the 2-bar loop.

### 2.6 One-shot stingers
All the keyed stingers use the current key.

| Stinger | When | Bus |
|---|---|---|
| `motif` | **The first sound of the game:** the first Magician tap, the audio unlock (A15), plays it *instead of* `tap`. It sounds from t=0: in v1.2 the file starts on its pickup. Its `musicalSeconds` is 2.33 s in D and 3.07 s in G.<br>**Dubi's first squawk** ("אין כלום! אין כלום!") starts when `musicalSeconds` ends. It never plays over the motif, which is the anthem's statement (§6).<br>**Coalition collapse (changed in v1.2):** fade the music out over 1 bar, then **silence**, with no stinger. The music restarts at bar 1 on the next tap.<br>The motif now carries the anthem's contour. Using it as a loss sting would be the "fail sting" the guardrail forbids. | SFX-Critical |
| `milestone` | An order-of-magnitude milestone (the head, 5-1) | SFX-Critical |
| `dubiFlash` | A story-flash card opens (the head 5-1-5 on BLIP) | Voice |
| `trophy` | The "שלום בית בפריים" trophy: the shutter, then a BLIP "ta-da" (5-♭7-1'). **Never the anthem on Dubi's chip voice.** | UI |
| `courtIn` | §2.3 | SFX-Critical |

**First sounds (v1.3).** The leader picker comes before the first tap and replaces the title, so the pick is now the game's first gesture.
- **The flag:** a cue with `firstSound: true` in the manifest plays before the first-tap gate. Two cues have it:
  - `leaderPick`, the picker's commit;
  - `returnAway`, the return card's collect. After a reload the card comes before any tap, so v1.2's gate swallowed it.
- **The gate:** a first sound does **not** open the first-tap gate. The picker's browsing (tile presses, long-press) stays silent, and the first Magician tap still plays `motif`, the anthem's statement.
- **iOS:** the pick commits on touchend, which is the gesture that unlocks audio. While the context is still locked, a first sound is **held** (up to 5 s, like the motif) and plays on the unlock, where any other cue would be dropped after 180 ms (U8).
- **Why `leaderPick` is safe as the first sound:**
  - It starts on its first roll hit at t=0, with no silent lead-in.
  - It is ≤ 1 s (843 ms).
  - Its level is burst −15 LUFS: no louder than the motif and no startle. The heard true peak is −5.7 dBTP.
  - It has no sub-bass: its lowest note is the TRI 1 in octave 3, crushed, so a phone speaker plays its harmonics.
  - Its four key files are warmed in `_warm()`, before any gesture.
- **A quick first tap:** it may land while the pick is still sounding, and the motif then starts over it.
  - The pick's musical content ends 0.39 s + 0.22 s in.
  - From 0.6 s the tail is high-passed crash under −32 LUFS (burst). At 0.5 s it measures −19.2 LUFS.
  - So the anthem's statement stays clear.

## 3. mix-bus-topology

```
Master ── HardLimiter (ceiling -1.0 dB, pre-gain 0, release 0.1 s) - nothing else
 ├─ Music (0 dB, settings "מוזיקה")      ← stems, fanfare
 │   └─ Outside (0 dB) LPF 800 Hz → Panner -0.3
 ├─ SFX-Critical (0 dB, settings "צלילים") ← crit, suitcase, gavel, whistle, ultimatum, courtIn, motif, milestone
 │   └─ Suitcase (0 dB) Panner, set at spawn from the suitcase x (-0.4..+0.4)
 ├─ SFX-Frequent (0 dB, "צלילים")        ← tap, buy, stamp, coin, suitcaseMiss, gavelWeak, courtOut
 ├─ UI (0 dB, "צלילים")                  ← chatPing, uiClick, cantAfford, shutter, trophy
 └─ Voice (0 dB, "צלילים")               ← dubiSquawk, dubiBlip, dubiFlash
```

**Why the master chain changes:**
- **The request:** replace the fork's master chain (Amplify −1.7 dB, then a compressor at −14 dB 6:1 with +5.3 dB of makeup, then the limiter) with the **limiter alone**.
- **Why:**
  - Every `play_db` was calibrated offline with unity buses.
  - The v1 emulation chain adds about +3.6 dB below its threshold and compresses above it, which would move the mix off its measured −16 LUFS.
  - It would also pump the 5 Hz tap stream.

**Ducks.** Each cue lists its ducks in `cues.<id>.ducks`. They act on the Music bus volume and are scripted in the Audio autoload, as the fork already does.

| Source | Music duck | Attack / release |
|---|---|---|
| Voice (Dubi) | −6 dB | 30 / 250 ms |
| SFX-Critical, except `ultimatumTick`, `motif` and `courtIn` | −4 dB | 50 / 200 ms |
| Taps, UI | none | none; a 5 Hz stream would pump the music |

- **The fanfare:** replaces the bed rather than ducking it.
- **Overlapping ducks:** they don't add; the deepest duck wins.

**Settings (UX owns the placement).**
- **The toggles:**
  - "מוזיקה" drives the Music bus.
  - "צלילים" drives SFX-Critical, SFX-Frequent, UI and Voice.
- **The slider law:** the default slider position must equal 0 dB, so the calibration holds at the defaults.
  - For UX's "music at 60%", map `volume_db = linear_to_db(slider / slider_default)`.
  - The mix already puts the taps over the music. Tap bursts sit at −16.6 LUFS in their own 1.5-4 kHz slot, against music at −17.3 LUFS integrated.

**Measured result (60 s per era: three layers, 5 taps/s, a ping, a Dubi line and a suitcase):**
- **Loudness:**
  - −16.3 / −16.2 / −16.1 LUFS integrated in Balfour, the Knesset and Washington, on the −16 target.
  - −17.0 in the Courthouse, by design: the court hush.
- **True peak before the master:** −0.4 to +0.2 dBTP, from coincident tap and music transients. The −1 dB limiter takes them.
- **v1.2 full mix:** −16.3 / −16.2 / −16.1 LUFS in Balfour, the Knesset and Washington, and −16.9 in the Courthouse. True peak before the master is −0.7 to +0.3 dBTP. (The v1.1 figures above are kept as the record.)
- **Music alone, summed-stem sample peak:**
  - −0.47 to −1.62 dBFS in all four eras (v1.2).
  - The master limiter takes at most 0.5 dB off isolated transients.

### 3.1 Mix pass v1.3 (the new cues)

**Method:**
- Each new cue takes its target from the family it sits beside, so the mix is unchanged: the pick at the milestone's burst, a crit at the rabbit's, the chat actions at the chat's, and a warning at the quiet UI floor.
- `play_db` comes from the generator (K-weighted BS.1770, dual mono, capped by the bus ceiling).
- The heard values were re-measured independently on the `OD_AUDIO_PREVIEW` renders: 4× oversampled true peak, and the tail from the peak down to −60 dB.
- Ranges cover the four keys.

| Cue | Bus | Target | play_db | Burst (100 ms) | M-max (400 ms) | Heard sample / true peak | Length | Tail after the peak |
|---|---|---|---|---|---|---|---|---|
| `leaderPick` | SFX-Critical | burst −15 (= `milestone`) | −4.68 | −15.00 | −17.94 | −5.7 / −5.7 dBTP | 843 ms | 270-279 ms |
| `critReact` | SFX-Critical | burst −12 (= `rabbitCrit`) | −5.47 | −12.00 | −14.64 | −6.5 / −6.5 | 364-534 ms | 181-368 ms |
| `decline` | SFX-Frequent | burst −16 (= chat) | −5.11 | −16.00 | −19.47 | −6.1 / −6.0 | 264 ms | 108-250 ms |
| `merge` | SFX-Frequent | burst −16 (= chat) | −4.00 (ceiling) | −16.08 | −18.92 | −5.0 / −4.9 | 274 ms | 98-256 ms |
| `suspicionHot` | SFX-Frequent | burst −20 (near `cantAfford`'s −21) | −10.63 | −20.00 | −25.86 | −11.6 / −11.2 | 168 ms | 146 ms |
| `chatPing` `brawl` | UI (the ping family's level) | inherits −6.81 | −6.81 | −19.4 | −23.0 | −8.2 / −8.2 | 244 ms | 229 ms |

**Reference points:**
- `rabbitCrit` measures −12.0 burst and −13.2 M-max.
- The ping family is −16 burst, `motif` −15 momentary, and `cantAfford` −21 burst.

**Clipping:**
- No file clips.
- The loudest heard true peak of any new cue is −4.86 dBTP (`merge_G`), 0.14 dB of inter-sample over its −5 dBFS sample-peak ceiling and 3.9 dB under the −1 dB master limiter.
- The worst coincidence, a pick at its peak on a music peak ducked 4 dB, sums to +1.0 dBFS before the master. That is within the v1.2 full mix's measured −0.7 to +0.3 dBTP range of coincident transients, and the limiter takes it.

**Tails:**
- Every UI-bus cue ends by 0.4 s. `compose_od.py` now fails a UI cue that runs longer.
- `brawl` ends at 244 ms, the longest v1.2 ping at 244 ms.
- The only long tail is the pick's crash, 0.42 s of high-passed noise. It is the fanfare's own crash, shortened from 0.8 s.

**The brawl sits 3 dB under a demand ping.** Two half-gain voices keep the pair at one ping's peak, so the family's files and `play_db` do not move. It is also right by meaning: a brawl is the partners' business, not a demand on the player.

## 4. Cues

Levels, files and lengths are in the manifest. Bus and priority are repeated here for the voice allocator.

**Priority:**
- The range is 5 (never stolen) down to 1.
- When a cue's `poly` is full, steal by the `steal` rule: `oldest`, or `never` (drop the new one).

| id | Event (trigger intent is the designer's) | Bus / priority / poly | Variant rule |
|---|---|---|---|
| `tap` | Magician tap | SFX-Frequent / 2 / 4, steal oldest | **Pitch:** `s<n>` with n = streak index mod 8 (walk and wrap). The streak resets after 400 ms without a tap. This is the strict walk mode (A3), not `_scale_pick`'s random window.<br>**Variant:** `d25` / `d12` alternate per tap.<br>**Gain:** ±1.5 dB jitter. |
| `rabbitCrit` | a crit ("the rabbit") | SFX-Critical / 5 / 1, never | Round-robin `s120` → `s150` → `s180` |
| `suitcaseSpawn` | a suitcase appears | SFX-Critical / 4 / 1, on the Suitcase bus | Random `g25` / `g28` / `g31`. Set the pan at spawn. |
| `suitcaseCatch` | a catch | SFX-Critical / 4 / 1 | none |
| `suitcaseMiss` | a miss | SFX-Frequent / 1 / 1 | none |
| `chatPing` | a partner posts | UI / 3 / 1 | **Variant:** the partner id (`benGvir`, `smotrich`, `deri`, `goldknopf`, `gafni`, `levin`, `regev`, `gotliv`); anyone else plays `default`.<br>**Rate:** at most 1 per 700 ms. Pings inside that window coalesce into one `burst`.<br>**Dubi:** never while Dubi squawks or babbles. Queue the ping until 300 ms after Dubi stops.<br>**Leaving:** `left` = left the group. |
| `ultimatumTick` | each displayed second of an ultimatum | SFX-Critical / 3 / 1, **no duck** | **Variant:** `tick` / `tock` alternate.<br>**The last 3 s:** 2 per second, with L2 forced off. |
| `ultimatumZero` | the ultimatum hits 0 | SFX-Critical / 4 / 1 | none. It includes the "left the group" ping. **No alarm, ever.** |
| `gavel` | court day starts | SFX-Critical / 5 / 1, never | Random `a` / `b` / `c` |
| `gavelWeak` | a postponement is granted | SFX-Frequent / 2 / 1 | none |
| `courtOut` | court day ends (on the crossfade bar line) | SFX-Frequent / 2 / 1 | none; in the key being returned to |
| `stamp` | Herzog's desk: the request bounced | SFX-Frequent / 2 / 2 | `bell` on every 5th stamp. **Otherwise identical, deliberately.** |
| `transferWhistle` | Gotliv's transfer window | SFX-Critical / 4 / 1, never | Random `w26` / `w28` / `w30` |
| `shutter` | a photobomb | UI / 3 / 1 | Random `m1` / `p0` / `p1` |
| `dubiSquawk` | before Dubi speaks | Voice / 4 / 1 | `up` before a ticker headline, `down` before a canned squawk |
| `dubiBlip` | one syllable of Dubi's babble | Voice / 4 / 1 | **Pitch:** `<degree>_<octave>`, drawn from the mode's {1, 3, 4, 5, 7} × {5, 6}. The third is minor in D, E and G and major in F; the seventh is ♭7 in every key and seeded by the text.<br>**Rate:** 8 per second, one blip per displayed syllable (about 1 per 2 Hebrew letters). A final "!" steps up one degree.<br>**Cap:** 1.6 s. The ticker babbles on at most 1 headline per 20 s.<br>**Canned lines:** use `babbleContours`, and double the contour for a doubled line, with a 150 ms gap. |
| `returnAway` | the "while you were away" return | SFX-Critical / 3 / 1 | none |
| `buy` | a source or spin is bought | SFX-Frequent / 3 / 2 | `d25` / `d12` alternate |
| `cantAfford` | a buy is refused | UI / 1 / 1 | none |
| `uiClick` | any UI press | UI / 1 / 2 | none |
| `coin` | the settings "צ'ינג" preview, and any explicit payout burst | SFX-Frequent / 1 / 3 | `a` / `b` alternate. **At most 6 per event, never scaled by the amount** (the deadpan rule). |
| `leaderPick` (v1.3) | the picker's commit (and a re-pick inside the undo window) | SFX-Critical / 5 / 1, steal oldest, Music −4 dB | none. **A first sound** (§2.6). It is the fanfare's material cut to its arrival: the darbuka roll (roll2-roll4), the C#-D lift with P2 brass a sixth below, and the downbeat on 1 over i with a shortened crash. It resolves, and never states the rise. |
| `critReact` (v1.3) | a crit, for every leader but Bibi | SFX-Critical / 5 / 1, never, Music −4 dB | **Variant:** the react event (`whoosh`, `shout`, `no`, `land`; see the `crits` table). The event's transient comes first, then `rabbitCrit`'s head (5-1′-5′), the crit's signature. It fires on the event's strip frame. |
| `chatPing` `brawl` (v1.3) | a brawl opens (two members at each other; two rows frozen) | as `chatPing` | Two pings talk over each other: 1+♭2, ♭6+5, 1+♭2. It goes through the ping rate limit and waits for Dubi. |
| `decline` (v1.3) | Liberman's "לא יושב" pill | SFX-Frequent / 2 / 1 | none. "No. No.": two flat TRI staccatos, 1 then ♭7 below. It closes, where `cantAfford` hangs on the leading tone. |
| `merge` (v1.3) | Golan's "לאחד" pill | SFX-Frequent / 2 / 1 | none. Two P2 voices a third apart glide into one note (♭3↑4, 5↓4). Then the stapler, Golan's prop. |
| `suspicionHot` (v1.3) | the thermometer crosses 75 % upward | SFX-Frequent / 2 / 1, never, no duck | none. A dry TRI gulp (5↓4) and one sweat drip. At most once per live crossing, never on a restore. |

**Babble plan:**
- `babbleContours` replaces `Audio.babble_plan`'s F-pentatonic table for canned lines.
- For headlines, keep the fork's pure `babble_plan` for the timing. Map its pitch index into the 10-blip era bank of degrees × octaves.
- **v1.3:** every leader's four squawks (`kit.dubi.squawks` firsttap, buy, elect and miss) have a canned contour.
  - They use bank degrees only, so there is no 2 or ♭6, and no line leaps 5→5′ (the anthem's leap). `compose_od.py` checks both.
  - `Audio.squawk_text(id, kind)` returns the line, and `event("squawk", kind)` speaks the current leader's line. `event("babble", text)` still takes any text.

### 4.1 Coverage audit v1.3: every session-2 view and modal

**How to read it:**
- "Silent on purpose" events are in `Audio.SILENT`.
- `test_every_event_the_game_sends_has_a_cue_or_is_silent_on_purpose` scans `res://scripts` for every event the game sends. It fails on any event that is not handled, not a cue or stinger, and not in `SILENT`.
- **Hook** marks a one-line call this pass added to a view.

| View / moment | Event → sound | Decision |
|---|---|---|
| **Coalition chat (T3)**: open / close | `panelOpen` / `panelClose` → `uiClick` | covered (v1.2) |
| T3: a bubble lands (open) or its preview toast (closed) | `chatPing(partner)` | covered. New partners (lapid, bennett, …) play `default`, on purpose: D11 allows no leader motifs, and the minor sigh is a demand. |
| T3: ultimatum ticks / zero / left | `ultimatumTick`, `ultimatumZero`, `chatLeft` | covered |
| T3: pay / ceremony ribbon | `stamp` + `ultimatumPaid`; the ribbon start is `uiClick` | covered |
| T3: **the brawl** (the stage cloud, the preview toast, a brawl row landing in the open thread) | `chatBrawl` → `chatPing:brawl` (**hook**, 2 lines in `view_chat.gd`; it was `chatPing(a)`, the plain demand sigh) | **new cue** |
| T3: brawl cue tap / "צאו החוצה" | `uiClick` | covered; the rows unfreezing are visual |
| T3: **the pending chip** "{n} ממתינים ↑" | press → `uiClick`; the chip appearing is **silent on purpose** (every pending message already pinged) | covered |
| **The partner card** | `panelOpen`, pay → `stamp`, close → `panelClose` | covered |
| Liberman's decline pill / Golan's merge pill (being built) | `decline` / `merge` (manifest cue ids, accepted by name) | **new cues**; the developer calls them on commit |
| **Dossier (T4)** and **the pardon desk** | `panelOpen` / `panelClose` / `uiClick`; the pardon's impact frame → `stamp` (its home) | covered |
| **Thermometer**: the fill, the reveal, the bubbles | silent on purpose (continuous; the visual carries it; no slot at 5 taps/s) | silent |
| Thermometer crosses **75 %** (magnifier → gavel icon) | `suspicionHot` (**hook**, 2 lines in `view_thermo.gd`) | **new cue**: the warning had no sound, and the gavel came unannounced |
| Thermometer ≥ 95 % (boil); **the sweat** | silent on purpose (the boil and the drops are the visual twin; the gavel is next) | silent |
| **Court card** open / chip tap / close / testify / aide drop | `panelOpen` / `uiClick` / `panelClose`; a refused postponement → `cantAfford` | covered |
| Court: summons / start / end / postponement | `gavel` (Bibi) or `shutter` (the press, v1.3) → `courtIn`; `courtOut`; `gavelWeak` | covered, plus the press skin |
| **Dubi's news flash** | `storyCard` → `dubiFlash`, then `babble` (Dubi waits 600 ms); close → `panelClose` | covered |
| **The cottage cup** | `cottagePixel` silent on purpose (v1.2 null: its meaning is visual); the button → `uiClick` | silent |
| **Election modal** open / close / confirm | `evolveOpen` / `evolveClose` → `uiClick`; `electionConfirm` → the fanfare | covered |
| The leader walk-out / walk-in (the election transition, the pick) | `leaderSwap` silent on purpose (spec §9.5: optional; the fanfare bridges the walk-out and `leaderPick` lands the walk-in) | silent |
| **Return modal** | `panelOpen`; collect → `returnAway` (**v1.3: a first sound**, audible after a reload); close → `panelClose` | fixed: it was gated silent after every reload |
| **Reset modal**: cancel | `uiClick` + `panelClose` | covered |
| Reset modal: confirm (the wipe) | `panelClose` + `gameReset` (**hook**, 1 line in `main.gd`): the music fades over a bar and the gate closes | **new behaviour**; no sting, because a wipe is not a loss sting |
| **Share cards** (receipt / result): open, buttons, WhatsApp, close | `panelOpen` / `uiClick` / `panelClose`; the OS share sheet's result is **silent on purpose** (the sheet's status line and the OS carry it) | covered |
| **Spin-end toast** | `spinEnd` silent on purpose (§4 v1.2: a buff ending is a loss moment, and the brief has no fail stings; the toast carries it) | silent |
| Frenzy start / end, trick cue, ceremony end, milestone headline, affordable, reveal | silent on purpose (v1.2) | silent |
| **The leader picker** (being built): browsing, long-press | silent (the first-tap gate: the pick is the first sound) | silent |
| The picker's commit / a re-pick / undo | `leaderPick` (with the leader id) / `leaderPick` / `leaderUndo` silent | **new cue** |
| A crit, per leader | `tapCrit`, then the leader's react event → `crit_for(id)` | **new mapping** (§4.2) |

### 4.2 Leader select: the engine API (spec §9.5, §10)

| Call | What it does |
|---|---|
| `Audio.event("leaderPick", leader_id)` | Plays `leaderPick` (a first sound) and sets the leader. Call it on the commit, and again on a re-pick. |
| `Audio.set_leader(id)` | Sets the round's leader: on install, on load and after an undo. It warms that leader's crit files. Without a call, the Audio reads `current_scene.state.leader`, else the content's default (Bibi). |
| `Audio.crit_for(id) -> Dictionary` | `{leader, event, cue, variant, art, anim, delayMs}`. `variant` "roundRobin" means rabbitCrit's slide lengths in turn. `delayMs` is the tap → the event's strip frame. Every leader, from their content kit: |
| | ביבי: `rabbit` → `rabbitCrit` (250 ms) · בנט: `whoosh` → `critReact:whoosh` (167 ms) · בן גביר, סמוטריץ׳: `shout` → `critReact:shout` (71 ms) · ליברמן: `no` → `critReact:no` (0 ms) · אייזנקוט, דרעי, גולן: `land` → `critReact:land` (357 ms) |
| `Audio.event("tapCrit")` | As before: `tap` at f0. The leader's crit cue then plays at `delayMs` (a third in reduced motion) or at once on the strip event. |
| `Audio.event("heroEvent", ev)`, `Audio.event(ev)` | `ev` is the leader's react event (`rabbit`, `whoosh`, `shout`, `no` or `land`) on its frame. Another leader's event name is ignored. |
| `Audio.squawk_text(id, kind)` / `Audio.event("squawk", kind)` | Dubi's line for the leader (`firsttap`, `buy`, `elect` or `miss`). The first-tap line still waits for the motif (O-A3). |
| `Audio.event("courtSummons", "press")` | The press day's shutter. The leader's skin picks it anyway. |
| `Audio.event("gameReset")` | After a wipe. |
| `Audio.route(name)` | "handler", "cue:<id>", "stinger:<id>", "silent" or "unknown" (tests and the dev probe). |

**Eisenkot:** `straightTaps` puts his crit chance at 0, so `critReact:land` never fires as his crit. The react he plays once at tap 7 (`rule.copy.tap7`) is a joke about there being no magic. It stays silent on purpose: the tap cue only, with no crit head, because a ta-da would contradict the joke.

## 5. Markers and the animator's checklist (`motion/event-markers.md` §6)

**Where the markers are:**
- **Cues:** `cues.<id>.markers[<variant or _>]`, in seconds from the cue's start. These exist for `rabbitCrit`, `suitcaseCatch`, `ultimatumZero`, `gavel` and `transferWhistle`.
- **Fanfare:** `stingers.fanfare.files[<key>][<tags>].markers` = `{pickup, rollEnd, tagOnsets[], fanfareEnd}`.
- Visuals anchored to audio read these values; they never hard-code them.

**The checklist:**
1. **The tap cue** is `tap`. A crit's f0 **does** play `tap`, so the scale walk never skips a step.
2. **`rabbitCrit`** is one cue. It fires at `crit.rabbit` (+250 ms), or +83 ms in reduced motion. It is not split, and the strip's `sting` event (f5) has no cue: the slide and head land inside the wink.
3. **The fanfare** starts on confirm f0 (§2.4).
   - `rollEnd` = IMPACT (the motif downbeat and the crash).
   - `tagOnsets[]` and `fanfareEnd` are per key × tags.
4. **The Suitcase catch:** the reversed zipper is 120 ms, and the cha-ching lands at **130 ms** (`markers._.chaChing`). Put the burst there.
5. **The transfer whistle:** `w1/w2/w3` = **0 / 160 / 320 ms**, not the 0/180/360 defaults.
6. **Postponement impact (+90):** `gavelWeak` **alone**.
   - The stamp stays Herzog's pardon desk only.
   - That sameness is its joke, so it must not be spent elsewhere.
7. **The proposed cues:**

   | Proposed | Decision |
   |---|---|
   | `coinArrive` | Adopted as `coin` (a/b alternate), ≤ 6 per sequence and ≥ 60 ms apart: the deadpan rule |
   | `electionReady` | Adopted as the `milestone` stinger (in v1.2, the rise begins: 1-2-♭3 on P2 50%) |
   | Levin's bang / bang2 | Adopted as `gavelWeak` at `bang` (214 ms) and `bang2` (500 ms) |
   | zipWhoosh, land, seatsGain, printerFeed, receiptTear, cottagePixel, Bennett's whoosh, the brawl bed, the brawl exit click, hatHush | **null** |
   | the cast strip events `shout`, `huff`, `whoosh`, `step`, `land`, `sting` | **null** |

   **Why so many nulls:**
   - Each would add a sound whose meaning is already carried: by the gavel, the courtIn/courtOut pair, the stamp, the chat ping, or the visual twin.
   - At 5 taps per second the mix has no free slot for decoration. The brief's "polite in the pocket" pillar wins.
   **v1.3:** the strip events `whoosh`, `shout`, `no` and `land` sound only as a crit's react event (`critReact`, §4.2). Anywhere else (a walk-in, a non-crit react) they stay null. The brawl bed and the brawl exit click stay null: the brawl has its ping (`chatPing:brawl`), not a bed.
8. **Polyphony:** `tap` has poly 4 with steal-oldest, and fires once per registered tap. The files are 68 ms, so even at 16 taps/s at most 2 overlap.

## 6. HaTikva: where it is, and the guardrail (v1.2)

**Where the anthem's contour appears:**

| Place | What sounds |
|---|---|
| **Every loop's bar 32** and the `motif` stinger (the first tap) | The rise 1-2-♭3-4-5, in the "עוד סבב" rhythm. It lands on the held 5 over V, unresolved. |
| **The fanfare** | The rise on P1 with brass P2 a sixth below. Then one tag more per round: ♭6-5, ♭6-5, the octave leap 5-5′, ♭6′-5′. |
| **The A-sections** | **Balfour:** bars 1-4 in the hora's 3+3+2.<br>**Courthouse:** bars 1-4 in half time, legato and dead straight over the tiptoe bass.<br>**Knesset:** the plenum argues *over* the contour. P1's rise is cut off before its 5, P2 answers with the ♭6-5-♭6 neighbour, and in A′ they swap.<br>**Washington:** only at the cadences, in F minor (A bar 7: ♭6-5 / ♭6-5 over ♭VI; bar 32: the motif). |
| **`milestone`** | The rise begins: 1-2-♭3. |

**The guardrail, as enforced:**
- **Cap on verbatim contour:** `compose_od.py` checks each melodic line and fails any run of more than **10 consecutive anthem intervals**, which is the anthem's first 2 bars.
  - Balfour and the Courthouse leads sit exactly at 10.
  - Every other line is at 6 or fewer.
- **Articulation:** the contour is never on BLIP (Dubi) and never staccato or tiptoe.
  - `courtIn` is now a legato, solemn rise. The v1.1 staccato tiptoe version was dropped.
- **Loss moments:** the contour is never used as a fail or loss sting (see collapse, §2.6).
- **Pitch:** it is never bent or detuned. The lead's vibrato is the same 5.5 Hz ±15 cents delayed vibrato on every note, anthem or not.
- **Everything else stays:** no sirens, no bugle calls (the fanfare keeps a chromatic C#-D step and stepwise motion), and no other quoted tunes (8 incipits are checked).

**Keys and scales:**
- **The tap walk and Dubi's bank** follow the key's mode. That is D, E and G natural minor; the walk from degree 5 is 5 ♭6 ♭7 1′ 2′ ♭3′ 4′ 5′, so a streak of taps climbs the anthem's rise.
- **F stays Mixolydian,** so Washington's taps agree with its stride body.

## 7. Payload

**Totals (v1.2):**
- The whole `game/assets/audio/od/` folder comes to **10.87 MB** against the ~11.3 MB budget. The per-type breakdown is in `od_manifest.json` → `sizes`.
- Music: 8.81 MB.
- Stingers: 1.42 MB. This is smaller than v1.1 because the `motif` and `trophy` files no longer carry a silent lead-in bar.
- SFX: 0.59 MB.

**Totals (v1.3):**
- The folder is **11.06 MB** (11,645,654 bytes, +202,676 over v1.2) and still under the ~11.3 MB budget.
- The growth is SFX alone: 0.59 → 0.78 MB, from 36 new files:
  - `leaderPick` ×4;
  - `critReact` ×16 (4 events × 4 keys);
  - `decline`, `merge` and `suspicionHot`, ×4 each;
  - `chatPing` `brawl` ×4.
- Music and stingers are unchanged.
- **The web export:** `index.pck` grew from 18,327,576 to 18,535,096 bytes (+207,520, +1.1 %); `index.wasm` is unchanged.

**How it fits:**
- The courthouse stems render at 22,044 Hz, where a step is 5,010 samples.
- The stingers render at 22,050 Hz.
- These are the O-U1 payload levers from the feasibility resolution, pulled because the fanfares came to 1.5 MB, not the estimated 1 MB.
- Balfour and every SFX stay at about 32 kHz.

**The boot pack (O-U1):**
- Balfour's stems, the Outside loop, every SFX, and the D stingers are about 3.4 MB.
- The rest can go in the eras 2-4 pack.
