extends RefCounted
## The coalition group chat (game/scripts/sim/coalition.gd) on the placeholder politics content
## (tests/fixtures/politics.json): seats, the 61 gate, % upkeep, demands, ultimatums, leaving and
## rejoining, and each partner's one-line mechanic.

const PF := preload("res://tests/politics_fixture.gd")

var runner: Object


func setup(_r: Object) -> void:
	PF.install()


func teardown() -> void:
	PF.restore()


static func _zero() -> float:
	return 0.0


static func _one() -> float:
	return 0.999


func _p1() -> String:
	return Content.producer_ids()[0]


## A state that has opened the group, with the listed partners already members. `quiet` stops
## the background demand timer so a test sees only the messages it posts.
func _with(members: Array, play_sec: float = 0.0, paid: int = 0, quiet: bool = false) -> GameState:
	var s := GameState.fresh()
	s.coalition["opened"] = true
	if quiet:
		s.coalition["nextDemandSec"] = 1e12
	s.stats["playtimeSec"] = play_sec
	s.coalition["paidLifetime"] = paid
	for id: String in members:
		Coalition.ps(s, id)["status"] = "member"
	return s


func _tick(s: GameState, sec: float, step: float = 0.5, rng: Callable = _zero) -> Array:
	var out: Array = []
	var t := 0.0
	while t < sec - 1e-9:
		out.append_array(Coalition.tick(s, step, Economy.derive(s), {}, rng))
		t += step
	return out


func _open_of(s: GameState, id: String, type: String = "") -> Dictionary:
	var m := Coalition.open_msg(s, id)
	return m if type == "" or (not m.is_empty() and m["type"] == type) else {}


func test_contract_lint() -> void:
	var err := Politics.validate()
	runner.check(err.is_empty(), "the placeholder politics content passes the lint: %s" % str(err))
	var bad := Content.data().duplicate(true)
	(bad["partners"][0] as Dictionary)["unlock"] = {"runBananasAtLeats": 5}
	(bad["partners"][1] as Dictionary)["effects"] = [{"type": "nope"}]
	(bad["partners"][2] as Dictionary)["excludes"] = ["ghost"]
	var e2 := Politics.validate(bad)
	runner.check(e2.size() >= 3, "a typo'd condition, an unknown effect and an unknown partner are all reported (%d)" % e2.size())


func test_game_content_passes_the_lint() -> void:
	# Whatever design/content.json holds now (the fork's, or the Hebrew rewrite with the politics
	# sections), its politics references must resolve. Sections not written yet are skipped.
	var c: Variant = JSON.parse_string(FileAccess.get_file_as_string(Content.PATH))
	runner.check(c is Dictionary, "design content parses")
	var err := Politics.validate(c)
	runner.check(err.is_empty(), "design/content.json politics sections pass the lint: %s" % str(err))


func test_c1_opens_the_group_with_the_fixed_first_demand() -> void:
	var s := GameState.fresh()
	s.owned[_p1()] = 2
	s.bananas = 100.0
	runner.check(_tick(s, 1.0).is_empty() and not s.coalition["opened"], "2 sources owned: no ping yet (C1 needs 3)")
	s.owned[_p1()] = 3
	s.bananas = 59.0
	_tick(s, 1.0)
	runner.check(not s.coalition["opened"], "the first demand isn't affordable yet: no ping")
	s.bananas = 60.0
	var blocked := Coalition.tick(s, 0.5, Economy.derive(s), {"allowPing": false})
	runner.check(blocked.is_empty(), "a modal open (allowPing false) holds the ping")
	var ev := _tick(s, 0.5)
	runner.check(s.coalition["opened"], "the group opens")
	var chat: Array = s.coalition["chat"]
	runner.check(chat[0]["key"] == "chat.sys.created" and chat[1]["key"] == "chat.sys.joined" and chat[1]["partner"] == "bengvir", "created, then Ben Gvir joins")
	runner.check(chat[2]["type"] == "demand" and chat[2]["partner"] == "bengvir" and float(chat[2]["price"]) == 60.0, "his demand is the fixed 60 ₪ (pitch §11 Q2)")
	runner.check(ev.any(func(e: Dictionary) -> bool: return e["ev"] == "groupOpened"), "the UI hears groupOpened")


