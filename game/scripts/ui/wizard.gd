class_name Wizard
extends Node2D
## The wizard overlay (2026-10-03, Bar: "the first two minutes clear, with a wizard overlay tutorial,
## and every new mechanic that joins gets its own wizard"; ADR 0007). Guided, do-it: the screen dims,
## a hole sits on the one thing to touch, Dubi's bubble says what and why, and the step ends when the
## player does it. "דלג" skips the flow.
##
## Flows are content (`wizard`): {flowId: {on, until, steps: [{id, anchor, when, done, text, soft,
## gone, hold}]}}. Steps are triggered by state, not a forced chain: a step shows only while its
## `when` holds and its `done` doesn't, so between steps the game plays undimmed (an idle game earns
## between them), and a mechanic's flow waits for its reveal-ladder key (`on`) and for the moment the
## mechanic first shows up (just-in-time teaching). One step shows at a time, the table's order first.
##   when / done / until   condition names (`a|b` = either, `!a` = not), the controller's vocabulary
##                         (WizardHooks.cond); `tapHole` = the player tapped inside the hole
##   anchor                a target name (WizardHooks.anchor: a root-space Rect2, empty = off screen)
##   soft                  no swallowing, a lighter dim: a hint over a choice (the new leader) or a
##                         moment the player can't act on (Mordechai's block)
##   gone                  once shown, the moment passing (`when` false) counts as done (the Suitcase)
##   hold                  holds the round's clock while it shows (an ultimatum, main.clock_held)
##   sec                   once shown this long, done (a soft hint never lingers)
##   seen                  `done` counts only once the step has shown (a `done` already true before
##                         its moment: the new leader's "picked")
##   text                  the bubble; "@reveal.<key>" = the reveal ladder's announcement
## State: stats "wiz_<flow>" = the bitmask of the steps done, FINISHED once the flow ends or is skipped
## (stats persist any plain number; the save keeps only the fixed boolean UI flags).

const FINISHED := 1 << 20
const DIM := Color(0.02, 0.02, 0.06, 0.68)
const SOFT_DIM := Color(0.02, 0.02, 0.06, 0.3)
const C_FRAME := Color("#ffd23f")
const BUBBLE_INK := Color("#1b1b2a")
const PAD := 12.0
const BUBBLE_W := 560.0
const SKIP := Vector2(136, 64)

## Unit tests switch it off (run_tests.gd) so no wizard covers the screen they pin; test_wizard.gd on.
static var enabled := true

var host: Node
var cond: Callable                 # func(name: String) -> bool
var anchor: Callable               # func(name: String) -> Rect2 (root space)
var fill: Callable                 # func(text: String) -> String (placeholders: the leader's names)
var on_event: Callable             # func(flow: String, what: String): the funnel (step id | skip | done)
var reduced_motion := false
## The screen in root space (the dim covers it) and the canvas column with its safe band (the bubble
## and the skip stay inside it).
var screen := Rect2(0, 0, 720, 1280)
var column := Rect2(0, 0, 720, 1280)

var flow := ""                     # the flow showing ("" = nothing)
var step_i := -1
var hole := Rect2()
var _step: Dictionary = {}
var _shown := {}                   # "flow/i" → ms shown (this session)
var _tapped := ""                  # "flow/i" whose hole was tapped
var _t := 0.0
var _fade := 0.0
var _dim: Array[ColorRect] = []
var _frame: Array[ColorRect] = []
var _bubble: NinePatchRect
var _text: PxText
var _count: PxText
var _skip_plate: NinePatchRect
var _skip_text: PxText
var skip_rect := Rect2()
var hand: Sprite2D


func _ready() -> void:
	_ensure()
	visible = false


## The nodes, once (built on the first frame too: a bare wizard in a test may never get _ready).
func _ensure() -> void:
	if _bubble != null:
		return
	for i in 4:
		var r := ColorRect.new()
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(r)
		_dim.append(r)
	for i in 4:
		var r := ColorRect.new()
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		r.color = C_FRAME
		add_child(r)
		_frame.append(r)
	_bubble = Ui.nine(self, Rect2(0, 0, 64, 64), Art.sprite_or("chat_bubble_in"))
	_text = PxText.make(self, Vector2.ZERO, "", L.TEXT, "plain", BUBBLE_INK)
	_text.wrap_width = BUBBLE_W - 48.0
	_text.max_lines = 4
	_text.align = 1
	_count = PxText.make(self, Vector2.ZERO, "", L.TEXT, "plain", Color("#c9d6f2"))
	_count.max_lines = 1
	_skip_plate = Ui.nine(self, Rect2(Vector2.ZERO, SKIP), Art.sprite_or("chat_system_pill"))
	_skip_text = PxText.make(self, Vector2.ZERO, Strings.s("WIZ_SKIP"), L.TEXT, "plain", "w")
	_skip_text.max_lines = 1
	hand = Sprite2D.new()
	hand.texture = Art.tex("ui_pointer", 0)
	hand.scale = Vector2(4, 4)
	add_child(hand)


# ------------------------------------------------------------------ the table and the state

