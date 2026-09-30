extends RefCounted
## The event scheduler (game/scripts/sim/events.gd): flags, conditions, cooldowns, the blackout
## filter, and what each effect does.

const PF := preload("res://tests/politics_fixture.gd")

var runner: Object


func setup(_r: Object) -> void:
	PF.install()


func teardown() -> void:
	PF.restore()


func _flags(on: Array) -> void:
	var f: Dictionary = Content.data()["flags"]
	for k in f.keys():
		f[k] = on.has(k)


## Fires the scheduler `n` times (forcing each gap to elapse) and counts what fired.
func _run(s: GameState, n: int, ctx: Dictionary = {}, seed_: int = 1) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_
	var r := func() -> float: return rng.randf()
	var seen := {}
	for i in n:
		s.events["nextSec"] = 0.001
		s.events["cooldowns"] = {}
		s.events["round"] = []
		for e: Dictionary in Events.tick(s, 0.01, Economy.derive(s), ctx, r):
			if e["ev"] == "event":
				seen[e["id"]] = int(seen.get(e["id"], 0)) + 1
	return seen


func _rich() -> GameState:
	var s := GameState.fresh()
	s.evolutions = 1
	s.stats["playtimeSec"] = 1000.0
	s.investigation["courtDays"] = 2
	for id in Content.producer_ids():
		s.owned[id] = 5
	# three members, under the 61 gate: at 61 no seat-costing card fires (test_vote_hold.gd)
	for id in ["bengvir", "smotrich", "amsalem"]:
		Coalition.ps(s, id)["status"] = "member"
	return s


func test_flagged_events_never_fire_by_default() -> void:
	var seen := _run(_rich(), 600, {"weekday": 6, "hour": 21})
	for id in ["mordechai", "yair", "nameless", "roulette", "kaia", "pinkfront"]:
		runner.check(not seen.has(id), "%s is behind a flag, off by default" % id)
	for id in ["brawl", "leak", "interview", "pardon", "lapid", "eisenkot", "liberman"]:
		runner.check(seen.has(id), "%s fires" % id)
	for f in ["mordechaiDavid", "yairNetanyahu", "postLaunch", "easterEggs"]:
		runner.check(Content.data()["flags"][f] == false, "flag %s ships off" % f)


func test_pink_front_only_on_saturday_night() -> void:
	_flags(["easterEggs"])
	var s := _rich()
	runner.check(not _run(s, 300, {"weekday": 5, "hour": 21}).has("pinkfront"), "not on Friday")
	runner.check(not _run(s, 300, {"weekday": 6, "hour": 12}).has("pinkfront"), "not on Saturday noon")
	runner.check(not _run(s, 300, {}).has("pinkfront"), "not without a device clock")
	runner.check(_run(s, 300, {"weekday": 6, "hour": 22}).has("pinkfront"), "Saturday night, by the device clock")


func test_poll_like_events_are_off_in_the_blackout() -> void:
	_flags(["postLaunch"])
	var s := _rich()
	runner.check(_run(s, 400).has("roulette"), "threshold roulette fires when switched on")
	s.calendar["mode"] = "blackout"
	var seen := _run(s, 400)
	runner.check(not seen.has("roulette"), "never during the blackout (poll_like)")
	runner.check(seen.has("nameless"), "a non-poll-like event still fires")


func test_cooldowns_and_once_per_round() -> void:
	var s := _rich()
	var rng := func() -> float: return 0.0
	var fired := 0
	var interviews := 0
	for i in 2000:
		for e: Dictionary in Events.tick(s, 1.0, Economy.derive(s), {}, rng):
			if e["ev"] == "event":
				fired += 1
				if e["id"] == "interview":
					interviews += 1
	runner.check(fired >= 2000 / 210 - 1 and fired <= 2000 / 150 + 1, "one event per 150-210 s (%d in 2000 s)" % fired)
	runner.check(interviews <= 1, "the interview fires once per round (%d)" % interviews)
	Events.on_election(s)
	runner.check(Events.eligible(s, Events.event("interview")), "a new round allows it again")
	s.events["nextSec"] = 1e9   # nothing else fires while the cooldown runs down
	s.events["cooldowns"] = {"lapid": 5.0}
	runner.check(not Events.eligible(s, Events.event("lapid")), "a cooling event isn't eligible")
	Events.tick(s, 5.0, Economy.derive(s), {}, rng)
	runner.check(Events.eligible(s, Events.event("lapid")), "cooldowns run down with play")


