extends RefCounted
## The investigation on screen (ui/views/view_thermo.gd, ui/views/view_court.gd): the thermometer
## tracks Investigation.suspicion (fill rows, floor hatch, state word, icon), the sweat rides Bibi's
## per-frame `temple` landmark, the summons opens the O2 card whose buttons go through
## Investigation.testify / postpone / drop_aide, and courtStart / courtEnd(reason) reach the Audio
## with the sim's reason (testified | served | postponed, the last on the stamp's impact). The real
## scene boots on the game content with a throwaway save folder.

var runner: Object
var tree: SceneTree
var dir := ""
var m: Node
var heard: Array = []


func setup(r: Object) -> void:
	TestFixture.use_game_content()
	tree = r as SceneTree
	dir = "user://test_court_%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(dir)


func teardown() -> void:
	if m and is_instance_valid(m):
		m.set_process(false)
		if m.get_parent():
			m.get_parent().remove_child(m)
		m.queue_free()
	var d := DirAccess.open(dir)
	if d:
		for f in d.get_files():
			d.remove(f)
	DirAccess.remove_absolute(dir)


func _boot() -> void:
	m = load("res://scenes/main.tscn").instantiate()
	m.store = SaveStore.new(dir)
	tree.root.add_child(m)
	for i in 3:
		await tree.process_frame
	m.ftue.handoff_ms = 1.0
	m.commit_pick("bibi")   # LEADER_PICK (leader select): Bibi's round, the shipped game
	_touch(_stage_pt(L.magician_hit().get_center()))   # title → main (tap 1)
	m._last_tap_ms = -1e9                                # past the card's tap-burst guard
	m.audio_sent.connect(func(n: String, a: Variant) -> void: heard.append([n, a]))


func _touch(p: Vector2, idx: int = 0) -> void:
	for pressed in [true, false]:
		var e := InputEventScreenTouch.new()
		e.index = idx
		e.position = p
		e.pressed = pressed
		m._unhandled_input(e)


func _stage_pt(p: Vector2) -> Vector2:
	return p + Vector2(m._sx, m._stage_y)


func _lower_pt(p: Vector2) -> Vector2:
	return p + Vector2(m._ox, m._lower_y)


func _heard(name: String) -> Array:
	return heard.filter(func(h: Array) -> bool: return h[0] == name)


func _thermo_settle(s: float) -> void:
	m.state.investigation["suspicion"] = s
	for i in 3:
		m.thermo.update_view(400.0, m.state, {"main": true})


## Suspicion at max → one economy step → the sim's summons → the card opens.
func _summon() -> void:
	m.state.investigation["revealed"] = true
	m.state.investigation["suspicion"] = 100.0
	m._step_economy(1.0 / 60.0, false)
	await tree.process_frame
	await tree.process_frame
	m.court._anim = {}   # skip the card's entry motion: aim at the settled card
	await tree.process_frame


# ------------------------------------------------------------------ the thermometer

