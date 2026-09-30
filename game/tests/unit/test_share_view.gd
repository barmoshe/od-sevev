extends RefCounted
## O4 the receipt and O5 the result card (ui/views/view_share.gd, ui/share_kit.gd; ux/first-minute.md
## §5, rtl-map §7.2, review R25) and Bar's WhatsApp share: the wa.me link is byte for byte the
## browser's encodeURIComponent (Hebrew, ₪, gershayim), the share texts are prose with the URL at the
## end and say ביבי, the receipt's lines add up and fit the kit's print column, the result card
## never shows a seat number, and T4's rows open the sheets with the WhatsApp button beside
## "לשתף" / "לשמור תמונה". The real scene boots on the game content with a throwaway save folder.

var runner: Object
var tree: SceneTree
var dir := ""
var m: Node


func setup(r: Object) -> void:
	TestFixture.use_game_content()
	tree = r as SceneTree
	dir = "user://test_share_%d" % Time.get_ticks_usec()
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


func _touch(p: Vector2, idx: int = 0) -> void:
	for pressed in [true, false]:
		var e := InputEventScreenTouch.new()
		e.index = idx
		e.position = p
		e.pressed = pressed
		m._unhandled_input(e)


## A state that has been around: 3 elections, 2 court days, money this round, a paid demand.
func _veteran() -> GameState:
	var s := GameState.fresh()
	s.evolutions = 3
	s.investigation = {"courtDays": 2, "postponementsLifetime": 9}
	s.golden_caught_lifetime = 12
	s.run_bananas = 4200000.0
	s.coalition = {"chat": [
		{"seq": 1, "type": "demand", "partner": "bengvir", "state": "paid", "price": 1000000.0},
		{"seq": 2, "type": "ultimatum", "partner": "smotrich", "state": "deleted", "price": 500000.0},
		{"seq": 3, "type": "demand", "partner": "deri", "state": "open", "price": 700000.0},
	]}
	return s


func _derived(s: GameState) -> Economy.Derived:
	var d := Economy.Derived.new()
	d.producer_bps = {"taxpayer": 10.0, "hitech": 10.0, "vat": 20.0, "submarine": 60.0}
	return d


# ------------------------------------------------------------------ the WhatsApp link (Bar)

func test_the_wa_link_is_the_browsers_encode_uri_component() -> void:
	var t1 := "שרדתי 3 סבבי בחירות ו־2 ימי משפט ב״עוד סבב״. מישהו פה עושה יותר? https://od-sevev.vercel.app/"
	var js1 := "%D7%A9%D7%A8%D7%93%D7%AA%D7%99%203%20%D7%A1%D7%91%D7%91%D7%99%20%D7%91%D7%97%D7%99%D7%A8%D7%95%D7%AA%20%D7%95%D6%BE2%20%D7%99%D7%9E%D7%99%20%D7%9E%D7%A9%D7%A4%D7%98%20%D7%91%D7%B4%D7%A2%D7%95%D7%93%20%D7%A1%D7%91%D7%91%D7%B4.%20%D7%9E%D7%99%D7%A9%D7%94%D7%95%20%D7%A4%D7%94%20%D7%A2%D7%95%D7%A9%D7%94%20%D7%99%D7%95%D7%AA%D7%A8%3F%20https%3A%2F%2Fod-sevev.vercel.app%2F"
	runner.check(ShareKit.encode_uri_component(t1) == js1, "Hebrew, maqaf, gershayim, ? and the URL encode as Node's encodeURIComponent")
	var t2 := "4.2 מיליון ₪ (במשחק. בינתיים.) *!~'"
	var js2 := "4.2%20%D7%9E%D7%99%D7%9C%D7%99%D7%95%D7%9F%20%E2%82%AA%20(%D7%91%D7%9E%D7%A9%D7%97%D7%A7.%20%D7%91%D7%99%D7%A0%D7%AA%D7%99%D7%99%D7%9D.)%20*!~'"
	runner.check(ShareKit.encode_uri_component(t2) == js2, "₪ is %%E2%%82%%AA and ( ) * ! ~ ' stay as the browser leaves them (%s)" % ShareKit.encode_uri_component(t2))
	var wa := ShareKit.wa_url(t1)
	runner.check(wa.begins_with("https://wa.me/?text=") and wa.trim_prefix("https://wa.me/?text=").uri_decode() == t1, "wa.me carries the text and decodes back to it")
	runner.check(ShareKit.encode_uri_component("\u2066") == "%E2%81%A6", "an isolate would travel as %%E2%%81%%A6 (the texts strip them)")


