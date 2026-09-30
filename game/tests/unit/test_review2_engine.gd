extends RefCounted
## UX build review 2 (ux/review-2026-09-30.md), the engine slice: U3 the pre-tap apron until card 1,
## U6 no pill on a partly visible row, U9 Dubi's pre-tap pick line in the toast dock, U13 the owned
## chip sized to its text. (U1 and the hemicycle: test_modals; U11, U14, E1, E2: test_share_view;
## the booth: test_mobile_layout; the glue: test_glue.) Runs on the game content, on the real scene.

var runner: Object
var tree: SceneTree
var dir := ""
var m: Node


func setup(r: Object) -> void:
	TestFixture.use_game_content()
	tree = r as SceneTree
	dir = "user://test_review2_engine_%d" % Time.get_ticks_usec()
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


func _tap_leader() -> void:
	var at: Vector2 = L.magician_hit().get_center() + Vector2(m._sx, m._stage_y)
	for pressed in [true, false]:
		var e := InputEventScreenTouch.new()
		e.position = at
		e.pressed = pressed
		m._unhandled_input(e)


# ------------------------------------------------------------------ U3

func test_u3_the_apron_stays_until_card_1() -> void:
	await _boot()
	m.commit_pick("bibi")
	await _frames(2)
	_tap_leader()
	await _frames(3)
	var fill: ColorRect = m._fills["shop"]
	runner.check(m.mode == "main" and m.state.taps_lifetime == 1, "tap 1 starts the round")
	runner.check(not fill.visible and m._title_floor.visible and m._title_floor.modulate.a > 0.99,
		"between tap 1 and card 1 the pane's white is not drawn; the apron stays (fill %s, floor %s)" % [fill.visible, m._title_floor.visible])
	for i in 2:
		await _frames(20)   # past the tap-burst guard
		_tap_leader()
	await _frames(20)
	runner.check(m.state.taps_lifetime >= 3 and fill.visible, "card 1: the white field comes with the pane (taps %d)" % m.state.taps_lifetime)
	await _frames(30)
	runner.check(not m._title_floor.visible or m._title_floor.modulate.a < 0.01, "and the apron is gone under it")


# ------------------------------------------------------------------ U6

func test_u6_a_cut_row_draws_no_pill() -> void:
	await _boot()
	m.commit_pick("bibi")
	await _frames(2)
	m.state.taps_lifetime = 3
	Economy.add_bananas(m.state, 1e6)
	m._set_mode("main", false)
	await _frames(6)
	var shop: Shop = m.shop
	var lr: Rect2 = shop.list_rect
	runner.check(shop.pill_whole(lr.position.y) and not shop.pill_whole(lr.end.y - 60.0) and not shop.pill_whole(lr.position.y - 20.0), "pill_whole: in, cut at the bottom, cut at the top")
	var pills: Array = shop.pill_rects()
	runner.check(pills.size() >= 2, "rows in the pane (%d)" % pills.size())
	var cut := 0
	for p: Array in pills:
		var whole := float(p[0]) >= lr.position.y - 0.5 and float(p[1]) <= lr.end.y + 0.5
		runner.check(whole or not bool(p[2]), "a pill is drawn only when whole (%s in %s-%s)" % [p, lr.position.y, lr.end.y])
		if not whole:
			cut += 1
	runner.check(cut >= 1, "the peek row is there and pill-less (%d cut)" % cut)


# ------------------------------------------------------------------ U9

func test_u9_the_pre_tap_pick_line_goes_in_the_toast_dock() -> void:
	await _boot()
	m.commit_pick("bibi")
	runner.check(m.mode == "title", "pre-tap")
	for e: Dictionary in m._pick_seq:
		(e["fn"] as Callable).call()
	var tt: Toasts = m.toasts
	runner.check(not tt.saying(), "no bubble floats over the leader before tap 1")
	var chat: Dictionary = tt._chats[tt._chats.size() - 1] if not tt._chats.is_empty() else {}
	runner.check(str(chat.get("head", "")) == m.dubi_head() and m.dubi_head().begins_with("דובי"), "a chat-toast plate headed by Dubi (%s)" % chat.get("head", ""))
	runner.check(bool(chat.get("passive", false)) and (chat.get("avatar", []) as Array).size() == 3, "with his face, and it takes no tap (tap 1 is the leader's)")
	# from H1 on, his bubble by the ticker
	_tap_leader()
	m._say_pick(Strings.s("DUBI_LEARNED"), Vector2(644, 300))
	runner.check(tt.saying(), "after tap 1 the line is Dubi's bubble again")


# ------------------------------------------------------------------ U13

func test_u13_the_owned_chip_fits_its_text() -> void:
	var r := Shop.owned_rect(40.0)
	runner.check(r == Rect2(572, 76, 56, 40), "text 40 → 56 × 40 at the plate's bottom-left (%s)" % r)
	runner.check(Shop.owned_rect(8.0).size.x == 48.0, "min 48")
	runner.check(Shop.owned_rect(40.0).size.x < 104.0, "smaller than the old 104 × 44 chip")
