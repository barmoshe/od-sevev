extends RefCounted
## Small rule fixes from the overwhelm report (2026-10-03), on the real game content.

var runner: Object


func setup(_r: Object) -> void:
	TestFixture.use_game_content()


## The p_patience perk (ultimatumPlusSec) was read by no code: it now lengthens every ultimatum.
func test_the_patience_perk_lengthens_ultimatums() -> void:
	var s := GameState.fresh()
	var base := Coalition.ult_sec(s)
	var p: Dictionary = {}
	for q: Dictionary in Meta.perks():
		if q["effect"] == "ultimatumPlusSec":
			p = q
	runner.check(not p.is_empty(), "the perk exists in content")
	if p.is_empty():
		return
	s.shop[p["id"]] = 1
	runner.check(is_equal_approx(Coalition.ult_sec(s), base + float((p["levels"] as Array)[0])), "level 1 adds its seconds (%s → %s)" % [base, Coalition.ult_sec(s)])


## The trophy summary counts the shipped list, never more than its total.
func test_the_trophy_count_never_passes_its_total() -> void:
	var s := GameState.fresh()
	for a: Dictionary in Meta.all_trophies():
		s.achievements.append(a["id"])
	var tc := ViewRules.trophy_counts(s)
	runner.check(tc.x <= tc.y and tc.y > 0, "earned %d of %d" % [tc.x, tc.y])
