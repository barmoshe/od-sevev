> **Superseded for "עוד סבב" (2026-09-28):** this is the Monkey Bananas v2 record the fork inherited. Implement from ftue.md. Kept for engine history only.

# ftue-flow + prompt-trigger-spec — Monkey Bananas

Owner: UX Designer. Consumers: Game Developer (prompt state machine, persistence), 2D Artist (pointer-hand sprite), Animator (pointer bob, callout motion), Audio Director (optional prompt cue; none required).
Coordinates are in [`hud-layout.md`](hud-layout.md). Copy strings (the `F_*` IDs) are in [`number-and-copy.md`](number-and-copy.md) §6.

## 1. Principles for this game

- **The world teaches; prompts only confirm.** Several things are self-teaching:
  - The Big Banana is the only gameplay-interactive object until the intern row reveals at 7.5 bananas (mechanic-spec §7).
  - The intern row's pill reads "BUY" the moment it is affordable.
  - The Golden sparkles and moves.
  - The Evolve button carries its own progress readout.

  Prompts are small (a pointing hand plus one ticker line). None is modal, and none blocks input.
- **Every trigger is a player-state predicate** in the studio vocabulary (`state.flag`, `mechanic_attempts_count`, `prompt.shown_count`, value comparisons on save fields). There is **no wall-clock trigger**. The single idle predicate (`idle_for`) is used only as an escalation fallback.
- **Auto-dismiss on demonstration.** Each prompt clears the frame the player performs the action, whether or not they noticed the prompt.
- **One prompt visible at a time.** Priority: P1 > P2 > P4 > P3 > P5 > P6. A lower-priority prompt waits (its trigger stays latched) until the higher one resolves. P4 (Golden) pre-empts because it is time-limited: an active P3 hand hides while P4 shows and returns after.
- **Spacing is by action, not by time.** A new non-Golden prompt may not appear until the player has made ≥ 3 registered actions (taps or purchases) since the last prompt resolved.
- **The ticker carries the onboarding voice.** FTUE lines outrank milestone headlines, which outrank ambient lines. A pre-empted headline goes back to the front of its queue.

## 2. Pre-gameplay flow (enumerated)

