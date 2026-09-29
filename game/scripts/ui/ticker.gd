class_name Ticker
extends Node2D
## News ticker: ux/number-and-copy.md §5 (queue priority), ux/mobile-first-layout.md §5.2 (the
## pager). od-sevev (ux/rtl-map.md §5.1): an 84-px row, `_lower`-local. The red "מבזק" anchor on
## the right (R-anchored: tagRight 700 + dx), Dubi left of it, the date chip on the left (L), the
## clip between them (x 192 … 516 + dx, S-anchored). When the election gate opens the whole row
## becomes the gold "עוד סבב!" button; the pager pauses with its queue intact.
##
## The pager (mobile-first §5.2, D39, replaces the crawl): a headline is broken at spaces into
## lines no wider than the clip, then into pages of 2 lines (1 in large text: two ×5 lines are
## taller than the row). A word is never split, so no glyph is ever cut at a clip edge, and the text
## is still while it is read. Line cells at y 2 and 42 (pitch 40), right-aligned at the clip's
## right edge; a one-line page sits centred in the row. Dwell max(3.5 s, 55 ms × the page's
## characters) (an ftue line: max(4.5 s, …)). The next page enters from the clip's LEFT edge and
## pushes the old one out to the right in 300 ms (the crawl's direction: the first word enters
## first); reduced motion: a 200 ms cross-fade.

const PRIORITY := {"ftue": 3, "milestone": 2, "flavor": 1, "ambient": 0}
const SCALE := L.TEXT
const TAG_BOX := 88.0         # string-budgets ticker.tag
const LINE_Y := [2.0, 42.0]   # mobile-first §5.2: the two line cells (pitch 40)
const ONE_LINE_Y := 22.0      # a one-line page, centred in the 84 row
const DWELL_MS := 3500.0
const DWELL_FTUE_MS := 4500.0
const DWELL_PER_CHAR_MS := 55.0
const PUSH_MS := 300.0
const FADE_MS := 200.0
## M1 (the Animator, later): the push is built but off; until the Animator tunes its curve every
## page change uses the reduced-motion cross-fade (the spec's base pager, mobile-first §8.4).
const PAGE_PUSH := false

var reduced_motion := false
var on_milestone_start: Callable
## func() -> String: an ambient line (v2: conditional headlines). Defaults to content ambientHeadlines.
var ambient_source: Callable

var _queues := {"ftue": [], "milestone": [], "flavor": [], "ambient": []}
var _clip := Control.new()
var _panel: ColorRect
var _flash: ColorRect
var _ambient_ms := 0.0
var _last_ambient := -1
var _hold_until := 0.0
var _now := 0.0
## The pager: two page nodes (the one shown, the one leaving), each two lines.
var _pages_n: Array[Node2D] = []
var _lines: Array = []            # per page node: [PxText, PxText]
var _cur := 0                     # index of the page node on screen
var _item: Dictionary = {}        # the headline showing ({} = none)
var _pages: Array = []            # its pages: Array of PackedStringArray (1-2 lines)
var _page_idx := -1
var _page_t := 0.0
var _dwell := 0.0
var _tr: Dictionary = {}          # the running transition {t, out (node index or -1), fade}


var cta: PxButton
var dubi: SpriteStrip
var _chip: Array[CanvasItem] = []
var _chip_box: NinePatchRect
var _chip_cal: Sprite2D
var _chip_date: PxText
var _anchor: Array[CanvasItem] = []
var _cta_on := false
var _tag_plate: ColorRect
var _tag_text: PxText
var _tag_w := 0.0
var _clip_x1 := float(L.TICKER["clipX1"])
var _clip_x0 := float(L.TICKER["clipX0"])


