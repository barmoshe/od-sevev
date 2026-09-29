#!/usr/bin/env python3
"""עוד סבב art pipeline: one command from the DCC sources to what Godot loads.

  python3 pipeline/od-sevev/build.py              refs -> render -> drift check -> import sprites + font + proofs
  python3 pipeline/od-sevev/build.py --no-render  import the approved showcase out/ as-is (about 5 s)
  python3 pipeline/od-sevev/build.py --godot      also run Godot's import, measure the .ctex bytes the
                                                  web .pck will carry, and render the font specimen through
                                                  Godot's TextServer (opens a small window for ~2 s)
  --allow-drift   import a render whose pixels differ from the approved out/ (default: fail)

Also imports the 2D Artist's UI kit (art/od-sevev/ui-kit.json) and app-icon master as-is.

Sources (read only): the creative pack at $ODS_CREATIVE_PACK, default
  gamestudio/output/artifacts/creative-pack/od-sevev/  (art/refs, art/showcase/src, art/src).
Outputs: game/assets/sprites/**, game/assets/fonts/**, pipeline/od-sevev/proofs/**, budget.json.
Needs: python3 with Pillow and numpy; Godot 4.7.2 via tools/godot.sh for --godot.
"""
import argparse, glob, json, os, re, shutil, subprocess, sys, tempfile, time
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
sys.dont_write_bytecode = True          # keep __pycache__ out of the repo
sys.path.insert(0, HERE)
import font as F
import sprites as S

FORK = S.FORK
GAME = os.path.join(FORK, "game")
FONT_DEST = os.path.join(GAME, "assets", "fonts")
PROOFS = os.path.join(HERE, "proofs")
BMFONT_PARAMS = {"scaling_mode": "1", "compress": "true"}   # integer-only scaling; zstd the .fontdata (lossless)


def log(msg):
    print(msg, flush=True)


def build_font():
    font = F.parse()
    for line in F.check(font):
        log("font: " + line)
    # content coverage: every glyph the game's strings use (keys starting with "_" are docs)
    have = set(font["glyphs"]) | set(font["aliases"]) | set(font["zeros"]) | {0x20, 0x0A}

    def walk(o, path):
        if isinstance(o, str):
            yield path, o
        elif isinstance(o, dict):
            for k, v in o.items():
                if not str(k).startswith("_"):
                    yield from walk(v, f"{path}.{k}")
        elif isinstance(o, list):
            for i, v in enumerate(o):
                yield from walk(v, f"{path}[{i}]")
    for rel in ("ux/ui-strings.json", "design/content.json"):
        fp = os.path.join(FORK, rel)
        if not os.path.exists(fp):
            continue
        miss = {}
        for path, s in walk(json.load(open(fp, encoding="utf-8")), ""):
            for ch in s:
                if ord(ch) not in have:
                    miss.setdefault(ch, path)
        log(f"font: {rel}: " + ("every character covered" if not miss else
            "WARN no glyph for " + ", ".join(f"U+{ord(c):04X} {c!r} (e.g. {p})" for c, p in miss.items())))
    os.makedirs(FONT_DEST, exist_ok=True)
    stats = []
    for name, outline in (("sevev9", False), ("sevev9_outline", True)):
        st = F.build(font, FONT_DEST, name, outline)
        S.write_import(os.path.join(FONT_DEST, name + ".fnt"), "font_data_bmfont", "FontFile", BMFONT_PARAMS)
        stats.append(st)
        log(f"font: {name}.fnt + .png page {st['page'][0]}x{st['page'][1]}, {st['chars']} chars")
    return font, stats


# ------------------------------------------------------------------ proofs
def _text(img, font, text, x, y, scale, color=(255, 255, 255, 255)):
    """Proof-only LTR blitter (used for hex labels and Latin); Hebrew proofs go through Godot."""
    g, al, sp = font["glyphs"], font["aliases"], font["space"]
    for ch in text:
        cp = ord(ch)
        src = cp if cp in g else al.get(cp)
        if src in g:
            rows = g[src]
            for j, r in enumerate(rows):
                for i, c in enumerate(r):
                    if c == "#":
                        for dy in range(scale):
                            for dx in range(scale):
                                img.putpixel((x + (i) * scale + dx, y + j * scale + dy), color)
            x += (len(rows[0]) + 1) * scale
        else:
            x += (sp + 1) * scale


