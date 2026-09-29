extends SceneTree
## Renders the music (res://data/music.json, a copy of audio/music.json) to looping stems: one per
## adaptive layer (base, evolved, frenzy) per key per era track, saved as QOA-compressed
## AudioStreamWAV resources, plus a quiet ambience bed per era and music_manifest.json. The
## effects are tools/gen_audio.gd. Run the whole pipeline with tools/audio.sh; this step alone:
##     tools/godot.sh --headless --path game -s <abs path>/tools/gen_music.gd
##
## Tracks (ADR 0002, phase 9 in ADR 0003):
## - "main" is the v1 song, the jungle era, in every key of keyOffsetByEvolutions:
##   music_<layer>_k<key>.res (unchanged since phase 4).
## - "village", "city" and "orbit" are arrangements of the same song for the later eras, built by
##   _arrange() from music.json: same 126 BPM and 32-bar form, same melody, chords and layer
##   model, new instruments and some new parts. One key each (TRACKS), to keep the music under
##   20 MB: music_<track>_<layer>_k<key>.res. The runtime plays taps in the era's key.
##
## The render follows chip.ts MusicPlayer: every channel's bar strings compile to one event per
## step (notes with their tied length, or kit hits), each event plays its instrument's layers
## through tools/lib_dsp.gd at the channel gain, and every tonal note is lifted by the key.
## The drums (a kit channel of the base layer) are mixed into the base stem, so the runtime
## plays three stems per key in one AudioStreamSynchronized and crossfades their volumes.
##
## Rate: 31,500 Hz, so one step (an 8th-note triplet at 126 BPM, 60/126/3 s) is exactly 5,000
## samples and the 384-step song exactly 1,920,000: no drift, the loop is sample-exact.
##
## Loop: notes ringing past the end of bar 32 wrap onto bar 1 (the song plays after itself, as
## v1's scheduler does). Godot 4.7.2 plays a forward loop as the samples (loop_begin,
## loop_end], so each stem carries one guard sample (a copy of sample 0) at index 1,920,000,
## loop_begin = 0 and loop_end = 1,920,000: the heard period is exactly the song.
##
## Levels: one scale per track puts its loudest stem at -1 dBFS, and the manifest's trim_db is
## what the runtime adds back, so the layers keep their balance. An era track's trim also
## carries match_db, which brings its base stem to the RMS of the jungle base stem (clamped to
## +/-6 dB), so an era change does not jump in level. The ambience beds sit AMB_UNDER_DB under
## that same RMS.
##
## Deterministic: every random stream is seeded per (track, channel, step, note, layer) and each
## resource gets a UID derived from its file name, so two runs write identical bytes.

const D := preload("lib_dsp.gd")
const SR := 31500
const OUT := "res://assets/audio/"
const PEAK := 0.891251   # -1 dBFS
const TAIL_S := 2.0      # render room past the loop end (wrapped back onto bar 1)
const LAYERS := ["base", "evolved", "frenzy"]
const MATCH_CLAMP_DB := 6.0
## era -> track. keys [] = every key of keyOffsetByEvolutions; one key otherwise (ADR 0003: the
## era arrivals climb +4, +5, then orbit floats back to the home key).
const TRACKS := [
	{"id": "main", "era": "jungle", "keys": []},
	{"id": "village", "era": "village", "keys": [4]},
	{"id": "city", "era": "city", "keys": [5]},
	{"id": "orbit", "era": "orbit", "keys": [0]},
]
const AMB_SR := 22050
const AMB_S := 16.0          # the bed loop length
const AMB_UNDER_DB := 12.0   # ambience RMS under the jungle base stem's RMS
const NAMES := ["C", "Db", "D", "Eb", "E", "F", "Gb", "G", "Ab", "A", "Bb", "B"]
const PCS := {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}


