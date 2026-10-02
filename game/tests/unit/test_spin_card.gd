extends RefCounted
## The spin card and the controller's sim hooks (engine, wave 3; sim/README "Controller wiring"):
## the pill reads Economy.upgrade_price / can_buy_upgrade (S07's costBpsSeconds price, S08's next
## level), a tap on a card that looks affordable always buys, the card's extras (Spins.card: the
## "שחוק" tag, a line's level, S08's bars, S10's flights), the live-spin chip, the S07 rate line,
## the night trophy's hour, S08's per-level flavor, and ViewRules.trophy_model compiling.
## Runs on the game content (design/content.json: s07 consumable, s08 line, s10 flightIncome);
## the card tests drive the real scene's Shop, buying through main.gd's handler.

const Main := preload("res://scripts/main.gd")

var runner: Object
var tree: SceneTree
var dir := ""
var m: Node


func setup(r: Object) -> void:
	TestFixture.use_game_content()
	tree = r as SceneTree
	dir = "user://test_spin_card_%d" % Time.get_ticks_usec()
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


func _touch(p: Vector2) -> void:
	for pressed in [true, false]:
		var e := InputEventScreenTouch.new()
		e.position = p
		e.pressed = pressed
		m._unhandled_input(e)


## The real scene past tap 3 (the panel is shown), in a round with income.
func _boot() -> GameState:
	m = load("res://scenes/main.tscn").instantiate()
	m.store = SaveStore.new(dir)
	tree.root.add_child(m)
	for i in 3:
		await tree.process_frame
	m.ftue.handoff_ms = 1.0
	m.commit_pick("bibi")   # LEADER_PICK (leader select): Bibi's round, the shipped game
	for i in 3:
		_touch(L.magician_hit().get_center() + Vector2(m._sx, m._stage_y))
	var s: GameState = m.state
	_rich(s)
	await tree.process_frame
	return s


## Income enough that S07 is unlocked (run 50,000) and its costBpsSeconds price beats its cost.
func _rich(s: GameState = null) -> GameState:
	if s == null:
		s = GameState.fresh()
	s.run_bananas = 1e7
	s.all_time_bananas = 1e7
	s.owned["qatari"] = 40
	return s


func _price_text(p: float) -> String:
	return Strings.s("CARD_PRICE", {"price": Fmt.cost(p)})


func _row(sh: Shop, s: GameState, id: String) -> Dictionary:
	var k := sh.row_index_of(s, "upgrade", id)
	return (sh._rows["upgrades"] as Array)[k] if k >= 0 else {}


# ------------------------------------------------------------------ the price pill (item 1)

func test_s07_pill_shows_the_income_scaled_price() -> void:
	var s: GameState = await _boot()
	var sh: Shop = m.shop
	var d := Economy.derive(s)
	var real := Economy.upgrade_price(s, "s07", d)
	var cost := float(Content.upgrade("s07")["cost"])
	runner.check(real > cost, "the fixture makes costBpsSeconds win (%s > %s)" % [real, cost])
	s.bananas = cost + 1.0   # enough for u.cost, not for the real price: the old pill was gold here
	sh.refresh(s, 16.0, false, d)
	var v := _row(sh, s, "s07")
	runner.check(not v.is_empty(), "S07 is on the shelf")
	if v.is_empty():
		return
	runner.check((v["pill2"] as PxText).text == _price_text(real), "the pill reads the real price %s, got %s" % [_price_text(real), (v["pill2"] as PxText).text])
	runner.check(v["afford"] == false, "and is not gold below it")
	var said := [false]
	sh.cant_afford.connect(func() -> void: said[0] = true)
	sh._commit(v, s)
	runner.check(said[0] and Spins.buys(s, "s07") == 0, "a tap below the real price says 'can't afford', never a silent nothing")
	s.bananas = real
	sh.refresh(s, 16.0, false, d)
	runner.check(v["afford"] == true and v["afford"] == Economy.can_buy_upgrade(s, "s07"), "gold exactly when the sim would sell it")
	sh._commit(v, s)
	runner.check(Spins.buys(s, "s07") == 1 and not Spins.live(s, "s07").is_empty(), "the tap bought S07 and its timer runs")


