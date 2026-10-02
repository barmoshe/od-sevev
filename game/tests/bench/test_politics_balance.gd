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
##   G1 no pure strategy beats the default's base-per-hour by more than 5% in the MEDIAN of seeds
##      11-19 (no dominant strategy). One seed is one chaotic hour: on seed 11 alone the verdict
##      flipped with unrelated changes (before the leader sim the aide dropper lost by 42% on
##      seed 11 and won by 38% on seed 13; after the p_deal perk started working it won by 52% on
##      seed 11 and lost by 8% on seed 12). "Dominant" means better in most hours, so the median
##      of the per-seed ratios is the gate; G2-G4 stay on seed 11;
##   G2 the clean route is viable (≥ 2 elections an hour) but slower than the default;
##   G3 suspicion is live: the default sees at least one court day an hour;
##   G4 the coalition corner is live: partners walk out on payAll? no, on the default at least once
##      an hour, or the default's maintenance spend is ≥ 5% of what it earns.

const SEED := 11
const G1_SEEDS := [11, 12, 13, 14, 15, 16, 17, 18, 19]   # 9 hours: one is chaotic (2026-10-02 probes)

var runner: Object
var _rows := {}


func _hour(name: String, seed_: int = SEED) -> Dictionary:
	var key := "%s:%d" % [name, seed_]
	if _rows.has(key):
		return _rows[key]
	var p: Dictionary = PacingSim.PLAYERS["engaged"].duplicate()
	p["politics"] = PacingSim.STRATEGIES[name]
	var r := PacingSim.session(p, 3600.0, seed_, 0.25)
	var s: GameState = r["state"]
	var runs: Array = r["runs"]
	var row := {
		"runs": runs.size(), "first": float(runs[0]) if not runs.is_empty() else -1.0, "base": s.thumbs_owned,
		"court": int(s.investigation.get("courtDays", 0)), "postpones": int(s.investigation.get("postponementsLifetime", 0)),
		"left": int(s.coalition.get("leftLifetime", 0)), "paid": int(s.coalition.get("paidLifetime", 0)),
		"drops": int(s.investigation.get("aideDrops", 0)), "runsList": runs,
	}
	print("  %-15s s%d elections %2d | first %s | base %4d | court days %2d, postponed %2d | walked out %2d, paid %3d | aide drops %d | %s" % [
		name, seed_, row["runs"], PacingSim.fmt_t(row["first"]), row["base"], row["court"], row["postpones"], row["left"], row["paid"], row["drops"],
		", ".join(runs.slice(0, 6).map(func(x: float) -> String: return PacingSim.fmt_t(x)))])
	_rows[key] = row
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
		var ratios: Array = []
		for sd: int in G1_SEEDS:
			ratios.append(float(_hour(name, sd)["base"]) / maxf(1.0, float(_hour("default", sd)["base"])))
		var sorted := ratios.duplicate()
		sorted.sort()
		var med := float(sorted[sorted.size() / 2])
		print("  G1 %-15s base / default per seed %s: median %.2f" % [name, ", ".join(ratios.map(func(x: float) -> String: return "%.2f" % x)), med])
		runner.check(med <= 1.05, "G1: %s must not dominate (median base ratio %.2f over seeds 11-19)" % [name, med])
	var clean := _hour("clean")
	runner.check(int(clean["runs"]) >= 2, "G2: the clean route is viable (%d elections an hour)" % clean["runs"])
	runner.check(int(clean["base"]) < int(base["base"]), "G2: and slower than dealing (base %d vs %d)" % [clean["base"], base["base"]])
	runner.check(int(base["court"]) >= 1, "G3: suspicion is live (court days an hour: %d)" % base["court"])
	runner.check(int(base["left"]) >= 1 or int(base["paid"]) >= 3 * int(base["runs"]), "G4: the coalition corner is live (walked out %d, paid %d)" % [base["left"], base["paid"]])
