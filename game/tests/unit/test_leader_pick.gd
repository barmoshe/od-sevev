extends RefCounted
## Leader select, the views/engine slice (design/leader-select-spec.md §3, §10.1; ux/rtl-map.md §8;
## ux/screen-graph.md §0): the LEADER_PICK screen replaces the title on a fresh game, a pick writes
## and saves the round, the pre-tap state and the leader on stage, the undo chip, the picker after
## an election and after a reload mid-pick, the bloc-balanced order, and the Bibi-only views hidden
## (the press skin) in everyone else's round. Runs the real scene on the shipped design content.

var runner: Object
var tree: SceneTree
var dir := ""
var m: Node


func setup(r: Object) -> void:
	TestFixture.use_game_content()
	tree = r as SceneTree
	dir = "user://test_leader_pick_%d" % Time.get_ticks_usec()
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


func _frames(n: int) -> void:
	for i in n:
		await tree.process_frame


## A saved round `id` that has just had its election: the picker is pending (save v4).
func _saved_after_election(id: String, evo: int = 1) -> GameState:
	var s := GameState.fresh()
	Leaders.set_salt(s, 7)
	Politics.install(s, id)
	Economy.tap(s)
	s.evolutions = evo
	s.run_taps = 0
	Politics.on_election(s)
	runner.check(Leaders.pick_pending(s), "an election leaves the pick pending")
	SaveStore.new(dir).save_game(s)
	return s


func _key(k: Key) -> void:
	var e := InputEventKey.new()
	e.keycode = k
	e.pressed = true
	m._unhandled_input(e)


# ---------------------------------------------------------------------------------------------

## Bar 2026-10-01: Gantz is on the picker, as a joke. A tap shows a line about the threshold in the
## caption strip and the picker stays open: pick again.
func test_gantz_is_on_the_picker_and_sends_you_to_pick_again() -> void:
	await _boot()
	var p: PickView = m.picker
	p._age = 1000.0   # past the tap guard
	runner.check(p.decoy_btn != null, "Gantz's button is on the picker")
	var at: Vector2 = p.decoy_btn.visual.get_center()
	p.pointer_down(at)
	p.pointer_up(at)
	runner.check(m.mode == "pick" and p.visible and not p.locked, "no round starts: the picker stays open")
	runner.check(p._strip.text.contains("גנץ"), "the strip says why (%s)" % p._strip.text)
	runner.check(p.cells.all(func(c: Dictionary) -> bool: return str(c["id"]) != "gantz"), "he is never a leader tile")
	runner.check(m.commit_pick("bennett"), "and the player picks again")


func test_a_fresh_game_opens_the_picker_before_the_first_tap() -> void:
	await _boot()
	var p: PickView = m.picker
	runner.check(m.mode == "pick" and p.visible and p.variant == "first", "LEADER_PICK (first) replaces the title (mode %s)" % m.mode)
	runner.check(not m._top.visible and not m._lower.visible and not m.bb.visible, "rows A/B, the ticker, the panel and the stage figure are hidden")
	runner.check(p.cells.size() == 9 and str(p.cells[4]["id"]) == "", "3 × 3: the 8 leaders and הפתעה in the centre (%d cells)" % p.cells.size())
	runner.check(p.again_btn == null, "no again button on the first picker")
	runner.check(p.focus == 4, "the initial focus is הפתעה, never a face (rtl-map §8.5)")
	var t0: float = m.state.play_time_sec if "play_time_sec" in m.state else 0.0
	await _frames(20)
	runner.check(m.state.taps_lifetime == 0 and m.state.bananas == 0.0, "the economy is frozen while the picker shows")
	if "play_time_sec" in m.state:
		runner.check(m.state.play_time_sec == t0, "playtime does not tick under the picker")
	for c: Dictionary in p.cells:
		var t: String = (c["name"] as PxText).text
		runner.check(not t.is_valid_float(), "no numbers on a tile (%s)" % t)


