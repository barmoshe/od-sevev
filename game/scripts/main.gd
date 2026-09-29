extends Node2D
## MainController: the LEADER_PICK, TITLE (pre-tap) and MAIN states, overlays and EVOLVE_TX in one
## scene (port of v1.1 src/scenes/MainScene.ts).
##
## Leader select (design/leader-select-spec.md §3, ux/rtl-map.md §8, ux/screen-graph.md §0):
## `mode == "pick"` is the picker (PickView), which replaces the title on a fresh game and follows
## EVOLVE_TX (and the O3b flash) after every election. One rule opens it: whenever the sim says
## the pick is pending (`Leaders.pick_pending`: a new game, every election, a reload mid-pick, the
## undo) and no transition or overlay is up. While it is pending the economy is frozen (the round's
## clock starts on the pick frame). A pick writes the round (`Politics.install`) and saves before
## the stage returns; a first-launch pick lands in the pre-tap state (`mode == "title"`, the title
## state without its lines), an after-election pick straight in the round. It owns the one GameState, ticks the pure economy on a fixed 1/60 s
## step, routes every pointer and key through one input boundary, and drives the views.
##
## Layout (ux/mobile-first-layout.md): the canvas is split into sections (top bar, stage, ticker +
## shop, overlays), each offset as a whole. The chrome spans the whole canvas width (L.cw, fluid
## anchors), only the stage art stays a centred 720 column (_sx); the vertical budget is
## bottom-up: the tab bar pinned to the safe bottom, whole card rows, the stage takes the rest.

const STEP_MS := 1000.0 / 60.0
const AWAY_GAP_SEC := 2.0          # a wall-clock gap longer than this between frames = time away

var state: GameState
var d: Economy.Derived
var settings: Dictionary = {}
var store := SaveStore.new()

var mode := "title"
var _load_kind := "none"
var _acc := 0.0
var _tx_locked := false
var _economy_frozen := false
var _next_state: GameState
var _presses := {}                  # pointer index -> {kind, ...}
var _keyboard_active := false
var _autosave_ms := 0.0
var _save_dirty := false
var _save_cooldown := 0.0
var _last_wall := 0.0
var _prev_buffs := {"frenzy": false, "tapFrenzy": false}
var _evolve_was_visible := false
var _hover_banana := false
var _first_input := false
var _pending_offline: Dictionary = {}
var _limiter: TapLimiter
var _shake := {"px": 0.0, "ms": 0.0, "t": 0.0, "frame": 0, "ysign": 1.0}
var _now := 0.0
var _dev := {"on": false, "speed": 1.0, "grant": 0.0, "evo": -1.0, "susp": -1.0, "aide": 0.0}
var _shot := {}                     # store screenshot mode (tools/store_shots.sh): never saves
var _auto_tap_acc := 0.0
var _butler_ms := 0.0
var _meta_check_ms := 0.0
var _milestone_seen := {}           # producer id -> milestone mult already announced
var _all_milestone_seen := 1.0
var _tap_frenzy_taps := 0
var _recent_headlines: Array = []
var _os_motion_ms := 0.0
var _golden_caught_this := false
var _coin_batch := 0                # taps since the Magician's last coin burst

# layout
var _vs := Vector2(L.W, L.H)
var _ox := 0.0                      # the chrome's x (0 on a phone: the canvas is the chrome)
var _sx := 0.0                      # the stage column's x (_ox + L.sox(): centred)
var _top_y := 0.0
var _stage_y := 0.0
var _stage_extra := 0.0
var _shop_extra := 0.0
var _ovl_y := 0.0
var _lower_y := 0.0

# scene graph
var _root := Node2D.new()          # shaken as a whole
var _bg := Node2D.new()             # full-width backdrops behind the sections
var _stage := Node2D.new()
var _top := Node2D.new()
var _lower := Node2D.new()          # ticker + shop
var _ui := Node2D.new()             # FTUE, UI FX
var _modal := Node2D.new()          # overlays + EVOLVE_TX
var diorama: Diorama
var bb: BigBanana
var prop_fx: PropFx                 # the Magician's coins and rabbit
var toasts: Toasts                  # the toast dock + Dubi's bubble (ux/ftue.md)
var _reveals: Dictionary = {}       # Ftue.reveals(state), refreshed every frame
var _last_tap_ms := -1e9            # play-time ms of the last registered tap (S1)
var _sources_sent := -1             # the last owned total sent to the Audio
var _progress_ms := 0.0             # set_era_progress throttle
var _trick_fired := false           # this election's trickCue (EvolveTx)
var _ceremony_on_marker := false    # the Audio emits marker("fanfare", "fanfareEnd")
var _settings_existed := false      # the player (or a previous session) saved settings
var golden: GoldenView
var floaters: Floaters
var buffs: BuffViews
var fx_stage: FxPlayer
var fx_ui: FxPlayer
var top_bar: TopBar
var ticker: Ticker
var shop: Shop
var title_view: TitleView
var ftue: Ftue
var overlays: OverlayManager
var tx: EvolveTx
var chat: ChatView                  # T3 "קואליציה 61" (ui/views/view_chat.gd)
var cottage: CottageCup             # Row A's Cottage Index (ui/views/view_cottage.gd)
var dossier: DossierView            # T4 "תיקים" + the pardon desk (ui/views/view_dossier.gd)
var court: CourtView                # the O2 court card + its ticker chip (ui/views/view_court.gd)
var thermo: Thermo                  # the suspicion thermometer + the sweat (ui/views/view_thermo.gd)
var picker: PickView                # LEADER_PICK (ui/views/view_pick.gd)
var _pick_res: Dictionary = {}      # the last commit's Leaders.start_round result + {via}
var _pick_seq: Array = []           # [{at (ms, _now), fn}]: the round-start sequence (rtl-map §8.6)
var _pick_shown_ms := 0.0
var _undo_btn: PxButton             # "להחליף ראש רשימה" (rtl-map §8.6)
var _undo_bar: ColorRect
var _undo_ms := 0.0                 # wall ms left on the undo chip
var _undo_full := 5000.0
var court_echo: CourtEcho            # the courthouse window on the stage (Bibi's rounds; ui/court_echo.gd)
## Every cue sent to the Audio, by name (tests and tools listen; nothing in the game does).
signal audio_sent(name: String, arg: Variant)
var _last_buy_ms := -1e9            # C1's allowPing: the last purchase ≥ 2 s ago
var _fills := {}
var _title_ground: TextureRect
var _title_floor: TextureRect        # the pre-tap / pick floor under the stage: paving (mobile-first §3.3)
var _bottom_inset := 0.0
var _seats_up := false               # the Row B fill is drawn (C2, mobile-first §3.3)
var _tabs_up := false                # the tab bar is revealed (C1)
var _slots_known := false
var _tab_slide: Tween
## R9 (rtl-map §7.1 "History"): one browser history entry per open layer (web only).
var history := LayerHistory.new()
var _js_pop_cb: JavaScriptObject     # kept alive: the shell calls window.odOnPop on popstate
var _layers_sent := -1


func _ready() -> void:
	_read_shot_args()
	if _shot.has("device") and not get_parent() is SubViewport:
		_enter_device_viewport.call_deferred()
		return
	_boot()


## `--device=WxH` shots: the whole scene renders into an offscreen SubViewport of exactly that many
## device pixels (a phone's backing store can be taller than this monitor); `_apply_display`
## gives it the same scale the window would get.
func _enter_device_viewport() -> void:
	var dev: Vector2i = _shot["device"]
	var sv := SubViewport.new()
	sv.size = dev
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	sv.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	sv.snap_2d_transforms_to_pixel = true
	sv.snap_2d_vertices_to_pixel = true
	get_tree().root.add_child(sv)
	get_parent().remove_child(self)
	sv.add_child(self)
	_boot()


func _boot() -> void:
	randomize()
	_read_content_override()
	_limiter = TapLimiter.new()
	_settings_existed = FileAccess.file_exists(store.settings_path)
	settings = store.load_settings(_default_settings())
	var res := store.load_game() if _shot.is_empty() else {"kind": "ok", "state": _shot_state(), "lastSaveTime": SaveStore.now_ms()}
	_load_kind = res["kind"]
	if res["kind"] == "ok":
		state = res["state"]
		mode = "main"
	else:
		state = GameState.fresh()
		Leaders.set_salt(state, randi())   # the seat deals differ between players (sim README)
		mode = "title"
	if _shot.is_empty() and Leaders.pick_pending(state):
		mode = "pick"   # a new game, or a reload mid-pick (leaderPickPending)
	_read_dev_params()
	if float(_dev["grant"]) > 0.0:
		Economy.add_bananas(state, float(_dev["grant"]))
	if float(_dev["evo"]) >= 0.0:
		state.evolutions = int(_dev["evo"])
	if float(_dev["susp"]) >= 0.0:   # the investigation views (&susp=100 summons on the first step)
		state.investigation["revealed"] = true
		state.investigation["suspicion"] = minf(100.0, float(_dev["susp"]))
	if float(_dev["aide"]) > 0.0:
		state.investigation["aideHolding"] = float(_dev["aide"])
	if float(_dev.get("chat", 0.0)) > 0.0:
		_dev_chat(int(_dev["chat"]))
	if float(_dev.get("court", 0.0)) > 0.0:   # &court=N: a court day of N s from the first frame (motion checks)
		state.investigation["revealed"] = true
		state.investigation["suspicion"] = 100.0
		state.investigation["phase"] = "summons"
		Investigation.testify(state)
		state.investigation["leftSec"] = float(_dev["court"])
	if float(_dev.get("slow", 0.0)) > 1.0:    # &slow=N: the whole game at 1/N speed (frame-strip captures)
		Engine.time_scale = 1.0 / float(_dev["slow"])
	d = Economy.derive(state)
	_build()
	_apply_settings()
	get_viewport().size_changed.connect(_relayout)
	_relayout()
	diorama.sync(state.owned, false)
	_evolve_was_visible = Economy.evolve_visible(state)
	_seed_milestones()
	diorama.set_era(Story.era_for(state.evolutions))
	_prev_buffs = {"frenzy": state.buff_frenzy > 0.0, "tapFrenzy": state.buff_tap_frenzy > 0.0}
	_audio_call("set_evolutions", [state.evolutions])
	if Leaders.active():
		_audio_call("set_leader", [Leaders.current(state)])   # Audio v1.3: the round's crits (on load)
	if mode == "pick":
		_open_picker()
	else:
		_set_mode(mode, false)
	if res["kind"] == "ok":
		_credit_away((SaveStore.now_ms() - float(res["lastSaveTime"])) / 1000.0, true)
	if res["kind"] == "corrupt" or res["kind"] == "newer":
		push_warning("[save] %s save kept at %s" % [res["kind"], res.get("backup", "")])
	_last_wall = Time.get_unix_time_from_system()
	if mode == "main" and not OS.has_feature("web"):
		_audio_call("start_music", [])   # web starts the song on the audio unlock (Audio autoload)
	_refresh_all(0.0)
	if not _pending_offline.is_empty() and mode != "pick":
		_show_offline()   # screen-graph §0.2 rule 2: O1 is queued until after the pick
	if not _shot.is_empty():
		_run_shot()


## Dev only (`?dev=1&chat=N`, the views wave-6 browser check): the group opens now, N partners'
## join lines follow the first demand, then Amsalem and Smotrich brawl, so T3 has an open pill above
## the fold (the "{n} ממתינים ↑" chip) and the stage shows the brawl cue.
func _dev_chat(n: int) -> void:
	if not Coalition.active():
		return
	var dd := Economy.derive(state)
	if not bool(state.coalition.get("opened", false)):
		Coalition.open_group(state, dd, func() -> float: return 0.0)
	var ids: Array = Coalition.partners().map(func(p: Dictionary) -> String: return str(p["id"]))
	for i in n:
		Coalition._post(state, {"type": "sys", "key": "chat.sys.joined", "partner": ids[i % ids.size()]}, [])
	# the shipped pair when both are in the round's lineup (Bibi's), else any two members (spec
	# §10.1: the lineup differs per leader)
	var pair: Array = ["amsalem", "smotrich"]
	if Coalition.partner("amsalem").is_empty() or Coalition.partner("smotrich").is_empty():
		pair = ids.filter(func(x: String) -> bool: return Coalition.partner(x).get("standIn", false) != true).slice(0, 2)
	if pair.size() < 2:
		return
	for id: String in pair:
		Coalition.ps(state, id)["status"] = "member"
	Coalition.start_brawl(state, pair[0], pair[1])


## Desktop dev runs only: `godot --path game -- --content=res://tests/fixtures/content.fork.json`
## boots on another content file (engine checks while design/content.json is mid-rewrite). The
## web build never reads it (no command line there; tests/ is not exported).
func _read_content_override() -> void:
	if OS.has_feature("web"):
		return
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--content="):
			Content.load_from(a.substr(10))


## Dev-only URL params on the web build (all ignored without ?dev=1): &speed=N multiplies game
## time, &grant=N adds bananas at boot, &evo=N sets the evolution count (era checks). Same contract as v1.1 (HOW-TO-RUN.md).
## &forkscale=1 shows the fork's fractional stretch (the "before" of integer art scaling).
## &sharp=0 draws every reading text on Sevev 9 (the "before" of the @2 reading cut, PxText.reading).
## &flash=N opens Dubi's news flash for round N on the first tap (view checks).
## &susp=N reveals the thermometer at N% suspicion (100 = a summons on the first step), &aide=N
## puts N ₪ of suitcase money on an aide (the "אני לא מכיר אותו" button).
## &court=N starts a court day of N s at boot (Bibi's exit / hat / return), &slow=N runs the whole
## game at 1/N speed (Engine.time_scale) for frame-strip captures (tools/web/motion_web.mjs).
func _read_dev_params() -> void:
	if not OS.has_feature("web"):
		return
	var q := str(JavaScriptBridge.eval("window.location.search || ''", true))
	if not q.contains("dev=1"):
		return
	_dev["on"] = true
	_dev["forkscale"] = q.contains("forkscale=1")
	if q.contains("sharp=0"):
		PxText.set_sharp_text(get_tree(), false)
	for part in q.trim_prefix("?").split("&"):
		var kv := part.split("=")
		if kv.size() == 2 and kv[0] in ["speed", "grant", "evo", "flash", "susp", "aide", "chat", "court", "slow"]:
			_dev[kv[0]] = maxf(0.0, float(kv[1]))
	if float(_dev["speed"]) <= 0.0:
		_dev["speed"] = 1.0


