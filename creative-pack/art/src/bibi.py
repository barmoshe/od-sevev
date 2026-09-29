"""The Magician's likeness, from the Israeli caricature canon (traits only; never traced).

Anchors, in priority order:
 1. HAIR: thick silver-white, combed straight BACK from a HIGH hairline, rising in a smooth
    high wave above the front of the head, sleek and flat on the sides, slight side sweep.
 2. BROAD EXPOSED FOREHEAD + heavy, low, dark-grey brows, one raised (the lecture look).
 3. Small, narrow, HOODED eyes with bags; knowing, half-lidded (not slits).
 4. BIG FLESHY NOSE with a wide tip.
 5. PEAR-SHAPED lower face: wider at the jowls than the temples, broad square jaw,
    double-chin hint, deep nasolabial folds, wide tight-lipped HALF-SMIRK.
 6. Ruddy/tanned skin: the shadow tone is used more generously than on the cast.
Legend: I white-hair light, G silver, g grey, s slate (hair shade), K skin, L skin light,
k skin shade (ruddy), d skin deep, B brow, b brow deep, W eye white, e ink.
"""
from pix import Layer, from_grid

LEG = {"I": "white", "G": "silver", "g": "grey", "s": "slate", "K": "skin", "L": "skin_hi",
       "k": "skin_sh", "d": "skin_dk", "B": "suit", "b": "suit_dk", "W": "white", "e": "ink",
       "F": "skin", "f": "skin_sh"}

# B: pushed caricature (the pick). 30 wide x 34.
HEAD_B = [
    "........IIIII.................",
    "......IIIIIIIIG...............",
    ".....IIIIIIIIIIIGg............",
    "....GIIIIgggIIIIIIGGg.........",
    "....GIIIIIIIIgggIIIIIGGgg.....",
    "...sGGIIIIIIIIIIIgggIIIGGgg...",
    "...sgGGGIIIIIIIIIIIIgIIIGGgs..",
    "...ssgGGGGGIIIIIIIIIIIIGGGgs..",
    "....sgGGGgggggggggggggGGggs...",
    "....sgGKKLLLLLLLLLLLLLKGgs....",
    "....sgKKLLLLLLLLLLLLLLKKgs....",
    "....sgKKKLLLLLLLLLLLKKKKgs....",
    "....sgKKBBBBBKLLLLKKKKKKkgs...",
    "....sKKBbbbbbBKLLKKBBBBBBkgs..",
    "...KsKKKKKKKKKKLLKKbbbbbbbkkK.",
    "...KKKkkkkkKKKLLLKkkkkkkKkkK..",
    "...KKKKWeeKKKLLLLkKWeeKKKkkK..",
    "...KKKkkkkKKKLLLLLkkkkkKKkkK..",
    "...KKKKKKKKKLLLLLLkKKKKKKkkk..",
    "..KKKKKKKKKKLLLLLLkkKKKKKkkk..",
    "..KKKKKKKKKkLLLLLLLkkKKKKkkk..",
    ".KKKKKKKKKkLLLLLLLLLkkKKKkkkk.",
    ".KKKKKKKKkLLLLLLLLLLkkKKKkkkk.",
    ".KKKKKKKkkLLLLLLLLLkkkKKKkkkk.",
    ".KKKKKKkKkdLLLLLLdkkkKkKkkkkk.",
    ".KKKKKkKKKkkddddkkkKKkKKkkkkk.",
    ".KKKKkKKKKKKKKKKKKKKKKkddkkkk.",
    ".KKKKkKKddddddddddddddkKkkkkk.",
    ".KKKKKkKKkkkkkkkkkkkKKKkkkkkk.",
    ".KKKKKKKKKKKKKKKKKKKKKKkkkkkk.",
    "..KKKKKKKKKKKLKKKKKKKKkkkkk...",
    "..kKKKKKKKKKKKKKKKKKKkkkkkk...",
    "...kkKKKKKkkkkkkKKKKKkkkkk....",
    ".....kkkkkkkkkkkkkkkkkkk......",
]


