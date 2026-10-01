extends RefCounted
## Leaders v3 phase 2 (design/leaders-v3.md): every leader's active ability (sim Ability, content
## leaders[].rule.active). One test per type, plus the save round-trip. Game content.

var runner: Object


func setup(_r: Object) -> void:
	TestFixture.use_game_content()


func _round(id: String) -> GameState:
	var s := GameState.fresh()
	Leaders.set_salt(s, 3)
	runner.check(Politics.install(s, id).get("ok", false) == true, "%s: the round starts" % id)
	return s


func _members(s: GameState, ids: Array) -> void:
	s.coalition["opened"] = true
	for id: String in ids:
		Coalition.ps(s, id)["status"] = "member"


func _demand(s: GameState, id: String, price: float = 100.0) -> Dictionary:
	return Coalition._post(s, {"type": "demand", "partner": id, "price": price, "kind": "money", "join": false,
		"ageSec": 0.0, "state": "open", "line": "demand", "variant": 0}, [])


func _d(s: GameState) -> Economy.Derived:
	var d := Economy.derive(s)
	d.seats_gate_open = false
	return d


func _first_member_ids(s: GameState, n: int) -> Array:
	var out: Array = []
	for p: Dictionary in Coalition.partners():
		if out.size() < n and p.get("standIn", false) != true:
			out.append(str(p["id"]))
	return out


func test_every_leader_has_an_ability() -> void:
	for id: String in Leaders.pickable():
		var s := _round(id)
		runner.check(not Ability.def(s).is_empty() and str(Ability.copy(s).get("btn", "")) != "", "%s: an active ability with a button (%s)" % [id, Ability.type(s)])


func test_bibi_unite_quiets_the_pair_once_a_round() -> void:
	var s := _round("bibi")
	runner.check(Ability.block(s) == "pair", "no pair in the group yet: nothing to unite")
	_members(s, ["bengvir", "smotrich"])
	var r := Ability.use(s, _d(s))
	runner.check(r.get("ok", false) and Coalition.is_quiet(s, "bengvir") and Coalition.is_quiet(s, "smotrich"), "תתאחדו: both busy refusing each other")
	runner.check(Ability.block(s) == "used" and not bool(Ability.view(s)["show"]), "once a round: the chip goes")


func test_bennett_signs_then_flips() -> void:
	var s := _round("bennett")
	var d := _d(s)
	runner.check(Ability.use(s, d).get("kind", "") == "sign" and Events.gate_plus(s) == 1, "לחתום: the pledge is up, the gate +1")
	runner.check(str(Ability.view(s, d)["label"]) == str(Ability.copy(s)["btnFlip"]), "the chip now says להפוך")
	var bank := s.bananas
	var susp := Investigation.suspicion(s)
	var f := Ability.use(s, d)
	runner.check(f.get("kind", "") == "flip" and Events.gate_plus(s) == 0, "להפוך: the gate drops now")
	runner.check(s.bananas > bank and (not Investigation.active() or Investigation.suspicion(s) > susp), "cash now, headlines too")
	runner.check(Ability.block(s, d) == "cooldown", "then the pen rests")


func test_bengvir_walks_out_and_comes_back_cheaper() -> void:
	var s := _round("bengvir")
	var ids := _first_member_ids(s, 1)
	_members(s, ids)
	var m := _demand(s, ids[0], 100.0)
	var d := _d(s)
	var before := Economy.derive(s).bps_mult
	runner.check(Ability.use(s, d).get("kind", "") == "walkout" and Ability.walked_out(s), "אני פורש: he is out")
	var dd := Economy.derive(s)
	runner.check(dd.taps_paused and is_equal_approx(dd.bps_mult, before * 0.6), "out: no taps, income × 0.6 (%s → %s)" % [before, dd.bps_mult])
	var ev: Array = []
	for i in 21:
		ev.append_array(Ability.tick(s, 1.0, d))
	runner.check(not Ability.walked_out(s) and ev.any(func(e: Dictionary) -> bool: return str(e.get("kind", "")) == "back"), "חזרתי after 20 s")
	runner.check(is_equal_approx(float(m["price"]), 60.0) and Events.is_active(s, "leaderBuff"), "the demand −40%%, taps × 1.3 (%s)" % str(m["price"]))
	runner.check(Ability.block(s, d) == "cooldown", "a cooldown after he is back")


