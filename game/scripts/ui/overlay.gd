class_name Overlay
extends Node2D
## A modal: ux/screen-graph.md §2-5 (slot rule, input capture, Esc, back button), hud-layout §11,
## settings-and-a11y §5 (keyboard focus), motion-spec modal-enter/-exit. A cream ui_card over the
## deep-grape scrim. J6: the card falls from −dropInOffsetPx and lands with a squash.

var id := ""
var host: Node               # MainController (duck-typed host API)
var mgr: OverlayManager
var panel := Node2D.new()
var scrim: ColorRect
var frame: NinePatchRect
var focusables: Array[PxButton] = []
var panel_rect := Rect2(0, 0, L.W, L.H)
var backdrop_closes := true
var focus_index := 0
var opened_ms := 0.0
var closing := false
var _age := 0.0
# optional scrolling body (Settings, Perks, Troop Book)
var body: Node2D
var clip: Control
var clip_rect := Rect2()
var scroll := 0.0
var content_bottom := 0.0
var body_focusables: Array[PxButton] = []
var _drag := {}
var _anim: Dictionary = {}
var _drop: Array = []


func _init() -> void:
	var D := float(Tune.MC["dropInOffsetPx"])
	var SQ := float(Tune.MC["squishPx"])
	_drop = [[-D, 0, 0], [-D, 0, 0], [-D * 7 / 8, 0, 0], [-D * 3 / 4, 0, 0], [-D * 9 / 16, 0, 0], [-D * 5 / 16, 0, 0],
		[0, 2 * SQ, -SQ], [0, 2 * SQ, -SQ], [-SQ / 2, -SQ, SQ], [-SQ, -SQ, SQ], [-SQ, 0, 0], [-SQ / 2, 0, 0],
		[0, SQ, -SQ / 2], [0, 0, 0], [0, 0, 0]]


func setup(host_: Node, mgr_: OverlayManager) -> void:
	host = host_
	mgr = mgr_
	scrim = Ui.rect(self, Rect2(-4000, -4000, 8720, 9280), Art.theme["scrim"], 0.0)
	add_child(panel)


func make_panel(r: Rect2) -> void:
	panel_rect = r
	frame = Ui.nine(panel, r, Art.theme["modal"]["sprite"], int(Art.theme["modal"]["frame"]))


func text(pos: Vector2, s: String, sc: int, role: Variant = null) -> PxText:
	return PxText.make(panel, pos, s, sc, "plain", role if role != null else Art.theme["modal"]["body"])


func centered(y: float, s: String, sc: int, role: Variant = null, region: Vector2 = Vector2(-1, -1)) -> PxText:
	if region.x < 0:
		region = Vector2(panel_rect.position.x, panel_rect.size.x)
	var t := text(Vector2(0, y), s, sc, role)
	# od-sevev (O-U3): a centred line never runs past its panel; an overflow ellipsizes (the
	# build-time lint is the real guard; this is the runtime backstop)
	t.wrap_width = maxf(0.0, region.y - 32.0)
	t.max_lines = 1
	t.center_in(region.x, region.y)
	return t


func close_button(visual: Rect2, hit: Rect2, on_commit: Callable) -> PxButton:
	var b := PxButton.make(panel, visual, {"hit": hit, "ghost": true, "on_commit": on_commit})
	Ui.img(panel, visual.position, Art.theme["close"]["sprite"], int(Art.theme["close"]["frame"]), 4)
	return b


func button(visual: Rect2, hit: Rect2, label: String, on_commit: Callable, kind: String = "button", label_scale: int = 4) -> PxButton:
	var b := PxButton.make(panel, visual, {"hit": hit, "label": label, "label_scale": label_scale, "kind": kind, "on_commit": on_commit})
	focusables.append(b)
	return b


## Esc / back button / backdrop (= the overlay's cancel path). Subclasses override.
func cancel(_via: String) -> void:
	mgr.close(self, _via)


func update_view(_dt_ms: float) -> void:
	pass


func default_focus() -> int:
	return 0


func on_opened() -> void:
	pass


func button_at(p: Vector2) -> PxButton:
	var lp := p - Vector2(0, panel.position.y)
	for b in focusables:
		if not body_focusables.has(b) and b.contains(lp):
			return b
	if body and Ui.in_rect(clip_rect, lp):
		var bp := lp + Vector2(0, scroll)
		for b in body_focusables:
			if b.contains(bp):
				return b
	return null


## A scrolling region inside the panel: children of `body` use design coordinates and scroll
## by dragging (or the mouse wheel) when their content is taller than `r`.
func make_scroll(r: Rect2) -> Node2D:
	clip_rect = r
	clip = Control.new()
	clip.clip_contents = true
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip.position = r.position
	clip.size = r.size
	panel.add_child(clip)
	body = Node2D.new()
	body.position = -r.position
	clip.add_child(body)
	return body


