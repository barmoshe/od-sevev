class_name LeaderWalk
extends RefCounted
## A leader walking off or onto the stage (design/leader-select-spec.md §9.3.4: the leader swap in
## EVOLVE_TX, ≤ 1.5 s with input locked; the old leader walks out screen-right on the fade, the new
## one walks in to the feet point on the fade-in). Prepared for the Animator's second slice; nothing
## calls it yet (the picker and EVOLVE_TX wiring are the Game Developer's).
##
## No leader has a walk strip, and none is requested: a 1-2 s walk cycle across a 180-ap stage is dead
## time, and the TA budget (CONTRACT §4c) has no room for 8 more strips. So a walk is the leader's own
## idle strip carried across at a brisk, even pace with a stepped 1-ap bob: up on every other 125 ms
## beat (4 bobs/s, a walk's double bounce read at gameplay scale), whole art px only, snapped after
## easing. Walk-out eases in (Sine.In: he sets off), walk-in eases out (Sine.Out: he settles on the
## mark, the last beat flat so he lands on idle's own frame). Reduced motion: no travel and no bob;
## the figure fades out / in on the mark over 150 ms.
##
## Usage: var w := LeaderWalk.make(parent, "bennett", L.magician_feet()); w.walk_in(-1); then each
## frame w.tick(dt) until w.done(). Or drive any SpriteStrip with LeaderWalk.new(strip, id).

const AP := 4.0
const OUT_MS := 560.0
const IN_MS := 640.0
const STEP_MS := 125.0
const BOB_AP := 1.0
const RM_FADE_MS := 150.0

var strip: SpriteStrip
var leader_id := ""
var feet := Vector2.ZERO
var reduced := false
var off_ap := 0.0                     # signed: where the figure is fully off the canvas
var _mode := ""                       # "" | out | in
var _dir := 1
var _t := 0.0
var _dur := 0.0


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
static func pose(t_ms: float, dur_ms: float, off: float, out: bool, reduced: bool) -> Dictionary:
	var k := clampf(t_ms / maxf(1.0, dur_ms), 0.0, 1.0)
	if reduced:
		var a := clampf(t_ms / RM_FADE_MS, 0.0, 1.0)
		return {"dx": 0, "dy": 0, "alpha": 1.0 - a if out else a}
	var e := (1.0 - cos(k * PI / 2.0)) if out else sin(k * PI / 2.0)   # Sine.In / Sine.Out
	var x := off * e if out else off * (1.0 - e)
	var beat := int(t_ms / STEP_MS)
	var bob := -BOB_AP if (beat % 2 == 1 and k < 1.0) else 0.0
	return {"dx": int(roundf(x)), "dy": int(bob), "alpha": 1.0}


## How far (signed ap) the figure must travel from `feet_x` to be fully off a canvas that runs from
## −ox to W + ox (logical): its frame rect `r` (feet-local) clears the edge by 4 ap.
static func off_for(r: Rect2, feet_x: float, ox: float, dir: int) -> float:
	if dir < 0:
		return -ceilf((feet_x + ox + r.end.x + 4.0 * AP) / AP)
	return ceilf((float(L.W) + ox - feet_x - r.position.x + 4.0 * AP) / AP)


## Walk off the stage toward `dir` (+1 screen-right, the default for the swap; -1 screen-left).
func walk_out(dir: int = 1, ms: float = OUT_MS, ox: float = 0.0) -> void:
	_begin("out", dir, ms, ox)


## Walk on from the `dir` side (-1 from screen-left, the default) to the feet point.
func walk_in(dir: int = -1, ms: float = IN_MS, ox: float = 0.0) -> void:
	_begin("in", dir, ms, ox)


func done() -> bool:
	return _mode == "" or _t >= (RM_FADE_MS if reduced else _dur)


func tick(dt: float) -> void:
	if _mode == "" or strip == null:
		return
	_t += dt
	var p := pose(_t, _dur, off_ap, _mode == "out", reduced)
	strip.position = feet + Vector2(float(p["dx"]), float(p["dy"])) * AP
	strip.modulate.a = float(p["alpha"])
	strip.update_view(dt)
	if done():
		if _mode == "out":
			strip.visible = false
		else:
			strip.position = feet
			strip.modulate.a = 1.0
		_mode = ""


func _begin(mode: String, dir: int, ms: float, ox: float) -> void:
	_mode = mode
	_dir = dir
	_t = 0.0
	_dur = ms
	if strip != null:
		off_ap = off_for(strip.rect(), feet.x, ox, dir)
		strip.visible = true
		if strip.anim != "idle":
			strip.play("idle")
		var p := pose(0.0, _dur, off_ap, mode == "out", reduced)
		strip.position = feet + Vector2(float(p["dx"]), float(p["dy"])) * AP
		strip.modulate.a = float(p["alpha"])
