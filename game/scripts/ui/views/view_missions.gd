class_name MissionsSheet
extends SheetCard
## The missions sheet (sim: Missions; opened from the stage's MissionsChip through MissionsUi.open).
## A §7.1 sheet card like the return card, laid out top to bottom:
##   title     MIS_TITLE "משימות" (the ✕ at the flap's left end; the backdrop, Esc and back close it)
##   the rank  MIS_RANK "דרגה {n}: {rankTitle}" centred, the rank's progress bar (claimed / missions of
##             the rank, filling from the right), MIS_NEXT "עוד {n} משימות לדרגת …" (muted) and
##             MIS_BONUS "בונוס הדרגה: +X% הכנסה" once a rank pays; at the last rank MIS_TOP
##   3 rows    the mission's text (×4, up to 2 lines, right), then a 64 band: on the right the progress
##             "12/25" over its bar, on the left the reward (gold) or, when done, the gold "לקחת"
##             button. All done: MIS_EMPTY.
## Live: the numbers and bars follow the game 4× a second; a mission finishing (or a claim) rebuilds
## the card in place (no re-drop). "לקחת" → MissionsUi.claim (the reward, the sound, a rank-up's
## celebration), then the rebuilt card shows the next mission in that row.

const ROW_GAP := 24.0
const BAND_H := 64.0
const BAR_H := 12.0
const RIGHT_W := 200.0       # the progress (x3) and its bar, x 440-640 (string box mis.progress)
const REWARD_W := 336.0      # the reward label, x 88-424 (mis.reward)
const PROGRESS_SCALE := 3
const BTN_W := 224.0
const C_TRACK := Color("#0f2350")
const C_FILL := Color("#ffd23a")
const C_FILL_GOAL := Color("#8fe052")

var _rows: Array = []        # [{i, value: PxText, fill: ColorRect, track: Rect2, done}]
var _sig := ""
var _tick := 0.0
var _rank_fill: ColorRect
var _rank_track := Rect2()


func build() -> MissionsSheet:
	id = "MISSIONS"
	_build_content()
	return self


func _state() -> GameState:
	return host.get("state") if host != null else null


func _d() -> Economy.Derived:
	var d: Variant = host.get("d") if host != null else null
	return d if d is Economy.Derived else Economy.derive(_state())


## The rows' identity: a change (a claim, a mission finishing) rebuilds the card.
func _signature(s: GameState) -> String:
	var parts := PackedStringArray([str(Missions.rank(s))])
	for sl: Dictionary in s.missions.get("slots", []):
		parts.append("%s:%s" % [sl.get("id", ""), "1" if sl.get("done", false) else "0"])
	return ",".join(parts)


func _build_content() -> void:
	var s := _state()
	_begin()
	close_x(func() -> void: cancel("close"))
	title(Strings.s("MIS_TITLE"))
	var rv := Missions.rank_view(s)
	var g2 := grow_half()
	para(Strings.s("MIS_RANK", {"n": str(int(rv["rank"])), "rankTitle": str(rv["title"])}), C_GOLD, true, 1)
	_y -= PARA_GAP - 8.0
	_rank_track = Rect2(88.0 - g2, _y, 544.0 + 2.0 * g2, BAR_H)
	Ui.rect(_holder, _rank_track, C_TRACK)
	_rank_fill = Ui.rect(_holder, _rank_track, C_FILL)
	_set_bar(_rank_fill, _rank_track, float(rv["frac"]))
	_y += BAR_H + 16.0
	if bool(rv["top"]) or str(rv["next"]) == "":
		para(Strings.s("MIS_TOP"), C_MUTED, true, 2)
	else:
		var left := int(rv["total"]) - int(rv["done"])
		para(Strings.plural("MIS_NEXT", left, {"n": str(left), "rankTitle": str(rv["next"]), "pct": str(int(rv["nextPct"]))}), C_MUTED, true, 2)
	if float(rv["incomePct"]) > 0.0:
		para(Strings.s("MIS_BONUS", {"pct": str(int(rv["incomePct"]))}), C_MUTED, true, 1)
	_rows.clear()
	var views := Missions.slots_view(s, _d())
	if views.is_empty():
		para(Strings.s("MIS_EMPTY"), C_TEXT, true, 2)
	var i := 0
	for v: Dictionary in views:
		_y += 8.0
		Ui.rect(_holder, Rect2(88.0 - g2, _y, 544.0 + 2.0 * g2, 4.0), C_MUTED, 0.25)
		_y += 4.0 + 12.0
		para(MissionsUi.text(Missions.mission(str(v["id"]))), C_TEXT, false, 2)
		_y -= PARA_GAP - 4.0
		_row_band(i, v, g2)
		_y += BAND_H + ROW_GAP
		i += 1
	_y -= ROW_GAP - 8.0
	finish()
	_sig = _signature(s)


