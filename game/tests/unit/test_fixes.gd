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


## The how-it-works sheet says only what the player has met, and always that a menu stops the clock.
func test_the_help_sheet_follows_the_ladder() -> void:
	Reveal.force_all = false
	var s := GameState.fresh()
	var r1 := HelpCard.lines(s)
	runner.check(not r1.has(Strings.s("HELP_SUSP")) and not r1.has(Strings.s("HELP_ULT")), "round 1: no suspicion or ultimatum lines")
	runner.check(r1.has(Strings.s("HELP_PAUSE")), "the clock line is always there")
	s.evolutions = 3
	var r4 := HelpCard.lines(s)
	runner.check(r4.has(Strings.s("HELP_SUSP")) and r4.has(Strings.s("HELP_ULT")), "round 4: both")
	Reveal.force_all = true


## Every leader's one-line rule fits the picker's strip (pick.strip: 656 px, 2 lines at ×4).
func test_every_rule_summary_fits_the_picker_strip() -> void:
	for l: Dictionary in Content.data().get("leaders", []):
		var sm := str(Leaders.rule(str(l["id"])).get("summary", ""))
		runner.check(sm != "", "%s has a summary" % l["id"])
		var lines := Ticker.wrap_lines_px(sm, 656.0, 4)
		runner.check(lines.size() <= 2, "%s: %d lines (%s)" % [l["id"], lines.size(), sm])


## DOS_INCOME: one number for every multiplier on income.
func test_one_income_number() -> void:
	var s := GameState.fresh()
	runner.check(is_equal_approx(DossierView.income_mult(s), 1.0), "nothing owned: ×1")
	s.owned[Content.producer_ids()[0]] = 30
	s.thumbs_owned = 10
	runner.check(DossierView.income_mult(s) > 1.5, "30 of a source and 10 base: more than ×1.5 (%s)" % DossierView.income_mult(s))
