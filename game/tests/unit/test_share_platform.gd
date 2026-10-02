extends RefCounted
## The share platform (Bar 2026-10-02): the rounds' history (RoundLog: a record per election, saved,
## old saves without one), the models and the copy rules of every kind (a Hebrew word first, ≤ 200
## chars, no em dash, the link alone on the last line, the family-safe variant names no leader, the
## election silence keeps 61 off the card), the stub paths, the cards' node trees in every format,
## ShareKit.request off the web (the canvas sheet on any kind), the prompt's frequency caps, T4's
## career row. The real scene boots on the game content with a throwaway save folder.

var runner: Object
var tree: SceneTree
var dir := ""
var m: Node


func setup(r: Object) -> void:
	TestFixture.use_game_content()
	tree = r as SceneTree
	dir = "user://test_sharep_%d" % Time.get_ticks_usec()
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
	m.commit_pick("bibi")
	m._set_mode("main", false)


## A veteran's state: Bibi's round with a seeded group chat, the gate at 7:42, 4 past rounds.
func _veteran() -> GameState:
	var s := GameState.fresh()
	Leaders.set_salt(s, 3)
	Politics.install(s, "bibi")
	s.evolutions = 4
	s.run_time_sec = 700.0
	s.run_bananas = 3.0e6
	s.all_time_bananas = 5.0e7
	for id in Content.producer_ids().slice(0, 4):
		s.owned[id] = 10
	ShareDesk.seed_demo_chat(s)
	s.round_log = {"gateSec": 462.0, "court0": 0, "left0": 0}
	for i in 4:
		s.history.append({"n": i + 1, "leader": ["bibi", "bennett", "deri", "bibi"][i], "sec": 900.0 - 50.0 * i, "gate": 800.0 - 100.0 * i,
			"earned": 1.0e6, "top": Content.producer_ids()[0], "topPct": 0.5, "paid": 3, "mvp": "smotrich", "left": 1, "court": 1, "post": 0})
	return s


# ------------------------------------------------------------------ the history (RoundLog)

func test_an_election_writes_a_record_and_the_save_keeps_it() -> void:
	var s := GameState.fresh()
	Politics.install(s, "bibi")
	s.run_time_sec = 321.0
	s.run_bananas = 99000.0
	var d := Economy.derive(s)
	d.seats_gate_open = true
	s.run_time_sec = 200.0
	RoundLog.on_tick(s, d)
	s.run_time_sec = 321.0
	RoundLog.on_tick(s, d)
	runner.check(is_equal_approx(RoundLog.gate_sec(s), 200.0), "the gate's FIRST second is kept (%s)" % RoundLog.gate_sec(s))
	s.investigation["courtDays"] = 2
	s.coalition["paidRound"] = 5
	var rec := RoundLog.record(s, d)
	runner.check(s.history.size() == 1 and int(rec["n"]) == 1 and str(rec["leader"]) == "bibi" and is_equal_approx(float(rec["gate"]), 200.0)
		and is_equal_approx(float(rec["sec"]), 321.0) and int(rec["court"]) == 2 and int(rec["paid"]) == 5, "the record (%s)" % rec)
	RoundLog.start_round(s)
	runner.check(RoundLog.gate_sec(s) < 0.0 and int(s.round_log["court0"]) == 2, "the next round starts its own marks (%s)" % s.round_log)
	s.investigation["courtDays"] = 3
	runner.check(int(RoundLog.current(s)["court"]) == 1, "a round counts only its own court days")
	# the save
	var back := GameState.from_dict(JSON.parse_string(JSON.stringify(s.to_dict())))
	runner.check(back.history.size() == 1 and str(back.history[0]["leader"]) == "bibi" and is_equal_approx(float(back.history[0]["gate"]), 200.0),
		"the history survives a save (%s)" % [back.history])
	runner.check(int(back.round_log["court0"]) == 2, "the round's marks survive a save")
	# an old save: no history, no marks
	var old := s.to_dict()
	old.erase("history")
	old.erase("roundLog")
	var o := GameState.from_dict(old)
	runner.check(o.history.is_empty() and RoundLog.gate_sec(o) < 0.0, "an old save loads with an empty history")
	var junk := s.to_dict()
	junk["history"] = [{"n": "x", "leader": 5}, 7, {"gate": 12.0, "leader": "deri"}]
	var j := GameState.from_dict(junk)
	runner.check(j.history.size() == 2 and str(j.history[0]["leader"]) == "" and str(j.history[1]["leader"]) == "deri", "a broken history is cleaned, not trusted")


