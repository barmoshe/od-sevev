"""15x15 icons, wave 2: the spins' first drafts (content.json upgrades; s12 removed, see below), the 17
trophy icon ids (content.json achievements[].icon), and the gear / sound on / sound off controls.

The shipped spin icons are the 24x24 ones in icons24.py (wave 5). Of the 15x15 spin grids only s06 (as the
trophy `icon_plane`) and s10 (as the stage `laundry_bag`) still ship; the rest are kept as reference.

Rules: 1 px `outline` silhouette, 3-band shading, one dominant hue per icon so a row of them never
reads as one colour; nothing that is a flag, an emblem, a party colour or a real logo. Grids are
right-padded to 15 with '.'.
"""
import math
from pix import Layer
from kit import grid_layer, outline_inplace

LEG = {
    "k": "outline", "i": "ink", "w": "white", "p": "paper", "s": "silver", "g": "grey", "l": "slate",
    "U": "suit_hi", "u": "suit", "d": "suit_dk", "n": "night",
    "y": "gold", "Y": "gold_hi", "o": "gold_sh", "O": "gold_dk",
    "r": "red", "R": "red_dk", "h": "red_hi",
    "P": "pink", "q": "pink_sh", "G": "green", "E": "green_sh", "L": "lime",
    "b": "sky", "B": "flag_hi", "F": "flag", "N": "navy",
    "t": "stone", "T": "stone_sh", "W": "wood", "D": "wood_dk",
    "m": "maroon", "M": "maroon_dk", "e": "skin", "f": "skin_sh", "j": "skin_hi",
    "x": "orange", "X": "orange_sh", "V": "stamp", "v": "stamp_lt", "c": "teal", "C": "teal_dk",
    "z": "plum", "Z": "plum_hi", "a": "rim", "K": "hair_dk",
}


def G(rows):
    rows = [r.ljust(15, ".") for r in rows]
    rows += ["." * 15] * (15 - len(rows))
    assert len(rows) == 15 and all(len(r) == 15 for r in rows), rows
    return grid_layer(rows, LEG)


# ------------------------------------------------------------------ spins (upgrades)
SPINS = {}

SPINS["s01"] = ("פיקדון על בקבוקים", G([            # a glass bottle with a deposit tag
    "....kkk",
    "....kgk",
    "....kgk",
    "....kGk",
    "...kGLGk",
    "..kGGLGGk",
    "..kGGLGGk.kkkkk",
    "..kGGLGGkkwwwwk",
    "..kGGLGGk.kwiwk",
    "..kGGGGGk.kwwwk",
    "..kGGGGGk.kwiwk",
    "..kGGGGEk.kwwpk",
    "..kEEEEEk.kkkkk",
    "...kkkkk",
]))

SPINS["s02"] = ("גלידת פיסטוק", G([                  # a melting pistachio cone
    ".....kkkk",
    "...kkLLLLkk",
    "..kLLwwLLLLk",
    "..kLLLLLLLGk",
    ".kLLLLLLLLGGk",
    ".kGLLGLLLGGGk",
    ".kkGGkGGGkGkk",
    "..ktGktTtktk",
    "..kTtTtTtTtk",
    "...ktTtTtTk",
    "...kTtTtTtk",
    "....ktTtTk",
    "....kTtTtk",
    ".....ktTk",
    "......kk",
]))

SPINS["s03"] = ("ביביסיטר", G([                      # a baby monitor wearing a tiny top hat
    ".....kkkkk",
    ".....kdddk",
    ".....kdddk",
    ".....kFFFk",
    "...kkkkkkkkk.k",
    "...kwwwwwwwk.k",
    "..kwwwwwwwwwkk",
    "..kwlwlwlwwpk",
    "..kwwlwlwlwpk",
    "..kwlwlwlwwpk",
    "..kwwwwwwwwpk",
    "..kwLwwwwwwpk",
    "..kppppppppk",
    "...kkkkkkkk",
]))

SPINS["s04"] = ("לא יהיה כלום", G([                  # an empty speech bubble, stamped
    "kkkkkkkkkkkk",
    "kwwwwwwwwwwk",
    "kwwwwwwwwwwk",
    "kwwwwwwwwwwk",
    "kwwwwwwwwwwk",
    "kwwwwwVVVVVVVV",
    "kwwwwwVwwwwwwV",
    "kppppVVwVVVVwV",
    "kkkkkkVwwwwwwV",
    "...kpkVVVVVVVV",
    "...kk",
]))


