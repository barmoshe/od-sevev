class_name HerzogFigure
extends Node2D
## President Herzog's compromise outline (Bar, 2026-10-01; content events.herzog, effect "mediation",
## fact herzog-framework). While the effect is live he walks in from the right to the front-right
## mark (Sara's; she steps off while he stands there), hands clasped (idle). A tap on him accepts
## the outline (main._accept_mediation) and he walks back out. Ignored until the effect lapses, he
## shrugs (the react: palms out, a sweat drop) and leaves. Any round, any stage; reduced motion
## skips the walk (he appears and disappears in place).

const CHAR := "herzog"
const MARK_ART := Vector2(150, 221)       # the right crowd's front row (SaraMark.MARK_ART)
const AP := 4.0
const WALK_MS := 520.0
const OFF_X := 520.0                      # logical px right of the mark: off the stage's right edge
const HIT := Vector2(152, 392)            # the tap box around him, logical px (feet at its bottom centre)

var strip: SpriteStrip
var reduced_motion := false
var state := ""                           # "" | enter | wait | shrug | exit
var _t := 0.0


static func mark() -> Vector2:
	var mf: Array = SpriteStrip.manifest().get("magicianFeet", [94, 219])
	return L.magician_feet() + (MARK_ART - Vector2(float(mf[0]), float(mf[1]))) * AP


static func live(s: GameState) -> bool:
	return s != null and Events.is_active(s, "mediation")


func _ready() -> void:
	strip = SpriteStrip.make(self, CHAR, Vector2.ZERO)
	visible = false
	position = mark()


## True while he takes a tap (on his mark or walking onto it).
func tappable() -> bool:
	return visible and (state == "enter" or state == "wait")


## His tap box in stage-local px (empty when he takes no tap).
func hit_rect() -> Rect2:
	if not tappable():
		return Rect2()
	return Rect2(position.x - HIT.x / 2.0, position.y - HIT.y, HIT.x, HIT.y)


## The outline was accepted: he walks back out.
func accept() -> void:
	if tappable():
		_go("exit")


func _go(st: String) -> void:
	state = st
	_t = 0.0
	if st == "shrug":
		strip.play("react", true, 0)
	elif st == "enter" or st == "exit":
		strip.play("idle", false)


func update_view(dt_ms: float, s: GameState, on_stage: bool) -> void:
	if strip == null:
		return
	if not on_stage:
		visible = false
		state = ""
		return
	var m := mark()
	if state == "" and live(s):
		visible = true
		strip.play("idle", true, randi() % maxi(1, strip.frame_count()))
		_go("enter")
	if state == "":
		visible = false
		return
	_t += dt_ms
	match state:
		"enter":
			var k := 1.0 if reduced_motion else clampf(_t / WALK_MS, 0.0, 1.0)
			position = Vector2(m.x + OFF_X * pow(1.0 - k, 2.0), m.y)
			if k >= 1.0:
				_go("wait")
		"wait":
			position = m
			if not live(s):
				_go("shrug")   # nobody took the outline: it lapses
		"shrug":
			position = m
			if strip.frame >= strip.frame_count() - 1 and _t >= 900.0:
				_go("exit")
		"exit":
			var k2 := 1.0 if reduced_motion else clampf(_t / WALK_MS, 0.0, 1.0)
			position = Vector2(m.x + OFF_X * k2 * k2, m.y)
			if k2 >= 1.0:
				state = ""
				visible = false
	strip.update_view(dt_ms)
