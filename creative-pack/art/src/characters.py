"""The cast of 'Od Sevev', authored pixel by pixel.

Construction (the proportion lock, see style-guide.md §5):
  chibi = 24 x 32 art px incl. outline. Head fill 16x16 (18x18 outlined) sits on a
  22x14 body (24x16 outlined); the chin overlaps the collar by 2 rows.
  Face grid: eyes on cols 5 and 10, brows row 7, eyes rows 8-9, nose col 8 row 10,
  mouth row 12, chin row 14. Caricature lives ONLY in rows 0-6 (hair/headwear),
  the eye band (glasses) and rows 11-15 (beards, mouths) plus one costume/prop cue.
Traits are caricatured from the written trait list in the brief, never from photos.
"""
from pix import Layer, from_grid

CW, CH = 32, 36  # character cell (room for props and big hair)

# ----------------------------------------------------------------------------
# bodies (fill only; outline added at build). 22 wide x 14 tall.
# J jacket  j jacket shadow  Q jacket light  W shirt  T tie  t tie shadow
# H hand  h hand shadow  P trousers  p trousers shadow  B shoes
# ----------------------------------------------------------------------------
BODY_SUIT = [
    "......QJJWTTWJJj......",
    "....QQJJJWTTWJJJjj....",
    "..QQQjJJJWTTWJJJjJJj..",
    "..QQQjJJJJTTJJJJjJJj..",
    "..QQQjJJJJTTJJJJjJJj..",
    "..QQQjJJJJTTJJJJjJJj..",
    "..QQQjJJJJtTJJJJjJJj..",
    "..QQQjJJJJJJJJJJjJJj..",
    "..HHhjJJJJJJJJJJjHHh..",
    "..HHh.jJJJJJJJJj.HHh..",
    "......PPPp..PPPp......",
    "......PPPp..PPPp......",
    "......PPPp..PPPp......",
    ".....BBBBB..BBBBB.....",
]

BODY_HEAVY = [
    ".......QJJWTTWJJj.......",
    ".....QQJJJWTTWJJJjj.....",
    "...QQQQJJJWTTWJJJJjjj...",
    "..QQQjJJJJJTTJJJJJjJJj..",
    "..QQQjJJJJJTTJJJJJjJJj..",
    "..QQQjJJJJJTTJJJJJjJJj..",
    "..QQQjJJJJJtTJJJJJjJJj..",
    "..QQQjJJJJJJJJJJJJjJJj..",
    "..HHhjJJJJJJJJJJJJjHHh..",
    "..HHh.jJJJJJJJJJJj.HHh..",
    ".......PPPp..PPPp.......",
    ".......PPPp..PPPp.......",
    ".......PPPp..PPPp.......",
    "......BBBBB..BBBBB......",
]

BODY_SKIRT = [
    "......QJJWTTWJJj......",
    "....QQJJJWTTWJJJjj....",
    "..QQQjJJJWTTWJJJjJJj..",
    "..QQQjJJJJTTJJJJjJJj..",
    "..QQQjJJJJTTJJJJjJJj..",
    "..QQQjJJJJJJJJJJjJJj..",
    "..QQQjJJJJJJJJJJjJJj..",
    "..QQQjJJJJJJJJJJjJJj..",
    "..HHhjJJJJJJJJJJjHHh..",
    "..HHh.PPPPPPPPPp.HHh..",
    ".....PPPPPPPPPPpp.....",
    ".......HH....Hh.......",
    ".......HH....Hh.......",
    "......BBB....BBB......",
]

BODY_TEE = [
    "......QJJJWWJJJj......",
    "....QQJJJJJJJJJJjj....",
    "..QQQjJJJJJJJJJJjJJj..",
    "..HHhjJJJJJJJJJJjHHh..",
    "..HHhjJJJJJJJJJJjHHh..",
    "..HHhjJJJJJJJJJJjHHh..",
    "..HHhjJJJJJJJJJJjHHh..",
    "..HHhjJJJJJJJJJJjHHh..",
    "..HHhjJJJJJJJJJJjHHh..",
    "......TTTTTTTTTt......",
    "......PPPp..PPPp......",
    "......PPPp..PPPp......",
    "......PPPp..PPPp......",
    ".....BBBBB..BBBBB.....",
]

BODY_HOODIE = [
    ".....QQJJJJJJJJjj.....",
    "....QQJJJWJJWJJJjj....",
    "..QQQjJJJWJJWJJJjJJj..",
    "..QQQjJJJWJJWJJJjJJj..",
    "..QQQjJJJJJJJJJJjJJj..",
    "..QQQjJJTTTTTTJJjJJj..",
    "..QQQjJJTjjjjTJJjJJj..",
    "..QQQjJJJJJJJJJJjJJj..",
    "..HHhjJJJJJJJJJJjHHh..",
    "..HHh.jJJJJJJJJj.HHh..",
    "......PPPp..PPPp......",
    "......PPPp..PPPp......",
    "......PPPp..PPPp......",
    ".....BBBBB..BBBBB.....",
]

