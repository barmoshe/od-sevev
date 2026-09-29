extends RefCounted
## O3b, Dubi's news flash (ui/views/view_flash.gd, ux/rtl-map.md §7.2): the mic Dubi at an integer
## art scale that fits the card, the card showing after an election and closing on "לסבב הבחירות
## הבא", its audio (storyCard + babble), the beak on the Audio's blips, and the word salad rolled
## through the sim before each Dubi talking point. The real scene boots on the game content.

var runner: Object
var tree: SceneTree
var dir := ""
var m: Node
var sv: SubViewport


func setup(r: Object) -> void:
	TestFixture.use_game_content()
	tree = r as SceneTree
	dir = "user://test_flash_%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(dir)
	FlashCard.recent_points.clear()


func teardown() -> void:
	FlashCard.rng = randf
	FlashCard.recent_points.clear()
	if m and is_instance_valid(m):
		m.set_process(false)
		if m.get_parent():
			m.get_parent().remove_child(m)
		m.queue_free()
	if sv and is_instance_valid(sv):
		sv.get_parent().remove_child(sv)
		sv.queue_free()
	Display.update(Vector2(720, 1280))
	var d := DirAccess.open(dir)
	if d:
		for f in d.get_files():
			d.remove(f)
	DirAccess.remove_absolute(dir)


func _boot(dev: Vector2i = Vector2i.ZERO) -> void:
	m = load("res://scenes/main.tscn").instantiate()
	m.store = SaveStore.new(dir)
	if dev != Vector2i.ZERO:
		sv = SubViewport.new()
		sv.size = dev
		tree.root.add_child(sv)
		sv.add_child(m)
	else:
		tree.root.add_child(m)
	for i in 3:
		await tree.process_frame
	m.ftue.handoff_ms = 1.0
	m.commit_pick("bibi")   # LEADER_PICK (leader select): Bibi's round, the shipped game
	var e := InputEventScreenTouch.new()
	for pressed in [true, false]:
		e = InputEventScreenTouch.new()
		e.position = L.magician_hit().get_center() + Vector2(m._sx, m._stage_y)
		e.pressed = pressed
		m._unhandled_input(e)   # title → main (tap 1)


func _touch(p: Vector2) -> void:
	for pressed in [true, false]:
		var e := InputEventScreenTouch.new()
		e.position = p
		e.pressed = pressed
		m._unhandled_input(e)


func _flash() -> FlashCard:
	var t: Overlay = m.overlays.top()
	return t as FlashCard if t is FlashCard else null


func _wait(sec: float) -> void:
	await tree.create_timer(sec).timeout


func _dubi_line(n: int) -> String:
	for l: String in Story.beat_for(n):
		if FlashCard.dubi_quote(l).x >= 0:
			return l
	return ""


# ------------------------------------------------------------------ pure rules

func test_the_art_scale_is_integer_and_crisp_where_it_can_be() -> void:
	var all := func(_s: int) -> bool: return true
	var cases := {4: 3, 6: 4, 8: 3, 12: 4, 7: 4, 2: 4}
	for k: int in cases:
		var s := FlashCard.pick_art_scale(k, 3, all)
		runner.check(s == int(cases[k]), "k %d: ×%d, got ×%d" % [k, cases[k], s])
	# crisp = one sprite px is a whole number of device px: s/3 · k/4
	for k: int in [4, 6, 8, 12]:
		var s := FlashCard.pick_art_scale(k, 3, all)
		runner.check((s * k) % 12 == 0, "k %d: a sprite px is %s device px" % [k, str(s * k / 12.0)])
	var small := func(s: int) -> bool: return s <= 2
	runner.check(FlashCard.pick_art_scale(6, 3, small) == 2, "k 6 in a short band: ×2 (1 device px per sprite px)")
	runner.check(FlashCard.pick_art_scale(4, 3, small) == 2, "k 4 in a short band: the largest that fits, ×2")
	var none := func(_s: int) -> bool: return false
	runner.check(FlashCard.pick_art_scale(4, 3, none) == 2, "nothing fits: the smallest scale, never a fraction")
	runner.check(FlashCard.pick_art_scale(4, 1, all) == 4, "a d 1 figure at k 4: ×4 is already crisp")
	# the mic Dubi ships d 3 + a d 2 alternate: any of them dividing s·k/4 makes ×s crisp
	for k: int in {2: 4, 4: 4, 6: 4, 8: 4, 7: 4}:
		runner.check(FlashCard.pick_art_scale(k, [3, 2], all) == 4, "d 3 + d 2 at k %d: ×4" % k)
	runner.check(FlashCard.pick_art_scale(4, [3, 2], func(sc: int) -> bool: return sc <= 3) == 3, "k 4, ×4 too tall: ×3 (the d 3 at 1 dp)")


