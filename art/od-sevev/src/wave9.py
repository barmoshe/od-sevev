"""Wave 9 (2026-09-30): the Animator's wave-B ask, the blue envelope's flap as its own layer.

  sheet_modal_body   38x38        the modal's envelope without its flap: the same 9-slice [7, 23, 7, 7] and content
                                  box as sheet_modal, so the two are interchangeable in `Ui.nine`
  sheet_modal_flap   38x24 x 3    the flap, drawn over the body's top: f0 sealed (a V from the corners to the
                                  point), f1 lifting, f2 open = the title band of sheet_modal, pixel for pixel.
                                  A horizontal 3-slice [7, 0, 7, 0]: the same columns as the body.

The invariant (asserted here): sheet_modal_body with sheet_modal_flap f2 on its top 24 rows is sheet_modal, every
pixel. sheet_modal itself is unchanged.

Why the strip is 24 rows and not 23: the flap's shadow at the point sits on sheet_modal's art row 23, the first row
of the stretched centre patch. Inside a 9-slice that one row is stretched down the whole body (at 624 logical px
wide and 480 tall: a ~190x45 dark slab, confirmed in the engine under the point). As part of the flap strip it stays one art row.
"""
import json
import os

from PIL import Image

from pix import Layer
from kit import save, strip, PROOFS
from palette import rgb
from wave2 import sheet_modal_layer, SHEET_W
import sheet

FLAP_H = 24
FLAP_SLICE = [7, 0, 7, 0]
BODY_SLICE = [7, 23, 7, 7]
POINT = 20                     # the flap's lowest flag row at the point (pre-pad), every frame


def v_bottom(side_row, W=SHEET_W):
    """A straight V inside the stretched centre columns: flat at `side_row` over the fixed 7-column margins, then
    one even staircase down to POINT at the middle two columns, so it stays a clean V at any modal width."""
    cx = (W - 1) / 2
    m0 = BODY_SLICE[0] - 1                  # first centre column, pre-pad (post-pad 7)
    half = cx - m0                          # 11.5
    def b(x):
        dist = abs(x - cx)
        if dist >= half:
            return side_row
        u = (half - dist) / (half - 0.5)    # 0 at the centre patch's edge, 1 at the middle two columns
        return side_row + int(round((POINT - side_row) * u))
    return b


FRAMES = (("sealed", v_bottom(2)), ("lifting", v_bottom(11)), ("open", None))


def _cut(full, body):
    """The flap alone: in each column, everything down to the lowest pixel that differs from the body; below that
    (the body showing through) transparent. The outline / edge columns follow their neighbour's cut."""
    W = full.w
    F = Layer(W, FLAP_H)
    cut = {}
    for x in range(W):
        rows = [y for y in range(FLAP_H) if full.get(x, y) != body.get(x, y)]
        cut[x] = max(rows) if rows else None
    for x in range(W):
        c = cut[x]
        if c is None:                                         # the edge columns: the nearest cut inward
            step = 1 if x < W // 2 else -1
            xx = x
            while cut[xx] is None:
                xx += step
            c = cut[xx]
        for y in range(c + 1):
            F.px[y][x] = full.px[y][x]
    return F


def _composite(body, flap):
    out = body.copy()
    for y in range(flap.h):
        for x in range(flap.w):
            if flap.px[y][x] is not None:
                out.px[y][x] = flap.px[y][x]
    return out


def build():
    body = sheet_modal_layer(band=False)
    modal = sheet_modal_layer()
    W = body.w
    save(body, "sheet_modal_body", "sheet", slice=BODY_SLICE, content=[7, 23, W - 14, body.h - 30], label="white",
         notes="The blue envelope without its flap (wave 9, the Animator's wave-B ask): sheet_modal's body, edge and "
               "9-slice [7, 23, 7, 7] exactly, with no title band. Never drawn alone: sheet_modal_flap sits on its top "
               "24 rows (frame 2 at rest), and body + flap f2 = sheet_modal pixel for pixel. Use it only where the flap "
               "animates; everywhere else sheet_modal stays.")
    frames = []
    for name, bottom in FRAMES:
        full = sheet_modal_layer(bottom) if bottom else modal
        frames.append(_cut(full, body))
    # the invariant: body + f2 is sheet_modal, every pixel (and the f2 cut is exactly the band)
    assert _composite(body, frames[2]).px == modal.px, "body + flap f2 != sheet_modal"
    for f in frames:
        assert f.w == W and f.h == FLAP_H
    save(strip(frames), "sheet_modal_flap", "sheet", slice=FLAP_SLICE, frames=3, frame_w=W, pivot=[0, 0],
         label="white",
         extra={"frameNames": [n for n, _ in FRAMES], "fps": 25, "loop": False, "base": "sheet_modal_body",
                "rows": [0, FLAP_H]},
         notes="The blue envelope's flap as a layer (wave 9, the Animator's wave-B ask). 3 frames of 38x24: f0 "
               "sealed (a V from the corners down to the point), f1 lifting, f2 open = sheet_modal's title band "
               "(the rest frame; body + f2 = sheet_modal, pixel for pixel). A horizontal 3-slice [7, 0, 7, 0] (the "
               "body's own columns; the V lives in the stretched centre, so it stays one even staircase at any "
               "width). Draw it with Ui.nine at the SAME x / width as the body and its top-left (pivot [0, 0]), 24 "
               "art rows tall (96 logical at x4), over sheet_modal_body and under the title and the close x. "
               "0 -> 1 -> 2 at 40 ms each on open, then hold 2. Reduced motion: frame 2 from the first frame. "
               "Transparent below the flap: the body shows through. Blank: no text, no emblem, no seal.")


def proof():
    """proofs/kit-w9-flap.png: the three frames over the body at the kit size and at a modal's size, on the scrim."""
    root = os.path.dirname(PROOFS)
    kit = {e["id"]: e for e in json.load(open(os.path.join(root, "ui-kit.json")))["pieces"]}

    def img(pid):
        return Image.open(os.path.join(root, kit[pid]["file"])).convert("RGBA")
    return contact(img("sheet_modal_body"), img("sheet_modal_flap"), img("sheet_modal"),
                   os.path.join(PROOFS, "kit-w9-flap.png"))


def contact(body, flap, modal, fn, sizes=((38, 38), (158, 64), (158, 120)), zoom=4):
    """Row per size: the body, f0, f1, f2 over the body, and today's sheet_modal 9-sliced to the same size."""
    fw = flap.width // 3
    pad = 6
    cols = 5
    cw = max(w for w, _ in sizes) + pad
    H = sum(h + pad for _, h in sizes) + pad
    out = Image.new("RGBA", (cols * cw + pad, H), rgb("ui_scrim") + (255,))
    y = pad
    for (w, h) in sizes:
        b9 = sheet.nine(body, BODY_SLICE, w, h)
        tiles = [b9]
        for i in range(3):
            f = flap.crop((i * fw, 0, (i + 1) * fw, flap.height))
            f9 = sheet.nine(f, FLAP_SLICE, w, flap.height)
            t = b9.copy()
            t.alpha_composite(f9, (0, 0))
            tiles.append(t)
        tiles.append(sheet.nine(modal, BODY_SLICE, w, h))
        for c, t in enumerate(tiles):
            out.alpha_composite(t, (pad + c * cw, y))
        y += h + pad
    out = out.resize((out.width * zoom, out.height * zoom), Image.NEAREST)
    out.save(fn)
    return fn


if __name__ == "__main__":
    from kit import write_manifest
    build()
    write_manifest()
    print(proof())