BODIES = {"suit": BODY_SUIT, "heavy": BODY_HEAVY, "skirt": BODY_SKIRT,
          "tee": BODY_TEE, "hoodie": BODY_HOODIE}


def suit_legend(jacket="suit", jacket_sh="suit_dk", jacket_hi="suit_hi", shirt="white",
                tie="flag", tie_sh="navy", hand="skin", hand_sh="skin_sh",
                trousers=None, trousers_sh=None, shoes="ink"):
    return {"J": jacket, "j": jacket_sh, "Q": jacket_hi, "W": shirt, "T": tie, "t": tie_sh,
            "H": hand, "h": hand_sh, "P": trousers or jacket_sh, "p": trousers_sh or "ink",
            "B": shoes}


# ----------------------------------------------------------------------------
# heads (fill only). K skin  k skin shadow  L skin light  n nose  m mouth  e eye
# ----------------------------------------------------------------------------
FACE = {"K": "skin", "k": "skin_sh", "L": "skin_hi", "n": "skin_sh", "m": "skin_dk",
        "e": "ink", "W": "white", "C": "pink"}

HEADS = {}

HEADS["sara"] = (dict(FACE, H="blonde", h="blonde_sh", I="white", b="blonde_sh", m="pink_sh"), 14, [
    "....HHHIHHH.....",
    "..HHHIIHHHHHh...",
    ".HHHIHHHHHHHhh..",
    "HHHIHHHHHHHHhhh.",
    "HHIHHHHHHKKKhhhh",
    "HHHHHHHKKKKKKhhh",
    "HHHHHKKKKKKKKkhh",
    "HHHHKbbKKKbbKkhh",
    "HHHKKeKKKKeKKkhh",
    "HHHKKeKKKKeKKkhh",
    "HHHKKKKKnKKKKkhh",
    "HHHKKCKKKKKCkkhh",
    "HHHhKKKmmmKKkhhh",
    "HHhh.KKKKKKk.hhh",
    "HHhh..kkkkk..hhh",
    ".hh...........h.",
])

HEADS["bengvir"] = (dict(FACE, Y="white", y="slate", H="hair_dk", h="hair_br", b="hair_dk",
                         G="ink", g="silver", s="grey"), 14, [
    "................",
    "......YYYY......",
    "....YyYYyYYY....",
    "...HYyYYYYyYH...",
    "..HHHHHHHHHHHH..",
    "..HhKKKKKKKKHH..",
    ".HKKKKKKKKKKKKh.",
    ".KKKbbKKKKbbKkk.",
    ".KKGGGGKKGGGGkk.",
    "KKGGgeGGGGegGGkk",
    "KKKGgeGKKGegGkkk",
    ".KKGGGGKnGGGGkk.",
    ".KsKsKKKKKsKskk.",
    "..sKsmmmmmKsk...",
    "...sKsKsKsKs....",
    ".....sssss......",
])

HEADS["smotrich"] = (dict(FACE, Y="navy", y="sky", H="hair_dk", h="hair_br", b="hair_dk",
                          D="hair_dk", d="hair_br", m="pink_sh"), 15, [
    "................",
    "................",
    ".....YyYyYY.....",
    "...HHYYYYYYHH...",
    "..HhHHHHHHHHHH..",
    "..HhhKKKKKKhHH..",
    ".HHKKKKKKKKKKHh.",
    ".HKKbbKKKKbbKkk.",
    "KKKKKeKKKKeKKkkk",
    "KKKKKeKKKKeKKkkk",
    "KdKKKKKKnKKKKkDk",
    ".ddKKKKKKKKKKDD.",
    ".dddDKmmmmKDDDD.",
    "..ddDDDDDDDDDD..",
    "...dDDDDDDDDD...",
    ".....DDDDDD.....",
])

HEADS["deri"] = (dict(FACE, Y="hair_dk", G="grey", g="slate", b="grey", D="grey", d="slate",
                      m="skin_dk"), 15, [
    "................",
    "................",
    ".....YYYYY......",
    "...KLYYYYYKK....",
    "..KLLKKKKKKKKk..",
    "..GKLKKKKKKKkG..",
    ".GGKKKKKKKKKKGg.",
    ".GKKbbKKKKbbKkg.",
    "KGKKKeKKKKeKKkgk",
    "KGKKKeKKKKeKKkgk",
    "KKKKKKKKnKKKKkkk",
    ".DKKKKKKKKKKKkd.",
    ".DDKKKmmmmKKkdd.",
    "..DDDDDDDDDDdd..",
    "...DDDDDDDDdd...",
    ".....DDDDdd.....",
])

HEADS["gafni"] = (dict(FACE, Y="hair_dk", G="grey", g="slate", b="grey", D="grey", d="slate",
                       O="ink", o="silver"), 15, [
    "................",
    ".....YYYYYY.....",
    "....YYYYYYYY....",
    "...GYYYYYYYYG...",
    "..GGKKKKKKKKGG..",
    "..GKKKKKKKKKKGg.",
    ".GKKKKKKKKKKKKg.",
    ".GKKbbKKKKbbKkg.",
    ".KKKOOKKKKOOKkk.",
    "KKKOoeOOOOeoOkkk",
    "KKKKOOKKnKOOKkkk",
    ".DKKKKKKKKKKKkd.",
    ".DDKKKmmmmKKkdd.",
    ".DDDDDDDDDDDDdd.",
    ".DDDDDDDDDDDDdd.",
    "..DDDDDDDDDDDd..",
    "..DDDDDDDDDDdd..",
    "...DDDDDDDDdd...",
    "....DDDDDDdd....",
    ".....DDDDdd.....",
])

