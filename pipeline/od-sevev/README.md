# עוד סבב art pipeline

One command, run from the fork root:

```bash
python3 pipeline/od-sevev/build.py            # full: refs → render → drift check → import → font → proofs (~2 min)
python3 pipeline/od-sevev/build.py --no-render # import the approved showcase out/ as-is (~4 s)
python3 pipeline/od-sevev/build.py --godot     # + Godot import, web .pck bytes, the TextServer font specimen
```

It needs Python 3.11+ with Pillow and numpy (`python3 -m pip install --user pillow numpy`). `--godot` also needs Godot 4.7.2 through
`tools/godot.sh`; it opens a small window for about 2 s to render the specimen.

## Stages

```
creative-pack art/refs/*.png ─┐
creative-pack art/showcase/src ├─ render (temp copy; the pack is never written) ─▶ strips, avatars, props, atlas.json
creative-pack art/src/locations.py ─────────────────────────────────────────────▶ stage_<era>.png
                               └─ drift check vs the approved showcase out/ (pixel-exact; FAIL on change)
art/od-sevev/ui-kit.json + out/ui/** (2D Artist) ─┐
art/od-sevev/out/key/icon-64-art.png ─────────────┤
                                                   ├─ validate ─▶ game/assets/sprites/** + sprites.json
pipeline/od-sevev/font/sevev9.glyphs ──────────────┴─ font ─────▶ game/assets/fonts/sevev9{,_outline}.fnt/.png
                                                                 game/assets/icon/*.png
                                                                 pipeline/od-sevev/proofs/*.png, budget.json
```

**The approved look is locked.** A full render must reproduce the approved `out/` pixel for pixel.
- **2026-09-28:** 0 changed files across 16 characters and the four stages.
- **2026-09-29 (the 3× cast, Bar's decision):** `out/` was re-rendered at density 3 and is the
  new approved look; a full render then gives 0 changed across 25 characters, 5 sources, props
  and stages. The shop icons and silhouettes still reproduce the 1× approved pixels exactly.
- **If a render drifts:** the build fails. `--allow-drift` exists only for a change Bar approved.

**It fails loudly on:**
- a strip that is not `frames × frameW`;
- semi-transparent texels;
- art on a frame's edge (named waivers only, today Bibi's clipped hat rim);
- a strip wider than 2048 (the WebGL2 floor);
- an event outside its anim;
- a UI-kit piece whose PNG doesn't match its declared size or 9-slice;
- an id collision;
- a missing required glyph;
- two glyphs with identical bitmaps. That guard caught ז = T in the draft; T is now 5 px wide.

**Adding things:**
- A new character (ref + `cast.py` entry, by the render owner) or a new UI piece (a `ui-kit.json`
  row, by the 2D Artist) lands with a rerun. No code change.
- A new glyph is a block in `font/sevev9.glyphs`.

**The contract for the engine** is `game/assets/sprites/CONTRACT.md`.

**The old Monkey Bananas pipeline** (`pipeline/*.ts`, `art/tools/*.mjs` → `game/data/art.json`)
still feeds the fork's baked sprites. It retires when the engine stops reading them.