func test_first_event_waits_for_4_minutes_of_play() -> void:
	var s := _rich()
	s.stats["playtimeSec"] = 0.0
	var t := 0.0
	var first := -1.0
	while t < 600.0 and first < 0.0:
		for e: Dictionary in Events.tick(s, 1.0, Economy.derive(s), {}, func() -> float: return 0.0):
			if e["ev"] == "event":
				first = t
		s.stats["playtimeSec"] = float(s.stats["playtimeSec"]) + 1.0
		t += 1.0
	runner.check(first >= 239.0 and first <= 241.0, "first event at firstAfterPlaySec (240 s), got %s" % first)


func test_brawl_event_uses_the_listed_pair_first() -> void:
	var s := _rich()
	var r := Events.fire(s, "brawl", Economy.derive(s), func() -> float: return 0.5)
	runner.check(r["result"]["a"] == "amsalem" and r["result"]["b"] == "smotrich", "Amsalem × Smotrich first (deck §E)")
	runner.check(not Coalition.counts(s, "amsalem") and not Coalition.counts(s, "smotrich"), "both rows frozen")
	var b := Coalition.open_brawl(s)
	Coalition.resolve_brawl(s, int(b["seq"]))
	Coalition.ps(s, "amsalem")["status"] = "left"
	var r2 := Events.fire(s, "brawl", Economy.derive(s), func() -> float: return 0.0)
	runner.check(r2["result"].has("a") and r2["result"]["a"] != r2["result"]["b"], "then any pair of members")


func test_leaks_play_in_order_then_loop() -> void:
	var s := _rich()
	var got: Array = []
	for i in 5:
		got.append(Events.fire(s, "leak", Economy.derive(s))["result"]["leak"])
	runner.check(got == [1, 2, 3, 1, 2], "leaks 1, 2, 3, then loop (deck §E.2): %s" % str(got))


func test_interview_raises_the_base_payout_for_the_round() -> void:
	var s := _rich()
	Content.data()["prestige"]["payout"] = {"scope": "round", "rootDegree": 3, "divisor": 50, "epsilon": 1e-9}
	s.run_bananas = 50.0 * pow(40.0, 3.0)   # cbrt(run / 50) = 40
	runner.check(Economy.derive(s).pending == 40, "round payout 40 (got %d)" % Economy.derive(s).pending)
	Events.fire(s, "interview", Economy.derive(s))
	runner.check(Economy.derive(s).pending == 44, "+10%% on this round's payout (got %d)" % Economy.derive(s).pending)
	var ev := []
	for i in 60:
		ev.append_array(Events.tick(s, 1.0, Economy.derive(s), {}, func() -> float: return 0.99))
	runner.check(ev.any(func(e: Dictionary) -> bool: return e["ev"] == "invoice"), "next morning the fee-discount invoice arrives")
	Events.on_election(s)
	runner.check(Economy.derive(s).pending == 40, "gone after the election")


func test_bennett_pledge_raises_the_gate_then_pays() -> void:
	var s := _rich()
	var g0 := int(Coalition.seat_info(s)["gate"])
	var base0 := s.thumbs_owned
	Events.fire(s, "bennett", Economy.derive(s))
	runner.check(int(Coalition.seat_info(s)["gate"]) == g0 + 1, "the gate is 62 while he pledges")
	var ev := []
	for i in 45:
		ev.append_array(Events.tick(s, 1.0, Economy.derive(s), {}, func() -> float: return 0.99))
	runner.check(int(Coalition.seat_info(s)["gate"]) == g0 and s.thumbs_owned == base0 + 1, "then it flips: the gate is back, +1 base")
	runner.check(ev.any(func(e: Dictionary) -> bool: return e["ev"] == "pledgeFlip"), "the UI hears pledgeFlip")


func test_eisenkot_means_no_rabbits() -> void:
	var s := _rich()
	runner.check(Economy.derive(s).crit_chance > 0.0, "rabbits normally")
	Events.fire(s, "eisenkot", Economy.derive(s))
	runner.check(Economy.derive(s).crit_chance == 0.0, "no rabbits while his card is up")
	for i in 20:
		Events.tick(s, 1.0, Economy.derive(s), {}, func() -> float: return 0.99)
	runner.check(Economy.derive(s).crit_chance > 0.0, "back after 20 s")


