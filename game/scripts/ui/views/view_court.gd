class_name CourtView
extends Node2D
## Court day: the O2 card over the panel (ux/rtl-map.md §6.4), its collapsed chip in the ticker's
## date-chip slot (§5.1, D17), the steady stage tint, the postponement stinger with the growing
## excuse (motion-spec court-overlay-in / court-card-collapse / court-postpone / court-overlay-out,
## copy deck §H) and the aide drop's stacked confirm (§7.1-7.2). A child of `_lower`: y 0 is the
## ticker's top, the panel starts at 84, the tab bar at 84 + P; the stage is y −S … 0.
##
## A VIEW of `Investigation` (sim/README.md "Court card"): the phase (summons / court / postponed
## / idle), `leftSec`, `summonsSec`, `postpone_cost`, `excuse_step`. Every action is the sim's:
## "להעיד" → `Investigation.testify`, "התייעצות ביטחונית" → `Investigation.postpone`, "אני לא מכיר
## אותו" → `Investigation.drop_aide`. The events those return go back through the controller's one
## politics router (`host._on_politics_event`), which voices courtStart / courtEnd(reason); the
## postponement's courtEnd {reason: "postponed"} is routed on the stamp's impact frame (+90 ms;
## f0 under reduced motion), where the Audio plays gavelWeak.
##
## Card, card-local (x 16, bottom-anchored to the tab bar): ✕ hit Rect2(0, 0, 88, 88); the header
## plate with COURT_TITLE and the gavel at the right; from y 96 COURT_BODY, COURT_EFFECT and
## COURT_TIMER, right-aligned at x 656 in a 624 box, flowing by their real line count (the card
## grows upward); the button row: primary on the LEFT Rect2(16, y, 416, 104) with
## COURT_POSTPONE_VERB over CARD_PRICE, secondary on the RIGHT Rect2(448, y, 224, 104) COURT_TESTIFY;
## while an aide holds suitcase money, a full-width AIDE_BTN row under them.

const CARD_X := 16.0
const CARD_W := 688.0
const TEXT_RIGHT := 656.0
const TEXT_W := 624.0
const CLOSE_HIT := Rect2(0, 0, 88, 88)
const CHIP_H := 80.0
const CHIP_Y := 2.0
const CHIP_MIN_W := 212.0
const TINT := Color("#d02a36")        # the court red (steady: a tint, never a strobe)

## motion-spec.yaml motion-constants (Tune.MC wins once the engine mirrors them)
const MC_DEFAULTS := {
	"courtCardInMs": 280, "courtCardOutMs": 180, "courtTintAlpha": 0.18, "courtTintMs": 400,
	"excuseReadMsPerChar": 60, "excuseReadMinMs": 2000, "stampSlamMs": 90, "tapBurstGuardMs": 1000,
	"courtCollapseMs": 200, "courtExpandMs": 240,
}

var host: Node
var reduced_motion := false

var _state: GameState
var _d: Economy.Derived
var _known_state: GameState
var _now := 0.0
var _ox := 0.0
var _vs_w := 720.0

## hidden | open | chip | postponed | exit
var _mode := "hidden"
var _pending_open := false
var _anim: Dictionary = {}           # {kind: in|out|collapse|expand, t}
var _layout_sig := ""
var _card_h := 0.0
var _covered := false                # a tall tab covers the ticker (the chip hides)

var _tint: ColorRect
var _tint_a := 0.0
var _card := Node2D.new()            # carries the motion offsets only
var _inner: Node2D                   # the card-local content, placed at the card's top
var _frame: NinePatchRect
var _close_icon: Sprite2D
var _gavel: Sprite2D
var _title: PxText
var _body: PxText
var _effect: PxText
var _timer: PxText
var _prefix: PxText
var _excuse: PxText
var _stamp: Sprite2D
var _primary: PxButton
var _verb: PxText
var _price: PxText
var _testify: PxButton
var _aide: PxButton
var _btn_y := 0.0
var _jolt := 0.0
var _shake_t := -1.0
var _press: Dictionary = {}

var _chip := Node2D.new()
var _chip_bg: NinePatchRect
var _chip_icon: Sprite2D
var _chip_title: PxText
var _chip_timer: PxText
var _chip_w := CHIP_MIN_W
var _chip_on := false

# the postponement stinger
var _pp: Dictionary = {}             # {t, step, events, routed, text, prev, hold}


static func mc(key: String) -> float:
	if Tune.MC.has(key):
		return float(Tune.MC[key])
	return float(MC_DEFAULTS.get(key, 0.0))


func setup(host_: Node) -> CourtView:
	host = host_
	return self


