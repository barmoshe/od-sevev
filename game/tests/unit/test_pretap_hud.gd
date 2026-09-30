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
