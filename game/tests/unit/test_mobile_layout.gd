extends RefCounted
## Mobile-first layout (ux/mobile-first-layout.md §2-§5.12, §8.7): the engine's layout math against
## the UX Designer's reference calculator (ux/tools/mobile_layout.py --json, frozen in
## tests/fixtures/mobile_layout.json: regenerate it with that command when the spec's numbers
## move), device by device of the matrix; then the real scene booted at phone backing stores.

var runner: Object
var tree: SceneTree
var dir := ""
var sv: SubViewport
var m: Node
var _saved := {}


func setup(r: Object) -> void:
	tree = r as SceneTree
	dir = "user://test_mobile_%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(dir)
	_saved = {"S": L.stage_h, "P": L.panel_h, "n": L.rows_whole, "cw": L.cw, "tabs": L.tabs_up}


func teardown() -> void:
	if m and is_instance_valid(m):
		m.set_process(false)
	if sv and is_instance_valid(sv):
		sv.get_parent().remove_child(sv)
		sv.queue_free()
	Display.update(Vector2(720, 1280))   # the default k 4, f 1 for the tests after this one
	L.stage_h = _saved["S"]
	L.panel_h = _saved["P"]
	L.rows_whole = _saved["n"]
	L.set_width(_saved["cw"])
	L.tabs_up = _saved["tabs"]
	TestFixture.use_game_content()
	var d := DirAccess.open(dir)
	if d:
		for f in d.get_files():
			d.remove(f)
	DirAccess.remove_absolute(dir)


static func _matrix() -> Array:
	var j: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/mobile_layout.json"))
	return j if j is Array else []


static func _v(a: Variant) -> Vector2:
	return Vector2(float(a[0]), float(a[1]))


func test_the_matrix_fixture_is_the_spec_matrix() -> void:
	var rows := _matrix()
	runner.check(rows.size() >= 12, "the calculator's matrix is readable (%d devices)" % rows.size())


## §2 / §0.1: k unchanged (crisp(min(floor(W/180), floor(H/267)))), the art grid, cw and dx.
func test_scale_grid_and_width_per_device() -> void:
	for row: Dictionary in _matrix():
		var dev := _v(row["device"])
		var name := str(row["name"])
		runner.check(Display.art_px_for(dev) == int(row["k"]), "%s: k %d (got %d)" % [name, int(row["k"]), Display.art_px_for(dev)])
		Display.update(dev)
		runner.check(Display.cols == int(row["cols"]) and Display.rows == int(row["rows"]), "%s: the art grid %d × %d (got %d × %d)" % [name, int(row["cols"]), int(row["rows"]), Display.cols, Display.rows])
		var vs := Display.logical_size(dev)
		L.set_width(L.canvas_w(Display.cw(), vs))
		runner.check(L.cw == float(row["cw"]) and L.dx == float(row["delta"]), "%s: cw %d, dx %d (got %d, %d)" % [name, int(row["cw"]), int(row["delta"]), L.cw, L.dx])
		runner.check(L.sox() == L.floor4(float(row["delta"]) / 2.0), "%s: the stage column at floor4(dx/2) = %d" % [name, L.sox()])


## §3.2: the bottom-up split: S, P, whole card rows and the peek, the reach guard included.
func test_split_per_device() -> void:
	for row: Dictionary in _matrix():
		var name := str(row["name"])
		var ins: Array = row["insets"]
		var vh := L.floor4(float(row["logical"][1]))
		var r := vh - float(ins[0]) - float(ins[1]) - float(L.FIXED_H)
		runner.check(r == float(row["R"]), "%s: R %d (got %d)" % [name, int(row["R"]), r])
		var sp := L.split(r, float(ins[0]), vh)
		runner.check(float(sp["S"]) == float(row["S"]) and float(sp["P"]) == float(row["P"]) and int(sp["n"]) == int(row["rowsWhole"]),
			"%s: S %d, P %d, %d rows (got %s)" % [name, int(row["S"]), int(row["P"]), int(row["rowsWhole"]), str(sp)])
		var peek := float(sp["P"]) - float(sp["n"]) * L.CARD
		runner.check(peek <= float(L.PEEK) and peek == float(row["peek"]), "%s: the peek %d ≤ 40 (a cut card never shows its pill)" % [name, int(peek)])
		L.set_split(r, float(ins[0]), vh)
		var lower := float(ins[0]) + float(L.ROW_A_H + L.ROW_B_H) + L.stage_h
		runner.check(lower == float(row["lowerY"]), "%s: lowerY %d (got %d)" % [name, int(row["lowerY"]), lower])
		L.tabs_up = true
		runner.check(lower + L.tabs_y() == float(row["tabsY"]), "%s: the tab bar top %d (got %d)" % [name, int(row["tabsY"]), lower + L.tabs_y()])
		runner.check(lower + L.tabs_y() + float(L.TABS_H) == vh - float(ins[1]), "%s: the tab bar sits on the safe bottom" % name)
		L.tabs_up = false
		runner.check(L.tabs_y() - float(L.SHOP["listY"]) == float(row["pane_before_c1"]), "%s: before C1 the pane runs under the tab slot (%d)" % [name, int(row["pane_before_c1"])])
		L.tabs_up = true
		var stage_hit_bottom := lower - 140.0
		if int(row["rowsWhole"]) > 3:
			runner.check(stage_hit_bottom >= 0.40 * vh, "%s: reach guard: the leader's hit bottom at %d%% ≥ 40%%" % [name, int(100.0 * stage_hit_bottom / vh)])


