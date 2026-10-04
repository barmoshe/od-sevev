extends SceneTree
## v2.1 (music v2.1, Bar: "test it in the game, mix and master it together with the SFX"): a scripted
## play session through the REAL Audio autoload (game/scripts/autoload/audio.gd) on the real bus layout
## (default_bus_layout.tres: the Music EQ and room, the master HPF, glue and limiter), so what comes
## out is the game's own mix of music, layers, ducks, stingers and SFX. Run it under Movie Maker,
## which mixes the audio offline at a fixed frame rate and writes it next to the frames:
##
##     tools/godot.sh --headless --path game --fixed-fps 30 --write-movie /tmp/s/mix.png \
##         -s $PWD/tools/mix_session.gd -- [--era=knesset] [--seconds=95] [--mute=music|sfx]
## (needs a renderer for the frames: on a server, run it under xvfb-run with --rendering-driver opengl3)
##
## then read /tmp/s/mix.wav (audio/tools/measure_session.py measures it). Never part of the build.

var _a: Node
var _t := 0.0
var _i := 0
var _end := 95.0
var _era := ""
var _tl: Array = []
var _tap_until := 0.0
var _tap_rate := 0.0
var _next_tap := 0.0
var _mute := ""


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--era="):
			_era = a.substr(6)
		elif a.begins_with("--seconds="):
			_end = float(a.substr(10))
		elif a.begins_with("--mute="):
			_mute = a.substr(7)   # music | sfx: measure the other alone, same session
	# [time s, event, arg] (a "taps" entry: [t, "taps", [rate per s, seconds]])
	_tl = [
		[0.3, "gesture", null], [0.5, "tap", null],                       # the motif, then the music at bar 1
		[3.0, "taps", [4.0, 7.0]],                                        # tapping: HaTikva on the bell, L2 steps back
		[6.0, "coin", 3], [8.5, "buy", null],                             # the first source: L1 comes in
		[11.0, "taps", [0.0, 0.0]],                                       # the taps rest: the lead returns
		[13.0, "chatPing", "partner"], [14.0, "headline", "ביבי: עוד סבב"],  # Dubi (Voice, ducks the music)
		[18.0, "taps", [6.0, 6.0]], [19.0, "goldenSpawn", null], [21.0, "goldenCatch", null],
		[21.2, "coin", 5], [24.0, "buyBulk", null], [25.0, "achievement", null],
		[27.0, "uiClick", null], [27.5, "panelOpen", null], [28.5, "panelClose", null],
		[30.0, "courtSummons", "court"], [34.0, "taps", [3.0, 6.0]], [42.0, "courtEnd", "testified"],
		[46.0, "ultimatumTick", 3], [47.0, "ultimatumTick", 2], [48.0, "ultimatumTick", 1], [48.6, "partnerPaid", null],
		[49.0, "ultimatumPaid", null], [50.0, "taps", [5.0, 8.0]], [52.0, "tapCrit", null],
		[60.0, "electionConfirm", 2],                                     # the fanfare, then the next era at bar 1
		[66.0, "taps", [4.0, 10.0]], [70.0, "chatPing", "partner"], [72.0, "buy", null], [74.0, "coin", 4],
		[80.0, "goldenSpawn", null], [82.0, "goldenCatch", null], [84.0, "taps", [0.0, 0.0]],
	]


func _process(delta: float) -> bool:
	if _a == null:
		_a = root.get_node_or_null("Audio")
		if _a == null:
			push_error("mix_session: no Audio autoload")
			return true
		if _era != "":
			_a.call("set_era", _era, true)
		if _mute == "music":
			_a.call("set_music_enabled", false)
		elif _mute == "sfx":
			_a.call("set_sfx_enabled", false)
	_t += delta
	while _i < _tl.size() and _t >= float(_tl[_i][0]):
		var ev: Array = _tl[_i]
		_i += 1
		match String(ev[1]):
			"gesture":
				_a.call("gesture")
			"taps":
				var r: Array = ev[2]
				_tap_rate = float(r[0])
				_tap_until = _t + float(r[1])
				_next_tap = _t
			_:
				_a.call("event", String(ev[1]), ev[2])
	if _tap_rate > 0.0 and _t < _tap_until and _t >= _next_tap:
		_a.call("event", "tap", null)
		_next_tap = _t + 1.0 / _tap_rate
	return _t >= _end
