extends RefCounted
## Motion with logic (animator, 2026-09-29): Bibi's court-day exit and return (ui/court_motion.gd,
## BigBanana.court_*; motion/state-graph-magician.md §1.3, §3, §5), the court window's echo
## (ui/court_echo.gd), the brawl cloud's boil (ChatView.brawl_boil), the toast's exit fade and the
## prepared leader walk (ui/leader_walk.gd). Each has a reduced-motion path; every offset is a whole
## art px. The integration cases boot the real scene on the game content.

var runner: Object
var tree: SceneTree
var dir := ""
var m: Node


func setup(r: Object) -> void:
	TestFixture.use_game_content()
	tree = r as SceneTree
	dir = "user://test_motion_court_%d" % Time.get_ticks_usec()
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
	TestFixture.use_game_content()


func _boot() -> void:
	m = load("res://scenes/main.tscn").instantiate()
	m.store = SaveStore.new(dir)
	tree.root.add_child(m)
	for i in 3:
		await tree.process_frame
	m.ftue.handoff_ms = 1.0
	var p: Vector2 = L.magician_hit().get_center() + Vector2(m._ox, m._stage_y)
	for pressed in [true, false]:
		var e := InputEventScreenTouch.new()
		e.position = p
		e.pressed = pressed
		m._unhandled_input(e)
	m.set_process(false)   # the test drives the Magician's clock itself


## Runs a CourtMotion for `ms` in 16-ms steps, collecting its events.
func _run(c: CourtMotion, ms: float, into: Array = []) -> Array:
	var t := 0.0
	while t < ms - 0.001:
		var dt := minf(16.0, ms - t)
		c.tick(dt)
		t += dt
		into.append_array(c.take_events())
	return into


func _kinds(ev: Array) -> Array:
	return ev.map(func(e: Dictionary) -> String: return str(e["kind"]))


# ------------------------------------------------------------------ CourtMotion (pure)

func test_the_exit_startles_zips_left_and_the_hat_comes_back() -> void:
	var c := CourtMotion.new()
	c.off_ap = -170.0
	c.start(false)
	runner.check(c.in_court() and c.body == "exitStartle" and c.body_frame() == 1 and c.body_dx_ap() == 0, "f0: tap.f1, the startle, on the mark")
	var ev := _run(c, 200.0)
	runner.check(c.body_frame() == 2 and c.body_dx_ap() == 1, "t 180: tap.f2 and the 1-ap lean away from the exit (dx %d)" % c.body_dx_ap())
	_run(c, 140.0, ev)
	runner.check(c.body == "exitZip" and _kinds(ev).has("dust") and c.smear(), "t 330: the zip, dust at the mark, the after-images on")
	var xs: Array = []
	for i in 13:
		c.tick(16.0)
		xs.append(c.body_dx_ap())
	var mono := true
	for i in range(1, xs.size()):
		mono = mono and int(xs[i]) <= int(xs[i - 1])
	runner.check(mono and c.travel_dir() == -1 or c.body == "offstage", "he zips screen-left, never back (%s)" % str(xs))
	_run(c, 40.0)
	runner.check(c.body == "offstage" and not c.body_visible() and not c.hat_visible(), "t 530: gone; the stage is empty for a beat")
	_run(c, 260.0)
	runner.check(c.hat == "zipIn" and c.hat_dx_ap() < 0, "t 780: the hat zips in from the left (dx %d)" % c.hat_dx_ap())
	_run(c, 310.0)
	runner.check(c.hat == "hover" and c.hat_dx_ap() == 0, "t 1080: the hat hovers on his mark")
	var ys: Dictionary = {}
	for i in 120:
		c.tick(16.0)
		ys[c.hat_dy_ap()] = true
	runner.check(ys.keys().all(func(y: int) -> bool: return y <= 0 and y >= -2) and ys.size() >= 2, "the hover bobs 0 → −2 ap in whole art px (%s)" % str(ys.keys()))


