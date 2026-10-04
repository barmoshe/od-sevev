extends RefCounted
## Leader select pacing (design/leader-select-spec.md §7.2): every pickable leader must pass the
## od-sevev gates ON ITS OWN, played by PacingSim with that leader's lineup, deal, rivals and rule
## (tests/bench/test_session.gd has the gates and their sources; Bibi, the shipped round, is
## measured there). A mixed session (a random leader every round) must pass S5-S7.
##   L1 median first election, seeds 1-9 (a different deal per seed): the MEDIAN in 7:00-9:00
##   S0 median C1 at 0:20-1:15, Q3 no ultimatum before 3:00 (seed 7)
##   S2 engaged / S3 casual first election 5:00-9:00; S4 idle later than the median, ≤ 16:00 (each
##      the median over seeds 1-9, one deal per seed)
##   S5 median round 2 in 3:00 .. round 1; S6 rounds 1-5 each ≥ 3:00; S7 the last era in the hour
## One leader: tools/balance.sh --leader=<id> (or --leader <id>); default: all of them.

var runner: Object

const SEEDS := [1, 2, 3, 4, 5, 6, 7, 8, 9]
static var _cache := {}


static func _only() -> String:
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		var a: String = args[i]
		if a.begins_with("--leader="):
			return a.substr(9)
		if a == "--leader" and i + 1 < args.size():
			return args[i + 1]
	return ""


static func _leaders(with_default: bool) -> Array:
	var only := _only()
	var out: Array = []
	for id in Leaders.pickable():
		if only != "" and id != only:
			continue
		if not with_default and Leaders.is_default(id) and only == "":
			continue
		out.append(id)
	return out


static func _in(t: float, lo_min: float, hi_min: float) -> bool:
	return t >= lo_min * 60.0 and t <= hi_min * 60.0


static func _first_event(events: Array, what: String) -> float:
	for e: Array in events:
		if e[1] == what:
			return float(e[0])
	return INF


static func _first(player: String, id: String, seed_: int) -> Dictionary:
	var k := "%s:%s:%d" % [player, id, seed_]
	if not _cache.has(k):
		var ev: Array = []
		var r := PacingSim.first_round(id, PacingSim.PLAYERS[player], seed_, 1800.0, 0.25, ev)
		r["events"] = ev
		_cache[k] = r
	return _cache[k]


static func _t(r: Dictionary) -> float:
	return float(r["gate_t"]) if float(r["gate_t"]) >= 0.0 else INF


func test_every_leader_first_election_median_4_to_5() -> void:
	if not Leaders.active():
		print("  (content has no leader select: skipped)")
		return
	for id: String in _leaders(true):
		var ts: Array = []
		for sd: int in SEEDS:
			ts.append(_t(_first("median", id, sd)))
		var sorted := ts.duplicate()
		sorted.sort()
		var med := float(sorted[sorted.size() / 2])
		print("  %-9s median first election %s (seeds 1-9: %s)" % [id, PacingSim.fmt_t(med),
			", ".join(ts.map(func(x: float) -> String: return PacingSim.fmt_t(x)))])
		runner.check(_in(med, 4.0, 5.0), "L1 %s: the median first election over seeds 1-9 in 4-5 min (ADR 0013), got %s" % [id, PacingSim.fmt_t(med)])
		# Mordechai David's dose (design/mordechai-david-spec.md §6): the seeds where his blockade fired
		# before the first election (Balfour is round 1 only)
		var md := 0
		for sd: int in SEEDS:
			var rs := _first("median", id, sd)
			if _first_event(rs["events"], "event:mordechai") <= _t(rs):
				md += 1
		print("  %-9s Mordechai David before the first election: %d of %d seeds" % [id, md, SEEDS.size()])
		var r7 := _first("median", id, 7)
		var c1 := _first_event(r7["events"], "c1")
		var u := _first_event(r7["events"], "ultimatum")
		runner.check(_in(c1, 20.0 / 60.0, 1.25), "S0 %s: C1 at 0:20-1:15, got %s" % [id, PacingSim.fmt_t(c1)])
		runner.check(u >= 180.0 - 0.25, "Q3 %s: no ultimatum before 3:00, first at %s" % [id, PacingSim.fmt_t(u)])


## A profile's first election, the median over seeds 1-9 (each seed deals the seats differently, so
## one seed is one deal; Bibi's round has no deal and test_session.gd measures seed 7).
static func _median_first(player: String, id: String) -> float:
	var ts: Array = []
	for sd: int in SEEDS:
		ts.append(_t(_first(player, id, sd)))
	ts.sort()
	return float(ts[ts.size() / 2])


