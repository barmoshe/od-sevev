class_name GoldenView
extends Node2D
## The Suitcase (ux/rtl-map.md §4.1, first-minute §3.4), the fork's golden pickup repurposed.
## It flies through the bottom band of the stage (centre y S-60) instead of drifting:
## - the first flight enters at x 760 and exits at x -104 (right → left), 6.0 s; while nothing has
##   been caught every flight keeps that speed and a sparkle trail (S1);
## - later flights alternate direction and take 3.5-4.5 s (floor 3.0 s);
## - bob ±8 px (none under reduced motion, where the speed is ×0.8);
## - after 3 misses without a catch, the next one hovers mid-band for 1 s (ux/ftue.md S1);
## - hit: a 136x120 rect centred on the sprite (replaces the fork's circle and its E6 rule).
## Leaving the far edge uncaught is a miss (on_despawn_start). Its clock only runs while no modal
## is open (the caller passes `paused`).
## Art: content golden.sprite, else the kit's "suitcase" (26x20 art px, catch rim baked in).

var sprite: Sprite2D
var state := "gone"   # gone | idle | caught
var gx := 0.0
var gy := 0.0
var reduced_motion := false
var lifetime_ms := 6000.0        # the flight time (kept for the fork's API)
var on_despawn_start: Callable
## ux/ftue.md S1: true until the first catch (first-flight speed + sparkle)
var first_flight := true
## ux/ftue.md S1 fallback: hover mid-band for 1 s on this flight
var hover_mid := false
var key := "suitcaseStandIn"

var _half := Vector2(8, 8)
var _dir := -1.0                 # -1 right → left
var _flights := 0
var _dur := 6000.0
var _age := 0.0
var _st := 0.0
var _hold_ms := 0.0
var _hovered := false
var _trail: Array[Dictionary] = []
var _trail_ms := 0.0


func _ready() -> void:
	var want := String(Content.data().get("golden", {}).get("sprite", "suitcase" if Art.has_sprite("suitcase") else "suitcaseStandIn"))
	key = Art.sprite_or(want)
	_half = Vector2(Art.sprite_size(key)) / 2.0
	for i in 8:
		var t := Sprite2D.new()
		t.texture = Art.tex("particle_gold", 0)
		t.scale = Vector2(4, 4)
		t.visible = false
		add_child(t)
		_trail.append({"s": t, "t": -1.0})
	sprite = Sprite2D.new()
	sprite.texture = Art.tex(key, 0)
	sprite.scale = Vector2(4, 4)
	sprite.visible = false
	add_child(sprite)


func age_ms() -> float:
	return _age


func on_screen() -> bool:
	return state == "idle"


func is_visible_state() -> bool:
	return state != "gone"


## mobile-first §4.1: the band spans the canvas; it enters at canvas x 760 + dx and exits at
## -104 (the node is in the stage column, canvas x = stage x + L.sox()).
func _right_edge() -> float:
	return L.W + 40.0 + L.dx - L.sox()


func _left_edge() -> float:
	return -_half.x * 8.0 - L.sox()


func _x0() -> float:
	return _right_edge() if _dir < 0.0 else _left_edge()


func _x1() -> float:
	return _left_edge() if _dir < 0.0 else _right_edge()


## Nothing to move: the flight's ends are read from L at every step.
func relayout() -> void:
	pass


func spawn() -> void:
	# the first flight is always right → left; later ones alternate
	_dir = -1.0 if _flights % 2 == 0 else 1.0
	_flights += 1
	# leader select (spec §5.9): the DOHA sticker is Bibi's; every other round flies suitcase_plain
	if Leaders.active():
		var sc := Leaders.suitcase(LeaderUi.id())
		var want := String(Content.data().get("golden", {}).get("sprite", "suitcase")) if sc.get("sticker", true) == true else str(sc.get("sprite", "suitcase_plain"))
		if Art.has_sprite(want) and want != key:
			key = want
			_half = Vector2(Art.sprite_size(key)) / 2.0
			Ui.set_frame(sprite, key, 0)
	_dur = 6000.0 if first_flight else maxf(3000.0, randf_range(3500.0, 4500.0))
	if reduced_motion:
		_dur /= 0.8
	lifetime_ms = _dur
	_age = 0.0
	_st = 0.0
	_hold_ms = 0.0
	_hovered = false
	gx = _x0()
	gy = L.suitcase_y()
	state = "idle"
	sprite.visible = true
	sprite.modulate.a = 1.0
	_render()


