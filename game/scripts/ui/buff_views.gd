class_name BuffViews
extends Node2D
## Buff chip, banner and Frenzy edge glow (feel-spec §2, motion-spec buff-banner / buff-presence).

const CHIP_SCALE := 3

var reduced_motion := false
var _chip_bg: NinePatchRect
var _chip_text: PxText
var _chip_track: ColorRect
var _chip_top: ColorRect
var _chip_bot: ColorRect
var _banner := Node2D.new()
var _banner_frame: NinePatchRect
var _banner_text: PxText
var _banner_t := -1.0
var _banner_drop: Array = []
var _edges: Array[ColorRect] = []
var _edge_alpha := 0.0
var _edge_tw: Tween
var _frenzy_on := false
var _stage_h := 504.0


func _ready() -> void:
	var th := Art.theme
	var C: Dictionary = th["buffChip"]
	_chip_bg = Ui.nine(self, L.BUFF["chip"], C["sprite"], int(C["frame"]))
	_chip_text = PxText.make(self, L.BUFF["chipText"], "", CHIP_SCALE, "plain", C["text"])
	var bar: Rect2 = L.BUFF["chipBar"]
	_chip_track = Ui.rect(self, bar, C["barTrack"])
	_chip_top = Ui.rect(self, Rect2(bar.position, Vector2(bar.size.x, bar.size.y / 2)), C["barFillTop"])
	_chip_bot = Ui.rect(self, Rect2(bar.position + Vector2(0, bar.size.y / 2), Vector2(bar.size.x, bar.size.y / 2)), C["barFillBottom"])
	_set_chip_visible(false)
	add_child(_banner)
	_banner.visible = false
	_banner_frame = Ui.nine(_banner, L.BUFF["banner"], th["banner"]["sprite"], int(th["banner"]["frame"]))
	_banner_text = PxText.make(_banner, Vector2((L.BUFF["banner"] as Rect2).position.x, L.BUFF["bannerTextY"]), "", 4, "plain", th["banner"]["text"])
	var B := float(Tune.MC["bannerEnterOffsetPx"])
	var SQ := float(Tune.MC["squishPx"])
	_banner_drop = [[-B, 0, 0], [-B, 0, 0], [-B * 3 / 4, 0, 0], [-B / 2, 0, 0],
		[0, 2 * SQ, -SQ], [0, 2 * SQ, -SQ], [-B / 4, -SQ, SQ / 2], [-B / 4, 0, 0], [0, 0, 0]]
	for i in 4:
		_edges.append(Ui.rect(self, Rect2(), th["frenzyEdgeGlow"], 0.0))
	set_stage_rect(-0.0, float(L.STAGE["y"]), float(L.W), L.stage_h)


## The Frenzy edge glow frames the (possibly grown) stage.
func set_stage_rect(x: float, y: float, w: float, h: float) -> void:
	var band := 8.0
	var rects := [Rect2(x, y, w, band), Rect2(x, y + h - band, w, band), Rect2(x, y, band, h), Rect2(x + w - band, y, band, h)]
	for i in 4:
		_edges[i].position = rects[i].position
		_edges[i].size = rects[i].size


func _set_chip_visible(v: bool) -> void:
	for o: CanvasItem in [_chip_bg, _chip_text, _chip_track, _chip_top, _chip_bot]:
		o.visible = v


## One chip (buffs never overlap, E5). remaining in seconds. A Suitcase frenzy wins; otherwise
## the live timed spin that ends first (Spins.active_effects: motion-spec buff-presence "only for
## timed spins": the timer bar and the last-3 s blink).
func update_chip(frenzy: float, tap_frenzy: float, stage_visible: bool, spins: Array = []) -> void:
	var kind := "tapFrenzy" if tap_frenzy > 0.0 else ("frenzy" if frenzy > 0.0 else "")
	var spin := first_spin(spins) if kind == "" else {}
	if (kind == "" and spin.is_empty()) or not stage_visible:
		_set_chip_visible(false)
		return
	_set_chip_visible(true)
	var rem: float
	var total: float
	if kind == "":
		rem = float(spin["leftSec"])
		total = maxf(1e-3, float(spin.get("durationSec", rem)))
		_chip_text.text = spin_chip_text(String(spin["id"]), rem, (L.BUFF["chipBar"] as Rect2).size.x)
	else:
		var o := Content.outcome_of_type("bpsFrenzy" if kind == "frenzy" else "tapFrenzy")
		rem = frenzy if kind == "frenzy" else tap_frenzy
		total = float(o.get("durationSec", 1))
		_chip_text.text = Strings.s("BUFF_CHIP_FRENZY" if kind == "frenzy" else "BUFF_CHIP_TAPFRENZY",
			{"mult": int(o.get("mult", 1)), "s": Fmt.secs(rem).replace("S", "")})
	var bar: Rect2 = L.BUFF["chipBar"]
	var w := Ui.snap(bar.size.x * minf(1.0, rem / total), 4)
	_chip_top.size.x = w
	_chip_bot.size.x = w
	# RTL: the bar drains toward the right edge (ux/first-minute.md §3.5 "Bars fill from the right")
	_chip_top.position.x = L.bar_x(bar, w)
	_chip_bot.position.x = _chip_top.position.x
	var a := 1.0
	if rem * 1000.0 <= float(Tune.MC["buffEndWarnMs"]):
		var half := 1000.0 / (2.0 * float(Tune.MC["buffEndBlinkHz"]))
		a = 1.0 if int(floorf(rem * 1000.0 / half)) % 2 == 0 else 0.4
	_chip_top.modulate.a = a
	_chip_bot.modulate.a = a