func test_the_thermometer_tracks_suspicion() -> void:
	await _boot()
	var th: Thermo = m.thermo
	await tree.process_frame
	runner.check(not th.is_shown(), "hidden before K1")
	m.state.investigation["revealed"] = true
	_thermo_settle(50.0)
	runner.check(th.is_shown(), "K1: the thermometer shows once the sim reveals it")
	# the tube follows the split (mobile-first §3.2): the full 70-row column at S ≥ 560, the short
	# piece below (the unit harness's 1280 canvas gives S 512)
	var column := int(th._liquid["yBottom"]) - int(th._liquid["yTop"])
	runner.check(th.shown_rows() == th.rows_for(50.0) and th.shown_rows() == column / 2 and (column == 70 or L.stage_h < 560.0),
		"50%% fills y_top(0.5) = half the kit's %d-row column (%d rows)" % [column, th.shown_rows()])
	runner.check(th.word().text == Strings.s("HUD_SUSP") and th.icon_id() == "thermo_icon_magnifier", "below 75%: 'חשד' and the magnifier")
	_thermo_settle(80.0)
	runner.check(th.shown_rows() == th.rows_for(80.0), "the fill follows the sim (%d rows)" % th.shown_rows())
	runner.check(th.word().text == Strings.s("HUD_SUSP_HOT") and th.icon_id() == "thermo_icon_gavel", "75%+: 'מבעבע' and the gavel (the non-colour channel)")
	_thermo_settle(96.0)
	runner.check(th.word().text == Strings.s("HUD_SUSP_BOIL"), "95%+: 'רותח!'")
	m.state.evolutions = 2
	_thermo_settle(12.0)
	runner.check(th._hatch.visible and int(th._hatch.size.y) == th.rows_for(Investigation.floor_pct(m.state)),
		"the carried floor (%.0f%%) is the hatched segment" % Investigation.floor_pct(m.state))
	var tr: Rect2 = th.tube_rect()
	runner.check(tr.position.x == 44.0 and tr.end.y == float(L.STAGE["y"]) + L.stage_h - 140.0, "the tube at x 44, its bottom at S − 140 (rtl-map §4)")
	var hr: Rect2 = th.hit_rect()
	var want_h := 404.0 if L.stage_h >= 560.0 else float(L.STAGE["y"]) + L.stage_h - 140.0 - th.icon_top()
	runner.check(hr.size == Vector2(120, want_h) and not hr.intersects(L.magician_hit()), "the 120×%d hit clears the Magician's" % want_h)


func test_the_sweat_rides_the_temple_landmark() -> void:
	await _boot()
	var th: Thermo = m.thermo
	m.state.investigation["revealed"] = true
	_thermo_settle(80.0)
	var bb: Magician = m.bb
	bb._state = "idle"   # the boot tap's squash has settled (the spawn gate wants the idle body)
	bb.hero.play("idle")
	th._next_drop = 0.0
	th.update_view(16.0, m.state, {"main": true})
	runner.check(not th.drops().is_empty(), "at 75%+ the Magician sweats")
	if th.drops().is_empty():
		return
	# the manifest's own numbers: temple[frame] in sprite px, drawn at artScale / density
	var c: Dictionary = SpriteStrip.manifest()["chars"]["bibi"]
	var a: Dictionary = c["anims"][bb.hero.anim]
	var tp: Array = a["temple"][bb.hero.frame]
	var anchor := Vector2(float(c["anchor"][0]), float(c["anchor"][1]))
	var sc := float(SpriteStrip.art_scale()) / float(SpriteStrip.density_of(c))
	var want := bb.hero.position + (Vector2(float(tp[0]), float(tp[1])) - anchor) * sc
	runner.check(th.temple().is_equal_approx(want), "the drop anchors on temple[frame] × artScale/density (%s vs %s)" % [str(th.temple()), str(want)])
	var spr: Sprite2D = th.drops()[0]["spr"]
	var piv: Array = Art.kit("sweat_drop")["pivot"]
	runner.check(spr.position.is_equal_approx((want - Vector2(float(piv[0]), float(piv[1])) * 4.0).snapped(Vector2(4, 4))),
		"with the kit's pivot on the landmark (%s)" % str(spr.position))
	for i in 60:
		th.update_view(50.0, m.state, {"main": true})
	runner.check(th.drops().size() <= 2, "nervous: at most 2 drops alive (%d)" % th.drops().size())
	_thermo_settle(40.0)
	for i in 20:
		th.update_view(50.0, m.state, {"main": true})
	runner.check(th.drops().is_empty(), "below 75% the live drops finish their fall and no new ones come")
	th.reduced_motion = true
	_thermo_settle(90.0)
	runner.check(th.bead_visible() and th.drops().is_empty(), "reduced motion: one static bead at the temple, no falling drops")


# ------------------------------------------------------------------ the court card

