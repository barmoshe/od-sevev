class_name PickView
extends Node2D
## LEADER_PICK, the ballot booth (2026-10-03, Bar: "תעצב מחדש לגמרי את מסך הבחירה"; the earlier 3 × 3
## grid: ux/rtl-map.md §8, design/leader-select-spec.md §3). A mode of the stage (`mode == "pick"`),
## not an overlay: the stage is scrimmed behind it and the economy is frozen (the controller's rule).
## It replaces the title state on first launch and follows EVOLVE_TX after every election.
##
## The screen is the Israeli voting booth: a tray of paper slips (פתקים), one per leader, in the booth
## frame; a big card above it shows the chosen slip (the face, the party, the leader's rule); the
## primary button puts the slip in the ballot box. Select, then vote (a second tap on the chosen slip
## also votes). Leaders not open yet (Leaders.unlock_round) are slips "in print": a blurred face and
## name, their round. הפתעה is the blank slip (Dubi writes a name on it); Gantz, the decoy, is a slip
## until he has fooled the player once.
##
## A child of the controller's root at (ox, 0): x is the canvas column, y is screen-logical. The
## controller hands it the safe band (`layout(top, bot, ...)`) and the model (`Leaders.picker`); it
## draws, takes the input and calls back:
##   on_commit(id, via) -> bool   the vote (via tile | random | again | key | card); false = refused
##   on_done()                    after the slip's flight and the fade (commit_ms)
##   on_card(id, via)             the leader card (long-press ≥ 600 ms or `I`)
##   on_decoy(id, line)           Gantz voted for: the controller's sound, the stat and DecoyCard

const SCRIM := Color(0.043, 0.039, 0.071, 0.6)    # #0b0a12 at 60% (rtl-map §7.1)
const C_NAME := Color("#fff8ec")
const C_PARTY := Color("#c9d6f2")
const C_STRIP := Color("#f7f4ec")
const STRIP_PLATE := Color("#072a7a")
const C_PAPER := Color("#f7f4ec")
const C_PAPER_EDGE := Color("#b9b19c")
const C_INK := Color("#1b1b2a")
const C_INK_MUTED := Color("#5d5a6e")
const C_PICKED := Color("#ffd23f")
const C_NEW := Color("#ffd23f")
const LH := 44.0                   # the line pitch at ×4
const HOLD_MS := 600.0             # a hold opens the leader card
const SLOP := 10.0
const GUARD_MS := 300.0            # screen-graph §0.2 rule 3: the tap-burst guard
const FLY_MS := 380.0              # the slip flies into the envelope
const HOLD_AFTER_MS := 150.0
const FADE_MS := 250.0
const PAD := 16.0                  # the canvas side margin
const GAP := 12.0                  # between slips
const COLS := 5                    # slips per row of the tray
const SLIP_H := 176.0              # 12 + face 64 + 8 + name 44 + sub 36 + 12
const FACE := 64.0                 # a slip's face
const BTN_H := 88.0                # the vote button (visual 80, hit 88)
const BOOTH_TOP := 36.0            # the booth frame around the tray (kit booth_frame at ×4)
const BOOTH_BOTTOM := 12.0
const CARD_MIN := 232.0            # the big card's least height (face 96 + name, party, two rule lines)
const XL_PREFIX := "avatar_pick_xl_"
## A locked name's smear: BLUR_RING faint copies BLUR_R logical px around it.
const BLUR_RING := 12
const BLUR_R := 9.0

var host: Node
var reduced_motion := false
var on_commit: Callable
var on_done: Callable
var on_card: Callable
var on_decoy: Callable

var variant := "first"             # first | after
var model: Dictionary = {}          # Leaders.picker(...)
var order: Array = []               # leader ids in slip order (the undo reopen keeps it)
var again_id := ""
var fresh_pct := 0.0
var lp := false                     # ftue.md LP: F9_PICK is the hint's default line
var cells: Array[Dictionary] = []   # the slips: {id ("" = הפתעה), rect, root, locked, name}
var focus := -1                     # the chosen slip (-1 none)
var show_focus := false
var locked := false                 # the vote is under way (input locked)
var go_btn: PxButton                # the vote button
var again_btn: PxButton             # = go_btn after an election (it reads "עוד סבב עם …" on the last leader)
var card_rect := Rect2()            # the big card, picker-local
var strip_rect := Rect2()           # the header's navy plate (the title, the hint), picker-local
var tray := Rect2()                 # the slips' bounding box, picker-local
var booth := Rect2()                # the booth frame, picker-local
var avatar := 128.0                 # the big card's face size
var tile := Vector2(128, SLIP_H)    # a slip's size (window.odPick.tile)
var grid := Vector2.ZERO            # the tray's [top, bottom], picker-local
## The free sky above the title [top, bottom], picker-local (seeded rounds: the controller puts the
## Daily Round's entry there when it fits; main.gd _sync_daily_btn).
var sky := Vector2.ZERO

var _top := 0.0
var _bot := float(L.H)
var _full_w := float(L.W)
var _ox := 0.0
var _press: Dictionary = {}         # {cell (-2 = the button), at, t, card, moved}
var _hover := -1
var _age := 0.0
var _commit: Dictionary = {}        # {cell, t, id, from, to}
var _strip: PxText                  # the hint under the title (the disclaimer, F9_PICK, Gantz's line)
var _scrim: ColorRect
var _layer := Node2D.new()
var _card_layer := Node2D.new()
var _decoy_revealed := false
var _decoy_ms := 0.0
var _decoy_n := 0
var _decoy_line := ""
const DECOY_MS := 3500.0
static var _blurred := {}


