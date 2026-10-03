class_name CourtMotion
extends RefCounted
## Bibi's court day on the stage (motion/state-graph-magician.md §1.3, §2 `court` states, §3 `hat-prop`,
## §5.1-5.2): he takes a startle, zips off screen-left (the forward direction in RTL), his hat zips back
## alone and hovers on his mark, taps hit the hat; at the end the hat fetches him and he zips back in and
## lands. A pure timeline over scene ms: no nodes, no clock, no Hebrew. Magician reads the pose every
## frame (body offset / frame / alpha, hat and rabbit offsets) and drains `take_events()` (dust, coins,
## rabbit, land). Every offset is in whole ART px (ap) of the stage (×4 logical), snapped after easing,
## so nothing lands between device px at any integer scale.
##
## Every leader (Bar, 2026-10-01): Bibi's court day leaves the hat on the mark; every other leader's
## press day runs the same timeline and Magician draws a PressDesk on the hat's track instead.
##
## Reduced motion (motion/README rule 5) changes parameters, never the routing: the exit is a 150 ms
## fade of the body, then the hat fades in on the mark (150 ms); the return is the hat fading out,
## then the body fading in on idle (no land). The hat does not bob or peek; a tap pays out with no hop.

const AP := 4.0
# §5.1 exit
const STARTLE_F2_MS := 180.0          # tap.f2 + the 1-ap lean away from the exit (knock 2)
const STARTLE_MS := 330.0             # then the zip
const ZIP_OUT_MS := 200.0             # Quad.In, smears on
const HAT_SUMMON_MS := 250.0          # after he is gone
const HAT_ZIP_IN_MS := 300.0          # Quad.Out
# §5.2 return
const HAT_FETCH_MS := 150.0           # Quad.In
const HAT_FETCH_QUICK_MS := 120.0
const EMPTY_BEAT_MS := 150.0
const ZIP_IN_MS := 220.0              # Quad.Out, smears on
const RETURN_QUICK_MS := 150.0        # a reversal mid-zip: Quad.Out back to the mark
# §3 hat-prop
const BOB_PERIOD_MS := 1600.0         # y 0 → −2 ap → 0, Sine.InOut
const BOB_AP := 2.0
const BOB_RESUME_MS := 300.0          # after the last tap
const HOP_UP_MS := 80.0               # hatTap: −4 ap Quad.Out (coins at the peak)
const HOP_DOWN_MS := 120.0            # then → 0 Quad.In
const HOP_AP := 4.0
const CRIT_RISE_MS := 200.0           # hatCrit: the rabbit rises 12 ap, Back.Out
const CRIT_HOLD_MS := 350.0           # "sees the court"
const CRIT_SINK_MS := 150.0           # Quad.In
const CRIT_AP := 12.0
const CRIT_COINS := 6
const PEEK_MIN_MS := 6000.0           # the rabbit peeks every U(6, 9) s while the hat hovers
const PEEK_MAX_MS := 9000.0
const PEEK_UP_MS := 150.0
const PEEK_HOLD_MS := 500.0
const PEEK_AP := 3.0
const HUSH_STEP_MS := 100.0           # hatHush: ears up 100 / hold 100 / duck 100
const HUSH_AP := 3.0
const WIGGLE_MS := 40.0               # hat x +1, −1, +1, 0 ap (Stepped)
const SPILL_GAP_MS := 67.0            # hatCrit: a tap spills 1 coin, at most one per 67 ms
const RM_FADE_MS := 150.0

## Screen-left of the mark, far enough that the whole figure is off the canvas (Magician sets it
## from the layout; negative = left).
var off_ap := -170.0
var reduced := false
## stage | exitStartle | exitZip | offstage | fetching | emptyBeat | returnZip | returnQuick | rmExit | rmIn
var body := "stage"
## hidden | zipIn | hover | hatTap | hatCrit | hatHush | zipOut
var hat := "hidden"
var quick := false
var rng := RandomNumberGenerator.new()

