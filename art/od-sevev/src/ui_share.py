"""Share cards: the thermal receipt (torn edges) and the result-card frame.

Grid: both cards are 1080x1350 PNGs (UX 5.1 / 5.2), authored on a 216x270 art grid at x5
(1080 / 5 = 216, 1350 / 5 = 270: an exact integer scale, so the card is one pixel grid like the
game). The cast sprites (96 art px tall) paste 1:1 onto this grid.
Key content stays inside the centred square (216x216 art = 1080x1080), y 27..242.

Text is the engine's (SubViewport render, UX 5.1). At x5 the 5x9 cut gives a 25 px letter body on a
1080 card; the receipt's printable column is 152 art px = 25 glyphs (6 px advance). Receipt lines
longer than 25 glyphs wrap: item on line 1, amount right... see style-guide 17.4 and the UX flag.
"""
from pix import Layer
from kit import save, chamfer, outline_inplace, grid_layer
import hebfont

G = "share"
CW, CH = 216, 270
PX0, PW = 24, 168              # receipt paper x and width
PAD = 8                        # print margin inside the paper -> 152 px text column


def torn_edge(w, top=True, seed=3):
    """A torn thermal-paper edge: irregular sawtooth, period 5-7, depth 1-3, one fibre row."""
    import random
    rnd = random.Random(seed)
    L = Layer(w, 6)
    x = 0
    depth = []
    while x < w:
        p = rnd.choice((5, 6, 7))
        d = rnd.choice((2, 3, 3, 4))
        for i in range(p):
            t = i / p
            depth.append(round(d * (1 - abs(2 * t - 1))) + 1)
        x += p
    for x in range(w):
        d = depth[x]
        for y in range(6):
            yy = y if not top else 5 - y
            if y >= 6 - d - 1:
                continue
            L.set(x, yy, "receipt")
        # fibre: the first paper row at the tear is the shadow tone
        fy = (6 - d - 2) if not top else (5 - (6 - d - 2))
        L.set(x, fy, "receipt_sh")
    return L


def receipt_pieces():
    top = torn_edge(PW, True, 3)
    bot = torn_edge(PW, False, 9)
    body = Layer(PW, 4)
    body.rect(0, 0, PW, 4, "receipt")
    body.vline(PW - 1, 0, 3, "receipt_sh")
    body.vline(0, 0, 3, "receipt_sh")
    save(top, "receipt_top", G, notes="Torn top edge of the thermal receipt, 168 art px wide. Stack: top + body (tiled) + bottom.")
    save(body, "receipt_body", G, mode="tile", notes="Receipt paper body, tile vertically. Paper #F4F1E8, ink #1A1A1A (UX 5.1, 15.4:1).")
    save(bot, "receipt_bottom", G, notes="Torn bottom edge.")
    rule = Layer(8, 1)
    for x in range(8):
        if x % 4 < 2:
            rule.set(x, 0, "receipt_ink")
    save(rule, "receipt_rule", G, mode="tile", notes="Dashed divider (the '────' rows), tile horizontally across the 152 px column.")
    return top, body, bot


def card_bg():
    L = Layer(CW, CH, fill="night")
    # a soft lift behind the paper: two value steps, checker seam (the style's only 'glow')
    L.ellipse(108, 134, 100, 128, "ui_panel")
    for y in range(CH):
        for x in range(CW):
            dx, dy = (x - 108) / 100.5, (y - 134) / 128.5
            d = dx * dx + dy * dy
            if 0.86 < d <= 1.0 and (x + y) % 2 == 0:
                L.set(x, y, "night")
    return L


def receipt_card():
    top, body, bot = receipt_pieces()
    L = card_bg()
    y0, y1 = 12, 258
    # drop shadow
    L.rect(PX0 + 3, y0 + 8, PW, y1 - y0 - 8, "outline")
    L.paste(top, PX0, y0)
    for y in range(y0 + 6, y1 - 6, 4):
        L.paste(body, PX0, y)
    L.paste(bot, PX0, y1 - 6)
    save(L, "share_receipt_bg", G, extra={"textColumn": [PX0 + PAD, y0 + 10, PW - 2 * PAD, y1 - y0 - 20],
                                            "exportScale": 5, "export": "1080x1350"},
         notes="Receipt share card at 1x (x5 = 1080x1350). Paper x 24..191, y 12..257; print column x 32..183 "
               "(152 px = 25 glyphs of the 5x9 cut), y 22..247 = 22 rows: UX's fit is 19 text lines + 3 dashed rules "
               "(ux/string-budgets.json receipt boxes), ending with the full 2-line disclaimer and the URL line.")
    return L


