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

from kit import ROOT, PROOFS
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


def build():
    """Nothing to draw here (see the module doc); kept so build_all treats every wave alike."""


if __name__ == "__main__":
    print(proof())
