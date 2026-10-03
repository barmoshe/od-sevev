#!/usr/bin/env python3
"""Generates ux/ui-strings.json and ux/string-budgets.json for "עוד סבב" and self-lints every
canvas string against its box with the shipping font's metrics (game/assets/fonts/sevev9.fnt xadvance,
the same sum TextServer and tools/lint_text.sh use).

Run: python3 ux/tools/gen_strings.py   (edit strings HERE, never in the JSON; exit code 1 on lint errors)

Notation in this source (converted on output):
  ⟦ … ⟧  -> LRI (U+2066) … PDI (U+2069)   bidi isolate for numeric runs
  ~₪     -> U+00A0 + ₪                    no-break space before the shekel sign
"""
import json, re, sys, math, os

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.dirname(HERE)  # ux/

LRI, PDI, NBSP = "⁦", "⁩", " "

# ---------------------------------------------------------------- boxes (rtl-map.md)
# name: (width_px, base_scale, lines_at_base, lines_at_large, note)
BOXES = {
    # Canvas text is x4 (one pixel grid with the art: 1 art px = 4 logical). Large text = x5 (an accessibility
    # exception to the grid). Share cards use their own art grid (x5 image, text at art scale 1).
    "rowA.counter":   (328, 4, 1, 1, "Row A counter (7-row numeral cut), centred x 196-524"),
    "rowA.rate":      (344, 4, 1, 1, "Row A rate line, centred x 188-532"),
    "rowA.cottageMinus": (88, 4, 1, 1, "The '−1' rising over the cottage cup on a pixel drop (motion cottage-pixel-loss), PxText"),
    "rowB.label":     (128, 4, 1, 1, "Row B label x 576-704"),
    "rowB.value":     (120, 4, 1, 1, "Row B numeral x 16-136 (PxText)"),
    "rowB.stamp":     (256, 4, 1, 1, "Blackout stamp inner (baked art; text is the a11y fallback)"),
    "stage.toast":    (644, 4, 2, 3, "Toast text x 32-676 (the kit toast's content box ends 6 art px = 24 before the plate's right edge, 704; 4 px air)"),
    "stage.toastChat":(564, 4, 2, 3, "Chat toast text x 32-596 (the 16x16 avatar crop, 64 px, at x 612-676 inside the accent)"),
    "stage.toastHead":(564, 4, 1, 1, "Chat toast line 1: sender + group, x 32-596"),
    "stage.courtChip":(256, 4, 1, 1, "Court chip inner"),
    "stage.thermo":   (120, 4, 1, 1, "Thermometer state word, x 12-132"),
    "stage.floater":  (400, 4, 1, 1, "Tap floater"),
    "stage.buffChip": (384, 4, 1, 1, "Buff chip inner (chip x 160-560)"),
    "stage.banner":   (496, 4, 1, 2, "Catch banner inner"),
    "stage.cameoChip":(128, 4, 1, 1, "Ultimatum chip over the stage cameo (PxText)"),
    "ticker.tag":     (88, 4, 1, 1, "Ticker anchor label"),
    "ticker.chip":    (160, 4, 1, 1, "Ticker chip line: date (+ calendar icon) or court day (2 lines)"),
    "ticker.chipWide":(168, 4, 1, 1, "Press-day chip line 1 (rtl-map §5.1: the chip widens to 220, the crawl clip becomes x 236-516 = 280)"),
    "ticker.idle":    (280, 4, 1, 1, "Ticker standing line (D19): one line, the narrowest clip (press day 280); shown while no headline is queued"),
    "ticker.crawl":   (None, 4, 1, 1, "Crawl: no width limit; paged by the live clip width under reduced motion (324 at x4, 302 at x5; 288 / 266 on court day)"),
    "cta.election":   (688, 4, 1, 1, "Election CTA"),
    "card.name":      (360, 4, 1, 2, "Card name x 220-580"),
    "card.line2":     (348, 4, 1, 1, "Card line 2, x 220-568 (the owned badge overlaps the plate corner at x 572+)"),
    "card.line2wide": (360, 4, 1, 2, "Card line 2 when no owned badge shows, x 220-580"),
    "card.pill":      (168, 4, 1, 1, "Pill line (verb or price), pill 184 wide"),
    "card.owned":     (96, 4, 1, 1, "Owned badge on the plate corner (PxText)"),
    "card.ms":        (248, 4, 1, 1, "Source milestone progress on the name row, left-aligned at the text box's left edge (x 220 - grow); drawn only where it clears the name by 16, else the short form, else not at all (the bar under line 2 stays)"),
    "card.msTag":     (72, 4, 1, 1, "Source milestone multiplier: the gold chip after line 2's rate (chip = text + 16, min 48, h 40)"),
    "perk.level":     (120, 4, 1, 1, "Clause level on an agreement row (PxText)"),
    "list.buyLabel":  (384, 4, 1, 2, "Buy-mode row label"),
    "list.buyBtn":    (168, 4, 1, 1, "Buy-mode button (visual 184)"),
    "list.empty":     (656, 4, 1, 2, "Empty-list line"),
    "tab.label":      (164, 4, 1, 1, "Tab label"),
    "tab.badge":      (40, 4, 1, 1, "Tab badge count (PxText)"),
    "tall.title":     (440, 4, 1, 1, "Tall-tab header title"),
    "tall.status":    (584, 4, 1, 1, "Tall-tab header status, x 32-616"),
    "chat.pinned":    (584, 4, 1, 1, "Pinned bar x 64-648 (56 visual)"),
    "chat.bubble":    (416, 4, 99, 99, "Bubble text column (104 art px, 17 glyphs)"),
    "chat.name":      (416, 4, 1, 1, "Sender name in a bubble"),
    "chat.pill":      (296, 4, 1, 1, "Pay pill inner (kit 9-slice stretched to 82x17 art)"),
    "partner.label":  (400, 4, 1, 1, "Partner card row label, right-aligned at the card's right − 32; its value sits at the left"),
    "chat.pillWide":  (480, 4, 1, 1, "Rejoin / poach pill on a system line (visual 512)"),
    "chat.sys":       (568, 4, 2, 3, "System pill inner"),
    "chat.banner":    (656, 4, 2, 3, "Transfer / brawl banner line (the card grows)"),
    "chat.btn":       (304, 4, 1, 1, "Brawl button inner"),
    "chat.label":     (300, 4, 1, 1, "Ultimatum label / forwarded label"),
    "chat.timer":     (120, 4, 1, 1, "Timer (PxText)"),
    "chat.divider":   (480, 4, 1, 1, "Day / unread divider"),
    "chat.pending":   (216, 4, 1, 1, "The '{n} ממתינים' chip on the thread's top edge (chip 296: text 216 + the 7x9 up-arrow icon 28 + air), game-developer views 2026-09-29"),
    "chat.composer":  (640, 4, 1, 1, "Disabled composer"),
    "dos.row":        (656, 4, 1, 2, "Dossier row"),
    "dos.btn":        (624, 4, 1, 1, "Dossier full-width button"),
    "sheet.title":    (432, 4, 1, 1, "Sheet / modal title (clears the top-left close)"),
    "sheet.group":    (360, 4, 1, 1, "Settings group header"),
    "sheet.label":    (360, 4, 1, 2, "Settings row label x 296-656"),
    "sheet.caption":  (360, 4, 2, 3, "Settings caption"),
    "sheet.state":    (104, 4, 1, 1, "Toggle state text x 176-280"),
    "sheet.btn":      (640, 4, 1, 1, "Sheet full-width button"),
    "sheet.note":     (656, 4, 2, 3, "Sheet footnote"),
    "modal.title":    (432, 4, 1, 2, "Modal title"),
    "modal.body":     (560, 4, 4, 6, "Modal body (cards grow vertically)"),
    "modal.big":      (560, 4, 1, 1, "Modal big number (7-row numeral cut)"),
    "modal.btnHalf":  (224, 4, 1, 1, "Half-width modal button inner"),
    "modal.btnFull":  (512, 4, 1, 1, "Full-width modal button inner"),
    "court.body":     (624, 4, 2, 3, "Court card text"),
    "court.btn":      (384, 4, 1, 1, "Court primary button line (2-line button: verb / price)"),
    "stage.ability":  (120, 3, 1, 1, "Leaders v3 ability chip label (AbilityChip.RECT 140 wide, 10 px pads; PxText fit_width may step down)"),
    "court.btn2":     (192, 4, 1, 1, "Court secondary button inner (visual 224)"),
    "tx.line":        (656, 4, 1, 2, "Election transition line"),
    "title.line":     (656, 4, 1, 2, "Title-state line"),
    # receipt: 216x270 art at x5; print column x 32-183 = 152 art px, 22 lines at 10 px pitch
    "receipt.line":   (152, 1, 1, 1, "Receipt full line (152 art px)"),
    "receipt.wrap":   (152, 1, 2, 2, "Receipt line allowed to wrap to 2"),
    "receipt.foot":   (152, 1, 3, 3, "Receipt footer block (disclaimer + URL)"),
    "receipt.item":   (92, 1, 1, 1, "Receipt item, amount on the same line"),
    "receipt.amount": (56, 1, 1, 1, "Receipt amount column"),
    "result.head":    (160, 1, 2, 2, "Result headline plate (2 lines)"),
    "result.line":    (168, 1, 1, 1, "Result stat strip"),
    "result.foot":    (200, 1, 1, 1, "Result footer band line"),
    # the share platform's cards (ui/share_cards.gd): 216 art px wide (square 216x270, story 216x384,
    # OG 240x126), text at 1 font px per art px (scale 1) or 2 (the headlines), a 10-art-px margin
    "card.wide":      (196, 1, 1, 1, "Share card full line (196 art px)"),
    "card.wrap2":     (196, 1, 2, 2, "Share card line allowed to wrap to 2"),
    "card.label":     (120, 1, 1, 1, "Share card label / chip"),
    "card.stamp":     (100, 1, 1, 1, "Share card satire stamp"),
    "card.big":       (196, 2, 2, 2, "Share card headline at scale 2 (2 lines)"),
    "stage.shareChip":(88, 3, 1, 1, "The share chip's label under its icon (ShareDesk chip 104 wide, 8 px pads)"),
    # LEADER_PICK (rtl-map.md §8, design/leader-select-spec.md §3). Tile boxes are the 3-column tile (216 wide,
    # 12 padding); the 2-column wave-1 tile (336) is roomier, so these are the worst case.
    "pick.title":     (656, 4, 1, 2, "Leader pick title, centred x 32-688"),
    "pick.chip":      (560, 4, 1, 1, "Fresh-face chip under the after-election title (kit chat_system_pill, visual <= 592)"),
    "pick.name":      (192, 4, 1, 1, "Pick tile: the leader's short name, centred (tile 216, padding 12)"),
    "pick.party":     (192, 4, 2, 2, "Pick tile: the party, centred, <= 2 lines at pitch 40"),
    "pick.strip":     (656, 4, 2, 2, "Caption strip under the grid (reading cut): the focused / pressed tile's blurb, else the default line"),
    "pick.again":     (560, 4, 1, 1, "'Again' button label (kit button_primary 672 wide: 48 face + 16 gap + label, centred as a group)"),
    "pick.undo":      (352, 4, 1, 1, "Undo chip on the stage after a pick (kit button_secondary, visual 392 x 80)"),
    "pick.card":      (560, 4, 6, 8, "Leader card (long-press / I): rule text; the card grows"),
    # seeded rounds (game-developer, challenge + daily slice, 2026-10-02)
    "pick.daily":     (480, 4, 1, 1, "The Daily Round's entry in the picker's sky (kit button_secondary, visual 544 x 80, a dot when unplayed)"),
    # missions + ranks (game/scripts/ui/missions_chip.gd, ui/views/view_missions.gd; Bar 2026-10-02)
    "stage.missions": (94, 3, 1, 1, "Missions chip word / second line (MissionsChip 152 wide: a 40 badge, 18 of pads; PxText fit_width may step down)"),
    "mis.text":       (560, 4, 2, 3, "Missions sheet: a mission's text (content missions.list[].text), right-aligned in the modal.body box, <= 2 lines"),
    "mis.progress":   (200, 3, 1, 1, "Missions sheet row: the progress (x3) over its bar, x 440-640 (MissionsSheet.RIGHT_W)"),
    "mis.reward":     (336, 4, 1, 1, "Missions sheet row: the reward label, x 88-424 (gold; the claim button takes its place once done)"),
    "mis.btn":        (192, 4, 1, 1, "Missions sheet 'לקחת' (the 224-wide gold kit button, 16 pads)"),
}
LARGE_OK = True  # every canvas label may step down from the large scale to the base scale

# ---------------------------------------------------------------- worst-case placeholder values
PH = {
    # Worst cases are the formatters' real extremes (design/content.json numberFormat): 3 significant digits + a
    # 2-letter suffix for costs/rates ("8.88mm"), 4 for the bank-style totals ("8.888mm"), full grouping on the receipt.
    "n": "999", "price": "8.88mm", "x": "8.888mm", "xr": "8,888,888", "rate": "8.88mm", "cost": "8.88mm", "mult": "99",
    "pmult": "999.9", "s": "60", "d": "29", "h": "24", "m": "59", "mmss": "88:88", "owned": "999",
    "qty": "99", "pending": "9999", "needed": "9999", "seats": "99", "version": "1.10.10",
    "date": "28.09.2026", "pct": "100", "k": "12", "lv": "10", "max": "10", "count": "9", "total": "5",
    "thumbs": "9999", "gmult": "9.99", "now": "999.9", "after": "999.9", "next": "999", "r": "99", "c": "99",
    "name": "גלית דיסטל־אטבריאן", "a": "אמסלם", "b": "סמוטריץ׳", "who": "היועצים המשפטיים",
    "to": "עוצמה יהודית", "from": "הליכוד", "era": "וושינגטון", "outlet": "ידיעות אחרונות",
    "NAME": "פנקס הצ׳קים הזהוב", "UPGRADE_NAME": "הוחלט להקים ועדה", "FLAVOR": "",
    "title": "הקוסם", "dur": "23 שע׳ 59 דק׳", "rounds": "99 סבבי בחירות", "days": "ו־99 ימי משפט",
    "amount": "999.9 מיליון", "url": "od-sevev.vercel.app", "publisher": "", "mail": "", "preview": "", "mood": "",
    "mine": "88:88", "theirs": "88:88",
    # the share platform (ui/share_cards.gd, ShareKit): a run time, a source's name, a payment count
    "time": "1:23:45", "source": "פנקס הצ׳קים הזהוב", "text": "", "grid": "", "paid": "99",
}
NUMERIC_PH = {"n", "price", "x", "xr", "rate", "cost", "mult", "pmult", "s", "d", "h", "m", "mmss", "owned", "time", "paid",
              "qty", "pending", "needed", "seats", "version", "date", "pct", "k", "lv", "max", "count",
              "total", "thumbs", "gmult", "now", "after", "next", "r", "c", "mine", "theirs", "val", "goal"}

HEB = re.compile(r"[א-ת]")

# ---------------------------------------------------------------- leader-select worst cases (from the designer's content)
# Every {short}/{party}/{verb}/... placeholder is linted with the WIDEST value any roster leader has, measured on the
# shipping font, so a new leader whose word is wider shows up here (and in the engine lint via worstCasePlaceholders).
_FNT0 = os.path.normpath(os.path.join(OUT, "..", "game", "assets", "fonts", "sevev9.fnt"))
_XADV0 = {}
for _ln in open(_FNT0, encoding="utf-8"):
    if _ln.startswith("char "):
        _kv = dict(x.split("=", 1) for x in _ln.split()[1:] if "=" in x)
        _XADV0[chr(int(_kv["id"]))] = int(_kv["xadvance"])
def _w0(t):
    return sum(_XADV0.get(ch, 8) for ch in t if ch not in (LRI, PDI))
def _widest(vals, fallback):
    vals = [v for v in vals if isinstance(v, str) and v]
    return max(vals, key=_w0) if vals else fallback
_CJ = os.path.normpath(os.path.join(OUT, "..", "design", "content.json"))
LEADERS = json.load(open(_CJ, encoding="utf-8")).get("leaders", []) if os.path.exists(_CJ) else []
_KITS = [L["kit"] for L in LEADERS if isinstance(L.get("kit"), dict)]
_TAPS = [k.get("tap", {}) for k in _KITS]
_HAZ = [k.get("hazard") for k in _KITS if isinstance(k.get("hazard"), dict)]
PH.update({
    "short": _widest([L.get("short") for L in LEADERS], "סמוטריץ׳"),
    "party": _widest([L.get("party") for L in LEADERS], "הציונות הדתית"),
    "verb": _widest([t.get("verb") for t in _TAPS], "העברה"),
    "verbPlural": _widest([t.get("verbPlural") for t in _TAPS], "סירובים"),
    "critName": _widest([t.get("critName") for t in _TAPS], "לא מוחלט"),
    "critPlural": _widest([t.get("critPlural") for t in _TAPS], "לא מוחלטים"),
    "banner": _widest([t.get("frenzyBanner") for t in _TAPS], "טורבו בסירובים!"),
    "rule": _widest([L.get("rule", {}).get("name") for L in LEADERS if isinstance(L.get("rule"), dict)], "לוח הזמנים"),
    "postpone": _widest([h.get("postponeVerb") for h in _HAZ], "לא יושב באולפן"),
})
# missions (content missions.ranks / missions.list): the widest rank title and mission text, the text's
# {verbPlural} / {critPlural} filled with the widest leader words; the progress numbers at the formatter's worst
_MIS = json.load(open(_CJ, encoding="utf-8")).get("missions", {}) if os.path.exists(_CJ) else {}
def _mis_fill(t):
    return str(t).replace("{verbPlural}", PH["verbPlural"]).replace("{critPlural}", PH["critPlural"])
PH.update({
    "rankTitle": _widest([r.get("title") for r in _MIS.get("ranks", [])], "עוזר פרלמנטרי"),
    "mission": _widest([_mis_fill(m.get("text", "")) for m in _MIS.get("list", [])], "לגייס 10 משלמי מסים. הם לא שאלו"),
    "val": "8.88mm", "goal": "8.88mm",
})

# ---------------------------------------------------------------- entries
# (key, value, box_or_surface, flags, spec)
#   box: a BOXES name -> canvas Label (or PxText when the value has no Hebrew and no ₪)
#   surface override: "html:<max>", "share-text:<max>", "og:<max>", "unused"
#   flags: "*" = chrome carries a joke (never truncate), "L" = legal line, "G" = words owned by the copy deck
E = []
def e(key, value, box, flags="", spec="", note=""):
    E.append((key, value, box, flags, spec, note))

