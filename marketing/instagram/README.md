# Instagram posts

Single marketing images for the game, built from the game's own art (the `flyer` skill pipeline).

| Post | Size | Source |
|---|---|---|
| `mordechai-government.png`: "האם מרדכי דוד יצליח להקים ממשלה? שחקו עכשיו" | 1080×1350 (feed) | `mordechai-government.html` |

- `assets/` holds the frames cut from the game's sprites (`game/assets/sprites/cast/*_idle.png` frame 0,
  `mordechai-david_block.png` frame 0), the Knesset stage and the logo.
- Render: `node render.mjs mordechai-government.html 1080x1350 1` (Playwright; needs network for Heebo
  and prints "Heebo ok").
- The URL printed is the live host, `od-sevev.bar-builds.com`.
- His name sits outside the game here: `design/redlines.json` scopes it to his in-game event, and the legal
  read is on Bar's pre-launch list. Bar asked for this post (2026-10-04).
