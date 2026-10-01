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
	var line := str(Events.event("pinkfront")["copy"]["ticker"])
	m._on_card_event({"ev": "event", "id": "pinkfront", "kind": "stage", "result": {}})
	var q: Array = m.ticker._queues["flavor"]
	runner.check(str(q).contains(line), "the Pink Front's line is queued in the ticker (%s)" % str(q))


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


# ------------------------------------------------------------------ Kaia (events.kaia, placeholder art)

func test_kaia_trots_in_and_a_tap_feeds_her() -> void:
	await _boot()
	runner.check(_start_round(), "Bibi's round starts")
	var s: GameState = m.state
	_members(s, ["amsalem", "smotrich", "bengvir"])
	m.kaia.reduced_motion = true
	m._on_politics_event(Events.fire(s, "kaia", m.d))
	var c: Dictionary = Events.event("kaia")["copy"]
	runner.check(m.toasts._queue.has(str(c["text"])), "her line is toasted on arrival (%s)" % str(m.toasts._queue))
	runner.check(not str(m.ticker._queues["flavor"]).contains(str(c["nipTicker"])), "the nip headline waits for a nip")
	for i in 3:
		m._process(0.05)
	var k: KaiaFigure = m.kaia
	runner.check(m.diorama.era_id() == "balfour" and k.visible and k.tappable() and k.position == KaiaFigure.mark(), "she stands on the front-left mark in Balfour")
	var at: Vector2 = k.hit_rect().get_center() + Vector2(m._sx, m._stage_y)
	for pressed in [true, false]:
		var e := InputEventScreenTouch.new()
		e.position = at
		e.pressed = pressed
		m._unhandled_input(e)
	runner.check(not Events.is_active(s, "kaia") and Events.is_active(s, "kaiaBuff"), "a tap feeds her: the nip becomes the tap buff")
	var want := Bidi.fill(str(c["feedText"]), {"sec": str(int(Events.event("kaia")["effect"]["buffSec"]))})
	runner.check(m.toasts._queue.has(want) or (m.toasts._text != null and m.toasts._text.text == want), "the cucumber line is toasted (%s)" % want)
	runner.check(k.state == "fed", "she holds the cucumber")
	for i in 25:
		m._process(0.05)
	runner.check(not k.visible, "then she trots off")


func test_an_ignored_kaia_nip_is_toasted_and_headlined() -> void:
	await _boot()
	runner.check(_start_round(), "Bibi's round starts")
	var c: Dictionary = Events.event("kaia")["copy"]
	m.toasts._queue.clear()
	m._on_politics_event({"ev": "kaiaNip", "partner": "amsalem"})
	var want := Bidi.fill(str(c["nipText"]), {"name": ChatView.partner_name("amsalem")})
	runner.check(m.toasts._queue.has(want), "the nip names the minister (%s)" % str(m.toasts._queue))
	runner.check(str(m.ticker._queues["flavor"]).contains(str(c["nipTicker"])), "and the nip headline runs")


# ------------------------------------------------------------------ no taps on the court / press day (Bar 2026-10-01)

func _tap_leader() -> void:
	var at: Vector2 = L.magician_hit().get_center() + Vector2(m._sx, m._stage_y)
	for pressed in [true, false]:
		var e := InputEventScreenTouch.new()
		e.position = at
		e.pressed = pressed
		m._unhandled_input(e)


func _hazard_day_blocks_taps(leader: String, want: String) -> void:
	await _boot()
	runner.check(_start_round(leader), "%s's round starts" % leader)
	var s: GameState = m.state
	runner.check(bool(Investigation.cfg().get("courtPausesTaps", false)), "content: courtPausesTaps is on")
	s.investigation["phase"] = "court"
	s.investigation["leftSec"] = 30.0
	m.d = Economy.derive(s)
	m.toasts._queue.clear()
	var bank := s.bananas
	var taps := s.taps_lifetime
	m._last_tap_ms = -1.0e9
	_tap_leader()
	runner.check(s.bananas == bank and s.taps_lifetime == taps, "%s: a tap on the hazard day earns and counts nothing" % leader)
	runner.check(m.toasts._queue.has(want), "%s: the toast says why (%s)" % [leader, str(m.toasts._queue)])
	m._last_tap_ms = -1.0e9
	_tap_leader()
	runner.check(m.toasts._queue.count(want) == 1, "%s: at most one such toast every 4 s" % leader)


