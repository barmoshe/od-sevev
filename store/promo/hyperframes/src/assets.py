"""Assets for the HyperFrames Reels: the game's own pixel lettering, footage, sound and end card.

    python3 src/assets.py <takes> crash|calendar|howto|all

<takes> is a scratch folder holding Movie Maker captures (take_<leader>/f%08d.png + f.wav), made
as in store/gameplay/README.md from store/gameplay/plans/plan-<leader>.json. Everything lands in
<reel>/assets/gen/ (git-ignored); the HyperFrames page (<reel>/index.html) only composes it.

Hebrew is drawn by the teaser kit's Sevev 9 font (teaser.text), the same lettering as every other
promo, so the browser never shapes Hebrew itself. Sound comes from the game's .res files
(teaser.load_wav) and the takes' own audio; the end card is the series' shared sign-off, cut from
od-sevev-reel-ghost.mp4 (reels5.end_card, the last 2.2 s).
"""
import json
import os
import subprocess
import sys
import wave

import numpy as np
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)  # store/promo/hyperframes
PROMO = os.path.dirname(ROOT)
sys.path.insert(0, os.path.join(PROMO, "..", "teaser", "src"))
import teaser as k  # noqa: E402
from teaser import INK, NAVY, GOLD, GOLD_HI, WHITE, RED, PAPER, text, img, badge  # noqa: E402

SR = 48000
FPS = 30
END = 2.2  # the shared end card's length (reels5.END)


def out(reel, *parts):
    p = os.path.join(ROOT, reel, "assets", "gen", *parts)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    return p


# ---------- lettering ----------

def labels(reel, items):
    """items: {id: (line, px, fill, ring)}; writes gen/text/<id>.png and a size manifest."""
    sizes = {}
    for key, spec in items.items():
        line, px = spec[0], spec[1]
        fill = spec[2] if len(spec) > 2 else WHITE
        ring = spec[3] if len(spec) > 3 else INK
        rtl = spec[4] if len(spec) > 4 else True
        im = text(line, px, fill=fill, ring=ring, shadow=ring is not None, rtl=rtl)
        im.save(out(reel, "text", key + ".png"))
        sizes[key] = [im.width, im.height]
    with open(out(reel, "text", "sizes.json"), "w") as f:
        json.dump(sizes, f, ensure_ascii=False, indent=1)


def sprite(reel, name, scale, key=None):
    im = img(name, scale)
    im.save(out(reel, "img", (key or name) + ".png"))
    return im.size


# ---------- footage ----------

def clip(reel, key, take, f0, f1, crop=None, scale=None):
    """Frames f0..f1 (inclusive) of a take as a silent H.264 clip; crop = (x, y, w, h) in take px."""
    vf = []
    if crop:
        vf.append("crop=%d:%d:%d:%d" % (crop[2], crop[3], crop[0], crop[1]))
    if scale:
        vf.append("scale=%d:%d:flags=lanczos" % scale)
    cmd = ["ffmpeg", "-loglevel", "error", "-y", "-framerate", str(FPS), "-start_number", str(f0),
           "-i", os.path.join(take, "f%08d.png"), "-frames:v", str(f1 - f0 + 1)]
    if vf:
        cmd += ["-vf", ",".join(vf)]
    cmd += ["-c:v", "libx264", "-crf", "14", "-pix_fmt", "yuv420p", "-an", out(reel, "video", key + ".mp4")]
    subprocess.run(cmd, check=True)


def still(reel, key, take, frame, crop=None, scale=None):
    im = Image.open(os.path.join(take, "f%08d.png" % frame)).convert("RGB")
    if crop:
        im = im.crop((crop[0], crop[1], crop[0] + crop[2], crop[1] + crop[3]))
    if scale:
        im = im.resize(scale, Image.LANCZOS)
    im.save(out(reel, "img", key + ".png"))


