"""One landmark sheet per ref: left = full figure with a ref-coordinate grid, right = the face at 2x."""
import sys
from PIL import Image, ImageDraw
REF = '../../refs/'
def sheet(name):
    im = Image.open(REF + name + '.png').convert('RGBA')
    a = im.getchannel('A').point(lambda v: 255 if v > 128 else 0); bb = a.getbbox()
    # full figure at 0.5 with 50px ref grid
    s = 0.5
    full = im.resize((int(im.width * s), int(im.height * s)), Image.LANCZOS)
    fb = Image.new('RGBA', full.size, (70, 50, 90, 255)); fb.alpha_composite(full); d = ImageDraw.Draw(fb)
    for x in range(0, im.width, 50):
        d.line([(x * s, 0), (x * s, fb.height)], fill=(255, 0, 0, 150) if x % 100 == 0 else (255, 255, 0, 45))
    for y in range(0, im.height, 50):
        d.line([(0, y * s), (fb.width, y * s)], fill=(255, 0, 0, 150) if y % 100 == 0 else (255, 255, 0, 45))
    for x in range(0, im.width, 100): d.text((x * s + 2, 2), str(x), fill='white')
    for y in range(0, im.height, 100): d.text((2, y * s + 2), str(y), fill='white')
    # face: top 40% of the figure's bbox, centred on the head's columns
    fx0, fy0 = bb[0], bb[1]; fx1 = bb[2]; fy1 = bb[1] + int((bb[3] - bb[1]) * 0.33)
    face = im.crop((fx0, fy0, fx1, fy1)); z = 700 / max(face.size)
    face = face.resize((int(face.width * z), int(face.height * z)), Image.LANCZOS)
    fcb = Image.new('RGBA', face.size, (70, 50, 90, 255)); fcb.alpha_composite(face); d = ImageDraw.Draw(fcb)
    for x in range((fx0 // 20 + 1) * 20, fx1, 20):
        X = (x - fx0) * z; d.line([(X, 0), (X, fcb.height)], fill=(255, 0, 0, 160) if x % 100 == 0 else (255, 255, 0, 40))
        if x % 100 == 0: d.text((X + 2, 2), str(x), fill='white')
    for y in range((fy0 // 20 + 1) * 20, fy1, 20):
        Y = (y - fy0) * z; d.line([(0, Y), (fcb.width, Y)], fill=(255, 0, 0, 160) if y % 100 == 0 else (255, 255, 0, 40))
        if y % 100 == 0: d.text((2, Y + 2), str(y), fill='white')
    out = Image.new('RGBA', (fb.width + fcb.width + 10, max(fb.height, fcb.height)), (20, 16, 24, 255))
    out.alpha_composite(fb, (0, 0)); out.alpha_composite(fcb, (fb.width + 10, 0))
    out.save('../_test/lm-' + name + '.png'); print(name, bb)
for n in sys.argv[1:]: sheet(n)
