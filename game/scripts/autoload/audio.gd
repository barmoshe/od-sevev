extends Node
## Audio (autoload "Audio"): the עוד סבב sound runtime. It plays the files tools/gen_od_sevev.gd
## renders into res://assets/audio/od/ and follows audio/od/cue-spec.md. Every number (files,
## play_db, bars, loops, ducks, priorities, markers, babble contours) is read from
## od_manifest.json; the rules that are pure functions live in scripts/audio/od_audio.gd.
##
## The controller still speaks the fork's event vocabulary (tap, tapCrit, buy, goldenSpawn,
## evolveConfirm, storyCard, babble, ...); EVENT_CUE maps it onto the od cues. The od events the
## Animator asked the engine for (courtSummons, courtStart, courtEnd(reason), electionConfirm,
## trickCue, ceremonyEnd) and the new gameplay events (chatPing, ultimatumTick, stamp, ...) are
## accepted by name. Any manifest cue or stinger id is also accepted directly. Unknown names
## are ignored.
##
## Rules implemented here (cue-spec section in brackets):
## - Nothing plays before the first Magician tap. That tap plays the `motif` stinger instead of
##   `tap`, and the music starts at bar 1 exactly where the motif's ♭2 resolves (§2.6, A15).
## - The strict tap walk: pitch = streak mod the rendered steps (8), reset after 400 ms; d25/d12
##   alternate; ±1.5 dB (§4, A3). A crit plays `tap` at f0 and `rabbitCrit` on the crit strip's
##   rabbit frame (+250 ms, +83 in reduced motion), or at once on event("rabbit").
## - Unity buses under a limiter-only master; the slider's default position is 0 dB (§3).
## - Ducks from `cues.<id>.ducks` (and per bus for the stingers), deepest wins (§3).
## - Dubi never speaks over the motif, the anthem's statement (§2.6, O-A3): a line that arrives
##   while it sounds (tap 1's "אין כלום!") starts when its `musicalSeconds` has elapsed (2.33 s
##   in D), and a line after a motif still held for the web unlock waits for that motif too.
## - Layers L0/L1/L2 switch at the next bar line and ramp over one bar; the 4-loop mute cycle
##   (antiFatigue) on a loop counter that resets with the track (§2.1, §2.2).
## - Era switches and court day cross-fade (400 ms, equal power) onto the same bar of the new
##   track at the next bar line; courtIn / courtOut on that bar line (§2.3).
## - The election fanfare starts on the confirm frame, stops the bed in 30 ms, and the incoming
##   era starts at bar 1 after exactly `musicalSamples` (§2.4). Its markers are emitted as
##   `marker("fanfare", name)` and readable through fanfare_clock_ms() / fanfare_markers().
## - Chat pings: at most 1 per 700 ms (the rest coalesce into `burst`), never during Dubi
##   (queued until 300 ms after he stops) (§4).
## - Dubi: squawk, then 8 blips a second from the era bank, canned contours, a 1.6 s cap, at most
##   one ticker headline per 20 s; `dubi_blip` drives the beak (§4, A13).
## - The Outside drum line (Balfour) on its LPF sub-bus, and the Pink Front sweep behind the
##   content's easterEggs flag, with tap-to-beat judging (§2.5).
##
## v1.3 (Audio Director, 2026-09-29: leader select and the session-2 views, cue-spec §4.1):
## - First sounds: a cue flagged `firstSound` (leaderPick, returnAway) plays before the first-tap
##   gate, because it IS the first gesture (the picker's commit; the return card after a reload).
##   It does not open the gate: the first Magician tap still plays the motif. Under a locked web
##   context it is held like the motif (up to 5 s) and plays on the unlock (iOS: touchend).
## - Crits by leader: set_leader(id) (or the scene state's `leader`); a crit plays the leader's
##   react-event cue (crit_for(id), manifest `crits`) on that event's strip frame, or at once on
##   event(<the event>) / event("heroEvent", <the event>) / event("crit"). Bibi keeps rabbitCrit.
## - Press day: courtSummons / courtStart for a leader whose hazard skin is "press" (or with arg
##   "press") play the shutter instead of the gavel; the courthouse hush is shared.
## - gameReset: the music fades out over a bar and the first-tap gate closes again, so a wiped
##   game starts like a new one (the pick, then the motif on the first tap).
## - SILENT lists the events that are silent on purpose; route(name) says where any event goes.
##
## Safe before the web audio unlock (the first-tap motif waits for the unlock; any other cue is
## held if at most 180 ms old, rule U8) and under the dummy audio driver (headless tests): the
## bookkeeping runs on a game clock, not on the players.

signal marker(cue_id: String, name: String)
signal dubi_blip(bank: String)
signal pink_front_beat(on_beat: bool, offset_ms: float)

const POOL := 24
const VOICE_CAP := 20
const OFF_DB := -80.0
const WEB_POLL_S := 0.25
const HOLD_MAX_MS := 180.0          # U8: a cue made while the web context is locked
const MOTIF_HOLD_MAX_MS := 5000.0   # the first-tap motif waits this long for the unlock (iOS: touchend)
const BED_STOP_MS := 30.0           # the fanfare replaces the bed
const TOGGLE_RAMP_MS := 30.0
const PING_GAP_MS := 700.0
const PING_AFTER_DUBI_MS := 300.0
const HEADLINE_GAP_MS := 20000.0
const BABBLE_AFTER_FLASH_MS := 600.0   # a flash line waits for the dubiFlash head (5-1-5)
const BABBLE_LATE_MS := 90.0           # a blip later than this (a frame hitch) is skipped
const RABBIT_FALLBACK_MS := 250.0
const BEAT_TOLERANCE_MS := 120.0       # tap-to-beat: a hit within this of a judge beat
const COIN_MAX := 6
const COIN_GAP_MS := 60.0
const LAYERS := ["L0", "L1", "L2"]
const SFX_BUSES := ["SFX-Critical", "SFX-Frequent", "UI", "Voice"]
## [bus, send] in layout order (default_bus_layout.tres; recreated here if a layout lacks one).
const BUS_TREE := [["Music", "Master"], ["Outside", "Music"], ["SFX-Critical", "Master"],
	["Suitcase", "SFX-Critical"], ["SFX-Frequent", "Master"], ["UI", "Master"], ["Voice", "Master"]]
const DUBI_CUES := ["dubiSquawk", "dubiBlip", "dubiFlash"]

## The controller's (fork) event names -> the od cue they play.
const EVENT_CUE := {
	"buy": "buy", "buyBulk": "buy", "upgradeBuy": "buy", "perkBuy": "buy",
	"cantAfford": "cantAfford",
	"uiClick": "uiClick", "uiToggle": "uiClick", "buyModeCycle": "uiClick", "panelOpen": "uiClick",
	"panelClose": "uiClick", "evolveOpen": "uiClick", "evolveClose": "uiClick",
	"goldenCatch": "suitcaseCatch", "goldenDespawn": "suitcaseMiss",
	"offlineCollect": "returnAway",
	"partnerPaid": "stamp", "pardonStamp": "stamp",
	"photobomb": "shutter", "transfer": "transferWhistle", "postponement": "gavelWeak",
}
## Event names -> a stinger.
## General trophies (`achievement`) take the brass 1-2-♭3 `milestone` (Audio Director v1.2: too short
## to read as the anthem, so safe on satirical trophies); only the album trophy plays `trophy`.
const EVENT_STINGER := {"milestone": "milestone", "evolveReady": "milestone", "electionReady": "milestone",
	"achievement": "milestone", "storyCard": "dubiFlash", "trophy": "trophy"}
## Event names with their own handler in event() (state only, or a rule beyond "play the cue").
const HANDLED := ["tap", "tapCrit", "rabbit", "heroEvent", "crit", "buy", "buyBulk", "evolveConfirm",
	"electionConfirm", "era", "courtSummons", "courtStart", "courtEnd", "chatPing", "chatLeft", "chatBrawl",
	"ultimatumTick", "ultimatumZero", "ultimatumEnd", "ultimatumPaid", "stamp", "coin", "coalitionCollapse",
	"pinkFront", "drumBeat", "babble", "squawk", "headline", "dubiHeadline", "dubiSquawk", "goldenSpawn",
	"leaderPick", "gameReset"]
## v1.3 coverage audit (cue-spec §4.1): events the game sends that are silent on purpose. Each one's
## meaning is carried by a sound that already plays, or by its visual twin (the reason is in §4.1).
const SILENT := ["frenzyStart", "frenzyEnd", "tapFrenzyStart", "tapFrenzyEnd", "milestoneHeadline",
	"becameAffordable", "producerReveal", "trickCue", "ceremonyEnd", "evolveTransitionEnd", "spinEnd",
	"cottagePixel", "leaderSwap", "leaderUndo"]
## Cues whose variant is random (never the same one twice in a row).
const RANDOM_VARIANT := ["suitcaseSpawn", "gavel", "transferWhistle", "shutter"]
## Cues whose variant alternates.
const ALTERNATE := {"buy": ["d25", "d12"], "ultimatumTick": ["tick", "tock"], "coin": ["a", "b"]}