func _ready() -> void:
	_tint = Ui.rect(self, Rect2(0, -L.stage_h, L.W, L.stage_h), TINT, 0.0)
	_tint.visible = false
	add_child(_card)
	_card.visible = false
	add_child(_chip)
	_chip.visible = false
	_chip_bg = Ui.nine(_chip, Rect2(0, 0, CHIP_MIN_W, CHIP_H), Art.sprite_or("chip_court"))
	_chip_icon = Ui.img(_chip, Vector2.ZERO, Art.sprite_or("chip_icon_gavel"), 0, 4)
	_chip_title = PxText.make(_chip, Vector2(0, 4), LeaderUi.s("COURT_CHIP_TITLE"), L.TEXT, "plain", "w")
	_chip_title.max_lines = 1
	_chip_timer = PxText.make(_chip, Vector2(0, 44), "", L.TEXT, "plain", "w")
	_chip_timer.max_lines = 1
	relayout()


func relayout() -> void:
	if host != null and "_ox" in host:
		_ox = float(host.get("_ox"))
		_vs_w = float((host.get("_vs") as Vector2).x)
	if _tint == null:
		return
	_tint.position = Vector2(-_ox - 8.0, -L.stage_h)
	_tint.size = Vector2(_vs_w + 16.0, L.stage_h)
	_layout_sig = ""
	_place_card()


# ------------------------------------------------------------------ reads

func phase() -> String:
	return Investigation.phase(_state) if _state != null and Investigation.active() else "idle"


func mode() -> String:
	return _mode


func card_visible() -> bool:
	return _card.visible


## The card is expanded and not already folding into its chip: one browser history layer (R9).
func expanded() -> bool:
	return _mode == "open" and String(_anim.get("kind", "")) != "collapse"


## The card is folding into its chip (the collapse motion runs): no longer a layer, takes no input.
func folding() -> bool:
	return _mode == "open" and String(_anim.get("kind", "")) == "collapse"


func card_rect() -> Rect2:
	return Rect2(CARD_X, L.tabs_y() - _card_h, CARD_W, _card_h)


func chip_rect() -> Rect2:
	return Rect2(8, CHIP_Y, _chip_w, CHIP_H)


## The chip's hit, grown to 88 tall (rtl-map §10).
func chip_hit() -> Rect2:
	return Rect2(8, 0, _chip_w, 88)


func chip_visible() -> bool:
	return _chip.visible


## The expanded card reaches into the Suitcase band (the floor viewport, rtl-map §4.1 guard).
func covers_band() -> bool:
	return _card.visible and card_rect().position.y < -4.0


## The timer text for the card and the chip: the automatic testimony's countdown during a summons,
## the testimony left during court day (ChatView.mmss: m:ss, ceil to the second).
func timer_sec() -> float:
	if _state == null:
		return 0.0
	match phase():
		"summons":
			return maxf(0.0, float(Investigation.cfg().get("summonsAutoTestifySec", 0.0)) - float(_state.investigation.get("summonsSec", 0.0)))
		"court":
			return float(_state.investigation.get("leftSec", 0.0))
	return 0.0


## The card's and the chip's texts by phase (rtl-map §6.4 "Two phases, two texts", review R10):
## the summons is the choice, nothing is slowed yet and its timer is the countdown to the
## automatic testimony; the court phase is the testimony itself. The card rebuilds on the phase
## edge (the layout signature carries the phase).
static func phase_keys(ph: String) -> Dictionary:
	if ph == "summons":
		return {"title": "COURT_SUMMONS_TITLE", "body": "COURT_SUMMONS_BODY", "effect": "COURT_SUMMONS_EFFECT",
			"timer": "COURT_SUMMONS_TIMER", "chip": "COURT_CHIP_SUMMONS"}
	return {"title": "COURT_TITLE", "body": "COURT_BODY", "effect": "COURT_EFFECT", "timer": "COURT_TIMER", "chip": "COURT_CHIP_TITLE"}


## The expanded card's height while it sits over a tall tab (T3 / T4): that tab's list pads its
## bottom by it so its last rows scroll clear (rtl-map §6.4 "Depth", review R21). 0 when the card
## is folded, hidden or leaving.
func pad_height() -> float:
	return _card_h if _card.visible and (_mode == "open" or _mode == "postponed") else 0.0


## The court view of a host (the tall tabs ask it for their padding), or null.
static func of(h: Node) -> CourtView:
	if h == null or not "court" in h:
		return null
	var c: Variant = h.get("court")
	return c as CourtView if c is CourtView else null


## The excuse line for a postponement step (content copy, court.postpone.copy.excuses; the sim
## holds no Hebrew). Steps past the list hold on the last line ("loops at step 6").
static func excuse(step: int) -> String:
	if not LeaderUi.court():   # the press skin: the leader's own ladder (spec §5.6)
		return LeaderUi.press_excuse(step) if step >= 1 else ""
	var ex: Array = Investigation.cfg().get("postpone", {}).get("copy", {}).get("excuses", [])
	if ex.is_empty() or step < 1:
		return ""
	return str(ex[mini(step, ex.size()) - 1])