func _default_settings() -> Dictionary:
	return {"sfx": true, "music": true, "reducedMotion": _os_reduced_motion(), "reducedMotionFollowsOs": true,
		"haptics": true, "notation": "letters", "sfxVolume": 1.0, "musicVolume": 1.0, "shake": 1.0, "largeText": false}


func _os_reduced_motion() -> bool:
	if OS.has_feature("web"):
		return js_bool(JavaScriptBridge.eval("window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches", true))
	return false


## A JS boolean through JavaScriptBridge.eval. The 4.7 web bridge hands a boolean back as the int 1 / 0
## (seen in Chromium, animator audit 2026-09-29), and `1 == true` is false in GDScript, so the OS
## reduced-motion preference was never followed on the web. Truthy numbers and bools count.
static func js_bool(v: Variant) -> bool:
	if v is bool:
		return v
	if v is int or v is float:
		return float(v) != 0.0
	return false


# ================================================================== build

func _build() -> void:
	add_child(_root)
	for n: Node2D in [_bg, _stage, _top, _lower, _ui, _modal]:
		_root.add_child(n)
	var th := Art.theme
	_fills["sky"] = null
	# the top bar's full-width backing lives in the top section, above the (extended) sky
	# od-sevev (rtl-map §1): Row A/B sit on the #140C24 scrim (92%); the panel on the night blue;
	# the tab bar's kit art is drawn by the shop; the bottom inset continues the tab bar colour
	_fills["top"] = Ui.rect(_top, Rect2(), Color(0.078, 0.047, 0.141, 0.92))
	_fills["shop"] = Ui.rect(_lower, Rect2(), Color("#2a2340"))
	_fills["bottom"] = Ui.rect(_lower, Rect2(), Color("#1b1426"))
	_title_ground = TextureRect.new()
	_title_ground.texture = Art.tex("env_ground")
	_title_ground.stretch_mode = TextureRect.STRETCH_TILE
	_title_ground.scale = Vector2(4, 4)
	_title_ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_title_ground)
	_root.move_child(_title_ground, 0)
	# mobile-first §3.3 (V11): in the pre-tap and pick states the ticker, pane and tabs are hidden;
	# the region under the stage is the apron continued to the safe bottom (interim for 2D ask A1:
	# the engine's paving tile in the era's floor colour, never one flat colour)
	_title_floor = TextureRect.new()
	_title_floor.stretch_mode = TextureRect.STRETCH_TILE
	_title_floor.scale = Vector2(4, 4)
	_title_floor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title_floor.visible = false
	_root.add_child(_title_floor)
	_root.move_child(_title_floor, _stage.get_index() + 1)
	_build_history()
	diorama = Diorama.new()
	_stage.add_child(diorama)
	bb = BigBanana.new()
	_stage.add_child(bb)
	prop_fx = PropFx.new()
	_stage.add_child(prop_fx)
	bb.on_hero_event = _on_hero_event
	bb.on_court_fx = _on_court_fx
	fx_stage = FxPlayer.new()
	_stage.add_child(fx_stage)
	diorama.play_fx = func(id: String, x: float, y: float) -> void: fx_stage.play(id, x, y)
	floaters = Floaters.new()
	_stage.add_child(floaters)
	buffs = BuffViews.new()
	_stage.add_child(buffs)
	golden = GoldenView.new()
	_stage.add_child(golden)
	golden.on_despawn_start = func() -> void:
		_audio("goldenDespawn")
		state.stats["goldenMissed"] = float(state.stats.get("goldenMissed", 0.0)) + 1.0
		ftue.on_golden_missed(state)
	toasts = Toasts.new()
	_stage.add_child(toasts)
	# rtl-map §4: the fork's Book / Perks plates are gone (the book is T4, perks the coalition
	# agreement, both tall-tab views of a later wave)
	title_view = TitleView.new()
	_stage.add_child(title_view)
	top_bar = TopBar.new()
	_top.add_child(top_bar)
	cottage = CottageCup.new().setup(self)
	_top.add_child(cottage)
	# every Dubi squawk is a talking point: the sim may scramble it (word salad, wordSaladSeen)
	toasts.dubi_line = func(t: String) -> String: return FlashCard.dubi_says(state, t)
	ticker = Ticker.new()
	_lower.add_child(ticker)
	ticker.on_milestone_start = func(text: String) -> void:
		_audio("milestoneHeadline")
		_audio("headline", text)   # the Audio rations Dubi's reading
	ticker.ambient_source = func() -> String: return Ambient.pick(state, _recent_headlines)
	shop = Shop.new()
	_lower.add_child(shop)
	shop.buy_producer_requested.connect(_on_buy_producer)
	shop.buy_upgrade_requested.connect(_on_buy_upgrade)
	shop.cant_afford.connect(func() -> void:
		_audio("cantAfford")
		_haptic(15))
	shop.cycle_mode.connect(_cycle_buy_mode)
	shop.tab_switched.connect(_on_tab_switched)
	shop.became_affordable.connect(func() -> void: _audio("becameAffordable"))
	shop.producer_revealed.connect(func() -> void: _audio("producerReveal"))
	shop.list_interaction.connect(func() -> void: ftue.on_input())
	shop.nudge_blocked = func() -> bool: return overlays.is_open() or tx.running or _tx_locked or ftue.pointer_visible()
	_build_chat()
	_build_investigation()
	fx_ui = FxPlayer.new()
	_ui.add_child(fx_ui)
	ftue = Ftue.new()
	_ui.add_child(ftue)
	ftue.ticker = func(t: String) -> void: ticker.enqueue("ftue", t)
	ftue.on_banana_emphasis = func() -> void: bb.emphasize(1200)
	ftue.on_pulse = func(hz: float) -> void: bb.set_pulse(hz)
	ftue.toasts = toasts
	overlays = OverlayManager.new()
	_modal.add_child(overlays)
	overlays.keyboard_active = func() -> bool: return _keyboard_active
	overlays.stack_changed.connect(func() -> void: top_bar.set_pulse_paused(overlays.is_open()))
	tx = EvolveTx.new()
	_modal.add_child(tx)
	picker = PickView.new()
	picker.host = self
	_root.add_child(picker)
	_root.move_child(picker, _modal.get_index())   # over the stage and the HUD, under the overlays
	picker.on_commit = _on_pick_commit
	picker.on_done = _on_pick_done
	picker.on_card = _open_leader_card
	_build_undo_chip()
	title_view.build(bool(settings["reducedMotion"]), show_key_hints())
	var a := get_node_or_null("/root/Audio")
	if a:
		if a.has_signal("marker"):
			_ceremony_on_marker = true
			a.connect("marker", func(cue: String, nm: String) -> void:
				if cue == "fanfare" and nm == "fanfareEnd":
					_audio("ceremonyEnd"))
		if a.has_signal("dubi_blip"):
			a.connect("dubi_blip", func(_bank: String) -> void: ticker.dubi_talk())


## R9 (rtl-map §7.1 "History"): the shell forwards every popstate that is not About's own to
## window.odOnPop; the controller closes the top layer on the player's back (LayerHistory).
func _build_history() -> void:
	if not OS.has_feature("web"):
		return
	_js_pop_cb = JavaScriptBridge.create_callback(func(_args: Array) -> void: _history_pop.call_deferred())
	var win := JavaScriptBridge.get_interface("window")
	if win != null:
		win.odOnPop = _js_pop_cb


## The open layers, bottom to top: T3/T4 (one slot: opening one closes the other), the expanded
## court card (non-modal, above the tall tabs), then the overlay stack (the partner card, settings,
## O10 over it, ...). Title state and the election transition hold no entries.
func layer_depth() -> int:
	if mode == "pick":
		# screen-graph §0.2 rule 4: the after-election picker holds one entry (back = again)
		return overlays.stack.size() + (1 if picker.variant == "after" and picker.again_id != "" else 0)
	if mode != "main":
		return 0
	var n := overlays.stack.size()
	if chat.is_open() or dossier.is_open():
		n += 1
	if court.expanded():
		n += 1
	return n


## Closes the top layer exactly as its ✕ / Esc does (browser back, Android back, Esc). False when
## nothing is open.
func back_layer() -> bool:
	if overlays.is_open():
		return overlays.back()
	if tx.running or _tx_locked:
		return true
	if mode == "pick":
		if picker.variant == "after" and picker.again_id != "":
			picker.commit_again("back")
			return true
		return false
	if court.expanded():
		court.collapse()   # rtl-map §6.4: back collapses the expanded card to its chip first
		return true
	if chat.is_open():
		chat.close()
		return true
	if dossier.is_open():
		dossier.close()
		return true
	return false


func _history_pop() -> void:
	if history.on_pop():
		back_layer()


func _sync_history() -> void:
	var depth := layer_depth()
	var js := LayerHistory.js_for(history.sync(depth))
	if depth != _layers_sent:
		_layers_sent = depth
		js += " window.odLayers = %d;" % depth   # web debug, like odDisplay: the open layers
	if js != "" and OS.has_feature("web"):
		JavaScriptBridge.eval(js, true)


## T3 "קואליציה 61" (ux/rtl-map.md §6.3): the chat view over the stage, ticker and panel, opened
## from its tab slot, Row B, a chat toast or the ultimatum cameo.
func _build_chat() -> void:
	chat = ChatView.new().setup(self)
	_lower.add_child(chat)
	shop.tall_tab_requested.connect(func(t: String) -> void:
		if t == "coalition":
			chat.toggle())
	chat.open_changed.connect(func(on: bool) -> void:
		shop.tall = "coalition" if on else ""
		shop.cancel_press())
	toasts.on_tap = func(tag: String) -> void:
		if tag == "chat" and _gameplay_input():
			chat.open()


## The investigation cluster: the thermometer and the sweat on the stage (rtl-map §4, just above
## the Magician), T4 over the stage, ticker and panel (§6.3), the court card over the panel and its
## chip in the ticker (§6.4, §5.1). T3 and T4 are one layer: opening one closes the other.
func _build_investigation() -> void:
	thermo = Thermo.new().setup(self, bb)
	_stage.add_child(thermo)
	_stage.move_child(thermo, bb.get_index() + 1)
	court_echo = CourtEcho.new()
	_stage.add_child(court_echo)
	_stage.move_child(court_echo, bb.get_index())   # over the stage art, behind the Magician
	dossier = DossierView.new().setup(self)
	_lower.add_child(dossier)
	court = CourtView.new().setup(self)
	_lower.add_child(court)
	shop.tall_tab_requested.connect(func(t: String) -> void:
		if t == "dossier":
			dossier.toggle())
	dossier.open_changed.connect(func(on: bool) -> void:
		if on:
			chat.close()
		shop.tall = "dossier" if on else ("" if shop.tall == "dossier" else shop.tall)
		shop.cancel_press())
	chat.open_changed.connect(func(on: bool) -> void:
		if on:
			dossier.close())


# ================================================================== layout

var _in_relayout := false


## Integer art scaling (core/display.gd, HOW-TO-RUN "Integer art scaling"): the viewport this
## scene renders into draws the logical canvas at f = k/4 device px per logical px, one uniform
## stretch transform, so 1 art px = k whole device px at every size and DPR, and Godot maps every
## input event back to logical px through the same transform (hit tests never see device px).
## - The window (web canvas, desktop, phone): stretch mode disabled + content_scale_factor f, so
##   the logical viewport is W/f × H/f (the aspect-`expand` area grows instead of the scale).
## - A SubViewport host (`--device` shots, the scaled-input tests): size_2d_override W/f × H/f.
## - Too small for k = 1 (the headless test window), or `--fork-scale`: the fork's fractional
##   canvas_items + expand stretch. Store shots with --target keep their own viewport stretch.
func _apply_display() -> void:
	if _shot.has("target"):
		return
	var sv := get_viewport() as SubViewport
	var dev := Vector2(sv.size) if sv else Vector2(get_window().size)
	var changed := Display.update(dev, _shot.has("fork_scale") or bool(_dev.get("forkscale", false)))
	if sv:
		var ov := Vector2i(Display.logical_size(dev).floor())
		if sv.size_2d_override != ov or not sv.size_2d_override_stretch:
			sv.size_2d_override = ov
			sv.size_2d_override_stretch = true
			changed = true
	else:
		var w := get_window()
		var mode := Window.CONTENT_SCALE_MODE_DISABLED if Display.integer else Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
		var fac := Display.f if Display.integer else 1.0
		if w.content_scale_mode != mode or not is_equal_approx(w.content_scale_factor, fac):
			w.content_scale_mode = mode
			w.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
			w.content_scale_factor = fac
			changed = true
	if changed:
		PxText.relayout_all(get_tree())
		SpriteStrip.refresh_all(get_tree())


