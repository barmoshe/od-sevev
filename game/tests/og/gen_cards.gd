extends SceneTree
## tools/og.sh's entry: loads og_cards.gd at run time (like tests/run_tests.gd), so the autoloads
## (Art) exist before any game class compiles.

var _impl: RefCounted


func _initialize() -> void:
	_impl = load("res://tests/og/og_cards.gd").new()
	_impl.call("start", self)
