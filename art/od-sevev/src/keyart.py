"""Key art: the app icon (1024 + the 60 px check) and the 1200x630 OG share image.

Both are composed on integer art-px grids and upscaled nearest-neighbour ONLY:
  icon  64x64 art  x16 = 1024        (60 / 29 px checks are LANCZOS downsamples, as the OS does)
  OG    240x126 art x5 = 1200x630    (key art inside the centre 126x126 = 630x630 square, UX 5.4)
The Magician is the APPROVED render-down (creative-pack showcase/out), pasted 1:1, never resampled.
"""
import math
import os
from PIL import Image

from pix import Layer
from palette import rgb
from kit import OUT, PROOFS, save, strip
from wordmark import render as display

SHOW = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", "..", "..", "..", "..", "artifacts",
                                     "creative-pack", "od-sevev", "art", "showcase", "out"))
KEY = os.path.join(OUT, "key")


def frame(anim, i, fw=71, fh=125):
    im = Image.open(os.path.join(SHOW, f"bibi_{anim}.png")).convert("RGBA")
    return im.crop((i * fw, 0, (i + 1) * fw, fh))


def prop(name):
    return Image.open(os.path.join(SHOW, f"prop_{name}.png")).convert("RGBA")


def ring(L, cx, cy, r0, r1, gap=(-80, -38)):
    """The gold 'again' loop: clockwise, with an arrowhead at the gap's leading end."""
    for y in range(L.h):
        for x in range(L.w):
            d = math.hypot(x + 0.5 - cx, y + 0.5 - cy)
            a = math.degrees(math.atan2(y + 0.5 - cy, x + 0.5 - cx))
            if r0 <= d <= r1 and not (gap[0] <= a <= gap[1]):
                c = "gold"
                if d > r1 - 1.2:
                    c = "gold_sh"
                elif d < r0 + 1.1:
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


def icon():
    N = 64
    L = Layer(N, N, fill="plum")
    # follow-spot field, two value steps with a checker seam
    for y in range(N):
        for x in range(N):
            d = math.hypot(x - 36, y - 28)
            if d < 26:
                L.set(x, y, "plum_hi")
            elif d < 28.5 and (x + y) % 2 == 0:
                L.set(x, y, "plum_hi")
    ring(L, 34, 34, 24.0, 28.6, gap=(-72, -36))
    # arrowhead at the gap's top end, pointing clockwise (= 'again', not 'undo')
    head = ["#.....", "###...", "#####.", "######", "#####.", "###...", "#....."]
    for j, row in enumerate(head):
        for i, ch in enumerate(row):
            if ch == "#":
                L.set(38 + i, 3 + j, "gold" if j < 5 else "gold_sh")
    outline_ring(L)
    img = L.to_image(1)
    # the Magician: idle frame 0 (finger up, hat spinning on it), bust crop
    f = frame("idle", 0)
    bust = f.crop((0, 28, 64, 92))
    img.alpha_composite(bust, (5, 7))
    big = img.resize((N * 16, N * 16), Image.NEAREST).convert("RGB")
    os.makedirs(KEY, exist_ok=True)
    big.save(os.path.join(KEY, "icon-1024.png"))
    s60 = big.resize((60, 60), Image.LANCZOS)
    s60.save(os.path.join(KEY, "icon-60.png"))
    s60.resize((240, 240), Image.NEAREST).save(os.path.join(PROOFS, "icon-60-zoomed.png"))
    big.resize((29, 29), Image.LANCZOS).resize((232, 232), Image.NEAREST).save(os.path.join(PROOFS, "icon-29-zoomed.png"))
    img.save(os.path.join(KEY, "icon-64-art.png"))
    return img


def og():
    W, H = 240, 126
    L = Layer(W, H, fill="plum")
    # follow-spot onto the centre
    for y in range(H):
        half = 22 + y * 0.30
        for x in range(W):
            e = half - abs(x - 120)
            if e > 1.5 or (e > 0 and (x + y) % 2 == 0):
                L.set(x, y, "plum_hi")
    # curtains
    for side in (0, 1):
        for x in range(40):
            xx = x if side == 0 else W - 1 - x
            c = "plum_hi" if (x // 6) % 2 else "plum"
            for y in range(0, H):
                if y < H - (x * x) // 28:
                    L.set(xx, y, c)
            yb = H - (x * x) // 28
            if 0 <= yb - 1 < H:
                L.set(xx, yb - 1, "outline")
    L.rect(0, 0, W, 6, "plum")
    for x in range(0, W, 10):
        L.ellipse(x + 4.5, 5, 5, 3, "plum")
        L.ellipse(x + 4.5, 4, 4, 2, "plum_hi")
    L.hline(0, W - 1, 0, "outline")
    img = L.to_image(1)
    # the Magician: tap pose, the frame where the hat is highest; feet below the frame (bust + torso)
    f = frame("tap", 3)
    fx = 120 - 36
    img.alpha_composite(f, (fx, H - 125 + 30))
    # shekels leaping out of the hat (hat mouth for tap frame 3 is at ~(12, 25) in frame space)
    hx, hy = fx + 12, H - 125 + 30 + 25
    coins = [prop("coin0"), prop("coin1"), prop("coin2"), prop("coin3"), prop("bill")]
    for k, (dx, dy) in enumerate([(-4, -10), (3, -16), (-10, -18), (8, -8), (-2, -24), (-14, -8), (6, -22)]):
        img.alpha_composite(coins[k % len(coins)], (hx + dx, hy + dy))
    # the Suitcase drifting through, upper left, with a speed trail
    sc = Image.open(os.path.join(OUT, "ui", "props", "suitcase.png")).convert("RGBA")
    tr = Layer(W, H)
    for i in range(3):
        tr.hline(44 + i * 2, 60 + i * 2, 36 + i * 5, "rim")
    img.alpha_composite(tr.to_image(1))
    img.alpha_composite(sc, (62, 30))
    # wordmark over the top of the centre square
    wm = display("עוד סבב", 16, 3, ext=2)
    img.alpha_composite(wm.to_image(1), ((W - wm.w) // 2, 5))
    big = img.resize((W * 5, H * 5), Image.NEAREST).convert("RGB")
    big.save(os.path.join(KEY, "og-1200x630.png"))
    big.save(os.path.join(KEY, "og-1200x630.jpg"), quality=90, optimize=True, subsampling=0)
    # the square-crop check (WhatsApp / Telegram thumbnails)
    sq = big.crop((285, 0, 915, 630))
    sq.resize((200, 200), Image.LANCZOS).save(os.path.join(PROOFS, "og-square-crop-200.png"))
    img.save(os.path.join(KEY, "og-240x126-art.png"))
    return img, wm


def build():
    icon()
    og()


if __name__ == "__main__":
    build()
    print(os.path.getsize(os.path.join(KEY, "og-1200x630.jpg")) // 1024, "KB jpg")