func _ready() -> void:
	var K: Dictionary = Art.theme["ticker"]
	var panel: Rect2 = L.TICKER["panel"]
	_panel = Ui.rect(self, panel, Color("#1b1426"))
	_clip.clip_contents = true
	_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_clip.position = Vector2(L.TICKER["clipX0"], panel.position.y)
	_clip.size = Vector2(float(L.TICKER["clipX1"]) - float(L.TICKER["clipX0"]), panel.size.y)
	add_child(_clip)
	for i in 2:
		var n := Node2D.new()
		n.visible = false
		_clip.add_child(n)
		_pages_n.append(n)
		var pair: Array = []
		for j in 2:
			var l := PxText.make(n, Vector2.ZERO, "", SCALE, "plain", K["text"])
			l.reading = true   # the headline reads on the @2 cut where crisp; the tag and chip stay display
			l.max_lines = 1
			pair.append(l)
		_lines.append(pair)
	# the anchor: a red plate with "מבזק", right-aligned (rtl-map §5.1)
	var tag: Rect2 = L.TICKER["tag"]
	_tag_plate = Ui.rect(self, tag, Color("#d02a36"))
	_anchor.append(_tag_plate)
	_tag_text = PxText.make(self, Vector2(0, float(L.TICKER["textY"])), Strings.s("TICKER_TAG"), SCALE, "plain", "w")
	_tag_text.fit_width = TAG_BOX   # rtl-map §0.2/§5.1: 110 px at ×5 > 88, so the tag stays ×4
	_anchor.append(_tag_text)
	# Dubi at the anchor (rtl-map §5.1): the TA's small Dubi (chars.dubi), feet on the row floor
	dubi = SpriteStrip.make(self, "dubi", L.TICKER["dubiFeet"])
	if dubi != null:
		dubi.finished.connect(func(_a: String) -> void: dubi.play("idle"))
		_anchor.append(dubi)
	# the date chip (L): kit chip_countdown, the calendar icon at its right, "27.10" left of it
	var cr: Rect2 = L.TICKER["chip"]
	_chip_box = Ui.nine(self, cr, Art.sprite_or("chip_countdown"))
	_chip.append(_chip_box)
	_chip_cal = Ui.img(self, Vector2(cr.end.x - 52, cr.position.y + 12), Art.sprite_or("chip_icon_calendar"), 0, 4)
	_chip.append(_chip_cal)
	_chip_date = PxText.make(self, Vector2(0, cr.position.y + 10), Strings.s("HUD_COUNTDOWN_DATE"), SCALE, "plain", "w")
	_chip_date.right_at(cr.end.x - 60)
	_chip.append(_chip_date)
	for n in _chip:
		n.modulate.a = 0.6
	_flash = Ui.fade_rect(self, panel, K["flash"])
	cta = PxButton.make(self, Rect2(8, 2, 704, 80), {"hit": L.TICKER["hit"], "label": Strings.s("HUD_CTA_ELECTION"), "label_scale": 5, "kind": "kit_gold"})
	cta.set_visible(false)
	relayout()


## mobile-first §4.1: the panel is full bleed (F), the anchor right (R: tagRight 700 + dx), the
## chip left (L), the clip stretches between them, the election CTA spans the row (S).
func relayout() -> void:
	if _panel == null:
		return
	var panel: Rect2 = L.TICKER["panel"]
	_panel.size = Vector2(L.cw + 4.0, panel.size.y)   # + the < 4 px aspect remainder: no seam
	_flash.size = _panel.size
	_layout_anchor()
	cta.set_rects(Rect2(8, 2, 704.0 + L.dx, 80), L.sa(L.TICKER["hit"]))
	if not _item.is_empty():
		_restart_item()   # the clip width changed: re-break the headline into pages


## The anchor, right → left (rtl-map §5.1): the red plate hugging "מבזק" (text right-aligned at
## tagRight, 8 px padding), then Dubi's whole frame, then the crawl clip. Nothing overlaps: the
## plate grows with the measured tag (×4 or large text ×5) and the clip ends where Dubi starts.
## Pure (tests pin it). tag_w = the tag's drawn width; dubi = Dubi's node-local frame rect ({}
## without the sprite). Returns {plate: Rect2, textRight, dubiFeet: Vector2, clipX1}.
static func anchor_layout(tag_w: float, dubi: Rect2, dx: float = 0.0) -> Dictionary:
	var T: Dictionary = L.TICKER
	var tag: Rect2 = T["tag"]
	var right := float(T["tagRight"]) + dx
	var pad := float(T["tagPad"])
	var gap := float(T["anchorGap"])
	var plate := Rect2(right - tag_w - pad, tag.position.y, tag_w + 2.0 * pad, tag.size.y)
	var feet: Vector2 = T["dubiFeet"]
	feet.x += dx
	var left := plate.position.x
	if dubi.size.x > 0.0:
		feet.x = plate.position.x - gap - dubi.end.x   # the frame's right edge sits gap px left of the plate
		left = feet.x + dubi.position.x
	return {"plate": plate, "textRight": right, "dubiFeet": feet, "clipX1": minf(float(T["clipX1"]) + dx, left - gap)}


