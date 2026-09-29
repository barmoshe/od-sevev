class_name Calendar
extends RefCounted
## The real calendar (brief-round2 "The real calendar"; ux/first-minute.md §6.3; engine
## feasibility U3). Pure rules, no nodes. Dates come from content.calendar. State:
## GameState.calendar {hwm, mode, noticeBlackout, noticeElection}.
##
## Three modes:
##   campaign    : the HUD counts down to election day (days_left).
##   blackout    : from blackoutStartUtc (23.10 00:00 Israel time) until pollsCloseUtc (27.10 22:00).
##                 No poll-like number anywhere: the seats numeral becomes a stamp, poll_like
##                 content is filtered, and poll_like events never fire.
##   negotiation : after the polls close, the endless "משא ומתן קואליציוני" mode.
##
## The clock can't be rewound (U3): now = max(device, build, saved high-water mark) offline; when
## the server's Date header is known, now = max(server, build) and the high-water mark is clamped
## to it, so a phone once set to 2027 recovers as soon as it's online.

const MODES := ["campaign", "blackout", "negotiation"]


static func cfg() -> Dictionary:
	var c: Variant = Content.data().get("calendar")
	return c if c is Dictionary else {}


static func active() -> bool:
	return not cfg().is_empty()


static func fresh_state() -> Dictionary:
	return {"hwm": 0.0, "mode": "campaign", "noticeBlackout": false, "noticeElection": false}


## An ISO date-time -> unix ms: "2026-10-23T00:00:00+03:00" (the Designer's Israel-local times),
## "…Z" or no suffix (UTC), or a bare "2026-10-27" (UTC midnight). 0 for an empty string.
static func parse_utc_ms(iso: String) -> float:
	var t := iso.strip_edges()
	if t == "":
		return 0.0
	var off_min := 0
	if t.ends_with("Z"):
		t = t.trim_suffix("Z")
	elif t.length() > 19 and (t[t.length() - 6] == "+" or t[t.length() - 6] == "-") and t[t.length() - 3] == ":":
		var sgn := 1 if t[t.length() - 6] == "+" else -1
		off_min = sgn * (t.substr(t.length() - 5, 2).to_int() * 60 + t.substr(t.length() - 2, 2).to_int())
		t = t.substr(0, t.length() - 6)
	if t.length() == 10:
		t += "T00:00:00"
	return (float(Time.get_unix_time_from_datetime_string(t)) - off_min * 60.0) * 1000.0


## The calendar's instants (contract v2 keys, v1 keys as a fallback).
static func blackout_from_ms() -> float:
	return blackout_from_ms_of(cfg())


static func polls_close_ms() -> float:
	return _polls_of(cfg())


## The clamp (U3). `server_ms` < 0 means offline / unknown. Updates the saved high-water mark.
static func resolve_now(s: GameState, device_ms: float, server_ms: float = -1.0, build_ms: float = 0.0) -> float:
	var now: float
	if server_ms > 0.0:
		now = maxf(server_ms, build_ms)
	else:
		now = maxf(maxf(device_ms, build_ms), float(s.calendar.get("hwm", 0.0)))
	s.calendar["hwm"] = now
	return now


static func israel_offset_h(now_ms: float) -> float:
	var h := float(cfg().get("defaultOffsetHours", 2.0))
	var best := -INF
	for o: Variant in cfg().get("utcOffsets", cfg().get("israelUtcOffsets", [])):
		if not o is Dictionary:
			continue
		var from := parse_utc_ms(str(o.get("from", o.get("fromUtc", ""))))
		if from <= now_ms and from > best:
			best = from
			h = float(o.get("hours", h))
	return h


## Whole days from today (Israel's local date) to election day: 29 on 28.10... 0 on the day,
## negative after.
static func days_left(now_ms: float) -> int:
	var day_ms := 86400000.0
	var local_day := floorf((now_ms + israel_offset_h(now_ms) * 3600000.0) / day_ms)
	var e_day := floorf(parse_utc_ms(str(cfg().get("electionDate", ""))) / day_ms)
	return int(e_day - local_day)


