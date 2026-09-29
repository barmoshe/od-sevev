class_name Diorama
extends Node2D
## Stage background + diorama: sky bands, ground tiles, decorative palms and foliage, drifting
## clouds (object-motion §4), and the critter slots (hud-layout §5) with 2-frame idles, desync,
## wander hops, plops and Evolve poofs (object-motion §3). On tall and wide screens the sky and
## ground extend past the 720x1280 design area (extend()).

var reduced_motion := false
var ground_y := 0
var play_fx: Callable      # func(id: String, x: float, y: float)

var _critters: Array[Dictionary] = []
var _clouds: Array[Dictionary] = []
var _cloud_ms := 0.0
var _now := 0.0
var _last_hop := -99999.0
var _last_plop := -99999.0
var _plop_queue: Array[Dictionary] = []
var _frenzy := false
var _tap_frenzy := false
var _bg := Node2D.new()
var _env := Node2D.new()
var _back := Node2D.new()
var _front := Node2D.new()
var _extend_x := 0.0
var _extend_top := 0.0
var _sky: Array[ColorRect] = []
var _props := Node2D.new()
var _stars: Array[Dictionary] = []
var _era: Dictionary = {}
var _owned: Dictionary = {}
var _fx := Node2D.new()
var _pieces: Array[Dictionary] = []
var _ground_tiles: Array[Sprite2D] = []
var _built_h := -1.0
var _has_bg := false
## producer id -> ms to its next set piece (od-sevev: which producers have one is content data,
## producers[].setPiece; the first-run delays keep the fork's per-kind values).
var _piece_timers := {}
const PIECE_FIRST_MS := {"lob": 4000.0, "launch": 9000.0, "blink": 6000.0}


func _ready() -> void:
	add_child(_bg)
	add_child(_props)
	add_child(_env)
	add_child(_back)
	add_child(_front)
	add_child(_fx)
	_build_backdrop()
	var th: Array = L.DIORAMA["thresholds"]
	var slot_table := L.slot_table()
	for id in Content.producer_ids():
		var slots: Array = slot_table.get(id, [])
		if _sprite_of(id) == Art.PLACEHOLDER:
			continue   # no stage art for this source yet: an empty slot beats a "?" card on stage
		var piece := Tune.set_piece(id)
		if PIECE_FIRST_MS.has(piece):
			_piece_timers[id] = PIECE_FIRST_MS[piece]
		for slot in mini(slots.size(), th.size()):
			var slot_name: String = slots[slot]
			var row := slot_name.substr(0, 1)
			var x := float(L.DIORAMA["xs"][row][int(slot_name.substr(1))])
			var y := float(L.DIORAMA["rows"][row])
			var s := Sprite2D.new()
			s.texture = Art.tex(_sprite_of(id), 0)
			s.centered = false
			s.offset = _pivot_of(id)       # pivot bottom-centre of the critter
			s.scale = _scale_of(id)
			s.position = Vector2(x + 32, y + 64)
			s.visible = false
			(_front if row == "F" else _back).add_child(s)
			_critters.append(_critter(s, id, slot, int(th[slot]), x + 32, y + 64))
		_add_crowd(id, slots)


## v2 eras: recolours the sky and places the era's props (huts, towers, stars and a planet).
## od-sevev: eras[].props entries are data. A string is a fork prop id with the fork's placement
## (FORK_PROPS); an object places any sprite:
##   {"sprite": "prop_x", "xs": [60, 540], "anchor": "ground" | "sky", "dy": -56,
##    "scale": 4, "tint": "#d9d9f2", "scatter": 22, "twinkle": true, "hideClouds": true}
## `scatter` ignores xs and strews that many copies across the sky (seeded, the same every run);
## `twinkle` alternates frames 0 and 1. eras[].background (optional) is a full-stage art key
## drawn at x4 over the sky bands when Art has it (the 180x320 stage backgrounds).
const FORK_PROPS := {
	"prop_hut": {"sprite": "prop_hut", "xs": [60, 132, 540, 612], "anchor": "ground", "dy": -56},
	"prop_tower": {"sprite": "prop_tower", "xs": [96, 160, 520, 584], "anchor": "ground", "dy": -120, "tint": "#d9d9f2"},
	"prop_planet": {"sprite": "prop_planet", "xs": [520], "anchor": "sky", "dy": 40},
	"prop_star": {"sprite": "prop_star", "anchor": "sky", "scatter": 22, "twinkle": true, "hideClouds": true},
}


