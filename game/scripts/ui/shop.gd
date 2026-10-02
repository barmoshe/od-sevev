class_name Shop
extends Node2D
## The card panel and the tab bar (ux/rtl-map.md §6), `_lower`-local: the list sits at y 84 with
## height P (the flex rule), the tab bar under it. RTL cards: plate and icon on the right, the name
## right-aligned beside it, line 2 (yield) under it, the owned count as a dark badge on the plate's
## bottom-left corner (rtl-map §6.1 D4), the price pill on the left. The WHOLE card is the buy target (first-minute §3.1): commit on release,
## a move beyond moveCancelPx makes the press a scroll. Hold a source card to repeat-buy.
## The pill (R5): verb over price; affordable = the kit's gold pill; unaffordable = the sunken well
## with a dim fill growing from the right as the treasury approaches the price.
## Tabs (rtl-map §6.2): four fixed slots, reading order right → left (מקורות, ספינים, קואליציה,
## תיקים); each appears when its reveal fires (ux/ftue.md §3) and never moves. The coalition and
## dossier tabs are tall tabs: their slot emits tall_tab_requested (the controller opens the view).
## Juice kept from the fork: press squish, pill hello and nudge, glint, can't-afford shake,
## success flash, icon hop and cascade, the upgrade shelf reflow, momentum scroll.
## Mobile-first (ux/mobile-first-layout.md §4.1, §5.1, §5.3, §5.4): the card stretches to 688 + dx
## (its plate, icon, name and line 2 R-anchored, the pill L), the pill grows by min(dx, 40) and
## shows its price at ×5 where it fits; after the real rows, one dim teaser row per source still to
## come fills the pane (no price, no pill, not a target); the tab bar has four fluid slots of
## floor4(cw / 4) and slides up from the screen bottom at C1.

signal buy_producer_requested(id: String, is_repeat: bool, result: Array)
signal buy_upgrade_requested(id: String, result: Array)
signal cant_afford
signal cycle_mode
signal tab_switched(tab: String)
signal became_affordable
signal producer_revealed
signal list_interaction
## A tall tab's slot was chosen (T3 "coalition", T4 "dossier"): the controller opens that view.
signal tall_tab_requested(tab: String)

const TABS := ["producers", "upgrades", "coalition", "dossier"]
const TAB_KEYS := ["TAB_SOURCES", "TAB_SPINS", "TAB_COALITION", "TAB_DOSSIER"]
const TAB_ICONS := ["tabicon_sources", "tabicon_spins", "tabicon_coalition", "tabicon_cases"]
## T3 (the coalition chat, ui/views/view_chat.gd) and T4 (the dossier, ui/views/view_dossier.gd)
## are built; a slot shows once its reveal fires.
const TAB_BUILT := [true, true, true, true]
const TALL_TABS := ["coalition", "dossier"]
## S08 "השלט" (karhiLine): its two bars live on the card only. One 2-art-px split track under
## line 2 (card-local): "שידור ציבורי" fills from the right, "ערוץ ידידותי" takes the rest. Labels
## on the 8-px bar don't fit (rtl-map §6.1): at level ≥ 1 line 2 names the growing part instead
## (SPIN_BARS_LINE, spin_line2). The palette letters are the art.json palette.
const SPIN_BARS := Rect2(220, 104, 360, 8)
## The spin tag's stamp: the bottom band of the plate (kit card_plate at 588-692 × 8-112).
const SPIN_TAG := Rect2(592, 72, 96, 40)
const TAG_SLAM_STEP_MS := 30.0      # the slip's stamp slam: ×6, ×5, ×4 (90 ms, Stepped)
const C_SIL_TEXT := Color("#072a7a")   # ui_panel on card_row_silhouette (review U7)
## D21 (mobile-first §5.3.1): the tab bar is always four slots. The plate is drawn from the kit's
## divider-free first column (its three baked dividers stretch with the 9-slice and sat beside empty
## slots); the engine draws one 1-art-px divider per slot boundary; a slot not yet revealed shows its
## own icon as a locked silhouette (ui_bubble on ui_panel, like the pale teaser slips) with the kit's
## padlock where the label goes. Not a target, no label: its name stays a reveal.
const TABBAR_PLAIN := Rect2(0, 0, 40, 26)     # kit `tabbar` columns 0-39: the rules, no divider
const C_TAB_DIVIDER := Color("#061029")       # the kit divider (ui_scrim)
const C_TAB_LOCKED := Color("#1045b5")        # ui_bubble: the locked slot's icon silhouette, a raised step on ui_panel (quiet: not a target)
const C_TAB_LOCK := Color(0.75, 0.82, 1.0, 0.6)   # the kit padlock, dimmed toward ui_mute (its keyhole stays legible)
## D20 (mobile-first §5.4.1): the white field is a ruled sheet, not a gap. A flag-blue rule, 1 art px,
## runs down each side of the pane on the canvas edge (x 0 and cw − 4), so the 4-art
## gutter reads as the ruled margin of a printed notice framed by the blue ticker and tab bar (style guide v4: "white notices ruled in flag
## blue"). The scroll thumb rides the left rule: 3 art px of deep blue while the list moves, hidden
## when idle (the peek is the resting scroll signifier, §3.2).
const RULE_INSET := 0.0
const RULE_W := 4.0
const C_RULE := Color("#0038b8")        # flag
const C_THUMB := Color("#072a7a")       # ui_panel
const THUMB_X := 0.0
const THUMB_W := 12.0
const SPIN_BAR_PUBLIC := "e"
const SPIN_BAR_FRIENDLY := "O"
## Milestones on the source card (Bar 2026-10-02: the ×2 bonuses were invisible; content
## milestones, applied in sim/meta.gd). An owned source shows, card-local on the R side:
## - a 2-art-px progress track under line 2 (the spin bars' slot, y 104), from the text box's left
##   edge to 8 px clear of the owned chip, filled from the right (RTL) by owned / next;
## - the label "12/25 ← ×2" (CARD_MS_NEXT) on the name row at the box's left edge, over the bar's
##   goal end; where it would come within 16 px of the name, the count alone (CARD_MS_SHORT), else
##   nothing (the bar stays);
## - its milestone multiplier so far as a gold chip "×4" (CARD_MS_MULT) after line 2's rate.
## Crossing a milestone pulses the card gold twice and slams the chip (×6 → ×5 → ×4); reduced
## motion: one soft gold fade. The buy-mode row (the list's head) carries the all-sources goal:
## line 2 "כולם ב־10 ← ×1.25" (SHOP_ALL_MS) over one segment per source, each filled by
## min(owned, n) / n.
const MS_BAR_Y := 104.0
const MS_BAR_H := 8.0
const MS_BAR_RIGHT := 564.0           # the owned chip starts at x 572
const MS_BAR_RIGHT_WIDE := 580.0      # the buy-mode row has no owned chip
const MS_GAP := 16.0
const MS_SEG_GAP := 4.0
const MS_TAG_H := 40.0
const MS_LABEL_W := 248.0             # string-budgets card.ms
const MS_CELEB_MS := 800.0            # two pulses (150 on, 150 off, 150 on), then the fade
const MS_CELEB_REDUCED_MS := 400.0
const C_MS_GOLD := Color("#ffd23a")   # Y: the pill's gold
const C_MS_GOLD_DIM := Color("#d9a21c")   # y: on the unaffordable (slate) card
const C_MS_INK := Color("#0f2350")    # U on the gold chip
const C_MS_TRACK := Color(0.059, 0.137, 0.314, 0.45)   # U at 45%: a groove on the card

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
var _dividers: Array[ColorRect] = []
var _slots: Array[Dictionary] = []
var _tab_pressed := -1
var _thumb: ColorRect
var _rules: Array[ColorRect] = []
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
var _layout_dx := -1.0

