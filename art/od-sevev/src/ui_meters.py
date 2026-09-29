"""Meters and chips: the "מנדטים X/61" seats bar, the suspicion thermometer (with the hatched
carried-over floor), the 27.10 countdown chip, and the ultimatum countdown chip.

UX sources (creative-pack ux/first-minute.md 3.2): seats bar = SEGMENTED horizontal fill from the
RIGHT, a tick every 10, gold rim at >= 61; thermometer = VERTICAL fill bottom-up, 4 ticks, icon swap
magnifier -> gavel, bubbles; the floor (pitch 11 Q8) = a hatched segment at the bottom of the tube.
Different SHAPES for the two meters, so they never read as the same gauge.
"""
import math
from pix import Layer
from kit import save, panel, capsule, grid_layer, outline_inplace, chamfer, strip, hatch

G = "meters"


# ------------------------------------------------------------------ seats bar
def seats():
    W, H = 12, 9
    t = Layer(W, H)
    t.rect(0, 0, W, H, "night")
    t.hline(0, W - 1, 0, "outline")
    t.hline(0, W - 1, H - 1, "ui_bub_hi")            # light lower lip = a sunken well
    t.vline(0, 0, H - 1, "outline"); t.vline(W - 1, 0, H - 1, "outline")
    t.hline(1, W - 2, 1, "ui_scrim")                 # inner top shadow
    save(t, "seats_track", G, slice=[2, 2, 2, 2],
         notes="Seats bar well. UX 228x16 CSS -> 105x7 art; ship it at 106x9 (fill area x1..104, y1..7 = 7 rows). "
         "Fill grows from the RIGHT edge (RTL). Row B is one 180x20 hit row that opens the chat.")
    f = Layer(6, 7)
    rows = ["white", "sky", "sky", "sky", "sky", "flag_hi", "flag_hi"]
    for y, c in enumerate(rows):
        f.hline(0, 5, y, c)
    f.vline(0, 0, 6, "white")                        # leading (left) edge glint
    f.set(0, 6, "sky")
    save(f, "seats_fill", G, slice=[1, 1, 1, 2], label="ink",
         notes="Seats fill: sky ramp (not flag blue, which is the Magician's; not gold, which is money). "
               "Anchor RIGHT, width = round(104 * seats / 61). Fill vs empty well: sky on night 7.8:1.")
    k = Layer(1, 7)
    k.vline(0, 0, 6, "night")
    save(k, "seats_tick", G,
         notes="Segment notch, drawn every 10 seats at x = right - round(104 * n / 61), n = 10..60. It shows only over the "
               "fill (on the empty well it is the well colour): the segmented read of UX 3.2.")
    GW, GH = W + 8, H + 8
    g = Layer(GW, GH)
    g.rect(0, 0, GW, GH, "outline")
    g.rect(1, 1, GW - 2, GH - 2, "gold")
    g.hline(1, GW - 2, 1, "gold_hi"); g.vline(1, 1, GH - 2, "gold_hi")
    g.hline(1, GW - 2, GH - 2, "gold_sh"); g.vline(GW - 2, 2, GH - 2, "gold_sh")
    g.rect(3, 3, GW - 6, GH - 6, "outline")
    for y in range(4, GH - 4):
        for x in range(4, GW - 4):
            g.px[y][x] = None
    chamfer(g, 0, 0, GW, GH, 1)
    save(g, "seats_goal_frame", G, slice=[5, 5, 5, 5],
         notes="At >= 61 seats: a gold frame whose 4px ring sits OUTSIDE the track (place it at track -4,-4, size +8,+8) (gold = the reward moment). The pulse is the "
               "Animator's; the frame alone carries the state under reduced motion.")


# ------------------------------------------------------------------ thermometer
TH_W, TH_H = 14, 88
TUBE_X0, TUBE_X1 = 3, 10          # outer x of the glass tube
IN_X0, IN_X1 = 5, 8               # the liquid column (4 px)
IN_TOP, IN_BOT = 3, 73            # liquid column y range (70 rows of travel above the neck)
BULB_C, BULB_R = (6.5, 80.5), 6.6
TH_H_SHORT = 58                   # thermo_tube_short (UX rtl-map §4: stages under 560 logical)


