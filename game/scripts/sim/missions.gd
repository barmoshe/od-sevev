class_name Missions
extends RefCounted
## Missions and ranks (AdVenture-Communist style, Bar 2026-10-02: the game had no "what next").
## Pure: no nodes, no clock. Content: `missions {slots, cashFloor, ranks[], list[]}` in
## design/content.json; without that section (the fork's content, the test fixtures) the whole
## system is off and every call is a no-op.
##
##   ranks[]   {title, incomePct}: ranks[0] is where a player starts (rank 1). Reaching rank r pays
##             ranks[r-1].incomePct for good: the bonus is the sum over the ranks reached, applied as
##             a global income multiplier in Economy.derive (like the trophies' morale bonus).
##   list[]    {id, rank, text, goal {type, ...}, reward {type, ...}}. `text` may carry {verbPlural}
##             / {critPlural} (the round's leader's tap words; the view fills them).
##
## Three slots (missions.slots) hold the current rank's missions in list order. A slot is `done` once
## its goal is met (latched: an election that resets the sources never un-does it); "לקחת" (claim)
## pays the reward and refills the slot with the rank's next unclaimed mission. When every mission of
## the rank is claimed, the rank goes up and the slots fill from the next rank.
##
## Goals. Counted ones run from the moment the mission became active (`base` = the lifetime counter
## then), read off counters the sim already keeps, so the only hook is the source purchase count:
##   taps {n}          s.taps_lifetime                crits {n}        s.crits_lifetime
##   earnRun {amount}  s.all_time_money (₪ earned)  suitcases {n}    s.golden_caught_lifetime
##   payDemands {n}    stats.demandsPaid              courtDays {n}    stats.hazardDays (court + press days)
##   elections {n}     s.evolutions                   buySpins {n}     s.upgrades_bought_lifetime
##   useAbility {n}    every leader's abilityUses + unityRefusals (Liberman's ability has no button)
##   sourcesTotal {n}  missions.bought (Economy.buy_producer → on_source_bought)
## State goals (what is true now): ownSource {source, n}, bpsAtLeast {n} (₪/s without frenzy),
## seatsAtLeast {n} (Coalition.seat_info effective).
##
## Rewards: cash {sec} (sec × ₪/s now, at least `min` or missions.cashFloor), frenzy {sec} (the
## Suitcase's income frenzy, golden.outcomes bpsFrenzy's multiplier; refreshes, never stacks),
## basePct {pct} (+pct on this round's base payout: Events' roundBasePct, reset by the election).
##
## Save: GameState.missions {rank, slots [{id, base, done}], claimed [ids], bought}. It persists
## across elections (meta progression). A save without it starts at rank 1 with fresh slots.

const COUNTED := ["sourcesTotal", "earnRun", "taps", "crits", "payDemands", "suitcases", "courtDays", "useAbility", "elections", "buySpins"]
const STATE := ["ownSource", "bpsAtLeast", "seatsAtLeast"]
const REWARDS := ["cash", "frenzy", "basePct"]

static var _installed := false
static var _idx_src: Array = []
static var _idx: Dictionary = {}


static func install() -> void:
	if _installed:
		return
	_installed = true
	Economy.MODIFIERS.append(_apply_modifiers)


static func cfg() -> Dictionary:
	var m: Variant = Content.data().get("missions")
	return m if m is Dictionary else {}


static func active() -> bool:
	var l: Variant = cfg().get("list")
	return l is Array and not (l as Array).is_empty()


static func list() -> Array:
	var l: Variant = cfg().get("list")
	return l if l is Array else []


static func ranks() -> Array:
	var r: Variant = cfg().get("ranks")
	return r if r is Array else []


static func slot_count() -> int:
	return clampi(int(cfg().get("slots", 3)), 1, 5)


static func mission(id: String) -> Dictionary:
	var l := list()   # keyed on the list itself: a test may swap the missions section in place
	if not is_same(_idx_src, l) or _idx.size() > l.size():
		_idx_src = l
		_idx = {}
		for m: Variant in l:
			if m is Dictionary:
				_idx[str((m as Dictionary).get("id", ""))] = m
	return _idx.get(id, {})


