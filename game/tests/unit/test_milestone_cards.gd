extends RefCounted
## Milestones on the source cards (Bar 2026-10-02, shop.gd MS_*): the progress track under line 2
## filled from the right, the "12/25 ← ×2" label clear of the name, the "×4" chip after the rate,
## the crossing's gold pulse (one soft fade under reduced motion), and the all-sources goal on the
## buy-mode row with one segment per source. On the real scene, its own loop stopped.

var runner: Object
var tree: SceneTree
var dir := ""
var m: Node


func setup(r: Object) -> void:
	TestFixture.use_game_content()
	tree = r as SceneTree
	dir = "user://test_milestone_cards_%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(dir)


func teardown() -> void:
	if m and is_instance_valid(m):
		m.set_process(false)
		if m.get_parent():
			m.get_parent().remove_child(m)
		m.queue_free()
	var d := DirAccess.open(dir)
	if d:
		for f in d.get_files():
			d.remove(f)
	DirAccess.remove_absolute(dir)


func _boot() -> void:
	m = load("res://scenes/main.tscn").instantiate()
	m.store = SaveStore.new(dir)
	tree.root.add_child(m)
	for i in 3:
		await tree.process_frame
	m.set_process(false)   # the test drives the shop's frames itself
	m.shop.ftue_single = false
	m.shop.reduced_motion = false


func _refresh(dt := 16.0) -> void:
	var s: GameState = m.state
	m.shop.refresh(s, dt, false, Economy.derive(s))


func _row(id: String) -> Dictionary:
	_refresh()
	var k: int = m.shop.row_index_of(m.state, "producer", id)
	return (m.shop._rows["producers"] as Array)[k] if k >= 0 else {}


func _box_left() -> float:
	return float(L.ROW["nameRight"]) - float(L.ROW["nameW"]) - (L.dx - m.shop._pill_g)


func _label_text(owned: int, nxt: int, form: String) -> String:
	return Strings.s(form, {"owned": str(owned), "next": str(nxt), "mult": "2"})


func test_the_models_read_the_content() -> void:
	runner.check(Shop.milestone_model(0).is_empty(), "nothing before the first one is owned")
	var a := Shop.milestone_model(12)
	runner.check(int(a["next"]) == 25 and is_equal_approx(float(a["mult"]), 1.0) and is_equal_approx(float(a["nextMult"]), 2.0), "12 owned: next 25 (×2), ×1 so far (%s)" % str(a))
	var b := Shop.milestone_model(60)
	runner.check(int(b["next"]) == 100 and is_equal_approx(float(b["mult"]), 4.0), "60 owned: next 100, ×4 so far (%s)" % str(b))
	var c := Shop.milestone_model(300)
	runner.check(int(c["next"]) == -1 and is_equal_approx(float(c["mult"]), 32.0), "300 owned: past the last, ×32 (%s)" % str(c))
	runner.check(Shop.ms_mult_text(2.0) == "2" and Shop.ms_mult_text(1.25) == "1.25" and Shop.ms_mult_text(1.5) == "1.5", "multipliers without trailing zeros")


func test_a_card_shows_its_progress_from_the_right() -> void:
	await _boot()
	var id: String = Content.producer_ids()[0]
	m.state.owned[id] = 12
	var v := _row(id)
	var tr: ColorRect = v["msTrack"]
	var fl: ColorRect = v["msFill"]
	runner.check(tr.visible and fl.visible, "the track and its fill show")
	runner.check(tr.position.y == Shop.MS_BAR_Y and tr.position.x == _box_left() and tr.position.x + tr.size.x == Shop.MS_BAR_RIGHT,
		"the track spans the text box's left edge to 8 px clear of the owned chip (%s)" % str(Rect2(tr.position, tr.size)))
	runner.check(is_equal_approx(fl.position.x + fl.size.x, tr.position.x + tr.size.x) and absf(fl.size.x - tr.size.x * 12.0 / 25.0) <= 4.0,
		"the fill grows from the right: 12/25 of the track (w %d of %d)" % [int(fl.size.x), int(tr.size.x)])
	var lab: PxText = v["msLabel"]
	var nm: PxText = v["name"]
	runner.check(lab.visible and (lab.text == _label_text(12, 25, "CARD_MS_NEXT") or lab.text == _label_text(12, 25, "CARD_MS_SHORT")), "the label reads 12/25 (%s)" % lab.text)
	runner.check(lab.position.x + float(lab.width()) + Shop.MS_GAP <= nm.position.x - float(nm.width()) + 0.5, "the label clears the name by 16")
	runner.check(not (v["msTag"] as PxText).visible, "no chip at ×1")
	runner.check(Bidi.strip_controls(Strings.s("CARD_MS_NEXT", {"owned": "12", "next": "25", "mult": "2"})) == "12/25 ← ×2", "the label's logical order: count, arrow, reward")


