# "עוד סבב": copy deck (all game-content Hebrew)

**Owner:** Game Designer · **Consumers:** Game Developer (string table), UX Designer (layout
lengths, microcopy seam), Audio Director (cue moments), 2D Artist (chat and receipt art).
UI microcopy (buttons, settings, disclaimer) belongs to UX; this deck is *content*.

## How to read this deck

- **Player address:** second person singular, **masculine** ("שלפת", "אתה"). The player *is* the
  Magician.
- **Dubi only repeats.** The ticker is his newsroom reading the script. When Dubi speaks in his own
  voice, it is always a repeated talking point, doubled: "אין כלום! אין כלום!". He never asks,
  reasons or improvises.
- **Tags:**
  - `[src: …]`: a real fact or quote, backed in `references.md`.
  - `[נוסח לאימות]`: our Hebrew rendering of a quote reported in English. Verify the exact Hebrew
    wording before shipping. Until then, show it as reported speech, not in quote marks.
  - Anything without a tag is invented and plainly absurd.
- **§0. Build tags** (requested by UX, first-minute §6.3 and §9):
  - **`poll_like`:** every line is `poll_like:false` **except** the lines marked `poll_like:true`
    below: Gotliv's card (§E) and the threshold-roulette card (§F).
    - True lines never show from 23.10 00:00 to 27.10 22:00.
    - §A has an explicit column.
    - No other line puts a digit within 3 words of "מנדט", "סקר", "מוביל" or "אחוז החסימה".
  - **`real_quote{source,date}`:** every `[src: …]` tag that marks a quote *is* this tag. The
    source and date sit in `references.md`.
    - Only `[Q]` rows render with UX's "ציטוט" label.
    - `[נוסח לאימות]` lines render as reported speech with no "ציטוט" label.
- **Ownership seam with UX** (`voice/review-designer.md` §3):
  - **UX owns:** tab names, chat system-line templates, the round card and moods, the return card,
    court chrome, and the O11/O12 modals.
  - **This deck owns:** headlines, Dubi's words, source, spin and partner names, partner bubbles,
    the suitcase lines, and the excuse ladder.
- **Length budgets:**
  - Ticker: ≤ 45 characters ideally, ≤ 60 at most.
  - Item flavour: ≤ 60.
  - Chat: reads like real chat.
- **Formatting:**
  - Latin digits, with ₪ after the number.
  - `{n}`, `{h}` are runtime variables.
  - No nikud (no pun here needs it).
- **Running callbacks:**
  - the hat;
  - the rabbit (right to remain silent);
  - the suitcase ("לא ידענו");
  - "אין כלום";
  - "התייעצות ביטחונית";
  - 17:00 deadlines;
  - Gantz's 99%;
  - the cottage cheese;
  - the round counter ("הציבור נרגש").

---

## A. Dubi's ticker: 26 flagship lines + 8 opposition lines (§A.2)

| ID | Line | Type | Source | poll_like |
|---|---|---|---|---|
| T01 | נרכש משלם מסים נוסף. הוא נאנח. זה נחשב הסכמה. | player (H3) | | false |
| T02 | הקופה עברה {x} ₪. הקוטג' איבד פיקסל. | player (H-cottage) | | false |
| T03 | ארנב קפץ מהכובע. קיבל זימון לעדות. | player (crit, H2) | | false |
| T04 | שדרגת את מכונת הרעל: 40,000 צפיות, 3 לייקים. | player | | false |
| T05 | בלפור: 3,000 לפי המשטרה, 30,000 לפי המארגנים, 61 לפי הקוסם. | era 1 | | false |
| T06 | כנף ציון נחתה בוושינגטון. בתא המטען: כביסה. לפי הפרסומים. | era 4 | [src: Wing of Zion; laundry suitcases, WaPo 2020, denied] | false |
| T07 | טראמפ שאל למי לעזאזל אכפת מסיגרים ושמפניה. בית המשפט: לנו. | era 4 / court | [src: Trump, Knesset, 13.10.2025] [נוסח לאימות]: reported speech, because the original is in English | false |
| T08 | גורמים בסביבת המזוודה: "היא רק עוברת פה." | suitcase | | false |
| T09 | משפט באגס באני: הארנב שומר על זכות השתיקה. | court | [src: Bugs Bunny trial] | false |
| T10 | הדיון נדחה. הנימוק יימסר בדיון הבא. | court | | false |
| T11 | החנינה: נדרשים מסמכים נוספים. המסמכים: נדרשת חנינה. | court | [src: pardon requested 30.11.2025; shelved 26.4.2026] | false |
| T12 | בן גביר איים לפרוש. זה כבר לא מבזק, זה לוח זמנים. | coalition | | false |
| T13 | סמוטריץ' מבקש להבהיר: אין כסף. יש העברות. | coalition | | false |
| T14 | שילמת לגפני. הוא יצא לשירותים. ההצבעה: תיקו. | coalition (fires only after the player pays Gafni) | | false |
| T15 | לפיד שאל "איפה הכסף?". דובי: "בכובע! בכובע!" | opposition | [src: Lapid, "איפה הכסף?"] | false |
| T16 | בנט חתם שלפיד לא יהיה רה"מ. היום הם רשימה אחת. העט בהלם. | opposition | [src: Bennett TV pledge 2021; merger Apr 2026] | false |
| T17 | גנץ מחכה לרוטציה מ-2020. הביא כיסא מתקפל. | opposition | [src: Gantz rotation 2020] | false |
| T18 | ליברמן לא יושב עם ביבי, לא עם בן גביר ולא על הגדר. | opposition | | false |
| T19 | אייזנקוט מבטיח פוליטיקה בלי קסמים. הקהל רוצה את הכסף בחזרה. | opposition | | false |
| T20 | גולן איחד את העבודה ומרצ. עכשיו רבים תחת קורת גג אחת. | opposition | [src: Labor + Meretz → the Democrats under Golan, announced 30.6.2024, ratified 12.7.2024] | false |
| T21 | האופוזיציה העבירה 800 מיליון ₪ בטעות. הקוסם לא נגע בכובע. | budget | [src: 2026 budget, NIS 800M by mistake] | false |
| T22 | המע"מ עלה ל-18%. איך שהוא גדל, בלי עין הרע. | budget | [src: VAT 18%, Jan 2025] | false |
| T23 | 5 מערכות בחירות בפחות מ-4 שנים. אצלנו זה החימום. | calendar | [src: five Knesset elections, Apr 2019 to Nov 2022 (IDI)] | false |
| T24 | עוד {n} ימים לבחירות. ואחר כך? עוד סבב. | calendar | [src: election 27.10.2026] | false |
| T25 | על פי פרסומים זרים, יש כובע. | Dubi / first line of the game (H1) | | false |
| T26 | תפסת מזוודה. בלשכה: "איזו מזוודה?" | suitcase (H-catch, first catch only) | | false |

