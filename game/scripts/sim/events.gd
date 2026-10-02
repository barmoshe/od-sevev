class_name Events
extends RefCounted
## Data-driven event scheduler for content.events[] (pitch §7, §9; deck §E, §E.2, §F; brief-round2
## easter eggs). Pure rules, no nodes. State: GameState.events (round + cooldowns) and
## GameState.album (the photobomb album, lifetime).
##
## Every eventsConfig.gapSec seconds of visible play one event fires, picked by weight among the
## eligible ones (an event with `atPlaySec` instead fires once at that play time). Eligible means:
##   - its flag is on (flags default off, so post-launch content and the flagged characters,
##     Mordechai David and Yair, never fire until switched on);
##   - its `when` holds (Conditions);
##   - its cooldown has run out, and it hasn't fired this round if `oncePerRound`;
##   - it isn't `pollLike` during the blackout (Calendar).
## What an event *does* is its effect.type, dispatched through EFFECTS; the parameters are data.

static var _installed := false


static func install() -> void:
	if _installed:
		return
	_installed = true
	Economy.MODIFIERS.append(_apply_modifiers)


## effect.type -> func(s, e: effect Dictionary, d: Derived, rng) -> Dictionary (the result the UI
## gets in the "event" ui-event). Adding a type is one entry here plus data.
static var EFFECTS: Dictionary = {
	"none": func(s: GameState, e: Dictionary, _d: Economy.Derived, _r: Callable) -> Dictionary:
		_activate(s, "none", e, {})
		return {},
	"suspicion": func(s: GameState, e: Dictionary, _d: Economy.Derived, _r: Callable) -> Dictionary:
		Investigation.add(s, float(e.get("add", 0.0)))
		return {"add": float(e.get("add", 0.0))},
	"noCrit": func(s: GameState, e: Dictionary, _d: Economy.Derived, _r: Callable) -> Dictionary:
		_activate(s, "noCrit", e, {})
		return {},
	"brawl": func(s: GameState, e: Dictionary, _d: Economy.Derived, r: Callable) -> Dictionary:
		var pair := _brawl_pair(s, e, r)
		if pair.is_empty():
			return {"skipped": true}
		var ev := Coalition.start_brawl(s, pair[0], pair[1], "brawl", _brawl_script(s, pair))
		return {"a": pair[0], "b": pair[1], "events": ev},
	"leak": func(s: GameState, e: Dictionary, _d: Economy.Derived, _r: Callable) -> Dictionary:
		var st := _st(s)
		var n := maxi(1, int(e.get("leaks", 1)))
		var idx := int(st["leak"]) % n
		st["leak"] = idx + 1
		return {"leak": idx + 1},   # deck §E.2: leaks 1..n in order, then loop
	"interview": func(s: GameState, e: Dictionary, _d: Economy.Derived, _r: Callable) -> Dictionary:
		# The prestige formula: this round's base payout × (1 + basePctThisRound / 100).
		var st := _st(s)
		st["roundBasePct"] = float(st["roundBasePct"]) + float(e.get("baseMultPct", e.get("pct", 0.0)))
		st["invoiceSec"] = float(e.get("invoiceAfterSec", 0.0))
		return {"basePct": float(e.get("baseMultPct", e.get("pct", 0.0)))},
	"pardonDesk": func(s: GameState, e: Dictionary, _d: Economy.Derived, _r: Callable) -> Dictionary:
		_activate(s, "pardonDesk", e, {})
		return {},
	"seatDrain": func(s: GameState, e: Dictionary, _d: Economy.Derived, _r: Callable) -> Dictionary:
		_activate(s, "seatDrain", e, {"seats": int(e.get("seats", 0))})
		return {"seats": int(e.get("seats", 0))},
	"pledge": func(s: GameState, e: Dictionary, _d: Economy.Derived, _r: Callable) -> Dictionary:
		# Bennett: the gate rises while the card is up; then the pledge flips and pays base.
		_activate(s, "pledge", e, {"gatePlus": int(e.get("gatePlus", 1)), "baseAdd": int(e.get("baseAdd", 0))})
		return {"gatePlus": int(e.get("gatePlus", 1))},
	"roulette": func(_s: GameState, e: Dictionary, _d: Economy.Derived, r: Callable) -> Dictionary:
		var lists: Array = e.get("lists", [])
		if lists.is_empty():
			return {"skipped": true}
		# pitch §2.8: which list sinks is random and uniform every round, never tied to data.
		return {"sunk": lists[int(float(r.call()) * lists.size()) % lists.size()]},
	"kaia": func(s: GameState, e: Dictionary, _d: Economy.Derived, _r: Callable) -> Dictionary:
		_activate(s, "kaia", e, {"sec": float(e.get("feedSec", 20.0))})
		return {},
	"drumline": func(s: GameState, e: Dictionary, _d: Economy.Derived, _r: Callable) -> Dictionary:
		_activate(s, "drumline", e, {})
		return {},
	"blockade": func(s: GameState, e: Dictionary, _d: Economy.Derived, r: Callable) -> Dictionary:
		# Mordechai David (design/mordechai-david-spec.md §5): a counting partner of 1..maxSeats seats is
		# stuck behind the blockade and misses the vote for `sec`; none in range: the card only.
		var pool: Array = []
		for p: Dictionary in Coalition.partners():
			var seats := int(Coalition.partner(p["id"]).get("seats", 0))
			if Coalition.counts(s, p["id"]) and seats > 0 and seats <= int(e.get("maxSeats", 4)):
				pool.append(p["id"])
		var id := ""
		if not pool.is_empty():
			id = pool[int(float(r.call()) * pool.size()) % pool.size()]
			Coalition.bench(s, id, float(e.get("sec", 20.0)))
		_activate(s, "blockade", e, {"partner": id})
		return {"partner": id},
	"screenBlock": func(s: GameState, e: Dictionary, _d: Economy.Derived, _r: Callable) -> Dictionary:
		# Mordechai David since 2026-10-01 (Bar): he walks in from the left and, for `sec`, nothing on
		# the screen takes a tap (main._input_blocked). No seats, no money: the cost is the lost seconds.
		# Three phases on one clock (block_phase): `approachSec` he walks in (taps still work), `sec` he
		# stands on his mark and blocks, `exitSec` he walks out (taps work again). The block starts
		# when he is on the screen and ends when he turns to go, so the cause is always in view.
		# effect.byLeader[the round's leader] swaps what he does on his mark (visit_mode).
		var ap := float(e.get("approachSec", 0.0))
		var bl := float(e.get("sec", 0.0))
		var ex := float(e.get("exitSec", 0.0))
		var by: Dictionary = e.get("byLeader", {}) if e.get("byLeader") is Dictionary else {}
		var ov: Dictionary = by.get(Leaders.current(s), {}) if by.get(Leaders.current(s)) is Dictionary else {}
		var mode := str(ov.get("type", "block"))
		var extra := {"sec": ap + bl + ex, "approachSec": ap, "blockSec": bl, "exitSec": ex, "mode": mode}
		if mode == "tapBuff":
			extra["tapMult"] = float(ov.get("mult", 1.0))
		_activate(s, "screenBlock", e, extra)
		return {"mode": mode, "mult": float(ov.get("mult", 1.0))},
	"mediation": func(s: GameState, e: Dictionary, _d: Economy.Derived, _r: Callable) -> Dictionary:
		# Herzog's compromise outline (fact herzog-framework, March 2023): he stands on the stage for
		# `sec`; a tap on him accepts it (act "accept": every open demand drops `pct`%); ignored, it
		# lapses and he shrugs. No seats, no penalty: the cost of ignoring him is the missed discount.
		_activate(s, "mediation", e, {})
		return {},
	"loseRandomPartner": func(s: GameState, _e: Dictionary, d: Economy.Derived, r: Callable) -> Dictionary:
		var pool: Array = []
		for p: Dictionary in Coalition.partners():
			if Coalition.counts(s, p["id"]) and Coalition.can_leave(p["id"]):
				pool.append(p["id"])
		if pool.is_empty():
			return {"skipped": true}
		var id: String = pool[int(float(r.call()) * pool.size()) % pool.size()]
		return {"partner": id, "events": Coalition.force_leave(s, id, d)},
}


