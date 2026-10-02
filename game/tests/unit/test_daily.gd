extends RefCounted
## "הסבב היומי" (seeded rounds, the daily round): Israel's day boundary with DST (any year), the
## day number and seed, the leader rotation, the grid from a round record and its share text, the
## streak, the round book (one official attempt a day), and the daily round through the real scene.

var runner: Object
var tree: SceneTree
var dir := ""
var m: Node


func setup(r: Object) -> void:
	TestFixture.use_game_content()
	tree = r as SceneTree
	dir = "user://test_daily_%d" % Time.get_ticks_usec()
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


static func _ms(iso_utc: String) -> float:
	return float(Time.get_unix_time_from_datetime_string(iso_utc)) * 1000.0


# ------------------------------------------------------------------ the day

func test_israel_offset_follows_dst_in_any_year() -> void:
	_check(DailyRound.israel_offset_h(_ms("2026-03-26T23:59:59")) == 2, "2026: winter until Friday 27.3 02:00")
	_check(DailyRound.israel_offset_h(_ms("2026-03-27T00:00:00")) == 3, "2026: summer from Friday 27.3 02:00 (00:00 UTC)")
	_check(DailyRound.israel_offset_h(_ms("2026-10-24T22:59:59")) == 3, "2026: summer until Sunday 25.10 02:00")
	_check(DailyRound.israel_offset_h(_ms("2026-10-24T23:00:00")) == 2, "2026: winter from Sunday 25.10 02:00 (23:00 UTC)")
	_check(DailyRound.israel_offset_h(_ms("2027-03-25T23:59:59")) == 2 and DailyRound.israel_offset_h(_ms("2027-03-26T00:00:00")) == 3, "2027: Friday 26.3")
	_check(DailyRound.israel_offset_h(_ms("2027-10-30T22:59:59")) == 3 and DailyRound.israel_offset_h(_ms("2027-10-30T23:00:00")) == 2, "2027: Sunday 31.10")
	for iso in ["2026-04-15T12:00:00", "2026-10-02T09:00:00", "2026-11-20T09:00:00"]:
		_check(DailyRound.israel_offset_h(_ms(iso)) == int(Calendar.israel_offset_h(_ms(iso))), "agrees with the content's 2026 table at %s" % iso)


func test_day_boundary_is_israel_midnight() -> void:
	_check(DailyRound.day_key(_ms("2026-10-01T20:59:59")) == "2026-10-01", "23:59:59 IDT is still the 1st")
	_check(DailyRound.day_key(_ms("2026-10-01T21:00:00")) == "2026-10-02", "00:00 IDT is the 2nd")
	_check(DailyRound.day_key(_ms("2026-11-01T21:59:59")) == "2026-11-01", "23:59:59 IST (after DST) is still the 1st")
	_check(DailyRound.day_key(_ms("2026-11-01T22:00:00")) == "2026-11-02", "00:00 IST is the 2nd")
	_check(DailyRound.day_key(_ms("2026-10-24T22:30:00")) == "2026-10-25", "the DST night: 01:30 IDT on the 25th")
	_check(DailyRound.prev_key("2026-11-01") == "2026-10-31" and DailyRound.prev_key("2027-01-01") == "2026-12-31", "the day before")


func test_day_number_seed_and_leader() -> void:
	_check(DailyRound.number_of(DailyRound.EPOCH) == 1, "#1 on the launch day")
	_check(DailyRound.number_of("2026-10-02") == 2 and DailyRound.number_of("2026-11-03") == 34, "#34 on 3.11")
	_check(DailyRound.number(_ms("2026-10-01T21:00:00")) == 2, "the number follows the Israel day")
	var a := DailyRound.seed_of("2026-10-02")
	_check(a == DailyRound.seed_of("2026-10-02") and a != DailyRound.seed_of("2026-10-03") and a >= 0, "one stable seed a day")
	var seen := {}
	var key := "2026-10-01"
	for i in Leaders.pickable().size():
		seen[DailyRound.leader_of(key)] = true
		key = DailyRound.key_of_day(DailyRound._unix_day_of(key) + 1)
	_check(seen.size() == Leaders.pickable().size(), "every leader gets a day in turn: %s" % str(seen.keys()))
	_check(Leaders.playable(DailyRound.leader_of("2026-10-02")), "the day's leader is playable")


