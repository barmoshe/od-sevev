class_name ElectionCard
extends SheetCard
## O3, the election card (ux/rtl-map.md §7.2 "EvolutionOverlay → O3, modal, stacked buttons";
## first-minute §1.1 and copy deck elect.*), opened from the ticker's "עוד סבב!" CTA (§5.3) or E.
## It replaces the fork's EvolutionOverlay (EVO_* at ×3 on fixed y, review R8).
##
##   title        ELECT_TITLE "סבב בחירות מס׳ {n}" (n = the round being called: evolutions + 1)
##   mood         MOOD_* for that round (the title state's line 2), muted, centred
##   the number   EVO_MULT "×now ← ×after" in money gold, centred (the loyal base's multiplier)
##   body         ELECT_RESET, ELECT_KEEP ({n} = the base after this election), ELECT_KEEP_CASES
##   not ready    EVO_NEED in red_hi, and "לפזר את הכנסת" disabled (E or a stale CTA)
##   buttons      §7.1 STACKED: ELECT_GO (kit primary) over ELECT_CANCEL (secondary); ✕ top-left
## Backdrop, Esc and back = "עוד לא". The confirm is idempotent (E7): the first press commits.

const MOODS := [1, 3, 5, 6, 10, 20]
## mobile-first §5.14.1 (F15): the hemicycle, the card's hero between the title band and the
## leader line (now its caption), ×4 (288 × 152), gaps 16 above and below; left out when the card
## would not fit the modal band (on the matrix: 375×548 only).
const HEMI_SCALE := 4.0
const HEMI_GAP := 16.0

var committed := false
var go_button: PxButton
var cancel_button: PxButton
var ready_state := false
var need_text: PxText
var leader_text: PxText   # ELECT_LEADER "{short} · {party}" (leader select)
var hemicycle: Hemicycle  # null when left out (no room, no coalition, no art)


## The 120-seat hemicycle: `hemicycle_track`, then `hemicycle_fill`'s seats[0 : n] over it (the
## kit's order is the fill order: seat 1 at the right end, sweeping left, RTL). No numeral, no
## input; drawn in the blackout too (its fill obeys the bar's rule, rtl-map §3).
class Hemicycle extends Node2D:
	var n := 0
	var scale_px := 4.0

	func size() -> Vector2:
		return Vector2(Art.sprite_size("hemicycle_track")) * scale_px

	func _draw() -> void:
		draw_texture_rect(Art.tex("hemicycle_track"), Rect2(Vector2.ZERO, size()), false)
		var fill := Art.tex("hemicycle_fill")
		var seats: Array = Art.kit("hemicycle_fill").get("seats", [])
		for i in mini(n, seats.size()):
			var r: Array = seats[i]
			var src := Rect2(float(r[0]), float(r[1]), float(r[2]), float(r[3]))
			draw_texture_rect_region(fill, Rect2(src.position * scale_px, src.size * scale_px), src)


## The seats the hemicycle fills: the effective seats (the gate's own count), 0-120.
static func hemi_seats(s: GameState) -> int:
	return clampi(int(Coalition.seat_info(s)["effective"]), 0, 120)


## The public-mood line for round n: the MOOD_k with the largest k ≤ n (MOOD_1 … MOOD_20).
static func mood_key(n: int) -> String:
	var best := "MOOD_1"
	for k: int in MOODS:
		if n >= k and Strings.has("MOOD_%d" % k):
			best = "MOOD_%d" % k
	return best


## The income multiplier after this election, as Economy.derive will compute it (the aide drops'
## ×0.97 each stay in d.base_mult across elections).
static func mult_after(s: GameState, d: Economy.Derived) -> float:
	return (1.0 + Economy.mult_per_base() * float(s.thumbs_owned + (d.pending if d.evolve_enabled else d.needed))) * d.base_mult


