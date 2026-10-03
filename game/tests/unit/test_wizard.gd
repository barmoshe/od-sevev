extends RefCounted
## The wizard overlay (ui/wizard.gd, content `wizard`, WizardHooks; ADR 0007): the table speaks the
## hooks' vocabulary, steps follow state (resume, tapHole, gone, sec), the hole passes a press and
## the dim swallows the rest, "דלג" ends a flow, and on the real scene the first launch opens with
## the picker step over the two open tiles while the old FTUE prompts stand down.

var runner: Object
var tree: SceneTree
var dir := ""
var m: Node
var w: Wizard


func setup(r: Object) -> void:
	TestFixture.use_game_content()
	Reveal.force_all = false
	Wizard.enabled = true
	tree = r as SceneTree
	dir = "user://test_wizard_%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(dir)


func teardown() -> void:
	Reveal.force_all = true
	Wizard.enabled = false
	if w and is_instance_valid(w):
		w.free()
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


func test_the_table_speaks_the_hooks_vocabulary() -> void:
	var fs := Wizard.flows()
	runner.check(fs.has("first"), "the first-round flow")
	for k: String in Reveal.table():
		if k == "copy" or k.begins_with("_") or k == "picker":
			continue
		runner.check(fs.has(k), "every reveal-ladder mechanic has its wizard: %s" % k)
	for f: String in fs:
		var F: Dictionary = fs[f]
		var on := Wizard.on_of(f)
		runner.check(on == "" or Reveal.table().has(on), "%s: on %s is a reveal key" % [f, on])
		for st: Dictionary in F.get("steps", []):
			runner.check(WizardHooks.ANCHORS.has(str(st.get("anchor", ""))), "%s/%s: anchor %s" % [f, st.get("id"), st.get("anchor")])
			for key in ["when", "done"]:
				for part: String in str(st.get(key, "")).split("|", false):
					runner.check(WizardHooks.CONDS.has(part.trim_prefix("!")), "%s/%s: %s %s" % [f, st.get("id"), key, part])
			runner.check(st.get("done", "") != "" or st.get("gone", false) or float(st.get("sec", 0)) > 0.0, "%s/%s can end" % [f, st.get("id")])
			runner.check(Wizard.text_of(st) != "", "%s/%s has a bubble" % [f, st.get("id")])
			runner.check(Wizard.text_of(st).length() <= 90, "%s/%s: one short line (%d)" % [f, st.get("id"), Wizard.text_of(st).length()])


## A bare wizard on a test flow: conds and anchors from dictionaries.
func _bare(flow: Dictionary, conds: Dictionary) -> GameState:
	var c := Content.data().duplicate()
	c["wizard"] = {"t": flow}
	Content.replace(c)
	w = Wizard.new()
	tree.root.add_child(w)
	w.cond = func(n: String) -> bool: return bool(conds.get(n, false))
	w.anchor = func(n: String) -> Rect2: return Rect2(100, 100, 80, 60) if n == "a" else Rect2()
	return GameState.fresh()


func test_steps_follow_state_resume_and_end() -> void:
	var conds := {"w1": true, "d1": false, "w2": true, "d2": false}
	var s := _bare({"on": "", "steps": [{"id": "one", "anchor": "a", "when": "w1", "done": "d1", "text": "x"},
		{"id": "two", "anchor": "a", "when": "w2", "done": "tapHole", "text": "y"}]}, conds)
	w.update_view(16.0, s)
	runner.check(w.showing() and w.step_i == 0, "the first step shows")
	runner.check(w.swallows(Vector2(10, 10), s), "a press outside the hole is swallowed")
	runner.check(not w.swallows(Vector2(140, 130), s), "a press in the hole passes through")
	conds["d1"] = true
	w.update_view(16.0, s)
	runner.check(Wizard.step_done(s, "t", 0) and w.step_i == 1, "its done → the next step")
	w.swallows(Vector2(140, 130), s)   # tapHole
	w.update_view(16.0, s)
	runner.check(Wizard.finished(s, "t") and not w.showing(), "the last step done ends the flow")
	# a step already done in state never shows (a reload resumes at the first undone step)
	var s2 := GameState.fresh()
	conds["d1"] = true
	w.update_view(16.0, s2)
	runner.check(w.step_i == 1, "resume at the first undone step (%d)" % w.step_i)


