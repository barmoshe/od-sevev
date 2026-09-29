"""Wave 6: the UX build review's art items (ux/review-2026-09-29.md, 2026-09-29).

  R7   button_danger_{default,pressed,disabled}   ui_controls.VARIANTS["danger"]: the reset modal's "למחוק הכול"
  R26  icon_trash (9x9)                            wave2.sheets: the settings danger row
  R26  icon_close (now the 16x16 round ✕)          wave2.sheets: one ✕ style for every card (same id, redrawn)
  R18  source_{submarine,poison,checkbook}_icon_sil  sources.silhouette: the locked shop card of the hand-drawn three
  R15  the modal scrim = `outline` #0b0a12 at 60% (engine alpha, not art): documented in the style guide §11.2

This module draws nothing new; the pieces live where their families live. `proof()` writes
proofs/kit-w6.png: every wave-6 piece at x4, in context, on the grounds it has to read on, including the
scrim composite (outline at 60% over the darkest and the brightest ground the stage can show).
"""
import os
from PIL import Image

from kit import ROOT, PROOFS, save, outline_inplace
from palette import rgb
from pix import Layer
import hebfont
import sheet

Z = 4
IDS = ["button_danger_default", "button_danger_pressed", "button_danger_disabled", "icon_close", "icon_trash",
       "source_submarine_icon_sil", "source_poison_icon_sil", "source_checkbook_icon_sil"]


def _png(pid):
    import json
    kit = {e["id"]: e for e in json.load(open(os.path.join(ROOT, "ui-kit.json")))["pieces"]}
    return kit[pid], Image.open(os.path.join(ROOT, kit[pid]["file"])).convert("RGBA")


