class_name Spins
extends RefCounted
## Spin kinds and the spin effects that are not a plain passive modifier (content `_upgradeRules`;
## pitch §4 spins; deck S02, S05, S07, S08, S10). Pure rules, no nodes. State: GameState.spins.
##
## Kinds (`upgrades[].kind`, default "once"):
##   once        bought once per round (the fork's upgrade). It goes into s.upgrades.
##   consumable  rebuyable in a round. Each buy starts a timed effect; while it runs, the card is
##               off the shelf (it comes back when the effect ends). The n-th rebuy in a round is
##               faded by fatigue^n: the effect's bonus when the effect has a `mult`, otherwise its
##               duration (`fatigueScales: "effect" | "duration"` overrides). Never in s.upgrades.
##   line        `levels[]` bought in order, each at its own cost. Leaves the shelf (and enters
##               s.upgrades) at the last level. Resets with the round.
## Price: `cost`, or for a consumable with `costBpsSeconds` the larger of `cost` and that many
## seconds of ₪/s, rounded up to 3 significant digits; a line's price is its next level's cost.
##
## Effects handled here (Economy.derive runs `_apply_modifiers`):
##   tapBuff {mult, durationSec}            taps × mult while live (S02)
##   idleToTap {durationSec, pourSecPerTap} passive income stops; each tap also pours
##                                          bps × pourSecPerTap (S07)
##   karhiLine {broadcasterDrainPct, basePctThisRound, suspicionAdd}
##                                          per level: +basePctThisRound % on this round's base
##                                          payout, +suspicionAdd suspicion when bought, the
##                                          card's two bars move by broadcasterDrainPct (S08)
##   flightIncome {addPct, capPct}          every Suitcase caught after buying: +addPct % income
##                                          for the rest of the round, up to capPct (S10)
##   basePerOppositionCard {add}            Events.fire pays it (S05)
## A consumable whose effect is one of Economy.ON_BUY (S12's suspicionFreeze) runs that handler
## with the faded duration, and its timer here only keeps the card off the shelf meanwhile.

const KINDS := ["once", "consumable", "line"]
const TYPES := ["tapBuff", "idleToTap", "karhiLine", "flightIncome", "basePerOppositionCard"]

static var _installed := false


static func install() -> void:
	if _installed:
		return
	_installed = true
	Economy.MODIFIERS.append(_apply_modifiers)


static func fresh_state() -> Dictionary:
	return {"buys": {}, "levels": {}, "active": [], "flights": 0}


static func kind(u: Dictionary) -> String:
	var k := str(u.get("kind", "once"))
	return k if KINDS.has(k) else "once"


static func levels_of(u: Dictionary) -> Array:
	var l: Variant = u.get("levels")
	return l if l is Array else []


static func level(s: GameState, id: String) -> int:
	return int(s.spins["levels"].get(id, 0))


static func buys(s: GameState, id: String) -> int:
	return int(s.spins["buys"].get(id, 0))


## The live timed entry of a consumable ({} when none).
static func live(s: GameState, id: String) -> Dictionary:
	for a: Dictionary in s.spins["active"]:
		if a["id"] == id:
			return a
	return {}


## On the shelf by kind (the unlock conditions are Economy.upgrade_unlocked's).
static func on_shelf(s: GameState, u: Dictionary) -> bool:
	var id: String = u["id"]
	match kind(u):
		"consumable":
			return live(s, id).is_empty()
		"line":
			return level(s, id) < levels_of(u).size() and not s.upgrades.has(id)
	return not s.upgrades.has(id)


## What the next buy costs now (-1 when there is nothing left to buy: a finished line).
static func price(s: GameState, u: Dictionary, d: Economy.Derived = null) -> float:
	if kind(u) == "line":
		var lv := levels_of(u)
		var n := level(s, u["id"])
		if n >= lv.size():
			return -1.0
		return float((lv[n] as Dictionary).get("cost", u.get("cost", 0.0))) if lv[n] is Dictionary else float(lv[n])
	var base := float(u.get("cost", 0.0))
	if u.has("costBpsSeconds"):
		if d == null:
			d = Economy.derive(s)
		base = maxf(base, ceil_sig(float(u["costBpsSeconds"]) * d.bps, 3))
	return Economy.clampf_num(base)


## Rounds up to `digits` significant digits (1234 -> 1240 at 3). Whole shekels at least.
static func ceil_sig(v: float, digits: int) -> float:
	if not (v > 0.0) or is_inf(v):
		return maxf(0.0, v) if not is_nan(v) else 0.0
	var step := maxf(1.0, pow(10.0, floorf(log(v) / log(10.0)) - float(digits - 1)))
	return ceilf(v / step - 1e-9) * step


## The effect of a consumable's next buy with fatigue applied: {effect, durationSec, n}.
static func faded(s: GameState, u: Dictionary) -> Dictionary:
	var e: Dictionary = (u.get("effect", {}) as Dictionary).duplicate()
	var n := buys(s, u["id"])
	var f := pow(clampf(float(u.get("fatigue", 1.0)), 0.0, 1.0), n)
	var scales := str(u.get("fatigueScales", "effect" if e.has("mult") else "duration"))
	if scales == "effect" and e.has("mult"):
		e["mult"] = 1.0 + (float(e["mult"]) - 1.0) * f
	elif e.has("durationSec"):
		e["durationSec"] = float(e["durationSec"]) * f
	return {"effect": e, "durationSec": float(e.get("durationSec", 0.0)), "n": n}


