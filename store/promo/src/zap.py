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
Liberman won't sit, the Knesset dissolves) on all three channels, each in its own spin, an old TV's
collapse-to-a-line between them. Every anchor is Dubi, the game's parrot, which is the
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
# One colour world per channel, so a zap reads at a glance: 12 red and white, 13 investigative noir,
# 14 blue and gold. Per story: the logo and one meter on top, one screen, Dubi behind the lower third
# (an anchor at his desk), the headline. Nothing else.

R12, R13, B14, G14 = (214, 30, 44), (232, 44, 52), (22, 52, 150), (238, 196, 76)
LOOK = {
    12: dict(bg=((92, 12, 24), (24, 4, 10)), rim=WHITE, lt=WHITE, l1=INK, l2=R12, ring=None, tag=R12, tag_ink=WHITE),
    13: dict(bg=((30, 30, 38), (8, 8, 12)), rim=R13, lt=(18, 18, 24), l1=WHITE, l2=(255, 120, 120), ring=INK, tag=R13, tag_ink=WHITE),
    14: dict(bg=((24, 56, 150), (6, 14, 54)), rim=G14, lt=(12, 30, 100), l1=WHITE, l2=G14, ring=INK, tag=G14, tag_ink=INK),
}
PANIC, TOXIC = (255, 92, 64), (120, 255, 80)

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
T_F1 = HOOK + SEG * len(STORIES)    # 39.2: three channels, one parrot
T_F2 = T_F1 + 1.5 * BAR             # the poison machine
T_END = T_F2 + 1.5 * BAR
DUR = T_END + 2 * BAR               # 49.0

Y_HEAD = 340                        # the logo and the meter
SCREEN = {12: (40, 480, 740, 490), 13: (300, 480, 740, 490), 14: (170, 470, 740, 450)}   # x, y, w, h
Y_LT = 1250                         # the lower third: Dubi stands behind it
ZAP = 0.13                          # the CRT collapse-and-open between channels