func _relayout() -> void:
	if _in_relayout:
		return
	_in_relayout = true
	_apply_display()
	_in_relayout = false
	_vs = get_viewport_rect().size
	var ins := _safe_insets()
	var top_inset := ceilf(float(ins.x) / 4.0) * 4.0
	var bottom_inset := ceilf(float(ins.y) / 4.0) * 4.0
	var vh := L.floor4(_vs.y)
	# mobile-first §3.1: Row A, Row B, the ticker and the tabs never shrink; the stage and the pane
	# split the rest bottom-up (§3.2)
	var r := vh - top_inset - bottom_inset - float(L.FIXED_H)
	var need := float(L.S_MIN + 2 * L.CARD)
	if r < need and top_inset > 0.0:
		var give := minf(top_inset, need - r)
		top_inset -= give
		r += give
	L.set_split(r, top_inset, vh)
	# §2: the chrome spans whole art columns (Display.cw); a landscape window (out of the matrix)
	# keeps a portrait-proportioned canvas, centred
	var cw := Display.cw() if Display.integer and not _shot.has("target") else float(L.W)
	L.set_width(minf(minf(cw, L.floor4(_vs.x)), maxf(float(L.W), L.floor4(0.75 * _vs.y))))
	_bottom_inset = bottom_inset
	_ox = L.floor4((_vs.x - L.cw) / 2.0)
	_sx = _ox + L.sox()
	_top_y = top_inset
	var st := _top_y + float(L.ROW_A_H + L.ROW_B_H)
	_stage_y = st - float(L.STAGE["y"])          # the stage node: design y 160 = the stage top
	_stage_extra = 0.0
	_shop_extra = 0.0
	_lower_y = st + L.stage_h
	_top.position = Vector2(_ox, _top_y)
	_stage.position = Vector2(_sx, _stage_y)
	_lower.position = Vector2(_ox, _lower_y)
	_ui.position = Vector2(_sx, _stage_y)
	# §5.10: the 1280 modal space in the safe band; on a tall canvas (safe height > 1400) its centre
	# sits at 55% of the band, so centred cards put their buttons in the lower half
	var hs := _vs.y - bottom_inset - _top_y
	var centre := _top_y + (0.55 if hs > 1400.0 else 0.5) * hs
	_ovl_y = L.floor4(clampf(centre - float(L.H) / 2.0, minf(_top_y, _vs.y - bottom_inset - float(L.H)), maxf(_top_y, _vs.y - bottom_inset - float(L.H))))
	_modal.position = Vector2(_ox, _ovl_y)
	diorama.extend(_sx + 8.0, _top_y + float(L.ROW_A_H + L.ROW_B_H) + 8.0)
	_apply_slots(false)
	title_view.refit()
	picker.position = Vector2(_ox, 0)
	picker.layout(_top_y, _vs.y - bottom_inset, _vs.x, _ox)
	_place_undo_chip()
	top_bar.relayout()
	cottage.position.x = L.dx
	ticker.relayout()
	toasts.relayout()
	golden.relayout()
	chat.relayout()
	dossier.relayout()
	court.relayout()
	thermo.relayout()
	court_echo.relayout()
	buffs.set_stage_rect(-_sx, float(L.STAGE["y"]), _vs.x, L.stage_h)
	bb.relayout()
	overlays.relayout()
	# TITLE: the dirt continues to the bottom of the screen (the fork's jungle; hidden under stage art)
	var gy := _stage_y + L.stage_bottom() - 64.0
	_title_ground.position = Vector2(0, gy)
	_title_ground.size = Vector2(ceilf(_vs.x / 64.0) + 1.0, ceilf((_vs.y - gy) / 64.0) + 1.0) * 16.0
	_place_title_floor()
	_publish_display()


## The reveal-dependent slots (mobile-first §3.3): Row B's fill only from C2 (before it the stage
## sky shows through the slot); the pane runs to the safe bottom until C1, when the tab bar slides
## up over its last 104 px (nothing above moves). `animate`: the reveal itself (150 ms / 200 ms;
## reduced motion: instant).
func _apply_slots(animate: bool) -> void:
	L.tabs_up = _tabs_up
	var W := _vs.x
	var row_b := float(L.ROW_B_H) if _seats_up else 0.0
	_set_fill("top", Rect2(-_ox, -_top_y - 8, W, _top_y + 8 + float(L.ROW_A_H) + row_b))
	var list_h := L.tabs_y() - float(L.SHOP["listY"])
	var shop_bottom := _vs.y - _lower_y + 8.0 if not _tabs_up else list_h
	_set_fill("shop", Rect2(-_ox, float(L.SHOP["listY"]), W, shop_bottom))
	_set_fill("bottom", Rect2(-_ox, L.tabs_y() + float(L.TABS_H) - 4.0, W, _vs.y - (_lower_y + L.tabs_y() + float(L.TABS_H)) + 12.0))
	(_fills["bottom"] as ColorRect).visible = _tabs_up
	shop.set_list_height(list_h)
	if animate and _tabs_up and not bool(settings.get("reducedMotion", false)):
		shop.slide_tabs(float(L.TABS_H) + _bottom_inset, 0.2)
	if animate and _seats_up:
		var f: ColorRect = _fills["top"]
		f.modulate.a = 0.0 if not bool(settings.get("reducedMotion", false)) else 1.0
		create_tween().tween_property(f, "modulate:a", 1.0, 0.15)


func _place_title_floor() -> void:
	var fy := _stage_y + L.stage_bottom()
	_title_floor.texture = Diorama.paving_texture(diorama.pad_bottom, false)
	# the tile's phase follows the stage column, so the floor continues the lane's joints
	var ph := fposmod(_sx, 64.0)
	_title_floor.position = Vector2(ph - 64.0, fy)
	_title_floor.size = Vector2(ceilf((_vs.x + 64.0) / 64.0) * 16.0, ceilf(maxf(0.0, _vs.y - fy) / 4.0) + 1.0)


## window.odDisplay (web debug, like window.odCueLog): the device scale, the section origins and
## the mobile-first split (logical px); tools/web/mobile_web.mjs reads it.
func _publish_display() -> void:
	if not OS.has_feature("web"):
		return
	var hat := L.magician_hit().get_center() + Vector2(_sx, _stage_y)
	JavaScriptBridge.eval("window.odDisplay = %s" % JSON.stringify({"k": Display.k, "f": Display.f,
		"integer": Display.integer, "logical": [_vs.x, _vs.y], "ox": _ox, "sx": _sx, "stageY": _stage_y,
		"lowerY": _lower_y, "hat": [hat.x, hat.y], "reducedMotion": bool(settings.get("reducedMotion", false)),
		"cw": L.cw, "S": L.stage_h, "P": L.panel_h, "rows": L.rows_whole, "cols": Display.cols, "artRows": Display.rows,
		"ticker": ticker.web_info()}), true)


func _set_fill(k: String, r: Rect2) -> void:
	var c: ColorRect = _fills[k]
	c.position = r.position
	c.size = r.size


## Safe-area insets (top, bottom) in design px: the notch/Dynamic Island and the home bar.
func _safe_insets() -> Vector2:
	var win := Vector2(DisplayServer.window_get_size())
	if win.x <= 0.0 or win.y <= 0.0:
		return Vector2.ZERO
	var k := _vs.y / win.y
	if OS.has_feature("web"):
		var v: Variant = JavaScriptBridge.eval("window.mbSafeArea ? window.mbSafeArea() : '0,0,0,0'", true)
		var parts := str(v).split(",")
		if parts.size() == 4:
			return Vector2(float(parts[0]) * _vs.y, float(parts[2]) * _vs.y)
		return Vector2.ZERO
	if OS.has_feature("mobile"):
		var safe := DisplayServer.get_display_safe_area()
		var screen := Vector2(DisplayServer.screen_get_size())
		return Vector2(float(safe.position.y) * k, maxf(0.0, screen.y - float(safe.end.y)) * k)
	return Vector2.ZERO


## Design-space point of a viewport point, for one section.
func _in_stage(p: Vector2) -> Vector2:
	return p - Vector2(_sx, _stage_y) - _root.position


func _in_top(p: Vector2) -> Vector2:
	return p - Vector2(_ox, _top_y) - _root.position


func _in_lower(p: Vector2) -> Vector2:
	return p - Vector2(_ox, _lower_y) - _root.position


func _in_modal(p: Vector2) -> Vector2:
	return p - Vector2(_ox, _ovl_y) - _root.position


func _in_pick(p: Vector2) -> Vector2:
	return p - picker.position - _root.position


# ================================================================== settings

func _apply_settings() -> void:
	var rm := bool(settings["reducedMotion"])
	Juice.reduced = rm
	bb.set_reduced_motion(rm)
	prop_fx.reduced_motion = rm
	golden.reduced_motion = rm
	diorama.set_reduced_motion(rm)
	floaters.reduced_motion = rm
	top_bar.set_reduced_motion(rm)
	buffs.set_reduced_motion(rm)
	ticker.set_reduced_motion(rm)
	shop.reduced_motion = rm
	chat.reduced_motion = rm
	cottage.reduced_motion = rm
	dossier.reduced_motion = rm
	court.reduced_motion = rm
	thermo.reduced_motion = rm
	court_echo.reduced_motion = rm
	ftue.reduced_motion = rm
	title_view.set_reduced_motion(rm)
	picker.reduced_motion = rm
	fx_stage.reduced_motion = rm
	fx_ui.reduced_motion = rm
	overlays.reduced = rm
	Fmt.notation = String(settings.get("notation", "letters"))
	var large := bool(settings.get("largeText", false))
	if large != PxText.large_text:
		PxText.set_large_text(get_tree(), large)
		if shop != null and _vs != Vector2.ZERO:
			_relayout()   # rtl-map §0.2: rows and centred labels re-measure at the scale drawn
	_audio_call("set_reduced_motion", [rm])
	_audio_call("set_sfx_enabled", [bool(settings["sfx"])])
	_audio_call("set_music_enabled", [bool(settings["music"])])
	_audio_call("set_volume", ["sfx", float(settings.get("sfxVolume", 1.0))])
	_audio_call("set_volume", ["music", float(settings.get("musicVolume", 1.0))])


## Host API for overlays.
func setting_on(key: String) -> bool:
	if key == "fullscreen":
		return is_fullscreen()
	return bool(settings.get(key, false))


func toggle_setting(key: String) -> void:
	if key == "fullscreen":
		set_fullscreen(not is_fullscreen())
	else:
		settings[key] = not bool(settings.get(key, false))
		if key == "reducedMotion":
			settings["reducedMotionFollowsOs"] = false   # the player chose: stop following the OS
		store.save_settings(settings)
		_apply_settings()
	_audio("uiToggle", setting_on(key))


func set_setting(key: String, value: Variant) -> void:
	settings[key] = value
	store.save_settings(settings)
	_apply_settings()


## O7 as a bottom sheet (rtl-map §7.1): h = min(content, 70% of the screen), in `_modal` space.
func sheet_rect(content_h: float) -> Rect2:
	var h := minf(content_h, floorf(0.70 * _vs.y / 4.0) * 4.0)
	var bi := bottom_inset()
	return Rect2(0, _vs.y - bi - h - _ovl_y, L.cw, h + bi)


func bottom_inset() -> float:
	return floorf(float(_safe_insets().y) / 4.0) * 4.0


## O4 the receipt / O5 the result card (ui/views/view_share.gd), from T4's rows (review R25).
func open_receipt() -> void:
	_open_share("receipt")


func open_result_card() -> void:
	_open_share("result")


func _open_share(kind: String) -> void:
	if overlays.is_open():
		return
	_audio("panelOpen")
	ShareKit.listen(_on_share_result)   # a bound method: a static lambda would outlive this node
	overlays.request(func() -> Overlay:
		var o := ShareSheet.new()
		o.setup(self, overlays)
		o.kind = kind
		return o.build())


## The shell's share result (window.odShareDone): the open sheet shows it in its status line.
func _on_share_result(_kind: String, result: String) -> void:
	var t := overlays.top()
	if t is ShareSheet:
		(t as ShareSheet).on_share_result(result)


## O8 About is HTML over the canvas (shell.html odOpenAbout).
func open_about() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.odOpenAbout && window.odOpenAbout()", true)


func fullscreen_available() -> bool:
	return OS.has_feature("pc") or (OS.has_feature("web") and not OS.has_feature("web_android") and not OS.has_feature("web_ios"))


func is_fullscreen() -> bool:
	return DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN


func set_fullscreen(on: bool) -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if on else DisplayServer.WINDOW_MODE_WINDOWED)


func show_key_hints() -> bool:
	return not DisplayServer.is_touchscreen_available()


func version_string() -> String:
	var v := str(ProjectSettings.get_setting("application/config/version", "2"))
	if OS.has_feature("web"):
		var b: Variant = JavaScriptBridge.eval("window.mbBuild || ''", true)
		if b != null and str(b) != "" and not str(b).begins_with("__"):
			v += " (" + str(b) + ")"
	return v


func audio_event(name: String, arg: Variant = null) -> void:
	_audio(name, arg)


func confirm_reset() -> void:
	_do_reset()


func confirm_evolve() -> void:
	_start_evolve()


func offline_collected() -> void:
	top_bar.big_gain("offline")


# ================================================================== audio + haptics

func _audio(name: String, arg: Variant = null) -> void:
	audio_sent.emit(name, arg)
	_audio_call("event", [name, arg])


func _audio_call(method: String, args: Array) -> void:
	var a := get_node_or_null("/root/Audio")
	if a and a.has_method(method):
		a.callv(method, args)


func _haptic(ms: int) -> void:
	if settings.get("haptics", true) and OS.has_feature("mobile"):
		Input.vibrate_handheld(ms)


# ================================================================== modes

func _set_mode(m: String, animate: bool) -> void:
	mode = m
	var main := m == "main"
	if m != "pick" and picker.visible:
		picker.close()
		picker.publish_closed()
	if m == "pick":
		# rtl-map §8: the HUD is hidden, the stage is empty behind the scrim
		bb.visible = false
		title_view.show_title(false)
		_top.visible = false
		_lower.visible = false
		_bg.visible = false   # as the title state: the era stage shows behind the scrim
		_title_ground.visible = not diorama.has_background()
		_title_floor.visible = true
		_title_floor.modulate.a = 1.0
		_place_title_floor()
		return
	bb.visible = true
	_bg.visible = main
	_title_ground.visible = not main and not diorama.has_background()
	_place_title_floor()
	_title_floor.modulate.a = 1.0
	_title_floor.visible = not main or animate   # fades out with the title (below)
	if not main:
		title_view.show_title(not Leaders.active())   # D26: the pre-tap state has no title lines
		_top.visible = false
		_lower.visible = false
		return
	var ms := float(Tune.MC["titleFadeReducedMs"] if settings["reducedMotion"] else Tune.MC["titleFadeMs"])
	_top.visible = true
	_lower.visible = true
	if animate:
		title_view.fade_out(ms)
		_top.modulate.a = 0.0
		_lower.modulate.a = 0.0
		var tw := create_tween().set_parallel()
		tw.tween_property(_top, "modulate:a", 1.0, ms / 1000.0)
		tw.tween_property(_lower, "modulate:a", 1.0, ms / 1000.0)
		tw.tween_property(_title_floor, "modulate:a", 0.0, ms / 1000.0)
		tw.chain().tween_callback(func() -> void: _title_floor.visible = mode != "main")
	else:
		title_view.show_title(false)


