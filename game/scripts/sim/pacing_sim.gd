class_name PacingSim
extends RefCounted
## Headless pacing bench: a greedy simulated player driving the REAL Economy (not a copy of its
## rules, so it cannot drift the way v1's design/sim/economy-sim.mjs could). Port of that sim's
## player model: taps at `tps` until `tap_until`, catches every Golden or none, and buys whatever
## has the best payback including the wait to afford it.
## Used by tests/unit/test_pacing.gd and tools/balance.sh.
##
## od-sevev: when the content has the politics sections, the simulated player also plays them
## through the real Politics.tick (the group chat, court days, events): it answers the chat, the
## court card and the brawl button by a strategy (`politics` below), so the bench measures the
## money / suspicion / coalition triangle (pitch §10) on the shipped numbers.
##   coalition: "subset" pays join / rejoin / poach offers when affordable, keeps members whose
##              maintenance costs ≤ keepFrac of the bank, lets the rest walk; "all" pays everything.
##   court:     "testify" | "postpone" (whenever affordable) | "mixed" (postpone while it costs
##              ≤ postponeFrac of the bank).
##   shady:     false never buys a court.sources producer (the clean route).
##   aide:      "drop" presses "אני לא מכיר אותו" whenever it can at ≥ 70% suspicion.

## "median" is the pitch's reference player (pitch §5: the first election at about 7-9 min), added
## for the od-sevev pacing gates in tests/bench/test_session.gd.
##
## Cadence (optional player keys; all default to the attentive player above, so no gate moves):
##   buy_every        seconds of play between two purchase actions (0: whenever the best buy is affordable)
##   buy_units        units per producer purchase action (0: the greedy default, 1 early, half the bank late)
##   buy              "best" (payback, the default) | "priciest" (the most expensive affordable source card)
##   spins            false never buys a spin (the source tab only)
##   politics_every   seconds between two looks at the chat, the court card and the brawl (0: every frame)
##   ping_after_buy   C1's controller half: the chat pings only this long after the last purchase
## A browser driver acts in wall-clock time while the dev clock (?speed=N) runs the game N times
## faster, so in game time it taps and buys N times less often: tests/bench/test_web_driver.gd
## replays tools/web/round_web.mjs's measured cadence through these keys (the 34-vs-8-minute gap).
const PLAYERS := {
	"median": {"tps": 1.5, "tap_until": INF, "catch_golden": true},
	"engaged": {"tps": 4.0, "tap_until": INF, "catch_golden": true},
	"casual": {"tps": 2.0, "tap_until": INF, "catch_golden": true},
	"idle": {"tps": 3.0, "tap_until": 120.0, "catch_golden": false},
	"spammer": {"tps": 30.0, "tap_until": INF, "catch_golden": true},
}

## The default politics strategy (an attentive, sensible player) and the bench's pure strategies.
const POLITICS := {"coalition": "subset", "court": "mixed", "shady": true, "aide": "never", "keepFrac": 0.25, "postponeFrac": 0.15}
const STRATEGIES := {
	"default": {},
	"payAll": {"coalition": "all"},
	"alwaysPostpone": {"court": "postpone"},
	"alwaysTestify": {"court": "testify"},
	"clean": {"shady": false},
	"aideDropper": {"aide": "drop"},
}


static func politics_on() -> bool:
	return Coalition.active() or Investigation.active() or Events.active()


static func strategy(player: Dictionary) -> Dictionary:
	var st: Dictionary = POLITICS.duplicate()
	st.merge(player.get("politics", {}), true)
	return st


