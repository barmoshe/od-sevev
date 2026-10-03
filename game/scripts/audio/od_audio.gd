class_name OdAudio
extends RefCounted
## עוד סבב: the pure side of the sound runtime. No nodes, no players: every rule of
## audio/od/cue-spec.md that can be a function of numbers lives here, so the Audio autoload stays
## plumbing and the tests can check the rules without a sound card.
##
## Source of every number: res://assets/audio/od/od_manifest.json (the generator's output, see
## tools/gen_od_sevev.gd). If the cue spec and the manifest disagree, the manifest wins.

const MANIFEST := "res://assets/audio/od/od_manifest.json"
const DIR := "res://assets/audio/od/"

## v1.10 (Bar, 2026-10-03: "each tap is a note"): the tap plays the next note of the song the era is
## playing (the era's `tapLine`). After a pause this long, the next tap joins the note the music is on.
const TAP_REJOIN_MS := 2500.0
const TAP_JITTER_DB := 1.5
## The music's lead (L2) steps back while the player taps (the player plays the song now), over this
## long, and comes back at a bar line this long after the last tap.
const L2_STEP_BACK_MS := 120.0
const L2_REST_MS := 2000.0
## The phrases of a tap line are this many bars (compose_od TAP_PHRASE_BARS); the phrase bonus pays at
## most once in 1.5 of them.
const PHRASE_BARS := 2
## A stolen voice fades out over this long instead of stopping on a click.
const STEAL_FADE_MS := 30.0
## The fallback melody (HaTikva, `tap.melody`, for a manifest without tap lines): its root's octave.
const ANTHEM_OCTAVE := 5
const KEY_PC := {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}
## Dubi (cue-spec §4 `dubiBlip`): 8 syllables a second, a 1.6 s cap, a doubled canned line
## repeats its contour after 150 ms.
const BABBLE_RATE_HZ := 8.0
const BABBLE_CAP_S := 1.6
const BABBLE_DOUBLE_GAP_S := 0.15
## The settings slider: its default position is 0 dB, so the offline calibration holds.
const SLIDER_DEFAULT := 1.0
const OFF_DB := -80.0


static var _man: Dictionary = {}


## The manifest, parsed once ({} when the generator has not run).
static func manifest() -> Dictionary:
	if _man.is_empty() and FileAccess.file_exists(MANIFEST):
		var v: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
		_man = v if v is Dictionary else {}
	return _man


# ------------------------------------------------------------------ files

## A value from a manifest file tree, trying the exact key and then "_" at each level.
static func _pick(tree: Variant, k: String) -> Variant:
	if not (tree is Dictionary):
		return null
	var d: Dictionary = tree
	if d.has(k):
		return d[k]
	return d.get("_")


## The file of a cue: `cues.<id>.files[<key>][<pitch>][<variant>]`, "_" standing for "not used".
## An unknown variant falls back to "_" or the first one listed, so a new partner id plays the
## cue's default rather than nothing. "" when the cue or the key has no file.
static func cue_file(man: Dictionary, cue_id: String, key: String, pitch := "_", variant := "_") -> String:
	var cue: Dictionary = man.get("cues", {}).get(cue_id, {})
	var by_pitch: Variant = _pick(_pick(cue.get("files", {}), key), pitch)
	if not (by_pitch is Dictionary) or (by_pitch as Dictionary).is_empty():
		return ""
	var d: Dictionary = by_pitch
	var f: Variant = d.get(variant, d.get("_", d.get("default")))
	if f == null:
		f = d.values()[0]
	return String(f)


## The variant names a cue has in a key (for a pitch), sorted.
static func cue_variants(man: Dictionary, cue_id: String, key := "_", pitch := "_") -> Array[String]:
	var cue: Dictionary = man.get("cues", {}).get(cue_id, {})
	var by_pitch: Variant = _pick(_pick(cue.get("files", {}), key), pitch)
	var out: Array[String] = []
	if by_pitch is Dictionary:
		for k: String in by_pitch:
			out.append(k)
	out.sort()
	return out


