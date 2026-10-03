extends RefCounted
## Real input routing through the controller (the v2 stand-in for wandcraft's taptest): the main
## scene runs headless with a throwaway save folder, and touch and key events go through the same
## _unhandled_input boundary a phone uses.

var runner: Object
var tree: SceneTree
var dir := ""
var m: Node


func setup(r: Object) -> void:
	TestFixture.use_fork_content()   # the input router, not the content, is under test here
	tree = r as SceneTree
	dir = "user://test_input_%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(dir)


func teardown() -> void:
	if m and is_instance_valid(m):
		m.set_process(false)   # no frame of this scene may run after the content switches back
		if m.get_parent():
			m.get_parent().remove_child(m)
		m.queue_free()
	TestFixture.use_game_content()
	var d := DirAccess.open(dir)
	if d:
		for f in d.get_files():
			d.remove(f)
	DirAccess.remove_absolute(dir)


func _boot(pick: bool = true) -> void:
	m = load("res://scenes/main.tscn").instantiate()
	m.store = SaveStore.new(dir)
	tree.root.add_child(m)
	for i in 3:
		await tree.process_frame
	if pick:
		m.commit_pick("bibi")   # LEADER_PICK first (leader select): Bibi's round, the shipped game


## A design-space point in a section to a viewport point.
func _stage_pt(p: Vector2) -> Vector2:
	return p + Vector2(m._sx, m._stage_y)


## The Magician's hit centre (rtl-map §4), stage design space.
func _hat() -> Vector2:
	return L.magician_hit().get_center()


## A `_lower`-local point (ticker, cards, tabs) to a viewport point.
func _lower_pt(p: Vector2) -> Vector2:
	return p + Vector2(m._ox, m._lower_y)


## The centre of card k in the panel, `_lower`-local.
func _card(k: int) -> Vector2:
	return Vector2(400, float(L.SHOP["listY"]) + float(L.SHOP["rowPitch"]) * k + 60.0)


func _top_pt(p: Vector2) -> Vector2:
	return p + Vector2(m._ox, m._top_y)


func _touch(p: Vector2, idx: int = 0) -> void:
	var e := InputEventScreenTouch.new()
	e.index = idx
	e.position = p
	e.pressed = true
	m._unhandled_input(e)
	var u := InputEventScreenTouch.new()
	u.index = idx
	u.position = p
	u.pressed = false
	m._unhandled_input(u)


func _key(k: Key) -> void:
	var e := InputEventKey.new()
	e.keycode = k
	e.pressed = true
	m._unhandled_input(e)


func test_title_tap_starts_and_taps_count() -> void:
	await _boot(false)
	# the fork's content has no leader select: the title state as ever (the picker: test_leader_pick)
	runner.check(m.mode == "title", "a fresh install starts on the title")
	_touch(_stage_pt(_hat()))
	runner.check(m.mode == "main", "a tap on the Magician starts the game")
	runner.check(m.state.taps_lifetime == 1, "and counts as tap #1")
	for i in 5:
		_touch(_stage_pt(_hat() + Vector2(0, 10 * i)), i)
	runner.check(m.state.taps_lifetime == 6, "five more taps register (%d)" % m.state.taps_lifetime)


func test_buy_a_producer_by_touch() -> void:
	await _boot()
	_touch(_stage_pt(_hat()))
	for i in 2:
		_touch(_stage_pt(_hat()))   # ux/ftue.md: card 1 appears at tap 3
	Economy.add_money(m.state, 100.0)
	for i in 3:
		await tree.process_frame
	var k: int = m.shop.row_index_of(m.state, "producer", "intern")
	runner.check(k == 0, "the first source is card 1")
	runner.check(m.shop.visible, "the panel is shown after tap 3")
	_touch(_lower_pt(_card(k) + Vector2(160, 0)))   # the name area: the whole card is the target
	runner.check(m.state.owned_of("intern") == 1, "tapping the card body buys the first source")


func test_keyboard_opens_evolution_and_back_closes() -> void:
	await _boot()
	_touch(_stage_pt(_hat()))
	Economy.add_money(m.state, 2_000_000.0)
	for i in 3:
		await tree.process_frame
	_key(KEY_E)
	runner.check(m.overlays.has_id("EVOLUTION"), "E opens the Evolution screen (v1 had no key for it)")
	m._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	runner.check(not m.overlays.has_id("EVOLUTION") or m.overlays.top().closing, "the back button closes it")


func test_modal_scrim_is_visible_once_open() -> void:
	await _boot()
	_touch(_stage_pt(_hat()))
	Economy.add_money(m.state, 2_000_000.0)
	for i in 3:
		await tree.process_frame
	_key(KEY_E)
	var o: Overlay = m.overlays.top()
	runner.check(o != null and o.id == "EVOLUTION", "E opens a modal")
	if o == null:
		return
	o.tick(float(Tune.MC["modalEnterMs"]) + 16.0)
	var seen := o.scrim.color.a * o.scrim.modulate.a
	var want := float(Tune.MC["backdropAlpha"])
	# colour alpha multiplies modulate alpha: a scrim built with colour alpha 0 never shows
	runner.check(is_equal_approx(seen, want), "the scrim dims the game at backdropAlpha once open (drawn alpha %.2f, want %.2f)" % [seen, want])


func test_hold_to_buy_stops_behind_a_modal() -> void:
	await _boot()
	_touch(_stage_pt(_hat()))
	for i in 2:
		_touch(_stage_pt(_hat()))
	Economy.add_money(m.state, 1e6)
	for i in 3:
		await tree.process_frame
	var e := InputEventScreenTouch.new()
	e.index = 0
	e.position = _lower_pt(_card(0))
	e.pressed = true
	m._unhandled_input(e)
	m._open_settings()
	for i in 60:
		await tree.process_frame
	runner.check(m.state.owned_of("intern") == 0, "no purchases behind the Settings modal (%d)" % m.state.owned_of("intern"))
