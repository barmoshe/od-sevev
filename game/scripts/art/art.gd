extends Node
## Autoload `Art`: bakes the procedural pixel art at boot. Every sprite, UI surface and glyph is
## a palette-indexed string grid in res://data/art.json (exported from art/sprites.ts and
## pipeline/pixel-font.ts by art/tools/export-godot-data.mjs), turned into ImageTextures here.
## There are no image files in the game. Rules: art/style-guide.md, pipeline/pipeline-conventions.md.

const PATH := "res://data/art.json"
const MASK_CHAR := "@"

var data: Dictionary = {}
var palette: Dictionary = {}          # char -> Color
var theme: Dictionary = {}            # UI_THEME
var meta: Dictionary = {}             # SPRITE_META
var _frames: Dictionary = {}          # id -> Array[ImageTexture]
var fonts: Dictionary = {}            # variant -> {tex, regions: {char: Rect2}, cell: Vector2i, offset: Vector2i}
var font_metrics: Dictionary = {}
var _aliases: Dictionary = {}
var _fallback := "?"


func _init() -> void:
	load_data()


func load_data() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	assert(parsed is Dictionary, "[art] cannot parse %s" % PATH)
	data = parsed
	palette.clear()
	for c: String in data["palette"]:
		var hex: String = data["palette"][c]
		palette[c] = Color(0, 0, 0, 0) if hex == "transparent" else Color.html(hex)
	palette[MASK_CHAR] = Color.WHITE
	theme = data["uiTheme"]
	meta = data["meta"]
	font_metrics = data["font"]["metrics"]
	_aliases = data["font"]["aliases"]
	_fallback = data["font"]["fallback"]
	_frames.clear()
	_bake_fonts()


## A palette char ("Y") or a theme role ({char, hex}) as a Color.
func col(c: Variant) -> Color:
	if c is Dictionary:
		c = c["char"]
	return palette.get(c, Color.MAGENTA)


## od-sevev: besides the baked art.json grids, a sprite id can be a PNG the Technical Artist
## ships in res://assets/sprites/<id>.png (single frame, 1x art px: props, stage backgrounds).
## Character strips go through SpriteStrip instead. An id with neither resolves to PLACEHOLDER
## through sprite_or(), so content can name art before it lands.
const SPRITE_DIR := "res://assets/sprites/"
const PLACEHOLDER := "_placeholder"


func has_sprite(id: String) -> bool:
	return data["sprites"].has(id) or id == PLACEHOLDER or _png_path(id) != ""


## `id` when it resolves, else the neutral placeholder.
func sprite_or(id: String) -> String:
	return id if (id != "" and has_sprite(id)) else PLACEHOLDER


func _png_path(id: String) -> String:
	if id == "" or id.contains("/") or id.contains(".."):
		return ""
	var p := SPRITE_DIR + id + ".png"
	return p if ResourceLoader.exists(p) else ""


func sprite_size(id: String) -> Vector2i:
	if not data["sprites"].has(id):
		return Vector2i(tex(id, 0).get_size())
	var s: Dictionary = data["sprites"][id]
	return Vector2i(int(s["w"]), int(s["h"]))


func frame_count(id: String) -> int:
	if not data["sprites"].has(id):
		if not has_sprite(id):
			return 1
		tex(id, 0)
		return (_frames[id] as Array).size()
	return (data["sprites"][id]["frames"] as Array).size()


## The baked 1x texture of one frame (draw it at an integer scale).
func tex(id: String, frame: int = 0) -> Texture2D:
	if not _frames.has(id):
		if data["sprites"].has(id):
			_frames[id] = _bake_sprite(id)
		elif id == PLACEHOLDER:
			_frames[id] = [_bake_placeholder()]
		else:
			var p := _png_path(id)
			assert(p != "", "[art] unknown sprite %s" % id)
			var t: Variant = load(p)
			if not t is Texture2D:
				push_warning("[art] %s did not load (not imported?); drawing the placeholder" % p)
				t = _bake_placeholder()
			_frames[id] = _kit_frames(id, t)
	var arr: Array = _frames[id]
	return arr[clampi(frame, 0, arr.size() - 1)]


