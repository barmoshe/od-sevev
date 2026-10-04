extends RefCounted
## The 34-vs-8-minute gap (HANDOFF "Next" 3, Designer): a scripted browser round
## (tools/web/round_web.mjs at ?speed=10) reached the first election at 34:24 of play while this
## bench says about 8:00. Neither the game nor the bench is wrong: the driver is a different player.
## It acts in wall-clock time (four hat taps, one source card and a look at the chat per loop of
## several real seconds under software rendering) while the dev clock runs the game 10× faster, so
## in GAME time it taps and buys dozens of times less often than the median player, never buys a
## spin, never catches the Suitcase and buys the priciest card instead of the best payback.
##
## This bench replays the driver's measured cadence (round_web.mjs prints it) through PacingSim on
## the real Economy + Politics. Re-recorded 2026-10-02 (the driver was rewritten on 09-30: it pays
## the chat on every loop, and LEADER=bibi pins the round the bench replays): three runs of
## `LEADER=bibi node tools/web/round_web.mjs <url> <out> 390x844@2 10 1200` on build 747a771 gave
## round 1 at 32:21, 62:34 and 40:11 of play (median 40:11) at 0.020-0.022 taps/s, a purchase action
## every 182-334 s (median 214) of 2-3 card taps, the chat every 167-214 s (median 200). The
## 2026-09-29 numbers (0.037 / 138 / 303, round 1 at 25:16) described the old driver. Re-recorded
## 2026-10-04 on build 1e3a3d2 (ADR 0013: round 1 shorter, the suspicion meter and Mordechai in it), same
## command, three runs: round 1 at 12:25, 13:50 and 15:37 of play (median 13:50) at 0.058-0.062 taps/s, a
## purchase action every 73-137 s (median 75) of about 2 card taps, the chat every 97-98 s. If the bench
## lands near the browser's round, the bench models the game and the gap is the player; if it ever
## drifts far, the game and the bench disagree and one of them has a bug.

var runner: Object

## tools/web/round_web.mjs in game seconds (its "cadence" line).
const DRIVER := {
	"tps": 0.061, "tap_until": INF, "catch_golden": false,
	"buy_every": 75.4, "buy_units": 2, "buy": "priciest", "spins": false,
	"politics_every": 97.7, "ping_after_buy": 20.0,
	"politics": {"coalition": "all", "court": "testify"},
}
const BROWSER_ROUND_SEC := 830.0   # the median run's first election (round_web "gate: … run 830s", 2026-10-04)


func test_the_browser_driver_is_a_slow_player_not_a_slow_game() -> void:
	if not PacingSim.politics_on():
		return
	var ts: Array = []
	for sd: int in [1, 2, 3]:
		var r := PacingSim.first_round("", DRIVER, sd, 3600.0, 0.25)
		ts.append(float(r["gate_t"]) if float(r["gate_t"]) >= 0.0 else INF)
	ts.sort()
	var med := float(ts[1])
	var median_player := float(PacingSim.first_round("", PacingSim.PLAYERS["median"], 7, 1800.0, 0.25)["gate_t"])
	print("  web driver cadence, seeds 1-3: %s (median %s); the browser measured %s; the median player %s" % [
		", ".join(ts.map(func(x: float) -> String: return PacingSim.fmt_t(x))), PacingSim.fmt_t(med),
		PacingSim.fmt_t(BROWSER_ROUND_SEC), PacingSim.fmt_t(median_player)])
	runner.check(med >= BROWSER_ROUND_SEC * 0.7 and med <= BROWSER_ROUND_SEC * 1.3,
		"the bench replays the browser round within ±30%% (bench %s, browser %s)" % [PacingSim.fmt_t(med), PacingSim.fmt_t(BROWSER_ROUND_SEC)])
	runner.check(median_player >= 4.0 * 60.0 and median_player <= 5.0 * 60.0, "and the median player still calls it in 4-5 min (ADR 0013) (%s)" % PacingSim.fmt_t(median_player))
