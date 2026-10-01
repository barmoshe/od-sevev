class_name PickView
extends Node2D
## LEADER_PICK, the leader picker (ux/rtl-map.md §8, ux/screen-graph.md §0,
## design/leader-select-spec.md §3). A mode of the stage (`mode == "pick"`), not an overlay: Rows
## A/B, the ticker, the panel and the tabs are hidden, the stage is empty behind the modal scrim,
## and the economy is frozen (the controller's rule). It replaces the title state on first launch
## and follows EVOLVE_TX (and the O3b flash) after every election.
##
## A child of the controller's root at (ox, 0): x is the 720 column, y is screen-logical. The
## controller hands it the safe band (`layout(top, bot, ...)`) and the tiles (`Leaders.picker`);
## it draws, takes the input and calls back:
##   on_commit(id, via) -> bool   at the commit frame (via tile | random | again | key | card);
##                                the controller writes the pick (Politics.install) and plays the
##                                `leaderPick` sting there. false = refused (the view unlocks).
##   on_done()                    ≈ 520 ms later (the pop, the dim, the hold, the fade): the stage
##   on_card(id, via)             the leader card (long-press ≥ 600 ms or `I`)
##
## Layout (ux/mobile-first-layout.md §5.8, D42, replaces rtl-map §8.2-8.3's placement): the
## wordmark (first launch) pinned at the top, the caption strip and the foot (after: the again
## button) pinned to the bottom, the grid BOTTOM-anchored on the strip (the thumb zone), the title
## line (+ the fresh chip) attached to the grid; the scrimmed stage above is the exempt "sky".
## Tiles are fluid: tw = floor4((cw − 72) / 3), growing in height to fill up to a 1.6:1 card, the
## content block centred in the tile. 8 leaders: 3 × 3 with הפתעה in the centre cell; 4: 2 × 2 and
## a full-width הפתעה bar. The avatar A is the first of [192 (even k only), 128, 96, 64] whose grid
## fits. The order is drawn on every open, balanced by bloc
## (§8.3.1: a checkerboard / the diagonals; no left/right cue), and kept by an undo reopen.
## No number anywhere but the fresh chip's +10% (§8.8).

const SCRIM := Color(0.043, 0.039, 0.071, 0.6)    # #0b0a12 at 60% (rtl-map §7.1)
const C_NAME := Color("#fff8ec")
const C_PARTY := Color("#c9d6f2")
const C_STRIP := Color("#f7f4ec")
const LH := 44.0                   # the line pitch at ×4
const HOLD_MS := 600.0             # §8.4: a hold opens the leader card
const SLOP := 10.0
const GUARD_MS := 300.0            # screen-graph §0.2 rule 3: the tap-burst guard
const POP_MS := 120.0
const DIM_MS := 150.0
const HOLD_AFTER_MS := 250.0
const FADE_MS := 250.0
const ROW_GAP := 12.0
const STRIP_H := 112.0              # 12 + 2 lines × 44 + 12
## A3 (mobile-first §5.8.1): the caption strip sits on a full-bleed navy plate, the ticker's panel
## colour, so its white text never lies on the plaza stone (#f7f4ec on #072a7a is 12.9:1).
const STRIP_PLATE := Color("#072a7a")
## mobile-first §5.8 A3: the XL pick avatar (96×96 at d3, drawn 2 logical px per sprite px); until
## the 2D Artist's piece lands (manifest chars.<art>.avatarPickXL, else this id) the 32-px pick
## avatar draws at ×6 (1.5 art px per sprite px: whole device px at every even k).
const XL_PREFIX := "avatar_pick_xl_"   # only when the manifest names no avatarPickXL (it ships avatar_pick_<c>_d3)
## mobile-first §5.14.2 (F15): the booth frame (kit `booth_frame` at ×4, content box [5, 9, 30, 28]
## → insets left 20, top 36, right 20, bottom 12) around the grid, where it costs no tile pixel.
const BOOTH_TOP := 36.0
const BOOTH_BOTTOM := 12.0
const BOOTH_SIDE := 20.0           # the tile columns move in from 16 to 20
const BOOTH_GRID_GAP := 20.0       # the grid bottom = the strip top − 20 (the booth's bottom = − 8)

var host: Node
var reduced_motion := false
var on_commit: Callable
var on_done: Callable
var on_card: Callable

var variant := "first"             # first | after
var model: Dictionary = {}          # Leaders.picker(...)
var order: Array = []               # leader ids in cell order (the undo reopen keeps it)
var again_id := ""
var fresh_pct := 0.0
var lp := false                     # ftue.md LP: F9_PICK is the strip's default line
var cells: Array[Dictionary] = []   # {id ("" = הפתעה), rect, root, plate, name, party, blurb}
var again_btn: PxButton
var focus := -1                     # a cell index, cells.size() = the again button
var show_focus := false
var locked := false
var avatar := 128.0                 # the avatar size drawn (XL 192 / L 128 / M 96 / S 64)
var tile := Vector2(216, 284)       # the 3 × 3 tile [tw, th] (window.odPick.tile)
var grid := Vector2.ZERO            # the grid's [top, bottom], picker-local (window.odPick.grid)
var booth := Rect2()                # the booth frame, picker-local (empty = no booth; window.odPick.booth)
var _booth_node: NinePatchRect

