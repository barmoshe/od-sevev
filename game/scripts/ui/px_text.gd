class_name PxText
extends Node2D
## Pixel text drawn at an exact integer scale with its glyph-box top-left at the node position
## (the UX layout contract, ux/hud-layout.md §0). Re-lays out only when the string changes.
##
## od-sevev: two routes (engine/feasibility.md O-U2, ux/first-minute.md §3.5):
## - SHAPED: Hebrew and mixed text goes through TextServer (TextServerAdvanced, ICU bidi,
##   LRI/PDI honoured) with HeFont ("Sevev 9"), shaped once per text change.
## - BITMAP: the fork's monospace 5x7 font, left to right, no bidi, allowed only for strings
##   with no RTL letter, no ₪ and no bidi control that the fork's glyphs cover. It is OFF by
##   default (BITMAP_ROUTE): the TA's loader contract (assets/sprites/CONTRACT.md §6) points out
##   that the fork's 5x7 digits are a different letterform from Sevev's, so "58/61" next to
##   "מנדטים" would not match. Numbers therefore shape too (an LTR paragraph costs microseconds,
##   and only on change). Flip BITMAP_ROUTE to get the fork's digits back.
##   RTL paragraphs start-align to the right. `wrap_width` wraps (body copy: max_lines, then
##   ellipsis); labels ellipsize at `wrap_width` with max_lines 1 (O-U3: no fractional shrink).
## Both routes draw at font size × px through the canvas transform, never a fractional size.
##
## The reading role (`reading = true`, CONTRACT.md §6.1, the 2D Artist's role split): body copy
## draws with Sevev 9 @2, shaped at size 18 and drawn at eff_px() / 2, wherever one Sevev 9 px is an
## EVEN number of device px (so an @2 px is whole: k 2, 4, 6, 8 at ×4); elsewhere (k 3, 9, large
## text ×5 at k 4, the fractional fallback) it draws Sevev 9. Every @2 metric is exactly 2× Sevev 9's,
## so both cuts wrap, ellipsise and measure identically: layout never moves. Display text (the
## counter, prices, titles, tabs, the ticker tag, chips, buttons, badges, anything dimmed or over
## art) keeps the default `reading = false`. The outline variants never use it (no @2 outline cut).

var text := "":
	set(v):
		if v != text:
			text = v
			_relayout()
var px := 3:
	set(v):
		if v != px:
			px = v
			if text != "":
				_relayout()   # the wrap box is in font units, and the large-text step depends on px
			else:
				queue_redraw()
var variant := "plain":
	set(v):
		if v != variant:
			variant = v
			if _para != null:
				_relayout()   # the outline variant shapes with the TA's outline cut
			else:
				queue_redraw()
## The plain variant is a white mask: tint is its colour. Outlined variants multiply by it.
var tint := Color.WHITE:
	set(v):
		if v != tint:
			tint = v
			queue_redraw()
var uppercase := true
## Line alignment inside the text box: -1 start (left in LTR, right in RTL), 0 left, 1 centre,
## 2 right.
var align := -1:
	set(v):
		if v != align:
			align = v
			queue_redraw()
## Which point of the text box the node position is: 0 its left edge (the fork's contract),
## 1 its centre, 2 its right edge (RTL rows anchor names to the right, L.ROW nameX).
var h_anchor := 0:
	set(v):
		if v != h_anchor:
			h_anchor = v
			queue_redraw()
var line_pitch := 0   # px between line tops; 0 = font line height × scale
## Wrap/ellipsis box in logical px (0 = none). With max_lines 1 a too-long label ellipsizes.
var wrap_width := 0.0:
	set(v):
		if v != wrap_width:
			wrap_width = v
			_relayout()
var max_lines := 2:
	set(v):
		if v != max_lines:
			max_lines = v
			_relayout()
## Large text (ux/rtl-map.md §0.2): the most lines this text may take at the large scale (the
## budget's `linesLarge`; 0 = max_lines). See _steps_up().
var max_lines_large := 0:
	set(v):
		if v != max_lines_large:
			max_lines_large = v
			_relayout()
## The box the large-text fit is measured against when the text has no wrap box (logical px;
## 0 = wrap_width). It never wraps or ellipsises: a label keeps its ×4 behaviour and only uses
## this width to decide between ×5 and ×4 (tab labels, pill lines, button labels, Row B).
var fit_width := 0.0:
	set(v):
		if v != fit_width:
			fit_width = v
			_relayout()
