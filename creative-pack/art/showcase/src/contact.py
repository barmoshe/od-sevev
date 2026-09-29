import json, sys
from PIL import Image
A = json.load(open('out/atlas.json'))
def pick(c, a, idx, z=3):
    d = A['chars'][c]; w, h = d['frameW'], d['frameH']; im = Image.open('out/' + d['anims'][a]['file'])
    fr = [im.crop((i * w, 0, i * w + w, h)) for i in idx]
    o = Image.new('RGBA', (len(fr) * (w * z + 4), h * z), (58, 40, 78, 255))
    for k, f in enumerate(fr): o.alpha_composite(f.resize((w * z, h * z), Image.NEAREST), (k * (w * z + 4), 0))
    return o
def sheet(rows, out):
    W = max(r.width for r in rows); H = sum(r.height for r in rows)
    o = Image.new('RGBA', (W, H), (58, 40, 78, 255)); y = 0
    for r in rows: o.alpha_composite(r, (0, y)); y += r.height
    o.save(out)
sheet([pick('bibi', 'idle', [0, 10, 17]), pick('bibi', 'tap', [1, 2, 3, 5]), pick('bibi', 'crit', [4, 6, 8, 12])], '_test/check-bibi.png')
sheet([pick('sara', 'offended', [0, 2, 4, 9]), pick('bennett', 'flip', [0, 2, 3, 4, 5, 7])], '_test/check-others.png')
