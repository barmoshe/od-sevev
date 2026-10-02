"""'עוד סבב': the social kit beyond Reels (Oct 2026). Everything is "בקרוב": no link, no version.

Research (sources in store/promo/README.md): carousels are saved about 35% more than single images, the
first slide decides, 7-10 slides; Stories with native stickers (quiz, poll, question, countdown) get
about twice the interactions, 3-7 frames; WhatsApp stickers are 512x512 WebP under 100 KB, transparent,
3-30 a pack, a 96x96 tray icon. Copy is the game's own (abilities, decoy lines, ticker) or held to
creative-pack/voice/review-rubric.md: a named mechanism, the punch last, both camps alike, no polls.

    stickers    18 WhatsApp stickers + tray (social/stickers/)
    abilities   carousel, 10 slides: "בחרו ראש רשימה. לכל אחד יש תרגיל." (social/carousel-abilities/)
    dictionary  carousel, 10 slides: "מילון עוד סבב" (social/carousel-dictionary/)
    stories     5 Story frames with room for Instagram's own stickers (social/stories/)
    memes       4 single-image memes (social/memes/)
    highlights  5 highlight covers (social/highlights/)

    python3 store/promo/src/social.py [all|stickers|abilities|dictionary|stories|memes|highlights]
"""
import os
import sys

from PIL import Image, ImageDraw, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import promo as P  # noqa: E402
import teaser as k  # noqa: E402
from teaser import INK, NIGHT, GOLD, GOLD_HI, GOLD_SH, WHITE, RED, img, text, plate, badge, char_frame  # noqa: E402

OUT = os.path.join(HERE, "..", "social")
NAVY = ((14, 22, 64), (6, 10, 30))
_c = {}


# ---------------------------------------------------------------------------- shared

def comp(c, im, x, y, anchor="c"):
    """alpha-composite im onto c at (x, y), clipped to c (any canvas size)."""
    if anchor == "c":
        x, y = x - im.width // 2, y - im.height // 2
    elif anchor == "b":
        x, y = x - im.width // 2, y - im.height
    x, y = int(round(x)), int(round(y))
    sx, sy = max(0, -x), max(0, -y)
    x, y = max(0, x), max(0, y)
    w, h = min(im.width - sx, c.width - x), min(im.height - sy, c.height - y)
    if w > 0 and h > 0:
        c.alpha_composite(im.crop((sx, sy, sx + w, sy + h)), (x, y))


def grad(size, top, bot):
    g = Image.new("RGBA", (1, 64))
    for y in range(64):
        u = y / 63
        g.putpixel((0, y), tuple(int(top[j] + (bot[j] - top[j]) * u) for j in range(3)) + (255,))
    return g.resize(size, Image.BILINEAR)


def figure(who, scale=1, anim=None, frame=0):
    ch = k.SPRITES["chars"][who]
    anim = anim or list(ch["anims"])[0]
    fr, anc = char_frame(who, anim, frame, scale)
    bb = fr.getchannel("A").getbbox()
    return fr.crop(bb)


def circle_av(name, size):
    a = img(name).resize((size * 4, size * 4), Image.NEAREST)
    m = Image.new("L", a.size, 0)
    ImageDraw.Draw(m).ellipse((0, 0, a.width - 1, a.height - 1), fill=255)
    out = Image.new("RGBA", a.size, (0, 0, 0, 0))
    out.paste(a, (0, 0), m)
    return out.resize((size, size), Image.LANCZOS)


def save(im, *parts):
    path = os.path.join(OUT, *parts)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    if path.endswith(".webp"):
        im.save(path, "WEBP", quality=80, method=6)
    else:
        im.save(path)
    return path