func _ready() -> void:
	_scrim = ColorRect.new()
	_scrim.color = SCRIM
	_scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_scrim)
	add_child(_layer)
	visible = false


## The safe band in screen-logical y, the full viewport width and the column's x offset.
func layout(top: float, bot: float, full_w: float, ox: float) -> void:
	_top = top
	_bot = bot
	_full_w = full_w
	_ox = ox
	_scrim.position = Vector2(-ox, -8.0)
	_scrim.size = Vector2(full_w, bot + 400.0)
	if visible:
		_build()


## Opens the booth. `keep_order` (the undo) redraws the previous order; `focus_id` is the slip to
## choose (the undo: the one just voted for; after an election: the last round's leader).
func open(variant_: String, model_: Dictionary, keep_order: Array = [], focus_id: String = "", fresh: float = 0.0, lp_: bool = false) -> void:
	variant = variant_
	model = model_
	again_id = str(model.get("again", "")) if variant == "after" else ""
	fresh_pct = fresh
	lp = lp_
	var ids: Array = []
	for t: Variant in model.get("tiles", []):
		ids.append(str((t as Dictionary)["id"]))
	if keep_order.size() == ids.size() and keep_order.all(func(x: Variant) -> bool: return ids.has(x)):
		order = keep_order.duplicate()
	else:
		order = arrange(model.get("tiles", []), randf)
	locked = false
	_commit = {}
	_press = {}
	_hover = -1
	_age = 0.0
	_decoy_revealed = false
	_decoy_ms = 0.0
	modulate.a = 1.0
	visible = true
	focus = -1
	_build()
	var want := focus_id if focus_id != "" else again_id
	for i in cells.size():
		if want != "" and str(cells[i]["id"]) == want:
			focus = i
	_refresh()


func close() -> void:
	visible = false
	locked = false
	_press = {}
	_commit = {}


func is_open() -> bool:
	return visible


## The tile model of a leader id ({} for הפתעה; the decoy's while he is on the tray).
func tile_of(id: String) -> Dictionary:
	var dt_ := _decoy_tile()
	if not dt_.is_empty() and str(dt_["id"]) == id:
		return dt_
	for t: Variant in model.get("tiles", []):
		if str((t as Dictionary)["id"]) == id:
			return t
	return {}


# ------------------------------------------------------------------ the order

## Leader ids in slip order: the open leaders first, the two blocs (`side`) taking turns so no stretch
## of the tray reads as one camp (a shuffle within each bloc); then the slips in print, by the round
## they open in.
static func arrange(tiles: Array, rng: Callable) -> Array:
	var by := {}
	var shut: Array = []
	for t: Variant in tiles:
		var d := t as Dictionary
		if d.get("locked", false) == true:
			shut.append(d)
			continue
		var sd := str(d.get("side", ""))
		if not by.has(sd):
			by[sd] = []
		(by[sd] as Array).append(str(d["id"]))
	var sides: Array = by.keys()
	for k: Variant in sides:
		_shuffle(by[k], rng)
	_shuffle(sides, rng)
	var out: Array = []
	var more := true
	while more:
		more = false
		for k: Variant in sides:
			if not (by[k] as Array).is_empty():
				out.append((by[k] as Array).pop_front())
				more = true
	shut.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.get("round", 0)) < int(b.get("round", 0)))
	return out + shut.map(func(d: Dictionary) -> String: return str(d["id"]))


static func _shuffle(a: Array, rng: Callable) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := int(float(rng.call()) * (i + 1)) % (i + 1)
		var t: Variant = a[i]
		a[i] = a[j]
		a[j] = t


# ------------------------------------------------------------------ layout

func _title_text() -> String:
	return Strings.s("LEADER_PICK_TITLE_AFTER" if variant == "after" else "LEADER_PICK_TITLE")


func _hint_text() -> String:
	if _decoy_ms > 0.0:
		return _decoy_line
	return Strings.s("F9_PICK") if lp else Strings.s("LEADER_PICK_DISCLAIMER")


## The booth's plan for a safe height H and canvas width cw (pure; tests pin it): the slip size and
## rows, and the big card's height and face. Bottom-up: the button, the tray in its booth, the card,
## the header (title, hint, the fresh chip after an election, the wordmark on a first launch if it fits).
static func plan(H: float, cw: float, variant_: String, n_slips: int) -> Dictionary:
	var sw := L.floor4((cw - 2.0 * PAD - float(COLS - 1) * GAP) / float(COLS))
	var rows := int(ceilf(float(n_slips) / float(COLS)))
	var tray_h := float(rows) * SLIP_H + float(rows - 1) * GAP
	var header := 12.0 + LH + 8.0 + 2.0 * LH + 12.0 + (64.0 if variant_ == "after" else 0.0)
	var bottom := 16.0 + BTN_H + 16.0
	var avail := H - header - bottom - (tray_h + BOOTH_TOP + BOOTH_BOTTOM) - 16.0
	var card_h := clampf(avail, CARD_MIN, 380.0)
	var a := 96.0
	for x: float in [192.0, 128.0]:
		if card_h >= x + 48.0 + 2.0 * LH:
			a = x
			break
	var wm := 0.0
	if variant_ == "first" and avail - card_h >= 64.0 + 24.0:
		wm = 116.0 if avail - card_h >= 116.0 + 24.0 and H >= 1280.0 else 64.0
	return {"sw": sw, "rows": rows, "trayH": tray_h, "cardH": card_h, "A": a, "wordmark": wm, "fits": avail >= CARD_MIN}


