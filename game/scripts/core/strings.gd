class_name Strings
extends RefCounted
## All player-facing copy comes from res://data/ui-strings.json (a copy of ux/ui-strings.json,
## owned by the UX Designer). Unknown ids fail loudly: a missing string is a bug, not a blank.

static var _u: Dictionary = {}


static func data() -> Dictionary:
	if _u.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/ui-strings.json"))
		assert(parsed is Dictionary, "[strings] cannot parse ui-strings.json")
		_u = parsed
	return _u


static func has(id: String) -> bool:
	return data()["strings"].has(id)


## Fills {placeholders}. od-sevev: in a Hebrew string every numeric value is wrapped in LRI…PDI
## (Bidi.fill), so numbers stay LTR tokens inside RTL text.
static func s(id: String, params: Dictionary = {}) -> String:
	var tbl: Dictionary = data()["strings"]
	assert(tbl.has(id), "[strings] unknown id %s" % id)
	return Bidi.fill(String(tbl.get(id, id)), params)


## od-sevev: the round's leader skin first (spec §5.3-5.4: tiers 4-8 and the spin slots carry a
## per-leader name outside Bibi's round, LeaderUi), then ui-strings.json producerNames/upgradeNames
## (UX's display override), then the content's own `name` (the Game Designer's copy deck), then the id.
static func producer_name(id: String) -> String:
	var sk := LeaderUi.producer_word(id, "name")
	if sk != "":
		return sk
	var n: Variant = data().get("producerNames", {}).get(id)
	if n == null and Content.producer_index(id) >= 0:
		n = Content.producer(id).get("name")
	return str(n) if n != null else id.to_upper()


static func upgrade_name(id: String) -> String:
	var sk := LeaderUi.spin_word(id, "name")
	if sk != "":
		return sk
	var n: Variant = data().get("upgradeNames", {}).get(id)
	if n == null:
		n = Content.upgrade(id).get("name")
	return str(n) if n != null else id.to_upper()


## The spin's short effect line: slots A, B and E through the _LEADER keys (the round's verb and
## crit name, for every leader: Bibi's kit words equal the shipped lines), else upgradeEffects.
static func upgrade_effect(id: String) -> String:
	var le := LeaderUi.spin_effect(id)
	if le != "":
		return le
	return data().get("upgradeEffects", {}).get(id, "")


## ux/ui-strings.json rule 3: plural variants are sibling keys (CLDR he): BASE_ZERO only when it
## exists and n == 0, BASE_TWO only when it exists and n == 2, BASE_ONE for n == 1, else
## BASE_OTHER. `n` is also passed as the {n} placeholder unless params sets it.
static func plural(base: String, n: int, params: Dictionary = {}) -> String:
	var p := params.duplicate()
	if not p.has("n"):
		p["n"] = str(n)
	var key := base + "_OTHER"
	if n == 0 and has(base + "_ZERO"):
		key = base + "_ZERO"
	elif n == 1 and has(base + "_ONE"):
		key = base + "_ONE"
	elif n == 2 and has(base + "_TWO"):
		key = base + "_TWO"
	elif not has(key):
		key = base
	return s(key, p)


## Rule 3: gendered variants BASE_M / BASE_F (masculine is the default). g: "m" | "f".
static func gendered(base: String, g: String, params: Dictionary = {}) -> String:
	var key := base + ("_F" if g == "f" else "_M")
	return s(key if has(key) else base, params)
