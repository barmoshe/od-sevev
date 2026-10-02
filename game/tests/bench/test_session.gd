extends RefCounted
## Pacing bench (tools/balance.sh): whole 60-minute sessions per player profile, played by PacingSim
## through the shipped Economy + Politics on design/content.json. This bench is the authoritative
## pacing check; design/sim/economy-sim.mjs is retired (design/progression-curve.md §0).
## The od-sevev gates (each with its source; the table is in design/progression-curve.md §0):
##   S0 median: the chat pings (C1) at 0:20-1:15 ............ pitch §11 Q2 ("first demand ~45 s")
##   Q3 no ultimatum before 3:00 of play ...................... pitch §11 Q3
##   S1 median (1.5 taps/s) first election 7:00-9:00 ......... pitch §5 Targets ("about 7-9 minutes")
##   S2 engaged (4 taps/s) first election 5:00-9:00 .......... the sim developer's objection (STATUS.md), accepted
##   S3 casual (2 taps/s) first election 5:00-9:00 ........... between S1 and S2 in tap rate, so inside their union
##   S4 idle first election later than the median, ≤ 16:00 .. pitch §10.3's rule for a style: "viable but slower,
##                                                              not a trap" (at most 2× the median's 8-min center)
##   S5 median second election 3:00 ≤ round 2 ≤ round 1 ..... pitch §11 Q8 note ("base growth makes later rounds
##                                                              faster") + §9 (a round holds a suitcase, every 2-4 min)
##   S6 median rounds 1-5 each ≥ 3:00 ......................... pitch §9 cadence (story flash, suitcase, ~90 s partner
##                                                              messages per round)
##   S7 median reaches the last era (Washington) in the hour . pitch §4 (4 eras) + §8/§9 (a story beat per election)
##   S8 median rounds get faster: the per-round median over ... the idle-genre rule (each prestige loop reaches the
##      seeds 3-11, rounds 2-8 each ≤ the previous + 0:15,      gate faster than the last) + pitch §11 Q8 note;
##      rounds 6-8 ≤ 6:00, none under 2:00                      2:00 keeps a round's partners, demands and court
##   plus the fork's liveness gates, kept: engaged ≥ 3 / casual ≥ 2 / idle ≥ 1 elections an hour, no round under a
##   minute, and something new at least every 5 min in runs 1-3 (pitch §9, "something new every few minutes").

var runner: Object

static var _cache := {}


func _session(profile: String) -> Dictionary:
	if _cache.has(profile):
		return _cache[profile]
	var r := PacingSim.session(PacingSim.PLAYERS[profile], 3600.0, 7, 0.25)
	var runs: Array = r["runs"]
	print("  %-8s runs %s | base %d | longest gap %s (runs 1-3)" % [profile,
		", ".join(runs.map(func(x: float) -> String: return PacingSim.fmt_t(x))), int(r["thumbs"]), PacingSim.fmt_t(r["maxGap"])])
	var s: GameState = r["state"]
	print("           trophies %d/%d, perks %s" % [s.achievements.size(), Meta.achievements().size(), str(s.shop)])
	_cache[profile] = r
	return r


static func _first(r: Dictionary) -> float:
	var runs: Array = r["runs"]
	return float(runs[0]) if not runs.is_empty() else INF


static func _first_event(r: Dictionary, what: String) -> float:
	for e: Array in r["events"]:
		if e[1] == what:
			return float(e[0])
	return INF


static func _in(t: float, lo_min: float, hi_min: float) -> bool:
	return t >= lo_min * 60.0 and t <= hi_min * 60.0


func test_median_first_election() -> void:
	var r := _session("median")
	var t := _first(r)
	runner.check(_in(t, 7.0, 9.0), "S1: median first election in 7-9 min (pitch §5), got %s" % PacingSim.fmt_t(t))
	var c1 := _first_event(r, "c1")
	runner.check(_in(c1, 20.0 / 60.0, 1.25), "S0: median C1 chat ping at 0:20-1:15 (pitch §11 Q2), got %s" % PacingSim.fmt_t(c1))
	var u := _first_event(r, "ultimatum")
	# Events carry their frame's start time while the frame's tick already counted its 0.25 s of play,
	# so an ultimatum posted at exactly 3:00 of play is stamped 2:59.75: allow that one bench frame.
	runner.check(u >= 180.0 - 0.25,"Q3: no ultimatum before 3:00 (pitch §11 Q3), first at %s" % PacingSim.fmt_t(u))


