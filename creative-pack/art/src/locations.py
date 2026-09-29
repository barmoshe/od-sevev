"""locations.png: the four eras as native 180x320 portrait stages, shown x2, RTL (era 1 on the right).

Every stage shares the same skeleton (style-guide.md §8):
  y   0-40   HUD sky band: flat, low-detail, so the HUD reads on top of it
  y  40-150  the place: the one landmark silhouette that names the era
  y 150-216  THE STAGE SLOT: x 66-114 is kept empty for the Magician (48x64)
  y 216-230  the floor line + the spotlight pool he stands in
  y 230-320  lower panel band: flat and dark, the UX panels sit on it
"""
import os, random
from pix import Layer, from_grid
import hebfont as F
import characters as C

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..")
SW, SH = 180, 320
SLOT = (66, 152, 48, 64)      # x, y, w, h of the Magician
FLOOR = 216


def spotlight(L, floor_c, light_c):
    L.ellipse(90, FLOOR + 3, 30, 5, light_c)
    L.dither(58, FLOOR, 64, 9, light_c, floor_c)          # soft 50% rim, then re-fill core
    L.ellipse(90, FLOOR + 3, 26, 4, light_c)


LIFT = {  # one value step up, same hue family: the follow-spot light map
    "night": "plum", "plum": "plum_hi", "plum_hi": "slate", "suit_dk": "suit", "suit": "suit_hi",
    "suit_hi": "slate", "slate": "grey", "grey": "silver", "wood_dk": "wood", "wood": "orange_sh",
    "orange_sh": "orange", "teal_dk": "teal_hi", "teal": "teal_hi", "teal_hi": "silver",
    "hair_dk": "hair_br", "ink": "suit_dk", "stone_sh": "stone", "green_sh": "green", "green": "lime",
}


def follow_spot(L, full=False):
    """The Magician's follow-spot: a cone from the top of the scene onto the stage slot.
    50% checker (or full) value-lift of whatever is behind it. Mandatory in night/indoor eras."""
    for y in range(40, FLOOR):
        t = (y - 40) / (FLOOR - 40)
        half = int(16 + t * 24)
        for x in range(90 - half, 90 + half):
            if full or (x + y) % 2 == 0 or abs(x - 90) < half - 4:
                c = L.get(x, y)
                if c in LIFT:
                    L.set(x, y, LIFT[c])


def lower_band(L, base, line):
    """The stage apron: flat, one value, a lip on top. UX panels sit here."""
    L.rect(0, 230, SW, 90, base)
    L.hline(0, SW - 1, 230, line)
    L.dither(0, 231, SW, 1, line, base)
    L.hline(0, SW - 1, 319, line)


def stars(L, n, y0, y1, seed):
    r = random.Random(seed)
    for _ in range(n):
        L.set(r.randrange(0, SW), r.randrange(y0, y1), "white" if r.random() < .5 else "slate")