func test_the_summons_opens_the_card_and_testify_goes_through_the_sim() -> void:
	await _boot()
	await _summon()
	var cv: CourtView = m.court
	runner.check(Investigation.phase(m.state) == "summons", "the sim summoned")
	runner.check(cv.card_visible() and cv.mode() == "open", "the summons opens the O2 card (mode %s)" % cv.mode())
	runner.check(not _heard("courtSummons").is_empty(), "courtSummons reached the Audio")
	var cr: Rect2 = cv.card_rect()
	runner.check(is_equal_approx(cr.end.y, L.tabs_y()) and cr.position.x == 16.0 and cr.size.x == 688.0, "the card sits on the tab bar, 688 wide (%s)" % str(cr))
	var pr: Rect2 = cv.button_rect("primary")
	var tr: Rect2 = cv.button_rect("testify")
	runner.check(pr.position.x < tr.position.x, "RTL: the primary (postpone) on the left, testify on the right")
	_touch(_lower_pt(tr.get_center()))
	runner.check(Investigation.phase(m.state) == "court", "'להעיד' is Investigation.testify (phase %s)" % Investigation.phase(m.state))
	var cs := _heard("courtStart")
	runner.check(cs.size() == 1, "courtStart reached the Audio once")
	cv.update_view(CourtView.mc("courtCollapseMs") + 20.0, m.state, m.d, {"main": true})
	cv.update_view(16.0, m.state, m.d, {"main": true})
	runner.check(cv.mode() == "chip" and cv.chip_visible(), "testimony runs in the ticker chip (mode %s)" % cv.mode())
	runner.check(m.ticker._court_on and m.ticker._clip.position.x >= cv.chip_rect().end.x, "the chip takes the date chip's slot; the crawl starts after it")
	# the testimony ends: courtEnd("testified")
	m.state.investigation["leftSec"] = 0.001
	m._step_economy(1.0 / 60.0, false)
	var ce := _heard("courtEnd")
	runner.check(ce.size() == 1 and ce[0][1] == "testified", "courtEnd carries the sim's reason 'testified' (%s)" % str(ce))
	cv.update_view(16.0, m.state, m.d, {"main": true})
	runner.check(not cv.chip_visible() and not m.ticker._court_on, "the chip leaves and the date chip returns")


func test_a_summons_left_alone_is_served() -> void:
	await _boot()
	await _summon()
	m.state.investigation["summonsSec"] = float(Investigation.cfg()["summonsAutoTestifySec"])
	m._step_economy(1.0 / 60.0, false)
	runner.check(Investigation.phase(m.state) == "court", "the summons testified by itself")
	m.state.investigation["leftSec"] = 0.001
	m._step_economy(1.0 / 60.0, false)
	var ce := _heard("courtEnd")
	runner.check(ce.size() == 1 and ce[0][1] == "served", "courtEnd('served') (%s)" % str(ce))


func test_postpone_pays_stamps_and_fires_court_end_postponed() -> void:
	await _boot()
	Economy.add_money(m.state, 1.0e6)
	await _summon()
	var cv: CourtView = m.court
	m.d = Economy.derive(m.state)
	var cost := Investigation.postpone_cost(m.state, m.d)
	var before: float = m.state.money
	m.toasts._queue.clear()
	heard.clear()
	_touch(_lower_pt(cv.button_rect("primary").get_center()))
	runner.check(Investigation.phase(m.state) == "postponed" and int(m.state.investigation["postponements"]) == 1,
		"'התייעצות ביטחונית' is Investigation.postpone (phase %s)" % Investigation.phase(m.state))
	runner.check(is_equal_approx(before - m.state.money, cost), "it cost the sim's price (%s of %s)" % [str(before - m.state.money), str(cost)])
	runner.check(cv.mode() == "postponed", "the card shows the postponement")
	runner.check(_heard("courtEnd").is_empty(), "courtEnd waits for the stamp's impact")
	await tree.process_frame
	cv.update_view(100.0, m.state, m.d, {"main": true})
	var ce := _heard("courtEnd")
	runner.check(ce.size() == 1 and ce[0][1] == "postponed", "courtEnd('postponed') on the impact (+90 ms) (%s)" % str(ce))
	runner.check(cv.stamp_visible(), "the 'נדחה' stamp sits over the body")
	cv.update_view(400.0, m.state, m.d, {"main": true})
	runner.check(cv.excuse_text() == CourtView.excuse(1) and CourtView.excuse(1) != "", "the excuse is step 1 of the content ladder (%s)" % cv.excuse_text())
	runner.check(not m.toasts._queue.has(Strings.s("TOAST_COURT_END")), "a postponement is not 'the testimony ended'")
	cv.update_view(float(CourtView.mc("excuseReadMinMs")) + 60.0 * CourtView.excuse(1).length() + 500.0, m.state, m.d, {"main": true})
	cv.update_view(200.0, m.state, m.d, {"main": true})
	runner.check(not cv.card_visible(), "after the reading hold the card leaves")
	runner.check(CourtView.excuse(2).begins_with(CourtView.excuse(1).trim_suffix(".")), "the next excuse is one sentence longer")