# ---------------------------------------------------------------------------------------------
# Content
# ---------------------------------------------------------------------------------------------

## The round's cards: content.events in the default leader's round, else the leader's (shared
## events, this round's rivals, their selfEvent card; Leaders.build_events, spec §5.5).
static func list() -> Array:
	return Leaders.events()


static func cfg() -> Dictionary:
	var v: Variant = Content.data().get("eventsConfig")
	return v if v is Dictionary else {}


static func active() -> bool:
	return not list().is_empty()


static func event(id: String) -> Dictionary:
	for e: Dictionary in list():
		if e["id"] == id:
			return e
	return {}


## Unknown flags are off. Flags default off in content (postLaunch, easterEggs, mordechaiDavid,
## yairNetanyahu), so nothing behind a flag fires until someone switches it on.
static func flag_on(name: String) -> bool:
	var f: Variant = Content.data().get("flags")
	return f is Dictionary and (f as Dictionary).get(name, false) == true


# ---------------------------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------------------------

static func fresh_state() -> Dictionary:
	return {"nextSec": -1.0, "cooldowns": {}, "round": [], "counts": {}, "active": [], "leak": 0,
		"roundBasePct": 0.0, "invoiceSec": 0.0, "followUps": []}


static func fresh_album() -> Dictionary:
	return {"liran": 0, "tomer": 0, "together": 0}


