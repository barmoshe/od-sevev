class_name Floaters
extends Node2D
## Pooled "+N" floaters: motion-spec tap-floater / crit-floater, feel-spec §1. Pool size =
## floaterMaxConcurrent (the oldest is recycled). Reduced motion caps them at 8 and makes them static.

const REDUCED_MAX := 8
const REDUCED_FADE_MS := 500.0
const REDUCED_CRIT_FADE_MS := 700.0

var reduced_motion := false
var _pool: Array[Dictionary] = []
var _serial := 0


func _ready() -> void:
	for i in int(Tune.T["floaterMaxConcurrent"]):
		var t := PxText.new()
		t.variant = "outline"
		t.px = 4
		t.visible = false
		add_child(t)
		_pool.append({"obj": t, "active": false, "born": 0, "t": 0.0, "crit": false, "big": false, "x": 0.0, "y0": 0.0, "reduced": false})


func spawn(x: float, y: float, text: String, crit: bool, tap_frenzy: bool) -> void:
	var cap := mini(REDUCED_MAX, _pool.size()) if reduced_motion else _pool.size()
	var actives := _pool.filter(func(f: Dictionary) -> bool: return f["active"])
	var f: Dictionary = {}
	for p in _pool:
		if not p["active"]:
			f = p
			break
	if actives.size() >= cap or f.is_empty():
		actives.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["born"]) < int(b["born"]))
		f = actives[0]
	var c: Dictionary = L.floater_clamp()
	var jitter := randf_range(-1.0, 1.0) * float(Tune.T["floaterJitterXPx"])
	f["active"] = true
	f["born"] = _serial
	_serial += 1
	f["t"] = 0.0
	f["crit"] = crit
	f["big"] = tap_frenzy and not crit
	f["reduced"] = reduced_motion
	f["x"] = clampf(x + jitter, float(c["x0"]), float(c["x1"]))
	f["y0"] = clampf(y, float(c["y0"]), float(c["y1"]))
	var o: PxText = f["obj"]
	o.variant = "crit" if (crit or tap_frenzy) else "outline"
	o.text = text
	o.visible = true
	o.modulate.a = 1.0
	_layout(f, _base_scale(f), 0.0)


func _base_scale(f: Dictionary) -> int:
	var h := float(Tune.T["critFloaterTextHeightPx"] if (f["crit"] or f["big"]) else Tune.T["floaterTextHeightPx"])
	return int(roundf(h / 7.0))


## Places the glyph box centred at (x, y0 − rise), snapped to its own texel size.
func _layout(f: Dictionary, sc: int, rise: float) -> void:
	var o: PxText = f["obj"]
	o.px = sc
	var w := float(o.width())
	var h := 7.0 * sc
	var g := float(_base_scale(f) if f["crit"] else sc)
	o.position = Vector2(Ui.snap(float(f["x"]) - w / 2.0, g), Ui.snap(float(f["y0"]) - h / 2.0 - rise, g))


func update_view(dt_ms: float) -> void:
	for f in _pool:
		if not f["active"]:
			continue
		f["t"] = float(f["t"]) + dt_ms
		var t: float = f["t"]
		var o: PxText = f["obj"]
		var base := _base_scale(f)
		if f["reduced"]:
			var dur := REDUCED_CRIT_FADE_MS if f["crit"] else REDUCED_FADE_MS
			o.modulate.a = maxf(0.0, 1.0 - t / dur)
			if t >= dur:
				_kill(f)
			continue
		if f["crit"]:
			var dur := float(Tune.T["critFloaterRiseMs"])
			var pop := minf(1.0, t / float(Tune.T["critFloaterPopMs"]))
			var ps := float(Tune.T["critFloaterPopScale"])
			var drv := ps + (1.0 - ps) * Ui.quad_out(pop)
			_layout(f, int(roundf(drv * base)), float(Tune.T["critFloaterRisePx"]) * Ui.cubic_out(minf(1.0, t / dur)))
			var fade_start := dur - 300.0
			o.modulate.a = 1.0 if t < fade_start else maxf(0.0, 1.0 - (t - fade_start) / 300.0)
			if t >= dur:
				_kill(f)
		else:
			var dur := float(Tune.T["floaterRiseMs"])
			_layout(f, base, float(Tune.T["floaterRisePx"]) * Ui.cubic_out(minf(1.0, t / dur)))
			var fs := float(Tune.T["floaterFadeStartMs"])
			o.modulate.a = 1.0 if t < fs else maxf(0.0, 1.0 - (t - fs) / (dur - fs))
			if t >= dur:
				_kill(f)


func _kill(f: Dictionary) -> void:
	f["active"] = false
	(f["obj"] as PxText).visible = false


func clear() -> void:
	for f in _pool:
		_kill(f)
