"""Widgets: the Cottage Index cup (8 depletion frames) and the Ben Gurion departure board.

Cottage Index (brief round 2; UX 3.2 #4; copy deck H-cottage): the cup 'loses a pixel' each time
the treasury crosses x10 (1K, 10K, 100K, ...). The joke is literal first, then it inflates:
cumulative missing pixels per frame = 0, 1, 3, 6, 10, 16, 24, 34. Frame 1 really is ONE pixel,
punched where the eye lands (the white front of the tub), so the ticker line is true.

Departure board (brief round 2; pitch 13: stage-background art, diegetic): squeezing the taxpayer
and the high-tech worker fills a Ben Gurion departures board. The joke is on the policy, never on
the people leaving: no faces, no names, only destinations and times.
"""
import random

from pix import Layer
from kit import save, strip, outline_inplace, grid_layer, chamfer
import hebfont

G = "widgets"

CUP_W, CUP_H = 16, 18
MISSING = [0, 1, 3, 6, 10, 16, 24, 34, 46, 62, 82, 106, None]   # None = every pixel gone (frame 12)


def cup():
    L = Layer(CUP_W, CUP_H)
    # the peeled foil lid: a disc leaning back behind the cup (drawn first, so the curds overlap it)
    lid = ["..ooo..",
           ".osssso",
           "oswsssg",
           "ossssgo",
           ".osssgo",
           "..osgo.",
           "...oo.."]
    for j, r in enumerate(lid):
        for i, c in enumerate(r):
            if c != ".":
                L.set(9 + i, j, {"o": "grey", "s": "silver", "w": "white", "g": "grey"}[c])
    # tub: tapers toward the base
    cx = 7.5
    for y in range(8, 17):
        hw = 7.0 - (y - 8) * 0.28
        for x in range(CUP_W):
            if abs(x + 0.5 - (cx + 0.5)) <= hw:
                L.set(x, y, "white")
        xr = int(cx + hw)
        L.set(xr, y, "paper"); L.set(xr - 1, y, "paper")
    # label band (a generic blue band: no brand, no text)
    for y in (12, 13):
        for x in range(CUP_W):
            if L.get(x, y) in ("white", "paper"):
                L.set(x, y, "sky" if y == 12 else "flag_hi")
    # rim and the mouth full of curds
    L.ellipse(7.5, 8, 7.2, 1.6, "silver")
    L.ellipse(7.5, 7.6, 6.0, 1.0, "white")
    # curd mound: four lumps above the rim, each with its own shadow = 'cottage', not 'yoghurt'
    for (bx, by, r) in [(3.3, 6.6, 1.6), (6.4, 5.2, 1.9), (9.6, 5.6, 1.7), (12.2, 6.8, 1.5)]:
        L.ellipse(bx, by, r, r, "white")
    for (x, y) in [(4, 7), (7, 6), (8, 6), (10, 7), (13, 7), (5, 7), (2, 7)]:
        L.set(x, y, "paper")
    for (x, y) in [(6, 4), (9, 5), (3, 6)]:
        L.set(x, y, "white")
    outline_inplace(L)
    return L


