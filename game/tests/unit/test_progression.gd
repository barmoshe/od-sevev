extends RefCounted
## The review's stall (ux/review-2026-09-29.md "Not reached at runtime": scripted play at speed 10
## stopped at 44/61 while one partner looped demand → ultimatum → leave → rejoin). A player who
## pays the chat reaches the 61 gate in round 1 on the shipped content, played through the real
## Economy + Politics (like PacingSim), even a slow one who pays only the newest pill every 10 s,
## or pays everything only every 130 s (the review script's cadence at speed 10). The stall was
## the script's: it paid only the pills visible at the bottom of the thread, and the pending
## partners' join demands (which never expire) sat above the fold (STATUS.md, views wave).

var runner: Object


func setup(_r: Object) -> void:
	TestFixture.use_game_content()


## One round: taps at 1.5/s, catches Suitcases, buys the greedy best source, testifies, ends
## brawls; every `every` seconds pays the open payable messages (all, or the `newest` N).
## Returns {gate: seconds or -1, seats, left, rejoins}.
## `force_brawl`: the brawl event fires once the group has 3 members (the scheduler's draw is luck, and
## the brawl tests need one).
static func play_round(every: float, newest: int, seed_: int, max_t: float = 1200.0, brawls: bool = true, force_brawl: bool = false) -> Dictionary:
	var s := GameState.fresh()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_
	var r := func() -> float: return rng.randf()
	var t := 0.0
	var dt := 0.25
	var acc := 0.0
	var next_visit := every
	var ctx := {"allowPing": true, "weekday": 2, "hour": 12}
	var d := Economy.derive(s)
	while t < max_t:
		acc += 1.5 * dt
		while acc >= 1.0:
			acc -= 1.0
			Economy.tap(s, r)
		d = Economy.derive(s)
		Economy.tick(s, dt, d)
		if Economy.tick_golden_timer(s, dt):
			Economy.apply_golden(s, Economy.roll_golden_outcome(r, s))
			Economy.schedule_next_golden(s, r)
		Politics.tick(s, dt, d, ctx, r)
		if force_brawl and Coalition.member_count(s) >= 3 and not (s.events["round"] as Array).has("brawl"):
			Events.fire(s, "brawl", d, r)
		if Investigation.phase(s) == "summons":
			Investigation.testify(s)
		var b := Coalition.open_brawl(s)
		if brawls and not b.is_empty():
			Coalition.resolve_brawl(s, int(b["seq"]))
		if t >= next_visit:
			next_visit = t + every
			var open: Array = []
			for m: Dictionary in s.coalition["chat"]:
				if m["state"] == "open" and Coalition.is_payable(m):
					open.append(m)
			if newest > 0:
				open = open.slice(maxi(0, open.size() - newest))
			for m: Dictionary in open:
				if s.bananas >= float(m.get("price", 0.0)):
					Coalition.pay(s, int(m["seq"]), true)
		d = Economy.derive(s)
		var best := {} if s.bananas < PacingSim._cheapest(s, d) else PacingSim._best_buy(s, d, 1.5, true, 10.0, {})
		if not best.is_empty() and s.bananas >= float(best["cost"]) and not best.has("upgrade"):
			var id: String = best["producer"]
			var n := Economy.max_affordable(s, id)
			Economy.buy_producer(s, id, maxi(1, n / 2) if n >= 10 else 1)
		if d.evolve_enabled:
			return {"gate": t, "seats": int(Coalition.seat_info(s)["effective"]), "left": int(s.coalition["leftLifetime"]),
				"rejoins": int(s.coalition["rejoinsLifetime"])}
		t += dt
	return {"gate": -1.0, "seats": int(Coalition.seat_info(s)["effective"]), "left": int(s.coalition["leftLifetime"]),
		"rejoins": int(s.coalition["rejoinsLifetime"])}


func test_a_player_who_pays_the_chat_reaches_61() -> void:
	for pol: Array in [[10.0, 1, 7], [130.0, 0, 3]]:
		var res := play_round(pol[0], pol[1], pol[2])
		runner.check(float(res["gate"]) > 0.0 and float(res["gate"]) <= 900.0,
			"paying %s every %ds (seed %d) opens the 61 gate within 15 min of round 1 (gate %s, seats %d, walked out %d, rejoined %d)" % [
			"the newest pill" if int(pol[1]) == 1 else "every pill", int(pol[0]), int(pol[2]),
			PacingSim.fmt_t(float(res["gate"])) if float(res["gate"]) > 0.0 else "never", int(res["seats"]), int(res["left"]), int(res["rejoins"])])


## The browser replay's stall (tools/web/round_web.mjs paid 194 pills and hovered at 42-50/61 for
## 100 min of play): the brawl freezes its two rows (out of the 61) until "צאו החוצה", a button
## inside T3 that neither the review's script nor the replay pressed. Paying alone is not enough;
## this pins the rule so the view keeps surfacing the brawl (the tab badge counts it, a toast says
## it with the chat closed: test_chat_view).
func test_an_unended_brawl_keeps_the_round_below_61() -> void:
	var stuck := play_round(30.0, 0, 11, 1500.0, false, true)
	var ended := play_round(30.0, 0, 11, 1500.0, true, true)
	runner.check(float(stuck["gate"]) < 0.0 and int(stuck["seats"]) < 61,
		"paying every pill but never pressing 'צאו החוצה' stays below 61 for 25 min (seats %d)" % int(stuck["seats"]))
	runner.check(float(ended["gate"]) > 0.0, "ending the brawl opens the gate (%s)" % PacingSim.fmt_t(float(ended["gate"])))


## The pills the review's script never reached: a pending partner's join demand neither expires
## nor escalates, however long it waits, so scrolling up to it always seats the partner.
func test_a_join_demand_waits_for_the_player() -> void:
	var s := GameState.fresh()
	s.coalition["opened"] = true
	s.coalition["nextDemandSec"] = 1e12
	s.coalition["paidLifetime"] = 5
	s.stats["playtimeSec"] = 3600.0
	Coalition.ps(s, "bengvir")["status"] = "member"
	var out: Array = []
	Coalition._post_join(s, "regev", Economy.derive(s), func() -> float: return 0.0, out)
	var join := Coalition.open_msg(s, "regev")
	runner.check(not join.is_empty() and bool(join.get("join", false)), "Regev joins with an open join demand")
	for i in 1200:   # 20 min of visible play
		Coalition.tick(s, 1.0, Economy.derive(s), {}, func() -> float: return 0.99)
	runner.check(str(join.get("state", "")) == "open" and Coalition.status(s, "regev") == "pending",
		"after 20 min the join demand is still open and Regev still pending (%s, %s)" % [join.get("state", ""), Coalition.status(s, "regev")])
	runner.check(Coalition.open_ultimatums(s) == 0, "a join demand never escalates to an ultimatum")
	var r := Coalition.pay(s, int(join["seq"]), true)
	runner.check(bool(r.get("ok", false)) and Coalition.status(s, "regev") == "member", "paying it seats Regev")
