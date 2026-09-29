class_name Toasts
extends Node2D
## The toast dock (ux/rtl-map.md §4: Rect2(16, 8, 688, 88) one line, 132 two lines, text box
## x 32-688 right-aligned) and Dubi's speech bubble (ux/ftue.md H1, P1 F1, E1). A child of the
## stage node (design y = STAGE.y + stage-local y).
## ux/ftue.md §3.1: one toast at a time, each ≥ 3 s (or until tapped), 1 s gap between toasts.

const SHOW_MS := 3000.0
const GAP_MS := 1000.0

var reduced_motion := false
## Called with the shown toast's tag when it is tapped (T3: a "chat" toast opens the chat).
var on_tap: Callable
## Dubi's line filter, func(text) -> String: every squawk is a talking point, so the controller
## routes it through FlashCard.dubi_says (the sim's word salad).
var dubi_line: Callable
var _queue: Array[String] = []
var _tags: Array[String] = []
var _tag := ""
var _plate: NinePatchRect
var _text: PxText
var _t := -1.0
var _gap := 0.0
var _bubble: NinePatchRect
var _btext: PxText
var _bt := -1.0
var _bdur := 0.0


func _ready() -> void:
	_plate = Ui.nine(self, Rect2(16, float(L.STAGE["y"]) + 8.0, 688, 88), Art.sprite_or("toast"))
	_text = PxText.make(self, Vector2(688, float(L.STAGE["y"]) + 24.0), "", L.TEXT, "plain", "w")
	_text.h_anchor = 2
	_text.wrap_width = 656
	_text.max_lines = 2
	_bubble = Ui.nine(self, Rect2(0, 0, 64, 64), Art.sprite_or("chat_bubble_in"))
	_btext = PxText.make(self, Vector2.ZERO, "", L.TEXT, "plain", Color("#1b1426"))
	for n: CanvasItem in [_plate, _text, _bubble, _btext]:
		n.visible = false


func show_toast(text: String, tag: String = "") -> void:
	if text != "":
		_queue.append(text)
		_tags.append(tag)


## True while nothing is showing and nothing waits (the C1 ping's allowPing half).
func idle() -> bool:
	return _t < 0.0 and _queue.is_empty()


## The rect a toast covers (the Suitcase spawn guard), or an empty rect.
func covered_rect() -> Rect2:
	return Rect2(_plate.position, _plate.size * 4.0) if _plate.visible else Rect2()


func tap(p: Vector2) -> bool:
	if _plate.visible and Ui.in_rect(Rect2(_plate.position, _plate.size * 4.0), p):
		_t = SHOW_MS
		if on_tap.is_valid() and _tag != "":
			on_tap.call(_tag)
		return true
	return false


## Dubi's bubble over a point (stage coordinates, the bubble's bottom centre), for `ms`.
func say(text: String, at: Vector2, ms: float = 1600.0) -> void:
	_btext.text = dubi_line.call(text) if dubi_line.is_valid() else text
	var w := float(_btext.width()) + 48.0
	var h := float(HeFont.line_height() * L.TEXT) + 24.0
	var x := clampf(Ui.snap(at.x - w / 2.0, 4), 16.0, L.W - 16.0 - w)
	var r := Rect2(x, Ui.snap(at.y - h, 4), Ui.snap(w, 4), Ui.snap(h, 4))
	Ui.set_nine_rect(_bubble, r)
	_btext.position = Vector2(r.position.x + 24.0, r.position.y + 12.0)
	_bubble.visible = true
	_btext.visible = true
	_bt = 0.0
	_bdur = ms


func saying() -> bool:
	return _bt >= 0.0


func update_view(dt_ms: float) -> void:
	if _bt >= 0.0:
		_bt += dt_ms
		if _bt >= _bdur:
			_bt = -1.0
			_bubble.visible = false
			_btext.visible = false
	if _t >= 0.0:
		_t += dt_ms
		if _t >= SHOW_MS:
			_t = -1.0
			_gap = GAP_MS
			_plate.visible = false
			_text.visible = false
		return
	if _gap > 0.0:
		_gap -= dt_ms
		return
	if _queue.is_empty():
		return
	_text.text = _queue.pop_front()
	_tag = _tags.pop_front() if not _tags.is_empty() else ""
	var two := _text.line_count() > 1
	Ui.set_nine_rect(_plate, Rect2(16, float(L.STAGE["y"]) + 8.0, 688, 132 if two else 88))
	_plate.visible = true
	_text.visible = true
	_t = 0.0
	if not reduced_motion:
		_plate.modulate.a = 0.0
		_text.modulate.a = 0.0
		var tw := create_tween().set_parallel()
		tw.tween_property(_plate, "modulate:a", 1.0, 0.18)
		tw.tween_property(_text, "modulate:a", 1.0, 0.18)
