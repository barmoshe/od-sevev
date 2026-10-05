# Instagram promos: three formats

| File | Length | The format | Music |
|---|---|---|---|
| `od-sevev-promo-mivzak.mp4` | 24 s | **"מבזק"**: Channel 61's news. Dubi the parrot anchors (the game's own newsroom voice: he only repeats, doubled), a video wall with real gameplay, a typed lower third with six of the game's ticker lines (3 coalition, 3 opposition), a crawl, and the "cottage index" (the game's cup loses a pixel per story). | the Knesset stage music + Dubi's blips, the news-flash stinger |
| `od-sevev-promo-select.mp4` | 29 s | **"בחר ראש רשימה"**: a fighting-game character select. Eight leaders, two absurd stats and a special move each (Liberman: refusals 100, sitting 0), a random "?" pick, "אתה VS 61", a beat-cut burst of the real game, and "תייגו את הליברמן של הקבוצה". | Glitch Warfare from its drop |
| `od-sevev-promo-fakead.mp4` | 26 s | **"רק 1 מכל 100 מגיע ל־61!"**: a parody of the misleading mobile-game ad. A hand picks; every choice fails (a threat, a flipped pledge, a chair that walks off); elections reset the board to the same thing; "the real game doesn't look like this. it's worse. like reality."; a "play now" button that stamps "בקרוב". | the Balfour stage music, cut out on every fail |

Each cover (`-cover.png`, also frames 0-1) is the frame that tells its joke.

    python3 src/promo.py <scratch with take_<leader>/, take1/, takeL/> mivzak|select|fakead [--stills | --one <sec>]

The footage is the captures of `store/gameplay` (plans in `store/gameplay/plans/`,
`plan-bengvir.json`, `plan-liberman.json`; capture steps in `store/gameplay/README.md`). Copy follows
`creative-pack/voice/review-rubric.md`; the news lines are the game's own ticker
(`creative-pack/voice/copy-deck.md`).

## Shorts: four 7-10 s loops (`src/shorts.py`)

Itay: short and crazy, so people want more and then download. Reels rank on replay and completion
(6-12 s, a clean loop gets watched several times), so each short is one idea that drops back into its
own start, with "לשחק בחינם · הלינק בביו" on screen the whole time.

| File | Length | The idea |
|---|---|---|
| `od-sevev-short-pov.mp4` | 9 s | **POV: אתה המנדט ה־61.** The lock screen at 20:00 on election day; all eight leaders text you, then a flood; "כולם רוצים אותך." |
| `od-sevev-short-stop.mp4` | 7 s | **עצרו את הסרטון!** A leader roulette too fast to read, each with his one true tag; pause to see who you are; it lands on "עוד סבב". |
| `od-sevev-short-speedrun.mp4` | 10 s | **ספידראן ל־61.** The real game at x6-x8 against a clock; world record 49; the Knesset dissolves; the clock resets. |
| `od-sevev-short-tap.mp4` | 8 s | **לחיצה = שקל.** Satisfying taps across the cast up to a billion; Ben Gvir: "ידידי, חסר לי משהו קטן."; back to zero. |

Copy follows the game after the 2026-10-01 copy audit and `creative-pack/voice/character-research-2026-10-01.md`.

    python3 src/shorts.py <scratch> pov|stop|speedrun|tap [--stills | --one <sec>]

## LinkedIn: one looping GIF (`src/linkedin.py`)

LinkedIn animates a GIF only under 5 MB and 400 frames (past either it freezes on frame 0), plays it
silent, and gives 4:5 the most feed. So: 18 s at 12 fps (216 frames), 1080x1350, flat backgrounds, and
frame 0 (`od-sevev-linkedin-cover.png`) is a complete still: "בניתי משחק על הבחירות.", the wordmark,
the eight, "אף אחד לא מגיע ל־61.". Then four real frames (pick, tap, money, coalition), four leaders'
mechanics, "כל עובדה במשחק באה עם מקור. הבדיחות לא.", the hemicycle stuck at 60, and "בקרוב" with
"עקבו באינסטגרם @od.sevev". No link until the game is announced.

