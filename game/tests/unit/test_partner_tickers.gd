extends RefCounted
## The partners' own ticker lines on a paid pill (main.on_partner_paid, routed from Coalition.pay's
## partnerPaid event through the chat): Gafni's onPaidTicker on a paid demand, Almog's poachTicker on
## the poach pill, nothing on a rejoin. And Bennett's flipText when a pledge runs out.

var runner: Object
var tree: SceneTree
var dir := ""
var m: Node


func setup(r: Object) -> void:
	TestFixture.use_game_content()
	tree = r as SceneTree
	dir = "user://test_partner_tickers_%d" % Time.get_ticks_usec()
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


func _boot(reduced := false) -> void:
	m = load("res://scenes/main.tscn").instantiate()
	m.store = SaveStore.new(dir)
	tree.root.add_child(m)
	for i in 3:
		await tree.process_frame
	m.ftue.handoff_ms = 1.0
	m.set_process(false)   # the test drives the clock itself
	m.settings["reducedMotion"] = reduced
	m.bb.set_reduced_motion(reduced)
	m.picker.reduced_motion = reduced
	m.street.reduced_motion = reduced


## The pick (landed, no walk), then tap 1: the round's clock runs from here.
func _start_round(id := "bibi") -> bool:
	if not m.commit_pick(id):
		return false
	_frames(2)
	var at: Vector2 = L.magician_hit().get_center() + Vector2(m._sx, m._stage_y)
	for pressed in [true, false]:
		var e := InputEventScreenTouch.new()
		e.position = at
		e.pressed = pressed
		m._unhandled_input(e)
	return m.mode == "main"


func _frames(n: int, ms := 16.0) -> void:
	for i in n:
		m._process(ms / 1000.0)


## Seats the round's partners so one small partner (1-4 seats) can be stuck; returns its id.
func test_paid_pills_queue_the_partners_ticker_lines() -> void:
	await _boot()
	runner.check(_start_round(), "Bibi's round starts")
	var gafni: Dictionary = Coalition.partner("gafni").get("copy", {})
	var almog: Dictionary = Coalition.partner("almog").get("copy", {})
	runner.check(m.on_partner_paid("gafni", "") == str(gafni["onPaidTicker"]), "a paid Gafni demand queues his tie line")
	runner.check(m.on_partner_paid("almog", "poach") == str(almog["poachTicker"]), "the poach pill queues Almog's line")
	runner.check(m.on_partner_paid("gafni", "rejoin") == "", "a rejoin pill queues nothing")
	runner.check(m.on_partner_paid("amsalem", "") == str((Coalition.partner("amsalem").get("copy", {}) as Dictionary)["onPaidTicker"]), "Amsalem's no-exclamation-mark line")
	runner.check(m.on_partner_paid("regev", "") == "", "a partner with no paid line queues nothing")


func test_a_paid_demand_emits_partner_paid() -> void:
	await _boot()
	runner.check(_start_round(), "Bibi's round starts")
	m.state.coalition["opened"] = true
	m.state.money = 1.0e9
	var out: Array = []
	Coalition._post(m.state, {"type": "demand", "partner": "gafni", "price": 10.0, "state": "open", "payable": "demand"}, out)
	var seq := int((m.state.coalition["chat"] as Array).back()["seq"])
	var r := Coalition.pay(m.state, seq)
	var ev: Array = (r.get("events", []) as Array).filter(func(x: Variant) -> bool: return x is Dictionary and x.get("ev", "") == "partnerPaid")
	runner.check(r.get("ok", false) and ev.size() == 1 and str(ev[0]["partner"]) == "gafni", "Coalition.pay reports partnerPaid (%s)" % str(r))


func test_the_pledge_flip_shows_bennetts_flip_line() -> void:
	await _boot()
	runner.check(_start_round(), "Bibi's round starts")
	var flip := str((Events.event("bennett").get("copy", {}) as Dictionary).get("flipText", ""))
	runner.check(flip != "", "the bennett event carries flipText")
	m._on_politics_event({"ev": "eventEnd", "type": "pledge"})
	_frames(2)
	var t: Toasts = m.toasts
	var shown := (t._text != null and str(t._text.text) == flip) or t._queue.has(flip)
	runner.check(shown, "the flip line is on the toast or queued for it")


func test_gotlivs_transfer_window_speaks_its_script() -> void:
	await _boot()
	runner.check(_start_round(), "Bibi's round starts")
	var s: GameState = m.state
	s.coalition["opened"] = true
	s.money = 1.0e9
	for pid: String in ["gotliv", "bengvir"]:
		Coalition.ps(s, pid)["status"] = "member"
	Coalition.ps(s, "gotliv")["meter"] = 100.0
	s.coalition["paidLifetime"] = 5                 # ultimatums unlock after 2 paid demands and 3 min of play
	s.stats["playtimeSec"] = 600.0
	var out: Array = []
	Coalition._tick_transfers(s, 0.1, Economy.derive(s), out)
	var chat: Array = s.coalition["chat"]
	var welcome := chat.filter(func(x: Dictionary) -> bool: return x.get("scriptFrom", "") == "gotliv" and x.get("partner", "") == "bengvir")
	runner.check(welcome.size() == 2, "Ben Gvir's two welcome lines post as the window opens (%d)" % welcome.size())
	runner.check(ChatView.line_text(welcome[0], s, null) == "ברוכה הבאה טלי!" if welcome.size() > 0 else false, "the text comes from content")
	runner.check(not ChatView.line_text(welcome[1], s, null).contains("ביבי") if welcome.size() > 1 else false, "no '@ביבי': the transfer also fires in other leaders' rounds")
	var ult := chat.filter(func(x: Dictionary) -> bool: return x.get("type", "") == "ultimatum" and x.get("transfer", "") == "gotliv")
	runner.check(ult.size() == 1, "the 90 s transfer ultimatum is open")
	if ult.size() == 1:
		var r := Coalition.pay(s, int(ult[0]["seq"]))
		var thanks := (s.coalition["chat"] as Array).filter(func(x: Dictionary) -> bool: return x.get("scriptFrom", "") == "gotliv" and x.get("partner", "") == "gotliv")
		runner.check(r.get("ok", false) and thanks.size() == 1 and ChatView.line_text(thanks[0], s, null).begins_with("תודה איתמר"), "paid: Gotliv's own thanks line")
	for e: Variant in out:
		m._on_politics_event(e)
	var q: Array = m.ticker._queues["flavor"]
	runner.check(q.any(func(x: Dictionary) -> bool: return str(x["text"]).begins_with("מבזק ספורט")), "the sports-flash ticker line is queued")