## A stinger's entry `{file, rate, musicalSamples, markers?}` in a key; tags picks the fanfare
## length (0-4), "_" for the one-length stingers. Falls back to the stinger's only key.
static func stinger_entry(man: Dictionary, id: String, key: String, tags := "_") -> Dictionary:
	var files: Dictionary = man.get("stingers", {}).get(id, {}).get("files", {})
	var by_key: Variant = files.get(key)
	if by_key == null and files.size() == 1:
		by_key = files.values()[0]
	var e: Variant = _pick(by_key, tags)
	return e if e is Dictionary else {}


## Every file the manifest names (cues, stingers, stems, the Outside loop), for the tests.
static func all_files(man: Dictionary) -> Array[String]:
	var out: Array[String] = []
	var walk := func(self_ref: Callable, v: Variant) -> void:
		if v is String:
			if String(v).ends_with(".res") and not out.has(v):
				out.append(v)
		elif v is Dictionary:
			for k: String in v:
				self_ref.call(self_ref, v[k])
	for id: String in man.get("cues", {}):
		walk.call(walk, man["cues"][id].get("files", {}))
	for id: String in man.get("stingers", {}):
		for key: String in man["stingers"][id].get("files", {}):
			for t: String in man["stingers"][id]["files"][key]:
				walk.call(walk, man["stingers"][id]["files"][key][t].get("file", ""))
	for era: String in man.get("eras", {}):
		walk.call(walk, man["eras"][era].get("layers", {}))
		walk.call(walk, man["eras"][era].get("outside", {}).get("file", ""))
	out.sort()
	return out


# ------------------------------------------------------------------ keys, eras, bars

## The key an era's track plays in ("D" Balfour, "E" Knesset, "G" Courthouse, "F" Washington).
static func era_key(man: Dictionary, era_id: String) -> String:
	return String(man.get("eras", {}).get(era_id, {}).get("key", "D"))


static func bar_seconds(man: Dictionary, era_id: String) -> float:
	var e: Dictionary = man.get("eras", {}).get(era_id, {})
	return float(e.get("barSamples", 66000)) / maxf(1.0, float(e.get("rate", 31900)))


static func loop_seconds(man: Dictionary, era_id: String) -> float:
	var e: Dictionary = man.get("eras", {}).get(era_id, {})
	return float(e.get("loopSamples", 2112000)) / maxf(1.0, float(e.get("rate", 31900)))


static func bars_per_loop(man: Dictionary, era_id: String) -> int:
	var e: Dictionary = man.get("eras", {}).get(era_id, {})
	return maxi(1, roundi(float(e.get("loopSamples", 2112000)) / maxf(1.0, float(e.get("barSamples", 66000)))))


# ------------------------------------------------------------------ the tap: the era's song

static func _ints(v: Variant) -> Array:
	var out: Array = []
	if v is Array:
		for x: Variant in v:
			out.append(int(x))   # JSON numbers load as floats
	return out


## The tap's melody for a track: {midi, steps, phrases, stepSeconds}. `steps` (note onsets from bar 1)
## is empty for the fallback (HaTikva in the track's key), which then never follows the music.
static func tap_line(man: Dictionary, track: String) -> Dictionary:
	var e: Dictionary = man.get("eras", {}).get(track, {})
	var tl: Variant = e.get("tapLine")
	if tl is Dictionary and not _ints((tl as Dictionary).get("midi")).is_empty():
		var ph := _ints(tl.get("phrases"))
		return {"midi": _ints(tl.get("midi")), "steps": _ints(tl.get("steps")), "phrases": ph if not ph.is_empty() else [0],
			"stepSeconds": float(e.get("stepSamples", 0)) / maxf(1.0, float(e.get("rate", 31900)))}
	var tap: Dictionary = man.get("cues", {}).get("tap", {})
	var root := (ANTHEM_OCTAVE + 1) * 12 + int(KEY_PC.get(era_key(man, track), 2))
	var mel: Array = []
	for lab: Variant in tap.get("melody", []):
		mel.append(root + int(String(lab).substr(1)))
	var ph2 := _ints(tap.get("phrases"))
	return {"midi": mel, "steps": [], "phrases": ph2 if not ph2.is_empty() else [0], "stepSeconds": 0.0}


