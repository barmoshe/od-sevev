# ux/ — "עוד סבב" (UX Designer's slice)

| File | What it is | Consumer |
|---|---|---|
| `ui-strings.json` | Every UI chrome string, Hebrew, logical order, bidi isolates included. Canonical for code (`tools/sync_data.sh` copies it to `game/data/`). | Game Developer |
| `string-budgets.json` | Per-key box, surface, scale, line budget and worst-case pixel width, for the build-time pixel-width lint. | Game Developer (lint) |
| `tools/gen_strings.py` | The single source for both JSON files; self-lints every canvas string with the shipping font's metrics (`game/assets/fonts/sevev9.fnt`). **Edit strings here, then run `python3 ux/tools/gen_strings.py`.** | UX Designer |
| `rtl-map.md` | Screen-by-screen RTL mapping of the fork's views: rects, fill and crawl directions, icon sides, tab order, safe areas, thumb zone, touch targets. §8 is the leader picker (`LEADER_PICK`), §4.3 the per-leader stage, HUD and press skin. | Game Developer, 2D Artist, Animator |
| `review-2026-09-29.md` | Build review R1-R26 (severity, owner, exact fix) and the §5.1 objection answer. | orchestrator, all roles |
| `ftue.md` | FTUE prompt triggers as predicates over the fork's `GameState`, with the new fields the developer adds. | Game Developer, Game Designer |
| `screen-graph.md` §0 | **Only §0 is live:** the `LEADER_PICK` node, its exits, history and entry deltas to first-minute §1 (leader select, rev 4). The rest is the Monkey Bananas record. | Game Developer |

Above these: `gamestudio/output/artifacts/creative-pack/od-sevev/ux/first-minute.md` (approved). The other `.md` files here are the Monkey Bananas record, marked superseded.
