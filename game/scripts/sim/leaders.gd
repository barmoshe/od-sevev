class_name Leaders
extends RefCounted
## Leader select (design/leader-select-spec.md; content `leaderSelect` + `leaders[]`). Pure rules,
## no nodes. Every round the player heads one party: the leader is fixed for the round and re-picked
## after every election. Every number stays shared (spec D5); a leader changes the coalition lineup
## (who holds the shared slots), the rival cards, the words, and one signature rule.
##
## The round's install (Politics.install(state, leader) → start_round) builds three things from the
## content, and the other modules read them through this file:
##   partners()  the lineup dealt onto `coalitionSlots` (Coalition reads it instead of content.partners)
##   events()    the round's cards: shared events, this leader's rivals, their own selfEvent
##   first_partner()  the leader's FTUE C1 partner (slot S1)
## The default leader (Bibi) installs the shipped `partners` / `events` lists untouched (the content
## lint proves his lineup equals content.partners), so his round is the shipped game bit for bit.
## Content without `leaders` (the fork's content, the test fixtures) is always that default round.
##
## State (save v4, GameState): leader, leader_pick_pending, leader_history, leaders (stats per
## leader), seat_deal, leader_round {prev, fresh, switched, freshPct, lastPlayed, salt}.
##
## Round flow. An election (on_election) closes the round for the leader who played it and begins
## the next one with the SAME leader, and sets leader_pick_pending: the picker may replace him
## (start_round) until the first tap. A build without the picker therefore keeps running as that
## leader (Bibi) forever. A repick undoes the automatic round's bookkeeping, so it counts once.

const STAT_KEYS := ["rounds", "elections", "taps", "crits", "declines", "merges", "bestRunSec", "playSec"]
const HISTORY_MAX := 10
## The per-slot numbers a lineup deals; every other partner field is the person's trait.
const SLOT_NUMBERS := ["seats", "upkeepPct", "demandWeight", "threatChance", "unlock"]
const SLOT_ORDER := ["S1", "S2", "S3", "S4", "S5", "SK", "L1", "L2", "L3", "L4", "L5", "L6", "L7", "L8", "SI"]
## Slots that never move in the deal: S1 (the FTUE C1 partner) and SI (the stand-in role).
const FIXED_SLOTS := ["S1", "SI"]
## Signature-rule effect types the sim knows (besides any Economy.EFFECTS type, applied as a
## passive modifier while the leader plays).
##   selfEvent          Bennett: his own shipped card at weight × and from firstAfterPlaySec (Events)
##   partnerThreatMult  Ben Gvir: partners' threatChance × mult (Coalition)
##   declineDemand      Liberman: Coalition.decline, one per cooldownSec, member demands only
##   straightTaps       Eisenkot: no crits; taps × (1 + c × (critMult − 1)), a noCrit card suspends it (Economy)
##   mergeMembers       Golan: Coalition.merge (seats and upkeep summed, one demand stream, leave together)
##   leaderEffects      Smotrich, Deri: `effects` (Economy effects), `demandDiscountPct` (adds to the
##                      p_deal perk), `coalition` (a coalition config override: rejoinMult), `onDemandPaid`
##                      (a tapBuff refreshed on every paid demand)
const RULE_TYPES := ["selfEvent", "partnerThreatMult", "declineDemand", "straightTaps", "mergeMembers", "leaderEffects"]
const OVERRIDABLE := ["rejoinMult", "poachSec", "patienceSec", "demandSec", "minPrice"]

# ---- the installed round (a cache of the state's leader + deal over the loaded content) ----
static var _c: Dictionary = {}          # the content object it was built from (is_same)
static var _key := ""           # no built key is "" (each holds "|"); a NUL sentinel printed "Unicode parsing error"
static var _state_id := 0
static var _state_ver := -1
static var _leader := ""
static var _partners: Array = []
static var _events: Array = []
static var _first := ""
static var _installed := false
static var _dflt := true           # the installed round is the default leader's (the shipped lists)
static var _eff: Dictionary = {}    # the installed leader's rule.effect ({} for the default)
static var _co: Dictionary = {}     # its coalition config override (leaderEffects.coalition)


static func install() -> void:
	if _installed:
		return
	_installed = true
	Economy.MODIFIERS.append(_apply_modifiers)


# ---------------------------------------------------------------------------------------------
# Content
# ---------------------------------------------------------------------------------------------

static func ls() -> Dictionary:
	var v: Variant = Content.data().get("leaderSelect")
	return v if v is Dictionary else {}


static func list() -> Array:
	var v: Variant = Content.data().get("leaders")
	return v if v is Array else []


## The content has leader select (both blocks). Without it everything here is the default round.
static func active() -> bool:
	return not ls().is_empty() and not list().is_empty()


static func default_leader() -> String:
	return str(ls().get("defaultLeader", "bibi")) if active() else ""


static func leader(id: String) -> Dictionary:
	for L: Variant in list():
		if L is Dictionary and str((L as Dictionary).get("id", "")) == id:
			return L
	return {}


## A leader the player can pick: in the roster and contentReady (spec §3.2 shipRule; the content
## lint's completeness check gates contentReady), with a coalition lineup (the default: his kit).
static func playable(id: String) -> bool:
	if not active() or id == "":
		return false
	var L := leader(id)
	if L.is_empty() or not (ls().get("roster", []) as Array).has(id) or not (ls().get("contentReady", []) as Array).has(id):
		return false
	return id == default_leader() or (L.get("coalition") is Dictionary and L.get("kit") is Dictionary)


## Picker order is the roster's (the view shuffles on every open, spec D10: picker(s, rng)).
static func pickable() -> PackedStringArray:
	var out := PackedStringArray()
	for id: Variant in ls().get("roster", []):
		if playable(str(id)):
			out.append(str(id))
	return out


static func kit(id: String) -> Dictionary:
	var k: Variant = leader(id).get("kit")
	return k if k is Dictionary else {}


static func rule(id: String) -> Dictionary:
	var r: Variant = leader(id).get("rule")
	return r if r is Dictionary else {}


static func rule_effect(id: String) -> Dictionary:
	var e: Variant = rule(id).get("effect")
	return e if e is Dictionary else {}


static func is_default(id: String) -> bool:
	return not active() or id == "" or id == default_leader()


## All cast profiles by id: the shipped partners plus leaderSelect.partnerProfiles.
static func profile(id: String) -> Dictionary:
	for p: Variant in Content.data().get("partners", []):
		if p is Dictionary and str((p as Dictionary).get("id", "")) == id:
			return p
	for p: Variant in ls().get("partnerProfiles", []):
		if p is Dictionary and str((p as Dictionary).get("id", "")) == id:
			return p
	return {}


