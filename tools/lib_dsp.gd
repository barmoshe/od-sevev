extends RefCounted
## The chip-synth toolkit behind tools/gen_audio.gd and tools/gen_music.gd: an offline,
## sample-accurate emulation of the v1 Web Audio graph (src/audio/chip.ts, itself a port of
## audio/preview.html). One call renders one layer of the cues.json layer schema, so the
## generators read cues.json and music.json and never hand-copy a number.
##
## Adapted from ~/wandcraft/tools/lib_dsp.gd (the buffer, seeding, loop and WAV helpers), with
## the synthesis replaced by what the v1 chip does:
## - band-limited wavetable oscillators that start at phase 0: the pulse is chip.ts's
##   PeriodicWave (real[n] = 2/(n*PI)*sin(n*PI*duty), n = 1..64, normalised to a peak of 1);
##   square and triangle are the browser's native waves; one table per octave of partials,
##   picked per 32-sample block so nothing aliases (Chrome does the same)
## - the 15-bit LFSR noise buffer (long mode bit0^bit1, metal mode bit0^bit6), read at
##   clock / sample rate with linear interpolation from a seeded random offset
## - the crush staircase WaveShaper (round(x*H)/H), BEFORE the envelope
## - BiquadFilterNode with the Web Audio formulas (lowpass/highpass Q in dB, bandpass Q linear)
## - the AudioParam envelope: linear attack, exponential (0.0001 floor) or linear decay, hold,
##   release, then 0
## - sweeps (exp / lin / step over `glide`), stepped arpeggios, the delayed vibrato LFO (ramps in
##   over 50 ms) and the per-layer detune jitter
##
## Conventions: every signal is a mono PackedFloat32Array at the static `sr` (set_rate). All
## randomness comes from a RandomNumberGenerator the caller passes in, seeded per
## (key, variant, layer) with rng_for(), so two runs write the same bytes.

const FLOOR := 0.0001        # the exponential-ramp floor of chip.ts
const TABLE := 2048          # wavetable length (one period)
const CTRL := 32             # control-rate block: wavetable bucket and filter coefficients
const PC := {"C": -9, "D": -7, "E": -5, "F": -4, "G": -2, "A": 0, "B": 2}

static var sr: int = 44100
static var _tables: Dictionary = {}   # "wave|duty" -> Array of PackedFloat32Array (index b: 2^b partials)
static var _lfsr: Dictionary = {}     # tap -> PackedFloat32Array (one period)


# ================================================================== setup and units

static func set_rate(rate: int) -> void:
	sr = rate