### A.2 Opposition ticker (UX-21 balance fix): 8 lines, all `poll_like:false`

| ID | Line | Target | Source |
|---|---|---|---|
| T27 | בנט חתם על התחייבות חדשה. הפעם בעיפרון. | Bennett | [src: 2021 pledge, the callback] |
| T28 | גנץ שלח תזכורת לגבי הרוטציה. סטטוס: נקרא. | Gantz | [src: rotation 2020] |
| T29 | לפיד שאל "איפה הכסף?". שידור חוזר. | Lapid | [src: "איפה הכסף?"] |
| T30 | ליברמן הציג את הקווים האדומים שלו. זה פשוט דף אדום. | Liberman | |
| T31 | "ישר" מתנהלת ישר. בפוליטיקה זה נחשב קסם. | Eisenkot | [src: Yashar] |
| T32 | גולן הציע איחוד נוסף. הדמוקרטים עוד מתאחדים מהקודם. | Golan | [src: the 2024 merger] |
| T33 | אייזנקוט, לפיד ובנט נפגשו לתיאום. תיאמו פגישת תיאום. | Eisenkot, Lapid, Bennett | |
| T34 | האופוזיציה פתחה קבוצה משותפת. תוך שעה: שלוש קבוצות. | All (the trigger line for §E.2) | |

**Ticker balance after this change:** 15 opposition lines (T15-T21, T27-T34) to 17 coalition lines.

### A.1 FTUE slot map (UX `prompt-trigger-spec` H1-H3, H-catch, H-cottage)

| UX slot | Trigger (UX §2.4) | Line |
|---|---|---|
| **H1** | `taps_total==1`, played alongside Dubi's "אין כלום! אין כלום!" | T25 "על פי פרסומים זרים, יש כובע." |
| **H2** | Tap 7, the scripted first rabbit | T03 |
| **H3** | First purchase | T01 |
| **H-catch** | First Suitcase caught | T26. Later catches use §G. |
| **H-miss** | First Suitcase missed | §G miss line |
| **H-cottage** | `lifetime_earned >= 1,000 ₪` (the cup appears) | T02 with {x}=1,000. It re-fires at every ×10 (10,000, 100,000…), each time the cup loses a pixel. |
| **H-court** | Court day starts | "יום משפט. הכל מאט. הארנב מתחבא בכובע." |

**Other placement notes:**
- **T24** runs daily until 26.10, and uses ICU for the day count:
  `עוד {d, plural, one {יום אחד} two {יומיים} other {# ימים}} לבחירות. ואחר כך? עוד סבב.`
  On 27.10 it swaps to the negotiation-mode opener in §I.
- **T09** is suppressed during round 3, the round whose flash (B3) carries the same joke.
- **Typography** (UX global note): ASCII `' "` inside Hebrew words become ׳ ״, and prefix-letter hyphens before digits become a maqaf. This is a build pass that skips real quotes.

---

## B. Dubi's story flashes: the five beats and the encore

Format: a news-flash card after each election round, with a header and then 2-4 lines.

### B1. After round 1: "the hat that never runs out"
> 📺 **מבזק | סבב בחירות מס' 1**
> הקוסם שלף 61 מכובע ריק.
> בלשכה מסרו: "אין שום כובע."
> דובי: "אין כובע! אין כובע!"
> הוחלט על בחירות. שוב. הציבור נרגש.

