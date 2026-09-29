class_name Shop
extends Node2D
## The card panel and the tab bar (ux/rtl-map.md §6), `_lower`-local: the list sits at y 84 with
## height P (the flex rule), the tab bar under it. RTL cards: plate and icon on the right, the name
## right-aligned beside it, line 2 (yield) under it, the owned count at the left end of line 2, the
## price pill on the left. The WHOLE card is the buy target (first-minute §3.1): commit on release,
## a move beyond moveCancelPx makes the press a scroll. Hold a source card to repeat-buy.
## The pill (R5): verb over price; affordable = the kit's gold pill; unaffordable = the sunken well
## with a dim fill growing from the right as the treasury approaches the price.
## Tabs (rtl-map §6.2): four fixed slots, reading order right → left (מקורות, ספינים, קואליציה,
## תיקים); each appears when its reveal fires (ux/ftue.md §3) and never moves. The coalition and
## dossier tabs are tall tabs: their slot emits tall_tab_requested (the controller opens the view);
## the dossier slot stays empty until its view exists.
## Juice kept from the fork: press squish, pill hello and nudge, glint, can't-afford shake,
## success flash, icon hop and cascade, the upgrade shelf reflow, momentum scroll.

signal buy_producer_requested(id: String, is_repeat: bool, result: Array)
signal buy_upgrade_requested(id: String, result: Array)
signal cant_afford
signal cycle_mode
signal tab_switched(tab: String)
signal became_affordable
signal producer_revealed
signal list_interaction
## A tall tab's slot was chosen (T3 "coalition"; T4 later): the controller opens that view.
signal tall_tab_requested(tab: String)

const TABS := ["producers", "upgrades", "coalition", "dossier"]
const TAB_KEYS := ["TAB_SOURCES", "TAB_SPINS", "TAB_COALITION", "TAB_DOSSIER"]
const TAB_ICONS := ["tabicon_sources", "tabicon_spins", "tabicon_coalition", "tabicon_cases"]
## T3 (the coalition chat, ui/views/view_chat.gd) is built; T4 (dossier) is not yet, so its slot
## stays hidden even when revealed.
const TAB_BUILT := [true, true, true, false]
const TALL_TABS := ["coalition", "dossier"]
## S08 "השלט" (karhiLine): its two bars live on the card only. One 2-art-px split track under
## line 2 (card-local): "שידור ציבורי" fills from the right, "ערוץ ידידותי" takes the rest. The
## labels wait for UX keys (STATUS request); the palette letters are the art.json palette.
const SPIN_BARS := Rect2(220, 104, 360, 8)
## The spin tag's stamp: the bottom band of the plate (kit card_plate at 588-692 × 8-112).
const SPIN_TAG := Rect2(592, 72, 96, 40)
const SPIN_BAR_PUBLIC := "e"
const SPIN_BAR_FRIENDLY := "O"

var tab := "producers"
## The tall tab currently open over the panel ("" = none): its slot shows as the active one.
var tall := ""
var reduced_motion := false
var nudge_blocked: Callable    # func() -> bool
var list_rect: Rect2
## ux/ftue.md: while true (the first run, before the first buy) the pill of an unaffordable card
## stays at 40% opacity.
var ftue_dim := false
## The first card before the first buy (first-minute §2.2): only the first source, named.
var ftue_single := false

var _tabs_on := false
var _slot_on := [true, false, false, false]
var _tabbar: NinePatchRect
var _slots: Array[Dictionary] = []
var _tab_pressed := -1
var _thumb: ColorRect
var _clip := Control.new()
var _lists := {}
var _rows := {"producers": [], "upgrades": []}
var _empty: Array[PxText] = []
var _scroll := {"producers": 0.0, "upgrades": 0.0}
var _max_for := {"producers": 0.0, "upgrades": 0.0}
var _vel := 0.0
var _scroll_tw: Tween
var _press: Dictionary = {}
var _last_interaction := -1e9
var _thumb_active_at := -1e9
var _revealed_count := -1
var _frozen_upgrades: Array = []
var _reflow_offset := 0.0
var _reflow_from := -1
var _tab_anim: Dictionary = {}
var _last_cascade := -1e9
var _nudge_t := 0.0
var _nudge_cursor := -1
var _now := 0.0
var _visible_shop := true
var _state: GameState

# juice tables
var SQ := 8.0
var PILL_REBOUND: Array
var ICON_NUDGE: Array
var PILL_HELLO: Array
var TAB_IN: Array
var PILL_RECT: Rect2


func _ready() -> void:
	var th := Art.theme
	var R: Dictionary = L.ROW
	SQ = float(Tune.MC["squishPx"])
	var hop := float(Tune.MC["cascadeHopPx"])
	PILL_REBOUND = [SQ, SQ]
	ICON_NUDGE = [-hop, -hop, -hop, 0.0]
	PILL_HELLO = [[-SQ / 2, 0, 0], [-SQ, 0, 0], [-SQ, 0, 0], [-SQ, 0, 0], [-SQ / 2, 0, 0],
		[0, SQ, -SQ], [0, SQ, -SQ], [-SQ / 2, 0, 0], [0, 0, 0], [0, 0, 0]]
	var O := float(Tune.MC["tabSwitchOffsetPx"])
	var V := float(Tune.MC["tabListOvershootPx"])
	TAB_IN = [O, O * 3 / 4, O / 2, O / 4, 0.0, -V, -V, -V, 0.0]
	PILL_RECT = R["pill"]
	_thumb = Ui.rect(self, Rect2(float(L.SHOP["scrollTrackX"]), float(L.SHOP["listY"]), 4, 48), th["shop"]["scrollThumb"])
	_clip.clip_contents = true
	_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_clip)
	for t in ["producers", "upgrades"]:
		var n := Node2D.new()
		_clip.add_child(n)
		_lists[t] = n
		var count := Content.producers().size() + 2 if t == "producers" else Content.upgrades().size()
		for k in count:
			(_rows[t] as Array).append(_make_row(n, k))
	var up: Node2D = _lists["upgrades"]
	var e1 := PxText.make(up, Vector2(0, 0), Strings.s("UPG_EMPTY_1"), L.TEXT, "plain", th["shop"]["emptyText"])
	var e2 := PxText.make(up, Vector2(0, 0), Strings.s("UPG_EMPTY_2"), L.TEXT, "plain", th["shop"]["emptyText"])
	_empty = [e1, e2]
	up.visible = false
	_build_tabs()
	set_list_height(L.panel_h)


