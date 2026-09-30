"""B14 sign options: the Balfour stage with only the protest signs redrawn.

Reads the creative pack's locations.balfour() from a worktree off restore-s4 and swaps the one
sign block for an option's sign painter. Nothing else in the stage changes; every pixel stays on
the 45-swatch master palette. Writes per-option 1x / 3x PNGs and options-sheet.png.

usage: python3 mock_signs.py <worktree>
"""
import inspect, json, os, sys, textwrap
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

WT = sys.argv[1]
OUT = os.path.dirname(os.path.abspath(__file__))
sys.dont_write_bytecode = True
sys.path.insert(0, os.path.join(WT, "creative-pack", "art", "src"))
import locations
from palette import PAL, rgb

# ---------------------------------------------------------------- the one block we replace
SRC = textwrap.dedent(inspect.getsource(locations.balfour))
OLD = '''            if i % 2 == 0:                                        # blank sign on a stick
                sx = x + r.choice((-2, 1))
                L.vline(sx + 2, top - 6, top + 6, "wood")
                L.rect(sx - 2, top - 14, 10, 8, "pink" if (i // 2) % 2 == 0 else "white")
                L.hline(sx - 2, sx + 7, top - 7, "pink_sh" if (i // 2) % 2 == 0 else "paper")
'''
NEW = '''            if i % 2 == 0:                                        # B14: the option's sign painter
                sx = x + r.choice((-2, 1))
                SIGN(L, sx, top, i, side)
'''
assert OLD in SRC, "locations.balfour() sign block changed; update the mock"
PATCHED = SRC.replace(OLD, NEW)


def balfour_with(painter):
    ns = dict(vars(locations))
    ns["SIGN"] = painter
    exec(PATCHED, ns)
    return ns["balfour"]()


# ---------------------------------------------------------------- sign painters
# Geometry kept from the approved art: a 10x8 board at (sx-2, top-14), a stick at sx+2 from
# top-6 to top+6, a 1-row shade at the board's foot. k = sign index along the side (0..3).

def board(L, sx, top, fill, shade, stick="wood"):
    L.vline(sx + 2, top - 6, top + 6, stick)
    L.rect(sx - 2, top - 14, 10, 8, fill)
    L.hline(sx - 2, sx + 7, top - 7, shade)