func _start_from_title(tap_at: Vector2, tapped: bool) -> void:
	_set_mode("main", true)
	if tapped:
		_handle_tap(tap_at)
	if _load_kind == "corrupt" or _load_kind == "newer":
		ticker.enqueue("ftue", Strings.s("F_SAVE_CORRUPT"))
	_load_kind = "none"
	_save_now()
	_audio_call("start_music", [])
	if int(_dev.get("flash", 0)) > 0:
		show_flash(int(_dev["flash"]))


# ================================================================== loop

func _process(delta: float) -> void:
	var wall := Time.get_unix_time_from_system()
	var gap := wall - _last_wall
	_last_wall = wall
	# A long wall-clock gap between frames is time away (a hidden tab, a locked phone, a call):
	# settle it through the one away rule instead of fast-forwarding the loop.
	if gap > AWAY_GAP_SEC and mode == "main":
		_on_away(gap)
	var dt := minf(250.0, delta * 1000.0)
	_now += dt
	# spec §3.1: the round's clock starts on the pick frame, never during the flash or the picker
	var running := mode == "main" and not Leaders.pick_pending(state)
	var modal := overlays.is_open() or tx.running
	if running and not _economy_frozen:
		_acc += dt * float(_dev["speed"])
		var guard := 0
		while _acc >= STEP_MS and guard < 2000:
			_acc -= STEP_MS
			guard += 1
			_step_economy(STEP_MS / 1000.0, modal)
	d = Economy.derive(state)
	if running and not _economy_frozen:
		_run_automation(dt, modal)
		_meta_check_ms += dt
		if _meta_check_ms >= 250.0:
			_meta_check_ms = 0.0
			_check_meta()
	_poll_handoff()
	_check_pick(dt)
	_check_buff_edges()
	_check_headlines()
	_check_reveals()
	_apply_reveals()
	# Bibi's court day on the stage (the exit, the hat, the return): polled from the sim's phase
	bb.court_sync(running and BigBanana.wants_court(state), tx.running)
	bb.update_view(dt)
	court_echo.update_view(dt, state, str(Story.era_for(state.evolutions).get("id", "")), running and Leaders.has_court())
	toasts.update_view(dt)
	prop_fx.update_view(dt)
	golden.update_view(dt, modal or not running)
	diorama.update_view(dt)
	floaters.update_view(dt)
	fx_stage.update_view(dt)
	fx_ui.update_view(dt)
	top_bar.update_view(dt)
	cottage.update_view(dt, state, running and bool(_reveals.get("counter", false)))
	_refresh_all(dt)
	shop.tick_hold(dt, state)
	chat.update_view(dt, state, d, {"main": running and not tx.running and not _tx_locked, "overlay": overlays.is_open()})
	var live := running and not tx.running and not _tx_locked
	dossier.update_view(dt, state, d, {"main": live})
	court.update_view(dt, state, d, {"main": live, "covered": chat.is_open() or dossier.is_open()})
	thermo.update_view(dt, state, {"main": running})
	ticker.update_view(dt)
	overlays.update_view(dt)
	tx.update_view(dt)
	_sync_history()
	ftue.update_view(dt, state, d, _ftue_ctx(running))
	_update_shake(dt)
	if bool(_dev["on"]):
		DevProbe.publish(self, dt)   # window.odDev for the browser drivers (tools/web/round_web.mjs)
	_audio_clocks(dt)
	Juice.tick(dt)
	_follow_os_motion(dt)
	if running and not tx.running:
		_autosave_ms += dt
		if _autosave_ms >= float(Content.data()["autosaveSec"]) * 1000.0:
			_autosave_ms = 0.0
			_save_now()
		_save_cooldown -= dt
		if _save_dirty and _save_cooldown <= 0.0:
			_save_now()


## Clock-driven Audio hooks: the Magician's trick lands 333 ms before the fanfare's roll end
## (motion-spec trickLeadMs), and the Outside bed rises with the progress toward 61 (1 Hz).
func _audio_clocks(dt: float) -> void:
	var a := get_node_or_null("/root/Audio")
	if a == null:
		return
	if tx.running and not _trick_fired and a.has_method("fanfare_clock_ms") and a.has_method("fanfare_markers"):
		var mk: Dictionary = a.call("fanfare_markers")
		if mk.has("rollEnd") and float(a.call("fanfare_clock_ms")) >= float(mk["rollEnd"]) * 1000.0 - float(Tune.MC.get("trickLeadMs", 333)):
			_trick_fired = true
			_audio("trickCue")
			if bb.hero != null:
				bb.hero.play(str(LeaderUi.tap()["critAnim"]), true, 1)   # the round's crit (Bibi: "crit")
	_progress_ms += dt
	if _progress_ms >= 1000.0 and mode == "main" and Coalition.active():
		_progress_ms = 0.0
		var si := Coalition.seat_info(state)
		_audio_call("set_era_progress", [clampf(float(si["effective"]) / maxf(1.0, float(si["gateSeats"])), 0.0, 1.0)])


## ux/ftue.md: what the prompts need to know this frame. Points are in the FTUE node's space
## (the stage node's: design y 160 = the stage top); the panel is `_lower`, S + 160 below it.
func _ftue_ctx(running: bool) -> Dictionary:
	var first: String = Content.producer_ids()[0]
	var k := shop.row_index_of(state, "producer", first) if bool(_reveals.get("card1", false)) else -1
	var pill: Variant = null
	if k >= 0 and shop.row_screen_y(k, "producers") >= 0.0 and shop.tab == "producers":
		pill = shop.pill_pos(k) + Vector2(-L.sox(), float(L.STAGE["y"]) + L.stage_h)   # `_lower` → the stage column
	return {
		"inMain": running and not tx.running, "title": mode == "title", "overlayOpen": overlays.is_open() or tx.running or chat.is_open() or dossier.is_open() or mode == "pick",
		"hat": L.magician_feet() - Vector2(0, 380), "pill": pill,
		"price": Economy.producer_cost(state, first, 1),
		"bounce": func() -> void: shop.bounce_row(k),
		"gateOpen": ticker.cta_on(), "ctaPoint": Vector2(360, L.stage_bottom() - 8.0),
	}


## rtl-map / ux/ftue.md reveals, applied every frame (derived from state, so reloads agree).
func _apply_reveals() -> void:
	Ftue.stamp_c1(state)   # K3 waits 10 s of play after the C1 toast (ux/ftue.md §3)
	_reveals = Ftue.reveals(state)
	var owned := Ftue.owned_total(state)
	if owned != _sources_sent:
		_sources_sent = owned
		_audio_call("set_sources_owned", [owned])   # the Audio's L1 follows the round's sources
	var main := mode == "main"
	top_bar.set_revealed(bool(_reveals["counter"]), bool(_reveals["rate"]), bool(_reveals["seats"]))
	shop.set_shop_visible(main and bool(_reveals["card1"]))
	shop.ftue_single = bool(_reveals["single"])
	shop.ftue_dim = state.evolutions == 0 and Ftue.owned_total(state) == 0
	var dos := dossier.tab_revealed()   # K2 (ux/ftue.md), derived in the dossier view
	# ux/ftue.md C1: the tab bar appears only with C1 ("tabs"); spins (K3) and the dossier (K2)
	# fill their fixed slots once it is there
	shop.set_tabs_revealed(bool(_reveals["tabs"]), [true, bool(_reveals["spins"]), bool(_reveals["tabs"]), dos])
	# mobile-first §3.3: the reserved slots fill at their reveals; nothing above them moves
	var seats_up := bool(_reveals["seats"])
	var tabs_up := bool(_reveals["tabs"])
	if seats_up != _seats_up or tabs_up != _tabs_up:
		var anim := _slots_known and mode == "main" and ((seats_up and not _seats_up) or (tabs_up and not _tabs_up))
		_seats_up = seats_up
		_tabs_up = tabs_up
		_apply_slots(anim)
		chat.relayout()
		dossier.relayout()
		court.relayout()
		_publish_display()
	_slots_known = true
	ticker.visible = main and bool(_reveals["counter"])
	ticker.set_cta(main and state.evolutions >= 0 and Coalition.gate_open(state) and Coalition.active())
	if bool(_reveals["seats"]):
		var si := Coalition.seat_info(state)
		top_bar.set_seats(int(si["effective"]), int(si["gateSeats"]), _blackout())
	top_bar.set_muted(not bool(settings.get("sfx", true)) and not bool(settings.get("music", true)))


func _blackout() -> bool:
	return Calendar.active() and Calendar.is_blackout(SaveStore.now_ms())


## The band is clear for a Suitcase (ux/ftue.md: stage_unobstructed()).
func stage_unobstructed() -> bool:
	return mode == "main" and not overlays.is_open() and not tx.running and not _tx_locked and not chat.is_open() \
		and not dossier.is_open() and not court.covers_band() and not undo_visible()


## The HTML disclaimer faded out (shell.html sets window.mbHandoffDone): the FTUE clocks start,
## and on a first launch the disclaimer's sound choice becomes the settings.
func _poll_handoff() -> void:
	if ftue.handoff_ms > 0.0:
		return
	if not OS.has_feature("web"):
		ftue.handoff_ms = maxf(1.0, _now)
		return
	var v: Variant = JavaScriptBridge.eval("window.mbHandoffDone || 0", true)
	if v == null or float(v) <= 0.0:
		return
	ftue.handoff_ms = float(v)
	if not _settings_existed:
		var snd: Variant = JavaScriptBridge.eval("window.odSound || ''", true)
		if str(snd) == "off" or str(snd) == "on":
			var on := str(snd) == "on"
			settings["sfx"] = on
			settings["music"] = on
			store.save_settings(settings)
			_settings_existed = true
			_apply_settings()


## v2 automation from Thumb Perks: auto-taps, the Banana Butler and the Golden Net.
func _run_automation(dt: float, modal: bool) -> void:
	var rate := Meta.auto_tap_rate(state) * float(_dev["speed"])
	if rate > 0.0:
		_auto_tap_acc += rate * dt / 1000.0
		while _auto_tap_acc >= 1.0:
			_auto_tap_acc -= 1.0
			var r := Economy.tap(state)
			bb.tap(r["crit"])
			floaters.spawn(L.magician_hit().get_center().x + randf_range(-60, 60), L.magician_hit().get_center().y - 40.0,
				Strings.s("FLOATER_CRIT" if r["crit"] else "FLOATER", {"n": Fmt.amount(float(r["value"]))}), r["crit"], state.buff_tap_frenzy > 0.0)
	_butler_ms += dt * float(_dev["speed"])
	if _butler_ms >= 1000.0:
		_butler_ms = 0.0
		var id := Meta.auto_buy(state)
		if id != "":
			diorama.sync(state.owned, true)
			_check_milestones(id)
	if Meta.auto_catch(state) and golden.on_screen() and not modal and golden.age_ms() > 900.0:
		_catch_golden()


## Trophies and all-producer milestones (throttled to 4 checks a second).
func _check_meta() -> void:
	for id in Meta.check_achievements(state, d):
		var a := Meta.achievement(id)
		ticker.enqueue("milestone", Strings.s("F_TROPHY", {"NAME": a["name"]}))
		_audio("achievement")
		_haptic(30)
		state.ui["unseenTrophies"] = int(state.ui.get("unseenTrophies", 0)) + 1
		fx_stage.play("purchaseConfetti", 64.0, 224.0, "bulk")
		_mark_dirty()
	var all_m := Meta.all_producers_mult(state)
	if all_m > _all_milestone_seen + 1e-9:
		_all_milestone_seen = all_m
		ticker.enqueue("milestone", Strings.s("F_ALL_MILESTONE", {"n": Meta.min_owned(state)}))
		_audio("milestone")
	if state.bananas >= 0.0 and state.evolutions >= 1 and not state.ui.get("perksHinted", false) and Meta.can_buy_any_perk(state):
		state.ui["perksHinted"] = true
		ticker.enqueue("ftue", Strings.s("F_PERKS_HINT"))


## A producer crossing a per-tier milestone: a ticker line and a sound.
func _check_milestones(id: String) -> void:
	var m := Meta.milestone_mult(state.owned_of(id))
	if m > float(_milestone_seen.get(id, 1.0)) + 1e-9:
		_milestone_seen[id] = m
		ticker.enqueue("milestone", Strings.s("F_MILESTONE", {"NAME": Strings.producer_name(id), "n": state.owned_of(id)}))
		_audio("milestone")
		_haptic(25)


func _seed_milestones() -> void:
	_milestone_seen.clear()
	for id in Content.producer_ids():
		_milestone_seen[id] = Meta.milestone_mult(state.owned_of(id))
	_all_milestone_seen = Meta.all_producers_mult(state)


## Until the player sets Reduced Motion themselves, it follows the OS setting live (web: the
## prefers-reduced-motion media query, checked every 2 s).
func _follow_os_motion(dt: float) -> void:
	if not OS.has_feature("web") or not settings.get("reducedMotionFollowsOs", true):
		return
	_os_motion_ms += dt
	if _os_motion_ms < 2000.0:
		return
	_os_motion_ms = 0.0
	var os_rm := _os_reduced_motion()
	if os_rm != bool(settings["reducedMotion"]):
		settings["reducedMotion"] = os_rm
		store.save_settings(settings)
		_apply_settings()


func _step_economy(dt_sec: float, modal: bool) -> void:
	var ev := Economy.tick(state, dt_sec, d)
	# the politics sim (sim/politics.gd): calendar, coalition, court, events. C1's controller half
	# (ux/ftue.md): no modal, the last purchase ≥ 2 s ago, no toast showing, Dubi not speaking.
	var ping := not modal and _now - _last_buy_ms >= 2000.0 and toasts.idle() and not toasts.saying()
	for pe: Variant in Politics.tick(state, dt_sec, d, politics_ctx(SaveStore.now_ms(), ping, Time.get_datetime_dict_from_system())):
		if pe is Dictionary:
			_on_politics_event(pe)
	if ev["frenzyEnded"]:
		_audio("frenzyEnd")
	if ev["tapFrenzyEnded"]:
		_audio("tapFrenzyEnd")
	_on_spins_ended(ev["spinsEnded"])
	# ux/ftue.md S1: no Suitcase before two sources; the first flight is forced while tapping
	var allowed := bool(_reveals.get("suitcase", true)) and stage_unobstructed()
	if allowed and not golden.is_visible_state() and Ftue.s1_due(state, _now - _last_tap_ms):
		_spawn_suitcase()
		Economy.schedule_next_golden(state)
	elif not modal and allowed and Economy.tick_golden_timer(state, dt_sec):
		Economy.schedule_next_golden(state)
		if not golden.is_visible_state():
			_spawn_suitcase()