func _build_tabs() -> void:
	_tabbar = Ui.nine(self, Rect2(0, 0, L.W, L.TABS_H), Art.sprite_or("tabbar"))
	for i in 4:
		var d := {}
		d["plate"] = Ui.nine(self, Rect2(0, 0, 180, L.TABS_H), Art.sprite_or("tab_active"))
		d["icon"] = Ui.img(self, Vector2.ZERO, Art.sprite_or(TAB_ICONS[i] + "_idle"), 0, 4)
		d["label"] = PxText.make(self, Vector2.ZERO, Strings.s(TAB_KEYS[i]), L.TEXT, "plain", "w")
		d["badge"] = Ui.nine(self, Rect2(0, 0, 44, 44), Art.sprite_or("badge_count"))
		d["badgeText"] = PxText.make(self, Vector2.ZERO, "", L.TEXT, "plain", "w")
		_slots.append(d)
	_layout_tabs()


func _layout_tabs() -> void:
	var y := L.tabs_y()
	Ui.set_nine_rect(_tabbar, Rect2(0, y, L.W, L.TABS_H))
	for i in 4:
		var d: Dictionary = _slots[i]
		var r := L.tab_rect(i + 1)
		Ui.set_nine_rect(d["plate"], Rect2(r.position.x + 12, y, 156, L.TABS_H))
		var ic: Sprite2D = d["icon"]
		ic.position = r.position + Vector2(60, 4)
		var lb: PxText = d["label"]
		lb.position.y = y + 60
		lb.center_in(r.position.x, r.size.x)
		Ui.set_nine_rect(d["badge"], Rect2(r.position.x + 44, y, 44, 44))
		(d["badgeText"] as PxText).position = Vector2(r.position.x + 44, y + 4)
	_refresh_tabs()


## ux/ftue.md: the bar appears at C1; each slot at its own reveal. Slots never move.
func set_tabs_revealed(bar: bool, slots: Array) -> void:
	_tabs_on = bar
	for i in 4:
		_slot_on[i] = bool(slots[i]) if i < slots.size() else false
	_refresh_tabs()


func _slot_shown(i: int) -> bool:
	return _visible_shop and _tabs_on and bool(_slot_on[i]) and bool(TAB_BUILT[i])


func _refresh_tabs() -> void:
	_tabbar.visible = _visible_shop and _tabs_on
	for i in 4:
		var d: Dictionary = _slots[i]
		var on := _slot_shown(i)
		var active: bool = on and (TABS[i] == tall if tall != "" else TABS[i] == tab)
		(d["plate"] as NinePatchRect).visible = active
		var ic: Sprite2D = d["icon"]
		ic.visible = on
		Ui.set_frame(ic, Art.sprite_or(TAB_ICONS[i] + ("_active" if active else "_idle")), 0)
		var lb: PxText = d["label"]
		lb.visible = on
		lb.tint = Art.col("w") if active else Color(0.62, 0.6, 0.68)
		(d["badge"] as NinePatchRect).visible = on and (d["badgeText"] as PxText).text != ""
		(d["badgeText"] as PxText).visible = (d["badge"] as NinePatchRect).visible


## The badge count on a slot ("" hides it).
func set_tab_badge(slot: int, text: String) -> void:
	var d: Dictionary = _slots[slot - 1]
	var bt: PxText = d["badgeText"]
	if bt.text == text:
		return
	bt.text = text
	bt.center_in(L.tab_rect(slot).position.x + 44, 44)
	_refresh_tabs()


## The list grows with P (the flex rule); the tab bar follows it.
func set_list_height(h: float) -> void:
	list_rect = Rect2(float(L.SHOP["listX"]), float(L.SHOP["listY"]), float(L.SHOP["listW"]), h)
	_clip.position = list_rect.position
	_clip.size = list_rect.size
	for t: String in _lists:
		(_lists[t] as Node2D).position = -list_rect.position
	for i in _empty.size():
		var e := _empty[i]
		e.position.y = list_rect.position.y + 96.0 + 36.0 * i
		e.center_in(list_rect.position.x, list_rect.size.x)
	if _tabbar:
		_layout_tabs()


func _make_row(list: Node2D, k: int) -> Dictionary:
	var th := Art.theme
	var R: Dictionary = L.ROW
	var S: Dictionary = L.SHOP
	var c := Node2D.new()
	c.position.y = float(S["listY"]) + float(S["rowVisualTop"]) + float(S["rowPitch"]) * k
	list.add_child(c)
	var row_h := float(S["rowVisualH"])
	var lx := float(S["listX"])
	var lw := float(S["listW"])
	var panel := Ui.nine(c, Rect2(lx, 0, lw, row_h), Art.sprite_or("card_source_affordable"))
	var content := Node2D.new()
	c.add_child(content)
	var plate := Ui.nine(content, R["plate"], Art.sprite_or("card_plate"))
	var icon := Ui.img(content, Vector2.ZERO, Art.PLACEHOLDER, 0, 4)
	var icon_flash := Sprite2D.new()
	icon_flash.centered = false
	icon_flash.scale = Vector2(4, 4)
	icon_flash.visible = false
	icon_flash.material = Ui.fill_material(Art.col(th["row"]["affordFlash"]))
	content.add_child(icon_flash)
	var name := PxText.make(content, Vector2(float(R["nameRight"]), float(R["nameY"])), "", L.TEXT, "plain", "w")
	var line2 := PxText.make(content, Vector2(float(R["line2Right"]), float(R["line2Y"])), "", L.TEXT, "plain", "w")
	for t: PxText in [name, line2]:
		t.max_lines = 1
		t.h_anchor = 2
	name.wrap_width = float(R["nameW"])
	line2.wrap_width = float(R["line2W"])
	var owned := PxText.make(content, Vector2(float(R["ownedX"]), float(R["ownedY"])), "", L.TEXT, "plain", "w")
	var pill := Ui.nine(content, PILL_RECT, Art.sprite_or("pay_pill_default"))
	var fill := Ui.nine(content, Rect2(PILL_RECT.end.x - 16, PILL_RECT.position.y + 8, 8, PILL_RECT.size.y - 24), Art.sprite_or("pay_pill_fill"))
	var pill1 := PxText.make(content, Vector2(PILL_RECT.position.x, float(R["pillLine1Y"])), "", L.TEXT, "plain", "w")
	var pill2 := PxText.make(content, Vector2(PILL_RECT.position.x, float(R["pillLine2Y"])), "", L.TEXT, "plain", "w")
	var flash := Ui.rect(c, Rect2(lx, 0, lw, row_h), th["row"]["affordFlash"], 0.0)
	var dim := Ui.fade_rect(c, Rect2(lx, 0, lw, row_h), th["scrim"])
	var glint := Ui.rect(c, Rect2(lx, 4, 8, row_h - 8), th["row"]["affordFlash"], 0.0)
	# S08's card-only bars (Spins.card bars): one split track under line 2, "public" from the right
	var sb: Rect2 = SPIN_BARS
	# a spin's tag ("שחוק", a line's "1/5"): a stamp over the plate's bottom edge (rtl-map §6.1)
	var tag_bg := Ui.rect(content, SPIN_TAG, th["scrim"], 0.85)
	var tag := PxText.make(content, Vector2(SPIN_TAG.position.x, SPIN_TAG.position.y + 2.0), "", L.TEXT, "plain", "w")
	tag_bg.visible = false
	tag.visible = false
	var bar_pub := Ui.rect(content, sb, Art.col(SPIN_BAR_PUBLIC))
	var bar_fr := Ui.rect(content, Rect2(sb.position, Vector2(0, sb.size.y)), Art.col(SPIN_BAR_FRIENDLY))
	bar_pub.visible = false
	bar_fr.visible = false
	c.visible = false
	return {
		"c": c, "panel": panel, "content": content, "plate": plate, "icon": icon, "iconFlash": icon_flash,
		"barPublic": bar_pub, "barFriendly": bar_fr, "tag": tag, "tagBg": tag_bg,
		"name": name, "line2": line2, "owned": owned, "pill": pill, "fill": fill, "pill1": pill1, "pill2": pill2,
		"flash": flash, "dim": dim, "glint": glint, "index": k, "model": {"kind": "none", "id": ""}, "key": "",
		"afford": null, "glintReadyAt": 0.0, "pressP": 0.0, "pressed": false, "shakeT": -1.0, "hopT": -1.0,
		"popT": -1.0, "upgradePopT": -1.0, "tintUntil": 0.0, "pillWasPressed": false, "pillNoRebound": false,
		"pillReboundT": -1.0, "helloT": -1.0, "helloLast": -1e9, "cascadeAt": -1.0, "rippleAt": -1.0, "glintT": -1.0,
		"iconBase": Vector2.ZERO,
	}