def _label(im, ent, text, color, dy=0):
    """Bake a centred proof label into a stretched button (proof only; the engine draws the text)."""
    L = Layer(im.width, im.height)
    hebfont.draw(L, text, im.width // 2, (ent["content"][1] if "content" in ent else 3) + dy, color, align="center")
    t = L.to_image(1)
    im.alpha_composite(t)
    return im


def _scrim(c):
    o = rgb("outline")
    return tuple(round(a * 0.6 + b * 0.4) for a, b in zip(o, c))


def proof():
    W, H = 220, 160
    img = Image.new("RGBA", (W, H), rgb("ui_panel") + (255,))
    # row 1: the O10 button row, commit LEFT (danger) and cancel RIGHT (secondary), each state
    y = 4
    for k, st in enumerate(("default", "pressed", "disabled")):
        de, dm = _png(f"button_danger_{st}")
        se, sm = _png(f"button_secondary_{st}")
        d = sheet.nine(dm, de["slice"], 64, 24, de.get("mode", "stretch"))   # O10 Rect2(.., 256, 96) = 64x24 art
        s = sheet.nine(sm, se["slice"], 64, 24, se.get("mode", "stretch"))
        _label(d, de, "למחוק הכול", de["label"] if st != "disabled" else "grey", 2)
        _label(s, se, "התחרטתי", se["label"] if st != "disabled" else "grey", 2)
        img.alpha_composite(d, (4, y + k * 26)); img.alpha_composite(s, (72, y + k * 26))
        img.alpha_composite(dm, (142 + k * 26, y))          # the 1x pieces as shipped
    # row 2: the round ✕ on every ground it meets (court wood, title band, sheet body, cream card, the scrim)
    y = 84
    grounds = [rgb("wood"), rgb("ui_bubble"), rgb("ui_panel"), (255, 244, 224), _scrim(rgb("ui_scrim")),
               _scrim((255, 255, 255)), rgb("teal_dk")]
    _, cx = _png("icon_close")
    _, tr = _png("icon_trash")
    for i, g in enumerate(grounds):
        tile = Image.new("RGBA", (24, 36), g + (255,))
        tile.alpha_composite(cx, (4, 2))
        tile.alpha_composite(tr, (7, 22))
        img.alpha_composite(tile, (4 + i * 27, y))
    # row 3: the settings danger row (trash leading the label on the right) on the dark sheet, and the
    # three new locked silhouettes on card_plate
    y = 126
    row = Layer(110, 16, fill="ui_panel")
    hebfont.draw(row, "איפוס התקדמות", 94, 4, "white")
    ri = row.to_image(1)
    ri.alpha_composite(tr, (99, 4))
    img.alpha_composite(ri, (4, y))
    _, plate = _png("card_plate")
    for i, sid in enumerate(("submarine", "poison", "checkbook")):
        _, sil = _png(f"source_{sid}_icon_sil")
        p = plate.copy()
        p.alpha_composite(sil, (1, 1))
        img.alpha_composite(p, (118 + i * 28, y - 4))
    big = img.resize((W * Z, H * Z), Image.NEAREST)
    fn = os.path.join(PROOFS, "kit-w6.png")
    big.save(fn)
    return fn


# ------------------------------------------------------------------ wave 6 polish: the "no photo" stand-in
# A partner the cast has no ChatGPT ref for (today Almog Cohen: asset-requests/REQUESTS.md `almog`) used to draw
# the engine's neutral "?" card in the chat and nothing on the partner card. We never draw a likeness of a real
# person without a ref, so every such partner gets ONE generic stand-in: a featureless head-and-shoulders on a
# cool grey disc (the contacts app's "no photo"), and a featureless figure in a suit. Graphic tier: v2 swatches,
# a 3-band cel on the slate ramp (light `slate`, base `suit_hi`, shadow `suit`), binary alpha, d = 1.
# The pipeline joins them as the hand-drawn character `nophoto` and aliases every content partner that has no
# character to it (pipeline/od-sevev/sprites.py `standin_aliases`), so ChatView.avatar_art, the partner card
# and the ultimatum cameo pick it up through SpriteStrip.resolve with no engine change.
NOPHOTO_RING, NOPHOTO_GROUND = "slate", "silver"
NOPHOTO_W, NOPHOTO_H = 40, 97            # the partners are 41 x 97 art px at d 3 (123 x 292 sprite px)
NOPHOTO_ANCHOR = [20, 96]


def _disc_mask(size, inset):
    """The render-down avatars' round mask (showcase build.py avatar(): PIL ellipse [inset, inset, size-1-inset])."""
    from PIL import ImageDraw
    m = Image.new("L", (size, size), 0)
    ImageDraw.Draw(m).ellipse([inset, inset, size - 1 - inset, size - 1 - inset], fill=255)
    return [[m.getpixel((x, y)) > 0 for x in range(size)] for y in range(size)]


def _cel(L, mask, base="suit_hi", light="slate", shadow="suit", outline=None):
    """Fill `mask` (set of (x, y)) with a 3-band cel: 1 px light on the top/left inner edge, 1 px shadow on the
    bottom/right one; with `outline`, the outermost ring of the mask is that swatch (outline_inplace's rule)."""
    edge = {(x, y) for (x, y) in mask if any((x + dx, y + dy) not in mask for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))}
    inner = mask - edge if outline else mask
    for (x, y) in mask:
        L.set(x, y, outline if (outline and (x, y) in edge) else base)
    ref = (mask - edge) if outline else mask
    for (x, y) in inner:
        if (x, y - 1) not in ref or (x - 1, y) not in ref:
            L.set(x, y, light)
        elif (x, y + 1) not in ref or (x + 1, y) not in ref:
            L.set(x, y, shadow)


def _ellipse_set(cx, cy, rx, ry):
    """The pixels of Layer.ellipse's rule, as a set."""
    T = Layer(200, 200)
    T.ellipse(cx, cy, rx, ry, "white")
    return {(x, y) for y in range(200) for x in range(200) if T.px[y][x]}


