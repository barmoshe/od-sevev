class_name SheetCard
extends Overlay
## The §7.1 modal card the od-sevev modals share (ux/rtl-map.md §7.1-7.2; kit `sheet_modal`, whose
## note names "the return card O1, the 'לפזר את הכנסת' election modal, the round card"): 624 wide
## at x 48, centred in the visible band, the kit's dark sheet with its 22-art title band, white
## labels. It replaces the fork's cream card with fixed-y ×3 lines, which ellipsised the Hebrew.
##
## A subclass lays its content out top to bottom with the helpers below and calls `finish()`:
##   title(text)          centred in a 432 box clear of the ✕, in the title band
##   para(text, colour)   ×4 body copy (large text ×5), right-aligned at x 640 in the modal.body
##                        box (560), wrapping: the card grows by the measured line count, never an
##                        ellipsis (string-budgets modal.body: 4 lines, 6 in large text)
##   two_buttons          §7.1: side by side when both labels fit 224 px at the scale drawn
##                        (cancel RIGHT Rect2(376, y, 256, 96), commit LEFT Rect2(88, y, 256, 96)),
##                        otherwise stacked full width Rect2(88, y, 544, 96), commit on top
##   one_button           full width
##   close_x              the ✕ at the title band's left end (visual 64 at +16, hit 104)
## Texts are laid out card-locally under a holder that finish() moves to the centred card; the
## buttons are built by finish() at their final rects, so input and the focus ring are exact.

const CARD_X := 48.0
const CARD_W := 624.0
const HEADER_H := 88.0               # sheet_modal title band (slice top 22 art)
const TEXT_RIGHT := 640.0            # modal.body box x 80-640
const TEXT_W := 560.0
const TITLE_W := 432.0
const PAD := 24.0
const PARA_GAP := 16.0
const BTN_H := 96.0
const BTN_GAP := 16.0
const HALF_LABEL_W := 224.0          # string-budgets modal.btnHalf
const BAND_MARGIN := 16.0
const C_TEXT := Color("#f7f4ec")     # white label on the sheet (kit note: 15.6:1 on ui_panel)
const C_MUTED := Color("#a4a9b8")    # grey
const C_GOLD := Color("#ffd23a")     # money (style guide: gold is money-only)
const C_ALERT := Color("#f86b5d")    # red_hi

var title_text: PxText
var paras: Array[PxText] = []
var close_btn: PxButton
var buttons: Array[PxButton] = []
var _holder := Node2D.new()
var _y := 0.0                        # the layout cursor, card-local
var _specs: Array = []               # [rect (card-local y), label, kind, on_commit]
var _close_cb := Callable()


func _begin() -> void:
	panel.add_child(_holder)
	_y = HEADER_H + PAD


func close_x(on_commit: Callable) -> void:
	_close_cb = on_commit


func title(t: String) -> PxText:
	title_text = PxText.make(_holder, Vector2(0, 24.0), t, L.TEXT, "plain", C_TEXT)
	title_text.wrap_width = TITLE_W
	title_text.max_lines = 1
	title_text.center_in(CARD_X + (CARD_W - TITLE_W) / 2.0, TITLE_W)
	return title_text


## A wrapping body paragraph at the cursor; `centre` centres it (one-line numbers, the mood).
func para(t: String, col: Color = C_TEXT, centre: bool = false, lines: int = 8) -> PxText:
	if t == "":
		return null
	var p := PxText.make(_holder, Vector2(0, _y), t, L.TEXT, "plain", col)
	p.wrap_width = TEXT_W
	p.max_lines = lines
	if centre:
		p.align = 1
		p.center_in(CARD_X + (CARD_W - TEXT_W) / 2.0, TEXT_W)
	else:
		p.right_at(TEXT_RIGHT)
	paras.append(p)
	_y += Ui.snap(_lh(p) * maxf(1.0, float(p.line_count())), 4) + PARA_GAP
	return p


func gap(px: float) -> void:
	_y += px


## True when every label fits the half-width box (224 px) at the scale drawn.
static func fits_half(labels: Array) -> bool:
	for l: Variant in labels:
		var t := PxText.new()
		t.px = L.TEXT
		t.text = str(l)
		var w := t.width()
		t.free()
		if w > HALF_LABEL_W:
			return false
	return true