func test_the_history_is_capped_and_the_career_adds_up() -> void:
	var s := GameState.fresh()
	for i in RoundLog.MAX + 7:
		s.history.append({"n": i + 1, "leader": "bibi" if i % 3 else "golan", "gate": 300.0 + i, "sec": 400.0 + i, "mvp": "deri" if i % 2 else "smotrich", "left": 1})
		if s.history.size() > RoundLog.MAX:
			s.history = s.history.slice(s.history.size() - RoundLog.MAX)
	runner.check(RoundLog.sanitize_history(s.history).size() == RoundLog.MAX, "at most %d records" % RoundLog.MAX)
	s.evolutions = 200
	s.leaders = {"bibi": {"rounds": 9.0}, "golan": {"rounds": 4.0}}
	var c := RoundLog.career(s)
	runner.check(int(c["rounds"]) == 200 and str(c["leader"]) == "bibi" and is_equal_approx(float(c["fastest"]), 307.0) and int(c["walked"]) == RoundLog.MAX,
		"the career: rounds, the favourite (by rounds played), the fastest gate, the walkouts (%s)" % c)
	runner.check(RoundLog.title_tier(0) == 0 and RoundLog.title_tier(3) == 2 and RoundLog.title_tier(10) == 4 and RoundLog.title_tier(30) == 5, "the rank tiers")
	# an old save: what the lifetime stats can say
	var o := GameState.fresh()
	o.evolutions = 6
	o.stats["fastestRunSec"] = 512.0
	o.leaders = {"deri": {"rounds": 6.0}}
	var oc := RoundLog.career(o)
	runner.check(not bool(oc["fromHistory"]) and int(oc["rounds"]) == 6 and is_equal_approx(float(oc["fastest"]), 512.0) and str(oc["leader"]) == "deri",
		"an old save's career comes from the lifetime stats (%s)" % oc)


# ------------------------------------------------------------------ the models and the copy

func test_every_kind_has_a_model_and_its_copy_follows_the_rules() -> void:
	var s := _veteran()
	var d := Economy.derive(s)
	var exts := {"challenge": {"leader": "bibi", "secs": 462.0, "url_hash": "s=1&t=462"}, "daily": {"n": 17, "grid_text": "🟩🟨\n🟥🟩"}}
	var shorts: Array = ShareKit.STUB_LEADERS.map(func(id: String) -> String: return ShareKit.short_of(id))
	for kind: String in ShareKit.DRAWER_KINDS:
		for neutral: bool in [false, true]:
			for rot in 4:
				var mo := ShareKit.model(kind, s, d, exts.get(kind, {}), {"neutral": neutral, "rot": rot})
				var t := str(mo["text"])
				var tag := "%s%s #%d" % [kind, " (family)" if neutral else "", rot]
				runner.check(t != "" and not t.contains("{") and not t.contains("\u2066") and not t.contains("\u2014"), "%s: filled prose, no isolates, no em dash (%s)" % [tag, t])
				runner.check(kind == "daily" or t.length() <= 200, "%s: ≤ 200 chars" % tag)
				var first := t.unicode_at(0)
				runner.check(first >= 0x05D0 and first <= 0x05EA, "%s: starts with a Hebrew letter (%s)" % [tag, t.left(12)])
				runner.check(not t.contains("http") and str(mo["stub"]).begins_with("s/"), "%s: no link in the text (the drawer adds it), a stub (%s)" % [tag, mo["stub"]])
				if neutral and kind != "receipt" and kind != "result" and kind != "daily":
					for sh: String in shorts:
						runner.check(not t.contains(sh), "%s: names no leader (%s in %s)" % [tag, sh, t])
					runner.check(str(mo["leader"]) == "" and str(mo["stub"]).begins_with("s/all-"), "%s: no face, the neutral stub (%s)" % [tag, mo["stub"]])
	var msg := ShareKit.compose("טקסט", "https://od-sevev.vercel.app/s/bibi-leak/?via=wa#r=abcdefgh&k=leak")
	runner.check(msg.split("\n").size() == 2 and msg.split("\n")[1].begins_with("https://"), "the link alone on the last line")
	runner.check(ShareKit.model("challenge", s, d, exts["challenge"])["hash"] == "s=1&t=462", "the caller's url_hash rides along")
	runner.check(ShareKit.model("daily", s, d, exts["daily"])["text"].contains("🟩🟨"), "the daily's text-only share carries the grid")