### B2. After round 2: "the partners discover the hat"
> 📺 **מבזק | סבב בחירות מס' 2**
> השותפים גילו את הכובע.
> בכובע יש עכשיו 61 ידיים.
> כל שליפה: בכפוף להסכם קואליציוני.
> דובי: "כספים קואליציוניים! כספים קואליציוניים!"

### B3. After round 3: "the hat gets subpoenaed"
> 📺 **מבזק | סבב בחירות מס' 3**
> הכובע קיבל זימון לעדות.
> הארנב שומר על זכות השתיקה.
> הלשכה ביקשה דחייה: התייעצות ביטחונית.

### B4. After round 4: "the suitcase has two addresses"
> 📺 **מבזק | סבב בחירות מס' 4**
> למזוודה נמצאו שתי כתובות: דוחא, ושולחן של יועץ.
> החשד: על היועצים. הקוסם: לא חשוד. `[src: Qatargate, aides suspected, Netanyahu not a suspect]`
> דובי: "ציד מכשפות! ציד מכשפות!" `[src: "witch hunt"]`

### B5. After round 5: "Washington wants a suitcase too"
> 📺 **מבזק | סבב בחירות מס' 5**
> וושינגטון ביקשה מזוודה משלה.
> קיבלה אחת. מלאה כביסה. לפי הפרסומים. `[src: WaPo 2020]`
> בלשכה: הכחשה. הכביסה: יצאה נקייה. `[src: Israel denied]`

### B6. The encore (after round 6 and every round after)
> 📺 **מבזק | סבב בחירות מס' {n}**
> המשחק ייגמר כשייגמרו הבחירות.
> כלומר: סבב בחירות מס' {n+1}.
> אין סוף. יש עוד סבב.

---

## C. The 8 money sources

| # | Name | Flavour (≤ 60) | Level-up line | Source |
|---|---|---|---|---|
| 1 | **משלם המסים** | משלם, נאנח, משלם. | עוד משלם מסים. אותה אנחה, בסטריאו. | |
| 2 | **ההייטקיסט** | מממן חצי מדינה. טאב של ליסבון פתוח ברקע. | עוד הייטקיסט. הקופה מחייכת, נתב"ג מתכונן. | (when the post-launch departure board ships, "עוד שורה בלוח ההמראות." becomes its flavour text) [src: 69,300 left in 2025] |
| 3 | **המע"מ** | 18% מכל דבר. כולל הקוטג'. | המע"מ עלה דרגה. בקופה חוגגים, בסופר שותקים. | [src: VAT 18%] |
| 4 | **החבר הנדיב** | סיגרים, שמפניה ורודה וחברות אמיצה. כתב אישום בנפרד. | הגיע ארגז. "סתם, מחברות." | [src: Case 1000, alleged; donors never named] |
| 5 | **הצוללת** | יורדת עמוק, עולה עם עמלות. | הפריסקופ רואה הכל. חוץ ממכתבי אזהרה. | [src: Case 3000, commission warning letters] |
| 6 | **היועצים הקטאריים** | מקדמים מסר, מקבלים דרך מתווך. החשודים: הם. אתה: לא. | עוד יועץ. אתה לא מכיר אותו. עדיין. | [src: Qatargate, aides suspected] |
| 7 | **מכונת הרעל** | 10,000 חשבונות. דעה אחת. | 1,000 עוקבים חדשים. כולם "ישראלי_גאה_83921". | |
| 8 | **פנקס הצ'קים הזהוב** | מוושינגטון באהבה. חתום בטוש, הכי עבה שיש. | צ'ק חדש. מגיע עם פוסט באותיות גדולות. | |

**Notes:**
- **Suspicion:** sources 1-3 are clean; sources 4-7 add suspicion.
- **The payers:**
  - Sources 1-2 are drawn with sympathy. The joke is always the money's destination, never the
    payer.
  - The high-tech line is about the policy, never the people who leave.

---

## D. Spins (upgrades): 14

