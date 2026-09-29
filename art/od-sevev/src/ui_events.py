"""Event art: the rubber stamp and its impressions, the dust-cloud brawl, the "חלון העברות" transfer
banner, and the court-day overlay frame + collapsed chip.

Stamp ink is bureaucracy violet (`stamp` on paper, `stamp_lt` on dark surfaces): not red (danger),
not gold (money), not maroon (the Suitcase). Stamps are axis-aligned: rotating pixel art smears it,
so 'hand-stamped' is carried by ink speckle (alpha holes) and one starved corner instead.
"""
import random

from pix import Layer
from kit import save, strip, panel, capsule, outline_inplace, grid_layer, chamfer, speckle, rotate_shear
import hebfont
from wordmark import render as display

G = "events"


# ------------------------------------------------------------------ the rubber stamp (tool)
def stamp_tool(down=False):
    L = Layer(18, 24)
    dy = 2 if down else 0
    # knob
    L.ellipse(8.5, 3 + dy, 4.2, 3.0, "wood")
    for (x, y) in [(6, 1), (7, 1), (6, 2), (5, 3)]:
        L.set(x, y + dy, "stone_sh")
    for (x, y) in [(11, 4), (12, 3), (10, 5), (11, 5), (12, 4)]:
        L.set(x, y + dy, "wood_dk")
    # neck
    L.rect(7, 6 + dy, 4, 5 - dy, "wood_dk")
    L.vline(7, 6 + dy, 10, "wood")
    # metal collar
    L.rect(4, 11, 10, 2, "slate")
    L.hline(4, 13, 11, "silver")
    # block
    top = 13
    bh = 5 if not down else 4
    L.rect(1, top, 16, bh, "wood")
    L.hline(1, 16, top, "stone_sh")
    L.vline(16, top, top + bh - 1, "wood_dk")
    L.hline(1, 16, top + bh - 1, "wood_dk")
    # rubber + inked face
    py = top + bh
    L.rect(2 if not down else 1, py, 14 if not down else 16, 1, "hair_dk")
    L.rect(2 if not down else 1, py + 1, 14 if not down else 16, 2, "stamp")
    outline_inplace(L)
    return L


