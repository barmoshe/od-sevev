"""'עוד סבב' gameplay reel, iPhone cut (v4): the same Ben Gvir round, played on an iPhone.

What changed from gameplay.py (v3, the bare screen on velvet), after the research pass:
  * a drawn iPhone (titanium rim, Dynamic Island, iOS status bar, home indicator) over a blurred copy of
    the footage, with a slow handheld drift so it reads as a phone in a hand, not a flat screenshot;
  * "show touches" circles at every real tap of the capture (Ben Gvir, the buy buttons, the tabs, the
    coalition payments), the same disc + ripple the workshop's video-tutorial kit uses;
  * a camera that opens tight on the game (gameplay in the first frame), pulls back to reveal the phone,
    and pushes in on each action (push 0.9 s, zoom 1.1-1.6);
  * captions moved to the top band (Reels hides the bottom ~320 px under its own caption and buttons);
  * the hook is late-game footage, so the full screen (meter, tab bar) is on it from frame one;
  * Mordechai David stays an easter egg: he peeks out from behind the phone, and holds on the cover.

    python3 store/gameplay/src/gameplay_iphone.py <take dir>            # -> store/gameplay/od-sevev-gameplay-iphone.mp4
    python3 store/gameplay/src/gameplay_iphone.py <take dir> --stills   # key-frame contact sheet
"""
import math
import os
import random
import subprocess
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, "..", "..", "teaser", "src"))
import teaser as k  # noqa: E402
import gameplay as g  # noqa: E402
from teaser import (INK, NIGHT, GOLD_HI, W, H, FPS, paste, scaled, text, plate, flash, pop_scale,  # noqa: E402
                    clamp, ease_out, ease_inout)
from gameplay import BAR, DUR, MUSIC, OUT, md_frame  # noqa: E402

NAME = "od-sevev-gameplay-iphone"   # output stem (a reel module built on this one sets its own)
PLAN = os.path.join(OUT, "plan-bengvir.json")
MUSIC_AT = 0.0                     # where in MUSIC the reel starts (s)
CAP_W, CAP_H = 1080, 2338          # the Movie Maker take (1080x2338, the game's 720x1559 logical x 1.5)

# ---------------------------------------------------------------------------- the phone (wide shot)
SW = 610                           # screen width in the wide shot
GW, GH = SW, round(SW * CAP_H / CAP_W)          # the game area: 610 x 1321
SB = round(SW * 59 / 393)          # iOS status bar (59 pt of a 393 pt wide iPhone 15 Pro)
SH = SB + GH                       # 1413
TI, BZ = 10, 26                    # titanium band, total border (titanium + black glass border)
PW, PH = SW + 2 * BZ, SH + 2 * BZ  # 662 x 1465
RS = round(SW * 55 / 393)          # screen corner radius (55 pt)
RO = RS + BZ
C = (540, 1010)                    # the phone's centre in the wide shot (top edge ~277, under the caption band)
HR = 1.7                           # chrome is drawn once at this scale (the tightest zoom) and only scaled down
MARGIN = 8                         # side buttons stick out this far (unit scale)

TI_BASE = (142, 138, 130)          # natural titanium
TI_DARK = (74, 72, 68)
TI_HI = (214, 210, 200)

try:
    SF = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", int(SB * 0.36 * HR))
except OSError:
    SF = ImageFont.load_default()


def rrect(d, box, r, fill):
    d.rounded_rectangle(box, radius=r, fill=fill)


