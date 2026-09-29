#!/usr/bin/env python3
"""Apply a palette colour map (old hex -> new hex) to hard-coded colours in code.

The map is art/od-sevev/palette-v3-map.json (the 2D Artist's palette v3, Bar's "Israel's palette, blue
and white"): top-level "#rrggbb": "#rrggbb" pairs; keys starting with "_" are notes and are ignored.

It rewrites three literal forms, keeping everything else on the line:
  - "#rrggbb" and "#rrggbbaa" (GDScript strings, CSS): the rgb part is replaced, a trailing alpha kept;
  - GDScript float colours Color(r, g, b) / Color(r, g, b, a) with decimal components, when every
    channel is within 1/255 of a mapped old colour: rewritten with the new colour at 3 decimals,
    alpha kept (Color(1, 1, 1) style integer literals and neutral modulates never match);
  - nothing else (Color8, named colours and computed colours are reported by --scan, not touched).

Usage (from the repo root):
  python3 tools/apply_palette_map.py                 # dry run over the default targets: prints file:line old -> new
  python3 tools/apply_palette_map.py --write         # apply in place
  python3 tools/apply_palette_map.py --check         # exit 1 if any mapped old colour is still in the targets
  python3 tools/apply_palette_map.py --scan          # also list every colour literal the map leaves alone
  python3 tools/apply_palette_map.py --refresh-notes # rewrite the map's "_sites" note from the current code
  python3 tools/apply_palette_map.py [--map M] [paths ...]   # other targets (files or directories)

Default targets: game/scripts/**/*.gd and game/web/shell.html.
"""
import argparse
import glob
import json
import os
import re
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
DEFAULT_MAP = os.path.join(ROOT, "art", "od-sevev", "palette-v3-map.json")
DEFAULT_TARGETS = ["game/scripts", "game/web/shell.html"]
EXTS = (".gd", ".html", ".css", ".js", ".tscn", ".tres", ".godot")

HEX_RE = re.compile(r"#([0-9a-fA-F]{6})([0-9a-fA-F]{2})?(?![0-9a-fA-F])")
NUM = r"(?:\d+\.\d*|\.\d+|\d+)"
COLOR_RE = re.compile(r"Color\(\s*(" + NUM + r")\s*,\s*(" + NUM + r")\s*,\s*(" + NUM + r")\s*(,\s*" + NUM + r"\s*)?\)")


def load_map(path):
    raw = json.load(open(path))
    m = {}
    for k, v in raw.items():
        if k.startswith("_"):
            continue
        if not (re.fullmatch(r"#[0-9a-fA-F]{6}", k) and re.fullmatch(r"#[0-9a-fA-F]{6}", v)):
            raise SystemExit(f"bad map entry {k!r}: {v!r} (want '#rrggbb': '#rrggbb')")
        m[k.lower()] = v.lower()
    return raw, m


def rgb(h):
    return tuple(int(h[i:i + 2], 16) for i in (1, 3, 5))


def targets(paths):
    out = []
    for p in paths:
        a = p if os.path.isabs(p) else os.path.join(ROOT, p)
        if os.path.isdir(a):
            for f in sorted(glob.glob(os.path.join(a, "**", "*"), recursive=True)):
                if f.endswith(EXTS) and os.path.isfile(f):
                    out.append(f)
        elif os.path.isfile(a):
            out.append(a)
        else:
            print(f"skip (missing): {p}", file=sys.stderr)
    return out


def float_match(parts, m):
    """The mapped old hex a Color(r, g, b) float literal stands for, or None."""
    if not all("." in p for p in parts):           # integer literals (Color(1, 1, 1)) are never palette colours here
        return None
    vals = [float(p) * 255 for p in parts]
    if any(v < 0 or v > 255.5 for v in vals):
        return None
    for old in m:
        if all(abs(v - c) <= 1.0 for v, c in zip(vals, rgb(old))):
            return old
    return None


def fmt(c):
    s = f"{c / 255:.3f}".rstrip("0")
    return s + "0" if s.endswith(".") else s


def rewrite_line(line, m):
    hits = []

    def hx(mo):
        old = "#" + mo.group(1).lower()
        if old not in m:
            return mo.group(0)
        new = m[old]
        new = new.upper() if mo.group(1).isupper() else new
        hits.append((mo.group(0), new + (mo.group(2) or "")))
        return new + (mo.group(2) or "")

    def fl(mo):
        old = float_match(mo.groups()[:3], m)
        if old is None:
            return mo.group(0)
        r, g, b = rgb(m[old])
        alpha = mo.group(4) or ""
        new = f"Color({fmt(r)}, {fmt(g)}, {fmt(b)}{alpha.rstrip()})"
        hits.append((mo.group(0), new + f"  [{old} -> {m[old]}]"))
        return new

    line = HEX_RE.sub(hx, line)
    line = COLOR_RE.sub(fl, line)
    return line, hits


def scan_others(line, m):
    """Colour literals on the line that the map leaves alone."""
    found = []
    for mo in HEX_RE.finditer(line):
        if "#" + mo.group(1).lower() not in m:
            found.append(mo.group(0))
    for mo in COLOR_RE.finditer(line):
        if float_match(mo.groups()[:3], m) is None:
            found.append(mo.group(0))
    return found


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("paths", nargs="*", default=DEFAULT_TARGETS)
    ap.add_argument("--map", default=DEFAULT_MAP)
    ap.add_argument("--write", action="store_true", help="apply in place (default: dry run)")
    ap.add_argument("--check", action="store_true", help="exit 1 if a mapped old colour remains")
    ap.add_argument("--scan", action="store_true", help="also list unmapped colour literals")
    ap.add_argument("--refresh-notes", action="store_true", help="rewrite the map's _sites note")
    a = ap.parse_args()
    raw, m = load_map(a.map)
    files = targets(a.paths)
    total, per_file, sites, others = 0, {}, {}, []
    for f in files:
        rel = os.path.relpath(f, ROOT)
        lines = open(f, encoding="utf-8").read().split("\n")
        changed = False
        for i, line in enumerate(lines):
            new, hits = rewrite_line(line, m)
            for old, rep in hits:
                total += 1
                per_file[rel] = per_file.get(rel, 0) + 1
                key = old.lower()[:7] if old.startswith("#") else rep.split("[")[1].split(" ")[0]
                sites.setdefault(key, []).append(f"{rel}:{i + 1}")
                if not a.refresh_notes:
                    print(f"{rel}:{i + 1}: {old} -> {rep}")
            if new != line:
                lines[i] = new
                changed = True
            if a.scan:
                others += [f"{rel}:{i + 1}: {o}" for o in scan_others(line, m)]
        if changed and a.write:
            open(f, "w", encoding="utf-8").write("\n".join(lines))
    if a.scan:
        print("\n-- colour literals the map leaves alone (review: neutral, alert, money, receipt or non-chrome) --")
        for o in others:
            print(o)
    if a.refresh_notes:
        raw["_sites"] = {k: v for k, v in sorted(sites.items())}
        raw["_siteCount"] = total
        json.dump(raw, open(a.map, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
        open(a.map, "a").write("\n")
        print(f"_sites: {total} sites in {len(per_file)} files written to {os.path.relpath(a.map, ROOT)}")
        return 0
    verb = "rewrote" if a.write else "would rewrite"
    print(f"\n{verb} {total} colour literals in {len(per_file)} files" +
          ("" if a.write else " (dry run; --write to apply)"))
    for rel, n in sorted(per_file.items()):
        print(f"  {n:3d}  {rel}")
    if a.check and total and not a.write:
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
