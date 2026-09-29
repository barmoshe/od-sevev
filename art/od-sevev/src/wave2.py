"""Wave 2 of the UI kit: the flat UI the Technical Artist found missing, and the Animator's art needs.

  sheet / modal · ticker bar + "מבזק" plate · source-card states + owned chip · spin card + 15 spin
  icons + "שחוק" tag · opposition card (front, back, timer) · 17 trophy icons + plates · gear and
  sound on/off · FTUE hand + tap ring · toast · 9x9 coin · the courthouse-window overlay · pre-rotated
  stamps · Washington laundry pieces · the election-ceremony curtain · the sweat drop.
Same kit rules (kit.py): 1x art px, `outline` silhouette, palette swatches only, binary alpha.
"""
import math

from pix import Layer
from kit import save, strip, panel, capsule, outline_inplace, grid_layer, chamfer, speckle, with_rim, hatch
from ui_controls import dim
import icons15 as I
import hebfont

LEG = I.LEG


# ------------------------------------------------------------------ 1. sheet / modal
def sheets():
    W = H = 36
    L = Layer(W, H)
    L.rect(0, 0, W, H, "ui_panel")
    L.rect(1, 1, W - 2, 18, "ui_bubble")                      # the title band
    L.hline(1, W - 2, 1, "ui_bub_hi"); L.vline(1, 1, H - 2, "ui_bub_hi")
    L.hline(1, W - 2, 19, "outline"); L.hline(1, W - 2, 20, "ui_scrim")
    L.hline(1, W - 2, H - 2, "ui_scrim"); L.vline(W - 2, 2, H - 2, "ui_scrim")
    chamfer(L, 0, 0, W, H, 2)
    outline_inplace(L)
    # wave 6 (F9): a 1 px suit_hi edge OUTSIDE the outline, following the chamfer, so the dark sheet lifts off the
    # near-black scrim (3.6:1 on the scrimmed dark; the ui_panel body alone was 1.1:1). The PNG grows 1 px per side.
    L = L.outlined("suit_hi", pad=1)
    W, H = L.w, L.h
    save(L, "sheet_modal", "sheet", slice=[7, 23, 7, 7], content=[7, 23, W - 14, H - 30], label="white",
         notes="Generic sheet / modal: settings O7, About O8, return card O1, the 'לפזר את הכנסת' election modal, the round "
               "card. Title band y 2..19 (title white on ui_bubble 13.1:1, the close ✕ at the band's LEFT end in RTL); body "
               "ui_panel (white 15.6:1). Engine scrim under it: the outline swatch #0b0a12 at 60% (UX R15 / rtl-map "
               "§7.1 D23; never the fork's grape, which lifts the dark base). Wave 6 (F9): a 1 px suit_hi edge outside the "
               "outline on all four sides (3.6:1 vs the scrimmed dark), so the modal reads lifted, not cut out; the piece "
               "is 38x38 and every margin grew by 1. Draw it at the card rect grown by 4 logical px per side to keep the "
               "title band and body exactly where they were.")
    P = panel(24, 24, "ui_panel", "ui_bub_hi", "ui_scrim", corner=2)
    save(P, "sheet_plain", "sheet", slice=[5, 5, 5, 5], content=[4, 3, 16, 17], label="white",
         notes="Title-less sheet (toast stacks, the pardon desk form behind the stamp, tooltips).")
    # wave 6 (UX R26: "one ✕ style for every card"): the round ✕. Same silhouette and ✕ as the modals' round ✕
    # (the fork's ui_close16, pixel for pixel), recoloured into the kit's raised language: rim-lit top arc,
    # ui_bub_hi face (one step above a ui_bubble title band, so it never vanishes into it), ui_bubble shadow.
    x = grid_layer(CLOSE16, {"k": "outline", "j": "rim", "u": "ui_bub_hi", "U": "ui_bubble", "w": "white"})
    save(x, "icon_close", "sheet", notes="Close ✕ for every card and sheet (UX R26: one ✕ style): 16x16, drawn x4 = the "
         "64x64 visual of rtl-map §7.1, centred in its 104 (or the court card's 88) hit. Same silhouette as the modals' "
         "round ✕; white ✕ on ui_bub_hi 8.6:1. Reads on the court header wood, a ui_bubble title band, the dark sheet "
         "body and a cream card (wave 6; was a thin 9x9 X).")
    t = grid_layer(TRASH9, {"k": "outline", "w": "white", "l": "slate"})
    save(t, "icon_trash", "sheet", notes="Trash can, 9x9 inline icon (one text cell tall): the settings danger row "
         "'SET_RESET' (rtl-map §7.4), leading the label on the RIGHT, and optionally leading 'למחוק הכול' on "
         "button_danger. Never mirrored (rtl-map §1 'keep'). White lid and can + slate ribs: white on ui_panel 15.6:1, "
         "outline on paper 13.5:1, so it reads on the dark sheet and on a cream card alike (wave 6).")


