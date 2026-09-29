"""The "עוד סבב" wordmark (v2, the detailed look) and the shared display-lettering renderer that the
event banners use.

v1 (creative pack) was 18 px cap, 3 px strokes, flat gold + 2 px extrusion + ink outline (102x28).
v2 follows the approved cast: more tones per surface and a near-black outline, plus the pale rim
the cast's star and props wear, so it holds on every stage.
  fill      gold_hi on top/left stroke edges, gold body, gold_sh on bottom/right edges, white glints
  extrusion 3 px down-right: orange_sh, then wood_dk for the far side (depth reads at a thumbnail)
  outline   1 px `outline` around the letters + extrusion
  rim       1 px `rim` outside the outline (dark-stage separation)
Cap 22 art px, strokes 4 art px -> 88 logical px tall letters on the 720 canvas.
"""
import os
from pix import Layer
from letters import word
from kit import save, OUT

FILL = dict(hi="gold_hi", body="gold", sh="gold_sh", glint="white", ext=("orange_sh", "wood_dk"))


def render(text, H, S, *, ext=3, fill=FILL, outline="outline", rim="rim", gap=None, space=None):
    m, w, top, bot = word(text, H, S, gap)
    pad = ext + 3
    Wd, Ht = w + 2 * pad, (bot - top + 1) + 2 * pad
    L = Layer(Wd, Ht)
    ox, oy = pad - 1, pad - 1 - top          # shift so the extrusion room is at bottom-right
    # extrusion first (behind), far layer then near layer
    for d in range(ext, 0, -1):
        c = fill["ext"][1] if d > 1 else fill["ext"][0]
        for (x, y) in m:
            L.set(ox + x + d, oy + y + d, c)
    for (x, y) in m:
        up, dn = (x, y - 1) in m, (x, y + 1) in m
        lf, rt = (x - 1, y) in m, (x + 1, y) in m
        c = fill["body"]
        if not dn or not rt:
            c = fill["sh"]
        if not up or not lf:
            c = fill["hi"]
        if not up and not lf:
            c = fill["glint"]
        L.set(ox + x, oy + y, c)
    L = L.outlined(outline, pad=0)
    if rim:
        L = L.outlined(rim, pad=0)
    # trim to content
    xs = [x for y in range(L.h) for x in range(L.w) if L.px[y][x] is not None]
    ys = [y for y in range(L.h) for x in range(L.w) if L.px[y][x] is not None]
    T = Layer(max(xs) - min(xs) + 1, max(ys) - min(ys) + 1)
    for y in range(T.h):
        for x in range(T.w):
            T.px[y][x] = L.px[y + min(ys)][x + min(xs)]
    return T


def build():
    wm = render("עוד סבב", 22, 4)
    save(wm, "wordmark", "key", pivot=[wm.w // 2, wm.h - 1],
         notes="Title-screen wordmark, 1x art px (x4 in game = %dx%d logical). Custom lettering on the parametric "
               "Hebrew block skeleton (letters.py) shared with the banners and the 5x9 UI cut's letter logic." % (wm.w * 4, wm.h * 4))
    norim = render("עוד סבב", 22, 4, rim=None)
    save(norim, "wordmark_norim", "key", notes="For light or busy backgrounds where the pale rim would halo.")
    mono = render("עוד סבב", 22, 4, fill=dict(hi="ink", body="ink", sh="ink", glint="ink", ext=("ink", "ink")),
                  outline="ink", rim=None)
    save(mono, "wordmark_mono", "key", notes="One-colour stamp/print version (the silhouette test).")
    sm = render("עוד סבב", 11, 2, ext=1)
    save(sm, "wordmark_small", "key", notes="Small cut (cap 11, stroke 2) for the result card and the receipt header.")
    return wm


if __name__ == "__main__":
    build()
    from kit import write_manifest
    print(write_manifest())