func set_shop_visible(v: bool) -> void:
	_visible_shop = v
	visible = v
	_refresh_tabs()


# ------------------------------------------------------------------ model

func _models(s: GameState, t: String) -> Array:
	if t == "producers":
		var out: Array = []
		if bool(s.ui.get("buyModeRevealed", false)):
			out.append({"kind": "buymode", "id": ""})
		if ftue_single:
			out.append({"kind": "producer", "id": Content.producer_ids()[0]})
			return out
		var pr := Economy.producer_rows(s)
		for id: String in pr["revealed"]:
			out.append({"kind": "producer", "id": id})
		if pr["silhouette"] != "":
			out.append({"kind": "silhouette", "id": pr["silhouette"]})
		return out
	var ids: Array = _frozen_upgrades if not _frozen_upgrades.is_empty() else Economy.available_upgrades(s).map(func(u: Dictionary) -> String: return u["id"])
	return ids.map(func(id: String) -> Dictionary: return {"kind": "upgrade", "id": id})


func _max_scroll(n: int) -> float:
	return maxf(0.0, float(L.SHOP["rowPitch"]) * n - list_rect.size.y)


func _row_top(k: int, t: String) -> float:
	return float(L.SHOP["listY"]) + float(L.SHOP["rowVisualTop"]) + float(L.SHOP["rowPitch"]) * k - float(_scroll[t])


## `_lower`-local y of row k's top in a tab (FTUE hands), or -1 when not fully in view.
func row_screen_y(k: int, t: String = "") -> float:
	if t == "":
		t = tab
	var y := _row_top(k, t)
	if y < list_rect.position.y or y + float(L.SHOP["rowVisualH"]) > list_rect.end.y:
		return -1.0
	return y


func _row_partly_visible(k: int, t: String) -> bool:
	var y := _row_top(k, t)
	return y + float(L.SHOP["rowVisualH"]) > list_rect.position.y and y < list_rect.end.y


func row_index_of(s: GameState, kind: String, id: String) -> int:
	var t := "producers" if kind == "producer" else "upgrades"
	var m := _models(s, t)
	for i in m.size():
		if m[i]["kind"] == kind and m[i]["id"] == id:
			return i
	return -1


## Row icon centre, `_lower`-local (the confetti anchor).
func icon_pos(k: int) -> Vector2:
	return Vector2(L.ROW["iconCenter"]) + Vector2(0, _row_top(k, tab))


## The pill centre of row k, `_lower`-local (the FTUE hand's target).
func pill_pos(k: int) -> Vector2:
	return PILL_RECT.get_center() + Vector2(0, _row_top(k, tab))


# ------------------------------------------------------------------ per-frame refresh

func refresh(s: GameState, dt_ms: float, animate_reveal: bool, d: Economy.Derived) -> void:
	_state = s
	_now += dt_ms
	_refresh_tabs()
	set_tab_badge(2, _badge_label(Economy.affordable_upgrade_count(s)) if _slot_shown(1) and tab != "upgrades" else "")
	var models_p := _models(s, "producers")
	var rev_n := 0
	for m: Dictionary in models_p:
		if m["kind"] == "producer":
			rev_n += 1
	if _revealed_count >= 0 and rev_n > _revealed_count and animate_reveal:
		producer_revealed.emit()
		_maybe_auto_scroll(models_p.size() - 1)
	_revealed_count = rev_n

	for t in ["producers", "upgrades"]:
		var models := models_p if t == "producers" else _models(s, t)
		var views: Array = _rows[t]
		for k in views.size():
			var v: Dictionary = views[k]
			var c: Node2D = v["c"]
			if k >= models.size():
				c.visible = false
				v["model"] = {"kind": "none", "id": ""}
				v["key"] = ""   # a row hidden here (the FTUE's single card) re-reads its model when it returns
				v["afford"] = null
				continue
			c.visible = true
			_render_row(s, d, v, models[k], t == tab)
			_animate_row(v, dt_ms)
			var y := _row_top(k, t)
			if t == "upgrades" and _reflow_from >= 0 and k >= _reflow_from:
				y += _reflow_offset
			c.position.y = y
		if t == "upgrades":
			for e in _empty:
				e.visible = models.is_empty()
	_update_scroll(s, dt_ms)
	_update_tab_anim(dt_ms)
	_update_nudge(dt_ms, animate_reveal)


func _badge_label(n: int) -> String:
	return "" if n <= 0 else Strings.s("TAB_BADGE", {"count": "9+" if n > 9 else str(n)})


func _card_sprite(kind: String, afford: bool) -> String:
	match kind:
		"silhouette":
			return Art.sprite_or("card_source_locked")
		"upgrade":
			return Art.sprite_or("card_spin" if afford else "card_spin_locked")
		"buymode":
			return Art.sprite_or("card_row")
	return Art.sprite_or("card_source_affordable" if afford else "card_source_unaffordable")


