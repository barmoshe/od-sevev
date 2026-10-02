class_name MissionsChip
extends Node2D
## The missions entry point on the stage (sim: Missions; the sheet: ui/views/view_missions.gd). A chip
## in the stage's top-left sky, the ability chip's look (AbilityChip sits in the top-right sky): the
## word "משימות", under it the nearest goal's count ("12/25") or "לקחת!" when one is done, a bar
## (the nearest mission's progress), and a gold count badge of the claimable missions. A done
## mission pulses the chip. A tap opens the sheet (main → MissionsUi.open).
##
## Geometry (stage-node coordinates; the node lives in the stage column, so canvas x is minus
## L.sox()): HUD-like and L-anchored like the thermometer, canvas x 8-160 (the thermometer's column
## is x 12-132), y 168 (the stage top + 8, the ability chip's row). The thermometer's icon sits at
## S − 544 (stage y 256 on the 640 stage): on a shorter stage, with the thermometer up, the chip
## drops its second line and bar (48 tall), and below S ≈ 600 (an iPhone SE) it moves right of the
## thermometer's icon (canvas x 96, up to the leader's tap box) as one word: "משימות", or "לקחת!"
## (pulsing) while a mission is done; no badge there. The controller routes a tap on the chip before
## the thermometer's (their hit boxes touch in that mode).

const X := 8.0          # canvas x (L-anchored)
const Y := 168.0
const W := 152.0
const H := 80.0
const H_SMALL := 48.0
const SIDE_X := 96.0    # canvas x right of the thermometer's icon (its column centre is x 72)
const TEXT_SCALE := 3
const BADGE := 40.0

var reduced_motion := false
var _bg: NinePatchRect
var _text: PxText
var _sub: PxText
var _track: ColorRect
var _fill: ColorRect
var _badge: NinePatchRect
var _badge_text: PxText
var _rect := Rect2(X, Y, W, H)
var _mode := ""
var _t := 0.0
var _ready_n := 0


func _ready() -> void:
	var C: Dictionary = Art.theme["buffChip"]
	_bg = Ui.nine(self, _rect, C["sprite"], int(C["frame"]))
	_text = PxText.make(self, Vector2.ZERO, Strings.s("MIS_CHIP"), TEXT_SCALE, "plain", C["text"])
	_text.max_lines = 1
	_sub = PxText.make(self, Vector2.ZERO, "", TEXT_SCALE, "plain", C["text"])
	_sub.max_lines = 1
	_track = Ui.rect(self, Rect2(), C["barTrack"])
	_fill = Ui.rect(self, Rect2(), C["barFillTop"])
	_badge = Ui.nine(self, Rect2(0, 0, BADGE, BADGE), Art.sprite_or("badge_count"))
	_badge_text = PxText.make(self, Vector2.ZERO, "", TEXT_SCALE, "plain", "w")
	_badge_text.fit_width = BADGE - 4.0
	visible = false


## The chip's rect for the stage and the thermometer: `thermo_top` is the thermometer icon's top
## (stage-node y) or INF when it is not shown; `leader_left` the leader's tap box left edge.
static func layout(thermo_top: float, leader_left: float) -> Dictionary:
	var sx := -L.sox()
	if thermo_top >= Y + H + 8.0:
		return {"rect": Rect2(X + sx, Y, W, H), "mode": "full"}
	if thermo_top >= Y + H_SMALL + 8.0:
		return {"rect": Rect2(X + sx, Y, W, H_SMALL), "mode": "small"}
	var w := clampf(leader_left - 4.0 - (SIDE_X + sx), 56.0, W)
	return {"rect": Rect2(SIDE_X + sx, Y, w, H_SMALL), "mode": "side"}


func hit_rect() -> Rect2:
	return _rect.grow(6)


## True when a tap at `p` (stage coordinates) should open the missions sheet.
func takes_tap(p: Vector2) -> bool:
	return visible and hit_rect().has_point(p)


## `v` = {claimable, frac (the nearest mission), sub ("12/25"), show}; `stage_visible`: the stage is
## up (main mode, no modal over the stage); `thermo_top` / `leader_left` for layout().
func update_view(dt_ms: float, v: Dictionary, stage_visible: bool, thermo_top: float, leader_left: float) -> void:
	visible = stage_visible and bool(v.get("show", false))
	if not visible:
		return
	_t += dt_ms
	var lay := layout(thermo_top, leader_left)
	if lay["rect"] != _rect or str(lay["mode"]) != _mode:
		_rect = lay["rect"]
		_mode = str(lay["mode"])
		_relayout()
	var n := int(v.get("claimable", 0))
	if _mode == "side":
		var word := Strings.s("MIS_CHIP_READY") if n > 0 else Strings.s("MIS_CHIP")
		if _text.text != word:
			_text.text = word
			_text.center_in(_rect.position.x, _rect.size.x)
	elif _text.text != Strings.s("MIS_CHIP"):
		_text.text = Strings.s("MIS_CHIP")
		_place_badge()
	var sub := Strings.s("MIS_CHIP_READY") if n > 0 else str(v.get("sub", ""))
	if _sub.text != sub:
		_sub.text = sub
		_place_sub()
	if n != _ready_n:
		_ready_n = n
		_badge_text.text = str(n) if n > 0 else ""
		_place_badge()
	var fill := 1.0 if n > 0 else clampf(float(v.get("frac", 0.0)), 0.0, 1.0)
	var w := Ui.snap(_track.size.x * fill, 4)
	_fill.size.x = w
	_fill.position.x = L.bar_x(Rect2(_track.position, _track.size), w)   # RTL: fills from the right
	var a := 1.0
	if n > 0 and not reduced_motion:
		a = 0.8 + 0.2 * (0.5 + 0.5 * sin(TAU * 1.2 * _t / 1000.0))
	modulate.a = a


func _relayout() -> void:
	Ui.set_nine_rect(_bg, _rect)
	var full := _mode == "full"
	_text.position.y = _rect.position.y + (10.0 if full else 12.0)
	_sub.visible = full
	_track.visible = full
	_fill.visible = full
	var bar := Rect2(_rect.position.x + 10.0, _rect.end.y - 16.0, _rect.size.x - 20.0, 8.0)
	_track.position = bar.position
	_track.size = bar.size
	_fill.position = bar.position
	_fill.size = bar.size
	_place_sub()
	_place_badge()


func _place_sub() -> void:
	_sub.fit_width = _rect.size.x - 20.0
	_sub.position.y = _rect.position.y + 40.0
	_sub.center_in(_rect.position.x, _rect.size.x)


func _place_badge() -> void:
	var on := _ready_n > 0 and _mode != "side"
	_badge.visible = on
	_badge_text.visible = on
	var r := Rect2(_rect.position.x + 4.0, _rect.position.y + 4.0, BADGE, BADGE)
	Ui.set_nine_rect(_badge, r)
	_badge_text.position.y = r.position.y + 6.0
	_badge_text.center_in(r.position.x, r.size.x)
	# the word yields to the badge on the left (side mode: one centred word, no badge)
	if _mode == "side":
		_text.fit_width = maxf(24.0, _rect.size.x - 12.0)
		_text.center_in(_rect.position.x, _rect.size.x)
		return
	var left_pad := 8.0 + (BADGE if on else 0.0)
	_text.fit_width = maxf(24.0, _rect.size.x - 10.0 - left_pad)
	_text.right_at(_rect.end.x - 10.0)