## The UI kit's strips (sprites.json ui[id].frames + frameW) cut into one AtlasTexture per frame.
func _kit_frames(id: String, t: Texture2D) -> Array:
	var u: Dictionary = kit(id)
	var n := int(u.get("frames", 1))
	var fw := int(u.get("frameW", 0))
	if n <= 1 or fw <= 0:
		return [t]
	var out: Array = []
	for i in n:
		var a := AtlasTexture.new()
		a.atlas = t
		a.region = Rect2(i * fw, 0, fw, t.get_height())
		out.append(a)
	return out


## The TA manifest's UI-kit entry for an id ({} when it is not a kit piece). A money source's
## stage strip (sprites.json sources[*].sprite) counts too: its frames/frameW cut the same way.
func kit(id: String) -> Dictionary:
	var m := SpriteStrip.manifest()
	var u: Dictionary = m.get("ui", {}).get(id, {})
	if not u.is_empty():
		return u
	for src: Dictionary in m.get("sources", {}).values():
		if String(src.get("sprite", "")) == id:
			return src
		for dk: Variant in src.get("densities", {}):     # a density alternate's strip (source_<id>_d2)
			if String(src["densities"][dk].get("sprite", "")) == id:
				return SpriteStrip.pick_variant(src, int(str(dk)))
	return {}


## The TA's art for a money source (sprites.json sources[id], through sourceAliases), or {}: the
## density variant crisp at the device scale (SpriteStrip.pick_variant, CONTRACT.md §4b), so the
## diorama draws a rendered source's d 2 alternate at k 4 and its main d 3 at k 6.
## `picked` false: the main entry as the manifest lists it.
func source(id: String, picked: bool = true) -> Dictionary:
	var m := SpriteStrip.manifest()
	var srcs: Dictionary = m.get("sources", {})
	var al := String(m.get("sourceAliases", {}).get(id, ""))
	var e: Dictionary = srcs.get(id, srcs.get(al, {}))
	return SpriteStrip.pick_variant(e, Display.k) if picked and not e.is_empty() else e


## A 16x16 neutral stand-in: an ink-outlined grey card with a "?" (art pending).
func _bake_placeholder() -> ImageTexture:
	var img := Image.create_empty(16, 16, false, Image.FORMAT_RGBA8)
	var ink := Color("#061029")
	var fill := Color8(0x7d, 0x83, 0x98)   # the v4 slate fill (the placeholder card; a fill, not the slate-text role the map lifts)
	var q := ["......", ".####.", ".#..#.", "....#.", "..##..", "..#...", "......", "..#..."]
	for y in range(1, 15):
		for x in range(2, 14):
			var edge := y == 1 or y == 14 or x == 2 or x == 13
			img.set_pixel(x, y, ink if edge else fill)
	for y in q.size():
		for x in (q[y] as String).length():
			if (q[y] as String)[x] == "#":
				img.set_pixel(5 + x, 4 + y, ink)
	return ImageTexture.create_from_image(img)


func _bake_sprite(id: String) -> Array:
	assert(has_sprite(id), "[art] unknown sprite %s" % id)
	var s: Dictionary = data["sprites"][id]
	var w := int(s["w"])
	var h := int(s["h"])
	var out: Array = []
	for rows: Array in s["frames"]:
		var img := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
		for y in h:
			var row: String = rows[y]
			for x in w:
				var ch := row[x]
				if ch == ".":
					continue
				var c: Color = palette.get(ch, Color(0, 0, 0, 0))
				if c.a > 0.0:
					img.set_pixel(x, y, c)
		out.append(ImageTexture.create_from_image(img))
	return out


var _masks: Dictionary = {}


## A white silhouette of one frame (for flash fills: the crit flash, the purchase flash).
func mask(id: String, frame: int = 0) -> Texture2D:
	var key := "%s#%d" % [id, frame]
	if not _masks.has(key):
		var img := tex(id, frame).get_image()
		for y in img.get_height():
			for x in img.get_width():
				if img.get_pixel(x, y).a > 0.0:
					img.set_pixel(x, y, Color.WHITE)
		_masks[key] = ImageTexture.create_from_image(img)
	return _masks[key]


