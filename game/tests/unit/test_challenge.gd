extends RefCounted
## "תעבור אותי" (seeded rounds, challenge links): the hash's parse/build round trip and its guards,
## the return link's math, the ghost chip's countdown, reproducibility (the same seed and the same
## scripted actions give the same deal, the same partners and the same event order), and save
## isolation through the real scene (a round never touches the main save, and leaving it restores
## the main game exactly).

var runner: Object
var tree: SceneTree
var dir := ""
var m: Node


func setup(r: Object) -> void:
	TestFixture.use_game_content()
	tree = r as SceneTree
	dir = "user://test_challenge_%d" % Time.get_ticks_usec()
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


func _check(cond: bool, msg: String) -> void:
	runner.call("check", cond, msg)


# ------------------------------------------------------------------ the hash

func test_hash_build_and_parse_round_trip() -> void:
	var c := {"leader": "bennett", "seed": 12345, "t": 462, "ref": "abcd1234"}
	var h := Challenge.build_hash(c)
	_check(h == "k=challenge&l=bennett&s=12345&t=462&r=abcd1234", "the hash's key order: %s" % h)
	var p := Challenge.parse("#" + h)
	_check(p["leader"] == "bennett" and int(p["seed"]) == 12345 and int(p["t"]) == 462 and p["ref"] == "abcd1234" and int(p["vs"]) == -1, "parse(build) round-trips: %s" % p)
	var back := Challenge.build_hash(Challenge.return_challenge(p, 400, "zz99zz99"))
	_check(back == "k=challenge&l=bennett&s=12345&t=400&r=zz99zz99&vs=462", "a return link carries vs: %s" % back)
	var p2 := Challenge.parse(back)
	_check(int(p2["vs"]) == 462 and int(p2["t"]) == 400, "vs parses back")
	# window.odArrival.params (strings, no k) parse the same way
	var p3 := Challenge.parse({"l": "bennett", "s": "12345", "t": "462", "r": "abcd1234"})
	_check(int(p3["seed"]) == 12345 and p3["leader"] == "bennett", "the arrival's params dictionary parses")


func test_hash_guards() -> void:
	_check(Challenge.parse("k=challenge&l=bibi&t=300").is_empty(), "no seed: not a challenge")
	_check(Challenge.parse("k=challenge&l=bibi&s=1&t=0").is_empty(), "t 0 is refused")
	_check(Challenge.parse("k=challenge&l=bibi&s=1&t=86401").is_empty(), "t over a day is refused")
	_check(Challenge.parse("k=challenge&l=bibi&s=-4&t=60").is_empty(), "a negative seed is refused")
	_check(Challenge.parse("k=challenge&l=bibi&s=abc&t=60").is_empty(), "a non-numeric seed is refused")
	_check(Challenge.parse("k=daily&s=1&t=60").is_empty(), "another kind is not a challenge")
	var p := Challenge.parse("k=challenge&l=nobody&s=7&t=60&r=BAD")
	_check(p["leader"] == Leaders.default_leader(), "an unknown leader falls back to the default")
	_check(p["ref"] == "", "a malformed ref is dropped")
	_check(Challenge.parse("k=challenge&l=gantz&s=7&t=60")["leader"] == Leaders.default_leader(), "the decoy is not a playable leader")
	var pairs := Challenge.parse_pairs("#a=1&b=%D7%91&c&=x")
	_check(pairs.get("a") == "1" and pairs.get("b") == "ב" and not pairs.has("c"), "pairs percent-decode and skip junk: %s" % pairs)


func test_links_and_refs() -> void:
	var c := {"leader": "deri", "seed": 9, "t": 300, "ref": "aaaa1111"}
	_check(Challenge.link("https://od-sevev.vercel.app/", c) == "https://od-sevev.vercel.app/s/deri-challenge#k=challenge&l=deri&s=9&t=300&r=aaaa1111", "the stub link")
	_check(Challenge.link("https://od-sevev.vercel.app", c, false) == "https://od-sevev.vercel.app/#k=challenge&l=deri&s=9&t=300&r=aaaa1111", "the root link")
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var ref := Challenge.new_ref(rng.randf)
	_check(ref.length() == 8 and Challenge._ref_ok(ref), "a ref is 8 × [a-z0-9]: %s" % ref)
	var s := GameState.fresh()
	Leaders.set_salt(s, 77)
	Leaders.start_round(s, "bennett")
	var a := Challenge.seed_for_round(s)
	_check(a == Challenge.seed_for_round(s) and a >= 0 and a <= Challenge.SEED_MAX, "a round's challenge seed is stable and in range")