func test_a_step_waits_for_its_when_and_its_target() -> void:
	var conds := {"w1": false}
	var s := _bare({"on": "", "steps": [{"id": "one", "anchor": "a", "when": "w1", "done": "d1", "text": "x"}]}, conds)
	w.update_view(16.0, s)
	runner.check(not w.showing() and not w.swallows(Vector2(10, 10), s), "nothing shows between steps: the game plays undimmed")
	conds["w1"] = true
	w.update_view(16.0, s)
	runner.check(w.showing(), "its moment comes: it shows")


func test_gone_sec_soft_hold_and_skip() -> void:
	var conds := {"w": true}
	var s := _bare({"on": "", "steps": [{"id": "g", "anchor": "a", "when": "w", "done": "", "gone": true, "soft": true, "hold": true, "text": "x"},
		{"id": "s", "anchor": "a", "when": "w", "done": "", "sec": 2, "text": "y"}]}, conds)
	w.update_view(16.0, s)
	runner.check(w.soft() and not w.swallows(Vector2(10, 10), s), "a soft step swallows nothing")
	runner.check(w.holds(), "a hold step holds the clock")
	conds["w"] = false
	w.update_view(16.0, s)
	runner.check(Wizard.step_done(s, "t", 0), "gone: the moment passing counts as done")
	conds["w"] = true
	w.update_view(16.0, s)
	w.update_view(2100.0, s)
	w.update_view(16.0, s)
	runner.check(Wizard.finished(s, "t"), "sec: done after that long shown")
	var s2 := GameState.fresh()
	w.update_view(16.0, s2)
	runner.check(w.showing(), "a fresh save shows it again")
	runner.check(w.swallows(w.skip_rect.get_center(), s2), "the skip takes its press")
	runner.check(Wizard.finished(s2, "t") and not w.showing(), "דלג ends the flow")


func test_a_mechanic_flow_waits_for_its_round() -> void:
	var conds := {"w": true}
	var s := _bare({"on": "suspicion", "steps": [{"id": "x", "anchor": "a", "when": "w", "done": "tapHole", "text": "x"}]}, conds)
	w.update_view(16.0, s)
	runner.check(not w.showing(), "no wizard before its reveal round")
	s.evolutions = Reveal.round_of("suspicion")
	w.update_view(16.0, s)
	runner.check(w.showing(), "it shows in the round its mechanic opens")


func test_the_first_launch_opens_on_the_picker_step() -> void:
	m = load("res://scenes/main.tscn").instantiate()
	m.store = SaveStore.new(dir)
	tree.root.add_child(m)
	for i in 3:
		await tree.process_frame
	m.ftue.handoff_ms = 1.0
	for i in 3:
		await tree.process_frame
	runner.check(m.mode == "pick", "the picker first")
	runner.check(m.wizard.showing() and m.wizard.flow == "first" and str(m.wizard._step.get("id")) == "slip", "the wizard's slip step (%s)" % str(m.wizard.web_info(Vector2.ZERO)))
	runner.check(Wizard.first_running(m.state), "the first wizard runs (the old FTUE prompts stand down)")
	var hole: Rect2 = m.wizard.hole
	for c: Dictionary in m.picker.cells:
		var cr := Rect2((c["rect"] as Rect2).position + m.picker.position, (c["rect"] as Rect2).size)
		var open := str(c["id"]) in ["bibi", "bennett"]
		runner.check(hole.encloses(cr) == open, "the hole holds exactly the open tiles (%s)" % str(c["id"]))
	# a press on a locked tile never reaches the picker; one in the hole does
	var shut: Vector2 = Vector2.ZERO
	for c: Dictionary in m.picker.cells:
		if c.get("locked", false):
			shut = (c["rect"] as Rect2).get_center() + m.picker.position + m._root.position
	m._pointer_down(0, shut)
	runner.check(not m._presses.has(0), "outside the hole: swallowed")
	var in_hole: Vector2 = Vector2.ZERO
	for c: Dictionary in m.picker.cells:
		if str(c["id"]) == "bibi":
			in_hole = (c["rect"] as Rect2).get_center() + m.picker.position + m._root.position
	m.picker._age = 1000.0   # past the tap-burst guard
	m._pointer_down(1, in_hole)
	runner.check(m._presses.has(1), "inside the hole: the picker takes it")
	m._pointer_up(1, in_hole)
	for i in 2:
		await tree.process_frame
	runner.check(str(m.wizard._step.get("id")) == "vote" and m.wizard.hole.encloses(Rect2(m.picker.go_btn.hit.position + m.picker.position, m.picker.go_btn.hit.size)),
		"a slip chosen: the vote step, on the button (%s)" % str(m.wizard.web_info(Vector2.ZERO)))
	var go: Vector2 = m.picker.go_btn.visual.get_center() + m.picker.position + m._root.position
	m._pointer_down(2, go)
	m._pointer_up(2, go)
	m.picker.finish_now()
	for i in 4:
		await tree.process_frame
	runner.check(not Leaders.pick_pending(m.state), "the pick is made")
	runner.check(m.wizard.showing() and str(m.wizard._step.get("id")) == "tap", "then the tap step (%s)" % str(m.wizard.web_info(Vector2.ZERO)))
	runner.check(m.wizard.hole.encloses(Rect2(m.bb.hit_rect().position + Vector2(m._sx, m._stage_y), m.bb.hit_rect().size)), "on the leader")


