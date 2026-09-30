extends RefCounted
## The §7.1 modals rebuilt this wave (ux/rtl-map.md §7.1-7.2, review R7, R8): O3 the election card,
## the election transition, O1 the return card and O10 the reset confirm, all on the kit's
## sheet_modal (SheetCard), ×4 wrapping bodies that never ellipsise, and the §7.1 button rules;
## plus the O8 About source list (tools/lib/render_shell.py, review R2). The real scene boots on
## the game content with a throwaway save folder.

var runner: Object
var tree: SceneTree
var dir := ""
var m: Node


func setup(r: Object) -> void:
	TestFixture.use_game_content()
	tree = r as SceneTree
	dir = "user://test_modals_%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(dir)


func teardown() -> void:
	PxText.set_large_text(tree, false)
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


func _touch(p: Vector2) -> void:
	for pressed in [true, false]:
		var e := InputEventScreenTouch.new()
		e.position = p
		e.pressed = pressed
		m._unhandled_input(e)


func _wait(sec: float) -> void:
	await tree.create_timer(sec).timeout


func _no_ellipsis(card: SheetCard) -> void:
	for p: PxText in card.paras:
		runner.check(not p.truncated(), "%s: a body line wraps, never ellipsises (%s)" % [card.id, p.text])
	runner.check(card.title_text != null and not card.title_text.truncated(), "%s: the title fits its 432 box" % card.id)
	for b: PxButton in card.buttons:
		runner.check(b.label == null or not b.label.truncated(), "%s: a button label fits (%s)" % [card.id, b.label.text if b.label else ""])


## Enough seats and base for the 61 gate: every coalition partner seated, a big round.
func _gate_open() -> void:
	for p: Dictionary in Coalition.partners():
		if not p.get("standIn", false) and p.get("side", "coalition") == "coalition":
			Coalition.ps(m.state, str(p["id"]))["status"] = "member"
	Economy.add_bananas(m.state, 5e9)
	m.d = Economy.derive(m.state)


# ------------------------------------------------------------------ O3 + the transition

