"""Leader select (design/leader-select-spec.md §9.2, Bar 2026-09-29): the 2D pieces every leader's round needs.

  prop_pen, prop_phone, prop_chair           wave-1 tap props (Bennett, Ben Gvir, Liberman)
  prop_ruler, prop_calculator, prop_coffee,  wave-2 tap props (Eisenkot, Smotrich, Deri, Golan). Smotrich's calculator
  prop_stapler                               and Deri's cup are in their refs (baked into the render): these two are
                                             for UI (chips, the picker) and never drawn over the body
  source_donor, source_funds                 the generic t4 / t5 money sources (+ 24x24 icon and locked silhouette)
  suitcase_plain (+ _norim)                  the Suitcase without the DOHA sticker (every round but Bibi's)
  spin_slot_A..E, G..I                       the 8 generic spin icons (F keeps s12's binder)
  pick_tile_{idle,pressed,focus,selected},   the picker (UX rtl-map §8.3-8.4): a 9-slice plate for avatar + name + party,
  pick_random                                every state a shape; the "הפתעה" tile's folded paper slip
  thermo_icon_press, chip_icon_press         the press skin's folded newspaper (UX rtl-map §4.3)

Tap props (the TA's contract, game/assets/sprites/CONTRACT.md §4c): d 1, at most 20x20 art px including the 1 px
`outline` and the pale `rim` (the rim marks on-stage touchables: the prop rides with the leader like the hat). Two
frames, rest + squash; the squash scales the fill about the grip (x 1.12, y 0.88), so the grip never leaves the
hand. `pivot` = the grip, drawn at the leader's `propMouth` point; `points.mouth` = where the coins leave, one [x, y]
per frame. Everything is a v2 swatch with binary alpha; no brand, app mark, party colour or emblem anywhere.
"""
import math
import os

from pix import Layer
from kit import save, strip, outline_inplace, with_rim, panel, chamfer, micro, grid_layer
import sources as SRC
from wave6 import _cel, _ellipse_set
from icons24 import digits

G_PROPS = "props"
MAXP = 20
SQ = (1.12, 0.88)


# ------------------------------------------------------------------ tap props
def _squash(F, grip, sx, sy, margin):
    """F scaled about grip (nearest, inverse-mapped: every target px copies one source px) onto F + margin per side."""
    S = Layer(F.w + 2 * margin, F.h)
    gx, gy = grip
    for ty in range(S.h):
        for tx in range(S.w):
            x = (tx - margin - gx) / sx + gx
            y = (ty - gy) / sy + gy
            xi, yi = int(math.floor(x + 0.5)), int(math.floor(y + 0.5))
            if 0 <= xi < F.w and 0 <= yi < F.h and F.px[yi][xi] is not None:
                S.px[ty][tx] = F.px[yi][xi]
    return S


def tap_prop(F, grip, mouth, pid, who, notes):
    """F = the fill (no outline). Returns and saves the 2-frame strip."""
    margin = 1
    rest = Layer(F.w + 2 * margin, F.h)
    rest.paste(F, margin, 0)
    sq = _squash(F, grip, SQ[0], SQ[1], margin)
    fr = [with_rim(x.outlined("outline", pad=1)) for x in (rest, sq)]
    w, h = fr[0].w, fr[0].h
    assert w <= MAXP and h <= MAXP, (pid, w, h)
    off = margin + 2
    piv = [grip[0] + off, grip[1] + 2]
    mx, my = mouth
    sm = [round((mx - grip[0]) * SQ[0] + grip[0]) + off, round((my - grip[1]) * SQ[1] + grip[1]) + 2]
    save(strip(fr), pid, G_PROPS, frames=2, frame_w=w, pivot=piv,
         extra={"points": {"mouth": [[mx + off, my + 2], sm]}, "density": 1, "leader": who},
         notes=f"{who}'s tap prop (leader-select-spec §5.2): d 1, {w}x{h} art px incl. outline + rim, 2 frames: f0 rest, "
               f"f1 squash (x{SQ[0]} / y{SQ[1]} about the grip; play f1 on the pointer-down frame, the hat's timing). "
               f"pivot = the grip: draw the frame with its pivot on the leader's propMouth point "
               f"(chars[c].anims[a].propMouth / density, per frame). points.mouth = where the coins leave. {notes}")
    return fr


def _pen():
    F = Layer(14, 14)
    F.rect(0, 5, 10, 9, "white")                                   # the small signed sheet
    F.vline(9, 6, 13, "paper"); F.hline(1, 9, 13, "paper")
    F.hline(1, 6, 7, "paper"); F.hline(1, 5, 9, "paper")           # printed lines
    for x, y in [(1, 11), (2, 10), (3, 11), (4, 12), (5, 11), (6, 10), (7, 11)]:
        F.set(x, y, "ink")                                          # the signature
    for i in range(9):                                              # the fat black pen, tip down-left
        x, y = 12 - i, 1 + i
        F.set(x, y, "hair_dk"); F.set(x + 1, y, "suit_dk"); F.set(x, y - 1, "suit")
        if i < 3:
            F.set(x + 1, y - 1, "suit_dk")
    F.set(13, 0, "suit"); F.set(12, 0, "suit")                      # the cap end
    F.set(11, 3, "silver"); F.set(10, 4, "silver")                  # the clip
    F.set(3, 10, "silver"); F.set(2, 11, "grey")                    # the nib
    return F, (7, 6), (2, 11)


