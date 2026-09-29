"""Shared helpers for the od-sevev UI kit: bevelled panels, capsules, hatch, stamps, and the
export registry that writes every piece at 1x art px plus its 9-slice metadata.

Conventions (binding; see style-guide.md section 16):
  - 1 art px = 4 logical px in the 720x1280 game. Every PNG here is 1x; the engine scales x4.
  - slice = [left, top, right, bottom] in art px: Godot NinePatchRect patch_margin_* (x4 at runtime
    if the TA bakes at 4x; x1 if the node itself is scaled x4).
  - mode = 'stretch' | 'tile' (Godot axis_stretch_* = STRETCH / TILE_FIT). Hatch and speckle
    pieces are 'tile' so the pattern never smears.
  - content = [x, y, w, h] the text-safe box of the base PNG; it grows with the stretched centre.
  - label = swatch name of the label colour that clears 4.5:1 on that face.
  - Alpha is 0 or 255 only. Every colour is a palette swatch.
"""
import json
import os

from pix import Layer
from palette import PAL, contrast

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, ".."))
OUT = os.path.join(ROOT, "out")
PROOFS = os.path.join(ROOT, "proofs")

REGISTRY = []


def save(L, pid, group, *, slice=None, mode="stretch", content=None, label=None, frames=None,
         frame_w=None, notes="", state=None, pivot=None, extra=None):
    """Write out/ui/<group>/<pid>.png at 1x and register it for ui-kit.json."""
    d = os.path.join(OUT, "ui", group)
    os.makedirs(d, exist_ok=True)
    fn = os.path.join(d, pid + ".png")
    L.to_image(1).save(fn)
    ent = {"id": pid, "group": group, "file": os.path.relpath(fn, ROOT), "w": L.w, "h": L.h}
    if state:
        ent["state"] = state
    if slice:
        ent["slice"] = list(slice)
        ent["mode"] = mode
        assert slice[0] + slice[2] < L.w and slice[1] + slice[3] < L.h, (pid, slice, L.w, L.h)
    if content:
        ent["content"] = list(content)
    if label:
        ent["label"] = label
    if frames:
        ent["frames"] = frames
        ent["frameW"] = frame_w
    if pivot:
        ent["pivot"] = list(pivot)
    if notes:
        ent["notes"] = notes
    if extra:
        ent.update(extra)
    REGISTRY[:] = [e for e in REGISTRY if e["id"] != pid]
    REGISTRY.append(ent)
    return L


def strip(frames):
    """Horizontal strip of equal-size frames."""
    w, h = frames[0].w, frames[0].h
    S = Layer(w * len(frames), h)
    for i, f in enumerate(frames):
        assert (f.w, f.h) == (w, h)
        S.paste(f, i * w, 0)
    return S


def write_manifest():
    path = os.path.join(ROOT, "ui-kit.json")
    old = []
    if os.path.exists(path):
        try:
            old = json.load(open(path))["pieces"]
        except Exception:
            old = []
    ids = {e["id"] for e in REGISTRY}
    pieces = [e for e in old if e["id"] not in ids] + REGISTRY
    pieces.sort(key=lambda e: (e["group"], e["id"]))
    doc = {
        "artifact": "ui-artwork",
        "owner": "2d-artist",
        "game": "od-sevev",
        "units": "art px (1 art px = 4 logical px in the 720x1280 canvas)",
        "slice": "[left, top, right, bottom] 9-slice patch margins",
        "mode": "stretch | tile  (Godot NinePatchRect axis_stretch STRETCH | TILE_FIT)",
        "content": "[x, y, w, h] text-safe box in the base PNG; grows with the centre patch",
        "pieces": pieces,
    }
    json.dump(doc, open(path, "w"), ensure_ascii=False, indent=1)
    return path


# ---------------------------------------------------------------- drawing primitives
def chamfer(L, x, y, w, h, r=1):
    """Cut r-px staircase corners (transparent) on the rect."""
    for k in range(r):
        n = r - k
        for i in range(n):
            for (cx, cy) in ((x + i, y + k), (x + w - 1 - i, y + k),
                             (x + i, y + h - 1 - k), (x + w - 1 - i, y + h - 1 - k)):
                L.px[cy][cx] = None


def outline_inplace(L, color="outline"):
    """Paint `color` on every opaque pixel that touches transparency or the canvas edge
    (4-neighbour). Draws the outline INSIDE the silhouette, so the size never changes."""
    src = [row[:] for row in L.px]
    for y in range(L.h):
        for x in range(L.w):
            if src[y][x] is None:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                xx, yy = x + dx, y + dy
                if not (0 <= xx < L.w and 0 <= yy < L.h) or src[yy][xx] is None:
                    L.px[y][x] = color
                    break


