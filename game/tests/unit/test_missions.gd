extends RefCounted
## Missions + ranks (game/scripts/sim/missions.gd; Bar 2026-10-02): goal counting from activation and
## state goals, the claim and its three rewards, the slot refill, the rank-up's income bonus, the
## save round-trip and the migration of a save without missions. The fixture missions below sit on
## the fork's content (TestFixture.FORK_CONTENT), so the numbers are the test's own; the last tests
## check the shipped content.

var runner: Object

const FIX := {
	"slots": 3, "cashFloor": 50,
	"ranks": [{"title": "אחד", "incomePct": 0}, {"title": "שניים", "incomePct": 10}, {"title": "שלושה", "incomePct": 5}],
	"list": [
		{"id": "ms_t_taps", "rank": 1, "text": "x", "goal": {"type": "taps", "n": 5}, "reward": {"type": "cash", "sec": 10}},
		{"id": "ms_t_own", "rank": 1, "text": "x", "goal": {"type": "ownSource", "source": "@1", "n": 3}, "reward": {"type": "basePct", "pct": 5}},
		{"id": "ms_t_earn", "rank": 1, "text": "x", "goal": {"type": "earnRun", "amount": 1000}, "reward": {"type": "frenzy", "sec": 12}},
		{"id": "ms_t_buy", "rank": 1, "text": "x", "goal": {"type": "sourcesTotal", "n": 4}, "reward": {"type": "cash", "sec": 10, "min": 7}},
		{"id": "ms_t_elect", "rank": 2, "text": "x", "goal": {"type": "elections", "n": 1}, "reward": {"type": "cash", "sec": 10}},
	],
}


func setup(_r: Object) -> void:
	var c: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(TestFixture.FORK_CONTENT))
	var m: Dictionary = FIX.duplicate(true)
	var first: String = (c["producers"] as Array)[0]["id"]
	for x: Dictionary in m["list"]:
		if (x["goal"] as Dictionary).get("source", "") == "@1":
			x["goal"]["source"] = first
	c["missions"] = m
	Content.replace(c)


func teardown() -> void:
	TestFixture.use_game_content()


func _eq(a: float, b: float, msg: String) -> void:
	runner.check(absf(a - b) <= 1e-6 * maxf(1.0, absf(b)), "%s (got %s, want %s)" % [msg, a, b])


func _ids(s: GameState) -> Array:
	return (s.missions["slots"] as Array).map(func(x: Dictionary) -> String: return x["id"])


func _slot(s: GameState, id: String) -> int:
	return _ids(s).find(id)


static func _no_crit() -> float:
	return 0.999


func test_fresh_state_fills_three_slots_in_list_order() -> void:
	var s := GameState.fresh()
	runner.check(Missions.active(), "the fixture has missions")
	runner.check(Missions.rank(s) == 1, "a new game starts at rank 1")
	Missions.tick(s)
	runner.check(_ids(s) == ["ms_t_taps", "ms_t_own", "ms_t_earn"], "3 slots, the rank's first three in list order: %s" % str(_ids(s)))
	runner.check(Missions.claimable(s) == 0, "nothing done yet")


func test_a_counted_goal_counts_from_activation() -> void:
	var s := GameState.fresh()
	s.taps_lifetime = 100   # taps before the mission showed never count
	Missions.tick(s)
	var v: Dictionary = Missions.slots_view(s)[0]
	_eq(float(v["value"]), 0.0, "taps before activation do not count")
	for i in 4:
		Economy.tap(s, _no_crit)
	runner.check(Missions.tick(s).is_empty(), "4 of 5 taps: not done")
	_eq(float(Missions.slots_view(s)[0]["value"]), 4.0, "the view counts 4")
	Economy.tap(s, _no_crit)
	var done := Missions.tick(s)
	runner.check(done == PackedStringArray(["ms_t_taps"]), "the 5th tap finishes it once: %s" % str(done))
	runner.check(Missions.tick(s).is_empty(), "a finished mission reports once")
	runner.check(Missions.claimable(s) == 1, "one to claim")


