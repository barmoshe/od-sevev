"""Give an opaque ChatGPT ref a transparent background, the way the approved refs arrive.

The ChatGPT batch of 2026-09-30 came back RGB on a flat off-white field; rig.py crops every ref
to its alpha box, so an opaque ref would render the whole frame. This keys out the field: every
pixel close to the border colour that is connected to the image edge becomes transparent, with a
soft ramp so the outline keeps its anti-aliasing. Enclosed gaps (an arm on a hip) stay opaque
unless `holes` names a seed point inside them; `clear` boxes (x0,y0,x1,y1) key out every
field-coloured pixel inside them, connected or not (pockets in curly hair; keep the box off the
teeth and the eyes, which are field-white too).

    python3 cutout.py <in.png> <out.png> [--holes x,y ...] [--clear x0,y0,x1,y1 ...]
"""
import sys
import numpy as np
from PIL import Image, ImageDraw

NEAR, FAR = 10, 42          # max-channel distance from the field: <= NEAR fully clear, >= FAR fully kept


def cutout(src, holes=(), clear=()):
    im = Image.open(src).convert('RGB')
    a = np.asarray(im).astype(np.int16)
    h, w, _ = a.shape
    edge = np.concatenate([a[0], a[-1], a[:, 0], a[:, -1]])
    field = np.median(edge, axis=0)
    d = np.abs(a - field).max(axis=2)
    bg = Image.fromarray(((d < FAR) * 255).astype(np.uint8)).copy()  # a fromarray image is read-only to floodfill
    seeds = [(x, 0) for x in range(0, w, 8)] + [(x, h - 1) for x in range(0, w, 8)] \
        + [(0, y) for y in range(0, h, 8)] + [(w - 1, y) for y in range(0, h, 8)] + list(holes)
    for s in seeds:
        if bg.getpixel(s) == 255:
            ImageDraw.floodfill(bg, s, 128)
    region = np.asarray(bg) == 128
    for x0, y0, x1, y1 in clear:
        box = np.zeros_like(region)
        box[y0:y1, x0:x1] = True
        region |= box & (d < FAR)
    alpha = np.full((h, w), 255, np.uint8)
    ramp = np.clip((d - NEAR) / (FAR - NEAR), 0, 1)
    alpha[region] = (ramp[region] * 255).astype(np.uint8)
    out = np.dstack([np.asarray(im), alpha])
    return Image.fromarray(out, 'RGBA')


if __name__ == '__main__':
    args = sys.argv[1:]
    opts = {'--holes': [], '--clear': []}
    for flag in ('--clear', '--holes'):
        if flag in args:
            i = args.index(flag)
            rest = args[i + 1:]
            n = next((k for k, a in enumerate(rest) if a.startswith('--')), len(rest))
            opts[flag] = [tuple(int(v) for v in p.split(',')) for p in rest[:n]]
            args = args[:i] + rest[n:]
    cutout(args[0], opts['--holes'], opts['--clear']).save(args[1])
