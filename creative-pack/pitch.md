# "עוד סבב": creative pitch

**Owner:** Game Designer · **Status:** pre-build pitch · **Inputs:** `brief.md`, `brief-round2.md`
(round 2 wins) · **Companion files:** `voice/copy-deck.md` (all game-content Hebrew),
`references.md` (every real fact used).

---

## 1. My take

You're the Magician. You pull shekels out of a hat, pay your partners so they stay in the group
chat, dodge the courtroom one "התייעצות ביטחונית" at a time, and once you have 61 you do the one
thing you're best at: call another election. The board resets and the base grows. The counter
ticks up ("סבב בחירות מס' 6. הציבור נרגש."), and Dubi the parrot reads the news he was told to
read.

**Why "עוד סבב" is the right title:** in an idle game, prestige is the loop you choose to restart
on purpose. Here that loop is the satire. Every idle game quietly promises you'll reset and do it
all again. This one says it on the box. The player's best move and the country's running joke are
the same button, so the title explains the mechanic, the mechanic makes the joke, and the share
card ("שרדתי 6 סבבים") sells both.

**One risk in the title, with a fix.** In Israeli Hebrew, "סבב" alone often means a round of
fighting ("עוד סבב בעזה"). That meaning leads to a red line. To keep the title tied to elections:
- the title screen, icon and share card always show a ballot box next to the words;
- every in-game use says "סבב בחירות" in full;
- the word "סבב" never appears next to anything that looks like the military.

This is a UX/2D brief note, not an objection to the title.

---

## 2. My changes (and why)

1. **Launch is 4 weeks and the calendar is the deadline.** The election is 27.10, 29 days from
   today. The joke peaks before election day, and from 23.10 the game must stop showing seat
   comparisons. My recommendations:
   - ship the spine by about 13.10 so the share cycle gets two weeks;
   - have the post-election "משא ומתן קואליציוני" mode ready as a patch by 27.10.
   
   Everything in the "post-launch" column below waits.

2. **The opposition needs mechanics, not only headlines.** "It roasts *everyone*" fails if the
   coalition gets systems and the opposition only gets ticker lines. Each opposition figure is an
   **event card** with one mechanical twist that *is* their joke (§7):
   - Eisenkot's card switches off rabbits while it's on screen ("politics without magic").
   - Gantz joins when a partner quits, and his rotation bar sits at 99% forever.
   - Liberman's card greys out every button.

   The cards are cheap: one card template and eight behaviours.

3. **Real price tags are the item prices.** Where the record has a number, that number is the
   in-game price or effect:
   - the bottle-deposit spin costs 4,000 ₪ and gives +30 agorot per tap;
   - the pistachio spin costs 10,000 ₪;
   - Wing of Zion costs 750,000,000 ₪;
   - the travel-expense cosmetics use the reported amounts.

   The joke then writes itself and stays sourced.

4. **Cut the 2018 Gaza cash from the suitcase.** The DOHA suitcase stands only for Qatargate and
   the Doha sticker. It never gets a Gaza destination, and "leadership comes with a price" goes
   unused. Public talk links that cash to October 7, so naming it pulls a red line into the
   running gag. The suitcase's "second address" in story beat 4 is **an aide's desk**, which
   matches the record exactly.

5. **Don't reference "Sleepy Bibi."** Its premise is dodging the October 7 warnings. Eisenkot gets
   roasted on "ישר" and on having no magic, never on sleep.

6. **Cut the "Total Victory" cap.** "ניצחון מוחלט" is the Gaza-war slogan. Replace it with a
   **"הכל בסדר" cap**: same stats (+10% confidence, −10% accuracy), same Channel-14 hook, no war.

7. **Refer to the threshold lists by leader, not by list name.** "המילואימניקים" names reserve
   duty, which is a red line. The threshold-roulette card shows the caricatures (Winter, Hendel
   with Zelekha, Haskel) and never the list name.

8. **Threshold roulette must never read as a poll.** Which list sinks is random and uniform every
   round. It is never tied to real data and is disabled from 23.10. Otherwise a list that "always
   drowns" is a fake poll. It's also post-launch, because it's a new mini-game.

