class_name BigBanana
extends Node2D
## The Big Banana: motion/state-graph-spec.md §1-3 (body, aura and hover as orthogonal regions)
## and motion/object-motion.md §1. The squash is a quantized driver: a number y is eased and mapped
## to one of the 5 drawn frames. No scale is ever applied to the banana itself.
##
## od-sevev: when the TA's cast strips are present, the round's leader (SpriteStrip, set_leader:
## leaders[].art, default "bibi") stands in for the banana: idle loops, a tap plays `tap`, a crit
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
## func(kind: String, at: Vector2, n: int) for the court day's stage FX (stage coordinates): "dust" at
## the feet (a zip leaving or landing), "coins" (n) from the hat's mouth, "rabbit" (the hat's crit).
var on_court_fx: Callable
var hero: SpriteStrip
## Bibi's court-day exit and return (CourtMotion; motion/state-graph-magician.md §1.3, §3, §5).
var court := CourtMotion.new()
## The leader swap's walk-out / walk-in (LeaderWalk; spec §9.3.4). BigBanana is the one owner of the
## figure's position, visibility and alpha: `_apply_figure` composes the walk's pose with the court
## day's every frame, and the court yields while a walk runs (it neither starts nor ticks the body).
var walk := LeaderWalk.new()
var _court_pending := false           # courtStart came mid-tap: he leaves when the strip is back on idle
var _suppress_coins := false          # the land / flinch reuse the tap strip: no coins
var _held_frame := -1                 # the tap-strip frame the court holds (-1 = the strip plays)
var _hat: Sprite2D                    # prop_hat, left on the mark while he testifies
var _hat_ghost: Sprite2D              # its one after-image while it zips
var _rabbit: Sprite2D                 # prop_rabbit, behind the hat
var _rabbit_clip: Control             # the hat's opening: the rabbit shows only above it
var _smears: Array[CourtSmear] = []
var _mark := Vector2.ZERO             # the hat's mouth on idle.f0 (stage coordinates), the hat's mark
## What takes the mark while the leader is off (LeaderUi.stage_skin): "court" = Bibi's hat and rabbit;
## "podium" / "bench" = a PressDesk on the feet, riding the hat's track (Bar, 2026-10-01: every leader).
var court_skin := "court"
var _desk: PressDesk
## Leaders v3: an ability's held pose (flash_pose), a second SpriteStrip on the hero's feet while the
## hero strip hides; _pose_ms counts down to the hero's return (<0 = none showing).
var _pose: SpriteStrip
var _pose_ms := -1.0

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
## The round's leader (spec §5.2): the tap kit, the loose prop and the manifest's prop entry.
var prop: Sprite2D
var _kit: Dictionary = {}
var _prop_info: Dictionary = {}
var _prop_frame := 0
var _prop_squash_ms := 0.0


## A loose prop held in the hand draws at this scale (logical px per art px; the art scale is 4).
const HELD_PROP_SCALE := 2

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
	set_leader(LeaderUi.art(), LeaderUi.tap())
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


# ------------------------------------------------------------------ the round's leader (spec §5.2)

