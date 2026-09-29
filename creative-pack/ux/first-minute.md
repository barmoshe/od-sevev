# "עוד סבב": the first minute (UX chrome, flows and microcopy)

**Owner:** UX Designer · **Pack:** `artifacts/creative-pack/od-sevev` · **Date:** 2026-09-28
**Inputs:** `../brief.md`, `../brief-round2.md` (round 2 wins where they differ).

**Typed artifacts inside this file:**

| Section | Typed artifacts |
|---|---|
| §1 | `screen-graph`, `navigation-contract` |
| §2 | `ftue-flow`, `prompt-trigger-spec` |
| §3 | `hud-layout` |
| §4 | the chat-tab layout (ad hoc: `chat-thread-spec`) |
| §5 | share assets (ad hoc: `share-kit`) |
| §6 | disclaimer and blackout |
| §7 | `settings-spec` plus the `accessibility-spec` minimums |
| §8 | the Hebrew slice of `localization-layout-spec`, as the microcopy table |

**Monetization:** there is no `monetization-flow`. The game sells nothing: no ads, no in-app purchases, and no prizes (brief red line). That is also stated in the About screen.

**Engine revision (2026-09-28).** This file is revised for the Godot 4.7 web fork, per `engine/feasibility.md` O-U1-O-U3 and the notes U2, U3, U7, U9 and U13. The HTML surfaces are the disclaimer, the returning-player splash, the hand-off bar and About; everything else is canvas.

**Reconcile wave (2026-09-28).** This file now has the Game Designer's objections O1-O9 and C1 from `voice/review-designer.md` applied, along with the seam resolutions S1-S12. My own review of the copy deck is in `voice/review-ux.md`.

**Wireframe:** [`hud-wireframe.png`](hud-wireframe.png) has three frames:
- **A:** the first seconds.
- **B:** the steady-state HUD.
- **C:** the coalition chat.

The colours in it are functional tokens that have been contrast-checked (§7.3). The final art belongs to the 2D Artist.

**Who owns what:**
- **I own:** chrome, labels, system lines, the disclaimer, share texts, and the receipt and result card copy.
- **The Game Designer's copy deck owns:** headlines, Dubi's lines, the names of sources, spins and partners, the partners' messages, and excuses.

Where this file shows a line from the Game Designer's domain, it is marked `[GD]`. That line is either a placeholder or the brief's own wording.

### Documented assumptions

| # | Assumption | Why |
|---|---|---|
| A1 | The game is a web game (PWA-capable) opened from a shared link, and it plays in the phone's browser. Home-screen install is optional. | The brief asks for share previews and a home-screen icon. |
| A2 | Design viewport: **390×844 CSS px**, portrait. On iPhone 12-15-class phones, CSS px equal pt. Safe areas are designed for the worst case: top 59 (Dynamic Island), bottom 34. The minimum supported size is 360×740 (§3.6). | Studio baseline (I4). |
| A3 | Hebrew is the only locale. The Hebrew budgets in §8 are the whole localization contract, so there is no expansion table for other locales. | — |
| A4 | Progress is saved on the device only. There are no accounts. | Keeps first launch at zero forms. |

---

## 1. Screen graph and navigation contract

**IA pattern: hub and spoke.** The hub is the **stage** (the Magician and the HUD). The four tabs are *lateral panels* attached to the hub, not pushed screens. Overlays sit on top of the hub. Depth from the hub is **2 at most**, so nothing sits three layers deep. To keep that true, the source list lives *inside* About rather than one level below it.

```
                ┌──────────┐   first launch only / disclaimer version bump
 (link/icon) ──►│ N0 טוען   │──────────────►┌──────────────────┐
                └────┬─────┘                │ N1 Disclaimer     │  [עם סאונד] [בשקט]
                     │ returning            └────────┬─────────┘
                     ▼                               ▼
   ┌──────────────────────────── N2 STAGE (hub) ─────────────────────────────┐
   │ title state (first launch / after reset) ──tap Magician──► play state    │
   │ Panel tabs (lateral, no history push): T1 מקורות · T2 ספינים (short)      │
   │                                        T3 קואליציה · T4 תיקים (tall*)     │
   └───┬──────────┬──────────┬──────────┬───────────┬──────────┬────────────┘
       │          │          │          │           │          │
   O1 return  O2 court    O3 election  O6 headline  O7 settings  one-time: O11 blackout,
   (modal)    day (non-   card (modal) card (from    (sheet, ⚙)   O12 election night
              modal card    │           ticker)       │
              ⇄ chip)       ▼                         ├─► O8 About (+ sources inline)
                          O3b Dubi flash              └─► O10 Reset confirm (destructive)
                            │
   T4 תיקים ─► O4 receipt · O5 result card · O13 album      (also offered after O3b)
```
\*A *tall* tab covers the stage. HUD rows A and B stay visible above it.

### 1.1 Node table (locatedness, exits, back)

| Node | Kind | How the player knows where they are | Visible exits | Host back (Android back, browser back, iOS edge swipe) |
|---|---|---|---|---|
| N0 splash (returning players only) | full, **HTML** | Wordmark plus a loading line | none (auto) | Leaves the page (nothing to lose) |
| N1 disclaimer | full, first launch, **HTML** (`shell.html`; the engine loads behind it) | Title "רגע לפני הסבב" | Two buttons, both continue | Leaves the page: no history exists yet. There is **no bypass** into the game. |
| N2 stage | hub | Location art, HUD, active tab underline | Tabs, ⚙, 🔊 | At root with no layer open: leaves the page. **No exit trap.** State autosaves on `visibilitychange` and `pagehide`. |
| T1/T2 short tabs | lateral | Gold underline and bold label | Other tabs | Same as N2. Tabs never push history. |
| T3/T4 tall tabs | lateral, but counted as one layer | Header with its own title, plus a collapse chevron on the right | Chevron ›, tapping the active tab again, swiping down | Collapses to the last short tab |
| O1 return | modal card | "בזמן שלא היית" | "לאסוף", tapping the backdrop | Same as "לאסוף". **The money is credited when the card opens**, so even a back press that leaves the page at cold launch (rule 1) loses nothing. |
| O2 court day | **non-modal** card over the panel | "יום משפט" plus a timer | "התייעצות ביטחונית", "להעיד" (collapses to a chip), ✕ | Collapses to the chip |
| O3 election card | modal | "סבב בחירות מס׳ {n}" | "לפזר את הכנסת", "עוד לא", backdrop | Same as "עוד לא" |
| O3b Dubi flash | modal, story | Dubi's news frame | "לסבב הבחירות הבא", "דלג" | Same as "דלג" |
| O4 receipt / O5 result | modal sheet | Title plus the card preview | "לשתף", "לשמור תמונה", ✕, "סגור" (bottom) | Closes the sheet |
| O6 headline card | small modal | "מבזק" | "סגור", backdrop, "למקור" (external, new tab) | Closes the card |
| O7 settings | sheet (62% height, so the stage stays visible for live preview) | "הגדרות" | "סגור" (bottom), ✕, backdrop | Closes the sheet |
| O8 About | full page, **HTML over the canvas** (screen-reader readable, real links) | "אודות" | "חזרה" › | Back to O7 |
| O10 reset confirm | destructive modal | "בטוח?" | "למחוק הכול", "התחרטתי" | Same as "התחרטתי". **Tapping the backdrop does nothing.** |
| O11 / O12 one-time notices | modal | Title | "הבנתי" / "למשא ומתן", backdrop | Same as the button |
| O13 album | sheet from T4 | "אלבום: תמיד בפריים" | ✕, "סגור", backdrop | Closes the sheet |
| Rotate overlay | system | "תחזיק את הטלפון לאורך" | Rotate the phone | — |

### 1.2 Navigation contract rules

1. **One history entry per layer.** Opening any overlay or tall tab calls `history.pushState({layer})`. A `popstate` event closes the top layer. So Android back, browser back and iOS edge swipe all *pop one layer* and never leave the game mid-overlay.
   - **How it's built** (Game Developer, U2): a JS bridge, with a `popstate` callback. When a layer is closed by its own button, the game calls `history.back()` and ignores the echoed `popstate`.
   - **Cold-launch rule.** Chromium's back button skips history entries pushed before the user's first interaction. So layers that open on their own at launch (O1, O11, O12) push their entry on the **first `pointerdown`**, not when they open. Until that first touch, back may leave the page. That is why O1 credits the money when it opens, and why O11 and O12 count as seen when they are shown.
2. **Close affordances are doubled for one thumb.**
   - Every sheet has a ✕ at the top-left. In RTL that is the trailing corner, which is hard to reach, so every sheet **also** has a full-width "סגור" button in the thumb zone.
   - Every non-destructive modal can also be dismissed by tapping the backdrop.
3. **Modal queue.** Only one modal shows at a time. Priority, highest first:
   1. reset confirm;
   2. one-time legal notices (O11, O12);
   3. return card (O1);
   4. election card (O3);
   5. court day (O2);
   6. toasts.

   No modal *auto-opens* during a tap burst (last tap under 1 s ago), except O1 at launch.
4. **Fairness guard.** The Suitcase never spawns while the stage is covered: a tall tab, a modal, or a toast over its flight band. You can't miss what you can't see.
5. **Election reset clears the chat.** After an election the chat thread is cleared and gets a system line. The tabs and HUD stay where they were, so the player keeps their bearings.

### 1.3 Entry-point matrix

| Entry | Lands on | Back stack |
|---|---|---|
| Cold, first ever (link, QR or typed URL) | N1 (HTML; the engine loads behind it) → [hand-off bar if cold] → N2 (title state) | [N2] |
| Cold, returning (home-screen icon or link) | N0 (HTML, ≤ 2 s warm) → N2, plus O1 if away ≥ 60 s and offline earnings > 0 | [N2, O1]; O1's history entry is pushed on the first touch |
| Share link, new player (`?from=share&r=6&c=3`) | N1 → N2 title state, plus a toast: "מישהו שרד 6 סבבי בחירות ו־3 ימי משפט. תורך." | [N2] |
| Share link, returning player | N2 (+O1). The share parameters are ignored, so no toast. | [N2] |
| Back to foreground (same tab, away ≥ 60 s) | N2 + O1 | [N2, O1] |
| Back to foreground (away < 60 s) | Wherever the player was | unchanged |
| After a reset | N2 title state (no disclaimer; it was already seen) | [N2] |
| First open between 23.10 00:00 and 27.10 22:00 | Normal entry + O11, once | [N2, O11] |
| First open after 27.10 22:00 | Normal entry + O12, once | [N2, O12] |
| Desktop browser | The same, inside a centered 390-wide phone frame. Keyboard map in §7.4. | same |

