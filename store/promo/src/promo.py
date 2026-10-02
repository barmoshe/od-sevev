"""'עוד סבב': three Instagram promos, three formats (research, Oct 2026: game-style formats such as
character select and tier lists, the self-aware "fake mobile ad", and deadpan news gravity on
absurd things are what travels on Reels right now; captions burned in for sound-off).

    1  mivzak     "מבזק": Channel 61's news, anchored by Dubi the parrot (the game's own newsroom).
    2  select     "בחר ראש רשימה": a fighting-game character select with absurd stats, VS 61.
    3  fakead     "רק 1 מכל 100 מגיע ל־61!": a parody of the misleading mobile-game ad; every
                  choice fails, elections reset the board, and the real game is "worse. like reality."

All art, voices and stingers are the game's (store/teaser/src/teaser.py loads them); the gameplay
inserts are real Movie Maker frames (store/gameplay/plans, plan-bengvir.json, plan-liberman.json).
Copy: the game's own ticker lines where they fit (creative-pack/voice/copy-deck.md), new lines held
to creative-pack/voice/review-rubric.md (a named mechanism, the punch last, no quote marks on real
people, coalition and opposition roasted alike).

    python3 store/promo/src/promo.py <scratch dir with take_<leader>/, take1/, takeL/> mivzak|select|fakead [--stills]
"""
import math
import os
import subprocess
import sys
import wave

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "teaser", "src"))
import teaser as k  # noqa: E402
from teaser import (INK, NIGHT, NAVY, GOLD, GOLD_HI, GOLD_SH, WHITE, RED, PAPER, W, H, FPS, img, paste, scaled,  # noqa: E402
                    fade, overlay, text, plate, bubble, badge, slam, flash, pop_scale, clamp, ease_out, ease_inout,
                    char_frame, coins_burst, speedlines, burst_bg, shake, vignette, spotlight, rnd)

OUT = os.path.join(HERE, "..")
GAMEPLAY = os.path.join(HERE, "..", "..", "gameplay")
SCRATCH = None
SR = 48000

LEAD = {  # id: (sprite, avatar, name, party)
    "bibi": ("bibi", "bibi", "בנימין נתניהו", "הליכוד"),
    "bennett": ("bennett", "bennett", "נפתלי בנט", "ביחד"),
    "bengvir": ("ben-gvir", "ben-gvir", "איתמר בן גביר", "עוצמה יהודית"),
    "liberman": ("liberman", "liberman", "אביגדור ליברמן", "ישראל ביתנו"),
    "smotrich": ("smotrich", "smotrich", "בצלאל סמוטריץ׳", "הציונות הדתית"),
    "eisenkot": ("eisenkot", "eisenkot", "גדי אייזנקוט", "ישר"),
    "deri": ("deri", "deri", "אריה דרעי", "ש״ס"),
    "golan": ("golan", "golan", "יאיר גולן", "הדמוקרטים"),
}


# ---------------------------------------------------------------------------- footage + helpers

def take_dir(who):
    return os.path.join(SCRATCH, {"bengvir": "take1", "liberman": "takeL"}.get(who, "take_" + who))


_tf = {}


def take_frame(who, t):
    i = max(0, int(round(t * FPS)))
    kk = (who, i)
    if kk not in _tf:
        if len(_tf) > 24:
            _tf.clear()
        _tf[kk] = Image.open(os.path.join(take_dir(who), "f%08d.png" % i)).convert("RGBA")
    return _tf[kk]


def stage_shot(who, t, size, box=(0, 330, 1080, 1050)):
    """The leader on his stage, cropped from the capture (capture px box) and fitted to size."""
    fr = take_frame(who, t)
    kk = ("shot", who, int(round(t * FPS)), size, box)
    if kk not in _tf:
        _tf[kk] = fr.crop(box).resize(size, Image.LANCZOS)
    return _tf[kk]


def lines_block(lines, px, fill=WHITE, gap=10):
    ims = [text(s, px, fill=fill) for s in lines]
    w = max(i.width for i in ims)
    h = sum(i.height for i in ims) + gap * (len(ims) - 1)
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    y = 0
    for im in ims:
        out.alpha_composite(im, (w - im.width, y))   # right-aligned (Hebrew)
        y += im.height + gap
    return out


def grad_bg(c, top, bot):
    key = ("grad", top, bot)
    if key not in _tf:
        g = Image.new("RGBA", (1, 256))
        for y in range(256):
            u = y / 255
            g.putpixel((0, y), tuple(int(top[i] + (bot[i] - top[i]) * u) for i in range(3)) + (255,))
        _tf[key] = g.resize((W, H), Image.BILINEAR)
    c.alpha_composite(_tf[key])


def music_seg(path, at, dur):
    w = wave.open(path)
    sr, ch = w.getframerate(), w.getnchannels()
    w.setpos(int(at * sr))
    a = np.frombuffer(w.readframes(int(dur * sr) + 1), np.int16).astype(np.float32) / 32768
    if ch == 2:
        a = a.reshape(-1, 2).mean(1)
    n = int(len(a) * SR / sr)
    return np.interp(np.linspace(0, len(a) - 1, n), np.arange(len(a)), a).astype(np.float32)