func _layout_anchor() -> void:
	_tag_w = float(_tag_text.width())
	var lay := anchor_layout(_tag_w, dubi.rect() if dubi != null else Rect2(), L.dx)
	var plate: Rect2 = lay["plate"]
	_tag_plate.position = plate.position
	_tag_plate.size = plate.size
	_tag_text.right_at(float(lay["textRight"]))
	_tag_text.position.y = float(L.TICKER["textY"])
	if dubi != null:
		dubi.position = lay["dubiFeet"]
	_clip_x1 = float(lay["clipX1"])
	_clip.size.x = _clip_x1 - _clip.position.x   # keeps the court-day left edge (x 228) if the chip is up


## The clip's right edge (the anchor's left edge), `_lower`-local.
func clip_x1() -> float:
	return _clip_x1


## The clip as drawn, `_lower`-local (tests: it must end before Dubi on every day).
func clip_rect() -> Rect2:
	return Rect2(_clip.position, _clip.size)


## One beak movement per babble syllable (the Audio's dubi_blip signal).
func dubi_talk() -> void:
	if dubi != null and dubi.has_anim("talk") and visible and not _cta_on:
		dubi.play("talk", true)


## The election CTA replaces the row (rtl-map §5.3). The pager pauses; its queue is kept.
func set_cta(on: bool) -> void:
	if on == _cta_on:
		return
	_cta_on = on
	cta.set_visible(on)
	_clip.visible = not on
	for n in _anchor:
		n.visible = not on
	for n in _chip:
		n.visible = not on and not _court_on


var _court_on := false


## Court day (ui/views/view_court.gd, rtl-map §5.1): the court chip takes the date chip's slot and
## the crawl clip starts `chip_right` + 8 (x 228 for the spec's 212-wide chip).
func set_court_chip(on: bool, chip_right: float = 0.0) -> void:
	_court_on = on
	for n in _chip:
		n.visible = not on and not _cta_on
	var x0 := maxf(float(L.TICKER["clipX0"]), chip_right + 8.0) if on else float(L.TICKER["clipX0"])
	_clip.position.x = x0
	# rtl-map §5.1: the clip's right edge is always the anchor's (anchor_layout().clipX1, 516 + dx),
	# court day included, so a headline never runs under Dubi
	_clip.size.x = _clip_x1 - x0
	if not _item.is_empty():
		_restart_item()


func cta_on() -> bool:
	return _cta_on


func enqueue(kind: String, text: String, front: bool = false) -> void:
	var it := {"text": text, "kind": kind}
	if front:
		(_queues[kind] as Array).push_front(it)
	else:
		(_queues[kind] as Array).append(it)


func defer_until(ms: float) -> void:
	_hold_until = ms


func now_ms() -> float:
	return _now


func set_reduced_motion(on: bool) -> void:
	reduced_motion = on


## window.odDisplay.ticker (mobile-first §5.2; tools/web/mobile_web.mjs reads it).
func web_info() -> Dictionary:
	return {"mode": "page", "clipW": _clip.size.x, "lines": lines_per_page()}


## 2 lines a page; 1 in large text (two ×5 lines are 100 > 84).
static func lines_per_page() -> int:
	return 1 if PxText.body_scale() > L.TEXT else 2


## The text showing: the current page's lines ("" = none; tests).
func page_text() -> String:
	if _item.is_empty() or _page_idx < 0 or _page_idx >= _pages.size():
		return ""
	return " ".join(_pages[_page_idx])


func _requeue(it: Dictionary) -> void:
	if it["kind"] != "ambient":
		(_queues[it["kind"]] as Array).push_front(it)


func _next_item(min_priority: int = 0) -> Dictionary:
	for k in ["ftue", "milestone", "flavor"]:
		if int(PRIORITY[k]) < min_priority:
			continue
		if k != "ftue" and _now < _hold_until:
			continue
		if not (_queues[k] as Array).is_empty():
			return (_queues[k] as Array).pop_front()
	return {}


