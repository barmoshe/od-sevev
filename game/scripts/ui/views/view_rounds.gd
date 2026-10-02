class_name RoundCards
extends RefCounted
## The seeded rounds' modal cards ("תעבור אותי" and "הסבב היומי"), on the shared §7.1 sheet card
## (SheetCard: the envelope, a title band, ×4 paragraphs, full-width stacked buttons). The controller
## (main.gd, the "seeded rounds" blocks) opens them and answers their buttons:
##   ChallengeIntro   a friend's link: who, what time, the sandbox note; GO / LATER
##   ChallengeOffer   after an election (a toast) or from T4: send this round as a challenge
##   ChallengeResult  at 61: won / lost / tie, the two times; SEND BACK / BACK TO MY GAME
##   DailyCard        the day's round: unplayed (GO) or played (the grid, the streak, SHARE, REPLAY)
##   DailyResult      at 61: the time, the grid, the court line, the streak; SHARE / BACK
##   QuitCard         a tap on the round chip: leave the round (nothing is kept)
## The grid is drawn, not typed (the pixel font has no emoji): Grid, one square per partner, read
## right to left like the lineup, ROW squares a line (SeededRound.CELLS has the emoji twins).

const C_CELL := {"B": Color("#2f6fdc"), "Y": Color("#ffd23a"), "R": Color("#e0414c"), "W": Color("#f7f4ec")}
const CELL := 48.0
const CELL_SMALL := 32.0
const CELL_GAP := 8.0


class Grid extends Node2D:
	var cells := ""
	var cell := 48.0
	var gap := 8.0

	func grid_size() -> Vector2:
		var n := cells.length()
		var cols := mini(n, SeededRound.ROW)
		var rows := int(ceilf(float(n) / float(SeededRound.ROW)))
		return Vector2(maxf(0.0, cols * cell + (cols - 1) * gap), maxf(0.0, rows * cell + (rows - 1) * gap))

	func _draw() -> void:
		var cols := mini(cells.length(), SeededRound.ROW)
		for i in cells.length():
			var r := i / SeededRound.ROW
			var c := i % SeededRound.ROW
			var x := float(cols - 1 - c) * (cell + gap)   # RTL: the lineup's first partner at the right
			var rc := Rect2(x, float(r) * (cell + gap), cell, cell)
			draw_rect(rc, RoundCards.C_CELL.get(cells[i], RoundCards.C_CELL["W"]))
			draw_rect(rc, Color(0, 0, 0, 0.35), false, 4.0)


## The base: stacked full-width buttons, a status line for share results, the grid helper.
class RoundCard extends SheetCard:
	var status: PxText
	var model: Dictionary = {}

	func stack(label: String, kind: String, cb: Callable) -> void:
		if _specs.is_empty():
			_y = Ui.snap(_y - PARA_GAP + PAD, 4)
		else:
			_y += BTN_GAP
		_specs.append([Rect2(88, _y, 544, BTN_H), label, kind, cb])
		_y += BTN_H

	func grid(cells: String, cell: float = 48.0) -> Grid:
		var g := Grid.new()
		g.cells = cells
		g.cell = cell
		g.gap = 8.0
		var sz := g.grid_size()
		g.position = Vector2(CARD_X + L.floor4((CARD_W - sz.x) / 2.0), _y)
		_holder.add_child(g)
		_y += Ui.snap(sz.y, 4) + PARA_GAP
		return g

	func leader_line(id: String) -> void:
		if LeaderUi.short(id) != "":
			para(Strings.s("ELECT_LEADER", {"short": LeaderUi.short(id), "party": LeaderUi.party(id)}), C_TEXT, true, 1)

	## The share status line (one line, centred, muted); empty until a share comes back.
	func status_line() -> void:
		status = para(" ", C_MUTED, true, 1)

	## The shell's share result (window.odShareDone through the controller).
	func on_share_result(result: String) -> void:
		if status == null:
			return
		var key := ""
		match result:
			"fallback", "copied":
				key = "SHARE_COPIED"
			"fail":
				key = "SHARE_FAIL"
		status.text = Strings.s(key) if key != "" else " "
		status.center_in(CARD_X + (CARD_W - body_w()) / 2.0, body_w())

	func _call(m: String, args: Array = []) -> void:
		if host != null and host.has_method(m):
			host.callv(m, args)

	func on_opened() -> void:
		publish_web({"round": id})


