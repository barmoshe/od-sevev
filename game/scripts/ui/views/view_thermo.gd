class_name Thermo
extends Node2D
## The suspicion thermometer "חשד" on the stage (ux/rtl-map.md §4 "Thermometer", motion-spec
## suspicion-thermometer) and the Magician's sweat (motion/state-graph-magician.md §8
## magician-sweat). A child of `_stage` drawn just above the Magician, so stage-local design y
## STAGE.y (160) is the stage top and every rtl-map value "S − n" is `_sy(−n)` here.
##
## A VIEW of `Investigation.suspicion(s)` (0..100), `Investigation.floor_pct(s)` (the hatched
## floor carried over from earlier rounds) and `state.investigation.revealed` (K1). No rule lives
## here. Geometry is the kit's: thermo_tube (14×88 art, pivot [6, 87], liquid column
## `liquid {x, w, yTop, yBottom}`, y_top(p) = yBottom − round(p × (yBottom − yTop))), read from
## the manifest, never copied. When S < 560 the kit's thermo_tube_short (14×58) replaces it
## (rtl-map §4); the icon keeps its 52-px gap above the tube top and the hit runs from the icon
## to the bulb, so the full tube's numbers (icon S−544, hit S−544…S−140) fall out unchanged.
##
## - Fill: bottom → up (`keep`, never mirrored); the floor is thermo_floor_hatch tiled from the
##   bottom to y_top(floor), the live part thermo_fill above it, thermo_meniscus on the surface.
##   A change animates over 300 ms Quad.Out, snapped to art rows (reduced motion: a cut).
## - ≥ 75 %: the state word HUD_SUSP_HOT, the icon swaps magnifier → gavel (a cut + a 1-ap hop),
##   3 bubbles rise 8 ap over 900 ms, staggered 300 ms; ≥ 95 %: HUD_SUSP_BOIL, 450 ms.
##   Reduced motion: one static bubble (the kit's frame 2).
## - Opacity 100 % for 3 s after a visible change and always at ≥ 75 %, else 60 % (200 ms fades).
## - Reveal (K1): slides in from the left edge, 280 ms Back.Out, then one fill tick from 0.
## - Hit Rect2(12, S−544, 120, 404): tap → T4 (the controller routes it).
## - Sweat: sweat_drop placed with its pivot on Bibi's per-frame `temple` landmark
##   (SpriteStrip.point, so artScale / density come from the manifest). nervous 75-94 %: a drop
##   every U(1400, 1800) ms, max 2; boiling ≥ 95 %: every U(700, 900) ms alternating temple and
##   temple + (−2, +1) ap, max 3. A drop sits 200 ms, slides 3 ap (300 ms Quad.In, tracking the
##   face), detaches and falls 12 ap (250 ms Quad.In, fading its last 100 ms). New drops only
##   while the body is idle; leaving idle detaches every attached drop at once. The summons gulp:
##   2 drops at once. Reduced motion: one static bead at the temple while ≥ 75 %.

const HOT := 75.0
const BOIL := 95.0
const TUBE_X := 44.0
const TUBE_BOTTOM := -140.0          # S − 140
const ICON_GAP := 52.0               # icon top above the tube top (S − 544 on the full tube)
const SHORT_BELOW := 560.0           # rtl-map §4: thermo_tube_short when S < 560
const WORD_Y := -136.0               # S − 136
const WORD_BOX := Vector2(12, 120)   # x 12-132
const HIT_X := Vector2(12, 120)      # hit x 12, w 120; y from the icon top to the bulb (S − 140)
const FILL_MS := 300.0
const REVEAL_MS := 280.0
const BRIGHT_MS := 3000.0
const AP := 4.0                      # one art px in logical px (the kit's ×4)

var host: Node
var bb: BigBanana
var reduced_motion := false

var _state: GameState
var _known_state: GameState
var _now := 0.0
var _root := Node2D.new()
var _tube: Sprite2D
var _hatch: TextureRect
var _fill: Sprite2D
var _men: Sprite2D
var _icon: Sprite2D
var _word: PxText
var _bubbles: Array[Sprite2D] = []
var _liquid := {"x": 5, "w": 4, "yTop": 3, "yBottom": 73}
var _pivot := Vector2(6, 87)

var _shown := false
var _reveal_t := -1.0
var _rows := 0.0                     # displayed live-fill top, in art rows above the bottom
var _from_rows := 0.0
var _to_rows := -1.0
var _fill_t := -1.0
var _bright_until := -1e9
var _alpha := 0.6
var _hot_icon := false
var _hot_seen := false               # the first state update is a restore, not a crossing (no cue)
var _hop_t := -1.0
var _word_key := ""

