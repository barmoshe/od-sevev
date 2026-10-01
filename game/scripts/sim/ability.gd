class_name Ability
extends RefCounted
## Leaders v3 phase 2 (design/leaders-v3.md, Bar 2026-10-01): every leader's ACTIVE ability, on top of
## the rule. One shared engine, eight types, all numbers in content (leaders[].rule.active):
##
##   unite       Bibi      "תתאחדו": once a round, the pair (Ben Gvir, Smotrich) argue instead of
##                         asking: both partners go quiet for quietSec (Coalition.quiet).
##   pledgeFlip  Bennett   "לחתום": sign a pledge (events.bennett's pledge effect: the gate +1, then
##                         base). While one is up, "להפוך": the gate drops now, cash = bps × flipBpsSec,
##                         headlines (suspicion) + flipHeadlines, and no base at the end.
##   walkout     Ben Gvir  "אני פורש": he leaves the stage for outSec (income × outBpsMult, no taps),
##                         then "חזרתי": open demands − backDiscountPct, patience full, taps × backTapMult.
##   clauses     Liberman  "המסמך": every "לא אשב" writes a clause; `clauses` of them = + basePct on
##                         this round's base, then a new page. Nothing to press.
##   roundTable  Eisenkot  "שולחן עגול": every member goes quiet for quietSec and open demands
##                         − discountPct.
##   budget      Smotrich  "תקציב בדקה ה־90": every everySec a budget comes up for windowSec at
##                         bps × priceBpsSec. Pay: + basePct (lastBasePct in the last lastSec);
##                         miss it: the gate + missGatePlus for missSec.
##   corridor    Deri      "נסגור במסדרון": the oldest open demand's partner goes quiet for quietSec
##                         and taps × tapMult for tapSec.
##   swipeLeft   Golan     "החלקה שמאלה": every everySec a unity offer comes up for windowSec; swipe
##                         it: + basePct.
##
## Phase 3, the shared unity offer (leaderSelect.unityOffer, Bar 2026-10-01): every OTHER opposition
## leader (side "opposition", type not swipeLeft) also gets Netanyahu's offer every everySec for
## windowSec. While it is up the chip says "לא"; a tap refuses it (+ basePct, the leader's own line from
## kit.unity.refuse, stats.unityRefusals). Ignoring it does nothing. It shares the state below
## (uPhase, uT, uNext) and never lands on the court day or over the leader's own live ability.
##
## State: s.leader_round["ability"] {leader, cd, phase, t, next, price, basePct, n, seen, used, uPhase,
## uT, uNext}, reset
## per round and per leader (sanitized by Leaders.sanitize_into through `sanitize`). Pure: no nodes.
## Ticked by Politics.tick (so the vote card holds it like everything else).

const TYPES := ["unite", "pledgeFlip", "walkout", "clauses", "roundTable", "budget", "corridor", "swipeLeft"]
const PHASES := ["", "out", "offer"]


## The round's ability definition (rule.active), {} when the leader has none.
static func def(s: GameState) -> Dictionary:
	if s == null or not Leaders.active():
		return {}
	var a: Variant = Leaders.rule(Leaders.current(s)).get("active")
	return a if a is Dictionary and TYPES.has(str((a as Dictionary).get("type", ""))) else {}


static func type(s: GameState) -> String:
	return str(def(s).get("type", ""))


static func copy(s: GameState) -> Dictionary:
	var c: Variant = def(s).get("copy")
	return c if c is Dictionary else {}


static func _fresh(leader: String) -> Dictionary:
	return {"leader": leader, "cd": 0.0, "phase": "", "t": 0.0, "next": -1.0, "price": 0.0, "basePct": 0.0, "n": 0, "seen": -1.0, "used": false,
		"uPhase": "", "uT": 0.0, "uNext": -1.0}


## This round's state; a new leader (or none yet) starts fresh.
static func st(s: GameState) -> Dictionary:
	var lid := Leaders.current(s) if Leaders.active() else ""
	var a: Variant = s.leader_round.get("ability")
	if not a is Dictionary or str((a as Dictionary).get("leader", "")) != lid:
		a = _fresh(lid)
		s.leader_round["ability"] = a
	return a


static func _n(e: Dictionary, k: String, dflt: float) -> float:
	return float(e.get(k, dflt))


# ------------------------------------------------------------------ the shared unity offer

