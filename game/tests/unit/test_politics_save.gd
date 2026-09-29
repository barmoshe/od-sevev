extends RefCounted
## Save v3: the politics sections (coalition, investigation, events, album, calendar) round-trip,
## a v2 save migrates with fresh defaults, and broken sections are sanitized at the boundary.

const PF := preload("res://tests/politics_fixture.gd")

var runner: Object
var dir := ""


func setup(_r: Object) -> void:
	PF.install()
	dir = "user://test_psave_%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(dir)


func teardown() -> void:
	var d := DirAccess.open(dir)
	if d:
		for f in d.get_files():
			d.remove(f)
	DirAccess.remove_absolute(dir)
	PF.restore()


## A state mid-round: members, an open ultimatum, a brawl, court day, a live card, an album.
func _busy() -> GameState:
	var s := GameState.fresh()
	s.owned[Content.producer_ids()[0]] = 12
	s.owned[Content.producer_ids()[3]] = 2
	s.stats["playtimeSec"] = 400.0
	s.bananas = 1000.0
	s.run_bananas = 50000.0
	s.all_time_bananas = 50000.0
	var d := Economy.derive(s)
	Coalition.open_group(s, d)
	Coalition.pay(s, int(Coalition.open_msg(s, "bengvir")["seq"]))   # one open message per partner
	s.coalition["paidLifetime"] = 5
	for id in ["bengvir", "smotrich", "amsalem", "goldknopf", "gotliv"]:
		Coalition.ps(s, id)["status"] = "member"
	s.coalition["levels"]["goldknopf"] = 4
	Coalition.ps(s, "gotliv")["meter"] = 42.5
	Coalition._post(s, {"type": "ultimatum", "partner": "bengvir", "price": 321.0, "kind": "money", "leftSec": 55.5, "state": "open"}, [])
	Coalition.start_brawl(s, "amsalem", "smotrich")
	s.investigation["suspicion"] = 63.25
	s.investigation["phase"] = "court"
	s.investigation["leftSec"] = 12.0
	s.investigation["aideDrops"] = 2
	s.investigation["postponements"] = 3
	Events.fire(s, "eisenkot", d)
	Events.fire(s, "interview", d)
	s.album["liran"] = 3
	Calendar.resolve_now(s, Calendar.parse_utc_ms("2026-10-24T10:00:00"))
	Calendar.update(s, float(s.calendar["hwm"]))
	return s


func test_round_trip_keeps_every_politics_field() -> void:
	var st := SaveStore.new(dir)
	var s := _busy()
	runner.check(st.save_game(s, 1000.0), "save writes")
	var r := st.load_game()
	runner.check(r["kind"] == "ok", "loads ok")
	var l: GameState = r["state"]
	for k in ["coalition", "investigation", "events", "album", "calendar"]:
		var a := JSON.stringify(s.to_dict()[k], "", true)
		var b := JSON.stringify(l.to_dict()[k], "", true)
		if a != b:
			for i in mini(a.length(), b.length()):
				if a[i] != b[i]:
					print("    %s differs at %d:\n      saved:  %s\n      loaded: %s" % [k, i, a.substr(maxi(0, i - 120), 240), b.substr(maxi(0, i - 120), 240)])
					break
		runner.check(a == b, k + " survives the round trip")
	runner.check(Coalition.seat_info(l) == Coalition.seat_info(s), "same seats after load")
	runner.check(is_equal_approx(Economy.derive(l).bps, Economy.derive(s).bps), "same ₪/s after load (upkeep, court day)")
	runner.check(is_equal_approx(Economy.derive(l).prestige_mult, Economy.derive(s).prestige_mult), "same base (aide drops, interview)")
	runner.check(Calendar.mode(l) == "blackout", "the calendar mode survives")


func test_duplicate_state_keeps_politics() -> void:
	# main.gd evolves a duplicate (E7: save first); the duplicate must carry the politics intact.
	var s := _busy()
	# (The fork's stats.goldenMissed turns int -> float through any round trip; not ours.)
	var dup := s.duplicate_state()
	var keys := ["coalition", "investigation", "events", "album", "calendar"]
	var a := JSON.stringify(keys.map(func(k: String) -> Variant: return s.to_dict()[k]), "", true)
	var b := JSON.stringify(keys.map(func(k: String) -> Variant: return dup.to_dict()[k]), "", true)
	if a != b:
		for i in mini(a.length(), b.length()):
			if a[i] != b[i]:
				print("    duplicate differs at %d:\n      orig: %s\n      dup:  %s" % [i, a.substr(maxi(0, i - 150), 300), b.substr(maxi(0, i - 150), 300)])
				break
	runner.check(a == b, "duplicate_state() carries every politics section exactly")