# ------------------------------------------------------------------ per frame

## ctx: {main: bool, covered: bool (a tall tab covers the ticker and panel)}.
func update_view(dt: float, s: GameState, d: Economy.Derived, ctx: Dictionary = {}) -> void:
	_now += dt
	if not is_same(s, _known_state):
		_on_new_state(s)
	_state = s
	_d = d
	_covered = bool(ctx.get("covered", false))
	var live: bool = ctx.get("main", true)
	var ph := phase()
	if not live:
		_hide_now()
	else:
		# the sim moved on without an event we saw (a load, an aide drop, an election)
		if _mode in ["open", "chip"] and not (ph == "summons" or ph == "court"):
			_start_exit()
		if _mode == "hidden" and (ph == "summons" or ph == "court") and not _pending_open:
			_pending_open = true
		if _pending_open and _tap_guard_clear():
			_pending_open = false
			if ph == "summons":
				_enter()
			elif ph == "court":
				_set_mode("chip")
	_update_pp(dt)
	_update_anim(dt)
	_update_tint(dt, live and ph == "court")
	_sync_card()
	_sync_chip()


func _on_new_state(s: GameState) -> void:
	_known_state = s
	_pp = {}
	_anim = {}
	_pending_open = false
	_state = s
	var ph := phase()
	_set_mode("chip" if (ph == "summons" or ph == "court") else "hidden")
	_tint_a = mc("courtTintAlpha") if ph == "court" else 0.0


func _hide_now() -> void:
	if _mode != "hidden":
		_set_mode("hidden")
	_pp = {}
	_anim = {}
	_jolt = 0.0


## UX rule 3 / motion-spec no_auto_open_in_tap_burst: the card never enters while the last
## registered tap is < 1 s old; it waits, then plays in full.
func _tap_guard_clear() -> bool:
	if host == null or not "_last_tap_ms" in host or not "_now" in host:
		return true
	return float(host.get("_now")) - float(host.get("_last_tap_ms")) >= mc("tapBurstGuardMs")


func _set_mode(m: String) -> void:
	_mode = m
	_card.visible = m == "open" or m == "postponed" or m == "exit"
	_layout_sig = ""


func _enter() -> void:
	_set_mode("open")
	_anim = {"kind": "in", "t": 0.0}


func _start_exit() -> void:
	if _mode == "chip" or not _card.visible:
		_set_mode("hidden")
		return
	_mode = "exit"
	_anim = {"kind": "out", "t": 0.0}


## ✕ or "להעיד": the card folds into the ticker chip (motion court-card-collapse).
func collapse() -> void:
	if _mode != "open":
		return
	_anim = {"kind": "collapse", "t": 0.0}


## A tap on the chip: the card unfolds (the chip cuts out at f0).
func expand() -> void:
	if _mode != "chip":
		return
	_set_mode("open")
	_anim = {"kind": "expand", "t": 0.0}


func _update_anim(dt: float) -> void:
	if _anim.is_empty():
		_card.position = Vector2(0, _jolt)
		_card.modulate.a = 1.0
		return
	_anim["t"] = float(_anim["t"]) + dt
	var t: float = _anim["t"]
	match String(_anim["kind"]):
		"in":
			if reduced_motion:
				_card.position.y = 0.0
				_card.modulate.a = minf(1.0, t / 150.0)
				if t >= 150.0:
					_anim = {}
				return
			var ms := mc("courtCardInMs")
			var k := minf(1.0, t / ms)
			var jolt := 4.0 if (t >= 180.0 and t < 180.0 + 2.0 * Tune.FRAME_MS) else 0.0
			_card.position.y = Ui.snap(24.0 * (1.0 - Ui.back_out(k, 1.70158)), 4) + jolt
			_card.modulate.a = Ui.quad_out(minf(1.0, t / 120.0))
			if k >= 1.0 and jolt == 0.0 and t >= 180.0 + 2.0 * Tune.FRAME_MS:
				_anim = {}
		"out":
			var ms2 := 120.0 if reduced_motion else mc("courtCardOutMs")
			var k2 := minf(1.0, t / ms2)
			_card.position.y = 0.0 if reduced_motion else Ui.snap(24.0 * Ui.quad_in(k2), 4)
			_card.modulate.a = 1.0 - k2
			if k2 >= 1.0:
				_anim = {}
				_set_mode("hidden")
		"collapse":
			var ms3 := 120.0 if reduced_motion else mc("courtCollapseMs")
			var k3 := minf(1.0, t / ms3)
			if reduced_motion:
				_card.modulate.a = 1.0 - k3
			else:
				# toward the chip slot (up and left), fading over its last 80 ms
				var dy := (chip_rect().position.y - card_rect().position.y) * Ui.quad_in(k3)
				_card.position = Vector2(0, Ui.snap(dy, 4))
				_card.modulate.a = 1.0 if t < 120.0 else maxf(0.0, 1.0 - (t - 120.0) / 80.0)
			if k3 >= 1.0:
				_anim = {}
				_set_mode("chip")
		"expand":
			var ms4 := 120.0 if reduced_motion else mc("courtExpandMs")
			var k4 := minf(1.0, t / ms4)
			if reduced_motion:
				_card.modulate.a = k4
			else:
				var dy2 := (chip_rect().position.y - card_rect().position.y) * (1.0 - Ui.quad_out(k4))
				_card.position = Vector2(0, Ui.snap(dy2, 4))
				_card.modulate.a = Ui.quad_out(k4)
			if k4 >= 1.0:
				_anim = {}


