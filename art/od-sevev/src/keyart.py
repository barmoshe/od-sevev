"""Key art: the app icon (1024 + the 60 px check) and the 1200x630 OG share image.

Bar, 2026-09-29 (leader select): the Bibi-with-hat key art is replaced by the LINEUP of the 8 launch leaders
(design/content.json leaderSelect.roster). Nobody is the "winner": the row is Hebrew-alphabetical by the name the
picker shows, read right to left (אייזנקוט, ביבי, בן גביר, בנט, גולן, דרעי, ליברמן, סמוטריץ׳), an even count so no
one stands in the middle, every figure the same height on the same floor line under the same spot, each with the
tap prop the round gives them. The icon is the same eight as a ring of heads around the gold "again" loop: a
rotation, in a mark with no text.

Both are composed on integer grids and upscaled nearest-neighbour ONLY. The cast is the APPROVED render-down
(creative-pack showcase/out), pasted 1:1 at one of its densities, never resampled; the stage, the props, the ring
and the wordmark are drawn at art px and scaled x d:
  icon  64x64 art, d 2 fine grid (128x128) x8 = 1024: the eight leader heads (showcase `<c>_avatar_pick.png`, the
        32x32 chat-avatar render-down on a neutral rim ring, also the picker's) pasted 1:1 on the fine grid, i.e. 16 art px each at
        d 2; master icon-128-art.png; the 60 / 29 px checks are LANCZOS downsamples, as the OS does
  OG    400x210 art at x3, d 3: the cast at 1 output px per sprite px (400x210 x 3 = 1200x630). The wordmark and
        the middle four stand inside the centre 210x210 art = the 630x630 square crop (UX 5.4).
The frame data (file, frameW/H, density, anchor, propMouth) is read from the showcase atlas.json, main render or its
`densities` entry (`frame()`), so a re-render at another density never cuts the wrong frames.
Nothing that echoes October 7 (style guide do/don't 13): a curtained stage, ballot slips and coins, Dubi.
"""
import json
import math
import os
from PIL import Image

from pix import Layer
from palette import rgb
from kit import OUT, PROOFS
from wordmark import render as display

_HERE = os.path.dirname(os.path.abspath(__file__))
_FORK = os.path.normpath(os.path.join(_HERE, "..", "..", ".."))
# the creative pack, resolved like pipeline/od-sevev/sprites.py: $ODS_CREATIVE_PACK, else the copy inside the
# fork, else the studio layout
_LOCAL = os.path.join(_FORK, "creative-pack")
CREATIVE = os.path.abspath(os.environ.get(
    "ODS_CREATIVE_PACK", _LOCAL if os.path.isdir(_LOCAL)
    else os.path.join(_FORK, "..", "..", "artifacts", "creative-pack", "od-sevev")))
SHOW = os.path.join(CREATIVE, "art", "showcase", "out")
KEY = os.path.join(OUT, "key")
ICON_D = 2        # 1024 / 64 = 16 output px per art px: d 2 -> 8 per sprite px (d 3 would be 5.33)
OG_D = 3          # 3 output px per art px: d 3 -> 1 per sprite px (eight full figures across 1200 px)
OG_ART = (400, 210, 3)
# the launch 8, Hebrew-alphabetical by `short` (the picker's name), index 0 = the RIGHTMOST (RTL reading order)
LINEUP = ["eisenkot", "bibi", "ben-gvir", "bennett", "golan", "deri", "liberman", "smotrich"]
KIT_JSON = os.path.join(OUT, "..", "ui-kit.json")


def cast(char="bibi", d=None):
    """The showcase atlas entry of `char` at density d (the main render when d is None or its own density)."""
    a = json.load(open(os.path.join(SHOW, "atlas.json")))["chars"][char]
    if d is None or d == a.get("density", 1):
        return a
    alt = dict(a)
    alt.update(a["densities"][str(d)])
    return alt


