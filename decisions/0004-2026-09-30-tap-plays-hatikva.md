# 0004. The tap plays HaTikva, one note per tap

- Date: 2026-09-30
- Status: Accepted (Bar)

## Context

Since v1.2 the music alludes to HaTikva under a binding guardrail (sonic brief v1.2, cue-spec §6):
at most about 2 bars of verbatim contour in one place, never on a comic or BLIP voice, never staccato,
never a loss sting. The tap walked 8 steps of the key's scale on a short pulse blip.

Bar asked for every tap on a character to be the next note of HaTikva, in sequence: the whole melody
on a respectful voice, in phrases of 4 or 8 bars, a different phrase each time, restarting after a pause.

## Decision

- **The tap is HaTikva.** `audio/od/cues.json` `tap` carries `melody` (one pitch key per tap, semitones
  above the key's root) and `phrases` (the note indexes a streak may open on). The generator renders the
  new pitch type `semis` in every key as natural minor (F included: the anthem is never re-moded).
- **The voice is a bell,** played straight: the cloth puff, then a sine with its octave and twelfth,
  0.55 s decay, no pitch bend, no detune. It replaces the pulse blip on the tap only.
- **Streaks and phrases:** taps under 400 ms apart walk on through the melody and wrap; after a pause the
  next streak opens the next phrase; an election starts again at phrase 0. The first tap of a save still
  plays the motif.
- **The guardrail's 2-bar cap is lifted for the tap** (Bar's call). Everything else in it stands.
- **Source:** bars 1-4 ("כל עוד בלבב פנימה / נפש יהודי הומיה") from the Hatikvah score on English
  Wikipedia (rev 1375885586, CC BY-SA 4.0), via the npm package anthem-scores 0.1.1 (`anthems/IL.json`).
  The second section ("עוד לא אבדה...") was not reachable from a verified source and is not shipped; it
  goes into `TAP_ANTHEM` in `audio/tools/compose_od.py` only from a verified score, with its phrase starts.
  `compose_od.py` checks that the melody opens with the anthem's first two bars.

## Consequences

- 32 tap files (8 pitches x 4 keys, one variant) replace 64; the audio folder is 11.23 MB (budget 11.3).
- `tap.poly` 6 (the bell rings longer than the blip). `OdAudio.tap_melody`, `tap_phrases`, `melody_step`;
  the walk stays as the fallback when a manifest has no melody. Tests: 439 passed.
