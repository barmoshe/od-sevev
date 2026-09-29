class_name FxPlayer
extends Node2D
## Plays the FX in pipeline/fx-data.json (exported into art.json): pooled pixel particles snapped
## to their grid, and flipbooks. Like v1's reference player it never fires audio or shake; those
## stay on the gameplay event wiring, so nothing double-fires.
## Particle model (Phaser semantics): angle in degrees (0 = right, 90 = down), speed px/s,
## gravityY px/s², alpha interpolated through `values` over the particle's life.

const POOL := 160

var reduced_motion := false
var _fx: Dictionary = {}
var _parts: Array[Dictionary] = []
var _flips: Array[Dictionary] = []
var _pending: Array[Dictionary] = []     # delayed emitter bursts


func _ready() -> void:
	for fx: Dictionary in Art.data["fx"]["fx"]:
		_fx[fx["id"]] = fx
	for i in POOL:
		var s := Sprite2D.new()
		s.centered = true
		s.visible = false
		add_child(s)
		_parts.append({"s": s, "alive": false})


func has_fx(id: String) -> bool:
	return _fx.has(id)


func play(id: String, x: float, y: float, variant: String = "") -> void:
	var fx: Dictionary = _fx.get(id, {})
	if fx.is_empty():
		push_warning("[fx] unknown fx %s" % id)
		return
	for def: Dictionary in fx["emitters"]:
		var count := _count(fx, def, variant)
		if count <= 0:
			continue
		var delay := float(def.get("delayMs", 0))
		if delay > 0.0:
			_pending.append({"def": def, "count": count, "x": x, "y": y, "wait": delay})
		else:
			_burst(def, count, x, y)
	for fb: Dictionary in fx.get("flipbooks", []):
		if reduced_motion and fb.get("reducedMotion", {}).get("disabled", false):
			continue
		_play_flip(fb, x, y)


func _count(fx: Dictionary, def: Dictionary, variant: String) -> int:
	var count := float(def["count"])
	var b: Dictionary = def.get("bindings", {})
	if b.has("count") and Tune.T.has(b["count"]):
		count = float(Tune.T[b["count"]])
	if variant != "":
		var v: Dictionary = fx.get("variants", {}).get(variant, {}).get("emitters", {}).get(def["name"], {})
		if v.has("count"):
			count = float(v["count"])
	var rm: Dictionary = def.get("reducedMotion", {})
	if reduced_motion and not rm.is_empty():
		if rm.get("disabled", false):
			return 0
		var f: Variant = rm.get("countFactor", 0.5)
		var factor := float(Tune.T.get(f, 0.5)) if f is String else float(f)
		count = maxf(1.0, roundf(count * factor))
	return int(roundf(count))


func _bound(def: Dictionary, field: String) -> Variant:
	var cfg: Dictionary = def["config"]
	var b: Dictionary = def.get("bindings", {})
	var v: Variant = cfg.get(field)
	if b.has(field) and Tune.T.has(b[field]):
		v = float(Tune.T[b[field]])
	var sp: Dictionary = def.get("spread", {})
	if sp.has(field) and (v is float or v is int):
		v = {"min": float(v) * (1.0 - float(sp[field])), "max": float(v) * (1.0 + float(sp[field]))}
	return v


func _range(v: Variant, dflt: float = 0.0) -> float:
	if v is Dictionary:
		return randf_range(float(v["min"]), float(v["max"]))
	if v is float or v is int:
		return float(v)
	return dflt