HEADS["lapid"] = (dict(FACE, I="white", G="silver", g="grey", b="suit_dk"), 16, [
    "....IIII........",
    "...IIIIIII......",
    "..IIIGGGGGG.....",
    "..IIGGGGGGGGg...",
    "..IGGGGGGGGGGg..",
    "..GGGGGGGGGGgg..",
    "..GGGGGGGGGGGgg.",
    "..GGKKKKKKKKGgg.",
    ".GKKKKKKKKKKKKg.",
    ".KKKbbKKKKbbKkk.",
    "KKKKKeKKKKeKKkkk",
    "KKKKKeKKKKeKKkkk",
    "KKKKKKKKnKKKKkkk",
    ".KKKKKKKKKKKKkk.",
    ".KKKKmWWWmKKKkk.",
    "..KKKKmmmKKKkk..",
    "....KKKKKKkk....",
    "................",
])

HEADS["bennett"] = (dict(FACE, Y="hair_dk", y="slate", H="hair_dk", h="hair_br", b="hair_dk"), 15, [
    "................",
    "................",
    ".......YY.......",
    "....KLYyYYKK....",
    "...KLLLKKKKKk...",
    "..KLLKKKKKKKKk..",
    ".HHKKKKKKKKKKHH.",
    ".HKKbbKKKKbbKkh.",
    "KHKKKeKKKKeKKkhk",
    "KKKKKeKKKKeKKkkk",
    "KKKCKKKKnKKKCkkk",
    ".KKKKKKKKKKKKkk.",
    ".KKKmKKKKKKmKkk.",
    "..KKKmmmmmmKkk..",
    "...KKKKKKKKkk...",
    ".....kkkkkk.....",
])

HEADS["liberman"] = (dict(FACE, G="grey", g="slate", b="grey", D="grey", d="slate"), 15, [
    "................",
    "................",
    ".....KKKKKK.....",
    "...KKLLKKKKKK...",
    "..KKLLKKKKKKKk..",
    "..KKLKKKKKKKKk..",
    ".GKKKKKKKKKKKkG.",
    ".GKbbbKKKKbbbkG.",
    "GGKKKkKKKKkKKkGg",
    "KGKKKeKKKKeKKkgk",
    "KKKKKKKKnKKKKkkk",
    ".KKKKKKKKKKKKkk.",
    ".KKKKKmmmmKKKkk.",
    "..KKKKDDDDKKkk..",
    "....KKDDDdkk....",
    "......DDdd......",
])

HEADS["eisenkot"] = (dict(FACE, g="grey", S="skin_sh", b="slate"), 14, [
    "................",
    "................",
    ".....gSgSgS.....",
    "...gSgSgSgSgS...",
    "..gSgSgSgSgSgS..",
    "..SKKKKKKKKKKg..",
    ".gKKKKKKKKKKKKS.",
    ".KKbbbKKKKbbbkk.",
    "KKKKKeKKKKeKKkkk",
    "KKKKKeKKKKeKKkkk",
    "KKKKKKKKnKKKKkkk",
    ".KKKKKKKKKKKKkk.",
    ".KKKKmKKKKmKKkk.",
    "..KKKKmmmmKKkk..",
    "....KKKKKKkk....",
    "................",
])

HEADS["gotliv"] = (dict(FACE, H="hair_br", h="hair_dk", b="hair_dk", M="red", W="white"), 15, [
    "......HHhHHHHhH.......",
    "...HHHHHHHHHHHHHHh....",
    "..HHhHHHHHHHHHHHHhh...",
    ".HHHHHHHHHHHHHHHHHhh..",
    "HHHHHHHHHHHHHHHHHHHhh.",
    "HHHHHHKKKKKKKKKKHHHhhh",
    "HHHHHKKKKKKKKKKKKHHhhh",
    "HHHHKKbbKKKKKKbbKKHhhh",
    "HHHHKKKKbKKKKbKKKKHhhh",
    "HHHHKKKKeKKKKeKKKkHhhh",
    "HHHHKKKKeKKKKeKKKkHhhh",
    "HHHHKKKKKKKnKKKKKkhhh.",
    "HHHHHKKKKmmmmKKKkkhhh.",
    "HHHHHKKKmWWWWmKKkhhh..",
    "HHHHH.KKmMMMMmKkkhh...",
    "HHHH...KKmmmmKkk.hh...",
    ".HH......kkkkk........",
])