def build_chrome():
    """The body at HR, supersampled x2: side buttons, titanium band with a highlight, black border."""
    s = HR * 2
    w, h = int((PW + 2 * MARGIN) * s), int(PH * s)
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    m = MARGIN * s
    for side, y0, y1 in (("l", 0.150, 0.185), ("l", 0.225, 0.290), ("l", 0.310, 0.375), ("r", 0.250, 0.350)):
        x0 = 0 if side == "l" else w - m - 6 * s
        rrect(d, (x0 + (2 * s if side == "l" else 0), y0 * h, x0 + m + 6 * s - (0 if side == "l" else 2 * s), y1 * h),
              3 * s, TI_DARK + (255,))
        rrect(d, (x0 + (3 * s if side == "l" else s), y0 * h + s, x0 + m + 5 * s - (0 if side == "l" else 3 * s),
                  y1 * h - s), 3 * s, TI_BASE + (255,))
    box = (m, 0, w - m - 1, h - 1)
    rrect(d, box, RO * s, TI_DARK + (255,))
    rrect(d, (box[0] + 1.5 * s, box[1] + 1.5 * s, box[2] - 1.5 * s, box[3] - 1.5 * s), (RO - 1.5) * s, TI_HI + (255,))
    rrect(d, (box[0] + 3 * s, box[1] + 3 * s, box[2] - 3 * s, box[3] - 3 * s), (RO - 3) * s, TI_BASE + (255,))
    rrect(d, (box[0] + (TI - 2) * s, box[1] + (TI - 2) * s, box[2] - (TI - 2) * s, box[3] - (TI - 2) * s),
          (RO - TI + 2) * s, TI_DARK + (255,))
    rrect(d, (box[0] + TI * s, box[1] + TI * s, box[2] - TI * s, box[3] - TI * s), (RO - TI) * s, (6, 6, 9, 255))
    return im.resize((int((PW + 2 * MARGIN) * HR), int(PH * HR)), Image.LANCZOS)


def build_mask():
    s = HR * 2
    m = Image.new("L", (int(SW * s), int(SH * s)), 0)
    ImageDraw.Draw(m).rounded_rectangle((0, 0, m.width - 1, m.height - 1), radius=RS * s, fill=255)
    return m.resize((int(SW * HR), int(SH * HR)), Image.LANCZOS)


def build_status():
    """iOS status bar at HR: time, Dynamic Island, signal, wi-fi, battery (white on the game's black top)."""
    s = HR * 2
    u = SW / 393 * s                       # one iOS point
    im = Image.new("RGBA", (int(SW * s), int(SB * s)), (0, 0, 0, 255))
    d = ImageDraw.Draw(im)
    iw, ih, it = 126 * u, 37 * u, 11 * u   # the island
    cx = im.width / 2
    rrect(d, (cx - iw / 2, it, cx + iw / 2, it + ih), ih / 2, (0, 0, 0, 255))
    cy = it + ih / 2
    font = ImageFont.truetype(SF.path, int(17 * u)) if hasattr(SF, "path") else SF
    d.text((66 * u, cy), "9:41", fill=(255, 255, 255, 255), font=font, anchor="mm")
    x = im.width - 30 * u                  # battery, right to left
    bw, bh = 25 * u, 12 * u
    rrect(d, (x - bw, cy - bh / 2, x, cy + bh / 2), 3.5 * u, (140, 140, 140, 255))
    rrect(d, (x - bw + 2 * u, cy - bh / 2 + 2 * u, x - bw + 2 * u + (bw - 4 * u) * 0.8, cy + bh / 2 - 2 * u),
          2 * u, (255, 255, 255, 255))
    d.rounded_rectangle((x + 1 * u, cy - 2 * u, x + 2.5 * u, cy + 2 * u), radius=u, fill=(140, 140, 140, 255))
    x -= bw + 7 * u                        # wi-fi: three arcs and a dot
    for i, r in enumerate((11 * u, 7.5 * u, 4 * u)):
        d.arc((x - 8.5 * u - r, cy + 5 * u - r, x - 8.5 * u + r, cy + 5 * u + r), 225, 315,
              fill=(255, 255, 255, 255), width=int(2.4 * u))
    d.ellipse((x - 10 * u, cy + 3.5 * u, x - 7 * u, cy + 6.5 * u), fill=(255, 255, 255, 255))
    x -= 23 * u                            # signal: four bars
    for i in range(4):
        bh2 = (4 + i * 2.6) * u
        rrect(d, (x - 17 * u + i * 4.6 * u, cy + 6 * u - bh2, x - 14 * u + i * 4.6 * u, cy + 6 * u), u,
              (255, 255, 255, 255))
    return im.resize((int(SW * HR), int(SB * HR)), Image.LANCZOS)