## leaderSelect.unityOffer when this round's leader gets it (opposition, not Golan's own swipe), else {}.
static func unity_def(s: GameState) -> Dictionary:
	if def(s).is_empty() or type(s) == "swipeLeft":
		return {}
	if str(Leaders.leader(Leaders.current(s)).get("side", "")) != "opposition":
		return {}
	var u: Variant = Leaders.ls().get("unityOffer")
	return u if u is Dictionary else {}


static func unity_copy(s: GameState) -> Dictionary:
	var c: Variant = unity_def(s).get("copy")
	return c if c is Dictionary else {}


static func unity_open(s: GameState) -> bool:
	return not unity_def(s).is_empty() and str(st(s).get("uPhase", "")) == "offer"


## The leader's own refusal (kit.unity.refuse).
static func unity_refuse_line(s: GameState) -> String:
	var u: Variant = Leaders.kit(Leaders.current(s)).get("unity")
	return str((u as Dictionary).get("refuse", "")) if u is Dictionary else ""


static func _refuse_unity(s: GameState) -> Dictionary:
	var u := unity_def(s)
	var a := st(s)
	var pct := _n(u, "basePct", 1.0)
	a["basePct"] = float(a["basePct"]) + pct
	a["uPhase"] = ""
	a["uT"] = 0.0
	a["uNext"] = _n(u, "everySec", 240.0)
	Leaders._bump(s, Leaders.current(s), "unityRefusals", 1.0)
	return {"ok": true, "kind": "unityRefuse", "events": [{"ev": "ability", "kind": "unityRefuse", "pct": pct}]}


static func _tick_unity(s: GameState, dt: float, e: Dictionary, a: Dictionary) -> Array:
	var u := unity_def(s)
	if u.is_empty():
		return []
	if str(a["uPhase"]) == "offer":
		a["uT"] = float(a["uT"]) - dt
		if float(a["uT"]) > 0.0:
			return []
		a["uPhase"] = ""
		a["uT"] = 0.0
		a["uNext"] = _n(u, "everySec", 240.0)
		return [{"ev": "ability", "kind": "unityMissed"}]
	if float(a["uNext"]) < 0.0:
		a["uNext"] = _n(u, "firstSec", 150.0)
	a["uNext"] = maxf(0.0, float(a["uNext"]) - dt)
	if float(a["uNext"]) > 0.0:
		return []
	# it waits out the court day and the leader's own live ability (a walk-off, a pledge to flip)
	var court := Investigation.active() and Investigation.phase(s) == "court"
	var busy := str(a["phase"]) != "" or (str(e["type"]) == "pledgeFlip" and Events.is_active(s, "pledge"))
	if court or busy:
		return []
	a["uPhase"] = "offer"
	a["uT"] = _n(u, "windowSec", 20.0)
	return [{"ev": "ability", "kind": "unityOffer"}]


# ------------------------------------------------------------------ the button

## Why the ability can't be used now: "" when it can, else none | passive | cooldown | out | court |
## used | pair | empty | nooffer | cost.
static func block(s: GameState, d: Economy.Derived = null) -> String:
	var e := def(s)
	if e.is_empty():
		return "none"
	var a := st(s)
	if unity_open(s):
		return ""   # the chip refuses the unity offer
	match str(e["type"]):
		"clauses":
			return "passive"
		"unite":
			if bool(a["used"]):
				return "used"
			var pair: Array = e.get("pair", [])
			if pair.size() < 2 or Coalition.status(s, str(pair[0])) != "member" or Coalition.status(s, str(pair[1])) != "member":
				return "pair"
			return ""
		"pledgeFlip":
			if Events.is_active(s, "pledge"):
				return ""   # flip the live pledge
			return "cooldown" if float(a["cd"]) > 0.0 else ""
		"walkout":
			if str(a["phase"]) == "out":
				return "out"
			if Investigation.active() and Investigation.phase(s) == "court":
				return "court"
			return "cooldown" if float(a["cd"]) > 0.0 else ""
		"roundTable":
			if float(a["cd"]) > 0.0:
				return "cooldown"
			return "" if Coalition.member_count(s) > 0 else "empty"
		"corridor":
			if float(a["cd"]) > 0.0:
				return "cooldown"
			return "" if not _corridor_target(s).is_empty() else "empty"
		"budget":
			if str(a["phase"]) != "offer":
				return "nooffer"
			return "" if s.bananas >= float(a["price"]) else "cost"
		"swipeLeft":
			return "" if str(a["phase"]) == "offer" else "nooffer"
	return "none"


static func can_use(s: GameState, d: Economy.Derived = null) -> bool:
	return block(s, d) == ""


