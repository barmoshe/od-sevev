#!/usr/bin/env python3
"""Templates the od-sevev HTML surfaces (N1 disclaimer, N0 splash, hand-off bar, O8 About) into
the exported build/web/index.html (ux/rtl-map.md §9: strings with surface "html" are templated
at export, <noscript> included).

    python3 tools/lib/render_shell.py build/web/index.html

{{KEY}}     -> ux/ui-strings.json strings[KEY], HTML-escaped
{{KEY_JS}}  -> the same, escaped for a single-quoted JS string
{{DISC_BY_HTML}}        -> DISC_BY with {publisher}/{mail} from OD_PUBLISHER / OD_CONTACT_MAIL
                           (empty segments dropped) and "אודות" as the About link
{{ABOUT_SOURCES_LIST}}  -> design/facts.json facts as <li> with "למקור" links
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

    items = []
    link_word = html.escape(ui.get("ABOUT_SOURCE_LINK", "למקור"))
    for f in facts:
        meta = " · ".join(x for x in [f.get("outlet") or "", f.get("date") or ""] if x)
        link = ' <a href="%s" target="_blank" rel="noopener">%s</a>' % (html.escape(f["url"]), link_word) if f.get("url") else ""
        items.append('<li dir="auto">%s<br><span class="od-src">%s</span>%s</li>' % (html.escape(f.get("text", "")), html.escape(meta), link))
    src = src.replace("{{ABOUT_SOURCES_LIST}}", "\n".join(items))

    def js(k):
        return ui.get(k, "").replace("\\", "\\\\").replace("'", "\\'")

    src = re.sub(r"\{\{([A-Z0-9_]+)_JS\}\}", lambda m: js(m.group(1)), src)
    src = re.sub(r"\{\{([A-Z0-9_]+)\}\}", lambda m: esc(m.group(1)) if m.group(1) in ui else m.group(0), src)
    left = sorted(set(re.findall(r"\{\{[A-Z0-9_]+\}\}", src)))
    if left:
        sys.exit("render_shell: unknown keys %s" % ", ".join(left))
    open(path, "w", encoding="utf-8").write(src)
    print("render_shell: templated %s (%d sources)" % (os.path.relpath(path, ROOT), len(items)))


if __name__ == "__main__":
    main(sys.argv[1])