## The step of the loop the music is on (`pos` seconds into it), for a line; -1 when it cannot follow.
static func song_step(line: Dictionary, pos: float) -> int:
	var ss := float(line.get("stepSeconds", 0.0))
	if ss <= 0.0 or (line.get("steps", []) as Array).is_empty() or pos < 0.0:
		return -1
	return int(floor(pos / ss + 1e-6))


## The phrase (an index into `phrases`) note `i` belongs to.
static func phrase_of(phrases: Array, i: int) -> int:
	var p := 0
	for k in phrases.size():
		if int(phrases[k]) <= i:
			p = k
	return p


## The first note at or after `step` (wrapping to note 0 past the last one).
static func note_at(steps: Array, step: int) -> int:
	for i in steps.size():
		if int(steps[i]) >= step:
			return i
	return 0


## The next tap on a line. `cur` is the last note played (-1: none yet), `run` how many notes of its
## phrase the player has played in one go from the phrase's first note (0: joined midway), `gap_ms`
## the time since the last tap, `music_step` the music's step (-1: no music to follow).
## - After a pause (or on the first tap) the tap joins the note the music is on.
## - Otherwise it is the next note. At a phrase's end, a tap more than a phrase ahead of the music, or
##   behind it, jumps to the start of the phrase the music plays.
## Returns {i, run, done}: done when this note ends a phrase the player played whole.
static func tap_next(line: Dictionary, cur: int, run: int, gap_ms: float, music_step: int) -> Dictionary:
	var midi: Array = line.get("midi", [])
	var steps: Array = line.get("steps", [])
	var ph: Array = line.get("phrases", [0])
	var n := midi.size()
	if n == 0:
		return {"i": -1, "run": 0, "done": false}
	var follow := music_step >= 0 and steps.size() == n
	var nxt := posmod(cur + 1, n)
	var cont := cur >= 0 and gap_ms <= TAP_REJOIN_MS
	if not cont and follow:
		nxt = note_at(steps, music_step)
	elif cont and follow and ph.has(nxt):
		var pm := 0   # the phrase the music plays: the last one that has started
		for k in ph.size():
			if int(steps[int(ph[k])]) <= music_step:
				pm = k
		if posmod(ph.find(nxt) - pm, ph.size()) > 1:
			nxt = int(ph[pm])
	var r := 0
	if ph.has(nxt):
		r = 1
	elif cont and run > 0 and nxt == posmod(cur + 1, n):
		r = run + 1
	var p := phrase_of(ph, nxt)
	var end_i := (int(ph[p + 1]) if p + 1 < ph.size() else n) - 1
	return {"i": nxt, "run": r, "done": nxt == end_i and r == end_i - int(ph[p]) + 1 and r >= 3}


## The bell roots the tap is rendered at (its variants r<midi>), low to high.
static func bell_roots(man: Dictionary) -> Array:
	var out: Array = []
	for v in cue_variants(man, "tap"):
		if v.begins_with("r") and v.substr(1).is_valid_int():
			out.append(int(v.substr(1)))
	out.sort()
	return out


## The bell root nearest a note (the lower one on a tie).
static func bell_root(roots: Array, note: int) -> int:
	var best := note
	var bd := 1 << 20
	for r: Variant in roots:
		var d := absi(int(r) - note)
		if d < bd:
			bd = d
			best = int(r)
	return best


## The pitch keys a cue is rendered at (in its first key), unsorted.
static func cue_pitches(man: Dictionary, cue_id: String) -> Array[String]:
	var files: Dictionary = man.get("cues", {}).get(cue_id, {}).get("files", {})
	var out: Array[String] = []
	if files.is_empty():
		return out
	var first: Variant = files.values()[0]
	if first is Dictionary:
		for k: String in first:
			out.append(k)
	return out


