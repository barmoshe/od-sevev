"""The "עוד סבב" mark, app icon and logo lockup (v5, 2026-09-30, Bar: "fix it, be creative, make an icon and a logo").

Why v5: the Home Screen showed Godot's robot, because the web export builds its apple-touch-icon from the project
icon (`application/config/icon`) and that was never set. The icon the export should have used, the ring of eight heads,
also blurs at 60 px: eight faces in 16 art px each read as a ring of dots on a phone. v5 is one idea at icon size.

**The mark: the round comes out of the hat and goes back in.** The Magician's top hat, mouth up. A thick gold "again"
loop rises out of it on the left, arcs over, and dives back in on the right, arrowhead first: the election he pulls
out of the hat, forever. Inside the loop, a blank ballot slip and a shekel fly UP and away (style guide v1 do/don't
6: slips fly up, never into a box). No text, no faces, no flag, no star; party-neutral (§2.4).

**The logo: the wordmark's ס is the loop.** Samekh is the round letter, so in the lockup it becomes the same gold
arrow, cut to the ס's box, while the rest stays the approved v2 wordmark (gold, extruded, outline, rim).

All on the graphic tier (palette.py only), drawn at art px, upscaled nearest-neighbour by an integer only:
  icon   64x64 art x16 = 1024 (master icon-128-art.png at x2, the pipeline's input); 60 / 29 px LANCZOS checks
  mark   the icon without its field, transparent, for the lockup and the splash
  logo   mark + wordmark-with-loop, horizontal (mark on the right: it reads first in RTL) and stacked
Build:  python3 logo.py   (build_all.py runs it through keyart.build())
"""
import math
import os
from PIL import Image

from pix import Layer
from letters import glyph
from kit import OUT, PROOFS
from wordmark import FILL

KEY = os.path.join(OUT, "key")
N = 64                       # icon art px
CX, CY = 32, 26              # the loop's centre
R_IN, R_OUT = 11.0, 17.0     # the loop band (6 art px: holds at 29 px)
GAP = (24, 120)              # screen degrees (0 = right, 90 = down) left open: the head dives at the mouth's right


# ---------------------------------------------------------------------------------------------- helpers
def _tri(p, a, b, c):
    def s(p1, p2, p3):
        return (p1[0] - p3[0]) * (p2[1] - p3[1]) - (p2[0] - p3[0]) * (p1[1] - p3[1])
    d1, d2, d3 = s(p, a, b), s(p, b, c), s(p, c, a)
    neg = d1 < 0 or d2 < 0 or d3 < 0
    pos = d1 > 0 or d2 > 0 or d3 > 0
    return not (neg and pos)


def _shade_gold(m):
    """Cel-shade a pixel set like the wordmark: gold_hi on top/left edges, gold_sh on bottom/right, white glint."""
    out = {}
    for (x, y) in m:
        up, dn = (x, y - 1) in m, (x, y + 1) in m
        lf, rt = (x - 1, y) in m, (x + 1, y) in m
        c = FILL["body"]
        if not dn or not rt:
            c = FILL["sh"]
        if not up or not lf:
            c = FILL["hi"]
        if not up and not lf:
            c = FILL["glint"]
        out[(x, y)] = c
    return out


