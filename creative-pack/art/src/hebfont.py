"""'Sevev 5x9': the game's hand-drawn Hebrew pixel font.

Cell: 5 px wide x 9 px tall = ascender 2 + body 5 + descender 2. Advance = glyph width + 1
(6 for the standard 5-wide letter; narrow letters ו ז י ן נ ' . , ! : are proportional).
Line height 11. Baseline = row 6 (last body row).

Separation rules at this size (the pairs that collapse in naive 5x5 fonts):
  ו / ז / ן : ו = hook + stem (2w); ז = centred 3-wide head (3w); ן = ו plus 2-row descender.
  ה / ח / ת : ה left leg DETACHED from the roof (1-row gap); ח left leg attached;
              ת left leg inset one column with a foot kicking left.
  ב / כ     : ב has a square bowl whose base sticks out right past the stem; כ is round, no tail.
  ד / ר     : ד roof overhangs right past its leg; ר has a rounded corner, no overhang.
  ס / ם     : ם square on all four corners; ס round bottom and round top-right.
  ע / צ     : ע = two arms converging, tail kicks LEFT on the base row; צ = crossed top, full base.
  ' / י     : the geresh is raised into the ascender band, so "מס'" never reads "מסי".
"""
from pix import Layer

A = None  # marker


def G(body, asc=None, desc=None):
    w = len(body[0])
    asc = asc or ["." * w] * 2
    desc = desc or ["." * w] * 2
    rows = asc + body + desc
    assert len(rows) == 9 and all(len(r) == w for r in rows), (body, asc, desc)
    return rows


