class_name SeededRound
extends RefCounted
## A sandboxed, reproducible round: "תעבור אותי" (Beat My Round, Challenge) and "הסבב היומי" (the
## Daily Round, DailyRound). Pure rules, no nodes. The controller (main.gd, the "seeded rounds" blocks)
## swaps its GameState for one of these while the round runs, and swaps the main save back after.
##
## Reproducible as far as the sim's randomness goes: the round is a fresh GameState (no base, no
## perks, no lifetime anything: PacingSim.first_round's setup) whose leader is fixed by the link or the
## day, whose seat deal is dealt from the seed (Leaders.set_salt → deal_seed), whose periodic event
## rolls (Events._every_roll's everySalt) come from the seed, and whose every other draw comes from
## its own seeded stream (rng(name)): "tap" (crits), "golden" (the Suitcase's timer and outcome),
## "politics" (the chat's demands and threats, the event deck, brawl pairs). Separate streams mean a
## different number of taps never re-deals the event deck (PacingSim does the same). The Politics
## clock context is pinned (hour, weekday), so the real time of day changes nothing.
##
## The round record (new_record / observe) is the spoiler-free grid: one cell per partner of the
## lineup (stand-ins left out), in lineup order:
##   B  joined (🟦)     Y  joined and paid a demand or an ultimatum after joining (a concession, 🟨)
##   R  walked out on an ultimatum (🟥)     W  never joined (⬜)
## plus the court line (testified / dodged) and the press flag (a press-day leader's skin).

const STREAMS := ["tap", "golden", "politics", "misc"]
const CTX_HOUR := 12
const CTX_WEEKDAY := 3
const CELLS := {"B": "🟦", "Y": "🟨", "R": "🟥", "W": "⬜"}
const ROW := 5

var kind := ""          # "challenge" | "daily"
var leader := ""
var seed_ := 0
var _rngs: Dictionary = {}


func _init(kind_: String = "", leader_: String = "", seed__: int = 0) -> void:
	kind = kind_
	leader = leader_
	seed_ = seed__
	for k: String in STREAMS:
		var r := RandomNumberGenerator.new()
		r.seed = stream_seed(seed_, k)
		_rngs[k] = r


## One stream's seed: a hash of the round's seed and the stream's name (stable across runs).
static func stream_seed(seed__: int, stream: String) -> int:
	return hash("od-sevev|%d|%s" % [seed__, stream])


## A draw in [0, 1) from the named stream, as a Callable the sim takes (`rng`).
func rng(stream: String) -> Callable:
	var r: RandomNumberGenerator = _rngs.get(stream, _rngs["misc"])
	return r.randf


## The Politics.tick context with the clock pinned (Conditions read hour / weekday): `base` is the
## controller's own context (nowMs stays real: the calendar's blackout is the real world's).
static func pin_ctx(base: Dictionary) -> Dictionary:
	var c := base.duplicate()
	c["hour"] = CTX_HOUR
	c["weekday"] = CTX_WEEKDAY
	return c


## The round's fresh state: a new game as `leader` (when playable; else the default leader's round),
## its deal and periodic rolls from `seed__`. `from` (the player's main save, optional) lends only the
## FTUE flags, so a player who knows the game is not walked through the tutorial again; it lends no
## money, base, perk, trophy or stat.
static func fresh_state(leader_: String, seed__: int, from: GameState = null) -> GameState:
	var s := GameState.fresh()
	Leaders.set_salt(s, seed__)
	if leader_ != "" and Leaders.playable(leader_):
		Leaders.start_round(s, leader_)
	elif Leaders.active():
		Leaders.start_round(s, Leaders.default_leader())
	s.leader_round.erase("undo")   # no "להחליף" chip: the link or the day fixed the leader
	s.events["everySalt"] = posmod(seed__, 1000003)
	if from != null:
		s.ftue = from.ftue.duplicate(true)
		for k: Variant in s.ui.keys():
			s.ui[k] = from.ui.get(k, s.ui[k])
	return s


# ------------------------------------------------------------------ the round record (the grid)

static func new_record() -> Dictionary:
	return {"order": [], "joined": {}, "paid": {}, "walked": {}, "hazardDays": 0, "press": false}


## Folds the state's coalition and court into the record (call it every step: a paid line is seen
## before the chat log's trim can drop it).
static func observe(rec: Dictionary, s: GameState) -> void:
	if (rec["order"] as Array).is_empty():
		for p: Variant in Coalition.partners():
			if p is Dictionary and (p as Dictionary).get("standIn", false) != true:
				(rec["order"] as Array).append(str((p as Dictionary).get("id", "")))
		rec["press"] = Leaders.active() and not Leaders.has_court()
	var co: Dictionary = s.coalition if s.coalition is Dictionary else {}
	var parts: Dictionary = co.get("partners", {}) if co.get("partners") is Dictionary else {}
	for id: String in rec["order"]:
		var st: Variant = parts.get(id)
		if not st is Dictionary:
			continue
		var status := str((st as Dictionary).get("status", ""))
		if status == "member" or status == "merged":
			rec["joined"][id] = true
		elif status == "left":
			rec["walked"][id] = true
	for m: Variant in co.get("chat", []):
		if not m is Dictionary:
			continue
		var md: Dictionary = m
		var t := str(md.get("type", ""))
		var paid := ["paid", "deleted"].has(str(md.get("state", "")))
		if paid and ((t == "demand" and md.get("join", false) != true) or t == "ultimatum"):
			var pid := str(md.get("partner", ""))
			var seen: Array = rec["paid"].get(pid, [])
			if not seen.has(int(md.get("seq", 0))):
				seen.append(int(md.get("seq", 0)))
			rec["paid"][pid] = seen
	rec["hazardDays"] = maxi(int(rec["hazardDays"]), Investigation.hazard_days(s))


## The record's cells, one letter per partner (B / Y / R / W, see the header), lineup order.
static func cells(rec: Dictionary) -> String:
	var out := ""
	for id: String in rec.get("order", []):
		if rec.get("walked", {}).has(id):
			out += "R"
		elif rec.get("joined", {}).has(id):
			out += "Y" if not (rec.get("paid", {}).get(id, []) as Array).is_empty() else "B"
		else:
			out += "W"
	return out


## The emoji grid, ROW cells a line; every line opens with an RLM so a chat app lays it out RTL
## (the same order as the lineup reads on the in-game grid).
static func grid_lines(cells_: String) -> PackedStringArray:
	var out := PackedStringArray()
	var line := ""
	for i in cells_.length():
		line += str(CELLS.get(cells_[i], "⬜"))
		if (i + 1) % ROW == 0:
			out.append(Bidi.RLM + line)
			line = ""
	if line != "":
		out.append(Bidi.RLM + line)
	return out


## "testified" (a court or press day was served) or "dodged".
static func court_word(rec: Dictionary) -> String:
	return "testified" if int(rec.get("hazardDays", 0)) > 0 else "dodged"


## "7:42": whole seconds, minutes unpadded (a round over an hour reads "61:05").
static func mmss(sec: float) -> String:
	var t := maxi(0, int(floorf(sec)))
	return "%d:%02d" % [t / 60, t % 60]
