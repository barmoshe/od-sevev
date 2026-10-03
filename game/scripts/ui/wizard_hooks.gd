class_name WizardHooks
extends RefCounted
## The controller's half of the wizard (ui/wizard.gd): the vocabulary content `wizard` speaks.
##   cond(host, name)    a condition over the state and the screen (when / done / until)
##   anchor(host, name)  a target's rect in root space (the wizard is the root's last child); an empty
##                       rect = not on screen, so the step waits
## Section origins as main._in_stage / _in_lower / _in_top / _in_pick (without the shake: the wizard
## shakes with the root).


static func _s(host: Node) -> GameState:
	return host.get("state")


## The round is up, nothing over the stage or the panel, nobody blocking the screen.
static func _free(host: Node) -> bool:
	return bool(host.call("_gameplay_input")) and not (host.get("chat") as ChatView).is_open() \
		and not (host.get("dossier") as DossierView).is_open() and not Leaders.pick_pending(_s(host))


static func _first_k(host: Node) -> int:
	var shop: Shop = host.get("shop")
	if shop.tab != "producers" or not shop.visible:
		return -1   # the cheap checks first: the row lookup rebuilds the row models
	var k := shop.row_index_of(_s(host), "producer", Content.producer_ids()[0])
	return k if k >= 0 and shop.row_screen_y(k, "producers") >= 0.0 else -1


static func _rv(host: Node, k: String) -> bool:
	return bool((host.get("_reveals") as Dictionary).get(k, false))


static func cond(host: Node, name: String) -> bool:
	var s := _s(host)
	var mgr: OverlayManager = host.get("overlays")
	var chat: ChatView = host.get("chat")
	match name:
		# the first round
		"picking":
			var pk: PickView = host.get("picker")
			return str(host.get("mode")) == "pick" and pk.visible and not pk.locked and not mgr.is_open() \
				and (host.get("ftue") as Ftue).handoff_ms > 0.0
		"slipChosen":
			var pk: PickView = host.get("picker")
			if pk.focus < 0 or pk.focus >= pk.cells.size():
				return false
			var id := str(pk.cells[pk.focus]["id"])
			return id == "" or (not pk.cells[pk.focus].get("locked", false) and not pk.tile_of(id).get("decoy", false))
		"picked":
			return not Leaders.pick_pending(s)
		"stage":
			var m := str(host.get("mode"))
			return (m == "title" or _free(host)) and not mgr.is_open() and not Leaders.pick_pending(s)
		"tapped3":
			return s.taps_lifetime >= 3
		"card1Afford":
			var first: String = Content.producer_ids()[0]
			return _free(host) and s.owned_of(first) == 0 and s.money >= Economy.producer_cost(s, first, 1)
		"owns1":
			return Ftue.owned_total(s) >= 1
		"suitcase":
			return _free(host) and (host.get("golden") as GoldenView).on_screen()
		"caught":
			return s.golden_caught_lifetime >= 1
		"chatWaiting":
			return _free(host) and _rv(host, "tabs") and s.coalition is Dictionary and bool((s.coalition as Dictionary).get("opened", false))
		"chatOpened":
			return bool(s.ui.get("chatOpened", false))
		"payVisible":
			return chat.is_open() and not mgr.is_open()
		"paid1":
			return s.coalition is Dictionary and int(float((s.coalition as Dictionary).get("paidLifetime", 0))) >= 1
		"seatsShown":
			return _free(host) and _rv(host, "seats")
		"ctaUp":
			return _free(host) and (host.get("ticker") as Ticker).cta_on()
		"elected":
			return s.evolutions >= 1
		# the reveal ladder's mechanics
		"newTile":
			return cond(host, "picking")   # the anchor (the new tile) decides
		"spinsTab":
			return _free(host) and _rv(host, "spins") and bool(host.get("_tabs_up")) and (host.get("shop") as Shop).tab != "upgrades"
		"spinsOpened":
			return (host.get("shop") as Shop).tab == "upgrades"
		"thermo":
			return _free(host) and (host.get("thermo") as Thermo).is_shown()
		"ultCameo":
			return _free(host) and chat.cameo_visible()
		"event":
			return _free(host) and float(host.get("_now")) - float(host.get("wiz_event_ms")) < 8000.0
		"ability":
			return _free(host) and (host.get("ability_chip") as AbilityChip).visible
		"missions":
			return _free(host) and (host.get("missions_chip") as MissionsChip).visible
		"perks":
			return chat.is_open() and not mgr.is_open() and Meta.can_buy_any_perk(s)
		"mordechai":
			return str(host.get("mode")) == "main" and Events.screen_blocked(s)
		"share":
			var sd: ShareDesk = host.get("share_desk")
			return _free(host) and sd != null and sd.chip != null and sd.chip.visible
		"milestone":
			return _free(host) and s.owned_of(Content.producer_ids()[0]) >= 1
	push_error("WizardHooks.cond: unknown %s" % name)
	return false


