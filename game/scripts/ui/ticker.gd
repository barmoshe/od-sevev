class_name Ticker
extends Node2D
## News ticker: ux/number-and-copy.md §5 (queue priority, marquee, paged), motion-spec
## headline-ticker. The scroll region is a clipping Control (x112..704) instead of v1's
## occluders. Milestone glyphs hop once as they enter (J8). Reduced motion pages the text.
## od-sevev (ux/rtl-map.md §5): an 84-px row, `_lower`-local. The red "מבזק" anchor on the right,
## the crawl clip from x 192 to Dubi's left edge (Ticker.anchor_layout) running LEFT → RIGHT (a Hebrew line's first word enters first), one
## art px (4 logical) every 3 frames = 80 px/s (the Animator's even cadence), the date chip on the
## left. When the election gate opens the whole row becomes the gold "עוד סבב!" button; the crawl
## pauses with its queue intact.

const PRIORITY := {"ftue": 3, "milestone": 2, "flavor": 1, "ambient": 0}
const SCALE := L.TEXT
const STEP_MS := 50.0         # one art px every 3 frames at 60 Hz

var reduced_motion := false
var on_milestone_start: Callable
## func() -> String: an ambient line (v2: conditional headlines). Defaults to content ambientHeadlines.
var ambient_source: Callable

var _queues := {"ftue": [], "milestone": [], "flavor": [], "ambient": []}
var _clip := Control.new()
var _pool: Array[PxText] = []
var _live: Array[Dictionary] = []
var _flash: ColorRect
var _ambient_ms := 0.0
var _last_ambient := -1
var _hold_until := 0.0
var _now := 0.0
var _pages: PackedStringArray = []
var _page_item: Dictionary = {}
var _page_t := 0.0
var _page_idx := -1
var _hop: Array = []


var cta: PxButton
var dubi: SpriteStrip
var _chip: Array[CanvasItem] = []
var _anchor: Array[CanvasItem] = []
var _cta_on := false
var _tag_plate: ColorRect
var _tag_text: PxText
var _tag_w := 0.0
var _clip_x1 := float(L.TICKER["clipX1"])


func _ready() -> void:
	var K: Dictionary = Art.theme["ticker"]
	var panel: Rect2 = L.TICKER["panel"]
	Ui.rect(self, panel, Color("#1b1426"))
	_clip.clip_contents = true
	_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_clip.position = Vector2(L.TICKER["clipX0"], panel.position.y)
	_clip.size = Vector2(float(L.TICKER["clipX1"]) - float(L.TICKER["clipX0"]), panel.size.y)
	add_child(_clip)
	for i in 3:
		var l := PxText.make(_clip, Vector2.ZERO, "", SCALE, "plain", K["text"])
		l.visible = false
		_pool.append(l)
	# the anchor: a red plate with "מבזק", right-aligned (rtl-map §5.1)
	var tag: Rect2 = L.TICKER["tag"]
	_tag_plate = Ui.rect(self, tag, Color("#d02a36"))
	_anchor.append(_tag_plate)
	_tag_text = PxText.make(self, Vector2(0, float(L.TICKER["textY"])), Strings.s("TICKER_TAG"), SCALE, "plain", "w")
	_anchor.append(_tag_text)
	# Dubi at the anchor (rtl-map §5.1): the TA's small Dubi (chars.dubi), feet on the row floor
	dubi = SpriteStrip.make(self, "dubi", L.TICKER["dubiFeet"])
	if dubi != null:
		dubi.finished.connect(func(_a: String) -> void: dubi.play("idle"))
		_anchor.append(dubi)
	_layout_anchor()
	# the date chip: kit chip_countdown, the calendar icon at its right, "27.10" left of it
	var cr: Rect2 = L.TICKER["chip"]
	_chip.append(Ui.nine(self, cr, Art.sprite_or("chip_countdown")))
	var cal := Ui.img(self, Vector2(cr.end.x - 52, cr.position.y + 12), Art.sprite_or("chip_icon_calendar"), 0, 4)
	_chip.append(cal)
	var date := PxText.make(self, Vector2(0, cr.position.y + 10), Strings.s("HUD_COUNTDOWN_DATE"), SCALE, "plain", "w")
	date.right_at(cr.end.x - 60)
	_chip.append(date)
	for n in _chip:
		n.modulate.a = 0.6
	_flash = Ui.fade_rect(self, panel, K["flash"])
	cta = PxButton.make(self, Rect2(8, 4, 704, 76), {"hit": L.TICKER["hit"], "label": Strings.s("HUD_CTA_ELECTION"), "label_scale": 5, "kind": "kit_gold"})
	cta.set_visible(false)
	var hp := float(Tune.MC["tickerHopPx"])
	_hop = [-hp / 2.0, -hp, -hp, -hp / 2.0, 0.0]


