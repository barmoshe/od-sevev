# 0003. Era music, v2 stingers, CHIP's babble and ambience beds (phase 9 audio)

- Date: 2026-09-28
- Status: Accepted

## Context

v2 adds four eras by evolution count (jungle 0-1, village 2-3, city 4-5, orbit 6+, from
`design/content.json` eras), story cards read by CHIP the news anchor after each Evolve,
trophies, per-tier milestones and perks. Phase 4 (ADR 0002) left the music as one song and
gave `achievement`, `milestone` and `perkBuy` stand-in v1 cues. Phase 9 asks for one
arrangement per era sharing the v1 motifs, stingers for the v2 events, a procedural voice for
CHIP, optional ambience, all through the same offline generator, deterministic, and inside a
music budget of 20 MB.

## Decision

- **Era arrangements are code over music.json, not new specs.** `tools/gen_music.gd`
  `_arrange()` takes a deep copy of the v1 song and re-orchestrates it: same 126 BPM, same
  32-bar form (so every stem is still 1,920,000 samples, 60.952 s, and loops the same way), same
  melody, chord chart and layer model (base, evolved, frenzy), new instruments and some parts
  rewritten from `form.chords`:
  - **village**: warm. A marimba lead (sine plus a two-octave triangle partial and a mallet
    click), a round uncrushed triangle bass, plucked off-beat chords (a lowpass sweep), and a
    soft kit (a gentler kick, a woodblock rim on the backbeat, shaker for the hats).
  - **city**: a bit of funk. A new octave-popping bass line from the chords (root, octave pops,
    fifth, a flat-seven pickup) on a filtered "slap" voice, a tight closed hat on every empty
    triplet, a staccato filtered clav lead, bandpassed chord stabs.
  - **orbit**: spacey. A new pad channel holding each bar's chord (slow attack, long release,
    detuned air), the melody as an octave arpeggio lead with a one-beat echo, a sub bass that
    holds the root, a half-time kit (kick on 1, soft snare on 3, a metallic shimmer every other
    bar), glassy sine off-beats with an echo, and sine blips for the frenzy percussion.
  - **jungle** is the v1 song unchanged (`main`, the same bytes as phase 4).
- **One key per later era.** Four eras x three layers x four keys would be about 27 MB. The
  jungle keeps the v1 key lift on every Evolve (all four keys); village, city and orbit are
  rendered in one key each, chosen from the keys the effects already have: village +4, city +5,
  orbit 0. An era arrival therefore climbs (+2 in the jungle, +4, +5) and orbit floats back to
  the home key (v1's "the monkeys forget" reset, now once, in space). The runtime plays the
  taps and every followsKey cue in the key that is actually playing, so they stay in tune.
- **Levels.** Each track is peak-normalised on its own; its `trim_db` also carries `match_db`,
  which brings its base stem to the RMS of the jungle base stem (clamped to +/-6 dB), so an era
  change does not jump in level.
- **Runtime era API.** `set_era(era_id, at_once = false)`: silent music applies at once (the
  next start plays the era); a playing song crossfades (400 ms, equal power) at the next bar
  line onto the same bar of the new track, using a second music player. `set_evolutions(n)`
  now also picks the era (content.json `fromEvolutions`, the same rule as `Story.era_for`), so
  the controller's existing calls already switch eras. `event("era", era_id)` switches, plays
  the arrival flourish in the new era's key and holds a pending music (re)start for the
  flourish's 2 bars, so the flourish plays as the new song's intro (bar 1 then starts with a
  30 ms fade instead of the 300 ms restart fade).
- **Stingers** live in `game/assets/audio/cues_v2.json`, in the cues.json schema, merged over
  it by `Audio.load_cues()` in both the generator and the runtime (audio/cues.json stays the v1
  spec). All follow the music key and sit under the tap level (tap -7.5 dB): achievement
  -12 dB (square fanfare C-E-G then a held C with vibrato), milestone -13 dB (a two-step level
  up), perkBuy -11 dB (a thumb pop, then a B5-E6 coin with a bell partial), storyCard -12 dB
  (swoosh, pickup, stab over a timpani, teletype ticks), era -10 dB (2 bars: a triplet climb
  over a snare swell, then a crash and a held F chord). The stand-in aliases remain only as a
  fallback when cues_v2.json is missing. A storyCard during the era flourish is skipped (the
  flourish already announces).
- **CHIP's babble** is a bank of 24 pre-rendered blips (12 pitches of the F major pentatonic
  from A3 x 2 vowel colours, each a square wave summed raw and through two formant bandpasses:
  "o" 650/1100 Hz, "i" 330/2300 Hz). `event("babble", text)` schedules one blip per letter or
  digit at 14 per second (spaces a silent slot, commas two, sentence ends three), pitched from
  the character code (vowels at indices 7-9, consonants 2-6) plus an arch per sentence (+1 in
  the middle, -1 at the end, +2 at the tail of a question). The plan is a pure static function
  (`Audio.babble_plan`), so it is deterministic and testable. It stops at the end of the text
  or on `stop_babble()`, ducks the music 4 dB and the era flourish 6 dB while it talks, waits
  for a story sting that started under 600 ms ago, pauses with the app and skips blips a frame
  hitch made late instead of bunching them.