func _burst(def: Dictionary, count: int, x: float, y: float) -> void:
	var cfg: Dictionary = def["config"]
	var angle: Variant = cfg.get("angle", {"min": 0, "max": 360})
	if def.has("arc"):
		var arc: Dictionary = def["arc"]
		var w := float(arc["widthDeg"])
		if arc.has("widthParam") and Tune.T.has(arc["widthParam"]):
			w = float(Tune.T[arc["widthParam"]])
		angle = {"min": float(arc["centerDeg"]) - w / 2.0, "max": float(arc["centerDeg"]) + w / 2.0}
	var frames: Array = cfg.get("frame", [])
	var tints: Array = def.get("tintChars", [])
	for i in count:
		var p := _free()
		if p.is_empty():
			return
		var fr: String = frames[randi() % frames.size()] if frames.size() > 0 else "fx_px/0"
		var parts := fr.split("/")
		var s: Sprite2D = p["s"]
		s.texture = Art.tex(parts[0], int(parts[1]) if parts.size() > 1 else 0)
		var sc := float(cfg.get("scale", 4))
		s.scale = Vector2(sc, sc)
		s.modulate = Art.col(tints[randi() % tints.size()]) if tints.size() > 0 else Color.WHITE
		s.visible = true
		var a := deg_to_rad(_range(angle))
		var spd := _range(_bound(def, "speed"))
		p["alive"] = true
		p["x"] = x
		p["y"] = y
		p["vx"] = cos(a) * spd
		p["vy"] = sin(a) * spd
		p["g"] = float(_range(_bound(def, "gravityY")))
		p["life"] = maxf(1.0, _range(_bound(def, "lifespan"), 400.0))
		p["t"] = 0.0
		p["snap"] = float(def.get("pixelSnap", 4))
		p["alpha"] = cfg.get("alpha", {"values": [1, 0]}).get("values", [1, 0])
		_place(p)


func _free() -> Dictionary:
	for p in _parts:
		if not p["alive"]:
			return p
	return {}


func _place(p: Dictionary) -> void:
	var s: Sprite2D = p["s"]
	var g: float = p["snap"]
	var half := s.texture.get_size() * s.scale / 2.0
	s.position = Vector2(roundf((float(p["x"]) - half.x) / g) * g + half.x, roundf((float(p["y"]) - half.y) / g) * g + half.y)
	var vals: Array = p["alpha"]
	var k := clampf(float(p["t"]) / float(p["life"]), 0.0, 1.0) * (vals.size() - 1)
	var i := mini(int(k), vals.size() - 2)
	s.modulate.a = lerpf(float(vals[i]), float(vals[i + 1]), k - i) if vals.size() > 1 else float(vals[0])


func _play_flip(fb: Dictionary, x: float, y: float) -> void:
	var s: Sprite2D = null
	for f in _flips:
		if not (f["s"] as Sprite2D).visible:
			s = f["s"]
			break
	if s == null:
		s = Sprite2D.new()
		add_child(s)
		_flips.append({"s": s})
	var rec: Dictionary = {}
	for f in _flips:
		if f["s"] == s:
			rec = f
	var sc := float(fb.get("scale", 4))
	s.scale = Vector2(sc, sc)
	s.texture = Art.tex(fb["sprite"], 0)
	var half := s.texture.get_size() * sc / 2.0
	var g := float(fb.get("pixelSnap", 4))
	s.position = Vector2(roundf((x - half.x) / g) * g + half.x, roundf((y - half.y) / g) * g + half.y)
	s.visible = true
	rec["t"] = 0.0
	rec["id"] = fb["sprite"]
	rec["ms"] = float(fb.get("frameMs", 60))


func update_view(dt_ms: float) -> void:
	for i in range(_pending.size() - 1, -1, -1):
		var q: Dictionary = _pending[i]
		q["wait"] = float(q["wait"]) - dt_ms
		if float(q["wait"]) <= 0.0:
			_pending.remove_at(i)
			_burst(q["def"], q["count"], q["x"], q["y"])
	var dt := dt_ms / 1000.0
	for p in _parts:
		if not p["alive"]:
			continue
		p["t"] = float(p["t"]) + dt_ms
		if float(p["t"]) >= float(p["life"]):
			p["alive"] = false
			(p["s"] as Sprite2D).visible = false
			continue
		p["vy"] = float(p["vy"]) + float(p["g"]) * dt
		p["x"] = float(p["x"]) + float(p["vx"]) * dt
		p["y"] = float(p["y"]) + float(p["vy"]) * dt
		_place(p)
	for f in _flips:
		var s: Sprite2D = f["s"]
		if not s.visible:
			continue
		f["t"] = float(f["t"]) + dt_ms
		var n := Art.frame_count(f["id"])
		var k := int(float(f["t"]) / float(f["ms"]))
		if k >= n:
			s.visible = false
		else:
			s.texture = Art.tex(f["id"], k)


func clear() -> void:
	_pending.clear()
	for p in _parts:
		p["alive"] = false
		(p["s"] as Sprite2D).visible = false
	for f in _flips:
		(f["s"] as Sprite2D).visible = false