func _build() -> void:
	for c in _layer.get_children():
		_layer.remove_child(c)
		c.queue_free()
	cells.clear()
	go_btn = null
	again_btn = null
	var cw := L.cw
	var ids: Array = order.duplicate()
	var dt_ := _decoy_tile()
	if not dt_.is_empty():
		ids.append(str(dt_["id"]))
	if model.get("random", true) == true:
		ids.append("")
	var H := _bot - _top
	var pl := plan(H, cw, variant, ids.size())
	var sw := float(pl["sw"])
	tile = Vector2(sw, SLIP_H)
	avatar = float(pl["A"])
	# bottom-up: the vote button in the thumb zone, the tray in its booth over it
	var by := _bot - 16.0 - BTN_H
	var bvis := Rect2(PAD + 8.0, by + 4.0, cw - 2.0 * PAD - 16.0, BTN_H - 8.0)
	go_btn = PxButton.make(_layer, bvis, {"hit": Rect2(PAD, by, cw - 2.0 * PAD, BTN_H), "kind": "kit_primary",
		"label": Strings.s("LEADER_PICK_CHOOSE"), "on_commit": func() -> void: _vote("tile")})
	if variant == "after":
		again_btn = go_btn
	var rows := int(pl["rows"])
	var tray_bottom := by - 16.0 - BOOTH_BOTTOM
	var tray_top := tray_bottom - float(pl["trayH"])
	grid = Vector2(tray_top, tray_bottom)
	booth = Rect2(0.0, tray_top - BOOTH_TOP, cw, float(pl["trayH"]) + BOOTH_TOP + BOOTH_BOTTOM)
	if Art.has_sprite("booth_frame"):
		Ui.nine(_layer, booth, "booth_frame")
	var row_w := func(r: int) -> float:
		var n_in := mini(COLS, ids.size() - r * COLS)
		return float(n_in) * sw + float(n_in - 1) * GAP
	tray = Rect2()
	for i in ids.size():
		var r := i / COLS
		var c := i % COLS
		var x0 := (cw + float(row_w.call(r))) / 2.0 - sw   # RTL: the first slip of a row on the right
		var rect := Rect2(Ui.snap(x0 - float(c) * (sw + GAP), 4), tray_top + float(r) * (SLIP_H + GAP), sw, SLIP_H)
		cells.append(_make_slip(str(ids[i]), rect))
		tray = rect if not tray.has_area() else tray.merge(rect)
	# the big card over the booth
	var card_h := float(pl["cardH"])
	card_rect = Rect2(PAD, booth.position.y - 16.0 - card_h, cw - 2.0 * PAD, card_h)
	_card_layer = Node2D.new()   # the old one went with the layer's children
	_layer.add_child(_card_layer)
	# the header: the title (+ the fresh chip after an election), the hint, the wordmark if it fits
	var y := card_rect.position.y - 12.0
	var plate := Ui.rect(_layer, Rect2(-_ox, 0, _full_w, 0), STRIP_PLATE)   # sized once the header is laid out
	plate.modulate.a = 0.92
	_strip = PxText.make(_layer, Vector2(0, y - 2.0 * LH), _hint_text(), L.TEXT, "plain", C_PARTY)
	_strip.wrap_width = cw - 64.0
	_strip.max_lines = 2
	_strip.align = 1
	balance_wrap(_strip, cw - 64.0)
	_strip.center_in(32.0, cw - 64.0)
	if _strip.line_count() < 2:
		_strip.position.y += LH / 2.0
	y -= 2.0 * LH + 8.0
	if variant == "after":
		var chip_t := Strings.s("LEADER_PICK_FRESH_CHIP", {"pct": int(roundf(fresh_pct))})
		var ct := PxText.make(_layer, Vector2(0, y - 56.0 + 10.0), chip_t, L.TEXT, "plain", "w")
		ct.max_lines = 1
		var chw := minf(592.0, Ui.snap(float(ct.width()) + 32.0, 4))
		var chx := Ui.snap((cw - chw) / 2.0, 4)
		var chip := Ui.nine(_layer, Rect2(chx, y - 56.0, chw, 56.0), Art.sprite_or("chat_system_pill"))
		_layer.move_child(chip, ct.get_index())
		ct.center_in(chx, chw)
		y -= 64.0
	var title := PxText.make(_layer, Vector2(0, y - LH), _title_text(), L.TEXT, "plain", C_NAME)
	title.wrap_width = cw - 64.0
	title.max_lines = 1
	title.center_in(32.0, cw - 64.0)
	y -= LH
	plate.position.y = y - 12.0
	plate.size.y = card_rect.position.y - 4.0 - plate.position.y
	strip_rect = Rect2(plate.position, plate.size)
	var sky_top := _top + 12.0
	if float(pl["wordmark"]) > 0.0:
		var wm := Art.sprite_or("wordmark" if float(pl["wordmark"]) >= 116.0 else "wordmark_small")
		if not Art.has_sprite("wordmark_small"):
			wm = Art.sprite_or("wordmark")
		var wsz := Vector2(Art.sprite_size(wm)) * 4.0
		Ui.img(_layer, Vector2(Ui.snap((cw - wsz.x) / 2.0, 4), _top + 12.0), wm, 0, 4)
		sky_top = _top + 12.0 + wsz.y + 12.0
	sky = Vector2(sky_top, y - 12.0)   # seeded rounds: the daily entry's band
	_publish()


# ------------------------------------------------------------------ the slips

## The decoy's tile model (Gantz, content leaderSelect.decoy) while he is still on the tray, else {}.
func _decoy_tile() -> Dictionary:
	var dec: Dictionary = model.get("decoy", {}) if model.get("decoy") is Dictionary else {}
	if dec.is_empty() or _decoy_revealed:
		return {}
	return {"id": str(dec.get("id", "")), "short": str(dec.get("short", "")), "party": str(dec.get("party", "")),
		"art": str(dec.get("art", "")), "blurb": str(dec.get("blurb", "")), "decoy": true}


