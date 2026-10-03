class_name Investigation
extends RefCounted
## Suspicion ("חשד") and court day (pitch §10, §11 Q8; deck §G, §H). Pure rules, no nodes. Numbers
## come from content.court (field reference: sim/README.md). State: GameState.investigation.
##
## The loop: shady money sources feed the meter → at max a summons opens the court card → the
## player testifies (court day: ₪/s × courtBpsMult and, with courtPausesTaps, no taps for
## courtDaySec; then suspicion falls to the round's floor) or postpones with "התייעצות ביטחונית"
## (cost treasuryPct × growth^n of the treasury, a shrinking cooldown, the excuse one sentence
## longer). A summons left alone testifies by itself after summonsAutoTestifySec. The suitcase can
## land on an aide; dropping him ("אני לא מכיר אותו") resets suspicion to the floor for a
## permanent base × baseMultPerDrop.
##
## Gain is scale-free: rate = Σ weight[source] × (that source's share of ₪/s). A source's weight is
## the pts/s it would add if it were all your income, so exponential growth never changes the heat.
## Optional: producers[].suspicionPerBuy adds per unit bought, / (1 + ownedBefore / 10).

const PHASES := ["idle", "summons", "court", "postponed"]

static var _installed := false


static func install() -> void:
	if _installed:
		return
	_installed = true
	Economy.MODIFIERS.append(_apply_modifiers)


## The round's hazard words (the view's copy): {skin: court | press, meterName, dayTitle, …,
## postponeVerb, excuses[6]} from the leader's kit over leaderSelect.hazardSkins (Leaders.hazard).
## The numbers are the same for every skin.
static func skin(s: GameState) -> Dictionary:
	return Leaders.hazard(Leaders.current(s))


static func cfg() -> Dictionary:
	var c: Variant = Content.data().get("court")
	return c if c is Dictionary else {}


static func active() -> bool:
	return not cfg().is_empty()


static func _num(key: String, dflt: float) -> float:
	return float(cfg().get(key, dflt))


static func _pp() -> Dictionary:
	return cfg().get("postpone", {})


static func fresh_state() -> Dictionary:
	return {
		"suspicion": 0.0, "phase": "idle", "leftSec": 0.0, "summonsSec": 0.0, "frozenSec": 0.0,
		"postponements": 0, "postponementsLifetime": 0, "courtDays": 0, "pressDays": 0,
		"aideHolding": 0.0, "aideDrops": 0, "pardons": 0, "lastStamp": 0, "revealed": false,
		"courtReason": "testified",   # how the running court day began: testified | served
	}


static func _i(s: GameState) -> Dictionary:
	return s.investigation


static func suspicion(s: GameState) -> float:
	return float(s.investigation.get("suspicion", 0.0))


static func phase(s: GameState) -> String:
	return str(s.investigation.get("phase", "idle"))


## pitch §11 Q8: after election n, suspicion starts at min(floorPerRoundPct × n, floorMaxPct).
## The thermometer draws this as the hatched segment.
static func floor_pct(s: GameState) -> float:
	# counted from the round suspicion opens in (the reveal ladder): it starts that round at 0
	var rounds := maxi(0, s.evolutions - Reveal.round_of("suspicion")) if not Reveal.force_all else s.evolutions
	return minf(_num("floorPerRoundPct", 0.0) * rounds, _num("floorMaxPct", 0.0))


static func shady_owned(s: GameState) -> int:
	var n := 0
	for id: Variant in cfg().get("sources", {}):
		n += s.owned_of(str(id))
	return n


## Suspicion points per second right now (0 while frozen, in court or waiting on the court card).
static func gain_rate(s: GameState, d: Economy.Derived) -> float:
	if not active() or phase(s) != "idle" or float(_i(s)["frozenSec"]) > 0.0:
		return 0.0
	var total := 0.0
	for id: Variant in d.producer_bps:
		total += float(d.producer_bps[id])
	if total <= 0.0:
		return 0.0
	var rate := 0.0
	var src: Dictionary = cfg().get("sources", {})
	for id: Variant in src:
		rate += float(src[id]) * float(d.producer_bps.get(id, 0.0)) / total
	return rate * d.suspicion_gain_mult


