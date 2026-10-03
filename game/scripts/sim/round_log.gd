class_name RoundLog
extends RefCounted
## The rounds' history for the share cards (the share platform, Bar 2026-10-02): one compact record
## per election in `GameState.history` (persisted, capped at MAX), and the live round's marks in
## `GameState.round_log` (the first frame the coalition reached the gate, and the lifetime counters
## at the round's start, so a record can say what THIS round added). Pure: no Hebrew, no nodes.
##
## A record (keys short on purpose: up to MAX of them ride in every save):
##   n       the election number this record closed (1 = the first election)
##   leader  the round's leader id ("" without leader content)
##   sec     the round's run seconds (pick to "עוד סבב!")
##   gate    seconds to the coalition gate (61), −1 when the round never logged it (an old save)
##   earned  the round's income (run_money)
##   top     the producer that earned the most this round ("" = none), topPct its share 0..1
##   paid    paid lines this round (demands, ultimatums, rejoins), mvp the partner paid the most
##   left    partners who walked out this round, court the court + press days this round
##   post    the round's postponements
## Hooks (sim): Economy.tick → on_tick (the gate's first frame), Economy.evolve → record (before the
## run resets) and start_round (after Politics.on_election).

const MAX := 120
const KEYS_NUM := ["n", "sec", "gate", "earned", "topPct", "paid", "left", "court", "post"]


static func fresh() -> Dictionary:
	return {"gateSec": -1.0, "court0": 0, "left0": 0}


## The round's marks after a load: numbers only, unknown keys dropped.
static func sanitize(raw: Variant) -> Dictionary:
	var out := fresh()
	if raw is Dictionary:
		for k: String in out.keys():
			var v: Variant = (raw as Dictionary).get(k)
			if (v is float or v is int) and is_finite(float(v)):
				out[k] = float(v) if k == "gateSec" else int(v)
	return out


## A saved history: at most MAX records, each with numbers that are numbers and ids that are short
## strings. Old saves have none (an empty history: the career card derives what it can from the
## lifetime stats, career()).
static func sanitize_history(raw: Variant) -> Array:
	var out: Array = []
	if not raw is Array:
		return out
	for r: Variant in raw:
		if not r is Dictionary:
			continue
		var rec := {}
		for k: String in KEYS_NUM:
			var v: Variant = (r as Dictionary).get(k, 0)
			rec[k] = float(v) if (v is float or v is int) and is_finite(float(v)) else 0.0
		for k in ["leader", "top", "mvp"]:
			var v: Variant = (r as Dictionary).get(k, "")
			rec[k] = str(v).substr(0, 24) if v is String else ""
		out.append(rec)
	if out.size() > MAX:
		out = out.slice(out.size() - MAX)
	return out


## The coalition reached the gate for the first time this round: the run second it happened.
static func on_tick(s: GameState, d: Economy.Derived) -> void:
	if s.round_log.is_empty():
		s.round_log = fresh()
	if float(s.round_log.get("gateSec", -1.0)) < 0.0 and d != null and d.seats_gate_open and Coalition.active():
		s.round_log["gateSec"] = s.run_time_sec


## Seconds to the gate this round (−1 = not reached / not logged).
static func gate_sec(s: GameState) -> float:
	return float(s.round_log.get("gateSec", -1.0)) if s.round_log is Dictionary else -1.0


## The live round as a record (the term summary before the election resets it; record() appends it).
static func current(s: GameState, d: Economy.Derived = null) -> Dictionary:
	if d == null:
		d = Economy.derive(s)
	var top := ""
	var top_pct := 0.0
	var sum := 0.0
	for id: Variant in d.producer_bps:
		sum += maxf(0.0, float(d.producer_bps[id]))
	if sum > 0.0:
		for id: Variant in d.producer_bps:
			var v := maxf(0.0, float(d.producer_bps[id])) / sum
			if v > top_pct:
				top_pct = v
				top = str(id)
	var inv: Dictionary = s.investigation if s.investigation is Dictionary else {}
	var co: Dictionary = s.coalition if s.coalition is Dictionary else {}
	var lg: Dictionary = s.round_log if s.round_log is Dictionary and not s.round_log.is_empty() else fresh()
	var court_now := int(inv.get("courtDays", 0)) + int(inv.get("pressDays", 0))
	return {
		"n": s.evolutions + 1, "leader": s.leader, "sec": s.run_time_sec,
		"gate": float(lg.get("gateSec", -1.0)), "earned": s.run_money,
		"top": top, "topPct": top_pct,
		"paid": int(co.get("paidRound", 0)), "mvp": mvp(s),
		"left": maxi(0, int(co.get("leftLifetime", 0)) - int(lg.get("left0", 0))),
		"court": maxi(0, court_now - int(lg.get("court0", 0))),
		"post": int(inv.get("postponements", 0)),
	}