class Mix:
    def __init__(self, dur):
        self.n = int(dur * SR)
        self.bus = np.zeros(self.n, np.float32)

    def put(self, t, a, gain_db=0.0):
        i = int(t * SR)
        if i >= self.n or i < 0:
            return
        a = a[: self.n - i]
        self.bus[i:i + len(a)] += a * (10 ** (gain_db / 20))

    def cue(self, t, name, gain_db=0.0):
        self.put(t, k.load_wav(name), gain_db)

    def duck(self, t0, t1, db_=-10, ramp=0.06):
        i0, i1, r = int(t0 * SR), int(t1 * SR), int(ramp * SR)
        g = np.ones(self.n, np.float32)
        lo = 10 ** (db_ / 20)
        g[max(0, i0):min(self.n, i1)] = lo
        for i in range(r):
            u = i / r
            if 0 <= i0 - r + i < self.n:
                g[i0 - r + i] = 1 + (lo - 1) * u
            if 0 <= i1 + i < self.n:
                g[i1 + i] = lo + (1 - lo) * u
        return g

    def write(self, path, fade_out=0.4):
        f = int(fade_out * SR)
        self.bus[-f:] *= np.linspace(1, 0, f)
        self.bus /= max(1e-6, np.abs(self.bus).max()) / 0.95
        with wave.open(path, "wb") as w:
            w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
            w.writeframes((self.bus * 32767).astype(np.int16).tobytes())


def dubi_says(mix, t, phrase, blips=6):
    """Dubi 'reads' a line: a squawk, then a run of his blips (the game's voice for him)."""
    mix.cue(t, "dubiSquawk_D_up", -5)
    names = ["dubiBlip_D_5_5", "dubiBlip_D_3_6", "dubiBlip_D_5_6", "dubiBlip_D_1_6", "dubiBlip_D_3_5", "dubiBlip_D_b7_5"]
    for j in range(blips):
        mix.cue(t + 0.12 + j * 0.085, names[(j + len(phrase)) % len(names)], -7)
    mix.cue(t + 0.12 + blips * 0.085 + 0.05, "dubiSquawk_D_down", -6)


