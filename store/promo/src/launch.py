"""'עכשיו באוויר': the 15 s launch share, 9:16 (Oct 2026). The game is live on od-sevev.bar-builds.com.

Every earlier video ends on "בקרוב"; this one ends on the link. Six bars of the real game, cut from the
finished one-minute iPhone montage (store/gameplay/od-sevev-teaser-mix.mp4, its own captions kept),
then the curtain card with the eight, "עכשיו באוויר" and the address. The footage is read from the mp4,
so no capture takes are needed.

Music: glitch-warfare.wav from the montage's bar 6, so the drop lands on this cut's bar 2, where the
montage starts cutting a bar at a time. Every cut is on a bar line (a bar is 1.808 s).

The cover (also frames 0-1) is the finished end card: the address is the thumbnail.

    python3 store/promo/src/launch.py [--stills | --one <sec>]
"""
import os
import subprocess
import sys

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, "..", "..", "teaser", "src"))
import promo as P  # noqa: E402
import teaser as k  # noqa: E402
from teaser import (INK, GOLD_HI, WHITE, W, H, FPS, paste, scaled, text, plate, badge, slam, pop_scale,  # noqa: E402
                    clamp, ease_out)

OUT = P.OUT
NAME = "od-sevev-launch"
SRC = os.path.join(P.GAMEPLAY, "od-sevev-teaser-mix.mp4")
A0 = 19.634                        # the track's bar 10 = the montage's bar 0
BARLEN = 1.808
BEAT = BARLEN / 4
DUR = 15.0
URL = "od-sevev.bar-builds.com"


def VB(j):
    return BARLEN * j


CUTS = [  # (this cut's bars, the montage's bar it starts on): its captions ride along
    (2, 0),    # "8 ראשי רשימה. אף אחד לא מגיע ל־61." the eight, a beat each
    (1, 4),    # "כל לחיצה: שקל."
    (1, 12),   # "מרכיבים קואליציה."
    (1, 20),   # "לא אשב."
    (1, 26),   # "אין 61? בחירות. שוב."
]
T_END = VB(sum(n for n, _ in CUTS))         # 10.85: the end card
MUSIC_AT = A0 + VB(6)                       # the drop (montage bar 8) on this cut's bar 2


def segments():
    out, t = [], 0.0
    for n, src_bar in CUTS:
        out.append((t, t + VB(n), VB(src_bar)))
        t += VB(n)
    return out


# ---------------------------------------------------------------------------- footage

class Reader:
    """Sequential frames of one segment from the mp4 (one ffmpeg per segment)."""

    def __init__(self):
        self.seg, self.p, self.i = None, None, 0

    def frame(self, seg, j):
        if seg != self.seg or j < self.i:
            if self.p:
                self.p.kill()
            t0, t1, s0 = seg
            n = int(round((t1 - t0) * FPS)) + 2
            self.p = subprocess.Popen([k.ffmpeg(), "-v", "error", "-ss", "%.4f" % s0, "-i", SRC, "-frames:v", str(n),
                                       "-f", "rawvideo", "-pix_fmt", "rgb24", "-"], stdout=subprocess.PIPE)
            self.seg, self.i, self.last = seg, 0, None
        while self.i <= j:
            buf = self.p.stdout.read(W * H * 3)
            if len(buf) == W * H * 3:
                self.last = Image.frombuffer("RGB", (W, H), buf).convert("RGBA")
            self.i += 1
        return self.last


R = Reader()


def footage(t):
    for seg in segments():
        if seg[0] <= t < seg[1]:
            j = int(round((t - seg[0]) * FPS))
            return R.frame(seg, max(j, 2) if seg[2] == 0 else j)   # the montage's frames 0-1 are its cover
    return None


# ---------------------------------------------------------------------------- end card

LINEUP = ["bibi", "bennett", "ben-gvir", "liberman", "smotrich", "eisenkot", "deri", "golan"]