## The anchor, right → left (rtl-map §5.1): the red plate hugging "מבזק" (text right-aligned at
## tagRight, 8 px padding), then Dubi's whole frame, then the crawl clip. Nothing overlaps: the
## plate grows with the measured tag (×4 or large text ×5) and the clip ends where Dubi starts.
## Pure (tests pin it). tag_w = the tag's drawn width; dubi = Dubi's node-local frame rect ({}
## without the sprite). Returns {plate: Rect2, textRight, dubiFeet: Vector2, clipX1}.
static func anchor_layout(tag_w: float, dubi: Rect2) -> Dictionary:
	var T: Dictionary = L.TICKER
	var tag: Rect2 = T["tag"]
	var right := float(T["tagRight"])
	var pad := float(T["tagPad"])
	var gap := float(T["anchorGap"])
	var plate := Rect2(right - tag_w - pad, tag.position.y, tag_w + 2.0 * pad, tag.size.y)
	var feet: Vector2 = T["dubiFeet"]
	var left := plate.position.x
	if dubi.size.x > 0.0:
		feet.x = plate.position.x - gap - dubi.end.x   # the frame's right edge sits gap px left of the plate
		left = feet.x + dubi.position.x
	return {"plate": plate, "textRight": right, "dubiFeet": feet, "clipX1": minf(float(T["clipX1"]), left - gap)}


func _layout_anchor() -> void:
	_tag_w = float(_tag_text.width())
	var lay := anchor_layout(_tag_w, dubi.rect() if dubi != null else Rect2())
	var plate: Rect2 = lay["plate"]
	_tag_plate.position = plate.position
	_tag_plate.size = plate.size
	_tag_text.right_at(float(lay["textRight"]))
	_tag_text.position.y = float(L.TICKER["textY"])
	if dubi != null:
		dubi.position = lay["dubiFeet"]
	_clip_x1 = float(lay["clipX1"])
	_clip.size.x = _clip_x1 - float(L.TICKER["clipX0"])


## The crawl clip's right edge (the anchor's left edge), `_lower`-local.
func clip_x1() -> float:
	return _clip_x1


## One beak movement per babble syllable (the Audio's dubi_blip signal).
func dubi_talk() -> void:
	if dubi != null and dubi.has_anim("talk") and visible and not _cta_on:
		dubi.play("talk", true)


## The election CTA replaces the row (rtl-map §5.3). The crawl pauses; its queue is kept.
func set_cta(on: bool) -> void:
	if on == _cta_on:
		return
	_cta_on = on
	cta.set_visible(on)
	_clip.visible = not on
	for n in _chip + _anchor:
		n.visible = not on


func cta_on() -> bool:
	return _cta_on


func _text_y() -> float:
	return float(L.TICKER["textY"]) - (L.TICKER["panel"] as Rect2).position.y


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
	if reduced_motion == on:
		return
	reduced_motion = on
	for l in _live:
		_requeue(l["item"])
	_clear_live()
	if not _page_item.is_empty():
		_requeue(_page_item)
		_page_item = {}
		_pool[0].visible = false


func _requeue(it: Dictionary) -> void:
	if it["kind"] != "ambient":
		(_queues[it["kind"]] as Array).push_front(it)


func _clear_live() -> void:
	for l in _live:
		var line: PxText = l["line"]
		line.visible = false
		line.set_meta("hop", null)
	_live.clear()


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


func _start_item(it: Dictionary) -> void:
	var K: Dictionary = Art.theme["ticker"]
	var milestone: bool = it["kind"] == "milestone"
	if milestone:
		if on_milestone_start.is_valid():
			on_milestone_start.call(String(it["text"]))
		if not reduced_motion:
			_flash.modulate.a = 0.8
			create_tween().tween_property(_flash, "modulate:a", 0.0, float(Tune.T["headlineFlashMs"]) / 1000.0).set_ease(Tween.EASE_OUT)
	if reduced_motion:
		_page_item = it
		# od-sevev (rtl-map §5.2): pages break by measured pixel width, not character count
		_pages = wrap_pages_px(String(it["text"]), _clip.size.x - 8.0, SCALE)
		_page_t = 0.0
		_page_idx = 0
		var l := _pool[0]
		l.text = _pages[0]
		l.tint = Art.col(Art.theme["juiceGain"] if milestone else K["text"])
		l.position = Vector2(4, _text_y())
		if L.RTL:
			l.right_at(_clip.size.x - 4.0)
		l.visible = true
		return
	var line: PxText = null
	for p in _pool:
		var used := false
		for x in _live:
			if x["line"] == p:
				used = true
		if not used:
			line = p
			break
	if line == null:
		return
	line.text = it["text"]
	line.tint = Art.col(K["milestoneText"] if milestone else K["text"])
	line.visible = true
	line.h_anchor = 0
	var x0 := -float(line.width()) if L.RTL else _clip.size.x
	line.position = Vector2(x0, _text_y())
	_live.append({"item": it, "line": line, "x0": x0, "t": 0.0, "w": line.width(), "hop": milestone, "hopAt": {}})