func _initialize() -> void:
	var t0 := Time.get_ticks_msec()
	D.set_rate(SR)
	var A: GDScript = load("res://scripts/autoload/audio.gd")
	var m: Dictionary = A.load_json("res://data/music.json")
	var cj: Dictionary = A.load_json("res://data/cues.json")
	var a4 := float(cj["globals"]["a4Hz"])
	var step_s := 60.0 / float(m["tempoBpm"]) / float(m["stepsPerBeat"])
	var step_n := int(roundf(step_s * SR))
	if absf(step_n - step_s * SR) > 1e-6:
		push_error("gen_music: a step is %.4f samples at %d Hz, not whole" % [step_s * SR, SR])
		quit(1)
		return
	var total := int(m["form"]["totalBars"]) * int(m["stepsPerBar"])
	var loop_n := total * step_n
	var all_keys: Array[int] = A.key_offsets(m)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))

	var tracks := {}
	var eras := {}
	var written := {}
	var total_bytes := 0
	var ref_rms := 0.0
	for T: Dictionary in TRACKS:
		var tid := String(T["id"])
		var tm: Dictionary = m if tid == "main" else _arrange(m, tid)
		var keys: Array[int] = []
		if (T["keys"] as Array).is_empty():
			keys = all_keys
		else:
			for k: Variant in T["keys"]:
				keys.append(int(k))
		var r := _render_track(tm, tid, keys, a4, step_s, step_n, total, loop_n, t0)
		var stems: Dictionary = r["stems"]
		var base_rms := D.rms(stems["base|%d" % keys[0]])
		if tid == "main":
			ref_rms = base_rms
		var match_db := 0.0 if tid == "main" else clampf(D.lin2db(ref_rms / maxf(base_rms, 1e-9)), -MATCH_CLAMP_DB, MATCH_CLAMP_DB)
		var scale := PEAK / maxf(float(r["peak"]), 1e-9)
		var files := {}
		for layer: String in LAYERS:
			files[layer] = {}
			for key in keys:
				var name := ("music_%s_k%d.res" % [layer, key]) if tid == "main" else ("music_%s_%s_k%d.res" % [tid, layer, key])
				var bytes := _save_loop(stems["%s|%d" % [layer, key]], scale, SR, loop_n, name)
				if bytes < 0:
					quit(1)
					return
				files[layer][str(key)] = name
				written[name] = true
				total_bytes += bytes
		tracks[tid] = {"title": String(tm.get("title", "")), "era": String(T["era"]), "loop_samples": loop_n,
			"loop_seconds": snappedf(float(loop_n) / SR, 0.000001), "step_samples": step_n,
			"trim_db": snappedf(-D.lin2db(scale) + match_db, 0.0001), "match_db": snappedf(match_db, 0.0001),
			"keys": keys, "layers": LAYERS, "files": files}
		eras[String(T["era"])] = tid
		print("  track %-8s base rms %+6.2f dBFS  match %+5.2f dB  %.1f s" % [tid, D.lin2db(base_rms), match_db,
			(Time.get_ticks_msec() - t0) / 1000.0])

	# the ambience beds, one per era
	D.set_rate(AMB_SR)
	var amb := {}
	var amb_bytes := 0
	for T: Dictionary in TRACKS:
		var era := String(T["era"])
		var y := _ambience(era)
		var an := int(AMB_S * AMB_SR)
		var scale := PEAK / maxf(D.peak(y), 1e-9)
		var name := "amb_%s.res" % era
		var bytes := _save_loop(y, scale, AMB_SR, an, name)
		if bytes < 0:
			quit(1)
			return
		written[name] = true
		amb_bytes += bytes
		# played at trim: rms(y) * scale * 10^(trim/20) = ref_rms - AMB_UNDER_DB
		var trim := D.lin2db(ref_rms) - AMB_UNDER_DB - D.lin2db(D.rms(y) * scale)
		amb[era] = {"file": name, "trim_db": snappedf(trim, 0.0001), "loop_samples": an, "rate": AMB_SR}
	D.set_rate(SR)

	# retire stems and beds this run did not write
	var dir := DirAccess.open(OUT)
	for f in dir.get_files():
		if (f.begins_with("music_") or f.begins_with("amb_")) and f.ends_with(".res") and not written.has(f):
			dir.remove(f)
	var man := {"version": 2, "rate": SR, "generator": "tools/gen_music.gd", "tracks": tracks, "eras": eras, "ambience": amb}
	var fa := FileAccess.open(OUT + "music_manifest.json", FileAccess.WRITE)
	fa.store_string(JSON.stringify(man, "\t", true) + "\n")
	fa.close()
	print("gen_music: %d stems, %.2f MB, %d ambience beds, %.2f MB, loop %d samples (%.3f s), %.1f s" % [
		written.size() - amb.size(), total_bytes / 1048576.0, amb.size(), amb_bytes / 1048576.0, loop_n,
		float(loop_n) / SR, (Time.get_ticks_msec() - t0) / 1000.0])
	quit()


## Every stem of one track: {stems: "layer|key" -> buffer (loop plus guard sample), peak}.
func _render_track(m: Dictionary, tid: String, keys: Array[int], a4: float, step_s: float, step_n: int,
		total: int, loop_n: int, t0: int) -> Dictionary:
	var channels: Array = []
	for id: String in m["channels"]:
		if id.begins_with("_"):
			continue
		var ch: Dictionary = m["channels"][id]
		channels.append({"id": id, "layer": String(ch["layer"]), "gain": float(ch["gain"]), "kit": ch.has("kit"),
			"echo": ch.get("echo", {}), "events": _compile(m, ch, total)})
	# the v1 seeds for main (its bytes stay those of phase 4), prefixed by the track otherwise
	var pre := "" if tid == "main" else tid + "/"
	var fixed := {}   # kit channel id -> buffer (key-independent)
	var stems := {}
	var pk := 0.0
	for key in keys:
		var kr := pow(2.0, key / 12.0)
		for layer: String in LAYERS:
			var buf := D.zeros(loop_n + int(TAIL_S * SR))
			for ch: Dictionary in channels:
				if ch["layer"] != layer:
					continue
				var x: PackedFloat32Array
				if ch["kit"]:
					if not fixed.has(ch["id"]):
						fixed[ch["id"]] = _echo(_render_channel(m, ch, 1.0, a4, step_s, step_n, buf.size(), pre), ch["echo"], step_n)
					x = fixed[ch["id"]]
				else:
					x = _echo(_render_channel(m, ch, kr, a4, step_s, step_n, buf.size(), pre), ch["echo"], step_n)
				D.mix_at(buf, x, 0, float(ch["gain"]))
			var y := D.loop_wrap(buf, loop_n)
			y.append(y[0])   # the guard sample
			stems["%s|%d" % [layer, key]] = y
			pk = maxf(pk, D.peak(y))
			print("  rendered %-8s %-8s k%d  peak %+6.2f dBFS  %.1f s" % [tid, layer, key, D.lin2db(D.peak(y)),
				(Time.get_ticks_msec() - t0) / 1000.0])
	return {"stems": stems, "peak": pk}


