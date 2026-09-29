class_name HeFont
extends RefCounted
## The Hebrew pixel font as a Godot FontFile, for the TextServer route (engine/feasibility.md
## O-U2: Label/TextServer bidi, never pre-reordered text).
##
## Source, first match wins:
## 1. The Technical Artist's BMFont "Sevev 9" (res://assets/fonts/sevev9.fnt, the loader
##    contract in res://assets/sprites/CONTRACT.md §6; else the first .fnt there). Godot imports
##    a .fnt as a FontFile with its fixed size (9) and integer-only scaling.
## 2. The stand-in built here at boot from SevevGlyphs (the approved "Sevev 5x9" draft) plus the
##    fork's 5x7 Latin capitals from art.json for any character the draft lacks.
##
## Metrics (both sources): one art px per font unit at `size()`; line height 11; advance =
## glyph width + 1, space 4 (the .fnt xadvance values are the truth). The TA's font puts the
## baseline 8 below the line top (glyph rows start 1 px down); the stand-in uses 7. PxText draws the font at size() and scales
## by its integer px, so every stroke stays on the pixel grid (O-U3: no fractional sizes).

const FONT_DIR := "res://assets/fonts/"
const PREFERRED_FILE := "sevev9.fnt"
const SIZE := 9
## Zero-width controls every font must map to an empty glyph (a missing glyph would draw a box).
const ZERO_WIDTH := [0x2066, 0x2067, 0x2068, 0x2069, 0x200E, 0x200F, 0x200B, 0x200C, 0x200D, 0x2060, 0xFEFF]

const OUTLINE_FILE := "sevev9_outline.fnt"

static var _font: FontFile
static var _outline: FontFile
static var _outline_loaded := false
static var _source := ""
static var _size := SIZE
static var _ascent := 7
static var _line_h := 11


static func font() -> FontFile:
	if _font == null:
		_load()
	return _font


## The TA's outline cut (white fill, baked 1-px ink ring, the same advances and line height), or
## null with the stand-in font. Used for PxText's "outline" variant over art.
static func outline() -> FontFile:
	if not _outline_loaded:
		_outline_loaded = true
		font()
		if _source.begins_with("ta:") and ResourceLoader.exists(FONT_DIR + OUTLINE_FILE):
			var f: Variant = load(FONT_DIR + OUTLINE_FILE)
			if f is FontFile and (f as FontFile).fixed_size == _size:
				_outline = f
				_outline.fixed_size_scale_mode = TextServer.FIXED_SIZE_SCALE_INTEGER_ONLY
				_outline.allow_system_fallback = false
	return _outline


## The font size to shape at (the bitmap's own size: never scaled by TextServer).
static func size() -> int:
	font()
	return _size


static func ascent() -> int:
	font()
	return _ascent


static func line_height() -> int:
	font()
	return _line_h


## "ta:<file>" or "standin" (for the settings report and tests).
static func source() -> String:
	font()
	return _source


static func _load() -> void:
	var fnt := _find_ta_font()
	if fnt != "":
		var f: Variant = load(fnt)
		if f is FontFile and (f as FontFile).fixed_size > 0:
			_font = f
			_font.fixed_size_scale_mode = TextServer.FIXED_SIZE_SCALE_INTEGER_ONLY
			_font.allow_system_fallback = false
			_size = _font.fixed_size
			_ascent = int(roundf(_font.get_ascent(_size)))
			_line_h = int(roundf(_font.get_height(_size)))
			_source = "ta:" + fnt.get_file()
			return
		push_warning("[font] %s is not a bitmap FontFile; using the stand-in" % fnt)
	_font = _build_standin()
	_source = "standin"


static func _find_ta_font() -> String:
	if ResourceLoader.exists(FONT_DIR + PREFERRED_FILE):
		return FONT_DIR + PREFERRED_FILE
	var d := DirAccess.open(FONT_DIR)
	if d == null:
		return ""
	var names := Array(d.get_files())
	names.sort()
	for n: String in names:
		# an exported build lists the import stubs, not the sources
		var base := n.trim_suffix(".import").trim_suffix(".remap")
		if base.get_extension() == "fnt" and ResourceLoader.exists(FONT_DIR + base):
			return FONT_DIR + base
	return ""


