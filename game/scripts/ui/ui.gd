class_name Ui
extends RefCounted
## Small render helpers over the Art baker: 9-slices, sprites, solid rects, easing.
## Everything is a plain CanvasItem with mouse input ignored; MainController routes input by rect.


## A pixel 9-slice at art scale 4: `r` is in logical px and must be a multiple of 4.
static func nine(parent: Node, r: Rect2, id: String, frame: int = 0, scale_px: int = 4) -> NinePatchRect:
	var n := NinePatchRect.new()
	n.texture = Art.tex(id, frame)
	var ins: Dictionary = Art.insets(id)
	n.patch_margin_left = int(ins["left"])
	n.patch_margin_right = int(ins["right"])
	n.patch_margin_top = int(ins["top"])
	n.patch_margin_bottom = int(ins["bottom"])
	n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	n.scale = Vector2(scale_px, scale_px)
	n.position = r.position
	n.size = r.size / float(scale_px)
	n.set_meta("sprite", id)
	parent.add_child(n)
	return n


static func set_nine_frame(n: NinePatchRect, id: String, frame: int) -> void:
	var t := Art.tex(id, frame)
	if n.texture != t:
		n.texture = t


static func set_nine_rect(n: NinePatchRect, r: Rect2, scale_px: int = 4) -> void:
	n.position = r.position
	n.size = r.size / float(scale_px)


## A sprite with its top-left at `pos`, drawn at an integer scale.
static func img(parent: Node, pos: Vector2, id: String, frame: int = 0, scale_px: int = 4) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = Art.tex(id, frame)
	s.centered = false
	s.scale = Vector2(scale_px, scale_px)
	s.position = pos
	s.set_meta("sprite", id)
	parent.add_child(s)
	return s


static func set_frame(s: Sprite2D, id: String, frame: int) -> void:
	var t := Art.tex(id, frame)
	if s.texture != t:
		s.texture = t


static var _fill_shader: Shader


## A material that draws a sprite's silhouette in one colour (Phaser's FILL tint mode): drop
## shadows and flash fills.
static func fill_material(c: Color) -> ShaderMaterial:
	if _fill_shader == null:
		_fill_shader = Shader.new()
		_fill_shader.code = "shader_type canvas_item;\nuniform vec4 fill_color : source_color = vec4(1.0);\nvoid fragment() {\n\tvec4 t = texture(TEXTURE, UV);\n\tCOLOR = vec4(fill_color.rgb, t.a * fill_color.a * COLOR.a);\n}\n"
	var m := ShaderMaterial.new()
	m.shader = _fill_shader
	m.set_shader_parameter("fill_color", c)
	return m


static func rect(parent: Node, r: Rect2, c: Variant, alpha: float = 1.0) -> ColorRect:
	var cr := ColorRect.new()
	cr.position = r.position
	cr.size = r.size
	var col: Color = c if c is Color else Art.col(c)
	col.a = alpha
	cr.color = col
	cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(cr)
	return cr


## A solid rect that starts hidden and is faded through `modulate.a` (scrims, dims, flashes).
## The colour stays opaque: `rect(..., 0.0)` bakes alpha 0 into the colour, and colour alpha
## multiplies modulate alpha, so a fade on such a rect never shows anything.
static func fade_rect(parent: Node, r: Rect2, c: Variant) -> ColorRect:
	var cr := rect(parent, r, c, 1.0)
	cr.modulate.a = 0.0
	return cr


static func in_rect(r: Rect2, p: Vector2) -> bool:
	return p.x >= r.position.x and p.x < r.end.x and p.y >= r.position.y and p.y < r.end.y


## Centred text x: floor4((regionW − textW)/2) + regionX.
static func center_x(text: String, s: int, region_x: float, region_w: float) -> float:
	return 4.0 * floorf((region_w - PxText.measure(text, s)) / 2.0 / 4.0) + region_x


static func snap(v: float, g: float) -> float:
	return roundf(v / g) * g


static func back_out(v: float, s: float) -> float:
	var k := v - 1.0
	return k * k * ((s + 1.0) * k + s) + 1.0


static func quad_out(v: float) -> float:
	return 1.0 - (1.0 - v) * (1.0 - v)


static func quad_in(v: float) -> float:
	return v * v


static func cubic_out(v: float) -> float:
	return 1.0 - pow(1.0 - v, 3.0)


static func clamp01(v: float) -> float:
	return clampf(v, 0.0, 1.0)


## Fills {placeholder} tokens in a ux/ui-strings.json string. A missing id fails loudly.
static func s(id: String, params: Dictionary = {}) -> String:
	return Strings.s(id, params)
