class_name DossierView
extends Node2D
## T4 "תיקים": the dossier as a tall tab (ux/rtl-map.md §6.3 "T4", the same frame as T3's chat),
## plus the O15 pardon desk it opens (rtl-map §7.2, launch as text). A child of `_lower` at
## y = −S, so its local space is "tall-local": y 0 = the stage top, height H_T = S + 84 + P down
## to the tab bar. Rows A and B stay visible above it.
##
## It is a VIEW of the run's record: every number is read from GameState / Investigation /
## Economy.Derived (`rows()` is the pure model the tests pin). The only actions are the sim's:
## `Investigation.request_pardon` (the desk), `Investigation.drop_aide` (through the court view's
## stacked confirm), and the story archive / share cards through the controller.
##
## Layout, tall-local: the kit chat_header (DOS_TITLE right-aligned at x 616, the › chevron hit
## Rect2(632, 8, 88, 88)); under it one scrolling body: 88-px stat rows (labels right-aligned at
## x 688, a 4-px divider), the aide row while an aide holds money, the full-width buttons (hit
## 688×88) SHARE_RECEIPT_TITLE / SHARE_RESULT_BTN (O4 / O5, ui/views/view_share.gd) / PARDON_ROW /
## BOOK_STORY, then the BOOK_TROPHIES section (104-px rows: icon right, name, description).
##
## K2 (ux/ftue.md): the tab slot appears when the case is open (the thermometer revealed and the
## suspicion above 0, or any later round) and 5 s have passed since that became true in this
## session, with the toast TOAST_DOSSIER on that edge. Derived from the saved state, so a reload
## shows the slot at once and never re-toasts.

signal open_changed(open: bool)

const HEADER_H := 104.0
const BODY_Y := 104.0
const CHEVRON_HIT := Rect2(632, 8, 88, 88)
const TITLE_RIGHT := 616.0
const LABEL_RIGHT := 688.0
const ROW_H := 88.0
const BTN_PITCH := 96.0
const TROPHY_H := 104.0
const K2_DELAY_MS := 5000.0
const INPUT_AFTER_OPEN_MS := 140.0
const TEXT_REFRESH_MS := 250.0      # stat rows re-shape at most 4× a second (the total climbs every frame)

const C_BG := Color("#1e1636")      # ui_panel
const C_LABEL := Color.WHITE
const C_MUTED := Color("#7d8398")   # slate
const C_DIVIDER := Color("#2e2548")
const C_LOCKED := Color("#a4a9b8")  # grey

var host: Node
var reduced_motion := false

var _state: GameState
var _d: Economy.Derived
var _open := false
var _anim: Dictionary = {}
var _open_ms := 0.0
var _now := 0.0
var _h := 1102.0
var _vs_w := 720.0
var _ox := 0.0

var _panel := Node2D.new()
var _bg: ColorRect
var _header: NinePatchRect
var _chev: Sprite2D
var _title: PxText
var _clip := Control.new()
var _content := Node2D.new()
var _thumb: ColorRect

var _row_texts: Array[Dictionary] = []   # {key, text: PxText}
var _hits: Array[Dictionary] = []        # {rect (content-local), kind, button}
var _content_h := 0.0
var _sig := ""
var _scroll := 0.0
var _vel := 0.0
var _press: Dictionary = {}
var _text_ms := 0.0
var _last_pad := 0.0

# K2
var _ready_since := -1.0     # ms (view clock) when the case opened this session; -2 = ready at load
var _known_state: GameState


func setup(host_: Node) -> DossierView:
	host = host_
	return self


func _ready() -> void:
	add_child(_panel)
	_panel.visible = false
	_bg = Ui.rect(_panel, Rect2(0, 0, L.W, _h), C_BG)
	_clip.clip_contents = true
	_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_clip.position = Vector2(0, BODY_Y)
	_panel.add_child(_clip)
	_clip.add_child(_content)
	_thumb = Ui.rect(_panel, Rect2(4, BODY_Y, 4, 48), Color(0.84, 0.8, 0.93), 0.0)
	_header = Ui.nine(_panel, Rect2(0, 0, L.W, HEADER_H), Art.sprite_or("chat_header"))
	var chev_id := Art.sprite_or("chat_icon_chevron")
	var cs := Vector2(Art.sprite_size(chev_id)) * 4.0
	_chev = Ui.img(_panel, (CHEVRON_HIT.get_center() - cs / 2.0).snapped(Vector2(4, 4)), chev_id, 0, 4)
	_title = PxText.make(_panel, Vector2(0, 32), Strings.s("DOS_TITLE"), L.TEXT, "plain", "w")
	_title.wrap_width = 440.0
	_title.max_lines = 1
	_title.right_at(TITLE_RIGHT)
	relayout()


