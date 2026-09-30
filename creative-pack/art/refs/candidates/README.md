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

- **In the game (2026-09-30):** `mk-offer`, `mk-undecided`, `mk-switcher` (the generic MKs in the
  opposition lineups), keyed out into `../`, landmarks in `cast.py`, rendered at d3 + d2.
- **Rejected as drawn:** `mk-returner` looks like Netanyahu (the style ref's face leaked). Regenerate
  with a made-up face; the game keeps the no-photo stand-in for him until then.