func _update_tint(dt: float, on: bool) -> void:
	var want := mc("courtTintAlpha") if on else 0.0
	var ms := 200.0 if reduced_motion else mc("courtTintMs")
	_tint_a = move_toward(_tint_a, want, mc("courtTintAlpha") * dt / maxf(1.0, ms))
	_tint.color.a = _tint_a
	_tint.visible = _tint_a > 0.001 and not _covered


func tint_alpha() -> float:
	return _tint_a


# ------------------------------------------------------------------ card build / sync

func _layout_signature() -> String:
	if _state == null:
		return ""
	var aide := _mode == "open" and phase() == "summons" and Investigation.can_drop_aide(_state)
	return "%s|%s|%s|%s|%d|%s" % [_mode, phase(), "A" if aide else "", "L" if PxText.large_text else "",
		int(_pp.get("step", 0)), "T" if Investigation.postpone_cost(_state, _d) >= 0.0 else ""] if _d != null else _mode


func _sync_card() -> void:
	if not _card.visible or _state == null:
		return
	var sig := _layout_signature()
	if sig != _layout_sig:
		_layout_sig = sig
		_build_card()
	_update_card_live()


func _build_card() -> void:
	if _inner != null:
		_inner.queue_free()
		_card.remove_child(_inner)
	_inner = Node2D.new()
	_card.add_child(_inner)
	_primary = null
	_testify = null
	_aide = null
	_verb = null
	_price = null
	_timer = null
	_excuse = null
	_stamp = null
	_frame = Ui.nine(_inner, Rect2(CARD_X, 0, CARD_W, 356), Art.sprite_or("court_frame"))
	var close_id := Art.sprite_or("icon_close")
	var csz := Vector2(Art.sprite_size(close_id)) * 4.0
	_close_icon = Ui.img(_inner, Vector2(CARD_X, 0) + (CLOSE_HIT.get_center() - csz / 2.0).snapped(Vector2(4, 4)), close_id, 0, 4)
	_close_icon.visible = _mode != "postponed"   # the stamp's corner: nothing to collapse while it reads
	# kit court_frame: the gavel at the header's right, x w − 18 art, y 5 art (frame-local)
	# the press skin has no gavel (it means the court): the folded newspaper (rtl-map §4.3)
	var gid := Art.sprite_or("thermo_icon_gavel" if LeaderUi.court() or LeaderUi.press_icon("thermo") == "" else LeaderUi.press_icon("thermo"))
	_gavel = Ui.img(_inner, Vector2(CARD_X + CARD_W - 18.0 * 4.0, 20), gid, 0, 4)
	var keys := phase_keys(phase())
	_title = _t(LeaderUi.s(keys["title"]), Color.WHITE, 432.0, 1)
	_title.right_at(_gavel.position.x - 12.0)
	_title.position.y = 24.0
	var y := 96.0
	if _mode == "postponed":
		_prefix = _t(LeaderUi.s("COURT_POSTPONED_PREFIX"), Color("#a4a9b8"), TEXT_W, 1)
		_prefix.right_at(CARD_X + TEXT_RIGHT)
		_prefix.position.y = y
		y += _lh(_prefix)
		_excuse = _t(excuse(int(_pp.get("step", 1))), Color.WHITE, TEXT_W, 8, true)
		_excuse.right_at(CARD_X + TEXT_RIGHT)
		_excuse.position.y = y
		_excuse.set_meta("y0", y)
		_excuse.modulate.a = 0.0
		y += _lh(_excuse) * maxf(1.0, float(_excuse.line_count()))
		var sid := Art.sprite_or("stamp_postponed_dark_rot" if Art.has_sprite("stamp_postponed_dark_rot") else "stamp_postponed_dark")
		_stamp = Ui.img(_inner, Vector2.ZERO, sid, 0, 4)
		_stamp.centered = true
		var ssz := Vector2(Art.sprite_size(sid)) * 4.0
		_stamp.position = Vector2(CARD_X + 24.0 + ssz.x / 2.0, 12.0 + ssz.y / 2.0).snapped(Vector2(4, 4))
		y += 24.0
	else:
		_body = _t(LeaderUi.s(keys["body"]), Color.WHITE, TEXT_W, 3, true)
		_body.right_at(CARD_X + TEXT_RIGHT)
		_body.position.y = y
		y += _lh(_body) * maxf(1.0, float(_body.line_count()))
		_effect = _t(LeaderUi.s(keys["effect"]), Color("#fff1a6"), TEXT_W, 2, true)
		_effect.right_at(CARD_X + TEXT_RIGHT)
		_effect.position.y = y
		y += _lh(_effect) * maxf(1.0, float(_effect.line_count()))
		_timer = _t("", Color.WHITE, TEXT_W, 1)
		_timer.position.y = y
		y += _lh(_timer) + 8.0
		if phase() == "summons" and _mode == "open":
			_btn_y = Ui.snap(y, 4)
			if _d != null and Investigation.postpone_cost(_state, _d) >= 0.0:
				_primary = PxButton.make(_inner,Rect2(CARD_X + 16, _btn_y, 416, 104), {"kind": "kit_primary"})
				_verb = _t(LeaderUi.s("COURT_POSTPONE_VERB"), Color.WHITE, 384.0, 1)
				_verb.position.y = _btn_y + 12.0
				_verb.center_in(CARD_X + 16, 416)
				_price = _t("", Color.WHITE, 384.0, 1)
				_price.position.y = _btn_y + 56.0
			_testify = PxButton.make(_inner,Rect2(CARD_X + 448, _btn_y, 224, 104), {"kind": "kit_secondary", "label": LeaderUi.s("COURT_TESTIFY")})
			y = _btn_y + 104.0 + 16.0
			if Investigation.can_drop_aide(_state):
				_aide = PxButton.make(_inner,Rect2(CARD_X + 16, y, 656, 88), {"kind": "kit_secondary", "label": Strings.s("AIDE_BTN")})
				y += 88.0 + 16.0
		else:
			y += 16.0
	_card_h = Ui.snap(maxf(y, 176.0), 4)
	Ui.set_nine_rect(_frame, Rect2(CARD_X, 0, CARD_W, _card_h))
	_place_card()