## The flex rule changed (MainController._relayout): H_T = S + 84 + P.
func relayout() -> void:
	position = Vector2(0, -L.stage_h)
	_h = L.stage_h + L.tabs_y()
	if host != null and "_ox" in host:
		_ox = float(host.get("_ox"))
		_vs_w = float((host.get("_vs") as Vector2).x)
	if _bg == null:
		return
	_bg.position = Vector2(-_ox - 8.0, 0)
	_bg.size = Vector2(_vs_w + 16.0, _h)
	_clip.size = Vector2(L.W, body_h())
	_set_scroll(_scroll)


func body_h() -> float:
	return maxf(0.0, _h - BODY_Y)


func is_open() -> bool:
	return _open


# ------------------------------------------------------------------ K2: the tab slot

## The case is open: the thermometer has been revealed (K1) and the suspicion is above 0, or the
## player has been through a round already (the flags persist per ux/ftue.md §1.1).
static func case_open(s: GameState) -> bool:
	if s == null or not Investigation.active():
		return false
	if s.evolutions >= 1:
		return true
	return bool(s.investigation.get("revealed", false)) and Investigation.suspicion(s) > 0.0


## Slot 4 shows (read by the controller's reveal pass every frame).
func tab_revealed() -> bool:
	return _ready_since == -2.0 or (_ready_since >= 0.0 and _now - _ready_since >= K2_DELAY_MS)


func _update_k2() -> void:
	if not case_open(_state):
		_ready_since = -1.0
		return
	if _ready_since == -1.0:
		_ready_since = _now
		return
	if _ready_since >= 0.0 and _now - _ready_since >= K2_DELAY_MS:
		_ready_since = -2.0
		if host != null and "toasts" in host and host.get("toasts") != null:
			(host.get("toasts") as Toasts).show_toast(LeaderUi.s("TOAST_DOSSIER"))   # press: PRESS_REVEAL


# ------------------------------------------------------------------ open / close (motion tall-tab)

func open() -> void:
	if _open:
		return
	_open = true
	_open_ms = _now
	_panel.visible = true
	_anim = {"kind": "open", "t": 0.0}
	_press = {}
	if case_open(_state):
		_ready_since = -2.0   # tapping the thermometer before K2 fired opens the case at once
	_audio("panelOpen")
	open_changed.emit(true)
	_sig = ""
	_rebuild_if_needed(true)
	_scroll = 0.0


func close() -> void:
	if not _open:
		return
	_open = false
	_press = {}
	_anim = {"kind": "close", "t": 0.0}
	_audio("panelClose")
	open_changed.emit(false)


func toggle() -> void:
	if _open:
		close()
	else:
		open()


func _animate_panel(dt: float) -> void:
	if _anim.is_empty():
		return
	_anim["t"] = float(_anim["t"]) + dt
	var t: float = _anim["t"]
	var opening: bool = _anim["kind"] == "open"
	if reduced_motion:
		var p := minf(1.0, t / ChatView.mc("tallTabOpenReducedMs" if opening else "tallTabCloseReducedMs"))
		_panel.position.y = 0.0
		_panel.modulate.a = p if opening else 1.0 - p
		if p >= 1.0:
			_end_anim(opening)
		return
	_panel.modulate.a = 1.0
	var p2 := minf(1.0, t / ChatView.mc("tallTabOpenMs" if opening else "tallTabCloseMs"))
	var e := Ui.cubic_out(p2) if opening else Ui.quad_in(p2)
	_panel.position.y = Ui.snap(_h * (1.0 - e if opening else e), 4)
	if p2 >= 1.0:
		_end_anim(opening)


func _end_anim(opening: bool) -> void:
	_anim = {}
	_panel.position.y = 0.0
	_panel.modulate.a = 1.0
	if not opening:
		_panel.visible = false


# ------------------------------------------------------------------ per frame

## ctx: {main: bool (main mode, no election transition)}.
func update_view(dt: float, s: GameState, d: Economy.Derived, ctx: Dictionary = {}) -> void:
	_now += dt
	if not is_same(s, _known_state):
		_known_state = s
		_ready_since = -2.0 if case_open(s) else -1.0   # a loaded / new state: no toast for an old case
		_sig = ""
	_state = s
	_d = d
	_animate_panel(dt)
	if _open and not bool(ctx.get("main", true)):
		close()
	_update_k2()
	if _panel.visible:
		_rebuild_if_needed(false)
		_text_ms += dt
		if _text_ms >= TEXT_REFRESH_MS:
			_text_ms = 0.0
			_refresh_texts()
		_update_scroll(dt)


