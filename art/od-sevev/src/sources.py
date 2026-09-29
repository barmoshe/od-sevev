"""Wave 3: the three OBJECT money sources, hand-drawn (ChatGPT budget is out) to sit beside the
rendered critters (taxpayer / hitech / VAT at 40 art px): dense 3-4 band shading, near-black outline,
pale rim, a friendly mascot read (the VAT machine has a face, so the submarine gets porthole eyes).

  source_submarine  (הצוללת)            f1 = hull +1 ap up, the periscope held level   (idle 800 ms)
  source_poison     (מכונת הרעל)        f1 = the LED rows swap (odd lit -> even lit)     (idle 400 ms)
  source_checkbook  (פנקס הצ׳קים הזהוב)  f1 = a 2-px glint on the gold edge + the top page corner lifts 1 ap (700 ms)
Each is a 2-frame strip, 40 art px tall INCLUDING outline and rim; pivot = bottom-centre (feet line).
f0 is the rest pose and the source of the 24x24 shop icon crop (motion/diorama-motion.md §1).
No flags, no navy markings, no seals, no eagle, no real logos (content.json visualHooks).
"""
import math
from pix import Layer
from kit import save, strip, grid_layer, with_rim

G = "sources"
H_ART = 40


def finish(L):
    """external 1 px outline + pale rim: +2 px each side."""
    return with_rim(L.outlined(pad=1))