- **Ambience beds**: a 16 s loop per era (jungle wind, bird chirps and insect trills; village
  wind, distant chatter blips and wood knocks; city mains hum, a swelling traffic bed, passing
  cars and horns; orbit a swelling F drone, slow high sine tones and filtered noise sweeps),
  22,050 Hz QOA, `amb_<era>.res`. They play on the Music bus (so the music toggle and volume
  drive them), 12 dB under the jungle base stem's RMS, start with the song and crossfade over
  2 s when the era changes. No new bus: the Music bus already carries the toggle, the volume and
  the right level.
- **Tooling.** `tools/audio.sh` now fails when a generator fails or prints a script error (it
  used to hide both behind `| tail`), and `--check` covers the beds too.

## Sizes

| Output | Files | In the repo | In the build |
|---|---|---|---|
| Effects (`sfx_*.wav`, stingers and babble included) | 330 | 7.53 MB of WAV | about 1.7 MB of QOA |
| Music (`music_*.res`) | 21 | 15.57 MB | 15.57 MB (already QOA) |
| Ambience (`amb_*.res`) | 4 | 0.55 MB | 0.55 MB |

Music plus ambience is 16.1 MB, under the 20 MB budget. `tools/audio.sh` takes about 3
minutes (the orbit pads and echoes are the slowest render) and `--check` writes identical
bytes twice.

## What the controller has to call

- Nothing new for the era music itself: `set_evolutions(n)` at boot and at the Evolve seam
  already switches eras. `set_era(id)` is there for anything that wants to force one.
- `event("era", era_id)` once when an Evolve lands in a new era, at `evolveTransitionEnd`
  (after it) or at the seam: the flourish then plays and the new song starts after it.
- `event("storyCard")` when CHIP's card opens, then `event("babble", text)` with the card's
  text (the babble waits for the sting on its own); `stop_babble()` when the card closes or is
  skipped.
- `achievement`, `milestone` and `perkBuy` keep their names and now play their own stingers.

## Consequences and known gaps

- **Not heard yet.** Everything was verified headless (dummy driver: files, loops, bookkeeping,
  switch timing). The arrangements were designed on paper and checked by level (RMS, peak),
  not by ear; the village marimba and the orbit pad level are the most likely to need a pass.
- **No key lift inside the later eras.** Evolves 3, 5 and 7+ no longer lift the key; the lift
  now happens per era. Adding the lift back costs about 2.2 MB per era per key.
- **One flourish for every era.** The era stinger is the same 2 bars (in the new era's key) for
  all eras, not orchestrated per era.
- **Babble pitch ignores the key.** CHIP's pentatonic is F major; in other keys a blip can rub
  against the music, which reads as speech rather than melody at 14 per second.
- **Live era crossfade is frame-timed.** The switch lands on the frame after the bar line (up
  to about 16 ms late) and the new player starts at the old one's position, which can differ
  by one mix block on a real driver.
- **Ambience loops are short (16 s)**; a patient ear can hear the birds repeat.
