class_name Overlays
extends RefCounted
## The concrete modals: SETTINGS, the fork's CONFIRM, PERKS and BOOK, and the names RESET_CONFIRM
## (O10), EVOLUTION (O3), OFFLINE (O1) and STORY (O3b), whose views live in ui/views/.
## Each builder returns an Overlay ready to request().


class SettingsOverlay:
	## O7 (ux/rtl-map.md §7.4): a bottom sheet, h = min(content, 70% of the screen), the body
	## scrolls beyond. ✕ top-left (hit 104), SET_TITLE centred, labels right-aligned at x 656,
	## captions under their label, the whole row is the hit (672 x row h), the switch on the left
	## with ON = knob left + fill (mirror), a fixed full-width "סגור" at the bottom.
	## Rows: sound (effects, music), accessibility (reduced motion + caption, haptics where
	## vibrate exists, large text + caption), game (About → the HTML page, reset → O10).
	## Manual test A6: every row is reachable on every phone. The sheet may rise to Row A's bottom
	## (`sheet_rect(.., tall)`) and, where the rows still do not fit, the group headers tighten
	## (GROUP_TIGHT; rows keep their 88 touch height); past that (large text on a 375×548) the body
	## scrolls with a visible thumb (Overlay.make_scroll).
	## A8: the switch shows its state by fill, knob side and word (SettingSwitch).
	extends Overlay
	var open_reset: Callable
	var _switches := {}          # key -> {view (SettingSwitch), state}
	var _built_large := false
	var compact := false         # the tight group headers (a short screen)
	const ROW := 88.0
	const CAP_ROW := 144.0
	const GROUP := 48.0
	const GROUP_TIGHT := 36.0
	const TEXT_W := 360.0        # string-budgets sheet.label / sheet.caption (x 296-656)
	const LABEL_DY := 26.0

	## mobile-first §5.11: a full-bleed sheet; labels, their captions and the danger icon R-anchored
	## (656 + dx), the switches left (L), the title centred, the rows and the bottom "סגור" stretched.
	func build() -> SettingsOverlay:
		id = "SETTINGS"
		full_bleed = true
		_built_large = PxText.large_text
		var th := Art.theme
		var rows: Array = [["g", "SET_GROUP_SOUND"], ["t", "sfx", "SET_SFX", ""], ["t", "music", "SET_MUSIC", ""],
			["g", "SET_GROUP_A11Y"], ["t", "reducedMotion", "SET_REDUCED_MOTION", "SET_MOTION_CAP"]]
		if host.haptics_available():
			rows.append(["t", "haptics", "SET_HAPTICS", ""])
		rows += [["t", "largeText", "SET_LARGE", "SET_LARGE_CAP"], ["g", "SET_GROUP_GAME"], ["about"], ["reset"]]
		# rtl-map §0.2: every row grows to its measured line count at the scale actually drawn, so
		# the content height is only known once the texts exist: build the rows first (in the body,
		# from y 0), then size the sheet and move the body under the header.
		var y := 0.0
		var placed: Array = []   # [row, y, h]
		var pr := Rect2()
		for pass_i in 2:
			compact = pass_i == 1
			y = 0.0
			placed.clear()
			for r: Array in rows:
				var h := _row_h(r)
				placed.append([r, y, h])
				y += h
			var content := 104.0 + y + 112.0 + 16.0
			pr = host.sheet_rect(content, true)
			if pr.size.y - float(host.bottom_inset()) >= content:
				break   # it fits: no scroll (the tight headers only when the roomy ones would scroll)
		make_panel(pr)
		var title := text(Vector2(0, pr.position.y + 24.0), Strings.s("SET_TITLE"), L.TEXT, th["modal"]["title"])
		title.fit_width = 432.0   # sheet.title
		title.center_in(pr.position.x + 144.0, pr.size.x - 288.0)
		var close := close_button(Rect2(pr.position.x + 16, pr.position.y + 16, 64, 64), Rect2(pr.position.x, pr.position.y, 104, 104), func() -> void: cancel("close"))
		var close_y := pr.end.y - 112.0 - float(host.bottom_inset())
		make_scroll(Rect2(pr.position.x, pr.position.y + 104.0, pr.size.x, close_y - pr.position.y - 104.0))
		var y0 := pr.position.y + 104.0
		for p: Array in placed:
			var r: Array = p[0]
			var ry: float = y0 + float(p[1])
			var h: float = p[2]
			match String(r[0]):
				"g":
					var g := PxText.make(body, Vector2(0, ry + (2.0 if compact else 8.0)), Strings.s(r[1]), L.TEXT, "plain", th["modal"]["groupLabel"])
					g.fit_width = TEXT_W   # sheet.group
					g.right_at(656.0 + L.dx)
				"t":
					_toggle(ry, h, r[1], r[2], r[3])
				"about":
					_row_button(ry, h, Strings.s("SET_ABOUT"), func() -> void:
						host.audio_event("uiClick")
						host.open_about(), null, -1.0, "about")
					var chev := PxText.make(body, Vector2(40, ry + LABEL_DY), "<", L.TEXT, "plain", th["modal"]["body"])
					chev.h_anchor = 0
				"reset":
					# rtl-map §7.4 danger row: the kit trash icon leads the label, on the right (R26)
					var trash := Art.has_sprite("icon_trash")
					_row_button(ry, h, Strings.s("SET_RESET"), func() -> void:
						host.audio_event("uiClick")
						open_reset.call(), th["modal"]["title"], 656.0 + L.dx - (48.0 if trash else 0.0), "reset")
					if trash:
						Ui.img(body, Vector2(620.0 + L.dx, ry + LABEL_DY), "icon_trash", 0, 4)
		content_bottom = y0 + y + 8.0
		var sc := button(Rect2(pr.position.x + 24, close_y + 12.0, 672.0 + L.dx, 88), Rect2(pr.position.x + 24, close_y + 12.0, 672.0 + L.dx, 88), Strings.s("SYS_CLOSE"),
			func() -> void: cancel("close"), "kit_secondary", L.TEXT)
		focusables.append(close)
		sync()
		return self

	## A settings text in its box (right-aligned at x 656, 360 wide): a label (1 line, 2 at ×5)
	## or a caption (2 lines, 3 at ×5), string-budgets sheet.label / sheet.caption.
	func _sheet_text(parent: Node, pos: Vector2, s: String, role: Variant, caption: bool, right: float = -1.0) -> PxText:
		if right < 0.0:
			right = 656.0 + L.dx
		var t := PxText.make(parent, pos, s, L.TEXT, "plain", role)
		t.reading = true   # settings labels and captions: the @2 reading cut where crisp
		t.wrap_width = TEXT_W
		t.max_lines = 2 if caption else 1
		t.max_lines_large = 3 if caption else 2
		t.right_at(right)
		return t

	static func _lh(t: PxText) -> float:
		return float(HeFont.line_height()) * t.eff_px()

	## The row height from the measured texts: a label row is 88 at ×4 (26 + one 44 line + 18); a
	## caption sits 2 px under the label and the row ends 16 px above its last caption line's
	## pitch (144 for a 1-line label over a 2-line caption at ×4, as the spec's table).
	func _row_h(r: Array) -> float:
		var th := Art.theme
		var probe_parent := Node2D.new()
		var h := ROW
		match String(r[0]):
			"g":
				var g := PxText.make(probe_parent, Vector2.ZERO, Strings.s(r[1]), L.TEXT, "plain", th["modal"]["groupLabel"])
				g.fit_width = TEXT_W
				h = (GROUP_TIGHT if compact else GROUP) + (_lh(g) - 44.0)
			"t", "about", "reset":
				var key: String = r[2] if r[0] == "t" else ("SET_ABOUT" if r[0] == "about" else "SET_RESET")
				var t := _sheet_text(probe_parent, Vector2.ZERO, Strings.s(key), th["modal"]["body"], false)
				var label_h := _lh(t) * float(maxi(1, t.line_count()))
				h = maxf(ROW, LABEL_DY + label_h + 18.0)
				if r[0] == "t" and String(r[3]) != "":
					var c := _sheet_text(probe_parent, Vector2.ZERO, Strings.s(r[3]), th["modal"]["note"], true)
					# the spec's 144 is the floor (a one-line caption keeps its air); rows only grow
					h = maxf(h, maxf(CAP_ROW, LABEL_DY + label_h + 2.0 + _lh(c) * float(maxi(1, c.line_count())) - 16.0))
		probe_parent.free()
		return ceilf(h / 4.0) * 4.0   # up to the 4-px grid: a row never cuts its last line

	func _row_button(y: float, h: float, label: String, on_commit: Callable, role: Variant = null, right: float = -1.0, row_id := "") -> void:
		var b := PxButton.make(body, Rect2(24, y, 672.0 + L.dx, h), {"hit": Rect2(24, y, 672.0 + L.dx, h), "ghost": true, "on_commit": on_commit})
		b.set_meta("row", row_id)   # window.odDev.modalRows (tools/web/mobile_web.mjs: every row reachable)
		focusables.append(b)
		body_focusables.append(b)
		_sheet_text(body, Vector2(0, y + LABEL_DY), label, role if role != null else Art.theme["modal"]["body"], false, right)

	func _toggle(y: float, h: float, key: String, label_key: String, cap_key: String) -> void:
		var th := Art.theme
		var b := PxButton.make(body, Rect2(24, y, 672.0 + L.dx, h), {"hit": Rect2(24, y, 672.0 + L.dx, h), "ghost": true,
			"on_commit": func() -> void:
				host.toggle_setting(key)
				sync()})
		b.set_meta("row", key)
		focusables.append(b)
		body_focusables.append(b)
		var t := _sheet_text(body, Vector2(0, y + LABEL_DY), Strings.s(label_key), th["modal"]["body"], false)
		if cap_key != "":
			_sheet_text(body, Vector2(0, y + LABEL_DY + _lh(t) * float(maxi(1, t.line_count())) + 2.0), Strings.s(cap_key), th["modal"]["note"], true)
		var sw := SettingSwitch.new()
		sw.position = Vector2(40, y + 14.0)   # rtl-map §7.4: visual Rect2(40, row.y + 14, 120, 60)
		body.add_child(sw)
		var st := PxText.make(body, Vector2(176, y + LABEL_DY), "", L.TEXT, "plain", th["modal"]["body"])
		st.fit_width = 104.0   # sheet.state x 176-280
		_switches[key] = {"view": sw, "state": st, "y": y}

	## Large text toggled from this sheet (rtl-map §0.2): the rows re-measure, so the sheet is rebuilt
	## in place (no enter motion), keeping the focus and the scroll.
	func rebuild_if_scale_changed() -> void:
		if _built_large == PxText.large_text or closing:
			return
		var fi := focus_index
		var sy := scroll
		# the pressed switch's PxButton still finishes its press on its old nodes (uiPressMinHoldMs):
		# park them hidden and free them a second later
		var old := Node2D.new()
		old.visible = false
		add_child(old)
		for c in panel.get_children():
			c.reparent(old, false)
		get_tree().create_timer(1.0).timeout.connect(old.queue_free)
		focusables.clear()
		body_focusables.clear()
		_switches.clear()
		body = null
		clip = null
		frame = null
		build()
		focus_index = clampi(fi, 0, maxi(0, focusables.size() - 1))
		set_scroll(sy)

	func sync() -> void:
		for key: String in _switches:
			var on: bool = host.setting_on(key)
			var sw: Dictionary = _switches[key]
			(sw["view"] as SettingSwitch).set_on(on)   # ON = flag fill + knob left (rtl-map §7.4, mirror)
			var st := sw["state"] as PxText
			st.text = Strings.s("SET_ON" if on else "SET_OFF")
			st.tint = SettingSwitch.C_ON if on else SettingSwitch.C_OFF_TEXT
		if _built_large != PxText.large_text:
			rebuild_if_scale_changed.call_deferred()

	func cancel(via: String) -> void:
		host.audio_event("panelClose")
		mgr.close(self, via)