func set_era(era: Dictionary) -> void:
	if era.is_empty() or era.get("id", "") == _era.get("id", "-"):
		return
	_era = era
	var bands: Array = era.get("skyBands", [])
	for i in mini(bands.size(), _sky.size()):
		_sky[i].color = Color.html(bands[i])
	for c in _props.get_children():
		c.queue_free()
	_stars.clear()
	var specs: Array = []
	for p: Variant in era.get("props", []):
		if p is Dictionary:
			specs.append(p)
		elif FORK_PROPS.has(str(p)):
			specs.append(FORK_PROPS[str(p)])
	# the TA's manifest maps era ids to stage art (sprites.json stages); content may override
	var stage: Dictionary = SpriteStrip.manifest().get("stages", {}).get(String(era.get("id", "")), {})
	var bg_key := String(era.get("background", stage.get("sprite", "")))
	var has_bg := bg_key != "" and Art.has_sprite(bg_key)
	if has_bg and stage.has("padTop"):
		for r in _sky:
			r.color = Color.html(String(stage["padTop"]))   # the band above the art on tall screens
	var hide_clouds := has_bg
	for sp: Dictionary in specs:
		hide_clouds = hide_clouds or bool(sp.get("hideClouds", false))
	for cl in _clouds:
		(cl["img"] as Sprite2D).visible = not hide_clouds
	_env.visible = not has_bg   # the fork's palms and foliage belong to the jungle backdrop
	_has_bg = has_bg
	for t in _ground_tiles:
		t.visible = not has_bg
	# beyond the 180x320 art (wide or very tall screens): the stage's own pad colours
	RenderingServer.set_default_clear_color(Color.html(String(stage.get("padBottom", "#2a2340"))) if has_bg \
		else ProjectSettings.get_setting("rendering/environment/defaults/default_clear_color", Color(0.165, 0.137, 0.251)))
	if has_bg:
		# full-stage art at x4 (first child of _props: above the sky bands, under every prop),
		# placed so its magicianFeet slot (sprites.json, art px) lands on the Magician's feet
		var mf: Array = SpriteStrip.manifest().get("magicianFeet", [94, 219])
		var feet: Vector2 = L.magician_feet()
		var bg := Ui.img(_props, feet - Vector2(float(mf[0]), float(mf[1])) * 4.0, bg_key, 0, 4)
		bg.set_meta("background", true)
	for sp: Dictionary in specs:
		_place_prop(sp)


func _place_prop(sp: Dictionary) -> void:
	var key := Art.sprite_or(String(sp.get("sprite", "")))
	var sc := int(sp.get("scale", 4))
	var sy := float(L.STAGE["y"])
	var base_y := float(ground_y) if String(sp.get("anchor", "ground")) == "ground" else sy
	var dy := float(sp.get("dy", 0))
	var tint := Color.html(String(sp["tint"])) if sp.has("tint") else Color.WHITE
	if int(sp.get("scatter", 0)) > 0:
		var rng := RandomNumberGenerator.new()
		rng.seed = 67
		for i in int(sp["scatter"]):
			var p := Vector2(Ui.snap(rng.randf_range(-_extend_x, L.W + _extend_x - 16), 4), Ui.snap(rng.randf_range(sy - _extend_top, ground_y - 200), 4))
			var st := Ui.img(_props, p, key, rng.randi() % 2, sc)
			st.modulate = tint
			if bool(sp.get("twinkle", false)):
				_stars.append({"s": st, "key": key, "t": rng.randf_range(0, 800), "period": rng.randf_range(500, 1200)})
		return
	for x: Variant in sp.get("xs", []):
		var img := Ui.img(_props, Vector2(float(x), base_y + dy), key, 0, sc)
		img.modulate = tint


