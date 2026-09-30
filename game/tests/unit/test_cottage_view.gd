extends RefCounted
## Row A's Cottage Index (ui/views/view_cottage.gd, ux/rtl-map.md §2, ux/ftue.md Q1, motion
## cottage-pixel-loss): hidden until 1,000 ₪ lifetime, a pixel lost at every ×10, 50% at rest and
## 100% for 3 s after a change, and a tap on its 88×88 hit opens the HUD_COTTAGE_TIP toast.

var runner: Object
var tree: SceneTree
var dir := ""
var m: Node


func setup(r: Object) -> void:
	TestFixture.use_game_content()
	tree = r as SceneTree
	dir = "user://test_cottage_%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(dir)


func teardown() -> void:
	if m and is_instance_valid(m):
		m.set_process(false)
		if m.get_parent():
			m.get_parent().remove_child(m)
		m.queue_free()
	var d := DirAccess.open(dir)
	if d:
		for f in d.get_files():
			d.remove(f)
	DirAccess.remove_absolute(dir)


func _boot() -> void:
	m = load("res://scenes/main.tscn").instantiate()
	m.store = SaveStore.new(dir)
	tree.root.add_child(m)
	for i in 3:
		await tree.process_frame
	m.ftue.handoff_ms = 1.0
	m.commit_pick("bibi")   # LEADER_PICK (leader select): Bibi's round, the shipped game
	_touch(L.magician_hit().get_center() + Vector2(m._sx, m._stage_y))   # title → main


func _touch(p: Vector2) -> void:
	for pressed in [true, false]:
		var e := InputEventScreenTouch.new()
		e.position = p
		e.pressed = pressed
		m._unhandled_input(e)


func _frames(n: int) -> void:
	for i in n:
		await tree.process_frame


func test_the_cup_appears_at_1000_and_loses_a_pixel_per_x10() -> void:
	await _boot()
	await _frames(2)
	var c: CottageCup = m.cottage
	runner.check(not c.visible and not c.shown(), "hidden before 1,000 ₪ lifetime")
	m.state.all_time_bananas = 1500.0
	await _frames(2)
	runner.check(c.visible and c.shown() and c.frame() == 1, "Q1: the cup appears on frame 1 (frame %d)" % c.frame())
	runner.check(c.events.has("appear") and c.events.has("drop:1"), "it appears and drops its first pixel (%s)" % str(c.events))
	var r: Rect2 = L.TOP["cottageHit"]
	# mobile-first §5.1.1 (A7/B10): one slot left of the identity chip's face (624-712)
	runner.check(r == Rect2(536, 4, 88, 88) and c.hit_rect() == r, "the hit is 88×88, left of the face at Row A's right end")
	await tree.create_timer(0.25).timeout   # past the appear hop
	var cup: Sprite2D = c._cup
	var sz := Vector2(Art.sprite_size(cup.get_meta("sprite"))) * cup.scale
	runner.check(sz == Vector2(64, 72) and cup.position + c.position == Vector2(548, 12), "the kit cup at ×4: 64×72 at (548, 12) in Row A, got %s at %s" % [sz, cup.position + c.position])
	m.state.all_time_bananas = 2.0e4
	await _frames(2)
	runner.check(c.frame() == 2 and c.events.has("drop:2"), "10,000 ₪: frame 2 (frame %d)" % c.frame())
	m.state.all_time_bananas = 2.0e14
	await _frames(2)
	runner.check(c.frame() == 12, "10^14 ₪: frame 12, every pixel gone (frame %d)" % c.frame())
	# an election keeps the lifetime treasury: the cup stays
	var s2 := GameState.fresh()
	s2.all_time_bananas = 2.0e14
	c.update_view(16.0, s2, true)
	runner.check(c.frame() == 12 and c.shown(), "a fresh round with the same lifetime keeps the frame")


func test_opacity_rests_at_half_and_lights_on_a_change() -> void:
	var c := CottageCup.new()
	tree.root.add_child(c)
	var s := GameState.fresh()
	s.all_time_bananas = 5.0e6
	c.update_view(16.0, s, true)
	runner.check(c.shown() and c.frame() == 4 and c.events == ["show"], "a save that loads revealed just shows it (%s)" % str(c.events))
	runner.check(is_equal_approx(c.alpha(), 0.5), "50%% at rest (%s)" % c.alpha())
	s.all_time_bananas = 5.0e7
	c.update_view(16.0, s, true)
	c.update_view(200.0, s, true)
	runner.check(c.frame() == 5 and is_equal_approx(c.alpha(), 1.0), "a lost pixel: 100%% (%s)" % c.alpha())
	c.update_view(2500.0, s, true)
	runner.check(is_equal_approx(c.alpha(), 1.0), "held for 3 s")
	c.update_view(1000.0, s, true)
	runner.check(is_equal_approx(c.alpha(), 0.5), "then back to 50%% (%s)" % c.alpha())
	c.update_view(16.0, s, false)
	runner.check(not c.visible and not c.contains(Vector2(668, 48)), "hidden with Row A (title, election)")
	c.queue_free()


func test_a_tap_opens_the_tooltip_toast() -> void:
	await _boot()
	m.state.all_time_bananas = 1500.0
	await _frames(3)
	var c: CottageCup = m.cottage
	var p: Vector2 = c.hit_rect().get_center() + Vector2(m._ox, m._top_y)
	_touch(p)
	var tip := Strings.s("HUD_COTTAGE_TIP")
	var toasts: Toasts = m.toasts
	runner.check(c.events.has("tip"), "the tap reached the cup (%s)" % str(c.events))
	runner.check(toasts._queue.has(tip) or toasts._text.text == tip, "HUD_COTTAGE_TIP goes to the toast dock")
	_touch(p)
	var n := 0
	for t: String in toasts._queue:
		if t == tip:
			n += 1
	runner.check(n + (1 if toasts._text.text == tip and toasts._text.visible else 0) == 1, "a second tap does not queue the tip twice")
	runner.check(m.state.taps_lifetime == 1, "the cup's hit does not tap the Magician")
	# the corners of the hit and the gear/mute neighbours
	runner.check(c.contains(Vector2(536, 4)) and c.contains(Vector2(623, 91)) and not c.contains(Vector2(532, 48)) and not c.contains(Vector2(628, 48)), "88×88, no more")
