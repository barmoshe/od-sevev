# "עוד סבב": FTUE and prompt triggers on the fork (`ftue-flow` + `prompt-trigger-spec`, engine-concrete)

**Owner:** UX Designer · **Consumers:** Game Developer (`game/scripts/ui/ftue.gd`, `main.gd`, `sim/game_state.gd`), Game Designer (tuning values in `design/content.json`), Animator (prompt motion), Audio Director (cue moments) · **Date:** 2026-09-28 · **Rev 4 (2026-09-29, leader select):** the FTUE starts at the leader pick (§8); P0 taps the leader; H1L; LP. **Rev 5 (2026-09-30, manual test A2/A7/B10/B12):** the pre-tap state is the round's screen before its first tap: Row A (the identity chip: face + name; mute; settings) and card 1 (dim) over the teaser rows are up from the pick; the round's name is no longer a toast over the stage; the pre-tap undo chip sits in a navy bar in the ticker slot (`mobile-first-layout.md` §3.3, §5.1.1, §5.9). **Rev 6 (2026-09-30, merge review M1, D62; built 2026-09-30):** until the round's first tap no toast covers the leader: Dubi's pick toast and the fresh toast dock in the lane band under his feet, and the fresh toast waits for the undo chip to go (`mobile-first-layout.md` §5.9, S18).

**Above this file:** `creative-pack/od-sevev/ux/first-minute.md` §2 (approved beats and triggers) and `pitch.md` §5 and §11 (the numbers). This file restates every trigger as a predicate over the fork's **real** state fields, names the fields the developer must add, and says what replaces each of the fork's P1-P7 prompts. Layout references (`§n` of `rtl-map.md`) are the geometry. **Supersedes** the fork's `ux/ftue-flow.md` for od-sevev.

**Design principle (unchanged):** one new thing at a time, zero instruction text in the first minute. The only words read in the first 60 s are Dubi's squawk, one headline and one price. Every prompt is a predicate over player state; the only clocks are *idle* clocks and *affordable-and-ignored* clocks measured in active play time, never wall-clock time since launch.

---

## 1. State vocabulary: first-minute names → fork fields