## QOA inside the resource, loop points built in, a UID pinned per file. Returns the bytes
## written, or -1 on failure.
func _save_loop(y: PackedFloat32Array, scale: float, rate: int, loop_n: int, name: String) -> int:
	var w := AudioStreamWAV.load_from_buffer(D.wav_bytes(y, scale, rate), {
		"compress/mode": 2, "edit/loop_mode": 2, "edit/loop_begin": 0, "edit/loop_end": loop_n,
		"edit/trim": false, "edit/normalize": false, "force/mono": false, "force/8_bit": false,
		"force/max_rate": false})
	if w == null or w.format != AudioStreamWAV.FORMAT_QOA or w.loop_mode != AudioStreamWAV.LOOP_FORWARD \
			or w.loop_end != loop_n or w.mix_rate != rate:
		push_error("gen_music: %s did not encode as a looping QOA stream" % name)
		return -1
	var path := OUT + name
	var err := ResourceSaver.save(w, path)
	if err != OK:
		push_error("gen_music: cannot save %s (%d)" % [path, err])
		return -1
	ResourceSaver.set_uid(path, _uid_for(name))
	return FileAccess.get_file_as_bytes(path).size()


## A feedback-free echo: `repeats` copies, each `steps` steps later and `gain` times quieter.
func _echo(x: PackedFloat32Array, e: Dictionary, step_n: int) -> PackedFloat32Array:
	if e.is_empty():
		return x
	var y := x.duplicate()
	var g := 1.0
	for r in range(1, int(e["repeats"]) + 1):
		g *= float(e["gain"])
		D.mix_at(y, x, r * int(e["steps"]) * step_n, g)
	return y


## chip.ts MusicPlayer.compile: the channel's section bars in form order, one event per step.
## A note event is {notes: [names], inst, len} (len counts the '-' holds after it), a kit event
## {hits: [instrument names]}.
func _compile(m: Dictionary, ch: Dictionary, total: int) -> Array:
	var toks: PackedStringArray = []
	for sec: String in m["form"]["order"]:
		for bar: String in ch["sections"][sec]:
			for t in bar.split(" ", false):
				toks.append(t)
	var ev: Array = []
	ev.resize(total)
	var kit: Dictionary = m["kits"][ch["kit"]] if ch.has("kit") else {}
	for i in total:
		if i >= toks.size():
			break
		var tok := toks[i]
		if tok == "." or tok == "-":
			continue
		if ch.has("kit"):
			var hits: Array = []
			for c in tok:
				if kit.has(c):
					hits.append(kit[c])
			ev[i] = {"hits": hits}
			continue
		var parts := tok.split("@")
		var n := 1
		while i + n < total and i + n < toks.size() and toks[i + n] == "-":
			n += 1
		ev[i] = {"notes": parts[0].split("+"), "inst": parts[1] if parts.size() > 1 else String(ch["instrument"]), "len": n}
	return ev


## One channel over the whole song at a key ratio (chip.ts scheduleStep + playInstrument).
func _render_channel(m: Dictionary, ch: Dictionary, kr: float, a4: float, step_s: float, step_n: int, size: int,
		pre: String) -> PackedFloat32Array:
	var out := D.zeros(size)
	var ma4 := float(m["a4Hz"])
	var events: Array = ch["events"]
	for s in events.size():
		var e: Variant = events[s]
		if e == null:
			continue
		var at := s * step_n
		if (e as Dictionary).has("hits"):
			var hi := 0
			for inst: String in e["hits"]:
				_play(m, inst, 1.0, step_s, at, out, a4, "%s%s/%d/%d" % [pre, ch["id"], s, hi])
				hi += 1
		else:
			var ni := 0
			for note: String in e["notes"]:
				var hz := D.to_hz(note, ma4) * kr
				_play(m, String(e["inst"]), hz / ma4, int(e["len"]) * step_s, at, out, a4, "%s%s/%d/%d" % [pre, ch["id"], s, ni])
				ni += 1
	return out


