"""'עוד סבב' teaser #2: 41 s, 1080x1920 @ 30 fps, cut to Bar's soundtrack (store/teaser/music/soundtrack.wav).

Teaser #1 (teaser.py, the game's Balfour theme) stays as shipped; this one reuses its drawing kit.
Brief (Bar, 2026-09-30): no single politician in focus (all 8 leaders get the same airtime), all Hebrew,
Mordechai David's "אני חוסם אותך" as the click-bait hook, written for the Israeli feed.

The soundtrack's grid (measured): 106.8 BPM, drop 1 at 14.016 s, drop 2 at 23.006 s (16 beats later),
breakdown from beat 31, the last section lands on beat 36, the stutter hit on 39.5, the music ends near beat 47.
Every cue below is BT(n): beat n counted from drop 1 (negative = the intro).

    python3 store/teaser/src/teaser2.py              # -> store/teaser/od-sevev-teaser-2.mp4 (+ cover)
    python3 store/teaser/src/teaser2.py --stills     # key-frame contact sheet
"""
import math
import os
import subprocess
import sys
import wave

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import teaser as k  # noqa: E402  (the drawing kit: font, cast strips, stages, particles)
from teaser import (INK, NIGHT, NAVY, GOLD, GOLD_HI, GOLD_SH, WHITE, RED, W, H, FPS,  # noqa: E402
                    img, paste, scaled, fade, overlay, rnd, text, bubble, plate, char_frame, draw_char,
                    draw_stage, stage, curtain, spotlight, speedlines, burst_bg, vignette, coins_burst, rain,
                    ripple, floaty, shake, flash, pop_scale, caption, stamp_img, badge, slam, clamp, ease_out,
                    ease_inout, SPRITES)

OUT = k.OUT
MUSIC = os.path.join(OUT, "music", "soundtrack.wav")
DUR = 41.0
D1 = 14.016
BEAT = (23.006 - D1) / 16


def BT(n):
    return D1 + n * BEAT


SFX = []
COVER_FRAMES = 2  # 2 frames = 67 ms at the very start: long enough to be frame 0, short enough to read as a cut


def sfx(t, name, db=0.0):
    SFX.append((t, name, db))


MD = "mordechai-david"
NAVY_HI = (52, 73, 143)

# ---------------------------------------------------------------------------- extra kit

_c = {}


def char_frame_flip(char, anim, i, scale):
    key = (char, anim, i, scale)
    if key not in _c:
        fr, anc = char_frame(char, anim, i, scale)
        _c[key] = (fr.transpose(Image.FLIP_LEFT_RIGHT), anc)
    return _c[key]


def draw_md(c, anim, t_local, x, y, scale, flip=False, loop=True):
    a = SPRITES["chars"][MD]["anims"][anim]
    n = a["frames"]
    i = int(t_local * a["fps"])
    i = i % n if loop else min(i, n - 1)
    if flip:
        fr, anc = char_frame_flip(MD, anim, i, scale)
        fw = SPRITES["chars"][MD]["frameW"]
        paste(c, fr, x - (fw - anc[0]) * scale, y - anc[1] * scale, "tl")
    else:
        fr, anc = char_frame(MD, anim, i, scale)
        paste(c, fr, x - anc[0] * scale, y - anc[1] * scale, "tl")