## A8 (manual test 2026-09-30): the settings switch, drawn in code on the 4-px grid (30 × 15 art px at
## ×4; a new kit sprite is not needed: the fork's `ui_toggle` is the v2 lime/lavender and 36 art wide).
## ON: a flag-blue track, the white knob on the LEFT (rtl-map §7.4, `mirror`: the RTL platforms'
## ON side) and the word "פועל" in flag blue. OFF: a grey track, the knob on the right, "כבוי" in
## slate. Colour is never the only cue: the knob side and the word change too. Contrast on the sheet's
## paper (#fff4e0, sampled): the night outline 14.0:1 (the control's boundary, WCAG 1.4.11 ≥ 3:1 in both
## states), flag 8.5:1, slate 6.9:1 (text ≥ 4.5:1); the knob keeps its night outline on either track
## (8.4:1 on the grey). Corners step 1 art px twice (a pill).
class SettingSwitch:
	extends Node2D
	const SIZE := Vector2(120, 60)
	const KNOB := 44.0
	const C_LINE := Color("#0f2350")      # night
	const C_ON := Color("#0038b8")        # flag
	const C_OFF := Color("#b9c0cf")       # grey track
	const C_KNOB := Color("#ffffff")
	const C_OFF_TEXT := Color("#4a5470")  # slate
	var on := false

	func set_on(v: bool) -> void:
		if v != on:
			on = v
			queue_redraw()

	## The knob's rect (switch-local): left when ON (RTL mirror), right when OFF.
	func knob_rect() -> Rect2:
		return Rect2(8.0 if on else SIZE.x - 8.0 - KNOB, 8.0, KNOB, KNOB)

	func _pill(r: Rect2, c: Color) -> void:
		draw_rect(Rect2(r.position.x + 8.0, r.position.y, r.size.x - 16.0, r.size.y), c)
		draw_rect(Rect2(r.position.x + 4.0, r.position.y + 4.0, r.size.x - 8.0, r.size.y - 8.0), c)
		draw_rect(Rect2(r.position.x, r.position.y + 8.0, r.size.x, r.size.y - 16.0), c)

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, SIZE)
		_pill(r, C_LINE)
		_pill(r.grow(-4.0), C_ON if on else C_OFF)
		var k := knob_rect()
		_pill(k, C_LINE)
		_pill(k.grow(-4.0), C_KNOB)