func test_first_payment_reveals_34_of_61() -> void:
	var s := GameState.fresh()
	s.owned[_p1()] = 3
	s.bananas = 75.0
	_tick(s, 0.5)
	var m := _open_of(s, "bengvir", "demand")
	var r := Coalition.pay(s, int(m["seq"]))
	runner.check(r["ok"] and r["joined"], "paying the join demand makes him a member")
	runner.check(is_equal_approx(s.bananas, 15.0), "60 ₪ spent")
	var si := Coalition.seat_info(s)
	runner.check(int(si["effective"]) == 34 and int(si["gateSeats"]) == 61, "one source + Ben Gvir = 34/61 (UX §2.3), got %d" % int(si["effective"]))
	var tail: Array = (s.coalition["chat"] as Array).slice(-2)
	runner.check(tail[0]["type"] == "reply" and tail[1]["type"] == "thanks", "the player's auto-reply, then his thanks")
	runner.check(m["state"] == "paid" and int(s.coalition["paidLifetime"]) == 1, "the pill becomes paid; one demand paid")


func test_demands_are_a_percentage_of_income() -> void:
	var s := _with(["bengvir"])
	s.owned[_p1()] = 50
	var d := Economy.derive(s)
	var want := ceilf(45.0 * d.bps)
	runner.check(is_equal_approx(Coalition.demand_price(s, "bengvir", d), want), "a demand costs 45 s of ₪/s (%s)" % want)
	s.owned[_p1()] = 500
	var d2 := Economy.derive(s)
	runner.check(Coalition.demand_price(s, "bengvir", d2) > 5.0 * want, "and scales with income, never flat")
	var s0 := _with(["bengvir"])
	runner.check(is_equal_approx(Coalition.demand_price(s0, "bengvir", Economy.derive(s0)), 10.0), "minPrice floors a zero income")
	runner.check(is_equal_approx(Coalition.demand_price(s, "regev", d2), 0.0), "Regev's demand is a ceremony, not money")


func test_upkeep_is_a_percentage_of_income_and_effects_apply() -> void:
	var s := GameState.fresh()
	for id in Content.producer_ids():
		s.owned[id] = 10
	var raw := Economy.derive(s).bps
	var p3: String = Content.producer_ids()[2]
	var p3_raw := float(Economy.derive(s).producer_bps[p3])
	Coalition.ps(s, "bengvir")["status"] = "member"
	Coalition.ps(s, "deri")["status"] = "member"
	var d := Economy.derive(s)
	runner.check(is_equal_approx(Coalition.upkeep_pct(s), 9.0), "Ben Gvir 4% + Deri 5%")
	runner.check(is_equal_approx(d.bps, raw * 0.91), "₪/s pays 9%% upkeep (%s vs %s)" % [d.bps, raw * 0.91])
	Coalition.ps(s, "smotrich")["status"] = "member"
	var d2 := Economy.derive(s)
	runner.check(is_equal_approx(float(d2.producer_bps[p3]), p3_raw * 1.2 * (1.0 - 0.12)), "Smotrich raises VAT: source 3 ×1.2, minus his 3%")
	Coalition.ps(s, "smotrich")["status"] = "left"
	runner.check(is_equal_approx(Economy.derive(s).bps, raw * 0.91), "a partner who left costs nothing and gives nothing")


func test_no_ultimatum_before_3_minutes_and_2_paid() -> void:
	var s := _with(["bengvir", "smotrich"], 0.0, 0)
	_tick(s, 400.0, 1.0, _zero)
	runner.check(Coalition.open_ultimatums(s) == 0, "no ultimatum before 3:00 and 2 paid demands, however long the demand waits")
	runner.check(not _open_of(s, "bengvir").is_empty() or not _open_of(s, "smotrich").is_empty(), "the demands still arrive (plain)")
	s.stats["playtimeSec"] = 200.0
	runner.check(not Coalition.ultimatums_unlocked(s), "3:00 alone isn't enough")
	s.coalition["paidLifetime"] = 2
	runner.check(Coalition.ultimatums_unlocked(s), "3:00 and 2 paid unlocks ultimatums (UX U1)")
	_tick(s, 1.0, 1.0, _zero)
	runner.check(Coalition.open_ultimatums(s) == 1, "a waiting demand escalates to exactly one ultimatum (maxOpen 1)")
	var u: Dictionary = {}
	for m: Dictionary in s.coalition["chat"]:
		if m["type"] == "ultimatum" and m["state"] == "open":
			u = m
	runner.check(is_equal_approx(float(u["leftSec"]), 90.0), "the countdown is 90 s (≥ 90, pitch §11 Q3)")