var _top := 0.0
var _bot := float(L.H)
var _full_w := float(L.W)
var _ox := 0.0
var _press: Dictionary = {}         # {cell, at, t, card}
var _hover := -1
var _age := 0.0
var _commit: Dictionary = {}        # {cell, t, id}
var _strip: PxText
var _strip_plate: ColorRect
var strip_rect := Rect2()           # the navy plate, picker-local (window.odPick.strip)
var _scrim: ColorRect
var _layer := Node2D.new()
var _again_group: Array[CanvasItem] = []


func _ready() -> void:
	_scrim = ColorRect.new()
	_scrim.color = SCRIM
	_scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_scrim)
	add_child(_layer)
	visible = false


## The safe band in screen-logical y (top = the safe top, bot = the screen bottom − the bottom
## inset), the full viewport width and the column's x offset (the scrim spans the whole width).
func layout(top: float, bot: float, full_w: float, ox: float) -> void:
	_top = top
	_bot = bot
	_full_w = full_w
	_ox = ox
	_scrim.position = Vector2(-ox, -8.0)
	_scrim.size = Vector2(full_w, bot + 400.0)
	if visible:
		_build()


## Opens the picker. `keep_order` (the undo) redraws the previous order; `focus_id` is the tile to
## focus (the undo: the one just picked).
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
	modulate.a = 1.0
	visible = true
	_build()
	focus = -1
	if focus_id != "":
		for i in cells.size():
			if str(cells[i]["id"]) == focus_id:
				focus = i
	if focus < 0:
		focus = cells.size() if (variant == "after" and again_btn != null) else _random_index()
	_refresh()


func close() -> void:
	visible = false
	locked = false
	_press = {}
	_commit = {}


func is_open() -> bool:
	return visible


## The tile model of a leader id ({} for הפתעה).
func tile_of(id: String) -> Dictionary:
	for t: Variant in model.get("tiles", []):
		if str((t as Dictionary)["id"]) == id:
			return t
	return {}


# ------------------------------------------------------------------ the order (§8.3.1)

## Leader ids in cell order (reading order: right → left, top → bottom, the centre skipped). The
## blocs (`side`) are balanced so the right and the left columns hold the same mix and no column
## is one bloc: 3 × 3 with 4 + 4 is a checkerboard (a coin flip gives one bloc the corners), 2 × 2
## with 2 + 2 the diagonals; anything else is a shuffle that rejects a one-bloc side column.
static func arrange(tiles: Array, rng: Callable) -> Array:
	var by := {}
	for t: Variant in tiles:
		var sd := str((t as Dictionary).get("side", ""))
		if not by.has(sd):
			by[sd] = []
		(by[sd] as Array).append(str((t as Dictionary)["id"]))
	for k: Variant in by:
		_shuffle(by[k], rng)
	var n := tiles.size()
	var sides: Array = by.keys()
	if sides.size() == 2 and (by[sides[0]] as Array).size() == (by[sides[1]] as Array).size():
		var first: Array = by[sides[0]] if float(rng.call()) < 0.5 else by[sides[1]]
		var second: Array = by[sides[1]] if first == by[sides[0]] else by[sides[0]]
		var out: Array = []
		out.resize(n)
		var a_cells: Array = [0, 2, 5, 7] if n == 8 else ([0, 3] if n == 4 else [])
		var b_cells: Array = [1, 3, 4, 6] if n == 8 else ([1, 2] if n == 4 else [])
		if not a_cells.is_empty():
			for i in a_cells.size():
				out[a_cells[i]] = first[i]
				out[b_cells[i]] = second[i]
			return out
	var ids: Array = []
	for t: Variant in tiles:
		ids.append(str((t as Dictionary)["id"]))
	var side_of := {}
	for t: Variant in tiles:
		side_of[str((t as Dictionary)["id"])] = str((t as Dictionary).get("side", ""))
	for _i in 60:
		_shuffle(ids, rng)
		if _columns_mixed(ids, side_of, n):
			break
	return ids


static func _shuffle(a: Array, rng: Callable) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := int(float(rng.call()) * (i + 1)) % (i + 1)
		var t: Variant = a[i]
		a[i] = a[j]
		a[j] = t


