class_name RoundBook
extends RefCounted
## The seeded rounds' own little file (user://rounds.json, next to the main save, never inside it):
## the device's challenge ref, the Daily Round's official results and the last challenge results.
## The main save (SaveStore, GameState) never learns about a challenge or a daily round, so neither
## can grant it money, base, perks or trophies. Validated at the boundary like the save.
##   {v: 1, ref: "a1b2c3d4", daily: {"2026-10-02": {n, leader, sec, cells, court, press}},
##    challenges: [{leader, seed, t, mine, result, at}]}

const VERSION := 1
const DAILY_KEEP := 120
const CHALLENGES_KEEP := 20
static var _KEY := RegEx.create_from_string("^\\d{4}-\\d{2}-\\d{2}$")
static var _CELLS := RegEx.create_from_string("^[BYRW]{0,20}$")

var path := ""
var data: Dictionary = {}


func _init(dir: String = "user://") -> void:
	path = dir.path_join("rounds.json")
	data = fresh()


static func fresh() -> Dictionary:
	return {"v": VERSION, "ref": "", "daily": {}, "challenges": []}


func load_book() -> RoundBook:
	data = fresh()
	if FileAccess.file_exists(path):
		var j := JSON.new()
		if j.parse(FileAccess.get_file_as_string(path)) == OK:
			data = sanitize(j.data)
	return self


func save_book() -> bool:
	return SaveStore._write_atomic(path, JSON.stringify(data))


static func sanitize(raw: Variant) -> Dictionary:
	var out := fresh()
	if not raw is Dictionary:
		return out
	var r: Dictionary = raw
	var ref := str(r.get("ref", ""))
	out["ref"] = ref if ref.length() == Challenge.REF_LEN and Challenge._ref_ok(ref) else ""
	var dl: Variant = r.get("daily")
	if dl is Dictionary:
		for k: Variant in dl:
			var v: Variant = (dl as Dictionary)[k]
			if k is String and _KEY.search(k) != null and v is Dictionary and _result_ok(v):
				out["daily"][k] = _clean_result(v)
	var la: Variant = r.get("last")
	if la is Dictionary:
		out["last"] = {"leader": str((la as Dictionary).get("leader", "")), "t": int(GameState._num((la as Dictionary).get("t"))),
			"seed": int(GameState._num((la as Dictionary).get("seed")))}
	for k in ["toastDay"]:
		if r.get(k) is String and _KEY.search(str(r[k])) != null:
			out[k] = r[k]
	var ch: Variant = r.get("challenges")
	if ch is Array:
		for c: Variant in ch:
			if c is Dictionary:
				out["challenges"].append((c as Dictionary).duplicate())
		while (out["challenges"] as Array).size() > CHALLENGES_KEEP:
			(out["challenges"] as Array).pop_front()
	return out


static func _result_ok(v: Dictionary) -> bool:
	var sec: Variant = v.get("sec")
	return (sec is float or sec is int) and float(sec) >= 0.0 and _CELLS.search(str(v.get("cells", ""))) != null


static func _clean_result(v: Dictionary) -> Dictionary:
	return {"n": int(v.get("n", 0)) if (v.get("n") is float or v.get("n") is int) else 0, "leader": str(v.get("leader", "")),
		"sec": int(v["sec"]), "cells": str(v.get("cells", "")),
		"court": "testified" if str(v.get("court", "")) == "testified" else "dodged", "press": v.get("press", false) == true}


## The device's ref, made (and saved) on first use.
func ref(rng: Callable = randf) -> String:
	if str(data.get("ref", "")) == "":
		data["ref"] = Challenge.new_ref(rng)
		save_book()
	return str(data["ref"])


func daily_result(key: String) -> Dictionary:
	return data["daily"].get(key, {})


func played(key: String) -> bool:
	return data["daily"].has(key)


## Stores the day's official result (the first one only). Returns false when the day already has one.
func record_daily(key: String, res: Dictionary) -> bool:
	if played(key):
		return false
	data["daily"][key] = _clean_result(res)
	var keys: Array = (data["daily"] as Dictionary).keys()
	keys.sort()
	while keys.size() > DAILY_KEEP:
		data["daily"].erase(keys.pop_front())
	save_book()
	return true


func streak(today: String) -> int:
	return DailyRound.streak(data["daily"], today)


func record_challenge(c: Dictionary) -> void:
	(data["challenges"] as Array).append(c.duplicate())
	while (data["challenges"] as Array).size() > CHALLENGES_KEEP:
		(data["challenges"] as Array).pop_front()
	save_book()


## The main game's last election, the round "אתגר חבר" sends: {leader, t, seed} or {}.
func last_round() -> Dictionary:
	var v: Variant = data.get("last")
	if not v is Dictionary or not Leaders.playable(str((v as Dictionary).get("leader", ""))) or int((v as Dictionary).get("t", 0)) <= 0:
		return {}
	return v


func note_round(leader: String, t: int, seed_: int) -> void:
	data["last"] = {"leader": leader, "t": clampi(t, 1, Challenge.T_MAX), "seed": posmod(seed_, Challenge.SEED_MAX)}
	save_book()


## The seeded round's save store: the controller swaps it in for SaveStore while a round runs, so
## every save call of the round (autosave, the vote, a reload's flush) lands in memory, never in the
## main save file. Settings keep the real file (a sound toggle in a round is the player's setting).
class Sandbox extends SaveStore:
	var last: Dictionary = {}
	var saves := 0

	func _init(main: SaveStore = null) -> void:
		super._init()
		if main != null:
			path = main.path.get_base_dir().path_join("round-sandbox.json")   # never read, never written
			settings_path = main.settings_path

	func load_game() -> Dictionary:
		return {"kind": "none"}

	func save_game(s: GameState, _now: float = SaveStore.now_ms()) -> bool:
		last = s.to_dict()
		saves += 1
		return true

	func wipe_game() -> void:
		last = {}