def frame_pair(f0, f1, sid, name, idle_ms, recipe, icon_box):
    a, b = finish(f0), finish(f1)
    assert a.h == H_ART and (a.w, a.h) == (b.w, b.h), (sid, a.w, a.h, b.w, b.h)
    save(strip([a, b]), f"source_{sid}", G, frames=2, frame_w=a.w, pivot=[a.w // 2, a.h - 1],
         notes=f"Money source '{name}' for the diorama: 40 art px tall incl. outline + pale rim (x4 in game). "
               f"2-frame idle, equal holds, idleFrameMs {idle_ms}: f1 = {recipe}. Pivot = bottom-centre. "
               "Hand-drawn graphic tier (ChatGPT budget exhausted), matched to the rendered critters' density.")
    x, y, w, h = icon_box
    ic = Layer(24, 24)
    for yy in range(24):
        for xx in range(24):
            if 0 <= y + yy < a.h and 0 <= x + xx < a.w:
                ic.px[yy][xx] = a.px[y + yy][x + xx]
    save(ic, f"source_{sid}_icon", G, notes=f"Shop-card icon for '{name}': a 24x24 crop of f0 at 1:1 (no rescale), "
         "centred on card_plate (26x26).")


# ------------------------------------------------------------------ the submarine
def _sub(bob):
    W, H = 46, 36
    L = Layer(W, H)
    dy = -1 if bob else 0
    # periscope FIRST (behind the sail) and never bobbing: 'the periscope sees everything'
    L.rect(31, 3, 2, 15, "suit")
    L.vline(31, 3, 17, "slate")
    L.rect(31, 1, 6, 3, "suit_dk"); L.hline(31, 35, 1, "slate")
    L.set(36, 2, "sky"); L.set(36, 3, "flag_hi")
    hull = Layer(W, H)
    cy = 26 + dy
    # hull body
    hull.ellipse(23, cy, 21, 6.5, "slate")
    for y in range(H):
        for x in range(W):
            if hull.get(x, y) == "slate":
                ny = (y - cy) / 6.5
                if ny < -0.55:
                    hull.set(x, y, "grey")
                elif ny > 0.45:
                    hull.set(x, y, "suit")
    hull.hline(8, 36, cy - 5, "silver")                               # the lit top line
    # an orange stripe (no navy markings, no flag): a toy boat, not a navy
    for x in range(4, 43):
        for y in range(H):
            if hull.get(x, y) in ("slate", "suit", "grey") and y == cy + 2:
                hull.set(x, y, "orange")
                if hull.get(x, y + 1) in ("slate", "suit"):
                    hull.set(x, y + 1, "orange_sh")
    # tail fin + propeller on the left
    for i in range(5):
        hull.vline(2 + i, cy - 4 + i, cy + 4 - i, "suit")
    hull.rect(0, cy - 2, 2, 5, "orange_sh"); hull.set(0, cy - 2, "orange")
    # the sail (conning tower)
    hull.rect(19, 13 + dy, 12, 9, "slate")
    hull.hline(20, 29, 13 + dy, "grey"); hull.vline(19, 14 + dy, 21 + dy, "grey")
    hull.vline(30, 14 + dy, 21 + dy, "suit")
    hull.px[13 + dy][19] = None; hull.px[13 + dy][30] = None
    for x in (21, 24, 27):
        hull.set(x, 17 + dy, "silver")                                # rivets
    # the open hatch and the cash poking out of it
    hull.rect(21, 11 + dy, 7, 2, "suit_dk")                           # hatch rim
    hull.hline(22, 26, 11 + dy, "suit")
    lid = [(18, 8), (19, 9), (20, 10), (18, 9), (19, 10)]
    for (x, y) in lid:
        hull.set(x, y + dy, "grey")
    for bx, by in ((22, 4), (25, 3), (23, 6)):                         # three bills fanned upward
        hull.rect(bx, by + dy, 3, 6, "lime")
        hull.vline(bx + 2, by + dy, by + 5 + dy, "green")
        hull.set(bx + 1, by + 2 + dy, "green_sh")
    hull.rect(27, 7 + dy, 3, 3, "gold"); hull.set(27, 7 + dy, "gold_hi"); hull.set(29, 9 + dy, "gold_sh")  # a coin
    # the face: two porthole eyes and a small smile (the VAT machine's mascot register)
    for ex in (14, 23):
        hull.ellipse(ex, cy - 1, 2.6, 2.6, "orange")
        hull.ellipse(ex, cy - 1, 1.6, 1.6, "sky")
        hull.set(ex - 1, cy - 2, "white")
        hull.set(ex + 1, cy, "ink"); hull.set(ex, cy, "ink")
    for (x, y) in [(17, 1), (18, 2), (19, 2), (20, 1)]:
        hull.set(x, cy + y + 1, "ink")
    L.paste(hull, 0, 0)
    # the water (does not bob): foam line, two value bands
    for x in range(W):
        wy = 31 + (1 if (x // 4) % 2 else 0)
        for y in range(wy, H):
            L.set(x, y, "sky" if y < wy + 2 else "flag_hi")
        L.set(x, wy, "white" if (x // 4) % 2 == 0 else "sky")
    return L


# ------------------------------------------------------------------ the poison machine
def _poison(swap):
    W, H = 30, 36
    L = Layer(W, H)
    # antennas (lime tips: the signal, not danger)
    for ax, top in ((6, 0), (15, 2), (23, 1)):
        L.vline(ax, top + 1, 7, "grey")
        L.set(ax, top, "lime")
        L.set(ax - 1, top, "green") if ax != 15 else L.set(ax + 1, top, "green")
    # cabinet
    L.rect(1, 7, W - 2, H - 7, "suit_dk")
    L.hline(1, W - 2, 7, "suit"); L.vline(1, 7, H - 1, "suit")
    L.vline(W - 2, 8, H - 1, "night")
    L.rect(3, 9, W - 6, 3, "night")                                   # top vent panel
    for x in range(4, W - 4, 2):
        L.set(x, 10, "slate")
    # 4 shelves x 3 phones, each phone: screen glow, a blank grey avatar, a tiny heart
    for r in range(4):
        sy = 13 + r * 6
        L.hline(3, W - 4, sy + 5, "slate")                            # the shelf
        for c in range(3):
            px = 4 + c * 8
            L.rect(px, sy, 6, 5, "night")
            L.rect(px + 1, sy + 1, 4, 3, "sky")
            L.set(px + 1, sy + 1, "white")
            L.rect(px + 2, sy + 2, 2, 2, "slate")                     # the blank avatar
            L.set(px + 4, sy + 3, "red")                              # the tiny heart
        # LED column at the right edge of the shelf: lit rows alternate between the frames
        lit = (r % 2 == 0) != swap
        L.set(W - 4, sy + 1, "lime" if lit else "green_sh")
        L.set(W - 4, sy + 3, "green_sh" if lit else "lime")
    L.rect(3, H - 2, W - 6, 1, "night")                                # plinth shadow
    return L


# ------------------------------------------------------------------ the golden chequebook
def _checkbook(glint):
    W, H = 38, 36
    L = Layer(W, H)
    # the marker, BEHIND the book, leaning up-right (a thick black marker with a silver clip)
    for i in range(12):
        x, y = 28 + i // 2, 2 + i
        L.rect(x, y, 3, 2, "hair_dk")
    L.rect(33, 0, 3, 3, "hair_dk"); L.set(34, 0, "white")              # the cap
    L.vline(31, 3, 8, "silver")                                         # the clip
    L.rect(28, 14, 3, 2, "ink")                                         # the felt tip, touching the page
    # the cover: gold, open, standing (a gold border shows around both pages)
    L.rect(0, 10, 34, 24, "gold")
    L.hline(0, 33, 10, "gold_hi"); L.vline(0, 10, 33, "gold_hi")
    L.hline(0, 33, 33, "gold_sh"); L.vline(33, 11, 33, "gold_sh")
    L.vline(16, 10, 33, "gold_dk"); L.vline(17, 10, 33, "gold_sh")     # the spine fold
    # two cheque pages
    for x0 in (2, 19):
        L.rect(x0, 12, 13, 19, "receipt")
        L.vline(x0 + 12, 12, 30, "receipt_sh")
        for ly in (16, 21, 26):                                         # printed lines
            L.hline(x0 + 1, x0 + 11, ly, "receipt_sh")
    # the right page: a signature scrawl and an amount box with a big number shape
    for (x, y) in [(21, 25), (22, 24), (23, 25), (24, 24), (25, 25), (26, 23), (27, 24), (28, 25)]:
        L.set(x, y, "ink")
    L.rect(21, 17, 8, 3, "receipt_sh"); L.hline(22, 27, 18, "ink")      # the amount: a long line of zeros
    for x in (23, 25, 27):
        L.set(x, 18, "receipt")
    # the left page: the stub, one small gold coin seal-less bookmark ribbon
    L.rect(3, 13, 4, 2, "gold_sh")
    L.vline(8, 30, 34, "red"); L.vline(9, 30, 35, "red_dk")             # a ribbon bookmark hanging out
    if glint:
        L.set(3, 11, "white"); L.set(4, 11, "white")                    # a 2-px glint on the gold edge
        L.set(33, 12, "white")
        L.set(31, 12, "receipt"); L.px[12][31] = "receipt"              # the top page corner lifts 1 ap
        L.set(30, 11, "receipt"); L.set(31, 11, "receipt_sh")
    return L


def build():
    frame_pair(_sub(False), _sub(True), "submarine", "הצוללת", 800,
               "the hull (sail, cash, face) 1 ap up while the periscope and the water hold still", (15, 1, 24, 24))
    frame_pair(_poison(False), _poison(True), "poison", "מכונת הרעל", 400,
               "the LED column swaps (even shelves lit -> odd shelves lit); a small area, under 3 Hz", (5, 10, 24, 24))
    frame_pair(_checkbook(False), _checkbook(True), "checkbook", "פנקס הצ׳קים הזהוב", 700,
               "a 2-px white glint on the gold edge + the right page's top corner lifted 1 ap", (16, 10, 24, 24))


if __name__ == "__main__":
    build()
    from kit import write_manifest
    print(write_manifest())
