"""'עוד סבב' on LinkedIn: one looping GIF, 4:5, silent by nature.

Research, Oct 2026: LinkedIn takes 4:5 in the feed (20-30% more of a phone screen than 16:9) and
animates a GIF only under 5 MB and 400 frames; past either it freezes on the first frame. So frame 0
is a complete still (the claim, the cast, the wordmark), the loop is 18 s at 12 fps (216 frames),
backgrounds are flat (moving rays would eat the budget), and 256 colours suit the pixel art. Full size
lands at about 4.5 MB; a half-size copy (nearest-neighbour, so the Sevev font stays crisp) is about 1.5 MB.
No link yet (Bar, Oct 2026: the game isn't announced): it ends on "בקרוב" and the Instagram handle.
The audience is professional, so the story is the maker's, in Bar's plain first person (workshop copy
rules: no dashes, short sentences, nothing claimed that the game can't back), and it ends on a question
for the comments. The workshop itself is never the subject.

    python3 store/promo/src/linkedin.py <scratch dir> [--stills | --one <sec>]

Out: od-sevev-linkedin.gif (1080x1350), od-sevev-linkedin-small.gif (540x675), od-sevev-linkedin-cover.png (frame 0).
"""
import math
import os
import shutil
import subprocess
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import promo as P  # noqa: E402
import shorts as S  # noqa: E402
import teaser as k  # noqa: E402
from teaser import (INK, NIGHT, GOLD, GOLD_HI, GOLD_SH, WHITE, W, img, paste, scaled, text, plate,  # noqa: E402
                    badge, slam, pop_scale, coins_burst)

OUT = P.OUT
LH = 1350                       # the 4:5 frame; drawn on the kit's 1080x1920 canvas, band Y0..Y0+LH, then cropped
Y0 = 285
DUR = 18.0
GFPS = 12
SIZES = {"": (1080, 1350), "-small": (540, 675)}  # the full one first; the half one if LinkedIn balks
NAVY_BG = ((10, 14, 42), (22, 34, 92))
LEADERS = ["bibi", "bennett", "bengvir", "liberman", "smotrich", "eisenkot", "deri", "golan"]


def Y(y):
    """A y inside the 4:5 frame -> canvas y."""
    return Y0 + y