func test_the_election_card_is_the_o3_sheet_with_stacked_buttons() -> void:
	await _boot()
	m._open_evolution()
	await _wait(0.4)
	var c := m.overlays.top() as ElectionCard
	runner.check(c != null and c.id == "EVOLUTION", "E / the CTA opens O3, an ElectionCard")
	if c == null:
		return
	runner.check(c.title_text.text == Strings.s("ELECT_TITLE", {"n": m.state.evolutions + 1}), "the title names the round being called (%s)" % c.title_text.text)
	var texts := c.paras.map(func(p: PxText) -> String: return p.text)
	for k in ["ELECT_RESET", "ELECT_KEEP_CASES", ElectionCard.mood_key(1)]:
		runner.check(texts.has(Strings.s(k)), "O3 says %s" % k)
	# the width rule (Bar 2026-09-30): the card grows by 2·grow_half() about the 720 design's x 48-672
	var g2 := SheetCard.grow_half()
	runner.check(c.panel_rect.size.x == 624.0 + 2.0 * g2 and c.panel_rect.position.x == 48.0 - g2 and c.panel_rect.size.x >= 0.92 * L.cw, "a ≥ 92%% card, 624 + %d at x 48 − %d (%s)" % [2.0 * g2, g2, c.panel_rect])
	runner.check(c.frame.get_meta("sprite") == "sheet_modal_body" and c.flap != null and c.flap.get_meta("sprite") == "sheet_modal_flap",
		"the envelope: sheet_modal_body + sheet_modal_flap (review U1)")
	runner.check(c.flap.position == c.panel_rect.position and c.flap.size * 4.0 == Vector2(c.panel_rect.size.x, 96.0) and c.flap.texture == Art.tex("sheet_modal_flap", 2),
		"the flap spans the card's top 96 at rest on f2 (%s)" % [c.flap.size * 4.0])
	runner.check(c.frame.get_index() < c.flap.get_index() and c.flap.get_index() < c.title_text.get_parent().get_index(), "draw order: body, flap, title")
	# §5.14.1: the hemicycle is the card's hero, under the title band and over the leader line
	runner.check(c.hemicycle != null, "the hemicycle is on O3 at 720×1280")
	if c.hemicycle != null:
		var hp := c.hemicycle.position
		runner.check(hp.y == SheetCard.HEADER_H + 16.0 and c.hemicycle.size() == Vector2(288, 152), "×4 (288×152) at the header + 16 (%s)" % hp)
		runner.check(absf(hp.x + 144.0 - (c.panel_rect.position.x + c.panel_rect.size.x / 2.0)) <= 4.0, "centred on the card")
		runner.check(c.hemicycle.n == ElectionCard.hemi_seats(m.state), "it fills the effective seats (%d)" % c.hemicycle.n)
		var first_para: PxText = c.paras[0]
		runner.check(first_para.position.y >= hp.y + 152.0 + 16.0, "the leader line / the first line is its caption, below it")
	var go := c.go_button
	var no := c.cancel_button
	runner.check(go.visual.size.x == 544.0 + 2.0 * g2 and no.visual.size.x == 544.0 + 2.0 * g2 and go.visual.position.y < no.visual.position.y,
		"§7.1 stacked: ELECT_GO full width over ELECT_CANCEL")
	runner.check(go.label.text == Strings.s("ELECT_GO") and no.label.text == Strings.s("ELECT_CANCEL"), "the ELECT_* labels, not the fork's EVO_*")
	runner.check(not go.is_enabled() and c.need_text != null and c.focus_index == 1, "no majority yet: 'לפזר' is disabled, EVO_NEED says why, focus on 'עוד לא'")
	_no_ellipsis(c)
	_gate_open()
	c.update_view(16.0)
	runner.check(go.is_enabled() and not c.need_text.visible, "the gate opens: 'לפזר את הכנסת' is live")
	c.cancel("backdrop")
	runner.check(c.closing and not c.committed, "the backdrop is 'עוד לא'")


## review U1 + style guide §17.2: the flap opens f0/f1/f2 at 0/40/80 ms and holds f2; the title and
## the ✕ show from f2; reduced motion: f2 at once.
func test_the_envelope_flap_opens_on_the_modal() -> void:
	await _boot()
	m._open_evolution()
	var c := m.overlays.top() as ElectionCard
	runner.check(c != null and c.flap != null, "O3 has a flap")
	if c == null or c.flap == null:
		return
	c.enter(false)
	runner.check(c.flap.texture == Art.tex("sheet_modal_flap", 0) and not c.title_text.visible and c.flap_head.size() == 2, "0 ms: sealed, the title and ✕ hidden")
	c.tick(40.0)
	runner.check(c.flap.texture == Art.tex("sheet_modal_flap", 1) and not c.title_text.visible, "40 ms: lifting")
	c.tick(40.0)
	runner.check(c.flap.texture == Art.tex("sheet_modal_flap", 2) and c.title_text.visible, "80 ms: open, the title shows")
	c.tick(400.0)
	runner.check(c.flap.texture == Art.tex("sheet_modal_flap", 2), "then it holds f2")
	c.enter(true)
	runner.check(c.flap.texture == Art.tex("sheet_modal_flap", 2) and c.title_text.visible, "reduced motion: f2 at once")
	# the hemicycle is left out when the card would not fit the band (§5.14.1)
	runner.check(c.hemicycle == null or c.laid_h() <= c.room(), "the card fits its band, or the hemicycle is left out")


