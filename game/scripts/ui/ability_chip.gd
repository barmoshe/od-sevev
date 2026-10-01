class_name AbilityChip
extends Node2D
## The round's active ability (leaders v3 phase 2, design/leaders-v3.md; sim: Ability). A chip at the
## stage's top right, the buff chip's look: the leader's verb ("אני פורש", "לחתום", "להעביר תקציב"…)
## with a number (cooldown seconds, the offer's countdown, Liberman's clauses 3/5) and a bar.
## Ready or an open offer: full colour and a slow pulse, and a tap uses it (main._use_ability).
## Cooldown: dimmed, the bar fills back. Hidden when the round's leader has no ability, or the ability
## has nothing to show (Smotrich between budgets, Golan between offers, Bibi's once-a-round used).
## Placeholder look until the GPT ability icons land (creative-pack/art/briefs/leaders-v3-gpt.md C).

## Stage px: the empty sky at the stage's top right (Bar's playtest 2026-10-01: at the bottom right it
## sat on the bought sources' figures), right of the leader's hit box (L.magician_hit ends at x 564, so
## rapid taps on the leader never land on it), in the top toast dock's row: while the chip is up the
## toasts dock in the lane band instead (main._dock_toasts). Tall enough for the ability's icon on top.
const RECT := Rect2(572, 168, 140, 132)   # ends at 300: an ultimatum cameo's timer chip starts below
const ICON_H := 48.0
const TEXT_SCALE := 3

var reduced_motion := false
var _bg: NinePatchRect
var _text: PxText
var _sub: PxText
var _track: ColorRect
var _fill: ColorRect
var _icon: Sprite2D
var _icon_id := "-"
var _view: Dictionary = {}
var _t := 0.0
var _shake := 0.0   # ms left of the "blocked" shake (nudge)


func _ready() -> void:
	var C: Dictionary = Art.theme["buffChip"]
	_bg = Ui.nine(self, RECT, C["sprite"], int(C["frame"]))
	_text = PxText.make(self, RECT.position + Vector2(10, 8 + ICON_H), "", TEXT_SCALE, "plain", C["text"])
	_text.fit_width = RECT.size.x - 20.0
	_sub = PxText.make(self, RECT.position + Vector2(10, 40 + ICON_H), "", TEXT_SCALE, "plain", C["text"])
	_sub.fit_width = RECT.size.x - 20.0
	var bar := Rect2(RECT.position.x + 10, RECT.end.y - 16, RECT.size.x - 20, 8)
	_track = Ui.rect(self, bar, C["barTrack"])
	_fill = Ui.rect(self, bar, C["barFillTop"])
	_icon = Sprite2D.new()
	_icon.centered = true
	_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_icon.position = RECT.position + Vector2(RECT.size.x / 2.0, 8.0 + ICON_H / 2.0)
	add_child(_icon)
	visible = false


## The ability's icon (`v.icon`, an Art sprite id such as prop_ability_bennett) drawn whole-px on top;
## none yet: the space stays empty.
func _set_icon(id: String) -> void:
	if id == _icon_id:
		return
	_icon_id = id
	_icon.texture = Art.tex(id) if id != "" and Art.has_sprite(id) else null
	if _icon.texture != null:
		var k := maxf(1.0, floorf(ICON_H / float(_icon.texture.get_height())))
		_icon.scale = Vector2(k, k)


## A blocked tap (Mordechai David's block): a short shake, at once.
func nudge() -> void:
	_shake = 300.0


## True when a tap at `p` (stage coordinates) should use the ability.
func takes_tap(p: Vector2) -> bool:
	var r := RECT.grow(6)
	r.position.x = maxf(r.position.x, L.magician_hit().end.x + 2.0)   # never the leader's tap box
	return visible and bool(_view.get("ready", false)) and r.has_point(p)


func hit_rect() -> Rect2:
	return RECT


## `v` = Ability.view(state, d); `stage_visible` = the stage is up (no modal over it).
func update_view(dt_ms: float, v: Dictionary, stage_visible: bool) -> void:
	_view = v
	visible = stage_visible and bool(v.get("show", false))
	if not visible:
		return
	_t += dt_ms
	_set_icon(str(v.get("icon", "")))
	var label := str(v.get("label", ""))
	var sub := str(v.get("sub", ""))
	var price := float(v.get("price", 0.0))
	if price > 0.0:
		sub = Fmt.amount(price) + "₪" + ((" · " + sub) if sub != "" else "")
	if _text.text != label:
		_text.text = label
		_text.center_in(RECT.position.x, RECT.size.x)
	if _sub.text != sub:
		_sub.text = sub
		_sub.center_in(RECT.position.x, RECT.size.x)
	var fill := clampf(float(v.get("fill", 0.0)), 0.0, 1.0)
	var state := str(v.get("state", "ready"))
	if state == "ready":
		fill = 1.0
	var w := Ui.snap(_track.size.x * fill, 4)
	_fill.size.x = w
	_fill.position.x = L.bar_x(Rect2(_track.position, _track.size), w)   # RTL: fills from the right
	var a := 1.0
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - dt_ms)
		position.x = 0.0 if reduced_motion or _shake <= 0.0 else roundf(sin(_shake / 300.0 * TAU * 3.0) * 6.0)
	if not bool(v.get("ready", false)) and state != "passive" and state != "active" and state != "blocked":
		a = 0.55   # cooling down
	elif not reduced_motion and (state == "ready" or state == "offer"):
		var hz := 1.6 if state == "offer" else 0.6
		a = 0.8 + 0.2 * (0.5 + 0.5 * sin(TAU * hz * _t / 1000.0))
	modulate.a = a
