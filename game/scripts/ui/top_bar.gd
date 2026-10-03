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
##
## The identity chip (od-sevev A7/B10, ux/mobile-first-layout.md §5.1.1): Row A's right end shows
## the round's leader, a 64-logical face medallion (the pick avatar at whole device px) with the
## short name to its left, from the pick on (the pre-tap state included). It replaces the
## round-start name toast that covered the stage. The name shares its slot with the Cottage Index:
## the name shows while the cup is not revealed, and at every round start until the round's first
## tap or buy; then it yields (a 150 ms fade) and the cup takes the slot. The name also yields if the
## counter or the rate line would reach it (a width guard; only the 360-wide phones can hit it).

const BANK_GAIN := [Vector2(5, 5), Vector2(5, 5), Vector2(5, 5), Vector2(5, 3), Vector2(5, 3), Vector2(4, 5), Vector2(4, 5), Vector2(4, 4)]
const BANK_GAIN_REDUCED_TINT_MS := 300.0
## mobile-first §5.1 (D40): ×6, digits 30 logical = 15 CSS, 1.5× the body text; its cell top at y 0,
## the rate line at y 52 (Row A stays 96). ×6 is whole device px at every even k.
const COUNTER_SCALE := 6
const COUNTER_Y := 0.0
const RATE_Y := 52.0
const RATE_DIM_AFTER_MS := 3000.0
## The settled rate line's alpha (first-minute §3.2 #1b). v4 puts Row A on flag blue #0038b8: the
## rate green #8fe052 at 0.6 blends to #569d7b, 2.9:1 (fails AA); at 0.9 it is #81cf5c, 4.9:1
## (UX review 2026-09-30, U4).
const RATE_DIM_ALPHA := 0.9
## The live rate (Bar 2026-10-02: "the money per second on screen should follow the tap speed"):
## the line shows the passive rate PLUS what taps actually paid lately (Economy.tap's value, crits
## and frenzies included, manual and auto taps; note_tap()). The taps' rate is their sum over the
## last TAP_WINDOW_MS, divided by the window (or by the burst's age, at least TAP_MIN_SPAN_MS, while
## a burst is younger than the window, so it rises within a second), then smoothed (exponential,
## TAP_SMOOTH_MS). After the last tap it slides to 0 as the taps leave the window and is exactly 0
## by TAP_ZERO_MS. Display only: nothing in the sim reads it (prices, away pay and the bench still
## read Economy.Derived.bps). The text changes at most every RATE_TEXT_MS (5 a second) and only by
## more than RATE_DEADBAND of itself, so the digits don't shimmer; while taps carry at least
## TAP_CUE_SHARE of it, the line takes the tap tint (pale gold) at full alpha.
const TAP_WINDOW_MS := 2000.0
const TAP_MIN_SPAN_MS := 1000.0
const TAP_SMOOTH_MS := 300.0
const TAP_ZERO_MS := 3000.0
const RATE_TEXT_MS := 200.0
const RATE_DEADBAND := 0.02
const TAP_CUE_SHARE := 0.15
const C_RATE_TAP := Color("#fff3a0")   # h: pale gold on flag blue (12.6:1)

var reduced_motion := false
var evo_state := "hidden"          # kept for the controller's API; the Evolve button is gone
var bank: PxText
var bps: PxText
var gear: Sprite2D
var mute: Sprite2D
var seats_label: PxText
var seats_value: PxText
var face: Sprite2D                 # the identity chip's medallion (null until a leader is set)
var leader_name: PxText

var _leader := "~"                 # the leader shown ("" = none: content without leader select)
var _face_k := -1                  # the device scale the face sprite was chosen for
var _id_on := false
var _name_want := false
var _name_tw: Tween

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
# the live rate (TAP_*): the window's taps [t_ms, value], their sum, the burst's start, the last tap
var _taps: Array = []
var _tap_sum := 0.0
var _burst_at := -1e9
var _last_tap_at := -1e9
var _tap_rate := 0.0               # smoothed ₪/s from taps
var _tap_shown := 0.0              # the tap part the text shows (throttled, dead-banded)
var _rate_text_at := -1e9
var _passive := 0.0                # rate_bps × frenzy_mult from the last set_bps
var _base_bps := 0.0
var _frenzy_mult := 1.0
var _pour := false
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
	leader_name = PxText.make(self, Vector2(0, float(T["nameY"])), "", L.TEXT, "plain", "w")
	leader_name.max_lines = 1
	leader_name.visible = false
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
	if _leader != "~" and _leader != "" and _face_k != Display.k:
		var again := _leader
		_leader = "~"
		set_leader(again)   # a new device scale: the medallion's densest crisp head
	_place_identity()


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


# ------------------------------------------------------------------ the identity chip (A7/B10)

## The face medallion's rect and hit, `_top`-local (R-anchored).
static func face_rect() -> Rect2:
	return L.ra(L.TOP["face"])


static func face_hit() -> Rect2:
	return L.ra(L.TOP["faceHit"])


## The name's right edge (R): 16 left of the face hit's inner edge.
static func name_right() -> float:
	return L.rx(float(L.TOP["nameRight"]))


