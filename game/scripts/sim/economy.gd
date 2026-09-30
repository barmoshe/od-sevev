class_name Economy
extends RefCounted
## Pure economy rules (design/mechanic-spec.md §2, progression-curve.md). No nodes.
## Every number comes from content.json through Content. Ported from the v1.1 src/core/economy.ts
## with the audit fixes: closed-form max-affordable, id-keyed producers, one derive per call site,
## and handler registries instead of hard-coded switches (lab research.md §1).

const MAX := 1.7976931348623157e308


class Derived:
	extends RefCounted
	var prestige_mult := 1.0
	var tap_mult := 1.0
	var tap_pct_of_bps := 0.0
	var crit_chance := 0.0
	var golden_interval_mult := 1.0
	var golden_life_mult := 1.0
	var buff_duration_mult := 1.0
	var global_mult := 1.0
	var producer_mult: Dictionary = {}      # id -> mult (upgrades × milestones)
	var producer_bps: Dictionary = {}       # id -> bps this producer adds, frenzy excluded
	var bps := 0.0                          # WITHOUT frenzy (tapPctOfBps, offline, Lucky Bunch)
	var frenzy_mult := 1.0
	var tap_frenzy_mult := 1.0
	var bps_effective := 0.0                # what actually accrues per second
	var tap_value_no_crit := 0.0
	var thumbs_total := 0
	var pending := 0
	var needed := 0
	var evolve_enabled := false
	# od-sevev (content v3 schema + politics; Coalition, Investigation, Events set these)
	var tap_add := 0.0                      # + base tap value (spin S01 "tapAdd")
	var base_mult := 1.0                    # × the base multiplier (aide drops: court.aideDrop.baseMultPenalty)
	var base_pct_round := 0.0               # + % on this round's base payout (S13, S08, "basePctThisRound")
	var bps_mult := 1.0                     # × producer income (court day)
	var income_mult := 1.0                  # × all income, taps included (court day, courtDay.incomeMult)
	var offline_mult := 1.0                 # × away income (S03 "offlineMult")
	var suspicion_gain_mult := 1.0          # × suspicion gain (S04, Levin)
	var taps_paused := false                # court day with courtDay.pausesTaps
	var no_crit := false                    # Eisenkot's card: no rabbits while it is up
	var seats_gate_open := true             # Coalition.gate_open(): the seat gate (true without a coalition)
	var tap_pour_sec := 0.0                 # S07 "idleToTap": income stops, each tap pours bps × this (Spins)
	var straight_mult := 1.0                # Eisenkot's "ישר": taps × the crits' expected value, crits 0 (Leaders)


## Upgrade effect handlers: effect.type -> func(effect: Dictionary, d: Derived). Adding an effect
## type is one entry here plus data in content.json.
static var EFFECTS: Dictionary = {
	"tapMult": func(e: Dictionary, d: Derived) -> void: d.tap_mult *= float(e["mult"]),
	"tapPctOfBps": func(e: Dictionary, d: Derived) -> void: d.tap_pct_of_bps += float(e["add"]),
	"critChance": func(e: Dictionary, d: Derived) -> void:
		if e.has("set"):
			d.crit_chance = maxf(d.crit_chance, float(e["set"]))
		d.crit_chance += float(e.get("add", 0.0)),
	"goldenIntervalMult": func(e: Dictionary, d: Derived) -> void: d.golden_interval_mult *= float(e["mult"]),
	"goldenLifeMult": func(e: Dictionary, d: Derived) -> void: d.golden_life_mult *= float(e["mult"]),
	"globalMult": func(e: Dictionary, d: Derived) -> void: d.global_mult *= float(e["mult"]),
	"producerMult": func(e: Dictionary, d: Derived) -> void:
		var id: String = e["producer"]
		d.producer_mult[id] = float(d.producer_mult.get(id, 1.0)) * float(e["mult"]),
	# od-sevev: usable by spins and by partners' `effects` (Coalition applies them while counting)
	"suspicionGainMult": func(e: Dictionary, d: Derived) -> void: d.suspicion_gain_mult *= float(e["mult"]),
	"baseMult": func(e: Dictionary, d: Derived) -> void: d.base_mult *= float(e["mult"]),
	"bpsMult": func(e: Dictionary, d: Derived) -> void: d.bps_mult *= float(e["mult"]),
	"tapAdd": func(e: Dictionary, d: Derived) -> void: d.tap_add += float(e.get("add", 0.0)),
	"offlineMult": func(e: Dictionary, d: Derived) -> void: d.offline_mult *= float(e.get("mult", 1.0)),
	"basePctThisRound": func(e: Dictionary, d: Derived) -> void: d.base_pct_round += float(e.get("pct", 0.0)),
}