static func _st(s: GameState) -> Dictionary:
	return s.events


static func _activate(s: GameState, type: String, e: Dictionary, extra: Dictionary) -> void:
	var sec := float(extra.get("sec", e.get("sec", 0.0)))
	if sec <= 0.0:
		return
	var a := {"type": type}
	a.merge(extra, true)
	a["leftSec"] = sec
	a.erase("sec")
	(_st(s)["active"] as Array).append(a)


## The live effects (for the UI: which card is up and how long it has left).
static func active_effects(s: GameState) -> Array:
	return _st(s)["active"]


## Mordechai David's visit (effect screenBlock): "" when none is live, else approach | block | exit.
## "block" is the time he stands on his mark, whatever he does there (mode).
static func block_phase(s: GameState) -> String:
	for a: Dictionary in s.events.get("active", []):
		if a["type"] == "screenBlock":
			return _phase_of(a)
	return ""


static func _phase_of(a: Dictionary) -> String:
	var ex := float(a.get("exitSec", 0.0))
	var bl := float(a.get("blockSec", float(a["leftSec"]) - ex))
	var left := float(a["leftSec"])
	if left <= ex:
		return "exit"
	if left <= ex + bl:
		return "block"
	return "approach"


## What he does on his mark this round (effect.byLeader, Bar 2026-10-01): "block" (the default),
## "tapBuff" (Ben Gvir ×3, Bibi ×2: taps count more while he stands there) or "none" (Smotrich: he
## just stands there). "" when he is not here.
static func visit_mode(s: GameState) -> String:
	for a: Dictionary in s.events.get("active", []):
		if a["type"] == "screenBlock":
			return str(a.get("mode", "block"))
	return ""


## True while the block holds the screen: nothing takes a tap, and the timers the player has to
## react to (ultimatums, the summons, offers, live cards) wait (Politics.tick).
static func screen_blocked(s: GameState) -> bool:
	return block_phase(s) == "block" and visit_mode(s) == "block"


## His tap multiplier while he stands on his mark in a tapBuff round (1 otherwise).
static func visit_tap_mult(s: GameState) -> float:
	for a: Dictionary in s.events.get("active", []):
		if a["type"] == "screenBlock" and str(a.get("mode", "block")) == "tapBuff" and _phase_of(a) == "block":
			return maxf(1.0, float(a.get("tapMult", 1.0)))
	return 1.0


## The block's seconds left and its share of the whole block (the chip's countdown and bar).
static func block_left(s: GameState) -> Array:
	for a: Dictionary in s.events.get("active", []):
		if a["type"] == "screenBlock":
			var ex := float(a.get("exitSec", 0.0))
			var bl := maxf(0.001, float(a.get("blockSec", 1.0)))
			var left := clampf(float(a["leftSec"]) - ex, 0.0, bl)
			return [left, left / bl]
	return [0.0, 0.0]


## One interruption on the stage at a time: the cards that take the stage (Mordechai's block,
## Herzog's outline, Kaia) never fire over one another, over the summons or the court day, nor over
## an open ability offer or Ben Gvir's walk-off. Each system used to guard alone, so they piled up.
const STAGE_INTERRUPTS := ["screenBlock", "mediation", "kaia"]


static func interrupt_live(s: GameState) -> bool:
	for a: Dictionary in s.events.get("active", []):
		if STAGE_INTERRUPTS.has(str(a["type"])):
			return true
	return false


static func stage_busy(s: GameState) -> bool:
	if interrupt_live(s):
		return true
	if Investigation.active() and ["summons", "court"].has(Investigation.phase(s)):
		return true
	return Ability.window_open(s) or Ability.walked_out(s)


static func is_active(s: GameState, type: String) -> bool:
	for a: Dictionary in s.events.get("active", []):
		if a["type"] == type:
			return true
	return false


static func seat_drain(s: GameState) -> int:
	var n := 0
	for a: Dictionary in s.events.get("active", []):
		if a["type"] == "seatDrain":
			n += int(a.get("seats", 0))
	return n


## Bennett's pledge raises the seat gate while it's up.
static func gate_plus(s: GameState) -> int:
	var n := 0
	for a: Dictionary in s.events.get("active", []):
		if a["type"] == "pledge" or a["type"] == "gateHold":   # gateHold: Smotrich's missed budget (Ability)
			n += int(a.get("gatePlus", 0))
	return n