def _net():
    L = Layer(15, 15)
    for y in range(15):
        for x in range(15):
            d = math.hypot((x - 9.5) / 4.6, (y - 4.5) / 4.1)
            if d <= 1.0:
                L.set(x, y, "white" if (x + y) % 2 == 0 else "grey")
    for y in range(15):
        for x in range(15):
            d = math.hypot((x - 9.5) / 4.6, (y - 4.5) / 4.1)
            if 0.82 <= d <= 1.12:
                L.set(x, y, "silver")
    for i in range(7):
        L.set(5 - i, 8 + i, "wood"); L.set(6 - i, 8 + i, "wood_dk") if i else None
    L.set(6, 8, "wood")
    outline_inplace(L)
    return L


SPINS["s05"] = ("ציד מכשפות", _net())                  # an empty butterfly net

SPINS["s06"] = ("כנף ציון", G([                        # a small white-and-blue jet, side view
    "",
    "",
    "",
    "...........kk",
    "..........kBk",
    ".........kBBk",
    ".kkkkkkkkkBBkk",
    "kwbwbwbwwwwwwk",
    "kwwwwwwwwwwwwwk",
    ".kBBBBBBBBBBBk",
    "..kkkkkkkkkkk",
    "....kwwwwk",
    ".....kkkk",
]))

SPINS["s07"] = ("סופר־ספרטה", G([                     # one finger in a gladiator helmet
    "....krrrrk",
    "...krhrrrrk",
    "...kkkkkkkk",
    "..kxxxxxxXk",
    "..kxkkkkkXk",
    "..kxkjeekXk",
    "..kxkeeekXk",
    "...kkeefkk",
    "....keefk",
    "....keefk",
    "...kkeefkk",
    "..keeeeeefk",
    "..keeeeeefk",
    "..kffffffk",
    "...kkkkkk",
]))

SPINS["s08"] = ("השלט", G([                            # a big TV remote with one oversized button
    "....kkkkkkk",
    "...kUuuuuuuk",
    "...kukkkkkuk",
    "...kkrrhrkuk",
    "...kkrhrrkdk",
    "...kkrrrrkuk",
    "...kukRRRkuk",
    "...kuuuuuuuk",
    "...kuwuwuwuk",
    "...kuuuuuuuk",
    "...kuwuwuwuk",
    "...kuuuuuuuk",
    "...kuuuuuudk",
    "...kddddddk",
    "....kkkkkk",
]))

SPINS["s09"] = ("פייג׳ר זהב", G([                     # a gold pager with a gift bow
    "....kk...kk",
    "...kPPk.kPPk",
    "...kPqPkPqPk",
    "....kkPPPkk",
    "..kkkkkPkkkkk",
    "..kYYYYYYYYYk",
    "..kyknnnnnkok",
    "..kykbbbbnkok",
    "..kyknnnnnkok",
    "..kyyyyyyyyok",
    "..kyyYyyYyyok",
    "..kooooooooOk",
    "...kkkkkkkkk",
]))

SPINS["s10"] = ("מזוודות כביסה", G([                 # a laundry bag with a luggage tag, a sock escaping
    "......kkk",
    ".....kpwpk..kk",
    "......kpk..klk",
    "....kkpwpkk.kgk",
    "...kwwwwwwwkkgk",
    "..kwwwwpwwwwkk",
    "..kwwpwwwwwpk",
    ".kwwwwwwwwwwpk",
    ".kwwwwwwwwwppkk",
    ".kwwwwwwwwwpkwk",
    ".kpwwwwwwwppkpk",
    "..kpwwwwwpppkk",
    "...kppppppk",
    "....kkkkkk",
]))

SPINS["s11"] = ("באגס באני", G([                     # the game's rabbit with a carrot microphone
    "..kk....kk",
    ".kgsk..kgsk",
    ".kgPk..kgPk",
    ".kgPk..kgsk",
    "..kgkkkkgk",
    ".kssssssssk",
    "kssissssissk",
    "ksssssPsssskGk",
    "kgsswwwwsssgkGk",
    ".kgssssssggkxk",
    "..kkgggggkkxXk",
    "...kssssskxXk",
    "...kgsssgkXk",
    "....kkkkkkk",
]))

