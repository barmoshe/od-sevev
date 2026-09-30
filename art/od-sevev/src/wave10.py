"""Wave 10 (2026-09-30): the art side of UX build review 2 (ux/review-2026-09-30.md U2, U7, U10; mobile-first §10 A4,
A5). New ids only: the old pieces stay as they are, so the engine switches when it is ready.

  button_white_{default,pressed,disabled}  24x20   U2 / A4: the v4 primary button, the flag's white on its blue: a white
                                                  face, a flag-blue lip (the key's side) and the outline; label `flag`
                                                  8.5:1. Pressed: a silver face, down 2 into the lip (label 6.4:1).
                                                  Disabled: the shared sunk slate (every kind's disabled is one shape).
  card_row_silhouette                      32x30   U7: a not-yet-revealed source row on the white pane, a blank pale slip:
                                                  `ui_mute` face, 1 art px `ui_rule` edge (5.6:1 on the pane: the edge
                                                  carries the shape, the face is 1.3:1), sunk 1 px, no ink outline.
                                                  Name label `ui_panel` 8.9:1.
  chat_system_pill_navy                    20x13   U7: T3's system pill on the thread: a flat `ui_scrim` well with a
                                                  `ui_rule` edge (1.5:1 fill + the edge vs the ui_panel thread), label
                                                  `ui_mute` 12.9:1. Flat, no light bevel: a system line is not a button.
  notice_frame                             40x40   U10: EVOLVE_TX as the gate's printed notice, a white notice card for the
                                                  flag-blue page, ruled in flag blue at its top (thick, a white gap, thin)
                                                  and bottom (thin, gap, thin) like the HTML gate's card. 9-slice.
  booth_frame_tall                         40x46   A5: booth_frame with a 12-row header, so the picker title (x4, white on
                                                  flag 8.5:1) can sit in it.

The pale silhouettes for the teaser rows (`<silhouette>_pale`, U7: the plate icon in `ui_dim` with a `ui_rule` edge) are
made by the pipeline from every shipped `source_*_icon_sil` (pipeline/od-sevev/sprites.py `pale_silhouettes`), because the
rendered sources' silhouettes are not authored here.
"""
from pix import Layer
from kit import save, panel, chamfer, outline_inplace
from palette import PAL

G = "controls"


# ------------------------------------------------------------------ U2 / A4: the white primary button
def button_white(W=24, H=20):
    # default: rows 0 outline | 1..15 white face | 16 silver shade | 17 flag | 18 flag_dk | 19 outline
    d = panel(W, H, "white", "white", "silver", lip=2, lip_c="flag")
    d.hline(1, W - 2, H - 2, "flag_dk")                 # the lip's lower row: the key's side in the flag's blue
    save(d, "button_white_default", G, state="default", slice=[3, 3, 3, 4], content=[3, 2, W - 6, H - 6],
         label="flag",
         notes="U2 / A4 (UX review 2): the v4 primary button, the flag's white on its blue. A white face, a silver "
               "bottom/right shade, a 2-row flag-blue lip (flag over flag_dk: the key's side) and the outline. Label "
               "`flag` (#0038b8) 8.46:1. Same size, 9-slice and content box as button_primary_*, so it is a drop-in: "
               "kit_primary -> button_white. It tells itself from button_secondary (ui_bubble + white, 7.5:1) by value "
               "(white vs ui_bubble 7.5:1; was flag vs ui_bubble 1.13:1) and by the label colour. One per screen. On a "
               "cream or white surface (the share sheet, the gate) the outline carries it (17.9:1 vs white).")
    p = Layer(W, H)
    pf = panel(W, H - 2, "silver", "grey", "silver", bevel=1)
    pf.hline(1, W - 2, 1, "grey"); pf.vline(1, 1, H - 4, "grey")        # the inner shadow: the key is down
    pf.hline(1, W - 2, H - 4, "silver"); pf.vline(W - 2, 2, H - 4, "silver")
    p.paste(pf, 0, 2)
    save(p, "button_white_pressed", G, state="pressed", slice=[3, 5, 3, 2], content=[3, 4, W - 6, H - 6],
         label="flag", notes="Pressed: the face drops 2 art px into the lip (the blue side disappears), silver with a "
         "grey inner shadow; the label moves +2 with it. flag on silver 6.40:1.")
    x = Layer(W, H)
    x.paste(panel(W, H - 2, "suit_dk", "suit_dk", "night", bevel=0), 0, 2)
    save(x, "button_white_disabled", G, state="disabled", slice=[3, 5, 3, 2], content=[3, 4, W - 6, H - 6],
         label="grey", notes="Disabled: the shared sunk, flat slate (= button_primary_disabled, pixel for pixel), label "
         "grey 5.5:1. Disabled never masquerades as a colour variant.")