## Dubi's blip bank, low to high: the `dubiBlip` pitches ("<degree>_<octave>") ordered by the
## manifest's `degrees` table (semitones above the root) and the octave.
static func babble_bank(man: Dictionary) -> Array[String]:
	var degrees: Dictionary = man.get("degrees", {})
	var bank := cue_pitches(man, "dubiBlip")
	bank.sort_custom(func(a: String, b: String) -> bool: return _blip_semis(a, degrees) < _blip_semis(b, degrees))
	return bank


static func _blip_semis(k: String, degrees: Dictionary) -> float:
	var i := k.rfind("_")
	if i < 0:
		return 0.0
	return float(k.substr(i + 1).to_int()) * 12.0 + float(degrees.get(k.substr(0, i), 0.0))


# ------------------------------------------------------------------ anti-fatigue (O-A1)

## The layers the 4-loop cycle mutes in bar `bar` (1-based) of loop `loop` (1-based).
static func af_muted(man: Dictionary, loop: int, bar: int) -> Array[String]:
	var out: Array[String] = []
	var cycle: Array = man.get("antiFatigue", {}).get("cycle", [])
	if cycle.is_empty():
		return out
	var plan: Dictionary = cycle[posmod(loop - 1, cycle.size())]
	for m: Dictionary in plan.get("mute", []):
		var bars: Array = m.get("bars", [])
		if bars.size() == 2 and bar >= int(bars[0]) and bar <= int(bars[1]):
			out.append(String(m["layer"]))
	return out


## Whether a layer is heading to silence during bar `bar`: it is muted there, or muted from the
## next bar on (the fade out starts on the bar line before the muted bars; cue-spec §2.2). The
## fade back in is a normal layer-on at the first unmuted bar line.
static func af_off_during(man: Dictionary, layer: String, loop: int, bar: int, bars_in_loop := 32) -> bool:
	if af_muted(man, loop, bar).has(layer):
		return true
	var nb := bar + 1
	var nl := loop
	if nb > bars_in_loop:
		nb = 1
		nl = loop + 1
	return af_muted(man, nl, nb).has(layer)


# ------------------------------------------------------------------ the fanfare (A12)

## Tags for the n-th election (1-based): min(n - 1, 4). Round 1 has none.
static func fanfare_tags(election_number: int) -> int:
	return clampi(election_number - 1, 0, 4)


# ------------------------------------------------------------------ Dubi's babble (A13)

## Whether a character is voiced: a Hebrew letter, a Latin letter or a digit.
static func _voiced(c: String) -> bool:
	var u := c.unicode_at(0)
	return (u >= 0x05D0 and u <= 0x05EA) or (u >= 0x41 and u <= 0x5A) or (u >= 0x61 and u <= 0x7A) \
		or (u >= 0x30 and u <= 0x39)


static func _squash(t: String) -> String:
	var out := ""
	for c in t:
		if not " \t\n ".contains(c):
			out += c
	return out


## The canned line a text repeats, and how often: {line, times} or {} (babbleContours keys; a
## doubled line is the same line twice, spaces ignored).
static func canned_line(man: Dictionary, text: String) -> Dictionary:
	var sq := _squash(text)
	if sq == "":
		return {}
	for k: String in man.get("babbleContours", {}):
		if k.begins_with("_"):
			continue
		var ks := _squash(k)
		for n in [1, 2, 3]:
			if sq == ks.repeat(n):
				return {"line": k, "times": n}
	return {}


