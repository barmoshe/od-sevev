class_name KaiaFigure
extends Node2D
## Kaia on the Balfour stage (content events.kaia, effect "kaia"; fact kaia). While her effect is
## live she trots in from the left to a front-left mark, wagging; a tap feeds her a cucumber
## (main._feed_kaia → Events.act("kaia", "feed"): the kaiaBuff tap multiplier) and she trots off.
## Ignored until the effect lapses, she nips a minister (Events._tick_active → kaiaNip) and leaves.
##
## The art (leaders v3 D): the `kaia` character in sprites.json (the GPT refs kaia / kaia-happy,
## 24 art px tall): `idle` wags her tail, `happy` holds the cucumber. Her hit box is the strip's rect
## grown by HIT_PAD. Without that character (an older import) the small pixel map below stands in
## (AP logical px per art px, the HIT box); the mark and the states are the same either way.

const CHAR := "kaia"
const MARK_ART := Vector2(58, 221)        # front-left, between the left crowd and the leader
const AP := 4.0
const WALK_MS := 420.0
const OFF_X := -420.0
const HIT := Vector2(112, 96)
const HIT_PAD := 8.0                      # logical px around the strip's frame

## 16 x 9 art px, facing left, feet on the last row. K outline, W coat, B brown patch, N nose, E eye.
const MAP := [
	"..KK............",
	".KBBK...........",
	"KBEBWK........K.",
	"NWWWWWKKKKKKKKWK",
	"KKWWWWWWWWBBBWK.",
	".KWWWWWWWBBBBWK.",
	".KWWWWWWWWWWWWK.",
	".KWK.KWK..KWK.KWK",
	".KK..KK...KK..KK.",
]
## the tail's tip, wagged: (col, row) for each of the two frames
const TAIL := [Vector2i(14, 2), Vector2i(15, 1)]
const COLORS := {"K": Color("#1d1a2b"), "W": Color("#f3efe6"), "B": Color("#a8703f"), "N": Color("#1d1a2b"), "E": Color("#1d1a2b")}
const CUKE := Color("#3f9a3a")
const CUKE_HI := Color("#8fd37a")

var strip: SpriteStrip                    # null: the drawn map stands in
var reduced_motion := false
var state := ""                           # "" | enter | wait | fed | exit
var _t := 0.0
var _wag := 0.0


static func mark() -> Vector2:
	var mf: Array = SpriteStrip.manifest().get("magicianFeet", [94, 219])
	return L.magician_feet() + (MARK_ART - Vector2(float(mf[0]), float(mf[1]))) * AP


static func live(s: GameState) -> bool:
	return s != null and Events.is_active(s, "kaia")


func _ready() -> void:
	if SpriteStrip.has_char(CHAR):
		strip = SpriteStrip.make(self, CHAR, Vector2.ZERO)
	visible = false
	position = mark()


func tappable() -> bool:
	return visible and (state == "enter" or state == "wait")


## Her tap box in stage-local px (empty when she takes no tap).
func hit_rect() -> Rect2:
	if not tappable():
		return Rect2()
	if strip != null:
		var r := strip.rect()
		return Rect2(position + r.position, r.size).grow(HIT_PAD)
	return Rect2(position.x - HIT.x / 2.0, position.y - HIT.y, HIT.x, HIT.y)


## Fed: the cucumber shows, then she trots off.
func feed() -> void:
	if tappable():
		_go("fed")


func _go(st: String) -> void:
	state = st
	_t = 0.0
	if strip != null:
		strip.play("happy" if st == "fed" and strip.has_anim("happy") else "idle", st == "fed")
	queue_redraw()


func update_view(dt_ms: float, s: GameState, on_stage: bool) -> void:
	if not on_stage:
		visible = false
		state = ""
		return
	var m := mark()
	if state == "" and live(s):
		visible = true
		_go("enter")
	if state == "":
		visible = false
		return
	_t += dt_ms
	_wag += dt_ms
	match state:
		"enter":
			var k := 1.0 if reduced_motion else clampf(_t / WALK_MS, 0.0, 1.0)
			position = Vector2(m.x + OFF_X * pow(1.0 - k, 2.0), m.y)
			if k >= 1.0:
				_go("wait")
		"wait":
			position = m
			if not live(s):
				_go("exit")   # ignored: the sim nips a minister (kaiaNip); she trots off
		"fed":
			position = m
			if _t >= 900.0:
				_go("exit")
		"exit":
			var k2 := 1.0 if reduced_motion else clampf(_t / WALK_MS, 0.0, 1.0)
			position = Vector2(m.x + OFF_X * k2 * k2, m.y)
			if k2 >= 1.0:
				state = ""
				visible = false
	if strip != null:
		strip.paused = reduced_motion   # reduced motion: no wag (the drawn map holds frame 0 too)
		strip.update_view(dt_ms)
	queue_redraw()


func _draw() -> void:
	if not visible or strip != null:
		return
	var h := MAP.size()
	var w := 0
	for row: String in MAP:
		w = maxi(w, row.length())
	var origin := Vector2(-w * AP / 2.0, -h * AP)   # feet centred on the mark
	var frame := 0 if reduced_motion else int(_wag / 220.0) % 2
	for y in h:
		var row: String = MAP[y]
		for x in row.length():
			var ch := row[x]
			if not COLORS.has(ch):
				continue
			draw_rect(Rect2(origin + Vector2(x, y) * AP, Vector2(AP, AP)), COLORS[ch])
	# the wagging tail tip
	var tip: Vector2i = TAIL[frame]
	draw_rect(Rect2(origin + Vector2(tip) * AP, Vector2(AP, AP)), COLORS["K"])
	if state == "fed":
		# the cucumber, held in front of her nose (4 x 2 art px, a highlight row)
		var c0 := origin + Vector2(-5, 3) * AP
		draw_rect(Rect2(c0, Vector2(4 * AP, AP)), CUKE_HI)
		draw_rect(Rect2(c0 + Vector2(0, AP), Vector2(4 * AP, AP)), CUKE)