# ------------------------------------------------------------------ U7: teaser rows and the navy system pill
def silhouette_row(W=32, H=30):
    L = Layer(W, H)
    L.rect(0, 1, W, H - 1, "ui_mute")                  # sunk 1 art px, like card_source_locked
    L.hline(1, W - 2, 2, "ui_dim")                      # the sunk top: one inner shadow row
    chamfer(L, 0, 1, W, H - 1, 1)
    outline_inplace(L, "ui_rule")                      # the edge in the dividers' blue, no ink outline
    save(L, "card_row_silhouette", "cards", state="teaser", slice=[4, 4, 4, 4], content=[3, 3, W - 6, H - 6],
         label="ui_panel",
         notes="U7 (UX review 2): a not-yet-revealed source row on the white pane, a blank pale slip. ui_mute face, a "
               "1 art px ui_rule edge (5.58:1 on the white pane; the face alone is 1.33:1, so the edge carries the "
               "shape), sunk 1 px with a ui_dim inner top row, chamfered, no ink outline (a blank slip, the lightest "
               "object on the pane; the saturated blue cards with gold pills stay the strong ones). Replaces "
               "card_source_locked (suit_dk slate, the pane's heaviest value) for the teaser and silhouette rows. "
               "Name 'מקור עלום' in ui_panel 8.87:1; the plate keeps card_plate, the icon is the pale silhouette "
               "`<silhouette>_pale` (ui_dim with a ui_rule edge, 5.58:1 on the slip); no pill.",
         extra={"textColors": {"name": "ui_panel", "line2": "ui_panel"},
                "hex": {"ui_mute": PAL["ui_mute"], "ui_rule": PAL["ui_rule"], "ui_panel": PAL["ui_panel"],
                        "ui_dim": PAL["ui_dim"]}})


def system_pill_navy(W=20, H=13):
    L = Layer(W, H)
    L.rect(0, 0, W, H, "ui_scrim")
    chamfer(L, 0, 0, W, H, 2)
    outline_inplace(L, "ui_rule")
    save(L, "chat_system_pill_navy", "chat", slice=[4, 3, 4, 3], content=[3, 2, W - 6, 9], label="ui_mute",
         notes="U7 (UX review 2): T3's system pill on the v4 thread (ui_panel). A flat ui_scrim well with a 1 art px "
               "ui_rule edge (fill 1.46:1 and edge 2.11:1 vs the thread, the edge 3.08:1 vs the well), no light bevel "
               "(a system line is not a button). Label ui_mute 12.91:1. Same size, 9-slice and content box as "
               "chat_system_pill, which stays (the picker's fresh chip still reads it).",
         extra={"hex": {"ui_scrim": PAL["ui_scrim"], "ui_rule": PAL["ui_rule"], "ui_mute": PAL["ui_mute"]}})