def loop_mask(cx, cy, r_in, r_out, gap, head=True, head_w=4.0, head_len=None):
    """The 'again' arrow: a clockwise ring with `gap` (screen degrees) open, and an arrowhead on the gap's
    clockwise end pointing along the direction of travel. Returns a set of (x, y)."""
    m = set()
    r_mid = (r_in + r_out) / 2
    band = r_out - r_in
    head_len = head_len if head_len is not None else band * 1.35
    x0, x1 = int(cx - r_out - head_w - 2), int(cx + r_out + head_w + 3)
    y0, y1 = int(cy - r_out - head_w - 2), int(cy + r_out + head_w + 3)
    for y in range(y0, y1):
        for x in range(x0, x1):
            dx, dy = x + 0.5 - cx, y + 0.5 - cy
            dd = math.hypot(dx, dy)
            a = math.degrees(math.atan2(dy, dx)) % 360
            if r_in <= dd <= r_out and not (gap[0] <= a <= gap[1]):
                m.add((x, y))
    if head:
        t = math.radians(gap[0])                    # the clockwise end of the ring = the gap's start angle
        bx, by = cx + r_mid * math.cos(t), cy + r_mid * math.sin(t)
        tx, ty = -math.sin(t), math.cos(t)          # clockwise tangent in screen coordinates
        nx, ny = math.cos(t), math.sin(t)
        hw = band / 2 + head_w
        A = (bx + nx * hw, by + ny * hw)
        B = (bx - nx * hw, by - ny * hw)
        C = (bx + tx * head_len, by + ty * head_len)
        # cut the ring's end square at the head's base so the band doesn't poke through
        for y in range(y0, y1 + 8):
            for x in range(x0 - 8, x1 + 8):
                p = (x + 0.5, y + 0.5)
                if _tri(p, A, B, C):
                    m.add((x, y))
    return m


def paint(L, pts, c):
    for (x, y) in pts:
        L.set(x, y, c)


def extrude(m, d, far="wood_dk", near="orange_sh"):
    """The wordmark's down-right extrusion, as {(x, y): colour} behind the mask."""
    out = {}
    for k in range(d, 0, -1):
        c = far if k > 1 else near
        for (x, y) in m:
            if (x + k, y + k) not in m:
                out[(x + k, y + k)] = c
    return out


# ---------------------------------------------------------------------------------------------- the mark
def slip(L, cx, cy, w, h, deg):
    """A blank ballot slip: a white paper rectangle rotated by `deg`, a paper edge and one printed flag-blue rule."""
    t = math.radians(deg)
    ct, st = math.cos(t), math.sin(t)
    R = int(max(w, h)) + 2
    for y in range(int(cy) - R, int(cy) + R + 1):
        for x in range(int(cx) - R, int(cx) + R + 1):
            dx, dy = x + 0.5 - cx, y + 0.5 - cy
            u, v = dx * ct + dy * st, -dx * st + dy * ct
            if abs(u) <= w / 2 and abs(v) <= h / 2:
                c = "white"
                if abs(v) > h / 2 - 1.0 or abs(u) > w / 2 - 1.0:
                    c = "paper"
                elif abs(v - (-h / 2 + 2.2)) < 0.55 and abs(u) < w / 2 - 2.2:
                    c = "flag"
                L.set(x, y, c)


COIN = [
    ".hgg.",
    "hgggs",
    "hgsgs",
    "ggggs",
    ".sss.",
]


def _grid(L, rows, x, y, legend):
    for j, row in enumerate(rows):
        for i, ch in enumerate(row):
            if ch in legend:
                L.set(x + i, y + j, legend[ch])