func test_the_order_is_bloc_balanced() -> void:
	var s := GameState.fresh()
	var tiles: Array = Leaders.picker(s)["tiles"]
	var side := {}
	for t: Dictionary in tiles:
		side[str(t["id"])] = str(t["side"])
	for seed_ in 12:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_ + 1
		var order := PickView.arrange(tiles, func() -> float: return rng.randf())
		runner.check(order.size() == 8, "every leader placed")
		var corners := [0, 2, 5, 7].map(func(i: int) -> String: return side[order[i]])
		var edges := [1, 3, 4, 6].map(func(i: int) -> String: return side[order[i]])
		runner.check(corners.all(func(x: String) -> bool: return x == corners[0]) and edges.all(func(x: String) -> bool: return x == edges[0]) and corners[0] != edges[0],
			"a checkerboard: one bloc on the corners, the other on the edges (seed %d)" % seed_)


func test_picking_bennett_puts_him_on_stage_and_saves() -> void:
	await _boot()
	runner.check(m.commit_pick("bennett"), "the pick commits")
	runner.check(Leaders.current(m.state) == "bennett" and not Leaders.pick_pending(m.state), "the round is Bennett's")
	runner.check(m.mode == "title", "a first-launch pick lands in the pre-tap state (mode %s)" % m.mode)
	runner.check(m.bb.visible and m.bb.leader_slug() == "bennett", "his figure is on the stage (%s)" % m.bb.leader_slug())
	runner.check(m.bb.prop != null, "his pen is drawn at propMouth (not baked into the render)")
	var saved: Dictionary = SaveStore.new(dir).load_game()
	runner.check(saved.get("kind", "") == "ok" and (saved["state"] as GameState).leader == "bennett" and not (saved["state"] as GameState).leader_pick_pending,
		"the pick is saved before the stage returns")
	await _frames(2)
	runner.check(m.undo_visible(), "the undo chip is up after the pick")
	# tap 1: the pre-tap state starts the round, the prop squashes, the chip goes
	var at: Vector2 = L.magician_hit().get_center() + Vector2(m._sx, m._stage_y)
	for pressed in [true, false]:
		var e := InputEventScreenTouch.new()
		e.position = at
		e.pressed = pressed
		m._unhandled_input(e)
	runner.check(m.mode == "main" and m.state.taps_lifetime == 1, "tap 1 starts the round")
	runner.check(m.bb.prop_squashed(), "the tap squashes the prop on the pointer-down frame")
	runner.check(Leaders.stat(m.state, "bennett", "taps") == 1.0, "the tap is his")
	await _frames(2)
	runner.check(not m.undo_visible(), "the undo chip goes with the first tap")


func test_a_prop_baked_into_the_render_draws_no_loose_prop() -> void:
	await _boot()
	m.commit_pick("smotrich")
	runner.check(m.bb.leader_slug() == "smotrich" and m.bb.prop == null, "Smotrich's calculator is in the render: no loose prop")
	var mp: Vector2 = m.bb.mouth_point()
	runner.check(Ui.in_rect(Rect2(0, 0, L.W, L.stage_bottom() + 200.0), mp), "the coins leave from his propMouth (%s)" % mp)


func test_the_undo_reopens_the_same_picker() -> void:
	await _boot()
	var order: Array = m.picker.order.duplicate()
	m.commit_pick("liberman")
	await _frames(1)
	runner.check(m.undo_visible(), "the chip is up")
	m._undo_pick()
	runner.check(m.mode == "pick" and m.picker.visible, "the undo returns to the picker")
	runner.check(m.picker.order == order, "in the same order")
	runner.check(str(m.picker.cells[m.picker.focus]["id"]) == "liberman", "with the focus on the tile just picked")
	runner.check(Leaders.pick_pending(m.state) and Leaders.current(m.state) == Leaders.default_leader(), "the pick is reverted in the sim")
	runner.check(m.commit_pick("golan") and Leaders.current(m.state) == "golan", "and a new pick works")


