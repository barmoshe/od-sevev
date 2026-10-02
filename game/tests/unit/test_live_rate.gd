extends RefCounted
## The live rate line (Bar 2026-10-02, top_bar.gd TAP_*): Row A's "+N ₪ לשנייה" = passive + the
## taps actually paid lately, smoothed, redrawn at most 5 times a second, back to the passive rate
## within 3 s of the last tap; the hop answers the passive rate only, and the sim never sees it.

var runner: Object
var tree: SceneTree
var dir := ""
var m: Node
var tb: TopBar

const FRAME := 1000.0 / 60.0


func setup(r: Object) -> void:
	TestFixture.use_game_content()
	tree = r as SceneTree
	dir = "user://test_live_rate_%d" % Time.get_ticks_usec()
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
	m.set_process(false)   # the test is the frame loop
	tb = m.top_bar
	tb.reduced_motion = true
	tb.reset_rate()


## `ms` of frames at 60 fps; a tap of `value` every `every` ms (0 = none). Returns the texts drawn.
func _run(ms: float, passive: float, every: float, value: float) -> Array:
	var texts: Array = []
	var t := 0.0
	var next_tap := 0.0
	while t < ms:
		if every > 0.0 and t >= next_tap:
			tb.note_tap(value)
			next_tap += every
		tb.update_view(FRAME)
		tb.set_bps(passive, 1.0, false)
		if texts.is_empty() or texts.back() != tb.bps.text:
			texts.append(tb.bps.text)
		t += FRAME
	return texts


func _line(rate: float) -> String:
	return Strings.s("HUD_BPS", {"rate": Fmt.rate(rate)})


func test_steady_tapping_adds_what_the_taps_pay() -> void:
	await _boot()
	_run(100.0, 10.0, 0.0, 0.0)
	runner.check(tb.bps.text == _line(10.0), "idle: the passive rate (%s)" % tb.bps.text)
	_run(3000.0, 10.0, 125.0, 5.0)   # 8 taps a second of 5 ₪ = 40 ₪/s
	runner.check(absf(tb.tap_rate() - 40.0) <= 4.0, "the taps' rate settles at 40 ₪/s (%.1f)" % tb.tap_rate())
	runner.check(absf(tb.shown_rate() - 50.0) <= 4.0 and tb.bps.text == _line(tb.shown_rate()), "the line shows passive + taps (%s)" % tb.bps.text)
	runner.check(tb.bps.tint == TopBar.C_RATE_TAP and tb.bps.self_modulate.a == 1.0, "taps carry it: the pale-gold cue at full alpha")


func test_it_rises_within_a_second_and_never_shimmers() -> void:
	await _boot()
	_run(100.0, 10.0, 0.0, 0.0)
	var texts := _run(1000.0, 10.0, 100.0, 4.0)   # 40 ₪/s
	runner.check(tb.shown_rate() >= 30.0, "after 1 s of tapping it carries most of the taps (%.1f of 50)" % tb.shown_rate())
	runner.check(texts.size() <= 6, "at most 5 redraws a second (%d texts in 1 s)" % texts.size())
	_run(1000.0, 10.0, 100.0, 4.0)   # settles
	var steady := _run(2000.0, 10.0, 100.0, 4.0)
	runner.check(steady.size() <= 3, "steady tapping holds a steady number (%s)" % str(steady))


func test_it_falls_back_to_the_passive_rate_within_three_seconds() -> void:
	await _boot()
	_run(3000.0, 10.0, 125.0, 5.0)
	var peak := tb.shown_rate()
	_run(1000.0, 10.0, 0.0, 0.0)
	var mid := tb.shown_rate()
	runner.check(mid < peak and mid > 10.0, "1 s after: falling, not gone (%.1f → %.1f)" % [peak, mid])
	_run(2050.0, 10.0, 0.0, 0.0)
	runner.check(tb.tap_rate() == 0.0 and tb.bps.text == _line(10.0), "3 s after: exactly the passive rate (%s)" % tb.bps.text)
	runner.check(tb.bps.tint == Art.col(Art.theme["statText"]["bps"]), "and its own green")


func test_crits_and_frenzies_count_their_real_value() -> void:
	await _boot()
	_run(2500.0, 0.0, 250.0, 100.0)   # 4 taps a second of 100 (a crit's worth)
	runner.check(absf(tb.tap_rate() - 400.0) <= 40.0, "the taps' actual value, not a count (%.0f)" % tb.tap_rate())
	tb.note_tap(0.0)
	tb.note_tap(-5.0)
	tb.note_tap(INF)
	_run(100.0, 0.0, 0.0, 0.0)
	runner.check(is_finite(tb.tap_rate()), "a paused (0), negative or infinite value is ignored")


func test_the_hop_answers_the_passive_rate_only() -> void:
	await _boot()
	tb.reduced_motion = false
	_run(3500.0, 10.0, 0.0, 0.0)
	_run(2000.0, 10.0, 100.0, 4.0)
	runner.check(not Juice.has(tb.bps) and tb.bps.position.y == TopBar.RATE_Y, "tapping moves the number, never the hop")
	tb.set_bps(12.0, 1.0, false)
	runner.check(Juice.has(tb.bps), "a passive rise still hops")


func test_the_sim_never_sees_it() -> void:
	await _boot()
	var s: GameState = m.state
	var id: String = Content.producer_ids()[0]
	s.owned[id] = 3
	var before := Economy.derive(s).bps
	var price := float(Economy.quote(s, id)["cost"])
	_run(2000.0, before, 100.0, 50.0)
	runner.check(Economy.derive(s).bps == before and float(Economy.quote(s, id)["cost"]) == price, "bps and prices are the sim's, untouched")


func test_the_pour_line_shows_what_the_taps_pour() -> void:
	await _boot()
	tb.set_bps(12.0, 1.0, true)
	runner.check(tb.bps.text == Strings.s("HUD_BPS_POUR"), "S07 idle: HUD_BPS_POUR")
	var t := 0.0
	while t < 2000.0:
		if fmod(t, 125.0) < FRAME:
			tb.note_tap(6.0)
		tb.update_view(FRAME)
		tb.set_bps(12.0, 1.0, true)
		t += FRAME
	runner.check(tb.bps.text == _line(tb.shown_rate()) and tb.shown_rate() > 30.0 and tb.bps.tint == Art.col(Art.theme["statText"]["bpsFrenzy"]),
		"S07 tapping: the poured rate in the frenzy tint (%s)" % tb.bps.text)
	tb.set_bps(12.0, 1.0, false)
	runner.check(tb.shown_rate() > 12.0, "back to passive + taps")
