extends RefCounted
## Leader select, the sim slice (design/leader-select-spec.md §9.6): the round's install per leader,
## the deal, the knobs (partnerThreatMult, declineDemand, selfEvent), the filters (spins, the
## Suitcase, the court vs the press, story, ambient), the Meta stats and trophies, the fresh-face
## bonus and save v4 (migration from v3). Runs on the shipped design content (res://data/).

var runner: Object
var dir := ""


func setup(_r: Object) -> void:
	TestFixture.use_game_content()
	dir = "user://test_leaders_%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(dir)


func teardown() -> void:
	var d := DirAccess.open(dir)
	if d:
		for f in d.get_files():
			d.remove(f)
	DirAccess.remove_absolute(dir)
	TestFixture.use_game_content()


func _round(id: String, salt: int = 3) -> GameState:
	var s := GameState.fresh()
	Leaders.set_salt(s, salt)
	var r := Politics.install(s, id)
	runner.check(r.get("ok", false) == true, "start_round(%s) ok: %s" % [id, str(r)])
	return s


func _ids(arr: Array) -> Array:
	return arr.map(func(p: Dictionary) -> String: return str(p["id"]))


func _p(id: String) -> Dictionary:
	return Coalition.partner(id)


## The engine's reads for a member row / a demand without running the whole chat.
func _member(s: GameState, id: String) -> void:
	Coalition.ps(s, id)["status"] = "member"


func _demand(s: GameState, id: String, join: bool = false) -> int:
	var m := Coalition._post(s, {"type": "demand", "partner": id, "price": 50.0, "kind": "money", "join": join,
		"ageSec": 0.0, "state": "open", "line": "demand", "variant": 0}, [])
	return int(m["seq"])


# ---------------------------------------------------------------------------------------------
# The default round and the picker
# ---------------------------------------------------------------------------------------------

func test_new_game_is_bibis_round_with_the_picker_open() -> void:
	runner.check(Leaders.active() and Leaders.default_leader() == "bibi", "the content has leader select, default bibi")
	var s := GameState.fresh()
	Economy.derive(s)
	runner.check(Leaders.current(s) == "bibi" and Leaders.pick_pending(s), "a new game: Bibi's round, the picker open")
	runner.check(is_same(Coalition.partners(), Content.data()["partners"]), "Bibi's round plays the shipped partners list")
	runner.check(is_same(Events.list(), Content.data()["events"]), "and the shipped events list")
	runner.check(Coalition.first_partner() == "bengvir", "C1 is Ben Gvir")
	runner.check(Leaders.stat(s, "bibi", "rounds") == 1.0 and s.leader_history == PackedStringArray(["bibi"]), "round 1 booked")
	Economy.tap(s)
	runner.check(not Leaders.pick_pending(s) and not Leaders.can_repick(s), "the first tap closes the picker")
	runner.check(Politics.install(s, "bennett").get("reason", "") == "started", "no pick once the round has started")
	runner.check(Leaders.stat(s, "bibi", "taps") == 1.0, "the tap is booked to Bibi")


func test_picker_lists_the_ready_leaders_without_numbers() -> void:
	var s := GameState.fresh()
	var ids := Leaders.pickable()
	runner.check(ids == PackedStringArray(["bibi", "bennett", "bengvir", "liberman", "eisenkot", "smotrich", "deri", "golan"]), "all 8 pickable (%s)" % str(ids))
	runner.check(not Leaders.playable("lapid") and not Leaders.playable("gantz"), "a partner who isn't a leader is not")
	var i := 0
	var seq := [0.9, 0.1, 0.5, 0.3]
	var p := Leaders.picker(s, func() -> float:
		i += 1
		return seq[i % seq.size()])
	var tiles: Array = p["tiles"]
	runner.check(tiles.size() == 8 and p["again"] == "" and p["first"] == true, "8 tiles, no 'again' on a new game")
	for t: Dictionary in tiles:
		runner.check(str(t["blurb"]) != "" and not t.has("seats"), "tile %s: blurb, no numbers" % t["id"])
		runner.check(str(t["ruleName"]) != "" and str(t["ruleText"]) != "", "tile %s: its one-line rule (Bibi's too)" % t["id"])
	runner.check(ids.has(Leaders.random_pick(func() -> float: return 0.99)), "הפתעה picks a tile")


# ---------------------------------------------------------------------------------------------
# install per leader
# ---------------------------------------------------------------------------------------------

func test_install_bennett() -> void:
	var s := _round("bennett")
	var ids := _ids(Coalition.partners())
	var want := ["liberman", "lapid", "eisenkot", "golan", "mk_offer", "abbas", "mk_undecided", "gafni", "mk_switcher", "gantz"]
	for id: String in want:
		runner.check(ids.has(id), "bennett's lineup has %s" % id)
	runner.check(ids.size() == want.size() and not ids.has("bengvir") and not ids.has("bennett"), "nobody else, never the leader")
	runner.check(Coalition.first_partner() == "liberman" and str(_p("liberman")["slot"]) == "S1" and int(_p("liberman")["seats"]) == 12, "C1: Liberman on S1 (12 seats)")
	runner.check(_p("lapid").get("cannotLeave") == true and float(_p("lapid")["threatChance"]) == 0.0, "Lapid (list No. 2) can't walk out")
	runner.check(float(_p("lapid").get("onPay", {}).get("suspicion", 0)) == 2.0, "Lapid's trait: paying him draws heat")
	var gafni := _p("gafni")
	var slot: Dictionary = Leaders.slots()[str(gafni["slot"])]
	runner.check(int(gafni["seats"]) == 0 and int(gafni["abstain"]) == int(slot["seats"]), "Gafni turns his slot's seats into abstentions")
	runner.check(str(_p("gantz")["slot"]) == "SI" and _p("gantz").get("standIn") == true, "Gantz stays the stand-in")
	runner.check((_p("liberman")["excludes"] as Array).has("gafni"), "Liberman's excludes ride along (the real choice)")
	runner.check(not (_p("liberman")["excludes"] as Array).has("abbas"), "but not Abbas: they sat together in 2021 (fact raam-2021)")
	runner.check(str(_p("abbas").get("lines", {}).get("thanks", "")).begins_with("כמו ב־2021"), "a lineup line override")
	var ev := _ids(Events.list())
	for id: String in ["card_bibi", "card_bengvir", "card_smotrich", "card_deri", "bennett", "leak", "brawl"]:
		runner.check(ev.has(id), "bennett's cards include %s" % id)
	for id: String in ["lapid", "eisenkot", "liberman", "golan", "pardon", "kaia", "pinkfront", "defector"]:
		runner.check(not ev.has(id), "bennett's cards exclude %s" % id)
	runner.check(str(Events.event("card_bibi")["side"]) == "rival", "a coalition-side card is a rival")
	var own := Events.event("bennett")
	runner.check(str(own["side"]) == "self" and float(own["weight"]) == 4.0, "his own pledge card: side self, weight ×2")
	runner.check(float(own["when"]["runSecAtLeast"]) == 240.0 and int(own["when"]["seatsBelow"]) == 61, "first after 4:00 of the round, never with the gate met")
	var leak := Events.event("leak")
	runner.check(str(leak.get("skin", "")) == "leakRight" and int(leak["effect"]["leaks"]) == 2, "the leak is the coalition's screenshot")
	runner.check(not Leaders.leak_copy(s).is_empty(), "leak_copy for the view")


