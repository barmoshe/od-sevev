#!/usr/bin/env python3
"""The share platform's link-preview stubs (Bar 2026-10-02): one tiny page per share variant,
build/web/s/<variant>/index.html, each with its own og:title / og:description / og:image (the
1200x630 JPEG tools/og.sh rendered into game/web/og/), and a forward into the game that keeps the
query (?via=<channel>) and the hash (#r=<ref>&k=<kind>&...; crawlers never see a hash).

    python3 tools/lib/gen_share_stubs.py <build/web> <site url with a trailing slash>

Reads game/web/og/variants.json (written by tools/og.sh: {variant: {leader, short, head}}) and
ux/ui-strings.json (OG_S_DESC, OG_S_ALT / OG_N_ALT), copies the JPEGs to <build/web>/og/.
The stub page counts as a page view of /s/<variant>/ on the deployed host (Vercel Web Analytics:
the arrivals by variant) and forwards once that script has loaded, at most 700 ms later; the hash
gains v=<variant> so the game knows which card brought the player (window.odArrival.params.v).
"""
import html
import json
import os
import shutil
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, "..", ".."))
MAX_JPEG = 300 * 1024   # WhatsApp skips a larger og:image

PAGE = """<!DOCTYPE html>
<html lang="he" dir="rtl">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{title} | עוד סבב</title>
<meta name="robots" content="noindex,follow">
<link rel="canonical" href="{site}">
<meta property="og:type" content="website">
<meta property="og:site_name" content="עוד סבב">
<meta property="og:locale" content="he_IL">
<meta property="og:title" content="{title}">
<meta property="og:description" content="{desc}">
<meta property="og:url" content="{url}">
<meta property="og:image" content="{img}">
<meta property="og:image:secure_url" content="{img}">
<meta property="og:image:type" content="image/jpeg">
<meta property="og:image:width" content="1200">
<meta property="og:image:height" content="630">
<meta property="og:image:alt" content="{alt}">
<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:title" content="{title}">
<meta name="twitter:description" content="{desc}">
<meta name="twitter:image" content="{img}">
<meta name="theme-color" content="#0038b8">
<noscript><meta http-equiv="refresh" content="0; url=/"></noscript>
<style>html,body{{margin:0;height:100%;background:#0038b8;color:#f7f4ec;font:18px system-ui,-apple-system,Arial,sans-serif}}a{{color:#f7f4ec}}p{{margin:0;padding:40vh 16px 0;text-align:center}}</style>
<script>
(function () {{
	var v = {variant_js};
	var go = function () {{
		if (go.done) return;
		go.done = true;
		var h = location.hash ? location.hash + '&' : '#';
		location.replace('/' + location.search + h + 'v=' + v);
	}};
	var live = !/^(localhost|127\\.0\\.0\\.1|\\[::1\\])$/.test(location.hostname);
	try {{ if (localStorage.getItem('odsevev.me') === '1') live = false; }} catch (x) {{ /* counted */ }}
	if (live) {{
		window.va = window.va || function () {{ (window.vaq = window.vaq || []).push(arguments); }};
		var s = document.createElement('script');
		s.defer = true;
		s.src = '/_vercel/insights/script.js';
		s.onload = function () {{ setTimeout(go, 150); }};
		s.onerror = go;
		document.head.appendChild(s);
		setTimeout(go, 700);
	}} else {{
		go();
	}}
}}());
</script>
</head>
<body><p><a href="/">{title}</a></p></body>
</html>
"""


def main(out, site):
    og_src = os.path.join(ROOT, "game", "web", "og")
    man = os.path.join(og_src, "variants.json")
    if not os.path.exists(man):
        print("gen_share_stubs: no %s (run tools/og.sh): no stubs" % os.path.relpath(man, ROOT))
        return 0
    variants = json.load(open(man, encoding="utf-8"))
    ui = json.load(open(os.path.join(ROOT, "ux", "ui-strings.json"), encoding="utf-8"))["strings"]
    desc = ui.get("OG_S_DESC", ui.get("OG_DESCRIPTION", ""))
    os.makedirs(os.path.join(out, "og"), exist_ok=True)
    n = 0
    big = []
    for name, v in sorted(variants.items()):
        jpg = os.path.join(og_src, name + ".jpg")
        if not os.path.exists(jpg):
            continue
        if os.path.getsize(jpg) > MAX_JPEG:
            big.append(name)
        shutil.copyfile(jpg, os.path.join(out, "og", name + ".jpg"))
        alt = (ui.get("OG_S_ALT", "") if v.get("leader") else ui.get("OG_N_ALT", "")).replace("{short}", v.get("short", ""))
        d = os.path.join(out, "s", name)
        os.makedirs(d, exist_ok=True)
        page = PAGE.format(title=html.escape(v.get("head", ""), quote=True), desc=html.escape(desc, quote=True),
                           site=html.escape(site or "/", quote=True), url=html.escape((site or "/") + "s/" + name + "/", quote=True),
                           img=html.escape((site or "/") + "og/" + name + ".jpg", quote=True), alt=html.escape(alt, quote=True),
                           variant_js=json.dumps(name))
        open(os.path.join(d, "index.html"), "w", encoding="utf-8").write(page)
        n += 1
    if big:
        sys.exit("gen_share_stubs: og images over %d KB: %s" % (MAX_JPEG // 1024, ", ".join(big)))
    print("gen_share_stubs: %d stubs under s/, their og images under og/" % n)
    return 0


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else "")
