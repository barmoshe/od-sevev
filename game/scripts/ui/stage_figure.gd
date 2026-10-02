class_name StageFigure
extends Node2D
## A character who walks onto a stage mark from off the stage's edge and takes a tap there (Sara,
## Herzog, Kaia). One home for what they shared as copies: the art-to-stage mark, the walk in
## (ease-out) and out (ease-in) along x, reduced motion (no walk: in and out in place), and the tap
## box (the strip's frame grown by hit_pad, empty unless the state takes a tap). A subclass sets the
## fields in _init, drives `state` and calls _walk_in / _walk_out from its own update_view.

const AP := 4.0

var strip: SpriteStrip
var reduced_motion := false
var state := ""                           # "" = away; the rest are the subclass's
var _t := 0.0                             # ms in the current state
var char_id := ""
var off_x := 520.0                        # logical px from the mark to off the stage (sign = side)
var walk_ms := 520.0
var hit_pad := 8.0                        # logical px around the frame
var tap_states: Array[String] = ["enter", "wait"]


## Art px on the stage art (feet as drawn) → stage-local logical px: the stage art is placed so its
## magicianFeet slot lands on the leader's feet.
static func stage_at(art: Vector2) -> Vector2:
	var mf: Array = SpriteStrip.manifest().get("magicianFeet", [94, 219])
	return L.magician_feet() + (art - Vector2(float(mf[0]), float(mf[1]))) * AP


func _ready() -> void:
	strip = SpriteStrip.make(self, char_id, Vector2.ZERO)
	visible = false


func tappable() -> bool:
	return visible and tap_states.has(state)


## The tap box in stage-local px (empty when the figure takes no tap).
func hit_rect() -> Rect2:
	if not tappable():
		return Rect2()
	var r := _frame()
	return Rect2(position + r.position, r.size).grow(hit_pad)


## The figure's own box, node-local (the strip's frame; Sara adds her arrow).
func _frame() -> Rect2:
	return strip.rect()


func _go(st: String) -> void:
	state = st
	_t = 0.0


func _hide() -> void:
	state = ""
	visible = false


## The walk on: from off_x beyond the mark, easing out onto it. True once on the mark.
func _walk_in(m: Vector2) -> bool:
	var k := 1.0 if reduced_motion else clampf(_t / walk_ms, 0.0, 1.0)
	position = Vector2(m.x + off_x * pow(1.0 - k, 2.0), m.y)
	return k >= 1.0


## The walk off, easing in. True once off the stage (the figure is hidden then).
func _walk_out(m: Vector2) -> bool:
	var k := 1.0 if reduced_motion else clampf(_t / walk_ms, 0.0, 1.0)
	position = Vector2(m.x + off_x * k * k, m.y)
	if k >= 1.0:
		_hide()
	return k >= 1.0