## v2 crowd: the troop visibly grows past v1's three critters per tier. Extra critters appear at
## CROWD_AT owned, placed with a per-tier seed so the crowd is the same every session.
const CROWD_AT := [50, 75, 100, 150, 200, 250]


func _add_crowd(id: String, slots: Array) -> void:
	var sky := String(slots[0]).begins_with("S") if not slots.is_empty() else false
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(id)
	for i in CROWD_AT.size():
		var x := Ui.snap(rng.randf_range(24, L.W - 88), 4)
		var y: float
		var front := rng.randf() < 0.5
		if sky:
			y = Ui.snap(rng.randf_range(float(L.DIORAMA["rows"]["S"]) + 8, float(L.DIORAMA["rows"]["S"]) + 120), 4)
			front = false
		else:
			y = float(L.DIORAMA["rows"]["F" if front else "B"]) + Ui.snap(rng.randf_range(-8, 8), 4)
		var s := Sprite2D.new()
		s.texture = Art.tex(_sprite_of(id), 0)
		s.centered = false
		s.offset = _pivot_of(id)
		s.scale = _scale_of(id)
		s.position = Vector2(x + 32, y + 64)
		s.visible = false
		(_front if front else _back).add_child(s)
		_critters.append(_critter(s, id, 3 + i, int(CROWD_AT[i]), x + 32, y + 64))


## The critter sprite of a producer: producers[].sprite, else "critter_<id>", else the neutral
## placeholder (a new id never crashes the stage while its art is pending).
static func _sprite_of(id: String) -> String:
	var src := Art.source(id)
	return Art.sprite_or(String(Content.producer(id).get("sprite", src.get("sprite", "critter_" + id))))


## Logical px per sprite px of a critter: ×4 art scale ÷ the TA's density (sprites.json
## sources[id].density, CONTRACT.md §3: the rendered sources are 3 sprite px per art px).
static func _scale_of(id: String) -> Vector2:
	var src := Art.source(id)
	var d := 1
	if not src.is_empty() and _sprite_of(id) == String(src.get("sprite", "")):
		d = maxi(1, int(src.get("density", 1)))
	return Vector2.ONE * (4.0 / d)


func _pivot_of(id: String) -> Vector2:
	var sz := Vector2(Art.tex(_sprite_of(id), 0).get_size())
	return Vector2(-floorf(sz.x / 2.0), -sz.y)


func _critter(s: Sprite2D, id: String, slot: int, th: int, x: float, y: float) -> Dictionary:
	return {"s": s, "type": id, "sprite": _sprite_of(id), "frameMs": Tune.critter_frame_ms(id), "wander": Tune.critter_wanders(id),
		"piece": Tune.set_piece(id), "slot": slot, "th": th, "homeX": x, "x": x, "y": y,
		"visible": false, "hopping": false, "nextHop": 0.0, "frame": 0, "frameT": 0.0, "rate": 1.0, "anim": false, "hop": {}}


## Rebuilds the sky and ground to cover `extend_x` px on each side and `extend_top` px above.
func extend(extend_x: float, extend_top: float) -> void:
	if is_equal_approx(extend_x, _extend_x) and is_equal_approx(extend_top, _extend_top) and is_equal_approx(L.stage_h, _built_h):
		return
	_built_h = L.stage_h
	_extend_x = extend_x
	_extend_top = extend_top
	for c in _bg.get_children():
		c.queue_free()
	for c in _env.get_children():
		c.queue_free()
	_clouds.clear()
	_build_backdrop()
	if not _era.is_empty():
		var e := _era
		_era = {}
		set_era(e)


