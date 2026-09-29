extends RefCounted
## od-sevev politics test content (game-developer sim). Layers the placeholder politics sections
## (tests/fixtures/politics.json, the data contract's worked instance) over a base content file, so
## the sim tests pin their own rules while design/content.json is tuned. "@N" in the fixture means
## "the Nth producer of the base" and is resolved here.
## Use: const PF := preload("res://tests/politics_fixture.gd"); PF.install(); ... PF.restore()

const POLITICS := "res://tests/fixtures/politics.json"
const SECTIONS := ["flags", "coalition", "partners", "court", "eventsConfig", "events", "calendar"]


## base: a content path. only_missing: keep sections the base already has (the balance bench uses
## the live content when it has them). with_outcomes: add the aide / laundry Suitcase outcomes.
static func install(base: String = TestFixture.FORK_CONTENT, only_missing: bool = false, with_outcomes: bool = true) -> void:
	Content.replace(build(base, only_missing, with_outcomes))


static func build(base: String = TestFixture.FORK_CONTENT, only_missing: bool = false, with_outcomes: bool = true) -> Dictionary:
	var c: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(base))
	var pol: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(POLITICS))
	var ids: Array = (c["producers"] as Array).map(func(p: Dictionary) -> String: return p["id"])
	pol = _resolve(pol, ids)
	for k in SECTIONS:
		if only_missing and c.has(k):
			continue
		c[k] = pol[k]
	if with_outcomes:
		var have := {}
		for o: Dictionary in c["golden"]["outcomes"]:
			have[o["id"]] = true
		for o: Dictionary in pol["_goldenOutcomesAdd"]:
			if not have.has(o["id"]):
				(c["golden"]["outcomes"] as Array).append(o)
	return c


static func restore() -> void:
	TestFixture.use_game_content()


## A copy of `v` with every "@N" string (in keys and values) replaced by the Nth producer id.
static func _resolve(v: Variant, ids: Array) -> Variant:
	if v is Dictionary:
		var out := {}
		for k: Variant in v:
			out[_resolve(k, ids)] = _resolve(v[k], ids)
		return out
	if v is Array:
		return (v as Array).map(func(x: Variant) -> Variant: return _resolve(x, ids))
	if v is String and (v as String).begins_with("@") and (v as String).substr(1).is_valid_int():
		var n := (v as String).substr(1).to_int()
		return ids[n - 1] if n >= 1 and n <= ids.size() else v
	return v


const TUNING := "res://tests/fixtures/tuning.json"


## The balance bench's content: the live design content with the sim's tuning laid over it
## (tests/fixtures/tuning.json). Returns the drift: every tuned field the live content doesn't
## have yet ("partners.deri.unlock: live {...} -> tuned {...}"), for the Designer to mirror.
static func install_bench() -> PackedStringArray:
	var c: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Content.PATH))
	var drift := PackedStringArray()
	if not c.has("partners") or not c.has("coalition"):
		Content.replace(c)
		return drift
	var tu: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(TUNING))
	for k: Variant in tu["coalition"]:
		if c["coalition"].get(k) != tu["coalition"][k] and not (c["coalition"].get(k) is float and is_equal_approx(float(c["coalition"].get(k)), float(tu["coalition"][k]))):
			drift.append("coalition.%s: live %s -> tuned %s" % [k, c["coalition"].get(k), tu["coalition"][k]])
			c["coalition"][k] = tu["coalition"][k]
	for p: Dictionary in c["partners"]:
		if not tu["unlocks"].has(p["id"]):
			continue
		var want: Dictionary = tu["unlocks"][p["id"]]
		if JSON.stringify(p.get("unlock", {}), "", true) != JSON.stringify(want, "", true):
			drift.append("partners.%s.unlock: live %s -> tuned %s" % [p["id"], JSON.stringify(p.get("unlock", {})), JSON.stringify(want)])
			p["unlock"] = want
	Content.replace(c)
	return drift