func body_button(visual: Rect2, hit: Rect2, label: String, on_commit: Callable, kind: String = "button", label_scale: int = 4) -> PxButton:
	var b := PxButton.make(body, visual, {"hit": hit, "label": label, "label_scale": label_scale, "kind": kind, "on_commit": on_commit})
	focusables.append(b)
	body_focusables.append(b)
	return b


func max_scroll() -> float:
	return maxf(0.0, content_bottom - clip_rect.end.y)


func set_scroll(v: float) -> void:
	scroll = clampf(v, 0.0, max_scroll())
	if body:
		body.position.y = -clip_rect.position.y - roundf(scroll / 4.0) * 4.0


func drag_begin(p: Vector2) -> void:
	var lp := p - Vector2(0, panel.position.y)
	if body and Ui.in_rect(clip_rect, lp):
		_drag = {"y0": lp.y, "s0": scroll, "moved": false}


## Returns true once the pointer has moved far enough to be a scroll (the pressed button cancels).
func drag_move(p: Vector2) -> bool:
	if _drag.is_empty():
		return false
	var lp := p - Vector2(0, panel.position.y)
	var dy := lp.y - float(_drag["y0"])
	if not _drag["moved"] and absf(dy) > float(Tune.T["buyDragCancelPx"]):
		_drag["moved"] = true
	if _drag["moved"]:
		set_scroll(float(_drag["s0"]) - dy)
	return _drag["moved"]


func drag_end() -> void:
	_drag = {}


func wheel(dy: float) -> void:
	if body:
		set_scroll(scroll + dy * float(Tune.MC["wheelNotchPx"]))


func in_panel(p: Vector2) -> bool:
	return Ui.in_rect(panel_rect, p)


func focused() -> PxButton:
	if focus_index < 0 or focus_index >= focusables.size():
		return null
	var b := focusables[focus_index]
	return b if b.is_enabled() else null


func move_focus(dir: int) -> void:
	var n := focusables.size()
	for i in range(1, n + 1):
		var j := posmod(focus_index + dir * i, n)
		if focusables[j].is_enabled():
			focus_index = j
			_scroll_into_view(focusables[j])
			return


func _scroll_into_view(b: PxButton) -> void:
	if not body or not body_focusables.has(b):
		return
	if b.visual.position.y - scroll < clip_rect.position.y:
		set_scroll(b.visual.position.y - clip_rect.position.y - 8.0)
	elif b.visual.end.y - scroll > clip_rect.end.y:
		set_scroll(b.visual.end.y - clip_rect.end.y + 8.0)


func enter(reduced: bool) -> void:
	visible = true
	panel.modulate.a = 0.0
	scrim.modulate.a = 0.0
	_anim = {"kind": "enter", "t": 0.0, "reduced": reduced}


func exit(reduced: bool, done: Callable) -> void:
	closing = true
	_anim = {"kind": "exit", "t": 0.0, "reduced": reduced, "done": done, "a0": scrim.modulate.a}


func tick(dt_ms: float) -> void:
	_age += dt_ms
	if not _anim.is_empty():
		_anim["t"] = float(_anim["t"]) + dt_ms
		var t: float = _anim["t"]
		var backdrop := float(Tune.MC["backdropAlpha"])
		if _anim["kind"] == "enter":
			if _anim["reduced"]:
				var p := minf(1.0, t / 120.0)
				panel.modulate.a = Ui.quad_out(p)
				scrim.modulate.a = backdrop * Ui.quad_out(p)
				panel.position.y = 0.0
				if p >= 1.0:
					_anim = {}
					on_opened()
			else:
				var enter_ms := float(Tune.MC["modalEnterMs"])
				if t >= enter_ms:
					panel.position.y = 0.0
					if frame:
						PxButton.squish_nine(frame, panel_rect, 0, 0)
					panel.modulate.a = 1.0
					scrim.modulate.a = backdrop
					_anim = {}
					on_opened()
				else:
					var d: Array = Juice.sample(_drop, t)
					panel.position.y = float(d[0])
					if frame:
						PxButton.squish_nine(frame, panel_rect, float(d[1]), float(d[2]))
					panel.modulate.a = minf(1.0, 1.0 - pow(1.0 - minf(1.0, t / 100.0), 2.0))
					scrim.modulate.a = backdrop * minf(1.0, 1.0 - pow(1.0 - minf(1.0, t / 200.0), 2.0))
		else:
			var ms := 100.0 if _anim["reduced"] else float(Tune.MC["modalExitMs"])
			var p2 := minf(1.0, t / ms)
			var e := p2 * p2
			if not _anim["reduced"]:
				panel.position.y = Ui.snap(float(Tune.MC["modalExitOffsetPx"]) * e, 4)
			panel.modulate.a = 1.0 - (p2 if _anim["reduced"] else e)
			scrim.modulate.a = float(_anim["a0"]) * (1.0 - (p2 if _anim["reduced"] else e))
			if p2 >= 1.0:
				var done: Callable = _anim["done"]
				_anim = {}
				queue_free()
				if done.is_valid():
					done.call()
				return
	update_view(dt_ms)
