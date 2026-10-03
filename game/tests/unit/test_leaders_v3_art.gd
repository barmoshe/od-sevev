extends RefCounted
## Leaders v3 art (creative-pack/art/briefs/leaders-v3-gpt.md, rigged 2026-10-01): the nine pose
## characters (`<leader>-<pose>`, each at its leader's scale and feet line), the stage props, the ability
## icons and Kaia ship in the manifest; PressDesk draws the prop sprites; KaiaFigure plays her strip;
## Magician.flash_pose stands a pose in for the hero and gives the stage back.

var runner: Object
var tree: SceneTree
var dir := ""
var m: Node

const POSES := {"bennett-sign": "bennett", "ben-gvir-walkout": "ben-gvir", "ben-gvir-back": "ben-gvir",
	"liberman-document": "liberman", "eisenkot-summit": "eisenkot", "smotrich-budget": "smotrich",
	"deri-bench": "deri", "golan-swipe": "golan", "bibi-matchmaker": "bibi"}
const ICON_LEADERS := ["bibi", "bennett", "bengvir", "liberman", "eisenkot", "smotrich", "deri", "golan"]


func setup(r: Object) -> void:
	TestFixture.use_game_content()
	tree = r as SceneTree
	dir = "user://test_leaders_v3_art_%d" % Time.get_ticks_usec()
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


func _boot() -> void:
	m = load("res://scenes/main.tscn").instantiate()
	m.store = SaveStore.new(dir)
	tree.root.add_child(m)
	for i in 3:
		await tree.process_frame
	m.ftue.handoff_ms = 1.0
	m.set_process(false)


func _start_round(id: String) -> bool:
	if not m.commit_pick(id):
		return false
	for i in 2:
		m._process(0.016)
	var at: Vector2 = L.magician_hit().get_center() + Vector2(m._sx, m._stage_y)
	for pressed in [true, false]:
		var e := InputEventScreenTouch.new()
		e.position = at
		e.pressed = pressed
		m._unhandled_input(e)
	return m.mode == "main"


# ------------------------------------------------------------------ the manifest

func test_the_pose_characters_stand_at_their_leaders_scale() -> void:
	var chars: Dictionary = SpriteStrip.manifest()["chars"]
	for pose: String in POSES:
		runner.check(chars.has(pose), "%s ships" % pose)
		if not chars.has(pose):
			continue
		var c: Dictionary = chars[pose]
		var l: Dictionary = chars[POSES[pose]]
		runner.check((c["anims"] as Dictionary).has("pose") and bool(c["anims"]["pose"]["loop"]), "%s: a looping 'pose' anim" % pose)
		runner.check(int(c["density"]) == int(l["density"]) and (c.get("densities", {}) as Dictionary).has("2"),
			"%s: the leader's density (d %s) and a d 2 alternate" % [pose, c["density"]])
		runner.check(SpriteStrip.resolve(pose) == pose, "%s resolves to itself" % pose)


func test_the_props_and_icons_ship() -> void:
	for id: String in ["prop_podium", "prop_corridor-bench", "prop_cardboard-box", "prop_round-table",
			"prop_pledge-scroll", "prop_budget-book", "prop_clause-doc"]:
		runner.check(Art.has_sprite(id), "%s ships" % id)
	runner.check(Art.sprite_size("prop_podium").y == 40, "the podium is 40 art px tall (the drawn map's height)")
	for lid: String in ICON_LEADERS:
		var id := "prop_ability_" + lid
		runner.check(Art.has_sprite(id) and Art.sprite_size(id) == Vector2i(16, 16), "%s: a 16 x 16 icon" % id)
		runner.check(Art.has_sprite(id + "_d2") and Art.sprite_size(id + "_d2") == Vector2i(32, 32), "%s_d2: its 32 x 32 twin" % id)
	var k: Dictionary = SpriteStrip.manifest()["chars"].get("kaia", {})
	runner.check((k.get("anims", {}) as Dictionary).has("idle") and (k.get("anims", {}) as Dictionary).has("happy"), "Kaia: idle + happy")


# ------------------------------------------------------------------ the views

func test_the_press_desk_draws_the_prop_sprites() -> void:
	var desk := PressDesk.new()
	for kind: String in ["podium", "bench", "box"]:
		desk.set_kind(kind)
		var id := desk.sprite_id()
		runner.check(id == PressDesk.SPRITES[kind], "%s draws %s" % [kind, PressDesk.SPRITES[kind]])
		runner.check(desk.size_px() == Vector2(Art.sprite_size(id)) * 4.0, "%s: its size follows the texture (%s)" % [kind, desk.size_px()])
	desk.free()


func test_flash_pose_stands_in_for_the_hero_and_gives_the_stage_back() -> void:
	await _boot()
	runner.check(_start_round("bennett"), "Bennett's round starts")
	var magician: Magician = m.magician
	for i in 80:   # the walk-in lands and the boot tap's strip ends on idle
		magician.update_view(16.0)
	magician.walk_land()
	var hero: SpriteStrip = magician.hero
	runner.check(not magician.flash_pose("no-such-pose"), "an unknown pose: false, nothing changes")
	runner.check(hero.visible and not magician.posing(), "the hero is still up")
	runner.check(magician.flash_pose("bennett-sign", 300.0), "bennett-sign flashes")
	var p := magician.pose_node()
	runner.check(p != null and p.visible and not hero.visible and p.position == hero.position and p.anim == "pose",
		"the pose stands on the hero's feet, the hero hidden")
	runner.check(magician.on_stage(), "posing is still on the stage")
	magician.update_view(200.0)
	runner.check(magician.flash_pose("bennett-sign", 300.0) and magician.pose_node() == p, "again: the same strip, the timer restarts")
	magician.update_view(200.0)
	runner.check(magician.posing(), "still posing 200 ms after the restart")
	magician.update_view(150.0)
	runner.check(not magician.posing() and hero.visible, "the timer ran out: the hero is back")
	# the court day takes the figure: a running pose ends, and none starts while he is away
	runner.check(magician.flash_pose("bennett-sign", 5000.0), "a long pose")
	magician.court_sync(true)
	runner.check(not magician.posing(), "the press day ends the pose")
	for i in 60:
		magician.court_sync(true)
		magician.update_view(16.0)
	runner.check(magician.court.in_court() and not magician.flash_pose("bennett-sign"), "no pose while he is away")


func test_kaia_plays_her_strip() -> void:
	await _boot()
	runner.check(_start_round("bibi"), "Bibi's round starts")
	var k: KaiaFigure = m.kaia
	runner.check(k.strip != null and k.strip.char_id == "kaia", "Kaia is the sprite, not the drawn map")
	var s: GameState = m.state
	k.reduced_motion = true
	m._on_politics_event(Events.fire(s, "kaia", m.d))
	for i in 3:
		m._process(0.05)
	runner.check(k.tappable() and k.strip.anim == "idle", "on her mark: idle")
	var r := k.hit_rect()
	runner.check(r.has_point(k.position + Vector2(0, -20)) and r.size.y >= k.strip.frame_size().y, "her hit box holds the strip (%s)" % r)
	k.feed()
	runner.check(k.state == "fed" and k.strip.anim == "happy", "fed: the cucumber")