## The cell (row, col) of order index i: 3 × 3 skips the centre; 2 × 2 is plain; col 0 = right.
static func cell_rc(i: int, n: int) -> Vector2i:
	if n <= 4:
		return Vector2i(i / 2, i % 2)
	var k := i if i < 4 else i + 1
	return Vector2i(k / 3, k % 3)


static func _columns_mixed(ids: Array, side_of: Dictionary, n: int) -> bool:
	var cols := {}
	for i in ids.size():
		var c := cell_rc(i, n).y
		if n > 4 and c == 1:
			continue
		if not cols.has(c):
			cols[c] = {}
		(cols[c] as Dictionary)[side_of.get(ids[i], "")] = true
	for c: Variant in cols:
		if (cols[c] as Dictionary).size() < 2:
			return false
	return true


# ------------------------------------------------------------------ layout (§8.2-8.3)

func _title_text() -> String:
	return Strings.s("LEADER_PICK_TITLE_AFTER" if variant == "after" else "LEADER_PICK_TITLE")


func _strip_default() -> String:
	return Strings.s("F9_PICK") if lp else Strings.s("LEADER_PICK_DISCLAIMER")


## The minimum tile height for an avatar: the content block (A + 8 + 44 + 80) + 24 of padding (3 × 3),
## or A + 120 (2 × 2).
static func tile_h(a: float, three: bool) -> float:
	return (156.0 if three else 120.0) + a


static func grid_h(a: float, three: bool) -> float:
	return 3.0 * tile_h(a, true) + 2.0 * ROW_GAP if three else 2.0 * tile_h(a, false) + ROW_GAP + 12.0 + 96.0


## mobile-first §5.8, pure (tests pin the table): for a safe height H, a canvas width cw, the art
## scale k and the variant ("first" | "after", with or without the again foot), returns
## {tw, A, th, avail, header, foot}. header = 12 + wordmark + 12 + 44 + 12 (first) or
## 12 + 44 + 8 + 56 + 12 (after); strip 112; foot 16 (first) or 116 (the again button).
static func grid_plan(H: float, cw: float, k: int, variant_: String, again: bool = true) -> Dictionary:
	var wm := 116.0 if H >= 1280.0 else 64.0
	var header := (12.0 + wm + 12.0 + 44.0 + 12.0) if variant_ == "first" else (12.0 + 44.0 + 8.0 + 56.0 + 12.0)
	var foot := 116.0 if (variant_ == "after" and again) else 16.0
	var avail := H - header - STRIP_H - foot
	var tw := L.floor4((cw - 32.0 - 40.0) / 3.0)
	var sizes: Array = ([192.0] if k % 2 == 0 else []) + [128.0, 96.0, 64.0]
	var a := 64.0
	for x: float in sizes:
		if x + 24.0 <= tw and 3.0 * (156.0 + x) + 24.0 <= avail:
			a = x
			break
	var th := maxf(156.0 + a, minf(L.floor4((avail - 24.0) / 3.0), L.floor4(1.6 * tw)))
	return {"tw": tw, "A": a, "th": th, "avail": avail, "header": header, "foot": foot, "wm": wm}


