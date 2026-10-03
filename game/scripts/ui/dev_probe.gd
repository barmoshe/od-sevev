class_name DevProbe
extends RefCounted
## Dev-only (web build, `?dev=1`): `window.odDev`, what a browser driver needs to play through the
## real UI with real taps (tools/web/round_web.mjs), 4 times a second. Nothing here acts on the
## game; it only reports where the targets are, in viewport logical px (the driver maps them to CSS
## with window.odDisplay, like window.odFlash / window.odModal).
##   bank, seats {effective, gate}, evolutions, runSec, cta (the "עוד סבב!" CTA is up), ready
##   (the election can be called), ctaAt [x, y] (the CTA's centre), modal (the top overlay's id or "")
##   chat {open, thread [top, bottom], pills [[x, y, seq, afford, ceremony]], brawls [[x, y, seq]],
##        avatars [[x, y, id]] (in view), openBrawl, payAll {visible, n, total, x, y}}: every open pay
##        pill and "צאו החוצה" button, in or out of view (the driver drags the thread to bring one
##        into view); payAll is the composer's "לסגור עם כולם" pill
##   coal {lines, afford, ultLeft, save, vote}: the open pay lines, how many the bank covers, the
##        nearest ultimatum (s, -1 none), the biggest ultimatum / rejoin price, the election card holding
##   shop {tab, list [top, bottom], rows [[x, y, id, afford]]}: the source cards in view
##   sara [x, y]: Sara's centre while she takes the tap (absent otherwise)

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
	var out := {"bank": s.money, "evolutions": s.evolutions, "runSec": s.run_time_sec,
		"ready": d.evolve_enabled if d != null else false, "cta": (host.get("ticker") as Ticker).cta_on(),
		"modal": "", "groupOpen": bool(s.coalition.get("opened", false)) if s.coalition is Dictionary else false,
		# leader select: the controller's mode (pick | title | main) and the round's leader
		"mode": str(host.get("mode")), "leader": Leaders.current(s), "pickPending": Leaders.pick_pending(s),
		"undo": bool(host.call("undo_visible")) if host.has_method("undo_visible") else false,
		"hud": host.call("hud_info") if host.has_method("hud_info") else {}}
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
		# manual test A6 (mobile_web.mjs): a scrolling body's clip and its rows [id, top, bottom], viewport y
		if t.body != null:
			var dy := t.panel.position.y + ov.y
			out["modalClip"] = [t.clip_rect.position.y + dy, t.clip_rect.end.y + dy]
			out["modalScroll"] = [t.scroll, t.max_scroll()]
			var rows: Array = []
			for b: PxButton in t.body_focusables:
				rows.append([str(b.get_meta("row", "")), b.hit.position.y - t.scroll + dy, b.hit.end.y - t.scroll + dy])
			out["modalRows"] = rows
	# the "עוד סבב!" CTA's centre, live (the lower band moves when the layout splits again)
	var tk: Ticker = host.get("ticker")
	var cc := tk.cta.visual.get_center() + tk.position + o
	out["ctaAt"] = [cc.x, cc.y]
	# D19 (mobile-first §5.2.2): what the ticker strip shows, live (never "" while the row is up)
	out["ticker"] = {"visible": tk.visible, "text": tk.strip_text(), "idle": tk.idle_showing(), "held": tk.holding()}
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
			pills.append([c.x, c.y, int(h["seq"]), s.money >= float(m.get("price", 0.0)), str(m.get("kind", "")) == "ceremony"])
	out["chat"] = {"open": chat.is_open(), "thread": [top, bottom], "pills": pills, "avatars": avatars, "brawls": brawls,
		"openBrawl": not Coalition.open_brawl(s).is_empty()}
	# the sim's open lines whether or not T3 is open (the driver saves for an ultimatum like a player)
	var lines := 0
	var n_afford := 0
	var ult_left := -1.0
	var ult_price := 0.0
	if s.coalition is Dictionary:
		for m: Dictionary in s.coalition.get("chat", []):
			if m["state"] != "open" or not Coalition.is_payable(m):
				continue
			lines += 1
			if s.money >= float(m.get("price", 0.0)):
				n_afford += 1
			if m["type"] == "ultimatum" or str(m.get("payable", "")) == "rejoin":
				ult_price = maxf(ult_price, float(m.get("price", 0.0)))
				if m["type"] == "ultimatum":
					ult_left = float(m["leftSec"]) if ult_left < 0.0 else minf(ult_left, float(m["leftSec"]))
	out["coal"] = {"lines": lines, "afford": n_afford, "ultLeft": ult_left, "save": ult_price, "vote": bool(host.call("vote_open")) if host.has_method("vote_open") else false}
	# the "{n} ממתינים ↑" chip and the brawl stage cue (views wave 6): centres in viewport px
	var pi := chat.pending_info()
	var pc := (pi["rect"] as Rect2).get_center() + chat.position + o
	out["chat"]["pending"] = {"visible": pi["visible"], "n": pi["n"], "seq": pi["seq"], "x": pc.x, "y": pc.y}
	# coalition UX rev 5: the composer's "לסגור עם כולם" pill (n lines, total ₪), centre in viewport px
	var pa := chat.pay_all_info()
	var pac := (pa["rect"] as Rect2).get_center() + chat.position + o
	out["chat"]["payAll"] = {"visible": pa["visible"], "n": pa["n"], "total": pa["total"], "x": pac.x, "y": pac.y}
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
			var afford := s.money >= Economy.producer_cost(s, id, 1)
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
	# Bar 2026-10-02: while Sara is on the stage the tap is hers (the driver taps her, not the leader)
	var sm: Variant = host.get("sara")
	if sm is SaraMark and (sm as SaraMark).tappable():
		var sc := (sm as SaraMark).hit_rect().get_center() + Vector2(float(host.get("_sx")), float(host.get("_stage_y")))
		out["sara"] = [sc.x, sc.y]
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
