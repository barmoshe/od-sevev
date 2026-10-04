> **Status (2026-09-29): §0 is the live עוד סבב pacing spec.** §1-§11 below are the inherited Monkey Bananas curve, kept only as the fork's reference. The live numbers are in `content.json`; the design rationale is `creative-pack/pitch.md` §5, §9, §10, §11 plus the `_why` / `_tuning` notes in `content.json`.

## 0. עוד סבב pacing: gates, tuning, and the authoritative bench

**The bench is authoritative.** `tools/balance.sh` runs `game/tests/bench/` through `PacingSim`,
which plays the shipped GDScript (Economy, Politics, Spins, Meta) on `design/content.json`. It
is the only pacing number this studio quotes.

**`design/sim/economy-sim.mjs` is retired as non-authoritative.** It reported the first election
at 7:22 (1.5 taps/s), while the real code on the same content took 5:00. Its buyer stops buying
sources while a demand is queued, and it models no stand-in (Gantz), spins, suitcases, perks or
`runSecAtLeast`. It stays in the repo only as a paper sketch of the first-five-minutes beats.

### 0.1 Profiles
| Profile | Taps/s | Suitcases | Notes |
|---|---|---|---|
| median | 1.5 | caught | the pitch's reference player (§5 "7-9 minutes"); new in `PacingSim.PLAYERS` |
| engaged | 4 | caught | |
| casual | 2 | caught | |
| idle | 3 for 2 min, then 0 | never | |

Each plays one 60-min session, seed 7, and calls every election at 61. The politics strategy is
the default (`PacingSim.POLITICS`).

**Bench clock fix (in `PacingSim.run`).**
- A frame that bought something had already ticked 0.25 s of play (income, taps and politics),
  but it skipped the clock.
- As a result, bench times ran about 5% short of real play time.
- The clock now advances on those frames too.
- The "Before" column below was measured with the old clock. On the fixed clock it would be about
  5% longer and would still fail the same gates.

### 0.1b Round 1 since ADR 0013 (2026-10-04)
Bar: round 1 "lost interest after about 5 min". Round 1 now opens the suspicion meter and Mordechai David
and runs **4-5 min** for the median player (gates S1/L1 4:00-5:00, S2 3:00-5:00, S3 3:30-5:30, S4 and SL by
8:00; the rest unchanged). The knobs are round-1-only: `coalition.round1MoneyScale` 0.115 and
`round1TimeScale` 0.5 on the late partners, `round1DemandScale` 0.5 on demand prices; shuffled deals are
re-dealt until `lineupRules.minRoundSeats` (35) reachable seats. Per-leader medians and the before/after
table: `decisions/0013-2026-10-04-round-one-is-shorter-and-hotter.md`. The S1-S4 rows below are the
2026-09-29 tuning, kept as the record.

### 0.2 Gates, their sources, and before → after (bench, seed 7)
| # | Gate | Source | Before | After |
|---|---|---|---|---|
| S0 | median C1 (chat ping) at 0:20-1:15 | pitch §11 Q2 ("~45 s") | new gate; early economy unchanged | 0:25 ✓ |
| Q3 | no ultimatum before 3:00 of play | pitch §11 Q3 | new gate (config-enforced) | 3:00 ✓ |
| S1 | median first election 7:00-9:00 | pitch §5 Targets (line 190) | 5:00 ✗ | 8:01 ✓ |
| S2 | engaged first election 5:00-9:00 | sim developer's objection (STATUS.md), accepted by the orchestrator | 3:15 ✗ | 7:28 ✓ |
| S3 | casual first election 5:00-9:00 | casual's 2 taps/s sits between S1 and S2 | 4:10 ✗ | 7:35 ✓ |
| S4 | idle first election later than the median and ≤ 16:00 | pitch §10.3: a style is "viable but slower, not a trap"; 16 = 2× the median's 8-min center | 7:44 ✓ | 10:07 ✓ |
| S5 | median round 2 between 3:00 and round 1 | pitch §11 Q8 note ("base growth makes later rounds faster") + §9 (a suitcase every 2-4 min must fit in a round) | 2:36 ✗ | 4:30 ✓ |
| S6 | median rounds 1-5 each ≥ 3:00 | pitch §9 cadence: each round holds a story flash, a suitcase and ~90 s partner messages | shortest 1:30 ✗ | shortest 4:05 ✓ |
| S7 | median reaches Washington (the 5th election, `eras.list`) within the hour | pitch §4 (four eras) + §8/§9 (one story beat per election) | ✓ (by 13 min) | ✓ (5th at 27:03; 8 in the hour) |
| S8 | median rounds get faster: the per-round median over seeds 3-11, rounds 2-8 each ≤ the previous + 0:15, rounds 6-8 ≤ 6:00, none under 2:00 | the idle-genre rule (each prestige loop reaches the gate faster than the last) + pitch §11 Q8 note | new gate (2026-10-02) | see §0.4 |
| — | engaged ≥ 3, casual ≥ 2, idle ≥ 1 elections/hour; no round < 1:00; nothing-new gap ≤ 5:00 in runs 1-3 | fork gates kept (pitch §9) | ✓ | ✓ (8 / 8 / 8; gaps ≤ 1:47) |
| G1-G4 | the triangle (`test_politics_balance.gd`, engaged, seed 11) | pitch §10 | ✓ | ✓ (below) |