func test_liberman_clauses_fill_the_document() -> void:
	var s := _round("liberman")
	var d := _d(s)
	Ability.tick(s, 0.1, d)
	var base := Economy.derive(s).base_pct_round
	Leaders.stats(s, "liberman")["declines"] = 4.0
	Ability.tick(s, 0.1, d)
	runner.check(str(Ability.view(s, d)["sub"]) == "4/5" and Ability.block(s, d) == "passive", "4 clauses of 5, nothing to press")
	Leaders.stats(s, "liberman")["declines"] = 5.0
	var ev := Ability.tick(s, 0.1, d)
	runner.check(ev.any(func(e: Dictionary) -> bool: return str(e.get("kind", "")) == "clausesDone"), "the 5th clause files the document")
	runner.check(is_equal_approx(Economy.derive(s).base_pct_round, base + 5.0), "+5% on this round's base")


func test_eisenkot_round_table_quiets_and_discounts() -> void:
	var s := _round("eisenkot")
	var ids := _first_member_ids(s, 2)
	_members(s, ids)
	var m := _demand(s, ids[0], 100.0)
	var d := _d(s)
	runner.check(Ability.use(s, d).get("kind", "") == "roundTable", "שולחן עגול")
	runner.check(is_equal_approx(float(m["price"]), 80.0) and Coalition.is_quiet(s, ids[0]) and Coalition.is_quiet(s, ids[1]), "−20%, everyone quiet")
	Coalition.tick(s, 10.0, d)
	runner.check(float(m["ageSec"]) == 0.0, "a quiet partner's demand does not age (%s)" % str(m["ageSec"]))


func test_smotrich_budget_paid_late_or_missed() -> void:
	var s := _round("smotrich")
	var d := _d(s)
	runner.check(not bool(Ability.view(s, d)["show"]), "no budget on the table yet")
	var ev: Array = []
	for i in 121:
		ev.append_array(Ability.tick(s, 1.0, d))
	runner.check(ev.any(func(e: Dictionary) -> bool: return str(e.get("kind", "")) == "offer"), "a budget comes up after 120 s")
	var price := float(Ability.st(s)["price"])
	s.bananas = price + 1000.0
	for i in 52:
		Ability.tick(s, 1.0, d)
	var r := Ability.use(s, d)
	runner.check(r.get("ok", false) and bool((r["events"] as Array)[0].get("late", false)), "paid in the last 10 s: בדקה ה־90")
	runner.check(is_equal_approx(float(Ability.st(s)["basePct"]), 5.0), "+5% for the late pass")
	for i in 181:
		Ability.tick(s, 1.0, d)
	for i in 61:
		ev.append_array(Ability.tick(s, 1.0, d))
	runner.check(ev.any(func(e: Dictionary) -> bool: return str(e.get("kind", "")) == "budgetMissed") and Events.gate_plus(s) == 1, "missed: the Knesset almost dissolves (gate +1)")


func test_deri_takes_a_demand_to_the_corridor() -> void:
	var s := _round("deri")
	var ids := _first_member_ids(s, 1)
	_members(s, ids)
	var d := _d(s)
	runner.check(Ability.block(s, d) == "empty", "no open demand: nothing to take out")
	_demand(s, ids[0], 100.0)
	runner.check(Ability.use(s, d).get("kind", "") == "corridor" and Coalition.is_quiet(s, ids[0]) and Events.is_active(s, "leaderBuff"), "למסדרון: the partner waits, taps × 1.2")
	runner.check(Ability.block(s, d) == "cooldown", "then 60 s")


func test_golan_swipes_the_unity_offer() -> void:
	var s := _round("golan")
	var d := _d(s)
	for i in 91:
		Ability.tick(s, 1.0, d)
	runner.check(str(Ability.st(s)["phase"]) == "offer" and Ability.can_use(s, d), "a unity offer is up")
	Ability.use(s, d)
	runner.check(is_equal_approx(float(Ability.st(s)["basePct"]), 2.0), "swiped left: +2% base")