## Stands the round's leader on the stage (design/leader-select-spec.md §5.2, CONTRACT.md §4c):
## `slug` is the manifest character, `kit` its tap kit (LeaderUi.tap). Only this leader's strips
## are resident: a swap frees the old SpriteStrip (and so its textures) before the new one loads
## (CONTRACT §7 budget). A leader whose prop is not baked into the render (pen, phone, ruler,
## chair, stapler) gets the kit prop drawn at `propMouth` every frame, above the figure; a tap
## squashes it (frame 1) on the pointer-down frame. The same slug again only refreshes the kit.
func set_leader(slug: String, kit: Dictionary) -> void:
	_kit = kit.duplicate()
	if hero != null and hero.char_id == slug:
		return
	end_pose()
	if hero != null:
		body.remove_child(hero)
		hero.queue_free()
		hero = null
	_suppress_coins = false
	if prop != null:
		body.remove_child(prop)
		prop.queue_free()
		prop = null
	_prop_info = {}
	_prop_frame = 0
	hero = SpriteStrip.make(body, slug, L.magician_feet())
	court_skin = LeaderUi.stage_skin_for_art(slug)
	walk.home()
	var on := hero != null
	for n: CanvasItem in [halo, sprite, flash, fidget]:
		n.visible = not on and (n == sprite or n == halo)   # the banana stands in (flash/fidget show on demand)
		n.set_process(not on)
	if not on:
		return
	var c: Dictionary = SpriteStrip.manifest().get("chars", {}).get(hero.char_id, {})
	var pi: Variant = c.get("prop")
	_prop_info = pi if pi is Dictionary else {"id": "prop_hat", "baked": true, "track": "hatMouth"}
	var pid := str(_prop_info.get("id", ""))
	if _prop_info.get("baked", true) != true and pid != "" and Art.has_sprite(pid):
		prop = Sprite2D.new()
		prop.centered = false
		prop.texture = Art.tex(pid, 0)
		var pv: Array = Art.kit(pid).get("pivot", [0, 0])
		prop.offset = -Vector2(float(pv[0]), float(pv[1]))
		# held in the hand (pen, phone, stapler): hand-sized, ×2, its grip (the pivot) on the palm; a
		# prop on the floor or in the air (chair, ruler) keeps the art scale (Bar 2026-10-03: the pen
		# floated beside Bennett's hand at twice its size)
		var held := str(_prop_info.get("path", "held")) == "held"
		prop.scale = Vector2.ONE * (float(HELD_PROP_SCALE) if held else 4.0)
		SpriteStrip.apply_filter(prop, prop.scale.x)
		body.add_child(prop)   # above the figure: it is in their hand
	hero.finished.connect(func(_a: String) -> void:
		_suppress_coins = false
		hero.play("idle"))
	hero.event.connect(func(ev: String, _f: int) -> void:
		if ev == "coins" and _suppress_coins:
			return
		if on_hero_event.is_valid():
			on_hero_event.call(ev, mouth_point()))
	_rebuild_court()
	_sync_prop()


## The court-day nodes (the Animator's CourtMotion: the hat on the mark, the rabbit, the smears)
## belong to one figure: a leader swap frees them and builds them for the new strip. The court
## runs in every round (wants_court): Bibi's hat, or the press desk (court_skin).
func _rebuild_court() -> void:
	for n: Node in [_rabbit_clip, _hat_ghost, _hat, _desk]:
		if n != null and is_instance_valid(n):
			n.get_parent().remove_child(n)
			n.queue_free()
	for g: CourtSmear in _smears:
		if is_instance_valid(g):
			g.get_parent().remove_child(g)
			g.queue_free()
	_smears.clear()
	_rabbit_clip = null
	_hat_ghost = null
	_hat = null
	_desk = null
	_rabbit = null
	_court_pending = false
	_held_frame = -1
	court.reset()
	if hero != null:
		_build_court()


## The manifest slug on stage ("" when the banana stands in).
func leader_slug() -> String:
	return hero.char_id if hero != null else ""


## Where coins leave this frame (stage coordinates): the loose prop's mouth, else the figure's
## track (`propMouth`; Bibi `hatMouth`), else a point at the chest.
func mouth_point() -> Vector2:
	if hero == null:
		return body.position + Vector2(L.BB["pivotX"], L.BB["pivotY"])
	if prop != null:
		var pts: Variant = Art.kit(str(_prop_info.get("id", ""))).get("points")
		var mo: Variant = (pts as Dictionary).get("mouth") if pts is Dictionary else null
		if mo is Array and not (mo as Array).is_empty():
			var m: Array = (mo as Array)[clampi(_prop_frame, 0, (mo as Array).size() - 1)]
			return body.position + prop.position + (Vector2(float(m[0]), float(m[1])) + prop.offset) * 4.0
		return body.position + prop.position
	var track := str(_prop_info.get("track", "hatMouth"))
	var fb := hero.point("hatMouth", Vector2(0, -hero.frame_size().y * 0.7))
	return hero.position + body.position + hero.point(track, fb)


## ftue.md P0 (merge review M4): the point the brightness pulse sits on, stage coordinates: the tap
## object's tracked point (`propMouth` for a leader with a prop; Bibi's baked hat at `hatMouth`), the
## same track `_sync_prop` draws the prop on. The P0 hand points here, not at the head.
func pulse_point() -> Vector2:
	if hero == null:
		return body.position + Vector2(L.BB["pivotX"], L.BB["pivotY"])
	var track := str(_prop_info.get("track", "hatMouth"))
	var fb := hero.point("hatMouth", Vector2(0, -hero.frame_size().y * 0.7))
	return Display.snap(body.position + hero.position + hero.point(track, fb))