func test_the_election_confirm_runs_the_transition_with_the_round() -> void:
	await _boot()
	_gate_open()
	m._open_evolution()
	await _wait(0.4)
	var c := m.overlays.top() as ElectionCard
	runner.check(c != null and c.go_button.is_enabled(), "the card opens ready")
	if c == null:
		return
	_touch(c.to_view(c.go_button.visual.get_center()))
	runner.check(c.committed and m.tx.running, "'לפזר את הכנסת' commits the election and the transition runs")
	var tx: EvolveTx = m.tx
	runner.check(tx._species.text == Strings.s("ELECT_TITLE", {"n": 2}), "the transition names the new round (%s)" % tx._species.text)
	runner.check(tx._line.text == Strings.s("EVOTX_LINE") and tx._line.px == L.TEXT, "EVOTX_LINE at the ×4 body scale")
	runner.check(tx._mult.text.contains("←") and not tx._mult.text.contains("→"), "the multiplier is EVO_MULT, ordered for RTL (%s)" % tx._mult.text)
	for p: PxText in [tx._line, tx._species, tx._mult, tx._gain]:
		runner.check(not p.truncated(), "a transition line fits 656 (%s)" % p.text)


# ------------------------------------------------------------------ O1

func test_the_return_card_speaks_by_absence_band() -> void:
	runner.check(ReturnCard.band_texts(5.0 * 60.0) == [Strings.s("RET_TITLE_SHORT"), Strings.s("RET_BODY_SHORT")], "1-15 min: SHORT")
	runner.check(ReturnCard.band_texts(2.0 * 3600.0)[0] == Strings.s("RET_TITLE_MID"), "15 min-8 h: MID")
	runner.check(ReturnCard.band_texts(20.0 * 3600.0)[0] == Strings.s("RET_TITLE_LONG"), "8-48 h: LONG")
	runner.check(ReturnCard.band_texts(2.5 * 86400.0)[0] == Strings.s("RET_TITLE_GONE_TWO"), "2 days: GONE_TWO")
	runner.check(ReturnCard.band_texts(5.0 * 86400.0)[0] == Strings.s("RET_TITLE_GONE_OTHER", {"n": 5}), "5 days: GONE_OTHER {n}")
	await _boot()
	m.state.coalition["unread"] = 3
	m._pending_offline = {"award": 12345.0, "away": 3.0 * 3600.0, "capped": true, "cold": true}
	m._show_offline()
	await _wait(0.4)
	var c := m.overlays.top() as ReturnCard
	runner.check(c != null and c.id == "OFFLINE", "the away receipt is O1, a ReturnCard")
	if c == null:
		return
	var texts := c.paras.map(func(p: PxText) -> String: return p.text)
	runner.check(c.title_text.text == Strings.s("RET_TITLE_MID") and texts.has(Strings.s("RET_BODY_MID")), "3 h away: the MID band")
	runner.check(c.amount_text.text == Strings.s("RET_GAIN", {"x": Fmt.amount(12345.0)}), "a cold load shows the whole gain (%s)" % c.amount_text.text)
	runner.check(texts.has(Strings.plural("RET_CHAT", 3, {"n": "3"})), "the chat line counts the unread messages")
	runner.check(texts.has(Strings.s("RET_CAP", {"h": str(int(c.info.get("capHours", 8)))})), "the cap line when the cap was reached")
	runner.check(c.buttons.size() == 1 and c.buttons[0].label.text == Strings.s("RET_BTN") and c.buttons[0].visual.size.x == 544.0 + 2.0 * SheetCard.grow_half(), "one full-width 'לאסוף'")
	_no_ellipsis(c)
	c.cancel("backdrop")
	runner.check(c.closing, "the backdrop collects too")


# ------------------------------------------------------------------ O10

