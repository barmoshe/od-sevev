extends RefCounted
## עוד סבב: the sound runtime (scripts/autoload/audio.gd + scripts/audio/od_audio.gd) against
## audio/od/cue-spec.md and the rendered od_manifest.json. Runs under the dummy audio driver:
## every check reads the runtime's bookkeeping (voices, files played, layer targets, the song
## clock), not the sound card.

var runner: Object

const AudioScript := preload("res://scripts/autoload/audio.gd")
## The controller's event vocabulary (main.gd) plus the od events the engine will emit.
const CONTROLLER_EVENTS := ["tap", "tapCrit", "buy", "buyBulk", "cantAfford", "upgradeBuy", "goldenSpawn",
	"goldenCatch", "goldenDespawn", "frenzyStart", "frenzyEnd", "tapFrenzyStart", "tapFrenzyEnd",
	"milestoneHeadline", "evolveOpen", "evolveClose", "evolveReady", "evolveTransitionEnd",
	"offlineCollect", "panelOpen", "panelClose", "uiClick", "uiToggle", "buyModeCycle", "becameAffordable",
	"producerReveal", "achievement", "perkBuy", "milestone", "storyCard", "era", "babble",
	"courtSummons", "courtStart", "courtEnd", "trickCue", "ceremonyEnd", "chatPing", "chatLeft",
	"ultimatumTick", "ultimatumZero", "stamp", "coin", "photobomb", "transfer", "trophy", "headline"]

var _a: Node
var _man: Dictionary


func setup(_r: Object) -> void:
	TestFixture.use_game_content()   # the od eras (balfour, knesset, courthouse, washington)
	_man = OdAudio.manifest()


func teardown() -> void:
	if is_instance_valid(_a):
		_a.queue_free()
	TestFixture.use_game_content()


## A fresh runtime per test (the autoload keeps its own state).
func _audio() -> Node:
	_a = AudioScript.new()
	(runner as SceneTree).root.add_child(_a)
	return _a


## Frees the runtime and gives the audio server time to drop its playbacks.
func _release() -> void:
	if is_instance_valid(_a):
		_a.queue_free()
	await (runner as SceneTree).create_timer(0.15).timeout


func _frames(n: int) -> void:
	for i in n:
		await (runner as SceneTree).process_frame


func _last(a: Node) -> String:
	var l: Array[String] = a.recent_files()
	return l[l.size() - 1] if not l.is_empty() else ""


## A runtime past its first tap (the motif) with the music live at bar 1.
func _playing() -> Node:
	var a := _audio()
	a.set_evolutions(0)
	a.event("tap")
	a.debug_skip_wait()
	await _frames(2)
	return a


# ------------------------------------------------------------------ files and buses

func test_every_manifest_file_exists_and_loads() -> void:
	runner.check(not _man.is_empty(), "od_manifest.json exists (run tools/audio.sh)")
	var files := OdAudio.all_files(_man)
	var want := 0
	for n: Variant in (_man.get("sizes", {}).get("files", {}) as Dictionary).values():
		want += int(n)
	runner.check(files.size() == want, "the manifest names %d files, its sizes say %d" % [files.size(), want])
	var missing: Array[String] = []
	for f in files:
		var s: AudioStreamWAV = load(OdAudio.DIR + f) as AudioStreamWAV if ResourceLoader.exists(OdAudio.DIR + f) else null
		if s == null:
			missing.append(f)
	runner.check(missing.is_empty(), "every file loads as an AudioStreamWAV, missing %s" % str(missing.slice(0, 5)))
	for era: String in ["balfour", "knesset", "courthouse", "washington"]:
		var e: Dictionary = _man["eras"][era]
		for l: String in ["L0", "L1", "L2"]:
			var w: AudioStreamWAV = load(OdAudio.DIR + String(e["layers"][l]))
			runner.check(w.loop_mode == AudioStreamWAV.LOOP_FORWARD and w.loop_end == int(e["loopSamples"]),
				"%s %s loops forward over the whole song" % [era, l])
		runner.check(OdAudio.bars_per_loop(_man, era) == 32, "%s has 32 bars" % era)
	var tap: AudioStreamWAV = load(OdAudio.DIR + OdAudio.cue_file(_man, "tap", "D", String(OdAudio.tap_melody(_man)[0]), "bell"))
	runner.check(tap.loop_mode == AudioStreamWAV.LOOP_DISABLED, "cues are one-shots")
	runner.check(not ResourceLoader.exists("res://assets/audio/sfx_tap.wav"), "the fork's sounds are out of the build")


func test_bus_layout_is_the_od_topology() -> void:
	var sends := {"Music": "Master", "Outside": "Music", "SFX-Critical": "Master", "Suitcase": "SFX-Critical",
		"SFX-Frequent": "Master", "UI": "Master", "Voice": "Master"}
	for b: String in sends:
		var i := AudioServer.get_bus_index(b)
		runner.check(i >= 0, "bus %s exists" % b)
		if i >= 0:
			runner.check(String(AudioServer.get_bus_send(i)) == sends[b], "%s sends to %s" % [b, sends[b]])
			runner.check(absf(AudioServer.get_bus_volume_db(i)) < 0.01, "%s sits at unity" % b)
	# v1.6 mix pass: HPF 35 Hz (below what a phone plays), a 2:1 glue compressor, then the limiter
	runner.check(AudioServer.get_bus_effect_count(0) == 3, "the master chain is HPF, glue, limiter")
	var hpf := AudioServer.get_bus_effect(0, 0) as AudioEffectHighPassFilter
	var glue := AudioServer.get_bus_effect(0, 1) as AudioEffectCompressor
	var lim := AudioServer.get_bus_effect(0, 2) as AudioEffectHardLimiter
	runner.check(hpf != null and absf(hpf.cutoff_hz - 35.0) < 1e-3, "master HPF at 35 Hz")
	runner.check(glue != null and absf(glue.ratio - 2.0) < 1e-4 and absf(glue.threshold + 14.0) < 1e-4, "glue: 2:1 from -14 dB")
	runner.check(lim != null and absf(lim.ceiling_db + 1.0) < 1e-4 and absf(lim.pre_gain_db - 2.0) < 1e-4, "HardLimiter at -1 dB, +2 dB pre-gain")
	# v1.7: the music bus is refined: a presence dip for the SFX slot, a softer top, a small room
	var mu := AudioServer.get_bus_index("Music")
	var eq := AudioServer.get_bus_effect(mu, 0) as AudioEffectEQ6
	var room := AudioServer.get_bus_effect(mu, 1) as AudioEffectReverb
	runner.check(eq != null and absf(eq.get_band_gain_db(4) + 2.5) < 1e-3 and absf(eq.get_band_gain_db(5) + 2.0) < 1e-3, "music EQ: -2.5 dB at 3.2 kHz, -2 dB at 10 kHz")
	runner.check(room != null and room.wet <= 0.15 and room.hipass >= 0.2, "music room: a light wet, the bass kept dry")
	var o := AudioServer.get_bus_index("Outside")
	var lpf := AudioServer.get_bus_effect(o, 0) as AudioEffectLowPassFilter
	var pan := AudioServer.get_bus_effect(o, 1) as AudioEffectPanner
	runner.check(lpf != null and absf(lpf.cutoff_hz - 800.0) < 1e-3, "Outside: LPF 800 Hz")
	runner.check(pan != null and absf(pan.pan + 0.3) < 1e-4, "Outside: pan -0.3")


