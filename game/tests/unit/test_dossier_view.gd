extends RefCounted
## T4 "תיקים" (ui/views/view_dossier.gd, ux/rtl-map.md §6.3) and the O15 pardon desk: the stat rows
## are the sim's own counters, slot 4 appears at K2 and opens the tall tab, the thermometer opens
## it too, T3 and T4 are one layer, and the pardon desk files through Investigation.request_pardon
## with the stamp cue on the impact. The real scene boots on the game content with a throwaway
## save folder; input goes through the same _unhandled_input boundary a phone uses.

var runner: Object
var tree: SceneTree
var dir := ""
var m: Node
var heard: Array = []


func setup(r: Object) -> void:
	TestFixture.use_game_content()
	tree = r as SceneTree
	dir = "user://test_dossier_%d" % Time.get_ticks_usec()
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
	m.commit_pick("bibi")   # LEADER_PICK (leader select): Bibi's round, the shipped game
	_touch(_stage_pt(L.magician_hit().get_center()))   # title → main (tap 1)
	m.audio_sent.connect(func(n: String, a: Variant) -> void: heard.append([n, a]))


func _touch(p: Vector2, idx: int = 0) -> void:
	for pressed in [true, false]:
		var e := InputEventScreenTouch.new()
		e.index = idx
		e.position = p
		e.pressed = pressed
		m._unhandled_input(e)


func _stage_pt(p: Vector2) -> Vector2:
	return p + Vector2(m._sx, m._stage_y)


func _dossier_pt(c: Vector2) -> Vector2:
	var dv: DossierView = m.dossier
	return dv.content_to_tall(c) + dv.position + Vector2(m._ox, m._lower_y)


## The case is open: the thermometer revealed (K1) and some suspicion. One source owned, so the
## panel and its tab bar are on screen.
func _open_case(susp: float = 10.0) -> void:
	m.state.owned[Content.producer_ids()[0]] = 1
	m.state.investigation["revealed"] = true
	m.state.investigation["suspicion"] = susp


func _open_now() -> void:
	var dv: DossierView = m.dossier
	dv.open()
	dv._open_ms -= 1000.0
	dv._end_anim(true)
	await tree.process_frame
	await tree.process_frame


func _heard(name: String) -> Array:
	return heard.filter(func(h: Array) -> bool: return h[0] == name)


# ------------------------------------------------------------------ the model (pure)

func test_rows_are_the_sims_counters() -> void:
	var s := GameState.fresh()
	s.evolutions = 2
	s.investigation["courtDays"] = 3
	s.investigation["postponementsLifetime"] = 4
	s.golden_caught_lifetime = 5
	s.stats["goldenMissed"] = 7.0
	s.all_time_bananas = 1234.0
	s.thumbs_owned = 12
	var d := Economy.derive(s)
	var rows := DossierView.rows(s, d)
	var keys: Array = rows.map(func(r: Dictionary) -> String: return r["key"])
	runner.check(keys == ["DOS_ROUNDS", "DOS_COURT_DAYS", "DOS_POSTPONES", "DOS_TOTAL", "DOS_CAUGHT", "DOS_ARRIVED", "DOS_INCOME", "DOS_BASE", "DOS_SUSP_FLOOR"],
		"the dossier lists the rounds, court days, postponements, total, caught, arrived, base and the carried floor (%s)" % str(keys))
	var by := {}
	for r: Dictionary in rows:
		by[r["key"]] = r["text"]
	runner.check(by["DOS_ROUNDS"] == Strings.s("DOS_ROUNDS", {"n": "2"}), "rounds = evolutions (%s)" % by["DOS_ROUNDS"])
	runner.check(by["DOS_COURT_DAYS"] == Strings.s("DOS_COURT_DAYS", {"n": "3"}), "court days = investigation.courtDays")
	runner.check(by["DOS_POSTPONES"] == Strings.s("DOS_POSTPONES", {"n": "4"}), "postponements are lifetime, not this round's")
	runner.check(by["DOS_CAUGHT"] == Strings.s("DOS_CAUGHT", {"n": "5"}), "caught suitcases")
	runner.check(by["DOS_ARRIVED"] == Strings.s("DOS_ARRIVED", {"n": "7"}), "the punchline row: the suitcases that 'arrived' are the missed ones")
	runner.check(by["DOS_TOTAL"] == Strings.s("DOS_TOTAL", {"x": Fmt.amount(1234.0)}), "the lifetime total through the formatter")
	runner.check(by["DOS_SUSP_FLOOR"] == Strings.s("DOS_SUSP_FLOOR", {"pct": str(int(Investigation.floor_pct(s)))}), "the floor row shows the round's carried suspicion")
	s.evolutions = 0
	var keys0: Array = DossierView.rows(s, d).map(func(r: Dictionary) -> String: return r["key"])
	runner.check(not keys0.has("DOS_SUSP_FLOOR"), "no floor row before the first election (nothing carried over)")