func test_the_return_fetches_him_and_he_lands() -> void:
	var c := CourtMotion.new()
	c.start(false)
	_run(c, 1200.0)
	c.finish()
	runner.check(c.body == "fetching" and c.hat == "zipOut" and not c.body_visible(), "courtEnd: the hat zips off to fetch him")
	var ev := _run(c, 160.0)
	runner.check(not c.hat_visible() and c.body == "emptyBeat", "the hat gone, 150 ms of empty stage (%s)" % c.body)
	_run(c, 150.0, ev)
	runner.check(c.body == "returnZip" and c.body_visible() and c.body_frame() == 2 and c.body_dx_ap() < 0, "he zips back in from the left on tap.f2")
	_run(c, 230.0, ev)
	runner.check(not c.in_court() and c.body_dx_ap() == 0, "on his mark")
	var land := ev.filter(func(e: Dictionary) -> bool: return e["kind"] == "land")
	runner.check(land.size() == 1 and int(land[0]["from"]) == 1 and bool(land[0]["dust"]), "the land: tap from f1 with dust (%s)" % str(land))


func test_early_and_quick_returns() -> void:
	var c := CourtMotion.new()
	c.start(false)
	_run(c, 200.0)
	c.finish()
	var ev: Array = c.take_events()
	runner.check(not c.in_court() and c.body_dx_ap() == 0 and ev.size() == 1 and int(ev[0]["from"]) == 3 and not bool(ev[0]["dust"]),
		"courtEnd during the startle: cut to the mark, land from the frame after (%s)" % str(ev))
	c.start(false)
	_run(c, 400.0)
	var x0 := c.body_dx_ap()
	c.finish()
	runner.check(c.body == "returnQuick", "courtEnd mid-zip: reverse from where he is (dx %d)" % x0)
	ev = _run(c, 160.0)
	runner.check(not c.in_court() and _kinds(ev).has("land"), "back and landed within 150 ms")
	c.start(false)
	_run(c, 1200.0)
	c.finish(true)
	_run(c, 125.0)
	runner.check(c.body == "returnZip", "the quick return (an election): a 120 ms fetch and no empty beat (%s)" % c.body)


func test_taps_hit_the_hat_during_court_day() -> void:
	var c := CourtMotion.new()
	runner.check(not c.tap(false), "on stage the body takes its own taps")
	c.start(false)
	runner.check(c.tap(false) and c.take_events().is_empty(), "before the hat is back a tap is credited, nothing moves")
	_run(c, 1200.0)
	runner.check(c.tap(false) and c.hat == "hatTap", "on the hovering hat: the hop")
	c.tick(16.0)
	c.tap(false)   # during the rise: merged
	var ev := _run(c, 100.0)
	var coins := ev.filter(func(e: Dictionary) -> bool: return e["kind"] == "coins")
	runner.check(coins.size() == 1 and int(coins[0]["n"]) == 3, "coins at the hop's peak: 2 + the merged tap (%s)" % str(coins))
	runner.check(c.hat_dy_ap() < 0 and c.hat_dy_ap() >= -4, "the hat is up to 4 ap off its mark (%d)" % c.hat_dy_ap())
	_run(c, 200.0)
	c.tap(true)
	ev = []
	ev.append_array(c.take_events())
	runner.check(c.hat == "hatCrit" and _kinds(ev).has("rabbit"), "a crit: the rabbit pops up and sees the court")
	var peak := 0
	var got: Array = []
	for i in 45:
		c.tick(16.0)
		peak = maxi(peak, c.rabbit_up_ap())
		got.append_array(c.take_events())
	runner.check(peak >= 12 and c.rabbit_up_ap() == 0 and c.hat == "hover", "it rises 12 ap, holds, sinks, and the hat hovers again (peak %d)" % peak)
	runner.check(got.filter(func(e: Dictionary) -> bool: return e["kind"] == "coins" and int(e["n"]) == 6).size() == 1, "6 coins from the crit")
	c.tap(false, true)
	runner.check(c.hat == "hatHush" and _run(c, 320.0).is_empty(), "a paused tap: the rabbit's ears peek and duck, no coins")


func test_reduced_motion_fades_instead_of_zipping() -> void:
	var c := CourtMotion.new()
	c.start(true)
	var ev: Array = []
	var dxs: Dictionary = {}
	var smeared := false
	for i in 12:
		c.tick(16.0)
		ev.append_array(c.take_events())
		dxs[c.body_dx_ap()] = true
		smeared = smeared or c.smear()
	runner.check(dxs.keys() == [0] and not smeared and c.body_frame() == -1 and not _kinds(ev).has("dust"), "no startle, lean, zip or dust")
	runner.check(c.body_alpha() < 0.1 or c.body == "offstage", "the body faded out in 150 ms (a %.2f, %s)" % [c.body_alpha(), c.body])
	_run(c, 200.0)
	runner.check(c.hat == "hover" and c.hat_alpha() == 1.0 and c.hat_dx_ap() == 0, "the hat faded in on the mark (%s)" % c.hat)
	var moved := false
	for i in 200:
		c.tick(16.0)
		moved = moved or c.hat_dy_ap() != 0 or c.rabbit_up_ap() != 0
	runner.check(not moved, "the hat is static: no bob, no peek")
	c.tap(false)
	ev = []
	ev.append_array(c.take_events())
	runner.check(ev.size() == 1 and int(ev[0]["n"]) == 3 and c.hat_dy_ap() == 0, "a tap: three coins at f0, no hop (%s)" % str(ev))
	c.tick(16.0)
	c.finish()
	ev = _run(c, 400.0)
	runner.check(not c.in_court() and c.body_alpha() == 1.0 and not _kinds(ev).has("land"), "the return: hat out, body in, no land")


