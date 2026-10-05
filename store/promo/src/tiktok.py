"""'עוד סבב' for TikTok: two videos and a photo carousel, laid out for TikTok's own safe area.

TikTok's UI covers more than Instagram's: the For You bar on top (about 150 px), the caption and
sound line at the bottom (about 450 px), and the like / comment / share column on the right (about
130 px, from y 700). So everything that matters sits in x 60-940, y 170-1450, and nothing is shrunk
with safefit: these are drawn for that box. The game is live, so every post ends on the address
(TikTok's link in bio needs 1,000 followers) instead of "בקרוב".

    guess   "נחשו מי זה": four leaders as black silhouettes of their ability pose, a clue each in
            the game's own ability copy, three seconds, the reveal; the other four stay dark ("את
            השאר תגלו במשחק"). Comment bait: "כמה ניחשתם?". 24 s. Blackout-safe (no seats).
    night   "עוד סבב אחד ואני הולך לישון.": the game on a phone in a dark bedroom, the clock jumps
            23:00 → 01:17 → 03:42 → 05:58, a new round and a new leader every time, the shekels
            growing; the window goes from moon to dawn, the 07:00 alarm. "קוראים לו עוד סבב. לא
            סתם." 16 s. The screen is drawn from the game's art (no recorded footage), and shows
            no seats, so it is blackout-safe.
    truth   "אמת או המצאה?": a photo-mode carousel, 12 slides (1080x1920 PNG). Five things that
            sound made up, each answered on the next slide with its source from design/facts.json;
            all five are true. Blackout-safe.

    python3 store/promo/src/tiktok.py guess|night|truth [--stills | --one <sec>]
"""
import math
import os
import subprocess
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import promo as P  # noqa: E402
import teaser as k  # noqa: E402
from teaser import (INK, NIGHT, NAVY, GOLD, GOLD_HI, GOLD_SH, WHITE, RED, PAPER, W, H, FPS, img, paste,  # noqa: E402
                    scaled, fade, text, plate, badge, slam, flash, pop_scale, clamp, ease_out, ease_inout,
                    char_frame, coins_burst, burst_bg, vignette, spotlight, stamp_img)

OUT = os.path.join(P.OUT, "tiktok")
URL = "od-sevev.bar-builds.com"
SAFE_W = 860                       # widest line: x 70-930, clear of the right-hand icons
LINEUP = ["bibi", "bennett", "ben-gvir", "liberman", "smotrich", "eisenkot", "deri", "golan"]
SOFT = (190, 196, 220)
GREEN = (64, 186, 96)


def wrap(s, px, width=SAFE_W, **kw):
    """Greedy word wrap in the game's lettering; returns the line images."""
    lines, cur = [], ""
    for word in s.split():
        trial = (cur + " " + word).strip()
        if cur and text(trial, px, **kw).width > width:
            lines.append(cur)
            cur = word
        else:
            cur = trial
    if cur:
        lines.append(cur)
    return [text(ln, px, **kw) for ln in lines]


