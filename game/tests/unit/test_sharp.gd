extends RefCounted
## Bar's "sharp characters on every phone" and "sharper text" (game-developer engine, 2026-09-29):
## - the crisp k rule (core/display.gd): k is the largest multiple of 2 or 3 that fits, so every
##   rendered figure has a density drawing whole device px; a view's own art scale stays whole too
##   (SpriteStrip.crisp_art_px: the ultimatum cameo);
## - Sevev 9 @2 (CONTRACT.md §6.1) in PxText's reading role: drawn only where one Sevev 9 px is an
##   even number of device px, and laid out exactly like Sevev 9 (measured both ways);
## - Ftue "tabs" counts the sources owned in total, as the sim's C1 does;
## - a court card folding into its chip takes no press (the first tap into T3 after Esc).

var runner: Object
var tree: SceneTree
var dir := ""
var m: Node
var heard: Array = []


func setup(r: Object) -> void:
	TestFixture.use_game_content()
	tree = r as SceneTree
	dir = "user://test_sharp_%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(dir)


func teardown() -> void:
	PxText.set_large_text(tree, false)
	PxText.set_sharp_text(tree, true)
	Display.update(Vector2(720, 1280))   # the default k 4, f 1 for the tests after this one
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


# ------------------------------------------------------------------ the crisp k rule

func test_every_phone_k_is_crisp_for_every_rendered_figure() -> void:
	# CSS × DPR → (the k that fits, the k drawn)
	var phones := {Vector2(780, 1688): [4, 4], Vector2(1170, 2532): [6, 6], Vector2(1290, 2796): [7, 6],
		Vector2(1284, 2778): [7, 6], Vector2(1080, 2400): [6, 6], Vector2(1442, 3202): [8, 8], Vector2(900, 1600): [5, 4],
		Vector2(390, 844): [2, 2], Vector2(1440, 900): [3, 3], Vector2(2000, 4400): [11, 10]}
	var man := SpriteStrip.manifest()
	for dev: Vector2 in phones:
		Display.update(dev)
		var want: Array = phones[dev]
		runner.check(Display.fit_k(dev) == int(want[0]) and Display.k == int(want[1]),
			"%s: fits k %d, draws k %d (got %d → %d)" % [dev, want[0], want[1], Display.fit_k(dev), Display.k])
		runner.check(Display.logical_size(dev).x >= 720.0 and Display.logical_size(dev).y >= 1068.0, "%s: the remainder is letterboxed, never cropped" % dev)
		# every character and source on the stage (×4) draws whole device px per sprite px
		for slug: String in man["chars"]:
			var v := SpriteStrip.pick_variant(man["chars"][slug], Display.k)
			runner.check(Display.k % SpriteStrip.density_of(v) == 0, "%s k %d: %s d %d is whole-block" % [dev, Display.k, slug, SpriteStrip.density_of(v)])
		for sid: String in man["sources"]:
			var sv := SpriteStrip.pick_variant(man["sources"][sid], Display.k)
			runner.check(Display.k % SpriteStrip.density_of(sv) == 0, "%s k %d: source %s is whole-block" % [dev, Display.k, sid])