func test_share_texts_are_prose_with_the_url_last() -> void:
	var s := _veteran()
	var d := _derived(s)
	var u := "https://od-sevev.vercel.app/"
	for kind in ["receipt", "result", "invite"]:
		var t := ShareKit.share_text(kind, s, d, 1790000000000.0, u)
		runner.check(t.ends_with(" " + u), "%s: the URL ends the message (%s)" % [kind, t])
		runner.check(not t.contains("\u2066") and not t.contains("\u2069"), "%s: no bidi isolates in prose" % kind)
		runner.check(not t.contains("{") and not t.contains("הקוסם"), "%s: every placeholder filled, never הקוסם" % kind)
		runner.check(ShareKit.wa_url(t).trim_prefix(ShareKit.WA).uri_decode() == t, "%s: the wa.me round trip" % kind)
	runner.check(ShareKit.share_text("invite", s, d, 0.0, u).contains("תורכם להקים ממשלה") and not ShareKit.share_text("invite", s, d, 0.0, u).contains("ביבי"),
		"the invite (SHARE_TEXT_INVITE, was _NEXT): תורכם להקים ממשלה, no leader named")
	var r := ShareKit.share_text("result", s, d, 0.0, u)
	runner.check(r.begins_with("שרדתי 3 סבבי בחירות ושני ימים בכותרות ב״עוד סבב״."), "the result text: rounds and days in words (%s)" % r)
	var total := float(ShareKit.receipt(s, d, 0.0)["total"])
	var rc := ShareKit.share_text("receipt", s, d, 0.0, u)
	runner.check(rc.contains(ShareKit.word_amount(total) + " ₪ החודש") and rc.contains("(במשחק. בינתיים.)"),
		"the receipt text: the total in Hebrew units, the fiction label kept (%s)" % rc)


func test_word_amounts_and_the_receipt_column() -> void:
	runner.check(ShareKit.word_amount(999.0) == "999", "under a thousand: the number")
	runner.check(ShareKit.word_amount(1500.0) == "1.5 אלף", "1.5 אלף (%s)" % ShareKit.word_amount(1500.0))
	runner.check(ShareKit.word_amount(850000.0) == "850 אלף", "850 אלף (%s)" % ShareKit.word_amount(850000.0))
	runner.check(ShareKit.word_amount(4213000.0) == "4.2 מיליון", "4.2 מיליון (%s)" % ShareKit.word_amount(4213000.0))
	runner.check(ShareKit.word_amount(999960.0) == "1 מיליון", "rounding up a tier (%s)" % ShareKit.word_amount(999960.0))
	runner.check(ShareKit.receipt_amount(4213000.0) == "4,213,000", "the receipt groups in full under 10M")
	runner.check(ShareKit.display_host("https://od-sevev.vercel.app/") == "od-sevev.vercel.app", "the card prints the host")
	runner.check(ShareKit.display_host(ShareKit.SITE_URL).length() <= 22, "RECEIPT_FOOT_URL's 22-glyph budget holds")


# ------------------------------------------------------------------ the models