## A timed spin ran out (S02, S07, S10, S12 ...): before this only its buff chip vanished. A
## toast names it (TOAST_SPIN_END) and the Audio hears `spinEnd` with the spin id. The cue-spec
## names no cue for it (frenzy / spin ends are silent by design, §4), so the Audio drops it unless
## the Audio Director adds one; the hook is there.
func _on_spins_ended(ids: Array) -> void:
	for id: Variant in ids:
		toasts.show_toast(spin_end_text(str(id)))
		_audio("spinEnd", str(id))


static func spin_end_text(id: String) -> String:
	return Strings.s("TOAST_SPIN_END", {"NAME": Strings.upgrade_name(id)})


## The Politics.tick context (sim/README "Controller wiring"): the device's local hour and weekday
## (the night trophy "לילה לבן", the Pink Front drum line), the resolved clock and the ping gate.
static func politics_ctx(now_ms: float, allow_ping: bool, local: Dictionary) -> Dictionary:
	return {"nowMs": now_ms, "allowPing": allow_ping, "hour": int(local.get("hour", 0)), "weekday": int(local.get("weekday", 0))}


## Politics events the engine shows or voices this wave. The Audio runtime (another developer)
## subscribes by name: courtSummons, courtStart, courtEnd(reason) (motion/state-graph-magician §2.1).
func _on_politics_event(e: Dictionary) -> void:
	chat.on_politics_event(e)   # chat pings, toasts, chatLeft / ultimatumZero
	court.on_politics_event(e)  # the court card and chip (the card now carries the summons text)
	thermo.on_politics_event(e) # the summons gulp
	match String(e.get("ev", "")):
		"summons":
			_audio("courtSummons")
			if Leaders.has_court():
				bb.court_flinch()   # the summons flinch (motion/state-graph-magician.md §1.3)
		"courtStart":
			_audio("courtStart")
		"courtEnd":
			# testified | served (the sim's tick) | postponed (CourtView routes postpone()'s events
			# on the stamp's impact frame; the Audio plays gavelWeak for it)
			var reason := String(e.get("reason", "testified"))
			_audio("courtEnd", reason)
			if reason != "postponed":
				toasts.show_toast(LeaderUi.s("TOAST_COURT_END"))
		"transfer":
			_audio("transfer")


## The court day's stage FX from the Magician (BigBanana.on_court_fx): the zip's dust at his feet, the
## hat's coins (fewer than his: the ×0.5 income, shown) and the rabbit's cue on a hat crit.
func _on_court_fx(kind: String, at: Vector2, n: int) -> void:
	match kind:
		"dust":
			fx_stage.play("dustPuff", at.x, at.y)
		"coins":
			prop_fx.coins(at, n)
		"rabbit":
			_audio("rabbit")


func _spawn_suitcase() -> void:
	golden.first_flight = state.golden_caught_lifetime == 0
	golden.hover_mid = state.golden_caught_lifetime == 0 and int(float(state.stats.get("goldenMissed", 0.0))) >= 3
	golden.spawn()
	_audio("goldenSpawn", clampf(golden.gx / float(L.W), 0.0, 1.0))   # the zipper's pan


func _check_buff_edges() -> void:
	var fr := state.buff_frenzy > 0.0
	var tf := state.buff_tap_frenzy > 0.0
	bb.set_aura("tapFrenzy" if tf else ("frenzy" if fr else "plain"))
	diorama.set_frenzy(fr)
	if tf != bool(_prev_buffs["tapFrenzy"]):
		diorama.set_tap_frenzy(tf)
	buffs.set_frenzy(fr)
	_audio_call("set_music_state", ["frenzy" if (fr or tf) else ("evolved" if state.evolutions > 0 else "base")])
	_prev_buffs = {"frenzy": fr, "tapFrenzy": tf}


## Milestone headlines fire once ever (headlinesSeen persists) and pre-empt ambient ticker text.
func _check_headlines() -> void:
	for h: Dictionary in Leaders.headlines(state):   # the round's: Bibi's own leave, the kit's join
		if state.headlines_seen.has(h["id"]):
			continue
		var tr: Dictionary = h["trigger"]
		var v: Variant = tr.get("value", 0)
		var hit := false
		var lh: Variant = Leaders.headline_hit(state, tr)
		if lh != null:
			hit = bool(lh)
		match String(tr["type"]):
			"tapsLifetime":
				hit = state.taps_lifetime >= int(v)
			"allTimeBananas":
				hit = state.all_time_bananas >= float(v)
			"critsLifetime":
				hit = state.crits_lifetime >= int(v)
			"goldenCaughtLifetime":
				hit = state.golden_caught_lifetime >= int(v)
			"evolutions":
				hit = state.evolutions >= int(v)
			"firstOwned":
				hit = state.owned_of(str(v)) >= 1
			"stat":
				hit = stat(String(tr.get("key", ""))) >= float(v)
		if hit:
			state.headlines_seen.append(h["id"])
			ticker.enqueue("milestone", h["text"])


## A counter by name (headline `stat` triggers): GameState.stats first, then the politics
## sim's own counters (partnersPaid / demandsPaid = paid demands, courtDays, pardons, aideDrops).
func stat(key: String) -> float:
	if state.stats.has(key):
		return float(state.stats[key])
	match key:
		"partnersPaid", "demandsPaid":
			return float(state.coalition.get("paidLifetime", 0))
		"courtDays":
			return float(state.investigation.get("courtDays", 0))
		"pardonRequests":
			return float(state.investigation.get("pardons", 0))
		"aideDrops":
			return float(state.investigation.get("aideDrops", 0))
	return 0.0


func _check_reveals() -> void:
	if not state.ui.get("buyModeRevealed", false):
		var any10 := state.evolutions >= 1
		for id in Content.producer_ids():
			if state.owned_of(id) >= 10:
				any10 = true
		if any10:
			state.ui["buyModeRevealed"] = true
			ticker.enqueue("ftue", Strings.s("F8_BULK"))
	if Economy.evolve_visible(state) and not state.ui.get("evolveRevealed", false):
		state.ui["evolveRevealed"] = true


func _refresh_all(dt: float) -> void:
	var main := mode == "main"
	top_bar.set_bank(state.bananas)
	top_bar.set_bps(d.bps, d.frenzy_mult, d.tap_pour_sec > 0.0)   # S07 pours the income into taps (HUD_BPS_POUR)
	top_bar.set_thumbs(state.thumbs_owned, d.prestige_mult)
	var vis := Economy.evolve_visible(state) and main
	var reveal := vis and not _evolve_was_visible
	var ready_edge := d.evolve_enabled and not state.evolve_ready_announced and vis
	top_bar.set_evolve(vis, d.pending, d.needed, d.evolve_enabled, reveal, ready_edge)
	if reveal:
		_audio("producerReveal")
	if ready_edge:
		state.evolve_ready_announced = true
		_audio("evolveReady")
	_evolve_was_visible = vis
	top_bar.set_evolve_badge(Ftue.badge_on(state) and vis)
	buffs.update_chip(state.buff_frenzy, state.buff_tap_frenzy, main, Spins.active_effects(state))
	buffs.update_view(dt, main)
	shop.refresh(state, dt, main and dt > 0.0, d)


# ================================================================== input boundary

func _gameplay_input() -> bool:
	return mode == "main" and not overlays.is_open() and not tx.running and not _tx_locked and overlays.now_ms() >= overlays.input_locked_until


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventScreenTouch:
		var t := e as InputEventScreenTouch
		if t.pressed:
			_pointer_down(t.index, t.position)
		else:
			_pointer_up(t.index, t.position)
	elif e is InputEventScreenDrag:
		var dr := e as InputEventScreenDrag
		_pointer_move(dr.index, dr.position)
	elif e is InputEventMouseButton:
		var mb := e as InputEventMouseButton
		if mb.device == InputEvent.DEVICE_ID_EMULATION:
			return
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_pointer_down(-1, mb.position)
			else:
				_pointer_up(-1, mb.position)
		elif mb.pressed and (mb.button_index == MOUSE_BUTTON_WHEEL_UP or mb.button_index == MOUSE_BUTTON_WHEEL_DOWN):
			var sp := _in_stage(mb.position)
			if overlays.is_open():
				overlays.wheel(_in_modal(mb.position), -1.0 if mb.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0)
			elif chat.is_open():
				chat.wheel(-1.0 if mb.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0)
			elif dossier.is_open():
				dossier.wheel(-1.0 if mb.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0)
			elif _gameplay_input() and shop.in_list(sp):
				shop.wheel(-1.0 if mb.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0)
	elif e is InputEventMouseMotion:
		var mm := e as InputEventMouseMotion
		if mm.device == InputEvent.DEVICE_ID_EMULATION:
			return
		_pointer_move(-1, mm.position)
		_update_hover(mm.position)
	elif e is InputEventKey:
		var k := e as InputEventKey
		if k.pressed and not k.echo:
			_on_key(k)
			get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if shop == null:
		return   # a lifecycle notification can arrive before _ready has built the scene
	match what:
		NOTIFICATION_WM_GO_BACK_REQUEST:
			# Android back: the top layer closes (the same rule as the browser's back, R9); with
			# nothing open it opens settings, as before
			if not back_layer() and mode == "main" and _gameplay_input():
				_open_settings()
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT:
			_flush_save()
			shop.cancel_press()
			_presses.clear()
			_audio_call("set_paused", [true])
		NOTIFICATION_APPLICATION_RESUMED, NOTIFICATION_APPLICATION_FOCUS_IN:
			_audio_call("set_paused", [false])
		NOTIFICATION_WM_CLOSE_REQUEST:
			_flush_save()


func _pointer_down(idx: int, p: Vector2) -> void:
	_first_input = true
	_keyboard_active = false
	ftue.on_input()
	if tx.running or _tx_locked:
		return
	if overlays.is_open():
		overlays.pointer_down(_in_modal(p))
		_presses[idx] = {"kind": "overlay"}
		return
	if overlays.now_ms() < overlays.input_locked_until:
		return
	var sp := _in_stage(p)
	var tp := _in_top(p)
	var lp := _in_lower(p)
	if mode == "pick":
		# the disclaimer is HTML over the canvas; until it hands off, nothing here is live
		if ftue.handoff_ms <= 0.0:
			return
		picker.pointer_down(_in_pick(p))
		_presses[idx] = {"kind": "pick"}
		return
	if undo_visible() and _undo_btn.contains(sp):
		_undo_btn.down()
		_presses[idx] = {"kind": "undo"}
		return
	if mode == "title":
		# the disclaimer is HTML over the canvas; until it hands off, nothing here is live
		if ftue.handoff_ms <= 0.0:
			return
		var on_hat := Ui.in_rect(bb.hit_rect(), sp)
		if on_hat:
			_start_from_title(sp, true)
		return
	if cottage.contains(tp):
		_presses[idx] = {"kind": "cottage"}
		return
	if top_bar.gear_contains(tp):
		_presses[idx] = {"kind": "gear"}
		return
	if top_bar.mute_contains(tp):
		_presses[idx] = {"kind": "mute"}
		return
	if top_bar.seats_contains(tp):
		_presses[idx] = {"kind": "seats"}   # rtl-map §3: the whole Row B opens T3
		return
	# the court card sits over everything in `_lower`; T4 then T3 cover the stage
	if court.pointer_down(lp):
		_presses[idx] = {"kind": "court"}
		return
	if dossier.pointer_down(lp):
		_presses[idx] = {"kind": "dossier"}
		return
	if chat.pointer_down(lp):
		_presses[idx] = {"kind": "chat"}
		return
	if thermo.is_shown() and Ui.in_rect(thermo.hit_rect(), sp):
		_presses[idx] = {"kind": "thermo"}   # rtl-map §4: tap → T4
		return
	if golden.hit_test(sp):
		_catch_golden()
		return
	# mobile-first §3.4: during a tap burst (the last leader tap < 1 s ago) a toast takes no tap, so
	# a toast over the leader's head never eats the rapid taps (it stays visible)
	if not tap_burst() and toasts.tap(sp):
		return
	if Ui.in_rect(bb.hit_rect(), sp):
		_handle_tap(sp)
		return
	if ticker.visible and ticker.cta_on() and ticker.cta.contains(lp):
		ticker.cta.down()
		_presses[idx] = {"kind": "cta"}
		return
	if shop.visible and shop.tabs_down(lp):
		_presses[idx] = {"kind": "tab"}
		return
	if shop.in_list(lp):
		shop.cancel_press()
		shop.list_down(lp, state)
		_presses[idx] = {"kind": "list"}
		return
	if sp.y >= float(L.STAGE["y"]) and sp.y < L.stage_bottom():
		ftue.on_stage_miss(state)


func _pointer_move(idx: int, p: Vector2) -> void:
	var pr: Dictionary = _presses.get(idx, {})
	if pr.get("kind", "") == "list":
		shop.list_move(_in_lower(p))
	elif pr.get("kind", "") == "overlay":
		overlays.pointer_move(_in_modal(p))
	elif pr.get("kind", "") == "chat":
		chat.pointer_move(_in_lower(p))
	elif pr.get("kind", "") == "dossier":
		dossier.pointer_move(_in_lower(p))
	elif pr.get("kind", "") == "pick":
		picker.pointer_move(_in_pick(p))