CLOSE16 = [".....kkkkkk.....", "...kkjjjjjjkk...", "..kjjuuuuuujjk..", ".kjuuuuuuuuuujk.", ".kuuuwuuuuwuuuk.",
           "kjuuuwwuuwwuuujk", "kuuuuuwwwwuuuuuk", "kuuuuuuwwuuuuuuk", "kuuuuuwwwwuuuuuk", "kUuuuwwuuwwuuuUk",
           "kUuuuwuuuuwuuuUk", ".kUuuuuuuuuuuUk.", ".kUUUuuuuuuUUUk.", "..kUUUUUUUUUUk..", "...kkUUUUUUkk...",
           ".....kkkkkk....."]
TRASH9 = ["...kkk...",      # the lid's knob
          "kkkwwwkkk",
          "kwwwwwwwk",      # the lid, wider than the can
          "kkkkkkkkk",
          ".kwlwlwk.",      # the can: white with slate ribs
          ".kwlwlwk.",
          ".kwlwlwk.",
          ".kwlwlwk.",
          "..kkkkk.."]


# ------------------------------------------------------------------ 2. ticker
def ticker():
    T = Layer(180, 20)
    T.rect(0, 0, 180, 20, "ui_panel")
    T.hline(0, 179, 0, "outline")
    T.hline(0, 179, 1, "red")                                  # the lower-third's red top rule
    T.hline(0, 179, 2, "ui_bub_hi")
    T.hline(0, 179, 19, "outline")
    save(T, "ticker_bar", "ticker", slice=[2, 4, 2, 2], content=[2, 5, 176, 12], label="silver",
         notes="Dubi's lower third (UX 3.1 ticker, 44 CSS = 20 art). Crawl text silver on ui_panel 11.8:1, y 6. The "
               "'מבזק' plate sits at the RIGHT end (RTL start), Dubi's avatar just left of it, the 27.10 chip at the left.")
    W, H = 32, 14
    p = Layer(W, H)
    for y in range(H):
        x0 = (H - 1 - y) // 3                                   # slant: 1 px every 3 rows, leaning into the crawl
        for x in range(x0, W):
            p.set(x, y, "red")
    for y in range(H):
        x0 = (H - 1 - y) // 3
        p.set(x0 + 1, y, "red_hi") if y < H - 1 else None
    p.hline(5, W - 2, 1, "red_hi")
    p.hline(1, W - 2, H - 2, "red_dk")
    outline_inplace(p)
    save(p, "ticker_flash_plate", "ticker", slice=[7, 3, 3, 3], content=[6, 2, W - 9, 9], label="white",
         notes="The red 'מבזק' label plate (blank, for engine text). white on red 4.7:1. Slanted leading edge faces the crawl.")
    q = p.copy()
    hebfont.draw(q, "מבזק", W - 4, 2, "white", align="right")
    save(q, "ticker_flash_plate_text", "ticker", notes="The same plate with 'מבזק' baked in the 5x9 cut.")