func test_the_stub_paths() -> void:
	runner.check(ShareKit.stub_path("breaking", "bibi", "gate") == "s/bibi-61/", "the gate is <leader>-61")
	runner.check(ShareKit.stub_path("breaking", "bibi", "court") == "s/bibi-breaking/", "a court day is <leader>-breaking")
	runner.check(ShareKit.stub_path("leak", "smotrich", "", true) == "s/all-leak/", "family-safe: all-<kind>")
	runner.check(ShareKit.stub_path("receipt", "bibi") == "s/all-receipt/", "the receipt is leader-neutral")
	runner.check(ShareKit.stub_path("daily", "bibi") == "s/daily/", "the daily has one stub")
	runner.check(ShareKit.stub_path("term", "gantz") == "s/all-term/", "an unknown leader falls back to all-")
	var vs := ShareKit.og_variants()
	runner.check(vs.size() == ShareKit.STUB_LEADERS.size() * ShareKit.STUB_OUTCOMES.size() + ShareKit.NEUTRAL_STUBS.size() + 1, "a variant per stub (%d)" % vs.size())
	for name: String in vs:
		var h := str(vs[name]["head"])
		runner.check(h != "" and h.unicode_at(0) >= 0x05D0 and h.unicode_at(0) <= 0x05EA and not h.contains("{"), "og:title %s starts with a Hebrew word (%s)" % [name, h])
	for kind: String in ShareKit.DRAWER_KINDS:
		for lid: String in ShareKit.STUB_LEADERS:
			for ev: String in ["", "gate", "court", "election"]:
				for neutral: bool in [false, true]:
					var v := ShareKit.stub_path(kind, lid, ev, neutral).trim_prefix("s/").trim_suffix("/")
					runner.check(vs.has(v), "every share links an existing stub (%s %s %s → %s)" % [kind, lid, ev, v])


func test_the_leak_picks_the_rounds_juiciest_lines() -> void:
	var s := _veteran()
	var lines := ShareKit.leak_lines(s)
	runner.check(lines.size() >= 3 and lines.size() <= 6, "3-6 lines (%d)" % lines.size())
	var hot := lines.filter(func(l: Dictionary) -> bool: return bool(l["hot"]))
	runner.check(hot.size() >= 1, "the ultimatum is in")
	runner.check(lines.any(func(l: Dictionary) -> bool: return l["kind"] == "sys"), "a walkout / the brawl is in")
	var n := ShareKit.leak_lines(s, true)
	for l: Dictionary in n:
		runner.check(str(l["char"]) == "", "family-safe: no faces")
		for p: Dictionary in Coalition.partners():
			runner.check(not str(l["text"]).contains(ChatView.partner_name(str(p["id"]))) and str(l["who"]) != ChatView.partner_name(str(p["id"])),
				"family-safe: no partner's name (%s)" % l)
	var empty := GameState.fresh()
	Politics.install(empty, "bibi")
	runner.check(ShareKit.leak_lines(empty).is_empty() and not ShareKit.kinds_for(empty).has("leak"), "no chat, no leak tab")
	runner.check(ShareKit.kinds_for(empty) == ["receipt", "result"], "a fresh round offers the receipt and the result (%s)" % [ShareKit.kinds_for(empty)])
	runner.check(ShareKit.kinds_for(s) == ["leak", "breaking", "term", "career", "receipt", "result"], "a veteran's round offers every kind (%s)" % [ShareKit.kinds_for(s)])


