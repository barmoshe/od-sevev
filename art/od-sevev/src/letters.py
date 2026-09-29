"""Parametric Hebrew display lettering (block letters, stroke S, cap height H).

One letter logic for every display size, so the wordmark "עוד סבב" (H 22, S 4) and the event
banners ("חלון העברות", H 11, S 2) read as one family with the 5x9 UI cut:
  ב: the base sticks out RIGHT past the stem (tail)      ד: the roof overhangs RIGHT past the leg
  ה: the left leg is DETACHED from the roof              ח: both legs attached
  ת: the left leg is inset, with a foot kicking LEFT     ע: two arms converge, the base kicks LEFT
  ס: square top-left, the other three corners round      ל: ascender rises above the cap line
  ן: vav with a descender                                ר: rounded top-right corner, no overhang
Masks are sets of (x, y); y < 0 is ascender space, y >= H is descender space.
"""
import math


def _rect(m, x, y, w, h):
    for yy in range(y, y + h):
        for xx in range(x, x + w):
            m.add((xx, yy))


def _line(m, x0, y0, x1, y1, S):
    """Thick line: stamp an SxS brush (top-left anchored) along the segment."""
    n = int(max(abs(x1 - x0), abs(y1 - y0)) * 2) + 1
    for i in range(n + 1):
        t = i / n
        x = round(x0 + (x1 - x0) * t)
        y = round(y0 + (y1 - y0) * t)
        _rect(m, x, y, S, S)


def _round_corner(m, cx, cy, r, quadrant):
    """Remove pixels outside a radius-r arc in the given corner of a filled block."""
    rm = set()
    for (x, y) in m:
        dx, dy = x - cx, y - cy
        if quadrant == "tr" and dx > 0 and dy < 0 and dx * dx + dy * dy > r * r:
            rm.add((x, y))
        if quadrant == "br" and dx > 0 and dy > 0 and dx * dx + dy * dy > r * r:
            rm.add((x, y))
        if quadrant == "bl" and dx < 0 and dy > 0 and dx * dx + dy * dy > r * r:
            rm.add((x, y))
    m -= rm


def glyph(ch, H, S):
    """Returns (mask, width)."""
    m = set()
    t = max(1, S // 2 + 1)          # overhang / tail
    W = round(H * 0.72) + (S if S > 2 else 0)
    if ch == "ב":
        stem = W - S - t
        _rect(m, 0, 0, stem + S, S)
        _rect(m, stem, 0, S, H)
        _rect(m, 0, H - S, W, S)
        _round_corner(m, stem + S - 1 - (S // 2), S // 2, S // 2 + 0.6, "tr")
    elif ch == "ד":
        leg = W - S - max(1, S // 2)
        _rect(m, 0, 0, W, S)
        _rect(m, leg, 0, S, H)
    elif ch in ("ו", "ן"):
        hx = S // 2 + 1
        W = hx + S
        _rect(m, 0, 0, hx + S, S)
        _rect(m, hx, 0, S, H + (round(H * 0.4) if ch == "ן" else 0))
    elif ch == "ע":
        W = round(H * 0.72) + (S if S > 2 else 0)
        jx, jy = round(W * 0.42), round(H * 0.62)
        _line(m, 0, 0, jx, jy, S)                          # left arm into the join
        _line(m, W - S, 0, W - S, round(H * 0.42), S)      # right arm down
        _line(m, W - S, round(H * 0.42), jx, jy, S)        # right arm curls left into the join
        _line(m, jx, jy, round(W * 0.28), H - S, S)        # down to the base
        _rect(m, 0, H - S, round(W * 0.28) + S, S)         # base kicks LEFT
    elif ch == "ס":
        W = round(H * 0.8) + (S if S > 2 else 0)
        r_out = S + 2 if S > 2 else S + 1
        for y in range(H):
            for x in range(W):
                inner = (S <= x < W - S) and (S <= y < H - S)
                if inner:
                    # inner corners follow the outer rounding so the ring keeps its stroke
                    ok_in = True
                    for (cx, cy, q) in ((W - 1 - r_out, H - 1 - r_out, "br"), (r_out, H - 1 - r_out, "bl"),
                                        (W - 1 - r_out, r_out, "tr")):
                        dx, dy = x - cx, y - cy
                        rr = max(0, r_out - S)
                        if ((q == "br" and dx > 0 and dy > 0) or (q == "bl" and dx < 0 and dy > 0) or
                                (q == "tr" and dx > 0 and dy < 0)) and dx * dx + dy * dy > rr * rr:
                            ok_in = False
                    if ok_in:
                        continue
                m.add((x, y))
        _round_corner(m, W - 1 - r_out, H - 1 - r_out, r_out + 0.5, "br")
        _round_corner(m, r_out, H - 1 - r_out, r_out + 0.5, "bl")
        _round_corner(m, W - 1 - r_out, r_out, r_out + 0.5, "tr")
    elif ch == "ח":
        _rect(m, 0, 0, W, S)
        _rect(m, 0, 0, S, H)
        _rect(m, W - S, 0, S, H)
    elif ch == "ה":
        gap = max(1, S // 2 + 1)
        _rect(m, 0, 0, W, S)
        _rect(m, W - S, 0, S, H)
        _rect(m, 0, S + gap, S, H - S - gap)
    elif ch == "ת":
        inset = max(1, S // 2)
        _rect(m, 0, 0, W, S)
        _rect(m, W - S, 0, S, H)
        _rect(m, inset, 0, S, H)
        _rect(m, 0, H - S, inset + S, S)
    elif ch == "ר":
        _rect(m, 0, 0, W, S)
        _rect(m, W - S, 0, S, H)
        _round_corner(m, W - 1 - S, S, S + 0.6, "tr")
    elif ch == "ל":
        A = round(H * 0.42)
        _rect(m, 0, -A, S, A + S)
        _rect(m, 0, S, W, S)
        _line(m, W - S, S, W - S, round(H * 0.5), S)
        _line(m, W - S, round(H * 0.5), round(W * 0.35), H - S, S)
    elif ch == " ":
        return set(), round(H * 0.4)
    else:
        raise KeyError(ch)
    return m, W


def word(text, H, S, gap=None):
    """Lay out an RTL Hebrew word/phrase. Returns (mask, width, top, bottom) where the mask is in
    visual (left-to-right on screen) coordinates, y from `top` (ascender) to `bottom`."""
    gap = gap if gap is not None else max(1, S // 2 + 1)
    vis = text[::-1]                                   # pure Hebrew: visual order is the reverse
    x, m = 0, set()
    for ch in vis:
        g, w = glyph(ch, H, S)
        for (gx, gy) in g:
            m.add((x + gx, gy))
        x += w + gap
    width = x - gap
    ys = [y for _, y in m] or [0]
    return m, width, min(ys), max(ys)