# ------------------------------------------------------------------ the grid

func test_grid_from_a_round_record() -> void:
	var rec := {"order": ["a", "b", "c", "d", "e", "f", "g"], "joined": {"a": true, "b": true, "c": true, "e": true},
		"paid": {"b": [3]}, "walked": {"c": true}, "hazardDays": 0, "press": false}
	_check(SeededRound.cells(rec) == "BYRWBWW", "joined / concession / walkout / unused: %s" % SeededRound.cells(rec))
	var lines := SeededRound.grid_lines("BYRWBWW")
	_check(lines.size() == 2 and lines[0] == Bidi.RLM + "🟦🟨🟥⬜🟦" and lines[1] == Bidi.RLM + "⬜⬜", "5 a line, RLM first: %s" % str(lines))
	_check(SeededRound.court_word(rec) == "dodged", "no court day: dodged")
	rec["hazardDays"] = 1
	_check(SeededRound.court_word(rec) == "testified", "a court day: testified")


func test_the_record_observes_a_real_round() -> void:
	var s := SeededRound.fresh_state("bibi", 11)
	var rec := SeededRound.new_record()
	SeededRound.observe(rec, s)
	var order: Array = rec["order"]
	_check(order.size() >= 5, "the lineup, stand-ins left out: %d" % order.size())
	var a: String = order[0]
	var b: String = order[1]
	var c: String = order[2]
	Coalition.ps(s, a)["status"] = "member"
	Coalition.ps(s, b)["status"] = "member"
	Coalition.ps(s, c)["status"] = "member"
	s.coalition["chat"] = [
		{"seq": 1, "type": "demand", "partner": a, "join": true, "state": "paid", "price": 60.0},
		{"seq": 2, "type": "demand", "partner": b, "join": false, "state": "paid", "price": 90.0},
	]
	SeededRound.observe(rec, s)
	Coalition.ps(s, c)["status"] = "left"   # the ultimatum ran out
	s.coalition["chat"] = []                 # the log trimmed: what was seen stays seen
	SeededRound.observe(rec, s)
	var cells := SeededRound.cells(rec)
	_check(cells.substr(0, 3) == "BYR" and cells.substr(3).replace("W", "") == "", "B (joined), Y (a paid demand), R (walked), the rest unused: %s" % cells)


func test_share_text_is_the_wordle_grid() -> void:
	var res := {"n": 34, "sec": 252, "cells": "BBBYWBBRBB", "court": "dodged", "press": false}
	var t := DailyRound.share_text(res, {"head": "עוד סבב #34", "court": "התחמקתי", "url": "od-sevev.vercel.app/s/daily"})
	var lines := t.split("\n")
	_check(lines.size() == 5, "head, two grid lines, the stats, the URL: %d" % lines.size())
	_check(lines[0] == "עוד סבב #34 🗳️", "a Hebrew word first: %s" % lines[0])
	_check(lines[1] == Bidi.RLM + "🟦🟦🟦🟨⬜" and lines[2] == Bidi.RLM + "🟦🟦🟥🟦🟦", "the grid")
	_check(lines[3] == Bidi.RLM + "61 ⏱️ 4:12 ⚖️ התחמקתי", "the stats line: %s" % lines[3])
	_check(lines[4] == "od-sevev.vercel.app/s/daily", "the URL last")
	var bo := DailyRound.share_text(res, {"head": "x", "court": "y", "url": "z"}, true)
	_check(not bo.contains("61") and bo.contains("✅ ⏱️ 4:12"), "the election silence drops the 61")
	res["press"] = true
	_check(DailyRound.share_text(res, {"head": "x", "court": "y", "url": "z"}).contains("🗞️"), "a press leader's line")
	var model: Dictionary = load("res://scripts/main.gd").daily_share_model(res, "https://od-sevev.vercel.app/", true, false)
	_check(str(model["text"]).begins_with("עוד סבב #34 🗳️") and str(model["url"]) == "od-sevev.vercel.app/s/daily", "the controller's model: %s" % model["text"])
	_check(not str(model["text"]).contains(Bidi.LRI), "share prose carries no isolates")