func _pointer_up(idx: int, p: Vector2) -> void:
	var pr: Dictionary = _presses.get(idx, {})
	_presses.erase(idx)
	if pr.is_empty():
		return
	var tp := _in_top(p)
	var lp := _in_lower(p)
	match String(pr["kind"]):
		"pick":
			picker.pointer_up(_in_pick(p))
		"undo":
			var inside := undo_visible() and _undo_btn.contains(_in_stage(p))
			_undo_btn.up(inside)
		"overlay":
			overlays.pointer_up(_in_modal(p))
		"list":
			shop.list_up(lp, state)
		"chat":
			chat.pointer_up(lp)
		"court":
			court.pointer_up(lp)
		"dossier":
			dossier.pointer_up(lp)
		"thermo":
			if Ui.in_rect(thermo.hit_rect(), _in_stage(p)) and _gameplay_input():
				dossier.open()
		"seats":
			if top_bar.seats_contains(tp) and _gameplay_input():
				chat.open()
		"tab":
			shop.tab_up(lp)
		"cta":
			ticker.cta.up(ticker.cta.contains(lp) and _gameplay_input())
			if ticker.cta.contains(lp) and _gameplay_input():
				_open_evolution()
		"gear":
			if top_bar.gear_contains(tp) and _gameplay_input():
				_open_settings()
		"cottage":
			if cottage.contains(tp) and _gameplay_input():
				cottage.tap()
		"mute":
			if top_bar.mute_contains(tp) and _gameplay_input():
				_toggle_mute()


## 🔊 in Row A: one switch for both sound settings (the settings sheet keeps them separate).
func _toggle_mute() -> void:
	var on := not (bool(settings.get("sfx", true)) or bool(settings.get("music", true)))
	settings["sfx"] = on
	settings["music"] = on
	store.save_settings(settings)
	_apply_settings()
	_audio("uiToggle", on)


func _update_hover(p: Vector2) -> void:
	var pointer := false
	if overlays.is_open():
		pointer = overlays.hover(_in_modal(p))
	elif mode == "pick":
		pointer = picker.hover(_in_pick(p))
	elif mode == "title":
		pointer = Ui.in_rect(bb.hit_rect(), _in_stage(p))
	elif _gameplay_input():
		var sp := _in_stage(p)
		var tp := _in_top(p)
		var lp := _in_lower(p)
		var on_golden := golden.hit_test(sp)
		var on_banana := not on_golden and Ui.in_rect(bb.hit_rect(), sp)
		_set_hover_banana(on_banana)
		pointer = on_golden or on_banana or top_bar.gear_contains(tp) or top_bar.mute_contains(tp) or cottage.contains(tp) or shop.in_list(lp) \
			or (shop.visible and Ui.in_rect(Rect2(0, L.tabs_y(), L.cw, L.TABS_H), lp)) or (ticker.cta_on() and ticker.cta.contains(lp))
	if not _gameplay_input():
		_set_hover_banana(false)
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND if pointer else Input.CURSOR_ARROW)


## mobile-first §3.4 / ftue §3.1: a tap burst is on while the last leader tap is < 1 s old.
func tap_burst() -> bool:
	return _now - _last_tap_ms < 1000.0


func _set_hover_banana(on: bool) -> void:
	if _hover_banana == on:
		return
	_hover_banana = on
	bb.set_hover(on)


func _on_key(e: InputEventKey) -> void:
	_first_input = true
	if e.keycode in [KEY_TAB, KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT, KEY_ENTER, KEY_SPACE, KEY_ESCAPE]:
		_keyboard_active = true
	ftue.on_input()
	if tx.running or _tx_locked:
		return
	if overlays.is_open():
		overlays.key(e)
		return
	if mode == "pick":
		if ftue.handoff_ms > 0.0:
			picker.key(e)
		return
	if e.keycode == KEY_U and undo_visible():
		_undo_pick()
		return
	if mode == "title":
		if (e.keycode == KEY_SPACE or e.keycode == KEY_ENTER) and ftue.handoff_ms > 0.0:
			_start_from_title(L.magician_hit().get_center(), true)   # ux/ftue.md §5: counts as tap 1
		return
	if overlays.now_ms() < overlays.input_locked_until:
		return
	# rtl-map §6.2 / ux/ftue.md §5: Space taps, S catches the Suitcase, 1-4 = tab slots (reading
	# order), E the election, B the buy mode, M mute, Esc settings
	match e.keycode:
		KEY_SPACE, KEY_ENTER:
			if not chat.is_open() and not dossier.is_open():   # rtl-map §6.3: a tall tab covers the Magician
				_handle_tap(L.magician_hit().get_center())
		KEY_S:
			if golden.on_screen() and not chat.is_open() and not dossier.is_open():
				_catch_golden()
		KEY_ESCAPE:
			# the top layer first (the expanded court card, then T3/T4); nothing open: settings
			if not back_layer():
				_open_settings()
		KEY_E:
			if ticker.cta_on() or Economy.evolve_visible(state):
				_open_evolution()
		KEY_M:
			_toggle_mute()
		KEY_B:
			if state.ui.get("buyModeRevealed", false):
				_cycle_buy_mode()
		KEY_1, KEY_2, KEY_3, KEY_4:
			shop.switch_slot(e.keycode - KEY_1 + 1)


# ================================================================== verbs

## The core verb (mechanic rules 1-2): award on pointer-down, the global 16/s cap, full juice at f0.
func _handle_tap(at: Vector2) -> void:
	if not _limiter.try_register(Time.get_ticks_msec()):
		return
	var r := Economy.tap(state)
	_last_tap_ms = _now
	var crit: bool = r["crit"]
	if state.buff_tap_frenzy > 0.0:
		_tap_frenzy_taps += 1
		state.stats["bestTapFrenzyTaps"] = maxf(float(state.stats.get("bestTapFrenzyTaps", 0.0)), float(_tap_frenzy_taps))
	else:
		_tap_frenzy_taps = 0
	bb.tap(crit, bool(r.get("paused", false)))
	_coin_batch += 1
	_audio("tapCrit" if crit else "tap")
	if state.taps_lifetime == 1:
		# after the tap, which opens the audio gate: the Audio holds Dubi's first line until the
		# motif's musicalSeconds (O-A3); the ticker/toast line stays at f0 (ux/ftue.md H1)
		_audio("babble", _first_squawk())
	elif Leaders.active() and Leaders.stat(state, Leaders.current(state), "taps") == 1.0:
		# ux/ftue.md H1L: a leader's first laugh, the first tap of their first round (D31)
		toasts.say(LeaderUi.firsttap(), L.magician_feet() - Vector2(0, 380), 1600.0)
		_audio("babble", _first_squawk())
	top_bar.set_bank(state.bananas)
	top_bar.pop_bank()
	var n := Fmt.amount(float(r["value"]))
	floaters.spawn(at.x, at.y, Strings.s("FLOATER_CRIT" if crit else "FLOATER", {"n": n}), crit, state.buff_tap_frenzy > 0.0)
	if crit and not LeaderUi.is_default() and str(LeaderUi.tap()["critName"]) != "":
		floaters.spawn(at.x, at.y - 56.0, str(LeaderUi.tap()["critName"]), true, false)   # spec §5.2: the crit word
	if r.get("tap7", false) == true:
		var t7 := str(Leaders.rule(Leaders.current(state)).get("copy", {}).get("tap7", ""))
		if t7 != "":
			floaters.spawn(at.x, at.y - 56.0, t7, true, false)   # Eisenkot's tap 7: "בלי קסמים. רק ישר."
			var ca := str(LeaderUi.tap()["critAnim"])
			if bb.hero != null and bb.hero.has_anim(ca):
				bb.hero.play(ca, true, 1)   # his react plays the beat the rabbit would
	if bb.hero == null:
		fx_stage.play("critBurst" if crit else "tapChips", at.x, at.y)
	elif crit:
		fx_stage.play("critBurst", at.x, at.y)   # the coins come from the strip's own "coins" frame
	if crit:
		_haptic(20)
		if not settings["reducedMotion"]:
			_start_shake(float(Tune.T["critShakePx"]), float(Tune.T["critShakeMs"]))
	ftue.on_registered_action()


## Dubi's first-tap line for the round's leader: the Audio's own lookup (v1.3 squawk_text, the
## text it babbles and contours), else the view's (LeaderUi.firsttap: the same content).
func _first_squawk() -> String:
	var a := get_node_or_null("/root/Audio")
	if a != null and a.has_method("squawk_text") and Leaders.active():
		var t := str(a.call("squawk_text", Leaders.current(state), "firsttap"))
		if t != "":
			return t
	return LeaderUi.firsttap()


## S10's running income bonus as an LTR token ("+15%").
static func flight_label(pct: float) -> String:
	return "\u2066+%d%%\u2069" % int(roundf(pct))


func _catch_golden() -> void:
	var gp := Vector2(golden.gx, golden.gy)
	if not golden.catch_it():
		return
	var id := Economy.roll_golden_outcome()
	var kind := Content.outcome_type(id)   # instant | bpsFrenzy | tapFrenzy (content data)
	var flight0 := Spins.flight_pct(state)
	var award := Economy.apply_golden(state, id)
	var flight1 := Spins.flight_pct(state)
	if flight1 > flight0:
		# S10: this flight's income bonus, as the running total (ux FLOATER_FLIGHT)
		floaters.spawn(gp.x, gp.y - 64.0, Strings.s("FLOATER_FLIGHT", {"pct": int(roundf(flight1))}), false, false)
	# The audio cue variants keep the fork's names (cues.json goldenCatch bunch/frenzy/tapFrenzy).
	_audio("goldenCatch", {"instant": "bunch", "bpsFrenzy": "frenzy", "tapFrenzy": "tapFrenzy"}[kind])
	if kind == "bpsFrenzy":
		_audio("frenzyStart")
	elif kind == "tapFrenzy":
		_audio("tapFrenzyStart")
	fx_stage.play("goldenCatch", gp.x, gp.y)
	_haptic(40)
	if not settings["reducedMotion"]:
		_start_shake(float(Tune.T["goldenCatchShakePx"]), float(Tune.T["goldenCatchShakeMs"]))
	var o := Content.outcome(id)
	match kind:
		"instant":
			buffs.show_banner(Strings.s("BANNER_BUNCH", {"n": Fmt.amount(award)}))
			top_bar.roll_bank(award)
			top_bar.big_gain("bunch")
		"bpsFrenzy":
			if Leaders.active():   # rtl-map §4.3: the round's frenzy banner (Bibi's is the same text)
				buffs.show_banner(Strings.s("BANNER_FRENZY_LEADER", {"banner": str(LeaderUi.tap()["frenzyBanner"]), "mult": int(o.get("mult", 1))}))
			else:
				buffs.show_banner(Strings.s("BANNER_FRENZY", {"mult": int(o.get("mult", 1))}))
		_:
			buffs.show_banner(Strings.s("BANNER_TAPFRENZY", {"mult": int(o.get("mult", 1))}))
	ftue.on_golden_caught(state)
	_mark_dirty()


## The Magician's strip events (TA loader contract §4). `at` is the hat's mouth on that frame.
## Unknown names are a no-op: the set grows with the cast.
func _on_hero_event(ev: String, at: Vector2) -> void:
	match ev:
		"coins":
			# motion/event-markers.md: min(base + batch - 1, cap), batch = taps since the last burst
			var crit := bb._state == "crit"
			var base := int(Tune.MC["critCoinBase" if crit else "coinBurstBase"])
			var cap := int(Tune.MC["critCoinCap" if crit else "coinBurstCap"])
			prop_fx.coins(at, mini(base + maxi(1, _coin_batch) - 1, cap))
			_coin_batch = 0
		"rabbit":
			prop_fx.rabbit(at)
			_audio("rabbit")   # the Audio's rabbitCrit on the strip's own frame
		_:
			# a leader's react (spec §5.2, CONTRACT §4c): its event (whoosh / shout / no / land) is
			# the crit's frame. The coins burst there, and the Audio plays crit_for(leader)'s cue
			# (spec §9.5, audio/od/cue-spec.md §4.2).
			if not LeaderUi.is_default() and ev == str(LeaderUi.tap().get("critEvent", "")) and bb._state == "crit":
				prop_fx.coins(at, int(Tune.MC["critCoinBase"]))
				_audio("heroEvent", ev)   # Audio v1.3 (cue-spec §4.2): the leader's crit cue on its frame
			# "sting" stays silent (cue-spec §5)


func _on_buy_producer(id: String, is_repeat: bool, result: Array) -> void:
	if not _gameplay_input() and not is_repeat:
		return
	if overlays.is_open() or _tx_locked:
		return   # v2: hold-to-buy never buys behind a modal
	var q := Economy.buy_producer(state, id)
	if q.is_empty():
		return
	result[0] = int(q["qty"])
	_last_buy_ms = _now
	_audio("buyBulk" if int(q["qty"]) > 1 else "buy")
	_haptic(10)
	var k := shop.row_index_of(state, "producer", id)
	var ip := shop.icon_pos(k)
	fx_ui.play("purchaseConfetti", ip.x, ip.y, "bulk" if int(q["qty"]) > 1 else "")
	var before := state.owned_of(id) - int(q["qty"])
	diorama.sync(state.owned, true)
	_check_milestones(id)
	if before >= 25:
		diorama.cheer(id)
	ftue.on_buy_producer()
	_mark_dirty()


## The ticker flavor of a spin just bought: a line's level carries its own line (S08 levels[n].flavor).
static func spin_flavor(s: GameState, id: String) -> String:
	var u := Content.upgrade(id)
	var lv := Spins.levels_of(u)
	var n := Spins.level(s, id)
	if Spins.kind(u) == "line" and n >= 1 and n <= lv.size() and lv[n - 1] is Dictionary and (lv[n - 1] as Dictionary).has("flavor"):
		return String(lv[n - 1]["flavor"])
	var sk := LeaderUi.spin_word(id, "flavor")   # the round's leader skin (spec §5.4)
	return sk if sk != "" else String(u.get("flavor", ""))


func _on_buy_upgrade(id: String, result: Array) -> void:
	if not _gameplay_input():
		return
	if not Economy.buy_upgrade(state, id):
		return
	result[0] = true
	_last_buy_ms = _now
	_audio("upgradeBuy")
	_haptic(15)
	var k := shop.row_index_of(state, "upgrade", id)
	var ip := shop.icon_pos(maxi(0, k))
	fx_ui.play("purchaseConfetti", ip.x, ip.y, "upgrade")
	ticker.enqueue("flavor", Strings.s("F_UPGRADE_FLAVOR", {"UPGRADE_NAME": Strings.upgrade_name(id), "FLAVOR": spin_flavor(state, id)}))
	ftue.on_buy_upgrade()
	_mark_dirty()