def caption(c, t, t0, line, sub=None, y=120, px=8):
    if t < t0:
        return
    im = text(line, px, grad=True)
    sc = pop_scale(t, t0, 0.14, 1.25)
    sh = text(sub, 6) if sub else None
    h = im.height + 34 + (sh.height + 14 if sh and t - t0 > 0.6 else 0)
    paste(c, scaled(plate(max(im.width, sh.width if sh else 0) + 70, h, NIGHT, INK, 6), sc), W // 2, Y(y) + (h - im.height - 34) // 2)
    paste(c, scaled(im, sc), W // 2, Y(y))
    if sh and t - t0 > 0.6:
        paste(c, sh, W // 2, Y(y) + im.height // 2 + 14 + sh.height // 2)


def phone_shot(c, who, tt, cx, cy, h=820):
    """A real frame of the game in a plain rounded phone, the stage and the HUD."""
    fr = P.take_frame(who, tt)
    w = round(h * 1080 / 1700)
    shot = fr.crop((0, 0, 1080, 1700)).resize((w, h), Image.BILINEAR)
    m = Image.new("L", (w, h), 0)
    ImageDraw.Draw(m).rounded_rectangle((0, 0, w - 1, h - 1), radius=40, fill=255)
    d = ImageDraw.Draw(c)
    d.rounded_rectangle((cx - w // 2 - 16, cy - h // 2 - 16, cx + w // 2 + 15, cy + h // 2 + 15), radius=56, fill=(20, 20, 26))
    d.rounded_rectangle((cx - w // 2 - 18, cy - h // 2 - 18, cx + w // 2 + 17, cy + h // 2 + 17), radius=58, outline=(140, 138, 130), width=4)
    c.paste(shot, (cx - w // 2, cy - h // 2), m)


# ---------------------------------------------------------------------------- scenes
# Each scene gets u, seconds since it began. Frame 0 is the post's still, so the hook is drawn settled.

def s_hook(c, u):
    """The claim, the wordmark, the eight; a gold ring walks the cast. Frame 0 tells the whole story."""
    P.grad_bg(c, *NAVY_BG)
    caption(c, u, -1, "בניתי משחק על הבחירות.", "26 ימים לפני שהן קורות.")
    paste(c, img("wordmark", 5), W // 2, Y(440))
    on = int(u / 0.3) % 8 if u > 0.3 else -1
    d = ImageDraw.Draw(c)
    for i, who in enumerate(LEADERS):
        x, y = 180 + (i % 4) * 240, Y(690 + (i // 4) * 215)
        if i == on:
            d.ellipse((x - 112, y - 112, x + 112, y + 112), fill=GOLD_HI)
        paste(c, S.avatar_round(who, 190), x, y - (12 if i == on else 0))
    a, b = text("8 ראשי רשימה.", 7, fill=WHITE), text("אף אחד לא מגיע ל־61.", 7, grad=True)
    paste(c, plate(max(a.width, b.width) + 70, a.height + b.height + 50, INK, GOLD_SH, 5), W // 2, Y(1185))
    paste(c, a, W // 2, Y(1185) - b.height // 2 - 6)
    paste(c, b, W // 2, Y(1185) + a.height // 2 + 6)


def s_play(c, u):
    """What you do in it, on real frames: four beats of a second."""
    P.grad_bg(c, *NAVY_BG)
    order = [("bibi", 4.6), ("bennett", 10.8), ("deri", 14.2), ("liberman", 33.5)]
    j = min(3, int(u / 1.0))
    who, tt = order[j]
    phone_shot(c, who, tt + (u - j * 1.0), W // 2, Y(790), h=1000)
    steps = ["בוחרים ראש רשימה.", "לוחצים.", "אוספים כסף.", "קונים קואליציה."]
    caption(c, u, j * 1.0, steps[j], y=120)


def s_cast(c, u):
    """Each leader plays differently."""
    P.grad_bg(c, *NAVY_BG)
    caption(c, u, 0, "לכל ראש רשימה מכניקה משלו.", y=120)
    cards = [("bibi", "שולף מהכובע"), ("bennett", "חותם על הכל"), ("liberman", "לא אשב"), ("eisenkot", "בלי הפתעות")]
    d = ImageDraw.Draw(c)
    for i, (who, tag) in enumerate(cards):
        t0 = 0.25 + i * 0.35
        if u < t0:
            continue
        col, row = i % 2, i // 2
        cx, cy = 290 + col * 500, Y(520 + row * 470)
        sc = pop_scale(u, t0, 0.16, 0.3)
        shot = P.stage_shot(who, 5.0 + (u - t0), (420, 300), (575 - 380, 760 - 330, 575 + 380, 760 + 210))
        d.rectangle((cx - 222, cy - 172, cx + 221, cy + 171), fill=GOLD_SH)
        c.alpha_composite(scaled(shot, sc), (int(cx - 210 * sc), int(cy - 160 * sc)))
        if u - t0 > 0.2:
            lab = text(tag, 6)
            paste(c, plate(lab.width + 40, lab.height + 20, INK, GOLD_SH, 4), cx, cy + 205)
            paste(c, lab, cx, cy + 205)


def s_sources(c, u):
    """The facts are sourced. The jokes are not."""
    P.grad_bg(c, (12, 12, 30), (30, 24, 60))
    paste(c, text("כל עובדה במשחק", 10, grad=True), W // 2, Y(400))
    paste(c, text("באה עם מקור.", 10, grad=True), W // 2, Y(520))
    if u > 0.5:
        slam(c, k.stamp_img("מקור", 12), u, 0.5, W // 2 + 230, Y(720), angle=-10, frm=2.4)
    if u > 1.3:
        slam(c, text("הבדיחות לא.", 11, fill=WHITE), u, 1.3, W // 2, Y(960), frm=2.0)


def s_goal(c, u):
    """The goal is 61; nobody gets there; elections again."""
    P.grad_bg(c, *NAVY_BG)
    caption(c, u, 0, "המטרה: 61 מנדטים.", y=120)
    filled = min(60, int(u * 60))
    P.hemicycle(c, W // 2, Y(640), 12, filled=filled, t=u, pulse61=True)
    paste(c, text("%d/61" % filled, 9, fill=GOLD_HI, rtl=False), W // 2, Y(930))
    if u > 1.1:
        slam(c, text("אף אחד עוד לא הגיע.", 9, fill=WHITE), u, 1.1, W // 2, Y(1080), frm=2.0)
    if u > 1.7:
        slam(c, badge("עוד סבב", 12), u, 1.7, W // 2, Y(1230), angle=-4, frm=2.2)


def s_cta(c, u):
    """What it is, that it's coming, and where to follow. No link yet: the game isn't announced."""
    P.grad_bg(c, *NAVY_BG)
    coins_burst(c, u, 0, W // 2, Y(330), n=24, seed=31, life=1.4, kinds=("coin", "coin", "bill"))
    paste(c, scaled(img("wordmark", 5), pop_scale(u, 0, 0.18, 0.2) or 0.01), W // 2, Y(300))
    if u > 0.3:
        paste(c, text("משחק סאטירה חינמי בדפדפן.", 7), W // 2, Y(500))
    if u > 0.6:
        slam(c, badge("בקרוב", 12), u, 0.6, W // 2, Y(680), angle=-4, frm=2.2)
    if u > 1.2:
        q = text("עקבו באינסטגרם", 8, grad=True)
        paste(c, plate(q.width + 70, q.height + 30, NIGHT, INK, 6), W // 2, Y(890))
        paste(c, q, W // 2, Y(890))
        h = text("@od.sevev", 9, fill=INK, ring=None, shadow=False, rtl=False)
        paste(c, plate(h.width + 60, h.height + 34, GOLD, INK, 6), W // 2, Y(1010))
        paste(c, h, W // 2, Y(1010))
    if u > 1.6:
        paste(c, text("סאטירה. לא מטעם אף מפלגה.", 5, fill=(180, 186, 210)), W // 2, Y(1190))


SCENES = [(0.0, s_hook), (2.8, s_play), (6.8, s_cast), (9.4, s_sources), (11.8, s_goal), (14.2, s_cta)]


def frame(t):
    c = Image.new("RGBA", (W, 1920), INK + (255,))
    t0, scene = [x for x in SCENES if t >= x[0]][-1]
    scene(c, t - t0)
    return c.crop((0, Y0, W, Y0 + LH)).convert("RGB")


def main():
    P.SCRATCH = sys.argv[1]
    if "--stills" in sys.argv:
        ts = [0.0, 1.5, 3.0, 4.2, 5.2, 6.3, 7.4, 8.9, 10.0, 11.2, 12.4, 13.0, 13.9, 14.6, 15.6, 17.9]
        ims = [frame(x).resize((270, 338)) for x in ts]
        sheet = Image.new("RGB", (8 * 275, 2 * 345), (30, 30, 30))
        for i, im in enumerate(ims):
            sheet.paste(im, ((i % 8) * 275, (i // 8) * 345))
        sheet.save(os.path.join(OUT, "_stills_linkedin.png"))
        return
    if "--one" in sys.argv:
        frame(float(sys.argv[sys.argv.index("--one") + 1])).save(os.path.join(OUT, "_one.png"))
        return
    name = "od-sevev-linkedin"
    frames = os.path.join(P.SCRATCH, "_li_frames")
    n = int(DUR * GFPS)
    for suf, (gw, gh) in SIZES.items():
        os.makedirs(frames + suf, exist_ok=True)
    for i in range(n):
        im = frame(i / GFPS)
        if i == 0:
            im.save(os.path.join(OUT, name + "-cover.png"))
        for suf, (gw, gh) in SIZES.items():
            im.resize((gw, gh), Image.NEAREST).save(os.path.join(frames + suf, "%04d.png" % i))
    graph = ("[0:v]split[a][b];[a]palettegen=max_colors=256:stats_mode=full[p];"
             "[b][p]paletteuse=dither=none:diff_mode=rectangle")
    for suf in SIZES:
        gif = os.path.join(OUT, name + suf + ".gif")
        subprocess.run([k.ffmpeg(), "-y", "-loglevel", "error", "-framerate", str(GFPS),
                        "-i", os.path.join(frames + suf, "%04d.png"), "-filter_complex", graph, "-loop", "0", gif],
                       check=True)
        shutil.rmtree(frames + suf)
        mb = os.path.getsize(gif) / 2 ** 20
        print("%s  %d frames  %.2f MB" % (gif, n, mb))
        if mb >= 5 or n >= 400:
            raise SystemExit("over LinkedIn's GIF limits (5 MB, 400 frames): it would not animate")

if __name__ == "__main__":
    main()