def _phone():
    F = Layer(9, 14)
    F.rect(0, 0, 9, 14, "suit_dk")
    F.vline(0, 1, 12, "suit"); F.hline(1, 7, 0, "suit")             # light plane top-left
    F.vline(8, 1, 13, "night"); F.hline(1, 8, 13, "night")
    chamfer(F, 0, 0, 9, 14, 1)
    F.rect(1, 2, 7, 9, "sky")                                       # the screen: plain, no app marks
    F.set(1, 2, "white"); F.set(2, 2, "white"); F.set(1, 3, "white")
    arrow = ["..#....",                                              # a curved "forward" arrow, pointing left (RTL)
             ".##....",
             "######.",
             ".##...#",
             "..#...#",
             "......#",
             ".....##"]
    for j, r in enumerate(arrow):
        for i, c in enumerate(r):
            if c == "#":
                F.set(1 + i, 3 + j, "navy")
    F.hline(3, 5, 1, "suit")                                        # the earpiece
    F.hline(3, 5, 12, "suit")                                       # the home bar
    return F, (4, 10), (4, 0)


def _chair():
    F = Layer(14, 16)
    F.rect(3, 0, 8, 7, "suit")                                      # the backrest
    F.hline(4, 9, 0, "suit_hi"); F.vline(3, 1, 6, "suit_hi")
    F.vline(10, 1, 6, "suit_dk"); F.hline(4, 10, 6, "suit_dk")
    F.px[0][3] = None; F.px[0][10] = None
    F.set(5, 2, "slate"); F.set(6, 2, "slate")                       # a stitched seam glint
    F.vline(1, 5, 8, "slate"); F.vline(12, 5, 8, "slate")           # the armrests
    F.hline(1, 3, 5, "grey"); F.hline(10, 12, 5, "grey")
    F.rect(1, 8, 12, 3, "suit")                                     # the seat
    F.hline(1, 12, 8, "suit_hi"); F.hline(1, 12, 10, "suit_dk")
    F.rect(6, 11, 2, 2, "grey"); F.set(7, 11, "slate"); F.set(7, 12, "slate")   # the gas lift
    F.hline(2, 11, 13, "suit_dk"); F.hline(4, 9, 13, "suit")         # the 5-star base
    F.set(1, 14, "suit_dk"); F.set(12, 14, "suit_dk")
    for x in (0, 6, 12):                                            # three of the five wheels show
        F.rect(x, 14, 2, 2, "night"); F.set(x, 14, "suit")
    return F, (7, 15), (7, 8)


def _ruler():
    F = Layer(14, 5)
    F.rect(0, 0, 14, 5, "stone")
    F.hline(0, 13, 4, "stone_sh"); F.vline(13, 0, 4, "stone_sh")
    for x in range(1, 13):
        F.set(x, 0, "wood" if x % 2 == 0 else "stone")
        if x % 4 == 0:
            F.set(x, 1, "wood")
    F.set(0, 0, "stone"); F.set(0, 1, "white"); F.set(1, 1, "white")   # a glint
    return F, (7, 2), (7, 0)


def _calculator():
    F = Layer(10, 13)
    F.rect(0, 0, 10, 13, "suit_dk")
    F.vline(0, 0, 12, "suit"); F.hline(0, 9, 0, "suit")
    F.vline(9, 1, 12, "night"); F.hline(1, 9, 12, "night")
    chamfer(F, 0, 0, 10, 13, 1)
    F.rect(1, 1, 8, 3, "teal_hi"); F.hline(1, 8, 3, "teal")        # the display (plain, no digits)
    F.set(1, 1, "white")
    for r in range(3):
        for c in range(3):
            x, y = 1 + c * 3, 5 + r * 2 + r
            F.rect(x, y, 2, 2, "silver"); F.set(x + 1, y + 1, "grey")
    return F, (5, 11), (5, 1)


def _coffee():
    F = Layer(9, 15)
    F.rect(3, 1, 3, 2, "suit_dk"); F.hline(3, 5, 1, "suit")         # the lid's sip spout
    F.rect(0, 3, 9, 2, "suit_dk"); F.hline(1, 7, 3, "suit")         # the lid
    F.px[3][0] = None; F.px[3][8] = None
    for y in range(5, 15):                                          # the paper cup, tapering to the base
        t = (y - 5) // 4
        F.hline(1 + t, 7 - t, y, "white")
        F.set(7 - t, y, "paper")
    for y in range(8, 12):                                          # the sleeve
        t = (y - 5) // 4
        F.hline(1 + t, 7 - t, y, "wood")
        F.set(1 + t, y, "orange_sh"); F.set(7 - t, y, "wood_dk")
    return F, (4, 10), (4, 3)