static func card_profile(id: String) -> Dictionary:
	for e: Variant in ls().get("cardProfiles", []):
		if e is Dictionary and str((e as Dictionary).get("id", "")) == id:
			return e
	return {}


static func _content_event(id: String) -> Dictionary:
	for e: Variant in Content.data().get("events", []):
		if e is Dictionary and str((e as Dictionary).get("id", "")) == id:
			return e
	return {}


static func bibi_only(key: String) -> Array:
	var v: Variant = ls().get("bibiOnly", {}).get(key, []) if ls().get("bibiOnly") is Dictionary else []
	return v if v is Array else []


# ---------------------------------------------------------------------------------------------
# The installed round (what Coalition / Events / Spins / Economy read)
# ---------------------------------------------------------------------------------------------

## The installed leader ("" on content without leader select).
static func installed() -> String:
	_refresh_content()
	return _leader


static func installed_default() -> bool:
	_refresh_content()
	return _dflt


## Coalition's partner list for the round.
static func partners() -> Array:
	_refresh_content()
	var p: Variant = Content.data().get("partners")
	if _dflt or _partners.is_empty():
		return p if p is Array else []
	return _partners


## Events' list for the round.
static func events() -> Array:
	_refresh_content()
	var v: Variant = Content.data().get("events")
	if _dflt:
		return v if v is Array else []
	return _events


static func first_partner() -> String:
	_refresh_content()
	if _dflt or _first == "":
		return str(Content.data().get("coalition", {}).get("firstPartner", "")) if Content.data().get("coalition") is Dictionary else ""
	return _first


## A content swap (tests, Content.replace) drops the cache back to the default round until the
## next ensure(state).
static func _refresh_content() -> void:
	if not is_same(_c, Content.data()):
		_c = Content.data()
		_key = ""
		_state_id = 0
		_state_ver = -1
		_leader = default_leader()
		_dflt = true
		_partners = []
		_events = []
		_first = ""
		_eff = {}
		_co = {}


## Makes the installed round match the state (Economy.derive and Politics.tick call this, so any
## state the engine or the bench plays installs itself). Cheap when nothing changed.
static func ensure(s: GameState) -> void:
	_refresh_content()
	if s == null:
		return
	if s.get_instance_id() == _state_id and s.leader_ver == _state_ver:
		return
	_state_id = s.get_instance_id()
	_state_ver = s.leader_ver
	var id := s.leader if playable(s.leader) else default_leader()
	var key := id + "|" + JSON.stringify(s.seat_deal, "", true)
	if key == _key:
		return
	_key = key
	_leader = id
	_dflt = is_default(id)
	_partners = [] if is_default(id) else build_roster(id, s.seat_deal)
	_events = [] if is_default(id) else build_events(id)
	var co: Variant = leader(id).get("coalition")
	_first = str((co as Dictionary).get("firstPartner", "")) if co is Dictionary else ""
	_eff = {} if is_default(id) else rule_effect(id)
	var ov: Variant = _eff.get("coalition") if str(_eff.get("type", "")) == "leaderEffects" else null
	_co = {}
	if ov is Dictionary:
		for k: Variant in ov:
			if OVERRIDABLE.has(str(k)) and (ov[k] is float or ov[k] is int):
				_co[str(k)] = float(ov[k])


# ---------------------------------------------------------------------------------------------
# Building a round: the lineup dealt onto the slots, and the round's cards
# ---------------------------------------------------------------------------------------------

static func _lineup(id: String) -> Array:
	var co: Variant = leader(id).get("coalition")
	var l: Variant = (co as Dictionary).get("lineup", []) if co is Dictionary else []
	return l if l is Array else []


static func slots() -> Dictionary:
	var v: Variant = ls().get("coalitionSlots")
	return v if v is Dictionary else {}


static func shuffles(id: String) -> bool:
	if is_default(id):
		return false
	var co: Variant = leader(id).get("coalition")
	var dflt: bool = ls().get("lineupRules", {}).get("shuffleSeatsExceptFirst", true) == true if ls().get("lineupRules") is Dictionary else true
	return (co as Dictionary).get("shuffleSeats", dflt) == true if co is Dictionary else false


## This round's slot deal {partnerId: slot} (spec §5.5, L4). S1 and SI stay put; the other members'
## slots are permuted by a seed (the round, the leader, the save's salt), so a reload never rerolls
## (the deal is saved) and an undo keeps the same seed. The default leader deals nothing: {}.
static func deal(id: String, seed_: int) -> Dictionary:
	var out := {}
	if is_default(id):
		return out
	var movers: Array = []
	var slots_: Array = []
	for m: Variant in _lineup(id):
		if not m is Dictionary:
			continue
		var sl := str((m as Dictionary).get("slot", ""))
		out[str(m["id"])] = sl
		if shuffles(id) and not FIXED_SLOTS.has(sl):
			movers.append(str(m["id"]))
			slots_.append(sl)
	if movers.size() > 1:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_
		for i in range(slots_.size() - 1, 0, -1):
			var j := rng.randi_range(0, i)
			var t: Variant = slots_[i]
			slots_[i] = slots_[j]
			slots_[j] = t
		for i in movers.size():
			out[movers[i]] = slots_[i]
	return out


static func deal_seed(s: GameState, id: String) -> int:
	return hash("%s:%d:%d" % [id, s.evolutions, int(s.leader_round.get("salt", 0))])


