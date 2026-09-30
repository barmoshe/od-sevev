"""'עוד סבב' gameplay reel: Ben Gvir's round, hosted by Mordechai David. 1080x1920 @ 30 fps, 68 s,
cut to Bar's soundtrack (store/gameplay/music/soundtrack.wav: 98.4 BPM, bar lines at 0.092 + 2.438 k).

The footage is the real game: a scripted round recorded with Godot's Movie Maker (1080x2338, fixed
30 fps) through the capture driver game/tests/dev/gameplay_capture.gd (see capture notes in the README).
The host strip, captions and the end card are drawn here with the teaser kit (store/teaser/src/teaser.py).

    python3 store/gameplay/src/gameplay.py <take dir>            # -> store/gameplay/od-sevev-gameplay.mp4
    python3 store/gameplay/src/gameplay.py <take dir> --stills   # key-frame contact sheet
"""
import math
import os
import subprocess
import sys
import wave

import numpy as np
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "teaser", "src"))
import teaser as k  # noqa: E402
from teaser import (INK, NIGHT, NAVY, GOLD, GOLD_HI, GOLD_SH, WHITE, RED, W, H, FPS, img, paste, scaled,  # noqa: E402
                    fade, overlay, text, plate, char_frame, curtain, spotlight, vignette, coins_burst, rain,
                    flash, pop_scale, badge, slam, clamp, ease_out, SPRITES)

OUT = os.path.join(HERE, "..")
MUSIC = os.path.join(OUT, "music", "soundtrack.wav")
DUR = 68.0
BEAT = 0.6095
PH = 0.092


def BAR(n):
    return PH + 4 * BEAT * n


PANEL_H = 1440          # the game on top, the host strip under it
HUD_H = 150             # the game's top bar (the ₪ counter), measured on a 1080-wide frame
MD = "mordechai-david"
TAKE = None             # set in main: the Movie Maker frame folder
_frames = {}


def take_frame(t_take):
    i = max(0, int(round(t_take * FPS)))
    if i in _frames:
        return _frames[i]
    path = os.path.join(TAKE, "f%08d.png" % i)
    while not os.path.exists(path) and i > 0:
        i -= 1
        path = os.path.join(TAKE, "f%08d.png" % i)
    im = Image.open(path).convert("RGBA")
    if len(_frames) > 12:
        _frames.clear()
    _frames[i] = im
    return im


# (video start, video end, take start, speed, crop y). Video spans follow the bar grid.
CLIPS = [
    (0.0, BAR(2), 5.0, 1.0, 0),            # hook: the forwarding frenzy
    (BAR(2), BAR(4), 0.3, 1.0, 0),         # the picker: Ben Gvir
    (BAR(4), BAR(6), 3.0, 1.0, 0),         # the first taps
    (BAR(6), BAR(8), 9.0, 1.2, 380),       # the drop: buying sources
    (BAR(8), BAR(10), 15.0, 1.0, 380),     # more sources
    (BAR(10), BAR(12) + 1.0, 21.5, 1.0, 0),  # Mordechai David blocks (the stage)
    (BAR(12) + 1.0, BAR(13), 27.0, 0.6, 0),  # the break: hold on the toast
    (BAR(13), BAR(17), 32.3, 1.0, 380),    # the coalition chat, paying
    (BAR(17), BAR(21), 40.0, 1.3, 380),    # the numbers go up
    (BAR(21), BAR(23), 54.6, 1.0, 0),      # the election
]
T_END = BAR(23)

CAPTIONS = [  # (start, end, text): the step, on the panel
    (BAR(2), BAR(4), "בוחרים ראש רשימה"),
    (BAR(4), BAR(6), "כל לחיצה = העברה"),
    (BAR(6), BAR(10), "קונים מקורות"),
    (BAR(10), BAR(13), "אירוע: חסימה"),
    (BAR(13), BAR(17), "משלמים לשותפים"),
    (BAR(17), BAR(21), "מגיעים ל־61"),
    (BAR(21), BAR(23), "בחירות. שוב."),
]