func test_ultimatum_marks_expiry_and_rejoin() -> void:
	var s := _with(["bengvir", "smotrich"], 300.0, 3, true)
	s.owned[_p1()] = 30
	var out: Array = []
	var m := Coalition._post(s, {"type": "ultimatum", "partner": "bengvir", "price": 200.0, "kind": "money", "leftSec": 90.0, "state": "open"}, out)
	var before := int(Coalition.seat_info(s)["effective"])
	var ev := _tick(s, 89.0, 1.0, _one)
	var marks := ev.filter(func(e: Dictionary) -> bool: return e["ev"] == "ultimatumMark").map(func(e: Dictionary) -> int: return e["left"])
	runner.check(marks == [60, 30], "the countdown announces 60 and 30 (deck §E), got %s" % str(marks))
	runner.check(Coalition.status(s, "bengvir") == "member", "still in at 1 s left")
	ev = _tick(s, 1.0, 1.0, _one)
	runner.check(m["state"] == "expired" and Coalition.status(s, "bengvir") == "left", "at 0 he leaves the group")
	var left := Coalition.open_msg(s, "bengvir")
	runner.check(left.get("key", "") == "chat.sys.left" and left.get("payable", "") == "rejoin", "the left line carries the rejoin pill")
	runner.check(is_equal_approx(float(left["price"]), 300.0), "rejoin costs 1.5× the missed demand (pitch §11 Q4)")
	runner.check(Coalition.status(s, "gantz") == "member", "Gantz walks in as the stand-in")
	var after := int(Coalition.seat_info(s)["effective"])
	runner.check(after == before - 12 + 4, "seats: −12 Ben Gvir, +4 Gantz (%d → %d)" % [before, after])
	s.bananas = 299.0
	runner.check(not Coalition.pay(s, int(left["seq"]))["ok"], "short of the rejoin price")
	s.bananas = 300.0
	var r := Coalition.pay(s, int(left["seq"]))
	runner.check(r["ok"] and Coalition.status(s, "bengvir") == "member", "rejoined (every timer loss recoverable)")
	runner.check(int(s.coalition["rejoinsLifetime"]) == 1 and int(s.coalition["leftLifetime"]) == 1, "counted")


func test_paying_an_ultimatum_deletes_it() -> void:
	var s := _with(["bengvir"], 300.0, 3, true)
	s.bananas = 500.0
	var m := Coalition._post(s, {"type": "ultimatum", "partner": "bengvir", "price": 200.0, "kind": "money", "leftSec": 90.0, "state": "open"}, [])
	var r := Coalition.pay(s, int(m["seq"]))
	runner.check(r["ok"] and m["state"] == "deleted", "a paid ultimatum reads 'ההודעה נמחקה' (UX §4.2)")
	runner.check(not Coalition.pay(s, int(m["seq"]))["ok"], "paying twice does nothing")
	_tick(s, 200.0, 1.0, _one)
	runner.check(Coalition.status(s, "bengvir") == "member", "and he stays")


func test_goldknopf_price_only_climbs() -> void:
	var s := _with(["goldknopf"])
	s.owned[_p1()] = 200
	s.bananas = 1e12
	var d := Economy.derive(s)
	var p0 := Coalition.demand_price(s, "goldknopf", d)
	var nxt := Coalition.next_price(s, "goldknopf", d)
	for i in 3:
		var m := Coalition._post(s, {"type": "demand", "partner": "goldknopf", "price": Coalition.demand_price(s, "goldknopf", d), "kind": "money", "state": "open"}, [])
		Coalition.pay(s, int(m["seq"]))
	var p3 := Coalition.demand_price(s, "goldknopf", d)
	runner.check(absf(nxt - p0 * 1.3) <= 2.0, "next price = ×1.3 (deck: 'עכשיו זה {next_price}')")
	runner.check(absf(p3 - p0 * pow(1.3, 3)) <= 2.0, "three payments: ×1.3³ (%s vs %s)" % [p3, p0 * pow(1.3, 3)])
	s.all_time_bananas = 1e9
	Coalition.on_election(s)
	runner.check(int(s.coalition["levels"]["goldknopf"]) == 3, "his bar never resets, not even on election")