## Economy.buy_upgrade's second half, after the price is paid: the kind's bookkeeping and the
## effect. Returns the buy's result for the UI: {kind, level?, n?, durationSec?}.
static func on_bought(s: GameState, u: Dictionary) -> Dictionary:
	var id: String = u["id"]
	var e: Dictionary = u.get("effect", {})
	match kind(u):
		"consumable":
			var f := faded(s, u)
			var fe: Dictionary = f["effect"]
			s.spins["buys"][id] = int(f["n"]) + 1
			var ob: Variant = Economy.ON_BUY.get(fe.get("type", ""))
			if ob != null:
				(ob as Callable).call(s, fe)
			var sec := float(f["durationSec"])
			if sec > 0.0:
				(s.spins["active"] as Array).append({"id": id, "type": str(fe.get("type", "")), "leftSec": sec,
					"durationSec": sec, "mult": float(fe.get("mult", 1.0)), "pour": float(fe.get("pourSecPerTap", 0.0))})
			return {"kind": "consumable", "n": int(f["n"]) + 1, "durationSec": sec}
		"line":
			var n := level(s, id) + 1
			s.spins["levels"][id] = n
			if e.get("type", "") == "karhiLine":
				Investigation.add(s, float(e.get("suspicionAdd", 0.0)))
			if n >= levels_of(u).size():
				s.upgrades.append(id)
			return {"kind": "line", "level": n}
	s.upgrades.append(id)
	var h: Variant = Economy.ON_BUY.get(e.get("type", ""))
	if h != null:
		(h as Callable).call(s, e)
	return {"kind": "once"}


## For the spin card (engine): {kind, price, level, levels, worn (the "שחוק" tag), liveSec,
## bars {public, friendly} for S08's card-only bars, flights, flightPct}.
static func card(s: GameState, id: String, d: Economy.Derived = null) -> Dictionary:
	var u := Content.upgrade(id)
	if u.is_empty():
		return {}
	var e: Dictionary = u.get("effect", {})
	var out := {"kind": kind(u), "price": price(s, u, d), "level": level(s, id), "levels": levels_of(u).size(),
		"worn": kind(u) == "consumable" and buys(s, id) > 0, "liveSec": float(live(s, id).get("leftSec", 0.0))}
	if e.get("type", "") == "karhiLine":
		var drained := minf(100.0, float(e.get("broadcasterDrainPct", 20.0)) * level(s, id))
		out["bars"] = {"public": 100.0 - drained, "friendly": drained}
	if e.get("type", "") == "flightIncome":
		out["flights"] = int(s.spins["flights"])
		out["flightPct"] = flight_pct(s)
	return out


## The live timed spins (for the buff views): [{id, type, leftSec, durationSec}].
static func active_effects(s: GameState) -> Array:
	return s.spins["active"]


# ---------------------------------------------------------------------------------------------
# Economy hooks
# ---------------------------------------------------------------------------------------------

static func _apply_modifiers(s: GameState, d: Economy.Derived) -> void:
	for a: Dictionary in s.spins.get("active", []):
		match str(a["type"]):
			"tapBuff":
				d.tap_mult *= maxf(1.0, float(a.get("mult", 1.0)))
			"idleToTap":
				d.tap_pour_sec = maxf(d.tap_pour_sec, float(a.get("pour", 0.0)))
	var lv: Dictionary = s.spins.get("levels", {})
	for id: Variant in lv:
		var e: Dictionary = Content.upgrade(str(id)).get("effect", {})
		if e.get("type", "") == "karhiLine":
			d.base_pct_round += float(e.get("basePctThisRound", 0.0)) * int(lv[id])
	var fp := flight_pct(s)
	if fp > 0.0:
		d.global_mult *= 1.0 + fp / 100.0


## S10: the income bonus the round's flights have earned (0 without the spin).
static func flight_pct(s: GameState) -> float:
	var e := _owned_effect(s, "flightIncome")
	if e.is_empty():
		return 0.0
	return minf(float(e.get("capPct", 50.0)), float(e.get("addPct", 5.0)) * int(s.spins.get("flights", 0)))


static func _owned_effect(s: GameState, type: String) -> Dictionary:
	for uid in s.upgrades:
		var e: Dictionary = Content.upgrade(uid).get("effect", {})
		if e.get("type", "") == type:
			return e
	return {}


## Economy.apply_golden: a caught Suitcase is a flight once S10 is owned.
static func on_golden_caught(s: GameState) -> void:
	var e := _owned_effect(s, "flightIncome")
	if e.is_empty():
		return
	var cap := ceili(float(e.get("capPct", 50.0)) / maxf(1e-9, float(e.get("addPct", 5.0))))
	s.spins["flights"] = mini(cap, int(s.spins["flights"]) + 1)