# ------------------------------------------------------------------ the model (pure)

## The dossier's stat rows, in reading order: [{key, text}]. Every value is the sim's own counter
## (sim/README.md "Trophy stats" / "Thermometer"); the floor row shows only once a round has left
## suspicion behind.
static func rows(s: GameState, d: Economy.Derived) -> Array:
	var inv: Dictionary = s.investigation if s.investigation is Dictionary else {}
	var base_pct := maxf(0.0, ((d.prestige_mult if d != null else 1.0) - 1.0) * 100.0)
	var out: Array = [
		{"key": "DOS_ROUNDS", "text": Strings.s("DOS_ROUNDS", {"n": str(s.evolutions)})},
	]
	# the hazard's days (rtl-map §4.3): the court's in Bibi's round, the press's in everyone else's;
	# a lifetime row of the other skin shows only when > 0
	var court_n := int(inv.get("courtDays", 0))
	var press_n := int(inv.get("pressDays", 0))
	if LeaderUi.court() or court_n > 0:
		out.append({"key": "DOS_COURT_DAYS", "text": Strings.s("DOS_COURT_DAYS", {"n": str(court_n)})})
	if Strings.has("PRESS_DAYS") and (not LeaderUi.court() or press_n > 0):
		out.append({"key": "PRESS_DAYS", "text": Strings.s("PRESS_DAYS", {"n": str(press_n)})})
	out.append_array([
		{"key": "DOS_POSTPONES", "text": Strings.s("DOS_POSTPONES", {"n": str(int(inv.get("postponementsLifetime", 0)))})},
		{"key": "DOS_TOTAL", "text": Strings.s("DOS_TOTAL", {"x": Fmt.amount(s.all_time_bananas)})},
		{"key": "DOS_CAUGHT", "text": Strings.s("DOS_CAUGHT", {"n": str(s.golden_caught_lifetime)})},
		{"key": "DOS_ARRIVED", "text": Strings.s("DOS_ARRIVED", {"n": str(int(float(s.stats.get("goldenMissed", 0.0))))})},
		{"key": "DOS_BASE", "text": Strings.s("DOS_BASE", {"n": Fmt.thumbs(s.thumbs_owned), "pct": Fmt.amount(base_pct)})},
	])
	var fl := Investigation.floor_pct(s) if Investigation.active() else 0.0
	if fl > 0.0:
		out.append({"key": "DOS_SUSP_FLOOR", "text": LeaderUi.s("DOS_SUSP_FLOOR", {"pct": str(int(roundf(fl)))})})
	out.append_array(leader_rows(s))
	return out


## "ראשי רשימה" (spec §6.2, rtl-map §6.3): once a second leader has been played, one row per
## leader in first-played order (never sorted by a count: that is a ranking), the rounds in words,
## then their own taps and crits in the kit's nouns. [] before that, or without leader select.
static func leader_rows(s: GameState) -> Array:
	var out: Array = []
	if not Leaders.active() or not s.leaders is Dictionary:
		return out
	var played: Array = []
	for id: Variant in s.leaders:
		if Leaders.stat(s, str(id), "rounds") > 0.0 and Leaders.playable(str(id)):
			played.append(str(id))
	if played.size() < 2:
		return out
	out.append({"key": "DOS_LEADERS", "text": Strings.s("DOS_LEADERS")})
	for id: String in played:
		var n := int(Leaders.stat(s, id, "rounds"))
		out.append({"key": "DOS_LEADER_ROUNDS", "leader": id, "text": Strings.plural("DOS_LEADER_ROUNDS", n, {"short": LeaderUi.short(id)})})
		var t := LeaderUi.tap(id)
		out.append({"key": "DOS_LEADER_TAPS", "leader": id, "text": Strings.s("DOS_LEADER_TAPS", {"verbPlural": str(t["verbPlural"]),
			"n": str(int(Leaders.stat(s, id, "taps"))), "critPlural": str(t["critPlural"]), "c": str(int(Leaders.stat(s, id, "crits")))})})
	return out


