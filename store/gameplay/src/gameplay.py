"""'עוד סבב' gameplay reel: Ben Gvir's round, with Mordechai David as an easter egg (Bar: not a host). 1080x1920 @ 30 fps, 68 s,
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


PANEL_H = H             # the game fills the frame (v2: no host strip; Mordechai David is an easter egg)
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
    (BAR(6), BAR(8), 9.0, 1.2, 300),       # the drop: buying sources (more cards in view)
    (BAR(8), BAR(10), 15.0, 1.0, 300),     # more sources
    (BAR(10), BAR(12) + 1.0, 21.5, 1.0, 0),  # the in-game blockade (his real cameo)
    (BAR(12) + 1.0, BAR(13), 27.0, 0.6, 0),  # the break: hold on the toast
    (BAR(13), BAR(17), 32.3, 1.0, 0),      # the coalition chat, paying
    (BAR(17), BAR(21), 40.0, 1.3, 0),      # the numbers go up
    (BAR(21), BAR(23), 50.3, 1.0, 0),      # 47 of 61: still short
]
T_END = BAR(23)

CAPTIONS = [  # (start, end, headline, sub): the narration is the captions (sound-off first)
    (0.15, BAR(2), "איך משחקים בתור בן גביר?", ""),
    (BAR(2), BAR(4), "בוחרים ראש רשימה", ""),
    (BAR(4), BAR(6), "כל לחיצה = העברה", "של אותה הודעה."),
    (BAR(6), BAR(8), "קונים מקורות", "משלם המסים נאנח. זה נחשב הסכמה."),
    (BAR(8), BAR(10), "חוג בית", "סלון, בורקס והעברה בנקאית."),
    (BAR(10), BAR(13), "אירוע: חסימה", "השר שלך תקוע בפקק."),
    (BAR(13), BAR(15), "משלמים לשותפים", "כולם רוצים תקציב."),
    (BAR(15), BAR(17), "ובן גביר?", "מאיים לפרוש. לפי לוח זמנים."),
    (BAR(17), BAR(19), "העברה, העברה, העברה", ""),
    (BAR(19), BAR(21), "עוד תקציב", "מחר: דרישה להגדלה."),
    (BAR(21), BAR(23), "47 מתוך 61", "אז... עוד סבב."),
]

PEEKS = [  # (start, length, line): Mordechai David, the easter egg: a peek from the bottom corner
    (BAR(5) + 1.2, 1.6, "חוסם."),
    (DUR - 3.6, 1.8, "חוסם."),
]


def md_frame(anim, t_local, scale):
    a = SPRITES["chars"][MD]["anims"][anim]
    n = a["frames"]
    i = int(t_local * a["fps"])
    i = i % n if a.get("loop", anim in ("idle", "block")) else min(i, n - 1)
    return char_frame(MD, anim, i, scale)


def peek(c, t):
    """The easter egg: he rises from the bottom-left corner, holds a beat, and ducks back down."""
    for t0, ln, line in PEEKS:
        u = t - t0
        if not 0 <= u < ln:
            continue
        rise = min(ease_out(u / 0.25), ease_out((ln - u) / 0.25))
        fr, anc = md_frame("block" if u > 0.35 else "block_in", max(0.0, u - 0.35) if u > 0.35 else u, 2)
        y = H - int(rise * 330)
        paste(c, fr, 150 - anc[0] * 2, y, "tl")
        if u > 0.3 and ln - u > 0.25:
            b = k.bubble(line, 5)
            paste(c, b, 250, y - 200)   # above the caption plate, never on it


GAME_H = H                                  # v3: the whole phone screen, never cropped
GAME_W = round(W * GAME_H / 2338)           # 887 px: the 1080x2338 capture scaled to the reel's height
GAME_X = (W - GAME_W) // 2


def panel(c, t):
    """The full game screen, scaled to the frame's height, on the game's velvet with a gold rim."""
    for vs, ve, ts, sp, _cy in CLIPS:
        if vs <= t < ve:
            curtain(c, 0, dim=0.35)
            d = ImageDraw.Draw(c)
            d.rectangle((GAME_X - 12, 0, GAME_X + GAME_W + 11, H), fill=GOLD_SH)
            d.rectangle((GAME_X - 6, 0, GAME_X + GAME_W + 5, H), fill=INK)
            fr = take_frame(ts + (t - vs) * sp)
            key = ("scaled", id(fr))
            if key not in _frames:
                _frames[key] = fr.resize((GAME_W, GAME_H), Image.LANCZOS)
            c.paste(_frames[key], (GAME_X, 0))
            flash(c, t, vs, 0.08, 0.35)
            return True
    return False


def captions(c, t):
    for s0, e, head, sub in CAPTIONS:
        if s0 <= t < e:
            sc = pop_scale(t, s0, 0.14, 1.3)
            y = 1480
            him = text(head, 8, grad=True)
            sim = text(sub, 6) if sub else None
            w = max(him.width, sim.width if sim else 0) + 70
            h = him.height + (sim.height + 14 if sim else 0) + 36
            paste(c, scaled(plate(w, h, NIGHT, INK, 6), sc), W // 2, y + h // 2 - 20)
            paste(c, scaled(him, sc), W // 2, y + him.height // 2 - 2)
            if sim and t - s0 > 0.35:
                paste(c, sim, W // 2, y + him.height + 10 + sim.height // 2)


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
    peek(c, t)
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