# s12 "הוחלט להקים ועדה": no 15x15 grid. The old one (a table with three empty chairs) echoed a memorial
# symbol that design/redlines.json category `oct7-hostages` rules out (Bar, 2026-09-29: visual echoes
# included), and it no longer shipped after wave 5. The shipped icon is icons24.py's frozen binder. Never
# bring back empty chairs at a table.

SPINS["s13"] = ("ראיון בערוץ ידידותי", G([          # a studio couch with two mugs
    "",
    "",
    "",
    ".kkk.....kkk",
    "kwbwk...kwwwk",
    "kwbwkk..kwPwkk",
    "kwwwkwk.kwwwkwk",
    "kpppkk..kpppkk",
    ".kkkkkkkkkkkkkk",
    "kZZZZZZZZZZZZZk",
    "kZzzzzzzzzzzzZk",
    "kzkkkkkkkkkkkzk",
    "kzk.........kzk",
    "kkk.........kkk",
]))

SPINS["s14"] = ("סרטון ויראלי", G([                 # a phone with a play button and a huge counter
    "...kkkkkkkkk",
    "..knnnnnnnnnk",
    "..knwwwwwwwnk",
    "..knwwPwwwwnk",
    "..knwwPPwwwnk",
    "..knwwPPPwwnk",
    "..knwwPPwwwnk",
    "..knwwPwwwwnk",
    "..knwwwwwwwnk",
    "..knnnnnnnnnk",
    "..knYkYkYkYnk",
    "..knnnnnnnnnk",
    "..knnnnlnnnnk",
    "...kkkkkkkkk",
]))

SPINS["s15"] = ("ביקור ממלכתי", G([                  # two chairs and a cigar in an ashtray, no faces
    ".kkkk....kkkk",
    ".kWWk....kWWk",
    ".kWDk....kWDk",
    ".kWDk....kWDk",
    ".kWDkkk.kWWDk",
    ".kWWWWk.kWWWWk",
    ".kDDDDk.kDDDDk",
    ".kk.kk...kk.kk",
    "",
    "...kkkkkkkk",
    "..kssssXxwwgk",
    "..kglllllllgk",
    "...kkkkkkkkk",
]))


# ------------------------------------------------------------------ trophies (achievements[].icon)
TROPHY = {}