9. **Make the Illouz defector a generic MK.** Illouz's quote stays as a ticker line. A named MK
   walking into Liberman's building would be a plausible-sounding false fact.

10. **Mordechai David: recommend dropping him, not only flagging him.**
    - The legal risk is high.
    - "Streaming at an opposition figure" is too close to harassment as a player action.
    - His only good line ("לך תשרת ותחזור אליי") is about military service.

    The poison machine's live-view counter already carries the "big views, no engagement" joke.
    **Yair Netanyahu** stays off at launch.

11. **Upkeep and postponements scale as a percentage, never a flat price.** Idle income grows
    exponentially, so a flat or doubling price is soon free, and the triangle collapses (§10).

12. **Dubi only repeats.** The parrot never asks, reasons or jokes in his own words. Every quoted
    Dubi line is a repeated talking point ("אין כלום! אין כלום!"). The ticker is his newsroom
    reading the script. The character stays a single, clean joke.
13. **Secondary meters live on their objects, not in the HUD.** I accept UX's `hud-design`
    objection (first-minute §9):
    - Gotliv's court meter is a ring on her chat avatar.
    - The public-broadcaster bar sits on Karhi's "השלט" card.
    - The departure board is stage-background art.
    - Spin fatigue is the "שחוק" tag on the spin card.
    - The view counter sits on the bot-farm card.
    - The persistent HUD stays at: the counter, seats, suspicion, the Cottage Index, the countdown
      and the ticker.

### Launch spine vs post-launch, ranked by laughs per unit of build cost

| System | Build cost | Laughs | Call |
|---|---|---|---|
| Coalition as group chat "קואליציה 61" | Low: a list of text bubbles plus a pay button | Highest in the game | **Launch.** It *is* the coalition system. |
| "התייעצות ביטחונית" excuse that grows | Near zero: copy on a cooldown | High, and it builds every time | **Launch** |
| Suitcase lands on an aide plus "אני לא מכיר אותו" | Low: one button, one flag | High | **Launch** |
| Brawl, "צאו החוצה" | Low: a chat event, one button | High | **Launch** |
| Gotliv's transfer window | Low-medium: a chat event plus a row swap | High | **Launch** |
| Household receipt share card | Medium: one render | High, and it's the share engine | **Launch** |
| Cottage Index | Very low: one HUD sprite | Medium, a slow burn | **Launch** |
| Pardon desk | Low if it's stamp text on a modal | Medium-high | **Launch as text**, mini-game post-launch |
| Real calendar countdown plus 23.10 lock | Low | Medium, and legally load-bearing | **Launch.** Must-have. |
| Opposition event cards (8) | Medium: one template | High, and they're the "roasts everyone" proof | **Launch** |
| Spin fatigue (word-salad ticker) | Low: string ops | Medium | Launch if time allows |
| Post-election "משא ומתן קואליציוני" mode | Medium | High, timely | **Patch on 27.10** |
| Threshold roulette | Medium-high: a new mini-game | Medium | Post-launch |
| Nameless Party spawn | Low-medium | Medium | Post-launch |
| Liran and Tomer in the frame | Medium: several scenes plus an album | Medium, niche | Post-launch |
| Kaia, the Pink Front drum line, the departure board, the travel-expense shop | Medium each | Medium each | Post-launch |
| Mordechai David, Yair Netanyahu | Unknown | Legal risk | Drop / off |

---

## 3. Three alternative titles (kept as a record; the client chose "עוד סבב")

- **"שולף מהכובע"**: the core verb as the title, with the idiom built in. It's strong, but it
  sells the tap rather than the loop.
- **"אין כלום"**: the catchphrase as an ironic title for a game packed with stuff. It turns a real
  quote into a brand, which is more legally awkward.
- **"קואליציה 61"**: the group chat as the hook. It reads as a "coalition sim" and undersells the
  satire of the never-ending elections.

---

## 4. The loop mapped to the idle engine