GLYPHS = {
    "א": G(["#...#", ".#..#", "..##.", ".#.#.", "##..#"]),
    "ב": G(["####.", "...#.", "...#.", "...#.", "#####"]),
    "ג": G(["##.", ".#.", ".#.", ".##", "#.#"]),
    "ד": G(["#####", "...#.", "...#.", "...#.", "...#."]),
    "ה": G(["#####", "....#", "#...#", "#...#", "#...#"]),
    "ו": G(["##", ".#", ".#", ".#", ".#"]),
    "ז": G(["###", ".#.", ".#.", ".#.", ".#."]),
    "ח": G(["#####", "#...#", "#...#", "#...#", "#...#"]),
    "ט": G(["#.###", "#.#.#", "#...#", "#...#", ".###."]),
    "י": G(["##", ".#", "..", "..", ".."]),
    "כ": G(["####.", "....#", "....#", "....#", "####."]),
    "ך": G(["####", "...#", "...#", "...#", "...#"], desc=["...#", "...#"]),
    "ל": G(["#....", "#####", "....#", "...#.", "..#.."], asc=["#....", "#...."]),
    "מ": G(["#.##.", "##..#", "#...#", "#...#", "#.###"]),
    "ם": G(["#####", "#...#", "#...#", "#...#", "#####"]),
    "נ": G(["##.", "..#", "..#", "..#", "###"]),
    "ן": G(["##", ".#", ".#", ".#", ".#"], desc=[".#", ".#"]),
    "ס": G(["####.", "#...#", "#...#", "#...#", ".###."]),
    "ע": G(["#...#", "#...#", ".#..#", "..##.", "###.."]),
    "פ": G(["####.", "#...#", "##..#", "....#", "####."]),
    "ף": G(["####", "#..#", "##.#", "...#", "...#"], desc=["...#", "...#"]),
    "צ": G(["#...#", ".#.#.", "..#..", "...#.", "#####"]),
    "ץ": G(["#..#", ".#.#", "..##", "...#", "...#"], desc=["...#", "...#"]),
    "ק": G(["#####", "....#", "#...#", "#..#.", "#...."], desc=["#....", "#...."]),
    "ר": G(["###.", "...#", "...#", "...#", "...#"]),
    "ש": G(["#.#.#", "#.#.#", "#.#.#", "#.##.", "####."]),
    "ת": G(["#####", ".#..#", ".#..#", ".#..#", "##..#"]),
    # punctuation
    "'": G(["#", ".", ".", ".", "."], asc=[".", "#"]),
    '"': G(["#.#", "...", "...", "...", "..."], asc=["...", "#.#"]),
    ".": G([".", ".", ".", ".", "#"]),
    ",": G([".", ".", ".", ".", "#"], desc=["#", "."]),
    "!": G(["#", "#", "#", ".", "#"]),
    "?": G(["###", "..#", ".##", "...", ".#."]),
    ":": G([".", "#", ".", "#", "."]),
    "-": G(["...", "...", "###", "...", "..."]),
    "·": G([".", ".", "#", ".", "."]),
    "₪": G(["###.#", "#.#.#", "#.#.#", "#.#.#", "#.###"]),
    "%": G(["#..#", "..#.", ".#..", "#..#", "...."]),
    "(": G([".#", "#.", "#.", "#.", ".#"]),
    ")": G(["#.", ".#", ".#", ".#", "#."]),
    ">": G(["#..", ".#.", "..#", ".#.", "#.."]),
    "<": G(["..#", ".#.", "#..", ".#.", "..#"]),
    "=": G(["...", "###", "...", "###", "..."]),
    "/": G(["..#", "..#", ".#.", "#..", "#.."]),
    "x": G(["...", "#.#", ".#.", "#.#", "..."]),
    # number-suffix Latin caps (idle-game magnitudes 1.2K / 3M / 4B / 5T), body height, LTR
    "K": G(["#..#", "#.#.", "##..", "#.#.", "#..#"]),
    "M": G(["#...#", "##.##", "#.#.#", "#...#", "#...#"]),
    "B": G(["###.", "#..#", "###.", "#..#", "###."]),
    "T": G(["###", ".#.", ".#.", ".#.", ".#."]),
    # math + UI marks
    "+": G(["...", ".#.", "###", ".#.", "..."]),
    "\u2212": G(["...", "...", "###", "...", "..."]),                      # − minus sign
    "\u00d7": G(["...", "#.#", ".#.", "#.#", "..."]),                      # × multiplication
    "\u2026": G([".....", ".....", ".....", ".....", "#.#.#"]),            # … ellipsis
    "\u2190": G(["..#..", ".#...", "#####", ".#...", "..#.."]),            # ← arrow (never auto-mirrored)
    # Hebrew marks: maqaf sits HIGH (top of the body), geresh/gershayim raised like ' and "
    "\u05be": G(["...", "###", "...", "...", "..."]),                      # ־ maqaf
    "\u05f3": G(["#", ".", ".", ".", "."], asc=[".", "#"]),                # ׳ geresh
    "\u05f4": G(["#.#", "...", "...", "...", "..."], asc=["...", "#.#"]),  # ״ gershayim
    # digits (body height, LTR runs)
    "0": G([".##.", "#..#", "#..#", "#..#", ".##."]),
    "1": G([".#.", "##.", ".#.", ".#.", "###"]),
    "2": G(["###.", "...#", ".##.", "#...", "####"]),
    "3": G(["###.", "...#", ".##.", "...#", "###."]),
    "4": G(["#..#", "#..#", "####", "...#", "...#"]),
    "5": G(["####", "#...", "###.", "...#", "###."]),
    "6": G([".##.", "#...", "###.", "#..#", ".##."]),
    "7": G(["####", "...#", "..#.", ".#..", ".#.."]),
    "8": G([".##.", "#..#", ".##.", "#..#", ".##."]),
    "9": G([".##.", "#..#", ".###", "...#", ".##."]),
}
SPACE_W = 3
LINE_H = 11
MIRROR = {"(": ")", ")": "(", "<": ">", ">": "<"}


def _is_ltr(ch):
    return ch.isdigit() or ("a" <= ch.lower() <= "z")