## The loose prop follows the figure's track every frame and shows its squash frame while pressed.
func _sync_prop() -> void:
	if prop == null or hero == null:
		return
	var track := str(_prop_info.get("track", "propMouth"))
	prop.position = Display.snap(hero.position + hero.point(track, Vector2(-hero.frame_size().x * 0.4, -hero.frame_size().y * 0.5)))
	var f := 1 if _prop_squash_ms > 0.0 else 0
	if f != _prop_frame:
		_prop_frame = f
		prop.texture = Art.tex(str(_prop_info.get("id", "")), f)


## The prop's squash frame is showing (tests).
func prop_squashed() -> bool:
	return prop != null and _prop_frame == 1


## Hit area = the drawn sprite rect + bigBananaHitPadPx on every side. Never follows the frame.
func hit_rect() -> Rect2:
	if hero != null:
		return L.magician_hit()   # rtl-map §4: 376x416, bottom 20 px clear of the Suitcase band
	var p := float(Tune.T["bigBananaHitPadPx"])
	var r: Rect2 = L.BB["sprite"]
	return Rect2(r.position.x - p, r.position.y - p, r.size.x + 2 * p, r.size.y + 2 * p)


# ------------------------------------------------------------------ body graph

func tap(crit: bool, paused: bool = false) -> void:
	if _state == "locked":
		return
	if hero != null and (_court_pending or court.in_court()):
		court.tap(crit, paused)   # the hat takes it (or it is credited with nothing moving)
		return
	_suppress_coins = false
	var from := _state
	if from == "idle":
		_leave_idle()
	var restart := from == "pressed" or from == "crit"
	_state = "crit" if crit else "pressed"
	if hero != null:
		_prop_squash_ms = float(Tune.T["squashDownMs"]) + 40.0   # the prop's squash frame (spec §9.3.1)
		_sync_prop()
		var crit_anim := str(_kit.get("critAnim", "crit"))
		var tap_anim := str(_kit.get("anim", "tap"))
		# a tap during a leader's react drives the prop only (spec §5.2): the react plays out
		var in_react := not crit and crit_anim != "crit" and hero.anim == crit_anim
		if crit and hero.has_anim(crit_anim):
			hero.play(crit_anim, true, 1)
		elif not in_react:
			# v1.10: a tap on f1-f2 of the tap strip merges into it (motion spec): the strip runs on to
			# its coins frame instead of restarting, so fast taps still pour coins
			var merge := hero.anim == tap_anim and hero.frame >= 1 and hero.frame <= 2
			hero.play(tap_anim if hero.has_anim(tap_anim) else "idle", not merge, 1)
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
	if court.in_court():
		court.finish(true)   # electionConfirm while he testifies: the quick return (§5.2)
	_court_pending = false
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
		_update_pose(dt_ms)
		_update_court(dt_ms)
		hero.update_view(dt_ms)
		_pulse_t += dt_ms
		if _prop_squash_ms > 0.0:
			_prop_squash_ms -= dt_ms
		_sync_prop()
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
		_place_court()


## ux/ftue.md P0: the hat's brightness pulse (hz 0 = off; 1 Hz, 2 Hz at F3). Reduced motion
## shows a static bright rim instead.
func set_pulse(hz: float) -> void:
	_pulse_hz = hz


var _pulse_hz := 0.0
var _pulse_t := 0.0
## v1.10 (Bar: the beat glow): the music's beat phase (Audio.beat_phase(), -1 without music), set by
## main every frame. The figure brightens a little on each beat and fades by the next; visual only,
## off under reduced motion.
var beat_phase := -1.0
const BEAT_GLOW := 0.14


func _sync_halo() -> void:
	halo.modulate.a = maxf(_aura_alpha, _hover_alpha)
	if hero != null:
		var pulse := 0.0
		if _pulse_hz > 0.0:
			pulse = 0.35 if reduced_motion else 0.35 * (0.5 - 0.5 * cos(TAU * _pulse_hz * _pulse_t / 1000.0))
		if beat_phase >= 0.0 and not reduced_motion:
			pulse = maxf(pulse, BEAT_GLOW * pow(1.0 - beat_phase, 3.0))
		var k := maxf(maxf(_aura_alpha, _hover_alpha), pulse)
		hero.modulate = Color(1, 1, 1).lerp(Color(1.3, 1.25, 1.05), k)
		hero.modulate.a = figure_alpha()
		if prop != null:   # rtl-map §4.3: P0's pulse sits on the prop too; it leaves with the figure
			prop.modulate = hero.modulate
			prop.visible = hero.visible   # (hidden under a flash_pose too: the pose holds its own props)
		if _pose != null:
			_pose.modulate = hero.modulate


