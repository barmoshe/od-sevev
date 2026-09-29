extends RefCounted
## Integer art scaling (core/display.gd, HOW-TO-RUN "Integer art scaling"): 1 art px is a whole
## number k of device px; density-d textures draw at 4/d logical px per sprite px (CONTRACT.md §3);
## and a touch in DEVICE px, pushed through a scaled viewport the way a phone's are, still lands
## on the Magician and on a shop card.

var runner: Object
var tree: SceneTree
var dir := ""
var sv: SubViewport
var m: Node


func setup(r: Object) -> void:
	TestFixture.use_game_content()   # the od money sources (taxpayer, washington) for the stage checks
	tree = r as SceneTree
	dir = "user://test_display_%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(dir)


func teardown() -> void:
	if m and is_instance_valid(m):
		m.set_process(false)
	if sv and is_instance_valid(sv):
		sv.get_parent().remove_child(sv)
		sv.queue_free()
	_use_manifest({})
	SpriteStrip.fractional_filter = "aa"
	Display.update(Vector2(720, 1280))   # the default k 4, f 1 for the tests after this one
	TestFixture.use_game_content()
	var d := DirAccess.open(dir)
	if d:
		for f in d.get_files():
			d.remove(f)
	DirAccess.remove_absolute(dir)


## Swaps the sprite manifest ({} = reload the shipped one).
func _use_manifest(man: Dictionary) -> void:
	SpriteStrip._man = man
	SpriteStrip._loaded = not man.is_empty()


## The shipped manifest as it was before the TA's re-render: Bibi and the taxpayer at density 1
## (frames, anchors and pivots a third of the size, in sprite px), no `density` keys.
func _d1_manifest() -> Dictionary:
	var man: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SpriteStrip.MANIFEST))
	for e: Dictionary in [man["chars"]["bibi"], man["sources"]["taxpayer"]]:
		var d := int(e.get("density", 1))
		for key: String in ["frameW", "frameH"]:
			e[key] = int(e[key]) / d
		for key: String in ["anchor", "pivot"]:
			if e.has(key):
				e[key] = [int(e[key][0]) / d, int(e[key][1]) / d]
		e.erase("density")
		e.erase("densities")   # the d 2 alternate postdates the d 1 manifest
		for a: Dictionary in (e.get("anims", {}) as Dictionary).values():
			a.erase("density")
			a.erase("frameMap")
	return man


# ------------------------------------------------------------------ the scale rule

func test_k_is_the_whole_device_px_per_art_px() -> void:
	# device backing stores (CSS × DPR) → k
	var cases := {Vector2(780, 1688): 4, Vector2(1170, 2532): 6, Vector2(750, 1624): 4, Vector2(1284, 2778): 7,
		Vector2(390, 844): 2, Vector2(720, 1280): 4, Vector2(1080, 2340): 6, Vector2(1280, 800): 2, Vector2(750, 1096): 4}
	for dev: Vector2 in cases:
		Display.update(dev)
		runner.check(Display.integer and Display.k == int(cases[dev]), "%s → k %d, got %d" % [dev, cases[dev], Display.k])
		runner.check(is_equal_approx(Display.device_per_art(), float(Display.k)), "%s: one art px = k device px" % dev)
	# every integer surface keeps the layout's minimum logical canvas (720 × 1068)
	for w in range(180, 1500, 37):
		for h in [267, 640, 1096, 1688, 2532, 2778]:
			Display.update(Vector2(w, h))
			var lg := Display.logical_size(Vector2(w, h))
			runner.check(lg.x >= 720.0 - 1e-3 and lg.y >= 1068.0 - 1e-3, "%dx%d keeps 720×1068 logical, got %s" % [w, h, lg])
	# too small for k = 1 (the 64×64 headless window): the fork's fractional stretch
	Display.update(Vector2(64, 64))
	runner.check(not Display.integer and is_equal_approx(Display.f, 0.05), "64×64 falls back to canvas_items + expand, f %f" % Display.f)
	runner.check(Display.logical_size(Vector2(64, 64)).is_equal_approx(Vector2(1280, 1280)), "and the fork's 1280×1280 logical canvas")
	runner.check(is_equal_approx(Display.text_scale(4.0), 4.0) and Display.snap(Vector2(1.3, 2.7)) == Vector2(1.3, 2.7), "the fallback does not snap")
	Display.update(Vector2(1170, 2532))
	runner.check(is_equal_approx(Display.text_scale(4.0) * Display.f, 6.0) and is_equal_approx(Display.text_scale(5.0) * Display.f, 8.0),
		"text at k 6: ×4 = 6 device px per font px, large text ×5 rounds to 8")
	Display.update(Vector2(1170, 2532), true)
	runner.check(not Display.integer and is_equal_approx(Display.f, 1170.0 / 720.0), "--fork-scale forces the old 1.625 stretch")


