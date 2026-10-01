"""'עוד סבב' shorts: four 7-10 s loops (Itay: short, crazy, people want more, then they download).

Research, Oct 2026: Reels now rank on replay and completion more than views; 6-12 s clips that loop
cleanly (the last frame runs back into the first) get watched two, three, ten times. So each short
is one idea, one escalation, and an ending that drops straight back into its start. The call to
action sits on screen the whole time, above the Reels caption zone.

    pov       "POV: אתה המנדט ה־61": the lock screen at 20:00 on election day; all eight leaders text you.
    stop      "עצרו את הסרטון!": a leader roulette too fast to read; pause to see who you are.
    speedrun  "ספידראן ל־61": the real game at x8 against a clock; world record 49; the Knesset
              dissolves and the clock resets.
    tap       "לחיצה = שקל": satisfying taps across the cast up to a billion; one partner's demand
              drains it to zero, and it starts over.

Copy follows the game after the 2026-10-01 copy audit and creative-pack/voice/character-research-2026-10-01.md
('ידידי' is Ben Gvir's address, Deri closes things in the corridor, Liberman: לא אשב).

    python3 store/promo/src/shorts.py <scratch dir> pov|stop|speedrun|tap [--stills | --one <sec>]
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
from teaser import (INK, NIGHT, GOLD, GOLD_HI, GOLD_SH, WHITE, RED, W, H, FPS, img, paste, scaled, fade,  # noqa: E402
                    text, plate, bubble, badge, slam, flash, pop_scale, clamp, ease_out, ease_inout, char_frame,
                    coins_burst, burst_bg, shake, speedlines, vignette, rnd)

OUT = P.OUT
CTA = "לשחק בחינם · הלינק בביו"
ORDER = ["bibi", "bennett", "bengvir", "liberman", "smotrich", "eisenkot", "deri", "golan"]


def cta_bar(c, t):
    """The standing call to action, above the Reels caption zone, on every frame (loops never lose it)."""
    d = ImageDraw.Draw(c)
    d.rectangle((0, 1468, W, 1560), fill=INK)
    d.rectangle((0, 1468, W, 1474), fill=GOLD)
    wm = text("עוד סבב", 6, grad=True)
    cta = text(CTA, 5)
    paste(c, wm, W - 40 - wm.width // 2, 1516)
    pulse = 1 + 0.04 * math.sin(t * 8)
    paste(c, scaled(cta, pulse), 40 + cta.width // 2, 1516)


def top_caption(c, line, sub=None, y=170, px=8, t=None, t0=None):
    im = text(line, px, grad=True)
    sc = pop_scale(t, t0, 0.14, 1.3) if t is not None else 1
    h = im.height + 30 + (text(sub, 5).height + 12 if sub else 0)
    paste(c, scaled(plate(im.width + 60, h, NIGHT, INK, 6), sc), W // 2, y + (h - im.height - 30) // 2)
    paste(c, scaled(im, sc), W // 2, y)
    if sub:
        s = text(sub, 5)
        paste(c, s, W // 2, y + im.height // 2 + 12 + s.height // 2)


def avatar_round(who, size):
    kk = ("avr", who, size)
    if kk not in P._tf:
        a = img("avatar_pick_%s_d3" % P.LEAD[who][1], 1).resize((size, size), Image.NEAREST)
        m = Image.new("L", (size * 4, size * 4), 0)
        ImageDraw.Draw(m).ellipse((0, 0, size * 4 - 1, size * 4 - 1), fill=255)
        out = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        out.paste(a, (0, 0), m.resize((size, size), Image.LANCZOS))
        P._tf[kk] = out
    return P._tf[kk]


# ============================================================================ 1. POV: the 61st seat

POV_DUR = 9.0
POV_MSGS = [  # (time, who, message): each in the game's voice after the copy audit
    (0.7, "bengvir", "ידידי, בוא אליי. הצבתי דד־ליין."),
    (1.45, "bennett", "חותם לך על הכל. בעט."),
    (2.1, "bibi", "הצהרה דרמטית ב־20:00. תהיה שם."),
    (2.65, "liberman", "לא אשב איתך. אבל תבוא."),
    (3.1, "smotrich", "תקציב? בשבילך תמיד יש."),
    (3.5, "eisenkot", "בלי פוליטשטיקים. ישר."),
    (3.85, "deri", "נסגור את זה במסדרון."),
    (4.15, "golan", "בוא נתאחד. שוב."),
]
POV_FLOOD = ["?", "בוא!", "ידידי?", "חתום?", "עונה?", "61?", "רק רגע", "טלפון?", "מסדרון?", "לא אשב. בוא."]
POV_HIT = 6.4


def pov_notes(t):
    notes = [(t0, who, msg) for t0, who, msg in POV_MSGS if t >= t0]
    r = rnd("flood")
    tt = 4.4
    i = 0
    while tt < min(t, POV_HIT):
        notes.append((tt, ORDER[r.randrange(8)], POV_FLOOD[r.randrange(len(POV_FLOOD))]))
        i += 1
        tt += max(0.045, 0.22 - i * 0.012)
    return notes


def pov_note(c, x, y, who, msg, a=1.0):
    w, h = 960, 150
    card = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(card)
    d.rounded_rectangle((0, 0, w - 1, h - 1), radius=34, fill=(236, 238, 246, 235))
    card.alpha_composite(avatar_round(who, 104), (w - 128, 23))
    nm = text(P.LEAD[who][2], 5, fill=INK, ring=None, shadow=False)
    card.alpha_composite(nm, (w - 150 - nm.width, 18))
    ms = text(msg, 5, fill=(40, 44, 60), ring=None, shadow=False)
    card.alpha_composite(ms, (max(20, w - 150 - ms.width), 82))
    app = text("עכשיו", 4, fill=(110, 116, 140), ring=None, shadow=False)
    card.alpha_composite(app, (28, 22))
    paste(c, fade(card, a), x, y, "tl")


def pov_frame(t):
    c = Image.new("RGBA", (W, H), INK + (255,))
    P.grad_bg(c, (40, 22, 80), (12, 26, 70))
    vib = 0
    if 0.6 < t < POV_HIT:
        vib = int(min(18, 2 + (t - 0.6) * 3)) if int(t * 20) % 2 else 0
    dx, dy = shake(t, [(POV_HIT, 40, 0.5)])
    off = (vib + dx, dy)
    # the lock screen: election day, 20:00
    paste(c, text("יום שלישי, 27 באוקטובר", 5, fill=(220, 224, 255)), W // 2 + off[0], 330 + off[1])
    paste(c, text("20:00", 22, fill=WHITE, ring=None, shadow=False, rtl=False), W // 2 + off[0], 470 + off[1])
    notes = pov_notes(t)
    y = 640
    for j, (t0, who, msg) in enumerate(reversed(notes)):       # newest on top, pushing the rest down
        if y > 1440:
            break
        slide = ease_out(clamp((t - t0) / 0.14))
        pov_note(c, 60 + off[0], y - (1 - slide) * 120 + off[1], who, msg, slide)
        y += 168 if j < 6 else 120
    n = len(notes)
    if n > 1 and t < POV_HIT + 0.3:
        b = text("+%d" % n, 6, fill=WHITE, rtl=False)
        paste(c, plate(b.width + 40, 70, RED, INK, 5), W - 150, 470)
        paste(c, b, W - 150, 470)
    top_caption(c, "אתה המנדט ה־61", y=170)
    pv = text("POV", 5, fill=INK, ring=None, shadow=False, rtl=False)
    paste(c, plate(pv.width + 30, 50, GOLD, INK, 4), 120, 170)
    paste(c, pv, 120, 170)
    if t >= POV_HIT:
        u = t - POV_HIT
        overlay = Image.new("RGBA", (W, H), INK + (int(200 * clamp(u / 0.15)),))
        c.alpha_composite(overlay)
        slam(c, text("כולם רוצים אותך.", 10, grad=True), t, POV_HIT, W // 2, 820, frm=2.4)
        if u > 0.7:
            paste(c, text("רק לך יש מנדט.", 7), W // 2, 1000)
        if u > 1.4:
            slam(c, badge("עוד סבב", 12), t, POV_HIT + 1.4, W // 2, 1230, angle=-4, frm=2.2)
        flash(c, t, POV_HIT, 0.14, 0.9)
    if t > POV_DUR - 0.35:                                       # back to the quiet lock screen: the loop
        c.alpha_composite(Image.new("RGBA", (W, H), INK + (int(255 * clamp((t - (POV_DUR - 0.35)) / 0.35)),)))
    cta_bar(c, t)
    return c.convert("RGB")


def buzz(dur, f=150):
    n = int(dur * P.SR)
    tt = np.arange(n) / P.SR
    env = np.minimum(1, tt / 0.01) * np.minimum(1, (dur - tt) / 0.02)
    return (np.sign(np.sin(2 * np.pi * f * tt)) * 0.18 * env).astype(np.float32)


def pov_audio(path):
    m = P.Mix(POV_DUR)
    pings = {"bengvir": "chatPing_D_benGvir", "deri": "chatPing_D_deri", "smotrich": "chatPing_D_smotrich"}
    for t0, who, _ in POV_MSGS:
        m.cue(t0, pings.get(who, "chatPing_D_default"), -2)
        m.put(t0, buzz(0.25), -12)
    for t0, who, _ in pov_notes(POV_HIT - 0.01)[len(POV_MSGS):]:
        m.cue(t0, "chatPing_D_burst" if int(t0 * 10) % 3 == 0 else "chatPing_D_default", -9)
    m.put(4.4, buzz(POV_HIT - 4.4, 120), -14)
    bed = k.load_wav("music_balfour_outside")
    m.put(0, bed[: int(POV_HIT * P.SR)], -10)
    m.cue(POV_HIT, "stinger_fanfare_D_t0", -1)
    m.cue(POV_HIT, "stamp", -2)
    m.cue(POV_HIT + 1.4, "stamp_bell", -3)
    m.write(path, 0.35)


# ============================================================================ 2. stop the video

STOP_DUR = 7.0
STOP_CARDS = [  # (who, label): the leader's one true tag (copy audit + research)
    ("bibi", "הקוסם"), ("bennett", "חותם על הכל"), ("bengvir", "ידידי"), ("liberman", "לא אשב"),
    ("smotrich", "יש כסף. לא לך."), ("eisenkot", "בלי פוליטשטיקים"), ("deri", "סוגר במסדרון"),
    ("golan", "מאחד הכל"), (None, "המנדט ה־61"),
]
STOP_LAND = 5.6


def stop_index(t):
    """Card shown at t: 15 a second, slowing like a wheel, landing on 'עוד סבב'."""
    if t >= STOP_LAND:
        return -1
    if t < 4.2:
        return int(t * 15) % len(STOP_CARDS)
    # decelerate: integrate a falling rate from 15/s to 2/s
    base = int(4.2 * 15)
    u = t - 4.2
    rate0, rate1, T = 15.0, 2.0, STOP_LAND - 4.2
    steps = rate0 * u + (rate1 - rate0) * u * u / (2 * T)
    return (base + int(steps)) % len(STOP_CARDS)


def stop_frame(t):
    c = Image.new("RGBA", (W, H), INK + (255,))
    i = stop_index(t)
    hues = [((60, 16, 30), RED), ((14, 24, 80), (30, 60, 160)), ((20, 60, 40), (40, 130, 80)), ((70, 50, 10), GOLD_SH)]
    c1, c2 = hues[(i if i >= 0 else 0) % 4]
    burst_bg(c, t * 3, c1, c2, cx=W // 2, cy=820, n=18)
    top_caption(c, "עצרו את הסרטון!", "מי אתם בקואליציה?", y=170, px=9)
    d = ImageDraw.Draw(c)
    d.rectangle((W // 2 - 300, 420, W // 2 + 299, 1019), fill=INK)
    d.rectangle((W // 2 - 290, 430, W // 2 + 289, 1009), fill=GOLD)
    d.rectangle((W // 2 - 276, 444, W // 2 + 275, 995), fill=(18, 28, 80))
    if i >= 0:
        who, label = STOP_CARDS[i]
        if who:
            paste(c, avatar_round(who, 520), W // 2, 720)
        else:
            paste(c, text("?", 40, fill=GOLD_HI), W // 2, 720)
        lab = text(label, 9, fill=WHITE)
        paste(c, plate(lab.width + 60, lab.height + 34, INK, GOLD_SH, 6), W // 2, 1120)
        paste(c, lab, W // 2, 1120)
    else:
        u = t - STOP_LAND
        sc = pop_scale(t, STOP_LAND, 0.16, 2.0)
        paste(c, scaled(img("wordmark", 5), sc), W // 2, 720)
        slam(c, text("יצא לכם: עוד סבב.", 8, grad=True), t, STOP_LAND + 0.2, W // 2, 1120, frm=2.2)
        coins_burst(c, t, STOP_LAND, W // 2, 720, n=46, seed=9, life=1.4, kinds=("coin", "coin", "bill"))
        flash(c, t, STOP_LAND, 0.14, 0.9)
    paste(c, text("כתבו בתגובות מה יצא לכם", 5, fill=(220, 224, 255)), W // 2, 1300)
    cta_bar(c, t)
    return c.convert("RGB")


def stop_audio(path):
    m = P.Mix(STOP_DUR)
    last = None
    for f in range(int(STOP_LAND * FPS)):
        t = f / FPS
        i = stop_index(t)
        if i != last:
            m.cue(t, "uiClick_D", -3)
            last = i
    m.put(0, P.music_seg(os.path.join(P.GAMEPLAY, "music", "glitch-warfare.wav"), 34.10, STOP_DUR), -6)
    m.cue(STOP_LAND, "rabbitCrit_D_s150", -2)
    m.cue(STOP_LAND + 0.2, "stamp", -3)
    m.cue(STOP_LAND + 0.1, "coin_D_a", -6)
    m.write(path, 0.3)


# ============================================================================ 3. speedrun to 61

SR_DUR = 10.0
SR_PLAY = [  # (video start, video end, take, take start, take end): the real game at x6-x8
    (0.0, 1.0, "bibi", 0.7, 6.5),
    (1.0, 2.0, "bennett", 4.0, 12.0),
    (2.0, 3.0, "deri", 8.0, 16.0),
    (3.0, 7.6, "liberman", 18.0, 56.5),       # coalition, demands, 49 of 61
]
SR_STOP = 7.6
SR_RESET = 9.4


def sr_clock(t):
    """The speedrun clock: game time at the cut's speed, frozen at the stop, zero at the reset."""
    if t >= SR_RESET:
        return 0.0
    tt = min(t, SR_STOP)
    acc = 0.0
    for vs, ve, _, ts, te in SR_PLAY:
        if tt > vs:
            acc += (min(tt, ve) - vs) * (te - ts) / (ve - vs)
    return acc * 2.6          # the game runs at dev speed 3: wall time of a real player


