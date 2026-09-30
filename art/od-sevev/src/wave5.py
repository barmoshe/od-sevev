"""Wave 5: the art gaps the engine and views developers reported (2026-09-29), and the Jerusalem-stone paving.

  lane_<era>          the Suitcase lane's floor, one 192x28 tile per era (2026-09-30: was 32x28, before that 2x28)
  thermo_tube_short   lives in ui_meters.py (the tube is parametric now)
  spin_s01..s15       redrawn at 24x24 in icons24.py, saved by wave2.spin_cards

The lane. The Suitcase flies in the band S-116..S-4 under the stage, which is the stage art's apron
(creative-pack locations.py lower_band: art rows 230-320, a lip on top, flat below). With the new layout
that apron is no longer under a UX panel, so a flat dark band reads as missing art.

The paving (2026-09-30, manual test A1: "the plaza reads as worms, not stone"). The lane and the plaza
(wave7.plaza) are one floor, drawn from ONE layout per era (`paving(era)`): courses of slabs laid in running
bond with random lengths, so no joint lines up with the joint above it and nothing repeats inside the 192-px
period (a phone shows 180-215 art columns: at most 1.1 copies across, so no repeat can be spotted). Stone reads
as stone by slab-to-slab TONE, not by lines:
  - every slab takes one of the era's 2-3 stone tones (weighted), with a lit top-left edge and a sparse
    chisel fleck (Jerusalem stone's dressed face), all within one value step;
  - the joints are 1 px of MORTAR (a grey or honey one value step off the stone, never black, never the
    outline), short (one slab long) and broken (2-4 px gaps), so they never join into a line across the screen;
  - no cable, no meander, no line longer than one slab (the old press cable's 1-px ink meander lined up
    across the tiles into the "snakes" of the manual test).
The lane keeps the stage apron's lip (rows 0-3: the art's own lip, dither and shadow), then courses that grow
toward the viewer (3, 4, 5, 6 rows); its last course (seam on row 25) continues into the plaza's rows 0-4, with
the plaza's own joints and tones, so the lane and the plaza meet without a seam. Every slab tone keeps >= 4.5:1
against the Suitcase's outline and >= 3:1 against its maroon (asserted), so the flying Suitcase still reads.

Tile rows 0..27 = stage art rows 230..257 (art row 230 is the lip; the Magician's feet are row 219 =
S-156, so S = row 258). Tile col 0 = stage-art col 0 (mod 192): even, the lip dither's phase.
"""
import random

from pix import Layer
from kit import save
from palette import contrast

PAVE_W = 192                       # the floor's period (lane and plaza), art px
H = 28                             # the lane's rows
PLAZA_H = 192                      # the plaza tile's rows (wave7)
PLAZA_OFF = 5                      # the plaza's first seam row: its last course wraps, from its seam down to row 4
LANE_SEAMS = (7, 12, 18, 25)       # the lane's course seams (tile rows); the course under 25 continues into the plaza

LANES = {
    # era: (lip line, lip shadow)  -- the stage art's own apron lip (rows 0-3 of the tile, unchanged since wave 5)
    "balfour":    ("wood_dk", "wood"),
    "knesset":    ("stone_sh", "stone_sh"),
    "courthouse": ("teal_dk", "stone_sh"),
    "washington": ("slate", "grey"),
}

