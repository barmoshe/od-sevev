"""Controls: buttons (primary / secondary / gold) in default / pressed / disabled, the tab bar,
the active-tab plate, the count badge, and the four tab icons (מקורות · ספינים · קואליציה · תיקים).

State language (every state differs in SHAPE, not only colour):
  default  = raised: 1px light bevel on top, a 2-row lip under the face (the key's side).
  pressed  = the face drops 2 art px into the lip; the light bevel becomes an inner shadow.
  disabled = sunk like pressed, flat (no light bevel), desaturated face, grey label.
"""
from pix import Layer
from palette import luminance
from kit import save, panel, grid_layer, recolor, chamfer, outline_inplace

G = "controls"

VARIANTS = {
    #          face         hi           lo          lip         press_face   press_shadow  label
    "primary":   ("flag",      "flag_hi",   "flag_dk",  "flag_dk",  "flag_dk",   "outline",    "white"),
    "secondary": ("ui_bubble", "ui_bub_hi", "ui_panel", "ui_scrim", "ui_panel",  "outline",    "white"),
    "gold":      ("gold",      "gold_hi",   "gold_sh",  "gold_dk",  "gold_sh",   "gold_dk",    "ink"),
    # wave 6 (UX R7): the destructive commit. The red ramp (danger), built exactly like primary so it is one family.
    "danger":    ("red",       "red_hi",    "red_dk",   "red_dk",   "red_dk",    "outline",    "white"),
}
USE = {
    "primary": "Primary action: 'התייעצות ביטחונית · {price} ₪', 'לשתף', 'להתחיל'. flag blue is reserved for the "
               "Magician's tie and THE primary button; one primary per screen. white on flag 8.5:1.",
    "secondary": "Secondary: 'להעיד', 'סגור', 'לשמור תמונה', 'צאו החוצה', 'להחזיר לקבוצה'. white on ui_bubble 13.1:1.",
    "gold": "Money / reward only: the full-width 'עוד סבב!' election button (replaces the ticker at >= 61 seats). "
            "ink on gold 11.0:1.",
    "danger": "Destructive commit only: 'למחוק הכול' in the reset modal O10 (UX R7), on the LEFT, beside a "
              "button_secondary cancel on the right that holds the focus. red = danger, and the shape that travels with "
              "it is the word itself plus, if the row has room, icon_trash leading the label (right). Never on a "
              "non-destructive action; never two on a screen. white on red 4.7:1, pressed white on red_dk 8.1:1.",
}


def button(kind, W=24, H=20):
    face, hi, lo, lip, pface, pshadow, label = VARIANTS[kind]
    d = panel(W, H, face, hi, lo, lip=2, lip_c=lip)
    save(d, f"button_{kind}_default", G, state="default", slice=[3, 3, 3, 4], content=[3, 2, W - 6, H - 6],
         label=label, notes=USE[kind] + " Text cell (9 rows) centred in rows 2..15.")
    p = Layer(W, H)
    pf = panel(W, H - 2, pface, pshadow, pface, bevel=1)
    # inner shadow instead of a light bevel: the key is down
    pf.hline(1, W - 2, 1, pshadow); pf.vline(1, 1, H - 4, pshadow)
    pf.hline(1, W - 2, H - 4, pface); pf.vline(W - 2, 2, H - 4, pface)
    p.paste(pf, 0, 2)
    save(p, f"button_{kind}_pressed", G, state="pressed", slice=[3, 5, 3, 2], content=[3, 4, W - 6, H - 6],
         label=label, notes="Pressed: label moves +2 art px down with the face.")
    x = Layer(W, H)
    xf = panel(W, H - 2, "suit_dk", "suit_dk", "night", bevel=0)
    x.paste(xf, 0, 2)
    save(x, f"button_{kind}_disabled", G, state="disabled", slice=[3, 5, 3, 2], content=[3, 4, W - 6, H - 6],
         label="grey", notes="Disabled: sunk, flat, no bevel light; label grey (5.5:1 on suit_dk). Same for every kind, "
         "so 'disabled' never masquerades as a colour variant.")


