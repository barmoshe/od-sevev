extends RefCounted
## D19 (manual test pass 2026-09-30, Bar's iPhone): the ticker row showed the "מבזק" plate, Dubi and
## the date over an EMPTY clip. Cause: when a headline ended with nothing queued the pager rolled an
## empty page node in, and in the first minute nothing refills it (ticker.ambientFrom "C1" holds the
## ambient lines until the group opens). ux/mobile-first-layout.md §5.2.2: the strip is never
## empty. A one-page headline holds (up to HOLD_MAX_MS); a multi-page one, an FTUE line and a hold
## that ran out roll to the standing line (TICKER_IDLE), which is also the row before its first
## headline. Every frame of every path below is sampled: the strip text is never "".

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


func _make(reduced: bool = false) -> void:
	t = Ticker.new()
	tree.root.add_child(t)
	await tree.process_frame
	t.set_reduced_motion(reduced)
	t.defer_until(0.0)
	# the first minute: ambient lines are held (ambientFrom C1), so nothing refills the row
	t.ambient_source = func() -> String: return ""


## Runs `ms` of 16-ms frames; returns the number of frames whose strip showed nothing.
func _run(ms: float) -> int:
	var blank := 0
	var e := 0.0
	while e < ms:
		t.update_view(16.0)
		e += 16.0
		if t.strip_text().strip_edges() == "":
			blank += 1
	return blank


func test_the_row_opens_on_its_standing_line() -> void:
	await _make()
	runner.check(t.strip_text() == Strings.s("TICKER_IDLE") and t.idle_showing(), "before any headline the strip reads the standing line (got \"%s\")" % t.strip_text())
	runner.check(_run(12000.0) == 0, "12 s with nothing queued and ambient held: never a blank strip")
	runner.check(Strings.s("TICKER_IDLE") != "" and PxText.measure(Strings.s("TICKER_IDLE"), L.TEXT) <= 280, "the standing line fits the narrowest clip (press day 280) on one line")


func test_a_one_page_headline_holds_then_gives_way() -> void:
	await _make()
	var line := "דובי: הכול בסדר"
	t.enqueue("flavor", line)
	var blank := _run(400.0)
	runner.check(t.page_text() == line and not t.idle_showing(), "the headline rolls in over the standing line")
	blank += _run(t._dwell + 2000.0)
	runner.check(t.holding() and t.strip_text() == line, "after its dwell, with nothing queued, the one-page headline HOLDS (got \"%s\")" % t.strip_text())
	blank += _run(Ticker.HOLD_MAX_MS)
	runner.check(t.idle_showing() and t.strip_text() == Strings.s("TICKER_IDLE"), "a hold longer than HOLD_MAX_MS gives way to the standing line")
	runner.check(blank == 0, "never a blank frame on the way (%d blank)" % blank)


func test_a_held_headline_rolls_out_under_the_next() -> void:
	await _make()
	t.enqueue("flavor", "דובי: הכול בסדר")
	_run(400.0)
	_run(t._dwell + 1000.0)
	runner.check(t.holding(), "holding")
	t.enqueue("milestone", "שיא חדש בסקרים")
	t.update_view(16.0)
	runner.check(not t.holding() and t.page_text() == "שיא חדש בסקרים" and t.in_transition(), "the next headline rolls in over the held page (no blank in between)")
	runner.check(_run(600.0) == 0, "and the roll never shows an empty strip")


func test_a_multi_page_headline_and_an_ftue_line_end_on_the_standing_line() -> void:
	await _make()
	t.enqueue("flavor", "ההייטקיסטים יוצאים לרחובות שוב, והפעם עם שלטים חדשים ועם כובע של קוסם ישן מהטלוויזיה")
	var blank := _run(32.0)
	runner.check(t._pages.size() >= 2, "a multi-page headline (%d pages)" % t._pages.size())
	blank += _run(30000.0)
	runner.check(t.idle_showing() and not t.holding(), "its last page alone would be a fragment: the standing line rolls in instead")
	t.enqueue("ftue", "נגיעה בראש הרשימה")
	blank += _run(12000.0)
	runner.check(t.idle_showing(), "an FTUE instruction goes stale once done: it never holds")
	runner.check(blank == 0, "never a blank frame (%d blank)" % blank)


func test_reduced_motion_never_blanks_either() -> void:
	await _make(true)
	t.enqueue("flavor", "ההייטקיסטים יוצאים לרחובות שוב, והפעם עם שלטים חדשים ועם כובע של קוסם ישן מהטלוויזיה")
	var blank := _run(30000.0)
	t.enqueue("flavor", "דובי: הכול בסדר")
	blank += _run(25000.0)
	runner.check(blank == 0 and t.idle_showing(), "the cross-fade path holds and returns to the standing line with no blank frame (%d blank)" % blank)


func test_the_hold_rule() -> void:
	runner.check(Ticker.should_hold("flavor", 1) and Ticker.should_hold("milestone", 1) and Ticker.should_hold("ambient", 1), "a whole one-page headline holds")
	runner.check(not Ticker.should_hold("flavor", 2) and not Ticker.should_hold("ftue", 1) and not Ticker.should_hold("", 1), "a fragment, an FTUE line, nothing: never")


func test_the_standing_line_follows_the_clip() -> void:
	await _make()
	t.set_court_chip(true, 220.0)   # the spec's 212-wide court chip: the clip starts at x 228
	runner.check(t.idle_showing() and t.strip_text() == Strings.s("TICKER_IDLE"), "court day: the standing line stays")
	var l: PxText = t._lines[t._cur][0]
	runner.check(is_equal_approx(l.position.x, t.clip_rect().size.x) and float(l.width()) <= t.clip_rect().size.x + 0.5, "right-aligned inside the narrowed clip (x %.0f, w %d, clip %s)" % [l.position.x, l.width(), t.clip_rect()])
	t.set_court_chip(false)
	runner.check(t.web_info()["text"] == Strings.s("TICKER_IDLE") and t.web_info()["idle"] == true, "web_info publishes what the strip shows")