func _render_row(s: GameState, d: Economy.Derived, v: Dictionary, m: Dictionary, active: bool) -> void:
	var R: Dictionary = L.ROW
	var afford := false
	var icon := ""
	var nm := ""
	var line2 := ""
	var owned_s := ""
	var l1 := ""
	var l2 := ""
	var price := 0.0
	var wide := false
	var bars: Dictionary = {}
	var tag_s := ""
	var id: String = m["id"]
	match String(m["kind"]):
		"producer":
			var q := Economy.quote(s, id)
			afford = q["affordable"]
			price = float(q["cost"])
			icon = Art.sprite_or(String(Content.producer(id).get("icon", Art.source(id).get("icon", "icon_" + id))))
			nm = Strings.producer_name(id)
			var owned := s.owned_of(id)
			if owned > 0:
				line2 = Strings.s("ROW_OWNED_BPS", {"rate": Fmt.rate(float(d.producer_bps.get(id, 0.0)))})
				owned_s = Strings.s("CARD_OWNED", {"n": Fmt.owned(owned)})
			else:
				line2 = Strings.s("CARD_YIELD", {"n": Fmt.rate(float(Content.producer(id).get("baseBps", 0.0)))})
				wide = true
			var bm: Variant = s.buy_mode
			if bm is int and bm == 1:
				l1 = Strings.s("CARD_VERB_FIRST" if owned == 0 else "CARD_VERB_MORE")
			else:
				l1 = Strings.s("ROW_BUY_N", {"qty": Fmt.qty(maxi(1, int(q["qty"])))})
			l2 = Strings.s("CARD_PRICE", {"price": Fmt.cost(price)})
		"silhouette":
			icon = Art.sprite_or(String(Content.producer(id).get("silhouette", Art.source(id).get("silhouette", "sil_" + id))))
			nm = Strings.s("ROW_LOCKED_NAME")
			line2 = Strings.s("CARD_LOCKED_CAP")
			wide = true
			price = float(Economy.quote(s, id, 1)["cost"])
			l1 = Strings.s("CARD_VERB_FIRST")
			l2 = Strings.s("CARD_PRICE", {"price": Fmt.cost(price)})
		"buymode":
			nm = Strings.s("BUYMODE_LABEL")
			afford = true
			var bm2: Variant = s.buy_mode
			l2 = Strings.s("BUYMODE_1" if (bm2 is int and bm2 == 1) else ("BUYMODE_10" if (bm2 is int and bm2 == 10) else "BUYMODE_MAX"))
		_:
			# the sim's price and buy rule (sim/README "Buy a spin"): a line's next level, S07's
			# income-scaled price; never u.cost / s.upgrades (a consumable or a line is never there)
			var u := Content.upgrade(id)
			var card := spin_card(s, id, d)
			price = float(card["price"])
			afford = bool(card["canBuy"])
			icon = Art.sprite_or(String(u.get("icon", "icon_" + id)))
			nm = Strings.upgrade_name(id)
			line2 = Strings.upgrade_effect(id)
			tag_s = String(card["tag"])
			wide = true
			l1 = Strings.s("SPIN_VERB")
			l2 = Strings.s("CARD_PRICE", {"price": Fmt.cost(price)}) if price >= 0.0 else Strings.s("SPIN_OWNED")
			bars = card.get("bars", {})
	var key := "%s:%s" % [m["kind"], id]
	var ic: Sprite2D = v["icon"]
	var is_btn: bool = m["kind"] == "buymode"
	if v["key"] != key:
		v["key"] = key
		v["model"] = m
		v["afford"] = null
		for k2 in ["pressP", "shakeT", "popT", "upgradePopT", "helloT", "pillReboundT", "cascadeAt", "rippleAt"]:
			v[k2] = 0.0 if k2 == "pressP" else -1.0
		v["pressed"] = false
		(v["plate"] as NinePatchRect).visible = not is_btn
		ic.visible = not is_btn and icon != ""
		if icon != "":
			ic.texture = Art.tex(icon, 0)
			var isz := Vector2(Art.sprite_size(icon)) * 4.0
			v["iconBase"] = Vector2(R["iconCenter"]) - (isz / 2.0 / 4.0).floor() * 4.0
			ic.position = v["iconBase"]
		ic.scale = Vector2(4, 4)
		(v["line2"] as PxText).wrap_width = float(R["line2WideW"] if wide else R["line2W"])
	(v["name"] as PxText).text = nm
	(v["line2"] as PxText).text = line2
	(v["owned"] as PxText).text = owned_s
	if v["afford"] == false and afford and active and _visible_shop and not is_btn:
		if _now >= float(v["glintReadyAt"]):
			v["glintReadyAt"] = _now + float(Tune.T["affordGlintCooldownMs"])
			if not reduced_motion:
				v["glintT"] = 0.0
				_start_hello(v)
			became_affordable.emit()
	v["afford"] = afford
	Ui.set_nine_frame(v["panel"], _card_sprite(m["kind"], afford), 0)
	# the pill: gold when affordable (pressed while held); a sunken well with a dim fill otherwise
	var pill_id := "button_secondary_default" if is_btn else ("pay_pill_pressed" if (afford and v["pressed"]) else ("pay_pill_default" if afford else "pay_pill_track"))
	Ui.set_nine_frame(v["pill"], Art.sprite_or(pill_id), 0)
	var fill: NinePatchRect = v["fill"]
	fill.visible = not afford and price > 0.0 and not is_btn
	if fill.visible:
		var inner := Rect2(PILL_RECT.position + Vector2(8, 8), PILL_RECT.size - Vector2(16, 24))
		var w := maxf(8.0, Ui.snap(inner.size.x * clampf(s.bananas / price, 0.0, 1.0), 4))
		Ui.set_nine_rect(fill, Rect2(L.bar_x(inner, w), inner.position.y, w, inner.size.y))
	var ink := Art.col("w") if (afford or is_btn) else Color(0.78, 0.74, 0.62)
	var p1: PxText = v["pill1"]
	var p2: PxText = v["pill2"]
	p1.text = l1
	p2.text = l2
	p1.tint = ink
	p2.tint = ink
	p1.center_in(PILL_RECT.position.x, PILL_RECT.size.x)
	p2.center_in(PILL_RECT.position.x, PILL_RECT.size.x)
	if is_btn:
		p2.position.y = PILL_RECT.get_center().y - 18.0
	var pill_a := 0.4 if (ftue_dim and not afford and not is_btn) else 1.0
	for n: CanvasItem in [v["pill"], fill, p1, p2]:
		n.modulate.a = pill_a
	var flash: Sprite2D = v["iconFlash"]
	var tinted := _now < float(v["tintUntil"])
	flash.visible = tinted
	if tinted:
		flash.texture = ic.texture
		flash.position = ic.position
	ic.modulate = Color.WHITE if (m["kind"] == "silhouette" or afford) else Color(0.6, 0.6, 0.6)
	(v["name"] as PxText).tint = Art.col("w") if (afford or is_btn) else Color(0.86, 0.84, 0.9)
	(v["line2"] as PxText).tint = Color(0.78, 0.9, 0.62) if afford else Color(0.72, 0.7, 0.78)
	(v["owned"] as PxText).tint = Color(0.86, 0.84, 0.9)
	_render_bars(v, bars)
	var tg: PxText = v["tag"]
	if tg.text != tag_s:
		tg.text = tag_s
		tg.center_in(SPIN_TAG.position.x, SPIN_TAG.size.x)
	tg.visible = tag_s != ""
	(v["tagBg"] as ColorRect).visible = tg.visible


