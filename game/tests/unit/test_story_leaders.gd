extends RefCounted
## Manual test 2026-09-30 B15: Dubi's post-election story card belongs to the leader who played the
## round. Every one of the 8 roster leaders gets their own card (title and lines) after their first
## election, never Bibi's ("הכובע שלא נגמר"), then their own later beats and the shared encore; the T4
## archive (Story.archive) replays each election with the card its leader got. Game content.

var runner: Object

const ROSTER := ["bibi", "bennett", "bengvir", "liberman", "eisenkot", "smotrich", "deri", "golan"]


func setup(_r: Object) -> void:
	TestFixture.use_game_content()


func teardown() -> void:
	TestFixture.use_game_content()


## An election in `id`'s round, as Economy.evolve books it (Meta.on_round_end, the run reset, then
## Politics.on_election), and the story beat the controller records (MainController._show_story_beat).
func _elect(s: GameState) -> Dictionary:
	Meta.on_round_end(s, 400.0)
	s.evolutions += 1
	Politics.on_election(s)
	var f := Story.flash(s)
	if not s.story_seen.has(str(f["id"])):
		s.story_seen.append(str(f["id"]))
	return f


func _round(id: String) -> GameState:
	var s := GameState.fresh()
	Leaders.set_salt(s, 3)
	runner.check(Politics.install(s, id).get("ok", false) == true, "%s: the round starts" % id)
	return s


func test_the_roster_is_the_eight() -> void:
	var roster: Array = Leaders.ls().get("roster", [])
	runner.check(roster == ROSTER, "the roster is the 8 leaders (%s)" % str(roster))
	for id: String in ROSTER:
		runner.check(Leaders.playable(id), "%s is playable" % id)


func test_every_leader_gets_their_own_card_after_an_election() -> void:
	var bibi_title := str((Content.data()["story"]["titles"] as Array)[0])
	var titles := {}
	var firsts := {}
	for id: String in ROSTER:
		var s := _round(id)
		var st := Leaders.story(id)
		runner.check((st["beats"] as Array).size() >= 3 and (st["titles"] as Array).size() == (st["beats"] as Array).size(),
			"%s: ≥ 3 beats, one title each (%d / %d)" % [id, (st["beats"] as Array).size(), (st["titles"] as Array).size()])
		var f := _elect(s)
		runner.check(str(f["leader"]) == id and int(f["n"]) == 1, "%s: the flash after the election is his (%s, n %d)" % [id, f["leader"], int(f["n"])])
		runner.check(str(f["title"]) != "" and Array(f["lines"]) == Array((st["beats"] as Array)[0]), "%s: his first title and beat (%s)" % [id, f["title"]])
		if id != "bibi":
			runner.check(str(f["title"]) != bibi_title and str(f["id"]) == "beat_%s_1" % id, "%s: not Bibi's card (%s, %s)" % [id, f["title"], f["id"]])
		titles[str(f["title"])] = id
		firsts[" ".join(Array(f["lines"]))] = id
		# story v3: his later beats in order, skipping a beat whose `when` is not met yet (a fresh state
		# has no crits / declines / merges), then his own encore
		var open_beats: Array = []
		for n in range(2, (st["beats"] as Array).size() + 1):
			if Story.beat_unlocked(s, id, n):
				open_beats.append(n)
		for n: int in open_beats:
			var g := _elect(s)
			runner.check(int(g["n"]) == n and Array(g["lines"]) == Array((st["beats"] as Array)[n - 1]), "%s: beat %d next" % [id, n])
		var e1 := _elect(s)
		var e2 := _elect(s)
		runner.check(Array(e1["lines"]) == Array(st["encore"]) and str(e1["title"]) == "", "%s: after his open beats, his encore" % id)
		runner.check(str(e1["id"]) != str(e2["id"]), "%s: every encore is its own card (%s, %s)" % [id, e1["id"], e2["id"]])
	runner.check(titles.size() == ROSTER.size() and firsts.size() == ROSTER.size(), "8 distinct first cards (%d titles, %d beats)" % [titles.size(), firsts.size()])


## Story v3 (Bar 2026-10-01): a beat can wait for what the player did as that leader. Golan's merger
## beat stays closed until his first merge, then it is the next card; every non-Bibi leader has an
## encore of his own.
func test_a_beat_waits_for_the_leaders_own_deed() -> void:
	var s := _round("golan")
	runner.check(not Story.beat_unlocked(s, "golan", 3), "golan: beat 3 waits for a merge")
	var f1 := _elect(s)
	var f2 := _elect(s)
	runner.check(int(f1["n"]) == 1 and int(f2["n"]) == 2, "golan: beats 1 and 2 first")
	var f3 := _elect(s)
	runner.check(int(f3["n"]) == 4, "golan: beat 3 is skipped while it waits (got %d)" % int(f3["n"]))
	Leaders.stats(s, "golan")["merges"] = 1.0
	var f4 := _elect(s)
	runner.check(int(f4["n"]) == 3, "golan: his first merge opens beat 3, shown next (got %d)" % int(f4["n"]))
	for id: String in ROSTER:
		if id != "bibi":
			var enc: Array = Leaders.story(id)["encore"]
			runner.check(enc != (Content.data()["story"]["encore"] as Array), "%s: an encore of his own" % id)


func test_no_card_puts_a_quote_in_a_real_persons_mouth() -> void:
	# the lint's reported-speech rule (design/sim/content-lint.mjs §6b), as a runtime guard: a quote only
	# in the narrator's mouth
	var narrator := Story.narrator_name()
	for id: String in ROSTER:
		for beat: Variant in Leaders.story(id)["beats"]:
			for l: Variant in beat:
				var line := str(l)
				if line.contains("\""):
					runner.check(line.begins_with(narrator + ": \""), "%s: a quote only in %s's mouth: %s" % [id, narrator, line])


func test_the_archive_replays_each_election_with_its_leaders_card() -> void:
	var s := _round("bennett")
	var f1 := _elect(s)
	Politics.install(s, "deri")
	var f2 := _elect(s)
	Politics.install(s, "bibi")
	var f3 := _elect(s)
	var a := Story.archive(s)
	runner.check(a.size() == 3, "three elections, three cards (%d)" % a.size())
	if a.size() == 3:
		runner.check(str(a[0]["leader"]) == "bibi" and str(a[0]["title"]) == str(f3["title"]), "newest first: Bibi's (%s)" % a[0]["title"])
		runner.check(str(a[1]["leader"]) == "deri" and Array(a[1]["lines"]) == Array(f2["lines"]), "then Deri's (%s)" % a[1]["title"])
		runner.check(str(a[2]["leader"]) == "bennett" and str(a[2]["title"]) == str(f1["title"]), "then Bennett's (%s)" % a[2]["title"])
	# an old save's ids (before leader select: "beat_<n>") read as the default leader's
	var old := GameState.fresh()
	old.story_seen = PackedStringArray(["beat_1", "beat_2"])
	var b := Story.archive(old)
	runner.check(b.size() == 2 and str(b[0]["leader"]) == "bibi" and int(b[0]["n"]) == 2, "an old save: Bibi's beats, newest first")
