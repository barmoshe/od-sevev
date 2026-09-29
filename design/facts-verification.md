# Fact and quote verification before ship

**Owner:** Game Designer · **Date:** 2026-09-29 · **Data:** `design/facts.json` (fields `url`, `url2`, `moreUrls`,
`verification`, `verifiedAt`, `verifiedEn`, `verifiedHe`, `heStatus`, `gameRendering`, `verificationNote`)

**Scope:** HANDOFF "Before ship → Sources": the 13 shipping facts that had no `url`, including the 4 quotes whose
Hebrew had to be checked (Trump, Gotliv, the brawl, Illouz).

## Method, and its limit
- **How facts were checked:** by web search, and only against reputable outlets:
  - Israeli outlets: ToI, JPost, Haaretz / TheMarker, Ynet, Walla, Kan, N12, Maariv, INN;
  - international outlets and primary documents: the UCSB Presidency Project transcript, the Knesset speech PDF.
  - Wikipedia is used only as a pointer.
- **The limit:** the sandbox's egress proxy blocks page fetches for every host. So each finding rests on the search
  results only: the outlet's headline, the URL and the indexed article text.
- **Headline quotes:** where a quote appears in a headline (Ynet's Gotliv headline, N12's Trump headline), the
  wording is the outlet's own.
- **Wording that isn't in a headline** is marked `unverified` in `facts.json`, and it stays unverified until someone
  reads the page.
- **Before ship,** a human should open each `url` once. It takes about 10 minutes and turns "found in search" into
  "read".
- **No URL or quote was invented.** Every link below was returned by search for that exact story.

## Result
**13 facts checked: 9 verified, 4 corrected, 0 unverified.**
- **Corrected** means the claim holds but a detail in `facts.json` changed (date, attribution or precision). Only
  the fact sheet changed; no player-facing claim was wrong.
- **Quotes (Hebrew wording):** 2 are verified (Trump as N12 reported it, Gotliv) and 2 are unverified (the brawl's
  Netanyahu line, Illouz).
  - Both unverified quotes are verified **in English** (JPost / INN).
  - The game already renders both as **reported speech without quote marks**, so no copy claims the exact Hebrew
    wording.
- **Lint:** `node design/sim/content-lint.mjs`: 0 errors, and the 13 "URL needed before ship" warnings are gone.

