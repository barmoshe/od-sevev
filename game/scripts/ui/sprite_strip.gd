class_name SpriteStrip
extends Node2D
## Plays one character's frame strips from the Technical Artist's manifest
## (res://assets/sprites/sprites.json, loader contract res://assets/sprites/CONTRACT.md §4).
##
## - The node position is the character's FEET point: the strip's `anchor` pixel sits there.
## - Frame i of an anim is Rect2(i·frameW, 0, frameW, frameH) of its texture, drawn at the one
##   art scale (×4, sprites.json artScale).
## - Each anim steps at its own fps. loop:true wraps; loop:false holds its last frame for one
##   frame time and then emits `finished` (the caller returns to idle).
## - `events` {name: frame} fire when playback ENTERS that frame, once per play, in order even
##   when a slow frame skips past several. Unknown names are the caller's no-op.
## - Per-frame point arrays (hatMouth) are read with point(): node-local logical px.
## Driven by update_view(dt_ms) from the controller's frame loop, like every other view.

signal event(name: String, frame: int)
signal finished(anim: String)

const MANIFEST := "res://assets/sprites/sprites.json"

static var _man: Dictionary = {}
static var _loaded := false

var char_id := ""
var anim := ""
var frame := 0
## Logical px per SPRITE px: artScale / density (4/3 for the 3x cast, 4 for 1x art).
var scale_px := 4.0
## Sprite px per art px of the variant in use (sprites.json density; 1 when absent).
var density := 1
## How a sprite is sampled when a sprite px is not a whole number of device px (k % density != 0):
## "aa" (default) = nearest texels with a one-device-px antialiased seam (the pixel-art AA shader:
## every sprite px keeps its size, edges get one blended device px instead of a 1-or-2 px stutter);
## "nearest" = plain nearest (uneven 1/2-px texels); "linear" = bilinear (soft).
static var fractional_filter := "aa"
static var _aa_shader: Shader
var paused := false
var _c: Dictionary = {}
var _a: Dictionary = {}
var _tex: Texture2D
var _t := 0.0
var _done := false


static func manifest() -> Dictionary:
	if not _loaded:
		_loaded = true
		if FileAccess.file_exists(MANIFEST):
			var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
			if parsed is Dictionary:
				_man = parsed
			else:
				push_warning("[sprites] cannot parse %s" % MANIFEST)
	return _man


## The manifest's character slug for a content id (aliases map "bengvir" to "ben-gvir").
static func resolve(id: String) -> String:
	var m := manifest()
	var chars: Dictionary = m.get("chars", {})
	if chars.has(id):
		return id
	var al: String = m.get("aliases", {}).get(id, "")
	return al if chars.has(al) else ""


static func has_char(id: String) -> bool:
	return resolve(id) != ""


static func art_scale() -> int:
	return int(manifest().get("artScale", 4))


## Builds a player for a character, or null when the manifest has no such character.
static func make(parent: Node, id: String, feet: Vector2, first_anim: String = "idle") -> SpriteStrip:
	var slug := resolve(id)
	if slug == "":
		return null
	var s := SpriteStrip.new()
	s.char_id = slug
	s._c = pick_variant(manifest()["chars"][slug], Display.k)
	s.density = maxi(1, int(s._c.get("density", manifest().get("density", 1))))
	s.scale_px = float(art_scale()) / s.density
	s._setup_filter()
	s.add_to_group("spritestrip")
	s.position = feet
	parent.add_child(s)
	s.play(first_anim)
	return s


## The character data for a device scale k: the main render, or one of its `densities`
## alternates ({"4": {frameW, frameH, anchor, anims}}), preferring the largest density that
## divides k (a whole number of device px per sprite px); the main render otherwise.
static func pick_variant(c: Dictionary, k: int) -> Dictionary:
	var best := c
	var best_d := 0
	var main_d := maxi(1, int(c.get("density", manifest().get("density", 1))))
	if k % main_d == 0:
		best_d = main_d
	var alts: Dictionary = c.get("densities", {})
	for key: Variant in alts:
		var d := int(str(key))
		if d > 0 and k % d == 0 and d > best_d:
			var v: Dictionary = c.duplicate()
			v.merge(alts[key], true)
			v["density"] = d
			v.erase("densities")
			best = v
			best_d = d
	return best


## The device scale changed (Display.k): every strip re-picks its density variant and filter.
static func refresh_all(tree: SceneTree) -> void:
	if tree == null:
		return
	for n in tree.get_nodes_in_group("spritestrip"):
		var st := n as SpriteStrip
		st._c = pick_variant(manifest()["chars"][st.char_id], Display.k)
		st.density = maxi(1, int(st._c.get("density", manifest().get("density", 1))))
		st.scale_px = float(art_scale()) / st.density
		st._setup_filter()
		var a := st.anim
		st.anim = ""
		if a != "":
			st.play(a)


