class_name Ftue
extends Node2D
## od-sevev FTUE (ux/ftue.md, replacing the fork's P1-P7): one new thing at a time and zero
## instruction text in the first minute. Every prompt is a predicate over player state; the only
## clocks are idle and affordable-and-ignored clocks in PLAY time, and they all start at the
## hand-off (the HTML disclaimer fading out: window.mbHandoffDone).
##
## This node draws the prompts (the hat pulse, Dubi's bubbles, the pixel hand) and fires the
## one-off lines. What is revealed when (counter, card 1, rate line, tabs, spins, seats row,
## buy-mode row) is a pure function of state: see Ftue.reveals(), which the controller applies
## every frame, so a reload re-derives it and nothing re-teaches.
##
## Prompts built this wave (ux/ftue.md §3):
## - P0 tap the hat (title state): the Magician's idle loop + a 1 Hz brightness pulse; F2 after
##   9 s idle: the hand taps the hat from the lower right; F3 after 20 s: 2 Hz. (F1, Dubi pecking
##   the hat, waits for Dubi's art: STATUS request.)
## - H1 first tap: Dubi's bubble "אין כלום! אין כלום!" over the Magician for 1.6 s.
## - P1 first buy: affordable and ignored ≥ 5 s while tapping → Dubi "לקנות! לקנות!" on the card;
##   ≥ 13 s → the hand on the pill; after 2 more ignored 8-s windows the card bounces each time the
##   treasury crosses a multiple of the price.
## - K3 spins: the toast "נפתחו ספינים…" when the spins tab appears.
## - B1 buy mode: the ticker line F8_BULK when the buy-mode row appears.
## - E1 first election: the CTA replaces the ticker; ignored 60 s → Dubi "בחירות! בחירות!", again
##   every 120 s, at most 3 times.
## - R2 round 2: F7_RUN2 then F7_RUN2_GATE on the ticker after the first election.
## - S1 first Suitcase: the controller forces the first flight (Ftue.s1_due()).
## The fork's F1_TAP / F2_HIRE / F4_GOLDEN / F5 / F6 lines are never enqueued.

const DIRS := {
	"up": {"frame": 0, "angle": 0.0, "v": Vector2(0, -1)},
	"right": {"frame": 0, "angle": 90.0, "v": Vector2(1, 0)},
	"left": {"frame": 0, "angle": 270.0, "v": Vector2(-1, 0)},
	"down": {"frame": 0, "angle": 180.0, "v": Vector2(0, 1)},
	"upleft": {"frame": 1, "angle": 0.0, "v": Vector2(-0.7071, -0.7071)},
}

var reduced_motion := false
var ticker: Callable            # func(text: String)
var on_banana_emphasis: Callable
## func(hz: float): the hat pulse (BigBanana.set_pulse)
var on_pulse: Callable
var toasts: Toasts
var hand: Sprite2D
## The hand-off time (ms, JS performance clock); 0 = the disclaimer is still up.
var handoff_ms := 0.0

var _idle_ms := 0.0
var _t := 0.0
var _prev_taps := -1
var _p1_ms := 0.0               # affordable-and-ignored play time
var _p1_f1 := false
var _p1_windows := 0
var _p1_mult := 0
var _e1_ms := 0.0
var _e1_said := 0
var _prev_reveals := {}
var _r2_done := false


func _ready() -> void:
	hand = Sprite2D.new()
	hand.texture = Art.tex("ui_pointer", 0)
	hand.scale = Vector2(4, 4)
	hand.visible = false
	add_child(hand)


func pointer_visible() -> bool:
	return hand.visible


## Every pointer or key input resets the idle clock (ux/ftue.md §1).
func on_input() -> void:
	_idle_ms = 0.0


func on_registered_action() -> void:
	pass


# the fork's hooks, kept so the controller's call sites stay put
func on_stage_miss(_s: GameState) -> void:
	pass


func on_buy_producer() -> void:
	_p1_ms = 0.0


func on_buy_upgrade() -> void:
	pass


func on_tab_selected(_s: GameState, _tab: String) -> void:
	pass


func on_evolve_button(_s: GameState) -> void:
	_e1_ms = 0.0


func on_overlay_opened(_s: GameState, _id: String, _ready: bool) -> void:
	pass


func on_golden_caught(_s: GameState) -> void:
	pass


func on_golden_missed(_s: GameState) -> void:
	pass


## After the first election's transition and flash (R2).
func on_tx_done(s: GameState, _d: Economy.Derived) -> void:
	if s.evolutions == 1 and not _r2_done and ticker.is_valid():
		_r2_done = true
		ticker.call(Strings.s("F7_RUN2", {"pmult": Fmt.mult(Economy.derive(s).prestige_mult)}))
		ticker.call(Strings.s("F7_RUN2_GATE"))


static func badge_on(_s: GameState) -> bool:
	return false


static func owned_total(s: GameState) -> int:
	var n := 0
	for id in Content.producer_ids():
		n += s.owned_of(id)
	return n


static func _sources(s: GameState) -> int:
	var n := 0
	for id in Content.producer_ids():
		if s.owned_of(id) > 0:
			n += 1
	return n