## The random stream of one (key, variant, layer): seed = hash("key/variant/layer"). Adding or
## reordering a cue never changes another cue's bytes.
static func rng_for(key: String, variant: int, layer: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = hash("%s/%d/%d" % [key, variant, layer])
	return r


## A frequency: a number (Hz) or a note in scientific pitch ('A4' = a4, 'Bb3', 'C#5').
static func to_hz(v: Variant, a4 := 440.0) -> float:
	if typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT:
		return float(v)
	var s := String(v)
	var semis: int = PC[s.substr(0, 1)]
	var i := 1
	if s.length() > 2 and (s[1] == "#" or s[1] == "b"):
		semis += 1 if s[1] == "#" else -1
		i = 2
	semis += (int(s.substr(i)) - 4) * 12
	return a4 * pow(2.0, semis / 12.0)


static func db2lin(db: float) -> float:
	return pow(10.0, db / 20.0)


static func lin2db(v: float) -> float:
	return 20.0 * log(maxf(absf(v), 1e-12)) / log(10.0)


# ================================================================== buffers

static func zeros(n: int) -> PackedFloat32Array:
	var b := PackedFloat32Array()
	b.resize(maxi(0, n))
	b.fill(0.0)
	return b


## Adds `src` into `dst` at sample `at`, times the linear gain k (what falls past the end drops).
static func mix_at(dst: PackedFloat32Array, src: PackedFloat32Array, at: int, k := 1.0) -> void:
	var end := mini(src.size(), dst.size() - at)
	for i in range(maxi(0, -at), end):
		dst[at + i] += src[i] * k


static func peak(x: PackedFloat32Array) -> float:
	var m := 0.0
	for v in x:
		m = maxf(m, absf(v))
	return m


## Root mean square of a buffer (0 for an empty one).
static func rms(x: PackedFloat32Array) -> float:
	if x.is_empty():
		return 0.0
	var s := 0.0
	for v in x:
		s += v * v
	return sqrt(s / x.size())


## A loop of L samples from a stationary bed rendered longer than L: the first m samples
## crossfade (equal power) with the m samples past L, so the seam continues the bed.
static func loop_xfade(a: PackedFloat32Array, L: int, m: int) -> PackedFloat32Array:
	var y := a.slice(0, L)
	var k := mini(m, a.size() - L)
	for i in k:
		var t := float(i) / k
		y[i] = a[i] * sqrt(t) + a[L + i] * sqrt(1.0 - t)
	return y


## A loop of L samples from a longer render whose tail rings past L: the tail wraps to the start
## (the song plays after itself, so notes ringing over the seam continue, as in v1's scheduler).
static func loop_wrap(a: PackedFloat32Array, L: int) -> PackedFloat32Array:
	var y := a.slice(0, L)
	for i in range(L, a.size()):
		y[(i - L) % L] += a[i]
	return y


## 16-bit PCM bytes of a float buffer times a linear gain (round to nearest, clamped).
static func pcm16(x: PackedFloat32Array, k := 1.0) -> PackedByteArray:
	var bytes := PackedByteArray()
	bytes.resize(x.size() * 2)
	for i in x.size():
		bytes.encode_s16(i * 2, clampi(int(roundf(x[i] * k * 32767.0)), -32768, 32767))
	return bytes


## Writes a mono 16-bit WAV (times a linear gain) at `rate` (the current sr when 0).
static func save_wav(x: PackedFloat32Array, path: String, k := 1.0, rate := 0) -> void:
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate if rate > 0 else sr
	w.stereo = false
	w.data = pcm16(x, k)
	w.save_to_wav(path)


## A mono 16-bit RIFF/WAVE file in memory (AudioStreamWAV.load_from_buffer reads it, which is
## how gen_music QOA-encodes a stem without a temp file).
static func wav_bytes(x: PackedFloat32Array, k := 1.0, rate := 0) -> PackedByteArray:
	var pcm := pcm16(x, k)
	var r := rate if rate > 0 else sr
	var h := PackedByteArray()
	h.resize(44)
	h.encode_u32(0, 0x46464952)      # "RIFF"
	h.encode_u32(4, 36 + pcm.size())
	h.encode_u32(8, 0x45564157)      # "WAVE"
	h.encode_u32(12, 0x20746d66)     # "fmt "
	h.encode_u32(16, 16)
	h.encode_u16(20, 1)              # PCM
	h.encode_u16(22, 1)              # mono
	h.encode_u32(24, r)
	h.encode_u32(28, r * 2)
	h.encode_u16(32, 2)
	h.encode_u16(34, 16)
	h.encode_u32(36, 0x61746164)     # "data"
	h.encode_u32(40, pcm.size())
	h.append_array(pcm)
	return h


# ================================================================== sources

## Fourier coefficients (cos, sin) of partial n of a wave, as the browser defines them.
static func _coef(wave: String, duty: float, n: int) -> Vector2:
	match wave:
		"pulse":
			return Vector2((2.0 / (n * PI)) * sin(n * PI * duty), 0.0)
		"square":
			return Vector2(0.0, 4.0 / (n * PI)) if n % 2 == 1 else Vector2.ZERO
		"triangle":
			if n % 2 == 0:
				return Vector2.ZERO
			var sgn := 1.0 if ((n - 1) / 2) % 2 == 0 else -1.0
			return Vector2(0.0, sgn * 8.0 / (PI * PI * n * n))
		_:
			return Vector2(0.0, 1.0) if n == 1 else Vector2.ZERO


## The highest partial bucket (2^cap partials): 64 for the pulse (chip.ts builds its
## PeriodicWave from 64 coefficients), 256 for the native waves (beyond it they are under -60 dB).
static func _cap(wave: String) -> int:
	match wave:
		"pulse":
			return 6
		"sine":
			return 0
		_:
			return 8


## The band-limited tables of a wave: index b holds 2^b partials. Every table is scaled by the
## richest one's peak (a normalised PeriodicWave, peak 1.0), as Chrome does.
static func _wave_tables(wave: String, duty: float) -> Array:
	var key := "%s|%s" % [wave, duty]
	if _tables.has(key):
		return _tables[key]
	var cap := _cap(wave)
	var tabs: Array = []
	tabs.resize(cap + 1)
	var acc := zeros(TABLE + 1)
	var done := 0
	for b in cap + 1:
		var h := 1 << b
		for n in range(done + 1, h + 1):
			var c := _coef(wave, duty, n)
			if c == Vector2.ZERO:
				continue
			for i in TABLE:
				var ph := TAU * n * i / TABLE
				acc[i] += c.x * cos(ph) + c.y * sin(ph)
		done = h
		acc[TABLE] = acc[0]
		tabs[b] = acc.duplicate()
	var norm := 1.0 / maxf(peak(tabs[cap]), 1e-9)
	for b in cap + 1:
		var t: PackedFloat32Array = tabs[b]
		for i in t.size():
			t[i] *= norm
		tabs[b] = t
	_tables[key] = tabs
	return tabs


## One period of the 15-bit LFSR (chip.ts lfsr): tap 1 = long mode, tap 6 = short ("metal").
static func _lfsr_buf(tap: int) -> PackedFloat32Array:
	if _lfsr.has(tap):
		return _lfsr[tap]
	var s := 1
	var v := PackedFloat32Array()
	while true:
		v.append(-1.0 if s & 1 else 1.0)
		var fb := (s & 1) ^ ((s >> tap) & 1)
		s = (s >> 1) | (fb << 14)
		if s == 1 or v.size() >= 40000:
			break
	_lfsr[tap] = v
	return v


# ================================================================== one layer

## Renders one cues.json layer (chip.ts ChipAudio.layer): from the layer's own start (the
## caller places it at cue start + delay) to the end of its release. `ratio` multiplies
## followPitch frequencies, `note_sec` is the length of a music note (duration 'note'), `cents`
## an extra constant detune (variant colour for otherwise deterministic cues).
static func render_layer(L: Dictionary, ratio: float, note_sec: float, rng: RandomNumberGenerator,
		a4 := 440.0, cents := 0.0) -> PackedFloat32Array:
	var attack := maxf(float(L.get("attack", 0.0)), 0.0005)
	var decay := float(L.get("decay", 0.0))
	var sustain := float(L.get("sustain", 0.0))
	var release := maxf(float(L.get("release", 0.0)), 0.002)
	var dv: Variant = L.get("duration", 0.0)
	var dur := note_sec if typeof(dv) == TYPE_STRING else float(dv)
	dur = maxf(dur, attack + decay)
	var t_end := dur + release
	var n := int(ceil(t_end * sr)) + 1
	var wave := String(L["wave"])
	var is_noise := wave == "noise" or wave == "noiseMetal"
	var follow: bool = L.get("followPitch", not is_noise)
	var k := ratio if follow else 1.0
	var det := cents
	if L.has("detuneJitterSemis"):
		det += (rng.randf() * 2.0 - 1.0) * float(L["detuneJitterSemis"]) * 100.0
	var x: PackedFloat32Array
	if is_noise:
		x = _noise(L, k * pow(2.0, det / 1200.0), n, dur, rng, 6 if wave == "noiseMetal" else 1)
	else:
		x = _osc(L, wave, k, n, dur, t_end, a4, det)
	if L.has("crush"):
		var h := float(1 << (int(L["crush"]) - 1))
		for i in n:
			x[i] = floorf(clampf(x[i], -1.0, 1.0) * h + 0.5) / h
	if L.has("filter"):
		x = _biquad(x, L["filter"], dur)
	var lin := String(L.get("envCurve", "exp")) == "lin"
	_env_in(x, float(L.get("gain", 1.0)), attack, decay, sustain, dur, release, lin)
	return x


## The end of a layer relative to its cue's start, in seconds (delay + duration + release).
static func layer_end(L: Dictionary, note_sec := 0.0) -> float:
	var attack := maxf(float(L.get("attack", 0.0)), 0.0005)
	var dv: Variant = L.get("duration", 0.0)
	var dur := note_sec if typeof(dv) == TYPE_STRING else float(dv)
	dur = maxf(dur, attack + float(L.get("decay", 0.0)))
	return float(L.get("delay", 0.0)) + dur + maxf(float(L.get("release", 0.0)), 0.002)


static func _osc(L: Dictionary, wave: String, k: float, n: int, dur: float, t_end: float, a4: float, det: float) -> PackedFloat32Array:
	var f0 := to_hz(L["freqStart"], a4) * k
	var f := zeros(n)
	var srf := float(sr)
	if L.has("arpeggio"):
		var arp: Array = L["arpeggio"]
		var rate := float(L["arpRateHz"])
		var loop: bool = L.get("arpLoop", true)
		var fs := PackedFloat32Array()
		for s in arp:
			fs.append(f0 * pow(2.0, float(s) / 12.0))
		var m := arp.size()
		for i in n:
			var st := int(floor(i / srf * rate + 1e-9))
			f[i] = fs[st % m] if loop else fs[mini(st, m - 1)]
	elif L.has("freqEnd"):
		var f1 := to_hz(L["freqEnd"], a4) * k
		var glide := float(L.get("glide", 0.0))
		if glide <= 0.0:
			glide = dur
		var gn := int(roundf(glide * srf))
		var curve := String(L.get("freqCurve", "exp"))
		var v := f0
		var mul := pow(f1 / f0, 1.0 / maxf(1.0, gn))
		for i in n:
			if i >= gn:
				f[i] = f1
			elif curve == "lin":
				f[i] = f0 + (f1 - f0) * i / gn
			elif curve == "step":
				f[i] = f0
			else:
				f[i] = v
				v *= mul
	else:
		f.fill(f0)
	if det != 0.0:
		var dk := pow(2.0, det / 1200.0)
		for i in n:
			f[i] *= dk
	if L.has("vibrato"):
		var vb: Dictionary = L["vibrato"]
		var vrate := float(vb["rateHz"])
		var depth := float(vb["depthCents"])
		var vd := int(roundf(float(vb.get("delay", 0.0)) * srf))
		var vr := maxf(1.0, minf(0.05 * srf, t_end * srf - vd))
		for i in range(vd, n):
			var d := depth * minf(1.0, (i - vd) / vr)
			f[i] *= exp(d * sin(TAU * vrate * i / srf) * 0.000577622650466621)   # ln(2)/1200
	var tabs := _wave_tables(wave, float(L.get("duty", 0.5)))
	var cap := tabs.size() - 1
	var nyq := srf * 0.5
	var x := zeros(n)
	var ph := 0.0
	var i := 0
	while i < n:
		var hm := nyq / maxf(f[i], 1.0)
		var b := 0
		while b < cap and float(2 << b) <= hm:
			b += 1
		var tb: PackedFloat32Array = tabs[b]
		var end := mini(i + CTRL, n)
		while i < end:
			var p := ph * TABLE
			var j := int(p)
			var fr := p - j
			x[i] = tb[j] + (tb[j + 1] - tb[j]) * fr
			ph += f[i] / srf
			ph -= floorf(ph)
			i += 1
	return x


static func _noise(L: Dictionary, k: float, n: int, dur: float, rng: RandomNumberGenerator, tap: int) -> PackedFloat32Array:
	var buf := _lfsr_buf(tap)
	var m := buf.size()
	var r0 := float(L["clockStart"]) / sr * k
	var r1 := float(L.get("clockEnd", L["clockStart"])) / sr * k
	var glide := float(L.get("glide", 0.0))
	var gn := int(roundf((glide if glide > 0.0 else dur) * sr))
	var pos := rng.randf() * m
	var x := zeros(n)
	for i in n:
		var j := int(pos)
		var a := buf[j]
		x[i] = a + (buf[(j + 1) % m] - a) * (pos - j)
		var r := r0
		if r1 != r0:
			r = r1 if i >= gn else r0 * pow(r1 / r0, float(i) / gn)
		pos += r
		if pos >= m:
			pos -= m
	return x


## Web Audio BiquadFilterNode coefficients [b0, b1, b2, a1, a2] (normalised by a0).
static func _coefs(type: String, fc: float, q: float) -> PackedFloat32Array:
	var w0 := TAU * minf(fc, sr * 0.5 - 1.0) / sr
	var cw := cos(w0)
	var sw := sin(w0)
	var b0: float
	var b1: float
	var b2: float
	var alpha: float
	if type == "bandpass":
		alpha = sw / (2.0 * q)
		b0 = alpha
		b1 = 0.0
		b2 = -alpha
	else:
		alpha = sw / (2.0 * pow(10.0, q / 20.0))   # lowpass/highpass: Q is resonance in dB
		if type == "highpass":
			b0 = (1.0 + cw) * 0.5
			b1 = -(1.0 + cw)
		else:
			b0 = (1.0 - cw) * 0.5
			b1 = 1.0 - cw
		b2 = b0
	var a0 := 1.0 + alpha
	return PackedFloat32Array([b0 / a0, b1 / a0, b2 / a0, -2.0 * cw / a0, (1.0 - alpha) / a0])


static func _biquad(x: PackedFloat32Array, F: Dictionary, dur: float) -> PackedFloat32Array:
	var type := String(F["type"])
	var q := float(F.get("Q", 0.7))
	var f0 := float(F["freq"])
	var f1 := float(F.get("freqEnd", 0.0))
	var sweep := f1 > 0.0
	var dn := maxf(1.0, dur * sr)
	var n := x.size()
	var y := zeros(n)
	var z1 := 0.0
	var z2 := 0.0
	var c := _coefs(type, f0, q)
	var i := 0
	while i < n:
		if sweep:
			c = _coefs(type, f0 * pow(f1 / f0, minf(1.0, i / dn)), q)
		var b0 := c[0]
		var b1 := c[1]
		var b2 := c[2]
		var a1 := c[3]
		var a2 := c[4]
		var end := mini(i + CTRL, n)
		while i < end:
			var xi := x[i]
			var yi := b0 * xi + z1
			z1 = b1 * xi - a1 * yi + z2
			z2 = b2 * xi - a2 * yi
			y[i] = yi
			i += 1
	return y


## The chip.ts envelope, in place: 0 -> peak (linear, attack), -> peak*sustain (exponential to
## the 0.0001 floor, or linear) over decay, held to `dur`, -> floor (or 0) over release, then 0.
static func _env_in(x: PackedFloat32Array, pk: float, attack: float, decay: float, sustain: float,
		dur: float, release: float, lin: bool) -> void:
	var srf := float(sr)
	var n := x.size()
	var na := attack * srf
	var nd := (attack + decay) * srf
	var nh := dur * srf
	var ne := (dur + release) * srf
	var s_level := pk * sustain
	var hold := s_level if lin else maxf(s_level, FLOOR)
	var dmul := pow(hold / pk, 1.0 / maxf(1.0, decay * srf))
	var rmul := pow(FLOOR / hold, 1.0 / maxf(1.0, release * srf))
	var g := pk
	var r := hold
	for i in n:
		var fi := float(i)
		var e: float
		if fi < na:
			e = pk * fi / na
		elif fi < nd:
			if lin:
				e = pk + (s_level - pk) * (fi - na) / (nd - na)
			else:
				e = g
				g *= dmul
		elif fi < nh:
			e = hold
		elif fi < ne:
			if lin:
				e = s_level * (1.0 - (fi - nh) / (ne - nh))
			else:
				e = r
				r *= rmul
		else:
			e = 0.0
		x[i] *= e
