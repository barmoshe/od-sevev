extends RefCounted
## Suspicion, court day, the postponement ladder, the aide drop and the pardon desk
## (game/scripts/sim/investigation.gd) on the placeholder politics content.

const PF := preload("res://tests/politics_fixture.gd")

var runner: Object


func setup(_r: Object) -> void:
	PF.install()


func teardown() -> void:
	PF.restore()


func _id(n: int) -> String:
	return Content.producer_ids()[n - 1]


func _tick(s: GameState, sec: float, step: float = 0.5) -> Array:
	var out: Array = []
	var t := 0.0
	while t < sec - 1e-9:
		out.append_array(Investigation.tick(s, step, Economy.derive(s)))
		t += step
	return out


func _eq(a: float, b: float, msg: String, tol: float = 1e-6) -> void:
	runner.check(absf(a - b) <= tol * maxf(1.0, absf(b)), "%s: got %s, want %s" % [msg, a, b])


func test_clean_money_never_raises_suspicion() -> void:
	var s := GameState.fresh()
	for n in [1, 2, 3, 8]:
		s.owned[_id(n)] = 20
	_tick(s, 600.0, 5.0)
	_eq(Investigation.suspicion(s), 0.0, "sources 1-3 and 8 are clean")
	runner.check(not s.investigation["revealed"], "the thermometer stays hidden (UX K1)")


func test_gain_is_the_shady_share_of_income() -> void:
	var s := GameState.fresh()
	s.owned[_id(1)] = 10
	s.owned[_id(4)] = 1
	var d := Economy.derive(s)
	var share := float(d.producer_bps[_id(4)]) / (float(d.producer_bps[_id(1)]) + float(d.producer_bps[_id(4)]))
	_eq(Investigation.gain_rate(s, d), 0.6 * share, "rate = weight × the source's share of ₪/s")
	var ev := _tick(s, 10.0, 1.0)
	runner.check(ev.any(func(e: Dictionary) -> bool: return e["ev"] == "revealed"), "the first shady source reveals the thermometer")
	_eq(Investigation.suspicion(s), 6.0 * share, "10 s of it", 1e-3)
	# Scale-free: ten times everything is the same heat.
	var s2 := GameState.fresh()
	s2.owned[_id(1)] = 100
	s2.owned[_id(4)] = 10
	var d2 := Economy.derive(s2)
	runner.check(absf(Investigation.gain_rate(s2, d2) - 0.6 * float(d2.producer_bps[_id(4)]) / (float(d2.producer_bps[_id(1)]) + float(d2.producer_bps[_id(4)]))) < 1e-9, "the rate reads shares, not amounts")
	Coalition.ps(s, "levin")["status"] = "member"
	_eq(Investigation.gain_rate(s, Economy.derive(s)), 0.6 * share * 0.8, "Levin slows the meter ×0.8")


func test_court_day() -> void:
	var s := GameState.fresh()
	s.owned[_id(5)] = 5
	s.owned[_id(1)] = 10
	var bps := Economy.derive(s).bps
	s.investigation["suspicion"] = 99.9
	var ev := _tick(s, 1.0, 0.5)
	runner.check(Investigation.phase(s) == "summons" and ev.any(func(e: Dictionary) -> bool: return e["ev"] == "summons"), "100% opens the court card")
	Investigation.testify(s)
	runner.check(Investigation.phase(s) == "court" and int(s.investigation["courtDays"]) == 1, "'להעיד' starts court day")
	var d := Economy.derive(s)
	_eq(d.bps, bps * 0.5, "court day: ₪/s × 0.5")
	var tap := Economy.tap(s, func() -> float: return 0.0)
	runner.check(tap.get("paused", false) and float(tap["value"]) == 0.0, "taps are paused")
	_tick(s, 29.5, 0.5)
	runner.check(Investigation.phase(s) == "court", "still testifying at 29.5 s")
	ev = _tick(s, 0.5, 0.5)
	runner.check(Investigation.phase(s) == "idle" and ev.any(func(e: Dictionary) -> bool: return e["ev"] == "courtEnd"), "30 s later testimony ends")
	_eq(Investigation.suspicion(s), 0.0, "round 1's floor is 0")
	_eq(Economy.derive(s).bps, bps, "income is back")


func test_summons_auto_testifies_when_ignored() -> void:
	var s := GameState.fresh()
	s.investigation["suspicion"] = 100.0
	_tick(s, 0.5)
	_tick(s, 29.0)
	runner.check(Investigation.phase(s) == "summons", "the card waits 30 s")
	_tick(s, 1.0)
	runner.check(Investigation.phase(s) == "court", "then court day starts by itself (an idle player never deadlocks)")


