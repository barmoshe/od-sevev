"""icon.png (1024) + icon-60.png: 64x64 art-px source, x16.

Concept (after the Game Designer's routed note: 'סבב' alone reads as a round of fighting):
a ballot box wearing the Magician's top hat, circled by one gold 'again' loop.
  - ballot box  = elections (not conflict), readable worldwide, no party letters on the slip
  - top hat     = the Magician / the show
  - gold loop   = 'עוד סבב', another round, forever
Three shapes, three values (dark hat, white box, gold ring) on a plum stage field.
No flag, no emblem, no party colour, nothing siren- or fire-like.
"""
import os, math
from PIL import Image
from pix import Layer

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..")
N = 64


def build():
    L = Layer(N, N, fill="plum")
    # soft spotlight field (2 value steps, checker seam)
    L.ellipse(31.5, 34, 27, 27, "plum_hi")
    for y in range(N):
        for x in range(N):
            d = math.hypot(x - 31.5, y - 34)
            if 25 <= d <= 28 and (x + y) % 2 == 0:
                L.set(x, y, "plum")
    # the gold loop: ring r=24..28, gap at the top-right, arrowhead pointing clockwise
    cx, cy = 31.5, 33.5
    for y in range(N):
        for x in range(N):
            d = math.hypot(x - cx, y - cy)
            a = math.degrees(math.atan2(y - cy, x - cx))  # 0 = right, -90 = up
            if 23.5 <= d <= 28.5 and not (-78 <= a <= -40):
                L.set(x, y, "gold" if d < 27.5 else "gold_sh")
                if d < 24.6:
                    L.set(x, y, "gold_hi")
    # arrowhead at the gap's TOP end, pointing right = clockwise = 'again' (not 'undo')
    head = ["#.....", "###...", "#####.", "######", "#####.", "###...", "#....."]
    for j, row in enumerate(head):
        for i, ch in enumerate(row):
            if ch == "#":
                L.set(36 + i, 3 + j, "gold" if j < 5 else "gold_sh")
    # ballot box: lidded carton, dark slot on the lid, navy band
    bx, by, bw, bh = 17, 36, 30, 19
    L.rect(bx - 1, by - 4, bw + 2, 4, "paper")                  # lid
    L.hline(bx - 1, bx + bw, by - 4, "white")
    L.rect(bx + 11, by - 3, 10, 2, "ink")                       # slot
    L.rect(bx, by, bw, bh, "white")
    L.vline(bx + bw - 1, by, by + bh - 1, "paper"); L.vline(bx + bw - 2, by, by + bh - 1, "paper")
    L.rect(bx, by + 6, bw, 6, "navy")                           # band
    L.hline(bx, bx + bw - 1, by + 6, "flag_hi")
    # the slip, tilted, halfway into the slot, with a check mark
    slip = [
        "..wwwwww",
        "..wwwwww",
        ".wwwwwkw",
        ".wwwwkww",
        ".wkwkwww",
        "wwwkwwww",
        "wwwwwww.",
        "wwwwwww.",
    ]
    L.grid(bx + 12, by - 11, slip, {"w": "white", "k": "navy"})
    # top hat perched on the lid's left, brim resting on it
    hx, hy = 12, 18
    L.rect(hx + 3, hy, 13, 11, "ink")                           # crown
    L.rect(hx + 4, hy + 1, 3, 9, "suit_dk")
    L.vline(hx + 5, hy + 1, hy + 9, "suit")
    L.rect(hx + 3, hy + 7, 13, 3, "flag")                       # band
    L.hline(hx + 3, hx + 15, hy + 7, "flag_hi")
    L.rect(hx, hy + 10, 19, 3, "ink")                           # brim, sits on the lid (y = 31)
    L.hline(hx + 1, hx + 8, hy + 10, "suit")
    # outline pass on the foreground objects: ink edge where box/hat meet the field
    fg = {"white", "paper", "navy", "flag", "flag_hi", "slate"}
    src = [row[:] for row in L.px]
    for y in range(N):
        for x in range(N):
            if src[y][x] in ("plum", "plum_hi", "gold", "gold_sh", "gold_hi"):
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    xx, yy = x + dx, y + dy
                    if 0 <= xx < N and 0 <= yy < N and src[yy][xx] in fg:
                        L.set(x, y, "ink")
                        break
    # ring outline where it meets the field
    src = [row[:] for row in L.px]
    for y in range(N):
        for x in range(N):
            if src[y][x] in ("plum", "plum_hi"):
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    xx, yy = x + dx, y + dy
                    if 0 <= xx < N and 0 <= yy < N and src[yy][xx] in ("gold", "gold_sh", "gold_hi"):
                        L.set(x, y, "ink")
                        break
    return L


if __name__ == "__main__":
    L = build()
    big = L.to_image(16).convert("RGB")               # 1024, opaque, square: the OS masks corners
    big.save(os.path.join(OUT, "icon.png"))
    big.resize((60, 60), Image.LANCZOS).save(os.path.join(OUT, "icon-60.png"))
    big.resize((60, 60), Image.LANCZOS).resize((240, 240), Image.NEAREST).save(os.path.join(OUT, "proofs", "icon-60-zoomed.png"))
    big.resize((29, 29), Image.LANCZOS).resize((232, 232), Image.NEAREST).save(os.path.join(OUT, "proofs", "icon-29-zoomed.png"))
    print("icon.png")
