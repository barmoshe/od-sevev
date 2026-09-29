extends RefCounted
## Views wave 6 (game-developer views, 2026-09-29): the chat's "{n} ממתינים ↑" chip (open pay pills
## or an open brawl above T3's viewport; a tap brings the nearest one in), the brawl stage cue
## (the brawl cloud under Row B while a brawl is open and T3 is closed; a tap opens T3 at it), and
## the timed-spin end feedback (a toast naming the spin, and the `spinEnd` audio hook). The real
## scene boots on the game content with a throwaway save folder; input goes through the same
## _unhandled_input boundary a phone uses.

var runner: Object
var tree: SceneTree
var dir := ""
var m: Node
var heard: Array = []


func setup(r: Object) -> void:
	TestFixture.use_game_content()
	tree = r as SceneTree
	dir = "user://test_wave6_%d" % Time.get_ticks_usec()
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
	_touch(L.magician_hit().get_center() + Vector2(m._sx, m._stage_y))   # title → main (tap 1)
	m.audio_sent.connect(func(n: String, a: Variant) -> void: heard.append([n, a]))


func _touch(p: Vector2, idx: int = 0) -> void:
	for pressed in [true, false]:
		var e := InputEventScreenTouch.new()
		e.index = idx
		e.position = p
		e.pressed = pressed
		m._unhandled_input(e)


## A tall-local point of the chat view to a viewport point.
func _tall_pt(q: Vector2) -> Vector2:
	var chat: ChatView = m.chat
	return q + chat.position + Vector2(m._ox, m._lower_y)


func _open_group() -> void:
	var ids := Content.producer_ids()
	for i in 3:
		m.state.owned[ids[i]] = 1
	Economy.add_bananas(m.state, 500.0)
	m.d = Economy.derive(m.state)
	Coalition.open_group(m.state, m.d, func() -> float: return 0.0)


func _open_chat_now() -> void:
	var chat: ChatView = m.chat
	chat.open()
	chat._open_ms -= 1000.0
	chat._end_anim(true)
	chat.reveal_all()
	await tree.process_frame
	chat._scroll_bottom(false)
	await tree.process_frame
	await tree.process_frame


func _quiet_toasts() -> void:
	var t: Toasts = m.toasts
	t._queue.clear()
	t._tags.clear()
	t._chats.clear()
	if t._t >= 0.0:
		t._t = Toasts.SHOW_MS   # the showing toast ends on this update (the plate hides)
	t.update_view(16.0)
	t._gap = 0.0


# ------------------------------------------------------------------ the pending chip

func test_pending_above_counts_open_items_over_the_viewport() -> void:
	var hits := [
		{"kind": "pay", "seq": 3, "rect": Rect2(200, 100, 352, 88)},
		{"kind": "partner", "partner": "bengvir", "rect": Rect2(576, 0, 128, 128)},
		{"kind": "brawl", "seq": 7, "rect": Rect2(192, 500, 336, 88)},
		{"kind": "pay", "seq": 9, "rect": Rect2(200, 900, 352, 88)},
	]
	var up := ChatView.pending_above(hits, 700.0)
	runner.check(up.size() == 2, "a pill and a brawl button wholly above the top edge count; an avatar never does (%s)" % str(up))
	runner.check(int(up[0]["seq"]) == 7 and int(up[1]["seq"]) == 3, "nearest first: the one just above the edge leads")
	runner.check(ChatView.pending_above(hits, 550.0).size() == 1, "an item cut by the top edge is still in view: not pending")
	runner.check(ChatView.pending_above(hits, 0.0).is_empty(), "at the top of the thread nothing is above")


func test_the_chip_shows_counts_and_scrolls_to_the_nearest() -> void:
	await _boot()
	_open_group()
	for i in 24:
		Coalition._post(m.state, {"type": "sys", "key": "chat.sys.created"}, [])
	await _open_chat_now()
	var chat: ChatView = m.chat
	chat.reduced_motion = true
	var info := chat.pending_info()
	var open_pay := 0
	for h: Dictionary in chat.hits():
		if h["kind"] == "pay" and (h["rect"] as Rect2).end.y <= chat.view_top():
			open_pay += 1
	runner.check(open_pay >= 1, "the first demand's pill sits above the viewport (%d)" % open_pay)
	runner.check(info["visible"] and int(info["n"]) == open_pay, "the chip is up and counts them (%s)" % str(info))
	var want := Strings.plural("CHAT_PENDING", open_pay, {"n": str(open_pay)})
	runner.check(chat._pending_text.text == want, "it reads '%s'" % want)
	var r: Rect2 = info["rect"]
	runner.check(is_equal_approx(r.get_center().x, 360.0) and r.position.y >= ChatView.THREAD_Y, "centred on the thread's top edge (%s)" % str(r))
	var target := int(info["seq"])
	_touch(_tall_pt(r.get_center()))
	await tree.process_frame
	await tree.process_frame
	var item := {}
	for h: Dictionary in chat.hits():
		if h["kind"] == "pay" and int(h["seq"]) == target:
			item = h
	var top := chat.view_top()
	runner.check(not item.is_empty() and (item["rect"] as Rect2).position.y >= top and (item["rect"] as Rect2).end.y <= top + chat.thread_h(),
		"the tap brings the nearest open pill into view (top %s, item %s)" % [top, str(item.get("rect", ""))])
	runner.check(["uiClick", null] in heard, "the chip clicks")
	runner.check(not chat.pending_info()["visible"] or int(chat.pending_info()["n"]) < open_pay, "the chip counts one less (or leaves) once it is in view")
	# at the bottom again: the chip is back
	chat._scroll_bottom(false)
	await tree.process_frame
	await tree.process_frame
	runner.check(chat.pending_info()["visible"], "scrolled back down, the chip returns")
	chat.close()
	await tree.process_frame
	runner.check(not chat.pending_info()["visible"], "a closed chat has no chip")


