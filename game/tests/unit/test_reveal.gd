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
	runner.check(Reveal.on(r1, "picker"), "the picker opens on the first launch (the roster ladder)")
	for k: String in ["spins", "suspicion", "ultimatums", "events", "abilities", "missions", "perks", "mordechai", "share", "milestones"]:
		runner.check(not Reveal.on(r1, k), "round 1 is calm: no %s" % k)
	runner.check(Reveal.on(_at(1), "spins") and not Reveal.on(_at(1), "suspicion"), "round 2: spins")
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
	runner.check(Ability.def(s).is_empty(), "no ability in round 1")
	var u := Content.upgrade("s01")
	s.run_money = 1.0e9
	s.all_time_money = 1.0e9
	runner.check(not Economy.upgrade_unlocked(s, u), "no spins in round 1")
	Investigation.add(s, 50.0)
	runner.check(Investigation.suspicion(s) == 0.0, "no suspicion before its round")
	var s3 := _at(3)
	s3.stats["playtimeSec"] = 600.0
	s3.coalition["paidLifetime"] = 10
	runner.check(Coalition.ultimatums_unlocked(s3), "ultimatums from round 4")
	runner.check(Investigation.floor_pct(_at(2)) == 0.0, "suspicion opens at 0 in its own round")
	runner.check(Investigation.floor_pct(_at(3)) > 0.0, "and the floor climbs from the round after")


func test_a_new_game_opens_the_picker_with_two_open_leaders() -> void:
	m = load("res://scenes/main.tscn").instantiate()
	m.store = SaveStore.new(dir)
	tree.root.add_child(m)
	for i in 3:
		await tree.process_frame
	runner.check(m.mode == "pick", "the picker on the first launch (mode %s)" % m.mode)
	var open: Array = []
	var shut: Array = []
	for c: Dictionary in m.picker.cells:
		if str(c["id"]) == "" or m.picker.tile_of(str(c["id"])).get("decoy", false):
			continue
		(shut if c.get("locked", false) else open).append(str(c["id"]))
	open.sort()
	runner.check(open == ["bennett", "bibi"], "Bibi and Bennett are open (%s)" % str(open))
	runner.check(shut.size() == Leaders.pickable().size() - 2, "the rest are locked (%s)" % str(shut))
	var first_two := [str(m.picker.cells[0]["id"]), str(m.picker.cells[1]["id"])]
	first_two.sort()
	runner.check(first_two == ["bennett", "bibi"], "the open tiles sit first, side by side (%s)" % str(first_two))
	# a slip in print: chosen, it shows blurred in the big card and the vote button stays off
	var li := -1
	for i in m.picker.cells.size():
		if m.picker.cells[i].get("locked", false):
			li = i
	m.picker._age = 1000.0
	m.picker.choose(li)
	runner.check(not m.picker.go_btn.is_enabled(), "a slip in print can't be voted (%s)" % m.picker.go_btn.label.text)
	var shut_id := str(m.picker.cells[li]["id"])
	var shown: Array = []
	for n: Node in m.picker._card_layer.find_children("*", "PxText", true, false):
		shown.append((n as PxText).text)
	runner.check(not shown.has(str(Leaders.leader(shut_id).get("short", ""))) and shown.has(Strings.s("LEADER_PICK_SECRET")),
		"the card never names a slip in print (%s)" % str(shown))
	m.picker.commit_cell(li, "tile")
	runner.check(m.mode == "pick" and Leaders.pick_pending(m.state), "a locked tile starts no round")
	# select, then vote: an open slip enables the button with its name; the button votes
	var bi := -1
	for i in m.picker.cells.size():
		if str(m.picker.cells[i]["id"]) == "bennett":
			bi = i
	m.picker.choose(bi)
	runner.check(m.picker.go_btn.is_enabled() and m.picker.go_btn.label.text.contains("בנט"), "Bennett chosen: '%s'" % m.picker.go_btn.label.text)
	runner.check(m.mode == "pick", "choosing is not voting")
	for i in 20:
		runner.check(["bibi", "bennett"].has(Leaders.random_pick(func() -> float: return float(i) / 20.0, m.state)), "הפתעה picks an open leader")


func test_every_round_opens_one_more_leader() -> void:
	var prev := 0
	for evo in 7:
		var n := Leaders.unlocked(_at(evo)).size()
		runner.check(n == 2 + evo, "round %d: %d leaders open (%d)" % [evo + 1, 2 + evo, n])
		runner.check(n > prev, "more than the round before")
		prev = n
	var p := Leaders.picker(_at(1))
	var news := (p["tiles"] as Array).filter(func(x: Variant) -> bool: return (x as Dictionary).get("new", false))
	runner.check(news.size() == 1 and str(news[0]["id"]) == "bengvir", "round 2's new tile is Ben Gvir (%s)" % str(news))
	for i in 30:
		runner.check(Leaders.unlocked(_at(1)).has(Leaders.random_pick(func() -> float: return float(i) / 30.0, _at(1))), "random_pick only picks open leaders")
	runner.check(Leaders.unlocked(_at(1)).has(PacingSim.pick_leader("mixed", func() -> float: return 0.99, _at(1))), "the bench's mixed player too")


func test_the_round_news_names_what_opens_and_the_rule_once() -> void:
	var s := _at(1)
	var news: PackedStringArray = load("res://scripts/main.gd").round_news(s, "bennett")
	runner.check(news.size() >= 2, "spins + Bennett's rule (%s)" % str(news))
	(load("res://scripts/ui/wizard.gd") as GDScript).set("enabled", true)
	var s2 := _at(1)
	var with_wiz: PackedStringArray = load("res://scripts/main.gd").round_news(s2, "bennett")
	(load("res://scripts/ui/wizard.gd") as GDScript).set("enabled", false)
	runner.check(with_wiz.size() == 1, "with the wizard on, spins is taught by its wizard: only the rule (%s)" % str(with_wiz))
	var again: PackedStringArray = load("res://scripts/main.gd").round_news(s, "bennett")
	runner.check(again.size() == news.size() - 1, "the rule is said once per leader")