func test_reload_mid_pick_shows_the_picker_again() -> void:
	_saved_after_election("bennett")
	await _boot()
	var p: PickView = m.picker
	runner.check(m.mode == "pick" and p.variant == "after", "a reload with leaderPickPending lands in LEADER_PICK (after)")
	runner.check(p.again_id == "bennett" and p.again_btn != null, "with 'עוד סבב עם בנט' (%s)" % p.again_id)
	runner.check(p._strip.text == Strings.s("F9_PICK"), "the first after-election picker teaches the switch (ftue.md LP)")
	runner.check(m.layer_depth() == 1, "the after picker holds one history entry")
	runner.check(m.commit_pick("liberman"), "pick ליברמן")
	runner.check(m.mode == "main" and Leaders.current(m.state) == "liberman", "straight into round 2 (mode %s)" % m.mode)
	runner.check(m.state.leader_round.get("fresh", false) == true and is_equal_approx(float(m.state.leader_round.get("freshPct", 0.0)), 10.0),
		"a new face: +10% to this round's base")
	runner.check(str(m.state.ui.get("lp", "")) == "done", "LP is done")
	var saved: Dictionary = SaveStore.new(dir).load_game()
	runner.check((saved["state"] as GameState).leader == "liberman" and not (saved["state"] as GameState).leader_pick_pending, "saved as Liberman's round")


func test_escape_after_an_election_is_again() -> void:
	_saved_after_election("golan", 2)
	await _boot()
	runner.check(m.mode == "pick", "the picker")
	m.picker._age = 1000.0
	_key(KEY_ESCAPE)
	runner.check(m.picker.locked, "Esc commits 'again'")
	m.picker.finish_now()
	runner.check(m.mode == "main" and Leaders.current(m.state) == "golan" and m.state.leader_round.get("fresh", true) == false,
		"the same leader, no fresh-face bonus")


func test_the_picker_follows_an_election() -> void:
	await _boot()
	m.commit_pick("bennett")
	m._set_mode("main", false)
	m.state.evolutions = 1
	Politics.on_election(m.state)
	await _frames(3)
	runner.check(m.mode == "pick" and m.picker.variant == "after" and m.picker.again_id == "bennett", "the picker opens after the election (mode %s)" % m.mode)
	var bank: float = m.state.bananas
	await _frames(10)
	runner.check(m.state.bananas == bank, "the new round's economy waits for the pick")
	runner.check(m.commit_pick("liberman") and m.bb.leader_slug() == "liberman", "the new leader walks in")


func test_bibi_only_views_are_hidden_for_liberman() -> void:
	await _boot()
	m.commit_pick("liberman")
	m._set_mode("main", false)
	await _frames(2)
	runner.check(not LeaderUi.court(), "Liberman's round has the press skin")
	var kinds: Array = m.dossier.buttons().map(func(b: Dictionary) -> String: return str(b["kind"]))
	runner.check(not kinds.has("pardon"), "the pardon row is hidden, not disabled (%s)" % str(kinds))
	runner.check(LeaderUi.s("HUD_SUSP") == Strings.s("PRESS_SUSP") and LeaderUi.s("COURT_TITLE") == Strings.s("PRESS_TITLE"), "the thermometer and the card say כותרות / יום תחקיר")
	runner.check(LeaderUi.s("COURT_BODY").begins_with("ליברמן"), "the press body names him (%s)" % LeaderUi.s("COURT_BODY"))
	runner.check(CourtView.excuse(1) == str(Leaders.hazard("liberman")["excuses"][0]), "his own excuse ladder")
	m.golden.spawn()
	runner.check(m.golden.key == "suitcase_plain", "no DOHA sticker: suitcase_plain (%s)" % m.golden.key)
	m.golden.clear()
	for sid: String in ["s07", "s09", "s10", "s14", "s15"]:
		runner.check(not Spins.on_shelf(m.state, Content.upgrade(sid)), "%s is off the shelf" % sid)
	m.state.investigation["aideHolding"] = 500.0
	runner.check(not Investigation.can_drop_aide(m.state), "no aide button")
	runner.check(Strings.producer_name("cigars") != Content.producer("cigars").get("name", ""), "tier 4 wears his skin (%s)" % Strings.producer_name("cigars"))


