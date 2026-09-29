class_name Meta
extends RefCounted
## v2 depth, pure: milestones, Troop Morale achievements, Thumb Perks and the automation they
## unlock. All numbers come from content.json (milestones, achievements, perks). Meta.install()
## registers the multiplier sources with Economy.derive(); everything else is a static helper the
## controller and the pacing bench both call, so the bench plays the same game as the player.

static var _installed := false


static func install() -> void:
	if _installed:
		return
	_installed = true
	Economy.MODIFIERS.append(_apply_modifiers)


static func _c() -> Dictionary:
	return Content.data()


# ---------------------------------------------------------------------------------------------
# Perks
# ---------------------------------------------------------------------------------------------

static func perks() -> Array:
	return _c().get("perks", {}).get("list", [])


static func perk(id: String) -> Dictionary:
	for p: Dictionary in perks():
		if p["id"] == id:
			return p
	return {}


static func perk_level(s: GameState, id: String) -> int:
	return int(s.shop.get(id, 0))


## The value of the perk's current level for an effect (0 when not owned).
static func effect_value(s: GameState, effect: String) -> float:
	for p: Dictionary in perks():
		if p["effect"] == effect:
			var lv := perk_level(s, p["id"])
			if lv <= 0:
				return 0.0
			return float((p["levels"] as Array)[mini(lv, (p["levels"] as Array).size()) - 1])
	return 0.0


static func has_effect(s: GameState, effect: String) -> bool:
	return effect_value(s, effect) > 0.0


static func next_cost(s: GameState, id: String) -> int:
	var p := perk(id)
	var lv := perk_level(s, id)
	var costs: Array = p.get("costs", [])
	return int(costs[lv]) if lv < costs.size() else -1


static func perk_maxed(s: GameState, id: String) -> bool:
	return next_cost(s, id) < 0


static func buy_perk(s: GameState, id: String) -> bool:
	var cost := next_cost(s, id)
	if cost < 0 or s.thumbs_available() < cost:
		return false
	s.thumbs_spent += cost
	s.shop[id] = perk_level(s, id) + 1
	return true


static func cheapest_perk_cost(s: GameState) -> int:
	var best := -1
	for p: Dictionary in perks():
		var c := next_cost(s, p["id"])
		if c >= 0 and (best < 0 or c < best):
			best = c
	return best


static func can_buy_any_perk(s: GameState) -> bool:
	var c := cheapest_perk_cost(s)
	return c >= 0 and s.thumbs_available() >= c


# ---------------------------------------------------------------------------------------------
# Milestones
# ---------------------------------------------------------------------------------------------

static func milestone_mult(owned: int) -> float:
	var m := 1.0
	for ms: Dictionary in _c().get("milestones", {}).get("perProducer", []):
		if owned >= int(ms["owned"]):
			m *= float(ms["mult"])
	return m


## The next per-producer milestone count above `owned` (-1 when past the last).
static func next_milestone(owned: int) -> int:
	for ms: Dictionary in _c().get("milestones", {}).get("perProducer", []):
		if owned < int(ms["owned"]):
			return int(ms["owned"])
	return -1


static func min_owned(s: GameState) -> int:
	var m := 1 << 30
	for id in Content.producer_ids():
		m = mini(m, s.owned_of(id))
	return m


static func all_producers_mult(s: GameState) -> float:
	var lo := min_owned(s)
	var m := 1.0
	for ms: Dictionary in _c().get("milestones", {}).get("allProducers", []):
		if lo >= int(ms["owned"]):
			m *= float(ms["mult"])
	return m


# ---------------------------------------------------------------------------------------------
# Achievements
# ---------------------------------------------------------------------------------------------

static func achievements() -> Array:
	return _c().get("achievements", {}).get("list", [])


static func achievement_pct(s: GameState) -> float:
	var spirit := effect_value(s, "achievementPct")
	return spirit / 100.0 if spirit > 0.0 else float(_c().get("achievements", {}).get("bonusPct", 0.0))


static func morale_mult(s: GameState) -> float:
	return 1.0 + achievement_pct(s) * s.achievements.size()


## Newly earned achievement ids (appends them to the state). Pass the frame's derived values.
static func check_achievements(s: GameState, d: Economy.Derived) -> PackedStringArray:
	var out := PackedStringArray()
	for a: Dictionary in achievements():
		if s.achievements.has(a["id"]):
			continue
		if _earned(s, d, a["trigger"]):
			s.achievements.append(a["id"])
			out.append(a["id"])
	return out