## FTUE failure branch: a pulsed emphasis on the banana (through the halo).
func emphasize(ms: float) -> void:
	if _hover_tw:
		_hover_tw.kill()
	_hover_tw = create_tween().set_loops(2)
	var q := ms / 4000.0
	_hover_tw.tween_property(self, "_hover_alpha", 0.6, q)
	_hover_tw.tween_property(self, "_hover_alpha", 0.0, q)


# ------------------------------------------------------------------ the hazard day (every leader)

## Is this state's hazard day on the stage now? Bibi's court day, or any other leader's press day
## (Bar, 2026-10-01: "not only Bibi"): the leader zips off and the mark holds the hat (court_skin
## "court") or a PressDesk (podium / bench) until the day ends.
static func wants_court(s: GameState) -> bool:
	return s != null and Investigation.active() and Investigation.phase(s) == "court"


## Every frame from the controller: `want` = the court day is running (wants_court, main mode);
## `quick` = an election is taking over (the hat fetches him at once, no empty beat). Polling the
## phase (not only the events) keeps the stage right through a load, an election or an aide drop.
func court_sync(want: bool, quick: bool = false) -> void:
	if hero == null:
		return
	if want and not court.in_court():
		if walk.walking() or walk.gone():
			_court_pending = true   # the court yields to the walk: he leaves after he has landed
			return
		if hero.anim != "idle":
			_court_pending = true   # exitPending: he leaves at the strip's end (§2)
			return
		_court_pending = false
		end_pose()   # the court day takes the figure: a held pose gives way at once
		_leave_idle()
		court.off_ap = off_stage_ap()
		court.start(reduced_motion)
	elif not want:
		_court_pending = false
		if court.in_court():
			court.finish(quick)


## A progress reset (O10) or a new state: he is simply home, the hat gone.
func court_reset() -> void:
	_court_pending = false
	end_pose()
	court.reset()
	walk.home()
	if hero != null:
		_hold_frame(-1)
		_place_court()
		_apply_court_pose()


## The summons flinch (§1.3): `land` from f1, no coins, no dust; only from idle.
func court_flinch() -> void:
	if hero == null or court.in_court() or _state != "idle" or hero.anim != "idle":
		return
	_suppress_coins = true
	hero.play("tap", true, 1)


## True while the Magician stands on his mark and is drawn (the sweat reads it).
func on_stage() -> bool:
	return hero == null or (not court.in_court() and walk.state() == "home" and (hero.visible or posing()))


## The hat's mark (stage coordinates): its mouth on idle.f0, where it hovers on court day.
func hat_mark() -> Vector2:
	return _mark


func hat_node() -> Sprite2D:
	return _hat


## How far left of the mark the figure is fully off the canvas, in art px (the widest the canvas
## gets is the viewport, _ox to the left of the design canvas).
func off_stage_ap() -> float:
	if hero == null:
		return -170.0
	var right := hero.rect().end.x   # the frame's right edge from the feet (logical)
	return -ceilf((L.magician_feet().x + _stage_ox() + right + 8.0 * CourtMotion.AP) / CourtMotion.AP)


## The stage column's x on the canvas (the widest the canvas gets is the viewport, this far to the
## left of the design canvas, and as far to the right).
func _stage_ox() -> float:
	var h := get_parent()
	while h != null and not "_sx" in h:
		h = h.get_parent()
	return float(h.get("_sx")) if h != null else 0.0


# ------------------------------------------------------------------ the leader swap (spec §9.3.4)

## The figure's rect from the feet (logical), its loose prop included: what must clear the canvas.
func _figure_rect() -> Rect2:
	var r := hero.rect()
	if prop != null and prop.texture != null:
		var pr := Rect2(prop.position - hero.position + prop.offset * prop.scale, Vector2(prop.texture.get_size()) * prop.scale)
		r = r.merge(pr)
	return r