var _ok := false
var _man: Dictionary = {}
var _streams: Dictionary = {}
var _requested: Array[String] = []   # background loads not collected yet
var _warned: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var _dummy := false

# ---- clock, voices, schedule
var _clock := 0.0                     # ms; stops while paused
var _players: Array[AudioStreamPlayer] = []
var _voices: Array = []               # {p, cue, start, end, prio}
var _sched: Array = []                # {at, fn}
var _alt: Dictionary = {}             # cue -> the next index into ALTERNATE[cue]
var _last_var: Dictionary = {}        # cue -> the last random variant
var _ducks: Dictionary = {}           # "music" | "voice" -> Array of {db, start, end, attack, release}
var _duck_db: Dictionary = {"music": 0.0, "voice": 0.0}
var _log: Array[String] = []          # the last played files (web: window.odCueLog)
var _log_t: Array[float] = []         # when each was played, audio clock ms (web: window.odCueLogMs)

# ---- the player's state as the audio sees it
var _first_tap := false
var _evolutions := 0
var _evo_known := false
var _era := ""                        # the era the music plays (or will play on its next start)
var _sources := 0
var _reduced_motion := false
var _last_tap := -1e12
var _tap_prev := -1e12
var _tap_streak := -1
var _tap_n := 0
var _tap_steps := 8                   # read from the manifest (the rendered tap pitches)
var _tap_melody: Array = []           # v1.5: HaTikva, one pitch key per tap (manifest tap.melody)
var _tap_phrases: Array = [0]
var _tap_phrase := -1                 # the phrase the current streak opened on (-1: none yet this round)
var _tap_note := -1
var _rabbit_due := -1.0               # a crit's cue is due then (the rabbit, or the leader's react event)
var _rabbit_n := 0
var _leader := ""                     # set_leader(); "" reads the scene state's leader (default bibi)
var _crit_cache: Dictionary = {}      # leader id -> crit_for() result
var _sprites: Dictionary = {}         # sprites.json, read once (the react event frames)
var _held_first: Dictionary = {}      # a first sound made while the web context is locked
var _stamp_n := 0
var _court := false
var _court_stinger := ""              # "in" | "out": plays on the next bar line
var _ult_force := false
var _era_progress := 0.0
var _pink_on := false
var _pink_k := 0.0
var _pink_applied := -1.0

# ---- settings
var _sfx_on := true
var _music_on := true
var _vol := {"sfx": 1.0, "music": 1.0}
var _toggle := {"sfx": 1.0, "music": 1.0}
var _paused := false

# ---- music
var _mp: Array[AudioStreamPlayer] = []   # the two decks' music players
var _op: Array[AudioStreamPlayer] = []   # the two decks' Outside players
var _deck_track: Array[String] = ["", ""]
var _d := 0                           # the active deck
var _sync: Dictionary = {}            # era -> AudioStreamSynchronized
var _music_live := false
var _track := ""                      # the track the active deck plays
var _song_clock := 0.0                # s; the song position under the dummy driver
var _pos_prev := 0.0
var _bar_i := -1
var _loop := 1
var _lg := {"L0": 1.0, "L1": 0.0, "L2": 0.0}
var _lt := {"L0": 1.0, "L1": 0.0, "L2": 0.0}
var _lramp: Dictionary = {}           # layer -> {from, to, t0, ms}
var _xf: Dictionary = {}              # {t0, ms} while two decks cross-fade
var _bed := 1.0                       # the bed gain (stops, collapses, starts)
var _bed_ramp: Dictionary = {}        # {from, to, t0, ms, stop}
var _restart_at := -1.0               # ms: the music starts at bar 1 then (after the motif / fanfare)
var _restart_era := ""
var _restart_on_tap := false          # after a coalition collapse: the next tap restarts the music
var _fanfare: Dictionary = {}         # {t0, key, tags, markers, fired, end}
var _deck_started_at := -1e12
var _deck_started_pos := 0.0

# ---- Dubi and the chat
var _babble: Dictionary = {}          # {t0, blips, i, squawk, squawked, end}
var _flash_at := -1e12
var _headline_at := -1e12
var _dubi_quiet_at := -1e12           # when Dubi last stopped (ms)
var _ping_last := -1e12
var _ping_q := {"n": 0, "variant": "", "left": false}

# ---- web
var _web := false
var _web_running := true
var _web_poll := 0.0
var _held: Dictionary = {}
var _held_motif := -1.0
var _motif_end := -1e12               # ms: the last motif's musicalSeconds end (Dubi waits, O-A3)
var _unlocked := false
var _pub_t := 0.0


func _ready() -> void:
	_ensure()
	process_mode = Node.PROCESS_MODE_ALWAYS


## Collects the background loads nobody asked for yet, so the loader lets go of them.
func _exit_tree() -> void:
	for path in _requested:
		ResourceLoader.load_threaded_get(path)
	_requested.clear()


## Loads the manifest and makes the buses and players (once; lazily, because other nodes may
## call in before this one is ready).
func _ensure() -> void:
	if _ok:
		return
	_ok = true
	_rng.seed = 0x0D5E   # variety only (jitter, random variants); the files are deterministic
	_man = OdAudio.manifest()
	if _man.is_empty():
		_warn_once("od_manifest.json missing (run tools/audio.sh)")
	_dummy = AudioServer.get_driver_name() == "Dummy"
	_web = OS.has_feature("web")
	_web_running = not _web
	_era = era_for(0)
	_ensure_buses()
	for i in POOL:
		var p := AudioStreamPlayer.new()
		p.name = "Voice%d" % i
		add_child(p)
		_players.append(p)
	for i in 2:
		var m := AudioStreamPlayer.new()
		m.name = "Music%d" % i
		m.bus = "Music"
		add_child(m)
		_mp.append(m)
		var o := AudioStreamPlayer.new()
		o.name = "Outside%d" % i
		o.bus = "Outside"
		add_child(o)
		_op.append(o)
	_tap_steps = OdAudio.tap_steps(_man)
	_tap_melody = OdAudio.tap_melody(_man)
	_tap_phrases = OdAudio.tap_phrases(_man)
	_warm()
	_apply_buses()


func _ensure_buses() -> void:
	for pair: Array in BUS_TREE:
		if AudioServer.get_bus_index(pair[0]) == -1:
			AudioServer.add_bus()
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, pair[0])
	for pair: Array in BUS_TREE:
		AudioServer.set_bus_send(AudioServer.get_bus_index(pair[0]), pair[1])


## Loads what the first minute needs before anyone taps: the motif, every tap, and the boot
## era's stems (the other eras load in the background when they come near).
func _warm() -> void:
	if _man.is_empty():
		return
	for key: String in ["D", "E", "F", "G"]:
		var e := OdAudio.stinger_entry(_man, "motif", key)
		if not e.is_empty():
			_stream(String(e["file"]))
	for key: String in ["D", "E", "F", "G"]:   # v1.3: the first sounds (the pick, the return card)
		for id: String in ["leaderPick", "returnAway"]:
			for v in OdAudio.cue_variants(_man, id, key):
				var f := OdAudio.cue_file(_man, id, key, "_", v)
				if f != "":
					_stream(f)
	for key: String in ["D", "E", "F", "G"]:
		for pitch in OdAudio.cue_pitches(_man, "tap"):
			for v in OdAudio.cue_variants(_man, "tap", key, pitch):
				var f := OdAudio.cue_file(_man, "tap", key, pitch, v)
				if f != "":
					_stream(f)
	_sync_for(_track_of(_era))
	_prefetch("courthouse")


func _now() -> float:
	return _clock


func _warn_once(msg: String) -> void:
	if not _warned.has(msg):
		_warned[msg] = true
		push_warning("[Audio] " + msg)


# ================================================================== public API