func test_no_taps_while_bibi_testifies() -> void:
	await _hazard_day_blocks_taps("bibi", Strings.s("COURT_TAP_PAUSED"))


func test_no_taps_on_another_leaders_press_day() -> void:
	# each leader's own line (kit.hazard.tapPaused), not the generic press twin
	await _hazard_day_blocks_taps("bennett", str(Leaders.hazard("bennett")["tapPaused"]))


## Bar, 2026-10-01 ("not only Bibi"): every leader leaves the stage on the hazard day. Bibi leaves the
## hat on his mark; everyone else leaves a PressDesk (Deri: the corridor bench). A tap during the day
## wiggles what is on the mark and never plays the leader's tap strip.
func test_every_leader_leaves_the_stage_on_the_hazard_day() -> void:
	var base := dir
	for lid: String in Leaders.pickable():
		# a fresh game per leader (its own save dir), so every round starts from the picker
		teardown()
		dir = "%s_%s" % [base, lid]
		DirAccess.make_dir_recursive_absolute(dir)
		await _boot()
		runner.check(_start_round(lid), "%s's round starts" % lid)
		var s: GameState = m.state
		s.investigation["phase"] = "court"
		s.investigation["leftSec"] = 30.0
		m.d = Economy.derive(s)
		for i in 180:
			m._process(0.016)
		var skin := LeaderUi.stage_skin(lid)
		runner.check(m.bb.court.in_court(), "%s: off the stage on the hazard day" % lid)
		runner.check(m.bb.court_skin == skin, "%s: the mark holds %s (got %s)" % [lid, skin, m.bb.court_skin])
		var desk: PressDesk = m.bb.desk_node()
		if skin == "court":
			runner.check(m.bb.hat_node().visible and not desk.visible, "%s: the hat on the mark, no desk" % lid)
		else:
			runner.check(desk.visible and desk.kind == skin and not m.bb.hat_node().visible, "%s: the %s on the mark, no hat" % [lid, skin])
		m._last_tap_ms = -1.0e9
		_tap_leader()
		runner.check(m.bb.hero.anim != "tap" and m.bb.court.hat == "hatHush", "%s: a tap hushes the mark, the strip stays still" % lid)
		s.investigation["phase"] = "idle"
		m.d = Economy.derive(s)
		for i in 120:
			m._process(0.016)
		runner.check(not m.bb.court.in_court(), "%s: back on the mark when the day ends" % lid)
		runner.check(lid != "deri" or skin == "bench", "deri sits on the corridor bench")


## Leaders v3 phase 2: the ability chip is on the stage, a tap on it uses the ability. Ben Gvir's
## "אני פורש" walks him off like a press day and leaves his cardboard box on the mark; no taps while out.
func test_the_ability_chip_walks_ben_gvir_out() -> void:
	await _boot()
	runner.check(_start_round("bengvir"), "Ben Gvir's round starts")
	for i in 3:
		m._process(0.016)
	runner.check(m.ability_chip.visible and m.ability_chip.takes_tap(m.ability_chip.hit_rect().get_center()), "the chip is up and ready")
	var at: Vector2 = m.ability_chip.hit_rect().get_center() + Vector2(m._sx, m._stage_y)
	for pressed in [true, false]:
		var e := InputEventScreenTouch.new()
		e.position = at
		e.pressed = pressed
		m._unhandled_input(e)
	runner.check(Ability.walked_out(m.state), "a tap on the chip: he walks out")
	for i in 180:
		m._process(0.016)
	runner.check(m.bb.court.in_court() and m.bb.desk_node().visible and m.bb.desk_node().kind == "box", "off the stage, his box on the mark")
	m.toasts._queue.clear()
	m._last_tap_ms = -1.0e9
	_tap_leader()
	runner.check(m.toasts._queue.has(str(Ability.copy(m.state)["tapPaused"])), "a tap while he is out says so (%s)" % str(m.toasts._queue))
