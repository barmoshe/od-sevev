class_name ShareDesk
extends Node
## The share platform's runtime (Bar 2026-10-02): main's one ShareDesk owns
##   - the share session: ShareKit.request(kind, model) → the HTML share drawer on the web
##     (game/web/shell.html window.odShareUI: the live preview, the WhatsApp-bubble mock, the format
##     and family-safe toggles, native share and the channel row), the canvas ShareSheet elsewhere;
##   - the card renders: one SubViewport at a time, the PNG read back and handed to JS as base64
##     BEFORE the player's tap (the drawer's real HTML button then calls navigator.share inside the
##     tap: Safari's transient activation never waits on the engine);
##   - the moments and the prompt rules: a share-worthy moment (a juicy chat line, the gate, a court
##     day, the election, round 3 / 5 / 10) lights the 📣 chip's dot; at most ONE proactive prompt a
##     session (the media advisor's chat toast, and his line in T3 for a leak), never during a tap
##     burst or over a celebration (a calm beat after it), backing off after ignored prompts
##     (settings.share: dismiss / promptAt; a share resets it);
##   - the 📣 "הדלף" chip (stage top-left, the ability chip's mirror) and its twin in T3's header;
##   - the arrival from a shared link (window.odArrival, parsed by the shell): a toast, and the
##     `arrived` signal for the challenge agent.
## Events JS → engine: window.odShareEvent(type, value) with type kind | fmt | neutral | result |
## close (result value "<channel>/<result>").

signal arrived(info: Dictionary)
signal share_done(kind: String, channel: String, result: String)

const BEAT_MS := 2500.0           # a prompt waits this long after its moment (never over the peak)
const QUIET_AFTER_TAP_MS := 1500.0
const PROMPT_TTL_MS := 45000.0    # a moment older than this never prompts (its dot stays)
const IGNORED_MS := 20000.0       # a prompt nobody opened within this counts as dismissed
const MAX_DISMISS := 3            # after this many, no proactive prompt until the player shares
const CAREER_ROUNDS := [3, 5, 10, 25]

var host: Node
var session: Dictionary = {}      # {kind, fmt, neutral, rot, prompted, shared, kinds}
var models: Dictionary = {}       # the caller's models by kind (challenge / daily)
var moment := ""                  # the kind the last share-worthy moment offers ("" = none)
var moment_event := ""
var moment_ms := -1e12
var prompted := false             # this session's one proactive prompt went out
var prompt_kind := ""
var prompt_ms := -1e12
var prompt_open_pending := false  # the prompt is out and nobody opened the drawer from it yet
var drawer_open := false
var arrival: Dictionary = {}
var last_text := ""               # the open session's message body (tests, window.odShareState)
var renders := 0                  # renders started (tests)
var chip: ShareChip
var chat_btn: ShareChip

var _now := 0.0
var _cache: Dictionary = {}       # "kind|fmt|neutral" -> base64 PNG
var _queue: Array = []            # [{key, kind, model, fmt}]
var _busy := false
var _vp: SubViewport
var _job: Dictionary = {}
var _js_cb: JavaScriptObject
var _gate_seen := false
var _arrival_toast := false
var _arrival_due := false         # the arrival toast waits for the round's stage (after the picker)


func setup(h: Node) -> ShareDesk:
	host = h
	name = "ShareDesk"
	ShareKit.desk = self
	return self


func _ready() -> void:
	if OS.has_feature("web"):
		_js_cb = JavaScriptBridge.create_callback(func(args: Array) -> void:
			var t := str(args[0]) if args.size() > 0 else ""
			var v: Variant = args[1] if args.size() > 1 else null
			_on_js.call_deferred(t, v))
		var win := JavaScriptBridge.get_interface("window")
		if win != null:
			win.odShareEvent = _js_cb
		arrival = read_arrival()