func _top_queued_priority() -> int:
	for k in ["ftue", "milestone", "flavor"]:
		if k != "ftue" and _now < _hold_until:
			continue
		if not (_queues[k] as Array).is_empty():
			return PRIORITY[k]
	return -1


## Breaks a headline into lines no wider than max_px at scale_px (measured on the real text
## route), at spaces only: a word is never split (a word wider than the box gets a line of its own;
## the content lint keeps every ticker word ≤ 280 at ×4, the narrowest clip).
static func wrap_lines_px(text: String, max_px: float, scale_px: int) -> PackedStringArray:
	var out := PackedStringArray()
	var cur := ""
	for w in text.split(" ", false):
		var trial := w if cur == "" else cur + " " + w
		if cur == "" or PxText.measure(trial, scale_px) <= max_px:
			cur = trial
		else:
			out.append(cur)
			cur = w
	if cur != "":
		out.append(cur)
	if out.is_empty():
		out.append("")
	return out


## mobile-first §5.2: the pages of a headline, `per` lines each.
static func paginate(text: String, max_px: float, scale_px: int, per: int) -> Array:
	var lines := wrap_lines_px(text, max_px, scale_px)
	var pages: Array = []
	var i := 0
	while i < lines.size():
		pages.append(lines.slice(i, i + per))
		i += per
	return pages


## Kept for the fork's callers: one-line pages by measured width.
static func wrap_pages_px(text: String, max_px: float, scale_px: int) -> PackedStringArray:
	return wrap_lines_px(text, max_px, scale_px)


static func dwell_ms(page: PackedStringArray, kind: String) -> float:
	var chars := 0
	for l in page:
		chars += l.length()
	return maxf(DWELL_FTUE_MS if kind == "ftue" else DWELL_MS, DWELL_PER_CHAR_MS * chars)


func _start_item(it: Dictionary) -> void:
	var milestone: bool = it["kind"] == "milestone"
	if milestone:
		if on_milestone_start.is_valid():
			on_milestone_start.call(String(it["text"]))
		if not reduced_motion:
			_flash.modulate.a = 0.8
			create_tween().tween_property(_flash, "modulate:a", 0.0, float(Tune.T["headlineFlashMs"]) / 1000.0).set_ease(Tween.EASE_OUT)
	_item = it
	_pages = paginate(String(it["text"]), _clip.size.x, PxText.body_scale(), lines_per_page())
	_page_idx = -1
	_show_page(0, true)


## Re-breaks the showing headline for a new clip width, keeping its place (the first page).
func _restart_item() -> void:
	_pages = paginate(String(_item["text"]), _clip.size.x, PxText.body_scale(), lines_per_page())
	_page_idx = -1
	_tr = {}
	for n in _pages_n:
		n.visible = false
		n.position.x = 0.0
		n.modulate.a = 1.0
	_show_page(0, false)


## Puts page i on the other page node and starts the push (or the fade); `animate` false = cut.
func _show_page(i: int, animate: bool) -> void:
	var K: Dictionary = Art.theme["ticker"]
	var out := _cur if _pages_n[_cur].visible else -1
	var nxt := 1 - _cur if out >= 0 else _cur
	_cur = nxt
	_page_idx = i
	_page_t = 0.0
	var page: PackedStringArray = _pages[i]
	_dwell = dwell_ms(page, String(_item["kind"]))
	var col := Art.col(K["milestoneText"] if _item["kind"] == "milestone" else K["text"])
	var pair: Array = _lines[nxt]
	var w := _clip.size.x
	for j in 2:
		var l: PxText = pair[j]
		l.text = page[j] if j < page.size() else ""
		l.visible = j < page.size()
		l.tint = col
		l.position.y = ONE_LINE_Y if page.size() == 1 else float(LINE_Y[j])
		if L.RTL:
			l.right_at(w)
		else:
			l.position.x = 0.0
	var n: Node2D = _pages_n[nxt]
	n.visible = true
	n.modulate.a = 1.0
	n.position.x = 0.0
	if animate and out >= 0 and out != nxt:
		_tr = {"t": 0.0, "out": out, "fade": reduced_motion or not PAGE_PUSH}
		_apply_transition(0.0)
	else:
		_tr = {}
		if out >= 0 and out != nxt:
			_pages_n[out].visible = false


