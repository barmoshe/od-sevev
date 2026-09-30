extends RefCounted
## The leader swap's walk (animator wave B; design/leader-select-spec.md §9.3.4,
## motion/state-graph-magician.md §9): LeaderWalk's state machine (home → out → gone → in → home),
## the walk-out when the EVOLVE_TX card lifts, the walk-in after a pick (Dubi's line after the
## landing), the undo (re-pick), the court day yielding to a walk (one owner of the figure's
## position), and reduced motion (fades on the mark). Every offset is a whole art px. The
## integration cases boot the real scene on the game content.

var runner: Object
var tree: SceneTree
var dir := ""
var m: Node


func setup(r: Object) -> void:
	TestFixture.use_game_content()
	tree = r as SceneTree
	dir = "user://test_leader_walk_%d" % Time.get_ticks_usec()
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


## Runs the controller's frame `n` times at `ms` a frame.
func _frames(n: int, ms := 16.0) -> void:
	for i in n:
		m._process(ms / 1000.0)


## The figure's offset from the feet point in logical px.
func _off() -> Vector2:
	return (m.bb.hero as SpriteStrip).position - L.magician_feet()


func _on_grid(v: Vector2) -> bool:
	return is_equal_approx(fmod(absf(v.x), 4.0), 0.0) and is_equal_approx(fmod(absf(v.y), 4.0), 0.0)


# ------------------------------------------------------------------ LeaderWalk (pure)

func test_the_walk_state_machine() -> void:
	var w := LeaderWalk.new()
	w.feet = Vector2(376, 900)
	var r := Rect2(-80, -436, 160, 440)
	runner.check(w.state() == "home" and w.shows() and w.alpha() == 1.0 and w.dx_ap() == 0, "home: on the mark, shown")
	w.walk_out(1, r, 0.0)
	runner.check(w.state() == "out" and w.walking() and w.dx_ap() == 0 and w.left_ms() == LeaderWalk.OUT_MS, "out: f0 on the mark, 560 ms to go")
	var prev := 0
	var mono := true
	var t := 0.0
	while w.walking():
		w.advance(16.0)
		t += 16.0
		mono = mono and w.dx_ap() >= prev
		prev = w.dx_ap()
	runner.check(mono and w.gone() and not w.shows() and absf(t - LeaderWalk.OUT_MS) < 16.0, "out: screen-right, never back, then gone at %.0f ms" % t)
	runner.check(376.0 + float(w.off_ap) * 4.0 + r.position.x >= 720.0 + 16.0, "gone: the whole frame is off the canvas, 4 ap clear")
	w.advance(500.0)
	runner.check(w.gone(), "gone holds (no timer brings him back)")
	w.walk_in(-1, r, 0.0)
	runner.check(w.state() == "in" and w.shows() and w.dx_ap() < 0 and 376.0 + float(w.dx_ap()) * 4.0 + r.end.x <= 0.0,
		"in: f0 fully off the canvas at screen-left (dx %d ap)" % w.dx_ap())
	t = 0.0
	prev = w.dx_ap()
	mono = true
	var grid := true
	while w.walking():
		w.advance(16.0)
		t += 16.0
		mono = mono and w.dx_ap() >= prev
		prev = w.dx_ap()
		grid = grid and w.dy_ap() in [0, -1]
	runner.check(mono and grid and w.state() == "home" and w.dx_ap() == 0 and w.dy_ap() == 0 and absf(t - LeaderWalk.IN_MS) < 16.0,
		"in: rightward to the mark, bobbing 1 ap, landing flat at %.0f ms" % t)
	w.walk_in(-1, r, 0.0)
	w.advance(100.0)
	w.land()
	runner.check(w.state() == "home" and w.dx_ap() == 0 and w.alpha() == 1.0, "land(): a walk-in ends on the mark now")
	w.walk_out(1, r, 0.0)
	w.land()
	runner.check(w.state() == "out", "land() leaves a walk-out alone")
	w.home()
	runner.check(w.state() == "home" and w.shows(), "home() cuts to the mark from anywhere")
	runner.check(LeaderWalk.OUT_MS + LeaderWalk.IN_MS <= 1500.0, "out + in fit the swap's 1.5 s budget")


func test_reduced_motion_walks_are_fades_on_the_mark() -> void:
	var w := LeaderWalk.new()
	w.reduced = true
	w.walk_out(1, Rect2(-80, -436, 160, 440), 0.0)
	w.advance(75.0)
	runner.check(w.dx_ap() == 0 and w.dy_ap() == 0 and is_equal_approx(w.alpha(), 0.5), "out: no travel, half faded at 75 ms")
	w.advance(80.0)
	runner.check(w.gone() and not w.shows(), "out: gone after 150 ms")
	w.walk_in(-1, Rect2(-80, -436, 160, 440), 0.0)
	runner.check(w.dx_ap() == 0 and w.alpha() == 0.0 and w.left_ms() == LeaderWalk.RM_FADE_MS, "in: on the mark, transparent, 150 ms to go")
	w.advance(160.0)
	runner.check(w.state() == "home" and w.alpha() == 1.0, "in: shown after 150 ms")