func test_install_bengvir() -> void:
	var s := _round("bengvir")
	var ids := _ids(Coalition.partners())
	runner.check(Coalition.first_partner() == "bibi" and ids[0] == "bibi", "C1: Bibi on S1")
	runner.check(not ids.has("abbas") and not ids.has("bengvir"), "Abbas is out, and the leader")
	var g := _p("gotliv")
	runner.check(not g.has("transfer") and g.get("cannotLeave") == true and str(g["lines"]["status"]).begins_with("במקום השני"), "Gotliv: no transfer, can't leave, her status line")
	var almog := _p("almog")
	runner.check(str(almog["lines"]["demand"]).begins_with("הוסרתי") and not (almog["linesVariants"] as Dictionary).has("demand"), "an overridden line drops its variants")
	var ev := _ids(Events.list())
	for id: String in ["lapid", "eisenkot", "liberman", "bennett", "golan"]:
		runner.check(ev.has(id), "the shipped opposition card %s is his rival" % id)
	runner.check(str(Events.event("bennett")["side"]) == "opposition" and not Events.event("leak").has("skin"), "rival pledge, the shipped leak")
	runner.check(is_equal_approx(Leaders.threat_mult(), 0.5), "partnerThreatMult 0.5")
	runner.check(s.leader == "bengvir", "the round is his")


## Spec §7.2.2: in Bennett's round a pill never trades Liberman's 12 seats away. Before, Gafni's
## (or Abbas's) join demand came while Liberman sat, and paying it threw him out with no pill.
func test_bennett_round_never_trades_liberman_away() -> void:
	var s := _round("bennett", 2)   # this deal has Gafni and Abbas in round 1
	s.run_bananas = 1e9
	s.run_time_sec = 900.0
	s.stats["playtimeSec"] = 900.0
	s.coalition["opened"] = true
	s.coalition["nextDemandSec"] = 1e12
	_member(s, "liberman")
	for i in 200:
		Coalition.tick(s, 1.0, Economy.derive(s), {}, func() -> float: return 0.5)
	runner.check(Coalition.status(s, "gafni") == "absent", "Gafni never asks while Liberman sits (the bigger side first)")
	runner.check(Coalition.status(s, "abbas") != "absent", "Abbas asks and sits with him, as in 2021 (%s)" % Coalition.status(s, "abbas"))
	# Liberman walks (an ultimatum ran out): now Gafni asks, next to Liberman's rejoin pill
	Coalition._leave(s, "liberman", 10.0, [])
	for i in 60:
		Coalition.tick(s, 1.0, Economy.derive(s), {}, func() -> float: return 0.5)
	runner.check(Coalition.status(s, "gafni") == "pending", "Liberman out: Gafni asks (%s)" % Coalition.status(s, "gafni"))
	var g := Coalition.open_msg(s, "gafni")
	s.bananas = 1e12
	Coalition.pay(s, int(g["seq"]))
	var pill := Coalition.open_msg(s, "liberman")
	runner.check(Coalition.status(s, "gafni") == "member" and str(pill.get("payable", "")) == "rejoin", "paying Gafni keeps Liberman's rejoin pill open (the bigger side's offer stays)")
	Coalition.pay(s, int(pill["seq"]))
	runner.check(Coalition.status(s, "liberman") == "member" and Coalition.status(s, "gafni") == "absent", "paying Liberman's pill brings him back and Gafni goes: they never sit together")


func test_install_liberman() -> void:
	_round("liberman")
	var ids := _ids(Coalition.partners())
	runner.check(Coalition.first_partner() == "bennett", "C1: Bennett")
	for x: String in ["bibi", "deri", "goldknopf", "gafni", "abbas"]:
		runner.check(not ids.has(x), "Liberman doesn't sit with %s" % x)
	var cap := 0
	for p: Dictionary in Coalition.partners():
		cap += int(Leaders.slots()[str(p["slot"])]["seats"])
	runner.check(cap == 46, "his capacity 46 (mk_offer on L4 and a generic MK on SK, the bench levers; got %d)" % cap)
	runner.check(ids.has("mk_returner") and not Conditions.ok(GameState.fresh(), Leaders.slots()["SK"]["unlock"]), "SK waits for election 1, so round 1 plays on 44")
	runner.check(not Leaders.decline_rule().is_empty(), "his rule: declineDemand")


