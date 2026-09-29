#!/usr/bin/env python3
"""Reports the widths of art pixels in a frame: along rows through the stage, it measures runs of
identical colour and prints how often each run length occurs among the short runs (≤ 12 px), the
ones that are single art pixels. One dominant width (k, 2k, ...) = crisp; 4-and-5 = wobble.
    python3 tools/lib/pixel_runs.py shot.png"""
import collections
import sys
from PIL import Image

im = Image.open(sys.argv[1]).convert("RGB")
w, h = im.size
px = im.load()
runs = collections.Counter()
for fy in (0.30, 0.38, 0.45):
    y = int(h * fy)
    x = 0
    while x < w:
        c = px[x, y]
        x2 = x
        while x2 < w and px[x2, y] == c:
            x2 += 1
        n = x2 - x
        if 0 < n <= 12 and x > 0 and x2 < w:
            runs[n] += 1
        x = x2
total = sum(runs.values()) or 1
top = ", ".join("%dpx:%d%%" % (n, round(100 * c / total)) for n, c in sorted(runs.items()))
print("   %s  %dx%d  runs %s" % (sys.argv[1].rsplit("/", 1)[-1], w, h, top))
