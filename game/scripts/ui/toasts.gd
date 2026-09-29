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
# the chat toast (show_chat_toast): its own face and two lines, so the plain toast's text node
# keeps its own box
const CHAT_TEXT_RIGHT := 596.0
const CHAT_TEXT_W := 564.0          # string-budgets stage.toastHead / stage.toastChat box
const FACE_X := 612.0
const FACE_ART := 16.0
const C_HEAD := Color("#a4a9b8")    # grey: the sender line, as the thread's names
var _chats: Array[Dictionary] = []
var _face: Sprite2D
var _head: PxText
var _preview: PxText


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
	_build_chat_nodes()


func show_toast(text: String, tag: String = "") -> void:
	if text != "":
		_queue.append(text)
		_tags.append(tag)
		_sync_chats()
		_chats.append({})


## A chat toast (rtl-map §4 "Chat toast", review R5): the sender's 16×16-art face crop inside the
## plate's accent (x 612-676), line 1 `head` (TOAST_CHAT_HEAD "{name} · בקבוצה"), line 2 the
## message preview, one line, ellipsised; both right-aligned at 596 (box x 32-596). Always two
## lines (132). `avatar` = [art id, logical px per sprite px, density] (ChatView.avatar_art); an
## empty id draws no face. The tag is "chat" (a tap opens T3).
func show_chat_toast(head: String, preview: String, avatar: Array) -> void:
	if preview == "" and head == "":
		return
	_queue.append(preview)
	_tags.append("chat")
	_sync_chats()
	_chats.append({"head": head, "avatar": avatar})


## Called right after a text is queued: the chat meta lines up with the texts already waiting
## (a caller may clear `_queue` directly, as the tests do).
func _sync_chats() -> void:
	var want := _queue.size() - 1
	while _chats.size() > want:
		_chats.pop_front()
	while _chats.size() < want:
		_chats.push_front({})


func _build_chat_nodes() -> void:
	var y0 := float(L.STAGE["y"]) + 8.0
	_face = Sprite2D.new()
	_face.centered = false
	_face.region_enabled = true
	_face.visible = false
	add_child(_face)
	_head = PxText.make(self, Vector2(CHAT_TEXT_RIGHT, y0 + 16.0), "", L.TEXT, "plain", C_HEAD)
	_head.wrap_width = CHAT_TEXT_W
	_head.max_lines = 1
	_head.right_at(CHAT_TEXT_RIGHT)
	_head.visible = false
	_preview = PxText.make(self, Vector2(CHAT_TEXT_RIGHT, y0 + 60.0), "", L.TEXT, "plain", "w")
	_preview.wrap_width = CHAT_TEXT_W
	_preview.max_lines = 1
	_preview.right_at(CHAT_TEXT_RIGHT)
	_preview.visible = false


## The face crop: the middle 16×16 art px of the 32×32 chat avatar, drawn at the avatar's own
## scale (art ×4 = 64 logical), so the toast keeps the pixel grid of the thread's avatar.
func _set_face(avatar: Array) -> bool:
	var id := str(avatar[0]) if avatar.size() >= 1 else ""
	if id == "" or id == Art.PLACEHOLDER or not Art.has_sprite(id):
		return false
	var sc := float(avatar[1]) if avatar.size() >= 2 else 4.0
	var dens := float(avatar[2]) if avatar.size() >= 3 else 1.0
	_face.texture = Art.tex(id)
	var tsz := Vector2(_face.texture.get_size())
	var crop := minf(FACE_ART * dens, minf(tsz.x, tsz.y))
	_face.region_rect = Rect2(floorf((tsz.x - crop) / 2.0), floorf((tsz.y - crop) / 2.0), crop, crop)
	_face.scale = Vector2(sc, sc)
	var y0 := float(L.STAGE["y"]) + 8.0
	_face.position = Vector2(FACE_X, y0 + Ui.snap((132.0 - crop * sc) / 2.0, 4))
	return true


## Test hook: what the dock shows now, {head, preview, text, face, h}.
func shown() -> Dictionary:
	return {"head": _head.text if _head.visible else "", "preview": _preview.text if _preview.visible else "",
		"text": _text.text if _text.visible else "", "face": _face.visible,
		"h": _plate.size.y * 4.0 if _plate.visible else 0.0}


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
			for n: CanvasItem in [_face, _head, _preview]:
				n.visible = false
		return
	if _gap > 0.0:
		_gap -= dt_ms
		return
	if _queue.is_empty():
		return
	var msg: String = _queue.pop_front()
	_tag = _tags.pop_front() if not _tags.is_empty() else ""
	var chat: Dictionary = _chats.pop_front() if _chats.size() > _queue.size() else {}
	while _chats.size() > _queue.size():
		_chats.pop_front()
	var shown_nodes: Array[CanvasItem] = [_plate]
	if chat.is_empty():
		_text.text = msg
		var two := _text.line_count() > 1
		Ui.set_nine_rect(_plate, Rect2(16, float(L.STAGE["y"]) + 8.0, 688, 132 if two else 88))
		shown_nodes.append(_text)
	else:
		_text.text = ""
		_head.text = str(chat.get("head", ""))
		_head.right_at(CHAT_TEXT_RIGHT)
		_preview.text = msg
		_preview.right_at(CHAT_TEXT_RIGHT)
		Ui.set_nine_rect(_plate, Rect2(16, float(L.STAGE["y"]) + 8.0, 688, 132))
		shown_nodes.append_array([_head, _preview])
		if _set_face(chat.get("avatar", [])):
			shown_nodes.append(_face)
	for n: CanvasItem in shown_nodes:
		n.visible = true
	_t = 0.0
	if not reduced_motion:
		var tw := create_tween().set_parallel()
		for n: CanvasItem in shown_nodes:
			n.modulate.a = 0.0
			tw.tween_property(n, "modulate:a", 1.0, 0.18)
