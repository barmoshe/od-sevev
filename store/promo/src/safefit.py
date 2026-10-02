"""Fit a full-bleed 1080x1920 frame into Instagram's Reels safe area (Bar: "things go out of the frame").

The older Reels (promo.py's three, shorts.py's four) were laid out edge to edge: captions under the
username bar, CTAs under the caption, right-aligned Hebrew under the icons. Moving each element in seven
layouts would redraw them all; one mapping fixes all of them: the frame at 84%, its centre (540, 980)
moved to (506, 943), so x 0-1080 lands at 53-959 (clear of the icons, 120 from the right), the
highest line (y 95) at 200 and the lowest content (y 1560) at 1430, above the caption zone. Around it,
the same frame blurred and dimmed, the card's corners rounded, a soft shadow (as the gameplay reels'
phone sits on its own blurred frame).
"""
from PIL import Image, ImageDraw, ImageFilter

W, H = 1080, 1920
S = 0.84
CW, CH = round(W * S), round(H * S)               # 907 x 1613
X0 = round(506 - 540 * S)                          # 52
Y0 = round(943 - 980 * S)                          # 120
R = 44
_m = {}


def _mask():
    if "m" not in _m:
        m = Image.new("L", (CW * 2, CH * 2), 0)
        ImageDraw.Draw(m).rounded_rectangle((0, 0, CW * 2 - 1, CH * 2 - 1), radius=R * 2, fill=255)
        _m["m"] = m.resize((CW, CH), Image.LANCZOS)
        sh = Image.new("L", (W, H), 0)
        ImageDraw.Draw(sh).rounded_rectangle((X0 + 6, Y0 + 22, X0 + CW + 6, Y0 + CH + 22), radius=R, fill=170)
        _m["sh"] = sh.filter(ImageFilter.GaussianBlur(26))
    return _m["m"], _m["sh"]


def fit(frame):
    """frame: a 1080x1920 image -> the same frame, fitted inside the safe area on its own blurred backdrop."""
    src = frame.convert("RGB")
    bg = src.resize((54, 96), Image.BILINEAR).filter(ImageFilter.GaussianBlur(3)).resize((W, H), Image.BICUBIC)
    bg = Image.blend(bg, Image.new("RGB", (W, H), (8, 10, 22)), 0.55)
    mask, shadow = _mask()
    bg.paste((0, 0, 0), (0, 0), shadow)
    card = src.resize((CW, CH), Image.LANCZOS)
    bg.paste(card, (X0, Y0), mask)
    return bg
