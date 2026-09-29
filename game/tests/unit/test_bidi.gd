extends RefCounted
## Hebrew number tokens (ux/first-minute.md §3.5, engine/feasibility.md U6): numbers are LTR
## tokens inside RTL text, ₪ follows the number in reading order and shows to its LEFT, and the
## isolates cost no width. Shaping goes through the real TextServer with HeFont, the same path
## PxText draws with.

var runner: Object


## Visual left-to-right characters of a shaped single-line string (bitmap glyph index = code).
func _visual(t: String) -> String:
	var tl := TextLine.new()
	tl.direction = TextServer.DIRECTION_RTL if Bidi.paragraph_rtl(t) else TextServer.DIRECTION_LTR
	tl.add_string(t, HeFont.font(), HeFont.size())
	var ts := TextServerManager.get_primary_interface()
	var out := ""
	for g: Dictionary in ts.shaped_text_get_glyphs(tl.get_rid()):
		var c := int(g["index"])
		if c > 0 and float(g["advance"]) > 0.0 and c != 0x20 and c != 0xA0:
			out += char(c)
	return out


func _width(t: String) -> float:
	var tl := TextLine.new()
	tl.direction = TextServer.DIRECTION_RTL if Bidi.paragraph_rtl(t) else TextServer.DIRECTION_LTR
	tl.add_string(t, HeFont.font(), HeFont.size())
	return tl.get_line_width()


func test_tokens_are_isolated() -> void:
	runner.check(Bidi.num("12.4K") == "\u206612.4K\u2069", "num wraps in LRI…PDI")
	runner.check(Bidi.num(Bidi.num("7")) == Bidi.num("7"), "num is idempotent")
	runner.check(Bidi.money("12.4K") == "\u206612.4K\u2069\u00a0₪", "money: number, NBSP, then ₪ (reading order)")


func test_number_token_detection() -> void:
	for t: String in ["12.4K", "58/61", "−5", "+1.2K", "0:45", "412K", "1,234", "18%", "×3", "1.23aa"]:
		runner.check(Bidi.is_number_token(t), "%s is a number token" % t)
	for t: String in ["מנדטים", "K", "", "₪", "5 מנדטים"]:
		runner.check(not Bidi.is_number_token(t), "'%s' is not a number token" % t)
	runner.check(Bidi.is_numeric("12.4K ₪") and Bidi.is_numeric(Bidi.money("3M")), "a price is purely numeric")
	runner.check(not Bidi.is_numeric("+1 ₪ לשנייה"), "a Hebrew line is not purely numeric")


func test_fill_isolates_numbers_only_in_rtl() -> void:
	var he := Bidi.fill("{n} ₪ לשנייה", {"n": "+1.2K"})
	runner.check(he == "\u2066+1.2K\u2069 ₪ לשנייה", "a Hebrew template isolates the number, got %s" % he.c_escape())
	var he2 := Bidi.fill("עוד {name} · {n}", {"name": "משלם", "n": "15"})
	runner.check(he2 == "עוד משלם · \u206615\u2069", "text values stay as they are, got %s" % he2.c_escape())
	runner.check(Bidi.fill("{n}/S", {"n": "12"}) == "12/S", "LTR templates are filled verbatim")
	var pre := Bidi.fill("\u2066+{rate}\u2069\u00a0₪ לשנייה", {"rate": "1.2K"})
	runner.check(pre == "\u2066+1.2K\u2069\u00a0₪ לשנייה", "an already-isolated placeholder is not wrapped again (rtl-map §0), got %s" % pre.c_escape())


func test_rtl_price_puts_shekel_left_of_the_number() -> void:
	var v := _visual(Bidi.money("12.4K"))
	runner.check(v == "₪12.4K", "RTL price reads '₪ 12.4K' on screen, got '%s'" % v)
	var line := _visual(Bidi.fill("{n} ₪ לשנייה", {"n": "+1.2K"}))
	runner.check(line.ends_with("+1.2K"), "the rate's number keeps its sign in front and sits at the right end, got '%s'" % line)
	runner.check(line.begins_with("היינשל"), "the Hebrew word is on the left, drawn in visual order, got '%s'" % line)


func test_isolates_keep_fractions_and_signs() -> void:
	var seats := _visual("מנדטים " + Bidi.num("58/61"))
	runner.check(seats.begins_with("58/61"), "'58/61' stays one LTR token at the line's left end, got '%s'" % seats)
	runner.check(seats.ends_with("םיטדנמ"), "the label is on the right, got '%s'" % seats)
	var minus := _visual("חשד " + Bidi.num("−5"))
	runner.check(minus.begins_with("−5"), "a minus stays in front of its number, got '%s'" % minus.c_escape())
	var clock := _visual("עוד " + Bidi.num("0:45"))
	runner.check(clock.begins_with("0:45"), "a timer keeps its order, got '%s'" % clock)


func test_isolates_have_no_width() -> void:
	runner.check(is_equal_approx(_width(Bidi.num("12")), _width("12")), "LRI/PDI add no width")
	runner.check(_width("12") > 0.0, "digits have width")


func test_font_covers_the_hud_glyph_range() -> void:
	# ux/first-minute.md §3.5 glyph range, minus what the stand-in draft lacks (logged for the TA)
	var must := "אבגדהוזחטיכךלמםנןסעפףצץקרשת0123456789.,:/+%()!?₪…·" + "−×←־׳״" + "KMBT"
	var miss := HeFont.missing_glyphs(must)
	runner.check(miss.is_empty(), "HeFont (%s) has every HUD glyph, missing %s" % [HeFont.source(), ", ".join(miss)])


func test_pxtext_routes() -> void:
	runner.check(PxText.bitmap_ok("12.4K") == PxText.BITMAP_ROUTE, "a pure number takes the bitmap route only when it is switched on")
	runner.check(not PxText.bitmap_ok("מנדטים"), "Hebrew takes the shaped route")
	runner.check(not PxText.bitmap_ok(Bidi.num("12")), "bidi controls take the shaped route")
	runner.check(PxText.measure("מנדטים", 3) == int(ceilf(_width("מנדטים"))) * 3, "shaped width is the TextServer width × scale")


func test_icu_plural_numbers_are_isolated() -> void:
	var t := "עוד {d, plural, one {יום אחד} two {יומיים} other {# ימים}} לבחירות."
	runner.check(Ambient.icu(t, {"d": 1}) == "עוד יום אחד לבחירות.", "one")
	runner.check(Ambient.icu(t, {"d": 2}) == "עוד יומיים לבחירות.", "two")
	var other := Ambient.icu(t, {"d": 28})
	runner.check(other == "עוד " + Bidi.num("28") + " ימים לבחירות.", "other: # is an LTR token, got %s" % other.c_escape())
