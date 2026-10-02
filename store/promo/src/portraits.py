"""'עוד סבב': leader portraits to send in a chat (Bar, Oct 2026: a friend asked for Bibi, Eisenkot, Bennett,
Yair Golan and Ben Gvir). The game's own pixel sprites, no copy beyond the name, the party and the title.

    cards     one 1080x1350 PNG per leader: sunburst, the sprite big, a name plate  (social/portraits/)
    cutouts   the same sprite on a transparent PNG                                   (social/portraits/cutout/)
    group     all five on one 1600x900 stage, and on a transparent PNG              (social/portraits/, cutout/)

    python3 store/promo/src/portraits.py [bibi eisenkot ...]
"""
import math
import os
import sys

from PIL import Image, ImageDraw, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import promo as P  # noqa: E402
from social import comp, grad, save  # noqa: E402
from teaser import INK, GOLD, GOLD_SH, WHITE, text, plate, char_frame  # noqa: E402

CW, CH = 1080, 1350
WHO = ["bibi", "eisenkot", "bennett", "golan", "bengvir"]
FILE = {"bibi": "netanyahu", "eisenkot": "eisenkot", "bennett": "bennett", "golan": "yair-golan", "bengvir": "ben-gvir"}
SHORT = {"bibi": "נתניהו", "eisenkot": "אייזנקוט", "bennett": "בנט", "golan": "גולן", "bengvir": "בן גביר"}
RAYS = {  # (base, ray): one colour per card, the picker's own
    "bibi": ((18, 36, 96), (28, 54, 132)),
    "eisenkot": ((16, 52, 72), (24, 76, 104)),
    "bennett": ((20, 30, 70), (34, 48, 108)),
    "golan": ((70, 18, 30), (104, 28, 44)),
    "bengvir": ((60, 44, 10), (92, 68, 16)),
}


def sprite(lid, scale):
    fr, _ = char_frame(P.LEAD[lid][0], "idle", 0, math.ceil(scale))
    fr = fr.crop(fr.getchannel("A").getbbox())
    if scale != math.ceil(scale):
        f = scale / math.ceil(scale)
        fr = fr.resize((round(fr.width * f), round(fr.height * f)), Image.LANCZOS)
    return fr


def rays(size, c1, c2, cx, cy, n=18):
    c = Image.new("RGBA", size, c1 + (255,))
    d = ImageDraw.Draw(c)
    for i in range(n):
        a0 = i * 2 * math.pi / n
        a1 = a0 + math.pi / n
        d.polygon([(cx, cy), (cx + math.cos(a0) * 3000, cy + math.sin(a0) * 3000),
                   (cx + math.cos(a1) * 3000, cy + math.sin(a1) * 3000)], fill=c2 + (255,))
    return c


def vignette(c, strength=200):
    w, h = c.size
    m = Image.new("L", (w // 10, h // 10), 0)
    for y in range(m.height):
        for x in range(m.width):
            d = math.hypot((x + 0.5) / m.width - 0.5, ((y + 0.5) / m.height - 0.5) * 0.85) / 0.6
            m.putpixel((x, y), int(min(1.0, max(0.0, (d - 0.55) / 0.5)) ** 1.5 * strength))
    v = Image.new("RGBA", (w, h), INK + (0,))
    v.putalpha(m.resize((w, h), Image.BILINEAR))
    c.alpha_composite(v)


def shadow(c, cx, y, w):
    s = Image.new("RGBA", c.size, (0, 0, 0, 0))
    ImageDraw.Draw(s).ellipse((cx - w // 2, y - 22, cx + w // 2, y + 22), fill=(0, 0, 0, 140))
    c.alpha_composite(s.filter(ImageFilter.GaussianBlur(10)))


def title(c, y, px=7):
    t = text("עוד סבב", px, grad=True)
    comp(c, t, c.width // 2, y)


def card(lid):
    _, _, name, party = P.LEAD[lid]
    base, ray = RAYS[lid]
    c = rays((CW, CH), base, ray, CW // 2, 520)
    vignette(c)
    title(c, 110)
    fig = sprite(lid, 3)
    feet = 1010
    shadow(c, CW // 2, feet, int(fig.width * 0.8))
    comp(c, fig, CW // 2, feet, anchor="b")
    nm = text(name, 9, fill=WHITE)
    pt = text(party, 5, fill=GOLD)
    pw = max(nm.width, pt.width) + 120
    ph = nm.height + pt.height + 70
    comp(c, plate(pw, ph, rim=GOLD_SH), CW // 2, 1150)
    comp(c, nm, CW // 2, 1150 - pt.height // 2 - 8)
    comp(c, pt, CW // 2, 1150 + nm.height // 2 + 10)
    return c.convert("RGB")


def group():
    gw, gh = 1600, 900
    c = rays((gw, gh), (18, 26, 70), (28, 40, 100), gw // 2, 300, n=24)
    vignette(c, 170)
    title(c, 90, px=8)
    order = ["golan", "eisenkot", "bibi", "bennett", "bengvir"]  # Bibi in the middle, the rest by height
    figs = [sprite(lid, 1.8) for lid in order]
    gap = 34
    total = sum(f.width for f in figs) + gap * (len(figs) - 1)
    x = (gw - total) // 2
    feet = 760
    for lid, f in zip(order, figs):
        cx = x + f.width // 2
        shadow(c, cx, feet, int(f.width * 0.8))
        comp(c, f, cx, feet, anchor="b")
        nm = text(SHORT[lid], 5, fill=WHITE)
        comp(c, plate(nm.width + 40, nm.height + 26, rim=GOLD_SH, px=4), cx, feet + 60)
        comp(c, nm, cx, feet + 60)
        x += f.width + gap
    return c.convert("RGB")


def group_cutout():
    """the group's five on a transparent PNG, no rays, no plates."""
    order = ["golan", "eisenkot", "bibi", "bennett", "bengvir"]
    figs = [sprite(lid, 1.8) for lid in order]
    gap = 34
    w = sum(f.width for f in figs) + gap * (len(figs) - 1)
    h = max(f.height for f in figs)
    c = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    x = 0
    for f in figs:
        c.alpha_composite(f, (x, h - f.height))
        x += f.width + gap
    return c


def main():
    who = [a for a in sys.argv[1:] if a in WHO] or WHO
    for lid in who:
        print(save(card(lid), "portraits", "%s.png" % FILE[lid]))
        print(save(sprite(lid, 3), "portraits", "cutout", "%s.png" % FILE[lid]))
    if who == WHO:
        print(save(group(), "portraits", "group.png"))
        print(save(group_cutout(), "portraits", "cutout", "group.png"))


if __name__ == "__main__":
    main()
