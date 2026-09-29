# ChatGPT asset requests

Some art in this game comes from **ChatGPT reference images** that Bar and the orchestrator generate
in Bar's ChatGPT conversation "יצירת דמות בפיקסל ארט". They're then rendered down to game pixels
with the approved pipeline in
`gamestudio/output/artifacts/creative-pack/od-sevev/art/showcase/src/` (rig.py, build.py, cast.py).

**Agents never generate these themselves.** When you need one, add a row below and keep working
with a placeholder. The orchestrator batches the requests, generates them, saves the refs to
`gamestudio/output/artifacts/creative-pack/od-sevev/art/refs/<slug>.png`, renders them down, and
ticks the row.

Style for every request: the same style as the approved cast (satirical pixel-art caricature, full
body, slightly big head), **transparent background**, no logos, no text. Objects and critters use
the same rendering style.

| status | slug | for (file/feature) | what (Hebrew prompt, or English description) | size in game (art px) | requested by |
|---|---|---|---|---|---|
| generating | karhi | coalition chat, partner card | שלמה קרעי: זקן כהה, כיפה סרוגה, חליפה כהה; מכוון שלט טלוויזיה גדול | 96 tall | orchestrator |
| done (opt1 picked by Bar 2026-09-29; rendered d=3, `chars["may-golan"]`, alias `maygolan`) | may-golan | coalition chat, partner card | מאי גולן: שיער כהה ארוך, ז'קט מחויט; קלסר, שתי רוחות רפאים חמודות לידה | 96 tall | orchestrator |
| generating | distel | coalition chat, partner card | גלית דיסטל-אטבריאן: שיער בהיר ארוך; לוחצת על כפתור השתק גדול | 96 tall | orchestrator |
| generating | lapid, eisenkot, gantz, liberman, golan, abbas | opposition cards, leaked chat | see creative-pack cast list | 96 tall | orchestrator |
| generating | herzog, trump | pardon desk, Washington era | see creative-pack cast list | 96 tall | orchestrator |
| generating | smotrich | redo: the first ref has an opaque background | same pose, transparent background | 96 tall | orchestrator |
| generating | dubi | narrator (replaces CHIP) | דובי: תוכי ירוק בחליפה ועניבה כחולה, מקור פתוח, כנף מורמת | 96 tall | orchestrator |
| dropped (2D Artist hand-drew it at 24x18) | suitcase | golden bonus (replaces Golden Banana) | מזוודה בורדו עם מדבקת DOHA | ~32 wide | orchestrator |
| generating | taxpayer, hitech, vat, cigars, submarine, qatari, poison, checkbook | the 8 money sources (diorama + shop icons) | see pitch §money sources; fictional, drawn with sympathy | **40 tall** + 2-frame idle (TA objection accepted) | orchestrator |
| done | amsalem, gafni, goldknopf, deri, levin, regev, gotliv, ben-gvir | cast | refs in creative-pack art/refs | 96 tall | orchestrator |
| queued | dubi-mic | ticker anchor ("מבזק" end of the ticker), Dubi's flashes; replaces `art/od-sevev/out/ui/props/dubi_placeholder_*` | דובי, תוכי ירוק בפרופיל (המקור המעוקל הוא הצללית), חליפה כהה ועניבה כחולה בוהקת, מחזיק מיקרופון מול המקור, פה פתוח באמצע צעקה; אותו תוכי כמו בשורת dubi, תנוחה שנייה | 96 tall (full body) + the 32x32 avatar crop | 2d-artist |
| queued | photobomber-grey | easter egg "תמיד בפריים": share-card margins, court scene, Dubi's flashes | דמות רקע: גבר בחולצת טי אפורה פשוטה, עומד מאחור ומציץ למצלמה, פנים גנריות בכוונה (כינוי בלבד, לא דיוקן), בלי לוגו | 48 tall (a background figure, half the cast height) | 2d-artist |
| queued | photobomber-white | easter egg "תמיד בפריים" (the second figure, one frame later) | דמות רקע: גבר לבוש כולו לבן עם משקפי שמש לבנים גדולים ושיער משוך לאחור, תנוחת פוזה למצלמה (כינוי בלבד, לא דיוקן), בלי לוגו | 48 tall | 2d-artist |
| queued | aide | Suitcase outcome "הכסף נחת אצל יועץ" + the "אני לא מכיר אותו" aide card (deck §G) | יועץ בדוי וגנרי (לא אדם אמיתי): גבר צעיר בחליפה כהה, אוזנייה, טלפון צמוד לאוזן, מבט מתחמק הצידה; מחזיק תיק מסמכים. אותו סגנון כמו הקאסט, רקע שקוף | 96 tall (+ 32x32 avatar) | technical-artist |
| queued | almog | coalition chat avatar (partner `almog`, the poach-a-rebel line; fact #39) | אלמוג כהן: קריקטורה בסגנון הקאסט, פוזה נייטרלית עם טלפון ביד. בלי התפרצויות, בלי שלטים | 96 tall + 24 avatar | game-designer |
| queued | mk-generic | defector event (a sulking MK walks toward Liberman's building) | a generic MK in a suit with a briefcase, sulking; generic face, NOT Illouz or any real MK | 40 tall, 2-frame walk | game-designer |

**2d-artist note on the `suitcase` row:** the in-game Suitcase is now hand-drawn (`art/od-sevev/out/ui/props/suitcase.png`, 24x18 + rim) because a render-down cannot keep the DOHA sticker legible at 24 px. The ChatGPT suitcase is only worth finishing if you want a large one for key art; otherwise drop that row.

**technical-artist note on the money-sources row (size):** the diorama the engine ships puts up to 8 critters
side by side in the front row at an **80-logical-px pitch = 20 art px** (`game/scripts/ui/layout.gd`
`DIORAMA.xs`), and the approved render-downs measure 0.41-0.70 px of body width per px of height (19 cast strips, idle frame 0).
- **At 64-96 tall:** a critter's body is 26-67 px wide, so neighbours overlap up to 3 deep and a front-row critter
  covers the Magician's stage slot (art y 150-216).
- **Proposed:**
  - **Diorama pose:** render the eight sources at **40 art px tall** (rig `H=40`; body 16-28 px wide, so neighbours at
    a 20-px pitch touch rather than bury each other),
    with the 2-frame idle the engine contract asks for (`idleFrameMs`).
  - **Other uses:** the same ref gives the shop icon and the silhouette. The pipeline crops them like
    the avatars (a `head` box in `cast.py`).
  - **Proof first:** the pipeline's `proofs/sprites-contact.png` shows the 40-px read at 1:1 before
    anything is committed.
- **Objects read fine at 40:** the VAT, cigars crate, submarine, bot machine and checkbook. The two
  human payers (taxpayer, high-tech worker) are the risk; if they don't read, give them a hand-drawn
  24x32 chibi (2D Artist) instead.



**game-designer note on the money-sources row (content ids and guardrails):** `design/content.json` uses the ids
`taxpayer, hitech, vat, cigars, submarine, qatari, poison, washington` (the checkbook is `washington`), so the engine's
default keys are `critter_<id>`, `icon_<id>`, `sil_<id>`. Slots and set pieces are in `producers[].slot` / `setPiece`
(40 art px, 2-frame idle, per the TA). Per-source briefs:
- `taxpayer`: משלם המסים: אדם רגיל בחולצת טריקו אפורה, כתפיים שמוטות, מפיל מטבע אחד לתוך כובע; מצויר באהדה, לא כבדיחה. no text
- `hitech`: ההייטקיסט: צעיר/ה בקפוצ'ון עם לפטופ; על המסך אייקון מטוס קטן; מצויר באהדה (הבדיחה על המדיניות, לא על האדם). no text
- `vat`: an object: a grey cash-register machine with a receipt tongue and a small '18%' display (digits only)
- `cigars`: a faceless tuxedo silhouette holding a cigar box and a pink champagne bottle. NEVER a real donor's likeness
- `submarine`: a small cartoon submarine surfacing with coins spilling from the hatch; no flags, no navy markings, no weapons
- `qatari`: two generic aides in dark suits with earpieces and a maroon folder; generic faces, NEVER the real aides
- `poison`: the bot farm: a small shelf rack of phones, each with a blank grey avatar and a tiny heart; no platform logos
- `washington`: a gold chequebook with a thick black marker clipped to it; no seal, no eagle, no flag

### Orchestrator log
- **Done and rendered (19 cast):** bibi, sara, bennett, ben-gvir, smotrich, deri, goldknopf, gafni, levin, regev, gotliv, amsalem, lapid, eisenkot, gantz, liberman, golan, abbas, distel (v2, separate chat).
- **Done in ChatGPT, waiting to download:** karhi (v2), trump, may-golan (v2, waiting for Bar to pick 1 of 3).
- **2026-09-29 · technical-artist:** May Golan done: Bar picked option 1 (`refs/candidates/may-golan-opt1.png` → `refs/may-golan.png`). Rendered with the 3× cast (idle 20 @ 10, a `hop` react 8 @ 14 with `land: 6`, 32/24-px avatars); the game resolves `may-golan` and `maygolan` (the content's partner id) through `sprites.json.aliases`.
- **Generating:** herzog, dubi, taxpayer. Next: hitech, vat, cigars, submarine, qatari, poison, checkbook, aide, photobomber-grey/white, dubi-mic.
