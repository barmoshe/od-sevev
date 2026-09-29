extends RefCounted
## Build-time pixel-width lint for every player-facing string (engine/feasibility.md O-U3,
## ux/first-minute.md §8, ux/string-budgets.json). Run: tools/lint_text.sh (tools/build_web.sh
## runs it first and fails the build on any overflow).
##
## For every key of ux/string-budgets.json:
## - surface label / pxtext with a box: substitute worstCasePlaceholders, shape with the REAL
##   text route (PxText.measure / TextServer + HeFont, bidi controls cost 0) and require the
##   string to fit the box in `lines` lines at the box scale. At scale + 1 (large text) it must
##   fit in `linesLarge` or it steps down to the base scale (reported, not a failure). Nothing
##   may need an ellipsis at the base scale; joke:true keys are listed separately because their
##   punchline is last.
## - every rendered string must have a glyph for each character in HeFont (a missing glyph
##   draws a box).
## - surface pxtext must be drawable by the bitmap route (no Hebrew, no ₪).
## - html / share-text / og: maxChars on the template without its {placeholders}.
## Producer and upgrade names (ui-strings producerNames/upgradeNames/upgradeEffects and the
## content's producers[].name / upgrades[].name) use budgets.contentNames.
## Exit code 1 on any failure.

var fails: Array[String] = []
var notes: Array[String] = []
var checked := 0


## Runs the lint; returns the exit code. (Loaded at runtime by run_lint.gd: a -s script cannot
## reference autoload-dependent classes at compile time.)
func run() -> int:
	var root := ProjectSettings.globalize_path("res://").path_join("..")
	var budgets_path := root.path_join("ux/string-budgets.json")
	var strings_path := root.path_join("ux/ui-strings.json")
	if not FileAccess.file_exists(budgets_path):
		print("[lint_text] no ux/string-budgets.json: nothing to lint")
		return 0
	var budgets: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(budgets_path))
	var ui: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(strings_path))
	var boxes: Dictionary = budgets.get("boxes", {})
	var worst: Dictionary = budgets.get("worstCasePlaceholders", {})
	var per_key: Dictionary = budgets.get("strings", {})
	var strs: Dictionary = ui.get("strings", {})
	print("[lint_text] font: %s" % HeFont.source())
	for key: String in per_key:
		var b: Dictionary = per_key[key]
		if not strs.has(key):
			fails.append("%s: budgeted but missing from ui-strings.json" % key)
			continue
		_lint_one(key, String(strs[key]), b, boxes, worst)
	for key: String in strs:
		if not per_key.has(key):
			notes.append("%s: no budget entry (not linted)" % key)
	# names from ui-strings and the content
	var cn: Dictionary = budgets.get("contentNames", {})
	var name_box := String(cn.get("box", "card.name"))
	var eff_box := String(cn.get("effectBox", "card.line2wide"))
	for group: String in ["producerNames", "upgradeNames"]:
		var g: Dictionary = ui.get(group, {})
		for id: String in g:
			_lint_one("%s.%s" % [group, id], String(g[id]), {"surface": "label", "box": name_box}, boxes, worst)
	var eff: Dictionary = ui.get("upgradeEffects", {})
	for id: String in eff:
		_lint_one("upgradeEffects.%s" % id, String(eff[id]), {"surface": "label", "box": eff_box}, boxes, worst)
	for p: Dictionary in Content.producers():
		if p.has("name") and Bidi.has_rtl(String(p["name"])):
			_lint_one("content.producers.%s.name" % p["id"], String(p["name"]), {"surface": "label", "box": name_box}, boxes, worst)
	for u: Dictionary in Content.upgrades():
		if u.has("name") and Bidi.has_rtl(String(u["name"])):
			_lint_one("content.upgrades.%s.name" % u["id"], String(u["name"]), {"surface": "label", "box": name_box}, boxes, worst)
	# the narrator's story beats (content copy on the story card: the budgets' modal.body box)
	var story: Dictionary = Content.data().get("story", {})
	var bi := 0
	for beat: Variant in story.get("beats", []):
		bi += 1
		var li := 0
		for line: Variant in (beat as Array if beat is Array else [beat]):
			li += 1
			_lint_one("content.story.beats[%d][%d]" % [bi, li], str(line), {"surface": "label", "box": "modal.body"}, boxes, worst)
	for n in notes:
		print("  note  ", n)
	for f in fails:
		print("  FAIL  ", f)
	print("[lint_text] %d strings checked, %d failures, %d notes" % [checked, fails.size(), notes.size()])
	return 1 if not fails.is_empty() else 0


func _fill(t: String, worst: Dictionary) -> String:
	var out := t
	var re := RegEx.create_from_string("\\{([A-Za-z_]+)\\}")
	for m in re.search_all(t):
		var k := m.get_string(1)
		out = out.replace("{" + k + "}", String(worst.get(k, "9999")))
	return out


func _lint_one(key: String, text: String, b: Dictionary, boxes: Dictionary, worst: Dictionary) -> void:
	var surface := String(b.get("surface", "label"))
	if surface == "unused" or text == "":
		return
	checked += 1
	if surface in ["html", "share-text", "og"]:
		var mc := int(b.get("maxChars", 0))
		var bare := RegEx.create_from_string("\\{[A-Za-z_]+\\}").sub(Bidi.strip_controls(text), "", true)
		if mc > 0 and bare.length() > mc:
			fails.append("%s: %d chars > maxChars %d (%s)" % [key, bare.length(), mc, surface])
		return
	var t := _fill(text, worst)
	var miss := HeFont.missing_glyphs(t)
	if not miss.is_empty():
		fails.append("%s: the font has no glyph for %s" % [key, " ".join(miss)])
	if surface == "pxtext" and (Bidi.has_rtl(t) or t.contains(Bidi.SHEKEL)):
		fails.append("%s: surface pxtext but holds Hebrew or ₪ (PxText has no bidi)" % key)
	var box_id := String(b.get("box", ""))
	if box_id == "" or not boxes.has(box_id):
		if box_id != "":
			fails.append("%s: unknown box %s" % [key, box_id])
		return
	var box: Dictionary = boxes[box_id]
	if box.get("widthPx") == null:
		return
	var w := float(box["widthPx"])
	var sc := int(box.get("scale", 3))
	var lines := int(box.get("lines", 1))
	var need := _lines_needed(t, w, sc)
	var joke := " (joke: punchline last)" if bool(b.get("joke", false)) else ""
	if need > lines:
		fails.append("%s: needs %d line(s) in %s (%d px at x%d, %d line(s) allowed), %d px wide%s" % [key, need, box_id, int(w), sc, lines, PxText.measure(t, sc), joke])
		return
	var lines_l := int(box.get("linesLarge", lines))
	if _lines_needed(t, w, sc + 1) > lines_l:
		notes.append("%s: large text steps down to x%d in %s" % [key, sc, box_id])


## Lines a string needs in a box of w px at scale sc (99 when a single word is wider than the box).
func _lines_needed(t: String, w: float, sc: int) -> int:
	var total := 0
	for para in t.split("\n"):
		if PxText.measure(para, sc) <= w:
			total += 1
			continue
		var p := TextParagraph.new()
		p.direction = TextServer.DIRECTION_RTL if Bidi.paragraph_rtl(para) else TextServer.DIRECTION_LTR
		p.break_flags = TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND
		p.width = floorf(w / float(sc))
		p.add_string(para, HeFont.font(), HeFont.size())
		for i in p.get_line_count():
			if p.get_line_width(i) > p.width + 0.01:
				return 99   # an unbreakable word wider than the box
		total += p.get_line_count()
	return total