## Economy.tick (visible time only): timers run down. Returns the ids whose effect just ended.
static func tick(s: GameState, dt: float) -> Array:
	var ended: Array = []
	var keep: Array = []
	for a: Dictionary in s.spins["active"]:
		a["leftSec"] = float(a["leftSec"]) - dt
		if float(a["leftSec"]) > 0.0:
			keep.append(a)
		else:
			ended.append(a["id"])
	s.spins["active"] = keep
	return ended


## Economy.reset_run: every spin is per round.
static func reset_round(s: GameState) -> void:
	s.spins = fresh_state()


# ---------------------------------------------------------------------------------------------
# Save and the content lint
# ---------------------------------------------------------------------------------------------

## Validates an untrusted dictionary. Ids must be spins of the right kind; live entries are rebuilt
## from the content (a save can't raise a multiplier or stretch a timer past the content's).
static func sanitize(raw: Variant) -> Dictionary:
	var out := fresh_state()
	if not raw is Dictionary:
		return out
	var r: Dictionary = raw
	var b: Variant = r.get("buys")
	if b is Dictionary:
		for k: Variant in b:
			var u := Content.upgrade(str(k))
			if not u.is_empty() and kind(u) == "consumable":
				out["buys"][str(k)] = mini(int(Coalition._n(b[k])), 1000)
	var l: Variant = r.get("levels")
	if l is Dictionary:
		for k: Variant in l:
			var u := Content.upgrade(str(k))
			if not u.is_empty() and kind(u) == "line":
				out["levels"][str(k)] = mini(int(Coalition._n(l[k])), levels_of(u).size())
	var ac: Variant = r.get("active")
	var seen := {}
	if ac is Array:
		for x: Variant in ac:
			if not x is Dictionary:
				continue
			var u := Content.upgrade(str((x as Dictionary).get("id", "")))
			if u.is_empty() or kind(u) != "consumable" or seen.has(u["id"]):
				continue
			seen[u["id"]] = true
			var e: Dictionary = u.get("effect", {})
			var left := minf(Coalition._n(x.get("leftSec")), float(e.get("durationSec", 0.0)))
			if left <= 0.0:
				continue
			(out["active"] as Array).append({"id": u["id"], "type": str(e.get("type", "")), "leftSec": left,
				"durationSec": minf(Coalition._n(x.get("durationSec"), left), float(e.get("durationSec", 0.0))),
				"mult": clampf(float(Coalition._n(x.get("mult"), 1.0)), 1.0, maxf(1.0, float(e.get("mult", 1.0)))),
				"pour": minf(Coalition._n(x.get("pour")), float(e.get("pourSecPerTap", 0.0)))})
	var cap := 0
	for u: Dictionary in Content.upgrades():
		var e: Dictionary = u.get("effect", {})
		if e.get("type", "") == "flightIncome":
			cap = maxi(cap, ceili(float(e.get("capPct", 50.0)) / maxf(1e-9, float(e.get("addPct", 5.0)))))
	out["flights"] = mini(int(Coalition._n(r.get("flights"))), cap)
	return out


## Held content (`unlock.pendingEngine: true` or the older `evolutionsBelow: 0`) may name effects
## that don't exist yet; everything else must be implemented.
static func held(u: Dictionary) -> bool:
	var k: Variant = u.get("unlock", {})
	return k is Dictionary and ((k as Dictionary).get("pendingEngine") == true or
		((k as Dictionary).has("evolutionsBelow") and int((k as Dictionary)["evolutionsBelow"]) <= 0))


static func implemented(type: String) -> bool:
	return Economy.EFFECTS.has(type) or Economy.ON_BUY.has(type) or TYPES.has(type)


static func validate(c: Dictionary) -> PackedStringArray:
	var err := PackedStringArray()
	for u: Variant in c.get("upgrades", []):
		if not u is Dictionary:
			continue
		var id := str(u.get("id", "?"))
		var k := str(u.get("kind", "once"))
		if not KINDS.has(k):
			err.append("upgrades.%s.kind: unknown %s (once | consumable | line)" % [id, k])
		var t := str(u.get("effect", {}).get("type", ""))
		if not held(u) and not implemented(t):
			err.append("upgrades.%s.effect.type: %s is not implemented; hold it with unlock.pendingEngine: true" % [id, t])
		if k == "line":
			var lv: Variant = u.get("levels")
			if not lv is Array or (lv as Array).is_empty():
				err.append("upgrades.%s.levels: a line needs at least one level" % id)
			else:
				for x: Variant in lv:
					if not (x is Dictionary and ((x as Dictionary).get("cost") is float or (x as Dictionary).get("cost") is int)):
						err.append("upgrades.%s.levels: every level needs a numeric cost" % id)
						break
		if k == "consumable":
			var f := float(u.get("fatigue", 1.0))
			if f <= 0.0 or f > 1.0:
				err.append("upgrades.%s.fatigue must be within (0, 1]" % id)
			if float(u.get("effect", {}).get("durationSec", 0.0)) <= 0.0:
				err.append("upgrades.%s.effect.durationSec: a consumable needs a duration" % id)
	return err