## Builds the stage chip (in `stage`) and T3's header button (in the chat panel).
func build_chips(stage: Node2D, chat_panel: Node2D) -> void:
	chip = ShareChip.new()
	chip.name = "ShareChip"
	stage.add_child(chip)
	chip.place(ShareChip.LEFT_RECT)
	chat_btn = ShareChip.new()
	chat_btn.name = "ShareChatBtn"
	chat_btn.compact = true
	if chat_panel != null:
		chat_panel.add_child(chat_btn)
	chat_btn.place(ShareChip.CHAT_RECT)


# ------------------------------------------------------------------ the session

## ShareKit.request: opens the drawer (web) or the canvas sheet on `kind`; `ext` is the caller's model.
func request(kind: String, ext: Dictionary = {}, via_prompt: bool = false) -> bool:
	if not ext.is_empty():
		models[kind] = ext
	var s := _state()
	var kinds := ShareKit.kinds_for(s, models.keys())
	if not kinds.has(kind):
		kinds.insert(0, kind)
	var pref := share_prefs()
	session = {"kind": kind, "fmt": str(pref.get("fmt", "sq")), "neutral": bool(pref.get("neutral", false)),
		"rot": int(pref.get("rot", 0)), "prompted": via_prompt, "shared": false, "kinds": kinds}
	if session["fmt"] == "story" and not _story_ok(kind):
		session["fmt"] = "sq"
	pref["rot"] = int(pref.get("rot", 0)) + 1
	_save_prefs(pref)
	if moment == kind:
		moment = ""   # the dot goes once its moment is open
	if via_prompt:
		prompt_open_pending = false
	_cache.clear()
	if not drawer_available():
		return _open_sheet(kind)
	drawer_open = true
	_send("open", payload())
	_render_current()
	if host != null and host.has_method("audio_event"):
		host.audio_event("panelOpen")
	return true


## The 📣 chip / T3's button / T4's row: the pending moment's kind, else the best one there is.
func open_menu(kind: String = "") -> bool:
	if kind == "":
		kind = moment if moment != "" else default_kind()
	var vp := moment == kind and moment != "" and prompt_open_pending
	return request(kind, models.get(kind, {}), vp)


func default_kind() -> String:
	var ks := ShareKit.kinds_for(_state(), models.keys())
	for k: String in ["leak", "breaking", "term", "career", "result"]:
		if ks.has(k):
			return k
	return "result"


## The drawer's model of the session's kind (the copy rotates per open).
func current_model() -> Dictionary:
	var k := str(session.get("kind", "result"))
	var opts := {"neutral": bool(session.get("neutral", false)), "rot": int(session.get("rot", 0))}
	if k == "breaking" and moment_event != "" and moment == "":
		opts["event"] = moment_event
	return ShareKit.model(k, _state(), _derived(), models.get(k, {}), opts)


## What the drawer needs (JSON): the tabs, the toggles, the text without the link, the stub path, the
## hash extra, the file name; the image comes after (image()).
func payload() -> Dictionary:
	var m := current_model()
	last_text = str(m.get("text", ""))
	var tabs: Array = []
	for k: String in session.get("kinds", []):
		tabs.append([k, Strings.s("SHARE_KIND_" + k.to_upper()) if Strings.has("SHARE_KIND_" + k.to_upper()) else k])
	var k := str(session.get("kind", ""))
	return {"kind": k, "tabs": tabs, "fmt": session.get("fmt", "sq"), "neutral": bool(session.get("neutral", false)),
		"neutralOk": not ["receipt", "daily"].has(k), "storyOk": _story_ok(k), "text": last_text,
		"stub": str(m.get("stub", "")), "hash": str(m.get("hash", "")), "file": ShareKit.file_name(k, str(session.get("fmt", "sq"))),
		"key": _key(k, str(session.get("fmt", "sq")), bool(session.get("neutral", false))), "site": ShareKit.site_url(),
		"daily": k == "daily", "og": ShareKit.og_head(str(m.get("stub", "")))}


func _story_ok(_kind: String) -> bool:
	return true