def lines_center(c, lines, y, px, fill=INK, gap=16, ring=None, cx=None):
    cx = c.width // 2 if cx is None else cx
    for s in lines:
        t = text(s, px, fill=fill, ring=ring, shadow=ring is not None)
        comp(c, t, cx, y + t.height // 2)
        y += t.height + gap
    return y


# ============================================================================ 1. WhatsApp stickers

STICKERS = [  # (file, figure, anim, frame, line): everyday replies in the leaders' own words
    ("lo-eshev", "liberman-document", None, 0, "לא אשב."),
    ("ani-poresh", "ben-gvir-walkout", None, 0, "אני פורש."),
    ("chazarti", "ben-gvir-back", None, 0, "חזרתי!"),
    ("beiparon", "bennett-sign", None, 0, "חתמתי. בעיפרון."),
    ("misderon", "deri-bench", None, 0, "נסגור במסדרון."),
    ("daka-90", "smotrich-budget", None, 0, "בדקה ה־90."),
    ("smola", "golan-swipe", None, 0, "שמאלה."),
    ("shulchan-agol", "eisenkot-summit", None, 0, "שולחן עגול?"),
    ("titachadu", "bibi-matchmaker", None, 0, "תתאחדו!"),
    ("ein-kova", "bibi", "idle", 0, "אין שום כובע."),
    ("nikra", "gantz", "idle", 0, "סטטוס: נקרא."),
    ("od-mechlit", "gantz", "react", 5, "אני עוד מחליט."),
    ("od-sevev", "dubi-mic", "talk", 1, "עוד סבב!"),
    ("bchirot", "dubi-mic", "talk", 0, "בחירות! בחירות!"),
    ("mivzak", "dubi-mic", "idle", 0, "מבזק!"),
    ("ein-61", None, None, 0, "אין 61."),
    ("nidcha", None, None, 0, "נדחה."),
    ("bekarov", None, None, 0, "בקרוב."),
]


def sticker(fig, anim, frame, line):
    c = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
    cap = text(line, 7 if len(line) < 11 else 6, fill=WHITE, ring=INK)
    if fig:
        f = figure(fig, 2, anim, frame)
        s = min(345 / f.height, 440 / f.width)
        f = f.resize((int(f.width * s), int(f.height * s)), Image.LANCZOS)
        comp(c, f, 256, 492, "b")
        bx = plate(cap.width + 40, cap.height + 24, INK, GOLD_SH, 5)
        comp(c, bx, 256, 30 + bx.height // 2)
        comp(c, cap, 256, 30 + bx.height // 2)
    else:
        if line == "אין 61.":
            P.hemicycle(c, 256, 290, 5, filled=60, pulse61=False)
            comp(c, text(line, 8, fill=WHITE, ring=INK), 256, 430)
        elif line == "נדחה.":
            st = k.stamp_img("נדחה.", 12).rotate(-12, resample=Image.NEAREST, expand=True)
            comp(c, st, 256, 256)
        else:
            comp(c, badge("בקרוב", 12), 256, 256)
    # the sticker's white die-cut border
    a = c.getchannel("A").point(lambda v: 255 if v > 40 else 0)
    edge = a.filter(ImageFilter.MaxFilter(17))
    out = Image.new("RGBA", c.size, (0, 0, 0, 0))
    out.paste(Image.new("RGBA", c.size, (255, 255, 255, 255)), (0, 0), edge)
    out.alpha_composite(c)
    return out


def make_stickers():
    paths = []
    for name, fig, anim, frame, line in STICKERS:
        im = sticker(fig, anim, frame, line)
        p = save(im, "stickers", "%02d-%s.webp" % (len(paths) + 1, name))
        if os.path.getsize(p) > 100_000:
            raise SystemExit("sticker over 100 KB: " + p)
        paths.append(p)
    tray = circle_av("avatar_dubi", 96)
    save(tray, "stickers", "tray.png")
    sheet = Image.new("RGBA", (6 * 260, 3 * 260), (40, 160, 120, 255))     # a preview on WhatsApp green
    for i, p in enumerate(paths):
        comp(sheet, Image.open(p).convert("RGBA").resize((240, 240), Image.LANCZOS), 130 + (i % 6) * 260, 130 + (i // 6) * 260)
    save(sheet.convert("RGB"), "stickers", "_preview.png")
    return paths


# ============================================================================ 2. carousel: the abilities

CW, CH = 1080, 1350
ABILITIES = [  # (leader id, figure, icon, ability, line 1, line 2): the game's abilities (leaders v3)
    ("bibi", "bibi-matchmaker", "bibi", "׳תתאחדו׳", "בן גביר וסמוטריץ׳ מסרבים זה לזה.", "בינתיים לא דורשים כלום."),
    ("bennett", "bennett-sign", "bennett", "׳לחתום׳ או ׳להפוך׳", "חותם על התחייבות.", "הופך אותה תמורת כסף."),
    ("bengvir", "ben-gvir-walkout", "bengvir", "׳אני פורש׳", "20 שניות בחוץ.", "חוזר. זול יותר."),
    ("liberman", "liberman-document", "liberman", "׳המסמך׳", "כל ׳לא אשב׳ כותב סעיף.", "חמישה סעיפים: מסמך."),
    ("eisenkot", "eisenkot-summit", "eisenkot", "׳לכנס׳", "שולחן עגול.", "כולם יושבים בשקט."),
    ("smotrich", "smotrich-budget", "smotrich", "׳תקציב בדקה ה־90׳", "מאשרים ברגע האחרון.", "מקבלים יותר."),
    ("deri", "deri-bench", "deri", "׳למסדרון׳", "הדרישה מחכה.", "סוגרים במסדרון."),
    ("golan", "golan-swipe", "golan", "׳שמאלה׳", "נתניהו מציע אחדות.", "החלקה."),
]


def slide_bg():
    c = grad((CW, CH), *NAVY)
    d = ImageDraw.Draw(c)
    d.rectangle((24, 24, CW - 25, CH - 25), outline=GOLD_SH, width=6)
    return c


def counter(c, i, n):
    t = text("%d/%d" % (i, n), 4, fill=(150, 160, 200), ring=None, shadow=False, rtl=False)
    comp(c, t, 90, 80)


def make_abilities():
    n = len(ABILITIES) + 2
    c = slide_bg()                                                    # 1: the hook
    comp(c, img("wordmark", 6), CW // 2, 300)
    lines_center(c, ["בחרו ראש רשימה."], 520, 9, fill=WHITE, ring=INK)
    lines_center(c, ["לכל אחד יש תרגיל."], 650, 9, fill=GOLD_HI, ring=INK)
    for i, (lid, *_ ) in enumerate(ABILITIES):
        comp(c, circle_av("avatar_pick_%s_d3" % P.LEAD[lid][1], 150), CW - 160 - (i % 4) * 253, 900 + (i // 4) * 180)
    comp(c, text("החליקו ←", 6, fill=(170, 180, 220), ring=None, shadow=False), CW // 2, 1240)
    counter(c, 1, n)
    save(c, "carousel-abilities", "01.png")
    for j, (lid, fig, icon, ab, l1, l2) in enumerate(ABILITIES):
        c = slide_bg()
        name, party = P.LEAD[lid][2], P.LEAD[lid][3]
        comp(c, text(name, 7, fill=WHITE, ring=INK), CW // 2, 130)
        comp(c, text(party, 5, fill=(170, 180, 220), ring=None, shadow=False), CW // 2, 205)
        f = figure(fig, 2)
        d = ImageDraw.Draw(c)
        d.ellipse((CW // 2 - 300, 840, CW // 2 + 300, 900), fill=(4, 6, 20))
        comp(c, f, CW // 2, 880, "b")
        chip_icon = img("prop_ability_" + icon, 7)
        t = text(ab, 9, grad=True)
        w = t.width + chip_icon.width + 90
        comp(c, plate(w, 150, NIGHT, GOLD, 6), CW // 2, 990)
        comp(c, chip_icon, CW // 2 + w // 2 - 40 - chip_icon.width // 2, 990)
        comp(c, t, CW // 2 - (chip_icon.width + 20) // 2, 990)
        lines_center(c, [l1], 1110, 6, fill=WHITE, ring=INK)
        lines_center(c, [l2], 1190, 6, fill=GOLD_HI, ring=INK)
        counter(c, j + 2, n)
        save(c, "carousel-abilities", "%02d.png" % (j + 2))
    c = slide_bg()                                                    # the last: a question for the comments
    y = lines_center(c, ["איזו יכולת", "הייתם לוקחים?"], 330, 10, fill=WHITE, ring=INK, gap=34)
    lines_center(c, ["כתבו בתגובות."], y + 40, 7, fill=GOLD_HI, ring=INK)
    comp(c, badge("בקרוב", 12), CW // 2, 920)
    comp(c, text("@od.sevev", 8, fill=WHITE, ring=INK, rtl=False), CW // 2, 1100)
    comp(c, text("סאטירה. לא מטעם אף מפלגה.", 4, fill=(150, 160, 200), ring=None, shadow=False), CW // 2, 1220)
    counter(c, n, n)
    save(c, "carousel-abilities", "%02d.png" % n)


# ============================================================================ 3. carousel: the dictionary

PAPER = (244, 238, 222)
DICT = [  # (word, part of speech, definition lines, illustration)
    ("רוטציה", "נ׳", ["משהו שמחכים לו.", "מאז 2020."], ("gantz", "idle")),
    ("מסדרון", "ז׳", ["המקום שבו באמת מחליטים.", "המליאה: תפאורה."], ("deri-bench", None)),
    ("התחייבות", "נ׳", ["מסמך חתום.", "בעיפרון."], ("bennett-sign", None)),
    ("קו אדום", "ז׳", ["דף אדום.", "ראו גם: עוד דף אדום."], ("liberman-document", None)),
    ("פרישה", "נ׳", ["יציאה זמנית מהממשלה.", "כולל ארגז. החזרה כלולה."], ("ben-gvir-walkout", None)),
    ("תקציב", "ז׳", ["מסמך שמאשרים בדקה ה־90.", "כל פעם. בהפתעה."], ("smotrich-budget", None)),
    ("אחדות", "נ׳", ["הצעה שכולם מחליקים", "עליה שמאלה."], ("golan-swipe", None)),
    ("61", "מספר", ["מספר דמיוני.", "ראו: עוד סבב."], None),
    ("עוד סבב", "ז׳", ["ראו: 61."], "end"),
]


def make_dictionary():
    n = len(DICT) + 1
    c = Image.new("RGBA", (CW, CH), PAPER + (255,))
    d = ImageDraw.Draw(c)
    d.rectangle((60, 60, CW - 61, CH - 61), outline=(60, 50, 40), width=4)
    lines_center(c, ["מילון"], 320, 9, fill=(120, 100, 80))
    lines_center(c, ["עוד סבב"], 430, 16, fill=INK)
    lines_center(c, ["9 מילים שצריך לדעת", "לפני הבחירות."], 700, 7, fill=(60, 50, 40), gap=24)
    comp(c, text("החליקו ←", 6, fill=(120, 100, 80), ring=None, shadow=False), CW // 2, 1150)
    counter(c, 1, n)
    save(c, "carousel-dictionary", "01.png")
    for j, (word, pos, lines, ill) in enumerate(DICT):
        c = Image.new("RGBA", (CW, CH), PAPER + (255,))
        d = ImageDraw.Draw(c)
        d.rectangle((60, 60, CW - 61, CH - 61), outline=(60, 50, 40), width=4)
        hw = text(word, 13, fill=INK, ring=None, shadow=False, rtl=word != "61")
        ps = text("(%s)" % pos, 6, fill=(130, 110, 90), ring=None, shadow=False)
        comp(c, hw, CW - 130 - hw.width // 2, 260)
        comp(c, ps, CW - 150 - hw.width - ps.width // 2, 280)
        d.line((130, 380, CW - 130, 380), fill=(60, 50, 40), width=4)
        y = 450
        for i, s in enumerate(lines):
            t = text(s, 7, fill=INK if i == 0 else (170, 40, 40), ring=None, shadow=False)
            comp(c, t, CW - 130 - t.width // 2, y + t.height // 2)
            y += t.height + 30
        if ill == "end":
            comp(c, img("wordmark", 5), CW // 2, 880)
            comp(c, badge("בקרוב", 11), CW // 2, 1060)
            comp(c, text("@od.sevev", 7, fill=INK, ring=None, shadow=False, rtl=False), CW // 2, 1190)
        elif ill is None:
            P.hemicycle(c, CW // 2, 950, 10, filled=60)
        else:
            f = figure(ill[0], 2, ill[1])
            if f.height > 560:
                f = f.resize((int(f.width * 560 / f.height), 560), Image.LANCZOS)
            comp(c, f, 330, 1240, "b")
        counter(c, j + 2, n)
        save(c, "carousel-dictionary", "%02d.png" % (j + 2))


# ============================================================================ 4. Stories

SW, SH = 1080, 1920


def story_bg(top, bot):
    c = grad((SW, SH), top, bot)
    k.vignette(c)
    return c


def lineup(c, y, size=150):
    for i, lid in enumerate(["bibi", "bennett", "bengvir", "liberman", "smotrich", "eisenkot", "deri", "golan"]):
        comp(c, circle_av("avatar_pick_%s_d3" % P.LEAD[lid][1], size), SW - 150 - (i % 4) * 260, y + (i // 4) * (size + 30))


def make_stories():
    """Five frames; the gap in each (marked in the README) is where Instagram's own sticker goes."""
    # 1: the countdown (Instagram's countdown sticker: y 900-1150)
    c = story_bg((20, 30, 90), (6, 8, 30))
    comp(c, img("wordmark", 7), SW // 2, 420)
    lines_center(c, ["משהו מגיע."], 600, 10, fill=WHITE, ring=INK)
    lineup(c, 1250)
    save(c, "stories", "01-countdown.png")
    # 2: this or that (the poll sticker: y 1300-1450, under the two cards)
    c = story_bg((60, 20, 60), (14, 8, 30))
    lines_center(c, ["איפה סוגרים", "עסקה?"], 300, 11, fill=WHITE, ring=INK, gap=24)
    for x, prop, lab, who in ((780, "prop_corridor-bench", "במסדרון", "deri"), (300, "prop_round-table", "בשולחן עגול", "eisenkot")):
        comp(c, plate(440, 560, NIGHT, GOLD_SH, 6), x, 900)
        comp(c, img(prop, 11), x, 860)
        comp(c, text(lab, 7, fill=GOLD_HI, ring=INK), x, 1100)
    save(c, "stories", "02-this-or-that.png")
    # 3: the quiz (the quiz sticker, 3 / 5 / 8, answer 5: April 2019 to November 2022; y 1150-1450)
    c = story_bg((10, 50, 60), (4, 14, 20))
    lines_center(c, ["כמה מערכות בחירות", "היו בפחות מ־4 שנים?"], 300, 9, fill=WHITE, ring=INK, gap=28)
    P.hemicycle(c, SW // 2, 800, 11, filled=0)
    f = figure("dubi-mic", 2, "talk", 1)
    comp(c, f.resize((f.width * 3 // 4, f.height * 3 // 4), Image.LANCZOS), 880, 1700, "b")
    comp(c, text("רמז: יותר מאחת.", 6, fill=(170, 220, 220), ring=None, shadow=False), 420, 1560)
    save(c, "stories", "03-quiz.png")
    # 4: ask Dubi (the question sticker: y 1250-1500)
    c = story_bg((30, 60, 30), (8, 18, 10))
    lines_center(c, ["שאלו את דובי."], 300, 11, fill=WHITE, ring=INK)
    lines_center(c, ["הוא עונה על הכל.", "פעמיים."], 470, 7, fill=(200, 240, 200), ring=INK, gap=20)
    f = figure("dubi-mic", 2, "talk", 1)
    comp(c, f, SW // 2, 1230, "b")
    save(c, "stories", "04-ask-dubi.png")
    # 5: follow (a mention or notify sticker: y 1050-1200)
    c = story_bg((20, 30, 90), (6, 8, 30))
    lines_center(c, ["הפעילו התראות."], 330, 10, fill=WHITE, ring=INK)
    lines_center(c, ["כשזה יוצא,", "תדעו ראשונים."], 500, 8, fill=GOLD_HI, ring=INK, gap=22)
    comp(c, text("@od.sevev", 10, fill=WHITE, ring=INK, rtl=False), SW // 2, 860)
    lineup(c, 1250)
    save(c, "stories", "05-follow.png")


# ============================================================================ 5. memes

def meme(top_lines, panel, out):
    c = Image.new("RGBA", (CW, CH), WHITE + (255,))
    y = 70
    for s in top_lines:
        t = text(s, 7, fill=INK, ring=None, shadow=False)
        comp(c, t, CW - 80 - t.width // 2, y + t.height // 2)
        y += t.height + 22
    py = max(y + 30, 300)
    st = k.stage("knesset", 6).crop((0, 300, CW, 300 + CH - py - 40))
    c.alpha_composite(st, (0, py))
    panel(c, py)
    comp(c, text("@od.sevev", 4, fill=WHITE, ring=INK, rtl=False), CW - 120, CH - 70)
    save(c, "memes", out)


def m_liberman(c, py):
    f = figure("liberman-document", 2)
    comp(c, f, CW // 2, CH - 60, "b")
    comp(c, k.bubble("לא אשב.", 7), CW // 2 - 200, py + 140)


def m_gantz(c, py):
    f = figure("gantz", 2)
    comp(c, f, CW // 2, CH - 60, "b")
    comp(c, plate(470, 110, NIGHT, GOLD_SH, 5), CW // 2, py + 110)
    comp(c, text("סטטוס: נקרא.", 6, fill=WHITE, ring=None, shadow=False), CW // 2, py + 110)


def m_bengvir(c, py):
    d = ImageDraw.Draw(c)
    d.rectangle((CW // 2 - 4, py, CW // 2 + 3, CH), fill=WHITE)
    for x, fig, lab in ((800, "ben-gvir-walkout", "יצא מהקבוצה"), (280, "ben-gvir-back", "הצטרף לקבוצה")):
        f = figure(fig, 2)
        if f.width > 500:
            f = f.resize((500, int(f.height * 500 / f.width)), Image.LANCZOS)
        comp(c, f, x, CH - 60, "b")
        comp(c, plate(400, 90, (30, 40, 50), (30, 40, 50), 4), x, py + 80)
        comp(c, text(lab, 5, fill=(220, 230, 235), ring=None, shadow=False), x, py + 80)


def m_smotrich(c, py):
    f = figure("smotrich-budget", 2)
    comp(c, f, CW // 2, CH - 60, "b")
    comp(c, k.bubble("עוד יש זמן.", 6), CW // 2 + 200, py + 130)


def make_memes():
    meme(["אף אחד:", "ליברמן:"], m_liberman, "01-af-echad.png")
    meme(["אני אחרי ששלחתי", "תזכורת לקבוצה:"], m_gantz, "02-status-nikra.png")
    meme(["אני בכל קבוצת וואטסאפ:"], m_bengvir, "03-whatsapp.png")
    meme(["הדדליין: בעוד חודש.", "אני, בדקה ה־89:"], m_smotrich, "04-deadline.png")


# ============================================================================ 6. highlight covers

def make_highlights():
    covers = [("characters", lambda: circle_av("avatar_pick_bibi_d3", 640)),
              ("news", lambda: circle_av("avatar_dubi", 640)),
              ("soon", lambda: img("icon_clock").crop((0, 0, 9, 9)).resize((540, 540), Image.NEAREST)),
              ("making-of", lambda: img("prop_clause-doc", 22)),
              ("questions", lambda: text("?", 70, fill=GOLD_HI, ring=INK, rtl=False))]
    for name, icon in covers:
        c = grad((SW, SH), *NAVY)
        d = ImageDraw.Draw(c)
        d.ellipse((SW // 2 - 470, SH // 2 - 470, SW // 2 + 470, SH // 2 + 470), outline=GOLD, width=24)
        comp(c, icon(), SW // 2, SH // 2)
        save(c, "highlights", name + ".png")


def main():
    which = sys.argv[1] if len(sys.argv) > 1 else "all"
    jobs = {"stickers": make_stickers, "abilities": make_abilities, "dictionary": make_dictionary,
            "stories": make_stories, "memes": make_memes, "highlights": make_highlights}
    for name, job in jobs.items():
        if which in ("all", name):
            job()
            print("done:", name)


if __name__ == "__main__":
    main()
