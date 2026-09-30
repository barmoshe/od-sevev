class_name Coalition
extends RefCounted
## The coalition as the group chat "קואליציה 61" (pitch §6, §10.2, §11 Q2-Q4; ux/first-minute.md
## §2.4 C1/C2/U1 and §4). Pure rules, no nodes. Every number comes from content.coalition and
## content.partners[] (field reference: sim/README.md). State lives in GameState.coalition (save v3).
##
## Time rule: call tick() only on visible frames (Politics.tick). Away time never advances a
## demand, an ultimatum or Gotliv's meter, so ultimatums pause while the app is hidden (UX U1).
##
## The chat is a model, not text. Each message has a `type` from UX §4.2; system lines carry the
## UX string id in `key` (chat.sys.*), and partner bubbles name a line of partners[].lines (or
## linesVariants) in `line`, with a `variant` index. The UI renders them. No Hebrew here.
##
## Money: upkeep is a % of ₪/s and a demand costs `demandSec` seconds of current ₪/s (pitch §11),
## never a flat price, so the coalition corner of the triangle scales with the exponential economy.

const STATUSES := ["absent", "pending", "member", "left", "removed", "transferred", "merged"]
const TYPES := ["demand", "ultimatum", "reply", "thanks", "status", "sys", "transfer", "brawl"]
const STATES := ["", "open", "paid", "deleted", "expired", "resolved", "declined"]
const SYS_KEYS := ["chat.sys.created", "chat.sys.joined", "chat.sys.left", "chat.sys.removed", "chat.sys.added",
	"chat.sys.transfer", "chat.sys.brawl", "chat.brawl.after", "chat.sys.muted", "chat.sys.cleared", "chat.sys.declined",
	"chat.sys.merged"]
const LINES := ["demand", "threat", "thanks", "return", "status", "after"]

static var _installed := false


static func install() -> void:
	if _installed:
		return
	_installed = true
	Economy.MODIFIERS.append(_apply_modifiers)


# ---------------------------------------------------------------------------------------------
# Content
# ---------------------------------------------------------------------------------------------

static func cfg() -> Dictionary:
	var c: Variant = Content.data().get("coalition")
	return c if c is Dictionary else {}


## The round's partners: content.partners in the default leader's (Bibi's) round, else the leader's
## lineup dealt onto the shared slots (Leaders.partners, leader-select-spec §5.5).
static func partners() -> Array:
	return Leaders.partners()


## The FTUE C1 partner: the round's leader's slot S1 (Bibi: coalition.firstPartner).
static func first_partner() -> String:
	return Leaders.first_partner()


## The coalition is live only when the content has both sections. Without them every function
## here is a no-op and the 61-seat gate is open, so the engine still runs the fork's content.
static func active() -> bool:
	return not partners().is_empty() and not cfg().is_empty()


static var _index: Dictionary = {}
static var _index_src: Array = []


## By id, through an index rebuilt whenever the content's partners list is a different object
## (Content.load_from / replace). derive() asks this many times per frame.
static func partner(id: String) -> Dictionary:
	var arr := partners()
	if not is_same(arr, _index_src):
		_index_src = arr
		_index = {}
		for p: Variant in arr:
			if p is Dictionary:
				_index[str((p as Dictionary).get("id", ""))] = p
	return _index.get(id, {})


## A coalition config number; the round's leader may override a few (Deri: rejoinMult 1.0,
## Leaders.coalition_override).
static func _num(key: String, dflt: float) -> float:
	var o: Variant = Leaders.coalition_override(key)
	if o != null:
		return float(o)
	return float(cfg().get(key, dflt))


static func _ult() -> Dictionary:
	return cfg().get("ultimatum", {})


# ---------------------------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------------------------

static func fresh_state() -> Dictionary:
	return {
		"opened": false, "seq": 0, "chat": [], "partners": {}, "levels": {},
		"paidRound": 0, "paidLifetime": 0, "leftLifetime": 0, "rejoinsLifetime": 0,
		"nextDemandSec": -1.0, "joinCooldownSec": 0.0, "replyIndex": 0,
		"corridorOpen": false, "corridorMsgs": 0, "transferDone": false, "unread": 0,
		"rot": {},   # "partner:line" -> the next linesVariants index (lifetime)
		"declineCdSec": 0.0,   # Liberman's "לא יושב" cooldown (round)
		"mergeCdSec": 0.0, "mergesRound": 0,   # Golan's "איחוד" (round)
	}


## memberSec: visible seconds as a member this round (Golan's merge needs 60 s). A partner merged
## into another's row has status "merged" and sits in that row's `carry` (like Gotliv's transfer).
static func _fresh_partner() -> Dictionary:
	return {"status": "absent", "meter": 0.0, "carry": [], "frozen": false, "benchSec": 0.0, "corridor": false, "memberSec": 0.0}


static func _c(s: GameState) -> Dictionary:
	return s.coalition


static func ps(s: GameState, id: String) -> Dictionary:
	var all: Dictionary = s.coalition["partners"]
	if not all.has(id):
		all[id] = _fresh_partner()
	return all[id]


static func status(s: GameState, id: String) -> String:
	var all: Dictionary = s.coalition["partners"]
	return str(all[id]["status"]) if all.has(id) else "absent"


## A member whose seats, upkeep and effects count right now (not brawling, not nipped by Kaia).
static func counts(s: GameState, id: String) -> bool:
	var all: Dictionary = s.coalition["partners"]
	if not all.has(id):
		return false
	var st: Dictionary = all[id]
	return st["status"] == "member" and not st["frozen"] and float(st["benchSec"]) <= 0.0


static func member_count(s: GameState) -> int:
	var n := 0
	for p: Dictionary in partners():
		if counts(s, p["id"]):
			n += 1
	return n


static func can_leave(id: String) -> bool:
	return not partner(id).get("cannotLeave", false)


# ---------------------------------------------------------------------------------------------
# Seats and the gate
# ---------------------------------------------------------------------------------------------

## Own seats grow with the top money source owned and with the base (pitch §4, "Seats").
static func own_seats(s: GameState) -> int:
	var o: Dictionary = cfg().get("ownSeats", {})
	var tier := 0
	var ids := Content.producer_ids()
	for i in ids.size():
		if s.owned_of(ids[i]) > 0:
			tier = i + 1
	var base_bonus := floorf(log(1.0 + float(s.thumbs_owned)) / log(2.0))
	var v := float(o.get("base", 0)) + float(o.get("perTier", 0)) * tier + float(o.get("perBaseDoubling", 0)) * base_bonus
	return int(minf(v, float(o.get("max", 1e9))))


## A partner's row: their seats plus anyone who transferred into their row (Gotliv).
static func row_seats(s: GameState, id: String) -> int:
	var n := int(partner(id).get("seats", 0))
	for cid: Variant in ps(s, id)["carry"]:
		n += int(partner(str(cid)).get("seats", 0))
	return n


static func _row_field(s: GameState, id: String, key: String) -> float:
	var v := float(partner(id).get(key, 0.0))
	for cid: Variant in ps(s, id)["carry"]:
		v += float(partner(str(cid)).get(key, 0.0))
	return v