func _on_js(t: String, v: Variant) -> void:
	if session.is_empty() and t != "close":
		return
	match t:
		"kind":
			var k := str(v)
			if not ShareKit.DRAWER_KINDS.has(k):
				return
			session["kind"] = k
			session["rot"] = int(session.get("rot", 0)) + 1
			if session["fmt"] == "story" and not _story_ok(k):
				session["fmt"] = "sq"
			_send("update", payload())
			_render_current()
		"fmt":
			var f := str(v)
			if not ["sq", "story", "text"].has(f):
				return
			session["fmt"] = f
			var p := share_prefs()
			p["fmt"] = f
			_save_prefs(p)
			_send("update", payload())
			_render_current()
		"neutral":
			var sv := str(v)   # never `v == true`: a String compared with a bool is a runtime error
			session["neutral"] = sv == "true" or sv == "1"
			var p2 := share_prefs()
			p2["neutral"] = session["neutral"]
			_save_prefs(p2)
			_send("update", payload())
			_render_current()
		"result":
			var parts := str(v).split("/")
			var ch := parts[0] if parts.size() > 0 else ""
			var r := parts[1] if parts.size() > 1 else ""
			on_result(str(session.get("kind", "")), ch, r)
		"close":
			close_session()


## A share went out (or was cancelled / failed): the funnel, the back-off reset on a real share.
func on_result(kind: String, channel: String, result: String) -> void:
	share_done.emit(kind, channel, result)
	if ["shared", "opened", "copied", "saved"].has(result):
		session["shared"] = true
		var p := share_prefs()
		p["dismiss"] = 0
		p["shares"] = int(p.get("shares", 0)) + 1
		_save_prefs(p)


## The drawer closed (✕, back, the backdrop): a prompted session that shared nothing is a dismissal.
func close_session() -> void:
	if session.is_empty() and not drawer_open:
		return
	if bool(session.get("prompted", false)) and not bool(session.get("shared", false)):
		note_dismissed()
	drawer_open = false
	session = {}
	_queue.clear()
	_cache.clear()
	if host != null and host.has_method("audio_event"):
		host.audio_event("panelClose")


## Closes the drawer from the engine (the history back, a new layer).
func close_drawer() -> void:
	if drawer_open:
		_send("close", {})
	close_session()


func note_dismissed() -> void:
	var p := share_prefs()
	p["dismiss"] = int(p.get("dismiss", 0)) + 1
	p["promptAt"] = _state().evolutions if _state() != null else 0
	_save_prefs(p)


# ------------------------------------------------------------------ renders

func _key(kind: String, fmt: String, neutral: bool) -> String:
	return "%s|%s|%s" % [kind, fmt, "n" if neutral else "p"]


## Renders the session's image (and then its other format, so a toggle is instant).
func _render_current() -> void:
	if session.is_empty():
		return
	var k := str(session["kind"])
	var neutral := bool(session.get("neutral", false))
	var fmt := str(session.get("fmt", "sq"))
	var want: Array = ["sq", "story"] if fmt != "story" else ["story", "sq"]
	var m := current_model()
	for f: String in want:
		var key := _key(k, f, neutral)
		if _cache.has(key):
			if f == want[0] or fmt == "text":
				_send_image(key, str(_cache[key]))
			continue
		enqueue(key, k, m, f)


func enqueue(key: String, kind: String, m: Dictionary, fmt: String) -> void:
	for j: Dictionary in _queue:
		if j["key"] == key:
			return
	if not _job.is_empty() and _job.get("key", "") == key:
		return
	_queue.append({"key": key, "kind": kind, "model": m, "fmt": fmt})
	_pump()


func _pump() -> void:
	if _busy or _queue.is_empty():
		return
	_busy = true
	_job = _queue.pop_front()
	renders += 1
	_vp = SubViewport.new()
	_vp.size = ShareCards.size_of(str(_job["fmt"]))
	_vp.transparent_bg = false
	_vp.disable_3d = true
	_vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	_vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	var root := Node2D.new()
	_vp.add_child(root)
	build_card(root, str(_job["kind"]), _job["model"], str(_job["fmt"]), _state(), _derived())
	add_child(_vp)
	if DisplayServer.get_name() == "headless":
		_finish.call_deferred(null)
	else:
		RenderingServer.frame_post_draw.connect(_on_post_draw, CONNECT_ONE_SHOT)


