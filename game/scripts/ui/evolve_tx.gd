class_name EvolveTx
extends Node2D
## EVOLVE_TX: motion-spec evolve-ceremony (beats synced to the evolveConfirm fanfare) and its
## reduced-motion dark crossfade; hud-layout §11 EVOLVE_TX card. Phase boundaries come from the
## feel tunables; the inner beats are the Animator's audio onsets.

const FADE_STEPS := [[0.0, 0.25], [90.0, 0.5], [180.0, 0.75], [270.0, 1.0]]
const SEAM_MS := 270.0
const LAND_MS := 570.0
const MULT_MS := 720.0
const DROP_PX := 32.0
const SPECIES_Y := 628.0

var running := false
var _card: ColorRect
var _line: PxText
var _species: PxText
var _mult_old: PxText
var _mult_new: PxText
var _gain: PxText
var _gain_icon: Sprite2D
var _era: PxText
var _t := 0.0
var _reduced := false
var _cb: Dictionary = {}
var _fired := {}


func _ready() -> void:
	visible = false
	var X: Dictionary = Art.theme["evolveTx"]
	_card = Ui.rect(self, Rect2(-4000, -4000, 8720, 9280), X["card"], 1.0)
	_line = PxText.make(self, Vector2(0, 588), Strings.s("EVOTX_LINE"), 3, "plain", X["text"])
	_species = PxText.make(self, Vector2(0, SPECIES_Y), "", 4, "plain", X["text"])
	_mult_old = PxText.make(self, Vector2(0, 700), "", 4, "plain", X["text"])
	_mult_new = PxText.make(self, Vector2(0, 700), "", 4, "plain", X["text"])
	_gain_icon = Ui.img(self, Vector2(0, 756), "icon_thumb", 0, 4)
	_gain = PxText.make(self, Vector2(0, 766), "", 3, "plain", X["text"])
	_era = PxText.make(self, Vector2(0, 820), "", 3, "plain", X["text"])


## info: {species, multBefore, multAfter, gained}; cb: {seam, hello, unlock} Callables.
func start(info: Dictionary, reduced: bool, cb: Dictionary) -> void:
	_reduced = reduced
	_cb = cb
	_t = 0.0
	running = true
	_fired = {"seam": false, "hello": false, "unlock": false}
	visible = true
	modulate.a = 1.0
	var X: Dictionary = Art.theme["evolveTx"]
	_card.color = Art.col(X["reducedMotionCard" if reduced else "card"])
	for t: PxText in [_line, _species, _mult_old, _mult_new, _gain]:
		t.tint = Art.col(X["reducedMotionText" if reduced else "text"])
	_line.center_in(0, L.W)
	_species.text = String(info["species"]).to_upper()
	_species.center_in(0, L.W)
	_mult_old.text = "×%s → " % Fmt.mult(info["multBefore"])
	_mult_new.text = "×%s" % Fmt.mult(info["multAfter"])
	_mult_new.px = 4
	_gain.text = "+%s %s" % [Fmt.thumbs(info["gained"]), Strings.s("EVO_K1")]
	var w_old := _mult_old.width()
	var w_new := _mult_new.width()
	var x0 := 4.0 * floorf((L.W - (w_old + 24 + w_new)) / 2.0 / 4.0)
	_mult_old.position.x = x0
	_mult_new.position.x = x0 + w_old + 24
	var gw := 48.0 + 12.0 + _gain.width()
	var gx := 4.0 * floorf((L.W - gw) / 2.0 / 4.0)
	_gain_icon.position.x = gx
	_gain.position.x = gx + 60
	_era.text = Strings.s("F_ERA", {"era": info["era"]}) if String(info.get("era", "")) != "" else ""
	_era.center_in(0, L.W)
	_era.tint = _gain.tint
	_set_texts(false, false)
	_card.modulate.a = 0.0


func _set_texts(title: bool, mult: bool) -> void:
	_line.visible = title
	_species.visible = title
	_mult_old.visible = mult
	_mult_new.visible = mult
	_gain.visible = mult
	_gain_icon.visible = mult
	_era.visible = mult


func _fire(k: String) -> void:
	if not _fired[k]:
		_fired[k] = true
		var c: Callable = _cb.get(k, Callable())
		if c.is_valid():
			c.call()


func update_view(dt_ms: float) -> void:
	if not running:
		return
	_t += dt_ms
	if _reduced:
		_update_reduced(_t)
	else:
		_update_full(_t)


func _text_alpha(a: float) -> void:
	for x: CanvasItem in [_line, _species, _mult_old, _mult_new, _gain, _gain_icon, _era]:
		x.modulate.a = a


func _update_full(t: float) -> void:
	var fade_out_end := float(Tune.T["evolveFadeOutMs"])
	var card_end := fade_out_end + float(Tune.T["evolveTitleCardMs"])
	var fade_in := float(Tune.T["evolveFadeInMs"])
	var total := card_end + fade_in
	var a := 0.0
	for st: Array in FADE_STEPS:
		if t >= float(st[0]):
			a = float(st[1])
	if t >= card_end:
		var k := mini(3, int(floorf((t - card_end) / fade_in * 3.0)))
		a = [0.67, 0.33, 0.0, 0.0][k]
	_card.modulate.a = a
	if t >= SEAM_MS:
		_fire("seam")
	var title_on := t >= fade_out_end and t < total
	var mult_on := t >= MULT_MS and t < total
	_set_texts(title_on, mult_on)
	_text_alpha(a if t >= card_end else 1.0)
	if title_on:
		var dy := 0.0
		var dt := t - fade_out_end
		if dt < LAND_MS - fade_out_end:
			dy = -DROP_PX * (1.0 - Ui.quad_in(dt / (LAND_MS - fade_out_end)))
		elif t < LAND_MS + 120.0:
			var p := (t - LAND_MS) / 120.0
			dy = -4.0 * Ui.quad_out(p * 2.0) if p < 0.5 else -4.0 * (1.0 - Ui.quad_in((p - 0.5) * 2.0))
		var y := SPECIES_Y + Ui.snap(dy, 4)
		_species.position.y = y
		_line.position.y = y - 40.0
	if mult_on:
		var p2 := minf(1.0, (t - MULT_MS) / 160.0)
		var sc := int(roundf((1.5 + (1.0 - 1.5) * Ui.quad_out(p2)) * 4.0))
		_mult_new.px = sc
		_mult_new.position.y = 700.0 - (7.0 * sc - 28.0) / 2.0
	if t >= card_end + fade_in / 3.0:
		_fire("hello")
	if t >= total:
		_finish()


func _update_reduced(t: float) -> void:
	var xfade := 200.0
	var card_end := xfade + float(Tune.T["evolveTitleCardMs"])
	var total := card_end + xfade
	var a := t / xfade if t < xfade else (1.0 if t < card_end else maxf(0.0, 1.0 - (t - card_end) / xfade))
	_card.modulate.a = a
	if t >= xfade:
		_fire("seam")
	_set_texts(t >= xfade and t < total, t >= MULT_MS and t < total)
	_text_alpha(a if t >= card_end else 1.0)
	_species.position.y = SPECIES_Y
	_line.position.y = SPECIES_Y - 40.0
	_mult_new.px = 4
	_mult_new.position.y = 700.0
	if t >= total:
		_finish()


func _finish() -> void:
	running = false
	visible = false
	_fire("unlock")