| File | Size |
|---|---|
| `od-sevev-linkedin.gif` | 1080x1350, about 4.5 MB |
| `od-sevev-linkedin-small.gif` | 540x675, about 1.5 MB, if LinkedIn freezes the big one |

    python3 src/linkedin.py <scratch> [--stills | --one <sec>]

## "ערוצי התבהלה נגד מכונת הרעל": one evening, three channels (`src/zap.py`)

`od-sevev-promo-zap.mp4`, 49 s, 9:16, on Bar's track `store/gameplay/music/panic-vs-poison.wav`
(122.5 BPM; every zap lands on a bar line, two bars a story). Each camp's insult for the other, worn as
the channel's own style: "ערוצי התבהלה" (the panic channels) is what 14's panel calls 12 and 13, and
"מכונת הרעל" is what the other side calls Netanyahu's spin network, 14 included. The open is a fight
bill (ערוצי התבהלה, נגד, מכונת הרעל); 12 and 13 run a panic meter, 14 a poison meter, and both max out.

The TV zaps (an old set's collapse-to-a-line) 12 → 13 → 14 through the same three game events (the hat, Liberman won't sit, the
Knesset dissolves): 12 panics ("פרשננו: הרגע הכי מסוכן. מאז אתמול.", "14 פרשנים. 15 תרחישי אימה."),
13 investigates nothing ("ארנב. הוא סירב להגיב."), 14 agrees out loud and finds the panic channels
guilty. 14's poison meter is labelled "רעל: 0%" and sits at full. The reveal: "תבהלה? רעל?", the three
channels side by side, one parrot (every anchor is Dubi); then the game's own מכונת הרעל source,
"בקרוב" and the Instagram handle.

Design (after "it looks cheap, confusing, overwhelming"): one colour world per channel (12 red and
white, 13 investigative noir, 14 blue and gold), the channel's number huge and faint on the set, and
per story only the logo, one meter, one screen, Dubi behind the lower third, and the headline. No
ticker, no static, no on-screen remote.

The looks are evoked, never copied: colours, shapes and numbers, no real logos, show names or anchors.
What they rest on (Oct 2026, search results only, page fetches were blocked):
- "ערוצי התבהלה": Yinon Magal's catchphrase on 14 (maariv.co.il/culture/tv/article-1158514); Netanyahu's
  "תבהלה 12" (srugim.co.il/1072723) and "ערוצי התבהלה והתרעלה" (youtube.com/shorts/ykbiZLYH89Y); Amit
  Segal's "כולנו ערוצי תבהלה... תבהלה 14" (ice.co.il/media/news/article/1043629)
- "מכונת הרעל": he.wikipedia.org/wiki/מכונת_הרעל; 14 as its TV arm in the other camp's usage: the7eye.org.il/522467
- almost every Israeli newscast is red now: alefalefalef.co.il/red-news/
- 12: red-white studio, blue behind the rhomboid logo, the screen "squares" for guests: he.wikipedia.org/wiki/חברת_החדשות
- 13: the red double-line logo (2022), the navy set with two big square screens that join: ice.co.il/tv/news/article/839864
- 14: the red-square logo, and Walla calling the rebrand suspiciously similar to 12's ("רגע, זה לא 12?"): b.walla.co.il/item/3729452

    python3 src/zap.py <scratch> [--stills | --one <sec>]

## Five more Reels: five looks, five jobs (`src/reels5.py`)

Bar: short (15 s, 30 s, never past 45), each one its own style, fit for different jobs. One end card for
the whole series (the wordmark, "בקרוב", @od.sevev) so the feed still reads as one account.

