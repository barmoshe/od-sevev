extends RefCounted
## Coalition UX rev 5 (Bar 2026-10-02, ux/rtl-map.md §6.3): what each open line in T3 is worth
## (ui/views/chat_stakes.gd) and how the chat shows it: the stake line over a pill, a member
## demand's patience, the pill's countdown to "the bank covers it", the composer's "לסגור עם כולם",
## the brawl's frozen seats, the header's summary, the pending chip's ultimatum; plus the entry
## points Bar's playtest missed (the avatar's "i", the pinned bar's chevron and free-base badge,
## the agreement's clause icons). Pure parts on the game content; the scene parts boot main.tscn.

var runner: Object
var tree: SceneTree
var dir := ""
var m: Node


func setup(r: Object) -> void:
	TestFixture.use_game_content()
	tree = r as SceneTree
	dir = "user://test_stakes_%d" % Time.get_ticks_usec()
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


# ------------------------------------------------------------------ pure (Bibi's shipped round)

## A state with the group open and `members` in, the demand timer stopped; ultimatums unlocked
## when `unlocked`.
func _state(members: Array, unlocked: bool = false) -> GameState:
	var s := GameState.fresh()
	Leaders.ensure(s)
	s.coalition["opened"] = true
	s.coalition["nextDemandSec"] = 1e12
	if unlocked:
		s.stats["playtimeSec"] = 600.0
		s.coalition["paidLifetime"] = 5
	for id: String in members:
		Coalition.ps(s, id)["status"] = "member"
	return s


func _post(s: GameState, msg: Dictionary) -> Dictionary:
	return Coalition._post(s, msg, [])


func _demand(s: GameState, id: String, price: float, join: bool = false, age: float = 0.0) -> Dictionary:
	return _post(s, {"type": "demand", "partner": id, "price": price, "kind": "money", "join": join, "ageSec": age,
		"state": "open", "line": "demand", "variant": 0})


func _ult(s: GameState, id: String, price: float, left: float = 90.0) -> Dictionary:
	return _post(s, {"type": "ultimatum", "partner": id, "price": price, "kind": "money", "leftSec": left,
		"state": "open", "line": "threat", "variant": 0})


func test_a_join_says_the_seats_it_brings_net_on_the_bar() -> void:
	var s := _state(["smotrich"])
	Coalition.ps(s, "bengvir")["status"] = "pending"
	var j := _demand(s, "bengvir", 60.0, true)
	var before := ChatStakes.effective(s)
	var sk := ChatStakes.stake(s, j)
	runner.check(sk["kind"] == "join" and int(sk["n"]) == int(Coalition.partner("bengvir")["seats"]),
		"Ben Gvir's join demand brings his seats (%s)" % str(sk))
	runner.check(ChatStakes.effective(s) == before and Coalition.status(s, "bengvir") == "pending" and not Coalition.counts(s, "bengvir"),
		"the preview puts every row back")
	runner.check(ChatView.stake_line(s, j)[0] == Strings.plural("CHAT_STAKE_JOIN", int(sk["n"]), {"n": str(sk["n"])}), "the stake line reads +N seats")
	# Gafni brings no seats but 4 abstentions: the bar's number moves by the gate he lowers
	Coalition.ps(s, "gafni")["status"] = "pending"
	var g := _demand(s, "gafni", 60.0, true)
	var gs := ChatStakes.stake(s, g)
	runner.check(int(gs["n"]) > 0 and int(gs["n"]) == ChatStakes.effective_with(s, {"gafni": {"status": "member"}}) - before,
		"an abstainer's join counts what the HUD will show (+%d)" % int(gs["n"]))


