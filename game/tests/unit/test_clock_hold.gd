extends RefCounted
## The round's clock holds while the player reads a menu (main.clock_held, 2026-10-03, the
## overwhelm report): settings, the missions sheet, the dossier. Play keeps it running: the
## coalition chat and the overlays that are play themselves (Overlay.holds_clock false).

var runner: Object
var tree: SceneTree
var dir := ""
var m: Node


func setup(r: Object) -> void:
	TestFixture.use_game_content()
	tree = r as SceneTree
	dir = "user://test_clock_hold_%d" % Time.get_ticks_usec()
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
	m.set_process(false)


func _frames(n: int, ms := 16.0) -> void:
	for i in n:
		m._process(ms / 1000.0)


func _start() -> bool:
	if Leaders.pick_pending(m.state) and not m.commit_pick("bibi"):
		return false
	_frames(2)
	var at: Vector2 = L.magician_hit().get_center() + Vector2(m._sx, m._stage_y)
	for pressed in [true, false]:
		var e := InputEventScreenTouch.new()
		e.position = at
		e.pressed = pressed
		m._unhandled_input(e)
	return m.mode == "main"


func test_a_menu_holds_the_round_and_play_does_not() -> void:
	await _boot()
	runner.check(_start(), "the round starts")
	_frames(30)
	var t0: float = m.state.run_time_sec
	_frames(60)
	runner.check(m.state.run_time_sec > t0, "the round runs")
	m._open_settings()
	_frames(2)
	runner.check(m.overlays.is_open() and m.clock_held(), "settings is a menu: the clock holds")
	var t1: float = m.state.run_time_sec
	_frames(120)
	runner.check(is_equal_approx(m.state.run_time_sec, t1), "nothing moves under settings (%s → %s)" % [t1, m.state.run_time_sec])
	m.overlays.close(m.overlays.top(), "test")
	_frames(30)
	runner.check(not m.clock_held(), "closed, the clock runs again")
	var t2: float = m.state.run_time_sec
	_frames(60)
	runner.check(m.state.run_time_sec > t2, "and the round moves on")