func test_gafni_turns_a_lost_vote_into_a_tie() -> void:
	var s := _with(["bengvir", "deri"])
	var before := Coalition.seat_info(s)
	Coalition.ps(s, "gafni")["status"] = "member"
	var si := Coalition.seat_info(s)
	runner.check(int(si["gate"]) == 59 and int(si["abstain"]) == 4, "4 abstainers: the majority is floor(116/2)+1 = 59")
	runner.check(int(si["total"]) == int(before["total"]) and int(si["effective"]) == int(before["effective"]) + 2, "Gafni adds no seats; 'effective' reads 2 closer to 61")


func test_seats_gate_blocks_the_election() -> void:
	var s := GameState.fresh()
	s.all_time_bananas = 1e7
	runner.check(not Economy.derive(s).evolve_enabled, "enough base pending but no coalition: no 'עוד סבב!'")
	for id in Content.producer_ids():
		s.owned[id] = 1
	for id in ["bengvir", "deri", "smotrich"]:
		Coalition.ps(s, id)["status"] = "member"
	var si := Coalition.seat_info(s)
	runner.check(int(si["effective"]) == 36 + 28 - 0, "36 own + 28 partners = %d" % int(si["effective"]))
	runner.check(Economy.derive(s).evolve_enabled, "61+ opens the gate")
	Coalition.ps(s, "deri")["frozen"] = true
	runner.check(not Economy.derive(s).evolve_enabled, "a frozen row doesn't count")


func test_gotliv_transfer_window() -> void:
	var s := _with(["bengvir", "gotliv"], 300.0, 3, true)
	var up0 := Coalition.upkeep_pct(s)
	var seats0 := int(Coalition.seat_info(s)["effective"])
	var ev := _tick(s, 199.0, 1.0, _one)
	runner.check(Coalition.status(s, "gotliv") == "member", "her meter isn't full yet")
	ev = _tick(s, 2.0, 1.0, _one)
	runner.check(ev.any(func(e: Dictionary) -> bool: return e["ev"] == "transfer" and e["partner"] == "gotliv" and e["to"] == "bengvir"), "the transfer window fires at a full meter")
	runner.check(Coalition.status(s, "gotliv") == "transferred" and (Coalition.ps(s, "bengvir")["carry"] as Array).has("gotliv"), "she moves to Ben Gvir's row")
	runner.check(Coalition.row_seats(s, "bengvir") == 14 and is_equal_approx(Coalition.upkeep_pct(s), up0), "with her seats and her upkeep (כולל דמי אחזקה)")
	runner.check(int(Coalition.seat_info(s)["effective"]) == seats0, "the total is unchanged until the ultimatum runs out")
	var u := _open_of(s, "bengvir", "ultimatum")
	runner.check(not u.is_empty() and str(u.get("transfer", "")) == "gotliv", "Ben Gvir posts the 90 s ultimatum")
	_tick(s, 91.0, 1.0, _one)
	runner.check(int(Coalition.seat_info(s)["effective"]) == seats0 - 14 + 4, "unpaid: Ben Gvir leaves and takes her seats (−14; Gantz stands in +4)")
	var left := Coalition.open_msg(s, "bengvir")
	s.bananas = float(left["price"])
	Coalition.pay(s, int(left["seq"]))
	runner.check(int(Coalition.seat_info(s)["effective"]) == seats0 + 4, "rejoining brings both back (Gantz stays for the round)")
	_tick(s, 400.0, 1.0, _one)
	runner.check(s.coalition["transferDone"] and not (Coalition.ps(s, "bengvir")["carry"] as Array).is_empty(), "once per round")


func test_poach_a_rebel() -> void:
	var s := _with(["bengvir"])
	s.run_bananas = 40000.0
	s.owned[_p1()] = 10
	_tick(s, 200.0, 1.0, _one)
	runner.check(Coalition.status(s, "almog") == "removed", "Almog shows up removed by an admin (deck §E)")
	var m := Coalition.open_msg(s, "almog")
	runner.check(m.get("key", "") == "chat.sys.removed" and m.get("payable", "") == "poach", "his line carries the poach pill")
	s.bananas = float(m["price"])
	var r := Coalition.pay(s, int(m["seq"]))
	runner.check(r["ok"] and Coalition.status(s, "almog") == "member", "poached")
	var last: Dictionary = (s.coalition["chat"] as Array).back()
	runner.check(last.get("key", "") == "chat.sys.added" and last.get("partner", "") == "almog", "'צורף על ידי מנהל'")