## The full-width buttons, in order. The receipt (O4) and the result card (O5) show once the
## controller can open them.
func buttons() -> Array:
	var out: Array = []
	if host != null and host.has_method("open_receipt"):
		out.append({"kind": "receipt", "key": "SHARE_RECEIPT_TITLE"})
	if host != null and host.has_method("open_result_card"):
		out.append({"kind": "result", "key": "SHARE_RESULT_BTN"})
	if LeaderUi.court():   # Bibi-only: hidden, not disabled, in every other round (rtl-map §4.3)
		out.append({"kind": "pardon", "key": "PARDON_ROW"})
	out.append({"kind": "story", "key": "BOOK_STORY"})
	return out


# ------------------------------------------------------------------ build

func _signature() -> String:
	if _state == null:
		return ""
	return "%s%d|%d|%d|%s|%d|%s|%s" % [LeaderUi.id(), _state.leaders.size(), _state.evolutions, _state.achievements.size(),
		"A" if Investigation.can_drop_aide(_state) else "", buttons().size(),
		"F" if Investigation.floor_pct(_state) > 0.0 else "", "L" if PxText.large_text else ""]


func _rebuild_if_needed(force: bool) -> void:
	if _state == null:
		return
	var sig := _signature()
	if sig == _sig and not force:
		return
	_sig = sig
	_build()


func _build() -> void:
	for c in _content.get_children():
		c.queue_free()
		_content.remove_child(c)
	_row_texts.clear()
	_hits.clear()
	var y := 8.0
	for r: Dictionary in rows(_state, _d):
		var t := _text(_content, str(r["text"]), C_LABEL, 656.0, 1)
		t.right_at(LABEL_RIGHT)
		t.position.y = y + 24.0
		Ui.rect(_content, Rect2(32, y + ROW_H - 4.0, 656, 4), C_DIVIDER)
		_row_texts.append({"key": r["key"], "text": t})
		y += ROW_H
	if Investigation.can_drop_aide(_state):
		var ah := _text(_content, Strings.s("AIDE_HOLDS"), C_LOCKED, 656.0, 1)
		ah.right_at(LABEL_RIGHT)
		ah.position.y = y + 24.0
		y += ROW_H
		y = _add_button(y, "aide", Strings.s("AIDE_BTN"), "kit_primary")
	y += 16.0
	for b: Dictionary in buttons():
		y = _add_button(y, str(b["kind"]), Strings.s(str(b["key"])), "kit_secondary")
	y += 24.0
	# the trophies section (BOOK_TROPHIES): the fork's Troop Book list in the dossier's frame
	var hd := _text(_content, Strings.s("BOOK_TROPHIES"), C_LABEL, 656.0, 1)
	hd.right_at(LABEL_RIGHT)
	hd.position.y = y + 8.0
	var n := Meta.trophy_count(_state)
	var pct := Meta.achievement_pct(_state) * n * 100.0
	var sm := _text(_content, Strings.s("TROPHY_SUMMARY", {"n": n, "total": Meta.achievements().size(), "pct": Fmt.mult(pct).trim_suffix(".0")}), C_MUTED, 656.0, 1)
	sm.right_at(LABEL_RIGHT)
	sm.position.y = y + 52.0
	y += ROW_H + 8.0
	for a: Dictionary in Meta.achievements():
		y = _add_trophy(y, a)   # neverAwarded ones (a_gantz) stay listed: that is their joke
	_content_h = y + 24.0


func _add_button(y: float, kind: String, label: String, look: String) -> float:
	var vis := Rect2(16, y + 4.0, 688, 80)
	var btn := PxButton.make(_content, vis, {"hit": Rect2(16, y, 688, 88), "label": label, "kind": look})
	if btn.label != null:
		btn.label.wrap_width = 624.0
		btn.label.max_lines = 1
		btn.label.center_in(vis.position.x, vis.size.x)
	_hits.append({"rect": Rect2(16, y, 688, 88), "kind": kind, "button": btn})
	return y + BTN_PITCH


## The 2D Artist's trophy art for an achievement: [plate, icon] (kit `trophy_plate_*` 21×21 with
## the 15×15 `trophy_<name>` / `trophy_<name>_locked` at (3, 3); a secret one shows only
## trophy_plate_secret until earned). The content names icons `icon_<name>`; an id the kit lacks
## draws as itself (or the neutral card).
static func trophy_art(a: Dictionary, got: bool) -> Array:
	var secret: bool = a.get("secret", false)
	if secret and not got:
		return [Art.sprite_or("trophy_plate_secret"), ""]
	var raw := str(a.get("icon", ""))
	var name := raw.trim_prefix("icon_")
	var icon := "trophy_" + name + ("" if got else "_locked")
	if not Art.has_sprite(icon):
		icon = Art.sprite_or(raw)
	return [Art.sprite_or("trophy_plate_earned" if got else "trophy_plate_locked"), icon]


