class_name Overlays
extends RefCounted
## The concrete modals: SETTINGS, RESET_CONFIRM, EVOLUTION and OFFLINE ("WELCOME BACK!").
## Layouts are ux/hud-layout.md §11, literally. Each builder returns an Overlay ready to request().


class SettingsOverlay:
	## O7 (ux/rtl-map.md §7.4): a bottom sheet, h = min(content, 70% of the screen), the body
	## scrolls beyond. ✕ top-left (hit 104), SET_TITLE centred, labels right-aligned at x 656,
	## captions under their label, the whole row is the hit (672 x row h), the switch on the left
	## with ON = knob left + fill (mirror), a fixed full-width "סגור" at the bottom.
	## Rows: sound (effects, music), accessibility (reduced motion + caption, haptics where
	## vibrate exists, large text + caption), game (About → the HTML page, reset → O10).
	extends Overlay
	var open_reset: Callable
	var _switches := {}          # key -> {track, fill, knob, state}
	const ROW := 88.0
	const CAP_ROW := 144.0
	const GROUP := 48.0

	func build() -> SettingsOverlay:
		id = "SETTINGS"
		var th := Art.theme
		var rows: Array = [["g", "SET_GROUP_SOUND"], ["t", "sfx", "SET_SFX", ""], ["t", "music", "SET_MUSIC", ""],
			["g", "SET_GROUP_A11Y"], ["t", "reducedMotion", "SET_REDUCED_MOTION", "SET_MOTION_CAP"]]
		if host.haptics_available():
			rows.append(["t", "haptics", "SET_HAPTICS", ""])
		rows += [["t", "largeText", "SET_LARGE", "SET_LARGE_CAP"], ["g", "SET_GROUP_GAME"], ["about"], ["reset"]]
		var content := 104.0
		for r: Array in rows:
			content += GROUP if r[0] == "g" else (CAP_ROW if (r[0] == "t" and r[3] != "") else ROW)
		content += 112.0 + 16.0
		var pr: Rect2 = host.sheet_rect(content)
		make_panel(pr)
		var title := text(Vector2(0, pr.position.y + 24.0), Strings.s("SET_TITLE"), L.TEXT, th["modal"]["title"])
		title.center_in(pr.position.x + 144.0, pr.size.x - 288.0)
		var close := close_button(Rect2(pr.position.x + 16, pr.position.y + 16, 64, 64), Rect2(pr.position.x, pr.position.y, 104, 104), func() -> void: cancel("close"))
		var close_y := pr.end.y - 112.0 - float(host.bottom_inset())
		make_scroll(Rect2(pr.position.x, pr.position.y + 104.0, pr.size.x, close_y - pr.position.y - 104.0))
		var y := pr.position.y + 104.0
		for r: Array in rows:
			match String(r[0]):
				"g":
					var g := PxText.make(body, Vector2(0, y + 8.0), Strings.s(r[1]), L.TEXT, "plain", th["modal"]["groupLabel"])
					g.right_at(656.0)
					y += GROUP
				"t":
					var h := CAP_ROW if r[2] != "" and String(r[3]) != "" else ROW
					_toggle(y, h, r[1], r[2], r[3])
					y += h
				"about":
					_row_button(y, Strings.s("SET_ABOUT"), func() -> void:
						host.audio_event("uiClick")
						host.open_about())
					var chev := PxText.make(body, Vector2(40, y + 26.0), "<", L.TEXT, "plain", th["modal"]["body"])
					chev.h_anchor = 0
					y += ROW
				"reset":
					_row_button(y, Strings.s("SET_RESET"), func() -> void:
						host.audio_event("uiClick")
						open_reset.call(), th["modal"]["title"])
					y += ROW
		content_bottom = y + 8.0
		var sc := button(Rect2(pr.position.x + 24, close_y + 12.0, 672, 88), Rect2(pr.position.x + 24, close_y + 12.0, 672, 88), Strings.s("SYS_CLOSE"),
			func() -> void: cancel("close"), "kit_secondary", L.TEXT)
		focusables.append(close)
		sync()
		return self

	func _row_button(y: float, label: String, on_commit: Callable, role: Variant = null) -> void:
		var b := PxButton.make(body, Rect2(24, y, 672, ROW), {"hit": Rect2(24, y, 672, ROW), "ghost": true, "on_commit": on_commit})
		focusables.append(b)
		body_focusables.append(b)
		var t := PxText.make(body, Vector2(0, y + 26.0), label, L.TEXT, "plain", role if role != null else Art.theme["modal"]["body"])
		t.wrap_width = 360.0
		t.max_lines = 1
		t.right_at(656.0)

	func _toggle(y: float, h: float, key: String, label_key: String, cap_key: String) -> void:
		var th := Art.theme
		var b := PxButton.make(body, Rect2(24, y, 672, h), {"hit": Rect2(24, y, 672, h), "ghost": true,
			"on_commit": func() -> void:
				host.toggle_setting(key)
				sync()})
		focusables.append(b)
		body_focusables.append(b)
		var t := PxText.make(body, Vector2(0, y + 26.0), Strings.s(label_key), L.TEXT, "plain", th["modal"]["body"])
		t.wrap_width = 360.0
		t.max_lines = 1
		t.right_at(656.0)
		if cap_key != "":
			var c := PxText.make(body, Vector2(0, y + 72.0), Strings.s(cap_key), L.TEXT, "plain", th["modal"]["note"])
			c.wrap_width = 360.0
			c.max_lines = 2
			c.right_at(656.0)
		var track := Ui.rect(body, Rect2(40, y + 14.0, 120, 60), Color("#1b1426"))
		var fill := Ui.rect(body, Rect2(44, y + 18.0, 112, 52), Color("#0038b8"))
		var knob := Ui.rect(body, Rect2(44, y + 18.0, 52, 52), Color("#f7f4ec"))
		var st := PxText.make(body, Vector2(176, y + 26.0), "", L.TEXT, "plain", th["modal"]["body"])
		_switches[key] = {"fill": fill, "knob": knob, "state": st, "y": y}

	func sync() -> void:
		for key: String in _switches:
			var on: bool = host.setting_on(key)
			var sw: Dictionary = _switches[key]
			(sw["fill"] as ColorRect).visible = on
			# ON = knob left (rtl-map §7.4, mirror)
			(sw["knob"] as ColorRect).position.x = 44.0 if on else 104.0
			(sw["state"] as PxText).text = Strings.s("SET_ON" if on else "SET_OFF")

	func cancel(via: String) -> void:
		host.audio_event("panelClose")
		mgr.close(self, via)