| ID | Name | Effect (designer spec) | Joke line (≤ 60) | Source |
|---|---|---|---|---|
| S01 | **פיקדון על בקבוקים** | +0.30 ₪ per tap. Price: **4,000 ₪**. The smallest upgrade in the game. | השדרוג הכי קטן במשחק. לפי הפרסומים, הוחזר. | [src: bottle deposits, NIS 4,000 repaid] |
| S02 | **גלידת פיסטוק** | Tap ×1.5 for 60 s. Price: **10,000 ₪**. | תקציב 10,000 ₪ לשנה, בוטל ב-2013. אצלנו: נמס תוך דקה. | [src: ice-cream budget, 2013] |
| S03 | **ביביסיטר** | Offline earnings ×2 | שומר על הקופה כשאתה לא פה. לא שואל שאלות. | [src: "Bibi-sitter" ad, 2015] |
| S04 | **לא יהיה כלום** | Suspicion gain −25% | "לא יהיה כלום כי אין כלום." בתוקף עד שיהיה משהו. | [src: quote, 2017] |
| S05 | **ציד מכשפות** | Every opposition card gives +1 base | כל כותרת נגדך מחזקת את הבסיס. מכשפות שנתפסו: 0. | [src: "witch hunt"] |
| S06 | **כנף ציון** | Unlocks the Washington era. Price: **750,000,000 ₪**. | הסבה בכ-750 מיליון ₪. מושב חלון, כמובן. | [src: Wing of Zion] |
| S07 | **סופר-ספרטה** | For 30 s, all idle income pours into the tap | עצמאות כלכלית מלאה. באצבע אחת. | [src: "Super-Sparta", Sept 2025] |
| S08 | **השלט** (Karhi line) | Drains "שידור ציבורי" into "ערוץ ידידותי": +base, +suspicion | ביקורת על סרט שלא ראיתי: 1/5. | [src: Karhi, "1948", unwatched; media law] |
| S09 | **פייג'ר זהב** | Golden checkbook ×1.5 | מתנה קטנה, צ'ק גדול. | [src: golden pager, Feb 2025] |
| S10 | **מזוודות כביסה** | Every Washington flight: +5% income | וושינגטון פוסט: כביסה. ישראל: הכחשה. המכונה: 40 מעלות. | [src: WaPo 2020, denied] |
| S11 | **באגס באני** | Rabbit chance +5% | הארנב קופץ יותר. המשפט זוחל כרגיל. | [src: Bugs Bunny trial] |
| S12 | **הוחלט להקים ועדה** | Suspicion frozen for 60 s | החשד מוקפא עד שהוועדה תחליט. היא לא תחליט. | |
| S13 | **ראיון בערוץ ידידותי** | +10% base this round. Next morning a "הנחה באגרה" invoice arrives. | שאלות קשות: 0. מחר בבוקר: הנחה באגרה. | [src: fee break, per Haaretz, alleged] |
| S14 | **סרטון ויראלי** | Poison-machine view counter ×10, "real likes" +1 | מיליוני צפיות. הלייקים עוד בדרך. | [src: "אני ביביסט" engagement, Walla, parodied generically] |

**Rules:**
- **Spin fatigue:** rebuying the same spin yields less.
- **Word salad:** at high bot-farm levels, Dubi's ticker degrades. See §I.

---

## E. The coalition group chat: "קואליציה 61" (+ pixel lock icon)

**What this chat is:**
- Generic chat styling, with no messaging-app branding.
- Every message here is **invented** and in the character's public *voice* only. It never states
  a fact about them unless it's tagged.
- There are no typos as jokes.
- **System lines** use UX's `chat.sys.*` templates (first-minute §8), which UX owns. Below they
  appear as `[…]` with the name already filled in. This deck owns only the partner bubbles and
  the "המסדרון" line.
- **Amounts in bubbles** are `{price}`, the same value as the pay pill "סגרנו · {price} ₪", so the
  text never contradicts the pill.

**Message types:**
- **Demand:** carries UX's pay pill (`chat.pay`, "סגרנו · {price} ₪").
- **Threat:** a timer starts.
- **Return / thanks:** after payment.

### Itamar Ben Gvir
- **Demand** (the first chat bubble of the game, FTUE C1): צריך תקציב לביטחון לאומי. היום. זה לא איום. עדיין 🔥
- **Threat** (always rendered as a forwarded message):
  > ↪︎ *הועברה פעמים רבות*
  > אם זה לא עובר, אני יוצא מהממשלה.
- **Return:** `[איתמר בן גביר הצטרף לקבוצה]` (the rejoin pill "להחזיר לקבוצה") חזרתי. לא בגלל הכסף. גם בגלל הכסף 🙏

### Bezalel Smotrich
- **Demand:** בתור שר האוצר: אין כסף. בתור יו"ר מפלגה: תעביר 💸
- **Threat:** אם זה לא נסגר עד 17:00, אני מפרק את הממשלה. ב-17:15 יש לי ועדת כספים.
- **Thanks:** הגיע. תודה 👍 ולהזכירכם: אין כסף.

