extends RefCounted
## The 2026-09-30 manual test pass, the pre-tap + HUD slice (ux/mobile-first-layout.md §3.3, §5.1.1,
## §5.8.1, §5.9; ux/ftue.md rev 5): A2 card 1 from the pick (no half-stone screen), A3 the picker's
## caption on a navy plate, A7/B10 the round's identity chip in Row A (face + name, clear of the
## leader's hit; no name toast over the stage), B12 the pre-tap undo chip in a navy bar in the free
## ticker slot. Runs on the game content, on the real scene.

var runner: Object
var tree: SceneTree
var dir := ""
var m: Node


func setup(r: Object) -> void:
	TestFixture.use_game_content()
	tree = r as SceneTree
	dir = "user://test_pretap_hud_%d" % Time.get_ticks_usec()
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


func _frames(n: int) -> void:
	for i in n:
		await tree.process_frame


func _touch(p: Vector2) -> void:
	for pressed in [true, false]:
		var e := InputEventScreenTouch.new()
		e.position = p
		e.pressed = pressed
		m._unhandled_input(e)


func _tap_leader() -> void:
	_touch(L.magician_hit().get_center() + Vector2(m._sx, m._stage_y))


## A viewport-space rect of a `_top`-local one.
func _top_rect(r: Rect2) -> Rect2:
	return Rect2(r.position + Vector2(m._ox, m._top_y), r.size)


func _leader_hit() -> Rect2:
	return Rect2(m.bb.hit_rect().position + Vector2(m._sx, m._stage_y), m.bb.hit_rect().size)


# ------------------------------------------------------------------ A2

func test_a2_card_1_is_up_from_the_pick() -> void:
	await _boot()
	m.ftue.handoff_ms = 1.0
	m.commit_pick("bengvir")
	await _frames(2)
	runner.check(m.mode == "title" and m.state.taps_lifetime == 0, "the pre-tap state")
	runner.check(Ftue.reveals(m.state)["card1"] and m.shop.visible and m._fills["shop"].visible,
		"card 1 and the pane's white field are up before tap 1 (shop %s)" % m.shop.visible)
	runner.check(m.shop.ftue_dim, "card 1 is dim (its pill at 40%%): the leader stays the one lit object")
	runner.check(not m.ticker.visible, "the ticker still waits for H1")
	# the floor is a strip: only the ticker slot shows it (the pane covers everything below)
	var strip_top: float = m._lower_y
	var pane_top: float = m._lower_y + float(L.SHOP["listY"])
	runner.check(is_equal_approx(pane_top - strip_top, float(L.TICKER_H)), "the plaza shows as one 84-px strip between the stage and the pane")
	# the fork's content keeps the tap-3 reveal
	var s := GameState.fresh()
	runner.check(Ftue.reveals(s)["card1"] == Ftue.picked(s), "without a pick, card 1 waits (tap 3 on the fork)")


# ------------------------------------------------------------------ A7 / B10

func test_a7_b10_the_identity_chip_is_in_row_a_clear_of_the_leader() -> void:
	await _boot()
	m.ftue.handoff_ms = 1.0
	m.commit_pick("smotrich")   # the widest short name (144 at ×4)
	await _frames(3)
	var tb: TopBar = m.top_bar
	runner.check(m._top.visible, "Row A is up in the pre-tap state")
	runner.check(tb.leader_shown() == "smotrich" and tb.face != null and tb.face.visible, "the face medallion is drawn")
	runner.check(tb.leader_name.text == LeaderUi.short("smotrich") and tb.name_visible(), "the short name is shown (%s)" % tb.leader_name.text)
	var idr := _top_rect(tb.identity_rect())
	runner.check(idr.has_area() and not idr.intersects(_leader_hit()), "the chip %s never touches the leader's hit %s" % [idr, _leader_hit()])
	runner.check(idr.position.y >= m._top_y and idr.end.y <= m._top_y + float(L.ROW_A_H), "the chip sits inside Row A (%s)" % idr)
	var face := _top_rect(TopBar.face_rect())
	runner.check(is_equal_approx(face.end.x, m._ox + L.cw - 20.0) and face.size == Vector2(64, 64), "the face is R-anchored, 64×64, 20 from the canvas edge (%s)" % face)
	runner.check(not tb.bank.visible, "the counter still waits for H1")
	# the name clears the gear/mute and the counter's box centre
	runner.check(idr.position.x - m._ox >= float((L.TOP["muteHit"] as Rect2).end.x), "the chip clears the mute hit")
	# no round-start name toast over the stage (the chip replaces it)
	var plate := Strings.s("LEADER_PICK_PLATE", {"short": LeaderUi.short("smotrich"), "party": LeaderUi.party("smotrich")})
	var toasts: Toasts = m.toasts
	runner.check(toasts._text.text != plate and not toasts._queue.has(plate), "the name is not a toast over the stage")