class ResetOverlay:
	extends Overlay

	func build() -> ResetOverlay:
		id = "RESET_CONFIRM"
		var LO: Dictionary = L.OVERLAY["reset"]
		var th := Art.theme
		backdrop_closes = false
		make_panel(LO["panel"])
		text(LO["title"], Strings.s("RST_TITLE"), 4, th["modal"]["title"])
		var body := [Strings.s("RST_BODY_1"), Strings.s("RST_BODY_2"), Strings.s("RST_BODY_3")]
		for i in 3:
			centered(float(LO["bodyY"][i]), body[i], 3)
		centered(float(LO["noteY"]), Strings.s("RST_NOTE"), 3, th["modal"]["note"])
		button(LO["cancel"], LO["cancelHit"], Strings.s("RST_CANCEL"), func() -> void:
			host.audio_event("uiClick")
			cancel("close"))
		button(LO["confirm"], LO["confirmHit"], Strings.s("RST_CONFIRM"), func() -> void: host.confirm_reset(), "danger")
		return self

	func cancel(via: String) -> void:
		host.audio_event("panelClose")
		mgr.close(self, via)


class EvolutionOverlay:
	extends Overlay
	var _ready_state := false
	var _gain_icon: Sprite2D
	var _gain_text: PxText
	var _bar_track: NinePatchRect
	var _bar_fill: NinePatchRect
	var _bonus: PxText
	var _mult: PxText
	var _need: PxText
	var _confirm: PxButton
	var _not_ready: PxText
	var committed := false

	func build() -> EvolutionOverlay:
		id = "EVOLUTION"
		var LO: Dictionary = L.OVERLAY["evolution"]
		var th := Art.theme
		var s: GameState = host.state
		make_panel(LO["panel"])
		text(LO["title"], Strings.s("EVO_TITLE"), 4, th["modal"]["title"])
		var close := close_button(LO["closeVisual"], LO["closeHit"], func() -> void: cancel("close"))
		centered(264, Strings.s("EVO_NEXT"), 3, th["modal"]["note"])
		centered(296, Content.species_title(s.evolutions + 1).to_upper(), 3)
		_gain_icon = Ui.img(panel, Vector2(0, 352), "icon_thumb", 0, 4)
		_gain_text = text(Vector2(0, 370), "", 4)
		var bar: Rect2 = LO["bar"]
		_bar_track = Ui.nine(panel, bar, "ui_bar_track", 0)
		_bar_fill = Ui.nine(panel, Rect2(bar.position, Vector2(8, bar.size.y)), "ui_bar_fill", 0)
		_bonus = centered(472, "", 3, th["modal"]["note"])
		_mult = centered(504, "", 4)
		Ui.rect(panel, Rect2(80, 560, 560, 4), th["modal"]["divider"])
		text(Vector2(80, 584), Strings.s("EVO_RESETS"), 3, th["modal"]["groupLabel"])
		text(Vector2(376, 584), Strings.s("EVO_KEEPS"), 3, th["modal"]["groupLabel"])
		var R := ["EVO_R1", "EVO_R2", "EVO_R3", "EVO_R4"]
		var K := ["EVO_K1", "EVO_K2", "EVO_K3", "EVO_K4"]
		var ys := [624, 652, 680, 708]
		for i in 4:
			text(Vector2(80, ys[i]), Strings.s(R[i]), 3)
			text(Vector2(376, ys[i]), Strings.s(K[i]), 3)
		Ui.rect(panel, Rect2(80, 752, 560, 4), th["modal"]["divider"])
		_need = centered(776, "", 3)
		centered(812, Strings.s("EVO_RULE_1"), 3)
		centered(840, Strings.s("EVO_RULE_2"), 3)
		centered(880, Strings.s("EVO_GROW"), 3, th["modal"]["note"])
		button(LO["back"], LO["backHit"], Strings.s("EVO_BACK"), func() -> void: cancel("close"))
		_confirm = button(LO["confirm"], LO["confirmHit"], Strings.s("EVO_CONFIRM"), _do_confirm, "evolve")
		var cr: Rect2 = LO["confirm"]
		_not_ready = centered(cr.position.y + 38, Strings.s("EVO_NOT_READY"), 3, th["evolve"]["labelNotReady"], Vector2(cr.position.x, cr.size.x))
		focusables.append(close)
		_refresh(true)
		return self

	func default_focus() -> int:
		return 1 if (host.d as Economy.Derived).evolve_enabled else 0

	func _refresh(force: bool = false) -> void:
		var s: GameState = host.state
		var d: Economy.Derived = host.d
		var ready := d.evolve_enabled
		var changed := ready != _ready_state or force
		_ready_state = ready
		if ready:
			_gain_text.text = Strings.s("EVO_THUMBS_GAIN", {"pending": Fmt.thumbs(d.pending)})
		else:
			_gain_text.text = Strings.s("EVO_THUMBS_PROGRESS", {"pending": Fmt.thumbs(d.pending), "needed": Fmt.thumbs(d.needed, "ceil")})
		var group_w := 64.0 + 16.0 + _gain_text.width()
		var gx := 4.0 * floorf((L.W - group_w) / 2.0 / 4.0)
		_gain_icon.position.x = gx
		_gain_text.position.x = gx + 80.0
		var after := 1.0 + Economy.mult_per_base() * (s.thumbs_owned + (d.pending if ready else d.needed))   # od-sevev: the sim's prestige rule
		_mult.text = Strings.s("EVO_MULT", {"now": Fmt.mult(d.prestige_mult), "after": Fmt.mult(after)})
		_mult.center_in(panel_rect.position.x, panel_rect.size.x)
		_need.text = Strings.s("EVO_NEED", {"needed": Fmt.thumbs(d.needed, "ceil")})
		_need.center_in(panel_rect.position.x, panel_rect.size.x)
		if not changed and ready:
			return
		_bonus.text = Strings.s("EVO_BONUS" if ready else "EVO_BONUS_PREVIEW")
		_bonus.center_in(panel_rect.position.x, panel_rect.size.x)
		_bar_track.visible = not ready
		_bar_fill.visible = not ready
		if not ready:
			var bar: Rect2 = L.OVERLAY["evolution"]["bar"]
			var w := maxf(8.0, Ui.snap(bar.size.x * minf(1.0, float(d.pending) / maxf(1.0, float(d.needed))), 4))
			_bar_fill.size = Vector2(w / 4.0, bar.size.y / 4.0)
		_confirm.set_visible(true).set_enabled(ready)
		if _confirm.label:
			_confirm.label.visible = ready
		_not_ready.visible = not ready
		if changed and not force and ready and focus_index == 0:
			focus_index = 1

	func update_view(_dt_ms: float) -> void:
		if not committed:
			_refresh()

	func _do_confirm() -> void:
		if committed or not (host.d as Economy.Derived).evolve_enabled:
			return
		committed = true
		host.confirm_evolve()

	func close_for_confirm() -> void:
		mgr.close(self, "confirm")

	func cancel(via: String) -> void:
		if committed:
			return
		host.audio_event("evolveClose")
		mgr.close(self, via)