## The babble of a text, deterministic: {blips: [{t (s), bank ("5_6"...)}], length (s), canned}.
## Canned lines (babbleContours) play their contour, repeated after 150 ms for a doubled line.
## Anything else: one blip per ~2 voiced letters of each word at 8 a second, a rest after
## punctuation, pitch from the bank seeded by the text (an arch over each sentence, a rise at the
## end of a question), a final "!" one degree up, everything capped at 1.6 s.
static func babble_plan(man: Dictionary, text: String) -> Dictionary:
	var slot := 1.0 / BABBLE_RATE_HZ
	var bank := babble_bank(man)
	var blips: Array = []
	var t := 0.0
	var canned := canned_line(man, text)
	if not canned.is_empty():
		var contour: Array = man["babbleContours"][canned["line"]]
		for rep in int(canned["times"]):
			if rep > 0:
				t += BABBLE_DOUBLE_GAP_S
			for step: Variant in contour:
				var blip := "%s_%d" % [String(step[0]), int(step[1])]
				if t + slot <= BABBLE_CAP_S + 1e-6:
					blips.append({"t": t, "bank": blip})
				t += slot
		return {"blips": blips, "length": minf(t, BABBLE_CAP_S), "canned": true}
	# headlines and flash lines: syllables per word, sentences for the arch
	var words: Array = []   # {n (syllables), code (seed), rest (slots after), end ("" . ! ?)}
	var cur := 0
	var code := 0
	for c in text + " ":
		if _voiced(c):
			cur += 1
			code = (code * 31 + c.unicode_at(0)) % 1000003
		elif cur > 0 or ".!?,;:".contains(c):
			if cur > 0:
				words.append({"n": maxi(1, ceili(cur / 2.0)), "code": code, "rest": 0, "end": ""})
				cur = 0
				code = 0
			if ".!?".contains(c) and not words.is_empty():
				words[words.size() - 1]["rest"] = 2
				words[words.size() - 1]["end"] = c
			elif ",;:".contains(c) and not words.is_empty():
				words[words.size() - 1]["rest"] = maxi(1, int(words[words.size() - 1]["rest"]))
	if words.is_empty() or bank.is_empty():
		return {"blips": [], "length": 0.0, "canned": false}
	# sentence spans (by word index) for the arch
	var sent_of: Array[int] = []
	var sent_len: Array[int] = [0]
	var sent_q: Array[bool] = [false]
	for w: Dictionary in words:
		sent_of.append(sent_len.size() - 1)
		sent_len[sent_len.size() - 1] += int(w["n"])
		if String(w["end"]) != "":
			sent_q[sent_q.size() - 1] = w["end"] == "?"
			sent_len.append(0)
			sent_q.append(false)
	var seen := {}
	var top := bank.size() - 1
	var mid := float(top) / 2.0
	for wi in words.size():
		var w: Dictionary = words[wi]
		var s := sent_of[wi]
		for k in int(w["n"]):
			var j := int(seen.get(s, 0))
			seen[s] = j + 1
			var p := float(j) / maxf(1.0, float(sent_len[s] - 1))
			# a spread around the middle of the bank from the letters, an arch over the sentence,
			# a rise at the end of a question
			var spread := maxi(1, roundi(top * 0.4))
			var idx := roundi(mid) - spread / 2 + (int(w["code"]) + k * 7) % (spread + 1) + roundi(top * 0.2 * sin(PI * p))
			if sent_q[s] and p > 0.7:
				idx += maxi(1, roundi(top * 0.2))
			idx = clampi(idx, 0, top)
			if t + slot > BABBLE_CAP_S + 1e-6:
				break
			blips.append({"t": t, "bank": bank[idx]})
			t += slot
		t += slot * int(w["rest"])
		if t >= BABBLE_CAP_S:
			break
	if blips.is_empty():
		return {"blips": [], "length": 0.0, "canned": false}
	if text.strip_edges().ends_with("!"):
		var last: Dictionary = blips[blips.size() - 1]
		last["bank"] = bank[mini(bank.find(String(last["bank"])) + 1, top)]
	var length := float(blips[blips.size() - 1]["t"]) + slot
	return {"blips": blips, "length": minf(length, BABBLE_CAP_S), "canned": false}


# ------------------------------------------------------------------ mix

## The settings slider law: the default position is 0 dB (cue-spec §3), 0 is silence.
static func slider_db(slider: float, default_pos := SLIDER_DEFAULT) -> float:
	if slider <= 0.0001:
		return OFF_DB
	return linear_to_db(slider / maxf(0.0001, default_pos))