# ------------------------------------------------------------------ the book

func test_streak_counts_consecutive_days() -> void:
	var r := {"2026-10-03": {}, "2026-10-04": {}, "2026-10-05": {}}
	_check(DailyRound.streak(r, "2026-10-05") == 3, "three days through today")
	_check(DailyRound.streak(r, "2026-10-06") == 3, "today unplayed: the streak holds through yesterday")
	_check(DailyRound.streak(r, "2026-10-07") == 0, "a missed day breaks it")
	r["2026-10-07"] = {}
	_check(DailyRound.streak(r, "2026-10-07") == 1, "and it starts again")


func test_one_official_attempt_a_day() -> void:
	var b := RoundBook.new(dir)
	_check(b.record_daily("2026-10-02", {"n": 2, "leader": "bennett", "sec": 300, "cells": "BBYW", "court": "dodged"}), "the first result is official")
	_check(not b.record_daily("2026-10-02", {"n": 2, "leader": "bennett", "sec": 100, "cells": "BBBB", "court": "dodged"}), "a replay is not")
	_check(int(b.daily_result("2026-10-02")["sec"]) == 300, "the official result stays")
	var ref := b.ref()
	var b2 := RoundBook.new(dir).load_book()
	_check(b2.played("2026-10-02") and b2.ref() == ref and ref.length() == 8, "it survives a reload, the ref too")
	var bad := RoundBook.sanitize({"ref": "<script>", "daily": {"x": {"sec": 1}, "2026-10-01": {"sec": -1, "cells": "B"}, "2026-10-03": {"sec": 5, "cells": "BQ"}}})
	_check(bad["ref"] == "" and (bad["daily"] as Dictionary).is_empty(), "junk is dropped at the boundary")


# ------------------------------------------------------------------ the scene

func _boot() -> void:
	m = load("res://scenes/main.tscn").instantiate()
	m.store = SaveStore.new(dir)
	tree.root.add_child(m)
	for i in 3:
		await tree.process_frame
	m.ftue.handoff_ms = 1.0


func test_daily_from_the_picker_for_a_new_player() -> void:
	await _boot()
	_check(m.mode == "pick", "a new game opens on the picker")
	for i in 2:
		await tree.process_frame
	var room: bool = m.picker.sky.y - m.picker.sky.x >= 96.0
	_check(m.daily_btn_rect().has_area() == room, "the daily entry sits in the picker's sky when it has room: %s" % m.picker.sky)
	m.open_daily()
	await tree.process_frame
	_check(m.overlays.top() is RoundCards.DailyCard, "the daily card")
	m.start_daily()
	var today: String = m._round_today()
	_check(m.in_round() and Leaders.current(m.state) == DailyRound.leader_of(today), "today's leader")
	_check(int(m.state.leader_round["salt"]) == DailyRound.seed_of(today), "today's seed")
	m.state.run_time_sec = 252.3
	m._finish_round()
	await tree.process_frame
	_check(m.overlays.top() is RoundCards.DailyResult, "the result card")
	_check(m.book.played(today) and int(m.book.daily_result(today)["sec"]) == 252, "the official result is kept")
	_check((m.overlays.top() as RoundCards.RoundCard).model.get("newPlayer") == true, "a new player is offered their own game")
	m.leave_round()
	for i in 3:
		await tree.process_frame
	_check(not m.in_round() and m.mode == "pick", "a new player then starts their own game at the picker")
	_check(not FileAccess.file_exists(SaveStore.new(dir).path), "the daily round wrote no main save")
	m.start_daily()
	_check(m.round_info.get("official") == false, "a second attempt is not official")
	m.state.run_time_sec = 100.0
	m._finish_round()
	_check(int(m.book.daily_result(today)["sec"]) == 252, "and does not replace the day's result")
	m.leave_round()