def end_card(c, tt):
    """The montage's curtain card, with the link where "בקרוב" used to be."""
    k.curtain(c, 0, dim=0.15)
    k.spotlight(c, W // 2, 0, 1400, 90, 480, 0.2, GOLD_HI)
    k.vignette(c)
    s = pop_scale(tt, 0, 0.18, 0.2)
    if s:
        paste(c, scaled(k.img("wordmark", 6), s), W // 2, 300)
    if tt >= 0.2:
        paste(c, text("הבחירות שלא נגמרות", 9), W // 2, 490)
    n = len(LINEUP)
    for i, who in enumerate(LINEUP):
        t0 = 0.15 + i * BEAT / 3
        if tt < t0:
            continue
        rise = ease_out(clamp((tt - t0) / 0.22))
        ch = k.SPRITES["chars"][who]
        a = ch["anims"]["idle"]
        fr, anc = k.char_frame(who, "idle", int((tt - t0) * a["fps"]) % a["frames"], 1)
        x = 115 + i * (850 / (n - 1))
        y = 1020 + int((1 - rise) * 260)
        paste(c, fr, x - anc[0], y - anc[1], "tl")
    t_badge = 0.15 + n * BEAT / 3              # beat 3 of the card, as the last one lands
    if tt >= t_badge:
        slam(c, badge("עכשיו באוויר", 12), tt, t_badge, W // 2, 1150, angle=-4, frm=2.4)
        k.flash(c, tt, t_badge, 0.1, 0.5, GOLD_HI)
    if tt >= t_badge + BEAT:
        u = text(URL, 6, fill=WHITE, rtl=False)
        sc = pop_scale(tt, t_badge + BEAT, 0.14, 1.3)
        pl = plate(u.width + 56, u.height + 34, INK, k.GOLD, 6)
        paste(c, scaled(pl, sc), W // 2, 1345)
        paste(c, scaled(u, sc), W // 2, 1345)
    if tt >= t_badge + 2 * BEAT:
        paste(c, text("לשחק בחינם, בדפדפן. בלי הורדה.", 6, fill=GOLD_HI), W // 2, 1450)
        paste(c, text("סאטירה. לא מטעם אף מפלגה.", 4, fill=(190, 196, 220)), W // 2, 1525)
    k.flash(c, tt, 0, 0.16, 1.0)


def frame(t):
    if t < T_END:
        c = footage(t).copy()
        for t0, _, _ in segments()[1:]:          # a soft white kiss on every cut
            k.flash(c, t, t0, 0.08, 0.35)
        return c.convert("RGB")
    c = Image.new("RGBA", (W, H), INK + (255,))
    end_card(c, t - T_END)
    return c.convert("RGB")


COVER_T = DUR - 0.05


# ---------------------------------------------------------------------------- audio

def audio(path):
    m = P.Mix(DUR)
    a = P.music_seg(os.path.join(P.GAMEPLAY, "music", "glitch-warfare.wav"), MUSIC_AT, DUR)
    f = int(0.5 * P.SR)
    a = a.copy()
    a[-f:] *= np.linspace(1, 0, f)
    m.put(0.0, a, -6)
    for t0, _, _ in segments()[1:]:
        m.cue(t0, "slipStamp", -12)
    t_badge = T_END + 0.15 + len(LINEUP) * BEAT / 3
    m.cue(T_END, "leaderPick_D", -6)
    m.cue(t_badge, "stamp", -2)
    m.write(path, 0.6)


# ---------------------------------------------------------------------------- render

def main():
    if "--stills" in sys.argv:
        ts = [round(x * (DUR - 0.05) / 15, 2) for x in range(16)]
        ims = [frame(x).resize((216, 384)) for x in ts]
        sheet = Image.new("RGB", (8 * 220, 2 * 388), (30, 30, 30))
        for i, im in enumerate(ims):
            sheet.paste(im, ((i % 8) * 220, (i // 8) * 388))
        sheet.save(os.path.join(OUT, "_stills_launch.png"))
        return
    if "--one" in sys.argv:
        frame(float(sys.argv[sys.argv.index("--one") + 1])).save(os.path.join(OUT, "_one.png"))
        return
    wav = os.path.join(OUT, "_launch.wav")
    audio(wav)
    video = os.path.join(OUT, NAME + ".mp4")
    cmd = [k.ffmpeg(), "-y", "-loglevel", "error",
           "-f", "rawvideo", "-pix_fmt", "rgb24", "-s", f"{W}x{H}", "-r", str(FPS), "-i", "-", "-i", wav,
           "-map", "0:v", "-map", "1:a", "-c:v", "libx264", "-preset", "slow", "-crf", "18", "-pix_fmt", "yuv420p",
           "-profile:v", "high", "-movflags", "+faststart",
           "-af", "loudnorm=I=-14:TP=-1.0:LRA=11,volume=2dB,alimiter=limit=0.89:level=false",
           "-c:a", "aac", "-b:a", "192k", "-ar", "48000", "-t", str(DUR), video]
    p = subprocess.Popen(cmd, stdin=subprocess.PIPE)
    cover = frame(COVER_T)
    cover.save(os.path.join(OUT, NAME + "-cover.png"))
    for i in range(int(DUR * FPS)):
        p.stdin.write((cover if i < 2 else frame(i / FPS)).tobytes())
    p.stdin.close()
    if p.wait() != 0:
        raise SystemExit("ffmpeg failed")
    os.remove(wav)
    print(video)


if __name__ == "__main__":
    main()