# sweat
var _drops_root := Node2D.new()
var _drops: Array[Dictionary] = []   # {spr, t, off, attached, from (Vector2, when detached), td}
var _next_drop := 0.0
var _alt := false
var _bead: Sprite2D                  # reduced motion's static bead
var _body_idle := true


func setup(host_: Node, bb_: BigBanana) -> Thermo:
	host = host_
	bb = bb_
	return self


static func state_of(p: float) -> String:
	return "boil" if p >= BOIL else ("hot" if p >= HOT else "calm")


static func word_key(p: float) -> String:
	return {"boil": "HUD_SUSP_BOIL", "hot": "HUD_SUSP_HOT", "calm": "HUD_SUSP"}[state_of(p)]


## The tube piece for a stage height: the kit's short tube under 560 px when it exists, else the full one.
static func tube_id_for(stage_h: float) -> String:
	if stage_h < SHORT_BELOW and Art.has_sprite("thermo_tube_short"):
		return "thermo_tube_short"
	return Art.sprite_or("thermo_tube")


## Swaps the tube piece and reads its liquid box and pivot; the drawn fill keeps its percentage.
func _apply_tube(id: String) -> void:
	var old_travel := float(int(_liquid["yBottom"]) - int(_liquid["yTop"]))
	var k := Art.kit(id)
	if k.get("liquid") is Dictionary:
		_liquid = k["liquid"]
	if k.get("pivot") is Array:
		_pivot = Vector2(float(k["pivot"][0]), float(k["pivot"][1]))
	var f := float(int(_liquid["yBottom"]) - int(_liquid["yTop"])) / maxf(1.0, old_travel)
	_rows = roundf(_rows * f)
	_from_rows = roundf(_from_rows * f)
	if _to_rows >= 0.0:
		_to_rows = roundf(_to_rows * f)
	_tube.texture = Art.tex(id, 0)
	_tube.set_meta("sprite", id)


func tube_id() -> String:
	return str(_tube.get_meta("sprite"))


func _ready() -> void:
	add_child(_root)
	_tube = Ui.img(_root, Vector2.ZERO, Art.sprite_or("thermo_tube"), 0, 4)
	_apply_tube(tube_id_for(L.stage_h))
	_hatch = TextureRect.new()
	_hatch.texture = Art.tex(Art.sprite_or("thermo_floor_hatch"))
	_hatch.stretch_mode = TextureRect.STRETCH_TILE
	_hatch.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_hatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hatch.scale = Vector2(AP, AP)
	_root.add_child(_hatch)
	_fill = Ui.img(_root, Vector2.ZERO, Art.sprite_or("thermo_fill"), 0, 4)
	_men = Ui.img(_root, Vector2.ZERO, Art.sprite_or("thermo_meniscus"), 0, 4)
	for i in 3:
		var b := Ui.img(_root, Vector2.ZERO, Art.sprite_or("thermo_bubble"), 0, 4)
		b.visible = false
		_bubbles.append(b)
	_icon = Ui.img(_root, Vector2.ZERO, Art.sprite_or("thermo_icon_magnifier"), 0, 4)
	_word = PxText.make(_root, Vector2.ZERO, Strings.s("HUD_SUSP"), L.TEXT, "plain", "w")
	_word.wrap_width = WORD_BOX.y
	_word.max_lines = 1
	_root.visible = false
	_drops_root.name = "SweatDrops"
	if bb != null and bb.hero != null:
		bb.body.add_child(_drops_root)   # after the hero: the drops draw in front of his face
	else:
		add_child(_drops_root)
	_bead = Ui.img(_drops_root, Vector2.ZERO, Art.sprite_or("sweat_drop"), 0, 4)
	_bead.visible = false
	relayout()


## Stage-node y of an rtl-map "S + v" stage-local value.
func _sy(v: float) -> float:
	return float(L.STAGE["y"]) + L.stage_h + v


func tube_rect() -> Rect2:
	var sz := Vector2(Art.sprite_size(_tube.get_meta("sprite"))) * AP
	return Rect2(Vector2(TUBE_X, _sy(TUBE_BOTTOM) - sz.y), sz)


## The icon's top, stage-node y: ICON_GAP above the tube top (S − 544 on the full tube, S − 424 on the short one).
func icon_top() -> float:
	return tube_rect().position.y - ICON_GAP


func hit_rect() -> Rect2:
	var top := icon_top()
	return Rect2(HIT_X.x, top, HIT_X.y, _sy(TUBE_BOTTOM) - top)


