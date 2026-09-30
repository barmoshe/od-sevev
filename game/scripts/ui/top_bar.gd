class_name TopBar
extends Node2D
## Row A + Row B (ux/rtl-map.md §2, §3), `_top`-local. Reading order right → left:
## Row A: (cottage) · the counter (centred) with the rate line under it · mute · settings.
## Row B: "מנדטים" · the seats track (fills from the right, a notch every 10 seats) · "58/61";
## the whole row is one target (it opens the coalition tab once that exists).
## Progressive reveal (ux/ftue.md §3): the counter appears at tap 1 (H1), the rate line at the
## first purchase (R1), Row B at the first paid demand (C2). The fork's stat window, thumbs line
## and Evolve button are gone: the election CTA lives in the ticker row (rtl-map §5.3).
## Juice kept from the fork: J2 bank pop and big-gain pop, the rate line's hop and tint.

const BANK_GAIN := [Vector2(5, 5), Vector2(5, 5), Vector2(5, 5), Vector2(5, 3), Vector2(5, 3), Vector2(4, 5), Vector2(4, 5), Vector2(4, 4)]
const BANK_GAIN_REDUCED_TINT_MS := 300.0
## mobile-first §5.1 (D40): ×6, digits 30 logical = 15 CSS, 1.5× the body text; its cell top at y 0,
## the rate line at y 52 (Row A stays 96). ×6 is whole device px at every even k.
const COUNTER_SCALE := 6
const COUNTER_Y := 0.0
const RATE_Y := 52.0
const RATE_DIM_AFTER_MS := 3000.0

var reduced_motion := false
var evo_state := "hidden"          # kept for the controller's API; the Evolve button is gone
var bank: PxText
var bps: PxText
var gear: Sprite2D
var mute: Sprite2D
var seats_label: PxText
var seats_value: PxText

var _counter_on := false
var _rate_on := false
var _seats_on := false
var _muted := false
var _pop_t := -1.0
var _roll_remainder := 0.0
var _roll_tw: Tween
var _now := 0.0
var _gain_tint_until := 0.0
var _bps_tint_until := 0.0
var _rate_changed_at := -1e9
var _prev_rate := -1.0
var _frenzy := false
var _bps_hop: Array = []
var _track: NinePatchRect
var _fill: NinePatchRect
var _goal: NinePatchRect
var _ticks: Array[Sprite2D] = []
var _seat_frac := -1.0


func _ready() -> void:
	var th := Art.theme
	var T: Dictionary = L.TOP
	var cb: Rect2 = counter_box()
	bank = PxText.make(self, Vector2(cb.position.x, COUNTER_Y), "", COUNTER_SCALE, "plain", th["statText"]["bank"])
	var rb: Rect2 = rate_box()
	bps = PxText.make(self, Vector2(rb.position.x, RATE_Y), "", L.TEXT, "plain", th["statText"]["bps"])
	bps.fit_width = rb.size.x   # rtl-map §0.2: ×5 only when the filled rate fits rowA.rate (344)
	gear = _icon(T["gearHit"], "icon_gear")
	mute = _icon(T["muteHit"], "icon_sound_on")
	var hop := float(Tune.MC["bpsHopPx"])
	_bps_hop = [-hop / 2.0, -hop, -hop, -hop, -hop / 2.0, 0.0]
	# Row B
	var tr: Rect2 = T["seatsTrack"]
	_track = Ui.nine(self, tr, Art.sprite_or("seats_track"))
	_fill = Ui.nine(self, Rect2(tr.end.x - 12, tr.position.y + 4, 8, tr.size.y - 8), Art.sprite_or("seats_fill"))
	for i in range(1, 7):
		_ticks.append(Ui.img(self, Vector2.ZERO, Art.sprite_or("seats_tick"), 0, 4))
	_goal = Ui.nine(self, tr.grow(12), Art.sprite_or("seats_goal_frame"))
	_goal.visible = false
	seats_label = PxText.make(self, Vector2(0, float(T["seatsY"])), Strings.s("HUD_SEATS"), L.TEXT, "plain", "w")
	# rtl-map §0.2: Row B's label box is x 576-704 (128) and the numeral's x 16-136 (120); at ×5
	# "מנדטים" (155) would run over the track, so it steps down
	seats_label.fit_width = float(T["seatsLabelRight"]) - tr.end.x - 8.0
	seats_value = PxText.make(self, Vector2(float(T["seatsValueX"]), float(T["seatsY"])), "", L.TEXT, "plain", "w")
	seats_value.fit_width = tr.position.x - float(T["seatsValueX"]) - 8.0
	relayout()
	_apply_reveal()


## mobile-first §4.1 Row A / Row B anchors: the counter and rate boxes stretch (their text centred on
## the canvas), the gear and mute stay left (L), the cottage right (R, its own view); Row B's label
## is R, its numeral L, the track stretches (the notches follow it), the hit spans the canvas.
static func counter_box() -> Rect2:
	return L.sa(L.TOP["counterBox"])


