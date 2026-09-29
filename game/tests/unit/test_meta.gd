extends RefCounted
## v2 depth: milestones, Troop Morale, Thumb Perks and automation (game/scripts/sim/meta.gd).

var runner: Object


func setup(_r: Object) -> void:
	TestFixture.use_fork_content()


func teardown() -> void:
	TestFixture.use_game_content()


func test_milestones_double_a_tier() -> void:
	runner.check(is_equal_approx(Meta.milestone_mult(24), 1.0), "no milestone below 25")
	runner.check(is_equal_approx(Meta.milestone_mult(25), 2.0), "x2 at 25")
	runner.check(is_equal_approx(Meta.milestone_mult(100), 8.0), "x8 at 100 (25, 50, 100)")
	runner.check(is_equal_approx(Meta.milestone_mult(150), 8.0), "no milestone at 150")
	var s := GameState.fresh()
	s.owned["intern"] = 25
	runner.check(is_equal_approx(Economy.derive(s).bps, 25 * 0.4 * 2.0), "25 interns earn double")
	runner.check(Meta.next_milestone(25) == 50, "next milestone after 25 is 50")


func test_all_producers_bonus() -> void:
	var s := GameState.fresh()
	for id in Content.producer_ids():
		s.owned[id] = 10
	runner.check(is_equal_approx(Meta.all_producers_mult(s), 1.25), "ten of each gives x1.25")


func test_achievements_pay_and_persist() -> void:
	var s := GameState.fresh()
	s.taps_lifetime = 100
	var got := Meta.check_achievements(s, Economy.derive(s))
	runner.check(got.has("a_tap_100"), "100 taps earns FINGER WORKOUT")
	runner.check(Meta.check_achievements(s, Economy.derive(s)).is_empty(), "earned once")
	s.owned["tree"] = 10
	var bps := 10 * 2.4
	runner.check(is_equal_approx(Economy.derive(s).bps, bps * 1.015), "each trophy adds 1.5%")
	var ids := {}
	for a: Dictionary in Meta.achievements():
		runner.check(not ids.has(a["id"]), "achievement ids are unique (%s)" % a["id"])
		ids[a["id"]] = true
		runner.check(String(a["name"]).length() <= 22 and String(a["desc"]).length() <= 22, "%s fits a row" % a["id"])
		runner.check(Art.has_sprite(a["icon"]), "%s icon exists" % a["id"])


func test_perks_spend_without_lowering_the_multiplier() -> void:
	var s := GameState.fresh()
	s.all_time_bananas = 1e6
	s.thumbs_owned = 10
	var before := Economy.derive(s).prestige_mult
	runner.check(Meta.buy_perk(s, "p_autotap"), "5 Thumbs buy Lazy Fingers")
	runner.check(s.thumbs_available() == 5 and s.thumbs_spent == 5, "spent 5, 5 left")
	runner.check(is_equal_approx(Economy.derive(s).prestige_mult, before), "spending never lowers the multiplier")
	runner.check(is_equal_approx(Meta.auto_tap_rate(s), 2.0), "auto-taps 2/s")
	runner.check(not Meta.buy_perk(s, "p_autotap"), "level 2 costs 25: not affordable")
	runner.check(not Meta.buy_perk(s, "nope"), "unknown perk")
	for p: Dictionary in Meta.perks():
		runner.check((p["levels"] as Array).size() == (p["costs"] as Array).size(), "%s levels match costs" % p["id"])
		runner.check(Art.has_sprite(p["icon"]), "%s icon exists" % p["id"])
		runner.check(String(p["name"]).length() <= 18, "%s name fits beside the pill" % p["id"])
		for v: Variant in p["levels"]:
			var fv := float(v)
			var vs := Fmt.amount(fv) if fv >= 1000.0 else (str(int(fv)) if is_equal_approx(fv, roundf(fv)) else str(fv))
			runner.check(String(p["desc"]).replace("{v}", vs).length() <= 18, "%s at %s fits beside the pill" % [p["id"], vs])


func test_away_perks() -> void:
	var s := GameState.fresh()
	s.owned["tree"] = 10
	runner.check(is_equal_approx(Meta.away_cap_sec(s), 28800.0), "default cap 8 h")
	s.shop["p_nap"] = 2
	s.shop["p_shift"] = 2
	runner.check(is_equal_approx(Meta.away_cap_sec(s), 86400.0), "Longer Naps II: 24 h")
	var r := Meta.away_award(s, 86400.0)
	runner.check(is_equal_approx(float(r["award"]), 24.0 * 86400.0), "Night Shift II pays full rate for the whole day")


func test_evolve_keeps_tool_belt_and_head_start() -> void:
	var s := GameState.fresh()
	s.all_time_bananas = 1e6
	s.upgrades = PackedStringArray(["glove", "internx2", "luckypeel"])
	s.shop["p_toolbelt"] = 1
	s.shop["p_start"] = 1
	var r := Meta.evolve(s)
	runner.check(not r.is_empty(), "evolved")
	runner.check(s.upgrades.has("glove") and s.upgrades.has("luckypeel") and not s.upgrades.has("internx2"), "tap upgrades kept, producer upgrade reset")
	runner.check(is_equal_approx(s.bananas, 1000.0), "Head Start I: 1,000 bananas")
	runner.check(s.stats.get("evolvedNoInterns", 0.0) == 1.0, "Union Buster stat")


func test_butler_buys_the_cheapest() -> void:
	var s := GameState.fresh()
	s.bananas = 200.0
	s.run_bananas = 200.0
	runner.check(Meta.auto_buy(s) == "", "no butler without the perk")
	s.shop["p_butler"] = 1
	runner.check(Meta.auto_buy(s) == "intern", "butler buys the cheapest (an intern)")
	s.bananas = 100.0
	runner.check(Meta.auto_buy(s) == "", "butler only spends pocket change (17 of 100 is too much)")


func test_buffs_last_longer() -> void:
	var s := GameState.fresh()
	s.shop["p_frenzy"] = 1
	Economy.apply_golden(s, "frenzy")
	runner.check(is_equal_approx(s.buff_frenzy, 15.0 * 1.25), "Long Frenzy I: +25%")