func test_the_receipt_adds_up_and_the_pistachio_is_free() -> void:
	var s := _veteran()
	var d := _derived(s)
	var r := ShareKit.receipt(s, d, 1790000000000.0)
	var sum := 0.0
	var keys: Array = []
	for ln: Dictionary in r["lines"]:
		keys.append(ln["key"])
		if str(ln["amount"]) != "":
			sum += float(ln["v"])
	runner.check(keys == ["RECEIPT_VAT", "RECEIPT_FUEL", "RECEIPT_FUEL_NOTE", "RECEIPT_WING", "RECEIPT_PISTACHIO", "RECEIPT_COALITION"], "the §5.1 item order (%s)" % str(keys))
	runner.check(is_equal_approx(sum, float(r["total"])), "the total is the sum of the amounts (%s vs %s)" % [sum, r["total"]])
	runner.check(is_equal_approx(float(r["lines"][0]["v"]), 4200000.0 * 0.2), "VAT = the round's income × the VAT source's share")
	runner.check(is_equal_approx(float(r["lines"][2]["v"]), 4200000.0 * 0.2 * 0.6) and is_equal_approx(float(r["lines"][3]["v"]), 4200000.0 * 0.2 * 0.4),
		"fuel / Wing of Zion split the taxpayer + hi-tech income 60/40")
	runner.check(float(r["lines"][4]["v"]) == 0.0 and r["lines"][4]["amount"] == "0", "the pistachio line is always 0 ₪")
	runner.check(is_equal_approx(float(r["lines"][5]["v"]), 1500000.0), "the coalition line = the round's paid lines, not the open one")
	runner.check(str(r["round"]).contains("4"), "the round printed is the current one (evolutions + 1): %s" % r["round"])
	var empty := ShareKit.receipt(GameState.fresh(), null, 1790000000000.0)
	runner.check(float(empty["total"]) == 0.0 and empty["totalText"] == "0", "a fresh round prints zeros, never a NaN")


func test_the_countdown_line_and_the_date() -> void:
	var day := 86400000.0
	var e := Calendar.parse_utc_ms(str(Calendar.cfg().get("electionDate", "")))
	if e <= 0.0:
		runner.check(false, "the content has an election date")
		return
	var noon := func(days_before: int) -> float: return e + 9.0 * 3600000.0 - days_before * day
	runner.check(ShareKit.countdown(noon.call(29)) == Strings.plural("RECEIPT_COUNTDOWN", 29, {"d": "29"}), "29 days out")
	runner.check(ShareKit.countdown(noon.call(1)) == Strings.s("RECEIPT_COUNTDOWN_ONE"), "one day out")
	runner.check(ShareKit.countdown(noon.call(0)) == Strings.s("RECEIPT_COUNTDOWN_TODAY"), "on the day")
	runner.check(ShareKit.countdown(noon.call(-3)) == Strings.s("RECEIPT_COUNTDOWN_AFTER"), "after it: the coalition is not done")
	runner.check(ShareKit.date_of(noon.call(0)) == "27.10.2026", "the date prints on Israel's day (%s)" % ShareKit.date_of(noon.call(0)))


func test_the_result_card_model() -> void:
	var s := _veteran()
	var r := ShareKit.result(s)
	runner.check(str(r["head"]) == Strings.s("RESULT_HEADLINE", {"rounds": Strings.plural("ROUNDS", 3), "days": Strings.plural("DAYS", 2)}), "the headline (%s)" % r["head"])
	runner.check(str(r["stats"]).contains("12") and str(r["stats"]).contains("9"), "suitcases caught and postponement requests (%s)" % r["stats"])
	s.investigation["pressDays"] = 3   # another leader's press days count too (leader-neutral DAYS_*)
	runner.check(str(ShareKit.result(s)["head"]).contains(Strings.plural("DAYS", 5)) and Strings.plural("DAYS", 5).contains("בכותרות"),
		"court + press days, in words that fit every leader (%s)" % ShareKit.result(s)["head"])
	s.investigation["courtDays"] = 0
	s.investigation["pressDays"] = 0
	runner.check(str(ShareKit.result(s)["head"]).ends_with(Strings.s("RESULT_ZERO_TAG")), "zero days: '... ואפס ימים בכותרות בינתיים.'")
	for v: Variant in ShareKit.result(s).values():
		runner.check(not str(v).contains("61") and not str(v).contains("מנדט"), "no seat number on a card (§5 global rule): %s" % v)


# ------------------------------------------------------------------ the cards (nodes at 5 card px per art px)