func test_bibi_keeps_the_court() -> void:
	await _boot()
	m.commit_pick("bibi")
	runner.check(LeaderUi.court() and m.dossier.buttons().any(func(b: Dictionary) -> bool: return b["kind"] == "pardon"), "Bibi's round keeps the court and the pardon row")
	runner.check(LeaderUi.s("HUD_SUSP") == Strings.s("HUD_SUSP"), "חשד")
	runner.check(m.bb.leader_slug() == "bibi" and m.bb.prop == null, "his hat is baked into his strips")


func test_libermans_decline_pill() -> void:
	await _boot()
	m.commit_pick("liberman")
	m._set_mode("main", false)
	var s: GameState = m.state
	s.coalition["opened"] = true
	Coalition.ps(s, "bennett")["status"] = "member"
	var msg := Coalition._post(s, {"type": "demand", "partner": "bennett", "price": 50.0, "kind": "money", "join": false,
		"ageSec": 0.0, "state": "open", "line": "demand", "variant": 0}, [])
	runner.check(ChatView.declinable(s, msg), "an open member demand is declinable in his round")
	m.chat.open()
	await _frames(30)
	m.chat.reveal_all()
	await _frames(3)
	var hit: Array = m.chat.hits().filter(func(h: Dictionary) -> bool: return h["kind"] == "decline")
	runner.check(hit.size() == 1, "the 'לא אשב' pill is under the pay pill (%d)" % hit.size())
	runner.check(m.chat.decline(int(msg["seq"])) and str(Coalition.message(s, int(msg["seq"]))["state"]) == "declined", "a press declines it for free")
	var sys: Array = (s.coalition["chat"] as Array).filter(func(x: Dictionary) -> bool: return x.get("key", "") == "chat.sys.declined")
	runner.check(sys.size() == 1 and ChatView.sys_text(sys[0]).contains(Strings.s("CHAT_PILL_DECLINE")), "CHAT_SYS_DECLINED (%s)" % (ChatView.sys_text(sys[0]) if sys.size() > 0 else ""))


func test_golans_merge_prompt() -> void:
	await _boot()
	m.commit_pick("golan")
	m._set_mode("main", false)
	var s: GameState = m.state
	s.coalition["opened"] = true
	for id: String in ["lapid", "bennett"]:
		Coalition.ps(s, id)["status"] = "member"
		Coalition.ps(s, id)["memberSec"] = 90.0
	m.chat.open_merge_card("lapid")
	await _frames(2)
	var o: Overlay = m.overlays.top()
	runner.check(o != null and o.id == "MERGE_CARD", "the pair prompt opens")
	runner.check(o is ChatView.MergeCard and (o as SheetCard).buttons.size() == 2, "one button per candidate, then close")
	(o as SheetCard).buttons[0].on_commit.call()
	runner.check(Coalition.status(s, "bennett") == "merged", "a pick merges them")
	var sys: Array = (s.coalition["chat"] as Array).filter(func(x: Dictionary) -> bool: return x.get("key", "") == "chat.sys.merged")
	runner.check(sys.size() == 1 and ChatView.sys_text(sys[0]) != "", "CHAT_SYS_MERGED (%s)" % (ChatView.sys_text(sys[0]) if sys.size() > 0 else ""))