## The 136x120 hit rect around the sprite (the Magician's hit ends ≥ 20 px above the band).
func hit_test(p: Vector2, _magician_hit: Rect2 = Rect2()) -> bool:
	return on_screen() and Ui.in_rect(hit_rect(), p)


func hit_rect() -> Rect2:
	var h := L.SUITCASE_HIT
	return Rect2(gx - h.x / 2.0, gy - h.y / 2.0, h.x, h.y)


func catch_it() -> bool:
	if not on_screen():
		return false
	state = "caught"
	_st = 0.0
	sprite.modulate.a = 1.0
	_render()
	return true


func clear() -> void:
	state = "gone"
	sprite.visible = false


func update_view(dt_ms: float, paused: bool) -> void:
	if state == "gone" or paused:
		# R19: the sparkles left behind keep fading after the flight ends (they froze at t and
		# stayed in the lane gutters for good); a modal pauses them with everything else
		_update_trail(0.0 if paused else dt_ms)
		return
	_st += dt_ms
	if state == "idle":
		if _hold_ms > 0.0:
			_hold_ms -= dt_ms
		else:
			var prev := gx
			_age += dt_ms
			var p := minf(1.0, _age / _dur)
			gx = lerpf(_x0(), _x1(), p)
			var mid := L.W / 2.0
			if hover_mid and not _hovered and (prev - mid) * (gx - mid) <= 0.0:
				_hovered = true
				_hold_ms = 1000.0
				gx = mid
			if p >= 1.0:
				clear()
				if on_despawn_start.is_valid():
					on_despawn_start.call()
				return
	elif state == "caught":
		var p2 := minf(1.0, _st / float(Tune.T["goldenCatchPopMs"]))
		sprite.modulate.a = 1.0 - p2
		if p2 >= 1.0:
			clear()
			return
	_render()
	_update_trail(dt_ms)


## A sparkle trail behind it while nothing has been caught yet (S1), not under reduced motion.
func _update_trail(dt_ms: float) -> void:
	_trail_ms += dt_ms
	if dt_ms <= 0.0:
		return
	if on_screen() and first_flight and not reduced_motion and _trail_ms >= 120.0:
		_trail_ms = 0.0
		for p in _trail:
			if float(p["t"]) < 0.0:
				p["t"] = 0.0
				var sp: Sprite2D = p["s"]
				sp.position = Vector2(Ui.snap(gx - _dir * _half.x * 4.0, 4), Ui.snap(gy + randf_range(-16, 16), 4))
				sp.visible = true
				break
	for p in _trail:
		if float(p["t"]) < 0.0:
			continue
		p["t"] = float(p["t"]) + dt_ms
		var sp2: Sprite2D = p["s"]
		sp2.modulate.a = maxf(0.0, 1.0 - float(p["t"]) / 500.0)
		if float(p["t"]) >= 500.0:
			p["t"] = -1.0
			sp2.visible = false


## Trail sparkles still drawn (tests: none may outlive the flight by more than their 500 ms fade).
func live_sparkles() -> int:
	var n := 0
	for p in _trail:
		if (p["s"] as Sprite2D).visible:
			n += 1
	return n


func _render() -> void:
	var sc := 4
	if state == "caught" and not reduced_motion:
		var p := minf(1.0, _st / float(Tune.T["goldenCatchPopMs"]))
		sc = maxi(4, int(roundf((1.0 + (float(Tune.T["goldenCatchPopScale"]) - 1.0) * Ui.quad_out(p)) * 4.0)))
	var bob := 0.0
	if state == "idle" and not reduced_motion:
		bob = Ui.snap(8.0 * sin(TAU * float(Tune.T["goldenBobHz"]) * (_age / 1000.0)), 4)
	Ui.set_frame(sprite, key, 0)
	sprite.scale = Vector2(sc, sc)
	var hw := _half.x * sc
	var hh := _half.y * sc
	sprite.position = Vector2(Ui.snap(gx - hw, 4) + hw, Ui.snap(gy + bob - hh, 4) + hh)