func test_deal_keeps_s1_and_si_and_permutes_the_rest() -> void:
	for id: String in ["bennett", "bengvir", "liberman"]:
		var lineup: Array = Leaders.leader(id)["coalition"]["lineup"]
		var want: Array = lineup.map(func(m: Dictionary) -> String: return str(m["slot"]))
		want.sort()
		var moved := false
		for salt in range(1, 9):
			var d := Leaders.deal(id, salt * 101)
			var got: Array = d.values()
			got.sort()
			runner.check(got == want, "%s salt %d: a permutation of the lineup's slots" % [id, salt])
			for m: Dictionary in lineup:
				if ["S1", "SI"].has(str(m["slot"])):
					runner.check(d[m["id"]] == m["slot"], "%s: %s keeps %s" % [id, m["id"], m["slot"]])
				elif d[m["id"]] != m["slot"]:
					moved = true
		runner.check(moved, "%s: seats are reshuffled (never read as polls)" % id)
	runner.check(Leaders.deal("bibi", 5).is_empty(), "Bibi's lineup ships unshuffled (the shipped list)")
	runner.check(Leaders.deal("bennett", 77) == Leaders.deal("bennett", 77), "the same seed deals the same")


func test_reload_keeps_the_deal_and_rejects_a_forged_one() -> void:
	var s := _round("bennett", 12345)
	var before := JSON.stringify(s.seat_deal, "", true)
	var st := SaveStore.new(dir)
	st.save_game(s, 1.0)
	var l: GameState = st.load_game()["state"]
	runner.check(JSON.stringify(l.seat_deal, "", true) == before and l.leader == "bennett", "the deal survives a reload")
	Economy.derive(l)
	runner.check(JSON.stringify(_ids(Coalition.partners())) == JSON.stringify(_ids(Leaders.build_roster("bennett", s.seat_deal))), "same roster after load")
	var raw := s.to_dict()
	raw["seatDeal"]["lapid"] = "S1"   # two S1s: a forged 12-seat slot
	var f := GameState.from_dict(JSON.parse_string(JSON.stringify(raw)))
	var s1 := 0
	for k: Variant in f.seat_deal:
		if f.seat_deal[k] == "S1":
			s1 += 1
	runner.check(s1 == 1, "a forged deal is re-dealt")


# ---------------------------------------------------------------------------------------------
# Knobs
# ---------------------------------------------------------------------------------------------

## A member's random demand at a fixed roll of 0.4: Bibi's partners' S1 (0.6) threatens, Ben Gvir's
## halved (0.3) doesn't.
func _roll_at(id: String, member: String) -> String:
	var s := _round(id)
	var d := Economy.derive(s)
	s.coalition["opened"] = true
	s.coalition["paidLifetime"] = 5
	s.stats["playtimeSec"] = 400.0
	s.coalition["nextDemandSec"] = 0.01
	for p: Dictionary in Coalition.partners():
		if str(p["id"]) != member:
			Coalition.ps(s, p["id"])["status"] = "absent"
	_member(s, member)
	var out: Array = []
	Coalition._tick_demands(s, 0.1, d, func() -> float: return 0.4, out)
	for e: Dictionary in out:
		if e["ev"] == "message":
			return str(e["msg"]["type"])
	return ""


func test_partner_threat_mult() -> void:
	runner.check(_roll_at("bibi", "bengvir") == "ultimatum", "Bibi's round: 0.6 > 0.4 → an ultimatum")
	runner.check(_roll_at("bengvir", "bibi") == "demand", "Ben Gvir's round: 0.6 × 0.5 = 0.3 < 0.4 → a demand")
	_round("bibi")
	runner.check(Leaders.threat_mult() == 1.0, "no knob outside his round")


func test_decline_demand() -> void:
	var s := _round("liberman")
	s.coalition["opened"] = true
	_member(s, "bennett")
	_member(s, "lapid")
	var seq := _demand(s, "bennett")
	runner.check(Coalition.decline_cooldown(s) == 0.0 and Coalition.can_decline(s, seq), "a member demand can be declined")
	var r := Coalition.decline(s, seq)
	runner.check(r["ok"] == true and Coalition.message(s, seq)["state"] == "declined", "declined: closed for free")
	runner.check(Coalition.status(s, "bennett") == "member", "the partner stays")
	runner.check(str((r["events"] as Array)[0]["msg"]["key"]) == "chat.sys.declined", "sys line chat.sys.declined")
	runner.check(Leaders.stat(s, "liberman", "declines") == 1.0, "counted for his trophy")
	var seq2 := _demand(s, "lapid")
	runner.check(Coalition.decline(s, seq2)["reason"] == "cooldown" and is_equal_approx(Coalition.decline_cooldown(s), 90.0), "one per 90 s")
	Coalition.tick(s, 91.0, Economy.derive(s), {"allowPing": false}, func() -> float: return 0.99)
	runner.check(Coalition.can_decline(s, seq2), "ready again after the cooldown")
	var join := _demand(s, "golan", true)
	Coalition.ps(s, "golan")["status"] = "pending"
	runner.check(not Coalition.can_decline(s, join), "never a join demand")
	var ult := Coalition._post(s, {"type": "ultimatum", "partner": "eisenkot", "price": 9.0, "leftSec": 90.0, "state": "open"}, [])
	_member(s, "eisenkot")
	runner.check(not Coalition.can_decline(s, int(ult["seq"])), "never an ultimatum")
	var b := _round("bibi")
	b.coalition["opened"] = true
	_member(b, "bengvir")
	runner.check(Coalition.decline(b, _demand(b, "bengvir"))["reason"] == "rule" and Coalition.decline_cooldown(b) == -1.0, "only in Liberman's round")


func test_self_event_is_his_own_card() -> void:
	var s := _round("bennett")
	var own := Events.event("bennett")
	s.run_time_sec = 100.0
	runner.check(not Events.eligible(s, own), "not before 4:00 of the round")
	s.run_time_sec = 250.0
	runner.check(Events.eligible(s, own), "his pledge card is live from 4:00")
	s.upgrades.append("s05")   # ציד מכשפות: base per rival card
	var base := s.thumbs_owned
	var d := Economy.derive(s)
	var r := Events.fire(s, "bennett", d)
	runner.check(str(r["side"]) == "self" and s.thumbs_owned == base, "his own card is no rival: no s05 base")
	runner.check(Events.gate_plus(s) == 1, "the gate goes to 62 while it's up")
	Events.fire(s, "card_bibi", d)
	runner.check(s.thumbs_owned == base + 1, "a rival card pays s05's base (spin slot I)")


