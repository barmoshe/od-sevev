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
- **Round 1 is shorter, for every leader:** three round-1-only knobs in `coalition` (`sim/coalition.gd`):
  `round1MoneyScale` 0.115 and `round1TimeScale` 0.5 on the late partners' unlock (the ones with a time
  floor; the early five keep the first minutes' beats), and `round1DemandScale` 0.5 on a demand's price
  (`price_scale(0)`). Measured first, the time floors alone changed nothing: money held round 1. From round
  2 the election scaling applies as before.
- **Every leader's deal can close 61 in its round:** a shuffled seat deal is re-dealt (from the next seed)
  until the partner seats that can open this round, and sit with the first partner and with each other,
  reach `leaderSelect.lineupRules.minRoundSeats` (35) (`Leaders.deal(id, seed, evolutions)`,
  `Leaders.reachable_seats`). Bennett's seeds 1 and 9 dealt 33 (Gafni, whom Liberman won't sit with, on the
  9-seat L6; Lapid or Golan on L5, closed in round 1) and took 15-16 min; Eisenkot's seed 6 stalled at 60/61
  (Liberman or Gafni, not both) for 3 min.
- **A postponement shows its wait:** the ticker chip reads "נדחה" with the countdown until the summons
  comes back (both skins), and can't be opened (there is nothing to choose yet).
- The bench gates move with it (`game/tests/bench/`, `design/progression-curve.md` §0).

## Measured (PacingSim first round, seeds 1-9)

| Profile | Before (live) | After |
|---|---|---|
| median, per leader | 8:14 (Bibi) … 8:51 (Bennett, two seeds 13-15 min) | 4:26 (Bibi), 4:33, 4:43, 4:29, 4:41, 4:28, 4:34, 4:53 (Golan) |
| engaged (Bibi, Bennett) | 7:45 | 3:37, 3:52 |
| casual | 8:30 | 4:35, 4:24 |
| idle | 10:57 | 5:25, 5:53 |
| chat every 45 s | 11:15 | 6:00 |

Mordechai David visits in 6-8 of 9 first rounds; the meter reaches 100 in most first rounds, so a press or
court day usually lands before the vote. The bench gates move with it (`game/tests/bench/`,
`design/progression-curve.md` §0): S1/L1 4-5 min, S2 3-5, S3 3:30-5:30, S4 and SL by 8 min.

## Consequences

- Round 1 now has two more beats: the meter heats once a shady source is bought, and Mordechai David
  visits in most first rounds. It also teaches more at once, which the reveal ladder was meant to avoid;
  Bar chose that trade.
- **Wipe #7** (`saveEpoch` 7). Bar first asked to keep the saves and reward the players, then, before the
  push: "reset all users data, this is the last time". So no save migration ships.