## The page transition at t ms: the push (the new page enters from the left edge, the old leaves
## through the right, 4-px steps, cubic ease-out) or the reduced-motion cross-fade.
func _apply_transition(t: float) -> void:
	var out: int = _tr["out"]
	var n_in: Node2D = _pages_n[_cur]
	var n_out: Node2D = _pages_n[out] if out >= 0 else null
	if _tr["fade"]:
		var p := minf(1.0, t / FADE_MS)
		n_in.modulate.a = p
		n_in.position.x = 0.0
		if n_out != null:
			n_out.modulate.a = 1.0 - p
		if p >= 1.0:
			_end_transition()
		return
	var p2 := minf(1.0, t / PUSH_MS)
	var e := 1.0 - pow(1.0 - p2, 3.0)
	var w := _clip.size.x
	var dir := 1.0 if L.RTL else -1.0
	var off := Ui.snap(w * e, 4)
	n_in.position.x = -dir * (w - off)
	if n_out != null:
		n_out.position.x = dir * off
	if p2 >= 1.0:
		_end_transition()


func _end_transition() -> void:
	var out: int = _tr["out"]
	_tr = {}
	(_pages_n[_cur] as Node2D).position.x = 0.0
	(_pages_n[_cur] as Node2D).modulate.a = 1.0
	if out >= 0 and out != _cur:
		var n: Node2D = _pages_n[out]
		n.visible = false
		n.position.x = 0.0
		n.modulate.a = 1.0


## The headline ended (its last page read) or was pre-empted: the next item pushes it out, or
## it leaves on its own (the same push with nothing entering, or the fade).
func _end_item(requeue: bool) -> void:
	if requeue:
		_requeue(_item)
	_item = {}
	_pages = []
	_page_idx = -1
	_ambient_ms = 0.0
	var nxt := _next_item()
	if not nxt.is_empty():
		_start_item(nxt)
		return
	# nothing queued: the page leaves (an empty page node enters)
	var out := _cur
	var pair: Array = _lines[1 - _cur]
	for l: PxText in pair:
		l.text = ""
		l.visible = false
	_cur = 1 - _cur
	(_pages_n[_cur] as Node2D).visible = true
	_tr = {"t": 0.0, "out": out, "fade": reduced_motion or not PAGE_PUSH}
	_apply_transition(0.0)


func update_view(dt_ms: float) -> void:
	_now += dt_ms
	if float(_tag_text.width()) != _tag_w:
		_layout_anchor()   # the text size changed (large text): the plate, Dubi and the clip follow
		if not _item.is_empty():
			_restart_item()
	if dubi != null:
		dubi.update_view(dt_ms)
	if _cta_on:
		return
	if not _tr.is_empty():
		_tr["t"] = float(_tr["t"]) + dt_ms
		_apply_transition(float(_tr["t"]))
	# a higher-priority headline pre-empts the showing one (it returns to its queue)
	if not _item.is_empty() and _top_queued_priority() > int(PRIORITY[_item["kind"]]):
		_end_item(true)
		return
	if _item.is_empty():
		var it := _next_item()
		if not it.is_empty():
			_start_item(it)
			_ambient_ms = 0.0
		else:
			_tick_ambient(dt_ms)
		return
	if not _tr.is_empty():
		return   # the dwell starts when the page is still
	_page_t += dt_ms
	if _page_t < _dwell:
		return
	if _page_idx + 1 < _pages.size():
		_show_page(_page_idx + 1, true)
	else:
		_end_item(false)


func _tick_ambient(dt_ms: float) -> void:
	_ambient_ms += dt_ms
	if _ambient_ms < float(Content.data()["ticker"]["ambientIntervalSec"]) * 1000.0:
		return
	_ambient_ms = 0.0
	var text := ""
	if ambient_source.is_valid():
		text = str(ambient_source.call())
		if text == "":
			return   # od-sevev: no eligible line (or ambientFrom C1 holds them) = no ambient line
	if text == "":
		var list: Array = Content.data()["ambientHeadlines"]
		var i := randi() % list.size()
		if list.size() > 1 and i == _last_ambient:
			i = (i + 1) % list.size()
		_last_ambient = i
		text = list[i]
	_start_item({"text": text, "kind": "ambient"})