# ------------------------------------------------------------------ 3. source card states + owned chip
def source_cards():
    W, H = 32, 30
    base = panel(W, H, "ui_bubble", "ui_bub_hi", "ui_panel", lip=1, lip_c="ui_scrim")
    save(base, "card_source_unaffordable", "cards", state="unaffordable", slice=[4, 4, 4, 4],
         content=[3, 2, W - 6, H - 6], label="white",
         notes="Money-source row (shop), not yet affordable: plain raised card; its price pill is pay_pill_track + pay_pill_fill.")
    a = base.copy()
    a.hline(2, W - 3, 1, "gold_sh"); a.hline(3, W - 4, 2, "gold_dk")     # a warm top edge: 'ready'
    a.vline(W - 3, 3, H - 6, "gold_sh")                                   # and on the RTL start side
    save(a, "card_source_affordable", "cards", state="affordable", slice=[4, 4, 4, 4], content=[3, 3, W - 7, H - 7],
         label="white", notes="Affordable: the same card plus a gold edge (top + right). The pill carries the state "
               "(raised gold pay_pill_default); the edge is the redundant channel. The WHOLE card is the buy target.")
    lk = Layer(W, H)
    lk.paste(panel(W, H - 1, "suit_dk", "suit_dk", "night", bevel=0), 0, 1)
    save(lk, "card_source_locked", "cards", state="locked", slice=[4, 4, 4, 4], content=[3, 3, W - 6, H - 6],
         label="grey", notes="Not revealed: sunk + flat, name '???', icon plate = plate_silhouette.")
    s = panel(26, 26, "night", "ui_scrim", "ui_bub_hi", corner=1)
    for i in range(3, 23, 2):
        s.set(i, 3, "slate"); s.set(i, 22, "slate"); s.set(3, i, "slate"); s.set(22, i, "slate")
    from kit import micro
    micro(s, "?", 11, 10, "grey")
    save(s, "plate_silhouette", "cards", notes="Icon plate for a locked source: dashed ring + '?'. The engine may instead "
         "draw the next critter's mask in `night` on card_plate (UX's silhouette rule).")
    c = capsule(14, 11, "night", "ui_bub_hi", "outline", r=2)
    save(c, "chip_owned", "cards", slice=[4, 3, 4, 3], content=[3, 1, 8, 9], label="white",
         notes="Owned count on a source card ('×12'), top-left corner of the plate. white on night 13.5:1.")


# ------------------------------------------------------------------ 4. spins
def spin_cards():
    W, H = 32, 30
    c = panel(W, H, "ui_bubble", "ui_bub_hi", "ui_panel", lip=1, lip_c="ui_scrim")
    c.rect(W - 4, 2, 2, H - 5, "pink_sh"); c.vline(W - 4, 2, H - 4, "pink")   # the spin stripe (RTL start)
    save(c, "card_spin", "cards", state="default", slice=[4, 4, 6, 4], content=[3, 2, W - 9, H - 6], label="white",
         notes="Spin card (ספינים tab). Pink stripe on the RIGHT = 'this is a talking point' (spins own pink; money "
               "cards don't have it). Icon 24x24 (spin_<id>, upgrades[].icon) on card_plate at the right, price pill left.")
    b = Layer(W, H)
    b.paste(panel(W, H - 1, "suit_dk", "suit_dk", "night", bevel=0), 0, 1)
    b.rect(W - 4, 3, 2, H - 6, "pink_sh")
    save(b, "card_spin_locked", "cards", state="locked", slice=[4, 4, 6, 4], content=[3, 3, W - 9, H - 6], label="grey",
         notes="A spin not yet unlocked / a once-spin already aired: sunk and flat, the stripe dimmed.")
    tw = hebfont.measure("שחוק")
    t = capsule(tw + 10, 13, "suit_dk", "suit", "night", r=2)
    hebfont.draw(t, "שחוק", tw + 4, 1, "grey", align="right")
    for (x, y) in [(0, 5), (0, 7), (tw + 9, 4), (tw + 9, 8), (4, 12), (tw + 3, 12)]:
        t.px[y][x] = None                                        # frayed edge: the talking point is worn out
    save(t, "tag_worn", "cards", notes="Spin-fatigue tag 'שחוק' (UX/pitch 13), baked text, grey on suit_dk 5.5:1; the "
         "frayed edge is the shape channel.")
    import icons24
    for sid, (name, L) in icons24.build_all().items():
        save(L, f"spin_{sid}", "spins",
             notes=f"Spin {sid} '{name}' (content.json upgrades[].icon). 24x24 at d = 1, the shop icon size: centred on "
                   "card_plate (26x26) like a money source's icon. Wave 5 redraw (icons24.py); was 15x15.")