| File | Length | The idea | The look | The job |
|---|---|---|---|---|
| `od-sevev-reel-ghost.mp4` | 15 s | **דברים שכדאי לגוסט**: October's sheet-ghost trend. A pixel ghost in sunglasses holds signs (התחייבות חתומה, מכתב פרישה, לחכות לרוטציה, תקציב בזמן, הצעת אחדות); a leader's new pose answers each. The last sign, הבחירות, can't be ghosted: "הן חוזרות." | night purple, the moon | ride a live trend before 27.10 |
| `od-sevev-reel-patch.mp4` | 15 s | **מה יש במשחק**: the leaders' abilities as patch notes (במשחק / באג ידוע), no version numbers (Bar: nothing is released, it's all בקרוב), ending on the known bug: "הבחירות חוזרות. נסגר כ׳לא יתוקן׳." (copy sharpened after Bar's review: every note now ends on a punch, "זה פיצ׳ר", "אישור מוקדם: לא נתמך.") | a dark launcher | show gamers what's in it |
| `od-sevev-reel-loading.mp4` | 15 s | **סופר את הקולות…**: the game's real loading line, tips, characters you've never seen before crossing the screen; 99%, "הכנסת התפזרה.", 0%. Loops. | a 16-bit console | replays |
| `od-sevev-reel-match.mp4` | 30 s | **אחדות**: a dating app. Netanyahu's unity card ("מחפש ממשלת אחדות. רק רציניים.") shown to Golan, Bennett, Liberman, Eisenkot: שמאלה, לא, לא אשב, לא. Then the coalition: Ben Gvir and Smotrich swipe left on each other. "0 התאמות. צריך 61." | a glossy pink app | DM sends |
| `od-sevev-reel-process.mp4` | 30 s | **מהכותרת למכניקה**: four real headlines (design/facts.json), the design note, the ability in the game (Ben Gvir, Smotrich, Golan, Liberman). "העובדות: עם מקור. הבדיחות: שלנו." | newsprint and sticky notes | trust, the making-of |

Research behind it (Oct 2026, search results):
- Mosseri: watch time, sends per reach and likes per reach lead; sends weigh most for non-followers
  (socialmediatoday.com/news/instagram-shares-algorithm-insights-2025/738034/, buffer.com/resources/instagram-algorithms/)
- 7-15 s for completion; the hook has under two seconds (go-viral.app/blog/instagram-reels-algorithm-2026/)
- raw beats polished; for indie games, behind-the-scenes beats trailers (presskit.gg/field-guides/tiktok-indie-game-marketing)
- October's trends: "Things You Should Definitely Ghost", "The Process" (newengen.com/insights/instagram-trends/)
- the loading-screen meme (knowyourmeme.com/memes/when-the-loading-screen-takes-so-long-you-start-seeing-characters-youve-never-seen-before)
- **the political-content limit**: Instagram doesn't recommend political content to non-followers by
  default (whyy.org/npr-story/meta-limit-political-content-instagram-facebook-opt-out). So every Reel
  opens as a game or a joke, and the caption should too; test reach with Trial Reels.

    python3 src/reels5.py <scratch> ghost|patch|loading|match|process [--stills | --one <sec>]

## Five more, five new looks (`src/reels6.py`)

After Bar's review ("some good, some not; better wording, newer ideas"): the patch notes, the loading
tips and one ghost line were rewritten to land a punch, and five new formats:

| File | Length | The idea | The look |
|---|---|---|---|
| `od-sevev-reel-doc.mp4` | 30 s | **עונת הקואליציה**: a nature documentary. Ben Gvir the migrant (out in January, back in March, "כמו הציפורים"), Deri's habitat the corridor, Liberman marks territory with one call, Gantz waits for the rotation since 2020, Netanyahu survives every season. A Latin name for each. "בפרק הבא: עוד סבב." | letterbox, film grain, subtitles |
| `od-sevev-reel-trailer.mp4` | 30 s | **הטריילר**: "בעולם / שבו הבחירות / לא נגמרות", eight leaders, "מנדט אחד חסר. תמיד.", the drop into the real game, three plainly fake reviews ("׳ראיתי את זה כבר חמש פעמים.׳ — כל המדינה"). | black, letterbox, Glitch Warfare |
| `od-sevev-reel-starter.mp4` | 15 s | **ערכת ראש רשימה למתחילים**: the starter-pack meme from the leaders-v3 props (התחייבות חתומה, בעיפרון; ארגז קרטון, לפרישה. ולחזרה.; שולחן עגול, אין ראש. אין סוף.). "לא כלול: 61 מנדטים." | white meme page |
| `od-sevev-reel-family.mp4` | 30 s | **המשפחה**: a family group chat. "זה של השמאל?" "זה של הימין?" "זה צוחק על כולם." "חשוד." "חשוד מאוד." "לראשונה מאז 2019: שמעון ורינה הסכימו." Then Friday dinner: "לא אשב ליד רינה." "גם ליברמן אמר את זה." "12 כיסאות. אף אחד לא מוכן לשבת. כמו בכנסת." | dark-mode chat |
| `od-sevev-reel-search.mp4` | 15 s | **למה בישראל יש...**: autocomplete (בחירות כל שנה, 5 בחירות ב־4 שנים, עוד סבב), then "איך מגיעים ל־61": בלי ליברמן, בלי בן גביר, בלי אף אחד. | a search page |

The family, the reviewers and the searches are invented, and plainly so.

    python3 src/reels6.py <scratch> doc|trailer|starter|family|search [--stills | --one <sec>]

## Safe-zone check (`src/framecheck.py`)

Bar: "some things go out of the frame in all the videos". Every element pasted onto a frame is logged;
the check reports what the frame clips and any text inside Instagram's UI (2026 guides: top 200,
bottom 380, right 120 from about y 1000, where the like / comment / share icons sit). Hebrew is
right-aligned, so the right margin bites first: text now ends at x 950 and centres on x 510.

    python3 src/framecheck.py <scratch> zap zap | reels5 <name> | reels6 <name> | shorts <name> | promo <name> [step]