## A gameplay or UI event (see the header). `arg` carries the variant or the payload: the partner
## id for chatPing, the seconds left for ultimatumTick, the reason for courtEnd, the text for
## babble / headline, the coin count for coin, the Suitcase's x (0..1 of the screen) for
## goldenSpawn, the election number for electionConfirm (optional), true/false for pinkFront.
func event(name: String, arg: Variant = null) -> void:
	_ensure()
	var now := _now()
	match name:
		"tap":
			_on_tap(now, false)
		"tapCrit":
			_on_tap(now, true)
		"rabbit", "crit":
			_rabbit_now(now)
		"heroEvent":
			if arg != null and str(arg) == String(crit_for(leader_id())["event"]):
				_rabbit_now(now)
		"leaderPick":
			if arg != null and str(arg) != "":
				set_leader(str(arg))
			_cue("leaderPick", now)
		"gameReset":
			_game_reset(now)
		"chatBrawl":
			_ping(now, "brawl")
		"buy", "buyBulk":
			set_sources_owned(maxi(_sources, 1))
			_cue_alt("buy", now)
		"evolveConfirm", "electionConfirm":
			_election(now, arg)
		"era":
			if arg != null:
				set_era(str(arg))
		"courtSummons":
			_court_in(now, true, arg)
		"courtStart":
			_court_in(now, false, arg)
		"courtEnd":
			_court_out(now, "" if arg == null else str(arg))
		"chatPing":
			_ping(now, OdAudio.ping_variant(_man, "" if arg == null else str(arg)))
		"chatLeft":
			_ping(now, "left")
		"ultimatumTick":
			_ultimatum_tick(now, arg)
		"ultimatumZero":
			_ult_force = false
			_cue("ultimatumZero", now)
		"ultimatumEnd", "ultimatumPaid":
			_ult_force = false
		"stamp":
			_stamp_n += 1
			_cue("stamp", now, OdAudio.stamp_variant(_stamp_n))
		"coin":
			_coins(now, arg)
		"coalitionCollapse":
			_collapse(now)
		"pinkFront":
			_pink_set(arg == null or bool(arg))
		"drumBeat":
			judge_tap()
		"babble":
			_dubi_speak(now, "" if arg == null else str(arg), "flash")
		"squawk":
			_dubi_speak(now, squawk_text(leader_id(), "firsttap" if arg == null else str(arg)), "flash")
		"headline", "dubiHeadline":
			_dubi_speak(now, "" if arg == null else str(arg), "headline")
		"dubiSquawk":
			_cue("dubiSquawk", now, "down" if str(arg) == "down" else "up")
		"goldenSpawn":
			_suitcase_spawn(now, arg)
		_:
			if _crit_events().has(name):
				if name == String(crit_for(leader_id())["event"]):
					_rabbit_now(now)   # the leader's react event, reported by the engine on its frame
			elif EVENT_CUE.has(name):
				_cue_alt(EVENT_CUE[name], now)
			elif EVENT_STINGER.has(name):
				if name == "storyCard":
					_flash_at = now
				_stinger(EVENT_STINGER[name], now)
			elif _man.get("cues", {}).has(name):
				_cue_alt(name, now, "_" if arg == null else str(arg))
			elif _man.get("stingers", {}).has(name) and name != "fanfare":
				_stinger(name, now)
			# anything else (frenzy*, trickCue, ceremonyEnd, ...) is silent by design


func set_sfx_enabled(on: bool) -> void:
	_ensure()
	_sfx_on = on


func set_music_enabled(on: bool) -> void:
	_ensure()
	if on == _music_on:
		return
	_music_on = on
	if on:
		start_music()
	else:
		_sched_at(_now() + 2.0 * TOGGLE_RAMP_MS, func() -> void:
			if not _music_on:
				_stop_music())


## A settings slider, 0..1, for "sfx" (every SFX bus) or "music". The default position is 0 dB.
func set_volume(bus: String, linear: float) -> void:
	_ensure()
	var b := bus.to_lower()
	if not _vol.has(b):
		_warn_once("unknown volume bus '%s'" % bus)
		return
	_vol[b] = clampf(linear, 0.0, 1.0)
	_apply_buses()


## The number of elections: selects the era (content.json eras fromEvolutions). While the music
## plays, a new era cross-fades at the next bar line; silent, it applies at once. A new round
## has no money sources yet (L1 off until the first one is bought).
func set_evolutions(n: int) -> void:
	_ensure()
	n = maxi(0, n)
	if _evo_known and n != _evolutions:
		_sources = 0
	_evo_known = true
	_evolutions = n
	set_era(era_for(n))


## Switches the music to an era (a content eras.list[].id). Playing: at the next bar line (or at
## once with at_once) onto the same bar of the era's track; silent: the next start plays it.
func set_era(era_id: String, at_once := false) -> void:
	_ensure()
	var id := era_id.to_lower()
	if id == "" or not (_man.get("eras", {}).has(id) or _content_eras().has(id)):
		_warn_once("unknown era '%s'" % era_id)
		return
	_era = id
	_prefetch(_track_of(id))
	if at_once and _music_live and _track_want() != _track:
		_switch_track(_now(), maxi(1, _bar_i + 1))


## How many money sources the round owns (L1 plays from the first one on). The engine calls it
## at boot and on each buy; a `buy` event also implies it.
func set_sources_owned(n: int) -> void:
	_ensure()
	_sources = maxi(0, n)


## The era's progress 0..1 (the Outside drum line rises by up to +6 dB across it).
func set_era_progress(p: float) -> void:
	_ensure()
	_era_progress = clampf(p, 0.0, 1.0)


## Reduced motion: the crit's rabbit (and its cue) comes one frame after the tap.
func set_reduced_motion(on: bool) -> void:
	_ensure()
	_reduced_motion = on


## v1.3: the round's leader (a content leaders[].id). event("leaderPick", id) sets it too; the
## engine may call this on install or load. "" follows the scene state's `leader` (the content's
## default leader when there is none). Warms the leader's crit files.
func set_leader(id: String) -> void:
	_ensure()
	_leader = id
	var c := crit_for(leader_id())
	for k: String in ["D", "E", "F", "G"]:
		for v in OdAudio.cue_variants(_man, String(c["cue"]), k):
			if String(c["variant"]) == "roundRobin" or v == String(c["variant"]):
				var f := OdAudio.cue_file(_man, String(c["cue"]), k, "_", v)
				if f != "":
					_stream(f)


## The leader the audio plays for now.
func leader_id() -> String:
	if _leader != "":
		return _leader
	var tree := get_tree()
	if tree != null and tree.current_scene != null:
		var st: Variant = tree.current_scene.get("state")
		if st is Object:
			var l: Variant = (st as Object).get("leader")
			if l is String and l != "" and Leaders.playable(l):
				return l
	var d := Leaders.default_leader()
	return d if d != "" else "bibi"


## v1.3 (leader-select spec §9.5): a leader's crit cue, keyed by the react event of its crit strip:
## {leader, event, cue, variant, art, anim, delayMs}. `variant` "roundRobin" = rabbitCrit's slide
## lengths in turn. delayMs is tap -> the event's strip frame (reduced motion plays at a third).
## Works for any id: an unknown leader gets the default kit (Bibi's rabbit).
func crit_for(id: String) -> Dictionary:
	_ensure()
	var L := Leaders.leader(id)
	var tap: Dictionary = {}
	var kit := Leaders.kit(id)
	if kit.get("tap") is Dictionary:
		tap = kit["tap"]
	var ev := OdAudio.crit_event(tap)
	var out := OdAudio.crit_cue(_man, ev)
	var art := String(L.get("art", "bibi")) if not L.is_empty() else "bibi"
	var anim := String(tap.get("critAnim", "crit"))
	out.merge({"leader": id, "event": ev, "art": art, "anim": anim,
		"delayMs": OdAudio.event_ms(_sprites_json(), art, anim, ev, RABBIT_FALLBACK_MS)})
	return out


## v1.3 (spec §10): Dubi's squawk for a leader, kind firsttap | buy | elect | miss (| drop):
## kit.dubi.squawks[kind], or content.dubi.squawks["dubi.<kind>"] for a kit that points at the
## shared Dubi (Bibi). "" when there is none. Every one of them has a canned contour.
func squawk_text(id: String, kind: String) -> String:
	var d: Variant = Leaders.kit(id).get("dubi")
	if d is Dictionary and (d as Dictionary).get("squawks") is Dictionary and (d as Dictionary)["squawks"].has(kind):
		return String((d as Dictionary)["squawks"].get(kind, ""))
	var shared: Variant = Content.data().get("dubi", {})
	if shared is Dictionary and (shared as Dictionary).get("squawks") is Dictionary:
		return String((shared as Dictionary)["squawks"].get("dubi." + kind, ""))
	return ""


## v1.3 coverage: where an event goes: "handler", "cue:<id>", "stinger:<id>", "silent" (SILENT) or
## "unknown" (a gap: the event plays nothing and nobody decided that).
func route(name: String) -> String:
	_ensure()
	if HANDLED.has(name) or _crit_events().has(name):
		return "handler"
	if EVENT_CUE.has(name):
		return "cue:" + String(EVENT_CUE[name])
	if EVENT_STINGER.has(name):
		return "stinger:" + String(EVENT_STINGER[name])
	if _man.get("cues", {}).has(name):
		return "cue:" + name
	if _man.get("stingers", {}).has(name) and name != "fanfare":
		return "stinger:" + name
	if SILENT.has(name):
		return "silent"
	return "unknown"


func _crit_events() -> Array:
	return (_man.get("crits", {}) as Dictionary).keys().filter(func(k: String) -> bool: return not k.begins_with("_"))


func _sprites_json() -> Dictionary:
	if _sprites.is_empty():
		var path := "res://assets/sprites/sprites.json"
		if FileAccess.file_exists(path):
			var v: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
			_sprites = v if v is Dictionary else {"_": true}
		else:
			_sprites = {"_": true}
	return _sprites


