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
	m.commit_pick("bibi")   # LEADER_PICK (leader select): Bibi's round, the shipped game
	_touch(_stage_pt(L.magician_hit().get_center()))   # title → main (tap 1)


func _touch(p: Vector2, idx: int = 0) -> void:
	for pressed in [true, false]:
		var e := InputEventScreenTouch.new()
		e.index = idx
		e.position = p
		e.pressed = pressed
		m._unhandled_input(e)


func _stage_pt(p: Vector2) -> Vector2:
	return p + Vector2(m._sx, m._stage_y)


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
	runner.check(ChatView.char_for("bengvir") == "ben-gvir" and ChatView.char_for("maygolan") == "may-golan" and ChatView.char_for("golan") == "golan", "partner ids resolve to the cast slugs; May Golan is never Yair Golan")
	var av: Array = ChatView.avatar_art("bengvir")
	var px := Vector2(Art.sprite_size(av[0])) * float(av[1])
	runner.check(px == Vector2(128, 128), "the chat avatar is 32 art px drawn at artScale/density = 128 logical (%s)" % str(px))
	# Almog Cohen was the no-photo stand-in until his ref landed (2026-09-30): now his own face, same 128 logical
	var na: Array = ChatView.avatar_art("almog")
	runner.check(ChatView.char_for("almog") == "almog" and na[0] == "avatar_almog" and Vector2(Art.sprite_size(na[0])) * float(na[1]) == Vector2(128, 128),
		"almog resolves to his own cast slug, avatar 128 logical (%s)" % str(na))
	runner.check(ChatView.toast_avatar("almog")[0] == "avatar_almog", "the chat toast shows his face too")
	# the stand-in itself still exists for a partner with no ref yet (mk_returner)
	runner.check(Art.has_sprite("avatar_nophoto"), "the no-photo stand-in is still in the kit")


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


# ------------------------------------------------------------------ views wave (review R5, R12, R13, R22, R23)

func test_the_header_counts_everyone_in_the_group() -> void:
	await _boot()
	_open_group()   # Ben Gvir joined: pending, his join demand open
	runner.check(ChatView.group_size(m.state) == 2, "a pending partner is in the group: him + the Magician (%d)" % ChatView.group_size(m.state))
	Coalition.ps(m.state, "smotrich")["status"] = "member"
	Coalition.ps(m.state, "smotrich")["frozen"] = true
	Coalition.ps(m.state, "regev")["status"] = "left"
	runner.check(ChatView.group_size(m.state) == 3, "a frozen member counts, one who left does not (%d)" % ChatView.group_size(m.state))
	await _open_chat_now()
	runner.check(m.chat._status.text == Strings.plural("CHAT_MEMBERS", 3), "the header reads the group size (%s)" % m.chat._status.text)


func test_a_ceremony_pill_reads_cut_then_cutting() -> void:
	await _boot()
	_open_group()
	var cer := _post({"type": "demand", "partner": "regev", "price": 0.0, "kind": "ceremony", "join": true, "ageSec": 0.0,
		"state": "open", "line": "demand", "variant": 0})
	await _open_chat_now()
	var pill: Dictionary = m.chat._pill_of(int(cer["seq"]))
	runner.check(not pill.is_empty() and (pill["label"] as PxText).text == Strings.s("CHAT_CEREMONY"), "a ceremony pill reads CHAT_CEREMONY, never '0 ₪'")
	runner.check(not m.chat.pay(int(cer["seq"])), "a tap starts the ribbon, it does not pay yet")
	await tree.process_frame
	runner.check((pill["label"] as PxText).text == Strings.s("CHAT_CEREMONY_CUTTING") and (pill["fill"] as NinePatchRect).visible,
		"while the ribbon fills the pill reads CHAT_CEREMONY_CUTTING (%s)" % (pill["label"] as PxText).text)
	m.chat._update_ribbon(ChatView.CEREMONY_MS + 1.0)
	runner.check(cer["state"] == "paid", "the ribbon's end pays the ceremony")


