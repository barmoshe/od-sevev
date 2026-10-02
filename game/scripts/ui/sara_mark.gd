class_name SaraMark
extends Node2D
## Sara on the Balfour stage (motion/state-graph-cast.md §3; pitch §6: a Balfour-era presence with no
## mechanic of her own). Bar, 2026-09-30: option B (creative-pack/art/sara-options/), right of the
## leader in front of the right crowd, facing him as drawn. Bibi's round only
## (leaderSelect.bibiOnly.systems "Sara's mark"), Balfour only.
##
## Bar, 2026-10-02: she IS the tap target while she is on the stage (this overrides the cast spec's
## "not a tap target"). From the moment she walks in, a tap on the leader earns nothing: it is
## swallowed, she huffs and the toast says to tap her (main._on_sara_block). A tap on her (or Space)
## sends her off (main._tap_sara) and the leader takes taps again. She stays until she is tapped, so
## the cue must be unmissable: a gold arrow bobs over her head and pulses on every wrong tap.
##
## Bar, 2026-10-01: not on stage the whole round. She comes for short VISITS: she walks in from the
## right, stays until she is tapped (Bar, 2026-10-02; was VISIT_MS) and walks out. A visit starts on her joke, the bottle-deposit spin S01 (she
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
const ARROW_BOB_PX := 12.0
const ARROW_BOB_HZ := 1.6
const NUDGE_MS := 420.0                   # the arrow's pulse after a wrong tap
## The arrow over her head, 7 x 8 art px, tip on the last row. K outline, G gold, H highlight.
const ARROW := [
	"..KKK..",
	"..KGK..",
	"..KGK..",
	"KKKGKKK",
	"KHGGGGK",
	".KHGGK.",
	"..KGK..",
	"...K...",
]
const ARROW_COLORS := {"K": Color("#1d1a2b"), "G": Color("#f5c242"), "H": Color("#fff1b0")}

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
	r = r.expand(Vector2(r.get_center().x, r.position.y - ARROW_GAP - ARROW.size() * AP))
	return r.grow(HIT_PAD)


## A tap on her: she walks off at once (a pending huff is dropped) and the leader takes taps again.
func tap() -> void:
	if not tappable():
		return
	_pending_ms = -1.0
	_huff_on_arrival = false
	strip.play("idle", true, 0)
	if state == "enter":
		# mid-walk: turn round from where she is (the exit curve starts at the same offset)
		var m := mark()
		var k := clampf((position.x - m.x) / OFF_X, 0.0, 1.0)
		_t = sqrt(k) * WALK_MS
	else:
		_t = 0.0
	state = "exit"
	queue_redraw()


## A tap on the leader while she waits: she huffs (outside the huff cooldown) and the arrow pulses.
func nudge() -> void:
	_nudge = NUDGE_MS
	if strip.anim != "offended" and _pending_ms < 0.0 and _since_ms >= 1000.0:
		_since_ms = 0.0
		strip.play("offended", true, 1)
	queue_redraw()


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
				_t = 0.0
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
	queue_redraw()


## The arrow over her head while she takes the tap: bobs (still under reduced motion), and grows one
## art px a side for NUDGE_MS after a wrong tap.
func _draw() -> void:
	if not tappable():
		return
	var top := strip.rect().position.y
	var bob := 0.0
	if not reduced_motion:
		bob = Ui.snap(ARROW_BOB_PX * (1.0 - cos(TAU * ARROW_BOB_HZ * _bob / 1000.0)) / 2.0, 4)
	var px := AP * (1.25 if _nudge > 0.0 else 1.0)
	var w: int = (ARROW[0] as String).length()
	var h := ARROW.size()
	var origin := Vector2(-w * px / 2.0, top - ARROW_GAP - h * px - bob)
	for y in h:
		var row: String = ARROW[y]
		for x in row.length():
			var ch := row[x]
			if ARROW_COLORS.has(ch):
				draw_rect(Rect2(origin + Vector2(x, y) * px, Vector2(px, px)), ARROW_COLORS[ch])
