class_name ChatStakes
extends RefCounted
## What an open line in T3 is worth (coalition UX, Bar 2026-10-02: "improve the coalition tasks").
## Pure queries over the sim, no nodes, no rules: the chat view draws them.
##   - a join, rejoin or poach line: the seats it brings ("+12 מנדטים לקואליציה");
##   - an ultimatum: the seats that walk out with it ("בלי תשלום: −12 מנדטים");
##   - a member demand: its patience (coalition.patienceSec) before it turns into an ultimatum, when
##     it can (Coalition._can_threaten: ultimatums unlocked, the partner can leave and counts);
##   - a brawl: the seats it froze;
##   - "לסגור עם כולם": which open lines one press pays, most urgent first.
## Seats are the HUD's number (Coalition.seat_info().effective, "מנדטים X/61"), so an abstainer
## (Gafni: 0 seats, 4 abstentions) reads as what the bar will do, and a newcomer who sends a
## smaller partner out (Coalition._on_joined, "won't sit with") is counted net.
## The previews flip the partner rows in place for one seat_info() call and put every field back.


## The effective seats with `changes` ({id: {field: value}}) applied to the partner rows, then undone.
static func effective_with(s: GameState, changes: Dictionary) -> int:
	var all: Dictionary = s.coalition["partners"]
	var saved := {}
	for id: Variant in changes:
		var had := all.has(id)
		var st := Coalition.ps(s, str(id))
		saved[id] = st.duplicate() if had else null
		for k: Variant in changes[id]:
			st[k] = changes[id][k]
	var eff := int(Coalition.seat_info(s)["effective"])
	for id: Variant in saved:
		if saved[id] == null:
			all.erase(id)
			continue
		var st: Dictionary = all[id]
		for k: Variant in (saved[id] as Dictionary):
			st[k] = saved[id][k]
	return eff


static func effective(s: GameState) -> int:
	return int(Coalition.seat_info(s)["effective"])


## Seats the bar gains if `id` comes in now (a join demand, a rejoin or a poach paid): the members
## who won't sit with them go out (Coalition._on_joined), so the number is net.
static func join_gain(s: GameState, id: String) -> int:
	if not Coalition.active() or Coalition.counts(s, id):
		return 0
	var p := Coalition.partner(id)
	var ch := {id: {"status": "member", "frozen": false, "benchSec": 0.0}}
	for q: Dictionary in Coalition.partners():
		var qid := str(q["id"])
		if qid != id and Coalition.status(s, qid) == "member" and Coalition.wont_sit(p, q):
			ch[qid] = {"status": "absent"}
	return effective_with(s, ch) - effective(s)


## Seats the bar loses if `id` walks out now (an ultimatum runs out). Their merged row goes too.
static func walk_loss(s: GameState, id: String) -> int:
	if not Coalition.active() or not Coalition.counts(s, id):
		return 0
	return effective(s) - effective_with(s, {id: {"status": "left"}})


## Seats a brawl between `a` and `b` keeps out of the vote until "צאו החוצה".
static func frozen_seats(s: GameState, a: String, b: String) -> int:
	if not Coalition.active():
		return 0
	return effective_with(s, {a: {"frozen": false}, b: {"frozen": false}}) - effective(s)


## A member demand's patience: {escalates, left (s), frac (1 → 0), ondeck}. `escalates`: the demand
## turns into an ultimatum when its patience runs out (Coalition._tick_messages); `ondeck`: it ran
## out and waits only for the open ultimatum to close (ultimatum.maxOpen); `quiet`: the partner is
## busy elsewhere (leaders v3), so the clock stands still.
static func patience(s: GameState, m: Dictionary) -> Dictionary:
	var out := {"escalates": false, "left": 0.0, "frac": 0.0, "ondeck": false, "quiet": false}
	if str(m.get("type", "")) != "demand" or m.get("join", false) == true or str(m.get("payable", "")) != "" \
			or str(m.get("state", "")) != "open":
		return out
	var id := str(m.get("partner", ""))
	if not (Coalition.ultimatums_unlocked(s) and Coalition.counts(s, id) and Coalition.can_leave(id)):
		return out
	var full := maxf(1.0, Coalition._num("patienceSec", 60.0))
	var left := maxf(0.0, full - float(m.get("ageSec", 0.0)))
	out["escalates"] = true
	out["left"] = left
	out["frac"] = clampf(left / full, 0.0, 1.0)
	out["ondeck"] = left <= 0.0 and Coalition.open_ultimatums(s) >= int(Coalition._ult().get("maxOpen", 1))
	out["quiet"] = Coalition.is_quiet(s, id)
	return out


