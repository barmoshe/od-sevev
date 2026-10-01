extends RefCounted
## The funnel events the analytics read (main.gd _funnel → window.odTrackFunnel in shell.html, which
## turns a few into the virtual page views /play/first-tap, /play/picked/<id>, /play/first-election,
## /play/share/<kind>/<result>). The web sink can't run headless, so this checks the events
## themselves through funnel_sent. Runs the real scene on the shipped design content.

var runner: Object
var tree: SceneTree
var dir := ""
var m: Node
var sent: Array = []


func setup(r: Object) -> void:
	TestFixture.use_game_content()
	tree = r as SceneTree
	dir = "user://test_funnel_%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(dir)
	sent = []


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
	m.funnel_sent.connect(func(n: String, p: Dictionary) -> void: sent.append([n, p]))


func _named(n: String) -> Array:
	return sent.filter(func(x: Array) -> bool: return x[0] == n)


func test_a_pick_reports_the_leader() -> void:
	await _boot()
	m.commit_pick("deri")
	var picks := _named("leader_pick_committed")
	runner.check(picks.size() == 1 and picks[0][1].get("leader") == "deri", "the pick reports its leader (%s)" % [picks])


func test_the_first_tap_is_reported_once() -> void:
	await _boot()
	m.commit_pick("bibi")
	var at: Vector2 = L.magician_hit().get_center() + Vector2(m._sx, m._stage_y)
	for i in 3:
		m._handle_tap(at)
	runner.check(_named("first_tap").size() == 1, "first_tap once in three taps (%d)" % _named("first_tap").size())


func test_an_election_reports_its_number() -> void:
	await _boot()
	m.commit_pick("bennett")
	m._set_mode("main", false)
	m._dev["on"] = true   # the dev-forced ceremony (no 61 gate), as test_leader_walk
	m._start_evolve(true)
	var els := _named("election_called")
	runner.check(els.size() == 1 and int(els[0][1].get("n", 0)) == 1, "the first election reports n = 1 (%s)" % [els])


func test_a_share_result_is_reported() -> void:
	await _boot()
	m._on_share_result("receipt", "shared")
	var sh := _named("share_done")
	runner.check(sh.size() == 1 and sh[0][1].get("kind") == "receipt" and sh[0][1].get("result") == "shared",
		"the share result is reported with its kind (%s)" % [sh])
