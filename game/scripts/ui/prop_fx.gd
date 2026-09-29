class_name PropFx
extends Node2D
## The Magician's hat props (TA loader contract §4: coins and the rabbit spawn at the hat mouth):
## a coin spray (prop_coin0-3 is a 4-frame spin) and the rabbit popping out of the hat. Pooled
## sprites at the one art scale (×4), positions snapped to the 4-px grid. Driven by
## update_view(dt_ms). Reduced motion: three coins rise and fade, no arcs; the rabbit fades in
## place.

const POOL := 24
const SPIN_MS := 70.0
const GRAVITY := 2200.0     # px/s²
const COIN_LIFE_MS := 700.0
const RABBIT_MS := 700.0

var reduced_motion := false
var _coins: Array[Dictionary] = []
var _rabbit: Dictionary = {}
var _coin_keys: Array[String] = []


func _ready() -> void:
	for i in 4:
		_coin_keys.append(Art.sprite_or("prop_coin%d" % i))
	for i in POOL:
		var s := Sprite2D.new()
		s.centered = true
		s.scale = Vector2(4, 4)
		s.visible = false
		s.texture = Art.tex(_coin_keys[0])
		add_child(s)
		_coins.append({"s": s, "t": -1.0})
	var r := Sprite2D.new()
	r.centered = true
	r.scale = Vector2(4, 4)
	r.visible = false
	r.texture = Art.tex(Art.sprite_or("prop_rabbit"))
	add_child(r)
	_rabbit = {"s": r, "t": -1.0, "p": Vector2.ZERO}


## A burst of n coins from `at` (stage coordinates), fanned upward.
func coins(at: Vector2, n: int = 6) -> void:
	var count := 3 if reduced_motion else n
	var used := 0
	for c in _coins:
		if used >= count:
			break
		if float(c["t"]) >= 0.0:
			continue
		used += 1
		var ang := deg_to_rad(-90.0 + randf_range(-50.0, 50.0))
		var speed := randf_range(520.0, 820.0)
		c["t"] = 0.0
		c["p"] = at
		c["v"] = Vector2(cos(ang), sin(ang)) * speed if not reduced_motion else Vector2(randf_range(-40, 40), -120.0)
		c["spin"] = randi() % 4
		var s: Sprite2D = c["s"]
		s.visible = true
		s.modulate.a = 1.0
		s.position = at


func rabbit(at: Vector2) -> void:
	_rabbit["t"] = 0.0
	_rabbit["p"] = at
	var s: Sprite2D = _rabbit["s"]
	s.visible = true
	s.modulate.a = 0.0 if reduced_motion else 1.0
	s.position = at


func clear() -> void:
	for c in _coins:
		c["t"] = -1.0
		(c["s"] as Sprite2D).visible = false
	_rabbit["t"] = -1.0
	(_rabbit["s"] as Sprite2D).visible = false


func update_view(dt_ms: float) -> void:
	var dt := dt_ms / 1000.0
	for c in _coins:
		if float(c["t"]) < 0.0:
			continue
		c["t"] = float(c["t"]) + dt_ms
		var s: Sprite2D = c["s"]
		var t: float = c["t"]
		if t >= COIN_LIFE_MS:
			c["t"] = -1.0
			s.visible = false
			continue
		var v: Vector2 = c["v"]
		if not reduced_motion:
			v.y += GRAVITY * dt
			c["v"] = v
		c["p"] = Vector2(c["p"]) + v * dt
		s.position = Vector2(Ui.snap(c["p"].x, 4), Ui.snap(c["p"].y, 4))
		if not reduced_motion:
			var f := (int(c["spin"]) + int(t / SPIN_MS)) % 4
			Ui.set_frame(s, _coin_keys[f], 0)
		s.modulate.a = clampf(1.0 - (t - COIN_LIFE_MS * 0.6) / (COIN_LIFE_MS * 0.4), 0.0, 1.0)
	if float(_rabbit["t"]) >= 0.0:
		_rabbit["t"] = float(_rabbit["t"]) + dt_ms
		var p := float(_rabbit["t"]) / RABBIT_MS
		var rs: Sprite2D = _rabbit["s"]
		if p >= 1.0:
			_rabbit["t"] = -1.0
			rs.visible = false
			return
		if reduced_motion:
			rs.modulate.a = sin(p * PI)
		else:
			# out of the hat, up 96 px and back down a little, then fades
			var hop := 4.0 * p * (1.0 - p) * 96.0 + p * 24.0
			var base: Vector2 = _rabbit["p"]
			rs.position = Vector2(Ui.snap(base.x + p * 40.0, 4), Ui.snap(base.y - hop, 4))
			rs.modulate.a = 1.0 if p < 0.75 else (1.0 - p) * 4.0