func test_b10_the_name_width_guard_at_dx_0() -> void:
	await _boot()
	m.ftue.handoff_ms = 1.0
	m.commit_pick("smotrich")
	await _frames(2)
	_tap_leader()
	await _frames(3)
	var tb: TopBar = m.top_bar
	runner.check(L.dx >= 0.0, "the canvas")
	m.state.bananas = 504.0
	await _frames(2)
	runner.check(tb.name_visible() and tb.name_fits(), "round 1: the name fits beside the counter (dx %d)" % int(L.dx))
	m.state.bananas = 8.888e15
	await _frames(12)
	var fits := tb.name_fits()
	runner.check(tb.name_visible() == fits, "a counter that reaches the name's slot hides the name (fits %s, shown %s)" % [fits, tb.name_visible()])


func test_face_sprite_is_whole_device_px() -> void:
	var art := LeaderUi.art("bengvir")
	var k6 := TopBar.face_sprite(art, 6, true)
	var k4 := TopBar.face_sprite(art, 4, true)
	var k2 := TopBar.face_sprite(art, 2, true)
	runner.check(not k6.is_empty() and Art.sprite_size(str(k6[0])).x == 96, "k 6: the 96-px d3 head (1 device px each), got %s" % str(k6))
	runner.check(not k4.is_empty() and Art.sprite_size(str(k4[0])).x == 64, "k 4: the 64-px d2 head, got %s" % str(k4))
	runner.check(not k2.is_empty() and Art.sprite_size(str(k2[0])).x == 32, "k 2: the 32-px head, got %s" % str(k2))
	for fs: Array in [k6, k4, k2]:
		runner.check(is_equal_approx(float(fs[1]) * Art.sprite_size(str(fs[0])).x, 64.0), "each draws 64 logical (%s)" % str(fs))


func test_b10_the_name_yields_to_the_cottage_after_the_round_starts() -> void:
	await _boot()
	m.ftue.handoff_ms = 1.0
	m.commit_pick("bibi")
	await _frames(2)
	m.state.all_time_bananas = 5000.0   # Q1 already reached (a later round, or a big away credit)
	await _frames(3)
	var tb: TopBar = m.top_bar
	var c: CottageCup = m.cottage
	runner.check(tb.name_visible() and not c.visible, "round start: the name holds the slot, the cup waits")
	_tap_leader()
	await _frames(20)
	runner.check(not tb.name_claims_slot() and not tb.name_visible(), "after the first tap the name yields")
	runner.check(c.visible, "and the cup takes the slot")
	runner.check(tb.face.visible, "the face stays")
	var cr := _top_rect(c.hit_rect())
	var face := _top_rect(TopBar.face_hit())
	runner.check(not cr.intersects(face) and is_equal_approx(cr.end.x, face.position.x), "the cup's hit sits just left of the face's (%s, %s)" % [cr, face])


# ------------------------------------------------------------------ B12

func test_b12_the_pretap_undo_chip_sits_in_a_navy_bar_in_the_ticker_slot() -> void:
	await _boot()
	m.ftue.handoff_ms = 1.0
	m.commit_pick("liberman")
	await _frames(2)
	runner.check(m.undo_visible() and m.undo_home() == "row", "pre-tap: the chip's home is the ticker slot (%s)" % m.undo_home())
	var rr: Rect2 = m.undo_row_rect()
	runner.check(rr.position.y >= 0.0 and rr.end.y <= float(L.TICKER_H), "inside the 84-px slot (%s)" % rr)
	runner.check(is_equal_approx(rr.get_center().x, L.cw / 2.0), "centred on the canvas")
	var band: ColorRect = m._undo_band
	runner.check(m._undo_row.visible and band.position.x <= -m._ox and band.size.x >= m._vs.x, "on a full-bleed navy bar")
	runner.check(band.color == Color("#072a7a"), "the ticker's panel colour (the ticker takes the same slot at H1)")
	var hit: Rect2 = m._undo_row_btn.hit
	runner.check(hit.size.y >= 88.0 and hit.size.x >= 408.0, "a full 88-px hit (%s)" % hit)
	# a real tap on it reopens the picker
	_touch(rr.get_center() + Vector2(m._ox, m._lower_y))
	await _frames(2)
	runner.check(m.mode == "pick" and m.picker.visible, "tapping it reopens the picker")