## {own, partners, drain, total, abstain, gate, effective, gateSeats}. Abstainers (Gafni) lower the
## majority to floor((knesset - abstain) / 2) + 1; Bennett's pledge raises it while up.
## `effective` = total + (gateSeats - gate), so the HUD compares one number against 61
## ("מנדטים X/61") whatever the tie trick did.
static func seat_info(s: GameState) -> Dictionary:
	var gate_seats := int(_num("gateSeats", 61))
	if not active():
		return {"own": 0, "partners": 0, "drain": 0, "total": 0, "abstain": 0, "gate": gate_seats, "effective": 0, "gateSeats": gate_seats}
	var own := own_seats(s)
	var ps_ := 0
	var abstain := 0.0
	for p: Dictionary in partners():
		if counts(s, p["id"]):
			ps_ += row_seats(s, p["id"])
			abstain += _row_field(s, p["id"], "abstain")
	var drain := Events.seat_drain(s)
	var total := maxi(0, own + ps_ - drain)
	var knesset := int(_num("knessetSize", 120))
	var gate := mini(gate_seats, int(floorf((knesset - abstain) / 2.0)) + 1) + Events.gate_plus(s)
	return {"own": own, "partners": ps_, "drain": drain, "total": total, "abstain": int(abstain), "gate": gate,
		"effective": total + (gate_seats - gate), "gateSeats": gate_seats}


## The 61 gate for "עוד סבב!". Open when the content has no coalition (the fork's content).
static func gate_open(s: GameState) -> bool:
	if not active():
		return true
	var si := seat_info(s)
	return int(si["effective"]) >= int(si["gateSeats"])


## Total upkeep, % of ₪/s, capped at upkeepMaxPct.
static func upkeep_pct(s: GameState) -> float:
	if not active():
		return 0.0
	var u := 0.0
	for p: Dictionary in partners():
		if counts(s, p["id"]):
			u += _row_field(s, p["id"], "upkeepPct")
	return minf(u, _num("upkeepMaxPct", 100.0))


## One pass over the partners per derive: upkeep, their effects, and the seat gate (derive() is
## called many times a frame, so this stays a single loop).
static func _apply_modifiers(s: GameState, d: Economy.Derived) -> void:
	if not active():
		return
	var up := 0.0
	var seats := 0
	var abstain := 0.0
	var all: Dictionary = s.coalition["partners"]
	for p: Dictionary in partners():
		var id: String = p["id"]
		if not all.has(id):
			continue
		var st: Dictionary = all[id]
		if st["status"] != "member" or st["frozen"] or float(st["benchSec"]) > 0.0:
			continue
		up += float(p.get("upkeepPct", 0.0))
		seats += int(p.get("seats", 0))
		abstain += float(p.get("abstain", 0.0))
		for cid: Variant in st["carry"]:
			var q := partner(str(cid))
			up += float(q.get("upkeepPct", 0.0))
			seats += int(q.get("seats", 0))
			abstain += float(q.get("abstain", 0.0))
			if status(s, str(cid)) == "merged":   # a merged partner is still in the coalition
				for e: Variant in q.get("effects", []):
					var hq: Variant = Economy.EFFECTS.get((e as Dictionary).get("type", ""))
					if hq != null:
						(hq as Callable).call(e, d)
		for e: Variant in p.get("effects", []):
			var h: Variant = Economy.EFFECTS.get((e as Dictionary).get("type", ""))
			if h != null:
				(h as Callable).call(e, d)
	d.bps_mult *= 1.0 - minf(up, _num("upkeepMaxPct", 100.0)) / 100.0
	var gate_seats := int(_num("gateSeats", 61))
	var total := maxi(0, own_seats(s) + seats - Events.seat_drain(s))
	var gate := mini(gate_seats, int(floorf((_num("knessetSize", 120) - abstain) / 2.0)) + 1) + Events.gate_plus(s)
	d.seats_gate_open = total + (gate_seats - gate) >= gate_seats


# ---------------------------------------------------------------------------------------------
# Rules
# ---------------------------------------------------------------------------------------------

## UX U1: no ultimatum before 3:00 of active play and 2 paid demands (pitch §11 Q3).
static func ultimatums_unlocked(s: GameState) -> bool:
	var u := _ult()
	return int(_c(s)["paidLifetime"]) >= int(u.get("minDemandsPaid", 2)) \
		and float(s.stats.get("playtimeSec", 0.0)) >= float(u.get("minPlaySec", 180.0))


## UX C1 (the sim's half): 3 sources owned and the first demand affordable. The controller adds
## "no modal and last purchase ≥ 2 s ago" through ctx.allowPing.
static func c1_ready(s: GameState) -> bool:
	return active() and not _c(s)["opened"] \
		and Conditions.sources_owned(s) >= int(_num("openAtSourcesOwned", 3)) \
		and s.bananas >= _num("firstDemandPrice", 60.0)


## demandSec seconds of current ₪/s × priceMult × priceGrowth^level (Goldknopf), at least minPrice.
## A ceremony (Regev) costs nothing. Whole shekels, rounded up.
static func demand_price(s: GameState, id: String, d: Economy.Derived) -> float:
	var p := partner(id)
	if p.get("demandKind", "money") == "ceremony":
		return 0.0
	var lv := int(_c(s)["levels"].get(id, 0))
	var v := _num("demandSec", 45.0) * d.bps * float(p.get("priceMult", 1.0)) * pow(float(p.get("priceGrowth", 1.0)), lv)
	# Golan's merge: one demand stream for the pair, at the higher of their prices.
	for cid: Variant in ps(s, id)["carry"]:
		if status(s, str(cid)) == "merged":
			var q := partner(str(cid))
			var lq := int(_c(s)["levels"].get(str(cid), 0))
			v = maxf(v, _num("demandSec", 45.0) * d.bps * float(q.get("priceMult", 1.0)) * pow(float(q.get("priceGrowth", 1.0)), lq))
	# The p_deal perk (demandDiscountPct) and Smotrich's "אין כסף" (adds to it).
	var disc := clampf(Meta.effect_value(s, "demandDiscountPct") + Leaders.demand_discount_pct(), 0.0, 90.0)
	if disc > 0.0:
		v *= 1.0 - disc / 100.0
	return ceilf(Economy.clampf_num(maxf(_num("minPrice", 10.0), v)))


## The next price Goldknopf will ask (deck: "עכשיו זה {next_price}").
static func next_price(s: GameState, id: String, d: Economy.Derived) -> float:
	var lv: Dictionary = _c(s)["levels"]
	var was := int(lv.get(id, 0))
	lv[id] = was + 1
	var v := demand_price(s, id, d)
	lv[id] = was
	return v


## A partner's unlock with coalition.unlockScalePerElection applied: runBananasAtLeast grows
## ×scale per election, so each round asks for more earnings than the last (the Designer's rule).
## Also coalition.unlockTimeScalePerElection: runSecAtLeast (round time, the arrival cadence)
## × scale^evolutions, never below unlockTimeMinGapSec × the partner's place in line.
static func unlock_of(s: GameState, p: Dictionary) -> Dictionary:
	var u: Variant = p.get("unlock", {})
	if not u is Dictionary:
		return {"<invalid>": true}
	if s.evolutions == 0:
		return u
	var out: Dictionary = (u as Dictionary).duplicate()
	var scale := _num("unlockScalePerElection", 1.0)
	if scale != 1.0 and out.has("runBananasAtLeast"):
		out["runBananasAtLeast"] = float(u["runBananasAtLeast"]) * pow(scale, s.evolutions)
	var tscale := _num("unlockTimeScalePerElection", 1.0)
	if tscale != 1.0 and out.has("runSecAtLeast"):
		out["runSecAtLeast"] = float(u["runSecAtLeast"]) * pow(tscale, s.evolutions)
	return out