func test_postponing_without_the_money_does_not_pay() -> void:
	await _boot()
	m.state.owned[Content.producer_ids()[0]] = 10   # some income: the price floor is seconds of ₪/s
	await _summon()
	var cv: CourtView = m.court
	m.state.money = 0.0
	m.d = Economy.derive(m.state)
	runner.check(Investigation.postpone_cost(m.state, m.d) > 0.0, "the postponement has a price")
	await tree.process_frame
	heard.clear()
	cv._press = {"kind": "primary"}
	cv.pointer_up(cv.button_rect("primary").get_center())
	runner.check(Investigation.phase(m.state) == "summons", "no money, no postponement")
	runner.check(not _heard("cantAfford").is_empty(), "the can't-afford cue plays")


func test_the_aide_drop_goes_through_the_sim() -> void:
	await _boot()
	m.state.investigation["aideHolding"] = 500.0
	m.state.evolutions = 1
	await _summon()
	var cv: CourtView = m.court
	runner.check(cv._aide != null, "while an aide holds suitcase money the card offers 'אני לא מכיר אותו'")
	cv.confirm_aide_drop()
	var o := m.overlays.top() as CourtView.AideConfirm
	runner.check(o != null and not o.backdrop_closes, "a stacked confirm the backdrop does not close")
	runner.check(o != null and o.default_focus() == 1, "focus starts on cancel")
	runner.check(cv.drop_aide(), "confirm → Investigation.drop_aide")
	runner.check(int(m.state.investigation["aideDrops"]) == 1 and Investigation.phase(m.state) == "idle", "the summons closes")
	runner.check(is_equal_approx(Investigation.suspicion(m.state), Investigation.floor_pct(m.state)), "suspicion falls to the round's floor")
	cv.update_view(16.0, m.state, m.d, {"main": true})
	cv.update_view(CourtView.mc("courtCardOutMs") + 20.0, m.state, m.d, {"main": true})
	runner.check(not cv.card_visible(), "the card leaves with the summons")


# ------------------------------------------------------------------ views wave (review R10, R21)

func test_the_summons_and_the_testimony_have_their_own_texts() -> void:
	await _boot()
	await _summon()
	var cv: CourtView = m.court
	cv.update_view(16.0, m.state, m.d, {"main": true})
	var left := float(Investigation.cfg().get("summonsAutoTestifySec", 0.0))
	runner.check(cv._title.text == Strings.s("COURT_SUMMONS_TITLE") and cv._body.text == Strings.s("COURT_SUMMONS_BODY")
		and cv._effect.text == Strings.s("COURT_SUMMONS_EFFECT"), "the summons card says a testimony is coming, not that income is slowed")
	runner.check(cv._timer.text == Strings.s("COURT_SUMMONS_TIMER", {"mmss": ChatView.mmss(left)}),
		"its timer counts down to the testimony (%s)" % cv._timer.text)
	cv.collapse()
	cv.update_view(CourtView.mc("courtCollapseMs") + 20.0, m.state, m.d, {"main": true})
	cv.update_view(16.0, m.state, m.d, {"main": true})
	runner.check(cv.chip_visible() and cv._chip_title.text == Strings.s("COURT_CHIP_SUMMONS"), "the folded summons chip reads COURT_CHIP_SUMMONS (%s)" % cv._chip_title.text)
	cv.testify()
	cv.update_view(16.0, m.state, m.d, {"main": true})
	runner.check(cv._chip_title.text == Strings.s("COURT_CHIP_TITLE"), "the testimony's chip reads COURT_CHIP_TITLE (%s)" % cv._chip_title.text)
	cv.expand()
	cv.update_view(CourtView.mc("courtExpandMs") + 20.0, m.state, m.d, {"main": true})
	var sec := float(m.state.investigation.get("leftSec", 0.0))
	runner.check(cv._title.text == Strings.s("COURT_TITLE") and cv._body.text == Strings.s("COURT_BODY")
		and cv._timer.text == Strings.s("COURT_TIMER", {"mmss": ChatView.mmss(sec)}), "the card rebuilt on the phase edge: the testimony texts and its own timer (%s)" % cv._timer.text)


