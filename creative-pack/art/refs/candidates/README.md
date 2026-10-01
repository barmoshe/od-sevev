# Candidates (Bar's picks recorded here)

- `may-golan-opt1.png` / `opt2` / `opt3`: May Golan v2, each generated in its own chat with the Bibi
  and Regev refs as style.
  - **Picked: option 1** (Bar, 2026-09-29): long dark hair, navy suit, the binder, two phantom
    employees in ties. Copied to `../may-golan.png`; landmarks in `art/showcase/src/cast.py`
    (`may-golan`), rendered at density 3 with the rest of the cast.
  - `opt2` and `opt3` stay here for the record; nothing reads them.

## ChatGPT batch, 2026-09-30

Every file in this batch came back RGB on a flat off-white field. `rig.py` crops a ref to its
alpha box, so each approved one is keyed out first:
`python3 creative-pack/art/showcase/src/cutout.py refs/candidates/<id>.png refs/<id>.png`.

- **In the game (2026-09-30):**
  - the generic MKs `mk-offer`, `mk-undecided`, `mk-switcher`;
  - the real MKs `lazimi`, `kariv`, `tibi` (Golan's round) and `almog` (Bibi's and Ben Gvir's);
  - the money sources `submarine`, `poison`, `checkbook` (Washington), `donor`, `funds`. These replaced
    the 2D Artist's 1x drawings; their 15 `ui-kit.json` rows are gone. The wide ones take `iconFit`
    (the whole object in the 24-px icon), and the submarine a narrower side `pad`, so it clears the
    thermometer column.

  Each was keyed out into `../`, given landmarks or a recipe in `cast.py`, and rendered at d3 + d2.
- **Not used yet:** `aide`. The engine has no slot to draw the aide figure (the aide is a button and a
  15-px trophy icon).
- **Rejected as drawn:** `mk-returner` looks like Netanyahu (the style ref's face leaked). Regenerate
  with a made-up face; the game keeps the no-photo stand-in for him until then.

## Leaders v3 GPT batch, 2026-10-01

All 19 files (`creative-pack/art/briefs/leaders-v3-gpt.md`) came back RGB on an off-white field. The
originals are kept here as `<id>-src.png`; the keyed copies in `../` are what `cast.py` / `build.py` read.
Each was cut with `cutout.py` (`python3 creative-pack/art/showcase/src/cutout.py <id>-src.png ../<id>.png`),
plus:

- `deri-bench`: `--holes 123,901 123,793 125,1003` (the gaps between the bench slats) and the soft floor
  shadow cleared: below y 1290, every keyed (partly transparent) field pixel goes fully clear; the shoes'
  highlights are opaque and stay.
- `round-table`: `--holes 295,736 719,736 830,677 193,676` (the floor between the chairs and the table).
- `ability-icons`: the same floor rule over the whole sheet (the shadows under the table and the bench).

**In the game:** the 9 poses as their own characters (`<leader>-<pose>`, laid into the leader's ref
coordinates: `cast.POSES`), the 7 objects as 1x props (`cast.REF_PROPS`), the 8 icons as
`prop_ability_<leader>` + `_d2` (`cast.ABILITY_ICONS`) and Kaia (`cast.KAIA`).