## A view's own art scale (the ultimatum cameo's ×3 / ×2): lowered to the largest scale drawing
## whole device px on one of the figure's densities.
func test_a_views_own_art_scale_stays_whole_pixel() -> void:
	var dens := SpriteStrip.densities_of("may-golan")
	runner.check(dens.has(3) and dens.has(2), "May Golan ships d 3 + d 2 (%s)" % [dens])
	var cases := [[Vector2(780, 1688), 3.0, 3.0], [Vector2(780, 1688), 2.0, 2.0], [Vector2(1170, 2532), 3.0, 8.0 / 3.0],
		[Vector2(1170, 2532), 2.0, 2.0], [Vector2(1442, 3202), 3.0, 3.0], [Vector2(1440, 900), 3.0, 8.0 / 3.0]]
	for c: Array in cases:
		Display.update(c[0])
		var a := SpriteStrip.crisp_art_px(float(c[1]), dens)
		var dp := a * Display.f
		runner.check(is_equal_approx(a, float(c[2])), "k %d: ×%s → ×%.3f, got ×%.3f" % [Display.k, c[1], c[2], a])
		runner.check(is_equal_approx(dp, roundf(dp)) and (int(roundf(dp)) % 2 == 0 or int(roundf(dp)) % 3 == 0),
			"k %d ×%.3f: %.2f device px per art px, divisible by a density" % [Display.k, a, dp])
	# the strip at that scale picks the crisp render and nearest sampling
	var parent := Node2D.new()
	tree.root.add_child(parent)
	await tree.process_frame
	Display.update(Vector2(1170, 2532))
	var s := SpriteStrip.make(parent, "may-golan", Vector2(644, 900))
	s.set_art_px(SpriteStrip.crisp_art_px(3.0, dens))
	runner.check(s.density == 2 and s.material == null and s.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST,
		"the cameo at k 6: ×8/3 = 4 dp per art px, the d 2 at 2 dp, nearest (d %d)" % s.density)
	var o: Vector2 = (s.position + s.rect().position) * Display.f
	runner.check(o.is_equal_approx(o.round()), "its frame's top-left sits on a whole device px (%s)" % o)
	parent.queue_free()


# ------------------------------------------------------------------ Sevev 9 @2

func _pair(parent: Node, t: String, wrap: float, lines: int) -> Array:
	var out: Array = []
	for reading: bool in [false, true]:
		var p := PxText.make(parent, Vector2.ZERO, "", L.TEXT, "plain", "w")
		p.reading = reading
		p.max_lines = lines
		p.wrap_width = wrap
		p.text = t
		out.append(p)
	return out


func test_the_reading_cut_draws_only_where_crisp() -> void:
	runner.check(HeFont.sharp() != null and HeFont.sharp_size() == 18, "Sevev 9 @2 loads (size %d)" % HeFont.sharp_size())
	var parent := Node2D.new()
	var t := "הצעת חוק פרטית"
	# k → Sevev 9 device px at ×4, whether @2 is drawn
	var table := [[Vector2(390, 844), 2, true], [Vector2(1440, 900), 3, false], [Vector2(780, 1688), 4, true],
		[Vector2(1170, 2532), 6, true], [Vector2(1442, 3202), 8, true], [Vector2(1620, 3000), 9, false]]
	for row: Array in table:
		Display.update(row[0])
		var pr := _pair(parent, t, 416.0, 2)
		runner.check(is_equal_approx((pr[1] as PxText).device_px(), float(row[1])), "k %d: ×4 is %d device px per Sevev 9 px" % [Display.k, row[1]])
		runner.check((pr[1] as PxText).is_sharp() == bool(row[2]), "k %d: a reading text draws @2 %s" % [Display.k, row[2]])
		runner.check(not (pr[0] as PxText).is_sharp(), "k %d: a display text keeps Sevev 9" % Display.k)
	Display.update(Vector2(780, 1688))
	var o := PxText.make(parent, Vector2.ZERO, t, L.TEXT, "outline", "w")
	o.reading = true
	runner.check(not o.is_sharp(), "the outline cut has no @2: outlined text stays Sevev 9")
	PxText.set_sharp_text(null, false)
	var off := _pair(parent, t, 416.0, 2)
	runner.check(not (off[1] as PxText).is_sharp(), "&sharp=0 turns the reading cut off")
	PxText.set_sharp_text(null, true)
	# large text ×5 composes: 5 device px at k 4 (odd) falls back to Sevev 9; 10 at k 8 draws @2
	PxText.large_text = true
	var lt := _pair(parent, t, 0.0, 1)
	runner.check((lt[1] as PxText).stepped_up() and is_equal_approx((lt[1] as PxText).device_px(), 5.0) and not (lt[1] as PxText).is_sharp(),
		"large text at k 4: ×5 = 5 device px, Sevev 9")
	Display.update(Vector2(1442, 3202))
	(lt[1] as PxText)._relayout()
	runner.check(is_equal_approx((lt[1] as PxText).device_px(), 10.0) and (lt[1] as PxText).is_sharp(), "large text at k 8: ×5 = 10 device px, @2 at 5")
	Display.update(Vector2(1170, 2532))
	(lt[1] as PxText)._relayout()
	runner.check(is_equal_approx((lt[1] as PxText).device_px(), 8.0) and (lt[1] as PxText).is_sharp(), "large text at k 6: ×5 snaps to 8 device px, @2 at 4")
	PxText.large_text = false
	parent.free()