## Optional per-glyph vertical offset: func(glyph_index: int, glyph_x: float) -> float (the
## ticker's J8 hop). glyph_x is the glyph's left edge in node px.
var glyph_dy: Callable
## The reading role (above): this text may draw with Sevev 9 @2 where that is crisp.
var reading := false:
	set(v):
		if v != reading:
			reading = v
			if text != "":
				_relayout()

## Draws at exactly `px` logical px per font px: no device-px snap, no large-text step, no @2
## (a SubViewport that renders 1:1, e.g. the share cards' PNG export, ui/views/view_share.gd).
var exact := false:
	set(v):
		if v != exact:
			exact = v
			if text != "":
				_relayout()

var _ft := ""                      # bitmap route: the font_text string
var _para: TextParagraph           # shaped route (null on the bitmap route)
var _box_w := 0.0                  # shaped route: box width in font units
var _up := false                   # large text: this string draws one whole scale up
var _u := 1                        # shaped font units per Sevev 9 px: 2 on the @2 cut, else 1


static func make(parent: Node, pos: Vector2, t: String, scale_px: int = 3, var_: String = "plain", c: Variant = "w") -> PxText:
	var p := PxText.new()
	p.add_to_group("pxtext")
	p.px = scale_px
	p.variant = var_
	p.tint = c if c is Color else Art.col(c)
	p.position = pos
	p.text = t
	parent.add_child(p)
	return p


## True when a string may use the bitmap route (every glyph in the fork font, no RTL, no bidi
## control).
const BITMAP_ROUTE := false
## Large-text mode (ux/rtl-map.md §0.2, the step-down rule): a text drawn at the body scale
## (L.TEXT, ×4) draws one whole scale up (×5) only where the FILLED string fits its box there:
## at most max_lines_large lines (else max_lines) of width wrap_width (else fit_width), no word
## wider than the box. Otherwise it steps back down to ×4, where the build lint proves every
## budgeted key fits, so a step-down key is never ellipsised by large text. A text with no box
## (the crawl, a floater) always draws ×5. Views that stack text measure line_count() and
## eff_px() after setting the text, so rows grow to the scale actually drawn.
static var large_text := false
## Master switch for the @2 reading cut (on; `?dev=1&sharp=0` and the before/after shots turn it off).
static var sharp_text := true


static func set_sharp_text(tree: SceneTree, on: bool) -> void:
	if on == sharp_text:
		return
	sharp_text = on
	relayout_all(tree)


static func set_large_text(tree: SceneTree, on: bool) -> void:
	if on == large_text:
		return
	large_text = on
	if tree:
		for n in tree.get_nodes_in_group("pxtext"):
			(n as PxText)._relayout()


## Re-lays out every text (the device scale or large text changed).
static func relayout_all(tree: SceneTree) -> void:
	if tree:
		for n in tree.get_nodes_in_group("pxtext"):
			(n as PxText)._relayout()


## The scale actually drawn, logical px per font px: px, or px + 1 for body text in large-text
## mode where it fits (_steps_up), snapped to whole device px (Display.text_scale), so every glyph
## pixel is crisp at any k.
func eff_px() -> float:
	if exact:
		return float(px)
	return Display.text_scale(float(px + 1 if _up else px))


## True when this text draws with Sevev 9 @2 now (the reading role, crisp at this scale).
func is_sharp() -> bool:
	return _u == HeFont.SHARP_DENSITY


## Device px per Sevev 9 px for this text as drawn (a whole number on an integer surface).
func device_px() -> float:
	return eff_px() * Display.f


## The @2 pick rule (CONTRACT.md §6.1): a reading text on the plain cut, the @2 font shipped, and one
## Sevev 9 px an even number (≥ 2) of whole device px.
func _wants_sharp() -> bool:
	if exact or not reading or not sharp_text or variant != "plain" or not Display.integer:
		return false
	var spec: Dictionary = Art.data.get("font", {}).get("variants", {}).get(variant, {})
	if spec.get("outline") != null or HeFont.sharp() == null:
		return false
	var dp := device_px()
	var n := int(roundf(dp))
	return is_equal_approx(dp, float(n)) and n >= HeFont.SHARP_DENSITY and n % HeFont.SHARP_DENSITY == 0


## True when large text draws this string one scale up (rtl-map §0.2).
func stepped_up() -> bool:
	return _up