func test_a_state_goal_reads_the_state_and_latches() -> void:
	var s := GameState.fresh()
	var id := Content.producer_ids()[0]
	s.owned[id] = 2
	Missions.tick(s)
	runner.check(not bool(s.missions["slots"][_slot(s, "ms_t_own")]["done"]), "2 of 3 owned: not done")
	s.owned[id] = 3
	Missions.tick(s)
	runner.check(bool(s.missions["slots"][_slot(s, "ms_t_own")]["done"]), "3 owned: done")
	s.owned[id] = 0   # an election resets the sources
	Missions.tick(s)
	runner.check(bool(s.missions["slots"][_slot(s, "ms_t_own")]["done"]), "a done mission stays done")


func test_claim_pays_cash_from_the_income_with_a_floor() -> void:
	var s := GameState.fresh()
	Missions.tick(s)
	s.missions["slots"][0]["done"] = true
	var before := s.money
	var r := Missions.claim(s, 0)
	runner.check(bool(r["ok"]), "claimed")
	_eq(s.money - before, 50.0, "no income yet: the cash floor (cashFloor 50)")
	# with income: sec × ₪/s
	var s2 := GameState.fresh()
	s2.owned[Content.producer_ids()[0]] = 40
	var d := Economy.derive(s2)
	runner.check(d.bps * 10.0 > 50.0, "the fixture's income beats the floor")
	Missions.tick(s2, d)
	s2.missions["slots"][0]["done"] = true
	var b2 := s2.money
	Missions.claim(s2, 0, d)
	_eq(s2.money - b2, ceilf(10.0 * d.bps), "10 s of ₪/s")
	runner.check(s2.run_money >= s2.money and s2.all_time_money >= s2.money, "the cash counts as earned")


func test_claim_pays_frenzy_and_base_pct() -> void:
	var s := GameState.fresh()
	Missions.tick(s)
	var base0 := Economy.derive(s).base_pct_round
	s.missions["slots"][_slot(s, "ms_t_own")]["done"] = true
	Missions.claim(s, _slot(s, "ms_t_own"))
	_eq(Economy.derive(s).base_pct_round - base0, 5.0, "basePct: +5% on this round's base")
	s.missions["slots"][_slot(s, "ms_t_earn")]["done"] = true
	Missions.claim(s, _slot(s, "ms_t_earn"))
	_eq(s.buff_frenzy, 12.0, "frenzy: the Suitcase's income frenzy for 12 s")
	runner.check(Economy.derive(s).frenzy_mult > 1.0, "the frenzy multiplies income")
	Politics.on_election(s)
	_eq(Economy.derive(s).base_pct_round, 0.0, "the base bonus is this round's only")


func test_claim_refuses_an_unfinished_mission() -> void:
	var s := GameState.fresh()
	Missions.tick(s)
	var r := Missions.claim(s, 0)
	runner.check(not bool(r["ok"]), "not done: no claim")
	runner.check(not bool(Missions.claim(s, 7)["ok"]), "no such slot")
	runner.check((s.missions["claimed"] as Array).is_empty(), "nothing claimed")


func test_claim_refills_the_slot_with_the_next_mission() -> void:
	var s := GameState.fresh()
	Missions.tick(s)
	s.missions["slots"][1]["done"] = true
	Missions.claim(s, 1)
	runner.check(_ids(s) == ["ms_t_taps", "ms_t_buy", "ms_t_earn"], "the rank's next mission takes the claimed one's row: %s" % str(_ids(s)))
	runner.check((s.missions["claimed"] as Array) == ["ms_t_own"], "claimed")
	# the refilled mission counts from now
	var id := Content.producer_ids()[0]
	s.money = 1.0e9
	for i in 3:
		Economy.buy_producer(s, id, 1)
	runner.check(Missions.tick(s).is_empty(), "3 of 4 sources bought")
	Economy.buy_producer(s, id, 1)
	runner.check(Missions.tick(s) == PackedStringArray(["ms_t_buy"]), "the 4th source finishes sourcesTotal")
	runner.check(Missions.rank(s) == 1, "still rank 1 with missions left")