## The partner this round paid the most (the chat log's paid lines; "" = nobody was paid).
static func mvp(s: GameState) -> String:
	var by := {}
	var co: Dictionary = s.coalition if s.coalition is Dictionary else {}
	for m: Variant in co.get("chat", []):
		if m is Dictionary and ["paid", "deleted"].has(str(m.get("state", ""))) and Coalition.is_payable(m):
			var pid := str(m.get("partner", ""))
			if pid != "":
				by[pid] = float(by.get(pid, 0.0)) + maxf(0.0, float(m.get("price", 0.0)))
	var best := ""
	var bv := -1.0
	for k: String in by:
		if float(by[k]) > bv:
			bv = float(by[k])
			best = k
	return best


## Economy.evolve, before the run resets: the round's record joins the history.
static func record(s: GameState, d: Economy.Derived = null) -> Dictionary:
	var rec := current(s, d)
	s.history.append(rec)
	if s.history.size() > MAX:
		s.history = s.history.slice(s.history.size() - MAX)
	return rec


## Economy.evolve, after Politics.on_election: the new round's marks (the lifetime counters now).
static func start_round(s: GameState) -> void:
	var inv: Dictionary = s.investigation if s.investigation is Dictionary else {}
	var co: Dictionary = s.coalition if s.coalition is Dictionary else {}
	s.round_log = {"gateSec": -1.0, "court0": int(inv.get("courtDays", 0)) + int(inv.get("pressDays", 0)),
		"left0": int(co.get("leftLifetime", 0))}


## The career across every round: {rounds, earned, fastest (s, 0 = unknown), leader (the favourite,
## by rounds played), partner (the most common MVP), court (days), walked (partners who left),
## best (the record with the fastest gate, or {}), fromHistory (false = an old save's estimate)}.
static func career(s: GameState) -> Dictionary:
	var h: Array = s.history
	var rounds := maxi(s.evolutions, h.size())
	var fastest := 0.0
	var best := {}
	var partners := {}
	var walked := 0
	for r: Dictionary in h:
		var g := float(r.get("gate", -1.0))
		var t := g if g > 0.0 else float(r.get("sec", 0.0))
		if t > 0.0 and (fastest <= 0.0 or t < fastest):
			fastest = t
			best = r
		var p := str(r.get("mvp", ""))
		if p != "":
			partners[p] = int(partners.get(p, 0)) + 1
		walked += int(r.get("left", 0))
	if fastest <= 0.0:
		fastest = float(s.stats.get("fastestRunSec", 0.0))
	var fav := ""
	var fav_n := -1.0
	for id: Variant in s.leaders:
		var e: Variant = s.leaders[id]
		var n := float((e as Dictionary).get("rounds", 0.0)) if e is Dictionary else 0.0
		if n > fav_n:
			fav_n = n
			fav = str(id)
	if fav == "" and not h.is_empty():
		fav = str(h[h.size() - 1].get("leader", ""))
	var partner := ""
	var pn := 0
	for k: String in partners:
		if int(partners[k]) > pn:
			pn = int(partners[k])
			partner = k
	if h.is_empty():
		walked = int(s.coalition.get("leftLifetime", 0)) if s.coalition is Dictionary else 0
	var court := int(float(s.stats.get("hazardDays", 0.0)))
	if court <= 0:
		court = Investigation.hazard_days(s)
	return {"rounds": rounds, "earned": s.all_time_money, "fastest": fastest, "leader": fav,
		"partner": partner, "court": court, "walked": walked, "best": best, "fromHistory": not h.is_empty()}


## The career's title tier 0..5 by rounds survived (the copy picks the words; CAREER_TITLE_<tier>).
static func title_tier(rounds: int) -> int:
	if rounds >= 25:
		return 5
	if rounds >= 10:
		return 4
	if rounds >= 5:
		return 3
	if rounds >= 3:
		return 2
	if rounds >= 1:
		return 1
	return 0
