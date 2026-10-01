#!/usr/bin/env python3
"""Templates the od-sevev HTML surfaces (N1 disclaimer, N0 splash, hand-off bar, O8 About) into
the exported build/web/index.html (ux/rtl-map.md §9: strings with surface "html" are templated
at export, <noscript> included).

    python3 tools/lib/render_shell.py build/web/index.html

{{KEY}}     -> ux/ui-strings.json strings[KEY], HTML-escaped
{{KEY_JS}}  -> the same, escaped for a single-quoted JS string
{{KEY_JSON}} -> the same as a JSON string literal, quotes included (the JSON-LD block)
{{DISC_BY_HTML}}        -> DISC_BY with {publisher}/{mail} from OD_PUBLISHER / OD_CONTACT_MAIL
                           (empty segments dropped) and "אודות" as the About link
{{ABOUT_SOURCES_LIST}}  -> design/facts.json facts as <li> with "למקור" links: only facts without
                           `notUsed: true`, and only their Hebrew `aboutHe` (about_items)
Any {{KEY}} left over fails the build.
"""
import html
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, "..", ".."))


def main(path):
    ui = json.load(open(os.path.join(ROOT, "ux", "ui-strings.json"), encoding="utf-8"))["strings"]
    facts_path = os.path.join(ROOT, "design", "facts.json")
    facts = json.load(open(facts_path, encoding="utf-8")).get("facts", []) if os.path.exists(facts_path) else []
    publisher = os.environ.get("OD_PUBLISHER", "base67")
    mail = os.environ.get("OD_CONTACT_MAIL", "")
    src = open(path, encoding="utf-8").read()

    def esc(k):
        return html.escape(ui.get(k, ""), quote=True)

    # DISC_BY: "מאת {publisher} · {mail} · אודות"
    parts = [p.strip() for p in ui.get("DISC_BY", "").split("·")]
    out = []
    about_word = ui.get("ABOUT_TITLE", "אודות")
    for p in parts:
        if "{mail}" in p:
            if not mail:
                continue
            out.append(html.escape(p.replace("{mail}", "")) + '<a href="mailto:%s">%s</a>' % (html.escape(mail), html.escape(mail)))
        elif "{publisher}" in p:
            out.append(html.escape(p.replace("{publisher}", publisher)))
        elif p == about_word:
            out.append('<a href="#" id="od-about-link">%s</a>' % html.escape(p))
        elif p:
            out.append(html.escape(p))
    src = src.replace("{{DISC_BY_HTML}}", " · ".join(out))

    items, skipped = about_items(facts, ui)
    src = src.replace("{{ABOUT_SOURCES_LIST}}", "\n".join(items))

    def js(k):
        return ui.get(k, "").replace("\\", "\\\\").replace("'", "\\'")

    def js_json(k):
        return json.dumps(ui[k], ensure_ascii=False).replace("</", "<\\/") if k in ui else "{{%s_JSON}}" % k

    src = re.sub(r"\{\{([A-Z0-9_]+)_JSON\}\}", lambda m: js_json(m.group(1)), src)
    src = re.sub(r"\{\{([A-Z0-9_]+)_JS\}\}", lambda m: js(m.group(1)), src)
    src = re.sub(r"\{\{([A-Z0-9_]+)\}\}", lambda m: esc(m.group(1)) if m.group(1) in ui else m.group(0), src)
    left = sorted(set(re.findall(r"\{\{[A-Z0-9_]+\}\}", src)))
    if left:
        sys.exit("render_shell: unknown keys %s" % ", ".join(left))
    open(path, "w", encoding="utf-8").write(src)
    print("render_shell: templated %s (%d sources; left out: %d notUsed, %d without aboutHe)"
          % (os.path.relpath(path, ROOT), len(items), skipped["notUsed"], skipped["noAboutHe"]))


def about_items(facts, ui):
    """O8 About's source list (ux/rtl-map.md §9, review R2). The page is public, so it prints only
    public text: a fact with `notUsed: true` (post-launch, bench-only or dropped) is left out, and
    only the Game Designer's Hebrew `aboutHe` line is printed, never the English research note in
    `text`; a fact without `aboutHe` is left out too. Returns ([<li>...], {notUsed, noAboutHe})."""
    items = []
    skipped = {"notUsed": 0, "noAboutHe": 0}
    link_word = html.escape(ui.get("ABOUT_SOURCE_LINK", "למקור"))
    for f in facts:
        if f.get("notUsed") is True:
            skipped["notUsed"] += 1
            continue
        line = (f.get("aboutHe") or "").strip()
        if not line:
            skipped["noAboutHe"] += 1
            continue
        meta = " · ".join('<bdi>%s</bdi>' % html.escape(x) for x in [f.get("outlet") or "", f.get("date") or ""] if x)
        link = ' <a href="%s" target="_blank" rel="noopener">%s</a>' % (html.escape(f["url"]), link_word) if f.get("url") else ""
        items.append('<li>%s<br><span class="od-src">%s</span>%s</li>' % (html.escape(line), meta, link))
    return items, skipped


if __name__ == "__main__":
    main(sys.argv[1])