def _stapler():
    F = Layer(14, 8)
    F.rect(0, 6, 14, 2, "suit"); F.hline(0, 13, 7, "suit_dk"); F.hline(1, 12, 6, "suit_hi")   # the base
    F.rect(2, 1, 11, 4, "slate")                                    # the top arm, steel
    F.hline(3, 12, 1, "grey"); F.set(4, 1, "silver"); F.set(5, 1, "silver"); F.vline(2, 1, 3, "grey")
    F.hline(2, 12, 4, "suit")
    F.rect(0, 2, 3, 3, "slate"); F.hline(0, 2, 2, "grey")           # the nose
    F.set(1, 5, "silver"); F.set(0, 5, "grey")                      # the staple exit
    F.rect(12, 2, 2, 4, "suit_dk"); F.set(12, 2, "suit")            # the hinge block
    return F, (7, 4), (1, 3)


PROPS = [
    ("prop_pen", "Bennett", _pen, "A fat black pen signing a small sheet (his pledges). Grip mid-barrel; coins leave at the nib."),
    ("prop_phone", "Ben Gvir", _phone, "A plain phone, a curved forward arrow on the screen (העברה), no app marks or colours. "
     "Grip low in the palm; coins leave at the top."),
    ("prop_chair", "Liberman", _chair, "An empty office swivel chair he won't sit in (לא יושב). It stands on the stage floor, "
     "pivot = the wheels' floor line: his propMouth is on the feet row, 6 art px screen-left of his legs. One chair, never at "
     "a table (style guide do/don't 13). Coins leave from the seat."),
    ("prop_ruler", "Eisenkot", _ruler, "A plain wooden ruler (ישר). It floats at his chest line beside his crossed arms; "
     "pivot = the centre."),
    ("prop_calculator", "Smotrich", _calculator, "A plain calculator (אין כסף), no digits. His is baked into his render "
     "(chars.smotrich.prop.baked): use this one for UI only (chips, the picker)."),
    ("prop_coffee", "Deri", _coffee, "A takeaway coffee with a sleeve and steam (☕, ידידי). His is baked into his render "
     "(chars.deri.prop.baked): use this one for UI only (the ☕ tap-buff chip)."),
    ("prop_stapler", "Golan", _stapler, "A plain desk stapler (איחוד), held in his hanging hand. Coins leave at the nose."),
]


def props():
    for pid, who, fn, notes in PROPS:
        F, grip, mouth = fn()
        tap_prop(F, grip, mouth, pid, who, notes)


