"""Wave 7: the art the mobile-first layout needs (ux/mobile-first-layout.md §10, 2026-09-29).

  A1  lane_<era>                (wave5.py, 192x28)  the Suitcase lane: the same paving as the plaza
  A1  plaza_<era>               192x192 TILE the floor in front of the stage, from art row 258 to the screen bottom
  A2  wing_<era>_l / _r         Wx230       the stage's side wings: art rows 0-229 continued past columns 0 / 179
  --  brawl_cloud_cue           26x20 x 4   the brawl cloud cut for the stage cue at x4 (the Animator's ask)
  --  court_window spots        (wave2.py)  moved to art rows the phones keep (the Animator's ask)

The stages stay the approved 180x320 art: nothing here repaints them. Everything is additive and drawn
by the diorama around (wings) and over (lane, plaza) the art, on the art's own x4 grid.

Wings (A2). The canvas is up to 215 art columns (430x932), so up to 17.5 columns show beside the art on
each side. Each wing is a strip of the era's rows 0-229 (the lane covers 230-257, the plaza 258 on), TILEABLE
horizontally with its own period W (a multiple of the era's own horizontal rhythm: Balfour's wall panels 10,
the Knesset lawn's specks 11, the courthouse's panels 30 and tubes 60, Washington's specks 9). The engine tiles
wing_<era>_l leftward from art column 0 (its last column abuts column 0) and wing_<era>_r rightward from
column 180 (its first column abuts column 179). Seamless both ways by construction: every wing is drawn in
stage-art coordinates on a canvas that wraps x mod W (`Wrap`), so an element that crosses the art's edge (a
tree, a protester, a bench, a kraft sign) is continued exactly and repeats every W; wing-native elements never cross
the wing's own edges. `seam_report()` checks the column next to the art against the art's edge column.

Plaza (A1). The rows under the lane were flat padBottom. The plaza tile is Jerusalem-stone paving (2026-09-30:
wave5.Paving, one layout with the lane): slabs of random length in 2-3 stone tones, short broken mortar joints,
chisel flecks, a square big stone, a repair, the odd flyer and a drain grate (the press cable is gone: it read as
worms). No row is one colour (UX S8's dead-band rule), no barrier or fence (do/don't 13: nothing that
reads as a border fence), no gold, no ribbons, no text. It is scenery, not UI: it shows before tap 1 and under
the picker's scrim, and the panels cover it the rest of the time.
"""
import os
import random

from pix import Layer
from kit import save, strip, outline_inplace, ROOT, PROOFS
from palette import rgb
from wave5 import Paving, draw_courses, PAVE_W, PLAZA_H

ERAS = ("balfour", "knesset", "courthouse", "washington")
WING_H = 230                 # art rows 0-229 (the lane starts at 230)
PLAZA_ROW = 258              # the first art row under the lane (lane rows 230-257)
PW, PH = PAVE_W, PLAZA_H      # the plaza tile, 192x192 (wave5: the floor's period)
WING_W = {"balfour": 20, "knesset": 22, "courthouse": 60, "washington": 36}
SW = 180


class Wrap(Layer):
    """A W-wide strip addressed in stage-art x: art x lands on column (x - x0) mod W. Anything drawn tiles with
    period W by construction."""
    def __init__(self, w, h, x0):
        super().__init__(w, h)
        self.x0 = x0

    def set(self, x, y, c):
        super().set((x - self.x0) % self.w, y, c)

    def get(self, x, y):
        return super().get((x - self.x0) % self.w, y)

    def span(self):
        """The art-x range the strip is placed at (one period)."""
        return range(self.x0, self.x0 + self.w)


def _wing(era, side):
    W = WING_W[era]
    return Wrap(W, WING_H, -W if side == "l" else SW)