| first-minute name | Fork field (exists) | New field (developer adds) | Notes |
|---|---|---|---|
| `taps_total` | `state.taps_lifetime` | — | Persistent. |
| `shekels` | `state.bananas` | — | Rename is optional; semantics are shekels. |
| `lifetime_earned` | `state.all_time_money` | — | Persistent across elections. Used by Q1 (cottage, 1,000 ₪) and K3 (spins, 1,500 ₪). |
| `sources_owned` | `Conditions.sources_owned(s)` (sim) | — | Run-scoped (resets on election). Written `owned_total` below. |
| `cost(src1)`, `cost(src2)` | `Economy.producer_cost(s, id, 1)` with ids `intern`, `tree` | — | Fork ids in the pitch §4 order (`ui-strings.json` `producerNames`). |
| `rabbits` | `state.crits_lifetime` | — | H2 forces the first crit. |
| `suitcase_seen` | — | `state.stats["suitcaseSpawned"]` (int, persistent) | Incremented in `GoldenView.spawn()`. |
| `caught` / missed | `state.golden_caught_lifetime`, `state.stats["goldenMissed"]` | — | — |
| `demands_paid` | `state.coalition["paidLifetime"]` (sim, `Coalition`) | — | Persistent. Written `demands_paid_lifetime` below. |
| `seats`, gate | `Coalition.seat_info(s)` → `effective`, `gateSeats`; `Coalition.gate_open(s)` (sim) | — | Written `d.seats ≥ 61` below; implement as `Coalition.gate_open(s)` (it already folds in Gafni's abstainers). |
| `suspicion`, floor, shady count | `Investigation.suspicion(s)` (0-100), `Investigation.floor_pct(s)`, `Investigation.shady_owned(s)` (sim) | — | Written `state.suspicion` below. |
| `playtime_active` | `state.stats["playtimeSec"]` | — | Ticks only in the economy step, so it pauses while hidden (U14) and never counts time away. |
| `stage.unobstructed` | — | `MainController.stage_unobstructed()` | `mode == "main"` and no overlay and no tall tab and no toast over the Suitcase band (rtl-map §4.1). |
| `last_tap_age`, `last_purchase_age` | — | `MainController._last_tap_ms`, `_last_buy_ms` | In play-time ms. |
| `no_modal` | `not overlays.is_open()` | also `not tx.running` | — |
| C1 and U1 gates | `Coalition.c1_ready(s)`, `Coalition.ultimatums_unlocked(s)` (sim) | — | The sim already implements the state halves of C1 and U1; the controller adds the UI half through `ctx.allowPing` (below). |
| `idle` | `Ftue._idle_ms` | — | Advances only while in the stage state (title or main) with no overlay and no tall tab; reset by `on_input()`. |
| hand-off moment | — | `Ftue.handoff_ms` | **Rev 4:** set when the `LEADER_PICK` has faded out after a commit (rtl-map §8.6), not when `shell.html` reports the gate gone (`window.mbHandoffDone` now only enables the picker). **All FTUE clocks start here**, so a player still reading the disclaimer, or the tiles, is never counted as idle. |

### 1.1 Persistent FTUE and reveal flags (`GameState.new_ftue()` and `fresh().ui`)

Replace the fork's `{"p1".."p7"}` with:

```
ftue = {
  "p0": "",            # tap the hat              "" | "done"
  "p1": "",            # first buy                "" | "done"
  "p2": "",            # second card choice       "" | "done"
  "s1": {"state": "", "misses": 0},   # first Suitcase
  "c1": "",            # first chat ping          "" | "toasted" | "done"
  "e1": "",            # first election CTA       "" | "shown" | "done"
  "r2": "",            # round-2 orientation      "" | "done"
  "pk": "",            # coalition agreement hint "" | "done"
  "lp": "",            # leader pick teaching line (F9_PICK) "" | "done"   (rev 4)
}
ui = {
  "rateRevealed": false, "tabsRevealed": false, "seatsRevealed": false,
  "thermoRevealed": false, "dossierRevealed": false, "spinsRevealed": false,
  "cottageRevealed": false, "buyModeRevealed": false, "tabsTouched": false
}
```

`from_dict` keeps its "unknown or broken fields fall back to fresh defaults" rule. `ui` flags are **never reset** by an election or by anything but a full reset: the HUD a player has learned stays put.

---

## 2. What replaces the fork's prompts

| Fork prompt (`ftue.gd`) | Fork form | od-sevev | Form |
|---|---|---|---|
| P1 tap the banana | ticker text `F1_TAP`, banana emphasis, hand after idle | **P0** tap the leader (was: the hat) | Textless: idle loop, then Dubi pecks the tap object (Bibi: the hat; others: their prop), then the hand (§3). It runs in the **pre-tap state** after the pick (rev 4; the title state without its lines), where the ticker does not exist yet. **Rev 5:** Row A (without the counter) and card 1 (dim, the fill at 0) are already on screen, so the tap has a visible goal; the leader is still the one lit, moving object. |
| P2 hire | ticker `F2_HIRE`, hand on the row | **P1** first buy | Card and pill; then Dubi on the card with `DUBI_BUY`; then the hand |
| P3 upgrade | ticker + badge | **K3** spins unlock | Toast `TOAST_SPINS` + tab slot 2 appears. No hand. |
| P4 golden | callout `CALLOUT_GOLDEN` + ticker | **S1** first Suitcase | Textless: slow first flight + sparkle. No callout. |
| P5 evolve seen | ticker + badge on the button | **C2** seats reveal | Textless: seat pips fly to Row B, which appears |
| P6 evolve ready | ticker + hand on the button | **E1** election CTA | The ticker row becomes "עוד סבב!"; Dubi fallback |
| P7 run 2 | two ticker lines | **R2** round-2 orientation | `F7_RUN2` then `F7_RUN2_GATE` on the ticker after the first election |
| `F8_BULK` reveal | ticker line | **B1** buy-mode reveal | Buy-mode row appears at the top of T1 + `F8_BULK` on the ticker |
| — | — | **C1** chat ping, **K1** thermometer, **K2** dossier, **Q1** cottage, **PK** coalition agreement | new |

The fork's `F1_TAP`, `F1_TAP_IDLE`, `F2_HIRE_NUDGE`, `F4_GOLDEN`, `F5_EVOLVE_SEEN` keys stay in `ui-strings.json` as text fallbacks but **are not enqueued** by the od-sevev FTUE.

---

## 3. Trigger table

Columns: **Predicate** is evaluated once per frame by `Ftue.update_view` (as the fork does). **Form** names the node. **Fallback** clocks are play-time clocks that start when the predicate first becomes true. **Done** is the state that retires the prompt forever. Every prompt auto-dismisses the moment the player performs the action.

| ID | Stage | Predicate (fork fields) | Form | Fallback ladder | Done when | Funnel events |
|---|---|---|---|---|---|---|
| **P0** tap the leader | introduce(tap) | `mode == "title" and taps_lifetime == 0 and handoff_ms > 0` (rev 4: "title" = the pre-tap stage after the pick; `handoff_ms` = the pick, §8) | Diegetic: the leader's idle loop (Bibi: wand taps hat, a coin peeks and sinks) + 1 Hz brightness pulse on the **tap object**: the hat for Bibi, the prop at `propMouth` for every other leader (`Magician.emphasize`; static rim under reduced motion). **No text.** The target is the leader's whole hit (rtl-map §4.3), never the prop alone. | **F1** `idle ≥ 3 s` **and Dubi's pick lines are done** (rtl-map §8.6): Dubi pecks the tap object; one coin pops with "+1 ₪" (a demonstration, not credited). **F2** `idle ≥ 9 s` (F1 + 6): the pixel hand (`Ftue.hand`) taps the hat on loop, pointing from the lower-right (`dir "upleft"`, hand at the hat's right side, since a right thumb comes from there). **F3** `idle ≥ 20 s`: the hand stays; the hat pulse doubles to 2 Hz (≤ 3 Hz, photosensitivity rule). No modal, ever. | `taps_lifetime ≥ 1` | `ftue_step_entered{step:"tap"}`, `ftue_first_agency` |
| **I0** idle coin-peek (main mode) | — | `mode == "main" and evolutions == 0 and owned_total < 3 and idle ≥ 20 s and stage_unobstructed()` | The Animator's `idleInvite`: one coin peek every 10 s. **Not** after `owned_total ≥ 3`: from then on tapping is optional and a recurring peek is a nag (rtl-map §4.2). | — | any tap, or the predicate turns false | — |
| **H1** first laugh | — | `taps_lifetime == 1` (edge) | Dubi bubble: the leader's `kit.dubi.squawks.firsttap` (Bibi: `DUBI_FIRSTTAP` "אין כלום! אין כלום!") over the leader for 1.6 s; the ticker fades into the plaza strip's slot and enqueues H1 (deck T25) at `ftue` priority; the counter fades into Row A (rev 5: Row A itself, with the identity chip, mute and settings, is up from the pick) | — | edge fires once | `ftue_step_completed{step:"tap"}` |
| **H2** first rabbit | introduce(crit) | `taps_lifetime == 7 and crits_lifetime == 0` (the 7th registered tap) | `Economy.tap(state, force_crit = true)` pays ×4 (pitch §11 Q5); rabbit hop; ticker H2 (deck T03) | — | edge | — |
| **card 1 reveal** | — | **rev 5:** `picked(s)` (leader select on, a leader installed, no pick pending) **or** `taps_lifetime ≥ 3` (content without leader select) | Card 1 (`producerNames.intern`) on the white field over the dim teaser rows, pill at 40% opacity, fill growing right → left as taps come in (rtl-map §6.1). With leader select it is **up from the pick**, in the pre-tap state (A2: before, the lower half of the first screen was bare stone until tap 3). Its fill growing with each tap is the tap's first visible consequence after the coin. | — | card shown (it never hides again this run) | — |
| **P1** first buy | introduce(buy) | `bananas ≥ cost(intern) and owned_of("intern") == 0 and evolutions == 0` | Pill full, 100% opacity, gold, one brightness pulse; `becameAffordable` cue | **F1** affordable-and-ignored `≥ 5 s` while taps continue: Dubi hops onto the card and squawks `DUBI_BUY` "לקנות! לקנות!". **F2** `+8 s` (13 s): the hand on the card, at the pill's centre, `dir "right"`, pointing at the pill from its right. **F3** after 2 more ignored 8-s windows: the card bounces once each time `bananas` crosses a multiple of the price. | `owned_of("intern") ≥ 1` | `ftue_step_entered{step:"buy"}`, `ftue_step_completed{step:"buy"}` |
| **R1** rate reveal | — | `owned_total ≥ 1` (first time) | Rate line `HUD_BPS` appears under the counter; the taxpayer walks onto the stage; ticker H3 (deck T01) | — | `ui.rateRevealed` | — |
| **P2** the choice | isolate(buy) | `owned_total ≥ 1 and bananas ≥ 0.5 × cost(tree)` | Card 2's name replaces `ROW_LOCKED_NAME` "מקור עלום" (before this, card 2 shows as locked from `owned_total ≥ 1`) | If `owned_total == 1 and bananas ≥ cost(tree)` for 10 s of play: card 2's pill pulses once | card 2 named | `ftue_step_entered{step:"choose"}` |
| **S1** first Suitcase | introduce(catch) | `owned_total ≥ 2 and stage_unobstructed() and stats.suitcaseSpawned == 0 and last_tap_age < 3 s` | Forces the first spawn now (overrides `golden_timer_sec`). First flight right → left, 6.0 s, sparkle trail, whoosh cue (rtl-map §4.1). **No callout text.** | **Missed:** ticker H-miss (deck §G) + `DUBI_MISS`. While `golden_caught_lifetime == 0`, every flight keeps first-flight speed and the sparkle. **After 3 misses** (`stats.goldenMissed ≥ 3`): the next one hovers mid-band for 1 s. | `golden_caught_lifetime ≥ 1` | `ftue_suitcase_caught`, `ftue_suitcase_missed{n}` |
| **C1** chat ping | introduce(pay partner) | `Coalition.c1_ready(s)` (= 3 sources owned, 60 ₪, group not opened) **and** `ctx.allowPing` = `no_modal and last_purchase_age ≥ 2 s and Toasts.idle() and no Dubi squawk playing` | Chat toast (Ben Gvir avatar, name, deck preview) in the toast dock; **at the same moment** the tab bar appears with slots 1 and 3 (`ui.tabsRevealed`), slot 3 carrying badge "1"; ping cue; 20 ms vibration where supported | **F1** toast dismissed unopened and `bananas ≥ 120`: the badge bounces once and the tab label goes bold. **F2** then, every 60 s of play while `bananas ≥ 2 × demand`: one badge bounce, at most 3 times. (F2 of first-minute, "tap the seats bar", cannot apply yet: Row B appears only after C2.) | chat opened (`c1 = "toasted"`) and first demand paid (`c1 = "done"`) | `ftue_step_entered{step:"coalition"}`, `ftue_step_completed{step:"coalition"}` |
| chat open cascade | — | T3 opened the first time | System lines in order: `CHAT_SYS_CREATED`, then `CHAT_SYS_JOINED_*` per member (≤ 250 ms apart; instant under reduced motion), then `CHAT_TYPING_M` for 1.2 s, then the first demand bubble with `CHAT_PAY` "סגרנו · 60 ₪" | — | — | — |
| **C2** seats reveal | isolate | `demands_paid_lifetime == 1` (edge) | Seat pips fly from the pay pill to Row B, which appears at the seat value (34/61, pitch §5). During the blackout the numeral node is absent and the stamp shows (rtl-map §3). The pay pill becomes the `CHAT_PAID` stamp; the auto-reply `CHAT_REPLY_1` appears on the left. | — | `ui.seatsRevealed` | `ftue_seats_revealed` |
| **U1** first ultimatum (gate) | recombine(pay + time) | `Coalition.ultimatums_unlocked(s)` (= `paidLifetime ≥ 2` and `stats.playtimeSec ≥ 180`) | The gate only *allows* the designer's scheduler to send ultimatums. Timer 90 s, paused while hidden. | Expired: `CHAT_SYS_LEFT_*` with `CHAT_SYS_REJOIN` (1.5× the missed demand). Every loss is recoverable. | — | `ftue_ultimatum_shown`, `_paid`, `_expired`, `_rejoined` |
| **K1** thermometer | introduce(heat) | `Investigation.shady_owned(s) ≥ 1`, first time (the shady ids are the keys of `content.court.sources`) | Thermometer slides in from the left edge and ticks up once (`ui.thermoRevealed`) | — | flag | `ftue_suspicion_revealed` |
| **K2** dossier | — | `Investigation.suspicion(s) > 0` first time, **and** ≥ 3 registered actions or 5 s of play since K1 | Toast `TOAST_DOSSIER` "נפתח לך תיק."; tab slot 4 appears (`ui.dossierRevealed`) | — | flag | — |
| **K3** spins | introduce(spin) | `all_time_money ≥ 1,500` **and not inside C1** (no toast, open chat or unpaid first demand: `c1 == "done"` or 10 s of play since the C1 toast) | Toast `TOAST_SPINS`; tab slot 2 appears with badge = affordable spins (`ui.spinsRevealed`) | If slot 2 is untouched for 90 s of play while a spin is affordable: badge bounces once | flag + T2 opened once | `ftue_step_entered{step:"spins"}` |
| **Q1** cottage | — | `all_time_money ≥ 1,000` | The cup appears in Row A (`ui.cottageRevealed`); first pixel drops; ticker H-cottage (deck T02). It re-fires at every ×10 (10,000, 100,000 …) as a pixel drop. | — | flag | — |
| **B1** buy mode | — | any `owned_of(id) ≥ 10`, or `evolutions ≥ 1` (the fork's rule) | Buy-mode row 0 appears in T1 (rtl-map §6.1); ticker `F8_BULK` | — | `ui.buyModeRevealed` | — |
| **E1** first election | introduce(prestige) | `Coalition.gate_open(s) and evolutions == 0` | The ticker row becomes the gold `HUD_CTA_ELECTION` "עוד סבב!" (rtl-map §5.3); seats bar gold rim; fanfare cue | Ignored for 60 s of play: Dubi squawks `DUBI_ELECT` "בחירות! בחירות!" once, then again every 120 s of play, at most 3 times | O3 confirmed | `ftue_first_prestige` |
| **R2** round 2 | — | `evolutions == 1` and `EvolveTx` done and the O3b flash closed **and the round-2 pick committed** (rev 4) | Ticker `F7_RUN2` (`{pmult}`), then `F7_RUN2_GATE` | — | `r2 = "done"` | — |
| **PK** coalition agreement | — | `evolutions ≥ 1 and thumbs_available() ≥ cheapest clause cost and pk == ""` | Toast `F_PERKS_HINT`; `!` badge on the T3 pinned bar and on tab slot 3 | — | agreement sheet opened once | — |

### 3.1 Order, spacing and suppression (replaces `ORDER` and the spacing rule in `ftue.gd`)

- **One prompt at a time.** Priority: P0 > P1 > C1 > S1 > E1 > P2 > K2 > Q1 > K3 > B1 > R2 > PK. (LP lives inside `LEADER_PICK` and H1L is an edge, so neither is in the queue; §8.) A higher prompt may pre-empt a lower one's *fallback* ladder; it never cancels an animation mid-flight.
- **Spacing.** A new prompt (not an edge like H1-H3 or C2) waits for ≥ 3 registered actions since the previous one resolved, exactly as the fork's `_actions >= 3`. P0 and S1 are exempt (as the fork exempts P1 and P4).
- **Toast queue.** One toast at a time; each shows ≥ 3 s (or until tapped), 1 s gap between toasts. A toast never spawns while its rect would sit over a Suitcase in flight (the dock is at the stage top, so in practice only the 2-line dock at the floor viewport matters).
- **Tap-burst rule.** No overlay auto-opens while the last tap is < 1 s old, except O1 at launch (first-minute §1.2 rule 3). Toasts may appear during a burst.
- **Tall tabs and overlays.** While one is open, no prompt fires and every fallback clock pauses. Exception: the chat cascade runs inside T3.
- **Blackout (23.10 00:00 to 27.10 22:00).** The FTUE is unchanged. C2 reveals the stamp instead of the numeral. No prompt text contains a seat number.
- **Audio seam.** The chat ping never plays during a Dubi squawk: it waits ≥ 300 ms after the squawk ends (Audio Director owns the duck).

### 3.2 First-minute trace on the fork (pitch §11 numbers)

| t after hand-off | Player state | Fires |
|---|---|---|
| 0 | the pick has committed (rev 4: t = 0 is the pick, §8); pre-tap stage, `taps_lifetime 0` | P0 (idle loop); Row A with the identity chip (the face and name: the round's "lower third", rev 5) and card 1 (dim) are up; the undo bar holds the ticker slot for 5 s; Dubi's `DUBI_LEARNED` plays over the first ~2.5 s (rev 6: in the lane band under the leader's feet, never over him), and P0's F1 waits for it |
| ~2 | tap 1 | H1 (Dubi, ticker, counter) |
| ~3 | tap 3 | (rev 5: card 1 is already up; its fill is at 3/15) |
| ~5 | tap 7 | H2 (rabbit ×4) |
| ~8-10 | tap 12: 15 ₪ | P1 (pill gold) |
| ~11 | first buy | R1 (rate line, taxpayer walks on) |
| ~15-30 | `bananas ≥ 0.5 × cost(tree)` | P2 (card 2 named) |
| ~25-40 | `owned_total ≥ 2` and tapping | S1 (first Suitcase) |
| ~40-50 | `owned_total ≥ 3`, 60 ₪ | C1 (toast + tab bar) |
| ~50-60 | first demand paid | C2 (Row B at 34/61) |
| **60** | — | **HUD: counter + rate, seats bar, ticker.** No thermometer, no cottage, no spins yet. |
| ~1:30 | 1,000 ₪ lifetime | Q1 (peripheral cup; accepted by the Game Designer as landing before spins) |
| ~2:00-2:30 | 1,500 ₪ lifetime, C1 settled | K3 |
| ~3:00 | first shady source | K1, then K2 |
| 3:00+ | `demands_paid ≥ 2`, 180 s | U1 gate open |
| ~7-9 min | 61 seats | E1 |

**Strip test.** Remove every toast, Dubi fallback and hand: the player still reaches first agency by reading the world (one moving, glowing object, and below it one dim card with one price; the card fills as they tap). None of the prompts above carries the load alone.

**Time to first agency:** warm ≈ 2-3.5 s after the disclaimer tap; cold on 4G ≤ 7 s; worst case with F1 and F2 ≤ 16 s. All within the studio's 30-s web budget.

---

## 4. Returning, reset and election behaviour

| Situation | FTUE behaviour |
|---|---|
| Reload mid-FTUE | Every prompt and reveal state is in `state.ftue` / `state.ui`, saved on every purchase and payment (U14). Nothing re-teaches. If `leaderPickPending`, the picker shows first. If `taps_lifetime == 0` the game re-enters the pre-tap state with the saved leader (no second pick) and P0 restarts its idle clock from the new hand-off. |
| After an election | `LEADER_PICK` (after) follows `EVOLVE_TX` and the O3b flash (§8). `ui` flags persist, so the HUD, tabs and thermometer stay where they were. Card 1 shows at once (the tap-3 wait applies only when `evolutions == 0`). P1, P2, S1, C1 never re-fire. The chat is cleared with `CHAT_SYS_CLEARED` ("ניקית את הצ׳אט…"). R2 fires once after the first election, after the pick. |
| After a reset | Fresh `GameState`: `LEADER_PICK` (first), then the full FTUE runs again. The disclaimer is not shown again (its version flag lives in `localStorage`, outside the save). |
| Away ≥ 60 s | O1 return card first; FTUE fallback clocks were paused (they run on play time). |
| Share-link entry, new player | The deep-link toast `SHARE_DEEPLINK` is queued **after** H1 (it would otherwise be text before first agency). |

---

## 5. Accessibility inside the FTUE

| Setting / need | Change |
|---|---|
| Reduced motion | Hat pulse → static bright rim; Dubi flies → appears; the hand does not bob (static, as the fork's `ftueHandBobPx` = 0); card bounce → a 200 ms brightness step; seat pips → cross-fade of the bar; the Suitcase still flies (essential) at ×0.8 with no bob. |
| Sound off (`בשקט`) | Every cue has a visual twin: ping → toast + badge; whoosh → sparkle; squawk → bubble. |
| Large text | Toasts use the 2-line dock; Dubi's bubble grows; no prompt text is longer than its box (`string-budgets.json`). |
| Keyboard (desktop) | Space/Enter satisfies P0 and counts as a registered tap; `S` catches the Suitcase for S1; `3` opens the chat for C1. The hand and Dubi prompts still show (they point at the object, not at a key). |
| Motor | No prompt requires a hold, a rapid tap or a timed response. The ultimatum (U1) is the first timer and arrives only after 3 minutes, with 90 s and a recoverable loss. |

---

## 6. Funnel events (plumbing by the developer, per first-minute §2.4)

Every event carries: `step`, `t_since_handoff_ms`, `taps_lifetime`, `owned_total`, `evolutions`, `reduced_motion: bool`, `sound: "on" | "off"`, `large_text: bool`, `viewport: "WxH"`.

| Event | When |
|---|---|
| `ftue_step_entered` | A prompt's predicate first becomes true (`step` ∈ tap, buy, choose, coalition, spins) |
| `ftue_step_completed` | Its done condition |
| `ftue_step_fallback` | Each fallback rung fires (`rung` 1-3) |
| `ftue_first_agency` | `taps_lifetime` becomes 1 |
| `ftue_suitcase_caught` / `ftue_suitcase_missed` | S1 outcomes (`n` = miss count) |
| `ftue_seats_revealed` | C2 |
| `ftue_suspicion_revealed` | K1 |
| `ftue_ultimatum_shown` / `_paid` / `_expired` / `_rejoined` | U1 family |
| `ftue_first_prestige` | E1 confirmed |
| `ftue_abandoned_at_step` | `pagehide` while a step is entered but not completed |

---

## 7. Tuning (Game Designer's numbers; they live in `design/content.json`)

| Value | Number | Consumed by |
|---|---|---|
| Tap value | +1 ₪ | P0, P1 timing |
| First source price (`intern`) | 15 ₪ (tap 12) | P1 |
| Scripted first rabbit | tap 7, ×4 | H2 |
| Later rabbits | 2% chance, ×10 (spin S11 raises it) | — |
| First demand | fixed 60 ₪ | C1 predicate |
| Later demands | 45 s of current ₪/s | — |
| Seats after the first partner | 34/61 | C2 |
| Ultimatum gate | `demands_paid ≥ 2` and 180 s of play | U1 |
| Ultimatum timer | 90 s, paused while hidden | U1 |
| Rejoin price | 1.5 × the missed demand | U1 fallback |
| Spins unlock | 1,500 ₪ lifetime (was 300: at 300 the unlock landed inside the first chat ping, two new things at once) | K3 |
| Cottage Index | 1,000 ₪ lifetime, then every ×10 | Q1 |
| C1 sources / first demand | `coalition.openAtSourcesOwned` 3, `coalition.firstDemandPrice` 60 | C1 (read by `Coalition.c1_ready`) |
| U1 gate | `coalition.ultimatum.minDemandsPaid` 2, `.minPlaySec` 180 | U1 (read by `Coalition.ultimatums_unlocked`) |
| Suspicion floor after election n | min(5% × n, 40%) | thermometer hatch, `DOS_SUSP_FLOOR` |
| First election | ≈ 7-9 min | E1 |

If a tuning value moves, the predicates above do not change; only the timing in §3.2 does.

---

## 8. Leader select in the FTUE (rev 4, 2026-09-29; `design/leader-select-spec.md`, `rtl-map.md` §8)

**Principle:** the pick is the game's first decision, and it is **pre-verb and textless**:
- the tiles are faces and names;
- the blurb shows only while a finger is on a tile;
- the only line read by default is the one-sentence equal-footing promise.

It takes the tap the title state already needed (the WebAudio gesture), so the first minute gains **0 taps**. The clocks start after it (§1 `handoff_ms`), so the §3.2 timings are unchanged from t = 0.

| ID | Stage | Predicate | Form | Done when | Funnel |
|---|---|---|---|---|---|
| **PK0** the first pick | introduce(choose) | first launch or after a reset, `mode == "pick"` | `LEADER_PICK` (first). Initial focus on הפתעה; no leader is pre-selected. **No fallback ladder**: a player who stalls on eight faces has הפתעה at the centre and a 5 s undo after any tap (spec §1's shaky claim; watch the first playtest's `ms_to_pick`). | a commit | `leader_pick_shown`, `leader_pick_committed` |
| **H1L** a leader's first laugh | — | the first registered tap of a round whose leader has `leaders[id].taps == 0` (for the very first round this *is* H1) | Dubi's bubble with the leader's `kit.dubi.squawks.firsttap` over the leader for 1.6 s, while their coins pour. At the pick Dubi said only `DUBI_LEARNED`, so the squawk lands on the coin spray (rtl-map D31). | edge, once per leader | — |
| **LP** you can switch | isolate(choose) | the first `LEADER_PICK` (after) with `evolutions == 1` and `ftue.lp == ""` (a migrated v3 save: its first after-election picker) | The strip's default line is `F9_PICK` "בכל סבב בחירות אפשר להחליף ראש רשימה. הבסיס נשאר." instead of the disclaimer. The fresh chip above says what switching pays. No toast: the line sits where the choice is, before it is made. | that picker commits (`lp = "done"`) | `ftue_step_completed{step:"switch"}` |
| **R2** round 2 | — | as §3, after the pick | unchanged (`F7_RUN2`, `F7_RUN2_GATE`) | — | — |

**What each variant teaches:**
- **The first picker** teaches nothing about switching; there is nothing to switch from yet.
- **The second picker** teaches the whole rule in one line (LP) plus one chip, in context.
- **Every later picker** repeats only the chip.

**Timing seams:**
- **The pick sequence** (rtl-map §8.6: the identity chip with Row A, then Dubi's line, then the fresh toast) runs before P0's F1 can fire. P0's F1 requires "Dubi's pick lines done", so Dubi never pecks the prop while he is still talking.
- **The undo chip** is gone by P0's F2 (9 s).
- **C1's chat ping and every other prompt** wait on their own predicates, all ≥ 40 s in.

**Accessibility:** the pick holds no timer (the undo's 5 s is optional, and the undo is recoverable by playing on), no hold is required (the long-press card has the keyboard key `I` and is optional), and it has a keyboard path and a reduced-motion path (rtl-map §8.5). Sound off: the pick sting's visual twin is the selection pop and rim.
