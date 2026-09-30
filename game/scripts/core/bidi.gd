class_name Bidi
extends RefCounted
## Hebrew/RTL text helpers (ux/first-minute.md §3.5, engine/feasibility.md U6). The engine never
## reorders text itself: TextServer (TextServerAdvanced, ICU bidi) does, and these helpers only
## insert the Unicode controls it honours.
##
## The number rule: every number shown inside Hebrew text is an LTR token wrapped in
## LRI…PDI (U+2066…U+2069), so "+1.2K", "58/61", "−5" and "0:45" never flip their sign or order.
## A price is `LRI 12.4K PDI NBSP ₪`: the number first in reading order, then the shekel sign,
## which an RTL line shows visually to the LEFT of the number ("₪ 12.4K").

const LRI := "\u2066"
const RLI := "\u2067"
const FSI := "\u2068"
const PDI := "\u2069"
const LRM := "\u200e"
const RLM := "\u200f"
const NBSP := "\u00a0"
const SHEKEL := "₪"
const MINUS := "−"
## Controls with no ink: the font gives them zero advance, the lint and tests skip them.
const CONTROLS := [LRI, RLI, FSI, PDI, LRM, RLM, "\u200b", "\u2060", "\u200c", "\u200d"]
## What a number token may contain: digits, separators, signs, the compact suffixes K M B T
## and the letter pairs after T (aa..zz), percent, times, colon, slash.
const _NUM_CHARS := "0123456789.,:/+-%" + MINUS + "×" + "KMBT"


## The UI's base direction. The game is Hebrew-only (ux A3); L.RTL (the layout mirror) reads it.
const UI_RTL := true


## The paragraph direction for a shaped string: RTL when it holds a Hebrew letter, or, in the RTL
## UI, when it is a price or an isolated token (so "LRI 12.4K PDI NBSP ₪" still shows "₪ 12.4K").
## Anything else (the fork's Latin copy) stays LTR.
static func paragraph_rtl(s: String) -> bool:
	if has_rtl(s):
		return true
	return UI_RTL and (s.contains(SHEKEL) or s.contains(LRI) or s.contains(FSI))


## An LTR number token: LRI + s + PDI. Idempotent.
static func num(s: String) -> String:
	if s.begins_with(LRI) and s.ends_with(PDI):
		return s
	return LRI + s + PDI


## A price in reading order: the isolated number, a no-break space, then ₪.
static func money(s: String) -> String:
	return num(s) + NBSP + SHEKEL


## True when the string holds a right-to-left letter (Hebrew block and presentation forms,
## Arabic ranges for safety).
static func has_rtl(s: String) -> bool:
	for i in s.length():
		var c := s.unicode_at(i)
		if (c >= 0x0590 and c <= 0x08FF) or (c >= 0xFB1D and c <= 0xFDFF) or (c >= 0xFE70 and c <= 0xFEFF):
			return true
	return false


## A number token: non-empty, made only of _NUM_CHARS (plus lowercase letter-pair suffixes after
## the digits, "1.23aa"), with at least one digit. Isolates and spaces around it are ignored.
static func is_number_token(s: String) -> bool:
	var t := strip_controls(s).strip_edges()
	if t == "":
		return false
	var digit := false
	for i in t.length():
		var ch := t[i]
		if ch >= "0" and ch <= "9":
			digit = true
		elif not _NUM_CHARS.contains(ch) and not (ch >= "a" and ch <= "z" and digit):
			return false
	return digit


## A purely numeric string (the only kind PxText's bitmap path may draw without bidi): number
## tokens, spaces and the shekel sign.
static func is_numeric(s: String) -> bool:
	var t := strip_controls(s).replace(NBSP, " ").replace(SHEKEL, " ")
	var any := false
	for part in t.split(" ", false):
		if not is_number_token(part):
			return false
		any = true
	return any


static func strip_controls(s: String) -> String:
	var out := s
	for c: String in CONTROLS:
		out = out.replace(c, "")
	return out


## Fills {key} placeholders. ux/ui-strings.json already isolates every numeric placeholder in
## its Hebrew strings (rtl-map §0: code must not add or strip isolates), so a placeholder that
## sits inside LRI/RLI/FSI…PDI is filled verbatim. Only a number placeholder left bare in an RTL
## template (content copy) is isolated, as a safety net. LTR templates are filled verbatim.
static func fill(template: String, params: Dictionary) -> String:
	if params.is_empty():
		return template
	var rtl := has_rtl(template)
	var out := ""
	var i := 0
	var depth := 0
	while i < template.length():
		var ch := template[i]
		if ch == LRI or ch == RLI or ch == FSI:
			depth += 1
		elif ch == PDI:
			depth = maxi(0, depth - 1)
		elif ch == "{":
			var j := template.find("}", i)
			if j > i:
				var k := template.substr(i + 1, j - i - 1)
				if params.has(k):
					var v := str(params[k])
					if rtl and depth == 0 and is_number_token(v):
						v = num(v)
					out += v
					i = j + 1
					continue
		out += ch
		i += 1
	return out


