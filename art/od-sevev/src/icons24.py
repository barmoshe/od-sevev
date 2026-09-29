"""24x24 spin icons (wave 5): the 15 spins (content.json upgrades s01-s15) at the SHOP ICON size, so a
spin card's icon fills card_plate (26x26) exactly like a money source's 24x24 icon does.

Why a redraw and not a 15->24 upscale: the kit never mixes pixel scales in one frame (style guide §1), and
the money-source icons beside them are dense 1:1 crops of 40-ap stage art. At 15 px the spins read as
small clip-art on a big plate; at 24 px each one gets its joke's second beat (the deposit tag's "0.30",
the drip, the one lit window seat, the frost and cobweb on the committee's binder, the "1" like).

Construction (graphic tier, style guide §3-4): each icon is built from PARTS, back to front. A part is a
fill grid (no outline drawn in it) that gets its own 1 px external `outline` before it is pasted, so an
overlapping front part draws its outline over the part behind it: the shapes separate without
anti-aliasing. Key light top-left: light plane on top/left edges, shadow on bottom/right. Inner lines use
the local shadow swatch; the only `ink` is text-like detail (digits, the play glyph). No rim (UI, not a
stage touchable). No flag, emblem, party colour, real logo or face (content.json visualHooks).

The 15x15 grids in icons15.py stay: the trophy `icon_plane` and the stage `laundry_bag` reuse them.
"""
from pix import Layer
from kit import grid_layer
from icons15 import LEG as LEG15

LEG = dict(LEG15)
LEG.update({"S": "skin_dk", "A": "teal_hi", "H": "hair_br", "Q": "receipt", "J": "receipt_sh"})

N = 24


def part(rows, dx=0, dy=0):
    """A fill grid -> (outlined layer, x, y). (x, y) is where the FILL's top-left lands on the canvas."""
    L = grid_layer(rows, LEG)
    return (L.outlined("outline", pad=1), dx - 1, dy - 1)


def compose(*parts):
    C = Layer(N, N)
    for L, x, y in parts:
        C.paste(L, x, y)
    return C


def dots(L, pts, c):
    for x, y in pts:
        L.set(x, y, c)
    return L


# 3x5 digits for the tags and counters (the kit's MICRO cut lacks 3 and 9)
DIG = {
    "0": ["###", "#.#", "#.#", "#.#", "###"],
    "1": [".#.", "##.", ".#.", ".#.", "###"],
    "3": ["###", "..#", ".##", "..#", "###"],
    "9": ["###", "#.#", "###", "..#", "###"],
    ".": ["...", "...", "...", "...", ".#."],
}


def digits(L, text, x, y, c, gap=1, dot_w=1):
    for ch in text:
        g = DIG[ch]
        if ch == ".":
            L.set(x, y + 4, c)
            x += dot_w + gap
            continue
        for j, row in enumerate(g):
            for i, v in enumerate(row):
                if v == "#":
                    L.set(x + i, y + j, c)
        x += 3 + gap
    return x


SPINS = {}

# ---------------------------------------------------------------- s01 a returnable bottle + a "0.30" tag
def _s01():
    bottle = part([
        "..sss..",
        "..ggg..",
        "..LGE..",
        "..LGE..",
        "..LGE..",
        ".LLGGE.",
        "LLGGGGE",
        "LwGGGGE",
        "LwGGGGE",
        "LwGGGGE",
        "LLGGGGE",
        "LGGGGGE",
        "LGGGGGE",
        "LGGGGGE",
        "LGGGGGE",
        "LGGGGGE",
        "LGGGGGE",
        "LGGGGEE",
        "LGGGGEE",
        "GEEEEEE",
    ], 1, 3)
    string = part([
        "gg...",
        "..g..",
        "...g.",
        "....g",
    ], 5, 7)
    tag = Layer(16, 9)
    tag.rect(0, 0, 16, 9, "white")
    tag.hline(0, 15, 8, "paper"); tag.vline(15, 0, 8, "paper")
    tag.px[0][0] = None; tag.px[8][0] = None                     # clipped corners: a tag, not a card
    tag.set(1, 4, "paper")                                        # the string hole's shadow
    digits(tag, "0.30", 2, 2, "ink", gap=1)
    return compose(bottle, string, (tag.outlined("outline", pad=1), 7, 10))


SPINS["s01"] = ("פיקדון על בקבוקים", _s01)