# ================= existing keys (fork schema), translated =================
e("BOOT_LOADING", "טוען…", "title.line")
e("TITLE_WORDMARK_1", "עוד סבב", "title.line", note="Fallback text and a11y name for the pixel wordmark art")
e("TITLE_WORDMARK_2", "", "unused", note="Intentionally empty: the wordmark is one line")
e("TITLE_TAGLINE", "סבב בחירות מס׳ ⟦1⟧ · הציבור נרגש", "title.line", "*", "title.round + mood.1")
e("TITLE_CTA", "", "unused", note="Intentionally empty: zero instruction text in the title state (first-minute §2)")
e("TITLE_KEYHINT", "", "unused", note="Intentionally empty (same reason)")
e("TITLE_FOOTER", "", "unused", note="Intentionally empty (same reason); the save note lives in About")
e("HUD_BPS", "⟦+{rate}⟧~₪ לשנייה", "rowA.rate", "", "hud.rate")
e("HUD_BPS_FRENZY", "⟦+{rate}⟧~₪ לשנייה", "rowA.rate", note="Same text as HUD_BPS in the frenzy tint; the multiplier is on the buff chip")
e("HUD_BPS_POUR", "הכסף הולך לשליפה", "rowA.rate", "*", "rate line while S07 (idleToTap) runs", "Replaces '+0.0 ₪ לשנייה', which reads as broken while S07 pours the income into taps. Bibi-only by construction: S07 is in leaderSelect.bibiOnly.upgrades (leader-select-spec §8), so no leader form is needed")
e("HUD_THUMBS","הבסיס: ⟦{thumbs}⟧ · ⟦×{pmult}⟧", "dos.row", note="Not in the persistent HUD; shown in T4")
e("EVOLVE_BTN", "עוד סבב", "unused", note="The not-ready Evolve button no longer exists; the seats bar carries progress")
e("EVOLVE_BTN_READY", "עוד סבב!", "cta.election", "*", "hud.cta.election")
e("EVOLVE_BTN_PROGRESS", "{pending}/{needed}", "unused", note="Seats progress is HUD_SEATS_VALUE")
e("EVOLVE_BTN_GAIN", "+{pending}", "unused", note="The election card uses EVO_THUMBS_GAIN")
e("EVOLVE_BADGE", "!", "tab.badge")
e("FLOATER", "⟦+{n}⟧~₪", "stage.floater", "", "first-minute §2.2 '+1 ₪'")
e("FLOATER_CRIT", "⟦+{n}!⟧~₪", "stage.floater")
e("BUFF_CHIP_FRENZY", "הכנסה ⟦×{mult}⟧ · ⟦{s}⟧ שנ׳", "stage.buffChip")
e("BUFF_CHIP_TAPFRENZY", "שליפה ⟦×{mult}⟧ · ⟦{s}⟧ שנ׳", "stage.buffChip", note="Pre-picker (Bibi) form. When the picker ships the view draws BUFF_CHIP_TAPFRENZY_LEADER for every leader, Bibi included (his kit verb is שליפה)")
e("BANNER_BUNCH", "מזוודה! ⟦+{n}⟧~₪", "stage.banner", "*")
e("BANNER_FRENZY", "טורבו בכובע! ⟦×{mult}⟧", "stage.banner", "*", note="Pre-picker (Bibi) form; BANNER_FRENZY_LEADER replaces it when the picker ships (Bibi's kit frenzyBanner is the same text)")
e("BANNER_TAPFRENZY", "ידיים של קוסם! ⟦×{mult}⟧", "stage.banner", "*", note="Shared by every leader: an idiom, not Bibi's name (Bar 2026-09-29)")
e("CALLOUT_GOLDEN", "תפוס אותה!", "stage.toast", note="Not used by the od-sevev FTUE (S1 is textless)")
e("TICKER_TAG", "מבזק", "ticker.tag", "", "hud.ticker.tag")
e("TICKER_IDLE", "מהדורה מיוחדת", "ticker.idle", "", "hud.ticker.idle", "D19 (mobile-first §5.2.2): the strip's standing line between headlines, in ui_mute; never an empty strip. A channel's lower third on an election night")
e("TAB_PRODUCERS", "מקורות", "tab.label", "*", "tab.sources")
e("TAB_UPGRADES", "ספינים", "tab.label", "", "tab.spins")
e("TAB_BADGE", "{count}", "tab.badge")
e("BUYMODE_1", "קנייה ⟦×1⟧", "list.buyBtn")
e("BUYMODE_10", "קנייה ⟦×10⟧", "list.buyBtn")
e("BUYMODE_MAX", "מקסימום", "list.buyBtn")
e("ROW_BUY", "לקנות", "card.pill")
e("ROW_BUY_N", "עוד ⟦{qty}⟧", "card.pill", "*", note="Pill line 1 in buy-mode ×10 / max; echoes עוד אחד")
e("ROW_NEED", "חסר", "card.pill")
e("ROW_COST", "⟦{cost}⟧~₪", "card.pill")
e("ROW_OWNED", "×{owned}", "card.owned")
e("ROW_OWNED_BPS", "⟦+{rate}⟧~₪ לשנייה", "card.line2", "", "card.yield", "The owned count is its own node (CARD_OWNED)")
e("ROW_OWNED_NEXT", "{owned}/{next}", "unused", note="Superseded by CARD_MS_NEXT / CARD_MS_SHORT (the card's milestone label, Bar 2026-10-02)")
e("ROW_LOCKED_NAME", "מקור עלום", "card.name", "*", "card.locked.name")
e("ROW_TEASER_HINT", "עוד מקורות ייפתחו", "card.name", "", "card.teaser.hint", "B9 (mobile-first §5.4): the name line of the first teaser row only (ui_panel on the pale slip); the teasers under it are wordless slips fading down")
e("UPG_EMPTY_1", "אין ספינים כרגע.", "list.empty")
e("UPG_EMPTY_2", "דובי עוד מתאמן על המסר.", "list.empty", "*")
e("SET_TITLE", "הגדרות", "sheet.title", "", "set.title")
e("SET_GROUP_SOUND", "סאונד", "sheet.group", "", "set.g.sound")
e("SET_SFX", "צלילים", "sheet.label", "", "set.sfx")
e("SET_MUSIC", "מוזיקה", "sheet.label", "", "set.music")
e("SET_GROUP_A11Y", "נוחות", "sheet.group", "", "set.g.comfort")
e("SET_REDUCED_MOTION", "תנועה מופחתת", "sheet.label", "", "set.motion")
e("SET_GROUP_GAME", "המשחק", "sheet.group", "", "set.g.game")
e("SET_FULLSCREEN", "מסך מלא", "unused", note="Not in the od-sevev settings (first-minute §7.2)")
e("SET_RESET", "איפוס התקדמות", "sheet.label", "", "set.reset")
e("SET_RESET_BTN", "איפוס", "unused", note="The whole danger row is the button")
e("SET_ON", "פועל", "sheet.state", "", "set.on")
e("SET_OFF", "כבוי", "sheet.state", "", "set.off")
e("SET_KEYS", "רווח: הקשה · S: מזוודה · ⟦1-4⟧: לשוניות · ESC: חזרה", "sheet.note", "", "first-minute §7.4; leader-select-spec §10.3", "Desktop only. Neutral: the tap verb differs per leader")
e("SET_VERSION", "עוד סבב · גרסה ⟦{version}⟧", "sheet.note")
e("RST_TITLE", "בטוח?", "modal.title", "", "reset.title")
e("RST_BODY_1", "זה כמו פיזור הכנסת, רק בלי בחירות חוזרות.", "modal.body", "*", "reset.joke")
e("RST_BODY_2", "כל ההתקדמות תימחק לתמיד: כסף, סבבי בחירות, תיקים ואלבום.", "modal.body", "", "reset.body")
e("RST_BODY_3", "", "unused", note="Intentionally empty: Labels wrap RST_BODY_2")
e("RST_NOTE", "ההגדרות נשארות.", "modal.body")
e("RST_CANCEL", "התחרטתי", "modal.btnHalf", "*", "reset.cancel")
e("RST_CONFIRM", "למחוק הכול", "modal.btnHalf", "", "reset.go")
e("EVO_TITLE", "בחירות מוקדמות", "modal.title", note="Param-free legacy title; the election card uses ELECT_TITLE")
e("EVO_NEXT", "הסבב הבא", "modal.body")
e("EVO_THUMBS_GAIN", "⟦+{pending}⟧ לבסיס", "modal.body")
e("EVO_THUMBS_PROGRESS", "⟦{pending}/{needed}⟧ לבסיס", "modal.body")
e("EVO_BONUS", "בונוס בחירות", "modal.body")
e("EVO_BONUS_PREVIEW", "הבונוס יתגלה ברוב", "modal.body")
e("EVO_MULT", "⟦×{now}⟧ ← ⟦×{after}⟧", "modal.body", note="Arrow is mirror-glyph: ← points to the new value")
e("EVO_RESETS", "מתאפס", "modal.body")
e("EVO_KEEPS", "נשאר", "modal.body")
e("EVO_R1", "הכסף", "modal.body")
e("EVO_R2", "המקורות", "modal.body")
e("EVO_R3", "הספינים", "modal.body")
e("EVO_R4", "הקואליציה", "modal.body")
e("EVO_K1", "הבסיס הנאמן", "modal.body")
e("EVO_K2", "סה״כ מכל הסבבים", "modal.body")
e("EVO_K3", "התיקים", "modal.body")
e("EVO_K4", "ההגדרות", "modal.body")
e("EVO_NEED", "צריך רוב כדי לפזר את הכנסת.", "modal.body")
e("EVO_RULE_1", "הבסיס הנאמן נשאר אחרי הבחירות,", "modal.body")
e("EVO_RULE_2", "וגדל עם כל שקל שנכנס בסבב הבחירות.", "modal.body", "", "leader-select-spec §10.3")
e("EVO_GROW", "הבחירות עוברות. הבסיס נשאר.", "modal.body", "*")
e("EVO_BACK", "עוד לא", "modal.btnFull", "", "elect.cancel")
e("EVO_CONFIRM", "לפזר את הכנסת", "modal.btnFull", "", "elect.go")
e("EVO_NOT_READY", "אין עדיין רוב", "modal.btnFull")
e("EVOTX_LINE", "הכנסת פוזרה. מתחילים:", "tx.line", "*")
e("OFF_TITLE", "בזמן שלא היית", "modal.title", "", "ret title 15 min-8 h")
e("OFF_AWAY", "לא היית פה {dur}.", "modal.body")
e("OFF_AWAY_CAPPED", "לא היית פה יותר מ־⟦8⟧ שעות.", "modal.body")
e("OFF_HARVESTED", "בינתיים נכנס לקופה:", "modal.body")
e("OFF_AMOUNT", "⟦+{n}⟧~₪", "modal.big", "", "ret.gain")
e("OFF_NOTE_1", "כשאתה לא פה, הקופה מתמלאת בחצי קצב,", "modal.body", "", "leader-select-spec §10.3")
e("OFF_NOTE_2", "ורק עד ⟦8⟧ שעות.", "modal.body")
e("OFF_COLLECT", "לאסוף", "modal.btnFull", "", "ret.btn")
e("ROTATE", "תחזיק את הטלפון לאורך.", "modal.title", "", "sys.rotate")
e("F1_TAP", "מבזק: ראש הרשימה נכנס ללשכה. הקופה פתוחה.", "ticker.crawl", note="Text fallback only; the od-sevev P0 prompt is textless (ux/ftue.md). Neutral (leader-select-spec §10.3)")
e("F1_TAP_IDLE", "הקופה עדיין מחכה. יש לה סבלנות. יש לה גם שקלים.", "ticker.crawl", "*", note="Text fallback only. Neutral (leader-select-spec §10.3)")
e("F2_HIRE", "לקנות! לקנות!", "ticker.crawl", "*G", "dubi.buy")
e("F2_HIRE_NUDGE", "משלם המסים מחכה בכרטיס. הוא כבר נאנח.", "ticker.crawl", "*", note="Text fallback only")
e("F3_UPGRADE", "נפתחו ספינים. דובי כבר חוזר עליהם.", "stage.toast", "*", "toast.spins")
e("F4_GOLDEN", "מזוודה באוויר! מקור: לא ידוע.", "ticker.crawl", "*", note="Text fallback only; S1 is textless")
e("F4_MISSED", "המזוודה הגיעה ליעדה. לא ידענו.", "ticker.crawl", "*G", "H-miss (copy deck §G)")
e("F5_EVOLVE_SEEN", "יש מד מנדטים. המטרה: רוב.", "ticker.crawl", note="Text fallback only; C2 is textless")
e("F6_EVOLVE_READY", "יש רוב. אפשר לפזר את הכנסת.", "ticker.crawl")
e("F7_RUN2", "סבב חדש! כל שקל שווה עכשיו ⟦×{pmult}⟧.", "ticker.crawl")
e("F7_RUN2_GATE", "הבסיס נשאר. הקואליציה מתחילה מאפס.", "ticker.crawl", "*")
e("F8_BULK", "אפשר לקנות בכמויות. הכפתור בראש רשימת המקורות.", "ticker.crawl")
e("SARA_ARRIVE", "שרה על הבמה. לגעת בה, לא בו.", "stage.toast", note="Bar 2026-10-02: Sara walks in; the tap is hers until she is tapped (SaraMark)")
e("SARA_BLOCK", "לא בו. קודם לגעת בשרה.", "stage.toast", note="A tap on the leader while Sara waits: swallowed (main._on_sara_block)")
e("SARA_DONE", "שרה מרוצה", "stage.floater", note="The floater when Sara is tapped and walks off")
e("F_NO_SAVE", "שים לב: הדפדפן הזה לא שומר. ההתקדמות תיעלם כשתצא.", "stage.toast")
e("F_SAVE_CORRUPT", "השמירה הישנה לא נקראה. מתחילים סבב חדש.", "stage.toast")
e("F_UPGRADE_FLAVOR", "{UPGRADE_NAME}: {FLAVOR}", "ticker.crawl")
e("PERKS_TITLE", "ההסכם הקואליציוני", "sheet.title", "", "rtl-map §7.3")
e("PERKS_HAVE", "בסיס פנוי לחתימות: ⟦{n}⟧", "sheet.note")
e("PERKS_NOTE", "חתימה על סעיף לא מקטינה את הבונוס.", "sheet.note")
e("PERK_LEVEL", "{lv}/{max}", "perk.level")
e("PERK_MAX", "סופי", "card.pill")
e("PERK_MAXED", "נחתם. באמת.", "card.line2", "*")
e("PARTNER_UPKEEP", "דמי אחזקה מההכנסה", "partner.label", "", "partner card upkeep row (rtl-map §6.3)", "Label; the value '−{upkeepPct}%' is drawn at the card's left (the share of ₪/s the partner costs)")
e("BOOK_TITLE", "תיקים", "tall.title", "*", "tab.dossier")
e("BOOK_TROPHIES", "תיק הישגים", "dos.row", "*")
e("BOOK_STATS", "נתונים", "dos.row")
e("BOOK_STORY", "ארכיון מבזקים", "dos.btn")
e("TROPHY_SUMMARY", "⟦{n}⟧ מתוך ⟦{total}⟧ · ⟦+{pct}%⟧ להכנסה", "dos.row")
e("TROPHY_SECRET", "תיק חסוי", "dos.row", "*")
e("TROPHY_LOCKED", "עוד לא נפתח", "dos.row")
e("TROPHY_DONE", "נפתח", "dos.row", "*")
e("ST_PLAYTIME", "זמן במשחק", "dos.row")
e("ST_ALLTIME", "סה״כ נכנס לקופה", "dos.row", "", "leader-select-spec §10.3")
e("ST_TAPS", "הקשות", "dos.row", "", "leader-select-spec §10.3", "Lifetime taps across every leader, so the neutral word; a leader's own row uses kit.tap.verbPlural (DOS_LEADER_TAPS)")
e("ST_CRITS", "הברקות", "dos.row", "*", "leader-select-spec §10.3", "Lifetime crits across every leader (rabbits, flips, threats...); a leader's own row uses kit.tap.critPlural")
e("ST_GOLDENS", "מזוודות שנתפסו", "dos.row")
e("ST_MISSED", "מזוודות שהגיעו ליעדן", "dos.row", "*")
e("ST_EVOLUTIONS", "סבבי בחירות", "dos.row")
e("ST_FASTEST", "הסבב הכי מהיר", "dos.row")
e("ST_BESTBPS", "שיא לשנייה", "dos.row")
e("ST_THUMBS", "בסיס שנצבר", "dos.row")
e("ST_SPENT", "בסיס שנחתם בהסכם", "dos.row")
e("ST_SPECIES", "תחנות בדרך", "dos.row")
e("ST_NONE", "-", "dos.row")
e("F_TROPHY", "גביע חדש: {NAME}.", "stage.toast", "*")
e("F_MILESTONE", "{NAME} · ⟦{n}⟧ בבעלותך: הכנסה ⟦×2⟧!", "ticker.crawl")
e("F_ALL_MILESTONE", "כל המקורות ב־⟦{n}⟧: כל ההכנסה עולה.", "ticker.crawl")
e("F_PERKS_HINT", "הבסיס מחכה לחתימות. ההסכם נעוץ בראש הקבוצה.", "stage.toast", "", "coalition UX rev 5", "A toast once (state.ui.perksHinted); a tap on it opens the agreement")
e("F_PERK_BOUGHT", "נחתם סעיף: {NAME}. הפעם מקיימים.", "stage.toast", "*")
e("SET_NOTATION", "מספרים", "unused", note="Not in the od-sevev settings")
e("SET_NOTATION_LETTERS", "1.5M", "unused")
e("SET_NOTATION_SCIENTIFIC", "1.5E6", "unused")
e("SET_NOTATION_ENGINEERING", "1.5E6 ENG", "unused")
e("SET_HAPTICS", "רטט", "sheet.label", "", "set.vibe")
e("SET_SAVE_CODE", "קוד שמירה", "unused", note="Not in the od-sevev settings")
e("SET_EXPORT", "העתקה", "unused")
e("SET_IMPORT", "הדבקה", "unused")
e("F_EXPORTED", "קוד השמירה הועתק. כדאי לשמור אותו במקום בטוח.", "unused")
e("F_IMPORT_BAD", "הקוד לא עבד. שום דבר לא השתנה.", "unused")
e("F_IMPORTED", "הקוד נטען. ברוך שובך.", "unused")
e("IMP_TITLE", "לטעון קוד שמירה?", "unused")
e("IMP_BODY_1", "המשחק הנוכחי יוחלף", "unused")
e("IMP_BODY_2", "במשחק שבקוד.", "unused")
e("IMP_BODY_3", "", "unused")
e("IMP_CONFIRM", "לטעון", "unused")
e("IMP_PROMPT", "הדביקו כאן את קוד השמירה (HK1:…)", "html:40", "", "main.gd import_save window.prompt", "System prompt text; reachable only if the save-code row returns (not in the od-sevev settings)")
e("OFF_AWAY_CAPPED_H", "לא היית פה יותר מ־⟦{h}⟧ שעות.", "modal.body")
e("OFF_NOTE_1_PCT", "כשאתה לא פה, הקופה מתמלאת ב־⟦{pct}%⟧ מהקצב,", "modal.body", "", "leader-select-spec §10.3")
e("OFF_NOTE_2_H", "ורק עד ⟦{h}⟧ שעות.", "modal.body")
e("OFF_CAP_TIP", "סעיפים בהסכם הקואליציוני מאריכים את המגבלה.", "modal.body", note="Param-free (main.gd passes no params)")
e("CLOSE", "סגור", "modal.btnFull", "", "sys.close")
e("STORY_CONTINUE", "להמשיך", "modal.btnFull")
e("STORY_TITLE", "{name}, {title}", "modal.body", note="Byline under the flash title")
e("STORY_EVOLUTION", "סבב ⟦{n}⟧: {era}", "modal.body")
e("STORY_EMPTY_1", "הארכיון ריק.", "list.empty")
e("STORY_EMPTY_2", "דובי מדווח אחרי כל סבב בחירות.", "list.empty")
e("F_ERA", "תחנה חדשה: {era}.", "ticker.crawl")