## The partner list of a round: each lineup member is the person's profile (their traits and
## voice), then the dealt slot's numbers, then the lineup's overrides (spec §5.5). A person whose
## trait is `abstain` (Gafni) turns the slot's seats into abstentions; `cannotLeave` (Deri, Lapid in
## Bennett's round) never threatens. A transfer to someone outside the lineup is dropped. The list
## is in slot order (S1 … L8, SI), which is the order partners are offered to join.
static func build_roster(id: String, deal_: Dictionary = {}) -> Array:
	var sl := slots()
	var members: Dictionary = {}
	for m: Variant in _lineup(id):
		if m is Dictionary:
			members[str(m["id"])] = true
	var out: Array = []
	for m: Variant in _lineup(id):
		if not m is Dictionary:
			continue
		var mid := str(m["id"])
		var base := profile(mid)
		if base.is_empty():
			continue
		var slot_id := str(deal_.get(mid, m.get("slot", "")))
		if not sl.get(slot_id) is Dictionary:
			slot_id = str(m.get("slot", ""))
		var slot: Dictionary = sl.get(slot_id, {}) if sl.get(slot_id) is Dictionary else {}
		var p: Dictionary = base.duplicate(true)
		for k: String in SLOT_NUMBERS:
			if slot.has(k):
				p[k] = (slot[k] as Dictionary).duplicate(true) if slot[k] is Dictionary else slot[k]
		if base.has("abstain"):
			p["abstain"] = int(slot.get("seats", 0))
			p["seats"] = 0
		var tr: Variant = m.get("traits")
		if tr is Dictionary:
			for k: Variant in tr:
				if tr[k] == null:
					p.erase(k)
				else:
					p[k] = (tr[k] as Dictionary).duplicate(true) if tr[k] is Dictionary else tr[k]
		if p.get("cannotLeave", false) == true:
			p["threatChance"] = 0
		var ln: Variant = m.get("lines")
		if ln is Dictionary:
			var lines: Dictionary = (p.get("lines", {}) as Dictionary).duplicate() if p.get("lines") is Dictionary else {}
			var lv: Dictionary = (p.get("linesVariants", {}) as Dictionary).duplicate() if p.get("linesVariants") is Dictionary else {}
			for k: Variant in ln:
				lines[k] = ln[k]
				lv.erase(k)   # the override is the line: its variants no longer apply
			p["lines"] = lines
			p["linesVariants"] = lv
		var t: Variant = p.get("transfer")
		if t is Dictionary and not members.has(str((t as Dictionary).get("to", ""))):
			p.erase("transfer")
		p["id"] = mid
		p["slot"] = slot_id
		out.append(p)
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return _slot_rank(str(a["slot"])) < _slot_rank(str(b["slot"])))
	return out


static func _slot_rank(slot: String) -> int:
	var i := SLOT_ORDER.find(slot)
	return i if i >= 0 else SLOT_ORDER.size()


## The rival cards of a leader's round as person ids (a card profile's `person`, a shipped event's
## own id): the rival ticker and the Story filter read them.
static func rival_people(id: String) -> PackedStringArray:
	var out := PackedStringArray()
	var co: Variant = leader(id).get("coalition")
	for r: Variant in ((co as Dictionary).get("rivals", []) if co is Dictionary else []):
		var cp := card_profile(str(r))
		out.append(str(cp.get("person", r)) if not cp.is_empty() else str(r))
	return out


## The cards of a round (spec §5.5, §8, §9.6): the shared events minus Bibi's own
## (bibiOnly.events) and minus every opposition card that isn't this round's rival; the rivals
## from `coalition.rivals` (a shipped event id or a leaderSelect.cardProfiles id, side "rival");
## the leak re-skinned to the coalition's screenshot (leakRight) when the player is the
## opposition; and the leader's own selfEvent card (side "self": Bennett's pledge).
static func build_events(id: String) -> Array:
	var L := leader(id)
	var co: Variant = L.get("coalition")
	var rivals: Array = (co as Dictionary).get("rivals", []) if co is Dictionary else []
	var drop := bibi_only("events")
	var eff := rule_effect(id)
	var self_id := str(eff.get("event", "")) if str(eff.get("type", "")) == "selfEvent" else ""
	var opposition := str(L.get("side", "")) == "opposition"
	var out: Array = []
	for e: Variant in Content.data().get("events", []):
		if not e is Dictionary:
			continue
		var eid := str(e.get("id", ""))
		if drop.has(eid) or eid == self_id:
			continue
		if str(e.get("side", "")) == "opposition" and str(e.get("kind", "card")) == "card" and not rivals.has(eid):
			continue   # an opposition card that isn't this round's rival (the leak is a shared chat event)
		var x: Dictionary = (e as Dictionary).duplicate(true)
		if str(x.get("effect", {}).get("type", "")) == "leak" and opposition and ls().get("leakRight") is Dictionary:
			x["effect"]["leaks"] = maxi(1, (ls()["leakRight"].get("leaks", []) as Array).size())
			x["skin"] = "leakRight"   # the view reads leaderSelect.leakRight (leak_copy)
		out.append(x)
	for r: Variant in rivals:
		var cp := card_profile(str(r))
		if not cp.is_empty():
			var x: Dictionary = cp.duplicate(true)
			x["side"] = "rival"
			out.append(x)
	if self_id != "":
		var se := _content_event(self_id)
		if not se.is_empty():
			var x: Dictionary = se.duplicate(true)
			x["side"] = "self"
			x["weight"] = float(se.get("weight", 1.0)) * float(eff.get("weightMult", 1.0))
			# His own card: from firstAfterPlaySec of round time, and never once the gate is met
			# (spec L7: it only raises a gate that isn't already closed).
			var gate := int(Content.data().get("coalition", {}).get("gateSeats", 61)) if Content.data().get("coalition") is Dictionary else 61
			x["when"] = {"runSecAtLeast": float(eff.get("firstAfterPlaySec", 0.0)), "seatsBelow": gate}
			x.erase("oncePerRound")
			out.append(x)
	return out


# ---------------------------------------------------------------------------------------------
# The pick (the engine's API)
# ---------------------------------------------------------------------------------------------

## The round's leader (the default on content without leader select).
static func current(s: GameState) -> String:
	if s.get_instance_id() == _state_id and s.leader_ver == _state_ver and is_same(_c, Content.data()):
		return _leader   # installed and validated by ensure()
	return s.leader if playable(s.leader) else default_leader()


## The picker is open now: after an election, or on a new game, until the round starts.
static func pick_pending(s: GameState) -> bool:
	return active() and s.leader_pick_pending and can_repick(s)


## A pick (or the 5 s undo) may still replace this round's leader: nothing has happened in the
## round yet (no tap, the group chat not opened).
static func can_repick(s: GameState) -> bool:
	return active() and s.run_taps == 0 and not _partners_touched(s.coalition)


## A partner has joined or been offered this round (the round's lineup is in use). After an
## election the coalition's partners reset (the group stays opened), so this is empty again.
static func _partners_touched(co: Variant) -> bool:
	var ps: Variant = (co as Dictionary).get("partners", {}) if co is Dictionary else {}
	if not ps is Dictionary:
		return false
	for id: Variant in ps:
		if ps[id] is Dictionary and str((ps[id] as Dictionary).get("status", "absent")) != "absent":
			return true
	return false