static func message(s: GameState, seq: int) -> Dictionary:
	for m: Dictionary in _c(s)["chat"]:
		if int(m["seq"]) == seq:
			return m
	return {}


## The partner's open payable message (a demand, an ultimatum, a rejoin or a poach line), or {}.
static func open_msg(s: GameState, id: String) -> Dictionary:
	for m: Dictionary in _c(s)["chat"]:
		if m["state"] == "open" and m.get("partner", "") == id and is_payable(m):
			return m
	return {}


static func is_payable(m: Dictionary) -> bool:
	return m["type"] == "demand" or m["type"] == "ultimatum" or str(m.get("payable", "")) != ""


static func open_ultimatums(s: GameState) -> int:
	var n := 0
	for m: Dictionary in _c(s)["chat"]:
		if m["type"] == "ultimatum" and m["state"] == "open":
			n += 1
	return n


## UX chat.threats: "{k} איומי פרישה פתוחים".
static func threat_count(s: GameState) -> int:
	return open_ultimatums(s)


## "Won't sit with" (`excludes`, either way round) with the bigger side first (Game Designer
## 2026-09-30, spec §7.2.2). Two partners who won't sit together never do; of the two, the one who
## brings more (seats + half the abstentions) has precedence:
##   - the smaller does not ask to join while the bigger sits (here), and its open offer (a join
##     demand, a rejoin pill) closes when the bigger comes in (_on_joined);
##   - the bigger may ask or come back while the smaller sits; paying it sends the smaller out
##     (Abbas leaves when Ben Gvir returns, as shipped).
## So a pill never trades seats down. Before, in Bennett's round (Liberman 12 excludes Abbas and
## Gafni), paying Abbas's join silently threw Liberman out with no rejoin pill, and a player who
## pays every pill never reached 61 in 5 of 9 deals.
static func _excluded(s: GameState, p: Dictionary) -> bool:
	var id := str(p.get("id", ""))
	for q: Dictionary in partners():
		var qid := str(q["id"])
		if qid != id and status(s, qid) == "member" and wont_sit(p, q) and weight(q) >= weight(p):
			return true
	return false


## The two won't sit together (either one's `excludes` names the other).
static func wont_sit(a: Dictionary, b: Dictionary) -> bool:
	return (a.get("excludes", []) as Array).has(str(b.get("id", ""))) or (b.get("excludes", []) as Array).has(str(a.get("id", "")))


## What a partner brings to the 61: seats, plus half the abstentions (they lower the majority by half).
static func weight(p: Dictionary) -> float:
	return float(p.get("seats", 0)) + float(p.get("abstain", 0)) / 2.0


## For the UI: every partner's row, in content order.
static func roster(s: GameState) -> Array:
	var out: Array = []
	for p: Dictionary in partners():
		var id: String = p["id"]
		var st := ps(s, id)
		var tr: Variant = p.get("transfer")
		var fire := maxf(1.0, float((tr as Dictionary).get("fireAt", 100.0))) if tr is Dictionary else 100.0
		out.append({
			"id": id, "status": st["status"], "counts": counts(s, id), "seats": row_seats(s, id),
			"upkeepPct": _row_field(s, id, "upkeepPct"), "frozen": st["frozen"], "benched": float(st["benchSec"]) > 0.0,
			"carry": (st["carry"] as Array).duplicate(), "meter": float(st["meter"]) / fire if tr is Dictionary else 0.0,
			"excluded": _excluded(s, p), "side": p.get("side", "coalition"), "corridor": st["corridor"],
			"cardHidden": card_hidden(s, id),
		})
	return out


## The designer's ask (3): a `pollLike` partner (Gotliv, whose card names a seat number) has only
## her partner card (`copy.card`) hidden in the blackout. Her membership, seats, meter, transfer
## and chat bubbles are untouched (her bubbles are poll_like: false). A card that sets its own
## `poll_like` / `pollLike` wins over the partner's flag.
static func card_hidden(s: GameState, id: String) -> bool:
	var p := partner(id)
	if p.is_empty() or Calendar.poll_like_allowed(s):
		return false
	var cd: Variant = p.get("copy", {}).get("card") if p.get("copy") is Dictionary else null
	if cd is Dictionary:
		for k: String in ["poll_like", "pollLike"]:
			if (cd as Dictionary).has(k):
				return (cd as Dictionary)[k] == true
	return p.get("pollLike", p.get("poll_like", false)) == true


# ---------------------------------------------------------------------------------------------
# Chat log
# ---------------------------------------------------------------------------------------------

static func _post(s: GameState, msg: Dictionary, out: Array) -> Dictionary:
	var c := _c(s)
	c["seq"] = int(c["seq"]) + 1
	msg["seq"] = c["seq"]
	if not msg.has("state"):
		msg["state"] = ""
	if not msg.has("partner"):
		msg["partner"] = ""
	(c["chat"] as Array).append(msg)
	c["unread"] = int(c["unread"]) + 1
	_trim(c)
	out.append({"ev": "message", "msg": msg})
	return msg


## Keeps the log at chatMax by dropping the oldest closed messages. Open ones are never dropped.
static func _trim(c: Dictionary) -> void:
	var chat: Array = c["chat"]
	var cap := int(_num("chatMax", 80))
	var i := 0
	while chat.size() > cap and i < chat.size():
		if chat[i]["state"] == "open":
			i += 1
		else:
			chat.remove_at(i)


static func _sys(s: GameState, key: String, fields: Dictionary, out: Array) -> Dictionary:
	var m := {"type": "sys", "key": key}
	m.merge(fields)
	return _post(s, m, out)


static func _reply(s: GameState, out: Array) -> void:
	var c := _c(s)
	c["replyIndex"] = int(c["replyIndex"]) % 3 + 1
	_post(s, {"type": "reply", "n": c["replyIndex"]}, out)


## How many rotations a partner has for a line: partners[].linesVariants[line] (a list) when
## present, else 1 (`lines[line]`, a string; a list there counts too).
static func variant_count(id: String, line: String) -> int:
	var p := partner(id)
	for src: String in ["linesVariants", "lines"]:
		var l: Variant = p.get(src, {}).get(line) if p.get(src) is Dictionary else null
		if l is Array and not (l as Array).is_empty():
			return (l as Array).size()
		if l is String:
			return 1
	return 1


## The designer's rotation (ask 2): each partner walks its variants of a line in order, so no
## bubble repeats until all have been seen. The counter per "partner:line" is saved and survives
## elections. Text: linesVariants[line][variant], or lines[line] when variant is 0.
static func _variant(s: GameState, id: String, line: String) -> int:
	var n := variant_count(id, line)
	if not _c(s).get("rot") is Dictionary:
		_c(s)["rot"] = {}
	var rot: Dictionary = _c(s)["rot"]
	var k := "%s:%s" % [id, line]
	var v := int(rot.get(k, 0)) % n
	rot[k] = (v + 1) % n
	return v