# ---------------------------------------------------------------------------------------------
# Filters
# ---------------------------------------------------------------------------------------------

func test_spin_shelf_per_leader() -> void:
	var b := _round("bibi")
	b.run_bananas = 60000.0
	b.evolutions = 1
	runner.check(Spins.on_shelf(b, Content.upgrade("s07")) and Economy.upgrade_unlocked(b, Content.upgrade("s07")), "Bibi: s07 on the shelf")
	runner.check(Spins.on_shelf(b, Content.upgrade("s08")), "Bibi: s08 as shipped")
	var s := _round("bennett")
	for id: String in ["s07", "s09", "s10", "s14", "s15"]:
		runner.check(not Spins.on_shelf(s, Content.upgrade(id)), "Bennett: Bibi's %s is off the shelf" % id)
	for id: String in ["s01", "s02", "s03", "s04", "s05", "s06", "s11", "s12", "s13"]:
		runner.check(Spins.on_shelf(s, Content.upgrade(id)), "Bennett: slot spin %s is on the shelf" % id)
	runner.check(not Spins.on_shelf(s, Content.upgrade("s08")), "no Karhi in his lineup: no s08")
	var g := _round("bengvir")
	runner.check(not Spins.on_shelf(g, Content.upgrade("s08")), "Ben Gvir: s08 waits for Karhi")
	_member(g, "karhi")
	runner.check(Spins.on_shelf(g, Content.upgrade("s08")), "Karhi a member: s08 is on the shelf")
	runner.check(Leaders.spin_skin("bennett", "s01")["name"] == "טוש עבה" and Leaders.spin_skin("bennett", "s12").is_empty(), "skins: A skinned, F shared as is")
	runner.check(str(Leaders.spin_skin("bennett", "s02").get("icon", "")) == "spin_slot_B", "the icon falls back to spin_slot_<slot>")


func test_skinned_g_has_no_invoice() -> void:
	for id: String in ["bibi", "bennett"]:
		var s := _round(id)
		s.evolutions = 2
		s.bananas = 2e6
		s.run_bananas = 2e6
		runner.check(Economy.buy_upgrade(s, "s13"), "%s buys s13" % id)
		var fu := (s.events["followUps"] as Array).size()
		runner.check(fu == (1 if id == "bibi" else 0), "%s: s13's next-morning invoice is Bibi's only (%d)" % [id, fu])


func test_suitcase_outcomes() -> void:
	var outs: Array = Content.data()["golden"]["outcomes"]
	_round("bibi")
	runner.check(Leaders.filter_outcomes(outs) == outs, "Bibi: the shipped outcomes")
	var s := _round("bennett")
	var f := Leaders.filter_outcomes(outs)
	var ids := _ids(f)
	var total := 0.0
	var cash := 0.0
	for o: Dictionary in f:
		total += float(o["weight"])
		if o["id"] == "cash":
			cash = float(o["weight"])
	runner.check(not ids.has("aide") and not ids.has("laundry"), "no aide, no laundry")
	runner.check(is_equal_approx(total, 1.1) and is_equal_approx(cash, 0.7), "cash takes their weight (0.45 + 0.15 + 0.1; the pool keeps its total)")
	s.golden_caught_lifetime = 3
	s.evolutions = 6   # Washington: the laundry would roll for Bibi
	var seen := {}
	for i in 200:
		var x := float(i) / 200.0
		seen[Economy.roll_golden_outcome(func() -> float: return x, s)] = true
	runner.check(not seen.has("aide") and not seen.has("laundry") and seen.has("cash"), "the roll never lands on them (%s)" % str(seen.keys()))
	runner.check(Leaders.suitcase("bennett")["sprite"] == "suitcase_plain" and Leaders.suitcase("bibi")["sticker"] == true, "DOHA is Bibi's")


func test_court_is_bibis_and_the_press_everyone_elses() -> void:
	var b := _round("bibi")
	b.investigation["aideHolding"] = 100.0
	runner.check(Investigation.can_drop_aide(b) and Investigation.skin(b)["skin"] == "court", "Bibi: the court and the aide")
	var s := _round("bennett")
	s.investigation["aideHolding"] = 100.0
	runner.check(not Investigation.can_drop_aide(s) and not Investigation.drop_aide(s), "no aide drop outside his round")
	runner.check(Investigation.request_pardon(s) == 0 and float(s.stats.get("pardonRequests", 0.0)) == 0.0, "no pardon desk")
	var sk := Investigation.skin(s)
	runner.check(sk["skin"] == "press" and sk["meterName"] == "כותרות" and sk["testifyVerb"] == "להגיב", "the press skin")
	runner.check((sk["excuses"] as Array).size() == 6 and str(sk["postponeVerb"]) != "", "his postpone verb and 6 excuses")


func test_story_follows_the_leader_just_played() -> void:
	var s := _round("bennett")
	Meta.on_round_end(s, 400.0)   # the election, as Economy.evolve does it
	s.evolutions += 1
	Politics.on_election(s)
	var f := Story.flash(s)
	var beats: Array = Leaders.kit("bennett")["story"]["beats"]
	runner.check(f["leader"] == "bennett" and f["n"] == 1 and Array(f["lines"]) == beats[0] and f["id"] == "beat_bennett_1", "Bennett's first beat by HIS election count")
	runner.check(str(f["title"]) == str(Leaders.kit("bennett")["story"]["titles"][0]), "his title")
	s.leaders["bennett"]["elections"] = float(beats.size() + 1)
	runner.check(Array(Story.flash(s)["lines"]) == Array(Content.data()["story"]["encore"]), "after his %d beats: the shared encore" % beats.size())
	var b := _round("bibi")
	Meta.on_round_end(b, 400.0)
	b.evolutions += 1
	Politics.on_election(b)
	runner.check(Story.flash(b)["id"] == "beat_1" and Array(Story.flash(b)["lines"]) == Array(Story.beat_for(1)), "Bibi's flash is the shipped beat")


