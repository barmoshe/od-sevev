class_name ShareKit
extends RefCounted
## The share cards' pure model and the web share boundary (ux/first-minute.md §5, rtl-map §7.2
## O4 / O5, review R25; Bar 2026-09-29: WhatsApp is the main channel).
##
## - The site URL lives HERE, once: SITE_URL. The web build overrides it with OD_SITE_URL
##   (tools/build_web.sh writes the same value into the OG tags and `window.odSiteUrl`, which
##   site_url() reads), so the link on the card, in the share text and in the preview agree.
## - Share texts are prose (§5.3): Hebrew units ("4.2 מיליון"), no bidi isolates, the URL at the
##   end. wa_url() is `https://wa.me/?text=` + encodeURIComponent(text), byte for byte what the
##   browser's own encodeURIComponent gives (the unit test pins Hebrew, ₪ and the gershayim).
## - The receipt's amounts are fiction by design (§5.1 "Where the amounts come from"): the round's
##   income split by each source's share of the income, the coalition line = what the round paid
##   the partners, pistachio always 0 ₪. Rates and facts on the item names are real (the footnote).
## - JS: the shell's `window.odShare` (game/web/shell.html) does the platform work: navigator.share
##   with the PNG (the primary path), else download + clipboard; wa.me in a new tab on desktop and
##   the same URL in place on a phone (the app takes it). Results come back through
##   `window.odShareDone(kind, result)` → ShareKit.on_result.

const SITE_URL := "https://od-sevev.vercel.app/"
const WA := "https://wa.me/?text="
const LRI := "\u2066"
const PDI := "\u2069"
const FILE_RECEIPT := "od-sevev-kabala.png"
const FILE_RESULT := "od-sevev-tozaa.png"

static var _site := ""
static var _cb: JavaScriptObject          # kept alive: the shell calls window.odShareDone
static var _listener: Callable            # func(kind: String, result: String)


## The deployed origin (with a trailing slash): the build's OD_SITE_URL on the web, else SITE_URL.
static func site_url() -> String:
	if _site != "":
		return _site
	_site = SITE_URL
	if OS.has_feature("web"):
		var v: Variant = JavaScriptBridge.eval("(typeof window.odSiteUrl === 'string') ? window.odSiteUrl : ''", true)
		var u := str(v) if v != null else ""
		if u.begins_with("https://") or u.begins_with("http://"):
			_site = u if u.ends_with("/") else u + "/"
	return _site


## The URL as printed on a card: no scheme, no trailing slash ("od-sevev.vercel.app", 19 glyphs;
## RECEIPT_FOOT_URL's budget is 22).
static func display_host(url: String) -> String:
	var h := url
	for p in ["https://", "http://"]:
		if h.begins_with(p):
			h = h.substr(p.length())
	return h.trim_suffix("/")


## JS encodeURIComponent: UTF-8, every byte %XX (upper case) except A-Z a-z 0-9 - _ . ! ~ * ' ( ).
static func encode_uri_component(s: String) -> String:
	const KEEP := "-_.!~*'()"
	var out := ""
	for b: int in s.to_utf8_buffer():
		var ok := (b >= 0x30 and b <= 0x39) or (b >= 0x41 and b <= 0x5A) or (b >= 0x61 and b <= 0x7A) or KEEP.contains(char(b))
		out += char(b) if ok else "%%%02X" % b
	return out


## The WhatsApp link for a message (wa.me opens the app on a phone, WhatsApp Web on a desktop).
static func wa_url(text: String) -> String:
	return WA + encode_uri_component(text)


## Share prose: no bidi isolates (the string tables keep them for the canvas).
static func plain(s: String) -> String:
	return s.replace(LRI, "").replace(PDI, "")


## "4.2 מיליון", "850 אלף", "999" (FMT_WORD_*: Hebrew units in share prose, K/M/B is HUD-only).
static func word_amount(v: float) -> String:
	v = maxf(0.0, v)
	if v < 1000.0:
		return str(int(roundf(v)))
	var keys := ["FMT_WORD_K", "FMT_WORD_M", "FMT_WORD_B", "FMT_WORD_T"]
	var t := mini(int(floorf(log(v) / log(1000.0))), keys.size())
	var x := v / pow(1000.0, t)
	if x >= 999.95 and t < keys.size():
		t += 1
		x = v / pow(1000.0, t)
	var n := ("%.1f" % x).trim_suffix(".0") if x < 100.0 else str(int(roundf(x)))
	return plain(Strings.s(keys[t - 1], {"n": n}))


