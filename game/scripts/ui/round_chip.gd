class_name RoundChip
extends Node2D
## The seeded round's chip (challenge: the ghost timer; daily: the round's number and clock), in the
## ticker's date-chip slot: the court chip's geometry (rtl-map §5.1: x 8, two tight lines, 80 tall,
## at least 212 wide), so it never meets the ability chip (stage sky), Row A / B or a toast. The date
## countdown means nothing inside a seeded round, so the slot is free; a court day's chip takes the
## slot over while it runs (the controller hides this one), and the election CTA covers the row.
##   challenge  line 1 CHALLENGE_CHIP "האתגר", line 2 the challenger's time left (counting down),
##              then "+0:12" in red_hi once the player is past it
##   daily      line 1 DAILY_CHIP "יומי #34", line 2 the round's own clock (counting up)
## A tap asks to leave the round (main.gd, ROUND_QUIT_*). `_lower`-local (the ticker's space).

const CHIP_H := 80.0
const CHIP_Y := 2.0
const MIN_W := 212.0
const C_TEXT := Color("#f7f4ec")
const C_OVER := Color("#ffaa9f")      # red_hi (SheetCard.C_ALERT)

var w := MIN_W
var _bg: NinePatchRect
var _title: PxText
var _timer: PxText
var _over := false


func _ready() -> void:
	_bg = Ui.nine(self, Rect2(8, CHIP_Y, MIN_W, CHIP_H), Art.sprite_or("chip_countdown"))
	_title = PxText.make(self, Vector2(0, CHIP_Y + 8.0), "", L.TEXT, "plain", "w")
	_title.max_lines = 1
	_timer = PxText.make(self, Vector2(0, CHIP_Y + 44.0), "", L.TEXT, "plain", "w")
	_timer.max_lines = 1
	visible = false


## The two lines for a round: `kind` "challenge" | "daily", `elapsed` the round's clock (s), `target`
## the challenger's time (s, challenge only), `n` the day's number (daily only).
static func lines(kind: String, elapsed: float, target: int, n: int) -> Dictionary:
	if kind == "daily":
		return {"title": Strings.s("DAILY_CHIP", {"n": n}), "timer": Strings.s("CHALLENGE_CHIP_TIME", {"mmss": SeededRound.mmss(elapsed)}), "over": false}
	var left := float(target) - elapsed
	if left >= 0.0:
		return {"title": Strings.s("CHALLENGE_CHIP"), "timer": Strings.s("CHALLENGE_CHIP_TIME", {"mmss": SeededRound.mmss(ceilf(left))}), "over": false}
	return {"title": Strings.s("CHALLENGE_CHIP"), "timer": Strings.s("CHALLENGE_CHIP_OVER", {"mmss": SeededRound.mmss(-left)}), "over": true}


func show_lines(v: Dictionary) -> void:
	var t := str(v.get("title", ""))
	var tm := str(v.get("timer", ""))
	if _title.text != t:
		_title.text = t
	if _timer.text != tm:
		_timer.text = tm
	var over: bool = v.get("over", false) == true
	if over != _over:
		_over = over
		_timer.tint = C_OVER if over else C_TEXT
	w = maxf(MIN_W, Ui.snap(16.0 + maxf(float(_title.width()), float(_timer.width())) + 16.0, 4))
	Ui.set_nine_rect(_bg, Rect2(8, CHIP_Y, w, CHIP_H))
	_title.center_in(8.0, w)
	_timer.center_in(8.0, w)


func hit_rect() -> Rect2:
	return Rect2(8, 0, w, 88)


func right() -> float:
	return 8.0 + w
