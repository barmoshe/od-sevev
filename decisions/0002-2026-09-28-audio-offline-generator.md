# 0002. Audio is rendered offline from the v1 specs; music ships as QOA stem resources

- Date: 2026-09-28
- Status: Accepted

## Context

v1 synthesised every sound live in Web Audio (`src/audio/chip.ts`, `engine.ts`): oscillators,
LFSR noise, a crush WaveShaper, biquads and AudioParam envelopes, driven by
`audio/cues.json` and `audio/music.json`. ADR 0001 kept that procedural identity but moved the
synthesis to an offline generator, because Godot has no Web Audio graph and live GDScript
synthesis would cost frames on phones.

The runtime has to reproduce what the spec asks for on top of the sound itself: pitch per
streak step and per music key, three adaptive music layers that fade in on the beat and out on
the bar, a key lift after every Evolve, ducking, and the anti-fatigue brief of phase 4
(variants, tap gain jitter, a 4-voice tap cap, a crit combo). It also has to be safe before
the web audio unlock and under the dummy driver of the headless tests.

## Decision

- **One DSP library, two generators.** `tools/lib_dsp.gd` emulates the v1 chip sample by
  sample (band-limited wavetables, the 15-bit LFSR, crush before the envelope, Web Audio biquad
  formulas, the exponential envelope with its 0.0001 floor). `tools/gen_audio.gd` renders every
  cue, `tools/gen_music.gd` renders the song. Both read the JSON specs, so no number is copied
  by hand. `tools/audio.sh` runs both and imports; `tools/audio.sh --check` runs everything twice
  and compares every file with shasum.
- **Effects: one WAV per reachable pitch.** Pitch never uses `pitch_scale` (it would change
  the length and move the fixed-pitch thumps and noise). Each pitch a cue can be asked for is its
  own file `sfx_<cue>_sNN.wav` (every music key for followsKey cues, every scale step the streak
  and the crit combo reach), fast cues get three variants, and the Tap Frenzy sparkle tap is its
  own set (`sfx_tap_fz_*`). Files are 44.1 kHz mono 16-bit, peak-normalised per cue to -1 dBFS;
  `sfx_manifest.json` stores the trim the runtime adds back. They import as QOA one-shots.
- **Music: stems as QOA resources, not WAV imports.** The song renders at **31,500 Hz**, where
  one step (an 8th-note triplet at 126 BPM) is exactly 5,000 samples, so the 32-bar loop is
  exactly 1,920,000 samples with no drift. It is split into the three adaptive layers (drums
  mixed into base) for each of the four keys (0, +2, +4, +5), twelve stems. Each stem is an
  `AudioStreamWAV` built with `load_from_buffer` (QOA, forward loop 0 to 1,920,000 with a guard
  sample) and saved as `music_<layer>_k<key>.res` with a UID pinned by `ResourceSaver.set_uid`,
  so the bytes are deterministic. The runtime plays one `AudioStreamSynchronized` per key and
  crossfades its three stream volumes.
  - Why `.res` and not imported WAVs: the loop points and the compression travel inside the
    file instead of in hand-edited `.import` files, the 16-bit masters never enter the repo
    (about 46 MB), and a stem is loadable the moment the generator writes it.
  - Why QOA: about 3.2 bits per sample, decoded by the engine on every platform, with loop
    support; the lossy step is inaudible on 8-bit-style material.
  - Why 31.5 kHz: sample-exact steps, and about 29% smaller than 44.1 kHz. The music has no content
    that needs more than 15.75 kHz except the air of the hi-hats.
- **Buses.** `default_bus_layout.tres`: Master (Amplify -1.7 dB as the v1 pre-gain, a
  compressor at -14 dB 6:1, 2 ms / 200 ms with +5.3 dB makeup standing in for Web Audio's
  automatic makeup, then a -1 dB hard limiter) fed by Music (-12.5 dB), SFX and UI (0 dB).
- **Runtime.** The `Audio` autoload (`game/scripts/autoload/audio.gd`) takes named events only,
  with `event(name, arg)`, and follows chip.ts for polyphony, steal, cooldown, priority, the
  scale-quantised tap pitch, rate compensation, ducks and the music commands. Its bookkeeping
  runs on the clock, so it is testable under the dummy driver. Unknown event names are ignored.
  Until phase 9 adds their own sounds, the v2 events play stand-ins: `achievement` plays the
  milestone headline, `perkBuy` the upgrade buy, `milestone` the producer reveal.

## Sizes

| Output | Files | In the repo | In the build |
|---|---|---|---|
| Effects (`sfx_*.wav`) | 286 | 5.17 MB of WAV | about 1.2 MB of QOA |
| Music (`music_*.res`) | 12 | 8.90 MB | 8.90 MB (already QOA) |

`tools/audio.sh` takes about 40 s (4 s for the effects, 28 s for the music) and a `--check`
run writes identical bytes twice.

## Consequences and known gaps vs v1

- **Compressor knee.** Godot's compressor has no knee and a fixed makeup gain, so the master
  curve matches v1 below threshold (+3.6 dB net) but is about 3 dB lower than v1 for sums near
  0 dBFS (v1's soft ceiling sat around -3.7 dBFS; this chain gives about -6.7 dBFS, then the
  limiter). Rarely reached, since the bus levels keep normal play under the threshold.
- **Per-frame layer fades.** v1 ramped a GainNode sample-accurately at the quantised beat or
  bar. The runtime computes the same beat or bar from the song clock but moves the stream
  volumes once per frame (about 16 ms steps), so fades start up to one frame late and step in
  frame-sized increments.
- **First-loop pickup tail.** Notes ringing past bar 32 are wrapped onto bar 1 so the loop is
  seamless. The very first bar 1 after a (re)start therefore carries the faint tail of the bar 32
  pickup, which v1's scheduler did not play on its first pass.
- **Stems keep every note.** v1 stopped scheduling a layer's notes at the fade-out boundary;
  the stems always contain them and rely on the 200 ms fade to cut the tails. Audibly the same.
- **Music above 15.75 kHz is gone** (31.5 kHz render): only the hats lose some air.
- **Key changes need their own stems.** A fifth key or a new era track means another set of
  stems (about 2.2 MB per key); phase 9's era tracks go into `music_manifest.json` next to
  `main`.
- **UIDs of new effect files** come from the first import and are random; re-runs keep them,
  so determinism holds from the second run on.
- Verified headless only (dummy driver: the stems decode and reach the Music bus meter). Not
  yet heard on a phone or in a web build.
