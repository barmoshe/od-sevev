"""Small Dubi (18 art px tall, 20x23 frame, anchor [10, 22]), hand-drawn as layered pixel grids.

Why hand-drawn: the 18-px render-down lost the beak, eye and claws below one art px, so talk differed from
idle by 3 pixels (TA objection, orchestrator wave 4). Here the jaw opens 2+ px and the eye is a 2x2 white.

Look = the approved mic Dubi (showcase/out/dubi-mic_*): green parrot (lime / green / green_sh), big white eye
with a dark pupil, hooked grey beak with a dark tip, navy suit, white shirt, bright flag-blue tie (Dubi's tie
is the one allowed non-Magician flag blue: he is the mouthpiece, style guide §2.2), tan claws. Faces
screen-LEFT (he looks along the crawl toward the stage); the engine flips for rightward flight.

Layers (each outlined on its own, then composited, so the head always draws a line over the collar):
  lower body (legs, claws)  ·  upper body (suit, shirt, tie)  ·  near wing at 3 angles (down / mid folded / up)
  ·  head (3 eyelid states)  ·  upper beak  ·  jaw (closed / open)
Frames are composed from motion/state-graph-dubi.md §1 recipes. At 18 px, a rig op becomes whole-pixel
moves: breath / squash = the waist cut moves 1 ap; the neck cut moves the head group; any beak angle >= +10°
is the open jaw; wing angles map to down (<= -10°), mid (-10°..+20°), up (>= +20°). The ±3° idle sway is
below one pixel, so it is carried by nothing (stated, not faked).
Seams (CONTRACT §4): every action's f0 and every one-shot's last frame == idle.f0; fly.f0 == land.f0.
"""
from pix import Layer
from kit import save, strip, grid_layer

G = "dubi"
FW, FH, ANCHOR = 20, 23, (10, 22)

LEG = {"L": "lime", "G": "green", "E": "green_sh", "w": "white", "i": "ink", "g": "grey", "l": "slate",
       "d": "suit_dk", "N": "navy", "n": "night", "B": "flag_hi", "F": "flag", "W": "white", "o": "orange_sh",
       "x": "skin", "r": "red_dk", "P": "pink_sh", "s": "silver"}


def fill(rows):
    w = max(len(r) for r in rows)
    return grid_layer([r.ljust(w, ".") for r in rows], LEG)


def out(L):
    return L.outlined("outline", pad=1)      # +1 px each side


# ---- the parts (fills; each gets its own 1-px outline; positions are the fill's top-left in frame px)
HEAD = {
    "open": [
        "...LLL...",
        ".LLLLLLL.",
        "LLLLLLLGG",
        "LLLwwLGGG",
        "LLLiwGGGE",
        "LLLLGGGGE",
        ".LGGGGGEE",
        "..EGGGEE.",
    ],
}
HEAD["half"] = [r.replace("ww", "GG") if i == 3 else r for i, r in enumerate(HEAD["open"])]
HEAD["shut"] = [r.replace("ww", "GG") if i == 3 else (r.replace("iw", "EE") if i == 4 else r)
                for i, r in enumerate(HEAD["open"])]
HEAD_POS = (6, 4)

BEAK = [".ggg", "ggsgg", "gglll", "gl", "d"]          # upper mandible: hooked, dark tip curling down-left
BEAK_POS = (2, 7)
JAW = {"closed": [".lll"], "open": [".rPr", ".rr", "..ll"]}   # open drops the lower mandible 2 ap
JAW_POS = (2, 11)

UPPER = [                                              # suit, shirt, tie (rows 13..18)
    "NNWFWNN",
    "NBWFWNNn",
    "NBNFNNNn",
    "NBNFFNNn",
    "NBNNNNNn",
    "NNNNNNNn",
]
UPPER_POS = (6, 13)
LOWER = [                                              # the trouser seat, legs and claws (rows 18..22)
    ".NNNNNn",
    ".nN.Nn",
    ".nN.Nn",
    "oox.oox",
]
LOWER_POS = (6, 18)

WING = {   # the near (screen-right) wing, drawn IN FRONT of the suit: lime on navy is the strongest read at 18 px
    "mid": ["LL", "LGE", "LGE", "LGE", ".GE", ".E"],                  # folded along the body (rest)
    "up": [".LL", "LLG", "LGE", "LGE", ".GE", ".E."],                   # raised above the shoulder (+35°), in front
    "down": ["LG..", "LGE.", ".LGE", "..GE", "...E"],                  # downstroke (-30°)
}
WING_POS = {"mid": (12, 13), "up": (14, 5), "down": (13, 14)}


XO = 1   # the whole figure sits 1 px right, so the claws centre on anchor x 10