LINES = [  # (start, end, line, pose): Mordechai David, the host
    (0.15, BAR(1), "רגע! אני חוסם אותך.", "block"),
    (BAR(1), BAR(2), "תראה איך הבוס שלי משחק.", "idle"),
    (BAR(2), BAR(4), "שלב 1: בוחרים את בן גביר. ברור.", "idle"),
    (BAR(4), BAR(6), "כל לחיצה זו העברה. של אותה הודעה.", "glance"),
    (BAR(6), BAR(8), "משלם המסים נאנח. זה נחשב הסכמה.", "idle"),
    (BAR(8), BAR(10), "חוג בית: סלון, בורקס והעברה בנקאית.", "glance"),
    (BAR(10), BAR(11) + 0.6, "רגע... זה אני!", "idle"),
    (BAR(11) + 0.6, BAR(13), "סליחה, בוס. השר שלך תקוע.", "block"),
    (BAR(13), BAR(15), "השותפים רוצים תקציב.", "idle"),
    (BAR(15), BAR(17), "בן גביר? מאיים לפרוש. לפי לוח זמנים.", "glance"),
    (BAR(17), BAR(19), "העברה, העברה, העברה.", "idle"),
    (BAR(19), BAR(21), "עוד תקציב. מחר: דרישה להגדלה.", "glance"),
    (BAR(21), BAR(23), "ואז... בחירות. שוב.", "idle"),
    (BAR(23), DUR, "אני חוסם אותך... עד שתעקוב.", "block"),
]


def md_frame(anim, t_local, scale):
    a = SPRITES["chars"][MD]["anims"][anim]
    n = a["frames"]
    i = int(t_local * a["fps"])
    i = i % n if a.get("loop", anim in ("idle", "block")) else min(i, n - 1)
    return char_frame(MD, anim, i, scale)


def host_strip(c, t):
    """The bottom band: a dark studio strip, the host's bust on the left, his line on the right."""
    y0 = PANEL_H
    d = ImageDraw.Draw(c)
    d.rectangle((0, y0, W, H), fill=(14, 20, 44))
    for x in range(0, W, 36):   # a faint pixel grid, the game's UI texture
        d.line((x, y0, x, H), fill=(20, 28, 58))
    d.rectangle((0, y0, W, y0 + 9), fill=GOLD_SH)
    d.rectangle((0, y0 + 9, W, y0 + 15), fill=INK)
    # "live" chip, top right of the strip
    chip = text("משדר חי", 5, fill=WHITE, ring=None, shadow=False)
    paste(c, plate(chip.width + 36, chip.height + 18, RED, INK, 4), W - 120, y0 + 52)
    paste(c, chip, W - 120, y0 + 52)
    line = pose = None
    t0 = 0.0
    for s, e, ln, ps in LINES:
        if s <= t < e:
            line, pose, t0 = ln, ps, s
    # the bust: scale 2, feet below the frame, the head and torso in view
    u = t - t0
    anim = {"block": "block" if u > 4 / 12 else "block_in", "glance": "glance", "idle": "idle"}.get(pose or "idle")
    fr, anc = md_frame(anim, u if anim != "block" else u - 4 / 12, 3)
    bob = int(math.sin(t * 9) * 3) // 3 * 3 if line and u < 1.6 else 0
    paste(c, fr, 200 - anc[0] * 3, y0 + 22 + bob, "tl")   # the bust: head and torso in the strip
    # name plate over his chest
    nm = text("מרדכי דוד", 6, grad=True)
    paste(c, plate(nm.width + 40, nm.height + 22, NIGHT, GOLD_SH, 5), 200, H - 110)
    paste(c, nm, 200, H - 110)
    if line:
        n = max(1, int(u * 30))   # the line types on, 30 chars a second
        shown = line[:n] if n < len(line) else line
        bubble_text(c, shown, line, 440, y0 + 110, 540)


def bubble_text(c, shown, full, x0, y0, wmax):
    """A speech bubble sized for the full line (so it doesn't grow while typing), wrapped to 2 lines."""
    words = full.split(" ")
    px = 6
    lines, cur = [], ""
    for wd in words:
        trial = (cur + " " + wd).strip()
        if text(trial, px, ring=None, shadow=False).width > wmax - 40 and cur:
            lines.append(cur)
            cur = wd
        else:
            cur = trial
    lines.append(cur)
    lh = 11 * px + 8
    bw, bh = wmax, len(lines) * lh + 36
    d = ImageDraw.Draw(c)
    d.rectangle((x0, y0, x0 + bw, y0 + bh), fill=INK)
    d.rectangle((x0 + 6, y0 + 6, x0 + bw - 6, y0 + bh - 6), fill=WHITE)
    d.polygon([(x0 + 6, y0 + 40), (x0 - 34, y0 + 60), (x0 + 6, y0 + 80)], fill=INK)
    d.polygon([(x0 + 8, y0 + 50), (x0 - 18, y0 + 60), (x0 + 8, y0 + 70)], fill=WHITE)
    left = len(shown)
    for i, ln in enumerate(lines):
        part = ln[:max(0, left)]
        left -= len(ln) + 1
        if part:
            im = text(part, px, fill=INK, ring=None, shadow=False)
            paste(c, im, x0 + bw - 22 - im.width, y0 + 18 + i * lh, "tl")   # RTL: right-aligned


