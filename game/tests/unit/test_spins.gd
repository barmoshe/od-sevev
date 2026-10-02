extends RefCounted
## Spin kinds and the five spin effects that were held (game/scripts/sim/spins.gd): consumables with
## fatigue (S02 tapBuff, S07 idleToTap, S12's freeze), the line (S08 karhiLine), S10 flightIncome,
## S05 basePerOppositionCard, costBpsSeconds pricing, the pendingEngine hold, and the save. The
## fixture spins below pin the rules; the last tests check the shipped content has no hold left.

const PF := preload("res://tests/politics_fixture.gd")

var runner: Object

const SPINS := [
	{"id": "t_buff", "kind": "consumable", "cost": 100, "fatigue": 0.8, "unlock": {},
		"effect": {"type": "tapBuff", "mult": 1.5, "durationSec": 60}},
	{"id": "t_pour", "kind": "consumable", "cost": 100, "costBpsSeconds": 60, "fatigue": 0.8, "unlock": {},
		"effect": {"type": "idleToTap", "durationSec": 30, "pourSecPerTap": 0.5}},
	{"id": "t_freeze", "kind": "consumable", "cost": 10, "fatigue": 0.8, "unlock": {},
		"effect": {"type": "suspicionFreeze", "durationSec": 60}},
	{"id": "t_line", "kind": "line", "cost": 100, "levels": [{"cost": 100}, {"cost": 1000}, {"cost": 10000}], "unlock": {},
		"effect": {"type": "karhiLine", "broadcasterDrainPct": 20, "basePctThisRound": 2, "suspicionAdd": 4}},
	{"id": "t_flight", "kind": "once", "cost": 10, "unlock": {}, "effect": {"type": "flightIncome", "addPct": 5, "capPct": 50}},
	{"id": "t_witch", "kind": "once", "cost": 10, "unlock": {}, "effect": {"type": "basePerOppositionCard", "add": 1}},
	{"id": "t_held", "kind": "once", "cost": 1, "unlock": {"pendingEngine": true}, "effect": {"type": "notBuiltYet"}},
]


func setup(_r: Object) -> void:
	var c := PF.build()
	for u: Dictionary in SPINS:
		(c["upgrades"] as Array).append(u.duplicate(true))
	Content.replace(c)


func teardown() -> void:
	PF.restore()


static func _no_crit() -> float:
	return 0.999


func _eq(a: float, b: float, msg: String) -> void:
	runner.check(absf(a - b) <= 1e-6 * maxf(1.0, absf(b)), "%s (got %s, want %s)" % [msg, a, b])


func _shelf(s: GameState) -> Array:
	return Economy.available_upgrades(s).map(func(u: Dictionary) -> String: return u["id"])


func _tick(s: GameState, sec: float, step: float = 0.5) -> void:
	var t := 0.0
	while t < sec - 1e-9:
		Economy.tick(s, step)
		t += step


func test_the_fixture_passes_the_contract_lint() -> void:
	var err := Politics.validate()
	runner.check(err.is_empty(), "Politics.validate: %s" % str(err))
	runner.check(Politics.unimplemented_effects().has("notBuiltYet") and Politics.unimplemented_effects().size() == 1,
		"only the held spin's effect is unimplemented: %s" % str(Politics.unimplemented_effects()))


func test_pending_engine_holds_a_spin_off_the_shelf() -> void:
	var s := GameState.fresh()
	s.bananas = 1e9
	runner.check(not _shelf(s).has("t_held") and not Economy.buy_upgrade(s, "t_held"), "unlock.pendingEngine: true never unlocks")
	var bad := PF.build()
	(bad["upgrades"] as Array).append({"id": "t_bad", "cost": 1, "unlock": {}, "effect": {"type": "notBuiltYet"}})
	runner.check(Politics.validate(bad).size() == 1, "an unimplemented effect without the hold fails the lint")