# ================= new keys (first-minute §8 IDs -> UPPER_SNAKE) =================
# --- HTML: loading, disclaimer
e("LOAD_1", "מקפל מזוודות…", "html:18", "*", "load.1")
e("LOAD_2", "מחמם את הקלפי…", "html:18", "*", "load.2; leader-select-spec §10.3", "Singular like LOAD_1 / LOAD_3")
e("LOAD_3", "מתייעץ ביטחונית…", "html:18", "*", "load.3")
e("LOAD_PREP", "סופר את הקולות…", "html:18", "*", "load.prep", "Shell load bar, every byte in, the engine still starting (wasm compile, pck mount, boot): replaces the rotating LOAD_1..3 until hand-off. Singular like LOAD_1..3")
e("LOAD_BAR_LABEL", "טוען את המשחק", "html:14", "", "load.bar.label")
e("DISC_TITLE", "רגע לפני הסבב", "html:16", "", "disc.title")
e("DISC_L1", "זו סאטירה. הדמויות הן קריקטורות פיקסל, ומה שהן עושות כאן בדיוני.", "html:80", "L", "disc.l1")
e("DISC_L2", "אין כאן טענה עובדתית על אף אחד. ציטוטים אמיתיים מסומנים כציטוט, עם מקור.", "html:80", "L", "disc.l2")
e("DISC_L3", "המשחק לא קשור לאף מפלגה או מועמד, ולא ממומן על ידי אף מפלגה, מועמד או מזוודה.", "html:85", "L*", "disc.l3")
e("DISC_L4", "ואין כאן המלצה להצביע לאף אחד.", "html:40", "L", "disc.l4")
e("DISC_BY", "מאת {publisher} · {mail} · אודות", "html:50", "L", "disc.by")
e("DISC_BTN_SOUND", "עם סאונד", "html:10", "", "disc.btn.sound")
e("DISC_BTN_QUIET", "בשקט", "html:8", "", "disc.btn.quiet")
e("DISC_BTN_QUIET_CAP", "אני בישיבה", "html:12", "*", "disc.btn.quiet.cap")
e("SPLASH_LOADING", "רגע, מסדרים את הרשימה…", "html:24", "*", "N0 splash loading line; leader-select-spec §10.3", "One line under the wordmark (system font 16, 358 CSS wide): 24 chars fit")
# --- title / rounds / moods
e("TITLE_ROUND", "סבב בחירות מס׳ ⟦{n}⟧", "modal.title", "", "title.round line 1")
e("MOOD_1", "הציבור נרגש", "modal.body", "*", "mood.1")
e("MOOD_3", "הציבור נרגש. בערך.", "modal.body", "*", "mood.3")
e("MOOD_5", "הציבור נרגש. שמישהו יבדוק אותו.", "modal.body", "*", "mood.5")
e("MOOD_6", "הציבור נרגש. הוא אמר שהוא בסדר.", "modal.body", "*", "mood.6")
e("MOOD_10", "הקלפי ביקשה חופשה.", "modal.body", "*G", "mood.10")
e("MOOD_20", "מישהו בדק שהציבור בסדר?", "modal.body", "*G", "mood.20")
# --- HUD
e("HUD_BANK", "⟦{n}⟧~₪", "rowA.counter", "", "first-minute §3.2 #1")
e("HUD_COUNTDOWN_DATE", "27.10", "ticker.chip", "", "hud.countdown (date line)")
e("HUD_COUNTDOWN_ONE", "עוד יום אחד", "title.line", "*", "hud.countdown one", "Title-state line only; the ticker chip shows the date (flag F2)")
e("HUD_COUNTDOWN_TWO", "עוד יומיים", "title.line", "*", "hud.countdown two")
e("HUD_COUNTDOWN_OTHER", "עוד ⟦{d}⟧ ימים", "title.line", "*", "hud.countdown other")
e("HUD_COUNTDOWN_TODAY", "היום", "ticker.chip", "", "hud.countdown.today", "Replaces the date in the chip on 27.10")
e("HUD_COUNTDOWN_AFTER_TAG", "משא ומתן", "html:12", "", "hud.countdown.after (a11y)", "Accessible name of the chip after 27.10")
e("HUD_COUNTDOWN_AFTER", "יום ⟦{n}⟧", "ticker.chip", "", "hud.countdown.after", "The chip after 27.10 (handshake icon); the ticker carries the negotiation line")
e("HUD_SEATS", "מנדטים", "rowB.label", "", "hud.seats")
e("HUD_SEATS_VALUE", "{seats}/61", "rowB.value", "", "first-minute §3.2 #2")
e("HUD_SEATS_BLACKOUT", "חסוי עד ⟦27.10⟧", "rowB.stamp", "L", "hud.seats.blackout")
e("HUD_SUSP", "חשד", "stage.thermo", "", "hud.susp", "Court skin (Bibi). Every other leader: PRESS_SUSP / _HOT / _BOIL")
e("HUD_SUSP_HOT", "מבעבע", "stage.thermo", "", "hud.susp.hot")
e("HUD_SUSP_BOIL", "רותח!", "stage.thermo", "", "hud.susp.boil")
e("HUD_COTTAGE_TIP", "מדד הקוטג׳: הקופה שלך גדלה. הקוטג׳ קטן.", "stage.toast", "*", "hud.cottage.tip")
e("HUD_COTTAGE_MINUS", "−1", "rowA.cottageMinus", "", "motion cottage-pixel-loss", "The lost pixel's '−1' over the cup (U+2212, PxText). Confirmed by UX 2026-09-29: numerals only, no ₪ (the cup loses a pixel, not money)")
e("FLOATER_FLIGHT", "⟦+{pct}%⟧ להכנסה", "stage.floater", "", "S10 flightIncome floater", "S10: the round's running flight bonus, over the caught Suitcase (was the bare '+15%')")
e("HUD_CTA_ELECTION", "עוד סבב!", "cta.election", "*", "hud.cta.election")
e("HUD_MUTE", "השתקה", "html:12", "", "hud.mute", "Accessible label (not drawn)")
e("HUD_UNMUTE", "ביטול השתקה", "html:12", "", "hud.unmute", "Accessible label (not drawn)")
e("HUD_SETTINGS", "הגדרות", "html:7", "", "hud.settings", "Accessible label (not drawn)")
# --- Dubi squawks (words owned by the copy deck)
e("DUBI_FIRSTTAP", "אין כלום! אין כלום!", "stage.toast", "*G", "dubi.firsttap", "Bibi's squawk. Other leaders: kit.dubi.squawks.firsttap (content), at their first tap (ftue.md H1 / H1L)")
e("DUBI_BUY", "לקנות! לקנות!", "stage.toast", "*G", "dubi.buy")
e("DUBI_ELECT", "בחירות! בחירות!", "stage.toast", "*G", "dubi.elect")
e("DUBI_MISS", "לא ידענו! לא ידענו!", "stage.toast", "*G", "dubi.miss")
e("DUBI_DROP", "מי? מי?", "stage.toast", "*G", "dubi.drop", "Bibi-only (the aide drop)")
e("DUBI_ABILITY", "תתאחדו! תתאחדו!", "stage.toast", "*G", "dubi.ability", "Bibi's ability squawk (leaders v3). Other leaders: kit.dubi.squawks.ability, on an ability use, at most every 20 s")
# --- tabs, toasts
e("TAB_SOURCES", "מקורות", "tab.label", "*", "tab.sources")
e("TAB_SPINS", "ספינים", "tab.label", "", "tab.spins")
e("TAB_COALITION", "קואליציה", "tab.label", "", "tab.coalition")
e("TAB_DOSSIER", "תיקים", "tab.label", "*", "tab.dossier")
e("TOAST_SPINS", "נפתחו ספינים. דובי כבר חוזר עליהם.", "stage.toast", "*", "toast.spins")
e("TOAST_DOSSIER", "נפתח לך תיק.", "stage.toast", "*", "toast.dossier")
e("SYS_OFFLINE", "אין חיבור. הקופה עובדת גם בלי.", "stage.toast", "*", "sys.offline; leader-select-spec §10.3")
e("TOAST_SPIN_END", "הספין ״{NAME}״ ירד מהכותרות.", "stage.toast", "*", "a timed spin (S02, S07, S10, S12 ...) ends (new)", "The subject is הספין (m), so any spin name agrees")
e("TOAST_COURT_END", "העדות הסתיימה. הקצב חזר.", "stage.toast", "", "court day end (new)")
e("RESET_DONE", "נמחק. אין כלום.", "stage.toast", "*", "reset.done")
e("ALBUM_NEW", "נכנס לאלבום.", "stage.toast", "", "album.new")
# --- source cards
e("CARD_BUY_FIRST", "לקנות · ⟦{price}⟧~₪", "stage.toast", "", "card.buy.first", "Single-line form (a11y label, toasts); the pill uses VERB + PRICE on two lines")
e("CARD_BUY_MORE", "עוד אחד · ⟦{price}⟧~₪", "stage.toast", "*", "card.buy.more", "Single-line form")
e("CARD_VERB_FIRST", "לקנות", "card.pill", "", "card.buy.first (pill line 1)")
e("CARD_VERB_MORE", "עוד אחד", "card.pill", "*", "card.buy.more (pill line 1)")
e("CARD_PRICE", "⟦{price}⟧~₪", "card.pill", "", "pill line 2")
e("CARD_YIELD", "⟦+{n}⟧~₪ לשנייה", "card.line2", "", "card.yield")
e("CARD_OWNED", "×{n}", "card.owned", "", "card.owned")
e("CARD_MS_NEXT", "⟦{owned}/{next}⟧ ← ⟦×{mult}⟧", "card.ms", "", "new: source milestone", "Bar 2026-10-02: owned / the next content milestones.perProducer count, then that milestone's own factor; the arrow points the reading direction. Gold on the card's name row over the progress bar's goal end")
e("CARD_MS_SHORT", "⟦{owned}/{next}⟧", "card.ms", "", "new: source milestone", "CARD_MS_NEXT's fallback where the full form would come within 16 px of a long name")
e("CARD_MS_MULT", "×{mult}", "card.msTag", "", "new: source milestone", "The source's milestone multiplier so far (shown when > 1), a gold chip after its rate")
e("SHOP_ALL_MS", "כולם ב־⟦{n}⟧ ← ⟦×{gmult}⟧", "card.line2wide", "", "new: all-sources milestone", "Line 2 of the buy-mode row (the list's head): every source at {n} multiplies all income by {gmult} (content milestones.allProducers); one bar segment per source under it")
e("CARD_SHADY_TAG", "מעלה חשד", "html:12", "", "new", "Accessible label of the magnifier badge on shady cards; the badge shape is the non-colour channel")
e("CARD_LOCKED_CAP", "יתגלה כשיהיה מספיק", "card.line2wide", "", "card.locked.cap")
e("BUYMODE_LABEL", "כמות בכל קנייה", "list.buyLabel", "", "rtl-map §6.1")
# --- spins
e("SPIN_VERB", "להפיץ", "card.pill", "", "spin.buy (pill line 1)")
e("SPIN_BUY", "להפיץ · ⟦{price}⟧~₪", "stage.toast", "", "spin.buy", "Single-line form")
e("SPIN_FATIGUE", "שחוק", "card.pill", "*", "spin.fatigue")
e("SPIN_FATIGUE_CAP", "כבר שמעו את זה", "card.line2", "*", "spin.fatigue.cap")
e("SPIN_ACTIVE", "פעיל · עוד ⟦{s}⟧ שנ׳", "card.line2wide", "", "new: timed spin")
e("SPIN_OWNED", "הופץ", "card.pill", "", "new: one-time spin bought")
e("SPIN_BARS_LINE", "ערוץ ידידותי: ⟦{pct}%⟧", "card.line2", "*", "S08 card line 2 at level >= 1", "Replaces the effect label once S08 has a level; {pct} = bars.friendly. The split bar under it keeps both parts (public from the right)")
e("SPIN_BAR_PUBLIC", "שידור ציבורי", "html:14", "", "S08 bar a11y", "Accessible name of the bar's public part (not drawn)")
e("SPIN_BAR_FRIENDLY", "ערוץ ידידותי", "html:14", "", "S08 bar a11y", "Accessible name of the bar's friendly part (not drawn)")
# --- coalition chat
e("CHAT_TITLE", "קואליציה ⟦61⟧", "tall.title", "", "chat.title")
e("CHAT_MEMBERS_ONE", "משתתף אחד", "tall.status", "", "chat.members")
e("CHAT_MEMBERS_OTHER", "⟦{n}⟧ משתתפים", "tall.status", "", "chat.members")
e("CHAT_TYPING_M", "{name} מקליד…", "tall.status", "*", "chat.typing")
e("CHAT_TYPING_F", "{name} מקלידה…", "tall.status", "*", "chat.typing")
e("CHAT_THREATS_ONE", "איום פרישה פתוח", "tall.status", "*", "chat.threats")
e("CHAT_THREATS_TWO", "שני איומי פרישה פתוחים", "tall.status", "*", "chat.threats")
e("CHAT_THREATS_OTHER", "⟦{k}⟧ איומי פרישה פתוחים", "tall.status", "*", "chat.threats")
e("CHAT_PINNED", "ההסכם הקואליציוני · טיוטה ⟦{n}⟧", "chat.pinned", "*", "chat.pinned", "The pin icon says נעוץ (x4 capacity)")
e("CHAT_TODAY", "היום", "chat.divider", "", "chat.today")
e("CHAT_UNREAD_ONE", "הודעה אחת שלא נקראה", "chat.divider", "", "chat.unread")
e("CHAT_UNREAD_OTHER", "⟦{n}⟧ הודעות שלא נקראו", "chat.divider", "", "chat.unread")
e("CHAT_PAY", "לשלם ⟦{price}⟧~₪", "chat.pill", "*", "chat.pay")
e("CHAT_PAY_SHORT", "חסר ⟦{n}⟧~₪", "chat.pill", "", "chat.pay.short")
e("CHAT_CEREMONY", "לגזור סרט ✂", "chat.pill", "*", "ceremony demand pill (Regev)", "A ceremony costs 0 ₪, so the money pill read 'סגרנו · 0 ₪'. Tap starts the 3 s ribbon fill")
e("CHAT_CEREMONY_CUTTING", "גוזרים…", "chat.pill", "*", "ceremony pill while the ribbon fills")
e("TOAST_CHAT_HEAD", "{name} · בקבוצה", "stage.toastHead", "", "C1 chat toast line 1 (ftue.md C1: avatar, name, preview)", "Line 1 of a chat toast; line 2 is the message preview, one line, ellipsised")
e("CHAT_PAID", "שולם", "chat.label", "", "chat.paid")
e("CHAT_REPLY_1", "העברתי.", "chat.bubble", "*", "chat.reply.1")
e("CHAT_REPLY_2", "סגור.", "chat.bubble", "*", "chat.reply.2")
e("CHAT_REPLY_3", "בוצע. תמחקו אחרי קריאה.", "chat.bubble", "*", "chat.reply.3", "The player's own reply: 'אין כלום' is Bibi's catchphrase and read wrong in any other leader's mouth")
e("CHAT_ULTIMATUM", "אולטימטום", "chat.label", "", "chat.ultimatum")
e("CHAT_ULT_TIMER", "{mmss}", "chat.timer", "", "first-minute §4.2")
e("CHAT_FORWARDED", "הועברה פעמים רבות", "chat.name", "*", "pitch §6 Ben Gvir")
e("CHAT_DELETED", "ההודעה נמחקה", "chat.bubble", "*", "chat.deleted")
e("CHAT_SYS_CREATED", "יצרת את הקבוצה ״קואליציה ⟦61⟧״", "chat.sys", "", "chat.sys.created; leader-select-spec §10.3", "Second person, as a chat app tells the group's creator: the player IS this round's leader. Needs no {name} (works in the Bibi-only build and after the picker) and no gender form (יצרת is spelled the same for m/f)")
e("CHAT_SYS_JOINED_M", "{name} הצטרף לקבוצה", "chat.sys", "", "chat.sys.joined")
e("CHAT_SYS_JOINED_F", "{name} הצטרפה לקבוצה", "chat.sys", "", "chat.sys.joined")
e("CHAT_SYS_LEFT_M", "{name} עזב את הקבוצה", "chat.sys", "", "chat.sys.left")
e("CHAT_SYS_LEFT_F", "{name} עזבה את הקבוצה", "chat.sys", "", "chat.sys.left")
e("CHAT_SYS_REMOVED_M", "{name} הוסר על ידי מנהל", "chat.sys", "*", "chat.sys.removed")
e("CHAT_SYS_REMOVED_F", "{name} הוסרה על ידי מנהל", "chat.sys", "*", "chat.sys.removed")
e("CHAT_SYS_ADDED_M", "{name} צורף על ידי מנהל", "chat.sys", "", "chat.sys.added")
e("CHAT_SYS_ADDED_F", "{name} צורפה על ידי מנהל", "chat.sys", "", "chat.sys.added")
e("CHAT_SYS_TRANSFER_M", "{name} עזב · צורף ל״{to}״", "chat.sys", "", "chat.sys.transfer")
e("CHAT_SYS_TRANSFER_F", "{name} עזבה · צורפה ל״{to}״", "chat.sys", "", "chat.sys.transfer")
e("CHAT_SYS_REJOIN", "להחזיר לקבוצה · ⟦{price}⟧~₪", "chat.pillWide", "", "chat.sys.rejoin")
e("CHAT_SYS_POACH", "לצרף לקבוצה · ⟦{price}⟧~₪", "chat.pillWide", "*", "pill on chat.sys.removed when payable = poach (Almog)")
e("CHAT_SYS_BRAWL", "{a} ו{b} רבים. שתי השורות הוקפאו.", "chat.sys", "", "chat.sys.brawl")
e("CHAT_BRAWL_BANNER", "קטטה בקבוצה", "chat.banner", "G", "copy deck §E brawl banner")
e("CHAT_BRAWL_BTN", "צאו החוצה", "chat.btn", "*", "chat.brawl.btn")
e("CHAT_BRAWL_AFTER", "נוצרה קבוצה חדשה: ״המסדרון״ · ⟦2⟧ משתתפים", "chat.sys", "*G", "chat.brawl.after (deck wording)")
e("CHAT_CORRIDOR_COUNT", "⟦{n}⟧ הודעות", "chat.label", "*", "chat.brawl.after muted counter")
e("CHAT_SYS_MUTED", "{who} ביקשו רשות דיבור · נדחה", "chat.sys", "", "chat.sys.muted", "{who} = partners[distel].copy.mutedWho (\"היועצים המשפטיים\"), never Distel's name")
e("CHAT_SYS_CLEARED", "ניקית את הצ׳אט. לקראת סבב בחירות ⟦{n}⟧.", "chat.sys", "*", "chat.sys.cleared; leader-select-spec §10.3", "Second person (see CHAT_SYS_CREATED); ניקית is spelled the same for m/f")
e("CHAT_EMPTY", "שקט בקבוצה. זה לא יחזיק.", "chat.sys", "*", "chat.empty")
e("CHAT_COMPOSER", "פה מדברים רק בשקלים", "chat.composer", "*", "chat.composer")
e("CHAT_TRANSFER_TITLE", "חלון העברות", "chat.banner", "", "chat.transfer.title")
e("CHAT_TRANSFER_LINE", "{from} ← {to} · כולל דמי אחזקה", "chat.banner", "", "chat.transfer.line")
e("CHAT_PENDING_ONE", "ממתין אחד", "chat.pending", "", "views dev 2026-09-29: an open pill or brawl above the thread's viewport", "Tap = scroll to the nearest one above; the ↑ is a pixel icon (the font has no U+2191)")
e("CHAT_PENDING_OTHER", "⟦{n}⟧ ממתינים", "chat.pending", "", "views dev 2026-09-29")
e("CHAT_PINNED_OPEN", "לפתוח את ההסכם", "html:16", "", "rtl-map §7.3", "Accessible label (not drawn)")
e("CHAT_COLLAPSE", "לסגור את הקבוצה", "html:16", "", "rtl-map §6.3", "Accessible label of the chevron (not drawn)")
# coalition UX (Bar 2026-10-02, "improve the coalition tasks"): what each open line is worth, its clock,
# when the bank covers it, one press for every line, the brawl's frozen seats (ux/rtl-map.md §6.3 rev 5)
e("CHAT_OPEN_ONE", "דרישה אחת פתוחה", "tall.status", "", "rtl-map §6.3 rev 5: header status", "While payable lines are open and no ultimatum or brawl is: demands, join / rejoin / poach pills")
e("CHAT_OPEN_TWO", "שתי דרישות פתוחות", "tall.status", "", "rtl-map §6.3 rev 5")
e("CHAT_OPEN_OTHER", "⟦{n}⟧ דרישות פתוחות", "tall.status", "", "rtl-map §6.3 rev 5")
e("CHAT_FROZEN_ONE", "קטטה · מנדט אחד מוקפא", "tall.status", "", "rtl-map §6.3 rev 5: header status while a brawl is open", "The seats the brawl keeps out of the 61 (the '44/61 stall', STATUS 2026-09-29)")
e("CHAT_FROZEN_OTHER", "קטטה · ⟦{n}⟧ מנדטים מוקפאים", "tall.status", "", "rtl-map §6.3 rev 5")
e("CHAT_FROZEN_X", "קטטה · שתי שורות מוקפאות", "tall.status", "", "rtl-map §6.3 rev 5", "The blackout form: no seat numeral (Calendar.seats_numeral_hidden)")
e("CHAT_STAKE_JOIN_ONE", "⟦+1⟧ מנדט לקואליציה", "chat.name", "", "rtl-map §6.3 rev 5: stake line over a join / rejoin / poach pill", "Net seats on the HUD's bar (abstentions and a partner who walks out on the newcomer included); hidden in the blackout")
e("CHAT_STAKE_JOIN_OTHER", "⟦+{n}⟧ מנדטים לקואליציה", "chat.name", "", "rtl-map §6.3 rev 5")
e("CHAT_STAKE_WALK_ONE_M", "יפרוש עם מנדט אחד", "chat.name", "", "rtl-map §6.3 rev 5: stake line over an ultimatum's pill", "The seats that walk out with the partner when the timer runs out (net on the HUD's bar). Plural _ONE/_OTHER, then the partner's gender _M/_F")
e("CHAT_STAKE_WALK_ONE_F", "תפרוש עם מנדט אחד", "chat.name", "", "rtl-map §6.3 rev 5")
e("CHAT_STAKE_WALK_OTHER_M", "יפרוש עם ⟦{n}⟧ מנדטים", "chat.name", "", "rtl-map §6.3 rev 5")
e("CHAT_STAKE_WALK_OTHER_F", "תפרוש עם ⟦{n}⟧ מנדטים", "chat.name", "", "rtl-map §6.3 rev 5")
e("CHAT_STAKE_WALK_X_M", "בלי תשלום: פורש", "chat.name", "", "rtl-map §6.3 rev 5", "The blackout form (no seat numeral)")
e("CHAT_STAKE_WALK_X_F", "בלי תשלום: פורשת", "chat.name", "", "rtl-map §6.3 rev 5")
e("CHAT_STAKE_PATIENCE", "אולטימטום בעוד ⟦{mmss}⟧", "chat.name", "", "rtl-map §6.3 rev 5: a member demand's patience (coalition.patienceSec)", "Only when the demand can escalate (ultimatums unlocked, the partner can leave); a draining bar under it")
e("CHAT_STAKE_ONDECK", "הבא בתור לאולטימטום", "chat.name", "", "rtl-map §6.3 rev 5", "Patience ran out; it escalates as soon as the open ultimatum closes (ultimatum.maxOpen)")
e("CHAT_PAY_ETA", "נסגור בעוד ⟦{mmss}⟧", "chat.pill", "", "rtl-map §6.3 rev 5: an unaffordable pill", "When the bank covers the price at the current ₪/s within 15:00; else CHAT_PAY_SHORT")
e("CHAT_PAY_ALL", "לסגור עם כולם · ⟦{price}⟧~₪", "chat.composer", "*", "rtl-map §6.3 rev 5: the composer as one gold pill", "Two or more open lines the bank covers: one press pays them, most urgent first (ultimatums, seats, patience); never a ceremony. The composer only talks in shekels")
e("CHAT_PAY_SOME", "לסגור עם ⟦{n}⟧ · ⟦{price}⟧~₪", "chat.composer", "*", "rtl-map §6.3 rev 5", "The same pill when the bank covers only some of the open lines")
e("CHAT_BRAWL_FROZEN_ONE", "מנדט אחד מוקפא עד שייצאו", "chat.sys", "", "rtl-map §6.3 rev 5: under 'צאו החוצה'")
e("CHAT_BRAWL_FROZEN_OTHER", "⟦{n}⟧ מנדטים מוקפאים עד שייצאו", "chat.sys", "", "rtl-map §6.3 rev 5")
# --- aide drop (the button words are the copy deck's)
e("AIDE_HOLDS", "הכסף אצל יועץ", "card.line2wide", "", "copy deck §G", "State line on the aide's card")
e("AIDE_BTN", "אני לא מכיר אותו", "modal.btnFull", "*G", "copy deck §G", "Bibi-only (the aide drop): hidden on the press card")
e("AIDE_CONFIRM_TITLE", "לנתק מגע?", "modal.title", "", "new: confirm (pitch §11 Q4)")
e("AIDE_CONFIRM_BODY", "החשד יורד לרצפה של הסבב. הבסיס יורד ב־⟦3%⟧, לתמיד.", "modal.body", "", "new: honest cost")
e("AIDE_CONFIRM_GO", "לא מכיר אותו", "modal.btnFull", "*", "new")
e("AIDE_CONFIRM_CANCEL", "רגע, מכיר", "modal.btnFull", "*", "new")
# --- opposition cards, leaked chat
e("OPP_HEADER", "האופוזיציה", "modal.title", "", "new: card header")
e("OPP_TIMER", "{mmss}", "chat.timer")
e("OPP_ABBAS_RULE", "מופיע רק כשבן גביר לא מחובר", "modal.body", "*", "copy deck §F (UX chrome)")
e("OPP_LIBERMAN_BTN", "לא אשב", "modal.btnHalf", "*G", "copy deck §F")
e("LEAK_FRAME", "צילום מסך דלף", "modal.title", "*", "copy deck §E.2 (UX owns the frame)")
e("LEAK_OPEN", "להציץ", "modal.btnHalf", "*", "new: opens the leak")
e("LEAK_READONLY", "קריאה בלבד", "chat.label", "", "new")
# --- court day
e("COURT_TITLE", "יום משפט", "modal.title", "", "court.title")
e("COURT_BODY", "ביבי בדוכן העדים. ההכנסות מואטות.", "court.body", "", "court.body", "Bibi-only: the court skin is his (leader-select-spec §5.6); every other leader draws PRESS_BODY_M/_F")
e("COURT_EFFECT", "הכנסות ⟦×0.5⟧, בלי הקשות, עד סוף העדות", "court.body", "", "new: legible effect (pitch §10)")
e("COURT_TIMER", "עדות: ⟦{mmss}⟧", "court.body", "", "court.timer")
e("COURT_POSTPONE", "התייעצות ביטחונית · ⟦{price}⟧~₪", "html:40", "*", "court.postpone", "Accessible label; drawn as COURT_POSTPONE_VERB over CARD_PRICE")
e("COURT_POSTPONE_VERB", "לדחות", "court.btn", "*", "court.postpone line 1")
e("COURT_TESTIFY", "להעיד", "court.btn2", "", "court.testify")
e("COURT_CHIP", "יום משפט · ⟦{mmss}⟧", "html:20", "", "court.chip", "Accessible label; drawn as COURT_CHIP_TITLE over COURT_CHIP_TIMER in the ticker chip")
e("COURT_CHIP_TITLE", "יום משפט", "ticker.chip", "", "court.chip line 1")
e("COURT_CHIP_TIMER", "{mmss}", "ticker.chip", "", "court.chip line 2")
e("COURT_STAMP", "נדחה", "modal.title", "*", "court.stamp")
e("COURT_POSTPONED_PREFIX", "הדיון נדחה:", "court.body", "G", "copy deck §H prefix")
e("COURT_TAP_PAUSED", "ביבי בדוכן העדים. ההקשות מחכות לסוף העדות.", "stage.toast", "", "new 2026-10-01 (Bar): a tap on the court day, courtPausesTaps")
e("PRESS_TAP_PAUSED_M", "{short} מגיב לתחקיר. ההקשות מחכות לסוף התגובה.", "stage.toast", "", "COURT_TAP_PAUSED's press twin")
e("PRESS_TAP_PAUSED_F", "{short} מגיבה לתחקיר. ההקשות מחכות לסוף התגובה.", "stage.toast", "", "COURT_TAP_PAUSED's press twin")
e("COURT_SUMMONS_TITLE", "זימון לעדות", "modal.title", "", "court card title while phase == summons")
e("COURT_SUMMONS_BODY", "ביבי זומן לדוכן העדים. אפשר לדחות, אפשר להעיד.", "court.body", "*", "court card body while phase == summons", "COURT_BODY ('ביבי בדוכן העדים. ההכנסות מואטות.') is true only once testimony runs. Bibi-only; others draw PRESS_SUMMONS_BODY")
e("COURT_SUMMONS_EFFECT", "בזמן העדות: הכנסות ⟦×0.5⟧, בלי הקשות", "court.body", "", "court card effect line while phase == summons")
e("COURT_SUMMONS_TIMER", "העדות מתחילה בעוד ⟦{mmss}⟧", "court.body", "", "court card timer while phase == summons (the auto-testify countdown)")
e("COURT_CHIP_SUMMONS", "זימון", "ticker.chip", "", "court chip line 1 while phase == summons")
# --- pardon desk (the "stamp mini-game", launch as text)
e("PARDON_ROW", "בקשת חנינה", "dos.btn", "", "pitch §2 launch spine", "Bibi-only: the T4 row is hidden in every other leader's round (leader-select-spec §5.6)")
e("PARDON_TITLE", "בקשת חנינה", "modal.title")
e("PARDON_FORM", "טופס בקשה לחנינה · עותק ⟦{n}⟧", "modal.body", "*")
e("PARDON_SUBMIT", "להגיש בקשה", "modal.btnFull")
e("PARDON_AGAIN", "להגיש שוב", "modal.btnFull", "*")
e("PARDON_STAMPING", "מחתימים…", "modal.body", "*")
e("PARDON_STATUS", "סטטוס: בטיפול", "modal.body", "*")
e("PARDON_COUNT_ONE", "הוגשה בקשה אחת", "modal.body")
e("PARDON_COUNT_OTHER", "הוגשו ⟦{n}⟧ בקשות", "modal.body")
e("PARDON_NOTE", "זה אף פעם לא עובד. תמיד אפשר לנסות.", "modal.body", "*", "new: honest (no mechanical effect)")
# --- election card, flash, transition
e("ELECT_TITLE", "סבב בחירות מס׳ ⟦{n}⟧", "modal.title", "", "elect.title")
e("ELECT_RESET", "מתאפס: הכסף, המקורות, הספינים והקואליציה.", "modal.body", "", "elect.reset")
e("ELECT_KEEP", "נשאר לתמיד: הבסיס, ⟦{n}⟧.", "modal.body", "", "elect.keep", "{n} = the base after this election (one unit: בסיס is the permanent count; the multiplier is EVO_MULT)")
e("ELECT_KEEP_CASES", "וגם התיקים.", "modal.body", "*", "elect.keep.cases")
e("ELECT_GO", "לפזר את הכנסת", "modal.btnFull", "", "elect.go")
e("ELECT_CANCEL", "עוד לא", "modal.btnFull", "", "elect.cancel")
e("FLASH_NEXT", "לסבב הבחירות הבא", "modal.btnFull", "", "flash.next", "Full-width primary; FLASH_SKIP is the secondary under it")
e("FLASH_SKIP", "דלג", "modal.btnHalf", "", "flash.skip")
# --- headline card
e("HEADLINE_TITLE", "מבזק", "modal.title", "", "headline.title")
e("HEADLINE_QUOTE", "ציטוט", "chat.label", "L", "headline.quote")
e("HEADLINE_SOURCE", "מקור: {outlet}, ⟦{date}⟧", "modal.body", "L", "headline.source")
e("HEADLINE_LINK", "למקור", "modal.btnHalf", "", "headline.link")
# --- return card (O1)
e("RET_TITLE_SHORT", "חזרת מהר.", "modal.title", "*", "ret 1-15 min")
e("RET_BODY_SHORT", "משלמי המסים לא הספיקו להתגעגע.", "modal.body", "*", "ret 1-15 min")
e("RET_TITLE_MID", "בזמן שלא היית", "modal.title", "", "ret 15 min-8 h")
e("RET_BODY_MID", "משלמי המסים המשיכו לשלם.", "modal.body", "*", "ret 15 min-8 h (brief)")
e("RET_TITLE_LONG", "איפה היית?", "modal.title", "*", "ret 8-48 h")
e("RET_BODY_LONG", "בלשכה מסרו: התייעצות ביטחונית.", "modal.body", "*", "ret 8-48 h")
e("RET_TITLE_GONE_TWO", "נעלמת ליומיים.", "modal.title", "*", "ret > 48 h (n = 2)")
e("RET_TITLE_GONE_OTHER", "נעלמת ל־⟦{n}⟧ ימים.", "modal.title", "*", "ret > 48 h")
e("RET_BODY_GONE", "תרגיל ההעלמה הכי טוב שלך עד היום.", "modal.body", "*", "ret > 48 h")
e("RET_GAIN", "⟦+{x}⟧~₪", "modal.big", "", "ret.gain")
e("RET_RECAP", "{short} · ⟦{seats}/{gate}⟧ מנדטים", "modal.body", "", "ret.recap", "2026-10-03: where the round stands on a return (the leader, the seats)")
e("RET_CHAT_ONE", "הודעה חדשה אחת בקואליציה", "modal.body", "", "ret.chat")
e("RET_CHAT_OTHER", "⟦{n}⟧ הודעות חדשות בקואליציה", "modal.body", "", "ret.chat")
e("RET_CAP", "הקופה סופרת עד ⟦{h}⟧ שעות. גם לה יש גבולות.", "modal.body", "*", "ret.cap; leader-select-spec §10.3")
e("RET_BTN", "לאסוף", "modal.btnFull", "", "ret.btn")
# --- duration formatters (Fmt.dur, Fmt.secs)
e("FMT_DUR_M", "⟦{m}⟧ דק׳", "modal.body", "", "Fmt.dur < 1 h")
e("FMT_DUR_HM", "⟦{h}⟧ שע׳ ו־⟦{m}⟧ דק׳", "modal.body", "", "Fmt.dur >= 1 h")
e("FMT_SECS", "⟦{s}⟧ שנ׳", "stage.buffChip", "", "Fmt.secs")
e("FMT_WORD_K", "{n} אלף", "share-text:20", "", "Hebrew magnitude words for share prose (no K/M/B there)")
e("FMT_WORD_M", "{n} מיליון", "share-text:20")
e("FMT_WORD_B", "{n} מיליארד", "share-text:20")
e("FMT_WORD_T", "{n} טריליון", "share-text:20")
# --- settings (new rows)
e("SET_MOTION_CAP", "בלי רעידות, בלי קפיצות, בלי החלקות.", "sheet.caption", "", "set.motion.cap")
e("SET_LARGE", "טקסט גדול", "sheet.label", "", "set.large")
e("SET_LARGE_CAP", "לקריאה ממרחק זרוע.", "sheet.caption", "*", "set.large.cap")
e("SET_ABOUT", "אודות ומקורות", "sheet.label", "", "set.about")
e("HELP_ROW", "איך זה עובד", "sheet.label", "", "help.row", "2026-10-03: the settings row that opens the how-it-works sheet (HelpCard)")
e("HELP_TITLE", "איך זה עובד", "modal.title", "", "help.title")
e("HELP_BTN", "איך זה עובד", "dos.btn", "", "help.dossier", "The dossier's button to the same sheet")
e("HELP_TAP", "מקישים על ראש הרשימה ואוספים שקלים. קונים מקורות, והם מכניסים לבד.", "modal.body", "", "help.tap")
e("HELP_61", "בצ'אט הקואליציה השותפים מבקשים כסף. משלמים, והם נשארים איתך עד ⟦61⟧ מנדטים.", "modal.body", "", "help.61")
e("HELP_ELECT", "ב־⟦61⟧ עולה ״עוד סבב!״: בחירות. השקלים מתאפסים, הבסיס נשאר ומגדיל כל הכנסה.", "modal.body", "", "help.elect")
e("HELP_SPINS", "ספינים: מסרים שקונים בכל סבב בחירות, והם עובדים בשבילך עד סוף הסבב.", "modal.body", "", "help.spins")
e("HELP_PICKER", "בכל סבב בחירות בוחרים ראש רשימה. לכל אחד חוק משלו:", "modal.body", "", "help.picker")
e("HELP_RULE", "{rule}: {summary}", "modal.body", "", "help.rule", "The round's leader: rule.name + rule.summary (content)")
e("HELP_SUSP", "חשד: מקורות מפוקפקים מחממים את המדחום. במאה יש יום משפט: חצי הכנסה ובלי הקשות.", "modal.body", "", "help.susp")
e("HELP_ULT", "דרישה שמחכה יותר מדי הופכת לאולטימטום. לא שילמת בזמן: השותף עוזב עם המנדטים.", "modal.body", "", "help.ult")
e("HELP_MISSIONS", "משימות: כל אחת נותנת פרס, וכל דרגה מעלה את ההכנסה לתמיד.", "modal.body", "", "help.missions")
e("HELP_PAUSE", "תפריט פתוח עוצר את השעון. הצ'אט לא.", "modal.body", "", "help.pause")
# --- About (HTML, O8)
e("ABOUT_TITLE", "אודות", "html:8", "", "O8 title")
e("ABOUT_1", "עוד סבב הוא משחק סאטירה. הדמויות הן קריקטורות פיקסל של אנשי ציבור, ומה שהן עושות ואומרות במשחק בדיוני.", "html:120", "L", "about.1")
e("ABOUT_2", "אין במשחק טענות עובדתיות על אף אדם. ציטוטים אמיתיים מופיעים במירכאות, מסומנים ״ציטוט״ ומקושרים למקור. פרשות משפטיות מתוארות כמו ברשומות: נאשם, לכאורה, בחקירה.", "html:170", "L", "about.2")
e("ABOUT_3", "המשחק לא קשור לאף מפלגה, רשימה או מועמד, ולא ממומן על ידם. גם לא על ידי מזוודה.", "html:120", "L*", "about.3")
e("ABOUT_4", "אין כאן המלצה להצביע לאף אחד, ואין כאן סקרים.", "html:120", "L", "about.4")
e("ABOUT_5", "אין כאן מה לקנות: אין פרסומות, אין רכישות, אין פרסים.", "html:120", "L", "about.5")
e("ABOUT_6", "לקראת הבחירות: מ־23.10 ועד סגירת הקלפיות לא יוצגו במשחק מספרי מנדטים.", "html:120", "L", "about.6")
e("ABOUT_7", "ההתקדמות נשמרת רק במכשיר שלך.", "html:120", "L", "about.7")
e("ABOUT_7_TELEMETRY", "ההתקדמות נשמרת רק במכשיר שלך, ונאספים נתוני שימוש אנונימיים.", "html:120", "L", "about.7 (if telemetry ships)")
e("ABOUT_SOURCES", "מקורות וציטוטים", "html:16", "", "about.sources")
e("ABOUT_SOURCE_LINK", "למקור", "html:6", "", "headline.link")
e("ABOUT_WHO_TITLE", "מי אנחנו", "html:10", "", "about who section")
e("ABOUT_WHO", "מאת {publisher}", "html:30", "L", "about.who")
e("ABOUT_CONTACT", "לפניות: {mail}", "html:30", "L", "about.contact")
e("ABOUT_VER", "גרסה ⟦{version}⟧", "html:30", "", "about.ver")
e("ABOUT_SHARE", "לשתף את המשחק", "html:14", "", "about.share")
e("ABOUT_BACK", "חזרה", "html:5", "", "sys.back")
# --- blackout, election night
e("BLK_TITLE", "שקט לפני הקלפי", "modal.title", "L", "blk.title")
e("BLK_BODY", "עד סגירת הקלפיות (⟦27.10⟧, ⟦22:00⟧) לא נציג פה מספרי מנדטים. אנחנו לא סקר, ולא מחפשים עוד תיק.", "modal.body", "L*", "blk.body")
e("BLK_BTN", "הבנתי", "modal.btnFull", "", "blk.btn")
e("NIGHT_TITLE", "הקלפיות נסגרו.", "modal.title", "", "night.title")
e("NIGHT_BODY", "הבחירות נגמרו. הקואליציה? עוד לא.", "modal.body", "*", "night.body")
e("NIGHT_BTN", "למשא ומתן", "modal.btnFull", "", "night.btn")
# --- share sheets
e("SHARE_BTN", "לשתף", "modal.btnHalf", "", "share.btn")
e("SHARE_SAVE", "לשמור תמונה", "modal.btnHalf", "", "share.save")
e("SHARE_CLOSE", "סגור", "sheet.btn", "", "share.close")
e("SHARE_PRINTING", "מדפיס…", "modal.body", "*", "share.printing")
e("SHARE_RECEIPT_TITLE", "הקבלה החודשית", "sheet.title", "", "share.receipt.title")
e("SHARE_RESULT_BTN", "לשתף תוצאה", "dos.btn", "", "share.result.btn")
e("SHARE_RESULT_TITLE", "כרטיס התוצאה", "sheet.title", "", "O5 title")
e("SHARE_COPIED", "הקישור הועתק.", "stage.toast", "", "share.copied")
e("SHARE_SAVED", "התמונה נשמרה.", "stage.toast", "", "share.saved")
e("SHARE_FAIL", "השיתוף לא עבד. נסה שוב.", "stage.toast", "", "share.fail")
e("SHARE_DEEPLINK", "מישהו שרד {rounds} {days}. תורך.", "stage.toast", "*", "share.deeplink")
e("SHARE_WA", "לשתף בוואטסאפ", "modal.btnFull", "", "Bar 2026-09-29: WhatsApp share (wa.me) on O4 / O5", "Full-width button with the speech-bubble icon; wa.me carries text only, so the link preview (OG) does the visual work")
e("ABOUT_SHARE_WA", "לשתף בוואטסאפ", "html:16", "", "Bar 2026-09-29: the invite's WhatsApp link in About (O8)")
# --- About's FAQ (2026-10-01, SEO/AEO: the canvas has no crawlable text; also in <noscript>)
e("FAQ_TITLE", "שאלות נפוצות", "html:16", "", "about.faq title")
e("FAQ_Q1", "מה זה עוד סבב?", "html:30", "", "about.faq q1")
e("FAQ_A1", "משחק סאטירה בדפדפן על הבחירות לכנסת ב־27.10.2026. בוחרים ראש רשימה, אוספים שקלים, משלמים לשותפים והולכים לבחירות שוב ושוב.", "html:140", "", "about.faq a1")
e("FAQ_Q2", "כמה זה עולה?", "html:30", "", "about.faq q2")
e("FAQ_A2", "כלום. אין פרסומות, אין רכישות ואין הרשמה.", "html:80", "", "about.faq a2")
e("FAQ_Q3", "איפה משחקים?", "html:30", "", "about.faq q3")
e("FAQ_A3", "בטלפון או במחשב, ישר בדפדפן, בלי להוריד אפליקציה.", "html:80", "", "about.faq a3")
e("FAQ_Q4", "המשחק בעד מפלגה מסוימת?", "html:30", "", "about.faq q4")
e("FAQ_A4", "לא. הסאטירה היא על כולם, המשחק לא קשור לאף מפלגה ולא ממומן על ידה, והמספרים בו בדיוניים ואינם סקר.", "html:120", "L", "about.faq a4")
e("FAQ_Q5", "מתי הבחירות לכנסת?", "html:30", "", "about.faq q5")
e("FAQ_A5", "ב־27.10.2026. מ־23.10 ועד סגירת הקלפיות המשחק לא מציג מספרי מנדטים.", "html:100", "L", "about.faq a5")
# --- search (2026-10-01, Bar: brand + the queries Israeli autocomplete shows): <meta description>, the
# static /about.html (crawlers that run no JS read it) and its links
e("META_DESCRIPTION", "משחק בחירות סאטירי בעברית: בוחרים ראש רשימה, אוספים שקלים, משלמים לשותפים לקואליציה והולכים לבחירות שוב ושוב. חינם, בלי הרשמה, סאטירה על כולם.", "html:160", "", "<meta name=description> + JSON-LD (OG keeps OG_DESCRIPTION)")
e("ABOUT_PAGE_TITLE", "עוד סבב: משחק הבחירות שלא נגמרות", "html:40", "", "/about.html h1")
e("ABOUT_LEAD", "עוד סבב הוא משחק דפדפן סאטירי וחינמי בעברית על הבחירות לכנסת ה־26 (27.10.2026): בוחרים ראש רשימה, אוספים שקלים, משלמים לשותפים לקואליציה והולכים לבחירות שוב ושוב. בלי הרשמה, לא קשור לאף מפלגה.", "html:220", "", "/about.html lead, the direct answer")
e("ABOUT_PLAY", "לשחק עכשיו", "html:14", "", "/about.html link to the game")
e("ABOUT_MORE", "על המשחק", "html:14", "", "About dialog + noscript link to /about.html")
e("ABOUT_UPDATED", "עודכן: {date}", "html:24", "", "/about.html, the build date")
# --- plural fragments for the result line and the deep-link toast
e("ROUNDS_ONE", "סבב בחירות אחד", "result.head", "", "§5.2 ICU rounds one")
e("ROUNDS_TWO", "שני סבבי בחירות", "result.head", "", "§5.2 ICU rounds two")
e("ROUNDS_OTHER", "⟦{n}⟧ סבבי בחירות", "result.head", "", "§5.2 ICU rounds other")
e("DAYS_ZERO", "ואפס ימים בכותרות", "result.head", "*", "§5.2 ICU days =0", "Leader-neutral (game-designer 2026-09-29): {n} = court days + press days (Investigation.hazard_days), so every leader's days count and the words fit both skins; was 'ימי משפט' (Bibi's court only)")
e("DAYS_ONE", "ויום אחד בכותרות", "result.head", "", "§5.2 ICU days one", "Leader-neutral, see DAYS_ZERO")
e("DAYS_TWO", "ושני ימים בכותרות", "result.head", "", "§5.2 ICU days two", "Leader-neutral, see DAYS_ZERO")
e("DAYS_OTHER", "ו־⟦{n}⟧ ימים בכותרות", "result.head", "", "§5.2 ICU days other", "Leader-neutral, see DAYS_ZERO")
# --- receipt card: 216x270 art at x5, print column 152 art px, <= 22 lines (2D Artist style guide §13, flag F3)
# Layout, top to bottom (19 text lines + 3 rules = 21.7 of 22): BRAND, KIND, ROUND, rule, HEAD (2 lines), TOTAL_LINE,
# rule, VAT, FUEL + FUEL_NOTE, WING, PISTACHIO, COALITION, rule, SUM, PAID_BY, COUNTDOWN, FOOT_REAL,
# FOOT_DISC_URL (2 lines), THANKS. Amounts sit at the left end of their item's line (RECEIPT_AMOUNT).
e("RECEIPT_BRAND", "עוד סבב", "receipt.line")
e("RECEIPT_KIND", "חשבונית מס / קבלה (העתק)", "receipt.line", "*")
e("RECEIPT_ROUND", "סבב בחירות מס׳ ⟦{n}⟧ · ⟦{date}⟧", "receipt.line")
e("RECEIPT_HEAD", "הקיסרות שלך עלתה למשפחה הממוצעת", "receipt.wrap", "*")
e("RECEIPT_TOTAL_LINE", "⟦{xr}⟧~₪ החודש", "receipt.line", "", "{xr}: full grouping below 10,000,000 (4,213,000), the bank format above (12.34M)")
e("RECEIPT_BIG", "⟦{x}⟧~₪", "unused", note="Replaced by RECEIPT_TOTAL_LINE (flag F3: 22-line card)")
e("RECEIPT_MONTH", "החודש", "unused", note="Folded into RECEIPT_TOTAL_LINE")
e("RECEIPT_COL_ITEM", "פריט", "unused", note="Column headers cut to fit 22 lines; the footnote explains the columns")
e("RECEIPT_COL_GAME", "במשחק", "unused")
e("RECEIPT_VAT", "מע״מ ⟦18%⟧*", "receipt.item", "L")
e("RECEIPT_FUEL", "דלק ⟦95⟧: ⟦8.25⟧~₪ לליטר*", "receipt.line", "L", note="Own line; its amount goes on RECEIPT_FUEL_NOTE's line")
e("RECEIPT_FUEL_NOTE", "(שיא, ⟦1.9.2026⟧)", "receipt.item", "L")
e("RECEIPT_WING", "כנף ציון: חלקכם*", "receipt.item", "L*")
e("RECEIPT_PISTACHIO", "גלידת פיסטוק*", "receipt.item", "L*", note="'(בוטל ב־2013)' cut for the 22-line card; the 0 ₪ carries the gag")
e("RECEIPT_COALITION", "כספים קואליציוניים*", "receipt.item", "L")
e("RECEIPT_COALITION_NOTE", "(כולל ⟦800⟧ מיליון ₪ שאושרו בטעות)*", "unused", note="Cut for the 22-line card (flag F3)")
e("RECEIPT_AMOUNT", "⟦{xr}⟧~₪", "receipt.amount", note="{xr}: full grouping below 10,000,000, the bank format above")
e("RECEIPT_SUM", "סה״כ", "receipt.item")
e("RECEIPT_PAID_BY", "שולם על ידי: אתם", "receipt.line", "*")
e("RECEIPT_PAY_METHOD", "אמצעי תשלום: המשכורת שלכם", "unused", note="Cut for the 22-line card (flag F3)")
e("RECEIPT_COUNTDOWN_ONE", "עד הבחירות: יום אחד (⟦27.10⟧)", "receipt.line")
e("RECEIPT_COUNTDOWN_TWO", "עד הבחירות: יומיים (⟦27.10⟧)", "receipt.line")
e("RECEIPT_COUNTDOWN_OTHER", "עד הבחירות: ⟦{d}⟧ ימים (⟦27.10⟧)", "receipt.line")
e("RECEIPT_COUNTDOWN_TODAY", "הבחירות: היום", "receipt.line")
e("RECEIPT_COUNTDOWN_AFTER", "הבחירות: נגמרו. הקואליציה: עוד לא.", "receipt.wrap", "*")
e("RECEIPT_FOOT_REAL", "* הנתון אמיתי. הסכום מהמשחק.", "receipt.line", "L")
e("RECEIPT_FOOT_DISC", "סאטירה. לא קשור לאף מפלגה או מועמד.", "receipt.wrap", "L", note="Never shorten: 'או מועמד' is the legal half")
e("RECEIPT_FOOT_URL", "{url}", "receipt.line", "L", note="MUST be on the image: iOS WhatsApp drops the share text when an image is attached (first-minute §5.1). URL <= 22 chars")
e("RECEIPT_THANKS", "*** תודה שבחרתם. שוב. ***", "receipt.line", "*")
# --- result card (216x270 art at x5)
e("RESULT_HEADLINE", "שרדתי {rounds} {days}", "result.head", "*", "§5.2")
e("RESULT_ZERO_TAG", "בינתיים.", "result.head", "*", "§5.2 appended when days = 0")
e("RESULT_SUB", "והציבור? נרגש.", "result.line", "*", "§5.2")
e("RESULT_STATS", "מזוודות שנתפסו: ⟦{s}⟧ · בקשות דחייה: ⟦{n}⟧", "result.line", "", "§5.2")
e("RESULT_FOOT", "משחק סאטירה · {url}", "result.foot", "L", "§5.2", "The URL MUST be on the image (see RECEIPT_FOOT_URL). 'עוד סבב · ' dropped (game-developer 2026-09-29): with the real host od-sevev.vercel.app the line is 209 px in the 200 band; the wordmark at the card's top carries the name")
e("RESULT_DISC", "סאטירה. לא קשור לאף מפלגה או מועמד.", "result.foot", "L", "§5.2")
# --- share texts (plain text into WhatsApp; plural address)
e("SHARE_TEXT_RESULT", "שרדתי {rounds} {days} ב״עוד סבב״. מישהו פה עושה יותר? {url}", "share-text:90", "*", "§5.3 result")
e("SHARE_TEXT_RECEIPT", "הקיסרות שלי ב״עוד סבב״ עלתה למשפחה הממוצעת {amount} ₪ החודש. (במשחק. בינתיים.) {url}", "share-text:100", "*L", "§5.3 receipt")
e("SHARE_TEXT_INVITE", "משחק סאטירה על הבחירות שלא נגמרות. תורכם להקים ממשלה. {url}", "share-text:70", "*", "§5.3 invite; spec §10.3 SHARE_TEXT_INVITE", "The picker shipped (2026-09-29): was SHARE_TEXT_INVITE_NEXT. game/tests/unit/test_share_view.gd pins 'תורכם להקים ממשלה'")
# ================= the share platform (Bar 2026-10-02: the reinvented sharing) =================
# The HTML share drawer (game/web/shell.html, templated by tools/lib/render_shell.py), the 📣 chip and
# the media advisor's prompt on the canvas, the share cards (ui/share_cards.gd, art px at scale 1 or 2)
# and the share texts. Texts: a Hebrew word first, the number and a short provocation, the link ALONE
# on the last line (the code appends "\n" + link, so no {url} here), at most 200 chars, 1-3 emoji at
# line ends, no em dash, never a poll number, "שיחקתי את" and never "who I vote for". The _N variants
# are the family-safe ones: they mock the system and name no leader. Rotation: ShareKit.copy_line.
# --- the drawer (html)
e("SHARE_DRAWER_TITLE", "להדליף לקבוצה", "html:24", "*", "share drawer h2")
e("SHARE_DRAWER_PREVIEW", "ככה זה ייראה בקבוצה", "html:30", "", "share drawer: the caption over the WhatsApp-bubble mock")
e("SHARE_FMT_SQUARE", "ריבוע", "html:10", "", "share drawer format toggle: 1080×1350")
e("SHARE_FMT_STORY", "סטורי", "html:10", "", "share drawer format toggle: 1080×1920")
e("SHARE_FMT_TEXT", "טקסט בלבד", "html:12", "", "share drawer format toggle: the text and the link (the link preview carries the picture)")
e("SHARE_FMT_LABEL", "פורמט", "html:12", "", "share drawer: the format group's accessible name")
e("SHARE_NEUTRAL", "גרסה לקבוצת המשפחה", "html:24", "*", "share drawer: the family-safe toggle")
e("SHARE_NEUTRAL_CAP", "צוחקת על השיטה, בלי שמות", "html:32", "", "share drawer: the family-safe toggle's caption")
e("SHARE_KINDS_LABEL", "מה להדליף", "html:16", "", "share drawer: the kind tabs' accessible name")
e("SHARE_CH_WA", "וואטסאפ", "html:10", "", "share drawer channel row")
e("SHARE_CH_TG", "טלגרם", "html:10", "", "share drawer channel row")
e("SHARE_CH_X", "X", "html:4", "", "share drawer channel row (the network's own name)")
e("SHARE_CH_COPY", "להעתיק", "html:10", "", "share drawer channel row: the text and the link to the clipboard")
e("SHARE_CH_SAVE", "לשמור", "html:10", "", "share drawer channel row: the image as a download")
e("SHARE_MORE", "או ישירות ל:", "html:16", "", "share drawer: the label over the channel row")
e("SHARE_INAPP_HINT", "הדפדפן של האפליקציה לא משתף תמונות. לחיצה ארוכה על התמונה שומרת אותה, או פתחו את המשחק בדפדפן.", "html:110", "", "share drawer: Instagram / Facebook in-app browsers (no navigator.share)")
e("SHARE_TEXT_COPIED", "הטקסט הועתק. הדביקו אותו ליד התמונה.", "html:44", "", "share drawer, iPhone: WhatsApp drops a caption sent with an image, so the caption is copied first")
e("SHARE_COPIED_ALL", "הטקסט והקישור הועתקו.", "html:30", "", "share drawer: copy")
e("SHARE_SENT", "יצא. עכשיו מחכים לתגובות בקבוצה.", "stage.toast", "*", "share result 'shared' (the drawer and the canvas sheet's status line)")
e("SHARE_KIND_LEAK", "הדלפה", "html:12", "*", "share drawer kind tab")
e("SHARE_KIND_BREAKING", "מבזק", "html:12", "", "share drawer kind tab")
e("SHARE_KIND_TERM", "סיכום קדנציה", "html:14", "", "share drawer kind tab")
e("SHARE_KIND_CAREER", "כל הסבבים", "html:14", "", "share drawer kind tab: every round so far")
e("SHARE_KIND_RECEIPT", "הקבלה", "html:12", "*", "share drawer kind tab (O4)")
e("SHARE_KIND_RESULT", "התוצאה", "html:12", "", "share drawer kind tab (O5)")
e("SHARE_KIND_CHALLENGE", "אתגר", "html:12", "", "share drawer kind tab (the challenge agent's card)")
e("SHARE_KIND_DAILY", "האתגר היומי", "html:14", "", "share drawer kind tab (the daily round)")
# --- the canvas: the 📣 chip, the media advisor (Dubi), T4's row
e("SHARE_CHIP", "הדלף", "stage.shareChip", "*", "the 📣 chip on the stage and in T3's header (ui/share_desk.gd)")
e("SHARE_CAREER_BTN", "סיכום כל הסבבים", "dos.btn", "", "T4 row: the career card")
e("ADVISOR_HEAD", "דובי · יועץ התקשורת", "stage.toastHead", "*", "the media advisor's chat toast (ShareDesk prompt)")
e("ADVISOR_LEAK", "יש לנו כותרת. להדליף?", "stage.toastChat", "*", "ShareDesk prompt after a juicy chat moment")
e("ADVISOR_BREAKING", "יש לנו מבזק. להדליף?", "stage.toastChat", "*", "ShareDesk prompt: 61 / a court day")
e("ADVISOR_TERM", "הקדנציה נגמרה. להדליף סיכום?", "stage.toastChat", "*", "ShareDesk prompt after the election ceremony")
e("ADVISOR_CAREER", "שרדת {rounds}. להדליף סיכום?", "stage.toastChat", "*", "ShareDesk prompt at round 3 / 5 / 10; {rounds} = ROUNDS_*")
e("CHAT_SYS_ADVISOR", "דובי, יועץ התקשורת: יש לנו כותרת. להדליף?", "chat.sys", "*", "the advisor's line in T3 (the header's 📣 lights up)")
# --- card text (art px; scale 1 unless the box says 2)
e("CARD_SATIRE", "סאטירה · עוד סבב", "card.stamp", "L", "the stamp on every share image")
e("CARD_URL", "{url}", "card.wide", "L", "the URL on every share image (iOS WhatsApp drops the caption)")
e("LEAK_CARD_TOP", "הודלף מ: עוד סבב", "card.wide", "*", "the leak card's header")
e("LEAK_CARD_MEMBERS", "⟦{n}⟧ משתתפים", "card.label", "", "the leak card's group status")
e("LEAK_CARD_FOOT", "צילום מסך שלא היה אמור לצאת", "card.wide", "*", "the leak card's footer line")
e("SHARE_ANON_1", "שותף א׳", "card.label", "", "the family-safe leak: the first partner's stand-in name")
e("SHARE_ANON_2", "שותף ב׳", "card.label", "", "the family-safe leak: the second partner")
e("SHARE_ANON_3", "שותף ג׳", "card.label", "", "the family-safe leak: the third partner")
e("SHARE_ANON_4", "שותף ד׳", "card.label", "", "the family-safe leak: the fourth partner")
e("LEAK_CARD_LINE", "{name}: {text}", "unused", note="The leak card builds its bubbles from the round's real chat lines (ChatView.line_text / sys_text)")
e("BREAK_CHANNEL", "ערוץ ⟦61⟧", "card.label", "*", "the breaking card's invented channel (never a real channel's name or logo)")
e("BREAK_CHANNEL_QUIET", "ערוץ עוד סבב", "card.label", "", "the channel name in the election silence (no 61)")
e("BREAK_LIVE", "שידור חי", "card.label", "", "the breaking card's live bug")
e("BREAK_HEAD_GATE", "{short} הרכיב קואליציה ב־⟦{time}⟧", "card.big", "*", "breaking: the gate")
e("BREAK_HEAD_GATE_N", "קואליציה הורכבה ב־⟦{time}⟧", "card.big", "*", "breaking: the gate, family-safe")
e("BREAK_HEAD_COURT", "{short} בבית המשפט. שוב.", "card.big", "*", "breaking: a court day")
e("BREAK_HEAD_COURT_N", "יום משפט באמצע הקדנציה", "card.big", "*", "breaking: a court day, family-safe")
e("BREAK_HEAD_ELECTION", "{short} הולך לבחירות. שוב.", "card.big", "*", "breaking: the election called")
e("BREAK_HEAD_ELECTION_N", "הכנסת התפזרה. שוב.", "card.big", "*", "breaking: the election called, family-safe")
e("BREAK_SUB_1", "גנץ עדיין שוקל", "card.wide", "*", "breaking sub-line (rotates)")
e("BREAK_SUB_2", "השותפים כבר דורשים עוד", "card.wide", "*", "breaking sub-line (rotates)")
e("BREAK_SUB_3", "והציבור? נרגש.", "card.wide", "*", "breaking sub-line (rotates)")
e("BREAK_SUB_4", "מי משלם? אתם.", "card.wide", "*", "breaking sub-line (rotates)")
e("BREAK_CRAWL", "בהמשך המהדורה: עוד בחירות", "card.wide", "*", "breaking: the crawl band")
e("TERM_HEAD", "סיכום הקדנציה", "card.big", "", "term summary title")
e("TERM_ROUND", "סבב בחירות מס׳ ⟦{n}⟧ · {short}", "card.wide", "", "term summary: the round and the leader")
e("TERM_ROUND_N", "סבב בחירות מס׳ ⟦{n}⟧", "card.wide", "", "term summary, family-safe")
e("TERM_GATE", "עד קואליציה", "card.label", "", "term summary: the label under the big time")
e("TERM_TOP", "⟦{pct}%⟧ מההכנסות: {source}", "card.wrap2", "*", "term summary: the top source's share")
e("TERM_PAID", "תשלומים לשותפים: ⟦{n}⟧", "card.wide", "*", "term summary stat")
e("TERM_LEFT", "טרקו את הדלת: ⟦{n}⟧", "card.wide", "*", "term / career stat: walkouts")
e("TERM_COURT", "ימים בכותרות: ⟦{n}⟧", "card.wide", "*", "term / career stat: court + press days (leader-neutral, like DAYS_*)")
e("TERM_POST", "בקשות דחייה: ⟦{n}⟧", "card.wide", "*", "term summary stat")
e("TERM_TITLE_LABEL", "התואר:", "card.label", "", "term summary: the run's title label")
e("TERM_TITLE_FAST", "מרכיב קואליציות בזק", "card.big", "*", "term title: the gate in under 5 minutes")
e("TERM_TITLE_COURT", "ראש ממשלה במשרה חלקית", "card.big", "*", "term title: 2+ days in the headlines")
e("TERM_TITLE_PAID", "הכספומט הלאומי", "card.big", "*", "term title: 8+ payments")
e("TERM_TITLE_LEFT", "מפרק קואליציות", "card.big", "*", "term title: 2+ walkouts")
e("TERM_TITLE_SLOW", "מתמהמה מקצועי", "card.big", "*", "term title: over 30 minutes to the gate")
e("TERM_TITLE_PLAIN", "עוד ראש ממשלה", "card.big", "*", "term title: the default")
e("CAREER_HEAD", "סיכום כל הסבבים", "card.big", "", "career card title")
e("CAREER_SURVIVED", "שרדתי {rounds}", "card.big", "*", "career card: {rounds} = ROUNDS_*")
e("CAREER_AS", "בתור {short}", "card.wide", "*", "career card: the favourite leader (by rounds played)")
e("CAREER_TOTAL", "הכנסות: {amount} ₪", "card.wide", "*", "career card: every round's income (Hebrew units)")
e("CAREER_FAST", "הכי מהר: ⟦{time}⟧ עד קואליציה", "card.wide", "", "career card: the fastest gate")
e("CAREER_PARTNER", "השותף הכי יקר: {name}", "card.wrap2", "*", "career card: the partner paid the most, most often")
e("CAREER_RANK", "הדרגה:", "card.label", "", "career card: the rank label")
e("CAREER_TITLE_1", "חבר כנסת מתחיל", "card.big", "*", "career rank: 1-2 rounds")
e("CAREER_TITLE_2", "סגן שר בלי תיק", "card.big", "*", "career rank: 3-4 rounds")
e("CAREER_TITLE_3", "שר בכיר לענייני בחירות", "card.big", "*", "career rank: 5-9 rounds")
e("CAREER_TITLE_4", "ראש ממשלה לנצח", "card.big", "*", "career rank: 10-24 rounds")
e("CAREER_TITLE_5", "מוסד לאומי", "card.big", "*", "career rank: 25+ rounds")
e("CHAL_HEAD", "אתגר", "card.big", "", "challenge card title")
e("CHAL_LINE", "{short} הרכיב קואליציה ב:", "card.wide", "*", "challenge card: over the big time")
e("CHAL_LINE_N", "קואליציה ב:", "card.wide", "", "challenge card, family-safe")
e("CHAL_DARE", "תעבור אותי?", "card.big", "*", "challenge card: the dare")
e("DAILY_HEAD", "עוד סבב ⟦#{n}⟧", "card.big", "", "daily card title")
e("DAILY_SUB", "האתגר היומי", "card.wide", "", "daily card sub-line")
e("DAILY_DARE", "מה התוצאה שלך?", "card.wide", "", "daily card: the dare")
e("SHARE_ARRIVED", "מישהו הדליף לך את זה. עכשיו תורך.", "stage.toast", "*", "the toast for a player who arrived from a shared link")
# --- share texts (the drawer appends "\n" + the link)
e("SHARE_LEAK_1", "הודלף מהקבוצה של {short}. אל תגידו שאני שלחתי 🤐", "share-text:200", "*", "share text: leak")
e("SHARE_LEAK_2", "צילום מסך מקבוצת הקואליציה של {short}. הוא עוד לא יודע שזה יצא 📱", "share-text:200", "*", "share text: leak")
e("SHARE_LEAK_3", "תראו מה קורה בקואליציה של {short} בעוד סבב. זה לא נגמר טוב 🔥", "share-text:200", "*", "share text: leak")
e("SHARE_LEAK_4", "דליפה מהקבוצה: שיחקתי את {short} ושילמתי לכולם. לכולם 💸", "share-text:200", "*", "share text: leak")
e("SHARE_LEAK_N1", "הודלף מקבוצת קואליציה. כל אחד רוצה משהו, אף אחד לא מוותר 🤐", "share-text:200", "*", "share text: leak, family-safe")
e("SHARE_LEAK_N2", "צילום מסך מקבוצת הקואליציה בעוד סבב. ככה מקימים ממשלה 📱", "share-text:200", "*", "share text: leak, family-safe")
e("SHARE_LEAK_N3", "דליפה מהקבוצה: דרישות, אולטימטומים ומישהו שיצא בטריקת דלת 🚪", "share-text:200", "*", "share text: leak, family-safe")
e("SHARE_BREAK_GATE_1", "מבזק: {short} הרכיב קואליציה ב־{time}. מי עושה מהר יותר? ⏱️", "share-text:200", "*", "share text: breaking, the gate")
e("SHARE_BREAK_GATE_2", "מבזק מעוד סבב: קואליציה תוך {time}. השותפים כבר דורשים עוד 📰", "share-text:200", "*", "share text: breaking, the gate")
e("SHARE_BREAK_GATE_3", "עדכון: שיחקתי את {short} וסגרתי קואליציה ב־{time}. גנץ עדיין שוקל 🗞️", "share-text:200", "*", "share text: breaking, the gate")
e("SHARE_BREAK_COURT_1", "מבזק: {short} בבית המשפט, הקואליציה בקבוצה. ככה זה אצלי בעוד סבב ⚖️", "share-text:200", "*", "share text: breaking, a court day")
e("SHARE_BREAK_COURT_2", "מבזק: יום משפט באמצע הקדנציה. הקואליציה מחכה בחוץ ⚖️", "share-text:200", "*", "share text: breaking, a court day")
e("SHARE_BREAK_ELECTION_1", "מבזק: {short} הולך לבחירות. שוב. מי בא איתי לעוד סבב? 🗳️", "share-text:200", "*", "share text: breaking, the election")
e("SHARE_BREAK_ELECTION_2", "מבזק: הכנסת התפזרה. אני כבר מתחיל עוד סבב 🗳️", "share-text:200", "*", "share text: breaking, the election")
e("SHARE_BREAK_N1", "מבזק: עוד קואליציה קמה, עוד בחירות בדרך. ככה זה אצלנו 📰", "share-text:200", "*", "share text: breaking, family-safe")
e("SHARE_BREAK_N2", "מבזק מעוד סבב: השותפים דורשים, הקופה משלמת. מי משלם? אתם 📰", "share-text:200", "*", "share text: breaking, family-safe")
e("SHARE_BREAK_N3", "מבזק: הכנסת התפזרה. שוב. מישהו מופתע? 🗳️", "share-text:200", "*", "share text: breaking, family-safe")
e("SHARE_TERM_1", "סיכום הקדנציה שלי בעוד סבב: {time} עד קואליציה, {paid} תשלומים לשותפים. מי משלם? 🧾", "share-text:200", "*", "share text: term summary")
e("SHARE_TERM_2", "שיחקתי את {short} וסיימתי קדנציה. התואר שלי: {title} 🏅", "share-text:200", "*", "share text: term summary")
e("SHARE_TERM_3", "עוד קדנציה נגמרה. {pct}% מההכנסות הגיעו מ{source}. מקרה? 🤔", "share-text:200", "*", "share text: term summary ({source} = the producer's name)")
e("SHARE_TERM_N1", "סיכום קדנציה בעוד סבב: {time} עד קואליציה. הקופה? שלכם 🧾", "share-text:200", "*", "share text: term summary, family-safe")
e("SHARE_TERM_N2", "עוד קדנציה נגמרה, עוד בחירות מתחילות. התואר שלי: {title} 🏅", "share-text:200", "*", "share text: term summary, family-safe")
e("SHARE_CAREER_1", "שרדתי {rounds} בעוד סבב. הדרגה שלי: {title}. מי עוד פה? 🏆", "share-text:200", "*", "share text: career")
e("SHARE_CAREER_2", "סיכום הקריירה שלי בעוד סבב: {rounds}, הכי מהר {time}. נראה אתכם 🏆", "share-text:200", "*", "share text: career")
e("SHARE_CAREER_3", "ראש הרשימה האהוב עליי: {short}. {rounds} ואף ממשלה לא החזיקה 🗳️", "share-text:200", "*", "share text: career")
e("SHARE_CAREER_N1", "סיכום הקריירה שלי בעוד סבב: {rounds}. הבחירות לא נגמרות, גם אני לא 🏆", "share-text:200", "*", "share text: career, family-safe")
e("SHARE_CAREER_N2", "שרדתי {rounds}. הדרגה שלי: {title}. תורכם 🏆", "share-text:200", "*", "share text: career, family-safe")
e("SHARE_CHAL_1", "אתגר: הרכבתי קואליציה עם {short} ב־{time}. תעבור אותי? ⏱️", "share-text:200", "*", "share text: challenge")
e("SHARE_CHAL_2", "אתגר מעוד סבב: {time} עד קואליציה. יש פה מישהו מהיר יותר? ⏱️", "share-text:200", "*", "share text: challenge")
e("SHARE_CHAL_N1", "אתגר: קואליציה ב־{time}. תעברו את זה? ⏱️", "share-text:200", "*", "share text: challenge, family-safe")
e("SHARE_DAILY", "האתגר היומי של עוד סבב #{n}\n{grid}", "share-text:200", "", "share text: the daily round ({grid} = the challenge agent's emoji grid)")
e("SHARE_RESULT_2", "שרדתי {rounds} {days} בעוד סבב. מישהו פה עושה יותר? 🏆", "share-text:200", "*", "share text: result (drawer form, the link on its own line)")
e("SHARE_RECEIPT_2", "הקיסרות שלי בעוד סבב עלתה למשפחה הממוצעת {amount} ₪ החודש. במשחק. בינתיים. 🧾", "share-text:200", "*L", "share text: receipt (drawer form)")
# --- the link previews of the share stubs (/s/<variant>/, tools/lib/gen_share_stubs.py; og:title starts with a Hebrew word)
e("OG_S_GATE", "{short} הרכיב קואליציה. עכשיו תורך", "og:60", "*", "stub og:title: <leader>-61")
e("OG_S_LEAK", "הודלף מהקואליציה של {short}", "og:60", "*", "stub og:title: <leader>-leak")
e("OG_S_BREAKING", "מבזק: {short} שוב בכותרות", "og:60", "*", "stub og:title: <leader>-breaking")
e("OG_S_TERM", "סיכום הקדנציה של {short}", "og:60", "", "stub og:title: <leader>-term")
e("OG_S_CAREER", "שרדתי עוד ועוד בחירות בתור {short}", "og:60", "*", "stub og:title: <leader>-career")
e("OG_S_CHALLENGE", "אתגר: להרכיב קואליציה מהר יותר מ{short}", "og:60", "*", "stub og:title: <leader>-challenge")
e("OG_S_RESULT", "שרדתי בתור {short}. עכשיו תורך", "og:60", "*", "stub og:title: <leader>-result")
e("OG_N_LEAK", "הודלף מקבוצת הקואליציה", "og:60", "*", "stub og:title: all-leak")
e("OG_N_BREAKING", "מבזק: הכנסת התפזרה. שוב.", "og:60", "*", "stub og:title: all-breaking")
e("OG_N_TERM", "סיכום קדנציה: מי שילם על הכול?", "og:60", "*", "stub og:title: all-term")
e("OG_N_CAREER", "סיכום כל הסבבים: כמה בחירות אפשר לשרוד?", "og:60", "*", "stub og:title: all-career")
e("OG_N_RECEIPT", "הקבלה החודשית של הקואליציה", "og:60", "*", "stub og:title: all-receipt")
e("OG_N_RESULT", "כמה סבבי בחירות אתם שורדים?", "og:60", "*", "stub og:title: all-result")
e("OG_N_CHALLENGE", "אתגר: להרכיב קואליציה הכי מהר", "og:60", "*", "stub og:title: all-challenge")
e("OG_DAILY", "האתגר היומי של עוד סבב", "og:60", "", "stub og:title: daily")
e("OG_S_DESC", "שיחקו את זה לפניך. בוחרים ראש רשימה, משלמים לשותפים והולכים לבחירות שוב. סאטירה על כולם.", "og:110", "L*", "stub og:description (every variant)")
e("OG_S_ALT", "כרטיס פיקסלים מעוד סבב: {short} על במה, מעליו הכותרת", "og:90", "", "stub og:image:alt with a leader")
e("OG_N_ALT", "כרטיס פיקסלים מעוד סבב: הכותרת על במה ריקה", "og:90", "", "stub og:image:alt without a leader")
# --- OG / manifest
e("OG_TITLE", "עוד סבב: הבחירות שלא נגמרות", "og:45", "*", "§5.4 og:title")
e("OG_DESCRIPTION", "בוחרים ראש רשימה, משלמים לשותפים ודוחים את מה שאפשר. סאטירה על כולם, לא קשורה לאף מפלגה.", "og:110", "L*", "§5.4 og:description; spec §10.3 OG_DESCRIPTION", "The picker shipped (2026-09-29): was OG_DESCRIPTION_NEXT. shell.html og:description / twitter:description read it at build ({{OG_DESCRIPTION}})")
e("OG_IMAGE_ALT", "שמונה ראשי רשימות בפיקסלים עומדים בשורה על במה, מעליהם הכיתוב עוד סבב", "og:90", "", "§5.4 og:image:alt; spec §10.3", "Describes the lineup og.jpg (Bar 2026-09-29: the lineup key art replaces Bibi-with-hat); was OG_IMAGE_ALT_NEXT")
e("OG_SITE_NAME", "עוד סבב", "og:12", "", "§5.4 og:site_name")
e("MANIFEST_SHORT_NAME", "עוד סבב", "og:12", "", "§5.5 short_name")
e("MANIFEST_NAME", "עוד סבב · משחק סאטירה", "og:30", "", "§5.5 name")
# --- dossier tab rows
e("DOS_TITLE", "תיקים", "tall.title", "*", "dos.title")
e("DOS_ROUNDS", "סבבי בחירות: ⟦{n}⟧", "dos.row", "", "dos.stats")
e("DOS_COURT_DAYS", "ימי משפט: ⟦{n}⟧", "dos.row", "", "dos.stats")
e("DOS_POSTPONES", "בקשות דחייה: ⟦{n}⟧", "dos.row", "", "dos.stats")
e("DOS_TOTAL", "סה״כ נכנס לקופה: ⟦{x}⟧~₪", "dos.row", "", "dos.stats; leader-select-spec §10.3")
e("DOS_CAUGHT", "מזוודות שנתפסו: ⟦{n}⟧", "dos.row", "", "dos.stats")
e("DOS_ARRIVED", "שהגיעו ליעדן: ⟦{n}⟧", "dos.row", "*", "dos.stats (the punchline row)")
e("DOS_INCOME", "כל ההכנסה: ⟦×{x}⟧", "dos.row", "", "dos.income", "2026-10-03: one number for every multiplier on income (₪/s over the sources' own yield)")
e("DOS_BASE", "הבסיס הנאמן: ⟦{n}⟧ · ⟦+{pct}%⟧ לכל הכנסה", "dos.row", "", "new")
e("DOS_SUSP_FLOOR", "חשד שנשאר מסבבים קודמים: ⟦{pct}%⟧", "dos.row", "*", "pitch §11 Q8 floor")
# --- album (post-launch)
e("ALBUM_TITLE", "אלבום: תמיד בפריים", "sheet.title", "", "album.title")
e("ALBUM_TROPHY", "שלום בית בפריים", "dos.row", "", "album.trophy")
# --- system
e("SYS_ROTATE_CAP", "הקואליציה עובדת רק בעמידה.", "modal.body", "*", "sys.rotate.cap; leader-select-spec §10.3")
e("SYS_ERROR", "משהו נתקע.", "modal.title", "", "sys.error")
e("SYS_RELOAD", "לרענן", "modal.btnFull", "", "sys.reload")
e("SYS_CLOSE", "סגור", "sheet.btn", "", "sys.close")
e("SYS_BACK", "חזרה", "html:5", "", "sys.back", "Accessible label of the chevron")
e("SYS_ERA_PACK_LATE", "הכנסת בשיפוצים. הממשלה עובדת מהבית.", "ticker.crawl", "*G", "first-minute §2.1 [GD] suggestion; leader-select-spec §10.3")