## §5.3: four fluid slots right → left, the remainder to slot 4, the whole slot is the hit.
func test_tab_slots_per_device() -> void:
	for row: Dictionary in _matrix():
		L.set_width(float(row["cw"]))
		var w := L.floor4(L.cw / 4.0)
		var s1 := L.tab_rect(1)
		var s4 := L.tab_rect(4)
		runner.check(s1.end.x == L.cw and s1.size.x == w and s4.position.x == 0.0, "%s: slot 1 ends at cw %d, slot 4 starts at 0 (w %d)" % [row["name"], int(L.cw), int(w)])
		var covered := 0.0
		for i in range(1, 5):
			covered += L.tab_rect(i).size.x
			runner.check(L.tab_rect(i).size.x >= 180.0 and L.tab_rect(i).size.y == 104.0, "%s: slot %d is ≥ 180 × 104" % [row["name"], i])
		runner.check(covered == L.cw, "%s: the slots cover the canvas" % row["name"])


## §5.8: the picker's tiles, avatar and tile height (the table's first / after columns).
func test_picker_plan_per_device() -> void:
	for row: Dictionary in _matrix():
		var ins: Array = row["insets"]
		var H := L.floor4(float(row["logical"][1])) - float(ins[0]) - float(ins[1])
		for v in ["first", "after"]:
			var want: Dictionary = row["pickFirst" if v == "first" else "pickAfter"]
			var got := PickView.grid_plan(H, float(row["cw"]), int(row["k"]), v)
			runner.check(float(got["tw"]) == float(want["tw"]) and float(got["A"]) == float(want["A"]) and float(got["th"]) == float(want["th"]) and float(got["avail"]) == float(want["avail"]),
				"%s %s: tw %d, A %d, th %d, avail %d (got %s)" % [row["name"], v, int(want["tw"]), int(want["A"]), int(want["th"]), int(want["avail"]), str(got)])


## §5.2: the ticker clip is 324 + dx (the anchor R-anchored at 700 + dx, the clip from x 192).
func test_ticker_clip_per_device() -> void:
	var dubi := Rect2(-40, -88, 80, 92)   # chars.dubi 20×23 art, anchor [10, 22], at ×4
	var tag_w := float(PxText.measure(Strings.s("TICKER_TAG"), 4))
	for row: Dictionary in _matrix():
		var lay := Ticker.anchor_layout(tag_w, dubi, float(row["delta"]))
		var clip := float(lay["clipX1"]) - float(L.TICKER["clipX0"])
		runner.check(clip == float(row["clip"]), "%s: the clip is %d wide (got %d)" % [row["name"], int(row["clip"]), clip])
		runner.check(float(lay["textRight"]) == 700.0 + float(row["delta"]), "%s: the tag right-aligned at 700 + dx" % row["name"])


## §5.2: pages of two lines, whole words, each line inside the clip.
func test_the_pager_never_splits_a_word() -> void:
	var text := "ההייטקיסטים יוצאים לרחובות שוב, והפעם עם שלטים חדשים ועם כובע"
	for clip: float in [280.0, 324.0, 464.0]:
		var pages := Ticker.paginate(text, clip, 4, 2)
		var words: Array = []
		for pg: Variant in pages:
			runner.check((pg as PackedStringArray).size() <= 2, "a page holds ≤ 2 lines")
			for ln: String in pg:
				runner.check(PxText.measure(ln, 4) <= int(clip), "'%s' fits the %d clip" % [ln, int(clip)])
				words.append_array(Array(ln.split(" ")))
		runner.check(" ".join(words) == text, "clip %d: the words, in order, none split" % int(clip))
	# M1 (the Animator) retunes the dwell by page length: floors 2.0 s / 4.5 s (ftue), caps 5.5 / 7.0 s
	runner.check(Ticker.dwell_ms(PackedStringArray(["קצר"]), "flavor") == 2000.0 and Ticker.dwell_ms(PackedStringArray(["קצר"]), "ftue") == 4500.0, "dwell floors 2.0 s / 4.5 s (ftue)")
	runner.check(Ticker.dwell_ms(PackedStringArray(["x".repeat(30)]), "flavor") == 3300.0, "1.2 s + 70 ms a character above the floor")
	runner.check(Ticker.dwell_ms(PackedStringArray(["x".repeat(100)]), "flavor") == 5500.0, "capped at 5.5 s")