func _build() -> void:
	for c in _layer.get_children():
		_layer.remove_child(c)
		c.queue_free()
	cells.clear()
	_booth_node = null
	again_btn = null
	_again_group.clear()
	var H := _bot - _top
	var cw := L.cw
	var has_again := variant == "after" and again_id != ""
	var plan := grid_plan(H, cw, Display.k if Display.integer else 2, variant, has_again)
	var wm_bottom := _top
	# the wordmark (first launch), pinned at top + 12, centred on the canvas
	if variant == "first":
		var wm := Art.sprite_or("wordmark" if H >= 1280.0 else "wordmark_small")
		if not Art.has_sprite("wordmark_small"):
			wm = Art.sprite_or("wordmark")
		var wsz := Vector2(Art.sprite_size(wm)) * 4.0
		Ui.img(_layer, Vector2(Ui.snap((cw - wsz.x) / 2.0, 4), _top + 12.0), wm, 0, 4)
		wm_bottom = _top + 12.0 + wsz.y
	# the caption strip and the foot, pinned to the bottom
	var foot := float(plan["foot"])
	var sy := _bot - foot - STRIP_H
	strip_rect = Rect2(-_ox, sy, _full_w, STRIP_H)
	_strip_plate = Ui.rect(_layer, strip_rect, STRIP_PLATE)
	_strip = PxText.make(_layer, Vector2(0, sy + 12.0), _strip_default(), L.TEXT, "plain", C_STRIP)
	_strip.reading = true
	_strip.wrap_width = 656.0 + L.dx
	_strip.max_lines = 2
	_strip.align = 1
	_place_strip()
	if has_again:
		var vis := Rect2(24, _bot - 100.0, 672.0 + L.dx, 80)
		again_btn = PxButton.make(_layer, vis, {"hit": Rect2(16, _bot - 104.0, 688.0 + L.dx, 88), "kind": "kit_primary",
			"on_commit": func() -> void: commit_again("again")})
		var lab := PxText.make(_layer, Vector2(0, vis.position.y + 20.0), Strings.s("LEADER_PICK_AGAIN", {"short": LeaderUi.short(again_id)}), L.TEXT, "plain", PxButton.label_color("kit_primary"))   # U2: flag on the white primary
		lab.wrap_width = 560.0
		lab.max_lines = 1
		var art := LeaderUi.art(again_id)
		var av_id := str(SpriteStrip.manifest().get("chars", {}).get(art, {}).get("avatar24Pick", "avatar24_pick_" + art))
		var gw := float(lab.width()) + (64.0 if Art.has_sprite(av_id) else 0.0)
		var gx := Ui.snap((cw - gw) / 2.0, 4)
		lab.position.x = gx
		_again_group.append(lab)
		if Art.has_sprite(av_id):
			var img := Ui.img(_layer, Vector2(gx + float(lab.width()) + 16.0, vis.position.y + 16.0), av_id, 0, 2)
			_again_group.append(img)
	# the grid, bottom-anchored on the strip (its bottom = the strip top − 12)
	var n := order.size()
	var three := n > 4
	var gb := sy - 12.0
	var tw := float(plan["tw"])
	var th := float(plan["th"])
	var gh := 3.0 * th + 2.0 * ROW_GAP
	avatar = float(plan["A"])
	if not three:
		tw = L.floor4((cw - 48.0) / 2.0)
		var avail := float(plan["avail"])
		avatar = 64.0
		for a2: float in ([192.0] if (Display.k % 2 == 0 and Display.integer) else []) + [128.0, 96.0, 64.0]:
			if a2 + 24.0 <= tw and grid_h(a2, false) <= avail:
				avatar = a2
				break
		th = maxf(tile_h(avatar, false), minf(L.floor4((avail - ROW_GAP - 12.0 - 96.0) / 2.0), L.floor4(1.6 * tw)))
		gh = 2.0 * th + ROW_GAP + 12.0 + 96.0
	# the title (and chip) never ride up into the wordmark: §5.8's `avail` leaves out the 12 above the
	# strip and counts 12 (not 16) under the title, so where the tile height is capped by avail (the SE,
	# the toolbar viewports) the tiles give back those 16 px instead
	var tl_est := clampf(ceilf(float(PxText.measure(_title_text(), L.TEXT)) / (656.0 + L.dx)), 1.0, 2.0)
	var gmin := wm_bottom + 12.0 + LH * tl_est + 16.0 + (64.0 if variant == "after" else 0.0)
	var shrunk := false
	if three and gb - gh < gmin:
		th = maxf(tile_h(avatar, true), L.floor4((gb - gmin - 2.0 * ROW_GAP) / 3.0))
		gh = 3.0 * th + 2.0 * ROW_GAP
		shrunk = true
	# the title (measured now: the booth's room depends on its lines)
	var title := PxText.make(_layer, Vector2.ZERO, _title_text(), L.TEXT, "plain", C_NAME)
	title.wrap_width = 656.0 + L.dx
	title.max_lines = 2
	title.align = 1
	var tlines := maxf(1.0, float(title.line_count()))
	var chip_h := 64.0 if variant == "after" else 0.0   # the fresh chip (56) + 8
	# mobile-first §5.14.2: the booth never costs a tile pixel. tw, th and A stay; it takes 36 above
	# the grid and 8 below it from the sky, and is drawn only if the title's top still clears the
	# wordmark (first) or the safe top (after) by 12
	var sky_top := (wm_bottom + 12.0) if variant == "first" else (_top + 12.0)
	booth = Rect2()
	if not shrunk and Art.has_sprite("booth_frame"):
		var gy_b := sy - BOOTH_GRID_GAP - gh
		if gy_b - BOOTH_TOP - 16.0 - chip_h - LH * tlines >= sky_top:
			booth = Rect2(0.0, gy_b - BOOTH_TOP, cw, gh + BOOTH_TOP + BOOTH_BOTTOM)
			gb = sy - BOOTH_GRID_GAP
	var gy := gb - gh
	tile = Vector2(tw, th)
	grid = Vector2(gy, gb)
	var side := BOOTH_SIDE if booth.has_area() else 16.0
	if booth.has_area():
		_booth_node = Ui.nine(_layer, booth, "booth_frame")
	var cols: Array = [cw - side - tw, L.floor4((cw - tw) / 2.0), side] if three else [cw - side - tw, side]
	for i in n:
		var rc := cell_rc(i, n)
		var r := Rect2(cols[rc.y], gy + rc.x * (th + ROW_GAP), tw, th)
		cells.append(_make_cell(str(order[i]), r, three))
	# הפתעה: the centre cell (3 × 3) or the full-width bar under a 2 × 2
	if model.get("random", true) == true:
		var rr := Rect2(cols[1], gy + th + ROW_GAP, tw, th) if three else Rect2(side, gy + 2.0 * (th + ROW_GAP), cw - 2.0 * side, 96)
		var rc_cell := _make_cell("", rr, three)
		if three:
			cells.insert(4, rc_cell)   # reading order: the centre is 5th (§8.5)
		else:
			cells.append(rc_cell)
	# the title line (+ the fresh chip after an election), attached to the grid: the title's cell
	# bottom 16 above the grid (after: title, 8, the chip, 16, the grid); with the booth, 16 above it
	var ty := (booth.position.y if booth.has_area() else gy) - 16.0
	if variant == "after":
		var chip_t := Strings.s("LEADER_PICK_FRESH_CHIP", {"pct": int(roundf(fresh_pct))})
		var cy := ty - 56.0
		var ct := PxText.make(_layer, Vector2(0, cy + 10.0), chip_t, L.TEXT, "plain", "w")
		ct.max_lines = 1
		var chw := minf(592.0, Ui.snap(float(ct.width()) + 32.0, 4))
		var chx := Ui.snap((cw - chw) / 2.0, 4)
		var chip := Ui.nine(_layer, Rect2(chx, cy, chw, 56.0), Art.sprite_or("chat_system_pill"))
		_layer.move_child(chip, ct.get_index())
		ct.center_in(chx, chw)
		ty = cy - 8.0
	title.position.y = ty - LH * tlines
	title.center_in(32.0, 656.0 + L.dx)
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