## Effect types that act once when bought (not a passive modifier): type -> func(s, e). The
## passive EFFECTS above ignore them; buy_upgrade() calls these.
static var ON_BUY: Dictionary = {
	"suspicionFreeze": func(s: GameState, e: Dictionary) -> void: Investigation.freeze(s, float(e.get("durationSec", 60.0))),
	"wipeSourceSuspicion": func(s: GameState, _e: Dictionary) -> void: Investigation.to_floor(s),
}

## Effect types the content may use that no handler implements yet (reported once, never silent).
static var _warned: Dictionary = {}

## Upgrade unlock conditions: key in upgrade.unlock -> func(value, s: GameState) -> bool (all must pass).
## od-sevev: any other key is looked up in the shared Conditions vocabulary (era, shadyOwnedAtLeast, …).
static var UNLOCKS: Dictionary = {
	"runBananasAtLeast": func(v: Variant, s: GameState) -> bool: return s.run_bananas >= float(v),
	"goldenCaughtLifetimeAtLeast": func(v: Variant, s: GameState) -> bool: return s.golden_caught_lifetime >= int(v),
	"ownedAtLeast": func(v: Variant, s: GameState) -> bool: return s.owned_of(v["producer"]) >= int(v["count"]),
	"evolutionsAtLeast": func(v: Variant, s: GameState) -> bool: return s.evolutions >= int(v),
}


## Mechanic E3: never INF or NaN. Clamp to the largest double and keep running.
static func clampf_num(v: float) -> float:
	if is_nan(v):
		return 0.0
	if is_inf(v):
		return MAX if v > 0.0 else 0.0
	return v


static func add_bananas(s: GameState, n: float) -> void:
	if not (n > 0.0):
		return
	s.bananas = clampf_num(s.bananas + n)
	s.run_bananas = clampf_num(s.run_bananas + n)
	s.all_time_bananas = clampf_num(s.all_time_bananas + n)


static func thumbs_for(all_time: float) -> int:
	var p := _payout()
	var root := float(p.get("rootDegree", 3))
	var v := pow(maxf(0.0, all_time) / float(p.get("divisor", 1000)), 1.0 / root) + float(p.get("epsilon", 1e-9))
	return int(minf(floorf(v), 9.0e15))


# ---- prestige schema (the fork's all-time Thumbs, or od-sevev's per-round base behind a seat gate) ----

static func _prestige() -> Dictionary:
	return Content.data()["prestige"]


## prestige.payout (od-sevev) or prestige itself (the fork): rootDegree, divisor, epsilon, scope.
static func _payout() -> Dictionary:
	var p := _prestige()
	var po: Variant = p.get("payout")
	return po if po is Dictionary else p


## "round": the base paid by an election is cbrt(this round's earnings / divisor) (od-sevev).
## Otherwise the fork's rule: Thumbs earned over all time, minus those owned.
static func round_scope() -> bool:
	return str(_payout().get("scope", "")) == "round"


## prestige.gate.type "seats": "עוד סבב!" is gated on the coalition's seats (Coalition.gate_open).
static func seats_gated() -> bool:
	var g: Variant = _prestige().get("gate")
	return g is Dictionary and str((g as Dictionary).get("type", "")) == "seats"