func _build_backdrop() -> void:
	var sy := float(L.STAGE["y"])
	var sh := L.stage_h
	var bands: Array = Art.data["skyBands"]
	var x0 := -_extend_x
	var w := L.W + 2.0 * _extend_x
	_sky.clear()
	for i in bands.size():
		var b: Dictionary = bands[i]
		var y0 := sy + Ui.snap(float(b["from"]) * sh, 4)
		var y1 := sy + Ui.snap(float(b["to"]) * sh, 4)
		if i == 0:
			y0 -= _extend_top
		_sky.append(Ui.rect(_bg, Rect2(x0, y0, w, y1 - y0), Color.html(b["color"])))
	ground_y = int(sy + Ui.snap(float(bands[bands.size() - 1]["to"]) * sh, 4))
	var gx := floorf(x0 / 64.0) * 64.0
	_ground_tiles.clear()
	while gx < L.W + _extend_x:
		_ground_tiles.append(Ui.img(_bg, Vector2(gx, ground_y), "env_grass"))
		var y := ground_y + 64.0
		while y < sy + sh:
			_ground_tiles.append(Ui.img(_bg, Vector2(gx, y), "env_ground"))
			y += 64.0
		gx += 64.0
	# Decorative palms at the stage edges (no bananas: yellow means a producer or the hero).
	for px: float in [8.0, 648.0]:
		var y := float(ground_y) - 64.0
		while y >= ground_y - 64.0 * 3:
			Ui.img(_env, Vector2(px, y), "env_palm_trunk")
			y -= 64.0
		var crown := Ui.img(_env, Vector2.ZERO, "env_palm_crown")
		var cs := Vector2(Art.sprite_size("env_palm_crown")) * 4.0
		crown.position = Vector2(px + 32 - cs.x * 0.5, ground_y - 64 * 3 + 8 - cs.y * 0.56)
	for f: Array in [["env_foliage_b", 92], ["env_foliage_a", 236], ["env_foliage_a", 484], ["env_foliage_b", 580]]:
		var fs := Vector2(Art.sprite_size(f[0])) * 4.0
		Ui.img(_env, Vector2(float(f[1]) - fs.x / 2.0, ground_y + 8 - fs.y), f[0])
	for c: Vector2 in [Vector2(96, 184), Vector2(420, 236), Vector2(640, 196)]:
		var img := Ui.img(_bg, c, "env_cloud")
		_clouds.append({"img": img, "x": c.x})


## True while the era draws full-stage art (the title hides the fork's dirt under it).
func has_background() -> bool:
	return _has_bg


func _owned_of(owned: Dictionary, id: String) -> int:
	return int(owned.get(id, 0))


## Shows slot n of a tier when owned >= [1, 10, 25][n]. `animate` = a buy just happened.
func sync(owned: Dictionary, animate: bool) -> void:
	_owned = owned
	var shown: Array[Dictionary] = []
	for c in _critters:
		var want := _owned_of(owned, c["type"]) >= int(c["th"])
		if want and not c["visible"]:
			c["visible"] = true
			shown.append(c)
		elif not want and c["visible"]:
			c["visible"] = false
			c["anim"] = false
			(c["s"] as Sprite2D).visible = false
	if not animate:
		for c in shown:
			_show_idle(c)
		return
	for i in shown.size():
		var at := maxf(_now, _last_plop + float(Tune.MC["critterPlopThrottleMs"])) + i * float(Tune.MC["critterBulkStaggerMs"])
		_last_plop = at
		_plop_queue.append({"c": shown[i], "at": at, "phase": "wait", "t": 0.0})


## A buy past the diorama cap: a random critter of that type cheers in place.
func cheer(type: String) -> void:
	if reduced_motion:
		return
	var list := _critters.filter(func(c: Dictionary) -> bool: return c["type"] == type and c["visible"] and not c["hopping"])
	if list.is_empty():
		return
	var c: Dictionary = list[randi() % list.size()]
	c["hopping"] = true
	c["hop"] = {"kind": "cheer", "t": 0.0}


func _show_idle(c: Dictionary) -> void:
	var s: Sprite2D = c["s"]
	s.visible = true
	s.modulate.a = 1.0
	s.position = Vector2(c["x"], c["y"])
	if reduced_motion:
		c["anim"] = false
		Ui.set_frame(s, c["sprite"], 0)
		return
	c["anim"] = true
	c["frame"] = randi() % 2
	c["frameT"] = randf() * float(c["frameMs"])
	c["rate"] = randf_range(0.9, 1.1)
	c["nextHop"] = _now + _hop_interval()
	_face_banana(c)