## The strip's text, centred in its navy plate (A3: one line or two) and on the canvas.
func _place_strip() -> void:
	if _strip == null:
		return
	balance_wrap(_strip, 656.0 + L.dx)   # D64
	var sy := _bot - (116.0 if (variant == "after" and again_id != "") else 16.0) - STRIP_H
	var lines := clampf(float(_strip.line_count()), 1.0, 2.0)
	# A3: the plate hugs the text: the Hebrew body's ink sits in rows +4 … +24 of a 44 cell at ×4, so a
	# plate of 44·lines + 24 with the cell top 20 below its top leaves 24 of navy above and below the
	# ink (112 for two lines: the whole strip; 68 for one, centred in the strip's box)
	var ph := LH * lines + 24.0
	strip_rect = Rect2(-_ox, sy + Ui.snap((STRIP_H - ph) / 2.0, 4), _full_w, ph)
	if _strip_plate != null:
		_strip_plate.position = strip_rect.position
		_strip_plate.size = strip_rect.size
	_strip.position.y = strip_rect.position.y + 20.0
	_strip.center_in(32.0, 656.0 + L.dx)


func _make_cell(id: String, r: Rect2, three: bool) -> Dictionary:
	var root := Node2D.new()
	root.position = r.position
	_layer.add_child(root)
	var plate := Ui.nine(root, Rect2(Vector2.ZERO, r.size), Art.sprite_or("pick_tile_idle"))
	var content := Node2D.new()
	root.add_child(content)
	var c := {"id": id, "rect": r, "root": root, "plate": plate, "content": content, "blurb": ""}
	var w := r.size.x
	if id == "":
		var bar := not three
		var ic := Art.sprite_or("pick_random")
		var sc := 2 if (bar or avatar <= 64.0) else (6 if avatar == 192.0 else 4)
		var isz := Vector2(Art.sprite_size(ic)) * float(sc)
		var nm := PxText.make(content, Vector2.ZERO, Strings.s("LEADER_PICK_RANDOM"), L.TEXT, "plain", C_NAME)
		nm.max_lines = 1
		if bar:
			var gw := isz.x + 16.0 + float(nm.width())
			var gx := Ui.snap((w - gw) / 2.0, 4)
			nm.position = Vector2(gx, Ui.snap((r.size.y - LH) / 2.0, 4) + 4.0)
			Ui.img(content, Vector2(gx + float(nm.width()) + 16.0, Ui.snap((r.size.y - isz.y) / 2.0, 4)), ic, 0, sc)
		else:
			# mobile-first §5.8: the content block (A + 8 + 44 + 80) centred in the tile
			var top := _block_top(r.size.y)
			Ui.img(content, Vector2(Ui.snap((w - isz.x) / 2.0, 4), top + Ui.snap((avatar - isz.y) / 2.0, 4)), ic, 0, sc)
			nm.wrap_width = w - 24.0
			nm.center_in(12.0, w - 24.0)
			nm.position.y = top + avatar + 8.0
		c["blurb"] = Strings.s("LEADER_PICK_RANDOM_CAP")
		c["name"] = nm
		return c
	var t := tile_of(id)
	var art := LeaderUi.art(id)
	var ch: Dictionary = SpriteStrip.manifest().get("chars", {}).get(art, {})
	var av := str(ch.get("avatar24Pick", "avatar24_pick_" + art)) if avatar == 96.0 else str(ch.get("avatarPick", "avatar_pick_" + art))
	var sc := 2.0 if avatar == 64.0 else (6.0 if avatar == 192.0 else 4.0)
	# the 2D Artist's denser heads (A3): 96×96 d3 for A 192, 64×64 d2 for A 128 (at an even k), at
	# 2 logical px per sprite px; else the 32-px head at ×6 / ×4
	var dense := str(ch.get("avatarPickXL", XL_PREFIX + art)) if avatar == 192.0 else (str(ch.get("avatarPick64", "")) if avatar == 128.0 else "")
	if dense != "" and Art.has_sprite(dense) and (avatar == 192.0 or Display.k % 2 == 0):
		av = dense
		sc = avatar / float(maxi(1, Art.sprite_size(dense).x))
	var top := _block_top(r.size.y) if three else 12.0
	if Art.has_sprite(av):
		var asz := Vector2(Art.sprite_size(av)) * sc
		var img := Ui.img(content, Vector2(Ui.snap((w - asz.x) / 2.0, 4), top), av, 0, 4)
		img.scale = Vector2(sc, sc)
	var nm := PxText.make(content, Vector2(0, top + avatar + 8.0), str(t.get("short", id)), L.TEXT, "plain", C_NAME)
	nm.wrap_width = w - 24.0
	nm.max_lines = 1
	nm.center_in(12.0, w - 24.0)
	var pt := PxText.make(content, Vector2(0, nm.position.y + LH), str(t.get("party", "")), L.TEXT, "plain", C_PARTY)
	pt.wrap_width = w - 24.0
	pt.max_lines = 2 if three else 1
	pt.line_pitch = 40   # rtl-map §8.3: party lines at pitch 40
	pt.align = 1
	pt.center_in(12.0, w - 24.0)
	c["name"] = nm
	c["party"] = pt
	c["blurb"] = str(t.get("blurb", ""))
	return c