func test_return_link_math() -> void:
	var w := Challenge.outcome(400, 462)
	_check(w["result"] == "win" and int(w["gap"]) == 62, "faster wins by the gap")
	var l := Challenge.outcome(506, 462)
	_check(l["result"] == "lose" and int(l["gap"]) == 44, "slower loses by the gap (0:44)")
	_check(Challenge.outcome(462, 462)["result"] == "tie", "equal seconds tie")
	var ch := {"leader": "bibi", "seed": 5, "t": 462, "ref": "abcd1234", "vs": -1}
	var r := Challenge.return_challenge(ch, 418, "ffff0000")
	_check(r["leader"] == "bibi" and int(r["seed"]) == 5 and int(r["t"]) == 418 and int(r["vs"]) == 462 and r["ref"] == "ffff0000", "the return keeps the round, swaps the times: %s" % r)


func test_ghost_chip_counts_down_then_over() -> void:
	var a := RoundChip.lines("challenge", 100.0, 462, 0)
	_check(Bidi.strip_controls(str(a["timer"])) == "6:02" and not a["over"], "7:42 − 1:40 = 6:02 left: %s" % a["timer"])
	var b := RoundChip.lines("challenge", 500.4, 462, 0)
	_check(Bidi.strip_controls(str(b["timer"])) == "+0:38" and b["over"], "past the challenger's time it counts up in red: %s" % b["timer"])
	var c := RoundChip.lines("daily", 252.0, 0, 34)
	_check(Bidi.strip_controls(str(c["timer"])) == "4:12" and Bidi.strip_controls(str(c["title"])).contains("#34"), "the daily chip: #34 and its own clock")


# ------------------------------------------------------------------ reproducibility

## A scripted player on the seeded streams (the controller's wiring): taps, buys the cheapest
## revealed source, pays what the bench's default strategy pays. Returns the log of what happened.
func _play(leader: String, seed_: int, secs: float, tps: float) -> Dictionary:
	var run := SeededRound.new("challenge", leader, seed_)
	var s := SeededRound.fresh_state(leader, seed_)
	var rec := SeededRound.new_record()
	var log: Array = []
	var dt := 0.25
	var t := 0.0
	var acc := 0.0
	var strat := PacingSim.strategy({})
	while t < secs:
		acc += tps * dt
		while acc >= 1.0:
			acc -= 1.0
			Economy.tap(s, run.rng("tap"))
		var d := Economy.derive(s)
		Economy.tick(s, dt, d)
		if Economy.tick_golden_timer(s, dt):
			Economy.apply_golden(s, Economy.roll_golden_outcome(run.rng("golden"), s))
			Economy.schedule_next_golden(s, run.rng("golden"))
		for e: Dictionary in Politics.tick(s, dt, d, SeededRound.pin_ctx({"allowPing": true}), run.rng("politics")):
			match str(e.get("ev", "")):
				"event":
					log.append("event:%s" % e.get("id", ""))
				"partnerJoined":
					log.append("join:%s" % e.get("partner", ""))
				"message":
					var msg: Dictionary = e["msg"]
					if str(msg.get("type", "")) in ["demand", "ultimatum"]:
						log.append("%s:%s" % [msg["type"], msg.get("partner", "")])
		PacingSim.play_politics(s, strat)
		SeededRound.observe(rec, s)
		var best := ""
		var cost := INF
		for id in Content.producer_ids():
			if Economy.is_revealed(s, id) and Economy.producer_cost(s, id, 1) < cost:
				cost = Economy.producer_cost(s, id, 1)
				best = id
		if best != "" and s.bananas >= cost:
			Economy.buy_producer(s, best, 1)
		t += dt
	return {"log": log, "deal": s.seat_deal.duplicate(), "cells": SeededRound.cells(rec), "bank": s.bananas, "salt": s.events.get("everySalt")}