## Phase 3: Netanyahu's unity offer for every opposition leader but Golan (leaderSelect.unityOffer).
func test_the_unity_offer_comes_to_every_other_opposition_leader() -> void:
	var u: Dictionary = Leaders.ls().get("unityOffer", {})
	var first := int(u.get("firstSec", 150))
	for id: String in Leaders.pickable():
		var s := _round(id)
		var want := str(Leaders.leader(id).get("side", "")) == "opposition" and Ability.type(s) != "swipeLeft"
		var d := _d(s)
		var saw := false
		for i in first + 1:
			for e: Variant in Ability.tick(s, 1.0, d):
				if e is Dictionary and str((e as Dictionary).get("kind", "")) == "unityOffer":
					saw = true
		runner.check(saw == want and Ability.unity_open(s) == want, "%s: the unity offer %s" % [id, "comes" if want else "never comes"])
		if want:
			runner.check(Ability.unity_refuse_line(s) != "", "%s: a refusal line of his own" % id)


func test_refusing_unity_raises_the_base_and_counts() -> void:
	var s := _round("liberman")
	var d := _d(s)
	var u: Dictionary = Leaders.ls().get("unityOffer", {})
	for i in int(u.get("firstSec", 150)) + 1:
		Ability.tick(s, 1.0, d)
	var v := Ability.view(s, d)
	runner.check(Ability.can_use(s, d) and str(v["state"]) == "offer" and str(v["label"]) == str(u.get("copy", {}).get("btn", "")), "the chip says no")
	var r := Ability.use(s, d)
	runner.check(str(r.get("kind", "")) == "unityRefuse" and is_equal_approx(float(Ability.st(s)["basePct"]), float(u.get("basePct", 1))), "refused: + base")
	runner.check(is_equal_approx(Leaders.stat(s, "liberman", "unityRefusals"), 1.0) and not Ability.unity_open(s), "counted, and the offer is gone")
	runner.check(Ability.block(s, d) == "passive", "the chip is his document again")


func test_an_ignored_unity_offer_does_nothing() -> void:
	var s := _round("eisenkot")
	var d := _d(s)
	var u: Dictionary = Leaders.ls().get("unityOffer", {})
	for i in int(u.get("firstSec", 150)) + int(u.get("windowSec", 20)) + 2:
		Ability.tick(s, 1.0, d)
	runner.check(not Ability.unity_open(s) and is_equal_approx(float(Ability.st(s)["basePct"]), 0.0), "the window closed with no change")
	_members(s, _first_member_ids(s, 1))
	runner.check(Ability.use(s, d).get("kind", "") == "roundTable", "the chip is his round table again")


func test_the_unity_offer_waits_for_a_live_pledge() -> void:
	var s := _round("bennett")
	var d := _d(s)
	Ability.use(s, d)   # sign: the pledge is up
	var u: Dictionary = Leaders.ls().get("unityOffer", {})
	Ability.st(s)["uNext"] = 0.5
	Ability.tick(s, 1.0, d)
	runner.check(Events.is_active(s, "pledge") and not Ability.unity_open(s), "no offer over a pledge he can still flip")
	var raw: Dictionary = JSON.parse_string(JSON.stringify(s.leader_round))
	var a := Ability.sanitize(raw.get("ability"))
	runner.check(a.has("uNext") and str(a.get("uPhase", "x")) in ["", "offer"], "the unity state survives a save")

func test_the_ability_survives_a_save() -> void:
	var s := _round("bengvir")
	var d := _d(s)
	Ability.use(s, d)
	Ability.tick(s, 5.0, d)
	var raw: Dictionary = JSON.parse_string(JSON.stringify(s.leader_round))
	var a := Ability.sanitize(raw.get("ability"))
	runner.check(str(a.get("phase", "")) == "out" and is_equal_approx(float(a["t"]), 15.0), "saved mid-walkout: still out, 15 s to go")
	runner.check(Ability.sanitize({"leader": "nobody", "cd": 5}).is_empty() and str(Ability.sanitize({"phase": "boom"}).get("phase", "")) == "", "junk is dropped")
	Politics.on_election(s)
	runner.check(not s.leader_round.has("ability"), "an election clears the round's ability")