## The receipt's amount column (RECEIPT_AMOUNT {xr}): full grouping below 10,000,000, the bank
## format above.
static func receipt_amount(v: float) -> String:
	v = maxf(0.0, v)
	if v < 10000000.0:
		return Fmt._group(int(roundf(v)), ",")
	return Fmt.bank(v)


## "סבב בחירות אחד" / "3 סבבי בחירות" and "ואפס ימי משפט" / "ו־3 ימי משפט" (§5.2 ICU plurals).
static func rounds_days(s: GameState) -> Array:
	var rounds := maxi(0, s.evolutions)
	var days := court_days(s)
	return [Strings.plural("ROUNDS", rounds), Strings.plural("DAYS", days)]


static func court_days(s: GameState) -> int:
	return int((s.investigation if s.investigation is Dictionary else {}).get("courtDays", 0))


# ------------------------------------------------------------------ the receipt (O4, §5.1)

## {round, date, head, total, lines: [{key, label, amount}], countdown}: every value a string ready
## for its row (amounts through receipt_amount). `now_ms` is the resolved clock (the calendar).
static func receipt(s: GameState, d: Economy.Derived, now_ms: float) -> Dictionary:
	var income := maxf(0.0, s.run_bananas)
	var share := source_shares(d)
	var vat := income * float(share.get("vat", 0.0))
	var people := income * (float(share.get("taxpayer", 0.0)) + float(share.get("hitech", 0.0)))
	var fuel := people * 0.6
	var wing := people * 0.4
	var coalition := coalition_paid(s)
	var total := vat + fuel + wing + coalition
	var lines: Array = [
		{"key": "RECEIPT_VAT", "amount": receipt_amount(vat), "v": vat},
		{"key": "RECEIPT_FUEL", "amount": "", "v": fuel},
		{"key": "RECEIPT_FUEL_NOTE", "amount": receipt_amount(fuel), "v": fuel},
		{"key": "RECEIPT_WING", "amount": receipt_amount(wing), "v": wing},
		{"key": "RECEIPT_PISTACHIO", "amount": receipt_amount(0.0), "v": 0.0},
		{"key": "RECEIPT_COALITION", "amount": receipt_amount(coalition), "v": coalition},
	]
	return {"round": Strings.s("RECEIPT_ROUND", {"n": str(s.evolutions + 1), "date": date_of(now_ms)}),
		"total": total, "totalText": receipt_amount(total), "lines": lines,
		"countdown": countdown(now_ms)}


## Each producer's share of the round's income (its bps / the sum; {} with no income).
static func source_shares(d: Economy.Derived) -> Dictionary:
	var out := {}
	if d == null:
		return out
	var sum := 0.0
	for id: Variant in d.producer_bps:
		sum += maxf(0.0, float(d.producer_bps[id]))
	if sum <= 0.0:
		return out
	for id: Variant in d.producer_bps:
		out[str(id)] = maxf(0.0, float(d.producer_bps[id])) / sum
	return out


## What this round paid the partners: every paid line in the chat log (demands, ultimatums,
## rejoins, poaches; the log is cleared at each election, so it is the round's).
static func coalition_paid(s: GameState) -> float:
	var sum := 0.0
	var co: Dictionary = s.coalition if s.coalition is Dictionary else {}
	for m: Variant in co.get("chat", []):
		if m is Dictionary and ["paid", "deleted"].has(str(m.get("state", ""))) and Coalition.is_payable(m):
			sum += maxf(0.0, float(m.get("price", 0.0)))
	return sum


## "28.09.2026" on Israel's calendar day (the calendar's offsets).
static func date_of(now_ms: float) -> String:
	var off := Calendar.israel_offset_h(now_ms) if Calendar.active() else 3.0
	var dt := Time.get_datetime_dict_from_unix_time(int(floorf(now_ms / 1000.0 + off * 3600.0)))
	return "%02d.%02d.%d" % [int(dt["day"]), int(dt["month"]), int(dt["year"])]


