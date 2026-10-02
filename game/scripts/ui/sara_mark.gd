class_name SaraMark
extends Node2D
## Sara on the Balfour stage (motion/state-graph-cast.md §3; pitch §6: a Balfour-era presence). Bar, 2026-09-30: option B (creative-pack/art/sara-options/), right of the
## leader in front of the right crowd, facing him as drawn. Bibi's round only
## (leaderSelect.bibiOnly.systems "Sara's mark"), Balfour only.
##
## Bar, 2026-10-02: she IS the tap target while she is on the stage (this overrides the cast spec's
## "not a tap target"). From the moment she walks in, a tap on the leader earns nothing: it is
## swallowed, she huffs and the toast says to tap her (main._on_sara_block). A tap on her (or Space)
## sends her off (main._tap_sara) and the leader takes taps again. She stays until she is tapped, so
## the cue must be unmissable: a gold arrow bobs over her head and pulses on every wrong tap.
##
## Bar, 2026-10-01: not on stage the whole round. She comes for VISITS: she walks in from the right,
## stays until she is tapped and walks out. A visit starts on her joke, the bottle-deposit spin S01 (she
## huffs, `offended`, 150 ms after she arrives or after the purchase if she is already there; an 8 s
## cooldown drops triggers inside it), and as a passing cameo every CAMEO_EVERY_MS of eligible play
## (the first after CAMEO_FIRST_MS). The old seat `blockade` and Herzog's outline both stand on her mark,
## so she steps off while one holds. Reduced motion: no walk, she appears and leaves in place.

const CHAR := "sara"
const MARK_ART := Vector2(150, 221)       # the right crowd's front row, feet as drawn (StreetFigure's mark)
const AP := 4.0
const OFFEND_DELAY_MS := 150.0
const OFFEND_COOLDOWN_MS := 8000.0
const TRIGGER_UPGRADE := "s01"
const CAMEO_FIRST_MS := 45000.0           # eligible play before the first cameo
const CAMEO_EVERY_MS := 90000.0           # then between cameos (counted while she is away)
const WALK_MS := 520.0
const OFF_X := 520.0                      # logical px right of the mark: off the stage's right edge
const HIT_PAD := 16.0                     # logical px around the strip's frame (her tap box)
const ARROW_GAP := 12.0                   # logical px between her head and the arrow's tip
const NUDGE_MS := 420.0                   # the arrow's pulse after a wrong tap
const ARROW := "ui_arrow_up"              # the kit's 8 x 8 arrow, flipped to point down at her, in gold
const ARROW_GOLD := Color("#ffd23a")

var strip: SpriteStrip
var reduced_motion := false
var state := ""                           # "" (away) | enter | stay | exit
var _t := 0.0
var _away_ms := 0.0
var _cameo_due := CAMEO_FIRST_MS
var _huff_on_arrival := false
var _pending_ms := -1.0
var _since_ms := 1.0e9
var _bob := 0.0
var _arrow: Sprite2D
var on_arrive: Callable                   # main: the "tap her" toast as she walks in
var _nudge := 0.0


## Her feet, stage-local: the stage art is placed so its magicianFeet slot lands on the leader's feet.
static func mark() -> Vector2:
	var mf: Array = SpriteStrip.manifest().get("magicianFeet", [94, 219])
	return L.magician_feet() + (MARK_ART - Vector2(float(mf[0]), float(mf[1]))) * AP


## She may visit: Bibi's round, in Balfour, and not while the blockade or Herzog holds her mark.
static func wanted(s: GameState, on_stage: bool) -> bool:
	return on_stage and s != null and Leaders.is_default(Leaders.current(s)) and not Events.is_active(s, "blockade") \
		and not Events.is_active(s, "mediation")   # Herzog stands on her mark while his outline is up


func _ready() -> void:
	strip = SpriteStrip.make(self, CHAR, Vector2.ZERO)
	_arrow = Ui.img(self, Vector2.ZERO, ARROW)
	_arrow.flip_v = true
	_arrow.modulate = ARROW_GOLD
	_arrow.visible = false
	visible = false
	position = mark()


func showing() -> bool:
	return visible


## She takes the tap (and the leader takes none) from the moment she walks in until she is tapped.
func tappable() -> bool:
	return visible and (state == "enter" or state == "stay")


