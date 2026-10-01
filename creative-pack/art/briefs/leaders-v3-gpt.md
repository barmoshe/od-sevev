# Images to generate in ChatGPT: leaders v3 (2026-10-01)

Bar, 2026-10-01: "אין לי בעיה שנייצר עוד אסטים… אל תתקמצן". This is the asset list for
**leaders v3**: a storyline and an active ability for each leader, and a busy moment for every
leader on the press/court day. The design is in `design/leaders-v3.md`.
Each image becomes a ref in `creative-pack/art/refs/`. The TA rigs it the way Herzog's shrug was done:
`cast.py` gets a pose react with the second ref (`react='shrug'`-style). Then `build.py` and the
scratchpad `import.sh`.

Until the art lands, the game runs on drawn placeholders: `PressDesk` for the podium and bench, the
leader's existing react for the poses, and the cooldown chip with a letter.

## How to generate (every image)
The rules in `CHATGPT-REQUESTS.md` still apply:
- one image per chat;
- portrait 1024×1536, plain flat light background;
- no text, logos, party colours, flags, uniforms or weapons;
- nothing near October 7.

**Second poses (A1–A9) must line up with the leader's first ref.**
- Attach `refs/<leader>.png` and say: *"The same person, same outfit, same caricature style, line
  weight and shading. Same scale and the same place in the frame: the head and the feet at the same
  height as in the attached image. Only the pose changes."*
- The rig pastes the second ref over the first in the first ref's coordinates (like
  `herzog-shrug.png` over `herzog.png`), so the feet line and the head size must match.
- Ask again if the figure came out bigger, smaller or moved.

**Objects (B1–B7)** need the cast style ref only: attach `refs/bibi.png` and say *"the same cartoon
style"*. Front view, slightly from above, one object centred.

## A. Second poses (the active ability's react)

| # | File | Leader | The ability it plays | Prompt |
|---|---|---|---|---|
| A1 | `bennett-sign.png` | בנט | "לחתום / להפוך": signs a pledge, then flips it | "Full body, he holds a long paper scroll in one hand and signs it with a big fountain pen in the other, proud half-smile, looking at the viewer. The scroll is blank (no writing)." |
| A2 | `ben-gvir-walkout.png` | בן גביר | "אני פורש": walks off with his things | "Full body, walking toward screen-left, carrying a cardboard office box (a desk plant and a mug sticking out), chin up, looking back over his shoulder. The box is plain, no text." |
| A3 | `ben-gvir-back.png` | בן גביר | "חזרתי": back after lunch | "Full body, standing, one hand raised in a big cheerful wave, the other hand holding the same plain cardboard box against his hip, grinning." |
| A4 | `liberman-document.png` | ליברמן | "המסמך": the 5-clause document | "Full body, holding up a single sheet of paper toward the viewer with one hand and pointing at it with the other, stern look. The paper shows five short grey bars (like lines of text) and no real letters." |
| A5 | `eisenkot-summit.png` | אייזנקוט | "שולחן עגול": convenes the heads | "Full body, one arm extended to the side, palm open, inviting someone to sit; the other hand holds a short wooden ruler; calm, straight posture." |
| A6 | `smotrich-budget.png` | סמוטריץ׳ | "תקציב בדקה ה־90": the last-minute budget | "Full body, hugging a huge thick binder to his chest with one arm, the other hand holding up a stopwatch, a satisfied smirk. No text on the binder." |
| A7 | `deri-bench.png` | דרעי | "נסגור במסדרון" and the busy moment | "Full body, sitting on a simple wooden corridor bench (include the bench), leaning forward, one hand raised as if calling someone over, friendly knowing smile. Plain background, no walls." |
| A8 | `golan-swipe.png` | גולן | "החלקה שמאלה": swipes the unity offer away | "Full body, holding a smartphone in one hand and swiping the screen to the left with a finger of the other hand, eyebrows up, amused. The phone screen is plain, no app, no logo." |
| A9 | `bibi-matchmaker.png` | ביבי | "תתאחדו": asks two partners to unite | "Full body, both arms out in front of him, hands together as if joining two other people's hands, a salesman's smile. No other people in the image." |

## B. Objects and stage props

| # | File | What | Where | Prompt |
|---|---|---|---|---|
| B1 | `podium.png` | A press podium with two microphones | **The busy moment for 7 leaders** (it replaces the drawn `PressDesk`) | "A small wooden press podium seen from the front, two microphones on short stalks on top, a small red 'on air' light on the front panel. No seal, no emblem, no text, no flag." |
| B2 | `corridor-bench.png` | A wooden corridor bench | Deri's busy moment | "A plain wooden bench like in a parliament corridor, three-quarter view, empty. No text, no plaque." |
| B3 | `round-table.png` | A small round table with empty chairs | Eisenkot's "שולחן עגול" | "A small round meeting table with four empty chairs around it, slightly from above. No text, no flags." |
| B4 | `cardboard-box.png` | A cardboard office box | Ben Gvir's walk-out (the chip icon and the stage) | "A cardboard office box with a desk plant, a mug and a folded jacket inside. No text." |
| B5 | `pledge-scroll.png` | A signed scroll | Bennett's pledge (chip icon and pill) | "A rolled-out paper scroll with a scribbled signature line at the bottom, a fountain pen lying across it. No readable text." |
| B6 | `budget-book.png` | A huge budget binder with a stopwatch | Smotrich's budget card | "A huge fat binder bulging with papers, a stopwatch lying on top of it. No text on the binder." |
| B7 | `clause-doc.png` | A document with five lines and a seal-less stamp | Liberman's clauses | "A single sheet of paper with five short grey lines and a big round red rubber stamp mark with no letters. No readable text." |

## C. Ability icons (UI)
Eight 64×64 icons for the ability chip next to the leader. Generate them as **one image**: a 4×2 grid
on a flat light background, each icon a simple bold cartoon object with a thick dark outline, the
same icon style as the game's UI icons (attach `game/assets/sprites/` icons as the reference if you
like). The TA cuts the grid and turns it into pixel art.

1. a fountain pen over a scroll (Bennett)
2. a cardboard box with a door arrow (Ben Gvir)
3. a sheet with five lines (Liberman)
4. a round table (Eisenkot)
5. a stopwatch on a binder (Smotrich)
6. a bench (Deri)
7. a phone with a left arrow (Golan)
8. two hands joining (Bibi)

## D. Still pending from earlier
- `kaia.png`: Kaia the dog (idle + happy). It replaces the drawn placeholder dog.
  - Prompt: "A cartoon white dog with a brown patch on the back, standing, tongue out, tail up, side view facing screen-left. Same cartoon style."
  - Plus `kaia-happy.png`: the same dog with a cucumber in its mouth.
- `mk-returner.png`: see `CHATGPT-REQUESTS.md` #5.
- Optional: **picker key art**, one wide image per leader for the picker (Bar's pending ask in spec §12).

## After generating
Save into `creative-pack/art/refs/` with the file names above and tell the TA.
- **Poses (A):** the second ref in `cast.py` (like `herzog-shrug`), with a check that the feet and
  head line up with the first ref.
- **Objects (B):** the props block in `cast.py`/`build.py`. Then:
  - `PressDesk` swaps its pixel map for the `podium` / `corridor-bench` sprite;
  - the ability chip swaps its letter for the icon (C).