def _tube(h):
    """The tube at height h. Everything below the column (neck, bulb) is anchored to the bottom, so the
    short tube is the full one with 30 rows of column taken out: same bulb, same neck, same glint and
    tick grammar, only the travel changes (70 rows -> 40)."""
    dy = h - TH_H                                  # 0 for the full tube, -30 for the short one
    in_bot = IN_BOT + dy
    bulb = (BULB_C[0], BULB_C[1] + dy)
    L = Layer(TH_W, h)
    # bulb
    L.ellipse(bulb[0], bulb[1], BULB_R, BULB_R, "red")
    for y in range(h):
        for x in range(TH_W):
            if L.get(x, y) == "red":
                ddx, ddy = x - bulb[0], y - bulb[1]
                if ddx + ddy > 4.5:
                    L.set(x, y, "red_dk")
    L.rect(3, 76 + dy, 2, 2, "red_hi"); L.set(3, 78 + dy, "red_hi")
    L.set(4, 76 + dy, "white")
    # glass tube with a rounded top
    L.rect(TUBE_X0, 0, TUBE_X1 - TUBE_X0 + 1, 76 + dy, "slate")
    chamfer(L, TUBE_X0, 0, TUBE_X1 - TUBE_X0 + 1, 76 + dy, 2)
    L.rect(IN_X0, IN_TOP, IN_X1 - IN_X0 + 1, in_bot - IN_TOP + 1, "ui_scrim")   # the empty column (red on it 3.7:1)
    L.rect(IN_X0, in_bot + 1, 4, 3, "red")                                       # neck, always full
    L.vline(TUBE_X0 + 1, 3, 70 + dy, "silver")                                   # glass glint, left wall
    L.set(TUBE_X0 + 1, 2, "white")
    L.vline(TUBE_X1 - 1, 4, 72 + dy, "suit_hi")                                  # right wall in shade
    outline_inplace(L)
    # redraw the inner edge of the column as outline for a crisp tube
    for y in range(IN_TOP - 1, in_bot + 1):
        L.set(IN_X0 - 1, y, "outline") if y < IN_TOP else None
    # ticks: 25 / 50 / 75 / 100 %, right side; 75 and 100 are longer (the critical band starts at 75)
    for p in (0.25, 0.5, 0.75, 1.0):
        y = in_bot - round(p * (in_bot - IN_TOP))
        n = 3 if p >= 0.75 else 2
        for i in range(n):
            L.set(TUBE_X1 + 1 + i, y, "silver")
    return L, in_bot