# ------------------------------------------------------------------ 5. opposition card
def opposition():
    W, H = 40, 40
    L = Layer(W, H)
    L.rect(0, 0, W, H, "slate")
    L.hline(1, W - 2, 1, "grey"); L.vline(1, 1, H - 2, "grey")
    L.hline(1, W - 2, H - 2, "suit"); L.vline(W - 2, 2, H - 2, "suit")
    L.rect(3, 3, W - 6, H - 6, "night")
    L.rect(3, 3, W - 6, 12, "suit_dk")                            # name band
    L.hline(3, W - 4, 15, "outline")
    chamfer(L, 0, 0, W, H, 1)
    outline_inplace(L)
    for (x, y) in [(4, 4), (W - 5, 4), (4, H - 5), (W - 5, H - 5)]:
        L.set(x, y, "silver")                                     # rivets: a steel 'outside the group' frame
    save(L, "card_opposition", "cards", slice=[6, 17, 6, 6], content=[5, 17, W - 10, H - 23], label="white",
         notes="Opposition event card (content.json opposition.cards, 8 cards). Neutral steel frame: NOT a party colour, "
               "NOT the coalition's violet. Name band y 3..14 (white on suit_dk 11.8:1), avatar (32x32 on a 34x34 "
               "card_plate) at the RIGHT under the band, text left of it, opp timer along the bottom.")
    B = Layer(W, H)
    B.paste(L, 0, 0)
    for y in range(4, H - 4):
        for x in range(4, W - 4):
            B.set(x, y, "suit_dk" if (x + y) % 6 < 3 else "night")
    save(B, "card_opposition_back", "cards", slice=[6, 6, 6, 6], mode="tile",
         notes="The card's back (Bennett's pledge flip, Golan's merge shuffle). Diagonal stripe period 6: TILE. "
               "Centre card_back_mark on it (never inside the 9-slice, or it would repeat).")
    M = Layer(16, 16)
    M.rect(0, 0, 16, 16, "night")
    M.rect(1, 1, 14, 14, "outline")
    hebfont.draw(M, "?", 9, 3, "grey", align="right")
    outline_inplace(M)
    save(M, "card_back_mark", "cards", pivot=[8, 8], notes="The '?' mark centred on card_opposition_back.")
    f = Layer(6, 7)
    for y, c in enumerate(["white", "silver", "silver", "silver", "grey", "grey", "slate"]):
        f.hline(0, 5, y, c)
    f.vline(0, 0, 6, "white")
    save(f, "opp_timer_fill", "cards", slice=[1, 1, 1, 2],
         notes="Opposition timer: draw inside seats_track (same well), anchored RIGHT, shrinking as durationSec runs out. "
               "Steel, so it never reads as seats (sky) or suspicion (red).")


