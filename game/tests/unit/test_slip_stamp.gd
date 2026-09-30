extends RefCounted
## The stamp on the ballot slip (animator wave B, v4 kit `card_plate`): a spin card's tag slams in at
## integer text scale 6 → 5 → 4 over 90 ms when it appears or changes on the same card, the backing
## growing around the tag's centre on the 4-px grid, and rests exactly in SPIN_TAG.

var runner: Object
var tree: SceneTree


func setup(r: Object) -> void:
	TestFixture.use_game_content()
	tree = r as SceneTree


func test_the_slam_steps() -> void:
	var seq: Array = []
	for t in [-1.0, 0.0, 29.0, 30.0, 59.0, 60.0, 89.0, 90.0]:
		seq.append(Shop.tag_slam_px(t))
	runner.check(seq == [4, 6, 6, 5, 5, 4, 4, 4], "×6 for 30 ms, ×5 for 30, ×4 (%s)" % str(seq))


func test_the_backing_grows_on_the_grid_and_rests_in_place() -> void:
	var host := Node2D.new()
	tree.root.add_child(host)
	var bg := ColorRect.new()
	host.add_child(bg)
	var tg := PxText.make(host, Vector2.ZERO, "2/5", L.TEXT, "plain", "w")
	var v := {"tag": tg, "tagBg": bg, "tagSlam": 0.0}
	var shop := Shop.new()
	shop._place_tag(v)
	runner.check(tg.px == 6 and is_equal_approx(fmod(bg.position.x, 4.0), 0.0) and is_equal_approx(fmod(bg.size.x, 4.0), 0.0) and bg.size.x > Shop.SPIN_TAG.size.x,
		"f0: ×6 on a grown backing, on the grid (%s)" % str(Rect2(bg.position, bg.size)))
	runner.check(absf(Rect2(bg.position, bg.size).get_center().x - Shop.SPIN_TAG.get_center().x) <= 2.0, "grown around the tag's centre")
	v["tagSlam"] = -1.0
	shop._place_tag(v)
	runner.check(tg.px == L.TEXT and Rect2(bg.position, bg.size) == Shop.SPIN_TAG and tg.position.y == Shop.SPIN_TAG.position.y + 2.0,
		"at rest: ×4 exactly in SPIN_TAG (%s)" % str(Rect2(bg.position, bg.size)))
	shop.free()
	host.queue_free()
