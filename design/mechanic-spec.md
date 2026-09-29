> **Status (2026-09-28): superseded for עוד סבב.** Inherited Monkey Bananas spec. The verbs carry over (tap = the hat, catch = the Suitcase, buy = sources and spins, Evolve = 'עוד סבב!'); the mechanics are in the creative pack's `pitch.md` §4-§10 and in `content.json`. Kept as the fork's reference until a rewrite. **Leader select (2026-09-29):** the player picks a party leader every round; see [`leader-select-spec.md`](leader-select-spec.md).

# mechanic-spec — Monkey Bananas

Owner: Game Designer. Consumers: Game Developer (implementation), Animator (tap/golden telegraphs), 2D Artist (silhouette/readability), Audio Director (event cues), UX Designer (learning experience).
Numbers: economy values are canonical in [`content.json`](content.json); feel values are canonical in the `feel-tunables` block of [`feel-spec.md`](feel-spec.md). This doc names the keys and does not restate their values as a second source of truth, except where a number is needed for the argument.

## 1. Core verb

**Tap the Big Banana.** One pointer-down on the Big Banana produces bananas right away. It is a single Koster skill atom: aim at one large target, press, get a reward.

Sub-verbs, ranked by expected frequency per minute in a typical first run:

| Rank | Sub-verb | Expected rate | When it matters |
|---|---|---|---|
| 1 | Tap Big Banana | 120–240 /min (2–4 taps/s) | Dominant from 0:00 to about 3:00, then a supplement worth 6–15% of income (more with Tap Frenzy or the Hammer) |
| 2 | Buy producer / upgrade | 2–6 /min | From 0:05 onward. This is the real decision verb of the genre |
| 3 | Catch Golden Banana | about 0.5 /min | From 1:15 onward. An attention reward |
| 4 | Toggle buy mode ×1 / ×10 / MAX | < 0.2 /min | Run 2 onward, once producer counts pass 20 |
| 5 | Evolve | about 0.1 /min | Once the gate opens (first time around 11–12 min) |

The verb deliberately hands its weight over from *tap* to *buy* during a run. That is the genre's contract: the player starts by making bananas by hand and ends up making decisions about bananas. The tap stays relevant for three reasons. It is the fastest way to start a run, it scales through `tapPctOfBps` upgrades, and Tap Frenzy makes it the best move for 12 s at a time.

## 2. Rules

1. **Tap.** Each registered pointer-down on the Big Banana hit area adds `tapValue` to `bananas`, `runBananas` and `allTimeBananas`. The award happens on pointer-down, not pointer-up.
   `tapValue = (tap.baseValue × tapMult × prestigeMult + tapPctOfBps × bps) × tapFrenzyMult × (crit ? tap.critMult : 1)`.
   Crit is rolled on each registered tap with probability `critChance` (starts at `tap.critChance`; the upgrade `luckypeel` sets it higher).
2. **Tap-rate cap.** At most `tap.maxRegisteredTapsPerSec` taps register per second, counted globally across all pointers and the Space key. Excess taps are dropped with **no award and no feedback**, so that feedback never lies about income.
3. **Production.** `bps = Σ(producer.baseBps × owned × producerMult) × globalMult × prestigeMult`. It accrues every frame as `bps × frenzyMult × dt`.
4. **Buy producer.** Cost of the next unit is `baseCost × costGrowth^owned`. The purchase deducts the cost at once and the unit produces from the next frame. Bulk cost uses `bulkCostFormula`. MAX buys `maxAffordable`, and never 0 units: if 0 units are affordable, MAX behaves like a can't-afford tap.
5. **Buy upgrade.** One-time per run. Its effect applies at once. Effect types are `tapMult`, `tapPctOfBps`, `critChance`, `goldenIntervalMult`, `globalMult` and `producerMult`.
6. **Reveal.** A producer row appears when `runBananas ≥ 0.5 × baseCost` or when you own at least one this run. Exactly one further row shows as a silhouette ("???") with its cost. An upgrade appears on the shelf when all its unlock conditions are true, and it stays until bought.
7. **Golden Banana.** The first one spawns `golden.firstSpawnDelaySec` into each run, and later ones follow a uniform interval `[spawnIntervalMinSec, spawnIntervalMaxSec] × goldenIntervalMult`. It lives for `lifetimeSec`. A tap on its hit area rolls a weighted outcome: Lucky Bunch (instant bananas), Banana Frenzy (bps ×5) or Tap Frenzy (tap ×10). If it is missed it simply despawns; nothing is lost. Its spawn timer and its on-screen lifetime run only while the page is visible **and no modal is open** (Settings, Evolution, Offline). A modal pauses both, while production and buffs keep running, so opening Settings never silently costs a Golden.
8. **Evolve (prestige).** `thumbsTotalEarned = floor(cbrt(allTimeBananas / divisor))`, and `pending = thumbsTotalEarned − thumbsOwned`. The Evolve button is enabled when `pending ≥ max(10, thumbsOwned)`. Evolving adds `pending` to `thumbsOwned` and resets the items in `prestige.resets`. It keeps `prestige.persists`. `prestigeMult = 1 + 0.10 × thumbsOwned`.
9. **Offline.** On load, `min(elapsed, 8 h) × bpsNoBuffs × 0.5` is awarded if `elapsed ≥ 60 s`. Any in-session gap longer than 60 s (a backgrounded tab) is also credited through this formula rather than at the full rate.
10. **Autosave** runs every `autosaveSec`, on `visibilitychange → hidden`, and right after every purchase and every Evolve.