func _play(m: Dictionary, inst_name: String, ratio: float, note_s: float, at: int, out: PackedFloat32Array, a4: float, seed_key: String) -> void:
	var inst: Dictionary = m["instruments"][inst_name]
	var gate := float(inst.get("gate", 1.0))
	var layers: Array = inst["layers"]
	for li in layers.size():
		var L: Dictionary = layers[li]
		var x := D.render_layer(L, ratio, note_s * gate, D.rng_for(seed_key, 0, li), a4)
		D.mix_at(out, x, at + int(roundf(float(L.get("delay", 0.0)) * SR)))


## A stable resource UID per file name, so re-saving writes the same bytes.
func _uid_for(name: String) -> int:
	var hi := hash("monkey-bananas/music/" + name) & 0x7FFFFFFF
	var lo := hash(name + "/uid") & 0xFFFFFFFF
	return (hi << 32) | lo


# ================================================================== era arrangements

## The v1 song re-orchestrated for an era: a deep copy of music.json with new instruments and
## kits, channels moved onto them, and some parts rewritten from the chord chart (form.chords).
## The melody, the form and the layer model stay, so frenzy and evolved behave the same.
func _arrange(m0: Dictionary, id: String) -> Dictionary:
	var m: Dictionary = m0.duplicate(true)
	var I: Dictionary = m["instruments"]
	var K: Dictionary = m["kits"]
	var C: Dictionary = m["channels"]
	I["kickSoft"] = _inst(1.0, [{"id": "body", "wave": "triangle", "crush": 4, "freqStart": 150, "freqEnd": 50,
		"freqCurve": "exp", "glide": 0.08, "followPitch": false, "attack": 0.002, "decay": 0.12, "sustain": 0,
		"duration": 0.121, "release": 0.01, "gain": 0.85}])
	match id:
		"village":
			# warm: a marimba lead, a round triangle bass, plucked off-beats, a wood-and-shaker kit
			m["title"] = "Banana Republic Shuffle (village)"
			I["marimba"] = _inst(1.0, [
				{"id": "bar", "wave": "sine", "freqStart": "A4", "attack": 0.002, "decay": 0.42, "sustain": 0, "duration": 0.42, "release": 0.05, "gain": 1.0},
				{"id": "body", "wave": "triangle", "freqStart": "A4", "attack": 0.002, "decay": 0.22, "sustain": 0, "duration": 0.22, "release": 0.04, "gain": 0.35},
				{"id": "overtone", "wave": "triangle", "freqStart": "A6", "attack": 0.001, "decay": 0.05, "sustain": 0, "duration": 0.05, "release": 0.01, "gain": 0.2},
				{"id": "mallet", "wave": "noise", "clockStart": 30000, "followPitch": false, "filter": {"type": "lowpass", "freq": 3000, "Q": 0.7}, "attack": 0.0005, "decay": 0.006, "sustain": 0, "duration": 0.007, "release": 0.003, "gain": 0.12}])
			I["ook"] = I["marimba"]
			I["bassWarm"] = _inst(0.85, [{"id": "tri", "wave": "triangle", "freqStart": "A4", "attack": 0.004, "decay": 0.15,
				"sustain": 0.65, "duration": "note", "release": 0.05, "gain": 1.0}])
			I["pluck"] = _inst(1.0, [{"id": "pluck", "wave": "pulse", "duty": 0.25, "freqStart": "A4",
				"filter": {"type": "lowpass", "freq": 2400, "freqEnd": 500, "Q": 2}, "attack": 0.002, "decay": 0.18,
				"sustain": 0, "duration": 0.18, "release": 0.03, "gain": 1.0}])
			I["rim"] = _inst(1.0, [
				{"id": "wood", "wave": "triangle", "freqStart": 1100, "freqEnd": 900, "freqCurve": "exp", "glide": 0.02, "followPitch": false, "attack": 0.0005, "decay": 0.035, "sustain": 0, "duration": 0.036, "release": 0.01, "gain": 0.6},
				{"id": "tick", "wave": "noise", "clockStart": 36000, "filter": {"type": "bandpass", "freq": 2500, "Q": 2}, "attack": 0.0005, "decay": 0.02, "sustain": 0, "duration": 0.021, "release": 0.005, "gain": 0.5}])
			K["drumsVillage"] = {"K": "kickSoft", "S": "rim", "H": "shaker", "O": "shaker"}
			_use(C["lead"], "marimba", 0.44)
			_use(C["bass"], "bassWarm", 0.38)
			C["drums"]["kit"] = "drumsVillage"
			C["drums"]["gain"] = 0.34
			_use(C["comp"], "pluck", 0.2)
			_use(C["arpFrenzy"], "marimba", 0.17)
		"city":
			# a bit of funk: an octave-popping bass, a hat on every triplet, a staccato clav lead, stabs
			m["title"] = "Banana Republic Shuffle (city)"
			I["slap"] = _inst(0.7, [
				{"id": "pop", "wave": "pulse", "duty": 0.25, "freqStart": "A4", "filter": {"type": "lowpass", "freq": 3200, "freqEnd": 600, "Q": 4}, "attack": 0.002, "decay": 0.12, "sustain": 0.25, "duration": "note", "release": 0.03, "gain": 0.7},
				{"id": "body", "wave": "triangle", "freqStart": "A4", "attack": 0.002, "decay": 0.1, "sustain": 0.7, "duration": "note", "release": 0.02, "gain": 0.9}])
			I["clav"] = _inst(0.6, [{"id": "clav", "wave": "pulse", "duty": 0.125, "freqStart": "A4",
				"filter": {"type": "lowpass", "freq": 2600, "Q": 3}, "attack": 0.002, "decay": 0.09, "sustain": 0.45,
				"duration": "note", "release": 0.03, "gain": 1.0, "vibrato": {"rateHz": 5.5, "depthCents": 12, "delay": 0.25}}])
			I["stab"] = _inst(1.0, [{"id": "stab", "wave": "square", "freqStart": "A4",
				"filter": {"type": "bandpass", "freq": 1400, "Q": 1.2}, "attack": 0.002, "decay": 0.09, "sustain": 0,
				"duration": 0.09, "release": 0.015, "gain": 1.0}])
			I["hatTight"] = _inst(1.0, [{"id": "noise", "wave": "noise", "clockStart": 48000,
				"filter": {"type": "highpass", "freq": 8000, "Q": 0.7}, "attack": 0.0005, "decay": 0.02, "sustain": 0,
				"duration": 0.021, "release": 0.004, "gain": 0.45}])
			K["drumsCity"] = {"K": "kick", "S": "snare", "H": "hatTight", "O": "hatO"}
			_use(C["lead"], "clav", 0.32)
			C["bass"] = {"instrument": "slap", "gain": 0.4, "layer": "base", "sections": _gen_sections(m, _funk_bar)}
			C["drums"]["kit"] = "drumsCity"
			C["drums"]["sections"] = _map_bars(C["drums"]["sections"], _busy_hats)
			_use(C["comp"], "stab", 0.3)
			_use(C["arpFrenzy"], "clav", 0.13)
		"orbit":
			# spacey: slow pads, the melody as an echoing octave arpeggio, a sub bass, a half-time kit
			m["title"] = "Banana Republic Shuffle (orbit)"
			I["pad"] = _inst(1.0, [
				{"id": "tri", "wave": "triangle", "freqStart": "A4", "attack": 0.45, "decay": 0.3, "sustain": 0.8, "duration": "note", "release": 0.8, "gain": 0.8, "vibrato": {"rateHz": 4.5, "depthCents": 10, "delay": 0.3}},
				{"id": "air", "wave": "pulse", "duty": 0.125, "freqStart": "A4", "detuneJitterSemis": 0.08, "filter": {"type": "lowpass", "freq": 1200, "Q": 0.5}, "attack": 0.6, "decay": 0.2, "sustain": 0.7, "duration": "note", "release": 0.9, "gain": 0.35}])
			I["arpLead"] = _inst(0.95, [{"id": "arp", "wave": "pulse", "duty": 0.125, "freqStart": "A4",
				"arpeggio": [0, 12, 7, 12], "arpRateHz": 12.6, "arpLoop": true, "attack": 0.01, "decay": 0.2,
				"sustain": 0.5, "duration": "note", "release": 0.25, "gain": 1.0}])
			I["subBass"] = _inst(0.95, [{"id": "sub", "wave": "triangle", "freqStart": "A4", "attack": 0.03,
				"decay": 0.3, "sustain": 0.7, "duration": "note", "release": 0.25, "gain": 1.0}])
			I["snareSoft"] = _inst(1.0, [{"id": "noise", "wave": "noise", "clockStart": 16000,
				"filter": {"type": "bandpass", "freq": 1400, "Q": 0.7}, "attack": 0.003, "decay": 0.35, "sustain": 0,
				"duration": 0.351, "release": 0.05, "gain": 0.6}])
			I["shimmer"] = _inst(1.0, [{"id": "metal", "wave": "noiseMetal", "clockStart": 40000,
				"filter": {"type": "highpass", "freq": 7000, "Q": 0.7}, "attack": 0.01, "decay": 0.35, "sustain": 0,
				"duration": 0.36, "release": 0.1, "gain": 0.3}])
			I["glass"] = _inst(1.0, [
				{"id": "sine", "wave": "sine", "freqStart": "A5", "attack": 0.004, "decay": 0.5, "sustain": 0, "duration": 0.5, "release": 0.1, "gain": 0.8},
				{"id": "tri", "wave": "triangle", "freqStart": "A5", "attack": 0.003, "decay": 0.25, "sustain": 0, "duration": 0.25, "release": 0.05, "gain": 0.3}])
			I["blipHi"] = _inst(1.0, [{"id": "blip", "wave": "sine", "freqStart": 1200, "freqEnd": 600, "freqCurve": "exp",
				"glide": 0.06, "followPitch": false, "attack": 0.001, "decay": 0.08, "sustain": 0, "duration": 0.081,
				"release": 0.01, "gain": 0.8}])
			I["blipLo"] = _inst(1.0, [{"id": "blip", "wave": "sine", "freqStart": 700, "freqEnd": 350, "freqCurve": "exp",
				"glide": 0.07, "followPitch": false, "attack": 0.001, "decay": 0.1, "sustain": 0, "duration": 0.101,
				"release": 0.01, "gain": 0.8}])
			K["drumsOrbit"] = {"K": "kickSoft", "S": "snareSoft", "O": "shimmer"}
			K["percOrbit"] = {"B": "blipHi", "b": "blipLo", "s": "shaker"}
			_use(C["lead"], "arpLead", 0.24)
			C["lead"]["echo"] = {"steps": 3, "gain": 0.35, "repeats": 2}
			C["bass"] = {"instrument": "subBass", "gain": 0.42, "layer": "base", "sections": _gen_sections(m, _sub_bar)}
			C["drums"]["kit"] = "drumsOrbit"
			C["drums"]["gain"] = 0.3
			C["drums"]["sections"] = _map_bars(C["drums"]["sections"], _half_time)
			C["pad"] = {"instrument": "pad", "gain": 0.14, "layer": "base", "sections": _gen_sections(m, _pad_bar)}
			_use(C["comp"], "glass", 0.12)
			C["comp"]["echo"] = {"steps": 3, "gain": 0.3, "repeats": 1}
			_use(C["arpFrenzy"], "glass", 0.12)
			C["perc"]["kit"] = "percOrbit"
			C["perc"]["gain"] = 0.26
	return m