### Aryeh Deri
- **Demand:** נסגור את זה במסדרון ☕ תביא פנקס. (2026-10-01: "ידידי" removed; it is Ben Gvir's tic, see design/content.json)
- **Threat:** ש"ס לא מאיימת. ש"ס מזכירה. זו תזכורת שלישית 🙏
- **Status line** (permanent): יצאנו מהממשלה, לא מהקבוצה. פה נוח. `[src: Haredi parties left the government, July 2025]`

### Yitzhak Goldknopf
Mechanic: the price only goes up.
- **Demand:** {price} וסגרנו. אחרון, באמת 🤝
- **After payment:** תודה!! עכשיו זה {next_price}. זה לא אני, זה השוק 📈
- **Threat:** אם לא, אני עוזב. רגע, כבר עזבתי. אז אני עוזב יותר. `[src: left the government, July 2025]`

### Moshe Gafni
Mechanic: the abstention broker.
- **Demand:** לא בעד, לא נגד. יוצא לשירותים 🚻 המחיר בהתאם.
- **Threat:** ההצבעה ב-17:00. אם לא סגרנו, אני דווקא נשאר באולם.
- **Thanks:** סגרנו. יצא תיקו, כמו שהזמנת 👌

### Yariv Levin
- **Demand:** צריך ועדה לבחירת שופטים. הרכב מוצע: אני, אני ועוד אני ⚖️
- **Threat:** אם זה לא עובר, אני עותר לבג"ץ. ...רגע.
- **Thanks:** עבר. נתראה ברפורמה הבאה.

### Miri Regev
Mechanic: demands a ceremony instead of money.
- **Demand:** רוצה לחנוך משהו. לא משנה מה. עם סרט ומספריים 🎀✂️
- **Threat:** אין טקס? אני מתפטרת. בטקס.
- **Thanks:** איזה ערב. בכיתי. מישהו צילם? 📸

### Tally Gotliv
Before the transfer.
- **Demand:** אני דורשת מקום ריאלי!!! לא "ריאלי בערך". ריאלי!!!
- **Threat:** עוד מילה אחת ואני עוברת. יש לי הצעות!!!
- **Her card** (reported speech, not a chat bubble): Gotliv said that if Likud gets 19 seats she
  expects to end up in a Shin Bet detention facility, and that the primary against her was a
  "targeted assassination". `[src: JPost 1.9, ToI 3.9, INN 2.9.2026] [נוסח לאימות]` **`poll_like:true`**
  (it names a seat number; hidden 23.10-27.10).
  - **Guardrail:** never mention the covert officer.

### David (Dudi) Amsalem
- **Demand:** תעביר תקציב ואני מפסיק לצעוק. לא, לא מפסיק. אבל תעביר.
- **Threat:** עוד יום בלי תקציב ואני עולה לאולפן. בלי מיקרופון.
- **Thanks:** תודה. `[מערכת: אמסלם כתב הודעה בלי סימן קריאה. לראשונה.]`

### Shlomo Karhi
- **Demand:** 25 מיליון בשנה עוברים מ"כאן" ל"שם" 📺⬅️📺 `[src: NIS 25M/yr out of Kan]`. The arrow points left, the direction of motion in RTL. **The one sourced exception to the `{price}` rule:** the bubble quotes the real transfer, and the pill carries the in-game price.
- **Threat:** אם "כאן" ממשיך לשדר, אני מעביר ערוץ. לכולם.
- **Thanks:** עבר. שלט אחד, כל הערוצים 📺 `[src: media law passed 53-48, Jul 2026]`
- **His item review** (also on S08): ביקורת על סרט שלא ראיתי: 1/5 ⭐ `[src: hadn't watched "1948"]`

### May Golan
Mechanic: phantom employees. Every hire adds suspicion. The card label reads: *"לפי המלצת
המשטרה: חשד למשרות פיקטיביות"* `[src, alleged]`.
- **Demand:** צריכה עוד 3 תקנים למשרד. דחוף 👻
- **Threat:** לא מאשרים? אני יוצאת מהקבוצה. ברצינות. תכף.
- **Thanks:** תודה!! הצוות מתחיל מחר 👻

### Galit Distel-Atbaryan
Mechanic: the mute button. The next law passes instantly and audit risk rises.
- **Demand:** חוק חדש, עובר תוך 4 שניות. לפני שמישהו אומר "אבל".
- **System line** (a one-off; UX to add a `chat.sys.muted` template): `[היועצים המשפטיים ביקשו רשות דיבור · נדחה]` with the pixel mute icon `[src: barred the legal advisers]`
- **Threat:** אם מחזירים להם מיקרופון, אני לוקחת את שלי והולכת.
- **Thanks:** שקט פה. נעים 🔇

### Almog Cohen: the origin of the chat
- **System line** (UX `chat.sys.removed`): `[אלמוג כהן הוסר על ידי מנהל]` `[src: removed from Otzma's groups]`
- **Poach action** (UX `chat.sys.added`): `[אלמוג כהן צורף על ידי מנהל]`, then Dubi's ticker: "אלמוג כהן הוסר מקבוצה אחת וצורף לאחרת. ניידות חברתית." `[src: removed from Otzma groups; later 8th in the Likud primary]`
- **Guardrail:** his outbursts are off-limits.

### The defector (generic, not Illouz)
- **Ticker** (reported speech until the Hebrew is verified): לפי דן אילוז, הליכוד הפך לקבלן משנה של דרעי וגולדקנופף. `[src: JPost] [נוסח לאימות]`
- **System line:** `[ח"כ ממורמר יצא מהבניין · כיוון: ליברמן]`

### Event: Gotliv's transfer window
> ⚽ **חלון העברות נפתח**
> `[טלי גוטליב עזבה · צורפה ל״עוצמה יהודית״]` (UX `chat.sys.transfer`) `[src: Sep 2026]`
> **בן גביר:** ברוכה הבאה טלי 💪
> **בן גביר:** @הקוסם יש לך 90 שניות להעביר לה את התקציב ⏳
> **בן גביר:** 60
> **בן גביר:** 30
> **גוטליב:** תודה איתמר!!! סוף סוף מקשיבים לי!!!

The countdown is the ultimatum timer, 90 s, and never runs before 3:00 of play (pitch §11). Ben
Gvir's "60" and "30" post at those ticks.

Ticker at the same moment: **מבזק ספורט: גוטליב החליפה חולצה. הווליום נשאר.**

### Event: the brawl, "צאו החוצה"
> 💥 **קטטה בקבוצה**
> `[לפי הדיווחים, אמסלם ביקש מסמוטריץ' שלא יקרא לו חוצפן · מקור]` (a system pill in reported speech) `[src: 19.1.2026] [נוסח לאימות]`
> **אמסלם:** אל תקרא לי ככה. (invented bubble. Once the Hebrew is verified, it can become the exact quote with the ציטוט tag.)
> **סמוטריץ':** 🙄
> **אמסלם:** גם לא אימוג'י!!
> `[אמסלם וסמוטריץ' רבים. שתי השורות הוקפאו.]` (UX `chat.sys.brawl`)
> **[ צאו החוצה ]**
> **הקוסם** (reported speech): אם הם לא מנהיגים, שייצאו החוצה וימשיכו להתווכח שם. `[src] [נוסח לאימות]`
> `[אמסלם וסמוטריץ' יצאו מהקבוצה]`
> `[נוצרה קבוצה חדשה: ״המסדרון״ · 2 משתתפים]` plus a muted counter, "{n} הודעות", that climbs every time the chat is opened (this replaces UX `chat.brawl.after`; see review O7).

**Generic brawl, for any pair:** UX `chat.sys.brawl`, then the same button, then the same
"המסדרון" line. It's one shared group, so its counter keeps growing across brawls.

### E.2 Event: the leaked opposition chat, "צילום מסך דלף" (UX-21)

**How it works:**
- It's read-only. It uses the same bubble component on a torn "screenshot" frame (UX owns the
  frame).