func two_buttons(commit_label: String, commit_kind: String, on_commit: Callable, cancel_label: String, on_cancel: Callable) -> void:
	_y = Ui.snap(_y - PARA_GAP + PAD, 4)
	if fits_half([commit_label, cancel_label]):
		_specs.append([Rect2(88, _y, 256, BTN_H), commit_label, commit_kind, on_commit])
		_specs.append([Rect2(376, _y, 256, BTN_H), cancel_label, "kit_secondary", on_cancel])
		_y += BTN_H
	else:
		_specs.append([Rect2(88, _y, 544, BTN_H), commit_label, commit_kind, on_commit])
		_y += BTN_H + BTN_GAP
		_specs.append([Rect2(88, _y, 544, BTN_H), cancel_label, "kit_secondary", on_cancel])
		_y += BTN_H


func one_button(label: String, kind: String, on_commit: Callable) -> void:
	_y = Ui.snap(_y - PARA_GAP + PAD, 4)
	_specs.append([Rect2(88, _y, 544, BTN_H), label, kind, on_commit])
	_y += BTN_H


## Sizes the sheet to the content, centres it in the visible band, moves the texts there and
## builds the buttons (in declaration order into `buttons`, then the ✕) at their final rects.
func finish() -> void:
	var h := Ui.snap(_y + PAD, 4)
	var band := _band()
	var lo := band.x + BAND_MARGIN
	var y := Ui.snap(clampf((band.x + band.y) / 2.0 - h / 2.0, lo, maxf(lo, band.y - BAND_MARGIN - h)), 4)
	panel_rect = Rect2(CARD_X, y, CARD_W, h)
	frame = Ui.nine(panel, panel_rect, Art.sprite_or("sheet_modal"))
	panel.move_child(frame, 0)
	_holder.position.y = y
	buttons.clear()
	for sp: Array in _specs:
		var r: Rect2 = sp[0]
		r.position.y += y
		var b := PxButton.make(panel, r, {"hit": r, "label": sp[1], "label_scale": L.TEXT, "kind": sp[2], "on_commit": sp[3]})
		if b.label != null:
			b.label.wrap_width = r.size.x - 32.0
			b.label.max_lines = 1
			b.label.center_in(r.position.x, r.size.x)
		focusables.append(b)
		buttons.append(b)
	if _close_cb.is_valid():
		var id := Art.sprite_or("icon_close")
		var sz := Vector2(Art.sprite_size(id)) * 4.0
		var vis := Rect2(CARD_X + 16.0, y + 16.0, 64.0, 64.0)
		close_btn = PxButton.make(panel, vis, {"hit": Rect2(CARD_X, y, 104.0, 104.0), "ghost": true, "on_commit": _close_cb})
		Ui.img(panel, (vis.position + (vis.size - sz) / 2.0).snapped(Vector2(4, 4)), id, 0, 4)
		focusables.append(close_btn)


func _lh(t: PxText) -> float:
	return float(HeFont.line_height()) * t.eff_px()


## The visible band of the modal space (y top, y bottom), as FlashCard: the 1280-tall modal space
## is centred between the insets (MainController._ovl_y).
func _band() -> Vector2:
	if host == null or not ("_ovl_y" in host and "_top_y" in host):
		return Vector2(0.0, float(L.H))
	var over := float(host.get("_ovl_y")) - float(host.get("_top_y"))
	return Vector2(-over, float(L.H) + over)


## Viewport logical px of a modal-space point (tests and the web driver aim with it).
func to_view(p: Vector2) -> Vector2:
	if host == null or not ("_ox" in host and "_ovl_y" in host):
		return p
	return p + Vector2(float(host.get("_ox")), float(host.get("_ovl_y")))


## Web debug: the buttons' centres in viewport logical px (window.odModal), for the browser
## driver (like window.odFlash).
func publish_web(extra: Dictionary = {}) -> void:
	if not OS.has_feature("web"):
		return
	var bs: Array = []
	for b: PxButton in buttons:
		var c := to_view(b.visual.get_center())
		bs.append([c.x, c.y])
	var info := {"open": true, "id": id, "buttons": bs}
	info.merge(extra)
	JavaScriptBridge.eval("window.odModal = %s" % JSON.stringify(info), true)


func _exit_tree() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.odModal = {open: false}", true)