## The body scale in effect for unboxed text (the ticker's paged widths): ×5 under large text.
static func body_scale() -> int:
	return L.TEXT + 1 if large_text else L.TEXT


## rtl-map §0.2: does `t` fit a box `box_w` logical px wide in `lines` lines at scale `scale_px`
## (word-wrapped the way the shaped route wraps; a word wider than the box does not fit)? Pure.
static func fits(t: String, box_w: float, lines: int, scale_px: int) -> bool:
	if t == "" or box_w <= 0.0:
		return true
	var sc := Display.text_scale(float(scale_px))
	var w := floorf(box_w / sc)
	if bitmap_ok(t):
		return Art.measure(Art.font_text(t), scale_px) <= int(box_w) and t.split("\n").size() <= lines
	var p := TextParagraph.new()
	p.direction = TextServer.DIRECTION_RTL if Bidi.paragraph_rtl(t) else TextServer.DIRECTION_LTR
	p.break_flags = TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND
	p.justification_flags = TextServer.JUSTIFICATION_NONE
	p.add_string(Bidi.glue(t) if lines > 1 else t, HeFont.font(), HeFont.size())   # §5.2.1: as it will wrap
	p.width = w
	if p.get_line_count() > maxi(1, lines):
		return false
	for i in p.get_line_count():
		if p.get_line_width(i) > w + 0.01:
			return false
	return true


func _steps_up() -> bool:
	if exact or not large_text or px != L.TEXT or text == "":
		return false
	if wrap_width > 0.0:
		return fits(text, wrap_width, max_lines_large if max_lines_large > 0 else max_lines, px + 1)
	if fit_width > 0.0:
		# an unwrapped label: its explicit lines only (it never wraps)
		return fits(text, fit_width, text.count("\n") + 1, px + 1)
	return true


static func bitmap_ok(t: String) -> bool:
	if not BITMAP_ROUTE or Bidi.has_rtl(t) or t.contains(Bidi.SHEKEL):
		return false
	for c: String in Bidi.CONTROLS:
		if t.contains(c):
			return false
	var glyphs: Dictionary = Art.data["font"]["glyphs"]
	var aliases: Dictionary = Art.data["font"]["aliases"]
	var up := t.to_upper()
	for i in up.length():
		var ch: String = aliases.get(up[i], up[i])
		if ch != "\n" and ch != " " and not glyphs.has(ch):
			return false
	return true


## Width in logical px of `t` drawn at scale `scale_px` on whichever route it takes (the widest
## line; no wrapping).
static func measure(t: String, scale_px: int) -> int:
	if t == "":
		return 0
	if bitmap_ok(t):
		return Art.measure(Art.font_text(t), scale_px)
	var widest := 0.0
	for l in t.split("\n"):
		var tl := TextLine.new()
		tl.direction = TextServer.DIRECTION_RTL if Bidi.paragraph_rtl(l) else TextServer.DIRECTION_LTR
		tl.add_string(l, HeFont.font(), HeFont.size())
		widest = maxf(widest, tl.get_line_width())
	return int(ceilf(widest)) * scale_px


## The "outline" variant uses the TA's outline cut when it exists (its ring is baked in, so the
## draw is one pass); every other variant uses the plain cut.
func _shaped_font() -> Font:
	if variant == "outline" and HeFont.outline() != null:
		return HeFont.outline()
	return HeFont.font()


func is_shaped() -> bool:
	return _para != null


func _relayout() -> void:
	_up = _steps_up()
	_u = 1
	if text == "" or bitmap_ok(text):
		_para = null
		_ft = Art.font_text(text, uppercase)
	else:
		_ft = ""
		# the @2 cut shapes at 18 in units half a Sevev 9 px wide: every box below is in shaped
		# units, i.e. the Sevev 9 box × _u (floored in Sevev 9 px first, so both cuts wrap alike)
		_u = HeFont.SHARP_DENSITY if _wants_sharp() else 1
		# mobile-first §5.2.1: a wrapping text is glued (a number keeps its ₪, a word its mark); if
		# a unit is still wider than the line, its weak joints open, then all of them (never lost)
		var wraps := wrap_width > 0.0 and maxi(max_lines, max_lines_large) > 1
		var tries: Array = [Bidi.glue(text), Bidi.glue_strong(text), text] if wraps else [text]
		for shown: String in tries:
			_shape(shown)
			if not _overflows() or shown == text:
				break
		_box_w = 0.0
		for i in _para.get_line_count():
			_box_w = maxf(_box_w, _para.get_line_width(i))
		if wrap_width > 0.0:
			_box_w = minf(_box_w, _wrap_units())
	queue_redraw()


