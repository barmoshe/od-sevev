extends RefCounted
## v2 story: eras, beats and conditional headlines (game/scripts/sim/story.gd).

var runner: Object


func setup(_r: Object) -> void:
	TestFixture.use_fork_content()


func teardown() -> void:
	TestFixture.use_game_content()


func test_eras_follow_evolutions() -> void:
	runner.check(Story.era_for(0)["id"] == "jungle", "run 1 is the jungle")
	runner.check(Story.era_for(2)["id"] == "village", "evolution 2 builds the village")
	runner.check(Story.era_for(5)["id"] == "city", "evolution 5 is still the city")
	runner.check(Story.era_for(40)["id"] == "orbit", "late game is orbit")
	for e: Dictionary in Story.eras():
		for p: String in e["props"]:
			runner.check(Art.has_sprite(p), "%s prop %s exists" % [e["id"], p])


func test_beats_fit_and_encore() -> void:
	for n in range(1, 12):
		var b := Story.beat_for(n)
		runner.check(b.size() == 3, "beat %d has 3 lines" % n)
		for l in b:
			runner.check(l.length() <= 31, "beat %d line fits the card: %s" % [n, l])
	runner.check(Story.beat_for(9)[0].contains("MK 3"), "the encore counts up")


func test_ambient_conditions_and_no_repeat() -> void:
	var s := GameState.fresh()
	var recent: Array = []
	var seen := {}
	for i in 12:
		var t := Story.pick_ambient(s, recent, 14)
		runner.check(t != "" and not seen.has(t), "no repeat inside the window (%s)" % t)
		seen[t] = true
	var all_text := ""
	for i in 200:
		all_text += Story.pick_ambient(s, recent, 14) + "\n"
	runner.check(not all_text.contains("Mission control"), "orbit lines never show in the jungle")
	runner.check(not all_text.contains("Tides confused"), "moon lines need 10 moons")
	runner.check(not all_text.contains("Good morning"), "morning lines need the morning")
	s.evolutions = 6
	var orbit := false
	for i in 300:
		if Story.pick_ambient(s, recent, 14).contains("shekel shower") or Story.pick_ambient(s, recent, 14).contains("Mission control"):
			orbit = true
	runner.check(orbit, "orbit lines show in orbit")
