"""Numeric squint proof for the Magician on each era's stage slot.

edge : WCAG 1.4.11-style non-text contrast measured per perimeter pixel, between the
       sprite's outermost pixel (the ink outline) and the backdrop pixel touching it.
       Target: >= 3:1 on >= 90% of the perimeter.
mass : mean luminance of his suit vs the mean of a 6px backdrop halo (the 'squint' read).
       Target: >= 2.5:1 (night/indoor eras reach it via the follow-spot).
"""
from palette import luminance
import characters as C
import locations as LOC


def ratio(a, b):
    return (max(a, b) + .05) / (min(a, b) + .05)


def check(scene):
    m, _ = C.magician_full()
    ox, oy = LOC.SLOT[0] - 1, LOC.SLOT[1] - 1
    occ = {(x, y) for y in range(m.h) for x in range(m.w) if m.px[y][x]}
    edge = []
    for (x, y) in occ:
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            if (x + dx, y + dy) not in occ:
                bg = scene.get(ox + x + dx, oy + y + dy)
                if bg:
                    edge.append(ratio(luminance(m.px[y][x]), luminance(bg)))
    halo = []
    for y in range(-6, m.h + 6):
        for x in range(-6, m.w + 6):
            if (x, y) in occ:
                continue
            if any((x + dx, y + dy) in occ for dx in (-6, 0, 6) for dy in (-6, 0, 6)):
                c = scene.get(ox + x, oy + y)
                if c:
                    halo.append(luminance(c))
    suit = [luminance(m.px[y][x]) for (x, y) in occ if m.px[y][x] in ("suit", "suit_dk", "suit_hi")]
    b = sum(halo) / len(halo)
    s = sum(suit) / len(suit)
    ok_edge = sum(1 for e in edge if e >= 3) / len(edge)
    return ok_edge, sorted(edge)[len(edge) // 2], ratio(s, b), b


if __name__ == "__main__":
    for title, mood, fn in LOC.ERAS:
        pe, med, mass, b = check(fn())
        print(f"{title:14s} edge>=3:1 on {pe*100:5.1f}% of perimeter (median {med:.1f}:1) | "
              f"suit mass vs backdrop {mass:.2f}:1 (backdrop L={b:.2f})")