## mobile-first §5.5 (D46): the thread teaches Golan's rule: a merge-ready system line with the
## "לאחד" pill under it, once per qualifying stretch, whose pill opens the pair prompt, pair first.
func test_golans_merge_ready_line() -> void:
	await _boot()
	m.commit_pick("golan")
	m._set_mode("main", false)
	var s: GameState = m.state
	s.coalition["opened"] = true
	for id: String in ["lapid", "bennett"]:
		Coalition.ps(s, id)["status"] = "member"
		Coalition.ps(s, id)["memberSec"] = 90.0
	await _frames(3)
	var ready: Array = (s.coalition["chat"] as Array).filter(func(x: Dictionary) -> bool: return x.get("key", "") == "chat.sys.merge_ready")
	runner.check(ready.size() == 1, "one merge-ready line is posted (%d)" % ready.size())
	if ready.is_empty():
		return
	runner.check(ChatView.sys_text(ready[0]) == Strings.s("CHAT_SYS_MERGE_READY", {"a": ChatView.partner_name(str(ready[0]["a"])), "b": ChatView.partner_name(str(ready[0]["b"]))}), "CHAT_SYS_MERGE_READY names the pair (%s)" % ChatView.sys_text(ready[0]))
	await _frames(3)
	var again: Array = (s.coalition["chat"] as Array).filter(func(x: Dictionary) -> bool: return x.get("key", "") == "chat.sys.merge_ready")
	runner.check(again.size() == 1, "and only once while the pair stays ready")
	m.chat.open()
	await _frames(30)
	m.chat.reveal_all()
	await _frames(3)
	var hit: Array = m.chat.hits().filter(func(h: Dictionary) -> bool: return h["kind"] == "merge")
	runner.check(hit.size() == 1 and (hit[0]["rect"] as Rect2).size == Vector2(536, 88), "the לאחד pill under it, hit 536 × 88 (%d)" % hit.size())
	if hit.is_empty():
		return
	m.chat._press = {"hit": hit[0]}
	m.chat._release_hit(true)
	await _frames(2)
	var o: Overlay = m.overlays.top()
	runner.check(o != null and o.id == "MERGE_CARD" and (o as ChatView.MergeCard).first == str(ready[0]["b"]), "its pill opens the pair prompt, that pair first")


func test_the_share_texts_and_card_follow_the_leader() -> void:
	await _boot()
	m.commit_pick("eisenkot")
	var u := "https://od-sevev.vercel.app/"
	var inv := ShareKit.share_text("invite", m.state, m.d, 0.0, u)
	runner.check(inv.contains("תורכם להקים ממשלה") and not inv.contains("ביבי"), "SHARE_TEXT_INVITE is the _NEXT text (%s)" % inv)
	runner.check(str(ShareKit.result(m.state)["sub"]).begins_with("אייזנקוט"), "the result card names the round's leader")
	runner.check(Strings.upgrade_effect("s01").contains(str(LeaderUi.tap()["verb"])), "SPIN_EFFECT_S01_LEADER in his verb (%s)" % Strings.upgrade_effect("s01"))


func test_leader_pick_sting_is_sent() -> void:
	await _boot()
	var sent: Array = []
	m.audio_sent.connect(func(n: String, a: Variant) -> void: sent.append([n, a]))
	m.commit_pick("deri")
	runner.check(sent.any(func(x: Array) -> bool: return x[0] == "leaderPick" and x[1] == "deri"), "the pick sends leaderPick (the Audio plays it if its cue table has it)")


func test_every_tap_on_the_character_sends_a_coin() -> void:
	await _boot()
	m.commit_pick("bibi")
	var sent: Array = []
	m.audio_sent.connect(func(n: String, a: Variant) -> void: sent.append([n, a]))
	var at: Vector2 = L.magician_hit().get_center() + Vector2(m._sx, m._stage_y)
	for i in 3:
		m._handle_tap(at)
	var coins := sent.filter(func(x: Array) -> bool: return x[0] == "coin")
	runner.check(coins.size() == 3, "a coin cue on every tap (%d of 3)" % coins.size())
