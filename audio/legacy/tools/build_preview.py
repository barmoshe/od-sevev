#!/usr/bin/env python3
"""Inlines audio/cues.json and audio/music.json into audio/preview.html.

preview.html must run from file:// (no fetch), so it carries inline copies.
Re-run after editing either JSON:  python3 audio/tools/build_preview.py
"""
import json, os, re

AUDIO = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
html_path = os.path.join(AUDIO, "preview.html")
html = open(html_path).read()

for tag, fname in (("cues-json", "cues.json"), ("music-json", "music.json")):
    data = json.load(open(os.path.join(AUDIO, fname)))
    payload = json.dumps(data, separators=(",", ":")).replace("</", "<\\/")
    pat = re.compile(r'(<script type="application/json" id="%s">).*?(</script>)' % tag, re.S)
    html, n = pat.subn(lambda m: m.group(1) + payload + m.group(2), html)
    assert n == 1, tag

open(html_path, "w").write(html)
print("inlined cues.json + music.json into", html_path)