## The metric rule, measured: every string of the UI deck (and the chat's sample lines) wraps,
## ellipsises and measures identically on both cuts, at k 4 and k 6, in the boxes the views use.
func test_the_reading_cut_lays_out_exactly_like_sevev_9() -> void:
	var parent := Node2D.new()
	var texts: Array = []
	var tbl: Dictionary = Strings.data()["strings"]
	for key: String in tbl:
		var v := String(tbl[key])
		if v.strip_edges() != "":
			texts.append(v)
	texts.append_array(["\u20661,250\u2069 ₪ לשנייה", "דובי: \"אין כלום, כי לא היה כלום!\"", "רה\"מ ביקש \u20663\u2069 מנדטים ועוד \u206645K\u2069 ₪ לתקציב הישיבות"])
	var boxes := [[0.0, 1], [416.0, 99], [560.0, 4], [300.0, 2], [200.0, 1]]
	var n := 0
	var sharp := 0
	for dev: Vector2 in [Vector2(780, 1688), Vector2(1170, 2532)]:
		Display.update(dev)
		for t: String in texts:
			for b: Array in boxes:
				var pr := _pair(parent, t, float(b[0]), int(b[1]))
				var a: PxText = pr[0]
				var s: PxText = pr[1]
				sharp += 1 if s.is_sharp() else 0
				var same: bool = a.width() == s.width() and a.line_count() == s.line_count() and a.truncated() == s.truncated() \
					and str(a.line_layout()) == str(s.line_layout())
				n += 1
				if not same:
					runner.check(false, "k %d box %s: '%s' lays out differently on @2 (w %d/%d, lines %d/%d, %s / %s)" % [Display.k, b,
						t.left(40), a.width(), s.width(), a.line_count(), s.line_count(), a.line_layout(), s.line_layout()])
				a.free()
				s.free()
	runner.check(n > 2000 and sharp == n, "%d layouts measured both ways, %d on @2" % [n, sharp])
	parent.free()


## The role split (CONTRACT §6.1) on the real scene: body text reads on @2, display text does not.
func test_the_role_split_on_the_real_scene() -> void:
	Display.update(Vector2(780, 1688))
	m = load("res://scenes/main.tscn").instantiate()
	m.store = SaveStore.new(dir)
	tree.root.add_child(m)
	for i in 3:
		await tree.process_frame
	var reading := 0
	var display := 0
	for p: PxText in tree.get_nodes_in_group("pxtext"):
		if p.reading:
			reading += 1
		else:
			display += 1
	runner.check(reading > 0 and display > 0, "both roles are in use (%d reading, %d display)" % [reading, display])
	runner.check(m.ticker._tag_text.reading == false, "the ticker tag stays display")
	runner.check(m.top_bar.bank.reading == false and m.top_bar.bps.reading == false, "the counter and the rate stay display")
	runner.check((m.toasts._text as PxText).reading and (m.toasts._preview as PxText).reading and not (m.toasts._head as PxText).reading,
		"toasts and the chat toast's line read; its sender head is display")


# ------------------------------------------------------------------ Ftue: the tab bar with C1