func update_view(dt_ms: float) -> void:
	_now += dt_ms
	if float(_tag_text.width()) != _tag_w:
		_layout_anchor()   # the text size changed (large text): the plate, Dubi and the clip follow
	if dubi != null:
		dubi.update_view(dt_ms)
	if _cta_on:
		return
	var top := _top_queued_priority()
	var showing: Array = []
	if reduced_motion:
		if not _page_item.is_empty():
			showing = [_page_item]
	else:
		showing = _live.map(func(l: Dictionary) -> Dictionary: return l["item"])
	var cur_max := -1
	for it: Dictionary in showing:
		cur_max = maxi(cur_max, int(PRIORITY[it["kind"]]))
	if not showing.is_empty() and top > cur_max:
		for it: Dictionary in showing:
			_requeue(it)
		_clear_live()
		if not _page_item.is_empty():
			_page_item = {}
			_pool[0].visible = false
	if reduced_motion:
		if not _page_item.is_empty():
			_page_t += dt_ms
			var idx := int(floorf(_page_t / float(Tune.MC["tickerPageMs"])))
			if idx >= _pages.size():
				_page_item = {}
				_pool[0].visible = false
				_ambient_ms = 0.0
			elif idx != _page_idx:
				_page_idx = idx
				_pool[0].text = _pages[idx]
				_pool[0].tint = Art.col(Art.theme["ticker"]["text"])
		if _page_item.is_empty():
			var it2 := _next_item()
			if not it2.is_empty():
				_start_item(it2)
			else:
				_tick_ambient(dt_ms)
		return
	var dir := 1.0 if L.RTL else -1.0
	for l in _live:
		l["t"] = float(l["t"]) + dt_ms
		var line: PxText = l["line"]
		line.position.x = float(l["x0"]) + dir * 4.0 * floorf(float(l["t"]) / STEP_MS)
		_apply_hop(l)
	var clip_w := _clip.size.x
	var done: Array = []
	for l in _live:
		var lx := (l["line"] as PxText).position.x
		if (L.RTL and lx > clip_w) or (not L.RTL and lx + float(l["w"]) < 0.0):
			done.append(l)
	for l: Dictionary in done:
		(l["line"] as PxText).visible = false
		(l["line"] as PxText).glyph_dy = Callable()
		_live.erase(l)
	var room := true
	if not _live.is_empty():
		var last: Dictionary = _live[_live.size() - 1]
		if L.RTL:
			room = (last["line"] as PxText).position.x >= float(Tune.MC["tickerGapPx"])
		else:
			room = (last["line"] as PxText).position.x + float(last["w"]) <= clip_w - float(Tune.MC["tickerGapPx"])
	if room and _live.size() < _pool.size():
		var it3 := _next_item()
		if not it3.is_empty():
			_start_item(it3)
			_ambient_ms = 0.0
			return
	if _live.is_empty():
		_tick_ambient(dt_ms)


## J8: each milestone glyph hops once as it passes clipX1 − tickerHopEntryInsetPx.
func _apply_hop(l: Dictionary) -> void:
	if not l["hop"]:
		return
	var line: PxText = l["line"]
	var hop_at: Dictionary = l["hopAt"]
	var inset := float(Tune.MC["tickerHopEntryInsetPx"])
	var entry := _clip.size.x - inset
	var adv := 6.0 * SCALE
	var hop_ms := _hop.size() * Tune.FRAME_MS
	line.glyph_dy = func(i: int, gx: float) -> float:
		var left := line.position.x + gx
		var entered := (left + adv >= inset) if L.RTL else (left <= entry)
		if not hop_at.has(i) and entered:
			hop_at[i] = _now
		if hop_at.has(i):
			var dt := _now - float(hop_at[i])
			if dt < hop_ms:
				return Ui.snap(float(Juice.sample(_hop, dt)), SCALE)
		return 0.0
	line.queue_redraw()


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


## Word-wrap into pages of <= n chars (paged mode, ux §5).
static func wrap_pages(text: String, n: int) -> PackedStringArray:
	var pages := PackedStringArray()
	var cur := ""
	for w in text.split(" ", false):
		if cur == "":
			cur = w.substr(0, n)
		elif cur.length() + 1 + w.length() <= n:
			cur += " " + w
		else:
			pages.append(cur)
			cur = w.substr(0, n)
	if cur != "":
		pages.append(cur)
	if pages.is_empty():
		pages.append("")
	return pages


## Word-wrap into pages no wider than max_px at scale_px, measured on the real text route.
static func wrap_pages_px(text: String, max_px: float, scale_px: int) -> PackedStringArray:
	var pages := PackedStringArray()
	var cur := ""
	for w in text.split(" ", false):
		var trial := w if cur == "" else cur + " " + w
		if cur == "" or PxText.measure(trial, scale_px) <= max_px:
			cur = trial
		else:
			pages.append(cur)
			cur = w
	if cur != "":
		pages.append(cur)
	if pages.is_empty():
		pages.append("")
	return pages