static func mult_per_base() -> float:
	var p := _prestige()
	return float(p.get("multPerBase", p.get("multPerThumb", 0.1)))


## This round's base payout: floor(cbrt(runEarned / divisor) + ε) × (1 + basePctThisRound / 100).
static func round_payout(s: GameState, base_pct: float) -> int:
	var p := _payout()
	var root := float(p.get("rootDegree", 3))
	var v := floorf(pow(maxf(0.0, s.run_bananas) / float(p.get("divisor", 1000)), 1.0 / root) + float(p.get("epsilon", 1e-9)))
	return int(minf(floorf(v * (1.0 + base_pct / 100.0)), 9.0e15))


## The most base a save could honestly hold (the load clamp on a hand-edited save). All-time scope:
## exactly thumbs_for(all_time). Round scope: Σ cbrt(r_i) ≤ n^(1-1/root) × cbrt(Σ r_i) (concavity),
## doubled for the payout bonuses, plus one per round for the opposition-card base.
static func base_cap(all_time: float, rounds: int) -> int:
	if not round_scope():
		return thumbs_for(all_time)
	var p := _payout()
	var root := float(p.get("rootDegree", 3))
	var n := maxf(1.0, float(rounds))
	var v := pow(n, 1.0 - 1.0 / root) * pow(maxf(0.0, all_time) / float(p.get("divisor", 1000)), 1.0 / root)
	return int(minf(ceilf(2.0 * v) + 50.0 * n, 9.0e15))


## Extra multiplier sources beyond upgrades (milestones, achievements, the Thumbs shop). Each is
## func(s: GameState, d: Derived). Meta.gd registers its own here, so this file stays v1-pure.
static var MODIFIERS: Array[Callable] = []


static func derive(s: GameState) -> Derived:
	var c := Content.data()
	var p: Dictionary = c["prestige"]
	Meta.install()
	Spins.install()
	Politics.install(s)   # the round's leader: lineup, rivals, rule (cheap when unchanged)
	var d := Derived.new()
	d.crit_chance = float(c["tap"]["critChance"])
	for id in Content.producer_ids():
		d.producer_mult[id] = 1.0
	for uid in s.upgrades:
		var u := Content.upgrade(uid)
		if u.is_empty():
			continue
		var e: Dictionary = u["effect"]
		var h: Variant = EFFECTS.get(e["type"])
		if h != null:
			(h as Callable).call(e, d)
		elif not ON_BUY.has(e["type"]) and not Spins.TYPES.has(e["type"]) and not _warned.has(e["type"]):
			_warned[e["type"]] = true
			push_warning("[economy] upgrade effect type '%s' has no handler yet (upgrade %s): it does nothing" % [e["type"], uid])
	for m in MODIFIERS:
		m.call(s, d)
	d.prestige_mult = (1.0 + mult_per_base() * s.thumbs_owned) * d.base_mult
	if Leaders.straight():
		# Eisenkot (straightTaps): no crits; every tap is paid their average up front,
		# × (1 + c × (critMult − 1)) for the round's crit chance c. A noCrit card suspends it.
		d.straight_mult = 1.0 if d.no_crit else 1.0 + maxf(0.0, d.crit_chance) * (float(c["tap"]["critMult"]) - 1.0)
		d.tap_mult *= d.straight_mult
		d.crit_chance = 0.0
	if d.no_crit:
		d.crit_chance = 0.0
	var raw := 0.0
	var inc := d.global_mult * d.prestige_mult * maxf(0.0, d.bps_mult) * maxf(0.0, d.income_mult)
	for pr: Dictionary in Content.producers():
		var id: String = pr["id"]
		var add := float(pr["baseBps"]) * s.owned_of(id) * float(d.producer_mult[id])
		d.producer_bps[id] = clampf_num(add * inc)
		raw += add
	d.bps = clampf_num(raw * inc)
	d.frenzy_mult = float(Content.outcome_of_type("bpsFrenzy").get("mult", 1.0)) if s.buff_frenzy > 0.0 else 1.0
	d.tap_frenzy_mult = float(Content.outcome_of_type("tapFrenzy").get("mult", 1.0)) if s.buff_tap_frenzy > 0.0 else 1.0
	d.bps_effective = clampf_num(d.bps * d.frenzy_mult)
	# tapValue = ((baseValue + tapAdd) × tapMult × prestigeMult + (pctOfBpsBase + tapPctOfBps) × bps)
	#            × tapFrenzy. Court day's incomeMult is already inside bps; the base part takes it here.
	var base_tap := float(c["tap"]["baseValue"]) + d.tap_add
	var pct := d.tap_pct_of_bps + float(c["tap"].get("pctOfBpsBase", 0.0))
	d.tap_value_no_crit = clampf_num((base_tap * d.tap_mult * d.prestige_mult * maxf(0.0, d.income_mult) + pct * d.bps) * d.tap_frenzy_mult)
	if d.tap_pour_sec > 0.0:
		# S07: the passive income is poured into the taps instead (tapValue + bps × pourSecPerTap).
		d.bps_effective = 0.0
		d.tap_value_no_crit = clampf_num(d.tap_value_no_crit + d.tap_pour_sec * d.bps)
	# d.seats_gate_open: true by default; Coalition's modifier sets it (== Coalition.gate_open(s)).
	if round_scope():
		d.pending = round_payout(s, d.base_pct_round)
		d.thumbs_total = s.thumbs_owned + d.pending
		d.needed = maxi(1, int(_payout().get("minGain", 1)))
	else:
		d.thumbs_total = thumbs_for(s.all_time_bananas)
		d.pending = maxi(0, d.thumbs_total - s.thumbs_owned)
		d.needed = maxi(int(p.get("minPendingFloor", 1)), ceili(float(p.get("minPendingRatioOfOwned", 0.0)) * s.thumbs_owned))
	d.evolve_enabled = d.pending >= d.needed and d.seats_gate_open
	return d