# The stone per era. tones: (swatch, weight) of the slabs; mortar: the joint (one value step off the stone);
# light / fleck: per tone, the lit top-left edge and the chisel fleck; bond: None = running bond with random
# lengths (lo, hi) per course band, or a fixed grid width (tiles / panels); course: the plaza's course height.
# v4 (Bar: "more Israel"): warm Jerusalem limestone, lamp-lit at Balfour, sunlit at the Knesset, polished inside the
# courthouse; Washington is not Jerusalem, so it gets pale concrete panels.
STONE = {
    "balfour": dict(   # Jerusalem stone at night, in lamp light: honey and ochre slabs, grey cement mortar
        tones=(("stone_sh", 64), ("blonde_sh", 36)), repair=("grey", 2),
        mortar="slate",
        light={"stone_sh": "blonde_sh", "blonde_sh": "stone", "grey": "silver"},        # grey: a cement repair
        fleck={"stone_sh": "blonde_sh", "blonde_sh": "stone_sh", "grey": "slate"},
        bond=None, course=12, big="blonde_sh"),
    "knesset": dict(   # sunlit Jerusalem stone: cream, honey-white and grey-white slabs, honey mortar
        tones=(("stone", 58), ("blonde", 26), ("paper", 16)),
        mortar="blonde_sh",
        light={"stone": "blonde", "blonde": "white", "paper": "white"},
        fleck={"stone": "blonde_sh", "blonde": "stone", "paper": "stone"},
        bond=None, course=12, big="blonde"),
    "courthouse": dict(  # polished limestone: long pale slabs in tall courses, fine grey joints, few flecks
        tones=(("paper", 56), ("stone", 30), ("receipt_sh", 14)), flecks=1, heights=[16] * 12, lens=(26, 48),
        mortar="grey",
        light={"paper": "white", "stone": "white", "receipt_sh": "white"},
        fleck={"paper": "receipt_sh", "stone": "paper", "receipt_sh": "paper"},
        bond=None, course=16, big=None),
    "washington": dict(  # pale concrete panels, scored expansion joints
        tones=(("silver", 80), ("receipt_sh", 14), ("paper", 6)), flecks=1, lit=(3, 7),
        mortar="grey",
        light={"silver": "white", "receipt_sh": "white", "paper": "white"},
        fleck={"silver": "grey", "receipt_sh": "grey", "paper": "grey"},
        bond=48, course=24, big=None),
}
ERAS = tuple(STONE)


def _cyc(a, b, w=PAVE_W):
    d = abs(a - b) % w
    return min(d, w - d)