func test_nameless_party_drains_seats() -> void:
	var s := _rich()
	var before := int(Coalition.seat_info(s)["effective"])
	Events.fire(s, "nameless", Economy.derive(s))
	runner.check(int(Coalition.seat_info(s)["effective"]) == before - 3, "−3 seats while it exists")
	for i in 120:
		Events.tick(s, 1.0, Economy.derive(s), {}, func() -> float: return 0.99)
	runner.check(int(Coalition.seat_info(s)["effective"]) == before, "it dissolves by itself")


func test_kaia_fed_or_ignored() -> void:
	var s := _rich()
	var tap := Economy.derive(s).tap_value_no_crit
	Events.fire(s, "kaia", Economy.derive(s))
	var r := Events.act(s, "kaia", "feed", Economy.derive(s))
	runner.check(float(r.get("buffSec", 0.0)) == 30.0 and is_equal_approx(Economy.derive(s).tap_value_no_crit, tap * 2.0), "a cucumber: taps ×2 for 30 s")
	var s2 := _rich()
	Events.fire(s2, "kaia", Economy.derive(s2))
	var ev: Array = []
	for i in 21:
		ev.append_array(Events.tick(s2, 1.0, Economy.derive(s2), {}, func() -> float: return 0.0))
	var nip: Array = ev.filter(func(e: Dictionary) -> bool: return e["ev"] == "kaiaNip")
	runner.check(nip.size() == 1 and not Coalition.counts(s2, nip[0]["partner"]), "ignored: a minister gets nipped and misses the vote")


## Mordechai David's blockade (design/mordechai-david-spec.md §5): a small partner is stuck and uncounted
## for 20 s, never one over 4 seats; with nobody small, the card only.
func _md_state() -> GameState:
	var s := GameState.fresh()
	s.stats["playtimeSec"] = 1000.0
	for id in ["bengvir", "smotrich", "amsalem"]:
		Coalition.ps(s, id)["status"] = "member"
	return s


func test_blockade_benches_a_small_partner_for_20_seconds() -> void:
	_flags(["mordechaiDavid"])
	var s := _md_state()
	var before := int(Coalition.seat_info(s)["effective"])
	var fired := Events.fire(s, "mordechai", Economy.derive(s), func() -> float: return 0.0)
	runner.check(str(fired["result"].get("partner", "")) == "amsalem", "the only 1-4 seat member is picked (got %s)" % fired["result"])
	runner.check(not Coalition.counts(s, "amsalem"), "amsalem misses the vote")
	runner.check(int(Coalition.seat_info(s)["effective"]) == before - 2, "the seats bar drops by his 2 seats")
	runner.check(Events.is_active(s, "blockade"), "the blockade is live")
	var ev: Array = []
	for i in 21:
		ev.append_array(Events.tick(s, 1.0, Economy.derive(s), {}, func() -> float: return 0.99))
		Coalition.ps(s, "amsalem")["benchSec"] = maxf(0.0, float(Coalition.ps(s, "amsalem")["benchSec"]) - 1.0)   # Coalition.tick's bench clock
	runner.check(Coalition.counts(s, "amsalem"), "after 20 s he counts again")
	runner.check(ev.any(func(e: Dictionary) -> bool: return e["ev"] == "eventEnd" and e["type"] == "blockade"), "eventEnd blockade")
	runner.check(int(Coalition.seat_info(s)["effective"]) == before, "the seats come back")


func test_blockade_never_strands_a_big_partner() -> void:
	var s := GameState.fresh()
	for id in ["bengvir", "smotrich"]:
		Coalition.ps(s, id)["status"] = "member"
	for k in 10:
		var r: Dictionary = Events.EFFECTS["blockade"].call(s, {"sec": 20, "maxSeats": 4}, Economy.derive(s), func() -> float: return k / 10.0)
		runner.check(str(r["partner"]) == "", "no 1-4 seat member: nobody is stuck (%s)" % r)
	runner.check(Coalition.counts(s, "bengvir") and Coalition.counts(s, "smotrich"), "12 and 7 seats still vote")
	var s2 := _md_state()
	Coalition.ps(s2, "regev")["status"] = "member"
	for k in 10:
		for id in ["amsalem", "regev"]:
			Coalition.ps(s2, id)["benchSec"] = 0.0   # each pick benches; clear it so every draw sees both
		var r2: Dictionary = Events.EFFECTS["blockade"].call(s2, {"sec": 20, "maxSeats": 4}, Economy.derive(s2), func() -> float: return k / 10.0)
		runner.check(["amsalem", "regev"].has(str(r2["partner"])), "only a partner of 1-4 seats (%s)" % r2)