## S08's split bar: "public" from the right (the RTL fill side), the drained share after it.
func _render_bars(v: Dictionary, bars: Dictionary) -> void:
	var pub: ColorRect = v["barPublic"]
	var fr: ColorRect = v["barFriendly"]
	pub.visible = not bars.is_empty()
	fr.visible = pub.visible
	if not pub.visible:
		return
	var sb := SPIN_BARS
	var wp := Ui.snap(sb.size.x * clampf(float(bars.get("public", 100.0)) / 100.0, 0.0, 1.0), 4)
	pub.position = Vector2(L.bar_x(sb, wp), sb.position.y)
	pub.size = Vector2(wp, sb.size.y)
	var wf := sb.size.x - wp
	fr.position = Vector2(sb.position.x if L.RTL else sb.position.x + wp, sb.position.y)
	fr.size = Vector2(wf, sb.size.y)


## The spin card's model (rtl-map §6.1 "Spin card"), from the sim's reads only:
## {price (-1 = nothing left), canBuy, tag (the owned-badge slot: "שחוק" on a worn consumable, a
## line's "level/levels"; "" = none), bars (S08), flightPct (S10), kind}.
static func spin_card(s: GameState, id: String, d: Economy.Derived = null) -> Dictionary:
	var c := Spins.card(s, id, d)
	if c.is_empty():
		return {"price": -1.0, "canBuy": false, "tag": "", "kind": "once"}
	var tag := ""
	if c["kind"] == "line" and int(c["levels"]) > 1:
		tag = Strings.s("PERK_LEVEL", {"lv": int(c["level"]), "max": int(c["levels"])})
	elif c["worn"]:
		tag = Strings.s("SPIN_FATIGUE")
	var out := {"price": float(c["price"]), "canBuy": Economy.can_buy_upgrade(s, id), "tag": tag, "kind": c["kind"]}
	if c.has("bars"):
		out["bars"] = c["bars"]
	if c.has("flightPct"):
		out["flightPct"] = c["flightPct"]
	return out


func _start_hello(v: Dictionary) -> void:
	if reduced_motion or v["pressed"]:
		return
	v["helloT"] = 0.0
	v["helloLast"] = _now


func _animate_row(v: Dictionary, dt_ms: float) -> void:
	var S: Dictionary = L.SHOP
	var target := 1.0 if v["pressed"] else 0.0
	var dur := float(Tune.T["buyPressMs"] if v["pressed"] else Tune.T["buyReleaseMs"])
	var pp: float = v["pressP"]
	if pp != target:
		pp = minf(1.0, pp + dt_ms / dur) if target > pp else maxf(0.0, pp - dt_ms / dur)
		v["pressP"] = pp
	var lx := float(S["listX"])
	var lw := float(S["listW"])
	var row_h := float(S["rowVisualH"])
	var bps_ := float(Tune.T["buyPressScale"])
	var max_x := maxf(1.0, roundf(lw * (1.0 - bps_) / 2.0 / 4.0))
	var max_y := maxf(1.0, roundf(row_h * (1.0 - bps_) / 2.0 / 4.0))
	var ix := maxf(1.0, ceilf(pp * max_x)) if pp > 0.0 else 0.0
	var iy := maxf(1.0, ceilf(pp * max_y)) if pp > 0.0 else 0.0
	var panel: NinePatchRect = v["panel"]
	panel.size = Vector2(lw / 4.0 - 2.0 * ix, row_h / 4.0 - 2.0 * iy)
	panel.position = Vector2(lx + ix * 4.0, iy * 4.0)
	var drop_y := 4.0 if pp > 0.0 else 0.0
	var hop := 0.0
	if float(v["hopT"]) >= 0.0:
		v["hopT"] = float(v["hopT"]) + dt_ms
		var p := minf(1.0, float(v["hopT"]) / float(Tune.T["iconHopMs"]))
		hop = -Ui.snap(float(Tune.T["iconHopPx"]) * 4.0 * p * (1.0 - p), 4)
		if p >= 1.0:
			v["hopT"] = -1.0
	for k in ["cascadeAt", "rippleAt"]:
		var at: float = v[k]
		if at < 0.0 or _now < at:
			continue
		var t := _now - at
		if t >= ICON_NUDGE.size() * Tune.FRAME_MS:
			v[k] = -1.0
			continue
		hop = minf(hop, float(Juice.sample(ICON_NUDGE, t)))
	(v["content"] as Node2D).position.y = drop_y
	var ic: Sprite2D = v["icon"]
	var base: Vector2 = v["iconBase"]
	if float(v["upgradePopT"]) >= 0.0:
		v["upgradePopT"] = float(v["upgradePopT"]) + dt_ms
		var p3 := minf(1.0, float(v["upgradePopT"]) / float(Tune.T["upgradePopMs"]))
		var sc := int(roundf(float(Tune.T["upgradePopScale"]) * (1.0 - p3 * p3) * 4.0))
		if sc <= 0:
			ic.visible = false
		else:
			var cen := Vector2(L.ROW["iconCenter"])
			var half := (Vector2(ic.texture.get_size()) * sc / 2.0).floor()
			ic.scale = Vector2(sc, sc)
			ic.position = cen - half
		if p3 >= 1.0:
			v["upgradePopT"] = -1.0
	else:
		ic.position = base + Vector2(0, hop)
	_animate_pill(v, dt_ms)
	var c: Node2D = v["c"]
	if float(v["shakeT"]) >= 0.0:
		v["shakeT"] = float(v["shakeT"]) + dt_ms
		var t2: float = v["shakeT"]
		var ms := float(Tune.T["cantAffordShakeMs"])
		if reduced_motion:
			(v["dim"] as ColorRect).modulate.a = 0.4 * maxf(0.0, 1.0 - t2 / ms)
			c.position.x = 0.0
		else:
			var halfc := ms / (2.0 * float(Tune.T["cantAffordShakeCycles"]))
			c.position.x = (float(Tune.T["cantAffordShakePx"]) * (1.0 if int(floorf(t2 / halfc)) % 2 == 0 else -1.0)) if t2 < ms else 0.0
		if t2 >= ms:
			v["shakeT"] = -1.0
			c.position.x = 0.0
			(v["dim"] as ColorRect).modulate.a = 0.0
	if float(v["glintT"]) >= 0.0:
		v["glintT"] = float(v["glintT"]) + dt_ms
		var p4 := minf(1.0, float(v["glintT"]) / float(Tune.T["affordGlintMs"]))
		var g: ColorRect = v["glint"]
		g.modulate.a = 0.5 if p4 < 1.0 else 0.0
		var e := 1.0 - p4 * p4 * (3.0 - 2.0 * p4)   # right to left: the reading direction
		g.position.x = Ui.snap(lx + 4.0 + (lw - 16.0) * e, 4)
		if p4 >= 1.0:
			v["glintT"] = -1.0