func test_b12_after_an_election_the_chip_stays_in_the_lane() -> void:
	var s := GameState.fresh()
	Leaders.set_salt(s, 7)
	Politics.install(s, "bennett")
	Economy.tap(s)
	s.evolutions = 1
	s.run_taps = 0
	Politics.on_election(s)
	SaveStore.new(dir).save_game(s)
	await _boot()
	m.commit_pick("liberman")
	await _frames(2)
	runner.check(m.mode == "main" and m.undo_visible() and m.undo_home() == "lane", "the ticker is live: the lane (%s)" % m.undo_home())
	runner.check(not m._undo_row.visible, "no bar over the ticker")
	runner.check(m.top_bar.name_visible() and m.top_bar.leader_shown() == "liberman", "the new round's name shows in Row A")


# ------------------------------------------------------------------ Row A input before tap 1

func test_b10_mute_and_settings_work_before_tap_1() -> void:
	await _boot()
	m.ftue.handoff_ms = 1.0
	m.commit_pick("deri")
	await _frames(2)
	var was: bool = bool(m.settings.get("sfx", true)) or bool(m.settings.get("music", true))
	_touch((L.TOP["muteHit"] as Rect2).get_center() + Vector2(m._ox, m._top_y))
	var now: bool = bool(m.settings.get("sfx", true)) or bool(m.settings.get("music", true))
	runner.check(now != was and m.mode == "title", "mute toggles in the pre-tap state")
	_touch((L.TOP["gearHit"] as Rect2).get_center() + Vector2(m._ox, m._top_y))
	await _frames(2)
	runner.check(m.overlays.is_open(), "the gear opens settings before tap 1")
	runner.check(m.state.taps_lifetime == 0, "neither counts as tap 1")


# ------------------------------------------------------------------ A3

func test_a3_the_picker_caption_sits_on_a_navy_plate() -> void:
	await _boot()
	var p: PickView = m.picker
	runner.check(m.mode == "pick" and p.visible, "the picker")
	var sr: Rect2 = p.strip_rect
	runner.check(sr.has_area() and sr.position.x <= -m._ox and sr.size.x >= m._vs.x, "the plate is full bleed (%s)" % sr)
	var t: PxText = p._strip
	var lines := clampf(float(t.line_count()), 1.0, 2.0)
	runner.check(t.position.y >= sr.position.y + 8.0 and t.position.y + 44.0 * lines <= sr.end.y,
		"the caption's lines sit inside it (%s..%s in %s)" % [t.position.y, t.position.y + 44.0 * lines, sr])
	var fg := Color("#f7f4ec")
	var bg := PickView.STRIP_PLATE
	var lum := func(c: Color) -> float:
		var f := func(v: float) -> float: return v / 12.92 if v <= 0.03928 else pow((v + 0.055) / 1.055, 2.4)
		return 0.2126 * f.call(c.r) + 0.7152 * f.call(c.g) + 0.0722 * f.call(c.b)
	var ratio: float = (float(lum.call(fg)) + 0.05) / (float(lum.call(bg)) + 0.05)
	runner.check(ratio >= 7.0, "white on the plate reads at %.1f:1 (≥ 7, AAA)" % ratio)


# ------------------------------------------------------------------ merge review M1 (D62, S18)

## Runs the toast dock `ms` of scene time with the controller's per-frame rule (D62).
func _pump_toasts(ms: float) -> void:
	var t := 0.0
	while t < ms:
		m._dock_toasts()
		m.toasts.update_view(50.0)
		t += 50.0


func _toast_rect() -> Rect2:
	return m.toasts.covered_rect()


