"""'עוד סבב' gameplay reel 2: Liberman's round, on the iPhone (the v4 renderer, gameplay_iphone.py).

Bar's brief: less Mordechai David and Ben Gvir; this one is Liberman, cut to Bar's second track
(store/gameplay/music/glitch-warfare.wav, ~132.7 BPM: a bar is 1.808 s, bar lines at 1.554 + 1.808 k).
The reel takes the track from bar 10 (19.63 s: the groove), so the drop (bar 18, 34.1 s) lands at
video bar 8 and the break (~51.5-56 s) under the demand, right before "לא יושב".

The voice (research, Sep 2026; nothing quoted): the satire shows play him cold and dry, and the scarier
the funnier; his 2026 campaign sells "strong on security, strong on the economy" and "the next prime
minister"; the opposition bloc polls at 60-61. The game's own kit does the rest: every tap is a refusal,
the prop is a chair, the sources are the disposable-dishes and sweet-drinks taxes, and his rule is the
"לא יושב" pill that closes a partner's demand for free. Facts only where the game sources them (2019).

    python3 store/gameplay/src/reel_liberman.py <take dir>            # -> store/gameplay/od-sevev-liberman.mp4
    python3 store/gameplay/src/reel_liberman.py <take dir> --stills
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import gameplay_iphone as gi  # noqa: E402
import teaser as k  # noqa: E402
from teaser import INK, GOLD_HI, W, H, paste, text, plate, badge, slam, pop_scale, clamp, ease_out  # noqa: E402

OUT = gi.OUT
A0 = 19.634                        # the track's bar 10 (1.554 + 1.808 * 10)
BARLEN = 1.808


def VB(j):
    """Video bar line j (the track's bar 10 + j)."""
    return BARLEN * j


DUR = VB(32)                       # 57.86 s: bars 10-42 of the track (a full 8-bar phrase ends at 77.5 s)
T_END = VB(28)

# (video start, video end, take start, speed)
CLIPS = [
    (0.0, VB(2), 44.5, 1.0),              # hook: the refusals at full tilt, the whole screen
    (VB(2), VB(4), 0.3, 1.0),             # the picker
    (VB(4), VB(8), 3.0, 1.0),             # the first refusals
    (VB(8), VB(10), 9.0, 1.2),            # the drop: buying
    (VB(10), VB(12), 15.0, 1.0),          # more sources
    (VB(12), VB(14), 18.6, 1.0),          # refusing: a "לא מוחלט" crit
    (VB(14), VB(16), 22.0, 0.7),          # 400K and the big buys (cut before the in-game Mordechai David event, ~24.5)
    (VB(16), VB(19), 29.8, 1.0),          # the coalition: partners join, he pays
    (VB(19), VB(24), 36.79, 1.0),         # the demand, "לא יושב" on the break's last beat, the next one
    (VB(24), VB(26), 48.0, 1.0),          # 5M, buying
    (VB(26), VB(27), 55.7, 1.0),          # the seats
    (VB(27), VB(28), 58.52, 0.22),        # "the Knesset dissolved": the ceremony card is up 0.4 s, held
]

CAPTIONS = [
    (0.15, VB(2), "איך משחקים בתור ליברמן?", ""),
    (VB(2), VB(4), "בוחרים ראש רשימה", "הוא כבר הודיע: ראש הממשלה הבא."),
    (VB(4), VB(6), "כל לחיצה = סירוב", "הכיסא מקבל שקל."),
    (VB(6), VB(8), "ליברמן לא מתיישב", "גם לא על הכיסא שלו."),
    (VB(8), VB(10), "קונים מקורות", "משלם המסים. תמיד הוא."),
    (VB(10), VB(12), "עוד מקורות", "ההייטק משלם. ליברמן עומד."),
    (VB(12), VB(14), "חזק בביטחון", "חלש בישיבה."),
    (VB(14), VB(16), "חזק בכלכלה", "400 אלף. ועדיין לא התיישב."),
    (VB(16), VB(18), "והקואליציה?", "ציונית. רחבה. על הנייר."),
    (VB(18), VB(20), "לפיד ביקש תקציב", "ליברמן שוקל..."),
    (VB(20), VB(22), "לא יושב.", "הדרישה נסגרה. בחינם."),
    (VB(22), VB(24), "עוד דרישה?", "הפעם שילם. הסירוב בטעינה."),
    (VB(24), VB(26), "המספרים עולים", "הכיסא עדיין ריק."),
    (VB(26), VB(27), "49 מתוך 61", ""),
    (VB(27), VB(28), "אז בחירות.", "שוב. כמו ב־2019."),
]


def cam_keys():
    b = VB
    return [
        (0.0, 1.6, 540, 820), (1.1, 1.6, 540, 820), (2.1, 1.0, None, None),             # hook: tight, reveal
        (b(2), 1.0, None, None), (b(2) + 0.5, 1.0, None, None), (b(2) + 1.3, 1.2, 540, 1500),
        (b(4) - 0.3, 1.2, 540, 1500), (b(4), 1.0, None, None),
        (b(4), 1.0, None, None), (b(8), 1.18, None, None),                                # a slow creep to the drop
        (b(8), 1.0, None, None), (b(8) + 0.8, 1.28, 540, 1560), (b(10), 1.28, 540, 1600),  # onto the shop
        (b(10), 1.0, None, None), (b(12), 1.0, None, None),
        (b(12), 1.0, None, None), (b(12) + 0.8, 1.3, 540, 760), (b(14), 1.3, 540, 760),    # on him, refusing
        (b(14), 1.0, None, None), (b(14) + 0.9, 1.26, 540, 1600), (b(16), 1.26, 540, 1600),
        (b(16), 1.0, None, None), (b(17), 1.0, None, None), (b(17) + 0.9, 1.25, 540, 1250), (b(19), 1.25, 540, 1250),
        (b(19), 1.25, 540, 1300), (b(20) - 0.35, 1.45, 540, 1500), (b(20) + 1.2, 1.45, 540, 1500),  # the pill
        (b(21) + 0.5, 1.0, None, None), (b(24), 1.0, None, None),
        (b(24), 1.0, None, None), (b(24) + 0.8, 1.26, 540, 1600), (b(26), 1.26, 540, 1600),
        (b(26), 1.0, None, None), (b(26) + 0.6, 1.5, 540, 200), (b(27), 1.5, 540, 200),     # the meter
        (b(27), 1.0, None, None), (b(27) + 0.5, 1.5, 540, 1385), (b(28), 1.55, 540, 1385),
    ]


LIB = "liberman"


def lib_frame(anim, t_local, scale):
    a = k.SPRITES["chars"][LIB]["anims"][anim]
    n = a["frames"]
    i = int(t_local * a["fps"])
    i = i % n if a.get("loop", anim == "idle") else min(i, n - 1)
    return k.char_frame(LIB, anim, i, scale)


def end_card(c, t):
    """The curtain, the wordmark, and him: standing next to an empty chair. The cover is its last frame."""
    tt = t - T_END
    k.curtain(c, 0, dim=0.15)
    k.spotlight(c, W // 2, 0, 1400, 90, 480, 0.2, GOLD_HI)
    k.vignette(c)
    wm = k.img("wordmark", 6)
    s = pop_scale(tt, 0, 0.18, 0.2)
    if s:
        paste(c, k.scaled(wm, s), W // 2, 330)
    if tt >= 0.3:
        paste(c, text("הבחירות שלא נגמרות", 9), W // 2, 540)
    # Liberman, arms crossed, and the chair he will not sit on
    rise = ease_out(clamp((tt - 0.2) / 0.35))
    fr, anc = lib_frame("react" if 1.0 <= tt < 2.2 else "idle", tt, 2)
    x, y = 330, 1610 + int((1 - rise) * 500)
    chair = k.img("prop_chair", 10)
    chair = chair.crop((0, 0, chair.width // 2, chair.height))   # the sheet holds two frames
    paste(c, chair, 790, y, "b")
    paste(c, fr, x - anc[0] * 2, y - anc[1] * 2, "tl")
    if tt >= 1.0:
        b = k.bubble("לא יושב.", 6)
        paste(c, b, x + 290, y - 560)
    if tt >= 1.6:
        slam(c, badge("בקרוב"), tt, 1.6, W // 2, 740, angle=-4, frm=2.4)
    if tt >= 2.2:
        cta = text("עקבו: @od.sevev", 8)
        paste(c, plate(cta.width + 50, cta.height + 26, INK, INK, 6), W // 2, 1735)
        paste(c, cta, W // 2, 1735)
        paste(c, text("סאטירה. לא מטעם אף מפלגה.", 5, fill=(190, 196, 220)), W // 2, 1830)
    k.flash(c, tt, 0, 0.16, 1.0)


# The chat taps, read off the take's log and frames (x, y in capture px): the log prints a pay only
# when it found a pill, so each is pinned to its plan step here; None = that step tapped nothing.
TAP_AT = {33: (552, 855), 34: (552, 1167), 35: (552, 1275), 36: None, 38.6: (552, 1953), 42.2: (552, 1839),
          53: None, 54: (552, 1953)}


def main():
    gi.TAP_AT = TAP_AT
    gi.NAME = "od-sevev-liberman"
    gi.PLAN = os.path.join(OUT, "plan-liberman.json")
    gi.MUSIC = os.path.join(OUT, "music", "glitch-warfare.wav")
    gi.MUSIC_AT = A0
    gi.DUR = DUR
    gi.T_END = T_END
    gi.CLIPS = CLIPS
    gi.CAPTIONS = CAPTIONS
    gi.PEEKS = []                   # no Mordechai David this time (Bar)
    gi.cam_keys = cam_keys
    gi.END = end_card
    gi.STILLS = [0.3, 1.5, 2.6, 5.0, 8.0, 12.0, 15.5, 17.5, 20.0, 23.5, 26.0, 28.0, 30.5, 33.0, 35.5,
                 36.4, 37.2, 39.0, 41.0, 44.0, 46.5, 48.0, 49.5, 51.0, 53.0, 57.8]
    gi.main()


if __name__ == "__main__":
    main()
