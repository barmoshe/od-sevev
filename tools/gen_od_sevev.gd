extends SceneTree
## "עוד סבב" audio: renders audio/od/music.json and audio/od/cues.json (the Audio Director's data)
## into game/assets/audio/od/ as QOA AudioStreamWAV resources, plus od_manifest.json, the runtime
## contract (files, play levels, buses, ducks, layer rules, babble contours). Added by the Audio
## Director (STATUS.md, 2026-09-28) as a new file beside gen_audio.gd / gen_music.gd, which it does
## not touch; it reuses tools/lib_dsp.gd unchanged. Run through tools/audio.sh, or alone:
##     tools/godot.sh --headless --path game -s <abs path>/tools/gen_od_sevev.gd
##
## Music: four era tracks (balfour D hijaz 116, knesset E hijaz 132, courthouse G hijaz 88,
## washington F Mixolydian 144), 32 bars each, three adaptive stems (L0 bed, L1 P2, L2 P1 lead) per
## era, one key per era. Each era renders at its own rate so that one grid step is a whole number of
## samples (31,900 / 32,032 / 31,944 / 31,968 Hz): the loop is sample-exact. Notes ringing past
## bar 32 wrap onto bar 1 (lib_dsp.loop_wrap); each stem carries one guard sample (ADR 0002).
## Balfour also gets the 2-bar Outside drum loop. An era may carry a slapback (none does since v2.0).
##
## Stingers (music.json "stingers"): tempo-bound one-shots written in D and transposed per key,
## rendered at the key's era tempo and rate. The fanfare renders five lengths (0-4 tags) per key.
##
## Cues (cues.json): one file per (key, pitch, variant) the runtime can ask for. 32 kHz mono.
##
## Levels: every stem set / cue shares one scale that puts its loudest file at -1 dBFS. play_db in
## the manifest is the AudioStreamPlayer volume_db that lands the item on its loudness target
## (K-weighted BS.1770 loudness, dual mono, computed here), with every bus at 0 dB.
##
## Deterministic: every random stream is seeded per (item, key, pitch, variant, layer) and each
## resource gets a UID derived from its file name. Set OD_AUDIO_PREVIEW=<dir> to also write the
## heard-level 16-bit WAVs there (for measuring and listening; never in the build).

const D := preload("lib_dsp.gd")
const OUT := "res://assets/audio/od/"
const PEAK := 0.707946   # -3 dBFS (v1.6: QOA overshoots a full-scale file by up to ~1 dB; play_db keeps the loudness)
const TAIL_S := 2.0
const LAYERS := ["L0", "L1", "L2"]
const ORDER := ["A", "A2", "B", "T"]
const PCS := {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}
const MORDENT_S := 0.04
const SCOOP_S := 0.05
const DUAL_MONO_DB := 3.0103

var _root := ""
var _m: Dictionary = {}
var _c: Dictionary = {}
var _a4 := 440.0
var _written := {}
var _bytes := {"music": 0, "outside": 0, "stingers": 0, "sfx": 0}
var _count := {"music": 0, "outside": 0, "stingers": 0, "sfx": 0}
var _preview := ""
var _t0 := 0


func _initialize() -> void:
	_t0 = Time.get_ticks_msec()
	_root = ProjectSettings.globalize_path("res://").path_join("..")
	_m = _load(_root.path_join("audio/od/music.json"))
	_c = _load(_root.path_join("audio/od/cues.json"))
	if _m.is_empty() or _c.is_empty():
		push_error("gen_od_sevev: audio/od/music.json or cues.json missing or invalid")
		quit(1)
		return
	_a4 = float(_m["a4Hz"])
	D.sample_dir = _root.path_join("audio/od/samples")   # v2.1: the CC0 one-shots (SOURCES.md)
	_preview = OS.get_environment("OD_AUDIO_PREVIEW")
	if _preview != "":
		DirAccess.make_dir_recursive_absolute(_preview)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var man := {"version": "od-1", "generator": "tools/gen_od_sevev.gd", "a4Hz": _a4,
		"layers": _m["layers"], "antiFatigue": _m["antiFatigue"], "courtDay": _m["courtDay"], "outsideSpec": _m["outside"],
		"keys": _c["keys"], "degrees": _c["degrees"], "buses": _c["buses"], "babbleContours": _c["babbleContours"],
		"crits": _c.get("crits", {}), "eras": {}, "stingers": {}, "cues": {}}
	var targets: Dictionary = _m["targets"]
	# v2.1, a mixing aid: OD_AUDIO_ERA=<era> renders only that era's stems (and previews), then stops
	# before the manifest, the stingers, the cues and the retiring of files. Never in the build.
	var only := OS.get_environment("OD_AUDIO_ERA")
	for eid: String in _m["eras"]:
		if only != "" and eid != only:
			continue
		var r := _render_era(eid, _m["eras"][eid], float(targets["music"]) + float(_m["eras"][eid].get("targetOffsetDb", 0.0)))
		if r.is_empty():
			quit(1)
			return
		man["eras"][eid] = r
	if only != "":
		print("gen_od_sevev: OD_AUDIO_ERA=%s only (no manifest written)" % only)
		quit()
		return
	for sid: String in _m["stingers"]:
		if sid.begins_with("_"):
			continue
		var r := _render_stinger(sid, _m["stingers"][sid], targets[sid])
		if r.is_empty():
			quit(1)
			return
		man["stingers"][sid] = r
	var ids: Array = (_c["cues"] as Dictionary).keys()
	ids.sort()
	# relative targets refer to other cues: render the absolute ones first
	var rel: Array = []
	for id: String in ids:
		if String(_c["cues"][id]["target"]["type"]) == "relative":
			rel.append(id)
			continue
		var r := _render_cue(id, _c["cues"][id], man)
		if r.is_empty():
			quit(1)
			return
		man["cues"][id] = r
	for id: String in rel:
		var r := _render_cue(id, _c["cues"][id], man)
		if r.is_empty():
			quit(1)
			return
		man["cues"][id] = r
	# retire what this run did not write
	var dir := DirAccess.open(OUT)
	for f in dir.get_files():
		if f.ends_with(".res") and not _written.has(f):
			dir.remove(f)
	man["sizes"] = {"music_bytes": _bytes["music"], "outside_bytes": _bytes["outside"], "stinger_bytes": _bytes["stingers"],
		"sfx_bytes": _bytes["sfx"], "files": _count}
	var fa := FileAccess.open(OUT + "od_manifest.json", FileAccess.WRITE)
	fa.store_string(JSON.stringify(man, "\t", true) + "\n")
	fa.close()
	var total := 0
	for k: String in _bytes:
		total += int(_bytes[k])
	print("gen_od_sevev: %d files, %.2f MB (music %d stems %.2f MB, outside %.2f MB, stingers %d %.2f MB, sfx %d %.2f MB), %.1f s" % [
		_written.size(), total / 1048576.0, _count["music"], _bytes["music"] / 1048576.0, _bytes["outside"] / 1048576.0,
		_count["stingers"], _bytes["stingers"] / 1048576.0, _count["sfx"], _bytes["sfx"] / 1048576.0,
		(Time.get_ticks_msec() - _t0) / 1000.0])
	quit()