TROPHY["icon_folder"] = G([
    "",
    "kkkkkk",
    "kttttk",
    "kttttkkkkkkkkk",
    "kTTTTTTTTTTTTk",
    "kTwwwwwwwwwwwkk",
    "kkkkkkkkkkkkkTk",
    "kttttttttttttTk",
    "ktttVVVVtttttTk",
    "ktttVtttVttttTk",
    "ktttVVVVtttttTk",
    "kttttttttttttTk",
    "kTTTTTTTTTTTTTk",
    "kkkkkkkkkkkkkkk",
])
TROPHY["icon_hat"] = G([
    "",
    "....kkkkkkk",
    "....kdduddk",
    "....kdudddk",
    "....kdudddk",
    "....kdudddk",
    "....kFFFFFk",
    "....kBBBBBk",
    "....kdudddk",
    "..kkkkkkkkkkk",
    ".kdUUUUUUUUudk",
    "..kkkkkkkkkkk",
])
TROPHY["icon_rabbit"] = G([
    "..kk.....kk",
    ".kgsk...kgsk",
    ".kgPk...kgPk",
    ".kgPk...kgsk",
    ".kgsk...kgk",
    "..kgkkkkkgk",
    ".kssssssssk",
    "kssissssissk",
    "ksssssPsssssk",
    "ksssswwwsssgk",
    ".kgsssssssgk",
    "..kggggggggk",
    "...kkkkkkkk",
])
TROPHY["icon_suitcase"] = G([
    "",
    "",
    ".....kkkkk",
    ".....kgggk",
    ".....kk.kk",
    ".kkkkkkkkkkkkk",
    "kqqqqqqqqqqqqmk",
    "kqmMmmmmmmMmMMk",
    "kqmMwwwwwwMmMMk",
    "kqmMwiwiwwMmMMk",
    "kqmMwwwwwwMmMMk",
    "kmmMmmmmmmMmMMk",
    "kMMMMMMMMMMMMMk",
    ".kkkkkkkkkkkkk",
])
TROPHY["icon_ballot"] = G([
    "......kkkk",
    ".....kwwwwk",
    ".....kwwiwk",
    ".....kwiwwk",
    "..kkkkwwwwkkkk",
    ".kpppkkkkkkpppk",
    ".kpppppppppppk",
    "kkkkkkkkkkkkkkk",
    "kwwwwwwwwwwwwpk",
    "kbbbbbbbbbbbbBk",
    "kNNNNNNNNNNNNNk",
    "kwwwwwwwwwwwwpk",
    "kwwwwwwwwwwwwpk",
    "kpppppppppppppk",
    "kkkkkkkkkkkkkkk",
])
TROPHY["icon_clock"] = G([
    "....kkkkkk",
    "..kkwwwwwwkk",
    ".kwwwwiwwwwwk",
    ".kwwwwiwwwwwk",
    "kwwwwwiwwwwwwk",
    "kwiwwwiwwwwiwk",
    "kwwwwwiiiiwwwk",
    "kwwwwwwwwwwwwk",
    "kwwwwwwwwwwwpk",
    ".kwwwwiwwwwpk",
    ".kpwwwwwwwppk",
    "..kkppppppkk",
    "....kkkkkk",
])
TROPHY["icon_gavel"] = G([
    "..kkkkkkkk",
    ".ktWWWWWWDk",
    ".ktWWWWWWDk",
    ".kTDDDDDDDk",
    "..kkkkWkkk",
    "......kWk",
    "......kWDk",
    ".......kWDk",
    "........kWDk",
    ".........kWDk",
    "..........kWk",
    "..kkkkkkkkkkk",
    ".ktttttttttTk",
    ".kTTTTTTTTTTk",
    "..kkkkkkkkkk",
])
TROPHY["icon_stamp"] = G([
    ".....kkkk",
    "....kWWWDk",
    "....kWtWDk",
    "....kWWDDk",
    ".....kDDk",
    ".....kWDk",
    "...kkllllkk",
    "..kWWWWWWWDk",
    "..ktWWWWWWDk",
    "..kDDDDDDDDk",
    "..kKKKKKKKKk",
    "..kVVVVVVVVk",
    "...kkkkkkkk",
    "",
    ".kVVVVVVVVVVk",
])
TROPHY["icon_aide"] = G([                            # a generic aide: suit, earpiece coil, no face
    "....kkkkk",
    "...kKKKKKk",
    "...keeeeeKk",
    "...keeeeefk",
    "...keeeeefkk",
    "....keeefkwk",
    "....kkkkk.wk",
    "..kkuuwFuuwk",
    ".kuuuwwFwuukk",
    "kuUuuwFFwuuuk",
    "kuUuuuFFuuuuk",
    "kuUuuuwwuuudk",
    "kuUuuuuuuuudk",
    "kdddddddddddk",
])
TROPHY["icon_pin"] = G([
    "......kkk",
    ".....kvvvk",
    "....kvwvvvk",
    "....kvvvvVk",
    "....kvvvvVk",
    "...kkvvvVVkk",
    "..kvvvvvvVVVk",
    "..kVVVVVVVVVk",
    "...kkkkgkkkk",
    ".......g",
    ".......g",
    ".......g",
    ".......l",
])
TROPHY["icon_coin"] = G([                            # a shekel coin, the 5x9 cut's ₪ embossed
    "....kkkkkk",
    "..kkYYYYYYkk",
    ".kYYyyyyyyyok",
    ".kYyyyyyyyyok",
    "kYyyOOOyOyyyok",
    "kYyyOyOyOyyyok",
    "kYyyOyOyOyyyok",
    "kyyyOyOyOyyyok",
    "kyyyOyOOOyyyok",
    "kyyyyyyyyyyyok",
    ".kyyyyyyyyyook",
    ".koyyyyyyyoOk",
    "..kkooooookk",
    "....kkkkkk",
])
TROPHY["icon_phone"] = G([                           # the poison machine: a phone with a blank avatar and a heart
    "...kkkkkkkk",
    "..knnnnnnnnk",
    "..knlllllllnk",
    "..knlggglllnk",
    "..knlgggllrrk",
    "..knlllllrhrrk",
    "..knlggglrrrrk",
    "..knlllllkrrk",
    "..knllllllkk",
    "..knlggggglnk",
    "..knllllllllnk",
    "..knnnnnnnnnk",
    "..knnnnlnnnnk",
    "...kkkkkkkkk",
])
TROPHY["icon_plane"] = SPINS["s06"][1]
TROPHY["icon_wand"] = G([
    "..........k",
    ".....k...kYk",
    "..........k",
    "........kkk..k",
    ".......kwwk",
    "......kiwk",
    ".....kiik",
    "....kiik",
    "...kiik",
    "..kiik",
    ".kiik",
    "kiik....k",
    "kik....kYk",
    ".k......k",
])
TROPHY["icon_moon"] = G([                            # a crescent asleep: two z's rising right (wave 6: the
    "....kkkk...wwww",                                # star beside the crescent read as an emblem)
    "..kkwwwk.....w",
    ".kwwwkk.....w",
    ".kwwk......wwww",
    "kwwpk..www",
    "kwwpk....w",
    "kwwpk...w",
    "kwwppk.www",
    ".kwppkk....kk",
    ".kppppkkkkkpk",
    "..kTppppppTk",
    "...kkTTTTkk",
    ".....kkkk",
])
TROPHY["icon_parrot"] = G([                          # Dubi's head in profile: the hooked beak is the read
    "....kkkkk",
    "...kLLLLGk",
    "..kLLLLGGGk",
    ".kLLwwLGGGGk",
    ".kLwiwLGGGGkk",
    ".kLwwLGGGkXxxk",
    "kLLLLGGGkXxxxxk",
    "kGLGGGGGkXxkXxk",
    "kGGGGGGGGkkkXk",
    "kEGGGGGGGGk.kk",
    ".kEEGGGGGk",
    "..kkkkFkk",
    "....kFFFk",
    ".....kFk",
])