Sliding cards, walkers crossing the loading screen and the curtain are clipped on purpose.

### The older videos: `src/safefit.py`

The first wave (promo.py's three, shorts.py's four, the gameplay reels and both teasers) was laid out
edge to edge. Rather than redraw thirteen layouts, `fit()` shrinks each finished frame to 84% and
centres it inside the safe area (x 52-959, y 120-1733) as a rounded card over a blurred, dimmed copy of
itself. Every one of those scripts writes `fit(frame(t))`, cover included. In the same pass the shorts'
CTA became "בקרוב · עקבו @od.sevev" (no link) and the mivzak date chip became "בחירות: 27.10", a date
that doesn't go stale like a countdown does.

## "בחרתם בגנץ." (`src/gantz.py`)

`od-sevev-reel-gantz.mp4`, 31 s, 9:16, in the iPhone of the gameplay reels. A teaser like the rest (Bar:
nothing is out yet, so it never says "hypothetical"). In the game Gantz only stands on the picker once,
as a joke; here he gets a round. The screens are the game's own Movie Maker frames (the picker from
take_bennett, a round's first seconds from take_golan) with the leader painted out (the Balfour stage
redrawn from its sprite at its exact offset) and Gantz painted in. "בחרתם בגנץ. בהצלחה." Every tap pays
"+0", the HUD stays at ₪0; his ability, "לחכות", fills a rotation bar to 99% and it's postponed ("מאז
2020", the 2020 rotation that never happened); "שלחתי תזכורת לגבי הרוטציה. סטטוס: נקרא." Then the game's
own decoy: "גנץ לא עבר", בחר שוב, "סוף הסבב.", and the cell is הפתעה again.

    python3 src/gantz.py <scratch with take_bennett/, take_golan/> [--stills | --one <sec>]

## The social kit beyond Reels (`src/social.py`, output in `social/`)

Bar: more marketing content, several types. Research (Oct 2026): carousels are saved about 35% more than
single images, the first slide decides, 7-10 slides (adpicto.com/en/blog/instagram-carousel-best-practices-2026,
krumzi.com/blog/15-instagram-carousel-ideas-that-actually-drive-engagement-in-2026); Stories with native
stickers get about twice the interactions, 3-7 frames (skedsocial.com/blog/ideas-to-boost-interactions-on-instagram-stories-in-2026);
WhatsApp stickers are 512x512 WebP under 100 KB, 3-30 a pack, a 96x96 tray (sticko.app/guides/whatsapp-sticker-size-and-format).