func _load(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var v: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return v if typeof(v) == TYPE_DICTIONARY else {}


# ================================================================== notes and tokens

func _midi(name: String) -> int:
	var v: int = PCS[name.substr(0, 1)]
	var i := 1
	if name.length() > 2 and (name[1] == "#" or name[1] == "b"):
		v += 1 if name[1] == "#" else -1
		i = 2
	return v + (int(name.substr(i)) + 1) * 12


func _hz(midi: int) -> float:
	return _a4 * pow(2.0, (midi - 69) / 12.0)


## One pitched token: "D5", "D4+A4", "D5~Eb5" (mordent), "D5<C#5" (scoop), with "@inst".
func _note_token(tok: String, semis: int) -> Dictionary:
	var inst := ""
	var at := tok.find("@")
	if at >= 0:
		inst = tok.substr(at + 1)
		tok = tok.substr(0, at)
	var orn := {}
	var main := tok
	if tok.contains("~"):
		var p := tok.split("~")
		main = p[0]
		orn = {"type": "mordent", "semis": _midi(p[1]) - _midi(p[0])}
	elif tok.contains("<"):
		var p := tok.split("<")
		main = p[0]
		orn = {"type": "scoop", "semis": _midi(p[0]) - _midi(p[1])}
	var notes: Array[int] = []
	for n in main.split("+"):
		notes.append(_midi(n) + semis)
	return {"notes": notes, "inst": inst, "orn": orn}


## A channel's bars -> one event per step: {notes, inst, orn, len} or {hits}.
func _compile(bars: PackedStringArray, ch: Dictionary, sec_of_bar: PackedStringArray, semis: int) -> Array:
	var toks: PackedStringArray = []
	var sec_of_tok: PackedStringArray = []
	for bi in bars.size():
		for t in bars[bi].split(" ", false):
			toks.append(t)
			sec_of_tok.append(sec_of_bar[bi] if bi < sec_of_bar.size() else "")
	var total := toks.size()
	var ev: Array = []
	ev.resize(total)
	var kit: Dictionary = _m["kits"][ch["kit"]] if ch.has("kit") else {}
	for i in total:
		var tok := toks[i]
		if tok == "." or tok == "-":
			continue
		if ch.has("kit"):
			var hits: Array = []
			var vels: Array = []
			for c in tok:
				if kit.has(c):
					# v2.0: a kit entry may carry a velocity, "hat@0.55"
					var parts := String(kit[c]).split("@")
					hits.append(parts[0])
					vels.append(float(parts[1]) if parts.size() > 1 else 1.0)
			ev[i] = {"hits": hits, "vel": vels, "g": float((ch.get("sectionGain", {}) as Dictionary).get(sec_of_tok[i], 1.0))}
			continue
		var e := _note_token(tok, semis)
		var n := 1
		while i + n < total and toks[i + n] == "-":
			n += 1
		if String(e["inst"]) == "":
			var si: Dictionary = ch.get("sectionInstrument", {})
			e["inst"] = String(si.get(sec_of_tok[i], ch["instrument"]))
		e["len"] = n
		e["g"] = float((ch.get("sectionGain", {}) as Dictionary).get(sec_of_tok[i], 1.0))
		ev[i] = e
	return ev


## Renders events into `out` (step positions from step_s at the current D.sr).
func _render_events(ev: Array, step_s: float, out: PackedFloat32Array, seed_pre: String, limit_steps := -1, detune := 1.0) -> void:
	for s in ev.size():
		if limit_steps >= 0 and s >= limit_steps:
			break
		var e: Variant = ev[s]
		if e == null:
			continue
		var at := int(roundf(s * step_s * D.sr))
		if (e as Dictionary).has("hits"):
			var hits: Array = e["hits"]
			for hi in hits.size():
				_play(String(hits[hi]), 1.0, step_s, at, out, "%s/%d/%d" % [seed_pre, s, hi], {}, float(e["g"]) * float(e["vel"][hi]))
			continue
		var ni := 0
		for n: int in e["notes"]:
			_play(String(e["inst"]), _hz(n) / _a4 * detune, int(e["len"]) * step_s, at, out, "%s/%d/%d" % [seed_pre, s, ni], e["orn"], float(e["g"]))
			ni += 1


func _play(inst_name: String, ratio: float, note_s: float, at: int, out: PackedFloat32Array, seed_key: String, orn: Dictionary, g := 1.0) -> void:
	var inst: Dictionary = _m["instruments"][inst_name]
	var gate := float(inst.get("gate", 1.0))
	var layers: Array = inst["layers"]
	for li in layers.size():
		var L: Dictionary = layers[li]
		var tonal := not String(L["wave"]).begins_with("noise") and bool(L.get("followPitch", true))
		if not orn.is_empty() and tonal and not L.has("freqEnd") and not L.has("arpeggio"):
			L = L.duplicate(true)
			if orn["type"] == "mordent":
				L["arpeggio"] = [0, int(orn["semis"]), 0]
				L["arpRateHz"] = 1.0 / MORDENT_S
				L["arpLoop"] = false
			else:
				var f := D.to_hz(L["freqStart"], _a4)
				L["freqStart"] = f * pow(2.0, -int(orn["semis"]) / 12.0)
				L["freqEnd"] = f
				L["glide"] = SCOOP_S
				L["freqCurve"] = "exp"
		var x := D.render_layer(L, ratio, note_s * gate, D.rng_for(seed_key, 0, li), _a4)
		D.mix_at(out, x, at + int(roundf(float(L.get("delay", 0.0)) * D.sr)), g)


## v1.8 (Bar: "thin / harsh, tiring"): a channel's `fx`. `double` {cents, db}: the line again, detuned,
## under it (the chip chorus: two pulse channels a few cents apart). `echo` {steps, db, repeats}: the
## line delayed by `steps` and `db` quieter per repeat (the chip echo channel). Both wrap with the loop.
func _channel_fx(x: PackedFloat32Array, ev: Array, fx: Dictionary, step_s: float, seed_pre: String) -> PackedFloat32Array:
	if fx.is_empty():
		return x
	var y := x
	if fx.has("double"):
		var dbl: Dictionary = fx["double"]
		var z := D.zeros(x.size())
		_render_events(ev, step_s, z, seed_pre + "/dbl", -1, pow(2.0, float(dbl["cents"]) / 1200.0))
		y = x.duplicate()
		D.mix_at(y, z, 0, D.db2lin(float(dbl["db"])))
	if fx.has("echo"):
		var ec: Dictionary = fx["echo"]
		var src := y
		y = src.duplicate()
		var gap := int(roundf(float(ec["steps"]) * step_s * D.sr))
		for r in int(ec.get("repeats", 1)):
			D.mix_at(y, src, gap * (r + 1), D.db2lin(float(ec["db"]) * float(r + 1)))
	return y


func _slap(x: PackedFloat32Array, sb: Dictionary) -> PackedFloat32Array:
	if sb.is_empty():
		return x
	var y := x.duplicate()
	D.mix_at(y, x, int(roundf(float(sb["ms"]) / 1000.0 * D.sr)), D.db2lin(float(sb["db"])))
	return y


## v2.0: the sidechain. The channel ducks by `db` under every hit of `hits` in the `by` channel's
## events: a `attackMs` ramp down, held for `holdMs`, then an exponential `releaseMs` back; it wraps.
func _duck(x: PackedFloat32Array, by_ev: Array, by_step_s: float, dk: Dictionary, loop_n: int) -> PackedFloat32Array:
	var n := x.size()
	var g := PackedFloat32Array()
	g.resize(n)
	g.fill(1.0)
	var floor_g := D.db2lin(float(dk["db"]))
	var att := maxi(1, int(float(dk.get("attackMs", 3.0)) / 1000.0 * D.sr))
	var hold := int(float(dk.get("holdMs", 20.0)) / 1000.0 * D.sr)
	var rel := float(dk.get("releaseMs", 140.0)) / 1000.0 * D.sr
	var want: Array = dk["hits"]
	for s in by_ev.size():
		var e: Variant = by_ev[s]
		if e == null or not (e as Dictionary).has("hits"):
			continue
		if not (e["hits"] as Array).any(func(h: String) -> bool: return want.has(h)):
			continue
		# the hit, and its copy one loop later (the tail past bar 32 folds back onto bar 1)
		for at: int in [int(roundf(s * by_step_s * D.sr)), int(roundf(s * by_step_s * D.sr)) + loop_n]:
			for i in range(maxi(0, at - att), mini(n, at + hold + int(rel * 5.0))):
				var t := i - at
				var v: float
				if t < 0:
					v = 1.0 + (floor_g - 1.0) * float(t + att) / att
				elif t < hold:
					v = floor_g
				else:
					v = 1.0 - (1.0 - floor_g) * exp(-float(t - hold) / rel)
				g[i] = minf(g[i], v)
	for i in n:
		x[i] *= g[i]
	return x


## v2.1: a {thresholdDb, ratio, attackMs, releaseMs} compressor (a channel's `comp`, a stem's `busComp`).
func _comp(x: PackedFloat32Array, cp: Dictionary) -> PackedFloat32Array:
	return D.compress(x, float(cp["thresholdDb"]), float(cp["ratio"]), float(cp["attackMs"]), float(cp["releaseMs"]))


# ================================================================== era tracks

func _render_era(eid: String, e: Dictionary, target: float) -> Dictionary:
	var rate := int(e["rate"])
	D.set_rate(rate)
	var step_s := 60.0 / float(e["tempoBpm"]) / float(e["stepsPerBeat"])
	var step_n := step_s * rate
	if absf(step_n - roundf(step_n)) > 1e-6:
		push_error("gen_od_sevev: %s step is %.4f samples at %d Hz, not whole" % [eid, step_n, rate])
		return {}
	var spb := int(e["stepsPerBeat"]) * int(e["beatsPerBar"])
	var sec_bars := int(_m["form"]["sectionBars"])
	var loop_n := int(_m["form"]["totalBars"]) * spb * int(roundf(step_n))
	var stems := {}
	var sends := {}
	var sent := {}
	for layer: String in LAYERS:
		stems[layer] = D.zeros(loop_n + int(TAIL_S * rate))
		sends[layer] = D.zeros(loop_n + int(TAIL_S * rate))
	# pass 1: every channel's events (v2.0: the 808's sidechain reads the kick's)
	var evs := {}
	var steps := {}
	for cid: String in e["channels"]:
		var ch: Dictionary = e["channels"][cid]
		var bars: PackedStringArray = []
		var secs: PackedStringArray = []
		for sec: String in ORDER:
			var sbars: Array = ch["sections"][sec]
			for i in sec_bars:
				bars.append(String(sbars[i % sbars.size()]))
				secs.append(sec)
		evs[cid] = _compile(bars, ch, secs, 0)
		# music v2.0: a channel may run on its own grid (the trap hats: 24 steps a beat, for rolls)
		steps[cid] = 60.0 / float(e["tempoBpm"]) / float(ch.get("stepsPerBeat", e["stepsPerBeat"]))
	for cid: String in e["channels"]:
		var ch: Dictionary = e["channels"][cid]
		var ev: Array = evs[cid]
		var ch_step_s: float = steps[cid]
		var x := D.zeros(loop_n + int(TAIL_S * rate))
		_render_events(ev, ch_step_s, x, "%s/%s" % [eid, cid])
		x = _channel_fx(x, ev, ch.get("fx", {}), ch_step_s, "%s/%s" % [eid, cid])
		x = _slap(x, e.get("slapback", {}))
		if ch.has("eq"):
			x = D.eq(x, ch["eq"])   # v2.1: the channel's EQ
		if ch.has("comp"):
			x = _comp(x, ch["comp"])
		if ch.has("duck"):
			var dk: Dictionary = ch["duck"]
			x = _duck(x, evs[dk["by"]], steps[dk["by"]], dk, loop_n)
		D.mix_at(stems[ch["layer"]], x, 0, float(ch["gain"]))
		if OS.get_environment("OD_AUDIO_CHANNELS") != "":
			_dump("chan_%s_%s.res" % [eid, cid], x.slice(0, loop_n), float(ch["gain"]), rate)   # v2.1: mix by channel
		if ch.has("reverb"):
			D.mix_at(sends[ch["layer"]], x, 0, float(ch["gain"]) * D.db2lin(float(ch["reverb"])))
			sent[ch["layer"]] = true
	# v2.0: one reverb per layer (Freeverb, the send high-passed so the low end stays dry), then the
	# bus clipper (the drum-bus glue of a trap mix: L0's peaks rounded before the stems are scaled)
	var rv: Dictionary = e.get("reverb", {})
	for layer: String in LAYERS:
		if not rv.is_empty() and sent.has(layer):
			var snd := D.eq(sends[layer], [{"type": "highpass", "freq": float(rv.get("hpHz", 250.0)), "Q": -3.0103}])
			var wet := D.reverb(snd, float(rv["size"]), float(rv["damp"]))
			D.mix_at(stems[layer], wet, int(roundf(float(rv.get("predelayMs", 0.0)) / 1000.0 * rate)), 1.0)
		# v2.1, the stem master: EQ, glue compression, then the clipper
		var se: Dictionary = e.get("stemEq", {})
		if se.has(layer):
			stems[layer] = D.eq(stems[layer], se[layer])
		var sg: Dictionary = e.get("busComp", {})
		if sg.has(layer):
			stems[layer] = _comp(stems[layer], sg[layer])
		var bc: Dictionary = e.get("busClip", {})
		if bc.has(layer):
			D.soft_clip(stems[layer], float(bc[layer]))
	var pk := 0.0
	for layer: String in LAYERS:
		var y := D.loop_wrap(stems[layer], loop_n)
		y.append(y[0])
		stems[layer] = y
		pk = maxf(pk, D.peak(y))
	var scale := PEAK / maxf(pk, 1e-9)
	var full := D.zeros(loop_n)
	for layer: String in LAYERS:
		D.mix_at(full, (stems[layer] as PackedFloat32Array).slice(0, loop_n), 0, scale)
	var lf := _lufs_int(full, rate)
	var play_db := snappedf(target - lf, 0.01)
	var sum_pk := D.lin2db(D.peak(full)) + play_db
	var info := {"key": e["key"], "mode": e["mode"], "tempoBpm": e["tempoBpm"], "rate": rate, "stepsPerBar": spb, "beatsPerBar": int(e["beatsPerBar"]),
		"stepSamples": int(roundf(step_n)), "barSamples": spb * int(roundf(step_n)), "loopSamples": loop_n,
		"loopSeconds": snappedf(float(loop_n) / rate, 0.0001), "play_db": play_db, "layers": {}, "lufs": {"full": snappedf(lf + play_db, 0.01)},
		"sumPeakDbfs": snappedf(sum_pk, 0.01)}
	if e.has("tapLine"):
		info["tapLine"] = e["tapLine"]   # v1.10: the tap's melody (the runtime plays it note by note)
	for layer: String in LAYERS:
		var name := "music_%s_%s.res" % [eid, layer]
		var bytes := _save(stems[layer], scale, rate, name, loop_n)
		if bytes < 0:
			return {}
		_bytes["music"] += bytes
		_count["music"] += 1
		var solo := (stems[layer] as PackedFloat32Array).slice(0, loop_n)
		var ll := _lufs_int(solo, rate) + D.lin2db(scale) + play_db
		info["layers"][layer] = name
		info["lufs"][layer] = snappedf(ll, 0.01)
		_dump(name, solo, scale * D.db2lin(play_db), rate)
	print("  era %-11s %s %s %3d BPM @ %d Hz  loop %.2f s  full %+.2f LUFS -> play %+.2f dB  (L0 %.1f  L1 %.1f  L2 %.1f)  sum peak %+.2f dBFS" % [
		eid, e["key"], e["mode"], int(e["tempoBpm"]), rate, float(loop_n) / rate, lf, play_db,
		info["lufs"]["L0"], info["lufs"]["L1"], info["lufs"]["L2"], sum_pk])
	if e.has("outside"):
		var o: Dictionary = e["outside"]
		var obars: PackedStringArray = []
		for b: String in o["bars"]:
			obars.append(b)
		var oev := _compile(obars, o, PackedStringArray(), 0)
		var on := obars.size() * spb * int(roundf(step_n))
		var ox := D.zeros(on + int(TAIL_S * rate))
		_render_events(oev, step_s, ox, "%s/outside" % eid)
		var oy := D.loop_wrap(ox, on)
		oy.append(oy[0])
		var oscale := PEAK / maxf(D.peak(oy), 1e-9)
		# the Outside level: -14 LU under L0 as heard, i.e. after the bus's 800 Hz low-pass
		var spec: Dictionary = _m["outside"]
		var lp := D._biquad(oy.slice(0, on), {"type": "lowpass", "freq": float(spec["lpfHz"]), "Q": -3.0103}, float(on) / rate)
		var l0 := float(info["lufs"]["L0"])
		var o_db := snappedf(l0 + float(spec["underL0Db"]) - (_lufs_int(lp, rate) + D.lin2db(oscale)), 0.01)
		var oname := "music_%s_outside.res" % eid
		var ob := _save(oy, oscale, rate, oname, on)
		if ob < 0:
			return {}
		_bytes["outside"] += ob
		_count["outside"] += 1
		var downs: Array = []
		for b in obars.size():
			for beat: int in [0, 2]:
				downs.append((b * spb + beat * int(e["stepsPerBeat"])) * int(roundf(step_n)))
		info["outside"] = {"file": oname, "loopSamples": on, "play_db": o_db, "judgeSamples": downs,
			"_doc": "judgeSamples: tap-to-beat targets inside the Outside loop (beats 1 and 3 of each bar)."}
		_dump(oname, oy.slice(0, on), oscale * D.db2lin(o_db), rate)
		print("  outside    %d bars, play %+.2f dB (-14 LU under L0 after the 800 Hz low-pass)" % [obars.size(), o_db])
	return info


# ================================================================== stingers

func _key_semis(written: String, key: String) -> int:
	var s := posmod(int(PCS[key]) - int(PCS[written]), 12)
	return s - 12 if s > 6 else s


func _render_stinger(sid: String, st: Dictionary, target: Dictionary) -> Dictionary:
	var out := {"bus": st["bus"], "files": {}}
	var pk := 0.0
	var bufs := {}   # name -> [buffer, rate, musical samples]
	var keys: Array = st["keys"]
	for key: String in keys:
		var kd: Dictionary = _c["keys"][key]
		var era: Dictionary = _m["eras"][kd["era"]]
		var rate := int(st.get("rate", era["rate"]))
		D.set_rate(rate)
		var step_s := 60.0 / float(kd["tempoBpm"]) / float(st["stepsPerBeat"])
		var semis := _key_semis(String(st.get("writtenIn", "D")), key)
		var lengths: Array = []
		if st.has("tags"):
			for k: Variant in st["tags"]:
				lengths.append(int(st["baseSteps"]) + int(k) * int(st["tagSteps"]))
		else:
			var n := 0
			for cid: String in st["channels"]:
				var tt := 0
				for b: String in st["channels"][cid]["bars"]:
					tt += b.split(" ", false).size()
				n = maxi(n, tt)
			lengths.append(n)
		for li in lengths.size():
			var cut: int = lengths[li]
			var n_samples := int(roundf(cut * step_s * rate))
			var buf := D.zeros(n_samples + int(1.2 * rate))
			for cid: String in st["channels"]:
				var ch: Dictionary = st["channels"][cid]
				var bars: PackedStringArray = []
				for b: String in ch["bars"]:
					bars.append(b)
				var ev := _compile(bars, ch, PackedStringArray(), semis)
				var x := D.zeros(buf.size())
				_render_events(ev, step_s, x, "%s/%s/%s" % [sid, key, cid], cut)
				D.mix_at(buf, _slap(x, st.get("slapback", {})), 0, float(ch["gain"]))
			# trim the silent tail (the last sample above -80 dBFS relative, plus 10 ms)
			var end := buf.size() - 1
			var floor_ := D.peak(buf) * 0.0001
			while end > n_samples and absf(buf[end]) < floor_:
				end -= 1
			buf = buf.slice(0, mini(buf.size(), end + int(0.01 * rate)))
			var name := ("stinger_%s_%s.res" % [sid, key]) if lengths.size() == 1 else ("stinger_%s_%s_t%d.res" % [sid, key, li])
			buf = _clean(buf, rate)
			bufs[name] = [buf, rate, n_samples, key, li]
			pk = maxf(pk, D.peak(buf))
	var scale := PEAK / maxf(pk, 1e-9)
	var meas := -200.0
	for name: String in bufs:
		var b: Array = bufs[name]
		var l := _measure(target, b[0], int(b[1]))
		meas = maxf(meas, l)
	var play_db := float(target["lufs"]) - meas - D.lin2db(scale)
	var ceil_db := float(_c["ceilings"][st["bus"]]) - D.lin2db(PEAK)
	out["limitedBy"] = "ceiling" if play_db > ceil_db else "target"
	play_db = snappedf(minf(play_db, ceil_db), 0.01)
	var names: Array = bufs.keys()
	names.sort()
	for name: String in names:
		var b: Array = bufs[name]
		var bytes := _save(b[0], scale, int(b[1]), name, -1)
		if bytes < 0:
			return {}
		_bytes["stingers"] += bytes
		_count["stingers"] += 1
		var key := String(b[3])
		if not out["files"].has(key):
			out["files"][key] = {}
		var entry := {"file": name, "rate": b[1], "musicalSamples": b[2], "musicalSeconds": snappedf(float(b[2]) / int(b[1]), 0.0001)}
		if st.has("markerSteps"):
			# markers in seconds from the stinger's start (the animator anchors visuals to them)
			var sps := 60.0 / float(_c["keys"][key]["tempoBpm"]) / float(st["stepsPerBeat"])
			var mk := {}
			for mid: String in st["markerSteps"]:
				mk[mid] = snappedf(int(st["markerSteps"][mid]) * sps, 0.0001)
			var onsets: Array = []
			for i in int(b[4]):
				onsets.append(snappedf((int(st["baseSteps"]) + i * int(st["tagSteps"])) * sps, 0.0001))
			mk["tagOnsets"] = onsets
			mk["fanfareEnd"] = entry["musicalSeconds"]
			entry["markers"] = mk
		out["files"][key][str(b[4]) if st.has("tags") else "_"] = entry
		_dump(name, b[0], scale * D.db2lin(play_db), int(b[1]))
	out["play_db"] = play_db
	out["target"] = target
	print("  stinger %-10s %2d files  play %+.2f dB  (%s %.1f, %s)" % [sid, names.size(), play_db, target["type"], float(target["lufs"]), out["limitedBy"]])
	return out


# ================================================================== cues

func _key_root(key: String, octave: int) -> int:
	return (octave + 1) * 12 + int(PCS[key])


## The pitches of a cue: [{key, pitch, ratio}] (key "_" and pitch "_" when unused).
func _pitches(cue: Dictionary) -> Array:
	var p: Dictionary = cue["pitch"]
	var out: Array = []
	var keys: Dictionary = _c["keys"]
	match String(p["type"]):
		"none":
			out.append({"key": "_", "pitch": "_", "ratio": 1.0})
		"key":
			for k: String in keys:
				if k.begins_with("_"):
					continue
				out.append({"key": k, "pitch": "_", "ratio": _hz(_key_root(k, int(p["rootOctave"]))) / _a4})
		"degrees":
			for k: String in keys:
				if k.begins_with("_"):
					continue
				var msc: Array = _c["modes"][keys[k]["mode"]]
				for dg: String in p["degrees"]:
					for o: Variant in p["octaves"]:
						# the label's number is a scale step of the key's mode ("3" = the mode's third)
						var pc := posmod(int(PCS[k]) + int(msc[int(dg.trim_prefix("b")) - 1]), 12)
						out.append({"key": k, "pitch": "%s_%d" % [dg, int(o)], "ratio": _hz((int(o) + 1) * 12 + pc) / _a4})
	return out


## v1.6 mix pass: a one-shot's clean-up. A DC blocker (one-pole high-pass, 20 Hz) and a 1.5 ms
## raised-cosine fade-in, so no cue starts on a step (the measured onsets reached -19 dBFS at
## sample 0: a click on a phone speaker). Loops (the music stems) never pass through here.
func _clean(x: PackedFloat32Array, rate: int) -> PackedFloat32Array:
	var y := PackedFloat32Array()
	y.resize(x.size())
	var k := exp(-TAU * 20.0 / rate)
	var prev_x := 0.0
	var prev_y := 0.0
	for i in x.size():
		prev_y = x[i] - prev_x + k * prev_y
		prev_x = x[i]
		y[i] = prev_y
	var nf := mini(y.size(), int(0.0015 * rate))
	for i in nf:
		y[i] *= 0.5 - 0.5 * cos(PI * float(i) / float(nf))
	return y


func _render_one(key: String, layers: Array, ratio: float) -> PackedFloat32Array:
	var end := 0.0
	for L: Dictionary in layers:
		end = maxf(end, D.layer_end(L))
	var out := D.zeros(int(ceil((end + 0.004) * D.sr)))
	for li in layers.size():
		var L: Dictionary = layers[li]
		D.mix_at(out, D.render_layer(L, ratio, 0.0, D.rng_for(key, 1, li), _a4), int(roundf(float(L.get("delay", 0.0)) * D.sr)))
	return out


func _render_cue(id: String, cue: Dictionary, man: Dictionary) -> Dictionary:
	var rate := int(_c["rate"])
	D.set_rate(rate)
	var bufs := {}
	var tree := {}
	var pk := 0.0
	var longest := 0.0
	for P: Dictionary in _pitches(cue):
		for v: String in cue["variants"]:
			var x := _render_one("%s/%s/%s/%s" % [id, P["key"], P["pitch"], v], cue["variants"][v], float(P["ratio"]))
			var parts: PackedStringArray = [id]
			for s: String in [String(P["key"]), String(P["pitch"]), v]:
				if s != "_" and s != "":
					parts.append(s)
			var name := "_".join(parts) + ".res"
			x = _clean(x, rate)
			bufs[name] = x
			pk = maxf(pk, D.peak(x))
			longest = maxf(longest, x.size() * 1000.0 / rate)
			var kk := String(P["key"])
			var pp := String(P["pitch"])
			var vv := v if v != "" else "_"
			if not tree.has(kk):
				tree[kk] = {}
			if not tree[kk].has(pp):
				tree[kk][pp] = {}
			tree[kk][pp][vv] = name
	var scale := PEAK / maxf(pk, 1e-9)
	var tg: Dictionary = cue["target"]
	var play_db := 0.0
	match String(tg["type"]):
		"momentary", "burst":
			var win := 0.4 if tg["type"] == "momentary" else 0.1
			var m := -200.0
			for n: String in bufs:
				m = maxf(m, _lufs_max(bufs[n], rate, win))
			play_db = float(tg["lufs"]) - m - D.lin2db(scale)
		"stream", "shortTerm":
			# a stream at rateHz through every file in order: the loudness of the steady stream
			var names: Array = bufs.keys()
			names.sort()
			var hz := float(tg["rateHz"])
			var secs := 12.0 if tg["type"] == "stream" else 3.2
			var s := D.zeros(int(secs * rate) + rate)
			var i := 0
			while i / hz < secs:
				D.mix_at(s, bufs[names[i % names.size()]], int(i / hz * rate))
				i += 1
			var l := _lufs_int(s.slice(0, int(secs * rate)), rate) if tg["type"] == "stream" else _lufs_max(s, rate, 3.0)
			play_db = float(tg["lufs"]) - l - D.lin2db(scale)
		"relative":
			var other: Dictionary = man["cues"][tg["to"]]
			var m := -200.0
			for n: String in bufs:
				m = maxf(m, _lufs_max(bufs[n], rate, 0.1))
			play_db = float(other["burstMax"]) + float(tg["db"]) - m - D.lin2db(scale)
	var ceil_db := float(_c["ceilings"][cue["bus"]]) - D.lin2db(PEAK)
	var limited := "ceiling" if play_db > ceil_db else "target"
	play_db = snappedf(minf(play_db, ceil_db), 0.01)
	var mmax := -200.0
	var bmax := -200.0
	var names2: Array = bufs.keys()
	names2.sort()
	for n: String in names2:
		mmax = maxf(mmax, _lufs_max(bufs[n], rate, 0.4) + D.lin2db(scale) + play_db)
		bmax = maxf(bmax, _lufs_max(bufs[n], rate, 0.1) + D.lin2db(scale) + play_db)
		var bytes := _save(bufs[n], scale, rate, n, -1)
		if bytes < 0:
			return {}
		_bytes["sfx"] += bytes
		_count["sfx"] += 1
		_dump(n, bufs[n], scale * D.db2lin(play_db), rate)
	var info := {"meaning": cue["meaning"], "bus": cue["bus"], "priority": cue["priority"], "poly": cue["poly"],
		"steal": cue["steal"], "ducks": cue["ducks"], "play_db": play_db, "momentaryMax": snappedf(mmax, 0.01), "burstMax": snappedf(bmax, 0.01), "limitedBy": limited,
		"lengthMs": snappedf(longest, 0.1), "files": tree, "runtime": cue.get("runtime", ""), "target": tg}
	for k: String in ["jitterDb", "pan", "shapes", "markers", "firstSound", "melody", "phrases"]:
		if cue.has(k):
			info[k] = cue[k]
	print("  cue %-16s %3d files  play %+7.2f dB  burst %+6.2f  M-max %+6.2f LUFS  %5.0f ms  %s" % [id, bufs.size(), play_db, bmax, mmax, longest, limited])
	return info


# ================================================================== loudness (ITU-R BS.1770-4, dual mono)

func _kweight(x: PackedFloat32Array, rate: int) -> PackedFloat64Array:
	var y := PackedFloat64Array()
	y.resize(x.size())
	# stage 1: high shelf +4 dB at 1681.97 Hz; stage 2: RLB high-pass at 38.14 Hz (pyloudnorm's design)
	var st := [[3.99984385397, 0.7071752369554193, 1681.9744509555319, true], [0.0, 0.5003270373253953, 38.13547087613982, false]]
	for i in x.size():
		y[i] = x[i]
	for s: Array in st:
		var w0 := TAU * float(s[2]) / rate
		var al := sin(w0) / (2.0 * float(s[1]))
		var cw := cos(w0)
		var b0: float
		var b1: float
		var b2: float
		var a0: float
		var a1: float
		var a2: float
		if s[3]:
			var A := pow(10.0, float(s[0]) / 40.0)
			var sq := 2.0 * sqrt(A) * al
			b0 = A * ((A + 1) + (A - 1) * cw + sq)
			b1 = -2 * A * ((A - 1) + (A + 1) * cw)
			b2 = A * ((A + 1) + (A - 1) * cw - sq)
			a0 = (A + 1) - (A - 1) * cw + sq
			a1 = 2 * ((A - 1) - (A + 1) * cw)
			a2 = (A + 1) - (A - 1) * cw - sq
		else:
			b0 = (1 + cw) / 2
			b1 = -(1 + cw)
			b2 = (1 + cw) / 2
			a0 = 1 + al
			a1 = -2 * cw
			a2 = 1 - al
		b0 /= a0
		b1 /= a0
		b2 /= a0
		a1 /= a0
		a2 /= a0
		var z1 := 0.0
		var z2 := 0.0
		for i in y.size():
			var xi := y[i]
			var yi := b0 * xi + z1
			z1 = b1 * xi - a1 * yi + z2
			z2 = b2 * xi - a2 * yi
			y[i] = yi
	return y


## Mean square of every block (win seconds, 75% overlap = hop of win/4 for 0.4 s; 0.1 s for 3 s).
func _blocks(x: PackedFloat32Array, rate: int, win: float) -> PackedFloat64Array:
	var k := _kweight(x, rate)
	var n := int(win * rate)
	var hop := int(minf(0.1, win / 4.0) * rate)
	var cum := PackedFloat64Array()
	cum.resize(k.size() + 1)
	cum[0] = 0.0
	for i in k.size():
		cum[i + 1] = cum[i] + k[i] * k[i]
	var out := PackedFloat64Array()
	if k.size() < n:
		out.append(cum[k.size()] / n)   # a short file: one block, zero-padded
		return out
	var i0 := 0
	while i0 + n <= k.size():
		out.append((cum[i0 + n] - cum[i0]) / n)
		i0 += hop
	return out


func _ms2lufs(ms: float) -> float:
	return -0.691 + 10.0 * log(maxf(ms, 1e-20)) / log(10.0) + DUAL_MONO_DB


func _lufs_int(x: PackedFloat32Array, rate: int) -> float:
	var b := _blocks(x, rate, 0.4)
	var sum := 0.0
	var n := 0
	for z in b:
		if _ms2lufs(z) > -70.0:
			sum += z
			n += 1
	if n == 0:
		return -200.0
	var rel := _ms2lufs(sum / n) - 10.0
	sum = 0.0
	n = 0
	for z in b:
		var l := _ms2lufs(z)
		if l > -70.0 and l > rel:
			sum += z
			n += 1
	return _ms2lufs(sum / maxi(n, 1))


func _lufs_max(x: PackedFloat32Array, rate: int, win: float) -> float:
	var m := -200.0
	for z in _blocks(x, rate, win):
		m = maxf(m, _ms2lufs(z))
	return m


func _measure(target: Dictionary, x: PackedFloat32Array, rate: int) -> float:
	match String(target["type"]):
		"integrated":
			return _lufs_int(x, rate)
		"shortTerm":
			return _lufs_max(x, rate, 3.0)
		"burst":
			return _lufs_max(x, rate, 0.1)
		_:
			return _lufs_max(x, rate, 0.4)


# ================================================================== files

## QOA inside an AudioStreamWAV resource; loop_n >= 0 builds a forward loop (0, loop_n]. Returns the
## bytes written, or -1.
func _save(y: PackedFloat32Array, scale: float, rate: int, name: String, loop_n: int) -> int:
	var opts := {"compress/mode": 2, "edit/loop_mode": 2 if loop_n >= 0 else 1, "edit/loop_begin": 0,
		"edit/loop_end": loop_n if loop_n >= 0 else -1, "edit/trim": false, "edit/normalize": false,
		"force/mono": false, "force/8_bit": false, "force/max_rate": false}
	var w := AudioStreamWAV.load_from_buffer(D.wav_bytes(y, scale, rate), opts)
	var want_loop := AudioStreamWAV.LOOP_FORWARD if loop_n >= 0 else AudioStreamWAV.LOOP_DISABLED
	if w == null or w.format != AudioStreamWAV.FORMAT_QOA or w.loop_mode != want_loop or w.mix_rate != rate \
			or (loop_n >= 0 and w.loop_end != loop_n):
		push_error("gen_od_sevev: %s did not encode as expected" % name)
		return -1
	var path := OUT + name
	var err := ResourceSaver.save(w, path)
	if err != OK:
		push_error("gen_od_sevev: cannot save %s (%d)" % [path, err])
		return -1
	ResourceSaver.set_uid(path, _uid_for(name))
	_written[name] = true
	return FileAccess.get_file_as_bytes(path).size()


func _uid_for(name: String) -> int:
	var hi := hash("od-sevev/audio/" + name) & 0x7FFFFFFF
	var lo := hash(name + "/uid") & 0xFFFFFFFF
	return (hi << 32) | lo


func _dump(name: String, x: PackedFloat32Array, k: float, rate: int) -> void:
	if _preview == "":
		return
	D.save_wav(x, _preview.path_join(name.get_basename() + ".wav"), k, rate)