func build() -> ElectionCard:
	id = "EVOLUTION"
	var s: GameState = host.state
	var d: Economy.Derived = host.d
	ready_state = d.evolve_enabled
	_begin()
	var n := s.evolutions + 1
	title(Strings.s("ELECT_TITLE", {"n": n}))
	var with_hemi := Coalition.active() and Art.has_sprite("hemicycle_track") and Art.has_sprite("hemicycle_fill")
	var hemi_y := HEADER_H + HEMI_GAP
	var hemi_h := float(Art.sprite_size("hemicycle_track").y) * HEMI_SCALE if with_hemi else 0.0
	if with_hemi:
		_y = hemi_y + hemi_h + HEMI_GAP
	if LeaderUi.short() != "":   # rtl-map §8.8 (D33): the round's leader under the title
		leader_text = para(Strings.s("ELECT_LEADER", {"short": LeaderUi.short(), "party": LeaderUi.party()}), C_TEXT, true, 1)
	para(Strings.s(mood_key(n)), C_MUTED, true, 2)
	para(Strings.s("EVO_MULT", {"now": Fmt.mult(d.prestige_mult), "after": Fmt.mult(mult_after(s, d))}), C_GOLD, true, 1)
	gap(8.0)
	para(Strings.s("ELECT_RESET"))
	para(Strings.s("ELECT_KEEP", {"n": Fmt.thumbs(float(s.thumbs_owned + (d.pending if d.evolve_enabled else 0)))}))
	para(Strings.s("ELECT_KEEP_CASES"))
	if not ready_state:
		need_text = para(Strings.s("EVO_NEED"), C_ALERT)
	close_x(func() -> void: cancel("close"))
	# stacked (rtl-map §7.2): "לפזר את הכנסת" does not fit a 224 half at ×4
	_specs.append([Rect2(88, Ui.snap(_y - PARA_GAP + PAD, 4), 544, BTN_H), Strings.s("ELECT_GO"), "kit_gold", _do_confirm])   # review U2: it completes the gold "עוד סבב!" CTA
	_y = Ui.snap(_y - PARA_GAP + PAD, 4) + BTN_H + BTN_GAP
	_specs.append([Rect2(88, _y, 544, BTN_H), Strings.s("ELECT_CANCEL"), "kit_secondary", func() -> void: cancel("close")])
	_y += BTN_H
	# §5.14.1 "when it fits": laid out with the hemicycle; if the card is then taller than the modal
	# band, the hemicycle is left out and the card is exactly the one without it
	if with_hemi and laid_h() > room():
		var dy := (hemi_y + hemi_h + HEMI_GAP) - (HEADER_H + PAD)
		for p: PxText in paras:
			p.position.y -= dy
		for sp: Array in _specs:
			var r: Rect2 = sp[0]
			r.position.y -= dy
			sp[0] = r
		_y -= dy
		with_hemi = false
	if with_hemi:
		hemicycle = Hemicycle.new()
		hemicycle.scale_px = HEMI_SCALE
		hemicycle.n = hemi_seats(s)
		var g2 := grow_half()
		var cwc := CARD_W + 2.0 * g2
		hemicycle.position = Vector2(CARD_X - g2 + L.floor4((cwc - hemicycle.size().x) / 2.0), hemi_y)
		_holder.add_child(hemicycle)
	finish()
	go_button = buttons[0]
	cancel_button = buttons[1]
	go_button.set_enabled(ready_state)
	focus_index = default_focus()
	return self


## "לפזר את הכנסת" when it can be pressed, else "עוד לא".
func default_focus() -> int:
	return 0 if ready_state else 1


func on_opened() -> void:
	publish_web({"ready": ready_state, "hemicycle": hemi_view()})


## §5.14.1 publish: the hemicycle's [x, y, w, h, n] in viewport logical px, or null when left out.
func hemi_view() -> Variant:
	if hemicycle == null:
		return null
	var p := to_view(hemicycle.position + _holder.position)
	var sz := hemicycle.size()
	return [p.x, p.y, sz.x, sz.y, hemicycle.n]


func update_view(_dt_ms: float) -> void:
	if committed or go_button == null:
		return
	if hemicycle != null:
		var hn := hemi_seats(host.state)
		if hn != hemicycle.n:
			hemicycle.n = hn
			hemicycle.queue_redraw()
	var ready: bool = (host.d as Economy.Derived).evolve_enabled
	if ready != ready_state:
		ready_state = ready
		go_button.set_enabled(ready)
		if need_text != null:
			need_text.visible = not ready


func _do_confirm() -> void:
	if committed or not (host.d as Economy.Derived).evolve_enabled:
		return
	committed = true
	host.confirm_evolve()


func close_for_confirm() -> void:
	mgr.close(self, "confirm")


func cancel(via: String) -> void:
	if committed:
		return
	host.audio_event("evolveClose")
	mgr.close(self, via)