## EVOLVE_TX, the card lifting: the leader walks off screen-right (560 ms Sine.In; reduced motion a
## 150 ms fade on the mark). A court day is cut home first (he is under the card when it ends).
## False without a figure (the banana stand-in has no walk).
func walk_out() -> bool:
	if hero == null:
		return false
	end_pose()
	if court.in_court() or _court_pending:
		court.reset()
		_court_pending = false
		_hold_frame(-1)
	walk.feet = L.magician_feet()
	walk.reduced = reduced_motion
	walk.walk_out(1, _figure_rect(), _stage_ox())
	hero.visible = true
	if hero.anim != "idle":
		hero.play("idle")
	_apply_figure()
	return true


## After the pick commit: the round's leader walks in from screen-left to the feet point (640 ms
## Sine.Out; reduced motion a 150 ms fade on the mark). Taps during the walk play on the moving
## figure (never dropped, never a pop); the court waits for the landing.
func walk_in() -> bool:
	if hero == null:
		return false
	end_pose()
	walk.feet = L.magician_feet()
	walk.reduced = reduced_motion
	walk.walk_in(-1, _figure_rect(), _stage_ox())
	hero.visible = true
	if hero.anim != "idle" and _state != "pressed" and _state != "crit":
		hero.play("idle")
	_apply_figure()
	return true


## A walk-in ends on the mark now (the controller's instant path: tests and tools).
func walk_land() -> void:
	walk.land()
	_apply_figure()


## A walk is running (out or in).
func walking() -> bool:
	return walk.walking()


## ms left in the running walk (0 when none): the controller times Dubi's line after the landing.
func walk_left_ms() -> float:
	return walk.left_ms()


## The figure is off the canvas after a walk-out (until the next walk-in or a reset).
func walked_off() -> bool:
	return walk.gone()


func _build_court() -> void:
	var rabbit_id := Art.sprite_or("prop_rabbit")
	var hat_id := Art.sprite_or("prop_hat")
	# the rabbit sits in a clip whose bottom is 1 ap inside the hat's opening: at rest the hat hides it
	_rabbit_clip = Control.new()
	_rabbit_clip.clip_contents = true
	_rabbit_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(_rabbit_clip)
	_rabbit = Ui.img(_rabbit_clip, Vector2.ZERO, rabbit_id, 0, 4)
	_hat_ghost = Ui.img(body, Vector2.ZERO, hat_id, 0, 4)
	_hat_ghost.modulate.a = 0.4
	_hat = Ui.img(body, Vector2.ZERO, hat_id, 0, 4)
	_desk = PressDesk.new()
	_desk.set_kind(court_skin)
	_desk.visible = false
	body.add_child(_desk)
	for i in 2:
		var g := CourtSmear.new()
		g.strip = hero
		g.alpha = 0.5 if i == 0 else 0.25
		g.visible = false
		body.add_child(g)
		body.move_child(g, hero.get_index())   # behind the body
		_smears.append(g)
	_place_court()
	_apply_court_pose()


func _place_court() -> void:
	if hero == null:
		return
	var feet := L.magician_feet()
	var arr: Variant = (hero._c.get("anims", {}) as Dictionary).get("idle", {}).get("hatMouth")
	var mouth := Vector2(0, -hero.frame_size().y * 0.7)
	if arr is Array and not (arr as Array).is_empty():
		var p: Array = (arr as Array)[0]
		mouth = (Vector2(float(p[0]), float(p[1])) - hero._anchor()) * hero.scale_px
	_mark = (feet + mouth).snapped(Vector2(CourtMotion.AP, CourtMotion.AP))
	walk.feet = feet
	_apply_figure()


func _update_court(dt_ms: float) -> void:
	walk.advance(dt_ms)
	if _court_pending and hero.anim == "idle" and not walk.walking() and not walk.gone():
		court_sync(true)
	court.tick(dt_ms)
	for e: Dictionary in court.take_events():
		match str(e["kind"]):
			"land":
				_hold_frame(-1)
				_suppress_coins = true
				hero.play("tap", true, int(e.get("from", 1)))
				_state = "idle"
				if bool(e.get("dust", false)):
					_court_fx("dust", L.magician_feet(), 0)
			"dust":
				_court_fx("dust", L.magician_feet(), 0)
			"coins":
				_court_fx("coins", _hat_mouth(), int(e.get("n", 1)))
			"rabbit":
				if court_skin == "court":
					_court_fx("rabbit", _hat_mouth(), 0)
	_apply_court_pose()


