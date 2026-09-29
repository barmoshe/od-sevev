extends RefCounted
## The ticker's anchor (ux/rtl-map.md §5.1): the red "מבזק" plate holds its whole word (right-aligned
## at x 700), small Dubi stands left of the plate, and the crawl clip ends before Dubi, so nothing
## clips the tag and Dubi never sits over the crawl. At text ×4 and large text ×5.

var runner: Object
var tree: SceneTree
var dir := ""
var m: Node


func setup(r: Object) -> void:
	TestFixture.use_game_content()
	tree = r as SceneTree
	dir = "user://test_ticker_%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(dir)


func teardown() -> void:
	if m and is_instance_valid(m):
		m.set_process(false)
		if m.get_parent():
			m.get_parent().remove_child(m)
		m.queue_free()
	var d := DirAccess.open(dir)
	if d:
		for f in d.get_files():
			d.remove(f)
	DirAccess.remove_absolute(dir)


func _check_layout(tag_w: float, dubi: Rect2, label: String) -> void:
	var lay := Ticker.anchor_layout(tag_w, dubi)
	var plate: Rect2 = lay["plate"]
	var text := Rect2(float(lay["textRight"]) - tag_w, plate.position.y, tag_w, plate.size.y)
	runner.check(float(lay["textRight"]) == 700.0, "%s: the tag is right-aligned at x 700" % label)
	runner.check(plate.encloses(text) and plate.end.x <= float(L.W), "%s: the plate holds the whole word (%s in %s)" % [label, text, plate])
	var dr := Rect2(dubi.position + Vector2(lay["dubiFeet"]), dubi.size)
	runner.check(dr.end.x <= plate.position.x, "%s: Dubi stands left of the plate (%s vs %s)" % [label, dr, plate])
	runner.check(float(lay["clipX1"]) <= dr.position.x, "%s: the crawl ends before Dubi (clip x1 %s, Dubi x %s)" % [label, lay["clipX1"], dr.position.x])
	runner.check(float(lay["clipX1"]) - float(L.TICKER["clipX0"]) >= 300.0, "%s: the crawl keeps ≥ 300 px (%s)" % [label, float(lay["clipX1"]) - float(L.TICKER["clipX0"])])
	runner.check(Vector2(lay["dubiFeet"]).y == float(L.TICKER["panel"].size.y), "%s: Dubi's feet on the row floor" % label)


func test_anchor_layout_at_both_text_scales() -> void:
	var dubi := Rect2(-40, -88, 80, 92)   # chars.dubi 20×23 art, anchor [10, 22], at ×4
	var w4 := float(PxText.measure(Strings.s("TICKER_TAG"), 4))
	var w5 := float(PxText.measure(Strings.s("TICKER_TAG"), 5))
	runner.check(w4 > 0.0 and w5 > w4, "the tag measures (%s at ×4, %s at ×5)" % [w4, w5])
	_check_layout(w4, dubi, "×4")
	_check_layout(w5, dubi, "×5")
	var none := Ticker.anchor_layout(w4, Rect2())
	runner.check(float(none["clipX1"]) <= (none["plate"] as Rect2).position.x, "without Dubi's art the crawl still ends before the plate")


func test_the_real_ticker_does_not_overlap() -> void:
	m = load("res://scenes/main.tscn").instantiate()
	m.store = SaveStore.new(dir)
	tree.root.add_child(m)
	for i in 3:
		await tree.process_frame
	var t: Ticker = m.ticker
	var plate := Rect2(t._tag_plate.position, t._tag_plate.size)
	var tw := float(t._tag_text.width())
	var tx: float = t._tag_text.position.x + t._tag_text._anchor_dx(tw)   # right_at: position.x is the right edge
	runner.check(tx >= plate.position.x and tx + tw <= plate.end.x, "the drawn tag (x %s, w %s) is inside its plate %s" % [tx, tw, plate])
	if t.dubi != null:
		var dr := t.dubi.rect()
		dr.position += t.dubi.position
		runner.check(dr.end.x <= plate.position.x and dr.position.x >= t.clip_x1(), "Dubi %s sits between the crawl (ends %s) and the plate" % [dr, t.clip_x1()])
	runner.check(is_equal_approx(t._clip.position.x + t._clip.size.x, t.clip_x1()), "the clip's right edge is the anchor's left edge")