func test_consumable_tap_buff_fades_and_comes_back() -> void:
	var s := GameState.fresh()
	s.bananas = 1000.0
	var base := Economy.derive(s).tap_value_no_crit
	runner.check(Economy.buy_upgrade(s, "t_buff"), "S02 bought")
	_eq(s.bananas, 900.0, "for its cost")
	_eq(Economy.derive(s).tap_value_no_crit, base * 1.5, "taps ×1.5 while live")
	runner.check(not s.upgrades.has("t_buff") and not _shelf(s).has("t_buff"), "off the shelf while live, never in s.upgrades")
	runner.check(not Economy.buy_upgrade(s, "t_buff"), "can't stack it")
	var c := Spins.card(s, "t_buff")
	runner.check(bool(c["worn"]) and is_equal_approx(float(c["liveSec"]), 60.0), "the card: worn, 60 s live")
	_tick(s, 59.5)
	_eq(Economy.derive(s).tap_value_no_crit, base * 1.5, "still up at 59.5 s")
	var ended: Dictionary = Economy.tick(s, 0.5)
	runner.check((ended["spinsEnded"] as Array).has("t_buff"), "Economy.tick reports it ending")
	_eq(Economy.derive(s).tap_value_no_crit, base, "then taps are back to normal")
	runner.check(_shelf(s).has("t_buff"), "and the card is back on the shelf")
	runner.check(is_equal_approx(float(Spins.card(s, "t_buff")["nextSec"]), 48.0), "the card names the rebuy's seconds: 60 × 0.8")
	Economy.buy_upgrade(s, "t_buff")
	# Bar 2026-10-02: fatigue shortens a rebuy, never weakens it ("×1.5" on the card stays true)
	_eq(Economy.derive(s).tap_value_no_crit, base * 1.5, "the rebuy is still ×1.5")
	runner.check(is_equal_approx(float(Spins.live(s, "t_buff")["leftSec"]), 48.0), "for 60 × 0.8 = 48 s")
	_tick(s, 48.0)
	Economy.buy_upgrade(s, "t_buff")
	runner.check(is_equal_approx(float(Spins.live(s, "t_buff")["leftSec"]), 38.4), "and again: 60 × 0.8² = 38.4 s")
	Economy.reset_run(s)   # what an election does to the run
	runner.check(Spins.buys(s, "t_buff") == 0 and Spins.active_effects(s).is_empty(), "the round's fatigue and timers reset")


func test_idle_to_tap_pours_the_income_into_taps() -> void:
	var s := GameState.fresh()
	s.owned[Content.producer_ids()[1]] = 10
	var d := Economy.derive(s)
	var bps := d.bps
	var tap0 := d.tap_value_no_crit
	s.bananas = 1e9
	var want := maxf(100.0, Spins.ceil_sig(60.0 * bps, 3))
	_eq(Economy.upgrade_price(s, "t_pour"), want, "costBpsSeconds: 60 s of ₪/s (3 significant digits), at least cost")
	runner.check(Economy.buy_upgrade(s, "t_pour"), "S07 bought")
	_eq(s.bananas, 1e9 - want, "for that price")
	var d2 := Economy.derive(s)
	_eq(d2.bps_effective, 0.0, "passive income stops")
	_eq(d2.bps, bps, "but ₪/s itself (prices, suspicion shares) is unchanged")
	_eq(d2.tap_value_no_crit, tap0 + 0.5 * bps, "each tap pays tapValue + bps × 0.5")
	var before := s.bananas
	Economy.tick(s, 1.0)
	_eq(s.bananas, before, "no accrual while it runs")
	var r := Economy.tap(s, func() -> float: return 0.0)   # a rabbit
	var cm := float(Content.data()["tap"]["critMult"])
	runner.check(r["crit"] == true, "a rabbit")
	_eq(float(r["value"]), tap0 * cm + 0.5 * bps, "a rabbit multiplies the tap, not the pour")
	_tick(s, 29.0)
	_eq(Economy.derive(s).bps_effective, bps, "30 s later the income flows again")
	Economy.buy_upgrade(s, "t_pour")
	_eq(float(Spins.live(s, "t_pour")["leftSec"]), 24.0, "the rebuy's duration fades (no mult): 30 × 0.8")


func test_consumable_freeze_fades_its_duration() -> void:
	var s := GameState.fresh()
	s.bananas = 1000.0
	Economy.buy_upgrade(s, "t_freeze")
	_eq(float(s.investigation["frozenSec"]), 60.0, "S12: suspicion frozen 60 s")
	_tick(s, 60.0)
	s.investigation["frozenSec"] = 0.0
	Economy.buy_upgrade(s, "t_freeze")
	_eq(float(s.investigation["frozenSec"]), 48.0, "the rebuy freezes 48 s")


func test_line_levels_in_order() -> void:
	var s := GameState.fresh()
	s.bananas = 20000.0
	_eq(Economy.upgrade_price(s, "t_line"), 100.0, "level 1 costs 100")
	runner.check(Economy.buy_upgrade(s, "t_line"), "level 1 bought")
	_eq(Economy.upgrade_price(s, "t_line"), 1000.0, "level 2 costs 1,000")
	_eq(Economy.derive(s).base_pct_round, 2.0, "+2% on this round's base")
	_eq(Investigation.suspicion(s), 4.0, "+4 suspicion")
	runner.check(_shelf(s).has("t_line") and not s.upgrades.has("t_line"), "still on the shelf")
	Economy.buy_upgrade(s, "t_line")
	Economy.buy_upgrade(s, "t_line")
	_eq(s.bananas, 20000.0 - 11100.0, "each level at its own cost")
	_eq(Economy.derive(s).base_pct_round, 6.0, "3 levels: +6%")
	var c := Spins.card(s, "t_line")
	runner.check(int(c["level"]) == 3 and is_equal_approx(float(c["bars"]["public"]), 40.0) and is_equal_approx(float(c["bars"]["friendly"]), 60.0),
		"the card's bars: public 40, friendly 60")
	runner.check(not _shelf(s).has("t_line") and s.upgrades.has("t_line") and Economy.upgrade_price(s, "t_line") < 0.0, "done: off the shelf")
	runner.check(not Economy.buy_upgrade(s, "t_line"), "no fourth level")
	Economy.reset_run(s)
	runner.check(Spins.level(s, "t_line") == 0 and is_equal_approx(Economy.derive(s).base_pct_round, 0.0), "resets on election")