func _inst(gate: float, layers: Array) -> Dictionary:
	return {"gate": gate, "layers": layers}


func _use(ch: Dictionary, inst: String, gain: float) -> void:
	ch["instrument"] = inst
	ch["gain"] = gain


## Sections built from the chord chart: fn(chords of the bar: [first half, second half]) -> the
## bar string (12 tokens). A split bar ("Bb|C") changes chord at its middle.
func _gen_sections(m: Dictionary, fn: Callable) -> Dictionary:
	var out := {}
	var chords: Dictionary = m["form"]["chords"]
	for sec: String in chords:
		var bars: Array = []
		for sym: String in chords[sec]:
			var halves := sym.split("|")
			bars.append(fn.call(halves[0], halves[halves.size() - 1]))
		out[sec] = bars
	return out


## Every bar string of a channel's sections through fn(tokens, section, bar index) -> tokens.
func _map_bars(sections: Dictionary, fn: Callable) -> Dictionary:
	var out := {}
	for sec: String in sections:
		var bars: Array = []
		var i := 0
		for bar: String in sections[sec]:
			var t: PackedStringArray = fn.call(bar.split(" ", false), sec, i)
			bars.append(" ".join(t))
			i += 1
		out[sec] = bars
	return out


## A chord symbol's root pitch class and intervals: "F", "Bb", "C7", "Dm", "Gm".
func _chord(sym: String) -> Dictionary:
	var pc: int = PCS[sym.substr(0, 1)]
	var rest := sym.substr(1)
	if rest.begins_with("b"):
		pc -= 1
		rest = rest.substr(1)
	elif rest.begins_with("#"):
		pc += 1
		rest = rest.substr(1)
	var iv := [0, 3 if rest.begins_with("m") else 4, 7]
	if rest.contains("7"):
		iv.append(10)
	return {"pc": posmod(pc, 12), "iv": iv}


