class_name BigBanana
extends Node2D
## The Big Banana: motion/state-graph-spec.md §1-3 (body, aura and hover as orthogonal regions)
## and motion/object-motion.md §1. The squash is a quantized driver: a number y is eased and mapped
## to one of the 5 drawn frames. No scale is ever applied to the banana itself.
##
## od-sevev: when the TA's cast strips are present, the Magician (SpriteStrip, content
## hero.char, default "bibi") stands in for the banana: idle loops, a tap plays `tap`, a crit
## plays `crit`, and each one-shot returns to idle. The strip's frame events (coins, rabbit,
## sting, ...) go to on_hero_event(name, stage_point), with the hat's mouth as the point when the
## anim carries `hatMouth`. The body/aura/hover graph still runs; the Magician shows the aura and
## hover as a brightness lift instead of the banana's halo sprite.

const DEPTH_RANK := {4: 0, 0: 1, 1: 2, 2: 3, 3: 4}
const BY_RANK := [4, 0, 1, 2, 3]

var sprite: Sprite2D
var flash: Sprite2D
var halo: Sprite2D
var fidget: Sprite2D
var body := Node2D.new()
var reduced_motion := false
var on_settle: Callable
## func(name: String, at: Vector2) for the Magician's frame events (stage coordinates).
var on_hero_event: Callable
var hero: SpriteStrip

var _state := "idle"          # idle | pressed | crit | locked
var _aura := "plain"          # plain | frenzy | tapFrenzy
var _phase := "none"          # none | down | return
var _t := 0.0
var _y_start := 1.0
var _y_target := 1.0
var _y := 1.0
var _f0 := 1
var _frame := 0
var _bands: Array[float] = []
var _flash_ms := 0.0
# idle
var _bob_up := false
var _bob_ms := 0.0
var _bob_wait := -1.0          # ms until the bob resumes; <0 = not waiting
var _bobbing := false
var _fidget_in := 0.0
var _fidget_t := -1.0
# halo
var _hover_alpha := 0.0
var _aura_alpha := 0.0
var _hover_tw: Tween
var _aura_tw: Tween
var _hello_ms := -1.0


func _ready() -> void:
	var sc := int(L.BB["scale"])
	var pivot := Vector2(L.BB["pivotX"], L.BB["pivotY"])
	var canvas_top := pivot.y - 49 * sc
	add_child(body)
	var hmeta: Dictionary = Art.meta["bigBanana_halo"]
	var hp: Array = hmeta["alignTo"]["canvasPx"]
	halo = Sprite2D.new()
	halo.texture = Art.tex("bigBanana_halo")
	halo.scale = Vector2(sc, sc)
	halo.position = Vector2(pivot.x - 24 * sc + float(hp[0]) * sc, canvas_top + float(hp[1]) * sc)
	halo.modulate.a = 0.0
	body.add_child(halo)
	sprite = Sprite2D.new()
	sprite.texture = Art.tex("bigBanana", 0)
	sprite.centered = false
	sprite.offset = Vector2(-24, -49)
	sprite.scale = Vector2(sc, sc)
	sprite.position = pivot
	body.add_child(sprite)
	flash = Sprite2D.new()
	flash.centered = false
	flash.offset = sprite.offset
	flash.scale = sprite.scale
	flash.position = pivot
	flash.modulate = Art.col("w")
	flash.visible = false
	body.add_child(flash)
	fidget = Ui.img(body, Vector2(pivot.x - 24 * sc + 20 * sc, canvas_top + 15 * sc), "particle_sparkle", 0, sc)
	fidget.visible = false
	var hero_id := String(Content.data().get("hero", {}).get("char", "bibi"))
	hero = SpriteStrip.make(body, hero_id, L.magician_feet())
	if hero != null:
		for n: CanvasItem in [halo, sprite, flash, fidget]:
			n.visible = false
			n.set_process(false)
		hero.finished.connect(func(_a: String) -> void: hero.play("idle"))
		hero.event.connect(func(ev: String, _f: int) -> void:
			if on_hero_event.is_valid():
				on_hero_event.call(ev, hero.position + body.position + hero.point("hatMouth", Vector2(0, -hero.frame_size().y * 0.7))))
	var hr: Array = Art.meta["bigBanana"]["heightRatio"]
	var mid := func(a: int, b: int) -> float: return (float(hr[a]) + float(hr[b])) / 2.0
	_bands = [mid.call(4, 0), mid.call(0, 1), mid.call(1, 2), mid.call(2, 3)]
	_enter_idle()


func _band(y: float) -> int:
	if y >= _bands[0]:
		return 4
	if y >= _bands[1]:
		return 0
	if y >= _bands[2]:
		return 1
	if y >= _bands[3]:
		return 2
	return 3