# ---------------------------------------------------------------------------------------------
# Time
# ---------------------------------------------------------------------------------------------

## FTUE C1: the group is created and the first partner posts the fixed first demand.
static func open_group(s: GameState, d: Economy.Derived, rng: Callable = randf) -> Array:
	var out: Array = []
	var c := _c(s)
	if not active() or c["opened"]:
		return out
	c["opened"] = true
	_sys(s, "chat.sys.created", {}, out)
	var first := first_partner()
	if not partner(first).is_empty():
		_post_join(s, first, d, rng, out)
		c["joinCooldownSec"] = _num("joinGapSec", 8.0)
	out.append({"ev": "groupOpened"})
	return out


## One visible frame. Returns UI events: {ev: message|ultimatumMark|partnerLeft|partnerJoined|
## standIn|transfer|groupOpened, ...}.
static func tick(s: GameState, dt: float, d: Economy.Derived, ctx: Dictionary = {}, rng: Callable = randf) -> Array:
	var out: Array = []
	if not active():
		return out
	var c := _c(s)
	if not c["opened"]:
		if ctx.get("allowPing", true) and c1_ready(s):
			out.append_array(open_group(s, d, rng))
		return out
	if float(c.get("declineCdSec", 0.0)) > 0.0:
		c["declineCdSec"] = maxf(0.0, float(c["declineCdSec"]) - dt)
	if float(c.get("mergeCdSec", 0.0)) > 0.0:
		c["mergeCdSec"] = maxf(0.0, float(c["mergeCdSec"]) - dt)
	_finish_grace(s, d)
	for id: Variant in c["partners"]:
		var st: Dictionary = c["partners"][id]
		if st["status"] == "member":
			st["memberSec"] = float(st.get("memberSec", 0.0)) + dt
		if float(st["benchSec"]) > 0.0:
			st["benchSec"] = maxf(0.0, float(st["benchSec"]) - dt)
	_tick_messages(s, dt, out)
	# Partners join one at a time as they unlock (the chat's "joined" cascade).
	c["joinCooldownSec"] = maxf(0.0, float(c["joinCooldownSec"]) - dt)
	if float(c["joinCooldownSec"]) <= 0.0:
		var nxt := _next_join(s, ctx)
		if nxt != "":
			_post_join(s, nxt, d, rng, out)
			c["joinCooldownSec"] = _num("joinGapSec", 8.0)
	_tick_demands(s, dt, d, rng, out)
	_tick_transfers(s, dt, d, out)
	return out


## The finish grace (spec §7.4, ultimatum.finishGraceSec): the frame the 61 gate opens, a running
## ultimatum gets at least that long left, once per ultimatum, so the reach for "עוד סבב!" never
## loses the gate to a timer (the vote hold starts at the press). Not a farm: it only delays an
## expiry by seconds, and it cannot repeat on the same ultimatum.
static func _finish_grace(s: GameState, d: Economy.Derived) -> void:
	var c := _c(s)
	var gate := d.seats_gate_open if d != null else gate_open(s)
	if gate and not bool(c.get("gateWas", false)):
		var g := float(_ult().get("finishGraceSec", 10.0))
		for m: Dictionary in c["chat"]:
			if m["type"] == "ultimatum" and m["state"] == "open" and not m.get("graced", false):
				m["leftSec"] = maxf(float(m["leftSec"]), g)
				m["graced"] = true
	c["gateWas"] = gate


static func _tick_messages(s: GameState, dt: float, out: Array) -> void:
	var marks: Array = _ult().get("marksSec", [])
	var expired: Array = []
	var escalate: Array = []
	for m: Dictionary in _c(s)["chat"]:
		if m["state"] != "open":
			continue
		if m["type"] == "ultimatum":
			var before := float(m["leftSec"])
			m["leftSec"] = maxf(0.0, before - dt)
			for mk: Variant in marks:
				if before > float(mk) and float(m["leftSec"]) <= float(mk):
					out.append({"ev": "ultimatumMark", "seq": m["seq"], "partner": m["partner"], "left": int(mk)})
			if float(m["leftSec"]) <= 0.0:
				expired.append(m)
		elif m["type"] == "demand" and not m.get("join", false):
			m["ageSec"] = float(m.get("ageSec", 0.0)) + dt
			if float(m["ageSec"]) >= _num("patienceSec", 60.0):
				escalate.append(m)
	for m: Dictionary in expired:
		_expire(s, m, out)
	for m: Dictionary in escalate:
		if _can_threaten(s, str(m["partner"])):
			m["state"] = "expired"
			_post(s, {"type": "ultimatum", "partner": m["partner"], "price": m["price"], "kind": m.get("kind", "money"),
				"leftSec": float(_ult().get("sec", 90.0)), "state": "open", "line": "threat", "variant": _variant(s, str(m["partner"]), "threat")}, out)


static func _can_threaten(s: GameState, id: String) -> bool:
	return ultimatums_unlocked(s) and counts(s, id) and can_leave(id) \
		and open_ultimatums(s) < int(_ult().get("maxOpen", 1))


static func _next_join(s: GameState, ctx: Dictionary) -> String:
	for p: Dictionary in partners():
		var id: String = p["id"]
		if status(s, id) != "absent" or p.get("standIn", false) or _excluded(s, p):
			continue
		if Conditions.ok(s, unlock_of(s, p), ctx):
			return id
	return ""


static func _post_join(s: GameState, id: String, d: Economy.Derived, rng: Callable, out: Array) -> void:
	var p := partner(id)
	var st := ps(s, id)
	if p.get("rebel", false):
		# Almog Cohen: "הוסר על ידי מנהל" elsewhere, waiting to be poached (deck §E).
		st["status"] = "removed"
		var price := ceilf(maxf(_num("minPrice", 10.0), _num("poachSec", 60.0) * d.bps))
		_sys(s, "chat.sys.removed", {"partner": id, "payable": "poach", "price": price, "state": "open"}, out)
		return
	st["status"] = "pending"
	_sys(s, "chat.sys.joined", {"partner": id}, out)
	var price := demand_price(s, id, d)
	var variant := _variant(s, id, "demand")
	if int(_c(s)["paidLifetime"]) == 0 and s.evolutions == 0 and id == first_partner():
		price = _num("firstDemandPrice", 60.0)   # pitch §11 Q2: the FTUE demand is a fixed 60 ₪
		variant = 0                              # the deck's first bubble (C1); the rotation goes on from 1
		(_c(s)["rot"] as Dictionary)["%s:demand" % id] = 1 % variant_count(id, "demand")
	_post(s, {"type": "demand", "partner": id, "price": price, "kind": p.get("demandKind", "money"),
		"join": true, "ageSec": 0.0, "state": "open", "line": "demand", "variant": variant}, out)