def advance(ch):
    """Per-glyph advance in art px: glyph width + 1 (space = 4). Engine BitmapFont xadvance."""
    return glyph_w(ch) + 1


def visual_order(text):
    """Minimal bidi for an RTL paragraph: Hebrew/neutral chars are reversed, runs of
    digits (with inner . , : separators) keep their LTR order, brackets mirror."""
    runs, i = [], 0
    while i < len(text):
        ch = text[i]
        if _is_ltr(ch):
            j = i
            while j < len(text) and (_is_ltr(text[j]) or (text[j] in ".,:" and j + 1 < len(text) and _is_ltr(text[j + 1]))):
                j += 1
            runs.append(("L", text[i:j]))
            i = j
        else:
            runs.append(("R", MIRROR.get(ch, ch)))
            i += 1
    return "".join(s for _, s in reversed(runs))


def glyph_w(ch):
    return SPACE_W if ch == " " else len(GLYPHS[ch][0])


def measure(text):
    vis = visual_order(text)
    return sum(glyph_w(c) + 1 for c in vis) - 1 if vis else 0


def draw(layer, text, x, y, color="white", align="right", shadow=None):
    """Draw RTL text. x is the RIGHT edge (align='right'), centre ('center') or left ('left').
    y is the top of the 9-row cell. Returns the drawn width."""
    w = measure(text)
    if align == "right":
        x0 = x - w + 1
    elif align == "center":
        x0 = x - w // 2
    else:
        x0 = x
    vis = visual_order(text)
    for pass_, col, off in ((0, shadow, 1), (1, color, 0)):
        if col is None:
            continue
        cx = x0
        for ch in vis:
            if ch == " ":
                cx += SPACE_W + 1
                continue
            rows = GLYPHS[ch]
            for j, row in enumerate(rows):
                for i, c in enumerate(row):
                    if c == "#":
                        layer.set(cx + i + off, y + j + off, col)
            cx += len(rows[0]) + 1
    return w


def plate(layer, text, cx, y, fg="white", bg="night", edge="ink", padx=2):
    """A name tag: text on a solid plate with a 1px ink edge, centred at cx.
    One line = rows y..y+10. '\n' stacks lines (each centred, 10 rows apart)."""
    lines = text.split("\n")
    w = max(measure(t) for t in lines)
    h = 10 * len(lines) + 1
    x0 = cx - (w + 2 * padx) // 2
    layer.rect(x0, y, w + 2 * padx, h, bg)
    layer.hline(x0, x0 + w + 2 * padx - 1, y + h - 1, edge)
    for k, t in enumerate(lines):
        draw(layer, t, x0 + padx + w // 2, y + 1 + 10 * k, fg, align="center")
    return x0, w + 2 * padx


if __name__ == "__main__":
    # specimen sheet
    import os
    lines = [
        "אבגדהוזחטיכךלמםנןסעפףצץקרשת",
        "ו ז ן · ה ח ת · ב כ · ד ר · ס ם",
        "עוד סבב",
        "סבב בחירות מס' 6. הציבור נרגש.",
        "לא יהיה כלום כי אין כלום",
        "1,250 ₪ · 18% מע\"מ",
        "1.2K · 3M · 4B · 5T · +12 \u2212 3 \u00d7 2\u2026",
        "\u2190 חזרה · בית\u05be\u05bfמשפט".replace("\u05bf", "") + " · צה\u05f4ל · ג\u05f3",
        "איפה הכסף?",
    ]
    L = Layer(200, 12 + LINE_H * len(lines), fill="night")
    for k, t in enumerate(lines):
        draw(L, t, 195, 4 + k * LINE_H, "white")
    here = os.path.dirname(os.path.abspath(__file__))
    L.to_image(4).save(os.path.join(here, "..", "proofs", "font-specimen.png"))
    print("ok", visual_order("סבב בחירות מס' 6. הציבור נרגש."))
