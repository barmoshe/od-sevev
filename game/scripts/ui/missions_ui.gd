class_name MissionsUi
extends RefCounted
## The controller's half of the missions (sim: Missions). MainController calls four things, so its
## own diff stays a few lines:
##   MissionsUi.chip_view(state, d)   the chip's model, every frame (MissionsChip.update_view)
##   MissionsUi.check(host)           4× a second (main._check_meta): latch finished goals; each one
##                                    rolls "משימה הושלמה: …" on the ticker with the milestone cue
##   MissionsUi.open(host)            the chip's tap: the sheet (ui/views/view_missions.gd)
##   MissionsUi.claim(host, i)        the sheet's "לקחת": the reward, the sound, and on a rank-up the
##                                    celebration (ticker milestone + toast + confetti + the trophy cue)
## Texts: the mission's own text from content (its {verbPlural} / {critPlural} filled with the round's
## leader's tap words), the chrome from ux/ui-strings.json (MIS_*).


## A mission's text for the round's leader.
static func text(m: Dictionary) -> String:
	var t := LeaderUi.tap()
	return Bidi.fill(str(m.get("text", "")), {"verbPlural": str(t.get("verbPlural", "")), "critPlural": str(t.get("critPlural", ""))})


## "12/25" (counts) or "1.2K/5K" (money, ₪/s): a slot view's progress.
static func progress_text(v: Dictionary) -> String:
	var g: Dictionary = v.get("goal", {})
	var money := str(g.get("type", "")) in ["earnRun", "bpsAtLeast"]
	var a := float(v.get("value", 0.0))
	var b := float(v.get("target", 1.0))
	if money:
		return Strings.s("MIS_PROGRESS", {"val": Fmt.amount(a), "goal": Fmt.amount(b)})
	return Strings.s("MIS_PROGRESS", {"val": str(int(floorf(a))), "goal": str(int(b))})


## The reward's label at today's numbers: "+1.2K ₪", "הכנסה ×5 · 15 שנ׳", "+5% לבסיס".
static func reward_text(s: GameState, r: Dictionary, d: Economy.Derived) -> String:
	var now := Missions.reward_now(s, r, d)
	match str(now.get("type", "")):
		"cash":
			return Strings.s("MIS_REWARD_CASH", {"x": Fmt.amount(float(now["cash"]))})
		"frenzy":
			return Strings.s("MIS_REWARD_FRENZY", {"mult": str(int(roundf(float(now["mult"])))), "s": str(int(now["sec"]))})
		"basePct":
			return Strings.s("MIS_REWARD_BASE", {"pct": str(int(now["pct"]))})
	return ""


static func chip_view(s: GameState, d: Economy.Derived) -> Dictionary:
	if not Reveal.on(s, "missions"):
		return {"show": false, "claimable": 0, "frac": 0.0, "sub": ""}   # the reveal ladder
	if not Missions.active() or (s.missions.get("slots", []) as Array).is_empty() and Missions.rank_view(s)["top"]:
		return {"show": Missions.active(), "claimable": 0, "frac": 1.0, "sub": ""}
	var best := {}
	for v: Dictionary in Missions.slots_view(s, d):
		if best.is_empty() or float(v["frac"]) > float(best["frac"]):
			best = v
	# the bar carries the progress; no "1/100 → 3/10" fraction that changes its own scale (report W6)
	return {"show": true, "claimable": Missions.claimable(s), "frac": float(best.get("frac", 0.0)), "sub": ""}


## 4× a second: finished goals roll on the ticker (the chip's badge and pulse do the rest).
static func check(host: Node) -> void:
	if not Missions.active():
		return
	var s: GameState = host.get("state")
	for id in Missions.tick(s, host.get("d")):
		var tk: Ticker = host.get("ticker")
		tk.enqueue("milestone", Strings.s("F_MISSION_DONE", {"mission": text(Missions.mission(id))}))
		host.call("_audio", "milestone")
		host.call("_haptic", 25)
		host.call("_mark_dirty")


static func open(host: Node) -> void:
	var mgr: OverlayManager = host.get("overlays")
	if mgr.is_open() or not Missions.active():
		return
	host.call("_audio", "panelOpen")
	mgr.request(func() -> Overlay:
		var o := MissionsSheet.new()
		o.setup(host, mgr)
		return o.build())


## "לקחת" on slot i. Returns Missions.claim's result.
static func claim(host: Node, i: int) -> Dictionary:
	var s: GameState = host.get("state")
	var d: Economy.Derived = Economy.derive(s)
	var r := Missions.claim(s, i, d)
	if not bool(r.get("ok", false)):
		return r
	host.call("_audio", "offlineCollect" if str(r["reward"].get("type", "")) == "cash" else "milestone")
	host.call("_haptic", 20)
	var up: Dictionary = r.get("rankUp", {})
	if not up.is_empty():
		var line := Strings.s("F_RANK_UP", {"rankTitle": str(up["title"]), "pct": str(int(up["incomePct"]))})
		(host.get("ticker") as Ticker).enqueue("milestone", line, true)   # one channel: the milestone ticker
		var fx: FxPlayer = host.get("fx_stage")
		if fx != null:
			fx.play("purchaseConfetti", 64.0, 224.0, "bulk")
		host.call("_audio", "achievement")
		host.call("_haptic", 40)
	host.set("d", Economy.derive(s))
	host.call("_mark_dirty")
	host.call("_save_now")
	return r


## Dev only (web): window.odMissions = {chip [x, y] (viewport logical), open, claim [[x, y], …]}.
static func publish_web(host: Node, chip: MissionsChip) -> void:
	if not OS.has_feature("web"):
		return
	var info := {"chip": [], "open": false, "claim": []}
	if chip != null and chip.visible:
		var c := chip.hit_rect().get_center() + Vector2(float(host.get("_sx")), float(host.get("_stage_y")))
		info["chip"] = [c.x, c.y]
	var mgr: OverlayManager = host.get("overlays")
	if mgr != null and mgr.top() is MissionsSheet:
		info["open"] = true
		info["claim"] = (mgr.top() as MissionsSheet).claim_points()
	JavaScriptBridge.eval("window.odMissions = %s" % JSON.stringify(info), true)