static func _tick_demands(s: GameState, dt: float, d: Economy.Derived, rng: Callable, out: Array) -> void:
	var c := _c(s)
	var busy := {}
	for m: Dictionary in c["chat"]:
		if m["state"] == "open" and is_payable(m):
			busy[m.get("partner", "")] = true
	var pool: Array = []
	for p: Dictionary in partners():
		if counts(s, p["id"]) and float(p.get("demandWeight", 1.0)) > 0.0 and not busy.has(p["id"]):
			pool.append(p)
	if pool.is_empty():
		return
	if float(c["nextDemandSec"]) < 0.0:
		c["nextDemandSec"] = _gap(s, rng)
	c["nextDemandSec"] = float(c["nextDemandSec"]) - dt
	if float(c["nextDemandSec"]) > 0.0:
		return
	var total := 0.0
	for p: Dictionary in pool:
		total += float(p.get("demandWeight", 1.0))
	var r := float(rng.call()) * total
	var pick: Dictionary = pool[pool.size() - 1]
	for p: Dictionary in pool:
		r -= float(p.get("demandWeight", 1.0))
		if r < 0.0:
			pick = p
			break
	var id: String = pick["id"]
	var price := demand_price(s, id, d)
	var kind: String = pick.get("demandKind", "money")
	# Ben Gvir's rule (partnerThreatMult): nobody out-threatens the threatener. The patience
	# escalation below is not a chance, so an unpaid demand still turns into an ultimatum (spec L6).
	if _can_threaten(s, id) and float(rng.call()) < float(pick.get("threatChance", 0.0)) * Leaders.threat_mult():
		_post(s, {"type": "ultimatum", "partner": id, "price": price, "kind": kind,
			"leftSec": float(_ult().get("sec", 90.0)), "state": "open", "line": "threat", "variant": _variant(s, id, "threat")}, out)
	else:
		_post(s, {"type": "demand", "partner": id, "price": price, "kind": kind, "join": false, "ageSec": 0.0,
			"state": "open", "line": "demand", "variant": _variant(s, id, "demand")}, out)
	c["nextDemandSec"] = _gap(s, rng)


## "Every ~90 s at first, rising with the number of partners" (pitch §9).
static func _gap(s: GameState, rng: Callable) -> float:
	var g: Array = cfg().get("demandGapSec", [60, 120])
	var v := float(g[0]) + (float(g[1]) - float(g[0])) * float(rng.call())
	v *= pow(_num("demandGapPerMember", 1.0), member_count(s))
	if str(s.calendar.get("mode", "")) == "negotiation":
		v *= float(cfg().get("negotiation", {}).get("demandGapMult", 1.0))
	return maxf(v, _num("demandGapMinSec", 0.0))


## Gotliv's transfer window (deck §E): her meter fills while she's a member; at fireAt she moves
## into the target's row with her seats and upkeep, and the target posts a 90 s ultimatum.
static func _tick_transfers(s: GameState, dt: float, d: Economy.Derived, out: Array) -> void:
	var c := _c(s)
	if c["transferDone"]:
		return
	for p: Dictionary in partners():
		var tr: Variant = p.get("transfer")
		if not tr is Dictionary:
			continue
		var id: String = p["id"]
		var st := ps(s, id)
		if st["status"] != "member":
			continue
		var fire := float(tr.get("fireAt", 100.0))
		st["meter"] = minf(fire, float(st["meter"]) + float(tr.get("meterPerSec", 0.0)) * dt)
		var to := str(tr.get("to", ""))
		if float(st["meter"]) < fire or not _can_threaten(s, to) or not open_msg(s, to).is_empty() or not open_msg(s, id).is_empty():
			continue
		st["status"] = "transferred"
		(ps(s, to)["carry"] as Array).append(id)
		c["transferDone"] = true
		_post(s, {"type": "transfer", "partner": id, "to": to}, out)
		_sys(s, "chat.sys.transfer", {"partner": id, "to": to}, out)
		for i: int in _script_lines(p, to, "welcome"):   # the target's welcome lines (copy.transferWindow.script)
			_post(s, {"type": "thanks", "partner": to, "scriptFrom": id, "scriptIdx": i}, out)
		_post(s, {"type": "ultimatum", "partner": to, "price": demand_price(s, to, d), "kind": "money",
			"leftSec": float(_ult().get("sec", 90.0)), "state": "open", "line": "threat", "variant": 0, "transfer": id}, out)
		out.append({"ev": "transfer", "partner": id, "to": to})
		return


## Gotliv's transfer script (partners[].copy.transferWindow.script, deck §E): the indexes of the
## lines spoken by `speaker`. "welcome" = the plain lines said as the window opens (no timing
## option); "onPaid" = the lines marked {onPaid: true}. The countdown lines ({atMark}) are the
## ultimatum chip's job, and "uxSys" rows are the sim's own system line.
static func _script_lines(p: Dictionary, speaker: String, when: String) -> Array:
	var out: Array = []
	var tw: Variant = p.get("copy", {}).get("transferWindow") if p.get("copy") is Dictionary else null
	if not tw is Dictionary:
		return out
	var sc: Array = (tw as Dictionary).get("script", []) if (tw as Dictionary).get("script") is Array else []
	for i in sc.size():
		var row: Variant = sc[i]
		if not row is Array or (row as Array).size() < 2 or str(row[0]) != speaker:
			continue
		var opt: Dictionary = row[3] if (row as Array).size() > 3 and row[3] is Dictionary else {}
		if (when == "onPaid" and opt.get("onPaid", false) == true) or (when == "welcome" and opt.is_empty()):
			out.append(i)
	return out


## An ultimatum ran out: the partner (with anyone in their row) leaves; the "left" line carries
## the rejoin pill at rejoinMult × the missed price (pitch §11 Q4: every timer loss recoverable).
static func _expire(s: GameState, m: Dictionary, out: Array) -> void:
	m["state"] = "expired"
	var id := str(m["partner"])
	_leave(s, id, ceilf(maxf(_num("minPrice", 10.0), _num("rejoinMult", 1.5) * float(m["price"]))), out)


static func _leave(s: GameState, id: String, rejoin_price: float, out: Array) -> void:
	var st := ps(s, id)
	st["status"] = "left"
	st["frozen"] = false
	_c(s)["leftLifetime"] = int(_c(s)["leftLifetime"]) + 1
	var f := {"partner": id, "payable": "rejoin", "price": rejoin_price, "state": "open"}
	var pair := merged_with(s, id)
	if not pair.is_empty():
		f["with"] = pair   # Golan's merged pair walks out together (copy leftTogether); one pill
	_sys(s, "chat.sys.left", f, out)
	out.append({"ev": "partnerLeft", "partner": id})
	_stand_in(s, out)


## The partners merged into `id`'s row (Golan's rule), in merge order.
static func merged_with(s: GameState, id: String) -> Array:
	var out: Array = []
	for cid: Variant in ps(s, id)["carry"]:
		if status(s, str(cid)) == "merged":
			out.append(str(cid))
	return out


## Gantz walks in whenever someone walks out (pitch §7). He stays for the round.
static func _stand_in(s: GameState, out: Array) -> void:
	for p: Dictionary in partners():
		var id: String = p["id"]
		if p.get("standIn", false) and status(s, id) == "absent" and Conditions.ok(s, p.get("unlock", {})):
			ps(s, id)["status"] = "member"
			_sys(s, "chat.sys.added", {"partner": id}, out)
			out.append({"ev": "standIn", "partner": id})
			return