def sr_frame(t):
    c = Image.new("RGBA", (W, H), (8, 10, 24, 255))
    gw, gh = 760, round(760 * 2338 / 1080)
    gx, gy = (W - gw) // 2, 300
    shot = None
    tt = min(t, SR_STOP)
    for vs, ve, who, ts, te in SR_PLAY:
        if vs <= tt <= ve or (tt == SR_STOP and ve == SR_STOP):
            u = (tt - vs) / (ve - vs)
            fr = P.take_frame(who, ts + u * (te - ts))
            shot = fr.resize((gw, gh), Image.BILINEAR)
            if t < SR_STOP:
                flash(c, t, vs, 0.05, 0.3)
            break
    if t >= 8.0:                                                     # the Knesset dissolves
        shot = P.take_frame("liberman", 58.6).resize((gw, gh), Image.BILINEAR)
    if shot is not None:
        d = ImageDraw.Draw(c)
        d.rectangle((gx - 10, gy - 10, gx + gw + 9, gy + 1160), fill=GOLD_SH)
        c.alpha_composite(shot.crop((0, 0, gw, 1150)), (gx, gy))
    if t < SR_STOP:
        speedlines(c, t, a=0.12, cy=800)
    # the clock
    ck = sr_clock(t)
    mm, ss = int(ck // 60), ck % 60
    clock = text("%02d:%05.2f" % (mm, ss), 11, fill=GOLD_HI if t < SR_STOP else RED, rtl=False)
    paste(c, plate(clock.width + 60, clock.height + 30, INK, GOLD_SH, 6), W // 2, 150)
    paste(c, clock, W // 2, 150)
    lab = text("ספידראן ל־61", 5, fill=(220, 224, 255))
    paste(c, lab, W // 2, 245)
    if SR_STOP <= t < 8.0:
        slam(c, text("שיא עולם: 49.", 10, grad=True), t, SR_STOP, W // 2, 820, frm=2.4)
        flash(c, t, SR_STOP, 0.12, 0.8, RED)
    if 8.0 <= t < SR_RESET:
        slam(c, text("חסרים 12. בחירות.", 8, fill=WHITE), t, 8.0, W // 2, 700, frm=2.0)
    if t >= SR_RESET:
        u = t - SR_RESET
        slam(c, text("סבב 2. מההתחלה.", 9, grad=True), t, SR_RESET, W // 2, 820, frm=2.4)
        flash(c, t, SR_RESET, 0.14, 0.9)
    cta_bar(c, t)
    return c.convert("RGB")


def sr_audio(path):
    m = P.Mix(SR_DUR)
    seg = P.music_seg(os.path.join(P.GAMEPLAY, "music", "glitch-warfare.wav"), 34.10, SR_STOP)
    m.put(0, seg, -4)
    for j in range(int(SR_STOP / 0.11)):
        m.cue(j * 0.11, "tap_D_s%d_d12" % (j % 8), -16)
    for vs, *_ in SR_PLAY:
        m.cue(vs, "critReact_D_whoosh", -6)
    m.cue(SR_STOP, "ultimatumZero_D", 0)
    m.cue(SR_STOP, "stamp", -2)
    m.cue(8.0, "courtOut_D", -4)
    m.cue(SR_RESET, "stinger_fanfare_D_t0", -2)
    m.write(path, 0.3)


# ============================================================================ 4. tap = shekel

TAP_DUR = 8.0
TAP_DRAIN = 6.3


def tap_value(t):
    if t >= TAP_DRAIN + 0.5:
        return 0
    if t >= TAP_DRAIN:
        return int(1e9 * (1 - ease_inout(clamp((t - TAP_DRAIN) / 0.5))))
    return int(min(1e9, 10 ** (t * 9 / (TAP_DRAIN - 0.3))))


def tap_times():
    out, t, gap = [], 0.15, 0.32
    while t < TAP_DRAIN - 0.1:
        out.append(t)
        t += gap
        gap = max(0.07, gap * 0.9)
    return out


def tap_frame(t):
    c = Image.new("RGBA", (W, H), INK + (255,))
    who = ORDER[min(7, int(t / (TAP_DRAIN / 8)))] if t < TAP_DRAIN else "bengvir"
    taps = tap_times()
    last = max([x for x in taps if x <= t], default=-9)
    hit = clamp(1 - (t - last) / 0.12)
    z = 1.0 + 0.05 * hit
    box = (575 - 300, 760 - 330, 575 + 300, 760 + 360)                # the leader, close
    shot = P.take_frame(who, 6.0 + (t % 1.0)).crop(box).resize((round(1080 * z), round(1242 * z)), Image.BILINEAR)
    dx, dy = shake(t, [(last, 18 * (1 + t / 3), 0.12)] + ([(TAP_DRAIN, 50, 0.5)] if t >= TAP_DRAIN else []))
    paste(c, shot, W // 2 + dx, 850 + dy)
    for x in taps:
        if 0 <= t - x < 0.5:
            coins_burst(c, t, x, 560 + (hash(x) % 200) - 100, 900, n=6, seed=int(x * 100), life=0.5, kinds=("coin",))
            k.ripple(c, t, x, 560, 900)
    v = tap_value(t)
    num = text("₪ {:,}".format(v), 11 if v < 1e8 else 10, fill=GOLD_HI if t < TAP_DRAIN else RED, rtl=False)
    paste(c, plate(num.width + 60, num.height + 30, INK, GOLD_SH, 6), W // 2, 140)
    paste(c, scaled(num, 1 + 0.12 * hit), W // 2, 140)
    lb = text("לחיצה = שקל", 5)
    paste(c, plate(lb.width + 40, lb.height + 20, RED, INK, 4), W // 2, 222)
    paste(c, lb, W // 2, 222)
    if t >= TAP_DRAIN:
        u = t - TAP_DRAIN
        b = bubble("ידידי, חסר לי משהו קטן.", 7)
        paste(c, scaled(b, pop_scale(t, TAP_DRAIN, 0.12, 1.5)), W // 2, 1170)
        paste(c, avatar_round("bengvir", 150), W // 2 - b.width // 2 - 20, 1250)
        if u > 0.5:
            paste(c, text("שולם.", 9, fill=RED), W // 2, 1340)
    cta_bar(c, t)
    return c.convert("RGB")


def tap_audio(path):
    m = P.Mix(TAP_DUR)
    for j, x in enumerate(tap_times()):
        m.cue(x, "tap_D_s%d_d25" % min(7, j // 6), -4)
        if j % 3 == 0:
            m.cue(x, "coin_D_a" if j % 2 else "coin_D_b", -10)
    m.cue(TAP_DRAIN, "chatPing_D_benGvir", 0)
    m.cue(TAP_DRAIN + 0.05, "suitcaseMiss_D", -2)
    m.cue(TAP_DRAIN + 0.5, "ultimatumZero_D", -2)
    bed = k.load_wav("music_balfour_L0") + k.load_wav("music_balfour_L1")
    m.put(0, bed[: int(TAP_DRAIN * P.SR)], -12)
    m.write(path, 0.25)


# ============================================================================ render

SHORTS = {  # frame, audio, length, name, cover time (the frame that sells it)
    "pov": (pov_frame, pov_audio, POV_DUR, "od-sevev-short-pov", 4.3),
    "stop": (stop_frame, stop_audio, STOP_DUR, "od-sevev-short-stop", 1.9),
    "speedrun": (sr_frame, sr_audio, SR_DUR, "od-sevev-short-speedrun", 7.9),
    "tap": (tap_frame, tap_audio, TAP_DUR, "od-sevev-short-tap", 5.9),
}


def main():
    P.SCRATCH = sys.argv[1]
    which = sys.argv[2]
    frame, audio, dur, name, cover_t = SHORTS[which]
    if "--stills" in sys.argv:
        k.frame = frame
        k.OUT = OUT
        k.stills([round(x * dur / 11, 2) for x in range(12)], os.path.join(OUT, "_stills_%s.png" % which))
        return
    if "--one" in sys.argv:
        frame(float(sys.argv[sys.argv.index("--one") + 1])).save(os.path.join(OUT, "_one.png"))
        return
    wav = os.path.join(P.SCRATCH, "_short_%s.wav" % which)
    audio(wav)
    video = os.path.join(OUT, name + ".mp4")
    cmd = [k.ffmpeg(), "-y", "-loglevel", "error",
           "-f", "rawvideo", "-pix_fmt", "rgb24", "-s", f"{W}x{H}", "-r", str(FPS), "-i", "-", "-i", wav,
           "-map", "0:v", "-map", "1:a", "-c:v", "libx264", "-preset", "slow", "-crf", "18", "-pix_fmt", "yuv420p",
           "-profile:v", "high", "-movflags", "+faststart", "-af", "loudnorm=I=-14:TP=-1.0:LRA=11",
           "-c:a", "aac", "-b:a", "192k", "-ar", "48000", "-t", str(dur), video]
    p = subprocess.Popen(cmd, stdin=subprocess.PIPE)
    frame(cover_t).save(os.path.join(OUT, name + "-cover.png"))
    for i in range(int(dur * FPS)):                 # loops: no cover frames up front, the start is the loop
        p.stdin.write(frame(i / FPS).tobytes())
    p.stdin.close()
    if p.wait() != 0:
        raise SystemExit("ffmpeg failed")
    print(video)


if __name__ == "__main__":
    main()
