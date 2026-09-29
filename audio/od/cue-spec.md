# עוד סבב: cue-spec and mix-bus-topology

**Artifacts:** `cue-spec`, `mix-bus-topology`, `music-stem`, `sfx-asset`.
**Owner:** Audio Director. **Consumer:** Game Developer (the engine). **Date:** 2026-09-28, rev v1.2 on 2026-09-29.

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

**Babble plan:**
- `babbleContours` replaces `Audio.babble_plan`'s F-pentatonic table for canned lines.
- For headlines, keep the fork's pure `babble_plan` for the timing. Map its pitch index into the 10-blip era bank of degrees × octaves.

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

**How it fits:**
- The courthouse stems render at 22,044 Hz, where a step is 5,010 samples.
- The stingers render at 22,050 Hz.
- These are the O-U1 payload levers from the feasibility resolution, pulled because the fanfares came to 1.5 MB, not the estimated 1 MB.
- Balfour and every SFX stay at about 32 kHz.

**The boot pack (O-U1):**
- Balfour's stems, the Outside loop, every SFX, and the D stingers are about 3.4 MB.
- The rest can go in the eras 2-4 pack.
