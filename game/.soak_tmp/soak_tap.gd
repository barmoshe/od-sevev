extends SceneTree
## Scratch: boot the game, tap the leader N times, log each tap's note.
var m: Node
func _initialize() -> void:
	(load("res://scripts/ui/wizard.gd") as GDScript).set("enabled", false)
	var dir := "user://soak_%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(dir)
	m = load("res://scenes/main.tscn").instantiate()
	m.store = SaveStore.new(dir)
	root.add_child(m)
	call_deferred("_run")

func _run() -> void:
	for i in 3:
		await process_frame
	m.ftue.handoff_ms = 1.0
	var a: Node = root.get_node("/root/Audio")
	var p: Vector2 = L.magician_hit().get_center() + Vector2(m._sx, m._stage_y)
	print("mode ", m.mode)
	for pressed in [true, false]:
		var e := InputEventScreenTouch.new()
		e.position = p
		e.pressed = pressed
		m._unhandled_input(e)
	print("after first tap mode ", m.mode, " leader ", Leaders.current(m.state) if Leaders.active() else "-")
	var gap := float(OS.get_environment("SOAK_GAP_MS")) if OS.get_environment("SOAK_GAP_MS") != "" else 160.0
	var n := int(OS.get_environment("SOAK_N")) if OS.get_environment("SOAK_N") != "" else 400
	var prev_i := -99
	var line := ""
	for k in n:
		var before: int = a.recent_files().size()
		var log_before: Array = a.recent_files().duplicate()
		if m._leader_tap_gate() == "":
			m._pay_tap(L.magician_hit().get_center(), true)
		else:
			m._handle_tap(L.magician_hit().get_center())
		var after: Array = a.recent_files()
		var tapf := ""
		var rate := 0.0
		for v: Dictionary in a._voices:
			if v["cue"] == "tap" and float(v["start"]) == a._now():
				tapf = "yes"
				rate = (v["p"] as AudioStreamPlayer).pitch_scale
		var i: int = a._tap_i
		var note := int(a._tap_line["midi"][i]) if i >= 0 and i < (a._tap_line["midi"] as Array).size() else -1
		var flag := ""
		if prev_i >= 0 and i != (prev_i + 1) % 105:
			flag = " <<< JUMP"
		if tapf == "":
			flag += " <<< NO BELL"
		var news: Array = after.slice(maxi(0, after.size() - 3))
		print("%3d t=%7.0f i=%3d note=%3d track=%-10s line=%-10s rate=%.3f gate=%s L2=%.2f%s  %s" % [k, a._now(), i, note, a._track, a._tap_line_of, rate, m._leader_tap_gate(), a.layer_gain("L2"), flag, str(news)])
		prev_i = i
		# advance the game and the audio by `gap`
		var steps := int(gap / 16.0)
		for s in steps:
			m._process(0.016)
			a._process(0.016)
	quit(0)
