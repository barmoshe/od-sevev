"""Sevev 9 font stage: sevev9.glyphs (text source) -> BMFont .fnt + .png pages for Godot's TextServer.

Two cuts share one advance table, so they are drop-in replacements for each other:
  sevev9          white glyphs on transparent; the Label's font_color tints them.
  sevev9_outline  white fill + a 1 px ink ring (8-connected), for text over art and big titles.

Fails loudly (FontError) on: a malformed block, a row that is not 9 x width, an unknown alias
target, a missing required code point, or two different glyphs with identical bitmaps (the
pair-collapse guard; intentional twins are listed in TWINS).
"""
import os, re
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
SOURCE = os.path.join(HERE, "font", "sevev9.glyphs")

ROWS = 9           # cell height: 2 ascender + 5 body + 2 descender
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


def parse(path=SOURCE):
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
            rows = [lines[i + k].rstrip() for k in range(ROWS)] if i + ROWS <= len(lines) else []
            if len(rows) != ROWS or any(not r or set(r) - {"#", "."} for r in rows):
                raise FontError(f"U+{cp:04X} (line {i}): needs exactly {ROWS} rows of '#'/'.'")
            if len({len(r) for r in rows}) != 1:
                raise FontError(f"U+{cp:04X} (line {i}): rows differ in width {[len(r) for r in rows]}")
            if cp in glyphs:
                raise FontError(f"U+{cp:04X}: defined twice")
            if not any("#" in r for r in rows):
                raise FontError(f"U+{cp:04X}: empty glyph (use 'space' or 'zero')")
            glyphs[cp] = rows
            i += ROWS
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
    return {"glyphs": glyphs, "aliases": aliases, "zeros": zeros, "space": space}


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
    w = len(rows[0])
    if not outline:
        im = Image.new("RGBA", (w, ROWS), (0, 0, 0, 0))
        for y in range(ROWS):
            for x in range(w):
                if rows[y][x] == "#":
                    im.putpixel((x, y), WHITE)
        return im
    im = Image.new("RGBA", (w + 2, ROWS + 2), (0, 0, 0, 0))
    for y in range(-1, ROWS + 1):
        for x in range(-1, w + 1):
            if _on(rows, x, y):
                im.putpixel((x + 1, y + 1), WHITE)
            elif any(_on(rows, x + dx, y + dy) for dx in (-1, 0, 1) for dy in (-1, 0, 1)):
                im.putpixel((x + 1, y + 1), INK)
    return im


def build(font, out_dir, name, outline):
    """Pack one cut into a single page and write <name>.fnt + <name>.png. Returns stats."""
    g, al, z, sp = font["glyphs"], font["aliases"], font["zeros"], font["space"]
    cells = {cp: _cell(rows, outline) for cp, rows in sorted(g.items())}
    # shelf pack, 1 px gutter all round (nearest filtering never reads a neighbour)
    x = y = 1
    shelf = 0
    pos = {}
    for cp, im in cells.items():
        if x + im.width + 1 > PAGE_W:
            x, y = 1, y + shelf + 1
            shelf = 0
        pos[cp] = (x, y)
        x += im.width + 1
        shelf = max(shelf, im.height)
    page_h = y + shelf + 1
    page_h = 1 << (page_h - 1).bit_length()          # power of two: friendliest for every GPU
    page = Image.new("RGBA", (PAGE_W, page_h), (0, 0, 0, 0))
    for cp, im in cells.items():
        page.paste(im, pos[cp])
    page.save(os.path.join(out_dir, name + ".png"))

    off = -1 if outline else 0
    lines = [
        f'info face="Sevev 9{" Outline" if outline else ""}" size={ROWS} bold=0 italic=0 charset="" unicode=1 '
        f'stretchH=100 smooth=0 aa=1 padding=0,0,0,0 spacing=1,1 outline={1 if outline else 0}',
        f"common lineHeight={LINE_H} base={TOP_PAD + BASELINE_ROW + 1} scaleW={PAGE_W} scaleH={page_h} "
        f"pages=1 packed=0 alphaChnl=0 redChnl=0 greenChnl=0 blueChnl=0",
        f'page id=0 file="{name}.png"',
    ]
    chars = []
    for cp in sorted(set(g) | set(al) | set(z) | {0x20}):
        if cp in g or (cp in al and al[cp] in g):
            src = cp if cp in g else al[cp]
            im, (px, py) = cells[src], pos[src]
            adv = len(g[src][0]) + 1
            chars.append(f"char id={cp} x={px} y={py} width={im.width} height={im.height} "
                         f"xoffset={off} yoffset={TOP_PAD + off} xadvance={adv} page=0 chnl=15")
        else:   # space, NBSP (alias to space) and the zero-width format characters
            adv = 0 if cp in z else sp + 1
            chars.append(f"char id={cp} x=0 y=0 width=0 height=0 xoffset=0 yoffset=0 xadvance={adv} page=0 chnl=15")
    lines.append(f"chars count={len(chars)}")
    lines += chars
    open(os.path.join(out_dir, name + ".fnt"), "w", encoding="utf-8").write("\n".join(lines) + "\n")
    return {"name": name, "page": [PAGE_W, page_h], "chars": len(chars)}


def advance_of(font, text):
    """Pixel width at scale 1 of a logical string (bidi does not change the sum)."""
    g, al, z, sp = font["glyphs"], font["aliases"], font["zeros"], font["space"]
    w = 0
    for ch in text:
        cp = ord(ch)
        src = cp if cp in g else al.get(cp, cp)
        w += 0 if cp in z else (len(g[src][0]) + 1 if src in g else sp + 1)
    return w - 1 if w else 0