var _bt := 0.0                        # ms in the body state
var _ht := 0.0                        # ms in the hat state
var _dx := 0.0                        # body x offset (ap, unsnapped)
var _zip_from := 0.0
var _hx := 0.0                        # hat x offset (ap, unsnapped)
var _hy := 0.0                        # hat y offset (ap, unsnapped; negative = up)
var _hat_from := Vector2.ZERO
var _hop_from := 0.0
var _batch := 1
var _coins_out := false
var _rabbit := 0.0                    # the rabbit's rise out of the hat (ap)
var _bob_t := 0.0
var _bob_wait := 0.0
var _peek_in := 0.0
var _peek_t := -1.0
var _last_spill := -1000.0
var _alpha := 1.0                     # body alpha (reduced motion fades)
var _hat_alpha := 1.0
var _events: Array[Dictionary] = []


## Only Bibi goes to court; everyone else's hazard is the press day (spec §10: the Bibi-only views).
static func allowed(has_court: bool, has_hero: bool) -> bool:
	return has_court and has_hero


func _init() -> void:
	rng.randomize()


# ------------------------------------------------------------------ pose (read every frame)

## True from the exit's f0 until he has landed back on his mark.
func in_court() -> bool:
	return body != "stage"


func body_visible() -> bool:
	return body in ["stage", "exitStartle", "exitZip", "returnZip", "returnQuick", "rmExit", "rmIn"]


func body_alpha() -> float:
	return _alpha


## The body's x offset from the mark in whole art px (negative = screen-left).
func body_dx_ap() -> int:
	return int(roundf(_dx))


## The tap-strip frame the body holds (1 = the startled squash, 2 = the stretched alarm pose that
## carries the zip), or -1 when the strip plays on its own (idle, or the land).
func body_frame() -> int:
	match body:
		"exitStartle":
			return 1 if _bt < STARTLE_F2_MS else 2
		"exitZip", "returnZip", "returnQuick":
			return 2
	return -1


## Two after-images trail the body while it zips (§2 exitZip / returnZip; none under reduced motion).
func smear() -> bool:
	return not reduced and body in ["exitZip", "returnZip", "returnQuick"]


## The direction the body travels (-1 left, +1 right, 0 still): the after-images trail behind it.
func travel_dir() -> int:
	match body:
		"exitZip":
			return -1
		"returnZip", "returnQuick":
			return 1
	return 0


func hat_visible() -> bool:
	return hat != "hidden"


func hat_alpha() -> float:
	return _hat_alpha


func hat_dx_ap() -> int:
	return int(roundf(_hx))


func hat_dy_ap() -> int:
	return int(roundf(_hy))


func hat_smear() -> bool:
	return not reduced and hat in ["zipIn", "zipOut"]


## How far the rabbit is up out of the hat (whole ap; 0 = hidden inside it).
func rabbit_up_ap() -> int:
	return int(roundf(_rabbit))


## Taps land on the hat (hop, coins) only while it hovers or reacts; in every other court state they
## are credited (floater, counter, cue) and nothing on the stage moves.
func hat_takes_taps() -> bool:
	return hat in ["hover", "hatTap", "hatCrit", "hatHush"]


## [{kind: dust | coins | rabbit | land, n, from, dust}] since the last call. dust: at the mark;
## coins: n from the hat's mouth; land: the body plays tap from `from` with its coins suppressed.
func take_events() -> Array[Dictionary]:
	var out := _events
	_events = []
	return out


# ------------------------------------------------------------------ events in

## courtStart (testimony begins). Ignored when he is already in court.
func start(rm: bool) -> void:
	if body != "stage":
		return
	reduced = rm
	quick = false
	_dx = 0.0
	_alpha = 1.0
	_set_body("rmExit" if rm else "exitStartle")