func test_the_election_silence_keeps_61_off_the_breaking_card() -> void:
	var s := _veteran()
	var mo := ShareKit.model("breaking", s, Economy.derive(s), {}, {"event": "gate"})
	runner.check(str(mo["head"]).contains("7:42") and str(mo["event"]) == "gate", "the gate's headline carries the round's clock (%s)" % mo["head"])
	var root := Node2D.new()
	mo["quiet"] = true
	ShareCards.build(root, "breaking", mo, "sq")
	var texts := _texts(root)
	runner.check(not texts.any(func(t: String) -> bool: return t.contains("61")), "in the silence the channel is not ערוץ 61 (%s)" % [texts])
	root.free()


# ------------------------------------------------------------------ the cards

func test_every_card_builds_in_every_format_with_the_url_and_the_stamp() -> void:
	var s := _veteran()
	var d := Economy.derive(s)
	var exts := {"challenge": {"leader": "bibi", "secs": 462.0}, "daily": {"n": 3, "grid_text": "🟩🟨🟥\n🟩🟩🟩"}}
	var host := ShareKit.display_host(ShareKit.site_url())
	for kind: String in ShareKit.DRAWER_KINDS:
		for fmt: String in ["sq", "story"]:
			var root := Node2D.new()
			var mo := ShareKit.model(kind, s, d, exts.get(kind, {}))
			ShareDesk.build_card(root, kind, mo, fmt, s, d)
			var texts := _texts(root)
			runner.check(texts.any(func(t: String) -> bool: return t.contains(host)), "%s %s: the URL is on the image" % [kind, fmt])
			if ShareCards.KINDS.has(kind) or fmt == "story":
				runner.check(texts.any(func(t: String) -> bool: return t.contains(Strings.s("CARD_SATIRE")) or t.contains(Strings.s("RESULT_DISC"))),
					"%s %s: the satire stamp" % [kind, fmt])
			var trunc := _truncated(root)
			runner.check(trunc.is_empty(), "%s %s: no line cut short (%s)" % [kind, fmt, trunc])
			root.free()
	runner.check(ShareCards.size_of("sq") == Vector2i(1080, 1350) and ShareCards.size_of("story") == Vector2i(1080, 1920) and ShareCards.size_of("og") == Vector2i(1200, 630), "the formats")
	runner.check(ShareCards.grid_rows("🟩🟨x\n\n🟥") .size() == 2, "the daily grid's rows (unknown glyphs dropped)")
	for name: String in ["bibi-61", "all-term", "daily", "smotrich-challenge"]:
		var r2 := Node2D.new()
		ShareCards.build(r2, "og", ShareKit.og_variants()[name], "og")
		runner.check(_truncated(r2).is_empty() and _texts(r2).has(str(ShareKit.og_variants()[name]["head"])), "og %s: the whole headline" % name)
		r2.free()


func _texts(n: Node) -> Array:
	var out: Array = []
	for c in n.get_children():
		if c is PxText:
			out.append((c as PxText).text)
		out.append_array(_texts(c))
	return out


func _truncated(n: Node) -> Array:
	var out: Array = []
	for c in n.get_children():
		if c is PxText and (c as PxText).truncated():
			out.append((c as PxText).text)
		out.append_array(_truncated(c))
	return out


# ------------------------------------------------------------------ the desk in the scene