def end_card(reel):
    src = os.path.join(PROMO, "od-sevev-reel-ghost.mp4")
    subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-sseof", "-%.2f" % END, "-i", src,
                    "-c:v", "libx264", "-crf", "14", "-pix_fmt", "yuv420p", "-c:a", "aac", "-b:a", "192k",
                    out(reel, "video", "endcard.mp4")], check=True)


# ---------- sound ----------

def game_wav(name):
    a = k.load_wav(name)
    return a if a.ndim == 1 else a.mean(axis=1)


def take_wav(take, t0, t1):
    w = wave.open(os.path.join(take, "f.wav"))
    sr, ch, sw = w.getframerate(), w.getnchannels(), w.getsampwidth()
    raw = w.readframes(w.getnframes())
    a = (np.frombuffer(raw, np.int32).astype(np.float32) / 2 ** 31 if sw == 4  # Movie Maker writes 32-bit
         else np.frombuffer(raw, np.int16).astype(np.float32) / 32768)
    a = a.reshape(-1, ch).mean(axis=1)
    if sr != SR:
        a = np.interp(np.arange(0, len(a), sr / SR), np.arange(len(a)), a)
    return a[int(t0 * SR): int(t1 * SR)]


class Mix:
    def __init__(self, dur):
        self.a = np.zeros(int(dur * SR), np.float32)

    def add(self, sig, at, db=0.0, fade_in=0.0, fade_out=0.0, length=None):
        sig = np.asarray(sig, np.float32)
        if length is not None:
            n = int(length * SR)
            sig = np.tile(sig, n // len(sig) + 1)[:n] if len(sig) < n else sig[:n]
        sig = sig * (10 ** (db / 20))
        if fade_in:
            n = min(len(sig), int(fade_in * SR)); sig[:n] *= np.linspace(0, 1, n)
        if fade_out:
            n = min(len(sig), int(fade_out * SR)); sig[-n:] *= np.linspace(1, 0, n)
        i = int(at * SR)
        j = min(len(self.a), i + len(sig))
        self.a[i:j] += sig[: j - i]

    def write(self, path, peak_db=-1.0):
        a = self.a
        p = np.abs(a).max() or 1.0
        lim = 10 ** (peak_db / 20)
        if p > lim:
            a = np.tanh(a / p * 1.4) / np.tanh(1.4) * lim  # soft limit the few hot peaks
        st = np.repeat((a * 32767).astype(np.int16)[:, None], 2, axis=1)
        w = wave.open(path, "wb")
        w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes(st.tobytes()); w.close()


def tone(freqs, dur, decay=6.0, shape="sine"):
    t = np.arange(int(dur * SR)) / SR
    s = np.zeros_like(t)
    for f in freqs:
        s += np.sin(2 * np.pi * f * t) if shape == "sine" else np.sign(np.sin(2 * np.pi * f * t)) * 0.5
    return (s / len(freqs) * np.exp(-decay * t)).astype(np.float32)


def click():
    rng = np.random.default_rng(7)  # fixed seed: the render stays deterministic
    n = int(0.018 * SR)
    return (rng.uniform(-1, 1, n) * np.exp(-np.linspace(0, 9, n))).astype(np.float32) * 0.8


def lowpass(a, cutoff):
    """One-pole low-pass, for the 'on hold' phone sound."""
    x = np.exp(-2 * np.pi * cutoff / SR)
    y = np.zeros_like(a)
    acc = 0.0
    for i, v in enumerate(a):
        acc = (1 - x) * v + x * acc
        y[i] = acc
    return y


# ---------- the reels ----------

def crash(takes):
    R = "crash"
    g, b, d = (os.path.join(takes, "take_" + n) for n in ("golan", "bennett", "deri"))
    # The window shows the top of the game (stage, ticker, first cards): 1080x1271 into 880x1036.
    crop, size = (0, 0, 1080, 1271), (880, 1036)
    clip(R, "play-bennett", b, 150, 166, crop, size)
    clip(R, "play-deri", d, 150, 166, crop, size)
    clip(R, "play-golan", g, 150, 165, crop, size)
    clip(R, "picker", g, 12, 30, crop, size)
    still(R, "picker-frozen", g, 30, crop, size)
    end_card(R)
    labels(R, {
        "win-title": ("עוד סבב", 5, WHITE),
        "win-title-hung": ("עוד סבב · לא מגיב", 5, WHITE),
        "dlg-title": ("עוד סבב", 5, WHITE),
        "dlg-l1": ("הקואליציה לא מגיבה.", 7, INK, None),
        "dlg-l2": ("אפשר לחכות לרוטציה,", 5, INK, None),
        "dlg-l3": ("או לפזר את הכנסת.", 5, INK, None),
        "btn-wait": ("לחכות לרוטציה", 4, INK, None),
        "btn-dissolve": ("לפזר את הכנסת", 4, INK, None),
        "prog-title": ("מחכה לרוטציה…", 5, WHITE),
        "prog-l1": ("מחכה לרוטציה…", 6, INK, None),
        "prog-eta": ("הזמן שנותר: חצי קדנציה", 5, INK, None),
        "prog-fail": ("הרוטציה נדחתה.", 6, RED, None),
        "bs-face": (":(", 22, WHITE, None, False),
        "bs-l1": ("המדינה נתקלה בבעיה", 7, WHITE, None),
        "bs-l2": ("וצריכה לאתחל.", 7, WHITE, None),
        "bs-l3": ("אנחנו אוספים קצת מידע,", 5, WHITE, None),
        "bs-l4": ("ואז יוצאים לבחירות.", 5, WHITE, None),
        "bs-done": ("הושלם", 5, WHITE, None),
        "bs-p0": ("0%", 5, WHITE, None, False),
        "bs-p1": ("27%", 5, WHITE, None, False),
        "bs-p2": ("64%", 5, WHITE, None, False),
        "bs-p3": ("100%", 5, WHITE, None, False),
        "bs-code": ("קוד עצירה: עוד_סבב", 4, WHITE, None),
        "boot": ("מאתחל…", 5, GOLD_HI),
        "start": ("התחל", 4, INK, None),
        "clock": ("27.10", 4, INK, None),
    })
    sprite(R, "wordmark", 6)
    # Sound: the game in the window, then silence, an error, hold music, a fail, a hum, a boot.
    m = Mix(12.8)
    m.add(take_wav(b, 5.0, 5.55), 0.0, 0)
    m.add(take_wav(d, 5.0, 5.55), 0.55, 0)
    m.add(take_wav(g, 5.0, 5.55), 1.1, 0, fade_out=0.05)
    m.add(take_wav(g, 0.4, 1.0), 1.65, -2, fade_out=0.08)              # the picker, cut dead at 2.2
    m.add(tone([880, 1318], 0.5, 7), 3.3, -4)                          # the dialog's ding
    m.add(click(), 5.45, -4)
    hold = lowpass(game_wav("music_balfour_L0")[: int(3.0 * SR)], 900)  # on hold, on a phone line
    m.add(hold, 5.75, 0, fade_in=0.2, fade_out=0.3, length=2.8)
    m.add(game_wav("fail_D"), 8.75, 0)
    m.add(tone([55, 110], 1.8, 0.3, "square"), 9.6, -26, fade_in=0.05, fade_out=0.2)  # the blue screen's hum
    m.add(game_wav("stinger_motif_E"), 11.65, -2)
    m.write(out(R, "audio", "soundtrack.wav"))


# The six elections since 2019 (public dates; the Knesset each one elected).
CAL = [
    ("9", "באפריל 2019", "לכנסת ה־21", "בחירות."),
    ("17", "בספטמבר 2019", "לכנסת ה־22", "שוב."),
    ("2", "במרץ 2020", "לכנסת ה־23", "ושוב."),
    ("23", "במרץ 2021", "לכנסת ה־24", "עוד פעם."),
    ("1", "בנובמבר 2022", "לכנסת ה־25", "אחרונות."),
    ("27", "באוקטובר 2026", "לכנסת ה־26", None),
]


def calendar(takes):
    R = "calendar"
    items = {"head": ("לוח שנה", 5, WHITE), "sure": ("בטוח.", 10, RED, None),
             "tag": ("הבחירות שלא נגמרות", 6, GOLD_HI)}
    for i, (day, month, knesset, word) in enumerate(CAL, 1):
        items["day%d" % i] = (day, 26, INK, None, False)
        items["month%d" % i] = (month, 8, INK, None)
        items["kn%d" % i] = (knesset, 5, (96, 92, 110), None)
        if word:
            items["word%d" % i] = (word, 10, RED, None)
    labels(R, items)
    sprite(R, "wordmark", 4)
    end_card(R)
    # Paper rips, rubber stamps, the Knesset theme underneath, a fanfare for the last page.
    rng = np.random.default_rng(11)
    def rip():
        n = int(0.32 * SR)
        a = rng.uniform(-1, 1, n).astype(np.float32)
        a = lowpass(a, 2600) * np.exp(-np.linspace(0, 5, n)) * (0.6 + 0.4 * np.sin(np.linspace(0, 60, n)) ** 2)
        return a * 2.2
    m = Mix(10.8)
    m.add(game_wav("music_knesset_L0"), 0.0, 1, fade_out=0.6, length=10.8)
    stamps = [0.3, 2.0, 3.35, 4.5, 5.7, 6.45]
    for t in stamps:
        m.add(game_wav("stamp"), t, 3)
    for t in [1.7, 3.1, 4.3, 5.4, 7.8]:
        m.add(rip(), t, -1)
    m.add(game_wav("stinger_milestone_E"), 8.35, -6)
    m.write(out(R, "audio", "soundtrack.wav"))


# The tutorial: (clip id, take, first frame, last frame, crop y, title, subtitle). Crops are
# 1080x1271 of the 1080x2338 take, shown at 832x980.
STEPS = [
    ("pick", "bennett", 15, 80, 0, "בוחרים ראש רשימה.", "לכל אחד יש תרגיל."),
    ("tap", "bennett", 120, 197, 0, "לוחצים.", "כל לחיצה: עוד שקל."),
    ("buy", "bennett", 210, 287, 1000, "קונים מקורות הכנסה.", "הכסף מתחיל לעבוד לבד."),
    ("elect", "golan", 630, 707, 560, "הולכים לבחירות.", "ומקבלים מבזק."),
    ("again", "bennett", 15, 62, 0, "ומתחילים מחדש.", "זה כל המשחק."),
]


def howto(takes):
    R = "howto"
    items = {"eyebrow": ("איך משחקים בעוד סבב", 5, GOLD_HI)}
    m = Mix(sum((f1 - f0 + 1) / FPS for _, _, f0, f1, _, _, _ in STEPS))
    at = 0.0
    for i, (key, who, f0, f1, cy, title, sub) in enumerate(STEPS, 1):
        take = os.path.join(takes, "take_" + who)
        clip(R, key, take, f0, f1, (0, cy, 1080, 1271), (832, 980))
        items["n%d" % i] = (str(i), 8, INK, None, False)
        items["t%d" % i] = (title, 8, WHITE)
        items["s%d" % i] = (sub, 6, GOLD_HI)
        dur = (f1 - f0 + 1) / FPS
        m.add(take_wav(take, f0 / FPS, (f1 + 1) / FPS), at, 0, fade_in=0.02, fade_out=0.04)
        m.add(game_wav("coin_E_a"), at, -6)  # a tick on every new step
        at += dur
    labels(R, items)
    end_card(R)
    m.write(out(R, "audio", "soundtrack.wav"))
    print("howto main length: %.3f s" % at)


if __name__ == "__main__":
    takes, which = sys.argv[1], sys.argv[2]
    for name in (["crash", "calendar", "howto"] if which == "all" else [which]):
        globals()[name](takes)
        print("assets:", name)