# ---------------------------------------------------------------------------
def balfour():
    """Era 1: the residence at night. Mood: late, warm lamp light, the street is awake."""
    L = Layer(SW, SH)
    L.bands(0, 0, SW, [("night", 110), ("plum", 60), ("plum_hi", 60)])
    stars(L, 26, 2, 90, 1)
    L.ellipse(146, 26, 7, 7, "paper"); L.ellipse(149, 24, 6, 6, "night")          # crescent moon
    # the residence: a stone villa behind trees
    L.rect(28, 100, 124, 80, "slate")
    L.rect(28, 100, 124, 3, "grey")                       # roof slab lit edge
    L.rect(24, 96, 132, 5, "suit")
    for wx in range(36, 148, 16):                          # windows: a few lit (someone is home)
        lit = wx in (52, 100, 132)
        L.rect(wx, 110, 8, 12, "orange" if lit else "suit_dk")
        L.rect(wx, 134, 8, 12, "orange_sh" if wx in (36, 116) else "suit_dk")
        if lit:
            L.rect(wx + 2, 112, 4, 4, "gold_hi")
    for x in range(28, 152):                               # night shadow on the lower wall
        L.set(x, 178, "suit")
    # the perimeter wall + gate (behind the stage)
    L.rect(0, 168, SW, 48, "slate")                      # wall, lamp-lit: MID value behind the stage
    L.rect(0, 168, SW, 3, "grey")
    for x in range(0, SW, 10):
        L.vline(x, 171, 215, "suit_hi")
    L.rect(66, 172, 48, 44, "wood")                        # gate, warm mid value
    for x in range(68, 114, 5):
        L.vline(x, 174, 215, "orange_sh")
    L.hline(66, 113, 172, "orange_sh")
    # dark trees framing the villa
    for (cx, cy) in [(18, 120), (8, 140), (166, 124), (176, 142)]:
        L.ellipse(cx, cy, 14, 22, "night")
    # street lamps
    for lx in (26, 154):
        L.vline(lx, 132, 215, "ink")
        L.rect(lx - 3, 128, 7, 5, "ink")
        L.rect(lx - 2, 130, 5, 2, "gold_hi")
        L.dither(lx - 9, 134, 19, 30, "orange_sh", None) if False else None
        for dy in range(0, 34):                           # a cone of lamp light, 50% dither
            half = dy // 3
            for dx in range(-half, half + 1):
                x, y = lx + dx, 134 + dy
                if (x + y) % 2 == 0 and L.get(x, y) not in (None, "ink"):
                    L.set(x, y, "orange_sh")
    follow_spot(L)
    # the street
    L.rect(0, 216, SW, 14, "suit_dk")
    spotlight(L, "suit_dk", "slate")
    # protest crowd behind barriers, left and right (generic people, blank signs)
    r = random.Random(7)
    for side in (0, 1):
        xs = range(2, 56, 7) if side == 0 else range(126, 178, 7)
        for i, x in enumerate(xs):
            h = 20 + r.randrange(0, 6)
            top = FLOOR - h
            L.rect(x - 3, top + 6, 7, h - 6, "night")            # body
            L.ellipse(x, top + 3, 2.6, 3, "skin_sh")             # head (lamp-lit side)
            L.set(x - 1, top + 1, "hair_dk"); L.set(x, top + 1, "hair_dk"); L.set(x + 1, top + 1, "hair_dk")
            if i % 2 == 0:                                        # blank sign on a stick
                sx = x + r.choice((-2, 1))
                L.vline(sx + 2, top - 6, top + 6, "wood")
                L.rect(sx - 2, top - 14, 10, 8, "pink" if (i // 2) % 2 == 0 else "white")
                L.hline(sx - 2, sx + 7, top - 7, "pink_sh" if (i // 2) % 2 == 0 else "paper")
        bx0 = 0 if side == 0 else 122
        L.hline(bx0, bx0 + 57, FLOOR - 7, "grey"); L.hline(bx0, bx0 + 57, FLOOR - 3, "grey")
        for x in range(bx0 + 2, bx0 + 58, 9):
            L.vline(x, FLOOR - 8, FLOOR, "slate")
    lower_band(L, "night", "suit_dk")
    return L


def knesset():
    """Era 2: the Knesset at midday. Mood: bright, official, warm stone, a little too orderly."""
    L = Layer(SW, SH)
    L.bands(0, 0, SW, [("sky", 118), ("white", 30)])
    for (cx, cy, w) in [(40, 30, 14), (128, 54, 18), (70, 70, 10)]:         # flat cartoon clouds
        L.ellipse(cx, cy, w, 3, "white"); L.ellipse(cx - w // 3, cy - 2, w // 2, 3, "white")
    # hills (Jerusalem), atmospheric: low contrast
    L.ellipse(20, 150, 60, 22, "teal_hi"); L.ellipse(160, 152, 70, 20, "teal_hi")
    # the building: flat roof slab + the square colonnade
    L.rect(14, 92, 152, 8, "stone")                        # roof slab
    L.hline(14, 165, 99, "stone_sh")
    L.rect(18, 100, 144, 64, "stone_sh")                  # shadowed facade behind the columns
    for x in range(20, 160, 8):                            # tall square pillars
        L.rect(x, 100, 5, 64, "stone")
        L.vline(x + 4, 100, 163, "stone_sh")
    L.rect(14, 164, 152, 5, "stone")                        # podium
    L.hline(14, 165, 168, "stone_sh")
    # olive trees
    for (cx, cy) in [(14, 176), (166, 178)]:
        L.vline(cx, cy, cy + 36, "wood_dk"); L.vline(cx + 1, cy + 8, cy + 36, "wood")
        L.ellipse(cx, cy - 4, 14, 10, "green_sh"); L.ellipse(cx - 4, cy - 8, 7, 5, "green")
    # lawn + stone plaza
    L.rect(0, 169, SW, 47, "green")
    L.dither(0, 169, SW, 2, "green", "green_sh")
    for y in range(172, 216, 3):
        for x in range((y * 7) % 11, SW, 11):
            L.set(x, y, "lime")
    L.rect(40, 186, 100, 30, "stone")                        # the plaza (stage)
    for x in range(40, 140, 10):
        L.vline(x, 187, 215, "stone_sh")
    L.rect(0, 216, SW, 14, "stone_sh")
    spotlight(L, "stone_sh", "stone")
    lower_band(L, "wood_dk", "ink")
    return L


def courthouse():
    """Era 3: the courtroom. Mood: cold fluorescent green, low ceiling, time dragging."""
    L = Layer(SW, SH)
    L.rect(0, 0, SW, 40, "teal_dk")
    for x in (20, 80, 140):                                 # fluorescent tubes
        L.rect(x, 10, 22, 2, "white"); L.hline(x - 1, x + 22, 12, "teal_hi")
    L.rect(0, 40, SW, 176, "teal")
    L.dither(0, 40, SW, 2, "teal", "teal_dk")
    for x in range(0, SW, 30):                              # wall panelling
        L.vline(x, 42, 215, "teal_dk")
    # the blank wall panel above the bench (deliberately EMPTY: no emblem, ever) + a clock
    L.rect(58, 50, 64, 40, "teal_hi")
    L.rect(60, 52, 60, 36, "teal")
    L.ellipse(90, 70, 9, 9, "white"); L.ellipse(90, 70, 7, 7, "paper")
    L.vline(90, 64, 70, "ink"); L.hline(90, 94, 70, "ink")
    L.set(90, 62, "ink"); L.set(98, 70, "ink"); L.set(82, 70, "ink"); L.set(90, 78, "ink")
    # judges' bench: raised, three empty high-backed chairs
    for cx in (54, 90, 126):
        L.rect(cx - 7, 94, 14, 24, "wood_dk"); L.hline(cx - 7, cx + 6, 94, "wood")
    L.rect(14, 114, 152, 34, "wood")
    L.rect(14, 114, 152, 3, "stone_sh")
    L.hline(14, 165, 147, "wood_dk")
    for x in range(22, 160, 18):
        L.rect(x, 120, 12, 22, "wood_dk"); L.rect(x + 1, 121, 10, 20, "wood")
    # case files on the bench: labelled with the real case numbers
    for i, (fx, lab) in enumerate([(30, "1000"), (62, "2000"), (126, "4000")]):
        L.rect(fx, 106, 22, 8, "paper"); L.hline(fx, fx + 21, 113, "stone_sh")
        L.rect(fx + 1, 104, 8, 2, "paper")
        F.draw(L, lab, fx + 21, 105, "ink")
    # floor
    L.rect(0, 148, SW, 68, "teal")                          # floor: MID value behind the stage
    for y in range(152, 216, 8):
        L.hline(0, SW - 1, y, "teal_dk")
    L.rect(0, 148, SW, 3, "teal_dk")
    follow_spot(L)
    # public benches at the edges (foreground, darkest)
    for x0 in (0, 142):
        L.rect(x0, 184, 38, 8, "wood"); L.rect(x0, 192, 38, 24, "wood_dk")
        L.hline(x0, x0 + 37, 184, "stone_sh")
    L.rect(0, 216, SW, 14, "teal")
    spotlight(L, "teal_hi", "silver")
    lower_band(L, "ink", "teal_dk")
    return L


def washington():
    """Era 4: Washington in blossom season. Mood: shiny, white marble, candy-pink, the big stage."""
    L = Layer(SW, SH)
    L.bands(0, 0, SW, [("sky", 124), ("white", 30)])
    # the obelisk (far, low contrast)
    L.rect(22, 70, 7, 80, "paper"); L.vline(28, 70, 149, "stone_sh")
    L.set(24, 68, "paper"); L.set(25, 67, "paper"); L.set(26, 68, "paper"); L.rect(23, 69, 5, 1, "paper")
    # the plane in the sky (tiny, the 'Wing of Zion')
    plane = ["......w.....", "wwwwwwwwwwn.", ".nnnnnwnnn..", "......w....."]
    L.grid(120, 24, plane, {"w": "white", "n": "navy"})
    # a generic white mansion with a columned portico (not a replica)
    L.rect(34, 108, 112, 62, "white")
    L.rect(34, 104, 112, 5, "paper"); L.hline(34, 145, 108, "stone_sh")
    for wx in range(40, 142, 12):
        if 62 < wx < 116:
            continue
        L.rect(wx, 118, 6, 10, "sky"); L.rect(wx, 138, 6, 10, "sky")
        L.vline(wx + 5, 118, 127, "flag_hi"); L.vline(wx + 5, 138, 147, "flag_hi")
    # portico: pediment + 4 columns
    for i in range(12):
        L.hline(62 + i * 2, 117 - i * 2, 96 - i, "white")
    L.hline(62, 117, 97, "stone_sh")
    L.rect(62, 98, 56, 4, "paper")
    L.rect(64, 102, 52, 66, "paper")
    for x in (66, 79, 92, 105):
        L.rect(x, 102, 7, 66, "white"); L.vline(x + 6, 102, 167, "stone_sh")
    L.rect(58, 166, 64, 4, "white")
    # cherry blossom trees
    for (cx, cy) in [(14, 170), (168, 168), (40, 186), (144, 188)]:
        L.vline(cx, cy, cy + 30, "wood_dk")
        L.ellipse(cx, cy - 6, 15, 10, "pink"); L.ellipse(cx + 4, cy - 2, 8, 5, "pink_sh")
        L.ellipse(cx - 5, cy - 10, 6, 4, "white")
    # lawn + white path
    L.rect(0, 170, SW, 46, "green")
    for y in range(172, 216, 3):
        for x in range((y * 5) % 9, SW, 9):
            L.set(x, y, "lime")
    for y in range(170, 216):
        w = 14 + (y - 170) // 2
        L.hline(90 - w, 89 + w, y, "paper")
    # redrawn trees in front of the lawn (they stand on it)
    for (cx, cy) in [(14, 170), (168, 168), (40, 186), (144, 188)]:
        L.vline(cx, cy, cy + 30, "wood_dk")
        L.ellipse(cx, cy - 6, 15, 10, "pink"); L.ellipse(cx + 4, cy - 2, 8, 5, "pink_sh")
        L.ellipse(cx - 5, cy - 10, 6, 4, "white")
    # the laundry (the 2020 report [A]): a small laundry bag parked by the path
    bag = ["..ww..", ".wppw.", "wpppp w".replace(" ", ""), "wppppw", ".wwww."]
    bag = ["..ww..", ".wwww.", "wwwwpp", "wwwwpp", ".wwpp."]
    L.grid(120, 206, bag, {"w": "white", "p": "paper"})
    L.rect(0, 216, SW, 14, "stone_sh")
    spotlight(L, "stone_sh", "paper")
    lower_band(L, "navy", "night")
    return L


ERAS = [("1 · בלפור", "לילה, פנסים, הרחוב ער", balfour),
        ("2 · הכנסת", "צהריים, אבן חמה, סדר", knesset),
        ("3 · בית המשפט", "ניאון קר, הזמן נמרח", courthouse),
        ("4 · וושינגטון", "שיש לבן, פריחה, במה גדולה", washington)]


def slot_ticks(L, ox, oy):
    x, y, w, h = SLOT
    for (cx, cy, dx, dy) in [(x, y, 1, 1), (x + w - 1, y, -1, 1), (x, y + h - 1, 1, -1), (x + w - 1, y + h - 1, -1, -1)]:
        for k in range(4):
            L.set(ox + cx + dx * k, oy + cy, "white"); L.set(ox + cx, oy + cy + dy * k, "white")


def build(with_magician=False):
    G, TOP = 8, 26
    W = 4 * SW + 5 * G
    H = TOP + SH + G
    L = Layer(W, H, fill="ink")
    for i, (title, mood, fn) in enumerate(ERAS):
        ox = W - G - SW - i * (SW + G)                    # RTL: era 1 on the right
        scene = fn()
        L.paste(scene, ox, TOP)
        F.draw(L, title, ox + SW - 1, 3, "white")
        F.draw(L, mood, ox + SW - 1, 14, "grey")
        if with_magician:
            m, coin = C.magician_full()
            L.paste(m, ox + SLOT[0] - 1, TOP + SLOT[1] - 1)
        else:
            slot_ticks(L, ox, TOP)
    return L


if __name__ == "__main__":
    build().to_image(2).save(os.path.join(OUT, "locations.png"))
    L = build(with_magician=True)
    img = L.to_image(2)
    img.save(os.path.join(OUT, "proofs", "locations-with-magician.png"))
    img.convert("L").save(os.path.join(OUT, "proofs", "locations-squint-greyscale.png"))
    print("locations.png")