## The highest rank number (ranks.size(); at least the last rank any mission belongs to).
static func max_rank() -> int:
	var n := ranks().size()
	for m: Dictionary in list():
		n = maxi(n, int(m.get("rank", 1)))
	return maxi(1, n)


static func fresh_state() -> Dictionary:
	return {"rank": 1, "slots": [], "claimed": [], "bought": 0.0}


static func _st(s: GameState) -> Dictionary:
	if not s.missions is Dictionary or s.missions.is_empty():
		s.missions = fresh_state()
	return s.missions


# ---------------------------------------------------------------------------------------------
# Counters and progress
# ---------------------------------------------------------------------------------------------

## The economy's one hook: a producer purchase of `qty` units (the player's, the butler's).
static func on_source_bought(s: GameState, qty: int) -> void:
	if not active() or qty <= 0:
		return
	var st := _st(s)
	st["bought"] = float(st.get("bought", 0.0)) + float(qty)


## The lifetime counter a counted goal type reads (0 for a state goal).
static func counter(s: GameState, type: String) -> float:
	match type:
		"sourcesTotal":
			return float(_st(s).get("bought", 0.0))
		"earnRun":
			return s.all_time_money
		"taps":
			return float(s.taps_lifetime)
		"crits":
			return float(s.crits_lifetime)
		"payDemands":
			return float(s.stats.get("demandsPaid", 0.0))
		"suitcases":
			return float(s.golden_caught_lifetime)
		"courtDays":
			return float(s.stats.get("hazardDays", s.stats.get("courtDays", 0.0)))
		"useAbility":
			var n := 0.0
			for id: Variant in s.leaders:
				var st: Variant = s.leaders[id]
				if st is Dictionary:
					n += float((st as Dictionary).get("abilityUses", 0.0)) + float((st as Dictionary).get("unityRefusals", 0.0))
			return n
		"elections":
			return float(s.evolutions)
		"buySpins":
			return float(s.upgrades_bought_lifetime)
	return 0.0


## The goal's target number.
static func target(goal: Dictionary) -> float:
	return maxf(1.0, float(goal.get("amount", goal.get("n", 1))))


## How far a mission's goal is now (0..target, not clamped): a state goal reads the state, a
## counted one the counter since `base`. `d` is the frame's derive (bpsAtLeast), or null.
static func value(s: GameState, goal: Dictionary, base: float, d: Economy.Derived = null) -> float:
	var t := str(goal.get("type", ""))
	match t:
		"ownSource":
			return float(s.owned_of(str(goal.get("source", ""))))
		"bpsAtLeast":
			return (d if d != null else Economy.derive(s)).bps
		"seatsAtLeast":
			return float(Coalition.seat_info(s).get("effective", 0))
	return maxf(0.0, counter(s, t) - base)


## The slots for the view: [{id, text, rank, goal, reward, value, target, frac, done}].
static func slots_view(s: GameState, d: Economy.Derived = null) -> Array:
	var out: Array = []
	if not active():
		return out
	ensure(s)
	for sl: Dictionary in _st(s)["slots"]:
		var m := mission(str(sl["id"]))
		var g: Dictionary = m.get("goal", {})
		var tg := target(g)
		var v := tg if bool(sl.get("done", false)) else minf(tg, value(s, g, float(sl.get("base", 0.0)), d))
		out.append({"id": sl["id"], "text": str(m.get("text", "")), "rank": int(m.get("rank", 1)), "goal": g,
			"reward": m.get("reward", {}), "value": v, "target": tg, "frac": clampf(v / tg, 0.0, 1.0),
			"done": bool(sl.get("done", false))})
	return out


static func claimable(s: GameState) -> int:
	if not active():
		return 0
	var n := 0
	for sl: Dictionary in _st(s)["slots"]:
		if bool(sl.get("done", false)):
			n += 1
	return n


# ---------------------------------------------------------------------------------------------
# Slots, ticking, claiming
# ---------------------------------------------------------------------------------------------