func test_the_tab_bar_counts_sources_owned_in_total() -> void:
	var s := GameState.fresh()
	s.taps_lifetime = 3
	var first: String = Content.producer_ids()[0]
	var open_at := int(Content.data().get("coalition", {}).get("openAtSourcesOwned", 3))
	s.owned[first] = open_at - 1
	runner.check(not Ftue.reveals(s)["tabs"], "%d of one kind: no tab bar yet" % (open_at - 1))
	s.owned[first] = open_at
	runner.check(Ftue.reveals(s)["tabs"], "%d taxpayers (one kind): the tab bar, as C1 opens the group" % open_at)
	runner.check(Ftue.owned_total(s) == Conditions.sources_owned(s), "Ftue and the sim count the same")
	s.bananas = 1e6
	runner.check(Coalition.c1_ready(s) == Ftue.reveals(s)["tabs"], "the sim's C1 and the tab slot agree")


# ------------------------------------------------------------------ the first tap after Esc folds the court card

func _touch_down(p: Vector2, idx: int = 0) -> void:
	var e := InputEventScreenTouch.new()
	e.index = idx
	e.position = p
	e.pressed = true
	m._unhandled_input(e)


func _touch_up(p: Vector2, idx: int = 0) -> void:
	var e := InputEventScreenTouch.new()
	e.index = idx
	e.position = p
	e.pressed = false
	m._unhandled_input(e)


func test_the_first_tap_after_esc_folds_the_court_card_reaches_t3() -> void:
	m = load("res://scenes/main.tscn").instantiate()
	m.store = SaveStore.new(dir)
	tree.root.add_child(m)
	for i in 3:
		await tree.process_frame
	m.ftue.handoff_ms = 1.0
	m.commit_pick("bibi")   # LEADER_PICK (leader select): Bibi's round, the shipped game
	var hat: Vector2 = L.magician_hit().get_center() + Vector2(m._sx, m._stage_y)
	_touch_down(hat)
	_touch_up(hat)
	m._last_tap_ms = -1e9
	# the summons opens the court card, expanded
	m.state.investigation["revealed"] = true
	m.state.investigation["suspicion"] = 100.0
	m._step_economy(1.0 / 60.0, false)
	for i in 2:
		await tree.process_frame
	m.court._anim = {}
	Coalition.open_group(m.state, m.d, func() -> float: return 0.0)
	var ids := Content.producer_ids()
	for i in 3:
		m.state.owned[ids[i]] = 1
	for i in 2:
		await tree.process_frame
	var cv: CourtView = m.court
	var chat: ChatView = m.chat
	chat.open()
	chat._end_anim(true)
	chat.reveal_all()
	chat._open_ms -= 1000.0
	await tree.process_frame
	runner.check(cv.expanded() and chat.is_open(), "the court card is expanded over T3")
	runner.check(m.layer_depth() == 2, "two layers (T3, the card)")
	var e := InputEventKey.new()
	e.keycode = KEY_ESCAPE
	e.pressed = true
	m._unhandled_input(e)
	runner.check(cv.folding() and not cv.expanded() and chat.is_open(), "Esc folds the card (the fold runs), T3 stays")
	runner.check(m.layer_depth() == 1, "the folding card is no longer a layer (history rewinds one entry)")
	var h: Dictionary = m.history.sync(m.layer_depth())
	runner.check(h.get("back", 0) == 1 or m.history.pushed == 1, "R9: the history drops to one entry (%s)" % [h])
	# a tap inside the folding card's old rect, on T3's thread: T3 takes it, not the fold
	var cr := cv.card_rect()
	var p := Vector2(360, cr.position.y + 24.0)
	var lp: Vector2 = p + Vector2(m._ox, m._lower_y)
	runner.check(not cv.pointer_down(p), "the folding card takes no press")
	_touch_down(lp)
	runner.check(String(m._presses.get(0, {}).get("kind", "")) == "chat", "the first tap after Esc goes to T3 (%s)" % m._presses.get(0, {}))
	_touch_up(lp)
	cv.update_view(CourtView.mc("courtCollapseMs") + 20.0, m.state, m.d, {"main": true, "covered": true})
	runner.check(cv.mode() == "chip", "the fold ends in the chip (%s)" % cv.mode())
