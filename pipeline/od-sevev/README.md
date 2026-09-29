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
art/od-sevev/out/key/icon-128-art.png ────────────┤
                                                   ├─ validate ─▶ game/assets/sprites/** + sprites.json
pipeline/od-sevev/font/sevev9.glyphs ──────────────┤
pipeline/od-sevev/font/sevev9@2.glyphs ────────────┴─ font ─────▶ game/assets/fonts/sevev9{,_outline,@2}.fnt/.png
                                                                 game/assets/fonts/fonts.json (cuts + density)
                                                                 game/assets/icon/*.png
                                                                 pipeline/od-sevev/proofs/*.png, budget.json
```

**The approved look is locked.** A full render must reproduce the approved `out/` pixel for pixel.
- **2026-09-28:** 0 changed files across 16 characters and the four stages.
- **2026-09-29 (the 3× cast, Bar's decision):** `out/` was re-rendered at density 3 and is the
  new approved look; a full render then gives 0 changed across 25 characters, 5 sources, props
  and stages. The shop icons and silhouettes still reproduce the 1× approved pixels exactly.
- **2026-09-29 (Bibi's d 2 alternate, engine request):** `bibi_{idle,tap,crit}_d2.png` joined
  the approved `out/` (a second render of the same motion at 192 px); the d 3 files did not move
  (0 changed).
- **2026-09-29 (d 2 for everything rendered, Bar: "sharp characters on every phone"):** every rig
  in `build.py` is now a function of the density d, and `DENSITIES = (3, 2)` renders each
  character and money source at both from the same function (`render_char`, `source`). 46
  character strips and 5 source strips (`*_d2.png`) joined the approved `out/`; a full render
  gives 0 changed, 0 new: the d 3 files and atlas entries did not move.
- **2026-09-29 (leader select, the generic tap rig):** a `tap` recipe on a `cast.py` entry (`TAP_DOC`)
  renders a `tap` anim from Bibi's squash table and exports `propMouth` + `temple` on every anim of that
  character. 14 tap strips (7 leaders × d 3 + d 2), the `source_advisers` recolour (4 files) and the
  8 leaders' neutral-ring picker avatars (`<c>_avatar_pick.png` 32, `<c>_avatar24_pick.png` 24; also the
  app icon's heads) joined `out/`; a full render gives 0 changed: every existing
  strip is pixel-exact and `atlas.json` only gained keys. `budget.json` now counts the heaviest
  leader as the resident body (`vramLeaderByK`), not Bibi.
- **2026-09-29 (the mobile-first picker, UX A3):** each launch leader's XL picker heads,
  `<char>_avatar_pick_d3.png` (96) and `<char>_avatar_pick_d2.png` (64), joined `out/`
  (`build.py` `avatar_pick_xl`: the same head crop and neutral ring, cut from the ref); a full
  render gives 0 changed. Imported as `avatar_pick_<c>_d3` / `_d2`, `chars[c].avatarPick96` / `avatarPick64`.
- **If a render drifts:** the build fails. `--allow-drift` exists only for a change Bar approved.

**It fails loudly on:**
- a strip that is not `frames × frameW`;
- semi-transparent texels;
- art on a frame's edge (named waivers only, today Bibi's clipped hat rim);
- a strip wider than 2048 (the WebGL2 floor);
- a frame that does not read back pixel-exact through its `frameMap` cell (repeated frames share
  a texture cell; CONTRACT §4);
- a density alternate (`chars[c].densities` / `sources[id].densities`: every rendered character
  and source has a d 2) whose frames, fps, loop or events (sources: frames, fps, loop, point names)
  differ from the main render's, whose landmarks (any named per-frame point track: `hatMouth`,
  `temple`, `propMouth`, ...; source `points`) sit more than half an art px from the main render's
  relative to the feet, or a point track that leaves its frame (checked twice: in the render,
  `same_motion`, and at import, `validate_char` / `validate_source_alt`). Tracks are found by shape
  (`sprites.is_track`: one `[x, y]` per frame), never by name, so a new track needs no pipeline code;
  the trimmed frame grows to hold every track point (a loose prop's anchor can sit beside the body);
- an event outside its anim;
- a UI-kit piece whose PNG doesn't match its declared size or 9-slice;
- a `design/content.json` money source that doesn't resolve to shipped art (stage strip, shop icon, locked
  silhouette, a `lob` set piece's coin), which would draw the engine's "?" placeholder;
- an id collision;
- a missing required glyph;
- two glyphs with identical bitmaps. That guard caught ז = T in the draft; T is now 5 px wide.
- **Sevev 9 @2 breaking the ×2 metric rule** (`font.check_companion`, on the written `.fnt` files): any
  code point whose `xadvance` is not exactly 2 × Sevev 9's, an ink box (width, height, offsets) that is not
  2 × its twin's, a line height or baseline not 2 ×, a different code-point set, or different kerning. With
  `--godot` it also shapes the proof lines through TextServer and fails unless every @2 width is 2 × Sevev 9's.

**Adding things:**
- A new character (ref + `cast.py` entry, by the render owner) or a new UI piece (a `ui-kit.json`
  row, by the 2D Artist) lands with a rerun. No code change.
- A new glyph is a block in `font/sevev9.glyphs` **and** its 2× redraw in `font/sevev9@2.glyphs` (18 rows,
  exactly twice as wide); the build fails until both exist.
- `--godot` needs a display (it opens a window): on a headless Linux box run it under
  `xvfb-run -a python3 pipeline/od-sevev/build.py --no-render --godot`. It writes
  `proofs/font-density2.png` (Sevev 9 vs @2, every glyph and the real strings in their boxes, ×4 on a k 4 device).

**The contract for the engine** is `game/assets/sprites/CONTRACT.md`.

**The old Monkey Bananas pipeline** (`pipeline/*.ts`, `art/tools/*.mjs` → `game/data/art.json`)
still feeds the fork's baked sprites. It retires when the engine stops reading them.