# ------------------------------------------------------------------ the glue (mobile-first §5.2.1)

## G2: the marks that close onto the word before them (a token made only of these).
const GLUE_CLOSE := ".,:;!?…)]״\"׳'"
## G3: the marks that open onto the word after them.
const GLUE_OPEN := "([„"
## G4 (weak): the magnitude words a number keeps.
const GLUE_MAGNITUDES := ["אלף", "אלפי", "מיליון", "מיליוני", "מיליארד", "מיליארדי", "טריליון"]


## mobile-first §5.2.1: the spaces inside a glued unit become U+00A0 (display time only), so the
## pager (which splits on U+0020) and TextServer (which does not break at U+00A0) keep the unit on
## one line. Strong glue: a currency sign with what it measures (G1), closing punctuation with the
## word before it (G2), opening punctuation with the word after it (G3). Weak glue (`weak`): a
## number with its magnitude word (G4). Spaces inside an LRI/RLI/FSI…PDI isolate are never
## touched. Idempotent (a glued unit has no U+0020 left to match).
static func glue(text: String, weak: bool = true) -> String:
	if not text.contains(" "):
		return text
	var n := text.length()
	# token boundaries: the U+0020 spaces outside any isolate
	var spaces: Array[int] = []
	var depth := 0
	for i in n:
		var ch := text[i]
		if ch == LRI or ch == RLI or ch == FSI:
			depth += 1
		elif ch == PDI:
			depth = maxi(0, depth - 1)
		elif ch == " " and depth == 0:
			spaces.append(i)
	if spaces.is_empty():
		return text
	var out := text
	# standalone quote tokens seen so far (odd = inside a pair); a quote opening the text counts
	var quotes := 1 if _only(strip_controls(text.substr(0, spaces[0])), "\"״") else 0
	var prev_start := 0
	for si in spaces.size():
		var i := spaces[si]
		var next_end := spaces[si + 1] if si + 1 < spaces.size() else n
		var prev := text.substr(prev_start, i - prev_start)
		var next := text.substr(i + 1, next_end - i - 1)
		prev_start = i + 1
		if prev == "" or next == "":
			continue
		var glue_it := false
		var nx := strip_controls(next)
		var pv := strip_controls(prev)
		if nx.begins_with(SHEKEL):
			glue_it = true                                    # G1: "100 ₪", "{price} ₪", "מיליון ₪"
		elif pv.ends_with(SHEKEL) and (next[0] == LRI or next[0] == FSI or next[0] == RLI or (nx != "" and nx[0] >= "0" and nx[0] <= "9")):
			glue_it = true                                    # G1: a prefix "₪ 15"
		elif _only(nx, GLUE_CLOSE) and not _only(nx, "\"״"):
			glue_it = true                                    # G2: "word ." / "word )"
		elif _only(pv, GLUE_OPEN):
			glue_it = true                                    # G3: "( word"
		elif _only(nx, "\"״") or _only(pv, "\"״"):
			# a standalone quote: the first of a pair opens (G3), the second closes (G2)
			if _only(pv, "\"״") and quotes % 2 == 1:
				glue_it = true
			elif _only(nx, "\"״") and quotes % 2 == 1:
				glue_it = true
		elif weak and _ends_with_digit(pv) and GLUE_MAGNITUDES.has(_strip_close(nx)):
			glue_it = true                                    # G4 (weak): "850.6 מיליארד"
		if _only(nx, "\"״"):
			quotes += 1
		if glue_it:
			out = out.substr(0, i) + NBSP + out.substr(i + 1)
	return out


## The glue's fallback (§5.2.1 "never lose text"): the weak joints of a unit opened back to spaces.
static func glue_strong(text: String) -> String:
	return glue(text, false)


static func _only(t: String, chars: String) -> bool:
	if t == "":
		return false
	for i in t.length():
		if not chars.contains(t[i]):
			return false
	return true


static func _ends_with_digit(t: String) -> bool:
	return t != "" and t[t.length() - 1] >= "0" and t[t.length() - 1] <= "9"


static func _strip_close(t: String) -> String:
	var e := t.length()
	while e > 0 and GLUE_CLOSE.contains(t[e - 1]):
		e -= 1
	return t.substr(0, e)