func _animate_pill(v: Dictionary, dt_ms: float) -> void:
	var squish := not reduced_motion
	if v["pressed"]:
		v["helloT"] = -1.0
	if v["pillWasPressed"] and not v["pressed"]:
		v["pillReboundT"] = 0.0 if (squish and not v["pillNoRebound"]) else -1.0
	if v["pressed"]:
		v["pillNoRebound"] = false
	v["pillWasPressed"] = v["pressed"]
	var dy := 0.0
	var dw := 0.0
	var dh := 0.0
	var anchor := "centre"
	if v["pressed"] and squish:
		dh = -SQ
	elif float(v["pillReboundT"]) >= 0.0:
		if float(v["pillReboundT"]) >= PILL_REBOUND.size() * Tune.FRAME_MS:
			v["pillReboundT"] = -1.0
		else:
			dh = float(Juice.sample(PILL_REBOUND, v["pillReboundT"]))
			v["pillReboundT"] = float(v["pillReboundT"]) + dt_ms
	if float(v["helloT"]) >= 0.0:
		if float(v["helloT"]) >= float(Tune.MC["pillHelloMs"]):
			v["helloT"] = -1.0
		else:
			var h: Array = Juice.sample(PILL_HELLO, v["helloT"])
			dy = float(h[0])
			dw = float(h[1])
			dh = float(h[2])
			anchor = "bottom"
			v["helloT"] = float(v["helloT"]) + dt_ms
	PxButton.squish_nine(v["pill"], PILL_RECT, dw, dh, 0, dy, anchor)
	if v["model"]["kind"] != "buymode":
		(v["pill1"] as PxText).position.y = float(L.ROW["pillLine1Y"]) + dy
		(v["pill2"] as PxText).position.y = float(L.ROW["pillLine2Y"]) + dy


func _update_nudge(dt_ms: float, live: bool) -> void:
	_nudge_t += dt_ms
	if _nudge_t < float(Tune.MC["pillNudgePeriodMs"]):
		return
	_nudge_t = 0.0
	if not live or reduced_motion or not _visible_shop or not _press.is_empty() or not _tab_anim.is_empty():
		return
	if _now - _last_interaction < float(Tune.MC["pillNudgeIdleMs"]) or (nudge_blocked.is_valid() and nudge_blocked.call()):
		return
	var eligible: Array = []
	for v: Dictionary in _rows[tab]:
		var kind: String = v["model"]["kind"]
		if (v["c"] as Node2D).visible and v["afford"] == true and (kind == "producer" or kind == "upgrade") \
			and row_screen_y(v["index"]) >= 0.0 and _now - float(v["helloLast"]) >= float(Tune.MC["pillNudgeRepeatMs"]):
			eligible.append(v)
	if eligible.is_empty():
		return
	var pick: Dictionary = eligible[0]
	for v: Dictionary in eligible:
		if int(v["index"]) > _nudge_cursor:
			pick = v
			break
	_nudge_cursor = pick["index"]
	_start_hello(pick)


## ux/ftue.md P1 F3: one bounce of a card (the pill's hello).
func bounce_row(k: int) -> void:
	var rows: Array = _rows[tab]
	if k >= 0 and k < rows.size():
		_start_hello(rows[k])


func _success_fx(v: Dictionary, is_upgrade: bool) -> void:
	var f: ColorRect = v["flash"]
	f.modulate.a = float(Tune.T["buyFlashAlpha"])
	create_tween().tween_property(f, "modulate:a", 0.0, float(Tune.T["buyFlashMs"]) / 1000.0).set_ease(Tween.EASE_OUT)
	if reduced_motion:
		return
	if is_upgrade:
		v["upgradePopT"] = 0.0
	else:
		v["popT"] = 0.0
		v["hopT"] = 0.0


func _cascade(v: Dictionary) -> void:
	if reduced_motion or _now - _last_cascade < float(Tune.MC["cascadeMinGapMs"]):
		return
	_last_cascade = _now
	var rows: Array = _rows["producers"]
	for dd in range(1, int(Tune.MC["cascadeReach"]) + 1):
		for k in [int(v["index"]) - dd, int(v["index"]) + dd]:
			if k < 0 or k >= rows.size():
				continue
			var n: Dictionary = rows[k]
			if not (n["c"] as Node2D).visible or n["model"]["kind"] != "producer" or not _row_partly_visible(k, "producers"):
				continue
			n["cascadeAt"] = _now + dd * float(Tune.MC["cascadeStepMs"])


func _cant_afford_fx(v: Dictionary) -> void:
	v["shakeT"] = 0.0
	v["pillNoRebound"] = true
	v["pillReboundT"] = -1.0


# ------------------------------------------------------------------ input (called by the router, `_lower`-local)

## A press on the tab bar: switches on release (tab_up). Returns true when it hit a shown slot.
func tabs_down(p: Vector2) -> bool:
	if not (_visible_shop and _tabs_on):
		return false
	for i in 4:
		if _slot_shown(i) and Ui.in_rect(L.tab_rect(i + 1), p):
			_tab_pressed = i
			return true
	return Ui.in_rect(Rect2(0, L.tabs_y(), L.W, L.TABS_H), p)   # the bar swallows presses between slots


func tab_up(p: Vector2 = Vector2(-1, -1)) -> void:
	var i := _tab_pressed
	_tab_pressed = -1
	if i < 0:
		return
	if p.x >= 0.0 and not Ui.in_rect(L.tab_rect(i + 1), p):
		return
	switch_tab(TABS[i])