## The content block's top in a tile of height h: (h − (A + 8 + 44 + 80)) / 2, at least 12.
func _block_top(h: float) -> float:
	return maxf(12.0, Ui.snap((h - (avatar + 8.0 + LH + 80.0)) / 2.0, 4))


func _random_index() -> int:
	for i in cells.size():
		if str(cells[i]["id"]) == "":
			return i
	return 0


# ------------------------------------------------------------------ states

## The plate of every cell by its state: selected (the commit), pressed, focus (keyboard or
## hover), idle; the strip shows the pressed / focused / hovered tile's blurb, else the default.
func _refresh() -> void:
	var active := -1
	for i in cells.size():
		var c: Dictionary = cells[i]
		var st := "idle"
		var sel := not _commit.is_empty() and int(_commit["cell"]) == i
		if sel:
			st = "selected"
		elif not _press.is_empty() and int(_press["cell"]) == i:
			st = "pressed"
			active = i
		elif (show_focus and focus == i) or _hover == i:
			st = "focus"
			if active < 0:
				active = i
		var sprite := Art.sprite_or("pick_tile_" + st)
		var r: Rect2 = Rect2(Vector2.ZERO, (c["rect"] as Rect2).size)
		if st == "selected":
			r = r.grow(4.0)
		var plate: NinePatchRect = c["plate"]
		if str(plate.get_meta("sprite", "")) != sprite:
			_set_nine_sprite(plate, sprite)
		Ui.set_nine_rect(plate, r)
		(c["content"] as Node2D).position.y = 4.0 if st == "pressed" else 0.0
	if again_btn != null:
		again_btn.hover(show_focus and focus == cells.size())
	if _strip != null:
		var txt := _strip_default()
		if active >= 0 and str(cells[active]["blurb"]) != "":
			txt = str(cells[active]["blurb"])
		if _strip.text != txt:
			_strip.text = txt
			_place_strip()


## A 9-slice's sprite and its own slice margins (the selected plate's rim is 1 art px wider).
static func _set_nine_sprite(n: NinePatchRect, id: String) -> void:
	n.texture = Art.tex(id, 0)
	var ins: Dictionary = Art.insets(id)
	n.patch_margin_left = int(ins["left"])
	n.patch_margin_right = int(ins["right"])
	n.patch_margin_top = int(ins["top"])
	n.patch_margin_bottom = int(ins["bottom"])
	n.set_meta("sprite", id)


func cell_at(p: Vector2) -> int:
	for i in cells.size():
		if Ui.in_rect(cells[i]["rect"], p):
			return i
	return -1


# ------------------------------------------------------------------ input (§8.4-8.5), picker-local