func test_floor_rises_with_rounds() -> void:
	var s := GameState.fresh()
	for n in [0, 1, 3, 8, 20]:
		s.evolutions = n
		_eq(Investigation.floor_pct(s), minf(5.0 * n, 40.0), "floor after %d elections" % n)
	s.evolutions = 3
	s.investigation["suspicion"] = 90.0
	s.investigation["postponements"] = 4
	Investigation.on_election(s)
	_eq(Investigation.suspicion(s), 15.0, "the election resets suspicion to the floor, not 0 (pitch §11 Q8)")
	runner.check(int(s.investigation["postponements"]) == 0, "and the postponement count")


func test_postponement_ladder() -> void:
	var s := GameState.fresh()
	s.owned[_id(1)] = 10
	var d := Economy.derive(s)
	var costs: Array = []
	var cds: Array = []
	var steps: Array = []
	for i in 6:
		s.bananas = 1000000.0
		s.investigation["phase"] = "summons"
		var want := Investigation.postpone_cost(s, d)
		var r := Investigation.postpone(s, d)
		if r.is_empty():
			costs.append(-1)
			break
		costs.append(int(r["cost"]))
		cds.append(int(r["cooldownSec"]))
		steps.append(int(r["step"]))
		runner.check(is_equal_approx(float(r["cost"]), want), "cost as quoted")
	runner.check(costs == [50000, 100000, 200000, 400000, 800000, -1], "5%% × 2^n of the treasury, the 5th costs 80%%, the 6th is impossible: %s" % str(costs))
	runner.check(cds == [120, 90, 60, 45, 30], "the cooldown shrinks: %s" % str(cds))
	runner.check(steps == [1, 2, 3, 4, 5], "one sentence longer each time: %s" % str(steps))
	s.investigation["postponements"] = 9
	runner.check(Investigation.excuse_step(s) == 6, "past step 6 the excuse holds at 6 (deck §H)")


func test_postponement_is_never_free() -> void:
	var s := GameState.fresh()
	s.owned[_id(1)] = 10
	var d := Economy.derive(s)
	s.bananas = 0.0
	s.investigation["phase"] = "summons"
	_eq(Investigation.postpone_cost(s, d), ceilf(10.0 * d.bps), "an empty treasury still pays 10 s of ₪/s")
	runner.check(not Investigation.can_postpone(s, d), "and can't afford it")


func test_postponed_summons_comes_back() -> void:
	var s := GameState.fresh()
	s.bananas = 100.0
	s.investigation["phase"] = "summons"
	s.investigation["suspicion"] = 100.0
	Investigation.postpone(s, Economy.derive(s))
	_tick(s, 119.5)
	runner.check(Investigation.phase(s) == "postponed", "postponed for 120 s")
	_eq(Investigation.suspicion(s), 100.0, "suspicion stays at the top meanwhile")
	_tick(s, 0.5)
	runner.check(Investigation.phase(s) == "summons", "then the summons is back")


func test_aide_catch_and_drop() -> void:
	var s := GameState.fresh()
	s.owned[_id(1)] = 10
	s.evolutions = 2
	runner.check(not Investigation.can_drop_aide(s), "no aide holds money: nothing to drop")
	var base := Economy.derive(s).prestige_mult
	var award := Economy.apply_golden(s, "aide")
	runner.check(award > 0.0 and is_equal_approx(float(s.investigation["aideHolding"]), award), "the suitcase pays, and the money sits on an aide's card")
	_eq(Investigation.suspicion(s), 15.0, "an aide with cash is suspicious (+15)")
	s.investigation["suspicion"] = 80.0
	runner.check(Investigation.drop_aide(s), "'אני לא מכיר אותו'")
	_eq(Investigation.suspicion(s), 10.0, "suspicion falls to the floor (2 rounds: 10%), never below")
	_eq(Economy.derive(s).prestige_mult, base * 0.97, "the base pays −3%")
	Investigation.aide_catch(s, 5.0)
	Investigation.drop_aide(s)
	_eq(Economy.derive(s).prestige_mult, base * 0.97 * 0.97, "and it compounds, permanently")
	s.all_time_bananas = 0.0
	Investigation.on_election(s)
	_eq(Economy.derive(s).prestige_mult, base * 0.97 * 0.97, "an election doesn't restore it")
	Investigation.aide_catch(s, 5.0)
	s.investigation["phase"] = "court"
	runner.check(not Investigation.drop_aide(s), "not during a court day (pitch §10.6)")