func _hop_interval() -> float:
	var lo := float(Tune.MC["critterWanderMinMs"])
	var hi := float(Tune.MC["critterWanderMaxMs"])
	return randf_range(lo / 2.0, hi / 2.0) if _frenzy else randf_range(lo, hi)


func _face_banana(c: Dictionary) -> void:
	if not c["wander"]:
		return
	if _tap_frenzy and not reduced_motion:
		(c["s"] as Sprite2D).flip_h = float(c["x"]) > float(L.BB["pivotX"])


func set_frenzy(on: bool) -> void:
	_frenzy = on


func set_tap_frenzy(on: bool) -> void:
	_tap_frenzy = on
	for c in _critters:
		if c["visible"]:
			if on:
				_face_banana(c)
			else:
				(c["s"] as Sprite2D).flip_h = false


func set_reduced_motion(on: bool) -> void:
	reduced_motion = on
	for c in _critters:
		if c["visible"]:
			_show_idle(c)


## Evolve: every visible critter poofs (staggered 0-180 ms, shuffled), or fades (reduced motion).
func poof_all() -> void:
	var vis := _critters.filter(func(c: Dictionary) -> bool: return c["visible"])
	vis.shuffle()
	for i in vis.size():
		var c: Dictionary = vis[i]
		c["hop"] = {"kind": "poof", "t": 0.0, "delay": (i * 180.0) / maxf(vis.size() - 1, 1)}
		c["hopping"] = true


func clear_all() -> void:
	_plop_queue.clear()
	clear_pieces()
	for c in _critters:
		c["visible"] = false
		c["anim"] = false
		c["hopping"] = false
		c["hop"] = {}
		var s: Sprite2D = c["s"]
		s.visible = false
		s.modulate.a = 1.0


func update_view(dt_ms: float) -> void:
	_now += dt_ms
	if not reduced_motion:
		for st in _stars:
			st["t"] = float(st["t"]) + dt_ms
			if float(st["t"]) >= float(st["period"]):
				st["t"] = 0.0
				var sp: Sprite2D = st["s"]
				Ui.set_frame(sp, st["key"], 1 if sp.texture == Art.tex(st["key"], 0) else 0)
	_update_plops(dt_ms)
	_cloud_ms += dt_ms
	var step := float(Tune.MC["cloudStepMs"])
	while _cloud_ms >= step:
		_cloud_ms -= step
		for cl in _clouds:
			cl["x"] = float(cl["x"]) + float(Tune.MC["cloudStepPx"])
			if float(cl["x"]) > L.W + _extend_x:
				cl["x"] = -24.0 * 4.0 - _extend_x
			(cl["img"] as Sprite2D).position.x = cl["x"]
	for c in _critters:
		if not c["visible"] and (c["hop"] as Dictionary).get("kind", "") != "poof":
			continue
		_animate(c, dt_ms)
		_update_hop(c, dt_ms)
	if reduced_motion:
		return
	_update_set_pieces(dt_ms)
	for c in _critters:
		if not c["visible"] or c["hopping"] or not c["anim"] or not c["wander"] or _now < float(c["nextHop"]):
			continue
		if _now - _last_hop < float(Tune.MC["critterHopGlobalGapMs"]):
			c["nextHop"] = _now + float(Tune.MC["critterHopGlobalGapMs"])
			continue
		_last_hop = _now
		c["nextHop"] = _now + _hop_interval()
		_start_hop(c)


func _animate(c: Dictionary, dt_ms: float) -> void:
	if not c["anim"]:
		return
	c["frameT"] = float(c["frameT"]) + dt_ms * float(c["rate"]) * (2.0 if _frenzy else 1.0)
	var fm := float(c["frameMs"])
	if float(c["frameT"]) >= fm:
		c["frameT"] = float(c["frameT"]) - fm
		c["frame"] = 1 - int(c["frame"])
		c["rate"] = randf_range(0.85, 1.15)
	Ui.set_frame(c["s"], c["sprite"], c["frame"])


