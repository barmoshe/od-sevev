class_name DailyRound
extends RefCounted
## "הסבב היומי" (the Daily Round, Wordle-style): one seed per Israel calendar day, one leader per day
## (the roster in turn), the same deal and event deck for everyone. Pure rules, no nodes.
##
## The day turns at midnight Israel time (Asia/Jerusalem) for everyone, wherever the phone is. The
## offset follows Israel's DST rule for any year (not the content's 2026 table): summer time from the
## Friday before the last Sunday of March, 02:00 (00:00 UTC), to the last Sunday of October, 02:00
## summer time (23:00 UTC on the Saturday). Day #1 is EPOCH.
##
## Score: the time to 61 (Challenge's clock); the grid (SeededRound.cells) shows the concessions.
## One official attempt per day (RoundBook keeps it); a replay is played and shown, never stored as
## the day's result. The streak counts consecutive days with an official result, through today (or
## through yesterday while today is still unplayed).

const EPOCH := "2026-10-01"
const DAY_MS := 86400000.0
const SEED_MAX := 2147483647


## The content flag `dailyRound` (off since Bar 2026-10-02): every entry point asks this.
static func enabled() -> bool:
	return Events.flag_on("dailyRound")


static func _last_sunday_utc_day(year: int, month: int) -> int:
	# the last day of the month, in unix days, then back to its Sunday
	var next := Time.get_unix_time_from_datetime_dict({"year": year + (1 if month == 12 else 0), "month": 1 if month == 12 else month + 1, "day": 1, "hour": 0, "minute": 0, "second": 0})
	var last_day := int(next / 86400) - 1
	var wd := posmod(last_day + 4, 7)   # 1970-01-01 was a Thursday (4); 0 = Sunday
	return last_day - wd


## Israel's UTC offset in hours (3 in summer time, else 2) at `ms` (unix ms).
static func israel_offset_h(ms: float) -> int:
	var year := int(Time.get_datetime_dict_from_unix_time(int(floorf(ms / 1000.0)))["year"])
	var dst_start := float(_last_sunday_utc_day(year, 3) - 2) * DAY_MS              # Friday 00:00 UTC
	var dst_end := float(_last_sunday_utc_day(year, 10)) * DAY_MS - 3600000.0         # Saturday 23:00 UTC
	return 3 if ms >= dst_start and ms < dst_end else 2


## The Israel calendar day of `ms` in unix days.
static func israel_day(ms: float) -> int:
	return int(floorf((ms + float(israel_offset_h(ms)) * 3600000.0) / DAY_MS))


static func _unix_day_of(key: String) -> int:
	return int(Time.get_unix_time_from_datetime_string(key + "T00:00:00") / 86400)


## "2026-10-02": the Israel date of `ms`.
static func day_key(ms: float) -> String:
	return key_of_day(israel_day(ms))


static func key_of_day(unix_day: int) -> String:
	var d := Time.get_datetime_dict_from_unix_time(unix_day * 86400)
	return "%04d-%02d-%02d" % [int(d["year"]), int(d["month"]), int(d["day"])]


## The key of the day before `key`.
static func prev_key(key: String) -> String:
	return key_of_day(_unix_day_of(key) - 1)


## #N: 1 on EPOCH, counting Israel days.
static func number_of(key: String) -> int:
	return _unix_day_of(key) - _unix_day_of(EPOCH) + 1


static func number(ms: float) -> int:
	return number_of(day_key(ms))


## The day's seed (same for every device).
static func seed_of(key: String) -> int:
	return posmod(hash("od-sevev-daily|" + key), SEED_MAX)


## The day's leader: the pickable roster in turn by the day number (#1 the roster's first).
static func leader_of(key: String) -> String:
	var ids := Leaders.pickable()
	if ids.is_empty():
		return Leaders.default_leader()
	return ids[posmod(number_of(key) - 1, ids.size())]


## Consecutive days with an official result in `results` ({key: result}), ending today, or yesterday
## while today is unplayed.
static func streak(results: Dictionary, today: String) -> int:
	var k := today if results.has(today) else prev_key(today)
	var n := 0
	while results.has(k) and n < 3660:
		n += 1
		k = prev_key(k)
	return n


## The spoiler-free share text: the Hebrew head line (bidi: a Hebrew word first), the grid, the time
## and court line, the URL last. `res` = {n, sec, cells, court ("testified" | "dodged"), press};
## `words` = {head, court, url} already in Hebrew (the controller fills them from the string table);
## `blackout` drops the 61 (no number that could read as a seat count in the election silence).
static func share_text(res: Dictionary, words: Dictionary, blackout: bool = false) -> String:
	var lines := PackedStringArray()
	lines.append(str(words.get("head", "")) + " 🗳️")
	lines.append_array(SeededRound.grid_lines(str(res.get("cells", ""))))
	var court_icon := "🗞️" if res.get("press", false) == true else "⚖️"
	var goal := "✅" if blackout else "61"
	lines.append(Bidi.RLM + "%s ⏱️ %s %s %s" % [goal, SeededRound.mmss(float(res.get("sec", 0))), court_icon, str(words.get("court", ""))])
	lines.append(str(words.get("url", "")))
	return "\n".join(lines)
