# game/scripts/sim — the rules, no nodes

Owner: game-developer (sim). Everything here is pure static code over `GameState` and
`Content.data()`. Nothing touches a node, a clock or a file except `SaveStore`. The controller
(`main.gd`) and the pacing bench (`PacingSim`) call the same functions, so the bench plays the
same game as the player.

| File | What it owns |
|---|---|
| `economy.gd` | Taps, sources, spins, the Suitcase, the election payout and gate, away income |
| `meta.gd` | Milestones, trophies, perks, automation |
| `story.gd` | Eras, Dubi's beats, conditional headlines |
| `politics.gd` | **The one entry point for the od-sevev systems**: `install`, `tick`, `on_election`, `validate` |
| `coalition.gd` | The group chat "קואליציה 61": partners, seats, upkeep, demands, ultimatums, the brawl, Gotliv's transfer |
| `investigation.gd` | Suspicion, court day, "התייעצות ביטחונית", the aide drop, the pardon desk |
| `events.gd` | The event scheduler (opposition cards, the brawl, the leak, easter eggs), the photobomb album |
| `calendar.gd` | The countdown to 27.10.2026, the blackout, post-election mode, the clock that can't be rewound |
| `spins.gd` | Spin kinds (once / consumable / line), prices, fatigue, and the spin effects that aren't passive modifiers |
| `conditions.gd` | The one condition vocabulary (`unlock`, `when`) |
| `leaders.gd` | Leader select: the round's lineup, cards and rule, the pick, per-leader stats, the kit lookups |
| `missions.gd` | Missions + ranks (meta): 3 slots of the rank's missions, goals, claims and rewards, the rank's income bonus |
| `game_state.gd` / `save_store.gd` | What is saved (save v4), validation at load, migration |
| `pacing_sim.gd` | The headless player for `tools/balance.sh` |

## Controller wiring (engine developer)

```gdscript
# once per fixed step, VISIBLE frames only (hidden / away time never advances politics):
var now := Calendar.resolve_now(state, device_ms, server_ms_or_-1, BUILD_MS)   # ~1/s is enough
var ev := Politics.tick(state, dt, d, {"allowPing": not modal and last_buy_age >= 2.0,
        "nowMs": now, "weekday": dt_dict.weekday, "hour": dt_dict.hour})
for e in ev: match e.ev: ...   # see the event list below
```

**The vote stops the clock** (design/leader-select-spec.md §7.4): while the election card (O3) is
open and unconfirmed, pass `"vote": true`. Politics then advances only the calendar: no
ultimatum, demand, join, transfer, card or court timer moves. The controller also skips
`Economy.tick` and automation for those steps (`main.gd` `vote_open()`, `_step_economy`), so the
card is a pause and never a farm.

**Player actions** (each returns a result, and a Dictionary of UI events where there are any):

| Action | Call |
|---|---|
| Pay a pill (demand, ultimatum, rejoin, poach) | `Coalition.pay(state, seq, ceremony_done)`. A ceremony (Regev) needs the 3 s ribbon first. `Coalition.can_pay(state, seq)` gives the pill state. |
| "צאו החוצה" | `Coalition.resolve_brawl(state, Coalition.open_brawl(state).seq)` |
| Chat opened | `Coalition.on_chat_opened(state)` (clears unread, grows "המסדרון") |
| Court card | `Investigation.testify(state)` / `Investigation.postpone(state, d)`; price `Investigation.postpone_cost(state, d)` (−1 = testify only); excuse line `Investigation.excuse_step(state)` (1-6). `postpone` returns `events: [{ev: courtEnd, reason: "postponed"}]` |
| Buy a spin | `Economy.buy_upgrade(state, id)`. The pill reads `Economy.upgrade_price(state, id)` (a line's next level, S07's `costBpsSeconds`; −1 = done) and `Economy.can_buy_upgrade(state, id)`, **not** `u.cost` / `s.upgrades.has(id)` |
| Spin card extras | `Spins.card(state, id)` → {kind, price, level, levels, worn (the "שחוק" tag), liveSec, bars {public, friendly} (S08), flights, flightPct (S10)}; live timers `Spins.active_effects(state)`; `Economy.tick` returns `spinsEnded: [ids]` |
| Dubi's word salad | before a talking point: `Story.roll_word_salad(state)` → true: show `Story.word_salad(last_three_points)` (counts `wordSaladSeen`) |
| "אני לא מכיר אותו" | `Investigation.can_drop_aide(state)` → confirm → `Investigation.drop_aide(state)` |
| Pardon request | `Investigation.request_pardon(state)` → stamp line 1..8 |
| Kaia / drum line | `Events.act(state, "kaia", "feed", d)` / `Events.act(state, "drumline", "beat", d)` |
| Photobombers | at a camera moment `var r := Events.roll_photobomb()`; when tapped `Events.album_add(state, r)` (true = trophy "שלום בית בפריים") |
| Blackout notices | `Calendar.pending_notice(state)` → "blackout" (O11) / "election" (O12) → show → `Calendar.ack_notice(state, which)` |

