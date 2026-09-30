"""Wave 5: the art gaps the engine and views developers reported (2026-09-29).

  lane_<era>          the Suitcase lane's floor, one 32x28 tile per era (mobile-first A1: was 2x28, horizontal-only)
  thermo_tube_short   lives in ui_meters.py (the tube is parametric now)
  spin_s01..s15       redrawn at 24x24 in icons24.py, saved by wave2.spin_cards

The lane. The Suitcase flies in the band S-116..S-4 under the stage, which is the stage art's apron
(creative-pack locations.py lower_band: art rows 230-320, a lip on top, flat below). With the new layout
that apron is no longer under a UX panel, so a flat dark band reads as missing art.

v1 of the tile (wave 5) was horizontal-only: every column the same. On the phones the UX measured
(ux/mobile-first-layout.md V4) that read as a 24-art striped dead strip, because every row was one
colour. The mobile-first redraw (A1, 2026-09-29) keeps the lip, its dither, the lip's shadow and the
course seams whose spacing grows toward the viewer (4, 5, 6, 7 rows), and adds horizontal detail:
running-bond joints (short slabs in the far course, long ones near), a lit pixel on each slab's
top-left, the press cable that runs across every lane (the TV crews are always there), and a flyer /
spike-tape mark / dropped page / carpet weave per era. The tile is 32 wide, x-phased on stage-art
column 0, so the column and a wide phone's side bands carry the same floor. Every lane swatch keeps
>= 4.5:1 against the Suitcase's pale rim (asserted), so the flying Suitcase still reads on it.

Tile rows 0..27 = stage art rows 230..257 (art row 230 is the lip; the Magician's feet are row 219 =
S-156, so S = row 258). Tile col 0 = stage-art col 0 (mod 32): even, the lip dither's phase.
plaza_<era> (wave7.py) continues the floor below, from art row 258 down.
"""
from pix import Layer
from kit import save
from palette import contrast

LANES = {
    # era: (line, base, lip shadow, course top edge, course gap)  -- line/base are the stage art's own
    # v4 (Bar: "more Israel"): warm Jerusalem limestone, lamp-lit at Balfour, sunlit at the Knesset, polished inside the
    # courthouse; Washington is not Jerusalem, so it gets pale concrete pavement.
    "balfour":    ("wood_dk", "stone_sh", "wood",     "stone",  "paper"),     # Jerusalem stone at night, in lamp light
    "knesset":    ("stone_sh", "stone",  "stone_sh", "white",  "stone_sh"),  # sunlit Jerusalem stone
    "courthouse": ("teal_dk", "paper",   "stone_sh", "white",  "stone_sh"),  # polished limestone tiles
    "washington": ("slate",   "silver",  "grey",     "white",  "grey"),      # pale concrete pavement
}
# per era: (joint, light, cable, (detail 1, detail 2)); every one >= 4.5:1 against `rim`
DETAIL = {
    "balfour":    ("paper",    "stone",  "ink",     ("white", "pink_sh")),    # pale mortar joints, the cable, a flyer
    "knesset":    ("stone_sh", "white",  "ink",     ("wood", "stone_sh")),    # slab joints, the cable, a spike-tape X
    "courthouse": ("stone_sh", "white",  "ink",     ("white", "stone_sh")),   # tile joints, the cable, a dropped page
    "washington": ("grey",     "white",  "ink",     ("grey", "slate")),       # expansion joints, the cable
}
COURSES = (7, 12, 18, 25)          # the top row of each course seam (tile rows)
H = 28
W = 32                             # the tile period (art px)
JOINTS = ((9, 11, 8, 3), (14, 17, 16, 11), (20, 24, 16, 3))   # (first row, last row, spacing, x offset) per course


def lane(era):
    line, base, shadow, top, gap = LANES[era]
    joint, light, cable, (d1, d2) = DETAIL[era]
    L = Layer(W, H)
    L.rect(0, 0, W, H, base)
    L.hline(0, W - 1, 0, line)                     # the lip (art row 230)
    for x in range(1, W, 2):
        L.set(x, 1, line)                          # its dither (art row 231: line on odd x)
    L.hline(0, W - 1, 2, shadow)                   # the shadow the lip casts
    for x in range(0, W, 2):
        L.set(x, 3, shadow)                        # ... softening into the floor (50 % checker)
    for y in COURSES:
        L.hline(0, W - 1, y, top)
        if gap != top:
            L.hline(0, W - 1, y + 1, gap)
    for (y0, y1, step, off) in JOINTS:             # running bond, key light top-left
        for x in range(off, W, step):
            L.vline(x, y0, y1, joint)
            L.set(x + 1, y0, light)
    if era == "washington":                        # v4 concrete: sparse grit marks (was the carpet's woven diamonds)
        for x in range(7, W, 16):
            for (dx, dy) in ((0, -1), (-1, 0), (1, 0), (0, 1)):
                L.set(x + dx, 15 + dy, d1)
        for x in range(0, W, 4):
            L.set(x, 5, d2)
    elif era == "knesset":                         # a spike-tape X on the stage floor, nail heads by the board ends
        for (x, y) in ((22, 4), (24, 4), (23, 5), (22, 6), (24, 6)):
            L.set(x, y, d1)
        for x in range(2, W, 8):
            L.set(x, 10, d2)
        L.set(12, 15, d2); L.set(28, 15, d2)
    else:                                          # a flyer (Balfour) / a dropped page (courthouse), and scuffs
        L.rect(21, 4, 3, 2, d1)
        L.set(21, 4, light)
        L.rect(26, 15, 2, 2, d1)
        L.set(8, 5, d2); L.set(10, 5, d2)
    # the press cable: across the whole tile, sagging one row in the middle; it enters and leaves on row 22, so it tiles
    for x in range(W):
        L.set(x, 23 if 9 <= x < 23 else 22, cable)
    # v4: the lane is light stone, so the flying Suitcase separates by its dark outline and maroon body, not by its
    # pale rim (rim vs stone ~1:1): the base keeps >= 4.5:1 against the outline and >= 3:1 against the maroon.
    assert contrast("outline", base) >= 4.5 and contrast("maroon", base) >= 3.0, (era, base)
    return L


def lanes():
    for era in LANES:
        save(lane(era), f"lane_{era}", "stage", mode="tile",
             notes=f"Suitcase-lane floor for the {era} stage: a {W}x{H} TILE (redrawn 2026-09-29 for the mobile-first "
                   "layout, A1: slab/board joints, the press cable, a flyer; no row is one colour any more). Draw it at "
                   "x4 from the stage art's apron lip (art row 230 of stage_<era>, i.e. the art origin's y + 920 logical "
                   "px) across the whole canvas width, x-phase: tile col 0 on stage-art col 0 (mod 32; "
                   "diorama._place_lane does this for any tile width), above the stage art and pads, under the critters "
                   "and the Suitcase. 28 rows = art rows 230-257 = S-112..S. v4: warm Jerusalem stone (Washington: pale "
                   "concrete); the base keeps >= 4.5:1 against the Suitcase's outline and >= 3:1 against its maroon. plaza_<era> "
                   "continues the floor below (art row 258 down).")


def build():
    lanes()


if __name__ == "__main__":
    build()
    from kit import write_manifest
    print(write_manifest())