func test_trophies_draw_the_kit_art() -> void:
	var a := {"id": "x", "icon": "icon_folder"}
	runner.check(DossierView.trophy_art(a, true) == ["trophy_plate_earned", "trophy_folder"], "earned: the gold plate + the icon (%s)" % str(DossierView.trophy_art(a, true)))
	runner.check(DossierView.trophy_art(a, false) == ["trophy_plate_locked", "trophy_folder_locked"], "locked: the grey plate + the slate icon")
	a["secret"] = true
	runner.check(DossierView.trophy_art(a, false) == ["trophy_plate_secret", ""], "secret until earned: the '???' plate alone")
	for t: Dictionary in Meta.achievements():
		var art := DossierView.trophy_art(t, true)
		runner.check(art[1] == "" or Art.has_sprite(art[1]), "every content trophy icon resolves to art (%s)" % str(t.get("icon", "")))


# ------------------------------------------------------------------ the real scene

func test_slot_4_appears_at_k2_and_opens_the_tab() -> void:
	await _boot()
	var dv: DossierView = m.dossier
	await tree.process_frame
	runner.check(not dv.tab_revealed() and not m.shop._slot_shown(3), "no dossier slot before the case opens")
	_open_case()
	await tree.process_frame
	runner.check(not dv.tab_revealed(), "K2 waits 5 s after the case opens (one prompt at a time)")
	m.toasts._queue.clear()
	dv.update_view(DossierView.K2_DELAY_MS + 10.0, m.state, m.d, {"main": true})
	runner.check(dv.tab_revealed(), "then the tab is revealed")
	runner.check(m.toasts._queue.has(Strings.s("TOAST_DOSSIER")), "with the toast 'נפתח לך תיק.'")
	await tree.process_frame
	# review R4 (ux/ftue.md C1): the tab bar appears only with C1; slot 4 fills it once it is there
	runner.check(not m.shop._slot_shown(3), "slot 4 waits for the tab bar (C1)")
	for id: String in Content.producer_ids().slice(0, 3):
		m.state.owned[id] = maxi(1, m.state.owned_of(id))
	await tree.process_frame
	runner.check(m.shop._slot_shown(3), "slot 4 shows")
	m.shop.switch_slot(4)
	runner.check(dv.is_open() and m.shop.tall == "dossier", "slot 4 opens T4 and shows as the active tab")
	runner.check(not m.stage_unobstructed(), "T4 covers the stage: no Suitcase spawns")
	dv._end_anim(true)
	await tree.process_frame
	var drawn := dv.drawn_rows()
	var want := DossierView.rows(m.state, m.d)
	runner.check(drawn.size() == want.size() and not drawn.is_empty(), "every model row is drawn (%d of %d)" % [drawn.size(), want.size()])
	var same := true
	for i in mini(drawn.size(), want.size()):
		same = same and drawn[i]["text"] == want[i]["text"]
	runner.check(same, "each drawn row is the model's text")
	var kinds: Array = dv.hits().map(func(h: Dictionary) -> String: return h["kind"])
	runner.check(kinds.has("pardon") and kinds.has("story"), "the pardon desk and the story archive are buttons (%s)" % str(kinds))
	var taps: int = m.state.taps_lifetime
	_touch(_stage_pt(L.magician_hit().get_center()))
	runner.check(m.state.taps_lifetime == taps, "the Magician takes no taps under T4")
	# the › chevron closes it
	dv._open_ms -= 1000.0
	_touch(Vector2(676, 52) + dv.position + Vector2(m._ox, m._lower_y))
	runner.check(not dv.is_open() and m.shop.tall == "", "the chevron closes T4")
	# T3 and T4 are one layer
	dv.open()
	m.chat.open()
	runner.check(m.chat.is_open() and not dv.is_open() and m.shop.tall == "coalition", "opening T3 closes T4")
	dv.open()
	runner.check(dv.is_open() and not m.chat.is_open() and m.shop.tall == "dossier", "and opening T4 closes T3")
	var e := InputEventKey.new()
	e.keycode = KEY_ESCAPE
	e.pressed = true
	m._unhandled_input(e)
	runner.check(not dv.is_open() and not m.overlays.is_open(), "Esc closes T4 (not the settings)")