func _art_of(id: String) -> String:
	var t := tile_of(id)
	if not t.get("decoy", false):
		return LeaderUi.art(id)
	var a := SpriteStrip.resolve(str(t["art"]))
	return a if a != "" else str(t["art"])


## A face `size` logical px wide at (x, y) in `parent`: the denser heads where the manifest has them.
func _face(parent: Node, id: String, size: float, pos: Vector2, blur: bool) -> Sprite2D:
	var art := _art_of(id)
	var ch: Dictionary = SpriteStrip.manifest().get("chars", {}).get(art, {})
	var av := str(ch.get("avatarPick", "avatar_pick_" + art))
	var dense := str(ch.get("avatarPickXL", XL_PREFIX + art)) if size >= 192.0 else str(ch.get("avatarPick64", ""))
	if dense != "" and Art.has_sprite(dense):
		av = dense
	if not Art.has_sprite(av):
		return null
	var img := Ui.img(parent, pos, av, 0, 1)
	var sc := size / float(maxi(1, Art.sprite_size(av).x))
	img.scale = Vector2(sc, sc)
	if blur:
		# Bar 2026-10-03: the leaders not open yet, really blurred (not darkened): a few-texel face grown
		# back by the GPU's linear filter
		var bt := blurred(av, img.texture)
		if bt != img.texture:
			img.scale *= float(img.texture.get_width()) / float(bt.get_width())
			img.texture = bt
			img.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	return img


## A name, smeared: BLUR_RING faint copies around its place (a locked slip, the big card for one).
static func smear(parent: Node, at: Vector2, text: String, box_x: float, box_w: float, ink: Color) -> void:
	for k in BLUR_RING:
		var off := Vector2(BLUR_R, 0).rotated(TAU * k / BLUR_RING)
		var g := PxText.make(parent, at + off, text, L.TEXT, "plain", ink)
		g.wrap_width = box_w
		g.max_lines = 1
		g.center_in(box_x + off.x, box_w)
		g.modulate.a = 2.0 / BLUR_RING


func _make_slip(id: String, r: Rect2) -> Dictionary:
	var root := Node2D.new()
	root.position = r.position
	_layer.add_child(root)
	var w := r.size.x
	var t := tile_of(id)
	var shut: bool = t.get("locked", false) == true
	# the paper: an edge, the sheet, a fold shadow at the bottom (flat pixel colours)
	var edge := Ui.rect(root, Rect2(Vector2.ZERO, r.size), C_PAPER_EDGE)
	var paper := Ui.rect(root, Rect2(4, 4, w - 8.0, r.size.y - 12.0), C_PAPER)
	paper.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW   # a smeared name stays on its slip
	var c := {"id": id, "rect": r, "root": root, "edge": edge, "locked": shut}
	if id == "":
		# הפתעה: the blank slip, a big question mark Dubi will answer
		var q := PxText.make(root, Vector2(0, 28.0), "?", 8, "plain", C_INK_MUTED)
		q.center_in(0.0, w)
		var nm := PxText.make(root, Vector2(0, SLIP_H - 12.0 - 36.0 - LH), Strings.s("LEADER_PICK_RANDOM"), L.TEXT, "plain", C_INK)
		nm.wrap_width = w - 12.0
		nm.max_lines = 1
		nm.center_in(6.0, w - 12.0)
		c["name"] = nm
		return c
	_face(root, id, FACE, Vector2(Ui.snap((w - FACE) / 2.0, 4), 12.0), shut)
	var name_y := 12.0 + FACE + 8.0
	var short := str(t.get("short", id))
	var nm := PxText.make(root, Vector2(0, name_y), short, L.TEXT, "plain", C_INK)
	nm.wrap_width = w - 12.0
	nm.max_lines = 1
	nm.center_in(6.0, w - 12.0)
	c["name"] = nm
	var sub := Strings.s("LEADER_PICK_LOCKED", {"n": int(t.get("round", 0))}) if shut else str(t.get("party", ""))
	var pt := PxText.make(root, Vector2(0, name_y + LH - 4.0), sub, 3, "plain", C_INK_MUTED)
	pt.wrap_width = w - 12.0
	pt.max_lines = 1
	pt.center_in(6.0, w - 12.0)
	if shut:
		nm.visible = false
		smear(paper, nm.position - paper.position, short, 2.0, w - 12.0, C_INK)
	elif t.get("new", false) == true:
		# a ribbon over the slip's top edge (never over the face)
		var tag := PxText.make(root, Vector2(0, -20.0), Strings.s("LEADER_PICK_NEW"), 3, "plain", C_INK)
		tag.max_lines = 1
		var tw_ := Ui.snap(float(tag.width()) + 16.0, 4)
		var pill := Ui.rect(root, Rect2(Ui.snap((w - tw_) / 2.0, 4), -24.0, tw_, 36.0), C_NEW)
		root.move_child(pill, tag.get_index())
		tag.center_in(pill.position.x, tw_)
	return c


## A locked leader's face, blurred for real (Bar: "ממש מטושטש, לא סתם מעומעם"): the image shrunk to
## a few texels a side (cached per sprite); the caller draws it scaled up with linear filtering.
static func blurred(id: String, tex: Texture2D) -> Texture2D:
	if _blurred.has(id):
		return _blurred[id]
	var im: Image = tex.get_image() if tex != null else null
	if im == null or im.is_empty():
		return tex
	im = im.duplicate()
	if im.is_compressed():
		im.decompress()
	im.convert(Image.FORMAT_RGBA8)
	var w := im.get_width()
	var s := maxi(3, w / 12)
	im.resize(s, maxi(3, im.get_height() * s / maxi(1, w)), Image.INTERPOLATE_BILINEAR)
	_blurred[id] = ImageTexture.create_from_image(im)
	return _blurred[id]