# juice tables
var SQ := 8.0
var PILL_REBOUND: Array
var ICON_NUDGE: Array
var PILL_HELLO: Array
var TAB_IN: Array
var PILL_RECT: Rect2
## mobile-first §5.1: the pill's growth, min(dx, 40)
var _pill_g := 0.0
var _tab_dy := 0.0
var _tab_tw: Tween


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
	for i in 2:
		_rules.append(Ui.rect(self, Rect2(0, 0, RULE_W, 4), C_RULE))
	_thumb = Ui.rect(self, Rect2(THUMB_X, float(L.SHOP["listY"]), THUMB_W, 48), C_THUMB)
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
	for e in _empty:
		e.fit_width = 656.0   # list.empty
	up.visible = false
	_build_tabs()
	set_list_height(L.panel_h)


func _build_tabs() -> void:
	_tabbar = Ui.nine(self, Rect2(0, 0, L.W, L.TABS_H), Art.sprite_or("tabbar"))
	if Art.has_sprite("tabbar") and Vector2(Art.sprite_size("tabbar")) == Vector2(180, 26):
		_tabbar.region_rect = TABBAR_PLAIN   # D21: the plate without its baked dividers
	for i in 3:
		_dividers.append(Ui.rect(self, Rect2(0, 0, 4, 64), C_TAB_DIVIDER))
	for i in 4:
		var d := {}
		d["plate"] = Ui.nine(self, Rect2(0, 0, 180, L.TABS_H), Art.sprite_or("tab_active"))
		# D21: the locked slot (drawn under the live icon; only one of the two shows)
		d["lockedIcon"] = Ui.img(self, Vector2.ZERO, Art.sprite_or(TAB_ICONS[i] + "_idle"), 0, 4)
		(d["lockedIcon"] as Sprite2D).material = Ui.fill_material(C_TAB_LOCKED)
		d["lock"] = Ui.img(self, Vector2.ZERO, Art.sprite_or("chat_icon_lock"), 0, 4)
		(d["lock"] as Sprite2D).modulate = C_TAB_LOCK
		d["icon"] = Ui.img(self, Vector2.ZERO, Art.sprite_or(TAB_ICONS[i] + "_idle"), 0, 4)
		d["label"] = PxText.make(self, Vector2.ZERO, Strings.s(TAB_KEYS[i]), L.TEXT, "plain", "w")
		(d["label"] as PxText).fit_width = 164.0   # tab.label (slot − 16): at ×5 "קואליציה" (195) steps down
		d["badge"] = Ui.nine(self, Rect2(0, 0, 44, 44), Art.sprite_or("badge_count"))
		d["badgeText"] = PxText.make(self, Vector2.ZERO, "", L.TEXT, "plain", "w")
		(d["badgeText"] as PxText).fit_width = 40.0   # tab.badge
		_slots.append(d)
	_layout_tabs()


## mobile-first §5.3: the plate full bleed; per slot the icon (60 × 60) centred at slot_w/2 − 30,
## y 8; the label centred at y 64 in a slot_w − 16 box; the badge at the icon's top-left (RTL
## trailing); the active plate inset 12 each side. `_tab_dy` is the C1 slide.
func _layout_tabs() -> void:
	var y := L.tabs_y() + _tab_dy
	Ui.set_nine_rect(_tabbar, Rect2(0, y, L.cw + 4.0, L.TABS_H))
	for i in 4:
		var d: Dictionary = _slots[i]
		var r := L.tab_rect(i + 1)
		var w := L.tab_w()
		if i == 3:
			r = Rect2(r.end.x - w, r.position.y, w, r.size.y)   # slot 4's visuals: its own width, the remainder is plate
		Ui.set_nine_rect(d["plate"], Rect2(r.position.x + 12, y, w - 24.0, L.TABS_H))
		var ic: Sprite2D = d["icon"]
		var ix := Ui.snap(w / 2.0 - 30.0, 4)
		ic.position = Vector2(r.position.x + ix, y + 8.0)
		(d["lockedIcon"] as Sprite2D).position = ic.position
		var lk: Sprite2D = d["lock"]
		var lsz := Vector2(Art.sprite_size(lk.get_meta("sprite"))) * 4.0
		lk.position = Vector2(r.position.x + Ui.snap((w - lsz.x) / 2.0, 4), y + 64.0)   # where the label would sit
		var lb: PxText = d["label"]
		lb.fit_width = w - 16.0
		lb.position.y = y + 64
		lb.center_in(r.position.x, w)
		Ui.set_nine_rect(d["badge"], Rect2(r.position.x + ix - 16.0, y, 44, 44))
		(d["badgeText"] as PxText).position = Vector2(r.position.x + ix - 16.0, y + 4)
		(d["badgeText"] as PxText).center_in(r.position.x + ix - 16.0, 44)
	# D21: one divider per slot boundary (x = cw − i·w), the kit's rows 5-20 (logical 20-84)
	for i in _dividers.size():
		var dv := _dividers[i]
		dv.position = Vector2(L.cw - float(i + 1) * L.tab_w() - 2.0, y + 20.0)
		dv.size = Vector2(4, 64)
	_refresh_tabs()


## C1 (mobile-first §3.3): the bar slides up from `from_dy` px below its slot over the pane's
## last 104 px; the list keeps its scroll offset. Reduced motion never calls it (instant).
func slide_tabs(from_dy: float, sec: float) -> void:
	if _tab_tw:
		_tab_tw.kill()
	_tab_dy = from_dy
	_layout_tabs()
	_tab_tw = create_tween()
	_tab_tw.tween_method(func(v: float) -> void:
		_tab_dy = Ui.snap(v, 4)
		_layout_tabs(), from_dy, 0.0, sec).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


## ux/ftue.md: the bar appears at C1; each slot at its own reveal. Slots never move.
func set_tabs_revealed(bar: bool, slots: Array) -> void:
	_tabs_on = bar
	for i in 4:
		_slot_on[i] = bool(slots[i]) if i < slots.size() else false
	_refresh_tabs()


func _slot_shown(i: int) -> bool:
	return _visible_shop and _tabs_on and bool(_slot_on[i]) and bool(TAB_BUILT[i])


## D21: slot i (0-3) is on the bar but not revealed yet: it draws its locked silhouette.
func slot_locked(i: int) -> bool:
	return _visible_shop and _tabs_on and not _slot_shown(i)