def build_glare():
    """A faint diagonal reflection over the glass."""
    s = HR
    im = Image.new("L", (int(SW * s), int(SH * s)), 0)
    d = ImageDraw.Draw(im)
    w, h = im.size
    d.polygon([(w * 0.55, 0), (w * 0.95, 0), (w * 0.05, h * 0.55), (-w * 0.35, h * 0.55)], fill=16)
    im = im.filter(ImageFilter.GaussianBlur(40 * s))
    out = Image.new("RGBA", im.size, (255, 255, 255, 0))
    out.putalpha(im)
    return out


def build_shadow():
    s = 0.5
    pad = 90
    m = Image.new("L", (int((PW + 2 * pad) * s), int((PH + 2 * pad) * s)), 0)
    ImageDraw.Draw(m).rounded_rectangle((pad * s, pad * s, (pad + PW) * s, (pad + PH) * s), radius=RO * s, fill=200)
    m = m.filter(ImageFilter.GaussianBlur(28 * s))
    out = Image.new("RGBA", m.size, (0, 0, 0, 0))
    out.putalpha(m)
    return out, pad


CHROME = MASK = STATUS = GLARE = SHADOW = None
_rs = {}


def resized(key, im, size, resample=Image.LANCZOS):
    kk = (key, size)
    if kk not in _rs:
        if len(_rs) > 64:
            _rs.clear()
        _rs[kk] = im.resize(size, resample)
    return _rs[kk]


# ---------------------------------------------------------------------------- the cut
# (video start, video end, take start, speed). The hook is late game: the full screen, meter and tab bar
# included (the tab bar only unlocks ~15 s into a real round, so the early clips show it without).
CLIPS = [
    (0.0, BAR(2), 39.9, 1.0),              # hook: Ben Gvir forwarding at 415k, 38 of 61
    (BAR(2), BAR(4), 0.3, 1.0),            # the picker
    (BAR(4), BAR(6), 3.0, 1.0),            # the first taps
    (BAR(6), BAR(8), 9.0, 1.2),            # the drop: buying sources
    (BAR(8), BAR(10), 15.0, 1.0),          # more sources
    (BAR(10), BAR(12) + 1.0, 21.5, 1.0),   # the in-game blockade
    (BAR(12) + 1.0, BAR(13), 27.0, 0.6),   # the break
    (BAR(13), BAR(17), 31.0, 0.95),        # the coalition chat, paying
    (BAR(17), BAR(21), 45.0, 1.0),         # the submarine, paying again
    (BAR(21), BAR(23), 55.0, 1.0),         # 47 of 61
]
T_END = BAR(23)

CAPTIONS = [  # (start, end, headline, sub): copy rules, no dashes, short
    (0.15, BAR(2), "איך משחקים בתור בן גביר?", ""),
    (BAR(2), BAR(4), "בוחרים ראש רשימה", ""),
    (BAR(4), BAR(6), "כל לחיצה = העברה", "של אותה הודעה."),
    (BAR(6), BAR(8), "קונים מקורות", "משלם המסים נאנח. זה נחשב הסכמה."),
    (BAR(8), BAR(10), "עוד מקורות", "הייטקיסט, מע״מ. כולם תורמים."),
    (BAR(10), BAR(13), "אירוע: חסימה", "השר שלך תקוע בפקק."),
    (BAR(13), BAR(15), "משלמים לשותפים", "כולם רוצים תקציב."),
    (BAR(15), BAR(17), "ובן גביר?", "מאיים לפרוש. לפי לוח זמנים."),
    (BAR(17), BAR(19), "מקור חדש: צוללות", "אל תשאלו."),
    (BAR(19), BAR(21), "עוד סבב תשלומים", "מחר: דרישה להגדלה."),
    (BAR(21), BAR(23), "47 מתוך 61", "אז... עוד סבב."),
]

