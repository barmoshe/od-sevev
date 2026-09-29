extends RefCounted
## res://data/ holds copies of the engine-agnostic specs (tools/sync_data.sh). The copies must
## match their sources, so the specs stay the single source of truth.

var runner: Object

const PAIRS := {
	"content.json": "design/content.json",
	"ui-strings.json": "ux/ui-strings.json",
	"cues.json": "audio/cues.json",
	"music.json": "audio/music.json",
}


func test_data_copies_match_specs() -> void:
	var root := ProjectSettings.globalize_path("res://").path_join("..")
	if not FileAccess.file_exists(root.path_join("design/content.json")):
		return   # exported build: no sources to compare against
	for copy: String in PAIRS:
		var a := FileAccess.get_file_as_string("res://data/" + copy)
		var b := FileAccess.get_file_as_string(root.path_join(PAIRS[copy]))
		runner.check(a == b, "res://data/%s matches %s (run tools/sync_data.sh)" % [copy, PAIRS[copy]])