static func flows() -> Dictionary:
	var w: Variant = Content.data().get("wizard")
	var out := {}
	if w is Dictionary:
		for k: Variant in w:
			if not str(k).begins_with("_") and w[k] is Dictionary:
				out[str(k)] = w[k]
	return out


static func bits(s: GameState, f: String) -> int:
	return int(float(s.stats.get("wiz_" + f, 0.0)))


static func finished(s: GameState, f: String) -> bool:
	return bits(s, f) & FINISHED != 0


static func step_done(s: GameState, f: String, i: int) -> bool:
	return bits(s, f) & (1 << i) != 0


static func mark(s: GameState, f: String, i: int) -> void:
	s.stats["wiz_" + f] = float(bits(s, f) | (1 << i))


static func finish(s: GameState, f: String) -> void:
	s.stats["wiz_" + f] = float(bits(s, f) | FINISHED)


## The first-round flow is still teaching (the old FTUE's prompts stand down meanwhile).
static func first_running(s: GameState) -> bool:
	return enabled and s != null and s.evolutions == 0 and flows().has("first") and not finished(s, "first")


## A step's bubble: its own line, or "@reveal.<key>" = the reveal ladder's announcement of the key.
static func text_of(st: Dictionary) -> String:
	var t := str(st.get("text", ""))
	if t.begins_with("@reveal."):
		return Reveal.announcement(t.substr(8))
	return t


# ------------------------------------------------------------------ the frame

func _test(expr: String, key: String) -> bool:
	if expr == "":
		return false
	for part: String in expr.split("|"):
		var neg := part.begins_with("!")
		var name := part.substr(1) if neg else part
		var v := (_tapped == key) if name == "tapHole" else (cond.is_valid() and bool(cond.call(name)))
		if v != neg:
			return true
	return false


## Picks what shows this frame (and books every step done meanwhile): [flow, i, rect] or [].
func pick(s: GameState) -> Array:
	if not enabled or s == null:
		return []
	var fs := flows()
	for f: String in fs:
		if finished(s, f):
			continue
		var F: Dictionary = fs[f]
		var on := str(F.get("on", ""))
		if on != "" and not Reveal.on(s, on):
			continue
		if _test(str(F.get("until", "")), ""):
			finish(s, f)
			_report(f, "done")
			continue
		var steps: Array = F.get("steps", [])
		var left := 0
		var show: Array = []
		for i in steps.size():
			if step_done(s, f, i):
				continue
			var st: Dictionary = steps[i]
			var key := "%s/%d" % [f, i]
			var passed: bool = st.get("gone", false) == true and _shown.has(key) and not _test(str(st.get("when", "")), key)
			if float(st.get("sec", 0.0)) > 0.0 and float(_shown.get(key, 0.0)) >= float(st["sec"]) * 1000.0:
				passed = true
			var can_end: bool = st.get("seen", false) != true or _shown.has(key)
			if (can_end and _test(str(st.get("done", "")), key)) or passed:
				mark(s, f, i)
				_report(f, str(st.get("id", i)))
				if _tapped == key:
					_tapped = ""
				continue
			left += 1
			if show.is_empty() and _test(str(st.get("when", "")), key):
				var r: Rect2 = anchor.call(str(st.get("anchor", ""))) if anchor.is_valid() else Rect2()
				if r.has_area():
					show = [f, i, r]
		if left == 0:
			finish(s, f)
			_report(f, "done")
			continue
		if not show.is_empty():
			return show
	return []


func update_view(dt_ms: float, s: GameState) -> void:
	_ensure()
	_t += dt_ms
	var p := pick(s)
	if p.is_empty():
		if visible:
			visible = false
			flow = ""
			step_i = -1
			_step = {}
		return
	var f := str(p[0])
	var i := int(p[1])
	hole = (p[2] as Rect2).grow(PAD)
	if f != flow or i != step_i:
		flow = f
		step_i = i
		_step = (flows()[f]["steps"] as Array)[i]
		_shown["%s/%d" % [f, i]] = 0.0
		_tapped = ""
		_fade = 0.0
		var t := text_of(_step)
		_text.text = fill.call(t) if fill.is_valid() else t
		var steps: Array = flows()[f]["steps"]
		_count.text = "%d/%d" % [i + 1, steps.size()] if steps.size() > 1 else ""
	visible = true
	_shown["%s/%d" % [f, i]] = float(_shown.get("%s/%d" % [f, i], 0.0)) + dt_ms
	_fade = minf(1.0, _fade + dt_ms / 160.0)
	modulate.a = 1.0 if reduced_motion else _fade
	_layout()