func test_reset_cuts_home() -> void:
	var c := CourtMotion.new()
	c.start(false)
	_run(c, 1200.0)
	c.reset()
	runner.check(not c.in_court() and not c.hat_visible() and c.body_dx_ap() == 0 and c.body_alpha() == 1.0, "a progress reset: home, hat gone")


# ------------------------------------------------------------------ on the stage (BigBanana)

func test_bibis_court_day_on_the_stage() -> void:
	await _boot()
	var bb: BigBanana = m.bb
	if bb.hero == null:
		runner.check(false, "the Magician strip loads")
		return
	for i in 40:
		bb.update_view(16.0)   # the boot tap's strip ends on idle
	m.state.investigation["revealed"] = true
	m.state.investigation["phase"] = "summons"
	Investigation.testify(m.state)
	runner.check(BigBanana.wants_court(m.state), "Bibi's round in court: the stage wants him gone")
	var feet := L.magician_feet()
	bb.court_sync(true)
	bb.update_view(16.0)
	runner.check(bb.court.in_court() and bb.hero.visible and bb.hero.anim == "tap" and bb.hero.frame == 1, "f0: the startle frame")
	var off := false
	for i in 40:
		bb.court_sync(true)
		bb.update_view(16.0)
		var x := bb.hero.position.x - feet.x
		off = off or not bb.hero.visible
		runner.check(is_equal_approx(fmod(absf(x), 4.0), 0.0), "the body moves in whole art px (dx %.1f)" % x)
		if not bb.hero.visible:
			break
	runner.check(off and not bb.on_stage(), "he has left the stage")
	for i in 60:
		bb.court_sync(true)
		bb.update_view(16.0)
	var hat := bb.hat_node()
	runner.check(hat.visible and hat.position.x + hat.texture.get_size().x * 2.0 == bb.hat_mark().x, "the hat hovers with its mouth on his mark")
	runner.check(is_equal_approx(fmod(hat.position.y, 4.0), fmod(bb.hat_mark().y, 4.0)), "on the art grid")
	var burst: Array = []
	bb.on_court_fx = func(kind: String, _at: Vector2, n: int) -> void: burst.append([kind, n])
	bb.tap(false)
	runner.check(bb.hero.anim != "tap" or not bb.hero.visible, "a tap in court does not play his tap (he is away)")
	for i in 10:
		bb.update_view(16.0)
	runner.check(burst.any(func(b: Array) -> bool: return b[0] == "coins"), "the hat pays its coins (%s)" % str(burst))
	# the sweat never beads on the empty stage
	m.thermo._next_drop = 0.0
	m.state.investigation["suspicion"] = 90.0
	m.thermo.update_view(16.0, m.state, {"main": true})
	runner.check(m.thermo.drops().is_empty(), "no sweat while he is away")
	# testimony over
	m.state.investigation["phase"] = "idle"
	for i in 60:
		bb.court_sync(BigBanana.wants_court(m.state))
		bb.update_view(16.0)
	runner.check(not bb.court.in_court() and bb.hero.visible and bb.hero.position == feet and not hat.visible, "back on his mark, the hat gone")


func test_only_bibi_goes_to_court() -> void:
	var s := GameState.fresh()
	Leaders.set_salt(s, 3)
	var r := Politics.install(s, "bennett")
	if not r.get("ok", false):
		runner.check(true, "no leader select in this content")
		return
	s.investigation["phase"] = "court"
	runner.check(not BigBanana.wants_court(s), "Bennett's hazard is the press day: he never leaves the stage")
	var e := CourtEcho.level(true, 100.0, "court")
	runner.check(e == "open", "the echo's level is data; the controller gates it on Leaders.has_court (%s)" % e)
	var s2 := GameState.fresh()
	Politics.install(s2, "bibi")
	s2.investigation["phase"] = "court"
	runner.check(BigBanana.wants_court(s2), "Bibi's court day takes him off")