## Any kind in any format: ShareCards' kinds, and O4 / O5 through ShareSheet (their story format
## centres the square card on ShareCards' band).
static func build_card(root: Node2D, kind: String, m: Dictionary, fmt: String, s: GameState, d: Economy.Derived) -> void:
	if ShareCards.KINDS.has(kind):
		ShareCards.build(root, kind, m, fmt)
		return
	var inner := root
	if fmt == "story":
		inner = ShareCards.wrap_story(root, ShareSheet.C_NIGHT if kind == "result" else Color("#e8e3d4"))
	ShareSheet.build_card(inner, kind, s, d, SaveStore.now_ms())


func _on_post_draw() -> void:
	if not is_instance_valid(_vp):
		_finish(null)
		return
	_finish(_vp.get_texture().get_image())


func _finish(img: Variant) -> void:
	var b64 := ""
	if img is Image and not (img as Image).is_empty():
		(img as Image).convert(Image.FORMAT_RGB8)
		b64 = Marshalls.raw_to_base64((img as Image).save_png_to_buffer())
	var key := str(_job.get("key", ""))
	if is_instance_valid(_vp):
		_vp.queue_free()
	_vp = null
	_busy = false
	_job = {}
	if key != "" and b64 != "":
		_cache[key] = b64
		if not session.is_empty() and key == _key(str(session["kind"]), str(session.get("fmt", "sq")), bool(session.get("neutral", false))):
			_send_image(key, b64)
		elif not session.is_empty() and str(session.get("fmt", "")) == "text" and key == _key(str(session["kind"]), "sq", bool(session.get("neutral", false))):
			_send_image(key, b64)
	_pump()


func _send_image(key: String, b64: String) -> void:
	if not OS.has_feature("web"):
		return
	JavaScriptBridge.eval("window.odShareUI && window.odShareUI.image(%s, '%s')" % [JSON.stringify(key), b64], true)


func _send(what: String, data: Dictionary) -> void:
	if not OS.has_feature("web"):
		return
	JavaScriptBridge.eval("window.odShareUI && window.odShareUI.%s(%s)" % [what, JSON.stringify(data)], true)


func drawer_available() -> bool:
	return OS.has_feature("web") and bool(JavaScriptBridge.eval("typeof window.odShareUI === 'object' && !!window.odShareUI.open", true))


## Off the web: the canvas sheet with the card (ShareSheet takes any kind).
func _open_sheet(kind: String) -> bool:
	if host == null or not host.has_method("open_share_sheet"):
		return false
	return bool(host.call("open_share_sheet", kind, models.get(kind, {})))


# ------------------------------------------------------------------ moments and the prompt

## A share-worthy moment: the 📣 dot lights; the one prompt of the session may follow, a beat later.
func note_moment(kind: String, event: String = "") -> void:
	moment = kind
	moment_event = event
	moment_ms = _now


## Politics events (main._on_politics_event): the juicy chat lines and the court day.
func on_politics_event(e: Dictionary) -> void:
	var ev := str(e.get("ev", ""))
	if ev == "message" and e.get("msg") is Dictionary:
		var m: Dictionary = e["msg"]
		var t := str(m.get("type", ""))
		var key := str(m.get("key", ""))
		if t == "ultimatum" or t == "transfer" or key == "chat.sys.brawl" or key == "chat.sys.left":
			note_moment("leak")
	elif ev == "partnerLeft":
		note_moment("leak")
	elif ev == "courtStart":
		note_moment("breaking", "court")


## The election was called (main._start_evolve): the term summary, or the career at round 3/5/10.
func on_election(n: int) -> void:
	if CAREER_ROUNDS.has(n):
		note_moment("career")
	else:
		note_moment("term")
	_gate_seen = false


## The prompt may go out now: one a session, the back-off, a calm beat, nothing over the stage.
func prompt_allowed(calm: bool) -> bool:
	if prompted or moment == "" or drawer_open or not calm:
		return false
	if _now - moment_ms < BEAT_MS or _now - moment_ms > PROMPT_TTL_MS:
		return false
	var p := share_prefs()
	var dis := int(p.get("dismiss", 0))
	if dis >= MAX_DISMISS:
		return false
	if dis > 0 and _state() != null and _state().evolutions < int(p.get("promptAt", 0)) + 2 * dis:
		return false
	return true