# ------------------------------------------------------------------ the big card

## The chosen slip, large: the face, the name and party, the rule. Before a choice (first launch) the
## booth's one line; a slip in print shows blurred; the blank slip says Dubi picks.
func _build_card() -> void:
	for ch in _card_layer.get_children():
		_card_layer.remove_child(ch)
		ch.queue_free()
	var r := card_rect
	Ui.nine(_card_layer, r, Art.sprite_or("pick_tile_selected" if focus >= 0 else "pick_tile_idle"))
	var inner_x := r.position.x + 24.0
	var inner_w := r.size.x - 48.0
	if focus < 0 or focus >= cells.size():
		# before a choice: Dubi, the booth's host, says what to do
		var dw := 0.0
		if Art.has_sprite("avatar_dubi"):
			var dsz := Vector2(Art.sprite_size("avatar_dubi"))
			var dsc := maxf(1.0, floorf(minf(160.0, r.size.y - 48.0) / maxf(1.0, dsz.y)))
			dw = dsz.x * dsc
			Ui.img(_card_layer, Vector2(r.end.x - 24.0 - dw, r.position.y + Ui.snap((r.size.y - dsz.y * dsc) / 2.0, 4)), "avatar_dubi", 0, int(dsc))
		var iw := inner_w - (dw + 16.0 if dw > 0.0 else 0.0)
		var intro := PxText.make(_card_layer, Vector2(inner_x, r.position.y + (r.size.y - 2.0 * LH) / 2.0), Strings.s("LEADER_PICK_INTRO"), L.TEXT, "plain", C_NAME)
		intro.wrap_width = iw
		intro.max_lines = 3
		intro.align = 1
		return
	var id := str(cells[focus]["id"])
	var t := tile_of(id)
	var shut: bool = t.get("locked", false) == true
	var a := avatar
	var fy := r.position.y + 20.0
	var fx := r.end.x - 24.0 - a   # RTL: the face on the right, the words to its left
	var tx := inner_x
	var tw := fx - 16.0 - inner_x
	# a slip in print never shows its name on the card (Bar), only "מתמודד סודי" and its round
	var name_t := Strings.s("LEADER_PICK_BLANK") if id == "" else (Strings.s("LEADER_PICK_SECRET") if shut else str(t.get("short", id)))
	if id == "":
		var ic := Art.sprite_or("pick_random")
		var isz := Vector2(Art.sprite_size(ic))
		var sc := maxf(1.0, floorf(a / maxf(1.0, isz.x)))
		Ui.img(_card_layer, Vector2(fx + Ui.snap((a - isz.x * sc) / 2.0, 4), fy + Ui.snap((a - isz.y * sc) / 2.0, 4)), ic, 0, int(sc))
	else:
		_face(_card_layer, id, a, Vector2(fx, fy), shut)
	var ny := fy + maxf(0.0, (a - 2.0 * LH) / 2.0) if a <= 128.0 else fy + 24.0
	var nm := PxText.make(_card_layer, Vector2(tx, ny), name_t, 5, "plain", C_NAME)
	nm.wrap_width = tw
	nm.max_lines = 1
	nm.align = 1
	var sub := Strings.s("LEADER_PICK_LOCKED", {"n": int(t.get("round", 0))}) if shut else ("" if id == "" else str(t.get("party", "")))
	var pt := PxText.make(_card_layer, Vector2(tx, ny + LH + 12.0), sub, L.TEXT, "plain", C_PARTY)
	pt.wrap_width = tw
	pt.max_lines = 2
	pt.line_pitch = 40
	pt.align = 1
	# the rule (rule.summary), under the face, the card's width
	var line := ""
	if shut:
		line = Strings.s("LEADER_PICK_LOCKED_CAP", {"n": int(t.get("round", 0))})
	elif id == "":
		line = Strings.s("LEADER_PICK_RANDOM_CAP")
	elif t.get("decoy", false):
		line = str(t.get("blurb", ""))
	else:
		var rs := str(Leaders.rule(id).get("summary", ""))
		line = rs if rs != "" else str(t.get("blurb", ""))
	var ry := maxf(fy + a + 16.0, pt.position.y + 2.0 * 40.0 + 8.0)
	var room := int(floorf((r.end.y - 16.0 - ry) / LH))
	if room >= 1 and line != "":
		var rl := PxText.make(_card_layer, Vector2(inner_x, ry), line, L.TEXT, "plain", C_STRIP)
		rl.reading = true
		rl.wrap_width = inner_w
		rl.max_lines = mini(3, room)
		rl.align = 1
		# the ability (rule.active), muted, if the card has a line left for it
		var ab := str(t.get("abilityText", "")) if not shut else ""
		var left := room - rl.line_count()
		if ab != "" and left >= 1:
			var al := PxText.make(_card_layer, Vector2(inner_x, ry + float(rl.line_count()) * LH + 8.0), ab, L.TEXT, "plain", C_PARTY)
			al.reading = true
			al.wrap_width = inner_w
			al.max_lines = left
			al.align = 1


