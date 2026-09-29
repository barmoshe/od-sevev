# sonic-brief — Monkey Bananas

Owner: Audio Director. Consumers: Game Developer (synth engine), Game Designer (cue moments), UX Designer (settings groups).
Companion files: [`cues.json`](cues.json) (SFX data), [`music.json`](music.json) (music data), [`mix-bus-topology.md`](mix-bus-topology.md), [`audio-cue-spec.md`](audio-cue-spec.md), [`preview.html`](preview.html) (audition page and reference synth).
Constraint: **zero audio files.** Every sound is synthesized at runtime by WebAudio from the data in this folder.

## 1. One-line identity

**"A 1989 cartridge found inside a banana."** A 4-voice, 2A03-shaped chiptune band (two pulse waves, a stepped triangle and LFSR noise) playing a swung jungle shuffle in F major, *very seriously*. The joke is that the music has the solemn swagger of a national anthem. The sounds are toys.

## 2. Palette (instrument lock): 7 timbres, each with one job

| # | Timbre (WebAudio recipe) | Role | Register | Visual analogue (art/sprites.ts) |
|---|---|---|---|---|
| 1 | **Pulse 25 %** (PeriodicWave, 64 harmonics) | Lead melody; the "voice" of the troop | C4–D5 (262–587 Hz) | The warm `Y`/`O` banana yellows: bright, reedy, the hero colour |
| 2 | **Pulse 12.5 %** (PeriodicWave) | Thin accompaniment: off-beat comp, frenzy arpeggio, sparkles, echoes | comp G3–A4; sparkle up to C7 | The `h`/`w` highlight pixels: narrow, glinting |
| 3 | **Square 50 %** (native) | UI ticks and power-up sweeps only | 1.3–1.8 kHz (UI) | The 3-px 9-slice button corners: hard and geometric |
| 4 | **Stepped triangle** (native triangle through a 4-bit staircase WaveShaper, "crush: 4") | Bass, kick drum, bongos, cue "thumps" | 78–311 Hz (+ step harmonics) | The single dark outline `k`: grounding, everywhere, never the focus |
| 5 | **Pure triangle** (no crush) | The tap "plink" and soft chimes | A5–C7 (880–2093 Hz) | The Big Banana's rounded shine |
| 6 | **LFSR noise, long mode** (15-bit, looped buffer, clock set by playbackRate) | Snare, hats, shaker, clicks, whooshes | band-passed per use | The dithered jungle foliage |
| 7 | **LFSR noise, short mode** ("noiseMetal", 93-step period) | Reserved: metallic hits; unused in v1 so it stays special | — | — |

**The bit-crush vibe comes from how sounds are built, not from a master effect.** The triangle is quantized to 16 levels (the real NES triangle is 4-bit). Noise is a genuine LFSR sequence with a lowered clock. Pulse widths are the 2A03's 12.5 / 25 / 50 % set. There is no crusher on the buses: a master crusher gates quiet tails and turns 16 taps/s into grit.

**May use:** vibrato only on notes longer than 200 ms (delayed 150–400 ms, as NES drivers did), arpeggio chords (rates of 8–36 Hz), pitch sweeps, and echo layers made from a delayed quieter copy.
**Voice budget:** music never uses more than 6 simultaneous voices (lead, bass, comp or arp, and three percussion). The limited palette is the art style.

## 3. No-go list (each with a reason)

