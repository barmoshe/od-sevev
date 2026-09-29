class_name Story
extends RefCounted
## v2 story, pure: eras, the narrator's story beats and the conditional ambient headlines
## (content.json eras, story, narrator, ambientHeadlinesV2).


static func _c() -> Dictionary:
	return Content.data()


static func eras() -> Array:
	return _c().get("eras", {}).get("list", [])


## The era for an evolution count: the last era whose fromEvolutions <= n.
static func era_for(evolutions: int) -> Dictionary:
	var out: Dictionary = {}
	for e: Dictionary in eras():
		if evolutions >= int(e["fromEvolutions"]):
			out = e
	return out


static func narrator_name() -> String:
	return str(_c().get("narrator", {}).get("name", "CHIP"))


## The beat shown after reaching `evolutions` (1-based): beats[n-1], then the encore with {n}.
static func beat_for(evolutions: int) -> PackedStringArray:
	var st: Dictionary = _c().get("story", {})
	var beats: Array = st.get("beats", [])
	if evolutions >= 1 and evolutions <= beats.size():
		return PackedStringArray(beats[evolutions - 1])
	var out := PackedStringArray()
	var mk := evolutions - beats.size() + 1
	for l: String in st.get("encore", []):
		out.append(l.replace("{n}", str(mk)))
	return out


static func beat_id(evolutions: int) -> String:
	return "beat_%d" % evolutions


## Dubi's flash after an election, for the leader who played the round just ended (spec §5.10):
## that leader's beats indexed by their OWN election count, then the shared encore.
## {leader, n, title, lines, id}. Bibi's id stays "beat_<n>" (storySeen of older saves).
static func flash(s: GameState) -> Dictionary:
	var id := str(s.leader_round.get("lastPlayed", "")) if Leaders.active() else ""
	if id == "" or not Leaders.playable(id):
		id = Leaders.current(s)
	var n := int(Leaders.stat(s, id, "elections")) if Leaders.active() else s.evolutions
	var st := Leaders.story(id)
	var beats: Array = st["beats"]
	var titles: Array = st["titles"]
	var lines := PackedStringArray()
	if n >= 1 and n <= beats.size():
		lines = PackedStringArray(beats[n - 1])
	else:
		for l: Variant in st["encore"]:
			lines.append(str(l).replace("{n}", str(n - beats.size() + 1)))
	var title := str(titles[n - 1]) if n >= 1 and n <= titles.size() else ""
	var bid := beat_id(n) if Leaders.is_default(id) else "beat_%s_%d" % [id, n]
	return {"leader": id, "n": n, "title": title, "lines": lines, "id": bid}


## One ambient headline whose conditions hold, avoiding the recent window. `recent` is updated.
static func pick_ambient(s: GameState, recent: Array, hour: int, rng: Callable = randf) -> String:
	var v2: Dictionary = _c().get("ambientHeadlinesV2", {})
	var window := int(v2.get("noRepeatWindow", 12))
	var pool: Array = []
	var era_id: String = era_for(s.evolutions).get("id", "")
	for h: Dictionary in Leaders.ambient(s, false):   # the round's lines (bibiOnly out, the leader's ticker in)
		if recent.has(h["text"]):
			continue
		if _when(s, h.get("when", {}), era_id, hour):
			pool.append(h["text"])
	if pool.is_empty():
		recent.clear()
		return ""
	var t: String = pool[int(float(rng.call()) * pool.size()) % pool.size()]
	recent.append(t)
	while recent.size() > window:
		recent.pop_front()
	return t


## Dubi's word salad (content dubi.wordSalad {when, chance}; deck §I spin fatigue): whether his
## next talking point comes out scrambled. The engine calls it when Dubi is about to speak; true
## counts the stat "wordSaladSeen" (secret trophy "אין! ציד! כלום!"), so call it once per line shown.
static func roll_word_salad(s: GameState, rng: Callable = randf, ctx: Dictionary = {}) -> bool:
	var ws: Variant = _c().get("dubi", {}).get("wordSalad")
	if not ws is Dictionary or not Conditions.ok(s, (ws as Dictionary).get("when", {}), ctx):
		return false
	if float(rng.call()) >= float((ws as Dictionary).get("chance", 0.0)):
		return false
	Meta.bump(s, "wordSaladSeen")
	return true


## The salad itself: the words of `lines` (his last three talking points), shuffled, each keeping or
## losing its "!" at random, the last always shouting. No Hebrew is authored here.
static func word_salad(lines: Array, rng: Callable = randf) -> String:
	var words: Array = []
	for l: Variant in lines:
		for w: String in str(l).split(" ", false):
			var bare := w.replace("!", "")
			if bare != "":
				words.append(bare)
	for i in range(words.size() - 1, 0, -1):
		var j := int(float(rng.call()) * (i + 1)) % (i + 1)
		var tmp: Variant = words[i]
		words[i] = words[j]
		words[j] = tmp
	var out := PackedStringArray()
	for i in words.size():
		out.append(str(words[i]) + ("!" if i == words.size() - 1 or float(rng.call()) < 0.5 else ""))
	return " ".join(out)


static func _when(s: GameState, w: Dictionary, era_id: String, hour: int) -> bool:
	if w.has("era") and w["era"] != era_id:
		return false
	if w.has("owned") and s.owned_of(w["owned"]["producer"]) < int(w["owned"]["count"]):
		return false
	if w.has("frenzy") and (s.buff_frenzy > 0.0) != bool(w["frenzy"]):
		return false
	if w.has("tapFrenzy") and (s.buff_tap_frenzy > 0.0) != bool(w["tapFrenzy"]):
		return false
	if w.has("evolutionsAtLeast") and s.evolutions < int(w["evolutionsAtLeast"]):
		return false
	if w.has("perk") and Meta.perk_level(s, w["perk"]) <= 0:
		return false
	if w.has("trophiesAtLeast") and Meta.trophy_count(s) < int(w["trophiesAtLeast"]):
		return false
	if w.has("allTimeAtLeast") and s.all_time_bananas < float(w["allTimeAtLeast"]):
		return false
	if w.has("goldenAtLeast") and s.golden_caught_lifetime < int(w["goldenAtLeast"]):
		return false
	if w.has("hour"):
		var a := int(w["hour"][0])
		var b := int(w["hour"][1])
		var inside := (hour >= a and hour <= b) if a <= b else (hour >= a or hour <= b)
		if not inside:
			return false
	return true