## The chat-ping variant of a partner id: the manifest's partner variants match ids with case,
## dashes and underscores ignored ("bengvir", "ben-gvir" -> benGvir); anyone else is "default".
static func ping_variant(man: Dictionary, partner: String) -> String:
	var want := partner.to_lower().replace("-", "").replace("_", "")
	for v: String in cue_variants(man, "chatPing", "D"):
		if v.to_lower() == want and v != "burst" and v != "left":
			return v
	return "default"


## A cue that may play before the player's first gesture (manifest `firstSound`: leaderPick,
## returnAway, wizardStep). It is held through a locked web context like the motif.
static func is_first_sound(man: Dictionary, cue_id: String) -> bool:
	return bool(man.get("cues", {}).get(cue_id, {}).get("firstSound", false))


# ------------------------------------------------------------------ leaders (leader-select §9.5)

## The react event a leader's crit plays on (content leaders[].kit.tap): `critEvent` when the kit
## names one; Bibi's rabbit crit (critAnim "crit" or the rabbit prop) is "rabbit"; else "land".
static func crit_event(tap_kit: Dictionary) -> String:
	var ev := String(tap_kit.get("critEvent", ""))
	if ev != "":
		return ev
	if String(tap_kit.get("critAnim", "crit")) == "crit" or String(tap_kit.get("critProp", "")) == "prop_rabbit":
		return "rabbit"
	return "land"


## The cue a react event plays {cue, variant}: the manifest's `crits` table (variant "roundRobin"
## for rabbitCrit's slide lengths). An unknown event plays "land"; a manifest without the table
## (pre-v1.3) plays rabbitCrit for everyone.
static func crit_cue(man: Dictionary, event: String) -> Dictionary:
	var t: Dictionary = man.get("crits", {})
	if t.is_empty():
		return {"cue": "rabbitCrit", "variant": "roundRobin"}
	var e: Variant = t.get(event, t.get("land", {}))
	return (e as Dictionary).duplicate() if e is Dictionary else {"cue": "rabbitCrit", "variant": "roundRobin"}


## Milliseconds from a crit's tap to its react event: the frame the strip marks for the event
## (sprites.json chars.<art>.anims.<anim>.events.<event>, entry at f1), `fallback` when unknown.
static func event_ms(sprites: Dictionary, art: String, anim: String, event: String, fallback: float) -> float:
	var a: Dictionary = sprites.get("chars", {}).get(art, {}).get("anims", {}).get(anim, {})
	var fps := float(a.get("fps", 0))
	var fr := int(a.get("events", {}).get(event, -1))
	if fps <= 0.0 or fr < 1:
		return fallback
	return float(fr - 1) * 1000.0 / fps


## The stamp variant of the n-th stamp (1-based): the bell on every 5th, otherwise identical.
static func stamp_variant(n: int) -> String:
	return "bell" if n > 0 and n % 5 == 0 else "_"


## Pink Front: the Outside low-pass cutoff k (0..1) of the way through its 2-bar sweep
## (exponential 800 -> 4000 Hz) and the boost in dB (linear 0 -> +8).
static func pink_cutoff(man: Dictionary, k: float) -> float:
	var sp: Dictionary = man.get("outsideSpec", {})
	var lo := float(sp.get("lpfHz", 800.0))
	var hi := float(sp.get("pinkFront", {}).get("lpfHz", 4000.0))
	return lo * pow(hi / lo, clampf(k, 0.0, 1.0))


static func pink_boost_db(man: Dictionary, k: float) -> float:
	return float(man.get("outsideSpec", {}).get("pinkFront", {}).get("boostDb", 8.0)) * clampf(k, 0.0, 1.0)


## Tap-to-beat: the signed distance (ms) from a song-clock position (samples inside the Outside
## loop) to the nearest judge beat (beats 1 and 3 of each bar), wrapping at the loop.
static func beat_offset_ms(pos_samples: float, judge: Array, loop_samples: float, rate: float) -> float:
	var best := INF
	for j: Variant in judge:
		for wrap: float in [-loop_samples, 0.0, loop_samples]:
			var d := pos_samples - (float(j) + wrap)
			if absf(d) < absf(best):
				best = d
	return best * 1000.0 / maxf(1.0, rate)
