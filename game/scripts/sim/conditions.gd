class_name Conditions
extends RefCounted
## The one condition vocabulary for partners[].unlock and events[].when (STATUS.md data contract,
## sim/README.md). Every key in a condition must hold. An unknown key is false (never silently
## true), and Politics.validate() reports it, so a typo fails tools/test.sh instead of the build.
## `ctx` carries the device clock for the easter eggs: {weekday: 0-6 (0 = Sunday), hour: 0-23}.

static var KEYS: Dictionary = {
	"era": func(v: Variant, s: GameState, _ctx: Dictionary) -> bool:
		return _in(Story.era_for(s.evolutions).get("id", ""), v),
	"evolutionsAtLeast": func(v: Variant, s: GameState, _ctx: Dictionary) -> bool: return s.evolutions >= int(v),
	"evolutionsBelow": func(v: Variant, s: GameState, _ctx: Dictionary) -> bool: return s.evolutions < int(v),
	"runMoneyAtLeast": func(v: Variant, s: GameState, _ctx: Dictionary) -> bool: return s.run_money >= float(v),
	"allTimeAtLeast": func(v: Variant, s: GameState, _ctx: Dictionary) -> bool: return s.all_time_money >= float(v),
	"ownedAtLeast": func(v: Variant, s: GameState, _ctx: Dictionary) -> bool:
		return v is Dictionary and s.owned_of(str(v.get("producer", ""))) >= int(v.get("count", 0)),
	"sourcesOwnedAtLeast": func(v: Variant, s: GameState, _ctx: Dictionary) -> bool: return sources_owned(s) >= int(v),
	"shadyOwnedAtLeast": func(v: Variant, s: GameState, _ctx: Dictionary) -> bool: return Investigation.shady_owned(s) >= int(v),
	"seatsAtLeast": func(v: Variant, s: GameState, _ctx: Dictionary) -> bool: return int(Coalition.seat_info(s)["effective"]) >= int(v),
	"seatsBelow": func(v: Variant, s: GameState, _ctx: Dictionary) -> bool: return int(Coalition.seat_info(s)["effective"]) < int(v),
	"membersAtLeast": func(v: Variant, s: GameState, _ctx: Dictionary) -> bool: return Coalition.member_count(s) >= int(v),
	"partnersInAtLeast": func(v: Variant, s: GameState, _ctx: Dictionary) -> bool: return Coalition.member_count(s) >= int(v),
	"critsLifetimeAtLeast": func(v: Variant, s: GameState, _ctx: Dictionary) -> bool: return s.crits_lifetime >= int(v),
	"goldenCaughtLifetimeAtLeast": func(v: Variant, s: GameState, _ctx: Dictionary) -> bool: return s.golden_caught_lifetime >= int(v),
	"partnerMember": func(v: Variant, s: GameState, _ctx: Dictionary) -> bool: return Coalition.status(s, str(v)) == "member",
	"partnerNotMember": func(v: Variant, s: GameState, _ctx: Dictionary) -> bool: return Coalition.status(s, str(v)) != "member",
	"suspicionAtLeast": func(v: Variant, s: GameState, _ctx: Dictionary) -> bool: return Investigation.suspicion(s) >= float(v),
	"suspicionBelow": func(v: Variant, s: GameState, _ctx: Dictionary) -> bool: return Investigation.suspicion(s) < float(v),
	"courtDaysAtLeast": func(v: Variant, s: GameState, _ctx: Dictionary) -> bool: return int(s.investigation.get("courtDays", 0)) >= int(v),
	"playSecAtLeast": func(v: Variant, s: GameState, _ctx: Dictionary) -> bool: return float(s.stats.get("playtimeSec", 0.0)) >= float(v),
	"runSecAtLeast": func(v: Variant, s: GameState, _ctx: Dictionary) -> bool: return s.run_time_sec >= float(v),
	"weekday": func(v: Variant, _s: GameState, ctx: Dictionary) -> bool:
		return ctx.has("weekday") and _in(int(ctx["weekday"]), v),
	"hour": func(v: Variant, _s: GameState, ctx: Dictionary) -> bool:
		if not ctx.has("hour") or not v is Array or (v as Array).size() != 2:
			return false
		var h := int(ctx["hour"])
		var a := int(v[0])
		var b := int(v[1])
		return (h >= a and h <= b) if a <= b else (h >= a or h <= b),
	"mode": func(v: Variant, s: GameState, _ctx: Dictionary) -> bool: return _in(str(s.calendar.get("mode", "campaign")), v),
	# The Designer's hold on content whose engine rule isn't built yet: `pendingEngine: true` never unlocks.
	"pendingEngine": func(v: Variant, _s: GameState, _ctx: Dictionary) -> bool: return v != true,
}


## True when every key holds. null or {} is always true.
static func ok(s: GameState, w: Variant, ctx: Dictionary = {}) -> bool:
	if w == null:
		return true
	if not w is Dictionary:
		return false
	for k: Variant in w:
		var h: Variant = KEYS.get(k)
		if h == null or not (h as Callable).call(w[k], s, ctx):
			return false
	return true


## Keys in `w` outside the vocabulary (the lint).
static func unknown_keys(w: Variant) -> PackedStringArray:
	var out := PackedStringArray()
	if w is Dictionary:
		for k: Variant in w:
			if not KEYS.has(k):
				out.append(str(k))
	elif w != null:
		out.append("<not an object>")
	return out


static func sources_owned(s: GameState) -> int:
	var n := 0
	for id in Content.producer_ids():
		n += s.owned_of(id)
	return n


## `x` equals `v`, or is one of `v` when it is a list. JSON numbers arrive as floats, so numbers
## compare by value and everything else as text.
static func _in(x: Variant, v: Variant) -> bool:
	for y: Variant in (v as Array if v is Array else [v]):
		if (x is int or x is float) and (y is int or y is float):
			if is_equal_approx(float(x), float(y)):
				return true
		elif str(x) == str(y):
			return true
	return false
