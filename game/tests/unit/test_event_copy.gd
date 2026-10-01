extends RefCounted
## Event copy on screen (2026-10-01; until then only the effects ran): a card event's toast carries
## the person's name, face and line (main._on_card_event); the leak posts its screenshot into the
## chat (Coalition.post_leak, ChatView.sys_text); the first Amsalem × Smotrich brawl speaks its
## script (Events._brawl_script, ChatView.line_text); a stage event's line crawls in the ticker;
## neutralCopy's ambient lines replace Bibi's outside his round (Leaders.ambient).

var runner: Object
var tree: SceneTree
var dir := ""
var m: Node


func setup(r: Object) -> void:
	TestFixture.use_game_content()
	tree = r as SceneTree
	dir = "user://test_event_copy_%d" % Time.get_ticks_usec()
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
	m.set_process(false)


func _start_round(id := "bibi") -> bool:
	if not m.commit_pick(id):
		return false
	for i in 2:
		m._process(0.016)
	var at: Vector2 = L.magician_hit().get_center() + Vector2(m._sx, m._stage_y)
	for pressed in [true, false]:
		var e := InputEventScreenTouch.new()
		e.position = at
		e.pressed = pressed
		m._unhandled_input(e)
	return m.mode == "main"


func _members(s: GameState, ids: Array) -> void:
	s.coalition["opened"] = true
	for id: String in ids:
		Coalition.ps(s, id)["status"] = "member"


# ------------------------------------------------------------------ pure

func test_the_first_scripted_brawl_speaks_its_lines() -> void:
	var s := GameState.fresh()
	_members(s, ["amsalem", "smotrich", "bengvir"])
	var r := Events.fire(s, "brawl", Economy.derive(s), func() -> float: return 0.5)
	runner.check(str(r["result"].get("a", "")) == "amsalem" and str(r["result"].get("b", "")) == "smotrich", "the scripted pair brawls first")
	var lines: Array = (s.coalition["chat"] as Array).filter(func(x: Dictionary) -> bool: return x.get("scriptEv", "") == "brawl")
	var script: Array = Events.event("brawl")["copy"]["script"]
	var want := script.filter(func(row: Variant) -> bool: return row is Array and ["amsalem", "smotrich"].has(str(row[0])))
	runner.check(lines.size() == want.size() and lines.size() > 0, "every line of the pair posts (%d of %d)" % [lines.size(), want.size()])
	if lines.size() > 0:
		runner.check(ChatView.line_text(lines[0], s, null) == str(want[0][1]), "the text comes from content (%s)" % ChatView.line_text(lines[0], s, null))
	var b := Coalition.open_brawl(s)
	Coalition.resolve_brawl(s, int(b["seq"]))
	var n0 := lines.size()
	Events.fire(s, "brawl", Economy.derive(s), func() -> float: return 0.5)
	var after: Array = (s.coalition["chat"] as Array).filter(func(x: Dictionary) -> bool: return x.get("scriptEv", "") == "brawl")
	runner.check(after.size() == n0, "a later brawl is the generic one (no script again)")


