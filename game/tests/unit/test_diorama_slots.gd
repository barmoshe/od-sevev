extends RefCounted
## The money sources on the stage (ux/review-2026-09-29.md R17; content producers[].slot → the
## diorama's L.DIORAMA rows and xs). Geometry only, from the real constants and the TA's sprite
## sizes (sprites.json sources: frameW / density, pivot bottom-centre at slot x + 32):
##   - no critter under the thermometer column (Thermo.WORD_BOX x 12-132), wandering included;
##   - no critter above the stage top + 8 (the sky row at y 168 put 88 px of a 160-px source under
##     Row B, so no source uses it);
##   - every critter inside the 720 design width, one critter per slot;
##   - the first critter of the three shared sources (every leader's round starts with them) sits
##     right of the Magician's feet, and the taxpayer's clears his hit entirely: the right half
##     of the stage carries the early round.
## A leader's generic tier sprite (leaderSelect.sourceTiers.genericSprites) is checked in the same
## slot, since the diorama will draw it there once the picker ships (spec §10.1 ui/diorama.gd).

var runner: Object

const WANDER := 16.0   # Diorama._start_hop: a wandering critter hops within homeX ± 16


func setup(_r: Object) -> void:
	TestFixture.use_game_content()


func teardown() -> void:
	TestFixture.use_game_content()


static func _sources() -> Dictionary:
	var j: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://assets/sprites/sprites.json"))
	return (j as Dictionary).get("sources", {}) if j is Dictionary else {}


## (half-width left of the pivot, full width, height) in logical px for a sprite key.
static func _extent(sources: Dictionary, sprite: String) -> Vector3:
	for k: Variant in sources:
		var e: Dictionary = sources[k]
		if str(e.get("sprite", "")) == sprite:
			var sc := 4.0 / float(e.get("density", 1))
			var fw := float(e["frameW"])
			return Vector3(floorf(fw / 2.0) * sc, fw * sc, float(e["frameH"]) * sc)
	return Vector3.ZERO


## Every sprite a producer's slot may draw: its own and, for tiers 4-8, the leaders' generic one.
static func _sprites_of(id: String) -> Array:
	var out: Array = [str(Content.producer(id).get("sprite", ""))]
	var st: Variant = Leaders.ls().get("sourceTiers", {})
	if st is Dictionary:
		var tiers: Dictionary = (st as Dictionary).get("tiers", {})
		for t: Variant in tiers:
			if str(tiers[t]) == id:
				var g: Variant = (st as Dictionary).get("genericSprites", {}).get(t)
				if g is Dictionary:
					out.append(str((g as Dictionary).get("sprite", "")))
	return out


func test_sources_clear_the_thermometer_and_the_stage_top() -> void:
	var src := _sources()
	runner.check(not src.is_empty(), "sprites.json sources readable")
	var thermo_right: float = Thermo.WORD_BOX.x + Thermo.WORD_BOX.y
	var used := {}
	for id: String in Content.producer_ids():
		var codes: Array = Content.producer(id).get("slot", [])
		runner.check(not codes.is_empty() and codes.size() <= 3, "%s: 1-3 slot codes from content (%s)" % [id, str(codes)])
		var wander := WANDER if Content.producer(id).get("wander", false) == true else 0.0
		for code: Variant in codes:
			var c := str(code)
			runner.check(L._valid_slot(c), "%s: %s is a diorama slot" % [id, c])
			runner.check(not used.has(c), "%s: slot %s is not shared (with %s)" % [id, c, used.get(c, "")])
			used[c] = id
			var row := c.substr(0, 1)
			var cx := float(L.DIORAMA["xs"][row][int(c.substr(1))]) + 32.0
			var bottom := float(L.DIORAMA["rows"][row]) + 64.0
			for sp: String in _sprites_of(id):
				var ex := _extent(src, sp)
				if ex == Vector3.ZERO:
					continue   # a sprite the TA hasn't delivered: the diorama leaves the slot empty
				var left := cx - ex.x
				runner.check(left - wander >= thermo_right, "%s (%s) at %s: left edge %d clears the thermometer column (x ≤ %d)" % [id, sp, c, int(left - wander), int(thermo_right)])
				runner.check(left + ex.y + wander <= float(L.W), "%s (%s) at %s: right edge %d inside the 720 stage" % [id, sp, c, int(left + ex.y + wander)])
				runner.check(bottom - ex.z >= float(L.STAGE["y"]) + 8.0, "%s (%s) at %s: sprite top %d under the stage top + 8 (not clipped by Row B)" % [id, sp, c, int(bottom - ex.z)])


func test_the_early_round_fills_the_right_half() -> void:
	var src := _sources()
	var feet := float(L.MAGICIAN["feetX"])
	var hit_right := float(L.MAGICIAN["feetX"]) + float(L.MAGICIAN["hitW"]) / 2.0
	for id: String in ["taxpayer", "hitech", "vat"]:
		var c := str((Content.producer(id)["slot"] as Array)[0])
		var cx := float(L.DIORAMA["xs"][c.substr(0, 1)][int(c.substr(1))]) + 32.0
		runner.check(cx > feet, "%s's first critter (%s, x %d) stands right of the Magician (feet x %d)" % [id, c, int(cx), int(feet)])
	var t := str((Content.producer("taxpayer")["slot"] as Array)[0])
	var tx := float(L.DIORAMA["xs"][t.substr(0, 1)][int(t.substr(1))]) + 32.0
	var left := tx - _extent(src, str(Content.producer("taxpayer")["sprite"])).x - WANDER
	runner.check(left >= hit_right, "the first taxpayer (%s, wandering) clears the Magician's hit (x ≥ %d, got %d)" % [t, int(hit_right), int(left)])