## O10 / O3 / O1 are rebuilt as §7.1 sheet cards (ui/views/view_reset.gd, view_election.gd,
## view_return.gd; review R7, R8); these names stay so every caller (MainController, the store
## shots, the tests) gets them.
class ResetOverlay:
	extends ResetCard


class EvolutionOverlay:
	extends ElectionCard


class OfflineOverlay:
	extends ReturnCard


class ConfirmOverlay:
	extends Overlay
	var title := ""
	var lines: Array = []
	var confirm_label := ""
	var on_confirm: Callable

	func build() -> ConfirmOverlay:
		id = "CONFIRM"
		var LO: Dictionary = L.OVERLAY["reset"]
		var th := Art.theme
		backdrop_closes = false
		make_panel(LO["panel"])
		centered((LO["title"] as Vector2).y, title, 4, th["modal"]["title"])
		for i in mini(3, lines.size()):
			centered(float(LO["bodyY"][i]), lines[i], 3)
		button(LO["cancel"], LO["cancelHit"], Strings.s("RST_CANCEL"), func() -> void:
			host.audio_event("uiClick")
			cancel("close"))
		button(LO["confirm"], LO["confirmHit"], confirm_label, func() -> void:
			mgr.close(self, "confirm")
			on_confirm.call())
		return self

	func cancel(via: String) -> void:
		host.audio_event("panelClose")
		mgr.close(self, via)


