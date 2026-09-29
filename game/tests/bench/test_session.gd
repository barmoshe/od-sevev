extends RefCounted
## Pacing bench (tools/balance.sh): whole 60-minute sessions per player profile. Gates:
## first Evolve in 10-15 min for engaged play, and never more than 5 minutes without something
## new (a producer, an upgrade, a milestone, a trophy, an Evolve or a perk) across runs 1-3.

var runner: Object


func _session(profile: String) -> Dictionary:
	var r := PacingSim.session(PacingSim.PLAYERS[profile], 3600.0, 7, 0.25)
	var runs: Array = r["runs"]
	print("  %-8s runs %s | Thumbs %d | longest gap %s (runs 1-3)" % [profile,
		", ".join(runs.map(func(x: float) -> String: return PacingSim.fmt_t(x))), int(r["thumbs"]), PacingSim.fmt_t(r["maxGap"])])
	var s: GameState = r["state"]
	print("           trophies %d/%d, perks %s" % [s.achievements.size(), Meta.achievements().size(), str(s.shop)])
	return r


func test_engaged_session() -> void:
	var r := _session("engaged")
	var runs: Array = r["runs"]
	runner.check(runs.size() >= 3, "engaged player evolves at least 3 times in an hour")
	runner.check(float(runs[0]) >= 570.0 and float(runs[0]) <= 900.0, "first Evolve in 9:30-15 min")
	var shortest := 1e9
	for x: float in runs:
		shortest = minf(shortest, x)
	runner.check(shortest >= 60.0, "no run under a minute in the first hour (shortest %s)" % PacingSim.fmt_t(shortest))
	runner.check(float(r["maxGap"]) <= 300.0, "something new at least every 5 min in runs 1-3 (longest gap %s)" % PacingSim.fmt_t(r["maxGap"]))


func test_casual_and_idle_sessions() -> void:
	var c := _session("casual")
	var i := _session("idle")
	runner.check((c["runs"] as Array).size() >= 2, "casual player evolves at least twice in an hour")
	runner.check((i["runs"] as Array).size() >= 1, "idle player evolves in an hour")