## Per frame from main: the clock, the gate's edge (breaking), the prompt, the ignored prompt, the
## chips. `calm` = no overlay, no transition, not the picker, no tap burst, the toast dock idle.
func tick(dt_ms: float, calm: bool, stage_up: bool, chat_open: bool) -> void:
	_now += dt_ms
	var s := _state()
	if s != null:
		var gate := RoundLog.gate_sec(s) > 0.0
		if gate and not _gate_seen:
			note_moment("breaking", "gate")
		_gate_seen = gate
	if _arrival_due and stage_up and host != null and host.get("toasts") != null:
		_arrival_due = false
		host.get("toasts").show_toast(Strings.s("SHARE_ARRIVED"), "", "lane")
	if prompt_allowed(calm):
		_prompt()
	if prompt_open_pending and _now - prompt_ms > IGNORED_MS:
		prompt_open_pending = false
		note_dismissed()
	var revealed := s != null and (s.evolutions >= 1 or (s.coalition is Dictionary and bool(s.coalition.get("opened", false))))
	if chip != null:
		_place_chip()
		chip.dot = moment != ""
		var cameo: bool = host != null and host.get("chat") != null and (host.get("chat") as ChatView).cameo_visible()
		chip.update_view(dt_ms, stage_up and revealed and not (cameo and chip.rect == ShareChip.ALT_RECT))
	if chat_btn != null:
		chat_btn.dot = moment != ""
		chat_btn.update_view(dt_ms, chat_open)


## The stage chip: under the missions chip in the left column (LEFT_RECT) while the thermometer is
## down; with the thermometer up, the right column: the ability chip's slot (TOP_RECT) while that
## chip is hidden, else under it (ALT_RECT), where it hides while an ultimatum's cameo stands (its
## timer chip shares the column). L-anchored on the left, like the missions chip.
func _place_chip() -> void:
	var th: Variant = host.get("thermo") if host != null else null
	var want := ShareChip.LEFT_RECT
	if th != null and (th as Thermo).is_shown() and (th as Thermo).icon_top() < ShareChip.LEFT_RECT.end.y + 8.0:
		var ab: Variant = host.get("ability_chip")
		want = ShareChip.ALT_RECT if ab != null and (ab as Node2D).visible else ShareChip.TOP_RECT
	chip.position.x = -L.sox() if want == ShareChip.LEFT_RECT else 0.0
	if chip.rect != want:
		chip.place(want)


## A stage point (MainController._in_stage) on the 📣 chip.
func chip_takes(sp: Vector2) -> bool:
	return chip != null and chip.takes(sp - chip.position)


## A `_lower` point on T3's header 📣 (the chat open and taking input).
func chat_btn_takes(chat: ChatView, lp: Vector2) -> bool:
	if chat_btn == null or chat == null or not chat.is_open() or not chat_btn.visible:
		return false
	return chat_btn.takes(chat._tall(lp))


func _prompt() -> void:
	prompted = true
	prompt_kind = moment
	prompt_ms = _now
	prompt_open_pending = true
	var key := "ADVISOR_" + moment.to_upper()
	var line := ""
	if moment == "career":
		line = Strings.s(key, {"rounds": Strings.plural("ROUNDS", maxi(_state().evolutions, _state().history.size()))})
	elif Strings.has(key):
		line = Strings.s(key)
	if host == null or line == "":
		return
	var toasts: Variant = host.get("toasts")
	if toasts != null:
		var face: Array = ChatView.toast_avatar("dubi")
		if str(face[0]) == "" and Art.has_sprite("avatar_dubi"):
			face = ["avatar_dubi", 4.0, 1]
		toasts.show_chat_toast(Strings.s("ADVISOR_HEAD"), line, face, "share", false, 2)
	# the advisor's line in T3 (the leak's moment is the chat's own)
	var s := _state()
	if moment == "leak" and s != null and s.coalition is Dictionary and bool(s.coalition.get("opened", false)):
		Coalition._post(s, {"type": "sys", "key": "chat.sys.advisor"}, [])