Removed: the old gate "first Evolve in 9:30-15 min", which is Monkey Bananas' number, not this game's.

**Round lengths, whole hour (m:ss):**
| Profile | Before (old clock) | After |
|---|---|---|
| median | 5:00, 2:36, 1:30, 2:08, 1:50, 2:23, 1:40, 1:25, … (first 20 min) | 8:01, 4:30, 5:37, 4:05, 4:50, 9:42, 9:47, 9:58 |
| engaged | 3:15, 3:40, 1:37, 2:03, 1:45, 1:51, 1:28, 1:46, 1:12, … (18 elections) | 7:28, 5:45, 6:05, 6:32, 4:31, 10:03, 9:06, 5:18 |
| casual | 4:10, 4:05, 1:42, 2:03, 2:20, 1:32, 1:30, 1:14, … (18) | 7:35, 4:30, 5:16, 5:11, 5:24, 8:50, 5:57, 8:36 |
| idle | 7:44, 2:57, 2:37, 2:16, 1:49, 1:40, … (17) | 10:07, 5:13, 4:50, 6:28, 4:43, 5:15, 9:11, 12:35 |

- Rounds 2-5 run 4-6 min.
- From round 6 the late money thresholds (× 5^n) outgrow the multiplier, and rounds lengthen to
  about 9-10 min. That is pitch §5's "later rounds lengthen".
- **Superseded 2026-10-02 (§0.4):** later rounds now get faster, each round no slower than the
  last, toward a floor of about 3:00.
- Base after an hour: median 42K (was about 205K on engaged).

**Seed spread (round 1, seeds 1-9, fixed clock, a scratch probe running `PacingSim.run`):**
- median 7:34-8:25 (midpoint 8:01)
- engaged 6:40-7:36
- casual 7:24-9:06 (one seed 6 s over the band)
- idle 9:36-10:07

**The triangle (engaged hour, seed 11), after:**
| Strategy | Elections | Base | Court days | Walked out |
|---|---|---|---|---|
| default | 8 | 49,469 | 27 | 20 |
| payAll | 5 | 9,066 | 22 | 13 |
| alwaysPostpone | 7 | 31,721 | 21 | 19 |
| alwaysTestify | 8 | 49,469 | 27 | 20 |
| clean | 7 | 4,225 | 17 | 17 |
| aideDropper | 7 | 28,902 | 24 | 19 |

- **G1 ✓:** nothing beats the default (alwaysTestify ties it).
- **G2 ✓:** clean has 7 elections and a lower base.
- **G3 ✓:** 27 court days.
- **G4 ✓:** 20 walkouts.
- **Open finding:** the clean route's first round is 21:19 against 7:21, far from pitch §10.3's
  "about 40% slower per round". Rounds 2+ are close to the default. The baseline was already 2.3×
  (8:50 vs 3:54). No G-gate covers it; it's a follow-up for the triangle.

### 0.3 What changed in `content.json` (tuning fields only; no copy)
**Why rounds were short.**
- In round 1 the economy doubles about every 45 s from minute 5, so a money threshold on its own
  buys little time. Round 1 closed on qatari (own 32) plus Gantz's stand-in (4 seats).
- From round 2 the own-seat cap (36) plus the five early partners (25 seats) reached 61 on their
  own, so every later round ran 1:30-2:30.

**The fix, in two parts:**
1. Own seats stop closing the gate.
2. The late partners arrive on money *and* the round clock.

