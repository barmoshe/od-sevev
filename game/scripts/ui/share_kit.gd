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


## Court days plus press days (leader-neutral, like the DAYS_* words): every leader's days count.
static func court_days(s: GameState) -> int:
	return Investigation.hazard_days(s)


# ------------------------------------------------------------------ the receipt (O4, §5.1)

## {round, date, head, total, lines: [{key, label, amount}], countdown}: every value a string ready
## for its row (amounts through receipt_amount). `now_ms` is the resolved clock (the calendar).
static func receipt(s: GameState, d: Economy.Derived, now_ms: float) -> Dictionary:
	var income := maxf(0.0, s.run_money)
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
	# leader select (spec §10.1, rtl-map §4.3): the card names the round's leader under the headline
	var sub := Strings.s("LEADER_PICK_PLATE", {"short": LeaderUi.short(), "party": LeaderUi.party()}) if LeaderUi.short() != "" else Strings.s("RESULT_SUB")
	return {"head": head, "sub": sub,
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


# ================================================================== the share platform (Bar 2026-10-02)
# One entry point for every share: ShareKit.request(kind, model). On the web it opens the HTML share
# drawer (game/web/shell.html window.odShareUI) through main's ShareDesk, which pre-renders the card
# when the moment opens and hands the PNG to JS before the player's tap (Safari's user activation
# then only covers navigator.share). Off the web (desktop, the headless tests) the canvas sheet
# (ShareSheet) shows the same card. Kinds: leak, breaking, term, career, receipt, result, and the
# challenge agent's challenge / daily. The pure parts live here: the models, the copy, the links.
#
# The link: SITE + "s/<variant>/?via=<channel>#r=<ref>&k=<kind>[&<model.url_hash>]". The /s/ stub
# (tools/lib/gen_share_stubs.py) carries the variant's own og:title / og:image and forwards to the
# game with the query and the hash; the hash (never seen by a crawler) is read by the shell as
# window.odArrival = {kind, via, ref, params}.

## The leaders with stub variants (the playable roster; Gantz is the picker's decoy).
const STUB_LEADERS := ["bibi", "bennett", "bengvir", "deri", "eisenkot", "golan", "liberman", "smotrich"]
## Every outcome a leader stub exists for (the neutral `all-*` set is NEUTRAL_STUBS).
const STUB_OUTCOMES := ["61", "leak", "breaking", "term", "career", "challenge", "result"]
const NEUTRAL_STUBS := ["leak", "breaking", "term", "career", "receipt", "result", "challenge"]
## The drawer's tabs, in order (challenge / daily only when their model was passed in).
const DRAWER_KINDS := ["leak", "breaking", "term", "career", "receipt", "result", "challenge", "daily"]

## main's ShareDesk (ui/share_desk.gd), set when it is built: request() goes through it.
static var desk: Object


## THE API (the challenge / daily agent calls this): opens the share drawer on `kind` with `model`.
##   challenge: {leader, secs, seed, url_hash}  → the leader's head, the big time, "תעבור אותי?"
##   daily:     {n, grid_text, url_hash}         → "עוד סבב #N", the emoji grid as pixel squares,
##              and the text-only share is the grid text itself.
## `url_hash` ("s=123&t=452") is appended to the link's hash after r=<ref>&k=<kind>. Returns false
## when there is no desk (a tool scene) or the kind is unknown.
static func request(kind: String, model: Dictionary = {}) -> bool:
	if desk == null or not is_instance_valid(desk) or not DRAWER_KINDS.has(kind):
		return false
	return bool(desk.call("request", kind, model))


## "7:42", "1:02:03" (a run's clock; never a seat number).
static func fmt_time(sec: float) -> String:
	var s := maxi(0, int(floorf(sec)))
	if s >= 3600:
		return "%d:%02d:%02d" % [s / 3600, (s % 3600) / 60, s % 60]
	return "%d:%02d" % [s / 60, s % 60]


static func short_of(leader: String) -> String:
	return str(Leaders.leader(leader).get("short", "")) if leader != "" else ""


## The stub's variant path ("s/bibi-leak/", "s/all-term/", "s/daily/") for a kind / event.
static func stub_path(kind: String, leader: String, event: String = "", neutral: bool = false) -> String:
	if kind == "daily":
		return "s/daily/"
	var outcome := kind
	if kind == "breaking" and event == "gate":
		outcome = "61"
	if neutral or kind == "receipt" or not STUB_LEADERS.has(leader):
		if outcome == "61":
			outcome = "breaking"
		return "s/all-%s/" % (outcome if NEUTRAL_STUBS.has(outcome) else "result")
	return "s/%s-%s/" % [leader, outcome if STUB_OUTCOMES.has(outcome) else "result"]


## Every stub variant: "<leader>-<outcome>" | "all-<outcome>" | "daily" -> {leader, head} (the
## og:title, which is also the headline on its og:image). tools/og.sh renders one JPEG per name and
## tools/lib/gen_share_stubs.py writes one page per name (from the build's ui-strings + this list,
## exported to build/og-variants.json by tools/og.sh).
static func og_variants() -> Dictionary:
	var out := {}
	var heads := {"61": "OG_S_GATE", "leak": "OG_S_LEAK", "breaking": "OG_S_BREAKING", "term": "OG_S_TERM",
		"career": "OG_S_CAREER", "challenge": "OG_S_CHALLENGE", "result": "OG_S_RESULT"}
	for lid: String in STUB_LEADERS:
		for o: String in STUB_OUTCOMES:
			out["%s-%s" % [lid, o]] = {"leader": lid, "short": short_of(lid), "head": plain(Strings.s(heads[o], {"short": short_of(lid)}))}
	for o: String in NEUTRAL_STUBS:
		out["all-" + o] = {"leader": "", "head": plain(Strings.s("OG_N_" + o.to_upper()))}
	out["daily"] = {"leader": "", "head": plain(Strings.s("OG_DAILY"))}
	return out


## The og:title of a stub path ("s/bibi-leak/" → "הודלף מהקואליציה של ביבי").
static func og_head(stub: String) -> String:
	var v := stub.trim_prefix("s/").trim_suffix("/")
	return str(og_variants().get(v, {}).get("head", ""))


## The copy variants (string keys) for a kind: the rotation picks one (copy_line).
static func copy_keys(kind: String, event: String = "", neutral: bool = false) -> Array:
	match kind:
		"leak":
			return ["SHARE_LEAK_N1", "SHARE_LEAK_N2", "SHARE_LEAK_N3"] if neutral else ["SHARE_LEAK_1", "SHARE_LEAK_2", "SHARE_LEAK_3", "SHARE_LEAK_4"]
		"breaking":
			if neutral:
				return ["SHARE_BREAK_N1", "SHARE_BREAK_N2", "SHARE_BREAK_N3"]
			match event:
				"court":
					return ["SHARE_BREAK_COURT_1", "SHARE_BREAK_COURT_2"]
				"election":
					return ["SHARE_BREAK_ELECTION_1", "SHARE_BREAK_ELECTION_2"]
			return ["SHARE_BREAK_GATE_1", "SHARE_BREAK_GATE_2", "SHARE_BREAK_GATE_3"]
		"term":
			return ["SHARE_TERM_N1", "SHARE_TERM_N2"] if neutral else ["SHARE_TERM_1", "SHARE_TERM_2", "SHARE_TERM_3"]
		"career":
			return ["SHARE_CAREER_N1", "SHARE_CAREER_N2"] if neutral else ["SHARE_CAREER_1", "SHARE_CAREER_2", "SHARE_CAREER_3"]
		"challenge":
			return ["SHARE_CHAL_N1"] if neutral else ["SHARE_CHAL_1", "SHARE_CHAL_2"]
		"daily":
			return ["SHARE_DAILY"]
		"receipt":
			return ["SHARE_RECEIPT_2"]
		"result":
			return ["SHARE_RESULT_2"]
	return ["SHARE_TEXT_INVITE"]


## The share text (no link: the drawer adds "\n" + the link): the `rot`-th variant whose
## placeholders the params can fill, as plain prose (no bidi isolates).
static func copy_line(kind: String, params: Dictionary, rot: int = 0, event: String = "", neutral: bool = false) -> String:
	var keys := copy_keys(kind, event, neutral)
	for i in keys.size():
		var k: String = keys[posmod(rot + i, keys.size())]
		var raw := String(Strings.data()["strings"].get(k, ""))
		var ok := true
		for ph: String in _placeholders(raw):
			if ph == "url":
				continue
			if not params.has(ph) or str(params[ph]) == "":
				ok = false
				break
		if ok:
			return _no_url(plain(Strings.s(k, params)))
	return _no_url(plain(Strings.s(keys[0], params)))


static func _no_url(t: String) -> String:
	return t.replace(" {url}", "").replace("{url}", "").strip_edges()


static func _placeholders(t: String) -> Array:
	var out: Array = []
	var i := t.find("{")
	while i >= 0:
		var j := t.find("}", i)
		if j < 0:
			break
		out.append(t.substr(i + 1, j - i - 1))
		i = t.find("{", j)
	return out


## The message as sent: the text, then the link alone on the last line.
static func compose(text: String, link: String) -> String:
	return text.strip_edges() + "\n" + link


static func file_name(kind: String, fmt: String = "sq") -> String:
	if kind == "receipt" and fmt == "sq":
		return FILE_RECEIPT
	if kind == "result" and fmt == "sq":
		return FILE_RESULT
	return "od-sevev-%s%s.png" % [kind, "-story" if fmt == "story" else ""]


# ------------------------------------------------------------------ the models

## The model of a kind, for the card and the copy: {kind, leader, neutral, quiet, event, stub,
## text (rot-th variant), file, hash, ...the card's own fields}. `ext` is the caller's model (the
## challenge / daily agent's), `opts` {neutral, rot, event}.
static func model(kind: String, s: GameState, d: Economy.Derived, ext: Dictionary = {}, opts: Dictionary = {}) -> Dictionary:
	var neutral := bool(opts.get("neutral", false))
	var rot := int(opts.get("rot", 0))
	var quiet := Calendar.seats_numeral_hidden(s) if s != null and Calendar.active() else false
	var leader := str(ext.get("leader", s.leader if s != null else ""))
	var m := {"kind": kind, "leader": "" if neutral else leader, "neutral": neutral, "quiet": quiet, "event": ""}
	var params := {"short": short_of(leader)}
	match kind:
		"leak":
			m["lines"] = leak_lines(s, neutral)
			m["members"] = ChatView.group_size(s) if s != null else 0
		"breaking":
			var ev := str(opts.get("event", ext.get("event", breaking_event(s))))
			m["event"] = ev
			var gate := RoundLog.gate_sec(s) if s != null else -1.0
			if ev == "election" and s != null and not s.history.is_empty():
				var last: Dictionary = s.history[s.history.size() - 1]
				gate = float(last.get("gate", -1.0))
				if gate <= 0.0:
					gate = float(last.get("sec", 0.0))
				leader = str(last.get("leader", leader))
				params["short"] = short_of(leader)
				if not neutral:
					m["leader"] = leader
			var t := fmt_time(gate) if gate > 0.0 else ""
			params["time"] = t
			m["time"] = t
			var hk: String = {"gate": "BREAK_HEAD_GATE", "court": "BREAK_HEAD_COURT", "election": "BREAK_HEAD_ELECTION"}.get(ev, "BREAK_HEAD_GATE")
			if ev == "gate" and t == "":
				hk = "BREAK_HEAD_ELECTION"
			m["head"] = Strings.s(hk + ("_N" if neutral else ""), params)
			m["sub"] = Strings.s("BREAK_SUB_%d" % (posmod(rot, 4) + 1))
		"term":
			var rec := term_record(s, d)
			var tc := term_card(rec, neutral)
			params.merge(tc["params"], true)
			tc.erase("params")
			m.merge(tc, true)
			leader = str(rec.get("leader", leader))
			params["short"] = short_of(leader)
			if not neutral:
				m["leader"] = leader
		"career":
			var c := RoundLog.career(s)
			var cc := career_card(c, neutral)
			params.merge(cc["params"], true)
			cc.erase("params")
			m.merge(cc, true)
			leader = str(c.get("leader", leader))
			m["leader"] = "" if neutral else leader
		"challenge":
			var secs := float(ext.get("secs", 0.0))
			m["time"] = fmt_time(secs)
			params["time"] = m["time"]
			m["line"] = Strings.s("CHAL_LINE_N" if neutral else "CHAL_LINE", params)
		"daily":
			m["n"] = int(ext.get("n", ext.get("seed", 1)))
			m["grid"] = str(ext.get("grid_text", ext.get("grid", "")))
			params["n"] = str(m["n"])
			params["grid"] = m["grid"]
		"receipt":
			params["amount"] = word_amount(float(receipt(s, d, SaveStore.now_ms())["total"])) if s != null else "0"
		"result":
			var rd := rounds_days(s) if s != null else ["", ""]
			params["rounds"] = plain(rd[0])
			params["days"] = plain(rd[1])
	m["stub"] = stub_path(kind, leader, str(m.get("event", "")), neutral)
	m["text"] = copy_line(kind, params, rot, str(m.get("event", "")), neutral)
	if str(ext.get("text", "")).strip_edges() != "":
		m["text"] = _no_url(str(ext["text"]).strip_edges())   # the caller's own copy (a round's return link, the daily grid)
	m["hash"] = str(ext.get("url_hash", ""))
	m["file"] = file_name(kind)
	return m


## The breaking card's event when none is given: the gate this round, else a court day this round,
## else the last election.
static func breaking_event(s: GameState) -> String:
	if s == null:
		return "election"
	if RoundLog.gate_sec(s) > 0.0:
		return "gate"
	if s.investigation is Dictionary and str(s.investigation.get("phase", "")) == "court":
		return "court"
	return "election" if not s.history.is_empty() else "gate"


## The term summary's record: the round just closed when the new round has not reached its gate
## yet (and there is a closed round), else the live round so far.
static func term_record(s: GameState, d: Economy.Derived) -> Dictionary:
	if s == null:
		return {}
	if not s.history.is_empty() and RoundLog.gate_sec(s) < 0.0:
		return s.history[s.history.size() - 1]
	return RoundLog.current(s, d)


## The term card's fields from a record: {round, time, stats[], title, params}.
static func term_card(rec: Dictionary, neutral: bool) -> Dictionary:
	var leader := str(rec.get("leader", ""))
	var gate := float(rec.get("gate", -1.0))
	var sec := float(rec.get("sec", 0.0))
	var t := fmt_time(gate) if gate > 0.0 else (fmt_time(sec) if sec > 0.0 else "")
	var stats: Array = []
	var top := str(rec.get("top", ""))
	var pct := int(roundf(float(rec.get("topPct", 0.0)) * 100.0))
	var src := plain(Strings.producer_name(top)) if top != "" else ""
	if top != "" and pct > 0:
		stats.append(Strings.s("TERM_TOP", {"pct": str(pct), "source": src}))
	stats.append(Strings.s("TERM_PAID", {"n": str(int(rec.get("paid", 0)))}))
	for pair: Array in [["left", "TERM_LEFT"], ["court", "TERM_COURT"], ["post", "TERM_POST"]]:
		if int(rec.get(pair[0], 0)) > 0:
			stats.append(Strings.s(pair[1], {"n": str(int(rec.get(pair[0], 0)))}))
	var title_key := term_title(rec)
	var n := int(rec.get("n", 1))
	return {"round": Strings.s("TERM_ROUND_N" if neutral or leader == "" else "TERM_ROUND", {"n": str(n), "short": short_of(leader)}),
		"time": t, "stats": stats, "title": Strings.s(title_key),
		"params": {"time": t, "paid": str(int(rec.get("paid", 0))), "title": plain(Strings.s(title_key)),
			"pct": str(pct) if pct > 0 else "", "source": src, "court": str(int(rec.get("court", 0)))}}


## The run's title (TERM_TITLE_*): the most striking thing about the round.
static func term_title(rec: Dictionary) -> String:
	var gate := float(rec.get("gate", -1.0))
	if int(rec.get("court", 0)) >= 2:
		return "TERM_TITLE_COURT"
	if int(rec.get("left", 0)) >= 2:
		return "TERM_TITLE_LEFT"
	if gate > 0.0 and gate < 300.0:
		return "TERM_TITLE_FAST"
	if int(rec.get("paid", 0)) >= 8:
		return "TERM_TITLE_PAID"
	if gate > 1800.0:
		return "TERM_TITLE_SLOW"
	return "TERM_TITLE_PLAIN"


## The career card's fields from RoundLog.career: {survived, as, stats[], title, rounds, params}.
static func career_card(c: Dictionary, neutral: bool) -> Dictionary:
	var rounds := int(c.get("rounds", 0))
	var rw := Strings.plural("ROUNDS", rounds)
	var stats: Array = []
	stats.append(Strings.s("CAREER_TOTAL", {"amount": word_amount(float(c.get("earned", 0.0)))}))
	var fast := float(c.get("fastest", 0.0))
	if fast > 0.0:
		stats.append(Strings.s("CAREER_FAST", {"time": fmt_time(fast)}))
	var partner := str(c.get("partner", ""))
	if partner != "" and not neutral:
		stats.append(Strings.s("CAREER_PARTNER", {"name": ChatView.partner_name(partner)}))
	if int(c.get("court", 0)) > 0:
		stats.append(Strings.s("TERM_COURT", {"n": str(int(c.get("court", 0)))}))
	if int(c.get("walked", 0)) > 0:
		stats.append(Strings.s("TERM_LEFT", {"n": str(int(c.get("walked", 0)))}))
	var tier := RoundLog.title_tier(rounds)
	var title := Strings.s("CAREER_TITLE_%d" % maxi(1, tier))
	var fav := str(c.get("leader", ""))
	return {"survived": Strings.s("CAREER_SURVIVED", {"rounds": rw}),
		"as": "" if neutral or fav == "" else Strings.s("CAREER_AS", {"short": short_of(fav)}),
		"stats": stats, "title": title, "rounds": rounds,
		"params": {"rounds": plain(rw), "title": plain(title), "time": fmt_time(fast) if fast > 0.0 else "", "short": short_of(fav)}}


## The leak card's lines: the round's juiciest real chat lines (ultimatums, walkouts, brawls, the
## transfer window, then demands), in their order, at most 6; [] when the group has said nothing.
## Each {kind: in|out|sys, who, char, text, hot}. Neutral: the partners become "שותף א׳"… and lose
## their faces. Short of 3 real lines, the leak event's scripted screenshot fills in.
static func leak_lines(s: GameState, neutral: bool = false) -> Array:
	if s == null or not s.coalition is Dictionary:
		return []
	var scored: Array = []
	var aliases := {}
	var d := Economy.derive(s)
	for m: Variant in s.coalition.get("chat", []):
		if not m is Dictionary:
			continue
		var t := str(m.get("type", ""))
		var key := str(m.get("key", ""))
		var score := 0
		var kind := "in"
		var text := ""
		match t:
			"ultimatum":
				score = 5
				text = ChatView.line_text(m, s, d)
			"demand":
				score = 2
				text = ChatView.line_text(m, s, d)
			"thanks", "status":
				score = 1
				text = ChatView.line_text(m, s, d)
			"transfer":
				score = 4
				text = ChatView.line_text(m, s, d)
			"sys":
				kind = "sys"
				if key in ["chat.sys.left", "chat.sys.removed", "chat.sys.brawl", "chat.sys.transfer", "chat.sys.merged", "leak.line"]:
					score = 4
				elif key in ["chat.sys.joined", "chat.sys.declined", "chat.sys.muted"]:
					score = 2
				if key != "chat.sys.advisor":
					text = ChatView.sys_text(m)
		if score <= 0 or plain(text).strip_edges() == "":
			continue
		var pid := str(m.get("partner", ""))
		var who := ""
		var ch := ""
		if kind == "in" and pid != "":
			if neutral:
				if not aliases.has(pid):
					aliases[pid] = aliases.size()
				who = Strings.s("SHARE_ANON_%d" % (int(aliases[pid]) % 4 + 1))
			else:
				who = ChatView.partner_name(pid)
				ch = ChatView.char_for(pid)
		if neutral and kind == "sys":
			text = _anon_sys(text)
		scored.append({"seq": int(m.get("seq", 0)), "score": score, "kind": kind, "who": who, "char": ch,
			"text": plain(text), "hot": t == "ultimatum"})
	# the top 6 by score (the newest first on a tie), back in the thread's order
	var best := scored.duplicate()
	best.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a["score"]) > int(b["score"]) or (int(a["score"]) == int(b["score"]) and int(a["seq"]) > int(b["seq"])))
	best = best.slice(0, 6)
	best.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["seq"]) < int(b["seq"]))
	# a run of one sender: the name and the face on its first bubble only (the thread's convention)
	for i in range(1, best.size()):
		if str(best[i]["kind"]) == "in" and str(best[i - 1]["kind"]) == "in" and str(best[i]["who"]) != "" and best[i]["who"] == best[i - 1]["who"]:
			best[i]["cont"] = true
	if not best.is_empty() and best.size() < 3:
		for ln: Variant in Events.leak_lines(1, ""):
			if best.size() >= 4:
				break
			if ln is Array and (ln as Array).size() >= 2 and str(ln[0]) != "typing":
				var sysl := str(ln[0]) == "sys"
				best.append({"seq": 0, "score": 1, "kind": "sys" if sysl else "in",
					"who": "" if sysl else (Strings.s("SHARE_ANON_4") if neutral else str(ln[0])),
					"char": "", "text": plain(str(ln[1])), "hot": false})
	return best


