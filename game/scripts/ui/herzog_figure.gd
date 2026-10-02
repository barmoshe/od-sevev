class_name HerzogFigure
extends StageFigure
## President Herzog's compromise outline (Bar, 2026-10-01; content events.herzog, effect "mediation",
## fact herzog-framework). While the effect is live he walks in from the right to the front-right
## mark (Sara's; she steps off while he stands there), hands clasped (idle). A tap on him accepts
## the outline (main._accept_mediation) and he walks back out. Ignored until the effect lapses, he
## shrugs (the react: palms out, a sweat drop) and leaves. Any round, any stage; reduced motion
## skips the walk (he appears and disappears in place).

const HIT := Vector2(152, 392)            # the tap box around him, logical px (feet at its bottom centre)


func _init() -> void:
	char_id = "herzog"
	hit_pad = 0.0


static func mark() -> Vector2:
	return SaraMark.mark()                # the right crowd's front row: Sara's mark


static func live(s: GameState) -> bool:
	return s != null and Events.is_active(s, "mediation")


func _ready() -> void:
	super()
	position = mark()


func _frame() -> Rect2:
	return Rect2(-HIT.x / 2.0, -HIT.y, HIT.x, HIT.y)


## The outline was accepted: he walks back out.
func accept() -> void:
	if tappable():
		_go("exit")


func _go(st: String) -> void:
	super(st)
	if st == "shrug":
		strip.play("react", true, 0)
	elif st == "enter" or st == "exit":
		strip.play("idle", false)


func update_view(dt_ms: float, s: GameState, on_stage: bool) -> void:
	if not on_stage:
		_hide()
		return
	var m := mark()
	if state == "" and live(s):
		visible = true
		strip.play("idle", true, randi() % maxi(1, strip.frame_count()))
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
				_go("shrug")   # nobody took the outline: it lapses
		"shrug":
			position = m
			if strip.frame >= strip.frame_count() - 1 and _t >= 900.0:
				_go("exit")
		"exit":
			_walk_out(m)
	strip.update_view(dt_ms)