# ------------------------------------------------------------------ the court window echo

func test_the_court_window_echo() -> void:
	runner.check(CourtEcho.level(false, 100.0, "court") == "off", "not shown: off")
	runner.check(CourtEcho.level(true, 50.0, "idle") == "dark" and CourtEcho.level(true, 80.0, "idle") == "hot" \
		and CourtEcho.level(true, 96.0, "idle") == "boil" and CourtEcho.level(true, 20.0, "summons") == "open", "dark < 75 ≤ hot < 95 ≤ boil; the summons and court day open the window")
	runner.check(not CourtEcho.glow_on("hot") and CourtEcho.glow_on("boil") and CourtEcho.glow_on("open"), "the halo: steady from 95 % and while open")
	var lo := 1.0
	var hi := 0.0
	var prev := CourtEcho.breath("open", 0.0, false)
	var max_step := 0.0
	for i in 200:
		var b := CourtEcho.breath("open", float(i) * 16.0, false)
		lo = minf(lo, b)
		hi = maxf(hi, b)
		max_step = maxf(max_step, absf(b - prev))
		prev = b
	runner.check(lo >= CourtEcho.BREATH_LOW - 0.001 and hi <= 1.0 and hi - lo > 0.3, "the open window breathes between 60 %% and 100 %% (%.2f-%.2f)" % [lo, hi])
	runner.check(max_step < 0.05 and CourtEcho.BREATH_MS >= 1000.0 / 3.0, "a slow ease (≤ 5 %% per frame, %.2f Hz), never a flicker" % (1000.0 / CourtEcho.BREATH_MS))
	runner.check(CourtEcho.breath("open", 800.0, true) == 1.0 and CourtEcho.breath("boil", 800.0, false) == 1.0, "reduced motion (and every other level): held lit")
	runner.check(CourtEcho.spot("courthouse").x < 0.0, "the courthouse era has its own clock panel: no echo")
	# the 2D Artist's spots (kit data, ui.court_window.spots): the whole house at or below art row 110, where the
	# phones keep the stage art, and inside the 180-column art (sprite 24×22, pivot bottom centre)
	var kit: Dictionary = SpriteStrip.manifest().get("ui", {}).get("court_window", {}).get("spots", {})
	for era in ["balfour", "knesset", "washington"]:
		var sp := CourtEcho.spot(era)
		runner.check(kit.has(era) and sp == Vector2(float(kit[era][0]), float(kit[era][1])), "%s: the spot is the kit's data (%s)" % [era, sp])
		runner.check(sp.y - CourtEcho.PIVOT.y >= 110.0 and sp.x - CourtEcho.PIVOT.x >= 0.0 and sp.x - CourtEcho.PIVOT.x + 24.0 <= 180.0,
			"%s: the house (top row %d) sits at or below art row 110, inside the art" % [era, int(sp.y - CourtEcho.PIVOT.y)])


func test_the_echo_on_the_stage() -> void:
	await _boot()
	var ce: CourtEcho = m.court_echo
	m.state.investigation["revealed"] = true
	m.state.investigation["suspicion"] = 80.0
	for i in 40:
		ce.update_view(16.0, m.state, "balfour", true)
	var dr := ce.drawn()
	runner.check(dr["house"] > 0.99 and dr["lit"] > 0.99 and not dr["glow"], "≥ 75 %%: the courthouse with its window lit (%s)" % str(dr))
	var pos: Vector2 = ce._house.position
	runner.check(is_equal_approx(fmod(pos.x - L.magician_feet().x, 4.0), 0.0) and is_equal_approx(fmod(pos.y - L.magician_feet().y, 4.0), 0.0), "on the stage art's grid (%s)" % str(pos))
	runner.check(pos.y >= float(L.STAGE["y"]) + CourtEcho.TOP_CLEAR, "never under the top bar or the toast dock (y %.0f)" % pos.y)
	for i in 40:
		ce.update_view(16.0, m.state, "balfour", false)
	runner.check(ce.drawn()["house"] < 0.01, "another leader's round: no courthouse")


# ------------------------------------------------------------------ the brawl boil, the toast, the walk