## Economy.buy_producer's hook: producers[].suspicionPerBuy (optional) per unit bought.
static func on_buy(s: GameState, id: String, qty: int, owned_before: int) -> void:
	if not active() or not Reveal.on(s, "suspicion") or qty <= 0:
		return
	var spb := float(Content.producer(id).get("suspicionPerBuy", 0.0))
	if spb <= 0.0:
		return
	var g := 0.0
	for i in mini(qty, 100000):
		g += spb / (1.0 + float(owned_before + i) / 10.0)
	add(s, g * Economy.derive(s).suspicion_gain_mult)


static func _apply_modifiers(s: GameState, d: Economy.Derived) -> void:
	if not active():
		return
	if phase(s) == "court":
		d.bps_mult *= _num("courtBpsMult", 0.5)
		d.taps_paused = cfg().get("courtPausesTaps", true) == true
	var drops := int(_i(s)["aideDrops"])
	if drops > 0:
		d.base_mult *= pow(float(cfg().get("aide", {}).get("baseMultPerDrop", 1.0)), drops)


# ---------------------------------------------------------------------------------------------
# Time
# ---------------------------------------------------------------------------------------------

## One visible frame. Returns UI events: {ev: revealed|summons|courtStart|courtEnd}. courtEnd
## carries `reason`: "testified" (the player pressed להעיד) or "served" (the summons was left
## alone and testified by itself). A postponement's courtEnd {reason: "postponed"} comes back in
## postpone()'s result, since it is the player's action, not the clock's.
static func tick(s: GameState, dt: float, d: Economy.Derived) -> Array:
	var out: Array = []
	if not active() or not Reveal.on(s, "suspicion"):
		return out
	var st := _i(s)
	if not st["revealed"] and shady_owned(s) > 0:
		st["revealed"] = true   # UX K1: the thermometer slides in with the first shady source
		out.append({"ev": "revealed"})
	var mx := _num("max", 100.0)
	match phase(s):
		"idle":
			if float(st["frozenSec"]) > 0.0:
				st["frozenSec"] = maxf(0.0, float(st["frozenSec"]) - dt)
			else:
				st["suspicion"] = minf(mx, float(st["suspicion"]) + gain_rate(s, d) * dt)
			if float(st["suspicion"]) >= mx:
				_summon(s, out)
		"summons":
			st["summonsSec"] = float(st["summonsSec"]) + dt
			var auto := _num("summonsAutoTestifySec", 0.0)
			if auto > 0.0 and float(st["summonsSec"]) >= auto:
				out.append_array(testify(s, true))
		"court":
			st["leftSec"] = maxf(0.0, float(st["leftSec"]) - dt)
			if float(st["leftSec"]) <= 0.0:
				st["phase"] = "idle"
				st["suspicion"] = floor_pct(s)
				out.append({"ev": "courtEnd", "reason": str(st.get("courtReason", "testified"))})
		"postponed":
			st["leftSec"] = maxf(0.0, float(st["leftSec"]) - dt)
			if float(st["leftSec"]) <= 0.0:
				_summon(s, out)
	return out


static func _summon(s: GameState, out: Array) -> void:
	var st := _i(s)
	st["phase"] = "summons"
	st["summonsSec"] = 0.0
	out.append({"ev": "summons"})


# ---------------------------------------------------------------------------------------------
# Player actions
# ---------------------------------------------------------------------------------------------

## "להעיד": court day starts now. `auto`: the summons testified by itself (summonsAutoTestifySec).
static func testify(s: GameState, auto: bool = false) -> Array:
	var st := _i(s)
	if phase(s) != "summons":
		return []
	st["phase"] = "court"
	st["leftSec"] = _num("courtDaySec", 30.0)
	st["courtReason"] = "served" if auto else "testified"
	# Bibi's court day, or everyone else's press day (same numbers; UX PRESS_DAYS). hazardDays counts
	# both, for the leader-neutral result card (DAYS_*).
	if Leaders.has_court():
		st["courtDays"] = int(st["courtDays"]) + 1
		Meta.bump(s, "courtDays")
	else:
		st["pressDays"] = int(st.get("pressDays", 0)) + 1
		Meta.bump(s, "pressDays")
	Meta.bump(s, "hazardDays")
	return [{"ev": "courtStart", "reason": st["courtReason"]}]