## courtEnd (testified, served, postponed) or an election while he is away (`quick_`: the hat is
## faster and the empty beat is skipped, §5.2 "Quick return").
func finish(quick_: bool = false) -> void:
	quick = quick or quick_
	match body:
		"stage", "fetching", "emptyBeat", "returnZip", "returnQuick", "rmIn":
			return
		"exitStartle":
			# early return: x cut back to the mark, land from the current frame + 1 (no dust)
			var f := body_frame()
			_dx = 0.0
			_set_body("stage")
			_events.append({"kind": "land", "from": f + 1, "dust": false})
		"exitZip":
			_zip_from = _dx
			_set_body("returnQuick")
		"rmExit":
			# mid-fade: fade back in from where the fade got to
			var a := _alpha
			_set_body("rmIn")
			_bt = a * RM_FADE_MS
		_:
			_set_body("fetching")
			_fetch_hat()


## A progress reset (O10) or a new run: cut home, hat hidden (§2 inherited runReset).
func reset() -> void:
	body = "stage"
	hat = "hidden"
	quick = false
	_dx = 0.0
	_hx = 0.0
	_hy = 0.0
	_rabbit = 0.0
	_alpha = 1.0
	_hat_alpha = 1.0
	_peek_t = -1.0
	_events.clear()


## A registered tap during court day. Returns true when the court owns it (the caller must not play
## the body's own tap). `paused`: courtPausesTaps, the tap earns nothing (hatHush, no coins).
func tap(crit: bool, paused: bool = false) -> bool:
	if body == "stage":
		return false
	if not hat_takes_taps():
		return true   # credited only (§3 table: zipIn / zipOut / hidden)
	_peek_t = -1.0
	if paused:
		_set_hat("hatHush")
		return true
	match hat:
		"hatCrit":
			if _ht - _last_spill >= SPILL_GAP_MS or _last_spill < 0.0:
				_last_spill = _ht
				_events.append({"kind": "coins", "n": 1})
			return true
		"hatTap":
			if crit:
				_start_crit()
			elif _ht < HOP_UP_MS and not reduced:
				_batch += 1   # merge into the rising hop
			else:
				_start_hop()
			return true
	if crit:
		_start_crit()
	else:
		_start_hop()
	return true


# ------------------------------------------------------------------ time

func tick(dt: float) -> void:
	_bt += dt
	_ht += dt
	_tick_hat(dt)    # the hat first: a fetch that ends this frame lets the body move on this frame
	_tick_body()


func _tick_body() -> void:
	match body:
		"exitStartle":
			_dx = 0.0 if _bt < STARTLE_F2_MS else 1.0   # the lean away from the exit
			if _bt >= STARTLE_MS:
				_zip_from = 1.0
				_set_body("exitZip")
				_events.append({"kind": "dust"})
		"exitZip":
			var k := minf(1.0, _bt / ZIP_OUT_MS)
			_dx = lerpf(_zip_from, off_ap, Ui.quad_in(k))
			if k >= 1.0:
				_dx = 0.0
				_set_body("offstage")
		"offstage":
			_dx = 0.0
			if hat == "hidden" and _bt >= (0.0 if reduced else HAT_SUMMON_MS):
				_set_hat("zipIn")
				_hx = 0.0 if reduced else off_ap
		"fetching":
			if hat == "hidden":
				if reduced:
					_set_body("rmIn")
				elif quick:
					_set_body("returnZip")
				else:
					_set_body("emptyBeat")
		"emptyBeat":
			if _bt >= EMPTY_BEAT_MS:
				_set_body("returnZip")
		"returnZip":
			var k2 := minf(1.0, _bt / ZIP_IN_MS)
			_dx = lerpf(off_ap, 0.0, Ui.quad_out(k2))
			if k2 >= 1.0:
				_land()
		"returnQuick":
			var k3 := minf(1.0, _bt / RETURN_QUICK_MS)
			_dx = lerpf(_zip_from, 0.0, Ui.quad_out(k3))
			if k3 >= 1.0:
				_land()
		"rmExit":
			_alpha = maxf(0.0, 1.0 - _bt / RM_FADE_MS)
			if _bt >= RM_FADE_MS:
				_alpha = 0.0
				_set_body("offstage")
		"rmIn":
			_alpha = minf(1.0, _bt / RM_FADE_MS)
			if _bt >= RM_FADE_MS:
				_alpha = 1.0
				_set_body("stage")