func pointer_down(p: Vector2) -> bool:
	show_focus = false
	if locked or _age < GUARD_MS:
		return true
	var i := cell_at(p)
	if i >= 0:
		_press = {"cell": i, "at": p, "t": 0.0, "card": false}
		_refresh()
		return true
	if again_btn != null and again_btn.contains(p):
		again_btn.down()
		_press = {"cell": -2, "at": p, "t": 0.0, "card": false}
		return true
	return true


func pointer_move(p: Vector2) -> void:
	if _press.is_empty():
		return
	if int(_press["cell"]) == -2:
		return
	if not Ui.in_rect(cells[int(_press["cell"])]["rect"], p):
		_press = {}   # slid off: cancel, the strip returns to its default
		_refresh()
	elif p.distance_to(_press["at"]) >= SLOP:
		_press["moved"] = true


func pointer_up(p: Vector2) -> void:
	if _press.is_empty():
		return
	var pr := _press
	_press = {}
	if int(pr["cell"]) == -2:
		var inside := again_btn != null and again_btn.contains(p)
		if again_btn != null:
			again_btn.up(inside)   # on_commit → commit_again
		return
	if pr.get("card", false) == true:
		_refresh()
		return
	var i := int(pr["cell"])
	if Ui.in_rect(cells[i]["rect"], p):
		commit_cell(i, "tile")
	else:
		_refresh()


## Mouse hover (fine pointer): the focus state and the blurb. True = a pointer cursor.
func hover(p: Vector2) -> bool:
	var i := cell_at(p)
	if i != _hover:
		_hover = i
		_refresh()
	var on_again := again_btn != null and again_btn.contains(p)
	return i >= 0 or on_again


## Keys (§8.5). True = handled. Focus moves in reading order: the grid right → left, top →
## bottom (the 3 × 3 centre is 5th), then the again button. ← is forward in RTL (mirror).
func key(e: InputEventKey) -> bool:
	if locked:
		return true
	show_focus = true
	var n := cells.size()
	var has_again := again_btn != null
	match e.keycode:
		KEY_TAB:
			focus = posmod(focus + (-1 if e.shift_pressed else 1), n + (1 if has_again else 0))
		KEY_LEFT, KEY_RIGHT:
			focus = _move(focus, 0, 1 if e.keycode == KEY_LEFT else -1)
		KEY_UP, KEY_DOWN:
			focus = _move(focus, 1 if e.keycode == KEY_DOWN else -1, 0)
		KEY_ENTER, KEY_SPACE, KEY_KP_ENTER:
			if focus == n and has_again:
				commit_again("key")
			elif focus >= 0 and focus < n:
				commit_cell(focus, "key")
			return true
		KEY_I:
			if focus >= 0 and focus < n and str(cells[focus]["id"]) != "" and on_card.is_valid():
				on_card.call(str(cells[focus]["id"]), "key")
		KEY_ESCAPE:
			if variant == "after" and has_again:
				commit_again("key")
		_:
			return false
	_refresh()
	return true


## The grid position of a focus index: [row, col] (col 0 = right); the 2 × 2 bar is row 2, col 0;
## the again button is the row under the grid.
func _rc(f: int) -> Vector2i:
	var n := cells.size()
	var cols := 3 if n > 5 else 2
	if f >= n:
		return Vector2i(3, 0)
	if cols == 2 and f >= 4:
		return Vector2i(2, 0)
	return Vector2i(f / cols, f % cols)


func _index(rc: Vector2i) -> int:
	var n := cells.size()
	var cols := 3 if n > 5 else 2
	if cols == 2 and rc.x == 2:
		return 4 if n > 4 else -1
	if rc.x == 3:
		return n if again_btn != null else -1
	var i := rc.x * cols + rc.y
	return i if i >= 0 and i < n else -1


## One step: dr rows down, dc columns toward the left. No wrap; ↓ from the bottom row reaches the
## again button, ↑ from it the grid's bottom row.
func _move(f: int, dr: int, dc: int) -> int:
	if f < 0:
		return _random_index()
	var rc := _rc(f)
	var cols := 3 if cells.size() > 5 else 2
	if dc != 0:
		if rc.x >= (3 if cols == 3 else 2):
			return f
		var nc := rc.y + dc
		if nc < 0 or nc >= cols:
			return f
		var j := _index(Vector2i(rc.x, nc))
		return j if j >= 0 else f
	var nr := rc.x + dr
	var last := 2   # the grid's bottom row (3 × 3 row 2; the 2 × 2 bar)
	if nr > last:
		return _index(Vector2i(3, 0)) if again_btn != null and dr > 0 else f
	if nr < 0:
		return f
	var col := rc.y if nr < (3 if cols == 3 else 2) else 0
	if rc.x == 3:
		col = 1 if cols == 3 else 0
	var i := _index(Vector2i(nr, col))
	return i if i >= 0 else f


# ------------------------------------------------------------------ commit (§8.4)