18 WhatsApp stickers, two carousels (the abilities; "מילון עוד סבב"), 5 Story frames with room for
Instagram's own stickers, 4 memes, 5 highlight covers, and a posting plan to 27.10 with captions:
`social/PLAN.md`.

    python3 src/social.py [all|stickers|abilities|dictionary|stories|memes|highlights]

## "עכשיו באוויר": the launch share (`src/launch.py`)

`od-sevev-launch.mp4`, 15 s, 9:16. The first video with the link instead of "בקרוב": six bars of the
real game cut a bar at a time from `store/gameplay/od-sevev-teaser-mix.mp4` (its captions ride along:
the eight, a tap is a shekel, the coalition, "לא אשב", the Knesset dissolves), then the curtain card
with the eight, "עכשיו באוויר", `od-sevev.bar-builds.com` and "לשחק בחינם, בדפדפן. בלי הורדה.".
Glitch Warfare from the montage's bar 6, so the drop lands on the first cut. The cover (also frames
0-1) is the finished end card, so the thumbnail carries the address. Reads the montage mp4, needs no takes.

    python3 src/launch.py [--stills | --one <sec>]

## "הבחירות עברו לענן.": the launch share, SaaS cut (`saas/`)

`od-sevev-launch-saas.mp4`, 15 s, 9:16. Bar didn't like the chiptune and asked for "marketing for an
elegant hi-tech SaaS company". The research (Oct 2026): one idea per shot, empty space, one accent colour,
one sans with tight tracking, word-by-word blur-in type, the real product UI floating in a device with a
soft 3D tilt, KPI chips, the CTA as a button; the music a soft steady pulse, a simple diatonic piano,
warm pads, 105-120 BPM, clean swells at the cuts (moonb.io/blog/product-launch-video,
motion.so/learn/apple-style-product-launch-video, hera.video/blog/kinetic-typography-video-generator-guide,
atomikgrowth.com/blog/best-saas-product-launch-videos-of-2026-with-actionable-tips-real-examples).

The joke is the game sold like a dashboard: "Elections as a Service", "צמיחה מהלחיצה הראשונה" with a
revenue counter, "קואליציה, בזמן אמת" with join toasts, "כמעט 61" on a KPI bar that stalls at 60,
"סנכרון אוטומטי לבחירות הבאות", then the app icon (Dubi), "עכשיו באוויר" and the address as a button
a cursor clicks. The screens in `saas/ui/` are crops of the iPhone montage. Heebo + Inter Tight, the
game's blue as the one accent. Music synthesized in `saas/music.mjs` (112 BPM, seven bars = 15.0 s).

    node store/promo/saas/music.mjs
    node <bar_builds>/jobs/honeybook/gtm-content/engine/motion/render.mjs store/promo/saas/launch.html --audio store/promo/saas/.out/launch.wav

### The English cut with a voiceover (`od-sevev-launch-en.mp4`, 25 s)

Bar, after the 15 s SaaS cut: the whole video in English, an English voiceover with a brisk marketing read,
25 s so the picture moves slower and reads clearer, and "Link in the first comment" instead of the address.
`saas/launch.html` is now this cut (the 15 s Hebrew one stays as `od-sevev-launch-saas.mp4`, at 16b8cc6).

- Voice: Kokoro-82M (Apache-2.0, local, `af_heart`, 1.12x), `saas/vo.py`; "Od Sevev" is spoken from
  written phonemes. Every line was checked by transcribing it back with local Whisper.
