"""Frame check: every element pasted onto a 1080x1920 frame, clipped by the frame or inside Instagram's UI.

Safe zone for Reels (2026 guides): top 220, bottom 380 (y > 1540), right 120 (x > 960, where the like /
comment / share icons sit, from about y 1000 down), left 60.
Text-like images (text, bubble, badge, plate, stamp) are tracked by id; everything else is an element.

    python3 framecheck.py <scratch> <module> <name> [step]
"""
import collections
import os
import sys

SRC = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, SRC)
sys.path.insert(0, os.path.join(SRC, "..", "..", "teaser", "src"))
import teaser as k  # noqa: E402
from PIL import Image  # noqa: E402

W, H = k.W, k.H
TEXTY = set()


def reg(fn):
    def w(*a, **kw):
        im = fn(*a, **kw)
        TEXTY.add(id(im))
        return im
    return w


for name in ("text", "bubble", "badge", "plate", "stamp_img"):
    setattr(k, name, reg(getattr(k, name)))

LOG = []
IN_PASTE = [False]
CUR_T = [0.0]
_orig_paste = k.paste
_orig_ac = Image.Image.alpha_composite


def visible_bbox(im, x0, y0):
    a = im.getchannel("A") if im.mode == "RGBA" else None
    bb = a.getbbox() if a is not None else (0, 0, im.width, im.height)
    if not bb:
        return None
    return (x0 + bb[0], y0 + bb[1], x0 + bb[2], y0 + bb[3])


def log(im, x0, y0, how):
    if im.width >= W * 0.95 and im.height >= 300:
        return                                       # backgrounds, full-frame overlays
    bb = visible_bbox(im, x0, y0)
    if bb is None:
        return
    LOG.append((CUR_T[0], id(im) in TEXTY, im.size, bb, how))


def paste(canvas, im, x, y, anchor="c"):
    if canvas.size == (W, H):
        if anchor == "c":
            x0, y0 = x - im.width // 2, y - im.height // 2
        elif anchor == "b":
            x0, y0 = x - im.width // 2, y - im.height
        else:
            x0, y0 = x, y
        log(im, int(round(x0)), int(round(y0)), "paste")
    IN_PASTE[0] = True
    try:
        return _orig_paste(canvas, im, x, y, anchor)
    finally:
        IN_PASTE[0] = False


def ac(self, im, dest=(0, 0), source=(0, 0)):
    if self.size == (W, H) and not IN_PASTE[0] and source == (0, 0):
        log(im, dest[0], dest[1], "composite")
    return _orig_ac(self, im, dest, source)


Image.Image.alpha_composite = ac
k.paste = paste

import promo as P  # noqa: E402
import shorts as S  # noqa: E402
import reels5  # noqa: E402
import reels6  # noqa: E402
import zap  # noqa: E402

for m in (P, S, reels5, reels6, zap):                # the modules bound the names at import
    for name in ("paste", "text", "bubble", "badge", "plate"):
        if hasattr(m, name):
            setattr(m, name, getattr(k, name))


def frames(mod, name):
    if mod == "zap":
        return zap.frame, zap.DUR
    if mod == "reels5":
        f, a, d, n, c = reels5.REELS[name]
        return f, d
    if mod == "reels6":
        f, a, d, n, c = reels6.REELS[name]
        return f, d
    if mod == "shorts":
        f, a, d, n, c = S.SHORTS[name]
        return f, d
    if mod == "promo":
        f, a, d, n, c = P.VIDEOS[name]
        return f, d


def main():
    P.SCRATCH = sys.argv[1]
    mod, name = sys.argv[2], sys.argv[3]
    step = float(sys.argv[4]) if len(sys.argv) > 4 else 0.25
    f, dur = frames(mod, name)
    t = 0.0
    while t < dur:
        CUR_T[0] = round(t, 2)
        f(t)
        t += step
    issues = collections.OrderedDict()
    for t, texty, size, (x0, y0, x1, y1), how in LOG:
        kinds = []
        over = max(-x0, -y0, x1 - W, y1 - H)
        if over > 6 and size[0] * size[1] > 60 * 60:
            kinds.append("CLIPPED by %dpx" % over)
        if texty:
            if y0 < 200:
                kinds.append("text in top UI")
            if y1 > 1540:
                kinds.append("text in bottom UI")
            if x1 > 960 and y1 > 1000:
                kinds.append("text under right icons")
            if x0 < 40:
                kinds.append("text at left edge")
        for kd in kinds:
            key = (kd, texty, size, (x0 // 40, y0 // 40))
            if key not in issues:
                issues[key] = [t, t, (x0, y0, x1, y1)]
            issues[key][1] = t
    for (kd, texty, size, _), (t0, t1, bb) in issues.items():
        print("%-6s %-24s %s size=%s bbox=%s t=%.2f-%.2f" % (name, kd, "TEXT" if texty else "elem", size, bb, t0, t1))


if __name__ == "__main__":
    main()
