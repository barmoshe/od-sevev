"""Key art: the app icon (1024 + the 60 px check) and the 1200x630 OG share image.

Both are composed on integer grids and upscaled nearest-neighbour ONLY. The Magician is the APPROVED
render-down (creative-pack showcase/out), pasted 1:1 at one of its densities, never resampled. Since the 3x cast
(2026-09-29) he ships at density d = 3 (main) and d = 2 (alternate): d sprite px per art px. So each image is
composed on a FINE grid of d px per art px (the stage, the ring, the props and the wordmark drawn at art px and
scaled x d; the Magician pasted 1:1), then scaled by the whole number (output px per art px) / d:
  icon  64x64 art, d 2:  128x128 fine  x8 = 1024   (master icon-128-art.png; 60 / 29 px checks are LANCZOS
                                                     downsamples, as the OS does)
  OG    200x105 art, d 3: 600x315 fine x2 = 1200x630 (6 output px per art px, 2 per sprite px; the key art
                                                     inside the centre 105x105 art = 630x630 square, UX 5.4)
The frame data (file, frameW/H, density, hatMouth) is read from the showcase atlas.json, main render or its
`densities` entry, so a re-render at another density never cuts the wrong frames again (the 1x crop of the 3x
strips was the wave-5 break). The OG moved from 240x126 art at x5 to 200x105 at x6 because no d > 1 divides 5.
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
OG_D = 3          # 6 output px per art px: d 3 -> 2 per sprite px (the full face detail at 1200 px; d 2 -> 3)
OG_ART = (200, 105, 6)


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


def icon(key=KEY, proofs=PROOFS):
    N, d = 64, ICON_D
    L = Layer(N, N, fill="plum")
    # follow-spot field, two value steps with a checker seam
    for y in range(N):
        for x in range(N):
            dd = math.hypot(x - 36, y - 28)
            if dd < 26:
                L.set(x, y, "plum_hi")
            elif dd < 28.5 and (x + y) % 2 == 0:
                L.set(x, y, "plum_hi")
    ring(L, 34, 34, 24.0, 28.6, gap=(-72, -36))
    # arrowhead at the gap's top end, pointing clockwise (= 'again', not 'undo')
    head = ["#.....", "###...", "#####.", "######", "#####.", "###...", "#....."]
    for j, row in enumerate(head):
        for i, ch in enumerate(row):
            if ch == "#":
                L.set(38 + i, 3 + j, "gold" if j < 5 else "gold_sh")
    outline_ring(L)
    img = up(L.to_image(1), d)
    # the Magician: idle frame 0 (finger up, hat spinning on it), the bust: art rows 28-92, columns 0-64
    f, fd, _ = frame("idle", 0, d)
    assert fd == d, (fd, d)
    img.alpha_composite(f.crop((0, 28 * d, 64 * d, 92 * d)), (5 * d, 7 * d))
    big = img.resize((N * 16, N * 16), Image.NEAREST).convert("RGB")
    os.makedirs(key, exist_ok=True)
    big.save(os.path.join(key, "icon-1024.png"))
    s60 = big.resize((60, 60), Image.LANCZOS)
    s60.save(os.path.join(key, "icon-60.png"))
    s60.resize((240, 240), Image.NEAREST).save(os.path.join(proofs, "icon-60-zoomed.png"))
    big.resize((29, 29), Image.LANCZOS).resize((232, 232), Image.NEAREST).save(os.path.join(proofs, "icon-29-zoomed.png"))
    img.save(os.path.join(key, "icon-128-art.png"))   # the master the pipeline imports (x8 = 1024, nearest)
    return img


def og(key=KEY, proofs=PROOFS, d=OG_D):
    W, H, S = OG_ART
    assert S % d == 0, f"OG: {S} output px per art px is not a whole number of density-{d} sprite px"
    L = Layer(W, H, fill="plum")
    cx = W // 2
    # follow-spot onto the centre
    for y in range(H):
        half = 18 + y * 0.30
        for x in range(W):
            e = half - abs(x - cx)
            if e > 1.5 or (e > 0 and (x + y) % 2 == 0):
                L.set(x, y, "plum_hi")
    # curtains: 34 art each side, draped back to ~57% of the height at their inner edge
    CW = 34
    for side in (0, 1):
        for x in range(CW):
            xx = x if side == 0 else W - 1 - x
            c = "plum_hi" if (x // 6) % 2 else "plum"
            yb = H - (x * x) // 24
            for y in range(0, H):
                if y < yb:
                    L.set(xx, y, c)
            if 0 <= yb - 1 < H:
                L.set(xx, yb - 1, "outline")
    L.rect(0, 0, W, 6, "plum")
    for x in range(0, W, 10):
        L.ellipse(x + 4.5, 5, 5, 3, "plum")
        L.ellipse(x + 4.5, 4, 4, 2, "plum_hi")
    L.hline(0, W - 1, 0, "outline")
    img = up(L.to_image(1), d)                               # the fine grid: d px per art px
    # the Magician: tap frame 3 (the hat at its highest), feet centred on the stage, cut at the hips
    f, fd, hm = frame("tap", 3, d)
    assert fd == d, (fd, d)
    anchor = cast("bibi", d)["anchor"]
    top, feet_x = 23, cx + 4                                 # art row of the frame's top edge; the feet's column
    fx = feet_x * d - anchor[0]
    img.alpha_composite(f, (fx, top * d))
    # shekels and a bill leaping out of the hat, on the art grid (1x props, x d)
    hx, hy = (fx + hm[0]) // d, top + hm[1] // d
    coins = [prop("coin0"), prop("coin1"), prop("coin2"), prop("coin3"), prop("bill")]
    for k, (dx, dy) in enumerate([(2, -9), (9, -14), (-2, -17), (15, -8), (6, -21), (19, -15), (13, -20)]):
        img.alpha_composite(up(coins[k % len(coins)], d), ((hx + dx) * d, (hy + dy) * d))
    # the Suitcase drifting through, upper left of the centre square, with a speed trail
    sc = Image.open(os.path.join(OUT, "ui", "props", "suitcase.png")).convert("RGBA")
    sx, sy = cx - 52, 28
    tr = Layer(W, H)
    for i in range(3):
        tr.hline(sx - 18 + i * 2, sx - 2 + i * 2, sy + 6 + i * 5, "rim")
    img.alpha_composite(up(tr.to_image(1), d))
    img.alpha_composite(up(sc, d), (sx * d, sy * d))
    # wordmark over the top of the centre square
    wm = display("עוד סבב", 16, 3, ext=2)
    img.alpha_composite(up(wm.to_image(1), d), ((W - wm.w) // 2 * d, 5 * d))
    k = S // d
    big = img.resize((img.width * k, img.height * k), Image.NEAREST).convert("RGB")
    assert big.size == (1200, 630), big.size
    os.makedirs(key, exist_ok=True)
    big.save(os.path.join(key, "og-1200x630.png"))
    big.save(os.path.join(key, "og-1200x630.jpg"), quality=90, optimize=True, subsampling=0)
    # the square-crop check (WhatsApp / Telegram thumbnails)
    sq = big.crop((285, 0, 915, 630))
    sq.resize((200, 200), Image.LANCZOS).save(os.path.join(proofs, "og-square-crop-200.png"))
    img.save(os.path.join(key, f"og-{W}x{H}-art-d{d}.png"))
    return img, wm


def build():
    icon()
    og()


if __name__ == "__main__":
    build()
    print(os.path.getsize(os.path.join(KEY, "og-1200x630.jpg")) // 1024, "KB jpg")