## The hazard skin of the leader's round: "court" (Bibi) or "press" (everyone else, spec §5.6).
func _hazard_skin() -> String:
	var h: Variant = Leaders.kit(leader_id()).get("hazard")
	if h is Dictionary:
		return String((h as Dictionary).get("skin", "court"))
	return "court"


## Starts the music at bar 1 once the first tap's motif has resolved (never before the first
## tap). The controller calls it when the game shows; it is a no-op until the motif has played.
func start_music() -> void:
	_ensure()
	if not _music_on or _music_live or not _first_tap or _restart_at >= 0.0 or _restart_on_tap:
		return
	_begin_music(0.0)


## The fork's buff-driven music states; the od layers follow taps, sources and court day.
func set_music_state(_state: String) -> void:
	_ensure()


## The app went to the background (true) or came back (false): every player pauses and the
## audio clock stops, so scheduled cues, Dubi and the fanfare wait with the game.
func set_paused(p: bool) -> void:
	_ensure()
	_paused = p
	for m: AudioStreamPlayer in _mp + _op:
		m.stream_paused = p
	for v in _voices:
		(v["p"] as AudioStreamPlayer).stream_paused = p


## Stops Dubi mid-line (the blip sounding now is cut too).
func stop_babble() -> void:
	_ensure()
	for v in _voices.duplicate():
		if v["cue"] == "dubiBlip" or v["cue"] == "dubiSquawk":
			_steal(v)
	if not _babble.is_empty():
		_babble = {}
		_dubi_quiet_at = _now()


func is_babbling() -> bool:
	return not _babble.is_empty()


## Pink Front tap-to-beat: the signed offset (ms) of now from the nearest Outside downbeat as the
## player hears it (the output latency taken off), and `pink_front_beat` with the verdict. INF
## when the drum line is not playing.
func judge_tap() -> float:
	_ensure()
	if not _music_live or _track != "balfour":
		return INF
	var bal: Dictionary = _man.get("eras", {}).get("balfour", {})
	var out: Dictionary = bal.get("outside", {})
	if out.is_empty():
		return INF
	var rate := float(bal.get("rate", 31900))
	var heard := _pos_prev - AudioServer.get_output_latency()
	var loop_n := float(out.get("loopSamples", 132000))
	var off := OdAudio.beat_offset_ms(fposmod(heard * rate, loop_n), out.get("judgeSamples", []), loop_n, rate)
	pink_front_beat.emit(absf(off) <= BEAT_TOLERANCE_MS, off)
	return off


## One line for the settings screen.
func report() -> String:
	_ensure()
	var parts: Array[String] = []
	parts.append("sfx %s %d%%" % ["on" if _sfx_on else "off", roundi(float(_vol["sfx"]) * 100.0)])
	parts.append("music %s %d%%" % ["on" if _music_on else "off", roundi(float(_vol["music"]) * 100.0)])
	parts.append("key " + key())
	parts.append("era " + _era)
	parts.append(track_name())
	parts.append("voices %d/%d" % [_active(-1.0).size(), VOICE_CAP])
	if _web:
		parts.append("web " + ("running" if _web_running else "locked"))
	if _man.is_empty():
		parts.append("files missing, run tools/audio.sh")
	return " | ".join(parts)


# ================================================================== inspection (tests, debug)

## The key keyed cues use now: the playing track's, or the era's (G on court day) when silent.
func key() -> String:
	if _music_live and _track != "":
		return OdAudio.era_key(_man, _track)
	return "G" if _court else OdAudio.era_key(_man, _track_of(_era))


func era() -> String:
	return _era


## The era for an election count: the last content era whose fromEvolutions <= n (the
## manifest's first era when the content has none).
func era_for(evolutions: int) -> String:
	var list: Array = Content.data().get("eras", {}).get("list", [])
	var out := ""
	for e: Variant in list:
		if not (e is Dictionary):
			continue
		if out == "":
			out = String((e as Dictionary).get("id", ""))
		if evolutions >= int((e as Dictionary).get("fromEvolutions", 0)):
			out = String((e as Dictionary).get("id", out))
	if out == "":
		out = "balfour"
	return out


func active_voices(cue_id := "") -> int:
	_ensure()
	var n := 0
	for v in _active(_now()):
		if cue_id == "" or v["cue"] == cue_id:
			n += 1
	return n


func is_music_playing() -> bool:
	return _music_live


func first_tap_done() -> bool:
	return _first_tap


func court_active() -> bool:
	return _court


func layer_gain(layer: String) -> float:
	return float(_lg.get(layer, 0.0))


func layer_target(layer: String) -> float:
	return float(_lt.get(layer, 0.0))


func loop_index() -> int:
	return _loop


## The bar (1-based) the music is in, 0 when silent.
func bar() -> int:
	return _bar_i + 1 if _music_live else 0


## "<track>:L0+L1..." while the music plays, "stopped" otherwise.
func track_name() -> String:
	if not _music_live:
		return "stopped"
	var s := _track + ":"
	var on: Array[String] = []
	for l: String in LAYERS:
		if float(_lt[l]) > 0.01:   # v1.6: the lead under the bell sits at 0.5, and is on
			on.append(l)
	return s + "+".join(on)


func duck_db(target: String) -> float:
	return float(_duck_db.get(target, 0.0))


## Milliseconds since the election fanfare started (-1 when none plays).
func fanfare_clock_ms() -> float:
	return _now() - float(_fanfare["t0"]) if not _fanfare.is_empty() else -1.0


## The playing fanfare's markers in seconds {pickup, rollEnd, tagOnsets[], fanfareEnd} ({} when none).
func fanfare_markers() -> Dictionary:
	return _fanfare.get("markers", {})


func queued_pings() -> int:
	return int(_ping_q["n"])


## The files played most recently, oldest first (the web build publishes them as window.odCueLog).
func recent_files() -> Array[String]:
	return _log.duplicate()


## Milliseconds until the music starts at bar 1 (after the motif or the fanfare), -1 when none waits.
func music_starts_in_ms() -> float:
	return _restart_at - _now() if _restart_at >= 0.0 else -1.0


## Test hook, dummy driver only: moves the song clock to `song_s` seconds into the playing track.
func debug_seek(song_s: float) -> void:
	if _dummy and _music_live:
		_song_clock = song_s


## Test hook: the pending bar-1 start (after the motif or the fanfare) happens on the next frame,
## and the motif's hold on Dubi (O-A3) ends now.
func debug_skip_wait() -> void:
	if _restart_at >= 0.0:
		_restart_at = _now()
	_motif_end = minf(_motif_end, _now())


## Milliseconds until Dubi may speak over the motif's end (O-A3); 0 when he may speak now, INF
## while the first-tap motif is held for the web unlock.
func dubi_waits_ms() -> float:
	return maxf(0.0, _dubi_clear_at() - _now())


## When Dubi may start a line: after the last motif's musicalSeconds, never under a held motif.
func _dubi_clear_at() -> float:
	return INF if _held_motif >= 0.0 else _motif_end


# ================================================================== the tap and the first sound

func _on_tap(now: float, crit: bool) -> void:
	_last_tap = now
	if not _first_tap:
		_first_tap = true
		_probe_sources()
		if _web and not _web_running:
			_held_motif = now   # iOS unlocks on touchend: the motif lands on release
		else:
			_play_intro(now)
		if crit:
			_rabbit_due = now + _rabbit_ms()
		return
	if _restart_on_tap:
		_restart_on_tap = false
		if _music_on and not _music_live:
			_begin_music(0.0)
	_tap_streak = OdAudio.tap_streak(_tap_streak, _tap_prev, now)
	_tap_prev = now
	var v := OdAudio.tap_variant(_tap_n)
	_tap_n += 1
	var pitch := OdAudio.tap_pitch(_tap_streak, _tap_steps)
	if not _tap_melody.is_empty():
		var st := OdAudio.melody_step(_tap_streak, _tap_phrase, _tap_note, _tap_melody.size(), _tap_phrases)
		_tap_phrase = st.x
		_tap_note = st.y
		pitch = String(_tap_melody[_tap_note])
	_cue("tap", now, v, pitch, _rng.randf_range(-OdAudio.TAP_JITTER_DB, OdAudio.TAP_JITTER_DB))
	if crit:
		_rabbit_due = now + _rabbit_ms()
	if _pink_on:
		judge_tap()


## The motif, then the music at bar 1 exactly where its ♭2 resolves.
func _play_intro(now: float) -> void:
	var e := OdAudio.stinger_entry(_man, "motif", key())
	_stinger("motif", now)
	if not e.is_empty():
		_restart_at = now + float(e["musicalSamples"]) / float(e["rate"]) * 1000.0
		_restart_era = ""


## Tap -> the crit's cue: the leader's react-event frame after entry at f1 (Bibi: the crit strip's
## rabbit frame, 250 ms). Reduced motion takes a third of it (the 83 ms of cue-spec §5).
func _rabbit_ms() -> float:
	var ms := float(crit_for(leader_id())["delayMs"])
	return ms / 3.0 if _reduced_motion else ms