func test_dubi_talking_points_are_found_in_the_beats() -> void:
	var l := _dubi_line(1)
	runner.check(l != "", "beat 1 carries a Dubi line (copy deck §B1)")
	var q := FlashCard.dubi_quote(l)
	runner.check(l.substr(q.x, q.y - q.x) == "אין כובע! אין כובע!", "the quote is his talking point (%s)" % l.substr(q.x, q.y - q.x))
	runner.check(FlashCard.dubi_quote(Story.beat_for(1)[0]).x < 0, "a line that is not Dubi's has no talking point")
	runner.check(FlashCard.dubi_quote(Story.beat_for(3)[0]).x < 0 and _dubi_line(3) == "", "beat 3 has no Dubi line")


func test_the_word_salad_is_rolled_by_the_sim_before_each_point() -> void:
	var s := GameState.fresh()
	var zero := func() -> float: return 0.0
	var high := func() -> float: return 0.99
	var l := _dubi_line(1)
	# the content's condition does not hold: never a salad, never counted
	runner.check(FlashCard.broadcast_line(s, l, zero) == l, "no bot farm, no salad")
	runner.check(float(s.stats.get("wordSaladSeen", 0.0)) == 0.0, "and nothing counted")
	s.owned["poison"] = 50
	runner.check(FlashCard.broadcast_line(s, l, high) == l, "the dice say no: the line as written")
	runner.check(float(s.stats.get("wordSaladSeen", 0.0)) == 0.0, "a miss is not counted")
	var pool := FlashCard.last_three()
	var out := FlashCard.broadcast_line(s, l, zero)
	runner.check(out != l and out.begins_with("דובי: \"") and out.ends_with("\""), "a hit scrambles only the quote (%s)" % out)
	runner.check(float(s.stats.get("wordSaladSeen", 0.0)) == 1.0, "Story.roll_word_salad counted wordSaladSeen")
	var words := {}
	for p: String in pool:
		for w: String in p.split(" ", false):
			words[w.replace("!", "")] = true
	var q := FlashCard.dubi_quote(out)
	for w: String in out.substr(q.x, q.y - q.x).split(" ", false):
		runner.check(words.has(w.replace("!", "")), "every salad word is one of his last three points (%s)" % w)
	runner.check(FlashCard.recent_points.back() == "אין כובע! אין כובע!", "the real point enters his memory, not the salad")


# ------------------------------------------------------------------ the real scene

func test_the_flash_shows_after_an_election_and_closes() -> void:
	await _boot()
	m.state.evolutions = 1
	m._show_story_beat()
	await _wait(0.45)
	var f := _flash()
	runner.check(f != null, "the flash is a FlashCard on top of the stack")
	if f == null:
		return
	runner.check(f.strip != null and f.strip.char_id == "dubi-mic", "the mic Dubi is on the card")
	var dens := f.strip.density   # the variant set_art_px picked for ×art_scale (d 3 or its d 2)
	runner.check([2, 3].has(dens) and is_equal_approx(f.strip.scale_px, float(f.art_scale) / dens),
		"×%d art: %s logical px per sprite px of a d %d strip" % [f.art_scale, str(f.strip.scale_px), dens])
	runner.check([2, 3, 4].has(f.art_scale), "an integer art scale (%d)" % f.art_scale)
	var fig := f.strip.rect()
	fig.position += f.strip.position
	runner.check(fig.position.y >= 0.0 and fig.end.y <= f.screen_rect.size.y and fig.position.x >= 0.0 and fig.end.x <= f.screen_rect.size.x,
		"the figure fits the news screen (%s in %s)" % [fig, f.screen_rect.size])
	runner.check(f.panel_rect.size.x == 624.0 and f.panel_rect.position.y >= 0.0 and f.panel_rect.end.y <= float(L.H),
		"the card is 624 wide and inside the modal space (%s)" % f.panel_rect)
	runner.check(f.lines.size() == Story.beat_for(1).size(), "one text per beat line")
	for p: PxText in f.lines:
		runner.check(not p.truncated(), "a beat line wraps, never ellipsizes (%s)" % p.text)
	runner.check(f.sent.size() >= 2 and f.sent[0] == ["storyCard", null], "the dubiFlash head plays (%s)" % str(f.sent))
	runner.check(f.sent[1][0] == "babble" and String(f.sent[1][1]) == " ".join(f.line_texts), "Dubi reads what the card shows")
	runner.check(m.state.story_seen.has(Story.beat_id(1)), "the beat is marked seen")
	# "לסבב הבחירות הבא" closes it
	_touch(f.next_button.visual.get_center() + Vector2(m._ox, m._ovl_y))
	runner.check(f.closing and f.sent.back() == ["panelClose", null], "FLASH_NEXT closes the card")
	await _wait(0.4)
	runner.check(not m.overlays.is_open(), "and the stack is empty")
	m._show_story_beat()
	await tree.process_frame
	runner.check(not m.overlays.is_open(), "a beat already seen does not show again")