def cur(L, sx, top, i, side):
    board(L, sx, top, "pink" if (i // 2) % 2 == 0 else "white", "pink_sh" if (i // 2) % 2 == 0 else "paper")


def opt_a(L, sx, top, i, side):
    """A: blue and white boards (colour only; no stripes, no star, so no flag object)."""
    k = i // 2
    if (k + side) % 2 == 0:
        board(L, sx, top, "white", "paper")
    else:
        board(L, sx, top, "sky", "flag_hi")


def flag_cloth(L, sx, top, cloth, stripe=None, pole="paper", side=0, sheen=None):
    """A cloth flag on a tall bamboo pole, flown ABOVE the boards (cloth rows top-20..top-15, boards start
    at top-14), 8x6, flying toward the stage; the fly end sags 1 px (cloth weight, no mid-cloth wave, so
    stripes stay straight)."""
    px = sx + 2
    L.vline(px, top - 20, top + 6, pole)
    for dx in range(8):
        x = px + 1 + dx if side == 0 else px - 1 - dx
        dy = 1 if dx >= 6 else 0
        L.rect(x, top - 20 + dy, 1, 6, cloth)
        if stripe:
            L.set(x, top - 19 + dy, stripe)
            L.set(x, top - 16 + dy, stripe)
    if sheen:
        x = px + 2 if side == 0 else px - 3
        L.hline(min(x, x + 1), max(x, x + 1), top - 19, sheen)


def side_of(sx):
    return 0 if sx < 90 else 1


def opt_a2(L, sx, top, i, side):
    """A': Kaplan's flag sea: white cloth with two blue stripes (no star), and white boards. Needs a waiver."""
    k = i // 2
    if (k + side) % 2 == 0:
        flag_cloth(L, sx, top, "white", "flag_hi", side=side)
    else:
        board(L, sx, top, "white", "paper")


def opt_b(L, sx, top, i, side):
    """B: the Pink Front as ONE accent per side, the rest blue and white."""
    k = i // 2
    pink_at = 1 if side == 0 else 2
    if k == pink_at:
        board(L, sx, top, "pink", "pink_sh")
    elif (k + side) % 2 == 0:
        board(L, sx, top, "white", "paper")
    else:
        board(L, sx, top, "sky", "flag_hi")


def opt_c(L, sx, top, i, side):
    """C: black flags (the 2020 'Black Flags') flown high, and plain white cardboard."""
    k = i // 2
    if (k + side) % 2 == 0:
        flag_cloth(L, sx, top, "ink", pole="grey", side=side, sheen="suit_dk")
    else:
        board(L, sx, top, "white", "paper")


# marker strokes: two straight 1-px "lines of handwriting", RIGHT-aligned like Hebrew (x0+8 is the
# right margin): a long line with one off-centre word gap over a shorter line. Straight 1-px rows can't
# form a letter; the gap is never centred and the lower line never centred (a centred "- -" over "-" is a face).
# One marker colour per board. (colour, top line as [(dx from right margin, length)], lower line length)
MARKS = [("ink",     [(0, 5), (6, 2)], 4),
         ("flag_hi", [(0, 2), (3, 5)], 5),
         ("red",     [(0, 6)],         3),
         ("ink",     [(0, 3), (4, 3)], 6)]


MARKS_V4 = [("ink",     [(0, 5), (6, 2)], 4),
            ("flag_hi", [(0, 2), (3, 5)], 5),
            ("ink",     [(0, 6)],         3),
            ("flag_hi", [(0, 3), (4, 3)], 6)]


def opt_d2(L, sx, top, i, side):
    """D': D with the marker restricted to ink + flag_hi (no alert red): the recommended form."""
    opt_d(L, sx, top, i, side, marks=MARKS_V4)


def opt_d(L, sx, top, i, side, marks=None):
    """D: handmade kraft cardboard, uneven, with marker strokes that stay below letter legibility."""
    k = i // 2
    L.vline(sx + 2, top - 6, top + 6, "wood")
    x0, y0 = sx - 2, top - 14
    fill = "stone" if (k + side) % 2 == 0 else "stone_sh"
    shade = "stone_sh" if fill == "stone" else "wood"
    # torn / cut-by-hand corners: one corner pixel knocked out per board, the corner varies
    cx, cy = [(x0, y0), (x0 + 9, y0), (x0 + 9, y0 + 7), (x0, y0 + 7)][(k + side) % 4]
    behind = L.get(cx, cy)
    L.rect(x0, y0, 10, 8, fill)
    L.hline(x0, x0 + 9, y0 + 7, shade)
    L.set(cx, cy, behind)
    c, top_line, n2 = (marks or MARKS)[(k + 2 * side) % 4]
    rm = x0 + 8                                            # the right margin
    for off, n in top_line:
        L.hline(rm - off - n + 1, rm - off, y0 + 2, c)
    L.hline(rm - n2 + 1, rm, y0 + 4, c)


OPTIONS = [
    ("current", "Current (v2 pink + white)", cur),
    ("A", "A · Blue & white boards", opt_a),
    ("A2", "A' · Kaplan flags (waiver)", opt_a2),
    ("B", "B · One pink accent + blue/white", opt_b),
    ("C", "C · Black flags + white cardboard", opt_c),
    ("D", "D · Handmade kraft + marker", opt_d),
    ("D2", "D' · Kraft, ink/blue marker (rec.)", opt_d2),
]

# ---------------------------------------------------------------- the leader, for "does it compete?"
man = json.load(open(os.path.join(WT, "game", "assets", "sprites", "sprites.json")))
SPR = os.path.join(WT, "game", "assets", "sprites")
c = man["chars"]["bibi"]
a = c["anims"]["idle"]
tex = Image.open(os.path.join(SPR, a["texture"])).convert("RGBA")
FR = tex.crop((0, 0, c["frameW"], c["frameH"]))           # idle frame 0, density 3 = art x3
FEET = man["magicianFeet"]


def with_leader(img3):
    img3 = img3.copy()
    img3.alpha_composite(FR, (FEET[0] * 3 - c["anchor"][0], FEET[1] * 3 - c["anchor"][1]))
    return img3


# ---------------------------------------------------------------- metrics
def lum(h):
    r, g, b = [int(h.lstrip("#")[i:i + 2], 16) / 255 for i in (0, 2, 4)]
    f = lambda v: v / 12.92 if v <= 0.03928 else ((v + 0.055) / 1.055) ** 2.4
    return 0.2126 * f(r) + 0.7152 * f(g) + 0.0722 * f(b)


def cr(a_, b_):
    la, lb = sorted((lum(PAL[a_]), lum(PAL[b_])), reverse=True)
    return (la + 0.05) / (lb + 0.05)


def sign_mask(img):
    """Pixels that differ from a stage with no signs at all."""
    base = np.asarray(balfour_with(lambda *a_: None).to_image(1).convert("RGBA")).astype(int)
    x = np.asarray(img.convert("RGBA")).astype(int)
    return (np.abs(x - base).sum(axis=2) > 0)


def deutan(img):
    """Viénot/Brettel-style deuteranopia approximation (LMS projection), for a quick colour-blind look."""
    a_ = np.asarray(img.convert("RGB")).astype(float) / 255
    lin = np.where(a_ <= 0.04045, a_ / 12.92, ((a_ + 0.055) / 1.055) ** 2.4)
    M = np.array([[0.29275, 0.70725, 0.0], [0.29275, 0.70725, 0.0], [-0.02234, 0.02234, 1.0]])
    o = lin @ M.T
    o = np.clip(o, 0, 1)
    s = np.where(o <= 0.0031308, o * 12.92, 1.055 * o ** (1 / 2.4) - 0.055)
    return Image.fromarray((s * 255).round().astype("uint8"))


# ---------------------------------------------------------------- render
CROP = (0, 90, 180, 232)          # art rows 90-231: villa, wall, crowd, street (the stage's working band)
results = {}
for key, label, fn in OPTIONS:
    im1 = balfour_with(fn).to_image(1)
    im1.save(os.path.join(OUT, f"b14-{key}-stage-1x.png"))
    im3 = im1.resize((540, 960), Image.NEAREST)
    im3.save(os.path.join(OUT, f"b14-{key}-stage-3x.png"))
    lead = with_leader(im3)
    lead.save(os.path.join(OUT, f"b14-{key}-leader-3x.png"))
    m = sign_mask(im1)
    arr = np.asarray(im1.convert("RGB")).reshape(-1, 3)[m.reshape(-1)]
    cols = {}
    for p in map(tuple, arr):
        h = "#%02x%02x%02x" % p
        cols[h] = cols.get(h, 0) + 1
    name_of = {v: k for k, v in PAL.items()}
    results[key] = {"label": label, "px": int(m.sum()),
                    "colours": {name_of.get(h, h): n for h, n in sorted(cols.items(), key=lambda t: -t[1])}}
    results[key]["vsWall"] = {n: round(cr(n, "slate"), 2) for n in results[key]["colours"] if n in PAL}
    results[key]["img1"], results[key]["lead"] = im1, lead

json.dump({k: {kk: vv for kk, vv in v.items() if kk not in ("img1", "lead")} for k, v in results.items()},
          open(os.path.join(OUT, "b14-metrics.json"), "w"), indent=1)

# ---------------------------------------------------------------- the sheet
FONT = None
for f in ("/System/Library/Fonts/Supplemental/Arial Bold.ttf", "/System/Library/Fonts/Helvetica.ttc"):
    if os.path.exists(f):
        FONT = f
        break
fnt = lambda s: ImageFont.truetype(FONT, s) if FONT else ImageFont.load_default()

BG, FG, MUTE = (16, 20, 34), (247, 244, 236), (180, 190, 215)
COLW = 540
x0c, y0c, x1c, y1c = CROP
cropH3 = (y1c - y0c) * 3
PH = 390 * (y1c - y0c) // 180                  # phone scale: the stage fills 390 CSS px
rows = [("3x with the leader (art x3, the leader's native density)", cropH3),
        ("Gameplay scale: the stage at 390 CSS px wide (1 CSS px = 1 px)", PH),
        ("1x art (native)", y1c - y0c),
        ("Squint: greyscale, 2-px blur at 3x", cropH3 // 2),
        ("Deuteranopia (approx.) at 3x", cropH3 // 2)]
PAD, HEAD = 24, 70
W = PAD + len(OPTIONS) * (COLW + PAD)
H = HEAD + sum(h + 44 for _, h in rows) + PAD + 60
sheet = Image.new("RGB", (W, H), BG)
d = ImageDraw.Draw(sheet)
d.text((PAD, 18), "B14 · Balfour protest signs · options (only the signs change; cast and stage untouched)", fill=FG, font=fnt(28))
for ci, (key, label, _) in enumerate(OPTIONS):
    cx = PAD + ci * (COLW + PAD)
    y = HEAD
    r = results[key]
    for ri, (rl, rh) in enumerate(rows):
        if ci == 0:
            pass
        d.text((cx, y + 4), (label if ri == 0 else "") or "", fill=FG, font=fnt(24))
        if ri > 0 and ci == 0:
            d.text((cx, y + 10), rl, fill=MUTE, font=fnt(18))
        elif ri == 0:
            d.text((cx, y + 30), "", fill=MUTE, font=fnt(14))
        y += 40
        if ri == 0:
            tile = r["lead"].crop((x0c * 3, y0c * 3, x1c * 3, y1c * 3))
        elif ri == 1:
            s1 = r["img1"].crop(CROP)
            tile = s1.resize((390, PH), Image.NEAREST)
        elif ri == 2:
            tile = r["img1"].crop(CROP)
        elif ri == 3:
            t = r["lead"].crop((x0c * 3, y0c * 3, x1c * 3, y1c * 3)).convert("L").filter(ImageFilter.GaussianBlur(2))
            tile = t.resize((COLW // 2, cropH3 // 2), Image.BILINEAR).convert("RGB")
        else:
            t = deutan(r["lead"].crop((x0c * 3, y0c * 3, x1c * 3, y1c * 3)))
            tile = t.resize((COLW // 2, cropH3 // 2), Image.BILINEAR)
        sheet.paste(tile.convert("RGB"), (cx, y))
        y += rh + 4
d.text((PAD, H - 50), "Row labels are in the first column. Palette: the 45-swatch master only. "
       "No letters, no stars, no logos, no faces on any sign. Current = the shipped stage_balfour.png (0 px drift).",
       fill=MUTE, font=fnt(18))
sheet.save(os.path.join(OUT, "options-sheet.png"))
print(json.dumps({k: {"px": v["px"], "colours": v["colours"], "vsWall": v["vsWall"]} for k, v in results.items()}, indent=1))
