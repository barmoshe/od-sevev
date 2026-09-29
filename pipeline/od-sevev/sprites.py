"""Sprite stages: render-down (refs -> strips), drift check against the approved out/, and import into
game/assets/sprites/ with a manifest (sprites.json) the engine's SpriteStrip player reads.

Everything the import writes is derived; the sources are the creative pack's refs + render scripts.
"""
import hashlib, json, os, re, shutil, subprocess, sys, tempfile
import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
FORK = os.path.abspath(os.path.join(HERE, "..", ".."))
# The creative pack: $ODS_CREATIVE_PACK, else a copy inside the fork (the standalone od-sevev repo),
# else the studio layout (gamestudio/output/artifacts/creative-pack/od-sevev).
_LOCAL_PACK = os.path.join(FORK, "creative-pack")
CREATIVE = os.path.abspath(os.environ.get(
    "ODS_CREATIVE_PACK", _LOCAL_PACK if os.path.isdir(_LOCAL_PACK)
    else os.path.join(FORK, "..", "..", "artifacts", "creative-pack", "od-sevev")))
SHOWCASE = os.path.join(CREATIVE, "art", "showcase")
APPROVED_OUT = os.path.join(SHOWCASE, "out")
ART_SRC = os.path.join(CREATIVE, "art", "src")
REFS = os.path.join(CREATIVE, "art", "refs")
DEST = os.path.join(FORK, "game", "assets", "sprites")
ICON_DEST = os.path.join(FORK, "game", "assets", "icon")
KIT_ROOT = os.path.join(FORK, "art", "od-sevev")          # the 2D Artist's slice (read only here)
KIT = os.path.join(KIT_ROOT, "ui-kit.json")
ICON_MASTER = os.path.join(KIT_ROOT, "out", "key", "icon-64-art.png")
# every size the export presets name (game/export_presets.cfg), from the 64 art-px master, nearest
ICON_SIZES = {"icon_1024.png": 1024, "pwa_512.png": 512, "pwa_180.png": 180, "pwa_144.png": 144,
              "android_192.png": 192, "android_fg_432.png": 432}

ERAS = ["balfour", "knesset", "courthouse", "washington"]
# The Magician stands with his feet here on every stage (art px), per the approved showcase
# (template.html bibiPos: x 94, floor 220 -> feet row 219) and locations.py's floor at y 216-230.
MAGICIAN_FEET = [94, 219]
MAX_TEX = 2048   # WebGL2's guaranteed MAX_TEXTURE_SIZE (the web export's floor)
POINT_TRACKS = ("hatMouth", "temple")   # per-frame [x, y] tracks, re-based when a frame is trimmed

# Frames whose content touches column 0 or frameW-1 are clipped art. Named waivers only:
# anything new that touches an edge fails the build.
EDGE_WAIVERS = {}
# Characters shipped so the engine can wire them, but whose art is known not to meet the bar yet.
PLACEHOLDERS = {
    "dubi": "18-px render-down: the beak, eye and claws fall below one art px (76 ref px per ap), so talk/squawk "
            "don't read. Frame counts, events and anchors are final; the pixels get replaced (STATUS). "
            "Removed automatically when the 2D Artist's hand-drawn strips are in the UI kit.",
}

TEX_PARAMS = {            # Godot 4.7 texture importer: pixel-perfect, lossless, no mipmaps, never VRAM-compressed
    "compress/mode": "0",
    "compress/high_quality": "false",
    "compress/lossy_quality": "0.7",
    "mipmaps/generate": "false",
    "mipmaps/limit": "-1",
    "process/fix_alpha_border": "true",
    "process/premult_alpha": "false",
    "process/size_limit": "0",
    "detect_3d/compress_to": "0",
}


# style-guide swatches used by the pipeline-owned FX sprites (sRGB, from creative-pack art/src/palette.py)
OD = {"white": (247, 244, 236, 255), "paper": (221, 213, 192, 255), "ink": (27, 20, 38, 255),
      "grey": (164, 169, 184, 255), "silver": (211, 214, 223, 255), "slate": (125, 131, 152, 255)}