func _refresh_tabs() -> void:
	_tabbar.visible = _visible_shop and _tabs_on
	for dv in _dividers:
		dv.visible = _tabbar.visible
	for i in 4:
		var d: Dictionary = _slots[i]
		var on := _slot_shown(i)
		var locked := slot_locked(i)
		(d["lockedIcon"] as Sprite2D).visible = locked
		(d["lock"] as Sprite2D).visible = locked
		var active: bool = on and (TABS[i] == tall if tall != "" else TABS[i] == tab)
		(d["plate"] as NinePatchRect).visible = active
		var ic: Sprite2D = d["icon"]
		ic.visible = on
		Ui.set_frame(ic, Art.sprite_or(TAB_ICONS[i] + ("_active" if active else "_idle")), 0)
		var lb: PxText = d["label"]
		lb.visible = on
		lb.tint = Art.col("w") if active else Color(0.788, 0.839, 0.949)
		(d["badge"] as NinePatchRect).visible = on and (d["badgeText"] as PxText).text != ""
		(d["badgeText"] as PxText).visible = (d["badge"] as NinePatchRect).visible


## The badge count on a slot ("" hides it).
func set_tab_badge(slot: int, text: String) -> void:
	var d: Dictionary = _slots[slot - 1]
	var bt: PxText = d["badgeText"]
	if bt.text == text:
		return
	bt.text = text
	var bg: NinePatchRect = d["badge"]
	bt.center_in(bg.position.x, 44)
	_refresh_tabs()


## The pane: P (the split), + the tab slot until C1 (mobile-first §3.3); the tab bar follows it.
## The cards stretch with the canvas (688 + dx).
func set_list_height(h: float) -> void:
	list_rect = Rect2(float(L.SHOP["listX"]), float(L.SHOP["listY"]), float(L.SHOP["listW"]) + L.dx, h)
	var g := minf(L.dx, 40.0)
	if not is_equal_approx(g, _pill_g) or _layout_dx != L.dx:
		_pill_g = g
		_layout_dx = L.dx
		PILL_RECT = Rect2((L.ROW["pill"] as Rect2).position, (L.ROW["pill"] as Rect2).size + Vector2(g, 0))
		for t: String in _rows:
			for v: Dictionary in _rows[t]:
				_layout_row(v)
	_clip.position = list_rect.position
	_clip.size = list_rect.size
	for i in _rules.size():
		var rl := _rules[i]
		rl.position = Vector2(RULE_INSET if i == 0 else L.cw - RULE_INSET - RULE_W, list_rect.position.y)
		rl.size = Vector2(RULE_W + (4.0 if i == 1 else 0.0), list_rect.size.y)   # the right one covers the < 4 px aspect remainder too (as the ticker panel)
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
	# the R-anchored side (plate, icon, name, line 2, owned badge, spin tag and bars): x + dx
	var rside := Node2D.new()
	content.add_child(rside)
	var plate := Ui.nine(rside, R["plate"], Art.sprite_or("card_plate"))
	var icon := Ui.img(rside, Vector2.ZERO, Art.PLACEHOLDER, 0, 4)
	var icon_flash := Sprite2D.new()
	icon_flash.centered = false
	icon_flash.scale = Vector2(4, 4)
	icon_flash.visible = false
	icon_flash.material = Ui.fill_material(Art.col(th["row"]["affordFlash"]))
	rside.add_child(icon_flash)
	var name := PxText.make(rside, Vector2(float(R["nameRight"]), float(R["nameY"])), "", L.TEXT, "plain", "w")
	var line2 := PxText.make(rside, Vector2(float(R["line2Right"]), float(R["line2Y"])), "", L.TEXT, "plain", "w")
	line2.reading = true   # the card's description (line 2): the @2 reading cut where crisp
	for t: PxText in [name, line2]:
		t.max_lines = 1
		t.h_anchor = 2
	name.wrap_width = float(R["nameW"])
	line2.wrap_width = float(R["line2W"])
	# the owned badge (rtl-map §6.1, D4): a dark chip on the plate's bottom-left corner
	var orect: Rect2 = R["owned"]
	var owned_bg := Ui.rect(rside, orect, th["scrim"], 0.85)
	owned_bg.visible = false
	var owned := PxText.make(rside, Vector2(orect.position.x, orect.position.y + 2.0), "", L.TEXT, "plain", "w")
	owned.fit_width = orect.size.x - 8.0   # card.owned 96
	var pill := Ui.nine(content, PILL_RECT, Art.sprite_or("pay_pill_default"))
	var fill := Ui.nine(content, Rect2(PILL_RECT.end.x - 16, PILL_RECT.position.y + 8, 8, PILL_RECT.size.y - 24), Art.sprite_or("pay_pill_fill"))
	var pill1 := PxText.make(content, Vector2(PILL_RECT.position.x, float(R["pillLine1Y"])), "", L.TEXT, "plain", "w")
	var pill2 := PxText.make(content, Vector2(PILL_RECT.position.x, float(R["pillLine2Y"])), "", L.TEXT, "plain", "w")
	for t: PxText in [pill1, pill2]:
		t.fit_width = PILL_RECT.size.x - 16.0   # large text: ×5 only inside the pill, else ×4
	var flash := Ui.rect(c, Rect2(lx, 0, lw, row_h), th["row"]["affordFlash"], 0.0)
	var dim := Ui.fade_rect(c, Rect2(lx, 0, lw, row_h), th["scrim"])
	var glint := Ui.rect(c, Rect2(lx, 4, 8, row_h - 8), th["row"]["affordFlash"], 0.0)
	# S08's card-only bars (Spins.card bars): one split track under line 2, "public" from the right
	var sb: Rect2 = SPIN_BARS
	# a spin's tag ("שחוק", a line's "1/5"): a stamp over the plate's bottom edge (rtl-map §6.1)
	var tag_bg := Ui.rect(rside, SPIN_TAG, th["scrim"], 0.85)
	var tag := PxText.make(rside, Vector2(SPIN_TAG.position.x, SPIN_TAG.position.y + 2.0), "", L.TEXT, "plain", "w")
	tag.fit_width = SPIN_TAG.size.x - 8.0
	tag_bg.visible = false
	tag.visible = false
	var bar_pub := Ui.rect(rside, sb, Art.col(SPIN_BAR_PUBLIC))
	var bar_fr := Ui.rect(rside, Rect2(sb.position, Vector2(0, sb.size.y)), Art.col(SPIN_BAR_FRIENDLY))
	bar_pub.visible = false
	bar_fr.visible = false
	# the milestone pieces (MS_*): the track and its fill, the label, the gold chip, the gold pulse
	var ms_track := Ui.rect(rside, Rect2(SPIN_BARS.position.x, MS_BAR_Y, 8, MS_BAR_H), C_MS_TRACK)
	var ms_fill := Ui.rect(rside, Rect2(SPIN_BARS.position.x, MS_BAR_Y, 0, MS_BAR_H), C_MS_GOLD)
	var ms_label := PxText.make(rside, Vector2(SPIN_BARS.position.x, float(R["nameY"])), "", L.TEXT, "plain", C_MS_GOLD)
	ms_label.max_lines = 1
	ms_label.fit_width = MS_LABEL_W
	var ms_tag_bg := Ui.rect(rside, Rect2(0, 0, 48, MS_TAG_H), C_MS_GOLD)
	var ms_tag := PxText.make(rside, Vector2.ZERO, "", L.TEXT, "plain", C_MS_INK)
	var ms_flash := Ui.rect(c, Rect2(lx, 0, lw, row_h), C_MS_GOLD, 0.0)
	for n: CanvasItem in [ms_track, ms_fill, ms_label, ms_tag_bg, ms_tag]:
		n.visible = false
	c.visible = false
	return {
		"c": c, "panel": panel, "content": content, "rside": rside, "plate": plate, "icon": icon, "iconFlash": icon_flash,
		"barPublic": bar_pub, "barFriendly": bar_fr, "tag": tag, "tagBg": tag_bg,
		"msTrack": ms_track, "msFill": ms_fill, "msLabel": ms_label, "msTagBg": ms_tag_bg, "msTag": ms_tag, "msFlash": ms_flash,
		"msSegs": [], "msMult": -1.0, "msCelebT": -1.0,
		"name": name, "line2": line2, "owned": owned, "ownedBg": owned_bg, "pill": pill, "fill": fill, "pill1": pill1, "pill2": pill2,
		"flash": flash, "dim": dim, "glint": glint, "index": k, "model": {"kind": "none", "id": ""}, "key": "",
		"afford": null, "glintReadyAt": 0.0, "pressP": 0.0, "pressed": false, "shakeT": -1.0, "hopT": -1.0,
		"popT": -1.0, "upgradePopT": -1.0, "tintUntil": 0.0, "pillWasPressed": false, "pillNoRebound": false,
		"pillReboundT": -1.0, "helloT": -1.0, "helloLast": -1e9, "cascadeAt": -1.0, "rippleAt": -1.0, "glintT": -1.0,
		"iconBase": Vector2.ZERO, "pricePx": 4,
	}


