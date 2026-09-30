extends Node
## Dev only: plays a scripted round for a Movie Maker capture (store/gameplay/src/capture.sh).
## Loaded as an autoload through a temporary game/override.cfg, never in the export. It reads a plan
## (JSON: [[seconds, action, args], ...]) from the path after `--plan=` in the user args, runs each
## action on its movie frame (Movie Maker's fixed fps makes the timing exact) and acts through the
## real UI with real touches, at the positions DevProbe reports (viewport logical px x Display.f).
##
## Actions: pick {leader}, hat {n, rate} (taps on the leader), grant {amount}, buy {id?} (the most
## expensive affordable card, or that id), event {id} (fires a politics event now, as ?dev=1's
## window.odDevEvent), tab {i}, pay (the first affordable chat pill), decline (Liberman's "לא יושב"
## pill, the first in view), demand (the next member demand now), esc, elect (forces the
## ceremony, as window.odDevElect), tapxy {x, y} (logical), log, speed {x} (the dev game speed).

var _plan: Array = []
var _i := 0
var _t := 0.0
var _taps: Array = []   # pending hat taps: [time]
var _tid := 10
var _release: Array = []   # [frame, index, pos]
var _frame := 0


func _ready() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--plan="):
			var f := FileAccess.open(a.trim_prefix("--plan="), FileAccess.READ)
			if f != null:
				_plan = JSON.parse_string(f.get_as_text())
	print("[capture] plan: %d steps" % _plan.size())


func _host() -> Node:
	return get_tree().current_scene


func _process(dt: float) -> void:
	_frame += 1
	_t += dt
	for r: Array in _release.duplicate():
		if _frame >= int(r[0]):
			_touch(r[2], false, int(r[1]))
			_release.erase(r)
	while not _taps.is_empty() and _t >= float(_taps[0]):
		_taps.pop_front()
		_tap_logical(_hat())
	while _i < _plan.size() and _t >= float(_plan[_i][0]):
		var step: Array = _plan[_i]
		_i += 1
		_run(String(step[1]), step[2] if step.size() > 2 and step[2] is Dictionary else {})


func _snap() -> Dictionary:
	return DevProbe.snapshot(_host())


func _f() -> float:
	return float(Display.f)


func _hat() -> Vector2:
	var h: Node = _host()
	var hit: Rect2 = L.magician_hit()
	return hit.get_center() + Vector2(float(h.get("_sx")), float(h.get("_stage_y")))


func _touch(pos: Vector2, pressed: bool, index: int) -> void:
	var e := InputEventScreenTouch.new()
	e.index = index
	e.pressed = pressed
	e.position = pos
	Input.parse_input_event(e)


func _tap_logical(p: Vector2) -> void:
	var w := p * _f()
	_tid += 1
	_touch(w, true, _tid % 8)
	_release.append([_frame + 2, _tid % 8, w])


func _run(what: String, a: Dictionary) -> void:
	var h: Node = _host()
	var s := _snap()
	match what:
		"pick":
			var pk: Dictionary = s.get("pick", {})
			for c: Array in pk.get("cells", []):
				if String(c[2]) == String(a.get("leader", "")):
					_tap_logical(Vector2(float(c[0]), float(c[1])))
		"hat":
			var n := int(a.get("n", 1))
			var rate := float(a.get("rate", 6.0))
			for k in n:
				_taps.append(_t + k / rate)
			_taps.sort()
		"grant":
			var st: GameState = h.get("state")
			st.bananas += float(a.get("amount", 0))
			st.all_time_bananas += float(a.get("amount", 0))
		"buy":
			var rows: Array = s.get("shop", {}).get("rows", [])
			var want := String(a.get("id", ""))
			var pick_row: Array = []
			for r: Array in rows:
				if bool(r[3]) and (want == "" or String(r[2]) == want):
					pick_row = r
			if not pick_row.is_empty():
				_tap_logical(Vector2(float(pick_row[0]), float(pick_row[1])))
			print("[capture] buy %s: %s of %s" % [want, str(pick_row), str(rows)])
		"event":
			h.call("_on_politics_event", Events.fire(h.get("state"), String(a.get("id", "")), h.get("d")))
		"tab":
			var vs: Vector2 = h.get("_vs")
			var cw := float(L.cw)
			var w := floorf(cw / 16.0) * 4.0
			var i := int(a.get("i", 3))
			var x := (cw - 3.0 * w) / 2.0 if i >= 4 else cw - i * w + w / 2.0
			_tap_logical(Vector2(x + float(h.get("_ox")), vs.y - 104.0 + 52.0))
		"pay":
			for p: Array in s.get("chat", {}).get("pills", []):
				if bool(p[3]):
					_tap_logical(Vector2(float(p[0]), float(p[1])))
					print("[capture] pay : [%.1f, %.1f]" % [float(p[0]), float(p[1])])
					break
		"decline":
			# Liberman's "לא יושב" pill under a member demand (view_chat.gd declinable): DevProbe
			# lists only pay pills, so read the chat's hits the way the probe does
			var chat: Node = h.get("chat")
			var o := Vector2(float(h.get("_ox")), float(h.get("_lower_y")))
			var top := float(chat.position.y) + float(ChatView.THREAD_Y) + o.y
			var bottom := top + float(chat.call("thread_h")) - float(chat.call("bottom_pad"))
			for hh: Dictionary in chat.call("hits"):
				if String(hh["kind"]) != "decline":
					continue
				var c: Vector2 = chat.call("content_to_tall", (hh["rect"] as Rect2).get_center()) + chat.position + o
				if c.y > top and c.y < bottom:
					_tap_logical(c)
					print("[capture] decline : [%.1f, %.1f]" % [c.x, c.y])
					break
		"demand":
			# the next member demand now (Coalition._tick_demands posts it on the next tick when a member
			# is free), so a capture can show a demand, and Liberman's "לא יושב", on cue
			var st2: GameState = h.get("state")
			if st2.coalition is Dictionary:
				st2.coalition["nextDemandSec"] = 0.001
		"esc":
			for down: bool in [true, false]:
				var k := InputEventKey.new()
				k.keycode = KEY_ESCAPE
				k.physical_keycode = KEY_ESCAPE
				k.pressed = down
				Input.parse_input_event(k)
		"elect":
			# the dev-forced ceremony needs the dev flag (main.gd _start_evolve); on only for the call
			var dv: Dictionary = h.get("_dev")
			var was := bool(dv["on"])
			dv["on"] = true
			h.call("_start_evolve", true)
			dv["on"] = was
		"tapxy":
			_tap_logical(Vector2(float(a.get("x", 0)), float(a.get("y", 0))))
		"speed":
			var dv: Dictionary = h.get("_dev")
			dv["speed"] = float(a.get("x", 1.0))
		"log":
			var keep := {}
			for k: String in ["mode", "leader", "bank", "seats", "modal", "runSec", "ready", "cta"]:
				keep[k] = s.get(k)
			keep["shop"] = s.get("shop", {}).get("rows", [])
			keep["pills"] = s.get("chat", {}).get("pills", [])
			keep["chatOpen"] = s.get("chat", {}).get("open", false)
			print("[capture] t=%.1f %s" % [_t, JSON.stringify(keep)])
