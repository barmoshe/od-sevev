class_name LeaderWalk
extends RefCounted
## A leader walking off or onto the stage (design/leader-select-spec.md §9.3.4, motion/state-graph-magician.md §9):
## the old leader walks out screen-right on the election's confirm frame, across the OLD stage and
## before the EVOLVE_TX card covers it (§9 revision 2: the new era is swapped under the opaque card
## afterwards); the picked leader walks in from screen-left to the feet point after the pick commit.
##
## No leader has a walk strip, and none is requested: a 1-2 s walk cycle across a 180-ap stage is dead
## time, and the TA budget (CONTRACT §4c) has no room for 8 more strips. So a walk is the leader's own
## idle strip carried across at a brisk, even pace with a stepped 1-ap bob: up on every other 125 ms
## beat (4 bobs/s, a walk's double bounce read at gameplay scale), whole art px only, snapped after
## easing. Walk-out eases in (Sine.In: he sets off), walk-in eases out (Sine.Out: he settles on the
## mark, the last beat flat so he lands on idle's own frame). Reduced motion: no travel and no bob;
## the figure fades out / in on the mark over 150 ms.
##
## One owner of the figure's position: a walk never writes the strip itself when BigBanana drives it.
## BigBanana advances it (`advance`) and composes its pose (`dx_ap`, `dy_ap`, `alpha`, `shows`) with
## the court day's in one place (`BigBanana._apply_figure`). The court yields while a walk runs.
## A standalone strip (tools, a preview) can still use `tick`, which advances and writes.
##
## States: home (on the mark, still) → out → gone (off the canvas, hidden) → in → home. `home()` cuts
## to the mark from anywhere (a reset, a load); `land()` ends a walk-in on the mark now.

const AP := 4.0
const OUT_MS := 560.0
const IN_MS := 640.0
const STEP_MS := 125.0
const BOB_AP := 1.0
const RM_FADE_MS := 150.0
const MARGIN_AP := 4.0                # clear of the canvas edge by this much when off

var strip: SpriteStrip
var leader_id := ""
var feet := Vector2.ZERO
var reduced := false
var off_ap := 0.0                     # signed: where the figure is fully off the canvas
var _mode := ""                       # "" (home) | out | gone | in
var _t := 0.0
var _dur := 0.0
var _pose := {"dx": 0, "dy": 0, "alpha": 1.0}


## Makes the leader's strip at `feet` (SpriteStrip.make: the density picked for the stage) and a walk
## for it. Null when the leader has no strip.
static func make(parent: Node, id: String, feet_: Vector2) -> LeaderWalk:
	var s := SpriteStrip.make(parent, id, feet_)
	if s == null:
		return null
	var w := LeaderWalk.new(s, id)
	w.feet = feet_
	return w


func _init(strip_: SpriteStrip = null, id: String = "") -> void:
	strip = strip_
	leader_id = id
	if strip != null:
		feet = strip.position


## The pose `t_ms` into a walk: {dx (ap from the mark), dy (ap, negative = up), alpha}. `out`: from the
## mark to `off`; else from `off` to the mark. Pure: every offset is a whole art px.
static func pose(t_ms: float, dur_ms: float, off: float, out: bool, reduced_: bool) -> Dictionary:
	var k := clampf(t_ms / maxf(1.0, dur_ms), 0.0, 1.0)
	if reduced_:
		var a := clampf(t_ms / RM_FADE_MS, 0.0, 1.0)
		return {"dx": 0, "dy": 0, "alpha": 1.0 - a if out else a}
	var e := (1.0 - cos(k * PI / 2.0)) if out else sin(k * PI / 2.0)   # Sine.In / Sine.Out
	var x := off * e if out else off * (1.0 - e)
	var beat := int(t_ms / STEP_MS)
	var bob := -BOB_AP if (beat % 2 == 1 and k < 1.0) else 0.0
	return {"dx": int(roundf(x)), "dy": int(bob), "alpha": 1.0}


