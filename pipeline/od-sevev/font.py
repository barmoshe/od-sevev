"""Sevev 9 font stage: sevev9.glyphs (text source) -> BMFont .fnt + .png pages for Godot's TextServer.

Two cuts share one advance table, so they are drop-in replacements for each other:
  sevev9          white glyphs on transparent; the Label's font_color tints them.
  sevev9_outline  white fill + a 1 px ink ring (8-connected), for text over art and big titles.

A density-2 companion, Sevev 9 @2 (sevev9@2.glyphs -> sevev9@2.fnt), redraws every glyph on a 2x grid
(18-row cell, advance = width + 2) to be drawn at half the scale: every metric is exactly 2x Sevev 9's, so a
string measures exactly twice as wide in @2 px and covers the same box. check_companion() proves that on the
written .fnt files and fails the build on any glyph that breaks it.

Fails loudly (FontError) on: a malformed block, a row that is not 9 x width, an unknown alias
target, a missing required code point, or two different glyphs with identical bitmaps (the
pair-collapse guard; intentional twins are listed in TWINS).
"""
import os, re
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
SOURCE = os.path.join(HERE, "font", "sevev9.glyphs")
SOURCE_2X = os.path.join(HERE, "font", "sevev9@2.glyphs")

# Metrics at density 1 (Sevev 9); a density-d cut multiplies every one of them by d.
ROWS = 9          # cell height: 2 ascender + 5 body + 2 descender
BASELINE_ROW = 6   # last body row
LINE_H = 11        # 1 px leading above + 9 + 1 px below
TOP_PAD = 1        # the leading above the cell inside a line
INK = (27, 20, 38, 255)        # style-guide `ink` #1b1426
WHITE = (255, 255, 255, 255)   # pure white so font_color tints exactly
PAGE_W = 128

# UX first-minute §3.5 "Glyph range for the TA's pixel font", plus the characters the UX
# rules themselves put into strings (NBSP before ₪, LRI/PDI around numbers).
REQUIRED = (
    [(0x20, 0x7E), (0x05D0, 0x05EA)] +
    [(c, c) for c in (0x05BE, 0x05F3, 0x05F4, 0x20AA, 0x2026, 0x00B7, 0x2190, 0x2013, 0x2014,
                      0x2212, 0x00D7, 0x00A0, 0x2066, 0x2069)]
)
# Glyph pairs that are the same bitmap on purpose.
TWINS = {frozenset((0x27, 0x05F3)),   # ' and geresh: both raised (the draft's rule)
         frozenset((0x22, 0x05F4)),   # " and gershayim
         frozenset((0x78, 0xD7)),     # x and × (the multiplier)
         frozenset((0x2D, 0x2212))}   # hyphen and − (the draft draws the minus as the hyphen)


class FontError(Exception):
    pass


def parse(path=SOURCE, density=1):
    """Parse a .glyphs source whose cells are ROWS x density rows tall."""
    rows_n = ROWS * density
    glyphs, aliases, zeros, space = {}, {}, {}, None
    lines = open(path, encoding="utf-8").read().split("\n")
    i = 0
    hexcp = lambda s: int(s[2:], 16)
    while i < len(lines):
        ln = lines[i].rstrip()
        i += 1
        if not ln or ln.startswith("#"):
            continue
        if ln.startswith("space "):
            space = int(ln.split()[1])
        elif ln.startswith("== "):
            m = re.match(r"== (U\+[0-9A-Fa-f]{4,6})", ln)
            if not m:
                raise FontError(f"line {i}: bad glyph header {ln!r}")
            cp = hexcp(m.group(1))
            rows = [lines[i + k].rstrip() for k in range(rows_n)] if i + rows_n <= len(lines) else []
            if len(rows) != rows_n or any(not r or set(r) - {"#", "."} for r in rows):
                raise FontError(f"U+{cp:04X} (line {i}): needs exactly {rows_n} rows of '#'/'.'")
            if len({len(r) for r in rows}) != 1:
                raise FontError(f"U+{cp:04X} (line {i}): rows differ in width {[len(r) for r in rows]}")
            if cp in glyphs:
                raise FontError(f"U+{cp:04X}: defined twice")
            if not any("#" in r for r in rows):
                raise FontError(f"U+{cp:04X}: empty glyph (use 'space' or 'zero')")
            glyphs[cp] = rows
            i += rows_n
        elif ln.startswith("alias "):
            m = re.match(r"alias (U\+[0-9A-F]+)(?:\.\.(U\+[0-9A-F]+))? -> (U\+[0-9A-F]+)(?:\.\.(U\+[0-9A-F]+))?", ln, re.I)
            if not m:
                raise FontError(f"line {i}: bad alias {ln!r}")
            a0, a1 = hexcp(m.group(1)), hexcp(m.group(2) or m.group(1))
            b0, b1 = hexcp(m.group(3)), hexcp(m.group(4) or m.group(3))
            if a1 - a0 != b1 - b0:
                raise FontError(f"line {i}: alias ranges differ in length")
            for k in range(a1 - a0 + 1):
                aliases[a0 + k] = b0 + k
        elif ln.startswith("zero "):
            zeros[hexcp(ln.split()[1])] = ln
        else:
            raise FontError(f"line {i}: unrecognised {ln!r}")
    if space is None:
        raise FontError("missing 'space <width>' line")
    for a, b in list(aliases.items()):
        if a in glyphs:           # an explicit glyph wins over a range alias
            del aliases[a]
        elif b not in glyphs and b != 0x20:
            raise FontError(f"alias U+{a:04X} -> U+{b:04X}: target has no glyph")
    return {"glyphs": glyphs, "aliases": aliases, "zeros": zeros, "space": space, "density": density}


