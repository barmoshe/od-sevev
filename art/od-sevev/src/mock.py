"""Game-scale proofs: the kit assembled into a HUD screen and a chat screen on the real 180x320 grid,
with the approved cast and stages, plus the share cards with sample text. Output at x2 (and x4 crops)
in proofs/. These are proofs, not layouts: the UX Designer owns placement (hud-layout for 720x1280).
"""
import json
import os
from PIL import Image

from pix import Layer
from palette import rgb
from kit import ROOT, PROOFS
from sheet import nine
import hebfont

SHOW = os.path.normpath(os.path.join(ROOT, "..", "..", "..", "..", "artifacts", "creative-pack", "od-sevev", "art",
                                     "showcase", "out"))
_K = {}


def _kit():
    if not _K:
        _K.update({e["id"]: e for e in json.load(open(os.path.join(ROOT, "ui-kit.json")))["pieces"]})
    return _K


def P(pid, frame=None):
    e = _kit()[pid]
    im = Image.open(os.path.join(ROOT, e["file"])).convert("RGBA")
    if frame is not None:
        fw = e["frameW"]
        im = im.crop((frame * fw, 0, (frame + 1) * fw, im.height))
    return im


def N(pid, w, h):
    e = _kit()[pid]
    return nine(P(pid), e["slice"], w, h, e.get("mode", "stretch"))


def S(name):
    return Image.open(os.path.join(SHOW, name)).convert("RGBA")


def T(text, color="white", shadow=None):
    w = max(hebfont.measure(text), 1)
    L = Layer(w + 2, 11)
    hebfont.draw(L, text, 0, 0, color, align="left", shadow=shadow)
    return L.to_image(1)


def rect(img, x, y, w, h, sw):
    img.paste(rgb(sw) + (255,), (x, y, x + w, y + h))


def put(img, im, x, y):
    img.alpha_composite(im, (int(x), int(y)))


def text_r(img, text, xr, y, color="white"):
    """Right-aligned (RTL) text whose right edge is xr."""
    t = T(text, color)
    put(img, t, xr - t.width + 2, y)
    return t.width - 2