def panel(w, h, face, hi, lo, *, outline="outline", corner=1, lip=0, lip_c=None, bevel=1):
    """Raised pixel panel: outline, 1px light bevel top+left, 1px dark bevel bottom+right,
    optional `lip` rows of lip_c under the face (the 'raised' depth), chamfered corners."""
    # rows: 0 outline | 1 hi | face ... | lo (row h-2-lip) | lip rows | h-1 outline
    L = Layer(w, h)
    L.rect(0, 0, w, h, face)
    lo_y = h - 2 - lip
    if bevel:
        L.hline(1, w - 2, 1, hi)
        L.vline(1, 1, lo_y, hi)
        L.hline(1, w - 2, lo_y, lo)
        L.vline(w - 2, 2, lo_y, lo)
    if lip:
        L.rect(0, lo_y + 1, w, lip, lip_c or lo)
    chamfer(L, 0, 0, w, h, corner)
    outline_inplace(L, outline)
    return L


def capsule(w, h, face, hi, lo, *, outline="outline", lip=0, lip_c=None, r=2):
    return panel(w, h, face, hi, lo, outline=outline, corner=r, lip=lip, lip_c=lip_c)


def hatch(L, x, y, w, h, a, b, period=4, on=2, slope=1, mask=None):
    """Diagonal stripes. (x+slope*y) % period < on -> a else b."""
    for yy in range(y, y + h):
        for xx in range(x, x + w):
            if mask and not mask(xx, yy):
                continue
            L.set(xx, yy, a if (xx + slope * yy) % period < on else b)


def speckle(L, color_from, color_to, seed, rate, box=None):
    """Replace a deterministic fraction of `color_from` pixels with `color_to` (stamp texture)."""
    import random
    rnd = random.Random(seed)
    x0, y0, w, h = box or (0, 0, L.w, L.h)
    for y in range(y0, y0 + h):
        for x in range(x0, x0 + w):
            if L.get(x, y) == color_from and rnd.random() < rate:
                L.px[y][x] = color_to


def grid_layer(rows, legend):
    w = max(len(r) for r in rows)
    L = Layer(w, len(rows))
    for j, r in enumerate(rows):
        for i, ch in enumerate(r):
            if ch in ". ":
                continue
            L.set(i, j, legend[ch])
    return L


def recolor(L, mapping):
    M = L.copy()
    for row in M.px:
        for i, c in enumerate(row):
            if c in mapping:
                row[i] = mapping[c]
    return M


def with_rim(L, rim="rim"):
    """Add the pale 1px rim outside the silhouette (grows the layer by 1 on each side)."""
    return L.outlined(rim, pad=1)


# 3x5 Latin/digit micro-font for stickers and tiny numerals (the Suitcase's DOHA, the cup's 5%)
MICRO = {
    "D": ["##.", "#.#", "#.#", "#.#", "##."],
    "O": ["###", "#.#", "#.#", "#.#", "###"],
    "H": ["#.#", "#.#", "###", "#.#", "#.#"],
    "A": [".#.", "#.#", "###", "#.#", "#.#"],
    "0": ["###", "#.#", "#.#", "#.#", "###"],
    "1": [".#.", "##.", ".#.", ".#.", "###"],
    "2": ["##.", "..#", ".#.", "#..", "###"],
    "4": ["#.#", "#.#", "###", "..#", "..#"],
    "5": ["###", "#..", "##.", "..#", "##."],
    "6": [".##", "#..", "###", "#.#", "###"],
    "%": ["#.#", "..#", ".#.", "#..", "#.#"],
    ".": ["...", "...", "...", "...", ".#."],
    "!": [".#.", ".#.", ".#.", "...", ".#."],
    "?": ["##.", "..#", ".#.", "...", ".#."],
}


def micro(L, text, x, y, color, gap=1):
    for ch in text:
        g = MICRO[ch]
        for j, row in enumerate(g):
            for i, c in enumerate(row):
                if c == "#":
                    L.set(x + i, y + j, color)
        x += 3 + gap
    return x


def check_contrast(pairs):
    """[(fg, bg, min)] -> list of failures. Used by the build to keep the label table honest."""
    bad = []
    for fg, bg, lo in pairs:
        c = contrast(fg, bg)
        if c < lo:
            bad.append((fg, bg, round(c, 2), lo))
    return bad


def rotate_shear(L, deg):
    """Rotate pixel art by the three-shear method (Paeth): every source pixel lands on exactly one target
    pixel, so no colour is invented, lost or smeared. deg > 0 = counter-clockwise ON SCREEN (right side up),
    which is Godot's rotation -deg. Returns a new, tightly trimmed layer."""
    import math
    th = math.radians(deg)
    t, s = math.tan(th / 2), math.sin(th)
    cx, cy = (L.w - 1) / 2, (L.h - 1) / 2
    pts = {}
    for y in range(L.h):
        for x in range(L.w):
            c = L.px[y][x]
            if c is None:
                continue
            X, Y = x - cx, y - cy
            X1 = X + round(t * Y)
            Y2 = Y + round(-s * X1)
            X3 = X1 + round(t * Y2)
            pts[(X3, Y2)] = c
    xs = [p[0] for p in pts]; ys = [p[1] for p in pts]
    x0, y0 = int(math.floor(min(xs))), int(math.floor(min(ys)))
    R = Layer(int(max(xs) - x0) + 1, int(max(ys) - y0) + 1)
    for (X, Y), c in pts.items():
        R.px[int(Y - y0)][int(X - x0)] = c
    return R