# ---------------------------------------------------------------- s02 a pistachio cone, melting
def _s02():
    import math
    cone = Layer(16, 12)
    for y in range(12):
        half = 8 - y * 8 / 12.5
        for x in range(16):
            if abs(x + 0.5 - 8) <= max(half, 1.0):
                waffle = (x + y) % 4 == 0 or (x - y) % 4 == 0
                shade = x + 0.5 > 8 + half - 2
                cone.set(x, y, "stone_sh" if (waffle or shade) else "stone")
    # a smooth dome (not a bumpy one: bumps read as broccoli), light top-left
    scoop = Layer(16, 12)
    for y in range(12):
        for x in range(16):
            d = math.hypot((x + 0.5 - 8) / 8.0, (y + 0.5 - 7) / 7.0)
            if d <= 1.0 and y <= 8:
                lx, ly = (x + 0.5 - 5) / 8.0, (y + 0.5 - 3) / 7.0
                l = math.hypot(lx, ly)
                scoop.set(x, y, "lime" if l < 0.75 else ("green" if l < 1.1 else "green_sh"))
    scoop.set(4, 2, "white"); scoop.set(5, 2, "white"); scoop.set(4, 3, "white")
    # the melted lip over the cone's rim, and two drips running down it
    for x in range(1, 15):
        scoop.set(x, 9, "green" if x < 11 else "green_sh")
    for x in (2, 3, 6, 7, 8, 12, 13):
        scoop.set(x, 10, "green" if x < 11 else "green_sh")
    scoop.set(3, 11, "green"); scoop.set(7, 11, "lime"); scoop.set(8, 11, "green")
    drip = part(["L", "G", "G", "G"], 11, 13)
    drop = part(["L", "G"], 19, 18)
    puddle = part(["LLGG"], 17, 22)
    C = compose((cone.outlined("outline", pad=1), 3, 10), (scoop.outlined("outline", pad=1), 3, 1), drip, drop, puddle)
    dots(C, [(9, 4), (14, 6)], "green_sh")                           # two pistachio bits, no more
    return C

SPINS["s02"] = ("גלידת פיסטוק", _s02)


# ---------------------------------------------------------------- s03 a baby monitor wearing a tiny top hat
def _s03():
    antenna = part(["s", "s", "g", "g", "g"], 17, 3)
    body = part([
        ".wwwwwwwwwwwp.",
        "wwwwwwwwwwwwwp",
        "wwssssssssswwp",
        "wwslglglglswwp",
        "wwsglglglgswwp",
        "wwslglglglswwp",
        "wwsglglglgswwp",
        "wwssssssssswwp",
        "wwwwwwwwwwwwwp",
        "wwrwwwLwwwwwwp",
        "wwwwwwwwwwwwwp",
        "wppppppppppppp",
        ".pppppppppppp.",
    ], 5, 9)
    hat = part([
        "..dddddd..",
        "..duddud..",
        "..dudddd..",
        "..dudddd..",
        "..FFFFFF..",
        "..BBBBBB..",
        "UUUUUUUUUd",
    ], 3, 1)
    waves = part([
        "..g",
        ".g.",
        "g..",
    ], 20, 13)
    return compose(antenna, body, hat)


SPINS["s03"] = ("ביביסיטר", _s03)


# ---------------------------------------------------------------- s04 an empty speech bubble, stamped "0"
def _s04():
    bubble = part([
        "wwwwwwwwwwwwwwwwwww.",
        "wwwwwwwwwwwwwwwwwwwp",
        "wwwwwwwwwwwwwwwwwwwp",
        "wwwwwwwwwwwwwwwwwwwp",
        "wwwwwwwwwwwwwwwwwwwp",
        "wwwwwwwwwwwwwwwwwwwp",
        "wwwwwwwwwwwwwwwwwwwp",
        "wwwwwwwwwwwwwwwwwwwp",
        "wwwwwwwwwwwwwwwwwwwp",
        "wwwwwwwwwwwwwwwwwwwp",
        "wwwwwwwwwwwwwwwwwwwp",
        ".ppppppppppppppwwwpp",
        "...............wwp..",
        "................wp..",
        ".................p..",
    ], 1, 1)
    C = compose(bubble)
    C.px[1][1] = None; C.px[1][21] = None                            # rounded corners, re-outlined below
    for (x, y) in [(1, 1), (21, 1)]:
        C.px[y][x] = "outline"
    # the stamp: a violet double frame with a "0", axis-aligned, speckled (style guide §4, do/don't 8)
    S = Layer(11, 11)
    for i in range(11):
        S.set(i, 0, "stamp"); S.set(i, 10, "stamp"); S.set(0, i, "stamp"); S.set(10, i, "stamp")
    for i in range(2, 9):
        S.set(i, 2, "stamp"); S.set(i, 8, "stamp"); S.set(2, i, "stamp"); S.set(8, i, "stamp")
    digits(S, "0", 4, 3, "stamp")
    for (x, y) in [(3, 0), (10, 6), (0, 8), (6, 10), (8, 5)]:       # ink-starved pixels
        S.px[y][x] = None
    C.paste(S, 10, 3)
    return C