HEADS["levin"] = (dict(FACE, b="hair_dk", S="skin_sh"), 14, [
    "................",
    "................",
    ".....KKKKKK.....",
    "...KKLLKKKKKK...",
    "..KKLLKKKKKKKk..",
    "..KKLKKKKKKKKk..",
    ".KKKKKKKKKKKKkk.",
    ".KKbbbKKKKbbbkk.",
    "KKKKKeKKKKeKKkkk",
    "KKKKKeKKKKeKKkkk",
    "KKKKKKKKnKKKKkkk",
    ".KSKKKKKKKKKSkk.",
    ".KSKKmmmmmKKSkk.",
    "..SKSKSKSKSKSk..",
    "....SKSKSKSk....",
    "................",
])

HEADS["regev"] = (dict(FACE, H="hair_dk", h="hair_br", b="hair_dk", O="silver", r="red"), 14, [
    "................",
    ".....hHHHHH.....",
    "...hhHHHHHHHH...",
    "..hHHHHHHHHHHH..",
    ".hHHHHHHHHHHHHH.",
    ".hHHKKKKKKKKHHH.",
    "hHHKKKKKKKKKKHHH",
    "hHKKbbKKKKbbKKHH",
    "hHKKKeKKKKeKKKHH",
    "hHKKKeKKKKeKKkHH",
    "hHKKKKKKnKKKKkHH",
    "hHOKKKKKKKKKKkOH",
    "hHOKKKrrrrKKkkOH",
    "hH..KKKKKKKk..HH",
    ".H....kkkkk...H.",
    "................",
])

HEADS["gantz"] = (dict(FACE, I="white", G="silver", g="grey", b="grey", e="navy"), 14, [
    "................",
    "................",
    ".....GGGGGG.....",
    "...IIIgGGGGGG...",
    "..IIIIgGGGGGGg..",
    "..GGKKKKKKKGGg..",
    ".GKKKKKKKKKKKKg.",
    ".KKKbbKKKKbbKkk.",
    "KKKKKeKKKKeKKkkk",
    "KKKKKeKKKKeKKkkk",
    "KKKKKKKKnKKKKkkk",
    ".KKKKKKKKKKKKkk.",
    ".KKKKKmmmmKKKkk.",
    "..KKKKKKKKKKkk..",
    "....KKKKKKkk....",
    "................",
])

HEADS["golan"] = (dict(FACE, G="grey", g="slate", b="grey", O="suit_dk", o="silver"), 14, [
    "................",
    "................",
    ".....KKKKKK.....",
    "...GGKLKKKGG....",
    "..GGGGKKKGGGGg..",
    "..GGKKKKKKKGGg..",
    ".GKKKKKKKKKKKKg.",
    ".KKKbbKKKKbbKkk.",
    "KKOOOOOOOOOOOkkk",
    "KKOoeOKKKOeoOkkk",
    "KKOOOOKKnOOOOkkk",
    ".KKKKKKKKKKKKkk.",
    ".KKKKKmmmmKKKkk.",
    "..KKKKKKKKKKkk..",
    "....KKKKKKkk....",
    "................",
])

HEADS["taxpayer"] = (dict(FACE, H="hair_br", h="hair_dk", b="hair_dk", S="skin_sh"), 14, [
    "................",
    "....H.HH.H......",
    "...HHHHHHHHH....",
    "..HHHHHHHHHHHh..",
    "..HHHHHHHHHHHhh.",
    "..HHKKHKKKKHHhh.",
    ".HHKKKKKKKKKKKh.",
    ".KKKbbKKKKbbKkk.",
    "KKKKKeKKKKeKKkkk",
    "KKKKSSKKKKSSKkkk",
    "KKKKKKKKnKKKKkkk",
    ".KKKKKKKKKKKKkk.",
    ".KKKKKmmmmKKKkk.",
    "..KKKmKKKKmKkk..",
    "....KKKKKKkk....",
    "................",
])

HEADS["hightech"] = (dict(FACE, H="hair_dk", h="hair_br", b="hair_dk", O="ink", o="suit"), 14, [
    "................",
    "....OOOOOOOO....",
    "...OHhHhHHhHO...",
    "..OHHhHHhHHHHO..",
    "..OHHHHHHHHHHO..",
    "..OHKKKKKKKKHO..",
    ".oOKKKKKKKKKKOo.",
    ".ooKbbKKKKbbKoo.",
    ".ooKKKKeKKKKeoo.",
    ".ooKKKKeKKKKeoo.",
    "KKKKKKKKnKKKKkkk",
    ".KKKKKKKKKKKKkk.",
    ".KKKKKKmmmmKKkk.",
    "..KKKKKKKKKKkk..",
    "....KKKKKKkk....",
    "................",
])

HEADS["greyshirt"] = (dict(FACE, H="hair_dk", h="hair_br", b="hair_dk"), 14, [
    "................",
    "................",
    ".....HHHHHH.....",
    "...HHHHHHHHHH...",
    "..HHHHHHHHHHHh..",
    "..HHKKKKKKKKHh..",
    ".HKKKKKKKKKKKKh.",
    ".KKKbbKKKKbbKkk.",
    "KKKKKeKKKKeKKkkk",
    "KKKKKeKKKKeKKkkk",
    "KKKKKKKKnKKKKkkk",
    ".KKKKKKKKKKKKkk.",
    ".KKKKKKmmmKKKkk.",
    "..KKKKKKKKKKkk..",
    "....KKKKKKkk....",
    "................",
])