func _setup_filter() -> void:
	var dev := scale_px * Display.f           # device px per sprite px
	if is_equal_approx(dev, roundf(dev)):
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		material = null
		return
	match fractional_filter:
		"nearest":
			texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		"linear":
			texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		_:
			texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			if _aa_shader == null:
				_aa_shader = Shader.new()
				_aa_shader.code = AA_SHADER
			var m := ShaderMaterial.new()
			m.shader = _aa_shader
			material = m


## Pixel-art AA: sample the texel centre except within one device px of a texel seam, where the
## bilinear filter blends exactly that px. Crisp at any fractional ratio, no uneven texel widths.
const AA_SHADER := """shader_type canvas_item;
varying vec4 modulate;
void vertex() {
	modulate = COLOR;
}
void fragment() {
	vec2 px = UV / TEXTURE_PIXEL_SIZE;
	vec2 seam = floor(px + 0.5);
	vec2 d = px - seam;
	vec2 w = max(fwidth(px), vec2(1e-5));
	px = seam + clamp(d / w, -0.5, 0.5);
	COLOR = texture(TEXTURE, px * TEXTURE_PIXEL_SIZE) * modulate;
}
"""


func has_anim(name: String) -> bool:
	return (_c.get("anims", {}) as Dictionary).has(name)


## Starts an anim (restart) or keeps it running when it already plays. `from_frame` skips the
## leading frames: action strips start at 1, because their frame 0 is idle's frame 0 pixel for
## pixel (animator, STATUS: "every action strip is entered at f1"), so f0 is pure latency.
func play(name: String, restart: bool = true, from_frame: int = 0) -> bool:
	if not has_anim(name):
		return false
	if name == anim and not restart and not _done:
		return true
	anim = name
	_a = _c["anims"][name]
	var path := String(manifest().get("root", "res://assets/sprites/")) + String(_a["texture"])
	_tex = load(path) if ResourceLoader.exists(path) else null
	var start := clampi(from_frame, 0, frame_count() - 1)
	_t = start * 1000.0 / fps()
	_done = false
	frame = start - 1
	_enter_frame(start)
	queue_redraw()
	return true


func fps() -> float:
	return maxf(1.0, float(_a.get("fps", 10)))


func frame_count() -> int:
	return maxi(1, int(_a.get("frames", 1)))


func update_view(dt_ms: float) -> void:
	if _a.is_empty() or paused or _done:
		return
	_t += dt_ms
	var n := frame_count()
	var step := 1000.0 / fps()
	var idx := int(floorf(_t / step))
	if bool(_a.get("loop", false)):
		if idx >= n:
			# a wrap: finish this cycle's events, then re-arm them for the next one
			if frame < n - 1:
				_enter_frame(n - 1)
			_t = fmod(_t, step * n)
			frame = -1
			_enter_frame(int(floorf(_t / step)))
			return
	elif idx >= n:
		if frame < n - 1:
			_enter_frame(n - 1)
		_done = true
		finished.emit(anim)
		return
	if idx != frame:
		_enter_frame(idx)


## Enters frame `idx`, firing every event on the frames passed through since the last one.
func _enter_frame(idx: int) -> void:
	var from := frame + 1
	frame = idx
	var ev: Dictionary = _a.get("events", {})
	for f in range(from, idx + 1):
		for k: String in ev:
			if int(ev[k]) == f:
				event.emit(k, f)
	queue_redraw()


## Frame size in logical px.
func frame_size() -> Vector2:
	return Vector2(float(_c.get("frameW", 0)), float(_c.get("frameH", 0))) * scale_px


func _anchor() -> Vector2:
	var a: Array = _c.get("anchor", [0, 0])
	return Vector2(float(a[0]), float(a[1]))


## The draw origin (logical), snapped so the frame's top-left sits on a whole device px.
func _origin() -> Vector2:
	var o := -_anchor() * scale_px
	return (o * Display.f).round() / Display.f


## The frame's rect in node-local logical px (the feet at the origin).
func rect() -> Rect2:
	return Rect2(_origin(), frame_size())


## A per-frame point array of the current anim (e.g. "hatMouth", "temple"), in sprite px of this
## variant, as node-local logical px; `fallback` when the anim has none.
func point(name: String, fallback: Vector2 = Vector2.ZERO) -> Vector2:
	var arr: Variant = _a.get(name)
	if not arr is Array or (arr as Array).is_empty():
		return fallback
	var p: Array = (arr as Array)[clampi(frame, 0, (arr as Array).size() - 1)]
	return (Vector2(float(p[0]), float(p[1])) - _anchor()) * scale_px


## Frame i of a strip, or of a grid when the anim wraps (cols x rows, row-major; the TA wraps
## strips wider than 2048 px).
func _src(i: int) -> Rect2:
	var fw := float(_c["frameW"])
	var fh := float(_c["frameH"])
	var cols := int(_a.get("cols", frame_count()))
	if cols <= 0:
		cols = frame_count()
	return Rect2((i % cols) * fw, (i / cols) * fh, fw, fh)


func _draw() -> void:
	if _tex == null or frame < 0:
		return
	draw_texture_rect_region(_tex, Rect2(_origin(), frame_size()), _src(frame))