func test_ambient_and_headlines_per_leader() -> void:
	var b := _round("bibi")
	var v2: Dictionary = Content.data()["ambientHeadlinesV2"]
	runner.check(Leaders.ambient(b).size() == (v2["list"] as Array).size() + (v2["listPolitics"] as Array).size(), "Bibi: every shipped line")
	var s := _round("bennett")
	var ids := _ids(Leaders.ambient(s))
	runner.check(not ids.has("g02") and not ids.has("c02") and ids.has("g01"), "bibiOnly lines out, shared in")
	runner.check(ids.has("tb01") and ids.has("r01") and ids.has("r03"), "his ticker and the rival ticker (Bibi, Ben Gvir are rivals)")
	var g := _round("bengvir")
	var gids := _ids(Leaders.ambient(g))
	runner.check(gids.has("tg01") or gids.any(func(x: String) -> bool: return x.begins_with("t")), "Ben Gvir's own ticker")
	runner.check(not gids.has("r01") and not gids.has("r03"), "no rival ticker about the coalition in a coalition leader's round")
	var lib := _ids(Leaders.ambient(_round("liberman")))
	runner.check(not lib.has("x04") and not lib.has("x18") and lib.has("x09"), "a roast aimed at Liberman skips his own round; Lapid's stays")
	runner.check(not lib.has("x14") and not lib.has("x21"), "'the opposition' lines skip an opposition leader's round (it is his bloc)")
	runner.check(not ids.has("x02") and ids.has("x04"), "Bennett's round drops the Bennett roast, keeps Liberman's")
	runner.check(gids.has("x14") and gids.has("x04"), "a coalition leader's round keeps the opposition roasts")
	var hl := _ids(Leaders.headlines(s))
	runner.check(not hl.has("h_first_tap") and hl.has("hb_first_tap") and hl.has("hb_t5"), "his headlines replace Bibi's")
	var h: Dictionary = Leaders.headlines(s).filter(func(x: Dictionary) -> bool: return x["id"] == "hb_first_tap")[0]
	runner.check(Leaders.headline_hit(s, h["trigger"]) == false, "not before his first tap")
	Economy.tap(s)
	runner.check(Leaders.headline_hit(s, h["trigger"]) == true, "his first tap")


# ---------------------------------------------------------------------------------------------
# Meta: stats, trophies, the switch bonus
# ---------------------------------------------------------------------------------------------

func _elect(s: GameState) -> void:
	Meta.on_round_end(s, 420.0)
	s.evolutions += 1
	Economy.reset_run(s)
	Politics.on_election(s)


func test_fresh_face_bonus_and_switches() -> void:
	var s := _round("bibi")
	_elect(s)
	runner.check(Leaders.pick_pending(s) and Leaders.current(s) == "bibi", "after the election: same leader, picker open")
	var d0 := Economy.derive(s).base_pct_round
	var r := Politics.install(s, "bennett")
	runner.check(r["fresh"] == true and is_equal_approx(float(r["freshPct"]), 10.0), "a new face: +10%")
	runner.check(is_equal_approx(Economy.derive(s).base_pct_round, d0 + 10.0), "on this round's base payout")
	runner.check(float(s.stats["leaderSwitches"]) == 1.0 and Leaders.stat(s, "bennett", "rounds") == 1.0 and Leaders.stat(s, "bibi", "rounds") == 1.0, "a switch; the auto round undone")
	Politics.install(s, "bibi")   # the 5 s undo: back to the same leader
	runner.check(float(s.stats["leaderSwitches"]) == 0.0 and not s.leader_round["fresh"] and Leaders.stat(s, "bennett", "rounds") == 0.0, "undo: no switch, no bonus")
	runner.check(is_equal_approx(Economy.derive(s).base_pct_round, d0), "the bonus is gone")
	Politics.install(s, "bennett")
	Politics.install(s, "bennett")
	runner.check(float(s.stats["leaderSwitches"]) == 1.0 and s.leader_history == PackedStringArray(["bibi", "bennett"]), "counted once however often he's re-picked")
	_elect(s)
	runner.check(not s.leader_round["fresh"] and is_equal_approx(float(s.leader_round["freshPct"]), 0.0), "the bonus is per round, never compounding")
	Politics.install(s, "liberman")
	runner.check(s.leader_round["fresh"] == true and float(s.stats["leaderSwitches"]) == 2.0, "Bennett → Liberman is a new face")


func test_leader_stats_and_trophies() -> void:
	var s := _round("bennett")
	for i in 5:
		Economy.tap(s)
	Economy.tick(s, 2.0)
	runner.check(Leaders.stat(s, "bennett", "taps") == 5.0 and is_equal_approx(Leaders.stat(s, "bennett", "playSec"), 2.0), "taps and play time per leader")
	s.leaders["bennett"]["taps"] = 1000.0
	var got := Meta.check_achievements(s, Economy.derive(s))
	runner.check(got.has("a_lead_bennett") and Meta.achievement("a_lead_bennett")["name"] == "חתום ומאושר", "his trophy (leaderStat)")
	s.crits_lifetime = 50
	runner.check(not Meta.check_achievements(s, Economy.derive(s)).has("a_rabbit_10"), "a bibiOnly trophy isn't earned in his round")
	var b := _round("bibi")
	b.crits_lifetime = 50
	runner.check(Meta.check_achievements(b, Economy.derive(b)).has("a_rabbit_10"), "but is in Bibi's")
	for id in Leaders.pickable():
		b.leaders[id] = Leaders.fresh_stats()
		b.leaders[id]["elections"] = 1.0
	b.stats["leaderSwitches"] = 10.0
	var g := Meta.check_achievements(b, Economy.derive(b))
	runner.check(g.has("a_all_leaders") and g.has("a_fresh_face"), "the two global trophies")
	runner.check(Meta.achievements().size() == (Content.data()["achievements"]["list"] as Array).size(), "the shipped list is unchanged (the dossier)")
	runner.check(Meta.all_trophies().size() == Meta.achievements().size() + 9, "all_trophies: + 2 global + 7 leaders (Bibi's are the shipped 40)")
	var e := _round("bengvir")
	_elect(e)
	runner.check(Leaders.stat(e, "bengvir", "elections") == 1.0 and is_equal_approx(Leaders.stat(e, "bengvir", "bestRunSec"), 420.0), "elections and the best round per leader")


