extends RefCounted
## Formatters (ux/number-and-copy.md §2) and the v2 notation setting.

var runner: Object


func setup(_r: Object) -> void:
	TestFixture.use_fork_content()


func teardown() -> void:
	Fmt.notation = "letters"
	TestFixture.use_game_content()


func _is(got: String, want: String, what: String) -> void:
	runner.check(got == want, "%s: got %s, want %s" % [what, got, want])


## content.json's examples round to nearest (the general rule); costs ceil (ux doc §2).
func test_content_examples() -> void:
	var ex: Dictionary = Content.data()["numberFormat"]["examples"]
	for k: String in ex:
		_is(Fmt.amount(float(k)), String(ex[k]).to_upper(), "amount(%s)" % k)
	_is(Fmt.cost(1234.0), "1.24K", "cost ceils")
	_is(Fmt.cost(1100.0), "1.10K", "cost 1.10K")


func test_bank() -> void:
	_is(Fmt.bank(999.0), "999", "bank 999")
	_is(Fmt.bank(12345.0), "12,345", "bank 12,345")
	_is(Fmt.bank(999999.9), "999,999", "bank floors")
	_is(Fmt.bank(1234567.0), "1.234M", "bank 1.234M")
	_is(Fmt.bank(2.5e12), "2.500T", "bank 2.500T")
	_is(Fmt.bank(Economy.MAX), "MAX", "bank at the ceiling")
	_is(Fmt.bank(INF), "MAX", "bank never shows inf")


func test_rate_amount_thumbs_mult() -> void:
	_is(Fmt.rate(0.4), "0.4", "rate 0.4")
	_is(Fmt.rate(16.0), "16", "rate 16")
	_is(Fmt.rate(4859.0), "4.86K", "rate 4.86K")
	_is(Fmt.amount(291000.0), "291K", "amount 291K")
	_is(Fmt.thumbs(4319.0), "4319", "thumbs exact below 10k")
	_is(Fmt.thumbs(43100.0), "43.1K", "thumbs 43.1K")
	_is(Fmt.mult(96.9), "96.9", "mult 96.9")
	_is(Fmt.mult(4310.0), "4.31K", "mult 4.31K")
	_is(Fmt.cost(999.5), "1.00K", "cost ceil rolls to the next tier")


func test_durations() -> void:
	_is(Fmt.dur(30.0), "1M", "dur minimum 1M")
	_is(Fmt.dur(7.0 * 3600.0 + 59.0 * 60.0), "7H 59M", "dur hours")
	_is(Fmt.dur(2.0 * 86400.0 + 3.0 * 3600.0), "2D 3H", "dur days (the Thumbs shop raises the cap)")
	_is(Fmt.secs(11.2), "12S", "secs ceil")
	_is(Fmt.clock(3725.0), "1H 02M 05S", "clock")


func test_notations() -> void:
	Fmt.notation = "scientific"
	_is(Fmt.cost(1.5e15), "1.50E15", "scientific")
	_is(Fmt.rate(4859.0), "4.86E3", "scientific rate")
	Fmt.notation = "engineering"
	_is(Fmt.cost(1.5e15), "1.50E15", "engineering 1.50E15")
	_is(Fmt.cost(3.3e17), "330E15", "engineering keeps multiples of 3")
	_is(Fmt.cost(15.0), "15", "small numbers stay plain")