## The card's content is card-local under `_inner`, which sits at the card's top: the bottom stays
## on the tab bar and the frame grows upward (`_card` itself only carries the motion offsets).
func _place_card() -> void:
	if _inner != null:
		_inner.position = Vector2(0, L.tabs_y() - _card_h)


## `reading`: the card's body copy (excuse, body, effect) on the @2 reading cut where crisp.
func _t(s: String, col: Variant, wrap: float, lines: int, reading: bool = false) -> PxText:
	var t := PxText.make(_inner, Vector2.ZERO, s, L.TEXT, "plain", col)
	t.reading = reading
	t.wrap_width = wrap
	t.max_lines = lines
	return t


func _lh(t: PxText) -> float:
	return float(HeFont.line_height()) * t.eff_px()


func _update_card_live() -> void:
	if _timer != null:
		var txt := LeaderUi.s(phase_keys(phase())["timer"], {"mmss": ChatView.mmss(timer_sec())})
		if _timer.text != txt:
			_timer.text = txt
			_timer.right_at(CARD_X + TEXT_RIGHT)
	if _primary != null and _d != null:
		var cost := Investigation.postpone_cost(_state, _d)
		var ptxt := Strings.s("CARD_PRICE", {"price": Fmt.cost(maxf(0.0, cost))})
		if _price.text != ptxt:
			_price.text = ptxt
		var ok := Investigation.can_postpone(_state, _d)
		if _primary.is_enabled() != ok and not bool(_press.get("primary", false)):
			_primary.set_enabled(ok)
		var dx := 0.0
		if _shake_t >= 0.0:
			_shake_t += Tune.FRAME_MS
			dx = 0.0 if reduced_motion else (4.0 if int(_shake_t / 45.0) % 2 == 0 else -4.0)
			if _shake_t >= 180.0:
				_shake_t = -1.0
				dx = 0.0
		_price.center_in(CARD_X + 16 + dx, 416)
		_verb.center_in(CARD_X + 16 + dx, 416)


# ------------------------------------------------------------------ the chip (ticker slot)

