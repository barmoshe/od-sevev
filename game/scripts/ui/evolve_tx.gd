class_name EvolveTx
extends Node2D
## EVOLVE_TX: motion-spec evolve-ceremony (beats synced to the evolveConfirm fanfare) and its
## reduced-motion dark crossfade; hud-layout §11 EVOLVE_TX card. Phase boundaries come from the
## feel tunables; the inner beats are the Animator's audio onsets.
## od-sevev (ux/rtl-map.md §7.2 "EvolveTx: EVOTX_LINE + ELECT_TITLE", review R8): the card reads
## "הכנסת פוזרה. מתחילים:" over "סבב בחירות מס׳ {n}" (the new round), then EVO_MULT "×before ←
## ×after" (the string orders it for RTL; the fork's "×a → ×b" ran left to right), the base gained
## (EVO_THUMBS_GAIN) and the era line, all at the ×4 body scale (large text ×5), centred.
##
## Manual test 2026-09-30 (A4, A5; motion/state-graph-magician.md §9, revision 2): when a pick follows,
## the old leader walks out FIRST, on the old stage, before any card (`leadMs`: the walk plus an
## 80 ms empty beat); the card then dims in over the empty stage, the new round's state and stage are
## swapped under the fully opaque page (the seam), and the lines leave (3 steps of 40 ms) while the
## page is still opaque, so the page lifts empty: no ceremony line ever prints over the ticker, the
## Row A readout or the stage below a translucent page.

const FADE_STEPS := [[0.0, 0.25], [90.0, 0.5], [180.0, 0.75], [270.0, 1.0]]
const SEAM_MS := 270.0
const LAND_MS := 570.0
const MULT_MS := 720.0
const DROP_PX := 32.0
const TEXT_OUT := [[0.0, 0.67], [40.0, 0.33], [80.0, 0.0]]   # the lines' stepped exit, opaque page
const TEXT_OUT_MS := 120.0
const WALK_BEAT_MS := 80.0           # the empty old stage between the walk-out and the card
const SPECIES_Y := 628.0
const MULT_Y := 704.0
const GAIN_Y := 760.0
const ERA_Y := 816.0
const WRAP := 656.0                  # string-budgets tx.line
## Review U10 (style guide §17.3 `notice_frame`): the page is flag blue and the lines sit on the
## gate's printed notice, a white card ruled in flag blue (slice [3, 7, 3, 5], content box [4, 8,
## 32, 26] → insets 16 / 32 / 16 / 24 at ×4), centred around them; the title lines in flag
## (8.5:1), the body in night (13.9:1). A card, not full bleed (§2.4: never the whole page as the flag).
const NOTICE := Rect2(16, 508, 688, 388)   # holds the title through its 32-px drop
const C_PAGE := Color("#0038b8")     # flag
const C_TITLE := Color("#0038b8")    # flag on the notice's white
const C_BODY := Color("#0f2350")     # night

var running := false
var _card: ColorRect
var _line: PxText
var _species: PxText
var _mult: PxText
var _gain: PxText
var _era: PxText
var _notice: NinePatchRect            # null without the kit piece (the fork's cream card)
var _t := 0.0
var _lead := 0.0                      # ms before the card: the walk-out on the old stage (0: none)
var _reduced := false
var _cb: Dictionary = {}
var _fired := {}


func _ready() -> void:
	visible = false
	var X: Dictionary = Art.theme["evolveTx"]
	_card = Ui.rect(self, Rect2(-4000, -4000, 8720, 9280), X["card"], 1.0)
	if Art.has_sprite("notice_frame"):
		_notice = Ui.nine(self, NOTICE, "notice_frame")
		_notice.visible = false
	_line = _tx_text(SPECIES_Y - 48.0, Strings.s("EVOTX_LINE"), X["text"])
	_species = _tx_text(SPECIES_Y, "", X["text"])
	_mult = _tx_text(MULT_Y, "", X["text"])
	_gain = _tx_text(GAIN_Y, "", X["text"])
	_era = _tx_text(ERA_Y, "", X["text"])


func _tx_text(y: float, t: String, col: Variant) -> PxText:
	var p := PxText.make(self, Vector2(0, y), t, L.TEXT, "plain", col)
	p.wrap_width = WRAP
	p.max_lines = 1
	return p


## info: {round (the new round's number), multBefore, multAfter, gained, era, leadMs}; cb: {seam, walk,
## hello, unlock} Callables. A caller without `round` gets the old species title. `leadMs` (> 0 when a
## pick follows: `lead_ms`) holds the card back while the old leader walks off the OLD stage; `walk`
## fires on f0 then (the leader swap's walk-out, spec §9.3.4, motion/state-graph-magician.md §9 rev 2),
## and never without a lead. The seam (the new round's state and stage) always lands under the
## fully opaque page, after the walk.
func start(info: Dictionary, reduced: bool, cb: Dictionary) -> void:
	_reduced = reduced
	_cb = cb
	_t = 0.0
	_lead = maxf(0.0, float(info.get("leadMs", 0.0)))
	running = true
	_fired = {"seam": false, "walk": false, "hello": false, "unlock": false}
	visible = true
	modulate.a = 1.0
	var X: Dictionary = Art.theme["evolveTx"]
	_card.color = Art.col(X["reducedMotionCard" if reduced else "card"])
	for t: PxText in [_line, _species, _mult, _gain]:
		t.tint = Art.col(X["reducedMotionText" if reduced else "text"])
	if _notice != null:   # U10: the notice on the flag-blue page, in both modes
		_card.color = C_PAGE
		_line.tint = C_TITLE
		_species.tint = C_TITLE
		for t: PxText in [_mult, _gain]:
			t.tint = C_BODY
	_line.center_in(0, L.W)
	_species.text = Strings.s("ELECT_TITLE", {"n": int(info["round"])}) if info.has("round") else String(info.get("species", ""))
	_species.center_in(0, L.W)
	_mult.text = Strings.s("EVO_MULT", {"now": Fmt.mult(info["multBefore"]), "after": Fmt.mult(info["multAfter"])})
	_mult.px = L.TEXT
	_mult.center_in(0, L.W)
	_gain.text = Strings.s("EVO_THUMBS_GAIN", {"pending": Fmt.thumbs(info["gained"])})
	_gain.center_in(0, L.W)
	_era.text = Strings.s("F_ERA", {"era": info["era"]}) if String(info.get("era", "")) != "" else ""
	_era.center_in(0, L.W)
	_era.tint = _gain.tint
	_set_texts(false, false)
	_text_alpha(1.0)
	_card.modulate.a = 0.0
	if _lead > 0.0:
		_fire("walk")   # f0, the confirm frame: he sets off on the old stage; the card waits for him