def _bond(r, lo, hi, avoid, gap):
    """Joint x positions of one running-bond course: slab lengths in [lo, hi], wrapping at PAVE_W, every joint at
    least `gap` columns from every joint in `avoid` (the courses above and below). Built joint by joint, each
    landing only where it is allowed; restarts when the course cannot close."""
    ok = [all(_cyc(x, a) >= gap for a in avoid) for x in range(PAVE_W)]
    starts = [x for x in range(PAVE_W) if ok[x]]
    for _ in range(4000):
        start = r.choice(starts)
        js, x = [start], start
        while True:
            left = start + PAVE_W - x
            if lo <= left <= hi and (left > (lo + hi) // 2 or r.random() < 0.5):
                return sorted(j % PAVE_W for j in js)
            cand = [n for n in range(lo, hi + 1) if ok[(x + n) % PAVE_W] and start + PAVE_W - (x + n) >= lo]
            if not cand:
                break
            x += r.choice(cand)
            js.append(x)
    raise RuntimeError("no running bond fits")


def _slabs(js, r, tones, checker=None):
    """[(x, length, tone)] from joint positions; neighbours never share a tone unless it is the base tone.
    checker (an int: the course's parity + 2, or falsy): the first two tones alternate like a hall floor's tiles, the
    third replaces one tile in ten."""
    names = [t for t, _ in tones]
    weights = [w for _, w in tones]
    out = []
    for i, a in enumerate(js):
        b = js[(i + 1) % len(js)]
        n = (b - a) % PAVE_W or PAVE_W
        if checker:
            t = names[(i + checker) % 2] if r.random() > 0.1 else names[2]
        else:
            t = r.choices(names, weights)[0]
            while out and t != names[0] and out[-1][2] == t:
                t = r.choices(names, weights)[0]
        out.append((a, n, t))
    return out


class Paving:
    """One era's floor layout: the plaza's courses (tile rows, wrapping at PLAZA_H) and the lane's courses above
    them. A course = (seam row, [rows], [(x, length, tone)])."""
    def __init__(self, era):
        cfg = STONE[era]
        self.era, self.cfg = era, cfg
        r = random.Random(7300 + ERAS.index(era))
        self.r = r
        c = cfg["course"]
        if cfg["bond"]:                                  # tiles / panels: one course height
            heights = [c] * (PLAZA_H // c)
        elif "heights" in cfg:
            heights = list(cfg["heights"])
        else:                                            # stone: course heights 10 / 12 / 14, shuffled (sum 192)
            heights = [10] * 5 + [12] * 6 + [14] * 5
            r.shuffle(heights)
        n = len(heights)
        seams = [PLAZA_OFF + sum(heights[:i]) for i in range(n)]
        self.plaza = []
        prev = []
        first = None
        for i, s in enumerate(seams):
            rows = [(s + 1 + k) % PLAZA_H for k in range(heights[i] - 1)]
            if cfg["bond"]:                              # fixed-size tiles / panels on a grid
                js = list(range(3, PAVE_W, cfg["bond"]))
            else:
                avoid = prev + (first if (i == n - 1 and first) else [])
                js = _bond(r, *cfg.get("lens", (16, 38)), avoid, 5)
            if first is None:
                first = js
            prev = js
            self.plaza.append((s, rows, _slabs(js, r, cfg["tones"], cfg.get("checker") and i)))
        # a repair or two: a slab replaced in another stone (a municipal patch), never in the last course
        if "repair" in cfg:
            t, k = cfg["repair"]
            done = []                                    # (course, x centre): far apart, so they never pair up
            while len(done) < k:
                ci = r.randrange(1, n - 1)
                s0, rows0, sl = self.plaza[ci]
                j = r.randrange(len(sl))
                cx = sl[j][0] + sl[j][1] // 2
                if all(abs(ci - c) >= n // 3 and _cyc(cx, x) >= PAVE_W // 3 for c, x in done):
                    sl[j] = (sl[j][0], sl[j][1], t)
                    done.append((ci, cx))
        # the lane: courses under the lip (rows 4-6), then seams 7, 12, 18; the course under seam 25 is the plaza's
        # last course (its rows 0-4 in the plaza tile), so its joints and tones are the plaza's
        last = self.plaza[-1]
        last_js = [a for a, _, _ in last[2]]
        spans = [(None, [4, 5, 6], (8, 18)), (7, [8, 9, 10, 11], (10, 22)), (12, [13, 14, 15, 16, 17], (12, 28)),
                 (18, [19, 20, 21, 22, 23, 24], (14, 32))]
        self.lane = []
        below = last_js
        built = []
        for (s, rows, (lo, hi)) in reversed(spans):     # bottom-up, so each course avoids the one under it
            if cfg["bond"]:                              # the far courses: the same grid
                js = list(range(3, PAVE_W, cfg["bond"]))
            else:
                js = _bond(r, lo, hi, below, 4)
            below = js
            built.append((s, rows, _slabs(js, r, cfg["tones"], cfg.get("checker") and (n - 1 - len(built)) % 2 + 2)))
        self.lane = list(reversed(built)) + [(25, [26, 27], last[2])]


def _put(L, x, y, c):
    L.set(x % L.w, y % L.h, c)


def draw_courses(L, pav, courses, *, lit_rows=True, seed=0):
    """Paint courses onto a PAVE_W-wide layer (x and y wrap). Joints: 1-px mortar, one slab long, broken."""
    cfg = pav.cfg
    r = random.Random(seed)
    mortar = cfg["mortar"]
    for (seam, rows, slabs) in courses:
        for (a, n, t) in slabs:
            for y in rows:
                for i in range(n):
                    _put(L, a + i, y, t)
            # chisel flecks: ~3 % of the face, never on the lit edge row
            face = [(a + 1 + i, y) for y in rows[1:] for i in range(n - 1)]
            for (x, y) in r.sample(face, max(1, len(face) * cfg.get("flecks", 3) // 100)) if face else []:
                _put(L, x, y, cfg["fleck"][t])
            # the lit top-left edge: the top row for part of the slab (worn), and the left column's first rows
            if lit_rows and rows:
                k = r.randint(*cfg["lit"]) if "lit" in cfg else r.randint(max(2, n * 3 // 10), max(3, n * 7 // 10))
                for i in range(1, min(k, n - 1)):
                    _put(L, a + i, rows[0], cfg["light"][t])
                for y in rows[1:3] if len(rows) > 4 else rows[1:2]:
                    _put(L, a + 1, y, cfg["light"][t])
            # the vertical joint: mortar the course's height, one pixel sometimes left out (a filled joint)
            skip = r.choice(rows[1:-1]) if len(rows) > 3 and r.random() < 0.5 else None
            for y in rows:
                if y != skip:
                    _put(L, a, y, mortar)
            # the seam above the slab: mortar, broken by 2-4 px gaps where the stone meets tight
            if seam is not None:
                x = 0
                while x < n:
                    if x > 1 and x < n - 3 and r.random() < 0.14:
                        g = r.randint(2, 4)
                        for gx in range(x, min(n - 1, x + g)):
                            _put(L, a + gx, seam, t)
                        x += g
                        continue
                    _put(L, a + x, seam, mortar)
                    x += 1


def lane(era):
    line, shadow = LANES[era]
    pav = Paving(era)
    L = Layer(PAVE_W, H)
    base = pav.cfg["tones"][0][0]
    L.rect(0, 0, PAVE_W, H, base)
    draw_courses(L, pav, pav.lane, seed=9100 + ERAS.index(era))
    L.hline(0, PAVE_W - 1, 0, line)                # the lip (art row 230)
    for x in range(1, PAVE_W, 2):
        L.set(x, 1, line)                          # its dither (art row 231: line on odd x)
    L.hline(0, PAVE_W - 1, 2, shadow)              # the shadow the lip casts
    for x in range(0, PAVE_W, 2):
        L.set(x, 3, shadow)                        # ... softening into the floor (50 % checker)
    # a few small, low-contrast details per era (never lettered, never gold, never a line)
    if era == "balfour":                           # two blank flyers
        for (x, y) in ((37, 9), (131, 20)):
            L.rect(x, y, 3, 2, "white"); L.set(x + 2, y + 1, "paper")
    elif era == "knesset":                         # an olive leaf blown off the lawn
        L.set(58, 15, "green"); L.set(59, 15, "green")
    elif era == "courthouse":                      # a dropped page
        L.rect(121, 14, 3, 2, "white"); L.set(123, 15, "receipt_sh")
    else:                                          # a blossom petal
        L.set(88, 21, "pink")
    # v4: the lane is light stone, so the flying Suitcase separates by its dark outline and maroon body, not by its
    # pale rim (rim vs stone ~1:1): every slab tone keeps >= 4.5:1 against the outline and >= 3:1 against the maroon.
    for t, _ in pav.cfg["tones"]:
        assert contrast("outline", t) >= 4.5 and contrast("maroon", t) >= 3.0, (era, t)
    return L


def lanes():
    for era in LANES:
        save(lane(era), f"lane_{era}", "stage", mode="tile",
             notes=f"Suitcase-lane floor for the {era} stage: a {PAVE_W}x{H} TILE (2026-09-30, manual test A1: redrawn "
                   "as Jerusalem-stone paving with the plaza, one layout; was 32x28 with a 1-px ink press cable that "
                   "read as a black wavy line above the ticker). The stage art's apron lip on rows 0-3, then courses "
                   "of slabs in running bond (random lengths, 2-3 stone tones, a lit top-left edge, chisel flecks) "
                   "with short, broken, mortar-tone joints; the last course continues into plaza_<era>'s rows 0-4. "
                   "Draw it at x4 from the stage art's apron lip (art row 230 of stage_<era>, i.e. the art origin's "
                   "y + 920 logical px) across the whole canvas width, x-phase: tile col 0 on stage-art col 0 "
                   f"(mod {PAVE_W}; diorama._place_lane does this for any tile width), above the stage art and pads, "
                   "under the critters and the Suitcase. 28 rows = art rows 230-257 = S-112..S. Every slab tone keeps "
                   ">= 4.5:1 against the Suitcase's outline and >= 3:1 against its maroon.")


def build():
    lanes()


if __name__ == "__main__":
    build()
    from kit import write_manifest
    print(write_manifest())