## Everything the picker screen needs (spec §3.2): the tiles in a fresh shuffle (D10), the "again"
## leader (the last round's; "" on a new game), the title key and the copy. No numbers (L9).
static func picker(s: GameState, rng: Callable = randf) -> Dictionary:
	var ids := Array(pickable())
	for i in range(ids.size() - 1, 0, -1):
		var j := int(float(rng.call()) * (i + 1)) % (i + 1)
		var t: Variant = ids[i]
		ids[i] = ids[j]
		ids[j] = t
	var tiles: Array = []
	for id: Variant in ids:
		tiles.append(tile(str(id)))
	var again := str(s.leader_round.get("prev", ""))
	if s.evolutions > 0 and again == "":
		again = current(s)
	var pk: Dictionary = ls().get("pick", {}) if ls().get("pick") is Dictionary else {}
	return {"tiles": tiles, "again": again if playable(again) else "", "first": s.evolutions == 0,
		"random": pk.get("randomTile", true) == true, "undoSec": float(pk.get("undoSec", 5.0)), "copy": pick_copy()}


static func tile(id: String) -> Dictionary:
	var L := leader(id)
	var pk: Dictionary = L.get("pick", {}) if L.get("pick") is Dictionary else {}
	return {"id": id, "name": L.get("name", ""), "short": L.get("short", ""), "party": L.get("party", ""),
		"g": L.get("g", "m"), "side": L.get("side", ""), "art": L.get("art", id), "avatar": L.get("avatar", ""),
		"blurb": pk.get("blurb", ""), "line": pk.get("line", ""), "ruleName": rule(id).get("name", ""), "ruleText": rule(id).get("text", "")}


static func pick_copy() -> Dictionary:
	var p: Variant = ls().get("pick", {})
	var c: Variant = (p as Dictionary).get("copy", {}) if p is Dictionary else {}
	return c if c is Dictionary else {}


## "הפתעה": a uniform pick among the tiles.
static func random_pick(rng: Callable = randf) -> String:
	var ids := pickable()
	return ids[int(float(rng.call()) * ids.size()) % ids.size()] if not ids.is_empty() else default_leader()


## Starts this round as `id` (the picker's tile, "again", or the 5 s undo). Legal while the round
## hasn't started (can_repick); a repick first undoes the round's automatic bookkeeping, so the
## stats, the history and the fresh-face bonus count once. Returns {ok, leader, fresh, freshPct,
## switched, repick} or {ok: false, reason: unknown | started | inactive}.
static func start_round(s: GameState, id: String) -> Dictionary:
	if not active():
		return {"ok": false, "reason": "inactive"}
	if not playable(id):
		return {"ok": false, "reason": "unknown"}
	if not can_repick(s):
		return {"ok": false, "reason": "started"}
	var r := s.leader_round
	var cur := current(s)
	var undo: Variant = r.get("undo") if r.get("picked", false) == true else {"leader": cur, "pending": s.leader_pick_pending}
	if s.leader_history.size() > 0 and bool(r.get("begun", false)):
		# undo the round that began automatically (after an election, a new game) or the last pick
		_bump(s, cur, "rounds", -1.0)
		if (stats(s, cur).values() as Array).all(func(v: Variant) -> bool: return float(v) == 0.0):
			s.leaders.erase(cur)   # a leader never really played leaves no row (the dossier's list)
		if r.get("switched", false) == true:
			Meta.bump(s, "leaderSwitches", -1.0)
		s.leader_history.remove_at(s.leader_history.size() - 1)
	var res := _begin(s, id, str(r.get("prev", "")))
	s.leader_pick_pending = false
	s.leader_round["picked"] = true
	s.leader_round["undo"] = undo   # the pre-pick state undo_pick() restores
	res["repick"] = cur != id
	res["ok"] = true
	return res


## The "להחליף" chip (UX §8; spec §3.1, L4): back to the exact pre-pick state, before the round
## starts. The pre-pick leader's round again (same seed, so the same deal), the +10% and the switch
## reverted, and the picker open as it was. {ok, leader} or {ok: false, reason: started | none}.
static func undo_pick(s: GameState) -> Dictionary:
	var r := s.leader_round
	if not can_repick(s):
		return {"ok": false, "reason": "started"}
	var u: Variant = r.get("undo")
	if r.get("picked", false) != true or not u is Dictionary or not playable(str((u as Dictionary).get("leader", ""))):
		return {"ok": false, "reason": "none"}
	start_round(s, str(u["leader"]))
	s.leader_round["picked"] = false
	s.leader_round.erase("undo")
	s.leader_pick_pending = u.get("pending", true) == true
	return {"ok": true, "leader": s.leader}


## Economy.evolve → Politics.on_election, after the run reset: the finished round is booked to its
## leader (Meta.on_round_end did elections/bestRunSec), the next round begins with the same leader,
## and the picker opens (leader_pick_pending) to replace him.
static func on_election(s: GameState) -> void:
	if not active():
		return
	var last := current(s)
	s.leader_round["lastPlayed"] = last
	_begin(s, last, last)
	s.leader_pick_pending = true


## The round's stats at the election (Meta.on_round_end, before the run resets).
static func on_round_end(s: GameState, run_sec: float) -> void:
	if not active():
		return
	var id := current(s)
	_bump(s, id, "elections", 1.0)
	var st := stats(s, id)
	if float(st["bestRunSec"]) <= 0.0 or run_sec < float(st["bestRunSec"]):
		st["bestRunSec"] = run_sec


static func _begin(s: GameState, id: String, prev: String) -> Dictionary:
	var switched := prev != "" and prev != id
	var pct := float(ls().get("pick", {}).get("freshFaceBasePct", 0.0)) if switched and ls().get("pick") is Dictionary else 0.0
	s.leader = id
	s.leader_history.append(id)
	while s.leader_history.size() > HISTORY_MAX:
		s.leader_history.remove_at(0)
	_bump(s, id, "rounds", 1.0)
	if switched:
		Meta.bump(s, "leaderSwitches")
	s.leader_round["prev"] = prev
	s.leader_round["switched"] = switched
	s.leader_round["fresh"] = pct > 0.0
	s.leader_round["freshPct"] = pct
	s.leader_round["begun"] = true
	s.leader_round["picked"] = false   # start_round marks a pick
	s.leader_round.erase("undo")
	s.seat_deal = deal(id, deal_seed(s, id))
	s.leader_ver += 1
	ensure(s)
	return {"leader": id, "fresh": pct > 0.0, "freshPct": pct, "switched": switched}


## The save's deal salt (the engine sets a random one on a new game; the bench sets its seed), so
## two players' round-3 Bennett deals differ. The current round's deal is not re-dealt.
static func set_salt(s: GameState, salt: int) -> void:
	s.leader_round["salt"] = salt


