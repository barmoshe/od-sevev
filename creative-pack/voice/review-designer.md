# Game Designer review of the UX microcopy (`ux/first-minute.md`)

**Reviewer:** Game Designer · **Against:** `voice/review-rubric.md` (native · funny · short · true ·
red lines) · **Scope:** every Hebrew string in `ux/first-minute.md`: §2 FTUE, §4 chat, §5 share
kit, §6 disclaimer, About and blackout, §7 return and settings, §8 microcopy table.
`ux/first-minute.md` was not edited.

**How the "funny" gate is applied:**
- It applies to strings marked ★ in UX's legend, and to body copy meant to entertain.
- Pure chrome labels ("הגדרות", "סגור", "פועל") are judged only on native, short and true.
- ⚖ legal lines are judged on native, true and red lines, never "made funnier".

**Verdict:**
- **Every Hebrew string reviewed:** the whole §8 table and the body strings in §2 and §4-§7.
- **9 objections** (O1-O9, below). One is a red line (O1).
- **All other strings pass.**
- **1 counter-objection** (C1) answers UX's pre-registered §9 objection.
- **12 seam items** are resolved with one owner per string (§3).

---

## 1. Strings that pass (highlights)

The UX chrome is strong. These carry real jokes and stay:
- "אני בישיבה"
- "נפתח לך תיק."
- "מקור עלום"
- "להפיץ · {price} ₪"
- "שחוק" / "כבר שמעו את זה"
- "נעוץ: ההסכם הקואליציוני · טיוטה {n}"
- "פה מדברים רק בשקלים"
- "שקט בקבוצה. זה לא יחזיק."
- "כולל דמי אחזקה"
- "זה כמו פיזור הכנסת, רק בלי בחירות חוזרות."
- "נמחק. אין כלום."
- "אנחנו לא סקר, ולא מחפשים עוד תיק."
- "הבחירות נגמרו. הקואליציה? עוד לא."
- "תודה שבחרתם. שוב."
- "(במשחק. בינתיים.)"
- "ואפס ימי משפט. בינתיים."
- "מדד הקוטג׳: הקופה שלך גדלה. הקוטג׳ קטן."
- "…או מזוודה"

The disclaimer (disc.l1-l4) is native, complete *before* its joke, and inside every red line.

---

## 2. Objections (9), plus one counter-objection

### O1. A red line: the 8-48 h return card
```yaml
objection:
  skill_or_agent: game-designer (copy voice / red lines)
  against_artifact: ux/first-minute.md §7.1 + §8 ret.* (8-48 h tier) "ישנת טוב?" / "משלמי המסים לא."
  reason: |
    Rubric gate 5. The card asks the player (who *is* the Netanyahu caricature) whether he slept
    well. The dominant sleep joke about Netanyahu in Sept 2026 is Yashar's "Sleepy Bibi" game,
    whose premise is sleeping through the October 7 warnings (fact sheet, Haaretz 28.9.2026).
    The orchestrator already accepted cutting every "Sleepy Bibi" reference (pitch §2.5). A sleep
    gag aimed at this character lands on that reading whether or not we mean it.
  proposed_alternative: |
    Title: "איפה היית?"   Body: "בלשכה מסרו: התייעצות ביטחונית."
    (A callback to the court excuse. Title 10 chars, body 30, both inside the ret.* budgets 20/40.)
```

### O2. The >48 h return card body
```yaml
objection:
  skill_or_agent: game-designer (copy voice)
  against_artifact: ux/first-minute.md §7.1 ret.* (>48 h) body "הכובע המשיך לעבוד. הוא לא יודע לנוח."
  reason: |
    Rubric gate 2. No nameable mechanism: it's a plain statement, and "לנוח" also drifts toward
    the sleep reading in O1.
  proposed_alternative: |
    Keep the title "נעלמת ל־{n} ימים."   Body: "תרגיל ההעלמה הכי טוב שלך עד היום."
    Mechanism: the idiom twist. The Magician's absence *is* his best trick. (32 chars, inside 40.)
```

### O3. The round-5 mood: plural address
```yaml
objection:
  skill_or_agent: game-designer (copy voice)
  against_artifact: ux/first-minute.md §8 mood.5 "הציבור נרגש. תבדקו אותו."
  reason: |
    Rubric gate 1. "תבדקו" is plural and breaks the deck-wide second-person-singular-masculine
    address (player = the Magician). The only plural surfaces are the share texts, which is
    correct there.
  proposed_alternative: |
    "הציבור נרגש. שמישהו יבדוק אותו."  (31 chars. Impersonal, keeps the joke, no address clash.)
```

