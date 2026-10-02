"""'עוד סבב': a hypothetical round as Gantz (Reels, 9:16, 31 s). He isn't playable: in the game he only
stands on the picker once, as a joke (leaderSelect.decoy). This is the "what if".

The screens are the game's own: a real Movie Maker frame of the picker (take_bennett) and of a round's
first seconds (take_golan), with the leader painted out (the Balfour stage redrawn from its sprite; the
take sits on it at an offset of 276 px, matched to zero error) and Gantz painted in, in the iPhone of
the gameplay reels (store/gameplay/src/gameplay_iphone.py). What he does is satire on two sourced facts
the game already carries: the 2020 rotation that never happened (gantz-rotation) and the game's own
lines for him (T28, the decoy lines). Every tap pays ₪0; his ability is to wait; the rotation bar
reaches 99% and is postponed. The end is the real game: "גנץ לא עבר", בחר שוב.

    python3 store/promo/src/gantz.py <scratch with take_bennett/, take_golan/> [--stills | --one <sec>]
"""
import math
import os
import subprocess
import sys

from PIL import Image, ImageDraw, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, "..", "..", "gameplay", "src"))
import promo as P  # noqa: E402
import reels5 as R  # noqa: E402
import teaser as k  # noqa: E402
import gameplay_iphone as gi  # noqa: E402
from teaser import (INK, NIGHT, GOLD, GOLD_HI, GOLD_SH, WHITE, RED, W, H, FPS, img, paste, scaled, text,  # noqa: E402
                    plate, badge, slam, flash, pop_scale, clamp, ease_out, ease_inout, char_frame)

OUT = P.OUT
CW, CH = 1080, 2338                 # the take
STAGE_DY = 276                      # take row y shows the Balfour stage (z 6) at row y + 276
HUD = (0, 56, 184)
SAFE_CX = 510

DUR = 31.0
T_ROUND = 3.6                       # the picker -> the round
T_ABIL = 10.0                       # the ability
T_NOTE = 16.5                       # the reminder
T_REAL = 22.0                       # back to the real game
T_END = 27.6
TAPS = [4.6, 5.1, 5.5, 5.9, 6.2, 6.5, 6.8, 7.1, 7.4]
FEET = (550, 1035)                  # his mark on the stage (take px)
CHIP = (950, 225)                   # the ability chip, in the sky top right
BAR0, BAR1 = 11.0, 14.2             # the rotation bar fills ... and is postponed
CAPTIONS = [  # (start, end, head, sub)
    (0.2, T_ROUND, "מה אם היה אפשר לשחק בגנץ?", "סבב היפותטי. במשחק אין כזה."),
    (T_ROUND + 0.4, T_ABIL, "כל לחיצה: ₪0.", "הכסף מחכה לרוטציה."),
    (T_ABIL, T_NOTE, "יכולת מיוחדת: לחכות.", "מאז 2020."),
    (T_NOTE, T_REAL, "שלח תזכורת לגבי הרוטציה.", "סטטוס: נקרא."),
    (T_REAL + 0.3, T_END, "במשחק האמיתי:", "גנץ רק בבוחר."),
]
TOASTS = [  # (start, end, name line, message): the toast lane of the round
    (8.0, T_ABIL, "דובי · דובר הלשכה", "הקופה: ₪0. גנץ: ממתין."),
    (T_NOTE + 0.4, T_NOTE + 2.9, "גנץ · כחול לבן", "שלחתי תזכורת לגבי הרוטציה."),
    (T_NOTE + 2.9, T_REAL, "דובי · דובר הלשכה", "סטטוס: נקרא."),
]
_c = {}


# ---------------------------------------------------------------------------- the game's screens

def circle(im, size):
    big = im.resize((size * 4, size * 4), Image.NEAREST)
    m = Image.new("L", big.size, 0)
    ImageDraw.Draw(m).ellipse((0, 0, big.width - 1, big.height - 1), fill=255)
    out = Image.new("RGBA", big.size, (0, 0, 0, 0))
    out.paste(big, (0, 0), m)
    return out.resize((size, size), Image.LANCZOS)