## How far (signed ap) the figure must travel from `feet_x` to be fully off a canvas that runs from
## −ox to W + ox (logical): its frame rect `r` (feet-local) clears the edge by MARGIN_AP.
static func off_for(r: Rect2, feet_x: float, ox: float, dir: int) -> float:
	if dir < 0:
		return -ceilf((feet_x + ox + r.end.x + MARGIN_AP * AP) / AP)
	return ceilf((float(L.W) + ox - feet_x - r.position.x + MARGIN_AP * AP) / AP)


## The walk's length in ms under the current setting (the fade under reduced motion).
static func length_ms(out: bool, reduced_: bool) -> float:
	return RM_FADE_MS if reduced_ else (OUT_MS if out else IN_MS)


# ------------------------------------------------------------------ events in

## Walk off the stage toward `dir` (+1 screen-right, the swap's; -1 screen-left). `r`: the figure's
## rect (feet-local) and `ox` the stage column's x on the canvas, for the off distance.
func walk_out(dir: int = 1, r: Rect2 = Rect2(), ox: float = 0.0) -> void:
	_begin("out", dir, r, ox)


## Walk on from the `dir` side (-1 from screen-left, the default) to the feet point.
func walk_in(dir: int = -1, r: Rect2 = Rect2(), ox: float = 0.0) -> void:
	_begin("in", dir, r, ox)


## Cut to the mark, still and shown (a reset, a load, a new state).
func home() -> void:
	_mode = ""
	_t = 0.0
	_pose = {"dx": 0, "dy": 0, "alpha": 1.0}


## A walk-in ends on the mark now (a caller that cannot wait). A walk-out is left alone.
func land() -> void:
	if _mode == "in":
		home()


# ------------------------------------------------------------------ pose (read every frame)

## True while the figure travels or fades (out or in).
func walking() -> bool:
	return _mode == "out" or _mode == "in"


## True after a walk-out has ended: the figure is off the canvas until a walk-in or home().
func gone() -> bool:
	return _mode == "gone"


func state() -> String:
	return "home" if _mode == "" else _mode


func shows() -> bool:
	return _mode != "gone"


func dx_ap() -> int:
	return int(_pose["dx"])


func dy_ap() -> int:
	return int(_pose["dy"])


func alpha() -> float:
	return float(_pose["alpha"])


## ms left in the running walk (0 when none).
func left_ms() -> float:
	if not walking():
		return 0.0
	return maxf(0.0, (RM_FADE_MS if reduced else _dur) - _t)


func done() -> bool:
	return not walking()


# ------------------------------------------------------------------ time

## Advances the walk; never writes the strip (BigBanana composes the pose).
func advance(dt: float) -> void:
	if not walking():
		return
	_t += dt
	_pose = pose(_t, _dur, off_ap, _mode == "out", reduced)
	if _t >= (RM_FADE_MS if reduced else _dur):
		if _mode == "out":
			_mode = "gone"
			_pose = {"dx": int(roundf(off_ap)) if not reduced else 0, "dy": 0, "alpha": 0.0}
		else:
			home()


## Standalone use: advance and write the strip (position, alpha, visibility) and run its frames.
func tick(dt: float) -> void:
	if strip == null:
		return
	advance(dt)
	_write()
	strip.update_view(dt)


func _write() -> void:
	if strip == null:
		return
	strip.position = feet + Vector2(float(dx_ap()), float(dy_ap())) * AP
	strip.modulate.a = alpha()
	strip.visible = shows()


func _begin(mode: String, dir: int, r: Rect2, ox: float) -> void:
	_mode = mode
	_t = 0.0
	_dur = OUT_MS if mode == "out" else IN_MS
	if r.size == Vector2.ZERO and strip != null:
		r = strip.rect()
	off_ap = off_for(r, feet.x, ox, dir)
	_pose = pose(0.0, _dur, off_ap, mode == "out", reduced)
	if strip != null:
		if strip.anim != "idle":
			strip.play("idle")
		_write()