## Lifetime court days (Bibi's rounds) plus press days (everyone else's): the leader-neutral count
## the result card's DAYS_* ("ו־{n} ימים בכותרות") and the deep-link toast read (ShareKit.rounds_days).
static func hazard_days(s: GameState) -> int:
	var st: Dictionary = s.investigation if s.investigation is Dictionary else {}
	return int(st.get("courtDays", 0)) + int(st.get("pressDays", 0))


## The postponement's price: treasuryPct × growth^n % of the treasury (pitch §10.1: the 5th costs
## 80%), and never less than minCostBpsSec × growth^n seconds of ₪/s, so an empty treasury isn't a
## free pass. -1 when the percentage passes maxPct: the player has to testify.
static func postpone_cost(s: GameState, d: Economy.Derived) -> float:
	var p := _pp()
	var n := int(_i(s)["postponements"])
	var g := pow(float(p.get("growth", 2.0)), n)
	var pct := float(p.get("treasuryPct", 5.0)) * g
	if pct > float(p.get("maxPct", 100.0)):
		return -1.0
	return ceilf(maxf(s.bananas * pct / 100.0, float(p.get("minCostBpsSec", 0.0)) * g * d.bps))


static func can_postpone(s: GameState, d: Economy.Derived) -> bool:
	var c := postpone_cost(s, d)
	return phase(s) == "summons" and c >= 0.0 and s.bananas >= c


## "התייעצות ביטחונית": pay, and the summons comes back after a cooldown that shrinks each time.
## Returns {cost, step, cooldownSec, events: [{ev: courtEnd, reason: postponed}]} ({} when it can't).
static func postpone(s: GameState, d: Economy.Derived) -> Dictionary:
	if not can_postpone(s, d):
		return {}
	var cost := postpone_cost(s, d)
	var st := _i(s)
	s.bananas = maxf(0.0, s.bananas - cost)
	st["postponements"] = int(st["postponements"]) + 1
	st["postponementsLifetime"] = int(st["postponementsLifetime"]) + 1
	var cds: Array = _pp().get("cooldownSec", [60])
	st["phase"] = "postponed"
	st["leftSec"] = float(cds[mini(int(st["postponements"]) - 1, cds.size() - 1)])
	Meta.stat_at_least(s, "maxPostponesInRound", float(st["postponements"]))   # trophy "הבורקס סווג"
	return {"cost": cost, "step": excuse_step(s), "cooldownSec": st["leftSec"],
		"events": [{"ev": "courtEnd", "reason": "postponed"}]}


## Which excuse line (deck §H, 1-based) the court card shows: one sentence longer per
## postponement this round, holding at the last step ("loops at step 6").
static func excuse_step(s: GameState) -> int:
	return clampi(int(_i(s)["postponements"]), 1, int(_pp().get("excuseSteps", 6)))


## Suspicion from an outside source (Lapid's audit, Golan's and Distel's payments, the aide).
static func add(s: GameState, pts: float) -> void:
	if not active() or not Reveal.on(s, "suspicion") or phase(s) == "court" or pts <= 0.0:
		return
	var st := _i(s)
	st["suspicion"] = minf(_num("max", 100.0), float(st["suspicion"]) + pts)


## Spin S12 "הוחלט להקים ועדה": suspicion frozen for `sec`.
static func freeze(s: GameState, sec: float) -> void:
	_i(s)["frozenSec"] = maxf(float(_i(s)["frozenSec"]), sec)


## Back to the round's floor (Trump's one-time item, effect "wipeSourceSuspicion").
static func to_floor(s: GameState) -> void:
	if phase(s) == "idle":
		_i(s)["suspicion"] = floor_pct(s)


## A caught suitcase whose money lands on an aide (golden outcome with `aide: true`).
## `pts` < 0: use court.aide.suspicion.
static func aide_catch(s: GameState, award: float, pts: float = -1.0) -> void:
	if not active() or not Reveal.on(s, "suspicion"):
		return
	var st := _i(s)
	st["aideHolding"] = float(st["aideHolding"]) + maxf(0.0, award)
	add(s, pts if pts >= 0.0 else float(cfg().get("aide", {}).get("suspicion", 0.0)))