func test_the_brawl_cloud_boils_in_whole_pixels() -> void:
	var offs: Dictionary = {}
	var frames: Dictionary = {}
	var rest_ok := true
	for i in 240:
		var t := float(i) * 10.0
		var b := ChatView.brawl_boil(t, 4, false)
		var o: Vector2i = b["off"]
		offs[o] = true
		frames[int(b["frame"])] = true
		if fmod(t, ChatView.BOIL_PERIOD_MS) >= ChatView.BOIL_PERIOD_MS - ChatView.BOIL_REST_MS:
			rest_ok = rest_ok and o == Vector2i.ZERO
	runner.check(frames.size() == 4, "the kit's 4 frames loop (%s)" % str(frames.keys()))
	runner.check(offs.size() == 5 and offs.keys().all(func(o: Vector2i) -> bool: return absi(o.x) + absi(o.y) <= 1), "a 1-ap ring plus the rest (%s)" % str(offs.keys()))
	runner.check(rest_ok, "each period ends on a 300 ms rest")
	var rm := ChatView.brawl_boil(530.0, 4, true)
	runner.check(int(rm["frame"]) == 0 and rm["off"] == Vector2i.ZERO, "reduced motion: frame 0, still")


func test_the_toast_fades_out_inside_its_three_seconds() -> void:
	await _boot()
	var t: Toasts = m.toasts
	_quiet(t)
	t.reduced_motion = false
	t.show_toast("x")
	t.update_view(16.0)
	t.update_view(Toasts.SHOW_MS - 80.0)
	runner.check(t._plate.visible and t._plate.modulate.a < 0.99 and t._plate.modulate.a > 0.0, "the last 120 ms fade (a %.2f)" % t._plate.modulate.a)
	t.update_view(100.0)
	runner.check(not t._plate.visible, "then it is gone")
	t.reduced_motion = true
	_quiet(t)
	t.show_toast("y")
	t.update_view(16.0)
	t.update_view(Toasts.SHOW_MS - 80.0)
	runner.check(t._plate.visible and t._plate.modulate.a == 1.0, "reduced motion: no fade, a cut")


func _quiet(t: Toasts) -> void:
	t._queue.clear()
	t._tags.clear()
	t._chats.clear()
	t._t = -1.0
	t._gap = 0.0


func test_the_leader_walk_pose() -> void:
	var off := LeaderWalk.off_for(Rect2(-80, -436, 160, 440), 376.0, 0.0, 1)
	runner.check(off > 0.0 and 376.0 + off * 4.0 - 80.0 > 720.0, "walking out screen-right clears the canvas (%.0f ap)" % off)
	var prev := 0
	var mono := true
	var bobbed := false
	for i in 36:
		var p := LeaderWalk.pose(float(i) * 16.0, LeaderWalk.OUT_MS, off, true, false)
		mono = mono and int(p["dx"]) >= prev
		prev = int(p["dx"])
		bobbed = bobbed or int(p["dy"]) == -1
		runner.check(typeof(p["dx"]) == TYPE_INT and int(p["dy"]) in [0, -1], "whole art px")
	var end := LeaderWalk.pose(LeaderWalk.OUT_MS, LeaderWalk.OUT_MS, off, true, false)
	runner.check(mono and bobbed and int(end["dx"]) == int(roundf(off)), "out: an even walk off, bobbing on the beat")
	var land := LeaderWalk.pose(LeaderWalk.IN_MS, LeaderWalk.IN_MS, -off, false, false)
	runner.check(int(land["dx"]) == 0 and int(land["dy"]) == 0, "in: he lands on the feet point, flat")
	var rm := LeaderWalk.pose(75.0, LeaderWalk.IN_MS, -off, false, true)
	runner.check(int(rm["dx"]) == 0 and is_equal_approx(float(rm["alpha"]), 0.5), "reduced motion: a fade on the mark, no travel")
	runner.check(LeaderWalk.OUT_MS + LeaderWalk.IN_MS <= 1500.0, "out + in fit the swap's 1.5 s budget")


func test_the_os_reduced_motion_preference_reads_the_web_bridges_int() -> void:
	var main_script: GDScript = load("res://scripts/main.gd")
	runner.check(main_script.js_bool(1) and main_script.js_bool(true) and main_script.js_bool(1.0), "the bridge's 1 (and true) is reduce")
	runner.check(not main_script.js_bool(0) and not main_script.js_bool(false) and not main_script.js_bool(null) and not main_script.js_bool(""), "0, false, null: no preference")
