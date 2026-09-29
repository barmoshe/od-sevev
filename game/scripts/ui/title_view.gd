class_name TitleView
extends Node2D
## The title state (ux/rtl-map.md §8, first-minute §2.2): the kit wordmark, the round + mood line
## and the day countdown, over the stage; Rows A/B, the ticker, the panel and the tabs are hidden,
## and the Magician is already at his gameplay position, so tap 1 lands on him. Zero instruction
## text: no CTA, no key hint, no footer (their keys are empty on purpose).
## Lines sit on a dark scrim plate (R7): the stage art behind them is busy.
## A child of the stage node, whose origin is the screen at stage-top − STAGE.y; `top_y` places
## the lines relative to the screen's safe top.

const SCRIM := Color(0.078, 0.047, 0.141, 0.82)   # #140C24 at 82%

var _items: Array[CanvasItem] = []
var _fade: Tween


func build(_reduced: bool, _show_keyhint: bool) -> void:
	# stage-local y of the screen's safe top: the stage node sits at (top_y + 180) - STAGE.y
	var top := float(L.STAGE["y"]) - float(L.ROW_A_H + L.ROW_B_H)
	var wm := Art.sprite_or("wordmark")
	if wm != Art.PLACEHOLDER:
		var sz := Vector2(Art.sprite_size(wm)) * 4.0
		_items.append(Ui.img(self, Vector2(floorf((L.W - sz.x) / 8.0) * 4.0, top + 24.0), wm, 0, 4))
	else:
		_line(top + 24.0, Strings.s("TITLE_WORDMARK_1"), 8, 1.0)
	_line(top + 176.0, Strings.s("TITLE_TAGLINE"), L.TEXT, 1.0)
	var cd := countdown_text()
	if cd != "":
		_line(top + 228.0, cd, L.TEXT, 0.6)


func _line(y: float, s: String, sc: int, alpha: float) -> void:
	if s == "":
		return
	var t := PxText.make(self, Vector2(0, y), s, sc, "plain", Color.WHITE)
	t.wrap_width = L.W - 48.0
	t.max_lines = 1
	t.center_in(0, L.W)
	var plate := Ui.rect(self, Rect2(t.position.x - 16.0, y - 8.0, t.width() + 32.0, float(HeFont.line_height() * sc) + 8.0), SCRIM)
	move_child(plate, t.get_index())
	t.modulate.a = alpha
	_items.append(plate)
	_items.append(t)


## "27.10 · עוד 29 ימים" (rtl-map §8: the one place the day count is always visible).
static func countdown_text() -> String:
	var date := String(Content.data().get("calendar", {}).get("electionDate", "2026-10-27"))
	var target := Time.get_unix_time_from_datetime_string(date + "T00:00:00")
	var today := Time.get_date_dict_from_system()
	var now := Time.get_unix_time_from_datetime_dict({"year": today["year"], "month": today["month"], "day": today["day"]})
	var days := int(roundf((target - now) / 86400.0))
	if days < 0:
		return ""
	var tail := Strings.s("HUD_COUNTDOWN_TODAY") if days == 0 else Strings.plural("HUD_COUNTDOWN", days, {"d": str(days)})
	return Strings.s("HUD_COUNTDOWN_DATE") + " · " + tail


func set_reduced_motion(_on: bool) -> void:
	pass


func show_title(v: bool) -> void:
	visible = v
	modulate.a = 1.0


func fade_out(ms: float) -> void:
	_fade = create_tween()
	_fade.tween_property(self, "modulate:a", 0.0, ms / 1000.0)
	_fade.tween_callback(func() -> void: visible = false)