func test_the_reset_confirm_puts_cancel_first_and_keeps_the_backdrop() -> void:
	await _boot()
	m._open_reset()
	await _wait(0.4)
	var c := m.overlays.top() as ResetCard
	runner.check(c != null and c.id == "RESET_CONFIRM", "the settings' reset row opens O10, a ResetCard")
	if c == null:
		return
	var texts := c.paras.map(func(p: PxText) -> String: return p.text)
	for k in ["RST_BODY_1", "RST_BODY_2", "RST_NOTE"]:
		runner.check(texts.has(Strings.s(k)), "O10 says %s in full" % k)
	_no_ellipsis(c)
	var cancel := c.cancel_button
	var commit := c.commit_button
	var gh := SheetCard.grow_half()
	runner.check(cancel.visual == SheetCard._grow_btn(Rect2(376, cancel.visual.position.y, 256, 96), gh) and commit.visual == SheetCard._grow_btn(Rect2(88, cancel.visual.position.y, 256, 96), gh),
		"§7.1 side by side: 'התחרטתי' on the right, 'למחוק הכול' on the left (%s / %s)" % [cancel.visual, commit.visual])
	runner.check(c.focus_index == c.focusables.find(cancel), "focus starts on cancel")
	runner.check(commit.kind == ResetCard.danger_kind() and ["kit_danger", "kit_secondary"].has(commit.kind), "the commit is a kit button (danger when drawn), never the fork's red (%s)" % commit.kind)
	runner.check(not c.backdrop_closes, "the backdrop does not close O10")
	m.overlays.pointer_down(Vector2(8, 8))
	runner.check(not c.closing, "a backdrop tap does nothing")
	c.cancel("esc")
	runner.check(c.closing, "Esc / back is cancel")


func test_the_reset_buttons_stack_under_large_text() -> void:
	await _boot()
	PxText.set_large_text(tree, true)
	m._open_reset()
	await _wait(0.4)
	var c := m.overlays.top() as ResetCard
	runner.check(c != null, "O10 opens")
	if c == null:
		return
	runner.check(c.commit_button.visual.size.x == 544.0 + 2.0 * SheetCard.grow_half() and c.commit_button.visual.position.y < c.cancel_button.visual.position.y,
		"×5 'למחוק הכול' is wider than a 224 half: stacked, commit on top")
	_no_ellipsis(c)


# ------------------------------------------------------------------ O8 About (tools/lib/render_shell.py)

func test_the_about_page_prints_only_public_hebrew() -> void:
	var game := ProjectSettings.globalize_path("res://")
	var root := game.path_join("..").simplify_path()
	var tmp := ProjectSettings.globalize_path("user://about_test.html")
	var src := FileAccess.get_file_as_string("res://web/shell.html")
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	f.store_string(src)
	f.close()
	var out: Array = []
	var code := OS.execute("python3", [root.path_join("tools/lib/render_shell.py"), tmp], out, true)
	runner.check(code == 0, "render_shell runs (%s)" % str(out))
	var html := FileAccess.get_file_as_string(tmp)
	DirAccess.remove_absolute(tmp)
	var facts: Array = JSON.parse_string(FileAccess.get_file_as_string(root.path_join("design/facts.json")))["facts"]
	var want := 0
	for fact: Dictionary in facts:
		if fact.get("notUsed") != true and str(fact.get("aboutHe", "")).strip_edges() != "":
			want += 1
			runner.check(html.contains(str(fact["aboutHe"]).xml_escape(true)) or html.contains(str(fact["aboutHe"])), "the public line of %s is listed" % fact["id"])
		runner.check(str(fact.get("text", "")) == "" or not html.contains(str(fact.get("text", "")).xml_escape(true)),
			"the English research note of %s is not printed" % fact["id"])
	var ul := html.find("<ul dir=\"rtl\">")
	var items := html.substr(ul, html.find("</ul>", ul) - ul).count("<li>")
	runner.check(ul >= 0 and items == want and want > 0, "an RTL list of %d public sources (%d)" % [want, items])
	for bad in ["NOT USED", "GAP:", "Bench only", "The game never names"]:
		runner.check(not html.contains(bad), "no internal note '%s'" % bad)
	# palette v4: About is a white notice, so its links are flag blue on white (8.5:1; was #9fc3ff on the dark page)
	runner.check(html.contains("#od-about a, #od-about a:visited { color: #0038b8;"),
		"links are #0038b8 on the white notice (8.5:1), not the browser's #0000ee")
	var back := html.find("id=\"od-about-back\"")
	runner.check(back >= 0 and back < html.find("id=\"od-about-title\"") and html.contains("position: sticky"),
		"ABOUT_BACK sticks at the top, before the title")