# ================= leader select (design/leader-select-spec.md; ux/rtl-map.md §8, ux/screen-graph.md §0, ux/ftue.md §8) =================
# Words that are the designer's (leaderSelect.pick.copy, hazardSkins.press, leaders.liberman.rule.copy) are mirrored here
# verbatim and checked for drift below; the view draws these keys. The per-leader nouns ({short}, {party}, {verb}, ...)
# come from design/content.json leaders[] at runtime; their worst cases are measured from the content (PH above).
# --- the picker screen (LEADER_PICK)
e("LEADER_PICK_TITLE", "מי מקים את הממשלה הפעם?", "pick.title", "", "leaderSelect.pick.copy.title", "First launch: under the wordmark")
e("LEADER_PICK_TITLE_AFTER", "סבב בחירות חדש. מי בראש הרשימה?", "pick.title", "", "leaderSelect.pick.copy.titleAfter", "After every election")
e("LEADER_PICK_FRESH_CHIP", "פנים חדשות: ⟦+{pct}%⟧ בונוס בחירות", "pick.chip", "", "spec §3.3 fresh face (D9); Bar 2026-09-29 keeps +10%", "After an election only: ONE chip under the title, never on a tile (a percent beside a face reads as a poll swing). {pct} = leaderSelect.pick.freshFaceBasePct")
e("LEADER_PICK_AGAIN", "עוד סבב עם {short}", "pick.again", "", "leaderSelect.pick.copy.again", "The last round's leader, with their 24 avatar at x2 as the leading icon. Esc / back = this button")
e("LEADER_PICK_LOCKED", "בסבב ⟦{n}⟧", "pick.party", "", "roster ladder (2026-10-03)", "A locked tile's second line instead of the party: the round its leader opens in (leaderSelect.unlockRound + 1)")
e("LEADER_PICK_LOCKED_CAP", "עוד מתמודד מצטרף בסבב ⟦{n}⟧. כל סבב בחירות נפתח עוד אחד.", "pick.strip", "", "roster ladder (2026-10-03)", "The strip line while a locked tile is pressed or focused")
e("LEADER_PICK_NEW", "חדש!", "pick.name", "", "roster ladder (2026-10-03)", "The tag on a tile that opened this round")
e("WIZ_SKIP", "דלג", "pick.name", "", "wizard overlay (ADR 0007)", "The wizard's skip, top-left of the column (kit chat_system_pill 136 x 64): ends the running wizard")
e("LEADER_PICK_VOTE", "לשים בקלפי: {short}", "pick.again", "", "the ballot booth (2026-10-03)", "The booth's primary button once a slip is chosen: the slip goes into the envelope and the ballot box")
e("LEADER_PICK_VOTE_BLANK", "פתק לבן: דובי בוחר", "pick.again", "", "the ballot booth (2026-10-03)", "The primary button when the blank slip (הפתעה) is chosen")
e("LEADER_PICK_CHOOSE", "בוחרים פתק מהמגש", "pick.again", "", "the ballot booth (2026-10-03)", "The primary button, disabled, before any slip is chosen")
e("LEADER_PICK_LOCKED_BTN", "הפתק הזה בדפוס", "pick.again", "", "the ballot booth (2026-10-03)", "The primary button, disabled, while a locked slip is chosen")
e("LEADER_PICK_INTRO", "הקלפי פתוחה. בוחרים פתק מהמגש, ושמים אותו בקלפי.", "pick.card", "", "the ballot booth (2026-10-03)", "The big card before any slip is chosen (first launch)")
e("LEADER_PICK_BLANK", "פתק לבן", "pick.name", "", "the ballot booth (2026-10-03)", "The big card's name for the blank slip (הפתעה)")
e("LEADER_PICK_SECRET", "מתמודד סודי", "pick.chip", "", "the ballot booth (2026-10-03, Bar: no name on a blurred card)", "The big card's name line for a slip in print: never the leader's name")
e("LEADER_PICK_RANDOM", "הפתעה", "pick.name", "*", "leaderSelect.pick.copy.random", "The random tile: the grid centre (3x3) or the full-width bar (wave 1, 2x2)")
e("LEADER_PICK_RANDOM_CAP", "דובי בוחר בשבילך. גם הוא עוד לא יודע את מי.", "pick.strip", "*", "rtl-map §8.4", "The strip line while the random tile is focused or pressed (its 'blurb')")
e("LEADER_PICK_RANDOM_LINE", "דובי בחר. הוא יחזור על זה.", "stage.toast", "*", "leaderSelect.pick.copy.randomLine", "Dubi's bubble after a random pick, instead of DUBI_LEARNED")
e("LEADER_PICK_DISCLAIMER", "לכל מנהיג חוק משלו. אף אחד לא מנצח.", "pick.strip", "L", "leaderSelect.pick.copy.disclaimer", "The strip's default line (nothing focused or pressed)")
e("LEADER_PICK_UNDO", "להחליף ראש רשימה", "pick.undo", "", "leaderSelect.pick.copy.undo ('להחליף'); rtl-map §8.6", "The stage chip for undoSec after a pick, until the first tap. 'להחליף' alone does not say what changes, at the bottom of a stage")
e("LEADER_PICK_FRESH", "פנים חדשות: ⟦+{pct}%⟧ בונוס בחירות בסבב הבחירות הזה", "stage.toast", "*", "leaderSelect.pick.copy.freshFace", "Toast after a pick that differs from the last round's leader")
e("LEADER_PICK_PLATE", "{short} · {party}", "stage.toast", "", "rtl-map §8.6 (the round-start lower third)", "The first toast of a round, as the leader walks in")
e("LEADER_PICK_CARD_RULE", "הכלל המיוחד: {rule}", "modal.body", "", "spec §5.1 (rule.name; rule.text under it, box pick.card)", "Leader card only; hidden for a leader without a `rule` (Bibi: his signature is the court)")
e("LEADER_PICK_CARD_GO", "לשחק בתור {short}", "modal.btnFull", "", "rtl-map §8.5", "Role play, never 'לבחור ב…' (reads as 'elect X': an endorsement)")
e("DUBI_LEARNED", "דובי למד מסרים חדשים.", "stage.toast", "*", "leaderSelect.pick.copy.dubiLearned", "Dubi's bubble at every pick (D8)")
e("F9_PICK", "בכל סבב בחירות אפשר להחליף ראש רשימה. הבסיס נשאר.", "pick.strip", "", "leaderSelect.pick.copy.ftueAfterFirstElection; ftue.md LP", "The strip's default line on the first picker after election 1 (ftue.lp), in place of LEADER_PICK_DISCLAIMER")
# --- HUD and screens around the leader
e("ELECT_LEADER", "{short} · {party}", "modal.body", "", "spec §6.1 (the election card names the leader)", "O3: a line under ELECT_TITLE ('סבב בחירות מס׳ 999 · סמוטריץ׳' is 536 px, over the 432 title box)")
e("DOS_STATUS_LEADER", "{short} · {party}", "tall.status", "", "rtl-map §6.3 T4 header", "T4 header status line: this round's leader")
e("DOS_LEADERS", "ראשי רשימה", "dos.row", "", "spec §6.2 T4 section", "Section header; one row per leader played, in first-played order (never sorted by a count: that is a ranking)")
e("DOS_LEADER_ROUNDS_ONE", "{short} · סבב בחירות אחד", "dos.row", "", "spec §6.2 leaders.<id>.rounds")
e("DOS_LEADER_ROUNDS_TWO", "{short} · שני סבבי בחירות", "dos.row", "", "spec §6.2")
e("DOS_LEADER_ROUNDS_OTHER", "{short} · ⟦{n}⟧ סבבי בחירות", "dos.row", "", "spec §6.2")
e("DOS_LEADER_TAPS", "{verbPlural}: ⟦{n}⟧ · {critPlural}: ⟦{c}⟧", "dos.row", "", "spec §6.2 leaders.<id>.taps / crits", "Muted second line of a leader row, in the kit's own nouns")
e("BUFF_CHIP_TAPFRENZY_LEADER", "{verb} ⟦×{mult}⟧ · ⟦{s}⟧ שנ׳", "stage.buffChip", "", "spec §10.3 BUFF_CHIP_TAPFRENZY", "{verb} = kit.tap.verb")
e("BANNER_FRENZY_LEADER", "{banner} ⟦×{mult}⟧", "stage.banner", "*", "spec §10.3 BANNER_FRENZY", "{banner} = kit.tap.frenzyBanner")
e("SPIN_EFFECT_S01_LEADER", "⟦+0.30⟧~₪ לכל {verb}", "card.line2wide", "", "spec §10.3 spin s01 (slot A)", "Replaces upgradeEffects.s01 for every leader once the picker ships")
e("SPIN_EFFECT_S02_LEADER", "{verb} ⟦×1.5⟧ · ⟦{s}⟧ שנ׳", "card.line2wide", "", "spec §10.3 spin s02 (slot B)", "{s} = the next buy's seconds (Spins.card nextSec; fatigue shortens a rebuy, never weakens it)")
e("SPIN_EFFECT_S11_LEADER", "{critName}: סיכוי ⟦+5%⟧", "card.line2wide", "", "spec §10.3 spin s11 (slot E)", "s07 is Bibi-only, so upgradeEffects.s07 keeps 'שליפה'")
# --- the press skin (every leader but Bibi; spec §5.6, leaderSelect.hazardSkins.press). Same geometry as the court.
e("PRESS_SUSP", "כותרות", "stage.thermo", "", "hazardSkins.press.meterName")
e("PRESS_SUSP_HOT", "חם", "stage.thermo", "", "hazardSkins.press.hotWords[0]")
e("PRESS_SUSP_BOIL", "רותח", "stage.thermo", "", "hazardSkins.press.hotWords[1]")
e("PRESS_REVEAL", "נפתח עליך תחקיר.", "stage.toast", "*", "hazardSkins.press.revealToast", "K2 for a press leader (instead of TOAST_DOSSIER)")
e("PRESS_TITLE", "יום תחקיר", "modal.title", "", "hazardSkins.press.dayTitle")
e("PRESS_BODY_M", "{short} מגיב לתחקיר. ההכנסות מואטות.", "court.body", "", "hazardSkins.press.dayBody")
e("PRESS_BODY_F", "{short} מגיבה לתחקיר. ההכנסות מואטות.", "court.body", "", "hazardSkins.press.dayBodyF")
e("PRESS_EFFECT", "הכנסות ⟦×0.5⟧, בלי הקשות, עד סוף התגובה", "court.body", "", "hazardSkins.press.dayEffect")
e("PRESS_TIMER", "תגובה: ⟦{mmss}⟧", "court.body", "", "COURT_TIMER's twin")
e("PRESS_SUMMONS_TITLE", "תחקיר בדרך", "modal.title", "", "hazardSkins.press.summonsTitle")
e("PRESS_SUMMONS_BODY", "תחקיר עליך עולה הערב. אפשר לדחות, אפשר להגיב.", "court.body", "*", "hazardSkins.press.summonsBody")
e("PRESS_SUMMONS_EFFECT", "בזמן התגובה: הכנסות ⟦×0.5⟧, בלי הקשות", "court.body", "", "COURT_SUMMONS_EFFECT's twin")
e("PRESS_SUMMONS_TIMER", "התגובה מתחילה בעוד ⟦{mmss}⟧", "court.body", "", "COURT_SUMMONS_TIMER's twin")
e("PRESS_TESTIFY", "להגיב", "court.btn2", "", "hazardSkins.press.testifyVerb")
e("PRESS_POSTPONE", "{postpone} · ⟦{price}⟧~₪", "html:40", "", "COURT_POSTPONE's twin", "Accessible label; drawn as kit.hazard.postponeVerb over CARD_PRICE")
e("PRESS_CHIP", "יום תחקיר · ⟦{mmss}⟧", "html:20", "", "COURT_CHIP's twin (a11y)")
e("PRESS_CHIP_TITLE", "יום תחקיר", "ticker.chipWide", "", "hazardSkins.press.dayTitle (chip line 1)")
e("PRESS_CHIP_SUMMONS", "תחקיר", "ticker.chip", "", "hazardSkins.press.chip (chip line 1 during the summons)")
e("PRESS_END", "התגובה פורסמה. הקצב חזר.", "stage.toast", "", "hazardSkins.press.endToast")
e("PRESS_SUSP_FLOOR", "כותרות שנשארו מסבבים קודמים: ⟦{pct}%⟧", "dos.row", "*", "DOS_SUSP_FLOOR's twin")
e("PRESS_DAYS", "ימי תחקיר: ⟦{n}⟧", "dos.row", "", "DOS_COURT_DAYS's twin", "Needs a press-day count in the sim (stats); DOS_COURT_DAYS then shows only when > 0")
# --- Liberman's rule (spec §9.4.3; the words are leaders.liberman.rule.copy)
e("CHAT_PILL_DECLINE", "לא אשב", "chat.pill", "*", "leaders.liberman.rule.copy.pill", "Second pill under a member demand's pay pill (rtl-map §6.3), Liberman's round only; never on an ultimatum or a join demand")
e("CHAT_PILL_DECLINE_CD", "לא אשב · ⟦{s}⟧ שנ׳", "chat.pill", "", "leaders.liberman.rule.copy.cooldown", "The same pill, disabled, during the 90 s cooldown")
e("CHAT_SYS_DECLINED", "הדרישה של {name} נדחתה · לא אשב", "chat.sys", "*", "leaders.liberman.rule.copy.sys", "Gender-free: one key")
# --- staged replacements: SHARE_TEXT_INVITE_NEXT, OG_DESCRIPTION_NEXT and OG_IMAGE_ALT_NEXT were promoted
#     into their base keys when the picker shipped (2026-09-29, game-developer engine).
# --- Golan's rule (spec §5.1 mergeMembers; the words are leaders.golan.rule.copy, mirrored verbatim)
e("CHAT_PILL_MERGE", "לאחד", "chat.pill", "*", "leaders.golan.rule.copy.pill", "A second pill on a member's partner card (Golan's round only): opens the pair prompt")
e("CHAT_PILL_MERGE_CD", "איחוד · ⟦{s}⟧ שנ׳", "chat.pill", "", "leaders.golan.rule.copy.cooldown", "The same pill, disabled, during the 120 s cooldown")
e("MERGE_PICK_TITLE", "לאחד עם…", "modal.title", "", "leaders.golan.rule.copy.pickPrompt", "The pair prompt: one full-width button per candidate (Coalition.merge_candidates)")
e("CHAT_SYS_MERGED", "{a} ו{b} התאחדו. מעכשיו: {a}־{b}.", "chat.sys", "*", "leaders.golan.rule.copy.sys", "Gender-free: one key")
e("CHAT_SYS_MERGE_READY", "{a} ו{b} יכולים להתאחד", "chat.sys", "*", "ux mobile-first-layout §5.5", "The thread's merge-ready notice (Golan's round): a system line with the לאחד pill under it; posted when a pair first qualifies with the cooldown at 0, again after each cooldown (≥ 120 s apart). Gender-free: one key")