static func rate_box() -> Rect2:
	return L.sa(L.TOP["rateBox"])


static func track_rect() -> Rect2:
	return L.sa(L.TOP["seatsTrack"])


static func seats_hit() -> Rect2:
	return Rect2(0, (L.TOP["seatsHit"] as Rect2).position.y, L.cw, (L.TOP["seatsHit"] as Rect2).size.y)


func relayout() -> void:
	if _track == null:
		return
	var tr := track_rect()
	Ui.set_nine_rect(_track, tr)
	for i in _ticks.size():
		_ticks[i].position = Vector2(Ui.snap(tr.end.x - 4.0 - (tr.size.x - 8.0) * float((i + 1) * 10) / 61.0, 4), tr.position.y + 4)
	Ui.set_nine_rect(_goal, tr.grow(12))
	seats_label.right_at(L.rx(float(L.TOP["seatsLabelRight"])))
	_seat_frac = -1.0
	if bank.text != "":
		bank.center_in(counter_box().position.x, counter_box().size.x)
	if bps.text != "":
		bps.center_in(rate_box().position.x, rate_box().size.x)


func _icon(hit: Rect2, id: String) -> Sprite2D:
	var key := Art.sprite_or(id)
	var sz := Vector2(Art.sprite_size(key)) * 4.0
	return Ui.img(self, hit.position + ((hit.size - sz) / 2.0 / 4.0).floor() * 4.0, key, 0, 4)


## ux/ftue.md §3: H1 shows the counter, R1 the rate line, C2 Row B. Never hidden again.
func set_revealed(counter: bool, rate: bool, seats: bool) -> void:
	if counter == _counter_on and rate == _rate_on and seats == _seats_on:
		return
	var fade_in: Array[CanvasItem] = []
	if counter and not _counter_on:
		fade_in.append(bank)
	if rate and not _rate_on:
		fade_in.append(bps)
	_counter_on = counter
	_rate_on = rate
	_seats_on = seats
	_apply_reveal()
	if not reduced_motion:
		for n in fade_in:
			n.modulate.a = 0.0
			create_tween().tween_property(n, "modulate:a", 1.0, 0.25)


func _apply_reveal() -> void:
	bank.visible = _counter_on
	bps.visible = _rate_on
	for n: CanvasItem in [_track, _fill, seats_label, seats_value]:
		n.visible = _seats_on
	for t in _ticks:
		t.visible = _seats_on
	_goal.visible = _goal.visible and _seats_on


# ------------------------------------------------------------------ counter / rate

func set_bank(bananas: float) -> void:
	bank.text = Strings.s("HUD_BANK", {"n": Fmt.bank(maxf(0.0, bananas - _roll_remainder))})
	bank.center_in(counter_box().position.x, counter_box().size.x)
	var th := Art.theme
	var tint: Variant = th["statText"]["bankGoldenRoll"] if (_roll_tw and _roll_tw.is_valid() and _roll_tw.is_running()) \
		else (th["juiceGain"] if _now < _gain_tint_until else th["statText"]["bank"])
	bank.tint = Art.col(tint)


## hud-bank-pop: 1.06 -> 1 over 80 ms. Never restarted while running.
func pop_bank() -> void:
	if reduced_motion or _pop_t >= 0.0 or Juice.has(bank):
		return
	_pop_t = 0.0


## J2 bank_big_gain (a Suitcase cash catch, the return card).
func big_gain(kind: String) -> void:
	if kind == "offline":
		_gain_tint_until = _now + (BANK_GAIN_REDUCED_TINT_MS if reduced_motion else float(Tune.MC["bankGainTintMs"]))
		bank.tint = Art.col(Art.theme["juiceGain"])
	if reduced_motion or Juice.has(bank):
		return
	_pop_t = -1.0
	var rest := func() -> void: bank.scale = Vector2.ONE
	Juice.play(bank, float(Tune.MC["bankGainPopMs"]), func(t: float) -> void:
		var s: Vector2 = Juice.sample(BANK_GAIN, t)
		bank.scale = s / 4.0, rest)