func _tick_hat(dt: float) -> void:
	match hat:
		"zipIn":
			if reduced:
				_hx = 0.0
				_hat_alpha = minf(1.0, _ht / RM_FADE_MS)
				if _ht >= RM_FADE_MS:
					_enter_hover()
			else:
				_hat_alpha = 1.0
				_hx = lerpf(off_ap, 0.0, Ui.quad_out(minf(1.0, _ht / HAT_ZIP_IN_MS)))
				if _ht >= HAT_ZIP_IN_MS:
					_enter_hover()
		"hover":
			_hx = 0.0
			if reduced:
				_hy = 0.0
				_rabbit = 0.0
				return
			if _bob_wait > 0.0:
				_bob_wait -= dt
				_hy = 0.0
			else:
				_bob_t += dt
				_hy = -BOB_AP * (0.5 - 0.5 * cos(TAU * fmod(_bob_t, BOB_PERIOD_MS) / BOB_PERIOD_MS))
			_tick_peek(dt)
		"hatTap":
			if reduced:
				_hy = 0.0
				_enter_hover()
				return
			if _ht < HOP_UP_MS:
				_hy = lerpf(_hop_from, -HOP_AP, Ui.quad_out(_ht / HOP_UP_MS))
			else:
				if not _coins_out:
					_coins_out = true
					_events.append({"kind": "coins", "n": mini(2 + _batch - 1, 4)})
				_hy = lerpf(-HOP_AP, 0.0, Ui.quad_in(minf(1.0, (_ht - HOP_UP_MS) / HOP_DOWN_MS)))
				if _ht >= HOP_UP_MS + HOP_DOWN_MS:
					_enter_hover(BOB_RESUME_MS)
		"hatCrit":
			var total := (500.0 if reduced else CRIT_RISE_MS + CRIT_HOLD_MS + CRIT_SINK_MS)
			if reduced:
				_hy = 0.0
				_rabbit = CRIT_AP
			else:
				# the hat hops like hatTap while the rabbit rises, holds and sinks
				if _ht < HOP_UP_MS:
					_hy = lerpf(_hop_from, -HOP_AP, Ui.quad_out(_ht / HOP_UP_MS))
				else:
					_hy = lerpf(-HOP_AP, 0.0, Ui.quad_in(minf(1.0, (_ht - HOP_UP_MS) / HOP_DOWN_MS)))
				if _ht < CRIT_RISE_MS:
					_rabbit = CRIT_AP * Ui.back_out(_ht / CRIT_RISE_MS, 1.70158)
				elif _ht < CRIT_RISE_MS + CRIT_HOLD_MS:
					_rabbit = CRIT_AP
				else:
					_rabbit = CRIT_AP * (1.0 - Ui.quad_in(minf(1.0, (_ht - CRIT_RISE_MS - CRIT_HOLD_MS) / CRIT_SINK_MS)))
				if not _coins_out and _ht >= CRIT_RISE_MS:
					_coins_out = true
					_events.append({"kind": "coins", "n": CRIT_COINS})
			if _ht >= total:
				_rabbit = 0.0
				_enter_hover(BOB_RESUME_MS)
		"hatHush":
			_hy = 0.0
			if reduced:
				_hx = 0.0
				_rabbit = HUSH_AP if _ht < RM_FADE_MS else 0.0
				if _ht >= RM_FADE_MS:
					_enter_hover(BOB_RESUME_MS)
				return
			var w := [1.0, -1.0, 1.0, 0.0]
			_hx = w[mini(3, int(_ht / WIGGLE_MS))]
			if _ht < HUSH_STEP_MS:
				_rabbit = HUSH_AP * Ui.quad_out(_ht / HUSH_STEP_MS)
			elif _ht < 2.0 * HUSH_STEP_MS:
				_rabbit = HUSH_AP
			else:
				_rabbit = HUSH_AP * (1.0 - Ui.quad_in(minf(1.0, (_ht - 2.0 * HUSH_STEP_MS) / HUSH_STEP_MS)))
			if _ht >= 3.0 * HUSH_STEP_MS:
				_rabbit = 0.0
				_enter_hover(BOB_RESUME_MS)
		"zipOut":
			_rabbit = 0.0
			if reduced:
				_hat_alpha = maxf(0.0, 1.0 - _ht / RM_FADE_MS)
				if _ht >= RM_FADE_MS:
					_set_hat("hidden")
				return
			var ms := HAT_FETCH_QUICK_MS if quick else HAT_FETCH_MS
			var k := minf(1.0, _ht / ms)
			_hx = lerpf(_hat_from.x, off_ap, Ui.quad_in(k))
			_hy = lerpf(_hat_from.y, 0.0, k)
			if k >= 1.0:
				_set_hat("hidden")