def pick_base(gantz=True):
    """The picker; the centre cell (הפתעה) holds a Gantz tile, as the game's decoy does once."""
    key = ("pick", gantz)
    if key not in _c:
        im = P.take_frame("bennett", 0.2).copy()
        if gantz:
            d = ImageDraw.Draw(im)
            x0, y0, x1, y1 = 384, 1062, 698, 1574                # the centre cell
            tile = im.getpixel((200, 1400))[:3]                    # a neighbour's blue
            d.rectangle((x0 + 8, y0 + 8, x1 - 8, y1 - 8), fill=tile)
            rim = im.getpixel((96, 1140))[:3]
            av = circle(img("avatar_gantz"), 270)
            cx = (x0 + x1) // 2
            d.ellipse((cx - 142, y0 + 22, cx + 142, y0 + 306), fill=rim)
            im.alpha_composite(av, (cx - 135, y0 + 29))
            a = text("גנץ", 7, fill=WHITE, ring=None, shadow=False)
            b = text("כחול לבן", 6, fill=WHITE, ring=None, shadow=False)
            im.alpha_composite(a, (cx - a.width // 2, y0 + 330))
            im.alpha_composite(b, (cx - b.width // 2, y0 + 410))
        _c[key] = im
    return _c[key]


def round_base():
    """The first seconds of a round, the leader painted out and the HUD's name set to Gantz."""
    if "round" not in _c:
        im = P.take_frame("golan", 3.0).copy()
        st = k.stage("balfour", 6)
        im.alpha_composite(st.crop((0, 140 + STAGE_DY, CW, 1062 + STAGE_DY)), (0, 140))
        d = ImageDraw.Draw(im)
        d.rectangle((700, 0, CW, 138), fill=HUD)                  # the name and the avatar
        im.alpha_composite(circle(img("avatar_gantz"), 96), (956, 22))
        nm = text("גנץ", 6, fill=WHITE, ring=None, shadow=False)
        im.alpha_composite(nm, (930 - nm.width, 70 - nm.height // 2))
        d.rectangle((44, 1086, 1036, 1246), fill=im.getpixel((300, 1180))[:3])   # the toast lane, empty
        _c["round"] = im
    return _c["round"]


def gantz(c, t, react_at):
    """Gantz on the mark: idle, or his react (a look at the watch) right after a tap."""
    anim, u = "idle", t
    for ta in react_at:
        if 0 <= t - ta < 10 / 14:
            anim, u = "react", t - ta
    a = k.SPRITES["chars"]["gantz"]["anims"][anim]
    i = min(a["frames"] - 1, int(u * a["fps"])) if anim == "react" else int(u * a["fps"]) % a["frames"]
    fr, anc = char_frame("gantz", anim, i, 2)
    c.alpha_composite(fr, (FEET[0] - anc[0] * 2, FEET[1] - anc[1] * 2))


def hud_money(c, t):
    if t < TAPS[0]:
        return
    d = ImageDraw.Draw(c)
    d.rectangle((300, 4, 690, 134), fill=HUD)
    m = text("₪ 0", 8, fill=GOLD_HI, ring=INK)
    c.alpha_composite(m, (495 - m.width // 2, 46 - m.height // 2))
    r = text("₪0.0 לשנייה", 4, fill=(120, 230, 120), ring=INK)
    c.alpha_composite(r, (495 - r.width // 2, 106 - r.height // 2))


def toast(c, t):
    for t0, t1, who, msg in TOASTS:
        if t0 <= t < t1:
            a = text(who, 4, fill=GOLD_HI, ring=None, shadow=False)
            b = text(msg, 5, fill=WHITE, ring=INK)
            c.alpha_composite(a, (900 - a.width, 1104))
            c.alpha_composite(b, (900 - b.width, 1166))
            av = circle(img("avatar_gantz" if "גנץ" in who else "avatar_dubi"), 110)
            c.alpha_composite(av, (918, 1112))


def chip(c, t):
    """The ability chip (leaders v3 puts it in the sky, top right): a clock, לחכות, and the rotation bar."""
    if t < T_ROUND + 0.6:
        return
    x, y = CHIP
    pressed = T_ABIL + 0.8 <= t < T_ABIL + 1.0
    pl = plate(250, 96, (30, 40, 90) if not pressed else (60, 80, 160), GOLD_SH, 5)
    c.alpha_composite(pl, (x - 125, y - 48))
    ck = img("icon_clock").crop((9 * (int(t * 2) % 4), 0, 9 * (int(t * 2) % 4) + 9, 9)).resize((54, 54), Image.NEAREST)
    c.alpha_composite(ck, (x + 50, y - 27))
    lab = text("לחכות", 5, fill=WHITE, ring=None, shadow=False)
    c.alpha_composite(lab, (x + 34 - lab.width, y - lab.height // 2))
    if t >= BAR0:                                              # the rotation, filling (twice)
        cyc = 3.9
        u = (t - BAR0) % cyc
        fill = min(0.99, u / (BAR1 - BAR0))
        late = u >= (BAR1 - BAR0)
        d = ImageDraw.Draw(c)
        bx0, by0, bx1 = 260, y + 84, 1060
        d.rectangle((bx0 - 8, by0 - 8, bx1 + 8, by0 + 98), fill=INK)
        d.rectangle((bx0, by0, bx1, by0 + 90), fill=(40, 40, 60))
        wdt = int((bx1 - bx0) * fill)
        d.rectangle((bx1 - wdt, by0, bx1, by0 + 90), fill=(250, 80, 80) if late else (120, 200, 255))
        lab = text("רוטציה: %d%%" % int(fill * 100) if not late else "רוטציה: נדחתה", 6, fill=WHITE, ring=INK)
        c.alpha_composite(lab, ((bx0 + bx1) // 2 - lab.width // 2, by0 + 45 - lab.height // 2))


def floats(c, t):
    """Every tap: a ripple where the finger lands and a +0 that floats up."""
    d = ImageDraw.Draw(c)
    for i, ta in enumerate(TAPS):
        u = t - ta
        if 0 <= u < 0.8:
            x, y = FEET[0] + (-60, 40, -20, 70, -50, 20, -70, 50, 0)[i], FEET[1] - 330 + (i % 3) * 40
            if u < 0.3:
                r = int(30 + 90 * u / 0.3)
                d.ellipse((x - r, y - r, x + r, y + r), outline=(255, 255, 255), width=6)
            z = text("+0", 7, fill=GOLD_HI, ring=INK)
            c.alpha_composite(z, (x - z.width // 2, int(y - 80 - u * 160)))


def modal(c, t):
    """The real game, once: Gantz on the picker gets a line and a בחר שוב (leaderSelect.decoy)."""
    c.alpha_composite(Image.new("RGBA", (CW, CH), (0, 0, 20, 150)))
    d = ImageDraw.Draw(c)
    d.rectangle((90, 860, 990, 1460), fill=GOLD_SH)
    d.rectangle((102, 872, 978, 1448), fill=(18, 30, 80))
    tl = text("גנץ לא עבר", 8, fill=GOLD_HI, ring=INK)
    c.alpha_composite(tl, (CW // 2 - tl.width // 2, 930))
    for j, ln in enumerate(("גנץ עוד מחליט אם הוא רץ.", "יחליט בשבוע האחרון. בחר שוב.")):
        x = text(ln, 5, fill=WHITE, ring=None, shadow=False)
        c.alpha_composite(x, (CW // 2 - x.width // 2, 1080 + j * 70))
    pressed = T_REAL + 4.2 <= t < T_REAL + 4.4
    bt = plate(360, 120, GOLD if not pressed else GOLD_HI, INK, 6)
    c.alpha_composite(bt, (CW // 2 - 180, 1270))
    bl = text("בחר שוב", 6, fill=INK, ring=None, shadow=False)
    c.alpha_composite(bl, (CW // 2 - bl.width // 2, 1330 - bl.height // 2))


def game_screen(t):
    """The phone's screen (take px) at time t."""
    if t < T_ROUND:
        c = pick_base().copy()
        if t >= 2.6:                                           # chosen: the others dim, his cell lights
            ov = Image.new("RGBA", (CW, CH), (0, 0, 0, 0))
            od = ImageDraw.Draw(ov)
            od.rectangle((0, 520, CW, 2100), fill=(20, 30, 60, 120))
            od.rectangle((384, 1062, 698, 1574), fill=(0, 0, 0, 0))
            c.alpha_composite(ov)
            ImageDraw.Draw(c).rectangle((380, 1058, 702, 1578), outline=WHITE, width=8)
        return c
    if t < T_REAL:
        c = round_base().copy()
        reacts = [ta for ta in TAPS] + [T_ABIL + 0.8, BAR1, BAR1 + 3.9]
        gantz(c, t - T_ROUND, [x - T_ROUND for x in reacts])
        hud_money(c, t)
        chip(c, t)
        floats(c, t)
        toast(c, t)
        return c
    if t < T_REAL + 4.6:
        c = pick_base().copy()
        modal(c, t)
        return c
    return pick_base(False).copy()                             # the cell is הפתעה again


def touches(t):
    """(x, y, age) of a finger on the screen, take px."""
    out = []
    if 2.6 <= t < 2.9:
        out.append((541, 1300, t - 2.6))
    for i, ta in enumerate(TAPS):
        if 0 <= t - ta < 0.25:
            out.append((FEET[0] + (-60, 40, -20, 70, -50, 20, -70, 50, 0)[i], FEET[1] - 330 + (i % 3) * 40, t - ta))
    if T_ABIL + 0.8 <= t < T_ABIL + 1.05:
        out.append((CHIP[0], CHIP[1], t - T_ABIL - 0.8))
    if T_REAL + 4.2 <= t < T_REAL + 4.45:
        out.append((540, 1330, t - T_REAL - 4.2))
    return out


# ---------------------------------------------------------------------------- the phone

def build():
    if gi.CHROME is None:
        gi.CHROME, gi.MASK, gi.STATUS, gi.GLARE = gi.build_chrome(), gi.build_mask(), gi.build_status(), gi.build_glare()
        gi.SHADOW = gi.build_shadow()


def screen_img(t, s):
    g = game_screen(t)
    d = ImageDraw.Draw(g)
    for x, y, age in touches(t):                               # a soft fingertip
        r = int(46 + 20 * age / 0.25)
        d.ellipse((x - r, y - r, x + r, y + r), fill=(255, 255, 255, 90), outline=(255, 255, 255, 200), width=4)
    sw, sb, gh = round(gi.SW * s), round(gi.SB * s), round(gi.GH * s)
    sh = sb + gh
    scr = Image.new("RGBA", (sw, sh), (0, 0, 0, 255))
    scr.paste(gi.STATUS.resize((sw, sb), Image.LANCZOS), (0, 0))
    scr.paste(g.resize((sw, gh), Image.LANCZOS), (0, sb))
    over = Image.new("RGBA", scr.size, (0, 0, 0, 0))
    hw, hh = 134 / 393 * sw, 5 / 393 * sw
    hy = sh - 5 / 393 * sw
    ImageDraw.Draw(over).rounded_rectangle((sw / 2 - hw / 2, hy - hh, sw / 2 + hw / 2, hy), radius=hh / 2,
                                           fill=(255, 255, 255, 130))
    scr.alpha_composite(over)
    scr.alpha_composite(gi.GLARE.resize((sw, sh), Image.LANCZOS))
    scr.putalpha(gi.MASK.resize((sw, sh), Image.LANCZOS))
    return scr, g


def cam(t):
    """(scale, the phone's centre): wide; in on the stage for the taps; on the chip; wide again.
    The phone's top stays under the caption band, so the HUD (₪0) is always in view."""
    keys = [(0.0, 0.93, 540, 1040), (T_ROUND + 0.3, 0.93, 540, 1040), (T_ROUND + 0.9, 1.15, 540, 1190),
            (T_ABIL - 0.2, 1.15, 540, 1190), (T_ABIL + 0.4, 1.2, 540, 1230), (T_NOTE - 0.2, 1.2, 540, 1230),
            (T_NOTE + 0.3, 1.15, 540, 1190), (T_REAL - 0.2, 1.15, 540, 1190), (T_REAL + 0.2, 1.2, 540, 1080),
            (T_REAL + 4.3, 1.2, 540, 1080), (T_REAL + 4.9, 0.93, 540, 1040)]
    for (t0, s0, x0, y0), (t1, s1, x1, y1) in zip(keys, keys[1:]):
        if t0 <= t < t1:
            u = ease_inout((t - t0) / (t1 - t0))
            return s0 + (s1 - s0) * u, x0 + (x1 - x0) * u, y0 + (y1 - y0) * u
    return keys[-1][1:]


def caption(c, t):
    for s0, e, head, sub in CAPTIONS:
        if s0 <= t < e:
            sc = pop_scale(t, s0, 0.14, 1.3)
            him = text(head, 7, grad=True)
            sim = text(sub, 6)
            show = t - s0 > 0.5
            w = max(him.width, sim.width) + 70
            h = him.height + (sim.height + 14 if show else 0) + 36
            y = 230
            paste(c, scaled(plate(w, h, NIGHT, INK, 6), sc), SAFE_CX, y + h // 2 - 20)
            paste(c, scaled(him, sc), SAFE_CX, y + him.height // 2 - 2)
            if show:
                paste(c, sim, SAFE_CX, y + him.height + 10 + sim.height // 2)


def frame(t):
    if t >= T_END:
        c = Image.new("RGBA", (W, H), INK + (255,))
        R.end_card(c, t - T_END)
        return c.convert("RGB")
    build()
    s, cx, cy = cam(t)
    scr, g = screen_img(t, s)
    bg = g.convert("RGB").resize((72, 156), Image.BILINEAR).filter(ImageFilter.GaussianBlur(2.2))
    bg = bg.resize((W, round(W * CH / CW)), Image.BICUBIC)
    y0 = (bg.height - H) // 2
    c = Image.blend(bg.crop((0, y0, W, y0 + H)), Image.new("RGB", (W, H), INK), 0.62).convert("RGBA")
    k.vignette(c)
    body = gi.CHROME.resize((round((gi.PW + 2 * gi.MARGIN) * s), round(gi.PH * s)), Image.LANCZOS)
    body.alpha_composite(scr, (round((gi.MARGIN + gi.BZ) * s), round(gi.BZ * s)))
    sh_im, pad = gi.SHADOW
    shs = sh_im.resize((round(sh_im.width / 0.5 * s), round(sh_im.height / 0.5 * s)), Image.BILINEAR)
    paste(c, shs, cx + 10 * s, cy + 34 * s)
    paste(c, body, cx, cy)
    flash(c, t, T_ROUND, 0.12, 0.6)
    flash(c, t, T_REAL, 0.12, 0.6)
    caption(c, t)
    return c.convert("RGB")


def audio(path):
    m = P.Mix(DUR)
    R.music(m, "music_balfour_L0", 0.0, 0.0, T_END, -12)
    m.cue(2.6, "leaderPick_D", -4)
    m.cue(T_ROUND, "critReact_D_whoosh", -6)
    for i, ta in enumerate(TAPS):
        m.cue(ta, k.tap_note(0), -9)
        m.cue(ta + 0.05, "cantAfford_D", -16)
    m.cue(8.0, "chatPing_D_default", -8)
    m.cue(T_ABIL + 0.8, "uiClick_D", -4)
    for cyc in (0.0, 3.9):
        m.cue(BAR1 + cyc, "decline_D", -4)
    m.cue(T_NOTE + 0.4, "chatPing_D_default", -8)
    m.cue(T_NOTE + 2.9, "chatPing_D_default", -8)
    m.cue(T_REAL, "critReact_D_no", -3)
    m.cue(T_REAL + 4.2, "uiClick_D", -4)
    R.end_audio(m, T_END)
    m.write(path, 0.6)


def main():
    P.SCRATCH = sys.argv[1]
    if "--stills" in sys.argv:
        ts = [0.5, 2.7, 4.0, 5.3, 7.2, 8.5, 11.5, 13.9, 14.6, 17.5, 20.0, 22.5, 25.0, 26.9, 28.6, 30.8]
        ims = [frame(x).resize((216, 384)) for x in ts]
        sheet = Image.new("RGB", (8 * 220, 2 * 388), (30, 30, 30))
        for i, im in enumerate(ims):
            sheet.paste(im, ((i % 8) * 220, (i // 8) * 388))
        sheet.save(os.path.join(OUT, "_stills_gantz.png"))
        return
    if "--one" in sys.argv:
        frame(float(sys.argv[sys.argv.index("--one") + 1])).save(os.path.join(OUT, "_one.png"))
        return
    name = "od-sevev-reel-gantz"
    wav = os.path.join(P.SCRATCH, "_reel_gantz.wav")
    audio(wav)
    video = os.path.join(OUT, name + ".mp4")
    cmd = [k.ffmpeg(), "-y", "-loglevel", "error",
           "-f", "rawvideo", "-pix_fmt", "rgb24", "-s", f"{W}x{H}", "-r", str(FPS), "-i", "-", "-i", wav,
           "-map", "0:v", "-map", "1:a", "-c:v", "libx264", "-preset", "slow", "-crf", "18", "-pix_fmt", "yuv420p",
           "-profile:v", "high", "-movflags", "+faststart",
           "-af", "loudnorm=I=-14:TP=-1.0:LRA=11,volume=2dB,alimiter=limit=0.89:level=false",
           "-c:a", "aac", "-b:a", "192k", "-ar", "48000", "-t", str(DUR), video]
    p = subprocess.Popen(cmd, stdin=subprocess.PIPE)
    cover = frame(T_ABIL + 4.3)
    cover.save(os.path.join(OUT, name + "-cover.png"))
    for i in range(int(DUR * FPS)):
        p.stdin.write((cover if i < 2 else frame(i / FPS)).tobytes())
    p.stdin.close()
    if p.wait() != 0:
        raise SystemExit("ffmpeg failed")
    print(video)


if __name__ == "__main__":
    main()