# ------------------------------------------------------------------ tab bar
def tabbar():
    # UX: tabs 97.5 x 56 CSS -> 45 x 26 art; bar spans 180.
    B = Layer(180, 26)
    B.rect(0, 0, 180, 26, "ui_panel")
    B.hline(0, 179, 0, "outline")
    B.hline(0, 179, 1, "ui_bub_hi")
    for x in (44, 89, 134):                       # hairline separators between the four tabs
        B.vline(x, 5, 20, "ui_scrim")
    save(B, "tabbar", G, slice=[2, 3, 2, 2], notes="Tab bar body, 180x26 (4 tabs x 45). Separators at x 44/89/134. "
         "Order RIGHT to LEFT (RTL): מקורות · ספינים · קואליציה · תיקים.")
    a = Layer(45, 26)
    a.rect(0, 0, 45, 26, "ui_bubble")
    a.hline(0, 44, 0, "outline")
    a.hline(1, 43, 1, "ui_bub_hi")
    a.vline(0, 1, 25, "outline"); a.vline(44, 1, 25, "outline")
    a.rect(4, 23, 37, 2, "rim")                   # the underline: pale rim, NOT gold (gold = money)
    a.hline(4, 40, 25, "outline")
    save(a, "tab_active", G, slice=[5, 3, 5, 4], content=[2, 2, 41, 20],
         notes="Active tab: raised plate + 2px pale underline + white label (inactive tabs: no plate, grey label, dimmed icon). "
         "Icon 15x15 at (15, 2); label cell (9 rows) at y 16. Deviation from UX 'gold underline': gold stays money-only.")
    # count badge (e.g. קואליציה 1): red capsule, white digit
    bd = panel(11, 11, "red", "red_hi", "red_dk", corner=3)
    save(bd, "badge_count", G, slice=[5, 4, 5, 4], content=[2, 1, 7, 9], label="white",
         notes="Unread / demand count on a tab: top-right of the icon. 1-2 digits in the 5x9 cut (body rows only). "
         "white on red 4.7:1; the number itself is the non-colour channel.")


# ------------------------------------------------------------------ tab icons 15x15
LEG = {"k": "outline", "s": "silver", "l": "slate", "w": "white", "y": "gold", "Y": "gold_hi", "o": "gold_sh",
       "g": "grey", "p": "pink", "P": "pink_sh", "d": "suit_dk", "u": "suit", "t": "stone", "T": "stone_sh",
       "v": "stamp", "i": "ink", "b": "ui_bubble", "B": "ui_bub_hi"}

ICONS = {
    # a faucet on a wall, a coin dropping out of it: "sources" = what you tap
    "sources": [
        "...kkkkkkk.....",
        "...ksssssk.....",
        "...kkkskkk.....",
        "kk....k........",
        "kskkkkskkkkk...",
        "kswssssssssk...",
        "kslllllllllsk..",
        "kskkkkkkkklsk..",
        "kk.......klsk..",
        ".........kkkk..",
        ".........kkkk..",
        "........kyYyyk.",
        "........kyyyok.",
        "........koyook.",
        ".........kkkk..",
    ],
    # a chat bubble that says 61: "coalition" = the group chat, and the number it is for
    "coalition": [
        "kkkkkkkkkkkkkkk",
        "kwwwwwwwwwwwwwk",
        "kwwwwwwwwwwwwwk",
        "kwwwiiwwiwwwwwk",
        "kwwiwwwiiwwwwwk",
        "kwwiiiwwiwwwwwk",
        "kwwiwwiwiwwwwwk",
        "kwwwiiwiiiwwwwk",
        "kwwwwwwwwwwwwwk",
        "kgggggggggggggk",
        "kkkkkkkkkkkggkk",
        "..........kgk..",
        "..........kk...",
        "...............",
        "...............",
    ],
    # a manila case file with a violet 'filed' mark and paper peeking: "cases"
    "cases": [
        "...............",
        "kkkkkk.........",
        "kttttk.........",
        "kttttkkkkkkkkk.",
        "kTTTTTTTTTTTTk.",
        "kTwwwwwwwwwwwkk",
        "kkkkkkkkkkkkkTk",
        "kttttttttttttTk",
        "ktttvvvvtttttTk",
        "ktttvtttvttttTk",
        "ktttvvvvtttttTk",
        "kttttttttttttTk",
        "kttttttttttttTk",
        "kTTTTTTTTTTTTTk",
        "kkkkkkkkkkkkkkk",
    ],
}