_LEG = {"w": "white", "p": "paper", "k": "ink", "g": "grey", "s": "silver", "l": "slate"}
FX_SPRITES = {                       # art px; one PNG each (the fx player picks a random id per particle)
    "fx_slip": ["ww", "ww", "pp"],                   # a ballot slip, 2x3 (animator: ballotConfetti)
    "fx_slip_tilt": ["wwp", "wwp"],                  # the same slip turned
    "fx_ink": ["k"],                                 # stamp ink specks
    "fx_ink2": ["kk"],
    "fx_puff0": [".ss.", "sggs", ".gg."],            # floor dust (dustPuff), light on the dark floors
    "fx_puff1": [".s.", "sgg"],
}


def _grid(rows):
    im = Image.new("RGBA", (max(len(r) for r in rows), len(rows)), (0, 0, 0, 0))
    for y, r in enumerate(rows):
        for x, c in enumerate(r):
            if c != ".":
                im.putpixel((x, y), OD[_LEG[c]])
    return im


class SpriteError(Exception):
    pass


def sha(path):
    return hashlib.sha256(open(path, "rb").read()).hexdigest()[:16]


# ------------------------------------------------------------------ render (refs -> staging out/)
def render(log):
    """Re-render every strip, avatar and prop from the refs, plus the four stages, into a
    temporary copy of the showcase. Never writes into the creative pack."""
    stage = tempfile.mkdtemp(prefix="ods-render-")
    src = os.path.join(stage, "art", "showcase", "src")
    shutil.copytree(os.path.join(SHOWCASE, "src"), src, ignore=shutil.ignore_patterns("__pycache__", "*.html"))
    os.symlink(REFS, os.path.join(stage, "art", "refs"))
    log(f"render: {os.path.join(SHOWCASE, 'src', 'build.py')} (refs {REFS}) -> {stage}")
    subprocess.run([sys.executable, "build.py"], cwd=src, check=True, stdout=subprocess.DEVNULL)
    out = os.path.join(stage, "art", "showcase", "out")
    for era, im in render_stages().items():
        im.save(os.path.join(out, f"stage_{era}.png"))
    return out


def _creative_modules():
    if ART_SRC not in sys.path:
        sys.path.insert(0, ART_SRC)


def render_stages():
    _creative_modules()
    import locations
    return {era: getattr(locations, era)().to_image(1) for era in ERAS}


def drift(rendered, approved=APPROVED_OUT):
    """Compare a fresh render with the approved out/. Returns (changed, only_new, only_old)."""
    r = {f for f in os.listdir(rendered) if f.endswith(".png")}
    a = {f for f in os.listdir(approved) if f.endswith(".png")}
    changed = []
    for f in sorted(r & a):
        x = np.asarray(Image.open(os.path.join(rendered, f)).convert("RGBA"))
        y = np.asarray(Image.open(os.path.join(approved, f)).convert("RGBA"))
        if x.shape != y.shape or (x != y).any():
            changed.append(f)
    return changed, sorted(r - a), sorted(a - r)


# ------------------------------------------------------------------ validation
def _alpha(im):
    return np.asarray(im.convert("RGBA"))[:, :, 3]