SPINS["s04"] = ("לא יהיה כלום", _s04)


# ---------------------------------------------------------------- s05 an empty butterfly net, mid-swing
def _s05():
    import math
    net = Layer(15, 15)
    for y in range(15):
        for x in range(15):
            d = math.hypot((x - 7) / 6.6, (y - 7) / 6.6)
            if d <= 1.0:
                net.set(x, y, "white" if (x + y) % 2 == 0 else "grey")
    # the bag hangs down-left of the hoop (it trails the swing)
    for y in range(15):
        for x in range(15):
            d = math.hypot((x - 7) / 6.6, (y - 7) / 6.6)
            if 0.84 <= d <= 1.08:
                net.set(x, y, "silver" if x + y < 15 else "slate")
    handle = part([
        ".......WD",
        "......WD.",
        ".....WD..",
        "....WD...",
        "...WD....",
        "..WD.....",
        ".WD......",
        "WD.......",
    ], 1, 15)
    swish = part([
        "g.......",
        ".g......",
        "..gg....",
    ], 1, 1)
    C = compose(handle, (net.outlined("outline", pad=1), 8, 1))
    # three speed marks behind the swing (the hunt), no witch anywhere
    for (x0, y0) in ((3, 4), (2, 8), (4, 12)):
        C.hline(x0, x0 + 2, y0, "slate")
    return C


SPINS["s05"] = ("ציד מכשפות", _s05)


# ---------------------------------------------------------------- s06 the jet, side view; one window seat lit
def _s06():
    tail = part([
        "B....",
        "BB...",
        "BBF..",
        "BBBF.",
        "BBBBF",
    ], 1, 2)
    body = part([
        "wwwwwwwwwwwwwwwwwww...",
        "wwwwwwwwwwwwwwwwwwwww.",
        "wbwbwbwbwbwbYwbwbwsbww",
        "wwwwwwwwwwwwwwwwwwwsww",
        "BBBBBBBBBBBBBBBBBBBBBs",
        "FFFFFFFFFFFFFFFFFFFFs.",
        ".sssssssssssssssssss..",
    ], 1, 7)
    wing = part([
        "wwwwwww...",
        ".wwwwwsss.",
        "..ssssslll",
    ], 6, 14)
    engine = part([
        "wwwwg",
        "sslll",
    ], 9, 18)
    stab = part(["www", "sss"], 1, 12)
    C = compose(tail, stab, body, wing, engine)
    return C

SPINS["s06"] = ("כנף ציון", _s06)


# ---------------------------------------------------------------- s07 one finger in a Spartan helmet
def _s07():
    crest = part([
        "..rrrrrrr.",
        ".rhhrrrrrR",
        "rhrrrrrrRR",
        "rr......RR",
    ], 7, 0)
    helmet = part([
        ".xxxxxxX.",
        "xxxxxxxxX",
        "xxxxxxxXX",
        "xXXXXXXXX",
        "xX.....XX",
        "xX.....XX",
        "xX.....XX",
        ".X.....X.",
    ], 7, 4)
    finger = part([
        ".jeeef.",
        "jeeeeef",
        "jeeeeef",
        "jeeeeef",
        "jeeeeef",
        "jeeeeef",
        "eeeeeff",
        "eeeeeff",
    ], 8, 6)
    fist = part([
        "..jeeeeeeef...",
        ".jeeeeeeeeeff.",
        "jeeefeeefeeeff",
        "jeeeeeeeeeeeff",
        "eefeeeefeeeeff",
        "eeeeeeeeeeefff",
        "feeeeeeeeeefff",
        ".ffffffffffff.",
        "..ffffffffff..",
    ], 5, 13)
    thumb = part([
        "jeeeeef.",
        "eeeeeeff",
        ".fffff..",
    ], 3, 15)
    C = compose(finger, helmet, crest, fist, thumb)
    C.set(10, 9, "skin_hi"); C.set(11, 9, "skin")                   # the fingertip looks out of the visor
    return C


