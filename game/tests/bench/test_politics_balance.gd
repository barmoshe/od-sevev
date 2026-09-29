extends RefCounted
## The money / suspicion / coalition triangle (pitch §10 DOG check), measured on the shipped
## content (design/content.json, through res://data/) by PacingSim playing the real Politics.
## One engaged hour per strategy (PacingSim.STRATEGIES):
##   - default: the attentive player (keeps cheap partners, postpones while cheap);
##   - payAll: pays every demand;
##   - alwaysPostpone / alwaysTestify;
##   - clean: never buys a shady source;
##   - aideDropper: drops the aide whenever it can.
## Gates, all falsifiable:
##   G1 no pure strategy beats the default's base-per-hour by more than 5% (no dominant strategy);
##   G2 the clean route is viable (≥ 2 elections an hour) but slower than the default;
##   G3 suspicion is live: the default sees at least one court day an hour;
##   G4 the coalition corner is live: partners walk out on payAll? no, on the default at least once
##      an hour, or the default's maintenance spend is ≥ 5% of what it earns.

const SEED := 11

var runner: Object
var _rows := {}


func _hour(name: String) -> Dictionary:
	if _rows.has(name):
		return _rows[name]
	var p: Dictionary = PacingSim.PLAYERS["engaged"].duplicate()
	p["politics"] = PacingSim.STRATEGIES[name]
	var r := PacingSim.session(p, 3600.0, SEED, 0.25)
	var s: GameState = r["state"]
	var runs: Array = r["runs"]
	var row := {
		"runs": runs.size(), "first": float(runs[0]) if not runs.is_empty() else -1.0, "base": s.thumbs_owned,
		"court": int(s.investigation.get("courtDays", 0)), "postpones": int(s.investigation.get("postponementsLifetime", 0)),
		"left": int(s.coalition.get("leftLifetime", 0)), "paid": int(s.coalition.get("paidLifetime", 0)),
		"drops": int(s.investigation.get("aideDrops", 0)), "runsList": runs,
	}
	print("  %-15s elections %2d | first %s | base %4d | court days %2d, postponed %2d | walked out %2d, paid %3d | aide drops %d | %s" % [
		name, row["runs"], PacingSim.fmt_t(row["first"]), row["base"], row["court"], row["postpones"], row["left"], row["paid"], row["drops"],
		", ".join(runs.slice(0, 6).map(func(x: float) -> String: return PacingSim.fmt_t(x)))])
	_rows[name] = row
	return row


func test_triangle_has_no_dominant_strategy() -> void:
	if not PacingSim.politics_on():
		print("  (content has no politics sections yet: skipped)")
		return
	print("  unimplemented spin effects (do nothing yet): %s" % str(Politics.unimplemented_effects()))
	var base := _hour("default")
	for name: String in PacingSim.STRATEGIES:
		if name == "default":
			continue
		var r := _hour(name)
		runner.check(float(r["base"]) <= float(base["base"]) * 1.05, "G1: %s must not dominate (base %d vs default %d)" % [name, r["base"], base["base"]])
	var clean := _hour("clean")
	runner.check(int(clean["runs"]) >= 2, "G2: the clean route is viable (%d elections an hour)" % clean["runs"])
	runner.check(int(clean["base"]) < int(base["base"]), "G2: and slower than dealing (base %d vs %d)" % [clean["base"], base["base"]])
	runner.check(int(base["court"]) >= 1, "G3: suspicion is live (court days an hour: %d)" % base["court"])
	runner.check(int(base["left"]) >= 1 or int(base["paid"]) >= 3 * int(base["runs"]), "G4: the coalition corner is live (walked out %d, paid %d)" % [base["left"], base["paid"]])
