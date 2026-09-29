"""Proof sheets for the UI kit (not deliverables): contact sheets per group, colour-blindness and
greyscale-squint checks of the assembled HUD / chat, the wordmark mono test, and the contrast table.
Colour-blindness: Machado et al. 2009, severity 1.0, applied in linear RGB (same as creative pack v1).
"""
import os
import numpy as np
from PIL import Image, ImageFilter

from kit import PROOFS
from palette import contrast
import sheet
import mock

MACHADO = {
    "deuteranopia": np.array([[0.367322, 0.860646, -0.227968], [0.280085, 0.672501, 0.047413],
                              [-0.011820, 0.042940, 0.968881]]),
    "protanopia": np.array([[0.152286, 1.052583, -0.204868], [0.114503, 0.786281, 0.099216],
                            [-0.003882, -0.048116, 1.051998]]),
}


def simulate(img, kind):
    a = np.asarray(img.convert("RGB")).astype(np.float64) / 255
    lin = np.where(a <= 0.04045, a / 12.92, ((a + 0.055) / 1.055) ** 2.4)
    out = np.clip(lin @ MACHADO[kind].T, 0, 1)
    srgb = np.where(out <= 0.0031308, out * 12.92, 1.055 * out ** (1 / 2.4) - 0.055)
    return Image.fromarray((srgb * 255).round().astype(np.uint8))


def squint(img):
    return img.convert("L").filter(ImageFilter.GaussianBlur(2.2)).convert("RGB")


# label pairs the kit promises (ui-kit.json 'label' fields + the style guide's UI table)
CONTRAST = [
    ("white", "ui_bubble", 4.5), ("white", "ui_out", 4.5), ("white", "suit_dk", 4.5), ("white", "ui_panel", 4.5),
    ("white", "flag", 4.5), ("white", "flag_dk", 4.5), ("ink", "gold", 4.5), ("ink", "gold_sh", 4.5),
    ("white", "gold_dk", 4.5), ("white", "ui_scrim", 4.5), ("white", "red", 4.5), ("white", "teal_dk", 4.5),
    ("white", "wood", 4.5), ("grey", "suit_dk", 4.5), ("grey", "ui_scrim", 4.5), ("slate", "ui_scrim", 3.0),
    ("stamp", "paper", 4.5), ("stamp", "receipt", 4.5), ("stamp_lt", "ui_bubble", 4.5), ("stamp_lt", "ui_out", 4.5),
    ("stamp_lt", "ui_scrim", 4.5), ("receipt_ink", "receipt", 4.5), ("orange", "outline", 4.5),
    ("gold_hi", "ui_panel", 4.5), ("red_hi", "ui_bubble", 4.5), ("silver", "ui_panel", 4.5),
    ("sky", "night", 3.0), ("red", "ui_scrim", 3.0), ("red", "outline", 3.0), ("rim", "night", 3.0), ("rim", "plum", 3.0),
]


def build():
    for groups, name, z in ((["chat"], "kit-chat.png", 5), (["controls"], "kit-controls.png", 5),
                            (["meters"], "kit-meters.png", 5), (["widgets"], "kit-widgets.png", 5),
                            (["events"], "kit-events.png", 4), (["props"], "kit-props.png", 5),
                            (["key"], "kit-wordmark.png", 4), (["share"], "kit-share.png", 2),
                            (["sheet", "ticker", "ftue"], "kit-w2-sheet-ticker-ftue.png", 5),
                            (["cards"], "kit-w2-cards.png", 5), (["spins", "trophies"], "kit-w2-spins-trophies.png", 5),
                            (["stage", "ceremony"], "kit-w2-stage-ceremony.png", 4),
                            (["sources"], "kit-w3-sources.png", 5), (["dubi"], "kit-w4-dubi-small.png", 5)):
        sheet.contact(groups, name, z)
    h, c, o, over, yend = mock.build()
    row = Image.new("RGB", (180 * 6 + 40, 320), (0, 0, 0))
    for i, im in enumerate((h, c)):
        row.paste(simulate(im, "deuteranopia"), (i * 376, 0))
        row.paste(simulate(im, "protanopia"), (i * 376 + 188, 0))
    row.paste(squint(h), (752, 0)); row.paste(squint(c), (752 + 188, 0))
    row.resize((row.width * 2, row.height * 2), Image.NEAREST).save(os.path.join(PROOFS, "cvd-deut-prot-and-squint-x2.png"))
    lines = ["| Label | Surface | Contrast | Min | Pass |", "|---|---|---|---|---|"]
    fails = 0
    for fg, bg, lo in CONTRAST:
        cval = contrast(fg, bg)
        ok = cval >= lo
        fails += not ok
        lines.append(f"| `{fg}` | `{bg}` | {cval:.2f}:1 | {lo}:1 | {'yes' if ok else 'NO'} |")
    open(os.path.join(PROOFS, "contrast-table.md"), "w").write("\n".join(lines) + "\n")
    return fails, over


if __name__ == "__main__":
    fails, over = build()
    print("contrast fails:", fails, "| receipt overflow:", over)