## The aide drop is Bibi's (it is Qatargate; leader-select-spec §5.6): every other leader's hazard is
## the press skin, with the same meter and numbers but no aide and no pardon desk.
static func can_drop_aide(s: GameState) -> bool:
	return active() and Leaders.has_court() and float(_i(s)["aideHolding"]) > 0.0 and phase(s) != "court"


## "אני לא מכיר אותו": suspicion to the floor, never below it; a pending court card closes; the
## base pays baseMultPerDrop forever (pitch §10.4). Not during a court day (§10.6).
static func drop_aide(s: GameState) -> bool:
	if not can_drop_aide(s):
		return false
	var st := _i(s)
	st["suspicion"] = floor_pct(s)
	st["phase"] = "idle"
	st["leftSec"] = 0.0
	st["aideHolding"] = 0.0
	st["aideDrops"] = int(st["aideDrops"]) + 1
	Meta.bump(s, "aideDrops")
	return true


## The pardon desk (deck §H): a stamp line 1..stamps, never the same twice in a row.
## 0 outside Bibi's round (the desk is his, and its event never fires there).
static func request_pardon(s: GameState, rng: Callable = randf) -> int:
	if not Leaders.has_court():
		return 0
	var st := _i(s)
	var n := maxi(1, int(cfg().get("pardon", {}).get("stamps", 8)))
	var last := int(st["lastStamp"])
	var k := 1 + int(float(rng.call()) * n) % n
	if k == last and n > 1:
		k = k % n + 1
	st["lastStamp"] = k
	st["pardons"] = int(st["pardons"]) + 1
	Meta.bump(s, "pardonRequests")
	return k


## Election: suspicion to the new round's floor (the cases don't close), postponements reset.
static func on_election(s: GameState) -> void:
	var st := _i(s)
	st["suspicion"] = floor_pct(s)
	st["phase"] = "idle"
	st["leftSec"] = 0.0
	st["summonsSec"] = 0.0
	st["frozenSec"] = 0.0
	st["postponements"] = 0
	st["aideHolding"] = 0.0


# ---------------------------------------------------------------------------------------------
# Save (v3) and the content lint
# ---------------------------------------------------------------------------------------------

static func sanitize(raw: Variant) -> Dictionary:
	var out := fresh_state()
	if not raw is Dictionary:
		return out
	var r: Dictionary = raw
	out["suspicion"] = minf(Coalition._n(r.get("suspicion")), maxf(1.0, _num("max", 100.0)))
	out["phase"] = r.get("phase") if PHASES.has(r.get("phase")) else "idle"
	for k in ["leftSec", "summonsSec", "frozenSec", "aideHolding"]:
		out[k] = Coalition._n(r.get(k))
	for k in ["postponements", "postponementsLifetime", "courtDays", "pressDays", "aideDrops", "pardons", "lastStamp"]:
		out[k] = int(Coalition._n(r.get(k)))
	out["revealed"] = r.get("revealed") == true
	out["courtReason"] = "served" if r.get("courtReason") == "served" else "testified"
	return out


static func validate(c: Dictionary) -> PackedStringArray:
	var err := PackedStringArray()
	var co: Variant = c.get("court")
	if co == null:
		return err
	if not co is Dictionary:
		return PackedStringArray(["court: must be an object"])
	var prods := {}
	for p: Dictionary in c.get("producers", []):
		prods[p["id"]] = true
	var src: Variant = co.get("sources", {})
	if not src is Dictionary or (src as Dictionary).is_empty():
		err.append("court.sources: needs at least one shady producer id")
	else:
		for id: Variant in src:
			if not prods.has(id):
				err.append("court.sources: unknown producer %s" % id)
	var cds: Variant = co.get("postpone", {}).get("cooldownSec", [])
	if not cds is Array or (cds as Array).is_empty():
		err.append("court.postpone.cooldownSec: needs at least one value")
	if float(co.get("courtBpsMult", 0.5)) < 0.0 or float(co.get("courtBpsMult", 0.5)) > 1.0:
		err.append("court.courtBpsMult must be within 0..1")
	return err