func commit_again(via: String) -> void:
	if locked or again_id == "":
		return
	_start_commit(cells.size(), again_id, via)


func commit_cell(i: int, via: String) -> void:
	if locked or i < 0 or i >= cells.size():
		return
	var id := str(cells[i]["id"])
	if id == "":
		id = Leaders.random_pick(randf)
		via = "random"
	_start_commit(i, id, via)


## The commit frame: input locks, the controller writes the pick and plays the sting; then the pop
## (120 ms), the others dim to 40% (150 ms), a 250 ms hold and a 250 ms fade (≈ 520 ms). Reduced
## motion: the selected rim for 250 ms, then a 150 ms cross-fade.
func _start_commit(cell: int, id: String, via: String) -> void:
	locked = true
	_press = {}
	_commit = {"cell": cell, "t": 0.0, "id": id, "via": via}
	var ok := true
	if on_commit.is_valid():
		ok = bool(on_commit.call(id, via))
	if not ok:
		locked = false
		_commit = {}
	_refresh()


## Total ms from the commit to the stage.
func commit_ms() -> float:
	return (HOLD_AFTER_MS + DIM_MS) if reduced_motion else (maxf(POP_MS, DIM_MS) + HOLD_AFTER_MS + FADE_MS)


func update_view(dt: float) -> void:
	if not visible:
		return
	_age += dt
	if not _press.is_empty() and int(_press["cell"]) >= 0 and _press.get("card", false) != true:
		_press["t"] = float(_press["t"]) + dt
		if float(_press["t"]) >= HOLD_MS and _press.get("moved", false) != true:
			_press["card"] = true
			var id := str(cells[int(_press["cell"])]["id"])
			if id != "" and on_card.is_valid():
				on_card.call(id, "hold")
	if _commit.is_empty():
		return
	var t := float(_commit["t"]) + dt
	_commit["t"] = t
	var ci := int(_commit["cell"])
	if not reduced_motion:
		for i in cells.size():
			var root: Node2D = cells[i]["root"]
			if i == ci:
				root.position.y = (cells[i]["rect"] as Rect2).position.y - (4.0 if t < POP_MS else 0.0)
			else:
				root.modulate.a = lerpf(1.0, 0.4, clampf(t / DIM_MS, 0.0, 1.0))
		for n: CanvasItem in _again_group:
			if ci != cells.size():
				n.modulate.a = lerpf(1.0, 0.4, clampf(t / DIM_MS, 0.0, 1.0))
		var f0 := maxf(POP_MS, DIM_MS) + HOLD_AFTER_MS
		modulate.a = 1.0 - clampf((t - f0) / FADE_MS, 0.0, 1.0)
	else:
		modulate.a = 1.0 - clampf((t - HOLD_AFTER_MS) / DIM_MS, 0.0, 1.0)
	if t >= commit_ms():
		_commit = {}
		visible = false
		if on_done.is_valid():
			on_done.call()


## Finishes a running commit now (tests; the controller's instant path).
func finish_now() -> void:
	if not _commit.is_empty():
		_commit["t"] = commit_ms()
		update_view(0.0)


# ------------------------------------------------------------------ web debug

## window.odPick: the open picker's cells and the again button in viewport logical px (the
## browser driver aims with them, as window.odModal).
func _publish() -> void:
	if not OS.has_feature("web"):
		return
	JavaScriptBridge.eval("window.odPick = %s" % JSON.stringify(web_info()), true)


func web_info() -> Dictionary:
	var off := position + ((get_parent() as Node2D).position if get_parent() is Node2D else Vector2.ZERO)
	var cs: Array = []
	for c: Dictionary in cells:
		var q := (c["rect"] as Rect2).get_center() + off
		cs.append([q.x, q.y, str(c["id"])])
	var ag: Array = []
	if again_btn != null:
		var q := again_btn.visual.get_center() + off
		ag = [q.x, q.y, again_id]
	var bo: Variant = null
	if booth.has_area():
		bo = [booth.position.x + off.x, booth.position.y + off.y, booth.size.x, booth.size.y]
	return {"open": visible, "variant": variant, "cells": cs, "again": ag, "avatar": avatar,
		"tile": [tile.x, tile.y], "grid": [grid.x + off.y, grid.y + off.y], "booth": bo,
		"strip": [strip_rect.position.x + off.x, strip_rect.position.y + off.y, strip_rect.size.x, strip_rect.size.y],
		"stripText": [_strip.position.y + off.y, _strip.position.y + off.y + LH * clampf(float(_strip.line_count()), 1.0, 2.0)] if _strip != null else []}


func publish_closed() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.odPick = {open: false}", true)


# ------------------------------------------------------------------ the leader card (§8.7)

## The leader card over the picker (a SheetCard, depth 1): the face, the full name, the party, the
## blurb, the rule (hidden for a leader without one) and "לשחק בתור {short}", which commits.
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
