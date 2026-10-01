class_name SaraMark
extends Node2D
## Sara on the Balfour stage (motion/state-graph-cast.md §3; pitch §6: a Balfour-era presence with no
## mechanic of her own). Bar, 2026-09-30: option B (creative-pack/art/sara-options/), right of the
## leader in front of the right crowd, facing him as drawn. Bibi's round only
## (leaderSelect.bibiOnly.systems "Sara's mark"), Balfour only, and never a tap target.
##
## She huffs (`offended`) 150 ms after the bottle-deposit spin S01 is bought: it is her only reference
## in the game and its copy never names her, so the huff is the joke. An 8 s cooldown drops triggers
## inside it. The old seat `blockade` planted Mordechai David on her mark, so she steps off while one
## holds; his screen block (since 2026-10-01) comes from the left and leaves her be. Reduced motion
## keeps her: every motion is in place.

const CHAR := "sara"
const MARK_ART := Vector2(150, 221)       # the right crowd's front row, feet as drawn (StreetFigure's mark)
const AP := 4.0
const OFFEND_DELAY_MS := 150.0
const OFFEND_COOLDOWN_MS := 8000.0
const TRIGGER_UPGRADE := "s01"

var strip: SpriteStrip
var _pending_ms := -1.0
var _since_ms := 1.0e9


## Her feet, stage-local: the stage art is placed so its magicianFeet slot lands on the leader's feet.
static func mark() -> Vector2:
	var mf: Array = SpriteStrip.manifest().get("magicianFeet", [94, 219])
	return L.magician_feet() + (MARK_ART - Vector2(float(mf[0]), float(mf[1]))) * AP


## On stage only in Bibi's round, in Balfour, and not while the blockade holds her mark.
static func wanted(s: GameState, on_stage: bool) -> bool:
	return on_stage and s != null and Leaders.is_default(Leaders.current(s)) and not Events.is_active(s, "blockade")


func _ready() -> void:
	strip = SpriteStrip.make(self, CHAR, Vector2.ZERO)
	visible = false
	position = mark()


func showing() -> bool:
	return visible


## The S01 purchase (main.gd): the huff after the reaction delay, unless the cooldown is running.
func offend() -> void:
	if not visible or _pending_ms >= 0.0 or _since_ms < OFFEND_COOLDOWN_MS or strip.anim == "offended":
		return
	_pending_ms = OFFEND_DELAY_MS


func update_view(dt_ms: float, s: GameState, on_stage: bool) -> void:
	if strip == null:
		return
	if not wanted(s, on_stage):
		visible = false
		_pending_ms = -1.0
		return
	if not visible:
		visible = true
		position = mark()
		strip.play("idle", true, randi() % maxi(1, strip.frame_count()))
	_since_ms += dt_ms
	if _pending_ms >= 0.0:
		_pending_ms -= dt_ms
		if _pending_ms < 0.0:
			_pending_ms = -1.0
			_since_ms = 0.0
			strip.play("offended", true, 1)
	if strip.anim == "offended" and strip.frame >= strip.frame_count() - 1 and _since_ms >= 1000.0:
		strip.play("idle", true, 0)
	strip.update_view(dt_ms)
