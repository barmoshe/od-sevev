extends RefCounted
## The UX build review's engine findings (ux/review-2026-09-29.md), game-developer engine slice:
## R1 Dubi's bubble ink, R3 the large-text step-down (rtl-map §0.2), R4 the spins unlock and the
## tab bar, R6 the toast text box, R9 one browser history entry per layer, R11 the court-day crawl
## clip, R14 S08's line 2, R15 the scrim, R16 the title floor, R19 the Suitcase's sparkles, R20 the
## owned badge, R24 the S07 rate line. Runs on the game content, on the real scene where it matters.

var runner: Object
var tree: SceneTree
var dir := ""
var m: Node


func setup(r: Object) -> void:
	TestFixture.use_game_content()
	tree = r as SceneTree
	dir = "user://test_review_engine_%d" % Time.get_ticks_usec()
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


func _lum(c: Color) -> float:
	var ch := func(v: float) -> float: return v / 12.92 if v <= 0.03928 else pow((v + 0.055) / 1.055, 2.4)
	return 0.2126 * float(ch.call(c.r)) + 0.7152 * float(ch.call(c.g)) + 0.0722 * float(ch.call(c.b))


func _contrast(a: Color, b: Color) -> float:
	var la := _lum(a)
	var lb := _lum(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


# ------------------------------------------------------------------ R1, R6: the toast dock

func test_r1_dubi_bubble_text_is_white_and_legible() -> void:
	await _boot()
	var bt: PxText = m.toasts.bubble_text_node()
	runner.check(bt.tint == Art.col("w"), "Dubi's bubble ink is the kit white `w` (got %s)" % bt.tint)
	var bubble_fill := Color("#2e2250")   # the kit chat_bubble_in fill (review R1)
	var c := _contrast(bt.tint, bubble_fill)
	runner.check(c >= 7.0, "white on the bubble reads at %.1f:1 (was 1.24:1; AAA 7:1)" % c)
	m.toasts.say(Strings.s("DUBI_FIRSTTAP"), Vector2(376, 300), 1600.0)
	runner.check(m.toasts.saying() and bt.visible, "the first-tap line shows in the bubble")


func test_r6_toast_text_box_ends_before_the_accent() -> void:
	await _boot()
	var t: PxText = m.toasts.text_node()
	runner.check(t.wrap_width == 644.0 and t.position.x == 676.0 and t.h_anchor == 2, "toast text right-aligned at x 676, wrap 644 (got %s, %s)" % [t.position.x, t.wrap_width])
	m.toasts.show_toast(Strings.s("HUD_COTTAGE_TIP"))
	m.toasts.update_view(16.0)
	var right := t.position.x
	var left := right - float(t.width())
	runner.check(right <= 676.0 and left >= 32.0, "the drawn line sits in x 32-676 (%s-%s)" % [left, right])
	runner.check(m.toasts.plate_h() == (88.0 if t.line_count() == 1 else 132.0), "the plate is 88 for one line, 132 for two at ×4")


# ------------------------------------------------------------------ R3: the large-text step-down

func test_r3_step_down_draws_x5_only_where_the_filled_string_fits() -> void:
	PxText.set_large_text(tree, true)
	var root := Node2D.new()
	tree.root.add_child(root)
	# a label with a fit box: "קואליציה" is 195 px at ×5 > the 164 tab box → ×4; "מקורות" fits → ×5
	var tab := PxText.make(root, Vector2.ZERO, Strings.s("TAB_COALITION"), L.TEXT)
	tab.fit_width = 164.0
	runner.check(not tab.stepped_up() and tab.eff_px() == float(L.TEXT), "TAB_COALITION steps down to ×4 in its 164 box (%s px at ×5)" % PxText.measure(tab.text, 5))
	var src := PxText.make(root, Vector2.ZERO, Strings.s("TAB_SOURCES"), L.TEXT)
	src.fit_width = 164.0
	runner.check(src.stepped_up() == (PxText.measure(src.text, 5) <= 164), "TAB_SOURCES is ×5 exactly when it fits (%s px)" % PxText.measure(src.text, 5))
	# an unwrapped label never counts a word wrap as fitting: "עוד אחד" is two words, 185 px at ×5
	var verb := PxText.make(root, Vector2.ZERO, Strings.s("CARD_VERB_MORE"), L.TEXT)
	verb.fit_width = 152.0
	runner.check(verb.stepped_up() == (PxText.measure(verb.text, 5) <= 152), "a two-word pill verb is ×5 only on one line (%s px at ×5)" % PxText.measure(verb.text, 5))
	# per filled string: a short price stays ×5, the widest steps down; neither is ellipsised
	var pill := PxText.make(root, Vector2.ZERO, Strings.s("CARD_PRICE", {"price": "15"}), L.TEXT)
	pill.fit_width = 152.0
	runner.check(pill.stepped_up(), "a short price stays ×5")
	pill.text = Strings.s("CARD_PRICE", {"price": "8.88mm"})
	runner.check(not pill.stepped_up() and pill.width() <= 168, "the widest price steps down and fits the pill (%s px)" % pill.width())
	# a wrapped step-down key: never ellipsised, at ×4 when ×5 would need more lines than linesLarge
	var pay := PxText.make(root, Vector2.ZERO, Strings.s("CHAT_PAY", {"price": "8.88mm"}), L.TEXT)
	pay.wrap_width = 296.0
	pay.max_lines = 1
	runner.check(not pay.truncated(), "CHAT_PAY at its worst price is not ellipsised under large text (was '....50K')")
	runner.check(not pay.stepped_up(), "it steps down: %s px at ×5 > 296" % PxText.measure(pay.text, 5))
	# a caption: 2 lines at ×4, up to 3 at ×5 (sheet.caption linesLarge) → stays ×5 and wraps to 3
	var cap := PxText.make(root, Vector2.ZERO, Strings.s("SET_MOTION_CAP"), L.TEXT)
	cap.wrap_width = 360.0
	cap.max_lines = 2
	cap.max_lines_large = 3
	runner.check(not cap.truncated(), "the reduced-motion caption is whole under large text (%d lines at ×%s)" % [cap.line_count(), cap.eff_px()])
	runner.check(cap.stepped_up() == PxText.fits(cap.text, 360.0, 3, 5), "the caption is ×5 exactly when it fits 3 lines there")
	# no box (the crawl, a floater): always ×5; large text off: always ×4
	var crawl := PxText.make(root, Vector2.ZERO, "שורה ארוכה מאוד בטיקר שאין לה קופסה בכלל", L.TEXT)
	runner.check(crawl.stepped_up(), "text with no box draws ×5")
	PxText.set_large_text(tree, false)
	runner.check(not tab.stepped_up() and not src.stepped_up() and not crawl.stepped_up() and crawl.eff_px() == float(L.TEXT), "large text off: everything ×4")
	root.queue_free()


func test_r3_fits_is_the_rtl_map_rule() -> void:
	runner.check(PxText.fits("", 10.0, 1, 5), "an empty string fits")
	var w5 := PxText.measure(Strings.s("HUD_SEATS"), 5)
	runner.check(not PxText.fits(Strings.s("HUD_SEATS"), 128.0, 1, 5) == (w5 > 128), "Row B's label: fits(128) iff %d ≤ 128" % w5)
	runner.check(PxText.fits(Strings.s("HUD_SEATS"), 128.0, 1, 4), "every step-down key fits its box at ×4 (HUD_SEATS)")
	var long := Strings.s("SET_MOTION_CAP")
	runner.check(not PxText.fits(long, 360.0, 1, 5) and PxText.fits(long, 360.0, 99, 5), "a word-wrapped caption needs its line budget")


func test_r3_settings_rows_grow_under_large_text() -> void:
	await _boot()
	m.set_setting("largeText", true)
	await tree.process_frame
	m._open_settings()
	await tree.process_frame
	var o: Overlay = m.overlays.top()
	runner.check(o != null and o.id == "SETTINGS", "the settings sheet is open")
	if o == null:
		return
	# every body text's box sits inside its row's hit, and rows never overlap
	var rows: Array[Rect2] = []
	for b in o.body_focusables:
		rows.append(b.hit)
	rows.sort_custom(func(a: Rect2, b: Rect2) -> bool: return a.position.y < b.position.y)
	for i in range(1, rows.size()):
		runner.check(rows[i].position.y >= rows[i - 1].end.y, "row %d starts under row %d (%s vs %s)" % [i, i - 1, rows[i], rows[i - 1]])
	var cut := 0
	var outside := 0
	var which: Array = []
	for n in o.body.get_children():
		if n is PxText and (n as PxText).text != "":
			var t := n as PxText
			if t.truncated():
				cut += 1
			var top := t.position.y
			var bottom := top + float(HeFont.line_height()) * t.eff_px() * float(maxi(1, t.line_count()))
			var inside := false
			for r in rows:
				if top >= r.position.y and bottom <= r.end.y + 16.0:
					inside = true
			var group := t.tint == Art.col(Art.theme["modal"]["groupLabel"])
			if not inside and not group and t.text != "<":
				outside += 1
				which.append("%s @%s-%s" % [t.text, top, bottom])
	runner.check(cut == 0, "no settings text is ellipsised under large text (%d cut)" % cut)
	runner.check(outside == 0, "every label and caption sits inside its row (%d outside: %s; rows %s)" % [outside, which, rows])
	# toggling large text from the sheet rebuilds it in place
	var h_large := o.panel_rect.size.y
	m.set_setting("largeText", false)
	(o as Overlays.SettingsOverlay).rebuild_if_scale_changed()
	await tree.process_frame
	runner.check(o.panel_rect.size.y <= h_large, "the ×4 sheet is no taller than the large one (%s ≤ %s)" % [o.panel_rect.size.y, h_large])


# ------------------------------------------------------------------ R4: K3 and the tab bar

func test_r4_spins_unlock_at_1500_and_not_inside_c1() -> void:
	var s := GameState.fresh()
	s.taps_lifetime = 3
	s.all_time_bananas = 2000.0
	var rv := Ftue.reveals(s)
	runner.check(not rv["spins"] and not rv["tabs"], "2,000 ₪ lifetime before C1: no spins, no tab bar (was spins at 300)")
	var ids := Content.producer_ids()
	for i in 3:
		s.owned[ids[i]] = 1
	s.all_time_bananas = 1400.0
	runner.check(not Ftue.reveals(s)["spins"] and Ftue.reveals(s)["tabs"], "C1's tab bar; spins wait for 1,500 ₪")
	s.all_time_bananas = 1600.0
	s.stats["playtimeSec"] = 100.0
	s.coalition["opened"] = true
	Ftue.stamp_c1(s)
	runner.check(float(s.ui.get("c1AtSec", -1.0)) == 100.0, "the C1 toast's play time is stamped")
	runner.check(not Ftue.reveals(s)["spins"], "inside C1 (toast up, first demand unpaid): no spins")
	s.stats["playtimeSec"] = 109.0
	runner.check(not Ftue.reveals(s)["spins"], "still inside C1 at 9 s")
	s.stats["playtimeSec"] = 110.0
	runner.check(Ftue.reveals(s)["spins"], "10 s of play after the C1 toast: spins")
	s.stats["playtimeSec"] = 101.0
	s.coalition["paidLifetime"] = 1
	runner.check(Ftue.reveals(s)["spins"], "or the first demand paid (c1 done)")
	var e := GameState.fresh()
	e.evolutions = 1
	runner.check(Ftue.reveals(e)["spins"] and Ftue.reveals(e)["tabs"], "after an election everything the first run taught stays")


func test_r4_the_tab_bar_appears_only_with_c1() -> void:
	await _boot()
	m.commit_pick("bibi")   # LEADER_PICK first (leader select)
	m._set_mode("main", false)
	var s: GameState = m.state
	s.taps_lifetime = 3
	s.all_time_bananas = 5000.0
	s.owned[Content.producer_ids()[0]] = 1
	await tree.process_frame
	runner.check(not m.shop._tabbar.visible, "5,000 ₪ lifetime, one source: no tab bar")
	for id: String in Content.producer_ids().slice(0, 3):
		s.owned[id] = 1
	await tree.process_frame
	runner.check(m.shop._tabbar.visible and m.shop._slot_shown(2), "C1: the bar with the coalition slot")


# ------------------------------------------------------------------ R9: history

func test_r9_layer_history_bookkeeping() -> void:
	var h := LayerHistory.new()
	runner.check(h.sync(0).is_empty() and not h.on_pop(), "the root: nothing pushed, a back there is not ours (the page may leave)")
	runner.check(h.sync(1) == {"push": 1}, "a layer opens: one entry")
	runner.check(h.sync(2) == {"push": 1} and h.pushed == 2, "a second layer over it: one more")
	runner.check(h.on_pop() and h.pushed == 1, "the player's back closes the top layer")
	runner.check(h.sync(1).is_empty(), "the game closed it: the browser already agrees")
	runner.check(h.sync(0) == {"back": 1}, "a layer closed by ✕ rewinds its entry")
	runner.check(not h.on_pop() and h.pushed == 0, "and the echo of that history.go is ignored")
	runner.check(h.sync(3) == {"push": 3} and h.sync(0) == {"back": 3}, "several at once: one history.go(-3)")
	runner.check(not h.on_pop(), "one echo for the one go()")
	runner.check(not h.on_pop(), "a back at the root is left to the browser")
	runner.check(LayerHistory.js_for({"push": 2}).count("pushState") == 2 and LayerHistory.js_for({"back": 2}).contains("history.go(-2)"), "the JavaScript")


func test_r9_back_closes_the_top_layer_like_esc() -> void:
	await _boot()
	m.ftue.handoff_ms = 1.0
	m.commit_pick("bibi")   # LEADER_PICK (leader select): Bibi's round, the shipped game
	m._set_mode("main", false)
	await tree.process_frame
	runner.check(m.layer_depth() == 0 and not m.back_layer(), "nothing open: depth 0, back is not trapped")
	m.dossier.open()
	runner.check(m.layer_depth() == 1, "T4 is one layer")
	m._open_settings()
	await tree.process_frame
	runner.check(m.layer_depth() == 2, "settings over T4: two")
	m.history.sync(m.layer_depth())
	var t0: float = m.overlays.now_ms()
	m.overlays.update_view(200.0)
	runner.check(m.overlays.now_ms() > t0, "time runs")
	m.history._ignore = 0
	m._history_pop()   # the browser's back button (popstate)
	runner.check(not m.overlays.is_open() and m.dossier.is_open(), "back closes settings first, T4 stays")
	m._history_pop()
	runner.check(not m.dossier.is_open() and m.layer_depth() == 0, "back again closes T4")
	m._history_pop()
	runner.check(m.layer_depth() == 0, "back at the root does nothing in the game")


# ------------------------------------------------------------------ R11: the court-day crawl clip

func test_r11_court_day_clip_ends_before_dubi() -> void:
	await _boot()
	var t: Ticker = m.ticker
	var x1 := t.clip_x1()
	runner.check(is_equal_approx(t.clip_rect().end.x, x1), "a normal day: the crawl ends at the anchor (%s)" % x1)
	t.set_court_chip(true, 220.0)
	runner.check(is_equal_approx(t.clip_rect().position.x, 228.0), "court day: the clip starts 8 px right of the chip")
	runner.check(is_equal_approx(t.clip_rect().end.x, x1), "court day: its right edge stays the anchor's (%s, was 552)" % t.clip_rect().end.x)
	if t.dubi != null:
		var dr := t.dubi.rect()
		dr.position += t.dubi.position
		runner.check(t.clip_rect().end.x <= dr.position.x, "the crawl never runs under Dubi (%s ≤ %s)" % [t.clip_rect().end.x, dr.position.x])
	t.set_court_chip(false)
	runner.check(is_equal_approx(t.clip_rect().position.x, float(L.TICKER["clipX0"])) and is_equal_approx(t.clip_rect().end.x, x1), "the chip goes: back to x 192-%s (was reset to 552)" % x1)


# ------------------------------------------------------------------ minors: R14, R15, R16, R19, R20, R24

func test_r14_s08_line_two_names_the_growing_part() -> void:
	var card := {"level": 0, "bars": {"public": 100.0, "friendly": 0.0}}
	runner.check(Shop.spin_line2("s08", card) == Strings.upgrade_effect("s08"), "level 0: the effect label")
	card = {"level": 2, "bars": {"public": 60.0, "friendly": 40.0}}
	runner.check(Shop.spin_line2("s08", card) == Strings.s("SPIN_BARS_LINE", {"pct": 40}), "level 2: SPIN_BARS_LINE with the friendly share (%s)" % Shop.spin_line2("s08", card))
	runner.check(Shop.spin_line2("s02", {"level": 1}) == Strings.upgrade_effect("s02"), "a spin without bars keeps its effect")


func test_r15_the_scrim_is_the_outline_swatch() -> void:
	runner.check(Art.col(Art.theme["scrim"]).to_html(false) == "0b0a12", "uiTheme.scrim is the kit outline #0b0a12 (was grape #3a1e72)")
	runner.check(is_equal_approx(float(Tune.MC["backdropAlpha"]), 0.6), "backdropAlpha stays 0.6")
	var base := Color("#140c24")
	var out := base.lerp(Art.col(Art.theme["scrim"]), 0.6)
	runner.check(_lum(out) < _lum(base), "the scrim only darkens the dark base (%s → %s)" % [base.to_html(false), out.to_html(false)])
	var plate := Color("#fff4e0").lerp(Art.col(Art.theme["scrim"]), 0.85)   # the spin tag plate at 85%
	runner.check(_contrast(Art.col("w"), plate) >= 7.0, "white 'שחוק' on the tag plate reads at %.1f:1" % _contrast(Art.col("w"), plate))


func test_r16_title_floor_fills_the_reserved_sections() -> void:
	await _boot()
	runner.check(m.mode == "pick", "a fresh save boots into LEADER_PICK")
	m.ftue.handoff_ms = 1.0
	m.commit_pick("bibi")
	runner.check(m.mode == "title", "the pick lands in the pre-tap (title) state")
	var f: ColorRect = m._title_floor
	var sb: float = m._stage_y + L.stage_bottom()
	# mobile-first A1: the 2D plaza (diorama, from the stage bottom) is the floor; the flat fill only continues it
	var reach: float = m.diorama.floor_reach()
	runner.check(reach > 0.0 and sb + reach >= m._vs.y, "the plaza art runs from the stage bottom (%s) past the screen bottom (%s)" % [sb, sb + reach])
	runner.check(f.visible and is_equal_approx(f.position.y, sb + reach) and is_equal_approx(f.position.y + f.size.y, maxf(m._vs.y, sb + reach)), "the flat floor starts where the plaza ends (%s) and reaches the screen bottom" % f.position.y)
	runner.check(f.position.x <= 0.0 and f.size.x >= m._vs.x, "full width, no inner rect")
	runner.check(f.color == m.diorama.pad_bottom, "in the stage's floor colour")
	m._set_mode("main", false)
	runner.check(not f.visible, "gone in the main state")


func test_r19_suitcase_sparkles_clear_after_the_flight() -> void:
	await _boot()
	var g: GoldenView = m.golden
	g.first_flight = true
	g.spawn()
	for i in 450:
		g.update_view(16.0, false)
		if g.state == "gone":
			break
	runner.check(g.state == "gone", "the flight ended")
	for i in 40:
		g.update_view(16.0, false)
	runner.check(g.live_sparkles() == 0, "no sparkle outlives the flight (%d left)" % g.live_sparkles())


func test_r20_owned_badge_sits_on_the_plate_corner() -> void:
	await _boot()
	var s: GameState = m.state
	var id: String = Content.producer_ids()[0]
	s.taps_lifetime = 3
	s.owned[id] = 123
	await tree.process_frame
	m.shop.refresh(s, 16.0, false, Economy.derive(s))
	var k: int = m.shop.row_index_of(s, "producer", id)
	var v: Dictionary = (m.shop._rows["producers"] as Array)[k]
	var ot: PxText = v["owned"]
	var chip: Rect2 = L.ROW["owned"]
	runner.check(ot.text == Strings.s("CARD_OWNED", {"n": Fmt.owned(123)}) and (v["ownedBg"] as ColorRect).visible, "the badge shows ×123 on its dark chip")
	var left := ot.position.x
	runner.check(left >= chip.position.x and left + float(ot.width()) <= chip.end.x, "the count is centred in the chip %s (x %s, w %s)" % [chip, left, ot.width()])
	var l2: PxText = v["line2"]
	runner.check(l2.position.x <= chip.position.x and l2.wrap_width == 348.0, "line 2 ends left of the badge (right %s, box 348)" % l2.position.x)


func test_r24_s07_rate_line_says_where_the_money_goes() -> void:
	await _boot()
	var tb: TopBar = m.top_bar
	tb.set_bps(12.0, 1.0, true)
	runner.check(tb.bps.text == Strings.s("HUD_BPS_POUR") and tb.bps.tint == Art.col(Art.theme["statText"]["bpsFrenzy"]), "while S07 runs: HUD_BPS_POUR in the frenzy tint (was '+0.0 ₪ לשנייה')")
	tb.set_bps(12.0, 1.0, false)
	runner.check(tb.bps.text == Strings.s("HUD_BPS", {"rate": Fmt.rate(12.0)}), "then the rate again")
