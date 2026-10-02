class_name KaiaFigure
extends StageFigure
## Kaia on the Balfour stage (content events.kaia, effect "kaia"; fact kaia). While her effect is
## live she trots in from the left to a front-left mark, wagging; a tap feeds her a cucumber
## (main._feed_kaia → Events.act("kaia", "feed"): the kaiaBuff tap multiplier) and she trots off.
## Ignored until the effect lapses, she nips a minister (Events._tick_active → kaiaNip) and leaves.
## The art (leaders v3 D): the `kaia` character in sprites.json, 24 art px tall: `idle` wags her
## tail, `happy` holds the cucumber. Reduced motion: no walk, no wag.

const MARK_ART := Vector2(58, 221)        # front-left, between the left crowd and the leader


func _init() -> void:
	char_id = "kaia"
	off_x = -420.0
	walk_ms = 420.0


static func mark() -> Vector2:
	return StageFigure.stage_at(MARK_ART)


static func live(s: GameState) -> bool:
	return s != null and Events.is_active(s, "kaia")


func _ready() -> void:
	super()
	position = mark()


## Fed: the cucumber shows, then she trots off.
func feed() -> void:
	if tappable():
		_go("fed")


func _go(st: String) -> void:
	super(st)
	strip.play("happy" if st == "fed" else "idle", st == "fed")


func update_view(dt_ms: float, s: GameState, on_stage: bool) -> void:
	if not on_stage:
		_hide()
		return
	var m := mark()
	if state == "" and live(s):
		visible = true
		_go("enter")
	if state == "":
		return
	_t += dt_ms
	match state:
		"enter":
			if _walk_in(m):
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
			_walk_out(m)
	strip.paused = reduced_motion
	strip.update_view(dt_ms)