## "Won't sit with" both ways, the bigger side first (spec §7.2.2): Abbas (4) excludes Ben Gvir (12).
## Abbas's rejoin pill closes when Ben Gvir comes back, so paying it can never throw Ben Gvir out;
## and a member who excludes a smaller partner keeps that partner from asking.
func test_wont_sit_with_the_bigger_side_first() -> void:
	var s := _with(["smotrich"], 0.0, 0, true)
	s.run_bananas = 60000.0
	Coalition.ps(s, "abbas")["status"] = "left"
	var am := Coalition._post(s, {"type": "sys", "key": "chat.sys.left", "partner": "abbas", "payable": "rejoin", "price": 10.0, "state": "open"}, [])
	Coalition.ps(s, "bengvir")["status"] = "left"
	var bm := Coalition._post(s, {"type": "sys", "key": "chat.sys.left", "partner": "bengvir", "payable": "rejoin", "price": 10.0, "state": "open"}, [])
	s.bananas = 10.0
	Coalition.pay(s, int(bm["seq"]))
	runner.check(Coalition.status(s, "bengvir") == "member" and am["state"] == "expired" and Coalition.status(s, "abbas") == "absent",
		"Ben Gvir back: Abbas's rejoin pill closes (a pill never trades 12 seats for 4)")
	# the other direction: a bigger member who excludes a smaller partner keeps him from asking
	(Coalition.partner("bengvir") as Dictionary)["excludes"] = ["amsalem"]
	_tick(s, 300.0, 1.0, _one)
	runner.check(Coalition.status(s, "amsalem") == "absent", "Ben Gvir won't sit with Amsalem (2): Amsalem never asks while he sits")
	runner.check(Coalition.roster(s).any(func(r: Dictionary) -> bool: return r["id"] == "amsalem" and r["excluded"]), "the roster marks him excluded")
	(Coalition.partner("bengvir") as Dictionary).erase("excludes")


func test_abbas_sits_only_while_ben_gvir_is_out() -> void:
	var s := _with([], 0.0, 0, true)
	s.run_bananas = 60000.0
	Coalition.ps(s, "bengvir")["status"] = "member"
	_tick(s, 300.0, 1.0, _one)
	runner.check(Coalition.status(s, "abbas") == "absent", "with Ben Gvir in, Abbas never joins")
	Coalition.ps(s, "bengvir")["status"] = "left"
	_tick(s, 20.0, 1.0, _one)
	runner.check(Coalition.status(s, "abbas") == "pending", "with Ben Gvir out, Abbas joins the chat")
	var m := Coalition.open_msg(s, "abbas")
	s.bananas = float(m["price"])
	runner.check(Coalition.pay(s, int(m["seq"]))["joined"], "and sits")
	var lm := Coalition._post(s, {"type": "sys", "key": "chat.sys.left", "partner": "bengvir", "payable": "rejoin", "price": 10.0, "state": "open"}, [])
	s.bananas = 10.0
	Coalition.pay(s, int(lm["seq"]))
	runner.check(Coalition.status(s, "bengvir") == "member" and Coalition.status(s, "abbas") == "absent", "Ben Gvir back: Abbas leaves")


func test_brawl_freezes_both_rows_until_they_go_outside() -> void:
	var s := _with(["amsalem", "smotrich", "bengvir"])
	var seats := int(Coalition.seat_info(s)["effective"])
	var ev := Coalition.start_brawl(s, "amsalem", "smotrich")
	runner.check(ev.size() == 2 and int(Coalition.seat_info(s)["effective"]) == seats - 9, "both rows freeze (−2 −7)")
	runner.check(Coalition.start_brawl(s, "amsalem", "bengvir").is_empty(), "a brawling partner can't start another")
	var b := Coalition.open_brawl(s)
	Coalition.resolve_brawl(s, int(b["seq"]))
	runner.check(int(Coalition.seat_info(s)["effective"]) == seats and b["state"] == "resolved", "'צאו החוצה' unfreezes them")
	runner.check(s.coalition["corridorOpen"], "'המסדרון' exists")
	Coalition.on_chat_opened(s, _zero)
	Coalition.on_chat_opened(s, _one)
	runner.check(int(s.coalition["corridorMsgs"]) == 1 + 9, "its muted counter climbs each time the chat opens (1 + 9)")


