extends RefCounted
## Mordechai David's stage event (design/mordechai-david-spec.md §3, §7.2, §9; StreetFigure): the copy
## skins per leader, the figure's walk-in to his mark in front of the right crowd, the hold, the walk-out
## timed to the effect's end, the toasts, and reduced motion. The integration cases boot the real scene
## on the game content (Balfour is the first stage).

var runner: Object
var tree: SceneTree
var dir := ""
var m: Node


func setup(r: Object) -> void:
	TestFixture.use_game_content()
	tree = r as SceneTree
	dir = "user://test_street_figure_%d" % Time.get_ticks_usec()
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
	m.street.reduced_motion = reduced


## The pick (landed, no walk), then tap 1: the round's clock runs from here.
func _start_round(id := "bibi") -> bool:
	if not m.commit_pick(id):
		return false
	_frames(2)
	var at: Vector2 = L.magician_hit().get_center() + Vector2(m._sx, m._stage_y)
	for pressed in [true, false]:
		var e := InputEventScreenTouch.new()
		e.position = at
		e.pressed = pressed
		m._unhandled_input(e)
	return m.mode == "main"


func _frames(n: int, ms := 16.0) -> void:
	for i in n:
		m._process(ms / 1000.0)


## Seats the round's partners so one small partner (1-4 seats) can be stuck; returns its id.
func _seat_partners() -> String:
	m.state.coalition["opened"] = true   # members only exist once the group is open (C1)
	var small := ""
	for p: Dictionary in Coalition.partners():
		var seats := int(p.get("seats", 0))
		if p.get("standIn", false) or str(p.get("side", "coalition")) != "coalition" or seats <= 0:
			continue
		if seats <= 4 and small == "":
			small = str(p["id"])
			Coalition.ps(m.state, small)["status"] = "member"
		elif seats > 4:
			Coalition.ps(m.state, str(p["id"]))["status"] = "member"
	return small


func test_the_copy_skins_per_leader() -> void:
	var base := StreetFigure.copy_for("bibi", "")
	runner.check(str(base["name"]) == "מרדכי דוד" and str(base["role"]) == "פעיל ימין", "the default name and role")
	runner.check(str(base["text"]).begins_with("לדבריו"), "the default line is reported speech")
	runner.check(not base.has("skins"), "the skins are resolved away")
	var bg := StreetFigure.copy_for("bengvir", str(Leaders.leader("bengvir").get("side", "")))
	runner.check(str(bg["role"]) == "מטה הצעירים שלך" and str(bg["text"]).contains("מטה הצעירים"), "Ben Gvir's round: your own youth-HQ man")
	runner.check(str(StreetFigure.copy_for("ben-gvir", "")["role"]) == "מטה הצעירים שלך", "a dashed id finds the same skin")
	var opp := StreetFigure.copy_for("bennett", "opposition")
	runner.check(str(opp["text"]).contains("אופוזיציה") and str(opp["role"]) == "פעיל ימין", "an opposition leader: the opposition line, the default role")
	var filled := StreetFigure.fill(str(base["blockedText"]), "")
	runner.check(filled.contains("6") and not filled.contains("{"), "{sec} fills in from the effect (%s)" % filled)


func test_he_walks_in_blocks_and_leaves_by_the_end() -> void:
	await _boot()
	runner.check(_start_round(), "the pick and tap 1 start the round")
	_frames(60)
	runner.check(m.diorama.era_id() == "balfour", "the first stage is Balfour")
	var stuck := _seat_partners()
	runner.check(stuck != "", "a 1-4 seat partner is in the coalition")
	var fig: StreetFigure = m.street
	var mark := StreetFigure.mark()
	m._on_politics_event(Events.fire(m.state, "mordechai", m.d, func() -> float: return 0.0))
	runner.check(str(m._street_partner) == "" and Coalition.counts(m.state, stuck), "no partner is benched any more: he blocks the screen")
	_frames(1)
	runner.check(fig.mode() == "in" and fig.visible and fig.position.x < m.street.off_x() + 40.0, "f1: walking in from off the canvas's LEFT edge (x %.0f)" % fig.position.x)
	runner.check(fig.scale.x > 0.0, "the walk-in heads right, as drawn")
	runner.check(not m._gameplay_input() and m._input_blocked(), "while he is there, nothing takes a tap")
	var presses_before: int = m._presses.size()
	m._pointer_down(0, L.magician_hit().get_center() + Vector2(m._sx, m._stage_y))
	runner.check(m._presses.size() == presses_before, "a tap on the leader is swallowed")
	var never_left := true
	var modes := {}
	var head_seen := false
	var grid := true
	var gone_at := -1
	for i in 500:   # 8 s at 16 ms (the block is 6 s)
		_frames(1)
		if gone_at < 0 and fig.mode() == "gone":
			gone_at = i
		if gone_at >= 0 and fig.mode() != "gone":
			runner.check(false, "once gone he stays gone (back as %s at frame %d)" % [fig.mode(), i])
			gone_at = 1 << 30
		modes[fig.mode()] = true
		if fig.visible:
			never_left = never_left and fig.position.x <= mark.x + 0.5
			grid = grid and is_equal_approx(fmod(absf(fig.position.x), 4.0), 0.0)
		if fig.mode() == "hold" and not modes.has("_hold_checked"):
			modes["_hold_checked"] = true
			runner.check(fig.position == Vector2(roundf(mark.x / 4.0) * 4.0, mark.y) and fig.scale.x > 0.0, "the hold is on his mark, facing the crowd as drawn")
		var sh: Dictionary = m.toasts.shown()
		if str(sh.get("preview", "")).begins_with("לדבריו") and bool(sh.get("face", false)) and str(sh.get("dock", "")) == "lane":
			head_seen = true
	runner.check(never_left, "he never passes his mark toward the leader's slot")
	runner.check(grid, "whole art px only")
	for k in ["in", "plant", "hold", "release", "out", "gone"]:
		runner.check(modes.has(k), "the beat %s ran" % k)
	runner.check(head_seen, "his toast: his face and his reported line, docked in the lane band under the leader's feet")
	runner.check(fig.mode() == "gone" and not fig.visible, "off the stage as the effect ends (mode %s, gone at frame %d)" % [fig.mode(), gone_at])
	runner.check(m._gameplay_input() and not m._input_blocked(), "and the screen takes taps again")


func test_reduced_motion_fades_on_the_mark() -> void:
	await _boot(true)
	_start_round()
	_frames(30)
	_seat_partners()
	var fig: StreetFigure = m.street
	m._on_politics_event(Events.fire(m.state, "mordechai", m.d, func() -> float: return 0.0))
	_frames(1)
	runner.check(fig.mode() == "hold" and fig.position.x == roundf(StreetFigure.mark().x / 4.0) * 4.0, "no walk: straight onto the mark")
	runner.check(fig.modulate.a < 1.0, "fading in")
	_frames(20)
	runner.check(is_equal_approx(fig.modulate.a, 1.0) and fig.strip.paused, "fully in, frozen")
	_frames(1300)
	runner.check(fig.mode() == "gone", "gone at the end")


func test_an_election_or_reset_clears_him() -> void:
	await _boot()
	_start_round()
	_frames(30)
	_seat_partners()
	m._on_politics_event(Events.fire(m.state, "mordechai", m.d, func() -> float: return 0.0))
	_frames(200)
	runner.check(m.street.showing(), "on stage")
	Events.on_election(m.state)
	_frames(400)
	runner.check(not m.street.showing(), "the effect cleared: he leaves")