# --- seeded rounds (game-developer, 2026-10-02; Bar approved): "תעבור אותי" (the challenge link) and "הסבב היומי"
#     (the daily round). The ghost chip takes the ticker's date-chip slot (the court chip's geometry: two tight lines).
e("CHALLENGE_TITLE", "תעבור אותי", "modal.title", "", "seeded rounds: the challenge intro card", "A friend's challenge link opened")
e("CHALLENGE_INTRO_BODY", "מישהו הגיע ל־⟦61⟧ ב־⟦{mmss}⟧ בתור {short}. אותו סבב, אותה חלוקה, אותם אירועים. מי מהיר יותר?", "modal.body", "", "seeded rounds")
e("CHALLENGE_INTRO_BACK", "התשובה הגיעה: ⟦{mine}⟧ מול ⟦{theirs}⟧ שלך. עוד סיבוב?", "modal.body", "", "seeded rounds: a return link (vs)", "{mine} = the friend's time (t), {theirs} = the time it answered (vs)")
e("CHALLENGE_SANDBOX", "סבב נפרד: המשחק שלך לא משתנה.", "modal.body", "", "seeded rounds: save isolation, said out loud")
e("CHALLENGE_GO", "לקבל את האתגר", "modal.btnFull", "", "seeded rounds")
e("CHALLENGE_LATER", "לא עכשיו", "modal.btnFull", "", "seeded rounds")
e("CHALLENGE_CHIP", "האתגר", "ticker.chipWide", "", "seeded rounds: the ghost chip, line 1", "The ticker's date-chip slot during a challenge round")
e("CHALLENGE_CHIP_TIME", "⟦{mmss}⟧", "ticker.chip", "", "seeded rounds: the ghost chip, line 2", "The challenger's time left, counting down")
e("CHALLENGE_CHIP_OVER", "⟦+{mmss}⟧", "ticker.chip", "", "seeded rounds: the ghost chip past the challenger's time", "Drawn in red_hi, counting up")
e("CHALLENGE_WIN", "ניצחת ב־⟦{mmss}⟧", "modal.title", "*", "seeded rounds: the result", "{mmss} = your time")
e("CHALLENGE_LOSE", "הפסדת ב־⟦{mmss}⟧", "modal.title", "*", "seeded rounds: the result", "{mmss} = the gap")
e("CHALLENGE_TIE", "תיקו ב־⟦{mmss}⟧", "modal.title", "*", "seeded rounds: the result")
e("CHALLENGE_VS", "הזמן שלך: ⟦{mine}⟧ · האתגר: ⟦{theirs}⟧", "modal.body", "", "seeded rounds: the result")
e("CHALLENGE_SEND_BACK", "לשלוח בחזרה", "modal.btnFull", "", "seeded rounds: the return link (the brief's 'שלח לו בחזרה' in the buttons' infinitive voice)")
e("CHALLENGE_BACK_MAIN", "להמשיך למשחק שלי", "modal.btnFull", "", "seeded rounds")
e("CHALLENGE_START_MAIN", "להתחיל משחק משלי", "modal.btnFull", "", "seeded rounds: a new player after the round")
e("CHALLENGE_OFFER_TITLE", "אתגר חבר", "modal.title", "", "seeded rounds: the offer after an election / from T4")
e("CHALLENGE_OFFER_BODY", "הגעת ל־⟦61⟧ ב־⟦{mmss}⟧ בתור {short}. החבר מקבל את אותו ראש רשימה מאפס: מי יגיע מהר יותר?", "modal.body", "", "seeded rounds")
e("CHALLENGE_OFFER_NOTE", "החבר משחק סבב ראשון, בלי הבסיס שלך.", "modal.body", "*", "seeded rounds: the fairness note")
e("CHALLENGE_SEND", "לשלוח אתגר", "modal.btnFull", "", "seeded rounds")
e("CHALLENGE_DOS_BTN", "אתגר חבר", "dos.btn", "", "seeded rounds: T4's row")
e("CHALLENGE_TOAST", "אתגר חבר: מי יעבור את ⟦{mmss}⟧?", "stage.toast", "", "seeded rounds: after an election's pick; a tap opens the offer")
e("CHALLENGE_SHARE_TEXT", "הגעתי ל־61 ב־{mmss} בתור {short} ב״עוד סבב״. תעבור אותי? {url}", "share-text:90", "*", "seeded rounds")
e("CHALLENGE_SHARE_WIN", "עברתי אותך ב״עוד סבב״: {mine} מול {theirs}. נראה אותך שוב? {url}", "share-text:90", "*", "seeded rounds: the return link")
e("CHALLENGE_SHARE_LOSE", "הגעתי ל־61 ב־{mine}. היית מהיר יותר ({theirs}). עוד סבב? {url}", "share-text:90", "*", "seeded rounds: the return link")
e("CHALLENGE_SHARE_TIE", "תיקו ב״עוד סבב״: שנינו ב־{mine}. מכריעים? {url}", "share-text:90", "*", "seeded rounds: the return link")
e("ROUND_QUIT_TITLE", "לצאת מהסבב?", "modal.title", "", "seeded rounds: a tap on the ghost chip")
e("ROUND_QUIT_BODY", "התוצאה לא תישמר. המשחק שלך מחכה בדיוק איפה שעצרת.", "modal.body", "", "seeded rounds")
e("ROUND_QUIT_GO", "לצאת", "modal.btnHalf", "", "seeded rounds")
e("ROUND_QUIT_STAY", "להישאר", "modal.btnHalf", "", "seeded rounds")
e("DAILY_TITLE", "הסבב היומי ⟦#{n}⟧", "modal.title", "", "seeded rounds: the daily card")
e("DAILY_BODY", "היום כולם משחקים את אותו הסבב: אותו ראש רשימה, אותה חלוקה, אותם אירועים. הזמן עד ⟦61⟧ קובע.", "modal.body", "", "seeded rounds")
e("DAILY_ONCE", "ניסיון רשמי אחד ביום. המשחק שלך לא משתנה.", "modal.body", "", "seeded rounds")
e("DAILY_GO", "לשחק", "modal.btnFull", "", "seeded rounds")
e("DAILY_REPLAY", "לשחק שוב · לא נספר", "modal.btnFull", "", "seeded rounds: after the official attempt")
e("DAILY_SHARE", "לשתף", "modal.btnFull", "", "seeded rounds")
e("DAILY_TODAY", "היום: ⟦{mmss}⟧", "modal.body", "", "seeded rounds: today's official result")
e("DAILY_YESTERDAY", "אתמול: ⟦{mmss}⟧", "modal.body", "", "seeded rounds: yesterday's grid")
e("DAILY_STREAK_ONE", "רצף: יום אחד", "modal.body", "", "seeded rounds")
e("DAILY_STREAK_TWO", "רצף: יומיים", "modal.body", "", "seeded rounds")
e("DAILY_STREAK_OTHER", "רצף: ⟦{n}⟧ ימים", "modal.body", "", "seeded rounds")
e("DAILY_RESULT", "סיימת ב־⟦{mmss}⟧", "modal.title", "", "seeded rounds: the daily result")
e("DAILY_UNOFFICIAL", "ניסיון חוזר: לא נספר. הרשמי: ⟦{mmss}⟧", "modal.body", "", "seeded rounds")
e("DAILY_COURT_NO", "התחמקתי", "modal.body", "*", "seeded rounds: the grid's court line (and the share text's)")
e("DAILY_COURT_YES", "העידו אותי", "modal.body", "*", "seeded rounds: a court day was served")
e("DAILY_PRESS_YES", "הגבתי לתחקיר", "modal.body", "*", "seeded rounds: a press day was served (every leader but Bibi)")
e("DAILY_CHIP", "יומי ⟦#{n}⟧", "ticker.chipWide", "", "seeded rounds: the round chip, line 1 (line 2: CHALLENGE_CHIP_TIME, counting up)")
e("DAILY_DOS_BTN", "הסבב היומי", "dos.btn", "", "seeded rounds: T4's row")
e("DAILY_PICK_BTN", "הסבב היומי ⟦#{n}⟧", "pick.daily", "", "seeded rounds: the picker's entry")
e("DAILY_TOAST", "הסבב היומי ⟦#{n}⟧ מחכה. כולם משחקים אותו היום.", "stage.toast", "", "seeded rounds: once a day on load; a tap opens the daily card")
e("DAILY_SHARE_HEAD", "עוד סבב #{n}", "share-text:20", "", "seeded rounds: the grid text's head line (a Hebrew word first, for the bidi)")
# ================= missions + ranks (Bar 2026-10-02; sim game/scripts/sim/missions.gd, content `missions`) =================
e("MIS_CHIP", "משימות", "stage.missions", "", "missions.chip", "The stage's missions entry (MissionsChip, the top-left sky); a gold badge counts the missions done")
e("MIS_CHIP_READY", "לקחת!", "stage.missions", "", "missions.chip.ready", "The chip's second line while a mission is done (else the nearest mission's MIS_PROGRESS)")
e("MIS_TITLE", "משימות", "modal.title", "", "missions.title")
e("MIS_RANK", "דרגה ⟦{n}⟧: {rankTitle}", "modal.body", "", "missions.rank", "Gold, centred, over the rank's progress bar; rankTitle = missions.ranks[].title")
e("MIS_NEXT_ONE", "עוד משימה אחת לדרגת {rankTitle}: ⟦+{pct}%⟧ הכנסה", "modal.body", "", "missions.next")
e("MIS_NEXT_OTHER", "עוד ⟦{n}⟧ משימות לדרגת {rankTitle}: ⟦+{pct}%⟧ הכנסה", "modal.body", "", "missions.next")
e("MIS_BONUS", "בונוס הדרגה: ⟦+{pct}%⟧ הכנסה, לתמיד", "modal.body", "", "missions.bonus", "The sum of the ranks reached (a global income multiplier in Economy.derive)")
e("MIS_TOP", "אין לאן לעלות. רק להישאר.", "modal.body", "*", "missions.top", "The last rank, every mission claimed")
e("MIS_EMPTY", "אין משימות פתוחות. הלשכה בפגרה.", "modal.body", "*", "missions.empty")
e("MIS_CLAIM", "לקחת", "mis.btn", "", "missions.claim", "Gold kit button on a done mission's row: pays the reward, the next mission takes the row")
e("MIS_PROGRESS", "⟦{val}/{goal}⟧", "mis.progress", "", "missions.progress", "Counts as integers, money (earnRun, bpsAtLeast) through Fmt.amount")
e("MIS_REWARD_CASH", "⟦+{x}⟧~₪", "mis.reward", "", "missions.reward.cash", "reward cash {sec}: sec × ₪/s now (at least the floor), priced live")
e("MIS_REWARD_FRENZY", "הכנסה ⟦×{mult}⟧ · ⟦{s}⟧ שנ׳", "mis.reward", "", "missions.reward.frenzy", "The Suitcase's income frenzy (golden bpsFrenzy's multiplier)")
e("MIS_REWARD_BASE", "⟦+{pct}%⟧ בונוס בחירות", "mis.reward", "", "missions.reward.basePct", "+pct on this round's base payout")
e("F_MISSION_DONE", "משימה הושלמה: {mission}", "ticker.crawl", "", "missions.done", "Ticker milestone line + the milestone cue when a mission's goal is met")
e("F_RANK_UP", "עלית בדרגה: {rankTitle} · ⟦+{pct}%⟧ הכנסה", "stage.toast", "", "missions.rankUp", "The rank-up toast (lane dock) and ticker milestone, with confetti and the trophy cue")

