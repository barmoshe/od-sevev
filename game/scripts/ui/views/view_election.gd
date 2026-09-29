class_name ElectionCard
extends SheetCard
## O3, the election card (ux/rtl-map.md §7.2 "EvolutionOverlay → O3, modal, stacked buttons";
## first-minute §1.1 and copy deck elect.*), opened from the ticker's "עוד סבב!" CTA (§5.3) or E.
## It replaces the fork's EvolutionOverlay (EVO_* at ×3 on fixed y, review R8).
##
##   title        ELECT_TITLE "סבב בחירות מס׳ {n}" (n = the round being called: evolutions + 1)
##   mood         MOOD_* for that round (the title state's line 2), muted, centred
##   the number   EVO_MULT "×now ← ×after" in money gold, centred (the loyal base's multiplier)
##   body         ELECT_RESET, ELECT_KEEP (+{x}% = the base after this election), ELECT_KEEP_CASES
##   not ready    EVO_NEED in red_hi, and "לפזר את הכנסת" disabled (E or a stale CTA)
##   buttons      §7.1 STACKED: ELECT_GO (kit primary) over ELECT_CANCEL (secondary); ✕ top-left
## Backdrop, Esc and back = "עוד לא". The confirm is idempotent (E7): the first press commits.

const MOODS := [1, 3, 5, 6, 10, 20]

var committed := false
var go_button: PxButton
var cancel_button: PxButton
var ready_state := false
var need_text: PxText


## The public-mood line for round n: the MOOD_k with the largest k ≤ n (MOOD_1 … MOOD_20).
static func mood_key(n: int) -> String:
	var best := "MOOD_1"
	for k: int in MOODS:
		if n >= k and Strings.has("MOOD_%d" % k):
			best = "MOOD_%d" % k
	return best


## ELECT_KEEP's {x}: the loyal base's bonus on every income after this election, in percent.
static func keep_pct(s: GameState, d: Economy.Derived) -> float:
	var after := Economy.mult_per_base() * float(s.thumbs_owned + (d.pending if d.evolve_enabled else 0))
	return maxf(0.0, after * 100.0)


static func mult_after(s: GameState, d: Economy.Derived) -> float:
	return 1.0 + Economy.mult_per_base() * float(s.thumbs_owned + (d.pending if d.evolve_enabled else d.needed))


func build() -> ElectionCard:
	id = "EVOLUTION"
	var s: GameState = host.state
	var d: Economy.Derived = host.d
	ready_state = d.evolve_enabled
	_begin()
	var n := s.evolutions + 1
	title(Strings.s("ELECT_TITLE", {"n": n}))
	para(Strings.s(mood_key(n)), C_MUTED, true, 2)
	para(Strings.s("EVO_MULT", {"now": Fmt.mult(d.prestige_mult), "after": Fmt.mult(mult_after(s, d))}), C_GOLD, true, 1)
	gap(8.0)
	para(Strings.s("ELECT_RESET"))
	para(Strings.s("ELECT_KEEP", {"x": Fmt.amount(keep_pct(s, d))}))
	para(Strings.s("ELECT_KEEP_CASES"))
	if not ready_state:
		need_text = para(Strings.s("EVO_NEED"), C_ALERT)
	close_x(func() -> void: cancel("close"))
	# stacked (rtl-map §7.2): "לפזר את הכנסת" does not fit a 224 half at ×4
	_specs.append([Rect2(88, Ui.snap(_y - PARA_GAP + PAD, 4), 544, BTN_H), Strings.s("ELECT_GO"), "kit_primary", _do_confirm])
	_y = Ui.snap(_y - PARA_GAP + PAD, 4) + BTN_H + BTN_GAP
	_specs.append([Rect2(88, _y, 544, BTN_H), Strings.s("ELECT_CANCEL"), "kit_secondary", func() -> void: cancel("close")])
	_y += BTN_H
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
	publish_web({"ready": ready_state})


func update_view(_dt_ms: float) -> void:
	if committed or go_button == null:
		return
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
