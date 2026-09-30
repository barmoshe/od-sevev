extends RefCounted
## The lower pane after the manual test pass of 2026-09-30 (HANDOFF §B/§D; ux/mobile-first-layout.md
## §5.3.1, §5.4, §5.4.1, §5.5.1): D20 the white field as a ruled margin (a flag rule on each canvas
## edge, the thumb hidden when idle), D21 the tab bar always four slots (plain plate, engine
## dividers, locked silhouettes), B9 the teasers (one hint, then wordless slips fading down), B11
## the chat thread anchored under the header with a day chip, and the reply in a named row.
## (D19, the ticker: test_ticker_idle.gd.)

var runner: Object
var tree: SceneTree
var dir := ""
var m: Node


func setup(r: Object) -> void:
	TestFixture.use_game_content()
	tree = r as SceneTree
	dir = "user://test_lower_pane_%d" % Time.get_ticks_usec()
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
	m.ftue.handoff_ms = 1.0
	m.commit_pick("bibi")
	var p: Vector2 = L.magician_hit().get_center() + Vector2(m._sx, m._stage_y)
	for pressed in [true, false]:
		var e := InputEventScreenTouch.new()
		e.position = p
		e.pressed = pressed
		m._unhandled_input(e)


func test_b9_the_teasers_fade_down_under_one_hint() -> void:
	runner.check(Shop.teaser_alpha(0) == 1.0, "the first teaser is the whole pale slip")
	var ok := true
	for j in range(1, 8):
		ok = ok and Shop.teaser_alpha(j) <= Shop.teaser_alpha(j - 1) and Shop.teaser_alpha(j) >= 0.2
	runner.check(ok and Shop.teaser_alpha(1) < 1.0, "then each fades a step, never under 0.2 (the slip still paints: no empty band, §0 rule 4)")
	runner.check(Shop.teaser_name(0) == Strings.s("ROW_TEASER_HINT") and Shop.teaser_name(1) == "" and Shop.teaser_name(5) == "", "one hint line, then wordless slips (no six identical 'מקור עלום' rows)")
	var out: Array = [{"kind": "producer", "id": Content.producer_ids()[0]}]
	Shop._append_teasers(out, null)
	var ts: Array = out.filter(func(x: Dictionary) -> bool: return x["kind"] == "teaser")
	var idx: Array = ts.map(func(x: Dictionary) -> int: return int(x["t"]))
	runner.check(ts.size() == Content.producer_ids().size() - 1 and idx == range(ts.size()), "every source still to come gets a numbered teaser (%s)" % str(idx))


func test_d20_d21_the_ruled_pane_and_the_four_slot_bar() -> void:
	await _boot()
	var sh: Shop = m.shop
	runner.check(sh._rules.size() == 2, "two rules")
	var lr: ColorRect = sh._rules[0]
	var rr: ColorRect = sh._rules[1]
	runner.check(lr.position.x == 0.0 and rr.position.x == L.cw - 4.0 and lr.size.x == 4.0 and lr.color == Color("#0038b8"), "a 1-art flag rule on each canvas edge (x 0 and cw − 4)")
	runner.check(is_equal_approx(lr.position.y, sh.list_rect.position.y) and is_equal_approx(lr.size.y, sh.list_rect.size.y), "the rules run the pane's height")
	runner.check(sh._thumb.position.x + sh._thumb.size.x <= float(L.SHOP["listX"]), "the thumb rides the left rule, clear of the cards")
	# the tab bar: C1 with only the sources and the coalition revealed (Bar's iPhone)
	m.set_process(false)   # hold the controller: it re-applies the reveals every frame
	sh.set_shop_visible(true)
	sh.set_tabs_revealed(true, [true, false, true, false])
	runner.check(sh._tabbar.region_rect == Shop.TABBAR_PLAIN, "the plate is the kit's divider-free column")
	runner.check(sh._dividers.size() == 3 and sh._dividers.all(func(d: ColorRect) -> bool: return d.visible), "three engine dividers, one per slot boundary")
	var xs: Array = sh._dividers.map(func(d: ColorRect) -> float: return d.position.x + 2.0)
	runner.check(xs == [L.cw - L.tab_w(), L.cw - 2.0 * L.tab_w(), L.cw - 3.0 * L.tab_w()], "on the boundaries (%s)" % str(xs))
	runner.check(not sh.slot_locked(0) and sh.slot_locked(1) and not sh.slot_locked(2) and sh.slot_locked(3), "the unrevealed slots are locked")
	var d1: Dictionary = sh._slots[1]
	runner.check((d1["lockedIcon"] as Sprite2D).visible and (d1["lock"] as Sprite2D).visible and not (d1["icon"] as Sprite2D).visible and not (d1["label"] as PxText).visible,
		"a locked slot draws its silhouette and the padlock, no live icon and no label (its name stays a reveal)")
	var d0: Dictionary = sh._slots[0]
	runner.check(not (d0["lockedIcon"] as Sprite2D).visible and (d0["icon"] as Sprite2D).visible, "a revealed slot draws its live icon")
	runner.check(sh.tabs_down(L.tab_rect(2).get_center()) and sh._tab_pressed == -1, "a locked slot swallows the press but is not a target")
	sh.set_tabs_revealed(false, [true, false, false, false])
	runner.check(not sh.slot_locked(1) and not (sh._dividers[0] as ColorRect).visible, "before C1 no bar, no locks, no dividers")