func test_slider_law_default_is_unity() -> void:
	runner.check(absf(OdAudio.slider_db(1.0)) < 1e-6, "the default slider position is 0 dB")
	runner.check(OdAudio.slider_db(0.0) <= OdAudio.OFF_DB, "the bottom of the slider is silence")
	runner.check(absf(OdAudio.slider_db(0.5) - linear_to_db(0.5)) < 1e-4, "linear_to_db(slider / default)")
	var a := _audio()
	a.set_volume("music", 1.0)
	a.set_volume("sfx", 1.0)
	await _frames(3)
	runner.check(absf(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music"))) < 0.01, "music at the default: 0 dB")
	runner.check(absf(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX-Frequent"))) < 0.01, "sfx at the default: 0 dB")
	a.set_volume("music", 0.6)
	runner.check(absf(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")) - linear_to_db(0.6)) < 0.01, "60% is -4.4 dB")
	a.set_volume("music", 1.0)
	await _release()


# ------------------------------------------------------------------ the first tap and the walk

func test_nothing_plays_before_the_first_tap() -> void:
	var a := _audio()
	a.set_evolutions(0)
	a.start_music()
	# (offlineCollect left this list in v1.3: returnAway is a first sound, see test_first_sounds_*)
	for n: String in ["uiClick", "buy", "goldenSpawn", "storyCard", "milestone", "courtSummons", "chatBrawl", "suspicionHot"]:
		a.event(n)
	a.event("babble", "אין כלום!")
	a.event("chatPing", "bengvir")
	await _frames(3)
	runner.check(a.active_voices() == 0 and a.recent_files().is_empty(), "no sound before the first tap")
	runner.check(not a.is_music_playing(), "no music before the first tap")
	runner.check(not a.first_tap_done(), "the gate is still closed")
	await _release()


func test_first_tap_plays_the_motif_then_the_music_at_bar_one() -> void:
	var a := _audio()
	a.set_evolutions(0)
	a.event("tap")
	runner.check(_last(a) == "stinger_motif_D.res", "the first tap plays the motif in D, got %s" % _last(a))
	runner.check(a.active_voices("tap") == 0, "instead of the tap")
	var e := OdAudio.stinger_entry(_man, "motif", "D")
	var want := float(e["musicalSamples"]) / float(e["rate"]) * 1000.0
	runner.check(absf(a.music_starts_in_ms() - want) < 20.0, "the music waits for the motif's resolution (%.0f ms), got %.0f" % [want, a.music_starts_in_ms()])
	a.start_music()
	runner.check(not a.is_music_playing(), "start_music does not cut the motif short")
	await _frames(3)
	runner.check(a.duck_db("voice") > -0.5, "the motif ducks no voice: nothing of Dubi's sits under it (O-A3)")
	runner.check(a.dubi_waits_ms() > 0.0, "Dubi waits for the motif (O-A3)")
	a.debug_skip_wait()
	await _frames(2)
	runner.check(a.is_music_playing() and a.bar() == 1 and a.loop_index() == 1, "the music starts at bar 1 of loop 1")
	runner.check(a.track_name().begins_with("balfour:L0"), "Balfour, L0 on, got %s" % a.track_name())
	await _release()


func test_tap_walk_is_strict_and_wraps() -> void:
	# v1.5: the manifest's tap plays HaTikva (test_tap_plays_hatikva_*); the walk stays the fallback rule
	var steps := 8
	var s := -1
	var t := -1e12
	var got: Array[String] = []
	for i in 10:
		s = OdAudio.tap_streak(s, t, 100.0 * i)
		t = 100.0 * i
		got.append(OdAudio.tap_pitch(s, steps))
	runner.check(got == ["s0", "s1", "s2", "s3", "s4", "s5", "s6", "s7", "s0", "s1"], "walk up and wrap, got %s" % str(got))
	runner.check(OdAudio.tap_streak(5, 0.0, 400.0) == 0, "400 ms without a tap resets the walk")
	runner.check(OdAudio.tap_streak(5, 0.0, 399.0) == 6, "under 400 ms it climbs")
	runner.check(OdAudio.tap_variant(0) == "d25" and OdAudio.tap_variant(1) == "d12" and OdAudio.tap_variant(2) == "d25", "d25 / d12 alternate")


func test_tap_plays_hatikva_one_note_per_tap() -> void:
	var mel := OdAudio.tap_melody(_man)
	var ph := OdAudio.tap_phrases(_man)
	runner.check(mel.size() == 56 and ph == [0, 22, 38], "the manifest carries HaTikva in three 4-bar phrases, got %d notes %s" % [mel.size(), str(ph)])
	var iv: Array[int] = []
	for i in 10:
		iv.append(int(String(mel[i + 1]).substr(1)) - int(String(mel[i]).substr(1)))
	runner.check(iv == [2, 1, 2, 2, 0, 1, -1, 1, 4, -5], "it opens with the anthem's first two bars, got %s" % str(iv))
	# pure: a streak opens the next phrase, then walks on and wraps
	runner.check(OdAudio.melody_step(0, -1, -1, 56, ph) == Vector2i(0, 0), "the first streak opens phrase 0")
	runner.check(OdAudio.melody_step(1, 0, 0, 56, ph) == Vector2i(0, 1), "the streak walks on")
	runner.check(OdAudio.melody_step(5, 2, 55, 56, ph) == Vector2i(2, 0), "and wraps at the end of the melody")
	runner.check(OdAudio.melody_step(0, 0, 7, 56, ph) == Vector2i(1, 22), "after a pause the next streak opens the next phrase")
	runner.check(OdAudio.melody_step(0, 2, 40, 56, ph) == Vector2i(0, 0), "and the phrases rotate")
	var a := _audio()
	a.set_evolutions(0)
	a.event("tap")   # the motif
	var files: Array[String] = []
	for i in 3:
		a.event("tap")
		files.append(_last(a))
	runner.check(files == ["tap_D_%s_bell.res" % mel[0], "tap_D_%s_bell.res" % mel[1], "tap_D_%s_bell.res" % mel[2]],
		"taps play HaTikva in D, got %s" % str(files))
	a._clock += OdAudio.TAP_STREAK_GAP_MS + 100.0
	a.event("tap")
	runner.check(_last(a) == "tap_D_%s_bell.res" % mel[22], "a pause, then the next phrase (עוד לא אבדה), got %s" % _last(a))
	a._clock += OdAudio.TAP_STREAK_GAP_MS + 100.0
	a.event("tap")
	runner.check(_last(a) == "tap_D_%s_bell.res" % mel[38], "then the third (להיות עם חופשי), got %s" % _last(a))
	a._clock += OdAudio.TAP_STREAK_GAP_MS + 100.0
	a.event("tap")
	runner.check(_last(a) == "tap_D_%s_bell.res" % mel[0], "then back to the first phrase, got %s" % _last(a))
	for i in 30:
		a.event("tap")
	runner.check(a.active_voices("tap") <= 6, "poly 6, steal oldest: got %d" % a.active_voices("tap"))
	a.event("electionConfirm", 1)
	a._clock += OdAudio.TAP_STREAK_GAP_MS + 100.0
	a.event("tap")
	runner.check(_last(a).ends_with("_%s_bell.res" % mel[0]), "a new round starts at the first phrase, got %s" % _last(a))
	await _release()


func test_crit_plays_tap_then_the_rabbit_on_its_frame() -> void:
	var a := _audio()
	a.event("tap")
	a.event("tapCrit")
	runner.check(_last(a) == "tap_D_%s_bell.res" % OdAudio.tap_melody(_man)[0], "a crit's f0 plays the tap (the melody never skips), got %s" % _last(a))
	runner.check(a.active_voices("rabbitCrit") == 0, "the rabbit waits for its frame")
	await (runner as SceneTree).create_timer(0.32).timeout
	runner.check(a.active_voices("rabbitCrit") == 1 and _last(a) == "rabbitCrit_D_s120.res", "rabbitCrit at +250 ms, got %s" % _last(a))
	await (runner as SceneTree).create_timer(0.7).timeout
	a.event("tapCrit")
	a.event("rabbit")   # the strip's rabbit frame, reported by the engine
	runner.check(_last(a) == "rabbitCrit_D_s150.res", "event(rabbit) plays it at once, round-robin s150, got %s" % _last(a))
	await _release()


# ------------------------------------------------------------------ music

func test_layers_follow_sources_taps_and_the_bar_line() -> void:
	var a: Node = await _playing()
	var bar_s := OdAudio.bar_seconds(_man, "balfour")
	runner.check(a.layer_target("L1") == 0.0, "no source yet: L1 off")
	runner.check(a.layer_target("L2") == OdAudio.L2_UNDER_BELL, "tapped under 3 s ago: L2 on, 6 dB under the bell (v1.6)")
	a.event("buy")
	runner.check(a.layer_target("L1") == 0.0, "L1 waits for the next bar line")
	a.debug_seek(bar_s + 0.01)
	await _frames(2)
	runner.check(a.bar() == 2 and a.layer_target("L1") == 1.0, "bar 2: L1 on (ramps over the bar)")
	runner.check(a.layer_gain("L1") < 0.5, "the ramp takes a bar, not a frame: %.2f" % a.layer_gain("L1"))
	await (runner as SceneTree).create_timer(3.1).timeout   # no tap for 3 s
	a.debug_seek(3.0 * bar_s + 0.01)
	await _frames(2)
	runner.check(a.layer_target("L2") == 0.0, "3 s without a tap: L2 off at the bar line")
	await _release()


func test_anti_fatigue_cycle() -> void:
	runner.check(OdAudio.af_muted(_man, 1, 17).is_empty() and OdAudio.af_muted(_man, 3, 12).is_empty(), "loops 1 and 3 are full")
	runner.check(OdAudio.af_muted(_man, 2, 17) == ["L2"] and OdAudio.af_muted(_man, 2, 24) == ["L2"], "loop 2: L2 muted in bars 17-24")
	runner.check(OdAudio.af_muted(_man, 2, 25).is_empty(), "loop 2 bar 25 is back")
	var m4 := OdAudio.af_muted(_man, 4, 9)
	runner.check(m4.has("L1") and m4.has("L2") and OdAudio.af_muted(_man, 4, 17).is_empty(), "loop 4: L1 + L2 muted in bars 9-16")
	runner.check(OdAudio.af_muted(_man, 6, 17) == ["L2"], "the cycle repeats every 4 loops")
	runner.check(OdAudio.af_off_during(_man, "L2", 2, 16), "the fade out starts on the bar line before the muted bars")
	runner.check(not OdAudio.af_off_during(_man, "L2", 2, 25), "the fade back in is a normal bar-line layer-on")
	# the runtime counts loops and applies it
	var a: Node = await _playing()
	a.set_sources_owned(3)
	var bar_s := OdAudio.bar_seconds(_man, "balfour")
	var loop_s := OdAudio.loop_seconds(_man, "balfour")
	a.debug_seek(loop_s - 0.5)
	await _frames(2)
	a.debug_seek(loop_s + 15.0 * bar_s + 0.01)   # loop 2, bar 16
	a.event("tap")
	await _frames(2)
	runner.check(a.loop_index() == 2 and a.bar() == 16, "loop 2 bar 16, got loop %d bar %d" % [a.loop_index(), a.bar()])
	runner.check(a.layer_target("L2") == 0.0 and a.layer_target("L1") == 1.0, "loop 2: L2 fades out ahead of bar 17, L1 stays")
	await _release()


func test_era_switch_crossfades_on_the_bar_line() -> void:
	var a: Node = await _playing()
	var bar_s := OdAudio.bar_seconds(_man, "balfour")
	a.set_evolutions(1)
	runner.check(a.era() == "knesset", "one election: the Knesset")
	runner.check(a.track_name().begins_with("balfour") and a.key() == "D", "still Balfour until the bar line")
	a.debug_seek(4.0 * bar_s + 0.01)
	await _frames(2)
	runner.check(a.track_name().begins_with("knesset") and a.key() == "E", "the Knesset (E) from bar 5, got %s" % a.track_name())
	runner.check(a.bar() == 5 and a.loop_index() == 1, "onto the same bar, loop counter reset: bar %d loop %d" % [a.bar(), a.loop_index()])
	a.event("tap")
	runner.check(_last(a).begins_with("tap_E_"), "the taps follow the key, got %s" % _last(a))
	var want := {0: "balfour", 1: "knesset", 2: "knesset", 3: "courthouse", 5: "washington", 9: "washington"}
	for n: int in want:
		runner.check(a.era_for(n) == want[n], "era_for(%d) is %s" % [n, want[n]])
	await _release()


func test_court_day() -> void:
	var a: Node = await _playing()
	var bar_s := OdAudio.bar_seconds(_man, "balfour")
	a.event("courtSummons")
	runner.check(a.court_active() and a.active_voices("gavel") == 1, "the summons plays the gavel")
	var n: int = a.recent_files().size()
	a.event("courtStart")
	runner.check(a.recent_files().size() == n, "testimony after a summons is silent")
	a.debug_seek(2.0 * bar_s + 0.01)
	await _frames(2)
	runner.check(a.track_name().begins_with("courthouse") and a.key() == "G", "court day: the Courthouse in G, got %s" % a.track_name())
	runner.check(a.active_voices("courtIn") == 1, "courtIn on the bar line")
	a.event("tap")
	runner.check(a.layer_target("L2") == 0.0, "L2 is forced off on court day")
	runner.check(_last(a).begins_with("tap_G_"), "taps use the G files, got %s" % _last(a))
	a.event("courtEnd", "postponed")
	runner.check(a.active_voices("gavelWeak") == 1 and not a.court_active(), "a postponement: gavelWeak alone, then back")
	a.debug_seek(4.0 * OdAudio.bar_seconds(_man, "courthouse") + 0.01)
	await _frames(2)
	runner.check(a.track_name().begins_with("balfour") and a.key() == "D", "back to Balfour at the bar line, got %s" % a.track_name())
	runner.check(_last(a) == "courtOut_D.res", "courtOut in the key returned to, got %s" % _last(a))
	await _release()


func test_election_fanfare_on_the_confirm_frame() -> void:
	var a: Node = await _playing()
	var got: Array[String] = []
	a.marker.connect(func(cue: String, nm: String) -> void: got.append(cue + ":" + nm))
	a.event("evolveConfirm")
	runner.check(_last(a) == "stinger_fanfare_E_t0.res", "round 1: the 0-tag fanfare in the incoming key (E), got %s" % _last(a))
	runner.check(a.fanfare_clock_ms() >= 0.0 and a.fanfare_clock_ms() < 20.0, "the fanfare clock starts on the confirm frame")
	var e := OdAudio.stinger_entry(_man, "fanfare", "E", "0")
	var want := float(e["musicalSamples"]) / float(e["rate"]) * 1000.0
	runner.check(absf(a.music_starts_in_ms() - want) < 20.0, "the Knesset starts after exactly musicalSamples (%.0f ms)" % want)
	runner.check(absf(float(a.fanfare_markers()["rollEnd"]) - float(e["markers"]["rollEnd"])) < 1e-6, "markers from the manifest")
	await (runner as SceneTree).create_timer(0.1).timeout
	runner.check(not a.is_music_playing(), "the bed stopped (30 ms)")
	a.set_evolutions(1)   # the seam
	await (runner as SceneTree).create_timer(float(e["markers"]["rollEnd"]) + 0.05).timeout
	runner.check(got.has("fanfare:rollEnd"), "rollEnd is emitted, got %s" % str(got))
	a.debug_skip_wait()
	await _frames(2)
	runner.check(a.is_music_playing() and a.track_name().begins_with("knesset") and a.bar() == 1, "the Knesset at bar 1, got %s" % a.track_name())
	a.event("electionConfirm", 3)
	runner.check(_last(a).ends_with("_t2.res"), "the 3rd election has 2 tags, got %s" % _last(a))
	runner.check((a.fanfare_markers()["tagOnsets"] as Array).size() == 2, "and 2 tag onsets")
	runner.check(OdAudio.fanfare_tags(1) == 0 and OdAudio.fanfare_tags(9) == 4, "tags = min(n - 1, 4)")
	await _release()


func test_music_ducks_deepest_wins() -> void:
	var a: Node = await _playing()
	a.event("goldenCatch")   # SFX-Critical: -4 dB
	await _frames(12)
	var d4: float = a.duck_db("music")
	runner.check(d4 < -2.0 and d4 >= -4.01, "a catch ducks the music toward -4 dB, got %.2f" % d4)
	a.event("dubiSquawk", "up")   # Voice: -6 dB
	await _frames(12)
	runner.check(a.duck_db("music") < -4.5 and a.duck_db("music") >= -6.01, "the deepest duck wins, got %.2f" % a.duck_db("music"))
	await (runner as SceneTree).create_timer(1.6).timeout
	runner.check(a.duck_db("music") > -0.5, "and releases, got %.2f" % a.duck_db("music"))
	for i in 5:
		a.event("tap")
		a.event("uiClick")
	await _frames(6)
	runner.check(a.duck_db("music") > -0.5, "taps and UI duck nothing")
	await _release()


# ------------------------------------------------------------------ chat and Dubi

func test_chat_pings_rate_limit_and_wait_for_dubi() -> void:
	runner.check(OdAudio.ping_variant(_man, "bengvir") == "benGvir" and OdAudio.ping_variant(_man, "ben-gvir") == "benGvir", "partner ids map onto the ping variants")
	runner.check(OdAudio.ping_variant(_man, "bennett") == "default", "anyone else pings the default")
	var a := _audio()
	a.event("tap")
	a.debug_skip_wait()   # past the motif, which holds Dubi (O-A3)
	a.event("chatPing", "smotrich")
	runner.check(_last(a) == "chatPing_D_smotrich.res", "the first ping plays at once, got %s" % _last(a))
	a.event("chatPing", "deri")
	a.event("chatPing", "gafni")
	runner.check(a.queued_pings() == 2, "pings inside 700 ms wait")
	await (runner as SceneTree).create_timer(0.8).timeout
	runner.check(_last(a) == "chatPing_D_burst.res" and a.queued_pings() == 0, "and coalesce into one burst, got %s" % _last(a))
	await (runner as SceneTree).create_timer(0.8).timeout
	a.event("babble", "אין כלום! אין כלום!")
	await _frames(2)
	a.event("chatPing", "levin")
	runner.check(a.queued_pings() == 1, "never during Dubi")
	var t0 := Time.get_ticks_msec()
	while a.queued_pings() > 0 and Time.get_ticks_msec() - t0 < 3000:
		await (runner as SceneTree).process_frame
	runner.check(not a.is_babbling() and _last(a) == "chatPing_D_levin.res", "it plays after Dubi stops, got %s" % _last(a))
	await _release()


func test_babble_plans() -> void:
	var canned := OdAudio.babble_plan(_man, "אין כלום! אין כלום!")
	var blips: Array = canned["blips"]
	runner.check(bool(canned["canned"]) and blips.size() == 6, "a doubled canned line repeats its 3-blip contour, got %d" % blips.size())
	var contour: Array = _man["babbleContours"]["אין כלום!"]
	runner.check(String(blips[0]["bank"]) == "%s_%d" % [contour[0][0], int(contour[0][1])]
		and String(blips[5]["bank"]) == "%s_%d" % [contour[2][0], int(contour[2][1])], "the canned contour from the manifest")
	runner.check(absf(float(blips[3]["t"]) - (3.0 / 8.0 + 0.15)) < 1e-6, "with a 150 ms gap between the two")
	var h := "ביבי שלף עוד מזוודה מהכובע, והכנסת התפזרה שוב!"
	var p1 := OdAudio.babble_plan(_man, h)
	var p2 := OdAudio.babble_plan(_man, h)
	var hb: Array = p1["blips"]
	runner.check(str(p1) == str(p2), "deterministic")
	runner.check(not hb.is_empty() and absf(float(hb[1]["t"]) - 0.125) < 1e-6, "8 blips a second")
	runner.check(float(p1["length"]) <= OdAudio.BABBLE_CAP_S + 1e-6, "capped at 1.6 s, got %.3f" % float(p1["length"]))
	var ok := true
	var bank := OdAudio.babble_bank(_man)
	for b: Dictionary in hb:
		ok = ok and bank.has(String(b["bank"]))
	runner.check(ok, "every blip is in the era bank")
	runner.check(bank.size() == OdAudio.cue_pitches(_man, "dubiBlip").size() and bank.size() >= 2, "the bank is the rendered dubiBlip pitches")
	var semis := func(k: String) -> float:
		return float(k.split("_")[1].to_int()) * 12.0 + float(_man["degrees"][k.split("_")[0]])
	var rising := true
	for i in range(1, bank.size()):
		rising = rising and semis.call(bank[i]) > semis.call(bank[i - 1])
	runner.check(rising, "ordered low to high by the manifest's degrees: %s" % str(bank))
	var short_ := OdAudio.babble_plan(_man, "שלום!")
	var sb: Array = short_["blips"]
	var plain: Array = OdAudio.babble_plan(_man, "שלום")["blips"]
	runner.check(sb.size() == 2 and (bank.find(String(sb[1]["bank"])) == bank.find(String(plain[1]["bank"])) + 1
		or bank.find(String(plain[1]["bank"])) == bank.size() - 1), "a final ! steps one degree up")
	runner.check((OdAudio.babble_plan(_man, "  ")["blips"] as Array).is_empty(), "an empty line says nothing")


## O-A3 (Audio Director, accepted): tap 1 plays the motif, the anthem's statement; Dubi's first
## line ("אין כלום!"), sent by the controller right after that tap, starts only when the motif's
## musicalSeconds have elapsed (2.33 s in D), never under it.
func test_first_tap_squawk_waits_for_the_motif() -> void:
	var a := _audio()
	a.set_evolutions(0)
	a.event("tap")                                   # tap 1: the motif
	var t_tap: float = a.get("_clock")
	a.event("babble", "אין כלום! אין כלום!")          # main.gd: right after tap 1
	var e := OdAudio.stinger_entry(_man, "motif", "D")
	var want := float(e["musicalSeconds"]) * 1000.0
	runner.check(absf(want - 2327.6) < 1.0, "the D motif's musicalSeconds is 2.33 s, got %.1f ms" % want)
	runner.check(a.is_babbling(), "the first line is queued, not dropped")
	a.event("headline", "מבזק: הקואליציה יציבה")      # a milestone headline inside the motif
	await _frames(3)
	var dubi := func() -> bool: return a.recent_files().any(func(f: String) -> bool: return f.begins_with("dubi"))
	runner.check(not dubi.call(), "no squawk or blip under the motif, got %s" % str(a.recent_files()))
	runner.check(a.active_voices("dubiBlip") == 0, "no blip under the motif")
	var at := -1.0
	var t0 := Time.get_ticks_msec()
	while at < 0.0 and Time.get_ticks_msec() - t0 < want + 2000.0:
		await (runner as SceneTree).process_frame
		if dubi.call():
			at = float(a.get("_clock"))
	runner.check(at >= 0.0, "Dubi speaks after the motif")
	var first: String = a.recent_files().filter(func(f: String) -> bool: return f.begins_with("dubi"))[0] if at >= 0.0 else ""
	runner.check(first == "dubiSquawk_D_down.res", "the squawk comes first, got %s" % first)
	runner.check(at - t_tap >= want - 0.5 and at - t_tap < want + 120.0,
		"the squawk starts at musicalSeconds (%.0f ms after the tap), got %.0f" % [want, at - t_tap])
	a.stop_babble()
	await _release()


func test_dubi_speaks_and_headlines_are_rationed() -> void:
	var a := _audio()
	a.event("tap")
	a.debug_skip_wait()   # past the motif (O-A3)
	var beaks := [0]
	a.dubi_blip.connect(func(_b: String) -> void: beaks[0] += 1)
	a.event("headline", "מבזק: הקואליציה יציבה")
	runner.check(a.is_babbling(), "a headline starts Dubi")
	await _frames(2)
	runner.check(_last(a) == "dubiSquawk_D_up.res", "an 'up' squawk before a headline, got %s" % _last(a))
	var most := 0
	var t0 := Time.get_ticks_msec()
	while a.is_babbling() and Time.get_ticks_msec() - t0 < 2500:
		await (runner as SceneTree).process_frame
		most = maxi(most, a.active_voices("dubiBlip"))
	runner.check(beaks[0] >= 3 and most == 1, "blips drive the beak, one at a time (%d blips, %d at once)" % [beaks[0], most])
	a.event("headline", "עוד מבזק")
	runner.check(not a.is_babbling(), "at most one ticker headline per 20 s")
	a.event("babble", "ציד מכשפות!")
	await _frames(2)
	runner.check(a.is_babbling() and _last(a) == "dubiSquawk_D_down.res", "a canned line gets the 'down' squawk, got %s" % _last(a))
	a.stop_babble()
	runner.check(not a.is_babbling() and a.active_voices("dubiBlip") == 0, "stop_babble silences him")
	await _release()


# ------------------------------------------------------------------ the rest of the cue list

func test_every_controller_event_is_accepted() -> void:
	var a := _audio()
	var args := {"chatPing": "bengvir", "courtEnd": "testified", "ultimatumTick": 5, "coin": 3, "era": "knesset",
		"babble": "בכובע!", "headline": "מבזק"}
	for n: String in CONTROLLER_EVENTS:
		a.event(n, args.get(n))
	for n: String in ["nope", "", "_doc", "TAP", "fanfare"]:
		a.event(n)
		a.event(n, 42)
	a.set_music_state("frenzy")
	a.set_volume("voice", 0.5)
	await _frames(3)
	runner.check(a.active_voices() > 0, "the controller's events play sounds")
	runner.check(a.active_voices() <= AudioScript.VOICE_CAP, "inside the global voice cap")
	runner.check(a.report().contains("era"), "report answers: %s" % a.report())
	await _release()


func test_cue_variant_rules() -> void:
	var a := _audio()
	a.event("tap")
	var stamps: Array[String] = []
	for i in 5:
		a.event("stamp")
		stamps.append(_last(a))
		await (runner as SceneTree).create_timer(0.36).timeout
	runner.check(stamps.slice(0, 4).all(func(f: String) -> bool: return f == "stamp.res") and stamps[4] == "stamp_bell.res",
		"stamps are identical, the 5th rings the bell: %s" % str(stamps))
	a.event("buy")
	var b1 := _last(a)
	await (runner as SceneTree).create_timer(0.25).timeout
	a.event("buy")
	runner.check(b1 == "buy_D_d25.res" and _last(a) == "buy_D_d12.res", "buy alternates d25 / d12")
	a.event("coin", 20)
	await (runner as SceneTree).create_timer(0.5).timeout
	var coins: Array = a.recent_files().filter(func(f: String) -> bool: return f.begins_with("coin_"))
	runner.check(coins.size() == 6, "at most 6 coins per event, never scaled by the amount: %d" % coins.size())
	a.event("goldenSpawn", 1.0)
	var pan := AudioServer.get_bus_effect(AudioServer.get_bus_index("Suitcase"), 0) as AudioEffectPanner
	runner.check(absf(pan.pan - 0.4) < 1e-4 and _last(a).begins_with("suitcaseSpawn_g"), "the Suitcase pans at spawn (x 1.0 -> +0.4)")
	await _release()


func test_pink_front_is_behind_the_easter_eggs_flag() -> void:
	var a: Node = await _playing()
	var lpf := AudioServer.get_bus_effect(AudioServer.get_bus_index("Outside"), 0) as AudioEffectLowPassFilter
	a.event("pinkFront", true)
	await _frames(10)
	runner.check(absf(lpf.cutoff_hz - 800.0) < 1.0, "flag off: the window stays shut")
	var c: Dictionary = Content.data().duplicate(true)
	c["flags"]["easterEggs"] = true
	Content.replace(c)
	a.event("pinkFront", true)
	await (runner as SceneTree).create_timer(0.6).timeout
	runner.check(lpf.cutoff_hz > 900.0 and lpf.cutoff_hz < 4000.0, "flag on: the LPF sweeps up (over 2 bars), at %.0f Hz" % lpf.cutoff_hz)
	runner.check(absf(OdAudio.pink_cutoff(_man, 1.0) - 4000.0) < 1e-3 and absf(OdAudio.pink_boost_db(_man, 1.0) - 8.0) < 1e-6, "to 4 kHz, +8 dB")
	var off := OdAudio.beat_offset_ms(33000.0 + 319.0, [0, 33000, 66000, 99000], 132000.0, 31900.0)
	runner.check(absf(off - 10.0) < 0.01, "tap-to-beat measures from the nearest judge beat")
	runner.check(absf(OdAudio.beat_offset_ms(131681.0, [0, 33000, 66000, 99000], 132000.0, 31900.0) + 10.0) < 0.01, "wrapping at the loop")
	runner.check(is_finite(a.judge_tap()), "the drum line is live in Balfour")
	a.event("pinkFront", false)
	TestFixture.use_game_content()
	await _release()


func test_coalition_collapse_waits_for_the_next_tap() -> void:
	var a: Node = await _playing()
	var before: Array[String] = a.recent_files()
	a.event("coalitionCollapse")
	var after: Array[String] = a.recent_files()
	runner.check(after == before, "no stinger on a collapse (cue-spec §2.6 v1.2: the motif is never a loss sting): %s -> %s" % [str(before), str(after)])
	await (runner as SceneTree).create_timer(OdAudio.bar_seconds(_man, "balfour") * 0.5).timeout
	runner.check(a.is_music_playing(), "the fade takes a whole bar")
	await (runner as SceneTree).create_timer(OdAudio.bar_seconds(_man, "balfour") * 0.5 + 0.2).timeout
	runner.check(not a.is_music_playing(), "the music faded out over a bar, then nothing")
	a.start_music()
	runner.check(not a.is_music_playing(), "and stays out")
	a.event("tap")
	await _frames(2)
	runner.check(a.is_music_playing() and a.bar() == 1, "the next tap restarts it at bar 1")
	await _release()


func test_general_trophies_play_milestone_the_album_keeps_trophy() -> void:
	var a: Node = await _playing()
	a.event("achievement")
	runner.check(_last(a).begins_with("stinger_milestone"), "a general trophy plays the milestone stinger, got %s" % _last(a))
	await (runner as SceneTree).create_timer(0.3).timeout
	a.event("trophy")
	runner.check(_last(a).begins_with("stinger_trophy"), "the album trophy keeps its own stinger, got %s" % _last(a))
	await _release()


func test_pause_and_music_toggle() -> void:
	var a: Node = await _playing()
	a.set_paused(true)
	var c0: float = a._clock
	await _frames(5)
	runner.check(a._clock == c0, "the audio clock stops while paused")
	a.set_paused(false)
	a.set_music_enabled(false)
	await (runner as SceneTree).create_timer(0.15).timeout
	runner.check(not a.is_music_playing(), "music off stops the song after the toggle ramp")
	a.set_music_enabled(true)
	runner.check(a.is_music_playing() and a.bar() == 1, "music on restarts it at bar 1")
	runner.check(a.report().contains("music on"), "report: %s" % a.report())
	await _release()


# ------------------------------------------------------------------ v1.3: the cue table (leader select,
# the session-2 views; audio/od/cue-spec.md §4.1)

const LEADER_KEYS := ["D", "E", "F", "G"]


## Every event name the game's scripts send to the Audio (audio_event("x") / _audio("x") /
## call("audio_event", "x"), and both sides of a `"a" if c else "b"` argument), read from the sources.
func _sent_events() -> Array[String]:
	var out: Array[String] = []
	var re := RegEx.create_from_string("(?:audio_event|_audio)\\(\\s*\"([A-Za-z]+)\"|call\\(\\s*\"audio_event\"\\s*,\\s*\"([A-Za-z]+)\"|\\(\\s*\"([A-Za-z]+)\" if [^)]* else \"([A-Za-z]+)\"")
	var stack: Array[String] = ["res://scripts"]
	while not stack.is_empty():
		var d: String = stack.pop_back()
		var da := DirAccess.open(d)
		if da == null:
			continue
		for sub in da.get_directories():
			stack.append(d.path_join(sub))
		if d.ends_with("autoload") or d.ends_with("audio"):
			continue
		for f in da.get_files():
			if not f.ends_with(".gd"):
				continue
			for line in FileAccess.get_file_as_string(d.path_join(f)).split("\n"):
				if not (line.contains("audio_event") or line.contains("_audio(")):
					continue
				for m in re.search_all(line):
					for g in [1, 2, 3, 4]:
						var s := m.get_string(g)
						if s != "" and not out.has(s):
							out.append(s)
	out.sort()
	return out


func test_every_event_the_game_sends_has_a_cue_or_is_silent_on_purpose() -> void:
	var a := _audio()
	var sent := _sent_events()
	runner.check(sent.size() >= 40, "the scan finds the game's audio events (%d)" % sent.size())
	for n: String in ["chatBrawl", "suspicionHot", "gameReset", "spinEnd", "cottagePixel", "stamp", "offlineCollect", "tapCrit", "slipStamp"]:
		runner.check(sent.has(n), "the scan sees %s" % n)
	var gaps: Array[String] = []
	for n: String in sent + CONTROLLER_EVENTS:
		if a.route(n) == "unknown" and not gaps.has(n):
			gaps.append(n)
	runner.check(gaps.is_empty(), "every sent event is handled, plays a cue or stinger, or is SILENT on purpose; gaps: %s" % str(gaps))
	for n: String in AudioScript.SILENT:
		runner.check(not _man["cues"].has(n) and not AudioScript.EVENT_CUE.has(n), "%s is silent on purpose, not also a cue" % n)
	runner.check(a.route("nope") == "unknown" and a.route("spinEnd") == "silent" and a.route("offlineCollect") == "cue:returnAway",
		"route() tells the three apart")
	await _release()


func test_every_referenced_cue_id_exists() -> void:
	var cues: Dictionary = _man["cues"]
	for ev: String in AudioScript.EVENT_CUE:
		var id: String = AudioScript.EVENT_CUE[ev]
		runner.check(cues.has(id), "EVENT_CUE %s -> %s exists" % [ev, id])
	for ev: String in AudioScript.EVENT_STINGER:
		runner.check(_man["stingers"].has(AudioScript.EVENT_STINGER[ev]), "EVENT_STINGER %s exists" % ev)
	for id: String in AudioScript.RANDOM_VARIANT + AudioScript.ALTERNATE.keys() + AudioScript.DUBI_CUES:
		runner.check(cues.has(id) or _man["stingers"].has(id), "variant rule / Dubi cue %s exists" % id)
	var crits: Dictionary = _man.get("crits", {})
	runner.check(crits.has("rabbit") and crits.has("whoosh") and crits.has("shout") and crits.has("no") and crits.has("land"),
		"the crits table keys every react event of spec §9.5")
	for ev: String in crits:
		if ev.begins_with("_"):
			continue
		var m: Dictionary = crits[ev]
		runner.check(cues.has(m["cue"]), "crits.%s -> %s exists" % [ev, m["cue"]])
		for k: String in LEADER_KEYS:
			var vs := OdAudio.cue_variants(_man, m["cue"], k)
			runner.check((m["variant"] == "roundRobin" and not vs.is_empty()) or vs.has(m["variant"]),
				"crits.%s: %s has %s in %s (%s)" % [ev, m["cue"], m["variant"], k, str(vs)])
	for id: String in ["leaderPick", "critReact", "decline", "merge", "suspicionHot"]:
		runner.check(cues.has(id), "v1.3 cue %s is in the manifest" % id)
		for k: String in LEADER_KEYS:
			runner.check(not OdAudio.cue_variants(_man, id, k).is_empty(), "%s renders in %s" % [id, k])
	runner.check(OdAudio.cue_variants(_man, "chatPing", "D").has("brawl"), "chatPing has the brawl variant")


func test_leader_pick_is_a_safe_first_sound() -> void:
	var c: Dictionary = _man["cues"].get("leaderPick", {})
	runner.check(not c.is_empty(), "the cue table registers exactly 'leaderPick'")
	runner.check(float(c.get("lengthMs", 9999)) <= 1000.0, "leaderPick <= 1 s, got %.0f ms" % float(c.get("lengthMs", 9999)))
	runner.check(bool(c.get("firstSound", false)) and OdAudio.is_first_sound(_man, "leaderPick"), "flagged as a first sound")
	runner.check(c.get("bus") == "SFX-Critical" and int(c.get("priority", 0)) == 5, "SFX-Critical, never stolen")
	runner.check(float(c.get("burstMax", 0.0)) <= -14.5,
		"a first sound is no louder than the motif's -15 LUFS statement: burst %.2f" % float(c.get("burstMax", 0.0)))
	var a := _audio()
	for k: String in LEADER_KEYS:
		var f := OdAudio.cue_file(_man, "leaderPick", k)
		runner.check(f != "" and a._streams.has(f) and a._streams[f] != null, "leaderPick_%s is warmed before any gesture" % k)
	a.set_evolutions(0)
	a.event("uiClick")
	runner.check(a.recent_files().is_empty(), "the picker's browsing is silent (the first-tap gate)")
	a.event("leaderPick", "bennett")
	runner.check(_last(a) == "leaderPick_D.res", "the pick is the first sound, in the boot key D, got %s" % _last(a))
	runner.check(a.leader_id() == "bennett", "the pick sets the leader")
	runner.check(not a.first_tap_done() and not a.is_music_playing(), "the pick does not open the gate or start the music")
	a.event("tap")
	runner.check(_last(a) == "stinger_motif_D.res", "the first tap still plays the motif, got %s" % _last(a))
	await _release()
	# a locked web context (iOS before touchend): the pick is held and plays on the unlock
	var b := _audio()
	b._web = true
	b._web_running = false
	b.event("leaderPick")
	runner.check(b.active_voices("leaderPick") == 0, "locked: held, not dropped")
	await _frames(3)   # the headless bridge answers "running": the unlock
	runner.check(b.recent_files().has("leaderPick_D.res"), "played on the unlock: %s" % str(b.recent_files()))
	await _release()


func test_first_sounds_play_before_the_first_tap() -> void:
	var a := _audio()
	a.set_evolutions(0)
	a.event("offlineCollect")
	runner.check(_last(a) == "returnAway_D.res", "the return card's collect is heard after a reload, got %s" % _last(a))
	runner.check(not a.first_tap_done(), "and the gate stays closed for everything else")
	await _release()


func test_crit_mapping_for_all_eight_leaders() -> void:
	var ids: Array[String] = []
	for L: Variant in Leaders.list():
		ids.append(str((L as Dictionary)["id"]))
	runner.check(ids.size() == 8, "8 leaders in the content, got %s" % str(ids))
	var a := _audio()
	var want := {"bibi": ["rabbit", "rabbitCrit"], "bennett": ["whoosh", "critReact"], "bengvir": ["shout", "critReact"],
		"liberman": ["no", "critReact"], "eisenkot": ["land", "critReact"], "smotrich": ["shout", "critReact"],
		"deri": ["land", "critReact"], "golan": ["land", "critReact"]}
	for id in ids:
		var c: Dictionary = a.crit_for(id)
		runner.check(want.has(id) and c["event"] == want[id][0] and c["cue"] == want[id][1],
			"%s: crit %s, got %s" % [id, str(want.get(id, [])), str(c)])
		var kt: Dictionary = Leaders.kit(id).get("tap", {})
		if kt.has("critEvent"):
			runner.check(c["event"] == kt["critEvent"], "%s: keyed by the kit's react event" % id)
		for k: String in LEADER_KEYS:
			var v: String = "s120" if c["variant"] == "roundRobin" else c["variant"]
			runner.check(OdAudio.cue_file(_man, c["cue"], k, "_", v) == "%s_%s_%s.res" % [c["cue"], k, v], "%s: a file in %s" % [id, k])
		runner.check(float(c["delayMs"]) >= 0.0 and float(c["delayMs"]) < 600.0, "%s: the event frame %.0f ms after the tap" % [id, float(c["delayMs"])])
	runner.check(absf(float(a.crit_for("bibi")["delayMs"]) - 250.0) < 0.5, "Bibi's rabbit stays at +250 ms")
	# the runtime: Bennett's crit plays critReact:whoosh on the flip's frame (f3 at 12 fps)
	a.set_leader("bennett")
	a.event("tap")
	a.event("tapCrit")
	runner.check(a.active_voices("critReact") == 0, "the crit waits for the react's frame")
	a.event("land")
	runner.check(a.active_voices("critReact") == 0, "another event name does not fire Bennett's crit")
	a.event("heroEvent", "whoosh")
	runner.check(_last(a) == "critReact_D_whoosh.res", "the whoosh frame fires it, got %s" % _last(a))
	await (runner as SceneTree).create_timer(0.7).timeout
	a.set_leader("deri")
	a.event("tapCrit")
	await (runner as SceneTree).create_timer(0.45).timeout
	runner.check(_last(a) == "critReact_D_land.res", "Deri's land on its own timer (+357 ms), got %s" % _last(a))
	await _release()


func test_every_leader_squawk_has_a_canned_contour() -> void:
	var a := _audio()
	for L: Variant in Leaders.list():
		var id := str((L as Dictionary)["id"])
		for kind: String in ["firsttap", "buy", "elect", "miss"]:
			var t: String = a.squawk_text(id, kind)
			runner.check(t != "", "%s has a %s squawk" % [id, kind])
			var plan := OdAudio.babble_plan(_man, t)
			runner.check(bool(plan["canned"]), "%s %s '%s' plays a canned contour (the parrot repeats)" % [id, kind, t])
	runner.check(a.squawk_text("bibi", "firsttap") == "אין כלום! אין כלום!", "Bibi's first squawk is the shipped one")
	a.set_leader("liberman")
	a.event("tap")
	a.debug_skip_wait()
	a.event("squawk", "firsttap")
	await (runner as SceneTree).create_timer(0.3).timeout
	runner.check(a.recent_files().any(func(f: String) -> bool: return f.begins_with("dubiSquawk")), "event(squawk) speaks the leader's line: %s" % str(a.recent_files()))
	await _release()


func test_press_day_opens_with_the_cameras() -> void:
	var a: Node = await _playing()
	a.set_leader("smotrich")
	a.event("courtSummons")
	runner.check(a.court_active() and a.active_voices("gavel") == 0 and _last(a).begins_with("shutter_"),
		"the press skin: the shutter, not the gavel, got %s" % _last(a))
	a.event("courtEnd", "testified")
	await (runner as SceneTree).create_timer(0.8).timeout
	a.event("courtSummons", "court")
	runner.check(a.active_voices("gavel") == 1, "arg 'court' keeps the gavel")
	await _release()


func test_brawl_ping_and_game_reset() -> void:
	var a: Node = await _playing()
	await (runner as SceneTree).create_timer(0.75).timeout
	a.event("chatBrawl")
	runner.check(_last(a) == "chatPing_D_brawl.res", "the brawl's own ping, got %s" % _last(a))
	a.event("gameReset")
	runner.check(not a.first_tap_done(), "a wiped game closes the gate")
	a.event("uiClick")
	runner.check(_last(a) == "chatPing_D_brawl.res", "and the gate holds after the wipe")
	await (runner as SceneTree).create_timer(OdAudio.bar_seconds(_man, "balfour") + 0.2).timeout
	runner.check(not a.is_music_playing(), "the music faded out over a bar")
	a.event("leaderPick", "golan")
	a.event("tap")
	runner.check(_last(a) == "stinger_motif_D.res", "the next first tap plays the motif again, got %s" % _last(a))
	await _release()


# ------------------------------------------------------------------ v1.4: the slip stamp (animator wave B)

func test_slip_stamp_is_a_short_ui_thunk_at_the_stamp_family_level() -> void:
	var c: Dictionary = _man["cues"].get("slipStamp", {})
	runner.check(not c.is_empty(), "the cue table registers exactly 'slipStamp'")
	runner.check(c.get("bus") == "UI" and (c.get("ducks", [1]) as Array).is_empty(), "UI bus, no duck")
	runner.check(float(c.get("lengthMs", 9999)) <= 250.0, "<= 0.25 s, got %.0f ms" % float(c.get("lengthMs", 9999)))
	var stamp := float(_man["cues"]["stamp"]["burstMax"])
	var slip := float(c.get("burstMax", 0.0))
	runner.check(slip <= stamp + 0.1 and slip >= stamp - 3.0,
		"at the stamp's heard level or a little under (it repeats): slip %.2f vs stamp %.2f LUFS burst" % [slip, stamp])
	runner.check(slip < float(_man["cues"]["buy"]["burstMax"]), "under the buy it lands with")
	for k: String in LEADER_KEYS:
		runner.check(OdAudio.cue_file(_man, "slipStamp", k) == "slipStamp.res", "one unpitched file in %s" % k)
	var a := _audio()
	runner.check(a.route("slipStamp") == "cue:slipStamp", "routes to its cue, got %s" % a.route("slipStamp"))
	a.set_evolutions(0)
	a.event("slipStamp")
	runner.check(a.recent_files().is_empty(), "behind the first-tap gate like every UI cue")
	a.event("tap")
	a.event("slipStamp")
	runner.check(_last(a) == "slipStamp.res", "plays after the gate, got %s" % _last(a))
	await _release()


## shop.gd's one-line hook reaches the controller three levels up (Shop → _lower → _root → main). If that
## path ever moves, the stamp would go silent with no error, so pin it on the real scene.
func test_the_shop_hook_reaches_the_audio_host() -> void:
	var tree := runner as SceneTree
	var dir := "user://test_slipstamp_%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(dir)
	var m: Node = load("res://scenes/main.tscn").instantiate()
	m.store = SaveStore.new(dir)
	tree.root.add_child(m)
	await _frames(3)
	var shop: Node = m.get("shop")
	runner.check(shop != null and shop.get_node_or_null("../../..") == m and m.has_method("audio_event"),
		"Shop's ../../.. is main, which has audio_event")
	m.set_process(false)
	tree.root.remove_child(m)
	m.queue_free()
	var d := DirAccess.open(dir)
	if d:
		for f in d.get_files():
			d.remove(f)
	DirAccess.remove_absolute(dir)


## v1.6 (2026-10-03, Bar: "improve the SFX"): the UI's events reach their own cues, a bulk buy and a
## partner's payment sound like rewards, and the ballot booth and the wizard have sounds that play
## before the first tap (first sounds, like leaderPick).
func test_v16_routes_and_first_sounds() -> void:
	var a := _audio()
	var want := {"panelOpen": "cue:uiOpen", "evolveOpen": "cue:uiOpen", "panelClose": "cue:uiClose", "evolveClose": "cue:uiClose",
		"uiToggle": "cue:uiToggle", "buyModeCycle": "cue:uiToggle", "partnerPaid": "cue:paid", "pardonStamp": "cue:stamp",
		"slipChoose": "cue:slipChoose", "slipLocked": "cue:slipLocked", "wizardStep": "cue:wizardStep",
		"wizardDone": "cue:wizardDone", "wizardSkip": "cue:wizardSkip"}
	for ev: String in want:
		runner.check(a.route(ev) == want[ev], "%s -> %s (got %s)" % [ev, want[ev], a.route(ev)])
	runner.check(AudioScript.EVENT_CUE["buyBulk"] == "buyBig" and AudioScript.EVENT_CUE["buy"] == "buy", "a bulk buy plays buyBig")
	for id: String in ["uiOpen", "uiClose", "uiToggle", "buyBig", "paid", "slipChoose", "slipLocked", "wizardStep", "wizardDone", "wizardSkip"]:
		runner.check(_man["cues"].has(id), "v1.6 cue %s is in the manifest" % id)
		for k: String in LEADER_KEYS:
			runner.check(not OdAudio.cue_variants(_man, id, k).is_empty() or str(_man["cues"][id]["pitch"]["type"]) == "none", "%s renders in %s" % [id, k])
	for id: String in ["slipChoose", "slipLocked", "wizardStep", "wizardDone", "wizardSkip"]:
		runner.check(OdAudio.is_first_sound(_man, id), "%s plays before the first tap (the booth and the wizard come first)" % id)
	# the reward is louder than the UI around it, and the bulk buy louder than one buy
	var burst := func(id: String) -> float: return float(_man["cues"][id].get("burstMax", -99.0))
	runner.check(burst.call("buyBig") > burst.call("buy"), "buyBig is bigger than buy (%.1f vs %.1f)" % [burst.call("buyBig"), burst.call("buy")])
	runner.check(burst.call("paid") > burst.call("uiClick") and burst.call("wizardStep") < burst.call("buy"), "a payment over a click; the wizard's chime under a purchase")