func test_the_court_card_over_a_tall_tab_pads_it_and_esc_folds_it_first() -> void:
	await _boot()
	await _summon()
	var cv: CourtView = m.court
	var chat: ChatView = m.chat
	Coalition.open_group(m.state, m.d, func() -> float: return 0.0)
	var ids := Content.producer_ids()
	for i in 3:
		m.state.owned[ids[i]] = 1   # C1's tab slot
	for i in 2:
		await tree.process_frame
	_touch(_lower_pt(Vector2(270, L.tabs_y() + 52)))   # the coalition slot, under the expanded card
	runner.check(chat.is_open(), "the tab slot opens T3 under the expanded card")
	chat._end_anim(true)
	chat.reveal_all()
	await tree.process_frame
	runner.check(cv.card_visible() and cv.pad_height() > 0.0, "the court card is expanded over T3")
	runner.check(is_equal_approx(chat.bottom_pad(), cv.pad_height() - ChatView.COMPOSER_H),
		"the thread pads its bottom by the card above the composer (%s)" % chat.bottom_pad())
	runner.check(chat._max_scroll() >= chat._content_h + chat.bottom_pad() - chat.thread_h() - 0.5, "so its last rows scroll clear of the card")
	var e := InputEventKey.new()
	e.keycode = KEY_ESCAPE
	e.pressed = true
	m._unhandled_input(e)
	runner.check(chat.is_open(), "Esc with the card expanded does not close T3")
	cv.update_view(CourtView.mc("courtCollapseMs") + 20.0, m.state, m.d, {"main": true, "covered": true})
	runner.check(cv.mode() == "chip" and not m.overlays.is_open(), "it folds the court card, and opens no settings (mode %s)" % cv.mode())
	await tree.process_frame
	runner.check(chat.bottom_pad() == 0.0, "the pad goes with the card")
	for i in 10:
		await tree.process_frame
	var av: Dictionary = {}
	for h: Dictionary in chat.hits():
		if h["kind"] == "partner" and av.is_empty():
			av = h
	if not av.is_empty():
		chat._open_ms -= 1000.0   # headless frames are short: past the 140 ms input guard
		_touch(_lower_pt(chat.content_to_tall((av["rect"] as Rect2).get_center()) + chat.position))
		await tree.process_frame
		runner.check(m.overlays.has_id("PARTNER_CARD"), "the first tap after the fold reaches the thread (an avatar opens its card)")
		m.overlays.close_all()
		for i in 20:
			await tree.process_frame
	m._unhandled_input(e)
	runner.check(not chat.is_open(), "the next Esc closes T3")
	m.dossier.open()
	cv.expand()
	cv.update_view(CourtView.mc("courtExpandMs") + 20.0, m.state, m.d, {"main": true, "covered": true})
	runner.check(is_equal_approx(m.dossier.bottom_pad(), cv.pad_height()), "T4's list pads by the whole card (%s)" % m.dossier.bottom_pad())
	# during the testimony too: the chip unfolds the card, and T3 opened under it keeps it
	m.dossier.close()
	cv.testify()
	cv.update_view(CourtView.mc("courtCollapseMs") + 20.0, m.state, m.d, {"main": true})
	cv.update_view(16.0, m.state, m.d, {"main": true})
	runner.check(cv.mode() == "chip", "testimony runs in the chip (%s)" % cv.mode())
	cv.expand()
	for i in 20:
		await tree.process_frame
	_touch(_lower_pt(Vector2(270, L.tabs_y() + 52)))
	for i in 20:
		await tree.process_frame
	runner.check(chat.is_open() and cv.card_visible() and cv.mode() == "open", "the testimony card stays over T3 (mode %s, open %s)" % [cv.mode(), chat.is_open()])