func test_rank_up_applies_the_income_bonus() -> void:
	var s := GameState.fresh()
	s.owned[Content.producer_ids()[0]] = 10
	var bps0 := Economy.derive(s).bps
	var up := {}
	for k in 4:
		Missions.tick(s)
		s.missions["slots"][0]["done"] = true
		var r := Missions.claim(s, 0)
		if not (r["rankUp"] as Dictionary).is_empty():
			up = r["rankUp"]
	runner.check(int(up.get("rank", 0)) == 2 and str(up.get("title", "")) == "שניים", "the 4th claim ranks up: %s" % str(up))
	_eq(float(up.get("incomePct", 0)), 10.0, "rank 2 pays +10%")
	runner.check(Missions.rank(s) == 2 and _ids(s) == ["ms_t_elect"], "rank 2's mission fills the slots: %s" % str(_ids(s)))
	_eq(Missions.income_pct(s), 10.0, "the bonus so far")
	_eq(Economy.derive(s).bps, bps0 * 1.1, "income ×1.10")
	# the elections goal, then the top
	s.evolutions += 1
	Missions.tick(s)
	var r2 := Missions.claim(s, 0)
	runner.check(int(r2["rankUp"].get("rank", 0)) == 3, "the last mission ranks up to the top")
	_eq(Missions.income_pct(s), 15.0, "the bonuses add up (10 + 5)")
	runner.check(bool(Missions.rank_view(s)["top"]) and _ids(s).is_empty(), "the top: no missions left")
	runner.check(not bool(Missions.claim(s, 0)["ok"]), "nothing to claim at the top")


func test_missions_persist_across_an_election() -> void:
	var s := GameState.fresh()
	Missions.tick(s)
	s.missions["slots"][0]["done"] = true
	Missions.claim(s, 0)
	var keep: Dictionary = s.missions.duplicate(true)
	Economy.reset_run(s)
	Politics.on_election(s)
	runner.check(s.missions == keep, "the election keeps the rank, the slots and the claims")


func test_save_round_trip() -> void:
	var s := GameState.fresh()
	s.taps_lifetime = 7
	Missions.tick(s)
	s.missions["slots"][0]["done"] = true
	Missions.claim(s, 0)
	Missions.on_source_bought(s, 3)
	var text := JSON.stringify({"version": SaveStore.VERSION, "lastSaveTime": 0, "state": s.to_dict()})
	var res := SaveStore.parse(text)
	runner.check(res["kind"] == "ok", "the save parses")
	var t: GameState = res["state"]
	runner.check(t.missions["rank"] == s.missions["rank"], "rank")
	runner.check(_ids(t) == _ids(s), "slots: %s vs %s" % [str(_ids(t)), str(_ids(s))])
	runner.check(Array(t.missions["claimed"]) == Array(s.missions["claimed"]), "claimed")
	_eq(float(t.missions["bought"]), 3.0, "the sources-bought count")
	for i in (s.missions["slots"] as Array).size():
		_eq(float(t.missions["slots"][i]["base"]), float(s.missions["slots"][i]["base"]), "slot %d's base" % i)
		runner.check(t.missions["slots"][i]["done"] == s.missions["slots"][i]["done"], "slot %d's done" % i)


func test_a_save_without_missions_migrates_to_rank_1() -> void:
	var s := GameState.fresh()
	s.taps_lifetime = 500
	var raw := s.to_dict()
	raw.erase("missions")
	var t := GameState.from_dict(raw)
	runner.check(t.missions["rank"] == 1 and (t.missions["claimed"] as Array).is_empty(), "rank 1, nothing claimed")
	Missions.tick(t)
	runner.check(_ids(t) == ["ms_t_taps", "ms_t_own", "ms_t_earn"], "fresh slots")
	_eq(float(t.missions["slots"][0]["base"]), 500.0, "an old player's taps before the missions never count")
	# an older file version (v4 without the section) parses too
	var res := SaveStore.parse(JSON.stringify({"version": SaveStore.VERSION, "lastSaveTime": 0, "state": raw}))
	runner.check(res["kind"] == "ok" and (res["state"] as GameState).missions["rank"] == 1, "a v%d file without missions loads" % SaveStore.VERSION)