func test_every_name_keeps_its_room() -> void:
	await _boot()
	for pid: String in Content.producer_ids():
		m.state.owned[pid] = 37
	_refresh()
	var shown := 0
	for pid: String in Content.producer_ids():
		var v := _row(pid)
		if v.is_empty():
			continue
		var lab: PxText = v["msLabel"]
		var nm: PxText = v["name"]
		runner.check((v["msTrack"] as ColorRect).visible, "%s: the bar always shows" % pid)
		if lab.visible:
			shown += 1
			runner.check(lab.position.x >= _box_left() and lab.position.x + float(lab.width()) + Shop.MS_GAP <= nm.position.x - float(nm.width()) + 0.5,
				"%s: the label (%s) stays in the box and 16 clear of the name" % [pid, lab.text])
	runner.check(shown >= 4, "most cards carry a label (%d)" % shown)


func test_the_chip_shows_the_multiplier_after_the_rate() -> void:
	await _boot()
	var id: String = Content.producer_ids()[0]
	m.state.owned[id] = 60
	var v := _row(id)
	var tag: PxText = v["msTag"]
	var bg: ColorRect = v["msTagBg"]
	var l2: PxText = v["line2"]
	runner.check(tag.visible and bg.visible and tag.text == Strings.s("CARD_MS_MULT", {"mult": "4"}), "60 owned: the gold ×4 chip (%s)" % tag.text)
	runner.check(bg.position.x + bg.size.x <= l2.position.x - float(l2.width()) - 12.0 + 0.5 and bg.position.x >= _box_left(), "the chip sits after the rate, 12 clear, inside the box")
	runner.check(bg.position.y + bg.size.y <= Shop.MS_BAR_Y, "the chip ends above the bar")
	var lab: PxText = v["msLabel"]
	runner.check(not lab.visible or lab.text.contains("60") and lab.text.contains("100"), "the label moves on to 60/100 (%s)" % lab.text)


func test_past_the_last_milestone_only_the_chip_stays() -> void:
	await _boot()
	var id: String = Content.producer_ids()[0]
	m.state.owned[id] = 300
	var v := _row(id)
	runner.check(not (v["msTrack"] as ColorRect).visible and not (v["msLabel"] as PxText).visible, "no goal left: no bar, no label")
	var tag: PxText = v["msTag"]
	var bg: ColorRect = v["msTagBg"]
	runner.check(tag.visible and tag.text == Strings.s("CARD_MS_MULT", {"mult": "32"}), "the ×32 chip stays (rate %s)" % (v["line2"] as PxText).text)
	var l2: PxText = v["line2"]
	var nm: PxText = v["name"]
	var on_l2 := bg.position.y >= float(L.ROW["line2Y"]) - 4.0
	var clear := (bg.position.x + bg.size.x <= l2.position.x - float(l2.width()) - 12.0 + 0.5) if on_l2 else (bg.position.x + bg.size.x + Shop.MS_GAP <= nm.position.x - float(nm.width()) + 0.5)
	runner.check(bg.position.x >= _box_left() and clear, "after the rate, or in the free name-row slot, clear of the text (%s)" % str(Rect2(bg.position, bg.size)))


