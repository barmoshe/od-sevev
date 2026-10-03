# 0009. The tap plays the song the era is playing

- Date: 2026-10-03
- Status: Accepted (Bar)
- Supersedes: [0004](0004-2026-09-30-tap-plays-hatikva.md) for the tap's melody (HaTikva stays as the fallback)

## Context

Since v1.5 (ADR 0004) every tap was the next note of HaTikva, in every era, over whatever the music
played. v1.9 gave each era two traditional songs (Hava Nagila, Hevenu Shalom Aleichem, Shalom Chaverim,
Ma'oz Tzur, Dayenu, Siman Tov). An explorer pass found five problems with the tap:

- the 400 ms streak reset meant a player tapping at about 1.5 taps/s only ever heard phrase openings;
- HaTikva in natural minor clashed with Washington's Mixolydian and Hava Nagila's F#;
- the music's lead played under the bell (−6 dB) for 3 s after every tap: two melodies at once;
- polyphony stole voices with a hard stop (a click at fast tapping), and a coin rang on every tap;
- the tap strip restarted at f1 on every tap, so above 7.5 taps/s it never reached its coins frame.

Bar asked: "Improve the tapping mechanism and music while tapping. Each tap is note." He picked
"the song the era is playing", plus the rhythm and feel fixes, a phrase bonus and a beat glow.

## Decision

- **The tap is the soloist.** Each era's `tapLine` (`audio/od/music.json`, copied to the manifest) is its
  loop's melody, note by note, with onsets and 2-bar phrases. Each tap plays the next note.
- **It follows the music, loosely:** inside a phrase, always the next note; at a phrase's end, a tap
  behind the music or more than a phrase ahead jumps to the phrase the music plays; after a 2.5 s
  pause the next tap joins the music's current note. Without music it runs on by itself.
- **The lead steps back:** L2 plays while the player rests and ramps out in 120 ms on a tap.
- **One bell, six roots:** rendered at C4, F#4, C5, F#5, C6 and F#6, played at `pitch_scale` (at most 3
  semitones). 6 files replace 36.
- **Feel:** 30 ms fades on stolen voices; plain-tap coins capped at 4/s; tap-strip merge on f1–f2.
- **Phrase bonus:** a phrase played whole pays `tap.phraseBonusMult` (3) taps' worth with a quiet
  sparkle (`phraseDone`), at most once per 1.5 phrases of music.
- **Beat glow:** `Audio.beat_phase()` drives a small brightness pulse on the leader (not in reduced motion).

## Consequences

- HaTikva is now the tap only where the music plays it (Balfour's A) and as the fallback melody.
  ADR 0004's respect rules for the anthem are unchanged; its streak and phrase rotation are retired.
- Audio payload 11.45 → 11.24 MB. A steady tapper earns about +10-25% on taps from the phrase bonus.
- Code: `compose_od.py` (`tap_line`, `check_tap_lines`, the bell roots, `phraseDone`),
  `gen_od_sevev.gd` (`tapLine`, `beatsPerBar`), `od_audio.gd` (`tap_line`, `tap_next`, `bell_root`),
  `audio.gd` (`_tap_note_play`, `phrase_done`, `beat_phase`, soft steal, coin cap), `Economy.phrase_bonus`,
  `big_banana.gd` (merge, glow). Tests: 610 passed.
