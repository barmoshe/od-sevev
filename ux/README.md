# ux/ — "עוד סבב" (UX Designer's slice)

| File | What it is | Consumer |
|---|---|---|
| `ui-strings.json` | Every UI chrome string, Hebrew, logical order, bidi isolates included. Canonical for code (`tools/sync_data.sh` copies it to `game/data/`). | Game Developer |
| `string-budgets.json` | Per-key box, surface, scale, line budget and worst-case pixel width, for the build-time pixel-width lint. | Game Developer (lint) |
| `tools/gen_strings.py` | The single source for both JSON files; self-lints every canvas string with the real `Sevev 5x9` metrics. **Edit strings here, then run `python3 ux/tools/gen_strings.py`.** | UX Designer |
| `rtl-map.md` | Screen-by-screen RTL mapping of the fork's views: rects, fill and crawl directions, icon sides, tab order, safe areas, thumb zone, touch targets. | Game Developer, 2D Artist, Animator |
| `ftue.md` | FTUE prompt triggers as predicates over the fork's `GameState`, with the new fields the developer adds. | Game Developer, Game Designer |

Above these: `gamestudio/output/artifacts/creative-pack/od-sevev/ux/first-minute.md` (approved). The other `.md` files here are the Monkey Bananas record, marked superseded.