def check(font):
    """Coverage + pair-collapse guard. Returns a list of report lines; raises on failure."""
    g, al, z = font["glyphs"], font["aliases"], font["zeros"]
    have = set(g) | set(al) | set(z) | {0x20}
    missing = [cp for lo, hi in REQUIRED for cp in range(lo, hi + 1) if cp not in have]
    if missing:
        raise FontError("missing required code points: " + " ".join(f"U+{c:04X}({chr(c)})" for c in missing))
    seen, dupes = {}, []
    for cp, rows in g.items():
        key = tuple(rows)
        if key in seen and frozenset((seen[key], cp)) not in TWINS:
            dupes.append((seen[key], cp))
        seen.setdefault(key, cp)
    if dupes:
        raise FontError("identical bitmaps (pair collapse): " +
                        ", ".join(f"U+{a:04X}{chr(a)}=U+{b:04X}{chr(b)}" for a, b in dupes))
    return [f"glyphs {len(g)} drawn + {len(al)} aliases + {len(z)} zero-width + space",
            f"required ranges covered: {len(REQUIRED)} spans, 0 missing"]


def _on(rows, x, y):
    return 0 <= y < len(rows) and 0 <= x < len(rows[0]) and rows[y][x] == "#"


def _cell(rows, outline):
    w, h = len(rows[0]), len(rows)
    if not outline:
        im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        for y in range(h):
            for x in range(w):
                if rows[y][x] == "#":
                    im.putpixel((x, y), WHITE)
        return im
    im = Image.new("RGBA", (w + 2, h + 2), (0, 0, 0, 0))
    for y in range(-1, h + 1):
        for x in range(-1, w + 1):
            if _on(rows, x, y):
                im.putpixel((x + 1, y + 1), WHITE)
            elif any(_on(rows, x + dx, y + dy) for dx in (-1, 0, 1) for dy in (-1, 0, 1)):
                im.putpixel((x + 1, y + 1), INK)
    return im


def build(font, out_dir, name, outline):
    """Pack one cut into a single page and write <name>.fnt + <name>.png. Returns stats."""
    g, al, z, sp = font["glyphs"], font["aliases"], font["zeros"], font["space"]
    d = font.get("density", 1)
    page_w = PAGE_W * d
    cells ={cp: _cell(rows, outline) for cp, rows in sorted(g.items())}
    # shelf pack, 1 px gutter all round (nearest filtering never reads a neighbour)
    x = y = 1
    shelf = 0
    pos = {}
    for cp, im in cells.items():
        if x + im.width + 1 > page_w:
            x, y = 1, y + shelf + 1
            shelf = 0
        pos[cp] = (x, y)
        x += im.width + 1
        shelf = max(shelf, im.height)
    page_h = y + shelf + 1
    page_h = 1 << (page_h - 1).bit_length()          # power of two: friendliest for every GPU
    page = Image.new("RGBA", (page_w, page_h), (0, 0, 0, 0))
    for cp, im in cells.items():
        page.paste(im, pos[cp])
    page.save(os.path.join(out_dir, name + ".png"))

    off = -1 if outline else 0
    face = "Sevev 9" + (f" @{d}" if d > 1 else "") + (" Outline" if outline else "")
    lines = [
        f'info face="{face}" size={ROWS * d} bold=0 italic=0 charset="" unicode=1 '
        f'stretchH=100 smooth=0 aa=1 padding=0,0,0,0 spacing=1,1 outline={1 if outline else 0}',
        f"common lineHeight={LINE_H * d} base={(TOP_PAD + BASELINE_ROW + 1) * d} scaleW={page_w} scaleH={page_h} "
        f"pages=1 packed=0 alphaChnl=0 redChnl=0 greenChnl=0 blueChnl=0",
        f'page id=0 file="{name}.png"',
    ]
    chars = []
    for cp in sorted(set(g) | set(al) | set(z) | {0x20}):
        if cp in g or (cp in al and al[cp] in g):
            src = cp if cp in g else al[cp]
            im, (px, py) = cells[src], pos[src]
            adv = len(g[src][0]) + d
            chars.append(f"char id={cp} x={px} y={py} width={im.width} height={im.height} "
                         f"xoffset={off} yoffset={TOP_PAD * d + off} xadvance={adv} page=0 chnl=15")
        else:   # space, NBSP (alias to space) and the zero-width format characters
            adv = 0 if cp in z else sp + d
            chars.append(f"char id={cp} x=0 y=0 width=0 height=0 xoffset=0 yoffset=0 xadvance={adv} page=0 chnl=15")
    lines.append(f"chars count={len(chars)}")
    lines += chars
    open(os.path.join(out_dir, name + ".fnt"), "w", encoding="utf-8").write("\n".join(lines) + "\n")
    return {"name": name, "page": [page_w, page_h], "chars": len(chars), "density": d,
            "size": ROWS * d, "lineHeight": LINE_H * d, "base": (TOP_PAD + BASELINE_ROW + 1) * d}


