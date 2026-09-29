class_name CourtEcho
extends Node2D
## The courthouse window on the stage (motion-spec suspicion-thermometer `courthouse_window`; 2D kit
## `court_window` 24×22 ×2 frames dark / lit + `court_window_glow`, the style's one checker halo): the
## diegetic echo of suspicion. A small courthouse in the stage's landmark band, on the 2D Artist's spot
## for the era (art px, the sprite's pivot): Balfour (150, 70), Knesset (156, 96), Washington (34, 96);
## the courthouse era has its own clock panel and shows none.
##
## Bibi only (Leaders.has_court): the press-day leaders get no courthouse.
##
## - It appears with the thermometer (the first shady source), fading in over 400 ms.
## - ≥ 75 %: the window lights: the lit frame fades in over the dark one, 400 ms Sine.InOut (out
##   the same below 75 %).
## - ≥ 95 %: the glow halo cuts in behind the window, steady.
## - While the court window is open (the summons and the court day itself): the halo stays on and
##   the lit window "breathes": its alpha eases 100 % → 60 % → 100 % over 1.6 s, Sine.InOut (0.63 Hz,
##   far under the 3 Hz photosensitivity ceiling, and never down to dark). A slow lamp, never a strobe.
## - Reduced motion: the fades take 200 ms (a state change, not motion) and the window holds lit.
## The sprites sit on whole art px (×4 logical) of the stage art's own grid.

const SPOTS := {"balfour": Vector2(150, 70), "knesset": Vector2(156, 96), "washington": Vector2(34, 96)}
const PIVOT := Vector2(12, 21)        # court_window's pivot (bottom centre of its 24×22 frame)
const TOP_CLEAR := 104.0             # the toast dock's band at the stage top (rtl-map §4)
const GLOW_AT := Vector2(2, 2)        # the halo's top-left in the frame: centred on the window (10-13, 9-15)
const HOT := 75.0
const BOIL := 95.0
const FADE_MS := 400.0
const FADE_RM_MS := 200.0
const BREATH_MS := 1600.0
const BREATH_LOW := 0.6

var reduced_motion := false
var _house: Sprite2D
var _lit: Sprite2D
var _glow: Sprite2D
var _house_a := 0.0
var _lit_a := 0.0
var _t := 0.0                          # ms since the court window opened (the breathing phase)
var _level := "off"
var _era := ""


## The echo's level: off (not shown) | dark | hot (≥ 75 %) | boil (≥ 95 %) | open (a summons or the
## court day: the window is open for business). Pure.
static func level(shown: bool, pct: float, phase: String) -> String:
	if not shown:
		return "off"
	if phase == "summons" or phase == "court":
		return "open"
	if pct >= BOIL:
		return "boil"
	if pct >= HOT:
		return "hot"
	return "dark"


## Whether the halo shows (steady from 95 % and while the window is open). Pure.
static func glow_on(lvl: String) -> bool:
	return lvl == "boil" or lvl == "open"


## The lit window's alpha multiplier `t_ms` into the open window: 1 → BREATH_LOW → 1 per BREATH_MS,
## Sine.InOut; 1 at every other level and under reduced motion. Pure.
static func breath(lvl: String, t_ms: float, reduced: bool) -> float:
	if lvl != "open" or reduced:
		return 1.0
	var ph := fmod(maxf(0.0, t_ms), BREATH_MS) / BREATH_MS
	return 1.0 - (1.0 - BREATH_LOW) * (0.5 - 0.5 * cos(TAU * ph))


## The era's spot in stage-art px, or (-1, -1) when the era shows no courthouse. Pure.
static func spot(era_id: String) -> Vector2:
	return SPOTS.get(era_id, Vector2(-1, -1))


func _ready() -> void:
	_glow = Ui.img(self, Vector2.ZERO, Art.sprite_or("court_window_glow"), 0, 4)
	_house = Ui.img(self, Vector2.ZERO, Art.sprite_or("court_window"), 0, 4)
	_lit = Ui.img(self, Vector2.ZERO, Art.sprite_or("court_window"), 1, 4)
	for n: Sprite2D in [_glow, _house, _lit]:
		n.visible = false
		n.modulate.a = 0.0
	visible = false


## Every frame. `on`: the round's leader goes to court and the game is in main mode.
func update_view(dt: float, s: GameState, era_id: String, on: bool) -> void:
	var shown := on and s != null and Investigation.active() and bool(s.investigation.get("revealed", false)) \
		and spot(era_id).x >= 0.0
	var lvl := level(shown, Investigation.suspicion(s) if s != null else 0.0, Investigation.phase(s) if s != null else "idle")
	if era_id != _era:
		_era = era_id
		_place()
	if lvl != _level:
		if lvl == "open" and _level != "open":
			_t = 0.0
		_level = lvl
	_t += dt
	var ms := FADE_RM_MS if reduced_motion else FADE_MS
	_house_a = move_toward(_house_a, 0.0 if lvl == "off" else 1.0, dt / ms)
	_lit_a = move_toward(_lit_a, 1.0 if lvl in ["hot", "boil", "open"] else 0.0, dt / ms)
	visible = _house_a > 0.0
	_house.visible = visible
	_house.modulate.a = sine_in_out(_house_a)
	_lit.visible = visible and _lit_a > 0.0
	_lit.modulate.a = sine_in_out(_lit_a) * _house.modulate.a * breath(lvl, _t, reduced_motion)
	_glow.visible = visible and glow_on(lvl)
	_glow.modulate.a = sine_in_out(_lit_a) * _house.modulate.a


static func sine_in_out(v: float) -> float:
	return 0.5 - 0.5 * cos(PI * clampf(v, 0.0, 1.0))


## Test hooks: {house, lit, glow} as drawn (alpha; glow visible).
func drawn() -> Dictionary:
	return {"house": _house.modulate.a if _house.visible else 0.0, "lit": _lit.modulate.a if _lit.visible else 0.0,
		"glow": _glow.visible, "level": _level}


## The stage's height or era changed: the stage art's origin is the Magician's feet less the art's
## magicianFeet slot (as the diorama draws the backdrop), so the house sits on the art's own grid.
func relayout() -> void:
	_place()


func _place() -> void:
	var sp := spot(_era)
	if sp.x < 0.0 or _house == null:
		return
	var mf: Array = SpriteStrip.manifest().get("magicianFeet", [94, 219])
	var origin := L.magician_feet() - Vector2(float(mf[0]), float(mf[1])) * 4.0
	var tl := origin + (sp - PIVOT) * 4.0
	# the flex rule crops the stage art's top rows on shorter stages (S 760 on a 390×844 phone puts
	# art row 70 above the stage): the house then drops, on the art grid, to just under the toast
	# dock (stage-local 8 + 88 + 8), so the echo is never drawn under the top bar
	tl.y = maxf(tl.y, origin.y + ceilf((float(L.STAGE["y"]) + TOP_CLEAR - origin.y) / 4.0) * 4.0)
	_house.position = tl
	_lit.position = tl
	_glow.position = tl + GLOW_AT * 4.0
