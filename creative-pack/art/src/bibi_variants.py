"""proofs/bibi-variants.png: A faithful / B pushed / C wildcard busts + D chibi head,
top row at 1x game scale (1 art px = 1 px), bottom row at x2. Whole sheet then shown x3."""
import os
from pix import Layer
import bibi
from characters import MICRO

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "proofs")


def letter(L, ch, x, y, c="white"):
    for j, row in enumerate(MICRO[ch]):
        for i, v in enumerate(row):
            if v == "#":
                L.set(x + i, y + j, c)


def x2(src):
    L = Layer(src.w * 2, src.h * 2)
    for y in range(src.h):
        for x in range(src.w):
            if src.px[y][x]:
                L.rect(2 * x, 2 * y, 2, 2, src.px[y][x])
    return L


if __name__ == "__main__":
    items = [("A", bibi.bust("A")), ("B", bibi.bust("B")), ("C", bibi.bust("C")), ("D", bibi.head("D"))]
    colw = 90
    S = Layer(colw * 4 + 8, 150, fill="plum")
    for k, (lab, spr) in enumerate(items):
        x0 = 4 + k * colw
        letter(S, lab, x0 + 2, 3, "gold" if lab == bibi.PICK else "white")
        S.paste(spr, x0 + (colw - spr.w) // 2, 12)                  # 1x
        big = x2(spr)
        S.paste(big, x0 + (colw - big.w) // 2, 150 - big.h - 2)      # x2
    S.to_image(3).save(os.path.join(OUT, "bibi-variants.png"))
    print("bibi-variants.png")