# ------------------------------------------------------------------ U10: the printed notice
def notice_frame(W=40, H=40):
    L = Layer(W, H)
    L.rect(0, 0, W, H, "white")
    for y in (1, 2, 3, 5, H - 4, H - 2):                # top: flag x3, a white gap, flag x1; bottom: flag, gap, flag
        L.hline(0, W - 1, y, "flag")
    chamfer(L, 0, 0, W, H, 1)
    outline_inplace(L)
    save(L, "notice_frame", "sheet", slice=[3, 7, 3, 5], content=[4, 8, W - 8, H - 14], label="night",
         notes="U10 (UX review 2): EVOLVE_TX dressed as the gate's printed notice. A white notice card ruled in flag "
               "blue edge to edge, at the top (3 rows, a white gap, 1 row) and the bottom (1, gap, 1), with the outline "
               "and 1-px chamfered corners: the HTML gate's card (#od-gate .od-card ::before/::after) on the kit grid. "
               "Draw it on the flag-blue page (`colors.page`), centred, around the card's lines (9-slice [3, 7, 3, 5]; "
               "the centre is plain white, so it stretches to any size). 'הכנסת פוזרה.' in `colors.title` (flag, "
               "8.46:1), the rest in `colors.text` (night, 13.88:1). Not full bleed: a white screen with a blue stripe "
               "at the top and the bottom is the flag's own layout with the text where the star sits (style guide "
               "§2.4, the rejected 'whole page as the flag'). A notice card on the blue page is the approved gate. "
               "Blank: no emblem, no institution's name, no seal.",
         extra={"colors": {"page": "flag", "title": "flag", "text": "night", "frame": "white"},
                "hex": {"flag": PAL["flag"], "night": PAL["night"], "white": PAL["white"]}})


# ------------------------------------------------------------------ A5: the booth with a title header
def booth_tall(W=40, HDR=12):
    H = 40 + (HDR - 7) + 1                              # booth_frame is 40 tall with a 7-row header (row 0 = outline)
    L = Layer(W, H)
    L.rect(0, 0, W, H, "paper")                          # cardboard, off-white
    L.rect(0, 0, W, HDR + 1, "flag")                     # rows 1..HDR: the header (row 0 becomes the outline)
    L.hline(0, W - 1, HDR + 1, "white")
    top = HDR + 3                                        # the opening's first row (booth_frame: 9)
    for y in range(HDR + 2, H):                          # the side wings, folded back
        L.hline(0, 3, y, "stone_sh"); L.hline(W - 4, W - 1, y, "stone_sh")
        L.set(4, y, "receipt_sh"); L.set(W - 5, y, "receipt_sh")
    for y in range(top, H - 3):
        for x in range(5, W - 5):
            L.px[y][x] = None
    L.hline(5, W - 6, H - 3, "receipt_sh")
    outline_inplace(L)
    save(L, "booth_frame_tall", "picker", slice=[6, top + 1, 6, 4], mode="stretch", content=[5, top, W - 10, H - top - 3],
         label="white",
         extra={"titleBox": [6, 2, W - 12, 9], "header": [1, 1, W - 2, HDR]},
         notes="A5 (mobile-first §5.14.2, optional): booth_frame with a 12-row flag-blue header (rows 1-12), so the "
               "picker title can sit in the booth: white on flag 8.46:1. `titleBox` [6, 2, w - 12, 9] is the text cell "
               "(the x4 Sevev 9 cell is 9 art rows; x5 large text is 45 logical, inside the 48 of the header). The "
               "opening, the wings and the bottom are booth_frame's exactly, 6 rows lower: 9-slice [6, 16, 6, 4], "
               "content [5, 15, 30, 28] (booth_frame: [6, 10, 6, 4], [5, 9, 30, 28]). Net: the title's own row and its "
               "16 gap above the booth go back to the sky; the booth's top inset grows 36 -> 60 logical. One line only: "
               "a 2-line title keeps booth_frame with the title above it. Blank otherwise: no emblem, no letters.")


# ------------------------------------------------------------------ proof
PALE = {"suit": "ui_dim", "rim": "ui_rule"}          # the pale silhouette recolour (the pipeline's pale_silhouettes)