# ---------------------------------------------------------------- content names (copy deck §C, §D)
PRODUCERS = [  # fork id -> (deck name, plural)
    ("intern", "משלם המסים", "משלמי המסים"),
    ("tree", "ההייטקיסט", "ההייטקיסטים"),
    ("hardhat", "המע״מ", "המע״מ"),
    ("bureaucrat", "החבר הנדיב", "החברים הנדיבים"),
    ("catapult", "הצוללת", "הצוללות"),
    ("rocket", "היועצים הקטאריים", "היועצים הקטאריים"),
    ("timechimp", "מכונת הרעל", "מכונות הרעל"),
    ("moon", "פנקס הצ׳קים הזהוב", "פנקסי הצ׳קים"),
]
SPINS = [  # deck id -> (name, short effect label from the designer's effect column)
    ("s01", "פיקדון על בקבוקים", "⟦+0.30⟧~₪ לכל שליפה"),
    ("s02", "גלידת פיסטוק", "שליפה ⟦×1.5⟧ · ⟦{s}⟧ שנ׳"),
    ("s03", "ביביסיטר", "כשאתה לא פה: ⟦×2⟧"),
    ("s04", "לא יהיה כלום", "חשד ⟦−25%⟧"),
    ("s05", "ציד מכשפות", "קלף נגדך: ⟦+1⟧ בסיס"),
    ("s06", "כנף ציון", "הכנסה ⟦×1.5⟧"),
    ("s07", "סופר־ספרטה", "⟦{s}⟧ שנ׳: הכול לשליפה"),
    ("s08", "השלט", "בונוס בחירות + חשד"),
    ("s09", "פייג׳ר זהב", "פנקס הצ׳קים ⟦×1.5⟧"),
    ("s10", "מזוודות כביסה", "כל טיסה: ⟦+5%⟧ הכנסה"),
    ("s11", "באגס באני", "סיכוי לארנב ⟦+5%⟧"),
    ("s12", "הוחלט להקים ועדה", "החשד קפוא ⟦{s}⟧ שנ׳"),
    ("s13", "ראיון בערוץ ידידותי", "בונוס בחירות ⟦+10%⟧"),
    ("s14", "סרטון ויראלי", "מכונות הרעל ⟦×2⟧"),
    ("s15", "ביקור ממלכתי", "מוחק חשד סיגרים"),
]