## The due crit's cue now (the leader's mapping; rabbitCrit's slide lengths round-robin).
func _rabbit_now(now: float) -> void:
	if _rabbit_due < 0.0:
		return
	_rabbit_due = -1.0
	var c := crit_for(leader_id())
	var id := String(c["cue"])
	var v := String(c["variant"])
	if v == "roundRobin":
		var vs := OdAudio.cue_variants(_man, id, key())
		v = vs[_rabbit_n % vs.size()] if not vs.is_empty() else "_"
		_rabbit_n += 1
	_cue(id, now, v)


## The money sources the round already owns, read once from the controller's state (a returning
## player's L1 plays before their next buy). Read-only and duck-typed: absent -> 0.
func _probe_sources() -> void:
	var tree := get_tree()
	if tree == null or tree.current_scene == null:
		return
	var st: Variant = tree.current_scene.get("state")
	if st == null or not (st is Object):
		return
	var owned: Variant = (st as Object).get("owned")
	if owned is Dictionary:
		var n := 0
		for k: Variant in owned:
			n += int(owned[k])
		_sources = maxi(_sources, n)


# ================================================================== cues and stingers

## The first-tap gate: nothing plays before the first Magician tap.
func _gate_open() -> bool:
	return _first_tap


func _locked() -> bool:
	return _web and not _web_running


## A cue whose variant alternates or is random (else `variant`).
func _cue_alt(id: String, now: float, variant := "_") -> bool:
	if ALTERNATE.has(id):
		var list: Array = ALTERNATE[id]
		var i := int(_alt.get(id, 0))
		_alt[id] = i + 1
		variant = String(list[i % list.size()])
	elif RANDOM_VARIANT.has(id):
		variant = _random_variant(id)
	return _cue(id, now, variant)


func _random_variant(id: String) -> String:
	var vs := OdAudio.cue_variants(_man, id, key())
	if vs.is_empty():
		return "_"
	var i := _rng.randi_range(0, vs.size() - 1)
	if vs.size() > 1 and vs[i] == String(_last_var.get(id, "")):
		i = (i + 1 + _rng.randi_range(0, vs.size() - 2)) % vs.size()
	_last_var[id] = vs[i]
	return vs[i]


## Plays a manifest cue now in the current key. Returns false when it is dropped (the first-tap
## gate, the web lock, polyphony, the voice cap, or a missing file).
func _cue(id: String, now: float, variant := "_", pitch := "_", extra_db := 0.0, bus := "") -> bool:
	var c: Dictionary = _man.get("cues", {}).get(id, {})
	var first := bool(c.get("firstSound", false))   # leaderPick, returnAway: the first gesture's own sound
	if not _gate_open() and not first:
		return false
	if _locked():
		if first:
			_held_first = {"id": id, "variant": variant, "t": now}   # waits for the unlock like the motif
		else:
			_held = {"id": id, "variant": variant, "pitch": pitch, "db": extra_db, "bus": bus, "t": now}
		return false
	if c.is_empty():
		_warn_once("unknown cue '%s'" % id)
		return false
	var file := OdAudio.cue_file(_man, id, key(), pitch, variant)
	if file == "":
		_warn_once("no file for %s in key %s" % [id, key()])
		return false
	var b := bus if bus != "" else String(c.get("bus", "UI"))
	var len_ms := float(c.get("lengthMs", 100.0))
	if not _voice(id, file, b, float(c.get("play_db", 0.0)) + extra_db, int(c.get("priority", 1)),
			int(c.get("poly", 1)), String(c.get("steal", "oldest")), now, len_ms):
		return false
	for dk: Dictionary in c.get("ducks", []):
		_duck("music" if String(dk.get("bus", "Music")) == "Music" else "voice", float(dk["db"]),
			float(dk["attackMs"]), float(dk["releaseMs"]), now, len_ms)
	var mk: Variant = c.get("markers", {}).get(variant, c.get("markers", {}).get("_"))
	if mk is Dictionary:
		for n: String in mk:
			var nm := n
			_sched_at(now + float(mk[n]) * 1000.0, func() -> void: marker.emit(id, nm))
	if DUBI_CUES.has(id):
		_dubi_quiet_at = maxf(_dubi_quiet_at, now + len_ms)
	return true


## Plays a stinger in `key_` (the current key when ""), `tags` picking the fanfare length.
func _stinger(id: String, now: float, key_ := "", tags := "_") -> bool:
	if not _gate_open():
		return false
	if _locked():
		return false
	var st: Dictionary = _man.get("stingers", {}).get(id, {})
	var e := OdAudio.stinger_entry(_man, id, key_ if key_ != "" else key(), tags)
	if st.is_empty() or e.is_empty():
		_warn_once("no stinger %s in key %s" % [id, key_])
		return false
	var bus := String(st.get("bus", "SFX-Critical"))
	var prio := 5 if ["motif", "fanfare", "courtIn"].has(id) else 4
	var len_ms := float(e["musicalSamples"]) / float(e["rate"]) * 1000.0
	if not _voice(id, String(e["file"]), bus, float(st.get("play_db", 0.0)), prio, 1, "oldest", now, len_ms):
		return false
	# ducks per bus (cue-spec §3): Voice -6 dB, SFX-Critical -4 dB except the motif and courtIn;
	# the fanfare replaces the bed and ducks nothing
	if bus == "Voice":
		_duck("music", -6.0, 30.0, 250.0, now, len_ms)
		_dubi_quiet_at = maxf(_dubi_quiet_at, now + len_ms)
	elif bus == "SFX-Critical" and not ["motif", "courtIn"].has(id):
		_duck("music", -4.0, 50.0, 200.0, now, len_ms)
	if id == "motif":
		# O-A3: Dubi waits for the motif's musical end (the file's tail may ring on)
		_motif_end = now + float(e.get("musicalSeconds", len_ms / 1000.0)) * 1000.0
	return true


## Starts one voice: per-cue polyphony (steal the oldest, or drop the new one for "never"), the
## global cap by priority (5 is never stolen), then the file.
func _voice(id: String, file: String, bus: String, db: float, prio: int, poly: int, steal: String, now: float, len_ms: float) -> bool:
	_active(now)
	var mine := _voices.filter(func(v: Dictionary) -> bool: return v["cue"] == id)
	if mine.size() >= maxi(1, poly):
		if steal == "never":
			return false
		_steal(mine[0])
	if not _room_under_cap(prio):
		return false
	var stream := _stream(file)
	if stream == null:
		_warn_once("missing %s (run tools/audio.sh)" % file)
		return false
	var p := _free_player()
	p.stream = stream
	p.bus = bus
	p.volume_db = db
	p.pitch_scale = 1.0   # never: every pitch is its own file
	p.stream_paused = _paused
	if p.is_inside_tree():
		p.play()
	var length := stream.get_length() * 1000.0
	if length <= 0.0:
		length = len_ms
	_voices.append({"p": p, "cue": id, "start": now, "end": now + length, "prio": prio})
	_log.append(file)
	_log_t.append(roundf(now))
	if _log.size() > 24:
		_log.pop_front()
		_log_t.pop_front()
	return true


func _room_under_cap(prio: int) -> bool:
	if _voices.size() < VOICE_CAP:
		return true
	var victim: Dictionary = {}
	for v in _voices:
		var vp := int(v["prio"])
		if vp >= 5 or vp > prio:
			continue
		if victim.is_empty() or vp < int(victim["prio"]) or (vp == int(victim["prio"]) and float(v["start"]) < float(victim["start"])):
			victim = v
	if victim.is_empty():
		return false
	_steal(victim)
	return true


func _active(now: float) -> Array:
	if now >= 0.0:
		_voices = _voices.filter(func(v: Dictionary) -> bool: return float(v["end"]) > now)
	return _voices


func _steal(v: Dictionary) -> void:
	var p: AudioStreamPlayer = v["p"]
	if p.playing:
		p.stop()
	_voices.erase(v)


func _free_player() -> AudioStreamPlayer:
	for p in _players:
		var busy := false
		for v in _voices:
			if v["p"] == p:
				busy = true
				break
		if not busy:
			return p
	var oldest: Dictionary = _voices[0]
	_steal(oldest)
	return oldest["p"]


func _stream(file: String) -> AudioStream:
	if not _streams.has(file):
		var path := OdAudio.DIR + file
		if _requested.has(path):
			_requested.erase(path)
			_streams[file] = ResourceLoader.load_threaded_get(path) as AudioStream
		else:
			_streams[file] = load(path) as AudioStream if ResourceLoader.exists(path) else null
	return _streams[file]


## Starts loading an era's stems in the background (they are needed at a bar line later).
func _prefetch(era_id: String) -> void:
	var e: Dictionary = _man.get("eras", {}).get(era_id, {})
	var files: Array = (e.get("layers", {}) as Dictionary).values()
	if e.has("outside"):
		files.append(e["outside"]["file"])
	for f: Variant in files:
		var path := OdAudio.DIR + String(f)
		if not _streams.has(String(f)) and ResourceLoader.exists(path) \
				and ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			if ResourceLoader.load_threaded_request(path, "AudioStream") == OK:
				_requested.append(path)


