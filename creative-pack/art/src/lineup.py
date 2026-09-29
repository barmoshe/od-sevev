"""lineup.png: the cast on one sheet, RTL reading order (first item on the RIGHT).
Every sprite at ONE pixel scale (x4). Name tags in the game's own 5x9 Hebrew font."""
import os
from pix import Layer, from_grid
import characters as C
import hebfont as F

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..")
SCALE = 4
W = 284
CELL = 34

TAGS = {
    "magician": "הקוסם", "bibi": "הקוסם, צ'יבי", "dubi": "דובי", "rabbit": "הארנב", "suitcase": "המזוודה",
    "sara": "שרה", "bengvir": "בן גביר", "smotrich": "סמוטריץ'", "deri": "דרעי", "gafni": "גפני",
    "levin": "לוין", "regev": "רגב", "gotliv": "גוטליב",
    "lapid": "לפיד", "bennett": "בנט", "liberman": "ליברמן", "eisenkot": "איזנקוט", "gantz": "גנץ",
    "golan": "גולן",
    "taxpayer": "משלם\nהמסים", "hightech": "ההייטקיסט", "greyshirt": "החולצה\nהאפורה",
    "whiteglasses": "המשקפיים\nהלבנים",
}


def bubble(L, text, x_right, y):
    w = F.measure(text)
    x0 = x_right - w - 4
    L.rect(x0, y, w + 5, 12, "white")
    L.hline(x0, x0 + w + 4, y - 1, "ink"); L.hline(x0, x0 + w + 4, y + 12, "ink")
    L.vline(x0 - 1, y, y + 11, "ink"); L.vline(x0 + w + 5, y, y + 11, "ink")
    # tail pointing down-right toward the speaker
    L.set(x_right - 3, y + 12, "white"); L.set(x_right - 2, y + 13, "ink"); L.set(x_right - 3, y + 13, "ink")
    L.set(x_right - 4, y + 13, "ink"); L.set(x_right - 2, y + 12, "ink")
    F.draw(L, text, x_right - 2, y + 1, "ink")


def row_label(L, text, y):
    F.draw(L, text, W - 6, y, "suit_dk")
    w = F.measure(text)
    L.hline(6, W - 10 - w, y + 5, "stone_sh")


def cells(L, names, y, cellw=CELL, floor=True, stagger=True):
    """Place chibis right-to-left starting at the right margin."""
    for i, n in enumerate(names):
        cx = W - 6 - cellw // 2 - i * cellw
        spr = C.build(n)
        L.paste(spr, cx - C.CW // 2, y)
        if floor:
            L.hline(cx - 11, cx + 10, y + C.CH, "stone_sh")
        text = TAGS[n]
        dy = 12 if (stagger and i % 2) else 0
        if dy:
            L.vline(cx, y + C.CH + 1, y + C.CH + dy + 1, "stone_sh")
        F.plate(L, text, cx, y + C.CH + 2 + dy)


def build():
    H = 352
    L = Layer(W, H, fill="paper")
    # header
    F.draw(L, "עוד סבב · הקאסט", W - 6, 4, "ink")
    F.draw(L, "סקיצות · כל דמות נקראת מ-2-3 סימנים", 6, 4, "slate", align="left")
    L.hline(4, W - 5, 15, "ink")

    # --- row A: the stars (Magician, Dubi, rabbit, Suitcase)
    y = 20
    row_label(L, "הכוכבים", y)
    mag, coin = C.magician_full("idle")
    mx = W - 6 - mag.w
    my = y + 22
    L.paste(mag, mx, my)
    F.plate(L, TAGS["magician"], mx + mag.w // 2, my + mag.h + 1)
    # Dubi with his one line
    dx = mx - 44
    L.paste(C.build("dubi"), dx, my + 30)
    L.hline(dx + 5, dx + 26, my + 30 + C.CH, "stone_sh")
    F.plate(L, TAGS["dubi"], dx + C.CW // 2, my + 30 + C.CH + 2)
    bubble(L, "אין כלום!", dx + 30, my + 12)
    # rabbit
    rb = C.rabbit()
    rx = dx - 40
    L.paste(rb, rx, my + 66 - rb.h + 4)
    F.plate(L, TAGS["rabbit"], rx + rb.w // 2, my + 70)
    # suitcase, floating, with motion ticks
    sc = C.suitcase()
    sx = rx - 44
    L.paste(sc, sx, my + 38)
    for k in range(3):
        L.hline(sx + sc.w + 2, sx + sc.w + 6 - k, my + 44 + k * 4, "slate")
    F.plate(L, TAGS["suitcase"], sx + sc.w // 2, my + 70)
    # construction note block (left)
    notes = ["צ'יבי 24x32, ראש 16x16", "קו מתאר אחד, בצבע דיו", "בורדו = רק המזוודה", "זהב = רק כסף"]
    ch = C.build("bibi")
    L.paste(ch, 34, my + 36)
    F.plate(L, "הקוסם, צ'יבי", 34 + C.CW // 2, my + 36 + C.CH + 1)
    for k, t in enumerate(notes):
        F.draw(L, t, 8, my - 8 + k * 11, "suit", align="left")

    # --- row B: coalition
    y = 130
    row_label(L, "הקואליציה", y)
    cells(L, ["sara", "bengvir", "smotrich", "deri", "gafni", "levin", "regev", "gotliv"], y + 10)
    # --- row C: opposition
    y = 202
    row_label(L, "האופוזיציה", y)
    cells(L, ["lapid", "bennett", "liberman", "eisenkot", "gantz", "golan"], y + 10)
    # --- row D: the public + the ones always in frame
    y = 274
    row_label(L, "הציבור (ומי שתמיד בפריים)", y)
    cells(L, ["taxpayer", "hightech", "greyshirt", "whiteglasses"], y + 10, cellw=68, stagger=False)
    L.to_image(SCALE).save(os.path.join(OUT, "lineup.png"))
    return L


if __name__ == "__main__":
    build()
    print("lineup.png")