## The MIDI note of pitch class pc at or above lo.
func _at_or_above(pc: int, lo: int) -> int:
	return lo + posmod(pc - lo, 12)


func _name(midi: int) -> String:
	return "%s%d" % [NAMES[posmod(midi, 12)], floori(midi / 12.0) - 1]


## city bass: root low, octave pops, the fifth and a flat-seven pickup (E2..Eb3 roots).
func _funk_bar(a: String, b: String) -> String:
	var pat := ["R", ".", "O", ".", "R", "O", "R", "-", "F", "O", ".", "7"]
	var t: PackedStringArray = []
	for i in 12:
		var r := _at_or_above(int(_chord(a if i < 6 else b)["pc"]), 40)
		match pat[i]:
			"R":
				t.append(_name(r))
			"O":
				t.append(_name(r + 12))
			"F":
				t.append(_name(r + 7))
			"7":
				t.append(_name(r + 10))
			_:
				t.append(pat[i])
	return " ".join(t)


## orbit bass: a held sub root per chord, the fifth late in an unsplit bar.
func _sub_bar(a: String, b: String) -> String:
	var ra := _at_or_above(int(_chord(a)["pc"]), 40)
	if a != b:
		var rb := _at_or_above(int(_chord(b)["pc"]), 40)
		return "%s - - - - -  %s - - - - -" % [_name(ra), _name(rb)]
	return "%s - - - - - - - -  %s - -" % [_name(ra), _name(ra + 7)]


