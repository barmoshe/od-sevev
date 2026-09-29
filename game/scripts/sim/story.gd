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


## One ambient headline whose conditions hold, avoiding the recent window. `recent` is updated.
static func pick_ambient(s: GameState, recent: Array, hour: int, rng: Callable = randf) -> String:
	var v2: Dictionary = _c().get("ambientHeadlinesV2", {})
	var window := int(v2.get("noRepeatWindow", 12))
	var pool: Array = []
	var era_id: String = era_for(s.evolutions).get("id", "")
	for h: Dictionary in v2.get("list", []):
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
	if w.has("trophiesAtLeast") and s.achievements.size() < int(w["trophiesAtLeast"]):
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