# ---------------------------------------------------------------------------------------------
# Player actions
# ---------------------------------------------------------------------------------------------

## Whether `pay` would succeed now (for the pill's state; a ceremony also needs the ribbon).
static func can_pay(s: GameState, seq: int) -> bool:
	var m := message(s, seq)
	return not m.is_empty() and m["state"] == "open" and is_payable(m) and s.bananas >= float(m.get("price", 0.0))


## Pays an open demand, ultimatum, rejoin or poach line. A ceremony (Regev) needs
## `ceremony_done` (the UI's 3 s ribbon tap). Returns {ok, reason?, price, partner, joined, events}.
static func pay(s: GameState, seq: int, ceremony_done: bool = false) -> Dictionary:
	var m := message(s, seq)
	if m.is_empty() or m["state"] != "open" or not is_payable(m):
		return {"ok": false, "reason": "closed"}
	var id := str(m["partner"])
	var p := partner(id)
	if p.is_empty():
		return {"ok": false, "reason": "unknown"}
	if m.get("kind", "money") == "ceremony" and not ceremony_done:
		return {"ok": false, "reason": "ceremony"}
	var price := float(m.get("price", 0.0))
	if s.bananas < price:
		return {"ok": false, "reason": "funds"}
	s.bananas = maxf(0.0, s.bananas - price)
	var out: Array = []
	var st := ps(s, id)
	var was := str(st["status"])
	var payable := str(m.get("payable", ""))
	m["state"] = "deleted" if m["type"] == "ultimatum" else "paid"   # UX §4.2: a paid ultimatum reads "ההודעה נמחקה"
	if payable == "rejoin":
		st["status"] = "member"
		_c(s)["rejoinsLifetime"] = int(_c(s)["rejoinsLifetime"]) + 1
		_sys(s, "chat.sys.joined", {"partner": id}, out)
		_post(s, {"type": "thanks", "partner": id, "line": "return", "variant": _variant(s, id, "return")}, out)
	elif payable == "poach":
		st["status"] = "member"
		_sys(s, "chat.sys.added", {"partner": id}, out)
	else:
		if was == "pending":
			st["status"] = "member"
		_reply(s, out)
		_post(s, {"type": "thanks", "partner": id, "line": "thanks", "variant": _variant(s, id, "thanks")}, out)
	var c := _c(s)
	c["paidRound"] = int(c["paidRound"]) + 1
	c["paidLifetime"] = int(c["paidLifetime"]) + 1
	if m["type"] == "demand" or m["type"] == "ultimatum":
		Meta.bump(s, "demandsPaid")   # trophy "61 ידיים": demands and ultimatums, not rejoin / poach pills
		var odp := Leaders.on_demand_paid()
		if not odp.is_empty():
			# Deri's coffee: a timed tap buff, refreshed (not stacked) by every paid demand.
			Events.leader_buff(s, odp)
			out.append({"ev": "leaderBuff", "partner": id, "type": str(odp.get("type", "")),
				"mult": float(odp.get("mult", 1.0)), "sec": float(odp.get("durationSec", 0.0))})
	if m.get("transfer", "") != "":
		# the transfer ultimatum paid: the transferred partner's own thanks line (copy.transferWindow.script, onPaid)
		var tid := str(m["transfer"])
		for i: int in _script_lines(partner(tid), tid, "onPaid"):
			_post(s, {"type": "thanks", "partner": tid, "scriptFrom": tid, "scriptIdx": i}, out)
	Meta.count(s, "countPartnerPaid", id)   # "gafniPaid" (trophy "תיקו כמו שהזמנת")
	out.append({"ev": "partnerPaid", "partner": id, "payable": payable})   # the partner's paid ticker (copy.onPaidTicker / poachTicker)
	if p.has("priceGrowth"):
		c["levels"][id] = int(c["levels"].get(id, 0)) + 1
	var sus := float(p.get("onPay", {}).get("suspicion", 0.0))
	if sus > 0.0:
		Investigation.add(s, sus)
	var joined: bool = was != "member" and st["status"] == "member"
	if joined:
		Meta.bump(s, "partnersPaid")   # a payment that brought a partner in (headline h_first_partner)
		_on_joined(s, id, out)
	return {"ok": true, "price": price, "partner": id, "joined": joined, "events": out}


static func _on_joined(s: GameState, id: String, out: Array) -> void:
	var p := partner(id)
	if p.get("mutedLine", false):
		_sys(s, "chat.sys.muted", {"partner": id}, out)
	if p.get("statusLine", false):
		_post(s, {"type": "status", "partner": id, "line": "status", "variant": 0}, out)
	out.append({"ev": "partnerJoined", "partner": id})
	# Won't sit with the newcomer (_excluded): a member leaves now (Abbas when Ben Gvir returns);
	# a smaller partner's open offer (join demand, rejoin pill) closes; a bigger one's stays.
	for q: Dictionary in partners():
		var qid: String = q["id"]
		if qid == id or not wont_sit(p, q):
			continue
		var qs := status(s, qid)
		var om := open_msg(s, qid)
		if qs == "member" or (qs == "pending" and weight(q) <= weight(p)):
			if not om.is_empty():
				om["state"] = "expired"
			ps(s, qid)["status"] = "absent"
			_sys(s, "chat.sys.left", {"partner": qid}, out)
		elif qs == "left" and weight(q) <= weight(p) and not om.is_empty():
			om["state"] = "expired"   # the rejoin pill closes; they ask again once the newcomer is out
			ps(s, qid)["status"] = "absent"


## Liberman's "לא יושב" (leader rule declineDemand, spec §5.1, L5): an open MEMBER demand closes for
## free and the partner stays. Never a join demand, a rejoin / poach pill or an ultimatum; one per
## cooldownSec of visible play. The partner's next demand comes on the normal gap.
static func can_decline(s: GameState, seq: int) -> bool:
	var r := Leaders.decline_rule()
	if r.is_empty() or float(_c(s).get("declineCdSec", 0.0)) > 0.0:
		return false
	var m := message(s, seq)
	# Member demands only: an ultimatum (notUltimatum) and a join demand never qualify.
	if m.is_empty() or m["state"] != "open" or m["type"] != "demand" or m.get("join", false) == true:
		return false
	return str(m.get("payable", "")) == "" and status(s, str(m.get("partner", ""))) == "member"


## Seconds left on the decline pill's cooldown (0 = ready; -1 = the round's leader has no decline).
static func decline_cooldown(s: GameState) -> float:
	if Leaders.decline_rule().is_empty():
		return -1.0
	return float(_c(s).get("declineCdSec", 0.0))


## Declines an open member demand. Returns {ok, reason?, partner, events} (reason: rule | cooldown |
## closed). The sys line is chat.sys.declined {partner} (UX CHAT_SYS_DECLINED).
static func decline(s: GameState, seq: int) -> Dictionary:
	var r := Leaders.decline_rule()
	if r.is_empty():
		return {"ok": false, "reason": "rule"}
	if float(_c(s).get("declineCdSec", 0.0)) > 0.0:
		return {"ok": false, "reason": "cooldown"}
	if not can_decline(s, seq):
		return {"ok": false, "reason": "closed"}
	var m := message(s, seq)
	var id := str(m["partner"])
	m["state"] = "declined"
	_c(s)["declineCdSec"] = float(r.get("cooldownSec", 90.0))
	var out: Array = []
	_sys(s, "chat.sys.declined", {"partner": id}, out)
	Leaders._bump(s, Leaders.current(s), "declines", 1.0)
	return {"ok": true, "partner": id, "events": out}