def text_c(img, text, cx, y, color="white"):
    t = T(text, color)
    put(img, t, cx - (t.width - 2) // 2, y)


def text_l(img, text, x, y, color="white"):
    put(img, T(text, color), x, y)


def wrap(text, maxw):
    words, lines, cur = text.split(" "), [], ""
    for w in words:
        cand = (cur + " " + w).strip()
        if hebfont.measure(cand) <= maxw:
            cur = cand
        else:
            lines.append(cur); cur = w
    lines.append(cur)
    return lines


# ------------------------------------------------------------------ HUD
def hud():
    img = S("stage_balfour.png")
    # row A
    rect(img, 0, 0, 180, 24, "ui_scrim")
    put(img, P("cottage_cup", 1), 3, 3)
    text_c(img, "12.4K ₪", 90, 2, "white")
    text_c(img, "+38 ₪ לשנייה", 90, 13, "grey")
    # row B
    rect(img, 0, 24, 180, 20, "ui_scrim")
    img.paste(rgb("outline") + (255,), (0, 43, 180, 44))
    text_r(img, "מנדטים", 176, 29, "white")
    tx, tw = 34, 106
    put(img, N("seats_track", tw, 9), tx, 29)
    seats = 58
    fw = round((tw - 2) * seats / 61)
    put(img, N("seats_fill", fw, 7), tx + 1 + (tw - 2 - fw), 30)
    for n in range(10, 61, 10):
        x = tx + 1 + (tw - 2) - round((tw - 2) * n / 61)
        if x >= tx + 1 + (tw - 2 - fw):
            put(img, P("seats_tick"), x, 30)
    text_l(img, "58/61", 4, 29, "white")
    # thermometer
    th = P("thermo_tube").copy()
    liq = _kit()["thermo_tube"]["liquid"]
    floor, cur = 0.10, 0.42
    ytop = lambda p: liq["yBottom"] - round(p * (liq["yBottom"] - liq["yTop"]))
    hat = P("thermo_floor_hatch")
    for y in range(ytop(floor), liq["yBottom"] + 1):
        for x in range(4):
            th.putpixel((liq["x"] + x, y), hat.getpixel((x, y % 4)))
    fill = P("thermo_fill")
    for y in range(ytop(cur), ytop(floor)):
        th.alpha_composite(fill, (liq["x"], y))
    th.alpha_composite(P("thermo_meniscus"), (liq["x"], ytop(cur)))
    put(img, th, 4, 66)
    put(img, P("thermo_icon_magnifier"), 5, 52)
    # the Magician on the slot, the Suitcase in its band
    f = S("bibi_idle.png").crop((0, 0, 71, 125))
    put(img, f, 90 - 35, 216 - 124)
    put(img, P("suitcase"), 128, 188)
    # ticker
    rect(img, 0, 232, 180, 20, "ui_panel")
    img.paste(rgb("outline") + (255,), (0, 232, 180, 233))
    rect(img, 146, 235, 32, 14, "red")
    text_c(img, "מבזק", 162, 237, "white")
    tick = T("על פי פרסומים זרים, יש כובע.", "silver")
    tick = tick.crop((max(0, tick.width - 92), 0, tick.width, tick.height))
    put(img, tick, 144 - tick.width, 237)
    chip = N("chip_countdown", 46, 13)
    put(img, chip, 2, 235)
    put(img, P("chip_icon_calendar"), 2 + 46 - 12, 237)
    text_r(img, "27.10", 2 + 46 - 14, 237, "white")
    # panel: one source card + the next one peeking
    rect(img, 0, 252, 180, 42, "night")
    card = N("card_row", 176, 30)
    put(img, card, 2, 254)
    put(img, N("card_plate", 26, 26), 2 + 176 - 29, 256)
    put(img, P("tabicon_sources_active"), 2 + 176 - 29 + 5, 261)
    text_r(img, "משלם המסים", 2 + 176 - 33, 257, "white")
    text_r(img, "+1 ₪ לשנייה · 3", 2 + 176 - 33, 268, "grey")
    pill = N("pay_pill_default", 54, 17)
    put(img, pill, 7, 260)
    text_c(img, "15 ₪", 7 + 27, 263, "ink")
    put(img, N("card_row", 176, 30).crop((0, 0, 176, 8)), 2, 286)
    # tab bar
    put(img, P("tabbar"), 0, 294)
    order = ["sources", "spins", "coalition", "cases"]
    heb = ["מקורות", "ספינים", "קואליציה", "תיקים"]
    for i, (k, hname) in enumerate(zip(order, heb)):
        x0 = 180 - 45 * (i + 1)
        if i == 0:
            put(img, P("tab_active"), x0, 294)
        put(img, P(f"tabicon_{k}_{'active' if i == 0 else 'idle'}"), x0 + 15, 296)
        text_c(img, hname, x0 + 22, 309, "white" if i == 0 else "grey")
        if k == "coalition":
            put(img, P("badge_count"), x0 + 29, 295)
            text_c(img, "1", x0 + 34, 294, "white")
    return img


# ------------------------------------------------------------------ chat
def chat():
    img = Image.new("RGBA", (180, 320), rgb("night") + (255,))
    put(img, P("chat_header"), 0, 0)
    put(img, P("chat_icon_chevron"), 170, 8)
    put(img, P("chat_icon_lock"), 157 - hebfont.measure("קואליציה 61") - 10, 4)
    text_r(img, "קואליציה 61", 157, 3, "white")
    text_r(img, "בן גביר מקליד/ה…", 157, 13, "grey")
    put(img, P("chat_pinned"), 0, 26)
    put(img, P("chat_icon_pin"), 167, 28)
    text_r(img, "נעוץ: ההסכם הקואליציוני · טיוטה 14", 164, 28, "grey")
    y = 44
    # system pill (wrapped)
    lines = wrap("הקוסם יצר את הקבוצה ״קואליציה 61״", 150)
    h = 4 + 10 * len(lines)
    wmax = max(hebfont.measure(t) for t in lines) + 8
    put(img, N("chat_system_pill", wmax, h), 90 - wmax // 2, y)
    for k, t in enumerate(lines):
        text_c(img, t, 90, y + 2 + 10 * k, "white")
    y += h + 5
    # incoming demand with avatar and pay pill
    av = S("ben-gvir_avatar.png")
    put(img, av, 146, y)
    text_r(img, "בן גביר", 142, y, "grey")
    body = wrap("צריך תקציב לביטחון לאומי. היום, לא מחר.", 104)
    bh = 6 + 10 * len(body) + 20
    bw = 120
    put(img, N("chat_bubble_in", bw, bh), 142 - bw + 5, y + 10)
    for k, t in enumerate(body):
        text_r(img, t, 142 - 9, y + 13 + 10 * k, "white")
    put(img, N("pay_pill_default", 70, 17), 142 - 9 - 70, y + 13 + 10 * len(body) + 1)
    text_c(img, "סגרנו · 60 ₪", 142 - 9 - 35, y + 13 + 10 * len(body) + 4, "ink")
    y += 10 + bh + 4
    # player's reply + the paid stamp
    put(img, N("chat_bubble_out", 52, 16), 4, y)
    text_r(img, "העברתי.", 4 + 52 - 5, y + 3, "white")
    put(img, P("stamp_paid_dark"), 64, y)
    y += 22
    # ultimatum
    ub = N("chat_bubble_ultimatum", 132, 46)
    put(img, ub, 142 - 132 + 7, y + 10)
    put(img, av, 146, y)
    text_r(img, "בן גביר", 142, y, "grey")
    text_r(img, "אולטימטום", 142 - 10, y + 16, "red_hi")
    text_r(img, "אם אין תקציב, אני בחוץ.", 142 - 10, y + 27, "white")
    put(img, N("chip_ultimatum", 34, 13), 142 - 10 - 34 - 72, y + 39)
    put(img, P("icon_clock", 1), 142 - 10 - 72 - 12, y + 41)
    text_r(img, "0:45", 142 - 10 - 72 - 14, y + 41, "white")
    put(img, N("pay_pill_default", 64, 17), 142 - 10 - 64, y + 37)
    text_c(img, "סגרנו · 90 ₪", 142 - 10 - 32, y + 40, "ink")
    y += 60
    # brawl
    lines = wrap("אמסלם וסמוטריץ׳ רבים. שתי השורות הוקפאו.", 150)
    h = 4 + 10 * len(lines)
    wmax = max(hebfont.measure(t) for t in lines) + 8
    put(img, N("chat_system_pill", wmax, h), 90 - wmax // 2, y)
    for k, t in enumerate(lines):
        text_c(img, t, 90, y + 2 + 10 * k, "white")
    put(img, P("brawl_cloud", 1), 64, y + h - 6)
    y += h + 30
    put(img, N("button_secondary_default", 60, 20), 60, y)
    text_c(img, "צאו החוצה", 90, y + 4, "white")
    put(img, P("chat_composer_disabled"), 0, 298)
    text_r(img, "פה מדברים רק בשקלים", 170, 304, "slate")
    return img


# ------------------------------------------------------------------ transfer + court (overlays)
def overlays():
    img = hud()
    sc = Image.new("RGBA", img.size, (0, 0, 0, 150))
    img.alpha_composite(sc)
    put(img, P("transfer_banner"), 0, 60)
    put(img, N("transfer_card", 180, 34), 0, 90)
    text_c(img, "גוטליב", 90, 94, "gold_hi")
    text_c(img, "קואליציה ← עוצמה · כולל דמי אחזקה", 90, 106, "white")
    cf = N("court_frame", 164, 82)
    put(img, cf, 8, 150)
    put(img, P("thermo_icon_gavel"), 8 + 164 - 18, 155)
    text_r(img, "יום משפט", 8 + 164 - 22, 156, "white")
    text_r(img, "הקוסם בדוכן העדים.", 8 + 164 - 8, 172, "white")
    text_r(img, "ההכנסות מואטות.", 8 + 164 - 8, 182, "white")
    text_r(img, "עדות: 02:40", 8 + 164 - 8, 192, "grey")
    put(img, P("stamp_postponed_dark"), 18, 172)
    put(img, N("button_primary_default", 96, 20), 8 + 164 - 8 - 96, 204)
    text_c(img, "התייעצות ביטחונית", 8 + 164 - 8 - 48, 208, "white")
    put(img, N("button_secondary_default", 50, 20), 16, 204)
    text_c(img, "להעיד", 41, 208, "white")
    put(img, N("chip_court", 64, 13), 58, 236)
    put(img, P("chip_icon_gavel"), 58 + 64 - 12, 238)
    text_r(img, "יום משפט · 02:40", 58 + 64 - 14, 238, "white")
    return img


# ------------------------------------------------------------------ share cards with sample text
RECEIPT = [   # UX's fit (ux/string-budgets.json): 19 text lines + 3 rules = the 22-row column
    ("c", "עוד סבב"), ("c", "חשבונית מס / קבלה (העתק)"), ("c", "סבב בחירות מס׳ 6 · 28.09.2026"), ("rule", ""),
    ("c", "הקיסרות שלך עלתה"), ("c", "למשפחה הממוצעת"), ("c", "4,213,000 ₪ החודש"), ("rule", ""),
    ("item", ("מע״מ 18%*", "1,102,000 ₪")),
    ("item", ("דלק 95: 8.25 ₪ לליטר*", "")), ("item", ("(שיא, 1.9.2026)", "760,000 ₪")),
    ("item", ("כנף ציון: חלקכם*", "508,000 ₪")),
    ("item", ("גלידת פיסטוק*", "0 ₪")),
    ("item", ("כספים קואליציוניים*", "1,843,000 ₪")),
    ("item", ("סה״כ", "4,213,000 ₪")), ("r", "שולם על ידי: אתם"),
    ("r", "עד הבחירות: 29 ימים (27.10)"), ("rule", ""),
    ("r", "* הנתון אמיתי. הסכום מהמשחק."), ("r", "סאטירה. לא קשור לאף מפלגה"), ("r", "או מועמד."),
    ("url", "od-sevev.xyz"),
]


def receipt():
    img = P("share_receipt_bg").copy()
    x0, y0, w, h = _kit()["share_receipt_bg"]["textColumn"]
    y = y0
    over = []
    for kind, val in RECEIPT:
        if kind == "rule":
            r = P("receipt_rule")
            for x in range(x0, x0 + w, 8):
                put(img, r, x, y + 4)
            y += 9
            continue
        if kind == "item":
            a, b = val
            text_r(img, a, x0 + w - 1, y, "receipt_ink")
            if b:
                text_l(img, b, x0, y, "receipt_ink")
            if hebfont.measure(a) + hebfont.measure(b) + 6 > w:
                over.append(a)
        elif kind == "url":
            text_c(img, val, x0 + w // 2, y, "receipt_ink")
        elif kind == "c":
            text_c(img, val, x0 + w // 2, y, "receipt_ink")
            if hebfont.measure(val) > w:
                over.append(val)
        else:
            text_r(img, val, x0 + w - 1, y, "receipt_ink")
            if hebfont.measure(val) > w:
                over.append(val)
        y += 10
    return img, over, y


def result():
    img = P("share_result_frame").copy()
    z = _kit()["share_result_frame"]["zones"]
    f = S("bibi_idle.png").crop((0, 0, 71, 125))
    ax, ay = z["castAnchor"]
    put(img, f, ax - 35, ay - 124)
    text_c(img, "שרדתי 6 סבבי בחירות", 108, 43, "white")
    text_c(img, "ו־3 ימי משפט", 108, 54, "white")
    text_c(img, "והציבור? נרגש.", 108, 67, "silver")
    text_c(img, "מזוודות שנתפסו: 12 · בקשות דחייה: 9", 108, 215, "silver")
    text_c(img, "עוד סבב · משחק סאטירה · od-sevev.xyz", 108, 238, "white")
    text_c(img, "סאטירה. לא קשור לאף מפלגה או מועמד.", 108, 251, "grey")
    return img


def cvd(img, kind):
    from proofs_cvd import simulate
    return simulate(img, kind)


def build():
    os.makedirs(PROOFS, exist_ok=True)
    h = hud(); c = chat(); o = overlays()
    row = Image.new("RGBA", (180 * 3 + 16, 320), (0, 0, 0, 255))
    for i, im in enumerate((h, c, o)):
        row.alpha_composite(im, (i * 188, 0))
    row.resize((row.width * 2, row.height * 2), Image.NEAREST).save(os.path.join(PROOFS, "game-scale-hud-chat-overlays-x2.png"))
    h.resize((720, 1280), Image.NEAREST).save(os.path.join(PROOFS, "game-scale-hud-x4.png"))
    c.resize((720, 1280), Image.NEAREST).save(os.path.join(PROOFS, "game-scale-chat-x4.png"))
    # phone-size read: the whole 720x1280 frame downsampled to a 390-CSS-wide phone (x2.17 per art px)
    ph = Image.new("RGBA", (390 * 3 + 20, 693), (0, 0, 0, 255))
    for i, im in enumerate((h, c, o)):
        ph.alpha_composite(im.resize((720, 1280), Image.NEAREST).resize((390, 693), Image.LANCZOS), (i * 400, 0))
    ph.save(os.path.join(PROOFS, "phone-390css-read.png"))
    r, over, yend = receipt()
    res = result()
    both = Image.new("RGBA", (216 * 2 + 8, 270), (0, 0, 0, 255))
    both.alpha_composite(r, (0, 0)); both.alpha_composite(res, (224, 0))
    both.resize((both.width * 2, both.height * 2), Image.NEAREST).save(os.path.join(PROOFS, "share-cards-x2.png"))
    r.resize((1080, 1350), Image.NEAREST).convert("RGB").save(os.path.join(PROOFS, "share-receipt-sample-1080.png"))
    res.resize((1080, 1350), Image.NEAREST).convert("RGB").save(os.path.join(PROOFS, "share-result-sample-1080.png"))
    return h, c, o, over, yend


if __name__ == "__main__":
    h, c, o, over, yend = build()
    print("receipt overflow lines:", over, "text ends at y", yend)
