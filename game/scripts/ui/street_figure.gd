class_name StreetFigure
extends Node2D
## Mordechai David, "החסימה" (design/mordechai-david-spec.md §7.2, §9; CONTRACT §4 "Mordechai David"):
## the stage figure and the event's copy. The sim owns the timing: the figure follows the live
## `blockade` effect (Events.active_effects), so a save loaded mid-blockade, an election that clears
## it, or a reset all land right without extra wiring.
##
## Beats (Bar, 2026-10-01: from the left only): walk in from beyond the canvas's left edge (`walk`, as
## drawn: heading right) to his mark in front of the left crowd (art x 34, feet row 221), `block_in`
## (plant), hold `block` facing the leader, one smug `glance` at the player, then `block_in` backwards
## and walk out to the left (flip_h). Timed so he is off the canvas as the effect ends. He never stops
## inside the leader's slot (art x 66-114); the walk stays left of it. Reduced motion: no walk, a
## 150 ms fade on the mark in the hold pose, frozen. Live on the `blockade` effect (the old seat
## bench) and on `screenBlock` (the tap block his event fires now).
##
## No player action on him, ever: no tap target (spec §1).

const CHAR := "mordechai-david"
const EVENT_ID := "mordechai"
const MARK_ART := Vector2(34, 221)    # the left crowd's front row, feet as drawn (Bar 2026-10-01: from the left)
const SLOT_ART_START := 66            # the leader's slot starts here: he never stops right of it
const WALK_AP_S := 31.0               # CONTRACT §4: travel ≈ 31 art px/s, feet planted
const AP := 4.0
const REACH_AP := 23.0                # the walk's widest reach from the feet (CONTRACT §4)
const OFF_MARGIN := 16.0
const PLANT_FPS := 12.0               # block_in 4 @ 12
const GLANCE_AFTER_MS := 3000.0       # into the hold
const RM_FADE_MS := 150.0

var reduced_motion := false
## func(name: String) for the cue markers (spec §11): mdEnter, mdBlock, mdRelease, mdExit. The Audio
## Director picks the sounds; an unknown name is dropped by the Audio runtime.
var on_marker: Callable

var strip: SpriteStrip
var _mode := "gone"                   # gone | in | plant | hold | release | out
var _x := 0.0                         # the feet's x, stage-local logical
var _t := 0.0
var _glanced := false
var _walk_in_next := false            # set by the fire event: the next live blockade walks in


## The feet mark, stage-local (the diorama's coordinates): the stage art is placed so its
## magicianFeet slot lands on the leader's feet.
static func mark() -> Vector2:
	var mf: Array = SpriteStrip.manifest().get("magicianFeet", [94, 219])
	return L.magician_feet() + (MARK_ART - Vector2(float(mf[0]), float(mf[1]))) * AP


## Fully off the canvas on the left (the stage column sits at canvas x L.sox(), so the canvas's left
## edge is stage-local −L.sox()).
static func off_x() -> float:
	return -L.sox() - REACH_AP * AP - OFF_MARGIN


func _ready() -> void:
	strip = SpriteStrip.make(self, CHAR, Vector2.ZERO)
	visible = false


## The live blockade or screen-block effect, or {}.
static func live(s: GameState) -> Dictionary:
	if s == null:
		return {}
	for a: Dictionary in Events.active_effects(s):
		if ["blockade", "screenBlock"].has(str(a.get("type", ""))):
			return a
	return {}


func showing() -> bool:
	return _mode != "gone"


func mode() -> String:
	return _mode


## The fire event: walk in (a figure first seen without it, after a load, stands on the mark).
func on_fire() -> void:
	_walk_in_next = true


func _walk_in_ms() -> float:
	return maxf(0.0, mark().x - off_x()) / (WALK_AP_S * AP) * 1000.0


## How long before the effect ends the release starts, so he is off the canvas at the end.
func release_lead_ms() -> float:
	if reduced_motion:
		return RM_FADE_MS
	return 4.0 / PLANT_FPS * 1000.0 + _walk_in_ms()


func update_view(dt_ms: float, s: GameState, on_stage: bool) -> void:
	if strip == null:
		return
	var a := live(s) if on_stage else {}
	var left_ms := float(a.get("leftSec", 0.0)) * 1000.0
	if a.is_empty():
		if not on_stage:
			_go()
		elif _mode in ["in", "plant", "hold"]:
			_start_release()   # an election or a reset cleared it early: he still leaves
	elif (_mode == "gone" or _mode == "out") and left_ms > release_lead_ms() + 500.0:
		# (re)enter only with time to leave again: a figure just gone with a few ms of effect left
		# would otherwise pop back on his mark and walk out twice
		_enter(_walk_in_next)
	elif _mode in ["in", "plant", "hold"] and left_ms <= release_lead_ms():
		_start_release()
	_walk_in_next = false
	_step(dt_ms)