# ---------------------------------------------------------------------------------------------
# Stats (spec §6.2)
# ---------------------------------------------------------------------------------------------

static func fresh_stats() -> Dictionary:
	var d := {}
	for k: String in STAT_KEYS:
		d[k] = 0.0
	return d


static func stats(s: GameState, id: String) -> Dictionary:
	if not s.leaders.has(id):
		s.leaders[id] = fresh_stats()
	return s.leaders[id]


static func stat(s: GameState, id: String, key: String) -> float:
	var st: Variant = s.leaders.get(id)
	return float((st as Dictionary).get(key, 0.0)) if st is Dictionary else 0.0


static func _bump(s: GameState, id: String, key: String, n: float) -> void:
	if id == "":
		return
	var st := stats(s, id)
	st[key] = maxf(0.0, float(st.get(key, 0.0)) + n)


## Economy.tap: the round's leader's taps and crits; the first tap closes the picker.
static func on_tap(s: GameState, crit: bool) -> void:
	if not active():
		return
	s.leader_pick_pending = false
	var st := stats(s, current(s))
	st["taps"] = float(st["taps"]) + 1.0
	if crit:
		st["crits"] = float(st["crits"]) + 1.0


static func on_play(s: GameState, dt: float) -> void:
	if not active():
		return
	var st := stats(s, current(s))
	st["playSec"] = float(st["playSec"]) + dt


## Trophy "כולם היו ראש ממשלה": every pickable leader has called an election.
static func all_played(s: GameState) -> bool:
	var ids := pickable()
	if ids.is_empty():
		return false
	for id in ids:
		if stat(s, id, "elections") < 1.0:
			return false
	return true


# ---------------------------------------------------------------------------------------------
# Rules and filters
# ---------------------------------------------------------------------------------------------

## The installed round's rule effect type ("" for the default leader).
static func rule_type() -> String:
	_refresh_content()
	return str(_eff.get("type", ""))


static func _eff_of(type: String) -> Dictionary:
	_refresh_content()
	return _eff if str(_eff.get("type", "")) == type else {}


## Ben Gvir: partners' threatChance × mult while he plays (1 otherwise).
static func threat_mult() -> float:
	return float(_eff_of("partnerThreatMult").get("mult", 1.0))


## Liberman: the decline rule's effect ({} when the round's leader has none).
static func decline_rule() -> Dictionary:
	return _eff_of("declineDemand")


## Golan: the merge rule's effect ({} otherwise).
static func merge_rule() -> Dictionary:
	return _eff_of("mergeMembers")


## Eisenkot: no crits, taps paid the crits' expected value (Economy.derive / Economy.tap).
static func straight() -> bool:
	return not _eff_of("straightTaps").is_empty()


## The round's override of a coalition config number (Deri: rejoinMult 1.0), or null.
static func coalition_override(key: String) -> Variant:
	_refresh_content()
	return _co.get(key)


## Smotrich: % off every demand while he plays; it adds to the p_deal perk's.
static func demand_discount_pct() -> float:
	return float(_eff_of("leaderEffects").get("demandDiscountPct", 0.0))


## Deri: the spin effect a paid demand fires ({} otherwise): {type: tapBuff, mult, durationSec}.
static func on_demand_paid() -> Dictionary:
	var v: Variant = _eff_of("leaderEffects").get("onDemandPaid")
	return v if v is Dictionary else {}


## Fresh face (+freshFaceBasePct on this round's base, any leader) and the leader rule's plain
## Economy effects: a rule whose effect is an Economy type, or leaderEffects.effects (Smotrich's
## VAT producerMult 1.18 from t 0).
static func _apply_modifiers(s: GameState, d: Economy.Derived) -> void:
	_refresh_content()
	d.base_pct_round += float(s.leader_round.get("freshPct", 0.0))
	if _eff.is_empty():
		return
	var effs: Array = [_eff]
	if str(_eff.get("type", "")) == "leaderEffects" and _eff.get("effects") is Array:
		effs = _eff["effects"]
	for e: Variant in effs:
		if e is Dictionary:
			var h: Variant = Economy.EFFECTS.get(str((e as Dictionary).get("type", "")))
			if h != null:
				(h as Callable).call(e, d)


## Spins (spec §5.4): Bibi's own spins leave the shelf outside his round; a partner-scoped spin
## (s08, Karhi's line) needs its condition (Karhi a member). The default round is untouched.
static func upgrade_allowed(s: GameState, id: String) -> bool:
	if installed_default():
		return true
	if bibi_only("upgrades").has(id):
		return false
	var ps: Variant = ls().get("bibiOnly", {}).get("upgradesPartnerScoped", {}) if ls().get("bibiOnly") is Dictionary else {}
	if ps is Dictionary and (ps as Dictionary).has(id):
		return Conditions.ok(s, ps[id])
	return true


## A skinned spin drops the fields `spinSlots.dropFromSkin` names (slot G: s13's next-morning
## invoice is Bibi's).
static func upgrade_follow_up_allowed(id: String) -> bool:
	if installed_default():
		return true
	var ss: Variant = ls().get("spinSlots", {})
	if not ss is Dictionary:
		return true
	var drop: Variant = (ss as Dictionary).get("dropFromSkin", {})
	if not drop is Dictionary:
		return true
	for slot: Variant in drop:
		if str(slot).begins_with("_"):
			continue
		if str((ss as Dictionary).get(slot, "")) == id and (drop[slot] as Array).has("followUp"):
			return false
	return true


## The Suitcase outside Bibi's round: bibiOnly.goldenOutcomes are dropped and cash takes their
## weight (content leaderSelect.suitcase._rule; the weights still sum as before, so the money /
## frenzy split is the shared one). `outs` is the already era-filtered pool.
static func filter_outcomes(outs: Array) -> Array:
	if installed_default():
		return outs
	var drop := bibi_only("goldenOutcomes")
	var freed := 0.0
	var out: Array = []
	for o: Dictionary in outs:
		if drop.has(str(o["id"])):
			freed += float(o.get("weight", 0.0))
		else:
			out.append(o)
	if freed > 0.0:
		for i in out.size():
			if str(out[i]["id"]) == "cash":
				var c: Dictionary = (out[i] as Dictionary).duplicate()
				c["weight"] = float(c.get("weight", 0.0)) + freed
				out[i] = c
				break
	return out


## The court (Bibi) vs the press (everyone else): the aide drop and the pardon desk are his.
static func has_court() -> bool:
	var id := installed()
	return is_default(id) or str(hazard(id).get("skin", "")) == "court"