func test_v2_save_migrates_to_v3() -> void:
	var st := SaveStore.new(dir)
	var f := FileAccess.open(st.path, FileAccess.WRITE)
	f.store_string(JSON.stringify({"version": 2, "lastSaveTime": 5.0, "state": {"bananas": 77.0, "evolutions": 2, "allTimeBananas": 1e7}}))
	f.close()
	var r := st.load_game()
	runner.check(r["kind"] == "ok", "a v2 save loads")
	var l: GameState = r["state"]
	runner.check(l.bananas == 77.0 and l.evolutions == 2, "its fields survive")
	runner.check(not l.coalition["opened"] and l.investigation["phase"] == "idle" and l.calendar["mode"] == "campaign", "politics start fresh")
	st.save_game(l, 6.0)
	runner.check(int(JSON.parse_string(FileAccess.get_file_as_string(st.path))["version"]) == 3, "the next save writes v3")


func test_newer_than_v3_is_kept_aside() -> void:
	var r := SaveStore.parse(JSON.stringify({"version": 4, "state": {}}))
	runner.check(r["kind"] == "newer", "a v4 save is newer, never overwritten")


func test_broken_sections_are_sanitized() -> void:
	var raw := _busy().to_dict()
	raw["coalition"]["partners"]["ghost"] = {"status": "member"}
	raw["coalition"]["partners"]["bengvir"]["status"] = "king"
	raw["coalition"]["chat"].append({"seq": 999, "type": "demand", "partner": "ghost", "state": "open", "price": 5})
	raw["coalition"]["chat"].append({"seq": 1000, "type": "boom", "state": "open"})
	raw["coalition"]["chat"].append({"seq": 1001, "type": "demand", "partner": "gotliv", "state": "open", "price": -5})
	raw["coalition"]["chat"].append({"seq": 1002, "type": "demand", "partner": "gotliv", "state": "open", "price": 7})
	raw["investigation"] = {"suspicion": 1e9, "phase": "jail", "aideDrops": "lots"}
	raw["events"] = {"active": [{"type": "noCrit", "leftSec": -3}], "cooldowns": {"nope": 5, "lapid": "x"}}
	raw["album"] = "album"
	raw["calendar"] = {"hwm": -5, "mode": "war"}
	var s := GameState.from_dict(JSON.parse_string(JSON.stringify(raw)))
	runner.check(s != null, "a broken save still loads")
	runner.check(not s.coalition["partners"].has("ghost") and Coalition.status(s, "bengvir") == "absent", "unknown partners dropped, bad statuses reset")
	var seqs: Array = (s.coalition["chat"] as Array).map(func(m: Dictionary) -> int: return m["seq"])
	runner.check(not seqs.has(999) and not seqs.has(1000), "messages about unknown partners or of unknown types are dropped")
	var open_g: Array = (s.coalition["chat"] as Array).filter(func(m: Dictionary) -> bool: return m.get("partner", "") == "gotliv" and m["state"] == "open")
	runner.check(open_g.size() == 1 and int(open_g[0]["seq"]) == 1002, "one open message per partner (the last wins)")
	var neg: Array = (s.coalition["chat"] as Array).filter(func(m: Dictionary) -> bool: return int(m["seq"]) == 1001)
	runner.check(neg.size() == 1 and float(neg[0]["price"]) == 0.0, "a negative price is cleaned to 0")
	runner.check(Investigation.suspicion(s) == 100.0 and Investigation.phase(s) == "idle" and int(s.investigation["aideDrops"]) == 0, "investigation clamped")
	runner.check((s.events["active"] as Array).is_empty() and not s.events["cooldowns"].has("nope") and not s.events["cooldowns"].has("lapid"), "events cleaned")
	runner.check(int(s.album["liran"]) == 0 and s.calendar["mode"] == "campaign" and float(s.calendar["hwm"]) == 0.0, "album and calendar fall back to fresh")


func test_evolve_resets_the_round_but_keeps_the_lifetime() -> void:
	var s := _busy()
	for id in Content.producer_ids():
		s.owned[id] = 1
	for id in ["deri", "levin", "regev"]:
		Coalition.ps(s, id)["status"] = "member"
	s.all_time_bananas = 1e7
	Coalition.resolve_brawl(s, int(Coalition.open_brawl(s)["seq"]))
	var r := Meta.evolve(s)
	runner.check(not r.is_empty(), "61 seats and enough base: the election runs")
	runner.check(Coalition.seat_info(s)["partners"] == 0 and int(s.coalition["levels"]["goldknopf"]) == 4, "coalition resets, Goldknopf's price level stays")
	runner.check(is_equal_approx(Investigation.suspicion(s), 5.0) and int(s.investigation["postponements"]) == 0, "suspicion to round 2's floor (5%), postponements reset")
	runner.check(int(s.investigation["aideDrops"]) == 2, "aide drops are forever")
	runner.check((s.events["active"] as Array).is_empty() and float(s.events["roundBasePct"]) == 0.0, "live cards and the interview end")
	runner.check(int(s.album["liran"]) == 3 and Calendar.mode(s) == "blackout", "the album and the calendar persist")