## orbit pad: the chord (root F3..E4, triad or seventh) held for its whole bar or half bar.
func _pad_bar(a: String, b: String) -> String:
	if a != b:
		return "%s - - - - -  %s - - - - -" % [_voicing(a), _voicing(b)]
	return "%s - - - - - - - - - - -" % _voicing(a)


func _voicing(sym: String) -> String:
	var c := _chord(sym)
	var r := _at_or_above(int(c["pc"]), 53)
	var notes: PackedStringArray = []
	for iv: int in c["iv"]:
		notes.append(_name(r + iv))
	return "+".join(notes)


## city drums: a closed hat on every empty triplet.
func _busy_hats(t: PackedStringArray, _sec: String, _i: int) -> PackedStringArray:
	for i in t.size():
		if t[i] == ".":
			t[i] = "H"
	return t


## orbit drums: half time. The kick of beat 1 stays, a soft snare on beat 3 (not in the
## breakdown), a metallic shimmer on every second bar's last beat.
func _half_time(t: PackedStringArray, sec: String, i: int) -> PackedStringArray:
	var out: PackedStringArray = []
	for s in 12:
		out.append(".")
	if t[0].contains("K"):
		out[0] = "K"
	if sec != "C":
		out[6] = "S"
	if i % 2 == 1:
		out[9] = "O"
	return out


# ================================================================== ambience beds

## One era's bed at AMB_SR, AMB_S long, looping: stationary layers render long and crossfade
## over the seam (D.loop_xfade); scattered events render into a second buffer whose tail wraps
## (D.loop_wrap). All randomness is seeded per era.
func _ambience(era: String) -> PackedFloat32Array:
	var n := int(AMB_S * AMB_SR)
	var long := AMB_S + 1.0
	var ev := D.zeros(n + int(4.0 * AMB_SR))
	var r := D.rng_for("amb/" + era, 0, 0)
	var bed := D.zeros(int(long * AMB_SR) + 2)
	match era:
		"jungle":
			_bed(bed, {"wave": "noise", "clockStart": 12000, "filter": {"type": "lowpass", "freq": 700, "Q": 0.5}, "gain": 0.12}, long, "jungle/wind")
			_birds(ev, r, 12, 0.35, "jungle")
			for k in 3:   # insect trills
				var x := D.render_layer({"wave": "noiseMetal", "clockStart": 50000, "filter": {"type": "bandpass", "freq": 4500, "Q": 5},
					"attack": 0.3, "decay": 0.0, "sustain": 1.0, "duration": 1.5, "release": 0.4, "gain": 0.12}, 1.0, 0.0, D.rng_for("amb/jungle/bug", k, 0))
				_am(x, 24.0 + 4.0 * k, 0.0)
				D.mix_at(ev, x, int(r.randf() * AMB_S * AMB_SR))
		"village":
			_bed(bed, {"wave": "noise", "clockStart": 10000, "filter": {"type": "lowpass", "freq": 500, "Q": 0.5}, "gain": 0.08}, long, "village/wind")
			_birds(ev, r, 4, 0.18, "village")
			for k in 8:   # distant chatter: short runs of formant blips
				var t := r.randf() * AMB_S
				var f1 := 650.0 if r.randf() < 0.5 else 330.0
				for j in r.randi_range(3, 7):
					var f := r.randf_range(180.0, 360.0)
					var x := D.render_layer({"wave": "square", "freqStart": f, "freqEnd": f * 0.94, "filter": {"type": "bandpass", "freq": f1, "Q": 3.0},
						"attack": 0.004, "decay": 0.05, "sustain": 0.2, "duration": 0.055, "release": 0.015, "gain": 0.12}, 1.0, 0.0, D.rng_for("amb/village/talk", k, j))
					D.mix_at(ev, x, int((t + j * r.randf_range(0.09, 0.12)) * AMB_SR))
			for k in 5:   # wood knocks
				var x := D.render_layer({"wave": "triangle", "freqStart": 800, "freqEnd": 700, "freqCurve": "exp", "glide": 0.02, "attack": 0.0005,
					"decay": 0.04, "sustain": 0, "duration": 0.041, "release": 0.01, "gain": 0.15}, 1.0, 0.0, D.rng_for("amb/village/knock", k, 0))
				var t := r.randf() * AMB_S
				D.mix_at(ev, x, int(t * AMB_SR))
				D.mix_at(ev, x, int((t + 0.16) * AMB_SR), 0.7)
		"city":
			_bed(bed, {"wave": "sine", "freqStart": 60, "gain": 0.08}, long, "city/hum")
			_bed(bed, {"wave": "sine", "freqStart": 120, "gain": 0.04}, long, "city/hum2")
			var traffic := D.zeros(bed.size())
			_bed(traffic, {"wave": "noise", "clockStart": 8000, "filter": {"type": "lowpass", "freq": 350, "Q": 0.5}, "gain": 0.25}, long, "city/traffic")
			D.mix_at(bed, traffic, 0)
			for k in 3:   # passing cars
				var x := D.render_layer({"wave": "noise", "clockStart": 15000, "filter": {"type": "bandpass", "freq": 400, "freqEnd": 1000, "Q": 1.0},
					"attack": 1.2, "decay": 1.3, "sustain": 0, "duration": 2.5, "release": 0.2, "gain": 0.25}, 1.0, 0.0, D.rng_for("amb/city/car", k, 0))
				D.mix_at(ev, x, int(r.randf() * AMB_S * AMB_SR))
			for k in 2:   # distant horns
				var t := r.randf() * AMB_S
				for f: float in [440.0, 554.37]:
					var x := D.render_layer({"wave": "pulse", "duty": 0.25, "freqStart": f, "filter": {"type": "lowpass", "freq": 1200, "Q": 0.7},
						"attack": 0.01, "decay": 0.05, "sustain": 0.8, "duration": 0.22, "release": 0.06, "gain": 0.08}, 1.0, 0.0, D.rng_for("amb/city/horn", k, int(f)))
					D.mix_at(ev, x, int(t * AMB_SR))
					if k == 1:
						D.mix_at(ev, x, int((t + 0.3) * AMB_SR))
		"orbit":
			var drone := D.zeros(bed.size())
			_bed(drone, {"wave": "sine", "freqStart": "F2", "gain": 0.1}, long, "orbit/drone")
			_bed(drone, {"wave": "sine", "freqStart": "C3", "gain": 0.06}, long, "orbit/drone5")
			D.mix_at(bed, drone, 0)
			var notes := ["F6", "G6", "A6", "C7", "D7", "F7"]
			for k in 14:   # slow shimmering tones
				var x := D.render_layer({"wave": "sine", "freqStart": notes[r.randi_range(0, notes.size() - 1)], "attack": 1.2, "decay": 0.0,
					"sustain": 1.0, "duration": 1.4, "release": 2.2, "gain": 0.08}, 1.0, 0.0, D.rng_for("amb/orbit/tone", k, 0))
				D.mix_at(ev, x, int(r.randf() * AMB_S * AMB_SR))
			for k in 2:   # filtered noise sweeps
				var x := D.render_layer({"wave": "noise", "clockStart": 20000, "filter": {"type": "bandpass", "freq": 2400, "freqEnd": 700, "Q": 4.0},
					"attack": 3.0, "decay": 0.0, "sustain": 1.0, "duration": 6.0, "release": 3.0, "gain": 0.07}, 1.0, 0.0, D.rng_for("amb/orbit/sweep", k, 0))
				D.mix_at(ev, x, int((1.0 + 8.0 * k) * AMB_SR))
	var y := D.loop_xfade(bed, n, int(0.5 * AMB_SR))
	# slow swells whose period divides the loop, so the seam stays continuous
	if era == "city":
		_am(y, 1.0 / 8.0, 0.55)
	elif era == "orbit":
		_am(y, 1.0 / 16.0, 0.6)
	D.mix_at(y, D.loop_wrap(ev, n), 0)
	return y