HEADS["whiteglasses"] = (dict(FACE, H="hair_dk", h="hair_br", b="hair_dk", O="white", o="ink"), 14, [
    "................",
    "................",
    ".....HHHHHH.....",
    "...HhHHHHHHHH...",
    "..HhhHHHHHHHHh..",
    "..HHKKKKKKKKHh..",
    ".HKKKKKKKKKKKKh.",
    ".KKKKKKKKKKKKkk.",
    "OOOOOOOOOOOOOOOO",
    "KOooooOOOOooooOk",
    "KOooooOKKOooooOk",
    ".KOOOOKKKKOOOOk.",
    ".KKKKKmmmmKKKkk.",
    "..KKKKKKKKKKkk..",
    "....KKKKKKkk....",
    "................",
])

HEADS["dubi"] = ({"G": "green", "g": "green_sh", "L": "lime", "B": "orange", "b": "orange_sh",
                  "e": "ink", "W": "white"}, 14, [
    "......LLL.......",
    ".....LLGL.......",
    "....LLGGGG......",
    "...LLGGGGGGG....",
    "..LLGGGGGGGGg...",
    "..LGGGGGGWWWgg..",
    ".LGGGGGGWWeWWgg.",
    ".GGGGGGGWWeWWgg.",
    ".GGGGGGGGWWWBBB.",
    ".GGGGGGGGGBBBBBB",
    ".gGGGGGGGGBBBBbB",
    "..gGGGGGGGGBBbbB",
    "..ggGGGGGGGGbb.b",
    "...gggGGGGGg..b.",
    ".....ggggggg....",
    "................",
])

import bibi as _bibi
HEADS["bibi"] = (_bibi.LEG, 13, _bibi.CHIBI_V2)

# name -> (head key, body key, body legend, props)
CAST = {
    "sara":     ("sara", "skirt", suit_legend("pink", "pink_sh", "pink", shirt="white", tie="white",
                                              trousers="pink", trousers_sh="pink_sh", hand="skin")),
    "bengvir":  ("bengvir", "suit", suit_legend(tie="slate", tie_sh="suit_dk", shirt="white")),
    "smotrich": ("smotrich", "suit", suit_legend(tie="red", tie_sh="maroon_dk")),
    "deri":     ("deri", "suit", suit_legend(tie="suit_dk", tie_sh="ink")),
    "gafni":    ("gafni", "suit", suit_legend("suit_dk", "night", "suit", tie="night", tie_sh="ink")),
    "levin":    ("levin", "suit", suit_legend(tie="slate", tie_sh="suit_dk")),
    "regev":    ("regev", "skirt", suit_legend("sky", "flag_hi", "sky", shirt="white", tie="white",
                                               trousers="sky", trousers_sh="flag_hi")),
    "gotliv":   ("gotliv", "suit", suit_legend("orange", "orange_sh", "orange", shirt="pink", tie="pink",
                                               tie_sh="pink_sh", trousers="suit", trousers_sh="suit_dk")),
    "lapid":    ("lapid", "suit", suit_legend("night", "ink", "suit_dk", shirt="suit_dk", tie="night",
                                              tie_sh="ink", trousers="night")),
    "bennett":  ("bennett", "suit", suit_legend("navy", "night", "flag_hi", tie="suit_hi", tie_sh="suit")),
    "liberman": ("liberman", "heavy", suit_legend(tie="slate", tie_sh="suit_dk")),
    "eisenkot": ("eisenkot", "suit", suit_legend(tie="white", tie_sh="paper")),
    "gantz":    ("gantz", "suit", suit_legend(tie="slate", tie_sh="suit_dk")),
    "golan":    ("golan", "tee", suit_legend("white", "paper", "white", tie="suit_dk", trousers="suit",
                                             trousers_sh="suit_dk")),
    "taxpayer": ("taxpayer", "suit", suit_legend("sky", "flag_hi", "white", shirt="white", tie="white",
                                                 trousers="slate", trousers_sh="suit")),
    "hightech": ("hightech", "hoodie", suit_legend("green_sh", "teal_dk", "green", shirt="white",
                                                   tie="green", trousers="navy", trousers_sh="night")),
    "greyshirt": ("greyshirt", "tee", suit_legend("slate", "suit", "grey", tie="navy", trousers="navy",
                                                  trousers_sh="night")),
    "whiteglasses": ("whiteglasses", "suit", suit_legend("white", "paper", "white", shirt="white",
                                                         tie="white", tie_sh="paper", trousers="white",
                                                         trousers_sh="paper", shoes="white")),
    "dubi":     ("dubi", "suit", suit_legend(tie="flag", hand="green", hand_sh="green_sh")),
    "bibi":     ("bibi", "suit", suit_legend("navy", "night", "navy_hi", tie="flag", tie_sh="flag_hi",
                                             trousers="navy", trousers_sh="night")),
}