func test_back_skips_and_the_archive_has_one_close_button() -> void:
	await _boot()
	m.show_flash(2)
	await _wait(0.45)
	var f := _flash()
	runner.check(f != null and f.skip_button != null, "a live flash has FLASH_SKIP under FLASH_NEXT")
	if f == null:
		return
	runner.check(f.skip_button.visual.position.y > f.next_button.visual.position.y and f.skip_button.visual.size.x == f.next_button.visual.size.x,
		"stacked full width (§7.1)")
	m.overlays.back()
	runner.check(f.closing, "host back = FLASH_SKIP")
	await _wait(0.4)
	m.show_flash(7, true)
	await _wait(0.45)
	var a := _flash()
	runner.check(a != null and a.archive and a.skip_button == null and a.next_button.label.text == Strings.s("SYS_CLOSE"),
		"an archive replay (T4) closes with SYS_CLOSE only")
	if a:
		runner.check(a.line_texts == Story.beat_for(7), "the encore round shows the encore")


func test_the_beak_follows_the_blips() -> void:
	await _boot()
	m.show_flash(1)
	await _wait(0.45)
	var f := _flash()
	if f == null or f.strip == null:
		runner.check(false, "no flash")
		return
	f.on_blip()
	runner.check(f.strip.anim == "talk" and f.strip.frame == 1, "a blip opens the beak (talk.f1)")
	f.update_view(70.0)
	runner.check(f.strip.anim == "talk" and f.strip.frame == 0, "60 ms later it shuts (talk.f0)")
	f.on_blip()
	f.update_view(30.0)
	runner.check(f.strip.frame == 1, "the next blip opens it again")
	f.update_view(300.0)
	runner.check(f.strip.anim == "idle" and not f.strip.paused, "250 ms after the last blip he idles")
	var a := tree.root.get_node_or_null("Audio")
	if a != null and a.has_signal("dubi_blip"):
		a.emit_signal("dubi_blip", "D")
		runner.check(f.strip.anim == "talk", "the Audio's dubi_blip drives it")


func test_the_live_flash_rolls_the_salad_for_his_line() -> void:
	FlashCard.rng = func() -> float: return 0.0
	await _boot()
	for i in 3:
		await tree.process_frame   # tap 1's squawk (a talking point too) is said and counted first
	m.state.owned["poison"] = 50
	var before := float(m.state.stats.get("wordSaladSeen", 0.0))
	m.show_flash(1)
	await _wait(0.2)
	var f := _flash()
	if f == null:
		runner.check(false, "no flash")
		return
	var l := _dubi_line(1)
	var i := Story.beat_for(1).find(l)
	runner.check(float(m.state.stats.get("wordSaladSeen", 0.0)) - before == 1.0, "one talking point on the card, one roll that hit")
	runner.check(f.line_texts[i] != l and f.line_texts[i].begins_with("דובי:"), "his line comes out as salad (%s)" % f.line_texts[i])
	runner.check(f.lines[i].text == f.line_texts[i], "and that is what the card shows")


func test_at_k6_dubi_is_x4_and_crisp() -> void:
	await _boot(Vector2i(1170, 2532))   # 390×844 CSS @3
	m.show_flash(1)
	await _wait(0.45)
	var f := _flash()
	runner.check(Display.k == 6 and f != null and f.art_scale == 4, "k 6: ×4 (2 device px per sprite px), got k %d ×%d" % [Display.k, f.art_scale if f else 0])
	if f:
		runner.check(f.strip.material == null and f.strip.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "nearest, no AA shader")
		var o: Vector2 = (f.strip.position + f.strip.rect().position + f.screen_rect.position) * Display.f
		runner.check(o.is_equal_approx(o.round()), "the figure's top-left is on a whole device px (%s)" % o)