func _sync_chip() -> void:
	var ticker: Ticker = host.get("ticker") if host != null and "ticker" in host else null
	var ph := phase()
	var show := _mode == "chip" and (ph == "summons" or ph == "court") and not _covered \
		and not (ticker != null and ticker.cta_on())
	if show:
		var ct := LeaderUi.s(phase_keys(ph)["chip"])
		if _chip_title.text != ct:
			_chip_title.text = ct
		var cid := "chip_icon_gavel" if LeaderUi.court() or LeaderUi.press_icon("chip") == "" else LeaderUi.press_icon("chip")
		if str(_chip_icon.get_meta("sprite", "")) != Art.sprite_or(cid):
			_chip_icon.texture = Art.tex(Art.sprite_or(cid), 0)
			_chip_icon.set_meta("sprite", Art.sprite_or(cid))
		var tw := maxf(float(_chip_title.width()), float(_chip_timer.width()))
		var icon_w := float(Art.sprite_size(_chip_icon.get_meta("sprite")).x) * 4.0
		_chip_w = maxf(CHIP_MIN_W, Ui.snap(16.0 + tw + 12.0 + icon_w + 12.0, 4))
		Ui.set_nine_rect(_chip_bg, Rect2(8, CHIP_Y, _chip_w, CHIP_H))
		_chip_icon.position = Vector2(8.0 + _chip_w - 12.0 - icon_w, CHIP_Y + 10.0)
		_chip_title.position.y = CHIP_Y + 8.0    # two tight lines, 40 + 36 (rtl-map §5.1)
		_chip_title.right_at(_chip_icon.position.x - 8.0)
		var tt := Strings.s("COURT_CHIP_TIMER", {"mmss": ChatView.mmss(timer_sec())})
		if _chip_timer.text != tt:
			_chip_timer.text = tt
		_chip_timer.position.y = CHIP_Y + 44.0
		_chip_timer.right_at(_chip_icon.position.x - 8.0)
	_chip.visible = show
	if show != _chip_on:
		_chip_on = show
		if ticker != null and ticker.has_method("set_court_chip"):
			ticker.set_court_chip(show, 8.0 + _chip_w)


# ------------------------------------------------------------------ actions (through the sim)

## "להעיד": court day starts now. The events go through the controller's politics router.
func testify() -> bool:
	if _state == null or phase() != "summons":
		return false
	var ev := Investigation.testify(_state)
	_route(ev)
	_dirty()
	return not ev.is_empty()


## "התייעצות ביטחונית": pays through the sim; the stamp slams, courtEnd(postponed) is routed on
## its impact, and the excuse reveals. Returns false (with the can't-afford shake) when it can't.
func postpone() -> bool:
	if _state == null or _d == null:
		return false
	var r := Investigation.postpone(_state, _d)
	if r.is_empty():
		_shake_t = 0.0
		_audio("cantAfford")
		return false
	_pp = {"t": 0.0, "step": int(r.get("step", 1)), "events": r.get("events", []), "routed": false,
		"text": excuse(int(r.get("step", 1))), "prev": excuse(int(r.get("step", 1)) - 1), "hold": -1.0}
	_anim = {}
	_set_mode("postponed")
	_card.visible = true
	_dirty()
	if reduced_motion:
		_route_pp()
	return true


func _route_pp() -> void:
	if _pp.is_empty() or bool(_pp["routed"]):
		return
	_pp["routed"] = true
	_route(_pp["events"])


func _update_pp(dt: float) -> void:
	if _pp.is_empty() or _mode != "postponed":
		return
	_pp["t"] = float(_pp["t"]) + dt
	var t: float = _pp["t"]
	if _stamp != null:
		if reduced_motion:
			_stamp.scale = Vector2(4, 4)
			_stamp.modulate.a = 1.0
		else:
			var sc := 6.0 if t < 33.0 else (5.0 if t < 67.0 else 4.0)
			_stamp.scale = Vector2(sc, sc)
			_stamp.modulate.a = 0.6 if t < 33.0 else 1.0
	if t >= mc("stampSlamMs"):
		_route_pp()
	# the card jolts 1 ap on the impact (2 frames)
	var impact := mc("stampSlamMs")
	_jolt = 4.0 if (not reduced_motion and t >= impact and t < impact + 2.0 * Tune.FRAME_MS) else 0.0
	if _excuse != null:
		var text: String = _pp["text"]
		var prev: String = _pp["prev"]
		if reduced_motion:
			_excuse.text = text
			_excuse.modulate.a = minf(1.0, t / 150.0)
		else:
			var newest_at := 200.0 + (150.0 if prev != "" else 0.0)
			if t < 200.0:
				_excuse.modulate.a = 0.0
			elif t < newest_at:
				if _excuse.text != prev:
					_excuse.text = prev
					_excuse.right_at(CARD_X + TEXT_RIGHT)
				_excuse.modulate.a = minf(1.0, (t - 200.0) / 120.0)
			else:
				if _excuse.text != text:
					_excuse.text = text
					_excuse.right_at(CARD_X + TEXT_RIGHT)
				_excuse.modulate.a = 1.0
				var ht := t - newest_at
				var base_y := float(_excuse.get_meta("y0", _excuse.position.y))
				_excuse.position.y = base_y - (4.0 * (1.0 - Ui.quad_out(minf(1.0, ht / 100.0))) if ht < 100.0 else 0.0)
	var reveal_end := 150.0 if reduced_motion else 200.0 + (150.0 if str(_pp["prev"]) != "" else 0.0) + 120.0
	if t >= reveal_end and float(_pp["hold"]) < 0.0:
		_pp["hold"] = t + maxf(mc("excuseReadMinMs"), mc("excuseReadMsPerChar") * str(_pp["text"]).length())
	if float(_pp["hold"]) >= 0.0 and t >= float(_pp["hold"]):
		_finish_pp()