func test_blockade_only_on_its_stage_and_never_at_the_gate() -> void:
	_flags(["mordechaiDavid"])
	var s := _md_state()
	var e := Events.event("mordechai")
	runner.check(Events.eligible(s, e), "eligible on the first stage with 3 members")
	var e2 := e.duplicate(true)
	e2["when"]["era"] = "no-such-era"
	runner.check(not Events.eligible(s, e2), "not on another stage (no crowd)")
	for p: Dictionary in Coalition.partners():
		if not p.get("standIn", false) and p.get("side", "coalition") == "coalition":
			Coalition.ps(s, str(p["id"]))["status"] = "member"
	Economy.add_bananas(s, 5e9)
	runner.check(Coalition.gate_open(s) and not Events.eligible(s, e), "never while the 61 gate is open")
	_flags([])
	runner.check(not Events.eligible(_md_state(), e), "never with the flag off")


## atPlaySec (spec §4, Bar 2026-09-30): Mordechai David fires once at one minute of play, ahead of
## the scheduler's 4-minute first wait, with or without partners in the group.
func test_blockade_fires_at_one_minute_of_play() -> void:
	_flags(["mordechaiDavid"])
	var s := GameState.fresh()
	var fires: Array = []
	var rng := func() -> float: return 0.5
	for i in 240:   # 0.5 s steps to 2:00
		s.stats["playtimeSec"] = float(s.stats["playtimeSec"]) + 0.5
		for ev: Dictionary in Events.tick(s, 0.5, Economy.derive(s), {}, rng):
			if ev["ev"] == "event":
				fires.append([float(s.stats["playtimeSec"]), ev["id"], ev["result"]])
	runner.check(fires.size() == 1 and fires[0][1] == "mordechai", "one event by 2:00, his (%s)" % str(fires))
	runner.check(not fires.is_empty() and is_equal_approx(float(fires[0][0]), 60.0), "at 1:00 of play")
	runner.check(not fires.is_empty() and str(fires[0][2].get("partner", "x")) == "", "an empty group: nobody is stuck, the card only")
	# never through the weighted pool: before his minute the scheduler never draws him
	var early := _md_state()
	early.stats["playtimeSec"] = 30.0
	var seen := _run(early, 300)
	runner.check(not seen.has("mordechai") and not seen.is_empty(), "the timer, not the weighted pool (%s)" % str(seen))


func test_lose_random_partner_skips_deri() -> void:
	var s := GameState.fresh()
	Coalition.ps(s, "deri")["status"] = "member"
	var r: Dictionary = Events.EFFECTS["loseRandomPartner"].call(s, {}, Economy.derive(s), func() -> float: return 0.0)
	runner.check(r.get("skipped", false) and Coalition.status(s, "deri") == "member", "Deri can't be made to leave")


func test_photobomb_album() -> void:
	runner.check(not Events.roll_photobomb(func() -> float: return 0.0)["liran"], "no photobombers while the flag is off")
	_flags(["postLaunch"])
	var both := Events.roll_photobomb(func() -> float: return 0.001)
	runner.check(both["together"], "a very rare draw puts both in frame")
	var s := GameState.fresh()
	runner.check(Events.album_add(s, both), "first time together: the trophy")
	runner.check(not Events.album_add(s, both), "only once")
	runner.check(int(s.album["liran"]) == 2 and int(s.album["together"]) == 2, "the album counts")
	var n := 0
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	for i in 10000:
		if Events.roll_photobomb(func() -> float: return rng.randf())["liran"]:
			n += 1
	runner.check(n > 250 and n < 600, "Liran ≈ 4%% of camera moments (%d / 10000)" % n)


func test_lint_catches_bad_events() -> void:
	var c := Content.data().duplicate(true)
	(c["events"] as Array).append({"id": "x", "flag": "nope", "when": {"hourr": [1, 2]}, "effect": {"type": "explode"}})
	var err := Politics.validate(c)
	var txt := "\n".join(err)
	runner.check(txt.contains("explode") and txt.contains("hourr") and txt.contains("nope"), "unknown effect, condition and flag are all reported:\n%s" % txt)
