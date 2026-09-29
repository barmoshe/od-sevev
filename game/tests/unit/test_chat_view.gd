extends RefCounted
## T3 "קואליציה 61" (ui/views/view_chat.gd, ux/rtl-map.md §6.3): the thread's run grouping, a pay
## pill tap committing through Coalition.pay, the ultimatum bubble's timer, the tab opening from
## Row B / slot 3, and C1's allowPing now that the chat exists. The real scene boots on the game
## content (design/content.json) with a throwaway save folder; input goes through the same
## _unhandled_input boundary a phone uses.

var runner: Object
var tree: SceneTree
var dir := ""
var m: Node


func setup(r: Object) -> void:
	TestFixture.use_game_content()
	tree = r as SceneTree
	dir = "user://test_chat_%d" % Time.get_ticks_usec()
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
	_touch(_stage_pt(L.magician_hit().get_center()))   # title → main (tap 1)


func _touch(p: Vector2, idx: int = 0) -> void:
	for pressed in [true, false]:
		var e := InputEventScreenTouch.new()
		e.index = idx
		e.position = p
		e.pressed = pressed
		m._unhandled_input(e)


func _stage_pt(p: Vector2) -> Vector2:
	return p + Vector2(m._ox, m._stage_y)


func _top_pt(p: Vector2) -> Vector2:
	return p + Vector2(m._ox, m._top_y)


## A chat content-local point to a viewport point.
func _chat_pt(c: Vector2) -> Vector2:
	var chat: ChatView = m.chat
	return chat.content_to_tall(c) + chat.position + Vector2(m._ox, m._lower_y)


## Three sources owned and the first demand affordable, then the group opens (C1).
func _open_group() -> void:
	var ids := Content.producer_ids()
	for i in 3:
		m.state.owned[ids[i]] = 1
	Economy.add_bananas(m.state, 500.0)
	m.d = Economy.derive(m.state)
	Coalition.open_group(m.state, m.d, func() -> float: return 0.0)


## Opens T3 and skips the open slide, the input delay and the reveal cascade.
func _open_chat_now() -> void:
	var chat: ChatView = m.chat
	chat.open()
	chat._open_ms -= 1000.0
	chat._end_anim(true)
	chat.reveal_all()
	await tree.process_frame
	chat._scroll_bottom(false)   # no scroll tween: aim at the settled thread
	await tree.process_frame


func _post(msg: Dictionary) -> Dictionary:
	return Coalition._post(m.state, msg, [])


# ------------------------------------------------------------------ pure rules

func test_run_grouping_shows_one_avatar_per_run() -> void:
	var chat := [
		{"seq": 1, "type": "sys", "key": "chat.sys.created", "state": "", "partner": ""},
		{"seq": 2, "type": "demand", "partner": "bengvir", "state": "paid", "line": "demand", "variant": 0, "price": 60.0},
		{"seq": 3, "type": "thanks", "partner": "bengvir", "state": "", "line": "thanks", "variant": 0},
		{"seq": 4, "type": "reply", "n": 1, "state": "", "partner": ""},
		{"seq": 5, "type": "demand", "partner": "bengvir", "state": "open", "line": "demand", "variant": 1, "price": 90.0},
		{"seq": 6, "type": "ultimatum", "partner": "bengvir", "state": "open", "line": "threat", "variant": 0, "price": 90.0, "leftSec": 45.0},
		{"seq": 7, "type": "demand", "partner": "smotrich", "state": "open", "line": "demand", "variant": 0, "price": 120.0},
		{"seq": 8, "type": "ultimatum", "partner": "smotrich", "state": "deleted", "line": "threat", "variant": 0, "price": 1.0},
	]
	var rows := ChatView.thread_model(chat)
	var firsts: Array = rows.map(func(r: Dictionary) -> bool: return r["first"])
	var kinds: Array = rows.map(func(r: Dictionary) -> String: return r["kind"])
	runner.check(kinds == ["sys", "in", "in", "out", "in", "ult", "in", "deleted"], "row kinds %s" % str(kinds))
	runner.check(firsts == [false, true, false, false, true, false, true, false],
		"a run from one sender shows its avatar and name once; a reply or another sender starts a new run (%s)" % str(firsts))
	runner.check(ChatView.thread_model(chat, 4).size() == 4, "messages past the revealed seq are not shown yet")