def seg_at(t):
    i = int((t - HOOK) // SEG)
    if t < HOOK or i >= len(STORIES):
        return None, None
    return i, t - HOOK - i * SEG


_c = {}


def grad(top, bot, h=H):
    key = ("g", top, bot, h)
    if key not in _c:
        g = Image.new("RGBA", (1, 64))
        for y in range(64):
            u = y / 63
            g.putpixel((0, y), tuple(int(top[j] + (bot[j] - top[j]) * u) for j in range(3)) + (255,))
        _c[key] = g.resize((W, h), Image.BILINEAR)
    return _c[key]


def studio(c, ch):
    """The set: the channel's gradient, its number huge and faint, a soft key light."""
    key = ("studio", ch)
    if key not in _c:
        s = grad(*LOOK[ch]["bg"]).copy()
        n = text(str(ch), 70, fill=WHITE, ring=None, shadow=False, rtl=False)
        n.putalpha(n.getchannel("A").point(lambda v: v * 10 // 255))
        s.alpha_composite(n, (W - n.width + 120, 560))
        spotlight(s, W // 2, 0, 1500, 90, 700, 0.10, (255, 255, 255))
        vignette(s)
        _c[key] = s
    c.alpha_composite(_c[key])


def bug(ch, s=1.0):
    """The corner logo, evoked: 12 a white numeral on a red rhomboid over blue; 13 red with a double
    rule; 14 a red square with a little flag."""
    key = ("bug", ch)
    if key not in _c:
        if ch == 12:
            im = Image.new("RGBA", (230, 120), (0, 0, 0, 0))
            d = ImageDraw.Draw(im)
            d.polygon([(40, 6), (226, 6), (190, 114), (4, 114)], fill=(28, 70, 170))
            d.polygon([(34, 0), (206, 0), (172, 104), (0, 104)], fill=R12)
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
            d.rectangle((0, 0, 119, 119), fill=(204, 26, 32))
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


def shot(who, t, size, box=(0, 330, 1080, 1050)):
    return P.stage_shot(who, t, size, box)


def footage(ev, u, size):
    """The event, from the real captures."""
    if ev == "hat":
        return shot("bibi", 7.0 + (u * 0.6) % 1.4, size)
    if ev == "chair":
        return shot("liberman", 5.0 + min(u, 1.2) * 0.5, size)
    h = round(1080 * size[1] / size[0])                           # the dissolve card, centred at y 1382
    return shot("golan", 21.25, size, (0, 1382 - h // 2, 1080, 1382 + h // 2))


def screen(c, ch, im):
    """One screen per story, rimmed in the channel's colour."""
    x, y, w, h = SCREEN[ch]
    d = ImageDraw.Draw(c)
    d.rectangle((x - 12, y - 12, x + w + 11, y + h + 11), fill=INK)
    d.rectangle((x - 8, y - 8, x + w + 7, y + h + 7), fill=LOOK[ch]["rim"])
    c.alpha_composite(im.resize((w, h), Image.NEAREST) if im.size != (w, h) else im, (x, y))


def anchor(c, x, y, u, talking, scale=2):
    """Dubi: idle, or talking while his line is read."""
    anim = "talk" if talking else "idle"
    a = k.SPRITES["chars"]["dubi-mic"]["anims"][anim]
    fr, anc = char_frame("dubi-mic", anim, int(u * a["fps"]) % a["frames"], scale)
    paste(c, fr, x - anc[0] * scale, y - anc[1] * scale, "tl")


def chip(c, s, x, y, fill, ink=WHITE, px=5):
    im = text(s, px, fill=ink, ring=None, shadow=False)
    paste(c, plate(im.width + 36, im.height + 22, fill, INK, 4), x, y)
    paste(c, im, x, y)


def meter(c, ch, u, lo, hi):
    """12 and 13 run a panic meter; 14 runs a poison meter that reads 0% at full. It climbs to the punch."""
    poison = ch == 14
    v = lo + (hi - lo) * ease_out(clamp((u - 0.3) / (L2_AT + 0.2)))
    n, sw = 8, 34
    lab = text("רעל: 0%" if poison else "תבהלה", 5, fill=WHITE, ring=None, shadow=False)
    w = n * sw + 28 + lab.width + 24
    xr, y = W - 60, Y_HEAD
    d = ImageDraw.Draw(c)
    d.rectangle((xr - w - 6, y - 40, xr + 5, y + 39), fill=INK)
    d.rectangle((xr - w, y - 34, xr - 1, y + 33), fill=(26, 26, 34))
    paste(c, lab, xr - 18 - lab.width // 2, y)
    full = TOXIC if poison else PANIC
    lit = int(round(v / 100 * n))
    x0 = xr - 18 - lab.width - 24
    for j in range(n):                                           # RTL: it fills from the right
        x = x0 - (j + 1) * sw
        col = full if j < lit else (54, 54, 66)
        if j < lit and lit == n and int(u * 8) % 2:
            col = WHITE
        d.rectangle((x + 4, y - 20, x + sw - 2, y + 19), fill=col)


def lower_third(c, u, ch, tag, l1, l2):
    """The channel's bar across the desk: the tag, then line 1, then the punch."""
    L = LOOK[ch]
    wipe = ease_out(clamp((u - 0.12) / 0.22))
    if wipe <= 0:
        return
    d = ImageDraw.Draw(c)
    xl, xr, y0, y1 = 36, W - 36, Y_LT, Y_LT + 230
    xw = xr - int((xr - xl) * wipe)
    d.rectangle((xw - 6, y0 - 6, xr + 5, y1 + 5), fill=INK)
    d.rectangle((xw, y0, xr, y1), fill=L["lt"])
    d.rectangle((xw, y0, xr, y0 + 10), fill=L["tag"])
    if ch == 13:
        d.rectangle((xw, y0 + 16, xr, y0 + 20), fill=L["tag"])
    if u > 0.2:
        tg = text(tag, 6, fill=L["tag_ink"], ring=None, shadow=False)
        tw = tg.width + 48
        paste(c, plate(tw, 80, L["tag"], INK, 5), xr - 20 - tw // 2, y0 - 26)
        paste(c, tg, xr - 20 - tw // 2, y0 - 26)
    if u > 0.32:
        a = text(l1, 6, fill=L["l1"], ring=L["ring"], shadow=L["ring"] is not None)
        paste(c, a, (xl + xr) // 2, y0 + 82)
    if u > L2_AT:
        b = text(l2, 6, fill=L["l2"], ring=L["ring"], shadow=L["ring"] is not None)
        paste(c, scaled(b, pop_scale(u, L2_AT, 0.12, 1.15)), (xl + xr) // 2, y0 + 168)


# ---------------------------------------------------------------------------- the three sets

def pixelated(im, block):
    sw, sh = max(1, im.width // block), max(1, im.height // block)
    return im.resize((sw, sh), Image.BILINEAR).resize(im.size, Image.NEAREST)


def set12(c, u, ev, talk):
    x, y, w, h = SCREEN[12]
    if ev == "chair":                                            # the screen fills with commentators
        im = Image.new("RGBA", (w, h), (40, 10, 18, 255))
        n = 12 if u < L2_AT else 14
        cols, cw, chh = 5, w // 5, h // 3
        for i in range(min(n, 15)):
            cx, cy = (i % cols) * cw, (i // cols) * chh
            col = WHITE if (i + i // cols) % 2 else R12
            ImageDraw.Draw(im).rectangle((cx + 4, cy + 4, cx + cw - 5, cy + chh - 5), fill=col)
            ImageDraw.Draw(im).rectangle((cx + 10, cy + 10, cx + cw - 11, cy + chh - 11), fill=(30, 34, 70))
            bob = 4 * ((int(u * 8) + i) % 2)
            av = img("avatar_dubi", 3)
            im.alpha_composite(av, (cx + cw // 2 - av.width // 2, cy + chh // 2 - av.height // 2 - bob))
        screen(c, 12, im)
        chip(c, "פרשנים באולפן: %d" % n, x + w // 2, y + h + 46, R12)
    else:
        screen(c, 12, footage(ev, u, (w, h)))
    anchor(c, 880, Y_LT + 130, u, talk)


def set13(c, u, ev, talk):
    x, y, w, h = SCREEN[13]
    if ev == "hat":                                              # the rabbit, identity withheld
        im = grad((70, 74, 96), (36, 38, 52), h).crop((0, 0, w, h)).copy()
        rab = img("prop_rabbit", 14)
        im.alpha_composite(rab, (w // 2 - rab.width // 2, h // 2 - rab.height // 2 + 40))
        im = pixelated(im, 34 if u > 0.45 else 2)
        screen(c, 13, im)
        chip(c, "זהותו שמורה במערכת", x + w // 2, y + 46, INK)
    elif ev == "chair":                                          # a security camera on an empty chair
        im = Image.new("RGBA", (w, h), (34, 44, 38, 255))
        sd = ImageDraw.Draw(im)
        sd.rectangle((0, 330, w, h), fill=(44, 56, 48))
        cc = (100, 122, 106)
        cx = w // 2
        sd.rectangle((cx - 80, 130, cx + 80, 152), fill=cc)
        sd.rectangle((cx - 80, 130, cx - 58, 290), fill=cc)
        sd.rectangle((cx + 58, 130, cx + 80, 290), fill=cc)
        sd.rectangle((cx - 100, 280, cx + 100, 306), fill=cc)
        for xx in (cx - 90, cx + 72):
            sd.rectangle((xx, 306, xx + 18, 400), fill=cc)
        for yy in range(0, h, 4):
            sd.line((0, yy, w, yy), fill=(0, 0, 0, 50))
        if int(u * 3) % 2 == 0:
            sd.ellipse((24, 24, 52, 52), fill=(255, 40, 40))
        im.alpha_composite(text("REC", 5, rtl=False), (64, 18))
        day = text("יום %d" % (1 + int(min(1.0, u / 2.8) * 182)), 5)
        im.alpha_composite(day, (w - day.width - 24, 18))
        screen(c, 13, im)
    else:                                                        # the exclusive: one sheet, one stamp
        im = Image.new("RGBA", (w, h), (24, 24, 30, 255))
        doc = Image.new("RGBA", (520, 380), (240, 234, 216, 255))
        ln = text("יש בחירות.", 8, fill=INK, ring=None, shadow=False)
        doc.alpha_composite(ln, (260 - ln.width // 2, 70))
        for j in range(4):
            ImageDraw.Draw(doc).rectangle((60, 200 + j * 34, 460 - j * 50, 214 + j * 34), fill=(160, 156, 146))
        im.alpha_composite(doc, (w // 2 - 260, h // 2 - 190))
        screen(c, 13, im)
        if u > 0.55:
            slam(c, k.stamp_img("בלעדי", 11), u, 0.55, x + w // 2 + 60, y + h // 2 + 110, angle=-10, frm=2.4)
    anchor(c, 190, Y_LT + 130, u, talk)


def set14(c, u, ev, talk):
    x, y, w, h = SCREEN[14]
    screen(c, 14, footage(ev, u, (w, h)))
    if ev == "chair" and u > L2_AT:                              # the culprits, found
        c.alpha_composite(Image.new("RGBA", (w, h), (6, 14, 54, 200)), (x, y))
        s_ = pop_scale(u, L2_AT, 0.14, 1.5)
        paste(c, scaled(bug(12), s_), x + w // 2 + 150, y + h // 2 - 40)
        paste(c, scaled(bug(13), s_), x + w // 2 - 150, y + h // 2 - 30)
        if u > L2_AT + 0.25:
            chip(c, "אשמים", x + w // 2, y + h - 70, (204, 26, 32), px=7)
    if ev == "vote":
        coins_burst(c, u, 0.4, x + w // 2, y + 120, n=26, seed=14, life=1.6, kinds=("coin", "bill"))
    for i in range(5):                                           # the panel: five of him
        px = 140 + i * 200
        loud = talk or (ev == "hat" and u > L2_AT)
        anchor(c, px, Y_LT + 60, u + i * 0.13, loud and (int(u * 6) + i) % 3 != 0, scale=1)
        if ev == "hat" and u > L2_AT + 0.1 + i * 0.12:
            paste(c, scaled(bubble("נכון!", 4), pop_scale(u, L2_AT + 0.1 + i * 0.12, 0.1, 1.5)), px, Y_LT - 300 + (i % 2) * 30)


SETS = {12: set12, 13: set13, 14: set14}


def broadcast(c, i, u):
    ch, ev, tag, l1, l2, lo, hi = STORIES[i]
    talk = L2_AT <= u < L2_AT + 1.0
    studio(c, ch)
    SETS[ch](c, u, ev, talk)
    paste(c, bug(ch), 60 + bug(ch).width // 2, Y_HEAD)
    meter(c, ch, u, lo, hi)
    lower_third(c, u, ch, tag, l1, l2)


def zap(c, u):
    """Between channels: the picture collapses to a line and opens again (an old TV changing over)."""
    if u >= ZAP:
        return c
    e = ease_out(u / ZAP)
    h = max(8, int(H * e))
    out = Image.new("RGBA", (W, H), (0, 0, 0, 255))
    out.alpha_composite(c.resize((W, h), Image.NEAREST), (0, (H - h) // 2))
    if e < 0.5:
        ImageDraw.Draw(out).rectangle((0, H // 2 - 4, W, H // 2 + 4), fill=(235, 240, 255))
    return out


# ---------------------------------------------------------------------------- the open, the reveal, the end

def s_hook(c, t):
    """The bill: ערוצי התבהלה, נגד, מכונת הרעל. Each side under the other side's name for it."""
    c.alpha_composite(grad((70, 10, 22), (10, 8, 20), H // 2), (0, 0))
    c.alpha_composite(grad((8, 12, 20), (12, 54, 24), H - H // 2), (0, H // 2))
    vignette(c)
    if t < 0.3:                                                  # the TV switching on
        d = ImageDraw.Draw(c)
        h = int(8 + 1400 * ease_out(t / 0.3) ** 3)
        d.rectangle((0, H // 2 - h // 2, W, H // 2 + h // 2), fill=(230, 236, 255))
        return
    if t >= 0.35:
        paste(c, scaled(text("ערוצי התבהלה", 11, fill=PANIC), pop_scale(t, 0.35, 0.14, 1.4)), W // 2, 470)
    for j, ch in enumerate((12, 13)):
        t0 = 0.6 + j * 0.15
        if t >= t0:
            paste(c, scaled(bug(ch, 1.15), pop_scale(t, t0, 0.14, 1.6)), W // 2 + 160 - j * 320, 660)
    if t >= 1.1:
        slam(c, badge("נגד", 13), t, 1.1, W // 2, H // 2, angle=-4, frm=2.8)
    if t >= 1.5:
        paste(c, scaled(text("מכונת הרעל", 11, fill=TOXIC), pop_scale(t, 1.5, 0.14, 1.4)), W // 2, 1230)
    if t >= 1.8:
        paste(c, scaled(bug(14, 1.15), pop_scale(t, 1.8, 0.14, 1.6)), W // 2, 1420)
    flash(c, t, 0.3, 0.1, 0.8)
    flash(c, t, 1.1, 0.1, 0.5)


def s_reveal(c, t):
    """Three channels side by side, the same parrot in each, moving as one."""
    u = t - T_F1
    for j, ch in enumerate((14, 13, 12)):                        # RTL: 12 on the right
        col = Image.new("RGBA", (W // 3, H))
        col.alpha_composite(grad(*LOOK[ch]["bg"]).crop((0, 0, W // 3, H)))
        c.alpha_composite(col, (j * W // 3, 0))
        cx = j * W // 3 + W // 6
        paste(c, bug(ch, 0.9), cx, 600)
        anchor(c, cx, 1300, u, int(u * 6) % 2 == 0, scale=2)
    d = ImageDraw.Draw(c)
    for j in (1, 2):
        d.rectangle((j * W // 3 - 3, 480, j * W // 3 + 2, 1300), fill=INK)
    if u > 0.1:
        paste(c, text("תבהלה? רעל?", 10, grad=True), W // 2, 380)
    if u > 0.8:
        slam(c, text("תוכי אחד.", 12, fill=WHITE), u, 0.8, W // 2, 1450, frm=2.2)
    flash(c, u, 0, 0.1, 0.6)


def s_machine(c, t):
    u = t - T_F2
    c.alpha_composite(grad((10, 8, 24), (20, 40, 22)))
    spotlight(c, W // 2, 0, 1500, 80, 600, 0.16, (160, 255, 140))
    vignette(c)
    paste(c, text("ומכונת הרעל?", 10, grad=True), W // 2, 420)
    fr = int(u * 2.5) % 2
    sheet = img("source_poison", 5)
    rack = sheet.crop((fr * 92 * 5, 0, fr * 92 * 5 + 92 * 5, 120 * 5))
    s = pop_scale(u, 0.15, 0.18, 0.3)
    if s:
        paste(c, scaled(rack, s), W // 2, 960)
    if u > 0.9:
        paste(c, text("במשחק יש לך אחת משלך.", 8), W // 2, 1360)
    if u > 1.4:
        paste(c, text("10,000 חשבונות. דעה אחת.", 6, fill=GOLD_HI), W // 2, 1470)
    flash(c, u, 0, 0.1, 0.6)


def s_end(c, tt):
    k.curtain(c, 0, dim=0.15)
    spotlight(c, W // 2, 0, 1400, 90, 480, 0.2, GOLD_HI)
    vignette(c)
    coins_burst(c, tt, 0, W // 2, 760, n=50, seed=12, life=2.0, kinds=("coin", "coin", "slip", "bill"))
    s = pop_scale(tt, 0, 0.18, 0.2)
    if s:
        paste(c, scaled(img("wordmark", 6), s), W // 2, 400)
    if tt >= 0.3:
        paste(c, text("כל הערוצים. משחק אחד.", 8), W // 2, 610)
    if tt >= 0.8:
        slam(c, badge("בקרוב"), tt, 0.8, W // 2, 860, angle=-4, frm=2.4)
    if tt >= 1.3:
        h = text("@od.sevev", 8)
        paste(c, plate(h.width + 50, h.height + 26, INK, INK, 6), W // 2, 1080)
        paste(c, h, W // 2, 1080)
        paste(c, text("עקבו באינסטגרם", 6, fill=GOLD_HI), W // 2, 1190)
    if tt >= 1.9:
        paste(c, text("סאטירה. לא מטעם אף ערוץ, ואף מפלגה.", 4, fill=(190, 196, 220)), W // 2, 1300)
    flash(c, tt, 0, 0.16, 1.0)


def frame(t):
    c = Image.new("RGBA", (W, H), INK + (255,))
    if t < HOOK:
        s_hook(c, t)
    elif t < T_F1:
        i, u = seg_at(t)
        broadcast(c, i, u)
        c = zap(c, u)
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
        m.put(t0, noise(0.08, -22))
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
        ts = [1.3, 3.5] + [HOOK + i * SEG + x for i in range(9) for x in (0.6, 3.2)] + [T_F1 + 1.8, T_F2 + 2.0, T_END + 2.6]
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