def _head(key):
    legend, chin, rows = HEADS[key]
    return from_grid(rows, legend), chin


def build(name):
    """Compose a chibi: body (outlined) + head (outlined) + per-character edits/props."""
    head_key, body_key, bleg = CAST[name]
    body = from_grid(BODIES[body_key], bleg)
    # per-character body edits (before outline)
    if name == "eisenkot":           # open collar, no tie: skin V at the neck, jacket below
        for y in range(0, 2):
            body.set(10, y, "skin"); body.set(11, y, "skin_sh")
        for y in range(3, 8):
            body.set(10, y, "suit"); body.set(11, y, "suit")
    if name == "lapid":              # black on black: a single grey lapel edge keeps the V legible
        for y in range(0, 3):
            body.set(8, y + 1, "suit"); body.set(13, y + 1, "suit")
    if name == "taxpayer":           # turned-out empty pockets
        body.set(5, 10, "white"); body.set(6, 10, "white"); body.set(15, 10, "white"); body.set(16, 10, "white")
        body.set(5, 11, "paper"); body.set(16, 11, "paper")
    if name == "golan":              # rolled sleeves on a plain white shirt
        for x in (2, 3, 4, 17, 18, 19):
            body.set(x, 3, "paper")
    if name == "bennett":            # the TV pledge: a signed sheet in hand
        pass
    if name == "gantz":              # taller: +2 leg rows
        rows = BODIES["suit"][:10] + [BODIES["suit"][10]] * 5 + [BODIES["suit"][13]]
        body = from_grid(rows, bleg)
    body = body.outlined()
    head, chin = _head(head_key)
    head = head.outlined()

    L = Layer(CW, CH)
    by = CH - body.h
    bx = (CW - body.w) // 2
    L.paste(body, bx, by)
    hx = (CW - head.w) // 2
    hy = by - chin + 1
    L.paste(head, hx, hy)
    _props(L, name, bx, by)
    return L


def _prop(L, rows, legend, x, y):
    p = from_grid(rows, legend).outlined()
    L.paste(p, x - 1, y - 1)


def _props(L, name, bx, by):
    lx, rx, hy = bx + 3, bx + 18, by + 9  # left-hand x, right-hand x, hand row
    if name == "levin":        # gavel
        _prop(L, ["WWWW", "WWWW", ".d..", ".d..", ".d.."], {"W": "wood", "d": "wood_dk"}, rx - 1, hy - 5)
    if name == "gantz":        # the rotation that never came: an hourglass, all sand still on top
        _prop(L, ["www", "ggg", ".g.", "w.w", "www"], {"w": "wood", "g": "gold_hi"}, rx, hy - 4)
    if name == "bennett":      # the signed TV pledge
        _prop(L, ["WWW", "WkW", "WWW", "WkW"], {"W": "white", "k": "slate"}, rx, hy - 3)
    if name == "hightech":     # laptop under the arm
        _prop(L, ["SSSSS", "SsssS", "SSSSS"], {"S": "silver", "s": "slate"}, lx - 4, hy - 2)
    if name == "dubi":         # microphone
        _prop(L, ["gg", "gg", "i.", "i."], {"g": "silver", "i": "suit_dk"}, rx + 1, hy - 4)
    if name == "taxpayer":     # sweat drop
        L.set(bx + 17, by - 9, "sky"); L.set(bx + 17, by - 8, "sky")


# ----------------------------------------------------------------------------
# non-chibi originals
# ----------------------------------------------------------------------------
def rabbit():
    """Original design: a round, grey, smug loaf of a rabbit. One ear up, one folded.
    No white muzzle, no gloves, no buck teeth, no lanky pose: deliberately not Bugs."""
    L = Layer(26, 28)
    L.ellipse(12, 20, 8, 6, "grey")           # body loaf
    L.ellipse(11, 12, 7, 5.5, "grey")         # head
    for (cx, cy, rx, ry) in [(12, 20, 8, 6)]:
        for y in range(28):
            for x in range(26):
                if L.get(x, y) == "grey" and ((x - cx) > rx * 0.45 and y > 14):
                    L.set(x, y, "slate")
    # head shade on right
    for y in range(6, 18):
        for x in range(15, 19):
            if L.get(x, y) == "grey":
                L.set(x, y, "slate")
    L.ellipse(10, 21, 3.5, 3, "silver")       # belly
    # upright ear (left)
    L.rect(6, 0, 3, 8, "grey"); L.vline(7, 1, 6, "pink"); L.set(6, 0, None); L.set(8, 0, None)
    # folded ear (right): goes up then flops right
    L.rect(13, 3, 3, 4, "grey"); L.rect(14, 2, 6, 2, "grey"); L.hline(15, 18, 3, "pink_sh")
    L.set(20, 3, "grey"); L.set(19, 2, None)
    # face: half-lidded smug eyes
    L.hline(7, 9, 11, "slate"); L.hline(7, 9, 12, "ink"); L.set(9, 12, "white")
    L.hline(13, 15, 11, "slate"); L.hline(13, 15, 12, "ink"); L.set(15, 12, "white")
    L.set(11, 14, "pink"); L.set(10, 15, "suit"); L.set(12, 15, "suit"); L.set(11, 15, "suit")
    L.set(6, 14, "pink"); L.set(16, 14, "pink")   # cheeks
    # feet
    L.ellipse(7, 25, 2, 1, "silver"); L.ellipse(15, 25, 2, 1, "silver")
    # carrot held up like a trophy (right paw): 9px long, 3px thick at the root
    carrot = [
        "......VV.V",
        ".......VVV",
        "......OOV.",
        ".....OOOo.",
        "....OOOo..",
        "...OOOo...",
        "..OOOo....",
        ".OOo......",
        ".Oo.......",
        "o.........",
    ]
    L.grid(15, 8, carrot, {"O": "orange", "o": "orange_sh", "V": "green"})
    L.ellipse(18, 15, 1.5, 1.5, "grey"); L.set(19, 15, "slate")       # paw gripping it
    return L.outlined()