SPINS["s07"] = ("סופר־ספרטה", _s07)


# ---------------------------------------------------------------- s08 the remote: one big button, all channels
def _s08():
    remote = part([
        ".UUUUUUUUu.",
        "UuuuuuuuuUd",
        "Uu.......ud",
        "Uu.......ud",
        "Uu.......ud",
        "Uu.......ud",
        "Uu.......ud",
        "UuuuuuuuuUd",
        "UuwuuwuuwUd",
        "UuuuuuuuuUd",
        "UuwuuwuuwUd",
        "UuuuuuuuuUd",
        "UuwuuwuuwUd",
        "UuuuuuuuuUd",
        "UuuuuuuuuUd",
        "UuuuuuuuuUd",
        "uddddddddd.",
    ], 5, 6)
    button = part([
        ".hhhhr.",
        "hhwhrrr",
        "hhhrrrR",
        "hrrrrRR",
        "rrrrRRR",
        ".RRRRR.",
    ], 7, 8)
    C = compose(remote, button)
    # the signal: two arcs out of the top
    for (x, y) in [(8, 3), (9, 2), (10, 2), (11, 2), (12, 3), (7, 1), (8, 0), (9, 0), (10, 0), (11, 0), (12, 0), (13, 1)]:
        C.set(x, y, "sky")
    return C


SPINS["s08"] = ("השלט", _s08)


# ---------------------------------------------------------------- s09 a gold pager, gift-wrapped
def _s09():
    bow = part([
        ".PP...PP.",
        "PwPP.PPqP",
        "PPqPPPqqP",
        ".qqPPPqq.",
        "...qPq...",
    ], 7, 1)
    pager = part([
        "YYYYYYYYYYYYYYYYYYo",
        "YyyyyyyyPPyyyyyyyyo",
        "Yyyyyyyyqqyyyyyyyyo",
        "Yynnnnnnnnnnnnnnnyo",
        "YynbbbbbbbbbbbbbnyO",
        "Yynbnnbnbbnbnbbbnyo",
        "YynbbbbbbbbbbbbbnyO",
        "Yynnnnnnnnnnnnnnnyo",
        "YyyyyyyyqqyyyyyyyyO",
        "YyYyyYyyPPyyYyyYyyo",
        "YyyyyyyyqqyyyyyyyyO",
        "ooooooooooooooooooO",
    ], 2, 8)
    C = compose(pager, bow)
    return C


SPINS["s09"] = ("פייג׳ר זהב", _s09)


# ---------------------------------------------------------------- s10 a laundry sack with a luggage tag, a sock out
def _s10():
    sock = part([                                                    # a striped tube sock, foot out
        "..ww",
        "..bb",
        "..ww",
        "..bb",
        "..ww",
        "..wp",
        "wwwp",
        "wwpp",
    ], 1, 1)
    sleeve = part([
        "..PPP",
        ".PPPq",
        "PPPq.",
        "PPq..",
    ], 11, 3)
    sack = part([
        "...wwwwwwwp..",
        "..wwwwwwwwwp.",
        ".wwwwwwwwwwwp",
        "wwwwwwwwwwwwp",
        "wwwwwwpwwwwwp",
        "wwwwwpwwwwwwp",
        "wwwwwwwwwwwpp",
        "wwwwwwwwwwwpp",
        "pwwwwwwwwwppp",
        "ppwwwwwwwpppp",
        ".pppppppppppp",
        "..ppppppppp..",
    ], 2, 9)
    neck = part(["..wpw..", "...p..."], 5, 7)
    tie = part(["WWW", "DDD"], 7, 7)
    string = part(["l", ".l", "..l"], 15, 10)
    tag = part([
        ".tttt",
        "ttttT",
        "tDDtT",
        "ttttT",
        "tDDDT",
        "TTTTT",
    ], 17, 12)
    return compose(sleeve, neck, sock, sack, tie, string, tag)

SPINS["s10"] = ("מזוודות כביסה", _s10)