## Keyboard 1-4 = slots 1-4 (rtl-map §6.2).
func switch_slot(slot: int) -> void:
	if slot >= 1 and slot <= 4 and _slot_shown(slot - 1):
		switch_tab(TABS[slot - 1])


func switch_tab(t: String) -> void:
	if TALL_TABS.has(t):
		tall_tab_requested.emit(t)
		return
	if t == tab:
		tab_switched.emit(t)
		return
	if not _lists.has(t):
		return
	var dir := -1.0 if t == "upgrades" else 1.0   # the list slides in from the side its tab sits on
	tab = t
	cancel_press()
	_vel = 0.0
	(_lists["producers"] as Node2D).visible = t == "producers"
	(_lists["upgrades"] as Node2D).visible = t == "upgrades"
	_tab_anim = {"t": 0.0, "dir": dir}
	_refresh_tabs()
	tab_switched.emit(t)


func _update_tab_anim(dt_ms: float) -> void:
	var l: Node2D = _lists[tab]
	var base_x := -list_rect.position.x
	if _tab_anim.is_empty():
		l.modulate.a = 1.0
		l.position.x = base_x
		return
	_tab_anim["t"] = float(_tab_anim["t"]) + dt_ms
	var t: float = _tab_anim["t"]
	if reduced_motion:
		var p := minf(1.0, t / 100.0)
		l.modulate.a = p
		l.position.x = base_x
		if p >= 1.0:
			_tab_anim = {}
		return
	var out_ms := float(Tune.MC["tabSwitchOutMs"])
	if t < out_ms:
		l.modulate.a = 0.0
		return
	var tin := t - out_ms
	var p2 := minf(1.0, tin / float(Tune.MC["tabSwitchInMs"]))
	l.modulate.a = 1.0 - (1.0 - p2) * (1.0 - p2)
	l.position.x = base_x + float(_tab_anim["dir"]) * float(Juice.sample(TAB_IN, tin))
	if p2 >= 1.0:
		_tab_anim = {}
		l.position.x = base_x


func in_list(p: Vector2) -> bool:
	return _visible_shop and Ui.in_rect(list_rect, p)


func _row_at(y: float) -> int:
	return int(floorf((y + float(_scroll[tab]) - float(L.SHOP["listY"]) - float(L.SHOP["rowVisualTop"])) / float(L.SHOP["rowPitch"])))


func list_down(p: Vector2, s: GameState) -> void:
	_mark_interaction()
	_vel = 0.0
	if _scroll_tw:
		_scroll_tw.kill()
	var k := _row_at(p.y)
	var rows: Array = _rows[tab]
	var valid: bool = k >= 0 and k < rows.size() and rows[k]["model"]["kind"] != "none" and (rows[k]["c"] as Node2D).visible
	_press = {"tab": tab, "row": k if valid else -1, "x0": p.x, "y0": p.y, "scroll0": _scroll[tab], "dragging": false,
		"repeated": false, "repeats": 0, "holdMs": -1.0, "lastY": p.y, "lastT": _now, "vel": 0.0}
	if not valid:
		return
	var v: Dictionary = rows[k]
	v["pressed"] = true
	v["helloT"] = -1.0
	v["pressP"] = maxf(float(v["pressP"]), 0.0001)
	if v["model"]["kind"] == "producer":
		_press["holdMs"] = float(Tune.T["holdRepeatDelayMs"])


## Hold-to-repeat, driven from the per-frame tick (stops the moment a modal opens: the router
## calls cancel_press()).
func tick_hold(dt_ms: float, s: GameState) -> void:
	if _press.is_empty() or _press["dragging"] or float(_press["holdMs"]) < 0.0:
		return
	_press["holdMs"] = float(_press["holdMs"]) - dt_ms
	if float(_press["holdMs"]) > 0.0:
		return
	var v: Dictionary = _rows[_press["tab"]][_press["row"]]
	if v["model"]["kind"] != "producer":
		_press["holdMs"] = -1.0
		return
	_press["repeated"] = true
	_press["repeats"] = int(_press["repeats"]) + 1
	var res: Array = [0]
	buy_producer_requested.emit(v["model"]["id"], true, res)
	var qty: int = res[0]
	if qty > 0:
		_success_fx(v, false)
		if int(_press["repeats"]) == 1 or qty > 1:
			_cascade(v)
		_press["holdMs"] = float(Tune.T["holdRepeatIntervalMs"])
	else:
		_cant_afford_fx(v)
		cant_afford.emit()
		_press["holdMs"] = -1.0


func _move_cancel_px() -> float:
	return maxf(float(Tune.T["buyDragCancelPx"]), float(L.SHOP["moveCancelPx"]))


func list_move(p: Vector2) -> void:
	if _press.is_empty():
		return
	var dt := maxf(1.0, _now - float(_press["lastT"]))
	if not _press["dragging"] and p.distance_to(Vector2(_press["x0"], _press["y0"])) > _move_cancel_px():
		_press["dragging"] = true
		_press["holdMs"] = -1.0
		var rows: Array = _rows[_press["tab"]]
		var r: int = _press["row"]
		if r >= 0 and r < rows.size():
			rows[r]["pressed"] = false
	if _press["dragging"]:
		var t: String = _press["tab"]
		var s0: float = _scroll[t]
		_set_scroll(t, float(_press["scroll0"]) - (p.y - float(_press["y0"])))
		_press["vel"] = (float(_scroll[t]) - s0) / (dt / Tune.FRAME_MS)
		_thumb_active_at = _now
	_press["lastY"] = p.y
	_press["lastT"] = _now
	_mark_interaction()


## The whole card commits on release (rtl-map §6.1), unless the press became a scroll.
func list_up(p: Vector2, s: GameState) -> void:
	var pr := _press
	_press = {}
	if pr.is_empty():
		return
	_mark_interaction()
	var rows: Array = _rows[pr["tab"]]
	var r: int = pr["row"]
	var v: Dictionary = rows[r] if (r >= 0 and r < rows.size()) else {}
	if not v.is_empty():
		v["pressed"] = false
	if pr["dragging"]:
		_vel = float(pr["vel"]) if absf(float(pr["vel"])) > float(Tune.MC["listMomentumStop"]) else 0.0
		return
	if v.is_empty() or pr["repeated"] or pr["tab"] != tab:
		return
	_commit(v, s)


## Keyboard 1-8: the same commit as a tap on the card.
func commit_producer(id: String, s: GameState) -> void:
	var k := row_index_of(s, "producer", id)
	if k < 0:
		return
	var v: Dictionary = _rows["producers"][k]
	v["model"] = {"kind": "producer", "id": id}
	v["key"] = ""
	_commit(v, s)