## One row's band at the cursor: the progress (right) and the reward or "לקחת" (left).
func _row_band(i: int, v: Dictionary, g2: float) -> void:
	var s := _state()
	var right := TEXT_RIGHT + g2
	var done := bool(v["done"])
	var row := {"i": i, "done": done}
	var reward := MissionsUi.reward_text(s, Missions.mission(str(v["id"])).get("reward", {}), _d())
	# right: "12/25" (x3), or once done the reward (gold, x4, in the room the button leaves), over the bar
	var top := PxText.make(_holder, Vector2(0, _y + (0.0 if done else 8.0)), reward if done else MissionsUi.progress_text(v),
		L.TEXT if done else PROGRESS_SCALE, "plain", C_GOLD if done else C_TEXT)
	top.max_lines = 1
	top.fit_width = (right - (88.0 + BTN_W + 16.0)) if done else RIGHT_W
	top.right_at(right)
	row["value"] = top
	var track := Rect2(right - RIGHT_W, _y + BAND_H - BAR_H - 4.0, RIGHT_W, BAR_H)
	Ui.rect(_holder, track, C_TRACK)
	var fill := Ui.rect(_holder, track, C_FILL_GOAL if not done else C_FILL)
	_set_bar(fill, track, float(v["frac"]))
	row["fill"] = fill
	row["track"] = track
	# left: the reward (gold), or the claim button
	if done:
		_specs.append([Rect2(88, _y, BTN_W, BAND_H), Strings.s("MIS_CLAIM"), "kit_gold", func() -> void: _claim(i)])
	else:
		var rw := PxText.make(_holder, Vector2(88.0 - g2, _y + 12.0), reward, L.TEXT, "plain", C_GOLD)
		rw.max_lines = 1
		rw.fit_width = REWARD_W + g2
	_rows.append(row)


func _set_bar(fill: ColorRect, track: Rect2, frac: float) -> void:
	var w := Ui.snap(track.size.x * clampf(frac, 0.0, 1.0), 4)
	fill.size = Vector2(w, track.size.y)
	fill.position = Vector2(L.bar_x(track, w), track.position.y)   # RTL: fills from the right


func _claim(i: int) -> void:
	MissionsUi.claim(host, i)
	_rebuild()


## Lays the card out again in place (a claim, a mission finishing): the frame, texts and buttons are
## rebuilt at the new height; the open animation is not replayed.
func _rebuild() -> void:
	for c in panel.get_children():
		panel.remove_child(c)
		c.queue_free()
	_holder = Node2D.new()
	title_text = null
	paras.clear()
	buttons.clear()
	focusables.clear()
	flap_head.clear()
	_specs.clear()
	close_btn = null
	_build_content()
	focus_index = clampi(focus_index, 0, maxi(0, focusables.size() - 1))
	publish_web()


func on_opened() -> void:
	publish_web()


func cancel(via: String) -> void:
	host.call("audio_event", "panelClose")
	mgr.close(self, via)


func default_focus() -> int:
	return 0


## The claim buttons' centres, viewport logical px (window.odMissions for the browser check).
func claim_points() -> Array:
	var out: Array = []
	for b: PxButton in buttons:
		if b.label != null and b.label.text == Strings.s("MIS_CLAIM"):
			var c := to_view(b.visual.get_center() + Vector2(0, panel.position.y))
			out.append([c.x, c.y])
	return out


func update_view(dt_ms: float) -> void:
	if closing:
		return
	_tick += dt_ms
	if _tick < 250.0:
		return
	_tick = 0.0
	var s := _state()
	if s == null:
		return
	if _signature(s) != _sig:
		_rebuild()
		return
	var views := Missions.slots_view(s, _d())
	for row: Dictionary in _rows:
		var i := int(row["i"])
		if i >= views.size() or bool(row["done"]):
			continue
		var t := MissionsUi.progress_text(views[i])
		var pt: PxText = row["value"]
		if pt.text != t:
			pt.text = t
			pt.right_at(TEXT_RIGHT + grow_half())
		_set_bar(row["fill"], row["track"], float(views[i]["frac"]))