## Every condition and anchor the content may name runs on the live scene without an error, in the
## picker and in a round-5 round (where every mechanic is open).
func test_every_hook_runs_on_the_live_scene() -> void:
	m = load("res://scenes/main.tscn").instantiate()
	m.store = SaveStore.new(dir)
	tree.root.add_child(m)
	for i in 3:
		await tree.process_frame
	m.ftue.handoff_ms = 1.0
	await tree.process_frame
	for n: String in WizardHooks.CONDS:
		if n != "tapHole":
			WizardHooks.cond(m, n)
	for n: String in WizardHooks.ANCHORS:
		WizardHooks.anchor(m, n)
	runner.check(WizardHooks.anchor(m, "pickOpen").has_area(), "the picker's open tiles have a rect")
	m.picker._age = 1000.0
	m.picker.commit_cell(0, "tile")
	m.picker.finish_now()
	m._start_from_title(m.bb.hit_rect().get_center(), true)
	m.state.evolutions = 4
	for i in 4:
		await tree.process_frame
	for n: String in WizardHooks.CONDS:
		if n != "tapHole":
			WizardHooks.cond(m, n)
	for n: String in WizardHooks.ANCHORS:
		WizardHooks.anchor(m, n)
	runner.check(m.mode == "main", "a round is up (%s)" % m.mode)
	runner.check(WizardHooks.anchor(m, "leader").has_area() and WizardHooks.anchor(m, "seats").has_area(), "the leader and the seats bar have rects")
	m.chat.open()
	for i in 3:
		await tree.process_frame
	for n: String in ["payVisible", "perks"]:
		WizardHooks.cond(m, n)
	for n: String in ["payPill", "perks"]:
		WizardHooks.anchor(m, n)


func test_the_wizard_sounds_a_step_its_done_and_a_skip() -> void:
	var heard: Array = []
	var conds := {"w": true, "d": false}
	var s := _bare({"on": "", "steps": [{"id": "x", "anchor": "a", "when": "w", "done": "d", "text": "x"},
		{"id": "y", "anchor": "a", "when": "w", "done": "d2", "text": "y"}]}, conds)
	w.on_sound = func(ev: String) -> void: heard.append(ev)
	w.update_view(16.0, s)
	w.update_view(16.0, s)
	runner.check(heard == ["wizardStep"], "a step shows: one chime, not one per frame (%s)" % str(heard))
	conds["d"] = true
	w.update_view(16.0, s)
	runner.check(heard == ["wizardStep", "wizardDone", "wizardStep"], "done by the player: the 'yes', then the next step's chime (%s)" % str(heard))
	w.skip(s)
	runner.check(heard.back() == "wizardSkip", "דלג: the swoosh (%s)" % str(heard))
