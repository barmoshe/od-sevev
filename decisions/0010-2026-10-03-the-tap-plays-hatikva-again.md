# 0010. The tap plays HaTikva again, the whole anthem from a verified score

- Date: 2026-10-03
- Status: Accepted (Bar)
- Supersedes: [0009](0009-2026-10-03-the-tap-plays-the-eras-song.md) for the tap's melody (its feel fixes stay)

## Context

ADR 0009 made each tap the next note of the song the era's music plays. Bar, the same day: "זה צריך
לנגן התקווה כשלוחצים על הדמות כל לחיצה תו" (it should play HaTikva when you tap the character,
every tap a note).

The tap's HaTikva (ADR 0004, 0005) had a verified first section, but its second section was written
from memory (v1.6) because no score was reachable then. Wikipedia is reachable now. The English
article's Hatikvah score (a LilyPond block, the same score anthem-scores 0.1.1 converted for section
A) has the whole anthem, and so does the Hebrew article's. The v1.6 section B was wrong: "עוד לא אבדה"
leaps to the octave (1 8 8 8), it is not 5 5 5 5.

## Decision

- **Every tap on the character is the next note of HaTikva, in every era**: the whole anthem, 105
  notes (section A and its repeat, the "עוד לא אבדה" lines, the last two lines twice as the volta
  says), from the English Wikipedia score. A script parses both Wikipedia LilyPond blocks and
  confirms the table: the English score note for note, and the Hebrew one for the first 77 notes.
  After that the Hebrew score sets the "וירושלים" lyric (one note fewer) and starts the repeat lower.
- **One key per era:** D (Balfour), E (Knesset), G (Courthouse), and D minor for Washington, the
  relative minor of its F, so the anthem's minor 3rd never sits against the stride's major 3rd.
- **It runs on by itself:** through pauses and key changes (court day continues on the next note,
  in G), wrapping at its end; a new round starts it from the top. It no longer follows the music's
  position.
- **Kept from 0009:** the bell from six roots at `pitch_scale`, the lead stepping back while the
  player taps, 30 ms steal fades, the coin cap, the tap-strip merge, the beat glow, and the phrase
  bonus, now on the anthem's ten 2-bar lines.

## Consequences

- ADR 0004's guardrail stands: the 2-bar cap is lifted for the tap only, the anthem is never bent,
  detuned or used as a loss sting.
- The fallback melody, `tap.melody` / `tap.phrases`, and the follow-the-music code (`song_step`,
  `note_at`, phrase steps) are removed; `tapLine` is `{midi, phrases, phraseBars}`.
- Payload unchanged. Tests: 611 passed.