## mobile-first §4.1 / §5.1 for one row: the R side at x + dx, the name and line-2 boxes grow by
## dx − the pill's growth (never narrower than at 720), the flash / dim / glint span the card.
func _layout_row(v: Dictionary) -> void:
	var R: Dictionary = L.ROW
	var lx := float(L.SHOP["listX"])
	var lw := float(L.SHOP["listW"]) + L.dx
	var row_h := float(L.SHOP["rowVisualH"])
	var grow := L.dx - _pill_g
	(v["rside"] as Node2D).position.x = L.dx
	(v["name"] as PxText).wrap_width = float(R["nameW"]) + grow
	for k in ["flash", "dim", "msFlash"]:
		var r: ColorRect = v[k]
		r.position = Vector2(lx, 0)
		r.size = Vector2(lw, row_h)
	var sb := SPIN_BARS
	(v["barPublic"] as ColorRect).position.x = sb.position.x - grow
	var pill: NinePatchRect = v["pill"]
	Ui.set_nine_rect(pill, PILL_RECT)
	for t: PxText in [v["pill1"], v["pill2"]]:
		t.fit_width = PILL_RECT.size.x - 16.0
	v["key"] = ""   # re-render: the line-2 box, the price scale and the pill text follow


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
			_append_teasers(out, s)
			return out
		var pr := Economy.producer_rows(s, _visible_shop)   # M2: the fill keys on card 1 being shown
		for id: String in pr["revealed"]:
			out.append({"kind": "producer", "id": id})
		if pr["silhouette"] != "":
			out.append({"kind": "silhouette", "id": pr["silhouette"]})
		var j := 0
		for id: String in pr.get("fill", PackedStringArray()):
			out.append({"kind": "teaser", "id": id, "t": j})
			j += 1
		return out
	var ids: Array = _frozen_upgrades if not _frozen_upgrades.is_empty() else Economy.available_upgrades(s).map(func(u: Dictionary) -> String: return u["id"])
	return ids.map(func(id: String) -> Dictionary: return {"kind": "upgrade", "id": id})


## mobile-first §5.4 (D38, G1 `producerReveal.fillSilhouettes`; the sim's producer_rows().fill
## outside the first card): after card 1, one teaser row per source still to come.
static func _append_teasers(out: Array, _s: GameState) -> void:
	if not bool((Content.data().get("producerReveal", {}) as Dictionary).get("fillSilhouettes", false)):
		return
	var shown := {}
	for m: Dictionary in out:
		shown[str(m["id"])] = true
	var j := 0
	for id: String in Content.producer_ids():
		if not shown.has(id):
			out.append({"kind": "teaser", "id": id, "t": j})
			j += 1


## B9 (mobile-first §5.4): teaser j's opacity. The first is the whole pale slip carrying the one-line
## hint; the rest are wordless slips fading down the pane (never under 0.2: each still paints its
## slip and silhouette, so the pane keeps no empty band, §0 rule 4).
static func teaser_alpha(j: int) -> float:
	if j >= TEASER_PLATE_ONLY_FROM:
		return 0.2   # M3: the plate alone, at the floor
	return maxf(0.2, pow(0.62, float(maxi(0, j))))


## Merge review M3 (D57): teaser j ≥ 3 (the rows on the 0.2 floor, 0.62³ = 0.24) draws only its
## silhouette plate on the ruled white field: no slip fill and no slip outline, so the pane reads
## "one hint, two fading slips, then a few faint figures on the sheet", not a grid of empty forms.
const TEASER_PLATE_ONLY_FROM := 3


static func teaser_slip(j: int) -> bool:
	return j < TEASER_PLATE_ONLY_FROM


## B9: the name line of teaser j: the hint on the first, nothing on the rest (six identical
## "מקור עלום" rows read as filler).
static func teaser_name(j: int) -> String:
	return Strings.s("ROW_TEASER_HINT") if j == 0 else ""


## Rows of `kind` fully inside the pane (the web probe: the pane's filled rows).
func rows_in_view(kinds: Array) -> int:
	var n := 0
	var views: Array = _rows["producers"]
	if tab != "producers":
		return 0
	for k in views.size():
		var v: Dictionary = views[k]
		if (v["c"] as Node2D).visible and kinds.has(str(v["model"]["kind"])) and row_screen_y(k, "producers") >= 0.0:
			n += 1
	return n


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
	return Vector2(L.ROW["iconCenter"]) + Vector2(L.dx, _row_top(k, tab))


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
		var last := models_p.size() - 1
		while last > 0 and models_p[last]["kind"] == "teaser":
			last -= 1
		_maybe_auto_scroll(last)
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
			_clip_pill(v, y)
		if t == "upgrades":
			for e in _empty:
				e.visible = models.is_empty()
	_update_scroll(s, dt_ms)
	_update_tab_anim(dt_ms)
	_update_nudge(dt_ms, animate_reveal)


