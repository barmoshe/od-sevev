extends SceneTree
## Dev proof for the 3x cast at k = 4 device px per art px (a sprite px is then 4/3 device px):
## renders the same density-3 frame with each fractional filter SpriteStrip offers, plus the
## 1x strip at k 4 and the density-3 strip at k 6 (2 whole device px per sprite px) for reference,
## into one PNG with a 3x nearest zoom of the face under each panel.
##   godot --path game -s res://tests/dev/density_compare.gd -- --d3=<bibi_idle.png density 3>
##         --frames=<n> --x1=<res:// 1x strip> --x1frames=<n> --out=<png>

var args := {}


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		if kv.size() == 2:
			args[kv[0]] = kv[1]
	_run.call_deferred()


func _tex(path: String) -> Texture2D:
	if path.begins_with("res://"):
		return load(path)
	return ImageTexture.create_from_image(Image.load_from_file(path))


func _panel(sv: SubViewport, x: float, tex: Texture2D, frames: int, dev_per_px: float, filter: String) -> float:
	var n := Node2D.new()
	sv.add_child(n)
	var fw := float(tex.get_width()) / frames
	var fh := float(tex.get_height())
	var sz := (Vector2(fw, fh) * dev_per_px).round()
	n.position = Vector2(x, 40)
	match filter:
		"nearest":
			n.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		"linear":
			n.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		"aa":
			n.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			var sh := Shader.new()
			sh.code = SpriteStrip.AA_SHADER
			var m := ShaderMaterial.new()
			m.shader = sh
			n.material = m
	n.draw.connect(func() -> void: n.draw_texture_rect_region(tex, Rect2(Vector2.ZERO, sz), Rect2(0, 0, fw, fh)))
	return sz.x


func _run() -> void:
	var d3 := _tex(String(args.get("d3", "")))
	var x1 := _tex(String(args.get("x1", "res://assets/sprites/cast/bibi_idle.png")))
	var n3 := int(args.get("frames", "20"))
	var n1 := int(args.get("x1frames", "20"))
	var sv := SubViewport.new()
	sv.size = Vector2i(1820, 640)
	sv.transparent_bg = false
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(sv)
	var bg := ColorRect.new()
	bg.color = Color("#2a2340")
	bg.size = Vector2(sv.size)
	sv.add_child(bg)
	var panels := [["d3 k4 nearest", d3, n3, 4.0 / 3.0, "nearest"], ["d3 k4 linear", d3, n3, 4.0 / 3.0, "linear"],
		["d3 k4 aa", d3, n3, 4.0 / 3.0, "aa"], ["1x k4", x1, n1, 4.0, "nearest"], ["d3 k6 (whole px)", d3, n3, 2.0, "nearest"]]
	var x := 20.0
	var xs: Array = []
	for p: Array in panels:
		xs.append(x)
		x += _panel(sv, x, p[1], p[2], p[3], p[4]) + 30.0
	for i in 6:
		await process_frame
	await RenderingServer.frame_post_draw
	var img := sv.get_texture().get_image()
	img.save_png(String(args.get("out", "user://density_compare.png")))
	print("DENSITY ", String(args.get("out", "")), " panels ", ", ".join(panels.map(func(p: Array) -> String: return p[0])), " at x ", xs)
	quit(0)