func test_regev_wants_a_ceremony() -> void:
	var s := _with(["regev"])
	var m := Coalition._post(s, {"type": "demand", "partner": "regev", "price": 0.0, "kind": "ceremony", "state": "open"}, [])
	runner.check(Coalition.pay(s, int(m["seq"]))["reason"] == "ceremony", "no money path: she wants the ribbon")
	runner.check(Coalition.pay(s, int(m["seq"]), true)["ok"], "the 3 s ribbon tap pays her")


func test_deri_cannot_leave_and_golan_adds_suspicion() -> void:
	var s := _with(["deri", "golan"], 300.0, 3)
	s.owned[_p1()] = 10
	_tick(s, 2000.0, 1.0, _one)
	runner.check(Coalition.status(s, "deri") == "member", "Deri never walks: 'יצאנו מהממשלה, לא מהקבוצה'")
	var s2 := _with(["golan"])
	var m := Coalition._post(s2, {"type": "demand", "partner": "golan", "price": 10.0, "kind": "money", "state": "open"}, [])
	s2.bananas = 10.0
	Coalition.pay(s2, int(m["seq"]))
	runner.check(is_equal_approx(Investigation.suspicion(s2), 4.0), "each phantom employee adds suspicion (+4)")


func test_partners_join_one_at_a_time_as_they_unlock() -> void:
	var s := _with([])
	s.run_bananas = 1e9
	s.owned[_p1()] = 10
	_tick(s, 7.5, 0.5)
	var joined := 0
	for m: Dictionary in s.coalition["chat"]:
		if m.get("key", "") == "chat.sys.joined" or m.get("key", "") == "chat.sys.removed":
			joined += 1
	runner.check(joined == 1, "one partner per joinGapSec (8 s), got %d" % joined)
	_tick(s, 200.0, 1.0)
	runner.check(Coalition.status(s, "gantz") == "absent", "the stand-in never joins by unlock")
	var pending := 0
	for p: Dictionary in Coalition.partners():
		if Coalition.status(s, p["id"]) in ["pending", "removed"]:
			pending += 1
	runner.check(pending >= 12, "the rest arrive over time (%d)" % pending)


func test_election_clears_the_chat() -> void:
	var s := _with(["bengvir", "deri"])
	s.owned[_p1()] = 10
	_tick(s, 300.0, 1.0)
	s.evolutions = 1
	Coalition.on_election(s)
	var chat: Array = s.coalition["chat"]
	runner.check(chat.size() == 1 and chat[0]["key"] == "chat.sys.cleared" and int(chat[0]["n"]) == 2, "'ביבי ניקה את הצ׳אט. לקראת סבב בחירות 2.'")
	runner.check(Coalition.status(s, "bengvir") == "absent" and int(Coalition.seat_info(s)["partners"]) == 0, "the coalition resets (UX elect.reset)")
	runner.check(s.coalition["opened"], "the group itself stays")


func test_chat_log_is_capped_but_keeps_open_messages() -> void:
	var s := _with(["bengvir"])
	var keep := Coalition._post(s, {"type": "demand", "partner": "bengvir", "price": 5.0, "kind": "money", "state": "open"}, [])
	for i in 200:
		Coalition._post(s, {"type": "reply", "n": 1}, [])
	var chat: Array = s.coalition["chat"]
	runner.check(chat.size() == 80, "the log holds chatMax messages")
	runner.check(chat.has(keep), "an open demand is never trimmed")


func test_no_coalition_content_means_no_gate() -> void:
	PF.restore()
	TestFixture.use_fork_content()
	var s := GameState.fresh()
	s.all_time_bananas = 1e6
	runner.check(not Coalition.active() and Economy.derive(s).evolve_enabled, "fork content: the gate is the base gate only")
	runner.check(Coalition.tick(s, 1.0, Economy.derive(s)).is_empty(), "and the coalition is a no-op")