## §5.10-§5.12: modal growth and the share preview scale.
func test_modal_and_share_per_device() -> void:
	for row: Dictionary in _matrix():
		var dev := _v(row["device"])
		Display.update(dev)
		L.set_width(float(row["cw"]))
		var mw := float(SheetCard.CARD_W) + 2.0 * SheetCard.grow_half()
		# Bar's width rule (2026-09-30) supersedes §5.10's 624 + min(dx, 64): ≥ 92% of the canvas, the
		# body text still ≤ 624
		runner.check(mw >= 0.92 * L.cw and mw <= L.cw - 40.0, "%s: the modal card %d wide, ≥ 92%% of cw %d" % [row["name"], int(mw), int(L.cw)])
		runner.check(SheetCard.body_w() <= 624.0, "%s: the modal body stays ≤ 624" % row["name"])
		var ins: Array = row["insets"]
		var sheet := L.floor4(float(row["logical"][1])) - float(ins[0]) - float(ins[1])
		var a := ShareSheet.preview_scale(sheet - 520.0, float(row["cw"]) - 32.0)
		runner.check(absf(a - float(row["sharePreview"])) < 0.01, "%s: the share preview at a = %.3f (got %.3f)" % [row["name"], float(row["sharePreview"]), a])


# ------------------------------------------------------------------ the real scene

func _boot_device(dev: Vector2i) -> void:
	TestFixture.use_game_content()
	sv = SubViewport.new()
	sv.size = dev
	tree.root.add_child(sv)
	m = load("res://scenes/main.tscn").instantiate()
	m.store = SaveStore.new(dir)
	sv.add_child(m)
	for i in 3:
		await tree.process_frame


func _check_booted(dev: Vector2i, name: String) -> void:
	await _boot_device(dev)
	var row: Dictionary = {}
	for r: Dictionary in _matrix():
		if str(r["name"]) == name:
			row = r
	runner.check(not row.is_empty(), "%s is in the matrix" % name)
	if row.is_empty():
		return
	runner.check(L.cw == float(row["cw"]) and m._ox == 0.0 and m._sx == L.floor4(float(row["delta"]) / 2.0), "%s: the chrome at x 0 spans cw %d; the stage column at x %d (got %d, %d, %d)" % [name, int(row["cw"]), int(L.floor4(float(row["delta"]) / 2.0)), L.cw, m._ox, m._sx])
	runner.check(m._lower_y == float(row["lowerY"]), "%s: lowerY %d (got %d)" % [name, int(row["lowerY"]), m._lower_y])
	runner.check(m.ticker.clip_rect().size.x == float(row["clip"]), "%s: the ticker clip %d (got %d)" % [name, int(row["clip"]), m.ticker.clip_rect().size.x])
	runner.check(m.mode == "pick" and m.picker.visible, "%s: a fresh game boots into LEADER_PICK" % name)
	var pf: Dictionary = row["pickFirst"]
	# th: §5.8's value, or up to 16 less where the tiles fill `avail` (the spec's header counts 12 under
	# the title and not the 12 above the strip; the engine keeps the title clear of the wordmark)
	var th_ok: bool = m.picker.tile.y <= float(pf["th"]) and m.picker.tile.y >= float(pf["th"]) - 16.0
	runner.check(m.picker.tile.x == float(pf["tw"]) and th_ok and m.picker.avatar == float(pf["A"]), "%s: pick tiles %s, A %d (got %s, %d)" % [name, [pf["tw"], pf["th"]], int(pf["A"]), m.picker.tile, m.picker.avatar])
	var title_top: float = m.picker.grid.x - 16.0 - 44.0
	runner.check(title_top >= 12.0 + (116.0 if m._vs.y >= 1280.0 else 64.0) + 12.0 - 0.5, "%s: the title line clears the wordmark (%d)" % [name, title_top])
	var H: float = float(m._vs.y) - float(m._bottom_inset)
	runner.check(m.picker.grid.y + 12.0 == H - 16.0 - PickView.STRIP_H, "%s: the grid sits on the strip (bottom %d)" % [name, m.picker.grid.y])
	var cb := TopBar.counter_box()
	runner.check(cb.size.x == 328.0 + L.dx and TopBar.COUNTER_SCALE == 6, "%s: the counter ×6 in a stretched box (%d)" % [name, cb.size.x])
	var p0: Rect2 = m.shop.PILL_RECT
	runner.check(p0.size.x == 168.0 + minf(L.dx, 40.0), "%s: the pill grows by min(dx, 40) (%d)" % [name, p0.size.x])


func test_boot_at_390x844_at_3() -> void:
	await _check_booted(Vector2i(1170, 2532), "390×844@3")


func test_boot_at_the_se() -> void:
	await _check_booted(Vector2i(750, 1334), "SE 375×667@2")


func test_boot_at_430x932_at_3() -> void:
	await _check_booted(Vector2i(1290, 2796), "430×932@3")


func test_boot_at_412x915_at_2_625() -> void:
	await _check_booted(Vector2i(1081, 2401), "412×915@2.625")
