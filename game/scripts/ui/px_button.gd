class_name PxButton
extends RefCounted
## A pixel button: 9-slice + centred label + a literal hit rect (hud-layout §1: hits >= 104 px).
## motion-spec button-press: the pressed frame and the label drop are a cut at pointer-down;
## release cuts back after max(pointer-up, uiPressMinHoldMs). Commit = up inside. The 9-slice
## squishes on press (ui-juice.yaml J1 variant A) and rebounds over squishReboundMs.

const SQ := 8.0   # Tune.MC.squishPx
static var SQUISH_PRESS := Vector2(SQ, -SQ)
static var SQUISH_REBOUND: Array = [Vector2(-SQ, SQ), Vector2(-SQ, SQ), Vector2(0, SQ / 2.0), Vector2(0, SQ / 2.0), Vector2.ZERO]

var visual: Rect2
var hit: Rect2
var bg: NinePatchRect
var label: PxText
var kind := "button"      # button | danger | toggle | evolve
var ghost := false
var visible := true
var on_commit: Callable

var _enabled := true
var _pressed := false
var _hovered := false
var _on := true
var _press_ms := 0.0
var _release_wait := -1.0
var _label_y := 0.0


static func kinds() -> Dictionary:
	var th := Art.theme
	return {
		"button": {
			"normal": [th["button"]["sprite"], th["button"]["frames"]["normal"], th["button"]["label"]],
			"pressed": [th["button"]["sprite"], th["button"]["frames"]["pressed"], th["button"]["label"]],
			"hover": [th["button"]["sprite"], th["button"]["frames"]["hover"], th["button"]["label"]],
			"disabled": [th["button"]["sprite"], th["button"]["frames"]["disabled"], th["button"]["labelDisabled"]],
		},
		"danger": {
			"normal": [th["danger"]["sprite"], th["danger"]["frames"]["normal"], th["danger"]["label"]],
			"pressed": [th["danger"]["sprite"], th["danger"]["frames"]["pressed"], th["danger"]["label"]],
			"hover": [th["danger"]["sprite"], th["danger"]["frames"]["hover"], th["danger"]["label"]],
			"disabled": [th["danger"]["sprite"], th["danger"]["frames"]["normal"], th["danger"]["label"]],
		},
		"pill": {
			"normal": [th["pill"]["sprite"], th["pill"]["frames"]["buy"], th["pill"]["labelBuy"]],
			"pressed": [th["pill"]["sprite"], th["pill"]["frames"]["pressed"], th["pill"]["labelBuy"]],
			"hover": [th["pill"]["sprite"], th["pill"]["frames"]["buy"], th["pill"]["labelBuy"]],
			"disabled": [th["pill"]["sprite"], th["pill"]["frames"]["need"], th["pill"]["labelNeed"]],
		},
		# od-sevev: the 2D Artist's kit buttons (separate PNG per state, frame 0, white label)
		# review U2 (style guide §17.3): the v4 primary is the flag's white on its blue, a flag label
		"kit_primary": _kit_kind("button_white") if Art.has_sprite("button_white_default") else _kit_kind("button_primary"),
		"kit_secondary": _kit_kind("button_secondary"),
		"kit_gold": _kit_kind("button_gold"),
		"kit_danger": _kit_kind("button_danger") if Art.has_sprite("button_danger_default") else _kit_kind("button_secondary"),
		"evolve": {
			"normal": [th["evolve"]["ready"]["sprite"], th["evolve"]["ready"]["frames"]["normal"], th["evolve"]["labelReady"]],
			"pressed": [th["evolve"]["ready"]["sprite"], th["evolve"]["ready"]["frames"]["pressed"], th["evolve"]["labelReady"]],
			"hover": [th["evolve"]["ready"]["sprite"], th["evolve"]["ready"]["frames"]["hover"], th["evolve"]["labelReady"]],
			"disabled": [th["evolve"]["notReady"]["sprite"], th["evolve"]["notReady"]["frame"], th["evolve"]["labelNotReady"]],
		},
	}


