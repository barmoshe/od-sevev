# 0011. The music goes trap: the same tunes on an 808, a trap kit and a flute

- Date: 2026-10-04
- Status: Accepted (Bar)
- Supersedes: the chip voicing of the music in [0002](0002-2026-09-28-audio-offline-generator.md) and
  [0003](0003-2026-09-28-era-music-and-stingers.md) (their render pipeline, stems, keys and form stay)

## Context

Every music voice was a chip emulation: pulse-wave leads and stabs, a 4-bit crushed triangle bass, an
LFSR-noise darbuka. Bar: "Let's reinvent the music style of this game to be more like less 8-bit and more
trap hip-hop." Asked how far to go, he chose: keep the tunes (HaTikva and the six traditional songs, v1.9)
over a trap beat; restyle the era loops and the musical stingers, not the SFX or Dubi's voice; keep the
tempos (the Animator's markers, the beat glow and the Outside judge are timed to them).

## Decision

- **The voices change, the notes do not.** Melodies, chords, keys, tempos, the 32-bar A/A′/B/T form, the
  bar-32 motif and the tap's HaTikva are as v1.11 left them; `check_music`, `check_tunes` and the anthem
  guardrail pass unchanged (the anthem's home is legato on the flute).
- **The palette** (`compose_od.py` `TRAP`): a driven-sine 808 with a pitch punch, slides and a knock for
  phone speakers; kick, clap + snare, ghost snares, rim and the darbuka tek as a ghost perc; white-noise
  hats with rolls on their own 24-steps-a-beat grid; a breathy flute lead, a pluck, dark bells, soft keys.
- **The layers keep their meaning:** L0 = 808 + kit + hats (always on), L1 = keys + bells + counter-line
  (from the first source), L2 = the lead (while the taps rest). L0 and L2 sit level, L1 5-6 LU under.
- **Each era its own trap:** Balfour melodic (clap on 3), Knesset drill-leaning, Courthouse slow and swung
  (claps on 2 and 4 on its triplet grid), Washington showbiz at 144.
- **Stingers:** the motif on the flute, the fanfare's darbuka roll becomes an accelerating snare roll (same
  markers), courtIn on the keys, milestone on the bells. Trophy, dubiFlash and every SFX cue stay chip.
- **Tools:** `lib_dsp.gd` gains an optional `drive` (tanh saturation; absent everywhere else, so the SFX
  render byte-identical); `gen_od_sevev.gd` lets a channel carry its own `stepsPerBeat` and `slapback`.

## v2.1, the same day: real samples, the sub, the mix and master, in the game

Bar, after the first drafts: "חסר לי סאבים מגניבים" (the subs are missing), "research mixing and mastering
of trap and drill", "download free CC0 drum one-shots", "improve the mix and master", "test it in the game,
integrate it dynamically, mix and master it together with the SFX".

- **CC0 one-shots** (`audio/od/samples/`, `SOURCES.md`): 8 from Freesound (each one's licence page checked:
  CC0 1.0) and 3 from Sonic Pi's sample folder (all CC0). The kick, clap, snare, hats, rim, snap, tabla.
  `lib_dsp.gd` gains a sample player (`wave: "sample"`, Hermite interpolation) that can be tuned
  (`rootHz`): the playback rate follows the note and the glide.
- **The 808:** a real 808 sample (KALPC, root C2; the Knesset's distorted drill 808, root C1) tuned to every
  note, with legato glides from the previous note (`808u<n>` / `808d<n>`, 110 ms, the 80-150 ms the guides
  give) and a driven-sine band above 140 Hz under it, so the bass line carries on a phone speaker.
- **Drill in the Knesset:** the snare on 3, shifted to 4 in the next bar; tresillo hats (3+3+2 at
  100/87/52 velocity); the 808 climbs the octave on the last two 8ths.
- **The mix** (`gen_od_sevev.gd`): kit velocities, the 808 sidechained 5 dB under the kick, a Freeverb room
  per layer (sends high-passed at 250 Hz), a slow compressor evening the 808 notes, channel EQs (the flute
  and keys dipped at 1 kHz, the snares given presence), and a stem master per layer: EQ (RBJ peaking and
  shelves), glue compression, a soft clipper. Balanced by measuring each channel's RMS and the octave bands
  against a trap reference curve: every band 63 Hz-8 kHz now within about 4 dB of it.
- **In the game** (`tools/mix_session.gd`, Movie Maker through the real Audio autoload and buses): music
  alone -18.0, SFX alone -18.6 LUFS. The music target moves -19.3 -> -20.5 LUFS so the bell and the coins sit
  on top; the limiter ceiling -1.0 -> -1.5 dB (the true peak was -0.9 dBTP); the master HPF 35 -> 28 Hz
  and the Music bus's 10 kHz cut removed (the 808 and the hats). Two dynamic moves in `audio.gd`: a 3 dB
  dip at 1 kHz on the Music bus while the player taps (the HaTikva bell's slot), and a low-pass that closes
  the music in an ultimatum's last 3 s and opens it when paid.

- **The tap** leaves the chip too (Bar: "improve the tapping sound effect"): a soft mallet tick, a gentle
  low thud and a marimba / kalimba tone with a pluck's fall into pitch, shorter (0.42 s), on the same six
  roots and the same HaTikva line.

## Consequences

- No manifest-schema or marker change; the payload is unchanged (music 8.81 MB, the folder 11.28 MB).
  The runtime changes are v2.1's two dynamic moves and the bus layout (HPF, EQ, tension low-pass, ceiling).
- The other SFX (UI blips, Dubi, rewards) are still 8-bit. Bringing them in line is a separate step if
  Bar wants it.
- The sub-bass under 100 Hz is lost on a phone speaker; the 808's drive and knock carry its pitch there.
