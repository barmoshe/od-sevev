class_name Toasts
extends Node2D
## The toast dock (ux/rtl-map.md §4: Rect2(16, 8, 688, 88) one line, 132 two lines, text box
## x 32-676 right-aligned) and Dubi's speech bubble (ux/ftue.md H1, P1 F1, E1). A child of the
## stage node (design y = STAGE.y + stage-local y).
## ux/ftue.md §3.1: one toast at a time, each ≥ 3 s (or until tapped), 1 s gap between toasts.
## Mobile-first §4.1: the dock stretches with the canvas (canvas x 16, w 688 + dx; the text's right
## edge 676 + dx); the node sits in the stage column, so canvas x = stage x + L.sox(). §3.4: during
## a tap burst the controller skips tap() so taps on a toast over the leader's head reach him.

const SHOW_MS := 3000.0
const GAP_MS := 1000.0
## Motion (animator audit 2026-09-29): the plate fades in over 180 ms Quad.Out and out over its last
## 120 ms Quad.In (inside the 3 s), so a toast never pops off; a tap still dismisses at once.
## Reduced motion: both cuts.
const IN_MS := 180.0
const OUT_MS := 120.0

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
var _shown: Array[CanvasItem] = []
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
const C_HEAD := Color("#c9d6f2")    # grey: the sender line, as the thread's names
var _chats: Array[Dictionary] = []
var _face: Sprite2D
var _head: PxText
var _preview: PxText


## rtl-map §4 (rev 2026-09-29): the toast text box is x 32-676, right-aligned at 676 (the kit
## toast's content box ends 24 px before the plate's right edge, where the accent stripe is).
const TEXT_RIGHT := 676.0
const TEXT_W := 644.0
## Dubi's bubble text: white `w` on the kit bubble's #1045b5 (13.6:1; rtl-map §4 "Dubi's bubble").
const BUBBLE_INK := "w"


## The dock in stage-local x (the node is in the stage column at canvas x L.sox()).
static func dock_x() -> float:
	return 16.0 - L.sox()


static func dock_w() -> float:
	return 688.0 + L.dx


## A right edge given in the 720 design (R anchor), in stage-local x.
static func rdx() -> float:
	return L.dx - L.sox()


func relayout() -> void:
	if _plate == null:
		return
	var r := Rect2(dock_x(), _plate.position.y, dock_w(), _plate.size.y * 4.0)
	Ui.set_nine_rect(_plate, r)
	_text.wrap_width = TEXT_W + L.dx
	_text.right_at(TEXT_RIGHT + rdx())
	_head.wrap_width = CHAT_TEXT_W + L.dx
	_head.right_at(CHAT_TEXT_RIGHT + rdx())
	_preview.wrap_width = CHAT_TEXT_W + L.dx
	_preview.right_at(CHAT_TEXT_RIGHT + rdx())
	_face.position.x = FACE_X + rdx()


func _ready() -> void:
	_plate = Ui.nine(self, Rect2(16, float(L.STAGE["y"]) + 8.0, 688, 88), Art.sprite_or("toast"))
	_text = PxText.make(self, Vector2(TEXT_RIGHT, float(L.STAGE["y"]) + 24.0), "", L.TEXT, "plain", "w")
	_text.reading = true   # toasts and Dubi's bubble read on the @2 cut where crisp (CONTRACT §6.1)
	_text.h_anchor = 2
	_text.wrap_width = TEXT_W
	_text.max_lines = 2
	_text.max_lines_large = 3   # string-budgets stage.toast linesLarge
	_bubble = Ui.nine(self, Rect2(0, 0, 64, 64), Art.sprite_or("chat_bubble_in"))
	_btext = PxText.make(self, Vector2.ZERO, "", L.TEXT, "plain", BUBBLE_INK)
	_btext.reading = true
	for n: CanvasItem in [_plate, _text, _bubble, _btext]:
		n.visible = false
	_build_chat_nodes()
	relayout()


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
	_preview.reading = true   # the chat toast's line (its head, the sender, stays display)
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
	_face.position = Vector2(FACE_X + rdx(), y0 + Ui.snap((132.0 - crop * sc) / 2.0, 4))
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
	var h := float(HeFont.line_height()) * _btext.eff_px() + 24.0
	var x := clampf(Ui.snap(at.x - w / 2.0, 4), 16.0 - L.sox(), L.cw - L.sox() - 16.0 - w)
	var r := Rect2(x, Ui.snap(at.y - h, 4), Ui.snap(w, 4), Ui.snap(h, 4))
	Ui.set_nine_rect(_bubble, r)
	_btext.position = Vector2(r.position.x + 24.0, r.position.y + 12.0)
	_bubble.visible = true
	_btext.visible = true
	_bt = 0.0
	_bdur = ms


## Hides Dubi's bubble now (the picker opens over the stage).
func clear_bubble() -> void:
	_bt = -1.0
	_bubble.visible = false
	_btext.visible = false


func saying() -> bool:
	return _bt >= 0.0


## The plate grows to the measured line count at the scale drawn (rtl-map §0.2): 88 for one line
## and 132 for two at ×4, one line pitch more per line.
func plate_h() -> float:
	var lh := float(HeFont.line_height()) * _text.eff_px()
	return maxf(88.0, Ui.snap(44.0 + lh * float(maxi(1, _text.line_count())), 4))


## Test hooks: the toast text and the bubble text nodes.
func text_node() -> PxText:
	return _text


func bubble_text_node() -> PxText:
	return _btext


func update_view(dt_ms: float) -> void:
	if _bt >= 0.0:
		_bt += dt_ms
		if _bt >= _bdur:
			_bt = -1.0
			_bubble.visible = false
			_btext.visible = false
	if _t >= 0.0:
		_t += dt_ms
		if _t < SHOW_MS:
			var a := 1.0
			if not reduced_motion:
				a = minf(Ui.quad_out(minf(1.0, _t / IN_MS)), 1.0 - Ui.quad_in(clampf((_t - (SHOW_MS - OUT_MS)) / OUT_MS, 0.0, 1.0)))
			for n: CanvasItem in _shown:
				n.modulate.a = a
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
	var y0 := float(L.STAGE["y"]) + 8.0
	if chat.is_empty():
		_text.text = msg
		Ui.set_nine_rect(_plate, Rect2(dock_x(), y0, dock_w(), plate_h()))
		shown_nodes.append(_text)
	else:
		_text.text = ""
		_head.text = str(chat.get("head", ""))
		_head.right_at(CHAT_TEXT_RIGHT + rdx())
		_preview.text = msg
		_preview.right_at(CHAT_TEXT_RIGHT + rdx())
		# two one-line rows at the scale drawn (132 at ×4; the lines grow under large text)
		var lh_head := float(HeFont.line_height()) * _head.eff_px()
		var lh_prev := float(HeFont.line_height()) * _preview.eff_px()
		_preview.position.y = y0 + 16.0 + lh_head
		Ui.set_nine_rect(_plate, Rect2(dock_x(), y0, dock_w(), maxf(132.0, Ui.snap(44.0 + lh_head + lh_prev, 4))))
		shown_nodes.append_array([_head, _preview])
		if _set_face(chat.get("avatar", [])):
			shown_nodes.append(_face)
	for n: CanvasItem in shown_nodes:
		n.visible = true
	_t = 0.0
	_shown = shown_nodes
	for n: CanvasItem in shown_nodes:
		n.modulate.a = 1.0 if reduced_motion else 0.0   # update_view eases it in (scene time)
