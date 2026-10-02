extends SceneTree
## Throwaway (never commit): per-round times under content overrides.
## env PROBE_JSON = {"coalition.unlockScalePerElection": 2, ...}; PROBE_SEEDS = "7,1,2"; PROBE_PROFILE; PROBE_LEADER

func _set_path(c: Dictionary, path: String, v: Variant) -> void:
	var parts := path.split(".")
	var cur: Variant = c
	for i in parts.size() - 1:
		var k := parts[i]
		if cur is Array:
			for e: Dictionary in cur:
				if str(e.get("id", "")) == k:
					cur = e
					break
		else:
			cur = (cur as Dictionary)[k]
	(cur as Dictionary)[parts[parts.size() - 1]] = v


func _initialize() -> void:
	var c: Dictionary = Content.data().duplicate(true)
	var oj := OS.get_environment("PROBE_JSON")
	if oj != "":
		var o: Dictionary = JSON.parse_string(oj)
		for k: String in o:
			_set_path(c, k, o[k])
	Content.replace(c)
	var seeds := OS.get_environment("PROBE_SEEDS")
	if seeds == "":
		seeds = "7"
	var prof := OS.get_environment("PROBE_PROFILE")
	if prof == "":
		prof = "median"
	var leader := OS.get_environment("PROBE_LEADER")
	if OS.get_environment("PROBE_DIAG") != "":
		_diag(int(seeds.split(",")[0]), prof)
		quit(0)
		return
	for sd_s in seeds.split(","):
		var sd := int(sd_s)
		var p: Dictionary = PacingSim.PLAYERS[prof].duplicate()
		if leader != "":
			p["leader"] = leader
		var r := PacingSim.session(p, 3600.0, sd, 0.25)
		var runs: Array = r["runs"]
		print("%s %s s%d | %s | base %d gap %s" % [prof, leader, sd, ", ".join(runs.map(func(x: float) -> String: return PacingSim.fmt_t(x))), int(r["thumbs"]), PacingSim.fmt_t(r["maxGap"])])
	quit(0)


var _trace_on := false


func _diag(seed_: int, prof: String) -> void:
	var tr := int(OS.get_environment("PROBE_ROUND"))
	var player: Dictionary = PacingSim.PLAYERS[prof]
	var s := GameState.fresh()
	Leaders.set_salt(s, seed_)
	var t0 := 0.0
	var n := 0
	while t0 < 3599.0 and n < 14:
		var ev: Array = []
		_trace_on = tr == n + 1
		var r := _run_trace(s, player, seed_ + n, 3600.0 - t0, true, 0.25, ev)
		t0 += float(r["t"])
		var si := Coalition.seat_info(s)
		var mem: Array = []
		for p: Dictionary in Coalition.partners():
			var st := Coalition.status(s, p["id"])
			if st != "absent":
				var u := Coalition.unlock_of(s, p)
				mem.append("%s:%s%s" % [p["id"], st.substr(0, 3), "(%s/%s)" % [PacingSim.fmt_t(float(u.get("runSecAtLeast", 0))), _k(float(u.get("runBananasAtLeast", 0)))] if u.has("runSecAtLeast") else ""])
		var d := Economy.derive(s)
		var evs: Array = []
		for e: Array in ev:
			var w: String = e[1]
			if w.begins_with("event:") or w == "court" or w == "ultimatum" or w.begins_with("Joined") or w.begins_with("Left") or w.begins_with("arrive"):
				evs.append("%s@%s" % [w, PacingSim.fmt_t(float(e[0]))])
		print("R%d %s | earned %s mult %.1f bps %s | own %d partners %d eff %d/%d | %s" % [n + 1, PacingSim.fmt_t(float(r["t"])), _k(s.run_bananas), d.prestige_mult, _k(d.bps), int(si["own"]), int(si["partners"]), int(si["effective"]), int(si["gateSeats"]), " ".join(mem)])
		print("     events: %s | court days %d left %d" % [" ".join(evs), int(s.investigation.get("courtDays", 0)), int(s.coalition.get("leftLifetime", 0))])
		if float(r["gate_t"]) < 0.0:
			break
		Meta.evolve(s)
		while Meta.can_buy_any_perk(s):
			var best := ""
			var best_c := 1 << 30
			for p: Dictionary in Meta.perks():
				var c := Meta.next_cost(s, p["id"])
				if c >= 0 and c < best_c:
					best_c = c
					best = p["id"]
			Meta.buy_perk(s, best)
		n += 1