func _add_trophy(y: float, a: Dictionary) -> float:
	var got := _state.achievements.has(a["id"])
	var secret: bool = a.get("secret", false)
	var shown := got or not secret
	var art := trophy_art(a, got)
	var plate_x := LABEL_RIGHT - 84.0
	Ui.img(_content, Vector2(plate_x, y + 10.0), art[0], 0, 4)
	if str(art[1]) != "":
		Ui.img(_content, Vector2(plate_x + 12.0, y + 22.0), art[1], 0, 4)
	var nm := _text(_content, str(a["name"]) if shown else Strings.s("TROPHY_LOCKED"), C_LABEL if got else C_LOCKED, 556.0, 1)
	nm.right_at(plate_x - 16.0)
	nm.position.y = y + 12.0
	var ds := _text(_content, str(a["desc"]) if shown else Strings.s("TROPHY_SECRET"), C_MUTED, 556.0, 1)
	ds.right_at(plate_x - 16.0)
	ds.position.y = y + 56.0
	Ui.rect(_content, Rect2(32, y + TROPHY_H - 4.0, 656, 4), C_DIVIDER)
	return y + TROPHY_H


func _text(parent: Node, s: String, col: Variant, wrap: float, lines: int) -> PxText:
	var t := PxText.make(parent, Vector2.ZERO, s, L.TEXT, "plain", col)
	t.max_lines = lines
	t.wrap_width = wrap
	return t


func _refresh_texts() -> void:
	if _state == null:
		return
	var model := rows(_state, _d)
	for i in mini(model.size(), _row_texts.size()):
		var t: PxText = _row_texts[i]["text"]
		var txt := str(model[i]["text"])
		if t.text != txt:
			t.text = txt
			t.right_at(LABEL_RIGHT)


## Test / tool hook: the stat rows as drawn, [{key, text}].
func drawn_rows() -> Array:
	_refresh_texts()
	return _row_texts.map(func(r: Dictionary) -> Dictionary: return {"key": r["key"], "text": (r["text"] as PxText).text})


func hits() -> Array[Dictionary]:
	return _hits


func content_to_tall(c: Vector2) -> Vector2:
	return Vector2(c.x, c.y + BODY_Y + _content.position.y)


# ------------------------------------------------------------------ actions

func act(kind: String) -> void:
	match kind:
		"pardon":
			open_pardon_desk()
		"story":
			_open_story()
		"aide":
			if host != null and "court" in host and host.get("court") != null:
				(host.get("court") as CourtView).confirm_aide_drop()
		"receipt":
			host.call("open_receipt")
		"result":
			host.call("open_result_card")


## O15: the pardon desk, a modal over T4 through the overlay stack.
func open_pardon_desk() -> void:
	if host == null or not "overlays" in host:
		return
	var mgr: OverlayManager = host.get("overlays")
	if mgr == null or mgr.is_open():
		return
	_audio("panelOpen")
	mgr.request(func() -> Overlay:
		var o := PardonDesk.new()
		o.setup(host, mgr)
		return o.build())


## The story archive (rtl-map §7.2: the Dubi flashes, re-read from T4): the fork's book on its
## story page.
func _open_story() -> void:
	if host == null or not "overlays" in host:
		return
	var mgr: OverlayManager = host.get("overlays")
	if mgr == null or mgr.is_open():
		return
	_audio("panelOpen")
	mgr.request(func() -> Overlay:
		var o := Overlays.BookOverlay.new()
		o.setup(host, mgr)
		o.tab = "story"
		return o.build())


func _audio(name: String, arg: Variant = null) -> void:
	if host != null and host.has_method("audio_event"):
		host.call("audio_event", name, arg)


# ------------------------------------------------------------------ scroll

func _max_scroll() -> float:
	return maxf(0.0, _content_h + bottom_pad() - body_h())


## rtl-map §6.4 "Depth" (review R21): the expanded court card over T4 pads the list's bottom by
## its height, so the last trophies scroll clear of it.
func bottom_pad() -> float:
	var c := CourtView.of(host)
	return c.pad_height() if c != null and _open else 0.0


func _set_scroll(v: float) -> void:
	_scroll = clampf(v, 0.0, _max_scroll())