# ---------------------------------------------------------------------------------------------
# Save v4
# ---------------------------------------------------------------------------------------------

func test_v3_save_migrates_as_bibis_round() -> void:
	var st := SaveStore.new(dir)
	var old := GameState.fresh()
	old.evolutions = 3
	old.taps_lifetime = 1234
	old.crits_lifetime = 21
	old.run_taps = 40
	var raw := old.to_dict()
	for k in ["leader", "leaderPickPending", "leaderHistory", "leaders", "seatDeal", "leaderRound"]:
		raw.erase(k)
	var f := FileAccess.open(st.path, FileAccess.WRITE)
	f.store_string(JSON.stringify({"version": 3, "lastSaveTime": 5.0, "state": raw}))
	f.close()
	var r := st.load_game()
	runner.check(r["kind"] == "ok", "a v3 save loads")
	var l: GameState = r["state"]
	runner.check(l.leader == "bibi" and not Leaders.pick_pending(l) and l.leader_history == PackedStringArray(["bibi"]), "Bibi's round, no picker until the next election")
	var b: Dictionary = l.leaders["bibi"]
	runner.check(b["rounds"] == 4.0 and b["elections"] == 3.0 and b["taps"] == 1234.0 and b["crits"] == 21.0, "leaders.bibi seeded (%s)" % str(b))
	st.save_game(l, 6.0)
	runner.check(int(JSON.parse_string(FileAccess.get_file_as_string(st.path))["version"]) == 4, "the next save writes v4")
	_elect(l)
	runner.check(Leaders.pick_pending(l) and l.leader_round["prev"] == "bibi", "the next election opens the picker")
	runner.check(Politics.install(l, "liberman")["fresh"] == true, "and a switch from Bibi is a fresh face")


func test_unknown_leader_at_load() -> void:
	var s := GameState.fresh()
	var raw := s.to_dict()
	raw["leader"] = "lapid"   # not a leader: a roster change
	raw["leaderPickPending"] = false
	var a := GameState.from_dict(JSON.parse_string(JSON.stringify(raw)))
	runner.check(a.leader == "bibi" and Leaders.pick_pending(a), "round not started: the default, and the picker")
	raw["runTaps"] = 9
	var b := GameState.from_dict(JSON.parse_string(JSON.stringify(raw)))
	runner.check(b.leader == "bibi" and not Leaders.pick_pending(b), "round started: it stays a (default) round")
	raw["leader"] = "bennett"
	raw["leaderPickPending"] = true   # a Bibi-only build never cleared it; the round has started
	var c := GameState.from_dict(JSON.parse_string(JSON.stringify(raw)))
	runner.check(c.leader == "bennett" and not c.leader_pick_pending, "a started round never reopens the picker")


func test_round_trip_v4() -> void:
	var s := _round("liberman", 99)
	Economy.tap(s)
	s.coalition["declineCdSec"] = 30.0
	var st := SaveStore.new(dir)
	st.save_game(s, 1.0)
	var l: GameState = st.load_game()["state"]
	for k in ["leader", "leaderPickPending", "leaderHistory", "leaders", "seatDeal", "leaderRound"]:
		runner.check(JSON.stringify(s.to_dict()[k], "", true) == JSON.stringify(l.to_dict()[k], "", true), k + " survives the round trip")
	runner.check(is_equal_approx(float(l.coalition["declineCdSec"]), 30.0), "the decline cooldown survives")


# ---------------------------------------------------------------------------------------------
# The content lint and the bench hooks
# ---------------------------------------------------------------------------------------------

func test_validate_is_clean_and_catches_a_bad_rule() -> void:
	var err := Politics.validate()
	runner.check(err.is_empty(), "Politics.validate() on the shipped content: %s" % str(err))
	var c: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Content.PATH))
	for L: Dictionary in c["leaders"]:
		if L["id"] == "bengvir":
			L["rule"]["effect"]["type"] = "teleport"
		if L["id"] == "liberman":
			L["coalition"]["lineup"].append({"id": "nobody", "slot": "L2"})
	var bad := Leaders.validate(c)
	runner.check(bad.size() >= 2, "an unknown rule and an unknown partner are errors (%s)" % str(bad))
	runner.check(Leaders.pickable().size() == 8 and Politics.validate().is_empty(), "the loaded content is untouched")


func test_pacing_sim_leader_and_mixed() -> void:
	var p: Dictionary = PacingSim.PLAYERS["median"].duplicate()
	p["leader"] = "bennett"
	var r := PacingSim.session(p, 40.0, 3, 0.5)
	runner.check((r["leaders"] as Array) == ["bennett"], "a leader session plays that leader")
	var picks := {}
	var i := 0
	for k in 40:
		i += 1
		var x := float(i % 10) / 10.0 + 0.05
		picks[PacingSim.pick_leader("mixed", func() -> float: return x)] = true
	runner.check(picks.size() == 8, "mixed picks among all 8 (%s)" % str(picks.keys()))
	runner.check(PacingSim.pick_leader("", randf) == "", "no leader: the round keeps its own")


# ---------------------------------------------------------------------------------------------
# Every leader, and the wave-2 knobs
# ---------------------------------------------------------------------------------------------