func test_a_rejoin_counts_who_walks_out_on_the_newcomer() -> void:
	var s := _state(["abbas"])
	var ben := Coalition.partner("bengvir")
	var abb := Coalition.partner("abbas")
	runner.check(Coalition.wont_sit(ben, abb), "the content still has Ben Gvir and Abbas who won't sit together")
	Coalition.ps(s, "bengvir")["status"] = "left"
	var r := _post(s, {"type": "sys", "key": "chat.sys.left", "partner": "bengvir", "payable": "rejoin", "price": 90.0, "state": "open"})
	var n := ChatStakes.join_gain(s, "bengvir")
	runner.check(n == int(ben["seats"]) - int(abb["seats"]), "his return sends Abbas out: net %d (want %d)" % [n, int(ben["seats"]) - int(abb["seats"])])
	runner.check(ChatStakes.stake(s, r)["kind"] == "join", "a rejoin pill is a join stake")
	runner.check(Coalition.status(s, "abbas") == "member", "the preview leaves Abbas in")


func test_an_ultimatum_says_the_seats_that_walk_and_the_blackout_hides_them() -> void:
	var s := _state(["smotrich", "regev"], true)
	var u := _ult(s, "smotrich", 100.0)
	var sk := ChatStakes.stake(s, u)
	runner.check(sk["kind"] == "walk" and int(sk["n"]) == int(Coalition.partner("smotrich")["seats"]), "Smotrich walks with his seats (%s)" % str(sk))
	runner.check(ChatView.stake_line(s, u)[0] == Strings.s("CHAT_STAKE_WALK_OTHER_M", {"n": str(sk["n"])}), "his line: %s" % ChatView.stake_line(s, u)[0])
	var r := _ult(s, "regev", 0.0)
	runner.check(ChatView.stake_line(s, r)[0] == Strings.s("CHAT_STAKE_WALK_OTHER_F", {"n": str(int(Coalition.partner("regev")["seats"]))}),
		"Regev's is the feminine form (%s; %s)" % [ChatView.stake_line(s, r)[0], str(ChatStakes.stake(s, r))])
	s.calendar["mode"] = "blackout"
	runner.check(ChatView.stake_line(s, u)[0] == Strings.gendered("CHAT_STAKE_WALK_X", "m"), "the blackout drops the seat numeral (%s)" % ChatView.stake_line(s, u)[0])
	Coalition.ps(s, "bengvir")["status"] = "pending"
	runner.check(ChatView.stake_line(s, _demand(s, "bengvir", 60.0, true))[0] == "", "a join says nothing in the blackout")


func test_a_member_demand_shows_its_patience_only_when_it_can_escalate() -> void:
	var locked := _state(["smotrich"])
	var d0 := _demand(locked, "smotrich", 100.0, false, 10.0)
	runner.check(ChatStakes.stake(locked, d0)["kind"] == "", "before ultimatums unlock a demand never escalates: no clock")
	var s := _state(["smotrich", "bengvir"], true)
	var d := _demand(s, "smotrich", 100.0, false, 18.0)
	var pt := ChatStakes.stake(s, d)
	var full := Coalition._num("patienceSec", 60.0)
	runner.check(pt["kind"] == "patience" and is_equal_approx(float(pt["left"]), full - 18.0) and is_equal_approx(float(pt["frac"]), (full - 18.0) / full),
		"patience left = patienceSec - age (%s)" % str(pt))
	runner.check(ChatView.stake_line(s, d)[0] == Strings.s("CHAT_STAKE_PATIENCE", {"mmss": ChatView.mmss(full - 18.0)}), "the line counts down")
	# run out while another ultimatum is open (maxOpen 1): next in line
	d["ageSec"] = full + 5.0
	_ult(s, "bengvir", 100.0)
	var od := ChatStakes.stake(s, d)
	runner.check(bool(od["ondeck"]) and ChatView.stake_line(s, d)[0] == Strings.s("CHAT_STAKE_ONDECK"), "patience out + an open ultimatum: on deck")
	# Deri cannot leave: his demand never threatens
	Coalition.ps(s, "deri")["status"] = "member"
	runner.check(ChatStakes.stake(s, _demand(s, "deri", 100.0)).get("kind", "") == "", "a partner who cannot leave shows no clock")


