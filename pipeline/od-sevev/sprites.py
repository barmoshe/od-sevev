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
ICON_MASTER = os.path.join(KIT_ROOT, "out", "key", "icon-128-art.png")   # 64 art px at d 2 (logo.py)
SPLASH_MASTER = os.path.join(KIT_ROOT, "out", "key", "logo-stacked-art.png")  # the mark over the wordmark, 1x (logo.py)
# every size the export presets name (game/export_presets.cfg), from the 64 art-px master, nearest
ICON_SIZES = {"icon_1024.png": 1024, "pwa_512.png": 512, "pwa_180.png": 180, "pwa_144.png": 144,
              "android_192.png": 192, "android_fg_432.png": 432}

ERAS = ["balfour", "knesset", "courthouse", "washington"]
# The Magician stands with his feet here on every stage (art px), per the approved showcase
# (template.html bibiPos: x 94, floor 220 -> feet row 219) and locations.py's floor at y 216-230.
MAGICIAN_FEET = [94, 219]
MAX_TEX = 2048   # WebGL2's guaranteed MAX_TEXTURE_SIZE (the web export's floor)
# Per-frame point tracks ([x, y] per frame, sprite px: hatMouth, temple, propMouth, ...) are found by shape, never
# by name (is_track): any named track an anim carries is re-based when a frame is trimmed, kept inside the trimmed
# frame, and compared across densities. The names in use are documented in CONTRACT.md §4.


def is_track(v, frames):
    """True when v is one [x, y] point per frame (a named per-frame point track)."""
    return (isinstance(v, list) and frames and len(v) == frames and
            all(isinstance(p, (list, tuple)) and len(p) == 2 and all(isinstance(c, (int, float)) for c in p) for p in v))


def point_tracks(anim):
    """The names of an anim's per-frame point tracks."""
    return sorted(k for k, v in anim.items() if k not in ("frameMap",) and is_track(v, anim.get("frames")))

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


# UX review 2 U7 (2D Artist wave 10): the teaser rows' plate icon is the silhouette in `ui_dim` with a `ui_rule` edge,
# so a not-yet-revealed row reads as a blank pale slip. Every silhouette is the same two swatches (the `suit` mask and
# its `rim` edge, rendered or hand-drawn), so the pale one is an exact swatch-for-swatch recolour.
PALE_MAP = {(69, 74, 96): (180, 195, 232),      # suit #454a60 -> ui_dim  #b4c3e8
            (214, 204, 236): (42, 92, 196)}     # rim  #d6ccec -> ui_rule #2a5cc4


def pale_silhouettes(sources, written, log):
    """<silhouette>_pale.png beside every shipped source silhouette, and sources[id].silhouettePale. Fails on a
    silhouette pixel that is neither swatch (the recolour would have to guess)."""
    done = 0
    for sid, s in sorted(sources.items()):
        sil = s.get("silhouette", "")
        fp = os.path.join(DEST, f"{sil}.png")
        if not sil or not os.path.exists(fp):
            continue
        a = np.asarray(Image.open(fp).convert("RGBA")).copy()
        on = a[:, :, 3] > 0
        out = a.copy()
        hit = np.zeros(on.shape, bool)
        for src, dst in PALE_MAP.items():
            m = on & (a[:, :, 0] == src[0]) & (a[:, :, 1] == src[1]) & (a[:, :, 2] == src[2])
            out[m, :3] = dst
            hit |= m
        if (on & ~hit).any():
            raise SpriteError(f"source {sid}: {sil} has pixels that are not the suit mask or its rim edge")
        Image.fromarray(out, "RGBA").save(os.path.join(DEST, f"{sil}_pale.png"))
        written.append(f"{sil}_pale.png")
        s["silhouettePale"] = f"{sil}_pale"
        done += 1
    log(f"sources: {done} pale silhouettes (<silhouette>_pale, teaser rows: ui_dim mask, ui_rule edge)")


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


def variants(d):
    """A character's renders: [(label suffix, entry)], the main one first, then each `densities`
    alternate (the atlas's chars[c].densities = {"<d>": {frameW, frameH, anchor, density, anims}})."""
    return [("", d)] + [(f"@d{k}", v) for k, v in sorted(d.get("densities", {}).items())]


LANDMARK_TOL = 0.5   # art px: a density alternate's landmark vs the main render's, relative to the feet