func _tick_peek(dt: float) -> void:
	if _peek_t < 0.0:
		_peek_in -= dt
		_rabbit = 0.0
		if _peek_in <= 0.0:
			_peek_t = 0.0
		return
	_peek_t += dt
	if _peek_t < PEEK_UP_MS:
		_rabbit = PEEK_AP * Ui.quad_out(_peek_t / PEEK_UP_MS)
	elif _peek_t < PEEK_UP_MS + PEEK_HOLD_MS:
		_rabbit = PEEK_AP
	elif _peek_t < 2.0 * PEEK_UP_MS + PEEK_HOLD_MS:
		_rabbit = PEEK_AP * (1.0 - Ui.quad_in((_peek_t - PEEK_UP_MS - PEEK_HOLD_MS) / PEEK_UP_MS))
	else:
		_rabbit = 0.0
		_peek_t = -1.0
		_peek_in = rng.randf_range(PEEK_MIN_MS, PEEK_MAX_MS)


# ------------------------------------------------------------------ transitions

func _set_body(b: String) -> void:
	body = b
	_bt = 0.0
	if b == "offstage" or b == "fetching" or b == "emptyBeat":
		_alpha = 0.0 if reduced else 1.0
	if b == "returnZip":
		_dx = off_ap
		_alpha = 1.0
	if b == "rmIn":
		_alpha = 0.0
	if b == "stage":
		_alpha = 1.0


func _set_hat(h: String) -> void:
	hat = h
	_ht = 0.0
	_coins_out = false
	if h == "hidden":
		_hx = 0.0
		_hy = 0.0
		_rabbit = 0.0
		_hat_alpha = 1.0
	if h == "zipIn":
		_hat_alpha = 0.0 if reduced else 1.0


func _enter_hover(wait_ms: float = 0.0) -> void:
	_set_hat("hover")
	_hx = 0.0
	_hat_alpha = 1.0
	_bob_t = 0.0
	_bob_wait = wait_ms
	_peek_t = -1.0
	_peek_in = rng.randf_range(PEEK_MIN_MS, PEEK_MAX_MS)


func _start_hop() -> void:
	_hop_from = _hy
	_batch = 1
	_set_hat("hatTap")
	if reduced:
		_events.append({"kind": "coins", "n": 3})   # RM: no hop, three coins straight up at f0
		_coins_out = true


func _start_crit() -> void:
	_hop_from = _hy
	_last_spill = -1000.0
	_set_hat("hatCrit")
	_events.append({"kind": "rabbit"})
	if reduced:
		_events.append({"kind": "coins", "n": CRIT_COINS})
		_coins_out = true


func _fetch_hat() -> void:
	if hat == "hidden":
		return
	_hat_from = Vector2(_hx, _hy)
	_set_hat("zipOut")
	_hat_alpha = 1.0


func _land() -> void:
	_dx = 0.0
	_set_body("stage")
	_events.append({"kind": "land", "from": 1, "dust": true})