**Reads for the HUD and the chat:**

| Read | Call |
|---|---|
| Seats "מנדטים X/61" | `Coalition.seat_info(state)` → {own, partners, total, gate, effective, gateSeats}; show `effective`/`gateSeats`. `Calendar.seats_numeral_hidden(state)` → stamp "חסוי עד 27.10" |
| The gate | `d.seats_gate_open`; `d.evolve_enabled` includes it |
| The chat log | `state.coalition.chat` (see Messages); `state.coalition.unread`; `Coalition.threat_count(state)` |
| Partner rows | `Coalition.roster(state)` → [{id, status, counts, seats, upkeepPct, frozen, benched, carry, meter 0..1 (Gotliv's ring), excluded, side, corridor, cardHidden}]. `cardHidden` (= `Coalition.card_hidden(state, id)`): a `pollLike` partner's card (`copy.card`) in the blackout; her membership and bubbles stay |
| Title | `Content.species_title(n)`: the last title + `prestige.speciesNumber` (" מס׳ {n}") |
| Trophy stats | `state.stats[key]` for every `Meta.STATS` key (the sim counts them; the engine keeps `capHits`, `goldenMissed`). `Meta.trophy_count(state)` skips `neverAwarded` |
| Thermometer | `Investigation.suspicion(state)` (0..100), `Investigation.floor_pct(state)` (hatched), `state.investigation.revealed`, `.phase` idle / summons / court / postponed, `.leftSec` |
| Live cards | `Events.active_effects(state)` → [{type, leftSec, …}] |
| Countdown chip | `Calendar.days_left(now)`; mode `Calendar.mode(state)` campaign / blackout / negotiation |
| Base payout on the election card | `d.pending` (this round's base), `d.base_pct_round` |

**UI events** from `Politics.tick`:
- chat: `message {msg}`, `ultimatumMark {seq, partner, left: 60|30}`, `partnerLeft`, `partnerJoined`,
  `standIn`, `transfer {partner, to}`, `groupOpened`
- court: `revealed`, `summons`, `courtStart {reason}`, `courtEnd {reason}`; reason `testified` (the
  player pressed להעיד) or `served` (the summons testified by itself); `postponed` comes from `postpone()`
- events: `event {id, kind, side, result}`, `eventEnd {type}`, `pledgeFlip {baseAdd}`, `invoice`,
  `followUp {upgrade}`, `kaiaNip {partner}`
- calendar: `modeChanged {mode, was}`

**Messages** (`state.coalition.chat[]`), each with `seq`, `type`, `state` (open / paid / deleted / expired / resolved) and `partner`:
- `demand` {price, kind money|ceremony, join, line, variant}
- `ultimatum` {price, leftSec, line "threat", variant, transfer?}. Paid → `state: deleted`, "ההודעה נמחקה".
- `reply` {n 1..3} → chat.reply.n
- `thanks` {line thanks|return}
- `status` (Deri)
- `transfer` {partner, to} (the banner)
- `brawl` {a, b} (the button)
- `sys` {key: the UX string id chat.sys.* / chat.brawl.after, partner, to, a, b, n, payable rejoin|poach, price}

Line text is `partners[].linesVariants[line][variant]` (or `.lines` when there are no variants). The
variants rotate in order per partner and line (`coalition.rot`, lifetime; C1 is always variant 0).
The sim never holds Hebrew.

## The data contract (v1, binding)

The worked instance is `game/tests/fixtures/politics.json`; `design/content.json` mirrors it.
`Politics.validate()` checks the references, and `test_coalition.gd::test_game_content_passes_the_lint`
runs it on the design content.

### `coalition`
| Field | Meaning |
|---|---|
| `gateSeats` 61, `knessetSize` 120 | The gate; abstainers lower the majority to floor((120 − abstain)/2)+1 |
| `ownSeats {base, perTier, perBaseDoubling, max}` | Own seats = base + perTier × (top source owned) + perBaseDoubling × floor(log2(1 + base)), capped at max |
| `firstPartner`, `firstDemandPrice` 60, `openAtSourcesOwned` 3 | FTUE C1 |
| `demandSec` 45, `minPrice` | A demand = demandSec × ₪/s × priceMult × priceGrowth^level (never flat) |
| `joinGapSec` | One new partner per gap as they unlock |
| `demandGapSec [min,max]`, `demandGapPerMember`, `demandGapMinSec` | Member demands: every gap × perMember^members |
| `patienceSec` | An unpaid member demand escalates to an ultimatum after this (once unlocked) |
| `ultimatum {sec 90, minPlaySec 180, minDemandsPaid 2, marksSec [60,30], maxOpen 1}` | UX U1 |
| `rejoinMult` 1.5, `poachSec`, `upkeepMaxPct`, `chatMax`, `corridorMsgsPerOpen` | |
| `unlockScalePerElection`, `unlockTimeScalePerElection` | partners' `runMoneyAtLeast` / `runSecAtLeast` × scale^evolutions |
| `round1MoneyScale`, `round1TimeScale`, `round1DemandScale`, `round1Ease` | ADR 0013: in round 1 the late partners' (those with `runSecAtLeast`) money and time thresholds and `price_scale(0)`; from round 2 the money/time discount eases out, `1 - (1 - scale) × round1Ease^n` |
| `negotiation {demandGapMult}` | Post-election mode: partners ask more often |

### `partners[]`
`id, g (m|f), seats, upkeepPct, demandWeight, threatChance, unlock` (conditions), plus one optional
mechanic each: `priceMult`, `priceGrowth` (Goldknopf, lifetime), `abstain` (Gafni),
`demandKind: ceremony` (Regev), `effects[]` (economy effect types; Smotrich `producerMult`, Levin
`suspicionGainMult`), `onPay {suspicion}` (Golan, Distel), `cannotLeave` + `statusLine` (Deri),
`transfer {to, meterPerSec, fireAt}` (Gotliv), `rebel` (Almog: poach only), `standIn` (Gantz),
`excludes [ids]` (Abbas, Liberman: the two never sit together, either way round; the bigger side (seats + abstain/2) comes first, so a pill never trades seats down, spec §7.2.2), `mutedLine` (Distel), `side`, `pollLike`, `lines` / `linesVariants`.

### `court`
`sources {producerId: weight}` (pts/s at 100% share of ₪/s), `max`, `floorPerRoundPct`, `floorMaxPct`,
`courtDaySec`, `courtBpsMult`, `courtPausesTaps`, `summonsAutoTestifySec`,
`postpone {treasuryPct, growth, maxPct, minCostBpsSec, cooldownSec[], excuseSteps}`,
`aide {suspicion, baseMultPerDrop}`, `pardon {stamps}`. Optional `producers[].suspicionPerBuy`.

### `eventsConfig` + `events[]`
`eventsConfig {gapSec [min,max], firstAfterPlaySec, photobomb {flag, liranPct, tomerPct, togetherPct}}`.
`events[] {id, kind (UI), side, flag, weight, cooldownSec, oncePerRound, pollLike, when, effect {type, …}}`.
Effect types: `none {sec}`, `suspicion {add}`, `noCrit {sec}`, `brawl {pairs, anyPair}`, `leak {leaks}`,
`interview {baseMultPct, invoiceAfterSec}` (+% on this round's base payout), `pardonDesk {sec}`,
`seatDrain {seats, sec}`, `pledge {gatePlus, sec, baseAdd}`, `roulette {lists}`,
`kaia {feedSec, buffSec, tapMult, nipSec}`, `drumline {sec, bpsSec}`, `loseRandomPartner`.

### `calendar`
`electionDate`, `blackoutStartUtc`, `pollsCloseUtc`, `israelUtcOffsets [{fromUtc, hours}]`,
`defaultOffsetHours`, `forceBlackout`, `forcePostElection`. ISO strings with offsets also parse.

### `flags`
`postLaunch`, `easterEggs`, `mordechaiDavid`, `yairNetanyahu`. All ship `false`; an unknown flag is off.

### Conditions (`unlock`, `when`, upgrade `unlock`)
`era, evolutionsAtLeast, evolutionsBelow, runMoneyAtLeast, allTimeAtLeast, ownedAtLeast {producer,count},
sourcesOwnedAtLeast, shadyOwnedAtLeast, seatsAtLeast, seatsBelow, membersAtLeast (partnersInAtLeast),
partnerMember, partnerNotMember, suspicionAtLeast, suspicionBelow, courtDaysAtLeast, critsLifetimeAtLeast,
goldenCaughtLifetimeAtLeast, playSecAtLeast, runSecAtLeast, weekday [0=Sun…], hour [from,to], mode, pendingEngine`.
An unknown key is false, and the lint flags it.

### Economy fields the od-sevev content added
- `prestige.payout {scope: "round", rootDegree, divisor, epsilon}`: base = floor(cbrt(runEarned/divisor)+ε) × (1 + basePctThisRound/100).
- `prestige.gate {type: "seats"}`.
- `prestige.multPerBase`.
- `tap.pctOfBpsBase`, `tap.firstCrit {atTap, mult, randomCritsFromTap}`.
- `golden.firstOutcome`, `outcomes[].era`, `outcomes[].aide`; the type aliases `bunch` / `frenzy`.
- `producers[].revealAtRunEarned`.
- Effects `tapAdd`, `offlineMult`, `basePctThisRound`, `critChance {add}`, and the buy-time
  `suspicionFreeze` / `wipeSourceSuspicion`.
- `upgrades[].followUp.fallbackAfterSec`.

### Spins (`upgrades[]`, `spins.gd`)
- `kind`: `once` (default; into `s.upgrades`), `consumable` (rebuyable; each buy starts a timer and
  the card leaves the shelf until it ends; the n-th rebuy in a round lasts `fatigue`^n of its
  `durationSec`, at full strength), `line`
  (`levels[{cost}]` in order; into `s.upgrades` at the last level).
- `costBpsSeconds`: a consumable's price is max(`cost`, that many seconds of ₪/s, 3 significant digits up).
- Effects: `tapBuff {mult, durationSec}`, `idleToTap {durationSec, pourSecPerTap}` (income stops, each
  tap adds bps × pour; a rabbit never multiplies the pour), `karhiLine {broadcasterDrainPct,
  basePctThisRound, suspicionAdd}` per level, `flightIncome {addPct, capPct}` per Suitcase caught
  after buying, `basePerOppositionCard {add}` per opposition card (Events). All reset with the round.
- The hold: `unlock.pendingEngine: true` keeps a spin off the shelf; `Politics.validate()` fails on an
  unimplemented effect that isn't held. `Politics.unimplemented_effects()` is empty on the shipped content.
- Save: `GameState.spins {buys, levels, active, flights}` (additive; an older v3 save starts fresh).

### Trophy stats (`GameState.stats`)
`Meta.STATS` start at 0 and persist (any other plain numeric stat key the engine adds persists too).
Counted by the sim: `partnersPaid` (a payment that brought a partner in), `demandsPaid` (demands +
ultimatums), `courtDays`, `maxPostponesInRound`, `pardonRequests`, `aideDrops`, `brawlsEnded`,
`corridorMessages`, `cleanRounds`, `streakRoundsUnder240s` (best streak; `streakUnder240sNow` is the
live one), `tapsAt2to4` (Politics.tick: ctx.hour, else Israel time from nowMs), `wordSaladSeen`
(`Story.roll_word_salad`). Content-driven through the trigger: `countEvent` (`lapidCards`),
`countUpgrade` (`wingOfZionBought`), `countPartnerPaid` (`gafniPaid`). An older save seeds the lifetime
ones from the modules' own counters.

## Missions + ranks (`missions.gd`, content `missions`; Bar 2026-10-02)

AdVenture Communist's spine: three missions at a time, "לקחת" pays, a finished rank pays a permanent
income bonus. Meta progression: it persists across elections. Content without `missions` (the fork's,
the fixtures) turns it off. The content's `_doc` has the shape; `design/sim/content-lint.mjs` §10 and
`ux/tools/gen_strings.py` (`mis.text`) lint it.

| What | Call |
|---|---|
| Fill the slots, latch finished goals (4×/s; the controller's `_check_meta` → `MissionsUi.check`) | `Missions.tick(s, d)` → the ids that just finished |
| The rows | `Missions.slots_view(s, d)` → [{id, text, goal, reward, value, target, frac, done}]; `Missions.claimable(s)` |
| "לקחת" | `Missions.claim(s, i, d)` → {ok, id, reward (`reward_now`), rankUp {} \| {rank, title, incomePct}} |
| The rank | `Missions.rank_view(s)` → {rank, title, next, done, total, frac, incomePct, nextPct, top}; `Missions.income_pct(s)` |

- **Goals.** Counted goals read lifetime counters the sim already keeps, as the difference from the
  slot's `base` (the counter when the mission showed): taps, crits, earnRun (all-time ₪), payDemands
  (`stats.demandsPaid`), suitcases, courtDays (`stats.hazardDays`: court or press days, so every leader
  can do it), useAbility (every leader's `abilityUses` + `unityRefusals`: Liberman's ability has no
  button, the unity offer's refusal counts), elections, buySpins. The only new counter is
  sourcesTotal (`missions.bought`, from `Economy.buy_producer`). State goals (ownSource, bpsAtLeast,
  seatsAtLeast) read the state now; a finished goal is latched (`done`), so an election that resets
  the sources never un-does it.
- **Rewards.** cash {sec, min?}: sec × ₪/s now (frenzy excluded), at least `min` or `cashFloor`;
  frenzy {sec}: the Suitcase's income frenzy (`buff_frenzy`, golden bpsFrenzy's own ×5, refreshed,
  never stacked: the design's `mult` is that outcome's, so the content gives only `sec`); basePct
  {pct}: + pct on this round's base payout (`events.roundBasePct`, reset by the election).
- **Ranks.** `ranks[r-1].incomePct` is paid on reaching rank r, summed over the ranks reached, as a
  global multiplier (`Missions.install` registers it in `Economy.MODIFIERS`, like the trophies' morale).
- **Pacing** (bench, `PacingSim.run` claims whatever is done each tick; `player.log_missions` adds the
  claims to the events). Round 1's rewards are mostly basePct: cash or a frenzy in the first minutes
  compounds, and the first cut (cash 30-60 s, a 50 ₪ floor) moved the median first election from
  8:04 to 6:25. Shipped list, median hour (seed 7): the first four missions inside 1:10 (the
  onboarding), rank 2 at 2:36, rank 3 at 13:44 (the first election is a rank-2 mission), rank 4 at
  20:06, rank 5 at 41:00, rank 6 at 58:32; then a mission every ~3-9 min, rank 7 after ~1:45 h.
  Bench (2026-10-02): median first election 7:14 (was 7:55), engaged 6:53, casual 6:53, idle 9:10;
  every leader's median over seeds 1-9 in 7:28-8:30 (`test_leaders_balance`).
- **Save.** `GameState.missions {rank, slots [{id, base, done}], claimed, bought}` (additive, no
  version bump); `Missions.sanitize` drops unknown, duplicate, claimed and other-rank slots; a save
  without the section starts at rank 1 (its old counters become the first slots' bases).
- **UI** (`ui/missions_chip.gd`, `ui/missions_ui.gd`, `ui/views/view_missions.gd`): the chip in the
  stage's top-left sky (from the first tap), the sheet, the ticker line on a finished mission, the
  rank-up toast + ticker + confetti. Tests: `tests/unit/test_missions.gd`.

## Save v3
`GameState` gained `coalition`, `investigation`, `events`, `album` and `calendar`. Each module owns
its dictionary: `fresh_state()` gives the defaults, `sanitize()` validates at load (unknown ids are
dropped, numbers are clamped, one open message per partner), and `on_election()` resets the round.
A v2 file migrates by gaining fresh sections; a newer file is kept aside (`SaveStore`).
Tests: `tests/unit/test_politics_save.gd`.

## Leader select (save v4; `leaders.gd`, design/leader-select-spec.md §9.6)

Every round the player heads one party. `Leaders` installs the round: the leader's `coalition.lineup`
dealt onto `leaderSelect.coalitionSlots` (the person's traits, then the slot's numbers, then the
lineup's overrides; `abstain` people turn the slot's seats into abstentions, `cannotLeave` never
threatens), the round's cards (shared events minus `bibiOnly.events`, the leader's `rivals`,
the `leakRight` skin for an opposition leader, a `selfEvent` card with side "self"), and the rule.
`Coalition.partners()` / `Events.list()` / `Coalition.first_partner()` read it. **Bibi (the default
leader) installs the shipped `partners` and `events` untouched**, so his round is the shipped game;
content without `leaders` (the fork's, the fixtures) is always that default round.

Round flow: a new game and every election begin a round with the same leader and open the picker
(`leader_pick_pending`); `start_round` replaces it until the round starts (no tap, no partner). The
engine (2026-09-29) opens `LEADER_PICK` (`ui/views/view_pick.gd`) whenever `Leaders.pick_pending` holds
and nothing else is up, and freezes the economy until the pick (`main.gd` `_check_pick`); the views
read the round through `ui/leader_ui.gd` (`LeaderUi`).

**Engine API** (the picker and the views):

| What | Call |
|---|---|
| The round's leader | `Leaders.current(s)`; `Leaders.pick_pending(s)` (show the picker); `Leaders.can_repick(s)` |
| The picker | `Leaders.picker(s, rng)` → {tiles [{id, name, short, party, g, side, art, avatar, blurb, line, ruleName, ruleText}] (shuffled), again (last round's leader or ""), first, random, undoSec, copy}; `Leaders.pickable()`; `Leaders.random_pick(rng)` ("הפתעה") |
| Pick | `Politics.install(s, id)` = `Leaders.start_round(s, id)` → {ok, leader, fresh, freshPct, switched, repick} / {ok: false, reason: unknown \| started \| inactive}. Esc/back = `start_round(s, Leaders.current(s))` or just leave it (the round is already that leader's). |
| Undo ("להחליף", ≤ 5 s, before tap 1) | `Leaders.undo_pick(s)` → the exact pre-pick state (same seed → same deal, the +10% and the switch reverted, the picker open) |
| New game | `Leaders.set_salt(s, randi())` once, so deals differ between players |
| Kit | `Leaders.tap_kit(id)` {prop, anim, critAnim, critEvent, critProp, verb, verbPlural, critName, critPlural, frenzyBanner}; `Leaders.hazard(id)` = `Investigation.skin(s)` {skin court \| press, meterName, dayTitle, dayBody, testifyVerb, chip, …, postponeVerb, excuses[6]}; `Leaders.dubi(id)`; `Leaders.suitcase(id)` {sticker, sprite, lines}; `Leaders.source_skin(id, producer)`; `Leaders.spin_skin(id, upgrade)` (icon fallback `spin_slot_<slot>`); `Leaders.story(id)`; `Leaders.rule(id)` (its `copy`); `Leaders.leader(id)` (name, short, party, g, side, art, avatar) |
| Round text | `Leaders.headlines(s)` (+ `Leaders.headline_hit(s, trigger)` for `leaderStat` / `when`); `Leaders.ambient(s)`; `Story.flash(s)` {leader, n, title, lines, id} (the leader just played, by their own election count); `Leaders.leak_copy(s)` (event result `skin: leakRight`) |
| Stats | `Leaders.stat(s, id, key)`, keys rounds, elections, taps, crits, declines, merges, bestRunSec, playSec; `stats.leaderSwitches`, `stats.pressDays` (UX PRESS_DAYS), `stats.hazardDays` (court + press); the result card's DAYS_* count is `Investigation.hazard_days(s)` (lifetime court + press days) |
| Trophies | `Meta.all_trophies()` = the shipped 40 + 2 global + 7 leaders (`Meta.achievements()` stays the shipped list until the dossier switches) |
| Liberman | `Coalition.can_decline(s, seq)`, `Coalition.decline(s, seq)` → {ok, reason?, partner, events}; `Coalition.decline_cooldown(s)` (−1 = not his round); message state `declined`, sys `chat.sys.declined` |
| Golan | `Coalition.merge_candidates(s, id)`, `Coalition.merge_block(s, a, b)` ("" or rule \| cooldown \| limit \| same \| member \| young \| standIn \| ultimatum), `Coalition.merge(s, a, b)`, `Coalition.merge_cooldown(s)`; status `merged` (in a's `carry`), sys `chat.sys.merged {a, b}`, a pair walkout's `chat.sys.left` carries `with: [b]` |
| Eisenkot | `d.straight_mult` (his chip); `Economy.tap` returns `tap7: true` at tap 7 of the first round (show `rule.copy.tap7`) |
| Deri | `Coalition.pay` events carry `{ev: leaderBuff, partner, type, mult, sec}`; the live buff is `Events.active_effects` type `leaderBuff` |

Knobs (`rule.effect.type`): `selfEvent`, `partnerThreatMult`, `declineDemand`, `straightTaps`, `mergeMembers`,
`leaderEffects` {`effects` (Economy effects), `demandDiscountPct` (adds to the p_deal perk, now
implemented in `Coalition.demand_price`), `coalition` {rejoinMult, poachSec, patienceSec, demandSec,
minPrice}, `onDemandPaid` {type tapBuff}}. Filters: Bibi's spins leave the shelf and s08 needs Karhi
(`Spins.on_shelf`), the aide / laundry Suitcase outcomes go to cash, the aide drop and the pardon
desk are the court's, bibiOnly trophies are earned in his round only.

Save v4: `leader, leaderPickPending, leaderHistory, leaders, seatDeal, leaderRound {prev, switched,
fresh, freshPct, lastPlayed, begun, picked, undo, salt}`. A v3 file becomes Bibi's round (leaders.bibi
seeded from the lifetime counters) with the picker closed until the next election. An unknown leader
falls back to Bibi (the picker opens if the round hasn't started); a started round never reopens
the picker; a forged deal is re-dealt. Tests: `tests/unit/test_leaders.gd`.

Bench: `PacingSim.session(player…)` with `player.leader` = an id or `"mixed"`; `PacingSim.first_round`.
Cadence keys (optional, default = the attentive player): `buy_every`, `buy_units`, `buy` (best | priciest), `spins`,
`politics_every`, `ping_after_buy`. `tests/bench/test_web_driver.gd` replays `tools/web/round_web.mjs`'s measured
game-time cadence with them: the browser driver's 25-34 min first election is the driver (0.037 taps/s, a buy every
~138 s, no spins, no Suitcase at ?speed=10), not the game.
`tools/balance.sh [--leader=<id>]` runs `tests/bench/test_leaders_balance.gd` (every leader: the
median first election over seeds 1-9 in 7-9 min, S0/Q3, S2-S4, a median hour for S5-S7; a mixed hour).

## Tuning table (bench-measured; the Designer mirrors it into design/content.json)

See the section "Tuning" below. `tools/balance.sh` prints it.