## Her tap box in stage-local px (empty when she takes no tap): the frame grown by HIT_PAD, plus the
## arrow over her head.
func hit_rect() -> Rect2:
	if not tappable():
		return Rect2()
	var r := strip.rect()
	r = Rect2(position + r.position, r.size)
	r = r.expand(Vector2(r.get_center().x, r.position.y - ARROW_GAP - _arrow.texture.get_size().y * AP))
	return r.grow(HIT_PAD)


## A tap on her: she walks off at once (a pending huff is dropped) and the leader takes taps again.
func tap() -> void:
	if not tappable():
		return
	_pending_ms = -1.0
	_huff_on_arrival = false
	strip.play("idle", true, 0)
	_arrow.visible = false
	if state == "enter":
		# mid-walk: turn round from where she is (the exit curve starts at the same offset)
		var m := mark()
		var k := clampf((position.x - m.x) / OFF_X, 0.0, 1.0)
		_t = sqrt(k) * WALK_MS
	else:
		_t = 0.0
	state = "exit"


## A tap on the leader while she waits: she huffs (outside the huff cooldown) and the arrow pulses.
func nudge() -> void:
	_nudge = NUDGE_MS
	if strip.anim != "offended" and _pending_ms < 0.0 and _since_ms >= 1000.0:
		_since_ms = 0.0
		strip.play("offended", true, 1)


## The S01 purchase (main.gd): she comes in to huff, or huffs where she stands (the reaction delay,
## unless the cooldown is running).
func offend() -> void:
	if strip == null or _since_ms < OFFEND_COOLDOWN_MS or _pending_ms >= 0.0 or strip.anim == "offended":
		return
	if state == "" or state == "exit":
		_huff_on_arrival = true
		_visit()
		return
	_pending_ms = OFFEND_DELAY_MS


func _visit() -> void:
	visible = true
	state = "enter"
	_t = 0.0
	strip.play("idle", true, randi() % maxi(1, strip.frame_count()))
	if on_arrive.is_valid():
		on_arrive.call()


func update_view(dt_ms: float, s: GameState, on_stage: bool) -> void:
	if strip == null:
		return
	if not wanted(s, on_stage):
		visible = false
		state = ""
		_pending_ms = -1.0
		_huff_on_arrival = false
		return
	_since_ms += dt_ms
	var m := mark()
	if state == "":
		_away_ms += dt_ms
		if _away_ms >= _cameo_due:
			_cameo_due = CAMEO_EVERY_MS
			_visit()
		else:
			visible = false
			return
	_t += dt_ms
	match state:
		"enter":
			var k := 1.0 if reduced_motion else clampf(_t / WALK_MS, 0.0, 1.0)
			position = Vector2(m.x + OFF_X * pow(1.0 - k, 2.0), m.y)
			if k >= 1.0:
				state = "stay"
				if _huff_on_arrival:
					_huff_on_arrival = false
					_pending_ms = OFFEND_DELAY_MS
		"stay":
			position = m   # until she is tapped (tap())
		"exit":
			var k2 := 1.0 if reduced_motion else clampf(_t / WALK_MS, 0.0, 1.0)
			position = Vector2(m.x + OFF_X * k2 * k2, m.y)
			if k2 >= 1.0:
				state = ""
				visible = false
				_away_ms = 0.0
	if _pending_ms >= 0.0:
		_pending_ms -= dt_ms
		if _pending_ms < 0.0:
			_pending_ms = -1.0
			_since_ms = 0.0
			strip.play("offended", true, 1)
	if strip.anim == "offended" and strip.frame >= strip.frame_count() - 1 and _since_ms >= 1000.0:
		strip.play("idle", true, 0)
	strip.update_view(dt_ms)
	_bob += dt_ms
	_nudge = maxf(0.0, _nudge - dt_ms)
	_place_arrow()


## The arrow over her head while she takes the tap: bobs like the FTUE hand (still under reduced
## motion) and grows one art px a side for NUDGE_MS after a wrong tap.
func _place_arrow() -> void:
	_arrow.visible = tappable()
	if not _arrow.visible:
		return
	var bob := 0.0
	if not reduced_motion:
		var k := (1.0 - cos(TAU * float(Tune.MC["ftueHandBobHz"]) * _bob / 1000.0)) / 2.0
		bob = Ui.snap(float(Tune.MC["ftueHandBobPx"]) * k, 4)
	var sc := AP + (1.0 if _nudge > 0.0 else 0.0)
	var size := _arrow.texture.get_size() * sc
	_arrow.scale = Vector2(sc, sc)
	_arrow.position = Vector2(-size.x / 2.0, strip.rect().position.y - ARROW_GAP - size.y - bob)