def _art_rel(p, anchor, dens):
    """A sprite-px point as art px relative to the feet (anchor), so two densities compare."""
    return ((p[0] - anchor[0]) / dens, (p[1] - anchor[1]) / dens)


def validate_char(name, d, src):
    errs, warns = [], []
    for label, v in variants(d):
        e, w = _validate_variant(name + label, v, src, waived=name in EDGE_WAIVERS)
        errs += e
        warns += w
    main_anims = set(d["anims"])
    for label, v in variants(d)[1:]:
        if set(v["anims"]) != main_anims:
            errs.append(f"{name}{label}: anims {sorted(v['anims'])} != the main render's {sorted(main_anims)}")
        for anim, m in v["anims"].items():
            base = d["anims"].get(anim, {})
            for key in ("frames", "fps", "loop", "events"):
                if key not in base or m.get(key, {} if key == "events" else None) != base[key]:
                    errs.append(f"{name}{label}.{anim}: {key} {m.get(key)} != the main render's {base.get(key)} "
                                "(a density alternate is the same motion: only pixels and sprite-px data differ)")
            for key in sorted(set(point_tracks(base)) | set(point_tracks(m))):
                if (key in base) != (key in m):
                    errs.append(f"{name}{label}.{anim}: {key} present in one render and not the other")
                elif key in m and len(m[key]) == len(base[key]):
                    off = max(max(abs(a - b) for a, b in zip(_art_rel(p, v["anchor"], v["density"]),
                                                             _art_rel(q, d["anchor"], d["density"])))
                              for p, q in zip(m[key], base[key]))
                    if off > LANDMARK_TOL:
                        errs.append(f"{name}{label}.{anim}: {key} is {off:.2f} art px off the main render's "
                                    f"(max {LANDMARK_TOL})")
    return errs, warns


def validate_source_alt(sid, main, alt, src):
    """A money source's density alternate: its own strip, the same timing and named points as the main one."""
    errs = []
    dens = alt.get("density", 1)
    for key in ("frames", "fps", "loop"):
        if alt.get(key) != main.get(key):
            errs.append(f"{key} {alt.get(key)} != the main render's {main.get(key)}")
    if set(alt.get("points", {})) != set(main.get("points", {})):
        errs.append(f"points {sorted(alt.get('points', {}))} != the main render's {sorted(main.get('points', {}))}")
    for k, p in alt.get("points", {}).items():
        q = main["points"].get(k)
        if q is not None:
            off = max(abs(a - b) for a, b in zip(_art_rel(p, alt["anchor"], dens),
                                                 _art_rel(q, main["anchor"], main.get("density", 1))))
            if off > LANDMARK_TOL:
                errs.append(f"point {k} is {off:.2f} art px off the main render's")
    p = os.path.join(src, alt["file"])
    if not os.path.exists(p):
        return errs + [f"missing {alt['file']}"]
    im = Image.open(p)
    a = _alpha(im)
    if im.size != (alt["frameW"] * alt["frames"], alt["frameH"]):
        errs.append(f"strip is {im.size}, expected {(alt['frameW'] * alt['frames'], alt['frameH'])}")
    if im.width > MAX_TEX or im.height > MAX_TEX:
        errs.append(f"strip is {im.size}, over {MAX_TEX}")
    if ((a > 0) & (a < 255)).any():
        errs.append("semi-transparent pixels")
    errs += [f"content on the frame edge in frame {i}" for i in range(alt["frames"])
             if a[:, i * alt["frameW"]].any() or a[:, (i + 1) * alt["frameW"] - 1].any()]
    if alt["frameH"] != 40 * dens:
        errs.append(f"frameH is {alt['frameH']}, expected {40 * dens} (40 art px x density)")
    return [f"source {sid}@d{alt.get('density')}: {e}" for e in errs]


def _validate_variant(name, d, src, waived=False):
    errs, warns = [], []
    fw, fh = d["frameW"], d["frameH"]
    ax, ay = d["anchor"]
    if not (0 <= ax < fw and 0 <= ay < fh):
        errs.append(f"{name}: anchor {d['anchor']} outside the {fw}x{fh} frame")
    for anim, m in d["anims"].items():
        for key in point_tracks(m) + [k for k in ("hatMouth", "temple", "propMouth") if k in m and k not in point_tracks(m)]:
            if key in m and len(m[key]) != m["frames"]:
                errs.append(f"{name}.{anim}: {key} has {len(m[key])} points for {m['frames']} frames")
            elif key in m and not all(0 <= p[0] < fw and 0 <= p[1] < fh for p in m[key]):
                errs.append(f"{name}.{anim}: a {key} point lies outside the {fw}x{fh} frame")
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
            base = name.split("@")[0]
            (warns if waived else errs).append(msg + (f" [waived: {EDGE_WAIVERS[base]}]" if waived else ""))
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