func test_request_off_the_web_opens_the_canvas_sheet_on_any_kind() -> void:
	await _boot()
	runner.check(ShareKit.desk == m.share_desk, "main's desk is ShareKit's")
	m.state.history.append({"n": 1, "leader": "bibi", "gate": 300.0, "sec": 400.0})
	m.state.evolutions = 1
	for kind: String in ["career", "challenge"]:
		var ok := ShareKit.request(kind, {"leader": "bibi", "secs": 300.0} if kind == "challenge" else {})
		await tree.process_frame
		var t = m.overlays.top()
		runner.check(ok and t is ShareSheet and t.kind == kind and t.id == "SHARE_" + kind.to_upper(), "%s: the canvas sheet opens (%s)" % [kind, t])
		if t is ShareSheet:
			runner.check(t.text_to_share.split("\n").size() == 2 and t.text_to_share.split("\n")[1].begins_with(ShareKit.site_url() + "s/"), "%s: the message ends with its stub link" % kind)
			runner.check(t.card_root() == null or t.card_root().get_child_count() > 0, "%s: the card was built" % kind)
		m.overlays.back()
		for i in 12:
			await tree.process_frame
	runner.check(not ShareKit.request("nope"), "an unknown kind is refused")


func test_the_prompt_waits_for_a_calm_beat_and_backs_off() -> void:
	await _boot()
	var dk: ShareDesk = m.share_desk
	dk.share_prefs().clear()
	dk.note_moment("leak")
	dk.tick(500.0, true, true, false)
	runner.check(not dk.prompted, "never at the moment's peak (a beat first)")
	dk.tick(3000.0, false, true, false)
	runner.check(not dk.prompted, "never while it's not calm (a tap burst, an overlay)")
	dk.tick(100.0, true, true, false)
	runner.check(dk.prompted and dk.prompt_kind == "leak", "the advisor's prompt after the beat")
	runner.check(m.toasts._tags.has("share") or m.toasts._tag == "share", "the prompt is the advisor's chat toast (tag share)")
	dk.note_moment("term")
	dk.tick(5000.0, true, true, false)
	runner.check(dk.moment == "term" and dk.prompt_kind == "leak", "one proactive prompt a session: the next moment only lights the dot")
	dk.tick(ShareDesk.IGNORED_MS + 10.0, true, true, false)
	runner.check(int(dk.share_prefs().get("dismiss", 0)) == 1, "a prompt nobody opened counts as dismissed")
	# a new session: the back-off holds until 2 more elections
	dk.prompted = false
	dk.note_moment("leak")
	dk.tick(3000.0, true, true, false)
	runner.check(not dk.prompted, "after a dismissal, no prompt until two more elections")
	m.state.evolutions = int(dk.share_prefs().get("promptAt", 0)) + 2
	dk.note_moment("leak")
	dk.tick(3000.0, true, true, false)
	runner.check(dk.prompted, "two elections later it may prompt again")
	dk.prompted = false
	dk.share_prefs()["dismiss"] = ShareDesk.MAX_DISMISS
	m.state.evolutions = 99
	dk.note_moment("leak")
	dk.tick(3000.0, true, true, false)
	runner.check(not dk.prompted, "after %d dismissals no proactive prompt at all" % ShareDesk.MAX_DISMISS)
	dk.on_election(3)
	runner.check(dk.moment == "career", "round 3 offers the career, not the term")
	dk.on_election(4)
	runner.check(dk.moment == "term", "round 4 offers the term summary")
	dk.on_politics_event({"ev": "message", "msg": {"type": "ultimatum"}})
	runner.check(dk.moment == "leak", "an ultimatum is a leak moment")
	dk.on_politics_event({"ev": "courtStart"})
	runner.check(dk.moment == "breaking" and dk.moment_event == "court", "a court day is breaking news")