static func _apply_modifiers(s: GameState, d: Economy.Derived) -> void:
	var st := _st(s)
	d.base_pct_round += float(st.get("roundBasePct", 0.0))
	for a: Dictionary in st.get("active", []):
		match str(a["type"]):
			"noCrit":
				d.no_crit = true
			"kaiaBuff", "leaderBuff":
				d.tap_boost *= maxf(1.0, float(a.get("tapMult", 1.0)))
			"screenBlock":
				if str(a.get("mode", "block")) == "tapBuff" and _phase_of(a) == "block":
					d.tap_boost *= maxf(1.0, float(a.get("tapMult", 1.0)))


## A leader rule's timed tap buff (Deri's ☕ onDemandPaid {type: tapBuff, mult, durationSec}):
## a new one refreshes the running one, never stacks. Round-scoped like every live card.
static func leader_buff(s: GameState, e: Dictionary) -> void:
	var act: Array = _st(s)["active"]
	for a: Dictionary in act.duplicate():
		if a["type"] == "leaderBuff":
			act.erase(a)
	_activate(s, "leaderBuff", e, {"sec": float(e.get("durationSec", 0.0)), "tapMult": float(e.get("mult", 1.0))})


# ---------------------------------------------------------------------------------------------
# Scheduling
# ---------------------------------------------------------------------------------------------

## Card effects that take seats off the 61 (a frozen pair, a raised gate, drained seats, a lost
## partner, Kaia's nip, Mordechai David's blockade): never fired while the gate is open.
const SEAT_COSTS := ["brawl", "pledge", "seatDrain", "loseRandomPartner", "kaia", "blockade"]


static func eligible(s: GameState, e: Dictionary, ctx: Dictionary = {}) -> bool:
	var st := _st(s)
	if e.has("flag") and not flag_on(str(e["flag"])):
		return false
	if e.get("pollLike", e.get("poll_like", false)) == true and not Calendar.poll_like_allowed(s):
		return false
	if float(st["cooldowns"].get(e["id"], 0.0)) > 0.0:
		return false
	if e.get("oncePerRound", false) == true and (st["round"] as Array).has(e["id"]):
		return false
	# The finish line is quiet (spec §7.4): while the 61 gate is open no card that costs seats fires,
	# so between "עוד סבב!" appearing and the vote only a counted-down ultimatum can take a seat.
	if SEAT_COSTS.has(str(e.get("effect", {}).get("type", ""))) and Coalition.gate_open(s):
		return false
	# nor a screen block: the vote button stays tappable at the finish line
	var etype := str(e.get("effect", {}).get("type", ""))
	if etype == "screenBlock" and Coalition.gate_open(s):
		return false
	# one interruption at a time (STAGE_INTERRUPTS), and no block behind a modal or a covered stage
	if STAGE_INTERRUPTS.has(etype) and stage_busy(s):
		return false
	if etype == "screenBlock" and ctx.get("stageHidden", false) == true:
		return false
	return float(e.get("weight", 1.0)) > 0.0 and Conditions.ok(s, e.get("when", {}), ctx)


## The periodic roll in [0, 1): a hash of the event, its roll count and a per-save salt (drawn once from
## the clock), never the shared rng.
static func _every_roll(s: GameState, eid: String) -> float:
	var st := _st(s)
	if not st.has("everySalt"):
		st["everySalt"] = int(Time.get_ticks_usec() % 1000003)
	var n: Dictionary = st.get("everyN", {}) if st.get("everyN") is Dictionary else {}
	st["everyN"] = n
	n[eid] = int(n.get(eid, 0)) + 1
	var h := hash("%s|%d|%d" % [eid, int(n[eid]), int(st["everySalt"])])
	return float(posmod(h, 1000003)) / 1000003.0