# ---------------------------------------------------------------- helpers
def conv(v, surface):
    v = v.replace("~₪", NBSP + "₪")
    if surface in ("share-text", "og"):
        return v.replace("⟦", "").replace("⟧", "")
    return v.replace("⟦", LRI).replace("⟧", PDI)

def plain_for_measure(v):
    for k, s in PH.items():
        v = v.replace("{" + k + "}", s)
    return v.replace("⟦", "").replace("⟧", "").replace("~₪", " ₪").replace(NBSP, " ").replace("−", "−")

missing_glyphs = set()
# Widths are measured exactly as the engine lint does (game/tests/lint/lint_text.gd):
#   label  -> TextServer on the shipping font: the sum of the .fnt xadvance values (bidi controls 0)
#   pxtext -> the fork's monospace bitmap route: 6*n - 1 font px (Art.measure)
FNT = os.path.normpath(os.path.join(OUT, "..", "game", "assets", "fonts", "sevev9.fnt"))
XADV = {}
for _ln in open(FNT, encoding="utf-8"):
    if _ln.startswith("char "):
        _kv = dict(x.split("=", 1) for x in _ln.split()[1:] if "=" in x)
        XADV[chr(int(_kv["id"]))] = int(_kv["xadvance"])
ZERO_W = {LRI, PDI, "\u2067", "\u2068", "\u200e", "\u200f", "\u202a", "\u202b", "\u202c", "\u202d", "\u202e", "\ufe0e", "\ufe0f"}
PX_MODE = [False]

