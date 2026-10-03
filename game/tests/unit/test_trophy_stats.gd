extends RefCounted
## The designer's trophy stat keys (STATUS.md designer ask (c)): they start at 0 in
## GameState.fresh(), persist through from_dict, and the sim counts them where it sees the act.
## Also: the neverAwarded trophy never counts, the content-driven counters (countEvent,
## countUpgrade, countPartnerPaid), the night-tap and word-salad hooks, and the "מס׳ N" title.

const PF := preload("res://tests/politics_fixture.gd")

var runner: Object


func setup(_r: Object) -> void:
	PF.install()
	var list: Array = Content.data()["achievements"]["list"]
	list.append({"id": "t_lapid", "trigger": {"type": "stat", "key": "lapidCards", "value": 2, "countEvent": "lapid"}})
	list.append({"id": "t_gafni", "trigger": {"type": "stat", "key": "gafniPaid", "value": 1, "countPartnerPaid": "gafni"}})
	list.append({"id": "t_plane", "trigger": {"type": "stat", "key": "wingOfZionBought", "value": 1, "countUpgrade": "glove"}})
	list.append({"id": "t_gantz", "trigger": {"type": "never"}, "neverAwarded": true, "fakeProgress": 0.99})


func teardown() -> void:
	PF.restore()


func _stat(s: GameState, k: String) -> float:
	return float(s.stats.get(k, -1.0))


func _group(s: GameState) -> void:
	s.owned[Content.producer_ids()[0]] = 3
	s.money = 1e9
	Coalition.open_group(s, Economy.derive(s))


func test_every_key_starts_at_zero_and_persists() -> void:
	var s := GameState.fresh()
	for k: String in Meta.STATS:
		runner.check(s.stats.has(k) and _stat(s, k) == 0.0, "fresh() has %s = 0" % k)
	s.stats["lapidCards"] = 7.0
	s.stats["bestTapFrenzyTaps"] = 42.0   # an engine counter fresh() doesn't know
	var raw := s.to_dict()
	raw["stats"]["evil key!"] = 5
	raw["stats"]["negative"] = -3
	var l := GameState.from_dict(JSON.parse_string(JSON.stringify(raw)))
	runner.check(_stat(l, "lapidCards") == 7.0, "a trophy stat survives a reload")
	runner.check(_stat(l, "bestTapFrenzyTaps") == 42.0, "so does an engine counter")
	runner.check(not l.stats.has("evil key!") and not l.stats.has("negative"), "junk keys and negative numbers are dropped")


func test_coalition_counts() -> void:
	var s := GameState.fresh()
	_group(s)
	var first := str(Coalition.cfg()["firstPartner"])
	Coalition.pay(s, int(Coalition.open_msg(s, first)["seq"]))
	runner.check(_stat(s, "partnersPaid") == 1.0 and _stat(s, "demandsPaid") == 1.0, "C1 paid: partnersPaid 1, demandsPaid 1")
	Coalition._post(s, {"type": "demand", "partner": first, "price": 5.0, "kind": "money", "join": false, "ageSec": 0.0,
		"state": "open", "line": "demand", "variant": 0}, [])
	Coalition.pay(s, int(Coalition.open_msg(s, first)["seq"]))
	runner.check(_stat(s, "partnersPaid") == 1.0 and _stat(s, "demandsPaid") == 2.0, "a member's demand: demandsPaid only")
	Coalition.ps(s, "gafni")["status"] = "pending"
	Coalition._post(s, {"type": "demand", "partner": "gafni", "price": 5.0, "kind": "money", "join": true, "ageSec": 0.0,
		"state": "open", "line": "demand", "variant": 0}, [])
	Coalition.pay(s, int(Coalition.open_msg(s, "gafni")["seq"]))
	runner.check(_stat(s, "gafniPaid") == 1.0 and _stat(s, "partnersPaid") == 2.0, "countPartnerPaid: gafniPaid")
	Coalition.ps(s, "smotrich")["status"] = "member"
	Coalition.ps(s, "amsalem")["status"] = "member"
	Coalition.start_brawl(s, "smotrich", "amsalem")
	Coalition.resolve_brawl(s, int(Coalition.open_brawl(s)["seq"]))
	runner.check(_stat(s, "brawlsEnded") == 1.0, "'צאו החוצה': brawlsEnded")
	Coalition.on_chat_opened(s, func() -> float: return 0.0)
	runner.check(_stat(s, "corridorMessages") == float(s.coalition["corridorMsgs"]) and _stat(s, "corridorMessages") > 0.0,
		"the corridor counter mirrors into corridorMessages")


func test_court_counts() -> void:
	var s := GameState.fresh()
	s.investigation["phase"] = "summons"
	Investigation.testify(s)
	runner.check(_stat(s, "courtDays") == 1.0, "courtDays")
	s.investigation["phase"] = "summons"
	for i in 3:
		s.money = 1e9
		s.investigation["phase"] = "summons"
		Investigation.postpone(s, Economy.derive(s))
	runner.check(_stat(s, "maxPostponesInRound") == 3.0, "maxPostponesInRound 3")
	Investigation.on_election(s)
	s.money = 1e9
	s.investigation["phase"] = "summons"
	Investigation.postpone(s, Economy.derive(s))
	runner.check(_stat(s, "maxPostponesInRound") == 3.0, "a smaller round never lowers the max")
	Investigation.request_pardon(s)
	Investigation.request_pardon(s)
	runner.check(_stat(s, "pardonRequests") == 2.0, "pardonRequests")
	s.investigation["aideHolding"] = 10.0
	Investigation.drop_aide(s)
	runner.check(_stat(s, "aideDrops") == 1.0, "aideDrops")