func test_the_partner_card_rows_and_its_ceremony_pill() -> void:
	await _boot()
	_open_group()
	Coalition.ps(m.state, "regev")["status"] = "pending"
	var cer := _post({"type": "demand", "partner": "regev", "price": 0.0, "kind": "ceremony", "join": true, "ageSec": 0.0,
		"state": "open", "line": "demand", "variant": 0})
	await _open_chat_now()
	m.chat.open_partner_card("regev")
	await tree.process_frame
	var card: ChatView.PartnerCard = m.overlays.top() as ChatView.PartnerCard
	runner.check(card != null, "the partner card opens")
	if card == null:
		return
	runner.check(card.row_value.size() == 2, "two rows: seats and upkeep")
	runner.check([2, 3, 4].has(card.fig_scale) and card.panel_rect.position.y >= 0.0 and card.panel_rect.end.y <= float(L.H),
		"the figure is at an integer art scale (×%d) and the card fits the modal space (%s)" % [card.fig_scale, card.panel_rect])
	var dens_list: Array = [4]   # k 4 (a DPR-2 phone): ×4 is exact on the d 2 alternate
	runner.check(FlashCard.pick_art_scale(4, [3, 2], func(_s: int) -> bool: return true, [4, 3, 2]) == 4 and FlashCard.pick_art_scale(6, [3, 2], func(_s: int) -> bool: return true, [4, 3, 2]) == 4,
		"the pick gives ×4 at k 4 and k 6 on a d 3 + d 2 cast %s" % str(dens_list))
	for v: PxText in card.row_value:
		runner.check(v.h_anchor == 2 and v.position.x > card.panel_rect.position.x + 200.0,
			"a value sits beside its label, not at the card's far left (right edge %s)" % v.position.x)
		runner.check(v.tint == Art.col(Art.theme["modal"]["body"]), "a value is in the body colour")
	runner.check(not card.pill.is_empty() and (card.pill["label"] as PxText).text == Strings.s("CHAT_CEREMONY"), "the card's pill is the thread's ceremony pill")
	card._pay.down()
	card._pay.up(true)
	runner.check(not card.closing and not m.chat._ribbon.is_empty(), "a ceremony pay from the card starts the ribbon and keeps the card open")
	card.update_view(16.0)
	runner.check((card.pill["label"] as PxText).text == Strings.s("CHAT_CEREMONY_CUTTING"), "and the card's own pill fills and reads CHAT_CEREMONY_CUTTING")
	m.chat._update_ribbon(ChatView.CEREMONY_MS + 1.0)
	runner.check(cer["state"] == "paid", "the ribbon pays")


func test_an_expired_ultimatum_chip_goes_grey() -> void:
	await _boot()
	_open_group()
	var u := _post({"type": "ultimatum", "partner": "bengvir", "price": 90.0, "kind": "money", "leftSec": 45.0,
		"state": "open", "line": "threat", "variant": 0})
	await _open_chat_now()
	var chip: Dictionary = m.chat._row_of(int(u["seq"])).get("chip", {})
	runner.check(not chip.is_empty() and (chip["root"] as Node2D).modulate.a == 1.0, "a live chip is the kit's red chip at full alpha")
	if chip.is_empty():
		return
	u["state"] = "expired"
	u["leftSec"] = 0.0
	await tree.process_frame   # the state edge rebuilds the thread: read the new row's chip
	chip = m.chat._row_of(int(u["seq"])).get("chip", {})
	if chip.is_empty():
		runner.check(false, "the expired ultimatum keeps its chip")
		return
	var root: Node2D = chip["root"]
	runner.check(root.modulate.a == 0.5, "a spent chip dims to 50%% (%.2f)" % root.modulate.a)
	var greyed := true
	for n: Node in root.get_children():
		if n is CanvasItem and (n as CanvasItem).material != ChatView.grey_material():
			greyed = false
	runner.check(greyed, "and every part of it is drawn grey (C_MUTED), not red")


