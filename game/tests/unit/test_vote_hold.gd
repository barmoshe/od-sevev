extends RefCounted
## "The vote stops the clock" (Game Designer 2026-09-30, design/leader-select-spec.md §7.4):
## while the election card (O3) is open, Politics.tick(ctx.vote) holds the round. No ultimatum
## counts down or expires, no demand ages into one, no partner joins, no card fires or runs out,
## the court waits. The seats the player opened the card with are the seats they vote on.
## On the placeholder politics content (tests/fixtures/politics.json).

const PF := preload("res://tests/politics_fixture.gd")

var runner: Object


func setup(_r: Object) -> void:
	PF.install()


func teardown() -> void:
	PF.restore()


static func _one() -> float:
	return 0.999


static func _zero() -> float:
	return 0.0


func _with(members: Array) -> GameState:
	var s := GameState.fresh()
	s.coalition["opened"] = true
	s.stats["playtimeSec"] = 300.0
	s.coalition["paidLifetime"] = 3
	s.owned[Content.producer_ids()[0]] = 30
	for id: String in members:
		Coalition.ps(s, id)["status"] = "member"
	return s


func _politics(s: GameState, sec: float, vote: bool, rng: Callable = _one) -> Array:
	var out: Array = []
	var t := 0.0
	while t < sec - 1e-9:
		out.append_array(Politics.tick(s, 0.5, Economy.derive(s), {"vote": vote, "weekday": 2, "hour": 12}, rng))
		t += 0.5
	return out


func test_an_ultimatum_never_runs_out_under_the_open_card() -> void:
	var s := _with(["bengvir", "smotrich"])
	var m := Coalition._post(s, {"type": "ultimatum", "partner": "bengvir", "price": 200.0, "kind": "money", "leftSec": 1.0, "state": "open"}, [])
	var seats := int(Coalition.seat_info(s)["effective"])
	var ev := _politics(s, 600.0, true)
	runner.check(ev.is_empty(), "the held round posts nothing (%d events)" % ev.size())
	runner.check(m["state"] == "open" and is_equal_approx(float(m["leftSec"]), 1.0), "the ultimatum stands at 1 s for 10 minutes of the open card")
	runner.check(Coalition.status(s, "bengvir") == "member" and int(Coalition.seat_info(s)["effective"]) == seats, "nobody walks out under the card")
	_politics(s, 1.0, false)
	runner.check(m["state"] == "expired" and Coalition.status(s, "bengvir") == "left", "closed, the clock resumes where it stood: at 0 he leaves")


func test_nothing_ages_joins_or_transfers_under_the_card() -> void:
	var s := _with(["bengvir", "gotliv"])
	s.run_bananas = 1e9   # every partner unlocked: they'd join one per joinGapSec
	s.coalition["joinCooldownSec"] = 0.0
	s.coalition["nextDemandSec"] = 0.1
	var d := Coalition._post(s, {"type": "demand", "partner": "bengvir", "price": 10.0, "kind": "money", "join": false, "ageSec": 59.0, "state": "open"}, [])
	Coalition.ps(s, "gotliv")["meter"] = 99.0
	var chat := (s.coalition["chat"] as Array).size()
	_politics(s, 300.0, true)
	runner.check(is_equal_approx(float(d["ageSec"]), 59.0) and d["state"] == "open", "a waiting demand doesn't age into an ultimatum")
	runner.check((s.coalition["chat"] as Array).size() == chat, "no join, no new demand, no transfer banner")
	runner.check(is_equal_approx(float(Coalition.ps(s, "gotliv")["meter"]), 99.0) and Coalition.status(s, "gotliv") == "member", "Gotliv's meter stands still")


func test_cards_and_the_court_hold_under_the_card() -> void:
	var s := _with(["bengvir"])
	s.events["active"] = [{"type": "pledge", "gatePlus": 1, "baseAdd": 1, "leftSec": 0.5}, {"type": "seatDrain", "seats": 3, "leftSec": 0.5}]
	s.events["nextSec"] = 0.1
	Coalition.bench(s, "bengvir", 0.5)
	s.investigation["suspicion"] = 100.0
	s.investigation["phase"] = "summons"
	s.investigation["summonsSec"] = 29.5
	var before := Coalition.seat_info(s)
	var base := s.thumbs_owned
	_politics(s, 120.0, true, _zero)
	runner.check((s.events["active"] as Array).size() == 2 and s.thumbs_owned == base, "a live card neither runs out nor flips")
	runner.check(float(s.events["nextSec"]) > 0.0 and is_equal_approx(float(s.events["nextSec"]), 0.1), "no new card fires")
	runner.check(Coalition.seat_info(s) == before, "the seat line is the one the card opened on (%s)" % str(Coalition.seat_info(s)))
	runner.check(Investigation.phase(s) == "summons", "the summons waits: the court never starts behind the card")


func test_the_vote_flag_is_the_only_switch() -> void:
	runner.check(Politics.holds_for_vote({"vote": true}), "ctx.vote holds")
	runner.check(not Politics.holds_for_vote({}) and not Politics.holds_for_vote({"vote": false}), "no vote key: the round runs (the bench, every other modal)")