## Every name the content may use (test_wizard checks the table against it).
const CONDS := ["picking", "slipChosen", "picked", "stage", "tapped3", "card1Afford", "owns1", "suitcase", "caught", "chatWaiting",
	"chatOpened", "payVisible", "paid1", "seatsShown", "ctaUp", "elected", "newTile", "spinsTab", "spinsOpened",
	"thermo", "ultCameo", "event", "ability", "missions", "perks", "mordechai", "share", "milestone", "tapHole"]
const ANCHORS := ["pickOpen", "pickGo", "pickNew", "leader", "card1Pill", "coalitionTab", "payPill", "seats", "suitcase", "cta",
	"spinsTab", "thermo", "ultimatum", "event", "ability", "missions", "perks", "mordechai", "share", "milestone"]


static func anchor(host: Node, name: String) -> Rect2:
	var stage := Vector2(float(host.get("_sx")), float(host.get("_stage_y")))
	var lower := Vector2(float(host.get("_ox")), float(host.get("_lower_y")))
	var top := Vector2(float(host.get("_ox")), float(host.get("_top_y")))
	var chat: ChatView = host.get("chat")
	match name:
		"pickOpen", "pickNew":
			var pk: PickView = host.get("picker")
			var r := Rect2()
			for c: Dictionary in pk.cells:
				var id := str(c["id"])
				var t := pk.tile_of(id)
				if id == "" or t.get("decoy", false) or t.get("locked", false):
					continue
				if name == "pickNew" and not t.get("new", false):
					continue
				var cr := (c["rect"] as Rect2)
				r = cr if not r.has_area() else r.merge(cr)
			return Rect2(r.position + pk.position, r.size) if r.has_area() else Rect2()
		"pickGo":
			var pk: PickView = host.get("picker")
			return Rect2(pk.go_btn.hit.position + pk.position, pk.go_btn.hit.size) if pk.go_btn != null else Rect2()
		"leader":
			var r := (host.get("magician") as Magician).hit_rect()
			return Rect2(r.position + stage, r.size)
		"card1Pill":
			var k := _first_k(host)
			if k < 0:
				return Rect2()
			var shop: Shop = host.get("shop")
			var c := shop.pill_pos(k)
			return Rect2(c - shop.PILL_RECT.size / 2.0 + lower, shop.PILL_RECT.size)
		"coalitionTab", "spinsTab":
			var r := L.tab_rect(Shop.TABS.find("coalition" if name == "coalitionTab" else "upgrades") + 1)
			return Rect2(r.position + lower, r.size)
		"payPill":
			if not chat.is_open():
				return Rect2()
			var top_y := ChatView.THREAD_Y
			var bot_y := top_y + chat.thread_h() - chat.bottom_pad()
			for h: Dictionary in chat.hits():
				if h["kind"] != "pay":
					continue
				var hr := h["rect"] as Rect2
				var p := chat.content_to_tall(hr.position)
				if p.y < top_y or p.y + hr.size.y > bot_y:
					continue
				return Rect2(p + chat.position + lower, hr.size)
			return Rect2()
		"seats":
			var r := TopBar.seats_hit()
			return Rect2(r.position + top, r.size)
		"suitcase":
			var g: GoldenView = host.get("golden")
			return Rect2(g.hit_rect().position + g.position + stage, L.SUITCASE_HIT) if g.on_screen() else Rect2()
		"cta":
			var tk: Ticker = host.get("ticker")
			var r := tk.cta.visual
			return Rect2(r.position + tk.position + lower, r.size)
		"thermo":
			var r := (host.get("thermo") as Thermo).hit_rect()
			return Rect2(r.position + stage, r.size)
		"ultimatum":
			var r := chat.cameo_rect()
			return Rect2(r.position + chat.position + lower, r.size) if r.has_area() else Rect2()
		"event":
			var r := (host.get("toasts") as Toasts).covered_rect()
			if r.has_area():
				return Rect2(r.position + stage, r.size)
			var tk: Ticker = host.get("ticker")
			return Rect2(tk.position + lower, Vector2(L.cw, L.TICKER_H)) if tk.visible else Rect2()
		"ability":
			var r := (host.get("ability_chip") as AbilityChip).hit_rect()
			return Rect2(r.position + stage, r.size)
		"missions":
			var r := (host.get("missions_chip") as MissionsChip).hit_rect()
			return Rect2(r.position + stage, r.size)
		"perks":
			var r := ChatView.pinned_hit()
			return Rect2(r.position + chat.position + lower, r.size)
		"mordechai":
			var m := StreetFigure.mark()
			return Rect2(m + Vector2(-96, -288) + stage, Vector2(192, 296))
		"share":
			var sd: ShareDesk = host.get("share_desk")
			if sd == null or sd.chip == null:
				return Rect2()
			return Rect2(ShareDesk.ShareChip.LEFT_RECT.position + sd.chip.position + stage, ShareDesk.ShareChip.LEFT_RECT.size)
		"milestone":
			var k := _first_k(host)
			if k < 0:
				return Rect2()
			var shop: Shop = host.get("shop")
			var y := shop.row_screen_y(k, "producers")
			return Rect2(Vector2(shop.list_rect.position.x, y) + lower, Vector2(shop.list_rect.size.x, float(L.SHOP["rowVisualH"])))
	push_error("WizardHooks.anchor: unknown %s" % name)
	return Rect2()