## The prompt's toast was tapped (main's toasts.on_tap, tag "share").
func open_prompted() -> bool:
	var k := prompt_kind if prompt_kind != "" else default_kind()
	return request(k, models.get(k, {}), true)


## Dev / tools only (the browser checks, tools/og.sh previews): a believable round of the group chat
## through the sim's own posts (a demand, an ultimatum, a walkout, a brawl, a join), so the leak card
## has real lines. Never called in play.
static func seed_demo_chat(s: GameState) -> void:
	if not Coalition.active():
		return
	var d := Economy.derive(s)
	if not bool(s.coalition.get("opened", false)):
		Coalition.open_group(s, d, func() -> float: return 0.0)
	var ids: Array = Coalition.partners().map(func(p: Dictionary) -> String: return str(p["id"])).filter(func(x: String) -> bool: return Coalition.partner(x).get("standIn", false) != true)
	if ids.size() < 4:
		return
	var out: Array = []
	for i in 4:
		Coalition.ps(s, ids[i])["status"] = "member"
	Coalition._post(s, {"type": "demand", "partner": ids[0], "price": 1200000.0, "kind": "money", "join": false, "ageSec": 0.0,
		"state": "paid", "line": "demand", "variant": 1}, out)
	Coalition._post(s, {"type": "ultimatum", "partner": ids[1], "price": 2400000.0, "kind": "money", "leftSec": 60.0,
		"state": "open", "line": "threat", "variant": 0}, out)
	Coalition._leave(s, ids[2], 3600000.0, out)
	Coalition._post(s, {"type": "demand", "partner": ids[3], "price": 800000.0, "kind": "money", "join": false, "ageSec": 0.0,
		"state": "open", "line": "demand", "variant": 2}, out)
	Coalition.start_brawl(s, ids[0], ids[1])
	s.coalition["paidRound"] = int(s.coalition.get("paidRound", 0)) + 3


# ------------------------------------------------------------------ the arrival

## window.odArrival (the shell parsed the shared link's hash and cleaned it): {kind, via, ref,
## params} or {}.
static func read_arrival() -> Dictionary:
	if not OS.has_feature("web"):
		return {}
	var raw: Variant = JavaScriptBridge.eval("window.odArrival ? JSON.stringify(window.odArrival) : ''", true)
	if raw == null or str(raw) == "":
		return {}
	var v: Variant = JSON.parse_string(str(raw))
	return v if v is Dictionary else {}


## After the hand-off, once: the arrival toast (a challenge / daily arrival is the challenge
## agent's: the signal only), then `arrived`.
func on_handoff() -> void:
	if arrival.is_empty() or _arrival_toast:
		return
	_arrival_toast = true
	arrived.emit(arrival)
	_arrival_due = not ["challenge", "daily"].has(str(arrival.get("kind", "")))


# ------------------------------------------------------------------ prefs (settings.share)

func share_prefs() -> Dictionary:
	if host == null or not "settings" in host:
		return {}
	var st: Dictionary = host.get("settings")
	if not st.get("share") is Dictionary:
		st["share"] = {}
	return st["share"]


func _save_prefs(p: Dictionary) -> void:
	if host == null or not "settings" in host:
		return
	var st: Dictionary = host.get("settings")
	st["share"] = p
	var store: Variant = host.get("store")
	if store != null:
		store.save_settings(st)


func _state() -> GameState:
	return host.get("state") if host != null else null


func _derived() -> Economy.Derived:
	return host.get("d") if host != null else null


## window.odShareState (the browser checks): the session, the moment, the chips' rects.
func debug_info() -> Dictionary:
	return {"open": drawer_open, "kind": session.get("kind", ""), "fmt": session.get("fmt", ""), "neutral": session.get("neutral", false),
		"moment": moment, "prompted": prompted, "promptKind": prompt_kind, "renders": renders, "text": last_text, "cached": _cache.keys()}


