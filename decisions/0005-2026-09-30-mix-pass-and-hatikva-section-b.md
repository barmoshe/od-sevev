# 0005. Mix pass v1.6, and HaTikva's second section on the tap

- Date: 2026-09-30
- Status: Accepted (Bar: "improve the mix, the master and the SFX, and think of the notes yourself")

## Context

A measured pass over every rendered cue (decoded from the shipped QOA files) found: 26 one-shots start
on a step (up to -19 dBFS at sample 0, a click on a phone speaker); several files hit 0 dBFS after QOA
(the codec overshoots a -1 dBFS normalisation); a small DC offset on `stamp` and `slipStamp`. The master
was the limiter alone. Since ADR 0004 the tap plays HaTikva on a bell while the music's lead (L2) plays
its own melody in the same register whenever the player taps.

## Decision

- **Generator** (`tools/gen_od_sevev.gd`): files normalise to -3 dBFS (play_db keeps every loudness
  target); every one-shot (cues and stingers, never the loops) gets a 20 Hz DC blocker and a 1.5 ms
  raised-cosine fade-in (`_clean`).
- **Master** (`game/default_bus_layout.tres`): high-pass 35 Hz, a 2:1 glue compressor from -14 dB
  (10 ms / 160 ms), then the HardLimiter at -1 dB with +2 dB pre-gain.
- **The lead under the bell:** while taps play HaTikva, L2 sits at 0.5 (-6 dB) instead of 1
  (`OdAudio.L2_UNDER_BELL`), so the bell leads.
- **HaTikva section B** is on the tap: "עוד לא אבדה תקוותנו / התקווה בת שנות אלפיים / להיות עם חופשי
  בארצנו / ארץ ציון וירושלים", three 4-bar phrases (streaks rotate A, B1, B2). **Section B is written
  from the anthem as sung, not from a score** (no source was reachable from the container); the close
  reuses the verified cadence of bars 3-4. Replace it in `TAP_ANTHEM` from a verified score.

## Consequences

- Max file peak -2.2 dBFS (was 0.0), no DC, onsets mostly silent (a QOA start residue under 0.06 remains
  on 6 files). A recorded 40 s session (Movie Maker, the real bus chain) measures -16.5 LUFS integrated,
  LRA 2.3 LU, peak -0.2 dBTP. Audio folder 11.26 MB (budget 11.3). Tests 439/439.
