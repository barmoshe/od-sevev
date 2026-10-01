class_name PressDesk
extends Node2D
## What stands on the leader's mark while he or she is off answering the press day (Bar, 2026-10-01:
## "not only Bibi"). Bibi's court day keeps the hat (CourtMotion); every other leader zips off the
## same way and this slides in on the feet instead: a press podium with two microphones, or Deri's
## corridor bench (kit.hazard.stage). BigBanana drives position and visibility from CourtMotion's hat
## track, so it zips in, wiggles on a paused tap (hatHush) and zips out exactly like the hat.
##
## PLACEHOLDER ART (2026-10-01): drawn from a small pixel map on the art grid (AP logical px per map
## cell, 2 art px), feet centred on the mark. Swap for the GPT `podium` / `corridor-bench` sprites when they land
## (creative-pack/art/briefs/leaders-v3-gpt.md); the hook-up stays.

const AP := 8.0   # logical px per map cell: 2 art px (×4), so the podium stands about waist high

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
const COLORS := {
	"K": Color("#1d1a2b"), "W": Color("#9a6a3f"), "D": Color("#6e4a2b"), "L": Color("#c99a62"),
	"M": Color("#2b2840"), "G": Color("#6b6880"), "S": Color("#3b3850"), "R": Color("#e0473c"),
}

var kind := "podium"   # podium | bench


func set_kind(k: String) -> void:
	kind = "bench" if k == "bench" else "podium"
	queue_redraw()


func map() -> Array:
	return BENCH if kind == "bench" else PODIUM


## The drawn size in logical px (tests, layout).
func size_px() -> Vector2:
	var m := map()
	var w := 0
	for row: String in m:
		w = maxi(w, row.length())
	return Vector2(w, m.size()) * AP


func _draw() -> void:
	var m := map()
	var sz := size_px()
	var origin := Vector2(-sz.x / 2.0, -sz.y)   # feet centred on the mark
	for y in m.size():
		var row: String = m[y]
		for x in row.length():
			var ch := row[x]
			if COLORS.has(ch):
				draw_rect(Rect2(origin + Vector2(x, y) * AP, Vector2(AP, AP)), COLORS[ch])
