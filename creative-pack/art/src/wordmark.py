"""The 'עוד סבב' wordmark: custom pixel lettering, 18 art-px cap height, 3px strokes.
Built from the same letter logic as the 5x9 UI font (ב's tail, ד's overhang, ע's left kick)
so the title and the UI read as one family. The ס doubles as the 'again' loop: a gold
arrowhead was tried on its wall and rejected (read as a glitch); see ARROW note below."""
from pix import Layer

LET = {}
LET["ב"] = [
    "##########...",
    "###########..",
    "###########..",
    "###.....###..",
] + ["........###.."] * 11 + ["#############"] * 3

LET["ד"] = ["##############"] * 3 + [".........###.."] * 15

LET["ו"] = ["#####.", "######", "######"] + ["...###"] * 15

LET["ע"] = [
    "###.......###",
    "###.......###",
    ".###......###",
    ".###......###",
    "..###.....###",
    "..###.....###",
    "...###....###",
    "...###....###",
    "....###...###",
    "....###...###",
    ".....###..###",
    "......######.",
    "......#####..",
    ".....#####...",
    "....#####....",
    "##########...",
    "#########....",
    "#########....",
]

LET["ס"] = [
    "###########...",
    "############..",
    "#############.",
] + ["###........###"] * 11 + [
    ".###......###.",
    ".############.",
    "..##########..",
    "...########...",
]

# REJECTED (kept for the record): a loop arrowhead on ס's wall read as a drip/glitch at x4.
# The loop motif lives in the icon instead. render(loop=False) is the shipping default.
ARROW = ["#######", ".#####.", "..###..", "...#..."]

GAP, SPACE = 2, 7


def mask(text="עוד סבב"):
    vis = text[::-1]                      # pure Hebrew: visual order is the reverse
    w = sum((SPACE if c == " " else len(LET[c][0])) + GAP for c in vis) - GAP
    M = [[0] * w for _ in range(18)]
    x, samekh_x = 0, None
    for c in vis:
        if c == " ":
            x += SPACE + GAP
            continue
        g = LET[c]
        for j, row in enumerate(g):
            for i, ch in enumerate(row):
                if ch == "#":
                    M[j][x + i] = 1
        if c == "ס":
            samekh_x = x
        x += len(g[0]) + GAP
    return M, w, samekh_x


def render(fill="gold", hi="gold_hi", sh="gold_sh", extrude="orange_sh", arrow="white", outline="ink", loop=False):
    M, w, sx = mask()
    pad = 5
    L = Layer(w + 2 * pad, 18 + 2 * pad)
    # extrusion, 2px down-right
    for d in (2, 1):
        for j in range(18):
            for i in range(w):
                if M[j][i]:
                    L.set(pad + i + d, pad + j + d, extrude)
    for j in range(18):
        for i in range(w):
            if M[j][i]:
                c = fill
                if j < 3:
                    c = hi                                     # top gloss band
                elif (i + 1 < w and not M[j][i + 1]) or j >= 15 and (j + 1 >= 18 or not M[j + 1][i]):
                    c = sh                                     # right/bottom inner edge
                L.set(pad + i, pad + j, c)
    if loop and sx is not None:
        ax = pad + sx + 11 - 2          # centred on the right wall (cols 11-13)
        for j, row in enumerate(ARROW):
            for i, ch in enumerate(row):
                if ch == "#":
                    L.set(ax + i, pad + 6 + j, arrow)
    return L.outlined(outline, pad=0)


if __name__ == "__main__":
    import os
    here = os.path.dirname(os.path.abspath(__file__))
    wm = render()
    big = Layer(wm.w + 8, wm.h + 8, fill="night")
    big.paste(wm, 4, 4)
    big.to_image(6).save(os.path.join(here, "..", "proofs", "wordmark.png"))
    mono = render("ink", "ink", "ink", "ink", "white", "ink")
    b2 = Layer(wm.w + 8, wm.h + 8, fill="white"); b2.paste(mono, 4, 4)
    b2.to_image(6).save(os.path.join(here, "..", "proofs", "wordmark-mono.png"))
    print(wm.w, wm.h)
