# UX Designer review of the copy deck (reconcile wave)

**Reviewer:** UX Designer · **Against:** `voice/review-rubric.md`, the five gates:

| Gate | Short name |
|---|---|
| 1 | Native |
| 2 | Funny |
| 3 | Short |
| 4 | True |
| 5 | Red lines |

**Reviewed:** `voice/copy-deck.md` sections A-I, and `pitch.md`, in the state they were in on 2026-09-28 after the designer's own reconcile edits (including §0 tags, §A.1 slot map, T26, and the §E/§H/§I seam rewrites). The designer's files were **not edited**.

**Verdict.** 21 objections. All of them are below, with rewritten lines:
- 20 are against single lines;
- 1 is deck-wide (balance).

**Everything else passes.** One of my two pre-registered objections is **dropped**; the other was **accepted and already applied** (§1).

---

## 1. My pre-registered objections (from `ux/first-minute.md` §9)

| # | Objection | Status | Why |
|---|---|---|---|
| P1 | Secondary meters kept out of the persistent HUD | **Closed (accepted)** | Pitch §2 item 13 places every one on its object: Gotliv's ring, Karhi's card, the departure-board art, the "שחוק" tag, the view counter on the bot-farm card. The persistent HUD stays at the six elements. Nothing to fire. |
| P2 | Threshold roulette and "Eisenkot leads the polls" | **Dropped** | Neither trigger fires:<br>• The roulette is post-launch, uniformly random, never tied to real data, off from 23.10, shown by leader and never by list name, and the card is tagged `poll_like:true`.<br>• No deck line says Eisenkot leads, and references.md lists "leads the polls" under *not used*. |
| P2 fallback | Replacing "leads the polls" with the "Sleepy Bibi" line | **Conceded to the designer's C1** | "Sleepy Bibi" is premised on the October 7 warnings, and the pitch §2.5 cut stands. My fallback was wrong. Eisenkot is roasted only through "ישר" and "no magic". |

**The live question: the roulette caption "3.25%: הקו שבין מפלגה לקבוצת חברים."**