func test_same_seed_same_round() -> void:
	var a := _play("bennett", 424242, 420.0, 3.0)
	var b := _play("bennett", 424242, 420.0, 3.0)
	_check(a["deal"] == b["deal"] and not (a["deal"] as Dictionary).is_empty(), "the same seed deals the same slots")
	_check(a["log"] == b["log"] and (a["log"] as Array).size() > 3, "the same seed and actions: the same joins, demands and events (%d entries)" % (a["log"] as Array).size())
	_check(a["cells"] == b["cells"] and is_equal_approx(float(a["bank"]), float(b["bank"])), "the same grid and the same bank")
	_check(a["salt"] == b["salt"], "the periodic rolls' salt comes from the seed")
	var c := _play("bennett", 1717, 420.0, 3.0)
	_check(c["deal"] != a["deal"] or c["log"] != a["log"], "another seed deals another round")


func test_tapping_differently_never_redeals_the_events() -> void:
	# the politics stream is its own: a player who taps more meets the same first partners
	var a := _play("bibi", 99, 300.0, 2.0)
	var b := _play("bibi", 99, 300.0, 5.0)
	var first_a: Array = (a["log"] as Array).filter(func(x: String) -> bool: return x.begins_with("demand:")).slice(0, 2)
	var first_b: Array = (b["log"] as Array).filter(func(x: String) -> bool: return x.begins_with("demand:")).slice(0, 2)
	_check(first_a == first_b and first_a.size() == 2, "the first demands are the same whatever the tap rate: %s / %s" % [str(first_a), str(first_b)])


func test_fresh_state_lends_only_the_tutorial() -> void:
	var main := GameState.fresh()
	main.thumbs_owned = 50
	main.shop = {"p_nap": 3}
	main.ftue["p1"] = "done"
	main.ui["tabsTouched"] = true
	main.achievements = PackedStringArray(["a_first"])
	var s := SeededRound.fresh_state("deri", 5, main)
	_check(s.thumbs_owned == 0 and s.shop.is_empty() and s.achievements.is_empty(), "no base, perks or trophies come along")
	_check(s.ftue["p1"] == "done" and s.ui["tabsTouched"] == true, "the tutorial flags do")
	_check(Leaders.current(s) == "deri" and not Leaders.pick_pending(s) and int(s.leader_round["salt"]) == 5, "the leader is fixed, the salt is the seed")
	_check(not s.leader_round.has("undo"), "no undo chip")


# ------------------------------------------------------------------ the scene: save isolation

func _boot() -> void:
	m = load("res://scenes/main.tscn").instantiate()
	m.store = SaveStore.new(dir)
	tree.root.add_child(m)
	for i in 3:
		await tree.process_frame
	m.ftue.handoff_ms = 1.0
	m.commit_pick("bibi")
	_touch(L.magician_hit().get_center() + Vector2(m._sx, m._stage_y))


func _touch(p: Vector2, idx: int = 0) -> void:
	for pressed in [true, false]:
		var e := InputEventScreenTouch.new()
		e.index = idx
		e.position = p
		e.pressed = pressed
		m._unhandled_input(e)