## Uses the ability. Returns {ok, reason?, kind, events}: `kind` names what happened (unite, sign,
## flip, walkout, roundTable, budgetPaid, corridor, swipe) and `events` are Politics-style ui events.
static func use(s: GameState, d: Economy.Derived) -> Dictionary:
	var why := block(s, d)
	if why != "":
		return {"ok": false, "reason": why}
	if unity_open(s):
		return _refuse_unity(s)
	var e := def(s)
	var a := st(s)
	var out: Array = []
	var kind := ""
	match str(e["type"]):
		"unite":
			var pair: Array = e.get("pair", [])
			for pid: Variant in pair:
				Coalition.quiet(s, str(pid), _n(e, "quietSec", 60.0))
			a["used"] = true
			kind = "unite"
			out.append_array(_line(s, "sys", {"a": str(pair[0]), "b": str(pair[1])}))
		"pledgeFlip":
			if Events.is_active(s, "pledge"):
				var act: Array = s.events["active"]
				for x: Dictionary in act.duplicate():
					if x["type"] == "pledge":
						act.erase(x)
				var cash := maxf(1.0, ceilf((d.bps if d != null else 0.0) * _n(e, "flipBpsSec", 20.0)))
				Economy.add_bananas(s, cash)
				if Investigation.active():
					Investigation.add(s, _n(e, "flipHeadlines", 8.0))
				kind = "flip"
				out.append({"ev": "ability", "kind": "flip", "cash": cash})
			else:
				var pe: Dictionary = Events.event("bennett").get("effect", {}) if Events.event("bennett").get("effect") is Dictionary else {}
				if pe.is_empty():
					pe = {"type": "pledge", "gatePlus": 1, "sec": 45, "baseAdd": 1}
				(Events.EFFECTS["pledge"] as Callable).call(s, pe, d, randf)
				a["cd"] = _n(e, "cooldownSec", 150.0)
				kind = "sign"
				out.append({"ev": "ability", "kind": "sign"})
		"walkout":
			a["phase"] = "out"
			a["t"] = _n(e, "outSec", 20.0)
			kind = "walkout"
			out.append({"ev": "ability", "kind": "walkout"})
		"roundTable":
			for p: Dictionary in Coalition.partners():
				if Coalition.status(s, str(p["id"])) == "member":
					Coalition.quiet(s, str(p["id"]), _n(e, "quietSec", 30.0))
			var nd := Coalition.discount_open(s, 1.0 - _n(e, "discountPct", 20.0) / 100.0)
			a["cd"] = _n(e, "cooldownSec", 150.0)
			kind = "roundTable"
			out.append({"ev": "ability", "kind": "roundTable", "discounted": nd})
		"corridor":
			var m := _corridor_target(s)
			var pid := str(m.get("partner", ""))
			Coalition.quiet(s, pid, _n(e, "quietSec", 45.0))
			Events.leader_buff(s, {"mult": _n(e, "tapMult", 1.2), "durationSec": _n(e, "tapSec", 15.0)})
			a["cd"] = _n(e, "cooldownSec", 60.0)
			kind = "corridor"
			out.append_array(_line(s, "sys", {"partner": pid}))
			out.append({"ev": "ability", "kind": "corridor", "partner": pid})
		"budget":
			var price := float(a["price"])
			s.bananas -= price
			var late := float(a["t"]) <= _n(e, "lastSec", 10.0)
			var pct := _n(e, "lastBasePct" if late else "basePct", 5.0)
			a["basePct"] = float(a["basePct"]) + pct
			a["phase"] = ""
			a["next"] = _n(e, "everySec", 180.0)
			kind = "budgetPaid"
			out.append({"ev": "ability", "kind": "budgetPaid", "late": late, "pct": pct, "price": price})
		"swipeLeft":
			var pct2 := _n(e, "basePct", 2.0)
			a["basePct"] = float(a["basePct"]) + pct2
			a["phase"] = ""
			a["next"] = _n(e, "everySec", 150.0)
			kind = "swipe"
			out.append({"ev": "ability", "kind": "swipe", "pct": pct2})
	Leaders._bump(s, Leaders.current(s), "abilityUses", 1.0)
	return {"ok": true, "kind": kind, "events": out}


## Deri's target: the oldest open member demand that isn't an ultimatum and isn't quiet already.
static func _corridor_target(s: GameState) -> Dictionary:
	for m: Dictionary in Coalition.open_demands(s, false):
		if not Coalition.is_quiet(s, str(m.get("partner", ""))):
			return m
	return {}