| Engine slot (Monkey Bananas) | Our thing | The joke it carries |
|---|---|---|
| Tap the big thing | **The Magician's hat**: every tap pulls shekels | "שלף מהכובע": money from nowhere |
| Crit on tap | **The rabbit** hops out | The Bugs Bunny trial: the rabbit keeps its right to remain silent |
| 8 producers | **8 money sources**: taxpayer → golden checkbook | The payers are drawn with sympathy; the joke is where the money goes |
| 15 upgrades | **Spins** (14, see deck §D) | Real affairs as upgrades priced at their real numbers |
| Golden drifting bonus | **The DOHA suitcase** | It arrives and lands somewhere, and nobody knew |
| Prestige ("evolve") | **Early elections.** The button is "עוד סבב!" and the card is "לפזר את הכנסת" (UX chrome). Gated at **61**. | Calling another election is the optimal play, and the button is the title |
| Permanent multiplier currency | **הבסיס** (the loyal base) | The only thing that survives an election |
| Perks | **Coalition deals** (permanent, bought with base) | The only promises that are kept |
| Trophies | **תיק הישגים**, a section inside the "תיקים" tab | A trophy case that is a case file |
| Narrator | **Dubi**, the spokes-parrot | He can only repeat the talking points |
| 4 eras | Balfour → Knesset → Court → Washington | The empire moves up the ladder |
| ~120 ticker headlines | Dubi's ticker | Deadpan news-speak applied to the absurd |
| *New:* upkeep drain | **Group chat "קואליציה 61"** | Partners are paid to stay, or they "left the group" |
| *New:* hazard meter | **חשד (suspicion) → court day** | Shady money is faster; the court slows everything |
| *New:* event cards | **The opposition** | Each card's mechanic is its joke |

**Seats:**
- Your own seats grow with your base and your top source tier.
- Partners add their seats while paid.
- Reaching 61 replaces the ticker with the gold "עוד סבב!" button.
- Seat numbers are abstract game values, never real polling or current-Knesset numbers.

---

## 5. The first five minutes

Aligned to UX's `ftue-flow` (first-minute §2). UX owns *how* each beat is shown; this table owns
the numbers that make the beats land when UX says. t=0 is the tap on the disclaimer button.

| Time | The player sees | The player does | What's learned |
|---|---|---|---|
| **~0:02** | Title state, then the first tap: coins, "+1 ₪", Dubi's squawk "אין כלום! אין כלום!". Ticker H1: "על פי פרסומים זרים, יש כובע." | Taps the hat | The verb, with no text, and the first laugh |
| **~0:05** | **Tap 7: the scripted first rabbit.** It pays ×4 (+4 ₪). Ticker H2: "ארנב קפץ מהכובע. קיבל זימון לעדות." | Keeps tapping | Crits exist; the trial runs in the background |
| **~0:10** | Tap 12: 15 ₪, and the "משלם המסים" card's pill turns gold. | Buys it. Ticker H3: "נרכש משלם מסים נוסף. הוא נאנח. זה נחשב הסכמה." | Buying makes passive income |
| **~0:30** | **The first Suitcase**: slow, and its outcome is always cash. On a catch, H-catch: "תפסת מזוודה. בלשכה: 'איזו מזוודה?'". On a miss: "המזוודה הגיעה ליעדה. לא ידענו." | Catches it or misses it. Both are funny. | The golden bonus; the running gag is planted |
| **~0:45** | **The chat pings.** Ben Gvir: "צריך תקציב לביטחון לאומי. היום, לא מחר 🔥", with the pill "סגרנו · 60 ₪". | Pays. Seat pips fly, and the seats bar appears at 34/61. | Partners give seats; 61 is the goal |
| **~2:00** | Spins unlock at `lifetime_earned` 300 ₪, with the toast "נפתחו ספינים. דובי כבר חוזר עליהם." | Buys S01, the bottle deposit (4,000 ₪, later), or saves | Spins exist |
| **~3:00** | The first shady source (the Generous Friend, 500 ₪) is affordable. The **suspicion thermometer** appears, then the toast "נפתח לך תיק." | Buys it: much more income, and suspicion ticks up | Fast money raises suspicion |
| **~3:30** | The Cottage cup appears at `lifetime_earned` 1,000 ₪, with H-cottage "הקופה עברה 1,000 ₪. הקוטג' איבד פיקסל." | — | Ambient satire |
| **3:00+** | The first **ultimatum** is possible (UX U1: `demands_paid ≥ 2` and ≥ 180 s). Ben Gvir's forwarded quit threat arrives with a 90 s timer. | Pays, or lets him walk and later taps "להחזיר לקבוצה" | Timers exist, and losses are recoverable |
| **~5:00** | Seats at about 55/61, suspicion about 50%, and Gafni's cheap tie on offer | Chooses: pay Ben Gvir, or buy Gafni's tie | The triangle is live; the goal is in sight |