func _shape(shown: String) -> void:
	_para = TextParagraph.new()
	_para.direction = TextServer.DIRECTION_RTL if Bidi.paragraph_rtl(shown) else TextServer.DIRECTION_LTR
	_para.break_flags = TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND
	_para.justification_flags = TextServer.JUSTIFICATION_NONE
	if _u > 1:
		_para.add_string(shown, HeFont.sharp(), HeFont.sharp_size())
	else:
		_para.add_string(shown, _shaped_font(), HeFont.size())
	if wrap_width > 0.0:
		_para.width = _wrap_units()


## True when a shaped line is wider than the wrap box (a glued unit longer than the line). Read
## before the line cap and the ellipsis are set, then sets them.
func _overflows() -> bool:
	if _para == null or wrap_width <= 0.0:
		return false
	var w := _wrap_units()
	var over := false
	for i in _para.get_line_count():
		if _para.get_line_width(i) > w + 0.01:
			over = true
	_para.max_lines_visible = maxi(1, max_lines_large if (_up and max_lines_large > 0) else max_lines)
	_para.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	return over


## The wrap box in shaped units: whole Sevev 9 px at the drawn scale, × _u.
func _wrap_units() -> float:
	return floorf(wrap_width / float(eff_px())) * _u


## Logical px per shaped unit (eff_px() on Sevev 9, eff_px() / 2 on @2).
func _unit_px() -> float:
	return eff_px() / float(_u)


func width() -> int:
	if _para != null:
		return int(ceilf(_box_w * _unit_px()))
	return Art.measure(_ft, px)


## The drawn lines' widths in logical px, top to bottom (D64: the picker caption's balanced break).
func line_widths() -> Array:
	var out: Array = []
	if _para != null:
		for i in line_count():
			out.append(_para.get_line_width(i) * _unit_px())
	elif _ft != "":
		for l in _ft.split("\n"):
			out.append(float(Art.measure(l, px)))
	return out


## Number of drawn lines (the lint and tests check wrapping).
func line_count() -> int:
	if _para != null:
		return mini(_para.get_line_count(), _para.max_lines_visible) if _para.max_lines_visible > 0 else _para.get_line_count()
	return _ft.split("\n").size() if _ft != "" else 0


## True when the shaped text was cut with an ellipsis.
func truncated() -> bool:
	if _para == null or wrap_width <= 0.0:
		return false
	if _para.get_line_count() > _para.max_lines_visible:
		return true
	for i in _para.get_line_count():
		if _para.get_line_width(i) > _wrap_units() + 0.01:
			return true
	return false


## The shaped lines' character ranges and widths in Sevev 9 px (tests: both cuts lay out alike).
func line_layout() -> Array:
	var out: Array = []
	if _para == null:
		return out
	for i in line_count():
		out.append([_para.get_line_range(i), _para.get_line_width(i) / float(_u)])
	return out


## Centres the current text horizontally inside [region_x, region_x + region_w), on a 4-px grid.
func center_in(region_x: float, region_w: float) -> PxText:
	h_anchor = 0
	position.x = 4.0 * floorf((region_w - width()) / 2.0 / 4.0) + region_x
	return self


## Places the text box's right edge at x (RTL rows).
func right_at(x: float) -> PxText:
	h_anchor = 2
	position.x = x
	return self


func _anchor_dx(w: float) -> float:
	return 0.0 if h_anchor == 0 else (-w if h_anchor == 2 else -floorf(w / 8.0) * 4.0)


func _draw() -> void:
	if _para != null:
		_draw_shaped()
		return
	if _ft == "":
		return
	var f: Dictionary = Art.fonts[variant]
	var tex: Texture2D = f["tex"]
	var regions: Dictionary = f["regions"]
	var cell: Vector2i = f["cell"]
	var off: Vector2i = f["offset"]
	var adv := int(Art.font_metrics["advance"]) * px
	var pitch := line_pitch if line_pitch > 0 else int(Art.font_metrics["lineHeight"]) * px
	var lines := _ft.split("\n")
	var widest := 0
	for l in lines:
		widest = maxi(widest, Art.measure(l, px))
	var ax := _anchor_dx(widest)
	var y := 0
	var gi := 0
	var has_dy := glyph_dy.is_valid()
	for l in lines:
		var x := 0
		if align == 1 or align == 2:
			var lw := Art.measure(l, px)
			x = (widest - lw) / (2 if align == 1 else 1)
			x = 4 * (x / 4) if align == 1 else x
		for i in l.length():
			var r: Variant = regions.get(l[i])
			if r != null and l[i] != " ":
				var dy: float = glyph_dy.call(gi, float(x) + ax) if has_dy else 0.0
				draw_texture_rect_region(tex, Rect2(ax + x + off.x * px, y + off.y * px + dy, cell.x * px, cell.y * px), r, tint)
			x += adv
			gi += 1
		y += pitch