| No-go | Why |
|---|---|
| Reverb or delay tails longer than 200 ms | At 16 taps/s tails pile into mush. They are also anachronistic for the NES idiom. |
| Sawtooth leads | The 2A03 has none. Saws are harsh at 2–4 kHz on phone speakers, the ear's most sensitive band. |
| Sub-bass below 60 Hz or sine subs | Phone speakers cannot reproduce it, and it eats limiter headroom that nobody hears. |
| Sampled or "realistic" monkey calls, jungle field recordings | The absurdity lives in the writing. Realism breaks the cartridge fiction and reads as stock. |
| Sad trombones or minor "fail" stings (can't-afford, despawn) | Idle games must never punish. "Not yet" is a shrug, not a failure. |
| Continuous drones or held pads longer than 1 s | An idle game is left open for hours, and drones are the first thing to fatigue. |
| Stereo width tricks (wideners, ping-pong) | The mix is mono-safe by design. Phones play one driver. |
| White-noise risers longer than 1 s | They read as EDM or "YouTube transition", which is off-era. |
| Audible limiter pumping | The master compressor is a safety net. Headroom is managed by gain staging (see `mix-bus-topology.md`). |

## 4. Motif lock: "Ba-NA-na"

```
         ba    NA        na
F major: C4  → A4 (long) → F4        (sol → mi, up a 6th → do, down a 3rd)
rhythm:  swung pickup | quarter | swung 8th
tracker (12 steps/bar):  prev bar pos 11 = C4 | A4 - - F4 - . ...
```
- **Function:** main theme and the "progress" leitmotif. It is the troop proudly announcing the only word they know.
- **Rationale:** the comic upward leap of a 6th, followed by a settle to the tonic, reads as "ta-daa, and that's final." It carries the referent *bananas achieved*.
- **Transformations:** (a) music bars 1, 5, 17, 21 and 29, stated plainly. (b) `evolveReady` states it as a fast arpeggio C–A–F–C. (c) The `evolveConfirm` fanfare augments it: C-C-C (triplet pickup) → A (long) → F → C6 (held over the F chord). (d) The tap pool is its pentatonic set (A C D F G), so every tap is a fragment of the theme.

## 5. Reference titles (take / reject)

| Reference | Take | Reject |
|---|---|---|
| *Kirby's Adventure* (NES 1993), "Vegetable Valley" | The bouncy triplet shuffle and cheerful pulse lead at a walking tempo | Its long-note pads |
| *Super Mario Bros. 3* (NES 1988), "Overworld 1" and the coin and power-up SFX | Short rising 2-note reward blips and quick arpeggio power-ups. The SFX speak in the key of the music | The frantic tempo of its athletic themes |
| *DuckTales* (NES 1989), "The Moon" | A lead hook you can hum after one listen, and a four-voice arrangement discipline | Its minor-key melancholy |
| *Wario Land: Super Mario Land 3* (Game Boy 1994) | Cheeky, self-important absurdity on a tiny palette. Comic "ook" slides | Its grungy, detuned GB noise |
| *Cookie Clicker* (web) | **Anti-reference.** We take its tap-anything-constantly scale | Its single identical click sample, which fatigues within a minute. Ours is pitch-pooled, streaked and rate-compensated |

## 6. Emotional register (2 axes)

```
            CEREMONIOUS (monkeys take this extremely seriously)
                 |  evolveConfirm (fanfare)
   evolveOpen    |          offlineCollect
                 |               evolveReady
CALM ------------+------------------------------- HYPE
   ambient idle  |   milestoneHeadline   goldenCatch*   tap streak at 16/s
   cantAfford    |   buy / upgradeBuy     frenzy music layer
            PLAYFUL
```
- Idle music sits at *playful-calm*: swung, mid-tempo (126 BPM), and loud enough to carry the room without competing.
- Only three beats reach *ceremonious-hype*: evolveReady, evolveConfirm and golden catches. Scarcity keeps them special.

## 7. Frequency slots (so SFX always stay on top)

| Slot | Band | Occupant |
|---|---|---|
| Bass | 78–311 Hz (+ step harmonics up to about 3 kHz) | Music bass, kick, bongos, cue thumps |
| Body / comp | 196–440 Hz | Music comp (post-evolve), cantAfford |
| Lead | 262–587 Hz | Music lead. **Never above D5** |
| Arp (frenzy only) | 262–932 Hz | Music frenzy arpeggio, quiet (12.5 % duty) |
| **Tap / SFX tonal** | **880–2 800 Hz** | tap plink, buy, crit stab, golden, UI. **Music never plays here** |
| Presence / air | 4–10 kHz | Noise clicks, hats, sparkles |

The music owns everything below about 900 Hz (lead top D5 = 587 Hz; the frenzy arp peaks at Bb5 = 932 Hz, quietly). The SFX own 880 Hz–2.8 kHz, the ear's most sensitive band, so feedback wins without any music ducking at the tap rate.

## 8. Differentiation test (how to falsify this brief)

Play 30 s of `preview.html` (music + "tap 4/s") against any generic asset-pack "8-bit adventure loop" plus click SFX. The studio clip is identifiable by two decisions: **(1) every tap is a note in the song's key, climbing with the streak.** **(2) The groove is a triplet shuffle with a stepped-triangle "oom-pah" bass, not straight 8ths.** If a reviewer cannot name both, the brief failed.