func test_b11_the_thread_starts_under_the_header() -> void:
	await _boot()
	var ids := Content.producer_ids()
	for i in 3:
		m.state.owned[ids[i]] = 1
	Economy.add_bananas(m.state, 500.0)
	m.d = Economy.derive(m.state)
	Coalition.open_group(m.state, m.d, func() -> float: return 0.0)
	Coalition._post(m.state, {"type": "reply", "n": 1, "state": "", "partner": ""}, [])
	var chat: ChatView = m.chat
	chat.open()
	chat._open_ms -= 1000.0
	chat._end_anim(true)
	chat.reveal_all()
	await tree.process_frame
	await tree.process_frame
	runner.check(chat._content_h < chat.thread_h(), "a short thread (%.0f of %.0f)" % [chat._content_h, chat.thread_h()])
	runner.check(chat._content.position.y == 0.0, "it starts under the header, not at the bottom (content y %.0f)" % chat._content.position.y)
	var first: Dictionary = chat.rows()[0]
	runner.check(float(first["y"]) > 16.0, "the day chip comes first (the first row at y %.0f)" % float(first["y"]))
	var chip_text := false
	for n in chat._content.get_child(0).get_children():
		if n is PxText and (n as PxText).text == Strings.s("CHAT_TODAY"):
			chip_text = true
	runner.check(chip_text, "the day chip reads CHAT_TODAY")
	var out_rows: Array = chat.rows().filter(func(r: Dictionary) -> bool: return r["kind"] == "out")
	runner.check(not out_rows.is_empty(), "the reply is in the thread")
	if out_rows.is_empty():
		return
	var o: Dictionary = out_rows[0]
	var named := false
	for n in (o["root"] as Node2D).get_children():
		if n is PxText and (n as PxText).text == LeaderUi.short():
			named = true
	runner.check(named and (o["bubbleRect"] as Rect2).position.y == ChatView.OUT_NAME_H, "the reply's row is headed by the leader's name (%s), the bubble under it" % LeaderUi.short())


## Merge review M3 (D57): from the fourth teaser (j ≥ 3, on the 0.2 floor) only the silhouette plate
## draws, at 0.2: no slip fill and no slip outline on the ruled white field.
func test_m3_floor_teasers_draw_only_the_silhouette_plate() -> void:
	runner.check(Shop.teaser_slip(0) and Shop.teaser_slip(1) and Shop.teaser_slip(2), "the hint and the two fading slips keep their slip")
	runner.check(not Shop.teaser_slip(3) and not Shop.teaser_slip(6), "j ≥ 3: no slip")
	runner.check(Shop.teaser_alpha(3) == 0.2 and Shop.teaser_alpha(7) == 0.2, "the plate alone at 0.2")
	await _boot()
	for i in 4:
		await tree.process_frame
	var slips := 0
	var plates := 0
	var bad := 0
	var why: Array = []
	# the current models (a view's own `model` is re-read only when its kind:id key changes)
	var models: Array = m.shop._models(m.state, "producers")
	var views: Array = m.shop._rows["producers"]
	for k in mini(views.size(), models.size()):
		var v: Dictionary = views[k]
		var mk: Dictionary = models[k]
		if str(mk.get("kind", "")) != "teaser" or not (v["c"] as Node2D).visible:
			continue
		var j := int(mk.get("t", 0))
		var panel_on: bool = (v["panel"] as NinePatchRect).visible
		var plate_on: bool = (v["plate"] as NinePatchRect).visible
		if j >= 3:
			plates += 1
			if panel_on or not plate_on or not is_equal_approx((v["c"] as Node2D).modulate.a, 0.2):
				bad += 1
				why.append("j%d panel %s plate %s a %.2f" % [j, panel_on, plate_on, (v["c"] as Node2D).modulate.a])
		else:
			slips += 1
			if not panel_on:
				bad += 1
				why.append("j%d no slip" % j)
	runner.check(slips >= 1 and plates >= 1, "the pane draws both kinds (%d slips, %d plates)" % [slips, plates])
	runner.check(bad == 0, "every floor teaser is the plate alone at 0.2, every earlier one keeps its slip (%d wrong: %s)" % [bad, str(why)])
