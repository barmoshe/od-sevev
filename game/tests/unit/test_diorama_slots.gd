extends RefCounted
## The money sources on the stage, layout v2 ("groups in the wings", Bar 2026-10-03): for every
## leader and owned sets from the first source to every source at 25:
##   - no source's opaque box (its wander included) enters the leader's keep-out band;
##   - every source inside the stage: right of the thermometer column (Thermo.WORD_BOX, x 12-132),
##     inside the 720 design width, the paving row's feet above the stage bottom;
##   - within a row, a neighbour covers at most half of the narrower figure;
##   - every owned tier shows (copy 1) before any tier shows twice, and copies 2 / 3 show in an
##     ordinary round ("לא רואים פה כפול 2");
##   - the round's first source (the taxpayer) stands right of the leader (review R17); the wings
##     balance after it.

var runner: Object


func setup(_r: Object) -> void:
	TestFixture.use_game_content()


func teardown() -> void:
	TestFixture.use_game_content()


func _diorama() -> Diorama:
	var d := Diorama.new()
	(runner as SceneTree).root.add_child(d)
	return d


func _round(id: String) -> GameState:
	var s := GameState.fresh()
	s.leader = id
	s.leader_ver += 1
	Leaders.ensure(s)
	return s


func _owned(counts: Array) -> Dictionary:
	var out := {}
	var ids := Content.producer_ids()
	for i in ids.size():
		out[ids[i]] = int(counts[i]) if i < counts.size() else 0
	return out


## Every placed critter with its box: [critter, row, left, right].
func _boxes(d: Diorama) -> Array:
	var out: Array = []
	for c: Dictionary in d._critters:
		if not bool(c.get("placed", false)) or not d._wanted(c):
			continue
		var half := d._half_of(String(c["type"]))
		var w := Diorama.WANDER if c["wander"] or c["piece"] == "blink" else 0.0
		out.append([c, String(c["row"]), float(c["homeX"]) - half - w, float(c["homeX"]) + half + w])
	return out


func test_no_source_stands_behind_any_leader() -> void:
	var d := _diorama()
	await (runner as SceneTree).process_frame
	var sets := [[1], [14, 9, 4, 1], [33, 19, 13, 15, 1], [10, 10, 10, 10, 10, 10, 10, 10], [25, 25, 25, 25, 25, 25, 25, 25],
		[260, 210, 160, 120, 90, 60, 30, 12]]
	var thermo_right: float = Thermo.WORD_BOX.x + Thermo.WORD_BOX.y
	var bottom_p := float(Diorama.ROW_FEET["P"])
	for L0: Variant in Leaders.list():
		var id := str((L0 as Dictionary)["id"])
		_round(id)
		d.update_view(16.0)
		var bands := {}
		for row: String in ["B", "F", "P"]:
			bands[row] = Diorama.leader_band(LeaderUi.art(), row)
			var band: Vector2 = bands[row]
			runner.check(band.y - band.x >= 120.0 and band.x > thermo_right and band.y < float(L.W),
				"%s: a sane keep-out band %s on row %s" % [id, str(band), row])
		for counts: Array in sets:
			d.sync(_owned(counts), false)
			var bx := _boxes(d)
			var bad: Array = []
			for b: Array in bx:
				var c: Dictionary = b[0]
				var tag := "%s#%d@%s" % [c["type"], int(c["slot"]), b[1]]
				var band: Vector2 = bands[b[1]]
				if float(b[3]) > band.x and float(b[2]) < band.y:
					bad.append(tag + " in the band")
				if float(b[2]) < thermo_right - 0.5 or float(b[3]) > float(L.W) + 0.5:
					bad.append(tag + " off the wings")
			for i in bx.size():
				for j in range(i + 1, bx.size()):
					if bx[i][1] != bx[j][1]:
						continue
					var ov := minf(float(bx[i][3]), float(bx[j][3])) - maxf(float(bx[i][2]), float(bx[j][2]))
					var mw := minf(float(bx[i][3]) - float(bx[i][2]), float(bx[j][3]) - float(bx[j][2]))
					if ov > (1.0 - Diorama.STEP) * mw + 0.5:
						bad.append("%s#%d covers %s#%d" % [bx[i][0]["type"], int(bx[i][0]["slot"]), bx[j][0]["type"], int(bx[j][0]["slot"])])
			runner.check(bad.is_empty(), "%s %s: %s" % [id, str(counts), "clear" if bad.is_empty() else str(bad.slice(0, 4))])
			# every owned tier is on stage (copy 1), whatever else has to give
			var missing: Array = []
			var ids := Content.producer_ids()
			for t in ids.size():
				if t < counts.size() and int(counts[t]) > 0 and not bx.any(func(b: Array) -> bool: return b[0]["type"] == ids[t] and int(b[0]["slot"]) == 0):
					missing.append(ids[t])
			runner.check(missing.is_empty(), "%s %s: every owned source shows (%s)" % [id, str(counts), str(missing)])
		runner.check(bottom_p <= float(L.STAGE["y"]) + float(L.S_PREF) - 8.0, "the paving row's feet stay on the visible floor")
	d.queue_free()
	await (runner as SceneTree).process_frame