static func _earned(s: GameState, d: Economy.Derived, t: Dictionary) -> bool:
	var v := float(t.get("value", 0))
	match String(t["type"]):
		"tapsLifetime":
			return s.taps_lifetime >= v
		"critsLifetime":
			return s.crits_lifetime >= v
		"goldenCaughtLifetime":
			return s.golden_caught_lifetime >= v
		"allTimeBananas":
			return s.all_time_bananas >= v
		"bps":
			return d.bps >= v
		"owned":
			return s.owned_of(t["producer"]) >= v
		"ownedEach":
			return min_owned(s) >= v
		"evolutions":
			return s.evolutions >= v
		"allUpgradesInRun":
			return s.upgrades.size() >= Content.upgrades().size()
		"perksBought":
			return s.shop.size() >= v
		"fastestRunUnder":
			var f := float(s.stats.get("fastestRunSec", 0.0))
			return s.evolutions >= 1 and f > 0.0 and f < v
		"stat":
			return float(s.stats.get(t["key"], 0.0)) >= v
		"bananasAtOnce":
			return s.bananas >= v
	return false


static func achievement(id: String) -> Dictionary:
	for a: Dictionary in achievements():
		if a["id"] == id:
			return a
	return {}


# ---------------------------------------------------------------------------------------------
# Economy hooks
# ---------------------------------------------------------------------------------------------

static func _apply_modifiers(s: GameState, d: Economy.Derived) -> void:
	for id in Content.producer_ids():
		d.producer_mult[id] = float(d.producer_mult[id]) * milestone_mult(s.owned_of(id))
	d.global_mult *= all_producers_mult(s) * morale_mult(s)
	var sooner := effect_value(s, "goldenSoonerPct")
	if sooner > 0.0:
		d.golden_interval_mult *= 1.0 - sooner / 100.0
	var longer := effect_value(s, "buffLongerPct")
	if longer > 0.0:
		d.buff_duration_mult *= 1.0 + longer / 100.0


## Away-time parameters after the Longer Naps and Night Shift perks.
static func away_cap_sec(s: GameState) -> float:
	var h := effect_value(s, "offlineCapHours")
	return h * 3600.0 if h > 0.0 else float(_c()["offline"]["capSec"])


static func away_efficiency(s: GameState) -> float:
	var pct := effect_value(s, "offlineEfficiencyPct")
	return pct / 100.0 if pct > 0.0 else float(_c()["offline"]["efficiency"])


static func away_award(s: GameState, elapsed_sec: float) -> Dictionary:
	return Economy.away_award(s, elapsed_sec, away_cap_sec(s), away_efficiency(s))


## Evolve with the run-start perks (Head Start bananas, Tool Belt tap upgrades) and the
## union-buster stat. Use this instead of Economy.evolve() everywhere.
static func evolve(s: GameState) -> Dictionary:
	if s.owned_of(Content.producer_ids()[0]) == 0 and Economy.derive(s).evolve_enabled:
		s.stats["evolvedNoInterns"] = 1.0
	var keep := PackedStringArray()
	if has_effect(s, "keepTapUpgrades"):
		for uid in s.upgrades:
			var t: String = Content.upgrade(uid).get("effect", {}).get("type", "")
			if t in ["tapMult", "tapPctOfBps", "critChance"]:
				keep.append(uid)
	var r := Economy.evolve(s)
	if r.is_empty():
		return r
	s.upgrades = keep
	var start := effect_value(s, "startBananas")
	if start > 0.0:
		s.bananas = start
		s.run_bananas = start
	return r


# ---------------------------------------------------------------------------------------------
# Automation (unlocked by perks)
# ---------------------------------------------------------------------------------------------

static func auto_tap_rate(s: GameState) -> float:
	return effect_value(s, "autoTapPerSec")


## Banana Butler: buys one unit of the cheapest revealed producer when it costs no more than
## perks.butlerSpendFrac of the bank (pocket change). Returns its id.
static func auto_buy(s: GameState) -> String:
	if not has_effect(s, "autoBuy"):
		return ""
	var best := ""
	var best_cost := INF
	for id in Content.producer_ids():
		if not Economy.is_revealed(s, id):
			continue
		var c := Economy.producer_cost(s, id, 1)
		if c < best_cost:
			best_cost = c
			best = id
	var frac := float(_c().get("perks", {}).get("butlerSpendFrac", 1.0))
	if best != "" and best_cost <= s.bananas * frac:
		Economy.buy_producer(s, best, 1)
		return best
	return ""


static func auto_catch(s: GameState) -> bool:
	return has_effect(s, "autoCatch")