## Trophies in bibiOnly.trophies are earned only in his round.
static func trophy_allowed(s: GameState, id: String) -> bool:
	return is_default(current(s)) or not bibi_only("trophies").has(id)


## The per-leader and global trophies (leaderSelect.trophies + every pickable leader's kit.trophy).
static func trophies() -> Array:
	var out: Array = []
	if not active():
		return out
	for t: Variant in ls().get("trophies", []):
		if t is Dictionary:
			out.append(t)
	for id in pickable():
		var t: Variant = kit(id).get("trophy")
		if t is Dictionary and (t as Dictionary).has("id"):
			out.append(t)
	return out


# ---------------------------------------------------------------------------------------------
# Kit lookups for the views (no Hebrew is authored here; these return the content's)
# ---------------------------------------------------------------------------------------------

## The tap kit: {prop, anim, critAnim, critEvent, critProp, verb, verbPlural, critName, critPlural,
## frenzyBanner}. Bibi: prop_hat, anim "tap", critAnim "crit", critProp prop_rabbit.
static func tap_kit(id: String) -> Dictionary:
	var t: Variant = kit(id).get("tap")
	return t if t is Dictionary else {}


## The hazard's words: the skin (`court` = content.court as shipped, or leaderSelect.hazardSkins.press)
## merged with the leader's postponeVerb / postponePrefix / excuses. {skin, ...skin strings, postponeVerb, excuses}.
static func hazard(id: String) -> Dictionary:
	var h: Variant = kit(id).get("hazard")
	var out := {}
	if h is String:
		out["skin"] = h
	elif h is Dictionary:
		out = (h as Dictionary).duplicate(true)
	if not out.has("skin"):
		out["skin"] = "court" if is_default(id) else "press"
	var skin: Variant = ls().get("hazardSkins", {}).get(out["skin"]) if ls().get("hazardSkins") is Dictionary else null
	if skin is Dictionary:
		for k: Variant in skin:
			if not str(k).begins_with("_") and not out.has(k):
				out[k] = skin[k]
	return out


static func dubi(id: String) -> Dictionary:
	var v: Variant = kit(id).get("dubi")
	return v if v is Dictionary else {}


## {sticker: bool, sprite, lines {cash, frenzy, tapFrenzy, miss}}.
static func suitcase(id: String) -> Dictionary:
	var v: Variant = kit(id).get("suitcase")
	var out: Dictionary = (v as Dictionary).duplicate(true) if v is Dictionary else {}
	var sc: Dictionary = ls().get("suitcase", {}) if ls().get("suitcase") is Dictionary else {}
	var sticker: bool = id == str(sc.get("stickerLeader", default_leader()))
	out["sticker"] = sticker
	out["sprite"] = "" if sticker else str(sc.get("plainSprite", "suitcase_plain"))
	return out


## A money source's skin for a leader: {} for a shared tier or the default leader (the shipped
## producer), else {name, flavor, levelUp, src?, firstOwned, sprite} (sprite: the kit's or the
## generic set's).
static func source_skin(id: String, producer_id: String) -> Dictionary:
	if is_default(id):
		return {}
	var st: Variant = ls().get("sourceTiers", {})
	if not st is Dictionary:
		return {}
	var tiers: Dictionary = (st as Dictionary).get("tiers", {})
	for t: Variant in tiers:
		if str(tiers[t]) != producer_id:
			continue
		var sk: Variant = kit(id).get("sources", {}).get(t) if kit(id).get("sources") is Dictionary else null
		var out: Dictionary = (sk as Dictionary).duplicate(true) if sk is Dictionary else {}
		if not out.has("sprite"):
			var g: Variant = (st as Dictionary).get("genericSprites", {}).get(t)
			out["sprite"] = str((g as Dictionary).get("sprite", "")) if g is Dictionary else ""
		out["tier"] = t
		return out
	return {}


## A spin's skin: {slot, name, flavor, icon (fallback spin_slot_<slot>), ...} for a skinned slot,
## {} for the default leader, a shared-as-is slot (F) or a spin with no slot.
static func spin_skin(id: String, upgrade_id: String) -> Dictionary:
	if is_default(id):
		return {}
	var ss: Variant = ls().get("spinSlots", {})
	if not ss is Dictionary:
		return {}
	var slot := ""
	for k: Variant in ss:
		if str(k).length() == 1 and str(ss[k]) == upgrade_id:
			slot = str(k)
	if slot == "" or ((ss as Dictionary).get("sharedAsIs", []) as Array).has(slot):
		return {}
	for sk: Variant in kit(id).get("spins", []):
		if sk is Dictionary and str((sk as Dictionary).get("slot", "")) == slot:
			var out: Dictionary = (sk as Dictionary).duplicate(true)
			if not out.has("icon"):
				out["icon"] = "spin_slot_" + slot
			return out
	return {}


## The story of a leader: {titles, beats, encore}. The default leader's is content.story.
static func story(id: String) -> Dictionary:
	var shared: Dictionary = Content.data().get("story", {}) if Content.data().get("story") is Dictionary else {}
	if is_default(id):
		return {"titles": shared.get("titles", []), "beats": shared.get("beats", []), "encore": shared.get("encore", [])}
	var k: Variant = kit(id).get("story")
	var st: Dictionary = k if k is Dictionary else {}
	return {"titles": st.get("titles", []), "beats": st.get("beats", []), "encore": shared.get("encore", [])}


## The leak's screenshot in an opposition leader's round (leaderSelect.leakRight), else {} (the
## shipped leak copy).
static func leak_copy(s: GameState) -> Dictionary:
	var id := current(s)
	if is_default(id) or str(leader(id).get("side", "")) != "opposition":
		return {}
	var v: Variant = ls().get("leakRight")
	return v if v is Dictionary else {}


