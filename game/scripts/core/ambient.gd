class_name Ambient
extends RefCounted
## The ticker's ambient lines (content ambientHeadlinesV2 `list` + `listPolitics`), picked on the
## engine side so the politics lines can use the whole condition vocabulary (game-designer ask a):
## - Story's own keys are evaluated here (era, owned {producer,count}, frenzy, tapFrenzy,
##   evolutionsAtLeast, perk, trophiesAtLeast, allTimeAtLeast, goldenAtLeast, hour);
## - the new keys: courtPhase (Investigation phase, or a list), ultimatumOpen (bool),
##   dateFrom / dateTo ("YYYY-MM-DD", Israel local date, inclusive), upgrade (a spin owned),
##   partnerMember as a list (every listed partner is a member);
## - every other key goes to the sim's Conditions vocabulary (an unknown key is false).
## Lines marked poll_like never show in the blackout. `ticker.ambientFrom: "C1"` keeps the first
## minute free of ambient lines until the first chat ping would fire (3 sources owned).
## ICU plural lines ({d, plural, one {…} two {…} other {# …}}) get `d` = days to the election.

static func pick(s: GameState, recent: Array, rng: Callable = randf) -> String:
	var c := Content.data()
	var v2: Dictionary = c.get("ambientHeadlinesV2", {})
	var t: Dictionary = c.get("ticker", {})
	if String(t.get("ambientFrom", "")) == "C1" and s.evolutions == 0 and Conditions.sources_owned(s) < int(c.get("coalition", {}).get("openAtSourcesOwned", 3)):
		return ""
	var now := SaveStore.now_ms()
	var blackout := Calendar.active() and Calendar.is_blackout(now)
	var dt := Time.get_datetime_dict_from_system()
	var ctx := {"hour": int(dt["hour"]), "weekday": int(dt["weekday"])}
	var window := int(v2.get("noRepeatWindow", 12))
	var pool: Array = []
	for h: Variant in Array(v2.get("list", [])) + Array(v2.get("listPolitics", [])):
		if not h is Dictionary:
			continue
		var text := String((h as Dictionary).get("text", ""))
		if text == "" or recent.has(text):
			continue
		if blackout and bool((h as Dictionary).get("poll_like", false)):
			continue
		if ok(s, (h as Dictionary).get("when", {}), ctx, now):
			pool.append(h)
	if pool.is_empty():
		recent.clear()
		return ""
	var pickd: Dictionary = pool[int(float(rng.call()) * pool.size()) % pool.size()]
	var out := String(pickd["text"])
	recent.append(out)
	while recent.size() > window:
		recent.pop_front()
	if bool(pickd.get("icu", false)):
		out = icu(out, {"d": Calendar.days_left(now) if Calendar.active() else 0})
	return out


static func ok(s: GameState, w: Variant, ctx: Dictionary, now_ms: float) -> bool:
	if not w is Dictionary:
		return true
	for k: String in (w as Dictionary):
		var v: Variant = w[k]
		var hit := false
		match k:
			"era":
				hit = _in(String(Story.era_for(s.evolutions).get("id", "")), v)
			"owned":
				hit = v is Dictionary and s.owned_of(str(v.get("producer", ""))) >= int(v.get("count", 0))
			"frenzy":
				hit = (s.buff_frenzy > 0.0) == bool(v)
			"tapFrenzy":
				hit = (s.buff_tap_frenzy > 0.0) == bool(v)
			"perk":
				hit = Meta.perk_level(s, str(v)) > 0
			"trophiesAtLeast":
				hit = s.achievements.size() >= int(v)
			"goldenAtLeast":
				hit = s.golden_caught_lifetime >= int(v)
			"courtPhase":
				hit = _in(Investigation.phase(s), v)
			"ultimatumOpen":
				hit = (Coalition.open_ultimatums(s) > 0) == bool(v)
			"dateFrom":
				hit = _local_date(now_ms) >= str(v)
			"dateTo":
				hit = _local_date(now_ms) <= str(v)
			"upgrade":
				hit = s.upgrades.has(str(v))
			"partnerMember":
				hit = true
				for p: Variant in (v as Array if v is Array else [v]):
					hit = hit and Coalition.status(s, str(p)) == "member"
			_:
				var f: Variant = Conditions.KEYS.get(k)
				hit = f != null and bool((f as Callable).call(v, s, ctx))
		if not hit:
			return false
	return true


static func _in(x: Variant, v: Variant) -> bool:
	if v is Array:
		return (v as Array).has(x)
	return str(x) == str(v)


## "YYYY-MM-DD" in Israel's local time (the calendar's offsets).
static func _local_date(now_ms: float) -> String:
	var off := Calendar.israel_offset_h(now_ms) if Calendar.active() else 0.0
	var d := Time.get_datetime_dict_from_unix_time(int((now_ms + off * 3600000.0) / 1000.0))
	return "%04d-%02d-%02d" % [d["year"], d["month"], d["day"]]


## A minimal ICU plural for Hebrew (CLDR he: one, two, other, plus =N): {x, plural, …}; `#` is the
## number as an LTR token.
static func icu(text: String, vars: Dictionary) -> String:
	var re := RegEx.create_from_string("\\{(\\w+), plural, ")
	var out := text
	var m := re.search(out)
	while m != null:
		var key := m.get_string(1)
		var n := int(vars.get(key, 0))
		var i := m.get_end()
		var cases := {}
		var depth := 0
		var label := ""
		var body := ""
		var end := i
		while end < out.length():
			var ch := out[end]
			if depth == 0 and ch == "}":
				break
			if ch == "{":
				depth += 1
				if depth == 1:
					body = ""
					end += 1
					continue
			elif ch == "}":
				depth -= 1
				if depth == 0:
					cases[label.strip_edges()] = body
					label = ""
					end += 1
					continue
			if depth == 0:
				label += ch
			else:
				body += ch
			end += 1
		var pickc := "other"
		if cases.has("=%d" % n):
			pickc = "=%d" % n
		elif n == 1 and cases.has("one"):
			pickc = "one"
		elif n == 2 and cases.has("two"):
			pickc = "two"
		var rep := String(cases.get(pickc, "")).replace("#", Bidi.num(str(n)))
		out = out.substr(0, m.get_start()) + rep + out.substr(end + 1)
		m = re.search(out)
	return out