# ------------------------------------------------------------------ density from the data

func test_density_one_and_three_from_the_manifest() -> void:
	var parent := Node2D.new()
	tree.root.add_child(parent)
	await tree.process_frame   # inside the tree, so refresh_all's group lookups see the strips
	Display.update(Vector2(780, 1688))   # k 4
	# the shipped manifest (the TA's 3x cast): Bibi d 3, the small Dubi d 1, read from the data
	var s3 := SpriteStrip.make(parent, "bibi", Vector2(376, 876))
	var dubi := SpriteStrip.make(parent, "dubi", Vector2(600, 876))
	var c: Dictionary = SpriteStrip.manifest()["chars"]["bibi"]
	runner.check(dubi.density == 1 and is_equal_approx(dubi.scale_px, 4.0), "the small Dubi d 1: ×4")
	runner.check(dubi.material == null and dubi.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "d 1 at k 4: nearest")
	# the TA's d 2 alternate (every DPR-2 phone is k 4): 2 device px per sprite px, crisp
	var c2: Dictionary = c.get("densities", {}).get("2", {})
	runner.check(not c2.is_empty(), "the manifest carries Bibi's d 2 alternate")
	runner.check(s3.density == 2 and is_equal_approx(s3.scale_px, 2.0), "k 4 picks Bibi's d 2: 2 logical px per sprite px (d %d)" % s3.density)
	runner.check(s3.frame_size().is_equal_approx(Vector2(float(c2.get("frameW", 0)), float(c2.get("frameH", 0))) * 2.0), "and the d 2 frame size")
	runner.check(s3.material == null and s3.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "d 2 at k 4: nearest, no fallback shader")
	runner.check(String(s3._a["texture"]).ends_with("_d2.png"), "and the d 2 texture (%s)" % s3._a["texture"])
	var o: Vector2 = s3.rect().position * Display.f
	runner.check(o.is_equal_approx(o.round()), "the frame's top-left sits on a whole device px (%s)" % o)
	# k 7 (430 @3): no density divides it, so the main d 3 render on the 'aa' fallback
	Display.update(Vector2(1284, 2778))
	SpriteStrip.refresh_all(tree)
	runner.check(s3.density == 3 and is_equal_approx(s3.scale_px, 4.0 / 3.0), "k 7: Bibi d 3, 4/3 logical px per sprite px (d %d)" % s3.density)
	runner.check(s3.frame_size().is_equal_approx(Vector2(float(c["frameW"]), float(c["frameH"])) * 4.0 / 3.0), "Bibi's d 3 frame is frameW·4/3 logical")
	runner.check(s3.material is ShaderMaterial, "k 7 is not a multiple of 3: the 'aa' fallback filter")
	SpriteStrip.fractional_filter = "nearest"
	SpriteStrip.refresh_all(tree)
	runner.check(s3.material == null and s3.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "fractional_filter 'nearest' is honoured")
	SpriteStrip.fractional_filter = "aa"
	for k: int in [6, 9]:
		Display.update(Vector2(180 * k, 2800))
		SpriteStrip.refresh_all(tree)
		runner.check(Display.k == k and s3.material == null and s3.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST,
			"k %d: a sprite px is %d device px, nearest" % [k, k / 3])
	# the money sources on the stage: taxpayer rendered (d 3), washington → the hand-drawn checkbook (d 1)
	Display.update(Vector2(780, 1688))
	var spr := Sprite2D.new()
	parent.add_child(spr)
	Diorama._scale_sprite(spr, "taxpayer")
	runner.check(spr.scale.is_equal_approx(Vector2.ONE * 4.0 / 3.0), "a d 3 source draws at 4/3, got %s" % spr.scale)
	runner.check(spr.material is ShaderMaterial, "and gets the fallback filter at k 4")
	Display.update(Vector2(1170, 2532))
	SpriteStrip.refresh_all(tree)
	runner.check(spr.material == null, "and nearest at k 6 after a scale change")
	var spr1 := Sprite2D.new()
	parent.add_child(spr1)
	Diorama._scale_sprite(spr1, "washington")
	runner.check(spr1.scale.is_equal_approx(Vector2(4, 4)) and spr1.material == null, "the d 1 checkbook stays ×4, nearest")
	# the manifest before the re-render (no density keys): d 1, ×4, the same size on screen
	var size3: Vector2 = s3.frame_size()
	_use_manifest(_d1_manifest())
	var s1 := SpriteStrip.make(parent, "bibi", Vector2(376, 876))
	runner.check(s1.density == 1 and is_equal_approx(s1.scale_px, 4.0), "no density key: d 1, 4 logical px per sprite px")
	runner.check(absf(s1.frame_size().x - size3.x) <= 4.0 and absf(s1.frame_size().y - size3.y) <= 4.0,
		"the same size on screen at both densities (%s vs %s)" % [s1.frame_size(), size3])
	runner.check(is_equal_approx(Diorama._scale_of("taxpayer").x, 4.0), "a d 1 taxpayer draws at ×4")
	# frameMap (the TA's VRAM offer): repeated frames share one texture cell; frames stays the count
	var st := SpriteStrip.make(parent, "bibi", Vector2(376, 876))
	var cols := int(st._a.get("cols", st.frame_count()))
	st._a = st._a.duplicate()
	st._a.erase("frameMap")
	runner.check(st._src(cols + 1).position == Vector2(float(st._c["frameW"]), float(st._c["frameH"])), "no frameMap: frame i is cell i (row-major grid)")
	st._a["frameMap"] = [0, 1, 0, 1]
	runner.check(st._src(2) == st._src(0) and st._src(3).position.x == float(st._c["frameW"]), "frameMap: frame 2 draws cell 0, frame 3 cell 1")
	# the shipped frameMaps (every render, every density): one cell per frame, inside the cols × rows
	# grid, and the texture holds that grid (manifest `files` sizes)
	var man := SpriteStrip.manifest()
	var maps := 0
	for slug: String in man["chars"]:
		var ch: Dictionary = man["chars"][slug]
		var renders: Array = [ch]
		for dk: String in ch.get("densities", {}):
			var v: Dictionary = ch.duplicate()
			v.merge(ch["densities"][dk], true)
			renders.append(v)
		for v: Dictionary in renders:
			for an: String in v["anims"]:
				var a: Dictionary = v["anims"][an]
				if not a.has("frameMap"):
					continue
				maps += 1
				var fm: Array = a["frameMap"]
				var cells := int(a["cols"]) * int(a["rows"])
				var ok := fm.size() == int(a["frames"]) and int(fm[0]) == 0
				for cell: Variant in fm:
					ok = ok and int(cell) >= 0 and int(cell) < cells
				var sz: Array = man["files"].get(a["texture"], {}).get("size", [0, 0])
				ok = ok and int(sz[0]) == int(a["cols"]) * int(v["frameW"]) and int(sz[1]) == int(a["rows"]) * int(v["frameH"])
				runner.check(ok, "%s.%s (d %s): frameMap fits its %dx%d grid" % [slug, an, v.get("density", 1), a["cols"], a["rows"]])
	runner.check(maps > 0, "the manifest ships frameMaps (%d anims)" % maps)
	# a density alternate that divides k wins (the TA may ship both)
	var alt := {"density": 3, "frameW": 243, "anims": {}, "densities": {"2": {"frameW": 162}}}
	runner.check(int(SpriteStrip.pick_variant(alt, 4)["density"]) == 2, "k 4 picks the d 2 alternate")
	runner.check(int(SpriteStrip.pick_variant(alt, 6)["density"]) == 3, "k 6 keeps the d 3 render")
	runner.check(int(SpriteStrip.pick_variant(alt, 7).get("density", 0)) == 3, "k 7 (no divisor) keeps the main render")
	parent.queue_free()