func test_the_pill_counts_down_to_the_bank() -> void:
	runner.check(ChatStakes.eta_sec(100.0, 50.0, 10.0) == 0.0 and ChatStakes.eta_sec(0.0, 50.0, 0.0) == -1.0, "covered: 0; no income: -1")
	runner.check(is_equal_approx(ChatStakes.eta_sec(10.0, 50.0, 4.0), 10.0), "(50 - 10) / 4 = 10 s")
	runner.check(ChatView.pay_short_text(10.0, 50.0, 4.0) == Strings.s("CHAT_PAY_ETA", {"mmss": "0:10"}), "the pill: %s" % ChatView.pay_short_text(10.0, 50.0, 4.0))
	runner.check(ChatView.pay_short_text(10.0, 50.0, 0.0) == Strings.s("CHAT_PAY_SHORT", {"n": Fmt.cost(40.0)}), "no income: the gap in shekels")
	runner.check(ChatView.pay_short_text(0.0, 1e6, 1.0) == Strings.s("CHAT_PAY_SHORT", {"n": Fmt.cost(1e6)}), "past 15:00: the gap in shekels")


func test_pay_all_goes_by_urgency_and_never_spends_an_ultimatums_money() -> void:
	var s := _state(["smotrich", "levin", "regev", "amsalem"], true)
	Coalition.ps(s, "bengvir")["status"] = "pending"
	var dl := _demand(s, "levin", 30.0, false, 50.0)      # 10 s of patience left
	var ds := _demand(s, "smotrich", 30.0, false, 5.0)    # 55 s left
	var j := _demand(s, "bengvir", 40.0, true)           # seats
	var u := _ult(s, "amsalem", 50.0, 20.0)
	var c := _post(s, {"type": "demand", "partner": "regev", "price": 0.0, "kind": "ceremony", "join": false, "ageSec": 0.0,
		"state": "open", "line": "demand", "variant": 0})
	s.money = 1000.0
	var plan := ChatStakes.pay_all_plan(s)
	runner.check(plan == [int(u["seq"]), int(j["seq"]), int(dl["seq"]), int(ds["seq"])],
		"ultimatum, then seats, then the least patience; never the ceremony (%s)" % str(plan))
	runner.check(not plan.has(int(c["seq"])), "Regev's ribbon is hers to cut")
	runner.check(ChatStakes.plan_total(s, plan) == 150.0, "the total is the plan's prices")
	s.money = 45.0
	runner.check(ChatStakes.pay_all_plan(s).is_empty(), "an ultimatum the bank can't cover stops the plan: that money is its (%s)" % str(ChatStakes.pay_all_plan(s)))
	u["state"] = "deleted"
	runner.check(ChatStakes.pay_all_plan(s) == [int(j["seq"])], "a smaller line it can't cover is skipped: %s" % str(ChatStakes.pay_all_plan(s)))


func test_pay_all_takes_one_of_two_who_wont_sit_together() -> void:
	var s := _state([], true)
	Coalition.ps(s, "bengvir")["status"] = "pending"
	Coalition.ps(s, "abbas")["status"] = "pending"
	var jb := _demand(s, "bengvir", 10.0, true)
	var ja := _demand(s, "abbas", 10.0, true)
	s.money = 1000.0
	var plan := ChatStakes.pay_all_plan(s)
	runner.check(plan.size() == 1 and (plan[0] == int(jb["seq"]) or plan[0] == int(ja["seq"])), "never both (%s)" % str(plan))


func test_a_brawl_names_its_frozen_seats_in_the_header() -> void:
	var s := _state(["amsalem", "smotrich"])
	Coalition.start_brawl(s, "amsalem", "smotrich")
	var n := ChatStakes.frozen_seats(s, "amsalem", "smotrich")
	runner.check(n == int(Coalition.partner("amsalem")["seats"]) + int(Coalition.partner("smotrich")["seats"]), "both rows' seats are frozen (%d)" % n)
	runner.check(ChatView.header_status(s) == Strings.plural("CHAT_FROZEN", n, {"n": str(n)}) and ChatView.header_urgent(s),
		"the header says so, in the alert colour (%s)" % ChatView.header_status(s))
	s.calendar["mode"] = "blackout"
	runner.check(ChatView.header_status(s) == Strings.s("CHAT_FROZEN_X"), "no numeral in the blackout")