## The countdown line (§5.1 variants): the day count, "היום" on the day, the after line.
static func countdown(now_ms: float) -> String:
	if not Calendar.active():
		return ""
	var n := Calendar.days_left(now_ms)
	if n < 0:
		return Strings.s("RECEIPT_COUNTDOWN_AFTER")
	if n == 0:
		return Strings.s("RECEIPT_COUNTDOWN_TODAY")
	return Strings.plural("RECEIPT_COUNTDOWN", n, {"d": str(n)})


# ------------------------------------------------------------------ the result card (O5, §5.2)

## {head, sub, stats}: the headline "שרדתי {rounds} {days}" (+ "בינתיים." at zero court days), the
## sub-line and the stat strip. Never a seat number (§5 global rule).
static func result(s: GameState) -> Dictionary:
	var rd := rounds_days(s)
	var head := Strings.s("RESULT_HEADLINE", {"rounds": rd[0], "days": rd[1]})
	if court_days(s) == 0:
		head += " " + Strings.s("RESULT_ZERO_TAG")
	var inv: Dictionary = s.investigation if s.investigation is Dictionary else {}
	return {"head": head, "sub": Strings.s("RESULT_SUB"),
		"stats": Strings.s("RESULT_STATS", {"s": str(s.golden_caught_lifetime), "n": str(int(inv.get("postponementsLifetime", 0)))})}


# ------------------------------------------------------------------ share texts (§5.3)

## kind: "receipt" | "result" | "invite". Prose with the URL at the end, no isolates.
static func share_text(kind: String, s: GameState, d: Economy.Derived, now_ms: float, url: String = "") -> String:
	var u := url if url != "" else site_url()
	match kind:
		"receipt":
			return plain(Strings.s("SHARE_TEXT_RECEIPT", {"amount": word_amount(float(receipt(s, d, now_ms)["total"])), "url": u}))
		"result":
			var rd := rounds_days(s)
			return plain(Strings.s("SHARE_TEXT_RESULT", {"rounds": plain(rd[0]), "days": plain(rd[1]), "url": u}))
	return plain(Strings.s("SHARE_TEXT_INVITE", {"url": u}))


# ------------------------------------------------------------------ the web boundary

## True where the shell's share helpers exist (the web build).
static func available() -> bool:
	return OS.has_feature("web") and bool(JavaScriptBridge.eval("typeof window.odShare === 'object'", true))


## Registers the result listener once: func(kind, result) with result "shared" | "cancel" |
## "fallback" (downloaded + link copied) | "saved" | "copied" | "whatsapp" | "fail".
static func listen(cb: Callable) -> void:
	_listener = cb
	if not OS.has_feature("web") or _cb != null:
		return
	_cb = JavaScriptBridge.create_callback(func(args: Array) -> void:
		var k := str(args[0]) if args.size() > 0 else ""
		var r := str(args[1]) if args.size() > 1 else ""
		on_result.call_deferred(k, r))
	var win := JavaScriptBridge.get_interface("window")
	if win != null:
		win.odShareDone = _cb


static func on_result(kind: String, result: String) -> void:
	if _listener.is_valid():
		_listener.call(kind, result)


static func _js_str(s: String) -> String:
	return JSON.stringify(s)


## The primary "לשתף": navigator.share({files: [png], text}) where the device can share files,
## else the PNG downloads and the text + URL go to the clipboard. Called inside the tap (Safari's
## user activation).
static func share_png(kind: String, png: PackedByteArray, file_name: String, text: String) -> void:
	if not OS.has_feature("web"):
		return
	JavaScriptBridge.eval("window.odShare && window.odShare.file(%s, %s, %s, %s)" % [_js_str(kind),
		_js_str(Marshalls.raw_to_base64(png)), _js_str(file_name), _js_str(text)], true)


## "לשמור תמונה": the PNG as a download.
static func save_png(kind: String, png: PackedByteArray, file_name: String) -> void:
	if not OS.has_feature("web"):
		return
	JavaScriptBridge.eval("window.odShare && window.odShare.save(%s, %s, %s)" % [_js_str(kind),
		_js_str(Marshalls.raw_to_base64(png)), _js_str(file_name)], true)


## "לשתף בוואטסאפ": wa.me with the text (a new tab on a desktop, in place on a phone).
static func whatsapp(kind: String, text: String) -> void:
	if not OS.has_feature("web"):
		return
	JavaScriptBridge.eval("window.odShare && window.odShare.whatsapp(%s, %s)" % [_js_str(kind), _js_str(wa_url(text))], true)
