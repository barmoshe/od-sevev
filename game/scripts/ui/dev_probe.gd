class_name DevProbe
extends RefCounted
## Dev-only (web build, `?dev=1`): `window.odDev`, what a browser driver needs to play through the
## real UI with real taps (tools/web/round_web.mjs), 4 times a second. Nothing here acts on the
## game; it only reports where the targets are, in viewport logical px (the driver maps them to CSS
## with window.odDisplay, like window.odFlash / window.odModal).
##   bank, seats {effective, gate}, evolutions, runSec, cta (the "עוד סבב!" CTA is up), ready
##   (the election can be called), modal (the top overlay's id or "")
##   chat {open, thread [top, bottom], pills [[x, y, seq, afford, ceremony]], brawls [[x, y, seq]],
##        avatars [[x, y, id]] (in view), openBrawl}: every open pay pill and "צאו החוצה" button, in
##        or out of view (the driver drags the thread to bring one into view)
##   shop {tab, list [top, bottom], rows [[x, y, id, afford]]}: the source cards in view

static var _ms := 0.0


static func publish(host: Node, dt_ms: float) -> void:
	_ms += dt_ms
	if _ms < 250.0 or not OS.has_feature("web"):
		return
	_ms = 0.0
	JavaScriptBridge.eval("window.odDev = %s" % JSON.stringify(snapshot(host)), true)


static func snapshot(host: Node) -> Dictionary:
	var s: GameState = host.get("state")
	var d: Economy.Derived = host.get("d")
	var o := Vector2(float(host.get("_ox")), float(host.get("_lower_y")))
	var out := {"bank": s.bananas, "evolutions": s.evolutions, "runSec": s.run_time_sec,
		"ready": d.evolve_enabled if d != null else false, "cta": (host.get("ticker") as Ticker).cta_on(),
		"modal": "", "groupOpen": bool(s.coalition.get("opened", false)) if s.coalition is Dictionary else false,
		# leader select: the controller's mode (pick | title | main) and the round's leader
		"mode": str(host.get("mode")), "leader": Leaders.current(s), "pickPending": Leaders.pick_pending(s),
		"undo": bool(host.call("undo_visible")) if host.has_method("undo_visible") else false}
	var pk: Variant = host.get("picker")
	if pk is PickView and (pk as PickView).visible:
		out["pick"] = (pk as PickView).web_info()
	var mgr: OverlayManager = host.get("overlays")
	out["modalButtons"] = []
	if mgr != null and mgr.is_open():
		var t := mgr.top()
		out["modal"] = t.id
		# the width rule (mobile_web.mjs): the top overlay's panel, viewport logical x and width
		out["modalRect"] = [t.panel_rect.position.x + t.position.x + float(host.get("_ox")), t.panel_rect.size.x]
		var ov := Vector2(float(host.get("_ox")), float(host.get("_ovl_y")))
		for b: PxButton in t.focusables:
			var c := b.visual.get_center() + Vector2(t.position.x, t.panel.position.y) + ov
			if t.body_focusables.has(b):
				c.y -= t.scroll
			out["modalButtons"].append([c.x, c.y, b.label.text if b.label != null else ""])
	var si := Coalition.seat_info(s)
	out["seats"] = {"effective": si["effective"], "gate": si["gateSeats"]}
	var chat: ChatView = host.get("chat")
	var pills: Array = []
	var avatars: Array = []
	var brawls: Array = []
	var top := chat.position.y + ChatView.THREAD_Y + o.y
	var bottom := top + chat.thread_h() - chat.bottom_pad()
	if chat.is_open():
		for h: Dictionary in chat.hits():
			var c := chat.content_to_tall((h["rect"] as Rect2).get_center()) + chat.position + o
			if h["kind"] == "partner" and c.y > top and c.y < bottom:
				avatars.append([c.x, c.y, str(h["partner"])])
			if h["kind"] == "brawl":
				brawls.append([c.x, c.y, int(h["seq"])])
			if h["kind"] != "pay":
				continue
			var m := Coalition.message(s, int(h["seq"]))
			pills.append([c.x, c.y, int(h["seq"]), s.bananas >= float(m.get("price", 0.0)), str(m.get("kind", "")) == "ceremony"])
	out["chat"] = {"open": chat.is_open(), "thread": [top, bottom], "pills": pills, "avatars": avatars, "brawls": brawls,
		"openBrawl": not Coalition.open_brawl(s).is_empty()}
	# the "{n} ממתינים ↑" chip and the brawl stage cue (views wave 6): centres in viewport px
	var pi := chat.pending_info()
	var pc := (pi["rect"] as Rect2).get_center() + chat.position + o
	out["chat"]["pending"] = {"visible": pi["visible"], "n": pi["n"], "seq": pi["seq"], "x": pc.x, "y": pc.y}
	var bc := ChatView.BRAWL_CUE.get_center() + chat.position + o
	out["brawlCue"] = {"visible": chat.brawl_cue_visible(), "x": bc.x, "y": bc.y}
	var shop: Shop = host.get("shop")
	var rows: Array = []
	var all_rows: Array = []
	if shop.visible and shop.tab == "producers":
		var models := shop._models(s, "producers")
		for k in models.size():
			var mk: Dictionary = models[k]
			if mk["kind"] != "producer":
				continue
			var id := str(mk["id"])
			var afford := s.bananas >= Economy.producer_cost(s, id, 1)
			var yt := shop._row_top(k, "producers")
			all_rows.append([360.0 + o.x, yt + float(L.SHOP["rowVisualH"]) / 2.0 + o.y, id, afford])
			var y := shop.row_screen_y(k, "producers")
			if y < 0.0:
				continue
			rows.append([360.0 + o.x, y + float(L.SHOP["rowVisualH"]) / 2.0 + o.y, id, afford])
	# mobile-first §5.4: the silhouette and teaser rows the pane shows whole (no price or no target)
	out["shop"] = {"tab": shop.tab, "list": [shop.list_rect.position.y + o.y, shop.list_rect.end.y + o.y], "rows": rows,
		"all": all_rows, "silhouettes": shop.rows_in_view(["silhouette", "teaser"]),
		"card": [shop.list_rect.position.x + o.x, shop.list_rect.end.x + o.x],   # the cards' x span (the width rule)
		# review U6 / S7: every row the pane shows at least partly, its pill [top, bottom, drawn]
		"pills": shop.pill_rects().map(func(p: Array) -> Array: return [float(p[0]) + o.y, float(p[1]) + o.y, p[2]])}
	var court: CourtView = host.get("court")
	var ct := court.button_rect("testify").get_center() + o if court.card_visible() else Vector2(-1, -1)
	out["court"] = {"card": court.card_visible(), "mode": court.mode(), "phase": court.phase(), "testify": [ct.x, ct.y]}
	# views wave 6: the thermometer (a tap opens T4) and T4's full-width rows (the share cards)
	var th: Thermo = host.get("thermo")
	var tc := th.hit_rect().get_center() + Vector2(float(host.get("_sx")), float(host.get("_stage_y")))
	out["thermo"] = {"shown": th.is_shown(), "x": tc.x, "y": tc.y}
	var dv: DossierView = host.get("dossier")
	var drows: Array = []
	if dv.is_open():
		for h: Dictionary in dv.hits():
			var c := dv.content_to_tall((h["rect"] as Rect2).get_center()) + dv.position + o
			drows.append([c.x, c.y, str(h["kind"])])
	out["dossier"] = {"open": dv.is_open(), "rows": drows}
	return out