**Targets:**
- The first "עוד סבב!" lands at about 7-9 minutes, and Dubi's first flash (deck B1) fires.
- Later rounds lengthen along the √(total earned) base curve.

---

## 6. The cast as mechanics: the coalition

- **Ben Gvir:**
  - *Mechanic:* the highest seats, the most frequent quit threats. His threats arrive as a
    "forwarded many times" message.
  - *The joke:* the threat is a timetable, not news.
- **Smotrich:**
  - *Mechanic:* as finance minister he raises VAT, which buffs the VAT source, and as party leader
    he demands money, a drain.
  - *The joke:* one man, both sides of the ledger.
- **Deri:**
  - *Mechanic:* stable and expensive. He "left the government, not the group": he still counts
    his seats but can't be removed.
  - *The joke:* the disqualified minister who decides the ministers.
- **Goldknopf:**
  - *Mechanic:* his demand bar never resets, and every payment raises the next price.
  - *The joke:* the politician's price tag, never the community.
- **Gafni:**
  - *Mechanic:* the abstention broker. Paying him turns a lost vote into a tie. He "goes to the
    bathroom."
- **Levin:**
  - *Mechanic:* pay him and the court meter's fill slows. Skip him and he "petitions the High
    Court... wait."
- **Regev:**
  - *Mechanic:* a cheap seat. She demands a ceremony (a 3-second ribbon-cut tap) instead of
    money.
- **Gotliv:**
  - *Mechanic:* her own court meter. Near full, the "חלון העברות" fires: she moves to Ben Gvir's
    row with her upkeep, and he posts a countdown ultimatum.
- **Amsalem × Smotrich:**
  - *Mechanic:* the brawl freezes both income rows until you press "צאו החוצה". Then they move to
    the "המסדרון" group.
  - The brawl recurs between any two partners.
- **Karhi, "השלט":**
  - *Mechanic:* an upgrade line that drains the public-broadcaster bar into a friendly-channel bar
    (+base, +suspicion).
  - *Item review:* "ביקורת על סרט שלא ראיתי: 1/5".
- **May Golan:**
  - *Mechanic:* hire "phantom employees": cheap loyalty, and each one adds suspicion.
  - *Label:* "[A] police recommendation".
- **Distel-Atbaryan, "🔇":**
  - *Mechanic:* pass the next law instantly; audit risk rises.
- **Almog Cohen:**
  - *Mechanic:* the origin of the chat. System line: "[אלמוג כהן הוסר על ידי המנהל]". Also the
    "poach a rebel" action.
- **Herzog, the pardon desk:**
  - *Mechanic:* a pardon request comes back stamped "נדרשים מסמכים נוספים". It's endless
    bureaucracy.
- **Trump:**
  - *Mechanic:* a one-time Washington item that wipes the Generous Friend's suspicion.
  - *Quote:* "Cigars and champagne, who the hell cares?"
- **Sara:**
  - *Mechanic:* a Balfour-era presence with no mechanic of her own.
  - Her record appears only as the bottle-deposit spin. She is not named in that copy, and the joke
    is the size of the upgrade.

## 7. The cast as mechanics: the opposition, roasted just as hard

- **Lapid, "איפה הכסף?":**
  - *Mechanic:* an audit card. It reveals one shady source and adds suspicion.
  - *The joke:* he asks, we answer "בכובע", and he keeps asking.
- **Bennett:**
  - *Mechanic:* a pledge card. He signs, live, not to back X, and the card flips when a timer runs
    out.
- **Eisenkot, "ישר":**
  - *Mechanic:* while his card is on screen, no rabbits.
  - *The joke:* politics without magic, and the audience wants a refund.
- **Gantz:**
  - *Mechanic:* he joins as a stand-in when a partner quits. His rotation bar sits at 99%, forever.