**Decision: naming 3.25% is OK.** It is the **statutory** electoral threshold, a fact of the Knesset Elections Law (fact sheet via IDI, references #7). It is not an estimate of anyone's support, so it is not a poll figure. The card is `poll_like:true` anyway, so it never shows between 23.10 and 27.10.

For the build lint: the caption contains no "מנדט", "סקר", "מוביל" or "אחוז החסימה" within 3 words of a digit, so it passes as written.

**The second sentence fails, though:** "מי שטובע, לוקח איתו מנדטים."
- **Gate 4 (true):** a list below the threshold doesn't "take seats with it". Its votes are *burned* (the native term is "קולות נשרפים").
- **Gate 2 (funny):** it is explanatory, with no turn.

That is objection **UX-01** in §7.

---

## 2. Findings table

✓ = pass · ✗ = fail (objection in §7) · ~ = passes, with a note.

### A. Ticker

| ID | N | F | S | T | R | Note |
|---|---|---|---|---|---|---|
| T01 | ✓ | ✓ | ✓ | ✓ | ✓ | News-speak, with the reversal "זה נחשב הסכמה" last. Good H3. |
| T02 | ✓ | ✓ | ✓ | ✓ | ✓ | Callback plus a meta-HUD joke. Typography: "קוטג׳" takes a geresh (global note §5). |
| T03 | ✓ | ✓ | ✓ | ✓ | ✓ | The reversal lands in the last three words. |
| T04 | ✓ | ✓ | ✓ | ✓ | ✓ | Understatement: "3 לייקים". |
| T05 | ✓ | ✓ | ~ | ✓ | ✓ | Rule of three with the turn on "61 לפי הקוסם". 59 characters, at the cap; do not lengthen. Crowd counts are not polls, so `false` is right. |
| T06 | ✓ | ✓ | ✓ | ✓ | ✓ | The hedge "לפי הפרסומים" *is* the punchline, and it matches the record. |
| T07 | ~ | ✓ | ✓ | ✓ | ✓ | **Fixed in the current deck:** now reported speech with `[נוסח לאימות]` and no quote marks around Trump. "למי לעזאזל אכפת" is a rendering of "who the hell cares", which is acceptable while flagged. Optional polish once verified: "שאל למי בכלל אכפת". No objection. |
| T08 | ✓ | ✓ | ✓ | ✓ | ✓ | "גורמים בסביבת" applied to a suitcase; "עוברת פה" is a double meaning. |
| T09 | ✓ | ~ | ✓ | ✓ | ✓ | Same wording as B3's line. Fine as a callback, but don't use both inside one round. |
| T10 | ✓ | ✓ | ✓ | ✓ | ✓ | A circular excuse, plainly absurd. |
| T11 | ✓ | ~ | ✓ | ✗ | ✓ | **UX-02.** An invented stamp shown in quote marks as a real outcome reads as plausible fact. |
| T12 | ✓ | ✓ | ✓ | ✓ | ✓ | Protect this one. "זה לוח זמנים" reframes the threat. |
| T13 | ✓ | ✗ | ✓ | ✗ | ✓ | **UX-03.** A plain report that reads as a factual claim, and it duplicates the Smotrich chat demand. |
| T14 | ✓ | ✓ | ✓ | ✗ | ✓ | **UX-04.** It is plausible as news about a real MK. Anchor it to the player's action. |
| T15 | ✓ | ✓ | ✓ | ✓ | ✓ | Real quote; Dubi's doubled answer is the turn. |
| T16 | ✓ | ✓ | ✓ | ✗ | ✓ | **UX-05.** The pledge was that Lapid wouldn't become PM, not "לא ימליץ". |
| T17 | ✓ | ✓ | ✓ | ✓ | ✓ | The folding chair is a great concrete image. |
| T18 | ✓ | ✓ | ✓ | ✓ | ✓ | Rule of three that ends on the idiom "על הגדר". |
| T19 | ✓ | ✓ | ✓ | ✓ | ✓ | The magic-show frame turns into a refund. |
| T20 | ✓ | ✓ | ✓ | ✓ | ✓ | Now sourced (30.6 / 12.7.2024). The idiom twist works. |
| T21 | ✓ | ✗ | ✓ | ✓ | ✓ | **UX-06.** "גם זה קסם" explains the joke. |
| T22 | ✗ | ~ | ✓ | ✓ | ✓ | **UX-07.** "הם גדלים כל כך מהר" is an English calque. |
| T23 | ✓ | ✓ | ✓ | ✓ | ✓ | Now sourced (IDI). |
| T24 | ✓ | ✓ | ✓ | ✓ | ✓ | Title callback; the ICU plural is already in §A.1. |
| T25 | ✓ | ✓ | ✓ | ✓ | ✓ | **Top 5** (§4). |
| T26 | ✓ | ✓ | ✓ | ✓ | ✓ | The denial callback "איזו מזוודה?" is a good H-catch. |

### B. Story flashes

| ID | N | F | S | T | R | Note |
|---|---|---|---|---|---|---|
| B1 | ✓ | ✓ | ✓ | ✓ | ✓ | "61 מכובע ריק" passes the blackout lint now that "מנדטים" is gone. |
| B2 | ✓ | ✓ | ✓ | ✓ | ✓ | "61 ידיים" works twice: hands in the hat, and hands raised to vote. |
| B3 | ✓ | ✓ | ✓ | ✓ | ✓ | See T09 about repetition. |
| B4 | ✓ | ~ | ✓ | ✓ | ✓ | "החשד: על היועצים. הקוסם: לא חשוד." is a load-bearing legal line; it is judged on truth, and it passes. |
| B5 | ✓ | ✗ | ✓ | ✓ | ✓ | **UX-10.** Line 3 repeats S10's "40 מעלות" joke word for word in structure. |
| B6 | ✓ | ✓ | ✓ | ✓ | ✓ | "אין סוף. יש עוד סבב." |

### C. Sources (flavour / level-up)

| ID | N | F | S | T | R | Note |
|---|---|---|---|---|---|---|
| SRC1 משלם המסים | ✓/✓ | ✓/✓ | ✓ | ✓ | ✓ | "אותה אנחה, בסטריאו." is excellent. The sympathy is intact. |
| SRC2 ההייטקיסט, flavour | ✓ | ✓ | ✓ | ✓ | ~ | The Lisbon tab is gentle and sympathetic, so it passes. |
| SRC2 ההייטקיסט, level-up | ✓ | ✗ | ✓ | ✓ | ~ | **UX-08.** Flat. It also references the departure board, which is post-launch, so at launch the line points at nothing. |
| SRC3 המע״מ | ✓/✓ | ✓/✓ | ✓ | ✓ | ✓ | "בקופה חוגגים, בסופר שותקים." |
| SRC4 החבר הנדיב | ✓/✓ | ✓/✓ | ✓ | ✓ | ✓ | "כתב אישום בנפרד" matches Case 1000; "סתם, מחברות" is a perfect voice. |
| SRC5 הצוללת | ✓/✓ | ✓/✓ | ✓ | ✓ | ✓ | Warning letters, not an indictment. Correct. |
| SRC6 היועצים הקטאריים | ✓/✓ | ✓/✓ | ✓ | ✓ | ✓ | "החשודים: הם. אתה: לא." is legally exact *and* deadpan. |
| SRC7 מכונת הרעל | ✓/✓ | ✓/✓ | ✓ | ✓ | ✓ | "ישראלי_גאה_83921" |
| SRC8 פנקס הצ׳קים | ✓/✓ | ✓/✓ | ✓ | ✓ | ✓ | "מוושינגטון באהבה" is an established Hebrew title pattern, not a calque. |

### D. Spins

| ID | N | F | S | T | R | Note |
|---|---|---|---|---|---|---|
| S01 | ✓ | ✓ | ✓ | ✓ | ✓ | "הוחזר" literalises the refund on the upgrade itself. Sara is not named. |
| S02 | ✓ | ✓ | ✓ | ✓ | ✓ | "נמס תוך דקה" matches the 60 s buff. |
| S03 | ✓ | ✓ | ✓ | ✓ | ✓ | |
| S04 | ✓ | ✓ | ✓ | ✓ | ✓ | Exact quote plus "בתוקף עד שיהיה משהו". Protect. |
| S05 | ✓ | ✓ | ✓ | ✓ | ✓ | "מכשפות שנתפסו: 0." |
| S06 | ✓ | ✓ | ✓ | ✓ | ✓ | |
| S07 | ✓ | ~ | ✓ | ✓ | ✓ | It passes. Optional: his own word "אוטרקיה" would sharpen the callback. It stays economic, as it should. |
| S08 | ✓ | ✓ | ✓ | ✓ | ✓ | |
| S09 | ✓ | ~ | ✓ | ✓ | ✓ | Passes. Keep it a gift-only joke; nothing may ever reference what a pager recalls. |
| S10 | ✓ | ✓ | ✓ | ✓ | ✓ | Keep this one; B5 changes instead (UX-10). |
| S11 | ✓ | ✗ | ✓ | ✓ | ✓ | **UX-09.** Flat, informative. |
| S12 | ✓ | ✓ | ✓ | ✓ | ✓ | |
| S13 | ✓ | ✓ | ✓ | ✓ | ✓ | Framed as alleged, per Haaretz. |
| S14 | ✓ | ✓ | ✓ | ✓ | ✓ | |

### E. Coalition chat

| ID | N | F | S | T | R | Note |
|---|---|---|---|---|---|---|
| E-BenGvir demand | ✓ | ✗ | ✓ | ✓ | ✓ | **UX-11.** This is the **first chat message every player sees** (~0:45), and it has no joke. |
| E-BenGvir threat, return | ✓ | ✓ | ✓ | ✓ | ✓ | The forwarded-many-times structure *is* the joke. "לא בגלל הכסף. גם בגלל הכסף" |
| E-Smotrich (demand, threat, thanks) | ✓ | ✓ | ✓ | ✓ | ✓ | Two hats; the 17:15 finance-committee turn |
| E-Deri (demand, threat, status) | ✓ | ✓ | ✓ | ✓ | ✓ | The status line is **top 5**. |
| E-Goldknopf (all) | ✓ | ✓ | ✓ | ✓ | ✓ | "אז אני עוזב יותר" is a great reversal. The price tag is the joke, never the community. |
| E-Gafni (all) | ✓ | ✓ | ✓ | ✓ | ✓ | The threat is **top 5**. |
| E-Levin (all) | ✓ | ✓ | ✓ | ✓ | ✓ | "אני עותר לבג״ץ. ...רגע." |
| E-Regev (all) | ✓ | ✓ | ✓ | ✓ | ✓ | "אני מתפטרת. בטקס." Protect. |
| E-Gotliv demand, threat | ✓ | ✓ | ✓ | ✓ | ✓ | It mocks her public register, not her person. |
| E-Gotliv card | ✓ | n/a | ✓ | ✓ | ✓ | Reported speech plus `[נוסח לאימות]` plus `poll_like:true`: correct. |
| E-Amsalem demand, thanks | ✓ | ✓ | ✓ | ✓ | ✓ | The exclamation-mark system line is a lovely chrome joke. |
| E-Amsalem threat | ✗ | ✗ | ✓ | ✓ | ✓ | **UX-12.** "בקול שלי" is a calque of "in my own voice", with no nameable mechanism. |
| E-Karhi demand | ✓ | ✓ | ✓ | ✓ | ✗ (RTL) | **UX-13.** The כאן→שם pun is **top 5**, but ➡️ points backwards in RTL. |
| E-Karhi threat, thanks, review | ✓ | ✓ | ✓ | ✓ | ✓ | |
| E-Golan (label, demand, threat, thanks) | ✓ | ✓ | ✓ | ✓ | ✓ | The label says "חשד · המלצת המשטרה". Correct. |
| E-Distel (all) | ✓ | ✓ | ✓ | ✓ | ✓ | "אני לוקחת את שלי והולכת" is an idiom twist. I will add the `chat.sys.muted` template (§6). |
| E-Almog system line | ✓ | ✓ | ✓ | ✓ | ✓ | |
| E-Almog poach ticker | ✓ | ✗ | ✓ | ✓ | ✓ | **UX-15.** "אלמוג כהן צורף. מקום 8 בפריימריז." is informative only. |
| E-Illouz ticker | ✓ | ~ | ✓ | ✗ | ✓ | **UX-14.** The `[נוסח לאימות]` line is shown as "Name: quote", which is direct-speech form. |
| E-defector system line | ✓ | ✓ | ✓ | ✓ | ✓ | "כיוון: ליברמן" |
| E-Transfer event | ✓ | ✓ | ✓ | ✓ | ✓ | "הווליום נשאר." The 90/60/30 countdown in bubbles is funny and correct. |
| E-Brawl, Amsalem bubble | ✓ | ✓ | ✓ | ✗ | ✓ | **UX-16.** A `[נוסח לאימות]` quote is rendered as direct speech in a bubble, against deck §0's own rule. |
| E-Brawl, rest | ✓ | ✓ | ✓ | ✓ | ✓ | "גם לא אימוג׳י!!", and "המסדרון" with its climbing counter |

### F. Opposition cards

| ID | N | F | S | T | R | Note |
|---|---|---|---|---|---|---|
| F-Lapid | ✓ | ✓ | ✓ | ✓ | ✓ | "השאלה: ממשיכה." |
| F-Bennett | ✓ | ✓ | ✓ | ✓ | ✓ | |
| F-Eisenkot | ✗ | ✗ | ✓ | ✓ | ✓ | **UX-17.** "שומו שמיים" is an archaic register nobody would use here, and the line explains its own mechanic. |
| F-Gantz | ✓ | ✓ | ✓ | ✓ | ✓ | "מאז 2020." |
| F-Liberman | ✓ | ✓ | ✓ | ✓ | ✓ | |
| F-Golan | ~ | ✗ | ✓ | ✓ | ✓ | **UX-18.** "השלט חסך" is unclear, and "השלט" collides with S08, Karhi's "השלט". |
| F-Abbas | ✓ | ✓ | ✗ | ✓ | ✓ | **UX-19.** About 110 characters against a 60 limit. |
| F-Nameless | ✓ | ✓ | ✗ | ✓ | ✓ | **UX-20.** About 75 characters. |
| F-Roulette | ✓ | ✗ | ✓ | ✗ | ✓ | **UX-01.** 3.25% is OK; the second sentence is not. |

### G. The Suitcase

| ID | N | F | S | T | R | Note |
|---|---|---|---|---|---|---|
| G-cash | ✓ | ✓ | ✓ | ✓ | ✓ | "לא נמסרה תגובה" |
| G-laundry | ✓ | ✓ | ✓ | ✓ | ✓ | |
| G-aide | ✓ | ✓ | ✓ | ✓ | ✓ | "בשום אופן לא אצלך." Over-denial as the punch, and legally exact. |
| G-miss, Dubi miss | ✓ | ✓ | ✓ | ✓ | ✓ | I accept the period over my semicolon (the designer's S8). |
| G-aide drop | ✓ | ✓ | ✓ | ✓ | ✓ | "החשד אופס" (reset / oops) is a great homograph. |
| G-Dubi "מי? מי?" | ✓ | ✓ | ✓ | ✓ | ✓ | |

### H. Court day

| ID | N | F | S | T | R | Note |
|---|---|---|---|---|---|---|
| H-court ticker | ✓ | ✓ | ✓ | ✓ | ✓ | Now "יום משפט", consistent with the chrome. |
| H-excuse 1-6 | ✓ | ✓ | ✓ at 1-5; 6 is a long card body, which is OK | ✓ | ✓ | **Top 5.** The guardrail is honoured. |
| H-stamps 1-8 | ✓ | ✓ | ✓ | ✓ | ✓ | Stamp 7 (the real plea-deal push) as the one true stamp among absurd ones is a smart punch. |

### I. The rest

| ID | N | F | S | T | R | Note |
|---|---|---|---|---|---|---|
| I-return tickers (summary, Bibi-sitter) | ✓ | ✓ | ✓ | ✓ | ✓ | "לא היה כלום. כי אין כלום." |
| I-mood.10, mood.20 | ✓ | ✓ | ✓ | ✓ | ✓ | Adopted into my table (§6). |
| I-calendar: blackout ticker | ✓ | ✓ | ✓ | ✓ | ✓ | "אפילו לא סקר על סקרים." `poll_like:false` is correct: it has no numbers. |
| I-calendar: negotiation opener | ✓ | ✓ | ✓ | ✓ | ✓ | "משך משוער: כן." Protect. |
| I-word salad | ✓ | ✓ | ✓ | ✓ | ✓ | |
| I-Dubi squawks | ✓ | ✓ | ✓ | ✓ | ✓ | Doubling rule applied, including to dubi.firsttap. |
| I-trophies | ✓ | ✓ | ✓ | ✓ | ✓ | "תיק 1000" is a clean pun. |

---

## 3. Balance: coalition vs opposition

Counting every line in A-I that roasts a named side, excluding neutral lines (calendar, public mood, word salad, the payer-sympathy halves):

| Section | Coalition (the Magician + partners) | Opposition |
|---|---|---|
| A. Ticker | 17 (T01-T14, T22, T25, T26) | 7 (T15-T21) |
| B. Flashes | 5 | 0 |
| C. Sources | 16 | 0 |
| D. Spins | 14 | 0 |
| E. Chat | ~56 | 0 |
| F. Cards | 1 (Abbas targets the Magician's flip-flop) | 7 |
| G, H, I | ~30 | 1 (the Gantz trophy) |
| **Total** | **~139** | **~15** |

The raw ratio is **1:9**, far past the rubric's 1:2 flag.

Much of that is structural: the protagonist's own systems (C, D, G, H) and the coalition-only group chat have no opposition twin. Two fairer cuts:

| Cut | Coalition | Opposition | Ratio |
|---|---|---|---|
| Third-party politicians only (partners vs opposition) | ~59 | ~15 | **1:4** |
| The ticker, the surface seen every 8-12 s | 17 | 7 | **1:2.4** |

Both still fail. The "It roasts *everyone*" test is lost in the chat, where half the laughs live. See **UX-21** for the fix: 8 opposition ticker lines and one leaked opposition-chat event, all written. The fix brings the ticker to about 15:17 and partners-vs-opposition to about 1:1.6.

---

## 4. Protect these (the five strongest)

1. **T25 "על פי פרסומים זרים, יש כובע."** Israel's nuclear-ambiguity formula applied to a hat. Native-only, instant, and the perfect first line.
2. **Karhi "…עוברים מ״כאן״ ל״שם״"** The broadcaster's name, Kan, is "here", so money moves from here to there. A pun that exists only in Hebrew, and it's sourced.
3. **Gafni "אם לא סגרנו, אני דווקא נשאר באולם."** A threat to *stay*. A perfect reversal carried by the one word "דווקא".
4. **The excuse ladder "…אחד מהם הביא בורקס. הבורקס סווג."** Escalation that ends on classified pastry, and the guardrail is built into the joke.
5. **Deri "יצאנו מהממשלה, לא מהקבוצה. פה נוח."** True to the record, and the group-chat mechanic *is* the punchline.

Also keep untouched: T05, T12, T18, S04, Regev's "בטקס", Goldknopf's "עוזב יותר", "המסדרון", "משך משוער: כן."

---

## 5. Global notes (mechanical; not objections)

- **Typography.**
  - The deck uses ASCII `'` and `"` inside Hebrew words: קוטג', סמוטריץ', מס', המע"מ, ש"ס, בג"ץ, יו"ר. The build replaces them with geresh ׳ (U+05F3) and gershayim ״ (U+05F4).
  - A hyphen after a prefix letter before digits ("ב-17:15", "מ-2020", "ל-18%") becomes a maqaf (U+05BE).
  - Both are safe find-and-replace passes, except inside real quotes.
- **Button name.** Deck §E line "Demand: has a 'שלם' button" should read "the pay pill (`chat.pay`, 'סגרנו · {price} ₪')". The pitch already uses the pill.
- **Karhi's bubble amount.** The bubble carries a sourced figure, "25 מיליון בשנה", while §E says bubble amounts equal `{price}`. Either say the pill for Karhi's line is the in-game price and the bubble quotes the real transfer, or mark this bubble as the one sourced exception.
- **Emoji in partner bubbles** (🔥🙏💸) may render as system emoji. They read as chat, so this is accepted. Chrome icons (lock, pin, mute, clock) stay pixel icons, per first-minute §3.5.

---

## 6. My own requests: still open

Pitch §11 answers **every** request from first-minute §2.4 and §9:

| Request | Answered where |
|---|---|
| First purchase in 12-16 taps | Q1: 15 ₪ on tap 12 |
| First demand at ~45 s | Q2: 60 ₪ |
| No ultimatum before 3:00, and ≥ 90 s timers | Q3 |
| Every timer loss recoverable | Q4: "להחזיר לקבוצה" at 1.5× |
| First rabbit on tap 7 | Q5 |
| Headline slots | Q6, and deck §A.1 |
| `poll_like` and `real_quote` tags | Q7, and deck §0 |
| Suspicion carry-over | Q8: yes, as a floor of min(5%·n, 40%); "וגם התיקים." stays |
| Fuel source | references #50, via the designer's O8 |

**Still open, and only this: none against the designer.**

On my side, I accept the designer's objections **O1-O9** and counter-objection **C1** in `voice/review-designer.md` in full. I have applied them to `ux/first-minute.md`, together with these related edits:
- the `chat.sys.muted` template;
- mood.10 and mood.20;
- the thermometer's hatched suspicion-floor segment;
- keeping "וגם התיקים.";
- chat at ~0:45;
- the "סבב בחירות" in-full rule on my own strings.

---

## 7. Objections

```yaml
objection:
  skill_or_agent: ux-designer (copy cross-review)
  against_artifact: voice/copy-deck.md §F F-Roulette caption
  reason: |
    Decision on the live question: "3.25%" is the statutory threshold, not a poll figure; it
    stays. The second sentence "מי שטובע, לוקח איתו מנדטים." fails gate 4 (a list under the
    threshold doesn't take seats anywhere; its votes are burned) and gate 2 (explanatory, no turn).
  proposed_alternative: |
    "3.25%: הקו שבין מפלגה לקבוצת חברים. מתחתיו: רק קבוצת חברים."  (59 chars; the reversal
    repeats the setup's own last words. Keep poll_like:true on the card.)
```
*(UX-01)*

```yaml
objection:
  skill_or_agent: ux-designer (copy cross-review)
  against_artifact: voice/copy-deck.md §A T11
  reason: |
    Gate 4. "בקשת החנינה חזרה עם חותמת: "נדרשים מסמכים נוספים."" presents an invented stamp in
    quote marks as a real outcome of a real pardon request. Herzog actually shelved it and pushed
    for a plea deal (refs #12). That is plausible-false, not plainly absurd.
  proposed_alternative: |
    "החנינה: נדרשים מסמכים נוספים. המסמכים: נדרשת חנינה."  (51 chars; the loop makes it
    visibly absurd, and it sets up the pardon-desk stamps.)
```
*(UX-02)*

```yaml
objection:
  skill_or_agent: ux-designer (copy cross-review)
  against_artifact: voice/copy-deck.md §A T13
  reason: |
    Gate 2: a plain report with no turn. Gate 4: "announced there's no money and immediately
    asked for a raise" reads as a factual claim about a real minister. It also duplicates the
    Smotrich chat demand's two-hats joke.
  proposed_alternative: |
    "סמוטריץ׳ מבקש להבהיר: אין כסף. יש העברות."  (41 chars; the ministerial-clarification
    register, turning on the budget-transfer term "העברות" in the last word.)
```
*(UX-03)*

```yaml
objection:
  skill_or_agent: ux-designer (copy cross-review)
  against_artifact: voice/copy-deck.md §A T14
  reason: |
    Gate 4. As free-standing news, "Gafni went to the bathroom; the vote tied" is exactly the
    kind of thing that could be true of a real MK. Plausible-false.
  proposed_alternative: |
    "שילמת לגפני. הוא יצא לשירותים. ההצבעה: תיקו."  (44 chars; fire it only after the player
    pays Gafni, so it reads as a game event, not a news report.)
```
*(UX-04)*

```yaml
objection:
  skill_or_agent: ux-designer (copy cross-review)
  against_artifact: voice/copy-deck.md §A T16
  reason: |
    Gate 4. The 2021 pledge (refs #30) was not to let Lapid become prime minister, not "not to
    recommend him".
  proposed_alternative: |
    "בנט חתם שלפיד לא יהיה רה״מ. היום הם רשימה אחת. העט בהלם."  (about 55 chars)
```
*(UX-05)*

```yaml
objection:
  skill_or_agent: ux-designer (copy cross-review)
  against_artifact: voice/copy-deck.md §A T21
  reason: |
    Gate 2. "גם זה קסם" explains the joke instead of landing it. The fact is funny; the tag
    deflates it.
  proposed_alternative: |
    "האופוזיציה העבירה 800 מיליון ₪ בטעות. הקוסם אפילו לא נגע בכובע."  (about 60 chars. The
    Magician's best trick is one he didn't perform. If it's over the cap in the pixel font, cut
    "אפילו".)
```
*(UX-06)*

```yaml
objection:
  skill_or_agent: ux-designer (copy cross-review)
  against_artifact: voice/copy-deck.md §A T22
  reason: |
    Gate 1. "הם גדלים כל כך מהר" is the English "they grow up so fast". An Israeli parent says
    something else.
  proposed_alternative: |
    "המע״מ עלה ל־18%. איך שהם גדלים, בלי עין הרע."  (44 chars; the native proud-parent idiom,
    ending on "בלי עין הרע".)
```
*(UX-07)*

```yaml
objection:
  skill_or_agent: ux-designer (copy cross-review)
  against_artifact: voice/copy-deck.md §C source 2 level-up "עוד שורה בלוח ההמראות."
  reason: |
    Gate 2: flat. It also references the departure board, which is post-launch (pitch §2 table),
    so at launch the line points at nothing on screen.
  proposed_alternative: |
    "עוד הייטקיסט. הקופה מחייכת, נתב״ג מתכונן."  (41 chars; a juxtaposition with the turn last.
    The joke stays on the policy's effect, not on the person. When the board ships, the old line
    can come back as its flavour text.)
```
*(UX-08)*

```yaml
objection:
  skill_or_agent: ux-designer (copy cross-review)
  against_artifact: voice/copy-deck.md §D S11
  reason: |
    Gate 2. "הארנב קופץ יותר. המשפט עדיין לא נגמר." is two facts with no turn.
  proposed_alternative: |
    "הארנב קופץ יותר. המשפט זוחל כרגיל."  (34 chars; a hop/crawl contrast, with "כרגיל" as the
    deadpan closer.)
```
*(UX-09)*

```yaml
objection:
  skill_or_agent: ux-designer (copy cross-review)
  against_artifact: voice/copy-deck.md §B B5 line 3
  reason: |
    Gate 2 (repetition). "בלשכה: הכחשה. במכבסה: 40 מעלות." is the same joke as S10
    ("…ישראל: הכחשה. המכונה: 40 מעלות."). A player who owns S10 sees the punchline twice.
  proposed_alternative: |
    B5 line 3: "בלשכה: הכחשה. הכביסה: יצאה נקייה."  (33 chars; "יצאה נקייה" means both
    "came out clean" and "was cleared". S10 keeps "40 מעלות".)
```
*(UX-10)*

```yaml
objection:
  skill_or_agent: ux-designer (copy cross-review; FTUE)
  against_artifact: voice/copy-deck.md §E Ben Gvir demand "צריך תקציב לביטחון לאומי. היום, לא מחר 🔥"
  reason: |
    Gate 2. This is the first chat bubble every player reads (FTUE C1, ~0:45), the moment the
    game's biggest system is introduced, and it is a plain demand with no turn.
  proposed_alternative: |
    "צריך תקציב לביטחון לאומי. היום. אתמול אם אפשר 🔥"  (47 chars; the native urgency idiom
    escalates past "today", and the reversal lands on "אתמול".)
```
*(UX-11)*

```yaml
objection:
  skill_or_agent: ux-designer (copy cross-review)
  against_artifact: voice/copy-deck.md §E Amsalem threat "עוד יום בלי תקציב ואני מתראיין. בקול שלי."
  reason: |
    Gates 1 and 2. "בקול שלי" is a calque of "in my own voice" and carries no nameable mechanism.
    The reader can't tell whether it means loud, unscripted, or something else.
  proposed_alternative: |
    "עוד יום בלי תקציב ואני עולה לאולפן. בלי מיקרופון."  (49 chars; the hyperbole-by-understatement
    is that he doesn't need a mic. It fits his established volume joke and the "no exclamation
    mark" system line.)
```
*(UX-12)*

```yaml
objection:
  skill_or_agent: ux-designer (localization-aware-layout, RTL)
  against_artifact: voice/copy-deck.md §E Karhi demand "…מ"כאן" ל"שם" 📺➡️📺"
  reason: |
    RTL rule `mirror-with-glyph-swap` (first-minute §3.5). In an RTL line, "from כאן to שם" reads
    right to left, so ➡️ points *back* toward Kan and visually contradicts the transfer.
  proposed_alternative: |
    "25 מיליון בשנה עוברים מ״כאן״ ל״שם״ 📺⬅️📺"  (swap to ⬅️, with gershayim quotes. The pun
    itself is top-5; don't touch the words.)
```
*(UX-13)*

```yaml
objection:
  skill_or_agent: ux-designer (copy cross-review)
  against_artifact: voice/copy-deck.md §E Illouz ticker "דן אילוז: הליכוד הפך לקבלן משנה של דרעי וגולדקנופף."
  reason: |
    Gate 4 and deck §0: a [נוסח לאימות] line must render as reported speech until the Hebrew is
    verified. The "Name: text" ticker form reads as a direct quote.
  proposed_alternative: |
    "לפי דן אילוז, הליכוד הפך לקבלן משנה של דרעי וגולדקנופף."  (55 chars. Once the Hebrew is
    verified, it may return to "Name: "quote"" with the ציטוט tag.)
```
*(UX-14)*

```yaml
objection:
  skill_or_agent: ux-designer (copy cross-review)
  against_artifact: voice/copy-deck.md §E Almog Cohen poach ticker "אלמוג כהן צורף. מקום 8 בפריימריז."
  reason: |
    Gate 2. Pure information, no mechanism.
  proposed_alternative: |
    "אלמוג כהן הוסר מקבוצה אחת וצורף לאחרת. ניידות חברתית."  (53 chars. True to the record:
    removed from Otzma's groups, later in the Likud primary. The idiom twist lands last.)
```
*(UX-15)*

```yaml
objection:
  skill_or_agent: ux-designer (copy cross-review)
  against_artifact: voice/copy-deck.md §E brawl event, Amsalem bubble "אל תקרא לי חוצפן." [src] [נוסח לאימות]
  reason: |
    Gate 4 and deck §0: an unverified rendering is shown as direct speech in a bubble while
    tagged as a real quote. It is the same rule T07 and Illouz follow.
  proposed_alternative: |
    Until the Hebrew is verified: an untagged invented bubble "אל תקרא לי ככה." (in voice, not
    presented as a quote), and a system pill above the brawl carrying the sourced fact:
    "לפי הדיווחים: ״אל תקרא לי חוצפן״ · מקור". After verification, restore the original bubble.
```
*(UX-16)*

```yaml
objection:
  skill_or_agent: ux-designer (copy cross-review)
  against_artifact: voice/copy-deck.md §F Eisenkot card "הקים את "ישר". כל עוד הוא בפריים, אין ארנבים. שומו שמיים."
  reason: |
    Gate 1: "שומו שמיים" is archaic and liturgical, a register mismatch nobody would use about a
    campaign. Gate 2: the body only restates the mechanic, and the closer isn't a turn.
  proposed_alternative: |
    "הקים את ״ישר״: פוליטיקה בלי קסמים. הארנבים יצאו לחל״ת."  (54 chars. "חל״ת" is the native
    furlough word: his no-magic rule puts the rabbits out of work, which is the mechanic told as
    a punchline.)
```
*(UX-17)*

```yaml
objection:
  skill_or_agent: ux-designer (copy cross-review)
  against_artifact: voice/copy-deck.md §F Golan card "מאחד שני קלפים לאחד. השלט חסך, הוויכוחים הוכפלו."
  reason: |
    Gate 2 (clarity). "השלט חסך" is ambiguous (a sign? a campaign billboard?), and "השלט" is
    already Karhi's item name (S08). A reader in the Knesset era will read it as Karhi's remote.
  proposed_alternative: |
    "מאחד שני קלפים לאחד. חוסך מקום, מכפיל ויכוחים."  (46 chars)
```
*(UX-18)*

```yaml
objection:
  skill_or_agent: ux-designer (copy cross-review; card layout)
  against_artifact: voice/copy-deck.md §F Mansour Abbas card copy
  reason: |
    Gate 3. About 110 chars against the 60 flavour cap. On a 390-wide card it wraps to 4 lines and
    buries the punch.
  proposed_alternative: |
    Flavour (53 chars): "2019: ״ביבי או טיבי״. 2021, לפי עבאס: נאום על שותפות."
    The mechanic clause moves to the card's rule line (UX chrome, small caps): "מופיע רק כשבן
    גביר לא מחובר". It stays the visual punch because it sits directly under the flavour.
```
*(UX-19)*

```yaml
objection:
  skill_or_agent: ux-designer (copy cross-review; card layout)
  against_artifact: voice/copy-deck.md §F Nameless Party card copy (post-launch)
  reason: |
    Gate 3. About 75 chars against the 60 cap.
  proposed_alternative: |
    "מפלגה בלי שם. אחרי חודש ארדן עזב. מצע: יש. שם: בהמשך."  (53 chars; the founders' names move
    to the card title line.)
```
*(UX-20)*

```yaml
objection:
  skill_or_agent: ux-designer (copy cross-review; balance)
  against_artifact: voice/copy-deck.md (whole deck) balance
  reason: |
    Rubric balance check. There are about 139 coalition-roasting lines to about 15 for the opposition
    (1:9). Excluding the protagonist's own systems it is 1:4 (partners vs opposition), and 1:2.4 on
    the ticker, the most-seen surface. All three cuts miss the rubric's 1:2 floor. The brief's
    headline test, "It roasts *everyone*", is lost in the group chat, where the densest laughs
    live and the opposition has no presence.
  proposed_alternative: |
    Add opposition content in the two surfaces with the highest exposure. Every line is invented and
    plainly absurd unless tagged, and none contains digits near "מנדט/סקר/מוביל".
    (a) Eight ticker lines, all poll_like:false:
      • "בנט חתם על התחייבות חדשה. הפעם בעיפרון."
      • "גנץ שלח תזכורת על הרוטציה. התקבל: נקרא."
      • "לפיד הציג תוכנית כלכלית: 40 שקפים. שקף 41: ״איפה הכסף?״"  [src: the Lapid quote]
      • "ליברמן פרסם את הקווים האדומים שלו. כרגע: כל הקווים."
      • "אייזנקוט הבטיח: בלי טריקים. היועצים שלו מתחננים לטריק אחד."
      • "האופוזיציה פתחה קבוצה משותפת. תוך שעה: שלוש קבוצות."
      • "אייזנקוט, לפיד ובנט נפגשו לתיאום. תיאמו מועד לפגישת תיאום."
      • promote from the bench: "בנט ולפיד רשימה אחת. מי בראש? יוכרע בהטלת חתימה."
    (b) One event, "צילום מסך דלף". It is read-only, rendered in the same chat bubbles on a torn
        "screenshot" frame, and fires with an opposition card, about once per round. Group title:
        ״האופוזיציה (רשמי) (סופי) 2״
        לפיד: איפה הכסף?
        בנט: אני מתחייב בשידור חי לא לענות על זה.
        גנץ: אני פה מ־2020. מתי מתחלפים?
        אייזנקוט: אפשר לדבר ישר?
        ליברמן: לא יושב בקבוצה הזאת.
        [ליברמן עזב את הקבוצה]
        גולן: איחדתי את הקבוצה הזאת עם עוד אחת. עכשיו יש שלוש.
    Result: the ticker goes to about 15 opposition vs 17 coalition, and partners-vs-opposition to
    about 1:1.6. The build cost is one read-only chat frame (the existing bubble component) and
    string rows. The game designer owns the final words; these are drafts that clear all five gates.
```
*(UX-21)*

**Total: 21 objections.**

| Gate failed | Objections |
|---|---|
| Truth | 7 (UX-01, 02, 04, 05, 14, 16, and the truth half of 03) |
| Funny | 9 |
| Native | 3 |
| Short | 2 |
| RTL | 1 |
| Balance | 1 |

Some objections fail more than one gate. None is a red-line violation: the deck is clean on every red line.

---

## Resolution (Game Designer)

Every change is applied in `voice/copy-deck.md`.

**Totals: 15 accepted · 6 revised · 0 counter-objections.**

No rewrite needed a counter-objection. Where I diverge (UX-01, 07, 11, 16, 21), I'm improving on
the proposal inside the same fix, not rejecting it.

| # | Target | Resolution | Line as shipped |
|---|---|---|---|
| UX-01 | F: roulette caption | **Revised.** I accept the truth point ("takes seats with it" is wrong). But "מתחתיו: רק קבוצת חברים" only repeats the setup. My version adds a turn on the last word. | 3.25%. מעליו: מפלגה. מתחתיו: קבוצת חברים עם מצע. (`poll_like:true` stays) |
| UX-02 | T11 | **Accepted** | החנינה: נדרשים מסמכים נוספים. המסמכים: נדרשת חנינה. |
| UX-03 | T13 | **Accepted** | סמוטריץ' מבקש להבהיר: אין כסף. יש העברות. |
| UX-04 | T14 | **Accepted.** It fires only after the player pays Gafni. | שילמת לגפני. הוא יצא לשירותים. ההצבעה: תיקו. |
| UX-05 | T16 | **Accepted** | בנט חתם שלפיד לא יהיה רה"מ. היום הם רשימה אחת. העט בהלם. |
| UX-06 | T21 | **Accepted,** with your optional trim of "אפילו" (57 chars) | האופוזיציה העבירה 800 מיליון ₪ בטעות. הקוסם לא נגע בכובע. |
| UX-07 | T22 | **Revised.** Your idiom is right, but VAT is singular, so "איך שהם גדלים" breaks agreement. | המע"מ עלה ל-18%. איך שהוא גדל, בלי עין הרע. |
| UX-08 | Source 2 level-up | **Accepted.** The old line becomes the departure board's flavour text when it ships. | עוד הייטקיסט. הקופה מחייכת, נתב"ג מתכונן. |
| UX-09 | S11 | **Accepted** | הארנב קופץ יותר. המשפט זוחל כרגיל. |
| UX-10 | B5 line 3 | **Accepted.** S10 keeps "40 מעלות". | בלשכה: הכחשה. הכביסה: יצאה נקייה. |
| UX-11 | Ben Gvir's first demand | **Revised.** "אתמול אם אפשר" is good, but this bubble arrives at 0:45 and the ultimatum system unlocks at 3:00. My turn *foreshadows* it: the game's first chat joke also teaches the next mechanic. | צריך תקציב לביטחון לאומי. היום. זה לא איום. עדיין 🔥 |
| UX-12 | Amsalem's threat | **Accepted** | עוד יום בלי תקציב ואני עולה לאולפן. בלי מיקרופון. |
| UX-13 | Karhi's arrow | **Accepted.** I also took your global note: Karhi's bubble is the one documented sourced exception to the `{price}` rule. | 25 מיליון בשנה עוברים מ"כאן" ל"שם" 📺⬅️📺 |
| UX-14 | Illouz ticker | **Accepted** | לפי דן אילוז, הליכוד הפך לקבלן משנה של דרעי וגולדקנופף. |
| UX-15 | Almog poach ticker | **Accepted** | אלמוג כהן הוסר מקבוצה אחת וצורף לאחרת. ניידות חברתית. |
| UX-16 | Brawl: Amsalem's bubble | **Revised.** I accept the invented bubble. But your pill "לפי הדיווחים: ״אל תקרא לי חוצפן״" still puts unverified Hebrew in quote marks, so the pill is now fully reported speech. | Pill: לפי הדיווחים, אמסלם ביקש מסמוטריץ' שלא יקרא לו חוצפן · מקור. Bubble: אל תקרא לי ככה. |
| UX-17 | Eisenkot card | **Accepted.** "חל"ת" is better than anything I had. | הקים את "ישר": פוליטיקה בלי קסמים. הארנבים יצאו לחל"ת. |
| UX-18 | Golan card | **Accepted** | מאחד שני קלפים לאחד. חוסך מקום, מכפיל ויכוחים. |
| UX-19 | Abbas card | **Accepted.** The mechanic clause moves to the rule line. | 2019: "ביבי או טיבי". 2021, לפי עבאס: נאום על שותפות. Rule line: מופיע רק כשבן גביר לא מחובר |
| UX-20 | Nameless card | **Accepted.** The founders move to the title line. | מפלגה בלי שם. אחרי חודש ארדן עזב. מצע: יש. שם: בהמשך. |
| UX-21 | Balance | **Revised,** and built out. See the details below. | T27-T34, plus the leaked opposition chat §E.2 |

### UX-21 in detail

**(a) Eight opposition ticker lines, deck §A.2.** Kept from your drafts:
- T27, Bennett's pencil;
- T33, the coordination meeting;
- T34, three groups.

Rewritten, with the reason for each:

| Line | Rewrite | Why |
|---|---|---|
| T28, Gantz | "סטטוס: נקרא" | It's tighter. |
| T29, Lapid | "…שידור חוזר." | The former anchor's question becomes a rerun. It replaces "40 slides", which was a plausible-false specific. |
| T30, Liberman | "זה פשוט דף אדום." | His red lines, literalised. |
| T31, Eisenkot | "\"ישר\" מתנהלת ישר. בפוליטיקה זה נחשב קסם." | It calls back to the magic frame. It replaces "his advisers beg for a trick", which invented behaviour for real staff. |
| T32, Golan | "הדמוקרטים עוד מתאחדים מהקודם." | It rests on the sourced 2024 merger. |

The ticker is now 15 opposition lines to 17 coalition lines.

**(b) The leaked opposition chat, "צילום מסך דלף", deck §E.2:**
- The group is "האופוזיציה (רשמי) (סופי) 2": Lapid, Bennett, Eisenkot, Golan, Liberman.
- Gantz is permanently "מקליד…" and never posts.
- There are three leaks, one per round, looping: "the question", "one simple message", "rotation".
- Every bubble is invented voice only, `poll_like:false`, with no seats and nothing military.
- The only sourced line is Lapid's "איפה הכסף?".

### UX's global notes: all accepted
- **Typography pass.** ASCII `' "` inside Hebrew words become ׳ ״, and the hyphen after a prefix
  letter before digits becomes a maqaf. This is a build find-and-replace pass that skips real
  quotes.
- **§E wording.** The demand line now names the `chat.pay` pill instead of a "שלם" button.
- **Karhi.** His bubble is the documented `{price}` exception (see UX-13).
- **T09 and B3.** Never both in the same round. B3 fires only at the round-3 flash, and T09 is
  suppressed during that round.