STILLS = [0.3, 1.5, 2.5, 5.4, 6.4, 11.0, 13.5, 16.0, 19.0, 21.0, 24.0, 26.0, 29.0, 31.5, 34.0, 36.5,
          40.0, 42.0, 44.0, 46.5, 48.0, 52.0, 54.5, 57.0, 60.0, 67.9]

PEEKS = [  # (start, length, line, stays): Mordechai David peeks out from behind the phone
    (BAR(8) + 0.5, 1.7, "חוסם.", False),   # a wide-shot bar, so the phone's edge is on screen
    (DUR - 2.6, 2.6, "חוסם.", True),       # on the end card, and on the cover (the last frame)
]


def take_at(t):
    """-> (take time, speed, clip start, take key). A clip's optional 5th field names a take in TAKES
    (a montage cuts between several captures); without it the clip plays the main take."""
    for clip in CLIPS:
        vs, ve, ts, sp = clip[:4]
        if vs <= t < ve:
            return ts + (t - vs) * sp, sp, vs, (clip[4] if len(clip) > 4 else None)
    return None


TAKES = {}                          # key -> take dir, for montage clips (None = the main take)
PLANS = {}                          # key -> that take's plan
_tf = {}


def take_frame(key, tt):
    """The take's frame at tt, cached by (take, index): object ids are never cache keys (v4.1)."""
    d = TAKES.get(key, g.TAKE)
    i = max(0, int(round(tt * FPS)))
    while not os.path.exists(os.path.join(d, "f%08d.png" % i)) and i > 0:
        i -= 1
    kk = (key, i)
    if kk not in _tf:
        if len(_tf) > 16:
            _tf.clear()
        _tf[kk] = Image.open(os.path.join(d, "f%08d.png" % i)).convert("RGBA")
    return _tf[kk], i


# ---------------------------------------------------------------------------- taps (take time, x, y in capture px)
HAT = (575, 760)                    # Ben Gvir's torso: L.magician_hit centre, measured on the take
BUY_X = 170                         # the row's price button (the driver taps the row; a thumb hits the button)
TAB = {3: (405, 2260), 1: (945, 2260)}
PICK = (194, 1836)                  # the Ben Gvir cell on the picker


def build_taps(take, plan_path=None, tap_at=None):
    plan = __import__("json").load(open(plan_path or PLAN))
    tap_at = TAP_AT if tap_at is None else tap_at
    take = os.path.abspath(take)
    log = take.rstrip("/") + ".log"          # <take>.log next to the take folder (takeL -> takeL.log)
    if not os.path.exists(log):
        log = os.path.join(os.path.dirname(take), "take1.log")
    rows, logged = [], {"pay": [], "decline": []}
    if os.path.exists(log):
        for ln in open(log, encoding="utf-8"):
            if ln.startswith("[capture] buy"):
                a = ln.split(": [", 1)[1].split("]", 1)[0].split(",")
                rows.append(float(a[1]))
            for kind in logged:
                if ln.startswith("[capture] %s : [" % kind):
                    a = ln.split(": [", 1)[1].split("]", 1)[0].split(",")
                    logged[kind].append((float(a[0]) * 1.5, float(a[1]) * 1.5))
    rng = random.Random(7)
    taps, bi = [], 0
    for step in plan:
        t, what = step[0], step[1]
        a = step[2] if len(step) > 2 else {}
        if what == "pick":
            taps.append((t, *tap_at.get(t, PICK)))   # the picker shuffles: a reel pins the cell
        elif what == "hat":
            n, rate = int(a.get("n", 1)), float(a.get("rate", 6))
            for i in range(n):
                taps.append((t + i / rate, HAT[0] + rng.uniform(-22, 22), HAT[1] + rng.uniform(-26, 26)))
        elif what == "buy":
            y = rows[bi] * 1.5 if bi < len(rows) else 1488
            bi += 1
            taps.append((t, BUY_X + rng.uniform(-8, 8), y + rng.uniform(-6, 6)))
        elif what == "tab":
            taps.append((t, *TAB[int(a.get("i", 3))]))
        elif what in ("pay", "decline"):
            p = tap_at[t] if t in tap_at else (find_pill(take, t) if what == "pay" else None)
            if p:
                taps.append((t, *p))
    return sorted(taps)