## Shared list-row look for the scrolling overlays (the shop row: panel, plate, icon, two lines).
static func list_row(o: Overlay, y: float, k: int, icon: String, plate: int, name: String, line2: String, dim: bool) -> Dictionary:
	var th := Art.theme
	var afford_frames: Array = th["row"]["frames"]["cantAfford" if dim else "afford"]
	var panel := Ui.nine(o.body, Rect2(64, y, 592, 96), th["row"]["sprite"], int(afford_frames[k % 2]))
	var pl := Ui.nine(o.body, Rect2(72, y + 8, 80, 80), th["plate"]["sprite"], plate)
	var ic := Ui.img(o.body, Vector2(80, y + 16), icon, 0, 4)
	if dim:
		ic.modulate = Color(0.5, 0.5, 0.5)
	var n := PxText.make(o.body, Vector2(160, y + 24), name, 3, "plain", th["row"]["name"])
	var l2 := PxText.make(o.body, Vector2(160, y + 52), line2, 3, "plain", th["row"]["line2"])
	return {"panel": panel, "plate": pl, "icon": ic, "name": n, "line2": l2}


## A clause's icon (coalition UX rev 5, Bar's playtest: most rows drew the "?" placeholder). The
## content names fork ids (icon_wand, icon_aide, ...) that only partly exist; the od-sevev kit draws
## the same objects as the trophies (trophy_wand, trophy_aide, ..., 15×15 art), so a clause takes
## its trophy twin when there is one, else its own id, else the placeholder.
static func perk_icon(icon: String) -> String:
	var twin := "trophy_" + icon.trim_prefix("icon_")
	if icon.begins_with("icon_") and Art.has_sprite(twin):
		return twin
	return Art.sprite_or(icon)