func test_every_leader_profiles() -> void:
	if not Leaders.active():
		return
	for id: String in _leaders(false):
		var m := _median_first("median", id)
		var e := _median_first("engaged", id)
		var c := _median_first("casual", id)
		var i := _median_first("idle", id)
		print("  %-9s first election (median of seeds 1-9): median %s, engaged %s, casual %s, idle %s" % [id, PacingSim.fmt_t(m), PacingSim.fmt_t(e), PacingSim.fmt_t(c), PacingSim.fmt_t(i)])
		runner.check(_in(e, 3.0, 5.0), "S2 %s: engaged first election in 3-5 min (ADR 0013), got %s" % [id, PacingSim.fmt_t(e)])
		runner.check(_in(c, 3.5, 5.5), "S3 %s: casual first election in 3:30-5:30 (ADR 0013), got %s" % [id, PacingSim.fmt_t(c)])
		runner.check(i > m and i <= 8.0 * 60.0, "S4 %s: idle later than the median (%s) and by 8 min (ADR 0013), got %s" % [id, PacingSim.fmt_t(m), PacingSim.fmt_t(i)])


static func _session_gates(runner_: Object, name: String, r: Dictionary) -> void:
	var runs: Array = r["runs"]
	var who: Array = r["leaders"]
	print("  %-9s runs %s | base %d | longest gap %s | leaders %s" % [name,
		", ".join(runs.map(func(x: float) -> String: return PacingSim.fmt_t(x))), int(r["thumbs"]), PacingSim.fmt_t(r["maxGap"]),
		",".join(who.slice(0, runs.size() + 1))])
	runner_.check(runs.size() >= 2 and float(runs[1]) >= 180.0 and float(runs[1]) <= float(runs[0]),
		"S5 %s: round 2 in 3:00 .. round 1 (%s), got %s" % [name, PacingSim.fmt_t(float(runs[0]) if runs.size() >= 1 else INF), PacingSim.fmt_t(float(runs[1]) if runs.size() >= 2 else INF)])
	var short := INF
	for k in mini(5, runs.size()):
		short = minf(short, float(runs[k]))
	runner_.check(runs.size() >= 5 and short >= 180.0, "S6 %s: rounds 1-5 each at least 3:00 (shortest %s, %d rounds)" % [name, PacingSim.fmt_t(short), runs.size()])
	var eras: Array = Content.data()["eras"]["list"]
	var last_era := int((eras.back() as Dictionary)["fromEvolutions"])
	runner_.check(runs.size() >= last_era, "S7 %s: the %s era (%d elections) in the hour, got %d" % [name, (eras.back() as Dictionary)["id"], last_era, runs.size()])


func test_every_leader_median_hour() -> void:
	if not Leaders.active():
		return
	for id: String in _leaders(false):
		var p: Dictionary = PacingSim.PLAYERS["median"].duplicate()
		p["leader"] = id
		_session_gates(runner, id, PacingSim.session(p, 3600.0, 7, 0.25))


func test_mixed_session() -> void:
	if not Leaders.active() or _only() != "":
		return
	var p: Dictionary = PacingSim.PLAYERS["median"].duplicate()
	p["leader"] = "mixed"
	var r := PacingSim.session(p, 3600.0, 7, 0.25)
	_session_gates(runner, "mixed", r)
	var s: GameState = r["state"]
	print("           switches %d, fresh-face rounds pay +%d%%" % [int(s.stats.get("leaderSwitches", 0)), int(Leaders.ls()["pick"]["freshFaceBasePct"])])


## V1 "the vote stops the clock" (spec §7.4): for every leader and deal, a median player who reaches
## 61 and then reads the election card for VOTE_READ_SEC (no taps, buys or chat) still has the gate
## when they press "לפזר את הכנסת". The line without the hold (politics running under the card, as
## before 2026-09-30) is printed for contrast: how often the card used to lose the gate.
const VOTE_READ_SEC := 30.0


static func _gate_after_reading(s: GameState, sd: int, vote: bool) -> bool:
	var rng := RandomNumberGenerator.new()
	rng.seed = sd * 31 + 5
	var rf := func() -> float: return rng.randf()
	var ctx := {"allowPing": false, "weekday": 2, "hour": 12, "vote": vote}
	var t := 0.0
	while t < VOTE_READ_SEC:
		var d := Economy.derive(s)
		if not vote:
			Economy.tick(s, 0.25, d)
		Politics.tick(s, 0.25, d, ctx, rf)
		t += 0.25
		if not Economy.derive(s).evolve_enabled:
			return false
	return true


func test_every_leader_keeps_the_gate_while_the_card_is_read() -> void:
	if not Leaders.active():
		return
	for id: String in _leaders(true):
		var held := 0
		var before := 0
		var n := 0
		for sd: int in SEEDS:
			var r := _first("median", id, sd)
			if float(r["gate_t"]) < 0.0:
				continue
			n += 1
			var st: GameState = r["state"]
			if _gate_after_reading(st.duplicate_state(), sd, false):
				before += 1
			if _gate_after_reading(st.duplicate_state(), sd, true):
				held += 1
		print("  %-9s the gate after %ds on the card: %d/%d (without the vote hold %d/%d)" % [id, int(VOTE_READ_SEC), held, n, before, n])
		runner.check(n > 0 and held == n, "V1 %s: the gate holds for every deal while the card is read, got %d/%d" % [id, held, n])