## The vote button's label and state for the chosen slip.
func _sync_button() -> void:
	if go_btn == null:
		return
	if focus < 0 or focus >= cells.size():
		go_btn.set_label(Strings.s("LEADER_PICK_CHOOSE")).set_enabled(false)
		return
	var id := str(cells[focus]["id"])
	var t := tile_of(id)
	if t.get("locked", false) == true:
		go_btn.set_label(Strings.s("LEADER_PICK_LOCKED_BTN")).set_enabled(false)
	elif id == "":
		go_btn.set_label(Strings.s("LEADER_PICK_VOTE_BLANK")).set_enabled(true)
	elif variant == "after" and id == again_id:
		go_btn.set_label(Strings.s("LEADER_PICK_AGAIN", {"short": LeaderUi.short(id)})).set_enabled(true)
	else:
		go_btn.set_label(Strings.s("LEADER_PICK_VOTE", {"short": str(t.get("short", id))})).set_enabled(true)


## Gantz voted for: no round. His line in the hint, he leaves the tray, the player chooses again.
func _tap_decoy() -> void:
	var dec: Dictionary = model.get("decoy", {}) if model.get("decoy") is Dictionary else {}
	var lines: Array = dec.get("lines", []) if dec.get("lines") is Array else []
	_decoy_line = str(lines[_decoy_n % lines.size()]) if not lines.is_empty() else ""
	_decoy_n += 1
	_decoy_revealed = true
	_press = {}
	focus = -1
	_build()
	_refresh()
	if on_decoy.is_valid():
		on_decoy.call(str(dec.get("id", "")), _decoy_line)
	else:
		_decoy_ms = DECOY_MS if _decoy_line != "" else 0.0
		_refresh()


# ------------------------------------------------------------------ states

## Every slip by its state (chosen: lifted and framed gold; pressed: down 4; hovered: the edge
## darkens), the big card and the button for the choice, the hint line.
func _refresh() -> void:
	for i in cells.size():
		var c: Dictionary = cells[i]
		var root: Node2D = c["root"]
		var chosen := i == focus
		var pressed := not _press.is_empty() and int(_press.get("cell", -9)) == i
		var base := (c["rect"] as Rect2).position
		root.position = base + Vector2(0, -12.0 if chosen else (4.0 if pressed else 0.0))
		(c["edge"] as ColorRect).color = C_PICKED if chosen else (C_INK_MUTED if (_hover == i or (show_focus and focus == i)) else C_PAPER_EDGE)
	_build_card()
	_sync_button()
	if _strip != null:
		var txt := _hint_text()
		if _strip.text != txt:
			_strip.text = txt
			_strip.center_in(32.0, L.cw - 64.0)
	_publish()


## D64 (mobile-first §5.8.1): a two-line caption breaks balanced, its second line ≥ 40% of its
## first. A one-word tail ("… מי שיוצא, / חוזר.") left the plate's second row almost empty navy,
## which reads as a dead band (S8) and breaks D53's "the plate hugs its text".
const STRIP_BALANCE := 0.4
const STRIP_BALANCE_STEP := 8.0


## Balances `t`'s break inside `full_w` (logical px): when two lines come out with the second under
## STRIP_BALANCE of the first, the wrap box narrows in STRIP_BALANCE_STEP steps (never below half
## the text's width) and keeps the widest box that still gives two whole lines at the ratio, else
## the most balanced two-line box it met. One line, or a text that does not fit two, is left as is.
static func balance_wrap(t: PxText, full_w: float) -> void:
	t.wrap_width = full_w
	var ws := t.line_widths()
	if ws.size() != 2 or t.truncated() or float(ws[1]) >= STRIP_BALANCE * float(ws[0]):
		return
	var best_w := full_w
	var best_r := float(ws[1]) / maxf(1.0, float(ws[0]))
	var floor_w := (float(ws[0]) + float(ws[1])) / 2.0
	var w := full_w - STRIP_BALANCE_STEP
	while w >= floor_w:
		t.wrap_width = w
		var lw := t.line_widths()
		if lw.size() != 2 or t.truncated():
			break
		var r := minf(float(lw[1]), float(lw[0])) / maxf(float(lw[1]), float(lw[0]))
		if r > best_r:
			best_r = r
			best_w = w
		if float(lw[1]) >= STRIP_BALANCE * float(lw[0]):
			return
		w -= STRIP_BALANCE_STEP
	t.wrap_width = best_w




func cell_at(p: Vector2) -> int:
	for i in cells.size():
		if Ui.in_rect(cells[i]["rect"], p):
			return i
	return -1


# ------------------------------------------------------------------ input (picker-local)

func pointer_down(p: Vector2) -> bool:
	show_focus = false
	if locked or _age < GUARD_MS:
		return true
	var i := cell_at(p)
	if i >= 0:
		_press = {"cell": i, "at": p, "t": 0.0, "card": false}
		_refresh()
		return true
	if go_btn != null and go_btn.contains(p):
		go_btn.down()
		_press = {"cell": -2, "at": p, "t": 0.0, "card": false}
	return true


func pointer_move(p: Vector2) -> void:
	if _press.is_empty() or int(_press["cell"]) < 0:
		return
	if not Ui.in_rect(cells[int(_press["cell"])]["rect"], p):
		_press = {}   # slid off: cancel
		_refresh()
	elif p.distance_to(_press["at"]) >= SLOP:
		_press["moved"] = true


## A slip: the first tap chooses it, a tap on the chosen slip votes; the button votes.
func pointer_up(p: Vector2) -> void:
	if _press.is_empty():
		return
	var pr := _press
	_press = {}
	if int(pr["cell"]) == -2:
		if go_btn != null:
			go_btn.up(go_btn.contains(p))   # on_commit → _vote
		return
	if pr.get("card", false) == true:
		_refresh()
		return
	var i := int(pr["cell"])
	if not Ui.in_rect(cells[i]["rect"], p):
		_refresh()
		return
	if i == focus:
		_vote("tile")
	else:
		choose(i)