### Facts
| # | id | Claim | Status | Sources | Notes |
|---|---|---|---|---|---|
| 12 | `pardon-shelved` | Herzog shelved the pardon request and pushed for a plea deal, 26 Apr 2026 | verified | [ToI](https://www.timesofisrael.com/herzog-pushes-for-new-plea-deal-talks-says-he-wont-consider-netanyahu-pardon-request-yet/) · [Ynet](https://www.ynet.co.il/news/article/skmasujt11g) | "At least for now": frozen, not rejected. The stamp "מומלץ לשקול הסדר טיעון" fits. |
| 15 | `trump-cigars-quote` | Trump in the Knesset, 13 Oct 2025: "cigars and champagne, who the hell cares" | verified | [ToI](https://www.timesofisrael.com/trump-urges-herzog-to-pardon-netanyahu-who-cares-about-cigars-and-champagne/) · [UCSB transcript](https://www.presidency.ucsb.edu/documents/remarks-the-knesset-jerusalem-israel-0) · [Knesset PDF](https://m.knesset.gov.il/EN/activity/Documents/SpeechPdf/trump.pdf) · [N12](https://www.mako.co.il/breaking_news-2025/m10_w03/shorts-8e39f6fdc8dd991027.htm) | The shortened quote in `text` is now the full wording. |
| 34 | `gotliv` | Gotliv to Otzma, No. 2; the "19 seats / Shin Bet detention" remark; "targeted assassination" | **corrected** | [Ynet](https://www.ynet.co.il/news/article/rk11xnoeogg) · [Walla](https://news.walla.co.il/item/3864616) · [Kan](https://www.kan.org.il/content/kan-news/politic/1095987/) · [ToI](https://www.timesofisrael.com/likud-arranges-to-have-firebrand-mk-tally-gotliv-run-with-ben-gvirs-otzma-yehudit/) · [JPost](https://www.jpost.com/israel-election-2026/article-907188) · [Haaretz](https://www.haaretz.co.il/news/elections/2026-09-03/ty-article/.premium/000001a0-6836-d1e9-ade0-f9f78e0f0000) | She was **not declared a defector**: she runs on Otzma's list by Likud arrangement (3 Sep; No. 2 on 4 Sep). Primary 12th, pushed to 20th by reserved slots. |
| 35 | `brawl` | Cabinet brawl: Amsalem "don't call me chutzpan"; Netanyahu "go outside and continue arguing there" | **corrected** | [JPost](https://www.jpost.com/israel-news/politics-and-diplomacy/article-883783) · [Ynet](https://www.ynet.co.il/news/article/bk5h1189sbl) · [Walla](https://news.walla.co.il/item/3809823) · [Kipa](https://www.kipa.co.il/%D7%97%D7%93%D7%A9%D7%95%D7%AA/1218212-0/) | Date **18 Jan 2026**, not 19: JPost says "on Sunday" and posted 19 Jan 02:12 UTC. The Hebrew wording of Netanyahu's line was not found (see quotes). |
| 36 | `karhi-remote` | Karhi threatened Kan over "1948" unseen (Sep 2025); media law 53-48 (Jul 2026), NIS 25M/yr out of Kan | verified | [ToI](https://www.timesofisrael.com/karhi-threatens-to-cut-public-broadcasters-funding-over-documentary-about-1948-war/) · [JPost](https://www.jpost.com/israel-news/politics-and-diplomacy/article-902758) · [Haaretz](https://www.haaretz.com/israel-news/culture/2025-09-04/ty-article/.premium/israeli-minister-threatens-to-cut-public-broadcasters-funding-over-controversial-film/00000199-154b-da27-a7fd-9d7bff090000) · [ToI, court freeze](https://www.timesofisrael.com/high-court-freezes-key-parts-of-governments-controversial-media-overhaul-law/) | Passed 16 Jul 2026. The regulator's NIS 25M is to be deducted from Kan (JPost); Karhi says it comes from Idan+ money. **The High Court froze key provisions** and the AG wants the whole law frozen. |
| 37 | `may-golan` | Police recommended charges over fictitious ministry jobs | verified | [ToI](https://www.timesofisrael.com/police-recommend-minister-golan-stand-trial-over-job-fixing-allegations/) · [Haaretz](https://www.haaretz.co.il/news/law/2026-06-10/ty-article/.premium/0000019e-b126-d7a4-a9bf-f5ee18c00000) | 10 Jun 2026. Suspected of bribery, fraud and breach of trust; she denies it. Prosecutors decide. The label "לפי המלצת המשטרה" is correct. |
| 38 | `distel-mute` | Distel-Atbaryan barred the legal advisers from speaking; they walked out | verified | [ToI](https://www.timesofisrael.com/liveblog_entry/legal-advisers-walk-out-of-knesset-media-bill-panel-after-chair-bars-them-from-speaking/) · [Ynet](https://www.ynet.co.il/news/article/b146o7qh11x) · [TheMarker](https://www.themarker.com/news/themedia/2026-04-13/ty-article/.premium/0000019d-8618-d8a8-afdd-8e3b3a3e0000) | 13 Apr 2026, in the broadcasting-bill committee she chaired. |
| 39 | `almog-cohen` | Removed from Otzma's WhatsApp groups; later 8th in the Likud primary | verified | [ToI (WhatsApp)](https://www.timesofisrael.com/liveblog_entry/otzma-yehudit-removed-cohen-from-whatsapp-groups-after-he-defied-party-line-on-votes-report/) · [ToI (No. 8)](https://www.timesofisrael.com/liveblog_entry/former-otzma-yehudit-mk-almog-cohen-thanks-netanyahu-likud-voters-after-snagging-no-8-in-primary/) | The removal was Jan 2025; the primary Aug 2026 (14th on the final slate). |
| 40 | `illouz` | Illouz: "Likud has become a subcontractor for Deri and Goldknopf" | verified (English) | [INN](https://www.israelnationalnews.com/news/431309) · [JPost](https://www.jpost.com/israel-news/politics-and-diplomacy/article-904701) · [Haaretz](https://www.haaretz.co.il/news/elections/2026-08-05/ty-article/.premium/0000019f-d04d-d970-adff-dc7f5cfa0000) | Said on joining Yisrael Beytenu, Aug 2026. The Hebrew is unverified (see quotes). |
| 42 | `channel14-fee` | Within 24 h of a Netanyahu interview, the ministry advanced a fee break for Channel 14 | verified | [Haaretz](https://www.haaretz.com/israel-news/israel-politics/2026-07-02/ty-article/.premium/israeli-govt-seeks-benefits-for-channel-14-after-flattering-netanyahu-interview/0000019f-1e98-d257-adbf-5ede85270000) · [TheMarker](https://www.themarker.com/news/themedia/2026-07-01/ty-article/.premium/0000019f-1e01-d9aa-afbf-5f1d7bcf0000) | 1 Jul 2026, after "The Patriots". The fee is a licence fee (אגרה), so it matches. |
| 43 | `bibist-video` | "אני ביביסט" video: tens of millions of views, ~0.01% engagement | **corrected** | [ToI](https://www.timesofisrael.com/netanyahu-posts-skit-of-young-man-coming-out-as-his-supporter-to-his-parents-horror/) · [Walla](https://tech.walla.co.il/item/3840262) · [Maariv](https://www.maariv.co.il/news/politics/article-1324759) | It was **not a Likud campaign video**: content creators made it (Solomon, Shamai HaCohen) and Netanyahu posted it on 21 May 2026. The 0.01% is **one expert's estimate** quoted by Walla. |
| 44 | `cottage-index` | The Cottage Index (cottage price as a cost-of-living gauge) | **corrected** | [Walla Finance](https://finance.walla.co.il/item/3799723) · [Wikipedia (pointer)](https://en.wikipedia.org/wiki/Cottage_cheese_boycott) | The round-2 "Walla, 1 Jun 2026" item wasn't found, so it was replaced by Walla's late-2025 piece. The game uses the concept only. |
| 46 | `testimony-cancelled` | Testimony cancelled Apr and May 2026 for "security consultations" | verified | [Haaretz, 4 May](https://www.haaretz.co.il/news/law/netanyahutrial/2026-05-04/ty-article/.premium/0000019d-f128-de36-abfd-fd2a33f10000) · [Haaretz, 27 Apr](https://www.haaretz.co.il/news/law/netanyahutrial/2026-04-27/ty-article/0000019d-cac0-d95a-afbd-ebcae3bf0000) · [ToI](https://www.timesofisrael.com/netanyahu-testimony-set-to-resume-after-monthslong-break-canceled-at-last-minute/) | 27 Apr cited a "לו״ז ביטחוני"; 4 May "התייעצויות ביטחוניות". The game never names the underlying events; keep it that way. |

### The four quotes
| id | As said / reported | Exact Hebrew as reported | Hebrew status | Game rendering |
|---|---|---|---|---|
| `trump-cigars-quote` | "And cigars and champagne, who the hell cares about that?" (transcript; ToI's report has "…about this?") | "סיגרים ושמפניות? למי אכפת?" (N12 headline) | verified. Said in English, so no Hebrew original exists. | **Paraphrase**, reported speech: `w02` "טראמפ שאל למי לעזאזל אכפת מסיגרים ושמפניה"; `s15` unnamed. OK as is. |
| `gotliv` | "If, God forbid, Likud gets 19 seats, I'll find myself in Shin Bet detention facilities" (ToI) | "אם הליכוד יקבל 19 מנדטים - אמצא את עצמי במתקני כליאה של שב״כ" (Ynet headline); her term: "סיכול ממוקד" (Walla, Ynet) | verified | Card: **paraphrase** in reported speech, plus the **verbatim** term "סיכול ממוקד" in quote marks, which matches. |
| `brawl` | Amsalem: "You're not speaking politely, don't call me chutzpan." Netanyahu: "…Both of you go outside. Leadership is restraint. If you are not leaders, go outside and continue arguing there." (JPost translation) | Not found. Headlines give fragments only: Ynet "לא מוכן שתצרחו כאן", Kipa "צאו החוצה", Walla "צאו מכאן", Kikar "חצוף, קמת עצבני" | **unverified** | `script[0]`: reported speech, "חוצפן" (backed by JPost's "chutzpan"); OK. `script[6]`: the Magician's bubble is a **back-translation** of JPost's English, in the third person. See the objection. Button "צאו החוצה" matches the Kipa headline and JPost. |
| `illouz` | "Likud has become a subcontractor for Deri and Goldknopf" (INN, JPost) | Not confirmed. One search summary gives "קבלן ביצוע של דרעי וגולדקנופף", source page not identified. | **unverified** | **Paraphrase**, reported speech, no quote marks: "לפי דן אילוז, הליכוד הפך לקבלן משנה של דרעי וגולדקנופף." Acceptable. Never add quote marks. |

## Game strings that use these facts
Found by fact id in `design/content.json`. `ux/ui-strings.json` holds no fact ids; its related keys are
`CHAT_SYS_BRAWL`, `CHAT_BRAWL_BTN`, `CHAT_BRAWL_AFTER`, `CHAT_SYS_TRANSFER_F`, `CHAT_SYS_MUTED`,
`CHAT_SYS_REMOVED_M` and `HUD_COTTAGE_TIP`, and none of them makes a factual claim.

| Fact | Strings (content.json path) |
|---|---|
| `pardon-shelved` | `court.pardon.copy.stamps[6]` ("מומלץ לשקול הסדר טיעון."), `ambientHeadlinesV2.list.c03` |
| `trump-cigars-quote` | `ambientHeadlinesV2.list.w02`, `upgrades.s15.flavor` |
| `gotliv` | `partners.gotliv.lines.*` (invented voice), `partners.gotliv.copy.card.text`, `…transferWindow.script[0]` → UX `CHAT_SYS_TRANSFER_F`, `…transferWindow.ticker` |
| `brawl` | `events.brawl.copy.script[0]`, `script[6]`, button "צאו החוצה", `achievements.a_get_out` |
| `karhi-remote` | `upgrades.s08` (flavor + 5 levels), `partners.karhi.lines.demand` ("25 מיליון בשנה עוברים מ"כאן" ל"שם""), `lines.thanks`, `copy.review` |
| `may-golan` | `partners.maygolan.copy.cardLabel`, `partners.maygolan.lines.*`, `ambientHeadlinesV2.listPolitics.m15` |
| `distel-mute` | `partners.distel.lines.*`, `copy.mutedWho` → UX `CHAT_SYS_MUTED` |
| `almog-cohen` | `partners.almog.lines.*`, `copy.poachTicker`, `copy.originSystem` → UX `CHAT_SYS_REMOVED_*` |
| `illouz` | `events.defector.copy.ticker` |
| `channel14-fee` | `upgrades.s13`, `ambientHeadlinesV2.listPolitics.m21` |
| `bibist-video` | `upgrades.s14` |
| `cottage-index` | `headlines.h_cottage_0` … `h_cottage_11`, `achievements.a_cottage`, UX `HUD_COTTAGE_TIP` |
| `testimony-cancelled` | `court.postpone.copy.excuses[*]`, `ambientHeadlinesV2.list.c04`, `story.beats[2][2]` |

## Copy changes
### Made
**In-game strings: none.** No shipping string presents any of these four quotes as a verbatim Hebrew quote with wrong
wording:
- "סיכול ממוקד" is verbatim and correct.
- Everything else is reported speech.

`design/content.json` is untouched, so `tools/sync_data.sh` was not needed.

**On the public About page:** `tools/lib/render_shell.py` prints every fact's `text` as a list item with a "למקור"
link, so the `facts.json` edits show up there:
- **URLs:** the 13 facts now get a "למקור" link.
- **`text` rewritten to match the record:**
  - `trump-cigars-quote`: the full quote;
  - `gotliv`: not formally a defector, 12th → 20th;
  - `brawl`: 18 Jan, and the full JPost wording;
  - `bibist-video`: a creators' skit that Netanyahu posted, and the 0.01% is an expert's estimate;
  - `cottage-index`.
- **Gotliv:** the sentence "Never mention the covert officer." moved out of `text` into `_guardrail`. On the public
  page it pointed readers at the very thing the guardrail keeps out.

**Found in passing (pre-existing, outside this slice):**
- Other `text` fields carry internal notes that also render publicly, for example "NOT USED at launch." (47),
  "GAP: no dated source; not used." (51) and "Bench only." (48, 49).
- The About page also lists the notUsed facts.
- **Suggested fix:** in `render_shell.py`, skip facts with `notUsed`, and move each production note into a `_note`
  field.

### Recommended (owner: Game Designer, next content pass; each needs `tools/sync_data.sh` + the lint)
1. **`events.brawl.copy.script[6]`: must change before ship** (see the objection). The Hebrew wording is unverified,
   and the line is a back-translation in the wrong person.
   - Change "אם הם לא מנהיגים, שייצאו החוצה וימשיכו להתווכח שם." to **"צאו החוצה ותמשיכו להתווכח שם."**
   - The new line is second person, addressed to the two ministers.
   - "צאו החוצה" is attested in Hebrew (Kipa headline), and the rest follows JPost's "go outside and continue arguing
     there".
   - Keep `reportedSpeech: true` and `src: ["brawl"]`, and use no quote marks.
2. **`partners.gotliv.copy.card.text`: optional, tighten to the record.**
   - Change "היא צופה שתמצא את עצמה במתקן כליאה של השב״כ" to "תמצא את עצמה במתקני כליאה של שב״כ", which matches
     Ynet's wording.
   - Or go verbatim: `גוטליב: "אם הליכוד יקבל 19 מנדטים - אמצא את עצמי במתקני כליאה של שב״כ".`
   - Either way, run the lint (glyphs, the 23.10 blackout, `poll_like`).
3. **`events.defector.copy.ticker` (Illouz): no change.** Keep it as reported speech with no quote marks, and keep
   `verifyHebrew: true` until someone reads the Hebrew source (Ynet `rj6nxxzifg` is the likely page).
4. **`partners.karhi.lines.demand`: no change required.**
   - It is a chat bubble, the character's invented voice (deck §E), and the law's text does move the money.
   - Note that the High Court froze key provisions, so "עוברים" is the law's promise, not a done transfer. If Bar wants
     it airtight: "25 מיליון בשנה אמורים לעבור מ"כאן" ל"שם"".
5. **Metadata to flip in the same pass:** drop `verifyHebrew: true` from `partners.gotliv.copy.card`, now verified.
   Keep it on the brawl `script[6]` and the Illouz ticker.

### Docs to sync (not game copy)
- **`creative-pack/references.md`:** rows 12, 15, 34-40, 42-44 and 46 still read "URL needed". Point them at
  `facts.json`.
- **Row 43 and `brief-round2.md`:** they call "אני ביביסט" a "campaign video"; it was a creators' skit that Netanyahu
  posted.
- **Row 35:** its date should read 18 Jan.
- **Done (2026-09-29, review R2):** all three are synced. Every launch fact now carries a public Hebrew
  `aboutHe` line and a boolean `notUsed` (reason in `notUsedWhy`), so the About page no longer needs `text`;
  `content-lint.mjs` enforces both.

## Objection
```yaml
objection:
  skill_or_agent: game-designer (source verification)
  against_artifact: content/events.brawl.copy.script[6] (the Magician's "go outside" bubble)
  reason: |
    The brief's red line says "No invented facts presented as real; real quotes are exact". The line is flagged
    src: brawl + reportedSpeech, so it presents itself as what Netanyahu said. But the only full record of the
    sentence is JPost's English translation ("If you are not leaders, go outside and continue arguing there").
    Search found no Hebrew outlet carrying that sentence. Hebrew headlines give other fragments ("לא מוכן
    שתצרחו כאן", "צאו מכאן", "צאו החוצה"), so the Hebrew original is unverified (facts.json brawl.heStatus).
    The current copy "אם הם לא מנהיגים, שייצאו החוצה וימשיכו להתווכח שם." is a back-translation and adds a
    claim: it has him call them non-leaders in the third person, which no Hebrew source shows. It also breaks the
    chat convention, since it is the Magician's own bubble addressed to the two ministers.
  proposed_alternative: |
    Replace it with "צאו החוצה ותמשיכו להתווכח שם." It is second person, and every word is backed by the record:
    "צאו החוצה" by the Kipa headline and JPost's "go outside", and "continue arguing there" by JPost. Keep
    reportedSpeech: true and src: ["brawl"], with no quote marks. The button "צאו החוצה" already matches. If Bar
    prefers the "leaders" beat, attribute it: add a sys line 'לפי הדיווחים, נתניהו אמר להם שמנהיגות היא איפוק'
    (reported speech, src brawl), and keep the bubble to "צאו החוצה.".
```

## Out of scope (still without a URL, all shipping disabled)
These six facts ship disabled or unused, so they don't block launch. Each needs a URL before its feature is enabled:
- `nameless-party` (41)
- `emigration-2025` (45)
- `eisenkot-quote` (47; drop recommended)
- `kaia` (48)
- `travel-expenses` (49)
- `electricity-water` (51, GAP)

## Leader select, wave 1 (2026-09-29, `design/leader-select-spec.md`)

The same method and limit as above: web search only, reputable outlets, pages not opened. There are 12 new facts. Each is `launchWith: "leaderSelect"` and `notUsed: true` until the picker ships. The lint still checks their `aboutHe` as if they were live.

| id | Claim | Label | Sources | Notes |
|---|---|---|---|---|
| `beyachad-list` | "ביחד": Bennett No. 1, Lapid No. 2, 4 of every 7 slots to Bennett (end Apr 2026) | F | [Ynet](https://www.ynet.co.il/news/elections2026/article/sk6esqq00gx) · [Kan](https://www.kan.org.il/content/kan-news/politic/1096328/) · Srugim · IDI · JPost | This is why Lapid is not a pick (spec D2). |
| `rotation-2022` | Lapid succeeded Bennett on 1 Jul 2022 under the rotation deal | F | [Axios](https://www.axios.com/2022/06/20/israel-bennett-lapid-dissolve-knesset-elections) · Britannica | |
| `bennett-raanana` | Staying in Ra'anana cost the state NIS 12-15M (TV report) | **A** | [ToI](https://www.timesofisrael.com/decision-by-bennett-to-keep-living-at-home-could-cost-state-millions-tv/) · Haaretz | The game always says "לפי הדיווח". The reason his office gave is never used. |
| `bennett-cyota` | Co-founded Cyota, sold to RSA in 2005 for $145M | F | [Globes](https://en.globes.co.il/en/article-1000036328) · Haaretz | |
| `raam-2021` | Ra'am was the first Arab party in an Israeli coalition (Jun 2021) | F | [ToI](https://www.timesofisrael.com/arab-israeli-raam-party-makes-history-by-joining-bennett-lapid-coalition/) · Time | Coalition arithmetic only. |
| `bengvir-ministry-rename` | Public Security → National Security; rebrand NIS 2-3M (Jan 2023) | F | [ToI](https://www.timesofisrael.com/rebranding-of-police-ministry-to-cost-between-nis-2-3-million/) · Ynet | |
| `otzma-vote-boycott` | Otzma walked out of votes for more Negev and Galilee money (May 2023) | F | [ToI](https://www.timesofisrael.com/in-latest-coalition-upheaval-otzma-yehudit-boycotts-knesset-votes-over-budget-dispute/) · INN | Never the earlier boycott that month; its trigger is a red line. |
| `otzma-budget-2025` | Otzma voted against the 2025 budget bill, which passed anyway (Dec 2024) | F | [ToI](https://www.timesofisrael.com/otzma-yehudit-votes-against-budget-as-coalition-splits-over-bid-to-fire-ag/) | |
| `liberman-finance-taxes` | Disposable-tableware tax (2021) and sugary-drinks tax (2022); both cancelled by Smotrich in 2023 | F | [ToI](https://www.timesofisrael.com/in-1st-move-as-minister-smotrich-orders-taxes-on-plasticware-sugary-drinks-nixed/) · ToI · JPost | Never who demanded the repeal. |
| `liberman-2019` | Refused to join in May 2019 → the Knesset dissolved → repeat election 17 Sep 2019 | F | [ToI](https://www.timesofisrael.com/infuriating-but-not-finishing-netanyahu-liberman-drags-israel-back-to-the-polls/) | Never the bill he cited (deliberatelyOut). |
| `liberman-wont-sit` | May 2026: even if the world turns over, he won't sit with Netanyahu | Q | [INN](https://www.inn.co.il/news/696237) · Srugim · JFeed | **Hebrew unverified:** INN and Srugim headline two different wordings, so the line is reported speech only. |
| `liberman-no-minority` | Aug 2026: no minority government | F | [Israel Hayom](https://www.israelhayom.co.il/news/politics/article/21214874) | |

**Deliberately not used:**
- Ben Gvir's quit and return in 2025 (its reason is a red line).
- The police-emblem directive (it is an emblem).
- The Sep 2026 bids to disqualify Otzma and the Democrats.
- Bennett's reason for staying home (it names his family).