## A stationary layer held for `len_s` seconds, added into dst.
func _bed(dst: PackedFloat32Array, L: Dictionary, len_s: float, key: String) -> void:
	var l := L.duplicate()
	l["attack"] = 0.001
	l["decay"] = 0.0
	l["sustain"] = 1.0
	l["duration"] = len_s
	l["release"] = 0.01
	D.mix_at(dst, D.render_layer(l, 1.0, 0.0, D.rng_for("amb/" + key, 0, 0), 440.0), 0)


## Amplitude modulation in place: floor + (1 - floor) * (0.5 + 0.5 sin), squared when floor is 0
## (a trill), at `hz`.
func _am(x: PackedFloat32Array, hz: float, floor_: float) -> void:
	for i in x.size():
		var s := 0.5 + 0.5 * sin(TAU * hz * i / AMB_SR)
		x[i] *= (s * s) if floor_ <= 0.0 else (floor_ + (1.0 - floor_) * s)


## Bird chirps: `count` calls of 1-3 fast sine sweeps between 2.2 and 3.8 kHz.
func _birds(ev: PackedFloat32Array, r: RandomNumberGenerator, count: int, loud: float, key: String) -> void:
	for k in count:
		var t := r.randf() * AMB_S
		var f0 := r.randf_range(2200.0, 3800.0)
		var up := r.randf() < 0.5
		for j in r.randi_range(1, 3):
			var x := D.render_layer({"wave": "sine", "freqStart": f0, "freqEnd": f0 * (1.35 if up else 0.7), "freqCurve": "exp",
				"glide": 0.07, "attack": 0.004, "decay": 0.08, "sustain": 0, "duration": 0.08, "release": 0.02,
				"gain": r.randf_range(0.4, 1.0) * loud}, 1.0, 0.0, D.rng_for("amb/%s/bird" % key, k, j))
			D.mix_at(ev, x, int((t + j * 0.11) * AMB_SR))