## The live spin that ends first ({} when none).
static func first_spin(spins: Array) -> Dictionary:
	var out: Dictionary = {}
	for a: Variant in spins:
		if a is Dictionary and float((a as Dictionary).get("leftSec", 0.0)) > 0.0:
			if out.is_empty() or float(a["leftSec"]) < float(out["leftSec"]):
				out = a
	return out


## "{name} · SPIN_ACTIVE" when it fits the chip's text box at the chip scale, else SPIN_ACTIVE alone.
static func spin_chip_text(id: String, left_sec: float, box_w: float) -> String:
	var active := Strings.s("SPIN_ACTIVE", {"s": Fmt.secs(left_sec).replace("S", "")})
	var full := Strings.upgrade_name(id) + " · " + active
	return full if PxText.measure(full, CHIP_SCALE) <= box_w else active


## buff-banner: enter, hold, exit. J6 enter falls from above and lands with a squash.
func show_banner(text: String) -> void:
	var nb: Rect2 = L.BUFF["banner"]
	_banner_text.text = text
	_banner_text.position.x = 4.0 * floorf((nb.size.x - _banner_text.width()) / 2.0 / 4.0) + nb.position.x
	_banner.visible = true
	_banner.modulate.a = 0.0
	_banner_t = 0.0


func set_frenzy(on: bool) -> void:
	if _frenzy_on == on:
		return
	_frenzy_on = on
	if _edge_tw:
		_edge_tw.kill()
	if on:
		if reduced_motion:
			_edge_alpha = 0.5
			return
		_edge_alpha = 0.2
		var half := 1.0 / (2.0 * float(Tune.T["frenzyEdgePulseHz"]))
		_edge_tw = create_tween().set_loops()
		_edge_tw.tween_property(self, "_edge_alpha", 0.6, half).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_edge_tw.tween_property(self, "_edge_alpha", 0.2, half).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	else:
		_edge_tw = create_tween()
		_edge_tw.tween_property(self, "_edge_alpha", 0.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


func set_reduced_motion(on: bool) -> void:
	reduced_motion = on
	if _frenzy_on:
		_frenzy_on = false
		set_frenzy(true)


func update_view(dt_ms: float, stage_visible: bool) -> void:
	for e in _edges:
		e.modulate.a = _edge_alpha if stage_visible else 0.0
	if _banner_t < 0.0:
		return
	_banner_t += dt_ms
	var t := _banner_t
	var fade := float(Tune.T["buffBannerFadeMs"])
	var hold := float(Tune.T["buffBannerHoldMs"])
	var nb: Rect2 = L.BUFF["banner"]
	var a := 1.0
	var d := [0.0, 0.0, 0.0]
	if t < fade:
		if reduced_motion:
			var p := t / fade
			a = 1.0 - (1.0 - p) * (1.0 - p)
		else:
			var p2 := minf(1.0, t / 100.0)
			a = 1.0 - (1.0 - p2) * (1.0 - p2)
			d = Juice.sample(_banner_drop, t)
	elif t < fade + hold:
		a = 1.0
	elif t < fade * 2.0 + hold:
		var p3 := (t - fade - hold) / fade
		a = 1.0 - p3 * p3
		d = [0.0 if reduced_motion else -8.0 * p3 * p3, 0.0, 0.0]
	else:
		_banner_t = -1.0
		_banner.visible = false
		PxButton.squish_nine(_banner_frame, nb, 0, 0)
		return
	_banner.modulate.a = a
	_banner.position.y = Ui.snap(float(d[0]), 4)
	PxButton.squish_nine(_banner_frame, nb, float(d[1]), float(d[2]))


func clear() -> void:
	_set_chip_visible(false)
	_banner_t = -1.0
	_banner.visible = false
	PxButton.squish_nine(_banner_frame, L.BUFF["banner"], 0, 0)
	if _edge_tw:
		_edge_tw.kill()
	_edge_alpha = 0.0
	_frenzy_on = false