func test_d62_the_pretap_toast_docks_in_the_lane_band_clear_of_the_leader() -> void:
	await _boot()
	m.ftue.handoff_ms = 1.0
	m.commit_pick("bengvir")
	await _frames(2)
	runner.check(m.mode == "title" and m.state.run_taps == 0, "pre-tap")
	for e: Dictionary in m._pick_seq:
		(e["fn"] as Callable).call()
	m._pick_seq.clear()
	_pump_toasts(400.0)
	var tt: Toasts = m.toasts
	var r := _toast_rect()
	runner.check(r.has_area() and tt.dock() == "lane", "Dubi's pick toast shows, in the lane band (%s, %s)" % [tt.dock(), r])
	runner.check(is_equal_approx(r.position.y, L.stage_bottom() - 136.0) and r.end.y <= L.stage_bottom(),
		"at S − 136, inside the stage (%s; stage bottom %s)" % [r, L.stage_bottom()])
	runner.check(not r.intersects(m.bb.hit_rect()), "clear of the leader's hit (%s vs %s)" % [r, m.bb.hit_rect()])
	runner.check(is_equal_approx(r.position.x, Toasts.dock_x()) and is_equal_approx(r.size.x, Toasts.dock_w()), "the dock's width (cw − 32)")
	var sh := tt.shown()
	runner.check(sh["head"] != "" and tt._head.position.y >= r.position.y and tt._preview.position.y + 44.0 <= r.end.y,
		"its two lines sit on the lane plate (%s, %s in %s)" % [tt._head.position.y, tt._preview.position.y, r])
	# the S18 sample, every 250 ms of the toast's life: never over the hit
	var bad := 0
	for i in 12:
		_pump_toasts(250.0)
		if _toast_rect().intersects(m.bb.hit_rect()):
			bad += 1
	runner.check(bad == 0, "S18: no sample over the leader's hit (%d)" % bad)
	# after the first tap the dock returns to the stage top
	_tap_leader()
	runner.check(not tt.lane_dock or m.state.run_taps > 0, "the round has started")
	_pump_toasts(4000.0)
	tt.show_toast("בדיקה")
	_pump_toasts(200.0)
	runner.check(tt.dock() == "top" and is_equal_approx(_toast_rect().position.y, Toasts.top_y()), "after tap 1 a toast docks at the stage top again (%s)" % tt.dock())


func test_d62_the_fresh_toast_waits_for_the_undo_chip_then_docks_in_the_lane() -> void:
	var s := GameState.fresh()
	Leaders.set_salt(s, 7)
	Politics.install(s, "bennett")
	Economy.tap(s)
	s.evolutions = 1
	s.run_taps = 0
	Politics.on_election(s)
	SaveStore.new(dir).save_game(s)
	await _boot()
	m.commit_pick("liberman")
	await _frames(2)
	var tt: Toasts = m.toasts
	var want := Strings.s("LEADER_PICK_FRESH", {"pct": int(roundf(float(m._pick_res.get("freshPct", 0.0))))})
	runner.check(m._pick_res.get("fresh", false) == true, "a switch: the fresh-face bonus")
	runner.check(m.undo_visible() and m.undo_home() == "lane", "the chip holds the lane")
	runner.check(m._fresh_due == want and not tt._queue.has(want) and tt._text.text != want, "the fresh toast waits while the undo chip is up")
	m._dock_toasts()
	runner.check(tt.hold, "the queue holds while the chip holds the lane")
	# the chip's 5 s run out
	m._undo_ms = 0.0
	m._update_undo_chip(16.0)
	m._dock_toasts()
	runner.check(m._fresh_due == "" and (tt._queue.has(want) or tt._text.text == want), "the chip gone: the fresh toast is queued")
	runner.check(not tt.hold, "the queue runs again")
	_pump_toasts(300.0)
	var r := _toast_rect()
	runner.check(tt._text.text == want and tt.dock() == "lane" and r.has_area(), "it shows in the lane band (%s)" % tt.dock())
	runner.check(not r.intersects(m.bb.hit_rect()), "clear of the new leader's hit (%s vs %s)" % [r, m.bb.hit_rect()])


func test_d62_an_undo_drops_the_waiting_fresh_toast() -> void:
	var s := GameState.fresh()
	Leaders.set_salt(s, 7)
	Politics.install(s, "bennett")
	Economy.tap(s)
	s.evolutions = 1
	s.run_taps = 0
	Politics.on_election(s)
	SaveStore.new(dir).save_game(s)
	await _boot()
	m.commit_pick("liberman")
	await _frames(2)
	runner.check(m._fresh_due != "", "the fresh toast waits")
	m._undo_pick()
	await _frames(2)
	runner.check(m.mode == "pick" and m._fresh_due == "", "the undo reverts the bonus: its toast never shows")


func test_d62_the_first_tap_ends_the_chip_and_the_fresh_toast_still_docks_in_the_lane() -> void:
	var s := GameState.fresh()
	Leaders.set_salt(s, 7)
	Politics.install(s, "bennett")
	Economy.tap(s)
	s.evolutions = 1
	s.run_taps = 0
	Politics.on_election(s)
	SaveStore.new(dir).save_game(s)
	await _boot()
	m.commit_pick("liberman")
	bb_land()
	await _frames(2)
	_tap_leader()
	m._update_undo_chip(16.0)
	m._dock_toasts()
	var tt: Toasts = m.toasts
	runner.check(not m.undo_visible() and m._fresh_due == "", "tap 1 ends the chip, and the fresh toast is due")
	runner.check(tt.queued_dock(tt._queue.size() - 1) == "lane" or tt.dock() == "lane", "it asks for the lane band, whatever ended the chip")