func test_the_chip_and_t4s_career_row() -> void:
	await _boot()
	var dk: ShareDesk = m.share_desk
	runner.check(dk.chip != null and dk.chat_btn != null, "the 📣 chip and T3's twin are built")
	m._process(0.016)
	runner.check(not dk.chip.visible, "hidden before the group opens (the first minute stays clean)")
	m.state.evolutions = 1
	m._process(0.016)
	runner.check(dk.chip.visible, "shown once there was an election")
	var c := dk.chip.position + dk.chip.rect.get_center()
	runner.check(dk.chip_takes(c) and not Ui.in_rect(L.magician_hit(), c), "its hit is clear of the leader's (%s)" % c)
	runner.check(dk.chip.rect.end.y <= float(L.STAGE["y"]) + L.stage_h - 136.0, "above the lane band")
	m.state.history.append({"n": 1, "leader": "bibi"})
	var kinds: Array = m.dossier.buttons().map(func(b: Dictionary) -> String: return b["kind"])
	runner.check(kinds.slice(0, 3) == ["receipt", "result", "career"], "T4: the receipt, the result, then the career (%s)" % [kinds])


## The seeded rounds through the drawer (RoundShare.platform_model): a first challenge takes the
## platform's copy with the round's time and hash (no k= / r=, the drawer adds its own); a return
## link keeps its win line and sends its own time; the daily keeps its whole grid text; none of
## them carries the URL in the prose. A link's hash parses back into the same challenge.
func test_the_rounds_hand_the_drawer_its_model() -> void:
	var ch := {"leader": "bibi", "seed": 12345, "t": 462, "ref": "abcd2345"}
	var h := Challenge.build_hash(ch)
	var url := "https://od-sevev.vercel.app/s/bibi-challenge#" + h
	var offer := RoundShare.platform_model("challenge", ch.merged({"hash": h, "url": url, "result": "", "vs": -1, "text": "הגעתי ל־61. " + url}))
	runner.check(offer["secs"] == 462.0 and offer["seed"] == 12345 and offer["leader"] == "bibi", "the offer: leader, seed, time (%s)" % [offer])
	runner.check(offer["url_hash"] == "l=bibi&s=12345&t=462", "the offer's hash without k= and r= (%s)" % offer["url_hash"])
	runner.check(not offer.has("text"), "the offer takes the platform's copy")
	var om := ShareKit.model("challenge", GameState.fresh(), null, offer)
	runner.check(str(om["text"]).contains("7:42") and not str(om["text"]).contains("http"), "the platform's line has the time and no URL (%s)" % om["text"])
	var back := Challenge.parse(Challenge.parse_pairs("r=abcd2345&k=challenge&" + offer["url_hash"] + "&v=bibi-challenge"))
	runner.check(back.get("seed") == 12345 and back.get("t") == 462 and back.get("ref") == "abcd2345", "the drawer's link parses back (%s)" % [back])
	var ret := RoundShare.platform_model("challenge", ch.merged({"hash": h + "&vs=462", "url": url, "result": "win", "mine": 401, "theirs": 462, "text": "עברתי אותך: 6:41 מול 7:42. " + url}))
	runner.check(ret["secs"] == 401.0 and str(ret["url_hash"]).ends_with("vs=462"), "the return link: my time, vs kept (%s)" % [ret])
	var rm := ShareKit.model("challenge", GameState.fresh(), null, ret)
	runner.check(rm["text"] == "עברתי אותך: 6:41 מול 7:42.", "the return link keeps its own line, URL out (%s)" % rm["text"])
	var daily := RoundShare.platform_model("daily", {"n": 7, "grid": ["🟦🟦🟨", "🟥⬜"], "url": "od-sevev.vercel.app/s/daily",
		"text": "עוד סבב #7 🗳️\n🟦🟦🟨\n🟥⬜\n61 ⏱️ 7:42\nod-sevev.vercel.app/s/daily"})
	runner.check(daily["n"] == 7 and daily["grid_text"] == "🟦🟦🟨\n🟥⬜" and daily["url_hash"] == "", "the daily: n, the grid (%s)" % [daily])
	var dm := ShareKit.model("daily", GameState.fresh(), null, daily)
	runner.check(str(dm["text"]).ends_with("7:42") and str(dm["text"]).contains("🟦🟦🟨") and dm["stub"] == "s/daily/", "the daily's text is its grid, URL out (%s)" % dm["text"])
	await _boot()
	runner.check(RoundShare.platform(), "main built the desk")