class PerksOverlay:
	extends Overlay
	var _rows := {}
	var _have: PxText

	func build() -> PerksOverlay:
		id = "PERKS"
		var th := Art.theme
		var pr := Rect2(48, 160, 624, 952)
		make_panel(pr)
		text(Vector2(Ui.center_x(Strings.s("PERKS_TITLE"), 4, pr.position.x, pr.size.x), 200), Strings.s("PERKS_TITLE"), 4, th["modal"]["title"])
		var close := close_button(Rect2(592, 176, 64, 64), Rect2(568, 168, 104, 104), func() -> void: cancel("close"))
		Ui.img(panel, Vector2(80, 252), "icon_thumb", 0, 4)
		_have = text(Vector2(136, 264), "", 3)
		make_scroll(Rect2(56, 312, 608, 736))
		var y := 320.0
		var k := 0
		for p: Dictionary in Meta.perks():
			var id_: String = p["id"]
			var r := Overlays.list_row(self, y, k, Overlays.perk_icon(str(p["icon"])), int(th["plate"]["frames"]["upgradeGlobal"]), p["name"], "", false)
			var b := body_button(Rect2(488, y + 8, 160, 80), Rect2(472, y, 184, 96), "", func() -> void: _buy(id_), "pill", 3)
			var cost := PxText.make(body, Vector2(488, y + 52), "", 3, "plain", th["pill"]["labelBuy"])
			r["button"] = b
			r["cost"] = cost
			_rows[id_] = r
			y += 104.0
			k += 1
		content_bottom = y + 8.0
		centered(1064, Strings.s("PERKS_NOTE"), 2, th["modal"]["note"])
		focusables.append(close)
		_refresh()
		return self

	func _buy(id_: String) -> void:
		host.buy_perk(id_)
		_refresh()

	func _refresh() -> void:
		var s: GameState = host.state
		_have.text = Strings.s("PERKS_HAVE", {"n": Fmt.thumbs(s.thumbs_available())})
		for p: Dictionary in Meta.perks():
			var id_: String = p["id"]
			var r: Dictionary = _rows[id_]
			var lv := Meta.perk_level(s, id_)
			var levels: Array = p["levels"]
			var cost := Meta.next_cost(s, id_)
			var b: PxButton = r["button"]
			var line2 := ""
			if cost < 0:
				line2 = Strings.s("PERK_MAXED")
				b.set_label(Strings.s("PERK_MAX"))
				b.set_enabled(false)
				(r["cost"] as PxText).text = ""
			else:
				var fv := float(levels[lv])
				var vs := Fmt.amount(fv) if fv >= 1000.0 else (str(int(fv)) if is_equal_approx(fv, roundf(fv)) else str(fv))
				line2 = String(p["desc"]).replace("{v}", vs)
				if levels.size() > 1 and lv > 0:
					var lvl := Strings.s("PERK_LEVEL", {"lv": lv, "max": levels.size()})
					(r["name"] as PxText).text = String(p["name"]) + " " + lvl if (String(p["name"]) + " " + lvl).length() <= 18 else String(p["name"])
				var afford := s.thumbs_available() >= cost
				b.set_label(Strings.s("ROW_BUY" if afford else "ROW_NEED"))
				b.set_enabled(afford)
				var ct := r["cost"] as PxText
				ct.text = Fmt.thumbs(cost)
				ct.tint = Art.col(Art.theme["pill"]["labelBuy" if afford else "labelNeed"])
				ct.center_in(488, 160)
			if b.label:
				b.label.position.y = b.visual.position.y + 16.0
			(r["line2"] as PxText).text = line2

	func update_view(_dt_ms: float) -> void:
		_refresh()

	func cancel(via: String) -> void:
		host.audio_event("panelClose")
		mgr.close(self, via)


