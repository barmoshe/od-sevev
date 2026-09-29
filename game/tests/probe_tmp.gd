extends SceneTree
const PF := preload("res://tests/politics_fixture.gd")
func _initialize() -> void:
	var drift := PF.install_bench()
	print("drift: ", drift.size())
	for prof in ["engaged", "casual", "idle"]:
		var w0 := Time.get_ticks_msec()
		var r := PacingSim.session(PacingSim.PLAYERS[prof], 3600.0, 7, 0.25)
		var s: GameState = r["state"]
		print("%-8s runs %s | base %d | gap %s | court %d postp %d | left %d | wall %ds" % [prof, ", ".join((r["runs"] as Array).map(func(x: float) -> String: return PacingSim.fmt_t(x))), s.thumbs_owned, PacingSim.fmt_t(r["maxGap"]), s.investigation["courtDays"], s.investigation["postponementsLifetime"], s.coalition["leftLifetime"], (Time.get_ticks_msec() - w0) / 1000])
	quit(0)
