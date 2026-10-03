extends RefCounted
## The reveal ladder (sim/reveal.gd, content `reveal`; 2026-10-03, Bar: one new system per round).
## On the real game content with the ladder ON (the runner switches it off for other unit tests).

var runner: Object
var tree: SceneTree
var dir := ""
var m: Node


func setup(r: Object) -> void:
	TestFixture.use_game_content()
	Reveal.force_all = false
	tree = r as SceneTree
	dir = "user://test_reveal_%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(dir)


func teardown() -> void:
	Reveal.force_all = true
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


func _at(evo: int) -> GameState:
	var s := GameState.fresh()
	s.evolutions = evo
	return s


func test_one_new_system_per_round() -> void:
	var r1 := _at(0)
	for k: String in ["spins", "picker", "suspicion", "ultimatums", "events", "abilities", "missions", "perks", "mordechai", "share", "milestones"]:
		runner.check(not Reveal.on(r1, k), "round 1 is calm: no %s" % k)
	runner.check(Reveal.on(_at(1), "spins") and Reveal.on(_at(1), "picker") and not Reveal.on(_at(1), "suspicion"), "round 2: spins and the picker")
	runner.check(Reveal.on(_at(2), "suspicion") and not Reveal.on(_at(2), "ultimatums"), "round 3: suspicion and the court")
	runner.check(Reveal.on(_at(3), "ultimatums") and Reveal.on(_at(3), "events") and Reveal.on(_at(3), "abilities") and not Reveal.on(_at(3), "missions"), "round 4: ultimatums, events, abilities")
	runner.check(Reveal.on(_at(4), "missions") and Reveal.on(_at(4), "mordechai"), "round 5: missions, perks, Mordechai, share, milestones")
	for evo in range(1, 5):
		var news := Reveal.new_this_round(_at(evo))
		runner.check(not news.is_empty(), "round %d opens something" % (evo + 1))
		for k: String in news:
			runner.check(Reveal.announcement(k) != "", "%s is announced" % k)


func test_the_sim_gates_follow_the_ladder() -> void:
	var s := _at(0)
	s.stats["playtimeSec"] = 600.0
	s.coalition["paidLifetime"] = 10
	runner.check(not Coalition.ultimatums_unlocked(s), "no ultimatum in round 1, however long")
	runner.check(not Leaders.pick_pending(s), "no picker on a new game: the default leader's round")
	runner.check(Ability.def(s).is_empty(), "no ability in round 1")
	var u := Content.upgrade("s01")
	s.run_bananas = 1.0e9
	s.all_time_bananas = 1.0e9
	runner.check(not Economy.upgrade_unlocked(s, u), "no spins in round 1")
	Investigation.add(s, 50.0)
	runner.check(Investigation.suspicion(s) == 0.0, "no suspicion before its round")
	var s3 := _at(3)
	s3.stats["playtimeSec"] = 600.0
	s3.coalition["paidLifetime"] = 10
	runner.check(Coalition.ultimatums_unlocked(s3), "ultimatums from round 4")
	runner.check(Investigation.floor_pct(_at(2)) == 0.0, "suspicion opens at 0 in its own round")
	runner.check(Investigation.floor_pct(_at(3)) > 0.0, "and the floor climbs from the round after")


func test_a_new_game_starts_as_the_default_leader_without_the_picker() -> void:
	m = load("res://scenes/main.tscn").instantiate()
	m.store = SaveStore.new(dir)
	tree.root.add_child(m)
	for i in 3:
		await tree.process_frame
	runner.check(m.mode != "pick", "no picker on the first launch (mode %s)" % m.mode)
	runner.check(Leaders.current(m.state) == Leaders.default_leader(), "the default leader's round")


func test_the_round_news_names_what_opens_and_the_rule_once() -> void:
	var s := _at(1)
	var news: PackedStringArray = load("res://scripts/main.gd").round_news(s, "bennett")
	runner.check(news.size() >= 3, "spins + picker + Bennett's rule (%s)" % str(news))
	var again: PackedStringArray = load("res://scripts/main.gd").round_news(s, "bennett")
	runner.check(again.size() == news.size() - 1, "the rule is said once per leader")