def proof():
    """proofs/kit-w10-review2.png: every wave-10 piece in its v4 context, before | after, at the game's x4."""
    import json
    import os
    from PIL import Image, ImageDraw
    import hebfont
    import sheet
    from kit import PROOFS, ROOT
    from palette import rgb
    kit = {e["id"]: e for e in json.load(open(os.path.join(ROOT, "ui-kit.json")))["pieces"]}

    def img(pid):
        return Image.open(os.path.join(ROOT, kit[pid]["file"])).convert("RGBA")

    def nine(pid, w, h):
        e = kit[pid]
        return sheet.nine(img(pid), e["slice"], w, h, e.get("mode", "stretch"))

    def text(t, color):
        L = Layer(max(hebfont.measure(t), 1) + 2, 11)
        hebfont.draw(L, t, 0, 0, color, align="left")
        return L.to_image(1)

    def put_c(dst, im, cx, y):
        dst.alpha_composite(im, (cx - im.width // 2, y))

    def pale(im):
        inv = {rgb(k): v for k, v in PALE.items()}
        out = im.copy()
        px = out.load()
        for y in range(out.height):
            for x in range(out.width):
                r, g, b, a = px[x, y]
                if a:
                    px[x, y] = rgb(inv[(r, g, b)]) + (255,)
        return out

    def plain(w, h, sw):
        return Image.new("RGBA", (w, h), (rgb(sw) if isinstance(sw, str) else sw) + (255,))

    W = 180
    tiles = []
    # 1. O3's buttons on the modal body: before (flag primary / ui_bubble secondary) | after (white / the gold CTA)
    for kind in ("before", "after"):
        t = plain(W, 84, "ui_panel")
        prim = "button_primary_default" if kind == "before" else "button_white_default"
        lab = "white" if kind == "before" else "flag"
        for i, (pid, lbl, col) in enumerate(((prim, "לשתף", lab), ("button_secondary_default", "סגור", "white"))):
            t.alpha_composite(nine(pid, 76, 22), (12 + i * 80, 4))
            put_c(t, text(lbl, col), 12 + i * 80 + 38, 4 + 7)
        g = "button_primary_default" if kind == "before" else "button_gold_default"
        t.alpha_composite(nine(g, 136, 22), (22, 32))
        put_c(t, text("לפזר את הכנסת", "white" if kind == "before" else "ink"), 90, 32 + 7)
        t.alpha_composite(nine("button_secondary_default", 136, 22), (22, 58))
        put_c(t, text("עוד לא", "white"), 90, 58 + 7)
        tiles.append((f"U2 a pair + O3's stack, {kind}", t))
    t = plain(W, 84, "ui_panel")
    for i, st in enumerate(("default", "pressed", "disabled")):
        t.alpha_composite(nine(f"button_white_{st}", 52, 22), (6 + i * 58, 8))
        dy = 2 if st != "default" else 0
        put_c(t, text("לשתף", "flag" if st != "disabled" else "grey"), 6 + i * 58 + 26, 8 + 7 + dy)
    cream = plain(W, 44, (255, 244, 224))
    cream.alpha_composite(nine("button_white_default", 136, 22), (22, 11))
    put_c(cream, text("לשמור תמונה", "flag"), 90, 11 + 7)
    t.alpha_composite(cream, (0, 40))
    tiles.append(("U2 white: default / pressed / disabled; on cream", t))
    # 2. the white pane: a real card over teaser rows, before | after
    for kind in ("before", "after"):
        t = plain(W, 100, "white")
        t.alpha_composite(nine("card_source_unaffordable", 172, 30), (4, 2))
        t.alpha_composite(img("card_plate"), (4 + 172 - 29, 4))
        t.alpha_composite(img("source_checkbook_icon"), (4 + 172 - 28, 5))
        t.alpha_composite(text("פנקס צ'קים", "white"), (4 + 172 - 32 - hebfont.measure("פנקס צ'קים"), 6))
        t.alpha_composite(nine("pay_pill_default", 54, 17), (8, 8))
        for r, sil in enumerate(("source_submarine_icon_sil", "source_poison_icon_sil")):
            y = 34 + r * 32
            row = "card_source_locked" if kind == "before" else "card_row_silhouette"
            t.alpha_composite(nine(row, 172, 30), (4, y))
            t.alpha_composite(img("card_plate"), (4 + 172 - 29, y + 3))
            t.alpha_composite(img(sil) if kind == "before" else pale(img(sil)), (4 + 172 - 28, y + 4))
            nm = "מקור עלום"
            t.alpha_composite(text(nm, "silver" if kind == "before" else "ui_panel"),
                              (4 + 172 - 32 - hebfont.measure(nm), y + 6))
        tiles.append((f"U7 the pane, {kind}", t))
    # 3. the thread: the system pill, before | after
    t = plain(W, 40, "ui_panel")
    for i, (pid, col) in enumerate((("chat_system_pill", "white"), ("chat_system_pill_navy", "ui_mute"))):
        lbl = "היום"
        w = hebfont.measure(lbl) + 12
        t.alpha_composite(nine(pid, w + 20, 13), (20 + i * 80, 14))
        put_c(t, text(lbl, col), 20 + i * 80 + (w + 20) // 2, 16)
    tiles.append(("U7 T3 system pill: before | after", t))
    # 4. the tab bar: the coalition icon, idle / active, with and without the badge
    t = plain(W, 40, "ui_panel")
    t.alpha_composite(sheet.nine(img("tabbar"), kit["tabbar"]["slice"], W, 26), (0, 7))
    for i, (st, badge) in enumerate((("idle", False), ("idle", True), ("active", False), ("active", True))):
        x = i * 45
        if st == "active":
            t.alpha_composite(img("tab_active"), (x, 7))
        t.alpha_composite(img(f"tabicon_coalition_{st}"), (x + 15, 9))
        if badge:
            t.alpha_composite(img("badge_count"), (x + 11, 7))
            put_c(t, text("1", "white"), x + 16, 8)
    tiles.append(("U8 coalition tab: idle, +badge, active, +badge", t))
    # 5. EVOLVE_TX as the printed notice
    t = plain(W, 110, "flag")
    t.alpha_composite(nine("notice_frame", 164, 80), (8, 15))
    for y, (line, col) in zip((25, 37, 51, 61, 71), (("הכנסת פוזרה. מתחילים:", "flag"), ("סבב בחירות מס׳ 2", "flag"),
                                                    ("המכפיל עולה", "night"), ("+12 אגודלים", "night"),
                                                    ("תקופה: הכנסת", "night"))):
        put_c(t, text(line, col), 90, y)
    tiles.append(("U10 EVOLVE_TX: the notice on the flag-blue page", t))
    # 6. the booth, and the tall booth with the title in its header
    t = plain(W, 110, "night")
    t.alpha_composite(nine("booth_frame", 84, 60), (2, 40))
    put_c(t, text("מי ינהל?", "white"), 44, 26)
    t.alpha_composite(nine("booth_frame_tall", 84, 66), (94, 34))
    put_c(t, text("מי ינהל?", "white"), 136, 36)
    for bx in (9, 101):
        for c in range(2):
            t.alpha_composite(nine("pick_tile_idle", 30, 36), (bx + 4 + c * 36, 51 if bx == 9 else 51))
    tiles.append(("A5 booth_frame | booth_frame_tall", t))
    # 7. U1: sheet_modal 9-sliced at a card size with its own slice (no slab under the point)
    t = plain(W, 110, "outline")
    t.alpha_composite(nine("sheet_modal", 164, 100), (8, 5))
    put_c(t, text("לפזר את הכנסת?", "white"), 90, 9)
    put_c(t, text("בן גביר · עוצמה יהודית", "white"), 90, 30)
    tiles.append(("U1 sheet_modal [7, 24, 7, 7]: no slab", t))

    pad, cap = 6, 12
    rows = [tiles[i:i + 2] for i in range(0, len(tiles), 2)]
    H = sum(max(t.height for _, t in r) + cap + pad for r in rows) + pad
    out = Image.new("RGBA", (2 * (W + pad) + pad, H), (46, 40, 62, 255))
    y = pad
    caps = []
    for r in rows:
        for i, (name, t) in enumerate(r):
            caps.append((pad + i * (W + pad), y, name))
            out.alpha_composite(t, (pad + i * (W + pad), y + cap))
        y += max(t.height for _, t in r) + cap + pad
    Z = 4
    out = out.resize((out.width * Z, out.height * Z), Image.NEAREST)
    d = ImageDraw.Draw(out)
    for x, yy, name in caps:
        d.text((x * Z, yy * Z + 8), name, fill=(235, 235, 245), font=sheet.FONT)
    fn = os.path.join(PROOFS, "kit-w10-review2.png")
    out.convert("RGB").save(fn)
    return fn


def build():
    button_white()
    silhouette_row()
    system_pill_navy()
    notice_frame()
    booth_tall()


if __name__ == "__main__":
    from kit import write_manifest
    build()
    print(write_manifest())
    print(proof())
