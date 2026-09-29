extends RefCounted
## The desktop phone frame (game/web/shell.html odFit, ux/first-minute.md §1.3): on a wide window
## with a mouse the canvas is a 390-CSS column, min(844, window − 48) CSS tall, whose backing store
## is exactly CSS × DPR. These are the backing stores odFit gives on common desktop windows; at each
## the engine's integer scale must hold (core/display.gd: a whole k, every section on a whole device
## px, device-px touches landing) and Dubi's news flash must fit at an integer art scale.
## (tools/web/views_web.mjs checks odFit itself in Chromium at 1440×900.)

## window CSS @ DPR → the frame's backing store (odFit) and the k it must give
const FRAMES := [
	{"window": "1440x900@1", "device": Vector2i(390, 844), "k": 2},
	{"window": "1152x720@1.25", "device": Vector2i(488, 840), "k": 2},
	{"window": "960x600@1.5", "device": Vector2i(585, 828), "k": 3},
	{"window": "1440x900@2", "device": Vector2i(780, 1688), "k": 4},
]

var runner: Object
var tree: SceneTree
var dir := ""
var sv: SubViewport
var m: Node


func setup(r: Object) -> void:
	TestFixture.use_game_content()
	tree = r as SceneTree
	dir = "user://test_frame_%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(dir)


func teardown() -> void:
	_drop()
	Display.update(Vector2(720, 1280))
	var d := DirAccess.open(dir)
	if d:
		for f in d.get_files():
			d.remove(f)
	DirAccess.remove_absolute(dir)


func _drop() -> void:
	if m and is_instance_valid(m):
		m.set_process(false)
	if sv and is_instance_valid(sv):
		sv.get_parent().remove_child(sv)
		sv.queue_free()
	m = null
	sv = null


## The odFit rule, restated for the table's check: 390 CSS wide, min(844, ih − 48) tall, × DPR.
static func odfit(win: Vector2, dpr: float) -> Vector2i:
	return Vector2i(roundi(390.0 * dpr), floori(maxf(1.0, minf(844.0, win.y - 48.0)) * dpr))


func test_the_frame_sizes_keep_a_whole_art_scale() -> void:
	for fr: Dictionary in FRAMES:
		var parts := String(fr["window"]).split("@")
		var wh := parts[0].split("x")
		var dev := odfit(Vector2(float(wh[0]), float(wh[1])), float(parts[1]))
		runner.check(dev == fr["device"], "%s: odFit gives %s, got %s" % [fr["window"], fr["device"], dev])
		Display.update(Vector2(dev))
		runner.check(Display.integer and Display.k == int(fr["k"]), "%s: k %d, got %d" % [fr["window"], fr["k"], Display.k])
		runner.check(is_equal_approx(Display.device_per_art(), float(Display.k)), "one art px = k device px")
		var lg := Display.logical_size(Vector2(dev))
		runner.check(lg.x >= 720.0 and lg.y >= 1068.0, "the column and the minimum layout fit (%s)" % lg)
		# text: every body glyph px a whole number of device px
		runner.check(is_equal_approx(fmod(Display.text_scale(4.0) * Display.f, 1.0), 0.0), "text ×4 is whole device px at k %d" % Display.k)


func _touch(logical: Vector2, k: int) -> void:
	for pressed in [true, false]:
		var e := InputEventScreenTouch.new()
		e.position = logical * (k / 4.0)
		e.pressed = pressed
		sv.push_input(e)


func test_the_game_in_the_frame_is_integer_and_playable() -> void:
	for fr: Dictionary in FRAMES.slice(0, 3):
		var dev: Vector2i = fr["device"]
		var k := int(fr["k"])
		TestFixture.use_game_content()
		sv = SubViewport.new()
		sv.size = dev
		tree.root.add_child(sv)
		m = load("res://scenes/main.tscn").instantiate()
		m.store = SaveStore.new(dir)
		sv.add_child(m)
		for i in 3:
			await tree.process_frame
		m.ftue.handoff_ms = 1.0
		var f := k / 4.0
		runner.check(Display.integer and Display.k == k, "%s: k %d (got %d)" % [dev, k, Display.k])
		runner.check(sv.get_final_transform().get_scale().is_equal_approx(Vector2(f, f)), "%s: the stretch is ×%.2f" % [dev, f])
		for v: float in [m._ox, m._top_y, m._stage_y, m._lower_y, m._ovl_y]:
			runner.check(is_equal_approx(fmod(absf(v) * f, 1.0), 0.0), "%s: section offset %.1f is a whole device px" % [dev, v])
		var taps: int = m.state.taps_lifetime   # the boots share a save folder
		_touch(L.magician_hit().get_center() + Vector2(m._ox, m._stage_y), k)
		runner.check(m.mode == "main" and m.state.taps_lifetime == taps + 1, "%s: a device-px tap on the Magician lands" % dev)
		# Dubi's flash fits the frame's band at an integer art scale, on whole device px
		m.show_flash(1)
		await tree.create_timer(0.45).timeout
		var fc: FlashCard = m.overlays.top() as FlashCard
		runner.check(fc != null, "%s: the flash opens" % dev)
		if fc:
			var band := fc._band()
			runner.check(fc.panel_rect.position.y >= band.x and fc.panel_rect.end.y <= band.y,
				"%s: the card (%s) fits the visible band %s at ×%d" % [dev, fc.panel_rect, band, fc.art_scale])
			var o: Vector2 = (fc.strip.position + fc.strip.rect().position + fc.screen_rect.position + Vector2(m._ox, m._ovl_y)) * Display.f
			runner.check(o.is_equal_approx(o.round()), "%s: the figure's top-left is a whole device px (%s)" % [dev, o])
		_drop()
		await tree.process_frame