## Chooses slip i (the big card and the button follow).
func choose(i: int) -> void:
	if locked or i < 0 or i >= cells.size():
		return
	if i != focus and host != null and host.has_method("audio_event"):
		host.call("audio_event", "slipLocked" if cells[i].get("locked", false) == true else "slipChoose")   # a paper flick / muffled
	focus = i
	_refresh()


## Mouse hover (fine pointer): the slip's edge. True = a pointer cursor.
func hover(p: Vector2) -> bool:
	var i := cell_at(p)
	if i != _hover:
		_hover = i
		_refresh()
	return i >= 0 or (go_btn != null and go_btn.contains(p))


## Keys: arrows / Tab move the choice over the tray (← is forward in RTL), Enter / Space vote, I the
## leader card, Esc after an election votes the last leader again.
func key(e: InputEventKey) -> bool:
	if locked:
		return true
	show_focus = true
	var n := cells.size()
	var f := maxi(focus, 0)
	match e.keycode:
		KEY_TAB:
			focus = posmod((focus if focus >= 0 else -1) + (-1 if e.shift_pressed else 1), n)
		KEY_LEFT, KEY_RIGHT:
			focus = clampi(f + (1 if e.keycode == KEY_LEFT else -1), 0, n - 1)
		KEY_UP, KEY_DOWN:
			var nf := f + (COLS if e.keycode == KEY_DOWN else -COLS)
			focus = nf if nf >= 0 and nf < n else f
		KEY_ENTER, KEY_SPACE, KEY_KP_ENTER:
			_vote("key")
			return true
		KEY_I:
			if focus >= 0 and str(cells[focus]["id"]) != "" and not tile_of(str(cells[focus]["id"])).get("decoy", false) \
					and not cells[focus].get("locked", false) and on_card.is_valid():
				on_card.call(str(cells[focus]["id"]), "key")
		KEY_ESCAPE:
			if variant == "after" and again_id != "":
				commit_again("key")
		_:
			return false
	_refresh()
	return true


# ------------------------------------------------------------------ the vote

func commit_again(via: String) -> void:
	if locked or again_id == "":
		return
	for i in cells.size():
		if str(cells[i]["id"]) == again_id:
			focus = i
	_start_commit(focus, again_id, via if via != "key" else "again")


func _vote(via: String) -> void:
	if focus >= 0:
		commit_cell(focus, via)


## Votes slip i now (the button, a second tap, the keys, the leader card, the controller's
## commit_pick). A slip in print never votes; Gantz fools; the blank slip draws an open leader.
func commit_cell(i: int, via: String) -> void:
	if locked or i < 0 or i >= cells.size():
		return
	var id := str(cells[i]["id"])
	focus = i
	if cells[i].get("locked", false) == true:
		_refresh()
		return
	if tile_of(id).get("decoy", false):
		_tap_decoy()
		return
	if id == "":
		id = Leaders.random_pick(randf, host.get("state") if host != null else null)
		via = "random"
	elif variant == "after" and id == again_id and via == "tile":
		via = "again"
	_start_commit(i, id, via)


## The vote: input locks, the controller writes the pick; the slip flies into the envelope on the
## button (FLY_MS), a short hold, the booth fades. Reduced motion: the hold and a cross-fade.
func _start_commit(cell: int, id: String, via: String) -> void:
	locked = true
	_press = {}
	var from := Vector2.ZERO
	var to := Vector2.ZERO
	if cell >= 0 and cell < cells.size():
		from = (cells[cell]["root"] as Node2D).position
		to = go_btn.visual.get_center() - (cells[cell]["rect"] as Rect2).size * 0.2 if go_btn != null else from
	_commit = {"cell": cell, "t": 0.0, "id": id, "via": via, "from": from, "to": to}
	var ok := true
	if on_commit.is_valid():
		ok = bool(on_commit.call(id, via))
	if not ok:
		locked = false
		_commit = {}
	_refresh()


## Total ms from the vote to the stage.
func commit_ms() -> float:
	return (HOLD_AFTER_MS + FADE_MS) if reduced_motion else (FLY_MS + HOLD_AFTER_MS + FADE_MS)


func update_view(dt: float) -> void:
	if not visible:
		return
	_age += dt
	if _decoy_ms > 0.0:
		_decoy_ms -= dt
		if _decoy_ms <= 0.0:
			_refresh()
	if not _press.is_empty() and int(_press["cell"]) >= 0 and _press.get("card", false) != true:
		_press["t"] = float(_press["t"]) + dt
		if float(_press["t"]) >= HOLD_MS and _press.get("moved", false) != true:
			_press["card"] = true
			var id := str(cells[int(_press["cell"])]["id"])
			if id != "" and not tile_of(id).get("decoy", false) and not cells[int(_press["cell"])].get("locked", false) and on_card.is_valid():
				on_card.call(id, "hold")
	if _commit.is_empty():
		return
	var t := float(_commit["t"]) + dt
	_commit["t"] = t
	var ci := int(_commit["cell"])
	if not reduced_motion:
		if ci >= 0 and ci < cells.size():
			var k := Ui.quad_in(clampf(t / FLY_MS, 0.0, 1.0))
			var root: Node2D = cells[ci]["root"]
			root.position = (_commit["from"] as Vector2).lerp(_commit["to"], k)
			root.scale = Vector2.ONE * lerpf(1.0, 0.4, k)
			root.modulate.a = 1.0 - clampf((t - FLY_MS * 0.8) / (FLY_MS * 0.2), 0.0, 1.0)
		modulate.a = 1.0 - clampf((t - FLY_MS - HOLD_AFTER_MS) / FADE_MS, 0.0, 1.0)
	else:
		modulate.a = 1.0 - clampf((t - HOLD_AFTER_MS) / FADE_MS, 0.0, 1.0)
	if t >= commit_ms():
		_commit = {}
		visible = false
		if on_done.is_valid():
			on_done.call()