# ------------------------------------------------------------------ the brawl stage cue

func test_an_open_brawl_puts_a_cloud_under_row_b() -> void:
	await _boot()
	_open_group()
	var chat: ChatView = m.chat
	await tree.process_frame
	runner.check(not chat.brawl_cue_visible(), "no brawl, no cue")
	for id in ["amsalem", "smotrich"]:
		Coalition.ps(m.state, id)["status"] = "member"
	for e: Dictionary in Coalition.start_brawl(m.state, "amsalem", "smotrich"):
		chat.on_politics_event(e)
	await tree.process_frame
	await tree.process_frame
	runner.check(not chat.brawl_cue_visible(), "the brawl toast is showing: the cue yields to the toast dock")
	_quiet_toasts()
	await tree.process_frame
	await tree.process_frame
	runner.check(chat.brawl_cue_visible(), "the brawl is open and T3 closed: the cloud stands under Row B")
	var cloud: Sprite2D = chat._brawl_cloud
	# the boil (animator 2026-09-29) steps the cloud around a 1-ap ring (4 logical) off its rest
	var boil := cloud.position - ChatView.BRAWL_CLOUD
	runner.check(absf(boil.x) + absf(boil.y) <= 4.0 and is_equal_approx(cloud.scale.x, 2.0) and ChatView.BRAWL_CUE.encloses(Rect2(cloud.position, Vector2(104, 80))),
		"the cloud at ×2 inside its bubble at the stage's top-left (%s)" % str(cloud.position))
	runner.check(ChatView.BRAWL_CUE_HIT.size.y >= 88.0 and ChatView.BRAWL_CUE_HIT.encloses(ChatView.BRAWL_CUE), "its hit is ≥ 88 tall and covers it")
	var brawl := Coalition.open_brawl(m.state)
	_touch(_tall_pt(ChatView.BRAWL_CUE.get_center()))
	await tree.process_frame
	runner.check(chat.is_open(), "a tap opens T3")
	chat._end_anim(true)
	chat.reveal_all()
	chat._scroll_to_seq(int(brawl["seq"]))
	await tree.process_frame
	await tree.process_frame
	runner.check(not chat.brawl_cue_visible(), "with T3 open the cue is gone")
	var row := chat._row_of(int(brawl["seq"]))
	runner.check(not row.is_empty() and float(row["y"]) + float(row["h"]) > chat.view_top(), "T3 opens at the brawl")
	chat.resolve_brawl(int(brawl["seq"]))
	chat.close()
	chat._end_anim(false)
	for i in 3:
		await tree.process_frame
	runner.check(not chat.brawl_cue_visible(), "\"צאו החוצה\" ends the brawl: no cue")


# ------------------------------------------------------------------ the timed-spin end

func test_a_timed_spin_ending_says_so() -> void:
	await _boot()
	_quiet_toasts()
	heard.clear()
	var id := ""
	for u: Dictionary in Content.upgrades():
		if Spins.kind(u) == "consumable":
			id = str(u["id"])
			break
	if id == "":
		id = "s07"
	m.state.spins["active"] = [{"id": id, "type": "tapFrenzy", "leftSec": 0.01, "durationSec": 30.0}]
	m._step_economy(0.05, false)
	var t: Toasts = m.toasts
	t.update_view(16.0)
	var want := Strings.s("TOAST_SPIN_END", {"NAME": Strings.upgrade_name(id)})
	runner.check(t.shown()["text"] == want or t._queue.has(want), "a toast names the spin that ended (%s)" % want)
	runner.check(want.contains(Strings.upgrade_name(id)) and not want.contains("{"), "the spin's own name is in it")
	runner.check(["spinEnd", id] in heard, "the Audio hears spinEnd(%s) (heard %s)" % [id, str(heard)])
	runner.check(Spins.active_effects(m.state).is_empty(), "the timer is gone")
	heard.clear()
	m._step_economy(0.05, false)
	runner.check(not heard.any(func(h: Array) -> bool: return h[0] == "spinEnd"), "once only")
