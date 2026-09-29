"""Proof helpers: a 9-slice renderer (the same math as Godot NinePatchRect, STRETCH / TILE_FIT)
and a contact sheet that shows every registered piece at 1x-as-shipped and stretched.

Captions use a system font: they are outside the art and ship nowhere.
"""
import json
import os
from PIL import Image, ImageDraw, ImageFont

from kit import ROOT, PROOFS

try:
    FONT = ImageFont.truetype("/System/Library/Fonts/Menlo.ttc", 11)
except Exception:
    FONT = ImageFont.load_default()


def nine(img, sl, w, h, mode="stretch"):
    """Render a 9-slice RGBA image to w x h (art px). Nearest-neighbour only."""
    l, t, r, b = sl
    W, H = img.size
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    xs = [(0, l, 0, l), (l, W - r, l, w - r), (W - r, W, w - r, w)]
    ys = [(0, t, 0, t), (t, H - b, t, h - b), (H - b, H, h - b, h)]
    for (sx0, sx1, dx0, dx1) in xs:
        for (sy0, sy1, dy0, dy1) in ys:
            sw, sh, dw, dh = sx1 - sx0, sy1 - sy0, dx1 - dx0, dy1 - dy0
            if sw <= 0 or sh <= 0 or dw <= 0 or dh <= 0:
                continue
            part = img.crop((sx0, sy0, sx1, sy1))
            if mode == "tile" and (dw != sw or dh != sh):
                tile = Image.new("RGBA", (dw, dh))
                for yy in range(0, dh, sh):
                    for xx in range(0, dw, sw):
                        tile.paste(part, (xx, yy))
                part = tile
            else:
                part = part.resize((dw, dh), Image.NEAREST)
            out.paste(part, (dx0, dy0))
    return out


def piece_img(ent):
    return Image.open(os.path.join(ROOT, ent["file"])).convert("RGBA")


def contact(groups, name, zoom=4, bg=(46, 40, 62), cols_w=900):
    kit = json.load(open(os.path.join(ROOT, "ui-kit.json")))["pieces"]
    items = [e for e in kit if e["group"] in groups]
    rows = []
    for e in items:
        im = piece_img(e)
        show = [im]
        if e.get("slice"):
            l, t, r, b = e["slice"]
            show.append(nine(im, e["slice"], max(im.width * 3, l + r + 40), max(im.height, t + b + 12), e.get("mode", "stretch")))
        rows.append((e, show))
    # layout
    pad = 10
    x, y, lineh = pad, pad, 0
    placed = []
    for e, show in rows:
        wsum = sum(s.width * zoom for s in show) + pad * (len(show) - 1)
        hmax = max(s.height * zoom for s in show) + 16
        if x + wsum > cols_w and x > pad:
            x, y = pad, y + lineh + pad
            lineh = 0
        placed.append((e, show, x, y))
        x += wsum + pad * 2
        lineh = max(lineh, hmax)
    H = y + lineh + pad
    sheet = Image.new("RGBA", (cols_w, H), bg + (255,))
    d = ImageDraw.Draw(sheet)
    for e, show, x, y in placed:
        d.text((x, y), e["id"], fill=(225, 220, 240), font=FONT)
        xx = x
        for s in show:
            big = s.resize((s.width * zoom, s.height * zoom), Image.NEAREST)
            sheet.alpha_composite(big, (xx, y + 14))
            xx += big.width + pad
    os.makedirs(PROOFS, exist_ok=True)
    fn = os.path.join(PROOFS, name)
    sheet.save(fn)
    return fn


if __name__ == "__main__":
    import sys
    print(contact(sys.argv[1].split(","), sys.argv[2], int(sys.argv[3]) if len(sys.argv) > 3 else 4))