def nophoto_avatar(size):
    """32 or 24: the avatars' construction (a 2 px ring, the disc inside), a slate ring on a silver disc, and a
    featureless head over a shoulder arc, one ground row between them so the head reads as a head."""
    ring, disc = _disc_mask(size, 0), _disc_mask(size, 2)
    L = Layer(size, size)
    for y in range(size):
        for x in range(size):
            if ring[y][x]:
                L.set(x, y, NOPHOTO_RING if not disc[y][x] else NOPHOTO_GROUND)
    c = (size - 1) / 2
    if size == 32:
        head, shoulders = _ellipse_set(c, 12.5, 5, 5.5), _ellipse_set(c, 29, 11, 9)
        top = 20
    else:
        head, shoulders = _ellipse_set(c, 9, 4, 4), _ellipse_set(c, 22, 8, 7)
        top = 15
    shoulders = {(x, y) for (x, y) in shoulders if y >= top}
    fig = {(x, y) for (x, y) in head | shoulders if 0 <= x < size and 0 <= y < size and disc[y][x]}
    _cel(L, fig)
    return L


def nophoto_body():
    """The partner-card / cameo figure, 40 x 97 at d 1, built like the cast (a big head, broad jacket, 96 art px
    feet to crown) with nothing that is a face: a round head with ears, a suit jacket with lapels over a shirt V
    and a dark tie, arms hanging to plain hands, trousers, shoes. Parts back to front, each in its own 3-band
    ramp (head and hands on the slate ramp, the suit on suit_hi, the shoes on suit_dk); the part edges give the
    inner lines in the local shadow; one `outline` ring round the whole silhouette (outline_inplace)."""
    cx = 19.5
    L = Layer(NOPHOTO_W, NOPHOTO_H)
    head = ("slate", "grey", "suit_hi")
    suit = ("suit_hi", "slate", "suit")
    shoe = ("suit_dk", "suit", "night")

    owner = {}

    def part(px, ramp):
        px = {(x, y) for (x, y) in px if 1 <= x < NOPHOTO_W - 1 and 0 <= y < NOPHOTO_H}
        _cel(L, px, *ramp)
        owner.update({p: ramp for p in px})

    legs = set()
    for y in range(60, 93):                                                # trousers, 2 px apart, a slight taper
        t = 1 if y >= 80 else 0
        legs |= {(x, y) for x in range(10 + t, 19)} | {(x, y) for x in range(21, 30 - t)}
    part(legs, suit)
    for sx in (13.5, 25.5):                                                # shoes, toes out, soles on the feet row
        s = {(x, y) for (x, y) in _ellipse_set(sx + (-0.5 if sx < cx else 0.5), 93.5, 5, 2.5) if y <= 96}
        s |= {(x, 96) for x in range(int(sx) - 5, int(sx) + 6)}
        part(s, shoe)
    part({(x, y) for x in range(16, 24) for y in range(22, 30)}, head)     # neck
    jacket = set()
    for y in range(27, 64):                                                # collar -> sloped shoulders -> a slight taper
        hw = 6 + (y - 27) * 2.2 if y < 31 else 14.5 - (y - 31) * 0.05
        jacket |= {(x, y) for x in range(int(cx - hw + 0.5), int(cx + hw + 0.5) + 1)}
    part(jacket, suit)
    for y in range(28, 36):                                                # the shirt V (flat, shirt-light)
        w = (35 - y) / 2
        for x in range(int(cx - w + 0.5), int(cx + w + 0.5) + 1):
            L.set(x, y, "silver" if x < cx else "grey")
    L.vline(19, 29, 40, "suit_dk"); L.vline(20, 29, 40, "suit_dk")         # the tie
    L.set(19, 41, "suit_dk")
    for k in range(10):                                                    # lapels: the V's edges run on to the button
        L.set(int(cx - 5 + k * 0.45), 29 + k, "suit"); L.set(int(cx + 5 - k * 0.45 + 0.5), 29 + k, "suit")
    L.vline(20, 42, 62, "suit")                                            # the jacket's front edge
    L.set(18, 46, "suit"); L.set(18, 53, "suit")                           # two buttons
    for side in (-1, 1):                                                   # arms hanging off the shoulders
        arm = set()
        for y in range(31, 61):
            x0 = cx + side * 12.5 + side * (y - 31) * 0.06
            arm |= {(int(x0 + dx + 0.5), y) for dx in (-2, -1, 0, 1, 2)}
        part(arm, suit)
        part(_ellipse_set(cx + side * 13.5 - 0.5, 62.5, 2.5, 3), head)     # hands
    hd = _ellipse_set(cx, 14, 9.5, 11.5)
    for ex in (cx - 10, cx + 10):                                          # ears, the only feature
        hd |= _ellipse_set(ex, 15, 1.5, 2.5)
    part(hd, head)
    # the silhouette's own light and shadow bands sit just inside its outline ring (which outline_inplace paints
    # over each part's outer edge band), in the ramp of the part that owns the pixel
    ring = {(x, y) for y in range(L.h) for x in range(L.w) if L.px[y][x] and any(
        L.get(x + dx, y + dy) is None for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))}
    for (x, y), (base, light, shadow) in owner.items():
        if (x, y) in ring or L.px[y][x] not in (base, light, shadow):
            continue
        if (x, y - 1) in ring or (x - 1, y) in ring:
            L.set(x, y, light)
        elif (x, y + 1) in ring or (x + 1, y) in ring:
            L.set(x, y, shadow)
    outline_inplace(L)
    return L