func test_flight_income_counts_catches_after_buying() -> void:
	var s := GameState.fresh()
	s.owned[Content.producer_ids()[0]] = 10
	var bps := Economy.derive(s).bps
	var bunch: String = Content.data()["golden"]["outcomes"][0]["id"]
	Economy.apply_golden(s, bunch)
	s.bananas = 100.0
	Economy.buy_upgrade(s, "t_flight")
	_eq(Economy.derive(s).bps, bps, "no flight yet: nothing")
	Economy.apply_golden(s, bunch)
	Economy.apply_golden(s, bunch)
	_eq(Economy.derive(s).bps, bps * 1.10, "two Suitcases after buying: +10%")
	for i in 20:
		Economy.apply_golden(s, bunch)
	_eq(Economy.derive(s).bps, bps * 1.5, "capped at +50%")
	runner.check(is_equal_approx(float(Spins.card(s, "t_flight")["flightPct"]), 50.0), "the card shows +50%")
	Economy.reset_run(s)
	runner.check(int(s.spins["flights"]) == 0, "the flights reset with the round")


func test_opposition_cards_pay_base_with_the_witch_hunt() -> void:
	var s := GameState.fresh()
	var d := Economy.derive(s)
	Events.fire(s, "liberman", d)
	runner.check(s.thumbs_owned == 0, "without S05 an opposition card pays nothing")
	s.bananas = 100.0
	Economy.buy_upgrade(s, "t_witch")
	var r := Events.fire(s, "liberman", d)
	runner.check(s.thumbs_owned == 1 and int(r["result"]["baseAdd"]) == 1, "with S05 it adds +1 base")
	Events.fire(s, "leak", d)
	runner.check(s.thumbs_owned == 1, "a non-opposition card doesn't")


func test_spins_survive_the_save_and_are_sanitized() -> void:
	var s := GameState.fresh()
	s.bananas = 1e6
	Economy.buy_upgrade(s, "t_buff")
	Economy.buy_upgrade(s, "t_line")
	Economy.buy_upgrade(s, "t_flight")
	Economy.apply_golden(s, Content.data()["golden"]["outcomes"][0]["id"])
	var l := GameState.from_dict(JSON.parse_string(JSON.stringify(s.to_dict())))
	runner.check(JSON.stringify(l.spins, "", true) == JSON.stringify(s.spins, "", true), "the spins section round-trips")
	_eq(Economy.derive(l).tap_value_no_crit, Economy.derive(s).tap_value_no_crit, "the live buff survives a reload")
	var raw := s.to_dict()
	raw["spins"] = {"buys": {"t_buff": 3, "ghost": 2, "t_flight": 9}, "levels": {"t_line": 99, "t_buff": 1},
		"active": [{"id": "t_buff", "leftSec": 9999, "mult": 50.0}, {"id": "t_buff", "leftSec": 5}, {"id": "nope", "leftSec": 5}],
		"flights": 1000}
	var b := GameState.from_dict(raw)
	runner.check(int(b.spins["buys"].get("t_buff", 0)) == 3 and b.spins["buys"].size() == 1, "buys: consumables only")
	runner.check(int(b.spins["levels"]["t_line"]) == 3 and b.spins["levels"].size() == 1, "levels clamped to the line")
	var a: Array = b.spins["active"]
	runner.check(a.size() == 1 and float(a[0]["leftSec"]) == 60.0 and float(a[0]["mult"]) == 1.5, "a live timer can't outgrow the content: %s" % str(a))
	runner.check(int(b.spins["flights"]) == 10, "flights clamped to the cap")


func test_shipped_content_has_no_held_spin() -> void:
	Content.load_from(Content.PATH)
	var err := Politics.validate()
	runner.check(err.is_empty(), "the design content passes: %s" % str(err))
	runner.check(Politics.unimplemented_effects().is_empty(), "no spin effect is unimplemented: %s" % str(Politics.unimplemented_effects()))
	for u: Dictionary in Content.upgrades():
		runner.check(not Spins.held(u), "%s is not held any more" % u["id"])
	var s := GameState.fresh()
	s.run_bananas = 60000.0
	s.bananas = 1e6
	var shelf := _shelf(s)
	runner.check(shelf.has("s02") and shelf.has("s07"), "S02 and S07 reach the shelf in round 1: %s" % str(shelf))
	runner.check(Economy.buy_upgrade(s, "s02") and _shelf(s).has("s07"), "S02 is bought as a consumable")
