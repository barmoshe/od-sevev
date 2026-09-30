"""Instagram profile pictures for @od-sevev: 1080x1080, safe inside the circle crop.

Built only from shipped art: the curtain tile, the wordmark, the hat, and Dubi's ref.
Three options (a/b/c) plus a preview sheet showing each in the circle at 1080 and ~110 px
(the size a profile picture actually shows in the feed).

    python3 store/instagram/src/profile.py
"""
import math
import os
import random

from PIL import Image, ImageDraw, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
SPR = os.path.join(ROOT, "game", "assets", "sprites")
OUT = os.path.join(HERE, "..")
N = 1080
PX = 9  # one art pixel = 9 screen px (120 art px across)

NIGHT = (15, 35, 80)
GOLD = (245, 197, 66)
GOLD_HI = (255, 241, 166)
GOLD_SH = (198, 138, 43)
WHITE = (240, 240, 245)


def spr(name, scale):
    im = Image.open(os.path.join(SPR, name)).convert("RGBA")
    return im.resize((im.width * scale, im.height * scale), Image.NEAREST)


def curtain():
    """Velvet-blue curtain field, tiled from the game's curtain panel, darkened to the edges."""
    tile = spr("curtain_panel.png", PX)
    bg = Image.new("RGBA", (N, N), NIGHT + (255,))
    x0 = (N - tile.width * 4) // 2
    for i in range(-1, 6):
        for y in range(0, N, tile.height):
            bg.alpha_composite(tile, (x0 + i * tile.width, y))
    return bg