func test_derive_gate_matches_seat_info() -> void:
	# Economy.derive() reads the gate from Coalition's one-pass modifier; seat_info() is the HUD's.
	# They must agree in every state.
	var s := _with(["bengvir", "smotrich", "deri", "gotliv", "gafni", "amsalem"], 300.0, 3, true)
	for id in Content.producer_ids():
		s.owned[id] = 1
	var cases := [
		func() -> void: pass,
		func() -> void: Coalition.ps(s, "gafni")["status"] = "left",
		func() -> void: Coalition.start_brawl(s, "amsalem", "smotrich"),
		func() -> void: Coalition.ps(s, "gotliv")["status"] = "transferred"; (Coalition.ps(s, "bengvir")["carry"] as Array).append("gotliv"),
		func() -> void: Coalition.bench(s, "deri", 30.0),
		func() -> void: Events.fire(s, "nameless", Economy.derive(s)),
		func() -> void: s.thumbs_owned = 40,
	]
	for i in cases.size():
		(cases[i] as Callable).call()
		var si := Coalition.seat_info(s)
		var want: bool = int(si["effective"]) >= int(si["gateSeats"])
		runner.check(Economy.derive(s).seats_gate_open == want and Coalition.gate_open(s) == want, "case %d: derive and seat_info agree (%s)" % [i, str(si)])
		# nudge the state across the gate both ways
		s.owned[Content.producer_ids()[7]] = 0 if i % 2 == 0 else 1


func test_round_time_unlocks_and_their_scale() -> void:
	# The arrival cadence: partners can unlock on round time (runSecAtLeast), and that ladder
	# shrinks by unlockTimeScalePerElection each election (coalition's pacing lever, sim/README).
	var p := Coalition.partner("smotrich")
	p["unlock"] = {"runSecAtLeast": 100}
	Content.data()["coalition"]["unlockTimeScalePerElection"] = 0.9
	var s := _with(["bengvir"], 0.0, 0, true)
	s.run_time_sec = 99.0
	runner.check(Coalition._next_join(s, {}) != "smotrich", "not before 100 s of the round")
	s.run_time_sec = 100.0
	runner.check(Coalition._next_join(s, {}) == "smotrich", "at 100 s he arrives")
	s.evolutions = 2
	s.run_time_sec = 81.0
	runner.check(Coalition._next_join(s, {}) == "smotrich", "two elections later: 100 × 0.9² = 81 s")
	s.run_time_sec = 80.0
	runner.check(Coalition._next_join(s, {}) != "smotrich", "and not before")
	# unlockTimeScaleMin: the clock eases toward a floor instead of to zero (later rounds get faster
	# and never collapse): 100 × (0.5 + 0.5 × 0.8²) = 82 s after two elections, ≥ 50 s forever.
	Content.data()["coalition"]["unlockTimeScalePerElection"] = 0.8
	Content.data()["coalition"]["unlockTimeScaleMin"] = 0.5
	s.run_time_sec = 82.0
	runner.check(Coalition._next_join(s, {}) == "smotrich", "eased: 100 × (0.5 + 0.5 × 0.8²) = 82 s")
	s.run_time_sec = 81.5
	runner.check(Coalition._next_join(s, {}) != "smotrich", "and not before 82 s")
	var prev := 2.0
	for n in 40:
		var f := Coalition.time_scale(n)
		runner.check(f <= prev and f >= 0.5, "the clock factor falls every election and stays ≥ the floor (n %d: %.3f)" % [n, f])
		prev = f


func test_demand_seconds_ease_per_election() -> void:
	# demandSecScalePerElection / demandSecScaleMin: a veteran's deals cost fewer seconds of income,
	# so the coalition does not eat the speed the base buys (the 45 s demand is round 1's price).
	var s := _with(["bengvir"], 0.0, 0, true)
	s.owned[_p1()] = 400
	var d := Economy.derive(s)
	var p0 := Coalition.demand_price(s, "bengvir", d)
	runner.check(d.bps * Coalition._num("demandSec", 45.0) > Coalition._num("minPrice", 10.0) * 2.0, "the test state earns above the price floor (%s/s)" % d.bps)
	Content.data()["coalition"]["demandSecScalePerElection"] = 0.8
	Content.data()["coalition"]["demandSecScaleMin"] = 0.5
	runner.check(Coalition.demand_price(s, "bengvir", d) == p0, "round 1 pays the full demandSec")
	s.evolutions = 1
	var want := ceilf(maxf(Coalition._num("minPrice", 10.0), Coalition._num("demandSec", 45.0) * 0.9 * d.bps))
	runner.check(is_equal_approx(Coalition.demand_price(s, "bengvir", d), want), "after one election: × (0.5 + 0.5 × 0.8) = 0.9 (%s)" % want)
	runner.check(is_equal_approx(Coalition.price_scale(60), 0.5 + 0.5 * pow(0.8, 60)), "and it eases toward the floor, never below")
	Content.data()["coalition"].erase("demandSecScalePerElection")
	runner.check(Coalition.price_scale(5) == 1.0, "without the key the price never eases")


