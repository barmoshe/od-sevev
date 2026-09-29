"""Face crop at 1:1 ref pixels with a labelled grid every 25 px (labels every 50)."""
import sys
from PIL import Image, ImageDraw
def face(name, box):
    im = Image.open('../../refs/' + name + '.png').convert('RGBA').crop(box)
    bg = Image.new('RGBA', im.size, (70, 50, 90, 255)); bg.alpha_composite(im); d = ImageDraw.Draw(bg)
    for x in range(box[0] - box[0] % 25 + 25, box[2], 25):
        X = x - box[0]; d.line([(X, 0), (X, bg.height)], fill=(255, 0, 0, 170) if x % 50 == 0 else (255, 255, 0, 60))
        if x % 50 == 0: d.text((X + 2, 2), str(x), fill='white'); d.text((X + 2, bg.height - 12), str(x), fill='white')
    for y in range(box[1] - box[1] % 25 + 25, box[3], 25):
        Y = y - box[1]; d.line([(0, Y), (bg.width, Y)], fill=(255, 0, 0, 170) if y % 50 == 0 else (255, 255, 0, 60))
        if y % 50 == 0: d.text((2, Y + 2), str(y), fill='white'); d.text((bg.width - 30, Y + 2), str(y), fill='white')
    bg.save('../_test/face-' + name + '.png')
name = sys.argv[1]; face(name, tuple(int(v) for v in sys.argv[2:6]))