## The fork shows the Evolve button from an all-time total; od-sevev's gold "עוד סבב!" replaces the
## ticker the moment the seat gate opens (UX E1).
static func evolve_visible(s: GameState) -> bool:
	if s.ui.get("evolveRevealed", false):
		return true
	if seats_gated():
		return Coalition.gate_open(s)
	return s.all_time_bananas >= float(_prestige().get("showEvolveButtonAtAllTimeBananas", 0.0))


# ---------------------------------------------------------------------------------------------
# Time
# ---------------------------------------------------------------------------------------------

## Advances production, buff timers and run time by dt seconds. Returns which buffs just ended.
static func tick(s: GameState, dt: float, d: Derived = null) -> Dictionary:
	if d == null:
		d = derive(s)
	add_bananas(s, d.bps_effective * dt)
	s.run_time_sec += dt
	s.stats["playtimeSec"] = float(s.stats.get("playtimeSec", 0.0)) + dt
	Leaders.on_play(s, dt)
	if d.bps > float(s.stats.get("bestBps", 0.0)):
		s.stats["bestBps"] = d.bps
	var ev := {"frenzyEnded": false, "tapFrenzyEnded": false, "spinsEnded": Spins.tick(s, dt)}
	if s.buff_frenzy > 0.0:
		s.buff_frenzy = maxf(0.0, s.buff_frenzy - dt)
		ev["frenzyEnded"] = s.buff_frenzy == 0.0
	if s.buff_tap_frenzy > 0.0:
		s.buff_tap_frenzy = maxf(0.0, s.buff_tap_frenzy - dt)
		ev["tapFrenzyEnded"] = s.buff_tap_frenzy == 0.0
	return ev


## Golden spawn timer. The caller only ticks it while visible and no modal is open.
static func tick_golden_timer(s: GameState, dt: float) -> bool:
	s.golden_timer_sec -= dt
	return s.golden_timer_sec <= 0.0


static func schedule_next_golden(s: GameState, rng: Callable = randf) -> void:
	var g: Dictionary = Content.data()["golden"]
	var lo := float(g["spawnIntervalMinSec"])
	var hi := float(g["spawnIntervalMaxSec"])
	s.golden_timer_sec = (lo + (hi - lo) * float(rng.call())) * derive(s).golden_interval_mult


