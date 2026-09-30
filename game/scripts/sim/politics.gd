class_name Politics
extends RefCounted
## The one entry point the controller needs for the od-sevev systems (Coalition, Investigation,
## Events, Calendar). Pure, no nodes. Economy.derive() calls install(); Economy.evolve() calls
## on_election(); the controller calls tick() once per fixed step on VISIBLE frames only (hidden
## time and away time never advance a demand, an ultimatum, the court or an event).
##
## ctx (all optional):
##   allowPing: bool  UX C1's controller half: no modal open and the last purchase >= 2 s ago.
##   nowMs: float     Calendar.resolve_now() result; when present the calendar mode updates.
##   weekday: int     device clock, 0 = Sunday (the Pink Front drum line)
##   hour: int        device clock, 0-23
##   vote: bool       the election card (O3) is open: "the vote stops the clock" (below).
##
## The vote stops the clock (Game Designer, 2026-09-30). While O3 is open the round holds:
## no ultimatum counts down or expires, no demand ages into one, no partner joins, Gotliv's
## meter and every live card's timer stand still, the court waits and no new card fires. The
## calendar alone follows the real clock. The controller also stops the economy for the same
## frames (main.gd `_step_economy`), so the card is a pause, never a farm: whatever the seats read
## when the player opened the card is what they vote on, and nothing is lost behind a modal that
## hides the chat. See design/leader-select-spec.md §7.4.


## Registers the systems' modifiers (once). With a state it installs that state's round (the
## leader's lineup, rivals and rule; Leaders.ensure: cheap when nothing changed, and Economy.derive
## calls it every derive). With a leader it also starts the round as that leader (the picker, spec
## §3; Leaders.start_round: only while the round hasn't started) and returns its result.
static func install(s: GameState = null, leader: String = "") -> Dictionary:
	Coalition.install()
	Investigation.install()
	Events.install()
	Leaders.install()
	if s == null:
		return {}
	if leader != "":
		return Leaders.start_round(s, leader)
	Leaders.ensure(s)
	return {}


## Returns every UI event of the frame, in order: coalition, court, events, calendar.
static func tick(s: GameState, dt: float, d: Economy.Derived, ctx: Dictionary = {}, rng: Callable = randf) -> Array:
	var out: Array = []
	Leaders.ensure(s)
	if ctx.has("nowMs"):
		out.append_array(Calendar.update(s, float(ctx["nowMs"])))
	if holds_for_vote(ctx):
		return out
	out.append_array(Coalition.tick(s, dt, d, ctx, rng))
	out.append_array(Investigation.tick(s, dt, d))
	out.append_array(Events.tick(s, dt, d, ctx, rng))
	_count_night_taps(s, ctx)
	return out


## The vote stops the clock: ctx.vote (the election card is open).
static func holds_for_vote(ctx: Dictionary) -> bool:
	return ctx.get("vote", false) == true


## Trophy "לילה לבן" (stat tapsAt2to4): taps made while the clock reads 02:00-03:59. The hour is
## ctx.hour (the device's local hour; the engine should pass it), else Israel time from ctx.nowMs.
static func _count_night_taps(s: GameState, ctx: Dictionary) -> void:
	var seen := s.taps_seen
	s.taps_seen = s.taps_lifetime
	if seen < 0 or s.taps_lifetime <= seen:
		return
	var h := night_hour(ctx)
	if h == 2 or h == 3:
		Meta.bump(s, "tapsAt2to4", float(s.taps_lifetime - seen))


static func night_hour(ctx: Dictionary) -> int:
	if ctx.has("hour"):
		return int(ctx["hour"])
	if ctx.has("nowMs") and Calendar.active():
		var now := float(ctx["nowMs"])
		return int(floorf(fposmod(now / 3600000.0 + Calendar.israel_offset_h(now), 24.0)))
	return -1


## Called by Economy.evolve() after the run resets ("עוד סבב!").
static func on_election(s: GameState) -> void:
	Leaders.on_election(s)   # first: the next round's lineup (same leader until a pick)
	Coalition.on_election(s)
	Investigation.on_election(s)
	Events.on_election(s)


## Every broken reference in a content dictionary (defaults to the loaded content). Empty = OK.
static func validate(c: Dictionary = {}) -> PackedStringArray:
	if c.is_empty():
		c = Content.data()
	var err := PackedStringArray()
	err.append_array(Coalition.validate(c))
	err.append_array(Investigation.validate(c))
	err.append_array(Events.validate(c))
	err.append_array(Calendar.validate(c))
	err.append_array(Spins.validate(c))
	err.append_array(Leaders.validate(c))
	for o: Variant in c.get("golden", {}).get("outcomes", []):
		if not o is Dictionary:
			continue
		if o.get("parksOnAide", o.get("aide", false)) == true and c.get("court") == null:
			err.append("golden.outcomes.%s: parksOnAide needs the `court` section" % o.get("id", "?"))
		for k in Conditions.unknown_keys(o.get("requires", {})):
			err.append("golden.outcomes.%s.requires: unknown condition %s" % [o.get("id", "?"), k])
		var t := str(o.get("type", ""))
		if t != "" and not ["instant", "bpsFrenzy", "tapFrenzy", "bunch", "frenzy"].has(t):
			err.append("golden.outcomes.%s.type: unknown %s" % [o.get("id", "?"), t])
	for u: Variant in c.get("upgrades", []):
		if u is Dictionary:
			for k in Conditions.unknown_keys(u.get("unlock", {})):
				if not Economy.UNLOCKS.has(k):
					err.append("upgrades.%s.unlock: unknown condition %s" % [u.get("id", "?"), k])
	var pr: Variant = c.get("prestige", {})
	var gate: Variant = (pr as Dictionary).get("gate") if pr is Dictionary else null
	if gate is Dictionary and str((gate as Dictionary).get("type", "")) == "seats" and not c.get("coalition") is Dictionary:
		err.append("prestige.gate.type seats needs the `coalition` section (its gateSeats)")
	return err


## Upgrade effect types in `c` that no handler implements yet (they do nothing). Reported by the
## balance bench and in sim/README.md; not a test failure, because spins are a separate slice.
static func unimplemented_effects(c: Dictionary = {}) -> PackedStringArray:
	if c.is_empty():
		c = Content.data()
	var out := PackedStringArray()
	for u: Variant in c.get("upgrades", []):
		if not u is Dictionary:
			continue
		var t := str((u as Dictionary).get("effect", {}).get("type", ""))
		if not Spins.implemented(t) and not out.has(t):
			out.append(t)
	return out