def build():
    """Wave 6 polish: the no-photo stand-in (the other wave-6 pieces live where their families live)."""
    save(nophoto_avatar(32), "avatar_nophoto", "nophoto",
         notes="Chat avatar for a partner with no ref (the stand-in character `nophoto`; today Almog Cohen). Same "
               "construction as the render-down avatars (2 px ring, disc inside), slate ring on silver: a neutral "
               "'no photo', never a likeness. Draw at artScale (d = 1).")
    save(nophoto_avatar(24), "avatar24_nophoto", "nophoto",
         notes="The 24 px chat avatar of the no-photo stand-in (UX's 48-logical-px chat avatar at x2).")
    save(nophoto_body(), "nophoto_idle", "nophoto", frames=1, frame_w=NOPHOTO_W, pivot=NOPHOTO_ANCHOR,
         extra={"fps": 1, "loop": True, "events": {}, "char": "nophoto", "anim": "idle", "standIn": True},
         notes="chars.nophoto 'idle' (1 frame, d = 1): the featureless figure the partner card and the ultimatum cameo "
               "draw for a partner with no ref. 40x97 like a partner at d 3, anchor [20, 96] (feet). The pipeline "
               "aliases every content partner without a character to it.")


POLISH_IDS = ["trophy_moon", "trophy_moon_locked", "sheet_modal", "avatar_nophoto", "avatar24_nophoto", "nophoto_idle"]


def proof_polish():
    """proofs/kit-w6-polish.png: the wave-6 polish pieces at x4 on the grounds they meet."""
    W, H = 200, 118
    img = Image.new("RGBA", (W, H), rgb("ui_panel") + (255,))
    x = 4
    for pid in ("trophy_moon", "trophy_moon_locked"):
        _, plate = _png("trophy_plate_earned" if pid == "trophy_moon" else "trophy_plate_locked")
        _, ic = _png(pid)
        p = plate.copy()
        p.alpha_composite(ic, (3, 3))
        img.alpha_composite(p, (x, 4))
        x += plate.width + 4
    # the modal on the scrimmed stage: the scrim over the darkest ground, the sheet on it
    scr = Image.new("RGBA", (70, 50), _scrim(rgb("ui_scrim")) + (255,))
    ent, sm = _png("sheet_modal")
    scr.alpha_composite(sheet.nine(sm, ent["slice"], 60, 40, ent.get("mode", "stretch")), (5, 5))
    img.alpha_composite(scr, (60, 2))
    for i, (pid, g) in enumerate((("avatar_nophoto", "ui_panel"), ("avatar24_nophoto", "ui_panel"))):
        _, a = _png(pid)
        img.alpha_composite(a, (4 + i * 36, 60))
    _, body = _png("nophoto_idle")
    img.alpha_composite(body, (140, 14))
    big = img.resize((W * Z, H * Z), Image.NEAREST)
    fn = os.path.join(PROOFS, "kit-w6-polish.png")
    big.save(fn)
    return fn


if __name__ == "__main__":
    print(proof())