def grid_shape(n, tw, th):
    """(cols, rows) for n cells of tw x th: the fewest cells (VRAM) inside MAX_TEX both ways, ties to
    the fewest rows. A 14-cell anim of 201-px frames is 7x2, not 10+4; 13 cells are 7x2 as well."""
    best = None
    for rows in range(1, n + 1):
        cols = -(-n // rows)
        if cols * tw > MAX_TEX or rows * th > MAX_TEX:
            continue
        if best is None or cols * rows < best[0] * best[1]:
            best = (cols, rows)
    return best


def _masked(f):
    """A frame's visible pixels: RGB under alpha 0 zeroed, so two frames that look the same compare equal."""
    g = f.copy()
    g[g[:, :, 3] == 0] = 0
    return g


def _pack(name, d, src, written):
    """One render of a character (the main one or a density alternate) -> cast/<file> grids + its
    sprites.json entry. Trims to the render's union box + 1 clear px, re-bases the anchor and every
    point track, and packs each anim's UNIQUE frames into a grid: when repeated frames make the grid
    smaller, `frameMap` (one cell index per frame; `frames` stays the playback count) says which cell
    frame i draws. Every frame is read back from the grid and must match the render pixel for pixel."""
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
    for anim, m in d["anims"].items():                  # every point track stays inside the trimmed frame (a loose
        for k in point_tracks(m):                       # prop's anchor may sit beside the body: Eisenkot, Liberman)
            for px, py in m[k]:
                union = [min(union[0], px), min(union[1], py), max(union[2], px + 1), max(union[3], py + 1)]
    # 1 px of clear margin keeps the frame-edge rule; the feet row always stays inside
    x0, y0 = max(union[0] - 1, 0), max(union[1] - 1, 0)
    x1, y1 = min(union[2] + 1, fw), max(min(union[3] + 1, fh), d["anchor"][1] + 1)
    x0, y0, x1, y1 = int(x0), int(y0), int(x1), int(y1)     # numpy ints are not JSON
    tw, th = x1 - x0, y1 - y0
    if tw > MAX_TEX or th > MAX_TEX:
        raise SpriteError(f"{name}: a trimmed frame is {tw}x{th}, over {MAX_TEX}")
    anims = {}
    for anim, m in d["anims"].items():
        n = m["frames"]
        frames = [strips[anim][y0:y1, i * fw + x0:i * fw + x1] for i in range(n)]
        cells, fmap, seen = [], [], {}
        for f in frames:                                  # first occurrence order: frame 0 is always cell 0
            key = _masked(f).tobytes()
            if key not in seen:
                seen[key] = len(cells)
                cells.append(f)
            fmap.append(seen[key])
        full = grid_shape(n, tw, th)
        dedup = grid_shape(len(cells), tw, th)
        if full is None or dedup is None:
            raise SpriteError(f"{name}.{anim}: {n} frames of {tw}x{th} don't fit a {MAX_TEX} grid")
        use_map = dedup[0] * dedup[1] < full[0] * full[1]     # only where it saves texels
        if not use_map:
            cells, fmap = frames, list(range(n))
        cols, rows = dedup if use_map else full
        grid = np.zeros((rows * th, cols * tw, 4), np.uint8)
        for c, f in enumerate(cells):
            grid[(c // cols) * th:(c // cols + 1) * th, (c % cols) * tw:(c % cols + 1) * tw] = f
        for i, f in enumerate(frames):                   # lossless round trip, as the reader will cut it
            c = fmap[i]
            back = grid[(c // cols) * th:(c // cols + 1) * th, (c % cols) * tw:(c % cols + 1) * tw]
            if not np.array_equal(_masked(back), _masked(f)):
                raise SpriteError(f"{name}.{anim}: frame {i} does not round-trip through cell {c}")
        rel = f"cast/{m['file']}"
        Image.fromarray(grid, "RGBA").save(os.path.join(DEST, rel), optimize=True)
        written.append(rel)
        a = {"texture": rel, "frames": n, "fps": m["fps"], "loop": m["loop"], "events": m.get("events", {}),
             "density": m.get("density", dens), "cols": cols, "rows": rows}
        if use_map:
            a["frameMap"] = fmap
        tracks = point_tracks(m)
        for k, v in m.items():                          # hatMouth, temple, propMouth, ...: into the trimmed frame
            if k in ("file", "frames", "fps", "loop", "events", "density"):
                continue
            a[k] = [[p[0] - x0, p[1] - y0] for p in v] if k in tracks else v
        anims[anim] = a
    return {"frameW": tw, "frameH": th, "anchor": [d["anchor"][0] - x0, d["anchor"][1] - y0],
            "density": dens, "anims": anims}


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
    for sid, s in atlas.get("sources", {}).items():
        for alt in s.get("densities", {}).values():
            errs += validate_source_alt(sid, s, alt, src)
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
        chars[name] = _pack(name, d, src, written)
        alts = {k: _pack(f"{name}@d{k}", v, src, written) for k, v in sorted(d.get("densities", {}).items())}
        if alts:
            chars[name]["densities"] = alts
        if name in PLACEHOLDERS:
            chars[name]["placeholder"] = PLACEHOLDERS[name]
        if d.get("prop"):                              # a leader's tap prop (CONTRACT §4c)
            chars[name]["prop"] = d["prop"]
        for suffix, key in (("", "avatar"), ("24", "avatar24")):
            ap = os.path.join(src, f"{name}_avatar{suffix}.png")
            if os.path.exists(ap):
                put(ap, f"{key}_{name}.png")
                chars[name][key] = f"{key}_{name}"
        # the chat avatar at density 2 (64 px, drawn at artScale / 2): the engine reads avatarDensity
        # (ChatView.avatar_art, the toasts); the 32 stays as avatar32 for anything that wants it
        hd = os.path.join(src, f"{name}_avatar_d2.png")
        if os.path.exists(hd):
            if Image.open(hd).size != (64, 64):
                raise SpriteError(f"{name}_avatar_d2.png is not 64x64")
            put(hd, f"avatar_{name}_d2.png")
            chars[name]["avatar32"] = chars[name].get("avatar", f"avatar_{name}")
            chars[name]["avatar"] = f"avatar_{name}_d2"
            chars[name]["avatarDensity"] = 2
        # a launch leader's picker avatars: the same heads on one neutral ring (CONTRACT §4c)
        # + the picker's XL heads (UX mobile-first A3): 96 (from the d 3 render; the 192-logical avatar) and 64 (the
        # 128-logical one), both drawn at 2 logical px per sprite px
        for suffix, key, file_key, size in (("_pick", "avatarPick", "avatar_pick", 32), ("24_pick", "avatar24Pick", "avatar24_pick", 24),
                                            ("_pick_d3", "avatarPickXL", "avatar_pick_{}_d3", 96),
                                            ("_pick_d2", "avatarPick64", "avatar_pick_{}_d2", 64)):
            ap = os.path.join(src, f"{name}_avatar{suffix}.png")
            if os.path.exists(ap):
                if Image.open(ap).size != (size, size):
                    raise SpriteError(f"{name}_avatar{suffix}.png is not {size}x{size}")
                sid = file_key.format(name) if "{}" in file_key else f"{file_key}_{name}"
                put(ap, f"{sid}.png")
                chars[name][key] = sid

    # single-frame sprites, flat, one PNG per engine id (Art.tex(id) -> res://assets/sprites/<id>.png)
    props = {}
    for k, p in sorted(atlas["props"].items()):
        put(os.path.join(src, p["file"]), f"prop_{k}.png")
        props[k] = f"prop_{k}"
    stages = {}
    for era in ERAS:
        put(os.path.join(src, f"stage_{era}.png"), f"stage_{era}.png")
        a = np.asarray(Image.open(os.path.join(DEST, f"stage_{era}.png")).convert("RGBA"))
        # padBottom = the apron's colour (locations.py lower_band: y 230-320, a lip on top and a 1-row rule
        # at y 319). The Suitcase lane (S-116..S-4 = art rows 229-257) shows the apron, so the pad beside
        # the column must be the apron, not the bottom rule (2d-artist, 2026-09-29: every era differed).
        stages[era] = {"sprite": f"stage_{era}", "padTop": _mode_color(a[0]), "padBottom": _mode_color(a[240:-1])}
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
        bad += [f"{k} is {Image.open(os.path.join(src, s[k])).size}, not 24x24 (shop icons are UI: density 1)"
                for k in ("icon", "sil") if Image.open(os.path.join(src, s[k])).size != (24, 24)]
        bad += ["frameH is %d, expected %d (40 art px x density)" % (s["frameH"], 40 * s.get("density", 1))] \
            if s["frameH"] != 40 * s.get("density", 1) else []
        if bad:
            raise SpriteError(f"source {sid}: " + "; ".join(bad))
        put(os.path.join(src, s["file"]), f"source_{sid}.png")
        put(os.path.join(src, s["icon"]), f"source_{sid}_icon.png")
        put(os.path.join(src, s["sil"]), f"source_{sid}_icon_sil.png")
        sources[sid] = {"sprite": f"source_{sid}", "frames": s["frames"], "frameW": s["frameW"], "frameH": s["frameH"],
                        "pivot": s["anchor"], "icon": f"source_{sid}_icon", "silhouette": f"source_{sid}_icon_sil",
                        "points": s.get("points", {}), "origin": "render-down", "density": s.get("density", 1),
                        "iconDensity": s.get("iconDensity", 1)}
        if s.get("fallback"):
            sources[sid]["fallback"] = s["fallback"]
        # density alternates (a second render at d, CONTRACT §4b): the same shape as chars[c].densities,
        # so SpriteStrip.pick_variant(sources[id], k) merges one over the main entry
        alts = {}
        for dk, alt in sorted(s.get("densities", {}).items()):
            aid = os.path.splitext(alt["file"])[0]
            put(os.path.join(src, alt["file"]), f"{aid}.png")
            alts[dk] = {"sprite": aid, "frameW": alt["frameW"], "frameH": alt["frameH"], "pivot": alt["anchor"],
                        "points": alt.get("points", {}), "density": alt["density"]}
        if alts:
            sources[sid]["densities"] = alts

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
            # a stand-in (kit rows flagged "standIn"): a hand-drawn character with no render-down behind it, e.g. the
            # 2D Artist's `nophoto` figure for partners without a ref (standin_aliases below points them at it)
            stand_in = c is None and all(pc.get("standIn") for _, pc in anims.values())
            if c is None and not stand_in:
                raise SpriteError(f"ui kit: {list(anims)} target unknown character {name}")
            if stand_in:
                c = chars[name] = {"anims": {}}
            sizes = {(pc["frameW"], pc["h"], tuple(pc.get("pivot", []))) for _, pc in anims.values()}
            if len(sizes) != 1:
                raise SpriteError(f"ui kit: {name}'s hand-drawn anims disagree on frame size/pivot {sizes}")
            fw, fh, piv = sizes.pop()
            if not stand_in and set(anims) != set(c["anims"]):
                raise SpriteError(f"ui kit: {name} hand-drawn anims {sorted(anims)} != render-down {sorted(c['anims'])}")
            if stand_in and "idle" not in anims:
                raise SpriteError(f"ui kit: stand-in {name} has no idle anim (SpriteStrip.make plays idle)")
            kerr = []
            for anim, (pid, pc) in anims.items():
                old = c["anims"].get(anim)
                if old and (pc["frames"] != old["frames"] or pc.get("events", {}) != old["events"]):
                    kerr.append(f"{name}.{anim}: frames/events differ from the state graph's")
                a = _alpha(Image.open(os.path.join(DEST, f"{pid}.png")))
                kerr += [f"{name}.{anim}: content on the frame edge in frame {i}" for i in range(pc["frames"])
                         if a[:, i * fw].any() or a[:, (i + 1) * fw - 1].any()]
                if old:
                    rel = old["texture"]
                    for f in (rel, rel + ".import"):
                        if os.path.exists(os.path.join(DEST, f)):
                            os.remove(os.path.join(DEST, f))
                    written.remove(rel)
                old = old or {"fps": 1, "loop": True}
                c["anims"][anim] = {"texture": f"{pid}.png", "frames": pc["frames"], "fps": pc.get("fps", old["fps"]),
                                    "loop": pc.get("loop", old["loop"]), "events": pc.get("events", {}),
                                    "density": 1, "cols": pc["frames"], "rows": 1}
            if stand_in:
                for key in ("avatar", "avatar24"):
                    if f"{key}_{name}" in ui:
                        c[key] = f"{key}_{name}"
                c["standIn"] = "hand-drawn stand-in for a partner with no ref (sprites.json aliases name who uses it)"
            if kerr:
                raise SpriteError("\n  ".join(["hand-drawn character strips:"] + kerr))
            c.update({"frameW": fw, "frameH": fh, "anchor": list(piv) or [fw // 2, fh - 1], "origin": "hand-drawn",
                      "density": 1})
            c.pop("placeholder", None)
            for alt in c.pop("densities", {}).values():      # a render-down alternate of a hand-drawn character
                for a in alt["anims"].values():
                    for f in (a["texture"], a["texture"] + ".import"):
                        if os.path.exists(os.path.join(DEST, f)):
                            os.remove(os.path.join(DEST, f))
                    written.remove(a["texture"])
            log(f"chars: {name} uses the 2D Artist's hand-drawn strips ({len(anims)} anims)")
        for pid, pc in ui.items():                       # hand-drawn sources join the same table
            if pc.get("group") == "sources" and pid.startswith("source_") and "frames" in pc:
                sid = pid[len("source_"):]
                sources.setdefault(sid, {"sprite": pid, "frames": pc["frames"], "frameW": pc["frameW"],
                                         "frameH": pc["h"], "pivot": pc.get("pivot"), "icon": f"{pid}_icon",
                                         "silhouette": f"{pid}_icon_sil", "points": {}, "origin": "hand-drawn",
                                         "density": 1, "iconDensity": 1})

    pale_silhouettes(sources, written, log)

    # Godot import settings, keeping uids from a previous import of the same file name
    for rel in written:
        k = os.path.basename(rel)
        if k in kept:
            open(os.path.join(DEST, rel + ".import"), "w").write(kept[k])   # verbatim: same path, same uid
        write_import(os.path.join(DEST, rel), "texture", "CompressedTexture2D", TEX_PARAMS)

    files = {rel: {"bytes": os.path.getsize(os.path.join(DEST, rel)), "sha": sha(os.path.join(DEST, rel)),
                   "size": list(Image.open(os.path.join(DEST, rel)).size)} for rel in sorted(written)}
    aliases = {v: n for n in chars if "-" in n for v in (n.replace("-", ""), n.replace("-", "_"))}
    for pid, n in standin_aliases(chars, aliases).items():
        aliases[pid] = n
        log(f"chars: partner '{pid}' has no character yet: aliased to the stand-in '{n}'")
    src_aliases = {a: b for a, b in atlas.get("sourceAliases", {}).items() if b in sources}
    log(f"sources: {len(sources)} (" + ", ".join(f"{k}:{v['origin']}" for k, v in sorted(sources.items())) + ")")
    manifest = {
        "_doc": "GENERATED by pipeline/od-sevev/build.py. Do not edit. Contract: game/assets/sprites/CONTRACT.md",
        "version": 1,
        "root": "res://assets/sprites/",
        "artScale": 4,
        "densityNote": "density d = sprite px per art px. A density-d texture draws at artScale/d logical px per sprite "
                       "px; it is crisp when the device scale k is a multiple of d. chars[c].densities and "
                       "sources[id].densities hold alternates (every rendered character and source: d 2 beside the "
                       "main d 3, so every k that is a multiple of 2 or 3 is crisp); frameMap maps a frame to its "
                       "texture cell.",
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


CONTENT = os.path.join(FORK, "design", "content.json")
FORK_ART = os.path.join(FORK, "game", "data", "art.json")


def standin_aliases(chars, aliases, content_path=None):
    """Content partners that resolve to no character, mapped to the stand-in character (a chars entry with
    `standIn`, the 2D Artist's `nophoto`). Resolution mirrors ChatView.char_for: the partner id, then its content
    `avatar` id without "_avatar", each through chars and aliases. Never a partial-name match. With the alias, the
    chat avatar, the partner card and the ultimatum cameo draw the stand-in instead of the engine's '?' card."""
    stand = sorted(n for n, c in chars.items() if c.get("standIn"))
    content_path = content_path or CONTENT
    if not stand or not os.path.exists(content_path):
        return {}
    ok = lambda i: bool(i) and (i in chars or aliases.get(i) in chars)
    out = {}
    for p in json.load(open(content_path, encoding="utf-8")).get("partners", []):
        pid, av = p["id"], str(p.get("avatar", "")).removesuffix("_avatar")
        if not ok(pid) and not ok(av):
            out[pid] = stand[0]
    return out


def check_content_sources(manifest, content_path=CONTENT, art_path=FORK_ART):
    """Every money source in content (producers[]) must resolve to shipped art, the way the engine resolves it
    (diorama.gd `_sprite_of`, shop.gd, Art.sprite_or): otherwise the stage or the shop draws the neutral '?'
    placeholder card (UX review R18). Returns a list of failures (empty = pass). Checks, per producer:
      - the stage sprite: producers[].sprite, else sources[id | sourceAliases[id]].sprite, else critter_<id>. It must
        be a money-source strip in sprites.json.sources (a density-aware 2-frame strip), not merely any PNG;
      - the shop icon and the locked silhouette (producers[].icon / .silhouette, else the sources entry's);
      - its set piece's art: 'lob' throws `icon_<currency.icon>` across the sky.
    An id resolves when res://assets/sprites/<id>.png is shipped or game/data/art.json (the fork's baked grids) has it."""
    content = json.load(open(content_path, encoding="utf-8"))
    baked = set(json.load(open(art_path, encoding="utf-8")).get("sprites", {})) if os.path.exists(art_path) else set()
    shipped = {os.path.splitext(os.path.basename(r))[0] for r in manifest["files"]}

    def ok(i):
        return bool(i) and (i in shipped or i in baked)

    sources, aliases = manifest["sources"], manifest.get("sourceAliases", {})
    strips = {s["sprite"] for s in sources.values()}
    coin = "icon_" + str(content.get("currency", {}).get("icon", ""))
    bad = []
    for p in content.get("producers", []):
        pid = p["id"]
        src = sources.get(pid) or sources.get(aliases.get(pid, ""), {})
        sprite = p.get("sprite", src.get("sprite", "critter_" + pid))
        if sprite not in strips:
            bad.append(f"{pid}: stage sprite '{sprite}' is not a money-source strip in sprites.json.sources "
                       f"(the stage would draw the '?' card or nothing)")
        for key in ("icon", "silhouette"):
            i = p.get(key, src.get(key, ""))
            if not ok(i):
                bad.append(f"{pid}: {key} '{i}' is not shipped (the shop would draw the '?' card)")
        if p.get("setPiece") == "lob" and not ok(coin):
            bad.append(f"{pid}: setPiece 'lob' throws '{coin}' (currency.icon), which is not shipped: a '?' card "
                       f"flies across the stage")
    return bad


def import_icons(log):
    """App icons from the 2D Artist's master (64 art px at d 2 = 128 px), nearest-neighbour, into the file names the
    export presets already reference. Replaces the fork's app icons (tools/icon.sh must not run)."""
    if not os.path.exists(ICON_MASTER):
        log("icons: no master at " + ICON_MASTER + " (kept the existing icons)")
        return []
    m = Image.open(ICON_MASTER).convert("RGBA")
    big = m.resize((1024, 1024), Image.NEAREST)
    out = []
    for f, s in ICON_SIZES.items():
        # an integer multiple of the 64 art px stays nearest-neighbour; 180 / 144 / 192 / 432 are LANCZOS from the
        # 1024, as the OS scales an icon (nearest there would draw art px 2 and 3 px wide at random)
        im = m.resize((s, s), Image.NEAREST) if s % 64 == 0 else big.resize((s, s), Image.LANCZOS)
        im.save(os.path.join(ICON_DEST, f))
        out.append(f)
    if os.path.exists(SPLASH_MASTER):                       # the boot splash: the stacked logo at the game's x4
        sp = Image.open(SPLASH_MASTER).convert("RGBA")
        sp.resize((sp.width * 4, sp.height * 4), Image.NEAREST).save(os.path.join(ICON_DEST, "splash.png"))
        out.append("splash.png")
    bg = Image.new("RGBA", (432, 432), m.getpixel((0, 0)))   # adaptive background = the icon's field colour
    bg.save(os.path.join(ICON_DEST, "android_bg_432.png"))
    out.append("android_bg_432.png")
    for f in out:
        write_import(os.path.join(ICON_DEST, f), "texture", "CompressedTexture2D", TEX_PARAMS)
    log(f"icons: {len(out)} sizes from {ICON_MASTER}")
    return out