def proof_glyphs(font):
    g = font["glyphs"]
    cps = sorted(g)
    cols, cw, ch = 12, 58, 66
    rows = (len(cps) + cols - 1) // cols
    img = Image.new("RGBA", (cols * cw + 8, rows * ch + 8), (42, 35, 64, 255))
    for k, cp in enumerate(cps):
        x, y = 4 + (k % cols) * cw, 4 + (k // cols) * ch
        for yy in range(y, y + ch - 4):
            for xx in range(x, x + cw - 4):
                img.putpixel((xx, yy), (27, 20, 38, 255))
        # the glyph at x4 with its advance box
        gx, gy = x + 6, y + 4
        w = len(g[cp][0])
        for j, r in enumerate(g[cp]):
            for i, c in enumerate(r):
                col = (247, 244, 236, 255) if c == "#" else ((60, 52, 84, 255) if 2 <= j <= 6 else (44, 38, 62, 255))
                for dy in range(4):
                    for dx in range(4):
                        img.putpixel((gx + i * 4 + dx, gy + j * 4 + dy), col)
        _text(img, font, f"{cp:04X}", x + 4, y + 44, 2, (245, 197, 66, 255))
    p = os.path.join(PROOFS, "font-glyphs.png")
    img.save(p)
    return p


def _frame(tex, spec, i=0):
    """Frame i of a strip or grid (sprites.json layout; `frameMap` picks the texture cell)."""
    cols = spec.get("cols", spec.get("frames", 1))
    fw, fh = spec["frameW"], spec["frameH"]
    c = spec["frameMap"][i] if "frameMap" in spec else i
    x, y = (c % cols) * fw, (c // cols) * fh
    return tex.crop((x, y, x + fw, y + fh))


def proof_cast(manifest, Z=3):
    """Everything on one sheet at ART x Z (a density-d texture at Z/d per sprite px), so the cast's 3x
    detail and the 1x stage, props and UI sit on one grid, the way the renderer will draw them."""
    D_ = S.DEST
    load = lambda sid: Image.open(os.path.join(D_, sid + ".png")).convert("RGBA")
    up = lambda im, d: im.resize((im.width * Z // d, im.height * Z // d), Image.NEAREST)
    chars = manifest["chars"]
    per_row, cell_w, cell_h = 8, 90 * Z, 150 * Z
    rows = -(-len(chars) // per_row)
    W = 180 * Z + 8 * Z + per_row * cell_w
    Hh = max(320 * Z, rows * cell_h) + 60 * Z
    img = Image.new("RGBA", (W, Hh), (27, 20, 38, 255))
    img.alpha_composite(up(load(manifest["stages"]["balfour"]["sprite"]), 1), (0, 0))
    b = chars.get("bibi")
    if b:
        d = b["density"]
        fr = up(_frame(Image.open(os.path.join(D_, b["anims"]["idle"]["texture"])).convert("RGBA"), {**b, **b["anims"]["idle"]}), d)
        fx, fy = manifest["magicianFeet"]
        img.alpha_composite(fr, (fx * Z - b["anchor"][0] * Z // d, fy * Z - b["anchor"][1] * Z // d))
    for k, (n, c) in enumerate(chars.items()):
        d = c["density"]
        cx = 180 * Z + 8 * Z + (k % per_row) * cell_w + cell_w // 2
        base = (k // per_row) * cell_h + 112 * Z
        fr = up(_frame(Image.open(os.path.join(D_, c["anims"]["idle"]["texture"])).convert("RGBA"), {**c, **c["anims"]["idle"]}), d)
        img.alpha_composite(fr, (cx - c["anchor"][0] * Z // d, base - c["anchor"][1] * Z // d))   # feet on one baseline
        if "avatar" in c:
            av = up(load(c["avatar"]), 1)
            img.alpha_composite(av, (cx - av.width // 2, base + 2 * Z))
    x, y = 4 * Z, max(320 * Z, rows * cell_h) + 4 * Z
    for sid, s in sorted(manifest.get("sources", {}).items()):
        strip = load(s["sprite"])
        for i in range(2):
            fr = up(_frame(strip, s, i), s.get("density", 1))
            img.alpha_composite(fr, (x, y))
            x += fr.width + Z
        x += 6 * Z
    for sid in manifest["props"].values():
        im = up(load(sid), 1)
        img.alpha_composite(im, (x, y))
        x += im.width + 4 * Z
    p = os.path.join(PROOFS, "sprites-contact.png")
    img.save(p)
    return p


def proof_stage(manifest, Z=6, density=None, char="bibi", anim="crit", frame=6):
    """A character on the stage at ART xZ, the way SpriteStrip picks it for k = Z: the main render
    (d 3 at x6: sprite px x2) or a `densities` alternate (d 2 at x4: sprite px x2)."""
    D_ = S.DEST
    st = Image.open(os.path.join(D_, manifest["stages"]["balfour"]["sprite"] + ".png")).convert("RGBA")
    img = st.resize((180 * Z, 320 * Z), Image.NEAREST)
    c = manifest["chars"][char]
    if density is not None and density != c["density"]:
        c = {**c, **c["densities"][str(density)]}
    d = c["density"]
    fr = _frame(Image.open(os.path.join(D_, c["anims"][anim]["texture"])).convert("RGBA"), {**c, **c["anims"][anim]}, frame)
    fr = fr.resize((fr.width * Z // d, fr.height * Z // d), Image.NEAREST)
    fx, fy = manifest["magicianFeet"]
    img.alpha_composite(fr, (fx * Z - c["anchor"][0] * Z // d, fy * Z - c["anchor"][1] * Z // d))
    p = os.path.join(PROOFS, f"stage-x{Z}-{char}" + (f"-d{d}" if density is not None else "") + ".png")
    img.save(p)
    return p


# ------------------------------------------------------------------ Godot: import, bytes, specimen
GODOT = os.path.join(FORK, "tools", "godot.sh")

SPECIMEN_LINES = [
    "אבגדהוזחטיכךלמםנןסעפףצץקרשת",
    "עוד סבב",
    "סבב בחירות מס׳ 6. הציבור נרגש.",
    "⁦+1.2K⁩ ₪ לשנייה",
    "סגרנו · ⁦12,400⁩ ₪",
    "מע״מ 18%* · סה״כ · יועמ״ש · ו־3",
    "הליכוד ← עוצמה יהודית",
    "(בית המשפט) [טיוטה] {שם}",
    "לא יהיה כלום כי אין כלום…",
    "DOHA · OK · 1.2K 3M 4B 5T · +12 − 3 × 2 = 30",
    "#$&@\\^_`|~;:!? 0123456789 – —",
]

SPECIMEN_GD = r'''extends SceneTree
# Renders the Sevev 9 specimen through Godot's TextServer (bidi, per-glyph advances) and dumps
# each line's VISUAL glyph order (the glyph actually drawn, so mirrored brackets show as such)
# so direction is verified as data, not by eye.
var vp: SubViewport
var frames := 0
func _label(host: Control, font: FontFile, size: int, text: String, y: int, color: Color, x := 12, w := 736) -> void:
	var l := Label.new()
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.text_direction = Control.TEXT_DIRECTION_RTL          # the paragraph is RTL (bidi base level 1)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	l.text = text
	l.position = Vector2(x, y)
	l.size = Vector2(w, size * 11 / 9)
	host.add_child(l)
func _initialize() -> void:
	var lines: Array = JSON.parse_string(FileAccess.get_file_as_string("res://lines.json"))
	var plain: FontFile = load("res://sevev9.fnt")
	var outl: FontFile = load("res://sevev9_outline.fnt")
	vp = SubViewport.new()
	vp.size = Vector2i(760, 1320)
	vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var host := Control.new(); host.size = Vector2(760, 1320); vp.add_child(host)
	var bg := ColorRect.new(); bg.color = Color("#2a2340"); bg.size = host.size; host.add_child(bg)
	var y := 10
	for sp in [[18, lines.size()], [27, 5], [36, 3]]:
		for i in sp[1]:
			_label(host, plain, sp[0], lines[i], y, Color.WHITE)
			y += sp[0] * 11 / 9 + 2
		y += 10
	var st := TextureRect.new(); st.texture = load("res://stage.png"); st.position = Vector2(200, y)
	st.scale = Vector2(2, 2); host.add_child(st)
	_label(host, outl, 45, "עוד סבב!", y + 40, Color("#f5c542"), 200, 360)
	_label(host, outl, 27, "סבב בחירות מס׳ 6", y + 110, Color.WHITE, 200, 360)
	_label(host, plain, 18, "\u2066+1.2K\u2069\u00a0₪ לשנייה", y + 150, Color("#f5c542"), 200, 360)
	var ts := TextServerManager.get_primary_interface()
	var dump := []
	for s in lines:
		var rid := ts.create_shaped_text(TextServer.DIRECTION_RTL)
		ts.shaped_text_add_string(rid, s, plain.get_rids(), 9)
		var vis := ""
		var w := 0.0
		var tofu := 0
		for g in ts.shaped_text_get_glyphs(rid):
			w += g["advance"]
			var idx: int = g["index"]
			if not (g["font_rid"] as RID).is_valid():
				var c: int = String(s).unicode_at(g["start"])
				if c > 0x20 and not (c >= 0x2066 and c <= 0x2069) and c != 0xA0:
					tofu += 1
					vis += "□"
				continue
			vis += String.chr(idx) if idx > 0x20 else " "
		dump.append({"visual": vis, "width": w, "tofu": tofu})
		ts.free_rid(rid)
	FileAccess.open("res://visual.json", FileAccess.WRITE).store_string(JSON.stringify(dump))
	print("server: ", ts.get_name())
func _process(_d: float) -> bool:
	frames += 1
	if frames == 4:
		vp.get_texture().get_image().save_png("res://specimen.png")
		return true
	return false
'''


def godot(args, cwd=None, timeout=300):
    return subprocess.run([GODOT] + args, cwd=cwd, capture_output=True, text=True, timeout=timeout)


def godot_import():
    r = godot(["--headless", "--path", GAME, "--import"], timeout=600)
    if r.returncode != 0:
        raise RuntimeError("godot --import failed:\n" + r.stdout[-2000:] + r.stderr[-2000:])


def measure(manifest):
    """Bytes the web .pck carries for our assets: the imported .ctex/.fontdata files."""
    rows = []
    roots = [(S.DEST, "sprites"), (FONT_DEST, "fonts")]
    for root, label in roots:
        for ip in sorted(glob.glob(os.path.join(root, "**", "*.import"), recursive=True)):
            if not os.path.exists(ip[:-len(".import")]):   # an orphan .import (its PNG was retired): drop it
                os.remove(ip)
                continue
            txt = open(ip).read()
            if 'importer="skip"' in txt:      # a BMFont page: Godot embeds it in the .fontdata
                rows.append({"file": os.path.relpath(ip[:-len(".import")], GAME), "source": os.path.getsize(ip[:-7]),
                             "imported": 0, "note": "embedded in the .fontdata"})
                continue
            m = re.search(r'dest_files=\["res://([^"]+)"', txt)
            src = ip[:-len(".import")]
            dst = os.path.join(GAME, m.group(1)) if m else None
            rows.append({"file": os.path.relpath(src, GAME), "source": os.path.getsize(src),
                         "imported": os.path.getsize(dst) if dst and os.path.exists(dst) else None})
    return rows


def specimen(font_dir):
    tmp = tempfile.mkdtemp(prefix="ods-specimen-")
    for f in os.listdir(font_dir):
        if f.endswith((".fnt", ".png", ".import")):
            shutil.copy(os.path.join(font_dir, f), tmp)
    for f in os.listdir(tmp):          # drop Godot's uid/dest lines so the temp project re-imports cleanly
        if f.endswith(".import"):
            txt = open(os.path.join(tmp, f)).read()
            txt = "\n".join(l for l in txt.split("\n") if not l.startswith(("uid=", "path=", "dest_files=", "source_file=")))
            open(os.path.join(tmp, f), "w").write(txt)
    shutil.copy(os.path.join(S.DEST, "stage_balfour.png"), os.path.join(tmp, "stage.png"))
    S.write_import(os.path.join(tmp, "stage.png"), "texture", "CompressedTexture2D", S.TEX_PARAMS)
    open(os.path.join(tmp, "project.godot"), "w").write(
        'config_version=5\n[application]\nconfig/name="specimen"\n[display]\nwindow/size/viewport_width=64\n'
        'window/size/viewport_height=64\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n'
        'textures/canvas_textures/default_texture_filter=0\n')
    json.dump(SPECIMEN_LINES, open(os.path.join(tmp, "lines.json"), "w"), ensure_ascii=False)
    open(os.path.join(tmp, "specimen.gd"), "w").write(SPECIMEN_GD)
    r = godot(["--headless", "--path", tmp, "--import"])
    r = godot(["--path", tmp, "--rendering-driver", "opengl3", "-s", "res://specimen.gd"], timeout=120)
    out = os.path.join(tmp, "specimen.png")
    if not os.path.exists(out):
        raise RuntimeError("specimen render failed:\n" + r.stdout[-3000:] + r.stderr[-3000:])
    shutil.copy(out, os.path.join(PROOFS, "font-specimen-godot.png"))
    vis = json.load(open(os.path.join(tmp, "visual.json"), encoding="utf-8"))
    return os.path.join(PROOFS, "font-specimen-godot.png"), vis, r.stdout


# ------------------------------------------------------------------ main
def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--no-render", action="store_true")
    ap.add_argument("--allow-drift", action="store_true")
    ap.add_argument("--godot", action="store_true")
    a = ap.parse_args()
    t0 = time.time()
    os.makedirs(PROOFS, exist_ok=True)

    if a.no_render:
        src = S.APPROVED_OUT
        log(f"sprites: importing the approved out/ as-is: {src}")
    else:
        src = S.render(log)
        changed, new, old = S.drift(src)
        log(f"drift vs approved out/: {len(changed)} changed, {len(new)} new, {len(old)} only in approved")
        for f in new:
            log(f"  new (not yet in approved out/): {f}")
        for f in old:
            log(f"  only in approved out/ (no ref or cast.py entry renders it): {f}")
        if changed:
            msg = "rendered pixels differ from the approved look:\n  " + "\n  ".join(changed)
            if not a.allow_drift:
                raise SystemExit("FAIL " + msg + "\n(re-run with --allow-drift only if Bar approved the change)")
            log("WARN " + msg)

    refs = {os.path.basename(p): S.sha(p) for p in sorted(glob.glob(os.path.join(S.REFS, "*.png")))}
    provenance = {
        "refs": "ChatGPT reference images generated by Bar (conversation 'יצירת דמות בפיקסל ארט'), "
                "first-party; no third-party licence",
        "refShas": refs,
        "renderDown": "creative-pack art/showcase/src (rig.py, build.py, cast.py)",
        "stagesAndWordmark": "creative-pack art/src (locations.py, wordmark.py)",
        "renderedFrom": "refs" if not a.no_render else "approved out/",
    }
    manifest, warns = S.import_sprites(src, log, provenance)
    if not a.no_render:                       # the staging copy is disposable once imported
        shutil.rmtree(os.path.abspath(os.path.join(src, "..", "..", "..")), ignore_errors=True)
    icons = S.import_icons(log)
    log(f"sprites: {len(manifest['chars'])} characters, {len(manifest['props'])} props, "
        f"{len(manifest['stages'])} stages -> {S.DEST}")

    font, fstats = build_font()
    log("proof: " + proof_glyphs(font))
    log("proof: " + proof_cast(manifest))
    log("proof: " + proof_stage(manifest))
    for dk in manifest["chars"].get("bibi", {}).get("densities", {}):
        z = next(k for k in (4, 2, 8) if k % int(dk) == 0)      # the phone scale the alternate is for
        log("proof: " + proof_stage(manifest, Z=z, density=int(dk)))

    budget = {"sourceBytes": {}, "vramBytes": 0}
    for rel, f in manifest["files"].items():
        budget["sourceBytes"][f"sprites/{rel}"] = f["bytes"]
        budget["vramBytes"] += f["size"][0] * f["size"][1] * 4
    for st in fstats:
        p = os.path.join(FONT_DEST, st["name"] + ".png")
        budget["sourceBytes"][f"fonts/{st['name']}.png"] = os.path.getsize(p)
        budget["sourceBytes"][f"fonts/{st['name']}.fnt"] = os.path.getsize(os.path.join(FONT_DEST, st["name"] + ".fnt"))
        budget["vramBytes"] += st["page"][0] * st["page"][1] * 4

    # typical resident set (lazy per-character loading): the Magician's strips, one stage, the small Dubi,
    # every money source, the UI kit, avatars, props/FX and the fonts. Partners load when their scene opens.
    def resident(rel):
        n = os.path.basename(rel)
        return (n.startswith(("stage_balfour", "dubi_small_", "source_", "avatar", "prop_", "fx_"))
                or os.path.splitext(n)[0] in manifest["ui"])
    tex = lambda rel: manifest["files"][rel]["size"][0] * manifest["files"][rel]["size"][1] * 4
    # the Magician: SpriteStrip loads only the render pick_variant picks for the device's k, so one
    # of his densities is resident at a time (d 2 at k 2/4/8, d 3 at k 6/9 and on the "aa" path at k 7)
    bibi = manifest["chars"].get("bibi", {})
    bibi_sets = {str(bibi.get("density", 1)): {a["texture"] for a in bibi.get("anims", {}).values()}}
    bibi_sets.update({k: {a["texture"] for a in v["anims"].values()} for k, v in bibi.get("densities", {}).items()})
    budget["vramBibi"] = {k: sum(tex(r) for r in s) for k, s in bibi_sets.items()}
    base = sum(tex(rel) for rel in manifest["files"] if resident(rel)) + sum(st["page"][0] * st["page"][1] * 4 for st in fstats)
    budget["vramTypicalByBibiDensity"] = {k: base + v for k, v in budget["vramBibi"].items()}
    budget["vramTypical"] = max(budget["vramTypicalByBibiDensity"].values())      # the worst k
    budget["vramCastAll"] = sum(tex(rel) for rel in manifest["files"] if rel.startswith("cast/"))
    budget["vramPerPartner"] = {n: sum(manifest["files"][c["anims"][k]["texture"]]["size"][0] *
                                       manifest["files"][c["anims"][k]["texture"]]["size"][1] * 4 for k in c["anims"])
                                for n, c in manifest["chars"].items() if n != "bibi"}
    if a.godot:
        godot_import()
        rows = measure(manifest)
        budget["imported"] = rows
        budget["pckBytes"] = sum(r["imported"] or 0 for r in rows)
        missing = [r["file"] for r in rows if r["imported"] is None]
        if missing:
            raise SystemExit("FAIL Godot did not import: " + ", ".join(missing))
        # the import pass rewrote the .import files: re-assert our params (idempotent)
        for rel in manifest["files"]:
            S.write_import(os.path.join(S.DEST, rel), "texture", "CompressedTexture2D", S.TEX_PARAMS)
        for st in fstats:
            S.write_import(os.path.join(FONT_DEST, st["name"] + ".fnt"), "font_data_bmfont", "FontFile", BMFONT_PARAMS)
        p, vis, out = specimen(FONT_DEST)
        log("proof: " + p)
        budget["specimenVisual"] = vis
        tofu = [v["visual"] for v in vis if v["tofu"]]
        if tofu:
            raise SystemExit("FAIL tofu (missing glyph) in the Godot specimen: " + " | ".join(tofu))
        for line, v in zip(SPECIMEN_LINES, vis):
            exp = F.advance_of(font, line) + 1
            if abs(v["width"] / 1 - exp) > 0.01:
                log(f"WARN width mismatch '{line}': godot {v['width']} vs table {exp}")

    budget["sourceTotal"] = sum(budget["sourceBytes"].values())
    json.dump(budget, open(os.path.join(HERE, "budget.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    log(f"budget: source {budget['sourceTotal']:,} B, VRAM typical {budget['vramTypical']:,} B "
        f"(by Bibi density {budget['vramTypicalByBibiDensity']}; cast all {budget['vramCastAll']:,} B; "
        f"all resident {budget['vramBytes']:,} B)"
        + (f", web .pck {budget['pckBytes']:,} B" if "pckBytes" in budget else ""))
    log(f"done in {time.time() - t0:.1f}s" + (f" with {len(warns)} waived warnings" if warns else ""))


if __name__ == "__main__":
    main()
