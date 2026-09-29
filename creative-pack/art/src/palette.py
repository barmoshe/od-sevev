"""The 'Od Sevev' master palette. Single source of truth.

45 swatches in 15 hue families. Every pixel in every asset is one of these.
Names are the swatch keys used in every sprite legend; hex values are sRGB.
`python3 palette.py` writes ../palette.png (swatch card) and ../palette.gpl (GIMP/Aseprite).
"""
from collections import OrderedDict

# (name, hex, family, role)
SWATCHES = [
    # --- inks & neutrals -------------------------------------------------
    ("ink",       "#1b1426", "ink",     "Outline for every sprite and glyph. Darkest value; never pure black."),
    ("night",     "#0f2350", "ink",     "v3 (od-sevev, 2026-09-29; was #2a2340): navy night sky base, deepest background, text plates."),
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
    ("pink",      "#f07fad", "pink",    "Sara's blazer, the protest's signs, Gotliv's top."),
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
    ("plum",      "#16357a", "plum",    "v3 (od-sevev; was #4a2552): velvet-blue curtain base, Balfour mid sky."),
    ("plum_hi",   "#2a57a6", "plum",    "v3 (od-sevev; was #7a3a7d): curtain fold light plane, Balfour horizon."),
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
    out = os.path.join(here, "..")
    # GIMP / Aseprite palette
    with open(os.path.join(out, "palette.gpl"), "w") as f:
        f.write("GIMP Palette\nName: od-sevev\nColumns: 8\n#\n")
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
    img.save(os.path.join(out, "palette.png"))
    print(len(SWATCHES), "swatches,", len({s[2] for s in SWATCHES}), "families")
