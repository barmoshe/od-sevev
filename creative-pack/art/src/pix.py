"""Tiny pixel-art canvas: every pixel is a palette swatch name (or None = transparent).

Sprites are authored as char-grids + a legend {char: swatch}. Layers composite with
paste(); outline() adds the studio's 1px external ink outline; to_image() upscales
nearest-neighbour by an integer factor only.
"""
from PIL import Image
from palette import PAL, rgb


class Layer:
    def __init__(self, w, h, fill=None):
        self.w, self.h = w, h
        self.px = [[fill] * w for _ in range(h)]

    # -- basic access -------------------------------------------------------
    def inb(self, x, y):
        return 0 <= x < self.w and 0 <= y < self.h

    def set(self, x, y, c):
        if c is not None and self.inb(x, y):
            assert c in PAL, f"unknown swatch {c!r}"
            self.px[y][x] = c

    def get(self, x, y):
        return self.px[y][x] if self.inb(x, y) else None

    def copy(self):
        L = Layer(self.w, self.h)
        L.px = [row[:] for row in self.px]
        return L

    # -- primitives ---------------------------------------------------------
    def rect(self, x, y, w, h, c):
        for yy in range(y, y + h):
            for xx in range(x, x + w):
                self.set(xx, yy, c)

    def hline(self, x0, x1, y, c):
        for x in range(min(x0, x1), max(x0, x1) + 1):
            self.set(x, y, c)

    def vline(self, x, y0, y1, c):
        for y in range(min(y0, y1), max(y0, y1) + 1):
            self.set(x, y, c)

    def line(self, x0, y0, x1, y1, c):
        dx, dy = abs(x1 - x0), -abs(y1 - y0)
        sx, sy = (1 if x0 < x1 else -1), (1 if y0 < y1 else -1)
        err = dx + dy
        while True:
            self.set(x0, y0, c)
            if x0 == x1 and y0 == y1:
                break
            e2 = 2 * err
            if e2 >= dy:
                err += dy; x0 += sx
            if e2 <= dx:
                err += dx; y0 += sy

    def ellipse(self, cx, cy, rx, ry, c):
        """Filled, pixel-centred ellipse (cx,cy may be .5 for even sizes)."""
        for y in range(int(cy - ry - 1), int(cy + ry + 2)):
            for x in range(int(cx - rx - 1), int(cx + rx + 2)):
                dx = (x + 0.5 - (cx + 0.5)) / (rx + 0.35)
                dy = (y + 0.5 - (cy + 0.5)) / (ry + 0.35)
                if dx * dx + dy * dy <= 1.0:
                    self.set(x, y, c)

    def dither(self, x, y, w, h, c1, c2, phase=0):
        for yy in range(y, y + h):
            for xx in range(x, x + w):
                self.set(xx, yy, c1 if (xx + yy + phase) % 2 == 0 else c2)

    def bands(self, x, y, w, rows):
        """rows: list of (swatch, height). A 1-row 50% checker is inserted at each seam."""
        yy = y
        for i, (c, hgt) in enumerate(rows):
            self.rect(x, yy, w, hgt, c)
            if i > 0:
                self.dither(x, yy, w, 1, c, rows[i - 1][0])
            yy += hgt
        return yy

    def grid(self, x, y, rows, legend, flip=False):
        for j, row in enumerate(rows):
            if flip:
                row = row[::-1]
            for i, ch in enumerate(row):
                if ch in ". ":
                    continue
                if ch not in legend:
                    raise KeyError(f"char {ch!r} not in legend (row {j}: {row!r})")
                self.set(x + i, y + j, legend[ch])

    def paste(self, other, x, y):
        for j in range(other.h):
            for i in range(other.w):
                c = other.px[j][i]
                if c is not None:
                    self.set(x + i, y + j, c)

    def replace(self, a, b):
        for row in self.px:
            for i, c in enumerate(row):
                if c == a:
                    row[i] = b

    def flipped(self):
        L = Layer(self.w, self.h)
        L.px = [row[::-1] for row in self.px]
        return L

    # -- the outline rule -----------------------------------------------------
    def outlined(self, color="ink", pad=1, diagonal=False):
        """Returns a new layer padded by `pad` with a 1px external outline."""
        L = Layer(self.w + 2 * pad, self.h + 2 * pad)
        L.paste(self, pad, pad)
        src = [row[:] for row in L.px]
        nb = [(1, 0), (-1, 0), (0, 1), (0, -1)]
        if diagonal:
            nb += [(1, 1), (-1, 1), (1, -1), (-1, -1)]
        for y in range(L.h):
            for x in range(L.w):
                if src[y][x] is None:
                    for dx, dy in nb:
                        xx, yy = x + dx, y + dy
                        if 0 <= xx < L.w and 0 <= yy < L.h and src[yy][xx] is not None:
                            L.px[y][x] = color
                            break
        return L

    def silhouette(self, c="ink"):
        L = Layer(self.w, self.h)
        for y in range(self.h):
            for x in range(self.w):
                if self.px[y][x] is not None:
                    L.px[y][x] = c
        return L

    # -- export -------------------------------------------------------------
    def to_image(self, scale=1, bg=None):
        img = Image.new("RGBA", (self.w, self.h), (0, 0, 0, 0) if bg is None else rgb(bg) + (255,))
        p = img.load()
        for y in range(self.h):
            for x in range(self.w):
                c = self.px[y][x]
                if c is not None:
                    p[x, y] = rgb(c) + (255,)
        if scale != 1:
            img = img.resize((self.w * scale, self.h * scale), Image.NEAREST)
        return img

    def colors(self):
        return {c for row in self.px for c in row if c is not None}


def from_grid(rows, legend, flip=False):
    w = max(len(r) for r in rows)
    L = Layer(w, len(rows))
    L.grid(0, 0, rows, legend, flip=flip)
    return L