func _set_texts(title: bool, mult: bool) -> void:
	if _notice != null:
		_notice.visible = title
	_line.visible = title
	_species.visible = title
	_mult.visible = mult
	_gain.visible = mult
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
	if _t < _lead:
		_card.modulate.a = 0.0
		_set_texts(false, false)
		return
	if _reduced:
		_update_reduced(_t - _lead)
	else:
		_update_full(_t - _lead)


func _text_alpha(a: float) -> void:
	for x: CanvasItem in [_line, _species, _mult, _gain, _era]:
		x.modulate.a = a
	if _notice != null:
		_notice.modulate.a = a


func _update_full(t: float) -> void:
	var fade_out_end := float(Tune.T["evolveFadeOutMs"])
	var card_end := fade_out_end + float(Tune.T["evolveTitleCardMs"])
	var lift := card_end + TEXT_OUT_MS   # the lines are gone; the page lifts empty
	var fade_in := float(Tune.T["evolveFadeInMs"])
	var total := lift + fade_in
	var a := 0.0
	for st: Array in FADE_STEPS:
		if t >= float(st[0]):
			a = float(st[1])
	if t >= lift:
		var k := mini(3, int(floorf((t - lift) / fade_in * 3.0)))
		a = [0.67, 0.33, 0.0, 0.0][k]
	_card.modulate.a = a
	if t >= SEAM_MS:
		_fire("seam")
	var title_on := t >= fade_out_end and t < lift
	var mult_on := t >= MULT_MS and t < lift
	_set_texts(title_on, mult_on)
	_text_alpha(text_out_alpha(t - card_end))
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
		_line.position.y = y - 48.0
	if mult_on:
		var p2 := minf(1.0, (t - MULT_MS) / 160.0)
		var sc := int(roundf((1.5 + (1.0 - 1.5) * Ui.quad_out(p2)) * float(L.TEXT)))
		_mult.px = sc
		_mult.center_in(0, L.W)
		_mult.position.y = MULT_Y - Ui.snap((9.0 * float(sc - L.TEXT)) / 2.0, 4)
	if t >= lift + fade_in / 3.0:
		_fire("hello")
	if t >= total:
		_finish()


## The lines' alpha `dt` ms after the title card's end: 1 before it, then TEXT_OUT's steps (the page
## stays opaque until they are gone).
static func text_out_alpha(dt: float) -> float:
	var a := 1.0
	for st: Array in TEXT_OUT:
		if dt >= float(st[0]):
			a = float(st[1])
	return a


func _update_reduced(t: float) -> void:
	var xfade := 200.0
	var card_end := xfade + float(Tune.T["evolveTitleCardMs"])
	var total := card_end + xfade
	var a := t / xfade if t < xfade else (1.0 if t < card_end else maxf(0.0, 1.0 - (t - card_end) / xfade))
	_card.modulate.a = a
	if t >= xfade:
		_fire("seam")
	# the lines cut as the cross-fade out starts: the page fades out empty
	_set_texts(t >= xfade and t < card_end, t >= MULT_MS and t < card_end)
	_text_alpha(1.0)
	_species.position.y = SPECIES_Y
	_line.position.y = SPECIES_Y - 48.0
	_mult.px = L.TEXT
	_mult.center_in(0, L.W)
	_mult.position.y = MULT_Y
	if t >= total:
		_finish()


func _finish() -> void:
	running = false
	visible = false
	if _lead > 0.0:
		_fire("walk")   # a caller that skipped ahead still gets it, before the unlock
	_fire("unlock")


## The lead a leader swap needs before the card (a pick follows): the walk-out on the old stage and an
## 80 ms empty beat. Reduced motion: the 150 ms fade on the mark and the beat.
static func lead_ms(reduced: bool) -> float:
	return LeaderWalk.length_ms(true, reduced) + WALK_BEAT_MS


## The seam in ms from the start with `lead` ms of walk-out first: the new round's state and stage,
## under the fully opaque page.
func seam_ms(reduced: bool, lead: float = 0.0) -> float:
	return lead + (200.0 if reduced else SEAM_MS)


## When the page starts to lift, in ms from the start (the lines are gone by then).
func lift_ms(reduced: bool, lead: float = 0.0) -> float:
	if reduced:
		return lead + 200.0 + float(Tune.T["evolveTitleCardMs"])
	return lead + float(Tune.T["evolveFadeOutMs"]) + float(Tune.T["evolveTitleCardMs"]) + TEXT_OUT_MS


## The whole transition in ms (with `lead` ms of walk-out first).
func total_ms(reduced: bool, lead: float = 0.0) -> float:
	if reduced:
		return lead + 400.0 + float(Tune.T["evolveTitleCardMs"])
	return lift_ms(false, lead) + float(Tune.T["evolveFadeInMs"])