## One visible frame. Returns UI events: {ev: event, id, kind, side, result} when one fires,
## {ev: eventEnd, type} when a timed effect ends, {ev: pledgeFlip, baseAdd}, {ev: invoice} for
## the interview's follow-up, {ev: followUp, upgrade} for an upgrade's (S13), {ev: kaiaNip, partner}.
static func tick(s: GameState, dt: float, d: Economy.Derived, ctx: Dictionary = {}, rng: Callable = randf) -> Array:
	var out: Array = []
	var st := _st(s)
	# the gate opened under the block (a partner back, a join): he leaves now, the vote stays tappable
	if Coalition.gate_open(s):
		for a: Dictionary in st["active"]:
			if a["type"] == "screenBlock" and float(a["leftSec"]) > float(a.get("exitSec", 0.0)):
				a["leftSec"] = float(a.get("exitSec", 0.0)) + 0.001
	# While the block holds the screen only the block's own clock runs: live cards, cooldowns and the
	# scheduler wait with the player (nothing fires or runs out while nothing can be tapped).
	if screen_blocked(s):
		for a: Dictionary in st["active"]:
			if a["type"] == "screenBlock":
				a["leftSec"] = float(a["leftSec"]) - dt
		# the periodic events' clocks are play time: they keep counting (no roll while he blocks)
		var ev: Dictionary = st.get("every", {}) if st.get("every") is Dictionary else {}
		st["every"] = ev
		for e: Dictionary in list():
			if e.has("everySec"):
				ev[str(e["id"])] = float(ev.get(str(e["id"]), 0.0)) + dt
		return out
	_tick_active(s, dt, rng, out)
	if float(st["invoiceSec"]) > 0.0:
		st["invoiceSec"] = maxf(0.0, float(st["invoiceSec"]) - dt)
		if float(st["invoiceSec"]) <= 0.0:
			out.append({"ev": "invoice"})   # "הנחה באגרה" (deck S13)
	var fu: Array = st["followUps"]
	for f: Dictionary in fu.duplicate():
		f["leftSec"] = float(f["leftSec"]) - dt
		if float(f["leftSec"]) <= 0.0:
			fu.erase(f)
			out.append({"ev": "followUp", "upgrade": f["upgrade"]})
	var cds: Dictionary = st["cooldowns"]
	for id: Variant in cds.keys():
		cds[id] = maxf(0.0, float(cds[id]) - dt)
		if float(cds[id]) <= 0.0:
			cds.erase(id)
	if not active():
		return out
	# A periodic event (`everySec` + `chance`, Mordechai David since 2026-10-01): every `everySec` of play
	# it rolls once and fires with probability `chance`, outside the weighted pool and its gap; it never
	# stacks on itself (a live one skips the roll). Its other rules (flag, when, cooldown) still hold.
	# The roll has its own source (_every_roll; ctx.everyRoll in tests) and the weighted scheduler runs
	# on in the same tick, so the shared rng stream, and everything seeded by it, is untouched.
	var every: Dictionary = st.get("every", {}) if st.get("every") is Dictionary else {}
	st["every"] = every
	for e: Dictionary in list():
		if not e.has("everySec"):
			continue
		var eid := str(e["id"])
		every[eid] = float(every.get(eid, 0.0)) + dt
		if float(every[eid]) < float(e["everySec"]):
			continue
		every[eid] = float(every[eid]) - float(e["everySec"])
		var typ := str(e.get("effect", {}).get("type", ""))
		if is_active(s, typ) or not eligible(s, e, ctx):
			continue
		var roll := float((ctx["everyRoll"] as Callable).call()) if ctx.get("everyRoll") is Callable else _every_roll(s, eid)
		if roll < float(e.get("chance", 1.0)):
			out.append(fire(s, eid, d, func() -> float: return 0.0))
	# A timed event (`atPlaySec`): it fires once when the save's play time reaches it, ahead of the
	# scheduler's first wait, gap and weights, and never through the weighted pool (Mordechai David at
	# one minute, design/mordechai-david-spec.md §4). Its other rules (flag, when, once, gate) still hold.
	for e: Dictionary in list():
		if e.has("atPlaySec") and float(s.stats.get("playtimeSec", 0.0)) >= float(e["atPlaySec"]) and eligible(s, e, ctx):
			out.append(fire(s, e["id"], d, rng))
			return out
	var c := cfg()
	if float(st["nextSec"]) < 0.0:
		var first := float(c.get("firstAfterPlaySec", 0.0)) - float(s.stats.get("playtimeSec", 0.0))
		st["nextSec"] = maxf(first, _gap(rng))
	st["nextSec"] = float(st["nextSec"]) - dt
	if float(st["nextSec"]) > 0.0:
		return out
	st["nextSec"] = _gap(rng)
	var pool: Array = []
	var total := 0.0
	for e: Dictionary in list():
		if not e.has("atPlaySec") and not e.has("everySec") and eligible(s, e, ctx):
			pool.append(e)
			total += float(e.get("weight", 1.0))
	if pool.is_empty():
		return out
	var r := float(rng.call()) * total
	var pick: Dictionary = pool[pool.size() - 1]
	for e: Dictionary in pool:
		r -= float(e.get("weight", 1.0))
		if r < 0.0:
			pick = e
			break
	out.append(fire(s, pick["id"], d, rng))
	return out


static func _gap(rng: Callable) -> float:
	var g: Array = cfg().get("gapSec", [180, 180])
	return float(g[0]) + (float(g[1]) - float(g[0])) * float(rng.call())


