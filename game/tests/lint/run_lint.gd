extends SceneTree
## tools/lint_text.sh entry point: loads the lint at runtime, after the autoloads exist.


func _initialize() -> void:
	var lint: Object = load("res://tests/lint/lint_text.gd").new()
	quit(int(lint.call("run")))