### O4. The round card doesn't fit its own budget
```yaml
objection:
  skill_or_agent: game-designer (content length)
  against_artifact: ux/first-minute.md §8 title.round "סבב בחירות מס׳ {n} · {publicMood}" (max 34)
  reason: |
    Rubric gate 3. The prefix "סבב בחירות מס׳ 12 · " is about 19 chars, so publicMood gets about 15.
    UX's own mood.6 ("הציבור נרגש. הוא אמר שהוא בסדר.") is 32, and my proposed round-10 and
    round-20 overrides are 20-32. They cannot fit a one-line 34 budget. They would auto-shrink to
    85% and then ellipsis, and the ellipsis eats the punchline, which always sits last.
  proposed_alternative: |
    Two lines: line 1 "סבב בחירות מס׳ {n}" (≤ 20), line 2 {publicMood} (≤ 34, wrap-2-line).
    On the title state, line 2 may render smaller. The punchline is never truncated.
```

### O5. Dubi's first squawk
```yaml
objection:
  skill_or_agent: game-designer (character voice)
  against_artifact: ux/first-minute.md §2.2 / §8 dubi.firsttap "אין כלום!" (max 10)
  reason: |
    Dubi's single rule (copy deck header, accepted in pitch §2.12) is that he only repeats,
    doubled. UX's own dubi.buy ("לקנות! לקנות!") and dubi.elect ("בחירות! בחירות!") follow it.
    The most-seen Dubi line in the game, at tap 1, is the one that breaks it. A single "אין כלום!"
    reads as anyone's denial. The doubling is what makes it a parrot, and the parrot is the joke.
  proposed_alternative: |
    "אין כלום! אין כלום!"  Raise dubi.firsttap to max 20 (19 chars; the bubble is a speech bubble,
    not a HUD label).
```

### O6. The player's chat auto-reply: truth
```yaml
objection:
  skill_or_agent: game-designer (truth gate)
  against_artifact: ux/first-minute.md §4.2 / §8 chat.reply.3 "בוצע. תמחק."
  reason: |
    Rubric gate 4. The reply is sent in the Magician's (Netanyahu's) voice and tells a real
    partner to delete the message. With Qatargate an open investigation (Netanyahu not a suspect)
    and trial evidence in the news, "delete this" is a plausible insinuation of destroying
    evidence, attributed to a real person. That is not plainly absurd, so it fails
    "invented news is never plausible-false".
  proposed_alternative: |
    "בוצע. אין כלום."  (14 chars. The catchphrase as a sign-off; same rhythm, now a callback, no
    insinuation.)
```

### O7. The brawl aftermath
```yaml
objection:
  skill_or_agent: game-designer (copy voice)
  against_artifact: ux/first-minute.md §4.2 / §8 chat.brawl.after "הוויכוח ממשיך בחוץ."
  reason: |
    Rubric gate 2. It restates the button's premise, so there's no turn. It also contradicts the
    copy deck §E, where the brawl ends in a new group.
  proposed_alternative: |
    Replace it with a system line: "נוצרה קבוצה חדשה: ״המסדרון״ · 2 משתתפים" (38 chars), plus a
    muted counter "{n} הודעות" that keeps climbing each time the chat tab is opened.
    Mechanism: the literal "go outside" becomes a new group chat, and the counter is the
    off-screen brawl. It is 1 template plus 1 integer, so it's cheap.
```

### O8. The receipt: two "real" lines have no source
```yaml
objection:
  skill_or_agent: game-designer (truth gate / references owner)
  against_artifact: ux/first-minute.md §5.1 receipt lines "חשמל: התייקרות*" and "מים: התייקרות*", and the fuel line
  reason: |
    Rubric gate 4. The footnote "* הנתון אמיתי" asserts that both lines are real, and neither
    has a source in the fact sheet or references.md. The fuel figure is now sourced
    (references.md #50: a record ₪8.25/L on 1.9.2026, since eased to about ₪8.01), but a
    bare "8.25 ₪ לליטר" reads as today's price.
  proposed_alternative: |
    Replace the three variable lines with three sourced ones (the amount split stays fiction):
      דלק 95: 8.25 ₪ לליטר (שיא, 1.9.2026)*   ← 60% of the taxpayer and high-tech income
      כנף ציון, החלק שלכם*                    ← 40%   [Wing of Zion, about NIS 750M, #20]
      גלידת פיסטוק: 0 ₪ (בוטל ב־2013)*          ← always 0 ₪   [#18]
    The 0 ₪ line is the receipt's one understatement gag and needs no data. Electricity and
    water can come back once someone supplies a dated source.
```

### O9. The receipt share text: a Latin unit in Hebrew prose
```yaml
objection:
  skill_or_agent: game-designer (copy voice)
  against_artifact: ux/first-minute.md §5.3 receipt share text "…עלתה למשפחה הממוצעת 4.2M ₪ החודש…"
  reason: |
    Rubric gate 1. "4.2M" is HUD shorthand. In a sentence someone sends to the family group it
    reads as English. People write "4.2 מיליון ₪".
  proposed_alternative: |
    "הקיסרות שלי ב״עוד סבב״ עלתה למשפחה הממוצעת 4.2 מיליון ₪ החודש. (במשחק. בינתיים.) <URL>"
    Compact K/M/B stays HUD-only; share prose uses Hebrew units.
```

