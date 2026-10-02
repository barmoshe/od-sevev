extends SceneTree
## Dev only: loads the scripts named on the command line (or the seeded-rounds set) so their parse
## errors print with file and line. godot --headless --path game -s res://tests/dev/compile_check.gd


func _initialize() -> void:
	var paths := OS.get_cmdline_user_args()
	if paths.is_empty():
		paths = PackedStringArray(["res://scripts/sim/seeded_round.gd", "res://scripts/sim/challenge.gd", "res://scripts/sim/daily.gd",
			"res://scripts/sim/round_book.gd", "res://scripts/ui/round_chip.gd", "res://scripts/ui/round_share.gd",
			"res://scripts/ui/views/view_rounds.gd", "res://scripts/main.gd"])
	for p in paths:
		var s: Variant = load(p)
		print("%s %s" % ["ok  " if s != null and (s as GDScript).can_instantiate() else "FAIL", p])
	quit(0)