func _finish_pp() -> void:
	_route_pp()
	_pp = {}
	_jolt = 0.0
	_mode = "exit"
	_anim = {"kind": "out", "t": 0.0}


## A tap on the card during the reading hold skips it.
func skip_reading() -> void:
	if not _pp.is_empty() and float(_pp["hold"]) >= 0.0:
		_finish_pp()


func postponing() -> bool:
	return not _pp.is_empty()


## The aide drop's stacked confirm (rtl-map §7.1: commit on top, cancel below, focus on cancel,
## the backdrop does not close it). Confirm → Investigation.drop_aide.
func confirm_aide_drop() -> void:
	if host == null or not "overlays" in host or _state == null or not Investigation.can_drop_aide(_state):
		return
	var mgr: OverlayManager = host.get("overlays")
	if mgr == null or mgr.is_open():
		return
	_audio("panelOpen")
	var view := self
	mgr.request(func() -> Overlay:
		var o := AideConfirm.new()
		o.setup(host, mgr)
		o.court = view
		return o.build(), true)


## Drops the aide through the sim; the copy is the designer's (court.aide.copy).
func drop_aide() -> bool:
	if _state == null or not Investigation.drop_aide(_state):
		return false
	var cp: Dictionary = Investigation.cfg().get("aide", {}).get("copy", {})
	if host != null and "toasts" in host and host.get("toasts") != null:
		var tt: Toasts = host.get("toasts")
		if str(cp.get("line", "")) != "":
			tt.show_toast(str(cp["line"]))
		if str(cp.get("dubi", "")) != "":
			tt.say(str(cp["dubi"]), L.magician_feet() - Vector2(0, 380), 1600.0)
	_audio("uiClick")
	_dirty()
	return true


func _route(events: Variant) -> void:
	if not events is Array:
		return
	for e: Variant in events:
		if e is Dictionary:
			if host != null and host.has_method("_on_politics_event"):
				host.call("_on_politics_event", e)
			else:
				on_politics_event(e)


func _dirty() -> void:
	if host != null and host.has_method("_mark_dirty"):
		host.call("_mark_dirty")


func _audio(name: String, arg: Variant = null) -> void:
	if host != null and host.has_method("audio_event"):
		host.call("audio_event", name, arg)


## Politics events the court voices visually (the controller routes every Politics.tick event,
## and the events of testify / postpone, here).
func on_politics_event(e: Dictionary) -> void:
	match String(e.get("ev", "")):
		"summons":
			if _mode == "hidden" or _mode == "exit":
				_pending_open = true
		"courtStart":
			# the testimony runs in the chip; H-court pre-empts the ticker at f0
			if _mode == "open":
				collapse()
			elif _mode == "hidden":
				_set_mode("chip")
			var line := str(Investigation.cfg().get("copy", {}).get("courtDayTicker", ""))
			if line != "" and host != null and "ticker" in host and host.get("ticker") != null:
				(host.get("ticker") as Ticker).enqueue("milestone", line, true)
		"courtEnd":
			if str(e.get("reason", "")) != "postponed" and _mode != "postponed":
				_start_exit()


# ------------------------------------------------------------------ input (`_lower`-local points)

## True when the court card or its chip takes this press.
func pointer_down(p: Vector2) -> bool:
	_press = {}
	if _chip.visible and Ui.in_rect(chip_hit(), p):
		_press = {"kind": "chip"}
		return true
	# a card folding into its chip (Esc / back / ✕, motion court-card-collapse) or leaving takes no
	# press: its rect is still the expanded card's, so the first tap into T3/T4 right after Esc
	# landed on the folding card and did nothing (views dev, seen in Chromium, where a slow frame
	# stretches the 200 ms fold over several taps' worth of wall time)
	if not _card.visible or _mode == "exit" or folding():
		return false
	var cr := card_rect()
	if not Ui.in_rect(cr, p):
		return false
	var q := p - Vector2(0, cr.position.y) - _card.position   # card-local (x keeps the card's x 16)
	_press = {"kind": "card"}
	if _mode == "postponed":
		_press["kind"] = "skip"
		return true
	if Ui.in_rect(Rect2(CARD_X + CLOSE_HIT.position.x, CLOSE_HIT.position.y, CLOSE_HIT.size.x, CLOSE_HIT.size.y), q):
		_press["kind"] = "close"
	elif _primary != null and Ui.in_rect(Rect2(CARD_X + 16, _btn_y, 416, 104), q):
		_press["kind"] = "primary"
		_press["primary"] = true
		_primary.down()
	elif _testify != null and Ui.in_rect(Rect2(CARD_X + 448, _btn_y, 224, 104), q):
		_press["kind"] = "testify"
		_testify.down()
	elif _aide != null and Ui.in_rect(_aide.visual, q):
		_press["kind"] = "aide"
		_aide.down()
	return true