def advance_of(font, text):
    """Pixel width at scale 1 (in the font's own px) of a logical string (bidi does not change the sum)."""
    g, al, z, sp = font["glyphs"], font["aliases"], font["zeros"], font["space"]
    d = font.get("density", 1)
    w = 0
    for ch in text:
        cp = ord(ch)
        src = cp if cp in g else al.get(cp, cp)
        w += 0 if cp in z else (len(g[src][0]) + d if src in g else sp + d)
    return w - d if w else 0


# ------------------------------------------------------------------ density companions
def read_fnt(path):
    """The metrics a .fnt ships: the common line, per-char boxes/offsets/advances, kerning pairs."""
    common, chars, kern = {}, {}, {}
    kv = lambda ln: dict(re.findall(r'(\w+)=("[^"]*"|\S+)', ln))
    for ln in open(path, encoding="utf-8"):
        if ln.startswith("common "):
            common = {k: int(v) for k, v in kv(ln).items() if v.lstrip("-").isdigit()}
        elif ln.startswith("char "):
            a = {k: int(v) for k, v in kv(ln).items()}
            chars[a["id"]] = a
        elif ln.startswith("kerning "):
            a = {k: int(v) for k, v in kv(ln).items()}
            kern[(a["first"], a["second"])] = a["amount"]
    return common, chars, kern


def check_companion(base_fnt, dense_fnt, d):
    """The hard metric rule for a density-d companion, checked on the shipped .fnt files. For every code
    point: xadvance = d x the base's, and the same ink box scaled (width, height, xoffset, yoffset x d, so the
    same baseline); lineHeight and base x d; the same code-point set; kerning pairs identical, amounts x d.
    Every string then measures exactly d x as wide in dense px, so layouts, budgets and the text lint are
    unchanged. Returns report lines; raises FontError listing every glyph that breaks the rule."""
    c1, g1, k1 = read_fnt(base_fnt)
    c2, g2, k2 = read_fnt(dense_fnt)
    bad = []
    for key in ("lineHeight", "base"):
        if c2.get(key) != d * c1.get(key, 0):
            bad.append(f"common {key} {c2.get(key)} != {d} x {c1.get(key)}")
    if set(g1) != set(g2):
        bad.append("code points differ: only in the base " + " ".join(f"U+{c:04X}" for c in sorted(set(g1) - set(g2)))
                   + f"; only in @{d} " + " ".join(f"U+{c:04X}" for c in sorted(set(g2) - set(g1))))
    for cp in sorted(set(g1) & set(g2)):
        a, b = g1[cp], g2[cp]
        if b["xadvance"] != d * a["xadvance"]:
            bad.append(f"U+{cp:04X} {chr(cp)!r} xadvance {b['xadvance']} != {d} x {a['xadvance']}")
        if a["width"]:      # an inked glyph: the same box, scaled
            for key in ("width", "height", "xoffset", "yoffset"):
                if b[key] != d * a[key]:
                    bad.append(f"U+{cp:04X} {chr(cp)!r} {key} {b[key]} != {d} x {a[key]}")
    if {p: d * v for p, v in k1.items()} != k2:
        bad.append(f"kerning differs ({len(k1)} base pairs, {len(k2)} @{d} pairs)")
    if bad:
        raise FontError(f"{os.path.basename(dense_fnt)} breaks the x{d} metric rule:\n  " + "\n  ".join(bad))
    return [f"@{d} metric check: {len(g2)} code points, every xadvance = {d} x Sevev 9's, every ink box x {d}, "
            f"lineHeight {c2['lineHeight']} = {d} x {c1['lineHeight']}, base {c2['base']} = {d} x {c1['base']}, "
            f"kerning pairs {len(k2)} = {len(k1)}: PASS"]