## The pick avatar that draws the 64-logical (16-art) medallion at whole device px: the densest of
## the 96 (d3), 64 (d2) and 32 px heads whose pixel count divides 16·k (k 6 → 96, k 4 → 64,
## k 2 → 32; a fractional scale falls back to the densest available). [id, logical px per sprite px].
static func face_sprite(art: String, k: int, integer: bool) -> Array:
	var ch: Dictionary = SpriteStrip.manifest().get("chars", {}).get(art, {})
	var cands := [[str(ch.get("avatarPickXL", "avatar_pick_" + art + "_d3")), 96], [str(ch.get("avatarPick64", "avatar_pick_" + art + "_d2")), 64],
		[str(ch.get("avatarPick", "avatar_pick_" + art)), 32]]
	var fallback: Array = []
	for c: Array in cands:
		if not Art.has_sprite(str(c[0])) or Art.sprite_size(str(c[0])).x != int(c[1]):
			continue
		if fallback.is_empty():
			fallback = [str(c[0]), 64.0 / float(c[1])]
		if integer and (16 * k) % int(c[1]) == 0:
			return [str(c[0]), 64.0 / float(c[1])]
	return fallback


## The round's leader (""/unknown: the chip hides). Rebuilds the face only when the leader changes.
func set_leader(leader_id: String) -> void:
	if leader_id == _leader:
		return
	_leader = leader_id
	if face != null:
		face.queue_free()
		face = null
	leader_name.text = LeaderUi.short(leader_id) if leader_id != "" else ""
	if leader_id != "":
		_face_k = Display.k
		var fs := face_sprite(LeaderUi.art(leader_id), Display.k, Display.integer)
		if not fs.is_empty():
			face = Ui.img(self, Vector2.ZERO, str(fs[0]), 0, 4)
			face.scale = Vector2(float(fs[1]), float(fs[1]))
	_place_identity()
	_apply_identity(false)


func leader_shown() -> String:
	return _leader if _id_on else ""


## `on`: the chip is on screen (a leader is set and Row A is up); `name_on`: the name holds the slot
## (no cup yet, or the round has not started). The width guard applies on top of it.
func set_identity(on: bool, name_on: bool) -> void:
	var fade := on and _id_on and name_on != _name_want
	_id_on = on
	_name_want = name_on
	_apply_identity(fade and not reduced_motion)


## The name holds the slot it shares with the Cottage Index (the cup stays hidden meanwhile).
func name_claims_slot() -> bool:
	return _id_on and _name_want and leader_name.text != ""


## The name's visible state (tests, window.odDev): wanted and clear of the counter and rate line.
func name_visible() -> bool:
	return leader_name.visible and leader_name.modulate.a > 0.5


## The chip's drawn rect (face + name when shown), `_top`-local; empty when hidden.
func identity_rect() -> Rect2:
	if not _id_on or face == null:
		return Rect2()
	var r := face_rect()
	if name_visible():
		var nw := float(leader_name.width())
		r = r.merge(Rect2(name_right() - nw, float(L.TOP["nameY"]), nw, 44.0))
	return r


## The name clears the counter's and the rate line's drawn ink by nameGap (16).
func name_fits() -> bool:
	var left := name_right() - float(leader_name.width())
	var gap := float(L.TOP["nameGap"])
	for t: PxText in [bank, bps]:
		if t.visible and t.text != "" and t.position.x + float(t.width()) + gap > left:
			return false
	return true


func _place_identity() -> void:
	if leader_name == null:
		return
	if face != null:
		var fr := face_rect()
		var sz := Vector2(Art.sprite_size(face.get_meta("sprite", ""))) * face.scale if face.has_meta("sprite") else fr.size
		face.position = fr.position + ((fr.size - sz) / 2.0).floor()
	leader_name.right_at(name_right())


func _apply_identity(fade: bool) -> void:
	if face != null:
		face.visible = _id_on
	var show := _id_on and _name_want and leader_name.text != "" and name_fits()
	if _name_tw:
		_name_tw.kill()
		_name_tw = null
	if not fade or not _id_on:
		leader_name.visible = show
		leader_name.modulate.a = 1.0
		return
	if show:
		if not leader_name.visible:
			leader_name.modulate.a = 0.0
		leader_name.visible = true
		_name_tw = create_tween()
		_name_tw.tween_property(leader_name, "modulate:a", 1.0, 0.15)
	elif leader_name.visible:
		_name_tw = create_tween()
		_name_tw.tween_property(leader_name, "modulate:a", 0.0, 0.15)
		_name_tw.tween_callback(func() -> void:
			leader_name.visible = false
			leader_name.modulate.a = 1.0)


# ------------------------------------------------------------------ counter / rate