func relayout() -> void:
	if _tube == null:
		return
	var want := tube_id_for(L.stage_h)
	if want != tube_id():
		_apply_tube(want)
	var tr := tube_rect()
	_tube.position = tr.position
	var isz := Vector2(Art.sprite_size(_icon.get_meta("sprite"))) * AP
	_icon.position = Vector2(Ui.snap(_column_x() - isz.x / 2.0, 4), icon_top())
	_word.position.y = _sy(WORD_Y)
	_word.center_in(WORD_BOX.x, WORD_BOX.y)
	_place_liquid()


## The liquid column's centre x (x 72 with the kit's column: rtl-map centres the icon and the word on it).
func _column_x() -> float:
	return TUBE_X + (float(_liquid["x"]) + float(_liquid["w"]) / 2.0) * AP


## The logical y of the top of art row `r` of the tube.
func _row_y(r: float) -> float:
	return tube_rect().position.y + r * AP


## y_top(p) in art rows (kit formula).
func y_top(p01: float) -> int:
	var yb := int(_liquid["yBottom"])
	var yt := int(_liquid["yTop"])
	return yb - int(roundf(clampf(p01, 0.0, 1.0) * float(yb - yt)))


## Rows of live fill for a percentage (0 … yBottom − yTop).
func rows_for(pct: float) -> int:
	return int(_liquid["yBottom"]) - y_top(pct / 100.0)


func _place_liquid() -> void:
	var x := TUBE_X + float(_liquid["x"]) * AP
	var w := float(_liquid["w"])
	var yb := float(_liquid["yBottom"])
	var fl_rows := float(rows_for(Investigation.floor_pct(_state))) if _state != null and Investigation.active() else 0.0
	_hatch.visible = fl_rows > 0.0
	_hatch.position = Vector2(x, _row_y(yb - fl_rows))
	_hatch.size = Vector2(w, fl_rows)
	var live := maxf(0.0, roundf(_rows) - fl_rows)
	_fill.visible = live > 0.0
	_fill.position = Vector2(x, _row_y(yb - roundf(_rows)))
	_fill.scale = Vector2(AP * w / maxf(1.0, float(Art.sprite_size(_fill.get_meta("sprite")).x)), AP * live)
	_men.visible = roundf(_rows) > 0.0
	_men.position = Vector2(x, _row_y(yb - roundf(_rows)))
	_men.scale = Vector2(AP * w / maxf(1.0, float(Art.sprite_size(_men.get_meta("sprite")).x)), AP)


func is_shown() -> bool:
	return _shown


## The live fill as drawn, in art rows (tests: "the thermometer tracks suspicion").
func shown_rows() -> int:
	return int(roundf(_rows))


func target_rows() -> int:
	return int(_to_rows) if _to_rows >= 0.0 else shown_rows()


func word() -> PxText:
	return _word


func icon_id() -> String:
	return str(_icon.get_meta("sprite"))


# ------------------------------------------------------------------ per frame

## ctx: {main: bool (main mode, gameplay visible)}.
func update_view(dt: float, s: GameState, ctx: Dictionary = {}) -> void:
	_now += dt
	if not is_same(s, _known_state):
		_known_state = s
		clear()
	_state = s
	var main: bool = ctx.get("main", true)
	var on := main and s != null and Investigation.active() and bool(s.investigation.get("revealed", false))
	if on and not _shown:
		_shown = true
		_root.visible = true
		_reveal_t = 0.0 if main else -1.0
		_rows = 0.0
		_to_rows = -1.0
	elif not on and _shown:
		_shown = false
		_root.visible = false
	if not _shown:
		_update_sweat(dt, 0.0)
		return
	var p := Investigation.suspicion(s)
	_update_reveal(dt)
	_update_fill(dt, p)
	_update_state(dt, p)
	_update_bubbles(p)
	_update_alpha(dt, p)
	_place_liquid()
	_update_sweat(dt, p)


func _update_reveal(dt: float) -> void:
	if _reveal_t < 0.0:
		_root.position.x = 0.0
		return
	_reveal_t += dt
	if reduced_motion:
		_root.position.x = 0.0
		_root.modulate.a = minf(1.0, _reveal_t / 150.0) * _alpha
		if _reveal_t >= 150.0:
			_reveal_t = -1.0
		return
	var w := tube_rect().end.x + 12.0
	var e := Ui.back_out(minf(1.0, _reveal_t / REVEAL_MS), 1.70158)
	_root.position.x = Ui.snap(-w * (1.0 - e), 4)
	if _reveal_t >= REVEAL_MS:
		_reveal_t = -1.0
		_root.position.x = 0.0