def measure(t):
    if PX_MODE[0]:
        return max(0, 6 * len(t) - 1)
    w = 0
    for ch in t:
        if ch in ZERO_W:
            continue
        if ch in XADV:
            w += XADV[ch]
        else:
            missing_glyphs.add(ch)
            w += 8
    return w

def wrap_lines(t, box_w, scale):
    words, lines, cur = t.split(" "), 0, ""
    for wd in words:
        cand = wd if not cur else cur + " " + wd
        if measure(cand) * scale <= box_w:
            cur = cand
        else:
            if cur:
                lines += 1
            cur = wd
            if measure(cur) * scale > box_w:
                return 99  # a single word overflows
    return lines + (1 if cur else 0)

def surface_of(box, value):
    if ":" in box and box.split(":")[0] in ("html", "share-text", "og"):
        return box.split(":")[0], int(box.split(":")[1])
    if box == "unused":
        return "unused", None
    text_ph = [m for m in re.findall(r"\{(\w+)\}", value) if m not in NUMERIC_PH]
    has_heb = bool(HEB.search(value)) or "₪" in value or bool(text_ph) or "⟦" in value  # a text placeholder carries Hebrew; an isolate needs the RTL route
    return ("label" if has_heb else "pxtext"), None

# isolate check: in a canvas Hebrew string every digit and numeric placeholder must be isolated
PH_RE = re.compile(r"\{(\w+)\}")
def isolate_problems(v):
    probs, depth = [], 0
    i = 0
    while i < len(v):
        ch = v[i]
        if ch == "⟦": depth += 1
        elif ch == "⟧": depth -= 1
        elif ch == "{":
            j = v.index("}", i)
            name = v[i + 1:j]
            if name in NUMERIC_PH and depth == 0:
                probs.append("{" + name + "}")
            i = j
        elif ch.isdigit() and depth == 0:
            probs.append(ch)
        i += 1
    return probs

# ---------------------------------------------------------------- build
strings, budgets, report = {}, {}, []
errors, warnings = [], []
seen = set()
for key, value, box, flags, spec, note in E:
    assert key not in seen, key
    seen.add(key)
    surf, cap = surface_of(box, value)
    out = conv(value, surf)
    strings[key] = out
    b = {"surface": surf}
    if spec: b["spec"] = spec
    if "*" in flags: b["joke"] = True
    if "L" in flags: b["legal"] = True
    if "G" in flags: b["deckWords"] = True
    if note: b["note"] = note
    if surf in ("html", "share-text", "og"):
        n = len(plain_for_measure(value.replace(" {url}", "").replace("{url}", "")))   # "≤ N + URL" (first-minute §5.3): the URL is not counted
        b["maxChars"] = cap
        if n > cap:
            errors.append(f"{key}: {n} chars > {cap}")
    elif surf in ("label", "pxtext"):
        bw, sc, ln, lnl, _ = BOXES[box]
        b["box"] = box
        if bw is None:
            b["maxChars"] = 60
            n = len(plain_for_measure(value))
            if n > 60: warnings.append(f"{key}: ticker line {n} > 60 chars")
        else:
            t = plain_for_measure(value)
            PX_MODE[0] = (surf == "pxtext")
            b["maxChars"] = max(1, bw // (6 * sc))
            if surf == "label" and HEB.search(value):
                probs = isolate_problems(value)
                if probs:
                    errors.append(f"{key}: numeric not isolated: {probs}")
            w_base = measure(t) * sc
            large = sc + 1 if sc == 4 else sc
            lines_base = 1 if w_base <= bw else wrap_lines(t, bw, sc)
            lines_large = wrap_lines(t, bw, large) if measure(t) * large > bw else 1
            b["worstPx"] = {str(sc): w_base, str(large): measure(t) * large}
            ok_base = lines_base <= ln
            ok_large = lines_large <= lnl or ok_base  # labels may step down one scale
            if not ok_base:
                (errors if "*" in flags or ln == 1 else warnings).append(
                    f"{key}: {w_base}px @x{sc} in {box} ({bw}px, {ln} line) -> {lines_base} lines")
            elif lines_large > lnl:
                b["largeText"] = "step-down"
            report.append((key, box, w_base, bw, lines_base, lines_large))
            PX_MODE[0] = False
    budgets[key] = b

ALIASES = {  # first-minute §8 mechanical key -> the fork key that already holds the string
    "HUD_RATE": "HUD_BPS", "HUD_TICKER_TAG": "TICKER_TAG", "CARD_LOCKED_NAME": "ROW_LOCKED_NAME",
    "SET_G_SOUND": "SET_GROUP_SOUND", "SET_G_COMFORT": "SET_GROUP_A11Y", "SET_G_GAME": "SET_GROUP_GAME",
    "SET_MOTION": "SET_REDUCED_MOTION", "SET_VIBE": "SET_HAPTICS", "RESET_TITLE": "RST_TITLE",
    "RESET_JOKE": "RST_BODY_1", "RESET_BODY": "RST_BODY_2", "RESET_CANCEL": "RST_CANCEL",
    "RESET_GO": "RST_CONFIRM", "SYS_ROTATE": "ROTATE",
}
for a, src in ALIASES.items():
    assert a not in strings and src in strings, a
    strings[a] = strings[src]
    budgets[a] = {"aliasOf": src, **{k: v for k, v in budgets[src].items() if k != "spec"}}

# coverage: every ID in first-minute §8 must resolve mechanically
FM = os.path.normpath(os.path.join(OUT, "..", "..", "..", "artifacts", "creative-pack", "od-sevev", "ux", "first-minute.md"))
if os.path.exists(FM):
    txt = open(FM, encoding="utf-8").read()
    sec = txt[txt.index("## 8. Microcopy table"):txt.index("## 9.")]
    ids = []
    for line in sec.splitlines():
        if not line.startswith("| ") or line.startswith("| ID") or line.startswith("|---"):
            continue
        cell = line.split("|")[1].strip()
        if "*" in cell:
            continue
        parts = [x.strip() for x in cell.split("/")]
        first = parts[0]
        prefix = first[:first.rfind(".") + 1]
        ids.append(first)
        ids += [prefix + x.lstrip(".") for x in parts[1:]]
    VAR = ["", "_M", "_ONE", "_OTHER"]
    GROUPS = {"dos.stats": ["DOS_ROUNDS", "DOS_COURT_DAYS", "DOS_POSTPONES", "DOS_TOTAL", "DOS_CAUGHT", "DOS_ARRIVED"]}
    unresolved = [i for i in ids if not any(i.upper().replace(".", "_") + v in strings for v in VAR)
                  and not all(k in strings for k in GROUPS.get(i, ["-"]))]
    print("first-minute §8 ids:", len(ids), "| unresolved:", unresolved)
    if unresolved:
        errors.append(f"unresolved §8 ids: {unresolved}")

prod_names = {pid: n for pid, n, _ in PRODUCERS}
prod_plurals = {pid: p for pid, _, p in PRODUCERS}
upg_names = {sid: n for sid, n, _ in SPINS}
upg_effects = {sid: conv(eff, "label") for sid, _, eff in SPINS}
for pid, n, _ in PRODUCERS:
    w = measure(n) * 4
    if w > 360: errors.append(f"producer {pid}: {w}px > 360 (card.name)")
for sid, n, eff in SPINS:
    if measure(n) * 4 > 360: errors.append(f"spin {sid}: name {measure(n)*4}px")
    w = measure(plain_for_measure(eff)) * 4
    if w > 360: errors.append(f"spin {sid}: effect {w}px > 360 (card.line2wide)")
    if isolate_problems(eff): errors.append(f"spin {sid}: effect not isolated")

# the names that actually render come from design/content.json (the Game Designer owns them)
CONTENT = os.path.normpath(os.path.join(OUT, "..", "design", "content.json"))
if os.path.exists(CONTENT):
    cj = json.load(open(CONTENT, encoding="utf-8"))
    for grp in ("producers", "upgrades"):
        for it in cj.get(grp, []):
            n = str(it.get("name", ""))
            w = measure(n) * 4
            if w > 360:
                errors.append(f"content {grp}.{it.get('id')} name {w}px > 360 (card.name)")
            if grp == "upgrades" and it.get("id") not in upg_effects:
                errors.append(f"content upgrade {it.get('id')} has no UI effect label in SPINS")
    print("content names linted:", sum(len(cj.get(g, [])) for g in ("producers", "upgrades")))

    # ---- leader select: the roster's words in the picker and HUD boxes (rtl-map §8), on the shipping font
    def lint_content(path, text, box, joke=False):
        bw, sc, ln, lnl, _ = BOXES[box]
        t = plain_for_measure(text)
        n = wrap_lines(t, bw, sc) if measure(t) * sc > bw else 1
        if n > ln:
            (errors if joke or ln == 1 else warnings).append(f"content {path}: {measure(t) * sc}px @x{sc} in {box} ({bw}px, {ln} line) -> {n} lines")
        return n
    nl = 0
    for L in cj.get("leaders", []):
        lid = L.get("id")
        for fld, box in (("short", "pick.name"), ("party", "pick.party")):
            lint_content(f"leaders.{lid}.{fld}", str(L.get(fld, "")), box); nl += 1
        pk = L.get("pick") or {}
        if pk.get("blurb"):
            lint_content(f"leaders.{lid}.pick.blurb", pk["blurb"], "pick.strip"); nl += 1
        if pk.get("line"):
            lint_content(f"leaders.{lid}.pick.line", pk["line"], "stage.toast", True); nl += 1
        r = L.get("rule")
        if isinstance(r, dict):
            lint_content(f"leaders.{lid}.rule.text", r.get("text", ""), "pick.card"); nl += 1
            act = r.get("active")
            if isinstance(act, dict):
                for ck, cv in (act.get("copy") or {}).items():
                    box = "stage.ability" if ck.startswith("btn") else ("pick.card" if ck == "desc" else "stage.toast")
                    lint_content(f"leaders.{lid}.rule.active.copy.{ck}", cv, box, box == "stage.ability"); nl += 1
        k = L.get("kit")
        if isinstance(k, dict):
            tp = k.get("tap", {})
            for fld in ("verbPlural", "critPlural"):
                lint_content(f"leaders.{lid}.kit.tap.{fld}", tp.get(fld, ""), "dos.row"); nl += 1
            lint_content(f"leaders.{lid}.kit.tap.critName", tp.get("critName", ""), "stage.floater", True); nl += 1
            hz = k.get("hazard")
            if isinstance(hz, dict):
                lint_content(f"leaders.{lid}.kit.hazard.postponeVerb", hz.get("postponeVerb", ""), "court.btn", True); nl += 1
                lint_content(f"leaders.{lid}.kit.hazard.postponePrefix", hz.get("postponePrefix", ""), "court.body"); nl += 1
                if hz.get("tapPaused"):
                    lint_content(f"leaders.{lid}.kit.hazard.tapPaused", hz["tapPaused"], "stage.toast"); nl += 1
            sq = (k.get("dubi") or {}).get("squawks") if isinstance(k.get("dubi"), dict) else None
            for sk, sv in (sq or {}).items():
                lint_content(f"leaders.{lid}.kit.dubi.squawks.{sk}", sv, "stage.toast", True); nl += 1
            un = k.get("unity")
            if isinstance(un, dict) and un.get("refuse"):
                lint_content(f"leaders.{lid}.kit.unity.refuse", un["refuse"], "stage.toast", True); nl += 1
    # leaders v3 phase 3: the shared unity offer (leaderSelect.unityOffer.copy)
    for ck, cv in ((cj.get("leaderSelect", {}).get("unityOffer") or {}).get("copy") or {}).items():
        box = "stage.ability" if ck.startswith("btn") else "stage.toast"
        lint_content(f"leaderSelect.unityOffer.copy.{ck}", cv, box, True); nl += 1
    print("leader words linted:", nl)

    # ---- missions (content missions.list[].text in the sheet's mis.text box; rank titles via MIS_RANK's PH)
    nm = 0
    for m in (cj.get("missions") or {}).get("list", []):
        lint_content(f"missions.{m.get('id')}.text", _mis_fill(m.get("text", "")), "mis.text", True); nm += 1
    print("mission texts linted:", nm)

    # ---- drift: the UI keys that mirror the designer's leader-select copy must say the same thing
    ls = cj.get("leaderSelect", {})
    pc = (ls.get("pick") or {}).get("copy", {})
    pr = (ls.get("hazardSkins") or {}).get("press", {})
    lib = next((L.get("rule", {}).get("copy", {}) for L in cj.get("leaders", []) if L.get("id") == "liberman"), {})
    MIRROR = {
        "LEADER_PICK_TITLE": pc.get("title"), "LEADER_PICK_TITLE_AFTER": pc.get("titleAfter"),
        "LEADER_PICK_AGAIN": pc.get("again"), "LEADER_PICK_RANDOM": pc.get("random"),
        "LEADER_PICK_RANDOM_LINE": pc.get("randomLine"), "LEADER_PICK_FRESH": pc.get("freshFace"),
        "LEADER_PICK_DISCLAIMER": pc.get("disclaimer"), "DUBI_LEARNED": pc.get("dubiLearned"),
        "F9_PICK": pc.get("ftueAfterFirstElection"),
        "PRESS_SUSP": pr.get("meterName"), "PRESS_REVEAL": pr.get("revealToast"), "PRESS_TITLE": pr.get("dayTitle"),
        "PRESS_CHIP_TITLE": pr.get("dayTitle"), "PRESS_BODY_M": pr.get("dayBody"), "PRESS_BODY_F": pr.get("dayBodyF"),
        "PRESS_EFFECT": pr.get("dayEffect"), "PRESS_SUMMONS_TITLE": pr.get("summonsTitle"),
        "PRESS_SUMMONS_BODY": pr.get("summonsBody"), "PRESS_TESTIFY": pr.get("testifyVerb"),
        "PRESS_CHIP_SUMMONS": pr.get("chip"), "PRESS_END": pr.get("endToast"),
        "PRESS_SUSP_HOT": (pr.get("hotWords") or [None, None])[0], "PRESS_SUSP_BOIL": (pr.get("hotWords") or [None, None])[1],
        "CHAT_PILL_DECLINE": lib.get("pill"), "CHAT_SYS_DECLINED": lib.get("sys"), "CHAT_PILL_DECLINE_CD": lib.get("cooldown"),
    }
    for key, want in MIRROR.items():
        if want is None:
            warnings.append(f"drift: {key} mirrors a content field that no longer exists")
        elif strings.get(key, "").replace(NBSP, " ") != str(want).replace(NBSP, " "):
            warnings.append(f"drift: {key} = {strings.get(key)!r} but the content says {want!r}")
    print("leader-select copy mirrored:", len(MIRROR))

# glyphs drawn by the pixel font = every canvas surface (label, pxtext) + content names
glyphs = set(" ")
for key, value, box, flags, spec, note in E:
    surf, _ = surface_of(box, value)
    if surf in ("label", "pxtext"):
        glyphs |= set(PH_RE.sub("", conv(value, surf)))
for s in list(prod_names.values()) + list(prod_plurals.values()) + list(upg_names.values()) + list(upg_effects.values()):
    glyphs |= set(s)
glyphs |= set("0123456789.,:/+%×KMBT−…־׳״₪·←()!?-")  # formatter output + §3.5 list
glyphs |= set("אבגדהוזחטיכךלמםנןסעפףצץקרשת")
glyphs -= {LRI, PDI}
glyph_str = "".join(sorted(glyphs, key=ord))
missing_font = sorted(c for c in glyphs if c not in XADV and c not in ZERO_W)

DOC = ("UI chrome copy for \"עוד סבב\" (Hebrew, RTL). Owned by the UX Designer; canonical for code (tools/sync_data.sh copies it to "
       "game/data). Generated with ux/string-budgets.json from one source; per-key boxes, surfaces and pixel budgets live there. "
       "RULES: (1) Values are LOGICAL order. Never reverse or pre-reorder; render Hebrew through a Godot Label/RichTextLabel with "
       "text_direction RTL (TextServer bidi). PxText only for keys whose surface is 'pxtext' (no Hebrew letters, no ₪). "
       "(2) Numeric runs inside Hebrew strings are already wrapped in LRI U+2066 … PDI U+2069, and ₪ is joined by U+00A0; code must "
       "not add or strip isolates. (3) Plural/gender variants are sibling keys: _ZERO/_ONE/_TWO/_OTHER (CLDR he; use _ZERO only "
       "when present and n==0, _TWO only when present and n==2, else _OTHER) and _M/_F (masculine is the default). "
       "(4) {placeholders} are filled by Strings.s; numeric ones get formatter output (K/M/B/T in the HUD, commas on the receipt, "
       "FMT_WORD_* in share prose). (5) Empty values are intentional (see budgets 'note'). (6) Keys are UPPER_SNAKE. Every first-minute §8 ID resolves "
       "MECHANICALLY: key = id.upper().replace('.', '_') plus a variant suffix where the string varies (e.g. chat.sys.left -> "
       "CHAT_SYS_LEFT_M / _F); where a fork key already held that string, an alias key with the same value exists. (7) producerNames/producerPlurals/upgradeNames are EMPTY on purpose: "
       "design/content.json owns every source and spin name (the Game Designer). upgradeEffects holds only the short UI effect "
       "label per spin id (s01-s15), derived from the designer's effect spec. requiredGlyphs = every character the pixel font must draw.")

ui = {
    "_doc": DOC,
    "strings": strings,
    "producerNames": {},
    "producerPlurals": {},
    "upgradeNames": {},
    "upgradeEffects": upg_effects,
    "requiredGlyphs": glyph_str,
}
bud = {
    "_doc": ("Per-key budgets for ux/ui-strings.json, for the Game Developer's build-time pixel-width lint (first-minute §8, "
             "engine review O-U3). LINT: substitute worstCasePlaceholders, drop LRI/PDI, measure with the shipping font "
             "(game/assets/fonts/sevev9.fnt: the sum of xadvance, space 4, ₪ 8) times the box's scale. PASS if it fits the box in "
             "`lines` lines at the base scale, and at base+1 (large text) either fits in `linesLarge` or carries largeText: "
             "'step-down'. RUNTIME RULE for step-down keys (ux/rtl-map.md §0.2): under large text the view draws the key at x5 only "
             "when it fits its box in linesLarge at x5, else at x4; it never ellipsises a step-down key. A key with joke:true must never "
             "need truncation (its punchline is last). html/share-text/og keys are checked by maxChars only (system font). "
             "surface 'unused' keys are not rendered in od-sevev. Box geometry is ux/rtl-map.md."),
    "fontMetrics": {"font": "Sevev 9 (game/assets/fonts/sevev9.fnt)", "cellRows": 9, "lineHeight": 11, "space": 4,
                    "advance": "fnt xadvance (glyph width + 1; ₪ 8, T 6)", "baseScale": 4, "largeScale": 5, "shareCards": "art scale 1 on the x5 card grid"},
    "boxes": {k: {"widthPx": v[0], "scale": v[1], "lines": v[2], "linesLarge": v[3], "where": v[4]} for k, v in BOXES.items()},
    "worstCasePlaceholders": PH,
    "numericPlaceholders": sorted(NUMERIC_PH),
    "strings": budgets,
    "contentNames": {"box": "card.name", "effectBox": "card.line2wide"},
}

os.makedirs(OUT, exist_ok=True)
with open(os.path.join(OUT, "ui-strings.json"), "w", encoding="utf-8") as f:
    json.dump(ui, f, ensure_ascii=False, indent=2)
    f.write("\n")
with open(os.path.join(OUT, "string-budgets.json"), "w", encoding="utf-8") as f:
    json.dump(bud, f, ensure_ascii=False, indent=2)
    f.write("\n")

print("keys:", len(strings), "| producers:", len(prod_names), "| spins:", len(upg_names))
print("surfaces:", {s: sum(1 for b in budgets.values() if b["surface"] == s) for s in ("label", "pxtext", "html", "share-text", "og", "unused")})
print("font:", FNT, "\nglyphs:", len(glyphs), "| missing from the font:", " ".join(repr(c) for c in missing_font))
errors += [f"no glyph in the shipping font for {c!r}" for c in sorted(missing_glyphs)]
print("ERRORS:", len(errors)); [print("  ", x) for x in errors]
print("WARNINGS:", len(warnings)); [print("  ", x) for x in warnings]
sys.exit(1 if errors else 0)