func _cycle_buy_mode() -> void:
	var modes: Array = Content.data()["buyModes"]
	var cur: Variant = state.buy_mode
	var i := 0
	for j in modes.size():
		var m: Variant = modes[j]
		if (m is String and cur is String and m == cur) or ((m is float or m is int) and (cur is int or cur is float) and int(m) == int(cur)):
			i = j
	var nxt: Variant = modes[(i + 1) % modes.size()]
	state.buy_mode = nxt if nxt is String else int(nxt)
	_audio("buyModeCycle", state.buy_mode)


func _on_tab_switched(t: String) -> void:
	chat.close()   # a list tab replaces the tall tab
	dossier.close()
	state.ui["tabsTouched"] = true
	_audio("uiClick")
	ftue.on_tab_selected(state, t)


# ================================================================== overlays

func _open_settings() -> void:
	if overlays.is_open():
		return
	_audio("panelOpen")
	overlays.request(func() -> Overlay:
		var o := Overlays.SettingsOverlay.new()
		o.setup(self, overlays)
		o.open_reset = _open_reset
		return o.build())
	ftue.on_overlay_opened(state, "SETTINGS", false)


## The narrator's card for the evolution just reached (once per evolution; replay in the Book).
func _show_story_beat() -> void:
	# leader select: the beat of the leader just played (Story.flash: "beat_<leader>_<n>"; Bibi's
	# ids are the shipped ones)
	var fl := Story.flash(state) if Leaders.active() else {}
	var bid := str(fl["id"]) if not fl.is_empty() and int(fl["n"]) >= 1 else Story.beat_id(state.evolutions)
	if state.story_seen.has(bid):
		return
	state.story_seen.append(bid)
	show_flash(state.evolutions)


## O3b, Dubi's news flash for round n (ui/views/view_flash.gd; it sends its own storyCard +
## babble). `archive` = a replay from T4 (SYS_CLOSE only, no word-salad roll).
func show_flash(n: int, archive := false) -> void:
	overlays.request(func() -> Overlay:
		var o := FlashCard.new()
		o.setup(self, overlays)
		o.evolutions = n
		o.archive = archive
		return o.build())


func stop_babble() -> void:
	_audio_call("stop_babble", [])


func _open_perks() -> void:
	if overlays.is_open():
		return
	_audio("panelOpen")
	overlays.request(func() -> Overlay:
		var o := Overlays.PerksOverlay.new()
		o.setup(self, overlays)
		return o.build())


func _open_book() -> void:
	if overlays.is_open():
		return
	_audio("panelOpen")
	state.ui["unseenTrophies"] = 0
	overlays.request(func() -> Overlay:
		var o := Overlays.BookOverlay.new()
		o.setup(self, overlays)
		return o.build())


func book_tabs() -> Array:
	return ["trophies", "stats", "story"]


func buy_perk(id: String) -> void:
	if Meta.buy_perk(state, id):
		_audio("perkBuy")
		_haptic(20)
		ticker.enqueue("flavor", Strings.s("F_PERK_BOUGHT", {"NAME": Meta.perk(id)["name"]}))
		_check_meta()
		_save_now()
	else:
		_audio("cantAfford")


func haptics_available() -> bool:
	return OS.has_feature("mobile") or OS.has_feature("web_android")


func cycle_notation() -> void:
	var order := ["letters", "scientific", "engineering"]
	var i := order.find(String(settings.get("notation", "letters")))
	set_setting("notation", order[(i + 1) % order.size()])
	_audio("uiToggle")


func export_save() -> void:
	_flush_save()
	DisplayServer.clipboard_set(SaveStore.export_code(state))
	ticker.enqueue("ftue", Strings.s("F_EXPORTED"))
	_audio("uiClick")


func import_save() -> void:
	var code := ""
	if OS.has_feature("web"):
		var ask := Strings.s("IMP_PROMPT") if Strings.has("IMP_PROMPT") else "הדביקו את קוד השמירה (HK1:…)"
		var v: Variant = JavaScriptBridge.eval("window.prompt(%s) || ''" % JSON.stringify(ask), true)
		code = str(v) if v != null else ""
	else:
		code = DisplayServer.clipboard_get()
	var r := SaveStore.parse(code)
	if r["kind"] != "ok":
		ticker.enqueue("ftue", Strings.s("F_IMPORT_BAD"))
		_audio("cantAfford")
		return
	var loaded: GameState = r["state"]
	overlays.request(func() -> Overlay:
		var o := Overlays.ConfirmOverlay.new()
		o.setup(self, overlays)
		o.title = Strings.s("IMP_TITLE")
		o.lines = [Strings.s("IMP_BODY_1"), Strings.s("IMP_BODY_2"), Strings.s("IMP_BODY_3")]
		o.confirm_label = Strings.s("IMP_CONFIRM")
		o.on_confirm = func() -> void: _apply_import(loaded)
		return o.build(), true)


func _apply_import(loaded: GameState) -> void:
	overlays.close_all()
	state = loaded
	d = Economy.derive(state)
	golden.clear()
	diorama.clear_all()
	diorama.sync(state.owned, false)
	buffs.clear()
	floaters.clear()
	prop_fx.clear()
	shop.reset_run()
	top_bar.reset_rate()
	_seed_milestones()
	diorama.set_era(Story.era_for(state.evolutions))
	_audio_call("set_evolutions", [state.evolutions])
	_save_now()
	ticker.enqueue("ftue", Strings.s("F_IMPORTED"))


func _open_reset() -> void:
	_audio("panelOpen")
	overlays.request(func() -> Overlay:
		var o := Overlays.ResetOverlay.new()
		o.setup(self, overlays)
		return o.build(), true)


func _open_evolution() -> void:
	if overlays.is_open():
		return
	ftue.on_evolve_button(state)
	_audio("evolveOpen")
	var ready := d.evolve_enabled
	overlays.request(func() -> Overlay:
		var o := Overlays.EvolutionOverlay.new()
		o.setup(self, overlays)
		return o.build())
	ftue.on_overlay_opened(state, "EVOLUTION", ready)
	shop.cancel_press()


## One away rule (Economy.away_award) for a cold load and for time backgrounded alike. The credit
## happens first and is saved; the WELCOME BACK modal is only a receipt.
func _credit_away(elapsed_sec: float, cold: bool) -> void:
	var target := _next_state if _next_state != null else state
	var e := maxf(0.0, elapsed_sec)
	target.buff_frenzy = maxf(0.0, target.buff_frenzy - e)
	target.buff_tap_frenzy = maxf(0.0, target.buff_tap_frenzy - e)
	var r := Meta.away_award(target, e)
	if r["capped"] and r["showReceipt"]:
		target.stats["capHits"] = float(target.stats.get("capHits", 0.0)) + 1.0
	if float(r["award"]) > 0.0:
		Economy.add_bananas(target, float(r["award"]))
		store.save_game(target)
		if r["showReceipt"] and target == state:
			_pending_offline = {"award": r["award"], "away": r["elapsedSec"], "capped": r["capped"], "cold": cold}


func _on_away(gap_sec: float) -> void:
	shop.cancel_press()
	_presses.clear()
	_credit_away(gap_sec, false)
	if not _pending_offline.is_empty():
		_show_offline()


func _show_offline() -> void:
	var p := _pending_offline
	if p.is_empty():
		return
	_pending_offline = {}
	_audio("panelOpen")
	overlays.request(func() -> Overlay:
		var o := Overlays.OfflineOverlay.new()
		o.setup(self, overlays)
		o.award = p["award"]
		o.away_sec = p["away"]
		o.capped = p["capped"]
		o.cold = p["cold"]
		var eff := int(roundf(Meta.away_efficiency(state) * 100.0))
		var cap_h := int(roundf(Meta.away_cap_sec(state) / 3600.0))
		o.info = {"capHours": cap_h,
			"note1": Strings.s("OFF_NOTE_1_PCT", {"pct": eff}),
			"note2": Strings.s("OFF_CAP_TIP") if (p["capped"] and not Meta.perk_maxed(state, "p_nap")) else Strings.s("OFF_NOTE_2_H", {"h": cap_h})}
		return o.build())


func _do_reset() -> void:
	store.wipe_game()
	_audio("panelClose")
	_audio("gameReset")   # Audio v1.3: the music fades over a bar; the next first tap plays the motif again
	overlays.close_all()
	state = GameState.fresh()
	d = Economy.derive(state)
	golden.clear()
	diorama.clear_all()
	buffs.clear()
	floaters.clear()
	prop_fx.clear()
	shop.reset_run()
	top_bar.reset_rate()
	shop.switch_tab("producers")
	bb.set_aura("plain")
	bb.court_reset()
	_audio_call("set_evolutions", [0])
	_evolve_was_visible = false
	_autosave_ms = 0.0
	_load_kind = "none"
	_seed_milestones()
	diorama.set_era(Story.era_for(0))
	Leaders.set_salt(state, randi())
	_undo_ms = 0.0
	_pick_seq.clear()
	if Leaders.pick_pending(state):
		_open_picker()   # screen-graph §0: O10 → LEADER_PICK (first)
	else:
		_set_mode("title", false)


# ================================================================== evolve (E7: idempotent, save first, input locked)

func _start_evolve() -> void:
	if _tx_locked:
		return
	var nxt := state.duplicate_state()
	var res := Meta.evolve(nxt)
	if res.is_empty():
		return
	_tx_locked = true
	_economy_frozen = true
	_next_state = nxt
	store.save_game(nxt)
	_audio("evolveConfirm")
	_audio("electionConfirm", nxt.evolutions)
	_trick_fired = false
	_haptic(60)
	var top := overlays.top()
	if top is Overlays.EvolutionOverlay:
		(top as Overlays.EvolutionOverlay).close_for_confirm()
	overlays.tx_active = true
	shop.cancel_press()
	bb.lock()
	_set_hover_banana(false)
	diorama.poof_all()
	var new_era := Story.era_for(nxt.evolutions)
	var era_name: String = new_era.get("name", "") if new_era.get("id", "") != Story.era_for(state.evolutions).get("id", "") else ""
	tx.start({"round": nxt.evolutions + 1, "multBefore": res["multBefore"], "multAfter": res["multAfter"], "gained": res["gained"], "era": era_name},
		bool(settings["reducedMotion"]), {
		"seam": func() -> void:
			state = _next_state
			_next_state = null
			d = Economy.derive(state)
			golden.clear()
			diorama.clear_all()
			buffs.clear()
			floaters.clear()
			prop_fx.clear()
			shop.reset_run()
			top_bar.reset_rate()
			bb.set_aura("plain")
			_audio_call("set_evolutions", [state.evolutions])
			_seed_milestones()
			diorama.sync(state.owned, false)
			var era := Story.era_for(state.evolutions)
			if era.get("id", "") != Story.era_for(state.evolutions - 1).get("id", ""):
				ticker.enqueue("milestone", Strings.s("F_ERA", {"era": era.get("name", "")}))
				_audio("era", era.get("id", ""))
			diorama.set_era(era)
			_economy_frozen = false
			_acc = 0.0,
		"hello": func() -> void: bb.hello(),
		"unlock": func() -> void:
			_tx_locked = false
			overlays.tx_active = false
			bb.unlock()
			_audio("evolveTransitionEnd")
			if not _ceremony_on_marker:
				_audio("ceremonyEnd")
			ticker.defer_until(ticker.now_ms() + float(Tune.MC["headlineDeferAfterEvolveMs"]))
			ftue.on_tx_done(state, Economy.derive(state))
			_show_story_beat()
			_save_now(),
	})


# ================================================================== persistence

func _mark_dirty() -> void:
	_save_dirty = true


# ================================================================== leader select (LEADER_PICK)

## The picker rule, every frame: open it whenever the pick is pending and nothing is up (a new
## game, each election after O3 → EVOLVE_TX → [O3b], a reload mid-pick, the undo). Also runs the
## round-start sequence and the undo chip.
func _check_pick(dt: float) -> void:
	if mode != "pick" and _shot.is_empty() and Leaders.pick_pending(state) and not tx.running and not _tx_locked \
			and not overlays.is_open() and not chat.is_open() and not dossier.is_open():
		_open_picker()
	picker.update_view(dt)
	while not _pick_seq.is_empty() and _now >= float(_pick_seq[0]["at"]):
		var step: Dictionary = _pick_seq.pop_front()
		(step["fn"] as Callable).call()
	_update_undo_chip(dt)


## Opens LEADER_PICK (first on evolutions 0, else after). `keep` = the undo: the same order and
## the focus on the tile just picked.
func _open_picker(keep: Array = [], focus_id: String = "") -> void:
	var variant := "first" if state.evolutions == 0 else "after"
	var model := Leaders.picker(state)
	var pk: Variant = Leaders.ls().get("pick", {})
	var fresh := float((pk as Dictionary).get("freshFaceBasePct", 0.0)) if pk is Dictionary else 0.0
	var lp := variant == "after" and str(state.ui.get("lp", "")) == ""
	_undo_ms = 0.0
	_pick_seq.clear()
	toasts.clear_bubble()
	shop.cancel_press()
	_presses.clear()
	_set_mode("pick", false)
	picker.open(variant, model, keep, focus_id, fresh, lp)
	_pick_shown_ms = _now
	_funnel("leader_pick_shown", {"variant": variant, "n_tiles": picker.cells.size(), "order": picker.order})


## The commit frame (PickView.on_commit): the sim writes the round, the sting plays (the game's
## first sound on a fresh game: the release is the WebAudio gesture), and the save lands before
## the stage returns (screen-graph §0.2 rule 1).
func _on_pick_commit(id: String, via: String) -> bool:
	var res := Politics.install(state, id)
	if res.get("ok", false) != true:
		return false
	_pick_res = res.duplicate()
	_pick_res["via"] = via
	_pick_res["variant"] = picker.variant
	_pick_res["order"] = picker.order.duplicate()
	if picker.variant == "after":
		state.ui["lp"] = "done"   # ux/ftue.md LP: the first after-election picker taught the switch
	d = Economy.derive(state)
	_audio("leaderPick", id)
	if _shot.is_empty():
		store.save_game(state)
	_funnel("leader_pick_committed", {"leader": id, "via": via, "ms_to_pick": int(_now - _pick_shown_ms),
		"fresh": bool(res.get("fresh", false)), "switched": bool(res.get("switched", false))})
	return true