## One run from `s` (a fresh or post-Evolve state). Stops at max_t, or when the gate opens and
## `evolve_at_gate` is set. Returns {t, gate_t, first: {id: t}, state}.
static func run(s: GameState, player: Dictionary, seed_: int, max_t: float = 3600.0, evolve_at_gate: bool = true, dt: float = 0.1, events: Array = []) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_
	var r := func() -> float: return rng.randf()
	var tps := minf(float(player["tps"]), float(Content.data()["tap"]["maxRegisteredTapsPerSec"]))
	var crit_mult := float(Content.data()["tap"]["critMult"])
	var first := {}
	var t := 0.0
	var acc := 0.0
	var auto_acc := 0.0
	var butler_ms := 0.0
	var gate_t := -1.0
	var d := Economy.derive(s)
	var milestones_seen := {}
	var pol := politics_on()
	var strat := strategy(player)
	var ctx := {"allowPing": true, "weekday": 2, "hour": 12}
	var buy_every := float(player.get("buy_every", 0.0))
	var buy_units := int(player.get("buy_units", 0))
	var pol_every := float(player.get("politics_every", 0.0))
	var ping_gap := float(player.get("ping_after_buy", 0.0))
	var last_buy := -INF
	var last_pol := -INF
	while t < max_t:
		var tapping := tps if t < float(player["tap_until"]) else 0.0
		acc += tapping * dt
		while acc >= 1.0:
			acc -= 1.0
			Economy.tap(s, r)
		auto_acc += Meta.auto_tap_rate(s) * dt
		while auto_acc >= 1.0:
			auto_acc -= 1.0
			Economy.tap(s, r)
		butler_ms += dt * 1000.0
		if butler_ms >= 1000.0:
			butler_ms = 0.0
			var bought := Meta.auto_buy(s)
			if bought != "" and not first.has(bought):
				first[bought] = t
				events.append([t, "producer:" + bought])
		d = Economy.derive(s)
		Economy.tick(s, dt, d)
		if Economy.tick_golden_timer(s, dt):
			if player["catch_golden"] or Meta.auto_catch(s):
				Economy.apply_golden(s, Economy.roll_golden_outcome(r, s))
			Economy.schedule_next_golden(s, r)
		if pol:
			ctx["allowPing"] = ping_gap <= 0.0 or t - last_buy >= ping_gap
			for e: Dictionary in Politics.tick(s, dt, d, ctx, r):
				if e["ev"] == "event":
					events.append([t, "event:" + String(e["id"])])
				elif e["ev"] == "courtStart":
					events.append([t, "court"])
				elif e["ev"] == "groupOpened":
					events.append([t, "c1"])   # the chat pings (pitch §11 Q2)
				elif e["ev"] == "message" and e["msg"].get("type", "") == "ultimatum":
					events.append([t, "ultimatum"])   # pitch §11 Q3: none before 3:00
			if t - last_pol >= pol_every:
				last_pol = t
				play_politics(s, strat)
		for a in Meta.check_achievements(s, d):
			events.append([t, "achievement:" + a])
		for id in Content.producer_ids():
			var nm := Meta.next_milestone(s.owned_of(id))
			var key := "%s>%d" % [id, s.owned_of(id)]
			if Meta.milestone_mult(s.owned_of(id)) > 1.0 and not milestones_seen.has(id + str(Meta.milestone_mult(s.owned_of(id)))):
				milestones_seen[id + str(Meta.milestone_mult(s.owned_of(id)))] = true
				events.append([t, "milestone:" + key])
		d = Economy.derive(s)
		# Nothing is affordable -> the greedy player can't buy this frame; skip ranking (same result).
		var best := {} if s.bananas < _cheapest(s, d) or t - last_buy < buy_every else _best_buy(s, d, tapping, player["catch_golden"], crit_mult, strat if pol else {}, player)
		if not best.is_empty() and s.bananas >= float(best["cost"]):
			last_buy = t
			if best.has("upgrade"):
				Economy.buy_upgrade(s, best["upgrade"])
				first["u:" + String(best["upgrade"])] = t
				events.append([t, "upgrade:" + String(best["upgrade"])])
			else:
				var id: String = best["producer"]
				if s.owned_of(id) == 0:
					first[id] = t
					events.append([t, "producer:" + id])
				# Late game the bank covers thousands of units: buy half of what it affords in one go
				# (the same greedy choice, without a loop pass per unit). Early on this is always 1.
				var n := Economy.max_affordable(s, id)
				Economy.buy_producer(s, id, clampi(buy_units, 1, maxi(1, n)) if buy_units > 0 else (maxi(1, n / 2) if n >= 10 else 1))
			# This frame already ticked the economy (dt of play, taps and politics), so the clock moves
			# too: without this, every purchase frame was dt of game time the bench never counted, and
			# its times ran about 5% short of s.run_time_sec (an ultimatum "at 2:51" was at 3:00 of play).
			t += dt
			continue
		if d.evolve_enabled and gate_t < 0.0:
			gate_t = t
			if evolve_at_gate:
				break
		t += dt
	return {"t": t, "gate_t": gate_t, "first": first, "state": s}