func _sched_at(at: float, fn: Callable) -> void:
	_sched.append({"at": at, "fn": fn})


# ================================================================== gameplay cues

func _suitcase_spawn(now: float, arg: Variant) -> void:
	var x := 0.5
	if arg is float or arg is int:
		x = clampf(float(arg), 0.0, 1.0)
	elif arg is Dictionary and (arg as Dictionary).has("x"):
		x = clampf(float(arg["x"]), 0.0, 1.0)
	var bi := AudioServer.get_bus_index("Suitcase")
	if bi >= 0 and AudioServer.get_bus_effect_count(bi) > 0:
		var pan := AudioServer.get_bus_effect(bi, 0) as AudioEffectPanner
		if pan:
			pan.pan = lerpf(-0.4, 0.4, x)
	_cue("suitcaseSpawn", now, _random_variant("suitcaseSpawn"), "_", 0.0, "Suitcase" if bi >= 0 else "")


func _coins(now: float, arg: Variant) -> void:
	var n := clampi(int(arg) if (arg is int or arg is float) else 1, 1, COIN_MAX)
	for i in n:
		_sched_at(now + i * COIN_GAP_MS, func() -> void: _cue_alt("coin", _now()))


func _ultimatum_tick(now: float, arg: Variant) -> void:
	var left := float(arg) if (arg is int or arg is float) else 99.0
	_cue_alt("ultimatumTick", now)
	if left <= 3.0:
		_ult_force = true
		if left > 0.0:
			_sched_at(now + 500.0, func() -> void:
				if _ult_force:
					_cue_alt("ultimatumTick", _now()))


func _court_in(now: float, _summons: bool, skin: Variant = null) -> void:
	if _court:
		return   # testimony after a summons: the startle is silent
	_court = true
	# v1.3: the press (every leader but Bibi, spec §5.6) opens its day with the cameras, not a gavel;
	# the courthouse hush and courtIn are the hazard's, shared
	var press := str(skin) == "press" if (skin is String and (skin == "press" or skin == "court")) else _hazard_skin() == "press"
	_cue_alt("shutter" if press else "gavel", now)
	if _music_live:
		_court_stinger = "in"
	else:
		_stinger("courtIn", now, "G")


func _court_out(now: float, reason: String) -> void:
	if reason.begins_with("postpone"):
		_cue("gavelWeak", now)
	if not _court:
		return
	_court = false
	if _music_live:
		_court_stinger = "out"
	else:
		_cue("courtOut", now)


## v1.3: the save was wiped (the reset card's confirm). The music fades out over one bar (no
## stinger), everything pending is dropped, and the first-tap gate closes again: the wiped game
## starts like a new one (the pick, then the motif on the first Magician tap).
func _game_reset(_now_ms: float) -> void:
	stop_babble()
	if _music_live:
		_ramp_bed(0.0, OdAudio.bar_seconds(_man, _track) * 1000.0, true)
	_restart_at = -1.0
	_restart_era = ""
	_restart_on_tap = false
	_fanfare = {}
	_court = false
	_court_stinger = ""
	_ult_force = false
	_rabbit_due = -1.0
	_held = {}
	_held_first = {}
	_held_motif = -1.0
	_ping_q = {"n": 0, "variant": "", "left": false}
	_first_tap = false
	_tap_streak = -1
	_tap_prev = -1e12
	_tap_phrase = -1
	_tap_note = -1
	_sources = 0
	_leader = ""


## Coalition collapse (cue-spec §2.6, v1.2): the music fades out over one bar, then silence, with
## no stinger (the motif is the anthem's contour and is never a loss sting). The next tap restarts
## the music at bar 1.
func _collapse(_now_ms: float) -> void:
	if _music_live:
		_ramp_bed(0.0, OdAudio.bar_seconds(_man, _track) * 1000.0, true)
	_restart_at = -1.0
	_restart_on_tap = true


## The election fanfare (§2.4): on the confirm frame, in the incoming era's key, tags by the
## election number; the bed stops in 30 ms; the incoming era starts at bar 1 after musicalSamples.
func _election(now: float, arg: Variant) -> void:
	# v1.5: a new round starts HaTikva again from its first phrase
	_tap_phrase = -1
	_tap_note = -1
	var n := _evolutions + 1
	if (arg is int or arg is float) and int(arg) > 0:
		n = int(arg)
	var incoming := era_for(maxi(n, _evolutions + 1))
	var k := OdAudio.era_key(_man, incoming)
	var tags := OdAudio.fanfare_tags(n)
	var e := OdAudio.stinger_entry(_man, "fanfare", k, str(tags))
	if e.is_empty():
		return
	var end_ms := float(e["musicalSamples"]) / float(e["rate"]) * 1000.0
	_fanfare = {"t0": now, "key": k, "tags": tags, "markers": e.get("markers", {}), "fired": {}, "end": end_ms}
	_prefetch(incoming)
	_court_stinger = ""
	_court = false   # the election ends the round, court day with it (the Magician returns quick)
	if _music_live:
		_ramp_bed(0.0, BED_STOP_MS, true)
	_stinger("fanfare", now, k, str(tags))
	_restart_at = now + end_ms
	_restart_era = incoming


func _update_fanfare(now: float) -> void:
	if _fanfare.is_empty():
		return
	var t := (now - float(_fanfare["t0"])) / 1000.0
	var mk: Dictionary = _fanfare["markers"]
	var fired: Dictionary = _fanfare["fired"]
	for n: String in ["pickup", "rollEnd", "fanfareEnd"]:
		if mk.has(n) and not fired.has(n) and t >= float(mk[n]):
			fired[n] = true
			marker.emit("fanfare", n)
	var tags: Array = mk.get("tagOnsets", [])
	for i in tags.size():
		var nm := "tag%d" % (i + 1)
		if not fired.has(nm) and t >= float(tags[i]):
			fired[nm] = true
			marker.emit("fanfare", nm)
	if t * 1000.0 > float(_fanfare["end"]) + 500.0:
		_fanfare = {}


func _pink_set(on: bool) -> void:
	if on and not bool(Content.data().get("flags", {}).get("easterEggs", false)):
		return   # the Pink Front is behind the content's easterEggs flag
	_pink_on = on


func _update_pink(dt: float) -> void:
	var bar_s := OdAudio.bar_seconds(_man, "balfour")
	var sweep := float(_man.get("outsideSpec", {}).get("pinkFront", {}).get("sweepBars", 2.0)) * bar_s
	_pink_k = move_toward(_pink_k, 1.0 if _pink_on else 0.0, dt / maxf(0.01, sweep))
	if absf(_pink_k - _pink_applied) < 1e-4:
		return
	_pink_applied = _pink_k
	var bi := AudioServer.get_bus_index("Outside")
	if bi >= 0 and AudioServer.get_bus_effect_count(bi) > 0:
		var lpf := AudioServer.get_bus_effect(bi, 0) as AudioEffectFilter
		if lpf:
			lpf.cutoff_hz = OdAudio.pink_cutoff(_man, _pink_k)


# ================================================================== the chat and Dubi

func _dubi_busy(now: float) -> bool:
	if not _babble.is_empty():
		return true
	return now < _dubi_quiet_at + PING_AFTER_DUBI_MS


func _ping(now: float, variant: String) -> void:
	if not _gate_open():
		return
	if _dubi_busy(now) or now - _ping_last < PING_GAP_MS:
		_ping_q["n"] = int(_ping_q["n"]) + 1
		_ping_q["variant"] = variant
		if variant == "left":
			_ping_q["left"] = true
		return
	_ping_last = now
	_cue("chatPing", now, variant)


func _update_pings(now: float) -> void:
	if int(_ping_q["n"]) == 0 or _dubi_busy(now) or now - _ping_last < PING_GAP_MS:
		return
	var v := "left" if bool(_ping_q["left"]) else ("burst" if int(_ping_q["n"]) > 1 else String(_ping_q["variant"]))
	_ping_q = {"n": 0, "variant": "", "left": false}
	_ping_last = now
	_cue("chatPing", now, v)


## Dubi speaks a line: kind "flash" (a story card; after the dubiFlash head) or "headline" (the
## ticker; at most one per 20 s, the rest are silent). A squawk first ('up' before a headline,
## 'down' before a canned line or a flash), then the blips.
func _dubi_speak(now: float, text: String, kind: String) -> void:
	if kind == "headline" and not _babble.is_empty() and not bool(_babble["squawked"]):
		return   # a line still waiting for the motif (O-A3: tap 1's "אין כלום!") is not cut by a headline
	stop_babble()
	if not _gate_open() or text.strip_edges() == "":
		return
	if kind == "headline":
		if now - _headline_at < HEADLINE_GAP_MS:
			return
		_headline_at = now
	var plan := OdAudio.babble_plan(_man, text)
	if (plan["blips"] as Array).is_empty():
		return
	var t0 := now
	if kind == "flash" and now - _flash_at < BABBLE_AFTER_FLASH_MS:
		t0 = _flash_at + BABBLE_AFTER_FLASH_MS
	var squawk := "up" if kind == "headline" and not bool(plan["canned"]) else "down"
	var sq_ms := float(_man.get("cues", {}).get("dubiSquawk", {}).get("lengthMs", 109.0))
	var blip_ms := float(_man.get("cues", {}).get("dubiBlip", {}).get("lengthMs", 71.0))
	_babble = {"t0": t0, "blips": plan["blips"], "i": 0, "squawk": squawk, "squawked": false,
		"lead": sq_ms, "end": t0 + sq_ms + float(plan["length"]) * 1000.0 + blip_ms}