class BookOverlay:
	extends Overlay
	var tab := "trophies"
	var _tabs := {}
	var _pages := {}
	var _summary: PxText

	func build() -> BookOverlay:
		id = "BOOK"
		var th := Art.theme
		var pr := Rect2(48, 160, 624, 952)
		make_panel(pr)
		text(Vector2(Ui.center_x(Strings.s("BOOK_TITLE"), 4, pr.position.x, pr.size.x), 200), Strings.s("BOOK_TITLE"), 4, th["modal"]["title"])
		var close := close_button(Rect2(592, 176, 64, 64), Rect2(568, 168, 104, 104), func() -> void: cancel("close"))
		var tabs := host.book_tabs() as Array
		var tw := 560.0 / tabs.size()
		for i in tabs.size():
			var t: String = tabs[i]
			_tabs[t] = button(Rect2(80 + i * tw, 248, tw - 8, 72), Rect2(72 + i * tw, 240, tw, 88), Strings.s("BOOK_" + t.to_upper()),
				func() -> void: _show(t), "button", 3)
		_summary = centered(340, "", 3, th["modal"]["note"])
		make_scroll(Rect2(56, 376, 608, 720))
		_build_trophies()
		_build_stats()
		if (host.book_tabs() as Array).has("story"):
			_build_story()
		focusables.append(close)
		_show(tab)
		return self

	func _page() -> Node2D:
		var n := Node2D.new()
		body.add_child(n)
		return n

	func _build_trophies() -> void:
		var s: GameState = host.state
		var page := _page()
		var y := 384.0
		var k := 0
		var saved := body
		body = page
		for a: Dictionary in Meta.achievements():
			var got := s.achievements.has(a["id"])
			var secret: bool = a.get("secret", false)
			var name: String = a["name"] if (got or not secret) else Strings.s("TROPHY_LOCKED")
			var line2: String = a["desc"] if (got or not secret) else Strings.s("TROPHY_SECRET")
			var r := Overlays.list_row(self, y, k, a["icon"] if (got or not secret) else "ui_trophy", int(Art.theme["plate"]["frames"]["upgradeGlobal"]), name, line2, not got)
			if got:
				Ui.img(page, Vector2(584, y + 16), "ui_trophy", 0, 4)
			y += 104.0
			k += 1
		body = saved
		page.set_meta("bottom", y + 8.0)
		_pages["trophies"] = page

	func _build_stats() -> void:
		var s: GameState = host.state
		var d: Economy.Derived = host.d
		var page := _page()
		var th := Art.theme
		var fastest := float(s.stats.get("fastestRunSec", 0.0))
		var rows := [
			["ST_SPECIES", Content.species_title(s.evolutions).to_upper()],
			["ST_PLAYTIME", Fmt.clock(float(s.stats.get("playtimeSec", 0.0)))],
			["ST_ALLTIME", Fmt.amount(s.all_time_bananas)],
			["ST_BESTBPS", Fmt.rate(maxf(float(s.stats.get("bestBps", 0.0)), d.bps))],
			["ST_TAPS", Fmt.amount(float(s.taps_lifetime))],
			["ST_CRITS", Fmt.amount(float(s.crits_lifetime))],
			["ST_GOLDENS", Fmt.amount(float(s.golden_caught_lifetime))],
			["ST_MISSED", Fmt.amount(float(s.stats.get("goldenMissed", 0.0)))],
			["ST_EVOLUTIONS", str(s.evolutions)],
			["ST_FASTEST", Fmt.clock(fastest) if fastest > 0.0 else Strings.s("ST_NONE")],
			["ST_THUMBS", Fmt.thumbs(s.thumbs_owned)],
			["ST_SPENT", Fmt.thumbs(s.thumbs_spent)],
		]
		var y := 392.0
		for r: Array in rows:
			PxText.make(page, Vector2(80, y), Strings.s(r[0]), 3, "plain", th["modal"]["groupLabel"])
			var v := PxText.make(page, Vector2(0, y), r[1], 3, "plain", th["modal"]["body"])
			if String(r[0]) == "ST_SPECIES":
				v.position = Vector2(80, y + 32)
				y += 32.0
			else:
				v.position.x = 640.0 - v.width()
			Ui.rect(page, Rect2(80, y + 36, 560, 4), th["modal"]["divider"])
			y += 56.0
		page.set_meta("bottom", y)
		_pages["stats"] = page

	func _build_story() -> void:
		var s: GameState = host.state
		var page := _page()
		var th := Art.theme
		var y := 392.0
		if s.evolutions == 0:
			for l in [Strings.s("STORY_EMPTY_1"), Strings.s("STORY_EMPTY_2")]:
				var t := PxText.make(page, Vector2(0, y), l, 3, "plain", th["modal"]["note"])
				t.center_in(panel_rect.position.x, panel_rect.size.x)
				y += 36.0
		# B15: each election's card is the one its leader got (Story.archive, from story_seen), newest
		# first, headed by that card's title and the leader; without leader select, the round's beats
		var cards: Array = Story.archive(s) if Leaders.active() else []
		if cards.is_empty():
			for n in range(s.evolutions, 0, -1):
				cards.append({"leader": "", "title": Strings.s("STORY_EVOLUTION", {"n": n, "era": Story.era_for(n).get("name", "")}), "lines": Story.beat_for(n)})
		for c: Dictionary in cards:
			var head := str(c["title"])
			if head == "":
				head = Strings.s("STORY_EVOLUTION", {"n": int(c.get("n", 0)), "era": ""}).trim_suffix(": ")
			if str(c["leader"]) != "":
				head += " · " + LeaderUi.short(str(c["leader"]))
			PxText.make(page, Vector2(80, y), head, 3, "plain", th["modal"]["groupLabel"])
			y += 36.0
			for l in c["lines"]:
				PxText.make(page, Vector2(80, y), str(l), 3, "plain", th["modal"]["body"])
				y += 30.0
			Ui.rect(page, Rect2(80, y + 6, 560, 4), th["modal"]["divider"])
			y += 28.0
		page.set_meta("bottom", y)
		_pages["story"] = page

	func _show(t: String) -> void:
		if not _pages.has(t):
			return
		tab = t
		for k: String in _pages:
			(_pages[k] as Node2D).visible = k == t
		for k: String in _tabs:
			(_tabs[k] as PxButton).set_enabled(k != t)
		content_bottom = float((_pages[t] as Node2D).get_meta("bottom", 0.0))
		set_scroll(0.0)
		var s: GameState = host.state
		if t == "trophies":
			var pct := Meta.achievement_pct(s) * s.achievements.size() * 100.0
			_summary.text = Strings.s("TROPHY_SUMMARY", {"n": s.achievements.size(), "total": Meta.achievements().size(), "pct": Fmt.mult(pct).trim_suffix(".0")})
		else:
			_summary.text = ""
		_summary.center_in(panel_rect.position.x, panel_rect.size.x)
		host.audio_event("uiClick")

	func cancel(via: String) -> void:
		host.audio_event("panelClose")
		mgr.close(self, via)


## O3b: the fork's story card is rebuilt as Dubi's news flash (ui/views/view_flash.gd, rtl-map
## §7.2); this name stays so every caller (the election, the store shots, a T4 archive) gets it.
class StoryOverlay:
	extends FlashCard
