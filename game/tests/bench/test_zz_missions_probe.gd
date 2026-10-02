extends RefCounted
## SCRATCH probe (not committed): mission claim times over a long median session.

var runner: Object


func test_probe() -> void:
	for prof in ["median", "idle"]:
		var pl: Dictionary = PacingSim.PLAYERS[prof].duplicate()
		pl["log_missions"] = true
		var r := PacingSim.session(pl, 7200.0, 7, 0.25)
		var runs: Array = r["runs"]
		print("%s runs %s" % [prof, ", ".join(runs.map(func(x: float) -> String: return PacingSim.fmt_t(x)))])
		var el := 0.0
		var line := ""
		var last := 0.0
		for e: Array in r["events"]:
			var w := str(e[1])
			if w == "evolve":
				line += " | E@%s" % PacingSim.fmt_t(float(e[0]))
			elif w.begins_with("mission:"):
				line += "\n   %s (+%s) %s" % [PacingSim.fmt_t(float(e[0])), PacingSim.fmt_t(float(e[0]) - last), w.substr(8)]
				last = float(e[0])
		print(line)
		var s: GameState = r["state"]
		print("  rank %d, claimed %d, income +%d%%" % [Missions.rank(s), (s.missions["claimed"] as Array).size(), int(Missions.income_pct(s))])
		print("  slots: ", JSON.stringify(Missions.slots_view(s)))