def mark(w=N, h=N, ox=0, oy=0):
    """The mark on a transparent layer (outline + rim included). ox/oy shift it inside a bigger canvas."""
    L = Layer(w, h)
    hx, brim_y = CX + ox, 44 + oy                     # the hat's centre line and the brim's centre row
    cx, cy = CX + ox, CY + oy

    # 1. the back half of the brim and the dark mouth (behind the loop's ends)
    for y in range(brim_y - 5, brim_y + 1):
        for x in range(hx - 17, hx + 17):
            ex = ((x + 0.5 - hx) / 16.0) ** 2 + ((y + 0.5 - brim_y) / 4.6) ** 2
            if ex <= 1:
                L.set(x, y, "suit" if ex > 0.55 else "outline")
    # 2. what flies out: a slip and a shekel, rising through the loop. They sit inside the loop's hole, on their
    # own layer with an outline and no rim (a rim would clump them into one pale blob at 60 px)
    F = Layer(w, h)
    slip(F, cx + 0.5, cy - 1.5, 10, 7, -18)
    _grid(F, COIN, cx - 6, cy + 3, {"h": "gold_hi", "g": "gold", "s": "gold_sh"})
    F = F.outlined("outline", pad=0)
    for (sx, sy) in ((cx + 5, cy + 5), (cx - 5, cy - 6)):          # two sparks
        for (dx, dy) in ((0, 0), (1, 0), (-1, 0), (0, 1), (0, -1)):
            F.set(sx + dx, sy + dy, "gold_hi" if (dx, dy) == (0, 0) else "white")
    # 3. the loop, extruded and shaded like the wordmark
    lm = loop_mask(cx, cy, R_IN, R_OUT, GAP, head_w=4.6, head_len=9.5)
    for p, c in extrude(lm, 2).items():
        L.set(*p, c)
    for p, c in _shade_gold(lm).items():
        L.set(*p, c)
    # 4. the hat's body (the crown, pointing down) and the front half of the brim, over the loop's ends
    top, bot = brim_y + 1, brim_y + 16
    for y in range(top, bot + 1):
        k = (y - top) / (bot - top)
        half = 11 - round(k * 1.5)                    # a slight taper to the crown
        for x in range(hx - half, hx + half):
            c = "suit_dk"
            if x <= hx - half + 2:
                c = "suit_hi" if x == hx - half + 1 else "suit"
            elif x >= hx + half - 3:
                c = "ink"
            if 3 <= y - top <= 5:                      # the band, the Magician's flag blue
                c = "flag_hi" if x <= hx - half + 2 else ("flag_dk" if x >= hx + half - 3 else "flag")
            if y == bot:
                c = "ink"
            L.set(x, y, c)
    for y in range(brim_y, brim_y + 6):
        for x in range(hx - 17, hx + 17):
            ex = ((x + 0.5 - hx) / 16.0) ** 2 + ((y + 0.5 - brim_y) / 4.6) ** 2
            if ex <= 1 and y + 0.5 >= brim_y + 0.5:
                inner = ((x + 0.5 - hx) / 12.5) ** 2 + ((y + 0.5 - brim_y) / 2.6) ** 2
                if inner > 1 or y > brim_y + 1:
                    c = "suit_hi" if y <= brim_y + 2 and x < hx + 6 else ("suit" if y <= brim_y + 3 else "suit_dk")
                    L.set(x, y, c)
    L = L.outlined("outline", pad=0)
    L = L.outlined("rim", pad=0)
    for y in range(h):                                 # no rim inside the loop's hole: the rim is for the silhouette
        for x in range(w):
            if L.px[y][x] == "rim" and y < brim_y - 5 and math.hypot(x + 0.5 - cx, y + 0.5 - cy) < R_IN:
                L.px[y][x] = None
    F.paste(L, 0, 0)
    return F


# ---------------------------------------------------------------------------------------------- the icon
def field(w=N, h=N):
    """Flag blue with a soft follow-spot and a darker, dithered edge: the stage the mark stands on."""
    L = Layer(w, h, fill="flag")
    for y in range(h):
        for x in range(w):
            dd = math.hypot(x + 0.5 - w / 2, y + 0.5 - (h / 2 - 2))
            if dd < 19:
                L.set(x, y, "flag_hi")
            elif dd < 23 and (x + y) % 2 == 0:
                L.set(x, y, "flag_hi")
            elif dd > 33 and (x + y) % 2 == 0:
                L.set(x, y, "flag_dk")
            if dd > 38:
                L.set(x, y, "flag_dk")
    return L


def icon(key=KEY, proofs=PROOFS):
    F = field()
    F.paste(mark(), 0, 0)
    img = F.to_image(1)
    os.makedirs(key, exist_ok=True)
    img.resize((N * 2, N * 2), Image.NEAREST).save(os.path.join(key, "icon-128-art.png"))  # the pipeline's master
    big = img.resize((N * 16, N * 16), Image.NEAREST).convert("RGB")
    big.save(os.path.join(key, "icon-1024.png"))
    s60 = big.resize((60, 60), Image.LANCZOS)
    s60.save(os.path.join(key, "icon-60.png"))
    os.makedirs(proofs, exist_ok=True)
    s60.resize((240, 240), Image.NEAREST).save(os.path.join(proofs, "icon-60-zoomed.png"))
    big.resize((29, 29), Image.LANCZOS).resize((232, 232), Image.NEAREST).save(os.path.join(proofs, "icon-29-zoomed.png"))
    return img