func test_lines_variants_rotate_without_repeats() -> void:
	# Designer ask (2): partners[].linesVariants rotate in order; lines.* stays the first variant.
	var p := Coalition.partner("smotrich")
	p["lines"] = {"demand": "A", "threat": "T"}
	p["linesVariants"] = {"demand": ["A", "B", "C"]}
	var s := _with(["smotrich"], 0.0, 0, false)
	var seen: Array = []
	for i in 7:
		seen.append(Coalition._variant(s, "smotrich", "demand"))
	runner.check(seen == [0, 1, 2, 0, 1, 2, 0], "demands walk the variants in order: %s" % str(seen))
	runner.check(Coalition._variant(s, "smotrich", "threat") == 0 and Coalition._variant(s, "smotrich", "threat") == 0, "a line without variants is always 0")
	var l := GameState.from_dict(JSON.parse_string(JSON.stringify(s.to_dict())))
	runner.check(Coalition._variant(l, "smotrich", "demand") == 1, "the rotation survives a reload")
	Coalition.on_election(l)
	runner.check(Coalition._variant(l, "smotrich", "demand") == 2, "and an election (it is lifetime)")


func test_first_demand_is_variant_zero_then_the_rotation_continues() -> void:
	var first := str(Coalition.cfg()["firstPartner"])
	Coalition.partner(first)["linesVariants"] = {"demand": ["C1", "second", "third"]}
	var s := GameState.fresh()
	s.owned[_p1()] = 3
	s.bananas = 1000.0
	Coalition.open_group(s, Economy.derive(s))
	runner.check(int(Coalition.open_msg(s, first)["variant"]) == 0, "C1 is the deck's first bubble")
	runner.check(Coalition._variant(s, first, "demand") == 1, "the next demand is the second variant")


func test_gotliv_card_only_hides_in_the_blackout() -> void:
	# Designer ask (3): pollLike hides her card (it names a seat number), never her membership.
	var s := _with(["bengvir", "gotliv"], 300.0, 3, true)
	var seats := int(Coalition.seat_info(s)["effective"])
	var row: Dictionary = Coalition.roster(s).filter(func(r: Dictionary) -> bool: return r["id"] == "gotliv")[0]
	runner.check(not row["cardHidden"] and not Coalition.card_hidden(s, "gotliv"), "campaign: her card shows")
	s.calendar["mode"] = "blackout"
	row = Coalition.roster(s).filter(func(r: Dictionary) -> bool: return r["id"] == "gotliv")[0]
	runner.check(row["cardHidden"] and row["counts"] and row["status"] == "member", "blackout: card hidden, still a member who counts")
	runner.check(int(Coalition.seat_info(s)["effective"]) == seats, "her seats still count")
	runner.check(not Coalition.card_hidden(s, "bengvir"), "a partner without pollLike keeps his card")
	s.bananas = 1e9
	Coalition._post(s, {"type": "demand", "partner": "gotliv", "price": 5.0, "kind": "money", "join": false, "ageSec": 0.0,
		"state": "open", "line": "demand", "variant": 0}, [])
	runner.check(Coalition.pay(s, int(Coalition.open_msg(s, "gotliv")["seq"]))["ok"], "her bubbles and pills still work")
	Coalition.partner("gotliv")["copy"] = {"card": {"poll_like": false}}
	runner.check(not Coalition.card_hidden(s, "gotliv"), "a card that says poll_like: false wins")
	Coalition.partner("gotliv").erase("copy")
	s.calendar["mode"] = "negotiation"
	runner.check(not Coalition.card_hidden(s, "gotliv"), "after the polls close it shows again")