- It fires alongside an opposition card, at most once per election round, and plays the three
  leaks in order, then loops.
- Opening it gives nothing and costs nothing. It's pure comedy.
- **Ticker when it fires:** מבזק: צילום מסך דלף מהאופוזיציה. גנץ עדיין מקליד.

**Rules** (the same as §E):
- Every bubble is **invented** and in the character's public voice only.
- No facts except where tagged.
- No seats, polls or "who's leading", so the whole event is `poll_like:false`.
- Nothing military, nothing about families.
- The group has 6 members. **Gantz never posts.** The header status is permanently
  **"בני גנץ מקליד…"**, the visual twin of his 99% rotation bar.

**Group title:** האופוזיציה (רשמי) (סופי) 2 · 6 משתתפים · *בני גנץ מקליד…*

**Leak 1: "the question"**
> **לפיד:** איפה הכסף? `[src: Lapid's quote]`
> **בנט:** מתחייב לענות עד מחר. חתמתי 🖊️
> **לפיד:** חתמת גם בפעם הקודמת.
> **בנט:** בגלל זה אני חותם שוב.
> **אייזנקוט:** אפשר לדבר ישר?
> **גולן:** אפשר. רק קודם נאחד את הקבוצה הזאת עם הקבוצה ההיא.
> `[גולן איחד את הקבוצות · נוצרה ״האופוזיציה (רשמי) (סופי) 3״]`
> **ליברמן:** לא יושב בקבוצה הזאת.
> **ליברמן:** גם לא ב-3.
> `[ליברמן עזב את הקבוצה]`

**Leak 2: "one simple message"**
> **אייזנקוט:** מציע מסר אחד. פשוט. ישר.
> **לפיד:** מסכים. אני אנסח. זה ייקח 40 דקות.
> **בנט:** אני אחתום עליו.
> **גולן:** אני אאחד אותו עם עוד מסר.
> **ליברמן:** לא יושב עם המסר הזה.
> **אייזנקוט:** אז מה המסר?
> **לפיד:** איפה הכסף?

**Leak 3: "rotation"**
> **לפיד:** מציע רוטציה בניהול הקבוצה.
> **בנט:** מתחייב לכבד אותה. בעיפרון.
> **אייזנקוט:** ישר: מי ראשון?
> **גולן:** גנץ, אתה פה הכי הרבה זמן. תגיד משהו.
> *בני גנץ מקליד…*
> **ליברמן:** אני לא מחכה.
> `[ליברמן עזב את הקבוצה]`
> *בני גנץ מקליד…*

---

## F. Opposition cards