def end_card(c, tt, line, cta=None, seed=5):
    """The shared sign-off: velvet, the wordmark, a line, the badge, the handle."""
    k.curtain(c, 0, dim=0.15)
    spotlight(c, W // 2, 0, 1400, 90, 480, 0.2, GOLD_HI)
    vignette(c)
    coins_burst(c, tt, 0, W // 2, 760, n=50, seed=seed, life=2.0, kinds=("coin", "coin", "slip", "bill"))
    s = pop_scale(tt, 0, 0.18, 0.2)
    if s:
        paste(c, scaled(img("wordmark", 6), s), W // 2, 330)
    if tt >= 0.3:
        paste(c, text(line, 8), W // 2, 540)
    if tt >= 0.8:
        slam(c, badge("בקרוב"), tt, 0.8, W // 2, 790, angle=-4, frm=2.4)
    if tt >= 1.3:
        h = text("@od.sevev", 8)
        paste(c, plate(h.width + 50, h.height + 26, INK, INK, 6), W // 2, 1010)
        paste(c, h, W // 2, 1010)
    if cta and tt >= 1.7:
        paste(c, text(cta, 6, fill=GOLD_HI), W // 2, 1130)
    if tt >= 1.9:
        paste(c, text("סאטירה. לא מטעם אף מפלגה.", 5, fill=(190, 196, 220)), W // 2, 1230)
    flash(c, tt, 0, 0.16, 1.0)


# ============================================================================ 1. מבזק

M_DUR = 24.0
M_ITEMS = [  # (leader, headline line 1, line 2, Dubi's doubled talking point); the game's ticker lines
    ("bennett", "בנט חתם על התחייבות חדשה.", "הפעם בעיפרון.", "ביחד! ביחד!"),
    ("smotrich", "המע״מ עלה ל־18%.", "באוצר חגגו בשקט. יש כסף. לא לך.", "לא לך! לא לך!"),
    ("liberman", "ליברמן הציג את הקווים האדומים שלו.", "זה פשוט דף אדום.", "לא אשב! לא אשב!"),
    ("deri", "בג״ץ סגר לדרעי את הדלת.", "דרעי מדד את החלון.", "מסדרון! מסדרון!"),
    ("eisenkot", "במטה של ישר תלו סרגל על הקיר.", "הקיר יושר.", "ישר! ישר!"),
    ("bibi", "20:00, הצהרה דרמטית:", "יש כובע.", "אין כלום! אין כלום!"),
]
M_T0 = 3.3
M_STEP = 2.9
M_OUT = M_T0 + M_STEP * len(M_ITEMS)        # 20.7: "ובחדשות אחרות"
M_END = 22.2
M_TICKER = ("גולן הציע איחוד. הצד השני עוד לא הבין שהוא צד.  ·  בן גביר איים לפרוש. הלשכה עדכנה את "
            "לוח הזמנים.  ·  הקוטג׳ איבד פיקסל.  ·  הדיון נדחה. הנימוק יימסר בדיון הבא.  ·  ")


def m_item(t):
    i = int((t - M_T0) // M_STEP)
    return (i, t - M_T0 - i * M_STEP) if 0 <= i < len(M_ITEMS) and t >= M_T0 else (None, None)


def m_studio(c, t):
    grad_bg(c, (10, 16, 46), (24, 40, 104))
    d = ImageDraw.Draw(c)
    for j in range(9):                                   # the set's light bars
        x = (j * 140 + t * 40) % (W + 200) - 100
        d.rectangle((x, 230, x + 6, 1120), fill=(40, 70, 160, 255))
    spotlight(c, 540, 0, 1500, 60, 520, 0.12, (150, 190, 255))
    # the channel bug and the countdown chip
    paste(c, plate(250, 76, RED, INK, 6), 175, 165)
    paste(c, text("ערוץ 61", 6), 175, 165)
    chip = text("בחירות: 27.10", 5, fill=GOLD_HI)       # a date, not a countdown that goes stale
    paste(c, plate(chip.width + 40, 66, NIGHT, GOLD_SH, 5), W - 40 - (chip.width + 40) // 2, 165)
    paste(c, chip, W - 40 - (chip.width + 40) // 2, 165)


def m_cottage(c, t):
    """The cottage index: the game's cup loses a pixel as the news gets worse."""
    f = min(12, int(t / M_DUR * 13))
    sheet = img("cottage_cup", 6)
    fw = 16 * 6
    cup = sheet.crop((f * fw, 0, f * fw + fw, sheet.height))
    paste(c, plate(250, 160, NIGHT, GOLD_SH, 5), 165, 1090)
    paste(c, text("מדד הקוטג׳", 4, fill=GOLD_HI), 165, 1040)
    paste(c, cup, 110, 1110)
    pct = text("-%d%%" % (f * 3) if f else "0%", 5, fill=(255, 120, 120) if f else WHITE, rtl=False)
    paste(c, pct, 225, 1110)


def m_monitor(c, t):
    """The video wall: the story's footage, a LIVE tag."""
    x0, y0, mw, mh = 135, 270, 810, 540
    d = ImageDraw.Draw(c)
    d.rectangle((x0 - 14, y0 - 14, x0 + mw + 13, y0 + mh + 13), fill=GOLD_SH)
    d.rectangle((x0 - 8, y0 - 8, x0 + mw + 7, y0 + mh + 7), fill=INK)
    i, u = m_item(t)
    if i is None:
        # before the first story: the hemicycle, empty, and the countdown
        d.rectangle((x0, y0, x0 + mw, y0 + mh), fill=(16, 30, 80))
        hemicycle(c, x0 + mw // 2, y0 + mh // 2 + 40, 9, filled=min(60, int(max(0, t - 0.6) * 40)))
        paste(c, text("בחירות! בחירות!", 7, fill=GOLD_HI), x0 + mw // 2, y0 + 70)
    else:
        who = M_ITEMS[i][0]
        sh = stage_shot(who, 4.6 + u, (mw, mh))
        c.alpha_composite(sh, (x0, y0))
        u2 = (t - M_T0 - i * M_STEP) / 0.12
        if u2 < 1:                                          # a cut flash on the wall only
            c.alpha_composite(Image.new("RGBA", (mw, mh), (255, 255, 255, int(150 * (1 - u2)))), (x0, y0))
    paste(c, plate(200, 54, RED, INK, 4), x0 + 115, y0 + 45)
    paste(c, text("שידור חי", 4), x0 + 115, y0 + 45)


def m_dubi(c, t):
    talking = False
    i, u = m_item(t)
    if i is not None and 0.75 <= u < 2.2:
        talking = True
    if 1.4 <= t < 3.2 or M_OUT + 0.2 <= t < M_END:
        talking = True
    a = k.SPRITES["chars"]["dubi-mic"]["anims"]["talk" if talking else "idle"]
    fr, anc = char_frame("dubi-mic", "talk" if talking else "idle", int(t * a["fps"]) % a["frames"], 2)
    paste(c, fr, 830 - anc[0] * 2, 1330 - anc[1] * 2 + 60, "tl")
    # the desk in front of him
    d = ImageDraw.Draw(c)
    d.rectangle((560, 1190, 1080, 1340), fill=INK)
    d.rectangle((566, 1196, 1080, 1334), fill=(30, 52, 130))
    d.rectangle((566, 1196, 1080, 1212), fill=GOLD)
    paste(c, text("ערוץ 61", 5, fill=GOLD_HI), 820, 1275)
    # his line, doubled, in a bubble
    line = None
    if i is not None and 0.75 <= u < 2.6:
        line, t0 = M_ITEMS[i][3], M_T0 + i * M_STEP + 0.75
    elif 1.4 <= t < 3.2:
        line, t0 = "בחירות! בחירות!", 1.4
    elif M_OUT + 0.2 <= t < M_END:
        line, t0 = "עוד סבב! עוד סבב!", M_OUT + 0.2
    if line:
        b = bubble(line, 6)
        paste(c, scaled(b, pop_scale(t, t0, 0.12, 1.4)), 440, 900)


def m_lower_third(c, t):
    i, u = m_item(t)
    if i is not None:
        l1, l2 = M_ITEMS[i][1], M_ITEMS[i][2]
        t0 = M_T0 + i * M_STEP
    elif M_OUT <= t < M_END:
        l1, l2, t0, u = "ובחדשות אחרות:", "הבחירות לא נגמרות.", M_OUT, t - M_OUT
    elif 1.4 <= t < M_T0:
        l1, l2, t0, u = "דובי", "מגיש ראשי. וגם יחיד.", 1.4, t - 1.4
    else:
        return
    wipe = ease_out(clamp(u / 0.18))
    d = ImageDraw.Draw(c)
    y0 = 1430
    xr = W - 30
    wdt = int((W - 60) * wipe)
    d.rectangle((xr - wdt, y0, xr, y0 + 170), fill=WHITE)
    d.rectangle((xr - wdt, y0, xr, y0 + 8), fill=RED)
    tab = text("מבזק" if i is not None else "ערוץ 61", 6)
    paste(c, plate(tab.width + 40, 74, RED, INK, 5), xr - (tab.width + 40) // 2, y0 - 34)
    paste(c, tab, xr - (tab.width + 40) // 2, y0 - 34)
    if u > 0.18:
        a = text(k.typed(l1, t, t0 + 0.18, 60), 6, fill=INK, ring=None, shadow=False)
        paste(c, a, xr - 30 - a.width // 2, y0 + 58)
    if u > 0.55:
        b = text(k.typed(l2, t, t0 + 0.55, 60), 6, fill=RED, ring=None, shadow=False)
        paste(c, b, xr - 30 - b.width // 2, y0 + 122)


def m_ticker(c, t):
    """The crawl, above the Reels caption zone; Hebrew crawls left to right."""
    d = ImageDraw.Draw(c)
    d.rectangle((0, 1346, W, 1398), fill=GOLD)
    s = text(M_TICKER * 2, 4, fill=INK, ring=None, shadow=False)
    x = -s.width // 2 + (t * 160) % (s.width // 2)
    paste(c, s, x, 1350, "tl")


def m_sting(c, t):
    burst_bg(c, t, (120, 18, 32), RED)
    speedlines(c, t, a=0.25)
    dx, dy = shake(t, [(0.35, 30, 0.4)])
    slam(c, badge("מבזק", 22), t, 0.3, W // 2 + dx, 860 + dy, angle=-3, frm=3.0)
    if t >= 0.75:
        paste(c, text("ערוץ 61 · מהדורה מיוחדת", 7), W // 2, 1180)
    flash(c, t, 0.3, 0.12, 0.9)


def mivzak_frame(t):
    c = Image.new("RGBA", (W, H), INK + (255,))
    if t < 1.3:
        m_sting(c, t)
    elif t < M_END:
        m_studio(c, t)
        m_monitor(c, t)
        m_cottage(c, t)
        m_dubi(c, t)
        m_ticker(c, t)
        m_lower_third(c, t)
        flash(c, t, 1.3, 0.12, 0.8)
    else:
        end_card(c, t - M_END, "החדשות. כמשחק.", seed=11)
    return c.convert("RGB")


def mivzak_audio(path):
    m = Mix(M_DUR)
    bed = k.load_wav("music_knesset_L0") + k.load_wav("music_knesset_L1")
    m.put(1.2, bed[: int((M_END - 1.2) * SR)], -9)
    m.cue(0.0, "stinger_dubiFlash_D", -1)
    m.cue(0.3, "stamp", -1)
    dubi_says(m, 1.45, "בחירות! בחירות!")
    for i, it in enumerate(M_ITEMS):
        t0 = M_T0 + i * M_STEP
        m.cue(t0 - 0.05, "critReact_D_whoosh", -4)
        m.cue(t0 + 0.2, "slipStamp", -6)
        dubi_says(m, t0 + 0.78, it[3])
    m.cue(M_OUT - 0.05, "critReact_D_whoosh", -4)
    dubi_says(m, M_OUT + 0.25, "עוד סבב! עוד סבב!", 7)
    m.cue(M_END, "stinger_motif_D", -1)
    m.cue(M_END + 0.8, "stamp", -2)
    m.write(path, 0.5)


# ============================================================================ 2. בחר ראש רשימה

GW_A0 = 34.10                     # Glitch Warfare's drop (bar 18); a bar is 1.808 s
BAR2 = 1.808
BEAT2 = BAR2 / 4
S_DUR = 16 * BAR2                 # 28.93 s
SELECT = [  # (id, stat 1, stat 2, special)
    ("bibi", ("שליפות מהכובע", 99), ("דחיות משפט", 100), "ארנב"),
    ("bennett", ("חתימות", 99), ("התחייבויות שנשארו", 3), "היפוך"),
    ("bengvir", ("העברות הודעה", 99), ("איומים לפרוש", 100), "איום"),
    ("liberman", ("סירובים", 100), ("ישיבה", 0), "לא מוחלט"),
    ("smotrich", ("חישובים", 99), ("כסף בשבילך", 0), "לא לך!"),
    ("eisenkot", ("יושר", 100), ("קסמים", 0), "אין. בלי קסמים."),
    ("deri", ("שיחות מסדרון", 99), ("משרדים", 0), "מהחלון"),
    ("golan", ("איחודים", 99), ("מה שנשאר לאחד", 1), "עוד איחוד"),
]
GRID = ["bibi", "bennett", "bengvir", "liberman", None, "smotrich", "eisenkot", "deri", "golan"]   # None = "?"


def s_cell(i):
    col, row = i % 3, i // 3
    return 540 + (1 - col) * 200, 1150 + row * 200     # RTL: the first cell on the right


def s_grid(c, t, sel, lit_all=False):
    for i, who in enumerate(GRID):
        x, y = s_cell(i)
        on = lit_all or i == sel
        d = ImageDraw.Draw(c)
        rim = GOLD if on else (60, 80, 150)
        if on and int(t * 8) % 2 and not lit_all:
            rim = GOLD_HI
        d.rectangle((x - 92, y - 92, x + 91, y + 91), fill=INK)
        d.rectangle((x - 86, y - 86, x + 85, y + 85), fill=rim)
        d.rectangle((x - 78, y - 78, x + 77, y + 77), fill=(20, 34, 90))
        if who:
            paste(c, img("avatar_pick_%s_d3" % LEAD[who][1], 1).resize((152, 152), Image.NEAREST), x, y)
        else:
            paste(c, text("?", 14, fill=GOLD_HI), x, y)
        if on and not lit_all:
            paste(c, plate(70, 44, RED, INK, 4), x + 60, y - 80)
            paste(c, text("P1", 4, rtl=False), x + 60, y - 80)


def s_bar(c, x_right, y, label, val, u):
    lab = text(label, 5)
    paste(c, lab, x_right - lab.width // 2, y)
    d = ImageDraw.Draw(c)
    bw = 430
    x0 = x_right - bw
    d.rectangle((x0 - 6, y + 34, x_right + 5, y + 74), fill=INK)
    fill = int(bw * val / 100 * ease_out(clamp(u / 0.5)))
    if fill:
        d.rectangle((x_right - fill, y + 40, x_right - 1, y + 68), fill=GOLD if val else RED)
    num = text(str(int(val * ease_out(clamp(u / 0.5)))), 5, fill=GOLD_HI, rtl=False)
    paste(c, num, x0 - 50, y + 54)


def s_panel(c, t, i, u):
    who, s1, s2, sp = SELECT[i]
    sprite, _, name, party = LEAD[who]
    burst_bg(c, t, (14, 24, 70), (24, 40, 110), cx=290, cy=760, n=14)
    d = ImageDraw.Draw(c)
    d.rectangle((0, 1030, W, H), fill=(8, 12, 36))
    a = k.SPRITES["chars"][sprite]["anims"]
    anim = "tap" if "tap" in a else "idle"
    fr, anc = char_frame(sprite, anim, int(u * a[anim]["fps"]) % a[anim]["frames"], 2)
    slide = (1 - ease_out(clamp(u / 0.2))) * -500
    paste(c, fr, 290 - anc[0] * 2 + slide, 1000 - anc[1] * 2, "tl")
    xr = 1040
    nm = text(name, 7, grad=True)
    paste(c, nm, xr - nm.width // 2 + int((1 - ease_out(clamp(u / 0.2))) * 500), 330)
    pt = text(party, 5, fill=(190, 200, 240))
    paste(c, pt, xr - pt.width // 2, 400)
    s_bar(c, xr, 470, s1[0], s1[1], u - 0.1)
    s_bar(c, xr, 590, s2[0], s2[1], u - 0.25)
    if u > 0.55:
        lab = text("מכה מיוחדת:", 5, fill=(190, 200, 240))
        paste(c, lab, xr - lab.width // 2, 730)
        spc = text(sp, 7, fill=GOLD_HI)
        paste(c, scaled(spc, pop_scale(u, 0.55, 0.12, 1.5)), xr - spc.width // 2, 800)


def s_title(c, t, line="בחר ראש רשימה", sub=None):
    tl = text(line, 8, grad=True)
    paste(c, plate(tl.width + 60, tl.height + 28, NIGHT, INK, 6), W // 2, 170)
    paste(c, tl, W // 2, 170)
    if sub:
        s = text(sub, 5)
        paste(c, s, W // 2, 250)


def select_frame(t):
    c = Image.new("RGBA", (W, H), INK + (255,))
    b = t / BAR2
    if b < 1:                                             # INSERT COIN
        burst_bg(c, t, (10, 14, 40), (20, 30, 80))
        slam(c, text("PLAYER 1", 10, fill=GOLD_HI, rtl=False), t, 0.0, W // 2, 620, frm=2.2)
        slam(c, text("בחר ראש רשימה", 11, grad=True), t, 0.45, W // 2, 820, frm=2.4)
        if int(t * 4) % 2:
            paste(c, text("הכנס מנדט כדי להתחיל", 6), W // 2, 1040)
        s_grid(c, t, -1)
        flash(c, t, 0.45, 0.1, 0.8)
    elif b < 9:                                           # the select loop, a bar each
        i = int(b - 1)
        u = t - BAR2 * (1 + i)
        s_panel(c, t, i, u)
        s_grid(c, t, GRID.index(SELECT[i][0]))
        s_title(c, t)
        flash(c, t, BAR2 * (1 + i), 0.06, 0.35)
    elif b < 10:                                          # the cursor lands on "?"
        burst_bg(c, t, (14, 24, 70), (24, 40, 110), cx=540, cy=700)
        u = t - BAR2 * 9
        roll = int(u * 14) % 9 if u < 1.2 else 4
        s_grid(c, t, roll)
        s_title(c, t, "בחירה אקראית...")
        if u >= 1.2:
            slam(c, text("הפתעה!", 12, fill=GOLD_HI), t, BAR2 * 9 + 1.2, W // 2, 700, frm=2.4)
    elif b < 12:                                          # VS
        u = t - BAR2 * 10
        d = ImageDraw.Draw(c)
        d.polygon([(0, 0), (W, 0), (W, 760), (0, 1160)], fill=(30, 50, 140))
        d.polygon([(0, 1160), (W, 760), (W, H), (0, H)], fill=(130, 20, 36))
        fr, anc = char_frame("mk-switcher", "idle", int(u * 8) % k.SPRITES["chars"]["mk-switcher"]["anims"]["idle"]["frames"], 2)
        sl = (1 - ease_out(clamp(u / 0.25))) * 600
        paste(c, fr, 760 - anc[0] * 2 + sl, 930 - anc[1] * 2, "tl")
        paste(c, text("אתה", 9), 760 + sl, 1000)
        hemicycle(c, 360 - sl, 1420, 7, filled=61)
        paste(c, text("61 מנדטים", 9), 360 - sl, 1640)
        slam(c, text("VS", 22, fill=GOLD_HI, rtl=False), t, BAR2 * 10 + 0.3, W // 2, 980, angle=-6, frm=3.0)
        if u > BAR2:
            slam(c, text("סבב ראשון. תתחילו.", 9, fill=WHITE), t, BAR2 * 11, W // 2, 200, frm=2.0)
        flash(c, t, BAR2 * 10 + 0.3, 0.12, 0.9)
    elif b < 14:                                          # the real game, a beat per leader
        j = int((t - BAR2 * 12) / BEAT2)
        who = SELECT[j % 8][0]
        u = t - BAR2 * 12 - j * BEAT2
        c.alpha_composite(stage_shot(who, 5.2 + u, (W, 1200), (0, 250, 1080, 1450)), (0, 300))
        flash(c, t, BAR2 * 12 + j * BEAT2, 0.06, 0.35)
        s_title(c, t, "זה משחק אמיתי.", "לוחצים. קונים. משלמים. 61.")
    else:                                                 # the sign-off: tag your friends
        tt = t - BAR2 * 14
        end_card(c, tt, "שמונה ראשי רשימה. 61 מקומות.", cta="תייגו את הליברמן של הקבוצה", seed=21)
    return c.convert("RGB")


def select_audio(path):
    m = Mix(S_DUR)
    m.put(0, music_seg(os.path.join(GAMEPLAY, "music", "glitch-warfare.wav"), GW_A0, S_DUR), -2)
    m.cue(0.0, "uiClick_D", -2)
    m.cue(0.45, "stamp", -4)
    for i in range(8):
        t0 = BAR2 * (1 + i)
        m.cue(t0, "uiClick_D", -1)
        m.cue(t0 + 0.55, "leaderPick_D", -9)
    for j in range(14):
        m.cue(BAR2 * 9 + j / 14, "uiClick_D", -8)
    m.cue(BAR2 * 9 + 1.2, "rabbitCrit_D_s150", -4)
    m.cue(BAR2 * 10 + 0.3, "stamp_bell", -2)
    m.cue(BAR2 * 11, "stamp", -3)
    for j in range(8):
        m.cue(BAR2 * 12 + j * BEAT2, k.tap_note(j % 8), -6)
    m.cue(BAR2 * 14, "stinger_motif_D", -2)
    m.write(path, 0.6)


# ============================================================================ 3. the fake ad

F_DUR = 26.0
SEATS = None


def hemicycle(c, cx, cy, sc, filled=60, red=(), lost=(), gone=(), t=0.0, pulse61=False):
    """The Knesset, from the game's own hemicycle map (120 seats, goal 61), at sc screen px per art px."""
    global SEATS
    if SEATS is None:
        SEATS = k.SPRITES["ui"]["hemicycle_fill"]["seats"]
    d = ImageDraw.Draw(c)
    x0, y0 = cx - 36 * sc, cy - 19 * sc
    for i, (x, y, w, h) in enumerate(SEATS):
        if i in gone:
            continue
        X, Y = x0 + x * sc, y0 + y * sc
        if i in lost:
            Y += lost[i]
        col = (50, 64, 120)
        if i < filled:
            col = GOLD
        if i in red:
            col = RED
        if pulse61 and i == 60 and i >= filled:
            col = GOLD_HI if int(t * 6) % 2 else (90, 110, 190)
        d.rectangle((X - 1, Y - 1, X + w * sc, Y + h * sc), fill=INK)
        d.rectangle((X, Y, X + w * sc - 1, Y + h * sc - 1), fill=col)


CHOICES = [  # (avatar, button label, what happens, seats it costs)
    ("bengvir", "לשלם לבן גביר", "בן גביר איים לפרוש.", 6),
    ("bennett", "לחתום על התחייבות", "ההתחייבות התהפכה.", 1),
    ("liberman", "להושיב את ליברמן", "לא יושב.", 0),
]
F_TRY = [3.0, 6.6, 10.2]          # each try: hand travels, taps at +0.9, result, fail at +1.9
F_ELECT = 13.8
F_REVEAL = 16.6
F_REAL = 19.0
F_END = 22.6


def f_button(c, x, y, who, label, t, t_press=None, red=False):
    pressed = t_press is not None and 0 <= t - t_press < 0.15
    b = img("button_%s_%s" % ("danger" if red else "gold", "pressed" if pressed else "default"), 1)
    # nine-slice-ish: stretch the 24x20 art to 820x150 (pixel scale 6)
    bw, bh = 820, 150
    im = b.resize((bw // 6, bh // 6), Image.NEAREST).resize((bw, bh), Image.NEAREST)
    paste(c, im, x, y + (6 if pressed else 0))
    if who:
        paste(c, img("avatar_pick_%s_d3" % LEAD[who][1], 1), x + 320, y - 4 + (6 if pressed else 0))
    lb = text(label, 7, fill=INK if not red else WHITE, ring=None if not red else INK, shadow=False)
    paste(c, lb, x - 50, y - 6 + (6 if pressed else 0))


def f_hand(c, x, y, press):
    sheet = img("ftue_hand", 8)
    fw = 18 * 8
    fr = sheet.crop(((1 if press else 0) * fw, 0, (1 if press else 0) * fw + fw, sheet.height))
    paste(c, fr, x - 7 * 8, y - 1 * 8, "tl")


def hand_path(t):
    """Where the hand is and whether it presses."""
    keys = [(1.8, (900, 1900), False)]
    for i, t0 in enumerate(F_TRY):
        bx, by = 540, 1180 + i * 190
        keys += [(t0 + 0.6, (bx + 120, by + 20), False), (t0 + 0.9, (bx + 120, by + 30), True),
                 (t0 + 1.1, (bx + 140, by + 60), False)]
    keys += [(F_ELECT + 0.5, (660, 1610), False), (F_ELECT + 0.8, (660, 1620), True),
             (F_ELECT + 1.1, (900, 1900), False)]
    keys += [(F_END + 1.0, (900, 1900), False), (F_END + 1.6, (640, 1460), False), (F_END + 1.9, (640, 1470), True),
             (F_END + 2.2, (700, 1560), False)]
    prev = (0, (900, 2100), False)
    for kt, pos, pr in keys:
        if t < kt:
            u = ease_inout(clamp((t - prev[0]) / max(1e-3, kt - prev[0])))
            return (prev[1][0] + (pos[0] - prev[1][0]) * u, prev[1][1] + (pos[1] - prev[1][1]) * u), pr and t > kt - 0.08
        prev = (kt, pos, pr)
    return prev[1], False


def f_board(c, t):
    """The Knesset stage behind, the bait banner, the seats, the choices, and what each one does."""
    st = k.stage("knesset", 6, dim=0.15)
    paste(c, st, 0, 0, "tl")
    overlay(c, NIGHT, 0.25)
    # the bait
    b1 = text("רק 1 מכל 100 מגיע ל־61!", 8, grad=True)
    paste(c, scaled(plate(b1.width + 60, b1.height + 34, RED, INK, 6), pop_scale(t, 0.1, 0.16, 1.6)), W // 2, 170)
    paste(c, scaled(b1, pop_scale(t, 0.1, 0.16, 1.6)), W // 2, 170)
    lvl = "שלב 61" if t < F_ELECT + 0.9 else "שלב 61. שוב."
    paste(c, plate(260, 66, NIGHT, GOLD_SH, 5), W // 2, 285)
    paste(c, text(lvl, 5, fill=GOLD_HI), W // 2, 285)
    # the seats: fill to 60 at the start, and again after the election
    fill_t = t if t < F_ELECT + 0.9 else t - (F_ELECT + 0.9)
    filled = min(60, int(max(0, fill_t - 0.4) * 45))
    red, lost, gone = set(), {}, set()
    for i, t0 in enumerate(F_TRY):
        u = t - (t0 + 1.0)
        nxt = F_TRY[i + 1] if i + 1 < len(F_TRY) else F_ELECT
        if u < 0 or t >= nxt:                              # "נסה שוב": the board resets to 60
            continue
        if i == 0:                                         # the threat: six seats fall
            for s in range(54, 60):
                red.add(s)
                lost[s] = int(max(0, u - 0.3) ** 2 * 2600)
        if i == 1:                                         # the pledge flips one seat
            red.add(59)
        if i == 2 and u > 0.1:                             # the 61st seat walks off
            gone.add(60)
    hemicycle(c, W // 2, 690, 12, filled=filled, red=red, lost=lost, gone=gone, t=t, pulse61=True)
    cnt = sum(1 for s in range(filled) if s not in red)
    paste(c, text("%d/61" % cnt, 8, fill=GOLD_HI if cnt < 61 else WHITE, rtl=False), W // 2, 990)
    # the choices
    if 2.0 <= t < F_REVEAL:
        for i, (who, label, _, _) in enumerate(CHOICES):
            y = 1180 + i * 190
            appear = pop_scale(t, 2.0 + i * 0.12, 0.14, 0.3)
            if appear:
                press = F_TRY[i] + 0.9
                f_button(c, W // 2, y, who, label, t, press)
        if t >= F_ELECT - 0.6:
            f_button(c, W // 2, 1180 + 3 * 190, None, "בחירות", t, F_ELECT + 0.8, red=True)
    # the result of each try, then the fail slam
    for i, t0 in enumerate(F_TRY):
        u = t - (t0 + 1.0)
        nxt = F_TRY[i + 1] if i + 1 < len(F_TRY) else F_ELECT
        if 0 <= u and t < nxt:
            who, _, what, _ = CHOICES[i]
            b = bubble(what, 7)
            paste(c, scaled(b, pop_scale(u, 0, 0.12, 1.4)), W // 2, 395)
        if 0.9 <= u and t < nxt:
            dx, dy = shake(t, [(t0 + 1.9, 26, 0.35)])
            slam(c, k.stamp_img("נכשלת!", 12), t, t0 + 1.9, W // 2 + dx, 760 + dy, angle=-8, frm=2.6)
            flash(c, t, t0 + 1.9, 0.14, 0.5, RED)
    if F_ELECT + 0.9 <= t < F_REVEAL:
        u = t - (F_ELECT + 0.9)
        slam(c, text("סבב 2", 12, grad=True), t, F_ELECT + 0.9, W // 2, 1090, frm=2.4)
        if u > 1.0:
            paste(c, bubble("אותו דבר.", 6), W // 2, 1250)
        flash(c, t, F_ELECT + 0.9, 0.16, 0.9)


def fakead_frame(t):
    c = Image.new("RGBA", (W, H), INK + (255,))
    if t < F_REVEAL:
        f_board(c, t)
    elif t < F_REAL:                                      # the twist
        u = t - F_REVEAL
        grad_bg(c, (8, 10, 26), (18, 24, 60))
        paste(c, text("רגע.", 10), W // 2, 640)
        if u > 0.5:
            paste(c, lines_block(["המשחק האמיתי", "לא נראה ככה."], 9), W // 2, 860)
        if u > 1.4:
            slam(c, text("הוא גרוע יותר.", 9, fill=GOLD_HI), t, F_REVEAL + 1.4, W // 2, 1110, frm=1.8)
        if u > 1.9:
            paste(c, text("כמו המציאות.", 7, fill=(190, 200, 240)), W // 2, 1230)
    elif t < F_END:                                       # the real thing, a beat per leader
        j = int((t - F_REAL) / 0.45)
        order = ["bibi", "liberman", "smotrich", "bennett", "deri", "golan", "bengvir", "eisenkot"]
        who = order[j % 8]
        u = t - F_REAL - j * 0.45
        c.alpha_composite(stage_shot(who, 5.6 + u, (W, 1200), (0, 250, 1080, 1450)), (0, 300))
        flash(c, t, F_REAL + j * 0.45, 0.06, 0.35)
        cap = text("זה המשחק. באמת.", 8, grad=True)
        paste(c, plate(cap.width + 60, cap.height + 28, NIGHT, INK, 6), W // 2, 170)
        paste(c, cap, W // 2, 170)
    else:                                                 # "play now" ... "soon"
        tt = t - F_END
        k.curtain(c, 0, dim=0.15)
        spotlight(c, W // 2, 0, 1400, 90, 480, 0.2, GOLD_HI)
        vignette(c)
        paste(c, scaled(img("wordmark", 6), pop_scale(tt, 0, 0.18, 0.2) or 0.01), W // 2, 360)
        paste(c, text("הבחירות שלא נגמרות", 8), W // 2, 570)
        pulse = 1 + 0.05 * math.sin(tt * 9) if tt < 1.9 else 1.0
        btn = scaled(img("button_gold_default", 1).resize((120, 30), Image.NEAREST).resize((720, 180), Image.NEAREST), pulse)
        paste(c, btn, W // 2, 1000)
        paste(c, scaled(text("שחק עכשיו", 9, fill=INK, ring=None, shadow=False), pulse), W // 2, 990)
        if tt >= 1.95:
            slam(c, badge("בקרוב"), tt, 1.95, W // 2, 1000, angle=-7, frm=2.6)
        if tt >= 2.4:
            h = text("@od.sevev", 8)
            paste(c, plate(h.width + 50, h.height + 26, INK, INK, 6), W // 2, 1250)
            paste(c, h, W // 2, 1250)
            paste(c, text("סאטירה. לא מטעם אף מפלגה.", 5, fill=(190, 196, 220)), W // 2, 1350)
        flash(c, tt, 0, 0.16, 1.0)
    if t < F_REVEAL or t >= F_END:
        pos, pr = hand_path(t)
        if pos[1] < H + 50:
            f_hand(c, pos[0], pos[1], pr)
    return c.convert("RGB")


def fakead_audio(path):
    m = Mix(F_DUR)
    bed = k.load_wav("music_balfour_L0") + k.load_wav("music_balfour_L1") + k.load_wav("music_balfour_L2")
    seg = bed[: int(F_REVEAL * SR)].copy()
    g = np.ones(len(seg), np.float32)
    for t0 in F_TRY:                                      # the music drops out on every fail
        a, b = int((t0 + 1.85) * SR), int((t0 + 2.6) * SR)
        g[a:b] = 0.15
    seg *= g
    m.put(0, seg, -8)
    for j in range(60):
        if j % 3 == 0:
            m.cue(0.4 + j / 45, "coin_D_a" if j % 2 else "coin_D_b", -14)
    for i, t0 in enumerate(F_TRY):
        m.cue(t0 + 0.9, "uiClick_D", 0)
        m.cue(t0 + 1.0, ["chatPing_D_benGvir", "chatPing_D_default", "critReact_D_no"][i], -4)
        m.cue(t0 + 1.9, "ultimatumZero_D", -1)
        m.cue(t0 + 1.9, "stamp", -3)
    m.cue(F_ELECT + 0.8, "uiClick_D", 0)
    m.cue(F_ELECT + 0.9, "stinger_fanfare_D_t0", -2)
    for j in range(20):
        m.cue(F_ELECT + 1.4 + j / 45 * 3, "coin_D_a", -16)
    m.cue(F_REVEAL, "suitcaseMiss_D", -4)
    real = k.load_wav("music_knesset_L0") + k.load_wav("music_knesset_L1") + k.load_wav("music_knesset_L2")
    m.put(F_REAL, real[: int((F_END - F_REAL) * SR)], -8)
    for j in range(8):
        m.cue(F_REAL + j * 0.45, k.tap_note(j), -6)
    m.cue(F_END, "stinger_motif_D", -2)
    m.cue(F_END + 1.9, "uiClick_D", 0)
    m.cue(F_END + 1.95, "stamp_bell", -1)
    m.write(path, 0.5)


# ============================================================================ render

VIDEOS = {  # (frame, audio, length, name, cover time): each cover is the frame that tells its joke
    "mivzak": (mivzak_frame, mivzak_audio, M_DUR, "od-sevev-promo-mivzak", M_T0 + 5 * M_STEP + 1.9),
    "select": (select_frame, select_audio, S_DUR, "od-sevev-promo-select", BAR2 * 4 + 1.5),
    "fakead": (fakead_frame, fakead_audio, F_DUR, "od-sevev-promo-fakead", F_TRY[0] + 2.6),
}


def main():
    global SCRATCH
    SCRATCH = sys.argv[1]
    which = sys.argv[2]
    frame, audio, dur, name, cover_t = VIDEOS[which]
    if "--stills" in sys.argv:
        ts = [round(x * dur / 23, 2) for x in range(24)]
        k.frame = frame
        k.OUT = OUT
        k.stills(ts, os.path.join(OUT, "_stills_%s.png" % which))
        return
    if "--one" in sys.argv:
        from safefit import fit
        fit(frame(float(sys.argv[sys.argv.index("--one") + 1]))).save(os.path.join(OUT, "_one.png"))
        return
    wav = os.path.join(SCRATCH, "_%s.wav" % which)
    audio(wav)
    video = os.path.join(OUT, name + ".mp4")
    cmd = [k.ffmpeg(), "-y", "-loglevel", "error",
           "-f", "rawvideo", "-pix_fmt", "rgb24", "-s", f"{W}x{H}", "-r", str(FPS), "-i", "-", "-i", wav,
           "-map", "0:v", "-map", "1:a", "-c:v", "libx264", "-preset", "slow", "-crf", "18", "-pix_fmt", "yuv420p",
           "-profile:v", "high", "-movflags", "+faststart", "-af", "loudnorm=I=-14:TP=-1.0:LRA=11",
           "-c:a", "aac", "-b:a", "192k", "-ar", "48000", "-t", str(dur), video]
    p = subprocess.Popen(cmd, stdin=subprocess.PIPE)
    nf = int(dur * FPS)
    from safefit import fit             # inside Instagram's safe area (store/promo/src/safefit.py)
    cover = fit(frame(cover_t))         # also frames 0-1, so the feed's first frame is the cover
    cover.save(os.path.join(OUT, name + "-cover.png"))
    for i in range(nf):
        p.stdin.write((cover if i < 2 else fit(frame(i / FPS))).tobytes())
        if i % 300 == 0:
            print(f"{which}: frame {i}/{nf}", flush=True)
    p.stdin.close()
    if p.wait() != 0:
        raise SystemExit("ffmpeg failed")
    print(video)


if __name__ == "__main__":
    main()