static func golden_lifetime(s: GameState) -> float:
	return float(Content.data()["golden"]["lifetimeSec"]) * derive(s).golden_life_mult


# ---------------------------------------------------------------------------------------------
# Tap
# ---------------------------------------------------------------------------------------------

## A registered tap: award on pointer-down (mechanic rule 1). Returns {value, crit}.
## od-sevev: on a court day taps register nothing and return {value: 0, crit: false, paused: true}.
## od-sevev tap.firstCrit {atTap, mult, randomCritsFromTap}: the scripted first rabbit on lifetime tap
## atTap in round 1 pays ×mult, and random rabbits start at randomCritsFromTap (pitch §11 Q5).
static func tap(s: GameState, rng: Callable = randf) -> Dictionary:
	var d := derive(s)
	if d.taps_paused:
		return {"value": 0.0, "crit": false, "paused": true}
	var t: Dictionary = Content.data()["tap"]
	var roll := float(rng.call())
	var crit := roll < d.crit_chance
	var cm := float(t["critMult"])
	var fc: Variant = t.get("firstCrit")
	var tap7 := false
	if fc is Dictionary and Leaders.straight():
		# Eisenkot has no crits, the scripted tap-7 rabbit included: the result flags tap7 and the
		# view shows rule.copy.tap7 with his react.
		tap7 = s.evolutions == 0 and s.crits_lifetime == 0 and s.taps_lifetime + 1 == int(fc.get("atTap", 0))
		fc = null
	if fc is Dictionary:
		var n := s.taps_lifetime + 1
		if s.evolutions == 0 and s.crits_lifetime == 0 and n == int(fc.get("atTap", 0)):
			crit = true
			cm = float(fc.get("mult", cm))
		elif n < int(fc.get("randomCritsFromTap", 0)):
			crit = false
	# A rabbit multiplies the tap, never S07's pour (the pour is income moved, not earned by the tap).
	var pour := d.tap_pour_sec * d.bps
	var value := clampf_num((d.tap_value_no_crit - pour) * (cm if crit else 1.0) + pour)
	add_bananas(s, value)
	s.run_taps += 1
	s.taps_lifetime += 1
	if crit:
		s.crits_lifetime += 1
	Leaders.on_tap(s, crit)   # the leader's taps / crits; the first tap closes the picker
	if tap7:
		return {"value": value, "crit": false, "tap7": true}
	return {"value": value, "crit": crit}


# ---------------------------------------------------------------------------------------------
# Producers
# ---------------------------------------------------------------------------------------------

## content.json bulkCostFormula: baseCost × g^owned × (g^n − 1) / (g − 1).
static func producer_cost(s: GameState, id: String, n: int) -> float:
	var p := Content.producer(id)
	var g := float(p["costGrowth"])
	return clampf_num(float(p["baseCost"]) * pow(g, s.owned_of(id)) * (pow(g, n) - 1.0) / (g - 1.0))


## Closed form (geometric series), then a bounded float-edge correction. v1 looped up to 1e6
## times per row per frame once the bank hit the double ceiling.
static func max_affordable(s: GameState, id: String) -> int:
	var p := Content.producer(id)
	var g := float(p["costGrowth"])
	var unit := float(p["baseCost"]) * pow(g, s.owned_of(id))
	if is_inf(unit) or unit >= MAX or s.bananas < unit:
		return 0
	var n := int(minf(floorf(log(s.bananas * (g - 1.0) / unit + 1.0) / log(g)), 1.0e6))
	var guard := 0
	while n > 0 and producer_cost(s, id, n) > s.bananas and guard < 4:
		n -= 1
		guard += 1
	guard = 0
	while producer_cost(s, id, n + 1) <= s.bananas and guard < 4 and n < 1000000:
		n += 1
		guard += 1
	return maxi(n, 0)


