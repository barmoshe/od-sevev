class_name SaraMark
extends Node2D
## Sara on the Balfour stage (motion/state-graph-cast.md §3; pitch §6: a Balfour-era presence with no
## mechanic of her own). Bar, 2026-09-30: option B (creative-pack/art/sara-options/), right of the
## leader in front of the right crowd, facing him as drawn. Bibi's round only
## (leaderSelect.bibiOnly.systems "Sara's mark"), Balfour only, and never a tap target.
##
## Bar, 2026-10-01: not on stage the whole round. She comes for short VISITS: she walks in from the
## right, stays VISIT_MS and walks out. A visit starts on her joke, the bottle-deposit spin S01 (she
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
const VISIT_MS := 9000.0                  # on her mark, per visit
const CAMEO_FIRST_MS := 45000.0           # eligible play before the first cameo
const CAMEO_EVERY_MS := 90000.0           # then between cameos (counted while she is away)
const WALK_MS := 520.0
const OFF_X := 520.0                      # logical px right of the mark: off the stage's right edge

var strip: SpriteStrip
var reduced_motion := false
var state := ""                           # "" (away) | enter | stay | exit
var _t := 0.0
var _away_ms := 0.0
var _cameo_due := CAMEO_FIRST_MS
var _huff_on_arrival := false
var _pending_ms := -1.0
var _since_ms := 1.0e9


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
	visible = false
	position = mark()


func showing() -> bool:
	return visible


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
	_t = minf(_t, 1000.0)   # a huff mid-visit keeps her a while longer


func _visit() -> void:
	visible = true
	state = "enter"
	_t = 0.0
	strip.play("idle", true, randi() % maxi(1, strip.frame_count()))


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
				_t = 0.0
				if _huff_on_arrival:
					_huff_on_arrival = false
					_pending_ms = OFFEND_DELAY_MS
		"stay":
			position = m
			if _t >= VISIT_MS and _pending_ms < 0.0 and strip.anim != "offended":
				state = "exit"
				_t = 0.0
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
