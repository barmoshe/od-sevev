extends RefCounted
## res://data/ holds copies of the engine-agnostic specs (tools/sync_data.sh). The copies must
## match their sources, so the specs stay the single source of truth.

var runner: Object

const PAIRS := {
	"content.json": "design/content.json",
	"ui-strings.json": "ux/ui-strings.json",
}


## The Monkey Bananas audio specs moved to audio/legacy/ (Audio Director's legacy move): nothing
## copies them into the game any more, so no stale copy can ship or drift.
func test_legacy_audio_specs_are_not_copied() -> void:
	var root := ProjectSettings.globalize_path("res://").path_join("..")
	if not FileAccess.file_exists(root.path_join("design/content.json")):
		return
	for f: String in ["cues.json", "music.json"]:
		runner.check(not FileAccess.file_exists("res://data/" + f), "res://data/%s is gone (the MB audio spec is legacy)" % f)
		runner.check(FileAccess.file_exists(root.path_join("audio/legacy/" + f)), "audio/legacy/%s kept" % f)
		runner.check(not FileAccess.file_exists(root.path_join("audio/" + f)), "audio/%s moved to audio/legacy/" % f)
	runner.check(not PAIRS.values().any(func(p: String) -> bool: return p.begins_with("audio/")), "no audio pair to sync")


func test_data_copies_match_specs() -> void:
	var root := ProjectSettings.globalize_path("res://").path_join("..")
	if not FileAccess.file_exists(root.path_join("design/content.json")):
		return   # exported build: no sources to compare against
	for copy: String in PAIRS:
		var a := FileAccess.get_file_as_string("res://data/" + copy)
		var b := FileAccess.get_file_as_string(root.path_join(PAIRS[copy]))
		runner.check(a == b, "res://data/%s matches %s (run tools/sync_data.sh)" % [copy, PAIRS[copy]])