## The current rank's next missions not yet claimed nor active, in list order.
static func _next_ids(s: GameState, n: int) -> PackedStringArray:
	var st := _st(s)
	var out := PackedStringArray()
	var busy := {}
	for sl: Dictionary in st["slots"]:
		busy[str(sl["id"])] = true
	for m: Dictionary in list():
		if out.size() >= n:
			break
		var id := str(m.get("id", ""))
		if int(m.get("rank", 1)) == int(st["rank"]) and not (st["claimed"] as Array).has(id) and not busy.has(id):
			out.append(id)
	return out


## Fills empty slots from the current rank (each new mission's base is the counter now).
static func ensure(s: GameState) -> void:
	if not active() or not Reveal.on(s, "missions"):
		return
	var st := _st(s)
	var slots: Array = st["slots"]
	if slots.size() >= slot_count():
		return
	for id in _next_ids(s, slot_count() - slots.size()):
		slots.append(_new_slot(s, id))


static func _new_slot(s: GameState, id: String) -> Dictionary:
	var g: Dictionary = mission(id).get("goal", {})
	return {"id": id, "base": counter(s, str(g.get("type", ""))), "done": false}


## Every frame (or every few): fills the slots and latches finished goals. Returns the ids that
## just finished (the view's "משימה הושלמה" toast).
static func tick(s: GameState, d: Economy.Derived = null) -> PackedStringArray:
	var out := PackedStringArray()
	if not active() or not Reveal.on(s, "missions"):
		return out
	ensure(s)
	for sl: Dictionary in _st(s)["slots"]:
		if bool(sl.get("done", false)):
			continue
		var g: Dictionary = mission(str(sl["id"])).get("goal", {})
		if value(s, g, float(sl.get("base", 0.0)), d) >= target(g):
			sl["done"] = true
			out.append(str(sl["id"]))
	return out


## What a reward pays now: {type, cash, sec, pct} (the claim's numbers; the view's label reads it).
static func reward_now(s: GameState, r: Dictionary, d: Economy.Derived = null) -> Dictionary:
	var t := str(r.get("type", ""))
	match t:
		"cash":
			var bps := (d if d != null else Economy.derive(s)).bps
			var lo := float(r.get("min", cfg().get("cashFloor", 50.0)))
			return {"type": t, "cash": Economy.clampf_num(ceilf(maxf(lo, float(r.get("sec", 60.0)) * bps))), "sec": float(r.get("sec", 60.0))}
		"frenzy":
			return {"type": t, "sec": float(r.get("sec", 15.0)), "mult": float(Content.outcome_of_type("bpsFrenzy").get("mult", 1.0))}
		"basePct":
			return {"type": t, "pct": float(r.get("pct", 0.0))}
	return {"type": t}


## "לקחת" on slot `i`. Returns {ok, id, reward (reward_now), rankUp: {} | {rank, title, incomePct}}.
static func claim(s: GameState, i: int, d: Economy.Derived = null) -> Dictionary:
	if not active():
		return {"ok": false}
	var st := _st(s)
	var slots: Array = st["slots"]
	if i < 0 or i >= slots.size() or not bool((slots[i] as Dictionary).get("done", false)):
		return {"ok": false}
	var id := str((slots[i] as Dictionary)["id"])
	var r := reward_now(s, mission(id).get("reward", {}), d)
	match str(r["type"]):
		"cash":
			Economy.add_money(s, float(r["cash"]))
		"frenzy":
			s.buff_frenzy = maxf(s.buff_frenzy, float(r["sec"]))
		"basePct":
			if s.events is Dictionary:
				s.events["roundBasePct"] = float(s.events.get("roundBasePct", 0.0)) + float(r["pct"])
	slots.remove_at(i)
	(st["claimed"] as Array).append(id)
	var nxt := _next_ids(s, 1)   # the next mission takes the claimed one's place in the list
	if not nxt.is_empty():
		slots.insert(i, _new_slot(s, nxt[0]))
	var up := {}
	ensure(s)
	if slots.is_empty() and int(st["rank"]) < max_rank():
		st["rank"] = int(st["rank"]) + 1
		up = {"rank": int(st["rank"]), "title": rank_title(int(st["rank"])), "incomePct": rank_pct(int(st["rank"]))}
		ensure(s)
	return {"ok": true, "id": id, "reward": r, "rankUp": up}