func test_the_leak_posts_its_screenshot_into_the_chat() -> void:
	var s := GameState.fresh()
	_members(s, ["amsalem", "smotrich", "bengvir"])
	var r := Events.fire(s, "leak", Economy.derive(s))
	var idx := int(r["result"]["leak"])
	var lines := Events.leak_lines(idx)
	runner.check(lines.size() > 0, "leak %d has lines in content" % idx)
	var out := Coalition.post_leak(s, idx, lines.size())
	var chat: Array = s.coalition["chat"]
	var frame := chat.filter(func(x: Dictionary) -> bool: return x.get("key", "") == "leak.frame")
	var rows := chat.filter(func(x: Dictionary) -> bool: return x.get("key", "") == "leak.line")
	runner.check(frame.size() == 1 and ChatView.sys_text(frame[0]) == Strings.s("LEAK_FRAME"), "the frame line: 'צילום מסך דלף'")
	runner.check(rows.size() == lines.size() and out.size() == lines.size() + 1, "one sys row per leaked line (%d)" % rows.size())
	var first := ChatView.sys_text(rows[0]) if rows.size() > 0 else ""
	runner.check(first == "%s: %s" % [str(lines[0][0]), str(lines[0][1])], "a row reads '{who}: {text}' (%s)" % first)
	for j in lines.size():
		if ["sys", "typing"].has(str(lines[j][0])):
			runner.check(ChatView.sys_text(rows[j]) == str(lines[j][1]), "a sys or typing row is the bare text")
			break
	runner.check(ChatView.thread_model(chat).filter(func(x: Dictionary) -> bool: return x["kind"] == "sys").size() >= rows.size() + 1, "the thread shows them as sys rows")


func test_neutral_ambient_replaces_bibis_line_outside_his_round() -> void:
	var nc: Dictionary = Leaders.ls().get("neutralCopy", {})
	var want := str(nc.get("ambient.p02", ""))
	runner.check(want != "", "neutralCopy has ambient.p02")
	var s := GameState.fresh()
	Politics.install(s, "bennett")
	var hit := Leaders.ambient(s).filter(func(h: Variant) -> bool: return h is Dictionary and str(h.get("id", "")) == "p02")
	runner.check(hit.size() == 1 and str(hit[0]["text"]) == want, "Bennett's round reads the neutral p02 (%s)" % str(hit))
	var b := GameState.fresh()
	Politics.install(b, "bibi")
	var orig := Leaders.ambient(b).filter(func(h: Variant) -> bool: return h is Dictionary and str(h.get("id", "")) == "p02")
	runner.check(orig.size() == 1 and str(orig[0]["text"]) != want, "Bibi's round keeps his own line")


# ------------------------------------------------------------------ the real scene

func test_a_card_event_toasts_its_name_face_and_line() -> void:
	await _boot()
	runner.check(_start_round(), "Bibi's round starts")
	var t: Toasts = m.toasts
	t._queue.clear()
	var c: Dictionary = Events.event("lapid")["copy"]
	m._on_politics_event(Events.fire(m.state, "lapid", m.d))
	var i := t._queue.find(str(c["text"]))
	runner.check(i >= 0, "Lapid's card line is queued (%s)" % str(t._queue))
	if i >= 0:
		var meta: Dictionary = t._chats[i + (t._chats.size() - t._queue.size())]
		runner.check(str(meta.get("head", "")) == str(c["name"]), "line 1 is his name (%s)" % str(meta.get("head", "")))
		runner.check(meta.get("avatar") is Array and str(meta["avatar"][0]) != "", "with his face (%s)" % str(meta.get("avatar")))
		runner.check(bool(meta.get("passive", false)), "a passive toast: no tap target")


func test_a_stage_event_runs_its_ticker_line() -> void:
	await _boot()
	runner.check(_start_round(), "Bibi's round starts")
	var line := str(Events.event("kaia")["copy"]["ticker"])
	m._on_card_event({"ev": "event", "id": "kaia", "kind": "stage", "result": {}})
	var q: Array = m.ticker._queues["flavor"]
	runner.check(str(q).contains(line), "Kaia's line is queued in the ticker (%s)" % str(q))


# ------------------------------------------------------------------ Herzog's outline (events.herzog)

