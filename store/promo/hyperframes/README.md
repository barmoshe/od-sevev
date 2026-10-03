# Three Reels made in HyperFrames

Three 9:16 Reels in three new looks, made as HTML pages rendered by
[HyperFrames](https://github.com/heygen-com/hyperframes) `0.8.114` (pinned) instead of the PIL scripts
in `../src/`. Every Hebrew line is still the game's Sevev 9 lettering (pre-rendered by
`src/assets.py` through `teaser.text`, so the browser never shapes Hebrew), and every one ends on the
series' shared end card (the last 2.2 s of `od-sevev-reel-ghost.mp4`, at 70% volume).

| File | Length | The idea | The look | Blackout 23-27.10 |
|---|---|---|---|---|
| `od-sevev-reel-crash.mp4` | 15 s | **הקואליציה לא מגיבה**: the game runs in an old desktop window (Bennett, Deri and Golan taps, then the picker), hangs ("עוד סבב · לא מגיב"); a dialog offers [לחכות לרוטציה] [לפזר את הכנסת]; waiting fills a bar that runs backwards to "הרוטציה נדחתה." over phone hold music; a blue screen ("המדינה נתקלה בבעיה וצריכה לאתחל. … ואז יוצאים לבחירות." · קוד עצירה: עוד_סבב); a reboot into a new round. | a 90s desktop in the game's blues | **safe** (no seat numbers; the % is a progress bar) |
| `od-sevev-reel-calendar.mp4` | 13 s | **לוח השנה**: a tear-off calendar through every election since 2019, each page stamped: 9.4.2019 בחירות. · 17.9.2019 שוב. · 2.3.2020 ושוב. · 23.3.2021 עוד פעם. · 1.11.2022 אחרונות. בטוח. · 27.10.2026, the wordmark, "הבחירות שלא נגמרות". Each page names the Knesset it elected (21 to 26). | paper on a wall, rubber stamps | **safe** (dates and Knesset numbers, no seats) |
| `od-sevev-reel-howto.mp4` | 13.8 s | **איך משחקים בעוד סבב**: five steps on clean footage: בוחרים ראש רשימה. / לוחצים. / קונים מקורות הכנסה. / הולכים לבחירות. / ומתחילים מחדש. "זה כל המשחק." Bennett's round for the pick, taps and buys; Golan's election card ("עוד איחוד"). | the game framed in gold, step chips | **hold** (the seat bar, "24/61", shows behind the card) |

Each cover (`-cover.png`) is the frame that tells its joke: the hang dialog, the "אחרונות. בטוח." page,
and "זה כל המשחק."

The calendar's dates are public record (Knesset elections of 9.4.2019, 17.9.2019, 2.3.2020, 23.3.2021,
1.11.2022, electing the 21st to 25th Knessets; 27.10.2026 is the game's date for the 26th). The crash
names no one; the tutorial's words are the game's own loop. Copy checked against
`creative-pack/voice/review-rubric.md`: no candidate in the first frame (a game window, a calendar page,
a game title), nothing about who to vote for, no red-line topics.

## How it is made

1. **Footage** (only crash and howto): Movie Maker takes of `store/gameplay/plans/plan-{bennett,deri,golan}.json`,
   as in `store/gameplay/README.md` (pass the plan as an absolute path, or the driver loads 0 steps):
   Golan 840 frames (it includes the forced election), Bennett and Deri 600 each. About 12 minutes for
   the three in parallel on the container.
2. **Assets:** `python3 src/assets.py <scratch with take_bennett/, take_deri/, take_golan/> crash|calendar|howto|all`
   writes `<reel>/assets/gen/` (git-ignored): the lettering PNGs, the footage clips (crops of the
   1080x2338 frames), the soundtrack (the takes' own audio, the game's `.res` sounds via
   `teaser.load_wav`, a few synthesized ones) and the end card. Needs Pillow and numpy.
3. **Render:** in each reel folder, `npm run check` (lint, runtime, layout, contrast), then
   `npm run render` → `out/od-sevev-reel-<name>.mp4` (about 30-45 s each). `npm run snapshot -- --at 1,5`
   for key frames.

Timings live in two places that must agree: the sound cues in `src/assets.py` and the timeline in each
`index.html` (stamps and tears in calendar, step boundaries in howto, the dialog beats in crash).

Never use `hyperframes publish` or `cloud` here: both upload to HeyGen.
