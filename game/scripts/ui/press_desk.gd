class_name PressDesk
extends Node2D
## What stands on the leader's mark while he or she is off answering the press day (Bar, 2026-10-01:
## "not only Bibi"). Bibi's court day keeps the hat (CourtMotion); every other leader zips off the
## same way and this slides in on the feet instead: a press podium with two microphones, or Deri's
## corridor bench (kit.hazard.stage). Magician drives position and visibility from CourtMotion's hat
## track, so it zips in, wiggles on a paused tap (hatHush) and zips out exactly like the hat.
##
## The art (leaders v3 B1/B2/B4): the GPT refs rendered 1x as `prop_podium`, `prop_corridor-bench` and
## `prop_cardboard-box` (SPRITES), drawn at ART_PX logical px per art px, feet centred on the mark. When a
## sprite is missing (an older import) the drawn pixel map below stands in (AP logical px per map cell,
## 2 art px); the hook-up is the same either way.

const AP := 8.0   # logical px per map cell: 2 art px (×4), so the podium stands about waist high
const ART_PX := 4.0   # logical px per art px for the 1x prop sprites (the stage's artScale)
const SPRITES := {"podium": "prop_podium", "bench": "prop_corridor-bench", "box": "prop_cardboard-box"}

## K outline, W wood, D dark wood, L light edge, M mic head, S stalk, R the red on-air light, G grille
const PODIUM := [
	"....M......M....",
	"...MGM....MGM...",
	"....S......S....",
	".....S....S.....",
	"KKKKKKKKKKKKKKKK",
	"KLLLLLLLLLLLLLLK",
	".KWWWWWWWWWWWWK.",
	".KWWWWWWWWWWWWK.",
	".KWDDDDDDDDDDWK.",
	".KWDWWWRRWWWDWK.",
	".KWDWWWRRWWWDWK.",
	".KWDDDDDDDDDDWK.",
	".KWWWWWWWWWWWWK.",
	".KWWWWWWWWWWWWK.",
	".KWWWWWWWWWWWWK.",
	".KWWWWWWWWWWWWK.",
	".KWWWWWWWWWWWWK.",
	"KKKKKKKKKKKKKKKK",
	"KDDDDDDDDDDDDDDK",
	"KKKKKKKKKKKKKKKK",
]
const BENCH := [
	"KKKKKKKKKKKKKKKKKKKKKKKK",
	"KLLLLLLLLLLLLLLLLLLLLLLK",
	"KWWWWWWWWWWWWWWWWWWWWWWK",
	"KKKKKKKKKKKKKKKKKKKKKKKK",
	"KLLLLLLLLLLLLLLLLLLLLLLK",
	"KDDDDDDDDDDDDDDDDDDDDDDK",
	"KKKKKKKKKKKKKKKKKKKKKKKK",
	".KDK..............KDK...",
	".KDK..............KDK...",
	".KDK..............KDK...",
	".KKK..............KKK...",
]
## Ben Gvir's walkout (leaders v3): the cardboard office box he leaves on his mark, a plant and a mug in it
const BOX := [
	"....G...........",
	"...GGG......MM..",
	"....S......MWWM.",
	"....S......MWWM.",
	"KKKKKKKKKKKKKKKK",
	"KLLLLLLLLLLLLLLK",
	"KBBBBBBBBBBBBBBK",
	"KBBBBKKKKKBBBBBK",
	"KBBBBBBBBBBBBBBK",
	"KBBBBBBBBBBBBBBK",
	"KBBBBBBBBBBBBBBK",
	"KKKKKKKKKKKKKKKK",
]
const COLORS := {
	"K": Color("#1d1a2b"), "W": Color("#9a6a3f"), "D": Color("#6e4a2b"), "L": Color("#c99a62"),
	"M": Color("#2b2840"), "G": Color("#6b6880"), "S": Color("#3b3850"), "R": Color("#e0473c"),
	"B": Color("#c49a5c"),
}
const BOX_COLORS := {"G": Color("#3f9a3a"), "S": Color("#2f6b2b"), "M": Color("#f3efe6"), "W": Color("#6b4a2b")}

var kind := "podium"   # podium | bench | box


func set_kind(k: String) -> void:
	kind = k if k in ["bench", "box"] else "podium"
	queue_redraw()


func map() -> Array:
	return BENCH if kind == "bench" else (BOX if kind == "box" else PODIUM)


## The sprite id this kind draws when it is shipped, else "" (the drawn map stands in).
func sprite_id() -> String:
	var id: String = SPRITES.get(kind, "")
	return id if id != "" and Art.has_sprite(id) else ""


## The drawn size in logical px (tests, layout): the sprite's, or the map's.
func size_px() -> Vector2:
	var id := sprite_id()
	if id != "":
		return Vector2(Art.sprite_size(id)) * ART_PX
	var m := map()
	var w := 0
	for row: String in m:
		w = maxi(w, row.length())
	return Vector2(w, m.size()) * AP


func _draw() -> void:
	var sz := size_px()
	var id := sprite_id()
	if id != "":
		# feet centred on the mark, the left edge on a whole art px
		draw_texture_rect(Art.tex(id), Rect2(Vector2(-floorf(sz.x / ART_PX / 2.0) * ART_PX, -sz.y), sz), false)
		return
	var m := map()
	var origin := Vector2(-sz.x / 2.0, -sz.y)   # feet centred on the mark
	for y in m.size():
		var row: String = m[y]
		for x in row.length():
			var ch := row[x]
			var col: Variant = BOX_COLORS.get(ch) if kind == "box" and BOX_COLORS.has(ch) else COLORS.get(ch)
			if col != null:
				draw_rect(Rect2(origin + Vector2(x, y) * AP, Vector2(AP, AP)), col)