## The round's milestone headlines (fire once ever, like content.headlines): the shared ones minus
## bibiOnly.headlines, plus the kit's four (triggers `leaderStat` / `when`) and its five source
## first-owned lines (trigger firstOwned). Evaluate with headline_hit (it knows every type here).
static func headlines(s: GameState) -> Array:
	var id := current(s)
	var all: Array = Content.data().get("headlines", []) if Content.data().get("headlines") is Array else []
	if is_default(id):
		return all
	var drop := bibi_only("headlines")
	var out: Array = []
	for h: Variant in all:
		if h is Dictionary and not drop.has(str((h as Dictionary).get("id", ""))):
			out.append(h)
	var kh: Variant = kit(id).get("headlines", {})
	var trig := {
		"firstTap": {"type": "leaderStat", "leader": id, "key": "taps", "value": 1},
		"firstCrit": {"type": "leaderStat", "leader": id, "key": "crits", "value": 1},
		"taps1000": {"type": "leaderStat", "leader": id, "key": "taps", "value": 1000},
		"firstPartner": {"type": "when", "when": {"membersAtLeast": 1}},
	}
	if kh is Dictionary:
		for k: String in trig:
			var h: Variant = (kh as Dictionary).get(k)
			if h is Dictionary:
				var x: Dictionary = (h as Dictionary).duplicate(true)
				x["trigger"] = trig[k]
				out.append(x)
	var tiers: Variant = ls().get("sourceTiers", {}).get("tiers", {}) if ls().get("sourceTiers") is Dictionary else {}
	for t: Variant in (tiers if tiers is Dictionary else {}):
		var sk: Variant = kit(id).get("sources", {}).get(t) if kit(id).get("sources") is Dictionary else null
		if sk is Dictionary and (sk as Dictionary).get("firstOwned") is Dictionary:
			var x: Dictionary = (sk["firstOwned"] as Dictionary).duplicate(true)
			x["trigger"] = {"type": "firstOwned", "value": str(tiers[t])}
			out.append(x)
	return out


## The sim's half of a headline trigger for the types headlines() adds; every other type returns
## null (the engine's own evaluator handles it).
static func headline_hit(s: GameState, t: Dictionary) -> Variant:
	match str(t.get("type", "")):
		"leaderStat":
			return stat(s, str(t.get("leader", current(s))), str(t.get("key", ""))) >= float(t.get("value", 0))
		"when":
			return Conditions.ok(s, t.get("when", {}))
	return null


## The round's ambient ticker lines: content ambientHeadlinesV2.list (+ listPolitics when asked),
## minus bibiOnly.ambient / ambientPolitics outside his round, plus the leader's kit.ticker and the
## rivalTicker lines whose rival is a rival card this round (spec §5.8).
static func ambient(s: GameState, with_politics: bool = true) -> Array:
	var v2: Dictionary = Content.data().get("ambientHeadlinesV2", {}) if Content.data().get("ambientHeadlinesV2") is Dictionary else {}
	var base: Array = Array(v2.get("list", [])) + (Array(v2.get("listPolitics", [])) if with_politics else [])
	var id := current(s)
	if is_default(id):
		return base
	var drop := bibi_only("ambient") + bibi_only("ambientPolitics")
	var out: Array = []
	for h: Variant in base:
		if h is Dictionary and not drop.has(str((h as Dictionary).get("id", ""))):
			out.append(h)
	for t: Variant in kit(id).get("ticker", []):
		if t is Dictionary:
			out.append(t)
	var riv := rival_people(id)
	for t: Variant in ls().get("rivalTicker", []):
		if t is Dictionary and riv.has(str((t as Dictionary).get("rival", ""))):
			out.append(t)
	return out


# ---------------------------------------------------------------------------------------------
# Save v4 (GameState) and the content lint
# ---------------------------------------------------------------------------------------------

## v3 → v4 (spec §6.3): the save becomes Bibi's round. Called on the raw state dictionary.
static func migrate_v3(st: Dictionary) -> void:
	var dflt := default_leader() if active() else "bibi"
	var ev := int(GameState._num(st.get("evolutions")))
	st["leader"] = dflt
	st["leaderPickPending"] = false
	st["leaderHistory"] = [dflt]
	var b := fresh_stats()
	b["rounds"] = float(ev + 1)
	b["elections"] = float(ev)
	b["taps"] = GameState._num(st.get("tapsLifetime"))
	b["crits"] = GameState._num(st.get("critsLifetime"))
	st["leaders"] = {dflt: b}
	st["seatDeal"] = {}
	st["leaderRound"] = {"prev": dflt if ev > 0 else "", "switched": false, "fresh": false, "freshPct": 0.0,
		"lastPlayed": dflt if ev > 0 else "", "begun": true, "picked": false, "salt": 0}


## The leader fields of a fresh game: the default leader's round has begun and the picker is open.
static func fresh_into(s: GameState) -> void:
	s.leader_round = {"prev": "", "switched": false, "fresh": false, "freshPct": 0.0, "lastPlayed": "", "begun": false, "picked": false, "salt": 0}
	if not active():
		return
	var id := default_leader()
	s.leader = id
	s.leader_history = PackedStringArray([id])
	s.leaders = {id: fresh_stats()}
	s.leaders[id]["rounds"] = 1.0
	s.leader_round["begun"] = true
	s.leader_pick_pending = true
	s.seat_deal = {}


## Validates the raw save's leader fields into `s` (called by GameState.from_dict before the
## coalition is sanitized, since the partner ids depend on the round's lineup). Spec §6.3 guards:
## an unknown leader falls back to the default, with the picker open if the round hasn't started.
static func sanitize_into(s: GameState, r: Dictionary) -> void:
	if not active():
		return   # fresh_into's defaults: no leader content, the default round
	if not r.has("leader"):
		var m := r.duplicate(true)
		migrate_v3(m)
		r = m
	var rr: Variant = r.get("leaderRound")
	var round_: Dictionary = {"prev": "", "switched": false, "fresh": false, "freshPct": 0.0, "lastPlayed": "", "begun": true, "picked": false, "salt": 0}
	if rr is Dictionary:
		for k in ["prev", "lastPlayed"]:
			round_[k] = str(rr.get(k, "")) if rr.get(k) is String and (str(rr.get(k)) == "" or playable(str(rr.get(k)))) else ""
		for k in ["switched", "fresh", "begun", "picked"]:
			round_[k] = rr.get(k) == true
		var u: Variant = rr.get("undo")
		if round_["picked"] and u is Dictionary and playable(str((u as Dictionary).get("leader", ""))):
			round_["undo"] = {"leader": str(u["leader"]), "pending": (u as Dictionary).get("pending") == true}
		var cap := float(ls().get("pick", {}).get("freshFaceBasePct", 0.0)) if ls().get("pick") is Dictionary else 0.0
		round_["freshPct"] = minf(GameState._num(rr.get("freshPct")), cap)
		var sv: Variant = rr.get("salt")
		round_["salt"] = int(sv) if (sv is int or sv is float) and is_finite(float(sv)) else 0
	s.leader_round = round_
	s.leaders = {}
	var ld: Variant = r.get("leaders")
	if ld is Dictionary:
		for k: Variant in ld:
			if not (ls().get("roster", []) as Array).has(str(k)) or not ld[k] is Dictionary:
				continue
			var st := fresh_stats()
			for sk: String in STAT_KEYS:
				st[sk] = GameState._num((ld[k] as Dictionary).get(sk))
			s.leaders[str(k)] = st
	s.leader_history = PackedStringArray()
	var h: Variant = r.get("leaderHistory")
	if h is Array:
		for x: Variant in h:
			if x is String and (ls().get("roster", []) as Array).has(x):
				s.leader_history.append(x)
		while s.leader_history.size() > HISTORY_MAX:
			s.leader_history.remove_at(0)
	var started: bool = int(GameState._num(r.get("runTaps"))) > 0 or _partners_touched(r.get("coalition"))
	var id := str(r.get("leader", "")) if r.get("leader") is String else ""
	s.leader_pick_pending = r.get("leaderPickPending") == true and not started
	if not playable(id):
		id = default_leader()
		if not started:
			s.leader_pick_pending = true
	s.leader = id
	if s.leader_history.is_empty() or s.leader_history[s.leader_history.size() - 1] != id:
		s.leader_history.append(id)
	s.seat_deal = _valid_deal(id, r.get("seatDeal"), s)
	s.leader_ver += 1
	ensure(s)