def vignette(im, strength=170):
    """Dark ring toward the circle's edge, stepped in art pixels so it stays pixel art."""
    mask = Image.new("L", (N // PX, N // PX), 0)
    c = (N // PX) / 2
    for y in range(mask.height):
        for x in range(mask.width):
            d = math.hypot(x + 0.5 - c, y + 0.5 - c) / c
            v = max(0.0, min(1.0, (d - 0.55) / 0.45))
            mask.putpixel((x, y), int(round(v * 4)) * strength // 4)
    mask = mask.resize((N, N), Image.NEAREST)
    dark = Image.new("RGBA", (N, N), NIGHT + (255,))
    return Image.composite(dark, im, mask)


def spotlight(im, cx, cy, r, alpha=70):
    """A soft cone of light drawn as stepped rings (two value steps, like the stage lamps)."""
    ov = Image.new("RGBA", (N, N), (0, 0, 0, 0))
    d = ImageDraw.Draw(ov)
    for k, a in ((1.0, alpha // 2), (0.72, alpha)):
        rr = r * k
        d.ellipse((cx - rr, cy - rr, cx + rr, cy + rr), fill=(120, 170, 255, a))
    im.alpha_composite(ov)
    return im


def confetti(im, seed, box, n=26):
    """Gold coins and white ballot slips in the air (the og/title vocabulary)."""
    rnd = random.Random(seed)
    d = ImageDraw.Draw(im)
    x0, y0, x1, y1 = box
    for _ in range(n):
        x = rnd.randrange(x0, x1) // PX * PX
        y = rnd.randrange(y0, y1) // PX * PX
        if rnd.random() < 0.5:
            d.rectangle((x, y, x + PX * 2 - 1, y + PX * 2 - 1), fill=GOLD)
            d.rectangle((x, y, x + PX - 1, y + PX - 1), fill=GOLD_HI)
        else:
            d.rectangle((x, y, x + PX * 2 - 1, y + PX - 1), fill=WHITE)
    return im


def center(im, layer, cy):
    im.alpha_composite(layer, ((N - layer.width) // 2, int(cy - layer.height / 2)))


def dubi_bust(height, detail=False):
    """Dubi's head and shoulders from the ref, glow dropped, snapped to the art-pixel grid.

    detail=True keeps the ref's own drawing (no snap to the 9-px grid) for the HD export."""
    ref = Image.open(os.path.join(ROOT, "creative-pack", "art", "refs", "dubi.png")).convert("RGBA")
    bust = ref.crop((25, 60, 1000, 900))  # whole raised wing and far shoulder, no hard crop edge
    a = bust.getchannel("A").point(lambda v: 255 if v > 200 else 0)
    bust.putalpha(a)
    w = round(bust.width * height / bust.height)
    if detail:
        big = bust.resize((w, height), Image.LANCZOS)
        big.putalpha(big.getchannel("A").point(lambda v: 255 if v > 128 else 0))
        t = max(2, PX // 3)  # dark outline, a third of an art px thick
        out = Image.new("RGBA", (w + 2 * t, height + 2 * t), (0, 0, 0, 0))
        sil = Image.new("RGBA", big.size, (11, 10, 18, 255))
        sil.putalpha(big.getchannel("A"))
        for dx in range(0, 2 * t + 1, t):
            for dy in range(0, 2 * t + 1, t):
                out.alpha_composite(sil, (dx, dy))
        out.alpha_composite(big, (t, t))
        return out
    small = bust.resize((w // PX * 1 or 1, height // PX), Image.LANCZOS)
    small.putalpha(small.getchannel("A").point(lambda v: 255 if v > 128 else 0))
    # 1-art-px dark outline so the bird reads on the curtain at 110 px
    outline = Image.new("RGBA", (small.width + 2, small.height + 2), (0, 0, 0, 0))
    sil = Image.new("RGBA", small.size, (11, 10, 18, 255))
    sil.putalpha(small.getchannel("A"))
    for dx, dy in ((0, 1), (2, 1), (1, 0), (1, 2)):
        outline.alpha_composite(sil, (dx, dy))
    outline.alpha_composite(small, (1, 1))
    return outline.resize((outline.width * PX, outline.height * PX), Image.NEAREST)


def option_a():
    """Wordmark only: 'עוד סבב' in gold under a spotlight, coins falling."""
    im = curtain()
    im = vignette(spotlight(im, N / 2, N / 2, 470))
    im = confetti(im, 7, (220, 230, 860, 400))
    im = confetti(im, 8, (240, 690, 840, 830), 14)
    center(im, spr("wordmark.png", 6), N / 2 + 10)
    return im


def option_b(detail=False):
    """Dubi the parrot, mid-heckle, with the wordmark as his nameplate.

    Layout is in 1080 units and scales with N, so the HD export is the same picture."""
    k = N / 1080
    im = curtain()
    im = vignette(spotlight(im, N / 2, 470 * k, 430 * k), 150)
    im = confetti(im, 3, tuple(int(v * k) for v in (200, 170, 880, 330)), 18)
    center(im, dubi_bust(int(630 * k), detail), 450 * k)
    plate = spr("wordmark.png", 4 * PX // 9)
    # a night plate under the wordmark so it never fights the suit
    d = ImageDraw.Draw(im)
    pw, ph = plate.width + PX * 18, plate.height + PX * 4  # wide enough to hide the sleeve cut
    py = int(790 * k)
    box = ((N - pw) // 2, py - ph // 2, (N + pw) // 2, py + ph // 2)
    d.rectangle(box, fill=GOLD_SH)
    d.rectangle((box[0] + PX, box[1] + PX, box[2] - PX, box[3] - PX), fill=NIGHT + (255,))
    center(im, plate, py)
    return im


def option_c():
    """The Magician's top hat with the wordmark rising out of it."""
    im = curtain()
    im = vignette(spotlight(im, N / 2, 560, 460))
    im = confetti(im, 11, (220, 180, 860, 420), 30)
    center(im, spr("wordmark.png", 5), 330)
    center(im, spr("prop_hat.png", 18), 640)
    return im


def circle_preview(opts):
    """Each option as Instagram shows it: circle crop large, and at 110 px."""
    big, small = 360, 110
    sheet = Image.new("RGBA", (len(opts) * (big + 40) + 40, big + small + 120), (250, 250, 250, 255))
    mask = Image.new("L", (big * 4, big * 4), 0)
    ImageDraw.Draw(mask).ellipse((0, 0, big * 4 - 1, big * 4 - 1), fill=255)
    for i, (name, im) in enumerate(opts):
        x = 40 + i * (big + 40)
        for size, y in ((big, 30), (small, big + 60)):
            m = mask.resize((size, size), Image.LANCZOS)
            t = im.resize((size, size), Image.LANCZOS)
            sheet.paste(t, (x + (big - size) // 2, y), m)
        ImageDraw.Draw(sheet).text((x, big + small + 80), name, fill=(40, 40, 40))
    return sheet


def main():
    opts = [("a - wordmark", option_a()), ("b - dubi", option_b()), ("c - hat", option_c())]
    for name, im in opts:
        im.convert("RGB").save(os.path.join(OUT, f"profile-{name[0]}.png"))
    circle_preview(opts).convert("RGB").save(os.path.join(OUT, "profile-preview.png"))
    # the chosen one (b), at 2160 with Dubi at the ref's full detail
    global N, PX
    N, PX = 2160, 18
    option_b(detail=True).convert("RGB").save(os.path.join(OUT, "profile-b-hd.png"))


if __name__ == "__main__":
    main()
