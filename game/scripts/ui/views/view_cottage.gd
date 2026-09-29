class_name CottageCup
extends Node2D
## Row A's Cottage Index, "מדד הקוטג׳" (ux/rtl-map.md §2 `TopBar.cottage`, ux/ftue.md Q1, motion
## cottage-pixel-loss, style guide §12.1). A child of `_top` (Row A-local coordinates).
##
## - Hit Rect2(624, 4, 88, 88) (L.TOP.cottageHit); the kit `cottage_cup` (16×18 art, 13 frames) at ×4
##   = 64×72 at (636, 12). Hidden until Q1 (the content's first cottagePixel threshold: 1,000 ₪
##   lifetime). The frame is ViewRules.cottage_frame: the highest cottagePixel headline whose
##   trigger holds (frame k = the k-th ×10 of the lifetime treasury).
## - Opacity: 50%; 100% for 3 s after it appears, loses a pixel, or is tapped, then back to 50%
##   over 300 ms (Quad.InOut).
## - Appear (Q1 in play): 0 → 100% over 200 ms (Quad.Out) + a 1-art-px hop (160 ms). A save that
##   loads with the cup already revealed just shows it.
## - Pixel loss (frame k → k+1, in play): the frame cuts; a 1-art-px `cottage_pixel` leaves the
##   hole (up 2 ap in 120 ms Quad.Out, down 14 ap in 380 ms Quad.In, x drift U(−2, 2) ap, fading
##   over its last 150 ms); "−1" (HUD_COTTAGE_MINUS, PxText) rises 6 ap over 600 ms (Cubic.Out),
##   fading over its last 250 ms; the Audio gets `cottagePixel` (unassigned today: silent).
##   Reduced motion: the frame cut, no pixel, a static "−1" that fades over 600 ms.
## - Tap: the tooltip HUD_COTTAGE_TIP as a toast (rtl-map §2), at most one per toast length.

signal tapped

const KIT := "cottage_cup"
const PIXEL := "cottage_pixel"
const CUP_POS := Vector2(636, 12)
const BASE_ALPHA := 0.5
const TIP_COOLDOWN_MS := 4000.0       # Toasts.SHOW_MS + GAP_MS: one tip in the dock at a time

## motion-spec cottage-pixel-loss (ViewRules.mc keys; the rest are the spec's own numbers)
const RISE_MS := 150.0
const HOP_MS := 160.0
const PARTICLE_UP_MS := 120.0
const PARTICLE_FADE_MS := 150.0
const MINUS_FADE_MS := 250.0

var host: Node                        # MainController (duck-typed: toasts, audio_event)
var reduced_motion := false
## What the cup did, for tests: "appear", "drop:<k>", "tip".
var events: Array[String] = []

var _cup: Sprite2D
var _minus: PxText
var _frames := 13
var _frame := -1                      # the frame on screen (-1: not initialised yet)
var _shown := false
var _now := 0.0
var _lit_at := -1e9                   # when it last went to 100%
var _lit_from := BASE_ALPHA
var _lit_rise := RISE_MS
var _hop_at := -1e9
var _particle: Sprite2D
var _p: Dictionary = {}               # {t, x0, y0, dx}
var _minus_t := -1.0
var _tip_at := -1e9


func setup(host_: Node) -> CottageCup:
	host = host_
	return self


func _ready() -> void:
	var id := Art.sprite_or(KIT)
	_frames = maxi(1, Art.frame_count(id))
	_cup = Ui.img(self, CUP_POS, id, 0, 4)
	_particle = Ui.img(self, CUP_POS, Art.sprite_or(PIXEL), 0, 4)
	_particle.visible = false
	_minus = PxText.make(self, Vector2.ZERO, Strings.s("HUD_COTTAGE_MINUS"), L.TEXT, "plain", "w")
	_minus.visible = false
	visible = false


func hit_rect() -> Rect2:
	return L.TOP["cottageHit"]


func contains(p: Vector2) -> bool:
	return visible and _shown and Ui.in_rect(hit_rect(), p)


func frame() -> int:
	return _frame


func shown() -> bool:
	return _shown


func alpha() -> float:
	return _cup.modulate.a if _cup != null else 0.0


## `allowed`: Row A is on screen (main mode, the counter revealed).
func update_view(dt_ms: float, s: GameState, allowed: bool) -> void:
	_now += dt_ms
	var fr := ViewRules.cottage_frame(s, _frames)
	var rev := ViewRules.cottage_revealed(s)
	var boot := _frame < 0
	if boot:
		_frame = fr                   # boot: whatever the save already had is not news
	if not rev:
		_shown = false
		_frame = fr
	elif allowed and not _shown and boot:
		_shown = true                 # a save that loads with the cup revealed: it is just there
		_set_frame(fr)
		events.append("show")
	elif allowed and not _shown:
		_shown = true
		_set_frame(fr)
		if fr > _frame:
			_drop(_frame, fr)
		_light(0.0, ViewRules.mc("cottageAppearMs"))
		_hop_at = _now
		events.append("appear")
		_frame = fr
	elif _shown and fr != _frame:
		if fr > _frame:
			_drop(_frame, fr)
		_set_frame(fr)
		_frame = fr
	visible = _shown and allowed
	if not visible:
		return
	_cup.modulate.a = _alpha_now()
	var hop := 0.0
	var ht := _now - _hop_at
	if not reduced_motion and ht < HOP_MS:
		hop = -4.0 if ht < HOP_MS / 2.0 else 0.0     # 1 art px up and back (a cut, on the grid)
	_cup.position = CUP_POS + Vector2(0, hop)
	_update_particle(dt_ms)


