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
	return _neutral("perks", _c().get("perks", {}).get("list", []))


static var _neutral_key := ""
static var _neutral_c: Dictionary = {}
static var _neutral_lists := {}

## Outside the default leader's round, the shared perks and trophies read
## leaderSelect.neutralCopy (spec §9): "perks.<id>.<field>" / "achievements.<id>.<field>" → the
## neutral text, so an opposition leader's shop never offers Bibi's wand or hat. Bibi's round (and
## content without leader select) keeps the shipped texts. Cached per installed leader and content.
static func _neutral(kind: String, list: Array) -> Array:
	var nc: Variant = Leaders.ls().get("neutralCopy", {})
	if not nc is Dictionary or (nc as Dictionary).is_empty() or Leaders.installed() == "" or Leaders.installed_default():
		return list
	var key := Leaders.installed()
	if key != _neutral_key or not is_same(_neutral_c, Content.data()):
		_neutral_key = key
		_neutral_c = Content.data()
		_neutral_lists = {}
	if _neutral_lists.has(kind):
		return _neutral_lists[kind]
	var out: Array = []
	for item: Variant in list:
		if not item is Dictionary:
			out.append(item)
			continue
		var d: Dictionary = item
		var copy := {}
		for field: String in ["name", "desc"]:
			var k := "%s.%s.%s" % [kind, str(d.get("id", "")), field]
			if (nc as Dictionary).has(k):
				copy[field] = (nc as Dictionary)[k]
		if copy.is_empty():
			out.append(d)
		else:
			var dd := d.duplicate()
			dd.merge(copy, true)
			out.append(dd)
	_neutral_lists[kind] = out
	return out


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
	if not Reveal.on(s, "perks"):
		return false
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
	if not Reveal.on(s, "perks"):
		return false
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
	return _neutral("achievements", _c().get("achievements", {}).get("list", []))


static func achievement_pct(s: GameState) -> float:
	var spirit := effect_value(s, "achievementPct")
	return spirit / 100.0 if spirit > 0.0 else float(_c().get("achievements", {}).get("bonusPct", 0.0))


static func morale_mult(s: GameState) -> float:
	return 1.0 + achievement_pct(s) * trophy_count(s)


## Earned trophies that count (for the bonus and `trophiesAtLeast`): a `neverAwarded` one never
## does, even if a hand-edited save lists it (Gantz's rotation, `fakeProgress` 0.99 forever).
static func trophy_count(s: GameState) -> int:
	var n := 0
	for id in s.achievements:
		if not achievement(id).get("neverAwarded", false):
			n += 1
	return n


## Newly earned achievement ids (appends them to the state). Pass the frame's derived values.
## Leader select: the shipped list plus the leader trophies (all_trophies); a trophy in
## leaderSelect.bibiOnly.trophies is earned only in Bibi's round.
static func check_achievements(s: GameState, d: Economy.Derived) -> PackedStringArray:
	var out := PackedStringArray()
	var bibi_only: Array = [] if Leaders.is_default(Leaders.current(s)) else Leaders.bibi_only("trophies")
	for a: Dictionary in all_trophies():
		if s.achievements.has(a["id"]) or a.get("neverAwarded", false) or bibi_only.has(a["id"]):
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
		"never":
			return false
		"leaderStat":
			return Leaders.stat(s, str(t.get("leader", "")), str(t.get("key", ""))) >= v
		"leadersPlayedAll":
			return Leaders.all_played(s)
	return false


## The shipped trophies (achievements()) plus the leader-select ones (Leaders.trophies: the two
## global ones and each pickable leader's kit.trophy). The dossier lists achievements() until the
## picker ships; the engine switches it to this list then.
static func all_trophies() -> Array:
	if not is_same(_all_src, _c()) or not is_same(_all_ach, achievements()):
		_all_src = _c()
		_all_ach = achievements()
		var lt := Leaders.trophies()
		_all = _all_ach if lt.is_empty() else _all_ach + lt
	return _all


static var _all_src: Dictionary = {}
static var _all_ach: Array = []
static var _all: Array = []


static func achievement(id: String) -> Dictionary:
	for a: Dictionary in all_trophies():
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


# ---------------------------------------------------------------------------------------------
# Trophy stats (GameState.stats; the designer's stat keys, STATUS.md designer ask (c))
# ---------------------------------------------------------------------------------------------

