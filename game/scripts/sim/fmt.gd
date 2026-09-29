class_name Fmt
extends RefCounted
## Number formatters (ux/number-and-copy.md §2). Display only: maths stays in raw doubles.
## Ported from v1.1 src/core/format.ts, plus a notation setting (v2): "letters" (K M B T, then
## AA AB ...), "scientific" (1.23e15) and "engineering" (123e12). Tiers are found by repeated
## comparison, never log10 alone (999.9999 edge errors).

const EPS := 1e-9

static var notation := "letters"


static func _nf() -> Dictionary:
	return Content.data()["numberFormat"]


static func suffix(tier: int) -> String:
	var sfx: Array = _nf()["suffixes"]
	if tier < sfx.size():
		return sfx[tier]
	var n := tier - sfx.size()
	return String.chr(65 + n / 26) + String.chr(65 + n % 26)


static func _tier_of(v: float) -> int:
	var t := 0
	while v >= pow(1000.0, t + 1) and t < 101:
		t += 1
	return t


static func _round_by(x: float, mode: String) -> float:
	var e := EPS * maxf(1.0, absf(x))
	match mode:
		"ceil":
			return ceilf(x - e)
		"floor":
			return floorf(x + e)
	return floorf(x + 0.5 + e)


static func _digits_int(m: float) -> int:
	return 1 if m < 10.0 else (2 if m < 100.0 else 3)


static func _fixed(v: float, d: int) -> String:
	return ("%." + str(d) + "f") % v


## `sig` significant digits with a suffix, rolling to the next tier when rounding reaches 1000.
static func _sig(v: float, sig: int, mode: String) -> String:
	if notation != "letters":
		return _exp(v, sig, mode)
	var t := _tier_of(v)
	for _guard in 3:
		var m := v / pow(1000.0, t)
		var d := maxi(0, sig - _digits_int(m))
		var p := pow(10.0, d)
		var r := _round_by(m * p, mode) / p
		if r >= 1000.0:
			t += 1
			continue
		var d2 := maxi(0, sig - _digits_int(r))
		if d2 < d:
			var p2 := pow(10.0, d2)
			r = _round_by(r * p2, mode) / p2
		return _fixed(r, d2) + suffix(t)
	return "MAX"


## Scientific (1.23E15) or engineering (123E12, exponent a multiple of 3).
static func _exp(v: float, sig: int, mode: String) -> String:
	if v <= 0.0:
		return "0"
	var e := 0
	while v >= pow(10.0, e + 1) and e < 400:
		e += 1
	while v < pow(10.0, e) and e > -400:
		e -= 1
	if notation == "engineering":
		e = e - posmod(e, 3)
	for _guard in 3:
		var m := v / pow(10.0, e)
		var d := maxi(0, sig - _digits_int(m))
		var p := pow(10.0, d)
		var r := _round_by(m * p, mode) / p
		var limit := 1000.0 if notation == "engineering" else 10.0
		if r >= limit:
			e += 3 if notation == "engineering" else 1
			continue
		return _fixed(r, d) + "E" + str(e)
	return "MAX"


static func _finite(v: float) -> bool:
	return is_finite(v) and v < Economy.MAX


## Top bar bank: floor; under 1M a full integer with separators; above, 4 significant digits.
static func bank(v: float) -> String:
	if not _finite(v):
		return "MAX"
	v = maxf(0.0, v)
	var b: Dictionary = _nf()["bank"]
	if v < float(b["fullIntegerBelow"]):
		return _group(int(floorf(v + EPS)), b["thousandsSeparator"])
	return _sig(v, int(b["significantDigitsAbove"]), "floor")


static func _group(n: int, sep: String) -> String:
	var s := str(n)
	var out := ""
	var c := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		c += 1
		if c % 3 == 0 and i > 0:
			out = sep + out
	return out


## Pill and silhouette cost: ceil at display precision, 3 significant digits.
static func cost(v: float) -> String:
	if not _finite(v):
		return "MAX"
	var sig := int(_nf()["significantDigits"])
	if v < 1000.0:
		var n := ceilf(v - EPS)
		return _sig(1000.0, sig, "ceil") if n >= 1000.0 else str(int(n))
	return _sig(v, sig, "ceil")


## bps: under 10 one decimal, under 1000 an integer, else 3 significant digits; round half-up.
static func rate(v: float) -> String:
	if not _finite(v):
		return "MAX"
	v = maxf(0.0, v)
	if v < 10.0:
		var r := _round_by(v * 10.0, "round") / 10.0
		if r < 10.0:
			return _fixed(r, 1)
	if v < 1000.0:
		var r2 := _round_by(v, "round")
		if r2 < 1000.0:
			return str(int(r2))
	return _sig(v, int(_nf()["significantDigits"]), "round")


## Floaters, Lucky Bunch, away amount: round; an integer below 1000. (Caller adds the "+".)
static func amount(v: float) -> String:
	if not _finite(v):
		return "MAX"
	v = maxf(0.0, v)
	if v < 1000.0:
		var r := _round_by(v, "round")
		if r < 1000.0:
			return str(int(r))
	return _sig(v, int(_nf()["significantDigits"]), "round")


## Thumbs: an exact integer below 10,000, then 3 significant digits.
static func thumbs(v: float, mode: String = "floor") -> String:
	if not _finite(v):
		return "MAX"
	if v < 10000.0:
		return str(int(floorf(v + EPS) if mode == "floor" else ceilf(v - EPS)))
	return _sig(v, int(_nf()["significantDigits"]), mode)


## Prestige multiplier: one decimal below 1000, then 3 significant digits. No "×".
static func mult(m: float) -> String:
	if not _finite(m):
		return "MAX"
	if m < 1000.0:
		var s := _fixed(_round_by(m * 10.0, "round") / 10.0, 1)
		if float(s) < 1000.0:
			return s
	return _sig(m, int(_nf()["significantDigits"]), "round")


## "BUY ×n": integer, display clamped to 999.
static func qty(n: int) -> String:
	return str(clampi(n, 0, 999))


## "OWNED n": integer, 3 significant digits above 99,999.
static func owned(n: int) -> String:
	if n <= 99999:
		return str(n)
	return _sig(float(n), int(_nf()["significantDigits"]), "floor")


## Away duration: "12M" below an hour, "3H 12M" above. The caller handles the cap.
static func dur(sec: float) -> String:
	var s := maxi(0, int(floorf(sec)))
	var m := s / 60
	if s < 3600:
		return "%dM" % maxi(1, m)
	if s < 86400:
		return "%dH %dM" % [s / 3600, (s % 3600) / 60]
	return "%dD %dH" % [s / 86400, (s % 86400) / 3600]


## Buff chip countdown: ceil seconds, "12S".
static func secs(sec: float) -> String:
	return "%dS" % maxi(0, int(ceilf(sec - EPS)))


## Stats playtime: "2H 05M 09S" / "5M 09S".
static func clock(sec: float) -> String:
	var s := maxi(0, int(floorf(sec)))
	if s >= 3600:
		return "%dH %02dM %02dS" % [s / 3600, (s % 3600) / 60, s % 60]
	return "%dM %02dS" % [s / 60, s % 60]
