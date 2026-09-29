"""proofs/bibi-v2.png: the v2 likeness. Row 1 at 1x game scale, row 2 at x2:
head, IDLE (the lecture), TAP (the trick), 16x16 chibi head, chibi full body. Sheet shown x3."""
import os
from pix import Layer
import bibi
import characters as C
from bibi_variants import letter, x2

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "proofs")

if __name__ == "__main__":
    items = [bibi.head_v2(), bibi.pose_idle(), bibi.pose_tap(), bibi.chibi_v2(), C.build("bibi")]
    xs, y1 = [], 10
    S = Layer(414, 214, fill="plum")
    x = 6
    for spr in items:                     # row 1: 1x
        S.paste(spr, x, y1 + 66 - spr.h)
        xs.append(x); x += spr.w + 10

    x = 6
    for spr in items:                     # row 2: x2
        big = x2(spr)
        S.paste(big, x, 212 - big.h)
        x += big.w + 6
    S.to_image(3).save(os.path.join(OUT, "bibi-v2.png"))
    print("bibi-v2.png")