func _update_fill(dt: float, p: float) -> void:
	var want := float(rows_for(p))
	if _reveal_t >= 0.0:
		return   # the tick comes after the slide
	if want != _to_rows:
		if absf(want - roundf(_rows)) >= 1.0:
			_bright_until = _now + BRIGHT_MS
		_from_rows = _rows
		_to_rows = want
		_fill_t = 0.0
	if _fill_t < 0.0:
		return
	if reduced_motion:
		_rows = _to_rows
		_fill_t = -1.0
		return
	_fill_t += dt
	var k := minf(1.0, _fill_t / FILL_MS)
	_rows = roundf(lerpf(_from_rows, _to_rows, Ui.quad_out(k)))
	if k >= 1.0:
		_rows = _to_rows
		_fill_t = -1.0


func _update_state(dt: float, p: float) -> void:
	var key := word_key(p)
	if key != _word_key:
		_word_key = key
		_word.text = Strings.s(key)
		_word.center_in(WORD_BOX.x, WORD_BOX.y)
	var hot := p >= HOT
	if hot != _hot_icon:
		if hot and _hot_seen and host != null and host.has_method("audio_event"):
			host.audio_event("suspicionHot")   # Audio v1.3: once per live upward crossing of 75 %
		_hot_icon = hot
		Ui.set_frame(_icon, Art.sprite_or("thermo_icon_gavel" if hot else "thermo_icon_magnifier"), 0)
		_icon.set_meta("sprite", Art.sprite_or("thermo_icon_gavel" if hot else "thermo_icon_magnifier"))
		_hop_t = 0.0 if not reduced_motion else -1.0
	_hot_seen = true
	var base_y := icon_top()
	if _hop_t >= 0.0:
		_hop_t += dt
		_icon.position.y = base_y - (AP if _hop_t < 100.0 else 0.0)
		if _hop_t >= 100.0:
			_hop_t = -1.0
	else:
		_icon.position.y = base_y


func _update_bubbles(p: float) -> void:
	var on := p >= HOT
	var bid: String = _bubbles[0].get_meta("sprite")
	var bw := float(Art.kit(bid).get("frameW", Art.sprite_size(bid).x)) * AP
	var cx := _column_x()
	var surface := _row_y(float(_liquid["yBottom"]) - roundf(_rows))
	if not on:
		for b in _bubbles:
			b.visible = false
		return
	if reduced_motion:
		for i in _bubbles.size():
			_bubbles[i].visible = i == 0
		Ui.set_frame(_bubbles[0], bid, mini(2, Art.frame_count(bid) - 1))
		_bubbles[0].position = Vector2(Ui.snap(cx - bw / 2.0, 4), surface - 5.0 * AP)
		_bubbles[0].modulate.a = 1.0
		return
	var period := 450.0 if p >= BOIL else 900.0
	for i in _bubbles.size():
		var b := _bubbles[i]
		var t := fmod(_now + i * (period / 3.0), period)
		var k := t / period
		b.visible = true
		Ui.set_frame(b, bid, i % maxi(1, mini(2, Art.frame_count(bid) - 1)))
		b.position = Vector2(Ui.snap(cx - bw / 2.0, 4), Ui.snap(surface - 4.0 * AP - 8.0 * AP * k, 4))
		var fade_from := period - 150.0
		b.modulate.a = 1.0 if t < fade_from else maxf(0.0, 1.0 - (t - fade_from) / 150.0)


func _update_alpha(dt: float, p: float) -> void:
	var want := 1.0 if (p >= HOT or _now < _bright_until) else 0.6
	var step := dt / (200.0 if not reduced_motion else 1.0) * 0.4
	_alpha = move_toward(_alpha, want, step) if not reduced_motion else want
	if _reveal_t < 0.0 or not reduced_motion:
		_root.modulate.a = _alpha


# ------------------------------------------------------------------ sweat (magician-sweat)

## The temple landmark this frame, in the drops' space (bb.body-local), with the fallback the
## animator specifies (eyes outer corner + (3, −2) ap) when the strip has no `temple`.
func temple() -> Vector2:
	if bb == null or bb.hero == null:
		return Vector2.ZERO
	var h := bb.hero
	var fb := Vector2(h.frame_size().x * 0.35, -h.frame_size().y * 0.72)
	return h.position + h.point("temple", fb)


func sweat_state(p: float) -> String:
	if p >= BOIL:
		return "boiling"
	if p >= HOT:
		return "nervous"
	return "dry"


func drops() -> Array[Dictionary]:
	return _drops


func bead_visible() -> bool:
	return _bead.visible


