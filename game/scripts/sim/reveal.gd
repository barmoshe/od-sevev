class_name Reveal
extends RefCounted
## The reveal ladder (2026-10-03, design/overwhelm-report-2026-10-03.html; Bar: "one new system per
## round"). Content `reveal` maps a system to the election count (s.evolutions) it opens at:
## round 1 (evolutions 0) is the picker (two open leaders, ADR 0007), the tap, the sources, the chat's
## demands, 61 and the Suitcase; each election after it adds one system, taught by its wizard when it
## first shows up (ui/wizard.gd; the bubble is `reveal.copy`).
## One table, one helper: every gate in the sim and the views asks Reveal.on(s, key). A content
## without the table (the fork fixture, old saves' tests) has everything on, as before.

## Tests that pin a system itself (not the round it opens in) switch the ladder off.
static var force_all := false


static func table() -> Dictionary:
	var t: Variant = Content.data().get("reveal")
	return t if t is Dictionary else {}


## The election count `key` opens at (0 = from the first round; a missing key is always on).
static func round_of(key: String) -> int:
	return int(table().get(key, 0))


static func on(s: GameState, key: String) -> bool:
	if force_all or s == null:
		return true
	return s.evolutions >= round_of(key)


## A whole round has been played with `key` open (a dossier stays shown from then on).
static func past(s: GameState, key: String) -> bool:
	return s != null and s.evolutions >= (1 if force_all else round_of(key) + 1)


## The systems that open in this round (their threshold is today's election count), in table order.
static func new_this_round(s: GameState) -> PackedStringArray:
	var out := PackedStringArray()
	if s == null or s.evolutions <= 0:
		return out
	for k: Variant in table():
		if str(k) == "copy" or str(k).begins_with("_"):
			continue
		if int(table()[k]) == s.evolutions:
			out.append(str(k))
	return out


## The one-line announcement of a system opening (reveal.copy[key]), "" without one.
static func announcement(key: String) -> String:
	var c: Variant = table().get("copy")
	return str((c as Dictionary).get(key, "")) if c is Dictionary else ""