func _update_babble(now: float) -> void:
	if _babble.is_empty():
		return
	var t0 := float(_babble["t0"])
	if not bool(_babble["squawked"]):
		# O-A3: a line that would start under the motif moves, whole, to the motif's end
		var clear := _dubi_clear_at()
		if is_inf(clear):
			return
		if t0 < clear:
			_babble["end"] = float(_babble["end"]) + (clear - t0)
			t0 = clear
			_babble["t0"] = t0
	if now < t0:
		return
	if not bool(_babble["squawked"]):
		_babble["squawked"] = true
		_cue("dubiSquawk", now, String(_babble["squawk"]))
	var start := t0 + float(_babble["lead"])
	var blips: Array = _babble["blips"]
	var i := int(_babble["i"])
	while i < blips.size() and start + float(blips[i]["t"]) * 1000.0 <= now:
		var b: Dictionary = blips[i]
		if now - (start + float(b["t"]) * 1000.0) <= BABBLE_LATE_MS and not _locked():
			_steal_cue("dubiBlip")   # poly 1: the next syllable cuts the last one
			if _cue("dubiBlip", now, "_", String(b["bank"])):
				dubi_blip.emit(String(b["bank"]))
		i += 1
	_babble["i"] = i
	if i >= blips.size() and now >= float(_babble["end"]):
		_babble = {}
		_dubi_quiet_at = maxf(_dubi_quiet_at, now)


func _steal_cue(id: String) -> void:
	for v in _voices.duplicate():
		if v["cue"] == id:
			_steal(v)


# ================================================================== ducks

## A duck on "music" (the decks) or "voice" (the Voice bus), held for `hold_ms` after its attack.
func _duck(target: String, db: float, attack: float, release: float, now: float, hold_ms: float) -> void:
	var list: Array = _ducks.get(target, [])
	list.append({"db": db, "start": now, "end": now + attack + hold_ms, "attack": attack, "release": release})
	_ducks[target] = list


## Each target moves toward the deepest active duck (time constant attack/3) or back to 0 dB
## (release/3). Ducks never add.
func _update_ducks(now: float, dt_ms: float) -> void:
	for target: String in ["music", "voice"]:
		var list: Array = (_ducks.get(target, []) as Array).filter(func(x: Dictionary) -> bool:
			return float(x["end"]) + float(x["release"]) * 5.0 > now)
		_ducks[target] = list
		var want := 0.0
		var tc := 50.0 / 3.0
		var act := list.filter(func(x: Dictionary) -> bool: return float(x["start"]) <= now and float(x["end"]) > now)
		if not act.is_empty():
			tc = 1e9
			for x: Dictionary in act:
				want = minf(want, float(x["db"]))
				tc = minf(tc, float(x["attack"]) / 3.0)
		else:
			for x: Dictionary in list:
				tc = maxf(tc, float(x["release"]) / 3.0)
		var cur := float(_duck_db[target])
		cur += (want - cur) * (1.0 - exp(-dt_ms / maxf(tc, 1.0)))
		if list.is_empty() and absf(cur) < 0.01:
			cur = 0.0
		_duck_db[target] = cur


# ================================================================== buses

func _apply_buses() -> void:
	var m := AudioServer.get_bus_index("Music")
	if m >= 0:
		var lin := float(_toggle["music"])
		var db := OdAudio.slider_db(float(_vol["music"])) + (linear_to_db(lin) if lin > 0.0001 else OFF_DB)
		AudioServer.set_bus_volume_db(m, maxf(db, OFF_DB))
		AudioServer.set_bus_mute(m, lin <= 0.0001 or float(_vol["music"]) <= 0.0001)
	for b: String in SFX_BUSES:
		var i := AudioServer.get_bus_index(b)
		if i < 0:
			continue
		var lin := float(_toggle["sfx"])
		var db := OdAudio.slider_db(float(_vol["sfx"])) + (linear_to_db(lin) if lin > 0.0001 else OFF_DB)
		if b == "Voice":
			db += float(_duck_db["voice"])
		AudioServer.set_bus_volume_db(i, maxf(db, OFF_DB))
		AudioServer.set_bus_mute(i, lin <= 0.0001 or float(_vol["sfx"]) <= 0.0001)


# ================================================================== music

## The track an era plays (the manifest's eras; an unknown era plays Balfour's).
func _track_of(era_id: String) -> String:
	return era_id if _man.get("eras", {}).has(era_id) else "balfour"


## The track the music should be on now: the Courthouse on court day, else the era's.
func _track_want() -> String:
	return "courthouse" if _court else _track_of(_era)


func _content_eras() -> Array:
	var ids: Array = []
	for e: Variant in Content.data().get("eras", {}).get("list", []):
		if e is Dictionary:
			ids.append(String((e as Dictionary).get("id", "")))
	return ids


func _sync_for(track: String) -> AudioStreamSynchronized:
	if _sync.has(track):
		return _sync[track]
	var layers: Dictionary = _man.get("eras", {}).get(track, {}).get("layers", {})
	var sync := AudioStreamSynchronized.new()
	sync.stream_count = LAYERS.size()
	for i in LAYERS.size():
		var f := String(layers.get(LAYERS[i], ""))
		var s: AudioStream = _stream(f) if f != "" else null
		if s == null:
			_warn_once("missing stem %s %s (run tools/audio.sh)" % [track, LAYERS[i]])
		sync.set_sync_stream(i, s)
		sync.set_sync_stream_volume(i, OFF_DB)
	_sync[track] = sync
	return sync


## Whether a layer should sound during `bar` of the current loop: its rule, the forced mutes
## (court day, an ultimatum's last 3 s: L2) and the 4-loop cycle.
func _layer_want(layer: String, bar_n: int) -> bool:
	var on := true
	match layer:
		"L1":
			on = _sources >= 1
		"L2":
			on = _now() - _last_tap < OdAudio.L2_TAP_WINDOW_MS and not _court and not _ult_force
	if not on or layer == "L0":
		return on
	return not OdAudio.af_off_during(_man, layer, _loop, bar_n, OdAudio.bars_per_loop(_man, _track))


## A layer's gain when it sounds: 1, except the lead under the tap's HaTikva (v1.6).
func _layer_level(layer: String, bar_n: int) -> float:
	if not _layer_want(layer, bar_n):
		return 0.0
	return OdAudio.L2_UNDER_BELL if layer == "L2" and not _tap_melody.is_empty() else 1.0


func _snap_layers(bar_n: int) -> void:
	_lramp = {}
	for l: String in LAYERS:
		var g := _layer_level(l, bar_n)
		_lg[l] = g
		_lt[l] = g
	_push_layers()


func _push_layers() -> void:
	if not _sync.has(_track):
		return
	var sync: AudioStreamSynchronized = _sync[_track]
	for i in LAYERS.size():
		var g := float(_lg[LAYERS[i]])
		sync.set_sync_stream_volume(i, linear_to_db(g) if g > 0.0001 else OFF_DB)


## Plays `track` on deck `d` from `pos` seconds (the Outside loop alongside on Balfour).
func _deck_play(d: int, track: String, pos: float) -> void:
	_deck_track[d] = track
	var m := _mp[d]
	m.stream = _sync_for(track)
	m.stream_paused = _paused
	if m.is_inside_tree():
		m.play(pos)
	_deck_started_at = _now()
	_deck_started_pos = pos
	var o := _op[d]
	var out: Dictionary = _man.get("eras", {}).get(track, {}).get("outside", {})
	if o.playing:
		o.stop()
	if not out.is_empty():
		var s := _stream(String(out.get("file", "")))
		if s:
			o.stream = s
			o.stream_paused = _paused
			var ol := float(out.get("loopSamples", 132000)) / float(_man["eras"][track].get("rate", 31900))
			if o.is_inside_tree():
				o.play(fposmod(pos, ol))


## Starts the music at bar 1 of the track wanted now.
func _begin_music(fade_ms: float) -> void:
	if not _music_on or _man.is_empty():
		return
	_restart_at = -1.0
	for i in 2:
		if _mp[i].playing:
			_mp[i].stop()
		if _op[i].playing:
			_op[i].stop()
	_xf = {}
	_track = _track_want()
	_music_live = true
	_song_clock = 0.0
	_pos_prev = 0.0
	_bar_i = 0
	_loop = 1
	_bed_ramp = {}
	_bed = 1.0
	if fade_ms > 0.0:
		_bed = 0.0
		_ramp_bed(1.0, fade_ms, false)
	_snap_layers(1)
	_deck_play(_d, _track, 0.0)
	_push_deck_volumes()