## The shaped route: TextServer draws each line at font size, scaled by px through the canvas
## transform. The outline variants draw the ring as 8 one-art-px offsets under the fill.
func _draw_shaped() -> void:
	var spec: Dictionary = Art.data["font"]["variants"].get(variant, {})
	var fill := tint
	var ring := Color(0, 0, 0, 0)
	if variant == "outline" and HeFont.outline() != null:
		pass   # the ring is in the glyphs; font_color (the tint) multiplies fill and ring alike
	elif spec.get("outline") != null:
		fill = Art.col(spec["fill"]) * tint
		ring = Art.col(spec["outline"])
		ring.a *= tint.a
	var sc := _unit_px()
	var pitch := float(line_pitch) / sc if line_pitch > 0 else float(HeFont.line_height() * _u)
	var rtl := _para.direction == TextServer.DIRECTION_RTL
	var a := align if align >= 0 else (2 if rtl else 0)
	# The fork placed a 7-row capital box at the node's top. Sevev's letter body sits lower in its
	# 11-row line (ascender band above it), so lift the line until the body's centre lands where
	# the capitals' centre was: every fork text position keeps its visual line.
	var lift := float(maxi(0, HeFont.ascent() - 6)) * eff_px()
	draw_set_transform(Vector2(_anchor_dx(_box_w * sc), -lift), 0.0, Vector2(sc, sc))
	var ci := get_canvas_item()
	var ts := TextServerManager.get_primary_interface()
	var n := line_count()
	var gi := 0
	for li in n:
		var rid := _para.get_line_rid(li)
		var lw := minf(_para.get_line_width(li), _box_w)
		# centring floors in whole Sevev 9 px, so the @2 cut centres exactly where Sevev 9 does
		var x := 0.0 if a == 0 else ((_box_w - lw) if a == 2 else floorf((_box_w - lw) / (2.0 * _u)) * _u)
		var top := li * pitch
		var base := top + float(HeFont.ascent() * _u)
		if glyph_dy.is_valid():
			gi = _draw_glyphs(ts, ci, rid, Vector2(x, base), fill, ring, gi)
			continue
		if ring.a > 0.0:
			for o: Vector2 in [Vector2(-1, -1), Vector2(0, -1), Vector2(1, -1), Vector2(-1, 0), Vector2(1, 0), Vector2(-1, 1), Vector2(0, 1), Vector2(1, 1)]:
				ts.shaped_text_draw(rid, ci, Vector2(x, base) + o, -1, -1, ring)
		ts.shaped_text_draw(rid, ci, Vector2(x, base), -1, -1, fill)
	draw_set_transform(Vector2.ZERO)


## Glyph by glyph (visual order), for per-glyph offsets. Returns the next glyph index.
func _draw_glyphs(ts: TextServer, ci: RID, rid: RID, pos: Vector2, fill: Color, ring: Color, gi: int) -> int:
	var x := pos.x
	var sc := _unit_px()
	var ax := _anchor_dx(_box_w * sc)
	for g: Dictionary in ts.shaped_text_get_glyphs(rid):
		var adv := float(g["advance"])
		var reps := int(g.get("repeat", 1))
		var frid: RID = g["font_rid"]
		for _r in reps:
			if frid.is_valid() and int(g["index"]) != 0:
				var dy: float = glyph_dy.call(gi, x * sc + ax) / sc
				var p := Vector2(x, pos.y + dy) + Vector2(g["offset"])
				if ring.a > 0.0:
					for o: Vector2 in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:
						ts.font_draw_glyph(frid, ci, int(g["font_size"]), p + o, int(g["index"]), ring)
				ts.font_draw_glyph(frid, ci, int(g["font_size"]), p, int(g["index"]), fill)
			x += adv
			gi += 1
	return gi