## What the HUD shows (ux/ftue.md §1.1 flags, derived from state so they never regress within a
## run and an election keeps them: evolutions ≥ 1 reveals everything the first run taught).
static func reveals(s: GameState) -> Dictionary:
	var played := s.evolutions >= 1
	var owned := owned_total(s)
	var c: Dictionary = Content.data().get("coalition", {})
	var paid := int(float((s.coalition as Dictionary).get("paidLifetime", 0))) if s.coalition is Dictionary else 0
	var open_at := int(c.get("openAtSourcesOwned", 3))
	return {
		"counter": played or s.taps_lifetime >= 1,
		"card1": played or owned > 0 or s.taps_lifetime >= 3,
		"single": not played and owned == 0,                      # only card 1, named
		"rate": played or owned >= 1,
		"tabs": played or _sources(s) >= open_at or paid >= 1,    # C1
		"spins": s.all_time_bananas >= 300.0,                     # K3 (pitch §11 Q6)
		"seats": played or paid >= 1,                             # C2
		"buyMode": bool(s.ui.get("buyModeRevealed", false)),      # B1 (the fork's rule, in the controller)
		"suitcase": played or owned >= 2,                         # S1: no Suitcase before 2 sources
	}


## S1: the first Suitcase is due now (the controller forces the spawn when the band is clear).
static func s1_due(s: GameState, last_tap_age_ms: float) -> bool:
	return s.golden_caught_lifetime == 0 and int(float(s.stats.get("goldenMissed", 0.0))) == 0 \
		and owned_total(s) >= 2 and s.evolutions == 0 and last_tap_age_ms < 3000.0


## ctx: inMain, title, overlayOpen, hat (stage point), cardRow (int, -1 none), pill (Vector2 in
## this node's space or null), price (first card), gateOpen, ctaPoint (Dubi's bubble anchor).
func update_view(dt_ms: float, s: GameState, _d: Economy.Derived, ctx: Dictionary) -> void:
	_t += dt_ms
	hand.visible = false
	if handoff_ms <= 0.0:
		_set_pulse(0.0)
		return
	var blocked: bool = ctx.get("overlayOpen", false)
	if not blocked:
		_idle_ms += dt_ms
	# H1: the first tap (an edge)
	if _prev_taps == 0 and s.taps_lifetime >= 1 and toasts:
		toasts.say(Strings.s("DUBI_FIRSTTAP"), ctx.get("hat", Vector2(376, 300)), 1600.0)
	_prev_taps = s.taps_lifetime
	# reveal edges that carry a line (K3 toast, B1 ticker)
	var rv := reveals(s)
	if not _prev_reveals.is_empty():
		if rv["spins"] and not _prev_reveals.get("spins", false) and toasts:
			toasts.show_toast(Strings.s("TOAST_SPINS"))
		if rv["buyMode"] and not _prev_reveals.get("buyMode", false) and ticker.is_valid():
			ticker.call(Strings.s("F8_BULK"))
	_prev_reveals = rv
	# P0: tap the hat (title state)
	if ctx.get("title", false) and s.taps_lifetime == 0:
		_set_pulse(2.0 if _idle_ms >= 20000.0 else 1.0)
		if _idle_ms >= 9000.0:
			_point(ctx.get("hat", Vector2(376, 300)) + Vector2(56, 40), "upleft")
		return
	_set_pulse(0.0)
	if blocked or not ctx.get("inMain", false):
		return
	# P1: the first buy
	var first: String = Content.producer_ids()[0]
	var price := float(ctx.get("price", 0.0))
	if s.evolutions == 0 and s.owned_of(first) == 0 and price > 0.0 and s.bananas >= price:
		_p1_ms += dt_ms
		var pill: Variant = ctx.get("pill")
		if _p1_ms >= 5000.0 and not _p1_f1 and toasts and pill is Vector2:
			_p1_f1 = true
			toasts.say(Strings.s("DUBI_BUY"), (pill as Vector2) + Vector2(160, -48), 1600.0)
		if _p1_ms >= 13000.0 and pill is Vector2:
			_point((pill as Vector2) + Vector2(96, -8), "left")
			var windows := int((_p1_ms - 13000.0) / 8000.0)
			if windows >= 2:
				var mult := int(floorf(s.bananas / price))
				if mult > _p1_mult and ctx.has("bounce"):
					(ctx["bounce"] as Callable).call()
				_p1_mult = mult
	else:
		_p1_ms = 0.0
	# E1: the election CTA ignored
	if ctx.get("gateOpen", false) and s.evolutions == 0:
		_e1_ms += dt_ms
		var due := 60000.0 + 120000.0 * _e1_said
		if _e1_said < 3 and _e1_ms >= due and toasts:
			_e1_said += 1
			toasts.say(Strings.s("DUBI_ELECT"), ctx.get("ctaPoint", Vector2(360, 600)), 1600.0)
	else:
		_e1_ms = 0.0


func _set_pulse(hz: float) -> void:
	if on_pulse.is_valid():
		on_pulse.call(hz)


func _point(pos: Vector2, dir: String) -> void:
	var dd: Dictionary = DIRS[dir]
	var off := Vector2.ZERO
	if not reduced_motion:
		var k := (1.0 - cos(TAU * float(Tune.MC["ftueHandBobHz"]) * (_t / 1000.0))) / 2.0
		var v: Vector2 = dd["v"]
		off = Vector2(Ui.snap(v.x * float(Tune.MC["ftueHandBobPx"]) * k, 4), Ui.snap(v.y * float(Tune.MC["ftueHandBobPx"]) * k, 4))
	Ui.set_frame(hand, "ui_pointer", dd["frame"])
	hand.rotation_degrees = dd["angle"]
	hand.position = pos + off
	hand.visible = true