func test_the_header_counts_open_lines_and_threats() -> void:
	var s := _state(["smotrich", "levin"], true)
	runner.check(ChatView.header_status(s) == Strings.plural("CHAT_MEMBERS", ChatView.group_size(s)), "nothing open: the group size")
	_demand(s, "smotrich", 10.0)
	_demand(s, "levin", 10.0)
	runner.check(ChatView.header_status(s) == Strings.plural("CHAT_OPEN", 2) and not ChatView.header_urgent(s), "two open lines (%s)" % ChatView.header_status(s))
	Coalition.ps(s, "amsalem")["status"] = "member"
	_ult(s, "amsalem", 10.0)
	runner.check(ChatView.header_status(s) == Strings.plural("CHAT_THREATS", 1, {"k": "1"}) and ChatView.header_urgent(s), "a threat outranks them")


func test_the_pending_chip_names_an_ultimatum_above() -> void:
	var s := _state(["smotrich", "amsalem"], true)
	var d := _demand(s, "smotrich", 10.0)
	var u := _ult(s, "amsalem", 10.0)
	var items := [{"y": 400.0, "seq": int(d["seq"]), "kind": "pay"}, {"y": 100.0, "seq": int(u["seq"]), "kind": "pay"}]
	runner.check(ChatView.ultimatum_index(items, s) == 1, "the ultimatum's pill is found among the items above")
	u["state"] = "deleted"
	runner.check(ChatView.ultimatum_index(items, s) == -1, "a paid one is not")


func test_every_clause_has_its_own_icon() -> void:
	for p: Dictionary in Meta.perks():
		var icon := Overlays.perk_icon(str(p["icon"]))
		runner.check(icon != Art.PLACEHOLDER, "%s draws %s, not the '?' placeholder" % [p["id"], icon])
	runner.check(Overlays.perk_icon("icon_wand") == "trophy_wand", "a fork id takes the kit's trophy twin")


# ------------------------------------------------------------------ the scene

func _boot() -> void:
	m = load("res://scenes/main.tscn").instantiate()
	m.store = SaveStore.new(dir)
	tree.root.add_child(m)
	for i in 3:
		await tree.process_frame
	m.ftue.handoff_ms = 1.0
	m.commit_pick("bibi")
	_touch(m._sx + L.magician_hit().get_center().x, m._stage_y + L.magician_hit().get_center().y)


func _touch(x: float, y: float) -> void:
	for pressed in [true, false]:
		var e := InputEventScreenTouch.new()
		e.position = Vector2(x, y)
		e.pressed = pressed
		m._unhandled_input(e)


func _open_group() -> void:
	var ids := Content.producer_ids()
	for i in 3:
		m.state.owned[ids[i]] = 1
	Economy.add_money(m.state, 500.0)
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


func test_the_composer_pays_every_line_in_one_press() -> void:
	await _boot()
	_open_group()   # Ben Gvir's join demand (60 ₪)
	m.state.coalition["nextDemandSec"] = 1e12
	Coalition.ps(m.state, "smotrich")["status"] = "member"
	var d := Coalition._post(m.state, {"type": "demand", "partner": "smotrich", "price": 25.0, "kind": "money", "join": false,
		"ageSec": 0.0, "state": "open", "line": "demand", "variant": 0}, [])
	m.state.money = 1000.0
	await _open_chat_now()
	await tree.process_frame
	var chat: ChatView = m.chat
	var info := chat.pay_all_info()
	runner.check(bool(info["visible"]) and int(info["n"]) == 2 and float(info["total"]) == 85.0, "two lines covered: the composer pill shows (%s)" % str(info))
	runner.check(chat._pay_all_text.text == Strings.s("CHAT_PAY_ALL", {"price": Fmt.cost(85.0)}) and not chat._composer_text.visible,
		"it reads לסגור עם כולם with the total (%s)" % chat._pay_all_text.text)
	var hit := chat.pay_all_hit()
	var p := hit.get_center() + chat.position + Vector2(m._ox, m._lower_y)
	var bank: float = m.state.money
	_touch(p.x, p.y)
	runner.check(str(Coalition.message(m.state, int(d["seq"]))["state"]) == "paid" and Coalition.status(m.state, "bengvir") == "member",
		"one tap paid both, through the sim")
	runner.check(is_equal_approx(m.state.money, bank - 85.0), "and charged their prices (%s, from %s)" % [m.state.money, bank])
	await tree.process_frame
	await tree.process_frame
	runner.check(not bool(chat.pay_all_info()["visible"]) and chat._composer_text.visible, "nothing left: the composer's line is back")