## What an open line is worth, for its bubble: {kind: join | walk | patience | "", n, ...}.
static func stake(s: GameState, m: Dictionary) -> Dictionary:
	if s == null or not Coalition.active() or str(m.get("state", "")) != "open" or not Coalition.is_payable(m):
		return {"kind": ""}
	var id := str(m.get("partner", ""))
	var pay := str(m.get("payable", ""))
	var t := str(m.get("type", ""))
	if t == "ultimatum":
		return {"kind": "walk", "n": walk_loss(s, id)}
	if pay == "rejoin" or pay == "poach" or (t == "demand" and m.get("join", false) == true):
		return {"kind": "join", "n": join_gain(s, id)}
	var pt := patience(s, m)
	if bool(pt["escalates"]):
		pt["kind"] = "patience"
		return pt
	return {"kind": ""}


## Seconds until the bank covers `price` at `bps` (0: it does now; -1: no income).
static func eta_sec(have: float, price: float, bps: float) -> float:
	if have >= price:
		return 0.0
	if bps <= 0.0:
		return -1.0
	return (price - have) / bps


## The open lines "לסגור עם כולם" pays, in order: [seq]. Every open payable line but a ceremony
## (Regev's needs the ribbon), most urgent first: ultimatums (least time left first), then the
## lines that bring seats (most first; of two who won't sit together only the first), then member
## demands (least patience first). It stops at an ultimatum the bank can't cover (that money is
## the ultimatum's); a smaller line it can't cover is skipped.
static func pay_all_plan(s: GameState) -> Array:
	var out: Array = []
	if s == null or not Coalition.active():
		return out
	var rows: Array = []
	for m: Dictionary in s.coalition.get("chat", []):
		if str(m.get("state", "")) != "open" or not Coalition.is_payable(m) or str(m.get("kind", "money")) == "ceremony":
			continue
		var t := str(m.get("type", ""))
		var rank := 2
		var key := 0.0
		if t == "ultimatum":
			rank = 0
			key = float(m.get("leftSec", 0.0))
		elif str(m.get("payable", "")) != "" or m.get("join", false) == true:
			rank = 1
			key = -float(join_gain(s, str(m.get("partner", ""))))
		else:
			var pt := patience(s, m)
			key = float(pt["left"]) if bool(pt["escalates"]) else 1e9
		rows.append({"m": m, "rank": rank, "key": key})
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a["rank"]) != int(b["rank"]):
			return int(a["rank"]) < int(b["rank"])
		if float(a["key"]) != float(b["key"]):
			return float(a["key"]) < float(b["key"])
		return int(a["m"]["seq"]) < int(b["m"]["seq"]))
	var bank := s.bananas
	var joining: Array = []
	for r: Dictionary in rows:
		var m: Dictionary = r["m"]
		var p := Coalition.partner(str(m.get("partner", "")))
		var price := float(m.get("price", 0.0))
		if int(r["rank"]) == 1:
			var clash := false
			for q: Dictionary in joining:
				if Coalition.wont_sit(p, q):
					clash = true
			if clash:
				continue
		if price > bank:
			if int(r["rank"]) == 0:
				break
			continue
		bank -= price
		out.append(int(m["seq"]))
		if int(r["rank"]) == 1:
			joining.append(p)
	return out


## The plan's total price.
static func plan_total(s: GameState, plan: Array) -> float:
	var t := 0.0
	for seq: Variant in plan:
		t += float(Coalition.message(s, int(seq)).get("price", 0.0))
	return t


## Every open payable line, a ceremony included: "לסגור עם כולם" only when the plan is all of them
## (else "לסגור עם 2").
static func open_lines(s: GameState) -> int:
	var n := 0
	if s == null or not Coalition.active():
		return n
	for m: Dictionary in s.coalition.get("chat", []):
		if str(m.get("state", "")) == "open" and Coalition.is_payable(m):
			n += 1
	return n


## The header's numbers: {open (payable lines), brawl (seats frozen by the open brawl, -1 none)}.
static func summary(s: GameState) -> Dictionary:
	var out := {"open": 0, "brawl": -1}
	if s == null or not Coalition.active():
		return out
	for m: Dictionary in s.coalition.get("chat", []):
		if str(m.get("state", "")) != "open":
			continue
		if Coalition.is_payable(m):
			out["open"] = int(out["open"]) + 1
		elif str(m.get("type", "")) == "brawl":
			out["brawl"] = maxi(0, frozen_seats(s, str(m.get("a", "")), str(m.get("b", ""))))
	return out