# ------------------------------------------------------------------ 6. trophies + 7. controls icons
def trophies_and_controls():
    for tid, L in I.TROPHY.items():
        save(L, f"trophy_{tid[5:]}", "trophies", state="earned", notes=f"Trophy icon '{tid}' (content.json achievements).")
        save(dim(L), f"trophy_{tid[5:]}_locked", "trophies", state="locked",
             notes=f"'{tid}', not yet earned: slate ramp. Secret trophies use trophy_plate_secret instead.")
    W = 21
    g = Layer(W, W)
    g.rect(0, 0, W, W, "gold")
    g.hline(1, W - 2, 1, "gold_hi"); g.vline(1, 1, W - 2, "gold_hi")
    g.hline(1, W - 2, W - 2, "gold_sh"); g.vline(W - 2, 2, W - 2, "gold_sh")
    g.rect(3, 3, W - 6, W - 6, "night")
    g.hline(3, W - 4, 3, "outline")
    chamfer(g, 0, 0, W, W, 2)
    outline_inplace(g)
    save(g, "trophy_plate_earned", "trophies", pivot=[10, 10],
         notes="Earned trophy: gold ring (a reward moment) around a night well; the 15x15 icon sits at (3,3).")
    l = panel(W, W, "suit_dk", "suit_dk", "night", corner=2, bevel=0)
    l.rect(3, 3, W - 6, W - 6, "night")
    save(l, "trophy_plate_locked", "trophies", notes="Not yet earned: flat grey ring, icon *_locked inside.")
    s = l.copy()
    hebfont.draw(s, "???", W // 2, 6, "grey", align="center")
    save(s, "trophy_plate_secret", "trophies", notes="Secret trophy until earned: '???' (content.json secret:true).")
    for cid, L in I.CONTROLS.items():
        save(L, cid, "controls", notes={"icon_gear": "⚙ settings, 15x15, hit 20x20 art (UX row A corner).",
                                        "icon_sound_on": "🔊 sound on: speaker + two arcs.",
                                        "icon_sound_off": "🔊 sound off: speaker + a red x (the x is the channel, not the red)."}[cid])


# ------------------------------------------------------------------ 8. FTUE hand, 9. toast, 10. coin
HAND = [
    "......kk",
    ".....kjek",
    ".....kjek",
    ".....kjek",
    ".....kjekkk",
    "...kkkjekefkk",
    "..kjekjeeeeefk",
    "..kjeeeeeeeefk",
    "..kjeeeeeeeefk",
    "...keeeeeeeefk",
    "...keeeeeeefk",
    "....keeeeeffk",
    "....kwwwwwwwk",
    "....kNNNNNNNk",
    "....kNNNNNNNk",
    "....kkkkkkkkk",
]


def hand_toast_coin():
    h = grid_layer([r.ljust(16, ".") for r in HAND], LEG)
    r = with_rim(h)
    up = Layer(r.w, r.h + 2); up.paste(r, 0, 0)
    dn = Layer(r.w, r.h + 2); dn.paste(r, 0, 2)  # pressed: the whole hand 2 px down; the cell is 2 px taller
    fr = strip([up, dn])
    save(fr, "ftue_hand", "ftue", frames=2, frame_w=up.w, pivot=[7, 1],
         notes="FTUE pointer (UX F2, P0 tap loop): the Magician's own lecturing finger, navy cuff, pale rim so it reads on "
               "every stage. Frame 0 = hover, frame 1 = pressed (2 px down). Pivot = the fingertip. Loop timing: Animator.")
    r = Layer(13, 13)
    for y in range(13):
        for x in range(13):
            d = math.hypot(x - 6, y - 6)
            if 5.0 <= d <= 6.2:
                r.set(x, y, "rim")
    save(r, "ftue_tap_ring", "ftue", pivot=[6, 6], notes="Tap ring under the fingertip on frame 1 (scale/fade = Animator).")
    t = panel(32, 20, "ui_panel", "ui_bub_hi", "ui_scrim", corner=2)
    t.rect(28, 2, 2, 15, "rim")                                    # the pale accent on the RTL start edge
    t.hline(2, 29, 18, "outline")
    save(t, "toast", "ftue", slice=[4, 4, 6, 4], content=[3, 3, 23, 13], label="white",
         notes="Toast / banner ('נפתח לך תיק', 'נפתחו ספינים…', the chat preview). Docks under HUD row B. Optional icon "
               "or 32px avatar at the right, inside the accent. white on ui_panel 15.6:1.")
    coin = grid_layer([
        "..kkkkk..",
        ".kYYYYok.",
        "kYyyyyyok",
        "kYyOyOyok",
        "kyyOyOyok",
        "kyyOOOyok",
        "kyyyyyook",
        ".koyyyoOk",
        "..kkkkk..",
    ], LEG)
    save(coin, "icon_coin9", "ftue", notes="9x9 shekel coin for the counter ('₪ 12.4K'), one text cell tall. Gold = money.")


# ------------------------------------------------------------------ 11. courthouse window overlay
# the courthouse echo's spot per era (art px, the sprite's pivot = its bottom centre); read by the engine from
# sprites.json ui.court_window.spots (court_echo.gd), so a move is an art change
COURT_SPOTS = {"balfour": [167, 167], "knesset": [158, 166], "washington": [162, 152]}


def court_window():
    frames = []
    for lit in (0, 1):
        L = Layer(24, 22)
        # pediment
        for y in range(0, 5):
            for x in range(12 - 2 * y - 1, 12 + 2 * y + 1):
                L.set(x, y + 1, "stone")
        L.hline(1, 22, 6, "stone_sh")
        L.rect(2, 7, 20, 14, "stone")
        for x in (3, 7, 16, 20):
            L.vline(x, 8, 19, "stone_sh")
        L.hline(1, 22, 20, "stone_sh")
        # the one window
        wc = "orange" if lit else "teal_dk"
        L.rect(10, 9, 4, 7, wc)
        if lit:
            L.rect(11, 10, 2, 5, "gold_hi")
            L.vline(12, 9, 15, "orange_sh"); L.hline(10, 13, 12, "orange_sh")
        outline_inplace(L)
        frames.append(L)
    save(strip(frames), "court_window", "stage", frames=2, frame_w=24, pivot=[12, 21],
         extra={"spots": COURT_SPOTS},
         notes="The diegetic echo of suspicion (UX 3.2 #3): a small courthouse on the stage whose one window lights at "
               ">= 75%. Frame 0 dark, frame 1 lit (orange + gold_hi core: v1's lamp rule). Decorative class: no rim. "
               "`spots` = the pivot per era in stage-art px (the courthouse stage uses its own clock panel: none). Moved "
               "2026-09-29 (the Animator's ask, mobile-first) from the sky band (Balfour (150, 70), Knesset (156, 96), "
               "Washington (34, 96)), which the phones crop under Row A / the toast dock, to the stage's right side, clear "
               "of the leader: Balfour behind the wall right of the lamp, Knesset on the lawn at the colonnade's end, "
               "Washington in the horizon band right of the mansion. Sprite tops at art rows 146 / 145 / 131, so the "
               "house sits unclamped under the toast dock on every stage S >= 552 / 556 / 612 logical px.")
    g = Layer(20, 20)
    for y in range(20):
        for x in range(20):
            d = math.hypot(x - 9.5, y - 9.5)
            if d < 9.5 and (x + y) % 2 == 0:
                g.set(x, y, "orange" if d < 5 else "orange_sh")
    save(g, "court_window_glow", "stage", pivot=[10, 10],
         notes="50% checker halo drawn BEHIND the lit window (the style's only glow; checker, never alpha).")


# ------------------------------------------------------------------ 12b. laundry, curtain, sweat
def laundry():
    pieces = {
        "shirt": ["..kkk.kkk..", ".kwwwkwwwk.", "kwwwwkwwwwk", "kwpkwwwkpwk", ".kkkwwwkkk.", "...kwwwk...",
                  "...kwwpk...", "...kwwpk...", "...kppppk..", "...kkkkk..."],
        "sock": ["kkkk..", "kbbk..", "kssk..", "kssk..", "kssk..", "ksskkk", "kssssk", "ksssgk", "kkkkkk"],
        "towel": ["kkkkkkkkkk", "kPPPPPPPPk", "kwwwwwwwwk", "kPPPPPPPPk", "kPPPPPPPqk", "kPPPPPPPqk", "kwwwwwwwwk",
                  "kqqqqqqqqk", "kkkkkkkkkk"],
        "shorts": ["kkkkkkkkk", "kbbbbbbbk", "kbPbbbPbk", "kbbbPbbbk", "kbbbkbbBk", "kbPbkbPBk", "kkkkkkkkk"],
    }
    for name, rows in pieces.items():
        w = max(len(r) for r in rows)
        L = grid_layer([r.ljust(w, ".") for r in rows], LEG)
        save(L, f"laundry_{name}", "stage", pivot=[L.w // 2, L.h // 2],
             notes="Washington era: laundry flying out of the 'מזוודות כביסה' (WaPo 2020, denied). Decorative, no rim. "
                   "Tumble/drift is the Animator's.")
    save(I.SPINS["s10"][1], "laundry_bag", "stage", notes="The laundry bag the pieces fly out of (same art as spin_s10).")


def curtain():
    W, H = 30, 40
    P = Layer(W, H)
    for x in range(W):
        f = x % 10
        c = "plum_hi" if 2 <= f <= 5 else ("plum" if f < 8 else "outline")
        if f in (1, 6):
            c = "plum"
        for y in range(H):
            P.set(x, y, c)
    save(P, "curtain_panel", "ceremony", mode="tile",
         notes="Election-ceremony curtain body: vertical folds, period 10 px; TILE both axes. PLUM, the stage-curtain ramp "
               "(v1 title), not maroon: maroon is the Suitcase's alone (see the flag in the report).")
    hem = Layer(W, 6)
    for x in range(W):
        f = x % 10
        dep = 3 + (1 if 2 <= f <= 5 else 0)
        for y in range(dep):
            hem.set(x, y, "plum_hi" if 2 <= f <= 5 else "plum")
        hem.set(x, dep, "gold_sh")
        if x % 3 == 0:
            hem.set(x, dep + 1, "gold")
    save(hem, "curtain_hem", "ceremony", mode="tile",
         notes="Curtain bottom edge with a gold fringe (the election is the game's reward moment). Tile horizontally.")
    V = Layer(180, 22)
    V.rect(0, 0, 180, 22, "plum")
    V.hline(0, 179, 0, "outline"); V.hline(0, 179, 1, "plum_hi")
    V.hline(0, 179, 18, "gold_sh"); V.hline(0, 179, 19, "gold"); V.hline(0, 179, 20, "gold_sh"); V.hline(0, 179, 21, "outline")
    for x0 in range(4, 176, 16):                                  # the ballot-slot motif: a row of ballot-box lids
        V.rect(x0, 5, 12, 9, "white")
        V.hline(x0, x0 + 11, 13, "paper"); V.vline(x0 + 11, 5, 13, "paper")
        V.rect(x0 + 3, 8, 6, 2, "outline")
        V.hline(x0, x0 + 11, 4, "outline"); V.hline(x0, x0 + 11, 14, "outline")
        V.vline(x0 - 1, 5, 13, "outline"); V.vline(x0 + 12, 5, 13, "outline")
    save(V, "curtain_valance", "ceremony", slice=[4, 2, 4, 3], mode="tile",
         notes="The valance across the top: a row of ballot-box lids with their slots (the election signifier, never a "
               "slip going in), gold rope trim. 16 px motif period; TILE horizontally.")


def sweat():
    s = grid_layer(["..k..", ".kwk.", ".kbk.", "kbwbk", "kbbBk", ".kkk."], LEG)
    save(s, "sweat_drop", "stage", pivot=[2, 5], notes="The Magician's sweat drop at suspicion >= 75% (Animator's optional "
         "echo). Placement on his temple: the Animator's anchor.")


def build():
    sheets(); ticker(); source_cards(); spin_cards(); opposition(); trophies_and_controls(); hand_toast_coin()
    court_window(); laundry(); curtain(); sweat()


if __name__ == "__main__":
    build()
    from kit import write_manifest
    print(write_manifest())