def thermo():
    L, in_bot = _tube(TH_H)
    save(L, "thermo_tube", G, pivot=[6, 87],
         notes=f"Suspicion thermometer ('חשד'), fixed size {TH_W}x{TH_H}; left edge of the stage (UX hit 44x218 CSS = 20x100 art). "
               f"Liquid column x {IN_X0}..{IN_X1}, y {IN_TOP}..{in_bot} (bottom-up). y_top(p) = {in_bot} - round(p * {in_bot - IN_TOP}). "
               "Ticks at 25/50/75/100 %. Icon (magnifier / gavel) sits centred above at y -13.",
         extra={"liquid": {"x": IN_X0, "w": IN_X1 - IN_X0 + 1, "yTop": IN_TOP, "yBottom": in_bot}})
    S, s_bot = _tube(TH_H_SHORT)
    save(S, "thermo_tube_short", G, pivot=[6, TH_H_SHORT - 1],
         notes=f"The same thermometer for stages under 560 logical px (UX rtl-map §4), {TH_W}x{TH_H_SHORT}: bulb, neck, glint "
               f"and ticks identical to thermo_tube, the column shortened to {s_bot - IN_TOP} rows of travel. Liquid column "
               f"x {IN_X0}..{IN_X1}, y {IN_TOP}..{s_bot}; y_top(p) = {s_bot} - round(p * {s_bot - IN_TOP}). Every other thermo_* "
               "piece (fill, meniscus, floor hatch, icons, bubbles) is shared. Icon sits centred above at y -13, as on the full tube.",
         extra={"liquid": {"x": IN_X0, "w": IN_X1 - IN_X0 + 1, "yTop": IN_TOP, "yBottom": s_bot}})
    f = Layer(4, 1)
    for x, c in enumerate(["red_hi", "red", "red", "red_dk"]):
        f.set(x, 0, c)
    save(f, "thermo_fill", G, notes="Live suspicion: stretch this 4x1 row vertically from the floor's top to y_top(p).")
    m = Layer(4, 1)
    for x, c in enumerate(["white", "red_hi", "red_hi", "red"]):
        m.set(x, 0, c)
    save(m, "thermo_meniscus", G, notes="1 row drawn at y_top(p): the liquid's lit surface.")
    h = Layer(4, 4)
    hatch(h, 0, 0, 4, 4, "red", "outline", period=4, on=2, slope=-1)
    save(h, "thermo_floor_hatch", G, mode="tile",
         notes="The carried-over floor (pitch 11 Q8: min(5% x n, 40%)): TILE this 4x4 from y_bottom up to y_top(floor). "
               "Diagonal red/black stripes = a SHAPE channel: 'this part came with you from the last round' (the same hazard stripe as the ultimatum border). Live fill stacks above it: red vs the black stripe 3.8:1, red vs empty 3.7:1.")
    # icons 11x11
    leg = {"k": "outline", "s": "silver", "w": "white", "b": "sky", "l": "slate", "o": "wood", "O": "wood_dk",
           "y": "stone", "Y": "stone_sh"}
    mag = [
        "..kkkkk....",
        ".kwbbbbk...",
        "kwbbbbbbk..",
        "kbbbbbbbk..",
        "kbbbbbbbk..",
        "kbbbbbbbk..",
        ".kbbbbbk...",
        "..kkkkkok..",
        "......kook.",
        ".......kook",
        "........kk.",
    ]
    gav = [
        ".kkkkkkk...",
        "kyooooook..",
        "kyooooook..",
        "kYOOOOOOk..",
        ".kkkkkkkk..",
        "....kok....",
        "....kok....",
        "....kok....",
        "....kok....",
        ".kkkkkkkkk.",
        "kyyyyyyyyYk",
    ]
    save(grid_layer(mag, leg), "thermo_icon_magnifier", G, state="below_75",
         notes="Suspicion < 75 %: 'being looked at'. Sits centred above the tube.")
    save(grid_layer(gav, leg), "thermo_icon_gavel", G, state="75_plus",
         notes="Suspicion >= 75 % (and the court card): the icon swap is a non-colour channel.")
    # bubbles: 3 sizes in 5x5 cells
    cells = []
    for rows in ([".....", ".....", "..r..", ".....", "....."],
                 [".....", "..r..", ".r.r.", "..r..", "....."],
                 [".rrr.", "r...r", "r.w.r", "r...r", ".rrr."]):
        cells.append(grid_layer(rows, {"r": "rim", "w": "white"}))
    save(strip(cells), "thermo_bubble", G, frames=3, frame_w=5,
         notes="Boil bubbles inside/above the column at >= 75 %. Frame 2 is the static bubble icon for reduced motion.")


# ------------------------------------------------------------------ chips
def chips():
    c = capsule(20, 13, "ui_panel", "ui_bub_hi", "ui_scrim", r=2)
    save(c, "chip_countdown", G, slice=[4, 3, 13, 3], content=[3, 2, 5, 9], label="white",
         notes="'27.10 · עוד 29 ימים' (UX: 60% alpha, 100% on the first view of a day). Calendar icon at the RIGHT "
               "(x w-12, y 2). white on ui_panel 15.0:1.")
    cal = [
        ".k.k.k.k.",
        "kbkbkbkbk",
        "kbbbbbbbk",
        "kwwwwwwwk",
        "kwiwiwiwk",
        "kwwwwwwwk",
        "kwiwiwwwk",
        "kwwwwwwpk",
        "kkkkkkkkk",
    ]
    save(grid_layer(cal, {"k": "outline", "b": "sky", "w": "white", "i": "slate", "p": "paper"}), "chip_icon_calendar", G,
         notes="Tear-off calendar page, 9x9 (the 27.10 chip and the receipt's countdown line).")
    u = capsule(20, 13, "red", "red_hi", "red_dk", r=2)
    save(u, "chip_ultimatum", G, slice=[4, 3, 13, 3], content=[3, 2, 5, 9], label="white",
         notes="Ultimatum countdown '0:45' with icon_clock at the RIGHT (x w-12, y 2). white on red 4.7:1. "
               "Channels: the clock (shape), the digits (text), red (colour), and it sits in the hatched bubble.")


def build():
    seats(); thermo(); chips()


if __name__ == "__main__":
    build()
    from kit import write_manifest
    print(write_manifest())