## Every stat key a trophy or headline reads. GameState.fresh() starts them at 0 so they persist
## through from_dict. Counted by the sim where it can see the act; the rest are the engine's
## (capHits, goldenMissed) or come through a sim hook the engine calls (wordSaladSeen:
## Story.roll_word_salad; tapsAt2to4: Politics.tick's clock).
const STATS := ["partnersPaid", "demandsPaid", "courtDays", "maxPostponesInRound", "pardonRequests", "aideDrops",
	"brawlsEnded", "corridorMessages", "gafniPaid", "cleanRounds", "wingOfZionBought", "streakRoundsUnder240s",
	"wordSaladSeen", "tapsAt2to4", "lapidCards", "capHits", "goldenMissed", "leaderSwitches",
	"pressDays", "hazardDays", "gantzFooled"]


static func bump(s: GameState, key: String, n: float = 1.0) -> void:
	s.stats[key] = float(s.stats.get(key, 0.0)) + n


static func stat_at_least(s: GameState, key: String, v: float) -> void:
	if v > float(s.stats.get(key, 0.0)):
		s.stats[key] = v


static var _count_src: Array = []
static var _count_size := -1
static var _count_index: Dictionary = {}


## Content-driven counters: a trophy or headline trigger {type: stat, key, <source>: id} counts
## every time that thing happens. Sources: countEvent (events[].id fired, "lapidCards"),
## countUpgrade (a spin bought, "wingOfZionBought"), countPartnerPaid (a partner paid, "gafniPaid").
static func count(s: GameState, source: String, id: String) -> void:
	var all: Array = [achievements(), _c().get("headlines", [])]
	if not is_same(all[0], _count_src) or (all[0] as Array).size() != _count_size:
		_count_src = all[0]
		_count_size = (all[0] as Array).size()
		_count_index = {}
		for list: Variant in all:
			for a: Variant in (list if list is Array else []):
				var tr: Variant = (a as Dictionary).get("trigger") if a is Dictionary else null
				if not tr is Dictionary or str((tr as Dictionary).get("type", "")) != "stat":
					continue
				for src: String in ["countEvent", "countUpgrade", "countPartnerPaid"]:
					if (tr as Dictionary).has(src):
						var k := "%s:%s" % [src, str(tr[src])]
						if not _count_index.has(k):
							_count_index[k] = []
						if not (_count_index[k] as Array).has(str(tr["key"])):
							(_count_index[k] as Array).append(str(tr["key"]))
	for key: String in _count_index.get("%s:%s" % [source, id], []):
		bump(s, key)


## Economy.evolve, before the run resets: the round-shaped stats.
##   cleanRounds            the round ended with no court.sources (shady) source ever owned
##                          (sources are never sold, so owning none at the end means none all round)
##   streakRoundsUnder240s  consecutive rounds each under 240 s; a slower round restarts the streak
##                          at 0 (the trophy fires at 5; the stat keeps the best streak reached)
static func on_round_end(s: GameState, run_sec: float) -> void:
	Leaders.on_round_end(s, run_sec)   # the leader's elections and best round
	if Investigation.active() and Investigation.shady_owned(s) == 0:
		bump(s, "cleanRounds")
	var cur := float(s.stats.get("streakUnder240sNow", 0.0))
	cur = cur + 1.0 if run_sec < 240.0 else 0.0
	s.stats["streakUnder240sNow"] = cur
	stat_at_least(s, "streakRoundsUnder240s", cur)


## A save from before these keys existed: lifetime counters the modules already kept seed their
## stat (never lower one). partnersPaid seeds from paid demands, the engine's old reading of it.
static func seed_stats(s: GameState) -> void:
	var paid := float(s.coalition.get("paidLifetime", 0))
	stat_at_least(s, "demandsPaid", paid)
	stat_at_least(s, "partnersPaid", minf(paid, float(Coalition.partners().size())) if paid > 0.0 else 0.0)
	stat_at_least(s, "courtDays", float(s.investigation.get("courtDays", 0)))
	stat_at_least(s, "pressDays", float(s.investigation.get("pressDays", 0)))
	stat_at_least(s, "hazardDays", float(s.investigation.get("courtDays", 0)) + float(s.investigation.get("pressDays", 0)))
	stat_at_least(s, "pardonRequests", float(s.investigation.get("pardons", 0)))
	stat_at_least(s, "aideDrops", float(s.investigation.get("aideDrops", 0)))
	stat_at_least(s, "corridorMessages", float(s.coalition.get("corridorMsgs", 0)))