## Fires one event now (the scheduler's pick, or a forced one: tests, dev tools, a spin that
## triggers a card). Returns {ev: event, id, kind, side, result}.
static func fire(s: GameState, id: String, d: Economy.Derived, rng: Callable = randf) -> Dictionary:
	var e := event(id)
	if e.is_empty():
		return {}
	var st := _st(s)
	var eff: Dictionary = e.get("effect", {"type": "none"})
	var h: Variant = EFFECTS.get(eff.get("type", "none"))
	var result: Dictionary = (h as Callable).call(s, eff, d, rng) if h != null else {"skipped": true}
	if e.has("skin"):
		result["skin"] = e["skin"]   # "leakRight": the coalition's screenshot (Leaders.leak_copy)
	if float(e.get("cooldownSec", 0.0)) > 0.0:
		st["cooldowns"][id] = float(e["cooldownSec"])
	if not (st["round"] as Array).has(id):
		(st["round"] as Array).append(id)
	st["counts"][id] = int(st["counts"].get(id, 0)) + 1
	Meta.count(s, "countEvent", id)   # "lapidCards" (trophy "בכובע!")
	# A rival card: the shipped opposition cards, or a coalition-side card in an opposition leader's
	# round (side "rival"). The leader's own card (side "self") is not a rival.
	if e.get("side", "") == "opposition" or e.get("side", "") == "rival":
		var bonus := 0
		for uid in s.upgrades:
			var ue: Dictionary = Content.upgrade(uid).get("effect", {})
			if ue.get("type", "") == "basePerOppositionCard":
				bonus += int(ue.get("add", 0))
		if bonus > 0:
			s.thumbs_owned += bonus   # S05 "ציד מכשפות": every opposition card strengthens the base
			result["baseAdd"] = bonus
	return {"ev": "event", "id": id, "kind": e.get("kind", "card"), "side": e.get("side", ""), "result": result}


static func _tick_active(s: GameState, dt: float, rng: Callable, out: Array) -> void:
	var keep: Array = []
	for a: Dictionary in _st(s)["active"]:
		a["leftSec"] = float(a["leftSec"]) - dt
		if float(a["leftSec"]) > 0.0:
			keep.append(a)
			continue
		out.append({"ev": "eventEnd", "type": a["type"]})
		if a["type"] == "pledge" and int(a.get("baseAdd", 0)) > 0:
			s.thumbs_owned += int(a["baseAdd"])   # the pledge flips; the player gets the base
			out.append({"ev": "pledgeFlip", "baseAdd": int(a["baseAdd"])})
		if a["type"] == "kaia":
			# Ignored: a random minister gets nipped and misses the vote (brief-round2, Kaia).
			var e := _effect_of("kaia")
			var pool: Array = []
			for p: Dictionary in Coalition.partners():
				if Coalition.counts(s, p["id"]):
					pool.append(p["id"])
			if not pool.is_empty():
				var id: String = pool[int(float(rng.call()) * pool.size()) % pool.size()]
				Coalition.bench(s, id, float(e.get("nipSec", 60.0)))
				out.append({"ev": "kaiaNip", "partner": id})
	_st(s)["active"] = keep


static func _effect_of(type: String) -> Dictionary:
	for e: Dictionary in list():
		var eff: Dictionary = e.get("effect", {})
		if eff.get("type", "") == type:
			return eff
	return {}


## The first brawl ever (events.brawl.counts 0) between the scripted pair (effect.pairs[0], e.g.
## Amsalem × Smotrich) plays events.brawl.copy.script; every later brawl is the generic one.
static func _brawl_script(s: GameState, pair: Array) -> Array:
	var b := event("brawl")
	var pairs: Array = b.get("effect", {}).get("pairs", [])
	if pairs.is_empty() or not pairs[0] is Array or int(_st(s)["counts"].get("brawl", 0)) > 0:
		return []
	var p0: Array = pairs[0]
	if not (p0.has(pair[0]) and p0.has(pair[1])):
		return []
	var sc: Variant = b.get("copy", {}).get("script", [])
	return sc if sc is Array else []


## The leak's lines in the round's skin (events.leak.copy.leaks, or leaderSelect.leakRight.leaks):
## leak `idx` is 1-based; [] when it has none.
static func leak_lines(idx: int, skin: String = "") -> Array:
	var c: Variant = Leaders.ls().get("leakRight", {}) if skin == "leakRight" else event("leak").get("copy", {})
	var leaks: Array = (c as Dictionary).get("leaks", []) if c is Dictionary else []
	if idx < 1 or idx > leaks.size() or not leaks[idx - 1] is Array:
		return []
	return leaks[idx - 1]


