"""'עוד סבב': five more Reels, five looks, five jobs (Oct 2026). Lengths per Bar: 15 s or 30 s, never past 45.

Research (sources in store/promo/README.md): Mosseri's top signals are watch time, sends per reach and
likes per reach, and sends weigh most for non-followers; the hook has under two seconds; 7-15 s gets the
best completion; raw beats polished; Instagram does not recommend political content to non-followers by
default, so every Reel opens as a game or a joke, never as a candidate. The series stays recognisable by
one end card (the wordmark, "בקרוב", @od.sevev) while each Reel wears its own skin:

    ghost    15 s  "דברים שכדאי לגוסט": October's sheet-ghost trend (signs, one per beat); a pixel
                   ghost in sunglasses, a leader's pose answers each sign. Night purple.
    patch    15 s  "עדכון 3.0: הערות גרסה": the leaders-v3 abilities as patch notes. A dark launcher.
    loading  15 s  "סופר את הקולות…": the game's real loading line, tips, characters you have never seen
                   before; 99%, the Knesset dissolves, 0%. A 16-bit console, a clean loop.
    match    30 s  "אחדות": a dating app. Netanyahu's unity card; every opposition leader swipes left;
                   then Ben Gvir and Smotrich swipe left on each other. "0 התאמות. צריך 61."
    process  30 s  "מהכותרת למכניקה": a real headline, the design note, the ability in the game.
                   Newsprint and sticky notes.

Every fact is one the game already carries (design/facts.json); ability names and lines are the game's.

    python3 store/promo/src/reels5.py <scratch> ghost|patch|loading|match|process [--stills | --one <sec>]
"""
import math
import os
import subprocess
import sys

import numpy as np
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import promo as P  # noqa: E402
import shorts as S  # noqa: E402
import teaser as k  # noqa: E402
from teaser import (INK, NIGHT, GOLD, GOLD_HI, GOLD_SH, WHITE, RED, W, H, FPS, img, paste, scaled, text,  # noqa: E402
                    plate, bubble, badge, slam, flash, pop_scale, clamp, ease_out, ease_inout, char_frame,
                    coins_burst, vignette, spotlight, shake, rnd)

OUT = P.OUT
END = 2.2                           # the shared end card's length
_c = {}


# ---------------------------------------------------------------------------- shared

def grad(top, bot, w=W, h=H):
    key = ("g", top, bot, w, h)
    if key not in _c:
        g = Image.new("RGBA", (1, 64))
        for y in range(64):
            u = y / 63
            g.putpixel((0, y), tuple(int(top[j] + (bot[j] - top[j]) * u) for j in range(3)) + (255,))
        _c[key] = g.resize((w, h), Image.BILINEAR)
    return _c[key]


def pose(c, who, x, y, scale=2, t=0.0, anim=None):
    """A character (or a GPT pose) with its feet at (x, y)."""
    ch = k.SPRITES["chars"][who]
    anim = anim or list(ch["anims"])[0]
    a = ch["anims"][anim]
    fr, anc = char_frame(who, anim, int(t * a["fps"]) % a["frames"], scale)
    paste(c, fr, x - anc[0] * scale, y - anc[1] * scale, "tl")