# A: faithful, derived from B with less pressure: the wave 2 rows lower, the nose tip
# 2px narrower, the jowls pulled in, no raised brow.
def _faithful(rows):
    out = ["." * 30, "." * 30] + [r for r in rows[2:]]
    for i in range(19, len(out)):
        r = list(out[i])
        for x in (1, 2, 27, 28):
            if r[x] != "." and (i > 20 or x in (1, 28)):
                r[x] = "."
        out[i] = "".join(r)
    for i in (21, 22, 23):
        r = list(out[i])
        for x in (10, 19):
            if r[x] == "L":
                r[x] = "K"
        out[i] = "".join(r)
    out[12] = "....sgKKKKKKKKLLLLKKKKKKkgs..."
    out[13] = "....sKBBBBBBBKLLKKBBBBBBkkgs.."
    return out


HEAD_A = _faithful(HEAD_B)

# C: wildcard, 'the lecture': B's head, left brow shot up, mouth open mid-sentence,
# eyes cutting to the viewer. The finger is added at bust level by bust().
HEAD_C = [r for r in HEAD_B]
HEAD_C[11] = "....sgKBBBBBBKLLLLKKKKKKKkgs.."[:30]
HEAD_C[12] = "....sgBbbKKbbBLLLLKKKKKKkkgs.."[:30]
HEAD_C[26] = ".KKKKkKKKKKKKKKKKKKKKKKkkkkkk."
HEAD_C[27] = ".KKKKkKKdddddddddddddKKkkkkkk."
HEAD_C[28] = ".KKKKKkKdWeeeeeeeeeWdKkkkkkkk."
HEAD_C[29] = ".KKKKKKKKddddddddddKKKKkkkkkk."

# D: the 16x16 chibi read, priority order: wave silhouette > forehead+brows > nose > jowls.
HEAD_D = [
    ".....IIIII......",
    "...IIIIIIIIg....",
    "..sGIIIggIIIGs..",
    ".ssGgggggggGGss.",
    ".sgKLLLLLLLLKgs.",
    ".sKBBBKLLKKKKks.",
    ".KKbbbKLLKbbbkK.",
    "KKKWeKKLLKKWekkK",
    "KKkkkKLLLLkkkkkK",
    "KKKKKLLLLLLkKkkK",
    "KKKKkdLLLLdkKkkK",
    "KKKkKkddddkKKdkK",
    "KKKkdddddddddkkK",
    ".KKKKkkkkkkKKkk.",
    ".kKKKKKKKKKKKkk.",
    "...kkkkkkkkkkk..",
]

HEADS = {"A": HEAD_A, "B": HEAD_B, "C": HEAD_C, "D": HEAD_D}
PICK = "B"


def head(v=PICK):
    rows = HEADS[v]
    w = len(rows[0])
    bad = [(i, len(r)) for i, r in enumerate(rows) if len(r) != w]
    assert not bad, (v, bad)
    return from_grid(rows, LEG).outlined()


def finger_hand():
    """The lecturing hand: fist with the index finger straight up."""
    return from_grid([
        ".KK..",
        ".KL..",
        ".KL..",
        ".KL..",
        "KKKKk",
        "KKLKk",
        "KKKkk",
        ".kkk.",
    ], LEG)