static func _cheapest(s: GameState, d: Economy.Derived) -> float:
	var c := INF
	for id in Content.producer_ids():
		if Economy.is_revealed(s, id):
			c = minf(c, Economy.producer_cost(s, id, 1))
	for u: Dictionary in Economy.available_upgrades(s):
		var p := Economy.upgrade_price(s, u["id"], d)
		if p >= 0.0:
			c = minf(c, p)
	return c


static func _best_buy(s: GameState, d: Economy.Derived, tapping: float, catch_golden: bool, crit_mult: float, strat: Dictionary = {}, player: Dictionary = {}) -> Dictionary:
	var inc0 := d.bps + tapping * d.tap_value_no_crit
	var best := {}
	var best_pb := INF
	var shady: Dictionary = Investigation.cfg().get("sources", {}) if strat.get("shady", true) == false else {}
	if str(player.get("buy", "best")) == "priciest":
		# tools/web/round_web.mjs: the most expensive source card it can afford now (never a spin).
		var top := -1.0
		for id in Content.producer_ids():
			var c := Economy.producer_cost(s, id, 1)
			if Economy.is_revealed(s, id) and not shady.has(id) and c <= s.bananas and c > top:
				top = c
				best = {"producer": id, "cost": c}
		return best
	for id in Content.producer_ids():
		if not Economy.is_revealed(s, id) or shady.has(id):
			continue
		var c := Economy.producer_cost(s, id, 1)
		s.owned[id] = s.owned_of(id) + 1
		var d2 := Economy.derive(s)
		s.owned[id] = s.owned_of(id) - 1
		var gain := d2.bps + tapping * d2.tap_value_no_crit - inc0
		var pb := c / maxf(gain, 1e-12) + maxf(0.0, c - s.bananas) / maxf(inc0, 1e-9)
		if pb < best_pb:
			best_pb = pb
			best = {"producer": id, "cost": c}
	for u: Dictionary in (Economy.available_upgrades(s) if player.get("spins", true) != false else []):
		var e: Dictionary = u["effect"]
		var c := Economy.upgrade_price(s, u["id"], d)
		if c < 0.0:
			continue
		if Spins.kind(u) == "consumable":
			# A timed burst is not a payback investment: buy it the moment it is affordable and its
			# own timer returns at least twice its price (the fatigue fades each rebuy).
			if s.bananas >= c and _burst_return(s, u, d, tapping) >= 2.0 * c:
				return {"upgrade": u["id"], "cost": c}
			continue
		var gain := 0.0
		match String(e["type"]):
			"critChance":
				gain = tapping * d.tap_value_no_crit * (float(e["set"]) - d.crit_chance) * (crit_mult - 1.0)
			"goldenIntervalMult", "goldenLifeMult":
				gain = inc0 * 0.35 * (1.0 / float(e["mult"]) - 1.0) if catch_golden else 0.0
			_:
				s.upgrades.append(u["id"])
				var d2 := Economy.derive(s)
				s.upgrades.remove_at(s.upgrades.size() - 1)
				gain = d2.bps + tapping * d2.tap_value_no_crit - inc0
		var pb := c / maxf(gain, 1e-12) + maxf(0.0, c - s.bananas) / maxf(inc0, 1e-9)
		if pb < best_pb:
			best_pb = pb
			best = {"upgrade": u["id"], "cost": c}
	return best


## What a consumable's timer earns over its whole duration at this tap rate (income with it live
## minus income without), through the real derive.
static func _burst_return(s: GameState, u: Dictionary, d: Economy.Derived, tapping: float) -> float:
	var f := Spins.faded(s, u)
	var fe: Dictionary = f["effect"]
	if not ["tapBuff", "idleToTap"].has(str(fe.get("type", ""))):
		return 0.0
	var inc := d.bps_effective + tapping * d.tap_value_no_crit
	var act: Array = s.spins["active"]
	act.append({"id": u["id"], "type": fe["type"], "leftSec": 1.0, "durationSec": 1.0,
		"mult": float(fe.get("mult", 1.0)), "pour": float(fe.get("pourSecPerTap", 0.0))})
	var d2 := Economy.derive(s)
	act.pop_back()
	return (d2.bps_effective + tapping * d2.tap_value_no_crit - inc) * float(f["durationSec"])


