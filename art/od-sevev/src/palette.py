"""The 'Od Sevev' GRAPHIC-TIER palette, v4 (UI kit, wordmark, key art, hand-drawn props).

v1 (creative pack) had 45 swatches in 15 families. v2 kept all 45 and added the UI / new-look
swatches. v3 (2026-09-29, Bar: "more in Israel's palette, with blue and white") re-values the
plum/violet chrome darks into a navy family around the flag blue (#0038b8), keeping every id, and
adds `ui_mute` and `ui_rule` (style-guide.md section 2.3). `night`, `plum` and `plum_hi` shift in the
creative pack's palette too, so Balfour's sky and the curtain move with the chrome.
v4 (2026-09-29, Bar: "more Israel theme and palette"): the flag's LAYOUT, not just its colours. The raised
chrome (cards, bubbles, tiles, panels) moves from navy up to the flag's own blue, white text stays white
(7.5-11.8:1), navy stays only as the deepest base (wells, behind the stage); the code map (palette-v4-map.json)
makes the card pane a white field between the blue ticker and the blue tab bar. Text-on-blue swatches are
lifted to clear 4.5:1 on the flag blues (`ui_mute`, `stamp_lt`; new `ui_dim`, `alert_lt`). style-guide.md 2.4. The CAST tier (rendered-down
caricatures) does not draw from this list: each character has its own locked palette.
Every pixel in every graphic-tier asset is one of these.
Names are the swatch keys used in every sprite legend; hex values are sRGB.
`python3 palette.py` writes ../palette.png (swatch card) and ../palette.gpl (GIMP/Aseprite).
"""
from collections import OrderedDict