func _set_frame(fr: int) -> void:
	Ui.set_frame(_cup, _cup.get_meta("sprite"), clampi(fr, 0, _frames - 1))


## Goes to 100% from `from` over `rise` ms, holds 3 s, then settles back to 50%.
func _light(from: float, rise: float) -> void:
	_lit_from = from
	_lit_rise = rise
	_lit_at = _now


func _alpha_now() -> float:
	var t := _now - _lit_at
	var hold := ViewRules.mc("cottageHoldMs")
	var settle := maxf(1.0, ViewRules.mc("cottageSettleMs"))
	if t < _lit_rise:
		return lerpf(_lit_from, 1.0, Ui.quad_out(t / _lit_rise))
	if t < _lit_rise + hold:
		return 1.0
	if t < _lit_rise + hold + settle:
		var p := (t - _lit_rise - hold) / settle
		var e := 2.0 * p * p if p < 0.5 else 1.0 - pow(-2.0 * p + 2.0, 2.0) / 2.0
		return lerpf(1.0, BASE_ALPHA, e)
	return BASE_ALPHA


func _drop(from: int, to: int) -> void:
	events.append("drop:%d" % to)
	_light(_cup.modulate.a, RISE_MS)
	if host != null and host.has_method("audio_event"):
		host.audio_event("cottagePixel", to)
	var hole := lost_pixel(from, to)
	var cup_art := Vector2(Art.sprite_size(_cup.get_meta("sprite")))
	_minus.position = CUP_POS + Vector2(0, -8.0)
	_minus.center_in(CUP_POS.x - 12.0, cup_art.x * 4.0 + 24.0)
	_minus.visible = true
	_minus_t = 0.0
	if reduced_motion:
		_particle.visible = false
		return
	_p = {"t": 0.0, "x0": CUP_POS.x + hole.x * 4.0, "y0": CUP_POS.y + hole.y * 4.0, "dx": float(randi_range(-2, 2))}
	_particle.position = Vector2(_p["x0"], _p["y0"])
	_particle.modulate.a = 1.0
	_particle.visible = true


## The art px (in the cup frame) that frame `to` lost against frame `from`: the first pixel that
## was opaque and is now clear, scanning from the centre row out (style guide §12.1: frame 1's
## one pixel is in the dead centre). The cup's centre when the images are not readable.
func lost_pixel(from: int, to: int) -> Vector2:
	var id: String = _cup.get_meta("sprite")
	var sz := Vector2(Art.sprite_size(id))
	var centre := (sz / 2.0).floor()
	if DisplayServer.get_name() == "headless":
		return centre
	var a := Art.tex(id, from).get_image()
	var b := Art.tex(id, to).get_image()
	if a == null or b == null or a.is_empty() or b.is_empty() or a.get_size() != b.get_size():
		return centre
	var best := Vector2(-1, -1)
	var best_d := INF
	for y in a.get_height():
		for x in a.get_width():
			if a.get_pixel(x, y).a > 0.5 and b.get_pixel(x, y).a < 0.5:
				var dd := Vector2(x, y).distance_squared_to(centre)
				if dd < best_d:
					best_d = dd
					best = Vector2(x, y)
	return best if best.x >= 0.0 else centre


func _update_particle(dt_ms: float) -> void:
	if _minus_t >= 0.0:
		_minus_t += dt_ms
		var total := ViewRules.mc("cottageMinusMs")
		var p := clampf(_minus_t / maxf(1.0, total), 0.0, 1.0)
		if reduced_motion:
			_minus.modulate.a = 1.0 - p
		else:
			_minus.position.y = CUP_POS.y - 8.0 - Ui.snap(24.0 * Ui.cubic_out(p), 4)
			_minus.modulate.a = clampf((total - _minus_t) / MINUS_FADE_MS, 0.0, 1.0)
		if p >= 1.0:
			_minus_t = -1.0
			_minus.visible = false
	if _p.is_empty():
		return
	_p["t"] = float(_p["t"]) + dt_ms
	var t: float = _p["t"]
	var total2 := ViewRules.mc("cottageParticleMs")
	var y := 0.0
	if t < PARTICLE_UP_MS:
		y = -8.0 * Ui.quad_out(t / PARTICLE_UP_MS)
	else:
		y = -8.0 + 56.0 * Ui.quad_in(clampf((t - PARTICLE_UP_MS) / maxf(1.0, total2 - PARTICLE_UP_MS), 0.0, 1.0))
	var x := float(_p["dx"]) * 4.0 * clampf(t / total2, 0.0, 1.0)
	_particle.position = Vector2(float(_p["x0"]) + Ui.snap(x, 4), float(_p["y0"]) + Ui.snap(y, 4))
	_particle.modulate.a = clampf((total2 - t) / PARTICLE_FADE_MS, 0.0, 1.0)
	if t >= total2:
		_p = {}
		_particle.visible = false


## The tooltip (rtl-map §2): HUD_COTTAGE_TIP in the toast dock; the cup lights up with it.
func tap() -> void:
	if not _shown:
		return
	_light(_cup.modulate.a, RISE_MS)
	tapped.emit()
	if _now - _tip_at < TIP_COOLDOWN_MS:
		return
	_tip_at = _now
	events.append("tip")
	if host != null:
		var t: Variant = host.get("toasts")
		if t is Toasts:
			(t as Toasts).show_toast(Strings.s("HUD_COTTAGE_TIP"), "cottage")
		if host.has_method("audio_event"):
			host.audio_event("uiClick")