## Golan's "איחוד" (leader rule mergeMembers, spec §2.1, the rule's _note): two members of
## minMemberSec+ merge into one row. `a` keeps its id (the view names it "a־b"); b's seats, upkeep
## (and abstentions) join a's row, demands come on one stream at the higher price, and a walkout
## takes both (one rejoin pill). Never the stand-in or a partner with an open ultimatum; maxPerRound
## per round, cooldownSec apart. Why it can't: "" when it can, else rule | cooldown | limit | same |
## member | young | standIn | ultimatum.
static func merge_block(s: GameState, a: String, b: String) -> String:
	var r := Leaders.merge_rule()
	if r.is_empty():
		return "rule"
	var c := _c(s)
	if float(c.get("mergeCdSec", 0.0)) > 0.0:
		return "cooldown"
	if int(c.get("mergesRound", 0)) >= int(r.get("maxPerRound", 2)):
		return "limit"
	if a == b:
		return "same"
	for id: String in [a, b]:
		if status(s, id) != "member":
			return "member"
		if float(ps(s, id).get("memberSec", 0.0)) < float(r.get("minMemberSec", 60.0)):
			return "young"
		if partner(id).get("standIn", false) == true:
			return "standIn"
		var om := open_msg(s, id)
		if not om.is_empty() and om["type"] == "ultimatum":
			return "ultimatum"
	return ""


static func can_merge(s: GameState, a: String, b: String) -> bool:
	return merge_block(s, a, b) == ""


## The members `id` could merge with now (the pair prompt "לאחד עם…").
static func merge_candidates(s: GameState, id: String) -> Array:
	var out: Array = []
	for p: Dictionary in partners():
		if can_merge(s, id, str(p["id"])):
			out.append(str(p["id"]))
	return out


## Seconds left on the merge pill's cooldown (0 = ready; -1 = no merge rule this round).
static func merge_cooldown(s: GameState) -> float:
	if Leaders.merge_rule().is_empty():
		return -1.0
	return float(_c(s).get("mergeCdSec", 0.0))


## Merges b into a. Returns {ok, reason?, a, b, events}. b's open demand (never an ultimatum) closes;
## the sys line is chat.sys.merged {a, b} (copy rule.copy.sys).
static func merge(s: GameState, a: String, b: String) -> Dictionary:
	var why := merge_block(s, a, b)
	if why != "":
		return {"ok": false, "reason": why}
	var r := Leaders.merge_rule()
	var c := _c(s)
	var out: Array = []
	var om := open_msg(s, b)
	if not om.is_empty():
		om["state"] = "resolved"
	var sb := ps(s, b)
	sb["status"] = "merged"
	(ps(s, a)["carry"] as Array).append(b)
	for cid: Variant in (sb["carry"] as Array).duplicate():   # anyone already in b's row comes along
		(ps(s, a)["carry"] as Array).append(cid)
	sb["carry"] = []
	c["mergesRound"] = int(c.get("mergesRound", 0)) + 1
	c["mergeCdSec"] = float(r.get("cooldownSec", 120.0))
	_sys(s, "chat.sys.merged", {"a": a, "b": b}, out)
	out.append({"ev": "merged", "a": a, "b": b})
	Leaders._bump(s, Leaders.current(s), "merges", 1.0)
	return {"ok": true, "a": a, "b": b, "events": out}


## The brawl (deck §E): both rows freeze until the player presses "צאו החוצה".
static func can_brawl(s: GameState, a: String, b: String) -> bool:
	return a != b and counts(s, a) and counts(s, b) and open_msg(s, a).is_empty() and open_msg(s, b).is_empty()


static func start_brawl(s: GameState, a: String, b: String) -> Array:
	var out: Array = []
	if not can_brawl(s, a, b):
		return out
	ps(s, a)["frozen"] = true
	ps(s, b)["frozen"] = true
	_sys(s, "chat.sys.brawl", {"a": a, "b": b}, out)
	_post(s, {"type": "brawl", "a": a, "b": b, "state": "open"}, out)
	return out


## "צאו החוצה": they stay in the coalition and take the argument to "המסדרון".
static func resolve_brawl(s: GameState, seq: int) -> Array:
	var out: Array = []
	var m := message(s, seq)
	if m.is_empty() or m["type"] != "brawl" or m["state"] != "open":
		return out
	m["state"] = "resolved"
	for id: String in [str(m["a"]), str(m["b"])]:
		var st := ps(s, id)
		st["frozen"] = false
		st["corridor"] = true
	var c := _c(s)
	c["corridorOpen"] = true
	Meta.bump(s, "brawlsEnded")
	_sys(s, "chat.brawl.after", {"a": m["a"], "b": m["b"], "n": c["corridorMsgs"]}, out)
	return out


## The open brawl message, if any (the controller shows its one button).
static func open_brawl(s: GameState) -> Dictionary:
	for m: Dictionary in _c(s)["chat"]:
		if m["type"] == "brawl" and m["state"] == "open":
			return m
	return {}


## Kaia nips a minister: they miss the vote (don't count) for `sec`.
static func bench(s: GameState, id: String, sec: float) -> void:
	if status(s, id) == "member":
		ps(s, id)["benchSec"] = maxf(float(ps(s, id)["benchSec"]), sec)


## A partner walks out without an ultimatum (Yair's tweet). The rejoin pill is priced like a demand.
static func force_leave(s: GameState, id: String, d: Economy.Derived) -> Array:
	var out: Array = []
	if not counts(s, id) or not can_leave(id):
		return out
	var om := open_msg(s, id)
	if not om.is_empty():
		om["state"] = "expired"
	_leave(s, id, ceilf(_num("rejoinMult", 1.5) * demand_price(s, id, d)), out)
	return out


## The chat was opened: unread clears, and "המסדרון"'s muted counter climbs (deck §E).
static func on_chat_opened(s: GameState, rng: Callable = randf) -> void:
	var c := _c(s)
	c["unread"] = 0
	if c["corridorOpen"]:
		var r: Array = cfg().get("corridorMsgsPerOpen", [1, 9])
		c["corridorMsgs"] = int(c["corridorMsgs"]) + int(r[0]) + int(float(rng.call()) * (int(r[1]) - int(r[0]) + 1))
		Meta.stat_at_least(s, "corridorMessages", float(c["corridorMsgs"]))


## Election: the coalition resets (UX elect.reset), the chat is cleared with the round line.
## Price levels (Goldknopf), the corridor and lifetime counters persist.
static func on_election(s: GameState) -> void:
	var c := _c(s)
	c["partners"] = {}
	c["chat"] = []
	c["paidRound"] = 0
	c["nextDemandSec"] = -1.0
	c["joinCooldownSec"] = 0.0
	c["transferDone"] = false
	c["unread"] = 0
	c["declineCdSec"] = 0.0
	c["mergeCdSec"] = 0.0
	c["mergesRound"] = 0
	if c["opened"] and active():
		_sys(s, "chat.sys.cleared", {"n": s.evolutions + 1}, [])