def find_pill(take, t):
    """The first payable pill on screen at t: the driver taps the first enabled one, the topmost."""
    i = int(round(t * FPS))
    im = np.asarray(Image.open(os.path.join(take, "f%08d.png" % i)).convert("RGB")).astype(int)
    r, gg, b = im[..., 0], im[..., 1], im[..., 2]
    m = (r > 215) & (gg > 160) & (gg < 230) & (b < 120)
    m[:250] = False
    m[2140:] = False
    m[:, :250] = False
    m[:, 900:] = False
    cnt = m.sum(1)
    ys = np.where(cnt > 120)[0]
    if not len(ys):
        return None
    y0 = ys[0]
    y1 = y0
    while y1 + 1 < len(cnt) and cnt[y1 + 1] > 120:
        y1 += 1
    xs = np.where(m[y0:y1 + 1].any(0))[0]
    return (float(xs.mean()), float((y0 + y1) / 2))


SUB_DELAY = 0.35                    # the sub line (the punch) lands this long after the headline

TAPS = []
TAPS_BY = {}                        # key -> taps of that montage take
TAP_AT_BY = {}                      # key -> that take's pinned taps
TAP_AT = {}                         # plan time -> (x, y) capture px, for taps a reel pins by hand


def draw_touches(scr, tt, sp, s, oy, key=None):
    """iOS 'show touches': a white disc that presses in and fades, and a ripple ring (the kit's shapes)."""
    gs = s * GW / CAP_W            # capture px -> screen image px
    dia = 0.1 * SW * s
    for t0, x, y in (TAPS_BY[key] if key in TAPS_BY else TAPS):
        age = (tt - t0) / sp       # video seconds since the tap
        if age < -0.01 or age > 0.42:
            continue
        cx, cy = x * gs, oy + y * gs
        pad = int(dia * 1.6)
        box = Image.new("RGBA", (pad * 2 * 3, pad * 2 * 3), (0, 0, 0, 0))
        d = ImageDraw.Draw(box)
        o = pad * 3
        if age < 0.40:
            sc = 1.25 - 0.25 * ease_out(clamp(age / 0.07))
            al = clamp(age / 0.03) * (1 - clamp((age - 0.18) / 0.22))
            rr = dia / 2 * sc * 3
            sh = 3 * 3 * s                  # a soft dark halo, so the disc reads on yellow and white too
            d.ellipse((o - rr - sh, o - rr - sh, o + rr + sh, o + rr + sh), fill=(0, 0, 0, int(70 * al)))
            d.ellipse((o - rr, o - rr, o + rr, o + rr), fill=(235, 235, 240, int(175 * al)),
                      outline=(255, 255, 255, int(250 * al)), width=int(max(3, 4 * s * 3)))
        u = clamp(age / 0.42)
        rr = dia / 2 * (0.6 + 1.1 * ease_out(u)) * 3
        wd = int(max(3, 4 * s * 3 * (1 - 0.5 * u)))
        d.ellipse((o - rr - 3, o - rr - 3, o + rr + 3, o + rr + 3), outline=(0, 0, 0, int(80 * (1 - u))), width=wd + 6)
        d.ellipse((o - rr, o - rr, o + rr, o + rr), outline=(255, 255, 255, int(220 * (1 - u))), width=wd)
        box = box.resize((pad * 2, pad * 2), Image.LANCZOS)
        paste_clip(scr, box, int(cx - pad), int(cy - pad))


def paste_clip(canvas, im, x, y):
    if x >= canvas.width or y >= canvas.height or x + im.width <= 0 or y + im.height <= 0:
        return
    canvas.alpha_composite(im, (max(0, x), max(0, y)), (max(0, -x), max(0, -y)))