| Card | Mechanic (1 line) | Copy | Source |
|---|---|---|---|
| **יאיר לפיד** | Audit: reveals one shady source, +suspicion | שואל "איפה הכסף?". התשובה: בכובע. השאלה: ממשיכה. | [src: "איפה הכסף?"] |
| **נפתלי בנט** | Pledge card: he promises not to back X, and it flips when the timer ends | חותם על התחייבויות בשידור חי. מכבד אותן עד השידור הבא. | [src: 2021 pledge] |
| **גדי אייזנקוט** | While on screen: no rabbits | הקים את "ישר": פוליטיקה בלי קסמים. הארנבים יצאו לחל"ת. | [src: Yashar] |
| **בני גנץ** | A stand-in partner when someone quits. His rotation bar is stuck at 99%. | נכנס לקבוצה כשמישהו עוזב. הרוטציה: 99%. מאז 2020. | [src: rotation 2020] |
| **אביגדור ליברמן** | Every button greyed out: "לא יושב" | מקבל כל הצעה בכבוד, ודוחה אותה באותו כבוד. | |
| **יאיר גולן** | Merger: the last two opposition cards fuse into one | מאחד שני קלפים לאחד. חוסך מקום, מכפיל ויכוחים. | [src: see T20] |
| **מנסור עבאס** | A hidden seat source, visible only while Ben Gvir is offline | 2019: "ביבי או טיבי". 2021, לפי עבאס: נאום על שותפות. **Rule line** (UX chrome, directly under it): מופיע רק כשבן גביר לא מחובר | [src: slogan 2019; talks per Abbas 2021] |
| **המפלגה ללא שם** *(post-launch)* | Spawns, drains seats, dissolves by itself | (title line: ארדן · אדלשטיין) מפלגה בלי שם. אחרי חודש ארדן עזב. מצע: יש. שם: בהמשך. | [src: ToI] |
| **רולטת אחוז החסימה** *(post-launch)* | Lists bob around the line; which one sinks is **random and uniform** every round; off from 23.10 | 3.25%. מעליו: מפלגה. מתחתיו: קבוצת חברים עם מצע. | [src: threshold 3.25%] **`poll_like:true`** |

**Guardrails:**
- The threshold-roulette caricatures are Winter, Hendel with Zelekha, and Haskel. List names are
  never shown (see pitch §2.7).
- 🚩 *Mordechai David (flagged, recommend drop):* Eisenkot's comeback, "לך תשרת ותחזור אליי",
  exists `[src]` but is not used at launch.

---

## G. The Suitcase

