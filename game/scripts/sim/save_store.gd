class_name SaveStore
extends RefCounted
## Persistence (save v2). A JSON file in user:// (IndexedDB on the web build), versioned and
## validated at the boundary. Audit fixes over v1.1 (lab research.md §1):
## - an unreadable or newer save is moved to a .bak file and never silently overwritten;
## - writes are atomic (temp file, then rename);
## - saves export and import as a text code.
## od-sevev (game-developer, wave 1): the export prefix is "HK1:" and the fork's v1 migration is
## gone. A new game has no v1 saves, and the v1 step hardcoded the fork's producer ids by tier
## position. A version-1 file now parses as corrupt and is kept aside as a .bak.
## (The file schema continues the fork's: 2 is the fork's, 3 adds the politics sections.)
## od-sevev (game-developer sim): v3 adds coalition, investigation, events, album and calendar
## (GameState). A v2 file migrates by gaining their fresh defaults; each module's sanitize()
## validates them at load, so a hand-edited or partial section never breaks a save.
## Leader select (game-developer sim): v4 adds leader, leaderPickPending, leaderHistory, leaders,
## seatDeal and leaderRound (GameState, Leaders). A v3 file migrates as the default leader's (Bibi's)
## round with the picker closed: it opens at the next election (spec §6.3).

const VERSION := 4
const EXPORT_PREFIX := "HK1:"

var path: String
var settings_path: String


func _init(dir: String = "user://") -> void:
	path = dir.path_join("save.json")
	settings_path = dir.path_join("settings.json")


## {kind: "none" | "ok" | "corrupt" | "newer", state, lastSaveTime (ms), backup}
func load_game() -> Dictionary:
	var text := ""
	if FileAccess.file_exists(path):
		text = FileAccess.get_file_as_string(path)
	else:
		return {"kind": "none"}
	var res := parse(text)
	if res["kind"] == "corrupt" or res["kind"] == "newer":
		res["backup"] = _backup(text)
	return res


## Parses save text (a file or an export code) without side effects.
static func parse(text: String) -> Dictionary:
	text = text.strip_edges()
	if text.begins_with(EXPORT_PREFIX):
		var b64 := text.substr(EXPORT_PREFIX.length())
		if b64 == "" or not RegEx.create_from_string("^[A-Za-z0-9+/]+={0,2}$").search(b64):
			return {"kind": "corrupt"}
		text = Marshalls.base64_to_utf8(b64)
	var json := JSON.new()   # an instance parse reports errors quietly (no engine error spam)
	if json.parse(text) != OK or not json.data is Dictionary:
		return {"kind": "corrupt"}
	var file: Dictionary = json.data
	var v: Variant = file.get("version")
	if not (v is float or v is int):
		return {"kind": "corrupt"}
	if int(v) > VERSION:
		return {"kind": "newer", "version": int(v)}
	var migrated := migrate(file)
	if migrated.is_empty():
		return {"kind": "corrupt"}
	var state := GameState.from_dict(migrated.get("state"))
	if state == null:
		return {"kind": "corrupt"}
	var t: Variant = migrated.get("lastSaveTime")
	var last := float(t) if (t is float or t is int) and is_finite(float(t)) else now_ms()
	return {"kind": "ok", "state": state, "lastSaveTime": last}


## Migration chain: one step per version bump.
static func migrate(file: Dictionary) -> Dictionary:
	var f := file.duplicate(true)
	var v := int(f.get("version", 0))
	if v < 2:
		return {}   # no v1 migration in this game (see the header)
	if v == 2:
		# v2 -> v3: the politics sections start fresh (the fork had none).
		var st: Variant = f.get("state")
		if not st is Dictionary:
			return {}
		(st as Dictionary)["coalition"] = Coalition.fresh_state()
		(st as Dictionary)["investigation"] = Investigation.fresh_state()
		(st as Dictionary)["events"] = Events.fresh_state()
		(st as Dictionary)["album"] = Events.fresh_album()
		(st as Dictionary)["calendar"] = Calendar.fresh_state()
		f["version"] = 3
		v = 3
	if v == 3:
		# v3 -> v4: the save becomes Bibi's round (leader-select-spec §6.3).
		var st4: Variant = f.get("state")
		if not st4 is Dictionary:
			return {}
		Leaders.migrate_v3(st4)
		f["version"] = 4
		v = 4
	return f


func save_game(s: GameState, now: float = now_ms()) -> bool:
	return _write_atomic(path, JSON.stringify({"version": VERSION, "lastSaveTime": now, "state": s.to_dict()}))


func wipe_game() -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path) if path.begins_with("user://") else path)


static func export_code(s: GameState, now: float = now_ms()) -> String:
	var json := JSON.stringify({"version": VERSION, "lastSaveTime": now, "state": s.to_dict()})
	return EXPORT_PREFIX + Marshalls.utf8_to_base64(json)


func load_settings(defaults: Dictionary) -> Dictionary:
	var out := defaults.duplicate()
	if not FileAccess.file_exists(settings_path):
		return out
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(settings_path))
	if parsed is Dictionary:
		for k: String in defaults:
			var v: Variant = (parsed as Dictionary).get(k)
			if v != null and typeof(v) == typeof(defaults[k]):
				out[k] = v
	return out


func save_settings(settings: Dictionary) -> bool:
	return _write_atomic(settings_path, JSON.stringify(settings))


func _backup(text: String) -> String:
	var bak := path.get_basename() + ".bak-%d.json" % int(now_ms())
	var f := FileAccess.open(bak, FileAccess.WRITE)
	if f == null:
		return ""
	f.store_string(text)
	f.close()
	return bak


static func _write_atomic(p: String, text: String) -> bool:
	var tmp := p + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(text)
	f.close()
	var dir := DirAccess.open(p.get_base_dir())
	if dir == null:
		return false
	if FileAccess.file_exists(p):
		dir.remove(p.get_file())
	return dir.rename(tmp.get_file(), p.get_file()) == OK


static func now_ms() -> float:
	return Time.get_unix_time_from_system() * 1000.0