# ------------------------------------------------------------------ Balfour (creative-pack locations.py balfour())
def _balfour_crowd():
    """The art's own protesters (the same seeded draw as locations.balfour): [(side, i, x, h, sign x or None)]."""
    r = random.Random(7)
    out = []
    for side in (0, 1):
        xs = range(2, 56, 7) if side == 0 else range(126, 178, 7)
        for i, x in enumerate(xs):
            h = 20 + r.randrange(0, 6)
            sx = x + r.choice((-2, 1)) if i % 2 == 0 else None
            out.append((side, i, x, h, sx))
    return out


# B14 (Bar, 2026-09-30: option D'): the protest signs are handmade kraft cardboard. A verbatim copy of the creative
# pack's locations.kraft_sign (same SIGN_MARKS, same (k, side) indexing), so a board that crosses the seam is the
# same board on both sides of it. See locations.py for the marker rule (right-aligned rows, never a centred gap).
SIGN_MARKS = [("ink",     [(0, 5), (6, 2)], 4),
              ("flag_hi", [(0, 2), (3, 5)], 5),
              ("ink",     [(0, 6)],         3),
              ("flag_hi", [(0, 3), (4, 3)], 6)]


def _kraft_sign(L, sx, top, k, side):
    """k = the sign's index along its side (the art's i // 2; wing-native signs continue it past 0..3),
    side 0 left / 1 right (the art's side, not the wing's)."""
    L.vline(sx + 2, top - 6, top + 6, "wood")
    x0, y0 = sx - 2, top - 14
    fill = "stone" if (k + side) % 2 == 0 else "stone_sh"
    shade = "stone_sh" if fill == "stone" else "wood"
    cx, cy = [(x0, y0), (x0 + 9, y0), (x0 + 9, y0 + 7), (x0, y0 + 7)][(k + side) % 4]
    behind = L.get(cx, cy)
    L.rect(x0, y0, 10, 8, fill)
    L.hline(x0, x0 + 9, y0 + 7, shade)
    L.set(cx, cy, behind)
    c, top_row, n2 = SIGN_MARKS[(k + 2 * side) % 4]
    rm = x0 + 8
    for off, n in top_row:
        L.hline(rm - off - n + 1, rm - off, y0 + 2, c)
    L.hline(rm - n2 + 1, rm, y0 + 4, c)


def _protester(L, x, h, sign=None, k=0, side=0, floor=216):
    top = floor - h
    L.rect(x - 3, top + 6, 7, h - 6, "night")
    L.ellipse(x, top + 3, 2.6, 3, "skin_sh")
    for dx in (-1, 0, 1):
        L.set(x + dx, top + 1, "hair_dk")
    if sign is not None:                                  # a handmade kraft sign on a stick (never lettered)
        _kraft_sign(L, sign, top, k, side)