| Outcome | Line | Source |
|---|---|---|
| **Catch: cash** (default) | תפסת! בפנים: מזומן. מאיפה? לא נמסרה תגובה. | |
| **Catch: laundry** (Washington era only) | תפסת! בפנים: כביסה מוושינגטון. מקופלת. לפי הפרסומים. | [src: WaPo 2020, denied] |
| **Catch: the aide** (the money lands on an aide's card) | תפסת! הכסף נחת אצל יועץ. לא אצלך. בשום אופן לא אצלך. | [src: Qatargate framing] |
| **Miss** (also H-miss; this deck owns it, with a period rather than UX's semicolon) | המזוודה הגיעה ליעדה. לא ידענו. | |
| Miss: Dubi's follow-up | דובי: "לא ידענו! לא ידענו!" | |
| **Aide drop:** button **"אני לא מכיר אותו"** (suspicion falls to the round's floor, pitch §11 Q8; "אופס" is both "reset" and "oops") | היועץ הוסר מהקבוצה. החשד אופס. הבסיס שם לב: ‎−3%. | |
| Aide drop: Dubi's follow-up | דובי: "מי? מי?" | |

The suitcase never has a Gaza destination. Its two addresses are Doha and an aide's desk (pitch
§2.4).

---

## H. Court day

**Court-day ticker line (H-court):** יום משפט. הכל מאט. הארנב מתחבא בכובע.
UX owns the court card itself (`court.*`, "יום משפט"). The term is "יום משפט" everywhere.

### "התייעצות ביטחונית": the postponement excuse, one sentence longer each time
Every postponement shows UX's "נדחה" stamp (`court.stamp`) on the court card. Under the stamp
is the full, growing text below, prefixed **"הדיון נדחה:"**. The button stays UX's
`court.postpone`: "התייעצות ביטחונית · {price} ₪".

1. התייעצות ביטחונית.
2. התייעצות ביטחונית. דחופה.
3. התייעצות ביטחונית. דחופה. עם אנשים רציניים מאוד.
4. התייעצות ביטחונית. דחופה. עם אנשים רציניים מאוד. אחד מהם הביא בורקס.
5. התייעצות ביטחונית. דחופה. עם אנשים רציניים מאוד. אחד מהם הביא בורקס. הבורקס סווג.
6. התייעצות ביטחונית. דחופה. עם אנשים רציניים מאוד. אחד מהם הביא בורקס. הבורקס סווג. ההתייעצות הבאה נקבעה בדיוק לדיון הבא.

After step 6 the text loops at step 6. **Guardrail:** no excuse ever names a front, an enemy, a
threat or a real security event. The joke is the pastry.

### The pardon desk: stamp lines (random, never repeating twice in a row)
1. נדרשים מסמכים נוספים.
2. נדרש צילום של המסמכים הנוספים.
3. הטופס מולא בכחול. נדרש שחור.
4. נא לפנות לאשנב 4. (אין אשנב 4.)
5. הבקשה הועברה לטיפול. הטיפול הועבר לבקשה.
6. חתימה לא ברורה. נא לחתום ברור יותר. (גם זה לא ברור.)
7. מומלץ לשקול הסדר טיעון. `[src: Herzog pushed for a plea deal, 26.4.2026]`
8. הלשכה פתוחה בימים ב' ו-ה', חוץ מבימים ב' ו-ה'.

---

## I. The rest

### Return after being away
**UX owns the return card (`ret.*`),** with review O1 and O2 applied. This deck adds only two
*ticker* lines. They fire as the first headline after the card is collected:
- **With a summary:** בזמן שלא היית: 3 איומי פרישה, 2 חזרות לקבוצה, ו-{n} פעמים "אין כלום".
- **If the Bibi-sitter is owned:** הביביסיטר מדווח: היה שקט. לא היה כלום. כי אין כלום.

(Retired as duplicates of `ret.*`: the "משלמי המסים המשיכו לשלם" line and the ">8 h" line. The
latter moved into UX's card via O1.)

### The election-round counter card
**UX owns** the template `title.round` and the moods (`mood.*`), rendered on two lines per review
O4. The two additions this deck proposes to UX:
- **mood.10:** הקלפי ביקשה חופשה.
- **mood.20:** מישהו בדק שהציבור בסדר?

The round-5 fact is carried by ticker T23.

### The real calendar
These are ticker lines. UX's O11 and O12 modals come first, and they own the notice text.
- **23.10 to 26.10** (seat comparisons locked; `poll_like:false`): עד הבחירות: בלי סקרים. אפילו לא סקר על סקרים.
- **From 27.10**, the first headline of the "משא ומתן קואליציוני" mode: מתחיל משא ומתן קואליציוני. משך משוער: כן.

### Dubi's squawks (this deck owns the words; UX owns the placement)
| UX ID | Squawk | When |
|---|---|---|
| dubi.firsttap | אין כלום! אין כלום! | Tap 1. Budget 20 (review O5). |
| dubi.buy | לקנות! לקנות! | P1 fallback |
| dubi.elect | בחירות! בחירות! | E1 fallback |
| dubi.miss | לא ידענו! לא ידענו! | After a Suitcase miss (§G) |
| dubi.drop | מי? מי? | After an aide drop (§G) |

### Spin fatigue: Dubi's word salad at a high bot-farm level
- ציד! כלום! אין מכשפות! כלום ציד! אין אין!
- (Built at runtime by shuffling the words of his last three talking points. This line is the
  reference sample.)

### "תיק הישגים": 5 trophies (a section inside UX's "תיקים" tab)
| Trophy | Condition |
|---|---|
| **תיק 1000** | You earned your first 1,000 ₪. |
| **חמש בפחות מארבע** | 5 election rounds in under 4 hours of play. `[src: five Knesset elections, Apr 2019 to Nov 2022]` |
| **הרוטציה של גנץ** | Never awarded. The progress bar sits at 99% forever. |
| **נדרשים מסמכים נוספים** | You filed a pardon request 10 times. |
| **לא מכיר אף אחד** | You pressed "אני לא מכיר אותו" 3 times. |

("שלום בית בפריים" stays as specced in the brief's Liran and Tomer easter egg, post-launch.)

---

## Bench (cut, but still good; swap in freely)

- ישיבת קואליציה: 120 דקות, 61 דרישות, 0 החלטות.
- מבזק: לא קרה כלום. פרטים בהמשך.
- נמצא חור בתקציב. הקוסם הכניס יד ושלף ארנב.
- דובי ביקש העלאה. נענה "לא יהיה כלום". חזר על זה בשמחה.
- הכנסת: 120 כיסאות, 61 דרישות.
- תקציב 2026: 850.6 מיליארד ₪. שיא כל הזמנים. עד הסבב הבא. `[src: 2026 budget]`
- כסף קטן: 4,000 ₪ מבקבוקים. כסף גדול: כ-750 מיליון ₪ למטוס. `[src: bottles; Wing of Zion]`
- מזוודה בורדו נצפתה בשמיים. מדבקה: DOHA. לא נמסרה תגובה.
- מקורבים לכובע: "הוא מעולם לא היה ריק."
- הטאפ האחרון שלך הוצא מהקשרו. לא נמסרה תגובה.
- בנט ולפיד רשימה אחת. מי בראש? יוכרע בהטלת חתימה.
- ארדן עזב את המפלגה ללא שם. לא הצליח למצוא אותה בחיפוש. `[src]`
- ראיון בערוץ ידידותי. למחרת: הנחה באגרה. איזה מזל. `[src: Haaretz, alleged]`
- *(post-launch, Kaia)* כאיה נשכה שר. השר החמיץ הצבעה. כאיה קיבלה מלפפון. `[src: Kaia, 2015-18]`
- *(post-launch, travel shop)* חשבון נסיעה: 295 דולר לתיקון דלת בשגרירות. הדלת מרגישה מצוין. `[src: JPost, 16-17.9.2026]`
- *(post-launch, Liran and Tomer)* מישהו בחולצה אפורה עומד מאחור. שוב.
- *(trophy, clean route)* **כסף נקי**: You finished a round without a single shady source.
- *(ticker, rejected)* הוחלט להקים ועדה. הוועדה החליטה להקים ועדה. (It's a classic, so it reads
  as generic.)