# ---------------------------------------------------------------------------- camera
# (time, zoom, focus x, focus y) in capture px; None focus = the wide shot. The camera eases from the
# previous key to this one over the gap; two keys at the same time are a cut.
def cap_to_wide(fx, fy):
    return (C[0] - SW / 2 + fx * GW / CAP_W, C[1] - SH / 2 + SB + fy * GW / CAP_W)


WIDE = (1.0, None)


def cam_keys():
    b = BAR
    K = [
        (0.0, 1.62, 575, 900), (1.25, 1.62, 575, 900), (2.25, 1.0, None, None),          # hook: tight, then reveal
        (b(2), 1.0, None, None), (b(2) + 0.6, 1.0, None, None), (b(2) + 1.3, 1.22, 540, 1500),  # picker: push to cells
        (b(4) - 0.4, 1.22, 540, 1500), (b(4), 1.0, None, None),
        (b(4), 1.0, None, None), (b(6), 1.2, None, None),                                 # first taps: slow creep
        (b(6), 1.0, None, None), (b(6) + 0.9, 1.3, 540, 1560), (b(8), 1.3, 540, 1600),  # buying: onto the shop
        (b(8), 1.0, None, None), (b(9), 1.0, None, None), (b(9) + 0.9, 1.28, 540, 1500), (b(10), 1.28, 540, 1500),
        (b(10), 1.0, None, None), (b(12) + 1.0, 1.0, None, None),
        (b(12) + 1.0, 1.4, 540, 1500), (b(13), 1.4, 540, 1500),                           # the break: on the toast
        (b(13), 1.0, None, None), (b(13) + 1.2, 1.0, None, None), (b(13) + 2.1, 1.3, 540, 1250),  # chat, paying
        (b(17) - 1.2, 1.3, 540, 1250), (b(17) - 0.3, 1.0, None, None),
        (b(17), 1.28, 540, 1650), (b(18), 1.28, 540, 1650), (b(18) + 0.9, 1.0, None, None),  # submarine buys
        (b(19), 1.0, None, None), (b(19) + 0.8, 1.3, 540, 1100), (b(21), 1.3, 540, 1100),   # pay again
        (b(21), 1.0, None, None), (b(21) + 0.9, 1.45, 540, 200), (b(23), 1.5, 540, 200),    # 47 of 61
    ]
    return K


KEYS = []


def cam(t):
    """-> (zoom, focus point in wide canvas coords)."""
    def st(key):
        _t, z, fx, fy = key
        return (z, C) if fx is None else (z, cap_to_wide(fx, fy))   # no focus: a centred zoom
    prev = KEYS[0]
    for key in KEYS:
        if key[0] > t:
            if key[0] - prev[0] <= 1e-6:
                return st(prev)
            u = k.ease_inout(clamp((t - prev[0]) / (key[0] - prev[0])))
            (z0, f0), (z1, f1) = st(prev), st(key)
            z = z0 + (z1 - z0) * u
            return z, (f0[0] + (f1[0] - f0[0]) * u, f0[1] + (f1[1] - f0[1]) * u)
        prev = key
    return st(prev)


def sway(t):
    """A slow handheld drift: no rotation and no bar-line zoom kick, both resample the pixel-art text
    every frame and read as flicker (Bar, v4.1). Kept fractional: the phone's position is rounded once,
    camera + drift together (rounding each apart made it hop a pixel and back, v4.2)."""
    dx = 4 * math.sin(2 * math.pi * t / 4.1)
    dy = 3 * math.sin(2 * math.pi * t / 3.3 + 1.0)
    return dx, dy


# ---------------------------------------------------------------------------- layers
_bg = {}


def background(frame, fi):
    kk = fi                        # the take frame index: object ids are reused once frames are freed
    if kk not in _bg:
        if len(_bg) > 8:
            _bg.clear()
        sm = frame.convert("RGB").resize((72, 156), Image.BILINEAR).filter(ImageFilter.GaussianBlur(2.2))
        big = sm.resize((W, round(W * CAP_H / CAP_W)), Image.BICUBIC)
        y0 = (big.height - H) // 2
        big = big.crop((0, y0, W, y0 + H))
        big = Image.blend(big, Image.new("RGB", (W, H), INK), 0.62).convert("RGBA")
        k.vignette(big)
        _bg[kk] = big
    return _bg[kk].copy()