def cup_frames():
    base = cup()
    interior = [(x, y) for y in range(CUP_H) for x in range(CUP_W)
                if base.get(x, y) not in (None, "outline")]
    rnd = random.Random(2710)
    first = (7, 10)                               # the literal first pixel: dead centre of the white tub front
    rest = [p for p in interior if p != first]
    # later losses bias toward the curds (top) and the lit side, so the cup 'empties' as it erodes
    rest.sort(key=lambda p: (p[1] + rnd.random() * 9))
    order = [first] + rest
    frames = []
    for k, n in enumerate(MISSING):
        F = base.copy()
        if n is None:
            # 'מדד הקוטג׳: 0' (trophy a_cottage): nothing is left but a dotted ghost of the outline, so the HUD
            # slot never silently vanishes
            gh = Layer(CUP_W, CUP_H)
            for y in range(CUP_H):
                for x in range(CUP_W):
                    if base.get(x, y) == "outline" and (x + y) % 2 == 0:
                        gh.px[y][x] = "slate"
            frames.append(gh)
            continue
        for (x, y) in order[:n]:
            F.px[y][x] = None
        frames.append(F)
    save(strip(frames), "cottage_cup", G, frames=len(frames), frame_w=CUP_W, pivot=[8, 17],
         notes="Cottage Index (מדד הקוטג׳), 13 states (Animator asked >= 12). Frame k = the k-th x10 of lifetime treasury: "
               "frame 1 at 1,000 ₪ ... frame 12 at 10^14 ₪ = trophy a_cottage 'מדד הקוטג׳: 0' (a dotted ghost of the cup). "
               "Cumulative missing pixels 0,1,3,6,10,16,24,34,46,62,82,106 of 131, then all: literally one pixel first, then inflation. "
               "HUD corner, 50% alpha idle / 100% for 3 s on a drop (UX). Holes are true alpha 0.")
    px = Layer(1, 1); px.set(0, 0, "white")
    save(px, "cottage_pixel", G, notes="The pixel that just left: the engine drops it from the hole with the '−1' puff "
         "(motion is the Animator's). Recolour to the hole's source colour if the TA prefers; white matches frame 1's.")


# ------------------------------------------------------------------ departure board
DEST = [("ליסבון", "09:10"), ("ברלין", "09:25"), ("אתונה", "09:40")]   # never early-morning times near 06:29 (Bar: no October 7 echoes)
BW, BH = 72, 48


def board(n_lit):
    L = Layer(BW, BH)
    L.rect(0, 0, BW, BH, "suit_dk")                                   # bezel
    L.hline(1, BW - 2, 1, "suit")
    L.rect(2, 2, BW - 4, 11, "ui_panel")                              # header
    hebfont.draw(L, "המראות", BW - 13, 3, "white", align="right")
    plane = ["...#...", "..###..", "#######", "..###..", "...#...", "..###.."]
    for j, r in enumerate(plane):
        for i, c in enumerate(r):
            if c == "#":
                L.set(BW - 11 + i, 4 + j, "white")
    L.rect(2, 13, BW - 4, BH - 15, "outline")                         # the black flap field
    for r in range(3):
        y = 15 + r * 11
        # flap tiles: destination slot (right, 7 cells) and time slot (left, 5 cells)
        for c in range(7):
            x = BW - 5 - (c + 1) * 6
            L.rect(x, y, 5, 9, "night")
            L.hline(x, x + 4, y + 4, "ui_scrim")                      # the split line of a split-flap
        for c in range(5):
            x = 4 + c * 5
            L.rect(x, y, 4, 9, "night")
            L.hline(x, x + 3, y + 4, "ui_scrim")
        if r < n_lit:
            dest, t = DEST[r]
            hebfont.draw(L, dest, BW - 6, y, "orange", align="right")
            hebfont.draw(L, t, 5, y, "orange", align="left")
            L.rect(28, y + 3, 2, 2, "orange")                         # the 'departed' lamp
            for yy in (y + 4,):                                      # keep the flap split visible through text
                for xx in range(4, BW - 5):
                    if L.get(xx, yy) == "orange" and (xx % 5 == 3):
                        L.set(xx, yy, "orange_sh")
        else:
            L.rect(28, y + 3, 2, 2, "suit")
    chamfer(L, 0, 0, BW, BH, 1)
    outline_inplace(L)
    return L


def depboard():
    frames = [board(k) for k in range(4)]
    save(strip(frames), "depboard", G, frames=4, frame_w=BW,
         notes="Ben Gurion 'המראות' board, stage-background prop (decorative class: no rim). Frame k = k departures "
               "shown (0..3), driven by the taxpayer / high-tech squeeze; prestige never resets it (brief round 2). "
               "Amber = orange (never gold: gold is money). Destinations are cities, never people.")


def build():
    cup_frames(); depboard()


if __name__ == "__main__":
    build()
    from kit import write_manifest
    print(write_manifest())