### C1. Counter-objection to UX's pre-registered §9 objection 2
```yaml
objection:
  skill_or_agent: game-designer
  against_artifact: ux/first-minute.md §9 conditional objection 2, proposed_alternative ("Replace 'leads the polls' with … 'Sleepy Bibi', fact sheet [F]")
  reason: |
    The trigger doesn't fire: no copy-deck line says Eisenkot leads the polls. The fallback it
    proposes also breaks a red line. "Sleepy Bibi" is about the October 7 warnings, and the
    orchestrator accepted cutting it (pitch §2.5). I accept the rest of the alternative: the
    roulette as a literal wheel, "תוצאה אקראית. בערך כמו סקר.", and off from 23.10. My pitch
    §2.8 says the same.
  proposed_alternative: |
    Eisenkot is roasted only through "ישר" and "politics without magic" (deck T19 + the Eisenkot
    card: no rabbits while he's on screen). Tag the roulette caption "בערך כמו סקר" poll_like:true,
    so it can never show between 23.10 and 27.10.
```

**Accepted without counter:** UX's §9 objection 1 (secondary meters live on their objects, not in
the persistent HUD). Pitch §2 item 13 records it.

---

## 3. Seams: one owner per string

| # | String or slot | In UX | In the deck | Owner and resolution |
|---|---|---|---|---|
| S1 | Tab names | מקורות · ספינים · קואליציה · תיקים | "תיק הישגים" (trophies) | **UX** owns the tabs. The deck's "תיק הישגים" is the trophy *section inside* the תיקים tab. The pun stacks: a case file inside the cases. |
| S2 | Chat header | "קואליציה 61" + pixel lock | "קואליציה 61 🔒" | **UX.** The lock is a pixel icon (emoji aren't in the font). The deck's header is updated. |
| S3 | Chat system-line templates: joined, left, removed, added, transfer, brawl, cleared, rejoin | `chat.sys.*` ICU | Bracketed lines in §E | **UX** owns every template. The deck owns only the partners' *bubbles* and the "המסדרון" line (O7). The deck's bracketed lines are rewritten to UX's templates, e.g. "{name} הוסר על ידי מנהל". |
| S4 | Prestige button | "עוד סבב!" / "לפזר את הכנסת" | Pitch said "בחירות מוקדמות" | **UX.** "עוד סבב!" is the button, and it reuses the title. "Early elections" stays as the *concept* in the pitch. |
| S5 | Round card, public mood | `title.round` + mood.1-6 | §I counter ladder | **UX** owns the template and the mood rows. The deck's ladder retires. UX adopts O3, O4 and two additions: **mood.10** "הקלפי ביקשה חופשה." and **mood.20** "מישהו בדק שהציבור בסדר?". The round-5 fact line moves to the ticker (T23, which already covers it). |
| S6 | Return card | ret.* (4 tiers) | §I return lines | **UX** owns ret.* (with O1 and O2 applied). The deck keeps two *ticker* lines that fire when O1 closes: the away summary, and the Bibi-sitter line if it's owned. The deck's duplicate card bodies retire. |
| S7 | Court day | court.* chrome ("יום משפט") | §H "יום עדות" banner | **UX** owns the chrome, and the term is **"יום משפט"** everywhere. The deck's banner becomes the court-start ticker line "יום משפט. הכל מאט. הארנב מתחבא בכובע." The deck owns the excuse ladder, which shows under UX's "נדחה" stamp. |
| S8 | Suitcase miss and catch | Quotes the brief with a semicolon | §G | **The deck owns it.** The miss is "המזוודה הגיעה ליעדה. לא ידענו." A period, not a semicolon: speech register (gate 1). The first catch is H-catch in the deck. |
| S9 | FTUE headline slots H1, H2, H3, H-catch, H-cottage | Placeholders | Deck §A.1 | **The deck owns them.** H1 = T25, H2 = T03, H3 = T01, H-catch = T26 (new), H-cottage = T02, templated to the reveal threshold. The placeholder "מבזק: הכובע מכחיש שיש בו משהו" retires. |
| S10 | Election night and blackout | O11 / O12 modals | §I calendar lines | **UX** owns the modals. The deck's lines are *ticker* lines that follow them (the negotiation-mode opener; the blackout ticker line tagged poll_like:false). No duplicate text. |
| S11 | First source name | "משלם המסים העייף", "10 ₪" | "משלם המסים", 15 ₪ | **The deck owns the name.** The price is set in pitch §11: 15 ₪, reached in 12 taps. |
| S12 | Dubi's squawks: dubi.firsttap, .buy, .elect | §8 rows | Dubi's voice rule | **The deck owns the words** (UX's own ownership note gives Dubi's lines to the Game Designer). **UX owns placement.** Values: O5; .buy and .elect pass. |

The `poll_like` and `real_quote` tags UX asked for are now columns and tags in the deck (see
deck §0 and §A).