## A chat line in the leader's voice (rule.active.copy.<line>), posted as the sys row "ability.line".
static func _line(s: GameState, line: String, fields: Dictionary) -> Array:
	if str(copy(s).get(line, "")) == "" or not Coalition.active() or not Coalition._c(s).get("opened", false):
		return []
	var f := {"leader": Leaders.current(s), "line": line}
	f.merge(fields)
	return Coalition.post_sys(s, "ability.line", f)


## The chat row's text (ChatView.sys_text): the leader's line with {name} / {a} / {b} filled in.
static func line_text(m: Dictionary, names: Callable) -> String:
	var r := Leaders.rule(str(m.get("leader", "")))
	var c: Variant = (r.get("active", {}) as Dictionary).get("copy") if r.get("active") is Dictionary else null
	if not c is Dictionary:
		return ""
	var t := str((c as Dictionary).get(str(m.get("line", "")), ""))
	return Bidi.fill(t, {"name": names.call(str(m.get("partner", ""))), "a": names.call(str(m.get("a", ""))), "b": names.call(str(m.get("b", "")))})


# ------------------------------------------------------------------ time

static func tick(s: GameState, dt: float, d: Economy.Derived) -> Array:
	var e := def(s)
	var out: Array = []
	if e.is_empty():
		return out
	var a := st(s)
	if float(a["cd"]) > 0.0:
		a["cd"] = maxf(0.0, float(a["cd"]) - dt)
	out.append_array(_tick_unity(s, dt, e, a))
	match str(e["type"]):
		"walkout":
			if str(a["phase"]) == "out":
				a["t"] = float(a["t"]) - dt
				if float(a["t"]) <= 0.0:
					a["phase"] = ""
					a["t"] = 0.0
					a["cd"] = _n(e, "cooldownSec", 150.0)
					var nd := Coalition.discount_open(s, 1.0 - _n(e, "backDiscountPct", 40.0) / 100.0)
					Coalition.refill_patience(s)
					Events.leader_buff(s, {"mult": _n(e, "backTapMult", 1.3), "durationSec": _n(e, "backTapSec", 30.0)})
					out.append({"ev": "ability", "kind": "back", "discounted": nd})
					out.append_array(_line(s, "back", {}))
		"clauses":
			var dec := Leaders.stat(s, Leaders.current(s), "declines")
			if float(a["seen"]) < 0.0:
				a["seen"] = dec
			if dec > float(a["seen"]):
				a["n"] = int(a["n"]) + int(dec - float(a["seen"]))
				a["seen"] = dec
				var need := int(_n(e, "clauses", 5.0))
				while int(a["n"]) >= need:
					a["n"] = int(a["n"]) - need
					a["basePct"] = float(a["basePct"]) + _n(e, "basePct", 5.0)
					out.append({"ev": "ability", "kind": "clausesDone", "pct": _n(e, "basePct", 5.0)})
					Leaders._bump(s, Leaders.current(s), "abilityUses", 1.0)
		"budget", "swipeLeft":
			if str(a["phase"]) == "offer":
				a["t"] = float(a["t"]) - dt
				if float(a["t"]) <= 0.0:
					a["phase"] = ""
					a["t"] = 0.0
					a["next"] = _n(e, "everySec", 180.0)
					if str(e["type"]) == "budget":
						Events._activate(s, "gateHold", {}, {"sec": _n(e, "missSec", 30.0), "gatePlus": int(_n(e, "missGatePlus", 1.0))})
						out.append({"ev": "ability", "kind": "budgetMissed"})
					else:
						out.append({"ev": "ability", "kind": "swipeMissed"})
			else:
				if float(a["next"]) < 0.0:
					a["next"] = _n(e, "firstSec", 120.0)
				a["next"] = float(a["next"]) - dt
				# an offer never lands on an open gate (it would cost the 61) nor on the court day
				var court := Investigation.active() and Investigation.phase(s) == "court"
				var gate := d.seats_gate_open if d != null else false
				if float(a["next"]) <= 0.0 and not court and not (str(e["type"]) == "budget" and gate):
					a["phase"] = "offer"
					a["t"] = _n(e, "windowSec", 60.0)
					a["price"] = maxf(10.0, ceilf((d.bps if d != null else 0.0) * _n(e, "priceBpsSec", 20.0))) if str(e["type"]) == "budget" else 0.0
					out.append({"ev": "ability", "kind": "offer", "price": float(a["price"])})
	return out