# ------------------------------------------------------------------ touch through the scaled viewport

## Boots the main scene into a SubViewport of `dev` device px (a phone's backing store).
func _boot_device(dev: Vector2i) -> void:
	TestFixture.use_fork_content()   # the input router is under test, as in test_input.gd
	sv = SubViewport.new()
	sv.size = dev
	tree.root.add_child(sv)
	m = load("res://scenes/main.tscn").instantiate()
	m.store = SaveStore.new(dir)
	sv.add_child(m)
	for i in 3:
		await tree.process_frame


## A touch at a logical point, delivered in DEVICE px (logical × k/4) through the viewport's own
## input path, as the browser delivers it.
func _touch(logical: Vector2, k: int, idx: int = 0) -> void:
	var dev := logical * (k / 4.0)
	for pressed in [true, false]:
		var e := InputEventScreenTouch.new()
		e.index = idx
		e.position = dev
		e.pressed = pressed
		sv.push_input(e)


func _device_tap_and_buy(dev: Vector2i, k: int) -> void:
	await _boot_device(dev)
	var f := k / 4.0
	runner.check(Display.integer and Display.k == k, "%s: k %d, got %d" % [dev, k, Display.k])
	var t := sv.get_final_transform()
	runner.check(t.get_scale().is_equal_approx(Vector2(f, f)) and t.origin == Vector2.ZERO, "%s: the viewport stretch is ×%.2f, got %s" % [dev, f, t])
	runner.check(m.get_viewport_rect().size.is_equal_approx((Vector2(dev) / f).floor()), "%s: logical %s" % [dev, m.get_viewport_rect().size])
	for v: float in [m._ox, m._top_y, m._stage_y, m._lower_y]:
		runner.check(is_equal_approx(fmod(v * f, 1.0), 0.0), "%s: section offset %.1f is a whole device px" % [dev, v])
	var hat: Vector2 = L.magician_hit().get_center() + Vector2(m._ox, m._stage_y)
	_touch(hat, k)
	runner.check(m.mode == "main" and m.state.taps_lifetime == 1, "%s: a device-px tap on the Magician starts the game (%s, %d)" % [dev, m.mode, m.state.taps_lifetime])
	for i in 2:
		_touch(hat + Vector2(0, 12 * i), k, i)
	runner.check(m.state.taps_lifetime == 3, "%s: taps 2 and 3 land (%d)" % [dev, m.state.taps_lifetime])
	Economy.add_bananas(m.state, 100.0)
	for i in 3:
		await tree.process_frame
	var row: int = m.shop.row_index_of(m.state, "producer", "intern")
	var card := Vector2(400, float(L.SHOP["listY"]) + float(L.SHOP["rowPitch"]) * row + 60.0) + Vector2(160, 0)
	_touch(card + Vector2(m._ox, m._lower_y), k)
	runner.check(m.state.owned_of("intern") == 1, "%s: a device-px tap on card 1 buys the first source" % dev)


func test_device_touch_at_dpr_2() -> void:
	await _device_tap_and_buy(Vector2i(780, 1688), 4)   # 390×844 CSS @2


func test_device_touch_at_dpr_3() -> void:
	await _device_tap_and_buy(Vector2i(1170, 2532), 6)  # 390×844 CSS @3
