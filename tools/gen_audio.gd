extends SceneTree
## Renders every cue of res://data/cues.json (a copy of audio/cues.json) to
## game/assets/audio/sfx_*.wav, 44.1 kHz mono 16-bit, and writes sfx_manifest.json. The music is
## tools/gen_music.gd. Run the whole pipeline with tools/audio.sh; this step alone:
##     tools/godot.sh --headless --path game -s <abs path>/tools/gen_audio.gd
##
## Every layer is synthesised by tools/lib_dsp.gd, an offline emulation of the v1 Web Audio chip
## (src/audio/chip.ts), so a file sounds like the v1 cue did: same waves, envelopes and notes.
##
## Files (names from Audio.sfx_file, shared with the runtime):
## - one file per pitch the runtime can ask for: the followsKey cues get every music key
##   (music.json keyOffsetByEvolutions), the scale cues (tap, tapCrit, buy) every degree the
##   streak and the crit combo reach, uiToggleOn the buy-mode steps. sfx_<cue>_sNN = +NN semis.
## - Audio.VARIANTS variants of the fast cues: _2, _3. They differ in their random parts (noise
##   offsets, the thump's detune jitter); a cue with no random part (cantAfford, the toggles)
##   gets +10 / -10 cents instead.
## - a conditional-layer set: sfx_tap_fz_* is the tap with its Tap Frenzy sparkle.
##
## Levels: the cue level (gainDb) is NOT baked in. Each cue's files share one scale that puts
## its loudest file at -1 dBFS, and sfx_manifest.json records the trim (dB) the runtime adds
## back, so a cue plays at exactly its spec level with the full 16 bits used.
##
## Phase 9 (ADR 0003): game/assets/audio/cues_v2.json adds the v2 stingers (achievement,
## milestone, perkBuy, storyCard, era) in the same schema, merged over cues.json by
## Audio.load_cues(), and CHIP's babble bank: sfx_babble_<colour>_<index>.wav, one short
## formant blip per (vowel colour, pitch), rendered by _render_babble.
##
## Deterministic: every random stream is seeded per (cue, set, pitch, variant, layer), so two runs
## write identical bytes. Retired sfx_*.wav (not written by this run) are deleted.

const D := preload("lib_dsp.gd")
const SR := 44100
const OUT := "res://assets/audio/"
const PEAK := 0.891251   # -1 dBFS
const TAIL_S := 0.002

var _cents: Array = [0.0]   # Audio.VARIANT_CENTS


func _initialize() -> void:
	var t0 := Time.get_ticks_msec()
	var A: GDScript = load("res://scripts/autoload/audio.gd")
	var C := A.get_script_constant_map()
	_cents = C["VARIANT_CENTS"]
	D.set_rate(SR)
	var cj: Dictionary = A.load_cues()
	var music: Dictionary = A.load_json("res://data/music.json")
	var cues: Dictionary = cj["cues"]
	var events: Dictionary = cj["events"]
	var a4 := float(cj["globals"]["a4Hz"])
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var written := {}
	var man := {"version": 1, "rate": SR, "generator": "tools/gen_audio.gd", "cues": {}}
	var total_bytes := 0
	var ids: Array = cues.keys()
	ids.sort()
	for id: String in ids:
		var cue: Dictionary = cues[id]
		var semis_list: Array[int] = A.render_semis(id, cue, events, music)
		var sets: Array[String] = A.cond_sets(cue)
		var nv: int = A.variants_of(id)
		var tonal_only := not _has_random(cue)
		var bufs := {}
		var pk := 0.0
		var longest := 0.0
		for set_name in sets:
			var layers: Array = (cue["layers"] as Array).duplicate()
			for cl: Dictionary in cue.get("conditionalLayers", []):
				if String((C["COND_SUFFIX"] as Dictionary).get(String(cl["when"]), String(cl["when"]))) == set_name:
					layers.append_array(cl["layers"])
			for s in semis_list:
				for v in range(1, nv + 1):
					var x := _render("%s/%s/%d" % [id, set_name, s], layers, s, v, tonal_only, a4)
					pk = maxf(pk, D.peak(x))
					longest = maxf(longest, x.size() * 1000.0 / SR)
					bufs[A.sfx_file(id, set_name, s, v)] = x
		var scale := PEAK / maxf(pk, 1e-9)
		var files: Array = bufs.keys()
		files.sort()
		for f: String in files:
			D.save_wav(bufs[f], OUT + f + ".wav", scale)
			written[f + ".wav"] = true
			total_bytes += 44 + (bufs[f] as PackedFloat32Array).size() * 2
		man["cues"][id] = {"trim_db": snappedf(-D.lin2db(scale), 0.0001), "semis": semis_list, "variants": nv,
			"sets": sets, "files": files.size(), "length_ms": snappedf(longest, 0.1)}
		print("  %-22s %3d files  %+6.2f dB trim  %s" % [id, files.size(), -D.lin2db(scale), str(semis_list)])
	# CHIP's babble bank
	var bb: Dictionary = cj.get("babble", {})
	if not bb.is_empty():
		var res := _render_babble(A, bb, a4)
		for f: String in res["files"]:
			D.save_wav(res["bufs"][f], OUT + f + ".wav", float(res["scale"]))
			written[f + ".wav"] = true
			total_bytes += 44 + (res["bufs"][f] as PackedFloat32Array).size() * 2
		man["babble"] = {"trim_db": snappedf(-D.lin2db(float(res["scale"])), 0.0001), "files": (res["files"] as Array).size(),
			"pitches": (bb["pitches"] as Array).size(), "colors": res["colors"], "length_ms": res["length_ms"]}
		print("  %-22s %3d files  %+6.2f dB trim" % ["babble", (res["files"] as Array).size(), -D.lin2db(float(res["scale"]))])
	# retire files this run did not write
	var dir := DirAccess.open(OUT)
	var removed := 0
	for f in dir.get_files():
		if f.begins_with("sfx_") and f.ends_with(".wav") and not written.has(f):
			dir.remove(f)
			if dir.file_exists(f + ".import"):
				dir.remove(f + ".import")
			removed += 1
	var fa := FileAccess.open(OUT + "sfx_manifest.json", FileAccess.WRITE)
	fa.store_string(JSON.stringify(man, "\t", true) + "\n")
	fa.close()
	print("gen_audio: %d files, %.2f MB of WAV, %d retired, %.1f s" % [written.size(), total_bytes / 1048576.0,
		removed, (Time.get_ticks_msec() - t0) / 1000.0])
	quit()