---

## 2. The first 10 and first 60 seconds (`ftue-flow` + `prompt-trigger-spec`)

**Design principle.** The whole first minute has **one new thing at a time and zero instruction text**. The only words the player reads are:
- Dubi's two-word squawk;
- one headline;
- one price.

Everything else is taught by consequence. The HUD reveals itself element by element, as each element starts to matter (§3.2). That is how six HUD elements fit a first-minute player: at 60 s they have seen **three**.

### 2.1 Pre-gameplay flow

Revised for the Godot web fork (engine review O-U1). The engine is about 19 MB on the wire, too big to hide behind a loader. **It downloads behind the disclaimer instead.** The player has to read the disclaimer anyway, and it now opens the game in about 1.5 s with a joke on screen.

| # | Screen | Surface | Budget | Notes |
|---|---|---|---|---|
| 1 | Browser / OS | platform | — | — |
| 2 | **N1 disclaimer** (§6.1), first launch | **HTML in `shell.html`**, painted before any engine byte is needed | **Painted ≤ 1.5 s cold on 4G** | The engine downloads behind it: the wasm plus a **boot pack of about 4 MB** (Balfour music, all SFX, art data). Eras 2-4 are a second pack, fetched after C1 (~minute 1). <br>Both buttons are live immediately. **The tap on either button is t=0.** It stores the sound choice in localStorage for the engine to read at boot. It **does not** unlock audio any more: audio unlocks on the first Magician tap (on touchend for iOS), so the first sound is the motif on the first tap, as the sonic brief asks. |
| 2b | **Hand-off bar** (only if the engine isn't ready at t=0) | HTML | Cold worst case **≤ 4 s** (engine ready ≤ 10 s, minus ~6 s of reading). Warm cache: 0 s. | The tapped button becomes a thin progress bar that fills **right to left**. The other button fades out. One loading line sits under the bar and changes every 1.5 s: "מקפל מזוודות…", "מחמם את הכובע…", "מתייעץ ביטחונית…". The stage cross-fades in the moment the engine reports ready. |
| 2r | **N0 splash**, returning players only | HTML | ≤ 2 s on a warm cache | The pixel wordmark plus one loading line, with no buttons. If the cache was evicted, the same bar as 2b appears. |

**If the era pack is late.** Suppose the eras 2-4 pack hasn't arrived by the first election (7-9 min, so very unlikely). The election still runs. The stage stays in Balfour art and the pack retries in the background. The ticker covers the wait with a `[GD]` line (suggested: "הכנסת בשיפוצים. הקוסם עובד מהבית."). No spinner, and no modal.

### 2.2 The first 10 seconds (beat sheet)

| t | Player sees / does | How it says "tap me" (signifiers) | Beat |
|---|---|---|---|
| −7.5 s (page open) | Nothing yet | — | — |
| −6 s | **The HTML disclaimer paints (≤ 1.5 s)**. The engine is already downloading, invisibly. | Two big buttons, live at once | **Laugh 0, while the game loads:** the notice says it isn't funded by any party, candidate "או מזוודה" (§6.1). The "בשקט" button's caption is "אני בישיבה". The download costs the player nothing: these ~6 s of reading were owed anyway, and now they're funny. |
| 0.0 | Taps "עם סאונד" or "בשקט". **Warm cache or fast network:** the disclaimer cross-fades (300 ms) to the stage in its **title state**. **Cold:** the tapped button turns into the hand-off bar with a rotating loading line (2b). | The bar fills right to left | **Laugh 0.5 (cold only):** "מקפל מזוודות…" |
| 0.3 (warm) / ≤ 4 (cold) | Sees the title state: the "עוד סבב" logo, "סבב בחירות מס׳ 1 · הציבור נרגש", the chip "27.10 · עוד 29 ימים", and the Magician idling with his top hat. **Nothing else is on screen:** no HUD, no tabs, no buttons. | (a) The Magician is the largest and most saturated sprite, and the only thing in frame that moves. (b) His idle loop: he taps the hat with his wand and **a coin peeks out and sinks back**. (c) A soft brightness pulse on the hat. Hick's law: one choice. | — |
| stage + 1.5-3 | **First tap on the Magician = first agency.** Coins spray out, the "+1 ₪" float appears, and the shekel counter pops in at the top center. The logo flies up and out. The ticker docks at the bottom with Dubi on its right end. | — | **Laugh 1 (the big one):** as the coins spray, Dubi squawks in a bubble **"אין כלום! אין כלום!"** while money is visibly pouring out. The contradiction is the joke, and it needs no context. At the same moment the ticker's first headline starts crawling (slot H1 = deck T25: "על פי פרסומים זרים, יש כובע."). |
| 3-6 | Taps in rhythm; the counter climbs. | Squash on every tap, coin sound, counter roll | — |
| ~5 | **Tap 7 is the first rabbit (scripted).** A crit burst and the rabbit hops out. | — | **Laugh 2:** the Bugs Bunny wink, headline slot H2 `[GD]`. |
| ~8-10 | The shekels reach the price of the first source. **The panel slides up with one card:** "משלם המסים" (deck), with a gold price pill reading "לקנות · 15 ₪" (tap 12, pitch §11 Q1). | The card is the only new object. The pill has been filling right to left while the player tapped (it was already on screen, 40% transparent, from tap 3), and now it is full and gold. Motion plus brightness. | — |

### 2.3 Seconds 10-60

| t (est.) | Beat |
|---|---|
| ~11 | **First purchase.** The taxpayer walks onto the stage and drops coins into the hat. The scene visibly fills, and the passive income shows *on the stage* before any number does. The rate line "+1 ₪ לשנייה" appears under the counter. Headline slot H3 `[GD]`. |
| ~15-30 | The second source card appears, showing its name only once the player can afford 50% of it. Before that it is **"מקור עלום"** (a pun on the journalist's anonymous source). The player now faces the first real *choice*: tapping versus two buy targets. After the first purchase of each source, its pill reads **"עוד אחד · {price}"**. |
| ~25-40 | **First Suitcase.** It is slow, crosses right to left in 6 s, and is the only moving thing in its band (§3.4). **Both outcomes are funny, so both teach:** a catch gives a coin burst plus headline H-catch `[GD]`; a miss makes it exit just above the ticker, which then reads the brief's own **"המזוודה הגיעה ליעדה; לא ידענו."** The cause and the punchline are 20 px apart. |
| ~40-50 | **The coalition chat pings (first ping).** See the trigger C1 in §2.4. <br>• A chat-preview toast drops in under the HUD with Ben Gvir's pixel avatar, his name, and the preview `[GD]`. <br>• At the same moment **the tab bar appears** with two tabs: מקורות and קואליציה (badge 1). <br>• Ping sound; a 20 ms vibration where supported. <br>Opening the chat plays out the group's creation as a cascade of system lines: "הקוסם יצר את הקבוצה…", then members joining. Then **"בן גביר מקליד…"**, then his demand with the pay pill **"סגרנו · {price}"**. |
| ~50-60 | **First partner paid.** Seat pips fly from the chat bubble up to the top of the screen, and the **seats bar appears: "מנדטים {x}/61"**. The goal of the whole game is now on screen, and the player earned its reveal. The bubble's pay pill becomes a "שולם" stamp, and the player's auto-reply appears on the left: "העברתי." The seats bar appears at 34/61 (pitch §5). |
| **60** | **HUD count: counter + rate line, seats bar, ticker.** No suspicion meter yet, no Cottage Index yet, and no ultimatums yet. |

### 2.4 `prompt-trigger-spec`

Every trigger below is a player-state predicate. None is a wall-clock time. Every prompt auto-dismisses when the player performs the action.

| ID | Stage (introduce / isolate / recombine) | Trigger predicate | Form | Failure branch | Funnel event |
|---|---|---|---|---|---|
| P0 `tap_magician` | introduce(tap) | `stage.visible AND taps_total==0` | Diegetic idle loop (coin peeks) | **F1:** `idle_since_stage >= 3s AND taps_total==0` → Dubi flies in and pecks the hat; one coin pops out with "+1 ₪" (a demonstration). **F2:** `idle >= 6s after F1` → a pixel hand icon taps the hat on loop (no text). **F3:** at `idle >= 20s` the hand stays and the hat pulse doubles. No modal, ever. | `ftue_step_entered:tap`, `ftue_first_agency` |
| H1 | — | `taps_total==1` | Dubi squawk plus headline H1 | n/a | `ftue_step_completed:tap` |
| H2 | introduce(crit) | `taps_total==7 AND rabbits==0` (scripted once) | Rabbit plus headline H2 | n/a | — |
| P1 `first_buy` | introduce(buy) | `shekels >= cost(src1) AND sources_owned==0` | The card slides in; the pill is full and gold, with a brightness pulse | **F1:** `affordable_since >= 5s AND taps continue AND sources_owned==0` → Dubi hops onto the card: "לקנות! לקנות!" (a diegetic prompt; the parrot repeats what he's told). **F2:** `+8s` → the pixel hand on the card. **F3:** after 2 more affordable-and-ignored windows, the card gets a gentle bounce every time the counter passes a multiple of the price. | `ftue_step_entered:buy`, `…completed:buy` |
| P2 `choose` | isolate(buy) | `sources_owned>=1 AND shekels >= 0.5*cost(src2)` | Card 2 is revealed | If `sources_owned` stays at 1 while `shekels >= cost(src2)` for 10 s of play → the pill pulses once | `ftue_step_entered:choose` |
| S1 `suitcase_intro` | introduce(catch) | `sources_owned>=2 AND stage.unobstructed AND suitcase_seen==0 AND last_tap_age < 3s` (the player is looking at the stage) | Slow Suitcase with a sparkle trail | **Missed:** the headline plays. The next Suitcase keeps first-flight speed and the sparkle `while caught==0`. **After 3 misses:** it hovers mid-band for 1 s. | `ftue_suitcase_caught / _missed` |
| C1 `chat_ping` | introduce(pay partner) | `sources_owned>=3 AND shekels >= cost(demand1) AND no_modal AND last_purchase_age >= 2s` | Toast plus tab bar plus badge | **F1:** `toast dismissed unopened AND shekels >= 2*cost(demand1)` → the badge bounces once and the tab label goes bold. **F2:** tapping the seats bar opens the chat too (once the bar exists). There is **no ultimatum** until `demands_paid >= 2`. | `ftue_step_entered:coalition`, `…completed:coalition` |
| C2 `seats_reveal` | isolate | `demands_paid==1` | Pips fly to the seats bar | n/a | `ftue_seats_revealed` |
| U1 `first_ultimatum` | recombine(pay + time) | `demands_paid>=2 AND playtime_active >= 180s` | Ultimatum bubble with a countdown | If it expires: the partner leaves, but the system line carries **"להחזיר לקבוצה"**. Every loss is recoverable (a request to the Game Designer). | `ftue_ultimatum_*` |
| K1 `suspicion_intro` | introduce(heat) | `first shady source bought` | The thermometer slides in and ticks up once | n/a | `ftue_suspicion_revealed` |
| K2 `dossier_unlock` | — | `suspicion > 0 first time` | Toast **"נפתח לך תיק."** and the תיקים tab appears | n/a | — |
| K3 `spins_unlock` | introduce(spin) | `lifetime_earned >= [GD]` | Toast **"נפתחו ספינים. דובי כבר חוזר עליהם."** and the tab appears | n/a | — |
| Q1 `cottage_intro` | — | `lifetime_earned >= [GD threshold]` | The cup appears; the first pixel drops; headline H-cottage `[GD]` | n/a | — |
| E1 `first_election` | introduce(prestige) | `seats >= 61` first time | The ticker is replaced by the gold **"עוד סבב!"** button | If it is ignored for 60 s of play: Dubi squawks "בחירות! בחירות!" | `ftue_first_prestige` |

**Modal-strip trace.** In the first 60 s the only modal is the disclaimer, which is a legal notice, not tutorial. Strip every toast and Dubi fallback, and the player still reaches first agency by reading the world: one moving, glowing object, then one card with one price. The overlay-free status is earned. None of the prompts above carries the load on its own.

**Time to first agency:**
- Warm: ~2-3.5 s after t=0.
- Cold on 4G: ≤ 7 s (a ≤ 4 s hand-off plus ~2-3 s).
- Cold worst case with the F1 and F2 fallbacks: ≤ 16 s.

The studio's web budget is ≤ 30 s. Measured from page open, the first *laugh* lands at ~1.5-3 s (the disclaimer's joke line), long before first agency. Laugh 1 (Dubi) lands on the first tap.

**Funnel events to instrument** (named here, built by the developer): `ftue_step_entered`, `ftue_step_completed`, `ftue_step_skipped`, `ftue_first_agency`, `ftue_abandoned_at_step`, plus the ones in the table. Each carries `reduced_motion: bool` and `sound: on|off`, so accessibility paths stay visible in the funnel.

**Requests to the Game Designer (tuning, not objections):**
- First-source price reachable in **12-16 taps**.
- First demand affordable at **about 45 s**.
- **No ultimatum before minute 3**, and an ultimatum countdown of **≥ 90 s**.
- Every timer loss must be recoverable.
- The first rabbit on tap 7.
- Headline slots H1, H2, H3, H-catch, H-cottage, filled in the copy deck.

---

## 3. HUD layout at 390×844 portrait, RTL (`hud-layout`)

See frame B of `hud-wireframe.png`. All numbers are in CSS px; y is measured from the top of the screen.

### 3.1 Regions

**Units.** Everything is in CSS px at 390×844. The fork's canvas is 720 logical px wide, so **1 CSS px = 1.846 logical px**. Restate every value on the fork's 4-px logical grid: round **hit areas up**, and round visuals to the nearest step. 44 CSS px = 81 logical px; the fork's 96-px rows already clear it.

| y | Region | Contents (right → left, because RTL) |
|---|---|---|
| 0-59 | Top safe area | Background art only |
| 59-111 | **Row A** (scrim `#140C24` at 92%) | Cottage Index 44×44 · **shekel counter** (center, 27 px, with the rate line in 12 px under it) · 🔊 44×44 · ⚙ 44×44 |
| 111-155 | **Row B** (the whole row is one 390×44 target, and it opens the chat) | "מנדטים" label · seats bar (228×16) filling from the right · "58/61" |
| 155-504 | **Stage** | Suspicion thermometer (hit area 44×218, left edge, x 12-56) · Magician hit area **200×225** (x 95-295, y 205-430) · **Suitcase band y 440-500** · toasts dock at y 163-223 |
| 504-548 | **Ticker** (44 tall, tappable) | Dubi plus "מבזק" anchor (90 w) · crawl area · countdown chip "27.10 / עוד 29 ימים" (92 w) |
| 548-754 | **Panel** | Three 64-px cards. **The whole card is the buy target** (366×64). The price pill (118×44) is the signifier and fills right to left as money comes in. |
| 754-810 | **Tabs** | מקורות · ספינים · קואליציה · תיקים, each 97.5×56 |
| 810-844 | Bottom safe area | — |

When seats ≥ 61, the ticker row is replaced by a full-width gold **"עוד סבב!"** button, 390×44. It sits in the easy thumb zone. The election is the core call to action, so it takes the most reachable strip, and the button reuses the title.

### 3.2 Element manifest

**Tiers:** C = critical, I = informational, P = peripheral.

| # | Element | State it shows | Tier | Taxonomy (one-line justification) | Update | Fade rule | Non-colour channel | Revealed when |
|---|---|---|---|---|---|---|---|---|
| 1 | Shekel counter "12.4K ₪" | Treasury | C | Non-diegetic: every buy decision reads it, so it can't depend on the scene | Continuous (text updated at ≤ 10 Hz) | Never fades | It's a number, with a coin icon | Tap 1 |
| 1b | Rate line "+1.2K ₪ לשנייה" | Income per second | I | Non-diegetic: a helper to #1 | Event (on purchase or buff) | 100% for 3 s after a change, then 60% | Number | First purchase |
| 2 | Seats bar "מנדטים 58/61" | Progress to the prestige gate | C | Non-diegetic *meta* (Knesset arithmetic, not an in-world object) | Event | Never fades. At ≥ 61 it pulses and gets a gold rim. | **Segmented** fill (a tick every 10), the numeral, and the label. In the blackout, fill plus stamp (§6.3). | First partner paid |
| 3 | Suspicion thermometer "חשד" | Heat toward court day | I below 75%, C at 75% and above | Non-diegetic gauge **with a diegetic echo**: the Magician sweats and the courthouse window lights up in the background | Event | 60% opacity while under 50% and unchanged for 3 s; 100% on any change or at ≥ 50% | **Vertical** fill (a different shape from the seats bar), 4 ticks, a state word ("מבעבע" at ≥ 75%, "רותח!" at ≥ 95%), an icon swap (magnifier → gavel), and bubbles (a static bubble icon under reduced motion) | First shady source. **Suspicion carries over between rounds as a floor** (pitch §11 Q8), drawn as a hatched segment at the bottom of the tube — a shape channel. |
| 4 | Cottage Index (a pixel cottage-cheese cup) | Satirical cost of living: the cup loses a pixel as the treasury grows | P | Non-diegetic meta commentary. It is a joke, not a decision input, so it goes in a corner. | Low frequency | 50% opacity; 100% for 3 s with a "−1" puff when a pixel drops | Shape (missing pixels). Tapping it gives the tooltip "מדד הקוטג׳: הקופה שלך גדלה. הקוטג׳ קטן." | `lifetime_earned` ≥ GD threshold (~minute 3) |
| 5 | Countdown chip "27.10 · עוד 29 ימים" | Real-calendar days to the election | P | Meta: it points outside the game on purpose, which is the joke | Daily | 60% opacity always; 100% on the first view of a new day | Text | Title state, then it docks into the ticker on tap 1 |
| 6 | Ticker (Dubi's crawl) | Reactions and headlines | I | Diegetic-ish: it is *Dubi's channel*, a TV lower-third inside the fiction | Continuous crawl at 40 px/s | Never fades (it's the comedy channel). It pauses while the "עוד סבב!" button replaces it. | Text | Tap 1 |

**Criticality budget per region:**
- Row A: 1 C and 2 P.
- Row B: 1 C.
- Stage: at most 1 C (suspicion at ≥ 75%) plus the verb targets.
- Ticker: 1 I and 1 P.

That is within ≤ 2 C per region. **No critical element sits in a corner:** the counter is top center, the seats bar spans the full width, and the thermometer is edge-adjacent at mid-height, beside the Magician's attention cone. Only the corners hold peripheral elements (the Cottage Index) and rare controls (⚙ and 🔊).

**Kept out of the persistent HUD** (pre-registered; see §9 for the conditional objection):
- Gotliv's own court meter goes on her chat avatar ring.
- The public-broadcaster bar goes on Karhi's "השלט" card.
- The departure board is diegetic, in the stage background.
- Spin fatigue shows as the "שחוק" tag on the spin card.

### 3.3 Thumb zone (right hand; mirrored reach for left hand noted)

- **Easy, y 480-810.** Holds the Suitcase band, the ticker / "עוד סבב!" button, the cards and the tabs.
- **OK, y 260-480.** Holds the Magician hit area (y 205-430). Its centre of mass is at y ≈ 318, and its **lower half (y 320-430) sits at the edge of the easy zone**. That is Fitts's law: a huge target at moderate reach.
- **Stretch, above 260 and the bottom-left corner.** Only read-only elements live there, and rare controls (⚙ 🔊) and shortcuts that duplicate a tab (the seats bar → chat, the thermometer → תיקים).
- **Cards are fully tappable across their width**, so the RTL convention that puts the price pill at the left (trailing) end never forces a right thumb into the bottom-left stretch corner. Scroll and tap are told apart by a 10 px move threshold.

### 3.4 Catching the Suitcase

| Property | Spec |
|---|---|
| Sprite | ≥ 40×32 CSS px (20×16 art px at 2×) |
| **Hit area** | **72×64**, centered on the sprite. It sits ≥ 10 px clear of the Magician's hit area; the two never overlap. |
| Band | y 440-500, the easy zone, directly above the ticker, so a miss exits right beside its own punchline |
| Speed | First flight crosses 390 px in **6.0 s**. Regular flights take 3.5-4.5 s. The **floor is 3.0 s**, which leaves room for reaction time plus moving the thumb. Vertical bob ≤ 8 px. |
| Direction | The first flight is always **right → left**, entering where a Hebrew reader's eye starts. Later flights alternate. |
| Spawn guard | Only when `stage.unobstructed`: no tall tab, modal or toast over the band (§1.2 rule 4) |
| Pre-attentive signal | It is the only moving object in its band: maroon with a cream outline against the lighter floor, and a "DOHA" sticker. It has a sparkle trail until the first catch. The spawn gets an audio "whoosh + zipper" cue (Audio Director spec). |
| Reduced motion | Still moves (it is essential to play), but at a constant speed ×0.8 with no bob or spin |

### 3.5 RTL and number rules (the HUD part of `localization-layout-spec`)

| Rule | Spec |
|---|---|
| Direction | **HTML surfaces** (N0, N1, the hand-off bar, O8): `dir="rtl"` and `lang="he"`. **Canvas** (everything else): Godot Controls with `layout_direction = RTL`, and RTL text direction on every `Label` / `RichTextLabel` (TextServerAdvanced, ICU bidi). |
| Bars | Fill **from the right** (`mirror`). The seats bar, the price pills, and progress on the demand pills all do this. |
| Thermometer | Fills bottom → up (`keep`, since it is direction-neutral) |
| Ticker | Crawls **left → right** (`mirror` of the LTR ticker). A Hebrew line's first word is its rightmost, so it enters from the left edge first. |
| Chevrons | Back / collapse ›, pointing right (`mirror`) |
| Transfer arrow | "הליכוד ← עוצמה יהודית", with the arrow pointing left, the direction of motion in RTL (`mirror-with-glyph-swap`) |
| Clock and timers, "0:45" | `keep`, LTR digits |
| Emoji and logo wordmark | `keep` |
| Numbers | Always wrapped in **LRI…PDI** (U+2066 … U+2069), or `<bdi dir="ltr">` on the HTML surfaces, so "+1.2K", "58/61", "−5" and "0:45" never flip their sign or order. |
| Compact format in the HUD | K / M / B / T, Latin capitals. 1 decimal below 100 ("12.4K"); integers from 100 up ("412K"). Full grouping with commas only on the receipt and result cards ("4,213,000"). |
| ₪ placement | **In reading order, the number first and then ₪**, with a no-break space: logical `‹LRI›12.4K‹PDI› ₪`. In an RTL line that renders with **₪ visually to the left of the number** ("₪ 12.4K" on screen), which is how Hebrew price text reads. The wireframe shows it this way. |
| Dates | "27.10" (DD.MM), with no year in the HUD |
| Hebrew quote marks | Real quotes go inside "…" and are always preceded by the tag "ציטוט". Hebrew abbreviations use gershayim ״ (U+05F4) and geresh ׳ (U+05F3): "מס׳", "סה״כ", "מע״מ", "יועמ״ש". Joined numerals use a maqaf: "ו־3" (U+05BE). |
| Rendering (request to the Developer and TA; engine review O-U2) | **Hebrew and mixed text:** a Godot `Label` or `RichTextLabel` with the bitmap `FontFile` built from the pixel-font data. TextServer does the bidi, and LRI/PDI are honoured. **`PxText` is only for purely numeric strings** (digits, `.,:/+−%`, `K M B T`, `₪`), because it has no bidi. **Never pre-reorder Hebrew at runtime:** `hebfont.py`'s `visual_order()` is for proofs only. Leave `include_text_server_data` off; Hebrew doesn't need it. |
| Glyph range for the TA's pixel font | U+0020-007E, U+05D0-05EA (including final forms), U+05BE, U+05F3-05F4, U+20AA ₪, U+2026 …, U+00B7 ·, U+2190 ←, U+2013/2014, U+2212 −, U+00D7 ×. **Missing from the font draft today (engine review F4):** K M B T, + −, …, ־ ״ ׳, ← × – —. The 2D Artist draws them at body height before the style guide locks. **No niqqud.** The in-game 🔒 📌 ⏱ are **pixel icons**, not emoji. Real emoji appear only in share text and the OG image. |

### 3.6 Smallest viewport (360×740)

- The stage shrinks from 349 to 283 px tall. The Magician scales to fit (hit area ≥ 160×180).
- The Suitcase band keeps a **fixed 60 px** height and 72×64 hit area.
- The panel drops to 2.5 cards.
- Nothing critical overlaps the stage rectangle. Toasts overlap only the top 60 px of the stage.

---

## 4. Coalition chat tab "קואליציה 61 🔒"

This is a **tall tab**, frame C in the wireframe. HUD rows A and B stay visible, so paying a partner visibly moves the seats bar in the same view.

### 4.1 Layout (top → bottom)

1. **Header, 56 px.**
   - Right: the collapse chevron › (44×44).
   - Title "קואליציה 61" with a pixel lock icon.
   - The status line under the title rotates by state:
     - "{n} משתתפים";
     - "{name} מקליד/ה…", for 1.2 s before any partner message (a telegraph);
     - "{k} איומי פרישה פתוחים".
2. **Pinned bar, 30 px.** "נעוץ: ההסכם הקואליציוני · טיוטה {n}", where {n} is the election round plus 13. It starts at "טיוטה 14" because the coalition agreement has *never* been final.
3. **Thread.**
   - Incoming bubbles align **right** and the player's replies align **left**, as Hebrew chat convention mirrors.
   - Sender name above each bubble, with a 24 px pixel avatar.
   - A day divider "היום".
   - An unread divider: "{n} הודעות שלא נקראו".
4. **Composer, disabled.** Placeholder: **"פה מדברים רק בשקלים"**.

### 4.2 Message types

| Type | Look | Chrome copy | Behaviour |
|---|---|---|---|
| **Demand** | Incoming bubble; `[GD]` text; a gold pay pill 170×36 (hit area 182×48) under the text, right-aligned in thumb reach | Pill: **"סגרנו · {price} ₪"**. Before the player can afford it, the pill fills right to left with "חסר {n} ₪" on it. | On pay: the pill becomes a "שולם" stamp; seat pips fly to Row B; the player's auto-reply appears on the left, rotating through "העברתי.", "סגור.", "בוצע. אין כלום." |
| **Ultimatum** | Bubble with a **hatched border** (shape) plus the **"אולטימטום"** label (text) plus a timer pill with a clock icon, "0:45" (text). Colour is the fourth channel, not the only one. | Pill "סגרנו · {price} ₪" | The countdown pauses while the app is hidden. Paid → the bubble collapses to **"ההודעה נמחקה"**. Expired → a system line "{name} עזב/ה את הקבוצה", and the seats drop by that partner. That system line carries the pill **"להחזיר לקבוצה · {price} ₪"**. |
| **System line** | A centered, neutral pill in small text, with no avatar | See §8, rows `chat.sys.*`. Gendered per member through ICU `select`. | Non-interactive, except the "להחזיר לקבוצה" variant |
| **Transfer banner** | Full-width football-style card: a black strip with "חלון העברות" in gold, then the name in large type, then "{from} ← {to} · כולל דמי אחזקה" | "חלון העברות" | It is followed by the system line "{name} עזב/ה · צורף/ה ל״{to}״" and then Ben Gvir's ultimatum `[GD]` |
| **Brawl** (Amsalem vs Smotrich, and any recurring pair) | System line "{a} ו{b} רבים. שתי השורות הוקפאו." plus one button | **"צאו החוצה"** (from the brief, quoting the record) | After it: "נוצרה קבוצה חדשה: ״המסדרון״ · 2 משתתפים", plus a muted "{n} הודעות" counter that climbs every time the chat is opened. It is one shared group across all brawls. |
| **Muted advisers** (Distel) | System line | "{who} ביקשו רשות דיבור · נדחה" + pixel mute icon | Non-interactive |
| Group events | System lines | "הקוסם יצר את הקבוצה ״קואליציה 61״"; "{name} הוסר/ה על ידי מנהל"; "{name} צורף/ה על ידי מנהל"; after an election: "הקוסם ניקה את הצ׳אט. לקראת סבב בחירות {n}." | — |
| Empty state | Centered text | "שקט בקבוצה. זה לא יחזיק." | — |

### 4.3 Generic styling, with no WhatsApp branding

- No green anywhere in the chat. Specifically, avoid `#25D366` and `#075E54`.
- No tick marks: no double ticks and no blue read receipts.
- No doodle wallpaper, no WhatsApp logo, font or phone-call icons.
- Bubbles are **square-cornered pixel panels** in the game's palette. Incoming bubbles are `#2E2250`; the player's are dark gold `#4A3A10`.
- The "chat" is recognisable from *structure* (bubbles, names, system pills, the typing line), not from brand marks.

---

## 5. Share assets

**Global rule:** share cards **never show seat numbers**, at any date. Cards outlive the blackout window and travel without context. Every card carries the one-line disclaimer.

### 5.1 The household receipt (the main share asset)

The image is 1080×1350 (4:5). Its key content sits inside the centred 1080×1080 area, so a square crop still works. It is a pixel thermal-receipt texture on paper `#F4F1E8` with ink `#1A1A1A` (15.4:1 contrast). Photobombers may appear in the margins (2D art).

```
                 עוד סבב
        חשבונית מס / קבלה (העתק)
      סבב בחירות מס׳ 6 · 28.09.2026
 ─────────────────────────────────────
     הקיסרות שלך עלתה למשפחה הממוצעת
               4,213,000 ₪
                  החודש
 ─────────────────────────────────────
 פריט                              במשחק
 מע״מ 18%*                    1,102,000 ₪
 דלק 95: 8.25 ₪ לליטר (שיא, 1.9.2026)*   760,000 ₪
 כנף ציון, החלק שלכם*              508,000 ₪
 גלידת פיסטוק (בוטל ב־2013)*            0 ₪
 כספים קואליציוניים*           1,843,000 ₪
   (כולל 800 מיליון ₪ שאושרו בטעות)*
 ─────────────────────────────────────
 סה״כ                          4,213,000 ₪
 שולם על ידי: אתם
 אמצעי תשלום: המשכורת שלכם
 ─────────────────────────────────────
 עד הבחירות: 29 ימים (27.10)
 ─────────────────────────────────────
 * הנתון אמיתי. הסכום מהמשחק.
 סאטירה. קריקטורות בדיוניות. לא קשור לאף מפלגה או מועמד.
 <URL> · <מפרסם>
         *** תודה שבחרתם. שוב. ***
```

**Honesty design.** Rates and facts are real and sourced. The ₪ amounts are fiction, and the footnote says exactly that. That keeps the red line "no invented facts presented as real".

**Where the amounts come from** (for the Developer and Game Designer):
- The VAT line = income from the VAT source this round.
- The coalition line = partner payments this round.
- Fuel and Wing of Zion split the taxpayer and high-tech income 60/40. This weighting is fiction, and it is covered by the footnote.
- The pistachio line is always 0 ₪. It is the receipt's one understatement gag (per designer O8).

**Sourcing.**
- VAT 18%, the NIS 800M, Wing of Zion (#20) and the pistachio budget (#18) come from references.md.
- Fuel is references #50: a record ₪8.25/L on 1.9.2026, so the line is dated.
- Electricity and water are **cut** until someone supplies a dated source.

**Variants of the countdown line:**
- On 27.10: "הבחירות: היום".
- After 27.10: "הבחירות: נגמרו. הקואליציה: עוד לא."

**In-game sheet chrome:** title "הקבלה החודשית"; buttons **"לשתף"** (primary: Web Share API with the image and text, falling back to a download) and "לשמור תמונה"; plus "סגור". The sheet is in the canvas.

**Rendering the card** (engine review U9):
- The card is rendered **when the sheet opens** (SubViewport → PNG, 100-300 ms on a phone), not on the Share tap. That keeps the Share tap inside Safari's user-activation window.
- While it renders, the preview is a blank receipt roll with **"מדפיס…"**, and "לשתף" shows its disabled state. The button enables the moment the file is ready. Reduced motion: no roll animation, just the text.
- **iOS WhatsApp drops the share text when an image is attached.** So the fiction label (the footnote "* הנתון אמיתי. הסכום מהמשחק." and the disclaimer line) must be **on the image**, never only in the text. The same holds for the result card.

### 5.2 The result card

The image is 1080×1350, with the same safe square as the receipt.

- **Headline:** **"שרדתי 6 סבבי בחירות ו־3 ימי משפט"**. This is an ICU string:
  ```
  שרדתי {rounds, plural, one {סבב בחירות אחד} two {שני סבבי בחירות} other {# סבבי בחירות}}
  {days, plural, =0 {ואפס ימי משפט. בינתיים.} one {ויום משפט אחד} two {ושני ימי משפט} other {ו־# ימי משפט}}
  ```
- **Subline:** "והציבור? נרגש."
- **Stat strip:** "מזוודות שנתפסו: 12 · בקשות דחייה: 9". No seats.
- **Footer:** "עוד סבב · משחק סאטירה · <URL>", plus the micro-disclaimer "סאטירה. לא קשור לאף מפלגה או מועמד."
- If both photobombers are in frame, a tiny pixel camera stamp (the brief's 📸) is added.

### 5.3 Share texts (the message body sent with the link)

These are addressed in the **plural**, because they land in a group chat.

| Use | Text | Chars |
|---|---|---|
| Result | "שרדתי 6 סבבי בחירות ו־3 ימי משפט ב״עוד סבב״. מישהו פה עושה יותר? <URL>" | ≤ 90 + URL |
| Receipt | "הקיסרות שלי ב״עוד סבב״ עלתה למשפחה הממוצעת 4.2 מיליון ₪ החודש. (במשחק. בינתיים.) <URL>" (Hebrew units in share prose; K/M/B is HUD-only) | ≤ 100 + URL |
| Generic invite (from About) | "משחק סאטירה על הבחירות שלא נגמרות. תורכם להיות הקוסם. <URL>" | ≤ 70 + URL |

**"(במשחק. בינתיים.)"** keeps the fiction label attached even when the text travels without the image.

### 5.4 Link previews (OG / Twitter)

| Tag | Value | Budget |
|---|---|---|
| `<title>` / `og:title` / `twitter:title` | **"עוד סבב: הבחירות שלא נגמרות"** | ≤ 45 |
| `og:description` / `twitter:description` | **"שולפים שקלים מהכובע, משלמים לשותפים ודוחים את המשפט. סאטירה על כולם, לא קשורה לאף מפלגה."** | ≤ 110 (WhatsApp shows about 2 lines) |
| `og:image` | 1200×630 JPEG, **≤ 300 KB** (WhatsApp is unreliable above that). Key art inside the **centre 630×630**, because WhatsApp and Telegram sometimes crop to a square thumbnail. | — |
| `og:image:alt` | "הקוסם בפיקסלים שולף שקלים מכובע, ומזוודה עם מדבקת DOHA עפה ברקע" | ≤ 90 |
| `og:locale` | `he_IL` | — |
| `og:type` | `website` | — |
| `twitter:card` | `summary_large_image` | — |
| `og:site_name` | "עוד סבב" | — |

The page the link opens *is* the game, so a new visitor meets the full disclaimer (N1) before anything else. N1 is HTML in `shell.html`, so crawlers and the `<noscript>` fallback see the full disclaimer text too.

### 5.5 Home-screen name

- Manifest `short_name`: **"עוד סבב"** (7 characters, within 12).
- `apple-mobile-web-app-title`: "עוד סבב".
- `name`: "עוד סבב · משחק סאטירה".
- Manifest also sets `dir: "rtl"`, `lang: "he"`, and `orientation: "portrait"`.

---

## 6. Disclaimer, About, and the blackout

### 6.1 First-launch splash (N1)

```
רגע לפני הסבב

זו סאטירה. הדמויות הן קריקטורות פיקסל, ומה שהן עושות כאן בדיוני.
אין כאן טענה עובדתית על אף אחד. ציטוטים אמיתיים מסומנים כציטוט, עם מקור.
המשחק לא קשור לאף מפלגה או מועמד, ולא ממומן על ידי אף מפלגה, מועמד או מזוודה.
ואין כאן המלצה להצביע לאף אחד.

מאת <מפרסם> · <מייל> · אודות

[ עם סאונד ]      [ בשקט ]
                   אני בישיבה
```

**The joke line is "…או מזוודה".** The legal statement "not affiliated with, and not funded by, any party or candidate" is complete *before* the joke. The third item adds a laugh without replacing anything.

**Layout.**
- **Surface: HTML in `shell.html`, not the canvas** (engine review O-U1 and O-U2). It paints in ≤ 1.5 s while the engine downloads. It is screen-reader readable, selectable, translatable, and readable by crawlers, so it also serves the share landing page.
- It uses the **system Hebrew font** (no webfont request, to protect the 1.5 s) in the game palette. A pixel wordmark "עוד סבב" (an inline image ≤ 10 KB) and a pixel border (CSS `border-image`, ≤ 5 KB) tie it to the game's look.
- Body text 16 px, line-height 1.5, on a solid panel with cream text on `#140C24` (17:1 contrast).
- Both buttons are 44+ px tall and full-width in the thumb zone.
- "אודות" is a text link that opens O8. Its back returns here.

**Versioning.** The splash is versioned (`disclaimer_v`). Any change re-shows it once.

### 6.2 About (O8)

**Surface: HTML over the canvas** (engine review O-U2), with real "למקור" links. It opens from the canvas settings sheet through the JS bridge and follows the same history rule (§1.2).

**Title:** "אודות"

1. "עוד סבב הוא משחק סאטירה. הדמויות הן קריקטורות פיקסל של אנשי ציבור, ומה שהן עושות ואומרות במשחק בדיוני."
2. "אין במשחק טענות עובדתיות על אף אדם. ציטוטים אמיתיים מופיעים במירכאות, מסומנים ״ציטוט״ ומקושרים למקור. פרשות משפטיות מתוארות כמו ברשומות: נאשם, לכאורה, בחקירה."
3. "המשחק לא קשור לאף מפלגה, רשימה או מועמד, ולא ממומן על ידם. גם לא על ידי מזוודה."
4. "אין כאן המלצה להצביע לאף אחד, ואין כאן סקרים."
5. "אין כאן מה לקנות: אין פרסומות, אין רכישות, אין פרסים."
6. "לקראת הבחירות: מ־23.10 ועד סגירת הקלפיות לא יוצגו במשחק מספרי מנדטים."
7. "ההתקדמות נשמרת רק במכשיר שלך." (The Developer must confirm this. If telemetry ships, add: "ונאספים נתוני שימוש אנונימיים.")

**Section "מקורות וציטוטים".** The full reference list from the Game Designer's `references.md`, *inline* on this page to keep depth at 2. Each entry has a "למקור" link.

**Section "מי אנחנו".**
- "מאת <מפרסם>"
- "לפניות: <מייל>"
- "גרסה {v}"

**Button:** "לשתף את המשחק", which uses the generic invite text.

### 6.3 The blackout: no poll-like numbers from 23.10

**Window.** From **23.10.2026 00:00 Israel time (22.10 21:00 UTC, IDT)** to **27.10.2026 22:00, when the polls close (20:00 UTC, IST)**. Israeli DST ends on 25.10. The window's dates come from the brief. **The publisher's lawyer should confirm the window against the Elections (Propaganda Methods) Law before launch.**

**How the UI enforces it:**

1. **Clock that can't be rewound** (engine review U3). JavaScript can't read the page's own `Date` header, so:
   - `now = max(device clock, the Date header of a same-origin fetch(location.href, {method:'HEAD', cache:'no-store'}), the build timestamp baked in at export, a saved high-water mark)`, in UTC.
   - When online, the high-water mark is clamped to the server time, so a phone once set to 2027 doesn't stay locked in post-election mode.
   - Setting the phone's clock back doesn't escape the window.
   - **Backstop:** the publisher deploys a build with the blackout flag forced on 22.10. There is no service worker, so a reload picks it up.
2. **HUD.** The seats bar keeps its segmented fill, so the gate still works, but the numeral "58/61" is replaced by a paper stamp **"חסוי עד 27.10"**. The label "מנדטים" stays. Fill plus stamp is not a number; the "עוד סבב!" button still appears at full.
3. **Content filter.** Every line in the Game Designer's copy deck carries a `poll_like: bool` tag. During the window the ticker, events and Dubi flashes draw only from `poll_like:false`.
4. **Build-time lint as a backstop.** Any string that contains a digit within 3 words of "מנדט", "סקר", "מוביל" or "אחוז החסימה" fails the build unless it is tagged. Default: deny.
5. **Mechanics that show real lists with numbers are off for the window.** This covers:
   - threshold roulette;
   - the Nameless Party's seat drain (its animation stays, its numbers go);
   - any seat comparison between two named lists.
6. **Share cards** carry no seat numbers at any time (§5).
7. **One-time notice O11:**
   - Title: "שקט לפני הקלפי".
   - Body: "עד סגירת הקלפיות (27.10, 22:00) לא נציג פה מספרי מנדטים. אנחנו לא סקר, ולא מחפשים עוד תיק."
   - Button: "הבנתי".
8. **Election night, O12:**
   - Title: "הקלפיות נסגרו."
   - Body: "הבחירות נגמרו. הקואליציה? עוד לא."
   - Button: "למשא ומתן", which enters the Game Designer's endless coalition-negotiation mode.
   - That mode also never shows real results.

---

## 7. Return screen, settings, accessibility

### 7.1 Return after being away (O1)

**Trigger:** `away >= 60s AND offline_earnings > 0`.

| Away for | Title | Body |
|---|---|---|
| 1-15 min | "חזרת מהר." | "משלמי המסים לא הספיקו להתגעגע." |
| 15 min-8 h | "בזמן שלא היית" | "משלמי המסים המשיכו לשלם." (brief) |
| 8-48 h | "איפה היית?" | "בלשכה מסרו: התייעצות ביטחונית." (designer O1: no sleep jokes) |
| > 48 h | "נעלמת ל־{n} ימים." | "תרגיל ההעלמה הכי טוב שלך עד היום." (designer O2) |

**Contents of the card:**
- **Big number:** "+3.4M ₪".
- **Optional line:** "{n} הודעות חדשות בקואליציה", or "הודעה חדשה אחת בקואליציה" for one.
- **Only if the offline cap was reached:** "הכובע סופר עד {h} שעות. גם לו יש גבולות."
- **Single button: "לאסוף".**

**Rules:**
- Tapping the backdrop or pressing back also collects.
- The card never shows an upsell (there is none).
- The chat badge carries whatever happened while the player was away. Ultimatums were paused, so **nothing was lost while away**.

### 7.2 `settings-spec` (O7: a sheet opened from ⚙)

The sheet is **62% of the screen tall**, so the stage stays visible behind it and every setting previews live. Seven items in three groups, so no group exceeds Miller's ceiling and there is no deeper level.

| Group | Setting | Default | Why it exists / why this default | Live preview |
|---|---|---|---|---|
| **סאונד** | צלילים | on (or off if "בשקט" was chosen) | The juice is half the feel. The splash choice is respected. | Toggling on plays one coin "צ'ינג" |
| | מוזיקה | on, at 60% of the SFX level (or off if "בשקט") | The median player listens on phone speakers and should hear taps over the music. Audio for iOS: set `navigator.audioSession.type='ambient'` so **the ringer switch mutes the game**. | Music fades in or out over 300 ms |
| **נוחות** | תנועה מופחתת. Caption: "בלי טיקר רץ, בלי רעידות, בלי קפיצות." | Follows the OS `prefers-reduced-motion` | Vestibular safety, and it calms the screen | The ticker behind the sheet stops crawling immediately |
| | רטט | on | The brief's "buzz in the hand". **Hidden where `navigator.vibrate` is unsupported** (iOS Safari), rather than shown as a dead toggle. | One 20 ms pulse |
| | טקסט גדול. Caption: "לקריאה ממרחק זרוע." | off | The audience includes older family-group players. It raises every Hebrew label and body text one whole pixel scale, 3 → 4 (×1.33; the pixel font has no in-between size). HUD numerals are already large. | The sheet's own text resizes |
| **המשחק** | אודות ומקורות | — | Legal, sources, contact | — |
| | איפוס התקדמות (danger colour **plus** a trash icon) | — | Required for a fresh start | — |

**Toggles.** Each toggle is a 64×32 pixel switch inside a **full-row hit area of 366×48**. The state is shown by knob position plus a "פועל" / "כבוי" text, never by colour alone.

**Persistence.** All settings persist locally. A reset keeps the settings and wipes only progress.

**The 🔊 button in Row A** is a one-tap master mute. Its accessible labels are "השתקה" / "ביטול השתקה", and a slash shape marks the muted state.

**Reset confirm (O10).** There is no backdrop dismiss.
- **Title:** "בטוח?"
- **Line 1:** "זה כמו פיזור הכנסת, רק בלי בחירות חוזרות."
- **Line 2 (clarity):** "כל ההתקדמות תימחק לתמיד: כסף, סבבי בחירות, תיקים ואלבום."
- **Buttons:** **"למחוק הכול"** (destructive, on the left) and **"התחרטתי"** (cancel; on the right and focused by default).
- **After the reset:** the toast **"נמחק. אין כלום."**, and the game returns to the stage's title state.

### 7.3 Accessibility minimums (the `accessibility-spec` slice for this surface)

**Contrast.** These are functional tokens. The 2D Artist may change the hues, but must keep these ratios. Values were computed with the WCAG formula.

| Pair | Ratio | Needed |
|---|---|---|
| HUD text cream `#FFF4DC` on scrim `#140C24` | 17.4:1 | 4.5 |
| Counter gold `#F5C542` on scrim | 11.7:1 | 3 (large) |
| Muted rate line `#B9AED0` on scrim | 9.1:1 | 4.5 |
| Ticker text on maroon `#7A1426` | 9.8:1 | 4.5 |
| Ink on the gold call-to-action | 11.7:1 | 4.5 |
| Seat fill `#5AA9FF` on track `#2B2145` | 6.1:1 | 3 (non-text) |
| Track outline `#6B5C92` on scrim | 3.2:1 | 3 |
| Suspicion fill `#FF6B5A` on track | 5.3:1 | 3 |
| Chat text on incoming bubble / player bubble / system pill | 13.2 / 10.1 / 13.3 : 1 | 4.5 |
| Ultimatum border on chat background | 6.2:1 | 3 |
| Danger text `#FF8A7A` on sheet | 7.6:1 | 4.5 |
| Receipt ink / grey on paper | 15.4 / 6.1 : 1 | 4.5 |
| Focus ring `#8FE3FF` on chat background | 12.1:1 | 3 |

**Scrims over the stage.** Every text element over the moving stage sits on a scrim. Toasts sit on `#140C24` at 92%. Dubi's speech bubble is cream with ink text.

**Colour is never the only channel:**
- The seats bar is segmented and carries a numeral or stamp.
- The suspicion meter is a vertical shape with a state word, an icon swap and ticks.
- The ultimatum has a hatched border, a label and a timer.
- Buy pills show fill plus price text.
- Toggles use knob position plus text.
- A deuteranopia / protanopia simulation pass is required on the art pass. The seats blue and the suspicion red also differ in luminance, and in shape, which does not depend on colour.

**Reduced motion** (`prefers-reduced-motion` or the setting):
- **The ticker stops crawling.** It shows one headline at a time, with a 200 ms cross-fade after the headline's reading time (max of 4 s and 60 ms per character). Tap for the next one.
- **Screen shake: 0.**
- Coin bursts shrink to 3 coins with no arcs.
- The rabbit appears instead of hopping.
- Parallax off; transitions are ≤ 200 ms cross-fades.
- Bubbles become static icons.
- The Suitcase still moves (it is essential) with no bob, at ×0.8 speed.
- **No flash at more than 3 Hz anywhere.** The court-day red is a steady tint, not a strobe.

**Touch targets.** Every interactive element is at least 44×44 CSS px:

| Element | Hit area |
|---|---|
| Tabs | 97×56 |
| Cards | 366×64 |
| Pay pill | 182×48 |
| Suitcase | 72×64 |
| Magician | 200×225 |
| Ticker | 390×44 |
| Rows and toggles | 366×48 |
| Icons | 44×44 |

**Motor.**
- There are no holds and no rapid-tap requirement.
- Once the first sources are bought, income flows without tapping, so tapping is optional after about minute 2.
- Timers pause while the app is hidden, and every timer loss is recoverable.

**Hearing.** Every audio cue has a visual twin:
- ping → badge and toast;
- Suitcase whoosh → sparkle;
- court day → card.

**Photosensitivity.** The crit and rabbit flashes are local and last ≤ 2 frames at ≤ 1 Hz.

**Commitment matrix:**

| Need | Tier |
|---|---|
| Low vision | A (large text, contrast) |
| Colour blindness | A |
| Blindness | C. **Screen-reader readable:** the disclaimer, About and the sources list, which are HTML. **Canvas, and not readable:** the play surface, settings, the chat and the share sheets. Reason: the Godot web export draws into one canvas with no accessibility tree. Deferred, not promised: an HTML `aria-live` region fed by the JS bridge for ticker headlines and chat pings. |
| Deaf / hard of hearing | A |
| One hand | A (it is the design) |
| Limited dexterity | A |
| Switch input | C (reason: the tap verb) |
| Cognitive | A (one new thing at a time, progressive HUD) |
| Photosensitive | A |
| Vestibular | A |

### 7.4 Keyboard (desktop)

- Space or Enter taps the Magician.
- The **S** key catches a Suitcase while one is on screen.
- The digit keys 1-4 switch tabs.
- Tab / Shift-Tab traverse cards and buttons. The focus ring has ≥ 3:1 contrast.
- Esc pops one layer, the same as host back.
- No focus traps; the reset modal starts focused on "התחרטתי".
- **HTML surfaces** (N1, O8) use native browser focus. **Canvas surfaces** use Godot focus neighbours, with the focus ring drawn in the ≥ 3:1 token `#8FE3FF`.

---

## 8. Microcopy table (every UI string defined here)

**Budgets** are the maximum length in Hebrew characters, counting spaces, excluding the `{placeholders}`' values. **Overflow** (revised for the pixel font; engine review O-U3):
- **Build time is the real guard.** A lint measures every string in pixels, using the real proportional font, against its box at *both* text scales (3 and 4). An overflow fails the build. The lint runs next to the §6.3 poll-number lint.
- **At runtime:**
  - Body copy wraps to 2 lines, then ellipsis.
  - Labels use ellipsis only.
  - A label drawn at scale 4 (large-text mode) may step down one whole scale to 3 (75%) before ellipsis. There is no fractional shrink.
  - Ellipsis is last resort. **A ★ string may never ship truncated,** because its punchline sits last; the lint enforces this.
- The character budgets below remain the writers' guide. Proportional advances make them conservative.

**Gender and plurals.** `ICU` marks an ICU MessageFormat string. Gendered system lines use `{g, select, female {…} other {…}}`. Plurals use the Hebrew CLDR categories `one | two | other`, plus explicit `=0` where the copy differs.

**Legend for the "?" column:** ★ = the chrome carries a joke; ⚖ = a legal line (do not edit for laughs).

| ID | String | Location | Max | ? |
|---|---|---|---|---|
| load.1 | מקפל מזוודות… | Hand-off bar / N0 splash (HTML) | 18 | ★ |
| load.2 | מחמם את הכובע… | Hand-off bar / N0 splash (HTML) | 18 | ★ |
| load.3 | מתייעץ ביטחונית… | Hand-off bar / N0 splash (HTML) | 18 | ★ |
| load.bar.label | טוען את המשחק | Hand-off bar (HTML `aria-label`, not shown on screen) | 14 | |
| disc.title | רגע לפני הסבב | Splash title | 16 | |
| disc.l1 | זו סאטירה. הדמויות הן קריקטורות פיקסל, ומה שהן עושות כאן בדיוני. | Splash | 80 | ⚖ |
| disc.l2 | אין כאן טענה עובדתית על אף אחד. ציטוטים אמיתיים מסומנים כציטוט, עם מקור. | Splash | 80 | ⚖ |
| disc.l3 | המשחק לא קשור לאף מפלגה או מועמד, ולא ממומן על ידי אף מפלגה, מועמד או מזוודה. | Splash | 85 | ⚖★ |
| disc.l4 | ואין כאן המלצה להצביע לאף אחד. | Splash | 40 | ⚖ |
| disc.by | מאת <מפרסם> · <מייל> · אודות | Splash footer | 50 | ⚖ |
| disc.btn.sound | עם סאונד | Splash button | 10 | |
| disc.btn.quiet | בשקט | Splash button | 8 | |
| disc.btn.quiet.cap | אני בישיבה | Caption under "בשקט" | 12 | ★ |
| title.round | Line 1: סבב בחירות מס׳ {n} / line 2: {publicMood} | Title state / election card | 20 / 34 (wrap-2-line; the punchline is never truncated) | ★ |
| mood.1 | הציבור נרגש | rounds 1-2 | 14 | ★ |
| mood.3 | הציבור נרגש. בערך. | rounds 3-4 | 20 | ★ |
| mood.5 | הציבור נרגש. שמישהו יבדוק אותו. | round 5 | 31 | ★ |
| mood.6 | הציבור נרגש. הוא אמר שהוא בסדר. | rounds 6-9 | 32 | ★ |
| mood.10 | הקלפי ביקשה חופשה. | rounds 10-19 (from the deck) | 20 | ★ |
| mood.20 | מישהו בדק שהציבור בסדר? | rounds 20 and up (from the deck) | 24 | ★ |
| hud.countdown | 27.10 · {d, plural, one {עוד יום אחד} two {עוד יומיים} other {עוד # ימים}} | Ticker chip (2 lines) | 12 per line | ICU ★ (echoes "עוד") |
| hud.countdown.today | 27.10 · היום | Chip | 12 | |
| hud.countdown.after | משא ומתן · יום {n} | Chip after the election | 16 | |
| hud.rate | {n} ₪ לשנייה | Under the counter | 16 | |
| hud.seats | מנדטים | Row B label | 8 | |
| hud.seats.blackout | חסוי עד 27.10 | Row B stamp | 13 | ⚖ |
| hud.susp | חשד | Thermometer label | 4 | |
| hud.susp.hot | מבעבע | Suspicion ≥ 75% | 6 | |
| hud.susp.boil | רותח! | Suspicion ≥ 95% | 6 | |
| hud.cottage.tip | מדד הקוטג׳: הקופה שלך גדלה. הקוטג׳ קטן. | Cottage tooltip | 42 | ★ |
| hud.ticker.tag | מבזק | Ticker anchor | 5 | |
| hud.cta.election | עוד סבב! | Prestige button | 9 | ★ (title reuse) |
| hud.mute / unmute | השתקה / ביטול השתקה | 🔊 accessible label | 12 | |
| hud.settings | הגדרות | ⚙ accessible label | 7 | |
| dubi.firsttap | אין כלום! אין כלום! | Dubi bubble, tap 1 | 20 | ★ (words owned by the deck) |
| dubi.buy | לקנות! לקנות! | Dubi fallback P1 | 14 | ★ |
| dubi.elect | בחירות! בחירות! | Dubi fallback E1 | 16 | ★ |
| tab.sources | מקורות | Tab | 7 | ★ (funding / media sources) |
| tab.spins | ספינים | Tab | 7 | |
| tab.coalition | קואליציה | Tab | 8 | |
| tab.dossier | תיקים | Tab | 7 | ★ (legal cases / bags) |
| toast.spins | נפתחו ספינים. דובי כבר חוזר עליהם. | Unlock toast | 38 | ★ |
| toast.dossier | נפתח לך תיק. | Unlock toast | 14 | ★ |
| card.buy.first | לקנות · {price} ₪ | Source pill, first purchase | 16 | |
| card.buy.more | עוד אחד · {price} ₪ | Source pill, later purchases | 18 | ★ |
| card.yield | {n} ₪ לשנייה | Card subline | 16 | |
| card.owned | ×{n} | Card | 5 | |
| card.locked.name | מקור עלום | Locked source | 10 | ★ |
| card.locked.cap | יתגלה כשיהיה לך מספיק | Locked caption | 24 | |
| spin.buy | להפיץ · {price} ₪ | Spin pill | 16 | |
| spin.fatigue | שחוק | Spin-fatigue tag | 5 | ★ |
| spin.fatigue.cap | כבר שמעו את זה | Fatigue caption | 16 | ★ |
| chat.title | קואליציה 61 | Chat header (plus the lock icon) | 12 | |
| chat.members | {n} משתתפים | Header status | 14 | |
| chat.typing | {name} {g, select, female {מקלידה} other {מקליד}}… | Header status | 24 | ICU ★ |
| chat.threats | {k, plural, one {איום פרישה פתוח} two {שני איומי פרישה פתוחים} other {# איומי פרישה פתוחים}} | Header status | 26 | ICU ★ |
| chat.pinned | נעוץ: ההסכם הקואליציוני · טיוטה {n} | Pinned bar | 36 | ★ |
| chat.today | היום | Day divider | 5 | |
| chat.unread | {n, plural, one {הודעה אחת שלא נקראה} other {# הודעות שלא נקראו}} | Divider | 24 | ICU |
| chat.pay | סגרנו · {price} ₪ | Demand / ultimatum pill | 18 | ★ |
| chat.pay.short | חסר {n} ₪ | Pill while unaffordable | 14 | |
| chat.paid | שולם | Stamp | 5 | |
| chat.reply.1 / .2 / .3 | העברתי. / סגור. / בוצע. אין כלום. | Player auto-reply (rotating) | 14 | ★ |
| chat.ultimatum | אולטימטום | Ultimatum label | 9 | |
| chat.deleted | ההודעה נמחקה | Paid ultimatum | 12 | ★ |
| chat.sys.created | הקוסם יצר את הקבוצה ״קואליציה 61״ | System | 36 | |
| chat.sys.joined | {name} {g, select, female {הצטרפה} other {הצטרף}} לקבוצה | System | 30 | ICU |
| chat.sys.left | {name} {g, select, female {עזבה} other {עזב}} את הקבוצה | System | 30 | ICU (brief) |
| chat.sys.removed | {name} {g, select, female {הוסרה} other {הוסר}} על ידי מנהל | System | 34 | ICU (brief) ★ |
| chat.sys.added | {name} {g, select, female {צורפה} other {צורף}} על ידי מנהל | System | 34 | ICU |
| chat.sys.transfer | {name} {g, select, female {עזבה · צורפה} other {עזב · צורף}} ל״{to}״ | System after the banner | 44 | ICU (brief) |
| chat.sys.rejoin | להחזיר לקבוצה · {price} ₪ | Pill on a "left" line | 24 | |
| chat.sys.brawl | {a} ו{b} רבים. שתי השורות הוקפאו. | System | 44 | |
| chat.brawl.btn | צאו החוצה | Brawl button | 10 | (brief, from the record) |
| chat.brawl.after | נוצרה קבוצה חדשה: ״המסדרון״ · 2 משתתפים | System, plus the muted counter "{n} הודעות" | 40 | ★ |
| chat.sys.muted | {who} ביקשו רשות דיבור · נדחה | System (+ pixel mute icon) | 36 | |
| chat.sys.cleared | הקוסם ניקה את הצ׳אט. לקראת סבב בחירות {n}. | System, new round | 42 | ★ |
| chat.empty | שקט בקבוצה. זה לא יחזיק. | Empty state | 26 | ★ |
| chat.composer | פה מדברים רק בשקלים | Disabled composer | 22 | ★ |
| chat.transfer.title | חלון העברות | Transfer banner | 12 | (brief) |
| chat.transfer.line | {from} ← {to} · כולל דמי אחזקה | Transfer banner | 44 | |
| court.title | יום משפט | Court card | 9 | |
| court.body | הקוסם בדוכן העדים. ההכנסות מואטות. | Court card | 38 | |
| court.timer | עדות: {mm:ss} | Court card / chip | 12 | |
| court.postpone | התייעצות ביטחונית · {price} ₪ | Primary button | 28 | ★ (brief, from the record) |
| court.testify | להעיד | Secondary button (collapse) | 6 | |
| court.chip | יום משפט · {mm:ss} | Collapsed chip | 18 | |
| court.stamp | נדחה | Stamp after postponing | 5 | |
| elect.title | סבב בחירות מס׳ {n} | Election card | 20 | |
| elect.reset | מתאפס: הכסף, המקורות, הספינים והקואליציה. | Election card | 44 | |
| elect.keep | נשאר: הבסיס הנאמן (+{x}% לכל הכנסה, לתמיד). | Election card | 44 | |
| elect.keep.cases | וגם התיקים. | Election card (confirmed: suspicion keeps a floor, pitch §11 Q8) | 12 | ★ |
| elect.go | לפזר את הכנסת | Primary button | 14 | |
| elect.cancel | עוד לא | Secondary button | 7 | |
| flash.next / skip | לסבב הבחירות הבא / דלג | Dubi flash buttons | 18 | |
| headline.title | מבזק | Headline card | 5 | |
| headline.quote | ציטוט | Tag before a real quote | 5 | ⚖ |
| headline.source | מקור: {outlet}, {date} | Headline card | 40 | ⚖ |
| headline.link | למקור | External link | 6 | |
| ret.* | (see §7.1: 4 titles, 4 bodies) | Return card | title 20 / body 40 | ★ |
| ret.gain | +{x} ₪ | Return card | — | |
| ret.chat | {n, plural, one {הודעה חדשה אחת בקואליציה} other {# הודעות חדשות בקואליציה}} | Return card | 30 | ICU |
| ret.cap | הכובע סופר עד {h} שעות. גם לו יש גבולות. | Return card | 40 | ★ |
| ret.btn | לאסוף | Return button | 6 | |
| set.title | הגדרות | Settings sheet | 7 | |
| set.g.sound / comfort / game | סאונד / נוחות / המשחק | Group headers | 8 | |
| set.sfx / music | צלילים / מוזיקה | Toggles | 8 | |
| set.motion | תנועה מופחתת | Toggle | 14 | |
| set.motion.cap | בלי טיקר רץ, בלי רעידות, בלי קפיצות. | Caption | 40 | |
| set.vibe | רטט | Toggle | 4 | |
| set.large | טקסט גדול | Toggle | 10 | |
| set.large.cap | לקריאה ממרחק זרוע. | Caption | 20 | ★ |
| set.on / off | פועל / כבוי | Toggle state | 5 | |
| set.about | אודות ומקורות | Row | 14 | |
| set.reset | איפוס התקדמות | Danger row | 14 | |
| reset.title | בטוח? | Confirm | 6 | |
| reset.joke | זה כמו פיזור הכנסת, רק בלי בחירות חוזרות. | Confirm line 1 | 44 | ★ |
| reset.body | כל ההתקדמות תימחק לתמיד: כסף, סבבי בחירות, תיקים ואלבום. | Confirm line 2 | 52 | |
| reset.go | למחוק הכול | Destructive button | 11 | |
| reset.cancel | התחרטתי | Cancel button | 8 | ★ |
| reset.done | נמחק. אין כלום. | Toast | 16 | ★ |
| about.* | (see §6.2, lines 1-7) | About | 120 per paragraph | ⚖ |
| about.sources | מקורות וציטוטים | About section | 16 | |
| about.who / contact / ver | מאת <מפרסם> / לפניות: <מייל> / גרסה {v} | About | 30 | ⚖ |
| about.share | לשתף את המשחק | About button | 14 | |
| blk.title | שקט לפני הקלפי | O11 | 16 | ⚖ |
| blk.body | עד סגירת הקלפיות (27.10, 22:00) לא נציג פה מספרי מנדטים. אנחנו לא סקר, ולא מחפשים עוד תיק. | O11 | 95 | ⚖★ |
| blk.btn | הבנתי | O11 | 6 | |
| night.title | הקלפיות נסגרו. | O12 | 16 | |
| night.body | הבחירות נגמרו. הקואליציה? עוד לא. | O12 | 36 | ★ |
| night.btn | למשא ומתן | O12 | 10 | |
| share.* | (see §5.1-5.4) | Share sheet / cards / OG | as listed there | ⚖★ |
| share.btn / save / close | לשתף / לשמור תמונה / סגור | Share sheets | 11 | |
| share.printing | מדפיס… | Receipt and result preview while the card renders | 7 | ★ (a thermal receipt) |
| share.receipt.title | הקבלה החודשית | Sheet / תיקים button | 14 | |
| share.result.btn | לשתף תוצאה | תיקים button | 11 | |
| share.copied / saved / fail | הקישור הועתק. / התמונה נשמרה. / השיתוף לא עבד. נסה שוב. | Toasts | 26 | |
| share.deeplink | מישהו שרד {r} סבבי בחירות ו־{c} ימי משפט. תורך. | Toast on a share-link entry | 44 | ICU (plural of r and c, as in §5.2) |
| dos.title / stats | תיקים · סבבי בחירות: {n} · ימי משפט: {n} · בקשות דחייה: {n} · סה״כ נשלף מהכובע: {x} ₪ · מזוודות שנתפסו: {n} · שהגיעו ליעדן: {m} | Dossier tab | 30 per row | ★ (the last row) |
| album.title | אלבום: תמיד בפריים | Album sheet | 20 | (brief) |
| album.new | נכנס לאלבום. | Toast | 13 | |
| album.trophy | שלום בית בפריים | Trophy | 16 | (brief) |
| sys.rotate | תחזיק את הטלפון לאורך. | Rotate overlay | 24 | |
| sys.rotate.cap | הקוסם עובד רק בעמידה. | Rotate caption | 22 | ★ |
| sys.offline | אין חיבור. הכובע עובד גם בלי. | Toast | 30 | ★ |
| sys.error | משהו נתקע. | Error title | 11 | |
| sys.reload | לרענן | Error button | 6 | |
| sys.close | סגור | Every sheet's bottom button | 5 | |
| sys.back | חזרה | Chevron accessible label | 5 | |

**Red-line review of my own copy.** None of the strings above touches:
- October 7, hostages, soldiers or children;
- any group of people as the punchline;
- any "vote for X";
- any poll figure or "who's leading" claim.

Every legal matter is left to `[GD]` lines, which must use the fact sheet's wording.

---

## 9. Hand-offs and conditional objections

### Hand-offs

**Game Designer:**
- The tuning requests at the end of §2.4.
- A `poll_like` tag and a `real_quote{source,date}` tag on every copy-deck line.
- Headline slots H1-H3, H-catch and H-cottage.
- A dated source for "fuel ₪8.25/L" (§5.1).
- Confirm whether suspicion persists across rounds (row `elect.keep.cases`).

**2D Artist:**
- The Cottage cup, with its pixel-loss states (≥ 12).
- The thermometer, in 4 states, with the magnifier → gavel icon swap.
- Segmented seat pips.
- Pixel icons: lock, pin, clock, trash, gear, speaker (plus the muted slash).
- The receipt paper texture.
- Chat bubbles in the palette, with **no WhatsApp green**.
- Keep the §7.3 contrast ratios.

**Animator:**
- Coin burst, the logo exit on tap 1, and the seat-pip flight from chat to Row B.
- Reduced-motion variants for every item in §7.3.

**Audio Director:**
- Cues: tap, first-tap squawk, chat ping, Suitcase whoosh, court day, the "עוד סבב!" fanfare.
- The ping must not fire during a Dubi squawk (duck, or queue ≥ 300 ms).

**Game Developer:**
- `history.pushState` per layer (§1.2).
- LRI/PDI isolation of numbers (§3.5).
- Hebrew text via a Godot `Label` / `RichTextLabel` with the bitmap `FontFile`; `PxText` for numerals only. N0, N1, the hand-off bar and O8 are HTML in `shell.html`.
- The blackout clock and build lint (§6.3).
- `audioSession` set to `ambient`.
- Feature-detect `navigator.vibrate`.
- Autosave on `pagehide`.
- The funnel events (§2.4).

**Technical Artist:**
- A Hebrew pixel font covering the glyph range in §3.5.
- Body text ≥ 14 px, and ≥ 17.5 px in large-text mode.

### Conditional objections

**Status after the reconcile wave:**
- Objection 1 was accepted by the designer (pitch §2 item 13) and is closed.
- Objection 2 did not fire: the roulette is random, post-launch and off from 23.10, and no line says anyone "leads".
- Objection 2's "Sleepy Bibi" fallback is **retracted**, per the designer's C1: that game is premised on the October 7 warnings.

Both are kept below as a record.

```yaml
objection:
  skill_or_agent: hud-design
  against_artifact: pitch.md (if any of: Gotliv court meter, public-broadcaster bar, departure board, spin-fatigue meter, poison-machine view counter is placed in the persistent HUD)
  reason: |
    At 390x844 the HUD already carries 2 critical elements (counter, seats bar),
    1 conditional-critical (suspicion) and 3 peripheral/informational (Cottage
    Index, countdown, ticker). A seventh persistent meter exceeds the region
    criticality budget (<=2 critical per region) and puts a first-minute
    player's glance over 4 competing bars, violating hud-design DOG 1 and the
    one-new-thing-at-a-time FTUE (onboarding-ftue-design DOG 4).
  proposed_alternative: |
    Attach each secondary meter to the object it belongs to: Gotliv's meter as
    a ring on her chat avatar and her card; broadcaster->friendly-channel bar on
    Karhi's "השלט" card; departure board as stage-background art (diegetic);
    spin fatigue as the "שחוק" tag; view counter on the bot-farm card. They
    surface to the HUD only as a one-line toast when they cross a threshold.
```

```yaml
objection:
  skill_or_agent: ux-designer (blackout / red-line enforcement)
  against_artifact: brief-round2 "threshold roulette" and any copy-deck line using "Eisenkot leads the polls"
  reason: |
    Showing real lists (Winter, Hendel/Zelekha, Haskel) bobbing above/below a
    3.25% line, or stating who leads the polls, is a poll-like "who's leading"
    depiction of real parties. It breaks the brief's standing red line ("no
    fake polls or who's-leading numbers") at every date, not only during the
    23.10-27.10 legal blackout, and it would be screenshotted out of context.
  proposed_alternative: |
    Keep the joke, drop the prediction: the roulette is a literal roulette
    wheel. The lists' names ride on the wheel's pockets and the "אחוז החסימה"
    line is a pocket colour; each spin is visibly random, with no percentages
    shown and a UI tag "תוצאה אקראית. בערך כמו סקר." Disabled entirely from
    23.10. Replace "leads the polls" with a record-safe line about Yashar's own
    campaign game ("Sleepy Bibi", fact sheet [F]).
```