static func _brawl_pair(s: GameState, e: Dictionary, rng: Callable) -> Array:
	for pr: Variant in e.get("pairs", []):
		if pr is Array and (pr as Array).size() == 2 and Coalition.can_brawl(s, str(pr[0]), str(pr[1])):
			return [str(pr[0]), str(pr[1])]
	if not e.get("anyPair", false) or not Coalition.open_brawl(s).is_empty():
		return []
	var ids: Array = []
	for p: Dictionary in Coalition.partners():
		if Coalition.counts(s, p["id"]) and Coalition.open_msg(s, p["id"]).is_empty():
			ids.append(p["id"])
	if ids.size() < 2:
		return []
	var i := int(float(rng.call()) * ids.size()) % ids.size()
	var j := int(float(rng.call()) * (ids.size() - 1)) % (ids.size() - 1)
	if j >= i:
		j += 1
	return [ids[i], ids[j]]


# ---------------------------------------------------------------------------------------------
# Player actions on live events
# ---------------------------------------------------------------------------------------------

## "feed" (Kaia's cucumber: a tap buff instead of the nip), "beat" (the Pink Front drum line,
## tapped to the beat: bpsSec seconds of ₪/s), "request" (the pardon desk's stamp).
## Returns {} when there is nothing to act on.
static func act(s: GameState, type: String, action: String, d: Economy.Derived) -> Dictionary:
	var st := _st(s)
	for a: Dictionary in st["active"]:
		if a["type"] != type:
			continue
		var e := _effect_of(type)
		if type == "kaia" and action == "feed":
			(st["active"] as Array).erase(a)
			_activate(s, "kaiaBuff", e, {"sec": float(e.get("buffSec", 30.0)), "tapMult": float(e.get("tapMult", 2.0))})
			return {"buffSec": float(e.get("buffSec", 30.0))}
		if type == "drumline" and action == "beat":
			(st["active"] as Array).erase(a)
			var award := Economy.clampf_num(float(e.get("bpsSec", 0.0)) * d.bps)
			Economy.add_bananas(s, award)
			return {"award": award}
		if type == "pardonDesk" and action == "request":
			return {"stamp": Investigation.request_pardon(s)}
		if type == "mediation" and action == "accept":
			(st["active"] as Array).erase(a)
			var pct := clampf(float(e.get("pct", 30.0)), 0.0, 100.0)
			return {"accepted": true, "pct": pct, "cut": Coalition.discount_open(s, 1.0 - pct / 100.0)}
	return {}


## An upgrade's delayed follow-up (S13's "next morning" invoice: the UI may show it at the device's
## next morning; the sim guarantees it after fallbackAfterSec of play).
static func follow_up(s: GameState, upgrade_id: String, sec: float) -> void:
	(_st(s)["followUps"] as Array).append({"upgrade": upgrade_id, "leftSec": maxf(0.0, sec)})


## A camera moment (Dubi's flash, court day, a share card) rolls for Liran and Tomer. They appear
## only while photobomb.flag is on (post-launch by default). {liran, tomer, together}
static func roll_photobomb(rng: Callable = randf) -> Dictionary:
	var pb: Dictionary = cfg().get("photobomb", {})
	var none := {"liran": false, "tomer": false, "together": false}
	if pb.is_empty() or not flag_on(str(pb.get("flag", ""))):
		return none
	if float(rng.call()) * 100.0 < float(pb.get("togetherPct", 0.0)):
		return {"liran": true, "tomer": true, "together": true}
	return {"liran": float(rng.call()) * 100.0 < float(pb.get("liranPct", 0.0)),
		"tomer": float(rng.call()) * 100.0 < float(pb.get("tomerPct", 0.0)), "together": false}


## The player tapped a photobomber: into the hidden album. Returns true the first time both were
## caught together (trophy "שלום בית בפריים").
static func album_add(s: GameState, roll: Dictionary) -> bool:
	var al: Dictionary = s.album
	if roll.get("liran", false):
		al["liran"] = int(al["liran"]) + 1
	if roll.get("tomer", false):
		al["tomer"] = int(al["tomer"]) + 1
	if roll.get("together", false):
		al["together"] = int(al["together"]) + 1
		return int(al["together"]) == 1
	return false


## Election: round-scoped effects end (the interview's +base, a live card), leaks keep their place.
static func on_election(s: GameState) -> void:
	var st := _st(s)
	st["round"] = []
	st["active"] = []
	st["roundBasePct"] = 0.0
	st["invoiceSec"] = 0.0


# ---------------------------------------------------------------------------------------------
# Save (v3) and the content lint
# ---------------------------------------------------------------------------------------------