func test_the_tx_cues_the_walk_when_the_card_lifts() -> void:
	for reduced: bool in [false, true]:
		var tx := EvolveTx.new()
		var fired: Array = []
		tree.root.add_child(tx)
		await tree.process_frame
		tx.start({"round": 2, "multBefore": 1.0, "multAfter": 1.1, "gained": 3, "era": ""}, reduced, {
			"seam": func() -> void: fired.append("seam"),
			"walk": func() -> void: fired.append("walk"),
			"unlock": func() -> void: fired.append("unlock")})
		var t := 0.0
		var at := -1.0
		while tx.running and t < 5000.0:
			tx.update_view(10.0)
			t += 10.0
			if at < 0.0 and fired.has("walk"):
				at = t
		runner.check(absf(at - tx.walk_ms(reduced)) <= 10.0 and fired == ["seam", "walk", "unlock"],
			"%s: the walk cue at the card's lift (%.0f ms, want %.0f), after the seam, before the unlock (%s)" % ["rm" if reduced else "full", at, tx.walk_ms(reduced), str(fired)])
		runner.check(tx.walk_ms(reduced) + LeaderWalk.length_ms(true, reduced) - tx.total_ms(reduced) <= 260.0,
			"%s: the walk-out ends ≤ 260 ms after the card is gone" % ("rm" if reduced else "full"))
		tx.queue_free()


# ------------------------------------------------------------------ on the stage

func test_the_pick_walks_the_leader_in_and_dubi_waits_for_the_landing() -> void:
	await _boot()
	runner.check(m.commit_pick("bennett", true), "the pick commits")
	var bb: BigBanana = m.bb
	runner.check(bb.walking() and bb.leader_slug() == "bennett" and bb.hero.visible, "Bennett walks in")
	var feet := L.magician_feet()
	runner.check(bb.hero.position.x + bb.hero.rect().end.x <= -float(m._sx), "f0: fully off the canvas at screen-left (x %.0f)" % bb.hero.position.x)
	runner.check(bb.modulate.a == 1.0, "no placeholder fade on the stage node")
	var seq: Array = m._pick_seq
	runner.check(not seq.is_empty() and float(seq[0]["at"]) >= m._now + LeaderWalk.IN_MS + 100.0,
		"Dubi's line waits for the landing (+%.0f ms)" % (float(seq[0]["at"]) - m._now))
	var grid := true
	var xs: Array = []
	var said_before := false
	for i in 42:
		_frames(1)
		grid = grid and _on_grid(_off())
		xs.append(_off().x)
		if bb.walking() and m.toasts.saying():
			said_before = true
	runner.check(grid, "every frame on the art grid (whole art px)")
	runner.check(not bb.walking() and bb.hero.position == feet and bb.hero.modulate.a == 1.0, "landed on the feet point (%s)" % str(_off()))
	runner.check(not said_before, "no bubble while he walks")
	runner.check(xs.all(func(x: float) -> bool: return x <= 0.0), "he comes from the left and never passes the mark")


func test_a_tap_during_the_walk_in_plays_on_the_moving_figure() -> void:
	await _boot()
	m.commit_pick("liberman", true)
	var bb: BigBanana = m.bb
	_frames(10)
	var x0: float = _off().x
	m._start_from_title(L.magician_hit().get_center(), true)
	runner.check(m.state.taps_lifetime == 1 and bb.walking(), "the tap counts and the walk goes on")
	_frames(2)
	runner.check(_off().x > x0 and bb.hero.anim != "idle", "he keeps walking while he reacts (no pop to the mark)")
	_frames(40)
	runner.check(not bb.walking() and _off() == Vector2.ZERO, "and lands on the mark")


func test_the_undo_mid_walk_reopens_the_picker_and_the_repick_walks_in() -> void:
	await _boot()
	m.commit_pick("liberman", true)
	_frames(8)
	runner.check(m.bb.walking() and m.undo_visible(), "mid-walk, the undo chip is up")
	m._undo_pick()
	runner.check(m.mode == "pick" and not m.bb.visible, "the undo: the picker over an empty stage")
	runner.check(m._pick_seq.is_empty(), "Dubi's pending line is dropped")
	runner.check(m.commit_pick("golan", true) and m.bb.leader_slug() == "golan", "the re-pick")
	runner.check(m.bb.walking() and _off().x < 0.0, "Golan walks in from screen-left (dx %.0f)" % _off().x)
	_frames(8)
	m._undo_pick()
	runner.check(m.commit_pick("golan", true) and m.bb.walking() and _off().x < -200.0, "the same leader again: he walks in again from off-stage")
	_frames(45)
	runner.check(not m.bb.walking() and _off() == Vector2.ZERO, "on the mark")