func bb_land() -> void:
	m.bb.walk_land()


# ------------------------------------------------------------------ merge review M4

func test_m4_the_p0_hand_points_at_the_pulse_on_the_tap_object() -> void:
	await _boot()
	m.ftue.handoff_ms = 1.0
	m.commit_pick("bengvir")
	await _frames(2)
	var ctx: Dictionary = m._ftue_ctx(true)
	var tp: Vector2 = ctx["tapPoint"]
	var head: Vector2 = ctx["hat"]
	runner.check(tp == m.bb.pulse_point(), "the ctx carries the pulse's own point")
	runner.check(tp.distance_to(head) >= 40.0, "for a leader with a prop it is not the head (%s vs %s)" % [tp, head])
	runner.check(m.bb.hit_rect().has_point(tp), "and it is on the leader (inside his hit)")
	var f: Ftue = m.ftue
	f.reduced_motion = true
	f._idle_ms = 10000.0
	f.update_view(16.0, m.state, m.d, ctx)
	runner.check(f.hand.visible and f.hand.position == tp + Vector2(56, 40), "F2: the hand at the tap object's right side (%s, want %s)" % [f.hand.position, tp + Vector2(56, 40)])


# ------------------------------------------------------------------ merge review M5

func test_m5_after_an_election_the_chip_docks_on_a_navy_tab_from_x_0() -> void:
	var s := GameState.fresh()
	Leaders.set_salt(s, 7)
	Politics.install(s, "bennett")
	Economy.tap(s)
	s.evolutions = 1
	s.run_taps = 0
	Politics.on_election(s)
	SaveStore.new(dir).save_game(s)
	await _boot()
	m.commit_pick("liberman")
	await _frames(2)
	runner.check(m.undo_home() == "lane" and m.undo_visible(), "after an election: the lane")
	var tab: ColorRect = m._undo_tab
	var chip: Rect2 = m._undo_lane_btn.visual
	runner.check(tab.visible and tab.color == Color("#072a7a"), "a flat navy tab, the undo bar's colour")
	runner.check(is_equal_approx(tab.position.x, -L.sox()), "from the canvas's left edge (x 0; %s)" % tab.position.x)
	runner.check(is_equal_approx(tab.position.x + tab.size.x, chip.end.x + 8.0), "to the chip's right edge + 8 (%s vs %s)" % [tab.position.x + tab.size.x, chip.end.x + 8.0])
	runner.check(is_equal_approx(tab.size.y, chip.size.y + 16.0) and is_equal_approx(tab.position.y, chip.position.y - 8.0), "the chip's height + 16, centred on it")
	var bar: ColorRect = m._undo_lane_bar
	runner.check(is_equal_approx(bar.position.y + bar.size.y, tab.position.y + tab.size.y) and bar.position.x >= tab.position.x - 0.5 \
		and bar.position.x + bar.size.x <= tab.position.x + tab.size.x + 0.5, "the timer line runs along the tab's bottom (%s in %s)" % [Rect2(bar.position, bar.size), Rect2(tab.position, tab.size)])
	runner.check(tab.get_index() < m._undo_lane_btn.bg.get_index(), "under the chip")
	m._undo_ms = 0.0
	m._update_undo_chip(16.0)
	runner.check(not tab.visible, "it goes with the chip")


# ------------------------------------------------------------------ merge review M2

func test_m2_a_round_begun_with_an_empty_purse_shows_card_1_and_the_teasers() -> void:
	var s := GameState.fresh()
	Leaders.set_salt(s, 7)
	Politics.install(s, "bennett")
	for i in 3:
		Economy.tap(s)
	s.evolutions = 1
	s.run_taps = 0
	s.run_bananas = 0.0
	Politics.on_election(s)
	s.bananas = 3.0
	SaveStore.new(dir).save_game(s)
	await _boot()
	m.commit_pick("liberman")
	await _frames(3)
	runner.check(m.state.bananas <= 5.0 and m.shop.visible, "round 2, ≤ 5 ₪ in hand, the pane up (%s ₪)" % m.state.bananas)
	var models: Array = m.shop._models(m.state, "producers")
	var kinds: Array = models.map(func(x: Dictionary) -> String: return str(x["kind"]))
	var first := kinds.find("producer")
	runner.check(first >= 0 and str(models[first]["id"]) == Content.producer_ids()[0], "card 1 is the first source, a real card (%s)" % str(kinds))
	runner.check(kinds.count("teaser") >= 1, "with the teaser rows under it (%s)" % str(kinds))
