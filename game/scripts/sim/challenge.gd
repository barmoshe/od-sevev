class_name Challenge
extends RefCounted
## "תעבור אותי" (Beat My Round): the challenge link's pure rules. No nodes, no JS.
##
## The link's hash (also what window.odArrival.params carries once the share platform parses it):
##   #k=challenge&l=<leader>&s=<seed>&t=<secs to 61>&r=<ref>[&vs=<the challenger's secs>]
##   k   always "challenge"
##   l   the leader id (a playable roster id; anything else falls back to the default leader)
##   s   the deal seed, 0 … 2147483647 (SeededRound: the deal, the events, every draw)
##   t   the sender's time to 61 in whole seconds, 1 … 86400
##   r   the sender's ref: 8 random [a-z0-9] kept on the device (RoundBook), never personal
##   vs  only on a return link: the time the sender was answering (their friend's t)
## The time is the round's play clock (GameState.run_time_sec: the economy's clock, so the vote
## hold, a hidden tab and the pick never count) at the moment "עוד סבב!" is pressed with the gate
## open, floored to whole seconds.

const KIND := "challenge"
const SEED_MAX := 2147483647
const T_MAX := 86400
const REF_LEN := 8
const REF_CHARS := "abcdefghijklmnopqrstuvwxyz0123456789"
const KEYS := ["k", "l", "s", "t", "r", "vs"]


## Key/value pairs of a URL hash or query ("#a=1&b=2", "a=1&b=2"), percent-decoded.
static func parse_pairs(h: String) -> Dictionary:
	var out := {}
	var t := h.strip_edges()
	if t.begins_with("#") or t.begins_with("?"):
		t = t.substr(1)
	for part in t.split("&", false):
		var i := part.find("=")
		if i <= 0:
			continue
		out[part.substr(0, i).uri_decode()] = part.substr(i + 1).uri_decode()
	return out


static func _int_in(v: Variant, lo: int, hi: int) -> int:
	var str_ := str(v).strip_edges()
	if str_ == "" or not str_.is_valid_int():
		return -1
	var n := str_.to_int()
	return n if n >= lo and n <= hi else -1


static func _ref_ok(r: String) -> bool:
	if r.length() != REF_LEN:
		return false
	for ch in r:
		if not REF_CHARS.contains(ch):
			return false
	return true


## A parsed, validated challenge from a hash string or a params dictionary (odArrival.params):
## {leader, seed, t, ref, vs} (vs −1 when absent, ref "" when missing or malformed), or {} when this
## is not a playable challenge (another kind, a missing or out-of-range seed or time).
static func parse(src: Variant) -> Dictionary:
	var p: Dictionary = src if src is Dictionary else parse_pairs(str(src))
	if str(p.get("k", KIND)) != KIND:
		return {}
	var seed_ := _int_in(p.get("s", ""), 0, SEED_MAX)
	var t := _int_in(p.get("t", ""), 1, T_MAX)
	if seed_ < 0 or t < 0:
		return {}
	var leader := str(p.get("l", ""))
	if not Leaders.playable(leader):
		leader = Leaders.default_leader()
	var ref := str(p.get("r", ""))
	return {"leader": leader, "seed": seed_, "t": t, "ref": ref if _ref_ok(ref) else "",
		"vs": _int_in(p.get("vs", ""), 1, T_MAX)}


## The hash (no "#") for a challenge {leader, seed, t, ref, vs?}: keys in KEYS order, vs only when > 0.
static func build_hash(c: Dictionary) -> String:
	var parts := PackedStringArray()
	parts.append("k=" + KIND)
	parts.append("l=" + str(c.get("leader", "")).uri_encode())
	parts.append("s=%d" % int(c.get("seed", 0)))
	parts.append("t=%d" % int(c.get("t", 0)))
	if str(c.get("ref", "")) != "":
		parts.append("r=" + str(c["ref"]).uri_encode())
	if int(c.get("vs", -1)) > 0:
		parts.append("vs=%d" % int(c["vs"]))
	return "&".join(parts)


## The shareable URL: the share platform's OG stub /s/<leader>-challenge (its preview card), the
## hash after it. `stub` false: the site root (before the platform's stub pages exist).
static func link(site: String, c: Dictionary, stub: bool = true) -> String:
	var base := site if site.ends_with("/") else site + "/"
	if stub:
		base += "s/%s-challenge" % str(c.get("leader", ""))
	return base + "#" + build_hash(c)


## The challenge a finished round sends: the main game's round (its leader and a seed of its own,
## stable for the round, so two shares of one round are one link) or a challenge round's (its seed).
static func seed_for_round(s: GameState) -> int:
	return posmod(hash("chal|%s|%d|%d" % [s.leader, s.evolutions, int(s.leader_round.get("salt", 0))]), SEED_MAX)


## Win / lose / tie by whole seconds: {result, mine, theirs, gap}. Lower is better.
static func outcome(mine: int, theirs: int) -> Dictionary:
	var r := "tie"
	if mine < theirs:
		r = "win"
	elif mine > theirs:
		r = "lose"
	return {"result": r, "mine": mine, "theirs": theirs, "gap": absi(mine - theirs)}


## The return link's challenge: the same leader and seed, my time as t, the time I answered as vs,
## my own ref as r.
static func return_challenge(ch: Dictionary, mine: int, my_ref: String) -> Dictionary:
	return {"leader": ch.get("leader", ""), "seed": int(ch.get("seed", 0)), "t": mine, "ref": my_ref, "vs": int(ch.get("t", 0))}


## A fresh device ref (8 × [a-z0-9]).
static func new_ref(rng: Callable = randf) -> String:
	var out := ""
	for i in REF_LEN:
		out += REF_CHARS[int(float(rng.call()) * REF_CHARS.length()) % REF_CHARS.length()]
	return out