def tape(c, t, t0, y, word="חסום", angle=-6):
    """Red/white roadblock tape slammed across the screen."""
    if t < t0:
        return
    key = ("tape", word)
    if key not in _c:
        strip = Image.new("RGBA", (W + 400, 150), WHITE + (255,))
        d = ImageDraw.Draw(strip)
        for x in range(-200, strip.width + 200, 120):
            d.polygon([(x, 0), (x + 60, 0), (x + 60 - 150, 150), (x - 150, 150)], fill=RED + (255,))
        d.rectangle((0, 0, strip.width, 8), fill=INK + (255,))
        d.rectangle((0, 142, strip.width, 150), fill=INK + (255,))
        lab = text(word, 9)
        p = plate(lab.width + 60, lab.height + 24, INK, INK, 6)
        for cx in (strip.width // 2 - 420, strip.width // 2, strip.width // 2 + 420):
            strip.alpha_composite(p, (cx - p.width // 2, 75 - p.height // 2))
            strip.alpha_composite(lab, (cx - lab.width // 2, 75 - lab.height // 2))
        _c[key] = strip.rotate(angle, Image.NEAREST, expand=True)
    im = _c[key]
    u = ease_out((t - t0) / 0.12)
    x = W // 2 + int((1 - u) * -1400)
    paste(c, im, x, y)


def hemicycle(c, filled, cx=W // 2, cy=1330, lost=0.0, t=0.0):
    """120 seats in five arcs; the first `filled` (by angle, as a Knesset chart) in gold.
    `lost` 0..1 scatters the gold seats (the coalition falls)."""
    rows = [(250, 16), (320, 20), (390, 24), (460, 28), (530, 32)]
    seats = []
    for r, n in rows:
        for j in range(n):
            a = math.pi - (j + 0.5) / n * math.pi
            seats.append((a, r))
    seats.sort(key=lambda s: -s[0])
    d = ImageDraw.Draw(c)
    rr = rnd("hemi", 1)
    for idx, (a, r) in enumerate(seats):
        x = cx + math.cos(a) * r
        y = cy - math.sin(a) * r
        on = idx < filled
        col = GOLD if on else NAVY_HI
        if on and lost > 0:
            vx = (rr.random() - 0.5) * 900
            vy = -300 - rr.random() * 500
            x += vx * lost
            y += vy * lost + 2600 * lost * lost
            col = RED if int(t * 20 + idx) % 2 else GOLD
        s = 13
        x, y = int(x) // 3 * 3, int(y) // 3 * 3
        d.rectangle((x - s - 3, y - s - 3, x + s + 3, y + s + 3), fill=INK)
        d.rectangle((x - s, y - s, x + s, y + s), fill=col)
        if on and not lost:
            d.rectangle((x - s, y - s, x + s - 6, y - s + 5), fill=GOLD_HI)


LEADERS = [  # the eight, equal airtime; the order keeps no one first or last by rank
    ("bennett", "בנט", "ביחד! ביחד!", "critReact_D_whoosh", "knesset"),
    ("smotrich", "סמוטריץ׳", "יש כסף! לא לך!", "critReact_D_shout", "washington"),
    ("eisenkot", "אייזנקוט", "ישר! ישר!", "critReact_D_land", "courthouse"),
    ("bibi", "ביבי", "אין כלום! אין כלום!", "critReact_D_shout", "balfour"),
    ("golan", "גולן", "איחוד! איחוד!", "critReact_D_whoosh", "knesset"),
    ("ben-gvir", "בן גביר", "אני פורש! אני פורש!", "critReact_D_shout", "washington"),
    ("liberman", "ליברמן", "לא אשב! לא אשב!", "critReact_D_no", "courthouse"),
    ("deri", "דרעי", "מסדרון! מסדרון!", "critReact_D_land", "balfour"),
]
BURST = [((22, 60, 140), (34, 87, 166)), ((120, 24, 40), (170, 40, 57)), ((20, 70, 60), (40, 120, 90)),
         ((70, 40, 110), (110, 70, 160)), ((130, 80, 20), (190, 130, 40)), ((20, 90, 120), (40, 140, 170))]
ALL8 = ["bibi", "bennett", "ben-gvir", "liberman", "eisenkot", "smotrich", "deri", "golan"]


# ---------------------------------------------------------------------------- scenes

def s_hook(c, t):
    """0 - BT(-20): Mordechai David walks in and blocks you. From scrolling."""
    draw_stage(c, "balfour", 9, 120, 150, dim=0.35)
    vignette(c)
    arrive = BT(-24)
    feet = 1760
    if t < arrive:
        u = t / arrive
        x = W + 350 - ease_out(u) * (W // 2 + 350)
        draw_md(c, "walk", t, x, feet, 4, flip=True)
    elif t < arrive + 4 / 12:
        draw_md(c, "block_in", t - arrive, W // 2 - 60, feet, 4, loop=False)
    else:
        draw_md(c, "block", t - arrive, W // 2 - 60, feet, 4)
    tape(c, t, arrive, 1540)
    if t >= arrive:
        paste(c, scaled(bubble("אני חוסם אותך!", 11), pop_scale(t, arrive, 0.12, 1.4)), W // 2, 420)
    if t >= BT(-22):
        paste(c, scaled(text("מלגלול.", 13), pop_scale(t, BT(-22), 0.12, 1.4)), W // 2, 650)
    flash(c, t, arrive, 0.1, 0.5, RED)


def s_again(c, t):
    """BT(-20) - BT(-16): Israel is going to elections. Again."""
    draw_stage(c, "knesset", 9, 90, 150, dim=0.6)
    vignette(c)
    words = [("ישראל", BT(-20), 600), ("הולכת", BT(-19), 790), ("לבחירות", BT(-18), 980)]
    for s, t0, y in words:
        if t >= t0:
            paste(c, scaled(text(s, 15), pop_scale(t, t0, 0.12, 1.35)), W // 2, y)
    if t >= BT(-17):
        slam(c, stamp_img("שוב.", 17), t, BT(-17), W // 2, 1290, angle=9, frm=2.8)
    flash(c, t, BT(-17), 0.1, 0.6, RED)


ERAS = ["balfour", "knesset", "courthouse", "washington"]


def s_count(c, t):
    """BT(-16) - BT(-12): round 1, 2, 3, 4, 5 ... 6."""
    hits = [BT(-16 + h) for h in (0, 0.5, 1, 1.5, 2, 3)]
    n = max(i for i, h in enumerate(hits) if t >= h) + 1
    draw_stage(c, ERAS[(n - 1) % 4], 9, 90, 140, dim=0.55 if n < 6 else 0.35)
    if n == 6:
        speedlines(c, t, GOLD_HI, 0.18)
    vignette(c)
    paste(c, text("סבב בחירות מס׳", 11), W // 2, 470)
    paste(c, scaled(text(str(n), 44 if n < 6 else 52, grad=True), pop_scale(t, hits[n - 1], 0.1, 1.5 if n < 6 else 2.0)),
          W // 2, 880)
    if n == 6:
        paste(c, scaled(text("הציבור נרגש.", 11), pop_scale(t, hits[5] + 0.12, 0.12)), W // 2, 1290)
        flash(c, t, hits[5], 0.14, 0.8, GOLD_HI)
        coins_burst(c, t, hits[5], W // 2, 900, n=30, seed=6, life=1.0)


def s_pick(c, t):
    """BT(-12) - BT(0): the leader select, all eight equal; the ballot boxes open before the drop."""
    curtain(c, 0, dim=0.2)
    spotlight(c, W // 2, 0, 1500, 100, 480, 0.12)
    vignette(c)
    t0 = BT(-12)
    paste(c, scaled(text("מי מקים את", 12), pop_scale(t, t0, 0.12)), W // 2, 420)
    paste(c, scaled(text("הממשלה הפעם?", 12), pop_scale(t, t0 + 0.1, 0.12)), W // 2, 560)
    # the cursor hops on eighths, speeds up to sixteenths, then spins like a slot machine
    if t < BT(-8):
        focus = int((t - t0) / (BEAT / 2)) % 8
    elif t < BT(-4):
        focus = int((t - t0) / (BEAT / 4)) % 8
    else:
        focus = int((t - t0) / (BEAT / 8)) % 8
    dim_all = t >= BT(-1.8)
    for i, cid in enumerate(ALL8):
        if t < t0 + i * 0.06:
            continue
        gx = W // 2 + (i % 4 - 1.5) * 230
        gy = 830 + (i // 4) * 240
        on = i == focus and not dim_all
        paste(c, img("pick_tile_focus" if on else "pick_tile_idle", 6), gx, gy)
        av = img("avatar_pick_%s_d3" % cid, 2)
        paste(c, av if on or t < BT(-8) else fade(av, 0.75), gx, gy)
    if t >= BT(-8):
        caption(c, "בוחרים ראש רשימה.", t, BT(-8), 1340, 9, plated=True)
    if t >= BT(-4):
        caption(c, "ודוחים את מה שאפשר.", t, BT(-4), 1480, 9, plated=True)
    # the breath before the drop: lights down, the ballot box
    if dim_all:
        u = clamp((t - BT(-1.8)) / 0.25)
        overlay(c, INK, 0.72 * u)
        paste(c, scaled(text("הקלפיות נפתחות...", 11), pop_scale(t, BT(-1.8), 0.12)), W // 2, 960)


def s_leaders(c, t):
    """BT(0) - BT(16): eight leaders, two beats each."""
    i = min(7, int((t - D1) / (2 * BEAT)))
    cid, name, line, _, era = LEADERS[i]
    u = t - BT(2 * i)
    c1, c2 = BURST[i % len(BURST)]
    burst_bg(c, t, c1, c2)
    paste(c, stage(era, 6, 0.2).crop((0, 1200, W, 1920)), 0, 1560, "tl")
    speedlines(c, t, WHITE, 0.16, seed=i)
    side = 1 if i % 2 else -1
    x = W // 2 + side * int((1 - ease_out(u / 0.12)) * 800)
    draw_char(c, cid, "tap", u, x, 1780, 4, loop=True)
    vignette(c)
    paste(c, scaled(bubble(line, 7), pop_scale(u, 0.06, 0.12, 0.3)), W // 2, 330)
    nm = text(name, 13, grad=True)
    paste(c, plate(nm.width + 70, nm.height + 40), W // 2, 1450)
    paste(c, nm, W // 2, 1450)
    # progress pips: 8 slots, one per leader, so nobody reads as "the" lead
    for j in range(8):
        px = W // 2 + (j - 3.5) * 54
        col = GOLD if j <= i else (60, 70, 110)
        ImageDraw.Draw(c).rectangle((px - 18, 1556, px + 18, 1574), fill=INK)
        ImageDraw.Draw(c).rectangle((px - 15, 1559, px + 15, 1571), fill=col)
    flash(c, u, 0, 0.08, 0.6)


def hud(c, t, value, t0, y=250):
    if t < t0:
        return
    im = text(f"{int(value):,} ₪", 9, grad=True)
    yy = y - int((1 - ease_out((t - t0) / 0.2)) * 300)
    paste(c, plate(im.width + 60, im.height + 36), W // 2, yy)
    paste(c, im, W // 2, yy)


def s_loop(c, t):
    """BT(16) - BT(31): the game in four beats a step: collect, pay, 61, fall."""
    if t < BT(20):
        # collect: a different leader taps on every beat
        b = int((t - BT(16)) / BEAT)
        order = ["eisenkot", "ben-gvir", "golan", "smotrich"]
        cid = order[b]
        draw_stage(c, ERAS[b], 6)
        u = t - BT(16 + b)
        fx, fy = 94, 219
        sx, sy = W // 2 + (fx - 90) * 6, H // 2 + (fy - 160) * 6
        draw_char(c, cid, "tap", u, sx, sy, 2, loop=False)
        ripple(c, t, BT(16 + b), sx, sy - 330)
        coins_burst(c, t, BT(16 + b) + 0.05, sx, sy - 420, n=22, seed=40 + b, life=1.2)
        floaty(c, t, BT(16 + b), f"+{(b + 1) * 2500:,} ₪", sx + 150, sy - 560, px=8, life=0.55)
        vignette(c)
        hud(c, t, (t - BT(16)) / (4 * BEAT) * 25000, BT(16))
        caption(c, "אוספים שקלים.", t, BT(16), 440, 10, plated=True)
    elif t < BT(24):
        # pay: the coalition chat, one partner per beat, then the stamp
        c.paste((18, 22, 44), (0, 0, W, H))
        u = t - BT(20)
        head = plate(W - 80, 150, NAVY, GOLD_SH, 9)
        paste(c, head, W // 2, 470)
        paste(c, text("קואליציה 61", 9, grad=True), W // 2, 470)
        msgs = [("deri", "נסגור במסדרון. תעביר."), ("liberman", "לא אשב! לא אשב!"),
                ("bennett", "ביחד! אחרי התשלום."), ("ben-gvir", "אני פורש! אני פורש!")]
        for j, (who, line) in enumerate(msgs[:3]):
            tj = BT(20 + j)
            if t < tj:
                continue
            y = 700 + j * 230
            slide = int((1 - ease_out((t - tj) / 0.14)) * 900)
            bim = bubble(line, 7, tail=None)
            paste(c, bim, W - 190 - bim.width // 2 + slide, y)
            paste(c, img("avatar_pick_%s_d3" % who, 2), W - 100 + slide, y)
        hud(c, t, 25000 - clamp((u - 3 * BEAT) / 0.3) * 24000, BT(20), 250)
        if t >= BT(23):
            slam(c, stamp_img("שולם", 14), t, BT(23), W // 2, 930, angle=-8)
            floaty(c, t, BT(23), "-24,000 ₪", W // 2, 1400, px=9, fill=RED, life=0.5)
        caption(c, "משלמים לשותפים.", t, BT(20), 1560, 10, plated=True)
    elif t < BT(28):
        # 61: the seats fill on eighths
        draw_stage(c, "knesset", 6, dim=0.55)
        vignette(c)
        u = (t - BT(24)) / (3 * BEAT)
        filled = int(clamp(u) ** 0.8 * 61)
        hemicycle(c, filled)
        big = text(str(filled), 30, grad=True)
        paste(c, big, W // 2, 1200)
        caption(c, "מגיעים ל־61.", t, BT(24), 470, 11, plated=True)
        if t >= BT(27):
            paste(c, scaled(text("יש ממשלה!", 14, grad=True), pop_scale(t, BT(27), 0.12, 2)), W // 2, 700)
            flash(c, t, BT(27), 0.12, 0.7, GOLD_HI)
            coins_burst(c, t, BT(27), W // 2, 1100, n=40, seed=61, life=1.3)
    else:
        # ... and it falls
        u = t - BT(28)
        draw_stage(c, "knesset", 6, dim=0.55)
        overlay(c, RED, 0.18 + 0.1 * math.sin(t * 30))
        vignette(c)
        hemicycle(c, 61, lost=clamp(u / 1.2), t=t)
        caption(c, "והממשלה נופלת.", t, BT(28), 470, 11, plated=True)
        if u < 1.6:
            fr, _ = char_frame("dubi", "fly", int(u * 12), 12)
            x = -150 + u / 1.6 * (W + 300)
            paste(c, fr, x, 900 + math.sin(u * 9) * 50)
            paste(c, bubble("בחירות! בחירות!", 7), clamp(x, 330, W - 330), 660)


def s_break(c, t):
    """BT(31) - BT(36): the breakdown: round 7, 8, 9, 10."""
    hits = [(BT(31), 7), (BT(32), 8), (BT(34), 9), (BT(35), 10)]
    n, t0 = 7, BT(31)
    for th, v in hits:
        if t >= th:
            n, t0 = v, th
    curtain(c, 0, dim=0.45)
    vignette(c)
    paste(c, text("סבב בחירות מס׳", 11), W // 2, 620)
    paste(c, scaled(text(str(n), 44, grad=True), pop_scale(t, t0, 0.1, 1.7)), W // 2, 960)
    flash(c, t, t0, 0.1, 0.45, GOLD_HI)
    if t >= BT(34):
        paste(c, text("והציבור עדיין נרגש.", 8), W // 2, 1300)


def s_title(c, t):
    """BT(36) - end: the title, 'coming soon', and Mordechai David blocks that too."""
    tt = t - BT(36)
    curtain(c, 0, dim=0.15)
    spotlight(c, W // 2, 0, 1700, 90, 520, 0.2, GOLD_HI)
    rain(c, t, BT(36) + 0.3, 5, n=46)
    vignette(c)
    coins_burst(c, tt, 0, W // 2, 900, n=70, seed=77, life=2.2, kinds=("coin", "coin", "slip", "bill"))
    wm = img("wordmark", 6)
    s = pop_scale(tt, 0, 0.18, 0.2)
    if s:
        paste(c, scaled(wm, s), W // 2, 640)
    if tt >= 0.4:
        paste(c, scaled(text("הבחירות שלא נגמרות", 9), pop_scale(tt, 0.4, 0.12)), W // 2, 860)
    flash(c, tt, 0, 0.16, 1.0)
    if t >= BT(39.5):
        slam(c, badge("בקרוב"), t, BT(39.5), W // 2, 1110, angle=-4, frm=2.4)
        flash(c, t, BT(39.5), 0.1, 0.5, GOLD_HI)
    # he walks in front of the badge, blocks it, and the video loops back to him
    t_in = BT(42.5)
    if t >= t_in:
        u = t - t_in
        feet = 1800
        mark = W - 250
        if u < 0.5:
            x = W + 300 - ease_out(u / 0.5) * (W + 300 - mark)
            draw_md(c, "walk", u, x, feet, 3, flip=True)
        elif u < 0.5 + 4 / 12:
            draw_md(c, "block_in", u - 0.5, mark, feet, 3, loop=False)
        else:
            draw_md(c, "block", u - 0.5, mark, feet, 3)
        if u >= 0.55:
            paste(c, scaled(bubble("גם את זה אני חוסם!", 7), pop_scale(u, 0.55, 0.12, 1.3)), W // 2 - 20, 985)
    # the call to action stays on top of everything
    if t >= BT(40.5):
        cta = text("עקבו: @od.sevev", 8)
        paste(c, plate(cta.width + 50, cta.height + 26, INK, INK, 6), W // 2, 1340)
        paste(c, cta, W // 2, 1340)
    if t >= BT(41):
        paste(c, text("סאטירה. לא מטעם אף מפלגה.", 5, fill=(190, 196, 220)), W // 2, 1450)


def frame(t):
    c = Image.new("RGBA", (W, H), INK + (255,))
    if t < BT(-20):
        s_hook(c, t); ev = [(BT(-24), 40, 0.35)]
    elif t < BT(-16):
        s_again(c, t); ev = [(BT(-17), 36, 0.35)]
    elif t < BT(-12):
        s_count(c, t); ev = [(BT(-13), 30, 0.3)]
    elif t < BT(0):
        s_pick(c, t); ev = []
    elif t < BT(16):
        s_leaders(c, t); ev = [(BT(2 * i), 22 if i == 0 else 16, 0.2) for i in range(8)]
    elif t < BT(31):
        s_loop(c, t); ev = [(BT(16 + b), 14, 0.15) for b in range(4)] + [(BT(23), 30, 0.3), (BT(27), 26, 0.3),
                                                                          (BT(28), 40, 0.6)]
    elif t < BT(36):
        s_break(c, t); ev = [(BT(x), 22, 0.2) for x in (31, 32, 34, 35)]
    else:
        s_title(c, t); ev = [(BT(36), 50, 0.45), (BT(39.5), 30, 0.3), (BT(42.5) + 0.5, 20, 0.25)]
    dx, dy = shake(t, ev)
    if dx or dy:
        c2 = Image.new("RGBA", (W, H), INK + (255,))
        c2.alpha_composite(c, (max(0, dx), max(0, dy)), (max(0, -dx), max(0, -dy)))
        c = c2
    overlay(c, INK, 1 - clamp(t / 0.08))
    # no fade-out: the last frame (Mordechai David blocking "בקרוב") is the Reels cover
    return c.convert("RGB")


# ---------------------------------------------------------------------------- sound: the soundtrack + a light SFX layer

def build_sfx():
    SFX.clear()
    import json
    contours = json.load(open(os.path.join(k.AUD, "od_manifest.json")))["babbleContours"]

    def babble(t0, line, db=-6):
        cont = contours.get(line)
        if not cont:
            return
        tt = t0
        for deg, octv in cont:
            sfx(tt, "dubiBlip_D_%s_%d" % (deg, int(octv)), db)
            tt += 0.085

    sfx(BT(-24), "stamp", -2); sfx(BT(-24), "gavel_a", -4)
    for j, (deg, o) in enumerate([("5", 5), ("5", 5), ("3", 5), ("5", 5), ("1", 6), ("5", 5)]):  # "a-ni cho-sem o-tach"
        sfx(BT(-24) + 0.08 + j * 0.09, "dubiBlip_D_%s_%d" % (deg, o), -8)
    for j in range(3):
        sfx(BT(-20 + j), "slipStamp", -4)
    sfx(BT(-17), "stamp", -1); sfx(BT(-17), "stamp_bell", -8)
    for j, h in enumerate((0, 0.5, 1, 1.5, 2)):
        sfx(BT(-16 + h), k.tap_note(j + 1), -6)
    sfx(BT(-13), k.tap_note(7), -4); sfx(BT(-13), "stamp_bell", -6)
    sfx(BT(-12), "leaderPick_D", -6)
    for j in range(8):
        sfx(BT(-12) + j * BEAT / 2, "uiClick_D", -16)
    for i, (cid, name, line, react, era) in enumerate(LEADERS):
        t0 = BT(2 * i)
        sfx(t0, react, -6)
        babble(t0 + 0.12, line.split(" ")[0] if line.count(" ") == 1 else line[:line.index("!") + 1])
    for b in range(4):
        sfx(BT(16 + b), k.tap_note(b * 2), -6); sfx(BT(16 + b) + 0.05, "coin_D_a", -10)
    for j, who in enumerate(("deri", "default", "default")):
        sfx(BT(20 + j), "chatPing_D_%s" % who, -6)
    sfx(BT(23), "stamp", -2)
    sfx(BT(27), "stamp_bell", -4)
    sfx(BT(28), "suitcaseMiss_D", -6); sfx(BT(28) + 0.2, "dubiSquawk_D_up", -6)
    for x in (31, 32, 34, 35):
        sfx(BT(x), "slipStamp", -6)
    sfx(BT(36), "coin_D_a", -6)
    sfx(BT(39.5), "stamp", -3)
    sfx(BT(42.5) + 0.5, "stamp", -4)


def mix_audio(path):
    SR = k.SR
    w = wave.open(MUSIC)
    a = np.frombuffer(w.readframes(w.getnframes()), np.int16).astype(np.float32) / 32768
    if w.getnchannels() == 2:
        a = a.reshape(-1, 2)
    else:
        a = np.stack([a, a], 1)
    if w.getframerate() != SR:
        idx = np.linspace(0, len(a) - 1, int(len(a) * SR / w.getframerate()))
        a = np.stack([np.interp(idx, np.arange(len(a)), a[:, ch]) for ch in (0, 1)], 1).astype(np.float32)
    n = int(DUR * SR)
    bus = np.zeros((n, 2), np.float32)
    bus[:min(n, len(a))] += a[:n]
    build_sfx()
    for t, name, g in SFX:
        s = k.load_wav(name) * k.db(g)
        i = int(t * SR)
        if i < n:
            s = s[: n - i]
            bus[i:i + len(s)] += s[:, None]
    tail = int(0.35 * SR)
    bus[-tail:] *= np.linspace(1, 0, tail)[:, None]
    bus /= max(1e-6, np.abs(bus).max()) / 0.95
    with wave.open(path, "wb") as o:
        o.setnchannels(2); o.setsampwidth(2); o.setframerate(SR)
        o.writeframes((bus * 32767).astype(np.int16).tobytes())


def main():
    if "--stills" in sys.argv:
        ts = [float(x) for x in sys.argv[sys.argv.index("--stills") + 1:]] or [
            0.3, 1.0, 2.2, 3.5, 4.8, 6.9, 8.0, 10.0, 12.2, 13.4, 14.5, 15.7,
            17.0, 18.5, 20.0, 21.7, 23.3, 24.6, 25.9, 27.6, 28.9, 29.8, 30.5, 31.8,
            33.3, 34.7, 35.6, 36.6, 37.6, 38.6, 39.4, 40.5]
        k.frame = frame
        k.stills(ts, os.path.join(OUT, "_stills2.png"))
        return
    audio = os.path.join(OUT, "_mix2.wav")
    mix_audio(audio)
    video = os.path.join(OUT, "od-sevev-teaser-2.mp4")
    cmd = [k.ffmpeg(), "-y", "-loglevel", "error",
           "-f", "rawvideo", "-pix_fmt", "rgb24", "-s", f"{W}x{H}", "-r", str(FPS), "-i", "-", "-i", audio,
           "-c:v", "libx264", "-preset", "slow", "-crf", "16", "-pix_fmt", "yuv420p", "-profile:v", "high",
           "-movflags", "+faststart", "-af", "loudnorm=I=-14:TP=-1.0:LRA=11",
           "-c:a", "aac", "-b:a", "192k", "-ar", "48000", "-shortest", video]
    p = subprocess.Popen(cmd, stdin=subprocess.PIPE)
    nf = int(DUR * FPS)
    cover = frame((nf - 1) / FPS)
    for i in range(nf):
        # the first COVER_FRAMES frames repeat the last one, so a platform that takes frame 0 as the
        # thumbnail still shows Mordechai David blocking "coming soon"
        p.stdin.write((cover if i < COVER_FRAMES else frame(i / FPS)).tobytes())
        if i % 120 == 0:
            print(f"frame {i}/{nf}", flush=True)
    p.stdin.close()
    if p.wait() != 0:
        raise SystemExit("ffmpeg failed")
    # the Reels cover is the video's last frame: Mordechai David blocking "coming soon"
    cover.save(os.path.join(OUT, "od-sevev-teaser-2-cover.png"))
    print(video)


if __name__ == "__main__":
    main()
