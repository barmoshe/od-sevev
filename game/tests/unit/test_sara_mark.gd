extends RefCounted
## Sara on the Balfour stage (SaraMark; motion/state-graph-cast.md §3, Bar's option B): Bibi's round
## only, Balfour only, off while Mordechai David's blockade holds the same mark, the S01 huff after the
## reaction delay with its cooldown. The integration cases boot the real scene on the game content.

var runner: Object
var tree: SceneTree
var dir := ""
var m: Node


func setup(r: Object) -> void:
	TestFixture.use_game_content()
	tree = r as SceneTree
	dir = "user://test_sara_mark_%d" % Time.get_ticks_usec()
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


func _boot(reduced := false) -> void:
	m = load("res://scenes/main.tscn").instantiate()
	m.store = SaveStore.new(dir)
	tree.root.add_child(m)
	for i in 3:
		await tree.process_frame
	m.ftue.handoff_ms = 1.0
	m.set_process(false)   # the test drives the clock itself
	m.settings["reducedMotion"] = reduced
	m.bb.set_reduced_motion(reduced)
	m.picker.reduced_motion = reduced
	m.street.reduced_motion = reduced


## The pick (landed, no walk), then tap 1: the round's clock runs from here.
func _start_round(id := "bibi") -> bool:
	if not m.commit_pick(id):
		return false
	_frames(2)
	var at: Vector2 = L.magician_hit().get_center() + Vector2(m._sx, m._stage_y)
	for pressed in [true, false]:
		var e := InputEventScreenTouch.new()
		e.position = at
		e.pressed = pressed
		m._unhandled_input(e)
	return m.mode == "main"


func _frames(n: int, ms := 16.0) -> void:
	for i in n:
		m._process(ms / 1000.0)


## Seats the round's partners so one small partner (1-4 seats) can be stuck; returns its id.
func test_only_in_bibis_round() -> void:
	var s := GameState.new()
	s.events = {"active": []}   # a bare state has no scheduler yet; the blockade check reads its live effects
	s.leader = "bibi"
	runner.check(SaraMark.wanted(s, true), "Bibi's round, on the Balfour stage: she is there")
	runner.check(not SaraMark.wanted(s, false), "off the Balfour stage (another era, or not running): she is not")
	s.leader = "bennett"
	runner.check(not SaraMark.wanted(s, true), "another leader's round: never")
	runner.check(SaraMark.mark().x > L.magician_feet().x, "her mark is right of the leader (option B)")


func test_she_visits_to_huff_at_the_bottle_deposits() -> void:
	await _boot(true)   # reduced motion: no walk, every step lands on a frame
	runner.check(_start_round(), "the pick and tap 1 start the round")
	_frames(30)
	var sara: SaraMark = m.sara
	sara.reduced_motion = true
	runner.check(m.diorama.era_id() == "balfour" and not sara.showing(), "Bar 2026-10-01: not on stage the whole round")
	sara.offend()
	_frames(2)
	runner.check(sara.showing() and sara.position == SaraMark.mark(), "S01: she comes in, on her mark")
	_frames(10)       # the 150 ms reaction delay runs from her arrival
	runner.check(sara.strip.anim == "offended", "and huffs after the reaction delay")
	_frames(80)
	runner.check(sara.strip.anim == "idle", "back to idle after the huff")
	sara.offend()
	_frames(20)
	runner.check(sara.strip.anim == "idle", "a second trigger inside the 8 s cooldown is dropped")
	m._on_politics_event(Events.fire(m.state, "mordechai", m.d, func() -> float: return 0.0))
	_frames(2)
	runner.check(sara.showing(), "Mordechai David comes from the left now: she stays")
	_frames(int(SaraMark.VISIT_MS / 16.0) + 10)
	runner.check(not sara.showing(), "after the visit she leaves")


func test_she_drops_by_for_a_cameo_now_and_then() -> void:
	await _boot(true)
	runner.check(_start_round(), "the pick and tap 1 start the round")
	var sara: SaraMark = m.sara
	sara.reduced_motion = true
	sara.update_view(SaraMark.CAMEO_FIRST_MS - 1000.0, m.state, true)
	runner.check(not sara.showing(), "no cameo before the first one is due")
	sara.update_view(1200.0, m.state, true)
	sara.update_view(16.0, m.state, true)
	runner.check(sara.showing(), "then a passing cameo")
	sara.update_view(SaraMark.VISIT_MS + 100.0, m.state, true)
	sara.update_view(16.0, m.state, true)
	runner.check(not sara.showing(), "which ends after the visit")
	sara.update_view(SaraMark.CAMEO_EVERY_MS / 2.0, m.state, true)
	runner.check(not sara.showing(), "and the next one waits its turn")


func test_not_in_another_leaders_round() -> void:
	await _boot()
	runner.check(_start_round("bennett"), "Bennett's round starts")
	_frames(30)
	runner.check(not m.sara.showing(), "no Sara outside Bibi's round")