class OfflineOverlay:
	extends Overlay
	var award := 0.0
	var away_sec := 0.0
	var capped := false
	var cold := false
	var info: Dictionary = {}
	var _amount: PxText
	var _icon: Sprite2D
	var _rolling := false
	var _roll_t := 0.0
	var _rolled := false
	var _cue_played := false
	var _beat_t := -1.0
	var _close_in := -1.0

	func build() -> OfflineOverlay:
		id = "OFFLINE"
		var LO: Dictionary = L.OVERLAY["offline"]
		var th := Art.theme
		make_panel(LO["panel"])
		text(LO["title"], Strings.s("OFF_TITLE"), 4, th["modal"]["title"])
		var away := Strings.s("OFF_AWAY_CAPPED_H", {"h": str(int(info.get("capHours", 8)))}) if (capped and Strings.has("OFF_AWAY_CAPPED_H")) \
			else (Strings.s("OFF_AWAY_CAPPED") if capped else Strings.s("OFF_AWAY", {"dur": Fmt.dur(away_sec)}))
		centered(424, away, 3)
		centered(476, Strings.s("OFF_HARVESTED"), 3)
		_icon = Ui.img(panel, Vector2(0, 522), th["offline"]["amountIcon"], 0, 6)
		# v2: a cold start shows the whole amount at once (v1 waited for COLLECT to count up from
		# +0, which read like a bug); returning to an open game still counts up.
		_amount = text(Vector2(0, 538), Strings.s("OFF_AMOUNT", {"n": Fmt.amount(award) if cold else "0"}), 4, th["offline"]["amount"])
		if cold:
			_rolled = true
		_layout_amount()
		var n1: String = info.get("note1", Strings.s("OFF_NOTE_1"))
		var n2: String = info.get("note2", Strings.s("OFF_NOTE_2"))
		centered(624, n1, 3, th["modal"]["note"])
		centered(652, n2, 3, th["modal"]["note"])
		button(LO["collect"], LO["collectHit"], Strings.s("OFF_COLLECT"), _collect)
		return self

	func _layout_amount() -> void:
		var w := 64.0 + 16.0 + _amount.width()
		var x := 4.0 * floorf((L.W - w) / 2.0 / 4.0)
		_icon.position.x = x + 2.0
		_amount.position.x = x + 80.0

	func on_opened() -> void:
		if not cold:
			_start_roll()

	func _start_roll() -> void:
		if _rolling or _rolled:
			return
		_rolling = true
		_roll_t = 0.0

	func _collect() -> void:
		host.audio_event("uiClick")
		if cold:
			_play_cue()
		if not _rolled:
			_finish_roll()
		_close_now("close")

	func _finish_roll() -> void:
		_rolling = false
		_rolled = true
		_amount.text = Strings.s("OFF_AMOUNT", {"n": Fmt.amount(award)})
		_layout_amount()
		_play_cue()

	func _play_cue() -> void:
		if _cue_played:
			return
		_cue_played = true
		host.audio_event("offlineCollect")

	func update_view(dt_ms: float) -> void:
		if _rolling:
			_roll_t += dt_ms
			var p := minf(1.0, _roll_t / float(Tune.T["offlineRollMs"]))
			_amount.text = Strings.s("OFF_AMOUNT", {"n": Fmt.amount(floorf(award * Ui.cubic_out(p)))})
			_layout_amount()
			if p >= 1.0:
				_finish_roll()
				_beat_t = 0.0
				_amount.px = 5
				if cold:
					_close_in = float(Tune.MC["offlineCloseAfterRollMs"])
		if _beat_t >= 0.0:
			_beat_t += dt_ms
			if _beat_t >= float(Tune.MC["offlineEndBeatMs"]):
				_beat_t = -1.0
				_amount.px = 4
		if _close_in >= 0.0:
			_close_in -= dt_ms
			if _close_in < 0.0 and not closing:
				_close_now("close")

	func _close_now(via: String, silent: bool = false) -> void:
		_close_in = -1.0
		if not silent:
			host.audio_event("panelClose")
		host.offline_collected()
		mgr.close(self, via)

	func cancel(via: String) -> void:
		if closing:
			return
		var silent := cold and not _rolling and not _rolled and (via == "esc" or via == "back")
		if not _rolled:
			_rolling = false
			_rolled = true
			if not silent:
				_play_cue()
		_close_now(via, silent)


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
			var r := Overlays.list_row(self, y, k, p["icon"], int(th["plate"]["frames"]["upgradeGlobal"]), p["name"], "", false)
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
		for n in range(s.evolutions, 0, -1):
			var era: Dictionary = Story.era_for(n)
			var h := PxText.make(page, Vector2(80, y), Strings.s("STORY_EVOLUTION", {"n": n, "era": era.get("name", "")}), 3, "plain", th["modal"]["groupLabel"])
			y += 36.0
			for l in Story.beat_for(n):
				PxText.make(page, Vector2(80, y), l, 3, "plain", th["modal"]["body"])
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