func _k(v: float) -> String:
	if v >= 1e12: return "%.1fT" % (v / 1e12)
	if v >= 1e9: return "%.1fB" % (v / 1e9)
	if v >= 1e6: return "%.1fM" % (v / 1e6)
	if v >= 1e3: return "%.0fK" % (v / 1e3)
	return "%.0f" % v


func _run_trace(s: GameState, player: Dictionary, seed_: int, max_t: float = 3600.0, evolve_at_gate: bool = true, dt: float = 0.1, events: Array = []) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_
	var r := func() -> float: return rng.randf()
	# Politics draws from its own stream: taps (crits) and the Suitcase consume `r` at rates that
	# differ by strategy, and a shared stream re-dealt every card after the first difference, so G1's
	# strategy-vs-default ratios swung ±40% per seed on noise (2026-10-02 probes)
	var prng := RandomNumberGenerator.new()
	prng.seed = seed_ * 7919 + 29
	var rp := func() -> float: return prng.randf()
	var tps := minf(float(player["tps"]), float(Content.data()["tap"]["maxRegisteredTapsPerSec"]))
	var crit_mult := float(Content.data()["tap"]["critMult"])
	var first := {}
	var t := 0.0
	var acc := 0.0
	var auto_acc := 0.0
	var butler_ms := 0.0
	var gate_t := -1.0
	var d := Economy.derive(s)
	var milestones_seen := {}
	var pol := PacingSim.politics_on()
	var strat := PacingSim.strategy(player)
	# Mordechai David's periodic roll from the seed, never the clock (Events._every_roll is salted by
	# the wall clock), so a bench run repeats
	var every_rng := RandomNumberGenerator.new()
	every_rng.seed = seed_ * 7919 + 3
	var ctx := {"allowPing": true, "weekday": 2, "hour": 12, "everyRoll": func() -> float: return every_rng.randf()}
	var buy_every := float(player.get("buy_every", 0.0))
	var buy_units := int(player.get("buy_units", 0))
	var pol_every := float(player.get("politics_every", 0.0))
	var ping_gap := float(player.get("ping_after_buy", 0.0))
	var last_buy := -INF
	var last_pol := -INF
	while t < max_t:
		# Mordechai David's block (Events.screen_blocked): nothing takes a tap, the player's or the perks'
		var tapping := tps if t < float(player["tap_until"]) and not Events.screen_blocked(s) else 0.0
		acc += tapping * dt
		while acc >= 1.0:
			acc -= 1.0
			Economy.tap(s, r)
		auto_acc += Meta.auto_tap_rate(s) * dt if not Events.screen_blocked(s) else 0.0
		while auto_acc >= 1.0:
			auto_acc -= 1.0
			Economy.tap(s, r)
		butler_ms += dt * 1000.0
		if butler_ms >= 1000.0:
			butler_ms = 0.0
			var bought := Meta.auto_buy(s)
			if bought != "" and not first.has(bought):
				first[bought] = t
				events.append([t, "producer:" + bought])
		d = Economy.derive(s)
		Economy.tick(s, dt, d)
		if Economy.tick_golden_timer(s, dt):
			if player["catch_golden"] or Meta.auto_catch(s):
				Economy.apply_golden(s, Economy.roll_golden_outcome(r, s))
			Economy.schedule_next_golden(s, r)
		if pol:
			ctx["allowPing"] = ping_gap <= 0.0 or t - last_buy >= ping_gap
			for e: Dictionary in Politics.tick(s, dt, d, ctx, rp):
				if e["ev"] == "event":
					events.append([t, "event:" + String(e["id"])])
				elif e["ev"] == "courtStart":
					events.append([t, "court"])
				elif e["ev"] == "partnerJoined" or e["ev"] == "partnerLeft":
					events.append([t, "%s:%s eff %d" % [e["ev"].substr(7), e["partner"], int(Coalition.seat_info(s)["effective"])]])
				elif e["ev"] == "message" and str(e["msg"].get("key", "")) == "chat.sys.joined":
					events.append([t, "arrive:" + str(e["msg"]["partner"])])
				elif e["ev"] == "groupOpened":
					events.append([t, "c1"])   # the chat pings (pitch §11 Q2)
				elif e["ev"] == "message" and e["msg"].get("type", "") == "ultimatum":
					events.append([t, "ultimatum"])   # pitch §11 Q3: none before 3:00
			if t - last_pol >= pol_every:
				last_pol = t
				PacingSim.play_politics(s, strat)
		if _trace_on and fmod(t, 10.0) < dt * 0.5:
			var openm: Array = []
			for m: Dictionary in Coalition._c(s)["chat"]:
				if m["state"] == "open" and Coalition.is_payable(m):
					openm.append("%s/%s%s %s" % [m.get("partner", ""), str(m.get("type", "")), str(m.get("payable", "")), _k(float(m.get("price", 0.0)))])
			print("   t %s eff %d bank %s bps %s blk %s | %s" % [PacingSim.fmt_t(t), int(Coalition.seat_info(s)["effective"]), _k(s.bananas), _k(d.bps), str(Events.screen_blocked(s)), ", ".join(openm)])
		for a in Meta.check_achievements(s, d):
			events.append([t, "achievement:" + a])
		for id in Content.producer_ids():
			var nm := Meta.next_milestone(s.owned_of(id))
			var key := "%s>%d" % [id, s.owned_of(id)]
			if Meta.milestone_mult(s.owned_of(id)) > 1.0 and not milestones_seen.has(id + str(Meta.milestone_mult(s.owned_of(id)))):
				milestones_seen[id + str(Meta.milestone_mult(s.owned_of(id)))] = true
				events.append([t, "milestone:" + key])
		d = Economy.derive(s)
		# Nothing is affordable -> the greedy player can't buy this frame; skip ranking (same result).
		var best := {} if s.bananas < PacingSim._cheapest(s, d) or t - last_buy < buy_every else PacingSim._best_buy(s, d, tapping, player["catch_golden"], crit_mult, strat if pol else {}, player)
		if not best.is_empty() and s.bananas >= float(best["cost"]):
			last_buy = t
			if best.has("upgrade"):
				Economy.buy_upgrade(s, best["upgrade"])
				first["u:" + String(best["upgrade"])] = t
				events.append([t, "upgrade:" + String(best["upgrade"])])
			else:
				var id: String = best["producer"]
				if s.owned_of(id) == 0:
					first[id] = t
					events.append([t, "producer:" + id])
				# Late game the bank covers thousands of units: buy half of what it affords in one go
				# (the same greedy choice, without a loop pass per unit). Early on this is always 1.
				var n := Economy.max_affordable(s, id)
				Economy.buy_producer(s, id, clampi(buy_units, 1, maxi(1, n)) if buy_units > 0 else (maxi(1, n / 2) if n >= 10 else 1))
			# This frame already ticked the economy (dt of play, taps and politics), so the clock moves
			# too: without this, every purchase frame was dt of game time the bench never counted, and
			# its times ran about 5% short of s.run_time_sec (an ultimatum "at 2:51" was at 3:00 of play).
			t += dt
			continue
		if d.evolve_enabled and gate_t < 0.0:
			gate_t = t
			if evolve_at_gate:
				break
		t += dt
	return {"t": t, "gate_t": gate_t, "first": first, "state": s}