static func _kit_kind(base: String) -> Dictionary:
	var d := base + "_default"
	var p := base + "_pressed" if Art.has_sprite(base + "_pressed") else d
	var x := base + "_disabled" if Art.has_sprite(base + "_disabled") else d
	var ok := Art.has_sprite(d)
	var fb: Array = [Art.theme["button"]["sprite"], Art.theme["button"]["frames"]["normal"], "w"]
	# the kit's label colour: ink on gold (money buttons; white on gold is unreadable), else white
	# and flag blue ("u", #0038b8, 8.5:1) on the white primary (review U2)
	var kl := str(Art.kit(d).get("label", ""))
	var lab := "k" if (kl == "ink" or base == "button_gold") else ("u" if kl == "flag" else "w")
	return {
		"normal": [d, 0, lab] if ok else fb, "pressed": [p, 0, lab] if ok else fb,
		"hover": [d, 0, lab] if ok else fb, "disabled": [x, 0, "w"] if ok else fb,
	}


## The label colour of a button kind in a state ("normal" | "pressed" | "hover" | "disabled"), for a
## view that draws its own label lines over the plate (the court's postpone, the picker's again).
static func label_color(kind_: String, state: String = "normal") -> Color:
	return Art.col(kinds()[kind_][state][2])


## Resizes a 9-slice drawn at `r` by (dw, dh) logical px: width centred, height anchored at the
## bottom (a press has weight) or the centre. (ox, oy) shift the whole rect.
static func squish_nine(ns: NinePatchRect, r: Rect2, dw: float, dh: float, ox: float = 0.0, oy: float = 0.0, anchor: String = "bottom") -> void:
	ns.size = Vector2((r.size.x + dw) / 4.0, (r.size.y + dh) / 4.0)
	var yoff := dh if anchor == "bottom" else 4.0 * floorf(dh / 8.0)
	ns.position = Vector2(r.position.x - 4.0 * floorf(dw / 8.0) + ox, r.position.y - yoff + oy)


static func make(parent: Node, visual_: Rect2, opts: Dictionary) -> PxButton:
	var b := PxButton.new()
	b.visual = visual_
	b.hit = opts.get("hit", visual_)
	b.kind = opts.get("kind", "button")
	b.ghost = opts.get("ghost", false)
	b.on_commit = opts.get("on_commit", Callable())
	var first: Array
	if b.kind == "toggle":
		first = [Art.theme["toggle"]["sprite"], Art.theme["toggle"]["frames"]["on"]]
	else:
		first = kinds()[b.kind]["normal"]
	b.bg = Ui.nine(parent, visual_, first[0], int(first[1]))
	b.bg.visible = not b.ghost
	if opts.has("label"):
		var s: int = opts.get("label_scale", 4)
		b._label_y = visual_.position.y + floorf((visual_.size.y - 7 * s) / 2.0 / 4.0) * 4.0
		var tint: Variant = Art.theme["toggle"]["labelOn"] if b.kind == "toggle" else kinds()[b.kind]["normal"][2]
		b.label = PxText.make(parent, Vector2(visual_.position.x, b._label_y), opts["label"], s, "plain", tint)
		# large text (rtl-map §0.2): ×5 only when the label fits the button's inner box, else ×4
		b.label.fit_width = float(opts.get("label_box", maxf(0.0, visual_.size.x - 16.0)))
		b._place_label()
	return b


func _place_label() -> void:
	if label == null:
		return
	if kind == "toggle":
		var r: Array = Art.theme["toggle"]["labelRegionArtPx"][0 if _on else 1]
		label.center_in(visual.position.x + float(r[0]) * 4.0, (float(r[1]) - float(r[0])) * 4.0)
	else:
		label.center_in(visual.position.x, visual.size.x)


func set_label(t: String) -> PxButton:
	if label:
		label.text = t
		_place_label()
	return self


func set_enabled(on: bool) -> PxButton:
	_enabled = on
	_refresh()
	return self


func is_enabled() -> bool:
	return _enabled and visible