def wing_balfour(side):
    L = _wing("balfour", side)
    x0, W = L.x0, L.w
    L.bands(x0, 0, W, [("night", 110), ("plum", 60), ("plum_hi", 60)])
    r = random.Random(71 if side == "l" else 72)          # a few stars (the art has 26 over 180 columns)
    for _ in range(max(2, W // 7)):
        L.set(x0 + r.randrange(1, W - 1), r.randrange(4, 96), "white" if r.random() < .5 else "slate")
    # the dark trees that frame the villa: the art's edge trees, continued (they wrap into a treeline)
    trees = [(8, 140), (18, 120)] if side == "l" else [(166, 124), (176, 142)]
    for (cx, cy) in trees:
        L.ellipse(cx, cy, 14, 22, "night")
    # the perimeter wall: lamp-lit slate, a grey coping, a panel joint every 10 columns (x % 10 == 0, as the art)
    L.rect(x0, 168, W, 48, "slate")
    L.rect(x0, 168, W, 3, "grey")
    for x in L.span():
        if x % 10 == 0:
            L.vline(x, 171, 215, "suit_hi")
    # the crowd: the art's protester that crosses the seam, continued; then wing-native protesters, 6-7 apart,
    # never crossing the wing's own edges (so a copy never lands on the art)
    crowd = _balfour_crowd()
    if side == "l":
        seam = [c for c in crowd if c[0] == 0 and (c[2] - 3 < 0 or (c[4] is not None and c[4] - 2 < 0))]
        native = [(-11, 23, None, -2), (-5, 21, -11, -1)]  # (x, h, sign x, k): k continues the art's 0..3 outward
    else:
        seam = [c for c in crowd if c[0] == 1 and (c[2] + 3 > SW - 1 or (c[4] is not None and c[4] + 7 > SW - 1))]
        native = [(183, 22, 182, 4), (190, 24, None, 5), (196, 21, 192, 5)]
    for (sd, i, x, h, sx) in seam:
        _protester(L, x, h, sx, k=i // 2, side=sd)
    for (x, h, sx, k) in native:
        _protester(L, x, h, sx, k=k, side=0 if side == "l" else 1)
    # the police barrier in front of them: two grey rails, a post every 10 (the art's are 9 apart; 10 tiles)
    L.hline(x0, x0 + W - 1, 209, "grey")
    L.hline(x0, x0 + W - 1, 213, "grey")
    for x in L.span():
        if x % 10 == (2 if side == "l" else 8):
            L.vline(x, 208, 216, "slate")
    L.rect(x0, 216, W, 14, "suit_dk")                     # the street
    return L


# ------------------------------------------------------------------ Knesset
def wing_knesset(side):
    L = _wing("knesset", side)
    x0, W = L.x0, L.w
    L.bands(x0, 0, W, [("sky", 118), ("white", 30)])
    # the hills (Jerusalem), continued as a low rolling ridge: the art's edge height at the seam, a 3-row swell
    import math
    edge = 129 if side == "l" else 133
    for x in L.span():
        ph = (x - (-1 if side == "l" else SW)) / W
        top = edge - round(3 * math.sin(math.pi * ph) ** 2)
        L.vline(x, top, 168, "teal_hi")
    # the lawn, exactly the art's pattern (the lime specks repeat every 11 columns: W = 22)
    L.rect(x0, 169, W, 47, "green")
    L.dither(x0, 169, W, 2, "green", "green_sh")
    for y in range(172, 216, 3):
        for x in L.span():
            if (x - (y * 7) % 11) % 11 == 0:
                L.set(x, y, "lime")
    # one olive tree per tile, standing on the lawn, inside the tile (the art's olive at 2/3 size)
    cx = x0 + W // 2
    L.vline(cx, 174, 211, "wood_dk"); L.vline(cx + 1, 180, 211, "wood")
    L.ellipse(cx, 170, 9, 7, "green_sh"); L.ellipse(cx - 3, 166, 5, 3, "green")
    L.rect(x0, 216, W, 14, "stone_sh")
    return L


# ------------------------------------------------------------------ the courthouse
def wing_courthouse(side):
    L = _wing("courthouse", side)
    x0, W = L.x0, L.w
    L.rect(x0, 0, W, 40, "teal_dk")
    for x in L.span():                                     # the fluorescent tubes, every 60 (the art's phase)
        if x % 60 == 20:
            L.rect(x, 10, 22, 2, "white"); L.hline(x - 1, x + 22, 12, "teal_hi")
    L.rect(x0, 40, W, 176, "teal")
    L.dither(x0, 40, W, 2, "teal", "teal_dk")
    for x in L.span():                                     # wall panelling every 30
        if x % 30 == 0:
            L.vline(x, 42, 215, "teal_dk")
    L.rect(x0, 148, W, 68, "teal")                         # the floor
    for y in range(152, 216, 8):
        L.hline(x0, x0 + W - 1, y, "teal_dk")
    L.rect(x0, 148, W, 3, "teal_dk")
    # the public benches: the art's edge benches continue to the canvas edge, with a 4-column aisle per tile
    aisle = range(-27, -23) if side == "l" else range(200, 204)
    for x in L.span():
        if x in aisle:
            continue
        L.set(x, 184, "stone_sh")
        L.vline(x, 185, 191, "wood")
        L.vline(x, 192, 215, "wood_dk")
    L.rect(x0, 216, W, 14, "teal")
    return L


# ------------------------------------------------------------------ Washington
def _blossom(L, cx, cy):
    L.vline(cx, cy, cy + 30, "wood_dk")
    L.ellipse(cx, cy - 6, 15, 10, "pink"); L.ellipse(cx + 4, cy - 2, 8, 5, "pink_sh")
    L.ellipse(cx - 5, cy - 10, 6, 4, "white")


def wing_washington(side):
    L = _wing("washington", side)
    x0, W = L.x0, L.w
    L.bands(x0, 0, W, [("sky", 124), ("white", 30)])
    L.rect(x0, 154, W, 16, "sky")          # rows 154-169 are unpainted in the art: the engine's padTop sky shows there
    L.rect(x0, 170, W, 46, "green")
    for y in range(172, 216, 3):
        for x in L.span():
            if (x - (y * 5) % 9) % 9 == 0:
                L.set(x, y, "lime")
    # the art's edge blossom tree, continued; its copy one period out stands whole in the wing
    tree = (14, 170) if side == "l" else (168, 168)
    _blossom(L, *tree)
    L.rect(x0, 216, W, 14, "stone_sh")
    return L


WINGS = {"balfour": wing_balfour, "knesset": wing_knesset, "courthouse": wing_courthouse, "washington": wing_washington}


# ------------------------------------------------------------------ the plaza (A1)
# 2026-09-30 (manual test A1: "the plaza reads as worms, not stone"): redrawn from the shared paving layout
# (wave5.Paving), so the lane and the plaza are one floor. The old tile's 1-px ink press cable meandered down the
# tile and lined up across copies into snakes; its 32-px running bond in one tone with full-length pale seams read
# as a brick wall. Now: slabs of random length in 2-3 stone tones, short broken mortar joints, chisel flecks, one
# square "big stone" or two across two courses (Jerusalem stone), and a few small details. 192x192: a phone shows
# at most 1.1 copies across and 1 down before tap 1, so no repeat can be spotted.

def _big_stone(L, pav, r, ci):
    """A square stone across courses ci and ci+1 (the plaza's): replaces a slab of course ci and cuts course ci+1,
    with its own joints. Returns False when a neighbour would be cut into a sliver (< 5 px)."""
    cfg = pav.cfg
    s0, rows0, slabs0 = pav.plaza[ci]
    s1, rows1, slabs1 = pav.plaza[ci + 1]
    cand = [sl for sl in slabs0 if 16 <= sl[1] <= 26]
    if not cand:
        return False
    a, n, _ = r.choice(cand)
    b = a + n
    j1 = [x for x, _, _ in slabs1]
    for j in j1:
        d = (j - a) % PW
        if 0 < d < n and (d < 5 or n - d < 5):
            return False
        if 0 < (a - j) % PW < 5 or 0 < (j - b) % PW < 5:
            return False
    t = cfg["big"]
    rows = rows0 + [s1] + rows1
    for y in rows:
        for i in range(n):
            L.set((a + i) % PW, y % PH, t)
    fleck = cfg["fleck"].get(t, cfg["mortar"])
    face = [(a + 1 + i, y) for y in rows[1:] for i in range(n - 1)]
    for (x, y) in r.sample(face, len(face) * 3 // 100):
        L.set(x % PW, y % PH, fleck)
    light = cfg["light"].get(t, "white")
    for i in range(1, n * 2 // 3):
        L.set((a + i) % PW, rows[0] % PH, light)
    for y in rows[1:4]:
        L.set((a + 1) % PW, y % PH, light)
    for y in rows:                                          # its two joints, the full height of both courses
        L.set(a % PW, y % PH, cfg["mortar"])
        L.set(b % PW, y % PH, cfg["mortar"])
    return True


def _grate(L, x, y, w, h, body, slot):
    L.rect(x, y, w, h, body)
    for xx in range(x + 1, x + w - 1, 2):
        L.vline(xx, y + 1, y + h - 2, slot)


def _flyer(L, x, y, w=4, h=3):
    L.rect(x, y, w, h, "white")
    L.hline(x, x + w - 1, y + h - 1, "paper")              # its fold / the shade under the far edge


def plaza(era):
    """One plaza tile, 192x192: the era's paving (wave5.Paving) plus a few small details, all decorative
    (<= 3:1 against the stone), never lettered, never gold, no barrier or fence, no line longer than one slab."""
    pav = Paving(era)
    cfg = pav.cfg
    L = Layer(PW, PH)
    L.rect(0, 0, PW, PH, cfg["tones"][0][0])
    draw_courses(L, pav, pav.plaza, seed=5800 + ERAS.index(era))
    r = random.Random(ERAS.index(era) + 580)
    if cfg["big"]:
        placed, last = 0, -9
        for ci in r.sample(range(1, len(pav.plaza) - 2), len(pav.plaza) - 3):
            if placed == 2:
                break
            if abs(ci - last) >= 5 and _big_stone(L, pav, r, ci):
                placed, last = placed + 1, ci
    # per-era details, sparse and irregular (never lettered, never gold)
    if era == "balfour":
        _grate(L, 118, 78, 9, 5, "slate", "suit_hi")             # a drain grate (slate on stone: 1.4:1)
        for (x, y) in ((27, 38), (151, 131), (83, 171)):
            _flyer(L, x, y)                                        # blank protest flyers (white on stone: 2.4:1)
        L.set(62, 117, "white"); L.set(63, 117, "paper")           # a torn corner
    elif era == "knesset":
        _grate(L, 42, 112, 9, 5, "stone_sh", "blonde_sh")
        _flyer(L, 140, 58, 5, 4)                                   # a dropped order paper, face down
        for (x, y) in ((96, 24), (22, 168), (171, 150)):           # olive leaves off the lawn (green on stone 2.0:1)
            L.set(x, y, "green"); L.set(x + 1, y, "green")
    elif era == "courthouse":
        _flyer(L, 35, 70, 4, 3)                                    # dropped pages
        _flyer(L, 139, 150, 3, 2)
        for (x, y) in ((70, 20), (160, 88), (18, 132), (110, 176)):   # floor-polish glints: a short white diagonal
            for k in range(3):
                L.set(x + k, y - k, "white")
    else:
        L.rect(60, 90, 4, 2, "grey"); L.set(60, 90, "slate")      # a dropped lanyard card, blank (grey on silver 1.6:1)
        for (x, y) in ((140, 30), (150, 36), (22, 150), (98, 166), (176, 118)):   # blossom petals (pink on silver 1.7:1)
            L.set(x, y, "pink")
    return L


# ------------------------------------------------------------------ the brawl cloud cue (26x20 at x4)
CW, CH = 26, 20
CPUFFS = [
    [(8, 11, 4), (12, 7, 4.5), (17, 8, 4), (19, 12, 3.5), (13, 13, 4.5), (7, 14, 3), (16, 15, 3)],
    [(7, 10, 4), (12, 7, 4), (17, 8, 4.5), (19, 13, 3.5), (13, 13, 4.5), (7, 14, 3.5), (16, 15, 3)],
    [(8, 11, 4.5), (12, 8, 4), (16, 7, 4), (19, 11, 3), (14, 13, 4.5), (6, 14, 3), (17, 15, 3.5)],
    [(8, 10, 3.5), (11, 7, 4.5), (17, 7, 4), (19, 12, 4), (13, 13, 4), (7, 15, 3.5), (16, 15, 3)],
]
# (kind, dx, dy) rays out of the cloud per frame: the same choreography as brawl_cloud, at half size
CLIMBS = [[("arm", -1, -1), ("leg", 1, 1)], [("arm", 1, -1), ("leg", -1, 1)],
          [("arm", -1, 1), ("arm", 1, 0)], [("arm", 0, -1), ("leg", 1, 1), ("arm", -1, 0)]]
CSPOTS = [[(21, 1), (14, 1)], [(1, 3), (12, 1)], [(21, 1), (2, 2)], [(1, 13), (23, 4)]]


def _carm(L, x, y, dx, dy):
    for i in range(3):                                     # a 2-px suit sleeve
        cx, cy = x + dx * i, y + dy * i
        L.rect(cx - 1, cy - 1, 2, 2, "suit_hi")
        L.set(cx, cy, "suit")
    cx, cy = x + dx * 3, y + dy * 3
    L.set(cx, cy, "white"); L.set(cx - (dy != 0), cy - (dx != 0), "white")   # the cuff
    fx, fy = x + dx * 4 + (dx > 0), y + dy * 4 + (dy > 0)
    L.rect(fx - 1, fy - 1, 3, 3, "skin")                    # the fist
    L.set(fx + 1, fy + 1, "skin_sh"); L.set(fx - 1, fy - 1, "skin_hi")


def _cleg(L, x, y, dx, dy):
    for i in range(2):
        cx, cy = x + dx * i, y + dy * i
        L.rect(cx - 1, cy - 1, 2, 2, "suit_hi")
    sx, sy = x + dx * 2, y + dy * 2
    x0 = sx - 1 if dx >= 0 else sx - 3
    L.rect(x0, sy - 1, 4, 2, "hair_dk")                    # the shoe
    L.set(x0 + 1, sy - 1, "slate")


def brawl_cue_frame(k):
    puffs = [(13 + (x - 13) * 0.85, 10 + (y - 11) * 0.8, r * 0.74) for (x, y, r) in CPUFFS[k]]   # room for the limbs
    cloud = Layer(CW, CH)
    for (cx, cy, r) in puffs:
        cloud.ellipse(cx, cy, r, r, "paper")
    back = Layer(CW, CH)
    for (kind, dx, dy) in CLIMBS[k]:
        x, y = 13, 11
        while cloud.get(x, y) is not None:
            x += dx; y += dy
        x -= dx; y -= dy
        reach = 5 if kind == "arm" else 3               # keep the fist / shoe (and its outline) inside the frame
        while not (2 <= x + dx * reach < CW - 2 and 2 <= y + dy * reach < CH - 2):
            x -= dx; y -= dy
        (_carm if kind == "arm" else _cleg)(back, x, y, dx, dy)
    back = back.outlined("outline", pad=0)             # outside the 2-px sleeves (inside would eat them)
    for y in range(CH):
        for x in range(CW):
            if cloud.get(x, y) != "paper":
                continue
            best = min(puffs, key=lambda p: ((x - p[0]) ** 2 + (y - p[1]) ** 2) / (p[2] ** 2))
            ddx, ddy = (x - best[0]) / best[2], (y - best[1]) / best[2]
            if ddx + ddy > 0.75:
                cloud.set(x, y, "stone_sh")
            elif ddx + ddy < -0.95:
                cloud.set(x, y, "white")
            elif ddx + ddy > 0.35:
                cloud.set(x, y, "stone")
    outline_inplace(cloud)
    L = Layer(CW, CH)
    L.paste(back, 0, 0)
    L.paste(cloud, 0, 0)
    fx = Layer(CW, CH)
    (px, py), (sx, sy) = CSPOTS[k]
    fx.rect(px, py, 3, 3, "white"); fx.set(px + 1, py + 1, "paper")     # a flying page
    for (dx, dy) in ((0, -1), (-1, 0), (0, 0), (1, 0), (0, 1)):          # a star
        fx.set(sx + dx, sy + dy, "white")
    L.paste(fx.outlined(pad=0), 0, 0)
    return L


# ------------------------------------------------------------------ build + proofs
def build():
    for era in ERAS:
        W = WING_W[era]
        for side in ("l", "r"):
            L = WINGS[era](side)
            edge = "its LAST column abuts stage-art column 0; tile it leftward" if side == "l" else \
                   "its FIRST column abuts stage-art column 179; tile it rightward"
            save(L, f"wing_{era}_{side}", "stage", mode="tile", pivot=[W if side == "l" else 0, 0],
                 extra={"artRow": 0, "period": W},
                 notes=f"Stage side wing (UX mobile-first A2), {'left' if side == 'l' else 'right'}: the {era} stage's art "
                       f"rows 0-229 continued past the 180-column art, a {W}x{WING_H} horizontal TILE (period {W}: a multiple "
                       f"of the era's own rhythm). Draw at x4 with its top on stage-art row 0; {edge} (x4, on the art "
                       "grid) out to the canvas edge. Under the lane (rows 230+), over the sky pads. Seam-exact against "
                       "the art's edge column and against itself.")
        save(plaza(era), f"plaza_{era}", "stage", mode="tile", extra={"artRow": PLAZA_ROW},
             notes=f"The plaza in front of the {era} stage (UX mobile-first A1): a {PW}x{PH} TILE, both axes. Draw it at x4 "
                   f"from stage-art row {PLAZA_ROW} (right under lane_{era}) down to the canvas bottom, across the whole "
                   f"canvas width, x-phase: tile col 0 on stage-art col 0 (mod {PW}), above the stage art (it replaces the "
                   "art's flat apron rows 258-319 and the padBottom below them), under everything else. Scenery: "
                   "Jerusalem-stone paving (2026-09-30, manual test A1; wave5.Paving, one layout with lane_<era>, whose "
                   "last course continues into rows 0-4): slabs of random length in 2-3 stone tones within one value "
                   "step, short broken mortar joints (never black, no line longer than one slab), chisel flecks, a few "
                   "decorative details (<= 3:1 against the stone); no row is one colour.")
    frames = [brawl_cue_frame(k) for k in range(4)]
    save(strip(frames), "brawl_cloud_cue", "events", frames=4, frame_w=CW, pivot=[CW // 2, CH - 2],
         notes="The brawl cloud cut for the STAGE CUE (the Animator's ask): brawl_cloud's 4-frame loop redrawn at "
               "26x20 so the cue draws at the stage's own x4 (104x80 logical, the same box as brawl_cloud at x2) and is "
               "crisp at every k. Same frames, order and timing as brawl_cloud (8 fps; reduced motion = frame 0); the "
               "same choreography of sleeves, fists, shoes, a page and a star at half size. No faces, no markers. "
               "brawl_cloud (52x40) stays for the thread's inline cloud at x4.")


STAGES = os.path.normpath(os.path.join(ROOT, "..", "..", "creative-pack", "art", "showcase", "out"))


def compose(era, cols, rows=466, lane=True, plaza_on=True):
    """The stage as the engine draws it at `cols` art columns: the art centred (stage_ox = floor((cols-180)/2)),
    the wings tiled out to the edges, the lane over rows 230-257 and the plaza from 258 to `rows`, all x-phased on
    art column 0. Returns (PIL image at 1x, art x of canvas column 0)."""
    from PIL import Image
    ox = (cols - SW) // 2
    img = Image.new("RGBA", (cols, rows), rgb("night") + (255,))
    art = Image.open(os.path.join(STAGES, f"stage_{era}.png")).convert("RGBA")
    pad_top = art.getpixel((0, 0))
    img.paste(Image.new("RGBA", (cols, rows), pad_top))          # the diorama's sky pads (padTop)
    img.alpha_composite(art, (ox, 0))
    wl, wr = WINGS[era]("l").to_image(), WINGS[era]("r").to_image()
    W = wl.width
    x = ox - W
    while x > -W:
        img.alpha_composite(wl, (x, 0)) if x >= 0 else img.paste(wl.crop((-x, 0, W, WING_H)), (0, 0))
        x -= W
    x = ox + SW
    while x < cols:
        img.paste(wr, (x, 0))
        x += W
    def tile(tex, y0, h):
        t = tex.width
        x = ox - ((ox + t - 1) // t) * t
        while x < cols:
            for y in range(y0, y0 + h, tex.height):
                img.paste(tex.crop((0, 0, t, min(tex.height, y0 + h - y))), (x, y))
            x += t
    if lane:
        tile(Layer_img(f"lane_{era}"), 230, 28)
    if plaza_on:
        tile(plaza(era).to_image(), PLAZA_ROW, rows - PLAZA_ROW)
    return img, -ox


def Layer_img(pid):
    from PIL import Image
    return Image.open(os.path.join(ROOT, "out", "ui", "stage", pid + ".png")).convert("RGBA")


def seam_report():
    """Per era and side: the rows where the wing's column next to the art differs from the art's edge column
    (a different swatch on both sides of the seam is a visible cut unless it continues an edge)."""
    from PIL import Image
    out = {}
    for era in ERAS:
        art = Image.open(os.path.join(STAGES, f"stage_{era}.png")).convert("RGBA")
        for side in ("l", "r"):
            w = WINGS[era](side).to_image()
            wc = w.width - 1 if side == "l" else 0
            ac = 0 if side == "l" else SW - 1
            diff = [y for y in range(WING_H) if w.getpixel((wc, y))[:3] != art.getpixel((ac, y))[:3]
                    and art.getpixel((ac, y))[3] == 255]
            out[f"{era}_{side}"] = diff
    return out


def proof():
    """proofs/kit-w7-mobile.png: every era at 215 columns (the widest phone) and at 260 (the wings tiling), with
    the lane and the plaza, at x2."""
    from PIL import Image
    shots = []
    for era in ERAS:
        for cols in (215, 260):
            shots.append(compose(era, cols)[0])
    gap = 6
    W = sum(s.width for s in shots) + gap * (len(shots) - 1)
    sheet = Image.new("RGBA", (W, 466), (255, 255, 255, 255))
    x = 0
    for s in shots:
        sheet.paste(s, (x, 0)); x += s.width + gap
    p = os.path.join(PROOFS, "kit-w7-mobile.png")
    sheet.resize((W * 2, 466 * 2), Image.NEAREST).save(p)
    # the brawl cue: brawl_cloud at x2 (today's cue) over brawl_cloud_cue at x4, both 104x80 per frame, on the bubble
    old = Image.open(os.path.join(ROOT, "out", "ui", "events", "brawl_cloud.png")).convert("RGBA")
    new = strip([brawl_cue_frame(k) for k in range(4)]).to_image()
    bw = 4 * 104 + 3 * 8
    cue = Image.new("RGBA", (bw + 16, 2 * 80 + 24), rgb("ui_bubble") + (255,))
    for k in range(4):
        cue.alpha_composite(old.crop((k * 52, 0, k * 52 + 52, 40)).resize((104, 80), Image.NEAREST), (8 + k * 112, 8))
        cue.alpha_composite(new.crop((k * CW, 0, k * CW + CW, CH)).resize((104, 80), Image.NEAREST), (8 + k * 112, 96))
    p2 = os.path.join(PROOFS, "kit-w7-brawl-cue.png")
    cue.resize((cue.width * 2, cue.height * 2), Image.NEAREST).save(p2)
    return p


if __name__ == "__main__":
    build()
    from kit import write_manifest
    print(write_manifest())
    print(proof())
    for k, v in seam_report().items():
        print("seam", k, len(v), "rows differ", v[:40])