func test_tapping_an_avatar_opens_the_partner_card() -> void:
	await _boot()
	_open_group()
	await _open_chat_now()
	var hit: Dictionary = {}
	for h: Dictionary in m.chat.hits():
		if h["kind"] == "partner":
			hit = h
	runner.check(not hit.is_empty(), "the first bubble's avatar is a target")
	if hit.is_empty():
		return
	_touch(_chat_pt((hit["rect"] as Rect2).get_center()))
	await tree.process_frame
	runner.check(m.overlays.has_id("PARTNER_CARD"), "a tap on the avatar opens the partner card")


func test_t3_opens_before_the_group_exists() -> void:
	await _boot()
	runner.check(not bool(m.state.coalition["opened"]), "no group yet")
	m.chat.open()
	m.chat._end_anim(true)
	for i in 3:
		await tree.process_frame   # _update_rows runs on the empty thread's one row
	runner.check(m.chat.rows().size() == 1 and float(m.chat.rows()[0]["y"]) == 16.0, "the empty thread shows CHAT_EMPTY, placed")
	m.chat.close()


func test_a_brawl_is_surfaced_with_the_chat_closed() -> void:
	await _boot()
	_open_group()
	for id in ["amsalem", "smotrich"]:
		Coalition.ps(m.state, id)["status"] = "member"
	var t: Toasts = m.toasts
	t._queue.clear()
	t._tags.clear()
	t._chats.clear()   # the round-start toasts (the leader plate) queued their tags too
	t._t = -1.0
	t._gap = 0.0
	var before := 0
	for m2: Dictionary in m.state.coalition["chat"]:
		if m2["state"] == "open" and Coalition.is_payable(m2):
			before += 1
	for e: Dictionary in Coalition.start_brawl(m.state, "amsalem", "smotrich"):
		m.chat.on_politics_event(e)
	t.update_view(16.0)
	runner.check(t.shown()["text"] == ChatView.sys_text({"key": "chat.sys.brawl", "a": "amsalem", "b": "smotrich"}) and t._tag == "chat",
		"a toast says who is brawling and that both rows are frozen (%s)" % t.shown()["text"])
	await tree.process_frame
	await tree.process_frame
	var want := Strings.s("TAB_BADGE", {"count": str(before + 1)})
	runner.check(m.shop._slots[2]["badgeText"].text == want, "the coalition tab's badge counts the brawl (%s, want %s)" % [m.shop._slots[2]["badgeText"].text, want])


func test_a_chat_toast_has_the_face_and_the_sender() -> void:
	await _boot()
	_open_group()
	var t: Toasts = m.toasts
	t._queue.clear()
	t._tags.clear()
	t._chats.clear()   # the round-start toasts (the leader plate) queued their tags too
	t._t = -1.0
	t._gap = 0.0
	var msg := _post({"type": "demand", "partner": "bengvir", "price": 90.0, "kind": "money", "join": false, "ageSec": 0.0,
		"state": "open", "line": "demand", "variant": 1})
	m.chat.on_politics_event({"ev": "message", "msg": msg})
	t.update_view(16.0)
	var sh := t.shown()
	runner.check(sh["head"] == Strings.s("TOAST_CHAT_HEAD", {"name": ChatView.partner_name("bengvir")}), "line 1 names the sender in the group (%s)" % sh["head"])
	runner.check(sh["preview"] == ChatView.line_text(msg, m.state, m.d), "line 2 is the message")
	runner.check(bool(sh["face"]), "the partner's face is in the plate's accent")
	runner.check(float(sh["h"]) == 132.0, "a chat toast is always two lines (132)")
	runner.check(t._face.position.x == Toasts.FACE_X and t._face.position.x + t._face.region_rect.size.x * t._face.scale.x <= 676.0,
		"the face sits in x 612-676 (%s)" % str(t._face.position))
	runner.check(t._preview.position.x == Toasts.CHAT_TEXT_RIGHT and not t._head.truncated(), "the lines are right-aligned at 596")
	runner.check(t._tag == "chat", "a tap on it opens T3")