class ChallengeIntro extends RoundCard:
	func build() -> ChallengeIntro:
		id = "CHALLENGE_INTRO"
		backdrop_closes = false
		_begin()
		title(Strings.s("CHALLENGE_TITLE"))
		var lid := str(model.get("leader", ""))
		leader_line(lid)
		para(Strings.s("CHALLENGE_INTRO_BODY", {"mmss": SeededRound.mmss(float(model.get("t", 0))), "short": LeaderUi.short(lid)}))
		if int(model.get("vs", -1)) > 0:
			para(Strings.s("CHALLENGE_INTRO_BACK", {"mine": SeededRound.mmss(float(model.get("t", 0))), "theirs": SeededRound.mmss(float(model.get("vs", 0)))}), C_GOLD)
		para(Strings.s("CHALLENGE_SANDBOX"), C_MUTED)
		stack(Strings.s("CHALLENGE_GO"), "kit_gold", func() -> void:
			mgr.close(self, "confirm")
			_call("round_accept_arrival"))
		stack(Strings.s("CHALLENGE_LATER"), "kit_secondary", func() -> void: cancel("close"))
		finish()
		return self

	func cancel(via: String) -> void:
		if closing:
			return
		mgr.close(self, via)
		_call("round_decline_arrival")


class ChallengeOffer extends RoundCard:
	func build() -> ChallengeOffer:
		id = "CHALLENGE_OFFER"
		_begin()
		title(Strings.s("CHALLENGE_OFFER_TITLE"))
		var lid := str(model.get("leader", ""))
		leader_line(lid)
		para(Strings.s("CHALLENGE_OFFER_BODY", {"mmss": SeededRound.mmss(float(model.get("t", 0))), "short": LeaderUi.short(lid)}))
		para(Strings.s("CHALLENGE_OFFER_NOTE"), C_MUTED)
		status_line()
		close_x(func() -> void: cancel("close"))
		stack(Strings.s("CHALLENGE_SEND"), "kit_gold", func() -> void: _call("round_share", ["offer"]))
		stack(Strings.s("SHARE_CLOSE"), "kit_secondary", func() -> void: cancel("close"))
		finish()
		return self

	func cancel(via: String) -> void:
		if closing:
			return
		_call("audio_event", ["panelClose"])
		mgr.close(self, via)


class ChallengeResult extends RoundCard:
	func build() -> ChallengeResult:
		id = "CHALLENGE_RESULT"
		backdrop_closes = false
		_begin()
		var r := str(model.get("result", "tie"))
		var mine := float(model.get("mine", 0))
		var gap_ := float(model.get("gap", 0))
		match r:
			"win":
				title(Strings.s("CHALLENGE_WIN", {"mmss": SeededRound.mmss(mine)}))
			"lose":
				title(Strings.s("CHALLENGE_LOSE", {"mmss": SeededRound.mmss(gap_)}))
			_:
				title(Strings.s("CHALLENGE_TIE", {"mmss": SeededRound.mmss(mine)}))
		leader_line(str(model.get("leader", "")))
		para(Strings.s("CHALLENGE_VS", {"mine": SeededRound.mmss(mine), "theirs": SeededRound.mmss(float(model.get("theirs", 0)))}), C_GOLD if r == "win" else C_TEXT, true, 1)
		if str(model.get("cells", "")) != "":
			grid(str(model["cells"]), RoundCards.CELL_SMALL)
		status_line()
		stack(Strings.s("CHALLENGE_SEND_BACK"), "kit_gold", func() -> void: _call("round_share", ["return"]))
		stack(Strings.s("CHALLENGE_START_MAIN" if model.get("newPlayer", false) == true else "CHALLENGE_BACK_MAIN"), "kit_secondary", func() -> void: cancel("close"))
		finish()
		return self

	func cancel(via: String) -> void:
		if closing:
			return
		mgr.close(self, via)
		_call("leave_round")