- Music: `saas/music.mjs` at 115.2 BPM, twelve bars = 25.0 s; scenes start on beats 0, 8, 15, 24, 29, 36
  (sized to the lines), the end card on bar 9. `saas/mix.py` lays each line on its scene and ducks the bed 8 dB.

    ~/.cache/kokoro-tts/venv/bin/python store/promo/saas/vo.py
    node store/promo/saas/music.mjs
    ~/.cache/kokoro-tts/venv/bin/python store/promo/saas/mix.py
    node <bar_builds>/jobs/honeybook/gtm-content/engine/motion/render.mjs store/promo/saas/launch.html --audio store/promo/saas/.out/launch.wav

### LinkedIn (`od-sevev-launch-linkedin.mp4` + `.srt`, 4:5, 25 s)

The English cut reflowed (not cropped) to 1080x1350: `launch.html#li` swaps the layout, `saas/render.mjs`
renders at any size. 4:5 is LinkedIn's feed default and fills the most of it on desktop and mobile; about
80% of LinkedIn video autoplays muted, so `od-sevev-launch-linkedin.srt` carries the voiceover as captions
(upload it with the video). Sources (Oct 2026): contentin.io/blog/linkedin-post-specs,
blog.sendspark.com/linkedin-video-specs, postfa.st/sizes/linkedin/video.

    node store/promo/saas/render.mjs store/promo/saas/launch.html --size 1080x1350 --hash li --name li --audio store/promo/saas/.out/launch.wav

## Three more, made in HyperFrames (`hyperframes/`)

`od-sevev-reel-crash.mp4` (15 s, "הקואליציה לא מגיבה", an old desktop that hangs, waits for the rotation
and blue-screens), `od-sevev-reel-calendar.mp4` (13 s, "לוח השנה", every election since 2019 torn off a
calendar) and `od-sevev-reel-howto.mp4` (13.8 s, "איך משחקים בעוד סבב", five steps, "זה כל המשחק.").
Same lettering and end card as the rest; built as HTML pages rendered by HyperFrames. Crash and calendar
are blackout-safe, howto is not. Details and the build steps: `hyperframes/README.md`.

## TikTok: three posts (`src/tiktok.py`, output in `tiktok/`)

Bar: three more posts for TikTok, video or images, all new (no recorded footage). Laid out for
TikTok's own safe area (For You bar ~150 px on top, caption ~450 px at the bottom, the icon column
~130 px on the right), so nothing is shrunk with safefit. The game is live, so each one ends on the
address (a TikTok link in bio needs 1,000 followers).

| Post | What | Blackout 23-27.10 |
|---|---|---|
| `od-sevev-tiktok-guess.mp4` (25 s) | **נחשו מי זה**: four leaders as black silhouettes of their ability pose, the clue in the game's own ability copy (אני פורש, החלקה, המסמך, לחתום ולהפוך), three seconds, the reveal; the other four stay dark, "כמה ניחשתם? כתבו בתגובות." | safe |
| `od-sevev-tiktok-night.mp4` (16 s) | **עוד סבב אחד ואני הולך לישון.**: the game on a phone in a dark bedroom, 23:00 → 01:17 → 03:42 → 05:58, a new leader each round, the shekels growing, moon to dawn, the 07:00 alarm: "קוראים לו עוד סבב. לא סתם." The phone screen is drawn from the game's art (stage, tap strips, HUD). | safe (no seats) |
| `truth/01-12.png` (photo mode) | **אמת או המצאה?**: five things that sound made up, each answered on the next slide with its source from `design/facts.json` (the 800 million voted by mistake, Gafni's five days, the pistachio budget, the disposables tax, five elections in under four years). All five are true: "הבדיחות: שלנו." | safe |

Captions (first line is the hook; game and comedy hashtags only):
- guess: "3 שניות לכל אחד. כמה ניחשתם? 👇 #עודסבב #משחק #פיקסלארט #אתגר #indiegame"
- night: "עוד סבב אחד ואני הולך לישון. (לא הלכתי) #עודסבב #גיימינג #פיקסלארט #הומור #indiegame"
- truth: "אמת או המצאה? החליקו לפני שאתם עונים. #עודסבב #אמתאוהמצאה #סאטירה #הומור"

    python3 store/promo/src/tiktok.py guess|night|truth [--stills | --one <sec>]