MICRO = {  # 3x5 Latin for the sticker only
    "D": ["##.", "#.#", "#.#", "#.#", "##."], "O": [".#.", "#.#", "#.#", "#.#", ".#."],
    "H": ["#.#", "#.#", "###", "#.#", "#.#"], "A": [".#.", "#.#", "###", "#.#", "#.#"],
    "B": ["##.", "#.#", "##.", "#.#", "##."], "C": [".##", "#..", "#..", "#..", ".##"],
}


def suitcase():
    L = Layer(28, 20)
    # handle
    L.rect(10, 0, 8, 1, "slate"); L.vline(10, 0, 3, "slate"); L.vline(17, 0, 3, "slate")
    L.hline(11, 16, 1, None)
    # body
    L.rect(1, 3, 26, 16, "maroon")
    for p in [(1, 3), (26, 3), (1, 18), (26, 18)]:
        L.set(*p, None)
    L.rect(22, 4, 4, 14, "maroon_dk"); L.rect(2, 16, 24, 2, "maroon_dk")
    L.hline(2, 21, 4, "pink_sh")                     # top light edge (the only warm light)
    L.vline(8, 4, 17, "maroon_dk"); L.vline(19, 4, 17, "maroon_dk")   # straps
    # corner guards
    for (x, y) in [(2, 4), (24, 4), (2, 16), (24, 16)]:
        L.rect(x, y, 2, 2, "slate")
    # DOHA sticker: white label, 4 glyphs x 3px + 1px gaps = 15px text on a 17px label
    L.rect(6, 8, 17, 7, "white"); L.hline(6, 22, 14, "paper"); L.vline(22, 8, 14, "paper")
    x = 7
    for ch in "DOHA":
        for j, row in enumerate(MICRO[ch]):
            for i, c in enumerate(row):
                if c == "#":
                    L.set(x + i, 9 + j, "ink")
        x += 4
    # luggage tag
    L.set(3, 2, "paper"); L.rect(2, 0, 3, 2, "paper")
    # CATCH RIM: catchables get a 1px white ring outside the ink outline (maroon is only
    # 1.3-1.6:1 against the night/plum/teal eras; the rim takes the edge to >= 8:1)
    return L.outlined().outlined("white")