# (name, hex, family, role)
SWATCHES = [
    # --- inks & neutrals -------------------------------------------------
    ("ink",       "#1b1426", "ink",     "Outline for every sprite and glyph. Darkest value; never pure black."),
    ("night",     "#0f2350", "ink",     "v3 navy (was #2a2340): night sky base (Balfour), deepest background, text plates, the shop pane."),
    ("suit_dk",   "#2f3042", "neutral", "Dark-suit shadow; interior lines on suits."),
    ("suit",      "#454a60", "neutral", "Dark-suit base (the Magician, most politicians)."),
    ("suit_hi",   "#636a86", "neutral", "Dark-suit light plane (top-left)."),
    ("slate",     "#7d8398", "neutral", "Mid grey: grey hair shadow, stone shadow at night."),
    ("grey",      "#a4a9b8", "neutral", "Grey hair / beards / stubble."),
    ("silver",    "#d3d6df", "neutral", "Silver hair (the Magician, Lapid); metal highlights."),
    ("white",     "#f7f4ec", "neutral", "Shirts, text, highlights. Warm white, never #fff."),
    ("paper",     "#ddd5c0", "neutral", "White-cloth shadow, signs, paper."),
    # --- skin (one ramp for the whole cast: skin is not a caricature channel)
    ("skin_hi",   "#f7cfa6", "skin",    "Skin light plane (forehead, nose tip)."),
    ("skin",      "#e3a97c", "skin",    "Skin base."),
    ("skin_sh",   "#c27f58", "skin",    "Skin shadow (right side, under brows, under chin)."),
    ("skin_dk",   "#8e5440", "skin",    "Mouth line, nostril, deepest skin shadow."),
    # --- hair --------------------------------------------------------------
    ("hair_dk",   "#2b2124", "hair",    "Dark hair and dark beards."),
    ("hair_br",   "#5a3d30", "hair",    "Dark-hair light plane, brown hair."),
    ("blonde",    "#efe2b4", "hair",    "Platinum blonde (Sara)."),
    ("blonde_sh", "#c9b27a", "hair",    "Platinum blonde shadow."),
    # --- blues -------------------------------------------------------------
    ("navy",      "#1f2b63", "blue",    "Navy suits (Bennett), Washington night, UI panel base."),
    ("navy_hi",   "#34498f", "blue",    "RESERVED: the Magician's navy suit light plane (his suit = navy / navy_hi / night)."),
    ("flag",      "#0038b8", "blue",    "RESERVED: the Magician's tie, flag pin, primary UI button."),
    ("flag_hi",   "#3f74e6", "blue",    "Flag-blue light plane; UI button hover."),
    ("sky",       "#8fc0ff", "blue",    "Day sky (Knesset, Washington)."),
    # --- reds & pinks --------------------------------------------------------
    ("maroon",    "#8a1538", "maroon",  "RESERVED: the Suitcase only. Nothing else on screen may be maroon."),
    ("maroon_dk", "#560b24", "maroon",  "RESERVED: Suitcase shadow."),
    ("red",       "#d02a36", "red",     "Danger (court meter, quit threats), the news-flash label, Smotrich's tie. White on red = 4.70:1. Always paired with a shape cue."),
    ("pink",      "#f07fad", "pink",    "Sara's blazer, Gotliv's top (not the protest signs: kraft since B14)."),
    ("pink_sh",   "#c4507f", "pink",    "Pink shadow."),
    # --- oranges & golds -----------------------------------------------------
    ("orange",    "#f5871f", "orange",  "Carrot, street lamps, Gotliv's loud jacket."),
    ("orange_sh", "#b85a17", "orange",  "Orange shadow."),
    ("gold",      "#f5c542", "gold",    "RESERVED: money (shekels), the wordmark, reward moments."),
    ("gold_sh",   "#c68a2b", "gold",    "Gold shadow / coin rim."),
    ("gold_hi",   "#fff1a6", "gold",    "Gold glint; lamp glow core."),
    # --- greens & teals ------------------------------------------------------
    ("green",     "#3fae4a", "green",   "Dubi the parrot; carrot leaves; lawns."),
    ("green_sh",  "#1f7a3d", "green",   "Green shadow; olive-tree canopy."),
    ("lime",      "#a3d84a", "green",   "Dubi's head highlight; lawn light."),
    ("teal_dk",   "#1e3a37", "teal",    "Courthouse deep shadow."),
    ("teal",      "#3a655e", "teal",    "Courthouse walls."),
    ("teal_hi",   "#79a597", "teal",    "Courthouse fluorescent-lit planes."),
    # --- earth & stone --------------------------------------------------------
    ("stone",     "#e4d3a8", "stone",   "Jerusalem stone (Knesset), Balfour walls in lamp light."),
    ("stone_sh",  "#b39d72", "stone",   "Stone shadow."),
    ("wood",      "#8a5632", "wood",    "Court benches, the Balfour gate, podium."),
    ("wood_dk",   "#55331f", "wood",    "Wood shadow."),
    # --- stage purple ---------------------------------------------------------
    ("plum",      "#16357a", "plum",    "v3 velvet blue (was #4a2552): stage curtain base (title, OG, icon), Balfour's mid sky. Id kept."),
    ("plum_hi",   "#2a57a6", "plum",    "v3 (was #7a3a7d): curtain fold light plane, Balfour's horizon band. Id kept."),
    # --- v2 additions: the new look (dark outline, pale rim) and the UI kit ----------
    ("outline",   "#0b0a12", "ink",     "v2: outer silhouette of every graphic-tier sprite and UI piece; matches the cast's near-black outline."),
    ("rim",       "#d6ccec", "rim",     "v2: pale 1px rim outside the outline on things the player touches on the stage (the Magician, hat, rabbit, the Suitcase)."),
    ("ui_scrim",  "#061029", "ui",      "v3 deep navy (was #140c24): HUD row A scrim, wells (meter tracks), the deepest UI surface."),
    ("ui_panel",  "#072a7a", "ui",      "v4 deep flag blue (v3 #0a1a42, v2 #1e1636): panel / header / tab-bar / sheet body (the blue envelope). white 11.8:1."),
    ("ui_bubble", "#1045b5", "ui",      "v4 flag blue, raised (v3 #112a64, v2 #2e2250): cards, picker tiles, incoming bubbles, secondary button. white 7.5:1."),
    ("ui_bub_hi", "#4f82e8", "ui",      "v4 (v3 #26499c, v2 #4a3c7c): top/left bevel light on ui_bubble and ui_panel; the round close face."),
    ("ui_out",    "#4a3a10", "gold",    "v2: the player's own chat bubble (UX: dark gold, because the player is the one paying)."),
    ("ui_out_hi", "#72601f", "gold",    "v2: bevel light on ui_out."),
    ("gold_dk",   "#7d5412", "gold",    "v2: gold lip / pressed gold face edge (money controls only)."),
    ("flag_dk",   "#00237a", "blue",    "v2: primary (flag) button lip and pressed face. Reserved with flag."),
    ("red_hi",    "#f86b5d", "red",     "v2: danger-fill light plane (thermometer, ultimatum chip)."),
    ("red_dk",    "#8f1d22", "red",     "v2: danger-fill shadow; hatch stripe partner. Not maroon: hue 357, and never on a case shape."),
    ("stamp",     "#5b3b9e", "stamp",   "v2: rubber-stamp ink on light (paper) surfaces. Bureaucracy violet: not danger, not money."),
    ("stamp_lt",  "#d8ccff", "stamp",   "v4 (v2 #b9a0ef): the same stamp on dark and blue surfaces (5.5:1 on the v4 ui_bubble)."),
    ("receipt",   "#f4f1e8", "receipt", "v2: thermal-receipt paper (UX 5.1)."),
    ("receipt_sh","#d8d1bf", "receipt", "v2: receipt paper shadow, curl, tear-edge fibre."),
    ("receipt_ink","#1a1a1a","receipt", "v2: thermal print ink (UX 5.1: 15.4:1 on receipt). The one near-neutral black; used only on the receipt."),
    # --- v3 additions: the blue-and-white chrome (Bar, 2026-09-29) ---------------------------------
    ("ui_mute",   "#c9d6f2", "ui",      "v4 (v3 #a3b3d3): secondary labels on blue (the picker's party line, idle tab labels, names); replaces UX's #9e99ad and the code's grey text. 5.7:1 on ui_bubble."),
    ("ui_rule",   "#2a5cc4", "ui",      "v4 (v3 #1c3876): dividers and hairlines on the blue panels (replaces #2e2548)."),
    ("ui_dim",    "#b4c3e8", "ui",      "v4: tertiary text on blue (the code's slate text: timestamps, counts). 4.7:1 on ui_bubble, 7.4:1 on ui_panel."),
    ("alert_lt",  "#ffaa9f", "red",     "v4: alert TEXT on blue ('אולטימטום', the last seconds): red_hi was 2.9:1 on the flag blue. 4.5:1 on ui_bubble. Always with its shape (hazard band, clock)."),
]