func roll_bank(award: float) -> void:
	if _roll_tw:
		_roll_tw.kill()
	_roll_remainder = award
	_roll_tw = create_tween()
	_roll_tw.tween_property(self, "_roll_remainder", 0.0, float(Tune.MC["luckyBunchRollMs"]) / 1000.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


## `pour`: S07 (idleToTap) is live, so passive income is 0 and every tap pours it instead. The
## line then reads HUD_BPS_POUR in the frenzy tint rather than "+0.0 ₪ לשנייה" (review R24).
func set_bps(rate_bps: float, frenzy_mult: float, pour: bool = false) -> void:
	var th := Art.theme
	var rb0: Rect2 = rate_box()
	if pour:
		_frenzy = true
		_prev_rate = -1.0
		bps.text = Strings.s("HUD_BPS_POUR")
		bps.center_in(rb0.position.x, rb0.size.x)
		bps.tint = Art.col(th["statText"]["bpsFrenzy"])
		bps.self_modulate.a = 1.0
		return
	var rate := rate_bps * frenzy_mult
	var rb: Rect2 = rate_box()
	if _prev_rate >= 0.0 and absf(rate - _prev_rate) > 1e-9:
		_rate_changed_at = _now
		if rate > _prev_rate:
			_bps_tint_until = _now + float(Tune.MC["bpsTintHoldMs"])
			if not reduced_motion and not Juice.has(bps):
				var y0 := RATE_Y
				Juice.play(bps, _bps_hop.size() * Tune.FRAME_MS, func(t: float) -> void: bps.position.y = y0 + float(Juice.sample(_bps_hop, t)),
					func() -> void: bps.position.y = y0)
	_prev_rate = rate
	_frenzy = frenzy_mult > 1.0
	if _frenzy:
		var m := str(int(frenzy_mult)) if is_equal_approx(frenzy_mult, roundf(frenzy_mult)) else str(frenzy_mult)
		bps.text = Strings.s("HUD_BPS_FRENZY", {"rate": Fmt.rate(rate), "mult": m})
	else:
		bps.text = Strings.s("HUD_BPS", {"rate": Fmt.rate(rate_bps)})
	bps.center_in(rb.position.x, rb.size.x)
	var tint: Variant = th["statText"]["bpsFrenzy"] if _frenzy else (th["juiceGain"] if _now < _bps_tint_until else th["statText"]["bps"])
	bps.tint = Art.col(tint)
	# 100% for 3 s after a change, then 60% (first-minute §3.2 #1b)
	bps.self_modulate.a = 1.0 if (_frenzy or _now - _rate_changed_at < RATE_DIM_AFTER_MS) else 0.6


func reset_rate() -> void:
	_prev_rate = -1.0


# ------------------------------------------------------------------ Row B seats

## effective / gate seats; the blackout removes the numeral (rtl-map §3; its stamp is a later piece).
func set_seats(effective: int, gate: int, blackout: bool) -> void:
	var tr: Rect2 = track_rect()
	var frac := clampf(float(effective) / maxf(1.0, float(gate)), 0.0, 1.0)
	if not is_equal_approx(frac, _seat_frac) or _seat_frac < 0.0:
		_seat_frac = frac
		var inner := Rect2(tr.position + Vector2(4, 4), tr.size - Vector2(8, 8))
		var w := maxf(8.0, Ui.snap(inner.size.x * frac, 4))
		Ui.set_nine_rect(_fill, Rect2(L.bar_x(inner, w), inner.position.y, w, inner.size.y))
	seats_value.visible = _seats_on and not blackout
	seats_value.text = Strings.s("HUD_SEATS_VALUE", {"seats": str(effective)})
	_goal.visible = _seats_on and effective >= gate


func seats_contains(p: Vector2) -> bool:
	return _seats_on and Ui.in_rect(seats_hit(), p)


# ------------------------------------------------------------------ controls

func gear_contains(p: Vector2) -> bool:
	return gear.visible and Ui.in_rect(L.TOP["gearHit"], p)


func mute_contains(p: Vector2) -> bool:
	return mute.visible and Ui.in_rect(L.TOP["muteHit"], p)


func set_muted(on: bool) -> void:
	if on == _muted:
		return
	_muted = on
	mute.texture = Art.tex(Art.sprite_or("icon_sound_off" if on else "icon_sound_on"), 0)


# ------------------------------------------------------------------ the fork's API, now no-ops

func set_thumbs(_owned: int, _mult: float) -> void:
	pass


func set_evolve(_vis: bool, _pending: int, _needed: int, _enabled: bool, _reveal: bool, _ready: bool) -> void:
	pass


func set_evolve_badge(_on: bool) -> void:
	pass


func evolve_contains(_p: Vector2) -> bool:
	return false


func evolve_down() -> void:
	pass


func evolve_up() -> void:
	pass


func evolve_hover(_on: bool) -> void:
	pass


func set_pulse_paused(_paused: bool) -> void:
	pass


func set_reduced_motion(on: bool) -> void:
	reduced_motion = on


func update_view(dt_ms: float) -> void:
	_now += dt_ms
	if _pop_t >= 0.0:
		_pop_t += dt_ms
		var dur := float(Tune.T["bankPopMs"])
		var p := minf(1.0, _pop_t / dur)
		var s := lerpf(float(Tune.T["bankPopScale"]), 1.0, Ui.quad_out(p))
		bank.scale = Vector2(s, s)
		if p >= 1.0:
			_pop_t = -1.0
			bank.scale = Vector2.ONE
	if _rate_on and not _frenzy and _now - _rate_changed_at >= RATE_DIM_AFTER_MS:
		bps.self_modulate.a = 0.6
