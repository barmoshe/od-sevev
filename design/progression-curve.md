> **Status (2026-09-28): superseded for עוד סבב.** This is the inherited Monkey Bananas curve. The live numbers are in `content.json`; the pacing check is `node design/sim/economy-sim.mjs` (it replaced the banana sim); the design rationale is `gamestudio/output/artifacts/creative-pack/od-sevev/pitch.md` §5, §10, §11 plus the `_why` / `_tuning` notes in `content.json`. Kept only as the fork's reference until a rewrite.

# progression-curve — Monkey Bananas

Owner: Game Designer. Consumers: Game Developer (economy, persistence), UX Designer (shop, Evolution screen, ticker), 2D Artist (icon briefs).
**Canonical numbers live in [`content.json`](content.json).** The tables below mirror it for review. If the two ever disagree, content.json wins, and this doc is the one that must be fixed.
Verification: `node design/sim/economy-sim.mjs` reads content.json and reproduces every timing in §7.

## 1. Currencies

| Currency | Earned by | Spent on | Resets on Evolve |
|---|---|---|---|
| Bananas | tapping, producers, Golden Bunch, offline credit | producers, upgrades | yes |
| Opposable Thumbs ("Thumbs") | Evolving: `floor(cbrt(allTimeBananas / 1000))` minus the Thumbs already owned | never spent. Each owned Thumb adds a passive +10% | no |

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

Reveal: a row appears at `runBananas ≥ 0.5 × baseCost`. One further row is shown as a black silhouette "???" with its cost, which gives the player a legible next goal. In run 1 the player reaches tiers 1–5, and tier 6 appears as the silhouette. That silhouette is the run-2 promise.

## 3. Upgrades (15)

| id | Name | Flavor | 16×16 visual hook | Cost | Effect | Unlock (AND) | Class |
|---|---|---|---|---|---|---|---|
| `glove` | Grippy Gloves | Twice the grip. Twice the banana. | one white cartoon glove | 100 | tap ×2 | runBananas ≥ 50 | knob |
| `bothhands` | Two-Handed Technique | A breakthrough 40 million years in the making. | two brown monkey hands, palms out | 1,500 | tap ×2 | runBananas ≥ 1,000 | knob |
| `workout` | Thumb Workout | Every tap now carries the weight of the economy. | flexing thumb in a red sweatband | 5,000 | each tap +2% of bps | runBananas ≥ 3,000 | **new combination** (couples tap to production) |
| `luckypeel` | Lucky Peel | Found on the ground. Obviously lucky. | peel with a four-leaf-clover spot | 7,500 | crit chance 5% → 10% | runBananas ≥ 5,000 | knob |
| `radar` | Golden Banana Radar | Beeps near gold. Also near regular bananas. Also always. | grey radar dish with a golden blip | 15,000 | Golden interval ×0.75 | runBananas ≥ 10,000 AND goldenCaughtLifetime ≥ 1 | **new combination** (turns the attention reward into a build) |
| `futures` | Banana Futures Market | Selling bananas that don't exist yet. Profitably. | green rising chart arrow over a banana | 150,000 | all production ×1.5 | runBananas ≥ 100,000 | knob |
| `hammer` | Banana Hammer | Structurally unsound. Economically devastating. | mallet with a banana head | 250,000 | each tap +4% of bps | runBananas ≥ 150,000 | **new combination** (active-tapper build payoff) |
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
| Thumbs earned (cumulative) | `floor(cbrt(allTimeBananas / 1000))`. Use `Math.cbrt` plus a 1e-9 epsilon |
| Pending | `thumbsTotalEarned − thumbsOwned` |
| Multiplier | `prestigeMult = 1 + 0.10 × thumbsOwned`, applied to all production and to the base tap |
| Gate (minimum threshold) | `pending ≥ max(10, thumbsOwned)`. Every Evolve at least doubles your Thumbs. The **first Evolve needs 1,000,000 all-time bananas → 10 Thumbs → ×2.0** |
| Button reveal | hidden until allTimeBananas ≥ 250,000; then disabled, showing `pending / needed` |
| Resets | bananas, runBananas, all producers, all upgrades, run taps, active buffs, the Golden timer (the first Golden again arrives at 75 s) |
| Persists | Thumbs, allTimeBananas, evolutions count, lifetime Golden catches, lifetime taps and crits, headlines seen, settings, buy mode |
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