func test_every_leader_installs_a_legal_round() -> void:
	for id in Leaders.pickable():
		for salt in [1, 2, 3]:
			var s := _round(id, salt)
			var co: Dictionary = Leaders.leader(id).get("coalition", {})
			var ps := Coalition.partners()
			if id == "bibi":
				runner.check(is_same(ps, Content.data()["partners"]), "bibi: the shipped list")
				continue
			runner.check(ps.size() == (co["lineup"] as Array).size(), "%s: one partner per lineup entry" % id)
			var cap := 0
			var people := {}
			for p: Dictionary in ps:
				cap += int(Leaders.slots()[str(p["slot"])]["seats"])
				people[str(p["id"])] = true
				runner.check(str(p["id"]) != id, "%s: the leader is never a partner" % id)
			runner.check(cap >= 40, "%s: capacity %d ≥ 40" % [id, cap])
			runner.check(Coalition.first_partner() == str(co["firstPartner"]) and str(Coalition.partner(Coalition.first_partner())["slot"]) == "S1", "%s: C1 on S1" % id)
			for person in Leaders.rival_people(id):
				runner.check(not people.has(person) and person != id, "%s: rival %s is not a partner" % [id, person])
			for e: Dictionary in Events.list():
				runner.check(not Leaders.bibi_only("events").has(str(e["id"])), "%s: no Bibi-only card %s" % [id, e["id"]])
			runner.check(not Economy.derive(s).evolve_enabled, "%s: a new round starts closed" % id)


func test_straight_taps() -> void:
	var s := _round("eisenkot")
	var d := Economy.derive(s)
	var cm := float(Content.data()["tap"]["critMult"])
	var c0 := float(Content.data()["tap"]["critChance"])
	runner.check(d.crit_chance == 0.0 and is_equal_approx(d.straight_mult, 1.0 + c0 * (cm - 1.0)), "no crits; taps × %.2f" % d.straight_mult)
	var tv := d.tap_value_no_crit
	var b := _round("bibi")
	var db := Economy.derive(b)
	runner.check(is_equal_approx(tv, db.tap_value_no_crit * d.straight_mult), "his tap = Bibi's × the crits' average (equal value)")
	Economy.derive(s)
	s.upgrades.append("s11")   # slot E: the crit chance up
	var de := Economy.derive(s)
	runner.check(de.crit_chance == 0.0 and is_equal_approx(de.straight_mult, 1.0 + 0.07 * (cm - 1.0)), "slot E: ×%.2f (1.63)" % de.straight_mult)
	var got_tap7 := false
	for i in 12:
		var r := Economy.tap(s, func() -> float: return 0.0)   # a roll that would always crit
		runner.check(r["crit"] == false, "tap %d never crits" % (i + 1))
		if r.get("tap7", false):
			got_tap7 = i == 6
	runner.check(got_tap7 and s.crits_lifetime == 0, "tap 7 is flagged for the view's line, no rabbit")
	Events.fire(s, "card_smotrich", Economy.derive(s))   # "אין כסף": noCrit
	var dn := Economy.derive(s)
	runner.check(dn.straight_mult == 1.0 and dn.crit_chance == 0.0, "a noCrit card suspends the bonus")


func test_leader_effects_smotrich() -> void:
	var b := _round("bibi")
	b.owned["vat"] = 3
	var db := Economy.derive(b)
	var s := _round("smotrich")
	s.owned["vat"] = 3
	var d := Economy.derive(s)
	runner.check(is_equal_approx(float(d.producer_mult["vat"]), float(db.producer_mult["vat"]) * 1.18), "VAT ×1.18 from t 0")
	runner.check(is_equal_approx(Leaders.demand_discount_pct(), 10.0), "demands −10%")
	_member(s, "bengvir")
	runner.check(is_equal_approx(Coalition.demand_price(s, "bengvir", d), ceilf(maxf(10.0, 45.0 * d.bps * 0.9))), "a demand at 90%")
	s.shop["p_deal"] = 1   # the perk's 10% adds to his
	runner.check(is_equal_approx(Coalition.demand_price(s, "bengvir", d), ceilf(maxf(10.0, 45.0 * d.bps * 0.8))), "perk + rule: 20% off")
	var ids := _ids(Coalition.partners())
	runner.check(ids.has("karhi") and not ids.has("abbas") and not ids.has("smotrich"), "Karhi in, Abbas out, never himself")


func test_leader_effects_deri() -> void:
	_round("bibi")
	runner.check(Coalition._num("rejoinMult", 1.5) == 1.5, "Bibi: the shipped 1.5×")
	var s := _round("deri")
	runner.check(Coalition._num("rejoinMult", 1.5) == 1.0, "Deri: rejoin at 1.0×")
	s.coalition["opened"] = true
	_member(s, "bibi")
	s.bananas = 1e6
	var d0 := Economy.derive(s)
	var r := Coalition.pay(s, _demand(s, "bibi"))
	runner.check(r["ok"] == true and (r["events"] as Array).any(func(e: Dictionary) -> bool: return e.get("ev", "") == "leaderBuff"), "a paid demand pours coffee")
	var d1 := Economy.derive(s)
	runner.check(is_equal_approx(d1.tap_mult, d0.tap_mult * 1.2), "taps ×1.2")
	Events.tick(s, 20.0, d1, {}, func() -> float: return 0.99)
	Coalition.pay(s, _demand(s, "bibi"))
	var live := (s.events["active"] as Array).filter(func(a: Dictionary) -> bool: return a["type"] == "leaderBuff")
	runner.check(live.size() == 1 and is_equal_approx(float(live[0]["leftSec"]), 30.0), "refreshed, not stacked")
	runner.check(is_equal_approx(Economy.derive(s).tap_mult, d0.tap_mult * 1.2), "still ×1.2")
	_member(s, "regev")
	Coalition._post(s, {"type": "ultimatum", "partner": "regev", "price": 400.0, "leftSec": 0.05, "state": "open"}, [])
	Coalition._tick_messages(s, 0.1, [])
	var pill := (s.coalition["chat"] as Array).filter(func(m: Dictionary) -> bool: return m.get("payable", "") == "rejoin")
	runner.check(pill.size() == 1 and float(pill[0]["price"]) == 400.0, "the rejoin pill costs the missed price")


func _golan_ready() -> GameState:
	var s := _round("golan")
	s.coalition["opened"] = true
	for id: String in ["eisenkot", "lapid", "bennett", "liberman"]:
		_member(s, id)
		Coalition.ps(s, id)["memberSec"] = 90.0
	return s