def screen(frame, fi, tt, sp, s, key=None):
    """The lit screen at scale s: status bar, the game, touches, home indicator, rounded corners."""
    sw, sb = round(SW * s), round(SB * s)
    gh = round(GH * s)
    sh = sb + gh
    scr = Image.new("RGBA", (sw, sh), (0, 0, 0, 255))
    scr.paste(resized("status", STATUS, (sw, sb)), (0, 0))
    scr.paste(resized(("game", fi), frame, (sw, gh)), (0, sb))
    draw_touches(scr, tt, sp, s, sb, key)
    d = ImageDraw.Draw(scr)
    hw, hh = 134 / 393 * sw, 5 / 393 * sw
    hy = sh - 5 / 393 * sw
    over = Image.new("RGBA", scr.size, (0, 0, 0, 0))
    ImageDraw.Draw(over).rounded_rectangle((sw / 2 - hw / 2, hy - hh, sw / 2 + hw / 2, hy), radius=hh / 2,
                                           fill=(255, 255, 255, 130))
    scr.alpha_composite(over)
    del d
    scr.alpha_composite(resized("glare", GLARE, (sw, sh)))
    scr.putalpha(resized("mask", MASK, (sw, sh)))
    return scr


def phone(frame, fi, tt, sp, s, key=None):
    body = resized("chrome", CHROME, (round((PW + 2 * MARGIN) * s), round(PH * s))).copy()
    scr = screen(frame, fi, tt, sp, s, key)
    body.alpha_composite(scr, (round((MARGIN + BZ) * s), round(BZ * s)))
    return body


