extends RefCounted
## M1, the ticker page change (animator wave B; ux/mobile-first-layout.md §5.2, §10 M1): the roll
## (the next page rises from under the row as the old one lifts out, 240 ms Cubic.Out, 4-px steps,
## the pages locked one row apart), no word ever cut into a fragment (x never moves; every line
## stays inside the clip's width), the reduced-motion cross-fade, and the dwell by page length.

var runner: Object
var tree: SceneTree
var t: Ticker


func setup(r: Object) -> void:
	TestFixture.use_game_content()
	tree = r as SceneTree


func teardown() -> void:
	if t and is_instance_valid(t):
		t.get_parent().remove_child(t)
		t.queue_free()


func _make(reduced: bool) -> void:
	t = Ticker.new()
	tree.root.add_child(t)
	await tree.process_frame
	t.set_reduced_motion(reduced)
	t.defer_until(0.0)


## A three-page headline at the narrowest clip, showing its first page.
func _headline() -> void:
	t.enqueue("flavor", "ההייטקיסטים יוצאים לרחובות שוב, והפעם עם שלטים חדשים ועם כובע של קוסם ישן מהטלוויזיה")
	t.update_view(16.0)
	t.update_view(16.0)


func test_the_roll_rises_in_whole_pixels_one_row_apart() -> void:
	var h := 84.0
	var prev := -1.0
	var mono := true
	for i in 25:
		var r := Ticker.roll_rise(float(i) / 24.0, h)
		mono = mono and r >= prev
		prev = r
		runner.check(is_equal_approx(fmod(r, 4.0), 0.0), "rise %.1f on the 4-px grid" % r)
	runner.check(mono and Ticker.roll_rise(0.0, h) == 0.0 and Ticker.roll_rise(1.0, h) == h, "0 → one row, never back")
	runner.check(Ticker.roll_rise(0.5, h) >= 0.8 * h, "Cubic.Out: most of the travel in the first half (%.0f at 50 %%)" % Ticker.roll_rise(0.5, h))
	runner.check(Ticker.ROLL_MS <= 300.0, "short: ≤ 300 ms (the UX budget)")


func test_a_page_change_rolls_and_never_cuts_a_word() -> void:
	await _make(false)
	_headline()
	runner.check(t.page_text() != "" and t._pages.size() >= 2, "a multi-page headline shows (%d pages)" % t._pages.size())
	var first := t.page_text()
	t.update_view(t._dwell + 1.0)
	runner.check(t.in_transition() and t.page_text() != first, "after the dwell the next page rolls in")
	var w: float = t._clip.size.x
	var h: float = t._clip.size.y
	var ok_x := true
	var ok_grid := true
	var ok_apart := true
	var ms := 0.0
	while t.in_transition() and ms < 1000.0:
		var o := t.page_offsets()
		var a: Vector2 = o[0]
		ok_x = ok_x and a.x == 0.0 and (o[1] == null or (o[1] as Vector2).x == 0.0)
		ok_grid = ok_grid and is_equal_approx(fmod(absf(a.y), 4.0), 0.0)
		if o[1] != null:
			ok_apart = ok_apart and is_equal_approx(a.y - (o[1] as Vector2).y, h)
		for pair: Array in t._lines:
			for l: PxText in pair:
				if l.visible and l.text != "":
					# right-aligned (h_anchor 2): the ink runs from x − width to x
					var x0 := l.position.x - float(l.width()) if l.h_anchor == 2 else l.position.x
					ok_x = ok_x and x0 >= 0.0 and x0 + float(l.width()) <= w + 0.5
		t.update_view(16.0)
		ms += 16.0
	runner.check(ok_x, "x never moves and every line stays inside the clip's width: no word is cut into a fragment")
	runner.check(ok_grid and ok_apart, "4-px steps, the two pages locked one row apart")
	runner.check(absf(ms - Ticker.ROLL_MS) <= 16.0, "the roll takes %.0f ms" % ms)
	runner.check(t.page_offsets()[0] == Vector2.ZERO, "the new page rests at the row's origin")


func test_reduced_motion_keeps_the_cross_fade() -> void:
	await _make(true)
	_headline()
	t.update_view(t._dwell + 1.0)
	runner.check(t.in_transition(), "the page changes")
	t.update_view(100.0)
	var o := t.page_offsets()
	var n_in: Node2D = t._pages_n[t._cur]
	runner.check(o[0] == Vector2.ZERO and (o[1] == null or o[1] == Vector2.ZERO), "no travel")
	runner.check(n_in.modulate.a > 0.3 and n_in.modulate.a < 0.7, "a cross-fade (a %.2f at 100 ms)" % n_in.modulate.a)
	t.update_view(120.0)
	runner.check(not t.in_transition() and n_in.modulate.a == 1.0, "done in 200 ms")
	runner.check(t.web_info()["transition"] == "fade", "published as the fade")


func test_the_dwell_follows_the_page_length() -> void:
	var p := func(n: int) -> PackedStringArray: return PackedStringArray(["א".repeat(n)])
	var short_: float = Ticker.dwell_ms(p.call(7), "flavor")
	var mid: float = Ticker.dwell_ms(p.call(23), "flavor")
	var long_: float = Ticker.dwell_ms(p.call(49), "flavor")
	runner.check(short_ == 2000.0 and mid == 2810.0 and long_ == 4630.0, "7 / 23 / 49 characters: 2.0 / 2.81 / 4.63 s (%s)" % str([short_, mid, long_]))
	runner.check(Ticker.dwell_ms(p.call(23), "flavor", false) == 2110.0, "a continuation page skips the 1.2 s orientation (0.5 s)")
	runner.check(Ticker.dwell_ms(p.call(40), "ftue") == 4900.0 and Ticker.dwell_ms(p.call(10), "ftue") == 4500.0, "ftue: 1.5 s + 85 ms a character, floor 4.5 s")
