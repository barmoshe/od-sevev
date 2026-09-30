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


func test_she_stands_and_huffs_at_the_bottle_deposits() -> void:
	await _boot()
	runner.check(_start_round(), "the pick and tap 1 start the round")
	_frames(30)
	var sara: SaraMark = m.sara
	runner.check(m.diorama.era_id() == "balfour" and sara.showing(), "Balfour, Bibi's round: she is on stage")
	runner.check(sara.position == SaraMark.mark() and sara.strip.anim == "idle", "on her mark, idle")
	sara.offend()
	_frames(5)        # 80 ms: inside the reaction delay
	runner.check(sara.strip.anim == "idle", "no huff before the 150 ms reaction delay")
	_frames(10)
	runner.check(sara.strip.anim == "offended", "then the huff")
	_frames(80)       # past the anim
	runner.check(sara.strip.anim == "idle", "back to idle after the huff")
	sara.offend()
	_frames(20)
	runner.check(sara.strip.anim == "idle", "a second trigger inside the 8 s cooldown is dropped")
	m._on_politics_event(Events.fire(m.state, "mordechai", m.d, func() -> float: return 0.0))
	_frames(2)
	runner.check(not sara.showing(), "the blockade holds her mark: she is off stage")


func test_not_in_another_leaders_round() -> void:
	await _boot()
	runner.check(_start_round("bennett"), "Bennett's round starts")
	_frames(30)
	runner.check(not m.sara.showing(), "no Sara outside Bibi's round")