func test_the_election_walks_the_leader_out_before_the_flash_or_picker() -> void:
	await _boot()
	m.commit_pick("bennett")
	m._set_mode("main", false)
	m._dev["on"] = true   # the dev-forced ceremony (no 61 gate); the flow after it is the real one
	var bb: BigBanana = m.bb
	m._start_evolve(true)
	runner.check(m.tx.running and m._tx_locked, "the ceremony runs, input locked")
	var walk_at: float = m.tx.walk_ms(false)
	var total: float = m.tx.total_ms(false)
	var t := 0.0
	var early := false
	var xs: Array = []
	var picker_during := false
	var unlocked := false
	var grid := true
	while t < total + 600.0:
		_frames(1)
		t += 16.0
		if t < walk_at - 16.0 and (bb.walking() or bb.walked_off()):
			early = true
		if bb.walking():
			xs.append(_off().x)
			grid = grid and _on_grid(_off())
			picker_during = picker_during or m.mode == "pick" or m.overlays.is_open()
			unlocked = unlocked or not m._tx_locked
	runner.check(not early, "he stands until the card lifts")
	runner.check(xs.size() >= 30 and float(xs[-1]) > float(xs[0]) and grid, "he walks off screen-right in whole art px (%d frames)" % xs.size())
	runner.check(not picker_during, "neither the flash nor the picker opens while he walks")
	runner.check(not unlocked, "input stays locked while he walks")
	runner.check(bb.walked_off() and not bb.hero.visible, "then the stage is empty")
	runner.check(not m._tx_locked, "input unlocks once he is off")
	runner.check(m.mode == "pick" or m.overlays.is_open(), "the flash or the picker follows (mode %s)" % m.mode)
	# the new round's pick walks the next leader in
	if m.overlays.is_open():
		m.overlays.close_all()
	for i in 5:
		_frames(1)
	if m.mode == "pick":
		runner.check(m.commit_pick("bennett", true) and bb.walking() and bb.hero.visible, "'again': the same leader walks back in")


func test_the_court_yields_to_the_walk() -> void:
	await _boot()
	m.commit_pick("bibi")
	m._set_mode("main", false)
	var bb: BigBanana = m.bb
	for i in 40:
		bb.update_view(16.0)
	# a court day that starts while he walks in waits for the landing
	bb.walk_in()
	bb.court_sync(true)
	bb.update_view(16.0)
	runner.check(not bb.court.in_court() and bb.walking(), "the court waits while he walks in")
	var owner_ok := true
	for i in 45:
		bb.court_sync(true)
		bb.update_view(16.0)
		if bb.walking():
			owner_ok = owner_ok and bb.hero.position == L.magician_feet() + Vector2(float(bb.walk.dx_ap()), float(bb.walk.dy_ap())) * 4.0
	runner.check(owner_ok, "while he walks, the walk alone places him (the court writes no offset)")
	runner.check(bb.court.in_court(), "after the landing the court day starts")
	# an election in court: the walk-out cuts the court home and walks him off
	for i in 20:
		bb.court_sync(true)
		bb.update_view(16.0)
	runner.check(bb.court.in_court() and not bb.on_stage(), "in court")
	bb.walk_out()
	runner.check(not bb.court.in_court() and not bb.hat_node().visible and bb.walking() and bb.hero.visible, "the walk-out cuts the court home (hat gone) and he walks")
	var monotone := true
	var prev := -1.0e9
	for i in 40:
		bb.court_sync(false)
		bb.update_view(16.0)
		if bb.walking():
			monotone = monotone and _off().x >= prev
			prev = _off().x
	runner.check(monotone and bb.walked_off(), "one owner: he walks off without a court pop")
	bb.court_reset()
	runner.check(not bb.walked_off() and bb.hero.visible and bb.hero.position == L.magician_feet(), "a reset brings him home")


func test_reduced_motion_the_swap_fades_on_the_mark() -> void:
	await _boot(true)
	m.commit_pick("deri", true)
	var bb: BigBanana = m.bb
	runner.check(bb.walking() and _off() == Vector2.ZERO and bb.figure_alpha() == 0.0, "walk-in: on the mark, faded out")
	var seq: Array = m._pick_seq
	runner.check(not seq.is_empty() and absf(float(seq[0]["at"]) - m._now - LeaderWalk.RM_FADE_MS - 120.0) < 1.0, "Dubi's line 120 ms after the 150 ms fade")
	_frames(5)
	runner.check(_off() == Vector2.ZERO and bb.figure_alpha() > 0.0 and bb.figure_alpha() < 1.0, "fading in, no travel (a %.2f)" % bb.figure_alpha())
	_frames(6)
	runner.check(not bb.walking() and bb.hero.modulate.a == 1.0, "in by 150 ms")
	m._set_mode("main", false)
	m._dev["on"] = true
	m._start_evolve(true)
	var t := 0.0
	var moved := false
	while m.tx.running or bb.walking() or m._tx_locked:
		_frames(1)
		t += 16.0
		moved = moved or _off() != Vector2.ZERO
		if t > 3000.0:
			break
	runner.check(not moved and bb.walked_off(), "walk-out: a fade on the mark, then gone")
	runner.check(t <= m.tx.total_ms(true) + 32.0, "no tail after the reduced ceremony (%.0f ms)" % t)