func _update_plops(dt_ms: float) -> void:
	for i in range(_plop_queue.size() - 1, -1, -1):
		var q: Dictionary = _plop_queue[i]
		var c: Dictionary = q["c"]
		var s: Sprite2D = c["s"]
		var key: String = c["sprite"]
		match q["phase"]:
			"wait":
				if q["at"] > _now:
					continue
				c["anim"] = false
				Ui.set_frame(s, key, 0)
				s.visible = true
				s.position = Vector2(c["x"], c["y"])
				if reduced_motion:
					s.modulate.a = 0.0
					q["phase"] = "fade"
				else:
					s.modulate.a = 1.0
					s.position.y = float(c["y"]) - float(Tune.MC["critterPlopFallPx"])
					q["phase"] = "fall"
				q["t"] = 0.0
			"fade":
				q["t"] = float(q["t"]) + dt_ms
				s.modulate.a = minf(1.0, float(q["t"]) / float(Tune.MC["critterReducedFadeMs"]))
				if s.modulate.a >= 1.0:
					_plop_queue.remove_at(i)
			"fall":
				q["t"] = float(q["t"]) + dt_ms
				var p := minf(1.0, float(q["t"]) / float(Tune.MC["critterPlopMs"]))
				s.position.y = float(c["y"]) - Ui.snap(float(Tune.MC["critterPlopFallPx"]) * (1.0 - Ui.quad_in(p)), 4)
				if p >= 1.0:
					s.position.y = c["y"]
					Ui.set_frame(s, key, 1)
					if play_fx.is_valid():
						play_fx.call("critterSpawnDust", c["x"], c["y"])
					q["phase"] = "land"
					q["t"] = 0.0
			"land":
				q["t"] = float(q["t"]) + dt_ms
				if float(q["t"]) >= float(Tune.MC["critterLandHoldMs"]):
					_plop_queue.remove_at(i)
					if c["visible"]:
						_show_idle(c)


func _start_hop(c: Dictionary) -> void:
	var opts := [-8.0, -4.0, 4.0, 8.0]
	var dx: float = opts[randi() % opts.size()]
	var lo := float(c["homeX"]) - 16.0
	var hi := float(c["homeX"]) + 16.0
	if float(c["x"]) + dx < lo or float(c["x"]) + dx > hi:
		dx = -dx
	if float(c["x"]) + dx < lo or float(c["x"]) + dx > hi:
		dx = 0.0
	c["hopping"] = true
	if dx != 0.0 and not _tap_frenzy:
		(c["s"] as Sprite2D).flip_h = dx < 0.0
	c["hop"] = {"kind": "hop", "t": 0.0, "x0": c["x"], "dx": dx}


func _update_hop(c: Dictionary, dt_ms: float) -> void:
	var h: Dictionary = c["hop"]
	if h.is_empty():
		return
	var s: Sprite2D = c["s"]
	h["t"] = float(h["t"]) + dt_ms
	var t: float = h["t"]
	match h["kind"]:
		"cheer":
			s.position.y = float(c["y"]) - 4.0 if t < 60.0 else float(c["y"])
			if t >= 120.0:
				c["hopping"] = false
				c["hop"] = {}
		"hop":
			var arc := [0, -4, -8, -8, -4, 0]
			var p := minf(1.0, t / float(Tune.MC["critterHopMs"]))
			var i := mini(arc.size() - 1, int(floorf(p * arc.size())))
			s.position = Vector2(Ui.snap(float(h["x0"]) + float(h["dx"]) * p, 4), float(c["y"]) + arc[i])
			if p >= 1.0:
				c["x"] = float(h["x0"]) + float(h["dx"])
				s.position = Vector2(c["x"], c["y"])
				c["hopping"] = false
				c["hop"] = {}
				_face_banana(c)
		"poof":
			if reduced_motion:
				s.modulate.a = maxf(0.0, 1.0 - t / float(Tune.MC["critterReducedFadeMs"]))
				if s.modulate.a <= 0.0:
					s.visible = false
					c["hop"] = {}
			elif t >= float(h["delay"]):
				s.visible = false
				if play_fx.is_valid():
					play_fx.call("evolvePoof", c["x"], float(c["y"]) - 32.0)
				c["hop"] = {}


# ------------------------------------------------------------------ v2 set pieces (object motion)
## Tier set pieces: catapults lob bananas across the sky, rockets launch, time chimps flicker and
## jump, moons bob. Each runs only when that tier is owned; reduced motion turns them all off.

