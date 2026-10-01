"""'עוד סבב' gameplay teaser, one minute on the iPhone: a mixed montage of the leaders.

Bar's brief: one minute, the iPhone look, no single candidate in focus, no segment per leader.
So the cut follows the game, not a person: pick, tap, buy, build a coalition, pay, almost 61,
elections again; each beat is played by whoever the cut lands on, the sides alternating
(coalition: Bibi, Ben Gvir, Smotrich, Deri; opposition: Bennett, Liberman, Eisenkot, Golan).

The footage: six short captures made for this cut (store/gameplay/plans/plan-<leader>.json, one
fresh save each) plus the Ben Gvir and Liberman takes of the earlier reels. Music: Bar's second track,
glitch-warfare.wav, from its bar 10 (a bar is 1.808 s): the drop lands on video bar 8, the break's
last beat on bar 20 ("לא יושב"), 33 bars = 59.7 s.

    python3 store/gameplay/src/reel_mix.py <scratch dir with take_<leader>/, take1/, takeL/>
    python3 store/gameplay/src/reel_mix.py <scratch dir> --stills
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import gameplay_iphone as gi  # noqa: E402
import reel_liberman as rl  # noqa: E402
import teaser as k  # noqa: E402
from teaser import INK, GOLD_HI, W, text, plate, badge, slam, pop_scale, clamp, ease_out, paste  # noqa: E402

OUT = gi.OUT
A0 = 19.634                        # the track's bar 10
BARLEN = 1.808
BEAT = BARLEN / 4


def VB(j):
    return BARLEN * j


DUR = VB(33)                       # 59.66 s
T_END = VB(28)

HOOK = [("bibi", 6.0), ("bennett", 6.0), ("bengvir", 5.5), ("liberman", 5.5),
        ("smotrich", 6.0), ("eisenkot", 6.0), ("deri", 6.0), ("golan", 6.0)]


def clips():
    c = [(VB(0) + i * BEAT, VB(0) + (i + 1) * BEAT, t, 1.0, key) for i, (key, t) in enumerate(HOOK)]
    c += [
        (VB(2), VB(4), 0.2, 1.0, "bennett"),          # the picker
        (VB(4), VB(5), 4.5, 1.0, "eisenkot"),         # every tap is a shekel
        (VB(5), VB(6), 4.5, 1.0, "bennett"),
        (VB(6), VB(6) + 2 * BEAT, 7.4, 1.0, "bibi"),  # each has a trick: hat, coffee, calculator, stapler
        (VB(6) + 2 * BEAT, VB(7), 7.4, 1.0, "deri"),
        (VB(7), VB(7) + 2 * BEAT, 7.4, 1.0, "smotrich"),
        (VB(7) + 2 * BEAT, VB(8), 7.4, 1.0, "golan"),
        (VB(8), VB(9), 7.0, 1.0, "bennett"),          # the drop: buying
        (VB(9), VB(10), 10.6, 1.0, "eisenkot"),
        (VB(10), VB(11), 14.0, 1.0, "deri"),          # the money
        (VB(11), VB(12), 14.0, 1.0, "golan"),
        (VB(12), VB(14), 32.3, 1.0, "bengvir"),       # the coalition chat
        (VB(14), VB(16), 32.5, 1.0, "liberman"),      # paying, and paying
        (VB(16), VB(17), 16.5, 1.0, "bibi"),          # the till bursts
        (VB(17), VB(18), 16.5, 1.0, "smotrich"),
        (VB(18), VB(19), 16.5, 1.0, "deri"),
        (VB(19), VB(22), 36.79, 1.0, "liberman"),     # the demand; "לא יושב" on bar 20
        (VB(22), VB(24), 14.0, 1.0, "smotrich"),      # half a million
        (VB(24), VB(25), 55.0, 1.0, "bengvir"),       # 47 of 61
        (VB(25), VB(26), 55.7, 1.0, "liberman"),      # 49 of 61
        (VB(26), VB(27), ELECT_FADE, 0.6, "golan"),   # the Knesset dissolves
        (VB(27), VB(28), ELECT_CARD, 0.3, "golan"),
    ]
    return c


ELECT_FADE = 20.0                  # the Golan take (elect at 20.0): the fade
ELECT_CARD = 21.25                 # and the "הכנסת פוזרה" card (frames ~634-657), held

CAPTIONS = [  # about the game, never one candidate; a mechanism per line, the punch last
    (0.15, VB(2), "8 ראשי רשימה.", "אף אחד לא מגיע ל־61."),
    (VB(2), VB(4), "בוחרים ראש רשימה.", "כולם בטוחים שזה הם."),
    (VB(4), VB(6), "כל לחיצה: שקל.", "בלי ועדת כספים."),
    (VB(6), VB(8), "לכל אחד תרגיל:", "כובע, סרגל, מחשבון, שדכן."),
    (VB(8), VB(10), "קונים מקורות.", "משלם המסים תמיד ראשון."),
    (VB(10), VB(12), "הכסף זורם.", "לאן? לקואליציה."),
    (VB(12), VB(14), "מרכיבים קואליציה.", "כולם רוצים תקציב."),
    (VB(14), VB(16), "משלמים.", "ומשלמים. ומשלמים."),
    (VB(16), VB(19), "הקופה מתפוצצת.", "הקואליציה עוד לא."),
    (VB(19), VB(20), "ויש מי שלא משלם.", ""),
    (VB(20), VB(22), "לא אשב.", "הדרישה נסגרה. בחינם."),
    (VB(22), VB(24), "חצי מיליון בקופה.", "יש כסף. לא לך."),
    (VB(24), VB(26), "כמעט 61.", "כמו תמיד."),
    (VB(26), VB(28), "אין 61?", "בחירות. שוב."),
]


def cam_keys():
    b = VB
    return [
        (0.0, 1.45, 575, 820), (b(2), 1.45, 575, 820),                                  # the hook: tight
        (b(2), 1.0, None, None), (b(2) + 0.4, 1.0, None, None), (b(2) + 1.2, 1.2, 540, 1300),
        (b(4) - 0.3, 1.2, 540, 1300), (b(4), 1.3, 575, 800),                             # the taps: on them
        (b(8), 1.3, 575, 800), (b(8), 1.26, 540, 1600), (b(12), 1.26, 540, 1600),        # buying: the shop
        (b(12), 1.0, None, None), (b(12) + 0.8, 1.25, 540, 1250), (b(16), 1.25, 540, 1250),  # the chat
        (b(16), 1.3, 575, 800), (b(19), 1.3, 575, 800),                                  # the till
        (b(19), 1.25, 540, 1300), (b(20) - 0.35, 1.45, 540, 1500), (b(20) + 1.2, 1.45, 540, 1500),
        (b(21) + 0.5, 1.0, None, None), (b(22), 1.0, None, None),
        (b(22), 1.0, None, None), (b(22) + 0.8, 1.26, 540, 1600), (b(24), 1.26, 540, 1600),
        (b(24), 1.45, 540, 200), (b(26), 1.5, 540, 200),                                  # the meter
        (b(26), 1.0, None, None), (b(27), 1.0, None, None), (b(27), 1.5, 540, CARD_Y), (b(28), 1.55, 540, CARD_Y),
    ]


CARD_Y = 1360                      # the dissolve card's centre in the take (capture px)

LINEUP = ["bibi", "bennett", "ben-gvir", "liberman", "smotrich", "eisenkot", "deri", "golan"]


def end_card(c, t):
    """The curtain, the wordmark, and all eight: one steps up on each beat. The cover is its last frame."""
    tt = t - T_END
    k.curtain(c, 0, dim=0.15)
    k.spotlight(c, W // 2, 0, 1400, 90, 480, 0.2, GOLD_HI)
    k.vignette(c)
    s = pop_scale(tt, 0, 0.18, 0.2)
    if s:
        paste(c, k.scaled(k.img("wordmark", 6), s), W // 2, 250)
    if tt >= 0.3:
        paste(c, text("הבחירות שלא נגמרות", 9), W // 2, 440)
    n = len(LINEUP)
    for i, who in enumerate(LINEUP):
        t0 = 0.4 + i * BEAT
        if tt < t0:
            continue
        rise = ease_out(clamp((tt - t0) / 0.22))
        ch = k.SPRITES["chars"][who]
        a = ch["anims"]["idle"]
        fr, anc = k.char_frame(who, "idle", int((tt - t0) * a["fps"]) % a["frames"], 1)
        x = 115 + i * (850 / (n - 1))
        y = 1000 + int((1 - rise) * 260)
        paste(c, fr, x - anc[0], y - anc[1], "tl")
    if tt >= 0.4 + n * BEAT:
        slam(c, badge("בקרוב"), tt, 0.4 + n * BEAT, W // 2, 1170, angle=-4, frm=2.4)
    if tt >= 1.0 + n * BEAT:
        cta = text("עקבו: @od.sevev", 8)
        paste(c, plate(cta.width + 50, cta.height + 26, INK, INK, 6), W // 2, 1405)
        paste(c, cta, W // 2, 1405)
        paste(c, text("סאטירה. לא מטעם אף מפלגה.", 5, fill=(190, 196, 220)), W // 2, 1505)
    k.flash(c, tt, 0, 0.16, 1.0)


def main():
    scratch = sys.argv[1]
    for key in ("bibi", "bennett", "smotrich", "eisenkot", "deri", "golan"):
        gi.TAKES[key] = os.path.join(scratch, "take_" + key)
        gi.PLANS[key] = os.path.join(OUT, "plans", "plan-%s.json" % key)
    gi.TAKES["bengvir"] = os.path.join(scratch, "take1")
    gi.PLANS["bengvir"] = os.path.join(OUT, "plan-bengvir.json")
    gi.TAKES["liberman"] = os.path.join(scratch, "takeL")
    gi.PLANS["liberman"] = os.path.join(OUT, "plan-liberman.json")
    gi.TAP_AT_BY["liberman"] = rl.TAP_AT
    gi.TAP_AT_BY["bennett"] = {1.4: PICK_BENNETT}
    sys.argv[1] = gi.TAKES["bibi"]
    gi.PLAN = gi.PLANS["bibi"]
    gi.NAME = "od-sevev-teaser-mix"
    gi.MUSIC = os.path.join(OUT, "music", "glitch-warfare.wav")
    gi.MUSIC_AT = A0
    gi.DUR = DUR
    gi.T_END = T_END
    gi.CLIPS = clips()
    gi.CAPTIONS = CAPTIONS
    gi.PEEKS = []
    gi.cam_keys = cam_keys
    gi.END = end_card
    gi.SUB_DELAY = 0.75
    gi.STILLS = [0.2, 0.7, 1.6, 2.5, 3.2, 4.5, 7.5, 9.0, 11.5, 12.2, 13.5, 15.5, 17.5, 19.5, 21.5, 23.5,
                 26.0, 28.5, 31.0, 34.0, 36.4, 37.5, 41.0, 44.5, 46.0, 48.0, 49.5, 51.5, 55.0, 59.6]
    gi.main()


PICK_BENNETT = (180, 1800)          # his cell on this take's (shuffled) picker, capture px


if __name__ == "__main__":
    main()