func test_engaged_session() -> void:
	var r := _session("engaged")
	var runs: Array = r["runs"]
	runner.check(_in(_first(r), 5.0, 9.0), "S2: engaged first election in 5-9 min, got %s" % PacingSim.fmt_t(_first(r)))
	runner.check(runs.size() >= 3, "engaged player calls at least 3 elections in an hour (%d)" % runs.size())
	var shortest := 1e9
	for x: float in runs:
		shortest = minf(shortest, x)
	runner.check(shortest >= 60.0, "no round under a minute in the first hour (shortest %s)" % PacingSim.fmt_t(shortest))
	runner.check(float(r["maxGap"]) <= 300.0, "something new at least every 5 min in runs 1-3 (longest gap %s)" % PacingSim.fmt_t(r["maxGap"]))


func test_casual_and_idle_sessions() -> void:
	var c := _session("casual")
	var i := _session("idle")
	var m := _session("median")
	runner.check(_in(_first(c), 5.0, 9.0), "S3: casual first election in 5-9 min, got %s" % PacingSim.fmt_t(_first(c)))
	runner.check(_first(i) > _first(m) and _first(i) <= 16.0 * 60.0,
		"S4: idle first election later than the median (%s) and by 16 min, got %s" % [PacingSim.fmt_t(_first(m)), PacingSim.fmt_t(_first(i))])
	runner.check((c["runs"] as Array).size() >= 2, "casual player calls at least 2 elections in an hour")
	runner.check((i["runs"] as Array).size() >= 1, "idle player calls an election in an hour")


func test_median_later_rounds_and_eras() -> void:
	var r := _session("median")
	var runs: Array = r["runs"]
	runner.check(runs.size() >= 2 and float(runs[1]) >= 180.0 and float(runs[1]) <= float(runs[0]),
		"S5: median round 2 in 3:00 .. round 1 (%s), got %s" % [PacingSim.fmt_t(_first(r)), PacingSim.fmt_t(float(runs[1]) if runs.size() >= 2 else INF)])
	var short := INF
	for k in mini(5, runs.size()):
		short = minf(short, float(runs[k]))
	runner.check(runs.size() >= 5 and short >= 180.0, "S6: median rounds 1-5 each at least 3:00 (shortest %s)" % PacingSim.fmt_t(short))
	var eras: Array = Content.data()["eras"]["list"]
	var last_era := int((eras.back() as Dictionary)["fromEvolutions"])
	runner.check(runs.size() >= last_era, "S7: median reaches the %s era (%d elections) in the hour, got %d" % [(eras.back() as Dictionary)["id"], last_era, runs.size()])
	runner.check(float(r["maxGap"]) <= 300.0, "median: something new at least every 5 min in runs 1-3 (longest gap %s)" % PacingSim.fmt_t(r["maxGap"]))


## S8: the idle-genre rule, each prestige loop reaches the gate faster than the last. One hour is
## one chaotic draw (a walkout cascade can add minutes to any round), so the curve is the per-round
## MEDIAN over CURVE_SEEDS. Rounds 2-8 each at most the previous + 15 s, rounds 6-8 at most 6:00,
## and no round of the curve under 2:00 (every round keeps its partners, demands and court).
const CURVE_SEEDS := [3, 5, 7, 9, 11]
const CURVE_ROUNDS := 8


func test_median_rounds_get_faster() -> void:
	var lists: Array = []
	for sd: int in CURVE_SEEDS:
		var r: Dictionary = _session("median") if sd == 7 else PacingSim.session(PacingSim.PLAYERS["median"], 3600.0, sd, 0.25)
		lists.append(r["runs"])
		if sd != 7:
			print("  median s%-3d runs %s" % [sd, ", ".join((r["runs"] as Array).map(func(x: float) -> String: return PacingSim.fmt_t(x)))])
	var curve: Array = []
	for k in CURVE_ROUNDS:
		var vals: Array = []
		for l: Array in lists:
			vals.append(float(l[k]) if l.size() > k else INF)
		vals.sort()
		curve.append(float(vals[vals.size() / 2]))
	print("  median curve (seeds %s): %s" % [str(CURVE_SEEDS), ", ".join(curve.map(func(x: float) -> String: return PacingSim.fmt_t(x)))])
	for k in range(1, CURVE_ROUNDS):
		runner.check(float(curve[k]) <= float(curve[k - 1]) + 15.0,
			"S8: round %d (%s) no slower than round %d (%s) + 0:15" % [k + 1, PacingSim.fmt_t(curve[k]), k, PacingSim.fmt_t(curve[k - 1])])
	for k in range(5, CURVE_ROUNDS):
		runner.check(float(curve[k]) <= 360.0, "S8: round %d at most 6:00, got %s" % [k + 1, PacingSim.fmt_t(curve[k])])
	for k in CURVE_ROUNDS:
		runner.check(float(curve[k]) >= 120.0, "S8: round %d keeps its content (≥ 2:00), got %s" % [k + 1, PacingSim.fmt_t(curve[k])])