func _court_fx(kind: String, at: Vector2, n: int) -> void:
	if on_court_fx.is_valid():
		on_court_fx.call(kind, at + body.position, n)


## The hat's opening now (top centre of the prop), stage coordinates minus body offset.
func _hat_mouth() -> Vector2:
	return _mark + Vector2(court.hat_dx_ap(), court.hat_dy_ap()) * CourtMotion.AP


func _hold_frame(f: int) -> void:
	if f == _held_frame:
		return
	_held_frame = f
	if f < 0:
		hero.paused = false
		if hero.anim != "tap":
			hero.play("idle")
		return
	hero.play("tap", true, f)
	hero.paused = true


## The one writer of the figure's position, visibility and alpha: the mark, plus the court day's
## zip offset, plus the walk's travel and bob (whole art px each, so the sum is whole art px). The
## court and the walk never both move him: the walk cuts the court home when it starts, and the court
## does not start while a walk runs or he is off after a walk-out.
func _apply_figure() -> void:
	if hero == null:
		return
	var feet := L.magician_feet()
	hero.position = feet + Vector2(float(court.body_dx_ap() + walk.dx_ap()), float(walk.dy_ap())) * CourtMotion.AP
	hero.visible = court.body_visible() and walk.shows()
	hero.modulate.a = figure_alpha()
	if _pose != null:   # a held pose stands in for the hero on the same feet (flash_pose)
		_pose.position = hero.position
		_pose.scale = hero.scale
		_pose.visible = hero.visible
		_pose.modulate = hero.modulate
		hero.visible = false


## The figure's alpha: the court's fades times the walk's (reduced motion) fades.
func figure_alpha() -> float:
	return court.body_alpha() * walk.alpha()


func _apply_court_pose() -> void:
	if hero == null:
		return
	if _hat == null:
		_apply_figure()
		return
	var in_c := court.in_court()
	if in_c:
		var f := court.body_frame()
		if f >= 0:
			_hold_frame(f)
		elif _held_frame >= 0:
			_held_frame = -1
			hero.paused = false
			hero.play("idle")
	_apply_figure()
	var dir := court.travel_dir()
	for i in _smears.size():
		var g := _smears[i]
		g.visible = court.smear() and hero.visible
		# the after-images trail behind the travel, 6 and 12 ap back
		g.position = hero.position - Vector2(float(dir) * 6.0 * float(i + 1) * CourtMotion.AP, 0.0)
		g.queue_redraw()
	# the hat: 22×16, its mouth (top centre) on the mark; the rabbit behind it, rising out of it
	var hsz := Vector2(Art.sprite_size(_hat.get_meta("sprite"))) * 4.0
	var mouth := _hat_mouth()
	_hat.visible = court.hat_visible()
	_hat.position = (mouth - Vector2(hsz.x / 2.0, 0.0)).snapped(Vector2(CourtMotion.AP, CourtMotion.AP))
	_hat.modulate.a = court.hat_alpha()
	_hat_ghost.visible = _hat.visible and court.hat_smear()
	var hdir := -1.0 if court.hat == "zipOut" else 1.0
	_hat_ghost.position = _hat.position - Vector2(hdir * 6.0 * CourtMotion.AP, 0.0)
	var rsz := Vector2(Art.sprite_size(_rabbit.get_meta("sprite"))) * 4.0
	var up := float(court.rabbit_up_ap()) * CourtMotion.AP
	_rabbit_clip.visible = _hat.visible and up > 0.0
	# the clip ends 1 ap below the hat's top edge; the rabbit's bottom rests 1 ap inside the hat
	_rabbit_clip.position = Vector2(_hat.position.x + Ui.snap((hsz.x - rsz.x) / 2.0, CourtMotion.AP), _hat.position.y + CourtMotion.AP - rsz.y - CourtMotion.CRIT_AP * CourtMotion.AP)
	_rabbit_clip.size = Vector2(rsz.x, rsz.y + CourtMotion.CRIT_AP * CourtMotion.AP)
	_rabbit.position = Vector2(0.0, _rabbit_clip.size.y - up).snapped(Vector2(CourtMotion.AP, CourtMotion.AP))
	_rabbit.modulate.a = court.hat_alpha()
	if court_skin != "court":
		# a press day: the desk rides the hat's x track on the feet (zip in, hush wiggle, zip out); no hat,
		# no rabbit, no bob
		_desk.visible = _hat.visible
		_desk.position = (L.magician_feet() + Vector2(float(court.hat_dx_ap()) * CourtMotion.AP, 0.0)).snapped(Vector2(CourtMotion.AP, CourtMotion.AP))
		_desk.modulate.a = court.hat_alpha()
		_hat.visible = false
		_hat_ghost.visible = false
		_rabbit_clip.visible = false
	else:
		_desk.visible = false