func set_bank(money: float) -> void:
	bank.text = Strings.s("HUD_BANK", {"n": Fmt.bank(maxf(0.0, money - _roll_remainder))})
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
## line then reads HUD_BPS_POUR in the frenzy tint rather than "+0.0 ₪ לשנייה" (review R24); while
## taps are paying it shows what they pay (the live rate) in the same tint.
## The hop and the juiceGain tint answer the PASSIVE rate only (a buy, a frenzy): the taps' part
## moves the number, never the hop (TAP_*).
func set_bps(rate_bps: float, frenzy_mult: float, pour: bool = false) -> void:
	var changed := pour != _pour or rate_bps != _base_bps or frenzy_mult != _frenzy_mult or bps.text == ""
	_base_bps = rate_bps
	_frenzy_mult = frenzy_mult
	_pour = pour
	if pour:
		_frenzy = true
		_prev_rate = -1.0
		_passive = 0.0
		_render_rate(changed)
		return
	var rate := rate_bps * frenzy_mult
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
	_passive = rate if _frenzy else rate_bps   # as before: the plain line shows the unmultiplied bps
	_render_rate(changed)


## One paid tap (manual or auto, crit and frenzy included): Economy.tap's value. Display only.
func note_tap(value: float) -> void:
	if not (value > 0.0) or is_inf(value) or is_nan(value):
		return
	if _taps.is_empty():
		_burst_at = _now
	_taps.append([_now, value])
	_tap_sum += value
	_last_tap_at = _now


## The taps' smoothed ₪/s now (tests, window.odDev).
func tap_rate() -> float:
	return _tap_rate


## The rate the line shows now: the passive part + the taps' part (as last drawn).
func shown_rate() -> float:
	return _tap_shown if _pour else _passive + _tap_shown


## TAP_*: drop the taps older than the window, then ease the smoothed rate toward the window's.
func _tick_taps(dt_ms: float) -> void:
	while not _taps.is_empty() and _now - float(_taps[0][0]) >= TAP_WINDOW_MS:
		_tap_sum -= float(_taps[0][1])
		_taps.pop_front()
	var raw := 0.0
	if _taps.is_empty():
		_tap_sum = 0.0
	else:
		raw = maxf(0.0, _tap_sum) / (clampf(_now - _burst_at, TAP_MIN_SPAN_MS, TAP_WINDOW_MS) / 1000.0)
	if _now - _last_tap_at >= TAP_ZERO_MS:
		_tap_rate = 0.0
	else:
		_tap_rate += (raw - _tap_rate) * (1.0 - exp(-maxf(0.0, dt_ms) / TAP_SMOOTH_MS))


func _tap_cue() -> bool:
	return _tap_shown > 0.0 and _tap_shown >= TAP_CUE_SHARE * shown_rate()


## Draws the line from the stored passive rate and the taps' part. `force` (the passive rate or
## the mode changed) redraws now; otherwise the taps' part changes at most every RATE_TEXT_MS and
## only past the dead band (or to exactly 0).
func _render_rate(force: bool) -> void:
	if force or _now - _rate_text_at >= RATE_TEXT_MS:
		var old := shown_rate()
		var want := _tap_rate
		var total := want if _pour else _passive + want
		if force or (want == 0.0 and _tap_shown != 0.0) or absf(total - old) > RATE_DEADBAND * maxf(old, 1e-6):
			if want != _tap_shown:
				_rate_text_at = _now
			_tap_shown = want
	var th := Art.theme
	var rb: Rect2 = rate_box()
	if _pour:
		bps.text = Strings.s("HUD_BPS", {"rate": Fmt.rate(_tap_shown)}) if _tap_shown > 0.0 else Strings.s("HUD_BPS_POUR")
		bps.center_in(rb.position.x, rb.size.x)
		bps.tint = Art.col(th["statText"]["bpsFrenzy"])
		bps.self_modulate.a = 1.0
		return
	var shown := shown_rate()
	if _frenzy:
		var m := str(int(_frenzy_mult)) if is_equal_approx(_frenzy_mult, roundf(_frenzy_mult)) else str(_frenzy_mult)
		bps.text = Strings.s("HUD_BPS_FRENZY", {"rate": Fmt.rate(shown), "mult": m})
	else:
		bps.text = Strings.s("HUD_BPS", {"rate": Fmt.rate(shown)})
	bps.center_in(rb.position.x, rb.size.x)
	var cue := _tap_cue()
	bps.tint = Art.col(th["statText"]["bpsFrenzy"]) if _frenzy else (C_RATE_TAP if cue else Art.col(th["juiceGain"] if _now < _bps_tint_until else th["statText"]["bps"]))
	# 100% for 3 s after a change (and while taps carry it), then the settled alpha (first-minute §3.2 #1b)
	bps.self_modulate.a = 1.0 if (_frenzy or cue or _now - _rate_changed_at < RATE_DIM_AFTER_MS) else RATE_DIM_ALPHA


func reset_rate() -> void:
	_prev_rate = -1.0
	_taps.clear()
	_tap_sum = 0.0
	_tap_rate = 0.0
	_tap_shown = 0.0
	_last_tap_at = -1e9


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
	_tick_taps(dt_ms)
	if bps.text != "":
		_render_rate(false)   # the live rate's throttled redraw (TAP_*); also settles the alpha
	# the width guard: the counter or the rate line grew into the name's slot (or left it again)
	if _id_on and _name_want and (_name_tw == null or not _name_tw.is_running()) and leader_name.visible != name_fits():
		_apply_identity(not reduced_motion)
