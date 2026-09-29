"""Wave 5: the art gaps the engine and views developers reported (2026-09-29).

  lane_<era>          the Suitcase lane's floor, one horizontal-only tile per era
  thermo_tube_short   lives in ui_meters.py (the tube is parametric now)
  spin_s01..s15       redrawn at 24x24 in icons24.py, saved by wave2.spin_cards

The lane. The Suitcase flies in the band S-116..S-4 under the stage, which is the stage art's apron
(creative-pack locations.py lower_band: art rows 230-320, a lip on top, flat below). With the new layout
that apron is no longer under a UX panel, so a flat dark band reads as missing art. The treatment stays
inside the skeleton's rule for that band (flat colour family, extendable) by being HORIZONTAL ONLY: the
apron's own lip and dither, a 1-row shadow the lip casts, then paving courses / boards whose spacing
grows toward the viewer (4, 5, 6, 7 rows), so it reads as a floor plane in front of the stage. Every
column of the tile is the same except the lip dither's 2-px phase, so the engine can tile it across the
whole canvas width and a wide phone's side bands carry the same floor as the 720 column (the stage art
alone stops at the column edge). No vertical edge ever sits behind the flying Suitcase, and every lane
swatch is at least as dark as the era's apron, so the Suitcase's rim keeps its contrast (§3).

Tile rows 0..27 = stage art rows 230..257 (art row 230 is the lip; the Magician's feet are row 219 =
S-156, so S = row 258). Tile col 0 = an even art x (the lip dither's phase: base on even x).
"""
from pix import Layer
from kit import save

LANES = {
    # era: (line, base, lip shadow, course top edge, course gap)  -- line/base are the stage art's own
    "balfour":    ("suit_dk", "night",   "ink",     "suit_dk", "ink"),       # the street in front of the residence, at night
    "knesset":    ("ink",     "wood_dk", "hair_dk", "hair_dk", "ink"),       # a wooden stage floor: dark board gaps only
    "courthouse": ("teal_dk", "ink",     "outline", "teal_dk", "outline"),   # corridor tiles under fluorescent teal
    "washington": ("night",   "navy",    "night",   "night",   "night"),     # a navy carpet with woven stripes
}
COURSES = (7, 12, 18, 25)          # the top row of each course seam (tile rows)
H = 28


def lane(era):
    line, base, shadow, top, gap = LANES[era]
    L = Layer(2, H)
    L.rect(0, 0, 2, H, base)
    L.hline(0, 1, 0, line)                         # the lip (art row 230)
    L.set(1, 1, line)                              # its dither (art row 231: line on odd x)
    L.hline(0, 1, 2, shadow)                       # the shadow the lip casts
    L.set(0, 3, shadow)                            # ... softening into the floor (50 % checker)
    for y in COURSES:
        L.hline(0, 1, y, top)
        if gap != top:
            L.hline(0, 1, y + 1, gap)
    return L


def lanes():
    for era in LANES:
        save(lane(era), f"lane_{era}", "stage", mode="tile",
             notes=f"Suitcase-lane floor for the {era} stage: a 2x{H} horizontal-only TILE. Draw it at x4 from the stage "
                   "art's apron lip (art row 230 of stage_<era>, i.e. the art origin's y + 920 logical px) across the whole "
                   "canvas width, x-phase on an even art column of the stage art, above the stage art and pads, under the "
                   "critters and the Suitcase. 28 rows = art rows 230-257 = S-112..S. Rows 2-27 are the apron colour "
                   "(= stages[era].padBottom) plus course seams, so the column and the side bands match.")


def build():
    lanes()


if __name__ == "__main__":
    build()
    from kit import write_manifest
    print(write_manifest())