## Leaders v3: an ability's held pose (sprites.json `<leader>-<pose>`, e.g. "bennett-sign",
## "ben-gvir-walkout"): the hero strip hides and the pose strip stands on the same feet for `ms`, then
## the hero is back. The pose char is rendered at the leader's scale and feet line, so the swap does not
## jump. False (nothing changes) without that character, or while the hero is away: walking, off after
## a walk-out, or on a court/press day (pending or running). Again while one shows: the same pose
## restarts its timer, another pose replaces it. A court day, a walk or a leader swap ends it at once.
func flash_pose(char_id: String, ms: float = 1200.0) -> bool:
	if hero == null or not SpriteStrip.has_char(char_id):
		return false
	if court.in_court() or _court_pending or walk.walking() or walk.gone() or walk.state() != "home":
		return false
	var slug := SpriteStrip.resolve(char_id)
	if _pose != null and _pose.char_id != slug:
		end_pose()
	if _pose == null:
		_pose = SpriteStrip.make(body, slug, hero.position, "pose")
		if _pose == null:
			return false
		if not _pose.has_anim("pose"):
			_pose.play("idle")
		body.move_child(_pose, hero.get_index() + 1)   # where the hero draws: under a loose prop, over the smears
	_pose.paused = reduced_motion   # reduced motion: the held pose, no breath
	_pose_ms = maxf(ms, 1.0)
	_apply_figure()
	return true


## A flash_pose is showing.
func posing() -> bool:
	return _pose != null


## The pose strip (tests): null when none shows.
func pose_node() -> SpriteStrip:
	return _pose


## Ends a flash_pose now: the pose strip is freed and the hero shows again (no-op when none shows).
func end_pose() -> void:
	_pose_ms = -1.0
	if _pose == null:
		return
	if is_instance_valid(_pose):
		if _pose.get_parent() != null:
			_pose.get_parent().remove_child(_pose)
		_pose.queue_free()
	_pose = null
	_apply_figure()


func _update_pose(dt_ms: float) -> void:
	if _pose == null:
		return
	_pose_ms -= dt_ms
	if _pose_ms <= 0.0 or court.in_court() or walk.walking() or walk.gone():
		end_pose()
		return
	_pose.update_view(dt_ms)


## Leaders v3: what holds the mark for an away that isn't the hazard day ("box": Ben Gvir's walkout);
## "" = the round's own stage skin (LeaderUi.stage_skin). Applied while he is on stage or away.
func set_away_kind(kind: String) -> void:
	if kind == "" and court.in_court():
		return   # the box zips out as a box; the podium comes back once he has landed
	var want := kind if kind != "" else LeaderUi.stage_skin_for_art(hero.char_id if hero != null else "")
	if want == court_skin:
		return
	if court_skin == "court" or want == "court":
		return   # Bibi's hat never swaps (he has no walkout)
	court_skin = want
	if _desk != null:
		_desk.set_kind(want)


## The press desk on the mark (tests): null in Bibi's round or before the figure is built.
func desk_node() -> PressDesk:
	return _desk


## One after-image of the Magician's current frame (§2 `smear: on`): the strip's own texture region,
## drawn at the strip's scale behind it, at a fixed alpha. Never a scaled or rotated copy.
class CourtSmear:
	extends Node2D
	var strip: SpriteStrip
	var alpha := 0.5

	func _draw() -> void:
		if strip == null or strip._tex == null or strip.frame < 0:
			return
		material = strip.material
		draw_texture_rect_region(strip._tex, Rect2(strip._origin(), strip.frame_size()), strip._src(strip.frame), Color(1, 1, 1, alpha))