## The simulated player's answers to the politics this frame (see the header for the strategies).
## Leaders v3: the median player's use of the round's active ability (Ability). Bennett signs when
## the gate is shut and never flips (he keeps the base); Ben Gvir, Eisenkot and Deri use theirs when a
## demand is open; Smotrich pays a budget he can afford; Golan swipes; Bibi unites once. Phase 3:
## every other opposition leader refuses each unity offer.
static func _play_ability(s: GameState, d: Economy.Derived) -> void:
	if not Ability.can_use(s, d):
		return
	if Ability.unity_open(s):
		Ability.use(s, d)
		return
	match Ability.type(s):
		"pledgeFlip":
			if Events.is_active(s, "pledge") or d.seats_gate_open:
				return
		"walkout", "roundTable":
			if Coalition.open_demands(s).is_empty():
				return
	Ability.use(s, d)


static func play_politics(s: GameState, strat: Dictionary) -> void:
	var d := Economy.derive(s)
	var b := Coalition.open_brawl(s)
	if not b.is_empty():
		Coalition.resolve_brawl(s, int(b["seq"]))   # "צאו החוצה"
	if Investigation.phase(s) == "summons":
		var mode: String = strat.get("court", "mixed")
		var cost := Investigation.postpone_cost(s, d)
		var go: bool = mode == "postpone" or (mode == "mixed" and cost >= 0.0 and cost <= float(strat.get("postponeFrac", 0.15)) * s.bananas)
		if go and Investigation.can_postpone(s, d):
			Investigation.postpone(s, d)
		else:
			Investigation.testify(s)
	if strat.get("aide", "never") == "drop" and Investigation.can_drop_aide(s) and Investigation.suspicion(s) >= 70.0:
		Investigation.drop_aide(s)
	if Events.is_active(s, "kaia"):
		Events.act(s, "kaia", "feed", d)
	# Liberman's "לא יושב": decline the priciest open member demand whenever the pill is ready.
	if Coalition.decline_cooldown(s) == 0.0:
		var worst := {}
		for m: Dictionary in Coalition._c(s)["chat"]:
			if Coalition.can_decline(s, int(m["seq"])) and (worst.is_empty() or float(m.get("price", 0.0)) > float(worst.get("price", 0.0))):
				worst = m
		if not worst.is_empty():
			Coalition.decline(s, int(worst["seq"]))
	# Golan's "איחוד": merge the eligible pair with the fewest seats (fewer demands, a small walkout).
	if Coalition.merge_cooldown(s) == 0.0:
		var pair: Array = []
		var best := 1 << 30
		var ids: Array = []
		for p: Dictionary in Coalition.partners():
			if Coalition.counts(s, p["id"]):
				ids.append(str(p["id"]))
		for i in ids.size():
			for j in range(i + 1, ids.size()):
				if Coalition.can_merge(s, ids[i], ids[j]):
					var n := Coalition.row_seats(s, ids[i]) + Coalition.row_seats(s, ids[j])
					if n < best:
						best = n
						pair = [ids[i], ids[j]]
		if not pair.is_empty():
			Coalition.merge(s, pair[0], pair[1])
	_play_ability(s, d)
	var all: bool = strat.get("coalition", "subset") == "all"
	var keep := float(strat.get("keepFrac", 0.25))
	for m: Dictionary in (Coalition._c(s)["chat"] as Array).duplicate():
		if m["state"] != "open" or not Coalition.is_payable(m):
			continue
		var price := float(m.get("price", 0.0))
		if s.bananas < price:
			continue
		var pay := all
		if not all:
			var joining: bool = m.get("join", false) == true or str(m.get("payable", "")) != ""
			pay = joining or price <= keep * s.bananas
			if joining and _join_costs_seats(s, str(m.get("partner", ""))):
				pay = false   # e.g. Gafni's join would push Liberman (12) out of Bennett's round
		if pay:
			Coalition.pay(s, int(m["seq"]), true)


