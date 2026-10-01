"""'עוד סבב': "ערוצי התבהלה נגד מכונת הרעל", one evening zapped across 12, 13 and 14 (Reels, 9:16).

Each camp's insult, worn as the channel's own style. "ערוצי התבהלה" (panic channels) is what 14's
panel calls 12 and 13 (Yinon Magal made it a catchphrase; Netanyahu added "תבהלה 12", and "התבהלה
והתרעלה"); "מכונת הרעל" is what the other camp calls Netanyahu's spin network, 14 included. Amit Segal
once answered: "כולנו ערוצי תבהלה", "תבהלה 14" too. So 12 and 13 run a panic meter, 14 runs a poison
meter, and both are the same parrot (sources in store/promo/README.md).

Research, Oct 2026 (sources in store/promo/README.md): nearly every Israeli newscast is red now; 12 has
the red-white studio with blue behind its rhomboid logo and the Friday panel of commentators; 13 has
the navy set with two big square screens and the investigative "חשיפה" brand; 14's rebrand was called
suspiciously similar to 12's, with a red square logo, flag and blue-gold "patriot" panel. Each camp
calls the other's channel "מכונת הרעל" or "ערוץ תעמולה". So: the same three game events (the hat,
Liberman won't sit, the Knesset dissolves) on all three channels, each in its own spin, with a remote
and a TV's green channel number between them. Every anchor is Dubi, the game's parrot, which is the
reveal: three channels, one parrot. The channels' looks are evoked (colours, shapes, numbers), never
their real logos, shows or anchors. Copy held to creative-pack/voice/review-rubric.md: the events are
the game's own and plainly absurd, all three channels roasted alike, no polls.

    python3 store/promo/src/zap.py <scratch with take_<leader>/, takeL/> [--stills | --one <sec>]
"""
import os
import subprocess
import sys

import numpy as np
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import promo as P  # noqa: E402
import teaser as k  # noqa: E402
from teaser import (INK, NIGHT, GOLD, GOLD_HI, GOLD_SH, WHITE, RED, W, H, FPS, img, paste, scaled, text,  # noqa: E402
                    plate, bubble, badge, slam, flash, pop_scale, clamp, ease_out, char_frame, coins_burst,
                    vignette, spotlight, rnd)

OUT = P.OUT
SR = P.SR

# ---------------------------------------------------------------------------- the channels' looks
R12, R12D, B12 = (200, 22, 34), (120, 6, 12), (28, 70, 170)
N13, N13B, R13 = (6, 8, 70), (4, 32, 108), (222, 36, 46)
R14, R14D, B14, G14 = (204, 26, 32), (116, 8, 14), (18, 46, 130), (236, 192, 72)
OSD = (90, 255, 110)

BAR = 4 * 60 / 122.54              # Bar's track (store/gameplay/music/panic-vs-poison.wav), 122.5 BPM
M0 = 0.055                         # its first downbeat; video 0 sits on it, every zap on a bar line
HOOK = 2 * BAR
SEG = 2 * BAR                      # 3.92 s a story
L2_AT = 1.15
STORIES = [  # (channel, event, tag, line 1, line 2, meter from, meter to), zapped 12 -> 13 -> 14 per event
    (12, "hat", "ערב גורלי", "הקוסם שלף 61 מכובע ריק.", "פרשננו: הרגע הכי מסוכן. מאז אתמול.", 62, 91),
    (13, "hat", "חשיפה", "חשיפה: מה באמת יש בכובע.", "ארנב. הוא סירב להגיב.", 70, 88),
    (14, "hat", "הישג היסטורי", "הקוסם שלף 61. הישג היסטורי.", "הפאנל: כולם מסכימים. בצעקות.", 80, 96),
    (12, "chair", "חשש כבד", "ליברמן הודיע: לא יושב.", "14 פרשנים. 15 תרחישי אימה.", 91, 99),
    (13, "chair", "תחקיר", "תחקיר: הכיסא של ליברמן.", "חצי שנה מעקב. הוא עדיין ריק.", 88, 97),
    (14, "chair", "דחוף", "ליברמן לא יושב.", "פרשננו: אשמת ערוצי התבהלה.", 96, 100),
    (12, "vote", "מבזק", "הכנסת התפזרה. שוב.", "מד התבהלה שבר שיא. גם זה שוב.", 99, 100),
    (13, "vote", "בלעדי", "בלעדי ל־13: יש בחירות.", "המקורות: כל המדינה.", 97, 100),
    (14, "vote", "ניצחון", "הכנסת התפזרה. ניצחון ענק.", "על מי? נעדכן.", 100, 100),
]
T_F1 = HOOK + SEG * len(STORIES)    # 39.2: three TVs, one parrot
T_F2 = T_F1 + 1.5 * BAR             # the poison machine
T_END = T_F2 + 1.5 * BAR
DUR = T_END + 2 * BAR               # 49.0