func test_a_round_never_touches_the_main_save() -> void:
	await _boot()
	var main_state: GameState = m.state
	main_state.bananas = 1234.0
	main_state.thumbs_owned = 3
	var path: String = (m.store as SaveStore).path
	m.round_arrive("challenge", {"k": "challenge", "l": "bennett", "s": "31337", "t": "462", "r": "abcd1234"})
	await tree.process_frame
	var top: Variant = m.overlays.top()
	_check(top is RoundCards.ChallengeIntro, "the link opens the challenge card")
	m.round_accept_arrival()
	var before := FileAccess.get_file_as_string(path)   # the main game, saved as the round began
	var dict_before := JSON.stringify(JSON.parse_string(JSON.stringify(main_state.to_dict())))   # JSON's numbers on both sides
	_check(SaveStore.parse(before)["state"].thumbs_owned == 3, "the main game was saved as the round began")
	_check(m.in_round() and m.state != main_state, "the round runs on its own state")
	_check(m.store is RoundBook.Sandbox, "and its own store")
	_check(Leaders.current(m.state) == "bennett" and int(m.state.leader_round["salt"]) == 31337, "the link's leader and seed")
	_check(m.state.thumbs_owned == 0 and m.state.bananas == 0.0, "nothing of the main game")
	_check(m.mode == "title", "the round starts before tap 1 (the clock with it)")
	await tree.create_timer(0.3).timeout   # the intro card's input lock
	_touch(L.magician_hit().get_center() + Vector2(m._sx, m._stage_y))
	for i in 10:
		await tree.process_frame
	_check(m.mode == "main" and m.state.taps_lifetime >= 1, "tap 1 starts the round")
	m.state.bananas = 9.0e9
	m.state.thumbs_owned = 999
	m._save_now()
	m._flush_save()
	_check(FileAccess.get_file_as_string(path) == before, "the main save file is untouched by the round's saves")
	_check((m.store as RoundBook.Sandbox).saves >= 1, "the round's saves went to the sandbox")
	m.state.run_time_sec = 418.6
	m._finish_round()
	await tree.process_frame
	_check(m.overlays.top() is RoundCards.ChallengeResult, "61: the result card")
	_check(m.round_result["result"] == "win" and int(m.round_result["mine"]) == 418 and int(m.round_result["gap"]) == 44, "won in 6:58 by 0:44: %s" % m.round_result)
	_check((m.book.data["challenges"] as Array).size() == 1, "the result is in the round book")
	_check(not m.round_chip.visible, "the round chip goes with the result")
	m.leave_round()
	_check(not m.in_round() and m.state == main_state, "back to the main game's own state object")
	var now_d: Dictionary = JSON.parse_string(JSON.stringify(m.state.to_dict()))
	var was_d: Dictionary = JSON.parse_string(dict_before)
	var diff: Array = []
	for k: String in now_d:
		if JSON.stringify(now_d[k]) != JSON.stringify(was_d.get(k)):
			diff.append("%s: %s -> %s" % [k, JSON.stringify(was_d.get(k)).left(300), JSON.stringify(now_d[k]).left(300)])
	_check(diff.is_empty(), "the main game exactly as it was: %s" % str(diff))
	for i in 3:
		await tree.process_frame
	_check(m.store.path == path and not (m.store is RoundBook.Sandbox), "the main store is back")
	_check(FileAccess.get_file_as_string(path) == before, "the main save file still untouched")
	_check(m.mode == "main", "the player's round resumes")


func test_no_election_inside_a_round() -> void:
	await _boot()
	var ev: int = m.state.evolutions
	m.start_round("challenge", {"leader": "bibi", "seed": 4, "ch": {"leader": "bibi", "seed": 4, "t": 300, "ref": "", "vs": -1}})
	m._start_evolve(true)
	_check(not m._tx_locked and m.state.evolutions == 0, "the dev election only ends the round")
	_check(m.overlays.top() is RoundCards.ChallengeResult, "with its result card")
	m.leave_round()
	await tree.process_frame
	_check(m.state.evolutions == ev, "the main game's elections unchanged")


func test_the_offer_after_an_election() -> void:
	await _boot()
	m.state.run_time_sec = 461.9
	m._round_note_election()
	var last: Dictionary = m.book.last_round()
	_check(last.get("leader") == "bibi" and int(last.get("t", 0)) == 461, "the election's round is noted: %s" % last)
	_check(m.round_offer_ready(), "T4's 'אתגר חבר' shows")
	var rb := RoundBook.new(dir).load_book()
	_check(rb.last_round() == last, "and survives a reload")
	m.open_challenge_offer()
	await tree.process_frame
	_check(m.overlays.top() is RoundCards.ChallengeOffer, "the offer card")