## True when a render has a random part (noise, a detune jitter): variants then differ by it.
func _has_random(cue: Dictionary) -> bool:
	var all: Array = (cue["layers"] as Array).duplicate()
	for cl: Dictionary in cue.get("conditionalLayers", []):
		all.append_array(cl["layers"])
	for L: Dictionary in all:
		if String(L["wave"]).begins_with("noise") or L.has("detuneJitterSemis"):
			return true
	return false


## One cue instance (chip.ts ChipAudio.play): every layer at its delay, pitched by `semis`.
func _render(key: String, layers: Array, semis: int, variant: int, tonal_only: bool, a4: float) -> PackedFloat32Array:
	var end := 0.0
	for L: Dictionary in layers:
		end = maxf(end, D.layer_end(L))
	var out := D.zeros(int(ceil((end + TAIL_S) * SR)))
	var ratio := pow(2.0, semis / 12.0)
	var cents: float = float(_cents[(variant - 1) % _cents.size()]) if tonal_only else 0.0
	for li in layers.size():
		var L: Dictionary = layers[li]
		var rng := D.rng_for(key, variant, li)
		var x := D.render_layer(L, ratio, 0.0, rng, a4, cents)
		D.mix_at(out, x, int(roundf(float(L.get("delay", 0.0)) * SR)))
	return out


## The babble bank: for every vowel colour and pitch, a square blip gliding down a little, summed
## raw and through the colour's two formant bandpasses. One scale for the whole bank (peak at
## -1 dBFS), so the colours keep their relative level.
func _render_babble(A: GDScript, bb: Dictionary, a4: float) -> Dictionary:
	var blip: Dictionary = bb["blip"]
	var pitches: Array = bb["pitches"]
	var colors: Dictionary = bb["colors"]
	var bufs := {}
	var files: Array[String] = []
	var pk := 0.0
	var longest := 0.0
	var cids: Array = colors.keys()
	cids.sort()
	for c: String in cids:
		var fm: Array = colors[c]["formants"]
		for i in pitches.size():
			var f := D.to_hz(pitches[i], a4)
			var base := {"wave": "square", "freqStart": f, "freqEnd": f * float(blip["glideRatio"]), "freqCurve": "exp",
				"attack": blip["attack"], "decay": blip["decay"], "sustain": blip["sustain"], "duration": blip["duration"],
				"release": blip["release"]}
			var layers: Array = []
			var raw := base.duplicate()
			raw["gain"] = blip["rawGain"]
			layers.append(raw)
			for k in fm.size():
				var L := base.duplicate()
				L["gain"] = 1.0 if k == 0 else 0.8
				L["filter"] = {"type": "bandpass", "freq": float(fm[k]), "Q": float(blip["formantQ"])}
				layers.append(L)
			var end := 0.0
			for L: Dictionary in layers:
				end = maxf(end, D.layer_end(L))
			var out := D.zeros(int(ceil((end + TAIL_S) * SR)))
			for li in layers.size():
				D.mix_at(out, D.render_layer(layers[li], 1.0, 0.0, D.rng_for("babble/%s/%d" % [c, i], 1, li), a4), 0)
			var name: String = A.babble_file(c, i)
			bufs[name] = out
			files.append(name)
			pk = maxf(pk, D.peak(out))
			longest = maxf(longest, out.size() * 1000.0 / SR)
	return {"bufs": bufs, "files": files, "scale": PEAK / maxf(pk, 1e-9), "length_ms": snappedf(longest, 0.1), "colors": cids}