func _enter(walk: bool) -> void:
	visible = true
	_glanced = false
	_t = 0.0
	if reduced_motion:
		_mode = "hold"
		_place(mark().x, 1.0)
		strip.play("block")
		strip.paused = true
		strip.frame = 0
		modulate.a = 0.0
		_marker("mdEnter")
		return
	if walk:
		_mode = "in"
		_place(off_x(), 1.0)
		strip.paused = false
		strip.play("walk")
		_marker("mdEnter")
	else:
		_mode = "hold"
		_place(mark().x, 1.0)
		strip.paused = false
		strip.play("block")


func _start_release() -> void:
	_mode = "release"
	if reduced_motion:
		_t = 0.0
		return
	_t = 0.0
	_place(minf(_x, mark().x), 1.0)
	strip.play("block_in")
	strip.paused = true
	strip.frame = strip.frame_count() - 1
	strip.queue_redraw()
	_marker("mdRelease")


func _go() -> void:
	if _mode != "gone":
		_marker("mdExit")
	_mode = "gone"
	visible = false
	modulate.a = 1.0


## Feet at stage-local x, facing `dir` (1 = as drawn, screen-right, toward the leader; -1 = flip_h,
## screen-left). Whole art px only.
func _place(x: float, dir: float) -> void:
	_x = x
	position = Vector2(roundf(x / AP) * AP, mark().y)
	scale = Vector2(dir, 1.0)


func _step(dt_ms: float) -> void:
	if _mode == "gone":
		return
	_t += dt_ms
	if reduced_motion:
		match _mode:
			"hold":
				modulate.a = minf(1.0, _t / RM_FADE_MS)
			"release":
				modulate.a = maxf(0.0, 1.0 - _t / RM_FADE_MS)
				if _t >= RM_FADE_MS:
					_go()
		return
	var v := WALK_AP_S * AP / 1000.0
	match _mode:
		"in":
			var x := minf(mark().x, _x + v * dt_ms)
			_place(x, 1.0)
			if x >= mark().x:
				_mode = "plant"
				_t = 0.0
				_place(mark().x, 1.0)
				strip.play("block_in", true, 1)   # f0 is the idle rest pose (the cast seam rule)
		"plant":
			if strip.anim == "block_in" and _t >= float(strip.frame_count()) / PLANT_FPS * 1000.0:
				_mode = "hold"
				_t = 0.0
				strip.play("block")
				_marker("mdBlock")
		"hold":
			if not _glanced and _t >= GLANCE_AFTER_MS:
				_glanced = true
				strip.play("glance")
			elif strip.anim == "glance" and strip.frame >= strip.frame_count() - 1 and _t >= GLANCE_AFTER_MS + 1000.0:
				strip.play("block")
		"release":
			var f := strip.frame_count() - 1 - int(floorf(_t / (1000.0 / PLANT_FPS)))
			if f >= 0:
				strip.frame = f
				strip.queue_redraw()
			else:
				_mode = "out"
				_t = 0.0
				strip.paused = false
				strip.play("walk")
		"out":
			var x := _x - v * dt_ms
			_place(x, -1.0)
			if x <= off_x():
				_go()
	if not strip.paused:
		strip.update_view(dt_ms)


func _marker(name: String) -> void:
	if on_marker.is_valid():
		on_marker.call(name)


# ------------------------------------------------------------------ copy (spec §3, §7.3, §8)

## The event's copy for this round's leader: copy.skins[leader id] (also with the dash dropped:
## "ben-gvir" → "bengvir"), then copy.skins[side], then the default. A skin overrides only its keys.
static func copy_for(leader_id: String, side: String) -> Dictionary:
	var e := Events.event(EVENT_ID)
	var c: Dictionary = (e.get("copy", {}) as Dictionary).duplicate()
	var skins: Dictionary = c.get("skins", {}) if c.get("skins") is Dictionary else {}
	for k in [leader_id, leader_id.replace("-", ""), side]:
		if k != "" and skins.get(k) is Dictionary:
			c.merge(skins[k] as Dictionary, true)
			break
	c.erase("skins")
	return c


## {name} (the stuck partner's name this round) and {sec} (the effect's length).
static func fill(text: String, partner_id: String) -> String:
	var e := Events.event(EVENT_ID)
	var sec := int(float((e.get("effect", {}) as Dictionary).get("sec", 20)))
	return Bidi.fill(text, {"name": ChatView.partner_name(partner_id) if partner_id != "" else "", "sec": str(sec)})


## The avatar for the chat-style toast: [art id, logical px per sprite px, density].
static func toast_avatar() -> Array:
	var c: Dictionary = SpriteStrip.manifest().get("chars", {}).get(CHAR, {})
	var art := str(c.get("avatar", "avatar_" + CHAR))
	if not Art.has_sprite(art):
		return ["", 4.0, 1]
	var dens := maxi(1, int(c.get("avatarDensity", Art.kit(art).get("density", 1))))
	var sc := float(SpriteStrip.art_scale()) / float(dens)
	return [art, sc, maxi(1, int(roundf(float(SpriteStrip.art_scale()) / maxf(0.001, sc))))]
