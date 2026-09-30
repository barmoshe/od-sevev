"""'עוד סבב' — 30 s 'coming soon' teaser, 1080x1920 @ 30 fps, cut to the Balfour theme (116 BPM).

Everything on screen is the game's own art (stages, cast strips, UI kit, the Sevev 9 pixel font);
everything you hear is the game's own audio (decoded from the shipped .res files by res2wav.py).

    python3 store/teaser/src/teaser.py            # render video + mix audio + mux -> store/teaser/od-sevev-teaser.mp4
    python3 store/teaser/src/teaser.py --stills   # a contact sheet of key frames only (fast check)

Timing is in beats: B = one beat at 116 BPM, BAR = 4 beats. Scene starts sit on bar lines.
"""
import json
import math
import os
import random
import subprocess
import sys
import wave

import numpy as np
from PIL import Image, ImageChops, ImageDraw, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
SPR = os.path.join(ROOT, "game", "assets", "sprites")
FONTS = os.path.join(ROOT, "game", "assets", "fonts")
AUD = os.path.join(ROOT, "game", "assets", "audio", "od")
OUT = os.path.join(HERE, "..")
WAV = os.environ.get("OD_WAV_DIR", os.path.join(OUT, "_wav"))

W, H, FPS = 1080, 1920, 30
DUR = 30.0
B = 60 / 116
BAR = 4 * B
T_HOOK, T_COUNT, T_MAGIC, T_GAG, T_LEAD, T_ROLL, T_TITLE, T_MOTIF = (
    0, BAR, 2 * BAR, 5 * BAR, 7 * BAR, 11 * BAR, 12 * BAR, 13 * BAR)

INK = (11, 10, 18)
NIGHT = (15, 35, 80)
NAVY = (31, 43, 99)
GOLD = (245, 197, 66)
GOLD_HI = (255, 241, 166)
GOLD_SH = (198, 138, 43)
WHITE = (244, 242, 236)
RED = (214, 40, 57)
PAPER = (236, 228, 205)

SPRITES = json.load(open(os.path.join(SPR, "sprites.json")))
SFX = []  # (time, wav name, gain dB) — the audio mixer reads this


def sfx(t, name, db=0.0):
    SFX.append((t, name, db))


# ---------------------------------------------------------------------------- helpers

def clamp(x, a=0.0, b=1.0):
    return max(a, min(b, x))


def ease_out(x):
    x = clamp(x)
    return 1 - (1 - x) ** 3


def ease_inout(x):
    x = clamp(x)
    return 3 * x * x - 2 * x * x * x


def back_out(x, s=2.2):
    x = clamp(x) - 1
    return x * x * ((s + 1) * x + s) + 1


_cache = {}


def img(name, scale=1):
    key = (name, scale)
    if key not in _cache:
        path = name if os.path.isabs(name) else os.path.join(SPR, name if name.endswith(".png") else name + ".png")
        im = Image.open(path).convert("RGBA")
        if scale != 1:
            im = im.resize((im.width * scale, im.height * scale), Image.NEAREST)
        _cache[key] = im
    return _cache[key]


def tint(im, rgb):
    """Recolor every opaque pixel keeping its luminance (for stamps/plates)."""
    key = ("tint", id(im), rgb)
    if key not in _cache:
        g = im.convert("L")
        lo = Image.new("RGB", im.size, tuple(int(c * 0.45) for c in rgb))
        hi = Image.new("RGB", im.size, rgb)
        mix = Image.composite(hi, lo, g.point(lambda v: 255 if v > 90 else 0))
        out = mix.convert("RGBA")
        out.putalpha(im.getchannel("A"))
        _cache[key] = out
    return _cache[key]


def paste(canvas, im, x, y, anchor="c"):
    """alpha-composite im with its anchor point at (x, y); anchors: c, tl, b (bottom-centre)."""
    if anchor == "c":
        x, y = x - im.width // 2, y - im.height // 2
    elif anchor == "b":
        x, y = x - im.width // 2, y - im.height
    x, y = int(round(x)), int(round(y))
    if x >= W or y >= H or x + im.width <= 0 or y + im.height <= 0:
        return
    canvas.alpha_composite(im, (max(0, x), max(0, y)),
                           (max(0, -x), max(0, -y)))


def scaled(im, s):
    """Float scale (pop/punch animations only); NEAREST keeps it pixel art."""
    if abs(s - 1) < 1e-3:
        return im
    return im.resize((max(1, int(im.width * s)), max(1, int(im.height * s))), Image.NEAREST)


def fade(im, a):
    if a >= 0.999:
        return im
    im = im.copy()
    im.putalpha(im.getchannel("A").point(lambda v: int(v * clamp(a))))
    return im


def overlay(canvas, rgb, a):
    if a <= 0:
        return
    canvas.alpha_composite(Image.new("RGBA", (W, H), rgb + (int(255 * clamp(a)),)))


def rnd(*seed):
    return random.Random(hash(seed) & 0xFFFFFFFF)


# ---------------------------------------------------------------------------- the Sevev 9 font

class Font:
    def __init__(self, fnt):
        self.page = Image.open(os.path.join(FONTS, fnt.replace(".fnt", ".png"))).convert("RGBA")
        self.ch = {}
        for line in open(os.path.join(FONTS, fnt), encoding="utf-8"):
            if line.startswith("char "):
                kv = dict(p.split("=") for p in line.split()[1:])
                self.ch[int(kv["id"])] = tuple(int(kv[k]) for k in
                                               ("x", "y", "width", "height", "xoffset", "yoffset", "xadvance"))

    @staticmethod
    def visual(s):
        """Minimal bidi for our lines: RTL paragraph, LTR runs (digits/latin) kept in order."""
        s = "".join(c for c in s if c not in "⁦⁧⁨⁩‎‏‪‫‬")
        if not any("֐" <= c <= "׿" for c in s):
            return s  # numbers and handles are already in display order
        runs, cur, cur_ltr = [], "", None
        for j, c in enumerate(s):
            ltr = c.isascii() and (c.isalnum() or c in "@_") or c == "₪"
            nxt = s[j + 1] if j + 1 < len(s) else ""
            if c in ".,:%" and cur_ltr and cur and cur[-1].isalnum() and nxt.isascii() and nxt.isalnum():
                ltr = True  # 1,000 / 1.5 / od.sevev stay inside their run; a full stop after "61" does not
            if cur_ltr is None or ltr == cur_ltr:
                cur += c
                cur_ltr = ltr if cur_ltr is None else cur_ltr
            else:
                runs.append((cur, cur_ltr)); cur, cur_ltr = c, ltr
        if cur:
            runs.append((cur, cur_ltr))
        out = ""
        for text, ltr in reversed(runs):
            out += text if ltr else text[::-1]
        # mirror paired punctuation in the RTL flow
        return out.translate(str.maketrans("()[]", ")(]["))

    def mask(self, s, rtl=True):
        s = self.visual(s) if rtl else s
        w = sum(self.ch.get(ord(c), self.ch[32])[6] for c in s) + 2
        m = Image.new("L", (max(1, w), 11), 0)
        x = 1
        for c in s:
            gx, gy, gw, gh, xo, yo, adv = self.ch.get(ord(c), self.ch[32])
            if gw and gh:
                g = self.page.crop((gx, gy, gx + gw, gy + gh)).getchannel("A")
                m.paste(255, (x + xo, yo), g)
            x += adv
        return m