func test_a_bubble_carries_its_stake_and_the_avatar_its_hint() -> void:
	await _boot()
	_open_group()
	m.state.coalition["nextDemandSec"] = 1e12
	await _open_chat_now()
	var chat: ChatView = m.chat
	var row: Dictionary = {}
	for r: Dictionary in chat.rows():
		if r.get("kind", "") == "in" and r.get("partner", "") == "bengvir" and r.has("stakes"):
			row = r
	runner.check(not row.is_empty(), "Ben Gvir's join bubble has a stake line")
	if not row.is_empty():
		var t: PxText = row["stakes"][0]["label"]
		runner.check(t.text == ChatView.stake_line(m.state, Coalition.open_msg(m.state, "bengvir"))[0] and not t.truncated(), "it reads %s" % t.text)
		runner.check(row.has("info") and (row["info"] as Sprite2D).texture != null, "his avatar carries the 'i'")
	runner.check(not ChatView.card_seen(m.state), "no partner card opened yet: the 'i' hints")
	chat.open_partner_card("bengvir")
	await tree.process_frame
	runner.check(ChatView.card_seen(m.state), "a card opened: the hint stops (saved in state.ui)")
	var back := GameState.from_dict(JSON.parse_string(JSON.stringify(m.state.to_dict())))
	runner.check(back.ui.get("partnerCardSeen", false) == true, "and it survives a save")


func test_the_pinned_bar_reads_as_a_button_after_the_first_election() -> void:
	await _boot()
	_open_group()
	await _open_chat_now()
	var chat: ChatView = m.chat
	runner.check(not chat._pin_chev.visible, "round 1: the pinned bar is a note, no chevron")
	m.state.evolutions = 1
	m.state.thumbs_owned = 400
	await tree.process_frame
	runner.check(chat._pin_chev.visible and chat._pin_chev.flip_h, "after an election: the '‹' at its left")
	if Meta.can_buy_any_perk(m.state):
		var free := int(m.state.thumbs_available())
		runner.check(chat._pinned_badge.visible and chat._pinned_badge_text.text == ("9+" if free > 9 else str(free)),
			"the badge shows the free base (%s)" % chat._pinned_badge_text.text)


func test_a_tap_on_the_avatar_opens_the_card() -> void:
	await _boot()
	_open_group()
	m.state.coalition["nextDemandSec"] = 1e12
	await _open_chat_now()
	var chat: ChatView = m.chat
	var hit: Dictionary = {}
	for h: Dictionary in chat.hits():
		if h["kind"] == "partner":
			hit = h
	runner.check(not hit.is_empty(), "the thread has an avatar hit")
	if hit.is_empty():
		return
	var p := chat.content_to_tall((hit["rect"] as Rect2).get_center()) + chat.position + Vector2(m._ox, m._lower_y)
	_touch(p.x, p.y)
	await tree.process_frame
	runner.check(m.overlays.is_open() and m.overlays.top().id == "PARTNER_CARD", "a tap on the avatar opens the partner card (%s)" % (m.overlays.top().id if m.overlays.is_open() else "none"))