## What a commit on a row buys in a buy mode. MAX with nothing affordable quotes 1 unit.
static func quote(s: GameState, id: String, mode: Variant = null) -> Dictionary:
	if mode == null:
		mode = s.buy_mode
	if mode is String and mode == "max":
		var n := max_affordable(s, id)
		if n == 0:
			return {"qty": 1, "cost": producer_cost(s, id, 1), "affordable": false}
		return {"qty": n, "cost": producer_cost(s, id, n), "affordable": true}
	var q := int(mode)
	var cost := producer_cost(s, id, q)
	return {"qty": q, "cost": cost, "affordable": s.bananas >= cost}


static func buy_producer(s: GameState, id: String, mode: Variant = null) -> Dictionary:
	var q := quote(s, id, mode)
	if not q["affordable"]:
		return {}
	s.bananas = maxf(0.0, s.bananas - float(q["cost"]))
	var before := s.owned_of(id)
	s.owned[id] = before + int(q["qty"])
	Investigation.on_buy(s, id, int(q["qty"]), before)   # shady sources feed suspicion per unit
	return q


static func is_revealed(s: GameState, id: String) -> bool:
	var p := Content.producer(id)
	if p.has("revealAtRunEarned"):
		return s.owned_of(id) > 0 or s.run_bananas >= float(p["revealAtRunEarned"])
	var frac := float(Content.data()["producerReveal"]["revealAtRunBananasFracOfBaseCost"])
	return s.owned_of(id) > 0 or s.run_bananas >= frac * float(p["baseCost"])


## Revealed producer ids in tier order, the single silhouette id ("" if none: a real row with its
## price), and `fill`: every later unrevealed id when producerReveal.fillSilhouettes is on (UX
## mobile-first-layout §5.4, G1: priceless, untappable rows that fill the pane; never past the
## content's last source). Merge review M2: the fill keys on "card 1 is shown" (`card1_shown`, the
## pane is up), not only on a source revealed by money, so a round begun with an empty purse never
## shows a lone locked row over an empty pane.
static func producer_rows(s: GameState, card1_shown := false) -> Dictionary:
	var revealed := PackedStringArray()
	var silhouette := ""
	var fill := PackedStringArray()
	var pr: Dictionary = Content.data()["producerReveal"]
	var show_sil: bool = pr["showNextAsSilhouette"]
	var fill_on: bool = pr.get("fillSilhouettes", false) == true
	for id in Content.producer_ids():
		if is_revealed(s, id):
			revealed.append(id)
		elif silhouette == "" and show_sil:
			silhouette = id
		elif fill_on:
			fill.append(id)
	if revealed.is_empty() and not card1_shown:
		fill = PackedStringArray()
	return {"revealed": revealed, "silhouette": silhouette, "fill": fill}


# ---------------------------------------------------------------------------------------------
# Upgrades
# ---------------------------------------------------------------------------------------------

static func upgrade_unlocked(s: GameState, u: Dictionary) -> bool:
	var k: Dictionary = u.get("unlock", {})
	for key: String in k:
		var h: Variant = UNLOCKS.get(key)
		if h != null:
			if not (h as Callable).call(k[key], s):
				return false
		elif not Conditions.ok(s, {key: k[key]}):
			return false
	return true


## The shelf: unlocked and on the shelf by kind (Spins.on_shelf: a once spin until bought, a
## consumable while its effect isn't live, a line until its last level), sorted by cost (stable).
static func available_upgrades(s: GameState) -> Array:
	var out: Array = []
	var i := 0
	for u: Dictionary in Content.upgrades():
		if Spins.on_shelf(s, u) and upgrade_unlocked(s, u):
			out.append([u, i])
		i += 1
	out.sort_custom(func(a: Array, b: Array) -> bool:
		return float(a[0]["cost"]) < float(b[0]["cost"]) or (float(a[0]["cost"]) == float(b[0]["cost"]) and int(a[1]) < int(b[1])))
	return out.map(func(x: Array) -> Dictionary: return x[0])