| # | Step | Latency budget | Notes |
|---|---|---|---|
| 1 | Page load plus Phaser boot | ≤ 1.5 s on 4G (the Game Developer's budget) | Vercel static serve |
| 2 | `BOOT`: bake procedural textures, font and audio buffers | ≤ 500 ms. Show "LOADING" after 300 ms | No player-visible choice |
| 3 | `TITLE` (first launch only) | 0 s: waits for the player | Unlocks WebAudio. **t = 0 is this first input.** |

There is no splash, login, ad or consent step (no third-party trackers, no monetization). Returning players skip step 3.

## 3. Time-to-first-agency

- **First meaningful agency** is the first registered Big Banana tap that awards bananas.
- **Budget: ≤ 30 s from first input** (web instant-play). **Designed: 0 s.** The TITLE CTA reads "TAP THE BANANA", and the banana is already in its gameplay position. If the start tap lands on the banana hit area (272×272, about 18% of the stage), it *is* tap #1.
- If the start tap misses the banana, P1 appears on the next frame. Expected agency then lands in under 3 s.

## 4. Introduce → isolate → recombine

| Mechanic | Introduce (alone, no pressure) | Isolate (one stable obstacle) | Recombine (with a prior mechanic) |
|---|---|---|---|
| Tap | TITLE: only the banana, with CTA plus P1 | 0–7.5 bananas: only the banana is interactive; each tap is +1 | Tap to afford the intern (P2) |
| Buy producer | Intern row: the only revealed row, first affordable at 15 bananas | Save up for the tree (revealed at 60 run-bananas; a cost the player can see and wait for) | Tap + buy + passive income, from about 0:34 |
| Upgrade | Glove appears at 50 run-bananas. P3 when first affordable (100), via the tab badge | One upgrade on the shelf, one tap | Upgrade effects on tap/production (TAP ×2 is felt on the next tap) |
| Golden | First spawn at 75 s into the run, after the purchase loop is established; P4 callout | One Golden, 10 s, no penalty for a miss | Buffs combine with tapping (Tap Frenzy) or with producers (Frenzy) |
| Evolve | Reveal at 250K all-time as a *disabled* button with progress (P5); tapping it opens the `preview` overlay | Watch the progress readout fill toward 10 (it cannot fire early, so nothing can go wrong) | Gate opens (P6), then run 2 with ×2.0 and the doubling rule shown as "NEED 10 NEW THUMBS" |

No two mechanics share an introduce beat. On the engaged-player timeline: tap at 0:00, intern at about 0:01–0:05, glove affordable at about 0:25, Golden at 1:15, Evolve reveal at about 7–8 min, gate at about 11 min. **The buy-mode toggle** is revealed when any producer is owned ≥ 10 (about 1:00–1:30). It gets a ticker line only (`F8_BULK`), no prompt.

## 5. prompt-trigger-spec

Persistence: all keys live in the save object under `ftue.*`. They **survive Evolve**, are **cleared by RESET SAVE**, and are written on the frame the state changes (an immediate save is not required; the next autosave is fine).

A "hand" is the 16×16 pointer-hand sprite drawn ×4 (64×64) at z 70.
- Directions come from the sprite `ui_pointer`: frame 0 points **up** and frame 1 points **up-left**. Rotations are multiples of 90° only (pixel-safe).

  | Dir | Frame | Rotation (clockwise) | Flip | Used by |
  |---|---|---|---|---|
  | `↑` | 0 | 0° | — | P5, P6 |
  | `→` | 0 | 90° | — | P2, P3 stage B |
  | `↓` | 0 | 180° | — | P3 stage A |
  | `←` | 0 | 270° | — | (spare) |
  | `↖` | 1 | 0° | — | P1 |
  | `↗` | 1 | 0° | flipX | (spare) |
  | `↙` | 1 | 0° | flipY | (spare) |
  | `↘` | 1 | 0° | flipX + flipY | (spare) |

  Positions given in the prompts are the top-left of the 64×64 drawn box **after** rotation (a rotation about the centre keeps the box in place).
- Motion: bob 8 px toward the target at ≤ 1 Hz (the Animator owns the curve). **Reduced motion: static, no bob.**
- Input: the hand is non-interactive; input passes through it.

### P1 — Tap the banana
| Field | Value |
|---|---|
| Trigger | `state.scene == MAIN AND tapsLifetime == 0 AND NOT ftue.p1 == 'done'` |
| Shows | Hand `↖` at 448,448 (its fingertip at the banana's lower-right, inside the hit area) + ticker `F1_TAP` |
| Auto-dismiss | first registered banana tap (`tapsLifetime ≥ 1`) → `ftue.p1 = 'done'` |
| Failure branch | L2: `mechanic_failures_count(stageTapOutsideBanana, ">=", 2)` → the Big Banana gets a 1-art-px outline pulse (reduced motion: static outline) and `F1_TAP` re-queues once. L3: `idle_for(8) AND tapsLifetime == 0` → `F1_TAP_IDLE` once. Nothing further: the banana is the only affordance and never gets blocked |
| Funnel | `ftue_step_entered{p1}`, `ftue_first_agency{msSinceStart}`, `ftue_step_completed{p1}` |

### P2 — First producer
| Field | Value |
|---|---|
| Trigger | `bananas >= cost(intern, 1) AND owned.intern == 0 AND evolutions == 0 AND ftue.p1 == 'done' AND NOT ftue.p2 == 'done'` |
| Shows | Tab forced to PRODUCERS **only if** the player has not touched the tabs yet. Hand `→` at 440, rowY(intern)+16, pointing at the pill (row 0 → 440,844). Ticker `F2_HIRE` |
| Auto-dismiss | `owned.intern ≥ 1` (bought by any path) → `ftue.p2 = 'done'` |
| Failure branch | L2: `bananas >= 2 × cost(intern,1)` still unbought → the row border pulses (reduced motion: static 1-art-px highlight border) and `F2_HIRE` re-queues. L3: `bananas >= 4 × cost(intern,1)` → `F2_HIRE_NUDGE` once. After that no further escalation; the hand stays until bought |
| Funnel | `ftue_step_entered{p2}`, `ftue_step_completed{p2, bananasAtBuy}` |

### P3 — First upgrade
| Field | Value |
|---|---|
| Trigger | `anyUpgradeAffordable AND upgradesBoughtLifetime == 0 AND NOT ftue.p3 == 'done'` (needs a new save counter `upgradesBoughtLifetime`, persistent) |
| Shows | **Stage A** (PRODUCERS tab active): hand `↓` at 364,652 over the UPGRADES tab, badge visible, plus ticker `F3_UPGRADE`. **Stage B** (UPGRADES tab active): hand `→` at 440, rowY(cheapest affordable)+16 |
| Auto-dismiss | Stage A → B when the UPGRADES tab is selected. Done when `upgradesBoughtLifetime ≥ 1` → `ftue.p3 = 'done'` |
| Failure branch | If the player switches back to PRODUCERS, return to Stage A (no new ticker line). If `mechanic_attempts_count(buyProducer, ">=", 5)` happens while Stage A is showing and no tab switch occurs, hide the hand, keep the numeric badge, and set `ftue.p3 = 'badge-only'`. The badge alone is sufficient, and it avoids nagging a player who is choosing not to upgrade yet. That player's first tap on the UPGRADES tab then sets `ftue.p3 = 'done'` with no hand |
| Funnel | `ftue_step_entered{p3}`, `ftue_step_skipped{p3, reason: badge-only}`, `ftue_step_completed{p3, upgradeId}` |

### P4 — First Golden Banana
| Field | Value |
|---|---|
| Trigger | `goldenOnScreen AND goldenCaughtLifetime == 0 AND ftue.p4.shown < 3 AND NOT ftue.p4.state == 'done'` |
| Shows | Callout ×3 "CATCH IT!" (outlined text, no panel), centred at `(golden.x, golden.y − 88)`, following the Golden each frame. The x of the centre is clamped to [96, 624]. If `golden.y − 88 < 176`, it is placed at `golden.y + 72` instead. Plus ticker `F4_GOLDEN`. `ftue.p4.shown += 1` on show |
| Auto-dismiss | caught → `ftue.p4.state = 'done'`. The regular `h_first_golden` headline follows |
| Failure branch | Despawned uncaught → callout gone, ticker `F4_MISSED`. Re-arms on the next Golden while `shown < 3`. After the 3rd miss → `ftue.p4.state = 'done'` (stop teaching; missing is legal and costless) |
| Funnel | `ftue_step_entered{p4, attempt}`, `ftue_step_completed{p4, attempt}`, `ftue_abandoned_at_step{p4}` after 3 misses |

### P5 — Evolve introduction (reveal at 250K)
| Field | Value |
|---|---|
| Trigger | `allTimeBananas >= prestige.showEvolveButtonAtAllTimeBananas AND evolutions == 0 AND NOT ftue.p5 == 'done'` |
| Shows | The Evolve button reveals (disabled, "6/10"). Hand `↑` at 460,124, pointing at the button from below (top-bar overlap is allowed at z 70). Ticker `F5_EVOLVE_SEEN` |
| Auto-dismiss | tap on the Evolve button → opens `EVOLUTION` in `preview`, which *is* the lesson: "NEED 10 NEW THUMBS", "EACH EVOLUTION MUST AT LEAST DOUBLE YOUR THUMBS", the progress bar, and the RESETS/KEEPS lists. Then `ftue.p5 = 'done'` |
| Failure branch | `mechanic_attempts_count(buyAny, ">=", 3)` since the hand appeared → hide the hand, show a "!" badge on the button (a 32×32 chip at 564,20, ×3 "!" centred, inside the Evolve visual and hit rects), set `ftue.p5 = 'badge'`. The badge persists until the first overlay open → `'done'` |
| Funnel | `ftue_step_entered{p5}`, `evolve_preview_opened`, `ftue_step_completed{p5}` |

### P6 — Gate opens (first time)
| Field | Value |
|---|---|
| Trigger | `pendingThumbs >= needed AND evolutions == 0 AND NOT ftue.p6 == 'done'` |
| Shows | The button switches to enabled ("EVOLVE!", "+10"). Hand `↑` at 460,124. Ticker `F6_EVOLVE_READY` |
| Auto-dismiss | opening `EVOLUTION` (the `ready` state) → `ftue.p6 = 'done'`. BACK is fine: the enabled button keeps signalling on its own (raised plus "!"). The player is never pushed to evolve |
| Failure branch | `mechanic_attempts_count(buyAny, ">=", 5)` with no open → hide the hand and set `'done'`. The raised button and the "EVOLVE!" label remain the persistent signal |
| Funnel | `ftue_step_entered{p6}`, `ftue_step_completed{p6}`, `evolve_confirmed` (from screen-graph) |

### P7 — Run-2 orientation (not a hand; ticker only)
| Field | Value |
|---|---|
| Trigger | `EVOLVE_TX` finished `AND evolutions == 1 AND NOT ftue.p7 == 'done'` |
| Shows | Ticker `F7_RUN2` (dynamic multiplier), then `F7_RUN2_GATE` (dynamic next "needed"). This pre-empts `h_evolve_1`, which plays next |
| Dismiss | Both lines played once → `'done'` |

### Non-prompt reveals (ticker lines only; the flag lives in `ui.*`)
| Reveal | Condition | Line | Flag |
|---|---|---|---|
| Buy-mode toggle | any `owned ≥ 10` or `evolutions ≥ 1` | `F8_BULK` | `ui.buyModeRevealed` |
| Save disabled | `localStorage.setItem` throws | `F_NO_SAVE` (once per session) | session only |
| Save unreadable | parse or version failure on load | `F_SAVE_CORRUPT` (once) | — |

## 6. Modal-strip trace (no prompt is load-bearing)

Remove P1–P7 and every FTUE ticker line, and walk through again:
1. The TITLE says "TAP THE BANANA", and the banana is the largest object, dead centre, with a hover cursor on desktop. The player taps it, and agency is reached.
2. At 7.5 bananas the intern row changes from "???" to a named row. At 15 its pill turns raised with the word "BUY". The player taps, and the purchase is learned from the label.
3. The glove appears in the UPGRADES tab. The numeric badge "1" is the signal, and a tab with a number reads as "something here".
4. The Golden is sparkly, moves and has a distinct hue, which draws attention by salience. Missing it costs nothing.
5. Evolve appears with "6/10" and a bar. Tapping it opens the overlay, which is itself the explanation: the gate rule, what resets and what persists.

**Result: first agency and the full loop are reachable with every prompt stripped.** The prompts shorten discovery; they are not the teaching surface. The one reliance on text is the TITLE CTA, which is diegetic signage on the play surface rather than a tutorial overlay.

## 7. Funnel event manifest (names only; developer plumbing per I6)

`ftue_step_entered{step}`, `ftue_step_completed{step, ...}`, `ftue_step_skipped{step, reason}`, `ftue_first_agency{msSinceFirstInput}`, `ftue_abandoned_at_step{step}`. Every event carries `reducedMotion: bool` and `inputModality: touch|mouse|keyboard`, so accessibility paths stay measurable (per objection-protocol example 3).