## 3. State

| Scope | Fields |
|---|---|
| Run (reset on Evolve) | `bananas`, `runBananas`, `owned[producerId]`, `upgradesBought[]`, `runTaps`, `activeBuffs{frenzy, tapFrenzy: remainingSec}`, `goldenTimerSec`, `goldenOnScreen{x, y, ageSec}` |
| Persistent | `thumbsOwned`, `allTimeBananas`, `evolutions`, `goldenCaughtLifetime`, `tapsLifetime`, `critsLifetime`, `headlinesSeen[]`, `settings{sfx, music}`, `buyMode`, `lastSaveTime` |
| Derived (never saved) | `bps`, `tapValue`, `prestigeMult`, `pendingThumbs`, `evolveEnabled`, `speciesTitle` |

## 4. Expressive depth: four distinguishable shapes of play

1. **Active tapper.** Taps 4–16/s and prioritizes `workout` and `hammer` (tap = +2%, then +6% of bps). Tap Frenzy is its jackpot. Simulated first Evolve: 7:18 at the tap cap, 10:58 at 4 taps/s.
2. **Idle builder.** Barely taps, ignores Goldens, and buys `futures` and the ×2 producer upgrades. Simulated first Evolve: 16:41. It also earns while away (offline credit at 50% for up to 8 h).
3. **Golden hunter.** Buys `radar` early (interval ×0.75) and keeps attention on screen. Goldens are worth about +35% income when every one is caught.
4. **Prestige rhythm.** Short runs (evolve the moment the gate opens: runs of about 6–8 min in the mid-meta) versus long runs (push deeper tiers before evolving). The doubling gate (§5 D2) keeps both viable and leaves neither as a trap.

## 5. Dominant-strategy stress test

| # | Candidate (comparable-title source) | Verdict and closing rule |
|---|---|---|
| D1 | **Tap spam / autoclicker** (Cookie Clicker, Clicker Heroes) | *Declared intended optimum, bounded.* The 16/s cap limits it. At the cap with the Hammer, taps add about +96% of bps. A max-rate autoclicker reaches first Evolve 1.5× faster than a 4-tap/s human (7:18 vs 10:58), not 10×. Counter: the tap share collapses whenever no `tapPctOfBps` upgrades are owned, and idle income keeps pace in the long run. |
| D2 | **Micro-prestige** (evolve for +1 point, as in AdVenture Capitalist angel spam) | *Neutralized by shape.* The gate is `pending ≥ max(10, thumbsOwned)`, so every Evolve at least doubles your Thumbs. Without this gate, simulated "evolve whenever pending ≥ 1" play ended with 39 Thumbs at 60 min against 650 for never evolving: a trap. |
| D3 | **Never evolve / one long run** | *Neutralized.* Growth hits a cost wall once the tiers are exhausted, because 1.15^n cost outruns linear producer gains. Simulated at 60 min: evolving at the gate gives 959 Thumbs (×96.9) against 161 (×17.1) for never evolving. The Evolution screen shows ×now → ×after, so the better choice is legible. |
| D4 | **Bank hoarding for % rewards** (Cookie Clicker "Lucky" scales with bank) | *Neutralized by shape.* Lucky Bunch pays `max(60 s × bps, 30 × tapValue)`. It scales with income, never with bank, so the player has no reason to sit on bananas. |
| D5 | **Single-tier spam** (buying only the cheapest producer) | *Self-correcting.* Uniform `costGrowth` 1.15 means that after about 15 units of a tier the next tier has the better payback. The greedy simulated buyer spreads naturally, owning 23/21/18/9/3 at the first gate. |

## 6. Degenerate edge cases