- **Liberman:**
  - *Mechanic:* every button on his card is grey: "לא יושב".
- **Golan:**
  - *Mechanic:* a merger card. The last two opposition cards fuse into one: one card, twice the
    arguing.
- **Mansour Abbas:**
  - *Mechanic:* a hidden seat source, visible only while Ben Gvir is offline.
  - *The joke:* "ביבי או טיבי" versus the talks, per Abbas. The target is the flip-flop.
- **The Nameless Party** *(post-launch)*:
  - *Mechanic:* spawns, drains seats, and dissolves by itself.
- **Threshold roulette** *(post-launch)*:
  - *Mechanic:* the lists bob around 3.25%; which one sinks is random.

**Behind a flag:**
- 🚩 Mordechai David: recommend dropping him.
- 🚩 Yair Netanyahu: off.
- 🚩 Easter eggs: Liran and Tomer, Kaia, the Pink Front drum line, the swing voter and his toast
  sauces.

---

## 8. The five story beats and the encore

The Hebrew for each beat is in the copy deck, §B.

1. **The hat that never runs out.** The Magician pulls 61 from an empty hat; the office says
   there's no hat.
2. **The partners discover the hat.** There are now 61 hands in it, and every pull needs a
   coalition agreement.
3. **The hat gets subpoenaed.** The rabbit keeps its right to remain silent, and the office asks
   for a postponement.
4. **The suitcase turns out to have two addresses:** Doha and an aide's desk. The aides are the
   suspects; the Magician is not.
5. **Washington wants a suitcase too.** It gets one, full of laundry, according to reports.
- **Encore:** the game ends when the elections end. That means round N+1. "אין סוף. יש עוד סבב."

---

## 9. Cadence: "something new every few minutes"

| Event | Cadence |
|---|---|
| Ticker line | Every 8-12 s. Conditional lines jump the queue. |
| Partner message | Every ~90 s at first, rising with the number of partners |
| Suitcase | Every 2-4 min |
| Opposition card | Every ~3 min, from the Knesset era on |
| Court day | When suspicion hits 100% |
| Story flash | Every election round |

---

## 10. DOG check: the money / suspicion / coalition triangle

**The loops:**
- **(+) Shady money:** shady money → faster income → more sources. This loop reinforces itself.
- **(−) Suspicion brake:** shady money → suspicion → court day (income ×0.5 until testimony ends).
  This loop balances the first.
- **(−) Coalition brake:** income → partners demand a percentage of income → seats. This loop
  balances income.
- **Election:** 61 seats → the election resets money and coalition, resets suspicion **to a rising floor** (§11, Q8) → the base grows.
  This is the intended runaway, bounded by the reset.

**The dominant-strategy risks, and how the design closes each one:**

1. **"Always postpone."**
   - *The risk:* the brief makes the postponement always work, with a doubling cost. Against
     exponential income, a doubling flat price is soon free, and suspicion stops mattering.
   - *The fix:* the postponement costs **5% × 2ⁿ of the current treasury**, where n is the number
     of postponements this round. By the 5th it costs 80%, so the player chooses to testify.
   - The cooldown still shrinks, so the gag escalates.
   - The postponement count resets on election.
2. **"Always pay everyone."**
   - *The risk:* if upkeep is flat, it's trivial.
   - *The fix:* each partner demands **a percentage of ₪/s**. The partners' seats add up to more
     than you need, so the question is *which subset*.
   - The cheapest subset keeps changing, because:
     - demand events spike one partner's price at random;
     - Goldknopf's price only climbs;
     - Gafni's tie is cheap but fragile;
     - Ben Gvir is big but quits most often.
   - There is no fixed cheapest set to memorise.
3. **"Clean money only."**
   - *The risk:* never buy shady sources, so suspicion never moves.
   - *The fix:* shady sources yield about 2.5× per shekel spent. The clean route is viable but
     about 40% slower per round, a legitimate style, not a trap.
   - The Pacifist-style trophy for it is on the bench.
4. **"Drop every aide."**
   - *The risk:* "אני לא מכיר אותו" resets suspicion to 0.
   - *The fix:* it's only possible while an aide holds suitcase money, and it costs a
     **permanent −3% base multiplier**. It's a panic button, not a routine.