FONT = Font("sevev9.fnt")


def text(s, px, fill=WHITE, ring=INK, shadow=True, grad=False, rtl=True):
    """Render a line in Sevev 9 at `px` screen px per font px, with an ink ring (+drop shadow)."""
    key = ("t", s, px, fill, ring, shadow, grad, rtl)
    if key in _cache:
        return _cache[key]
    m = FONT.mask(s, rtl)
    pad = 2
    big = Image.new("L", (m.width + pad * 2, m.height + pad * 2), 0)
    big.paste(m, (pad, pad))
    ringm = big.filter(ImageFilter.MaxFilter(3)) if ring else None
    out = Image.new("RGBA", big.size, (0, 0, 0, 0))
    if shadow and ring:
        sh = Image.new("L", big.size, 0)
        sh.paste(ringm, (1, 1))
        out.paste(Image.new("RGBA", big.size, INK + (255,)), (0, 0), sh)
    if ring:
        out.paste(Image.new("RGBA", big.size, ring + (255,)), (0, 0), ringm)
    if grad:
        fillim = Image.new("RGBA", big.size)
        d = ImageDraw.Draw(fillim)
        for y in range(big.height):
            f = (y - pad) / 8
            c = GOLD_HI if f < 0.3 else GOLD if f < 0.7 else GOLD_SH
            d.line((0, y, big.width, y), fill=c + (255,))
        out.paste(fillim, (0, 0), big)
    else:
        out.paste(Image.new("RGBA", big.size, fill + (255,)), (0, 0), big)
    out = out.resize((out.width * px, out.height * px), Image.NEAREST)
    _cache[key] = out
    return out