def peek(c, t, edge_x, s):
    """The easter egg: he leans out from behind the phone's left edge, says one word, and ducks back."""
    for t0, ln, line, stays in PEEKS:
        u = t - t0
        if not 0 <= u < ln:
            continue
        out = ease_out(clamp(u / 0.25)) if stays else min(ease_out(u / 0.25), ease_out((ln - u) / 0.25))
        fr, anc = md_frame("block" if u > 0.35 else "block_in", max(0.0, u - 0.35) if u > 0.35 else u, 2)
        x = edge_x + 40 - out * fr.width * 0.62
        y = 1180
        paste(c, fr, x, y, "tl")
        if u > 0.3 and (stays or ln - u > 0.25):
            b = k.bubble(line, 5)
            paste(c, b, max(b.width // 2 + 20, x + fr.width * 0.3), y - 70)


def captions(c, t):
    for s0, e, head, sub in CAPTIONS:
        if s0 <= t < e:
            sc = pop_scale(t, s0, 0.14, 1.3)
            him = text(head, 8, grad=True)
            sim = text(sub, 6) if sub else None
            w = max(him.width, sim.width if sim else 0) + 70
            show = sim is not None and t - s0 > SUB_DELAY    # the plate grows when the punch lands
            h = him.height + (sim.height + 14 if show else 0) + 36
            y = 118
            paste(c, scaled(plate(w, h, NIGHT, INK, 6), sc), W // 2, y + h // 2 - 20)
            paste(c, scaled(him, sc), W // 2, y + him.height // 2 - 2)
            if show:
                paste(c, sim, W // 2, y + him.height + 10 + sim.height // 2)


def game_frame(t):
    tt, sp, vs, key = take_at(t)
    fr, i = take_frame(key, tt)
    fi = (key, i)                  # cache key for the resized frame and the blurred backdrop
    c = background(fr, fi)
    z, f = cam(t)
    dx, dy = sway(t)
    s = z
    cx = C[0] + (C[0] - f[0]) * z + dx
    cy = C[1] + (C[1] - f[1]) * z + dy
    sh_im, pad = SHADOW
    shs = resized("shadow", sh_im, (round(sh_im.width / 0.5 * s), round(sh_im.height / 0.5 * s)), Image.BILINEAR)
    paste(c, shs, cx + 10 * s, cy + 34 * s)
    edge = cx - PW * s / 2
    peek(c, t, edge, s)
    paste(c, phone(fr, fi, tt, sp, s, key), cx, cy)
    flash(c, t, vs, 0.07, 0.3)
    captions(c, t)
    return c


def end_default(c, t):
    g.end_card(c, t)
    peek_end(c, t)


END = end_default


def frame(t):
    if t < T_END:
        c = game_frame(t)
    else:
        c = Image.new("RGBA", (W, H), INK + (255,))
        END(c, t)
    return c.convert("RGB")


def peek_end(c, t):
    """On the end card there is no phone: he peeks from the bottom-left corner, as in v2/v3."""
    for t0, ln, line, stays in PEEKS:
        u = t - t0
        if not 0 <= u < ln or t < T_END:
            continue
        rise = ease_out(clamp(u / 0.25)) if stays else min(ease_out(u / 0.25), ease_out((ln - u) / 0.25))
        fr, anc = md_frame("block" if u > 0.35 else "block_in", max(0.0, u - 0.35) if u > 0.35 else u, 2)
        y = H - int(rise * 330)
        paste(c, fr, 150 - anc[0] * 2, y, "tl")
        if u > 0.3:
            paste(c, k.bubble(line, 5), 250, y - 200)


def main():
    global CHROME, MASK, STATUS, GLARE, SHADOW, TAPS, KEYS
    take = sys.argv[1]
    g.TAKE = take
    CHROME, MASK, STATUS, GLARE = build_chrome(), build_mask(), build_status(), build_glare()
    SHADOW = build_shadow()
    TAPS = build_taps(take)
    for kk, d in TAKES.items():
        TAPS_BY[kk] = build_taps(d, PLANS[kk], TAP_AT_BY.get(kk, {}))
    KEYS = cam_keys()
    g.T_END = T_END
    if "--stills" in sys.argv:
        ts = STILLS
        k.frame = frame
        k.OUT = OUT
        k.stills(ts, os.path.join(OUT, "_stills.png"))
        os.replace(os.path.join(OUT, "_stills.png"), os.path.join(OUT, "_stills_%s.png" % NAME))
        return
    if "--one" in sys.argv:
        t = float(sys.argv[sys.argv.index("--one") + 1])
        frame(t).save(os.path.join(OUT, "_stills_one.png"))
        return
    video = os.path.join(OUT, NAME + ".mp4")
    cmd = [k.ffmpeg(), "-y", "-loglevel", "error",
           "-f", "rawvideo", "-pix_fmt", "rgb24", "-s", f"{W}x{H}", "-r", str(FPS), "-i", "-",
           "-ss", str(MUSIC_AT), "-i", MUSIC,
           "-map", "0:v", "-map", "1:a",
           "-c:v", "libx264", "-preset", "slow", "-crf", "17", "-pix_fmt", "yuv420p", "-profile:v", "high",
           "-movflags", "+faststart", "-af", f"afade=t=out:st={DUR - 0.4}:d=0.4,loudnorm=I=-14:TP=-1.0:LRA=11",
           "-c:a", "aac", "-b:a", "192k", "-ar", "48000", "-t", str(DUR), video]
    p = subprocess.Popen(cmd, stdin=subprocess.PIPE)
    nf = int(DUR * FPS)
    cover = frame((nf - 1) / FPS)
    cover.save(os.path.join(OUT, NAME + "-cover.png"))
    for i in range(nf):
        p.stdin.write((cover if i < 2 else frame(i / FPS)).tobytes())
        if i % 300 == 0:
            print(f"frame {i}/{nf}", flush=True)
    p.stdin.close()
    if p.wait() != 0:
        raise SystemExit("ffmpeg failed")
    print(video)


if __name__ == "__main__":
    main()
