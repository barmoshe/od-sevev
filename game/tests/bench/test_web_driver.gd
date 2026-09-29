extends RefCounted
## The 34-vs-8-minute gap (HANDOFF "Next" 3, Designer): a scripted browser round
## (tools/web/round_web.mjs at ?speed=10) reached the first election at 34:24 of play while this
## bench says about 8:00. Neither the game nor the bench is wrong: the driver is a different player.
## It acts in wall-clock time (four hat taps, one source card and a look at the chat per loop of
## several real seconds under software rendering) while the dev clock runs the game 10× faster, so
## in GAME time it taps and buys dozens of times less often than the median player, never buys a
## spin, never catches the Suitcase and buys the priciest card instead of the best payback.
##
## This bench replays the driver's measured cadence (round_web.mjs prints it; the numbers below are
## the 2026-09-29 run at 390×844 @2, speed 10: 0.037 taps/s, a purchase action every 138 s of
## 3 card taps, the chat every 303 s, round 1 at 25:16 of play) through PacingSim on the real
## Economy + Politics. If the bench lands near the browser's round, the bench models the game and
## the gap is the player; if it ever drifts far, the game and the bench disagree and one of them
## has a bug.

var runner: Object

## tools/web/round_web.mjs in game seconds (its "cadence" line).
const DRIVER := {
	"tps": 0.037, "tap_until": INF, "catch_golden": false,
	"buy_every": 138.0, "buy_units": 3, "buy": "priciest", "spins": false,
	"politics_every": 303.0, "ping_after_buy": 20.0,
	"politics": {"coalition": "all", "court": "testify"},
}
const BROWSER_ROUND_SEC := 1516.0   # the same run's first election (round_web "gate: … run 1516s")


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
	runner.check(median_player >= 7.0 * 60.0 and median_player <= 9.0 * 60.0, "and the median player still calls it in 7-9 min (%s)" % PacingSim.fmt_t(median_player))
