"""Proof sheets (not deliverables): silhouette grid, colour-blindness sims, 1x game-scale read.
Colour-blindness: Machado et al. 2009 matrices, severity 1.0, applied in linear RGB."""
import os
from PIL import Image
import numpy as np
from pix import Layer
import characters as C

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..")
P = os.path.join(OUT, "proofs")

MACHADO = {
    "deuteranopia": np.array([[0.367322, 0.860646, -0.227968], [0.280085, 0.672501, 0.047413], [-0.011820, 0.042940, 0.968881]]),
    "protanopia": np.array([[0.152286, 1.052583, -0.204868], [0.114503, 0.786281, 0.099216], [-0.003882, -0.048116, 1.051998]]),
}


def simulate(img, kind):
    a = np.asarray(img.convert("RGB")).astype(np.float64) / 255
    lin = np.where(a <= 0.04045, a / 12.92, ((a + 0.055) / 1.055) ** 2.4)
    out = lin @ MACHADO[kind].T
    out = np.clip(out, 0, 1)
    srgb = np.where(out <= 0.0031308, out * 12.92, 1.055 * out ** (1 / 2.4) - 0.055)
    return Image.fromarray((srgb * 255).round().astype(np.uint8))


def silhouettes():
    names = list(C.CAST)
    L = Layer(len(names) * 26 + 4, 40, fill="white")
    for i, n in enumerate(names):
        L.paste(C.build(n).silhouette("ink"), 2 + i * 26 - 3, 2)
    return L


if __name__ == "__main__":
    silhouettes().to_image(3).save(os.path.join(P, "cast-silhouettes.png"))
    for f in ("lineup.png", "title.png"):
        im = Image.open(os.path.join(OUT, f))
        for k in MACHADO:
            simulate(im, k).save(os.path.join(P, f.replace(".png", f"-{k}.png")))
    # 1x game scale: the coalition row exactly as a phone shows it at 180px width (x1 art px)
    names = ["sara", "bengvir", "smotrich", "deri", "gafni", "levin", "regev", "gotliv",
             "lapid", "bennett", "liberman", "eisenkot", "gantz", "golan"]
    L = Layer(7 * 26, 2 * 36, fill="plum")
    for i, n in enumerate(names):
        L.paste(C.build(n), (i % 7) * 26 - 3, (i // 7) * 36)
    L.to_image(1).save(os.path.join(P, "cast-1x-gamescale.png"))
    L.to_image(3).save(os.path.join(P, "cast-3x-phone.png"))
    print("proofs ok")