func _update_scroll(dt: float) -> void:
	if _press.is_empty() and _vel != 0.0:
		_set_scroll(_scroll + _vel * (dt / Tune.FRAME_MS))
		_vel *= pow(float(Tune.MC.get("listMomentumDecay", 0.92)), dt / Tune.FRAME_MS)
		if absf(_vel) < float(Tune.MC.get("listMomentumStop", 0.1)):
			_vel = 0.0
	var pad := bottom_pad()
	if pad != _last_pad:
		_last_pad = pad
		_set_scroll(_scroll)
	_content.position.y = Ui.snap(-_scroll, 4)
	var th := body_h()
	var scrollable := _content_h + pad > th
	_thumb.visible = scrollable
	if scrollable:
		var tl := maxf(48.0, th * th / (_content_h + pad))
		_thumb.size.y = Ui.snap(tl, 4)
		_thumb.position.y = Ui.snap(BODY_Y + (th - tl) * (_scroll / maxf(1.0, _max_scroll())), 4)
		var dragging: bool = not _press.is_empty() and _press.get("dragging", false)
		_thumb.modulate.a = 1.0 if (dragging or _vel != 0.0) else 0.35


func wheel(dy: float) -> void:
	_set_scroll(_scroll + signf(dy) * float(Tune.MC.get("wheelNotchPx", 104)))


# ------------------------------------------------------------------ input (`_lower`-local points)

func _tall(p: Vector2) -> Vector2:
	return p - position - (_panel.position if _open else Vector2.ZERO)


func _content_pt(q: Vector2) -> Vector2:
	if q.y < BODY_Y or q.y >= BODY_Y + body_h():
		return Vector2(-1, -1)
	return Vector2(q.x, q.y - BODY_Y - _content.position.y)


## True when the dossier takes this press (anywhere on the open tab: it covers the stage).
func pointer_down(p: Vector2) -> bool:
	if not _open:
		return false
	var q := _tall(p)
	if q.y < 0.0 or q.y >= _h:
		return false
	_vel = 0.0
	_press = {"kind": "body", "y0": q.y, "x0": q.x, "scroll0": _scroll, "dragging": false, "lastT": _now, "vel": 0.0, "hit": {}}
	if Ui.in_rect(CHEVRON_HIT, q):
		_press["kind"] = "chevron"
		return true
	var c := _content_pt(q)
	if c.y < 0.0 or _now - _open_ms < INPUT_AFTER_OPEN_MS:
		return true
	for h: Dictionary in _hits:
		if Ui.in_rect(h["rect"], c):
			_press["hit"] = h
			(h["button"] as PxButton).down()
			break
	return true


func pointer_move(p: Vector2) -> void:
	if _press.is_empty() or _press["kind"] != "body":
		return
	var q := _tall(p)
	var dt := maxf(1.0, _now - float(_press["lastT"]))
	if not _press["dragging"] and q.distance_to(Vector2(_press["x0"], _press["y0"])) > float(L.SHOP["moveCancelPx"]):
		_press["dragging"] = true
		var h: Dictionary = _press["hit"]
		if not h.is_empty():
			(h["button"] as PxButton).cancel()
			_press["hit"] = {}
	if _press["dragging"]:
		var s0 := _scroll
		_set_scroll(float(_press["scroll0"]) - (q.y - float(_press["y0"])))
		_press["vel"] = (_scroll - s0) / (dt / Tune.FRAME_MS)
	_press["lastT"] = _now


func pointer_up(p: Vector2) -> void:
	var pr := _press
	_press = {}
	if pr.is_empty():
		return
	var q := _tall(p)
	match String(pr["kind"]):
		"chevron":
			if Ui.in_rect(CHEVRON_HIT, q):
				close()
		"body":
			if pr["dragging"]:
				_vel = float(pr["vel"]) if absf(float(pr["vel"])) > float(Tune.MC.get("listMomentumStop", 0.1)) else 0.0
				return
			var h: Dictionary = pr["hit"]
			if h.is_empty():
				return
			var inside := Ui.in_rect(h["rect"], _content_pt(q))
			(h["button"] as PxButton).up(inside)
			if inside:
				_audio("uiClick")
				act(str(h["kind"]))


# =============================================================================================
# O15 the pardon desk (rtl-map §7.2, copy deck §H "stamp lines"): a modal. "להגיש בקשה" files a
# request through Investigation.request_pardon; the answer is a rubber stamp (motion stamp-slam,
# identical every time: the sameness is the joke). Line 1 is the 2D Artist's baked stamp_pardon;
# the others are content copy (court.pardon.copy.stamps) in stamp ink inside stamp_frame_*.
# The `stamp` cue lands on the impact (+90 ms; f0 under reduced motion); the Audio adds the bell
# on every 5th.
# =============================================================================================