| # | Case | Closing rule |
|---|---|---|
| E1 | Clock moved forward to farm offline | Capped at 8 h and paid at 50% efficiency. |
| E2 | Clock moved backward | A negative elapsed time is treated as 0, and `lastSaveTime := now`. Nothing is ever subtracted. |
| E3 | Floating-point overflow in the endless late game | The simulation reaches about 8e13 all-time bananas after 3 h. The formatter handles up to 1e308. Beyond `Number.MAX_VALUE`, clamp the value and keep the game running (no Infinity or NaN). All arithmetic stays in plain doubles; do not use BigInt. |
| E4 | "Can afford" shown but the purchase fails because of rounding | The displayed bank is floored: shown as a full integer with thousands separators below 1M, and to 4 significant digits above that. The displayed cost is ceiled, to 3 significant digits. The affordability check uses raw values (`bananas >= cost`). |
| E5 | Two buffs stacking multiplicatively (Frenzy × Tap Frenzy) | Rolling the same buff refreshes its timer and never stacks. Different buffs cannot overlap, because the minimum interval of 67.5 s (with radar) is longer than the longest buff (15 s). `tapPctOfBps` reads bps **without** the Frenzy multiplier. |
| E6 | Golden despawns during a tap / a tap lands on the Golden and the Big Banana at once | A tap never counts for both. The Golden spawns and drifts only at least 0.25 W from the banana center (feel-spec `goldenBigBananaExclusion`, rejection-sampled, and drift bounces off that circle). If a tap lands in both hit areas, it goes to the Golden only when it is inside the Golden's drawn 64×64 bounds; otherwise the Big Banana takes it. |
| E7 | Evolve pressed twice / during a transition | Evolve is idempotent per open dialog. Input locks for the duration of the transition, and the save happens before the transition starts. |
| E8 | Evolve pressed at the gate with a Frenzy active | Buffs are reset. The confirmation shows ×now → ×after only; buffs are not part of the value shown. |
| E9 | Multi-touch "piano" on the Big Banana | Every pointer-down counts, but all of them go through the one global 16/s cap. |
| E10 | Key-repeat on Space | Only `keydown` with `repeat === false` counts. |
| E11 | Opening a modal to stall a Golden | The pause freezes the Golden's lifetime but also hides it behind the scrim, and buffs keep ticking, so pausing gains nothing. |

## 7. Per-platform translation (input-modality matrix)

| Modality | Tap mapping | Timing budget | Discoverability cost |
|---|---|---|---|
| Touch (phone portrait, primary) | pointer-down on the Big Banana. The hit area is the banana sprite bounds plus 16 px of padding | Feedback within 2 frames (target 1). Touch adds about 2 frames of OS latency, which we accept | Zero. The Big Banana is the only interactive object on screen until the first reveal, at 7.5 bananas (about 8 taps) |
| Mouse (desktop) | left pointer-down | 1 frame target | Zero. Hover shows a hand cursor and a halo at alpha 0.3; the banana does not scale |
| Keyboard (optional) | Space = tap, subject to the same cap (no key-repeat) | 1 frame | Low. The settings overlay mentions it; it is not taught |

## 8. System loop (Machinations vocabulary)

```
[Tap] --source--> (Bananas) <--source-- [Producers] <--converter-- (Bananas)   (reinforcing loop R1: buy -> more bps)
(Bananas) --converter--> [Upgrades] --multiplier--> [Tap], [Producers]        (R2)
[Golden gate, variable interval] --source/buff--> (Bananas)                   (attention reward)
(allTimeBananas) --cbrt--> (Thumbs) --multiplier--> everything                (R3: meta loop, damped by the cube root + doubling gate)
costGrowth 1.15^n  --drain--> R1                                               (balancing loop B1: the cost wall that makes Evolve correct)
```

## 9. Seam briefs

- **Game Developer.** Import `content.json`. Implement the rules above as data-driven code with no hard-coded economy numbers, and mirror the `feel-tunables` block into `src/core/tuning.ts`.
- **Animator.** The tap squash starts on the pointer-down frame. The Golden needs a readable spawn fade-in, idle bob and wobble, and a 2 s despawn blink (the numbers are in the feel-spec).
- **2D Artist.** Draw every producer and upgrade icon at 16×16 from its `visualHook`. The Golden Banana must never be confusable with the Big Banana: it needs a distinct gold hue, a sparkle, and to be at most 0.35× the Big Banana's on-screen size. Crit floaters need a distinct color from normal floaters.
- **Audio Director.** Cue events: `tap`, `tapCrit`, `buy`, `buyBulk`, `cantAfford`, `upgradeBuy`, `goldenSpawn`, `goldenCatch`, `goldenDespawn` (soft), `frenzyStart`, `frenzyEnd`, `tapFrenzyStart`, `tapFrenzyEnd`, `milestoneHeadline`, `evolveOpen`, `evolveConfirm`, `offlineCollect`. The tap cue fires on the pointer-down frame. The tap cue can fire up to 16 times per second, so it needs a polyphony and fatigue plan.
- **UX Designer.** Owns how the gate is taught: the Evolve button stays hidden until `allTimeBananas ≥ 250,000`, then appears disabled with its progress shown as `pending / needed`. Owns the Evolution screen, which must show Thumbs gained, ×now → ×after, what resets and what persists, and the next species title.
