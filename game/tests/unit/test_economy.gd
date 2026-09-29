extends RefCounted
## Economy rules (mechanic-spec §2) and the v1.1 audit fixes.

var runner: Object


func setup(_r: Object) -> void:
	TestFixture.use_fork_content()


func teardown() -> void:
	TestFixture.use_game_content()


func _eq(a: float, b: float, msg: String, tol: float = 1e-6) -> void:
	runner.check(absf(a - b) <= tol * maxf(1.0, absf(b)), "%s: got %s, want %s" % [msg, a, b])


func test_fresh_state() -> void:
	var s := GameState.fresh()
	runner.check(s.owned.size() == Content.producers().size(), "fresh state owns every producer id")
	_eq(s.golden_timer_sec, 75.0, "first golden delay")
	var d := Economy.derive(s)
	_eq(d.bps, 0.0, "no bps at start")
	_eq(d.tap_value_no_crit, 1.0, "tap is worth 1 at start")
	_eq(d.crit_chance, 0.05, "base crit chance")


func test_bulk_cost_and_quotes() -> void:
	var s := GameState.fresh()
	_eq(Economy.producer_cost(s, "intern", 1), 15.0, "first intern")
	_eq(Economy.producer_cost(s, "intern", 10), 15.0 * (pow(1.15, 10) - 1.0) / 0.15, "ten interns")
	s.bananas = 14.0
	var q := Economy.quote(s, "intern", "max")
	runner.check(q["qty"] == 1 and not q["affordable"], "MAX with nothing affordable quotes 1, unaffordable")
	s.bananas = Economy.producer_cost(s, "intern", 10)
	runner.check(Economy.max_affordable(s, "intern") == 10, "max affordable is exactly 10 at the 10-unit price")
	s.bananas = Economy.producer_cost(s, "intern", 10) - 0.001
	runner.check(Economy.max_affordable(s, "intern") == 9, "a hair short of 10 buys 9")


func test_max_affordable_at_the_double_ceiling_is_instant() -> void:
	var s := GameState.fresh()
	s.bananas = Economy.MAX
	var t0 := Time.get_ticks_usec()
	for id in Content.producer_ids():
		var n := Economy.max_affordable(s, id)
		runner.check(n > 0 and n <= 1000000, "%s max affordable is bounded (%d)" % [id, n])
	runner.check(Time.get_ticks_usec() - t0 < 50000, "8 rows at the ceiling take under 50 ms (v1 froze)")


func test_buy_and_upgrades() -> void:
	var s := GameState.fresh()
	s.bananas = 200.0
	s.run_bananas = 200.0
	var q := Economy.buy_producer(s, "intern", 1)
	runner.check(not q.is_empty() and s.owned_of("intern") == 1, "bought one intern")
	_eq(Economy.derive(s).bps, 0.4, "one intern = 0.4 bps")
	runner.check(Economy.available_upgrades(s).map(func(u: Dictionary) -> String: return u["id"]).has("glove"), "glove on the shelf at 50 run bananas")
	runner.check(Economy.buy_upgrade(s, "glove"), "glove bought")
	runner.check(not Economy.buy_upgrade(s, "glove"), "an upgrade is bought once")
	_eq(Economy.derive(s).tap_value_no_crit, 2.0, "glove doubles the tap")


func test_producer_mult_and_per_row_bps() -> void:
	var s := GameState.fresh()
	s.owned["intern"] = 10
	s.upgrades.append("internx2")
	var d := Economy.derive(s)
	_eq(d.bps, 8.0, "10 interns with coffee = 8 bps")
	_eq(float(d.producer_bps["intern"]), 8.0, "per-row bps line")


func test_tap_crit_and_limiter() -> void:
	var s := GameState.fresh()
	var r := Economy.tap(s, func() -> float: return 0.0)
	runner.check(r["crit"] and is_equal_approx(float(r["value"]), 10.0), "a roll of 0 crits for x10")
	runner.check(s.crits_lifetime == 1 and s.taps_lifetime == 1, "tap counters")
	var lim := TapLimiter.new(16)
	var ok := 0
	for i in 40:
		if lim.try_register(1000.0 + i * 10.0):
			ok += 1
	runner.check(ok == 16, "16 taps register within one second (got %d)" % ok)
	runner.check(lim.try_register(2100.0), "the window slides after a second")


func test_golden_outcomes_do_not_stack() -> void:
	var s := GameState.fresh()
	s.owned["tree"] = 10
	Economy.apply_golden(s, "frenzy")
	_eq(s.buff_frenzy, 15.0, "frenzy lasts 15 s")
	_eq(Economy.derive(s).bps_effective, Economy.derive(s).bps * 5.0, "frenzy x5")
	Economy.tick(s, 5.0)
	Economy.apply_golden(s, "frenzy")
	_eq(s.buff_frenzy, 15.0, "a second frenzy refreshes, never stacks")
	var bps := Economy.buffless_bps(s)
	var award := Economy.apply_golden(s, "bunch")
	_eq(award, 60.0 * bps, "Lucky Bunch pays 60 s of buffless bps")


func test_evolve_gate_and_reset() -> void:
	var s := GameState.fresh()
	s.all_time_bananas = 999_000.0   # cbrt(999) = 9.99 -> 9 Thumbs, under the floor of 10
	runner.check(Economy.evolve(s).is_empty(), "the gate is closed below 10 pending")
	s.all_time_bananas = 1_000_000.0
	s.bananas = 5.0
	s.owned["intern"] = 3
	var r := Economy.evolve(s)
	runner.check(r.get("gained") == 10, "evolve grants 10 Thumbs at 1M all-time")
	runner.check(s.thumbs_owned == 10 and s.evolutions == 1 and s.owned_of("intern") == 0 and s.bananas == 0.0, "run reset, thumbs kept")
	_eq(Economy.derive(s).prestige_mult, 2.0, "10 Thumbs = x2")
	runner.check(Economy.derive(s).needed == 10, "the doubling gate needs max(10, owned)")


func test_away_award_is_continuous_and_capped() -> void:
	var s := GameState.fresh()
	s.owned["tree"] = 10            # 24 bps
	var a59 := float(Economy.away_award(s, 59.0)["award"])
	var a61 := float(Economy.away_award(s, 61.0)["award"])
	_eq(a59, 59.0 * 24.0, "under a minute pays full rate")
	runner.check(a61 > a59, "no cliff at 60 s (v1 paid 30.5 s at 61 s)")
	var big := Economy.away_award(s, 100000.0)
	runner.check(big["capped"], "8 h cap reached")
	_eq(float(big["award"]), 24.0 * (60.0 + (28800.0 - 60.0) * 0.5), "cap pays 60 s full then half rate")
	s.buff_frenzy = 10.0
	_eq(float(Economy.away_award(s, 59.0)["award"]), 59.0 * 24.0, "buffs never count while away")
	_eq(float(Economy.away_award(s, -500.0)["award"]), 0.0, "clock moved back pays nothing")


func test_species_titles() -> void:
	runner.check(Content.species_title(0) == "Monkeys", "run 1 title")
	runner.check(Content.species_title(7) == "Ascended Bunch Mk 1", "last title gets Mk 1")
	runner.check(Content.species_title(9) == "Ascended Bunch Mk 3", "and counts up")