# ---------------------------------------------------------------- s11 the game's rabbit with a carrot microphone
def _s11():
    ears = part([
        ".ss....ss.",
        "sPs...sPs.",
        "sPs...sPs.",
        "sPg...sPg.",
        "sPg...sPg.",
        ".sg...sg..",
    ], 3, 0)
    head = part([
        "..sssssss...",
        ".sssssssssg.",
        "sssiwssiwsgg",
        "sssiisssiigg",
        "sssssPPsssgg",
        "sssswwwwsggg",
        ".ssssiisggg.",
        "..gggggggg..",
    ], 1, 6)
    body = part([
        ".sssssssg.",
        "sssssssggg",
        "ssssssgggg",
        ".gggggggg.",
    ], 2, 15)
    mic = part([
        "..GE",
        ".GGE",
        "lllx",
        "lglx",
        "xxxX",
        "xxxX",
        "xxX.",
        "xX..",
        "X...",
    ], 15, 5)
    paw = part(["ss", "sg"], 13, 11)
    return compose(body, ears, head, mic, paw)


SPINS["s11"] = ("באגס באני", _s11)


# ---------------------------------------------------------------- s12 the committee: a frozen binder, an idle gavel, a cobweb
# Bar, 2026-09-29 (design/redlines.json `oct7-hostages`, visual echoes included): the old icon, three empty
# chairs at a table, echoed a memorial symbol, so the committee is now its paperwork: a fat lever-arch binder
# whose spine label has the shape of "ועדה" (4 micro glyphs, RTL; not meant to be read at 24 px), frosted
# over with icicles (the suspicion is frozen), a gavel lying on top that nobody picks up, and a cobweb.
# No chair, table, seat or empty place setting in this icon, ever.
MICRO_VAADA = [                    # visual order, left to right = ה ד ע ו (the word reads right to left)
    "###.###.#.#.#",
    "..#...#..##.#",
    "#.#...#.##..#",
]


def _s12():
    W, H = 17, 16
    binder = Layer(W, H)
    binder.rect(0, 0, W, H, "teal")
    binder.vline(0, 0, H - 1, "teal_hi")                             # light plane: the spine's left edge
    binder.rect(W - 2, 0, 2, H, "teal_dk")                           # the back cover's thickness, in shadow
    binder.hline(1, W - 3, H - 2, "teal_dk")                         # the foot
    binder.hline(0, W - 3, H - 1, "teal_dk")
    # the spine label: paper on the teal, "ועדה" in ink micro glyphs
    binder.rect(1, 4, 14, 5, "white")
    binder.hline(1, 14, 8, "paper"); binder.vline(14, 4, 8, "paper")
    for j, row in enumerate(MICRO_VAADA):
        for i, v in enumerate(row):
            if v == "#":
                binder.set(1 + i, 5 + j, "ink")
    # the finger hole of a lever-arch spine: sunk, lit on its lower inner edge
    binder.rect(6, 10, 4, 3, "teal_dk")
    binder.hline(7, 9, 12, "teal_hi")
    # frost on the top edge, and three icicles hanging over the label
    binder.hline(0, W - 1, 0, "white")
    binder.hline(0, W - 1, 1, "silver")
    for x, n in ((2, 2), (8, 3), (13, 2)):
        binder.set(x, 1, "white")
        binder.vline(x, 2, 1 + n, "sky")
    # the gavel, lying on its side on the file: the head stands on its face (frosted top, two grooves)
    gavel_handle = part(["WWWWWWWWWWt", "DDDDDDDDDDD"], 11, 5)
    gavel_head = part([
        "wwww",
        "tWWD",
        "DDDD",
        "tWWD",
        "tWWD",
        "DDDD",
    ], 6, 1)
    C = compose((binder.outlined("outline", pad=1), 3, 6), gavel_handle, gavel_head)
    # a cobweb in the top-right corner, strung to the gavel's handle: nobody has lifted it in a while
    for (x, y) in [(23, 0), (22, 1), (21, 2), (20, 3), (21, 0), (21, 1), (22, 2), (23, 2), (23, 4), (22, 3), (23, 3)]:
        if C.get(x, y) is None:
            C.set(x, y, "grey")
    # a snowflake in the top-left corner: the freeze, said once more for the small screen
    FLAKE = ["#.#.#", ".###.", "##o##", ".###.", "#.#.#"]
    for j, row in enumerate(FLAKE):
        for i, v in enumerate(row):
            if v != ".":
                C.set(i, j, "white" if v == "o" else "sky")
    return C

SPINS["s12"] = ("הוחלט להקים ועדה", _s12)


