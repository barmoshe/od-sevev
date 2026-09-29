"""do-dont.png: the style guide's exemplar pairs, same subject side by side (proof sheet).
Art panels are pure palette pixels; the caption strip uses a system font (outside the art)."""
import os
from PIL import Image, ImageDraw, ImageFont
from pix import Layer, from_grid
import hebfont as F
import characters as C
import locations as LOC

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..")
S = 3
PW, PH = 72, 84


def mark(L, ok):
    """Redundant cue: shape (check / cross) AND colour."""
    if ok:
        for (x, y) in [(3, 6), (4, 7), (5, 8), (6, 7), (7, 6), (8, 5), (9, 4)]:
            L.rect(x, y, 2, 2, "green")
    else:
        for i in range(7):
            L.rect(3 + i, 3 + i, 2, 2, "red"); L.rect(9 - i, 3 + i, 2, 2, "red")


def panel(fill="paper"):
    return Layer(PW, PH, fill=fill)


def pair_palette():
    a, b = panel(), panel()
    a.paste(C.build("smotrich"), 20, 30); b.paste(C.build("smotrich"), 20, 30)
    b.replace("red", "maroon"); b.replace("maroon_dk", "maroon_dk")
    for L in (a, b):
        L.paste(C.suitcase(), 38, 8)
    return a, b, "Palette: maroon is the Suitcase's alone", "Red tie reads as 'not the Suitcase'", "Maroon tie: a second 'catchable' on screen"


def pair_value():
    a = LOC.courthouse(); b = LOC.courthouse()
    # b: the same court with no follow-spot (rebuild without it)
    import types
    src = LOC.courthouse.__code__
    b = LOC.Layer(LOC.SW, LOC.SH)
    b.paste(LOC.courthouse(), 0, 0)
    # undo the lift inside the cone by re-darkening floor/wall pixels
    inv = {v: k for k, v in LOC.LIFT.items() if k.startswith("teal")}
    inv["teal_hi"] = "teal_dk"
    for y in range(40, LOC.FLOOR):
        for x in range(50, 130):
            c = b.get(x, y)
            if c in ("teal_hi",):
                b.set(x, y, "teal_dk")
            elif c == "teal" and y > 148:
                b.set(x, y, "teal_dk")
    m, _ = C.magician_full()
    out = []
    for L in (a, b):
        L.paste(m, LOC.SLOT[0] - 1, LOC.SLOT[1] - 1)
        crop = Layer(PW, PH)
        for y in range(PH):
            for x in range(PW):
                crop.px[y][x] = L.get(54 + x, 142 + y)
        out.append(crop)
    return out[0], out[1], "Value: the follow-spot owns the stage", "Spot lifts the backdrop one step: suit >= 3:1", "No spot: dark suit sinks into dark floor"


def pair_line():
    a, b = panel("stone_sh"), panel("stone_sh")
    for L in (a, b):
        for x in range(0, PW, 6):
            L.vline(x, 0, PH - 1, "stone")
    a.paste(C.build("gafni"), 20, 28)
    body = from_grid(C.BODIES["suit"], C.CAST["gafni"][2])
    legend, chin, rows = C.HEADS["gafni"]
    head = from_grid(rows, legend)
    raw = Layer(C.CW, C.CH); raw.paste(body, 5, C.CH - 15); raw.paste(head, 8, C.CH - 15 - chin + 1)
    b.paste(raw, 20, 28)
    return a, b, "Line: one 1px ink outline on every sprite", "Ink outline: the figure holds on a busy wall", "No outline: beard and suit dissolve into it"


def pair_scale():
    a, b = panel("plum"), panel("plum")
    ch = C.build("bennett")
    a.paste(ch, 4, 44); a.paste(C.build("lapid"), 36, 44)
    big = Layer(ch.w * 2, ch.h * 2)
    for y in range(ch.h):
        for x in range(ch.w):
            c = ch.px[y][x]
            if c:
                big.rect(x * 2, y * 2, 2, 2, c)
    b.paste(big, -6, 8); b.paste(C.build("lapid"), 44, 44)
    return a, b, "Scale: one pixel grid per frame", "Same art-px size, same grid", "Upscaled x2 next to x1: mixels"


def pair_hebrew():
    a, b = panel("night"), panel("night")
    t = "עוד סבב"
    F.draw(a, t, 60, 30, "white")
    F.draw(a, "סבב מס' 6", 60, 46, "silver")
    # b: the classic bug - logical order drawn left-to-right
    def ltr(L, text, x, y, col):
        cx = x
        for ch in text:
            if ch == " ":
                cx += F.SPACE_W + 1; continue
            rows = F.GLYPHS[ch]
            for j, row in enumerate(rows):
                for i, c in enumerate(row):
                    if c == "#":
                        L.set(cx + i, y + j, col)
            cx += len(rows[0]) + 1
    ltr(b, t, 16, 30, "white"); ltr(b, "סבב מס' 6", 16, 46, "silver")
    return a, b, "Hebrew: right-to-left, digits stay LTR", "Visual order: RTL, '6' stays whole", "Logical order drawn LTR: reads backwards"


def pair_motif():
    a, b = panel("plum"), panel("plum")
    m, coin = C.magician_full()
    for L, into_box in ((a, False), (b, True)):
        L.paste(m, 12, 20)
        slip = from_grid(["www", "wsw"], {"w": "white", "s": "slate"}).outlined()
        pts = [(40, 14), (30, 8), (22, 4)] if not into_box else [(52, 16), (58, 26), (62, 40)]
        for (x, y) in pts:
            L.paste(slip, x, y)
        box = Layer(14, 12); box.rect(0, 2, 14, 10, "white"); box.rect(0, 6, 14, 3, "navy"); box.hline(4, 9, 2, "ink")
        L.paste(box.outlined(), 56, 70)
    return a, b, "Motif: never imply what the record doesn't", "Slips fly up and away: 'he calls another round'", "Slips arc into the box: reads as ballot-stuffing"


PAIRS = [pair_palette, pair_value, pair_line, pair_scale, pair_hebrew, pair_motif]


def build():
    cap_h = 72
    W = 2 * PW * S + 3 * 8
    img = Image.new("RGB", (W, len(PAIRS) * (PH * S + cap_h + 16) + 8), (27, 20, 38))
    d = ImageDraw.Draw(img)
    try:
        f1 = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 20)
        f2 = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 15)
    except Exception:
        f1 = f2 = ImageFont.load_default()
    y = 8
    for fn in PAIRS:
        a, b, title, ca, cb = fn()
        mark(a, True); mark(b, False)
        d.text((8, y), title, fill=(247, 244, 236), font=f1)
        img.paste(a.to_image(S).convert("RGB"), (8, y + 28))
        img.paste(b.to_image(S).convert("RGB"), (16 + PW * S, y + 28))
        d.text((8, y + 32 + PH * S), "DO (left):  " + ca, fill=(163, 216, 74), font=f2)
        d.text((8, y + 52 + PH * S), "DON'T (right):  " + cb, fill=(240, 127, 173), font=f2)
        y += PH * S + cap_h + 16
    img.save(os.path.join(OUT, "proofs", "do-dont.png"))


if __name__ == "__main__":
    build()
    print("do-dont.png")