func _update_set_pieces(dt_ms: float) -> void:
	for k: String in _piece_timers:
		if _owned_of(_owned, k) <= 0:
			continue
		_piece_timers[k] = float(_piece_timers[k]) - dt_ms
		if float(_piece_timers[k]) <= 0.0:
			_start_piece(k)
	for i in range(_pieces.size() - 1, -1, -1):
		var p: Dictionary = _pieces[i]
		p["t"] = float(p["t"]) + dt_ms
		var sp: Sprite2D = p["s"]
		var t := float(p["t"]) / float(p["dur"])
		match String(p["kind"]):
			"lob":
				var x := lerpf(float(p["x0"]), float(p["x1"]), t)
				var y := float(p["y0"]) - 4.0 * float(p["h"]) * t * (1.0 - t)
				sp.position = Vector2(Ui.snap(x, 4), Ui.snap(y, 4))
				sp.rotation = 0.0
			"launch":
				var e := t * t
				sp.position = Vector2(float(p["x0"]), Ui.snap(lerpf(float(p["y0"]), float(p["y1"]), e), 4))
		if t >= 1.0:
			sp.queue_free()
			_pieces.remove_at(i)
	var tsec := _now / 1000.0
	for c in _critters:
		if c["piece"] == "bob" and c["visible"] and not c["hopping"]:
			(c["s"] as Sprite2D).position.y = float(c["y"]) + Ui.snap(4.0 * sin(tsec * 1.3 + float(c["x"]) * 0.01), 4)


func _visible_of(type: String) -> Array:
	return _critters.filter(func(c: Dictionary) -> bool: return c["type"] == type and c["visible"])


func _start_piece(id: String) -> void:
	match Tune.set_piece(id):
		"lob":
			_piece_timers[id] = randf_range(5000, 9000)
			var cs := _visible_of(id)
			if cs.is_empty():
				return
			var c: Dictionary = cs[randi() % cs.size()]
			var right := float(c["x"]) < L.W / 2.0
			var b := Ui.img(_fx, Vector2(c["x"], float(c["y"]) - 48), Art.sprite_or("icon_" + String(Content.data()["currency"].get("icon", ""))), 0, 4)
			_pieces.append({"kind": "lob", "s": b, "t": 0.0, "dur": 1400.0, "x0": c["x"], "y0": float(c["y"]) - 48.0,
				"x1": (L.W + 80.0) if right else -120.0, "h": 260.0})
		"launch":
			_piece_timers[id] = randf_range(10000, 16000)
			var x := Ui.snap(randf_range(40, L.W - 104), 4)
			var r := Ui.img(_fx, Vector2(x, ground_y - 64), _sprite_of(id), 0, 4)
			r.scale = _scale_of(id)
			if play_fx.is_valid():
				play_fx.call("critterSpawnDust", x + 32.0, float(ground_y))
			_pieces.append({"kind": "launch", "s": r, "t": 0.0, "dur": 1600.0, "x0": x, "y0": float(ground_y) - 64.0,
				"y1": float(L.STAGE["y"]) - _extend_top - 140.0})
		"blink":
			_piece_timers[id] = randf_range(7000, 12000)
			var ts := _visible_of(id)
			if ts.is_empty():
				return
			var c2: Dictionary = ts[randi() % ts.size()]
			if c2["hopping"]:
				return
			c2["hopping"] = true
			var sp2: Sprite2D = c2["s"]
			var tw := create_tween()
			for i in 6:
				tw.tween_callback(func() -> void: sp2.visible = not sp2.visible)
				tw.tween_interval(0.06)
			tw.tween_callback(func() -> void:
				c2["x"] = clampf(float(c2["homeX"]) + randf_range(-40, 40), 40.0, L.W - 40.0)
				sp2.position.x = Ui.snap(float(c2["x"]), 4)
				sp2.visible = c2["visible"]
				c2["hopping"] = false)


func clear_pieces() -> void:
	for p in _pieces:
		(p["s"] as Sprite2D).queue_free()
	_pieces.clear()