def stack(c, ims, y, gap=14, x=W // 2):
    """Lines centred on x, the first one's centre at y; returns the y under the block."""
    for im in ims:
        paste(c, im, x, y)
        y += im.height + gap
    return y - ims[-1].height // 2 if ims else y


def bg_grad(top, bot):
    key = ("tt-grad", top, bot)
    if key not in k._cache:
        a = np.linspace(0, 1, H)[:, None, None]
        arr = (np.array(top)[None, None] * (1 - a) + np.array(bot)[None, None] * a).repeat(W, 1)
        k._cache[key] = Image.fromarray(arr.astype(np.uint8), "RGB").convert("RGBA")
    return k._cache[key].copy()


def end_card(c, tt):
    """launch.py's live end card, moved up into TikTok's safe area."""
    beat = 1.808 / 4
    k.curtain(c, 0, dim=0.15)
    spotlight(c, W // 2, 0, 1300, 90, 460, 0.2, GOLD_HI)
    vignette(c)
    s = pop_scale(tt, 0, 0.18, 0.2)
    if s:
        paste(c, scaled(img("wordmark", 6), s), W // 2, 300)
    if tt >= 0.2:
        paste(c, text("הבחירות שלא נגמרות", 8), W // 2, 470)
    n = len(LINEUP)
    for i, who in enumerate(LINEUP):
        t0 = 0.15 + i * beat / 3
        if tt < t0:
            continue
        rise = ease_out(clamp((tt - t0) / 0.22))
        a = k.SPRITES["chars"][who]["anims"]["idle"]
        fr, anc = char_frame(who, "idle", int((tt - t0) * a["fps"]) % a["frames"], 1)
        x = 125 + i * (790 / (n - 1))
        paste(c, fr, x - anc[0], 960 + int((1 - rise) * 260) - anc[1], "tl")
    tb = 0.15 + n * beat / 3
    if tt >= tb:
        slam(c, badge("עכשיו באוויר", 11), tt, tb, W // 2, 1080, angle=-4, frm=2.4)
        flash(c, tt, tb, 0.1, 0.5, GOLD_HI)
    if tt >= tb + beat:
        u = text(URL, 6, rtl=False)
        sc = pop_scale(tt, tb + beat, 0.14, 1.3)
        paste(c, scaled(plate(u.width + 56, u.height + 34, INK, GOLD, 6), sc), W // 2, 1250)
        paste(c, scaled(u, sc), W // 2, 1250)
    if tt >= tb + 2 * beat:
        paste(c, text("לשחק בחינם, בדפדפן. בלי הורדה.", 6, fill=GOLD_HI), W // 2, 1355)
        paste(c, text("סאטירה. לא מטעם אף מפלגה.", 4, fill=SOFT), W // 2, 1425)
    flash(c, tt, 0, 0.16, 1.0)


END_LEN = 3.2


def end_audio(m, t0):
    m.cue(t0, "leaderPick_D", -6)
    m.cue(t0 + 0.15 + 8 * 1.808 / 12, "stamp", -2)


def tone(freq, dur, decay=4.0, square=False):
    t = np.arange(int(dur * P.SR)) / P.SR
    s = np.sin(2 * np.pi * freq * t)
    if square:
        s = np.sign(s) * 0.5
    return (s * np.exp(-decay * t)).astype(np.float32)


def loop_music(m, name, t0, t1, db):
    a = k.load_wav(name)
    a = a if a.ndim == 1 else a.mean(1)
    a = np.tile(a, int((t1 - t0) * P.SR) // len(a) + 1)[: int((t1 - t0) * P.SR)].copy()
    f = int(0.4 * P.SR)
    a[-f:] *= np.linspace(1, 0, f)
    m.put(t0, a, db)


# ============================================================================ 1. נחשו מי זה

G_HOOK = 1.8
G_ROUND = 4.4
G_REVEAL = 3.0                      # within a round: 0.0-0.3 in, 0.3-3.0 the clock, then the reveal
G_ROUNDS = [  # (pose char, ability, clue from the game's copy, name)
    ("ben-gvir-walkout", "״אני פורש״", "פורש מהממשלה.|יחזור אחרי הצהריים.", "איתמר בן גביר"),
    ("golan-swipe", "״החלקה״", "נתניהו מציע אחדות.|הוא מחליק שמאלה.", "יאיר גולן"),
    ("liberman-document", "״המסמך״", "כל ״לא אשב״|כותב עוד סעיף.", "אביגדור ליברמן"),
    ("bennett-sign", "״לחתום״ ו״להפוך״", "חותם על התחייבות.|ואז הופך אותה.", "נפתלי בנט"),
]
G_REST = ["bibi-matchmaker", "smotrich-budget", "eisenkot-summit", "deri-bench"]
G_TEASE = G_HOOK + G_ROUND * len(G_ROUNDS)          # 19.4
G_END = G_TEASE + 2.6                               # 22.0
G_DUR = G_END + END_LEN                             # 25.2


def silhouette(char, scale, rgb=INK):
    key = ("tt-sil", char, scale, rgb)
    if key not in k._cache:
        fr, anc = char_frame(char, "pose", 0, scale)
        s = Image.new("RGBA", fr.size, rgb + (255,))
        s.putalpha(fr.getchannel("A").point(lambda v: 255 if v > 40 else 0))
        rim = s.getchannel("A").filter(ImageFilter.MaxFilter(9))
        out = Image.new("RGBA", fr.size, GOLD_HI + (0,))
        out.putalpha(rim.point(lambda v: int(v * 0.85)))
        out.alpha_composite(s)
        k._cache[key] = (out, anc)
    return k._cache[key]


def g_backdrop(c, t, lit):
    burst_bg(c, t * 0.4, (28, 44, 120) if not lit else (60, 70, 170), NIGHT, cx=W // 2, cy=1020, n=18)
    vignette(c)


def g_header(c, line, sub=None):
    im = text(line, 8, grad=True)
    paste(c, plate(im.width + 70, im.height + 34, NIGHT, INK, 6), W // 2, 250)
    paste(c, im, W // 2, 250)
    if sub:
        paste(c, text(sub, 5, fill=GOLD_HI), W // 2, 345)


def guess_frame(t):
    c = Image.new("RGBA", (W, H), INK + (255,))
    if t >= G_END:
        end_card(c, t - G_END)
        return c.convert("RGB")
    if t < G_HOOK:                                  # the hook: all four question marks
        g_backdrop(c, t, False)
        g_header(c, "נחשו מי זה", "לפי היכולת שלו במשחק")
        for i, (pose, *_rest) in enumerate(G_ROUNDS):
            sil, anc = silhouette(pose, 1)
            x = 190 + i * 233
            y = 1000 + int(math.sin(t * 4 + i) * 8)          # frame 0 is the whole hook: no rise
            paste(c, sil, x - anc[0], y - anc[1], "tl")
            q = text("?", 9, grad=True)
            paste(c, q, x, y - 330)
        paste(c, text("4 סבבים. 3 שניות לכל אחד.", 6, fill=WHITE), W // 2, 1180)
        return c.convert("RGB")
    if t < G_TEASE:
        i = int((t - G_HOOK) // G_ROUND)
        u = t - G_HOOK - i * G_ROUND
        pose, ability, clue, name = G_ROUNDS[i]
        revealed = u >= G_REVEAL
        g_backdrop(c, t, revealed)
        g_header(c, "נחשו מי זה", "%d/%d" % (i + 1, len(G_ROUNDS)))
        # the clue card slides in from the left
        x = W // 2 - int((1 - ease_out(clamp(u / 0.3))) * 1100)
        ab = text(ability, 8, grad=True)
        cl = [text(x, 6) for x in clue.split("|")]
        h = 60 + ab.height + 20 + sum(im.height + 10 for im in cl) + 30
        card = plate(880, h, NAVY, GOLD_SH, 6)
        top = 375
        paste(c, card, x, top + h // 2)
        paste(c, text("היכולת:", 4, fill=SOFT), x, top + 36)
        paste(c, ab, x, top + 50 + ab.height // 2 + 10)
        yy = top + 50 + ab.height + 30
        for im in cl:
            paste(c, im, x, yy + im.height // 2)
            yy += im.height + 10
        feet = 1385
        if not revealed:
            sil, anc = silhouette(pose, 2)
            sil = sil.resize((int(sil.width * 0.9), int(sil.height * 0.9)), Image.NEAREST)
            anc = (anc[0] * 0.9, anc[1] * 0.9)
            bob = int(math.sin(u * 3) * 6)
            paste(c, sil, W // 2 - anc[0] * 2, feet - anc[1] * 2 + bob, "tl")
            left = max(0.0, G_REVEAL - u)
            if u >= 0.3:                            # the clock: a draining bar and the seconds
                frac = clamp(left / (G_REVEAL - 0.3))
                d = ImageDraw.Draw(c)
                d.rectangle((170, 1405, 910, 1440), fill=INK)
                d.rectangle((176, 1411, 176 + int(728 * frac), 1434), fill=RED if left < 1 else GOLD)
                sec = text(str(int(math.ceil(left))), 9, grad=True, rtl=False)
                paste(c, scaled(sec, pop_scale(u, G_REVEAL - math.ceil(left), 0.12, 1.4) or 1), W // 2, 1490)
        else:
            v = u - G_REVEAL
            spotlight(c, W // 2, 560, feet + 10, 60, 300, 0.25, GOLD_HI)
            fr, anc = char_frame(pose, "pose", int(v * 2), 2)
            s = 0.9 * pop_scale(v, 0, 0.16, 1.25)
            im = scaled(fr, s)
            paste(c, im, W // 2 - anc[0] * 2 * s, feet - anc[1] * 2 * s, "tl")
            coins_burst(c, v, 0, W // 2, 900, n=26, seed=i + 3, life=1.3)
            nm = text(name, 9)
            sc = pop_scale(v, 0.05, 0.14, 1.6)
            paste(c, scaled(plate(nm.width + 60, nm.height + 30, RED, INK, 6), sc), W // 2, 1430)
            paste(c, scaled(nm, sc), W // 2, 1430)
            flash(c, u, G_REVEAL, 0.12, 0.8)
        return c.convert("RGB")
    # the tease: the other four stay dark
    u = t - G_TEASE
    g_backdrop(c, t, False)
    g_header(c, "ועוד ארבעה במשחק", "את השאר תגלו לבד")
    for i, pose in enumerate(G_REST):
        sil, anc = silhouette(pose, 1)
        x = 190 + i * 233
        y = 1020 + int((1 - ease_out(clamp((u - i * 0.1) / 0.3))) * 500)
        paste(c, sil, x - anc[0], y - anc[1], "tl")
        paste(c, text("?", 9, grad=True), x, y - 330)
    if u >= 0.8:
        slam(c, text("כמה ניחשתם? כתבו בתגובות.", 7, fill=GOLD_HI), u, 0.8, W // 2, 1240, frm=1.8)
    return c.convert("RGB")


def guess_audio(path):
    m = P.Mix(G_DUR)
    loop_music(m, "music_knesset_L0", 0.0, G_END, -9)
    m.cue(0.05, "leaderPick_D", -6)
    for i in range(len(G_ROUNDS)):
        t0 = G_HOOK + i * G_ROUND
        m.cue(t0, "slipStamp", -10)
        for s in range(3):                          # the clock: three ticks, the last one higher
            m.put(t0 + G_REVEAL - 3 + s + 0.02 if s else t0 + 0.32, tone(1400 if s < 2 else 1900, 0.09, 30), -10)
        m.cue(t0 + G_REVEAL, "stinger_milestone_E", -6)
        m.cue(t0 + G_REVEAL, "coin_E_a", -4)
    m.cue(G_TEASE, "fail_D", -8)
    m.cue(G_TEASE + 0.8, "stamp", -4)
    end_audio(m, G_END)
    m.write(path, 0.5)


# ============================================================================ 2. עוד סבב אחד ואני הולך לישון

N_SCREEN = (620, 603)               # the phone's screen: drawn from the game's art, no recorded footage
N_BEATS = [  # (start, clock, line, leader, stage, shekels from, to): a new round, a new leader, every hour
    (0.0, "23:00", "עוד סבב אחד|ואני הולך לישון.", "bennett", "knesset", 0, 1240),
    (3.0, "01:17", "עוד אחד. קטן.", "deri", "balfour", 48310, 61900),
    (5.4, "03:42", "זה האחרון. באמת.", "golan", "knesset", 2104000, 2650000),
    (7.8, "05:58", "טוב. עוד סבב.", "liberman", "balfour", 96200000, 99800000),
]
N_ALARM = 10.2
N_END = 13.0
N_DUR = N_END + END_LEN             # 16.2
NAMES = {"bennett": "נפתלי בנט", "deri": "אריה דרעי", "golan": "יאיר גולן", "liberman": "אביגדור ליברמן"}


def shekels(v):
    v = int(v)
    if v >= 1_000_000:
        return "%.2fM" % (v / 1_000_000)
    return "{:,}".format(v)


def taps(t0, t1):
    """The thumb's taps in a beat: a steady, slightly uneven rhythm (fixed seed, so it renders the same)."""
    rng = np.random.default_rng(int(t0 * 10) + 3)
    out, t = [], t0 + 0.15
    while t < t1 - 0.1:
        out.append((t, int(rng.integers(200, 420)), int(rng.integers(210, 380))))
        t += float(rng.uniform(0.17, 0.3))
    return out


def game_screen(b, t):
    """One frame of the game as a phone shows it: the stage, the leader tapping, the coins, the counter."""
    t0, _, _, who, stg, v0, v1 = N_BEATS[b]
    t1 = N_BEATS[b + 1][0] if b + 1 < len(N_BEATS) else N_ALARM
    sw, sh = N_SCREEN
    sc = Image.new("RGBA", (sw, sh), NIGHT + (255,))
    st = k.stage(stg, 4, 0.0)                               # 720x1280; the leader's mark at art (94, 219)
    sc.alpha_composite(st, (0, 0), (94 * 4 - sw // 2, 219 * 4 - 470, 94 * 4 + sw // 2, 219 * 4 - 470 + sh))
    tp = [x for x in taps(t0, t1) if x[0] <= t]
    last = tp[-1][0] if tp else -9
    a = k.SPRITES["chars"][who]["anims"]
    if t - last < 8 / a["tap"]["fps"]:
        fr, anc = char_frame(who, "tap", int((t - last) * a["tap"]["fps"]), 1)
    else:
        fr, anc = char_frame(who, "idle", int(t * a["idle"]["fps"]), 1)
    z = 4 / 3
    fr = fr.resize((int(fr.width * z), int(fr.height * z)), Image.NEAREST)
    sc.alpha_composite(fr, (int(sw // 2 - anc[0] * z), int(470 - anc[1] * z)))
    d = ImageDraw.Draw(sc)
    for (tt, x, y) in tp:                                   # ripples where the thumb lands, a shekel rising
        u = t - tt
        if u < 0.25:
            r = int(16 + u * 160)
            d.ellipse((x - r, y - r, x + r, y + r), outline=(255, 255, 255, int(200 * (1 - u / 0.25))), width=4)
        if u < 0.7:
            f = text("+₪", 4, fill=GOLD_HI)
            sc.alpha_composite(fade(f, 1 - u / 0.7), (x - f.width // 2, int(y - 30 - u * 140)))
    n = len(tp) / max(1, len(taps(t0, t1)))
    val = v0 + (v1 - v0) * (0.25 * clamp((t - t0) / (t1 - t0)) + 0.75 * n)
    d.rectangle((0, 0, sw, 70), fill=NAVY)
    d.rectangle((0, 70, sw, 76), fill=INK)
    money = text("₪ " + shekels(val), 5, fill=GOLD_HI, rtl=False)
    sc.alpha_composite(money, (18, 35 - money.height // 2))
    nm = text(NAMES[who], 3)
    sc.alpha_composite(nm, (sw - nm.width - 16, 35 - nm.height // 2))
    d.rectangle((0, sh - 92, sw, sh), fill=NAVY)            # the buy row
    d.rectangle((0, sh - 92, sw, sh - 86), fill=INK)
    row = text("מקור הכנסה חדש", 4)
    sc.alpha_composite(row, (sw - row.width - 24, sh - 46 - row.height // 2))
    btn = text("לקנות", 4, fill=INK, ring=None, shadow=False)
    lit = 1 if int(t * 3) % 2 else 0
    d.rectangle((20, sh - 74, 40 + btn.width + 20, sh - 18), fill=GOLD_HI if lit else GOLD, outline=INK, width=4)
    sc.alpha_composite(btn, (40, sh - 46 - btn.height // 2))
    return sc


def n_beat(t):
    i = 0
    for j, b in enumerate(N_BEATS):
        if t >= b[0]:
            i = j
    return i


def n_room(c, dawn):
    """The bedroom: a wall, a window (moon → sunrise), a blanket at the bottom."""
    sky_top = tuple(int(a + (b - a) * dawn) for a, b in zip((8, 12, 40), (250, 150, 110)))
    sky_bot = tuple(int(a + (b - a) * dawn) for a, b in zip((20, 30, 80), (255, 214, 140)))
    wall = tuple(int(a + (b - a) * dawn * 0.6) for a, b in zip((10, 12, 26), (70, 52, 60)))
    c.alpha_composite(bg_grad(wall, tuple(max(0, v - 6) for v in wall)))
    d = ImageDraw.Draw(c)
    wx, wy, ww, wh = 700, 540, 230, 300                     # the window, upper right, behind the phone
    for yy in range(wh):
        u = yy / wh
        col = tuple(int(a * (1 - u) + b * u) for a, b in zip(sky_top, sky_bot))
        d.line((wx, wy + yy, wx + ww, wy + yy), fill=col)
    if dawn < 0.6:
        mx, my = wx + 150, wy + 80 + int(dawn * 260)
        d.ellipse((mx - 34, my - 34, mx + 34, my + 34), fill=(246, 240, 210, int(255 * (1 - dawn / 0.6))))
    else:
        sx, sy = wx + 70, wy + wh - int((dawn - 0.6) / 0.4 * 120)
        d.ellipse((sx - 46, sy - 46, sx + 46, sy + 46), fill=(255, 236, 170))
    d.rectangle((wx - 12, wy - 12, wx + ww + 12, wy + wh + 12), outline=INK, width=14)
    d.line((wx + ww // 2, wy, wx + ww // 2, wy + wh), fill=INK, width=10)
    d.line((wx, wy + wh // 2, wx + ww, wy + wh // 2), fill=INK, width=10)
    d.rectangle((0, 1460, W, H), fill=tuple(int(a + (b - a) * dawn * 0.5) for a, b in zip((22, 30, 70), (90, 80, 120))))
    for x in range(0, W, 120):
        d.rectangle((x, 1460, x + 60, 1472), fill=(40, 50, 100))


def n_phone(c, screen, cx, cy, glow):
    pw, ph = N_SCREEN[0] + 44, N_SCREEN[1] + 140
    x0, y0 = cx - pw // 2, cy - ph // 2
    if glow > 0:                                            # the screen lights the room
        g = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        ImageDraw.Draw(g).ellipse((cx - 560, cy - 520, cx + 560, cy + 560), fill=(70, 110, 255, int(70 * glow)))
        c.alpha_composite(g.filter(ImageFilter.GaussianBlur(90)))
    d = ImageDraw.Draw(c)
    d.rounded_rectangle((x0, y0, x0 + pw, y0 + ph), radius=56, fill=(18, 18, 24), outline=(70, 72, 90), width=6)
    d.rounded_rectangle((cx - 70, y0 + 24, cx + 70, y0 + 52), radius=14, fill=INK)
    sx, sy = cx - N_SCREEN[0] // 2, y0 + 80
    if screen is not None:
        c.alpha_composite(screen, (sx, sy))
    d.rectangle((sx, sy + N_SCREEN[1], sx + N_SCREEN[0], y0 + ph - 30), fill=(10, 14, 40))
    d.rounded_rectangle((cx - 90, y0 + ph - 28, cx + 90, y0 + ph - 20), radius=4, fill=(120, 120, 140))
    # a thumb on the screen, tapping
    return sx, sy


def n_clock(c, clock, t, t0, red=False):
    im = text(clock, 11, fill=RED if red else (120, 255, 150), ring=INK, rtl=False)
    sc = pop_scale(t, t0, 0.14, 1.35) or 1
    pl = plate(im.width + 60, im.height + 34, INK, (60, 60, 80), 6)
    paste(c, scaled(pl, sc), W // 2, 490)
    paste(c, scaled(im, sc), W // 2, 490)


def night_frame(t):
    c = Image.new("RGBA", (W, H), INK + (255,))
    if t >= N_END:
        end_card(c, t - N_END)
        return c.convert("RGB")
    if t < N_ALARM:
        b = n_beat(t)
        t0, clock, line = N_BEATS[b][:3]
        dawn = clamp((t - 6.0) / 4.0) * 0.85
        n_room(c, dawn)
        screen = game_screen(b, t)
        bob = int(math.sin(t * 2.2) * 5)
        n_phone(c, screen, W // 2 - 20, 1050 + bob, 1 - dawn * 0.6)
        n_clock(c, clock, t, t0)
        lines = [text(ln, 8, grad=b == 0) for ln in line.split("|")]
        sc = pop_scale(t, t0, 0.14, 1.25) or 1
        y = 250 - (len(lines) - 1) * 45
        for im in lines:
            paste(c, scaled(im, sc), W // 2, y)
            y += im.height + 12
        for tb in N_BEATS[1:]:
            flash(c, t, tb[0], 0.12, 0.6, (200, 220, 255))
        return c.convert("RGB")
    # 07:00: the alarm, the room in daylight, the punchline
    u = t - N_ALARM
    n_room(c, 1.0)
    shake = int(math.sin(u * 70) * 10) if u < 1.6 else 0
    n_phone(c, game_screen(len(N_BEATS) - 1, N_ALARM - 0.01), W // 2 - 20 + shake, 1050, 0.3)  # frozen
    if int(u * 4) % 2 == 0 or u > 1.6:
        n_clock(c, "07:00", t, N_ALARM, red=True)
    if u >= 0.9:
        a = text("קוראים לו עוד סבב.", 8, grad=True)
        b_ = text("לא סתם.", 9, fill=WHITE)
        sc = pop_scale(u, 0.9, 0.14, 1.3)
        paste(c, scaled(plate(max(a.width, b_.width) + 70, a.height + b_.height + 60, NIGHT, INK, 6), sc), W // 2, 240)
        paste(c, scaled(a, sc), W // 2, 240 - b_.height // 2 - 6)
        if u >= 1.5:
            slam(c, b_, u, 1.5, W // 2, 240 + a.height // 2 + 10, frm=1.8)
    flash(c, t, N_ALARM, 0.12, 0.9)
    return c.convert("RGB")


def night_audio(path):
    m = P.Mix(N_DUR)
    a = k.load_wav("music_balfour_L0")
    a = a if a.ndim == 1 else a.mean(1)
    n = int(N_ALARM * P.SR)
    a = np.tile(a, n // len(a) + 1)[:n].copy()
    # late-night: darker and quieter as the hours go by
    x = np.exp(-2 * np.pi * 1400 / P.SR)
    y = np.zeros_like(a)
    acc = 0.0
    for i in range(len(a)):
        acc = (1 - x) * a[i] + x * acc
        y[i] = acc
    y[-int(0.05 * P.SR):] *= np.linspace(1, 0, int(0.05 * P.SR))
    m.put(0.0, y, -4)
    for i, bt in enumerate(N_BEATS):                 # the thumb's taps, a coin each
        t1 = N_BEATS[i + 1][0] if i + 1 < len(N_BEATS) else N_ALARM
        for j, (tt, _, _) in enumerate(taps(bt[0], t1)):
            m.cue(tt, "coin_E_a" if j % 2 else "coin_E_b", -14)
        if i:
            m.cue(bt[0], "leaderPick_D", -12)        # a new round, a new leader
    for tb in N_BEATS[1:]:
        m.cue(tb[0] - 0.12, "critReact_D_whoosh", -6)
    beep = np.concatenate([tone(2000, 0.09, 2, True), np.zeros(int(0.06 * P.SR), np.float32)] * 4)
    for r in range(3):
        m.put(N_ALARM + r * 0.75, beep, -8)
    m.cue(N_ALARM + 1.5, "stamp", -3)
    end_audio(m, N_END)
    m.write(path, 0.5)


# ============================================================================ 3. אמת או המצאה? (photo mode)

# (claim, answer lines, source, sprites on the answer slide). All from design/facts.json, never
# stronger than its aboutHe; the claim names no one, the answer does.
TRUTH = [
    ("תוספת של 800 מיליון ₪ לתקציב אושרה כי חברי אופוזיציה הצביעו בעדה בטעות.",
     ["תקציב 2026.", "850.6 מיליארד ₪, הגדול אי־פעם."], "טיימס אוף ישראל", []),
    ("יושב ראש של ועדה בכנסת התפטר, וחזר לתפקיד כעבור חמישה ימים.",
     ["משה גפני, ועדת הכספים,", "יולי 2025."], "דה מרקר; כיכר השבת", ["gafni"]),
    ("במעון ראש הממשלה היה תקציב של 10,000 ₪ בשנה לגלידת פיסטוק.",
     ["הסעיף בוטל ב־2013."], "טיימס אוף ישראל", ["bibi"]),
    ("שר אוצר הטיל מס על כלים חד־פעמיים, והשר שבא אחריו ביטל אותו.",
     ["ליברמן הטיל (2021).", "סמוטריץ׳ ביטל (2023)."], "טיימס אוף ישראל; ג׳רוזלם פוסט", ["liberman", "smotrich"]),
    ("בישראל היו חמש מערכות בחירות בפחות מארבע שנים.",
     ["מאפריל 2019 עד נובמבר 2022."], "המכון הישראלי לדמוקרטיה", []),
]


def t_base(dim=0.78):
    c = Image.new("RGBA", (W, H), INK + (255,))
    k.draw_stage(c, "knesset", 9, 90, 150, dim=dim)
    vignette(c)
    return c


def t_dubi(c, x, y, scale=12, anim="talk", i=0):
    fr, anc = char_frame("dubi", anim, i, scale)
    paste(c, fr, x - anc[0] * scale, y - anc[1] * scale, "tl")


def t_count(c, i):
    paste(c, text("%d/%d" % (i + 1, len(TRUTH)), 5, fill=GOLD_HI, rtl=False), W // 2, 190)


def t_claim_card(c, claim, y_mid, px=6):
    lines = wrap(claim, px, 780, fill=INK, ring=None, shadow=False)
    h = sum(im.height + 16 for im in lines) + 80
    paste(c, plate(880, h, PAPER, INK, 8), W // 2, y_mid)
    stack(c, lines, y_mid - h // 2 + 40 + lines[0].height // 2, 16)
    return y_mid + h // 2


def t_cover():
    c = t_base(0.7)
    paste(c, img("wordmark", 5), W // 2, 260)
    q = text("אמת או המצאה?", 11, grad=True)
    paste(c, plate(q.width + 80, q.height + 50, NIGHT, INK, 8), W // 2, 470)
    paste(c, q, W // 2, 470)
    stack(c, wrap("5 דברים מהמשחק שנשמעים מומצאים.", 6, 700), 620, 18)
    t_dubi(c, W // 2, 1120, 14, "squawk", 1)
    paste(c, text("?", 14, grad=True), W // 2 + 190, 820)
    paste(c, text("נחשו לפני שמחליקים.", 6, fill=GOLD_HI), W // 2, 1230)
    paste(c, text("החליקו ←", 7, fill=WHITE), W // 2, 1360)
    return c


def t_question(i):
    claim = TRUTH[i][0]
    c = t_base()
    t_count(c, i)
    q = text("אמת או המצאה?", 8, grad=True)
    paste(c, q, W // 2, 290)
    bottom = t_claim_card(c, claim, 640)
    y = max(bottom + 130, 1000)
    for x, word, col in ((W // 2 + 210, "אמת", GREEN), (W // 2 - 210, "המצאה", RED)):
        im = text(word, 8)
        paste(c, plate(360, im.height + 60, col, INK, 8), x, y)
        paste(c, im, x, y)
    t_dubi(c, W // 2, y + 330, 9, "idle", 0)
    paste(c, text("התשובה בשקופית הבאה", 5, fill=SOFT), W // 2, 1400)
    return c


def t_answer(i):
    claim, lines, src, who = TRUTH[i]
    c = t_base(0.84)
    t_count(c, i)
    small = wrap(claim, 4, 820, fill=SOFT)
    stack(c, small, 280, 10)
    st = stamp_img("אמת", 16, GREEN).rotate(-6, resample=Image.NEAREST, expand=True)
    paste(c, st, W // 2, 590)
    y = 860
    for ln in lines:
        im = text(ln, 7)
        paste(c, im, W // 2, y)
        y += im.height + 18
    sx = [W // 2] if len(who) == 1 else [W // 2 - 170, W // 2 + 170]
    for x, ch in zip(sx, who):
        fr, anc = char_frame(ch, "idle", 0, 1)
        paste(c, fr, x - anc[0], 1330 - anc[1], "tl")
    if not who:
        t_dubi(c, W // 2, 1300, 10, "squawk", 2)
    s = text("מקור: " + src, 4, fill=GOLD_HI)
    paste(c, plate(s.width + 40, s.height + 24, INK, INK, 4), W // 2, 1410)
    paste(c, s, W // 2, 1410)
    return c


def t_final():
    c = t_base(0.6)
    k.curtain(c, 0, dim=0.2)
    spotlight(c, W // 2, 0, 1300, 90, 460, 0.2, GOLD_HI)
    vignette(c)
    paste(c, text("5 מתוך 5:", 8), W // 2, 230)
    paste(c, badge("אמת.", 14), W // 2, 400)
    y = stack(c, wrap("במשחק יש עוד הרבה כאלה. כל עובדה עם מקור.", 6, 760), 560)
    paste(c, text("הבדיחות: שלנו.", 7, grad=True), W // 2, y + 75)
    for i, who in enumerate(LINEUP):
        fr, anc = char_frame(who, "idle", 0, 1)
        x = 125 + i * (790 / 7)
        paste(c, fr, x - anc[0], 1240 - anc[1], "tl")
    u = text(URL, 6, rtl=False)
    paste(c, plate(u.width + 56, u.height + 34, INK, GOLD, 6), W // 2, 1310)
    paste(c, u, W // 2, 1310)
    paste(c, text("כמה ניחשתם? כתבו בתגובות.", 5, fill=GOLD_HI), W // 2, 1410)
    return c


def truth():
    d = os.path.join(OUT, "truth")
    os.makedirs(d, exist_ok=True)
    slides = [t_cover()]
    for i in range(len(TRUTH)):
        slides += [t_question(i), t_answer(i)]
    slides.append(t_final())
    for n, s in enumerate(slides, 1):
        p = os.path.join(d, "%02d.png" % n)
        s.convert("RGB").save(p, optimize=True)
        print(p)


# ============================================================================ render

VIDEOS = {  # (frame, audio, length, name, cover time)
    "guess": (guess_frame, guess_audio, G_DUR, "od-sevev-tiktok-guess", G_HOOK + G_REVEAL + 0.6),
    "night": (night_frame, night_audio, N_DUR, "od-sevev-tiktok-night", N_ALARM + 2.0),
}


def main():
    which = sys.argv[1]
    if which == "truth":
        truth()
        return
    frame, audio, dur, name, cover_t = VIDEOS[which]
    os.makedirs(OUT, exist_ok=True)
    if "--stills" in sys.argv:
        k.frame = frame
        k.stills([round(x * dur / 17, 2) for x in range(18)], os.path.join(OUT, "_stills_%s.png" % which))
        return
    if "--one" in sys.argv:
        frame(float(sys.argv[sys.argv.index("--one") + 1])).save(os.path.join(OUT, "_one.png"))
        return
    wav = os.path.join(OUT, "_%s.wav" % which)
    audio(wav)
    video = os.path.join(OUT, name + ".mp4")
    cmd = [k.ffmpeg(), "-y", "-loglevel", "error",
           "-f", "rawvideo", "-pix_fmt", "rgb24", "-s", f"{W}x{H}", "-r", str(FPS), "-i", "-", "-i", wav,
           "-map", "0:v", "-map", "1:a", "-c:v", "libx264", "-preset", "slow", "-crf", "18", "-pix_fmt", "yuv420p",
           "-profile:v", "high", "-movflags", "+faststart", "-af", "loudnorm=I=-14:TP=-1.0:LRA=11",
           "-c:a", "aac", "-b:a", "192k", "-ar", "48000", "-t", str(dur), video]
    p = subprocess.Popen(cmd, stdin=subprocess.PIPE)
    cover = frame(cover_t)
    cover.save(os.path.join(OUT, name + "-cover.png"))
    for i in range(int(dur * FPS)):
        p.stdin.write(frame(i / FPS).tobytes())
    p.stdin.close()
    if p.wait() != 0:
        raise SystemExit("ffmpeg failed")
    os.remove(wav)
    print(video)


if __name__ == "__main__":
    main()