# ---------------------------------------------------------------- s13 the friendly-channel couch: two mugs, one heart
def _s13():
    lamp = part([
        "ss.",
        "sYs",
        ".s.",
        ".l.",
        ".l.",
        ".l.",
    ], 19, 1)
    couch_back = part([
        ".qqqqqqqqqqqqqqqq.",
        "qZZZZZZZZZZZZZZZZz",
        "ZZZZZZZZZZZZZZZZZz",
        "ZZZZZZZZZZZZZZZZzz",
    ], 1, 7)
    seat = part([
        "qqqqqqqqqqqqqqqqqqqq",
        "ZZZZZZZZZZZZZZZZZZZz",
        "zzzzzzzzzzzzzzzzzzzz",
        "zz................zz",
        "zz................zz",
    ], 1, 11)
    table = part([
        "WWWWWWWWWWWW",
        "DDDDDDDDDDDD",
        ".DD......DD.",
        ".DD......DD.",
    ], 6, 17)
    mug1 = part(["www.", "wPwg", "PPPg", "wPpg", "ppp."], 7, 12)
    mug2 = part(["www.", "wwwg", "wwwg", "wwpg", "ppp."], 13, 12)
    C = compose(lamp, couch_back, seat, table, mug1, mug2)
    for (x, y) in [(8, 10), (9, 9), (14, 10), (15, 9)]:
        C.set(x, y, "white")                                         # steam: it's cosy in there
    return C

SPINS["s13"] = ("ראיון בערוץ ידידותי", _s13)


# ---------------------------------------------------------------- s14 a phone: play, a huge view count, 1 like
def _s14():
    phone = Layer(14, 21)
    phone.rect(0, 0, 14, 21, "night")
    phone.hline(1, 12, 0, "suit"); phone.vline(0, 1, 19, "suit")
    phone.rect(1, 2, 12, 10, "white")                                # the video
    phone.hline(1, 12, 11, "paper"); phone.vline(12, 2, 11, "paper")
    for y in range(3, 10):                                           # the play glyph
        w = 4 - abs(y - 6)
        phone.hline(5, 5 + w, y, "pink")
    phone.vline(5, 3, 9, "pink_sh")
    digits(phone, "999", 1, 13, "white", gap=1)                      # the view counter, edge to edge
    # the likes: a heart and a "1" (realLikesAdd 1)
    for (x, y) in [(2, 19), (4, 19), (1, 19)]:
        pass
    phone.set(2, 18, "red"); phone.set(4, 18, "red")
    phone.hline(2, 4, 19, "red"); phone.set(3, 20, "red"); phone.set(1, 18, None) if False else None
    phone.hline(1, 5, 18, "night"); phone.set(2, 18, "red"); phone.set(4, 18, "red")
    phone.vline(8, 18, 20, "white"); phone.set(7, 18, "white")
    phone.px[0][0] = None; phone.px[0][13] = None; phone.px[20][0] = None; phone.px[20][13] = None
    arrow = part([                                                   # trending: up and to the right
        "...LL",
        "..LLG",
        ".LLEG",
        "LLE.G",
        "LE...",
    ], 18, 1)
    return compose((phone.outlined("outline", pad=1), 3, 2), arrow)

SPINS["s14"] = ("סרטון ויראלי", _s14)


# ---------------------------------------------------------------- s15 the state visit: two armchairs, a cigar in an ashtray
def _s15():
    def chair(x, flip):
        rows = [
            ".tttttt..",
            "ttttttTT.",
            "tTtttTTT.",
            "tTtttTTTT",
            "tTTTTTTtT",
            "ttwwwwwTT",
            "tTttttTTT",
            "TTTTTTTTT",
            "D.......D",
        ]
        if flip:
            rows = [r[::-1] for r in rows]
        return part(rows, x, 3)
    ashtray = part([
        "sssssssss",
        "lglllllgl",
        ".lllllll.",
    ], 7, 18)
    cigar = part(["xXWWWWWWD"], 6, 17)
    smoke = part(["..g.", ".g..", ".g..", "..g."], 5, 12)
    C = compose(chair(1, False), chair(14, True), smoke, ashtray, cigar)
    C.set(5, 17, "orange"); C.set(5, 18, "red")                      # the ember
    return C

SPINS["s15"] = ("ביקור ממלכתי", _s15)


def build_all():
    out = {}
    for sid, (name, fn) in SPINS.items():
        L = fn()
        assert (L.w, L.h) == (N, N), (sid, L.w, L.h)
        out[sid] = (name, L)
    return out
