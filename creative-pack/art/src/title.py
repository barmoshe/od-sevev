"""title.png: the portrait title screen, 180x320 art px shown x4 (720x1280).

Focal hierarchy (3 tiers):
  1. the wordmark 'עוד סבב' (gold, top third)
  2. the Magician under his follow-spot, hat up, pulling ballot slips AND shekels out of it
  3. the election signifiers + running gags: the ballot box 'קלפי' his wand points at,
     the subtitle 'סבב בחירות מס' 6', the drifting Suitcase, Dubi at the mic
'סבב' alone reads as a round of fighting; on this screen it is ALWAYS paired with a ballot
box and the words 'סבב בחירות' (Game Designer note, accepted).
"""
import os
from pix import Layer, from_grid
import hebfont as F
import characters as C
import wordmark as WM
import locations as LOC

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..")
SW, SH = 180, 320
SUBTITLE = "סבב בחירות מס' 6. הציבור נרגש."
TAP = "לגעת בכובע"
DISCLAIMER = "סאטירה. לא מטעם אף מפלגה."


def ballot_box():
    """A plain ballot box: white carton, navy band with 'קלפי', a slip halfway into the slot."""
    L = Layer(32, 30)
    L.rect(2, 8, 24, 20, "white")                     # front
    L.rect(26, 6, 4, 20, "paper")                     # side face
    for i in range(3):
        L.set(26 + i, 7 - i if False else 7, "paper")
    L.rect(4, 5, 26, 3, "paper")                      # top face
    L.rect(2, 7, 24, 1, "white")
    for k in range(4):                                # top face perspective step
        L.set(2 + k, 7 - (k > 1), "paper")
    L.rect(9, 6, 12, 1, "ink")                        # the slot
    # tally of rounds on the carton: one bundle of five + one = round 6
    for x in (5, 7, 9, 11):
        L.vline(x, 9, 12, "ink")
    L.line(4, 12, 12, 9, "red")
    L.vline(15, 9, 12, "ink")
    L.rect(2, 14, 24, 11, "navy")                     # label band
    L.hline(2, 25, 14, "flag_hi")
    F.draw(L, "קלפי", 14, 15, "white", align="center")
    L.hline(2, 29, 27, "stone_sh")
    # the slip going in
    L.rect(11, 0, 8, 6, "white"); L.hline(12, 17, 2, "slate"); L.hline(12, 15, 4, "slate")
    return L.outlined()


def slip():
    return from_grid(["wwwww", "wsssw", "wwwww", "wssww"], {"w": "white", "s": "slate"}).outlined()