## A system line with the partners' names swapped out (the family-safe leak).
static func _anon_sys(text: String) -> String:
	var t := text
	var i := 0
	for p: Dictionary in Coalition.partners():
		var nm := ChatView.partner_name(str(p["id"]))
		if nm != "" and t.contains(nm):
			t = t.replace(nm, Strings.s("SHARE_ANON_%d" % (i % 4 + 1)))
			i += 1
	return t


## The kinds the drawer offers for this state, in DRAWER_KINDS order (challenge / daily only when
## `extra` names them).
static func kinds_for(s: GameState, extra: Array = []) -> Array:
	var out: Array = []
	for k: String in DRAWER_KINDS:
		match k:
			"leak":
				if s != null and s.coalition is Dictionary and bool(s.coalition.get("opened", false)) and not leak_lines(s).is_empty():
					out.append(k)
			"breaking":
				if s != null and (RoundLog.gate_sec(s) > 0.0 or not s.history.is_empty() or breaking_event(s) == "court"):
					out.append(k)
			"term":
				if s != null and (RoundLog.gate_sec(s) > 0.0 or not s.history.is_empty()):
					out.append(k)
			"career":
				if s != null and maxi(s.evolutions, s.history.size()) >= 1:
					out.append(k)
			"receipt", "result":
				out.append(k)
			_:
				if extra.has(k):
					out.append(k)
	return out
