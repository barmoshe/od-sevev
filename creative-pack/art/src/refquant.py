"""Ref-based redraw helper: crop a client reference, box-downscale to sprite size, map every
pixel to the nearest swatch of a restricted palette subset (CIE Lab distance), strip the
background by flood-fill from the border, and dump a char-grid for hand clean-up.
The shipped sprite is always the hand-cleaned grid, never this raw output."""
import sys
from PIL import Image
import numpy as np
from palette import rgb


def _lab(c):
    c = np.asarray(c, dtype=np.float64) / 255
    c = np.where(c > 0.04045, ((c + 0.055) / 1.055) ** 2.4, c / 12.92)
    M = np.array([[0.4124, 0.3576, 0.1805], [0.2126, 0.7152, 0.0722], [0.0193, 0.1192, 0.9505]])
    xyz = c @ M.T / np.array([0.95047, 1.0, 1.08883])
    f = np.where(xyz > 0.008856, np.cbrt(xyz), 7.787 * xyz + 16 / 116)
    return np.stack([116 * f[..., 1] - 16, 500 * (f[..., 0] - f[..., 1]), 200 * (f[..., 1] - f[..., 2])], -1)


def quantize(path, box, size, legend, bg_thresh=40):
    """legend: {char: swatch}. Returns list of strings."""
    im = Image.open(path).convert("RGB").crop(box).resize(size, Image.BOX)
    a = np.asarray(im)
    chars = list(legend)
    pal = _lab(np.array([rgb(legend[c]) for c in chars]))
    lab = _lab(a)
    d = ((lab[:, :, None, :] - pal[None, None, :, :]) ** 2).sum(-1)
    idx = d.argmin(-1)
    g = [[chars[i] for i in row] for row in idx]
    # background: dark, low-chroma pixels connected to the border
    h, w = idx.shape
    lum = a.mean(-1)
    dark = lum < bg_thresh
    seen = set(); stack = [(x, y) for x in range(w) for y in (0, h - 1)] + [(x, y) for y in range(h) for x in (0, w - 1)]
    while stack:
        x, y = stack.pop()
        if (x, y) in seen or not (0 <= x < w and 0 <= y < h) or not dark[y, x]:
            continue
        seen.add((x, y)); g[y][x] = "."
        stack += [(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)]
    return ["".join(r) for r in g]


if __name__ == "__main__":
    from bibi import LEG
    rows = quantize(sys.argv[1], tuple(map(int, sys.argv[2].split(","))), tuple(map(int, sys.argv[3].split(","))), LEG)
    print("\n".join(rows))