## Finishes a running vote now (tests; the controller's instant path).
func finish_now() -> void:
	if not _commit.is_empty():
		_commit["t"] = commit_ms()
		update_view(0.0)


# ------------------------------------------------------------------ web debug

## window.odPick: the open booth's slips and the vote button in viewport logical px (the drivers aim
## with them). cells: [x, y, id, locked]; go: the button's centre; chosen: the chosen slip's id.
func _publish() -> void:
	if not OS.has_feature("web") or not visible:
		return
	JavaScriptBridge.eval("window.odPick = %s" % JSON.stringify(web_info()), true)


func web_info() -> Dictionary:
	var off := position + ((get_parent() as Node2D).position if get_parent() is Node2D else Vector2.ZERO)
	var cs: Array = []
	for c: Dictionary in cells:
		var q := (c["rect"] as Rect2).get_center() + off
		cs.append([q.x, q.y, str(c["id"]), c.get("locked", false) == true])
	var go: Array = []
	if go_btn != null:
		var q := go_btn.visual.get_center() + off
		go = [q.x, q.y, go_btn.is_enabled()]
	return {"open": visible, "variant": variant, "cells": cs, "go": go,
		"again": [go[0], go[1], again_id] if variant == "after" and again_id != "" and not go.is_empty() else [],
		"chosen": str(cells[focus]["id"]) if focus >= 0 and focus < cells.size() else null, "avatar": avatar,
		"tile": [tile.x, tile.y], "grid": [grid.x + off.y, grid.y + off.y],
		"card": [card_rect.position.x + off.x, card_rect.position.y + off.y, card_rect.size.x, card_rect.size.y],
		"booth": [booth.position.x + off.x, booth.position.y + off.y, booth.size.x, booth.size.y]}


func publish_closed() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.odPick = {open: false}", true)


# ------------------------------------------------------------------ the leader card (§8.7)

## The leader card over the picker (a SheetCard, depth 1): the face, the full name, the party, the
## blurb, the rule (hidden for a leader without one) and "לשחק בתור {short}", which commits.
## Gantz picked (the decoy): a modal over the picker. His head, the title (decoy.title), the line,
## and "בחר שוב" (decoy.btn), which closes it back to the picker (the centre is הפתעה again).
class DecoyCard extends SheetCard:
	var line := ""
	var dec: Dictionary = {}
	var ok_button: PxButton

	func build() -> DecoyCard:
		id = "DECOY_CARD"
		_begin()
		title(str(dec.get("title", "")))
		var art := SpriteStrip.resolve(str(dec.get("art", "")))
		var ch: Dictionary = SpriteStrip.manifest().get("chars", {}).get(art, {})
		var av := str(ch.get("avatarPick64", "avatar_pick_" + art + "_d2"))
		if Art.has_sprite(av):
			Ui.img(_holder, Vector2(CARD_X + (CARD_W - 128.0) / 2.0, _y), av, 0, 2)   # the 64 px head at 2 px = 128
			_y += 128.0 + PARA_GAP
		para(line)
		close_x(func() -> void: cancel("close"))
		one_button(str(dec.get("btn", "")), "kit_primary", func() -> void: cancel("ok"))
		finish()
		ok_button = buttons[0]
		focus_index = 0
		return self

	func on_opened() -> void:
		publish_web({"decoy": str(dec.get("id", ""))})

	func cancel(via: String) -> void:
		mgr.close(self, via)


class LeaderCard extends SheetCard:
	var leader_id := ""
	var picker: PickView
	var go_button: PxButton

	func build() -> LeaderCard:
		id = "LEADER_CARD"
		var t := picker.tile_of(leader_id)
		_begin()
		title(str(t.get("name", leader_id)))
		var art := LeaderUi.art(leader_id)
		var av := str(SpriteStrip.manifest().get("chars", {}).get(art, {}).get("avatarPick", "avatar_pick_" + art))
		if Art.has_sprite(av):
			Ui.img(_holder, Vector2(CARD_X + (CARD_W - 128.0) / 2.0, _y), av, 0, 4)
			_y += 128.0 + PARA_GAP
		para(str(t.get("party", "")), C_MUTED, true, 1)
		para(str(t.get("blurb", "")))
		if str(t.get("ruleName", "")) != "":
			para(Strings.s("LEADER_PICK_CARD_RULE", {"rule": str(t["ruleName"])}), C_TEXT)   # not gold: gold is money-only
			para(str(t.get("ruleText", "")), C_TEXT, false, 6)
			if str(t.get("abilityText", "")) != "":
				para(str(t["abilityText"]), C_TEXT, false, 6)   # leaders v3: the active ability (rule.active.copy.desc)
		close_x(func() -> void: cancel("close"))
		one_button(Strings.s("LEADER_PICK_CARD_GO", {"short": str(t.get("short", ""))}), "kit_primary", func() -> void:
			mgr.close(self, "go")
			var i := -1
			for k in picker.cells.size():
				if str(picker.cells[k]["id"]) == leader_id:
					i = k
			if i >= 0:
				picker.commit_cell(i, "card"))
		finish()
		go_button = buttons[0]
		focus_index = 0
		return self

	func on_opened() -> void:
		publish_web({"leader": leader_id})

	func cancel(via: String) -> void:
		mgr.close(self, via)
		var i := -1
		for k in picker.cells.size():
			if str(picker.cells[k]["id"]) == leader_id:
				i = k
		if i >= 0:
			picker.focus = i
			picker._refresh()