## Hit area = the drawn sprite rect + bigBananaHitPadPx on every side. Never follows the frame.
func hit_rect() -> Rect2:
	if hero != null:
		return L.magician_hit()   # rtl-map §4: 376x416, bottom 20 px clear of the Suitcase band
	var p := float(Tune.T["bigBananaHitPadPx"])
	var r: Rect2 = L.BB["sprite"]
	return Rect2(r.position.x - p, r.position.y - p, r.size.x + 2 * p, r.size.y + 2 * p)


# ------------------------------------------------------------------ body graph

func tap(crit: bool) -> void:
	if _state == "locked":
		return
	var from := _state
	if from == "idle":
		_leave_idle()
	var restart := from == "pressed" or from == "crit"
	_state = "crit" if crit else "pressed"
	if hero != null:
		hero.play("crit" if crit and hero.has_anim("crit") else "tap", true, 1)
	var sy := float(Tune.T["squashScaleY"])
	var smin := float(Tune.T["squashMinScaleY"])
	var target: float
	if crit:
		target = smin
	elif restart:
		target = maxf(smin, minf(sy, _y - (1.0 - sy) / 3.0))
	else:
		target = sy
	var f0 := 1
	if restart:
		f0 = _band((_y + target) / 2.0)
		var cur: int = DEPTH_RANK[_frame]
		if int(DEPTH_RANK[f0]) <= cur and cur < 4:
			f0 = BY_RANK[cur + 1]
	if crit and not restart:
		f0 = 1
	_y_start = _y
	_y_target = target
	_f0 = f0
	_phase = "down"
	_t = 0.0
	_show(f0)   # f0 is synchronous in the input handler (tapLatencyTargetFrames = 1)
	if crit:
		_flash_ms = float(Tune.MC["critFlashMs"])
	_apply_flash()


func lock() -> void:
	_leave_idle()
	_state = "locked"
	set_hover(false)
	if reduced_motion:
		_phase = "none"
		_y = 1.0
		_show(0)
		return
	_y_start = _y
	_y_target = float(Tune.T["squashMinScaleY"])
	_f0 = 1
	_phase = "down"
	_t = 0.0
	_show(1)


func unlock() -> void:
	if _state != "locked":
		return
	_state = "idle"
	_phase = "none"
	_y = 1.0
	_show(0)
	_enter_idle()


## The EVOLVE_TX "hello": the stretch frame for 50 ms, then rest.
func hello() -> void:
	if reduced_motion:
		return
	_show(4)
	_hello_ms = 50.0


func _show(f: int) -> void:
	_frame = f
	if hero != null:
		return
	Ui.set_frame(sprite, "bigBanana", f)
	if flash.visible:
		flash.texture = Art.mask("bigBanana", f)


func _apply_flash() -> void:
	var on := _flash_ms > 0.0
	if hero != null:
		return
	if on != flash.visible:
		flash.visible = on
		if on:
			flash.texture = Art.mask("bigBanana", _frame)


func update_view(dt_ms: float) -> void:
	if hero != null:
		hero.update_view(dt_ms)
		_pulse_t += dt_ms
	if _flash_ms > 0.0:
		_flash_ms -= dt_ms
	_apply_flash()
	_sync_halo()
	if _hello_ms >= 0.0:
		_hello_ms -= dt_ms
		if _hello_ms < 0.0 and _phase == "none":
			_show(0)
	_update_idle(dt_ms)
	if _phase == "none":
		return
	_t += dt_ms
	if _phase == "down":
		var down := float(Tune.T["squashDownMs"])
		_y = _y_start + (_y_target - _y_start) * minf(1.0, _t / down)
		_show(_f0 if _t < 0.4 * down else _band(_y_target))
		if _t >= down:
			_phase = "return"
			_t = 0.0
			_y = _y_target
		return
	var p := minf(1.0, _t / float(Tune.T["squashReturnMs"]))
	_y = _y_target + (1.0 - _y_target) * Ui.back_out(p, float(Tune.T["squashReturnOvershoot"]))
	_show(_band(_y))
	if p >= 1.0:
		_phase = "none"
		_y = 1.0
		_show(0)
		if _state == "pressed" or _state == "crit":
			_state = "idle"
			_enter_idle()
			if on_settle.is_valid():
				on_settle.call()


# ------------------------------------------------------------------ idle (bob + fidget)

func _enter_idle() -> void:
	_bob_wait = float(Tune.MC["bbBobResumeMs"])
	_fidget_in = randf_range(float(Tune.MC["bbFidgetMinMs"]), float(Tune.MC["bbFidgetMaxMs"]))


func _leave_idle() -> void:
	_bob_wait = -1.0
	_bobbing = false
	_bob_up = false
	_fidget_t = -1.0
	_fidget_in = -1.0
	fidget.visible = false
	body.position.y = 0.0