func test_the_thermometer_opens_the_dossier() -> void:
	await _boot()
	_open_case(30.0)
	for i in 3:
		await tree.process_frame
	runner.check(m.thermo.is_shown(), "the thermometer shows once revealed (K1)")
	_touch(_stage_pt(m.thermo.hit_rect().get_center()))   # hit_rect is in the stage node's space
	runner.check(m.dossier.is_open(), "a tap on the thermometer opens T4 (rtl-map §4)")
	runner.check(m.dossier.tab_revealed(), "and opens the case at once, before K2's delay")


func test_the_pardon_desk_files_through_the_sim() -> void:
	await _boot()
	_open_case()
	await _open_now()
	var dv: DossierView = m.dossier
	var hit: Dictionary = {}
	for h: Dictionary in dv.hits():
		if h["kind"] == "pardon":
			hit = h
	runner.check(not hit.is_empty(), "T4 has the pardon row")
	if hit.is_empty():
		return
	_touch(_dossier_pt((hit["rect"] as Rect2).get_center()))
	var desk := m.overlays.top() as DossierView.PardonDesk
	runner.check(desk != null, "the pardon row opens the desk (O15)")
	if desk == null:
		return
	var hz: Array = desk.panel.get_children().filter(func(n: Node) -> bool: return n.get_meta("role", "") == "herzog")
	runner.check(hz.size() == 1 and (hz[0] as Sprite2D).position.x + 96.0 <= desk.panel_rect.end.x,
		"Herzog's avatar sits inside the desk's title band")
	heard.clear()
	var k := desk.submit()
	runner.check(int(m.state.investigation["pardons"]) == 1 and float(m.state.stats.get("pardonRequests", 0.0)) == 1.0,
		"the request is Investigation.request_pardon's (pardons %s)" % str(m.state.investigation["pardons"]))
	runner.check(k >= 1 and k <= int(Investigation.cfg()["pardon"]["stamps"]), "a stamp line 1..%d (%d)" % [int(Investigation.cfg()["pardon"]["stamps"]), k])
	runner.check(desk._stamp_text.text == DossierView.PardonDesk.stamp_line(k) or (k == 1 and desk._stamp_img.visible),
		"the stamp shows that line (the baked stamp for line 1)")
	runner.check(_heard("stamp").is_empty(), "no stamp cue before the impact")
	desk.update_view(100.0)
	runner.check(_heard("stamp").size() == 1, "the stamp cue lands on the impact (+90 ms)")
	var k2 := desk.submit()
	runner.check(k2 != k, "never the same stamp twice in a row")
	runner.check(desk._submit.label.text == Strings.s("PARDON_AGAIN"), "the button reads 'להגיש שוב' after the first request")