# ---------------------------------------------------------------------------------------------- the logo
def samekh_loop(H, S):
    """A ס-sized 'again' loop for the wordmark: the same box and stroke as letters.glyph('ס')."""
    _, W = glyph("ס", H, S)
    r_out = min(W, H) / 2
    # the head at the top, pointing right (clockwise), poking one stroke above the cap line like a flourish
    m = loop_mask(W / 2, H / 2, r_out - S, r_out, (280, 345), head_w=S * 1.0, head_len=S * 2.2)
    return m, W


def word_loop(text, H, S, gap=None):
    """letters.word, with every ס drawn as the loop."""
    gap = gap if gap is not None else max(1, S // 2 + 1)
    x, m = 0, set()
    for ch in text[::-1]:
        if ch == "ס":
            g, w = samekh_loop(H, S)
        else:
            g, w = glyph(ch, H, S)
        for (gx, gy) in g:
            m.add((x + gx, gy))
        x += w + gap
    return m


def wordmark_loop(text="עוד סבב", H=22, S=4, ext=3, rim="rim"):
    """The v2 wordmark's treatment (wordmark.render) on word_loop's mask."""
    m = word_loop(text, H, S)
    xs, ys = [p[0] for p in m], [p[1] for p in m]
    m = {(x - min(xs), y - min(ys)) for (x, y) in m}
    w, hh = max(xs) - min(xs) + 1, max(ys) - min(ys) + 1
    pad = ext + 3
    L = Layer(w + 2 * pad, hh + 2 * pad)
    ox, oy = pad - 1, pad - 1
    for p, c in extrude(m, ext, FILL["ext"][1], FILL["ext"][0]).items():
        L.set(ox + p[0], oy + p[1], c)
    for p, c in _shade_gold(m).items():
        L.set(ox + p[0], oy + p[1], c)
    L = L.outlined("outline", pad=0)
    if rim:
        L = L.outlined(rim, pad=0)
    return _trim(L)


def _trim(L):
    xs = [x for y in range(L.h) for x in range(L.w) if L.px[y][x] is not None]
    ys = [y for y in range(L.h) for x in range(L.w) if L.px[y][x] is not None]
    T = Layer(max(xs) - min(xs) + 1, max(ys) - min(ys) + 1)
    for y in range(T.h):
        for x in range(T.w):
            T.px[y][x] = L.px[y + min(ys)][x + min(xs)]
    return T


def lockups(key=KEY):
    mk = _trim(mark())
    wm = wordmark_loop()
    # horizontal: the mark on the right (read first, RTL), the wordmark on its left, bottoms aligned to the brim
    gapx = 6
    H = Layer(wm.w + gapx + mk.w, max(mk.h, wm.h))
    H.paste(mk, wm.w + gapx, 0)
    H.paste(wm, 0, (H.h - wm.h) // 2 + 2)
    # stacked: the mark over the wordmark, centred
    V = Layer(max(mk.w, wm.w), mk.h + 4 + wm.h)
    V.paste(mk, (V.w - mk.w) // 2, 0)
    V.paste(wm, (V.w - wm.w) // 2, mk.h + 4)
    for L, name, s in ((mk, "mark", 16), (wm, "wordmark-loop", 8), (H, "logo-horizontal", 8), (V, "logo-stacked", 8)):
        L.to_image(1).save(os.path.join(key, f"{name}-art.png"))
        L.to_image(s).save(os.path.join(key, f"{name}.png"))
    return mk, wm, H, V


def build():
    icon()
    return lockups()


if __name__ == "__main__":
    build()
    print("icon + mark + logo lockups ->", KEY)