## Review U13: the owned chip for a label `text_w` px wide, card-local (R side): w = text + 16
## (min 48), h 40, its left and bottom edges where the old fixed chip had them (x 572, y 116).
static func owned_rect(text_w: float) -> Rect2:
	var o: Rect2 = L.ROW["owned"]
	var w := maxf(48.0, Ui.snap(text_w + 16.0, 4))
	return Rect2(o.position.x, o.end.y - 40.0, w, 40.0)


## Review U6 (mobile-first §0 rule 5, S7): a row the pane cuts shows no pill (a tappable
## half-button); plate, icon and name only, and the pill appears once it is fully in.
func _clip_pill(v: Dictionary, y: float) -> void:
	var shown := pill_whole(y)
	v["pillCut"] = not shown
	if shown:
		(v["pill1"] as PxText).visible = true
		(v["pill2"] as PxText).visible = true
		return
	for n: CanvasItem in [v["pill"], v["fill"], v["pill1"], v["pill2"]]:
		n.visible = false


## True when the pill of a row whose top is at `y` (`_lower`-local) lies wholly inside the pane.
func pill_whole(y: float) -> bool:
	return y + PILL_RECT.position.y >= list_rect.position.y - 0.5 and y + PILL_RECT.end.y <= list_rect.end.y + 0.5


## The pills the pane shows (web probe, S7): [top, bottom, visible] in `_lower`-local y for every
## row that is at least partly in the pane (source cards, the locked row, the teasers).
func pill_rects() -> Array:
	var out: Array = []
	var views: Array = _rows[tab] if _rows.has(tab) else []
	for v: Dictionary in views:
		var c: Node2D = v["c"]
		if not c.visible:
			continue
		var y := c.position.y
		if y + float(L.SHOP["rowVisualH"]) <= list_rect.position.y or y >= list_rect.end.y:
			continue
		out.append([y + PILL_RECT.position.y, y + PILL_RECT.end.y, (v["pill"] as NinePatchRect).visible and (v["pill2"] as PxText).visible])
	return out


func _badge_label(n: int) -> String:
	return "" if n <= 0 else Strings.s("TAB_BADGE", {"count": "9+" if n > 9 else str(n)})


## Review U7: a silhouette's pale cut on the pale slip (`<silhouette>_pale`: a ui_dim mask with a
## ui_rule edge, drawn unmodulated), when the pipeline ships one; else the silhouette itself.
static func pale_sil(sil: String) -> String:
	if not Art.has_sprite("card_row_silhouette"):
		return sil
	return sil + "_pale" if Art.has_sprite(sil + "_pale") else sil