func pointer_up(p: Vector2) -> void:
	var pr := _press
	_press = {}
	if pr.is_empty():
		return
	var cr := card_rect()
	var q := p - Vector2(0, cr.position.y) - _card.position
	match String(pr.get("kind", "")):
		"chip":
			if Ui.in_rect(chip_hit(), p):
				_audio("uiClick")
				expand()
		"skip":
			skip_reading()
		"close":
			if Ui.in_rect(Rect2(CARD_X, 0, 88, 88), q):
				_audio("uiClick")
				collapse()
		"primary":
			var inside := Ui.in_rect(Rect2(CARD_X + 16, _btn_y, 416, 104), q)
			if _primary != null:
				_primary.up(inside)
			if inside:
				postpone()
		"testify":
			var inside2 := Ui.in_rect(Rect2(CARD_X + 448, _btn_y, 224, 104), q)
			if _testify != null:
				_testify.up(inside2)
			if inside2:
				_audio("uiClick")
				testify()
		"aide":
			if _aide != null:
				_aide.up(true)
			confirm_aide_drop()


## Test hook: the card-local button rects in `_lower` space.
func button_rect(which: String) -> Rect2:
	var top := L.tabs_y() - _card_h
	match which:
		"primary":
			return Rect2(CARD_X + 16, top + _btn_y, 416, 104)
		"testify":
			return Rect2(CARD_X + 448, top + _btn_y, 224, 104)
		"close":
			return Rect2(CARD_X, top, 88, 88)
	return Rect2()


func excuse_text() -> String:
	return _excuse.text if _excuse != null and is_instance_valid(_excuse) else ""


func stamp_visible() -> bool:
	return _stamp != null and is_instance_valid(_stamp) and _stamp.visible and _mode == "postponed"


# =============================================================================================
# The aide-drop confirm (rtl-map §7.1-7.2 ConfirmOverlay "aide-drop confirm"): a modal card with
# STACKED buttons (the labels don't fit two 224-px halves at ×4): commit on top, cancel below,
# focus on cancel, the backdrop does not close it. The body states the honest cost.
# =============================================================================================

class AideConfirm:
	extends Overlay
	var court: CourtView

	func build() -> AideConfirm:
		id = "AIDE_CONFIRM"
		backdrop_closes = false
		var th := Art.theme
		var body := Strings.s("AIDE_CONFIRM_BODY")
		var probe := PxText.make(panel, Vector2.ZERO, body, L.TEXT, "plain", "w")
		probe.wrap_width = 560.0
		probe.max_lines = 6
		var lines := maxf(1.0, float(probe.line_count()))
		probe.queue_free()
		var h := Ui.snap(104.0 + 44.0 * lines + 32.0 + 96.0 + 16.0 + 96.0 + 32.0, 4)
		var y := Ui.snap((L.H - h) / 2.0, 4)
		var pr := Rect2(48, y, 624, h)
		make_panel(pr)
		var title := text(Vector2(0, y + 32.0), Strings.s("AIDE_CONFIRM_TITLE"), L.TEXT, th["modal"]["title"])
		title.wrap_width = 432.0
		title.max_lines = 1
		title.center_in(pr.position.x + 96.0, 432.0)
		var bt := body_text(Vector2(0, y + 104.0), body, L.TEXT, th["modal"]["body"])
		bt.wrap_width = 560.0
		bt.max_lines = 6
		bt.right_at(pr.end.x - 32.0)
		var by := y + 104.0 + 44.0 * lines + 32.0
		button(Rect2(88, by, 544, 96), Rect2(88, by - 4.0, 544, 104), Strings.s("AIDE_CONFIRM_GO"), func() -> void:
			mgr.close(self, "confirm")
			court.drop_aide(), "kit_primary", L.TEXT)
		button(Rect2(88, by + 112.0, 544, 96), Rect2(88, by + 108.0, 544, 104), Strings.s("AIDE_CONFIRM_CANCEL"),
			func() -> void: cancel("close"), "kit_secondary", L.TEXT)
		focus_index = 1
		return self

	func default_focus() -> int:
		return 1

	func cancel(via: String) -> void:
		host.audio_event("panelClose")
		mgr.close(self, via)