def magician():
    """The Magician, 48x64 fill. Key pose 'the lecture trick': the upside-down top hat spins
    on his raised LECTURING INDEX FINGER (his signature gesture); shekels and ballot slips
    leap out of it; the other hand holds the wand. The hat is OFF his head on purpose:
    the swept-back silver wave is his #1 recognition anchor (see bibi.py)."""
    L = Layer(48, 64)
    # legs & shoes
    L.rect(15, 56, 6, 5, "suit_dk"); L.rect(25, 56, 6, 5, "suit_dk")
    L.vline(20, 56, 60, "ink"); L.vline(30, 56, 60, "ink")
    L.rect(13, 61, 8, 3, "ink"); L.rect(25, 61, 8, 3, "ink")
    L.hline(14, 17, 61, "suit")
    # torso
    L.ellipse(22.5, 50, 13, 8, "suit")
    L.rect(10, 49, 26, 8, "suit")
    for y in range(40, 58):
        for x in range(27, 38):
            if L.get(x, y) == "suit":
                L.set(x, y, "suit_dk")
        for x in range(9, 14):
            if L.get(x, y) == "suit":
                L.set(x, y, "suit_hi")
    for y in range(43, 52):                               # shirt V
        w = max(0, 3 - (y - 43) // 2)
        L.hline(22 - w, 23 + w, y, "white")
    L.rect(22, 43, 2, 2, "flag")                          # tie knot
    for y in range(45, 56):
        L.hline(22, 23, y, "flag"); L.set(23, y, "navy")
    L.set(22, 45, "flag_hi"); L.set(22, 46, "flag_hi")
    for y in range(43, 51):                               # lapels
        L.set(19 - (y - 43) // 3, y, "suit_hi")
        L.set(26 + (y - 43) // 3, y, "suit_dk")
    L.rect(29, 47, 3, 1, "flag"); L.rect(29, 48, 3, 1, "white"); L.rect(29, 49, 3, 1, "flag")  # flag pin
    L.set(21, 54, "suit_dk")
    # wand arm (screen left)
    L.rect(6, 46, 6, 8, "suit_hi"); L.vline(11, 46, 53, "suit")
    L.rect(5, 53, 6, 2, "white")                          # cuff
    L.rect(4, 55, 6, 4, "skin"); L.hline(4, 9, 58, "skin_sh"); L.set(9, 56, "skin_sh")
    L.line(5, 55, 0, 45, "ink"); L.line(6, 55, 1, 45, "ink")
    L.rect(0, 43, 2, 2, "white")
    # lecture arm (screen right): up to a fist with the index finger raised
    for i in range(22):
        y = 47 - i
        x = 31 + (i * 6) // 22
        L.rect(x, y, 5, 1, "suit_dk" if i < 7 else "suit")
        L.set(x, y, "suit_hi")
    L.rect(36, 24, 6, 2, "white")                         # cuff
    L.rect(36, 19, 6, 5, "skin"); L.vline(41, 19, 23, "skin_sh"); L.hline(36, 41, 23, "skin_sh")
    L.hline(37, 40, 19, "skin_hi"); L.set(36, 21, "skin_sh"); L.set(38, 21, "skin_sh")   # curled fingers
    L.rect(38, 15, 2, 4, "skin"); L.vline(39, 15, 18, "skin_sh"); L.set(38, 15, "skin_hi")  # THE finger
    # the hat, upside down, spinning on the fingertip, opening up
    L.rect(33, 6, 13, 9, "ink")
    L.rect(34, 7, 2, 7, "suit_dk"); L.vline(35, 7, 13, "suit")
    L.rect(33, 6, 13, 2, "flag"); L.hline(33, 45, 6, "flag_hi")
    L.ellipse(39, 4.5, 8, 1.6, "suit")                    # brim top surface
    L.ellipse(39, 4.5, 5, 0.7, "ink")                     # the opening
    L.hline(31, 35, 3, "suit_hi")
    for (x, y) in [(31, 12), (32, 13), (33, 15), (47, 10), (46, 11)]:   # spin ticks
        L.set(x, y, "silver")
    return L


def magician_full(pose="tap"):
    """The v2 likeness (bibi.py). pose: 'tap' (hat raised, the trick) or 'idle' (the lecture).
    Returns (sprite 50x66 outlined, coin sprite)."""
    import bibi
    out = bibi.pose_tap() if pose == "tap" else bibi.pose_idle()
    coin = from_grid([".gg.", "gGGg", "gGGg", ".gg."], {"g": "gold_sh", "G": "gold"}).outlined()
    coin.set(2, 2, "gold_hi")
    return out, coin


def magician_head():
    """26x26 head, hand-placed. Traits: silver-white swept-back hair with volume, heavy
    dark brows, sly side-glance, big rounded nose, broad jowly jaw, smirk."""
    rows = [
        "..........GGGGGGG.........",
        ".......GGGIIIIIIGGGG......",
        ".....GGGIIIIIIIIIIIGGg....",
        "....GGIIIIGGGGGGIIIIGGg...",
        "...GGIIIGGGGGGGGGGGGGGgs..",
        "..gGIIGGGIIGGGGGGGGGGGgss.",
        "..gGIGGGIIGGGGGGGGGGGggss.",
        ".sgGGGGIGGGGLLLLGGGGGGgsss",
        ".sgGGGGGLLLLLLLLLLGGGggsss",
        ".sgGGGLLLLLLLLLLLLLKGGgss.",
        ".sgGKKLLLLLLLLLLLKKKKGgss.",
        ".sgKKKKLLLLLLLLKKKKKKkgs..",
        "..gKKBBBBBKKKKKBBBBBKkkg..",
        "..KKBBBBBBBKKKBBBBBBBkkk..",
        ".KKKKKKKKKKKKKKKKKKKKkkkK.",
        "KkKKKWWWeeKKLKKWWWeeKkkkkK",
        "KkKKKkkkkkKLLLKkkkkkkkkkkK",
        ".KKKKKKKKKLLLLLKKKKKKkkkK.",
        ".KKKKKKKKKLLLLLLKKKKkkkk..",
        "..KKKKKKKLLLLLLLkKKKkkkk..",
        "..KKKKKKKkLLLLLkkKKKkkkk..",
        "..KKKKKKKKkddkkKKKKkkkk...",
        "..kKKKKKKKKKKKKKKKddkkk...",
        "...kKKKKKddddddddKKkkk....",
        "...kkKKKKKKKKKKKKKkkkk....",
        "....kkkKKKKKKKKKKkkkk.....",
        ".....kkkkkkkkkkkkkkk......",
        ".......kkkkkkkkkkk........",
    ]
    legend = {"G": "silver", "I": "white", "g": "grey", "s": "slate", "K": "skin", "L": "skin_hi",
              "k": "skin_sh", "d": "skin_dk", "B": "suit_dk", "W": "white", "e": "ink"}
    return from_grid(rows, legend).outlined()