## A court summons: the gulp, two drops at once whatever the suspicion (not under reduced motion).
func gulp() -> void:
	if reduced_motion or bb == null or bb.hero == null or not _shown or not bb.on_stage():
		return
	for i in 2:
		_spawn(Vector2(-2.0 * AP, AP) if i == 1 else Vector2.ZERO)


func on_politics_event(e: Dictionary) -> void:
	if String(e.get("ev", "")) == "summons":
		gulp()


func _body_is_idle() -> bool:
	return bb != null and bb.hero != null and bb._state == "idle" and bb.hero.anim == "idle" and bb.on_stage()


func _spawn(off: Vector2) -> void:
	var spr := Ui.img(_drops_root, Vector2.ZERO, Art.sprite_or("sweat_drop"), 0, 4)
	_drops.append({"spr": spr, "t": 0.0, "off": off, "attached": true, "from": Vector2.ZERO, "td": 0.0})
	_place_drop(_drops[_drops.size() - 1])


func _drop_pivot() -> Vector2:
	var k := Art.kit(Art.sprite_or("sweat_drop"))
	return Vector2(float(k["pivot"][0]), float(k["pivot"][1])) * AP if k.get("pivot") is Array else Vector2(2, 5) * AP


func _update_sweat(dt: float, p: float) -> void:
	if bb == null or bb.hero == null:
		return
	var st := sweat_state(p) if _shown else "dry"
	var idle := _body_is_idle()
	# reduced motion: one static bead tracking the temple
	# (never on an empty stage: court day takes him off, motion/state-graph-magician.md §5.1)
	_bead.visible = reduced_motion and st != "dry" and _shown and bb.on_stage()
	if _bead.visible:
		_bead.position = (temple() - _drop_pivot()).snapped(Vector2(AP, AP))
	if reduced_motion:
		for d: Dictionary in _drops:
			(d["spr"] as Sprite2D).queue_free()
		_drops.clear()
		return
	# leaving idle detaches every attached drop at once (never a bead floating off a moving face)
	if not idle and _body_idle:
		for d: Dictionary in _drops:
			if d["attached"]:
				_detach(d)
	_body_idle = idle
	if st != "dry" and idle:
		var cap := 3 if st == "boiling" else 2
		if _now >= _next_drop and _drops.size() < cap:
			var off := Vector2.ZERO
			if st == "boiling":
				_alt = not _alt
				off = Vector2(-2.0 * AP, AP) if _alt else Vector2.ZERO
			_spawn(off)
			_next_drop = _now + (randf_range(700.0, 900.0) if st == "boiling" else randf_range(1400.0, 1800.0))
	elif st == "dry":
		_next_drop = minf(_next_drop, _now)
	for i in range(_drops.size() - 1, -1, -1):
		var d: Dictionary = _drops[i]
		d["t"] = float(d["t"]) + dt
		if d["attached"] and float(d["t"]) >= 500.0:
			_detach(d)
		if not d["attached"] and float(d["t"]) - float(d["td"]) >= 250.0:
			(d["spr"] as Sprite2D).queue_free()
			_drops.remove_at(i)
			continue
		_place_drop(d)


func _detach(d: Dictionary) -> void:
	d["attached"] = false
	d["from"] = (d["spr"] as Sprite2D).position
	d["td"] = float(d["t"])
	var sid: String = (d["spr"] as Sprite2D).get_meta("sprite")
	if Art.frame_count(sid) > 1:
		Ui.set_frame(d["spr"], sid, 1)


func _place_drop(d: Dictionary) -> void:
	var spr: Sprite2D = d["spr"]
	var t := float(d["t"])
	if d["attached"]:
		var slide := 0.0
		if t >= 200.0:
			slide = 3.0 * AP * Ui.quad_in(minf(1.0, (t - 200.0) / 300.0))
		spr.position = (temple() + (d["off"] as Vector2) + Vector2(0, slide) - _drop_pivot()).snapped(Vector2(AP, AP))
		spr.modulate.a = 1.0
	else:
		var k := minf(1.0, (t - float(d["td"])) / 250.0)
		spr.position = ((d["from"] as Vector2) + Vector2(0, 12.0 * AP * Ui.quad_in(k))).snapped(Vector2(AP, AP))
		spr.modulate.a = 1.0 if k < 0.6 else maxf(0.0, 1.0 - (k - 0.6) / 0.4)


## A reset / import / election seam: the drops go, the fill restarts from the new state.
func clear() -> void:
	for d: Dictionary in _drops:
		(d["spr"] as Sprite2D).queue_free()
	_drops.clear()
	_to_rows = -1.0
	_fill_t = -1.0