func test_s08_line_pill_walks_its_levels_and_the_card_stays() -> void:
	var s: GameState = await _boot()
	var sh: Shop = m.shop
	s.evolutions = 1   # S08 unlocks from round 2
	var lv: Array = Content.upgrade("s08")["levels"]
	var d := Economy.derive(s)
	s.bananas = 1e12
	for n in 3:
		sh.refresh(s, 16.0, false, d)
		var v := _row(sh, s, "s08")
		runner.check(not v.is_empty(), "S08 is on the shelf at level %d" % n)
		if v.is_empty():
			return
		var want := float(lv[n]["cost"])
		runner.check((v["pill2"] as PxText).text == _price_text(want), "level %d costs %s (got %s)" % [n + 1, _price_text(want), (v["pill2"] as PxText).text])
		runner.check((v["tag"] as PxText).text == Strings.s("PERK_LEVEL", {"lv": n, "max": lv.size()}) and (v["tag"] as PxText).visible,
			"the plate's stamp shows the level %d/%d" % [n, lv.size()])
		runner.check((v["owned"] as PxText).text == "", "line 2 keeps its wide box (no owned count on a spin)")
		runner.check((v["barPublic"] as ColorRect).visible, "S08's bars are on its card")
		runner.check(absf((v["barPublic"] as ColorRect).size.x - Ui.snap(Shop.SPIN_BARS.size.x * (100.0 - 20.0 * n) / 100.0, 4)) < 0.5,
			"the public bar drains 20 points per level (level %d: %s)" % [n, (v["barPublic"] as ColorRect).size.x])
		sh._commit(v, s)
		runner.check(Spins.level(s, "s08") == n + 1, "the tap bought level %d" % (n + 1))
		runner.check(sh.row_index_of(s, "upgrade", "s08") >= 0 and (v["icon"] as Sprite2D).visible, "the card stays on the shelf, its icon not popped away")


func test_spin_card_model_tags_and_extras() -> void:
	var s := _rich()
	s.bananas = 1e12
	var c := Shop.spin_card(s, "s07")
	runner.check(c["tag"] == "" and c["kind"] == "consumable", "a fresh consumable has no tag")
	Economy.buy_upgrade(s, "s07")
	Economy.tick(s, 31.0)
	c = Shop.spin_card(s, "s07")
	runner.check(c["tag"] == Strings.s("SPIN_FATIGUE"), "a rebuy is worn: 'שחוק' (got %s)" % c["tag"])
	runner.check(float(c["price"]) == Economy.upgrade_price(s, "s07"), "the model's price is the sim's")
	s.upgrades.append("s10")
	s.spins["flights"] = 3
	runner.check(absf(float(Shop.spin_card(s, "s10").get("flightPct", -1.0)) - 15.0) < 1e-9, "S10's bonus: 3 flights = 15%")
	runner.check(Main.flight_label(15.0) == "\u2066+15%\u2069", "the flight floater is an LTR token")


func test_s08_flavor_follows_its_level() -> void:
	var s := _rich()
	s.evolutions = 1
	s.bananas = 1e12
	var lv: Array = Content.upgrade("s08")["levels"]
	Economy.buy_upgrade(s, "s08")
	Economy.buy_upgrade(s, "s08")
	runner.check(Main.spin_flavor(s, "s08") == String(lv[1]["flavor"]), "level 2's own ticker line")
	runner.check(Main.spin_flavor(s, "s01") == String(Content.upgrade("s01")["flavor"]), "a once spin keeps its flavor")


# ------------------------------------------------------------------ buff views (item 2)

func test_live_spin_chip() -> void:
	var s: GameState = await _boot()
	s.bananas = 1e12
	runner.check(BuffViews.first_spin(Spins.active_effects(s)).is_empty(), "no live spin, no chip")
	Economy.buy_upgrade(s, "s07")
	s.spins["active"].append({"id": "s02", "type": "tapBuff", "leftSec": 50.0, "durationSec": 60.0, "mult": 1.5, "pour": 0.0})
	var f := BuffViews.first_spin(Spins.active_effects(s))
	runner.check(f.get("id") == "s07", "the chip shows the spin that ends first")
	var t := BuffViews.spin_chip_text({"id": "s07", "type": "idleToTap"}, 12.2, 368.0)
	runner.check(t.contains(Strings.s("SPIN_ACTIVE", {"s": "13"})), "SPIN_ACTIVE with the seconds left: %s" % t)
	runner.check(PxText.measure(t, BuffViews.CHIP_SCALE) <= 368, "it fits the chip")
	var tp := BuffViews.spin_chip_text(Spins.live(s, "s02"), 42.0, 368.0)
	runner.check(tp.contains("1.5") and tp.contains("42"), "the pistachio's chip says what it does: %s" % tp)
	runner.check(PxText.measure(tp, BuffViews.CHIP_SCALE) <= 368, "and fits the chip")
	var bv: BuffViews = m.buffs
	bv.update_chip(0.0, 0.0, true, Spins.active_effects(s))
	runner.check(bv._chip_text.visible and bv._chip_text.text == BuffViews.spin_chip_text(Spins.live(s, "s07"), float(Spins.live(s, "s07")["leftSec"]), 368.0),
		"the chip is up for S07: %s" % bv._chip_text.text)
	bv.update_chip(5.0, 0.0, true, Spins.active_effects(s))
	runner.check(bv._chip_text.text.contains("×"), "a Suitcase frenzy wins the one chip (E5)")
	var d := Economy.derive(s)
	runner.check(d.tap_pour_sec > 0.0 and d.bps > 0.0, "S07 pours the income (the rate line reads 0 while it runs)")


