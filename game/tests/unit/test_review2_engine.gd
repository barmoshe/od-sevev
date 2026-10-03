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

## Superseded by A2 (2026-09-30 manual test, mobile-first §3.3 rev): with leader select, card 1
## (dim) and its white field are up from the pick, so the screen under the stage is never half stone;
## the plaza stays only as the strip in the (still free) ticker slot until H1.
func test_u3_the_apron_stays_until_card_1() -> void:
	await _boot()
	m.commit_pick("bibi")
	await _frames(2)
	var fill: ColorRect = m._fills["shop"]
	runner.check(m.mode == "title" and fill.visible and m.shop.visible, "pre-tap: card 1 and the pane's white are up from the pick (fill %s, shop %s)" % [fill.visible, m.shop.visible])
	runner.check(m._title_floor.visible and not m.ticker.visible, "the ticker slot is still the plaza strip (floor %s, ticker %s)" % [m._title_floor.visible, m.ticker.visible])
	_tap_leader()
	await _frames(3)
	runner.check(m.mode == "main" and m.state.taps_lifetime == 1, "tap 1 starts the round")
	runner.check(fill.visible and m.ticker.visible, "H1: the ticker takes the strip's slot; the pane stays")
	await tree.create_timer(1.0).timeout   # past the title fade
	runner.check(not m._title_floor.visible or m._title_floor.modulate.a < 0.01, "and the strip's floor is gone under the ticker")


# ------------------------------------------------------------------ U6

func test_u6_a_cut_row_draws_no_pill() -> void:
	await _boot()
	m.commit_pick("bibi")
	await _frames(2)
	m.state.taps_lifetime = 3
	Economy.add_money(m.state, 1e6)
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
	# from H1 on, his bubble by the ticker; tap 1 retires the dock line
	_tap_leader()
	runner.check(tt._chats.all(func(c: Dictionary) -> bool: return not bool(c.get("passive", false))), "tap 1 drops Dubi's queued dock line")
	m._say_pick(Strings.s("DUBI_LEARNED"), Vector2(644, 300))
	runner.check(tt.saying(), "after tap 1 the line is Dubi's bubble again")


# ------------------------------------------------------------------ U13

func test_u13_the_owned_chip_fits_its_text() -> void:
	var r := Shop.owned_rect(40.0)
	runner.check(r == Rect2(572, 76, 56, 40), "text 40 → 56 × 40 at the plate's bottom-left (%s)" % r)
	runner.check(Shop.owned_rect(8.0).size.x == 48.0, "min 48")
	runner.check(Shop.owned_rect(40.0).size.x < 104.0, "smaller than the old 104 × 44 chip")


# ------------------------------------------------------------------ the 2D Artist's wave 10 (U2, U7, U10)

func test_u2_the_white_primary_and_the_gold_election_call() -> void:
	var k: Dictionary = PxButton.kinds()["kit_primary"]
	runner.check(str(k["normal"][0]) == "button_white_default" and str(k["pressed"][0]) == "button_white_pressed", "kit_primary is the white button (%s)" % k["normal"][0])
	runner.check(str(k["normal"][2]) == "u" and str(k["pressed"][2]) == "u" and PxButton.label_color("kit_primary") == Color("#0038b8"), "its label is flag blue, never white on white")
	runner.check(str(PxButton.kinds()["kit_secondary"]["normal"][2]) == "w", "the secondary keeps its white label")
	await _boot()
	m._open_evolution()
	await tree.create_timer(0.3).timeout
	var c := m.overlays.top() as ElectionCard
	runner.check(c != null and c.go_button.kind == "kit_gold", "O3's ELECT_GO takes the gold CTA skin")


func test_u7_the_teaser_rows_and_the_system_pill() -> void:
	var sh := Shop.new()
	runner.check(sh._card_sprite("teaser", false) == "card_row_silhouette" and sh._card_sprite("silhouette", true) == "card_row_silhouette", "teaser and locked rows are the pale slip")
	sh.free()
	var sil := "source_taxpayer_icon_sil"
	runner.check(Shop.pale_sil(sil) == sil + "_pale", "the silhouette draws its pale cut")
	runner.check(Art.has_sprite("chat_system_pill_navy"), "T3's navy system pill ships")


func test_u10_the_transition_is_the_printed_notice() -> void:
	await _boot()
	var tx: EvolveTx = m.tx
	tx.start({"round": 2, "multBefore": 1.0, "multAfter": 1.2, "gained": 12, "era": ""}, false, {})
	tx.update_view(400.0)
	runner.check(tx._notice != null and tx._notice.visible and tx._card.color == Color("#0038b8"), "a white notice on the flag-blue page")
	runner.check(tx._species.tint == Color("#0038b8") and tx._gain.tint == Color("#0f2350"), "the title in flag, the body in night")
	var nr := Rect2(tx._notice.position, tx._notice.size * 4.0)
	runner.check(nr.position.y + 32.0 <= tx._line.position.y and nr.end.y - 24.0 >= EvolveTx.ERA_Y + 36.0, "the notice frames the lines (%s)" % nr)
	tx._finish()