## 9-slice insets in art px (SPRITE_META[id].nineSlice).
func insets(id: String) -> Dictionary:
	var sl: Variant = kit(id).get("slice")
	if sl is Array and (sl as Array).size() == 4:
		return {"left": int(sl[0]), "top": int(sl[1]), "right": int(sl[2]), "bottom": int(sl[3])}
	var m: Dictionary = meta.get(id, {})
	return m.get("nineSlice", {"left": 3, "right": 3, "top": 3, "bottom": 3})


# ---------------------------------------------------------------------------------------------
# Pixel font: three variants (plain = white mask, tinted at draw; outline = w on k; crit = Y on r)
# ---------------------------------------------------------------------------------------------

func _bake_fonts() -> void:
	var f: Dictionary = data["font"]
	var glyphs: Dictionary = f["glyphs"]
	var gm: Dictionary = f["metrics"]
	var om: Dictionary = f["outline"]
	var chars: Array = glyphs.keys()
	chars.sort()
	var cols := 16
	for variant: String in f["variants"]:
		var spec: Dictionary = f["variants"][variant]
		var outlined: bool = spec["outline"] != null
		var cw := int(om["cellW"]) if outlined else int(gm["glyphW"])
		var chh := int(om["cellH"]) if outlined else int(gm["glyphH"])
		var ox := -int(om["xOffset"]) if outlined else 0
		var oy := -int(om["yOffset"]) if outlined else 0
		var rows_n := ceili(chars.size() / float(cols))
		var img := Image.create_empty(cols * (cw + 1) + 1, rows_n * (chh + 1) + 1, false, Image.FORMAT_RGBA8)
		var fill: Color = col(spec["fill"])
		var ring: Color = col(spec["outline"]) if outlined else Color(0, 0, 0, 0)
		var regions := {}
		for i in chars.size():
			var ch: String = chars[i]
			var g: Array = glyphs[ch]
			var cx := 1 + (i % cols) * (cw + 1)
			var cy := 1 + (i / cols) * (chh + 1)
			regions[ch] = Rect2(cx, cy, cw, chh)
			var on := func(x: int, y: int) -> bool:
				return y >= 0 and y < g.size() and x >= 0 and x < String(g[y]).length() and String(g[y])[x] == "#"
			if outlined:
				for y in range(-1, g.size() + 1):
					for x in range(-1, int(gm["glyphW"]) + 1):
						if on.call(x, y):
							continue
						var hit: bool = on.call(x - 1, y) or on.call(x + 1, y) or on.call(x, y - 1) or on.call(x, y + 1) \
							or on.call(x - 1, y - 1) or on.call(x + 1, y - 1) or on.call(x - 1, y + 1) or on.call(x + 1, y + 1)
						if hit:
							img.set_pixel(cx + ox + x, cy + oy + y, ring)
			for y in g.size():
				for x in String(g[y]).length():
					if on.call(x, y):
						img.set_pixel(cx + ox + x, cy + oy + y, fill)
		fonts[variant] = {
			"tex": ImageTexture.create_from_image(img), "regions": regions,
			"cell": Vector2i(cw, chh), "offset": Vector2i(-ox, -oy),
		}


## Aliases, UPPERCASE (UX rule), and the fallback glyph for anything the font lacks.
func font_text(text: String, uppercase: bool = true) -> String:
	var src := text.to_upper() if uppercase else text
	var glyphs: Dictionary = data["font"]["glyphs"]
	var out := ""
	for i in src.length():
		var c: String = _aliases.get(src[i], src[i])
		out += c if (c == "\n" or glyphs.has(c)) else _fallback
	return out


## Width in logical px at integer scale s: 6·s·n − s per line (the widest line).
func measure(text: String, s: int) -> int:
	var adv := int(font_metrics["advance"])
	var gap := int(font_metrics["letterSpacing"])
	var widest := 0
	for line in text.split("\n"):
		var n := line.length()
		widest = maxi(widest, (adv * n - gap) * s if n > 0 else 0)
	return widest