func test_laundry_rolls_only_in_its_era() -> void:
	var s := GameState.fresh()
	var seen := {}
	for i in 400:
		seen[Economy.roll_golden_outcome(func() -> float: return float(i) / 400.0, s)] = true
	runner.check(not seen.has("laundry") and seen.has("aide"), "round 1: cash, buffs, the aide; no laundry")
	s.evolutions = 6
	seen = {}
	for i in 400:
		seen[Economy.roll_golden_outcome(func() -> float: return float(i) / 400.0, s)] = true
	runner.check(seen.has("laundry"), "the laundry rolls in its era")


func test_pardon_desk_never_repeats() -> void:
	var s := GameState.fresh()
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var last := 0
	var seen := {}
	for i in 300:
		var k := Investigation.request_pardon(s, func() -> float: return rng.randf())
		runner.check(k != last and k >= 1 and k <= 8, "stamp %d follows %d" % [k, last])
		last = k
		seen[k] = true
	runner.check(seen.size() == 8 and int(s.investigation["pardons"]) == 300, "all 8 stamps, 300 requests counted")
	var fixed := Investigation.request_pardon(s, func() -> float: return float(last - 1) / 8.0 + 0.01)
	runner.check(fixed != last, "a draw of the last stamp moves to the next one")


func test_external_suspicion_and_freeze() -> void:
	var s := GameState.fresh()
	s.owned[_id(4)] = 3
	Investigation.add(s, 8.0)
	_eq(Investigation.suspicion(s), 8.0, "Lapid's audit +8")
	Investigation.freeze(s, 60.0)
	_tick(s, 59.0, 1.0)
	_eq(Investigation.suspicion(s), 8.0, "S12: frozen for 60 s")
	_tick(s, 3.0, 1.0)
	runner.check(Investigation.suspicion(s) > 8.0, "then it moves again")
	Investigation.add(s, 500.0)
	_eq(Investigation.suspicion(s), 100.0, "capped at max")


func test_court_end_says_why() -> void:
	# For the audio's courtEnd(reason): testified | served | postponed.
	var s := GameState.fresh()
	s.investigation["phase"] = "summons"
	var st := Investigation.testify(s)
	runner.check(str(st[0].get("reason", "")) == "testified", "courtStart after 'להעיד' says testified")
	var ev := _tick(s, 30.0)
	var ends := ev.filter(func(e: Dictionary) -> bool: return e["ev"] == "courtEnd")
	runner.check(ends.size() == 1 and ends[0]["reason"] == "testified", "and so does its courtEnd: %s" % str(ends))
	s.investigation["suspicion"] = 100.0
	ev = _tick(s, 31.0)
	runner.check(ev.any(func(e: Dictionary) -> bool: return e["ev"] == "courtStart" and e["reason"] == "served"), "an ignored summons is served")
	ev = _tick(s, 30.0)
	runner.check(ev.any(func(e: Dictionary) -> bool: return e["ev"] == "courtEnd" and e["reason"] == "served"), "and ends as served")
	s.bananas = 1e6
	s.investigation["phase"] = "summons"
	var r := Investigation.postpone(s, Economy.derive(s))
	runner.check(r["events"] == [{"ev": "courtEnd", "reason": "postponed"}], "a postponement returns courtEnd postponed")
	s.investigation["phase"] = "court"
	s.investigation["courtReason"] = "served"
	var l := GameState.from_dict(JSON.parse_string(JSON.stringify(s.to_dict())))
	runner.check(l.investigation["courtReason"] == "served", "the reason survives a reload mid-court")


## The election card's "×after" now carries the aide drops' ×0.97 each (Economy.derive's
## prestige_mult does); it used to promise more than the next round paid.
func test_the_election_card_counts_aide_drops() -> void:
	var s := GameState.fresh()
	s.thumbs_owned = 10
	var d0 := Economy.derive(s)
	var clean := ElectionCard.mult_after(s, d0)
	s.investigation["aideDrops"] = 2
	var d2 := Economy.derive(s)
	runner.check(is_equal_approx(ElectionCard.mult_after(s, d2), clean * pow(0.97, 2)), "two drops: ×0.97² (%s vs %s)" % [ElectionCard.mult_after(s, d2), clean])
	runner.check(is_equal_approx(d2.prestige_mult, (1.0 + Economy.mult_per_base() * 10.0) * pow(0.97, 2)), "and that is what derive pays now")