PAL = OrderedDict((n, h) for n, h, _, _ in SWATCHES)


def rgb(name):
    h = PAL[name].lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def luminance(name):
    """Relative luminance (WCAG) of a swatch."""
    def ch(c):
        c = c / 255
        return c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4
    r, g, b = rgb(name)
    return 0.2126 * ch(r) + 0.7152 * ch(g) + 0.0722 * ch(b)


def contrast(a, b):
    la, lb = luminance(a), luminance(b)
    hi, lo = max(la, lb), min(la, lb)
    return (hi + 0.05) / (lo + 0.05)


if __name__ == "__main__":
    import os
    from PIL import Image, ImageDraw, ImageFont
    here = os.path.dirname(os.path.abspath(__file__))
    out = os.path.join(here, "..", "out")
    # GIMP / Aseprite palette
    with open(os.path.join(out, "palette-v4.gpl"), "w") as f:
        f.write("GIMP Palette\nName: od-sevev-graphic-v4\nColumns: 8\n#\n")
        for n, h, fam, role in SWATCHES:
            r, g, b = rgb(n)
            f.write(f"{r:3d} {g:3d} {b:3d}\t{n}\n")
    # swatch card (caption strip uses a system font: it is outside the art)
    cols, sw, sh = 4, 230, 44
    rows = (len(SWATCHES) + cols - 1) // cols
    img = Image.new("RGB", (cols * sw, rows * sh), (20, 18, 28))
    d = ImageDraw.Draw(img)
    try:
        font = ImageFont.truetype("/System/Library/Fonts/Menlo.ttc", 12)
    except Exception:
        font = ImageFont.load_default()
    for i, (n, h, fam, role) in enumerate(SWATCHES):
        x, y = (i % cols) * sw, (i // cols) * sh
        d.rectangle([x + 4, y + 4, x + 40, y + sh - 4], fill=rgb(n))
        d.text((x + 48, y + 8), n, fill=(240, 240, 240), font=font)
        d.text((x + 48, y + 24), f"{h}  L={luminance(n):.2f}", fill=(170, 170, 185), font=font)
    img.save(os.path.join(out, "palette-v4.png"))
    print(len(SWATCHES), "swatches,", len({s[2] for s in SWATCHES}), "families")