func _stop_music() -> void:
	_music_live = false
	_xf = {}
	_bed_ramp = {}
	_court_stinger = ""
	for i in 2:
		if _mp[i].playing:
			_mp[i].stop()
		if _op[i].playing:
			_op[i].stop()


func _ramp_bed(to: float, ms: float, stop: bool) -> void:
	_bed_ramp = {"from": _bed, "to": to, "t0": _now(), "ms": maxf(1.0, ms), "stop": stop}


## The cross-fade onto the same bar of the wanted track (equal power, courtDay.xfadeMs).
func _switch_track(now: float, bar_n: int) -> void:
	var want := _track_want()
	if want == _track:
		return
	_prefetch(want)
	var nd := 1 - _d
	var pos := float(bar_n - 1) * OdAudio.bar_seconds(_man, want)
	_d = nd
	_track = want
	_loop = 1   # the loop counter resets with the track
	_bar_i = bar_n - 1
	_song_clock = pos
	_pos_prev = pos
	_snap_layers(bar_n)
	_deck_play(nd, want, pos)
	_xf = {"t0": now, "ms": float(_man.get("courtDay", {}).get("xfadeMs", 400.0))}
	_push_deck_volumes()


## A bar line of the playing track: a pending track switch, the court stinger, then the layer
## targets for the bar that starts (each change ramps linearly over this bar).
func _on_bar_line(now: float, bar_n: int) -> void:
	if _track_want() != _track:
		_switch_track(now, bar_n)
	match _court_stinger:
		"in":
			_stinger("courtIn", now, "G")
		"out":
			_cue("courtOut", now)
	_court_stinger = ""
	var bar_ms := OdAudio.bar_seconds(_man, _track) * 1000.0
	for l: String in LAYERS:
		var to := _layer_level(l, bar_n)
		if to != float(_lt[l]):
			_lt[l] = to
			_lramp[l] = {"from": float(_lg[l]), "to": to, "t0": now, "ms": bar_ms}


func _push_deck_volumes() -> void:
	var duck := db_to_linear(float(_duck_db["music"]))
	var k := 1.0
	if not _xf.is_empty():
		k = clampf((_now() - float(_xf["t0"])) / maxf(1.0, float(_xf["ms"])), 0.0, 1.0)
	for i in 2:
		var g := _bed * duck
		if not _xf.is_empty():
			g *= sin(k * PI * 0.5) if i == _d else cos(k * PI * 0.5)
		elif i != _d:
			g = 0.0
		var tr := _deck_track[i]
		var era_d: Dictionary = _man.get("eras", {}).get(tr, {})
		var lin_db := linear_to_db(g) if g > 0.0001 else OFF_DB
		_mp[i].volume_db = maxf(OFF_DB, float(era_d.get("play_db", 0.0)) + lin_db)
		var out: Dictionary = era_d.get("outside", {})
		if not out.is_empty():
			var rise := float(_man.get("outsideSpec", {}).get("riseDb", 6.0)) * _era_progress
			_op[i].volume_db = maxf(OFF_DB, float(out.get("play_db", 0.0)) + rise + OdAudio.pink_boost_db(_man, _pink_k) + lin_db)
	if not _xf.is_empty() and k >= 1.0:
		_xf = {}
		var o := 1 - _d
		if _mp[o].playing:
			_mp[o].stop()
		if _op[o].playing:
			_op[o].stop()


func _update_music(now: float, dt: float) -> void:
	if _restart_at >= 0.0 and now >= _restart_at:
		_restart_at = -1.0
		if _restart_era != "":
			_era = _restart_era   # the election seam has normally set it already
			_restart_era = ""
		if _music_on and _first_tap:
			_begin_music(0.0)
	if not _bed_ramp.is_empty():
		var k := clampf((now - float(_bed_ramp["t0"])) / float(_bed_ramp["ms"]), 0.0, 1.0)
		_bed = lerpf(float(_bed_ramp["from"]), float(_bed_ramp["to"]), k)
		if k >= 1.0:
			var stop := bool(_bed_ramp["stop"])
			_bed_ramp = {}
			if stop:
				_stop_music()
	if not _music_live:
		return
	var loop_s := OdAudio.loop_seconds(_man, _track)
	var bar_s := OdAudio.bar_seconds(_man, _track)
	var pos: float
	var m := _mp[_d]
	if m.playing and not _dummy:
		var pp := m.get_playback_position()
		if now - _deck_started_at < 250.0 and absf(pp - _deck_started_pos) < 0.001:
			pos = _pos_prev + dt   # a fresh playback reports its start until the mixer reaches it
		else:
			pos = pp + AudioServer.get_time_since_last_mix()
	else:
		if not _paused:
			_song_clock += dt
		pos = fposmod(_song_clock, loop_s)
	pos = fposmod(pos, loop_s)
	if pos < _pos_prev - loop_s * 0.5:
		_loop += 1
		_bar_i = -1
	_pos_prev = pos
	var bi := clampi(int(floor(pos / bar_s + 1e-6)), 0, OdAudio.bars_per_loop(_man, _track) - 1)
	if bi != _bar_i:
		_bar_i = bi
		_on_bar_line(now, bi + 1)
	var changed := false
	for l: String in _lramp.keys():
		var r: Dictionary = _lramp[l]
		var k := clampf((now - float(r["t0"])) / maxf(1.0, float(r["ms"])), 0.0, 1.0)
		_lg[l] = lerpf(float(r["from"]), float(r["to"]), k)
		changed = true
		if k >= 1.0:
			_lramp.erase(l)
	if changed:
		_push_layers()


# ================================================================== the frame

func _process(dt: float) -> void:
	if not _ok:
		return
	if not _paused:
		_clock += dt * 1000.0
	var now := _now()
	var dt_ms := dt * 1000.0
	for g: String in ["sfx", "music"]:
		var tgt := 1.0 if (_sfx_on if g == "sfx" else _music_on) else 0.0
		var cur := float(_toggle[g])
		if cur != tgt:
			cur += (tgt - cur) * (1.0 - exp(-dt_ms / (TOGGLE_RAMP_MS / 3.0)))
			if absf(cur - tgt) < 0.001:
				cur = tgt
			_toggle[g] = cur
	_active(now)
	if not _paused:
		if not _sched.is_empty():
			var due := _sched.filter(func(s: Dictionary) -> bool: return float(s["at"]) <= now)
			if not due.is_empty():
				_sched = _sched.filter(func(s: Dictionary) -> bool: return float(s["at"]) > now)
				for s: Dictionary in due:
					(s["fn"] as Callable).call()
		if _rabbit_due >= 0.0 and now >= _rabbit_due:
			_rabbit_now(now)
		_update_babble(now)
		_update_pings(now)
		_update_fanfare(now)
	_update_ducks(now, dt_ms)
	_apply_buses()
	_update_music(now, dt if not _paused else 0.0)
	_update_pink(dt)
	_push_deck_volumes()
	if _web:
		_update_web(now, dt)


func _update_web(now: float, dt: float) -> void:
	_web_poll -= dt
	if _web_poll <= 0.0 or not _web_running:
		_web_poll = WEB_POLL_S
		var st: Variant = JavaScriptBridge.eval("window.mbAudioState ? window.mbAudioState() : 'running'", true)
		var running := st == null or String(st).contains("running")   # no bridge: assume it plays
		var first := running and not _web_running
		_web_running = running
		if first:
			_unlocked = true
			if not _held_first.is_empty():
				if now - float(_held_first["t"]) <= MOTIF_HOLD_MAX_MS:
					_cue(String(_held_first["id"]), now, String(_held_first["variant"]))
				_held_first = {}
			if _held_motif >= 0.0:
				if now - _held_motif <= MOTIF_HOLD_MAX_MS:
					_play_intro(now)
				_held_motif = -1.0
			if not _held.is_empty() and now - float(_held["t"]) <= HOLD_MAX_MS:
				_cue(String(_held["id"]), now, String(_held["variant"]), String(_held["pitch"]), float(_held["db"]), String(_held["bus"]))
			_held = {}
	_pub_t -= dt
	if _pub_t > 0.0:
		return
	_pub_t = WEB_POLL_S
	var bus := AudioServer.get_bus_index("Music")
	var db := maxf(AudioServer.get_bus_peak_volume_left_db(bus, 0), -200.0) if bus >= 0 else -200.0
	JavaScriptBridge.eval("window.mbMusicPeak = %.1f; window.mbMusicTrack = %s; window.odCueLogMs = %s; window.odCueLog = %s; window.odAudioKey = %s;"
		% [db, JSON.stringify(track_name()), JSON.stringify(_log_t), JSON.stringify(_log), JSON.stringify(key())], true)