def validate_char(name, d, src):
    errs, warns = [], []
    fw, fh = d["frameW"], d["frameH"]
    ax, ay = d["anchor"]
    if not (0 <= ax < fw and 0 <= ay < fh):
        errs.append(f"{name}: anchor {d['anchor']} outside the {fw}x{fh} frame")
    for anim, m in d["anims"].items():
        p = os.path.join(src, m["file"])
        if not os.path.exists(p):
            errs.append(f"{name}.{anim}: missing {m['file']}")
            continue
        im = Image.open(p)
        if im.size != (fw * m["frames"], fh):
            errs.append(f"{name}.{anim}: strip is {im.size}, expected {(fw * m['frames'], fh)}")
            continue
        a = _alpha(im)
        if ((a > 0) & (a < 255)).any():
            errs.append(f"{name}.{anim}: semi-transparent pixels (alpha must be 0 or 255)")
        edge = [i for i in range(m["frames"]) if a[:, i * fw].any() or a[:, i * fw + fw - 1].any()]
        if edge:
            msg = f"{name}.{anim}: content on the frame edge in frames {edge}"
            (warns if name in EDGE_WAIVERS else errs).append(msg + (f" [waived: {EDGE_WAIVERS[name]}]" if name in EDGE_WAIVERS else ""))
        for ev, fr in m.get("events", {}).items():
            if not 0 <= fr < m["frames"]:
                errs.append(f"{name}.{anim}: event {ev} at frame {fr} outside 0..{m['frames'] - 1}")
    return errs, warns


# ------------------------------------------------------------------ Godot import stubs
def write_import(path, importer, rtype, params):
    """Create <path>.import with our params, or patch the params of an existing one in place
    (keeping Godot's uid and dest paths)."""
    ip = path + ".import"
    if not os.path.exists(ip):
        body = [ "[remap]", "", f'importer="{importer}"', f'type="{rtype}"', "", "[params]", ""]
        body += [f"{k}={v}" for k, v in params.items()]
        open(ip, "w").write("\n".join(body) + "\n")
        return "new"
    lines = open(ip).read().split("\n")
    seen, changed = set(), False
    for i, ln in enumerate(lines):
        k = ln.split("=", 1)[0]
        if k in params:
            seen.add(k)
            if ln != f"{k}={params[k]}":
                lines[i] = f"{k}={params[k]}"
                changed = True
    missing = [k for k in params if k not in seen]
    if missing:
        lines = [l for l in lines if l != ""] + [f"{k}={params[k]}" for k in missing] + [""]
        changed = True
    if changed:
        open(ip, "w").write("\n".join(lines))
    return "patched" if changed else "ok"


# ------------------------------------------------------------------ import
def _previous_files():
    """Files the last run generated (from its sprites.json), plus their .import text (keeps uids)."""
    mp = os.path.join(DEST, "sprites.json")
    files = list(json.load(open(mp)).get("files", {})) if os.path.exists(mp) else []
    for legacy in ("pages", "stages", "ui"):            # layout of the first run of this pass
        root = os.path.join(DEST, legacy)
        if os.path.isdir(root):
            files += [f"{legacy}/{f}" for f in os.listdir(root) if f.endswith(".png")]
    root = os.path.join(DEST, "cast")
    if os.path.isdir(root):
        files += [f"cast/{f}" for f in os.listdir(root) if f.endswith(".png")]
    kept = {}
    for rel in set(files):
        ip = os.path.join(DEST, rel + ".import")
        if os.path.exists(ip):
            kept[os.path.basename(rel)] = open(ip).read()
    return sorted(set(files)), kept


def _remove(files):
    for rel in files:
        for p in (os.path.join(DEST, rel), os.path.join(DEST, rel + ".import")):
            if os.path.exists(p):
                os.remove(p)
    for d in ("pages", "stages", "ui", "cast"):
        root = os.path.join(DEST, d)
        if os.path.isdir(root) and not os.listdir(root):
            os.rmdir(root)


def _mode_color(row):
    vals, counts = np.unique(row.reshape(-1, 4), axis=0, return_counts=True)
    c = vals[counts.argmax()]
    return "#%02x%02x%02x" % tuple(int(v) for v in c[:3])