func test_content_driven_counters() -> void:
	var s := GameState.fresh()
	var d := Economy.derive(s)
	Events.fire(s, "lapid", d)
	Events.fire(s, "liberman", d)
	Events.fire(s, "lapid", d)
	runner.check(_stat(s, "lapidCards") == 2.0, "countEvent: lapidCards counts Lapid's card only")
	s.run_money = 1e6
	s.money = 1e6
	Economy.buy_upgrade(s, "glove")
	runner.check(_stat(s, "wingOfZionBought") == 1.0, "countUpgrade: wingOfZionBought")
	runner.check(Meta.check_achievements(s, Economy.derive(s)).has("t_lapid"), "and the trophy reads the stat")


func test_round_stats() -> void:
	var s := GameState.fresh()
	var shady: String = Investigation.cfg()["sources"].keys()[0]
	for i in 5:
		Meta.on_round_end(s, 200.0)
	runner.check(_stat(s, "cleanRounds") == 5.0, "five clean rounds")
	runner.check(_stat(s, "streakRoundsUnder240s") == 5.0, "five in a row under 4 minutes")
	s.owned[shady] = 1
	Meta.on_round_end(s, 300.0)
	runner.check(_stat(s, "cleanRounds") == 5.0, "a shady source makes the round dirty")
	Meta.on_round_end(s, 100.0)
	runner.check(_stat(s, "streakRoundsUnder240s") == 5.0 and _stat(s, "streakUnder240sNow") == 1.0, "a slow round restarts the streak; the best stays")


func test_night_taps_and_word_salad() -> void:
	var s := GameState.fresh()
	var d := Economy.derive(s)
	Politics.tick(s, 0.1, d, {"hour": 3, "allowPing": false})
	for i in 4:
		Economy.tap(s, func() -> float: return 0.999)
	Politics.tick(s, 0.1, d, {"hour": 3, "allowPing": false})
	runner.check(_stat(s, "tapsAt2to4") == 4.0, "taps at 03:00 count")
	Economy.tap(s, func() -> float: return 0.999)
	Politics.tick(s, 0.1, d, {"hour": 4, "allowPing": false})
	runner.check(_stat(s, "tapsAt2to4") == 4.0, "at 04:00 they don't")
	var night := Calendar.parse_utc_ms("2026-10-01T23:30:00Z")   # 02:30 in Israel (UTC+3)
	Economy.tap(s, func() -> float: return 0.999)
	Politics.tick(s, 0.1, d, {"nowMs": night, "allowPing": false})
	runner.check(_stat(s, "tapsAt2to4") == 5.0, "without ctx.hour the Israel clock from nowMs decides")
	Content.data()["dubi"] = {"wordSalad": {"when": {"evolutionsAtLeast": 1}, "chance": 0.5}}
	runner.check(not Story.roll_word_salad(s, func() -> float: return 0.0), "not before its condition")
	s.evolutions = 1
	runner.check(not Story.roll_word_salad(s, func() -> float: return 0.9), "a miss")
	runner.check(Story.roll_word_salad(s, func() -> float: return 0.1) and _stat(s, "wordSaladSeen") == 1.0, "a salad counts wordSaladSeen")
	var salad := Story.word_salad(["אין כלום!", "לא ידענו!", "ציד מכשפות!"], func() -> float: return 0.3)
	var words := Array(salad.replace("!", "").split(" "))
	words.sort()
	var want := ["אין", "כלום", "לא", "ידענו", "ציד", "מכשפות"]
	want.sort()
	runner.check(words == want and salad.ends_with("!"), "the salad is his words, shuffled: %s" % salad)


func test_never_awarded_never_counts() -> void:
	var s := GameState.fresh()
	var d := Economy.derive(s)
	Meta.check_achievements(s, d)
	runner.check(not s.achievements.has("t_gantz"), "Gantz's rotation is never awarded")
	s.achievements.append("t_gantz")   # a hand-edited save
	runner.check(Meta.trophy_count(s) == s.achievements.size() - 1, "and never counts toward trophiesAtLeast or the bonus")
	_eq_mult(s)


func _eq_mult(s: GameState) -> void:
	var want := 1.0 + Meta.achievement_pct(s) * (s.achievements.size() - 1)
	runner.check(is_equal_approx(Meta.morale_mult(s), want), "the trophy bonus skips it")


func test_old_save_seeds_the_lifetime_stats() -> void:
	var s := GameState.fresh()
	s.coalition["paidLifetime"] = 12
	s.investigation["courtDays"] = 3
	s.investigation["aideDrops"] = 2
	s.investigation["pardons"] = 4
	s.coalition["corridorMsgs"] = 77
	var raw := s.to_dict()
	raw.erase("stats")
	var l := GameState.from_dict(raw)
	runner.check(_stat(l, "demandsPaid") == 12.0 and _stat(l, "courtDays") == 3.0 and _stat(l, "aideDrops") == 2.0
		and _stat(l, "pardonRequests") == 4.0 and _stat(l, "corridorMessages") == 77.0, "seeded from the modules' counters")
	runner.check(_stat(l, "partnersPaid") >= 1.0, "partnersPaid seeded (the first-partner headline stays earned)")


func test_species_title_numbers_in_hebrew() -> void:
	Content.load_from(Content.PATH)
	var titles: Array = Content.data()["prestige"]["speciesTitles"]
	var last := titles.size() - 1
	runner.check(Content.species_title(0) == titles[0], "round 1: the first title")
	runner.check(Content.species_title(last) == "%s מס׳ 1" % titles[last], "the last title gets ' מס׳ 1': %s" % Content.species_title(last))
	runner.check(Content.species_title(last + 2) == "%s מס׳ 3" % titles[last], "and counts up")
	runner.check(not Content.species_title(last).contains("Mk"), "no 'Mk' left")