static func affordable_upgrade_count(s: GameState) -> int:
	var n := 0
	for u: Dictionary in available_upgrades(s):
		var p := Spins.price(s, u)   # derives only for a costBpsSeconds spin
		if p >= 0.0 and s.bananas >= p:
			n += 1
	return n


## What the spin costs now: `cost`, a line's next level, or a consumable's costBpsSeconds price
## (-1: nothing left to buy). The card's price pill should read this, not `u.cost`.
static func upgrade_price(s: GameState, id: String, d: Derived = null) -> float:
	var u := Content.upgrade(id)
	return -1.0 if u.is_empty() else Spins.price(s, u, d)


## Whether buy_upgrade would succeed now (the pill's gold state).
static func can_buy_upgrade(s: GameState, id: String) -> bool:
	var u := Content.upgrade(id)
	if u.is_empty() or not Spins.on_shelf(s, u) or not upgrade_unlocked(s, u):
		return false
	var p := Spins.price(s, u)
	return p >= 0.0 and s.bananas >= p


static func buy_upgrade(s: GameState, id: String) -> bool:
	if not can_buy_upgrade(s, id):
		return false
	var u := Content.upgrade(id)
	s.bananas = maxf(0.0, s.bananas - Spins.price(s, u))
	s.upgrades_bought_lifetime += 1
	Spins.on_bought(s, u)
	Meta.count(s, "countUpgrade", id)
	var fu: Variant = u.get("followUp")
	if fu is Dictionary and (fu as Dictionary).has("fallbackAfterSec") and Leaders.upgrade_follow_up_allowed(id):
		Events.follow_up(s, id, float(fu["fallbackAfterSec"]))   # S13: next morning's invoice
	return true


# ---------------------------------------------------------------------------------------------
# Golden Banana
# ---------------------------------------------------------------------------------------------

## od-sevev: pass the state so outcomes tagged `era` (the Washington laundry) only roll in that era.
## od-sevev (with the state): golden.firstOutcome for the first catch; outcomes tagged `eraOnly` /
## `era` roll only in that era and push out the outcome they `replaces` (the Washington laundry
## replaces the frenzy); `requires` is a condition (the aide needs a shady source).
static func roll_golden_outcome(rng: Callable = randf, s: GameState = null) -> String:
	var g: Dictionary = Content.data()["golden"]
	var outs: Array = g["outcomes"]
	if s != null:
		Leaders.ensure(s)
		if s.golden_caught_lifetime == 0 and g.has("firstOutcome") and Content.has_outcome(str(g["firstOutcome"])):
			return str(g["firstOutcome"])
		var era: String = Story.era_for(s.evolutions).get("id", "")
		outs = outs.filter(func(o: Dictionary) -> bool:
			var only := str(o.get("eraOnly", o.get("era", "")))
			return (only == "" or only == era) and Conditions.ok(s, o.get("requires", {})))
		var gone := {}
		for o: Dictionary in outs:
			if o.has("replaces"):
				gone[o["replaces"]] = true
		outs = outs.filter(func(o: Dictionary) -> bool: return not gone.has(o["id"]))
		outs = Leaders.filter_outcomes(outs)   # outside Bibi's round: no aide / laundry, cash takes their weight
		if outs.is_empty():
			outs = g["outcomes"]
	var total := 0.0
	for o: Dictionary in outs:
		total += float(o["weight"])
	var r := float(rng.call()) * total
	for o: Dictionary in outs:
		r -= float(o["weight"])
		if r < 0.0:
			return o["id"]
	return outs[outs.size() - 1]["id"]