def stamp_impression(lines, ink, seed):
    widths = [hebfont.measure(t) for t in lines]
    tw = max(widths)
    bw = 3                                      # outer line, gap, inner line
    padx, pady = 3, 1
    W = tw + 2 * (bw + padx)
    H = 10 * len(lines) - 1 + 2 * (bw + pady)
    L = Layer(W, H)
    L.rect(0, 0, W, H, ink)
    for y in range(1, H - 1):                   # the gap between the two border lines
        for x in range(1, W - 1):
            if x in (1, W - 2) or y in (1, H - 2):
                L.px[y][x] = None
    for y in range(3, H - 3):                   # the inner field
        for x in range(3, W - 3):
            L.px[y][x] = None
    for k, t in enumerate(lines):
        hebfont.draw(L, t, W // 2, bw + pady + 10 * k, ink, align="center")
    speckle(L, ink, None, seed, 0.10, box=(0, 0, W, 3))           # borders take the most wear
    speckle(L, ink, None, seed + 2, 0.10, box=(0, H - 3, W, 3))
    speckle(L, ink, None, seed + 3, 0.10, box=(0, 3, 3, H - 6))
    speckle(L, ink, None, seed + 4, 0.10, box=(W - 3, 3, 3, H - 6))
    speckle(L, ink, None, seed + 5, 0.035, box=(3, 3, W - 6, H - 6))  # the text stays legible
    rnd = random.Random(seed + 1)               # one ink-starved corner: the stamp was pressed unevenly
    cx, cy = (W - 1, H - 1) if rnd.random() < 0.5 else (W - 1, 0)
    for y in range(H):
        for x in range(W):
            if abs(x - cx) + abs(y - cy) < 3 + rnd.random() * 1.5:
                L.px[y][x] = None
    return L


STAMPS = {
    "pardon": (["נדרשים מסמכים", "נוספים"], "The pardon desk's answer (brief round 2; copy deck 'stamp lines' #1)."),
    "postponed": (["נדחה"], "Court card after a postponement (UX court.stamp)."),
    "paid": (["שולם"], "Replaces the pay pill in the chat after paying (UX chat.paid)."),
    "blackout": (["חסוי עד 27.10"], "Row B during the poll blackout, in place of the 58/61 numeral (UX 6.3 hud.seats.blackout)."),
}


def stamps():
    save(stamp_tool(False), "stamp_tool_up", G, state="up", pivot=[8, 23],
         notes="The pardon desk's rubber stamp, key pose UP. Timing and squash are the Animator's.")
    save(stamp_tool(True), "stamp_tool_down", G, state="down", pivot=[8, 23],
         notes="Key pose DOWN: handle 2 px lower, block 1 row squashed, pad spread to full width.")
    for i, (key, (lines, note)) in enumerate(STAMPS.items()):
        for ink, surf in (("stamp", "paper"), ("stamp_lt", "dark")):
            imp = stamp_impression(lines, ink, 100 + i)
            save(imp, f"stamp_{key}_{surf}", G, state=surf,
                 notes=note + f" Ink {ink} for {surf} surfaces ("
                 + ("5.6:1 on paper, 7.3:1 on receipt" if ink == "stamp" else "6.4:1 on ui_bubble, 4.9:1 on ui_out") + ").")
            rot = rotate_shear(imp, 8)
            save(rot, f"stamp_{key}_{surf}_rot", G, state=surf + "_rotated", pivot=[rot.w // 2, rot.h // 2],
                 notes="The same impression PRE-ROTATED 8 deg counter-clockwise (Godot rotation -8 deg; Animator's ask: no "
                       "runtime rotation of pixel text). Three-shear rotation: every ink pixel moved, none invented or smeared. "
                       "Pivot = centre (the slam lands on it).")
    # generic frame for the other pardon lines (engine sets the text in the same ink)
    for ink, surf in (("stamp", "paper"), ("stamp_lt", "dark")):
        L = Layer(16, 14)
        L.rect(0, 0, 16, 14, ink)
        for y in range(1, 13):
            for x in range(1, 15):
                if x in (1, 14) or y in (1, 12) or (3 <= x <= 12 and 3 <= y <= 10):
                    L.px[y][x] = None
        speckle(L, ink, None, 7, 0.09)
        save(L, f"stamp_frame_{surf}", G, slice=[4, 4, 4, 4], mode="tile", content=[4, 3, 8, 8], label=ink,
             notes="Double-line stamp border for the other 7 pardon lines (copy deck). TILE so the speckle never smears; "
                   "draw the text in the same ink; add no rotation.")


# ------------------------------------------------------------------ the brawl dust cloud (4-frame loop)
BW, BH = 52, 40
PUFFS = [
    [(15, 22, 8), (23, 15, 9), (33, 16, 8), (38, 24, 7), (26, 26, 9), (13, 29, 6), (32, 30, 6)],
    [(14, 21, 8), (24, 14, 8), (34, 17, 9), (37, 26, 7), (25, 26, 9), (14, 29, 7), (31, 31, 6)],
    [(16, 23, 9), (23, 16, 8), (32, 15, 8), (39, 23, 6), (27, 27, 9), (12, 28, 6), (33, 31, 7)],
    [(15, 21, 7), (22, 15, 9), (33, 15, 8), (38, 25, 8), (25, 27, 8), (14, 30, 7), (31, 30, 6)],
]


def _arm(L, x, y, dx, dy, n=7):
    """A suit sleeve (4 px) with a white cuff and a big fist, pointing along (dx, dy) from (x, y)."""
    for i in range(n):
        cx, cy = x + dx * i, y + dy * i
        L.rect(cx - 2, cy - 2, 4, 4, "suit_hi")
        L.set(cx - 2, cy - 2, "grey"); L.set(cx - 1, cy - 2, "grey")
        L.set(cx + 1, cy + 1, "suit")
    cx, cy = x + dx * n, y + dy * n
    L.rect(cx - 2, cy - 2, 4, 4, "white")
    fx, fy = x + dx * (n + 3), y + dy * (n + 3)
    L.rect(fx - 3, fy - 3, 6, 6, "skin")
    L.hline(fx - 3, fx + 2, fy + 2, "skin_sh"); L.vline(fx + 2, fy - 3, fy + 2, "skin_sh")
    L.hline(fx - 2, fx, fy - 3, "skin_hi")
    L.hline(fx - 2, fx + 1, fy - 1, "skin_dk")        # knuckle line: it is a fist, not a mitten


def _leg(L, x, y, dx, dy, n=6):
    for i in range(n):
        cx, cy = x + dx * i, y + dy * i
        L.rect(cx - 2, cy - 2, 4, 4, "suit_hi")
        L.set(cx + 1, cy + 1, "suit")
    sx, sy = x + dx * n, y + dy * n
    x0 = sx - 2 if dx >= 0 else sx - 5
    L.rect(x0, sy - 2, 8, 4, "hair_dk")
    L.hline(x0 + 1, x0 + 4, sy - 2, "slate")
    L.hline(x0, x0 + 7, sy + 1, "outline")


def _paper(L, x, y):
    L.rect(x, y, 5, 6, "white")
    L.hline(x + 1, x + 3, y + 2, "paper"); L.hline(x + 1, x + 3, y + 4, "paper")


def _star(L, x, y):
    for (dx, dy) in [(0, -2), (0, -1), (-2, 0), (-1, 0), (0, 0), (1, 0), (2, 0), (0, 1), (0, 2)]:
        L.set(x + dx, y + dy, "white")


LIMBS = [  # (kind, dx, dy, visible length) per frame, rays out of the cloud centre
    [("arm", -1, -1, 4), ("leg", 1, 1, 3)],
    [("arm", 1, -1, 4), ("leg", -1, 1, 3)],
    [("arm", -1, 1, 3), ("arm", 1, 0, 4)],
    [("arm", 0, -1, 3), ("leg", 1, 1, 3), ("arm", -1, 0, 2)],
]


def brawl_frame(k):
    puffs = [(x, y, r * 0.85) for (x, y, r) in PUFFS[k]]
    cloud = Layer(BW, BH)
    for (cx, cy, r) in puffs:
        cloud.ellipse(cx, cy, r, r, "paper")
    back = Layer(BW, BH)
    ccx, ccy = 26, 22
    for (kind, dx, dy, vis) in LIMBS[k]:
        x, y = ccx, ccy
        while cloud.get(x, y) is not None:            # walk to the cloud's edge along the ray
            x += dx; y += dy
        x -= 2 * dx; y -= 2 * dy                      # start 2 steps inside, so the limb emerges from it
        (_arm if kind == "arm" else _leg)(back, x, y, dx, dy, vis + 2)
    outline_inplace(back)
    for y in range(BH):
        for x in range(BW):
            if cloud.get(x, y) != "paper":
                continue
            best = min(puffs, key=lambda p: ((x - p[0]) ** 2 + (y - p[1]) ** 2) / (p[2] ** 2))
            dx, dy = (x - best[0]) / best[2], (y - best[1]) / best[2]
            if dx + dy > 0.75:
                cloud.set(x, y, "stone_sh")
            elif dx + dy < -0.95:
                cloud.set(x, y, "white")
            elif dx + dy > 0.35:
                cloud.set(x, y, "stone")
    outline_inplace(cloud)
    L = Layer(BW, BH)
    L.paste(back, 0, 0)
    L.paste(cloud, 0, 0)
    fx = Layer(BW, BH)
    spots = [[(40, 3), (27, 4)], [(4, 6), (24, 3)], [(42, 3), (5, 5)], [(5, 26), (46, 9)]][k]
    _paper(fx, *spots[0])
    _star(fx, *spots[1])
    L.paste(fx.outlined(pad=0), 0, 0)
    return L


def brawl():
    frames = [brawl_frame(k) for k in range(4)]
    save(strip(frames), "brawl_cloud", G, frames=4, frame_w=BW, pivot=[BW // 2, BH - 4],
         notes="Dust-cloud brawl (brief round 2: Amsalem vs Smotrich, recurring for any pair). 4-frame loop; the cloud "
               "sits over the two frozen income rows / the chat line. Sleeves, fists, shoes, a flying page: NO faces, "
               "no kippot, no religious markers, no weapons. Suggested 8 fps; timing is the Animator's; reduced motion = frame 0.")


# ------------------------------------------------------------------ "חלון העברות" transfer banner
def transfer():
    W, H = 180, 30
    L = Layer(W, H)
    L.rect(0, 0, W, H, "outline")
    L.hline(0, W - 1, 1, "gold_sh"); L.hline(0, W - 1, H - 2, "gold_sh")
    for x0 in (4, W - 34):                             # broadcast speed-stripes at both ends
        for s in range(5):
            for y in range(4, H - 4):
                for w in range(3):
                    x = x0 + s * 6 + w + (H - 4 - y) // 2
                    if x0 <= x < x0 + 30:
                        L.set(x, y, "gold" if w < 2 else "gold_sh")
    txt = display("חלון העברות", 11, 2, ext=1, rim=None)
    L.rect((W - txt.w) // 2 - 4, 3, txt.w + 8, H - 6, "outline")
    L.paste(txt, (W - txt.w) // 2, 3)
    save(L, "transfer_banner", G, slice=[40, 3, 40, 3],
         notes="Football-style transfer strip (UX 4.2): black, gold display lettering 'חלון העברות' (letters.py, cap 11). "
               "Centre patch holds the lettering: stretch only by widening beyond 180 via the stripe patches' edges. "
               "Below it the engine sets the name large + '{from} ← {to} · כולל דמי אחזקה' on transfer_card.")
    c = panel(24, 16, "ui_panel", "ui_bub_hi", "ui_scrim")
    c.hline(1, 22, 1, "gold_sh")
    save(c, "transfer_card", G, slice=[3, 3, 3, 3], content=[4, 3, 16, 10], label="white",
         notes="The card body under transfer_banner. white on ui_panel 15.0:1; the name line may use gold_hi (money).")


# ------------------------------------------------------------------ court day
def court():
    W, H = 40, 36
    L = Layer(W, H)
    L.rect(0, 0, W, H, "wood")
    L.hline(1, W - 2, 1, "stone_sh"); L.vline(1, 1, H - 2, "stone_sh")
    L.hline(1, W - 2, H - 2, "wood_dk"); L.vline(W - 2, 2, H - 2, "wood_dk")
    L.rect(3, 3, W - 6, H - 6, "red")                  # the steady danger line (never flashes)
    L.rect(4, 4, W - 8, H - 8, "teal_dk")
    L.rect(4, 4, W - 8, 13, "wood")                    # header plate
    L.hline(4, W - 5, 4, "stone_sh")
    L.hline(4, W - 5, 16, "wood_dk")
    L.hline(4, W - 5, 17, "outline")
    L.hline(4, W - 5, 18, "teal")                      # the lit top of the teal body
    chamfer(L, 0, 0, W, H, 1)
    outline_inplace(L)
    save(L, "court_frame", G, slice=[6, 20, 6, 6], content=[6, 20, W - 12, H - 26], label="white",
         notes="Court-day card (UX O2, non-modal, over the panel). Header plate y 4..16: title 'יום משפט' white on wood "
               "5.6:1, gavel icon (thermo_icon_gavel) at the RIGHT, x w-18 y 5. Body teal_dk: body text white 11.1:1, timer "
               "'עדות: mm:ss'. The red inner line is the steady court tint (UX: no strobe). Buttons: button_primary "
               "('התייעצות ביטחונית · {price} ₪') + button_secondary ('להעיד').")
    c = capsule(20, 13, "teal_dk", "teal", "outline", r=2)
    c.hline(2, 17, 11, "red")
    save(c, "chip_court", G, slice=[4, 3, 13, 3], content=[3, 2, 5, 9], label="white",
         notes="Collapsed court card: 'יום משפט · {mm:ss}' + chip_icon_gavel at the RIGHT (x w-12, y 2). white on teal_dk 11.1:1.")
    gav = [
        "kkkkkkk..",
        "kyoooook.",
        "kYOOOOOk.",
        "kkkkkkkk.",
        "...kok...",
        "...kok...",
        "...kok...",
        "kkkkkkkk.",
        "kyyyyyYk.",
    ]
    save(grid_layer(gav, {"k": "outline", "y": "stone", "Y": "stone_sh", "o": "wood", "O": "wood_dk"}),
         "chip_icon_gavel", G, notes="9x9 gavel for chip_court (the 11x11 thermo_icon_gavel is the large one).")


def build():
    stamps(); brawl(); transfer(); court()


if __name__ == "__main__":
    build()
    from kit import write_manifest
    print(write_manifest())