TICKER = {
    12: "לפי ערוץ 12: ערוץ 14 הוא מכונת רעל  ·  הישארו איתנו. מפחיד פה  ·  אחרי הפרסומות: עוד פחד  ·  ",
    13: "לפי ערוץ 13: יש מכונת רעל. הפרטים בהמשך  ·  בהמשך: חשיפה. אחריה: חשיפה על החשיפה  ·  ",
    14: "לפי ערוץ 14: ערוצים 12 ו־13 הם ערוצי תבהלה  ·  מד הרעל: 0%. כמו תמיד  ·  כל הפאנל מסכים  ·  ",
}

Y_LT = 1262                         # the lower third's top
Y_TK = 1462                         # the ticker
Y_TV = 1600                         # the broadcast ends here; the living room and the remote below


def seg_at(t):
    i = int((t - HOOK) // SEG)
    if t < HOOK or i >= len(STORIES):
        return None, None
    return i, t - HOOK - i * SEG


# ---------------------------------------------------------------------------- shared pieces

_c = {}


def grad(top, bot, h=Y_TV):
    key = ("g", top, bot, h)
    if key not in _c:
        g = Image.new("RGBA", (1, 64))
        for y in range(64):
            u = y / 63
            g.putpixel((0, y), tuple(int(top[j] + (bot[j] - top[j]) * u) for j in range(3)) + (255,))
        _c[key] = g.resize((W, h), Image.BILINEAR)
    return _c[key]


def bug(ch, s=1.0):
    """The corner logo, evoked: 12 a white numeral on a red rhomboid over blue; 13 red with a double
    rule; 14 a red square with a little flag."""
    key = ("bug", ch)
    if key not in _c:
        if ch == 12:
            im = Image.new("RGBA", (230, 120), (0, 0, 0, 0))
            d = ImageDraw.Draw(im)
            d.polygon([(40, 6), (226, 6), (190, 114), (4, 114)], fill=B12)
            d.polygon([(34, 0), (206, 0), (172, 104), (0, 104)], fill=R12)
            d.polygon([(34, 0), (206, 0), (200, 18), (28, 18)], fill=(236, 70, 80))
            n = text("12", 9, ring=None, shadow=False, rtl=False)
            im.alpha_composite(n, (103 - n.width // 2, 52 - n.height // 2))
        elif ch == 13:
            im = Image.new("RGBA", (190, 132), (0, 0, 0, 0))
            d = ImageDraw.Draw(im)
            d.rectangle((0, 0, 189, 99), fill=R13)
            n = text("13", 9, ring=None, shadow=False, rtl=False)
            im.alpha_composite(n, (95 - n.width // 2, 50 - n.height // 2))
            d.rectangle((0, 108, 189, 115), fill=R13)
            d.rectangle((0, 124, 189, 131), fill=R13)
        else:
            im = Image.new("RGBA", (232, 120), (0, 0, 0, 0))
            d = ImageDraw.Draw(im)
            d.rectangle((0, 0, 119, 119), fill=R14)
            d.rectangle((0, 0, 119, 9), fill=G14)
            n = text("14", 9, ring=None, shadow=False, rtl=False)
            im.alpha_composite(n, (60 - n.width // 2, 62 - n.height // 2))
            d.rectangle((134, 20, 231, 89), fill=WHITE)              # the flag
            d.rectangle((134, 28, 231, 35), fill=B14)
            d.rectangle((134, 74, 231, 81), fill=B14)
            cx, cy = 182, 55
            d.polygon([(cx, cy - 15), (cx + 13, cy + 8), (cx - 13, cy + 8)], outline=B14, width=3)
            d.polygon([(cx, cy + 15), (cx + 13, cy - 8), (cx - 13, cy - 8)], outline=B14, width=3)
        _c[key] = im
    return scaled(_c[key], s) if s != 1.0 else _c[key]


def framed(c, im, x, y, rim, w=10):
    d = ImageDraw.Draw(c)
    d.rectangle((x - w, y - w, x + im.width + w - 1, y + im.height + w - 1), fill=rim)
    c.alpha_composite(im, (x, y))


def shot(who, t, size, box=(0, 330, 1080, 1050)):
    return P.stage_shot(who, t, size, box)


def footage(ev, u, size):
    """The event on the wall, from the real captures."""
    if ev == "hat":
        return shot("bibi", 7.0 + (u * 0.6) % 1.4, size)
    if ev == "chair":
        return shot("liberman", 5.0 + min(u, 1.2) * 0.5, size)
    h = round(1080 * size[1] / size[0])                           # the dissolve card, centred at y 1382
    return shot("golan", 21.25, size, (0, 1382 - h // 2, 1080, 1382 + h // 2))


def anchor(c, x, y, u, talking, scale=2):
    """Dubi at the desk: idle, or talking while his line is read."""
    anim = "talk" if talking else "idle"
    a = k.SPRITES["chars"]["dubi-mic"]["anims"][anim]
    fr, anc = char_frame("dubi-mic", anim, int(u * a["fps"]) % a["frames"], scale)
    paste(c, fr, x - anc[0] * scale, y - anc[1] * scale, "tl")


def ticker(c, ch, t, band, ink):
    d = ImageDraw.Draw(c)
    d.rectangle((0, Y_TK, W, Y_TK + 54), fill=band)
    s = text(TICKER[ch] * 2, 4, fill=ink, ring=None, shadow=False)
    x = -s.width // 2 + (t * 170) % (s.width // 2)          # Hebrew crawls left to right
    paste(c, s, x, Y_TK + 5, "tl")


def lower_third(c, u, ch, tag, l1, l2):
    """Each channel's own bar; the tag on the right (RTL), line 1 then the punch."""
    wipe = ease_out(clamp((u - 0.15) / 0.2))
    if wipe <= 0:
        return
    d = ImageDraw.Draw(c)
    xr = W - 24
    wdt = int((W - 48) * wipe)
    if ch == 12:
        bar, top, f1, f2, tagc, tagr = WHITE, R12, INK, R12, R12, INK
    elif ch == 13:
        bar, top, f1, f2, tagc, tagr = N13, R13, WHITE, (200, 214, 255), R13, INK
    else:
        bar, top, f1, f2, tagc, tagr = R14D, G14, WHITE, G14, B14, G14
    d.rectangle((xr - wdt, Y_LT, xr, Y_LT + 180), fill=bar)
    d.rectangle((xr - wdt, Y_LT, xr, Y_LT + 9), fill=top)
    if ch == 13:
        d.rectangle((xr - wdt, Y_LT + 15, xr, Y_LT + 19), fill=top)
    if ch == 12:
        d.polygon([(xr - wdt, Y_LT + 180), (xr - wdt + 40, Y_LT + 180), (xr - wdt + 16, Y_LT + 120), (xr - wdt, Y_LT + 120)], fill=B12)
    tg = text(tag, 6)
    tw = tg.width + 44
    paste(c, plate(tw, 76, tagc, tagr, 5), xr - tw // 2, Y_LT - 30)
    paste(c, tg, xr - tw // 2, Y_LT - 30)
    if u > 0.3:
        a = text(l1, 6, fill=f1, ring=None if ch == 12 else INK, shadow=ch != 12)
        paste(c, scaled(a, pop_scale(u, 0.3, 0.1, 1.08)), xr - 26 - a.width // 2, Y_LT + 62)
    if u > L2_AT:
        b = text(l2, 6, fill=f2, ring=None if ch == 12 else INK, shadow=ch != 12)
        paste(c, scaled(b, pop_scale(u, L2_AT, 0.12, 1.15)), xr - 26 - b.width // 2, Y_LT + 132)


def meter(c, ch, u, lo, hi):
    """12 and 13 run a panic meter; 14 a poison meter. It climbs to the punch line."""
    poison = ch == 14
    v = lo + (hi - lo) * ease_out(clamp((u - 0.3) / (L2_AT + 0.3)))
    x0, y0, n = 330, 228, 10
    lab = text("מד רעל" if poison else "מד תבהלה", 4, fill=WHITE)
    paste(c, lab, x0 + 470 - lab.width, y0 - 50, "tl")
    d = ImageDraw.Draw(c)
    d.rectangle((x0 - 6, y0 - 6, x0 + 476, y0 + 46), fill=INK)
    lit = int(round(v / 100 * n))
    full = (90, 255, 60) if poison else (255, 60, 40)
    for j in range(n):                                           # RTL: it fills from the right
        x = x0 + 470 - (j + 1) * 47
        on = j < lit
        col = full if on else (40, 40, 52)
        if on and j >= n - 2 and int(u * 8) % 2:
            col = WHITE
        d.rectangle((x + 4, y0, x + 44, y0 + 40), fill=col)
    if u >= 1.2:                                                 # after the TV's channel number has gone
        pc = text("%d%%" % round(v), 6, fill=full if v < 100 or int(u * 8) % 2 else WHITE, rtl=False)
        paste(c, pc, x0 + 540 + pc.width // 2, y0 + 20)


def osd(c, ch, u):
    """The TV's own channel number, green, top right, for a second after each zap."""
    if 0.08 <= u < 1.2:
        n = text(str(ch), 13, fill=OSD, ring=(10, 40, 10), shadow=True, rtl=False)
        paste(c, n, W - 70 - n.width // 2, 250)


def static(c, u, dur=0.14):
    if u >= dur:
        return
    r = np.random.default_rng(int(u * 1000) + 7)
    n = r.integers(0, 255, (Y_TV // 6, W // 6), dtype=np.uint8)
    im = Image.fromarray(n, "L").resize((W, Y_TV), Image.NEAREST).convert("RGBA")
    c.alpha_composite(im, (0, 0))


def live_strip(c, ch):
    """The broadcast's bottom edge: the clock and LIVE."""
    d = ImageDraw.Draw(c)
    band = {12: B12, 13: N13B, 14: B14}[ch]
    d.rectangle((0, Y_TK + 54, W, Y_TV), fill=band)
    paste(c, text("20:00", 5, rtl=False), 110, Y_TK + 54 + (Y_TV - Y_TK - 54) // 2)
    lv = text("שידור חי", 5)
    paste(c, plate(lv.width + 30, 54, RED, INK, 4), W - 40 - (lv.width + 30) // 2, Y_TK + 54 + (Y_TV - Y_TK - 54) // 2)
    paste(c, lv, W - 40 - (lv.width + 30) // 2, Y_TK + 54 + (Y_TV - Y_TK - 54) // 2)


# ---------------------------------------------------------------------------- 12: the big studio

def set12(c, t, u, ev, talk):
    c.alpha_composite(grad((14, 20, 60), (40, 12, 30)))
    d = ImageDraw.Draw(c)
    for j in range(6):                                           # red and white rhomboid bands
        x = (j * 260 + t * 30) % (W + 520) - 260
        d.polygon([(x, 330), (x + 90, 330), (x + 10, 1250), (x - 80, 1250)], fill=(150, 18, 30) if j % 2 else (70, 20, 40))
    spotlight(c, 540, 0, 1250, 60, 520, 0.12, (255, 200, 200))
    if ev == "chair":                                            # the panel: a wall of commentators
        n = 12 if u < L2_AT else 14
        for i in range(n):
            col, row = i % 4, i // 4
            x, y = 60 + col * 245, 340 + row * 200
            if row > 2:
                x, y = 60 + (i - 12) * 245 + 245, 340 + 3 * 200
            if i < 12 or u > L2_AT:
                d.rectangle((x, y, x + 220, y + 180), fill=WHITE if (i + row) % 2 else R12)
                d.rectangle((x + 8, y + 8, x + 212, y + 172), fill=(30, 40, 90))
                bob = int(4 * ((int(u * 8) + i) % 2))
                paste(c, img("avatar_dubi", 4), x + 110, y + 96 - bob)
        cnt = text("פרשנים: %d" % n, 5, fill=WHITE)
        paste(c, plate(cnt.width + 40, 60, R12, INK, 4), 540, 1060 if n == 12 else 1060)
        paste(c, cnt, 540, 1060)
        return
    wall = footage(ev, u, (720, 450))
    m = Image.new("L", wall.size, 0)
    ImageDraw.Draw(m).polygon([(40, 0), (720, 0), (680, 450), (0, 450)], fill=255)
    rim = Image.new("RGBA", (744, 474), (0, 0, 0, 0))
    ImageDraw.Draw(rim).polygon([(46, 0), (744, 0), (698, 474), (0, 474)], fill=WHITE)
    c.alpha_composite(rim, (28, 368))
    c.paste(wall, (40, 380), m)
    anchor(c, 880, 1150, u, talk)
    d.rectangle((560, 1030, W, 1200), fill=R12)                  # the desk
    d.rectangle((560, 1030, W, 1042), fill=WHITE)
    d.polygon([(560, 1030), (600, 1030), (560, 1200)], fill=B12)
    paste(c, bug(12, 0.6), 860, 1120)


# ---------------------------------------------------------------------------- 13: the investigation

def pixelated(im, block):
    sw, sh = max(1, im.width // block), max(1, im.height // block)
    return im.resize((sw, sh), Image.BILINEAR).resize(im.size, Image.NEAREST)


def set13(c, t, u, ev, talk):
    c.alpha_composite(grad(N13, N13B))
    d = ImageDraw.Draw(c)
    for j in range(5):
        d.rectangle((0, 340 + j * 180, W, 342 + j * 180), fill=(20, 40, 120))
    join = ev != "hat"                                           # the two squares join into one
    if not join:
        for i, x in enumerate((60, 560)):
            d.rectangle((x - 8, 352, x + 468, 828), fill=R13)
            d.rectangle((x - 2, 358, x + 462, 822), fill=N13)
            d.rectangle((x - 8, 836, x + 468, 840), fill=R13)
        # left: the rabbit, identity protected; right: the document, redacted
        sc = Image.new("RGBA", (460, 460), (30, 34, 60, 255))
        rab = img("prop_rabbit", 9)
        sc.alpha_composite(rab, (230 - rab.width // 2, 260 - rab.height // 2))
        sc = pixelated(sc, 26 if u > 0.4 else 3)
        c.alpha_composite(sc, (60, 360))
        lab = text("הארנב. פניו טושטשו.", 4)
        paste(c, plate(lab.width + 24, 46, INK, INK, 3), 290, 395)
        paste(c, lab, 290, 395)
        doc = Image.new("RGBA", (380, 420), (238, 232, 214, 255))
        dd = ImageDraw.Draw(doc)
        for j in range(9):
            w = 300 if j % 3 else 200
            dd.rectangle((40, 50 + j * 38, 40 + w, 66 + j * 38), fill=(20, 20, 20) if j % 2 else (120, 120, 120))
        c.alpha_composite(doc.rotate(4, resample=Image.NEAREST, expand=True), (590, 375))
        if u > 0.5:
            slam(c, k.stamp_img("סודי", 8), u, 0.5, 780, 600, angle=-12, frm=2.2)
    else:
        d.rectangle((52, 352, 1028, 888), fill=R13)
        d.rectangle((58, 358, 1022, 882), fill=N13)
        if ev == "chair":                                        # a CCTV feed of an empty chair
            sc = Image.new("RGBA", (960, 520), (34, 44, 38, 255))
            sd = ImageDraw.Draw(sc)
            sd.rectangle((0, 380, 960, 520), fill=(44, 56, 48))
            ch = (90, 110, 96)
            sd.rectangle((400, 180, 560, 200), fill=ch)          # the back
            sd.rectangle((400, 180, 420, 330), fill=ch)
            sd.rectangle((540, 180, 560, 330), fill=ch)
            sd.rectangle((380, 320, 580, 345), fill=ch)          # the seat
            for x in (390, 560):
                sd.rectangle((x, 345, x + 18, 440), fill=ch)
            for y in range(0, 520, 4):
                sd.line((0, y, 960, y), fill=(0, 0, 0, 40))
            c.alpha_composite(sc, (60, 360))
            if int(u * 3) % 2 == 0:
                d.ellipse((92, 390, 122, 420), fill=(255, 40, 40))
            paste(c, text("REC", 5, fill=WHITE, rtl=False), 180, 405)
            day = 1 + int(min(1.0, u / 2.6) * 182)
            dl = text("יום %d" % day, 5, fill=WHITE)
            paste(c, dl, 900, 405)
        else:                                                    # the exclusive: a sheet and a stamp
            doc = Image.new("RGBA", (620, 440), (238, 232, 214, 255))
            dd = ImageDraw.Draw(doc)
            ln = text("יש בחירות.", 8, fill=INK, ring=None, shadow=False)
            doc.alpha_composite(ln, (310 - ln.width // 2, 80))
            for j in range(4):
                dd.rectangle((70, 260 + j * 36, 550 - j * 60, 276 + j * 36), fill=(150, 150, 150))
            c.alpha_composite(doc, (120, 400))
            if u > 0.55:
                slam(c, k.stamp_img("בלעדי", 11), u, 0.55, 470, 740, angle=-10, frm=2.4)
    d.rectangle((0, 1080, W, 1250), fill=(10, 14, 50))           # the desk
    d.rectangle((0, 1080, W, 1086), fill=R13)
    d.rectangle((0, 1094, W, 1098), fill=R13)
    anchor(c, 540 if ev == "hat" else 880, 1200, u, talk)


# ---------------------------------------------------------------------------- 14: the panel

def set14(c, t, u, ev, talk):
    c.alpha_composite(grad((40, 12, 30), (14, 20, 60)))
    d = ImageDraw.Draw(c)
    for j in range(6):                                           # the same red bands. almost.
        x = (j * 260 - t * 30) % (W + 520) - 260
        d.polygon([(x, 330), (x + 90, 330), (x + 10, 1250), (x - 80, 1250)], fill=(150, 18, 30) if j % 2 else (60, 30, 70))
    d.rectangle((0, 330, W, 338), fill=G14)
    wall = footage(ev, u, (640, 400))
    framed(c, wall, 220, 380, G14, 10)
    if ev == "chair" and u > L2_AT:                              # the culprit, found
        paste(c, bug(12, 0.8), 330, 640)
        paste(c, bug(13, 0.8), 330, 770)
        slam(c, k.stamp_img("אשמים", 7), u, L2_AT + 0.15, 330, 705, angle=-14, frm=2.2)
    if ev == "vote":
        coins_burst(c, u, 0.4, 540, 560, n=30, seed=14, life=1.6, kinds=("coin", "bill"))
    d.rectangle((0, 1040, W, 1250), fill=B14)                    # the long desk
    d.rectangle((0, 1040, W, 1050), fill=G14)
    for i in range(5):
        x = 120 + i * 210
        loud = talk or (ev == "hat" and u > L2_AT)
        anchor(c, x, 1150, u + i * 0.13, loud and (int(u * 6) + i) % 3 != 0, scale=1)
        if ev == "hat" and u > L2_AT + 0.1 + i * 0.12:
            paste(c, scaled(bubble("נכון!", 4), pop_scale(u, L2_AT + 0.1 + i * 0.12, 0.1, 1.5)), x, 850 + (i % 2) * 40)
    if ev == "hat" and 0.35 <= u < 1.7:                         # the first zap onto 14
        b = bubble("רגע, זה לא 12?", 5, tail=None)
        paste(c, b, 640, 345)


# ---------------------------------------------------------------------------- frames

SETS = {12: set12, 13: set13, 14: set14}
LOOK = {12: ((28, 60, 150), WHITE), 13: (WHITE, N13), 14: (B14, G14)}


def broadcast(c, t, i, u):
    ch, ev, tag, l1, l2, lo, hi = STORIES[i]
    talk = L2_AT <= u < L2_AT + 1.0
    SETS[ch](c, t, u, ev, talk)
    paste(c, bug(ch), 70 + bug(ch).width // 2, 260)
    meter(c, ch, u, lo, hi)
    lower_third(c, u, ch, tag, l1, l2)
    ticker(c, ch, t, *LOOK[ch])
    live_strip(c, ch)
    osd(c, ch, u)
    static(c, u)


def room(c, t, press=None, pu=9.0):
    """Below the broadcast: the living room and the remote; the pressed button lights."""
    d = ImageDraw.Draw(c)
    d.rectangle((0, Y_TV, W, H), fill=(14, 12, 22))
    d.rectangle((0, Y_TV, W, Y_TV + 12), fill=(40, 38, 50))     # the TV's bezel edge
    x0, y0 = 340, Y_TV + 70
    d.rounded_rectangle((x0, y0, x0 + 400, y0 + 340), radius=40, fill=(46, 46, 54))
    d.rounded_rectangle((x0 + 8, y0 + 8, x0 + 392, y0 + 332), radius=34, fill=(30, 30, 36))
    d.ellipse((x0 + 185, y0 + 22, x0 + 215, y0 + 52), fill=(200, 40, 40) if press is not None and pu < 0.25 else (90, 20, 20))
    for j, ch in enumerate((12, 13, 14)):
        bx = x0 + 300 - j * 110                                  # RTL: 12 on the right
        on = press == ch and pu < 0.35
        dy = 6 if on else 0
        d.rounded_rectangle((bx - 44, y0 + 80 + dy, bx + 44, y0 + 150 + dy), radius=14, fill=GOLD if on else (70, 70, 82))
        n = text(str(ch), 5, fill=INK if on else WHITE, ring=None, shadow=False, rtl=False)
        paste(c, n, bx, y0 + 115 + dy)


PANIC, TOXIC = (255, 92, 64), (120, 255, 80)


def s_hook(c, t):
    """The bill: ערוצי התבהלה, נגד, מכונת הרעל. Each side under the other side's name for it."""
    c.alpha_composite(grad((50, 10, 20), (8, 10, 30), 800), (0, 0))
    c.alpha_composite(grad((8, 10, 30), (10, 44, 20), Y_TV - 800), (0, 800))
    if t < 0.3:                                                  # the CRT switching on
        d = ImageDraw.Draw(c)
        h = int(6 + 1200 * ease_out(t / 0.3) ** 3)
        d.rectangle((0, Y_TV // 2 - h // 2, W, Y_TV // 2 + h // 2), fill=(230, 236, 255))
        return
    if t >= 0.35:
        paste(c, scaled(text("ערוצי התבהלה", 10, fill=PANIC), pop_scale(t, 0.35, 0.14, 1.4)), W // 2, 400)
    for j, ch in enumerate((12, 13)):
        t0 = 0.6 + j * 0.15
        if t >= t0:
            paste(c, scaled(bug(ch, 1.2), pop_scale(t, t0, 0.14, 1.6)), W // 2 + 170 - j * 340, 590)
    if t >= 1.1:
        slam(c, badge("נגד", 13), t, 1.1, W // 2, 820, angle=-4, frm=2.8)
    if t >= 1.5:
        paste(c, scaled(text("מכונת הרעל", 10, fill=TOXIC), pop_scale(t, 1.5, 0.14, 1.4)), W // 2, 1040)
    if t >= 1.8:
        paste(c, scaled(bug(14, 1.2), pop_scale(t, 1.8, 0.14, 1.6)), W // 2, 1230)
    if t >= 2.5:
        paste(c, text("הערב, בשידור חי.", 7, fill=WHITE), W // 2, 1450)
    flash(c, t, 0.3, 0.1, 0.8)
    flash(c, t, 1.1, 0.1, 0.5)


def mini_tv(i, t):
    """A whole broadcast, shrunk into a little TV (for the reveal)."""
    c = Image.new("RGBA", (W, H), INK + (255,))
    broadcast(c, t, i, 2.2)
    return c.crop((0, 200, W, Y_TV)).resize((330, 428), Image.NEAREST)


def s_reveal(c, t):
    u = t - T_F1
    c.alpha_composite(grad((8, 10, 30), (20, 26, 70)))
    for j, i in enumerate((0, 1, 2)):
        x = W - 190 - j * 350
        tv = mini_tv(i, t)
        framed(c, tv, x - 165, 420, (40, 38, 50), 14)
    if u > 0.1:
        paste(c, text("תבהלה? רעל?", 9, grad=True), W // 2, 290)
    if u > 0.8:
        anchor(c, W // 2, 1700, u, int(u * 6) % 2 == 0, scale=2)
        slam(c, text("תוכי אחד.", 11, fill=WHITE), u, 0.8, W // 2, 990, frm=2.2)
    flash(c, u, 0, 0.1, 0.6)


def s_machine(c, t):
    u = t - T_F2
    c.alpha_composite(grad((10, 8, 24), (34, 14, 40)))
    spotlight(c, W // 2, 0, 1500, 80, 600, 0.16, (255, 120, 120))
    caption = text("ומכונת הרעל?", 9, grad=True)
    paste(c, caption, W // 2, 320)
    fr = int(u * 2.5) % 2
    sheet = img("source_poison", 5)
    rack = sheet.crop((fr * 92 * 5, 0, fr * 92 * 5 + 92 * 5, 120 * 5))
    s = pop_scale(u, 0.15, 0.18, 0.3)
    if s:
        paste(c, scaled(rack, s), W // 2, 900)
    if u > 0.9:
        paste(c, text("במשחק יש לך אחת משלך.", 8), W // 2, 1300)
    if u > 1.4:
        paste(c, text("10,000 חשבונות. דעה אחת.", 6, fill=GOLD_HI), W // 2, 1410)
    flash(c, u, 0, 0.1, 0.6)


def s_end(c, tt):
    k.curtain(c, 0, dim=0.15)
    spotlight(c, W // 2, 0, 1400, 90, 480, 0.2, GOLD_HI)
    vignette(c)
    coins_burst(c, tt, 0, W // 2, 760, n=50, seed=12, life=2.0, kinds=("coin", "coin", "slip", "bill"))
    s = pop_scale(tt, 0, 0.18, 0.2)
    if s:
        paste(c, scaled(img("wordmark", 6), s), W // 2, 330)
    if tt >= 0.3:
        paste(c, text("כל הערוצים. משחק אחד.", 8), W // 2, 540)
    if tt >= 0.8:
        slam(c, badge("בקרוב"), tt, 0.8, W // 2, 790, angle=-4, frm=2.4)
    if tt >= 1.3:
        h = text("@od.sevev", 8)
        paste(c, plate(h.width + 50, h.height + 26, INK, INK, 6), W // 2, 1010)
        paste(c, h, W // 2, 1010)
        paste(c, text("עקבו באינסטגרם", 6, fill=GOLD_HI), W // 2, 1120)
    if tt >= 1.9:
        paste(c, text("סאטירה. לא מטעם אף ערוץ, ואף מפלגה.", 4, fill=(190, 196, 220)), W // 2, 1230)
    flash(c, tt, 0, 0.16, 1.0)


def frame(t):
    c = Image.new("RGBA", (W, H), INK + (255,))
    if t < HOOK:
        s_hook(c, t)
        room(c, t)
    elif t < T_F1:
        i, u = seg_at(t)
        broadcast(c, t, i, u)
        room(c, t, STORIES[i][0], u)
    elif t < T_F2:
        s_reveal(c, t)
    elif t < T_END:
        s_machine(c, t)
    else:
        s_end(c, t - T_END)
    return c.convert("RGB")


# ---------------------------------------------------------------------------- sound

def noise(dur, db_):
    r = np.random.default_rng(3)
    return (r.uniform(-1, 1, int(dur * SR)) * 10 ** (db_ / 20)).astype(np.float32)


def audio(path):
    m = P.Mix(DUR)
    m.put(0.0, P.music_seg(os.path.join(P.GAMEPLAY, "music", "panic-vs-poison.wav"), M0, DUR), -4)
    m.put(0.0, noise(0.3, -22))
    m.cue(0.35, "uiClick_D", -6)
    for j in range(2):
        m.cue(0.6 + j * 0.15, "uiClick_D", -8)
    m.cue(1.1, "stamp", -1)
    m.cue(1.5, "uiClick_D", -6)
    m.cue(1.8, "uiClick_D", -8)
    for i, st in enumerate(STORIES):
        ch, ev, l2 = st[0], st[1], st[4]
        t0 = HOOK + i * SEG
        m.cue(t0 - 0.02, "uiClick_D", -4)
        m.put(t0, noise(0.14, -18))
        m.cue(t0 + 0.3, "slipStamp", -12)
        if ch == 14 and ev == "hat":
            for j in range(5):
                P.dubi_says(m, t0 + L2_AT + 0.1 + j * 0.12, "נכון", 3)
        else:
            P.dubi_says(m, t0 + L2_AT, l2, 7)
        if ch == 13 and ev != "chair":
            m.cue(t0 + 0.55, "stamp", -6)
        if ch == 14 and ev == "chair":
            m.cue(t0 + L2_AT + 0.15, "stamp", -4)
        if ch == 14 and ev == "vote":
            for j in range(0, 12, 2):
                m.cue(t0 + 0.4 + j * 0.06, "coin_D_a", -14)
    m.cue(T_F1, "critReact_D_whoosh", -6)
    for j in range(3):
        P.dubi_says(m, T_F1 + 0.8 + j * 0.04, "עוד", 5)
    m.cue(T_F2, "critReact_D_whoosh", -6)
    m.cue(T_F2 + 0.15, "stamp", -3)
    m.cue(T_END + 0.8, "stamp", -2)
    m.write(path, 1.2)


def main():
    P.SCRATCH = sys.argv[1]
    if "--stills" in sys.argv:
        ts = [0.2, 1.3, 3.5] + [HOOK + i * SEG + x for i in range(9) for x in (0.6, 3.2)] + [T_F1 + 1.8, T_F2 + 2.0, T_END + 2.6]
        ims = [frame(x).resize((216, 384)) for x in ts]
        cols = 8
        rows = (len(ims) + cols - 1) // cols
        sheet = Image.new("RGB", (cols * 220, rows * 388), (30, 30, 30))
        for i, im in enumerate(ims):
            sheet.paste(im, ((i % cols) * 220, (i // cols) * 388))
        sheet.save(os.path.join(OUT, "_stills_zap.png"))
        return
    if "--one" in sys.argv:
        frame(float(sys.argv[sys.argv.index("--one") + 1])).save(os.path.join(OUT, "_one.png"))
        return
    name = "od-sevev-promo-zap"
    wav = os.path.join(P.SCRATCH, "_zap.wav")
    audio(wav)
    video = os.path.join(OUT, name + ".mp4")
    cmd = [k.ffmpeg(), "-y", "-loglevel", "error",
           "-f", "rawvideo", "-pix_fmt", "rgb24", "-s", f"{W}x{H}", "-r", str(FPS), "-i", "-", "-i", wav,
           "-map", "0:v", "-map", "1:a", "-c:v", "libx264", "-preset", "slow", "-crf", "18", "-pix_fmt", "yuv420p",
           "-profile:v", "high", "-movflags", "+faststart", "-af", "loudnorm=I=-14:TP=-1.0:LRA=11",
           "-c:a", "aac", "-b:a", "192k", "-ar", "48000", "-t", str(DUR), video]
    p = subprocess.Popen(cmd, stdin=subprocess.PIPE)
    nf = int(DUR * FPS)
    cover = frame(T_F1 + 1.8)           # three TVs, one parrot; also frames 0-1
    cover.save(os.path.join(OUT, name + "-cover.png"))
    for i in range(nf):
        p.stdin.write((cover if i < 2 else frame(i / FPS)).tobytes())
        if i % 300 == 0:
            print(f"zap: frame {i}/{nf}", flush=True)
    p.stdin.close()
    if p.wait() != 0:
        raise SystemExit("ffmpeg failed")
    print(video)


if __name__ == "__main__":
    main()