## Applies a caught Golden. The same buff refreshes its timer and never stacks (E5).
## Returns the Lucky Bunch award (0 for the buffs).
static func apply_golden(s: GameState, id: String) -> float:
	var o := Content.outcome(id)
	var dur_mult := derive(s).buff_duration_mult
	s.golden_caught_lifetime += 1
	Spins.on_golden_caught(s)   # S10: a caught Suitcase is a flight
	var kind := Content.outcome_type(id)   # od-sevev: dispatch on the data type, not the id
	if kind == "instant":
		var d := derive(s)
		var award := clampf_num(maxf(float(o.get("bunchBpsSeconds", 0)) * d.bps, float(o.get("bunchMinTaps", 0)) * d.tap_value_no_crit))
		add_bananas(s, award)
		if o.get("parksOnAide", o.get("aide", false)) == true:
			Investigation.aide_catch(s, award, float(o.get("suspicionAdd", -1.0)))   # deck §G: the money lands on an aide's card
		return award
	if kind == "bpsFrenzy":
		s.buff_frenzy = float(o.get("durationSec", 0)) * dur_mult
	else:
		s.buff_tap_frenzy = float(o.get("durationSec", 0)) * dur_mult
	return 0.0


# ---------------------------------------------------------------------------------------------
# Evolve
# ---------------------------------------------------------------------------------------------

static func reset_run(s: GameState) -> void:
	s.bananas = 0.0
	s.run_bananas = 0.0
	for id in Content.producer_ids():
		s.owned[id] = 0
	s.upgrades = PackedStringArray()
	s.run_taps = 0
	s.buff_frenzy = 0.0
	s.buff_tap_frenzy = 0.0
	s.golden_timer_sec = float(Content.data()["golden"]["firstSpawnDelaySec"])
	s.evolve_ready_announced = false
	s.run_time_sec = 0.0
	Spins.reset_round(s)


## Mechanic rule 8. Returns {} when the gate is closed (idempotent per dialog, E7).
static func evolve(s: GameState) -> Dictionary:
	var d := derive(s)
	if not d.evolve_enabled:
		return {}
	var mult_before := d.prestige_mult
	var run_sec := s.run_time_sec
	var fastest := float(s.stats.get("fastestRunSec", 0.0))
	if fastest <= 0.0 or run_sec < fastest:
		s.stats["fastestRunSec"] = run_sec
	Meta.on_round_end(s, run_sec)   # the round's trophy stats, before the run resets
	s.thumbs_owned += d.pending
	s.evolutions += 1
	reset_run(s)
	Politics.on_election(s)   # coalition and round state reset, suspicion to the new floor
	var after := derive(s).prestige_mult
	return {"gained": d.pending, "multBefore": mult_before, "multAfter": after, "runSec": run_sec}


# ---------------------------------------------------------------------------------------------
# Away time (mechanic rule 9, E1, E2), one rule for app-closed and backgrounded alike
# ---------------------------------------------------------------------------------------------

## The first minAwaySec pay full rate (as if the game were running), the rest pays
## offline.efficiency, and the total is capped at offline.capSec. Continuous: no cliff at 60 s.
## Buffs never count. `cap_sec` / `efficiency` let the Thumbs shop raise them.
static func away_award(s: GameState, elapsed_sec: float, cap_sec: float = -1.0, efficiency: float = -1.0) -> Dictionary:
	var o: Dictionary = Content.data()["offline"]
	if cap_sec < 0.0:
		cap_sec = float(o["capSec"])
	if efficiency < 0.0:
		efficiency = float(o["efficiency"])
	var e := maxf(0.0, elapsed_sec)
	var full := minf(e, float(o["minAwaySec"]))
	var credited := minf(e, cap_sec)
	var slow := maxf(0.0, credited - full)
	var fb := buffless_bps(s) * derive(s).offline_mult   # S03 "ביביסיטר": offline ×2
	var award := clampf_num(fb * (full + slow * efficiency))
	return {
		"elapsedSec": e, "creditedSec": credited, "award": award,
		"capped": e >= cap_sec, "showReceipt": e >= float(o["minAwaySec"]),
	}


static func buffless_bps(s: GameState) -> float:
	var f := s.buff_frenzy
	var t := s.buff_tap_frenzy
	s.buff_frenzy = 0.0
	s.buff_tap_frenzy = 0.0
	var b := derive(s).bps
	s.buff_frenzy = f
	s.buff_tap_frenzy = t
	return b