func test_the_receipt_fits_the_kits_print_column() -> void:
	var s := _veteran()
	s.run_bananas = 98765432.0   # the widest amounts: the bank format past 10M
	var root := Node2D.new()
	ShareSheet.build_card(root, "receipt", s, _derived(s), 1790000000000.0)
	var texts := root.get_children().filter(func(n: Node) -> bool: return n is PxText)
	runner.check(texts.size() >= 20, "every receipt row is drawn (%d texts)" % texts.size())
	for t: PxText in texts:
		var x0 := t.position.x / ShareSheet.S
		var x1 := x0 + ceilf(float(t.width()) / ShareSheet.S)
		runner.check(x0 >= 32.0 - 0.01 and x1 <= 184.0 + 0.01, "'%s' sits in the column x 32-184 (%s-%s)" % [t.text, x0, x1])
		runner.check(not t.truncated(), "'%s' is never cut" % t.text)
		runner.check(t.exact and t.eff_px() == float(ShareSheet.S), "the card draws at exactly 5 card px per font px")
	var bottom := float(root.get_meta("bottom", 999.0))
	runner.check(bottom <= 248.0, "the last row ends inside the paper's print area (y %s ≤ 248)" % bottom)
	var host := false
	for t: PxText in texts:
		host = host or t.text == ShareKit.display_host(ShareKit.site_url())
	runner.check(host, "the URL is on the image (iOS WhatsApp drops the text when an image is attached)")
	root.free()


func test_the_result_card_uses_the_kits_zones() -> void:
	var s := _veteran()
	var root := Node2D.new()
	ShareSheet.build_card(root, "result", s, _derived(s), 0.0)
	var texts := root.get_children().filter(func(n: Node) -> bool: return n is PxText)
	runner.check(texts.size() == 5, "headline, sub-line, stats, footer, disclaimer (%d)" % texts.size())
	for t: PxText in texts:
		runner.check(not t.truncated(), "'%s' is never cut" % t.text)
		var x1 := t.position.x / ShareSheet.S + ceilf(float(t.width()) / ShareSheet.S)
		runner.check(t.position.x >= 0.0 and x1 <= 216.0, "'%s' stays on the card" % t.text)
	runner.check((texts[0] as PxText).line_count() <= 2, "the headline takes at most its 2 plate lines")
	var foot: PxText = texts[3]
	runner.check(foot.text.contains(ShareKit.display_host(ShareKit.site_url())), "the footer carries the URL (%s)" % foot.text)
	var fig := root.get_node_or_null("Figure") as Sprite2D
	runner.check(fig != null and fig.scale == Vector2(2, 2), "ביבי stands on the stage at 2 card px per sprite px (whole pixels)")
	if fig != null:
		var feet := fig.position + Vector2((fig.texture as AtlasTexture).region.size) * 0.0
		runner.check(fig.position.y + (fig.texture as AtlasTexture).region.size.y * 2.0 <= 210.0 * ShareSheet.S, "the figure stands on the stage floor")
		runner.check(fig.position.y >= 78.0 * ShareSheet.S, "the figure clears the headline plate (top y %s)" % (fig.position.y / ShareSheet.S))
		runner.check(feet.x >= 0.0, "on the card")
	# §5.14.3 E1: the blank envelope on the stage floor at card-art (38, 197), after the floor and
	# before the cast; the receipt has none
	var env := root.get_node_or_null("Envelope") as Sprite2D
	runner.check(env != null and env.position == Vector2(38, 197) * ShareSheet.S and env.scale == Vector2(ShareSheet.S, ShareSheet.S), "E1: the envelope lies on the floor at (38, 197)")
	if env != null and fig != null:
		runner.check(env.get_index() < fig.get_index(), "drawn before the leader")
	root.free()
	var rc := Node2D.new()
	ShareSheet.build_card(rc, "receipt", s, _derived(s), 0.0)
	runner.check(rc.get_node_or_null("Envelope") == null, "not on the receipt (a thermal slip carries no props)")
	rc.free()


