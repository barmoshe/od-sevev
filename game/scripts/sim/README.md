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
| `game_state.gd` / `save_store.gd` | What is saved (save v3), validation at load, migration |
| `pacing_sim.gd` | The headless player for `tools/balance.sh` |

## Controller wiring (engine developer)

```gdscript
# once per fixed step, VISIBLE frames only (hidden / away time never advances politics):
var now := Calendar.resolve_now(state, device_ms, server_ms_or_-1, BUILD_MS)   # ~1/s is enough
var ev := Politics.tick(state, dt, d, {"allowPing": not modal and last_buy_age >= 2.0,
        "nowMs": now, "weekday": dt_dict.weekday, "hour": dt_dict.hour})
for e in ev: match e.ev: ...   # see the event list below
```

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
| `unlockScalePerElection`, `unlockTimeScalePerElection` | partners' `runBananasAtLeast` / `runSecAtLeast` × scale^evolutions |
| `negotiation {demandGapMult}` | Post-election mode: partners ask more often |

### `partners[]`
`id, g (m|f), seats, upkeepPct, demandWeight, threatChance, unlock` (conditions), plus one optional
mechanic each: `priceMult`, `priceGrowth` (Goldknopf, lifetime), `abstain` (Gafni),
`demandKind: ceremony` (Regev), `effects[]` (economy effect types; Smotrich `producerMult`, Levin
`suspicionGainMult`), `onPay {suspicion}` (Golan, Distel), `cannotLeave` + `statusLine` (Deri),
`transfer {to, meterPerSec, fireAt}` (Gotliv), `rebel` (Almog: poach only), `standIn` (Gantz),
`excludes [ids]` (Abbas), `mutedLine` (Distel), `side`, `pollLike`, `lines` / `linesVariants`.

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
`era, evolutionsAtLeast, evolutionsBelow, runBananasAtLeast, allTimeAtLeast, ownedAtLeast {producer,count},
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
  the card leaves the shelf until it ends; the n-th rebuy in a round fades by `fatigue`^n: the
  effect's bonus when it has `mult`, else its duration; `fatigueScales` overrides), `line`
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

## Save v3
`GameState` gained `coalition`, `investigation`, `events`, `album` and `calendar`. Each module owns
its dictionary: `fresh_state()` gives the defaults, `sanitize()` validates at load (unknown ids are
dropped, numbers are clamped, one open message per partner), and `on_election()` resets the round.
A v2 file migrates by gaining fresh sections; a newer file is kept aside (`SaveStore`).
Tests: `tests/unit/test_politics_save.gd`.

## Tuning table (bench-measured; the Designer mirrors it into design/content.json)

See the section "Tuning" below. `tools/balance.sh` prints it.