func _layout() -> void:
	var soft := soft()
	var c := SOFT_DIM if soft else DIM
	var sc := screen
	var h := hole
	var parts := [Rect2(sc.position.x, sc.position.y, sc.size.x, maxf(0.0, h.position.y - sc.position.y)),
		Rect2(sc.position.x, h.end.y, sc.size.x, maxf(0.0, sc.end.y - h.end.y)),
		Rect2(sc.position.x, h.position.y, maxf(0.0, h.position.x - sc.position.x), h.size.y),
		Rect2(h.end.x, h.position.y, maxf(0.0, sc.end.x - h.end.x), h.size.y)]
	for k in 4:
		_dim[k].color = c
		_dim[k].position = parts[k].position
		_dim[k].size = parts[k].size
	# the frame: 4 px of gold around the hole, breathing (still under reduced motion)
	var a := 1.0 if reduced_motion else 0.55 + 0.45 * (0.5 + 0.5 * sin(_t / 1000.0 * TAU * 1.2))
	var fr := [Rect2(h.position.x - 4, h.position.y - 4, h.size.x + 8, 4), Rect2(h.position.x - 4, h.end.y, h.size.x + 8, 4),
		Rect2(h.position.x - 4, h.position.y, 4, h.size.y), Rect2(h.end.x, h.position.y, 4, h.size.y)]
	for k in 4:
		_frame[k].position = fr[k].position
		_frame[k].size = fr[k].size
		_frame[k].modulate.a = a
	# the bubble: above the hole if it fits under the skip row, else below it; inside the column
	var lines := maxf(1.0, float(_text.line_count()))
	var bh := Ui.snap(float(HeFont.line_height()) * _text.eff_px() * lines + 32.0, 4)
	var bw := minf(BUBBLE_W, column.size.x - 32.0)
	_text.wrap_width = bw - 48.0
	var bx := clampf(Ui.snap(h.get_center().x - bw / 2.0, 4), column.position.x + 16.0, column.end.x - 16.0 - bw)
	var top_min := column.position.y + SKIP.y + 24.0
	var by := h.position.y - 24.0 - bh
	if by < top_min:
		by = h.end.y + 24.0
	if by + bh > column.end.y - 8.0:
		by = maxf(top_min, h.position.y + 16.0)   # a hole as tall as the screen: over its top
	var br := Rect2(bx, Ui.snap(by, 4), bw, bh)
	Ui.set_nine_rect(_bubble, br)
	_text.position = Vector2(br.position.x + 24.0, br.position.y + 16.0)
	_text.center_in(br.position.x + 24.0, bw - 48.0)
	# "דלג": the column's top-left corner (RTL: away from the reading start), the step count beside it
	skip_rect = Rect2(column.position.x + 16.0, column.position.y + 12.0, SKIP.x, SKIP.y)
	_count.position = Vector2(skip_rect.end.x + 16.0, skip_rect.position.y + 10.0)
	_count.visible = _count.text != ""
	Ui.set_nine_rect(_skip_plate, skip_rect)
	_skip_text.position = Vector2(0, skip_rect.position.y + 10.0)
	_skip_text.center_in(skip_rect.position.x, skip_rect.size.x)
	# the hand: at the hole's lower right, pointing in (none on a soft step)
	hand.visible = not soft
	if hand.visible:
		Ui.set_frame(hand, "ui_pointer", 1)
		var off := Vector2.ZERO if reduced_motion else Ftue.hand_bob(_t, Vector2(-0.7071, -0.7071))
		var hp := h.get_center() + Vector2(minf(56.0, h.size.x / 2.0), minf(40.0, h.size.y / 2.0))
		hand.position = hp + off


# ------------------------------------------------------------------ input (root space)

func showing() -> bool:
	return visible and flow != ""


func soft() -> bool:
	return _step.get("soft", false) == true


## The round's clock holds while a `hold` step shows (main.clock_held).
func holds() -> bool:
	return showing() and _step.get("hold", false) == true


## A press at `p`: true = the controller drops it. "דלג" skips the flow; a press in the hole passes
## through (and counts as tapHole); anything else is swallowed unless the step is soft.
func swallows(p: Vector2, s: GameState) -> bool:
	if not showing():
		return false
	if Ui.in_rect(skip_rect, p):
		skip(s)
		return true
	if Ui.in_rect(hole, p):
		_tapped = "%s/%d" % [flow, step_i]
		return false
	return not soft()


## Esc skips (keys otherwise pass: the steps are things to touch).
func swallows_key(k: InputEventKey, s: GameState) -> bool:
	if showing() and k.keycode == KEY_ESCAPE:
		skip(s)
		return true
	return false


func skip(s: GameState) -> void:
	if flow == "":
		return
	finish(s, flow)
	_report(flow, "skip")
	visible = false
	flow = ""
	step_i = -1
	_step = {}


func _report(f: String, what: String) -> void:
	if on_event.is_valid():
		on_event.call(f, what)


## Dev only (web): window.odWizard = {flow, step, hole [x, y, w, h], skip [x, y]} in viewport px.
func web_info(origin: Vector2) -> Dictionary:
	if not showing():
		return {"flow": ""}
	return {"flow": flow, "step": str(_step.get("id", step_i)), "soft": soft(),
		"hole": [hole.position.x + origin.x, hole.position.y + origin.y, hole.size.x, hole.size.y],
		"center": [hole.get_center().x + origin.x, hole.get_center().y + origin.y],
		"skip": [skip_rect.get_center().x + origin.x, skip_rect.get_center().y + origin.y], "text": _text.text}