## A saved deal is kept only when it is a permutation of the lineup's slots with S1 and SI in place
## (a hand-edited save can't deal the 12-seat slot twice); otherwise the round is re-dealt.
static func _valid_deal(id: String, raw: Variant, s: GameState) -> Dictionary:
	var want := deal(id, deal_seed(s, id))
	if not raw is Dictionary or is_default(id):
		return want
	var got: Dictionary = raw
	if got.size() != want.size():
		return want
	var a: Array = []
	var b: Array = []
	for k: Variant in want:
		if not got.has(k) or not got[k] is String:
			return want
		if FIXED_SLOTS.has(str(want[k])) and str(got[k]) != str(want[k]):
			return want
		a.append(str(want[k]))
		b.append(str(got[k]))
	a.sort()
	b.sort()
	if a != b:
		return want
	var out := {}
	for k: Variant in got:
		out[str(k)] = str(got[k])
	return out


static func to_dict(s: GameState) -> Dictionary:
	return {"leader": s.leader, "leaderPickPending": s.leader_pick_pending, "leaderHistory": Array(s.leader_history),
		"leaders": s.leaders.duplicate(true), "seatDeal": s.seat_deal.duplicate(), "leaderRound": s.leader_round.duplicate(true)}


## Every broken reference in the leader content, for each pickable leader (Politics.validate).
static func validate(c: Dictionary) -> PackedStringArray:
	var err := PackedStringArray()
	var lsv: Variant = c.get("leaderSelect")
	var lv: Variant = c.get("leaders")
	if lsv == null and lv == null:
		return err
	if not lsv is Dictionary or not lv is Array:
		err.append("leaders: needs both `leaderSelect` (object) and `leaders` (list)")
		return err
	# Validate against `c` by swapping it in (the builders read Content.data()).
	var was := Content.data()
	var swapped := not is_same(was, c)
	if swapped:
		Content.replace(c)
	var sl := slots()
	for id in pickable():
		var P := "leaders.%s" % id
		if is_default(id):
			continue
		for m: Variant in _lineup(id):
			if not m is Dictionary:
				err.append("%s.coalition.lineup: every entry is an object" % P)
				continue
			if profile(str(m.get("id", ""))).is_empty():
				err.append("%s.coalition.lineup: unknown partner %s" % [P, m.get("id", "")])
			if not sl.get(str(m.get("slot", ""))) is Dictionary:
				err.append("%s.coalition.lineup.%s: unknown slot %s" % [P, m.get("id", ""), m.get("slot", "")])
		var co: Dictionary = leader(id).get("coalition", {})
		var roster := build_roster(id, deal(id, 1))
		var ids := {}
		for p: Dictionary in roster:
			ids[p["id"]] = true
			for k in Conditions.unknown_keys(p.get("unlock", {})):
				err.append("%s: slot %s unlock: unknown condition %s" % [P, p.get("slot", ""), k])
			for e: Variant in p.get("effects", []):
				if not e is Dictionary or not Economy.EFFECTS.has((e as Dictionary).get("type", "")):
					err.append("%s.%s.effects: unknown effect %s" % [P, p["id"], str(e)])
		if not ids.has(str(co.get("firstPartner", ""))):
			err.append("%s.coalition.firstPartner: %s is not in the lineup" % [P, co.get("firstPartner", "")])
		for r: Variant in co.get("rivals", []):
			if card_profile(str(r)).is_empty() and _content_event(str(r)).is_empty():
				err.append("%s.coalition.rivals: unknown card %s" % [P, r])
		for e: Dictionary in build_events(id):
			if not Events.EFFECTS.has(str(e.get("effect", {}).get("type", "none"))):
				err.append("%s: card %s effect %s unknown" % [P, e.get("id", "?"), e.get("effect", {}).get("type", "")])
			for k in Conditions.unknown_keys(e.get("when", {})):
				err.append("%s: card %s when: unknown condition %s" % [P, e.get("id", "?"), k])
		var re := rule_effect(id)
		var rt := str(re.get("type", ""))
		if rt == "":
			err.append("%s.rule.effect: missing (one signature rule per leader)" % P)
		elif not RULE_TYPES.has(rt) and not Economy.EFFECTS.has(rt):
			err.append("%s.rule.effect.type: %s is not implemented by the sim" % [P, rt])
		if rt == "selfEvent" and _content_event(str(re.get("event", ""))).is_empty():
			err.append("%s.rule.effect.event: unknown event %s" % [P, re.get("event", "")])
		if rt == "leaderEffects":
			for e: Variant in re.get("effects", []):
				if not e is Dictionary or not Economy.EFFECTS.has(str((e as Dictionary).get("type", ""))):
					err.append("%s.rule.effect.effects: unknown economy effect %s" % [P, str(e)])
			var odp: Variant = re.get("onDemandPaid")
			if odp != null and (not odp is Dictionary or str((odp as Dictionary).get("type", "")) != "tapBuff"):
				err.append("%s.rule.effect.onDemandPaid: only tapBuff is implemented" % P)
			var co_: Variant = re.get("coalition", {})
			for k: Variant in (co_ if co_ is Dictionary else {}):
				if not OVERRIDABLE.has(str(k)):
					err.append("%s.rule.effect.coalition.%s: not an overridable coalition number" % [P, k])
	if swapped:
		Content.replace(was)
	return err