func test_lines_and_system_text_come_from_content_and_ui_strings() -> void:
	var m1 := {"type": "demand", "partner": "bengvir", "line": "demand", "variant": 1, "price": 60.0}
	var t := ChatView.line_text(m1, null, null)
	runner.check(t == str(Coalition.partner("bengvir")["linesVariants"]["demand"][1]), "the bubble is the content's line variant")
	var s := ChatView.sys_text({"type": "sys", "key": "chat.sys.left", "partner": "regev"})
	runner.check(s == Strings.s("CHAT_SYS_LEFT_F", {"name": ChatView.partner_name("regev")}), "a system line picks the partner's gender (%s)" % s)
	var mu := ChatView.sys_text({"type": "sys", "key": "chat.sys.muted", "partner": "distel"})
	runner.check(mu.begins_with("היועצים המשפטיים"), "Distel's muted line names the legal advisers, not her (%s)" % mu)
	runner.check(ChatView.char_for("bengvir") == "ben-gvir" and ChatView.char_for("maygolan") == "golan", "partner ids resolve to the cast slugs")
	var av: Array = ChatView.avatar_art("bengvir")
	var px := Vector2(Art.sprite_size(av[0])) * float(av[1])
	runner.check(px == Vector2(128, 128), "the chat avatar is 32 art px drawn at artScale/density = 128 logical (%s)" % str(px))


# ------------------------------------------------------------------ the real scene

func test_three_ben_gvir_bubbles_show_one_avatar_and_name() -> void:
	await _boot()
	_open_group()
	for v in [1, 2]:
		_post({"type": "demand", "partner": "bengvir", "price": 10.0, "kind": "money", "join": false, "ageSec": 0.0,
			"state": "expired", "line": "demand", "variant": v})
	await _open_chat_now()
	var avatars := 0
	var bubbles := 0
	for r: Dictionary in m.chat.rows():
		if r.get("partner", "") == "bengvir" and ["in", "ult", "deleted"].has(r.get("kind", "")):
			bubbles += 1
			if r.has("avatar"):
				avatars += 1
	runner.check(bubbles == 3 and avatars == 1, "three Ben Gvir bubbles in a run: one avatar (%d bubbles, %d avatars)" % [bubbles, avatars])


func test_tapping_the_pay_pill_pays_through_the_sim() -> void:
	await _boot()
	_open_group()
	await _open_chat_now()
	var hit: Dictionary = {}
	for h: Dictionary in m.chat.hits():
		if h["kind"] == "pay":
			hit = h
	runner.check(not hit.is_empty(), "the first demand carries a pay pill")
	if hit.is_empty():
		return
	var seq: int = hit["seq"]
	var before: float = m.state.bananas
	_touch(_chat_pt((hit["rect"] as Rect2).get_center()))
	var msg := Coalition.message(m.state, seq)
	runner.check(msg.get("state", "") == "paid", "the tap commits Coalition.pay (state %s)" % msg.get("state", ""))
	runner.check(is_equal_approx(before - m.state.bananas, 60.0), "the fixed first demand cost 60 ₪ (%s)" % str(before - m.state.bananas))
	runner.check(int(m.state.coalition["paidLifetime"]) == 1, "the sim counted the payment")
	runner.check(Coalition.status(m.state, "bengvir") == "member", "Ben Gvir joined")
	for i in 2:
		await tree.process_frame
	var stamped := false
	for r: Dictionary in m.chat.rows():
		for p: Dictionary in r["pills"]:
			if int(p["seq"]) == seq and (p["stamp"] as Sprite2D).visible:
				stamped = true
	runner.check(stamped, "the pill turns into the שולם stamp")


func test_an_unaffordable_pill_does_not_pay() -> void:
	await _boot()
	_open_group()
	m.state.bananas = 5.0
	await _open_chat_now()
	var seq := -1
	for h: Dictionary in m.chat.hits():
		if h["kind"] == "pay":
			seq = h["seq"]
			_touch(_chat_pt((h["rect"] as Rect2).get_center()))
	runner.check(seq >= 0 and Coalition.message(m.state, seq).get("state", "") == "open", "no money, no payment: the demand stays open")