def frame(anim, i, d=None, char="bibi"):
    """(frame image, density, hatMouth or None) of `char`'s `anim` frame i at density d: the cell read through the
    atlas's frameW/frameH (and cols when a strip is wrapped), in that render's own sprite px."""
    c = cast(char, d)
    a = c["anims"][anim]
    fw, fh = c["frameW"], c["frameH"]
    cols = a.get("cols", a["frames"])
    cell = a.get("frameMap", list(range(a["frames"])))[i]
    im = Image.open(os.path.join(SHOW, a["file"])).convert("RGBA")
    x, y = (cell % cols) * fw, (cell // cols) * fh
    assert im.width >= x + fw and im.height >= y + fh, (a["file"], im.size, fw, fh, cell)
    hm = a.get("hatMouth")
    return im.crop((x, y, x + fw, y + fh)), a.get("density", c.get("density", 1)), (hm[i] if hm else None)


def prop(name):
    return Image.open(os.path.join(SHOW, f"prop_{name}.png")).convert("RGBA")


def up(im, d):
    return im.resize((im.width * d, im.height * d), Image.NEAREST)


def ring(L, cx, cy, r0, r1, gap=(-80, -38)):
    """The gold 'again' loop: clockwise, with an arrowhead at the gap's leading end."""
    for y in range(L.h):
        for x in range(L.w):
            dd = math.hypot(x + 0.5 - cx, y + 0.5 - cy)
            a = math.degrees(math.atan2(y + 0.5 - cy, x + 0.5 - cx))
            if r0 <= dd <= r1 and not (gap[0] <= a <= gap[1]):
                c = "gold"
                if dd > r1 - 1.2:
                    c = "gold_sh"
                elif dd < r0 + 1.1:
                    c = "gold_hi"
                L.set(x, y, c)


def outline_ring(L, colors=("gold", "gold_sh", "gold_hi")):
    src = [row[:] for row in L.px]
    for y in range(L.h):
        for x in range(L.w):
            if src[y][x] in colors:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                xx, yy = x + dx, y + dy
                if 0 <= xx < L.w and 0 <= yy < L.h and src[yy][xx] in colors:
                    L.px[y][x] = "outline"
                    break


def kit_prop(pid, f=0):
    """A kit prop's frame f (d 1) and its pivot, from ui-kit.json."""
    e = {p["id"]: p for p in json.load(open(KIT_JSON))["pieces"]}[pid]
    im = Image.open(os.path.join(OUT, "..", e["file"])).convert("RGBA")
    w = e.get("frameW", im.width)
    return im.crop((f * w, 0, f * w + w, im.height)), e.get("pivot", [w // 2, im.height - 1])


def icon(key=KEY, proofs=PROOFS):
    N, d = 64, ICON_D
    L = Layer(N, N, fill="plum")
    for y in range(N):                                   # one follow-spot, centred: the ring shares it equally
        for x in range(N):
            dd = math.hypot(x + 0.5 - 32, y + 0.5 - 32)
            if dd < 26.5:                                # v4: the flag's blue in the middle, a white ring round it
                L.set(x, y, "flag")
            elif dd < 28.5:
                L.set(x, y, "white")
            elif dd < 31 and (x + y) % 2 == 0:
                L.set(x, y, "plum_hi")
    ring(L, 32, 32, 7.2, 11.0, gap=(-110, -62))          # the gold "again" loop in the middle
    head = ["#....", "##...", "###..", "####.", "###..", "##...", "#...."]
    for j, row in enumerate(head):                       # its arrowhead at the gap's leading end, clockwise
        for i, ch in enumerate(row):
            if ch == "#":
                L.set(33 + i, 18 + j, "gold" if j < 5 else "gold_sh")
    outline_ring(L)
    img = up(L.to_image(1), d)
    # the eight heads on a circle of radius 23 art px, starting at 22.5 deg right of the top and going clockwise in
    # the lineup's order: no one sits at 12 o'clock, no one in the middle
    for k, c in enumerate(LINEUP):
        a = math.radians(-90 + 22.5 + 45 * k)
        cx, cy = 32 + 23 * math.cos(a), 32 + 23 * math.sin(a)
        av = Image.open(os.path.join(SHOW, f"{c}_avatar_pick.png")).convert("RGBA")   # 32 px = 16 art px at d 2
        assert av.size == (16 * d, 16 * d), av.size
        img.alpha_composite(av, (int(round(cx - 8)) * d, int(round(cy - 8)) * d))
    big = img.resize((N * 16, N * 16), Image.NEAREST).convert("RGB")
    os.makedirs(key, exist_ok=True)
    big.save(os.path.join(key, "icon-1024.png"))
    s60 = big.resize((60, 60), Image.LANCZOS)
    s60.save(os.path.join(key, "icon-60.png"))
    s60.resize((240, 240), Image.NEAREST).save(os.path.join(proofs, "icon-60-zoomed.png"))
    big.resize((29, 29), Image.LANCZOS).resize((232, 232), Image.NEAREST).save(os.path.join(proofs, "icon-29-zoomed.png"))
    img.save(os.path.join(key, "icon-128-art.png"))   # the master the pipeline imports (x8 = 1024, nearest)
    return img


def lineup_positions(d, x0, x1):
    """[(char, frame, anchor, paste x in fine px)] for LINEUP laid right to left between art x0 and x1, with the
    seam between the 4th and 5th leaders on the canvas centre line, so nobody stands in the middle: each half's
    visible widths (idle frame 0's alpha box) are packed with one equal gap (negative = a shoulder overlap).
    Returns the positions and each half's gap in art px (right half, left half)."""
    items = []
    for c in LINEUP:
        f, fd, _ = frame("idle", 0, d, c)
        assert fd == d, (c, fd, d)
        items.append((c, f, cast(c, d)["anchor"], f.getchannel("A").getbbox()))
    mid = (x0 + x1) / 2 * d
    half = len(items) // 2
    out, gaps = [], []
    for grp, hi, lo in ((items[:half], x1 * d, mid), (items[half:], mid, x0 * d)):
        widths = [bb[2] - bb[0] for *_, bb in grp]
        # half a gap on the seam side, so the seam gap equals the others
        gap = ((hi - lo) - sum(widths)) / (len(grp) - 0.5)
        right = hi - (gap / 2 if hi == mid else 0)
        for (c, f, anc, bb), w in zip(grp, widths):
            left = right - w
            out.append((c, f, anc, int(round(left - bb[0]))))
            right = left - gap
        gaps.append(gap / d)
    return out, gaps


def og(key=KEY, proofs=PROOFS, d=OG_D):
    import random
    W, H, S = OG_ART
    assert S % d == 0, f"OG: {S} output px per art px is not a whole number of density-{d} sprite px"
    FEET = 200                                            # the floor line every leader stands on (art row)
    L = Layer(W, H, fill="plum")
    for x in range(W):                                    # the back curtain's folds: soft vertical light planes
        m = x % 20
        for y in range(8, FEET - 12):
            if 2 <= m <= 6 or (m in (1, 7) and (x + y) % 2 == 0):
                L.set(x, y, "plum_hi")
    L.rect(0, FEET - 12, W, H - FEET + 12, "stone_sh")    # the stage floor: v4 warm Jerusalem stone (was night)
    L.hline(0, W - 1, FEET - 12, "stone")
    for x in range(0, W, 2):
        L.set(x, FEET - 11, "stone")
    for y in range(FEET - 6, H, 6):                       # the stone's courses, one value step
        L.hline(0, W - 1, y, "wood")
    CW = 16                                               # the side curtains, draped back
    for side in (0, 1):
        for x in range(CW):
            xx = x if side == 0 else W - 1 - x
            c = "plum_hi" if (x // 5) % 2 else "plum"
            yb = H - (x * x) // 3
            for y in range(0, max(yb, 0)):
                if y < H:
                    L.set(xx, y, c)
            if 0 <= yb - 1 < H:
                L.set(xx, yb - 1, "outline")
    L.rect(0, 0, W, 7, "plum")                            # the valance
    for x in range(0, W, 10):
        L.ellipse(x + 4.5, 6, 5, 3, "plum")
        L.ellipse(x + 4.5, 5, 4, 2, "plum_hi")
    L.hline(0, W - 1, 0, "outline")
    # v4: the chrome's national frame on the stage: a white rule over a flag-blue one under the valance, and the
    # stage apron's trim (flag blue over white) above the stone floor. Stripes on the set, never a flag object.
    L.hline(0, W - 1, 9, "white"); L.hline(0, W - 1, 10, "flag")
    L.hline(0, W - 1, FEET - 14, "flag"); L.hline(0, W - 1, FEET - 13, "white")
    pos, gap = lineup_positions(d, CW + 2, W - CW - 2)
    for c, f, anc, px in pos:                             # one follow-spot pool per leader, all the same
        cx = (px + anc[0]) / d
        for y in range(FEET - 4, FEET + 4):
            for x in range(int(cx - 22), int(cx + 23)):
                e = ((x + 0.5 - cx) / 21) ** 2 + ((y + 0.5 - FEET) / 4.2) ** 2
                if e <= 1 and (e < 0.6 or (x + y) % 2 == 0):
                    L.set(x, y, "stone")                      # v4: a warm pool on the stone
    # ballot slips and coins raining over the stage (no letters on the slips), seeded
    rnd = random.Random(1027)
    confetti = Layer(W, H)
    for _ in range(46):
        x, y = rnd.randrange(CW + 4, W - CW - 8), rnd.randrange(60, 104)
        if 120 <= x <= 280 and y < 70:
            continue
        if rnd.random() < 0.6:
            shape = [(0, 0), (1, 0), (0, 1), (1, 1), (0, 2), (1, 2)] if rnd.random() < 0.5 else [(0, 0), (1, 0), (2, 0), (0, 1), (1, 1), (2, 1)]
            for i, (a, b) in enumerate(shape):
                confetti.set(x + a, y + b, "white" if i < 4 else "paper")
        elif rnd.random() < 0.5:                          # v4: a blue ballot envelope (המעטפה הכחולה), blank
            for j, row in enumerate(("hffh", "fhhf", "ffff")):
                for i, ch in enumerate(row):
                    confetti.set(x + i, y + j, "flag_hi" if ch == "h" else "flag")
    img = up(L.to_image(1), d)
    img.alpha_composite(up(confetti.to_image(1), d))
    for _ in range(14):
        x, y = rnd.randrange(CW + 6, W - CW - 10), rnd.randrange(58, 102)
        if 120 <= x <= 280 and y < 70:
            continue
        img.alpha_composite(up(prop("coin%d" % rnd.randrange(4)), d), (x * d, y * d))
    # the leaders, right to left, feet on the floor line, each with the tap prop the round gives them
    for c, f, anc, px in pos:
        img.alpha_composite(f, (px, FEET * d - anc[1]))
    # the loose tap props, where they don't cover a neighbour (a prop on someone else's chest reads as theirs)
    import numpy as np
    bodies = {}
    for c, f, anc, px in pos:
        m = np.zeros((img.height, img.width), bool)
        a_ = np.asarray(f.getchannel("A")) > 0
        y0 = FEET * d - anc[1]
        ys, xs = np.nonzero(a_)
        ok = (ys + y0 >= 0) & (ys + y0 < img.height) & (xs + px >= 0) & (xs + px < img.width)
        m[ys[ok] + y0, xs[ok] + px] = True
        bodies[c] = m
    for c, f, anc, px in pos:
        a = cast(c, d)
        pr = a.get("prop", {})
        pm = a["anims"]["idle"].get("propMouth")
        if pr and not pr.get("baked") and pm:
            pim, piv = kit_prop(pr["id"])
            x = px + pm[0][0] - piv[0] * d
            y = FEET * d - anc[1] + pm[0][1] - piv[1] * d
            box = np.zeros_like(bodies[c])
            box[max(y, 0):y + pim.height * d, max(x, 0):x + pim.width * d] = True
            if any((box & m).any() for o, m in bodies.items() if o != c):
                continue
            img.alpha_composite(up(pim, d), (x, y))
    # Dubi, the office's parrot (everyone's spokesman), flying across the top right to left
    dubi = Image.open(os.path.join(OUT, "ui", "dubi", "dubi_small_fly.png")).convert("RGBA")
    dubi = dubi.crop((0, 0, 20, dubi.height))
    img.alpha_composite(up(dubi, d), ((W - CW - 58) * d, 60 * d))
    # the wordmark over the top of the centre square
    wm = display("עוד סבב", 32, 6, ext=4)
    assert wm.w <= 206, wm.w                              # inside the 630x630 square crop
    img.alpha_composite(up(wm.to_image(1), d), ((W - wm.w) // 2 * d, 10 * d))
    k = S // d
    big = img.resize((img.width * k, img.height * k), Image.NEAREST).convert("RGB")
    assert big.size == (1200, 630), big.size
    os.makedirs(key, exist_ok=True)
    big.save(os.path.join(key, "og-1200x630.png"))
    # q 82 at 4:4:4 (sharp chroma on pixel edges): ~200 KB for eight figures, well under WhatsApp's 300 KB
    big.save(os.path.join(key, "og-1200x630.jpg"), quality=82, optimize=True, subsampling=0)
    # the square-crop check (WhatsApp / Telegram thumbnails)
    sq = big.crop((285, 0, 915, 630))
    sq.resize((200, 200), Image.LANCZOS).save(os.path.join(proofs, "og-square-crop-200.png"))
    for old in os.listdir(key):                           # the previous grid's art file
        if old.startswith("og-") and old.endswith(f"-art-d{d}.png") and old != f"og-{W}x{H}-art-d{d}.png":
            os.remove(os.path.join(key, old))
    img.save(os.path.join(key, f"og-{W}x{H}-art-d{d}.png"))
    return img, wm


def build():
    import logo                    # v5 (2026-09-30): the icon is the hat-and-loop mark; icon() above is the retired ring of heads
    logo.build()
    og()


if __name__ == "__main__":
    build()
    print(os.path.getsize(os.path.join(KEY, "og-1200x630.jpg")) // 1024, "KB jpg")