# ------------------------------------------------------------------ night trophy, trophy count, view rules (3, 4, 6)

func test_politics_ctx_carries_the_local_hour() -> void:
	var ctx := Main.politics_ctx(1.0e12, true, {"hour": 3, "weekday": 5})
	runner.check(ctx["hour"] == 3 and ctx["weekday"] == 5 and ctx["allowPing"] == true and ctx["nowMs"] == 1.0e12, "ctx: %s" % str(ctx))
	runner.check(Politics.night_hour(ctx) == 3, "the sim reads the device hour, not Israel time")


func test_ambient_trophies_at_least_skips_gantz() -> void:
	var s := GameState.fresh()
	var never := ""
	var real := ""
	for a: Dictionary in Meta.achievements():
		if a.get("neverAwarded", false) and never == "":
			never = a["id"]
		elif not a.get("neverAwarded", false) and real == "":
			real = a["id"]
	runner.check(never != "" and real != "", "the content has a neverAwarded trophy (a_gantz)")
	s.achievements.append(never)
	runner.check(not Ambient.ok(s, {"trophiesAtLeast": 1}, {}, 0.0), "Gantz's rotation never counts")
	s.achievements.append(real)
	runner.check(Ambient.ok(s, {"trophiesAtLeast": 1}, {}, 0.0) and not Ambient.ok(s, {"trophiesAtLeast": 2}, {}, 0.0), "a real trophy counts once")


func test_view_rules_trophy_model_compiles_and_models() -> void:
	var s := GameState.fresh()
	var a: Dictionary = Meta.achievements()[0]
	var m0 := ViewRules.trophy_model(s, a)
	runner.check(m0["earned"] == false and m0["id"] == a["id"], "locked: %s" % str(m0))
	s.achievements.append(a["id"])
	runner.check(ViewRules.trophy_model(s, a)["earned"] == true, "earned once in the state")
	var gantz := {"id": "x_never", "neverAwarded": true, "fakeProgress": 0.99}
	s.achievements.append("x_never")
	var mg := ViewRules.trophy_model(s, gantz)
	runner.check(mg["earned"] == false and absf(float(mg["progress"]) - 0.99) < 1e-9, "neverAwarded is never earned and shows its fake progress")


# ------------------------------------------------------------------ the whole route, by touch

func test_touching_an_s08_card_buys_a_level_in_the_real_scene() -> void:
	var s: GameState = await _boot()
	s.evolutions = 1
	s.bananas = 1e7
	m.shop.switch_tab("upgrades")
	for i in 30:
		await tree.process_frame
	var k: int = m.shop.row_index_of(s, "upgrade", "s08")
	runner.check(k >= 0, "S08 is on the shelf")
	if m.shop.row_screen_y(k) < 0.0:
		m.shop._set_scroll("upgrades", float(L.SHOP["rowPitch"]) * k)
		for i in 3:
			await tree.process_frame
	var y: float = m.shop.row_screen_y(k)
	runner.check(y >= 0.0, "its card is in view")
	_touch(Vector2(400, y + 60.0) + Vector2(m._ox, m._lower_y))
	runner.check(Spins.level(s, "s08") == 1, "a touch on the card bought level 1 (level %d)" % Spins.level(s, "s08"))
	for i in 3:
		await tree.process_frame
	var v: Dictionary = (m.shop._rows["upgrades"] as Array)[m.shop.row_index_of(s, "upgrade", "s08")]
	var want := _price_text(float(Content.upgrade("s08")["levels"][1]["cost"]))
	runner.check((v["pill2"] as PxText).text == want, "the pill moved to level 2's price %s (got %s)" % [want, (v["pill2"] as PxText).text])