# =============================================================================================
# The 📣 chip: the ability chip's look (the kit buffChip), a megaphone drawn here (no kit icon yet),
# "הדלף" under it, a red dot while a moment waits. LEFT_RECT is stage px under the missions chip
# (left of the leader's hit box, which starts at x 188); TOP_RECT and ALT_RECT the right column
# with the thermometer up (the ability chip's slot, or under it); CHAT_RECT is
# T3's tall-local header (its left end; the status line yields 96 px).
# =============================================================================================

class ShareChip:
	extends Node2D

	const LEFT_RECT := Rect2(8, 256, 96, 100)   # under the missions chip (MissionsChip 168-248, full mode)
	const TOP_RECT := Rect2(612, 168, 96, 100)   # the ability chip's slot (AbilityChip.RECT 572-712), its right edge
	const ALT_RECT := Rect2(612, 308, 96, 100)   # under the ability chip (AbilityChip.RECT ends at 300)
	const CHAT_RECT := Rect2(12, 8, 88, 88)
	const ICON := ["............",
		"..........KK",
		"........KKWK",
		"......KKWWWK",
		"KKKKKKWWWWWK",
		"KGGGWWWWWWWK",
		"KGGGWWWWWWWK",
		"KKKKKKWWWWWK",
		"...KK.KKWWWK",
		"...KK...KKWK",
		"...KK.....KK"]

	var rect := Rect2()
	var dot := false
	var compact := false
	var reduced_motion := false
	var _bg: NinePatchRect
	var _icon: Sprite2D
	var _label: PxText
	var _dot: ColorRect
	var _dot_in: ColorRect
	var _t := 0.0
	static var _tex: ImageTexture

	static func icon_texture() -> ImageTexture:
		if _tex != null:
			return _tex
		var h := ICON.size()
		var w := String(ICON[0]).length()
		var img := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))
		var cols := {"K": Color("#061029"), "W": Color("#f7f4ec"), "G": Color("#ffd23f")}
		for y in h:
			var row := String(ICON[y])
			for x in w:
				var c := row[x]
				if cols.has(c):
					img.set_pixel(x, y, cols[c])
		_tex = ImageTexture.create_from_image(img)
		return _tex

	func place(r: Rect2) -> void:
		rect = r
		for c in get_children():
			c.queue_free()
		var C: Dictionary = Art.theme.get("buffChip", {}) if Art.theme is Dictionary else {}
		if not compact and C.has("sprite"):
			_bg = Ui.nine(self, r, str(C["sprite"]), int(C.get("frame", 0)))
		elif not compact:
			Ui.rect(self, r, Color("#0f2350"))
		_icon = Sprite2D.new()
		_icon.texture = icon_texture()
		_icon.centered = true
		_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_icon.scale = Vector2(4, 4)
		_icon.position = r.position + Vector2(r.size.x / 2.0, (r.size.y / 2.0) if compact else 32.0)
		add_child(_icon)
		if not compact:
			_label = PxText.make(self, r.position + Vector2(0, 64), Strings.s("SHARE_CHIP"), 3, "plain", C.get("text", "k"))
			_label.fit_width = r.size.x - 8.0
			_label.center_in(r.position.x, r.size.x)
		_dot = Ui.rect(self, Rect2(r.end.x - 24, r.position.y - 4, 28, 28), Color("#061029"))
		_dot_in = Ui.rect(self, Rect2(r.end.x - 20, r.position.y, 20, 20), Color("#d02a36"))
		_dot.visible = false
		_dot_in.visible = false
		visible = false

	func takes(p: Vector2) -> bool:
		return visible and rect.grow(4).has_point(p)

	func update_view(dt_ms: float, show: bool) -> void:
		visible = show
		if not show:
			return
		_t += dt_ms
		_dot.visible = dot
		_dot_in.visible = dot
		var a := 1.0
		if dot and not reduced_motion:
			a = 0.85 + 0.15 * (0.5 + 0.5 * sin(TAU * 1.2 * _t / 1000.0))
		_icon.modulate.a = a