func test_merge_members() -> void:
	var s := _golan_ready()
	var d := Economy.derive(s)
	var seats := int(Coalition.seat_info(s)["partners"])
	var up := Coalition.upkeep_pct(s)
	var pa := Coalition.demand_price(s, "lapid", d)
	var pb := Coalition.demand_price(s, "bennett", d)
	runner.check(Coalition.can_merge(s, "lapid", "bennett") and Coalition.merge_candidates(s, "lapid").has("bennett"), "two members of 60 s+ can merge")
	var r := Coalition.merge(s, "lapid", "bennett")
	runner.check(r["ok"] == true and Coalition.status(s, "bennett") == "merged", "merged into Lapid's row")
	runner.check(int(Coalition.seat_info(s)["partners"]) == seats and is_equal_approx(Coalition.upkeep_pct(s), up), "seats and upkeep summed (unchanged in total)")
	runner.check(Coalition.row_seats(s, "lapid") == int(_p("lapid")["seats"]) + int(_p("bennett")["seats"]), "one row")
	runner.check(is_equal_approx(Coalition.demand_price(s, "lapid", d), maxf(pa, pb)), "one stream at the higher price")
	runner.check(Coalition.member_count(s) == 3, "one fewer member asking")
	runner.check(Leaders.stat(s, "golan", "merges") == 1.0, "counted for his trophy")
	runner.check(Coalition.merge_block(s, "eisenkot", "liberman") == "cooldown", "120 s apart")
	s.coalition["mergeCdSec"] = 0.0
	runner.check(Coalition.merge(s, "eisenkot", "liberman")["ok"] == true, "a second merge")
	s.coalition["mergeCdSec"] = 0.0
	_member(s, "kariv")
	Coalition.ps(s, "kariv")["memberSec"] = 90.0
	runner.check(Coalition.merge_block(s, "lapid", "kariv") == "limit", "2 per round")
	Coalition._post(s, {"type": "ultimatum", "partner": "lapid", "price": 100.0, "leftSec": 0.05, "state": "open"}, [])
	Coalition._tick_messages(s, 0.1, [])
	var left := (s.coalition["chat"] as Array).filter(func(m: Dictionary) -> bool: return m.get("key", "") == "chat.sys.left" and m.get("partner", "") == "lapid")
	runner.check(left.size() == 1 and (left[0].get("with", []) as Array) == ["bennett"], "the pair walks out together, one pill")
	runner.check(not Coalition.counts(s, "lapid") and not Coalition.counts(s, "bennett"), "both seats are gone")


func test_undo_restores_the_pre_pick_state() -> void:
	var s := _round("bibi")
	_elect(s)
	var before := JSON.stringify(s.to_dict(), "", true)
	runner.check(Leaders.undo_pick(s)["reason"] == "none", "nothing to undo before a pick")
	Politics.install(s, "golan")
	var golan_deal := JSON.stringify(s.seat_deal, "", true)
	runner.check(s.leader_round["fresh"] == true and not Leaders.pick_pending(s), "picked: fresh face, picker closed")
	var u := Leaders.undo_pick(s)
	runner.check(u["ok"] == true and u["leader"] == "bibi", "undo: back to the pre-pick leader")
	var after := JSON.parse_string(JSON.stringify(s.to_dict(), "", true)) as Dictionary
	var want := JSON.parse_string(before) as Dictionary
	for k in ["leader", "leaderPickPending", "leaderHistory", "leaders", "seatDeal", "stats"]:
		runner.check(JSON.stringify(after[k], "", true) == JSON.stringify(want[k], "", true), "undo restores %s" % k)
	runner.check(not s.leader_round["fresh"] and float(s.leader_round["freshPct"]) == 0.0 and Leaders.pick_pending(s), "the +10% reverted, the picker open again")
	Politics.install(s, "golan")
	runner.check(JSON.stringify(s.seat_deal, "", true) == golan_deal, "re-picking deals the same seats (same seed)")
	Economy.tap(s)
	runner.check(Leaders.undo_pick(s)["reason"] == "started", "no undo after the first tap")


func test_press_days_and_hazard_days() -> void:
	var s := _round("bennett")
	s.investigation["phase"] = "summons"
	Investigation.testify(s)
	runner.check(float(s.stats["pressDays"]) == 1.0 and float(s.stats["courtDays"]) == 0.0 and float(s.stats["hazardDays"]) == 1.0, "a press day, not a court day")
	runner.check(int(s.investigation["pressDays"]) == 1 and int(s.investigation["courtDays"]) == 0, "the module counts it apart")
	var b := _round("bibi")
	b.investigation["phase"] = "summons"
	Investigation.testify(b)
	runner.check(float(b.stats["courtDays"]) == 1.0 and float(b.stats["pressDays"]) == 0.0 and float(b.stats["hazardDays"]) == 1.0, "Bibi's court day")


func test_merge_guards() -> void:
	var s := _golan_ready()
	Coalition.ps(s, "lapid")["memberSec"] = 30.0
	runner.check(Coalition.merge_block(s, "lapid", "bennett") == "young", "60 s as a member first")
	_member(s, "gantz")
	Coalition.ps(s, "gantz")["memberSec"] = 90.0
	runner.check(Coalition.merge_block(s, "eisenkot", "gantz") == "standIn", "never the stand-in")
	Coalition._post(s, {"type": "ultimatum", "partner": "liberman", "price": 9.0, "leftSec": 90.0, "state": "open"}, [])
	runner.check(Coalition.merge_block(s, "eisenkot", "liberman") == "ultimatum", "never a partner with an open ultimatum")
	runner.check(Coalition.merge_block(s, "eisenkot", "eisenkot") == "same", "not with himself")
	var b := _round("bibi")
	runner.check(Coalition.merge_block(b, "bengvir", "regev") == "rule" and Coalition.merge_cooldown(b) == -1.0, "only in Golan's round")
	var g := _golan_ready()
	Coalition.merge(g, "lapid", "bennett")
	var st := SaveStore.new(dir)
	st.save_game(g, 1.0)
	var l: GameState = st.load_game()["state"]
	runner.check(Coalition.status(l, "bennett") == "merged" and (Coalition.ps(l, "lapid")["carry"] as Array).has("bennett") and int(l.coalition["mergesRound"]) == 1, "a merge survives a reload")