## The screenshot's round (Bennett, 33 / 19 / 13 / 15 / 1): every copy the counts earn shows.
func test_a_sources_copies_show_in_an_ordinary_round() -> void:
	var d := _diorama()
	await (runner as SceneTree).process_frame
	for id: String in ["bennett", "bibi", "golan"]:
		_round(id)
		d.update_view(16.0)
		d.sync(_owned([33, 19, 13, 15, 1]), false)
		var shown := {}
		for b: Array in _boxes(d):
			var k := String(b[0]["type"])
			shown[k] = int(shown.get(k, 0)) + 1
		# every source once, and the ×2 the counts earn for the first three (the screenshot's complaint)
		var least := {"taxpayer": 2, "hitech": 2, "vat": 2, "cigars": 1, "submarine": 1}
		var short := least.keys().filter(func(k: String) -> bool: return int(shown.get(k, 0)) < int(least[k]))
		runner.check(short.is_empty(), "%s: copies on stage %s (at least %s)" % [id, str(shown), str(least)])
		# review R17: the round's first source stands right of the leader (the right half carries it)
		var c1: Array = d._critters.filter(func(c: Dictionary) -> bool: return c["type"] == "taxpayer" and int(c["slot"]) == 0)
		runner.check(float(c1[0]["homeX"]) > float(L.MAGICIAN["feetX"]), "%s: the taxpayer stands right of the leader (x %d)" % [id, int(c1[0]["homeX"])])
	d.queue_free()
	await (runner as SceneTree).process_frame


## UX mobile-first-layout §5.4 G1 (producerReveal.fillSilhouettes): after the first reveal, the
## sources past the one priced silhouette come back as `fill`, priceless rows, in tier order.
func test_the_pane_fills_with_silhouettes() -> void:
	runner.check(Content.data()["producerReveal"].get("fillSilhouettes") == true, "the content turns the fill on")
	var s := GameState.fresh()
	# merge review M2: the first source is revealed at every run start (revealAtRunEarned 0), so the
	# pane is card 1 + the fill from the pick, whatever the purse
	runner.check(float(Content.data()["producers"][0].get("revealAtRunEarned", -1)) == 0.0, "producers[0] reveals at the run start")
	var r0 := Economy.producer_rows(s)
	runner.check(r0["revealed"] == PackedStringArray([Content.producer_ids()[0]]) and not (r0["fill"] as PackedStringArray).is_empty(),
		"a fresh run: card 1 and the fill (%s)" % str(r0))
	# the fill keys on "card 1 is shown", not only on a source revealed by money
	var c0: Dictionary = Content.data().duplicate(true)
	(c0["producers"][0] as Dictionary).erase("revealAtRunEarned")
	Content.replace(c0)
	var rn := Economy.producer_rows(s)
	runner.check((rn["revealed"] as PackedStringArray).is_empty() and (rn["fill"] as PackedStringArray).is_empty(), "no money reveal and no card 1: no fill (%s)" % str(rn))
	runner.check(not (Economy.producer_rows(s, true)["fill"] as PackedStringArray).is_empty(), "card 1 shown: the fill comes with it")
	TestFixture.use_game_content()
	s.owned["taxpayer"] = 1
	var r := Economy.producer_rows(s)
	var ids := Content.producer_ids()
	var want := PackedStringArray()
	for id in ids:
		if not (r["revealed"] as PackedStringArray).has(id) and id != str(r["silhouette"]):
			want.append(id)
	runner.check(r["revealed"] == PackedStringArray(["taxpayer"]) and str(r["silhouette"]) == ids[1], "one real row, the next one priced (%s)" % str(r))
	runner.check(r["fill"] == want and (r["fill"] as PackedStringArray).size() == ids.size() - 2, "the rest fill the pane, in tier order (%s)" % str(r["fill"]))
	var c: Dictionary = Content.data().duplicate(true)
	c["producerReveal"]["fillSilhouettes"] = false
	Content.replace(c)
	runner.check((Economy.producer_rows(s)["fill"] as PackedStringArray).is_empty(), "off: today's single silhouette")


## Bar 2026-10-03 (a phone screenshot): Bennett's round drew Bibi's cigar friend on stage while the
## shop card showed Bennett's donor. The critters are built at boot, before the pick, so the stage
## re-skins tiers 4-8 when the round's leader changes (Diorama.update_view → _repick_density).
func test_the_stage_reskins_the_sources_when_the_leader_changes() -> void:
	var tree := runner as SceneTree
	var s := GameState.fresh()
	Leaders.ensure(s)   # the default round (Bibi's), as at boot before the picker
	var d := Diorama.new()
	tree.root.add_child(d)
	await tree.process_frame
	d.update_view(16.0)
	var cig: Array = d._critters.filter(func(c: Dictionary) -> bool: return c["type"] == "cigars")
	runner.check(not cig.is_empty() and String(cig[0]["sprite"]).begins_with("source_cigars"),
		"Bibi's round: the cigar friend (%s)" % ("none" if cig.is_empty() else str(cig[0]["sprite"])))
	s.leader = "bennett"
	s.leader_ver += 1
	Leaders.ensure(s)
	d.update_view(16.0)
	var tex: Texture2D = (cig[0]["s"] as Sprite2D).texture if not cig.is_empty() else null
	runner.check(not cig.is_empty() and String(cig[0]["sprite"]).begins_with("source_donor"),
		"Bennett's round: tier 4 draws his donor, like the card (%s)" % ("none" if cig.is_empty() else str(cig[0]["sprite"])))
	runner.check(tex != null, "the critter has a texture after the re-skin")
	s.leader = "bibi"
	s.leader_ver += 1
	Leaders.ensure(s)
	d.update_view(16.0)
	runner.check(String(cig[0]["sprite"]).begins_with("source_cigars"), "back to Bibi: the cigar friend again")
	d.queue_free()
	await tree.process_frame