def panel(c, t):
    for vs, ve, ts, sp, cy in CLIPS:
        if vs <= t < ve:
            fr = take_frame(ts + (t - vs) * sp)
            c.paste(fr.crop((0, cy, W, cy + PANEL_H)), (0, 0))
            if cy > 0:   # the game's HUD (the ₪ counter) stays on every shot
                c.paste(fr.crop((0, 0, W, HUD_H)), (0, 0))
                ImageDraw.Draw(c).rectangle((0, HUD_H, W, HUD_H + 5), fill=INK)
            flash(c, t, vs, 0.08, 0.35)
            return True
    return False


def captions(c, t):
    for s, e, tx in CAPTIONS:
        if s <= t < e:
            im = text(tx, 7, grad=True)
            sc = pop_scale(t, s, 0.14, 1.3)
            y = 1300
            paste(c, scaled(plate(im.width + 60, im.height + 30, NIGHT, INK, 6), sc), W // 2, y)
            paste(c, scaled(im, sc), W // 2, y)


def end_card(c, t):
    tt = t - T_END
    curtain(c, 0, dim=0.15)
    spotlight(c, W // 2, 0, 1400, 90, 480, 0.2, GOLD_HI)
    rain(c, t, T_END + 0.3, 5, n=40)
    vignette(c)
    coins_burst(c, tt, 0, W // 2, 700, n=60, seed=77, life=2.2, kinds=("coin", "coin", "slip", "bill"))
    wm = img("wordmark", 6)
    s = pop_scale(tt, 0, 0.18, 0.2)
    if s:
        paste(c, scaled(wm, s), W // 2, 420)
    if tt >= 0.4:
        paste(c, text("הבחירות שלא נגמרות", 9), W // 2, 640)
    if tt >= 1.2:
        slam(c, badge("בקרוב"), tt, 1.2, W // 2, 900, angle=-4, frm=2.4)
    if tt >= 1.8:
        cta = text("עקבו: @od.sevev", 8)
        paste(c, plate(cta.width + 50, cta.height + 26, INK, INK, 6), W // 2, 1110)
        paste(c, cta, W // 2, 1110)
    if tt >= 2.2:
        paste(c, text("סאטירה. לא מטעם אף מפלגה.", 5, fill=(190, 196, 220)), W // 2, 1230)
    flash(c, tt, 0, 0.16, 1.0)


def frame(t):
    c = Image.new("RGBA", (W, H), INK + (255,))
    if t < T_END:
        panel(c, t)
        captions(c, t)
    else:
        end_card(c, t)
    host_strip(c, t)
    return c.convert("RGB")


def main():
    global TAKE
    TAKE = sys.argv[1]
    if "--stills" in sys.argv:
        ts = [0.5, 2.0, 5.5, 8.0, 11.0, 13.5, 16.0, 19.0, 21.0, 24.0, 26.0, 28.5, 30.5, 33.0, 36.0, 40.0,
              43.0, 47.0, 50.0, 52.5, 55.0, 57.0, 60.0, 66.0]
        k.frame = frame
        k.OUT = OUT
        k.stills(ts, os.path.join(OUT, "_stills.png"))
        os.replace(os.path.join(OUT, "_stills.png"), os.path.join(OUT, "_stills_gameplay.png"))
        return
    video = os.path.join(OUT, "od-sevev-gameplay.mp4")
    cmd = [k.ffmpeg(), "-y", "-loglevel", "error",
           "-f", "rawvideo", "-pix_fmt", "rgb24", "-s", f"{W}x{H}", "-r", str(FPS), "-i", "-", "-i", MUSIC,
           "-map", "0:v", "-map", "1:a",
           "-c:v", "libx264", "-preset", "slow", "-crf", "17", "-pix_fmt", "yuv420p", "-profile:v", "high",
           "-movflags", "+faststart", "-af", f"afade=t=out:st={DUR - 0.4}:d=0.4,loudnorm=I=-14:TP=-1.0:LRA=11",
           "-c:a", "aac", "-b:a", "192k", "-ar", "48000", "-t", str(DUR), video]
    p = subprocess.Popen(cmd, stdin=subprocess.PIPE)
    nf = int(DUR * FPS)
    cover = frame((nf - 1) / FPS)
    cover.save(os.path.join(OUT, "od-sevev-gameplay-cover.png"))
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