func test_a_crossing_pulses_gold_twice_and_slams_the_chip() -> void:
	await _boot()
	var id: String = Content.producer_ids()[0]
	m.state.owned[id] = 24
	var v := _row(id)
	runner.check(not m.shop.ms_celebrating(v), "24: nothing yet")
	m.state.owned[id] = 25
	_refresh(0.0)
	runner.check(m.shop.ms_celebrating(v), "25: the crossing starts")
	runner.check((v["msFill"] as ColorRect).size.x == (v["msTrack"] as ColorRect).size.x, "the bar shows the goal reached, full")
	_refresh(1.0)
	var mf: ColorRect = v["msFlash"]
	runner.check(mf.color.a > 0.3 and (v["msTag"] as PxText).px == 6, "f0: the gold pulse is on, the ×2 chip at ×6 (a %.2f, px %d)" % [mf.color.a, (v["msTag"] as PxText).px])
	var seq: Array = []
	for i in 60:
		_refresh(16.0)
		seq.append(snappedf(mf.color.a, 0.01))
	runner.check(not m.shop.ms_celebrating(v) and mf.color.a == 0.0 and (v["msTag"] as PxText).px == L.TEXT, "done by 0.8 s: no gold, the chip at rest")
	var flips := 0
	for i in range(1, seq.size()):
		if (float(seq[i]) > 0.0) != (float(seq[i - 1]) > 0.0):
			flips += 1
	runner.check(flips <= 3, "two pulses, not a strobe (%d on/off flips)" % flips)
	var fl: ColorRect = v["msFill"]
	runner.check(absf(fl.size.x - (v["msTrack"] as ColorRect).size.x * 0.5) <= 4.0, "then the bar shows 25/50")


func test_reduced_motion_is_one_soft_fade() -> void:
	await _boot()
	m.shop.reduced_motion = true
	var id: String = Content.producer_ids()[0]
	m.state.owned[id] = 49
	var v := _row(id)
	m.state.owned[id] = 50
	_refresh(1.0)
	var mf: ColorRect = v["msFlash"]
	runner.check(m.shop.ms_celebrating(v) and mf.color.a > 0.0 and mf.color.a <= 0.4 and (v["msTag"] as PxText).px == L.TEXT, "one soft gold, no slam")
	var last := mf.color.a
	var mono := true
	for i in 30:
		_refresh(16.0)
		mono = mono and mf.color.a <= last + 1e-6
		last = mf.color.a
	runner.check(mono and not m.shop.ms_celebrating(v) and mf.color.a == 0.0, "it only fades, gone by 0.4 s")
	runner.check(absf((v["msFill"] as ColorRect).size.x - (v["msTrack"] as ColorRect).size.x * 0.5) <= 4.0, "no full-bar beat: straight to 50/100")


func test_a_new_model_learns_without_celebrating() -> void:
	await _boot()
	var id: String = Content.producer_ids()[0]
	m.state.owned[id] = 120
	m.shop.reset_run()
	var v := _row(id)
	runner.check(not m.shop.ms_celebrating(v), "a load / a new round / a shifted row shows ×8 without a party")


func test_the_head_row_carries_the_all_sources_goal() -> void:
	await _boot()
	var ids := Content.producer_ids()
	for pid: String in ids:
		m.state.owned[pid] = 12
	m.state.owned[ids[ids.size() - 1]] = 5
	m.state.ui["buyModeRevealed"] = true
	_refresh()
	var head: Dictionary = (m.shop._rows["producers"] as Array)[0]
	runner.check(str(head["model"]["kind"]) == "buymode", "the buy-mode row heads the list")
	var l2: PxText = head["line2"]
	runner.check(l2.text == Strings.s("SHOP_ALL_MS", {"n": "10", "gmult": "1.25"}), "line 2: every source at 10 → ×1.25 (%s)" % l2.text)
	runner.check(l2.width() <= int(L.ROW["line2WideW"]), "it fits the wide line 2 (%d)" % l2.width())
	var segs: Array = head["msSegs"]
	var vis := segs.filter(func(p: Array) -> bool: return (p[0] as ColorRect).visible)
	runner.check(vis.size() == ids.size(), "one segment per source (%d)" % vis.size())
	if vis.size() == ids.size():
		var first: ColorRect = vis[0][1]
		var last: ColorRect = vis[ids.size() - 1][1]
		runner.check(first.position.x > last.position.x, "the first source's segment is the rightmost (RTL)")
		runner.check(is_equal_approx(first.size.x, (vis[0][0] as ColorRect).size.x) and absf(last.size.x - (vis[ids.size() - 1][0] as ColorRect).size.x * 0.5) <= 4.0,
			"a source at 12 fills its segment, the one at 5 half of it")
	m.state.owned[ids[ids.size() - 1]] = 10
	_refresh(0.0)
	runner.check(m.shop.ms_celebrating(head), "the last source reaching 10 lights the head row")
	_refresh(1.0)
	runner.check(l2.text == Strings.s("SHOP_ALL_MS", {"n": "25", "gmult": "1.25"}), "then the next goal (%s)" % l2.text)
