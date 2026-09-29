"""Inline every showcase PNG as a data URI into template.html -> ../od-sevev-cast.html"""
import base64, glob, json, os

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, '..', 'out')
assets = {}
for p in sorted(glob.glob(os.path.join(OUT, '*.png'))):
    k = os.path.splitext(os.path.basename(p))[0]
    assets[k] = 'data:image/png;base64,' + base64.b64encode(open(p, 'rb').read()).decode()
atlas = json.load(open(os.path.join(OUT, 'atlas.json')))
html = open(os.path.join(HERE, 'template.html'), encoding='utf-8').read()
html = html.replace('__ASSETS__', json.dumps(assets)).replace('__ATLAS__', json.dumps(atlas))
dst = os.path.join(HERE, '..', 'od-sevev-cast.html')
open(dst, 'w', encoding='utf-8').write(html)
print(dst, round(len(html) / 1024), 'KB', len(assets), 'assets')