func test_the_ultimatum_bubble_shows_its_timer() -> void:
	await _boot()
	_open_group()
	var u := _post({"type": "ultimatum", "partner": "bengvir", "price": 90.0, "kind": "money", "leftSec": 45.0,
		"state": "open", "line": "threat", "variant": 0})
	await _open_chat_now()
	var row: Dictionary = {}
	for r: Dictionary in m.chat.rows():
		if r.get("kind", "") == "ult":
			row = r
	runner.check(not row.is_empty() and row.get("chip") != null, "the ultimatum bubble carries the clock chip")
	if row.is_empty() or row.get("chip") == null:
		return
	var t: PxText = row["chip"]["text"]
	runner.check(t.text == "0:45", "the chip shows the time left (%s)" % t.text)
	u["leftSec"] = 2.2
	await tree.process_frame
	runner.check(t.text == "0:03", "the digits follow the sim, ceil to the second (%s)" % t.text)
	runner.check(bool(row["chip"]["urgent"]), "the last 3 s mark the chip urgent (the 2 Hz nudge)")
	runner.check(m.chat.pay(int(u["seq"])), "paying the ultimatum goes through the sim")
	runner.check(Coalition.message(m.state, int(u["seq"])).get("state", "") == "deleted", "a paid ultimatum reads 'ההודעה נמחקה'")


func test_the_tab_opens_from_the_seats_row_and_slot_3() -> void:
	await _boot()
	_open_group()
	m.state.coalition["paidLifetime"] = 1   # C2: Row B is revealed after the first paid demand
	for i in 3:
		await tree.process_frame
	runner.check(not m.chat.is_open(), "T3 starts closed")
	_touch(_top_pt(Vector2(360, 138)))
	runner.check(m.chat.is_open(), "a tap anywhere on Row B opens T3")
	runner.check(m.shop.tall == "coalition", "the coalition slot shows as the active tab")
	runner.check(not m.stage_unobstructed(), "the stage is covered (no Suitcase spawns)")
	var taps: int = m.state.taps_lifetime
	_touch(_stage_pt(L.magician_hit().get_center()))
	runner.check(m.state.taps_lifetime == taps, "the Magician takes no taps under the chat")
	var e := InputEventKey.new()
	e.keycode = KEY_ESCAPE
	e.pressed = true
	m._unhandled_input(e)
	runner.check(not m.chat.is_open(), "Esc closes T3 (not the settings)")
	runner.check(not m.overlays.is_open(), "and opens no overlay")
	m.shop.switch_slot(3)
	runner.check(m.chat.is_open(), "keyboard 3 / the tab slot opens T3")
	m.shop.switch_tab("producers")
	runner.check(not m.chat.is_open(), "a list tab closes it")


func test_the_group_opens_now_that_the_chat_exists() -> void:
	await _boot()
	var ids := Content.producer_ids()
	for i in 3:
		m.state.owned[ids[i]] = 1
	Economy.add_bananas(m.state, 500.0)
	m.d = Economy.derive(m.state)
	m.toasts._queue.clear()
	m.toasts._t = -1.0
	m.toasts._bt = -1.0
	m._step_economy(1.0 / 60.0, false)
	runner.check(bool(m.state.coalition["opened"]), "C1: allowPing is live, the group opens")
	for i in 2:
		await tree.process_frame
	runner.check(m.shop._slots[2]["badgeText"].text != "", "slot 3 carries the open demand's badge")


func test_typing_telegraph_only_for_messages_posted_while_open() -> void:
	await _boot()
	_open_group()
	await _open_chat_now()
	var chat: ChatView = m.chat
	chat.close()
	var a := _post({"type": "demand", "partner": "bengvir", "price": 10.0, "kind": "money", "join": false, "ageSec": 0.0,
		"state": "open", "line": "demand", "variant": 1})
	chat.open()
	runner.check(chat._upto >= int(a["seq"]), "a message that landed while closed shows at once on open (no typing)")
	var b := _post({"type": "demand", "partner": "bengvir", "price": 10.0, "kind": "money", "join": false, "ageSec": 0.0,
		"state": "open", "line": "demand", "variant": 2})
	chat.update_view(400.0, m.state, m.d, {"main": true})   # past the cascade gap of the C1 lines
	runner.check(int(chat.typing().get("seq", -1)) == int(b["seq"]) and chat._upto < int(b["seq"]),
		"a bubble posted while open waits behind the typing telegraph")
	runner.check(chat._status.text == Strings.gendered("CHAT_TYPING", "m", {"name": ChatView.partner_name("bengvir")}),
		"the header says who is typing")
	chat.update_view(ChatView.mc("chatTypingMs") + 20.0, m.state, m.d, {"main": true})
	runner.check(chat._upto >= int(b["seq"]), "then it lands")
