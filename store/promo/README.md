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