def import_sprites(src, log, provenance):
    atlas = json.load(open(os.path.join(src, "atlas.json")))
    errs, warns = [], []
    for name, d in atlas["chars"].items():
        e, w = validate_char(name, d, src)
        errs += e
        warns += w
    for k, p in atlas["props"].items():
        if not os.path.exists(os.path.join(src, p["file"])):
            errs.append(f"prop {k}: missing {p['file']}")
    for era in ERAS:
        p = os.path.join(src, f"stage_{era}.png")
        if not os.path.exists(p) or Image.open(p).size != (180, 320):
            errs.append(f"stage {era}: missing or not 180x320")
    for name in atlas["chars"]:
        p = os.path.join(src, f"{name}_avatar.png")
        if os.path.exists(p) and Image.open(p).size != (32, 32):
            errs.append(f"{name}_avatar.png is not 32x32")
    if errs:
        raise SpriteError("\n  ".join(["sprite validation failed:"] + errs))
    for w in warns:
        log("WARN " + w)

    old, kept = _previous_files()
    _remove(old)
    os.makedirs(os.path.join(DEST, "cast"), exist_ok=True)
    written = []

    def put(src_path, rel):
        shutil.copyfile(src_path, os.path.join(DEST, rel))     # byte-for-byte: same sha as the render
        written.append(rel)

    # cast strips (SpriteStrip): cast/<char>_<anim>.png, trimmed to the character's union box and
    # wrapped into a grid when a row would pass MAX_TEX (frame i at col i % cols, row i // cols)
    chars = {}
    for name, d in atlas["chars"].items():
        fw, fh = d["frameW"], d["frameH"]
        dens = d.get("density", 1)
        strips = {anim: np.asarray(Image.open(os.path.join(src, m["file"])).convert("RGBA")) for anim, m in d["anims"].items()}
        union = None                                        # the tightest box holding every frame of every anim
        for anim, arr in strips.items():
            for i in range(d["anims"][anim]["frames"]):
                ys, xs = np.nonzero(arr[:, i * fw:(i + 1) * fw, 3])
                if len(xs):
                    bb = [xs.min(), ys.min(), xs.max() + 1, ys.max() + 1]
                    union = bb if union is None else [min(union[0], bb[0]), min(union[1], bb[1]),
                                                      max(union[2], bb[2]), max(union[3], bb[3])]
        # 1 px of clear margin keeps the frame-edge rule; the feet row always stays inside
        x0, y0 = max(union[0] - 1, 0), max(union[1] - 1, 0)
        x1, y1 = min(union[2] + 1, fw), max(min(union[3] + 1, fh), d["anchor"][1] + 1)
        tw, th = x1 - x0, y1 - y0
        if tw > MAX_TEX or th > MAX_TEX:
            raise SpriteError(f"{name}: a trimmed frame is {tw}x{th}, over {MAX_TEX}")
        anims = {}
        for anim, m in d["anims"].items():
            n = m["frames"]
            cols = min(n, MAX_TEX // tw)
            rows = -(-n // cols)
            if rows * th > MAX_TEX:
                raise SpriteError(f"{name}.{anim}: {n} frames of {tw}x{th} don't fit a {MAX_TEX} grid")
            grid = np.zeros((rows * th, cols * tw, 4), np.uint8)
            for i in range(n):
                grid[(i // cols) * th:(i // cols + 1) * th, (i % cols) * tw:(i % cols + 1) * tw] = \
                    strips[anim][y0:y1, i * fw + x0:i * fw + x1]
            rel = f"cast/{m['file']}"
            Image.fromarray(grid, "RGBA").save(os.path.join(DEST, rel), optimize=True)
            written.append(rel)
            a = {"texture": rel, "frames": n, "fps": m["fps"], "loop": m["loop"], "events": m.get("events", {}),
                 "density": m.get("density", dens), "cols": cols, "rows": rows}
            for k, v in m.items():                          # hatMouth, temple, ...: into the trimmed frame
                if k in ("file", "frames", "fps", "loop", "events", "density"):
                    continue
                a[k] = [[p[0] - x0, p[1] - y0] for p in v] if k in POINT_TRACKS else v
            anims[anim] = a
        chars[name] = {"frameW": tw, "frameH": th, "anchor": [d["anchor"][0] - x0, d["anchor"][1] - y0],
                       "density": dens, "anims": anims}
        if name in PLACEHOLDERS:
            chars[name]["placeholder"] = PLACEHOLDERS[name]
        for suffix, key in (("", "avatar"), ("24", "avatar24")):
            ap = os.path.join(src, f"{name}_avatar{suffix}.png")
            if os.path.exists(ap):
                put(ap, f"{key}_{name}.png")
                chars[name][key] = f"{key}_{name}"

    # single-frame sprites, flat, one PNG per engine id (Art.tex(id) -> res://assets/sprites/<id>.png)
    props = {}
    for k, p in sorted(atlas["props"].items()):
        put(os.path.join(src, p["file"]), f"prop_{k}.png")
        props[k] = f"prop_{k}"
    stages = {}
    for era in ERAS:
        put(os.path.join(src, f"stage_{era}.png"), f"stage_{era}.png")
        a = np.asarray(Image.open(os.path.join(DEST, f"stage_{era}.png")).convert("RGBA"))
        stages[era] = {"sprite": f"stage_{era}", "padTop": _mode_color(a[0]), "padBottom": _mode_color(a[-1])}
    # pipeline-owned FX sprites (fx-data.json particles) + the hat glow (animator request)
    fx = {}
    for sid, rows in FX_SPRITES.items():
        _grid(rows).save(os.path.join(DEST, f"{sid}.png"))
        written.append(f"{sid}.png")
        fx[sid] = sid
    hat = Image.open(os.path.join(src, atlas["props"]["hat"]["file"]))
    ha = np.asarray(hat.convert("RGBA"))[:, :, 3] > 0
    H, W = ha.shape
    glow = np.zeros((H + 2, W + 2), bool)
    for dy in (0, 1, 2):
        for dx in (0, 1, 2):
            glow[dy:dy + H, dx:dx + W] |= ha
    glow[1:1 + H, 1:1 + W] &= ~ha
    g = np.zeros((H + 2, W + 2, 4), np.uint8)
    g[glow] = OD["white"]
    Image.fromarray(g, "RGBA").save(os.path.join(DEST, "prop_hat_glow.png"))
    written.append("prop_hat_glow.png")
    fx["prop_hat_glow"] = {"sprite": "prop_hat_glow", "offset": [-1, -1],
                           "note": "1-ap ring outside the hat mask; draw at the hat's top-left − (1, 1)"}

    # money sources rendered from refs: source_<id>.png (2-frame idle strip), _icon, _icon_sil (flat)
    sources = {}
    for sid, s in atlas.get("sources", {}).items():
        im = Image.open(os.path.join(src, s["file"]))
        a = _alpha(im)
        bad = [] if im.size == (s["frameW"] * s["frames"], s["frameH"]) else [f"strip is {im.size}"]
        bad += ["semi-transparent pixels"] if ((a > 0) & (a < 255)).any() else []
        bad += [f"content on the frame edge in frame {i}" for i in range(s["frames"])
                if a[:, i * s["frameW"]].any() or a[:, (i + 1) * s["frameW"] - 1].any()]
        if bad:
            raise SpriteError(f"source {sid}: " + "; ".join(bad))
        put(os.path.join(src, s["file"]), f"source_{sid}.png")
        put(os.path.join(src, s["icon"]), f"source_{sid}_icon.png")
        put(os.path.join(src, s["sil"]), f"source_{sid}_icon_sil.png")
        sources[sid] = {"sprite": f"source_{sid}", "frames": s["frames"], "frameW": s["frameW"], "frameH": s["frameH"],
                        "pivot": s["anchor"], "icon": f"source_{sid}_icon", "silhouette": f"source_{sid}_icon_sil",
                        "points": s.get("points", {}), "origin": "render-down", "density": s.get("density", 1)}
        if s.get("fallback"):
            sources[sid]["fallback"] = s["fallback"]

    # the 2D Artist's UI kit (art/od-sevev/ui-kit.json): flat, one PNG per piece id
    ui = {}
    if os.path.exists(KIT):
        kit = json.load(open(KIT, encoding="utf-8"))
        taken = {os.path.splitext(os.path.basename(r))[0] for r in written}
        kerr = []
        for pc in kit["pieces"]:
            pid, fp = pc["id"], os.path.join(KIT_ROOT, pc["file"])
            if pid in taken or "/" in pid:
                kerr.append(f"ui {pid}: id collides with another sprite id or contains '/'")
                continue
            if not os.path.exists(fp):
                kerr.append(f"ui {pid}: missing {pc['file']}")
                continue
            im = Image.open(fp)
            if im.size != (pc["w"], pc["h"]):
                kerr.append(f"ui {pid}: PNG is {im.size}, kit says {(pc['w'], pc['h'])}")
            a = _alpha(im)
            if ((a > 0) & (a < 255)).any():
                kerr.append(f"ui {pid}: semi-transparent pixels")
            if im.width > MAX_TEX or im.height > MAX_TEX:
                kerr.append(f"ui {pid}: larger than {MAX_TEX}")
            if "frames" in pc and pc.get("frameW", 0) * pc["frames"] != pc["w"]:
                kerr.append(f"ui {pid}: frames x frameW != w")
            if "slice" in pc:
                l, tp, r, bt = pc["slice"]
                if l + r >= pc["w"] or tp + bt >= pc["h"]:
                    kerr.append(f"ui {pid}: 9-slice margins leave no centre patch")
            taken.add(pid)
            put(fp, f"{pid}.png")
            ui[pid] = {k: v for k, v in pc.items() if k not in ("file", "notes")}
        if kerr:
            raise SpriteError("\n  ".join(["UI kit validation failed (art/od-sevev/ui-kit.json):"] + kerr))
        log(f"ui kit: {len(ui)} pieces from {KIT}")
        # hand-drawn character strips (a kit row with "char" + "anim") replace the render-down's
        override = {}
        for pid, pc in ui.items():
            if "char" in pc and "anim" in pc:
                override.setdefault(pc["char"], {})[pc["anim"]] = (pid, pc)
        for name, anims in override.items():
            c = chars.get(name)
            if c is None:
                raise SpriteError(f"ui kit: {list(anims)} target unknown character {name}")
            sizes = {(pc["frameW"], pc["h"], tuple(pc.get("pivot", []))) for _, pc in anims.values()}
            if len(sizes) != 1:
                raise SpriteError(f"ui kit: {name}'s hand-drawn anims disagree on frame size/pivot {sizes}")
            fw, fh, piv = sizes.pop()
            if set(anims) != set(c["anims"]):
                raise SpriteError(f"ui kit: {name} hand-drawn anims {sorted(anims)} != render-down {sorted(c['anims'])}")
            kerr = []
            for anim, (pid, pc) in anims.items():
                old = c["anims"][anim]
                if pc["frames"] != old["frames"] or pc.get("events", {}) != old["events"]:
                    kerr.append(f"{name}.{anim}: frames/events differ from the state graph's")
                a = _alpha(Image.open(os.path.join(DEST, f"{pid}.png")))
                kerr += [f"{name}.{anim}: content on the frame edge in frame {i}" for i in range(pc["frames"])
                         if a[:, i * fw].any() or a[:, (i + 1) * fw - 1].any()]
                rel = old["texture"]
                for f in (rel, rel + ".import"):
                    if os.path.exists(os.path.join(DEST, f)):
                        os.remove(os.path.join(DEST, f))
                written.remove(rel)
                c["anims"][anim] = {"texture": f"{pid}.png", "frames": pc["frames"], "fps": pc.get("fps", old["fps"]),
                                    "loop": pc.get("loop", old["loop"]), "events": pc.get("events", {}),
                                    "density": 1, "cols": pc["frames"], "rows": 1}
            if kerr:
                raise SpriteError("\n  ".join(["hand-drawn character strips:"] + kerr))
            c.update({"frameW": fw, "frameH": fh, "anchor": list(piv) or [fw // 2, fh - 1], "origin": "hand-drawn",
                      "density": 1})
            c.pop("placeholder", None)
            log(f"chars: {name} uses the 2D Artist's hand-drawn strips ({len(anims)} anims)")
        for pid, pc in ui.items():                       # hand-drawn sources join the same table
            if pc.get("group") == "sources" and pid.startswith("source_") and "frames" in pc:
                sid = pid[len("source_"):]
                sources.setdefault(sid, {"sprite": pid, "frames": pc["frames"], "frameW": pc["frameW"],
                                         "frameH": pc["h"], "pivot": pc.get("pivot"), "icon": f"{pid}_icon",
                                         "silhouette": f"{pid}_icon_sil", "points": {}, "origin": "hand-drawn",
                                         "density": 1})

    # Godot import settings, keeping uids from a previous import of the same file name
    for rel in written:
        k = os.path.basename(rel)
        if k in kept:
            open(os.path.join(DEST, rel + ".import"), "w").write(kept[k])   # verbatim: same path, same uid
        write_import(os.path.join(DEST, rel), "texture", "CompressedTexture2D", TEX_PARAMS)

    files = {rel: {"bytes": os.path.getsize(os.path.join(DEST, rel)), "sha": sha(os.path.join(DEST, rel)),
                   "size": list(Image.open(os.path.join(DEST, rel)).size)} for rel in sorted(written)}
    aliases = {v: n for n in chars if "-" in n for v in (n.replace("-", ""), n.replace("-", "_"))}
    src_aliases = {a: b for a, b in atlas.get("sourceAliases", {}).items() if b in sources}
    log(f"sources: {len(sources)} ({', '.join(f'{k}:{v["origin"]}' for k, v in sorted(sources.items()))})")
    manifest = {
        "_doc": "GENERATED by pipeline/od-sevev/build.py. Do not edit. Contract: game/assets/sprites/CONTRACT.md",
        "version": 1,
        "root": "res://assets/sprites/",
        "artScale": 4,
        "densityNote": "density d = sprite px per art px. A density-d texture draws at artScale/d device-or-logical px "
                       "per sprite px; the renderer's scale must be a multiple of every density used (1 and 3).",
        "artHeight": atlas.get("artHeight", 96),
        "magicianFeet": MAGICIAN_FEET,
        "chars": chars,
        "aliases": aliases,
        "props": props,
        "stages": stages,
        "sources": sources,
        "sourceAliases": src_aliases,
        "ui": ui,
        "fx": fx,
        "files": files,
        "provenance": provenance,
    }
    json.dump(manifest, open(os.path.join(DEST, "sprites.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    return manifest, warns


def import_icons(log):
    """App icons from the 2D Artist's 64 art-px master, nearest-neighbour, into the file names the
    export presets already reference. Replaces the fork's banana icons (tools/icon.sh must not run)."""
    if not os.path.exists(ICON_MASTER):
        log("icons: no master at " + ICON_MASTER + " (kept the existing icons)")
        return []
    m = Image.open(ICON_MASTER).convert("RGBA")
    out = []
    for f, s in ICON_SIZES.items():
        m.resize((s, s), Image.NEAREST).save(os.path.join(ICON_DEST, f))
        out.append(f)
    bg = Image.new("RGBA", (432, 432), m.getpixel((0, 0)))   # adaptive background = the icon's field colour
    bg.save(os.path.join(ICON_DEST, "android_bg_432.png"))
    out.append("android_bg_432.png")
    for f in out:
        write_import(os.path.join(ICON_DEST, f), "texture", "CompressedTexture2D", TEX_PARAMS)
    log(f"icons: {len(out)} sizes from {ICON_MASTER}")
    return out