class DailyCard extends RoundCard:
	func build() -> DailyCard:
		id = "DAILY"
		_begin()
		title(Strings.s("DAILY_TITLE", {"n": int(model.get("n", 1))}))
		leader_line(str(model.get("leader", "")))
		var today: Dictionary = model.get("today", {})
		if today.is_empty():
			para(Strings.s("DAILY_BODY"))
			para(Strings.s("DAILY_ONCE"), C_MUTED)
		else:
			para(Strings.s("DAILY_TODAY", {"mmss": SeededRound.mmss(float(today.get("sec", 0)))}), C_GOLD, true, 1)
			grid(str(today.get("cells", "")), RoundCards.CELL)
			para(RoundCards.court_text(today), C_TEXT, true, 1)
			para(Strings.plural("DAILY_STREAK", int(model.get("streak", 0))), C_TEXT, true, 1)
		var yd: Dictionary = model.get("yesterday", {})
		if not yd.is_empty():
			para(Strings.s("DAILY_YESTERDAY", {"mmss": SeededRound.mmss(float(yd.get("sec", 0)))}), C_MUTED, true, 1)
			grid(str(yd.get("cells", "")), RoundCards.CELL_SMALL)
		close_x(func() -> void: cancel("close"))
		if today.is_empty():
			status = null
			stack(Strings.s("DAILY_GO"), "kit_gold", func() -> void:
				mgr.close(self, "confirm")
				_call("start_daily"))
		else:
			status_line()
			stack(Strings.s("DAILY_SHARE"), "kit_gold", func() -> void: _call("round_share", ["daily"]))
			stack(Strings.s("DAILY_REPLAY"), "kit_secondary", func() -> void:
				mgr.close(self, "confirm")
				_call("start_daily"))
		stack(Strings.s("SHARE_CLOSE"), "kit_secondary", func() -> void: cancel("close"))
		finish()
		return self

	func cancel(via: String) -> void:
		if closing:
			return
		_call("audio_event", ["panelClose"])
		mgr.close(self, via)


class DailyResult extends RoundCard:
	func build() -> DailyResult:
		id = "DAILY_RESULT"
		backdrop_closes = false
		_begin()
		var res: Dictionary = model.get("result", {})
		title(Strings.s("DAILY_RESULT", {"mmss": SeededRound.mmss(float(res.get("sec", 0)))}))
		leader_line(str(res.get("leader", "")))
		grid(str(res.get("cells", "")), RoundCards.CELL)
		para(RoundCards.court_text(res), C_TEXT, true, 1)
		if model.get("official", false) == true:
			para(Strings.plural("DAILY_STREAK", int(model.get("streak", 0))), C_GOLD, true, 1)
		else:
			var off: Dictionary = model.get("officialResult", {})
			para(Strings.s("DAILY_UNOFFICIAL", {"mmss": SeededRound.mmss(float(off.get("sec", 0)))}), C_MUTED)
		status_line()
		stack(Strings.s("DAILY_SHARE"), "kit_gold", func() -> void: _call("round_share", ["daily"]))
		stack(Strings.s("CHALLENGE_START_MAIN" if model.get("newPlayer", false) == true else "CHALLENGE_BACK_MAIN"), "kit_secondary", func() -> void: cancel("close"))
		finish()
		return self

	func cancel(via: String) -> void:
		if closing:
			return
		mgr.close(self, via)
		_call("leave_round")


class QuitCard extends RoundCard:
	func build() -> QuitCard:
		id = "ROUND_QUIT"
		_begin()
		title(Strings.s("ROUND_QUIT_TITLE"))
		para(Strings.s("ROUND_QUIT_BODY"))
		close_x(func() -> void: cancel("close"))
		two_buttons(Strings.s("ROUND_QUIT_GO"), "kit_primary", func() -> void:
			mgr.close(self, "confirm")
			_call("leave_round"), Strings.s("ROUND_QUIT_STAY"), func() -> void: cancel("close"))
		finish()
		return self

	func cancel(via: String) -> void:
		if closing:
			return
		mgr.close(self, via)


## The court line under a grid: "⚖ העידו אותי" / "התחמקתי" (press leaders: "הגבתי לתחקיר").
static func court_text(res: Dictionary) -> String:
	if str(res.get("court", "")) == "testified":
		return Strings.s("DAILY_PRESS_YES" if res.get("press", false) == true else "DAILY_COURT_YES")
	return Strings.s("DAILY_COURT_NO")
