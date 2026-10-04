# 0012. The tap follows the song that is playing (again); the coins step back

- Date: 2026-10-04
- Status: Accepted (Bar)
- Supersedes: [0010](0010-2026-10-03-the-tap-plays-hatikva-again.md) for the tap's melody; brings back
  [0009](0009-2026-10-03-the-tap-plays-the-eras-song.md)'s rule

## Context

With the music now trap (ADR 0011), every tap still played the next note of HaTikva over whatever the loop
played: Hava Nagila, Hevenu Shalom Aleichem, Shalom Chaverim, Ma'oz Tzur, Dayenu or Siman Tov. Bar, after
hearing it in the game: "the tapping notes should change according to the current song is playing and the
coin sounds should be more in the bg".

## Decision

- **Each tap is the next note of the song the era's loop is playing** (ADR 0009's rule, its code restored):
  `tapLine` is the loop's melody (the lead, or P2 in the Knesset's A′ hocket), with its onsets and 2-bar
  phrases. After a pause the next tap joins the note the music is on; at a phrase's end, a player who fell
  behind or ran more than a phrase ahead jumps to the phrase the music plays. HaTikva is still what the
  taps play in Balfour's A (its home), and the whole verified anthem stays as the cue's fallback melody.
- **Kept:** the v2.1 tap voice (marimba, mallet, thud), the six bell roots, the lead stepping back, the
  1 kHz slot while tapping, the phrase bonus on the song's phrases.
- **Coins** move 7 LU back (burst target −19 → −26 LUFS) and lose the 50% pulse for sines and a softer
  shimmer: a sparkle behind the tap's melody, not a second lead.

- **Compressed and side-chained, the song kept** (Bar, the same day: "the tapping and the music should be
  better compressed and side-chained and not completely mute the melody of the background music"): the lead
  steps back to −8 dB under the taps instead of going out; a compressor on the Music bus side-chained from
  the taps' bus (2.5:1, 10 ms / 300 ms) dips the bed about 3 dB under each tap; a compressor on the taps' bus
  evens the taps and the coins.

## Consequences

- ADR 0004's guardrail stands: the anthem plays straight wherever it plays.
- `tapLine` is `{steps, midi, phrases, phraseBars}` again; `OdAudio.song_step` / `note_at` / the
  follow-the-music branch of `tap_next` are back, with v1.10's tests.