5. **"Prestige the moment you hit 61."**
   - This is **intended as the optimum**, because it *is* the joke.
   - The base payout is √(total earned this round), so longer rounds still pay, and the speed
     route is rewarded with the trophy "חמש בפחות מארבע".
6. **Postpone plus aide-drop stacking:** capped. The aide-drop can't be used during a court day.

**Falsifiable claims:**
- No single choice at any of the three corners is strictly best across a round.
- Each corner's best move depends on a state the player can read on the HUD: the treasury, the
  seat meter, suspicion, and which partner is spiking.

**Legibility:**
- *Shown:* seats (n/61), suspicion, treasury, partner status in the chat, and the round counter.
- *Hidden:* partner demand weights and the suitcase outcome table.

---

## 11. Answers to UX's tuning and content requests (first-minute §2.4, §9)

All accepted. One comes with a design addition.

| # | UX request | Answer | Spec |
|---|---|---|---|
| Q1 | First purchase reachable in **12-16 taps** | **Accept** | Taxpayer price **15 ₪**; +1 ₪ per tap; the tap-7 rabbit pays ×4. So 15 ₪ lands on **tap 12**. UX's placeholder "10 ₪" and the name "משלם המסים העייף" yield to 15 ₪ and "משלם המסים". |
| Q2 | First demand affordable at **~45 s** | **Accept** | The first demand is a **fixed 60 ₪** (FTUE only). By about 45 s the player owns 3 taxpayers at 1 ₪/s each, plus taps. From demand 2 on, a demand costs **45 s of current ₪/s** (the percentage rule from §10). |
| Q3 | **No ultimatum before 3:00**; countdown **≥ 90 s** | **Accept** | Ultimatums are gated on UX U1 (`demands_paid ≥ 2 AND playtime_active ≥ 180 s`). **Every ultimatum timer is 90 s**, paused while the app is hidden. Gotliv's transfer countdown uses the same 90 s (deck §E). |
| Q4 | **Every timer loss recoverable** | **Accept** | A partner who walks leaves a "להחזיר לקבוצה" line that costs **1.5×** the missed demand. A missed Suitcase costs nothing. Court day only slows income. **Not a timer loss, by design:** the aide drop's −3% base is a deliberate player choice with a confirm, and it stays permanent (§10.4). |
| Q5 | **First rabbit on tap 7** | **Accept** | Scripted once, pays ×4 (see Q1). Later rabbits: 2% base chance, ×10, raised by spin S11. |
| Q6 | Fill **H1, H2, H3, H-catch, H-cottage** | **Done** | Copy deck §A.1: H1 = T25, H2 = T03, H3 = T01, H-catch = T26 (new), H-cottage = T02 at 1,000 ₪, plus H-miss and H-court. Also the thresholds UX left as `[GD]`: spins unlock at `lifetime_earned` **300 ₪**; the Cottage Index at **1,000 ₪**. |
| Q7 | A **`poll_like` tag** (and `real_quote`) on every line | **Done** | Deck §0 and a §A column. `poll_like:true` applies to Gotliv's card (it names a seat number) and the threshold-roulette card. B1 no longer says "61 מנדטים", so it passes UX's build lint. `real_quote` = the `[src]` tags, with source and date in `references.md`. |
| Q8 | Does **suspicion persist across rounds?** (row `elect.keep.cases`) | **Yes, as a floor.** Keep "וגם התיקים." | After election n, suspicion resets to **min(5% × n, 40%)**, not 0. |

**Why the Q8 floor (a design addition):**
- *It's the joke:* the cases don't close when the Knesset dissolves.
- *It's the system:*
  - Base growth makes later rounds faster.
  - The rising floor makes them *hotter*, so the suspicion corner of the triangle stays live in
    late rounds rather than fading to zero.
  - The cap stops late rounds from starting one purchase away from court.
- *Legibility:* the thermometer draws the floor as a hatched segment (a shape channel for UX's
  §7.3), so the player sees what carried over.
- *No new degenerate strategy:* the aide drop still resets suspicion to the floor, never below it.
