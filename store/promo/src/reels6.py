"""'עוד סבב': five more Reels in five new looks (Oct 2026; 15 or 30 s, per Bar).

    doc      30 s  "עונת הקואליציה": a nature documentary. Letterbox, film grain, a narrator in subtitles,
                   a Latin name for each species: Ben Gvir migrates (out in January, back in March),
                   Deri's habitat is the corridor, Liberman marks territory with one call, Gantz waits.
    trailer  30 s  "עוד סבב: הטריילר": an action-trailer parody on Bar's Glitch Warfare. "בעולם / שבו
                   הבחירות / לא נגמרות", the drop, a montage of the real game, three plainly fake reviews.
    starter  15 s  "ערכת ראש רשימה למתחילים": the starter-pack meme, built from the leaders-v3 props.
                   "לא כלול: 61 מנדטים."
    family   30 s  "המשפחה": a family group chat, dark mode. Half the family is sure the game is the
                   left's, half the right's; the uncle and the aunt agree for the first time ("חשוד");
                   nobody will sit together at Friday dinner. "כמו בכנסת."
    search   15 s  "למה בישראל יש...": search autocomplete. Then "איך מגיעים ל־61": בלי ליברמן, בלי בן
                   גביר, בלי אף אחד.

Facts are the game's own (design/facts.json; five elections from April 2019 to November 2022, Ben Gvir's
party out in January 2025 and back in March, the 2020 rotation that never happened). The family, the
reviewers and the searches are invented and plainly so. No candidate in any opening frame (Instagram
doesn't recommend political content to non-followers), no polls, both camps roasted alike.

    python3 store/promo/src/reels6.py <scratch> doc|trailer|starter|family|search [--stills | --one <sec>]
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
import reels5 as R  # noqa: E402
import teaser as k  # noqa: E402
from teaser import (INK, NIGHT, GOLD, GOLD_HI, GOLD_SH, WHITE, RED, W, H, FPS, img, paste, scaled, text,  # noqa: E402
                    plate, bubble, badge, slam, flash, pop_scale, clamp, ease_out, ease_inout, char_frame,
                    coins_burst, vignette, spotlight, shake, speedlines, rnd)

OUT = P.OUT
END = R.END
grad, pose, end_card, end_audio, music = R.grad, R.pose, R.end_card, R.end_audio, R.music
_c = {}


def stage_crop(name, x, y, w, h, z=6):
    key = ("stc", name, x, y, w, h, z)
    if key not in _c:
        _c[key] = k.stage(name, z).crop((x, y, x + w, y + h))
    return _c[key]


# ============================================================================ 1. doc (30 s)

D_DUR = 30.0
D_INTRO = 2.8
D_STEP = 4.5
D_TOP, D_BOT = 300, 1500                    # the letterbox
D_SCENES = [  # (stage, pose, pose 2 at half time, species, Latin, narrator line 1, line 2)
    ("knesset", "ben-gvir-walkout", "ben-gvir-back", "בן גביר הנודד", "Itamarus migrans",
     "בינואר הוא עוזב את הממשלה.", "במרץ הוא חוזר. כמו הציפורים."),
    ("knesset", "deri-bench", None, "דרעי המצוי", "Aryeh corridorius",
     "בית הגידול שלו: המסדרון.", "שם, הרחק מהפרוטוקול, הכל נסגר."),
    ("knesset", "liberman-document", None, "ליברמן הנוקשה", "Avigdor non sedens",
     "הוא מסמן טריטוריה בקריאה אחת.", "׳לא אשב׳. ושוב. ושוב."),
    ("courthouse", "gantz", None, "גנץ הממתין", "Gantzus patiens",
     "הוא מחכה לרוטציה מאז 2020.", "ועדיין בודק את השעון."),
    ("balfour", "bibi-matchmaker", None, "נתניהו השורד", "Bibius perpetuus",
     "הוותיק מכולם שורד כל עונה,", "ובכל עונה מחפש שותף חדש."),
]
D_OUT = D_INTRO + D_STEP * len(D_SCENES)    # 25.3
D_END = D_DUR - 3.0


def grain(c, t):
    key = ("grain", int(t * 12) % 4)
    if key not in _c:
        r = np.random.default_rng(key[1] + 3)
        n = (r.random((H // 4, W // 4)) * 255).astype(np.uint8)
        g = Image.fromarray(n, "L").resize((W, H), Image.NEAREST)
        im = Image.new("RGBA", (W, H), (255, 236, 200, 0))
        im.putalpha(g.point(lambda v: 22 if v > 200 else 0))
        _c[key] = im
    c.alpha_composite(_c[key])


def subtitle(c, line, y, t, t0):
    if t < t0:
        return
    im = text(line, 6, fill=WHITE, ring=INK, shadow=True)
    paste(c, im, W // 2, y)


def doc_frame(t):
    c = Image.new("RGBA", (W, H), (0, 0, 0, 255))
    if t >= D_END:
        end_card(c, t - D_END)
        return c.convert("RGB")
    if t < D_INTRO:
        if t > 0.2:
            paste(c, text("עונת הקואליציה", 10, fill=(250, 236, 200), ring=None, shadow=False), W // 2, 860)
        if t > 0.8:
            paste(c, text("סדרת טבע. פרק 3.", 5, fill=(170, 160, 140), ring=None, shadow=False), W // 2, 980)
        if t > 1.4:
            subtitle(c, "פעם בכמה חודשים, הטבע מתעורר.", 1420, t, 1.4)
        grain(c, t)
        return c.convert("RGB")
    if t >= D_OUT:
        u = t - D_OUT
        paste(c, text("בפרק הבא:", 7, fill=(170, 160, 140), ring=None, shadow=False), W // 2, 860)
        if u > 0.5:
            paste(c, text("עוד סבב.", 10, fill=(250, 236, 200), ring=None, shadow=False), W // 2, 980)
        grain(c, t)
        return c.convert("RGB")
    j = int((t - D_INTRO) // D_STEP)
    u = t - D_INTRO - j * D_STEP
    stg, p1, p2, sp, lat, l1, l2 = D_SCENES[j]
    pan = int(u * 14)                                            # a slow pan, in whole pixels
    c.alpha_composite(stage_crop(stg, 0, 420, W, D_BOT - D_TOP).crop((0, 0, W, D_BOT - D_TOP)), (0, D_TOP))
    c.alpha_composite(stage_crop(stg, 0, 420, W, D_BOT - D_TOP), (-pan // 3, D_TOP))
    who = p2 if (p2 and u > D_STEP / 2) else p1
    pose(c, who, 560 - pan, 1330, 2, u)
    c.alpha_composite(Image.new("RGBA", (W, D_BOT - D_TOP), (255, 190, 120, 26)), (0, D_TOP))   # warm grade
    d = ImageDraw.Draw(c)
    d.rectangle((0, 0, W, D_TOP), fill=(0, 0, 0))
    d.rectangle((0, D_BOT, W, H), fill=(0, 0, 0))
    if u > 0.4:                                                  # the species card, lower right
        a = ease_out(clamp((u - 0.4) / 0.3))
        x = W - 40 - int((1 - a) * 300)
        nm = text(sp, 6, fill=WHITE, ring=INK)
        la = text(lat, 4, fill=(250, 220, 160), ring=INK, rtl=False)
        d.rectangle((x - max(nm.width, la.width) - 40, D_TOP + 60, x, D_TOP + 210), fill=(0, 0, 0, 255))
        d.rectangle((x - 8, D_TOP + 60, x, D_TOP + 210), fill=(250, 200, 90))
        paste(c, nm, x - 24 - nm.width // 2, D_TOP + 110)
        paste(c, la, x - 24 - la.width // 2, D_TOP + 172)
    subtitle(c, l1, D_BOT + 70, u, 0.6)
    subtitle(c, l2, D_BOT + 150, u, 2.2)
    if u < 0.25:
        c.alpha_composite(Image.new("RGBA", (W, H), (0, 0, 0, int(255 * (1 - u / 0.25)))))
    grain(c, t)
    return c.convert("RGB")


def doc_audio(path):
    m = P.Mix(D_DUR)
    music(m, "music_washington_L0", 0.0, 0.0, D_END, -8)
    for j in range(len(D_SCENES)):
        t0 = D_INTRO + j * D_STEP
        m.cue(t0 + 0.4, "slipStamp", -12)
        if D_SCENES[j][2]:
            m.cue(t0 + D_STEP / 2, "critReact_D_land", -8)
    end_audio(m, D_END)
    m.write(path, 0.6)


# ============================================================================ 2. trailer (30 s)

T_DUR = 30.0
T_BAR = 1.808                       # Glitch Warfare: a bar is 1.808 s; the drop lands on bar 8
T_A0 = 34.10 - 8 * T_BAR            # the track's time at video 0
T_DROP = 8 * T_BAR                  # 14.46
T_REV = 10 * T_BAR                  # the reviews
T_TITLE = 13 * T_BAR                # the title
T_END = T_DUR - 3.0
T_LB = 360                          # the letterbox
T_WORDS = [(0, "בעולם"), (1, "שבו הבחירות"), (2, "לא נגמרות")]
T_CUTS = [("bibi", 7.4), ("bennett", 10.8), ("deri", 14.2), ("liberman", 5.0),
          ("smotrich", 7.4), ("eisenkot", 10.6), ("golan", 7.4), ("bibi", 16.5)]
T_REVIEWS = [
    (5, "׳כמו המציאות. רק עם כפתור.׳", "דודה שלי"),
    (4, "׳שיחקתי סבב אחד. התפזרתי.׳", "השכן מהשלישית"),
    (5, "׳ראיתי את זה כבר חמש פעמים.׳", "כל המדינה"),
]


def star(on):
    key = ("star", on)
    if key not in _c:
        rows = ["...X...", "..XXX..", "XXXXXXX", ".XXXXX.", ".XX.XX.", "XX...XX"]
        im = Image.new("RGBA", (7, 6), (0, 0, 0, 0))
        for y, r in enumerate(rows):
            for x, ch in enumerate(r):
                if ch == "X":
                    im.putpixel((x, y), (GOLD_HI if on else (80, 80, 90)) + (255,))
        _c[key] = im.resize((70, 60), Image.NEAREST)
    return _c[key]


def trailer_frame(t):
    c = Image.new("RGBA", (W, H), (0, 0, 0, 255))
    if t >= T_END:
        end_card(c, t - T_END)
        return c.convert("RGB")
    b = t / T_BAR
    if b < 3:                                                    # the voice of every trailer
        for bi, w in T_WORDS:
            if bi <= b < bi + 1:
                slam(c, text(w, 11, fill=WHITE, ring=None, shadow=False), t, bi * T_BAR, W // 2, H // 2, frm=1.3, dur=0.18)
    elif b < 4:                                                  # the Knesset, wide
        u = t - 3 * T_BAR
        c.alpha_composite(stage_crop("knesset", 0, 300, W, H - 2 * T_LB), (0, T_LB))
        c.alpha_composite(Image.new("RGBA", (W, H), (0, 0, 0, int(255 * max(0, 1 - u / 0.5)))))
    elif b < 6:                                                  # eight leaders, one per beat
        u = t - 4 * T_BAR
        paste(c, text("שמונה ראשי רשימה.", 8, fill=WHITE, ring=None, shadow=False), W // 2, 700)
        for i, who in enumerate(P.LEAD):
            if u >= i * (T_BAR / 4):
                x = W - 135 - (i % 4) * 270
                y = 980 + (i // 4) * 280
                paste(c, scaled(R.S.avatar_round(who, 220), pop_scale(u, i * T_BAR / 4, 0.12, 1.4)), x, y)
    elif b < 7:                                                  # 60 of 61
        u = t - 6 * T_BAR
        P.hemicycle(c, W // 2, 1060, 11, filled=min(60, int(u * 60)), t=t, pulse61=True)
        paste(c, text("מנדט אחד חסר.", 8, fill=WHITE, ring=None, shadow=False), W // 2, 700)
    elif b < 8:
        if b > 7.25:
            paste(c, text("תמיד.", 11, fill=(250, 80, 80), ring=None, shadow=False), W // 2, H // 2)
    elif t < T_REV:                                              # the drop: the real game, one cut a beat
        i = int((t - T_DROP) / (T_BAR / 2))
        who, at = T_CUTS[i % len(T_CUTS)]
        u = t - T_DROP - i * T_BAR / 2
        sh = P.stage_shot(who, at + u, (W, 720))
        c.alpha_composite(sh, (0, H // 2 - 360))
        speedlines(c, t, a=0.18)
        flash(c, u, 0, 0.08, 0.7)
    elif t < T_TITLE:                                            # the reviews
        j = min(2, int((t - T_REV) / T_BAR))
        n, q, who = T_REVIEWS[j]
        u = t - T_REV - j * T_BAR
        for s_ in range(5):
            paste(c, star(s_ < n), W // 2 + 160 - s_ * 80, 760)
        paste(c, scaled(text(q, 7, fill=WHITE, ring=None, shadow=False), pop_scale(u, 0, 0.12, 1.2)), W // 2, 920)
        if u > 0.3:
            paste(c, text("— " + who, 5, fill=(170, 170, 180), ring=None, shadow=False), W // 2, 1040)
    else:                                                        # the title
        u = t - T_TITLE
        spotlight(c, W // 2, T_LB, H - T_LB, 80, 520, 0.18, GOLD_HI)
        s = pop_scale(u, 0, 0.2, 2.0)
        if s:
            paste(c, scaled(img("wordmark", 7), s), W // 2, 860)
        if u > 0.8:
            slam(c, badge("בקרוב", 12), u, 0.8, W // 2, 1110, angle=-4, frm=2.4)
        flash(c, u, 0, 0.12, 0.8)
    d = ImageDraw.Draw(c)
    d.rectangle((0, 0, W, T_LB), fill=(0, 0, 0))
    d.rectangle((0, H - T_LB, W, H), fill=(0, 0, 0))
    return c.convert("RGB")


def trailer_audio(path):
    m = P.Mix(T_DUR)
    music(m, "glitch-warfare.wav", T_A0, 0.0, T_END, -3)
    for bi, w in T_WORDS:
        m.cue(bi * T_BAR, "stamp", -6)
    m.cue(7.25 * T_BAR, "gavel_a", -4)
    for j in range(3):
        m.cue(T_REV + j * T_BAR, "slipStamp", -6)
    m.cue(T_TITLE, "stamp_bell", -2)
    m.cue(T_END + 0.6, "stamp", -2)
    m.write(path, 0.6)


# ============================================================================ 3. starter (15 s)

S_DUR = 15.0
S_T0, S_STEP = 0.9, 1.3
S_ITEMS = [  # (sprite, name, the small print)
    ("prop_pledge-scroll", "התחייבות חתומה", "בעיפרון"),
    ("prop_cardboard-box", "ארגז קרטון", "לפרישה. ולחזרה."),
    ("prop_corridor-bench", "ספסל", "המשרד האמיתי"),
    ("clock", "שעון", "לרוטציה. מאז 2020."),
    ("prop_budget-book", "תקציב", "נפתח בדקה ה־90"),
    ("prop_round-table", "שולחן עגול", "אין ראש. אין סוף."),
]
S_LAST = S_T0 + S_STEP * len(S_ITEMS) + 0.3     # "לא כלול"
S_END = S_DUR - END


def item_img(name):
    key = ("item", name)
    if key not in _c:
        if name == "clock":
            im = img("icon_clock").crop((0, 0, 9, 9))
        else:
            im = img(name)
        s = max(1, min(260 // im.width, 170 // im.height))
        _c[key] = im.resize((im.width * s, im.height * s), Image.NEAREST)
    return _c[key]


def starter_frame(t):
    c = Image.new("RGBA", (W, H), (250, 250, 246, 255))
    if t >= S_END:
        end_card(c, t - S_END)
        return c.convert("RGB")
    paste(c, text("ערכת ראש רשימה", 9, fill=INK, ring=None, shadow=False), W // 2, 250)
    paste(c, text("למתחילים", 7, fill=(200, 30, 40), ring=None, shadow=False), W // 2, 350)
    for i, (spr, nm, sub) in enumerate(S_ITEMS):
        t0 = S_T0 + i * S_STEP
        if t < t0:
            continue
        col, row = i % 2, i // 2
        x, y = (790 if col == 0 else 290), 560 + row * 300
        s = pop_scale(t, t0, 0.14, 1.5)
        im = item_img(spr)
        rot = im.rotate([-6, 4, -3, 5, -5, 3, 6, -4][i], resample=Image.NEAREST, expand=True)
        paste(c, scaled(rot, s), x, y)
        if t >= t0 + 0.2:
            a = text(nm, 6, fill=INK, ring=None, shadow=False)
            b = text(sub, 5, fill=(110, 110, 110), ring=None, shadow=False)
            paste(c, a, x, y + 120)
            paste(c, b, x, y + 178)
    if t >= S_LAST:
        slam(c, k.stamp_img("לא כלול: 61 מנדטים.", 8), t, S_LAST, W // 2, 1460, angle=-3, frm=2.2)
    return c.convert("RGB")


def starter_audio(path):
    m = P.Mix(S_DUR)
    music(m, "music_balfour_L0", 0.0, 0.0, S_END, -11)
    for i in range(len(S_ITEMS)):
        m.cue(S_T0 + i * S_STEP, "leaderPick_D", -8)
    m.cue(S_LAST, "stamp", -1)
    end_audio(m, S_END)
    m.write(path, 0.5)


# ============================================================================ 4. family (30 s)

F_DUR = 30.0
F_END = F_DUR - 3.0
PEOPLE = {  # name: (letter, colour)
    "דוד שמעון": ("ש", (250, 140, 80)),
    "דודה רינה": ("ר", (200, 120, 255)),
    "סבא": ("ס", (90, 200, 250)),
    "אמא": ("א", (250, 110, 150)),
}
F_MSGS = [  # (time, who, text); who None = me (Noa), "sys" = a system line, "img" = my screenshot
    (0.6, None, "שיחקתי בעוד סבב כל הלילה"),
    (1.6, "img", ""),
    (3.4, "דוד שמעון", "זה של השמאל?"),
    (5.0, "דודה רינה", "זה של הימין?"),
    (6.8, None, "זה צוחק על כולם"),
    (8.6, "סבא", "אז מי מממן את זה?"),
    (10.2, None, "אף אחד. זה חינם."),
    (11.8, "דוד שמעון", "חשוד."),
    (13.0, "דודה רינה", "חשוד מאוד."),
    (14.4, "sys", "לראשונה מאז 2019: שמעון ורינה הסכימו."),
    (16.6, "אמא", "יופי. מגיעים לארוחת שישי?"),
    (18.4, "דוד שמעון", "לא אשב ליד רינה."),
    (20.0, "סבא", "גם ליברמן אמר את זה."),
    (21.8, "אמא", "12 כיסאות. אף אחד לא מוכן לשבת."),
    (23.6, "אמא", "כמו בכנסת."),
]
F_TOP, F_BOTTOM = 330, 1380         # the chat's viewport


def avatar_letter(who, size=72):
    key = ("avl", who, size)
    if key not in _c:
        letter, col = PEOPLE[who]
        im = Image.new("RGBA", (size * 4, size * 4), (0, 0, 0, 0))
        ImageDraw.Draw(im).ellipse((0, 0, size * 4 - 1, size * 4 - 1), fill=col)
        im = im.resize((size, size), Image.LANCZOS)
        tx = text(letter, 5, fill=WHITE, ring=None, shadow=False)
        im.alpha_composite(tx, (size // 2 - tx.width // 2, size // 2 - tx.height // 2))
        _c[key] = im
    return _c[key]


def msg_img(who, body):
    key = ("msg", who, body)
    if key in _c:
        return _c[key]
    if who == "sys":
        tx = text(body, 5, fill=(220, 230, 235), ring=None, shadow=False)
        im = Image.new("RGBA", (tx.width + 50, tx.height + 30), (0, 0, 0, 0))
        ImageDraw.Draw(im).rounded_rectangle((0, 0, im.width - 1, im.height - 1), radius=18, fill=(24, 34, 40))
        im.alpha_composite(tx, (25, 15))
    elif who == "img":
        sh = P.stage_shot("bibi", 7.4, (460, 300))
        im = Image.new("RGBA", (480, 320), (0, 0, 0, 0))
        ImageDraw.Draw(im).rounded_rectangle((0, 0, 479, 319), radius=22, fill=(0, 92, 75))
        m = Image.new("L", (460, 300), 0)
        ImageDraw.Draw(m).rounded_rectangle((0, 0, 459, 299), radius=16, fill=255)
        im.paste(sh, (10, 10), m)
    else:
        mine = who is None
        tx = text(body, 6, fill=WHITE, ring=None, shadow=False)
        nm = None if mine else text(who, 4, fill=PEOPLE[who][1], ring=None, shadow=False)
        w = max(tx.width, nm.width if nm else 0) + 60
        h = tx.height + 44 + (nm.height + 10 if nm else 0)
        im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        ImageDraw.Draw(im).rounded_rectangle((0, 0, w - 1, h - 1), radius=26, fill=(0, 92, 75) if mine else (32, 44, 51))
        y = 22
        if nm:
            im.alpha_composite(nm, (w - 30 - nm.width, 16))
            y = 16 + nm.height + 10
        im.alpha_composite(tx, (w - 30 - tx.width, y))
    _c[key] = im
    return im


def family_frame(t):
    c = Image.new("RGBA", (W, H), (11, 20, 26, 255))
    if t >= F_END:
        end_card(c, t - F_END)
        return c.convert("RGB")
    d = ImageDraw.Draw(c)
    shown = [m for m in F_MSGS if t >= m[0]]
    # lay the messages out bottom-up from the input bar
    y = F_BOTTOM
    placed = []
    for tm, who, body in reversed(shown):
        im = msg_img(who, body)
        placed.append((tm, who, im, y - im.height))
        y -= im.height + 22
    for tm, who, im, top in placed:
        if top + im.height < F_TOP:
            continue
        a = ease_out(clamp((t - tm) / 0.18))
        dy = int((1 - a) * 40)
        if who == "sys":
            x = W // 2 - im.width // 2
        elif who is None or who == "img":
            x = W - 40 - im.width                                # mine: on the right (RTL)
        else:
            x = 140
            if top + im.height - 72 >= F_TOP:
                c.alpha_composite(avatar_letter(who), (40, top + im.height - 72 + dy))
        c.alpha_composite(im, (x, top + dy))
    # the header and the input bar, over the scroll
    d.rectangle((0, 0, W, F_TOP - 20), fill=(31, 44, 52))
    d.ellipse((W - 190, 210, W - 90, 310), fill=(90, 120, 110))
    paste(c, text("ה", 6, fill=WHITE, ring=None, shadow=False), W - 140, 260)
    hd = text("המשפחה", 7, fill=WHITE, ring=None, shadow=False)
    paste(c, hd, W - 230 - hd.width // 2, 236)
    mem = text("סבא, אמא, דוד שמעון, דודה רינה ועוד 43", 4, fill=(150, 170, 180), ring=None, shadow=False)
    paste(c, mem, W - 230 - mem.width // 2, 294)
    d.rectangle((0, F_BOTTOM + 20, W, 1540), fill=(11, 20, 26))
    d.rounded_rectangle((40, F_BOTTOM + 40, W - 160, F_BOTTOM + 130), radius=45, fill=(31, 44, 52))
    paste(c, text("הודעה", 5, fill=(130, 145, 155), ring=None, shadow=False), W - 260, F_BOTTOM + 85)
    d.ellipse((W - 140, F_BOTTOM + 40, W - 50, F_BOTTOM + 130), fill=(0, 168, 132))
    # who is typing
    nxt = [m for m in F_MSGS if m[0] > t]
    if nxt and nxt[0][0] - t < 0.7 and nxt[0][1] in PEOPLE:
        tp = text("%s מקליד/ה..." % nxt[0][1], 4, fill=(0, 200, 150), ring=None, shadow=False)
        d.rectangle((W - 900, 274, W - 210, 314), fill=(31, 44, 52))   # the typing line replaces the members
        paste(c, tp, W - 230 - tp.width // 2, 294)
    return c.convert("RGB")


def family_audio(path):
    m = P.Mix(F_DUR)
    music(m, "music_balfour_L0", 0.0, 0.0, F_END, -14)
    for tm, who, body in F_MSGS:
        if who is None or who == "img":
            m.cue(tm, "uiClick_D", -8)
        elif who == "sys":
            m.cue(tm, "stamp_bell", -6)
        else:
            m.cue(tm, "chatPing_D_default", -6)
    end_audio(m, F_END)
    m.write(path, 0.6)


# ============================================================================ 5. search (15 s)

Q_DUR = 15.0
Q_END = Q_DUR - END
Q_TURNS = [  # (start, typed, suggestions)
    (0.3, "למה בישראל יש", [" בחירות כל שנה", " 5 בחירות ב־4 שנים", " עוד סבב", " 120 ח״כים ואין 61"]),
    (6.2, "איך מגיעים ל־61", [" בלי ליברמן", " בלי בן גביר", " בלי אף אחד", " ? (אי אפשר)"]),
]
Q_TYPE = 1.2                        # typing time
Q_RESULT = 11.2


def search_frame(t):
    c = Image.new("RGBA", (W, H), (248, 249, 250, 255))
    if t >= Q_END:
        end_card(c, t - Q_END)
        return c.convert("RGB")
    d = ImageDraw.Draw(c)
    paste(c, text("חיפוש", 9, fill=(66, 133, 244), ring=None, shadow=False), W // 2, 380)
    j = 1 if t >= Q_TURNS[1][0] else 0
    t0, typed, sugg = Q_TURNS[j]
    u = t - t0
    shown = k.typed(typed, t, t0, len(typed) / Q_TYPE)
    d.rounded_rectangle((60, 500, W - 60, 620), radius=60, fill=WHITE, outline=(220, 222, 228), width=4)
    d.ellipse((110, 534, 152, 576), outline=(120, 124, 130), width=6)       # the magnifier
    d.line((146, 570, 170, 594), fill=(120, 124, 130), width=8)
    if shown:
        tx = text(shown, 6, fill=INK, ring=None, shadow=False)
        paste(c, tx, W - 110 - tx.width // 2, 560)
        if int(t * 3) % 2:
            d.rectangle((W - 116 - tx.width - 6, 532, W - 110 - tx.width - 6, 588), fill=INK)
    if u > Q_TYPE + 0.2 and t < Q_RESULT:                        # the suggestions
        d.rectangle((60, 640, W - 60, 640 + 130 * len(sugg)), fill=WHITE)
        for i, s_ in enumerate(sugg):
            if u < Q_TYPE + 0.2 + i * 0.35:
                continue
            y = 705 + i * 130
            a = text(typed, 5, fill=(110, 114, 120), ring=None, shadow=False)
            b = text(s_, 5, fill=INK, ring=None, shadow=False)
            paste(c, a, W - 110 - a.width // 2, y)
            paste(c, b, W - 110 - a.width - b.width // 2, y)
            d.ellipse((110, y - 18, 146, y + 18), outline=(170, 174, 180), width=5)
            if i < len(sugg) - 1:
                d.line((100, y + 65, W - 100, y + 65), fill=(236, 237, 240), width=2)
    if t >= Q_RESULT:                                            # the one result
        u2 = t - Q_RESULT
        d.rounded_rectangle((60, 680, W - 60, 1180), radius=30, fill=WHITE, outline=(220, 222, 228), width=3)
        paste(c, text("od.sevev · אינסטגרם", 4, fill=(32, 120, 60), ring=None, shadow=False, rtl=False), W - 300, 740)
        paste(c, text("עוד סבב: משחק", 8, fill=(26, 13, 171), ring=None, shadow=False), W - 120 - text("עוד סבב: משחק", 8).width // 2, 830)
        paste(c, text("אף אחד לא מגיע ל־61. אפשר לנסות.", 5, fill=(70, 74, 80), ring=None, shadow=False), W // 2 + 20, 950)
        paste(c, img("wordmark", 4), W // 2, 1080)
        if u2 > 0.6:
            slam(c, badge("בקרוב", 11), u2, 0.6, W // 2, 1340, angle=-4, frm=2.4)
    return c.convert("RGB")


def search_audio(path):
    m = P.Mix(Q_DUR)
    music(m, "music_balfour_L0", 0.0, 0.0, Q_END, -14)
    for t0, typed, sugg in Q_TURNS:
        for q in range(len(typed)):
            m.cue(t0 + q * Q_TYPE / len(typed), "uiClick_D", -14)
        for i in range(len(sugg)):
            m.cue(t0 + Q_TYPE + 0.2 + i * 0.35, "chatPing_D_default", -14)
    m.cue(Q_RESULT, "leaderPick_D", -6)
    m.cue(Q_RESULT + 0.6, "stamp", -2)
    end_audio(m, Q_END)
    m.write(path, 0.5)


# ============================================================================ render

REELS = {
    "doc": (doc_frame, doc_audio, D_DUR, "od-sevev-reel-doc", D_INTRO + 2.6),
    "trailer": (trailer_frame, trailer_audio, T_DUR, "od-sevev-reel-trailer", T_REV + 0.6),
    "starter": (starter_frame, starter_audio, S_DUR, "od-sevev-reel-starter", S_LAST + 0.6),
    "family": (family_frame, family_audio, F_DUR, "od-sevev-reel-family", 15.2),
    "search": (search_frame, search_audio, Q_DUR, "od-sevev-reel-search", Q_TURNS[1][0] + 3.0),
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
        p.stdin.write((cover if i < 2 else frame(i / FPS)).tobytes())
    p.stdin.close()
    if p.wait() != 0:
        raise SystemExit("ffmpeg failed")
    print(video)


if __name__ == "__main__":
    main()