| Field | Before | After | Why |
|---|---|---|---|
| `coalition.ownSeats.base` | 20 | 21 | keeps C1 at 34/61 (21 + 1 + Ben Gvir 12, UX §2.3) |
| `coalition.ownSeats.perTier` | 2 | 1 | round 1 tops out at 26-27 own seats |
| `coalition.ownSeats.max` | 36 | 28 | the 5 early partners (25) + own never reach 61 alone |
| `coalition.unlockTimeScalePerElection` | (absent = 1) | 0.9 | the round-clock floor eases 10% per election |
| `goldknopf.unlock` | 16K | 225K, round ≥ 4:30 | late partner #1 |
| `gotliv.unlock` (round ≥ 3) | 5K | 247.5K, ≥ 5:00 | |
| `distel.unlock` (round ≥ 2) | 12K | 270K, ≥ 4:00 | |
| `gafni.unlock` | 60K | 292.5K, ≥ 5:00 | pitch §5 "~5:00 Gafni's cheap tie on offer" |
| `abbas.unlock` (round ≥ 2) | 20K | 337.5K, ≥ 5:30 | |
| `deri.unlock` | 30K | 360K, ≥ 6:00 | the usual round-1 closer |
| `maygolan.unlock` | 45K | 450K, ≥ 6:30 | |
| `almog.unlock` | 80K | 562.5K, ≥ 7:00 | |

- The late money thresholds are L × (1, 1.1, 1.2, 1.3, 1.5, 1.6, 2, 2.5) with L = 225K. Round time
  is `runSecAtLeast`. Both scale per election: money × 5^n (`unlockScalePerElection`, unchanged),
  time × 0.9^n.
- Unchanged: the early partners (Ben Gvir; Regev 1K, Smotrich 2.5K, Levin 6K, Amsalem 9K), all
  prices (`demandSec` 45), sources, spins, the suitcase and the payout. The pitch §5 and §11 Q1-Q2
  beats therefore still hold: 15 ₪ on tap 12, C1 fixed at 60 ₪, the first shady source at about
  2:30, and about 51-55/61 seats at 5:00.

**Candidates tried (probe on the real code, seed 7, median / engaged first election):**
- Late thresholds alone (L = 60K / 150K / 400K, own max 32): 6:04 / 6:09 / 6:53 median. Gantz and
  qatari close the gate first.
- Own 21 + 1/tier, max 28, money only: L 120K 6:22, L 400K 8:40, L 1M 12:16. Later rounds stayed
  1:30-3:30, and `unlockScalePerElection` 12 barely moved them.
- Adding the round-clock floors (L 200K / 225K / 250K / 300K): 7:11 / 7:46 / 8:30 / 8:31 median
  (old clock). 225K is the one centred in 7-9 across seeds, and gives 8:01 on the fixed clock.
- All candidates were probed on the old bench clock (about 5% fast).