func _commit(v: Dictionary, s: GameState) -> void:
	var m: Dictionary = v["model"]
	match String(m["kind"]):
		"producer":
			var res: Array = [0]
			buy_producer_requested.emit(m["id"], false, res)
			if int(res[0]) > 0:
				_success_fx(v, false)
				_cascade(v)
			else:
				_cant_afford_fx(v)
				cant_afford.emit()
		"upgrade":
			var before: Array = _models(s, "upgrades").map(func(x: Dictionary) -> String: return x["id"])
			var idx := before.find(m["id"])
			var res2: Array = [false]
			buy_upgrade_requested.emit(m["id"], res2)
			if res2[0]:
				if Economy.available_upgrades(s).any(func(u: Dictionary) -> bool: return u["id"] == m["id"]):
					_success_fx(v, false)   # a line's next level: the card stays, so no pop-out and no reflow
				else:
					_success_fx(v, true)
					_start_reflow(before, idx)
			else:
				_cant_afford_fx(v)
				cant_afford.emit()
		"buymode":
			cycle_mode.emit()
		"silhouette":
			_cant_afford_fx(v)
			cant_afford.emit()


func _start_reflow(before: Array, idx: int) -> void:
	if reduced_motion:
		return
	_frozen_upgrades = before
	get_tree().create_timer(float(Tune.T["upgradePopMs"]) / 1000.0).timeout.connect(func() -> void:
		_frozen_upgrades = []
		_reflow_from = idx
		_reflow_offset = float(L.SHOP["rowPitch"])
		for r: Dictionary in _rows["upgrades"]:
			r["key"] = ""
		var tw := create_tween()
		tw.tween_method(func(o: float) -> void: _reflow_offset = Ui.snap(o, 4), float(L.SHOP["rowPitch"]), 0.0, float(Tune.T["shelfReflowMs"]) / 1000.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_callback(func() -> void: _land_reflow(idx)))


func _land_reflow(idx: int) -> void:
	var end := func() -> void:
		_reflow_offset = 0.0
		_reflow_from = -1
	if reduced_motion:
		end.call()
		return
	Juice.play(_rows["upgrades"], 2.0 * Tune.FRAME_MS, func(_t: float) -> void: _reflow_offset = -float(Tune.MC["reflowLandBumpPx"]), end)
	var j := 0
	var rows: Array = _rows["upgrades"]
	for k in range(idx, rows.size()):
		if j >= 4:
			break
		var r: Dictionary = rows[k]
		if not (r["c"] as Node2D).visible or not _row_partly_visible(k, "upgrades"):
			continue
		r["rippleAt"] = _now + j * float(Tune.MC["reflowIconStaggerMs"])
		j += 1


func cancel_press() -> void:
	_tab_pressed = -1
	if _press.is_empty():
		return
	var rows: Array = _rows[_press["tab"]]
	var r: int = _press["row"]
	if r >= 0 and r < rows.size():
		rows[r]["pressed"] = false
	_press = {}


func pressing() -> bool:
	return not _press.is_empty()


func wheel(dy: float) -> void:
	_mark_interaction()
	_thumb_active_at = _now
	var t := tab
	var target := float(_scroll[t]) + signf(dy) * float(Tune.MC["wheelNotchPx"])
	if _scroll_tw:
		_scroll_tw.kill()
	if reduced_motion:
		_set_scroll(t, target)
		return
	_scroll_tw = create_tween()
	_scroll_tw.tween_method(func(v: float) -> void: _set_scroll(t, v), float(_scroll[t]), target, float(Tune.MC["wheelEaseMs"]) / 1000.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)


func _mark_interaction() -> void:
	_last_interaction = _now
	list_interaction.emit()


func _set_scroll(t: String, v: float) -> void:
	_scroll[t] = clampf(v, 0.0, float(_max_for[t]))


func _maybe_auto_scroll(k: int) -> void:
	if reduced_motion or not _press.is_empty() or _now - _last_interaction <= float(Tune.MC["revealAutoScrollIdleMs"]) or tab != "producers":
		return
	var bottom := _row_top(k, "producers") + float(_scroll["producers"]) + float(L.SHOP["rowVisualH"])
	if bottom <= list_rect.end.y + float(_scroll["producers"]):
		return
	var target := bottom - list_rect.end.y
	_max_for["producers"] = maxf(float(_max_for["producers"]), target)
	if _scroll_tw:
		_scroll_tw.kill()
	_scroll_tw = create_tween()
	_scroll_tw.tween_method(func(v: float) -> void: _set_scroll("producers", v), float(_scroll["producers"]), target, float(Tune.MC["revealAutoScrollMs"]) / 1000.0).set_ease(Tween.EASE_OUT)


func _update_scroll(s: GameState, dt_ms: float) -> void:
	for t in ["producers", "upgrades"]:
		_max_for[t] = _max_scroll(_models(s, t).size())
		_set_scroll(t, _scroll[t])
	if _press.is_empty() and _vel != 0.0:
		_set_scroll(tab, float(_scroll[tab]) + _vel * (dt_ms / Tune.FRAME_MS))
		_vel *= pow(float(Tune.MC["listMomentumDecay"]), dt_ms / Tune.FRAME_MS)
		if absf(_vel) < float(Tune.MC["listMomentumStop"]):
			_vel = 0.0
		_thumb_active_at = _now
	var n := _models(s, tab).size()
	var content_h := float(L.SHOP["rowPitch"]) * n
	var lh := list_rect.size.y
	var scrollable := content_h > lh
	_thumb.visible = scrollable and _visible_shop
	if scrollable:
		var th := maxf(48.0, lh * lh / content_h)
		var mx: float = _max_for[tab] if float(_max_for[tab]) > 0.0 else 1.0
		var y := list_rect.position.y + (lh - th) * (float(_scroll[tab]) / mx)
		_thumb.size.y = Ui.snap(th, 4)
		_thumb.position.y = Ui.snap(y, 4)
		var active: bool = (not _press.is_empty() and _press["dragging"]) or _now - _thumb_active_at < float(Tune.MC["thumbIdleMs"])
		_thumb.modulate.a = 1.0 if active else float(Tune.MC["thumbIdleAlpha"])


func reset_run() -> void:
	_scroll = {"producers": 0.0, "upgrades": 0.0}
	_vel = 0.0
	_revealed_count = -1
	_frozen_upgrades = []
	cancel_press()
	for t in ["producers", "upgrades"]:
		for r: Dictionary in _rows[t]:
			r["key"] = ""
			r["afford"] = null