def bust(v):
    """Head + shoulders (+ lecturing finger for C), as seen in HUD portraits/cards."""
    h = head(v)
    W, H = max(h.w + 6, 40), h.h + 12
    L = Layer(W, H)
    sh = Layer(W - 2, 12)
    sh.rect(2, 0, W - 6, 12, "suit")
    sh.rect(W // 2 - 4, 0, 6, 8, "white")
    sh.rect(W // 2 - 2, 1, 2, 11, "flag")
    sh.rect(W // 2 + 7, 3, 3, 1, "flag"); sh.rect(W // 2 + 7, 4, 3, 1, "white"); sh.rect(W // 2 + 7, 5, 3, 1, "flag")
    L.paste(sh.outlined(), 0, H - 14)
    L.paste(h, (W - h.w) // 2, 0)
    if v == "C":
        f = finger_hand().outlined()
        L.paste(f, W - f.w - 1, H - 22)
    return L


# ===========================================================================================
# v2 (client push, 28 Sep): the canon read, rebuilt from the client's trait notes.
#  - NOT a cap: a high, mostly bald DOME with thin swept-back strands; the volume is in
#    silver WINGS on the sides/back, puffing out above and behind the ears
#  - BIG protruding EARS beside the wings (the #1 small-scale anchor)
#  - SIDE-EYE: both pupils cut to one side; one heavy brow RAISED, the other low
#  - closed SMIRK, one corner up; deep nose-to-mouth lines; bags
#  - big fleshy round-tipped NOSE
#  - NAVY suit (navy / navy_hi / night), white shirt, bright flag-blue tie, flag pin
# ===========================================================================================
HEAD_V2 = [
    "............GIIIG...............",
    "..........KGLLIGGK..............",
    "........KKLLGLLLIGKK............",
    "......gKKLLLLLGLLLLGKKg.........",
    ".....gGKLLLLLLLLLLLLLLKGg.......",
    "....gGIGKLLLLLLLLLLLLLKGIGg.....",
    "...sgIIGKLLLLLLLLLLLLLKKGIIGs...",
    "..ssGIIGKLLLkkkkkkkLLLKKGIIGgs..",
    "..sgGIIGKKLLLLLLLLLLLKKKGIIGgs..",
    "..sgGIGGKKLLLkkkkkkLLKKKGGIGgs..",
    "..sgGGGKKBBBBKLLLLLLLKKKKGGGgs..",
    "..sgGGKKBbbbbBKLLLLKKKKKKKGGgs..",
    ".KKsgGKKKKKKKKKLLLKKBBBBBBKGgKK.",
    "KKkKgKKkkkkkKKKLLLKBbbbbbbkKkKkK",
    "KkkKKKKWWWeKKKLLLLKkWWeekKKKkkkK",
    "KkKKKKKkkkkKKLLLLLkkkkkkkKKKKkkK",
    "KKkKKKKKKKKKLLLLLLLkKKKKKKKKkkkK",
    ".KKKKKKKKKKLLLLLLLLLkKKKKKKKkkK.",
    "..KKKKKKKKLLLLLLLLLLLkKKKKKKkk..",
    "..KKKKKKKkLLLLLLLLLLLkkKKKKKkk..",
    "..KKKKKKkKdLLLLLLLLdkkkKKKKkkk..",
    "..KKKKKdKKKKkddddkkkKKKdKKKkkk..",
    "..KKKKdKKKKKKKKKKKKKKKKdKKkkkk..",
    "..KKKKddKKKKKKKKKKKKKKdKKKkkkk..",
    "..KKKKKKdddddddddddddKKKKKkkkk..",
    "..KKKKKKKkkkkkkkkkkkKKKKKkkkkk..",
    "...KKKKKKKKKKKKKKKKKKKKKkkkkk...",
    "...kKKKKKKKKKKKKKKKKKKKkkkkkk...",
    "....kkKKKKKKkkkkkkkKKKKkkkkk....",
    "......kkkkkkkkkkkkkkkkkkkk......",
]

CHIBI_V2 = [
    ".....KGLLK......",
    "...KKLLGLLKK....",
    "..GKLLLLLLLKKG..",
    ".GIGKLLkkLLKGIG.",
    ".GIGBBKLLLKKGIG.",
    ".sGKbbKLLBBBKGs.",
    "KKKWeKLLLWeKKkKK",
    "KkKkkKLLLLkkKkkK",
    "KKKKKLLLLLLkKKkK",
    ".KKKdLLLLLdkKkk.",
    ".KdKKkddddkKdkk.",
    ".KKdddddddddKkk.",
    ".KKKkkkkkkKKKkk.",
    "..kKKKKKKKKKkk..",
    "...kkkkkkkkkk...",
    "................",
]


def _check(rows):
    w = len(rows[0])
    bad = [(i, len(r)) for i, r in enumerate(rows) if len(r) != w]
    assert not bad, bad
    return rows


def head_v2():
    return from_grid(_check(HEAD_V2), LEG).outlined()


def chibi_v2():
    return from_grid(_check(CHIBI_V2), LEG).outlined()


SUIT = {"J": "navy", "j": "night", "Q": "navy_hi"}


def _torso(L, cx, top, bottom):
    """Navy jacket block centred on cx, rows top..bottom, light from top-left."""
    L.ellipse(cx, top + 6, 11, 6, SUIT["J"])
    L.rect(cx - 11, top + 6, 23, bottom - top - 5, SUIT["J"])
    for y in range(top, bottom + 1):
        for x in range(cx - 13, cx + 14):
            if L.get(x, y) == SUIT["J"]:
                if x >= cx + 5:
                    L.set(x, y, SUIT["j"])
                elif x <= cx - 8:
                    L.set(x, y, SUIT["Q"])
    for y in range(top + 1, top + 9):                        # shirt V
        w = max(0, 3 - (y - top - 1) // 2)
        L.hline(cx - w, cx + 1 + w, y, "white")
    L.rect(cx, top + 1, 2, 2, "flag")                         # knot
    for y in range(top + 3, bottom - 1):                      # bright blue tie on navy: blue on blue
        L.hline(cx, cx + 1, y, "flag"); L.set(cx + 1, y, "flag_hi" if y < top + 5 else "flag")
    for y in range(top + 1, top + 9):                         # lapels
        L.set(cx - 3 - (y - top - 1) // 3, y, SUIT["Q"])
        L.set(cx + 4 + (y - top - 1) // 3, y, SUIT["j"])
    L.rect(cx + 6, top + 4, 3, 1, "flag"); L.rect(cx + 6, top + 5, 3, 1, "white"); L.rect(cx + 6, top + 6, 3, 1, "flag")
    L.set(cx - 1, bottom - 3, SUIT["j"])                      # button


def _legs(L, cx, top, contrapposto=False):
    if contrapposto:   # weight on screen-left leg, screen-right knee relaxed out
        L.rect(cx - 8, top, 6, 11, SUIT["J"]); L.vline(cx - 3, top, top + 10, SUIT["j"])
        for i in range(11):
            L.rect(cx + 2 + i // 4, top + i, 6, 1, SUIT["j"])
        L.rect(cx - 10, top + 11, 8, 3, "ink"); L.hline(cx - 9, cx - 6, top + 11, "suit")
        L.rect(cx + 4, top + 11, 8, 3, "ink")
    else:
        L.rect(cx - 8, top, 6, 11, SUIT["J"]); L.rect(cx + 3, top, 6, 11, SUIT["j"])
        L.vline(cx - 3, top, top + 10, SUIT["j"])
        L.rect(cx - 10, top + 11, 8, 3, "ink"); L.rect(cx + 3, top + 11, 8, 3, "ink")
        L.hline(cx - 9, cx - 6, top + 11, "suit")


def _hat(L, x, y, opening_up=True):
    """Top hat 13 wide; (x, y) = top-left of the brim. Upside down (opening up) by default."""
    L.rect(x + 2, y + 2, 13, 9, "ink")
    L.rect(x + 3, y + 3, 2, 7, "suit_dk"); L.vline(x + 4, y + 3, y + 9, "suit")
    L.rect(x + 2, y + 2, 13, 2, "flag"); L.hline(x + 2, x + 14, y + 2, "flag_hi")
    L.ellipse(x + 8, y + 0.5, 8, 1.6, "suit")
    L.ellipse(x + 8, y + 0.5, 5, 0.7, "ink")
    L.hline(x, x + 4, y - 1, "suit_hi")


def pose_idle():
    """IDLE, 'the lecture': contrapposto, index finger raised by the face, other hand in the
    trouser pocket, the hat waiting upside-down at his feet."""
    L = Layer(48, 64)
    cx = 26
    _legs(L, cx, 50, contrapposto=True)
    _torso(L, cx, 31, 50)
    # pocket arm (screen right): elbow out, hand hidden in the pocket slit
    for i in range(12):                                                            # arm, elbow bowed out
        L.rect(cx + 10 + (1 if 3 <= i <= 8 else 0), 33 + i, 4, 1, SUIT["j"])
    L.rect(cx + 8, 44, 6, 4, SUIT["j"]); L.hline(cx + 7, cx + 11, 48, "ink")       # forearm into pocket
    L.set(cx + 6, 47, "white")                                                     # cuff peeking
    # finger arm (screen left): elbow down-out, fist by the face, index finger up
    for i in range(9):
        L.rect(cx - 16 + i // 3, 36 + i, 6, 1, SUIT["Q"])                            # upper arm
    for i in range(10):
        L.rect(cx - 21 + i // 5, 36 - i, 5, 1, SUIT["J"])                            # forearm up
    L.rect(cx - 22, 25, 6, 2, "white")                                             # cuff
    L.rect(cx - 22, 19, 6, 6, "skin"); L.vline(cx - 17, 19, 24, "skin_sh"); L.hline(cx - 22, cx - 17, 24, "skin_sh")
    L.set(cx - 20, 21, "skin_sh"); L.set(cx - 20, 22, "skin_sh"); L.hline(cx - 21, cx - 18, 19, "skin_hi")
    L.rect(cx - 21, 13, 2, 6, "skin"); L.vline(cx - 20, 13, 18, "skin_sh"); L.set(cx - 21, 13, "skin_hi")
    # the hat at his feet
    _hat(L, 34, 55)
    L.paste(head_v2(), cx - 17, 2)
    return L.outlined()


def pose_tap():
    """TAP, 'the trick': the hat raised high in one hand, opening up; wand in the other."""
    L = Layer(48, 64)
    cx = 20
    _legs(L, cx, 50)
    _torso(L, cx, 31, 50)
    # wand arm (screen left)
    L.rect(cx - 15, 36, 6, 9, SUIT["Q"]); L.vline(cx - 10, 36, 44, SUIT["J"])
    L.rect(cx - 16, 45, 6, 2, "white")
    L.rect(cx - 17, 47, 6, 4, "skin"); L.hline(cx - 17, cx - 12, 50, "skin_sh")
    L.line(cx - 16, 47, cx - 20, 38, "ink"); L.line(cx - 15, 47, cx - 19, 38, "ink")
    L.rect(cx - 20, 36, 2, 2, "white")
    # hat arm (screen right), up
    for i in range(20):
        y = 40 - i
        x = cx + 11 + (i * 7) // 20
        L.rect(x, y, 5, 1, SUIT["j"] if i < 8 else SUIT["J"])
        L.set(x, y, SUIT["Q"])
    L.rect(cx + 17, 19, 6, 2, "white")
    L.rect(cx + 17, 14, 6, 5, "skin"); L.vline(cx + 22, 14, 18, "skin_sh"); L.hline(cx + 18, cx + 21, 14, "skin_hi")
    _hat(L, cx + 12, 3)
    L.paste(head_v2(), cx - 17, 2)
    return L.outlined()


def _build_v2():
    """HEAD_V2 rebuilt by stamping: silhouette -> dome -> wings -> ears -> features.
    Every stamp is a named anchor so a reviewer can find it in the grid."""
    W, H = 32, 30
    g = [["."] * W for _ in range(H)]

    def put(x, y, c):
        if 0 <= x < W and 0 <= y < H:
            g[y][x] = c

    def span(y, x0, x1, c):
        for x in range(x0, x1 + 1):
            put(x, y, c)

    # 1. face + dome silhouette (pear: narrower at the temples, widest at the jowls)
    prof = {0: (13, 17), 1: (11, 19), 2: (9, 21), 3: (8, 22), 4: (7, 23), 5: (6, 24), 6: (6, 24),
            7: (5, 25), 8: (5, 25), 9: (5, 25), 10: (5, 25), 11: (6, 25), 12: (6, 25), 13: (6, 25),
            14: (6, 25), 15: (6, 25), 16: (6, 25), 17: (6, 25), 18: (6, 25), 19: (5, 26), 20: (5, 26),
            21: (5, 26), 22: (4, 27), 23: (4, 27), 24: (4, 27), 25: (4, 27), 26: (5, 26), 27: (5, 26),
            28: (7, 24), 29: (10, 21)}
    for y, (a, b) in prof.items():
        span(y, a, b, "K")
        for x in range(b - 3, b + 1):                     # shadow side (right)
            put(x, y, "k")
    # dome light: big exposed forehead, up to the crown
    for y in range(1, 11):
        a, b = prof[y]
        span(y, a + 2, b - 5, "L")
    # forehead wrinkles
    span(6, 12, 18, "k"); span(8, 11, 19, "k")
    # thin swept-back strands over the dome
    for (x, y) in [(13, 0), (14, 0), (15, 0), (16, 0), (12, 1), (15, 1), (16, 1), (17, 1), (11, 2), (17, 2), (18, 2),
                   (19, 3), (20, 3), (10, 3), (21, 4)]:
        put(x, y, "G" if (x + y) % 3 else "I")
    # 2. silver WINGS, sides and back, puffed out above/behind the ears
    for side in (0, 1):
        for y in range(3, 13):
            w = [2, 3, 4, 5, 5, 5, 5, 5, 4, 3][y - 3]
            for i in range(w):
                x = (prof[y][0] + 1 - w + i) if side == 0 else (prof[y][1] - 1 + w - i)
                x = x - 2 if side == 0 else x + 2
                c = "I" if i == w - 2 else ("G" if i < w - 2 else "g")
                if side == 1:
                    c = "G" if i == w - 2 else ("g" if i < w - 2 else "s")
                put(x, y, c)
            # swept-back strand line through each wing
            if 5 <= y <= 10:
                put((prof[y][0] - 1) if side == 0 else (prof[y][1] + 1), y, "g" if side == 0 else "s")
    # 3. EARS: stick out below the wings, rows 12-19, with an inner curl and a separator
    for side in (0, 1):
        sx = 0 if side == 0 else 31
        d = 1 if side == 0 else -1
        rows = {11: "..KK", 12: ".KKKK", 13: "KKddK", 14: "KdKKK", 15: "KdKKK", 16: "KKddK", 17: ".KKKK", 18: "..KK"}
        for y, pat in rows.items():
            for i, c in enumerate(pat):
                if c != ".":
                    put(sx + d * i, y, c if side == 0 else ("k" if c == "K" and i == 0 else c))
        for y in range(12, 18):
            put(sx + d * 5, y, "k")                       # the crease where ear meets head
        put(sx + d * 0, 18, "."); put(sx + d * 1, 18, "."); put(sx + d * 0, 19, "."); put(sx + d * 1, 19, ".")
        put(sx + d * 2, 19, "."); put(sx + d * 3, 19, ".")   # carve under the lobe so the outline wraps it
    # 4. BROWS: screen-left raised and arched, screen-right low and heavy
    span(10, 9, 13, "B"); span(11, 8, 9, "B"); span(11, 10, 14, "b"); put(14, 12, "b")
    span(12, 18, 24, "B"); span(13, 17, 24, "b")
    # 5. EYES: side-eye to screen right, hooded
    span(13, 8, 12, "k")                                   # heavy upper lid under the raised brow
    put(8, 14, "W"); put(9, 14, "W"); put(10, 14, "W"); put(11, 14, "e"); put(12, 14, "e")
    put(18, 14, "W"); put(19, 14, "W"); put(20, 14, "e"); put(21, 14, "e")
    span(15, 8, 12, "k"); span(15, 18, 22, "k")            # lower lids
    span(16, 8, 11, "k"); span(16, 19, 22, "k")            # bags
    # 6. NOSE: big, fleshy, round tip
    for y in range(12, 17):
        span(y, 14, 16, "L"); put(17, y, "k")
    span(17, 13, 17, "L"); put(18, 17, "k")
    span(18, 12, 18, "L"); put(19, 18, "k")
    span(19, 12, 18, "L"); put(19, 19, "k"); put(14, 18, "W") if False else None
    span(20, 13, 17, "L"); put(12, 20, "d"); put(18, 20, "d")    # nostril wings
    span(21, 13, 17, "k")                                    # under-nose shadow
    put(15, 18, "L")
    # 7. nose-to-mouth folds + the SMIRK (closed, screen-left corner up)
    put(11, 20, "d"); put(10, 21, "d"); put(9, 22, "d"); put(9, 23, "d")
    put(19, 20, "d"); put(20, 21, "d"); put(21, 22, "d"); put(21, 23, "d")
    put(10, 23, "d"); span(24, 11, 19, "d"); put(20, 24, "k")
    span(25, 13, 18, "k")                                    # lower lip shade
    # 8. jowls + double chin
    span(27, 9, 21, "k"); put(8, 26, "k"); put(22, 26, "k")
    return ["".join(r) for r in g]


HEAD_V2 = _build_v2()