## The modifiers (Economy.derive): Ben Gvir away (income × outBpsMult, no taps) and every
## ability's round base (+ basePct).
static func apply_modifiers(s: GameState, d: Economy.Derived) -> void:
	var e := def(s)
	if e.is_empty():
		return
	var a := st(s)
	d.base_pct_round += float(a.get("basePct", 0.0))
	if str(e["type"]) == "walkout" and str(a["phase"]) == "out":
		d.bps_mult *= _n(e, "outBpsMult", 0.6)
		d.taps_paused = true


## Ben Gvir is off the stage (the stage walks him off like a court day).
static func walked_out(s: GameState) -> bool:
	return type(s) == "walkout" and str(st(s)["phase"]) == "out"


## The chip (ui/ability_chip.gd): {show, label, sub, ready, fill (0..1), state: ready | cooldown |
## active | offer | passive}. Words are the content's (rule.active.copy).
static func view(s: GameState, d: Economy.Derived = null) -> Dictionary:
	var e := def(s)
	if e.is_empty():
		return {"show": false}
	var a := st(s)
	if unity_open(s):
		var u := unity_def(s)
		return {"show": true, "label": str(unity_copy(s).get("btn", "")), "sub": "%d" % ceili(float(a["uT"])), "ready": true,
			"fill": clampf(float(a["uT"]) / maxf(1.0, _n(u, "windowSec", 20.0)), 0.0, 1.0), "state": "offer"}
	var c := copy(s)
	var why := block(s, d)
	var out := {"show": true, "label": str(c.get("btn", "")), "sub": "", "ready": why == "", "fill": 0.0, "state": "ready" if why == "" else "cooldown"}
	match str(e["type"]):
		"clauses":
			var need := int(_n(e, "clauses", 5.0))
			out["state"] = "passive"
			out["fill"] = float(a["n"]) / float(maxi(1, need))
			out["sub"] = "%d/%d" % [int(a["n"]), need]
		"pledgeFlip":
			if Events.is_active(s, "pledge"):
				out["label"] = str(c.get("btnFlip", out["label"]))
				out["state"] = "active"
		"walkout":
			if str(a["phase"]) == "out":
				out["label"] = str(c.get("btnOut", out["label"]))
				out["state"] = "active"
				out["fill"] = clampf(float(a["t"]) / maxf(1.0, _n(e, "outSec", 20.0)), 0.0, 1.0)
				out["sub"] = "%d" % ceili(float(a["t"]))
		"budget", "swipeLeft":
			if str(a["phase"]) == "offer":
				out["label"] = str(c.get("btnOffer", out["label"]))
				out["state"] = "offer"
				out["fill"] = clampf(float(a["t"]) / maxf(1.0, _n(e, "windowSec", 60.0)), 0.0, 1.0)
				out["sub"] = "%d" % ceili(float(a["t"]))
				out["price"] = float(a["price"])
			else:
				out["show"] = false
		"unite":
			if bool(a["used"]):
				out["show"] = false
	if str(out["state"]) == "cooldown" and float(a["cd"]) > 0.0:
		out["fill"] = 1.0 - clampf(float(a["cd"]) / maxf(1.0, _n(e, "cooldownSec", 150.0)), 0.0, 1.0)
		out["sub"] = "%d" % ceili(float(a["cd"]))
	return out


# ------------------------------------------------------------------ round and save

static func on_election(s: GameState) -> void:
	s.leader_round.erase("ability")


static func sanitize(raw: Variant) -> Dictionary:
	if not raw is Dictionary:
		return {}
	var r: Dictionary = raw
	var lid := str(r.get("leader", ""))
	if lid != "" and not Leaders.playable(lid):
		return {}
	var a := _fresh(lid)
	for k in ["cd", "t", "next", "price", "basePct", "seen", "uT", "uNext"]:
		var v: Variant = r.get(k)
		if (v is float or v is int) and is_finite(float(v)):
			a[k] = float(v)
	a["cd"] = clampf(float(a["cd"]), 0.0, 600.0)
	a["t"] = clampf(float(a["t"]), 0.0, 600.0)
	a["basePct"] = clampf(float(a["basePct"]), 0.0, 100.0)
	a["n"] = int(clampf(float(r.get("n", 0)) if (r.get("n") is float or r.get("n") is int) else 0.0, 0.0, 99.0))
	a["phase"] = str(r.get("phase", "")) if PHASES.has(str(r.get("phase", ""))) else ""
	a["uPhase"] = "offer" if str(r.get("uPhase", "")) == "offer" else ""
	a["uT"] = clampf(float(a["uT"]), 0.0, 600.0)
	a["uNext"] = clampf(float(a["uNext"]), -1.0, 600.0)
	a["used"] = r.get("used") == true
	return a