# ---------------------------------------------------------------------------------------------
# Save (v3) and the content lint
# ---------------------------------------------------------------------------------------------

## Validates an untrusted dictionary into a clean coalition state. Never throws.
static func sanitize(raw: Variant) -> Dictionary:
	var out := fresh_state()
	if not raw is Dictionary:
		return out
	var r: Dictionary = raw
	out["opened"] = r.get("opened") == true
	out["transferDone"] = r.get("transferDone") == true
	out["corridorOpen"] = r.get("corridorOpen") == true
	for k in ["seq", "paidRound", "paidLifetime", "leftLifetime", "rejoinsLifetime", "replyIndex", "corridorMsgs", "unread"]:
		out[k] = int(_n(r.get(k)))
	out["nextDemandSec"] = _n(r.get("nextDemandSec"), -1.0)
	out["joinCooldownSec"] = _n(r.get("joinCooldownSec"))
	out["declineCdSec"] = minf(_n(r.get("declineCdSec")), float(Leaders.decline_rule().get("cooldownSec", 0.0)))
	out["mergeCdSec"] = minf(_n(r.get("mergeCdSec")), float(Leaders.merge_rule().get("cooldownSec", 0.0)))
	out["mergesRound"] = mini(int(_n(r.get("mergesRound"))), int(Leaders.merge_rule().get("maxPerRound", 0)))
	var known := {}
	for p: Dictionary in partners():
		known[p["id"]] = true
	var lv: Variant = r.get("levels")
	if lv is Dictionary:
		for k: Variant in lv:
			if known.has(k):
				out["levels"][k] = int(_n(lv[k]))
	var rot: Variant = r.get("rot")
	if rot is Dictionary:
		for k: Variant in rot:
			var parts := str(k).split(":")
			if parts.size() == 2 and known.has(parts[0]) and LINES.has(parts[1]):
				out["rot"][str(k)] = int(_n(rot[k])) % variant_count(parts[0], parts[1])
	var pr: Variant = r.get("partners")
	if pr is Dictionary:
		for k: Variant in pr:
			if not known.has(k) or not pr[k] is Dictionary:
				continue
			var src: Dictionary = pr[k]
			var st := _fresh_partner()
			st["status"] = src.get("status") if STATUSES.has(src.get("status")) else "absent"
			st["meter"] = _n(src.get("meter"))
			st["frozen"] = src.get("frozen") == true
			st["corridor"] = src.get("corridor") == true
			st["benchSec"] = _n(src.get("benchSec"))
			st["memberSec"] = _n(src.get("memberSec"))
			if src.get("carry") is Array:
				for x: Variant in src["carry"]:
					if x is String and known.has(x) and not (st["carry"] as Array).has(x):
						(st["carry"] as Array).append(x)
			out["partners"][k] = st
	var open_by: Dictionary = {}
	var ch: Variant = r.get("chat")
	if ch is Array:
		for x: Variant in ch:
			if not x is Dictionary:
				continue
			var m: Dictionary = (x as Dictionary).duplicate(true)
			if not TYPES.has(m.get("type")) or not STATES.has(m.get("state", "")) or not (m.get("seq") is float or m.get("seq") is int):
				continue
			var bad := false
			for pid in ["partner", "to", "a", "b", "transfer"]:
				if m.has(pid) and str(m[pid]) != "" and not known.has(str(m[pid])):
					bad = true
			if bad:
				continue
			m["seq"] = int(m["seq"])
			for nk in ["price", "leftSec", "ageSec"]:
				if m.has(nk):
					m[nk] = _n(m[nk])
			for ik in ["n", "variant"]:
				if m.has(ik):
					m[ik] = int(_n(m[ik]))
			if m["state"] == "open" and is_payable(m):
				var pid := str(m.get("partner", ""))
				if open_by.has(pid):
					(open_by[pid] as Dictionary)["state"] = "expired"   # one open message per partner
				open_by[pid] = m
			(out["chat"] as Array).append(m)
			out["seq"] = maxi(int(out["seq"]), int(m["seq"]))
	return out


static func _n(v: Variant, dflt: float = 0.0) -> float:
	if (v is float or v is int) and is_finite(float(v)) and float(v) >= 0.0:
		return float(v)
	return dflt


static func validate(c: Dictionary) -> PackedStringArray:
	var err := PackedStringArray()
	var co: Variant = c.get("coalition")
	var pa: Variant = c.get("partners")
	if co == null and pa == null:
		return err
	if not co is Dictionary or not pa is Array or (pa as Array).is_empty():
		err.append("coalition: needs both `coalition` (object) and `partners` (non-empty list)")
		return err
	var prods := {}
	for p: Dictionary in c.get("producers", []):
		prods[p["id"]] = true
	var ids := {}
	var seat_sum := 0
	for p: Variant in pa:
		if not p is Dictionary or str((p as Dictionary).get("id", "")) == "":
			err.append("partners: every partner needs an id")
			continue
		var id := str(p["id"])
		if ids.has(id):
			err.append("partners: duplicate id %s" % id)
		ids[id] = p
		if not ["m", "f"].has(p.get("g", "m")):
			err.append("partners.%s.g must be m or f" % id)
		if not ["money", "ceremony"].has(p.get("demandKind", "money")):
			err.append("partners.%s.demandKind must be money or ceremony" % id)
		for k in Conditions.unknown_keys(p.get("unlock", {})):
			err.append("partners.%s.unlock: unknown condition %s" % [id, k])
		for e: Variant in p.get("effects", []):
			if not e is Dictionary or not Economy.EFFECTS.has((e as Dictionary).get("type", "")):
				err.append("partners.%s.effects: unknown effect %s" % [id, str(e)])
			elif (e as Dictionary).has("producer") and not prods.has(e["producer"]):
				err.append("partners.%s.effects: unknown producer %s" % [id, e["producer"]])
		for lk: Variant in p.get("lines", {}):
			if not LINES.has(lk):
				err.append("partners.%s.lines: unknown line %s" % [id, lk])
		if not p.get("standIn", false) and p.get("side", "coalition") == "coalition":
			seat_sum += int(p.get("seats", 0))
	for id: String in ids:
		var p: Dictionary = ids[id]
		var tr: Variant = p.get("transfer")
		if tr is Dictionary and not ids.has(str(tr.get("to", ""))):
			err.append("partners.%s.transfer.to: unknown partner %s" % [id, tr.get("to", "")])
		for x: Variant in p.get("excludes", []):
			if not ids.has(str(x)):
				err.append("partners.%s.excludes: unknown partner %s" % [id, x])
	if not ids.has(str(co.get("firstPartner", ""))):
		err.append("coalition.firstPartner: unknown partner %s" % co.get("firstPartner", ""))
	var own_max := int(co.get("ownSeats", {}).get("max", 0))
	if own_max + seat_sum < int(co.get("gateSeats", 61)):
		err.append("coalition: own seats max %d + coalition partners %d can never reach %d" % [own_max, seat_sum, int(co.get("gateSeats", 61))])
	if own_max >= int(co.get("gateSeats", 61)):
		err.append("coalition: own seats alone reach %d; a round would never need partners" % int(co.get("gateSeats", 61)))
	return err