func test_sanitize_drops_what_it_cannot_trust() -> void:
	var bad := {"rank": 99, "bought": -5, "claimed": ["ms_t_taps", "ms_t_taps", "nope", 3],
		"slots": [{"id": "ms_t_taps", "base": 1, "done": true}, {"id": "ghost"}, {"id": "ms_t_own", "base": -1, "done": "yes"},
			{"id": "ms_t_own"}, {"id": "ms_t_elect", "base": 2}, 7]}
	var m := Missions.sanitize(bad)
	runner.check(int(m["rank"]) == 3, "the rank is clamped to the ranks: %s" % str(m["rank"]))
	_eq(float(m["bought"]), 0.0, "a negative count is 0")
	runner.check(m["claimed"] == ["ms_t_taps"], "unknown and duplicate ids dropped: %s" % str(m["claimed"]))
	runner.check((m["slots"] as Array).is_empty(), "at rank 3 no rank-1 / rank-2 mission holds a slot: %s" % str(m["slots"]))
	bad["rank"] = 1
	m = Missions.sanitize(bad)
	var ids: Array = (m["slots"] as Array).map(func(x: Dictionary) -> String: return x["id"])
	runner.check(ids == ["ms_t_own"], "a claimed, unknown, duplicate or other-rank slot is dropped: %s" % str(ids))
	runner.check(m["slots"][0]["done"] == false and float(m["slots"][0]["base"]) == 0.0, "a bad done / base falls back")
	runner.check(Missions.sanitize("junk") == Missions.fresh_state(), "junk is a fresh rank 1")


func test_without_the_section_missions_are_off() -> void:
	TestFixture.use_fork_content()
	var s := GameState.fresh()
	runner.check(not Missions.active(), "the fork's content has no missions")
	runner.check(Missions.tick(s).is_empty() and Missions.claimable(s) == 0, "no-op")
	_eq(Missions.income_pct(s), 0.0, "no bonus")
	runner.check(not bool(Missions.claim(s, 0)["ok"]), "nothing to claim")


# ---------------------------------------------------------------------------------------------
# The shipped content
# ---------------------------------------------------------------------------------------------

func test_shipped_missions_are_complete_and_known() -> void:
	TestFixture.use_game_content()
	runner.check(Missions.active(), "design/content.json has missions")
	var list := Missions.list()
	runner.check(list.size() >= 35, "≥ 35 missions (%d)" % list.size())
	var rs := Missions.ranks()
	runner.check(rs.size() >= 8, "≥ 8 ranks (%d)" % rs.size())
	var per := {}
	var s := GameState.fresh()
	var d := Economy.derive(s)
	for m: Dictionary in list:
		per[int(m["rank"])] = int(per.get(int(m["rank"]), 0)) + 1
		var g: Dictionary = m["goal"]
		runner.check(Missions.COUNTED.has(g["type"]) or Missions.STATE.has(g["type"]), "%s: goal type %s known" % [m["id"], g["type"]])
		runner.check(Missions.REWARDS.has(m["reward"]["type"]), "%s: reward type known" % m["id"])
		runner.check(Missions.value(s, g, 0.0, d) >= 0.0, "%s: progress reads" % m["id"])
		runner.check(str(m["text"]).length() <= 40, "%s: text ≤ 40 characters" % m["id"])
	for r in range(1, rs.size()):
		runner.check(int(per.get(r, 0)) >= 3, "rank %d has missions (%d)" % [r, int(per.get(r, 0))])
	_eq(Missions.rank_pct(1), 0.0, "rank 1 pays nothing")


func test_the_bench_player_claims_missions() -> void:
	TestFixture.use_game_content()
	var s := GameState.fresh()
	PacingSim.run(s, PacingSim.PLAYERS["median"], 7, 240.0, false, 0.25)
	runner.check((s.missions["claimed"] as Array).size() >= 3, "4 minutes of the median player claim ≥ 3 missions (%d)" % (s.missions["claimed"] as Array).size())
	runner.check(Missions.rank(s) >= 2, "rank 1 is done in the first round's first minutes (rank %d)" % Missions.rank(s))