## ≈ 520 ms after the commit (PickView.on_done): the leader walks in (appears; the walk is the
## Animator's), the lower third, Dubi's line, the fresh toast and the 5 s undo chip (rtl-map §8.6).
func _on_pick_done() -> void:
	picker.publish_closed()
	bb.set_leader(LeaderUi.art(), LeaderUi.tap())
	bb.unlock()
	var first := state.evolutions == 0 and state.taps_lifetime == 0
	_set_mode("title" if first else "main", not first)
	if not first:
		_audio_call("start_music", [])
	bb.modulate.a = 0.0 if not settings["reducedMotion"] else 1.0
	if not settings["reducedMotion"]:
		create_tween().tween_property(bb, "modulate:a", 1.0, 0.25)
	ftue.on_input()   # rtl-map §8.6: every FTUE clock starts at the pick
	var id := Leaders.current(state)
	toasts.show_toast(Strings.s("LEADER_PICK_PLATE", {"short": LeaderUi.short(id), "party": LeaderUi.party(id)}))
	var dubi_at := Vector2(644, L.stage_bottom() - 232.0)
	var random := str(_pick_res.get("via", "")) == "random"
	_pick_seq = [{"at": _now + 380.0, "fn": func() -> void:
		toasts.say(Strings.s("LEADER_PICK_RANDOM_LINE" if random else "DUBI_LEARNED"), dubi_at, 1600.0)}]
	var line := str(Leaders.leader(id).get("pick", {}).get("line", "")) if Leaders.leader(id).get("pick") is Dictionary else ""
	if Leaders.stat(state, id, "taps") > 0.0 and line != "":
		_pick_seq.append({"at": _now + 2080.0, "fn": func() -> void: toasts.say(line, dubi_at, 1600.0)})
	if _pick_res.get("fresh", false) == true:
		toasts.show_toast(Strings.s("LEADER_PICK_FRESH", {"pct": int(roundf(float(_pick_res.get("freshPct", 0.0))))}))
	var pk: Variant = Leaders.ls().get("pick", {})
	_undo_full = 1000.0 * (float((pk as Dictionary).get("undoSec", 5.0)) if pk is Dictionary else 5.0)
	_undo_ms = _undo_full
	_place_undo_chip()
	if not _pending_offline.is_empty():
		_show_offline()   # O1 waited for the pick
	if mode == "main":
		_save_now()


## Test / tool hook: picks `id` at once (the commit and the stage, no animation).
func commit_pick(id: String) -> bool:
	if mode != "pick":
		if not Leaders.pick_pending(state):
			return false   # a loaded round (or content without leader select): nothing to pick
		_open_picker()
	var i := -1
	for k in picker.cells.size():
		if str(picker.cells[k]["id"]) == id:
			i = k
	if i < 0:
		return false
	picker.commit_cell(i, "tile")
	if not picker.locked:
		return false
	picker.finish_now()
	return true


## The leader card over the picker (rtl-map §8.7).
func _open_leader_card(id: String, via: String) -> void:
	if overlays.is_open():
		return
	_audio("panelOpen")
	_funnel("leader_card_opened", {"leader": id, "via": via})
	overlays.request(func() -> Overlay:
		var o := PickView.LeaderCard.new()
		o.setup(self, overlays)
		o.leader_id = id
		o.picker = picker
		return o.build())


## The undo chip (rtl-map §8.6): kit button_secondary at the left of the Suitcase band, a 2-art-px
## bar draining left → right over undoSec; up for undoSec of wall time after every pick while the
## round has not started (no tap, no buy).
func _build_undo_chip() -> void:
	_undo_btn = PxButton.make(_ui, Rect2(16, 0, 392, 80), {"kind": "kit_secondary", "label": Strings.s("LEADER_PICK_UNDO"),
		"label_box": 352.0, "on_commit": _undo_pick})
	_undo_bar = ColorRect.new()
	_undo_bar.color = Color("#fff8ec")
	_undo_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_undo_bar)
	_undo_btn.set_visible(false)
	_undo_bar.visible = false


func _place_undo_chip() -> void:
	if _undo_btn == null:
		return
	# rtl-map §8.6 / mobile-first §5.8: L-anchored in the lane (canvas x 16; `_ui` is the stage column)
	var y := L.stage_bottom() - 96.0
	var x := 16.0 - L.sox()
	_undo_btn.visual = Rect2(x, y, 392, 80)
	_undo_btn.hit = Rect2(x - 8.0, y - 4.0, 408, 88)
	Ui.set_nine_rect(_undo_btn.bg, _undo_btn.visual)
	if _undo_btn.label != null:
		_undo_btn.label.position.y = y + Ui.snap((80.0 - 28.0) / 2.0, 4)
		_undo_btn.label.center_in(x, 392)
	_undo_bar.position = Vector2(x + 8.0, y + 64.0)
	_undo_bar.size = Vector2(376, 8)


func undo_visible() -> bool:
	return _undo_ms > 0.0 and mode != "pick" and _undo_btn != null


func _update_undo_chip(dt: float) -> void:
	if _undo_ms > 0.0:
		_undo_ms -= dt
		if not Leaders.can_repick(state) or state.run_taps > 0 or Ftue.owned_total(state) > 0 or tx.running:
			_undo_ms = 0.0
	var on := undo_visible()
	_undo_btn.set_visible(on)
	_undo_bar.visible = on and not settings["reducedMotion"]
	if on:
		var f := clampf(_undo_ms / maxf(1.0, _undo_full), 0.0, 1.0)
		_undo_bar.size.x = Ui.snap(376.0 * f, 4)
		_undo_bar.position.x = 24.0 + 376.0 - _undo_bar.size.x   # drains left → right (mirror)


## "להחליף ראש רשימה" / U: back to the same picker (the same variant, order and seat seed), with
## the focus on the tile just picked; the sim reverts the pick (the +10%, the switch, the history).
func _undo_pick() -> void:
	if not undo_visible():
		return
	var from := Leaders.current(state)
	var r := Leaders.undo_pick(state)
	if r.get("ok", false) != true:
		_undo_ms = 0.0
		return
	_funnel("leader_pick_undo", {"from": from, "ms_since_pick": int(_undo_full - maxf(0.0, _undo_ms))})
	_undo_ms = 0.0
	_audio("leaderUndo")   # silent on purpose (cue-spec §4.1)
	_audio_call("set_leader", [Leaders.current(state)])
	d = Economy.derive(state)
	if _shot.is_empty():
		store.save_game(state)
	_open_picker(_pick_res.get("order", []), from)


## Funnel events (ux/screen-graph.md §0.4; names only, the developer plumbs them): the web build
## appends them to window.odFunnel for the drivers and a later analytics hook.
func _funnel(name: String, payload: Dictionary) -> void:
	if OS.has_feature("web"):
		var ev := payload.duplicate()
		ev["ev"] = name
		JavaScriptBridge.eval("(window.odFunnel = window.odFunnel || []).push(%s)" % JSON.stringify(ev), true)


func _save_now() -> void:
	if mode != "main" or _tx_locked or not _shot.is_empty():
		return
	_save_dirty = false
	_save_cooldown = 1000.0
	if not store.save_game(state):
		ticker.enqueue("ftue", Strings.s("F_NO_SAVE"))


func _flush_save() -> void:
	if mode == "main" and not _tx_locked and _shot.is_empty():
		store.save_game(state)
		_save_dirty = false


# ================================================================== shake
## Integer px offsets, linear decay, alternating x sign, random y sign (feel-spec §1/§2).

func _start_shake(px: float, ms: float) -> void:
	px *= float(settings.get("shake", 1.0))
	if px <= 0.0 or ms <= 0.0:
		return
	var active := float(_shake["ms"]) > 0.0 and float(_shake["t"]) < float(_shake["ms"])
	if active and roundf(float(_shake["px"]) * (1.0 - float(_shake["t"]) / float(_shake["ms"]))) > px:
		return
	_shake = {"px": px, "ms": ms, "t": 0.0, "frame": 0, "ysign": -1.0 if randf() < 0.5 else 1.0}


func _update_shake(dt: float) -> void:
	var o := Vector2.ZERO
	if float(_shake["ms"]) > 0.0 and float(_shake["t"]) < float(_shake["ms"]):
		var mag := roundf(float(_shake["px"]) * (1.0 - float(_shake["t"]) / float(_shake["ms"])))
		var alt := 1.0 if int(_shake["frame"]) % 2 == 0 else -1.0
		o = Vector2(alt * mag, float(_shake["ysign"]) * mag * alt)
		_shake["t"] = float(_shake["t"]) + dt
		_shake["frame"] = int(_shake["frame"]) + 1
	_root.position = o


# ================================================================== store screenshots
## `godot --path game -- --shot=<preset> --out=<png> [--frames=N]`: stage a preset state, let it
## animate, save the viewport as a PNG and quit. Presets: era<N> (the Nth content era, 0-based;
## an era id works too), perks, book, story.

func _read_shot_args() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shot="):
			_shot["name"] = a.substr(7)
		elif a.begins_with("--out="):
			_shot["out"] = a.substr(6)
		elif a.begins_with("--device="):
			var dv := a.substr(9).split("x")
			_shot["device"] = Vector2i(int(dv[0]), int(dv[1]))
		elif a == "--fork-scale":
			_shot["fork_scale"] = true
		elif a.begins_with("--frames="):
			_shot["frames"] = int(a.substr(9))
		elif a.begins_with("--target="):
			var wh := a.substr(9).split("x")
			_shot["target"] = Vector2i(int(wh[0]), int(wh[1]))
	if _shot.has("target"):
		# Render the design canvas at 1 design px per pixel for the target's aspect (the window
		# may be smaller than a phone screen); _run_shot scales it up to the exact store size.
		var t: Vector2i = _shot["target"]
		get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
		get_window().content_scale_size = Vector2i(L.W, int(roundf(float(L.W) * t.y / t.x)))


## The content era index a shot preset names (-1: not an era preset).
func _shot_era_index(n: String) -> int:
	var eras := Story.eras()
	if n.begins_with("era") and n.substr(3).is_valid_int():
		return clampi(int(n.substr(3)), 0, maxi(0, eras.size() - 1))
	for i in eras.size():
		if String(eras[i].get("id", "")) == n:
			return i
	return -1


func _shot_state() -> GameState:
	var s := GameState.fresh()
	var n: String = _shot["name"]
	var ei := _shot_era_index(n)
	var eras := Story.eras()
	var evo := int(eras[ei].get("fromEvolutions", 0)) if ei >= 0 and not eras.is_empty() else ({"perks": 3, "book": 5, "story": 2}.get(n, 0) as int)
	s.evolutions = evo
	var ids := Content.producer_ids()
	# owned counts per tier, by how far into the eras the preset is (first / middle / last)
	var tables := [[14, 9, 4, 1, 0, 0, 0, 0], [120, 95, 70, 52, 30, 12, 0, 0], [260, 210, 160, 120, 90, 60, 30, 12]]
	var owned: Array = [60, 40, 25, 10, 3, 0, 0, 0]
	if ei >= 0:
		owned = tables[0 if ei == 0 else (2 if ei >= eras.size() - 1 else 1)]
	for i in ids.size():
		s.owned[ids[i]] = int(owned[i]) if i < owned.size() else 0
	s.thumbs_owned = [0, 10, 20, 40, 80, 160, 320, 640][mini(evo, 7)]
	s.all_time_bananas = maxf(1000.0 * pow(float(s.thumbs_owned) * 2.0, 3.0), 5000.0)
	s.bananas = s.all_time_bananas * 0.02
	s.run_bananas = s.bananas * 4.0
	var ups: Array = Content.upgrades().map(func(u: Dictionary) -> String: return u["id"])
	s.upgrades = PackedStringArray(ups.slice(0, 5 if evo > 0 else 1))
	s.taps_lifetime = 3000 * (evo + 1)
	s.golden_caught_lifetime = 4 * evo
	s.crits_lifetime = 150 * (evo + 1)
	if n == "perks":
		s.thumbs_spent = 18
		s.shop = {"p_autotap": 1, "p_nap": 1, "p_start": 1}
	Meta.check_achievements(s, Economy.derive(s))
	s.ui = {"buyModeRevealed": evo > 0, "evolveRevealed": evo > 0, "tabsTouched": true}
	s.ftue = {"p1": "done", "p2": "done", "p3": "done", "p5": "done", "p6": "done", "p7": "done", "p4": {"shown": 3, "state": "done"}}
	for i in range(1, evo + 1):
		s.story_seen.append(Story.beat_id(i))
	if ei == 2:
		s.buff_frenzy = 12.0
	s.stats = {"playtimeSec": 5400.0 * (evo + 1), "bestBps": 0.0, "fastestRunSec": 420.0 if evo > 0 else 0.0, "goldenMissed": 2}
	return s


func _run_shot() -> void:
	var n: String = _shot["name"]
	match n:
		"perks":
			_open_perks()
		"book":
			_open_book()
		"story":
			overlays.request(func() -> Overlay:
				var o := Overlays.StoryOverlay.new()
				o.setup(self, overlays)
				o.evolutions = state.evolutions
				return o.build())
		_ when _shot_era_index(n) == 0:
			var hl: Array = Content.data().get("headlines", [])
			if not hl.is_empty():
				ticker.enqueue("milestone", String(hl[0].get("text", "")))
			golden.lifetime_ms = 60000.0
			golden.spawn()
	await get_tree().create_timer(float(_shot.get("frames", 150)) / 60.0).timeout
	if _shot_era_index(n) >= 0:
		seed(7)
		for i in 2:
			_handle_tap(L.magician_hit().get_center() + Vector2(-50.0 + 100.0 * i, -40.0))
			await get_tree().create_timer(0.15).timeout
	await get_tree().create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	if _shot.has("target"):
		var t: Vector2i = _shot["target"]
		img.resize(t.x, t.y, Image.INTERPOLATE_NEAREST)
	img.save_png(String(_shot.get("out", "user://shot.png")))
	print("SHOT ", _shot["name"], " ", img.get_width(), "x", img.get_height())
	get_tree().quit(0)
