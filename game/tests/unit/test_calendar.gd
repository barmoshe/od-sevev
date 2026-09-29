extends RefCounted
## The real calendar (game/scripts/sim/calendar.gd): the countdown to 27.10.2026, the blackout
## window and the clock that can't be rewound (UX §6.3, engine feasibility U3).

const PF := preload("res://tests/politics_fixture.gd")

var runner: Object


func setup(_r: Object) -> void:
	PF.install()


func teardown() -> void:
	PF.restore()


func _ms(iso: String) -> float:
	return Calendar.parse_utc_ms(iso)


func test_countdown_days_in_israel_time() -> void:
	runner.check(Calendar.days_left(_ms("2026-09-28T07:00:00")) == 29, "28.9 → 29 days (UX title chip 'עוד 29 ימים')")
	runner.check(Calendar.days_left(_ms("2026-10-26T20:59:00")) == 1, "26.10 22:59 local (IST, UTC+2) → 1 day")
	runner.check(Calendar.days_left(_ms("2026-10-26T22:30:00")) == 0, "27.10 00:30 local is election day → 0")
	runner.check(Calendar.days_left(_ms("2026-10-22T21:30:00")) == 4, "23.10 00:30 local (IDT, UTC+3) → 4")
	runner.check(Calendar.days_left(_ms("2026-10-22T20:30:00")) == 5, "22.10 23:30 local → 5")
	runner.check(Calendar.days_left(_ms("2026-10-29T12:00:00")) < 0, "after the day: negative")


func test_modes() -> void:
	runner.check(Calendar.mode_at(_ms("2026-10-22T20:59:59")) == "campaign", "22.10 23:59:59 Israel: campaign")
	runner.check(Calendar.mode_at(_ms("2026-10-22T21:00:00")) == "blackout", "23.10 00:00 Israel: blackout")
	runner.check(Calendar.mode_at(_ms("2026-10-27T19:59:59")) == "blackout", "27.10 21:59:59 Israel: still blackout")
	runner.check(Calendar.mode_at(_ms("2026-10-27T20:00:00")) == "negotiation", "polls close at 22:00: 'משא ומתן קואליציוני'")
	runner.check(Calendar.mode_at(_ms("2027-06-01T00:00:00")) == "negotiation", "and it never ends")


func test_blackout_hides_poll_like_numbers() -> void:
	var s := GameState.fresh()
	Calendar.update(s, _ms("2026-10-01T12:00:00"))
	runner.check(Calendar.poll_like_allowed(s) and not Calendar.seats_numeral_hidden(s), "campaign: numbers shown")
	var ev := Calendar.update(s, _ms("2026-10-24T12:00:00"))
	runner.check(ev.size() == 1 and ev[0]["mode"] == "blackout", "the mode change is announced once")
	runner.check(not Calendar.poll_like_allowed(s) and Calendar.seats_numeral_hidden(s), "blackout: 'חסוי עד 27.10' instead of the numeral")
	runner.check(Calendar.update(s, _ms("2026-10-24T12:00:01")).is_empty(), "no repeat event")
	runner.check(Calendar.pending_notice(s) == "blackout", "O11 is owed")
	Calendar.ack_notice(s, "blackout")
	runner.check(Calendar.pending_notice(s) == "", "and shown once")
	Calendar.update(s, _ms("2026-10-28T12:00:00"))
	runner.check(Calendar.pending_notice(s) == "election" and Calendar.poll_like_allowed(s), "election night: O12, and the mode no longer filters")


func test_clock_cannot_be_rewound() -> void:
	var s := GameState.fresh()
	var inside := _ms("2026-10-24T12:00:00")
	var now := Calendar.resolve_now(s, inside)
	runner.check(Calendar.mode_at(now) == "blackout", "in the window")
	now = Calendar.resolve_now(s, _ms("2026-10-01T12:00:00"))
	runner.check(now == inside and Calendar.mode_at(now) == "blackout", "setting the phone back doesn't leave the window (high-water mark)")
	now = Calendar.resolve_now(s, _ms("2026-10-01T12:00:00"), -1.0, _ms("2026-10-25T00:00:00"))
	runner.check(now == _ms("2026-10-25T00:00:00"), "the build timestamp is a floor")


func test_online_server_time_clamps_a_future_phone() -> void:
	var s := GameState.fresh()
	var now := Calendar.resolve_now(s, _ms("2027-01-01T00:00:00"))
	runner.check(Calendar.mode_at(now) == "negotiation", "offline, a phone set to 2027 reads post-election")
	now = Calendar.resolve_now(s, _ms("2027-01-01T00:00:00"), _ms("2026-10-10T09:00:00"))
	runner.check(Calendar.mode_at(now) == "campaign" and float(s.calendar["hwm"]) == _ms("2026-10-10T09:00:00"), "online, the server's Date wins and the mark is clamped")
	now = Calendar.resolve_now(s, _ms("2026-10-10T09:00:00"))
	runner.check(Calendar.mode_at(now) == "campaign", "and stays clamped offline")


func test_force_flags() -> void:
	Content.data()["calendar"]["forceBlackout"] = true
	runner.check(Calendar.mode_at(_ms("2026-10-01T00:00:00")) == "blackout", "the publisher's 22.10 backstop build")
	Content.data()["calendar"]["forceBlackout"] = false
	Content.data()["calendar"]["forcePostElection"] = true
	runner.check(Calendar.mode_at(_ms("2026-10-01T00:00:00")) == "negotiation", "the 27.10 patch can be forced too")


func test_negotiation_mode_speeds_up_demands() -> void:
	var s := GameState.fresh()
	var g1 := Coalition._gap(s, func() -> float: return 0.5)
	s.calendar["mode"] = "negotiation"
	var g2 := Coalition._gap(s, func() -> float: return 0.5)
	runner.check(is_equal_approx(g2, maxf(g1 * 0.6, 30.0)), "after the election the partners ask 40%% more often (%s → %s)" % [g1, g2])


func test_no_calendar_content_is_campaign() -> void:
	PF.restore()
	TestFixture.use_fork_content()
	runner.check(Calendar.mode_at(_ms("2026-10-24T12:00:00")) == "campaign", "without content.calendar there is no blackout")