func _update_idle(dt_ms: float) -> void:
	if _bob_wait >= 0.0:
		_bob_wait -= dt_ms
		if _bob_wait < 0.0 and _state == "idle" and not reduced_motion and hero == null:
			_bobbing = true
			_bob_ms = 0.0
	if _bobbing:
		_bob_ms += dt_ms
		var half := float(Tune.MC["bbBobHalfFrenzyMs"] if _aura == "frenzy" else Tune.MC["bbBobHalfMs"])
		if _bob_ms >= half:
			_bob_ms -= half
			_bob_up = not _bob_up
			body.position.y = -float(Tune.MC["bbBobPx"]) if _bob_up else 0.0
	if _fidget_in >= 0.0 and _state == "idle" and hero == null:
		_fidget_in -= dt_ms
		if _fidget_in < 0.0:
			_fidget_t = 0.0
			fidget.visible = true
			_fidget_in = randf_range(float(Tune.MC["bbFidgetMinMs"]), float(Tune.MC["bbFidgetMaxMs"]))
	if _fidget_t >= 0.0:
		_fidget_t += dt_ms
		var f := float(Tune.MC["bbFidgetFrameMs"])
		Ui.set_frame(fidget, "particle_sparkle", 1 if (_fidget_t >= f and _fidget_t < 2 * f) else 0)
		if _fidget_t >= 3 * f:
			_fidget_t = -1.0
			fidget.visible = false


func set_reduced_motion(on: bool) -> void:
	reduced_motion = on
	if on:
		_bobbing = false
		body.position.y = 0.0
		_bob_up = false
	elif _state == "idle":
		_enter_idle()
	if _aura == "tapFrenzy":
		_enter_aura("tapFrenzy", true)


# ------------------------------------------------------------------ aura graph

func set_aura(next: String) -> void:
	if next != _aura:
		_enter_aura(next, false)


func _enter_aura(next: String, force: bool) -> void:
	if next == _aura and not force:
		return
	_aura = next
	if _aura_tw:
		_aura_tw.kill()
	if next == "tapFrenzy":
		if reduced_motion and Tune.T["tapFrenzyGlowStaticUnderReducedMotion"]:
			_aura_alpha = 0.5
		else:
			var half := 1.0 / (2.0 * float(Tune.T["tapFrenzyGlowPulseHz"]))
			_aura_alpha = 0.35
			_aura_tw = create_tween().set_loops()
			_aura_tw.tween_property(self, "_aura_alpha", 0.85, half).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			_aura_tw.tween_property(self, "_aura_alpha", 0.35, half).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	elif _aura_alpha > 0.0:
		_aura_tw = create_tween()
		_aura_tw.tween_property(self, "_aura_alpha", 0.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_sync_halo()


# ------------------------------------------------------------------ hover graph (mouse only)

func set_hover(on: bool) -> void:
	var target := float(Tune.T["bigBananaHoverHaloAlpha"]) if (on and _state != "locked") else 0.0
	if _hover_tw:
		_hover_tw.kill()
	_hover_tw = create_tween()
	_hover_tw.tween_property(self, "_hover_alpha", target, float(Tune.T["bigBananaHoverMs"]) / 1000.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


## The stage height changed (the flex rule): the Magician's feet are bottom-anchored.
func relayout() -> void:
	if hero != null:
		hero.position = L.magician_feet()


## ux/ftue.md P0: the hat's brightness pulse (hz 0 = off; 1 Hz, 2 Hz at F3). Reduced motion
## shows a static bright rim instead.
func set_pulse(hz: float) -> void:
	_pulse_hz = hz


var _pulse_hz := 0.0
var _pulse_t := 0.0


func _sync_halo() -> void:
	halo.modulate.a = maxf(_aura_alpha, _hover_alpha)
	if hero != null:
		var pulse := 0.0
		if _pulse_hz > 0.0:
			pulse = 0.35 if reduced_motion else 0.35 * (0.5 - 0.5 * cos(TAU * _pulse_hz * _pulse_t / 1000.0))
		var k := maxf(maxf(_aura_alpha, _hover_alpha), pulse)
		hero.modulate = Color(1, 1, 1).lerp(Color(1.3, 1.25, 1.05), k)


## FTUE failure branch: a pulsed emphasis on the banana (through the halo).
func emphasize(ms: float) -> void:
	if _hover_tw:
		_hover_tw.kill()
	_hover_tw = create_tween().set_loops(2)
	var q := ms / 4000.0
	_hover_tw.tween_property(self, "_hover_alpha", 0.6, q)
	_hover_tw.tween_property(self, "_hover_alpha", 0.0, q)