static func sanitize(raw: Variant) -> Dictionary:
	var out := fresh_state()
	if not raw is Dictionary:
		return out
	var r: Dictionary = raw
	out["nextSec"] = Coalition._n(r.get("nextSec"), -1.0)
	out["leak"] = int(Coalition._n(r.get("leak")))
	out["roundBasePct"] = Coalition._n(r.get("roundBasePct"))
	out["invoiceSec"] = Coalition._n(r.get("invoiceSec"))
	var known := {}
	for e: Dictionary in list():
		known[e["id"]] = true
	for key in ["cooldowns", "counts"]:
		var v: Variant = r.get(key)
		if v is Dictionary:
			for k: Variant in v:
				if not known.has(k):
					continue
				if key == "counts":
					out[key][k] = int(Coalition._n(v[k]))
				elif Coalition._n(v[k]) > 0.0:
					out[key][k] = Coalition._n(v[k])
	var rd: Variant = r.get("round")
	if rd is Array:
		for x: Variant in rd:
			if x is String and known.has(x) and not (out["round"] as Array).has(x):
				(out["round"] as Array).append(x)
	var ac: Variant = r.get("active")
	if ac is Array:
		for x: Variant in ac:
			# a block never survives a load: he has walked off by the time the player is back
			if x is Dictionary and str((x as Dictionary).get("type", "")) != "" and str((x as Dictionary).get("type", "")) != "screenBlock" and Coalition._n(x.get("leftSec")) > 0.0:
				var a: Dictionary = (x as Dictionary).duplicate()
				a["leftSec"] = Coalition._n(a["leftSec"])
				(out["active"] as Array).append(a)
	var fu: Variant = r.get("followUps")
	if fu is Array:
		for x: Variant in fu:
			if x is Dictionary and not Content.upgrade(str((x as Dictionary).get("upgrade", ""))).is_empty():
				(out["followUps"] as Array).append({"upgrade": str(x["upgrade"]), "leftSec": Coalition._n(x.get("leftSec"))})
	return out


static func sanitize_album(raw: Variant) -> Dictionary:
	var out := fresh_album()
	if raw is Dictionary:
		for k in out.keys():
			out[k] = int(Coalition._n((raw as Dictionary).get(k)))
	return out


static func validate(c: Dictionary) -> PackedStringArray:
	var err := PackedStringArray()
	var ev: Variant = c.get("events")
	if ev == null:
		return err
	if not ev is Array:
		return PackedStringArray(["events: must be a list"])
	var flags: Variant = c.get("flags", {})
	var partner_ids := {}
	for p: Variant in c.get("partners", []):
		if p is Dictionary:
			partner_ids[str(p.get("id", ""))] = true
	var ids := {}
	for e: Variant in ev:
		if not e is Dictionary or str((e as Dictionary).get("id", "")) == "":
			err.append("events: every event needs an id")
			continue
		var id := str(e["id"])
		if ids.has(id):
			err.append("events: duplicate id %s" % id)
		ids[id] = true
		var t := str(e.get("effect", {}).get("type", "none"))
		if not EFFECTS.has(t):
			err.append("events.%s.effect.type: unknown %s" % [id, t])
		for k in Conditions.unknown_keys(e.get("when", {})):
			err.append("events.%s.when: unknown condition %s" % [id, k])
		if e.has("flag") and not (flags is Dictionary and (flags as Dictionary).has(e["flag"])):
			err.append("events.%s.flag: %s is not declared in `flags`" % [id, e["flag"]])
		if t == "screenBlock" and e.get("effect", {}).get("byLeader") != null:
			var by: Variant = e.get("effect", {}).get("byLeader")
			if not by is Dictionary:
				err.append("events.%s.effect.byLeader: must be a map of leader id -> {type}" % id)
			else:
				for lid: Variant in by:
					var bt := str((by[lid] as Dictionary).get("type", "")) if by[lid] is Dictionary else ""
					if not ["block", "none", "tapBuff"].has(bt):
						err.append("events.%s.effect.byLeader.%s.type: block | none | tapBuff, got %s" % [id, lid, bt])
		if t == "brawl":
			for pr: Variant in e.get("effect", {}).get("pairs", []):
				for x: Variant in (pr if pr is Array else []):
					if not partner_ids.has(str(x)):
						err.append("events.%s.effect.pairs: unknown partner %s" % [id, x])
	var pb: Variant = c.get("eventsConfig", {}).get("photobomb", {}) if c.get("eventsConfig") is Dictionary else {}
	if pb is Dictionary and (pb as Dictionary).has("flag") and not (flags is Dictionary and (flags as Dictionary).has(pb["flag"])):
		err.append("eventsConfig.photobomb.flag: %s is not declared in `flags`" % pb["flag"])
	return err