static func _build_standin() -> FontFile:
	var glyphs := {}
	for ch: String in SevevGlyphs.GLYPHS:
		glyphs[ch] = SevevGlyphs.GLYPHS[ch]
	# the fork's Latin capitals (5x7, rows 0-6: the same band as the Hebrew ascender + body)
	var latin: Dictionary = Art.data.get("font", {}).get("glyphs", {})
	for ch: String in latin:
		if not glyphs.has(ch) and ch.length() == 1:
			var rows: Array = (latin[ch] as Array).duplicate()
			var w := String(rows[0]).length() if not rows.is_empty() else 1
			while rows.size() < SevevGlyphs.CELL_H:
				rows.append(".".repeat(w))
			glyphs[ch] = rows
	for c in range(0x61, 0x7B):   # lowercase Latin draws as the capital ("DOHA" either way)
		var lo := char(c)
		if not glyphs.has(lo) and glyphs.has(lo.to_upper()):
			glyphs[lo] = glyphs[lo.to_upper()]
	var chars: Array = glyphs.keys()
	chars.sort()
	var cell_h := SevevGlyphs.CELL_H
	var total_w := 1
	for ch: String in chars:
		total_w += String(glyphs[ch][0]).length() + 1
	var img := Image.create_empty(total_w, cell_h + 2, false, Image.FORMAT_LA8)
	var f := FontFile.new()
	f.fixed_size = SIZE
	f.fixed_size_scale_mode = TextServer.FIXED_SIZE_SCALE_INTEGER_ONLY
	f.allow_system_fallback = false
	f.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	f.hinting = TextServer.HINTING_NONE
	f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	f.generate_mipmaps = false
	var sz := Vector2i(SIZE, 0)
	f.set_cache_ascent(0, SIZE, SevevGlyphs.ASCENT)
	f.set_cache_descent(0, SIZE, SevevGlyphs.LINE_H - SevevGlyphs.ASCENT)
	var x := 1
	for ch: String in chars:
		var rows: Array = glyphs[ch]
		var w := String(rows[0]).length()
		for yy in cell_h:
			var r := String(rows[yy]) if yy < rows.size() else ""
			for xx in mini(w, r.length()):
				if r[xx] == "#":
					img.set_pixel(x + xx, 1 + yy, Color(1, 1, 1, 1))
		var gi := ch.unicode_at(0)
		f.set_glyph_advance(0, SIZE, gi, Vector2(w + 1, 0))
		f.set_glyph_offset(0, sz, gi, Vector2(0, -SevevGlyphs.ASCENT))
		f.set_glyph_size(0, sz, gi, Vector2(w, cell_h))
		f.set_glyph_uv_rect(0, sz, gi, Rect2(x, 1, w, cell_h))
		f.set_glyph_texture_idx(0, sz, gi, 0)
		x += w + 1
	for gi: int in [0x20, 0xA0]:
		f.set_glyph_advance(0, SIZE, gi, Vector2(SevevGlyphs.SPACE_ADVANCE, 0))
		f.set_glyph_offset(0, sz, gi, Vector2.ZERO)
		f.set_glyph_size(0, sz, gi, Vector2.ZERO)
		f.set_glyph_uv_rect(0, sz, gi, Rect2())
		f.set_glyph_texture_idx(0, sz, gi, -1)
	for gi: int in ZERO_WIDTH:
		f.set_glyph_advance(0, SIZE, gi, Vector2.ZERO)
		f.set_glyph_offset(0, sz, gi, Vector2.ZERO)
		f.set_glyph_size(0, sz, gi, Vector2.ZERO)
		f.set_glyph_uv_rect(0, sz, gi, Rect2())
		f.set_glyph_texture_idx(0, sz, gi, -1)
	f.set_texture_image(0, sz, 0, img)
	_size = SIZE
	_ascent = SevevGlyphs.ASCENT
	_line_h = SevevGlyphs.LINE_H
	return f


## True when the font has ink for every visible character of `text` (the lint's glyph check).
static func missing_glyphs(text: String) -> PackedStringArray:
	var f := font()
	var out := PackedStringArray()
	for i in text.length():
		var c := text.unicode_at(i)
		if c == 0x20 or c == 0xA0 or c == 0x0A or ZERO_WIDTH.has(c):
			continue
		if not f.has_char(c) and not out.has(text[i]):
			out.append(text[i])
	return out
