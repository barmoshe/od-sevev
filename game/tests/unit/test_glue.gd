extends RefCounted
## ux/mobile-first-layout.md §5.2.1 (D49, review 2026-09-30 U16), the no-break rule: a currency sign
## stays with what it measures and punctuation with its word (strong glue, never broken); a number
## stays with its magnitude word (weak glue, broken only when the unit is wider than the line). Spaces
## inside a unit become U+00A0 at display time, in the ticker pager and in every wrapping PxText.

var runner: Object
const NB := " "
const CLOSE := ".,:;!?…)]"


func setup(_r: Object) -> void:
	TestFixture.use_game_content()


## (a) the Animator's case: "₪." never opens a line, at every width from the unit's own to 464.
func test_the_shekel_never_opens_a_line() -> void:
	var t := "הקופה עברה 100,000 ₪."
	var unit := PxText.measure("100,000" + NB + "₪.", 4)
	var bad := 0
	var w := float(unit)
	while w <= 464.0:
		for l in Ticker.wrap_lines_px(Bidi.glue(t), w, 4):
			if l.strip_edges().begins_with("₪"):
				bad += 1
		w += 4.0
	runner.check(bad == 0, "no line starts with ₪ from %d to 464 (%d bad)" % [unit, bad])
	runner.check(Bidi.glue(t) == "הקופה עברה 100,000" + NB + "₪.", "G1: the space before ₪ is glued")


func test_the_rules() -> void:
	runner.check(Bidi.glue("₪ 15 לכל אחד") == "₪" + NB + "15 לכל אחד", "G1: a prefix ₪ keeps its number")
	runner.check(Bidi.glue("אמר משהו .") == "אמר משהו" + NB + ".", "G2: a lone closing mark keeps its word")
	runner.check(Bidi.glue("( בערך ) היום") == "(" + NB + "בערך" + NB + ") היום", "G2 + G3: brackets keep their word")
	runner.check(Bidi.glue("עלה 850.6 מיליארד ₪.") == "עלה 850.6" + NB + "מיליארד" + NB + "₪.", "G4 (weak) + G1")
	runner.check(Bidi.glue("עלה 850.6 מיליארד ₪.", false) == "עלה 850.6 מיליארד" + NB + "₪.", "strong only: the weak joint stays a space")
	runner.check(Bidi.glue("הקופה עברה מיליארד ₪.") == "הקופה עברה מיליארד" + NB + "₪.", "a magnitude word as a noun: only its ₪ is glued")
	runner.check(Bidi.glue("אמר \" שלום \" והלך") == "אמר \"" + NB + "שלום" + NB + "\" והלך", "a quote pair: the first opens, the second closes")
	runner.check(Bidi.glue("בלי שום דבק") == "בלי שום דבק", "plain words: untouched")


## (c) idempotent, and an isolate is never touched.
func test_idempotent_and_isolates_untouched() -> void:
	var iso := Bidi.LRI + "12 / 61" + Bidi.PDI + " ₪ ."
	var g := Bidi.glue(iso)
	runner.check(g.begins_with(Bidi.LRI + "12 / 61" + Bidi.PDI), "the spaces inside LRI…PDI stay (got %s)" % g.c_escape())
	runner.check(g == Bidi.LRI + "12 / 61" + Bidi.PDI + NB + "₪" + NB + ".", "outside the isolate the glue applies")
	for t: String in ["הקופה עברה 100,000 ₪.", "( בערך ) היום", "עלה 850.6 מיליארד ₪.", iso, "אמר \" שלום \" והלך"]:
		runner.check(Bidi.glue(Bidi.glue(t)) == Bidi.glue(t), "glue(glue(x)) == glue(x): %s" % t)
	runner.check(Bidi.glue(Bidi.money("12.4K")) == Bidi.money("12.4K"), "a price is already one unit")


## The fallback: a unit wider than the line breaks at its weak joint first, never before ₪, and no
## text is lost.
func test_a_unit_wider_than_the_line_falls_back_to_its_weak_joint() -> void:
	var t := "עלה 850.6 מיליארד ₪."
	var unit := PxText.measure("850.6" + NB + "מיליארד" + NB + "₪.", 4)
	var w := float(unit - 8)
	var lines := Ticker.wrap_lines_px(Bidi.glue(t), w, 4)
	var joined := " ".join(lines).replace(NB, " ")
	runner.check(joined == t, "nothing is lost (%s)" % " | ".join(lines))
	var ok := true
	for l in lines:
		ok = ok and not l.strip_edges().begins_with("₪")
	runner.check(ok and lines.size() >= 2, "it breaks at the weak joint, never before ₪ (%s)" % " | ".join(lines))


## (b) every ticker line in content.json at the four clips: no line starts with ₪ or a closing mark,
## none ends with an opening one (a weak-joint fallback may still start with a magnitude word).
func test_every_ticker_line_keeps_its_units() -> void:
	var texts: Array = []
	_walk(Content.data(), false, texts)
	texts = texts.filter(func(t: String) -> bool: return t != "" and not t.contains("{"))
	runner.check(texts.size() > 100, "the ticker lines are found (%d)" % texts.size())
	var bad: Array = []
	for clip: float in [280.0, 324.0, 384.0, 464.0]:
		for t: String in texts:
			var pages: Array = Ticker.paginate(t, clip, 4, 2)
			for pg: Variant in pages:
				for l: String in pg:
					var s := l.strip_edges()
					if s == "":
						continue
					if s.begins_with("₪") or CLOSE.contains(s[0]) or "([„".contains(s[s.length() - 1]):
						bad.append("%d: %s" % [int(clip), s])
	runner.check(bad.is_empty(), "no line opens with ₪ or a closing mark (%d: %s)" % [bad.size(), str(bad.slice(0, 4))])


## A wrapping PxText breaks the same way: "₪." stays on the number's line.
func test_a_wrapping_text_keeps_the_shekel_with_its_number() -> void:
	var p := PxText.new()
	p.px = 4
	p.text = "הקופה עברה 100,000 ₪."
	p.wrap_width = float(PxText.measure("הקופה עברה 100,000", 4) + 8)
	p.max_lines = 3
	var ls: Array = p.line_layout()
	var starts_shekel := false
	for l: Variant in ls:
		var r: Vector2i = (l as Array)[0]
		if r.y > r.x and p.text.substr(r.x, r.y - r.x).strip_edges().begins_with("₪"):
			starts_shekel = true
	runner.check(p.line_count() >= 2 and not starts_shekel, "the unit moves down whole (%d lines)" % p.line_count())
	p.free()


func _walk(v: Variant, in_ticker: bool, out: Array) -> void:
	if v is Dictionary:
		for k: Variant in v:
			var key := str(k)
			if key.begins_with("_"):
				continue
			var val: Variant = v[k]
			var tick := in_ticker or key in ["headlines", "ambientHeadlines", "ambientHeadlinesV2"]
			if key == "text" and in_ticker and val is String:
				out.append(val)
			elif key in ["ticker", "tickerStart", "onPaidTicker"] and val is String:
				out.append(val)
			else:
				_walk(val, tick, out)
	elif v is Array:
		for x: Variant in v:
			if x is String and in_ticker:
				out.append(x)
			else:
				_walk(x, in_ticker, out)