func _card_sprite(kind: String, afford: bool) -> String:
	match kind:
		"silhouette", "teaser":
			# review U7 (style guide §17.3): a blank pale slip on the white pane (ui_mute face,
			# ui_rule edge), not the slate locked card
			return "card_row_silhouette" if Art.has_sprite("card_row_silhouette") else Art.sprite_or("card_source_locked")
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
	var ms: Dictionary = {}
	var id: String = m["id"]
	match String(m["kind"]):
		"producer":
			var q := Economy.quote(s, id)
			afford = q["affordable"]
			price = float(q["cost"])
			var ska := LeaderUi.producer_art(id)   # the round's leader skin (spec §5.3)
			icon = Art.sprite_or(str(ska["icon"]) if not ska.is_empty() else String(Content.producer(id).get("icon", Art.source(id).get("icon", "icon_" + id))))
			nm = Strings.producer_name(id)
			var owned := s.owned_of(id)
			ms = milestone_model(owned)
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
			var sks := LeaderUi.producer_art(id)
			icon = pale_sil(Art.sprite_or(str(sks["silhouette"]) if not sks.is_empty() else String(Content.producer(id).get("silhouette", Art.source(id).get("silhouette", "sil_" + id)))))
			nm = Strings.s("ROW_LOCKED_NAME")
			line2 = Strings.s("CARD_LOCKED_CAP")
			wide = true
			price = float(Economy.quote(s, id, 1)["cost"])
			l1 = Strings.s("CARD_VERB_FIRST")
			l2 = Strings.s("CARD_PRICE", {"price": Fmt.cost(price)})
		"teaser":
			# mobile-first §5.4: the silhouette, "מקור עלום", no price, no pill, not a target
			var skt := LeaderUi.producer_art(id)
			icon = pale_sil(Art.sprite_or(str(skt["silhouette"]) if not skt.is_empty() else String(Content.producer(id).get("silhouette", Art.source(id).get("silhouette", "sil_" + id)))))
			nm = teaser_name(int(m.get("t", 0)))   # B9: the hint once, then wordless slips
			wide = true
		"buymode":
			nm = Strings.s("BUYMODE_LABEL")
			afford = true
			var bm2: Variant = s.buy_mode
			l2 = Strings.s("BUYMODE_1" if (bm2 is int and bm2 == 1) else ("BUYMODE_10" if (bm2 is int and bm2 == 10) else "BUYMODE_MAX"))
			# the list's head carries the all-sources goal (MS_*): its line 2 and one segment per source
			ms = all_milestone_model(s)
			if int(ms["next"]) > 0:
				line2 = Strings.s("SHOP_ALL_MS", {"n": str(int(ms["next"])), "gmult": ms_mult_text(float(ms["nextMult"]))})
			wide = true
		_:
			# the sim's price and buy rule (sim/README "Buy a spin"): a line's next level, S07's
			# income-scaled price; never u.cost / s.upgrades (a consumable or a line is never there)
			var u := Content.upgrade(id)
			var card := spin_card(s, id, d)
			price = float(card["price"])
			afford = bool(card["canBuy"])
			var ski := LeaderUi.spin_icon(id)   # spec §5.4: the skin's icon, else spin_slot_<slot>
			icon = Art.sprite_or(ski if ski != "" else String(u.get("icon", "icon_" + id)))
			nm = Strings.upgrade_name(id)
			line2 = spin_line2(id, card)
			tag_s = String(card["tag"])
			wide = true
			l1 = Strings.s("SPIN_VERB")
			l2 = Strings.s("CARD_PRICE", {"price": Fmt.cost(price)}) if price >= 0.0 else Strings.s("SPIN_OWNED")
			bars = card.get("bars", {})
	var key := "%s:%s" % [m["kind"], id]
	var ic: Sprite2D = v["icon"]
	var is_btn: bool = m["kind"] == "buymode"
	var teaser: bool = m["kind"] == "teaser"
	# v4 (style guide F14): the pane is the white field, so a teaser is the locked card at full
	# opacity (a 50% card would put its white text straight on white); it reads dim by its sprite,
	# its muted icon and name, and the missing pill
	(v["c"] as Node2D).modulate.a = teaser_alpha(int(m.get("t", 0))) if teaser else 1.0   # B9: fading down
	var fresh := false
	if v["key"] != key:
		fresh = true
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
	# line 2: x 220-568 beside the owned badge, x 220-580 without it (string-budgets card.line2*)
	var l2t: PxText = v["line2"]
	l2t.wrap_width = float(R["line2WideW"] if wide else R["line2W"]) + L.dx - _pill_g
	l2t.position.x = float(R["line2WideRight"] if wide else R["line2Right"])
	(v["name"] as PxText).text = nm
	l2t.text = line2
	var ot: PxText = v["owned"]
	ot.text = owned_s
	# review U13: the chip is sized to its text (text + 16, min 48, h 40) at the plate's bottom-left
	# corner, so it covers the portrait's corner, not its torso
	var orect := owned_rect(float(ot.width()))
	var obg: ColorRect = v["ownedBg"]
	obg.position = orect.position
	obg.size = orect.size
	ot.position.y = orect.position.y + Ui.snap((orect.size.y - 9.0 * float(ot.eff_px())) / 2.0, 2)   # as the slip's tag
	ot.center_in(orect.position.x, orect.size.x)   # re-centred every render: large text changes the width
	obg.visible = owned_s != ""
	if v["afford"] == false and afford and active and _visible_shop and not is_btn:
		if _now >= float(v["glintReadyAt"]):
			v["glintReadyAt"] = _now + float(Tune.T["affordGlintCooldownMs"])
			if not reduced_motion:
				v["glintT"] = 0.0
				_start_hello(v)
			became_affordable.emit()
	v["afford"] = afford
	Ui.set_nine_frame(v["panel"], _card_sprite(m["kind"], afford), 0)
	(v["panel"] as NinePatchRect).visible = not teaser or teaser_slip(int(m.get("t", 0)))   # M3: the plate alone past j 3
	# the pill: gold when affordable (pressed while held); a sunken well with a dim fill otherwise
	var pill_id := "button_secondary_default" if is_btn else ("pay_pill_pressed" if (afford and v["pressed"]) else ("pay_pill_default" if afford else "pay_pill_track"))
	Ui.set_nine_frame(v["pill"], Art.sprite_or(pill_id), 0)
	var fill: NinePatchRect = v["fill"]
	fill.visible = not afford and price > 0.0 and not is_btn and not teaser
	(v["pill"] as NinePatchRect).visible = not teaser
	if fill.visible:
		var inner := Rect2(PILL_RECT.position + Vector2(8, 8), PILL_RECT.size - Vector2(16, 24))
		var w := maxf(8.0, Ui.snap(inner.size.x * clampf(s.bananas / price, 0.0, 1.0), 4))
		Ui.set_nine_rect(fill, Rect2(L.bar_x(inner, w), inner.position.y, w, inner.size.y))
	var ink := Art.col("w") if (afford or is_btn) else Color(0.78, 0.74, 0.62)
	var p1: PxText = v["pill1"]
	var p2: PxText = v["pill2"]
	p1.text = l1
	# mobile-first §5.1: the price at ×5 when it fits the pill box (the verb stays ×4); large
	# text keeps ×4 here and steps it up by its own rule
	var ppx := 5 if (not is_btn and PxText.body_scale() == L.TEXT and PxText.measure(l2, 5) <= int(PILL_RECT.size.x - 16.0)) else L.TEXT
	v["pricePx"] = ppx
	p2.px = ppx
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
	ic.modulate = Color.WHITE if (m["kind"] == "silhouette" or teaser or afford) else Color(0.6, 0.6, 0.6)
	(v["name"] as PxText).tint = Art.col("w") if (afford or is_btn) else Color(0.827, 0.839, 0.875)
	(v["line2"] as PxText).tint = Color(0.78, 0.9, 0.62) if afford else Color(0.788, 0.839, 0.949)
	if (m["kind"] == "silhouette" or teaser) and Art.has_sprite("card_row_silhouette"):
		# U7: the pale slip's text is ui_panel (8.9:1 on its ui_mute face)
		(v["name"] as PxText).tint = C_SIL_TEXT
		(v["line2"] as PxText).tint = C_SIL_TEXT
	(v["owned"] as PxText).tint = Color(0.827, 0.839, 0.875)
	_render_bars(v, bars)
	_watch_milestone(v, ms, fresh)
	_render_ms(v, ms, afford)
	var tg: PxText = v["tag"]
	# the stamp on the ballot slip (animator wave B): a tag that appears or changes on the same card
	# (a line's "1/5" → "2/5" after a buy, "שחוק") slams like the chat's pay-pill stamp; a card that
	# only scrolled or changed tab keeps its tag still
	var tkey := "%s:%s" % [m["kind"], id]
	if tag_s != str(v.get("tagText", "")):
		var same := str(v.get("tagKey", "")) == tkey
		v["tagSlam"] = 0.0 if (same and tag_s != "" and not reduced_motion) else -1.0
		if same and tag_s != "" and get_node_or_null("../../..") != null and get_node("../../..").has_method("audio_event"): get_node("../../..").call("audio_event", "slipStamp")   # Audio v1.4: the thunk on f0 (×6), on the cut in reduced motion; main is 3 up (_lower, _root); a no-op without it or the cue
		v["tagText"] = tag_s
	v["tagKey"] = tkey
	tg.text = tag_s
	tg.visible = tag_s != ""
	(v["tagBg"] as ColorRect).visible = tg.visible
	_place_tag(v)


## The slip's stamp at its slam step (TAG_SLAM: integer text scale 6 → 5 → 4 over 90 ms, the backing
## growing with it around the tag's centre in 4-px steps; a transient under 180 ms). At rest: ×4 in
## SPIN_TAG.
func _place_tag(v: Dictionary) -> void:
	var tg: PxText = v["tag"]
	var bg: ColorRect = v["tagBg"]
	var px := tag_slam_px(float(v.get("tagSlam", -1.0)))
	var c := SPIN_TAG.get_center()
	var sz := Vector2(Ui.snap(SPIN_TAG.size.x * float(px) / float(L.TEXT), 4), Ui.snap(SPIN_TAG.size.y * float(px) / float(L.TEXT), 4))
	bg.position = Vector2(Ui.snap(c.x - sz.x / 2.0, 4), Ui.snap(c.y - sz.y / 2.0, 4))
	bg.size = sz
	if tg.px != px:
		tg.px = px
	tg.center_in(bg.position.x, bg.size.x)
	tg.position.y = bg.position.y + Ui.snap((sz.y - 9.0 * float(px)) / 2.0, 2)   # at rest: SPIN_TAG.y + 2


## The stamp's text scale `t` ms into its slam (-1 = at rest): 6 for 30 ms, 5 for 30, then 4.
static func tag_slam_px(t: float) -> int:
	if t < 0.0 or t >= 3.0 * TAG_SLAM_STEP_MS:
		return L.TEXT
	return L.TEXT + 2 - int(t / TAG_SLAM_STEP_MS)


## S08's split bar: "public" from the right (the RTL fill side), the drained share after it.
func _render_bars(v: Dictionary, bars: Dictionary) -> void:
	var pub: ColorRect = v["barPublic"]
	var fr: ColorRect = v["barFriendly"]
	pub.visible = not bars.is_empty()
	fr.visible = pub.visible
	if not pub.visible:
		return
	var grow := L.dx - _pill_g
	var sb := Rect2(SPIN_BARS.position.x - grow, SPIN_BARS.position.y, SPIN_BARS.size.x + grow, SPIN_BARS.size.y)
	var wp := Ui.snap(sb.size.x * clampf(float(bars.get("public", 100.0)) / 100.0, 0.0, 1.0), 4)
	pub.position = Vector2(L.bar_x(sb, wp), sb.position.y)
	pub.size = Vector2(wp, sb.size.y)
	var wf := sb.size.x - wp
	fr.position = Vector2(sb.position.x if L.RTL else sb.position.x + wp, sb.position.y)
	fr.size = Vector2(wf, sb.size.y)