HEB = {"sources": "מקורות", "spins": "ספינים", "coalition": "קואליציה", "cases": "תיקים"}


def dim(L):
    """Inactive icon: collapse every colour to a 3-step slate ramp by luminance (keeps the read,
    drops the pop; the active one is the only coloured icon in the bar)."""
    M = L.copy()
    for row in M.px:
        for i, c in enumerate(row):
            if c is None or c == "outline":
                continue
            l = luminance(c)
            row[i] = "grey" if l > 0.45 else ("slate" if l > 0.12 else "suit")
    return M


def spins_icon():
    """Dubi's microphone broadcasting two pink arcs: 'spins' = talking points on repeat."""
    import math
    L = Layer(15, 15)
    head = ["..kkkk..",
            ".kswssk.",
            "kslslslk",
            "ksslslsk",
            "kslslslk",
            "ksslslsk",
            ".kllllk.",
            "..kkkk.."]
    L.paste(grid_layer(head, LEG), 0, 0)
    # U-holder, stem, base
    for (x, y) in [(0, 5), (0, 6), (1, 7), (7, 5), (7, 6), (6, 7)]:
        L.set(x, y, "grey")
    L.set(1, 8, "grey"); L.set(6, 8, "grey"); L.hline(2, 5, 9, "grey")
    L.vline(3, 10, 12, "slate"); L.vline(4, 10, 12, "grey")
    L.hline(1, 6, 13, "grey"); L.hline(1, 6, 14, "outline"); L.hline(1, 6, 12, "outline")
    L.set(3, 12, "slate"); L.set(4, 12, "grey")
    cx, cy = 3.5, 4.0
    for r in (6.2, 8.8):
        for a in range(-42, 43, 3):
            x = cx + r * math.cos(math.radians(a)); y = cy + r * math.sin(math.radians(a))
            L.set(int(round(x)), int(round(y)), "pink")
    return L


def tab_icons():
    ICONS["spins"] = None
    for key, rows in ICONS.items():
        if rows is None:
            L = spins_icon()
        else:
            assert all(len(r) == 15 for r in rows) and len(rows) == 15, key
            L = grid_layer(rows, LEG)
        save(L, f"tabicon_{key}_active", G, state="active", notes=f"Tab '{HEB[key]}', active (15x15).")
        save(dim(L), f"tabicon_{key}_idle", G, state="idle", notes=f"Tab '{HEB[key]}', inactive: slate ramp.")


def cards():
    """The source / partner card row in the panel (UX 3.1: 366x64 CSS -> 169x30 art, the WHOLE card is the target)."""
    W, H = 32, 30
    c = panel(W, H, "ui_bubble", "ui_bub_hi", "ui_panel", lip=1, lip_c="ui_scrim")
    save(c, "card_row", G, state="default", slice=[4, 4, 4, 4], content=[3, 2, W - 6, H - 6], label="white",
         notes="Source / partner card: 169x30 art in the panel. RTL: the 26x26 plate (card_plate) at the RIGHT (x w-29, y 2), "
               "name + line 2 right-aligned after it, the price pill (pay_pill_*) at the LEFT end, 54x17 art.")
    lk = Layer(W, H)
    lf = panel(W, H - 1, "suit_dk", "suit_dk", "night", bevel=0)
    lk.paste(lf, 0, 1)
    save(lk, "card_row_locked", G, state="locked", slice=[4, 4, 4, 4], content=[3, 3, W - 6, H - 6], label="grey",
         notes="The silhouette / not-yet-revealed card: flat, sunk, grey label '???'.")
    p = panel(26, 26, "night", "ui_scrim", "ui_bub_hi", corner=1)
    save(p, "card_plate", G, slice=[3, 3, 3, 3],
         notes="Recessed plate for the 24x24 source icon or the 32x32 cast avatar (then 34x34, slice keeps the bevel).")


def build():
    cards()
    for k in VARIANTS:
        button(k)
    tabbar()
    tab_icons()


if __name__ == "__main__":
    build()
    from kit import write_manifest
    print(write_manifest())