def _cottage_ghost():
    """'מדד הקוטג׳: 0' - the cup has lost every pixel: only a dotted ghost of its outline is left."""
    L = Layer(15, 15)
    pts = []
    for y in range(3, 14):
        hw = 6.0 - (y - 3) * 0.3
        pts += [(int(7 - hw), y), (int(7 + hw), y)]
    pts += [(x, 3) for x in range(1, 14)] + [(x, 13) for x in range(4, 11)]
    for k, (x, y) in enumerate(sorted(set(pts))):
        if (x + y) % 2 == 0:
            L.set(x, y, "grey")
    return L


TROPHY["icon_cottage"] = _cottage_ghost()


# ------------------------------------------------------------------ gear, sound on / off
def _gear():
    L = Layer(15, 15)
    cx = cy = 7
    for y in range(15):
        for x in range(15):
            d = math.hypot(x - cx, y - cy)
            a = (math.degrees(math.atan2(y - cy, x - cx)) + 360) % 45
            if d <= 5.2 or (d <= 7.2 and (a < 13 or a > 32)):
                L.set(x, y, "silver" if (x + y) < 14 else "grey")
    for y in range(15):
        for x in range(15):
            if math.hypot(x - cx, y - cy) <= 2.1:
                L.px[y][x] = None
    outline_inplace(L)
    return L


SPEAKER = [
    "",
    "....kk",
    "...kgk",
    "..kssk",
    "kkksgk",
    "ksssgk",
    "ksssgk",
    "ksssgk",
    "ksssgk",
    "kkksgk",
    "..kssk",
    "...kgk",
    "....kk",
]


def _speaker(on):
    L = G(SPEAKER)
    if on:
        for r, a0 in ((3.5, 55), (6.0, 50)):
            for a in range(-a0, a0 + 1, 4):
                x = 6 + r * math.cos(math.radians(a)); y = 7 + r * math.sin(math.radians(a))
                L.set(int(round(x)), int(round(y)), "white")
    else:
        for i in range(5):
            L.set(8 + i, 5 + i, "red_hi"); L.set(12 - i, 5 + i, "red_hi")
    return L


CONTROLS = {"icon_gear": _gear(), "icon_sound_on": _speaker(True), "icon_sound_off": _speaker(False)}