def end_card(c, tt):
    """One sign-off for the whole series: the wordmark, בקרוב, the handle."""
    c.alpha_composite(grad((14, 18, 52), (6, 8, 22)))
    spotlight(c, W // 2, 0, 1500, 90, 560, 0.16, GOLD_HI)
    vignette(c)
    coins_burst(c, tt, 0, W // 2, 640, n=36, seed=21, life=1.8, kinds=("coin", "coin", "bill"))
    s = pop_scale(tt, 0, 0.18, 0.2)
    if s:
        paste(c, scaled(img("wordmark", 6), s), W // 2, 560)
    if tt > 0.3:
        paste(c, text("משחק סאטירה. חינם, בדפדפן.", 7), W // 2, 760)
    if tt > 0.6:
        slam(c, badge("בקרוב", 13), tt, 0.6, W // 2, 960, angle=-4, frm=2.4)
    if tt > 1.0:
        h = text("@od.sevev", 8)
        paste(c, plate(h.width + 50, h.height + 26, INK, GOLD_SH, 6), W // 2, 1170)
        paste(c, h, W // 2, 1170)
        paste(c, text("עקבו באינסטגרם", 6, fill=GOLD_HI), W // 2, 1280)
    if tt > 1.3:
        paste(c, text("סאטירה. לא מטעם אף מפלגה.", 4, fill=(180, 186, 210)), W // 2, 1380)
    flash(c, tt, 0, 0.14, 0.9)


def end_audio(m, t0):
    m.cue(t0, "stinger_motif_D", -3)
    m.cue(t0 + 0.6, "stamp", -2)


def music(m, name, at, t0, dur, db):
    if name.endswith(".wav"):
        a = P.music_seg(os.path.join(P.GAMEPLAY, "music", name), at, dur)
    else:
        a = np.concatenate([k.load_wav(name)] * 6)[int(at * P.SR): int((at + dur) * P.SR)]
    n = len(a)
    f = int(0.4 * P.SR)
    if n > 2 * f:
        a = a.copy()
        a[-f:] *= np.linspace(1, 0, f)
    m.put(t0, a, db)


# ============================================================================ 1. ghost (15 s)

G_DUR = 15.0
G_T0, G_STEP = 1.0, 1.75
G_SIGNS = [  # (sign, who answers, his line): the things to ghost; a leader's pose answers each
    ("התחייבות חתומה", "bennett-sign", "כבר הפכתי."),
    ("מכתב פרישה", "ben-gvir-back", "חזרתי!"),
    ("לחכות לרוטציה", "gantz", "מאז 2020."),
    ("תקציב בזמן", "smotrich-budget", "בדקה ה־90."),
    ("הצעת אחדות", "golan-swipe", "שמאלה."),
]
G_LAST = G_T0 + G_STEP * len(G_SIGNS)       # 9.75: the sign "הבחירות"
G_END = G_DUR - END


def ghost_img():
    """A sheet ghost in sunglasses, drawn on a 36x46 grid and blown up 9x."""
    if "ghost" in _c:
        return _c["ghost"]
    g = Image.new("RGBA", (36, 46), (0, 0, 0, 0))
    d = ImageDraw.Draw(g)
    o, b, s = INK, (244, 244, 252), (196, 198, 222)
    d.ellipse((2, 1, 33, 32), fill=o)
    d.rectangle((2, 16, 33, 40), fill=o)
    d.ellipse((3, 2, 32, 31), fill=b)
    d.rectangle((3, 16, 32, 39), fill=b)
    for i in range(4):                                           # the hem
        x = 3 + i * 8
        d.ellipse((x - 1, 35, x + 8, 44), fill=o)
        d.ellipse((x, 35, x + 7, 43), fill=b)
    d.rectangle((24, 8, 32, 41), fill=s)                         # shade on the right
    d.ellipse((24, 2, 32, 31), fill=s)
    d.rectangle((6, 14, 30, 16), fill=o)                         # the sunglasses
    d.rectangle((7, 15, 16, 20), fill=o)
    d.rectangle((20, 15, 29, 20), fill=o)
    d.point([(9, 16), (22, 16)], fill=WHITE)
    d.rectangle((0, 24, 3, 28), fill=o)                          # the arms, up to the sign
    d.rectangle((32, 24, 35, 28), fill=o)
    d.rectangle((1, 25, 3, 27), fill=b)
    d.rectangle((32, 25, 34, 27), fill=s)
    _c["ghost"] = g.resize((36 * 9, 46 * 9), Image.NEAREST)
    return _c["ghost"]


def sign_img(line, red=False):
    key = ("sign", line, red)
    if key not in _c:
        t = text(line, 8, fill=(200, 20, 30) if red else INK, ring=None, shadow=False)
        w, h = max(560, t.width + 80), 230
        im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        d = ImageDraw.Draw(im)
        d.rectangle((0, 0, w - 1, h - 1), fill=(120, 84, 46))
        d.rectangle((8, 8, w - 9, h - 9), fill=(214, 170, 112))
        d.rectangle((8, h - 30, w - 9, h - 9), fill=(196, 150, 94))
        im.alpha_composite(t, (w // 2 - t.width // 2, h // 2 - t.height // 2 - 8))
        _c[key] = im
    return _c[key]


def flip_in(im, t, t0, dur=0.16):
    """A sign flipped up into view: it grows from a sliver, with a little overshoot."""
    u = (t - t0) / dur
    if u <= 0:
        return None
    if u >= 1:
        return im
    sy = max(0.02, k.back_out(u, 1.4))
    return im.resize((im.width, max(1, int(im.height * sy))), Image.NEAREST)


def ghost_frame(t):
    c = Image.new("RGBA", (W, H), INK + (255,))
    if t >= G_END:
        end_card(c, t - G_END)
        return c.convert("RGB")
    c.alpha_composite(grad((44, 18, 78), (10, 6, 26)))
    d = ImageDraw.Draw(c)
    r = rnd("stars")
    for _ in range(40):                                          # stars that twinkle
        x, y = r.randrange(W), r.randrange(200, 1300)
        if (int(t * 3) + x) % 5:
            d.rectangle((x, y, x + 5, y + 5), fill=(220, 210, 255))
    d.ellipse((840, 520, 1000, 680), fill=(250, 240, 200))       # the moon
    d.ellipse((800, 500, 944, 644), fill=(36, 16, 66))
    d.rectangle((0, 1440, W, H), fill=(18, 10, 34))              # the ground
    d.rectangle((0, 1440, W, 1450), fill=(70, 40, 110))
    paste(c, text("דברים שכדאי לגוסט", 10, grad=True), W // 2, 330)
    paste(c, text("לפני 27.10", 6, fill=(220, 210, 255)), W // 2, 440)
    bob = int(10 * math.sin(t * 3.2))
    gx, gy = 300, 1080 + bob
    i = int((t - G_T0) // G_STEP) if t >= G_T0 else -1
    if t >= G_LAST:                                              # the last sign: it can't be ghosted
        dx, dy = shake(t, [(G_LAST + 1.0, 18, 0.5)])
        paste(c, ghost_img(), gx + dx, gy + dy)
        sg = flip_in(sign_img("הבחירות"), t, G_LAST)
        if sg:
            paste(c, sg, 400 + dx, 780 + bob + dy)
        if t >= G_LAST + 1.0:
            slam(c, sign_img("הן חוזרות.", red=True), t, G_LAST + 1.0, 560, 840, angle=-5, frm=2.0)
        if t >= G_LAST + 1.7:
            slam(c, badge("עוד סבב", 12), t, G_LAST + 1.7, 700, 1300, angle=-4, frm=2.4)
            flash(c, t, G_LAST + 1.7, 0.12, 0.6)
        return c.convert("RGB")
    paste(c, ghost_img(), gx, gy)
    if i >= 0:
        line, who, says = G_SIGNS[i]
        t0 = G_T0 + i * G_STEP
        sg = flip_in(sign_img(line), t, t0)
        if sg:
            paste(c, sg, 400, 780 + bob)
        if t >= t0 + 0.45:
            s = pop_scale(t, t0 + 0.45, 0.14, 0.4)
            fr = Image.new("RGBA", (440, 640), (0, 0, 0, 0))
            pose(fr, who, 220, 620, 2, t)
            paste(c, scaled(fr, s), 850, 1440 - 320)
        if t >= t0 + 0.75:
            paste(c, scaled(bubble(says, 6), pop_scale(t, t0 + 0.75, 0.12, 1.4)), 880, 700)
    return c.convert("RGB")


def ghost_audio(path):
    m = P.Mix(G_DUR)
    music(m, "music_courthouse_L0", 0.0, 0.0, G_END, -9)
    m.cue(0.0, "dubiSquawk_D_up", -8)
    for i in range(len(G_SIGNS)):
        t0 = G_T0 + i * G_STEP
        m.cue(t0, "slipStamp", -4)
        m.cue(t0 + 0.45, "leaderPick_D", -9)
        m.cue(t0 + 0.75, "chatPing_D_default", -8)
    m.cue(G_LAST, "slipStamp", -3)
    m.cue(G_LAST + 1.0, "stamp", -1)
    m.cue(G_LAST + 1.7, "stamp_bell", -2)
    end_audio(m, G_END)
    m.write(path, 0.5)


# ============================================================================ 2. patch notes (15 s)

N_DUR = 15.0
N_T0, N_STEP = 1.1, 1.55
N_ITEMS = [  # (tag, icon, title, note): the leaders-v3 abilities, as the game's patch notes
    ("חדש", "dubi", "לכל ראש רשימה: יכולת.", "8 כפתורים חדשים. 0 הסכמות."),
    ("חדש", "bengvir", "בן גביר: ׳אני פורש׳.", "חוזר אחרי 20 שניות. זה לא באג."),
    ("איזון", "smotrich", "סמוטריץ׳: תקציב בדקה ה־90.", "בכוונה. כמו במציאות."),
    ("חדש", "liberman", "ליברמן: ׳לא אשב׳ = סעיף.", "חמישה סעיפים: מסמך. ולא יושב."),
    ("חדש", "deri", "דרעי: ׳למסדרון׳.", "הדרישה מחכה. סוגרים במסדרון."),
    ("באג ידוע", "gantz", "גנץ מופיע בבוחר.", "עוד מחליט אם הוא רץ."),
    ("באג ידוע", "vote", "הבחירות חוזרות.", "אין תיקון בטווח הנראה לעין."),
]
N_ROW, N_TOP, N_ROWS = 200, 410, 5
N_END = N_DUR - END
TAGC = {"חדש": (70, 220, 120), "איזון": (250, 190, 60), "באג ידוע": (250, 80, 80)}


def note_icon(key):
    if key == "dubi":
        return img("avatar_dubi", 3)
    if key == "vote":
        return img("chip_icon_calendar", 6)
    if key == "gantz":
        fr, _ = char_frame("gantz", "idle", 0, 1)
        return fr.crop((0, 0, fr.width, fr.width)).resize((96, 96), Image.NEAREST)
    return img("prop_ability_" + key, 6)


def patch_frame(t):
    c = Image.new("RGBA", (W, H), INK + (255,))
    if t >= N_END:
        end_card(c, t - N_END)
        return c.convert("RGB")
    c.alpha_composite(grad((16, 20, 28), (8, 10, 14)))
    d = ImageDraw.Draw(c)
    for x in range(0, W, 60):                                    # the faint grid
        d.line((x, 0, x, H), fill=(22, 28, 38))
    for y in range(0, H, 60):
        d.line((0, y, W, y), fill=(22, 28, 38))
    d.rectangle((40, 220, W - 40, 380), fill=(24, 30, 42))       # the header
    d.rectangle((40, 220, W - 40, 228), fill=(70, 220, 120))
    paste(c, img("wordmark", 3), W - 60 - img("wordmark", 3).width // 2, 290)
    v = text("v3.0", 6, fill=INK, ring=None, shadow=False, rtl=False)
    paste(c, plate(v.width + 30, v.height + 18, (70, 220, 120), INK, 3), 110, 290)
    paste(c, v, 110, 290)
    hd = text("הערות גרסה", 6, fill=(170, 180, 200), ring=None, shadow=False)
    paste(c, hd, W - 60 - hd.width // 2, 350)
    shown = sum(1 for j in range(len(N_ITEMS)) if t >= N_T0 + j * N_STEP)
    scroll = sum(ease_out(clamp((t - (N_T0 + j * N_STEP)) / 0.25)) for j in range(N_ROWS, len(N_ITEMS)))
    for j in range(shown):
        tag, icon, title, sub = N_ITEMS[j]
        t0 = N_T0 + j * N_STEP
        y = int(N_TOP + (j - scroll) * N_ROW)
        if y < N_TOP - N_ROW + 40:
            continue
        new = j == shown - 1
        a_ = ease_out(clamp((t - t0) / 0.18))
        x_off = int((1 - a_) * 80)
        d.rectangle((40 + x_off, y, W - 40, y + N_ROW - 16), fill=(34, 42, 58) if new else (22, 27, 37))
        d.rectangle((W - 50, y, W - 40, y + N_ROW - 16), fill=TAGC[tag])
        tg = text(tag, 4, fill=INK, ring=None, shadow=False)
        paste(c, plate(tg.width + 24, tg.height + 14, TAGC[tag], INK, 3), W - 72 - (tg.width + 24) // 2, y + 36)
        ti = text(title, 6, fill=WHITE if new else (190, 196, 210), ring=None, shadow=False)
        paste(c, ti, W - 72 - ti.width // 2 + x_off, y + 100)
        if t >= t0 + 0.35:
            sb = text(sub, 5, fill=TAGC[tag] if new else (120, 130, 150), ring=None, shadow=False)
            paste(c, sb, W - 72 - sb.width // 2, y + 152)
        paste(c, note_icon(icon), 120 + x_off, y + 92)
    d.rectangle((0, 0, W, N_TOP - 12), fill=(14, 17, 24))       # the header sits over the scroll
    d.rectangle((40, 220, W - 40, 380), fill=(24, 30, 42))
    d.rectangle((40, 220, W - 40, 228), fill=(70, 220, 120))
    paste(c, img("wordmark", 3), W - 60 - img("wordmark", 3).width // 2, 290)
    paste(c, plate(v.width + 30, v.height + 18, (70, 220, 120), INK, 3), 110, 290)
    paste(c, v, 110, 290)
    paste(c, hd, W - 60 - hd.width // 2, 350)
    if int(t * 2) % 2 and shown < len(N_ITEMS):                  # the cursor
        y = int(N_TOP + (shown - scroll) * N_ROW)
        if y < N_TOP + N_ROWS * N_ROW:
            d.rectangle((W - 90, y + 20, W - 70, y + 70), fill=(70, 220, 120))
    return c.convert("RGB")


def patch_audio(path):
    m = P.Mix(N_DUR)
    music(m, "glitch-warfare.wav", 34.10 - N_T0, 0.0, N_END, -7)
    for j in range(len(N_ITEMS)):
        t0 = N_T0 + j * N_STEP
        for q in range(4):
            m.cue(t0 + q * 0.05, "uiClick_D", -12)
        m.cue(t0 + 0.35, "chatPing_D_default", -9)
    end_audio(m, N_END)
    m.write(path, 0.5)


# ============================================================================ 3. loading (15 s, a loop)

L_DUR = 15.0
L_FULL = 12.2                       # 99% from here
L_DROP = 13.0                       # the Knesset dissolves
L_TIPS = [
    "טיפ: בן גביר פרש? חכו 20 שניות.",
    "טיפ: תקציב מאשרים בדקה ה־90.",
    "טיפ: ליברמן לא יושב. אבל כותב.",
    "טיפ: גנץ בבוחר. אל תתרגלו.",
    "טיפ: דרעי סוגר במסדרון.",
    "טיפ: אין 61? יש עוד סבב.",
]
L_GUESTS = [  # (start, end, who, anim, scale, y): characters you've never seen before cross the screen
    (2.0, 5.0, "kaia", "idle", 3, 1400),
    (6.0, 9.2, "mk-undecided", "idle", 1, 1440),
    (9.6, 12.4, "gantz", "idle", 1, 1440),
]


def load_pct(t):
    if t < L_FULL:
        u = t / L_FULL
        return min(99, int(99 * (u ** 0.8)) - (3 if 0.45 < u < 0.5 else 0))   # one stall, as they do
    if t < L_DROP:
        return 99
    return max(0, int(99 * (1 - (t - L_DROP) / 0.6)))


def loading_frame(t):
    c = Image.new("RGBA", (W, H), (6, 6, 10, 255))
    d = ImageDraw.Draw(c)
    paste(c, img("wordmark", 6), W // 2, 520)
    pct = load_pct(t)
    x0, x1, y0 = 140, W - 140, 760
    d.rectangle((x0 - 12, y0 - 12, x1 + 11, y0 + 71), fill=(200, 200, 210))
    d.rectangle((x0 - 6, y0 - 6, x1 + 5, y0 + 65), fill=(6, 6, 10))
    cells = 20
    cw = (x1 - x0) / cells
    lit = int(pct / 100 * cells + 0.5)
    for j in range(lit):                                         # RTL: it fills from the right
        xr = x1 - j * cw
        col = (250, 80, 80) if t >= L_DROP else GOLD
        d.rectangle((int(xr - cw + 4), y0 + 4, int(xr - 4), y0 + 55), fill=col)
    pc = text("%d%%" % pct, 7, fill=WHITE, rtl=False)
    paste(c, pc, W // 2, y0 + 150)
    if t < L_DROP:
        dots = "." * (1 + int(t * 3) % 3)
        ln = text("סופר את הקולות" + dots, 6, fill=(200, 200, 210), ring=None, shadow=False)
        paste(c, ln, x1 - ln.width // 2, y0 - 70)
    else:
        slam(c, text("הכנסת התפזרה.", 9, fill=(250, 80, 80)), t, L_DROP, W // 2, 660, frm=2.0)
        if t >= L_DROP + 0.7:
            paste(c, text("עוד סבב.", 8, grad=True), W // 2, 1080)
    if t < L_DROP:                                               # the tips
        j = min(len(L_TIPS) - 1, int(t / (L_DROP / len(L_TIPS))))
        tp = text(L_TIPS[j], 5, fill=(150, 200, 255), ring=None, shadow=False)
        d.rectangle((60, 1080, W - 60, 1200), fill=(14, 16, 26))
        d.rectangle((60, 1080, W - 60, 1084), fill=(150, 200, 255))
        paste(c, tp, W // 2, 1142)
    for t0, t1, who, anim, sc, y in L_GUESTS:                    # someone you've never seen before
        if t0 <= t < t1:
            u = (t - t0) / (t1 - t0)
            x = int(-160 + (W + 320) * u)
            pose(c, who, x, y, sc, t, anim)
    d.rectangle((0, 1468, W, 1560), fill=(14, 16, 26))
    cta = text("בקרוב · עקבו @od.sevev", 5, fill=GOLD_HI, ring=None, shadow=False)
    paste(c, cta, W // 2, 1514)
    return c.convert("RGB")


def loading_audio(path):
    m = P.Mix(L_DUR)
    music(m, "music_balfour_L0", 0.0, 0.0, L_DROP, -12)
    for j in range(len(L_TIPS)):
        m.cue(j * (L_DROP / len(L_TIPS)) + 0.05, "uiClick_D", -10)
    m.cue(2.0, "chatPing_D_default", -12)
    m.cue(L_FULL, "cantAfford_D", -6)
    m.cue(L_DROP, "gavel_a", -2)
    m.cue(L_DROP + 0.7, "dubiSquawk_D_up", -6)
    m.write(path, 0.3)


# ============================================================================ 4. match (30 s)

A_DUR = 30.0
A_SPLASH = 1.2
A_CARDS = [  # (start, card id, shown to, verdict): Netanyahu's unity card, then the coalition's own
    (1.2, "bibi", "golan", "שמאלה"),
    (5.2, "bibi2", "bennett", "לא"),
    (8.6, "bibi3", "liberman", "לא אשב"),
    (11.6, "bibi3", "eisenkot", "לא"),
    (15.4, "smotrich", "bengvir", "לא"),
    (18.8, "bengvir", "smotrich", "לא"),
]
A_SWIPE = {"bibi": 2.4, "bibi2": 2.0, "bibi3": 1.6, "smotrich": 2.0, "bengvir": 1.8}   # when, after the card lands
A_BRIDGE = (14.2, 15.4)             # "בינתיים, בקואליציה:"
A_RESULT = 22.2
A_END = A_DUR - 3.0
CARD = {  # id: (pose char, name, bio)
    "bibi": ("bibi-matchmaker", "בנימין, 76", "מחפש ממשלת אחדות. רק רציניים."),
    "bibi2": ("bibi-matchmaker", "בנימין, 76", "עדיין מחפש ממשלת אחדות."),
    "bibi3": ("bibi-matchmaker", "בנימין, 76", "מחפש אחדות. גמיש מאוד."),
    "smotrich": ("smotrich", "בצלאל, 46", "רץ לבד. פתוח להצעות."),
    "bengvir": ("ben-gvir", "איתמר, 50", "רץ לבד. ההחלטה סופית."),
}
PINK, PINK2 = (255, 92, 120), (255, 150, 110)


def heart(px=6, col=PINK):
    key = ("heart", px, col)
    if key not in _c:
        rows = [".XX.XX.", "XXXXXXX", "XXXXXXX", ".XXXXX.", "..XXX..", "...X..."]
        im = Image.new("RGBA", (7, 6), (0, 0, 0, 0))
        for y, r in enumerate(rows):
            for x, ch in enumerate(r):
                if ch == "X":
                    im.putpixel((x, y), col + (255,))
        _c[key] = im.resize((7 * px, 6 * px), Image.NEAREST)
    return _c[key]


def card_img(cid):
    key = ("card", cid)
    if key not in _c:
        who, name, bio = CARD[cid]
        w, h = 820, 1000
        im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        m = Image.new("L", (w, h), 0)
        ImageDraw.Draw(m).rounded_rectangle((0, 0, w - 1, h - 1), radius=48, fill=255)
        body = Image.new("RGBA", (w, h), WHITE + (255,))
        body.alpha_composite(grad((120, 170, 255), (255, 200, 220), w, 700))
        pose(body, who, w // 2, 690, 2, 0.0)
        body.alpha_composite(grad((0, 0, 0), (0, 0, 0), w, 10), (0, 690))
        nm = text(name, 9, fill=INK, ring=None, shadow=False)
        body.alpha_composite(nm, (w - 50 - nm.width, 740))
        bi = text(bio, 5, fill=(90, 90, 110), ring=None, shadow=False)
        body.alpha_composite(bi, (w - 50 - bi.width, 880))
        im.paste(body, (0, 0), m)
        _c[key] = im
    return _c[key]


def match_card_at(t):
    for j in range(len(A_CARDS) - 1, -1, -1):
        if t >= A_CARDS[j][0]:
            return j
    return None


def match_frame(t):
    c = Image.new("RGBA", (W, H), INK + (255,))
    if t >= A_END:
        end_card(c, t - A_END)
        return c.convert("RGB")
    c.alpha_composite(grad((255, 244, 246), (255, 226, 232)))
    d = ImageDraw.Draw(c)
    d.rectangle((0, 180, W, 300), fill=WHITE)                    # the app bar
    paste(c, heart(7), W // 2 + 130, 240)
    paste(c, text("אחדות", 8, fill=PINK, ring=None, shadow=False), W // 2 - 40, 240)
    if t < A_SPLASH:                                             # the splash
        s = pop_scale(t, 0.05, 0.2, 0.3)
        if s:
            paste(c, scaled(heart(30), s), W // 2, 820)
        if t > 0.4:
            paste(c, text("אפליקציית ההיכרויות", 6, fill=(140, 90, 110), ring=None, shadow=False), W // 2, 1140)
            paste(c, text("לממשלות אחדות", 6, fill=(140, 90, 110), ring=None, shadow=False), W // 2, 1220)
        return c.convert("RGB")
    if A_RESULT <= t:
        u = t - A_RESULT
        paste(c, text("0", 40, fill=PINK, ring=None, shadow=False, rtl=False), W // 2, 760)
        paste(c, text("התאמות.", 10, fill=INK, ring=None, shadow=False), W // 2, 1060)
        if u > 1.2:
            slam(c, badge("צריך 61", 12), u, 1.2, W // 2, 1300, angle=-4, frm=2.4)
        return c.convert("RGB")
    if A_BRIDGE[0] <= t < A_BRIDGE[1]:
        paste(c, text("בינתיים,", 9, fill=INK, ring=None, shadow=False), W // 2, 800)
        paste(c, text("בקואליציה:", 9, fill=PINK, ring=None, shadow=False), W // 2, 920)
        return c.convert("RGB")
    j = match_card_at(t)
    t0, cid, viewer, verdict = A_CARDS[j]
    u = t - t0
    sw = A_SWIPE[cid]
    # who is swiping: a chip under the app bar
    av = S.avatar_round(viewer, 90)
    nm = P.LEAD[viewer][2]
    lab = text("מוצג ל: " + nm, 5, fill=INK, ring=None, shadow=False)
    paste(c, plate(lab.width + 150, 110, WHITE, (255, 210, 220), 4), W // 2, 380)
    paste(c, av, W // 2 + (lab.width + 150) // 2 - 70, 380)
    paste(c, lab, W // 2 - 40, 380)
    card = card_img(cid)
    land = ease_out(clamp(u / 0.25))
    cx, cy, ang = W // 2, 950 + int((1 - land) * 300), 0
    if u > sw:
        v = ease_inout(clamp((u - sw - 0.35) / 0.4))
        cx -= int(v * 1300)
        ang = 14 * v
    im = card.rotate(ang, resample=Image.BILINEAR, expand=True) if ang else card
    paste(c, im, cx, cy)
    if u > sw:                                                   # the verdict, stamped
        st = k.stamp_img(verdict, 12, color=(230, 40, 60))
        slam(c, st, u, sw, cx + 120, cy - 280, angle=12, frm=2.2)
    for bx, sym, col in ((W // 2 - 170, "X", (230, 60, 80)), (W // 2 + 170, None, PINK)):   # the buttons
        hot = sym == "X" and sw - 0.15 < u < sw + 0.35
        r = 92 if hot else 80
        d.ellipse((bx - r, 1560 - r, bx + r, 1560 + r), fill=WHITE, outline=(240, 200, 210), width=6)
        if sym:
            paste(c, text("X", 9, fill=col, ring=None, shadow=False, rtl=False), bx, 1560)
        else:
            paste(c, heart(9), bx, 1560)
    return c.convert("RGB")


def match_audio(path):
    m = P.Mix(A_DUR)
    music(m, "soundtrack.wav", 0.0, 0.0, A_END, -9)
    m.cue(0.05, "chatPing_D_default", -4)
    for t0, cid, viewer, verdict in A_CARDS:
        m.cue(t0, "critReact_D_whoosh", -9)
        m.cue(t0 + A_SWIPE[cid], "critReact_D_no", -4)
        m.cue(t0 + A_SWIPE[cid] + 0.05, "stamp", -5)
    m.cue(A_BRIDGE[0], "chatPing_D_default", -6)
    m.cue(A_RESULT, "cantAfford_D", -3)
    m.cue(A_RESULT + 1.2, "stamp_bell", -2)
    end_audio(m, A_END)
    m.write(path, 0.6)


# ============================================================================ 5. process (30 s)

R_DUR = 30.0
R_T0, R_STEP = 2.2, 5.9
R_ITEMS = [  # (headline lines, the ability, its note in two lines, the pose(s)): headlines from design/facts.json
    (["ינואר 2025: מפלגתו של", "בן גביר פרשה מהממשלה.", "מרץ 2025: חזרה."],
     "׳אני פורש׳", ("20 שניות בחוץ,", "ואז חוזר. זול יותר."), "ben-gvir-walkout", "ben-gvir-back"),
    (["מרץ 2026: התקציב אושר", "שעות לפני שהכנסת", "הייתה מתפזרת."],
     "׳תקציב בדקה ה־90׳", ("מאשרים ברגע האחרון.", "מקבלים יותר."), "smotrich-budget", None),
    (["2026: גולן השווה ממשלה", "עם נתניהו לדייט", "עם נוכל הטינדר."],
     "׳שמאלה׳", ("כל הצעת אחדות:", "החלקה."), "golan-swipe", None),
    (["ספטמבר 2026: ליברמן", "מוצג כראש הממשלה הבא."],
     "׳המסמך׳", ("כל ׳לא אשב׳", "כותב סעיף."), "liberman-document", None),
]
R_OUT = R_T0 + R_STEP * len(R_ITEMS)        # 25.8
R_END = R_DUR - END
PAPER = (236, 230, 214)


def paper_bg(c):
    if "paper" not in _c:
        p = Image.new("RGBA", (W, H), PAPER + (255,))
        d = ImageDraw.Draw(p)
        r = rnd("paper")
        for _ in range(2600):                                    # newsprint grain
            x, y = r.randrange(W), r.randrange(H)
            d.rectangle((x, y, x + 2, y + 2), fill=(222, 214, 196))
        _c["paper"] = p
    c.alpha_composite(_c["paper"])


def clipping(lines):
    key = ("clip", tuple(lines))
    if key not in _c:
        ts = [text(x, 6, fill=INK, ring=None, shadow=False) for x in lines]
        w = max(x.width for x in ts) + 100
        h = 130 + 78 * len(ts) + 40
        im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        d = ImageDraw.Draw(im)
        pts = [(0, 6)] + [(x, (x * 7) % 11) for x in range(0, w, 18)] + [(w, 4), (w, h - 6)] + \
              [(x, h - (x * 5) % 13) for x in range(w, 0, -18)] + [(0, h - 4)]
        d.polygon(pts, fill=(248, 246, 238))
        lab = text("חדשות", 5, fill=WHITE, ring=None, shadow=False)
        d.rectangle((40, 30, w - 40, 30 + lab.height + 8), fill=(40, 40, 40))   # the paper's masthead
        im.alpha_composite(lab, (w - 50 - lab.width, 34))
        for j, x in enumerate(ts):
            im.alpha_composite(x, (w - 50 - x.width, 110 + j * 78))
        _c[key] = im.rotate(-2, resample=Image.BICUBIC, expand=True)
    return _c[key]


def sticky(title, lines):
    key = ("sticky", title, lines)
    if key not in _c:
        lab = text("יכולת:", 5, fill=(110, 90, 30), ring=None, shadow=False)
        a = text(title, 6, fill=INK, ring=None, shadow=False)
        bs = [text(x, 5, fill=(60, 50, 20), ring=None, shadow=False) for x in lines]
        w = max([a.width, lab.width] + [x.width for x in bs]) + 80
        h = 150 + 64 * len(bs) + 30
        im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        d = ImageDraw.Draw(im)
        d.rectangle((6, 8, w - 1, h - 1), fill=(200, 180, 80))
        d.rectangle((0, 0, w - 7, h - 9), fill=(255, 226, 100))
        d.rectangle((w // 2 - 60, 0, w // 2 + 60, 24), fill=(230, 230, 220))   # tape
        im.alpha_composite(lab, (w - 40 - lab.width, 40))
        im.alpha_composite(a, (w - 40 - a.width, 86))
        for j, x in enumerate(bs):
            im.alpha_composite(x, (w - 40 - x.width, 168 + j * 64))
        _c[key] = im.rotate(3, resample=Image.BICUBIC, expand=True)
    return _c[key]


def harrow(c, x0, x1, y, u):
    """A dashed arrow pointing left (the reading direction)."""
    if u <= 0:
        return
    d = ImageDraw.Draw(c)
    xe = x0 - int((x0 - x1) * clamp(u))
    for x in range(x0, xe, -26):
        d.rectangle((x - 14, y - 5, x, y + 5), fill=(60, 60, 60))
    if u >= 1:
        d.polygon([(x1 + 10, y - 26), (x1 + 10, y + 26), (x1 - 20, y)], fill=(60, 60, 60))


def arrow(c, x, y0, y1, u):
    if u <= 0:
        return
    d = ImageDraw.Draw(c)
    ye = y0 + int((y1 - y0) * clamp(u))
    for y in range(y0, ye, 26):
        d.rectangle((x - 5, y, x + 5, y + 14), fill=(60, 60, 60))
    if u >= 1:
        d.polygon([(x - 26, y1 - 10), (x + 26, y1 - 10), (x, y1 + 20)], fill=(60, 60, 60))


def process_frame(t):
    c = Image.new("RGBA", (W, H), INK + (255,))
    if t >= R_END:
        end_card(c, t - R_END)
        return c.convert("RGB")
    paper_bg(c)
    paste(c, text("מהכותרת למכניקה", 10, fill=INK, ring=None, shadow=False), W // 2, 250)
    if t < R_T0:
        if t > 0.5:
            paste(c, text("כל יכולת במשחק", 8, fill=INK, ring=None, shadow=False), W // 2, 760)
            paste(c, text("מתחילה בכותרת אמיתית.", 8, fill=(200, 30, 40), ring=None, shadow=False), W // 2, 880)
        return c.convert("RGB")
    if t >= R_OUT:
        u = t - R_OUT
        paste(c, text("העובדות: עם מקור.", 9, fill=INK, ring=None, shadow=False), W // 2, 760)
        if u > 0.8:
            slam(c, k.stamp_img("הבדיחות: שלנו.", 10), u, 0.8, W // 2, 940, angle=-6, frm=2.2)
        return c.convert("RGB")
    j = int((t - R_T0) // R_STEP)
    u = t - R_T0 - j * R_STEP
    hl, ab, notes, p1, p2 = R_ITEMS[j]
    d = ImageDraw.Draw(c)
    for q in range(len(R_ITEMS)):                                # where we are: four dots
        x = W // 2 + 60 - q * 40
        d.rectangle((x - 10, 330, x + 10, 350), fill=(200, 30, 40) if q == j else (190, 182, 160))
    cl = clipping(hl)                                            # 1: the headline, across the top
    s = pop_scale(u, 0.1, 0.16, 1.3)
    if s:
        paste(c, scaled(cl, s), W // 2 + 10, 400 + cl.height // 2)
    yb = 440 + cl.height
    arrow(c, 800, yb, yb + 60, (u - 1.2) / 0.3)
    if u > 1.5:                                                  # 2: the note, on the right
        st = sticky(ab, notes)
        paste(c, scaled(st, pop_scale(u, 1.5, 0.14, 1.3)), 800, yb + 110 + st.height // 2)
    harrow(c, 600, 540, yb + 330, (u - 2.7) / 0.3)
    if u > 3.0:                                                  # 3: the game, on the left
        y0, x0, pw = yb + 90, 40, 480
        d.rectangle((x0, y0, x0 + pw, 1480), fill=INK)
        ph = 1476 - (y0 + 4)
        stg = k.stage("balfour", 6)
        crop = stg.crop((304, 1300 - ph, 304 + pw - 8, 1300))     # the residence, its lights, the gate
        c.alpha_composite(crop, (x0 + 4, y0 + 4))
        who = p2 if (p2 and u > 4.4) else p1
        pose(c, who, x0 + pw // 2, 1470, 2, u)
        flash(c, u, 3.0, 0.1, 0.5)
    return c.convert("RGB")


def process_audio(path):
    m = P.Mix(R_DUR)
    music(m, "soundtrack.wav", 0.0, 0.0, R_END, -10)
    for j in range(len(R_ITEMS)):
        t0 = R_T0 + j * R_STEP
        m.cue(t0 + 0.1, "slipStamp", -4)
        m.cue(t0 + 1.5, "slipStamp", -7)
        m.cue(t0 + 3.0, "leaderPick_D", -6)
        if R_ITEMS[j][5]:
            m.cue(t0 + 4.4, "critReact_D_land", -6)
    m.cue(R_OUT + 0.8, "stamp", -2)
    end_audio(m, R_END)
    m.write(path, 0.6)


# ============================================================================ render

REELS = {  # frame, audio, length, name, cover (the frame that sells it; also frames 0-1)
    "ghost": (ghost_frame, ghost_audio, G_DUR, "od-sevev-reel-ghost", G_T0 + 1 * G_STEP + 1.2),
    "patch": (patch_frame, patch_audio, N_DUR, "od-sevev-reel-patch", N_T0 + 6 * N_STEP + 0.9),
    "loading": (loading_frame, loading_audio, L_DUR, "od-sevev-reel-loading", 7.0),
    "match": (match_frame, match_audio, A_DUR, "od-sevev-reel-match", A_CARDS[2][0] + A_SWIPE["bibi3"] + 0.3),
    "process": (process_frame, process_audio, R_DUR, "od-sevev-reel-process", R_T0 + 4.0),
}


def main():
    P.SCRATCH = sys.argv[1]
    which = sys.argv[2]
    frame, audio, dur, name, cover_t = REELS[which]
    if "--stills" in sys.argv:
        ts = [round(x * (dur - 0.05) / 15, 2) for x in range(16)]
        ims = [frame(x).resize((216, 384)) for x in ts]
        sheet = Image.new("RGB", (8 * 220, 2 * 388), (30, 30, 30))
        for i, im in enumerate(ims):
            sheet.paste(im, ((i % 8) * 220, (i // 8) * 388))
        sheet.save(os.path.join(OUT, "_stills_%s.png" % which))
        return
    if "--one" in sys.argv:
        frame(float(sys.argv[sys.argv.index("--one") + 1])).save(os.path.join(OUT, "_one.png"))
        return
    wav = os.path.join(P.SCRATCH, "_reel_%s.wav" % which)
    audio(wav)
    video = os.path.join(OUT, name + ".mp4")
    cmd = [k.ffmpeg(), "-y", "-loglevel", "error",
           "-f", "rawvideo", "-pix_fmt", "rgb24", "-s", f"{W}x{H}", "-r", str(FPS), "-i", "-", "-i", wav,
           "-map", "0:v", "-map", "1:a", "-c:v", "libx264", "-preset", "slow", "-crf", "18", "-pix_fmt", "yuv420p",
           "-profile:v", "high", "-movflags", "+faststart",
           "-af", "loudnorm=I=-14:TP=-1.0:LRA=11,volume=2dB,alimiter=limit=0.89:level=false",
           "-c:a", "aac", "-b:a", "192k", "-ar", "48000", "-t", str(dur), video]
    p = subprocess.Popen(cmd, stdin=subprocess.PIPE)
    nf = int(dur * FPS)
    cover = frame(cover_t)
    cover.save(os.path.join(OUT, name + "-cover.png"))
    for i in range(nf):
        p.stdin.write((cover if i < 2 and which != "loading" else frame(i / FPS)).tobytes())
    p.stdin.close()
    if p.wait() != 0:
        raise SystemExit("ffmpeg failed")
    print(video)


if __name__ == "__main__":
    main()
