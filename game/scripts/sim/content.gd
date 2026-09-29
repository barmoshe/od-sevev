class_name Content
extends RefCounted
## Typed-ish view of res://data/content.json (a copy of design/content.json, the economy's single
## source of truth; tools/sync_data.sh keeps it current). Pure data: no nodes.

const PATH := "res://data/content.json"

static var _c: Dictionary = {}
static var _producer_index: Dictionary = {}
static var _upgrade_by_id: Dictionary = {}
static var _outcome_by_id: Dictionary = {}


static func data() -> Dictionary:
	if _c.is_empty():
		load_from(PATH)
	return _c


## Loads content from a path (tests may point this at a fixture). Fails loudly on bad JSON.
static func load_from(path: String) -> void:
	var text := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text)
	assert(parsed is Dictionary, "[content] cannot parse %s" % path)
	replace(parsed)


## Swaps in an already-parsed content dictionary (tests layer fixture sections over a base).
static func replace(c: Dictionary) -> void:
	_c = c
	_producer_index.clear()
	_upgrade_by_id.clear()
	_outcome_by_id.clear()
	var i := 0
	for p: Dictionary in _c["producers"]:
		_producer_index[p["id"]] = i
		i += 1
	for u: Dictionary in _c["upgrades"]:
		_upgrade_by_id[u["id"]] = u
	for o: Dictionary in _c["golden"]["outcomes"]:
		_outcome_by_id[o["id"]] = o


static func producers() -> Array:
	return data()["producers"]


static func producer_ids() -> PackedStringArray:
	var ids := PackedStringArray()
	for p: Dictionary in producers():
		ids.append(p["id"])
	return ids


static func producer(id: String) -> Dictionary:
	data()
	return producers()[_producer_index[id]]


static func producer_index(id: String) -> int:
	data()
	return _producer_index.get(id, -1)


static func upgrades() -> Array:
	return data()["upgrades"]


static func upgrade(id: String) -> Dictionary:
	data()
	return _upgrade_by_id.get(id, {})


static func outcome(id: String) -> Dictionary:
	data()
	assert(_outcome_by_id.has(id), "[content] golden outcome %s missing" % id)
	return _outcome_by_id[id]


## od-sevev (game-developer, wave 1): golden outcomes are typed by data, not by id.
## golden.outcomes[].type is one of OUTCOME_TYPES; content without `type` keeps the fork's ids.
const OUTCOME_TYPES := ["instant", "bpsFrenzy", "tapFrenzy"]
const _LEGACY_OUTCOME_TYPE := {"bunch": "instant", "frenzy": "bpsFrenzy", "tapFrenzy": "tapFrenzy"}


## The od-sevev content names the same three types bunch / frenzy / tapFrenzy (game-developer sim).
const _OUTCOME_TYPE_ALIASES := {"bunch": "instant", "frenzy": "bpsFrenzy"}


static func outcome_type(id: String) -> String:
	var t := String(outcome(id).get("type", _LEGACY_OUTCOME_TYPE.get(id, "")))
	t = String(_OUTCOME_TYPE_ALIASES.get(t, t))
	assert(OUTCOME_TYPES.has(t), "[content] golden outcome %s has no known type (%s)" % [id, t])
	return t


## The first outcome of a type ({} when the content has none): the buff multipliers read it.
static func outcome_of_type(t: String) -> Dictionary:
	for o: Dictionary in data()["golden"]["outcomes"]:
		if outcome_type(o["id"]) == t:
			return o
	return {}


static func has_outcome(id: String) -> bool:
	data()
	return _outcome_by_id.has(id)


static func section(key: String) -> Variant:
	return data().get(key)


## content.json `_speciesRule`: index = min(evolutions, last); at the last title append
## "Mk " + (evolutions - (last - 1)).
static func species_title(evolutions: int) -> String:
	var titles: Array = data()["prestige"]["speciesTitles"]
	var last := titles.size() - 1
	var i := mini(evolutions, last)
	if i == last:
		return "%s Mk %d" % [titles[last], evolutions - (last - 1)]
	return titles[i]