## An attentive player's check before bringing `id` in: the members who won't sit with them
## (`excludes`) would walk, and together they hold more seats than `id` brings (seats plus half the
## abstentions, which lower the majority by half as much). Bibi's round never hits it (only Abbas
## excludes, and only Ben Gvir's 12 seats).
static func _join_costs_seats(s: GameState, id: String) -> bool:
	var lose := 0
	for p: Dictionary in Coalition.partners():
		var q := str(p["id"])
		var st := Coalition.status(s, q)
		if (st == "member" or st == "pending") and (p.get("excludes", []) as Array).has(id):
			lose += Coalition.row_seats(s, q)
	if lose == 0:
		return false
	var p := Coalition.partner(id)
	return float(lose) > float(Coalition.row_seats(s, id)) + float(p.get("abstain", 0.0)) / 2.0


## A whole session: evolve at every gate, then spend Thumbs greedily on the cheapest perk.
## Returns {runs: [run seconds], events: [[t, what]], thumbs, maxGap (s, first 3 runs)}.
## Leader select (spec §7.2): player.leader is a leader id (every round that leader: its lineup,
## deal, rivals and rule), "mixed" (a random pickable leader every round, seeded), or absent (the
## default round, the shipped game). The save's deal salt is the seed, so seeds deal differently.
## Returns also {leaders: [the leader of each round played]}.
static func session(player: Dictionary, total_sec: float, seed_: int = 7, dt: float = 0.25) -> Dictionary:
	var s := GameState.fresh()
	var t0 := 0.0
	var runs: Array = []
	var events: Array = []
	var played: Array = []
	var n := 0
	var pick_rng := RandomNumberGenerator.new()
	pick_rng.seed = seed_ * 7919 + 17
	Leaders.set_salt(s, seed_)
	while t0 < total_sec - 1.0:
		var who := pick_leader(str(player.get("leader", "")), func() -> float: return pick_rng.randf())
		if who != "":
			Leaders.start_round(s, who)
		played.append(Leaders.current(s))
		var ev: Array = []
		var r := run(s, player, seed_ + n, total_sec - t0, true, dt, ev)
		for e: Array in ev:
			events.append([t0 + float(e[0]), e[1]])
		t0 += float(r["t"])
		if float(r["gate_t"]) < 0.0:
			break
		Meta.evolve(s)
		runs.append(float(r["t"]))
		events.append([t0, "evolve"])
		while Meta.can_buy_any_perk(s):
			var best := ""
			var best_c := 1 << 30
			for p: Dictionary in Meta.perks():
				var c := Meta.next_cost(s, p["id"])
				if c >= 0 and c < best_c:
					best_c = c
					best = p["id"]
			Meta.buy_perk(s, best)
			events.append([t0, "perk:" + best])
		n += 1
	events.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	var horizon := 0.0
	for i in mini(3, runs.size()):
		horizon += float(runs[i])
	var gap := 0.0
	var last := 0.0
	for e: Array in events:
		var et := float(e[0])
		if et > horizon:
			break
		gap = maxf(gap, et - last)
		last = et
	return {"runs": runs, "events": events, "thumbs": s.thumbs_owned, "maxGap": gap, "state": s, "leaders": played}


## "" (no pick: the round keeps its leader), a leader id, or "mixed" (uniform among the pickable).
static func pick_leader(mode: String, rng: Callable) -> String:
	if mode == "" or not Leaders.active():
		return ""
	if mode == "mixed":
		return Leaders.random_pick(rng)
	return mode


## One leader's first round from a new game (the bench's per-seed first election): {t, gate_t, first, state}.
static func first_round(leader: String, player: Dictionary, seed_: int, max_t: float = 1800.0, dt: float = 0.25, events: Array = []) -> Dictionary:
	var s := GameState.fresh()
	Leaders.set_salt(s, seed_)
	if leader != "":
		Leaders.start_round(s, leader)
	return run(s, player, seed_, max_t, true, dt, events)


static func fmt_t(sec: float) -> String:
	# Round the whole value once (179.75 s is "3:00"; rounding only the seconds printed "2:00").
	if is_inf(sec) or is_nan(sec) or sec > 1e8:
		return "never"
	var r := int(roundf(sec))
	return "%d:%02d" % [r / 60, r % 60]
