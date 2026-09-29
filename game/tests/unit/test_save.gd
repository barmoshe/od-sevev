extends RefCounted
## Save v2: round trip, corrupt and newer saves are backed up, no v1 migration, HK1: export codes.

var runner: Object
var dir := ""


func setup(_r: Object) -> void:
	TestFixture.use_fork_content()
	dir = "user://test_save_%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(dir)


func teardown() -> void:
	TestFixture.use_game_content()
	var d := DirAccess.open(dir)
	if d:
		for f in d.get_files():
			d.remove(f)
	DirAccess.remove_absolute(dir)


func _store() -> SaveStore:
	return SaveStore.new(dir)


func test_round_trip() -> void:
	var st := _store()
	var s := GameState.fresh()
	s.bananas = 1234.5
	s.run_bananas = 2000.0
	s.all_time_bananas = 2_000_000.0
	s.owned["tree"] = 7
	s.upgrades.append("glove")
	s.thumbs_owned = 12
	s.buy_mode = "max"
	s.achievements.append("a_test")
	runner.check(st.save_game(s, 1000.0), "save writes")
	var r := st.load_game()
	runner.check(r["kind"] == "ok", "loads ok")
	var l: GameState = r["state"]
	runner.check(l.bananas == 1234.5 and l.owned_of("tree") == 7 and l.upgrades.has("glove"), "fields survive")
	runner.check(l.thumbs_owned == 12 and l.buy_mode == "max" and l.achievements.has("a_test"), "persistent fields survive")
	runner.check(float(r["lastSaveTime"]) == 1000.0, "last save time survives")


func test_corrupt_save_is_backed_up_not_lost() -> void:
	var st := _store()
	var f := FileAccess.open(st.path, FileAccess.WRITE)
	f.store_string("{not json")
	f.close()
	var r := st.load_game()
	runner.check(r["kind"] == "corrupt", "corrupt detected")
	runner.check(String(r.get("backup", "")) != "" and FileAccess.file_exists(r["backup"]), "backup file written")
	runner.check(FileAccess.get_file_as_string(r["backup"]) == "{not json", "backup keeps the original bytes")


func test_newer_save_is_backed_up() -> void:
	var st := _store()
	var f := FileAccess.open(st.path, FileAccess.WRITE)
	f.store_string(JSON.stringify({"version": 99, "state": {}}))
	f.close()
	var r := st.load_game()
	runner.check(r["kind"] == "newer" and FileAccess.file_exists(r["backup"]), "a newer save is kept aside, never overwritten")


func test_v1_save_is_not_migrated() -> void:
	# od-sevev: no v1 migration. A version-1 file (the fork's positional producer array) is kept
	# aside as corrupt, never loaded as this game's progress.
	var st := _store()
	var f := FileAccess.open(st.path, FileAccess.WRITE)
	f.store_string(JSON.stringify({"version": 1, "lastSaveTime": 42.0, "state": {"bananas": 5.0, "owned": [20, 13]}}))
	f.close()
	var r := st.load_game()
	runner.check(r["kind"] == "corrupt", "a v1 save does not load, got %s" % r["kind"])
	runner.check(String(r.get("backup", "")) != "" and FileAccess.file_exists(r["backup"]), "the v1 file is kept aside")


func test_thumbs_cannot_exceed_all_time() -> void:
	var s := GameState.from_dict({"allTimeBananas": 1_000_000.0, "thumbsOwned": 5000})
	runner.check(s.thumbs_owned == 10, "hand-edited Thumbs clamp to what all-time earned (%d)" % s.thumbs_owned)


func test_export_import_code() -> void:
	var s := GameState.fresh()
	s.bananas = 77.0
	s.owned["moon"] = 2
	var code := SaveStore.export_code(s)
	runner.check(code.begins_with("HK1:"), "export code prefix")
	var r := SaveStore.parse(code)
	runner.check(r["kind"] == "ok" and (r["state"] as GameState).owned_of("moon") == 2, "export code imports")
	runner.check(SaveStore.parse("HK1:@@@")["kind"] == "corrupt", "a garbled code is rejected")


func test_settings_keep_types() -> void:
	var st := _store()
	st.save_settings({"sfx": false, "music": true, "notation": 3})
	var got := st.load_settings({"sfx": true, "music": false, "notation": "letters"})
	runner.check(got["sfx"] == false and got["music"] == true, "bool settings load")
	runner.check(got["notation"] == "letters", "a wrong-typed value falls back to the default")