## MS_*: a source's milestone state from the sim's reads ({} before the first one is owned):
## {kind "one", owned, mult (the ×2s so far), next (-1 past the last), nextMult (that milestone's own factor)}.
static func milestone_model(owned: int) -> Dictionary:
	if owned <= 0:
		return {}
	var nxt := Meta.next_milestone(owned)
	var nm := 1.0
	for e: Dictionary in Content.data().get("milestones", {}).get("perProducer", []):
		if int(e["owned"]) == nxt:
			nm = float(e["mult"])
			break
	return {"kind": "one", "owned": owned, "mult": Meta.milestone_mult(owned), "next": nxt, "nextMult": nm}


## MS_*: the all-sources goal: {kind "all", mult (so far), next (the next allProducers count above
## the lowest owned, -1 past the last), nextMult, fracs (per source, content order: min(owned, next) / next)}.
static func all_milestone_model(s: GameState) -> Dictionary:
	var lo := Meta.min_owned(s)
	var nxt := -1
	var nm := 1.0
	for e: Dictionary in Content.data().get("milestones", {}).get("allProducers", []):
		if lo < int(e["owned"]):
			nxt = int(e["owned"])
			nm = float(e["mult"])
			break
	var fr: Array = []
	if nxt > 0:
		for pid: String in Content.producer_ids():
			fr.append(clampf(float(s.owned_of(pid)) / float(nxt), 0.0, 1.0))
	return {"kind": "all", "mult": Meta.all_producers_mult(s), "next": nxt, "nextMult": nm, "fracs": fr}


## "2", "32", "1.25": a multiplier without trailing zeros (the ×N chips and labels).
static func ms_mult_text(m: float) -> String:
	if is_equal_approx(m, roundf(m)):
		return str(int(roundf(m)))
	return ("%.2f" % m).rstrip("0").rstrip(".")


## A row whose milestone multiplier grew since the last frame (same card, same model) celebrates;
## a row that just took a new model (a scroll, a reveal shift, a load, a new round) only learns it.
func _watch_milestone(v: Dictionary, ms: Dictionary, fresh: bool) -> void:
	if ms.is_empty():
		v["msMult"] = -1.0
		return
	var mm := float(ms["mult"])
	var was := float(v["msMult"])
	v["msMult"] = mm
	if not fresh and was > 0.0 and mm > was + 1e-9:
		_start_ms_celeb(v)


func _start_ms_celeb(v: Dictionary) -> void:
	v["msCelebT"] = 0.0


func ms_celebrating(v: Dictionary) -> bool:
	return float(v.get("msCelebT", -1.0)) >= 0.0


## The milestone pieces of one row (MS_*): the source's track, label and chip, or the head row's
## segments; everything hidden on any other row.
func _render_ms(v: Dictionary, ms: Dictionary, afford: bool) -> void:
	var track: ColorRect = v["msTrack"]
	var fill: ColorRect = v["msFill"]
	var lab: PxText = v["msLabel"]
	var tag: PxText = v["msTag"]
	var tag_bg: ColorRect = v["msTagBg"]
	var kind := str(ms.get("kind", ""))
	var nxt := int(ms.get("next", -1))
	var R: Dictionary = L.ROW
	var box_l := float(R["nameRight"]) - float(R["nameW"]) - (L.dx - _pill_g)   # the text box's left edge (220 − grow)
	var gold := C_MS_GOLD if afford else C_MS_GOLD_DIM
	# a crossing (not under reduced motion): the bar shows the goal reached, full and pale, for the
	# two pulses, then drops to the next goal's progress
	var full := ms_celebrating(v) and not reduced_motion and float(v["msCelebT"]) < 450.0
	var bar_col := Art.col("w") if full else gold
	_render_segments(v, Rect2(box_l, MS_BAR_Y, MS_BAR_RIGHT_WIDE - box_l, MS_BAR_H), ms.get("fracs", []) if (kind == "all" and nxt > 0) else [], bar_col, full)
	var one := kind == "one"
	track.visible = one and nxt > 0
	fill.visible = track.visible
	lab.visible = false
	tag.visible = false
	tag_bg.visible = false
	if kind == "all":
		(v["line2"] as PxText).tint = gold
		return
	if not one:
		return
	if nxt > 0:
		var bar := Rect2(box_l, MS_BAR_Y, MS_BAR_RIGHT - box_l, MS_BAR_H)
		track.position = bar.position
		track.size = bar.size
		var w := bar.size.x if full else Ui.snap(bar.size.x * clampf(float(ms["owned"]) / float(nxt), 0.0, 1.0), 4)
		fill.position = Vector2(L.bar_x(bar, w), bar.position.y)
		fill.size = Vector2(w, bar.size.y)
		fill.color = bar_col
		# the label: the full form where it clears the name by 16, else the count, else nothing
		var nm: PxText = v["name"]
		var room := float(R["nameRight"]) - (float(nm.width()) if nm.text != "" else 0.0) - MS_GAP - box_l
		var p := {"owned": Fmt.owned(int(ms["owned"])), "next": str(nxt), "mult": ms_mult_text(float(ms["nextMult"]))}
		for k: String in ["CARD_MS_NEXT", "CARD_MS_SHORT"]:
			lab.text = Strings.s(k, p)
			if float(lab.width()) <= room:
				lab.visible = true
				break
		lab.h_anchor = 0
		lab.position = Vector2(box_l, float(R["nameY"]))
		lab.tint = gold
	var mm := float(ms["mult"])
	if mm <= 1.0 + 1e-9:
		return
	# the chip: after line 2's rate in reading order (to its left), 12 px clear of it; where a long
	# rate leaves no room, the name row's left slot when the label is not using it (past the last
	# milestone it never is); else no chip (the rate already includes it)
	tag.text = Strings.s("CARD_MS_MULT", {"mult": ms_mult_text(mm)})
	var l2: PxText = v["line2"]
	var cw := maxf(48.0, Ui.snap(float(tag.width()) + 16.0, 4))
	var cx := floorf((l2.position.x - float(l2.width()) - 12.0 - cw) / 4.0) * 4.0
	var cy := float(R["line2Y"]) - 4.0
	if cx < box_l:
		var nmw := float((v["name"] as PxText).width())
		if lab.visible or box_l + cw + MS_GAP > float(R["nameRight"]) - nmw:
			return
		cx = box_l
		cy = float(R["nameY"]) - 4.0
	v["msTagRect"] = Rect2(cx, cy, cw, MS_TAG_H)
	tag.visible = true
	tag_bg.visible = true
	tag_bg.color = gold
	_place_ms_tag(v)