### 0.4 Later rounds get faster (2026-10-02)
**The rule.** Each election should reach the 61 gate faster than the one before (the idle-genre
rule, and pitch §11 Q8's note that "base growth makes later rounds faster"). Before this retune the
median's rounds 2-8 sat flat at 5-6 min, with spikes of 9-12 min. Bench gate S8 now holds the curve.

**Why rounds did not speed up.** Three causes, measured with a round-by-round probe of
`PacingSim.run` (who arrived, who was still unpaid, every walkout):
1. **Partner prices are seconds of income.** A demand costs `demandSec` (45) × current ₪/s, so the
   base never makes it cheaper. A late round brings about 13 partners in a 90 s window. With 45 s
   each, the median player spent 1-2 min paying the queue. The unpaid demands turned into
   ultimatums, and walkouts cascaded: one round 8 lost Ben Gvir, Smotrich, Gafni and May Golan and
   ran 9:03.
2. **The round clock barely eased.** `runSecAtLeast` × 0.9^n. Once the queue was paid, the gate
   still waited for Gotliv (5:00 × factor) or Deri (6:00 × factor).
3. **Goldknopf's lifetime price.** His `priceGrowth` 1.3 counts every payment ever, so in some late
   rounds he stays unpaid. Deri then closes the round instead of Gotliv, and his later floor (360 s
   against 300 s) put a 30-40 s bump into every such round (rounds 4 and 5 in most seeds).

The money thresholds were not the brake in this build: from round 3 the round earned 100-10,000×
the threshold. At × 5^n they caught up again around round 14, and rounds 14-15 ran 4-7 min.

**The fix (`coalition.gd` + `content.json`).**
- `Coalition.unlock_of` eases `runSecAtLeast` toward a floor instead of toward zero:
  × (`unlockTimeScaleMin` + (1 - min) × `unlockTimeScalePerElection`^n). Without the min key it is
  the old scale^n.
- `Coalition.demand_price` (and the poach price) take the same ease on `demandSec` / `poachSec`:
  × (`demandSecScaleMin` + (1 - min) × `demandSecScalePerElection`^n). Rejoins follow, at 1.5× the
  price. A veteran's deals cost fewer seconds of income, so the coalition stops eating the speed that
  the base buys. Round 1 pays the full 45 s, so the FTUE and the round-1 politics are untouched.

| Field | Before | After | Why |
|---|---|---|---|
| `coalition.unlockTimeScalePerElection` | 0.9 | 0.6 | the clock factor: 1, 0.83, 0.73, 0.67, 0.63, 0.61, 0.60, … |
| `coalition.unlockTimeScaleMin` | (absent = 0) | 0.58 | the floor: Gotliv's 5:00 never falls below 2:54, so no round collapses |
| `coalition.demandSecScalePerElection` | (absent = 1) | 0.5 | a demand costs 45 s, 25 s, 14 s, 9 s, 7 s, … of income |
| `coalition.demandSecScaleMin` | (absent) | 0.1 | at least 4.5 s of income, so a demand still costs something |
| `coalition.unlockScalePerElection` | 5 | 2 | below the base's growth, so earnings never gate a late round (× 5^n caught up at round 14) |
| `deri.unlock.runSecAtLeast` (+ slot L6) | 360 | 320 | Deri's floor no longer adds 30-40 s when he closes instead of Gotliv; round 1 still waits for his 360K |

**Median rounds (m:ss), the per-round median over seeds 3, 5, 7, 9 and 11 (probe of
`PacingSim.session`, the S8 seeds):**
| Round | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9-16 |
|---|---|---|---|---|---|---|---|---|---|
| Before | 8:00 | 5:08 | 5:29 | 5:38 | 4:54 | 5:27 | 5:06 | 6:02 | 4:43-9:12 |
| After | 8:00 | 4:10 | 3:47 | 3:29 | 3:26 | 3:04 | 3:00 | 3:03 | 2:56-3:11 |

- After the retune most seeds land within 30 s of the median in every round. Before, rounds 2-8
  ranged 3:32-11:45 across the five seeds.
- The median plays 16 elections an hour (was 9-10). Rounds 9-16 hold at 2:55-3:15, each one still a
  full round: the queue of demands, an ultimatum, a court day.
- Round 1 is unchanged for every leader (L1). Rounds 1-5 stay ≥ 3:00 for every leader (S6):
  BENCH_LEADERS.

**Candidates tried (probe, seeds 3-11 median unless noted):**
- Clock only (0.75 / min 0.3, price unchanged): the spikes stayed (seeds 1-7: rounds of 7-10 min).
  The demand queue was the brake.
- Clock 0.75 / min 0.4, price 0.8 / min 0.5: 4:34, 4:22, 4:42, 4:21, 4:14 (seeds 1-7). The walkouts
  were fewer but still set the round.
- Clock 0.7 / min 0.5, price 0.7 / min 0.25: 4:31, 4:12, 4:26, 3:50, 3:28, 3:26, 3:13. Round 4 was
  14 s over round 3 (Goldknopf's bump).
- Price 0.5 / min 0.1 (the payment lag mostly gone), clock 0.65 / min 0.5: 4:22, 3:41, 3:23, 3:26,
  2:51, 2:41, 2:39. Smooth, but the floor is too low.
- Clock 0.6 / min 0.58: 4:22, 3:47, 3:34, 3:48, 3:04, 3:00, 2:58. Round 5 was 14 s over round 4
  because Deri closed it. With Goldknopf at `priceGrowth` 1.15 instead: the same bump. With Deri at
  320 s: 3:34 → 3:33, and the bump was gone.
- Clock 0.7 / min 0.57 (a gentler curve): round 4 was 4:16 against round 3's 3:54, so it was
  rejected.
- Money × 5^n: rounds 14-15 ran 3:19-7:27. With × 2^n they hold at about 3:10.

# progression-curve — Monkey Bananas

Owner: Game Designer. Consumers: Game Developer (economy, persistence), UX Designer (shop, Evolution screen, ticker), 2D Artist (icon briefs).
**Canonical numbers live in [`content.json`](content.json).** The tables below mirror it for review. If the two ever disagree, content.json wins, and this doc is the one that must be fixed.
Verification: `node design/sim/economy-sim.mjs` reads content.json and reproduces every timing in §7.

## 1. Currencies

| Currency | Earned by | Spent on | Resets on Evolve |
|---|---|---|---|
| Bananas | tapping, producers, Golden Bunch, offline credit | producers, upgrades | yes |
| Opposable Thumbs ("Thumbs") | Evolving: `floor(cbrt(allTimeMoney / 1000))` minus the Thumbs already owned | never spent. Each owned Thumb adds a passive +10% | no |

## 2. Producers

All producers use `costGrowth = 1.15`. Cost of the next unit is `baseCost × 1.15^owned`. Payback is `baseCost / baseBps`, and it rises by about 1.3–2.7× per tier, so that the late tiers slow growth down (the cost wall that makes Evolve the right call).

| # | id | Name | Flavor | 16×16 visual hook | Base cost | Base bananas/s | Payback |
|---|---|---|---|---|---|---|---|
| 1 | `intern` | Intern Monkey | Unpaid. Paid in bananas. Eats the pay. | monkey face with a blue lanyard and white ID badge | 15 | 0.4 | 38 s |
| 2 | `tree` | Banana Tree | Grows bananas. The monkeys still suspect witchcraft. | stubby palm, green fronds, yellow bunch | 120 | 2.4 | 50 s |
| 3 | `hardhat` | Hard-Hat Crew | Climbs taller trees. Unionized. Demands smaller hats. | monkey in a white dome hard hat with a grey ridge and a tiny pickaxe | 1,100 | 16 | 69 s |
| 4 | `bureaucrat` | Banana Bureaucrat | Files each banana in triplicate. Now there are three. | monkey in a red necktie with a banana rubber stamp | 12,000 | 96 | 125 s |
| 5 | `catapult` | Banana Catapult | Imports bananas from other islands at 200 km/h. No refunds. | wooden catapult, arm cocked, one banana loaded | 130,000 | 560 | 232 s |
| 6 | `rocket` | Monkey Space Program | Searching the cosmos for bananas. Found: one (1) banana. | white rocket with a banana nose cone and a monkey porthole | 1.4M | 3,200 | 438 s |
| 7 | `timechimp` | Time-Traveling Chimp | Steals bananas from the past. The past is furious. | chimp with green swirl goggles and a clock | 20M | 20,000 | 1,000 s |
| 8 | `moon` | The Banana Moon | It was always a banana. Astronomers: "In hindsight, obviously." | banana crescent moon with a stem and a tiny flag | 330M | 120,000 | 2,750 s |

Reveal: a row appears at `runMoney ≥ 0.5 × baseCost`. One further row is shown as a black silhouette "???" with its cost, which gives the player a legible next goal. In run 1 the player reaches tiers 1–5, and tier 6 appears as the silhouette. That silhouette is the run-2 promise.

## 3. Upgrades (15)

| id | Name | Flavor | 16×16 visual hook | Cost | Effect | Unlock (AND) | Class |
|---|---|---|---|---|---|---|---|
| `glove` | Grippy Gloves | Twice the grip. Twice the banana. | one white cartoon glove | 100 | tap ×2 | runMoney ≥ 50 | knob |
| `bothhands` | Two-Handed Technique | A breakthrough 40 million years in the making. | two brown monkey hands, palms out | 1,500 | tap ×2 | runMoney ≥ 1,000 | knob |
| `workout` | Thumb Workout | Every tap now carries the weight of the economy. | flexing thumb in a red sweatband | 5,000 | each tap +2% of bps | runMoney ≥ 3,000 | **new combination** (couples tap to production) |
| `luckypeel` | Lucky Peel | Found on the ground. Obviously lucky. | peel with a four-leaf-clover spot | 7,500 | crit chance 5% → 10% | runMoney ≥ 5,000 | knob |
| `radar` | Golden Banana Radar | Beeps near gold. Also near regular bananas. Also always. | grey radar dish with a golden blip | 15,000 | Golden interval ×0.75 | runMoney ≥ 10,000 AND goldenCaughtLifetime ≥ 1 | **new combination** (turns the attention reward into a build) |
| `futures` | Banana Futures Market | Selling bananas that don't exist yet. Profitably. | green rising chart arrow over a banana | 150,000 | all production ×1.5 | runMoney ≥ 100,000 | knob |
| `hammer` | Banana Hammer | Structurally unsound. Economically devastating. | mallet with a banana head | 250,000 | each tap +4% of bps | runMoney ≥ 150,000 | **new combination** (active-tapper build payoff) |
| `internx2` | Coffee for Interns | Interns now vibrate at harvest frequency. | steaming mug with a banana handle | 150 | intern ×2 | own 10 intern | knob |
| `treex2` | Banana Fertilizer | Ingredients: bananas. | burlap sack with a banana label | 1,200 | tree ×2 | own 10 tree | knob |
| `hardhatx2` | Taller Ladders | OSHA has been notified. OSHA is also a monkey. | ladder with a banana on top | 11,000 | hardhat ×2 | own 10 hardhat | knob |
| `bureaucratx2` | Form B-4-NANA | Approved in record time: nine months. | clipboard with a red stamped banana | 120,000 | bureaucrat ×2 | own 10 bureaucrat | knob |
| `catapultx2` | Double-Barrel Catapult | Twice the bananas. Twice the property damage. | two crossed bananas over a spring | 1.3M | catapult ×2 | own 10 catapult | knob |
| `rocketx2` | Banana Fuel | Smells amazing at 3,000 degrees. | red fuel canister with a peel logo | 14M | rocket ×2 | own 10 rocket | knob |
| `timechimpx2` | Paradox Insurance | Covers grandfathers, butterflies, and bananas. | hourglass with a banana in the sand | 200M | timechimp ×2 | own 10 timechimp | knob |
| `moonx2` | A Second Moon | Tides are now "confused". | two small banana crescents | 3.3B | moon ×2 | own 10 moon | knob |

Other icons the 2D Artist needs: **Thumb** (the prestige currency): an upright brown monkey thumbs-up. **Golden Banana**: a bright gold banana with a 4-point sparkle, clearly distinct from the Big Banana.

**Unlock classification (DOG check 3).** 3 are new combinations, 12 are parameter knobs, and there are 0 content gates. That falls short of the ≥ 2:1 expressive-to-gate ratio as literally written. The justification is the genre and slot: in an idle MVP the "verb" is allocation. Parameter knobs *are* the expression surface, because which multiplier you buy first defines your build (§4 of the mechanic-spec). The only gated content is producer tiers 7–8, which are revealed as silhouettes and gated purely by economy, never by time or payment. None of the 15 upgrades restricts access.

## 4. Click power scaling

`tapValue = (1 × tapMult × prestigeMult + tapPctOfBps × bps) × tapFrenzyMult × (crit ? 10 : 1)`

| Stage | tapMult | tapPctOfBps | Typical tap (no crit) | Tap share of income at 4 taps/s |
|---|---|---|---|---|
| Start | 1 | 0 | 1 | 100% (bps is 0) |
| + glove, bothhands | 4 | 0 | 4 | about 30% at 2 min, falling |
| + workout | 4 | 0.02 | 4 + 2% bps | about 8–10% |
| + hammer | 4 | 0.06 | 4 + 6% bps | about 19% (at the 16/s cap, about 49%) |
| × prestigeMult | scales the base tap; the %-of-bps part already includes it through bps | | | |

Crit: 5% base (10% with `luckypeel`) × 10 gives an expected tap multiplier of ×1.45 (×1.9 with luckypeel). The simulated tap share of total run-1 income is 10% for the engaged player, 6% for the casual player and 32% for the autoclicker at the cap.

## 5. Evolution (prestige)

| Parameter | Value |
|---|---|
| Thumbs earned (cumulative) | `floor(cbrt(allTimeMoney / 1000))`. Use `Math.cbrt` plus a 1e-9 epsilon |
| Pending | `thumbsTotalEarned − thumbsOwned` |
| Multiplier | `prestigeMult = 1 + 0.10 × thumbsOwned`, applied to all production and to the base tap |
| Gate (minimum threshold) | `pending ≥ max(10, thumbsOwned)`. Every Evolve at least doubles your Thumbs. The **first Evolve needs 1,000,000 all-time bananas → 10 Thumbs → ×2.0** |
| Button reveal | hidden until allTimeMoney ≥ 250,000; then disabled, showing `pending / needed` |
| Resets | bananas, runMoney, all producers, all upgrades, run taps, active buffs, the Golden timer (the first Golden again arrives at 75 s) |
| Persists | Thumbs, allTimeMoney, evolutions count, lifetime Golden catches, lifetime taps and crits, headlines seen, settings, buy mode |
| Species title | `speciesTitles[min(evolutions, 7)]`: Monkeys → Slightly Smarter Monkeys → Banana Sapiens → Peel-Dwelling Philosophers → The Banana Bureaucracy → Post-Banana Primates → Galactic Banana Council → Ascended Bunch Mk N |

Thumbs by all-time bananas: 1M → 10 · 8M → 20 · 64M → 40 · 512M → 80 · 4.1B → 160 · 32.8B → 320 · about 262B → 640 · 2.1T → 1,280.

**Why cube root and the doubling gate** (both chosen from simulation, §7):
- With a **square root**, the doubling rule produced a runaway loop. Runs shrank from 10.8 min to 0.7 min, and the multiplier reached ×29,940 in 60 min, because loop gain was above 1. The cube root keeps each doubling at about 6–8 min through the mid-meta. After that, runs lengthen naturally (14 → 40 → 72 min) as the tiers run out. That is an endless tail with no runaway.
- **No gate** (evolve whenever pending ≥ 1) was a trap for players: 39 Thumbs at 60 min against 959 with the gate.

## 6. Offline earnings, numbers, and buy modes

- **Offline:** `min(elapsed, 8 h) × bpsNoBuffs × 0.5`, credited only when elapsed ≥ 60 s. It is shown in a "While you were away" modal. The 8-hour cap covers a night's sleep, so returning the next morning always collects the full value: there is no FOMO appointment. The 50% efficiency keeps active play the better way to play without making idle play pointless.
- **Number format:** costs, rates and every other number use 3 significant digits and are ceiled. Suffixes are K, M, B, T, then aa, ab … az, ba … zz (letter pair index = tier − 5). Values under 1,000 are shown as integers, except rates under 10, which show one decimal ("0.4/s"). Examples: 1234 → 1.23K · 12345 → 12.3K · 1.5e6 → 1.50M · 1e15 → 1.00aa · 3.3e17 → 330aa · 1e18 → 1.00ab. **The bank** (UX OBJ-5) is always floored. Below 1M it shows the full integer with thousands separators (1,234 and 999,999), so every +1 tap is visible. From 1M up it shows 4 significant digits (1.234M, 2.500T). The display therefore never claims you can afford something you cannot.
- **Buy modes:** ×1 / ×10 / MAX. Bulk cost is `baseCost × 1.15^owned × (1.15^n − 1) / 0.15`.

## 7. Pacing: worked simulation

Method (`design/sim/economy-sim.mjs`, 0.1 s ticks, seeded RNG, 5 seeds). A greedy buyer always targets the visible item with the best `cost / Δincome + wait-to-afford` and buys it as soon as it can. Goldens are caught by the engaged, casual and autoclicker profiles. The tap cap is enforced.

**Time to first purchase of each producer, and to first Evolve (run 1, seed 1, m:ss):**

| Milestone | Engaged (4 taps/s) | Casual (2 taps/s) | Idle (taps 2 min only, no Goldens) |
|---|---|---|---|
| intern | 0:01 | 0:03 | 0:02 |
| tree | 0:34 | 1:02 | 0:43 |
| hardhat | 1:23 | 2:08 | 2:22 |
| bureaucrat | 3:57 | 5:08 | 6:40 |
| catapult | 8:33 | 10:40 | 12:59 |
| rocket / timechimp / moon | silhouette only (run 2+) | — | — |
| **First Evolve available (mean of 5 seeds)** | **10:58** (range 10:43–11:16) | **12:13** (11:59–12:31) | **16:41** (16:33–16:48) |
| Autoclicker at the 16/s cap | 7:18 (range 6:59–7:48) | | |

Owned at the first gate: 23/21/18/9/3 (tiers 1–5), bps ≈ 4,860.

**Run 2** (10 Thumbs, ×2.0, engaged): intern 0:02 · tree 0:18 · hardhat 1:01 · bureaucrat 2:00 · catapult 4:27 · **rocket 7:22 · timechimp 11:26 · moon 20:02**. Each of the first three runs introduces new tiers, so content lasts through about run 3.

**Meta rhythm (engaged, evolving the moment the gate opens):**

| Horizon | Evolve at gate | Never evolve |
|---|---|---|
| 60 min | 959 Thumbs (×96.9). Runs: 10:50, 7:56, 7:54, 7:24, 6:36, 5:59, 7:01, … | 161 Thumbs (×17.1) |
| 180 min | 4,319 Thumbs (×432.9). Runs then lengthen: 14:28, 40:17, 71:36 | 498 Thumbs (×50.8) |

All-time bananas after 3 h are about 8e13, far from any floating-point limit.

## 8. Reward cadence (DOG checks 1–2)

| Stream | Schedule type | Justification |
|---|---|---|
| Tap → bananas | Continuous (FR-1) | Immediate competence feedback. The verb must feel like it works on every press |
| Crit (5–10%) | Variable-ratio | Low stakes (×10 of a small tap), no loss, never monetized. It exists for the juice spike (Lazzaro "fun of surprise"), not for retention |
| Purchases / reveals | Fixed-ratio (price thresholds) | Fully predictable, and the silhouette row shows the next goal and its price |
| Golden Banana | Variable-interval (90–180 s) | It rewards glancing at the screen. A miss costs nothing, and ignoring every Golden only slows the first Evolve from about 11 to about 17 min alongside no tapping. This is a commitment lever, not a compulsion lever |
| Headlines | Fixed-ratio (milestones) | Once-ever narrative beats that make progress legible |
| Evolve | Player-chosen, gated by a doubling | A transparent formula with the result previewed before confirming |

**Beats per session cohort** (engaged):
- **3-min check-in:** 1 offline collect + 4–8 purchases + about 1 Golden + about 1 headline, so roughly 7–11 beats in 180 s, one every 16–25 s.
- **12-min first session:** 5 producer reveals + about 12 upgrade buys + about 60 producer buys + 6 Goldens + about 10 headlines + the first Evolve, so a meaningful beat (a reveal, upgrade, Golden, headline or Evolve) about every 20–25 s.
- **30-min session:** first Evolve plus 2–3 more (runs of about 8 min), each adding new tiers (rocket, timechimp) or a new species title.

## 9. Meta-loop legibility (DOG check 4)

- **After run 1** (about 11 min), the player knows that the Thumbs count and the ×multiplier are visible in the HUD. The Evolution screen showed the formula outcome (×1.0 → ×2.0), a list of what resets and what persists, and the new species title. The silhouette of tier 6 promised new content.
- **After run 3**, the player knows the doubling rule ("needed: 40"), sees that each run is shorter than the first, and has watched the species title change twice.
- **Run N (mid-meta):** runs lengthen as the tiers run out. The ×now → ×after preview lets the player judge short-versus-long runs without leaving the screen.

## 10. Compulsion vs commitment audit (DOG check 5)

- **Scarcity or loss (Octalysis 6/8):** none. Offline credit caps at 8 h, so an overnight absence loses nothing. A missed Golden loses nothing. There are no streaks, dailies or timers that punish absence.
- **Unpredictability (Octalysis 7):** crits and Golden outcomes only. Both are bounded, never paid for, and never the only route to progress. The player's informed preference ("more bananas, a surprise now and then") matches the lever.
- **Brignull patterns:** there is no monetization, no confirmshaming and no forced continuity. Evolve is always optional and previewed.

## 11. Economy steady state (DOG check 6)

- **Solvent:** the greedy simulated buyer never waits long for its next purchase. The longest gap in run 1 is 64 s for engaged play, 89 s for casual and 98 s for idle; in run 2 it is 42 / 45 / 58 s. The greedy buyer deliberately waits for the item with the best payback, so a real player who buys cheaper items along the way has shorter gaps.
- **Not saturated:** the next tier's silhouette always has a price above the bank until the tiers run out, around run 7–8.
- **Rate cliffs to watch:** (a) a square-root prestige runs away (§5). Raising `multPerThumb` squeezes mid-meta runs too short for a legible rhythm: the shortest run is 6.0 min at 0.10, 5.3 min at 0.12, 4.2 min at 0.15 and 3.1 min at 0.20. Keep it at 0.10. (b) Goldens. By expected value the current Golden values add about +35% income for a player who catches every one. An earlier draft (Frenzy ×7 for 20 s, Bunch = 120 s of bps, interval 60–120 s) came to about +100%, which would make Goldens compulsory. Treat +50% as the ceiling. (c) `costGrowth` 1.15 is what creates the cost wall that makes Evolve correct. Lowering it softens that wall. This was not simulated, so re-run the sim before changing it.