func test_the_preview_scale_is_whole_device_px() -> void:
	var was := [Display.f, Display.integer]
	for f: float in [0.5, 0.75, 1.0, 1.5, 2.0]:
		Display.f = f
		Display.integer = true
		var a := ShareSheet.preview_scale(886.0, 672.0)
		var dp := a * f
		runner.check(is_equal_approx(dp, roundf(dp)) and dp >= 1.0, "f %s: %s logical per art px = %s device px, whole" % [f, a, dp])
		runner.check(a * 270.0 <= 886.0 + 0.01 or dp == 1.0, "f %s: the preview fits its room" % f)
	Display.f = was[0]
	Display.integer = was[1]


# ------------------------------------------------------------------ the sheets in the scene

func test_t4_rows_open_the_receipt_and_the_result_sheets() -> void:
	await _boot()
	var dv: DossierView = m.dossier
	var kinds: Array = dv.buttons().map(func(b: Dictionary) -> String: return b["kind"])
	runner.check(kinds.slice(0, 2) == ["receipt", "result"], "R25: T4's rows start with the receipt and the result card (%s)" % str(kinds))
	for kind in ["receipt", "result"]:
		dv.act(kind)
		await tree.process_frame
		var t = m.overlays.top()
		runner.check(t is ShareSheet and t.kind == kind, "%s: the sheet is open" % kind)
		if not t is ShareSheet:
			continue
		var sh: ShareSheet = t
		runner.check(sh.id == ("SHARE_RECEIPT" if kind == "receipt" else "SHARE_RESULT"), "the overlay id")
		# mobile-first §5.12 (D44, replaces rtl-map §7.2's 0.8 · vs.y): at most the whole safe height
		runner.check(sh.panel_rect.size.y <= floorf(m._vs.y / 4.0) * 4.0 - m._top_y + 4.0, "a sheet of at most the safe height (mobile-first §5.12)")
		runner.check(sh.wa_btn.visual.position.y > sh.share_btn.visual.position.y, "§5.12: WhatsApp is the nearest action to the thumb (under the pair)")
		runner.check(sh.wa_btn != null and sh.wa_btn.label.text == Strings.s("SHARE_WA") and sh.wa_btn.is_enabled(), "the WhatsApp button is there and live at once (text only)")
		runner.check(sh.panel.get_node_or_null("WaIcon") == null, "review U11: the label only, no WhatsApp-mark icon")
		runner.check(sh.wa_btn.visual.position.x == 24.0 and sh.wa_btn.visual.size.x == 672.0 + L.dx and sh.wa_btn.hit.size == sh.wa_btn.visual.size + Vector2(16, 16),
			"review U14: full width (672 + dx), hit + 8 on every side (%s)" % sh.wa_btn.visual)
		runner.check(absf(sh.wa_btn.label.position.x + sh.wa_btn.label.width() / 2.0 - sh.wa_btn.visual.get_center().x) <= 4.0, "the label centred")
		runner.check(sh.share_btn.label.text == Strings.s("SHARE_BTN") and sh.save_btn.label.text == Strings.s("SHARE_SAVE"), "לשתף beside לשמור תמונה")
		runner.check(sh.share_btn.visual.position.x < sh.save_btn.visual.position.x, "§7.1: the commit (share) on the left")
		runner.check(sh.text_to_share.ends_with(ShareKit.site_url()), "the message ends with the URL")
		for i in 4:
			await tree.process_frame
		runner.check(sh.rendered and sh.share_btn.is_enabled(), "once rendered (here: no renderer) לשתף enables")
		runner.check(sh.png.is_empty() == not sh.save_btn.is_enabled(), "לשמור תמונה only with an image")
		var dp := sh.art_px * (Display.f if Display.integer else 1.0)
		runner.check(is_equal_approx(dp, roundf(dp)), "the preview is whole device px per art px")
		sh.on_share_result("shared")
		runner.check(sh.sent_mark != null and sh.sent_mark.visible and sh.sent_mark.scale == Vector2(4, 4), "E2: a share that went out shows the envelope on the status line")
		sh.on_share_result("fail")
		runner.check(sh.status.text == Strings.s("SHARE_FAIL"), "a failed share says so in the sheet")
		runner.check(not sh.sent_mark.visible, "no envelope for saved / copied / fail")
		m.overlays.back()
		for i in 12:
			await tree.process_frame
		runner.check(not m.overlays.is_open(), "Esc / back closes the sheet")