def result_frame():
    L = Layer(CW, CH, fill="plum")
    # follow-spot from the top onto the stage floor
    for y in range(20, 200):
        half = 14 + (y - 20) * 0.28
        for x in range(CW):
            if abs(x - 108) <= half:
                edge = half - abs(x - 108)
                if edge > 1.5 or (x + y) % 2 == 0:
                    L.set(x, y, "plum_hi")
    # stage floor
    L.rect(0, 196, CW, 12, "wood")
    L.hline(0, CW - 1, 196, "stone_sh")
    L.rect(0, 206, CW, 2, "wood_dk")
    L.ellipse(108, 199, 34, 3, "stone_sh")
    L.ellipse(108, 199, 26, 2, "stone")
    # curtains: vertical folds, both sides
    for side in (0, 1):
        for x in range(34):
            xx = x if side == 0 else CW - 1 - x
            fold = (x // 5) % 2
            c = "plum_hi" if fold else "plum"
            for y in range(0, 208 - (x * x) // 30):
                L.set(xx, y, c)
            L.set(xx, 208 - (x * x) // 30 - 1, "outline")
    # valance
    L.rect(0, 0, CW, 14, "plum")
    for x in range(0, CW, 12):
        L.ellipse(x + 5.5, 12, 6, 4, "plum")
        L.ellipse(x + 5.5, 11, 5, 3, "plum_hi")
    L.hline(0, CW - 1, 0, "outline")
    # plates for engine text (headline / stats / footer)
    L.rect(20, 40, 176, 38, "outline")          # headline plate: 2 headline lines + the sub-line (5x9 cut)
    L.rect(21, 41, 174, 36, "night")
    L.hline(40, 175, 65, "ui_bubble")          # hairline between the headline and 'והציבור? נרגש.' 
    L.rect(20, 212, 176, 16, "outline")         # stat strip
    L.rect(21, 213, 174, 14, "night")
    L.rect(0, 232, CW, 38, "ui_scrim")          # footer + disclaimer band
    L.hline(0, CW - 1, 232, "outline")
    L.hline(0, CW - 1, 233, "ui_bub_hi")
    from wordmark import render
    wm = render("עוד סבב", 11, 2, ext=1)
    L.paste(wm, (CW - wm.w) // 2, 18)
    save(L, "share_result_frame", G, pivot=[108, 198],
         extra={"zones": {"wordmark": [(CW - wm.w) // 2, 18, wm.w, wm.h], "headline": [28, 43, 160, 20], "sub": [24, 67, 168, 10],
                          "castAnchor": [108, 198], "stats": [24, 215, 168, 10], "footer": [8, 238, 200, 10], "disclaimer": [8, 251, 200, 10]},
                "exportScale": 5, "export": "1080x1350"},
         notes="Result card frame (UX 5.2) at 1x (x5 = 1080x1350). Stage curtains + follow-spot; paste the Magician "
               "(showcase bibi_idle frame 0 or bibi_tap last frame) bottom-centre at castAnchor. Headline 2 lines + "
               "sub-line (white on night 13.5:1); stat strip; the band holds RESULT_FOOT WITH THE URL (iOS WhatsApp drops "
               "the share text, so the image carries the link) and the full RESULT_DISC. No seat numbers (UX 5 global rule).")


def camera_stamp():
    cam = ["..kkk....",
           "kkkwkkkkk",
           "kssssssrk",
           "kslllllsk",
           "ksl.w.lsk",
           "kslllllsk",
           "kssssssskk",
           "kkkkkkkkk"]
    cam = [r[:9] for r in cam]
    save(grid_layer(cam, {"k": "outline", "s": "silver", "l": "slate", "w": "white", "r": "red", ".": None}),
         "stamp_camera", G, notes="The 📸 photobomber stamp (UX 5.2), 9x8, for when both photobombers are in frame.")


def build():
    receipt_card(); result_frame(); camera_stamp()


if __name__ == "__main__":
    build()
    from kit import write_manifest
    print(write_manifest())