func set_visible(v: bool) -> PxButton:
	visible = v
	bg.visible = v and not ghost
	if label:
		label.visible = v
	return self


func set_on(on: bool) -> PxButton:
	if kind != "toggle":
		return self
	_on = on
	var t: Dictionary = Art.theme["toggle"]
	Ui.set_nine_frame(bg, t["sprite"], int(t["frames"]["on" if on else "off"]))
	if label:
		label.tint = Art.col(t["labelOn" if on else "labelOff"])
	_place_label()
	return self


func contains(p: Vector2) -> bool:
	return is_enabled() and Ui.in_rect(hit, p)


func _squishes() -> bool:
	return not ghost and _enabled and not Juice.reduced


func down() -> void:
	if not is_enabled():
		return
	_pressed = true
	_press_ms = Time.get_ticks_msec()
	_release_wait = -1.0
	Juice.cancel(self)
	if _squishes():
		squish_nine(bg, visual, SQUISH_PRESS.x, SQUISH_PRESS.y)
	_refresh()


## Pointer-up; commits when inside.
func up(inside: bool) -> void:
	if not _pressed:
		return
	var held := Time.get_ticks_msec() - _press_ms
	var min_hold := float(Tune.MC["uiPressMinHoldMs"])
	if held >= min_hold:
		_finish()
	else:
		_release_wait = min_hold - held
		bg.get_tree().create_timer(_release_wait / 1000.0).timeout.connect(_finish)
	if inside and is_enabled() and on_commit.is_valid():
		on_commit.call()


func _finish() -> void:
	# the min-hold timer can fire after the button's nodes were freed (a rebuilt sheet, a closed
	# view, a test scene torn down): nothing left to release
	if not _pressed or not is_instance_valid(bg):
		return
	_pressed = false
	_refresh()
	_rebound()


func cancel() -> void:
	var was := _pressed
	_pressed = false
	_refresh()
	if was:
		_rebound()


func _rebound() -> void:
	if not is_instance_valid(bg):
		return
	if not _squishes():
		squish_nine(bg, visual, 0, 0)
		return
	Juice.play(self, float(Tune.MC["squishReboundMs"]),
		func(t: float) -> void:
			if is_instance_valid(bg):
				var d: Vector2 = Juice.sample(SQUISH_REBOUND, t)
				squish_nine(bg, visual, d.x, d.y),
		func() -> void:
			if is_instance_valid(bg):
				squish_nine(bg, visual, 0, 0))


func hover(on: bool) -> void:
	if _hovered == on:
		return
	_hovered = on
	_refresh()


func _refresh() -> void:
	var drop := float(Tune.MC["uiLabelPressDropArtPx"]) * 4.0
	if kind == "toggle":
		if label:
			label.position.y = _label_y + (drop if _pressed else 0.0)
		return
	var k: Dictionary = kinds()[kind]
	var look: Array = k["disabled"] if not _enabled else (k["pressed"] if _pressed else (k["hover"] if _hovered else k["normal"]))
	Ui.set_nine_frame(bg, look[0], int(look[1]))
	if not _enabled and not _pressed:
		squish_nine(bg, visual, 0, 0)
	if label:
		label.position.y = _label_y + (drop if (_pressed and _enabled) else 0.0)
		label.tint = Art.col(look[2])


func set_alpha(a: float) -> void:
	bg.modulate.a = a
	if label:
		label.modulate.a = a


## Moves the button (a relayout, mobile-first §4 anchors): the visual, the hit, the plate and the
## label (re-centred, its fit box following the new width).
func set_rects(visual_: Rect2, hit_: Rect2) -> void:
	visual = visual_
	hit = hit_
	if bg != null:
		Ui.set_nine_rect(bg, visual)
	if label != null:
		_label_y = visual.position.y + floorf((visual.size.y - 7 * label.px) / 2.0 / 4.0) * 4.0
		label.position.y = _label_y
		label.fit_width = maxf(0.0, visual.size.x - 16.0)
		_place_label()
