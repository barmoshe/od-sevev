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