# ------------------------------------------------------------------ generic money sources (t4, t5)
def _donor(flap):
    """A faceless figure in a suit (the no-photo stand-in's construction at source size) holding a plain envelope
    in front and a pen in the other hand. f1: the envelope's flap lifts."""
    W, H = 24, 36
    L = Layer(W, H)
    head = ("slate", "grey", "suit_hi")
    suit = ("suit_hi", "slate", "suit")
    shoe = ("suit_dk", "suit", "night")
    cx = 11.5
    legs = {(x, y) for y in range(24, 34) for x in list(range(7, 11)) + list(range(13, 17))}
    _cel(L, legs, *suit)
    for sx in (8.5, 15.5):
        _cel(L, {(x, y) for (x, y) in _ellipse_set(sx, 34, 3, 1.5) if y <= 35} | {(x, 35) for x in range(int(sx) - 2, int(sx) + 4)}, *shoe)
    jacket = set()
    for y in range(11, 27):
        hw = 4 + (y - 11) * 2 if y < 14 else 8.5
        jacket |= {(x, y) for x in range(int(cx - hw + 0.5), int(cx + hw + 0.5) + 1)}
    _cel(L, jacket, *suit)
    for y in range(11, 16):                                         # the shirt V and a dark tie
        w = (15 - y) / 2
        for x in range(int(cx - w + 0.5), int(cx + w + 0.5) + 1):
            L.set(x, y, "silver")
    L.vline(11, 12, 18, "suit_dk"); L.vline(12, 12, 18, "suit_dk")
    for side in (-1, 1):                                            # arms, bent forward to the waist
        arm = {(int(cx + side * 8 + dx + 0.5), y) for y in range(13, 22) for dx in (-1, 0, 1)}
        _cel(L, arm, *suit)
    _cel(L, _ellipse_set(cx, 5.5, 5, 5.5), *head)                   # the featureless head
    _cel(L, _ellipse_set(cx - 5.5, 6, 1, 1.5) | _ellipse_set(cx + 5.5, 6, 1, 1.5), *head)
    # the envelope, held at the waist in front (screen-left hand), plain: no stamp, no logo
    ex, ey = 1, 18
    L.rect(ex, ey, 10, 7, "white"); L.hline(ex, ex + 9, ey + 6, "paper"); L.vline(ex + 9, ey, ey + 6, "paper")
    if flap:                                                        # f1: the flap lifts open, 2 ap
        for i in range(5):
            L.set(ex + i, ey - 2 + (i // 2), "paper"); L.set(ex + 9 - i, ey - 2 + (i // 2), "paper")
        L.hline(ex + 4, ex + 5, ey, "paper")
    else:
        for i in range(5):
            L.set(ex + i, ey + 1 + i // 2, "paper"); L.set(ex + 9 - i, ey + 1 + i // 2, "paper")
    _cel(L, _ellipse_set(ex + 9.5, ey + 4, 1.5, 1.5), *head)       # the hand over it
    # the pen in the other (screen-right) hand
    _cel(L, _ellipse_set(cx + 8.5, 22.5, 1.5, 1.5), *head)
    for i in range(4):
        L.set(int(cx + 9 + i * 0.5), 21 - i, "hair_dk")
    L.set(int(cx + 11), 17, "silver")
    return L


def _funds(hop):
    """A fat lever-arch budget binder, a blank tab on its spine, coins spilling out of the top. f1: a coin hops."""
    W, H = 26, 36
    L = Layer(W, H)
    x0, y0 = 1, 8
    # the pages, stuffed, showing over the top edge
    for i, c in enumerate(("white", "paper", "white", "paper")):
        L.hline(x0 + 8, x0 + 22, y0 - 1 + i, c)
    # the spine (screen-left) and the cover: a steel-grey binder
    _cel(L, {(x, y) for x in range(x0, x0 + 8) for y in range(y0, y0 + 27)}, "suit", "suit_hi", "suit_dk")
    _cel(L, {(x, y) for x in range(x0 + 8, x0 + 24) for y in range(y0 + 2, y0 + 27)}, "slate", "grey", "suit_hi")
    L.rect(x0 + 2, y0 + 4, 4, 10, "white"); L.vline(x0 + 5, y0 + 4, y0 + 13, "paper")   # the blank tab
    L.hline(x0 + 2, x0 + 5, y0 + 13, "paper")
    _cel(L, _ellipse_set(x0 + 3.5, y0 + 20, 1.5, 2), "night", "outline", "night")          # the finger hole
    L.vline(x0 + 8, y0 + 2, y0 + 26, "suit_dk")                                           # the hinge line
    # coins spilling from the top
    for (cx, cy) in ((x0 + 12, y0 - 4), (x0 + 16, y0 - 5), (x0 + 20, y0 - 3)):
        L.ellipse(cx, cy, 2, 1.5, "gold"); L.set(cx - 1, cy - 1, "gold_hi"); L.set(cx + 1, cy + 1, "gold_sh")
    hy = y0 - 8 - (2 if hop else 0)                                                        # the hopping coin
    L.rect(x0 + 14, hy, 3, 3, "gold"); L.set(x0 + 14, hy, "gold_hi"); L.set(x0 + 16, hy + 2, "gold_sh")
    L.rect(x0 + 22, y0 + 4, 3, 3, "gold"); L.set(x0 + 22, y0 + 4, "gold_hi"); L.set(x0 + 24, y0 + 6, "gold_sh")  # one sliding down
    return L


def generic_sources():
    SRC.G = "sources"
    SRC.frame_pair(_donor(False), _donor(True), "donor", "תורם (כללי)", 700,
                   "the envelope's flap lifts 2 ap (the money is about to change hands)", (1, 4, 24, 24))
    SRC.frame_pair(_funds(False), _funds(True), "funds", "קופה (כללי)", 600,
                   "one coin hops 2 ap off the pile", (2, 6, 24, 24))


# ------------------------------------------------------------------ the plain Suitcase
def suitcase_plain():
    from props import suitcase
    s = suitcase(sticker=False)
    save(s, "suitcase_plain_norim", G_PROPS, notes="The plain Suitcase without the rim (cards, icons on light grounds).")
    r = with_rim(s)
    save(r, "suitcase_plain", G_PROPS, pivot=[r.w // 2, r.h // 2],
         notes="THE running gag, every round but Bibi's (content leaderSelect.suitcase.plainSprite): the kit Suitcase "
               "pixel for pixel with the DOHA sticker removed (the DOHA sticker is Bibi's only, spec §5.9). Maroon stays "
               "(the Suitcase is the one maroon thing), rim, 26x20, pivot and hit area as `suitcase`.")


# ------------------------------------------------------------------ the 8 generic spin icons (24x24)
N = 24


def _o(L):
    return L.outlined("outline", pad=1)


def _coin(L, cx, cy, r):
    L.ellipse(cx, cy, r, r, "gold")
    for y in range(L.h):
        for x in range(L.w):
            if L.get(x, y) == "gold":
                d = math.hypot(x - cx, y - cy)
                if d > r - 0.9:
                    L.set(x, y, "gold_sh" if (x - cx) + (y - cy) > 0 else "gold_hi")


def _plus(L, x, y, fg, bg):
    """A round badge with a plus (9x9)."""
    L.ellipse(x + 4, y + 4, 4, 4, bg)
    L.hline(x + 2, x + 6, y + 4, fg); L.vline(x + 4, y + 2, y + 6, fg)


def spin_A():                     # tapAdd: a coin with a plus
    C = Layer(N, N)
    c = Layer(18, 18); _coin(c, 8, 8, 7.5)
    for x, y in [(6, 5), (6, 6), (6, 7), (6, 8), (6, 9), (7, 10), (8, 10), (9, 10), (10, 9), (10, 8), (10, 7), (9, 5), (9, 6), (9, 7)]:
        c.set(x, y, "gold_sh")                                     # an embossed shekel-ish mark, no text
    C.paste(_o(c), 1, 3)
    b = Layer(9, 9); _plus(b, 0, 0, "white", "green_sh")
    C.paste(_o(b), 13, 1)
    return C


def spin_B():                     # tapBuff: a stopwatch
    C = Layer(N, N)
    w = Layer(18, 20)
    w.rect(7, 0, 4, 2, "grey"); w.set(7, 0, "silver")              # the crown button
    w.rect(8, 2, 2, 2, "slate")
    w.ellipse(8.5, 11.5, 8, 8, "silver")
    w.ellipse(8.5, 11.5, 6, 6, "white")
    for a in range(0, 360, 90):                                    # 4 ticks
        x = 8.5 + 5.2 * math.cos(math.radians(a)); y = 11.5 + 5.2 * math.sin(math.radians(a))
        w.set(int(round(x)), int(round(y)), "slate")
    w.line(9, 12, 12, 8, "ink"); w.set(9, 12, "red")               # the hand, running fast
    w.set(2, 8, "grey"); w.set(15, 8, "grey")
    C.paste(_o(w), 2, 1)
    return C


def spin_C():                     # offlineMult: a crescent moon over a small stack of coins (no star)
    C = Layer(N, N)
    m = Layer(14, 16)
    m.ellipse(7, 8, 7, 7.5, "stone")
    m2 = Layer(14, 16); m2.ellipse(10.5, 6, 6, 6.5, "stone")
    for y in range(16):
        for x in range(14):
            if m2.px[y][x] is not None:
                m.px[y][x] = None
    for y in range(16):
        for x in range(14):
            if m.px[y][x] == "stone" and (m.get(x + 1, y) is None or m.get(x, y + 1) is None):
                m.set(x, y, "stone_sh")
    m.set(2, 6, "white"); m.set(2, 7, "white")
    C.paste(_o(m), 1, 1)
    s = Layer(10, 8)
    for k in range(3):
        s.rect(0, 5 - k * 2, 10, 2, "gold"); s.hline(0, 9, 5 - k * 2, "gold_hi"); s.set(9, 6 - k * 2, "gold_sh")
    C.paste(_o(s), 12, 14)
    return C


def spin_D():                     # heat x0.75: a thermometer low + a down arrow
    C = Layer(N, N)
    t = Layer(7, 20)
    t.rect(2, 0, 3, 15, "white"); t.vline(4, 1, 14, "paper")
    t.rect(3, 10, 1, 6, "red")
    t.ellipse(3, 16.5, 3, 3, "red"); t.set(2, 15, "red_hi")
    for y in (3, 6, 9, 12):
        t.set(2, y, "slate")
    C.paste(_o(t), 3, 1)
    a = Layer(9, 14)
    a.rect(3, 0, 3, 8, "sky"); a.vline(3, 0, 7, "white")
    for i in range(5):
        a.hline(i, 8 - i, 8 + i, "sky")
    a.set(4, 12, "flag_hi")
    C.paste(_o(a), 12, 5)
    return C


def spin_E():                     # crit chance: a 4-point sparkle (never a 5- or 6-point star)
    C = Layer(N, N)
    s = Layer(17, 17)
    c = 8
    for i in range(9):
        w = i // 3                                                 # rays taper to points (concave sides)
        s.hline(c - w, c + w, c - 8 + i, "gold"); s.hline(c - w, c + w, c + 8 - i, "gold")
        s.vline(c - 8 + i, c - w, c + w, "gold"); s.vline(c + 8 - i, c - w, c + w, "gold")
    s.rect(c - 1, c - 1, 3, 3, "gold_hi"); s.set(c, c, "white")
    s.vline(c, c - 7, c - 2, "gold_hi"); s.hline(c - 7, c - 2, c, "gold_hi")
    s.vline(c, c + 2, c + 7, "gold_sh"); s.hline(c + 2, c + 7, c, "gold_sh")
    C.paste(_o(s), 1, 5)
    k = Layer(7, 7)
    k.hline(0, 6, 3, "gold_hi"); k.vline(3, 0, 6, "gold_hi"); k.set(3, 3, "white")
    C.paste(_o(k), 15, 1)
    return C


def spin_G():                     # +10% base this round: a mic broadcasting (the spins tab's two pink arcs)
    C = Layer(N, N)
    m = Layer(9, 20)
    m.ellipse(4, 4, 4, 4.5, "grey")
    for y in range(1, 9):
        for x in range(1, 8):
            if m.get(x, y) == "grey" and (x + y) % 2 == 0:
                m.set(x, y, "slate")
    m.set(2, 1, "silver"); m.set(1, 2, "silver")
    m.rect(3, 9, 3, 10, "suit_dk"); m.vline(3, 9, 18, "suit")
    m.hline(2, 6, 9, "silver")
    C.paste(_o(m), 11, 2)
    for r, col in ((5, "pink"), (8, "pink_sh")):                   # the arcs on the screen-left side (the talk goes RTL)
        for a in range(120, 241, 6):
            x = 12 + r * math.cos(math.radians(a)); y = 7 + r * math.sin(math.radians(a))
            C.set(int(round(x)), int(round(y)), col)
    return C


def spin_H():                     # income x1.5: a rising arrow over a x1.5 tag
    C = Layer(N, N)
    a = Layer(15, 12)
    pts = [(0, 11), (4, 7), (7, 9), (12, 3)]
    for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
        for o in (0, 1):
            a.line(x0, y0 + o, x1, y1 + o, "green")
    for i in range(4):
        a.hline(11 - i, 14, i, "lime"); a.set(14, i + 3, "lime")
    a.set(14, 0, "lime")
    C.paste(_o(a), 6, 1)
    tag = Layer(17, 9)
    tag.rect(0, 0, 17, 9, "white"); tag.hline(0, 16, 8, "paper"); tag.vline(16, 0, 8, "paper")
    tag.px[0][0] = None; tag.px[8][0] = None
    for (x, y) in [(2, 3), (4, 3), (3, 4), (2, 5), (4, 5)]:        # the multiplication sign
        tag.set(x, y, "ink")
    x = micro(tag, "1", 6, 2, "ink")
    tag.set(x, 6, "ink")
    micro(tag, "5", x + 2, 2, "ink")
    C.paste(_o(tag), 3, 13)
    return C


def spin_I():                     # base per rival card: a rival's steel card with a plus
    C = Layer(N, N)
    c = Layer(14, 18)
    c.rect(0, 0, 14, 18, "slate"); c.hline(0, 13, 0, "grey"); c.vline(0, 0, 17, "grey")
    c.hline(1, 13, 17, "suit"); c.vline(13, 1, 17, "suit")
    c.rect(2, 2, 10, 14, "night"); c.rect(2, 2, 10, 4, "suit_dk")
    for (x, y) in [(1, 1), (12, 1), (1, 16), (12, 16)]:
        c.set(x, y, "silver")
    c.ellipse(7, 10, 2, 2, "suit_hi"); c.rect(4, 13, 7, 2, "suit_hi")   # a faceless profile on the card
    C.paste(_o(c), 2, 4)
    b = Layer(9, 9); _plus(b, 0, 0, "white", "green_sh")
    C.paste(_o(b), 13, 1)
    return C


SPIN_SLOTS = [("A", "s01 tapAdd", spin_A), ("B", "s02 tapBuff", spin_B), ("C", "s03 offlineMult", spin_C),
              ("D", "s04 heat x0.75", spin_D), ("E", "s11 crit chance", spin_E), ("G", "s13 +10% base this round", spin_G),
              ("H", "s06 income x1.5", spin_H), ("I", "s05 base per rival card", spin_I)]


def spin_slots():
    for slot, what, fn in SPIN_SLOTS:
        L = fn()
        assert (L.w, L.h) == (N, N)
        save(L, f"spin_slot_{slot}", "spins",
             notes=f"Generic spin icon for slot {slot} ({what}; content leaderSelect.spinSlots): the fallback when a leader's "
                   "spin skin names no icon of its own. 24x24 at d 1 on card_plate, like spin_s01..s15. Slot F keeps "
                   "spin_s12 (shared as-is). No flag, emblem, party colour, text beyond digits.")


# ------------------------------------------------------------------ the picker kit
def pick_tiles():
    """UX rtl-map §8.3 / §8.4: the plate holds a round avatar, the name (white) and the party (#9e99ad, 5.2:1 on the
    ui_bubble face; ui_panel inner shadow 6.2:1). Four states, each with a non-colour channel: idle raised (a 1-row
    lip), pressed 1 art px down into it, focus a dashed white ring outside, selected a 1-art-px pale `rim` ring
    outside (the stage-touchable rim). Focus and selected are 1 art px larger on each side: grow the rect by 1."""
    W, H = 32, 32
    sl = [4, 4, 4, 5]

    def plate(pressed):
        L = Layer(W, H)
        if pressed:
            face = panel(W, H - 1, "ui_bubble", "ui_bub_hi", "ui_panel", lip=0)
            L.paste(face, 0, 1)
            L.hline(2, W - 3, 2, "ui_panel")                             # sunk: an inner shadow on the top row
        else:
            L.paste(panel(W, H, "ui_bubble", "ui_bub_hi", "ui_panel", lip=1, lip_c="ui_scrim"), 0, 0)
        return L

    def ring(L, col, dashed):
        R = L.outlined(col, pad=1)
        if dashed:
            k = 0
            for y in range(R.h):
                for x in range(R.w):
                    if R.px[y][x] == col and (x == 0 or y == 0 or x == R.w - 1 or y == R.h - 1 or L.get(x - 1, y - 1) is None):
                        if (x + y) % 3 == 2:
                            R.px[y][x] = None
                        k += 1
        return R

    idle = plate(False)
    base = dict(label="white", content=[3, 3, W - 6, H - 8])
    notes = ("Leader-picker tile plate (UX rtl-map §8.3, spec §9.2.5), {st}: a 9-slice {sl} (stretch). Holds the round "
             "avatar (y 3 art px), the name (`white` 13.6:1) and the party (#9e99ad 5.2:1 on the ui_bubble face). "
             "No party or bloc colour, no number. {extra}")
    save(idle, "pick_tile_idle", "picker", state="idle", slice=sl, **base,
         notes=notes.format(st="idle", sl=sl, extra="Raised: a 1-row ui_scrim lip under the face."))
    save(plate(True), "pick_tile_pressed", "picker", state="pressed", slice=sl, **base,
         notes=notes.format(st="pressed", sl=sl, extra="The face 1 art px down into the lip, a ui_panel inner shadow on top "
                             "(UX: 'pressed = a 1-art-px offset'). Move the tile's content down 1 art px with it."))
    save(ring(idle, "white", True), "pick_tile_focus", "picker", state="focus", slice=[s + 1 for s in sl],
         label="white", content=[4, 4, W - 6, H - 8],
         notes=notes.format(st="focus (keyboard focus, mouse hover)", sl=[s + 1 for s in sl],
                            extra="A dashed 1-px white ring outside the outline: the focus channel, a different shape "
                                  "from selected's solid rim. 34x34: draw at the tile rect grown by 1 art px."))
    save(ring(idle, "rim", False), "pick_tile_selected", "picker", state="selected", slice=[s + 1 for s in sl],
         label="white", content=[4, 4, W - 6, H - 8],
         notes=notes.format(st="selected (the commit frame)", sl=[s + 1 for s in sl],
                            extra="A solid 1-art-px pale `rim` ring outside the outline (UX §8.4), then the Animator's "
                                  "120 ms pop and the others dim. 34x34: draw at the tile rect grown by 1 art px."))
    R = Layer(24, 24)                                              # הפתעה: a folded ballot slip with a question mark
    R.rect(2, 3, 20, 18, "white")
    for i in range(10):                                            # the fold: the right half in shadow, a crease
        R.vline(12 + i, 3 + i // 3, 20 - i // 3, "paper")
    R.vline(12, 3, 20, "stone_sh")
    for x in range(2, 12):
        R.px[3][x] = "white"
    q = [".###.", "##.##", "...##", "..##.", "..#..", ".....", "..#.."]
    for j, r in enumerate(q):
        for i, c in enumerate(r):
            if c == "#":
                R.set(5 + i, 8 + j, "stamp")
    outline_inplace(R)
    save(R, "pick_random", "picker",
         notes="The הפתעה tile's icon (UX §8.3: 24 art at x4 = 96, or x2 = 48 when A = S, centred in the avatar slot): a "
               "folded paper slip with a violet question mark (Dubi picks). No letters, no party mark, never a slip going "
               "into a box (v1 do/don't 6).")


def press_icons():
    """UX rtl-map §4.3: the press skin's own non-colour sign (the gavel means the court): a folded newspaper, masthead
    bar and columns, in the magnifier's and the gavel's construction (outline, 3 bands)."""
    leg = {"k": "outline", "w": "white", "p": "paper", "s": "silver", "g": "grey", "i": "ink", "l": "slate"}
    big = [
        "kkkkkkkkk..",
        "kwwwwwwwkk.",
        "kiiiiiiiwpk",
        "kwwwwwwwwpk",
        "kwgwgggwwpk",
        "kwwwwwwwwpk",
        "kwgwgggwwpk",
        "kwwwwwwwwpk",
        "kwgwgggwwpk",
        "kpppppppppk",
        "kkkkkkkkkkk",
    ]
    small = [
        "kkkkkkk..",
        "kiiiiiwk.",
        "kwwwwwwpk",
        "kwgwggwpk",
        "kwwwwwwpk",
        "kwgwggwpk",
        "kwwwwwwpk",
        "kppppppppk"[:9],
        "kkkkkkkkk",
    ]
    save(grid_layer(big, leg), "thermo_icon_press", "meters", state="press",
         notes="The thermometer's icon in the press skin (every leader but Bibi; UX rtl-map §4.3): a folded newspaper, "
               "11x11 like thermo_icon_magnifier / _gavel. The gavel means the court and stays Bibi's.")
    save(grid_layer(small, leg), "chip_icon_press", "events",
         notes="9x9 folded newspaper for the press-day chip (chip_court with PRESS_CHIP_TITLE 'יום תחקיר'), at the RIGHT "
               "like chip_icon_gavel.")


def build():
    props(); generic_sources(); suitcase_plain(); spin_slots(); pick_tiles(); press_icons()


IDS = ([p[0] for p in PROPS] + ["source_donor", "source_donor_icon", "source_donor_icon_sil", "source_funds",
       "source_funds_icon", "source_funds_icon_sil", "suitcase", "suitcase_plain"] +
       [f"spin_slot_{s[0]}" for s in SPIN_SLOTS] + ["spin_s12"] +
       ["pick_tile_idle", "pick_tile_pressed", "pick_tile_focus", "pick_tile_selected", "pick_random",
        "thermo_icon_press", "chip_icon_press"])


def proof(dst=None, Z=6):
    """proofs/kit-leaders.png: every leader-select piece at x Z on the stage's plum and the UI's panel, the tap props
    with their pivot (red) and mouth (cyan) marked on both frames, and the picker tile 9-sliced at a real size with a
    leader stood on its floor."""
    import json
    from PIL import Image, ImageDraw
    import sheet
    from kit import ROOT, PROOFS
    from palette import rgb
    kit = {e["id"]: e for e in json.load(open(os.path.join(ROOT, "ui-kit.json")))["pieces"]}
    png = lambda i: Image.open(os.path.join(ROOT, kit[i]["file"])).convert("RGBA")
    cells = []
    for pid in IDS:
        e, im = kit[pid], png(pid)
        ground = rgb("plum") if e["group"] in ("props", "sources") else rgb("ui_panel")
        c = Image.new("RGBA", (im.width + 4, im.height + 4), ground + (255,))
        c.alpha_composite(im, (2, 2))
        c = c.resize((c.width * Z, c.height * Z), Image.NEAREST)
        d = ImageDraw.Draw(c)
        if "points" in e and "mouth" in e.get("points", {}):
            for f in range(e["frames"]):
                for (x, y), col in ((e["pivot"], (255, 60, 60)), (e["points"]["mouth"][f], (60, 230, 255))):
                    X, Y = (2 + f * e["frameW"] + x) * Z + Z // 2, (2 + y) * Z + Z // 2
                    d.rectangle([X - 2, Y - 2, X + 2, Y + 2], outline=col)
        cells.append((pid, c))
    import keyart
    # the tile at UX's 3x3 size (216 x (156 + A 128) logical = 54 x 71 art), an L avatar (32 at x4 = 32 art at
    # x1 here, the proof being in art px) and name/party lines in their colours
    import hebfont
    for st, who in (("idle", "liberman"), ("pressed", "golan"), ("focus", "bennett"), ("selected", "deri")):
        ent = kit[f"pick_tile_{st}"]
        grow = 1 if st in ("focus", "selected") else 0
        t = sheet.nine(png(f"pick_tile_{st}"), ent["slice"], 54 + 2 * grow, 71 + 2 * grow, ent.get("mode", "stretch"))
        dy = (1 if st == "pressed" else 0) + grow
        av = Image.open(os.path.join(keyart.SHOW, f"{who}_avatar_pick.png")).convert("RGBA")
        t.alpha_composite(av, (grow + 11, dy + 3))
        lab = Layer(t.width, t.height)
        hebfont.draw(lab, {"liberman": "ליברמן", "golan": "גולן", "bennett": "בנט", "deri": "דרעי"}[who],
                     t.width // 2, dy + 38, "white", align="center")
        hebfont.draw(lab, {"liberman": "ישראל ביתנו", "golan": "הדמוקרטים", "bennett": "ביחד", "deri": "ש״ס"}[who],
                     t.width // 2, dy + 49, "white", align="center")
        li = lab.to_image(1)
        px = li.load()
        for yy in range(li.height):                                 # the party line in UX's #9e99ad
            for xx in range(li.width):
                if px[xx, yy][3] and yy >= dy + 49:
                    px[xx, yy] = (0x9e, 0x99, 0xad, 255)
        t.alpha_composite(li)
        c = Image.new("RGBA", (t.width + 8, t.height + 8), rgb("ui_scrim") + (255,))
        c.alpha_composite(t, (4, 4))
        c = c.resize((c.width * Z, c.height * Z), Image.NEAREST)
        cells.append((f"pick_tile_{st} @54x71 (3x3, A=L)", c))
    W = 2400
    x = y = 0; rowh = 0; pos = []
    for pid, c in cells:
        if x + c.width > W:
            x, y = 0, y + rowh + 22; rowh = 0
        pos.append((pid, c, x, y)); x += c.width + 12; rowh = max(rowh, c.height)
    out = Image.new("RGBA", (W, y + rowh + 22), (20, 16, 30, 255))
    d = ImageDraw.Draw(out)
    for pid, c, x, y in pos:
        out.alpha_composite(c, (x, y + 16)); d.text((x, y + 2), pid, fill=(255, 255, 255))
    dst = dst or os.path.join(PROOFS, "kit-leaders.png")
    out.save(dst)
    return dst


if __name__ == "__main__":
    build()
    from kit import write_manifest
    print(write_manifest())
    print(proof())