static func is_blackout(now_ms: float) -> bool:
	if cfg().get("forceBlackout", false) == true:
		return true   # the publisher's 22.10 backstop build (U3)
	var a := blackout_from_ms()
	var b := polls_close_ms()
	return a > 0.0 and now_ms >= a and now_ms < b


static func is_post_election(now_ms: float) -> bool:
	if cfg().get("forcePostElection", false) == true:
		return true
	var b := polls_close_ms()
	return b > 0.0 and now_ms >= b


static func mode_at(now_ms: float) -> String:
	if not active():
		return "campaign"
	if is_post_election(now_ms):
		return "negotiation"
	if is_blackout(now_ms):
		return "blackout"
	return "campaign"


## Stores the mode on the state (the other modules read s.calendar.mode) and returns
## {ev: modeChanged, mode, was} when it changed.
static func update(s: GameState, now_ms: float) -> Array:
	var was := str(s.calendar.get("mode", "campaign"))
	var m := mode_at(now_ms)
	s.calendar["mode"] = m
	if m != was:
		return [{"ev": "modeChanged", "mode": m, "was": was}]
	return []


static func mode(s: GameState) -> String:
	return str(s.calendar.get("mode", "campaign"))


## poll_like content (deck §0 tags) may show: anything but the blackout.
static func poll_like_allowed(s: GameState) -> bool:
	return mode(s) != "blackout"


## UX §6.3 item 2: in the blackout the seats bar keeps its fill but the numeral becomes a stamp.
static func seats_numeral_hidden(s: GameState) -> bool:
	return mode(s) == "blackout"


## The one-time notice the UI owes: "blackout" (O11), "election" (O12) or "". Ack it when shown.
static func pending_notice(s: GameState) -> String:
	var m := mode(s)
	if m == "negotiation" and not s.calendar.get("noticeElection", false):
		return "election"
	if m == "blackout" and not s.calendar.get("noticeBlackout", false):
		return "blackout"
	return ""


static func ack_notice(s: GameState, which: String) -> void:
	if which == "election":
		s.calendar["noticeElection"] = true
		s.calendar["noticeBlackout"] = true   # a player first seen after the polls close skips O11
	elif which == "blackout":
		s.calendar["noticeBlackout"] = true


static func sanitize(raw: Variant) -> Dictionary:
	var out := fresh_state()
	if not raw is Dictionary:
		return out
	var r: Dictionary = raw
	out["hwm"] = Coalition._n(r.get("hwm"))
	out["mode"] = r.get("mode") if MODES.has(r.get("mode")) else "campaign"
	out["noticeBlackout"] = r.get("noticeBlackout") == true
	out["noticeElection"] = r.get("noticeElection") == true
	return out


static func validate(c: Dictionary) -> PackedStringArray:
	var err := PackedStringArray()
	var ca: Variant = c.get("calendar")
	if ca == null:
		return err
	if not ca is Dictionary:
		return PackedStringArray(["calendar: must be an object"])
	if blackout_from_ms_of(ca) <= 0.0:
		err.append("calendar.blackout.from: not an ISO date-time")
	if parse_utc_ms(str(ca.get("electionDate", ""))) <= 0.0:
		err.append("calendar.electionDate: not a date (YYYY-MM-DD)")
	if blackout_from_ms_of(ca) >= _polls_of(ca):
		err.append("calendar: the blackout must start before the polls close")
	if not ca.has("utcOffsets") and not ca.has("israelUtcOffsets"):
		err.append("calendar.utcOffsets: missing, so the day count ignores DST (contract v2 item 10)")
	return err


static func blackout_from_ms_of(ca: Dictionary) -> float:
	var b: Variant = ca.get("blackout")
	return parse_utc_ms(str(b.get("from", "")) if b is Dictionary else str(ca.get("blackoutStartUtc", "")))


static func _polls_of(ca: Dictionary) -> float:
	var pe: Variant = ca.get("postElection")
	if pe is Dictionary and str(pe.get("from", "")) != "":
		return parse_utc_ms(str(pe["from"]))
	if ca.has("pollsClose"):
		return parse_utc_ms(str(ca["pollsClose"]))
	var b: Variant = ca.get("blackout")
	return parse_utc_ms(str(b.get("to", "")) if b is Dictionary else str(ca.get("pollsCloseUtc", "")))