def bubble(s, px=6, fill=WHITE, ink=INK, tail="down"):
    """A pixel speech bubble (1 font px ink border) around a line of text."""
    key = ("bubble", s, px, fill, tail)
    if key in _cache:
        return _cache[key]
    m = FONT.mask(s)
    bw, bh = m.width + 8, m.height + 5
    th = 4 if tail else 0
    im = Image.new("RGBA", (bw, bh + th), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rectangle((1, 0, bw - 2, bh - 1), fill=ink)
    d.rectangle((0, 1, bw - 1, bh - 2), fill=ink)
    d.rectangle((2, 1, bw - 3, bh - 2), fill=fill)
    d.rectangle((1, 2, bw - 2, bh - 3), fill=fill)
    if tail:
        cx = bw // 2 + 4
        for i in range(th):
            d.line((cx - (th - i), bh - 1 + i, cx, bh - 1 + i), fill=ink)
            if th - i - 2 > 0:
                d.line((cx - (th - i) + 1, bh - 1 + i, cx - 1, bh - 1 + i), fill=fill)
    im.paste(ink + (255,), (4, 3), m)
    im = im.resize((im.width * px, im.height * px), Image.NEAREST)
    _cache[key] = im
    return im


def plate(w, h, fill=NIGHT, rim=GOLD_SH, px=6):
    key = ("plate", w, h, fill, rim, px)
    if key not in _cache:
        im = Image.new("RGBA", (w, h), rim + (255,))
        ImageDraw.Draw(im).rectangle((px, px, w - px - 1, h - px - 1), fill=fill + (255,))
        _cache[key] = im
    return _cache[key]


# ---------------------------------------------------------------------------- cast strips

def char_frame(char, anim, i, scale):
    c = SPRITES["chars"][char]
    a = c["anims"][anim]
    key = ("cf", char, anim, i, scale)
    if key not in _cache:
        tex = img(os.path.join(SPR, a["texture"]))
        fw, fh = c["frameW"], c["frameH"]
        n = a["frames"]
        m = a.get("frameMap", list(range(n)))[i % n]
        cols = a["cols"]
        fr = tex.crop((m % cols * fw, m // cols * fh, m % cols * fw + fw, m // cols * fh + fh))
        _cache[key] = fr.resize((fw * scale, fh * scale), Image.NEAREST)
    return _cache[key], c["anchor"]


def draw_char(canvas, char, anim, t_local, x, y, scale, loop=True, frame=None):
    a = SPRITES["chars"][char]["anims"][anim]
    n = a["frames"]
    i = frame if frame is not None else int(t_local * a["fps"])
    i = i % n if loop else min(i, n - 1)
    fr, anc = char_frame(char, anim, i, scale)
    paste(canvas, fr, x - anc[0] * scale, y - anc[1] * scale, "tl")
    return i


def stage(name, z=6, dim=0.0):
    key = ("stage", name, z, dim)
    if key not in _cache:
        im = img("stage_" + name, z)
        if dim:
            im = Image.blend(im, Image.new("RGBA", im.size, NIGHT + (255,)), dim)
        _cache[key] = im
    return _cache[key]


def draw_stage(canvas, name, z=6, cx=90, cy=160, dim=0.0):
    """Stage at art scale z, art point (cx, cy) at the screen centre."""
    im = stage(name, z, dim)
    paste(canvas, im, W // 2 - cx * z, H // 2 - cy * z, "tl")


def curtain(canvas, open_amt=0.0, dim=0.0):
    """Closed velvet curtain in two halves; open_amt 0..1 slides them out."""
    key = ("curtainhalf", dim)
    if key not in _cache:
        half = Image.new("RGBA", (W // 2 + 12, H), NIGHT + (255,))
        tile = img("curtain_panel", 6)
        for x in range(0, half.width, tile.width):
            for y in range(0, H, tile.height):
                half.alpha_composite(tile, (x, y))
        hem = img("curtain_hem", 6)
        for x in range(0, half.width, hem.width):
            half.alpha_composite(hem, (x, H - hem.height))
        if dim:
            half = Image.blend(half, Image.new("RGBA", half.size, NIGHT + (255,)), dim)
        _cache[key] = half
    half = _cache[key]
    off = int(ease_inout(open_amt) * (W // 2 + 40))
    paste(canvas, half, -off - 12, 0, "tl")
    paste(canvas, half, W // 2 + off, 0, "tl")
    val = img("curtain_valance", 6)
    paste(canvas, val, 0, 0, "tl")


def spotlight(canvas, cx, top, bottom, w_top, w_bot, a=0.22, color=(160, 200, 255)):
    ov = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(ov)
    d.polygon([(cx - w_top, top), (cx + w_top, top), (cx + w_bot, bottom), (cx - w_bot, bottom)],
              fill=color + (int(255 * a),))
    d.ellipse((cx - w_bot, bottom - 40, cx + w_bot, bottom + 40), fill=color + (int(255 * a * 1.4),))
    canvas.alpha_composite(ov)


def speedlines(canvas, t, color=(255, 255, 255), a=0.35, cx=W / 2, cy=H * 0.45, n=34, seed=1):
    ov = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(ov)
    r = rnd(seed, int(t * FPS) // 2)
    for k in range(n):
        ang = (k + r.random() * 0.6) / n * 2 * math.pi
        r0 = 380 + r.random() * 260
        wd = 0.012 + r.random() * 0.02
        pts = [(cx + math.cos(ang) * r0, cy + math.sin(ang) * r0),
               (cx + math.cos(ang - wd) * 1800, cy + math.sin(ang - wd) * 1800),
               (cx + math.cos(ang + wd) * 1800, cy + math.sin(ang + wd) * 1800)]
        d.polygon(pts, fill=color + (int(255 * a),))
    canvas.alpha_composite(ov)


def burst_bg(canvas, t, c1, c2, cx=W / 2, cy=H * 0.45, n=16):
    """Rotating sunburst rays (the leader cards)."""
    d = ImageDraw.Draw(canvas)
    d.rectangle((0, 0, W, H), fill=c1)
    rot = t * 0.35
    for k in range(n):
        a0 = rot + k * 2 * math.pi / n
        a1 = a0 + math.pi / n
        d.polygon([(cx, cy), (cx + math.cos(a0) * 2400, cy + math.sin(a0) * 2400),
                   (cx + math.cos(a1) * 2400, cy + math.sin(a1) * 2400)], fill=c2)


VIGNETTE = None


def vignette(canvas):
    global VIGNETTE
    if VIGNETTE is None:
        m = Image.new("L", (W // 12, H // 12), 0)
        for y in range(m.height):
            for x in range(m.width):
                dx = (x + 0.5) / m.width - 0.5
                dy = (y + 0.5) / m.height - 0.5
                d = math.hypot(dx * 1.1, dy * 0.75) / 0.52
                m.putpixel((x, y), int(clamp((d - 0.62) / 0.5) ** 1.6 * 200))
        m = m.resize((W, H), Image.BILINEAR)
        VIGNETTE = Image.new("RGBA", (W, H), INK + (0,))
        VIGNETTE.putalpha(m)
    canvas.alpha_composite(VIGNETTE)


# ---------------------------------------------------------------------------- particles

def coins_burst(canvas, t, t0, x0, y0, n=24, seed=0, spread=1.0, up=1.0, g=2600, life=1.6, kinds=("coin",)):
    dt = t - t0
    if dt < 0 or dt > life:
        return
    r = rnd("coins", seed)
    for k in range(n):
        ang = -math.pi / 2 + (r.random() - 0.5) * 2.4 * spread
        sp = (700 + r.random() * 900) * up
        vx, vy = math.cos(ang) * sp, math.sin(ang) * sp
        kd = kinds[k % len(kinds)]
        x = x0 + vx * dt
        y = y0 + vy * dt + 0.5 * g * dt * dt
        if y > H + 60:
            continue
        if kd == "coin":
            f = int((dt * 14 + k) % 4)
            im = img("prop_coin%d" % f, 9)
        elif kd == "bill":
            im = img("prop_bill", 9)
        elif kd == "slip":
            im = img("fx_slip_tilt" if (int(dt * 10) + k) % 2 else "fx_slip", 9)
        else:
            im = img("prop_spark", 9)
        paste(canvas, fade(im, 1 - clamp((dt - life * 0.75) / (life * 0.25))), x, y)


def rain(canvas, t, t0, seed, n=40, kinds=("coin", "slip"), speed=700, t1=None):
    if t < t0 or (t1 and t > t1):
        return
    r = rnd("rain", seed)
    for k in range(n):
        x = r.random() * W
        start = t0 + r.random() * 2.2
        if t < start:
            continue
        y = -60 + (t - start) * speed * (0.7 + r.random() * 0.6)
        if y > H + 60:
            continue
        kd = kinds[k % len(kinds)]
        if kd == "coin":
            im = img("prop_coin%d" % int((t * 12 + k) % 4), 9)
        else:
            im = img("fx_slip_tilt" if (int(t * 8) + k) % 2 else "fx_slip", 9)
        paste(canvas, im, x + math.sin(t * 3 + k) * 20, y)


def ripple(canvas, t, t0, x, y):
    """The tap marker: two expanding pixel rings."""
    dt = t - t0
    if not 0 <= dt < 0.35:
        return
    d = ImageDraw.Draw(canvas)
    for k, lag in enumerate((0, 0.08)):
        u = (dt - lag) / 0.27
        if 0 <= u <= 1:
            r = 30 + u * 110
            wdt = int(12 * (1 - u)) + 3
            d.ellipse((x - r, y - r, x + r, y + r), outline=WHITE, width=wdt)


def floaty(canvas, t, t0, s, x, y, px=6, fill=GOLD, life=0.8):
    dt = t - t0
    if not 0 <= dt < life:
        return
    im = text(s, px, fill=fill)
    paste(canvas, fade(im, 1 - clamp((dt - life * 0.6) / (life * 0.4))), x, y - dt * 260)


def shake(t, events):
    """Sum of decaying shakes: events = [(t0, amp_px, dur)]."""
    dx = dy = 0
    for t0, amp, dur in events:
        u = (t - t0) / dur
        if 0 <= u < 1:
            r = rnd("shake", round(t * FPS))
            k = amp * (1 - u) ** 2
            dx += (r.random() * 2 - 1) * k
            dy += (r.random() * 2 - 1) * k
    return int(dx) // 3 * 3, int(dy) // 3 * 3


def flash(canvas, t, t0, dur=0.12, a=0.85, rgb=(255, 255, 255)):
    u = (t - t0) / dur
    if 0 <= u < 1:
        overlay(canvas, rgb, a * (1 - u))


def pop_scale(t, t0, dur=0.16, frm=1.6):
    u = (t - t0) / dur
    if u < 0:
        return 0
    if u >= 1:
        return 1
    return frm + (1 - frm) * back_out(u, 1.6)


def typed(s, t, t0, cps=26):
    n = int((t - t0) * cps)
    return s[:max(0, n)] if n < len(s) else s


def caption(canvas, s, t, t0, y=300, px=8, fill=WHITE, t_out=None, grad=False, plated=False):
    """Top caption with a quick pop; readable with the sound off."""
    if t < t0 or (t_out is not None and t >= t_out):
        return
    im = text(s, px, fill=fill, grad=grad)
    sc = pop_scale(t, t0, 0.14, 1.25)
    if plated:
        paste(canvas, scaled(plate(im.width + 60, im.height + 30, NIGHT, INK, 6), sc), W // 2, y)
    paste(canvas, scaled(im, sc), W // 2, y)


def stamp_img(word, px=10, color=RED):
    key = ("stamp", word, px, color)
    if key in _cache:
        return _cache[key]
    m = FONT.mask(word)
    bw, bh = m.width + 10, m.height + 8
    im = Image.new("RGBA", (bw, bh), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rectangle((0, 0, bw - 1, bh - 1), outline=color, width=1)
    d.rectangle((2, 2, bw - 3, bh - 3), outline=color, width=1)
    im.paste(color + (255,), (5, 4), m)
    # worn ink: knock out a few pixels
    r = rnd("wear", word)
    px_ = im.load()
    for _ in range(0):  # no wear: legibility beats texture at phone size
        x, y = r.randrange(bw), r.randrange(bh)
        px_[x, y] = (0, 0, 0, 0)
    im = im.resize((bw * px, bh * px), Image.NEAREST)
    _cache[key] = im
    return im


def badge(word, px=15):
    """'Coming soon' badge: white letters on a red plate with a gold rim."""
    key = ("badge", word, px)
    if key in _cache:
        return _cache[key]
    im = text(word, px, fill=WHITE)
    w, h = im.width + 8 * px, im.height + 4 * px
    b = Image.new("RGBA", (w, h), GOLD + (255,))
    d = ImageDraw.Draw(b)
    d.rectangle((0, 0, w - 1, h - 1), outline=INK + (255,), width=px)
    d.rectangle((px * 2, px * 2, w - px * 2 - 1, h - px * 2 - 1), fill=RED + (255,))
    d.rectangle((px * 2, h - px * 3, w - px * 2 - 1, h - px * 2 - 1), fill=(150, 24, 40, 255))
    b.alpha_composite(im, ((w - im.width) // 2, (h - im.height) // 2 - px // 2))
    _cache[key] = b
    return b


def slam(canvas, im, t, t0, x, y, angle=0, frm=2.6, dur=0.1):
    if t < t0:
        return
    s = pop_scale(t, t0, dur, frm)
    k = ("rot", id(im), angle)
    if k not in _cache:
        _cache[k] = im.rotate(angle, resample=Image.NEAREST, expand=True)
    paste(canvas, scaled(_cache[k], s), x, y)


# ---------------------------------------------------------------------------- scenes

def scene_hook(c, t):
    draw_stage(c, "balfour", 9, 90, 150, dim=0.72)
    vignette(c)
    tt = t - T_HOOK
    if tt >= 0:
        plate_im = img("ticker_flash_plate_text", 9)
        x = W // 2 + int((1 - ease_out(tt / 0.14)) * 700)
        paste(c, plate_im, x, 380)
    words = [("ישראל", 0, 600), ("הולכת", B, 790), ("לבחירות", 2 * B, 980)]
    for s, t0, y in words:
        if tt >= t0:
            paste(c, scaled(text(s, 15), pop_scale(tt, t0, 0.12, 1.35)), W // 2, y)
    if tt >= 3 * B:
        slam(c, stamp_img("שוב.", 17), tt, 3 * B, W // 2, 1280, angle=9, frm=2.8)
        coins_burst(c, tt, 3 * B, W // 2, 1300, n=10, seed=3, kinds=("slip",), life=0.8, up=0.7)
    flash(c, tt, 3 * B, 0.1, 0.6, RED)


ERAS = ["balfour", "knesset", "courthouse", "washington"]


def scene_count(c, t):
    tt = t - T_COUNT
    hits = [0, B / 2, B, 1.5 * B, 2 * B, 3 * B]
    k = max(i for i, h in enumerate(hits) if tt >= h)
    n = k + 1
    draw_stage(c, ERAS[k % 4], 9, 90, 140, dim=0.55 if n < 6 else 0.35)
    if n == 6:
        speedlines(c, t, GOLD_HI, 0.18)
    vignette(c)
    paste(c, text("סבב בחירות מס׳", 11), W // 2, 470)
    num = text(str(n), 44 if n < 6 else 52, grad=True)
    paste(c, scaled(num, pop_scale(tt, hits[k], 0.1, 1.5 if n < 6 else 2.0)), W // 2, 880)
    if n == 6:
        paste(c, scaled(text("הציבור נרגש.", 11), pop_scale(tt, 3 * B + 0.12, 0.12)), W // 2, 1290)
        flash(c, tt, 3 * B, 0.14, 0.8, GOLD_HI)
        coins_burst(c, tt, 3 * B, W // 2, 900, n=30, seed=6, life=1.0)


BIBI_FEET = (94, 219)


def hud_counter(c, t, value, t0):
    if t < t0:
        return
    s = f"{int(value):,} ₪"
    im = text(s, 9, grad=True)
    p = plate(im.width + 60, im.height + 36)
    y = 300 - int((1 - ease_out((t - t0) / 0.2)) * 300)
    paste(c, p, W // 2, y)
    paste(c, im, W // 2, y)


def magic_value(tt):
    """The HUD counter: rises with the taps, drops when the partners get paid."""
    if tt < 4 * B:
        return 0
    if tt < 6 * B:
        return 1515 * ease_out((tt - 4 * B) / (2 * B))
    v = 1515 + clamp((tt - 6 * B) / (4 * B)) ** 2 * 60000
    if tt > 10 * B:
        v -= clamp((tt - 10 * B) / 0.3) * 48000
    return v


def scene_magic(c, t):
    tt = t - T_MAGIC
    z = 6 if tt < 4 * B else 9
    fx, fy = BIBI_FEET
    cx, cy = (90, 160) if z == 6 else (fx - 6, fy - 62)
    draw_stage(c, "balfour", z, cx, cy)
    sx = W // 2 + (fx - cx) * z
    sy = H // 2 + (fy - cy) * z
    spotlight(c, sx, 0, sy, 60, 220, 0.12)
    s = z // 3  # d3 cast at art scale z
    crit_t0 = 4 * B
    if crit_t0 <= tt < crit_t0 + 14 / 12:
        i = draw_char(c, "bibi", "crit", tt - crit_t0, sx, sy, s, loop=False)
        if i >= 4:
            hm = SPRITES["chars"]["bibi"]["anims"]["crit"]["hatMouth"][i]
            anc = SPRITES["chars"]["bibi"]["anchor"]
            hx, hy = sx + (hm[0] - anc[0]) * s, sy + (hm[1] - anc[1]) * s
            coins_burst(c, tt, crit_t0 + 4 / 12, hx, hy, n=36, seed=11, life=1.8)
    elif tt >= crit_t0 + 14 / 12:
        # tapping on the beat: tap strip per beat, a ripple, coins, a floating +₪
        tb = tt - (crit_t0 + 14 / 12)
        beat_t = (tt - 6 * B) % (B / 2) if tt >= 6 * B else tb
        draw_char(c, "bibi", "tap", beat_t, sx, sy, s, loop=False)
    else:
        draw_char(c, "bibi", "idle", tt, sx, sy, s)
    # tap feedback + coins after the crit
    for k in range(12):
        tk = 6 * B + k * B / 2
        if tk <= tt < tk + 1.2 and tk < 10 * B:
            hm = SPRITES["chars"]["bibi"]["anims"]["tap"]["hatMouth"][3]
            anc = SPRITES["chars"]["bibi"]["anchor"]
            hx, hy = sx + (hm[0] - anc[0]) * s, sy + (hm[1] - anc[1]) * s
            ripple(c, tt, tk, sx - 40, sy - 380)
            coins_burst(c, tt, tk + 0.1, hx, hy, n=8, seed=20 + k, life=1.1, spread=0.6)
            floaty(c, tt, tk, "+" + f"{(k + 1) * 1000:,}" + " ₪", sx + 200 - (k % 3) * 140, sy - 640 + (k % 2) * 60, px=7, life=0.6)
    vignette(c)
    hud_counter(c, tt, magic_value(tt), 4 * B)
    # chat: the partners want their cut
    if tt >= 8 * B:
        bubbles = [(8 * B, "ben-gvir", "אני פורש! אני פורש!", 1200), (8.9 * B, "smotrich", "אין כסף! אין כסף!", 1420)]
        for t0, who, line, y in bubbles:
            if tt >= t0:
                bim = bubble(line, 6, tail=None)
                av = img("avatar_pick_%s_d3" % who, 2)
                slide = int((1 - ease_out((tt - t0) / 0.15)) * 900)
                x = W - 210 - bim.width // 2 + slide
                paste(c, bim, x, y)
                paste(c, av, W - 110 + slide, y, "c")
        if tt >= 10 * B:
            slam(c, stamp_img("שולם", 9), tt, 10 * B, W - 420, 1310, angle=-6)
            floaty(c, tt, 10 * B, "-48,000 ₪", W // 2 - 200, 1150, px=8, fill=RED, life=1.0)
    # captions (all within the first second of each bar)
    caption(c, "הקוסם חוזר לבמה.", tt, 0.25, 620, 9, t_out=4 * B)
    caption(c, "שולף שקלים מכובע.", tt, 4 * B + 0.1, 460, 9, t_out=8 * B, plated=True)
    caption(c, "משלם לשותפים.", tt, 8 * B, 460, 9, plated=True)
    # the curtain opens on the drop
    if tt < 0.6:
        curtain(c, tt / 0.55)


def scene_gag(c, t):
    tt = t - T_GAG
    if tt < 4 * B:
        # the DOHA suitcase flies in, gets tapped, bursts
        draw_stage(c, "balfour", 6)
        fx, fy = BIBI_FEET
        sx, sy = W // 2 + (fx - 90) * 6, H // 2 + (fy - 160) * 6
        draw_char(c, "bibi", "idle", tt, sx, sy, 2)
        catch = 2 * B
        if tt < catch:
            u = tt / catch
            x = W + 150 - u * (W * 0.55)
            y = 620 + math.sin(tt * 9) * 40
            paste(c, img("suitcase", 12), x, y)
        else:
            x, y = W + 150 - W * 0.55, 620
            ripple(c, tt, catch, x, y)
            coins_burst(c, tt, catch, x, y, n=40, seed=31, kinds=("bill", "coin"), life=1.6)
            floaty(c, tt, catch + 0.05, "+1,500,000 ₪", W // 2, 820, px=9, life=1.6)
            flash(c, tt, catch, 0.1, 0.5, GOLD_HI)
        vignette(c)
        caption(c, "תופס מזוודות.", tt, 0.05, 430, 9)
        ticker(c, tt, 'תפסת מזוודה. בלשכה: "איזו מזוודה?"')
    else:
        u = tt - 4 * B
        draw_stage(c, "courthouse", 6)
        fx, fy = BIBI_FEET
        sx, sy = W // 2 + (fx - 90) * 6, H // 2 + (fy - 160) * 6
        draw_char(c, "bibi", "idle", u, sx, sy, 2)
        vignette(c)
        # the summons card
        card_y = 1050
        if u >= 0:
            s = pop_scale(u, 0, 0.14, 0.4)
            card = plate(900, 330, NAVY, GOLD_SH, 9)
            paste(c, scaled(card, s), W // 2, card_y)
            if u > 0.1:
                paste(c, text("זימון לעדות", 10, grad=True), W // 2, card_y - 70)
                paste(c, text("ביבי זומן לדוכן העדים.", 6), W // 2, card_y + 60)
        if u >= 2 * B:
            slam(c, tint(img("stamp_postponed_paper_rot", 13), RED), u, 2 * B, W // 2 + 60, card_y + 10, angle=-8)
            flash(c, u, 2 * B, 0.1, 0.5, RED)
        caption(c, "דוחה את המשפט.", u, 2 * B, 430, 9)


def ticker(c, tt, line):
    bar = img("ticker_bar", 6)
    y = 1330
    paste(c, bar, 0, y, "tl")
    im = text(line, 6, ring=None, shadow=False)
    x = -im.width + int(tt * 420)  # the game's ticker crawls left -> right (RTL reading order enters first)
    paste(c, im, x, y + bar.height // 2 - im.height // 2 + 6, "tl")
    pl = img("ticker_flash_plate_text", 6)
    paste(c, pl, W - pl.width - 12, y + bar.height // 2 - pl.height // 2 + 3, "tl")


LEADERS = [  # (sprite id, name, line, react cue, era)
    ("bennett", "בנט", "ביחד! ביחד!", "critReact_D_whoosh", "knesset"),
    ("ben-gvir", "בן גביר", "אני פורש! אני פורש!", "critReact_D_shout", "washington"),
    ("liberman", "ליברמן", "לא יושב! לא יושב!", "critReact_D_no", "courthouse"),
    ("eisenkot", "אייזנקוט", "ישר! ישר!", "critReact_D_land", "balfour"),
    ("smotrich", "סמוטריץ׳", "אין כסף! אין כסף!", "critReact_D_shout", "knesset"),
    ("deri", "דרעי", "ידידי! ידידי!", "critReact_D_land", "washington"),
    ("golan", "גולן", "איחוד! איחוד!", "critReact_D_whoosh", "courthouse"),
]
LEAD_SLOTS = [(2, 2), (4, 2), (6, 2), (8, 1), (9, 1), (10, 1), (11, 1)]  # (start beat, beats)
BURST = [((22, 60, 140), (34, 87, 166)), ((120, 24, 40), (170, 40, 57)), ((20, 70, 60), (40, 120, 90)),
         ((70, 40, 110), (110, 70, 160))]


def scene_leaders(c, t):
    tt = t - T_LEAD
    beat = tt / B
    if beat < 2:
        # the picker: "who forms the government this time?"
        curtain(c, 0, dim=0.2)
        vignette(c)
        paste(c, scaled(text("מי מקים את", 12), pop_scale(tt, 0, 0.12)), W // 2, 470)
        paste(c, scaled(text("הממשלה הפעם?", 12), pop_scale(tt, 0.1, 0.12)), W // 2, 610)
        ids = ["bibi", "bennett", "ben-gvir", "liberman", "eisenkot", "smotrich", "deri", "golan"]
        focus = int(tt / (B / 4)) % 8
        for k, cid in enumerate(ids):
            gx = W // 2 + (k % 4 - 1.5) * 230
            gy = 900 + (k // 4) * 240
            tile = img("pick_tile_focus" if k == focus else "pick_tile_idle", 6)
            if tt < k * 0.05:
                continue
            paste(c, tile, gx, gy)
            paste(c, img("avatar_pick_%s_d3" % cid, 2), gx, gy)
        return
    if beat >= 12:
        scene_lineup(c, t)
        return
    k = max(i for i, (b0, _) in enumerate(LEAD_SLOTS) if beat >= b0)
    b0, nb = LEAD_SLOTS[k]
    cid, name, line, _, era = LEADERS[k]
    u = tt - b0 * B
    c1, c2 = BURST[k % 4]
    burst_bg(c, t, c1, c2)
    floor = stage(era, 6, 0.2)
    paste(c, floor.crop((0, 1200, W, 1920)), 0, 1560, "tl")
    speedlines(c, t, WHITE, 0.16, seed=k)
    # slam-in from the side: 3 frames of travel, then the tap strip on the beat
    side = 1 if k % 2 else -1
    x = W // 2 + side * int((1 - ease_out(u / 0.12)) * 800)
    draw_char(c, cid, "tap", u, x, 1780, 4, loop=True)
    vignette(c)
    # the line, in a bubble; the name on a plate
    bim = bubble(line, 7 if nb == 2 else 6)
    paste(c, scaled(bim, pop_scale(u, 0.06, 0.12, 0.3)), W // 2, 330)
    nm = text(name, 13, grad=True)
    p = plate(nm.width + 70, nm.height + 40)
    paste(c, p, W // 2, 1450)
    paste(c, nm, W // 2, 1450)
    flash(c, u, 0, 0.08, 0.6)


def scene_lineup(c, t):
    tt = t - T_LEAD - 12 * B
    draw_stage(c, "knesset", 6)
    spotlight(c, W // 2, 0, 1500, 120, 560, 0.1, GOLD_HI)
    order = [("liberman", 150), ("deri", 400), ("golan", 680), ("eisenkot", 930),
             ("smotrich", 70), ("ben-gvir", 330), ("bibi", 560), ("bennett", 820)]
    for k, (cid, x) in enumerate(order):
        t0 = k * B / 2
        if tt < t0:
            continue
        y = 1260 if k < 4 else 1600
        dy = int((1 - ease_out((tt - t0) / 0.12)) * -500)
        anim = "idle"
        draw_char(c, cid, anim, tt + k * 0.3, x + 60, y + dy, 2)
    vignette(c)
    caption(c, "כולם היו ראש ממשלה.", tt, 0.0, 400, 9)


def scene_roll(c, t):
    tt = t - T_ROLL
    # the lineup stays behind as the curtain closes over it
    if tt < 0.6:
        scene_lineup(c, t)
        curtain(c, 1 - tt / 0.55)
    else:
        curtain(c, 0)
        spotlight(c, W // 2, 0, 1180, 50, 300, 0.18 + 0.08 * math.sin(tt * 40))
    vignette(c)
    # Dubi flies across squawking
    if 0.2 <= tt < 1.8:
        u = (tt - 0.2) / 1.6
        x = -150 + u * (W + 300)
        y = 820 + math.sin(u * 9) * 60
        fr, anc = char_frame("dubi", "fly", int(tt * 12), 12)
        paste(c, fr, x, y)
        bim = bubble("בחירות! בחירות!", 6)
        paste(c, bim, clamp(x, 330, W - 330), y - 260)
    # the hat drops into the light and trembles with the roll
    if tt >= 1.0:
        u = tt - 1.0
        y = -200 + ease_out(u / 0.35) * 1320
        j = int(math.sin(tt * 60) * 6 * clamp(u / 1.0)) // 3 * 3
        glow = img("prop_hat_glow", 18)
        if int(tt * 16) % 2:
            paste(c, glow, W // 2 + j, y - 6)
        paste(c, img("prop_hat", 18), W // 2 + j, y)


def scene_title(c, t):
    tt = t - T_TITLE
    curtain(c, 0, dim=0.15)
    spotlight(c, W // 2, 0, 1700, 90, 520, 0.2, GOLD_HI)
    rain(c, t, T_TITLE + 0.3, 5, n=46)
    vignette(c)
    # hat flips away as the wordmark bursts out of it
    if tt < 0.5:
        hat = img("prop_hat", 18)
        paste(c, hat.rotate(-tt * 400, Image.NEAREST, expand=True), W // 2 + tt * 900, 1120 + tt * tt * 3000)
    coins_burst(c, tt, 0, W // 2, 1000, n=70, seed=77, life=2.2, kinds=("coin", "coin", "slip", "bill"))
    wm = img("wordmark", 6)
    s = pop_scale(tt, 0, 0.18, 0.2)
    wy = 700
    if s:
        paste(c, scaled(wm, s), W // 2, wy)
    # the gold shine sweep
    if 0.35 <= tt <= 0.95:
        u = (tt - 0.35) / 0.6
        band = Image.new("L", wm.size, 0)
        bx = int(-200 + u * (wm.width + 400))
        ImageDraw.Draw(band).polygon([(bx, 0), (bx + 90, 0), (bx - 60, wm.height), (bx - 150, wm.height)], fill=200)
        band = ImageChops.multiply(band, wm.getchannel("A"))
        shine = Image.new("RGBA", wm.size, (255, 255, 240, 0))
        shine.putalpha(band)
        paste(c, shine, W // 2, wy)
    if tt >= 0.45:
        paste(c, scaled(text("הבחירות שלא נגמרות", 9), pop_scale(tt, 0.45, 0.12)), W // 2, 940)
    flash(c, tt, 0, 0.16, 1.0)
    # coming soon, on the motif's downbeat
    down = T_MOTIF - T_TITLE + 0.776
    if tt >= down:
        slam(c, badge("בקרוב"), tt, down, W // 2, 1200, angle=-4, frm=2.4)
        flash(c, tt, down, 0.1, 0.5, GOLD_HI)
    if tt >= down + 0.5:
        paste(c, text("@od.sevev", 8, fill=WHITE, rtl=False), W // 2, 1420)
    if tt >= down + 0.8:
        paste(c, text("סאטירה. לא מטעם אף מפלגה.", 5, fill=(190, 196, 220)), W // 2, 1530)
    # Dubi on the corner, squawking with the motif
    if tt >= T_MOTIF - T_TITLE:
        u = tt - (T_MOTIF - T_TITLE)
        anim = "squawk" if down - (T_MOTIF - T_TITLE) <= u < down - (T_MOTIF - T_TITLE) + 0.4 else "idle"
        fr, anc = char_frame("dubi", anim, int(u * 10), 9)
        paste(c, fr, 150, 1400, "c")


def frame(t):
    c = Image.new("RGBA", (W, H), INK + (255,))
    if t < T_COUNT:
        scene_hook(c, t)
        dx, dy = shake(t, [(3 * B, 36, 0.35)])
    elif t < T_MAGIC:
        scene_count(c, t)
        dx, dy = shake(t, [(T_COUNT + 3 * B, 30, 0.3)])
    elif t < T_GAG:
        scene_magic(c, t)
        dx, dy = shake(t, [(T_MAGIC, 18, 0.25), (T_MAGIC + 4 * B + 4 / 12, 24, 0.3), (T_MAGIC + 10 * B, 30, 0.3)])
    elif t < T_LEAD:
        scene_gag(c, t)
        dx, dy = shake(t, [(T_GAG + 2 * B, 24, 0.3), (T_GAG + 6 * B, 40, 0.35)])
    elif t < T_ROLL:
        scene_leaders(c, t)
        dx, dy = shake(t, [(T_LEAD + b * B, 16, 0.18) for b, _ in LEAD_SLOTS])
    elif t < T_TITLE:
        scene_roll(c, t)
        u = (t - T_ROLL) / BAR
        dx, dy = shake(t, [(T_ROLL + 1.0, 10 * u, 1.1)])
    else:
        scene_title(c, t)
        dx, dy = shake(t, [(T_TITLE, 50, 0.45), (T_MOTIF + 0.776, 30, 0.3)])
    if dx or dy:
        c2 = Image.new("RGBA", (W, H), INK + (255,))
        c2.alpha_composite(c, (max(0, dx), max(0, dy)), (max(0, -dx), max(0, -dy)))
        c = c2
    # fade in from black and out at the very end
    overlay(c, INK, 1 - clamp(t / 0.08))
    overlay(c, INK, clamp((t - (DUR - 0.25)) / 0.25))
    return c.convert("RGB")


# ---------------------------------------------------------------------------- sound design

def build_sfx():
    SFX.clear()
    # hook
    sfx(0.0, "ultimatumZero_D", -6)
    for k in range(3):
        sfx(k * B, "slipStamp", -2)
    sfx(3 * B, "stamp", 0); sfx(3 * B, "gavel_a", -2); sfx(3 * B, "stamp_bell", -6)
    # count-up: the tap walk climbs with the numbers
    for k, h in enumerate([0, B / 2, B, 1.5 * B, 2 * B]):
        sfx(T_COUNT + h, "tap_D_s%d_d25" % (k * 1 + 1), -2)
        sfx(T_COUNT + h, "coin_D_a", -10)
    sfx(T_COUNT + 3 * B, "tap_D_s7_d25", 0); sfx(T_COUNT + 3 * B, "stamp_bell", -3)
    sfx(T_COUNT + 3 * B, "merge_D", -4)
    # magician
    sfx(T_MAGIC, "shutter_p1", -6)
    sfx(T_MAGIC + 4 * B + 4 / 12, "rabbitCrit_D_s150", 0)
    sfx(T_MAGIC + 4 * B + 3 / 12, "coin_D_a", -4)
    walk = 0
    for k in range(8):
        tk = T_MAGIC + 6 * B + k * B / 2
        sfx(tk, "tap_D_s%d_d25" % (walk % 8), -3); walk += 1
        sfx(tk + 0.1, "coin_D_%s" % "ab"[k % 2], -8)
    sfx(T_MAGIC + 8 * B, "chatPing_D_benGvir", -2)
    sfx(T_MAGIC + 8.9 * B, "chatPing_D_smotrich", -2)
    sfx(T_MAGIC + 10 * B, "stamp", 0); sfx(T_MAGIC + 10 * B, "buy_D_d25", -4)
    # gags
    sfx(T_GAG, "suitcaseSpawn_g28", -2)
    sfx(T_GAG + 2 * B, "suitcaseCatch_D", 0)
    sfx(T_GAG + 4 * B, "gavel_a", -1); sfx(T_GAG + 5 * B, "gavel_b", -1)
    sfx(T_GAG + 6 * B, "stamp", 0); sfx(T_GAG + 6 * B, "gavel_c", -2); sfx(T_GAG + 6 * B, "courtOut_D", -6)
    # leaders
    sfx(T_LEAD, "leaderPick_D", -2)
    for k in range(8):
        sfx(T_LEAD + k * B / 4, "uiClick_D", -12)
    contours = json.load(open(os.path.join(AUD, "od_manifest.json")))["babbleContours"]
    for (cid, name, line, react, era), (b0, nb) in zip(LEADERS, LEAD_SLOTS):
        t0 = T_LEAD + b0 * B
        sfx(t0, react, -3)
        word = line.split(" ")[0] if line.count("!") == 2 and len(line.split(" ")) == 2 else line[:line.index("!") + 1]
        cont = contours.get(word) or contours.get(word.strip())
        if cont:
            reps = 2 if nb == 2 else 1
            tt = t0 + 0.12
            for r in range(reps):
                for deg, octv in cont:
                    sfx(tt, "dubiBlip_D_%s_%d" % (deg, int(octv)), -4)
                    tt += 0.085
                tt += 0.15
    for k in range(8):
        sfx(T_LEAD + 12 * B + k * B / 2, "tap_D_s%d_d12" % k, -4)
    # roll + title: the fanfare is the music bed; Dubi squawks across
    sfx(T_ROLL + 0.25, "dubiSquawk_D_up", -2); sfx(T_ROLL + 0.55, "dubiSquawk_D_down", -2)
    for k, (deg, octv) in enumerate(contours.get("בחירות!", [])):
        sfx(T_ROLL + 0.35 + k * 0.085, "dubiBlip_D_%s_%d" % (deg, int(octv)), -4)
    sfx(T_TITLE, "stamp_bell", -2); sfx(T_TITLE, "coin_D_a", -2)
    sfx(T_MOTIF + 0.776, "stamp", -1)
    sfx(T_MOTIF + 0.776, "dubiSquawk_D_up", -4)


def load_wav(name):
    path = os.path.join(WAV, name + ".wav")
    if not os.path.exists(path):
        os.makedirs(WAV, exist_ok=True)
        subprocess.run([sys.executable, os.path.join(HERE, "res2wav.py"), os.path.join(AUD, name + ".res"), path],
                       check=True, stdout=subprocess.DEVNULL)
    w = wave.open(path)
    a = np.frombuffer(w.readframes(w.getnframes()), np.int16).astype(np.float32) / 32768
    if w.getnchannels() == 2:
        a = a.reshape(-1, 2).mean(1)
    r = w.getframerate()
    n = int(len(a) * SR / r)
    return np.interp(np.linspace(0, len(a) - 1, n), np.arange(len(a)), a).astype(np.float32)


SR = 48000


def db(x):
    return 10 ** (x / 20)


def lowpass(a, fc):
    """One-pole-cascade low-pass (the 'Outside' bus)."""
    k = math.exp(-2 * math.pi * fc / SR)
    out = a.copy()
    for _ in range(2):
        y = 0.0
        o = np.empty_like(out)
        for i in range(len(out)):  # short clip (4 s); fine in pure python
            y = (1 - k) * out[i] + k * y
            o[i] = y
        out = o
    return out


def mix_audio(path):
    n = int(DUR * SR)
    bus = np.zeros(n, np.float32)

    def put(t, a, gain=1.0):
        i = int(t * SR)
        if i >= n:
            return
        a = a[: n - i]
        bus[i:i + len(a)] += a * gain

    # 0-2 bars: the protest drums outside the residence, muffled
    outside = load_wav("music_balfour_outside")
    put(0, lowpass(outside, 900), db(-2))
    # the drop: Balfour, all three layers, bars 1-9 of the loop
    music = load_wav("music_balfour_L0") + load_wav("music_balfour_L1") + load_wav("music_balfour_L2")
    seg = music[: int(9 * BAR * SR)].copy()
    ramp = int(0.25 * SR)
    seg[-ramp:] *= np.linspace(1, 0.35, ramp)
    put(T_MAGIC, seg, db(-4))
    # the election fanfare: roll from bar 11, the hit on the title
    put(T_ROLL, load_wav("stinger_fanfare_D_t0"), db(-1))
    # the "עוד סבב" motif signs off
    put(T_MOTIF, load_wav("stinger_motif_D"), db(-1))
    build_sfx()
    for t, name, g in SFX:
        put(t, load_wav(name), db(g - 3))
    # gentle tail fade, then peak-normalise; loudnorm happens in ffmpeg
    tail = int(0.3 * SR)
    bus[-tail:] *= np.linspace(1, 0, tail)
    bus /= max(1e-6, np.abs(bus).max()) / 0.95
    with wave.open(path, "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes((bus * 32767).astype(np.int16).tobytes())


# ---------------------------------------------------------------------------- main

def ffmpeg():
    import imageio_ffmpeg
    return imageio_ffmpeg.get_ffmpeg_exe()


def stills(times, path):
    ims = [frame(t).resize((270, 480), Image.LANCZOS) for t in times]
    cols = 6
    sheet = Image.new("RGB", (cols * 280, ((len(ims) + cols - 1) // cols) * 500), (30, 30, 30))
    d = ImageDraw.Draw(sheet)
    for i, (t, im) in enumerate(zip(times, ims)):
        x, y = (i % cols) * 280 + 5, (i // cols) * 500 + 5
        sheet.paste(im, (x, y))
        d.text((x + 4, y + 482), "%.2fs" % t, fill=(255, 255, 0))
    sheet.save(path)


def main():
    if "--stills" in sys.argv:
        ts = [float(x) for x in sys.argv[sys.argv.index("--stills") + 1:]] or [
            0.3, 1.2, 1.7, 2.3, 3.4, 3.9, 4.3, 5.2, 6.6, 7.8, 9.0, 10.0,
            11.0, 11.6, 12.8, 13.8, 14.8, 15.9, 17.0, 18.0, 19.0, 20.3, 21.5, 22.3,
            23.3, 24.2, 25.1, 25.8, 27.0, 28.2, 29.2, 29.8]
        stills(ts, os.path.join(OUT, "_stills.png"))
        return
    audio = os.path.join(OUT, "_mix.wav")
    mix_audio(audio)
    video = os.path.join(OUT, "od-sevev-teaser.mp4")
    cmd = [ffmpeg(), "-y", "-loglevel", "error",
           "-f", "rawvideo", "-pix_fmt", "rgb24", "-s", f"{W}x{H}", "-r", str(FPS), "-i", "-",
           "-i", audio,
           "-c:v", "libx264", "-preset", "slow", "-crf", "16", "-pix_fmt", "yuv420p", "-profile:v", "high",
           "-movflags", "+faststart",
           "-af", "loudnorm=I=-14:TP=-1.0:LRA=11", "-c:a", "aac", "-b:a", "192k", "-ar", "48000",
           "-shortest", video]
    p = subprocess.Popen(cmd, stdin=subprocess.PIPE)
    nf = int(DUR * FPS)
    for i in range(nf):
        p.stdin.write(frame(i / FPS).tobytes())
        if i % 60 == 0:
            print(f"frame {i}/{nf}", flush=True)
    p.stdin.close()
    if p.wait() != 0:
        raise SystemExit("ffmpeg failed")
    print(video)


if __name__ == "__main__":
    main()