class PardonDesk:
	extends Overlay
	## The desk is a paper modal: the kit's `_paper` stamps and the `stamp` ink (style guide §2:
	## #5b3b9e, 5.6:1 on paper; the `_dark` / stamp_lt pair is for dark surfaces).
	const STAMP_INK := Color("#5b3b9e")
	const WELL_H := 200.0
	var _form: PxText
	var _count: PxText
	var _submit: PxButton
	var _stamp_root := Node2D.new()
	var _stamp_img: Sprite2D
	var _stamp_frame: NinePatchRect
	var _stamp_text: PxText
	var _stamp_center := Vector2.ZERO
	var _slam_t := -1.0
	var _cue_due := false
	var line := 0              # the last stamp line shown (1-based), 0 = none yet
	var _specks: Array = []

	func build() -> PardonDesk:
		id = "PARDON"
		var th := Art.theme
		var s: GameState = host.state
		# measure first (the card grows vertically with its text: ×4, or ×5 in large text)
		var lh := float(HeFont.line_height()) * float(L.TEXT) * (1.25 if PxText.large_text else 1.0)
		var note_probe := PxText.make(panel, Vector2.ZERO, Strings.s("PARDON_NOTE"), L.TEXT, "plain", "w")
		note_probe.wrap_width = 560.0
		note_probe.max_lines = 3
		var note_lines := maxf(1.0, float(note_probe.line_count()))
		note_probe.queue_free()
		var h := Ui.snap(104.0 + 2.0 * lh + 8.0 + lh + 16.0 + WELL_H + 16.0 + lh + 8.0 + note_lines * lh + 24.0 + 96.0 + 16.0 + 96.0 + 24.0, 4)
		var y := Ui.snap((L.H - h) / 2.0, 4)
		var pr := Rect2(48, y, 624, h)
		make_panel(pr)
		var close := close_button(Rect2(pr.position.x + 16, pr.position.y + 16, 64, 64), Rect2(pr.position.x, pr.position.y, 104, 104), func() -> void: cancel("close"))
		var title := text(Vector2(0, y + 32.0), Strings.s("PARDON_TITLE"), L.TEXT, th["modal"]["title"])
		title.wrap_width = 432.0
		title.max_lines = 1
		title.center_in(pr.position.x + 96.0, 432.0)
		var cy := y + 104.0
		_form = text(Vector2(0, cy), "", L.TEXT, th["modal"]["body"])
		_form.wrap_width = 560.0
		_form.max_lines = 2
		cy += 2.0 * lh + 8.0
		var st := text(Vector2(0, cy), Strings.s("PARDON_STATUS"), L.TEXT, th["modal"]["note"])
		st.wrap_width = 560.0
		st.max_lines = 1
		st.right_at(pr.end.x - 32.0)
		cy += lh + 16.0
		# the stamp well
		_stamp_center = Vector2(360, Ui.snap(cy + WELL_H / 2.0, 4))
		cy += WELL_H + 16.0
		panel.add_child(_stamp_root)
		_stamp_root.position = _stamp_center
		var sid := Art.sprite_or("stamp_pardon_paper_rot" if Art.has_sprite("stamp_pardon_paper_rot") else "stamp_pardon_paper")
		_stamp_img = Ui.img(_stamp_root, Vector2.ZERO, sid, 0, 4)
		_stamp_img.centered = true
		_stamp_img.visible = false
		var fid := Art.sprite_or("stamp_frame_paper")
		_stamp_frame = Ui.nine(_stamp_root, Rect2(-264, -80, 528, 160), fid)
		if String(Art.kit(fid).get("mode", "")) == "tile":
			_stamp_frame.axis_stretch_horizontal = NinePatchRect.AXIS_STRETCH_MODE_TILE_FIT
			_stamp_frame.axis_stretch_vertical = NinePatchRect.AXIS_STRETCH_MODE_TILE_FIT
		_stamp_frame.visible = false
		_stamp_text = PxText.make(_stamp_root, Vector2(-240, -60), "", L.TEXT, "plain", STAMP_INK)
		_stamp_text.wrap_width = 480.0
		_stamp_text.max_lines = 3
		_stamp_text.visible = false
		_count = text(Vector2(0, cy), "", L.TEXT, th["modal"]["note"])
		_count.wrap_width = 560.0
		_count.max_lines = 1
		cy += lh + 8.0
		var note := text(Vector2(0, cy), Strings.s("PARDON_NOTE"), L.TEXT, th["modal"]["note"])
		note.wrap_width = 560.0
		note.max_lines = 3
		note.right_at(pr.end.x - 32.0)
		var by := pr.end.y - 24.0 - 96.0 - 16.0 - 96.0
		_submit = button(Rect2(88, by, 544, 96), Rect2(88, by - 4.0, 544, 104), Strings.s("PARDON_SUBMIT"),
			func() -> void: submit(), "kit_primary", L.TEXT)
		button(Rect2(88, by + 112.0, 544, 96), Rect2(88, by + 108.0, 544, 104), Strings.s("SYS_CLOSE"),
			func() -> void: cancel("close"), "kit_secondary", L.TEXT)
		focusables.append(close)
		_sync(s)
		return self

	func _sync(s: GameState) -> void:
		var pardons := int(s.investigation.get("pardons", 0))
		_form.text = Strings.s("PARDON_FORM", {"n": str(pardons + 1)})
		_form.right_at(panel_rect.end.x - 32.0)
		_count.text = "" if pardons <= 0 else Strings.plural("PARDON_COUNT", pardons, {"n": str(pardons)})
		_count.right_at(panel_rect.end.x - 32.0)

	## The stamp line's text (content copy; the sim holds no Hebrew).
	static func stamp_line(k: int) -> String:
		var st: Array = Investigation.cfg().get("pardon", {}).get("copy", {}).get("stamps", [])
		return str(st[k - 1]) if k >= 1 and k <= st.size() else ""

	## "להגיש בקשה" / "להגיש שוב": files the request, then the stamp slams.
	func submit() -> int:
		var s: GameState = host.state
		line = Investigation.request_pardon(s)
		var baked := line == 1 and Art.has_sprite("stamp_pardon_paper")
		_stamp_img.visible = baked
		_stamp_frame.visible = not baked
		_stamp_text.visible = not baked
		if not baked:
			_stamp_text.text = stamp_line(line)
			_stamp_text.align = 1
			_stamp_text.h_anchor = 0
			_stamp_text.center_in(-240.0, 480.0)
			var lines := maxf(1.0, float(_stamp_text.line_count()))
			var th := Ui.snap(float(HeFont.line_height()) * _stamp_text.eff_px() * lines + 48.0, 4)
			Ui.set_nine_rect(_stamp_frame, Rect2(-264, -th / 2.0, 528, th))
			_stamp_text.position.y = -th / 2.0 + 24.0
		_submit.set_label(Strings.s("PARDON_AGAIN"))
		_sync(s)
		if host.has_method("_mark_dirty"):
			host.call("_mark_dirty")
		_slam_t = 0.0
		_cue_due = true
		if mgr.reduced:
			_stamp_root.scale = Vector2.ONE
			_land()
		return line

	## The impact frame: the stamp cue, the 1-ap jolt, 4 ink specks (none under reduced motion).
	func _land() -> void:
		if not _cue_due:
			return
		_cue_due = false
		host.audio_event("stamp")
		if mgr.reduced:
			return
		for n: Node in _specks:
			n.queue_free()
		_specks.clear()
		for i in 4:
			var sp := Ui.rect(panel, Rect2(0, 0, 4, 4), STAMP_INK)
			_specks.append(sp)

	func update_view(dt_ms: float) -> void:
		if _slam_t < 0.0:
			return
		_slam_t += dt_ms
		if not mgr.reduced:
			var t := _slam_t
			var sc := 1.5 if t < 33.0 else (1.25 if t < 67.0 else 1.0)   # s+2 → s+1 → s at ×4
			_stamp_root.scale = Vector2(sc, sc)
			_stamp_root.modulate.a = 0.6 if t < 33.0 else 1.0
			if t >= 90.0:
				_land()
			panel.position.y = 4.0 if (t >= 90.0 and t < 90.0 + 2.0 * Tune.FRAME_MS) else 0.0
			var st := clampf((t - 90.0) / 150.0, 0.0, 1.0)
			var dirs := [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]
			for i in _specks.size():
				var sp: ColorRect = _specks[i]
				var off := Vector2(dirs[i]) * Ui.snap(4.0 * (3.0 + 2.0 * Ui.quad_out(st)), 4)
				sp.position = (_stamp_center + Vector2(dirs[i]) * Vector2(200, 60) + off).snapped(Vector2(4, 4))
				sp.modulate.a = 1.0 - st
			if t > 400.0:
				_slam_t = -1.0
				_stamp_root.scale = Vector2.ONE
				_stamp_root.modulate.a = 1.0
				panel.position.y = 0.0
		else:
			_slam_t = -1.0

	func cancel(via: String) -> void:
		host.audio_event("panelClose")
		mgr.close(self, via)