def stage_backdrop():
    L = Layer(SW, SH, fill="night")
    L.bands(0, 0, SW, [("night", 150), ("plum", 66)])
    # back wall of the stage: soft vertical drape rhythm
    for x in range(24, 156, 9):
        L.vline(x, 20, 215, "plum" if x % 2 else "night")
    # the follow-spot (same device as every era)
    LOC.follow_spot(L)
    # stage floor + spot pool
    L.rect(0, 216, SW, 14, "wood_dk")
    L.hline(0, SW - 1, 216, "wood")
    LOC.spotlight(L, "wood_dk", "wood")
    # curtains, left and right, with light folds
    for side in (0, 1):
        for i in range(22):
            x = i if side == 0 else SW - 1 - i
            fold = (i % 6) in (1, 2)
            depth = 216 + (6 if i > 14 else 0)
            for y in range(0, depth - (i // 3 if i > 14 else 0)):
                L.set(x, y, "plum_hi" if fold else "plum")
            L.set(x, 0, "plum")
        tie_x = 16 if side == 0 else SW - 18
        L.rect(tie_x - 1, 150, 4, 3, "orange_sh")
    # valance with scallops
    L.rect(0, 0, SW, 12, "plum")
    for x in range(0, SW, 12):
        L.ellipse(x + 6, 11, 6, 4, "plum")
        L.hline(x + 2, x + 9, 15, "plum_hi")
    L.hline(0, SW - 1, 1, "plum_hi")
    # lower band (UX): flat
    LOC.lower_band(L, "night", "suit_dk")
    return L


def build():
    L = stage_backdrop()
    # 1. wordmark
    wm = WM.render()
    wx = (SW - wm.w) // 2
    L.paste(wm, wx, 22)
    # subtitle on a quiet plate
    sw = F.measure(SUBTITLE)
    L.rect((SW - sw) // 2 - 3, 53, sw + 6, 12, "ink")
    F.draw(L, SUBTITLE, SW // 2 + sw // 2, 55, "white", align="right")
    # 2. the Magician
    mag, coin = C.magician_full()
    mx, my = LOC.SLOT[0] - 1, LOC.SLOT[1] - 1
    L.paste(mag, mx, my)
    # the burst out of the hat: a fountain of ballot slips and shekels rising up and to the
    # LEFT, away from the ballot box (nothing on screen may read as ballot-stuffing)
    s = slip()
    for (x, y) in [(96, 136), (84, 118), (70, 104), (56, 94)]:
        L.paste(s, x, y)
    for (x, y) in [(104, 140), (92, 126), (78, 112), (100, 116), (64, 88), (86, 98), (48, 82)]:
        L.paste(coin, x, y)
    for (x, y, c) in [(104, 146, "white"), (103, 146, "gold_hi"), (105, 146, "gold_hi"), (104, 145, "gold_hi"),
                      (104, 147, "gold_hi"), (104, 144, "white"), (104, 148, "white"), (102, 146, "white"), (106, 146, "white")]:
        L.set(x, y, c)
    L.set(104, 146, "white")
    # 3. the ballot box: stage right, apart from the magic
    bb = ballot_box()
    L.paste(bb, 128, 216 - bb.h + 2)
    # Dubi at the mic, stage left
    d = C.build("dubi")
    L.paste(d, 22, 216 - C.CH + 1)
    # the Suitcase drifting through, trailing motion ticks
    sc = C.suitcase()
    L.paste(sc, 124, 84)
    for k in range(3):
        L.hline(124 + sc.w + 1, 124 + sc.w + 7 - 2 * k, 90 + k * 5, "slate")
    # Dubi's news ticker (runs through the lower band; copy is placeholder, owned by the designer)
    L.rect(0, 278, SW, 13, "ink")
    L.rect(SW - 30, 278, 30, 13, "red")
    F.draw(L, "מבזק", SW - 4, 280, "white")
    F.draw(L, "הקוסם הוציא עוד סבב בחירות מהכובע · הציבור נרגש · ", SW - 34, 280, "silver")
    L.rect(SW - 30, 278, 1, 13, "white")
    # tap prompt: primary button colour, pointing up at the hat
    tw = F.measure(TAP)
    bx0, by0 = SW // 2 - tw // 2 - 6, 250
    L.rect(bx0, by0, tw + 12, 15, "flag")
    L.hline(bx0, bx0 + tw + 11, by0, "flag_hi")
    L.hline(bx0, bx0 + tw + 11, by0 + 15, "ink")
    for p in [(bx0, by0), (bx0 + tw + 11, by0), (bx0, by0 + 14), (bx0 + tw + 11, by0 + 14)]:
        L.set(*p, "night")
    F.draw(L, TAP, SW // 2 + tw // 2, by0 + 3, "white")
    for k in range(3):                                   # the chevron ^ above the button
        L.hline(SW // 2 - k, SW // 2 + k, 242 + k, "white")
    # disclaimer strip (UX owns final wording; <= 28 glyphs fits one line at 180px)
    L.rect(0, 303, SW, 17, "ink")
    F.draw(L, DISCLAIMER, SW // 2 + F.measure(DISCLAIMER) // 2, 307, "grey")
    return L


if __name__ == "__main__":
    L = build()
    L.to_image(4).save(os.path.join(OUT, "title.png"))
    L.to_image(1).convert("L").resize((360, 640), 0).save(os.path.join(OUT, "proofs", "title-squint-greyscale.png"))
    print("title.png", F.measure(SUBTITLE), F.measure(DISCLAIMER))
