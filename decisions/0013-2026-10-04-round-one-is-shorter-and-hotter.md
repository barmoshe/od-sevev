# 0013. Round 1 is shorter, and opens the suspicion meter and Mordechai David

- Date: 2026-10-04
- Status: Accepted (Bar)
- Amends: the reveal ladder (2026-10-03, `design/overwhelm-report-2026-10-03.html`, "one new system per
  round") for round 1 only

## Context

Bar, after playing the live build: "the first round lacks dopamine and is too slow" and "after about 5
minutes of play it loses interest". Asked what should add the excitement, Bar picked the suspicion meter
(חשד), then: "the suspicion meter should come earlier, in the first round; Mordechai David also in the first
round". The target Bar chose for round 1 is 4-5 minutes for the median player (the bench measured 8:01;
gate S1 was 7-9 min). Bar also reported that the meter "doesn't go down" (a screenshot at רותח, Eisenkot's
round): after a postponement the meter stays full until the summons comes back, and nothing on screen said so.

## Decision

- **The suspicion meter and Mordechai David open in round 1** (`reveal.suspicion` and `reveal.mordechai`
  0). The rest of the ladder still opens one system per round: round 2 spins, round 3 events (moved up from
  round 4 so round 3 still opens something), round 4 ultimatums and abilities, round 5 missions, perks,
  share and milestones. Their wizard bubbles drop the word "חדש" in round 1.
- **Mordechai David never blocks under a wizard bubble** (the stage counts as covered while one shows), so
  the first round's guided steps are never interrupted.
- **Round 1's clock is shorter:** a new knob, `coalition.round1TimeScale`, multiplies the late partners'
  `runSecAtLeast` in round 1 only; later rounds keep their eased floors (`unlockTimeScalePerElection`), so
  rounds 2+ keep their lengths. See the bench numbers below.
- **A postponement shows its wait:** the ticker chip reads "נדחה" with the countdown until the summons
  comes back (both skins), and can't be opened (there is nothing to choose yet).
- The bench gates move with it (`game/tests/bench/`, `design/progression-curve.md` §0).

## Consequences

- Round 1 now has two more beats: the meter heats once a shady source is bought (a press/court day can land
  before the vote), and Mordechai David visits in most first rounds.
- Round 1 teaches more at once, which the reveal ladder was meant to avoid; Bar chose that trade.
- Saves are untouched (no wipe): this is content and pacing.