func test_herzogs_outline_discounts_open_demands_when_accepted() -> void:
	var s := GameState.fresh()
	_members(s, ["amsalem", "smotrich", "bengvir"])
	var out: Array = []
	Coalition._post(s, {"type": "demand", "partner": "amsalem", "price": 100.0, "state": "open", "payable": "demand"}, out)
	Coalition._post(s, {"type": "demand", "partner": "smotrich", "price": 40.0, "state": "paid", "payable": "demand"}, out)
	Events.fire(s, "herzog", Economy.derive(s))
	runner.check(Events.is_active(s, "mediation"), "the outline stands (effect mediation)")
	var r := Events.act(s, "mediation", "accept", Economy.derive(s))
	var chat: Array = s.coalition["chat"]
	runner.check(int(r.get("cut", 0)) == 1, "one open demand re-priced (%s)" % str(r))
	runner.check(float(chat[0]["price"]) == 70.0 and float(chat[1]["price"]) == 40.0, "the open one drops 30%%, a paid one stays (%s, %s)" % [chat[0]["price"], chat[1]["price"]])
	runner.check(not Events.is_active(s, "mediation"), "accepted: the outline is gone")
	runner.check(Events.act(s, "mediation", "accept", Economy.derive(s)).is_empty(), "and cannot be accepted twice")


func test_herzogs_outline_lapses_with_an_event_end() -> void:
	var s := GameState.fresh()
	_members(s, ["amsalem", "smotrich", "bengvir"])
	Events.fire(s, "herzog", Economy.derive(s))
	var ends: Array = []
	for i in 40:
		for e: Dictionary in Events.tick(s, 0.5, Economy.derive(s), {}, func() -> float: return 0.99):
			if e.get("ev", "") == "eventEnd":
				ends.append(e.get("type", ""))
	runner.check(ends.has("mediation") and not Events.is_active(s, "mediation"), "ignored, it lapses (%s)" % str(ends))


func test_herzog_walks_in_takes_a_tap_and_walks_out() -> void:
	await _boot()
	runner.check(_start_round(), "Bibi's round starts")
	var s: GameState = m.state
	_members(s, ["amsalem", "smotrich", "bengvir"])
	var out: Array = []
	Coalition._post(s, {"type": "demand", "partner": "amsalem", "price": 100.0, "state": "open", "payable": "demand"}, out)
	m.herzog.reduced_motion = true
	m._on_politics_event(Events.fire(s, "herzog", m.d))
	var c: Dictionary = Events.event("herzog")["copy"]
	runner.check(m.toasts._queue.has(str(c["text"])), "his card line is toasted")
	for i in 3:
		m._process(0.05)
	var hz: HerzogFigure = m.herzog
	runner.check(hz.visible and hz.tappable() and hz.position == HerzogFigure.mark(), "he stands on the front-right mark")
	runner.check(not m.sara.visible, "Sara steps off her mark while he stands there")
	var at: Vector2 = hz.hit_rect().get_center() + Vector2(m._sx, m._stage_y)
	for pressed in [true, false]:
		var e := InputEventScreenTouch.new()
		e.position = at
		e.pressed = pressed
		m._unhandled_input(e)
	runner.check(not Events.is_active(s, "mediation"), "a tap on him accepts the outline")
	runner.check(float((s.coalition["chat"] as Array)[0]["price"]) == 70.0, "the open demand is 30% cheaper")
	var want := Bidi.fill(str(c["acceptText"]), {"pct": "30"})
	runner.check(m.toasts._queue.has(want) or (m.toasts._text != null and m.toasts._text.text == want), "the accept line is toasted")
	for i in 3:
		m._process(0.05)
	runner.check(not hz.visible, "and he walks out (reduced motion: at once)")


func test_herzog_shrugs_when_ignored() -> void:
	await _boot()
	runner.check(_start_round(), "Bibi's round starts")
	var s: GameState = m.state
	_members(s, ["amsalem", "smotrich", "bengvir"])
	m.herzog.reduced_motion = true
	m._on_politics_event(Events.fire(s, "herzog", m.d))
	m._process(0.05)
	Events._st(s)["active"] = (Events._st(s)["active"] as Array).filter(func(a: Dictionary) -> bool: return a["type"] != "mediation")
	m._process(0.05)
	runner.check(m.herzog.state == "shrug" and m.herzog.strip.anim == "react", "the outline lapsed: he shrugs (the react)")
