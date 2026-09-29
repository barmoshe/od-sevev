import json, sys
from PIL import Image
A = json.load(open('out/atlas.json'))
rows = []
for c in sys.argv[2:]:
    d = A['chars'][c]; w, h = d['frameW'], d['frameH']; z = 3
    fr = []
    idle = Image.open('out/' + d['anims']['idle']['file']); fr += [idle.crop((i*w, 0, i*w+w, h)) for i in (0, 10)]
    ra = [k for k in d['anims'] if k != 'idle'][0]; im = Image.open('out/' + d['anims'][ra]['file'])
    n = d['anims'][ra]['frames']; fr += [im.crop((i*w, 0, i*w+w, h)) for i in (2, 4, n // 2 + 2)]
    o = Image.new('RGBA', (len(fr) * (w*z+4), h*z), (58, 40, 78, 255))
    for k, f in enumerate(fr): o.alpha_composite(f.resize((w*z, h*z), Image.NEAREST), (k*(w*z+4), 0))
    rows.append(o)
W = max(r.width for r in rows); H = sum(r.height for r in rows)
out = Image.new('RGBA', (W, H), (58, 40, 78, 255)); y = 0
for r in rows: out.alpha_composite(r, (0, y)); y += r.height
out.save(sys.argv[1]); print(out.size)