# ---------------------------------------------------------------------------------------------
# Ranks
# ---------------------------------------------------------------------------------------------

static func rank(s: GameState) -> int:
	return int(s.missions.get("rank", 1)) if active() and s.missions is Dictionary else 1


static func rank_title(r: int) -> String:
	var rs := ranks()
	return str((rs[clampi(r - 1, 0, rs.size() - 1)] as Dictionary).get("title", "")) if not rs.is_empty() else ""


## The income bonus reaching rank r pays (ranks[r-1].incomePct).
static func rank_pct(r: int) -> float:
	var rs := ranks()
	return float((rs[r - 1] as Dictionary).get("incomePct", 0.0)) if r >= 1 and r <= rs.size() else 0.0


## The permanent income bonus in percent: every rank reached so far.
static func income_pct(s: GameState) -> float:
	if not active():
		return 0.0
	var p := 0.0
	for r in range(1, rank(s) + 1):
		p += rank_pct(r)
	return p


## {rank, title, next (title or ""), done (claimed in this rank), total (missions in this rank),
## frac, incomePct (the bonus now), nextPct (what the next rank adds), top (the last rank)}.
static func rank_view(s: GameState) -> Dictionary:
	var r := rank(s)
	var total := 0
	var done := 0
	var claimed: Array = _st(s).get("claimed", []) if active() else []
	for m: Dictionary in list():
		if int(m.get("rank", 1)) == r:
			total += 1
			if claimed.has(str(m.get("id", ""))):
				done += 1
	var top := r >= max_rank()
	return {"rank": r, "title": rank_title(r), "next": "" if top else rank_title(r + 1), "done": done, "total": total,
		"frac": float(done) / float(total) if total > 0 else 1.0, "incomePct": income_pct(s),
		"nextPct": 0.0 if top else rank_pct(r + 1), "top": top and total == done}


static func _apply_modifiers(s: GameState, d: Economy.Derived) -> void:
	var p := income_pct(s)
	if p > 0.0:
		d.global_mult *= 1.0 + p / 100.0


# ---------------------------------------------------------------------------------------------
# Save
# ---------------------------------------------------------------------------------------------

## The load boundary: unknown ids are dropped, a mission claimed or of another rank leaves its slot,
## numbers are clamped. A missing / broken section (an older save) is a fresh rank 1.
static func sanitize(raw: Variant) -> Dictionary:
	var out := fresh_state()
	if not raw is Dictionary or not active():
		return out
	var r: Dictionary = raw
	out["rank"] = clampi(int(_num(r.get("rank"), 1.0)), 1, max_rank())
	out["bought"] = _num(r.get("bought"))
	var claimed: Array = []
	var cl: Variant = r.get("claimed")
	if cl is Array:
		for x: Variant in cl:
			if x is String and not claimed.has(x) and not mission(x).is_empty():
				claimed.append(x)
	out["claimed"] = claimed
	var slots: Array = []
	var seen := {}
	var sv: Variant = r.get("slots")
	if sv is Array:
		for x: Variant in sv:
			if not x is Dictionary or slots.size() >= slot_count():
				continue
			var id := str((x as Dictionary).get("id", ""))
			var m := mission(id)
			if m.is_empty() or seen.has(id) or claimed.has(id) or int(m.get("rank", 1)) != int(out["rank"]):
				continue
			seen[id] = true
			slots.append({"id": id, "base": _num((x as Dictionary).get("base")), "done": (x as Dictionary).get("done") is bool and bool((x as Dictionary)["done"])})
	out["slots"] = slots
	return out


static func _num(v: Variant, dflt: float = 0.0) -> float:
	if (v is float or v is int) and is_finite(float(v)) and float(v) >= 0.0:
		return float(v)
	return dflt