## The chip at rest, or at its slam step while a crossing plays (×6 → ×5 → ×4 over 90 ms, the
## backing growing around its centre in 4-px steps, as the spin slip's stamp).
func _place_ms_tag(v: Dictionary) -> void:
	var r: Rect2 = v.get("msTagRect", Rect2())
	var tag: PxText = v["msTag"]
	var bg: ColorRect = v["msTagBg"]
	var px := tag_slam_px(float(v["msCelebT"])) if (ms_celebrating(v) and not reduced_motion) else L.TEXT
	var c := r.get_center()
	var sz := Vector2(Ui.snap(r.size.x * float(px) / float(L.TEXT), 4), Ui.snap(r.size.y * float(px) / float(L.TEXT), 4))
	bg.position = Vector2(Ui.snap(c.x - sz.x / 2.0, 4), Ui.snap(c.y - sz.y / 2.0, 4))
	bg.size = sz
	if tag.px != px:
		tag.px = px
	tag.center_in(bg.position.x, bg.size.x)
	tag.position.y = bg.position.y + Ui.snap((sz.y - 9.0 * float(tag.eff_px())) / 2.0, 2)


## The head row's segments: one per source, right to left in content order (RTL), 4 px apart.
func _render_segments(v: Dictionary, bar: Rect2, fracs: Array, col: Color, full: bool) -> void:
	var segs: Array = v["msSegs"]
	var n := fracs.size()
	var rside: Node2D = v["rside"]
	while segs.size() < n:
		var tr := Ui.rect(rside, Rect2(0, MS_BAR_Y, 8, MS_BAR_H), C_MS_TRACK)
		var fl := Ui.rect(rside, Rect2(0, MS_BAR_Y, 0, MS_BAR_H), C_MS_GOLD)
		segs.append([tr, fl])
	for i in segs.size():
		for r: ColorRect in segs[i]:
			r.visible = i < n
	if n == 0:
		return
	var sw := floorf((bar.size.x - MS_SEG_GAP * float(n - 1)) / float(n) / 4.0) * 4.0
	for i in n:
		var x := bar.end.x - float(i + 1) * sw - float(i) * MS_SEG_GAP if L.RTL else bar.position.x + float(i) * (sw + MS_SEG_GAP)
		var seg := Rect2(x, bar.position.y, sw, bar.size.y)
		var tr: ColorRect = segs[i][0]
		var fl: ColorRect = segs[i][1]
		tr.position = seg.position
		tr.size = seg.size
		var w := sw if full else Ui.snap(sw * float(fracs[i]), 4)
		fl.position = Vector2(L.bar_x(seg, w), seg.position.y)
		fl.size = Vector2(w, seg.size.y)
		fl.color = col


## The gold pulse's alpha `t` ms into a crossing: on 150, off 150, on 150, then a 350-ms fade
## (two flashes in 0.8 s, under the three-a-second line). Reduced motion: one 400-ms fade.
static func ms_pulse_alpha(t: float, reduced: bool) -> float:
	if t < 0.0:
		return 0.0
	if reduced:
		return 0.4 * maxf(0.0, 1.0 - t / MS_CELEB_REDUCED_MS)
	if t < 150.0:
		return 0.5
	if t < 300.0:
		return 0.0
	if t < 450.0:
		return 0.4
	return 0.4 * maxf(0.0, 1.0 - (t - 450.0) / (MS_CELEB_MS - 450.0))


## A spin card's line 2 (rtl-map §6.1): the effect label ({s} = a consumable's next duration); S08 (the split bars) at level ≥ 1 reads
## SPIN_BARS_LINE "ערוץ ידידותי: {pct}%" instead, naming the part of the bar that grows (R14).
static func spin_line2(id: String, card: Dictionary) -> String:
	var bars: Dictionary = card.get("bars", {})
	if not bars.is_empty() and int(card.get("level", 0)) >= 1:
		return Strings.s("SPIN_BARS_LINE", {"pct": int(roundf(float(bars.get("friendly", 0.0))))})
	# a consumable's line names what the next buy lasts (fatigue shortens a rebuy: 60, 48, 38 s)
	return Strings.upgrade_effect(id, {"s": int(roundf(float(card.get("nextSec", 0.0))))} if card.has("nextSec") else {})


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
	var out := {"price": float(c["price"]), "canBuy": Economy.can_buy_upgrade(s, id), "tag": tag, "kind": c["kind"],
		"level": int(c.get("level", 0))}
	if c.has("bars"):
		out["bars"] = c["bars"]
	if c.has("flightPct"):
		out["flightPct"] = c["flightPct"]
	if c.has("nextSec"):
		out["nextSec"] = c["nextSec"]
	return out


func _start_hello(v: Dictionary) -> void:
	if reduced_motion or v["pressed"]:
		return
	v["helloT"] = 0.0
	v["helloLast"] = _now


func _animate_row(v: Dictionary, dt_ms: float) -> void:
	if ms_celebrating(v):
		v["msCelebT"] = float(v["msCelebT"]) + dt_ms
		var tc: float = v["msCelebT"]
		var mf: ColorRect = v["msFlash"]
		mf.color.a = ms_pulse_alpha(tc, reduced_motion)
		if tc >= (MS_CELEB_REDUCED_MS if reduced_motion else MS_CELEB_MS):
			v["msCelebT"] = -1.0
			mf.color.a = 0.0
		if (v["msTag"] as PxText).visible:
			_place_ms_tag(v)
	if float(v.get("tagSlam", -1.0)) >= 0.0:
		v["tagSlam"] = float(v["tagSlam"]) + dt_ms
		if float(v["tagSlam"]) >= 3.0 * TAG_SLAM_STEP_MS:
			v["tagSlam"] = -1.0
		_place_tag(v)
	var S: Dictionary = L.SHOP
	var target := 1.0 if v["pressed"] else 0.0
	var dur := float(Tune.T["buyPressMs"] if v["pressed"] else Tune.T["buyReleaseMs"])
	var pp: float = v["pressP"]
	if pp != target:
		pp = minf(1.0, pp + dt_ms / dur) if target > pp else maxf(0.0, pp - dt_ms / dur)
		v["pressP"] = pp
	var lx := float(S["listX"])
	var lw := float(S["listW"]) + L.dx
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
		# a ×5 price sits 4 px higher so its ink stays inside the pill's well
		(v["pill2"] as PxText).position.y = float(L.ROW["pillLine2Y"]) + dy - (4.0 if int(v["pricePx"]) > L.TEXT else 0.0)


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
	return Ui.in_rect(Rect2(0, L.tabs_y(), L.cw, L.TABS_H), p)   # the bar swallows presses between slots


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
	var valid: bool = k >= 0 and k < rows.size() and not ["none", "teaser"].has(str(rows[k]["model"]["kind"])) and (rows[k]["c"] as Node2D).visible
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
		_thumb.modulate.a = 1.0 if active else 0.0   # D20: hidden when idle; the left rule stays as the track


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
			r["msMult"] = -1.0
			r["msCelebT"] = -1.0
			(r["msFlash"] as ColorRect).color.a = 0.0
