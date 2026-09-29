class_name OverlayManager
extends Node2D
## The modal stack (ux/screen-graph.md §2-5): one overlay at a time (SETTINGS -> RESET excepted),
## the rest queue. Owns input capture while open, keyboard focus, and the back button.

signal stack_changed

var stack: Array[Overlay] = []
var tx_active := false
var input_locked_until := 0.0
var reduced := false
var keyboard_active: Callable   # func() -> bool
var _queue: Array[Callable] = []
var _pressed: PxButton
var _focus_ring: NinePatchRect
var _now := 0.0


func _ready() -> void:
	_focus_ring = Ui.nine(self, Rect2(0, 0, 32, 32), Art.theme["focusRing"]["sprite"], int(Art.theme["focusRing"]["frame"]))
	_focus_ring.visible = false
	_focus_ring.z_index = 10


func is_open() -> bool:
	return not stack.is_empty()


func top() -> Overlay:
	return stack[stack.size() - 1] if not stack.is_empty() else null


func now_ms() -> float:
	return _now


func has_id(id: String) -> bool:
	for o in stack:
		if o.id == id:
			return true
	return false


## `make` builds the overlay: func() -> Overlay.
func request(make: Callable, child: bool = false) -> void:
	if not stack.is_empty() and not child:
		_queue.append(make)
		return
	var ov: Overlay = make.call()
	add_child(ov)
	move_child(_focus_ring, -1)
	stack.append(ov)
	ov.focus_index = ov.default_focus()
	ov.opened_ms = _now
	ov.enter(reduced)
	stack_changed.emit()


func close(ov: Overlay, _via: String = "") -> void:
	if ov.closing or not stack.has(ov):
		return
	stack.erase(ov)
	input_locked_until = _now + (50.0 if reduced else 80.0)
	_pressed = null
	ov.exit(reduced, func() -> void:
		if stack.is_empty() and not _queue.is_empty():
			request(_queue.pop_front())
		stack_changed.emit())
	stack_changed.emit()


func close_all() -> void:
	_queue.clear()
	for o in stack.duplicate():
		close(o, "confirm")


func back() -> bool:
	if tx_active:
		return true
	var t := top()
	if t == null:
		return false
	t.cancel("back")
	return true


func pointer_down(p: Vector2) -> void:
	var t := top()
	if t == null:
		return
	if t.closing or _now - t.opened_ms < 120.0:
		return
	var b := t.button_at(p)
	t.drag_begin(p)
	if b:
		_pressed = b
		b.down()
		t.focus_index = maxi(0, t.focusables.find(b))
		return
	if not t.in_panel(p) and t.backdrop_closes:
		t.cancel("backdrop")


func pointer_move(p: Vector2) -> void:
	var t := top()
	if t and t.drag_move(p) and _pressed:
		_pressed.cancel()
		_pressed = null


func wheel(p: Vector2, dy: float) -> void:
	var t := top()
	if t:
		t.wheel(dy)


func pointer_up(p: Vector2) -> void:
	var b := _pressed
	_pressed = null
	var t := top()
	if t:
		t.drag_end()
	if b:
		var lp := p - Vector2(0, t.panel.position.y) if t else p
		if t and t.body_focusables.has(b):
			lp += Vector2(0, t.scroll)
		b.up(Ui.in_rect(b.hit, lp))


func hover(p: Vector2) -> bool:
	var t := top()
	if t == null:
		return false
	var any := false
	for b in t.focusables:
		var lp := p - Vector2(0, t.panel.position.y)
		if t.body_focusables.has(b):
			lp = lp + Vector2(0, t.scroll) if Ui.in_rect(t.clip_rect, lp) else Vector2(-9999, -9999)
		var on := b.contains(lp)
		b.hover(on)
		any = any or on
	return any


func key(e: InputEventKey) -> void:
	var t := top()
	if t == null or t.closing:
		return
	match e.keycode:
		KEY_ESCAPE:
			t.cancel("esc")
		KEY_TAB:
			t.move_focus(-1 if e.shift_pressed else 1)
		KEY_DOWN, KEY_RIGHT:
			t.move_focus(1)
		KEY_UP, KEY_LEFT:
			t.move_focus(-1)
		KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
			var b := t.focused()
			if b:
				b.down()
				b.up(true)


func update_view(dt_ms: float) -> void:
	_now += dt_ms
	for o in stack.duplicate():
		o.tick(dt_ms)
	for c in get_children():
		if c is Overlay and not stack.has(c):
			(c as Overlay).tick(dt_ms)
	var t := top()
	var b := t.focused() if t else null
	if t and b and keyboard_active.is_valid() and keyboard_active.call() and not t.closing:
		var o := float(Art.theme["focusRing"]["outsetPx"])
		_focus_ring.visible = true
		var sy := t.scroll if t.body_focusables.has(b) else 0.0
		_focus_ring.position = Vector2(b.visual.position.x - o, b.visual.position.y - o + t.panel.position.y - sy)
		_focus_ring.size = (b.visual.size + Vector2(2 * o, 2 * o)) / 4.0
	else:
		_focus_ring.visible = false
