extends RefCounted
## Pacing gates (design/progression-curve.md §7), measured by PacingSim on the real Economy.
## v1's JS sim reported first Evolve at 10:58 (engaged), 12:13 (casual) and 16:41 (idle); the
## port must stay inside a band around those, and inside the 10-15 min target for engaged play.

var runner: Object


func setup(_r: Object) -> void:
	TestFixture.use_fork_content()


func teardown() -> void:
	TestFixture.use_game_content()


func _gate(profile: String) -> float:
	var r := PacingSim.run(GameState.fresh(), PacingSim.PLAYERS[profile], 1, 3600.0, true, 0.2)
	return float(r["gate_t"])


func test_first_evolve_engaged() -> void:
	var t := _gate("engaged")
	print("    engaged first Evolve ", PacingSim.fmt_t(t))
	runner.check(t >= 9.0 * 60.0 and t <= 13.0 * 60.0, "engaged first Evolve in 9-13 min (v1 10:58), got %s" % PacingSim.fmt_t(t))


func test_first_evolve_idle() -> void:
	var t := _gate("idle")
	print("    idle first Evolve ", PacingSim.fmt_t(t))
	runner.check(t >= 14.0 * 60.0 and t <= 19.0 * 60.0, "idle first Evolve in 14-19 min (v1 16:41), got %s" % PacingSim.fmt_t(t))


func test_first_evolve_spammer_is_bounded() -> void:
	var t := _gate("spammer")
	print("    autoclicker first Evolve ", PacingSim.fmt_t(t))
	runner.check(t >= 5.5 * 60.0, "the tap cap keeps an autoclicker above 5:30 (v1 7:18), got %s" % PacingSim.fmt_t(t))