def compose(head="open", jaw="closed", wing="mid", neck=(0, 0), waist=0):
    """neck = (dx, dy) of the head group (head, beak, jaw); waist = dy of everything above the waist
    (upper body, wing, head group): -1 = stretch/breath up, +1 = squash."""
    F = Layer(FW, FH)

    def put(fl, pos, dx=0, dy=0):
        o = out(fl)
        F.paste(o, pos[0] - 1 + dx + XO, pos[1] - 1 + dy)

    put(fill(LOWER), LOWER_POS)
    put(fill(UPPER), UPPER_POS, 0, waist)
    if wing != "up":
        put(fill(WING[wing]), WING_POS[wing], 0, waist)
    hx, hy = neck[0], neck[1] + waist
    put(fill(HEAD[head]), HEAD_POS, hx, hy)
    put(fill(JAW[jaw]), JAW_POS, hx, hy)
    put(fill(BEAK), BEAK_POS, hx, hy)
    if wing == "up":                                   # the raised wing reads in front of the head
        put(fill(WING[wing]), WING_POS[wing], 0, waist)
    # the seat of the suit must stay joined to the jacket when the waist lifts (breath / stretch)
    if waist < 0:
        for x in range(FW):
            if F.get(x, 18) in ("navy", "night") and F.get(x, 17 + waist + 1) is None:
                F.set(x, 17, F.get(x, 18))
    return F


def frames():
    I0 = compose()
    idle = []
    for i in range(16):
        breath = -1 if 4 <= i <= 11 else 0
        nod = (0, -1) if i in (6, 7) else (0, 0)
        head = {12: "half", 13: "shut"}.get(i, "open")
        idle.append(I0 if i == 0 else compose(head=head, neck=nod, waist=breath))
    talk = [I0, compose(jaw="open")]
    squawk = [I0, compose(jaw="open", wing="up", neck=(0, -1), waist=-1), compose(jaw="open"), I0]
    fly_base = dict(waist=1)
    FLY0 = compose(wing="up", **fly_base)
    fly = [FLY0, compose(wing="mid", **fly_base), compose(wing="down", **fly_base), compose(wing="mid", **fly_base)]
    land = [FLY0, compose(wing="mid", waist=1), I0]
    # the recipe's strike is -2 forward / +2 down; -2 forward puts the beak tip on the 20-px frame edge, so the
    # strike is -1 forward / +2 down (the drop carries the peck) and the contact frame adds the squash
    peck = [I0, compose(neck=(1, -1)), compose(neck=(-1, 2)), compose(neck=(-1, 2), waist=1), compose(neck=(0, 1)), I0]
    return {"idle": idle, "talk": talk, "squawk": squawk, "fly": fly, "land": land, "peck": peck}


ANIMS = {  # CONTRACT §4 / TA sprites.json chars.dubi: counts, fps, loop, events are final and unchanged
    "idle": (16, 8, True, {}), "talk": (2, 16, False, {}), "squawk": (4, 12, False, {"squawk": 1}),
    "fly": (4, 12, True, {"flap": 2}), "land": (3, 12, False, {"touch": 1}), "peck": (6, 12, False, {"peck": 2}),
}


def build():
    fr = frames()
    for name, fs in fr.items():
        n, fps, loop, ev = ANIMS[name]
        assert len(fs) == n and all((f.w, f.h) == (FW, FH) for f in fs), name
        for f in fs:                                   # nothing may touch the frame edge (the TA's edge check)
            assert all(f.px[0][x] is None for x in range(FW)) and all(f.px[y][0] is None and f.px[y][FW - 1] is None
                                                                     for y in range(FH)), name
        save(strip(fs), f"dubi_small_{name}", G, frames=n, frame_w=FW, pivot=list(ANCHOR),
             extra={"fps": fps, "loop": loop, "events": ev, "char": "dubi", "anim": name},
             notes=f"chars.dubi '{name}': {n} frames @ {fps} fps, loop={loop}, events={ev}. 20x23 frames, anchor [10,22] "
                   "(feet). Hand-drawn layered replacement for the 18-px render-down placeholder.")
    # seam checks
    same = lambda a, b: a.px == b.px
    I0 = fr["idle"][0]
    assert all(same(fr[k][0], I0) for k in ("talk", "squawk", "peck"))
    assert all(same(fr[k][-1], I0) for k in ("squawk", "land", "peck"))
    assert same(fr["fly"][0], fr["land"][0])
    diff = sum(1 for y in range(FH) for x in range(FW) if fr["talk"][0].px[y][x] != fr["talk"][1].px[y][x])
    return fr, diff


if __name__ == "__main__":
    fr, diff = build()
    print("talk f0 vs f1 differs by", diff, "px")
    from kit import write_manifest
    print(write_manifest())
