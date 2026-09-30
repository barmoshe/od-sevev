class_name ChatView
extends Node2D
## T3 "קואליציה 61": the coalition group chat as a tall tab (ux/rtl-map.md §6.3, kit `chat_*`),
## plus the ultimatum stage cameo (§4.2). A child of `_lower`, positioned at y = −S, so its local
## space is "tall-local": y 0 = the stage top, the tab covers the stage, the ticker and the panel
## down to the tab bar (H_T = S + 84 + P). Rows A and B stay visible above it.
## Mobile-first §4.1 / §5.5: the tab spans the canvas. The header chevron, title and status, the
## pinned pin and text, the composer text and the incoming avatars and bubbles are R-anchored
## (+ dx: a partner row's root sits at x dx); the replies stay left (x 16); system pills, the
## brawl slot and the pending chip are centred on the canvas; backgrounds, the pinned bar, the
## thread clip and the composer stretch. Bubble text columns keep their 720 measure (≤ 20 glyphs).
##
## It is a VIEW of the sim's chat log (`state.coalition.chat`, game/scripts/sim/README.md
## "Messages"). No rule lives here: pay / rejoin / poach go through `Coalition.pay`, "צאו החוצה"
## through `Coalition.resolve_brawl`. The view only decides WHEN a message is shown (the typing
## telegraph and the join cascade, ux/ftue.md "chat open cascade"; motion chat-typing) and how.
##
## Rebuild model: the thread's nodes are rebuilt when the log's shape changes (a message posted,
## paid, expired, revealed); per frame only the live parts move (pill affordance, ultimatum
## timers, the corridor counter, the arrival / stamp / pip tweens). The log is capped at chatMax
## (80) by the sim, so a rebuild is a few hundred nodes at most and happens a few times a minute.
##
## Audio (Audio autoload through host.audio_event): chatPing(partner) on a bubble landing while
## open or on the preview toast while closed; ultimatumTick(seconds) once per displayed second
## (the Audio doubles the last 3 s); ultimatumZero when an ultimatum runs out (instead of
## chatLeft); chatLeft when a partner leaves otherwise; stamp + ultimatumPaid on paying;
## panelOpen / panelClose.

signal open_changed(open: bool)

## tall-local layout (rtl-map §6.3)
const HEADER_H := 104.0
const PINNED_Y := 104.0
const PINNED_H := 56.0
const THREAD_Y := 160.0
const COMPOSER_H := 88.0
const CHEVRON_HIT := Rect2(632, 8, 88, 88)
const PINNED_HIT := Rect2(0, 104, 720, 88)
const TITLE_RIGHT := 616.0
const AVATAR_RIGHT := 704.0
const AVATAR_BOX := 128.0            # 32 art px at ×4 (flag F5 / D15)
const BUBBLE_RIGHT := 568.0
const BUBBLE_MIN_X := 88.0           # width ≤ 480
const TEXT_W := 416.0                # chat.bubble box: 17 glyphs
const NAME_HIT_W := 416.0
const PILL_W := 328.0                # kit pay_pill stretched to 82×17 art
const PILL_H := 68.0
const PILL_HIT := Vector2(352, 88)
const WIDE_PILL := Rect2(104, 0, 512, 68)     # rejoin / poach, centred; hit 536×88
const SYS_TEXT_W := 568.0
const CHIP_W := 128.0
const CHIP_H := 52.0
const RUN_GAP := 24.0
## B11 (mobile-first §5.5.1): the thread opens under the header with a day chip ("היום", the
## messenger convention), then the messages top-down; the player's reply gets a row of its own: the
## round's leader named over the bubble (the partners' name-over-bubble, mirrored to the left).
const OUT_NAME_H := 44.0
const IN_RUN_GAP := 8.0
const CASCADE_MAX := 4               # more pending than this on open: show them at once
const INPUT_AFTER_OPEN_MS := 140.0   # motion tall-tab: the thread accepts taps from 140 ms
const CEREMONY_MS := 3000.0          # sim: a ceremony (Regev) needs "the UI's 3 s ribbon"

## palette (style guide v2 §2.1)
const C_THREAD := Color("#072a7a")    # ui_panel
const C_NAME := Color("#c9d6f2")      # grey
const C_MUTED := Color("#b4c3e8")     # slate
const C_SYS_TEXT := Color("#c9d6f2")  # ui_mute on chat_system_pill_navy (12.9:1, review U7)
const C_INK := Color("#061029")       # ink (on gold)
const C_ALERT := Color("#ffaa9f")     # red_hi ("אולטימטום", the last seconds)
const C_GOLD_HI := Color("#fff1a6")
const C_SKY := Color("#8fc0ff")       # the seats fill (pips)

## motion-spec.yaml motion-constants (Tune.MC wins once the engine mirrors them)
const MC_DEFAULTS := {
	"tallTabOpenMs": 280, "tallTabCloseMs": 200, "tallTabOpenReducedMs": 150, "tallTabCloseReducedMs": 120,
	"chatBubbleInMs": 180, "chatBubbleInOffsetPx": 16, "chatScrollMs": 180, "stampSlamMs": 90,
	"seatPipMax": 6, "seatPipStaggerMs": 50, "seatPipFlightMs": 450,
	"ultimatumNudgeFromSec": 10, "ultimatumUrgentFromSec": 3,
	"chatTypingMs": 1200, "chatCascadeGapMs": 250, "chatReplyDelayMs": 300,
}

var host: Node                        # MainController (duck-typed: audio_event, state, shop, toasts, ...)
var reduced_motion := false

var _state: GameState
var _d: Economy.Derived
var _open := false
var _anim: Dictionary = {}            # {kind: open|close, t}
var _open_ms := 0.0
var _now := 0.0
var _h := 1102.0                      # H_T
var _vs_w := 720.0
var _ox := 0.0

# nodes
var _panel := Node2D.new()
var _bg: ColorRect
var _header: NinePatchRect
var _chev: Sprite2D
var _title: PxText
var _lock: Sprite2D
var _status: PxText
var _pinned: NinePatchRect
var _pin: Sprite2D
var _pinned_text: PxText
var _pinned_badge: NinePatchRect
var _pinned_badge_text: PxText
var _clip := Control.new()
var _content := Node2D.new()
var _composer: NinePatchRect
var _composer_text: PxText
var _thumb: ColorRect
var _fx := Node2D.new()               # seat pips (above everything in the tab)

# thread
var _rows: Array[Dictionary] = []     # built rows: {seq, kind, root, y, h, pills: [], chip, ...}
var _hits: Array[Dictionary] = []     # {rect (content-local), kind: pay|partner|brawl, seq, partner, pill}
var _content_h := 0.0
var _sig := ""
var _scroll := 0.0
var _vel := 0.0
var _stick := true
var _scroll_tw: Tween
var _press: Dictionary = {}
var _last_pad := 0.0

# reveal (typing telegraph + join cascade)
var _upto := -1                       # highest seq shown
var _typing: Dictionary = {}          # {seq, partner, until}
var _next_at := 0.0
var _just_opened := false             # the first reveal step after open()
var _arrive_at: Dictionary = {}       # seq -> ms (arrival tween start)
var _stamp_at: Dictionary = {}        # seq -> ms (stamp slam start)
var _ribbon: Dictionary = {}          # {seq, t} a ceremony in progress
var _shake: Dictionary = {}           # seq -> ms (can't-afford shake start)
var _pips: Array[Dictionary] = []

# audio / events
var _tick_sec: Dictionary = {}        # ultimatum seq -> last displayed second
var _known_state: GameState

# cameo (rtl-map §4.2)
var _cameo := Node2D.new()
var _cameo_strip: SpriteStrip
var _cameo_id := ""
var _cameo_chip: NinePatchRect
var _cameo_clock: Sprite2D
var _cameo_timer: PxText
var _cameo_rect := Rect2()
var _cameo_seq := -1

# the "{n} ממתינים ↑" chip (views dev 2026-09-29): open pills / an open brawl above the viewport
const PENDING_W := 296.0
const PENDING_H := 64.0               # kit button_secondary (a raised button: the chip is a target)
const PENDING_Y := 12.0               # below the thread's top edge (tall-local THREAD_Y + 12)
const PENDING_MARGIN := 16.0          # the item lands this far under the chip
var _pending_root := Node2D.new()
var _pending_bg: NinePatchRect
var _pending_text: PxText
var _pending_arrow: Sprite2D
var _pend_items: Array = []              # content-local items above the viewport, nearest first: {y, seq, kind}
var _pending_rect := Rect2()          # tall-local visual

# the brawl stage cue (views dev 2026-09-29): the brawl cloud under Row B while a brawl is open
# and T3 is closed; tap → T3 at the brawl
const BRAWL_CUE := Rect2(8, 4, 144, 104)      # tall-local visual: a chat_bubble_in plate ...
const BRAWL_CLOUD := Vector2(24, 16)           # ... holding brawl_cloud (52×40) at ×2 (104×80)
const BRAWL_CUE_HIT := Rect2(4, 0, 152, 112)
var _brawl_cue := Node2D.new()
var _brawl_cloud: Sprite2D
var _brawl_seq := -1
var _brawl_cue_t := -1.0                  # ms since the cue appeared (its entry fade), -1 = hidden
var _pending_t := -1.0                    # ms since the pending chip appeared (its entry), -1 = hidden
var _dt_ms := 0.0                         # this frame's dt (the entries above)

## The brawl cloud's boil (motion-spec brawl-cloud; whole art px only): the kit's 4-frame loop at
## 8 fps (125 ms, the 2D Artist's rate) under a 1-ap ring the whole cloud steps around every 100 ms
## (Stepped): (1, 0) → (0, −1) → (−1, 0) → (0, 1). Each 1200 ms period ends on a 300 ms rest at
## (0, 0): the fight breathes, so the loop doesn't fatigue. Reduced motion: frame 0, still.
const BOIL_FRAME_MS := 125.0
const BOIL_STEP_MS := 100.0
const BOIL_PERIOD_MS := 1200.0
const BOIL_REST_MS := 300.0
const BOIL_RING: Array[Vector2i] = [Vector2i(1, 0), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(0, 1)]
const CUE_IN_MS := 150.0                  # the brawl cue's entry (ease-out)
const PENDING_IN_MS := 120.0              # the pending chip's entry (ease-out)


## "m:ss" for a seconds count (the timer chip; LTR digits, CHAT_ULT_TIMER's {mmss}).
static func mmss(sec: float) -> String:
	var n := maxi(0, int(ceilf(sec - 0.001)))
	return "%d:%02d" % [n / 60, n % 60]


static func mc(key: String) -> float:
	if Tune.MC.has(key):
		return float(Tune.MC[key])
	return float(MC_DEFAULTS.get(key, 0.0))


func setup(host_: Node) -> ChatView:
	host = host_
	return self


func _ready() -> void:
	add_child(_cameo)
	_cameo.visible = false
	_cameo_chip = Ui.nine(_cameo, Rect2(0, 0, CHIP_W, CHIP_H), Art.sprite_or("chip_ultimatum"))
	_cameo_clock = Ui.img(_cameo, Vector2.ZERO, Art.sprite_or("icon_clock"), 0, 4)
	_cameo_timer = PxText.make(_cameo, Vector2.ZERO, "", L.TEXT, "plain", "w")
	_cameo_timer.fit_width = 120.0   # rtl-map §0.2: the timer steps down to ×4 in its chip
	add_child(_panel)
	_panel.visible = false
	_bg = Ui.rect(_panel, Rect2(0, 0, L.W, _h), C_THREAD)
	_clip.clip_contents = true
	_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_clip.position = Vector2(0, THREAD_Y)
	_panel.add_child(_clip)
	_clip.add_child(_content)
	_thumb = Ui.rect(_panel, Rect2(4, THREAD_Y, 4, 48), Color(0.788, 0.839, 0.949), 0.0)   # v4 ui_mute
	_build_pending_chip()
	add_child(_brawl_cue)
	_brawl_cue.visible = false
	Ui.nine(_brawl_cue, BRAWL_CUE, Art.sprite_or("chat_bubble_in"))
	# the 2D Artist's 26×20 cue cut at ×4 (4 frames), else the 52×40 brawl cloud at ×2: the same 104×80
	var cue_id := "brawl_cloud_cue" if Art.has_sprite("brawl_cloud_cue") else Art.sprite_or("brawl_cloud")
	_brawl_cloud = Ui.img(_brawl_cue, BRAWL_CLOUD, cue_id, 0, 4 if cue_id == "brawl_cloud_cue" else 2)
	_header = Ui.nine(_panel, Rect2(0, 0, L.W, HEADER_H), Art.sprite_or("chat_header"))
	var chev_id := Art.sprite_or("chat_icon_chevron")
	var cs := Vector2(Art.sprite_size(chev_id)) * 4.0
	_chev = Ui.img(_panel, (CHEVRON_HIT.get_center() - cs / 2.0).snapped(Vector2(4, 4)), chev_id, 0, 4)
	_title = PxText.make(_panel, Vector2(0, 16), Strings.s("CHAT_TITLE"), L.TEXT, "plain", "w")
	_title.right_at(TITLE_RIGHT)
	_lock = Ui.img(_panel, Vector2.ZERO, Art.sprite_or("chat_icon_lock"), 0, 4)
	_status = PxText.make(_panel, Vector2(0, 56), "", L.TEXT, "plain", C_NAME)
	_status.wrap_width = TITLE_RIGHT - 32.0
	_status.max_lines = 1
	_pinned = Ui.nine(_panel, Rect2(0, PINNED_Y, L.W, PINNED_H), Art.sprite_or("chat_pinned"))
	_pin = Ui.img(_panel, Vector2(676, PINNED_Y + 10), Art.sprite_or("chat_icon_pin"), 0, 4)
	_pinned_text = PxText.make(_panel, Vector2(0, PINNED_Y + 10), "", L.TEXT, "plain", C_NAME)
	_pinned_text.wrap_width = 584.0
	_pinned_text.max_lines = 1
	_pinned_text.right_at(660)
	_pinned_badge = Ui.nine(_panel, Rect2(16, 110, 44, 44), Art.sprite_or("badge_count"))
	_pinned_badge_text = PxText.make(_panel, Vector2(16, 110), "!", L.TEXT, "plain", "w")
	_pinned_badge_text.center_in(16, 44)
	_composer = Ui.nine(_panel, Rect2(0, _h - COMPOSER_H, L.W, COMPOSER_H), Art.sprite_or("chat_composer_disabled"))
	_composer_text = PxText.make(_panel, Vector2(0, _h - COMPOSER_H + 24), Strings.s("CHAT_COMPOSER"), L.TEXT, "plain", C_MUTED)
	_composer_text.wrap_width = 640.0
	_composer_text.max_lines = 1
	_composer_text.right_at(680)
	_panel.add_child(_fx)
	relayout()


## The split or the width changed (MainController._relayout): H_T = S + 84 + P; the anchors.
func relayout() -> void:
	position = Vector2(0, -L.stage_h)
	_h = L.stage_h + L.tabs_y()
	if host != null and "_ox" in host:
		_ox = float(host.get("_ox"))
		_vs_w = float((host.get("_vs") as Vector2).x)
	if _bg == null:
		return
	var dx := L.dx
	_bg.position = Vector2(-_ox - 8.0, 0)
	_bg.size = Vector2(_vs_w + 16.0, _h)
	_clip.size = Vector2(L.cw, thread_h())
	Ui.set_nine_rect(_header, Rect2(0, 0, L.cw + 4.0, HEADER_H))
	var cs := Vector2(Art.sprite_size(_chev.get_meta("sprite"))) * 4.0
	_chev.position = (chevron_hit().get_center() - cs / 2.0).snapped(Vector2(4, 4))
	_title.right_at(TITLE_RIGHT + dx)
	_status.right_at(TITLE_RIGHT + dx)
	Ui.set_nine_rect(_pinned, Rect2(0, PINNED_Y, L.cw + 4.0, PINNED_H))
	_pin.position.x = 676.0 + dx
	_pinned_text.wrap_width = 584.0 + dx
	_pinned_text.right_at(660.0 + dx)
	Ui.set_nine_rect(_composer, Rect2(0, _h - COMPOSER_H, L.cw + 4.0, COMPOSER_H))
	_composer_text.wrap_width = 640.0 + dx
	_composer_text.right_at(680.0 + dx)
	_composer_text.position.y = _h - COMPOSER_H + 24
	_cameo.position.x = L.sox()   # the cameo stands in the stage column
	if _state != null:
		_update_header()
	_sig = ""   # the thread's rows re-anchor on the next rebuild
	_rebuild_if_needed(false)
	_set_scroll(_scroll)


## The header's back chevron, R-anchored.
static func chevron_hit() -> Rect2:
	return L.ra(CHEVRON_HIT)


static func pinned_hit() -> Rect2:
	return L.sa(PINNED_HIT)


func thread_h() -> float:
	return maxf(0.0, _h - THREAD_Y - COMPOSER_H)


func is_open() -> bool:
	return _open


# ------------------------------------------------------------------ open / close (motion tall-tab)

## Opens T3. `focus_seq` scrolls to that message (the cameo opens at the ultimatum).
func open(focus_seq: int = -1) -> void:
	if not _open:
		_open = true
		_open_ms = _now
		_just_opened = true
		_panel.visible = true
		_anim = {"kind": "open", "t": 0.0}
		_press = {}
		if _state != null:
			Coalition.on_chat_opened(_state)
		_audio("panelOpen")
		open_changed.emit(true)
		_sig = ""
		_advance_reveal()
		_rebuild_if_needed(true)
		_stick = true
		_scroll = _max_scroll()
	if focus_seq >= 0:
		_scroll_to_seq(focus_seq)


func close() -> void:
	if not _open:
		return
	_open = false
	_press = {}
	_typing = {}
	_ribbon = {}
	_anim = {"kind": "close", "t": 0.0}
	_audio("panelClose")
	open_changed.emit(false)


func toggle() -> void:
	if _open:
		close()
	else:
		open()


func _animate_panel(dt: float) -> void:
	if _anim.is_empty():
		return
	_anim["t"] = float(_anim["t"]) + dt
	var t: float = _anim["t"]
	var opening: bool = _anim["kind"] == "open"
	if reduced_motion:
		var ms := mc("tallTabOpenReducedMs" if opening else "tallTabCloseReducedMs")
		var p := minf(1.0, t / ms)
		_panel.position.y = 0.0
		_panel.modulate.a = p if opening else 1.0 - p
		if p >= 1.0:
			_end_anim(opening)
		return
	_panel.modulate.a = 1.0
	var ms2 := mc("tallTabOpenMs" if opening else "tallTabCloseMs")
	var p2 := minf(1.0, t / ms2)
	var e := Ui.cubic_out(p2) if opening else Ui.quad_in(p2)
	_panel.position.y = Ui.snap(_h * (1.0 - e if opening else e), 4)
	if p2 >= 1.0:
		_end_anim(opening)


func _end_anim(opening: bool) -> void:
	_anim = {}
	_panel.position.y = 0.0
	_panel.modulate.a = 1.0
	if not opening:
		_panel.visible = false


# ------------------------------------------------------------------ per frame

## ctx: {main: bool (main mode, no election transition), overlay: bool (a modal is open)}.
func update_view(dt: float, s: GameState, d: Economy.Derived, ctx: Dictionary = {}) -> void:
	_now += dt
	_dt_ms = dt
	if not is_same(s, _known_state):
		_on_new_state(s)
	_state = s
	_d = d
	var live: bool = ctx.get("main", true)
	_animate_panel(dt)
	if _open and not live:
		close()
	_advance_reveal()
	if live:
		_post_merge_ready()
	_rebuild_if_needed(false)
	_tick_ultimatums(live)
	_update_ribbon(dt)
	if _panel.visible:
		_update_header()
		_update_rows(dt)
		_update_scroll(dt)
		_update_pending()
		_update_pips()
	_update_cameo(dt, live and not bool(ctx.get("overlay", false)))
	_update_brawl_cue(live and not bool(ctx.get("overlay", false)))
	_update_badge()


## mobile-first §5.5 (D46): Golan's merge is his signature rule, and the partner card (its home) is
## never taught; so when a pair first qualifies with the cooldown at 0 (and again after each
## cooldown, at most once per MERGE_READY_GAP_SEC of play) the thread gets a system line
## "CHAT_SYS_MERGE_READY" with the "לאחד" pill under it (512 × 68, hit 536 × 88, centred), which
## opens the same MergeCard with that pair first. The line is a notice, not a demand: it has no
## price and no state, so the sim never expires, trims-protects or pays it.
const MERGE_READY_GAP_SEC := 120.0


## The first qualifying pair [a, b] ([] = none; the rule is off or on cooldown).
static func merge_ready_pair(s: GameState) -> Array:
	if s == null or not Coalition.active() or Coalition.merge_cooldown(s) != 0.0:
		return []
	for p: Dictionary in Coalition.partners():
		var a := str(p["id"])
		var cands := Coalition.merge_candidates(s, a)
		if not cands.is_empty():
			return [a, str(cands[0])]
	return []


func _post_merge_ready() -> void:
	var s := _state
	if s == null or not (s.coalition is Dictionary) or not bool(s.coalition.get("opened", false)):
		return
	var c: Dictionary = s.coalition
	if Coalition.merge_cooldown(s) > 0.0:
		c["mergeReadyArmed"] = true   # a merge ran: the next ready pair is news again
		return
	if c.get("mergeReadyArmed", true) != true:
		return
	if s.run_time_sec - float(c.get("mergeReadyAtSec", -1e9)) < MERGE_READY_GAP_SEC:
		return
	var pair := merge_ready_pair(s)
	if pair.is_empty():
		return
	c["mergeReadyArmed"] = false
	c["mergeReadyAtSec"] = s.run_time_sec
	Coalition._sys(s, "chat.sys.merge_ready", {"a": pair[0], "b": pair[1], "action": "merge"}, [])


## A fresh GameState (boot, reset, import, election seam): everything already in its log counts
## as seen, and the view's per-message memory is dropped.
func _on_new_state(s: GameState) -> void:
	_known_state = s
	_upto = _last_seq(s)
	_typing = {}
	_arrive_at.clear()
	_stamp_at.clear()
	_tick_sec.clear()
	_shake.clear()
	_ribbon = {}
	_pips.clear()
	_sig = ""
	_stick = true


static func _chat(s: GameState) -> Array:
	if s == null or not s.coalition is Dictionary:
		return []
	var c: Variant = (s.coalition as Dictionary).get("chat", [])
	return c if c is Array else []


static func _last_seq(s: GameState) -> int:
	var n := -1
	for m: Dictionary in _chat(s):
		n = maxi(n, int(m.get("seq", -1)))
	return n


## Shows every message now (tests; the cascade skip).
func reveal_all() -> void:
	_upto = _last_seq(_state)
	_typing = {}


func typing() -> Dictionary:
	return _typing


# ------------------------------------------------------------------ reveal: typing + cascade

static func is_partner_bubble(m: Dictionary) -> bool:
	var t := str(m.get("type", ""))
	return (t == "demand" or t == "ultimatum" or t == "thanks" or t == "status") and str(m.get("partner", "")) != ""


func _pending() -> Array:
	var out: Array = []
	for m: Dictionary in _chat(_state):
		if int(m.get("seq", -1)) > _upto:
			out.append(m)
	return out


func _advance_reveal() -> void:
	if _state == null:
		return
	if not _open:
		_typing = {}
		return
	var pend := _pending()
	if pend.is_empty():
		_typing = {}
		_just_opened = false
		return
	if pend.size() > CASCADE_MAX:
		_upto = int(pend[pend.size() - 1]["seq"])
		_typing = {}
		_just_opened = false
		return
	var fresh := _just_opened
	_just_opened = false
	if fresh and not _has_created(pend):
		# opened onto messages that landed while it was closed: they are already written, so no
		# typing telegraph (the timer of an ultimatum is running); only the C1 group creation
		# plays its cascade (ux/ftue.md "chat open cascade")
		_upto = int(pend[pend.size() - 1]["seq"])
		return
	if _now < _next_at:
		return
	var m: Dictionary = pend[0]
	var seq := int(m["seq"])
	if is_partner_bubble(m) and m.get("type", "") != "status":
		if _typing.get("seq", -1) != seq:
			_typing = {"seq": seq, "partner": str(m["partner"]), "until": _now + mc("chatTypingMs")}
			return
		if _now < float(_typing["until"]):
			return
	_typing = {}
	_upto = seq
	_arrive_at[seq] = _now
	if is_partner_bubble(m):
		_audio("chatPing", str(m["partner"]))
	elif str(m.get("type", "")) == "brawl" and str(m.get("state", "")) == "open":
		_audio("chatBrawl")   # Audio v1.3: a brawl landing in the open thread
	_next_at = _now + (0.0 if reduced_motion or m.get("type", "") != "sys" else mc("chatCascadeGapMs"))


static func _has_created(pend: Array) -> bool:
	for m: Dictionary in pend:
		if str(m.get("key", "")) == "chat.sys.created":
			return true
	return false


# ------------------------------------------------------------------ thread model (pure)

## The rows the thread shows for a chat log, oldest first, up to seq `upto`:
## [{seq, kind, partner, first, msg}]. kind: in (a partner bubble), ult (an open or expired
## ultimatum), deleted (a paid ultimatum), out (the player's reply), sys, transfer, brawl.
## `first` = the first bubble of a run from one sender (avatar + name shown; rtl-map §6.3).
static func thread_model(chat: Array, upto: int = 1 << 30) -> Array:
	var out: Array = []
	var prev_partner := ""
	for m: Dictionary in chat:
		if int(m.get("seq", 0)) > upto:
			continue
		var t := str(m.get("type", ""))
		var st := str(m.get("state", ""))
		var kind := ""
		match t:
			"demand", "thanks", "status":
				kind = "in"
			"ultimatum":
				kind = "deleted" if st == "deleted" else "ult"
			"reply":
				kind = "out"
			"sys":
				kind = "sys"
			"transfer":
				kind = "transfer"
			"brawl":
				kind = "brawl" if st == "open" else ""
		if kind == "":
			continue
		var pid := str(m.get("partner", ""))
		var bubble := kind == "in" or kind == "ult" or kind == "deleted"
		var first := bubble and not (pid != "" and pid == prev_partner)
		out.append({"seq": int(m.get("seq", 0)), "kind": kind, "partner": pid, "first": first, "msg": m})
		prev_partner = pid if bubble else ""
	return out


## The header's "{n} משתתפים" (review R22): everyone in the group, i.e. every partner whose status
## is member (frozen and benched included: they are still in the group) or pending (joined, the
## join demand unpaid: the "…הצטרף לקבוצה" line is in the thread), plus the Magician. Not
## Coalition.member_count, which counts only the seats that vote right now.
static func group_size(s: GameState) -> int:
	var n := 1
	if s == null or not Coalition.active():
		return n
	for p: Dictionary in Coalition.partners():
		var st := Coalition.status(s, str(p["id"]))
		if st == "member" or st == "pending":
			n += 1
	return n


static func partner_name(id: String) -> String:
	return str(Coalition.partner(id).get("name", id))


## The partner's line for a bubble: partners[].linesVariants[line][variant] or .lines[line]
## (content copy; the sim holds no Hebrew). {price} is the message's price; Goldknopf's thanks
## falls back to his "after" line, whose {next_price} is the price he asks next.
static func line_text(m: Dictionary, s: GameState, d: Economy.Derived) -> String:
	if m.has("scriptFrom"):
		# a transfer-window line: the text stays in content (copy.transferWindow.script), the save keeps the index
		var tw: Variant = Coalition.partner(str(m["scriptFrom"])).get("copy", {}).get("transferWindow")
		var sc: Array = (tw as Dictionary).get("script", []) if tw is Dictionary else []
		var i := int(m.get("scriptIdx", -1))
		return str((sc[i] as Array)[1]) if i >= 0 and i < sc.size() and sc[i] is Array else ""
	var id := str(m.get("partner", ""))
	var p := Coalition.partner(id)
	var line := str(m.get("line", ""))
	if m.get("type", "") == "thanks" and _pick_line(p, line, 0) == "" and _pick_line(p, "after", 0) != "":
		line = "after"
	var t := _pick_line(p, line, int(m.get("variant", 0)))
	var params := {"price": Fmt.cost(float(m.get("price", 0.0)))}
	if t.contains("{next_price}") and s != null and d != null:
		params["next_price"] = Fmt.cost(Coalition.demand_price(s, id, d))
	return Bidi.fill(t, params)


static func _pick_line(p: Dictionary, line: String, variant: int) -> String:
	var lv: Variant = p.get("linesVariants", {}).get(line) if p.get("linesVariants") is Dictionary else null
	if lv is Array and not (lv as Array).is_empty():
		return str((lv as Array)[posmod(variant, (lv as Array).size())])
	var l: Variant = p.get("lines", {}).get(line) if p.get("lines") is Dictionary else null
	if l is Array and not (l as Array).is_empty():
		return str((l as Array)[posmod(variant, (l as Array).size())])
	return str(l) if l is String else ""


## A system line's text: the UX key from the sim's `key` (chat.sys.left → CHAT_SYS_LEFT_M/_F by
## the partner's gender), with {name}, {to}, {a}, {b}, {n} and Distel's {who} filled.
static func sys_text(m: Dictionary) -> String:
	var key := str(m.get("key", ""))
	var base := key.to_upper().replace(".", "_")
	var pid := str(m.get("partner", ""))
	var p := Coalition.partner(pid)
	var params := {"name": partner_name(pid), "to": partner_name(str(m.get("to", ""))),
		"a": partner_name(str(m.get("a", ""))), "b": partner_name(str(m.get("b", ""))), "n": str(int(m.get("n", 0)))}
	if key == "chat.sys.muted":
		params["who"] = str(p.get("copy", {}).get("mutedWho", "")) if p.get("copy") is Dictionary else ""
	if Strings.has(base + "_M") or Strings.has(base + "_F"):
		return Strings.gendered(base, str(p.get("g", "m")), params)
	if Strings.has(base):
		return Strings.s(base, params)
	return ""


## A chat toast's line 1 (review R5): TOAST_CHAT_HEAD "{name} · בקבוצה".
static func toast_head(pid: String) -> String:
	return Strings.s("TOAST_CHAT_HEAD", {"name": partner_name(pid)})


## A chat toast's face: [art id, logical px per sprite px, density] of the partner's chat avatar
## (["", …] when the partner has no art: the toast then shows no face).
static func toast_avatar(pid: String) -> Array:
	var av := avatar_art(pid)
	if av[0] == Art.PLACEHOLDER:
		return ["", 4.0, 1]
	return [av[0], float(av[1]), maxi(1, int(roundf(float(SpriteStrip.art_scale()) / maxf(0.001, float(av[1])))))]


## The manifest character slug for a partner id: SpriteStrip.resolve (aliases), then the
## content's `avatar` art id without "_avatar". Never a partial-name match: "may-golan" and
## "golan" are different people, so a missing slug draws the neutral card instead.
static func char_for(id: String) -> String:
	var slug := SpriteStrip.resolve(id)
	if slug != "":
		return slug
	# leader select's cast profiles name their art (the generic MKs: "nophoto", never a real face)
	var art := str(Coalition.partner(id).get("art", ""))
	if art != "" and SpriteStrip.resolve(art) != "":
		return SpriteStrip.resolve(art)
	var av := str(Coalition.partner(id).get("avatar", "")).trim_suffix("_avatar")
	return SpriteStrip.resolve(av) if av != "" else ""


## The chat avatar's art id and its logical draw scale (artScale / density; never hard-coded:
## the TA's manifest and CONTRACT §3). "" when the partner has no art yet (the neutral card).
static func avatar_art(id: String) -> Array:
	var slug := char_for(id)
	var c: Dictionary = SpriteStrip.manifest().get("chars", {}).get(slug, {}) if slug != "" else {}
	var art := str(c.get("avatar", "avatar_" + slug)) if slug != "" else ""
	if art == "" or not Art.has_sprite(art):
		return [Art.PLACEHOLDER, 4.0]
	var dens := maxi(1, int(c.get("avatarDensity", Art.kit(art).get("density", 1))))
	return [art, float(SpriteStrip.art_scale()) / float(dens)]


# ------------------------------------------------------------------ build

func _signature() -> String:
	var parts := PackedStringArray()
	parts.append(str(_upto))
	for m: Dictionary in _chat(_state):
		if int(m.get("seq", 0)) <= _upto:
			parts.append("%d%s" % [int(m["seq"]), str(m.get("state", ""))[0] if str(m.get("state", "")) != "" else "_"])
	parts.append(str(Coalition.member_count(_state)) if _state != null and Coalition.active() else "0")
	for pid: String in _statuses():
		parts.append(pid)
	parts.append("L" if PxText.large_text else "")
	return ",".join(parts)


func _statuses() -> PackedStringArray:
	var out := PackedStringArray()
	if _state == null or not Coalition.active():
		return out
	for p: Dictionary in Coalition.partners():
		out.append(Coalition.status(_state, str(p["id"]))[0])
	return out


func _rebuild_if_needed(force: bool) -> void:
	if _state == null or not (_open or _panel.visible or force):
		return
	var sig := _signature()
	if sig == _sig and not force:
		return
	var at_bottom := _stick or _scroll >= _max_scroll() - 4.0
	_sig = sig
	_build_thread()
	if at_bottom:
		_scroll_bottom(not force)


func _build_thread() -> void:
	for c in _content.get_children():
		c.queue_free()
		_content.remove_child(c)
	_rows.clear()
	_hits.clear()
	var model := thread_model(_chat(_state), _upto)
	var y := 16.0
	if not model.is_empty():
		y += _build_day_chip(y) + RUN_GAP   # B11: the thread starts under the header, dated
	if model.is_empty():
		var r := _build_sys(Strings.s("CHAT_EMPTY"), {}, y)
		r["y"] = y          # the empty thread's one row (T3 opened before the group exists)
		r["seq"] = -1
		r["kind"] = "sys"
		_rows.append(r)
		y += float(r["h"])
	var prev_kind := ""
	for i in model.size():
		var row: Dictionary = model[i]
		var gap := 0.0
		if i > 0:
			gap = IN_RUN_GAP if (not row["first"] and prev_kind != "" and ["in", "ult", "deleted"].has(row["kind"])) else RUN_GAP
		y += gap
		var r: Dictionary
		var nh := _hits.size()
		var rx := 0.0
		match String(row["kind"]):
			"in", "ult", "deleted":
				r = _build_bubble(row, y)
				rx = L.dx   # mobile-first §4.1: incoming avatar and bubble, R-anchored
			"out":
				r = _build_out(row, y, prev_kind != "out")
			"sys":
				r = _build_sys(sys_text(row["msg"]), row["msg"], y)
			"transfer":
				r = _build_transfer(row, y)
			"brawl":
				r = _build_brawl(row, y)
				rx = L.sox()   # the brawl slot, centred
		r["x"] = rx
		for hi in range(nh, _hits.size()):
			var hr: Rect2 = _hits[hi]["rect"]
			_hits[hi]["rect"] = Rect2(hr.position.x + rx, hr.position.y, hr.size.x, hr.size.y)
		(r["root"] as Node2D).position.x = rx
		r["seq"] = row["seq"]
		r["kind"] = row["kind"]
		r["first"] = row["first"]
		r["partner"] = row["partner"]
		r["y"] = y
		_rows.append(r)
		y += float(r["h"])
		prev_kind = row["kind"]
	_content_h = y + 16.0


func _lh(t: PxText) -> float:
	return float(HeFont.line_height()) * t.eff_px()


## `reading`: a message body (PxText.reading, the @2 cut where crisp); names, labels, pills and
## dimmed lines stay display text.
func _text(parent: Node, s: String, col: Variant, wrap: float, lines: int, reading: bool = false) -> PxText:
	var t := PxText.make(parent, Vector2.ZERO, s, L.TEXT, "plain", col)
	t.reading = reading
	t.max_lines = lines
	t.wrap_width = wrap
	return t


func _root(y: float) -> Node2D:
	var n := Node2D.new()
	n.position = Vector2(0, y)
	_content.add_child(n)
	return n


## A partner bubble (rtl-map §6.3): avatar 128 at x 576-704 and the name above the bubble on the
## first of a run; the bubble's right edge at 568, width ≤ 480, text column 416; an ultimatum
## gets the hatched kit bubble with "אולטימטום" and the clock chip at its left; an open message
## carries its pay pill, a paid one the "שולם" stamp in the pill's place.
func _build_bubble(row: Dictionary, y: float) -> Dictionary:
	var m: Dictionary = row["msg"]
	var pid := str(row["partner"])
	var kind := str(row["kind"])
	var root := _root(y)
	var r := {"root": root, "pills": [], "chip": null}
	var gone := _state != null and ["left", "removed", "transferred", "absent"].has(Coalition.status(_state, pid))
	var top := 0.0
	if row["first"]:
		var av: Array = avatar_art(pid)
		var sz := Vector2(Art.sprite_size(av[0])) * float(av[1])
		var sc := float(av[1])
		if av[0] == Art.PLACEHOLDER:
			sc = floorf(AVATAR_BOX / maxf(1.0, float(Art.sprite_size(av[0]).x)))
			sz = Vector2(Art.sprite_size(av[0])) * sc
		var img := Ui.img(root, Vector2(AVATAR_RIGHT - sz.x, 0), av[0], 0, 1)
		img.scale = Vector2(sc, sc)
		if gone:
			img.modulate = Color(0.45, 0.45, 0.5)
		r["avatar"] = img
		var nm := _text(root, partner_name(pid), C_NAME, NAME_HIT_W, 1)
		nm.right_at(BUBBLE_RIGHT)
		_hits.append({"rect": Rect2(AVATAR_RIGHT - AVATAR_BOX, y, AVATAR_BOX, AVATAR_BOX), "kind": "partner", "partner": pid})
		_hits.append({"rect": Rect2(BUBBLE_RIGHT - NAME_HIT_W, y - 22.0, NAME_HIT_W, 88), "kind": "partner", "partner": pid})
		top = 44.0
	var ult := kind == "ult"
	var sprite := "chat_bubble_ultimatum" if ult else "chat_bubble_in"
	var pad := Vector4(24, 24, 44, 24) if ult else Vector4(16, 12, 36, 12)   # left, top, right, bottom
	var bubble := Ui.nine(root, Rect2(0, top, 64, 64), Art.sprite_or(sprite))
	if ult and String(Art.kit(sprite).get("mode", "")) == "tile":
		bubble.axis_stretch_horizontal = NinePatchRect.AXIS_STRETCH_MODE_TILE_FIT
		bubble.axis_stretch_vertical = NinePatchRect.AXIS_STRETCH_MODE_TILE_FIT
	var inner_r := BUBBLE_RIGHT - pad.z
	var cy := top + pad.y
	var w := 0.0
	var st := str(m.get("state", ""))
	if ult:
		var lab := _text(root, Strings.s("CHAT_ULTIMATUM"), C_ALERT, 300.0, 1)
		lab.right_at(inner_r)
		lab.position.y = cy + 8.0
		var chip := _make_chip(root, Vector2(0, cy))   # x set once the width is known
		r["chip"] = chip
		w = maxf(w, float(lab.width()) + 16.0 + CHIP_W)
		cy += CHIP_H + 8.0
	if kind != "deleted" and m.get("line", "") == "threat" and _forwarded(pid):
		var fw := _text(root, Strings.s("CHAT_FORWARDED"), C_MUTED, TEXT_W, 1)
		fw.right_at(inner_r)
		fw.position.y = cy
		w = maxf(w, float(fw.width()))
		cy += _lh(fw)
	var body := Strings.s("CHAT_DELETED") if kind == "deleted" else line_text(m, _state, _d)
	var dimmed := (ult and st == "expired") or (kind == "in" and st == "expired")
	var tx := _text(root, body, C_MUTED if kind == "deleted" else Color.WHITE, TEXT_W, 99, kind != "deleted" and not dimmed)
	tx.right_at(inner_r)
	tx.position.y = cy
	if dimmed:
		tx.modulate.a = 0.5
	w = maxf(w, float(tx.width()))
	cy += _lh(tx) * maxf(1.0, float(tx.line_count()))
	var payable := Coalition.is_payable(m) and (st == "open" or st == "paid" or st == "deleted")
	if payable and kind != "deleted":
		cy += 16.0
		var pr := Rect2(inner_r - PILL_W, cy, PILL_W, PILL_H)
		var pill := _make_pill(root, pr, int(m["seq"]), false)
		pill["key"] = "CHAT_CEREMONY" if str(m.get("kind", "")) == "ceremony" else ""   # UX: a 0 ₪ ceremony is not "סגרנו · 0 ₪"
		r["pills"].append(pill)
		w = maxf(w, PILL_W)
		if st == "open":
			_hits.append({"rect": Rect2(pr.get_center().x - PILL_HIT.x / 2.0, y + pr.get_center().y - PILL_HIT.y / 2.0, PILL_HIT.x, PILL_HIT.y),
				"kind": "pay", "seq": int(m["seq"]), "pill": pill})
		cy += PILL_H
		# Liberman's "לא יושב" (rtl-map §6.3 rev 4, spec §5.1 declineDemand): a second pill UNDER
		# the pay pill, the same 328×68, right-aligned, 8 gap, the secondary look (it costs
		# nothing); only on an open member demand, never an ultimatum or a join demand
		if st == "open" and kind == "in" and declinable(_state, m):
			cy += 8.0
			var dr := Rect2(inner_r - PILL_W, cy, PILL_W, PILL_H)
			var db := PxButton.make(root, dr, {"kind": "kit_secondary", "label": Strings.s("CHAT_PILL_DECLINE"), "label_box": PILL_W - 32.0})
			r["declines"] = [{"button": db, "seq": int(m["seq"])}]
			_hits.append({"rect": Rect2(dr.get_center().x - PILL_HIT.x / 2.0, y + dr.get_center().y - PILL_HIT.y / 2.0, PILL_HIT.x, PILL_HIT.y),
				"kind": "decline", "seq": int(m["seq"]), "button": db})
			cy += PILL_H
	var bw := clampf(Ui.snap(w + pad.x + pad.z + 2.0, 4), 96.0, BUBBLE_RIGHT - BUBBLE_MIN_X)
	var bh := Ui.snap(cy + pad.w - top, 4)
	Ui.set_nine_rect(bubble, Rect2(BUBBLE_RIGHT - bw, top, bw, bh))
	if r["chip"] != null:
		(r["chip"]["root"] as Node2D).position.x = BUBBLE_RIGHT - bw + pad.x
	r["bubble"] = bubble
	r["bubbleRect"] = Rect2(BUBBLE_RIGHT - bw, top, bw, bh)
	r["h"] = maxf(top + bh, AVATAR_BOX if row["first"] else 0.0)
	return r


func _forwarded(pid: String) -> bool:
	var cp: Variant = Coalition.partner(pid).get("copy")
	return cp is Dictionary and (cp as Dictionary).get("threatForwarded", false) == true


func _make_chip(parent: Node, at: Vector2) -> Dictionary:
	var root := Node2D.new()
	root.position = at
	parent.add_child(root)
	Ui.nine(root, Rect2(0, 0, CHIP_W, CHIP_H), Art.sprite_or("chip_ultimatum"))
	var clock := Ui.img(root, Vector2(CHIP_W - 48.0, 8), Art.sprite_or("icon_clock"), 0, 4)
	var t := PxText.make(root, Vector2(12, 8), "", L.TEXT, "plain", "w")
	t.fit_width = 120.0   # chat.timer (rtl-map §0.2)
	return {"root": root, "clock": clock, "text": t, "lastSec": -1, "nudgeAt": -1e9, "y0": at.y, "urgent": false}


## A pay pill (kit pay_pill_*): gold + "סגרנו · {price} ₪" when affordable, the sunken track with a
## dim fill growing from the right + "חסר {n} ₪" otherwise; "שולם" stamp once paid. `wide` = the
## rejoin / poach pill on a system line.
func _make_pill(parent: Node, pr: Rect2, seq: int, wide: bool) -> Dictionary:
	var nine := Ui.nine(parent, pr, Art.sprite_or("pay_pill_default"))
	var fill := Ui.nine(parent, Rect2(pr.end.x - 16, pr.position.y + 16, 8, pr.size.y - 28), Art.sprite_or("pay_pill_fill"))
	var lab := _text(parent, "", C_INK, pr.size.x - 32.0, 1)
	lab.position.y = pr.position.y + 12.0
	var stamp_id := Art.sprite_or("stamp_paid_dark_rot" if Art.has_sprite("stamp_paid_dark_rot") else "stamp_paid_dark")
	var stamp := Ui.img(parent, Vector2.ZERO, stamp_id, 0, 4)
	stamp.centered = true
	var ssz := Vector2(Art.sprite_size(stamp_id)) * 4.0
	stamp.position = Vector2(pr.end.x - ssz.x / 2.0, pr.get_center().y).snapped(Vector2(4, 4)) if not wide else pr.get_center().snapped(Vector2(4, 4))
	stamp.visible = false
	return {"nine": nine, "fill": fill, "label": lab, "stamp": stamp, "rect": pr, "seq": seq, "wide": wide,
		"pressed": false, "key": "", "base": pr.position}


## The player's reply (rtl-map §6.3: x 16, left). B11: the first reply of a run is headed by the
## round's leader's short name, left-aligned over the bubble (C_NAME, as a partner's name), so the
## reply reads as a message in its own row, not a chip loose at the edge.
func _build_out(row: Dictionary, y: float, named: bool = true) -> Dictionary:
	var m: Dictionary = row["msg"]
	var root := _root(y)
	var n := clampi(int(m.get("n", 1)), 1, 3)
	var top := 0.0
	var who := LeaderUi.short() if named else ""
	if who != "":
		var nm := _text(root, who, C_NAME, NAME_HIT_W, 1)
		nm.position = Vector2(20.0, 0.0)
		top = OUT_NAME_H
	var bubble := Ui.nine(root, Rect2(16, top, 64, 64), Art.sprite_or("chat_bubble_out"))
	var tx := _text(root, Strings.s("CHAT_REPLY_%d" % n), Color.WHITE, TEXT_W, 99, true)
	var tw := float(tx.width())
	var bw := clampf(Ui.snap(tw + 36.0 + 16.0 + 2.0, 4), 96.0, 480.0)
	tx.right_at(16.0 + bw - 16.0)
	tx.position.y = top + 12.0
	var bh := Ui.snap(12.0 + _lh(tx) * maxf(1.0, float(tx.line_count())) + 12.0, 4)
	Ui.set_nine_rect(bubble, Rect2(16, top, bw, bh))
	return {"root": root, "pills": [], "h": top + bh, "bubbleRect": Rect2(16, top, bw, bh)}


## B11: the day chip at the top of the thread (CHAT_TODAY, chat.divider box), centred on the canvas:
## the navy system pill, smaller and quieter than a system line. Returns its height.
func _build_day_chip(y: float) -> float:
	var root := _root(y)
	var navy := Art.has_sprite("chat_system_pill_navy")
	var bg := Ui.nine(root, Rect2(0, 0, 64, 52), "chat_system_pill_navy" if navy else Art.sprite_or("chat_system_pill"))
	var tx := _text(root, Strings.s("CHAT_TODAY"), C_SYS_TEXT if navy else Color.WHITE, 480.0, 1)
	var w := Ui.snap(float(tx.width()) + 64.0, 4)
	var h := Ui.snap(_lh(tx) + 12.0, 4)   # the system pill's metrics (6 over, 6 under the line)
	var x := Ui.snap((L.cw - w) / 2.0, 4)
	Ui.set_nine_rect(bg, Rect2(x, 0, w, h))
	tx.position = Vector2(x + 32.0, 6.0)
	tx.h_anchor = 0
	return h


## A centred system pill (≤ 600 wide, ≤ 2 lines); a "left" line carries the rejoin pill, a
## "removed" line with payable = poach the poach pill; the brawl's after-line the corridor count.
func _build_sys(text: String, m: Dictionary, y: float) -> Dictionary:
	var root := _root(y)
	var r := {"root": root, "pills": []}
	# review U7: the v4 thread's system pill is a flat ui_scrim well, ui_rule edge, ui_mute label
	var navy := Art.has_sprite("chat_system_pill_navy")
	var pill_bg := Ui.nine(root, Rect2(0, 0, 64, 52), "chat_system_pill_navy" if navy else Art.sprite_or("chat_system_pill"))
	var icon_w := 0.0
	var icon: Sprite2D = null
	if str(m.get("key", "")) == "chat.sys.muted" and Art.has_sprite("chat_icon_mute"):
		icon = Ui.img(root, Vector2.ZERO, "chat_icon_mute", 0, 4)
		icon_w = float(Art.sprite_size("chat_icon_mute").x) * 4.0 + 12.0
	var tx := _text(root, text, C_SYS_TEXT if navy else Color.WHITE, SYS_TEXT_W - icon_w, 2, true)
	tx.align = 1
	var lines := maxf(1.0, float(tx.line_count()))
	var w := Ui.snap(float(tx.width()) + icon_w + 48.0, 4)
	var h := Ui.snap(_lh(tx) * lines + 12.0, 4)
	var x := Ui.snap((L.cw - w) / 2.0, 4)
	Ui.set_nine_rect(pill_bg, Rect2(x, 0, w, h))
	tx.position = Vector2(x + 24.0, 6.0)
	tx.h_anchor = 0
	if icon != null:
		icon.position = Vector2(x + w - 24.0 - icon_w + 12.0, Ui.snap((h - 36.0) / 2.0, 4))
	var cy := h
	var payable := str(m.get("payable", ""))
	var st := str(m.get("state", ""))
	if payable != "" and (st == "open" or st == "paid"):
		cy += 16.0
		var pr := Rect2(L.cx(WIDE_PILL.position.x), cy, WIDE_PILL.size.x, WIDE_PILL.size.y)
		var pill := _make_pill(root, pr, int(m["seq"]), true)
		pill["key"] = "CHAT_SYS_REJOIN" if payable == "rejoin" else "CHAT_SYS_POACH"
		r["pills"].append(pill)
		if st == "open":
			_hits.append({"rect": Rect2(pr.get_center().x - 268.0, y + pr.get_center().y - 44.0, 536, 88), "kind": "pay",
				"seq": int(m["seq"]), "pill": pill})
		cy += PILL_H
	if str(m.get("action", "")) == "merge":
		cy += 16.0
		var mr := Rect2(L.cx(WIDE_PILL.position.x), cy, WIDE_PILL.size.x, WIDE_PILL.size.y)
		var mb := PxButton.make(root, mr, {"kind": "kit_secondary", "label": Strings.s("CHAT_PILL_MERGE"), "label_box": mr.size.x - 32.0})
		r["merges"] = [{"button": mb, "a": str(m.get("a", "")), "b": str(m.get("b", ""))}]
		_hits.append({"rect": Rect2(mr.get_center().x - 268.0, y + mr.get_center().y - 44.0, 536, 88), "kind": "merge",
			"seq": int(m.get("seq", -1)), "a": str(m.get("a", "")), "b": str(m.get("b", "")), "button": mb})
		cy += PILL_H
	if str(m.get("key", "")) == "chat.brawl.after":
		var cc := _text(root, "", C_MUTED, 300.0, 1)
		cc.position.y = cy + 8.0
		r["corridor"] = cc
		cy += 8.0 + _lh(cc)
	r["h"] = cy
	return r


## Gotliv's transfer (kit transfer_banner 720×120 full bleed + transfer_card under it).
func _build_transfer(row: Dictionary, y: float) -> Dictionary:
	var m: Dictionary = row["msg"]
	var root := _root(y)
	Ui.nine(root, Rect2(0, 0, L.cw, 120), Art.sprite_or("transfer_banner"))
	var card := Ui.nine(root, Rect2(16, 128, 688.0 + L.dx, 64), Art.sprite_or("transfer_card"))
	var nm := PxText.make(root, Vector2(0, 148), partner_name(str(m.get("partner", ""))), L.TEXT + 1, "plain", C_GOLD_HI)
	nm.wrap_width = 640.0
	nm.max_lines = 1
	nm.right_at(672.0 + L.dx)
	var ln := _text(root, Strings.s("CHAT_TRANSFER_LINE", {"from": partner_name(str(m.get("partner", ""))), "to": partner_name(str(m.get("to", "")))}), Color.WHITE, 640.0, 2, true)
	ln.right_at(672.0 + L.dx)
	ln.position.y = 148.0 + _lh(nm) + 4.0
	var ch := Ui.snap(20.0 + _lh(nm) + 4.0 + _lh(ln) * maxf(1.0, float(ln.line_count())) + 16.0, 4)
	Ui.set_nine_rect(card, Rect2(16, 128, 688.0 + L.dx, ch))
	return {"root": root, "pills": [], "h": 128.0 + ch}


## The brawl: the cloud slot inline, 208×160 centred (rtl-map answer to the Animator), then the
## "צאו החוצה" button (visual 312×80, hit 336×88).
func _build_brawl(row: Dictionary, y: float) -> Dictionary:
	var root := _root(y)
	var cloud := Ui.img(root, Vector2(256, 0), Art.sprite_or("brawl_cloud"), 0, 4)
	var btn := PxButton.make(root, Rect2(204, 168, 312, 80), {"hit": Rect2(192, 164, 336, 88), "label": Strings.s("CHAT_BRAWL_BTN"), "kind": "kit_secondary"})
	_hits.append({"rect": Rect2(192, y + 164, 336, 88), "kind": "brawl", "seq": int(row["seq"]), "button": btn})
	return {"root": root, "pills": [], "h": 256.0, "cloud": cloud, "cloudAt": cloud.position, "button": btn}


## The boil pose at `t_ms`: {frame, off (ap)}. Pure (tests: whole px, the rest, reduced motion).
static func brawl_boil(t_ms: float, frames: int, reduced: bool) -> Dictionary:
	if reduced:
		return {"frame": 0, "off": Vector2i.ZERO}
	var ph := fmod(maxf(0.0, t_ms), BOIL_PERIOD_MS)
	var off := Vector2i.ZERO
	if ph < BOIL_PERIOD_MS - BOIL_REST_MS:
		off = BOIL_RING[int(ph / BOIL_STEP_MS) % BOIL_RING.size()]
	return {"frame": int(maxf(0.0, t_ms) / BOIL_FRAME_MS) % maxi(1, frames), "off": off}


## Poses a brawl cloud sprite around its rest position; `scale` = logical px per ring step (4: one stage art px).
func _boil(cl: Sprite2D, at: Vector2, scale: float) -> void:
	var id: String = cl.get_meta("sprite")
	var b := brawl_boil(_now, Art.frame_count(id), reduced_motion)
	Ui.set_frame(cl, id, int(b["frame"]))
	cl.position = at + Vector2(b["off"]) * scale


# ------------------------------------------------------------------ live updates

func _update_header() -> void:
	if _state == null:
		return
	var txt := ""
	if not _typing.is_empty():
		var pid := str(_typing["partner"])
		txt = Strings.gendered("CHAT_TYPING", str(Coalition.partner(pid).get("g", "m")), {"name": partner_name(pid)})
	else:
		var k := Coalition.threat_count(_state) if Coalition.active() else 0
		if k > 0:
			txt = Strings.plural("CHAT_THREATS", k, {"k": str(k)})
		else:
			txt = Strings.plural("CHAT_MEMBERS", group_size(_state))
	_status.text = txt
	_status.right_at(TITLE_RIGHT + L.dx)
	_lock.position = Vector2(Ui.snap(TITLE_RIGHT + L.dx - float(_title.width()) - 12.0 - float(Art.sprite_size(_lock.get_meta("sprite")).x) * 4.0, 4), 20)
	_pinned_text.text = Strings.s("CHAT_PINNED", {"n": str(_state.evolutions + 1)})
	var agreement := _state.evolutions >= 1
	var badge := agreement and Meta.can_buy_any_perk(_state)
	_pinned_badge.visible = badge
	_pinned_badge_text.visible = badge


func _update_rows(dt: float) -> void:
	var bps := _d.bps if _d != null else 0.0
	for r: Dictionary in _rows:
		var seq := int(r.get("seq", -1))
		var root: Node2D = r["root"]
		# arrival (motion chat-message-arrival)
		var base_x := 0.0
		var base_y := 0.0
		var a := 1.0
		if _arrive_at.has(seq):
			var t := _now - float(_arrive_at[seq])
			var ms := mc("chatBubbleInMs")
			if t >= ms + 100.0:
				_arrive_at.erase(seq)
			elif reduced_motion:
				a = minf(1.0, t / 120.0)
			else:
				var p := minf(1.0, t / ms)
				var off := mc("chatBubbleInOffsetPx") * (1.0 - Ui.quad_out(p))
				match String(r.get("kind", "")):
					"in", "ult", "deleted", "transfer":
						base_x = Ui.snap(off, 4)
					"out":
						base_x = -Ui.snap(off, 4)
					_:
						base_y = Ui.snap(off / 2.0, 4)
				a = p
				if r.get("kind", "") == "ult" and t > ms:
					base_y = Ui.snap(4.0 * (1.0 - Ui.quad_out(minf(1.0, (t - ms) / 100.0))), 4)   # the 1-ap thud
		root.position = Vector2(float(r.get("x", 0.0)) + base_x, float(r.get("y", 0.0)) + base_y)
		root.modulate.a = a
		for pill: Dictionary in r["pills"]:
			_update_pill(pill, bps)
		for dc: Dictionary in r.get("declines", []):
			_update_decline(dc)
		for mg: Dictionary in r.get("merges", []):
			# live: enabled while that pair (or any) can still merge; the cooldown's seconds otherwise
			var b: PxButton = mg["button"]
			var cd := Coalition.merge_cooldown(_state)
			var t := Strings.s("CHAT_PILL_MERGE_CD", {"s": str(int(ceilf(cd)))}) if cd > 0.0 else Strings.s("CHAT_PILL_MERGE")
			if b.label != null and b.label.text != t:
				b.set_label(t)
			b.set_enabled(cd == 0.0 and not merge_ready_pair(_state).is_empty())
		if r.get("chip") != null:
			_update_chip(r["chip"], Coalition.message(_state, seq), dt)
		if r.has("corridor"):
			(r["corridor"] as PxText).text = Strings.s("CHAT_CORRIDOR_COUNT", {"n": str(int(_state.coalition.get("corridorMsgs", 0)))})
			(r["corridor"] as PxText).center_in(0, L.cw)
		if r.has("cloud"):
			_boil(r["cloud"], r["cloudAt"], 4.0)


## A member demand Liberman may decline (Coalition.can_decline without the cooldown): the pill is
## drawn on every such demand, disabled with the seconds during the cooldown (rtl-map §6.3).
static func declinable(s: GameState, m: Dictionary) -> bool:
	if s == null or Coalition.decline_cooldown(s) < 0.0:
		return false
	return str(m.get("type", "")) == "demand" and m.get("join", false) != true and str(m.get("payable", "")) == "" \
		and Coalition.status(s, str(m.get("partner", ""))) == "member"


func _update_decline(dc: Dictionary) -> void:
	var b: PxButton = dc["button"]
	var m := Coalition.message(_state, int(dc["seq"]))
	var open := str(m.get("state", "")) == "open"
	b.set_visible(open)
	if not open:
		return
	var cd := Coalition.decline_cooldown(_state)
	var t := Strings.s("CHAT_PILL_DECLINE_CD", {"s": str(int(ceilf(cd)))}) if cd > 0.0 else Strings.s("CHAT_PILL_DECLINE")
	if b.label != null and b.label.text != t:
		b.set_label(t)
	b.set_enabled(cd <= 0.0)


## "לא יושב": the sim closes the demand for free (Coalition.decline); its sys line and events go
## through the chat's one router.
func decline(seq: int) -> bool:
	if _state == null:
		return false
	var r := Coalition.decline(_state, seq)
	if r.get("ok", false) != true:
		if r.get("reason", "") == "cooldown":
			_audio("cantAfford")
		return false
	_audio("decline")   # Audio v1.3 cue (cue-spec §4.1)
	for e: Variant in r.get("events", []):
		if e is Dictionary:
			on_politics_event(e)
	if host != null and host.has_method("_mark_dirty"):
		host.call("_mark_dirty")
	return true


## Golan's "איחוד": merges b into a (Coalition.merge); the sys line is chat.sys.merged.
func merge(a: String, b: String) -> bool:
	if _state == null:
		return false
	var r := Coalition.merge(_state, a, b)
	if r.get("ok", false) != true:
		_audio("cantAfford")
		return false
	_audio("merge")   # Audio v1.3 cue (cue-spec §4.1)
	for e: Variant in r.get("events", []):
		if e is Dictionary:
			on_politics_event(e)
	if host != null and host.has_method("_mark_dirty"):
		host.call("_mark_dirty")
	return true


func _update_pill(pill: Dictionary, _bps: float) -> void:
	var seq := int(pill["seq"])
	var m := Coalition.message(_state, seq)
	var st := str(m.get("state", ""))
	var nine: NinePatchRect = pill["nine"]
	var fill: NinePatchRect = pill["fill"]
	var lab: PxText = pill["label"]
	var stamp: Sprite2D = pill["stamp"]
	var pr: Rect2 = pill["rect"]
	if st != "open":
		nine.visible = false
		fill.visible = false
		lab.visible = false
		var paid := st == "paid" or st == "deleted"
		stamp.visible = paid
		if paid:
			var sc := 4.0
			if _stamp_at.has(seq) and not reduced_motion:
				var t := _now - float(_stamp_at[seq])
				sc = 6.0 if t < 33.0 else (5.0 if t < mc("stampSlamMs") * 0.75 else 4.0)
				stamp.modulate.a = 0.6 if t < 33.0 else 1.0
				if t > 400.0:
					_stamp_at.erase(seq)
			stamp.scale = Vector2(sc, sc)
		return
	stamp.visible = false
	nine.visible = true
	lab.visible = true
	var price := float(m.get("price", 0.0))
	var have := _state.bananas
	var afford := have >= price
	var ribbon := not _ribbon.is_empty() and int(_ribbon["seq"]) == seq
	var sprite := "pay_pill_pressed" if (afford and pill["pressed"]) else ("pay_pill_default" if afford else "pay_pill_track")
	Ui.set_nine_frame(nine, Art.sprite_or(sprite), 0)
	var dx := 0.0
	if _shake.has(seq):
		var t2 := _now - float(_shake[seq])
		if t2 >= 180.0:
			_shake.erase(seq)
		elif not reduced_motion:
			dx = 4.0 if int(t2 / 45.0) % 2 == 0 else -4.0
	var dy := 8.0 if pill["pressed"] and afford else 0.0
	Ui.set_nine_rect(nine, Rect2(pr.position + Vector2(dx, dy / 2.0), pr.size - Vector2(0, dy / 2.0)))
	var inner := Rect2(pr.position + Vector2(8, 16), pr.size - Vector2(16, 28))
	var frac := 0.0
	if ribbon:
		frac = clampf(float(_ribbon["t"]) / CEREMONY_MS, 0.0, 1.0)
	elif not afford and price > 0.0:
		frac = clampf(have / price, 0.0, 1.0)
	fill.visible = frac > 0.0 and (ribbon or not afford)
	if fill.visible:
		var w := maxf(8.0, Ui.snap(inner.size.x * frac, 4))
		Ui.set_nine_rect(fill, Rect2(L.bar_x(inner, w) + dx, inner.position.y, w, inner.size.y))
	var text := ""
	var key := str(pill.get("key", ""))
	if ribbon and key == "CHAT_CEREMONY":
		text = Strings.s("CHAT_CEREMONY_CUTTING")   # rtl-map §6.3: "גוזרים…" while the ribbon fills
	elif afford or ribbon:
		text = Strings.s(key if key != "" else "CHAT_PAY", {"price": Fmt.cost(price)})
	else:
		text = Strings.s("CHAT_PAY_SHORT", {"n": Fmt.cost(ceilf(price - have))}) if key == "" else Strings.s(key, {"price": Fmt.cost(price)})
	lab.text = text
	lab.tint = C_INK if afford else Color.WHITE
	lab.center_in(pr.position.x + dx, pr.size.x)
	lab.position.y = pr.position.y + 12.0 + dy / 2.0


## The ultimatum chip (motion chat-ultimatum-countdown): digits cut once per displayed second;
## ≤ 10 s a 1-ap nudge on each tick, ≤ 3 s on every half second (2 Hz, with the Audio's doubled
## ticks); the clock hand steps per second. Deviation, stated: the digits stay white. The spec's
## "alert palette index" is red, and red digits on the kit's red chip (white 4.7:1) would not read.
func _update_chip(chip: Dictionary, m: Dictionary, _dt: float) -> void:
	var left := float(m.get("leftSec", 0.0))
	var open := str(m.get("state", "")) == "open"
	var secs := int(ceilf(left - 0.001)) if open else 0
	var t: PxText = chip["text"]
	t.text = Strings.s("CHAT_ULT_TIMER", {"mmss": mmss(float(secs))})
	chip["urgent"] = open and secs <= int(mc("ultimatumUrgentFromSec"))
	var half := int(ceilf(left * 2.0 - 0.001)) if open else 0
	if bool(chip["urgent"]) and half != int(chip.get("lastHalf", -1)) and not reduced_motion:
		chip["nudgeAt"] = _now
	chip["lastHalf"] = half
	if secs != int(chip["lastSec"]):
		chip["lastSec"] = secs
		if open and secs <= int(mc("ultimatumNudgeFromSec")) and not reduced_motion:
			chip["nudgeAt"] = _now
		var clock: Sprite2D = chip["clock"]
		Ui.set_frame(clock, clock.get_meta("sprite"), 0 if reduced_motion else posmod(-secs, maxi(1, Art.frame_count(clock.get_meta("sprite")))))
	var root: Node2D = chip["root"]
	# review R23: an ultimatum that ran out (or was superseded) keeps no red "0:00": the chip goes
	# grey (C_MUTED) and dims to the bubble's 50%
	var spent := not open
	if bool(chip.get("spent", false)) != spent:
		chip["spent"] = spent
		for n: Node in root.get_children():
			if n is CanvasItem:
				(n as CanvasItem).material = grey_material() if spent else null
		root.modulate = Color(1, 1, 1, 0.5) if spent else Color.WHITE
	var nt := _now - float(chip["nudgeAt"])
	root.position.y = float(chip["y0"]) + (Ui.snap(4.0 * (1.0 - Ui.quad_out(minf(1.0, nt / 100.0))), 4) if nt < 100.0 else 0.0)


static var _grey: ShaderMaterial


## A spent ultimatum chip's look: every pixel to its luminance, tinted toward C_MUTED (slate), so
## the kit's red chip and its white digits read as one grey, inactive piece.
static func grey_material() -> ShaderMaterial:
	if _grey == null:
		var sh := Shader.new()
		sh.code = """shader_type canvas_item;
uniform vec3 tint = vec3(0.49, 0.514, 0.596);
void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	float l = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	COLOR = vec4(tint * (0.55 + 0.9 * l), c.a);
}"""
		_grey = ShaderMaterial.new()
		_grey.shader = sh
	return _grey


func _update_badge() -> void:
	if host == null or not "shop" in host or host.get("shop") == null or _state == null:
		return
	var n := 0
	if Coalition.active():
		for m: Dictionary in _chat(_state):
			# an open brawl counts too: its two rows stay frozen (out of the 61) until "צאו החוצה"
			if str(m.get("state", "")) == "open" and (Coalition.is_payable(m) or str(m.get("type", "")) == "brawl"):
				n += 1
	var txt := "" if (n <= 0 or _open) else Strings.s("TAB_BADGE", {"count": "9+" if n > 9 else str(n)})
	(host.get("shop") as Shop).set_tab_badge(3, txt)


## One ultimatumTick per displayed second of every open ultimatum (the Audio adds the half-second
## ticks in the last 3 s). The sim pauses ultimatums while hidden, so the ticks do too.
func _tick_ultimatums(live: bool) -> void:
	if _state == null or not Coalition.active():
		return
	for m: Dictionary in _chat(_state):
		if m.get("type", "") != "ultimatum" or m.get("state", "") != "open":
			continue
		var seq := int(m["seq"])
		var secs := int(ceilf(float(m.get("leftSec", 0.0)) - 0.001))
		if int(_tick_sec.get(seq, -1)) != secs:
			var first := not _tick_sec.has(seq)
			_tick_sec[seq] = secs
			if live and not first:
				_audio("ultimatumTick", secs)


func _update_ribbon(dt: float) -> void:
	if _ribbon.is_empty():
		return
	_ribbon["t"] = float(_ribbon["t"]) + dt
	if float(_ribbon["t"]) >= CEREMONY_MS:
		var seq := int(_ribbon["seq"])
		_ribbon = {}
		pay(seq, true)


# ------------------------------------------------------------------ player actions

## Pays an open demand / ultimatum / rejoin / poach line through the sim. A ceremony (Regev)
## first runs its 3 s ribbon on the pill, then pays. Returns true when the sim took the money.
func pay(seq: int, ceremony_done: bool = false) -> bool:
	if _state == null:
		return false
	var m := Coalition.message(_state, seq)
	if m.is_empty() or str(m.get("state", "")) != "open":
		return false
	if str(m.get("kind", "money")) == "ceremony" and not ceremony_done:
		if _ribbon.is_empty():
			_ribbon = {"seq": seq, "t": 0.0}
			_audio("uiClick")
		return false
	var was_ult := str(m.get("type", "")) == "ultimatum"
	var r := Coalition.pay(_state, seq, ceremony_done)
	if not r.get("ok", false):
		if r.get("reason", "") == "funds":
			_shake[seq] = _now
			_audio("cantAfford")
		return false
	_audio("stamp")
	if was_ult:
		_audio("ultimatumPaid")
	_stamp_at[seq] = _now
	_tick_sec.erase(seq)
	_next_at = _now + mc("chatReplyDelayMs")
	_launch_pips(seq, str(r.get("partner", "")))
	for e: Variant in r.get("events", []):
		if e is Dictionary:
			on_politics_event(e)
	if host != null and host.has_method("_mark_dirty"):
		host.call("_mark_dirty")
	return true


func resolve_brawl(seq: int) -> void:
	if _state == null:
		return
	for e: Variant in Coalition.resolve_brawl(_state, seq):
		if e is Dictionary:
			on_politics_event(e)
	_audio("uiClick")
	if host != null and host.has_method("_mark_dirty"):
		host.call("_mark_dirty")


## Politics events the chat voices (MainController routes every Politics.tick event here).
func on_politics_event(e: Dictionary) -> void:
	match String(e.get("ev", "")):
		"message":
			var msg: Dictionary = e.get("msg", {})
			if not _open and is_partner_bubble(msg) and (msg.get("type", "") == "demand" or msg.get("type", "") == "ultimatum"):
				_audio("chatPing", str(msg.get("partner", "")))
				if host != null and "toasts" in host and host.get("toasts") != null:
					var tt: Toasts = host.get("toasts")
					if tt.has_method("show_chat_toast"):
						var pid := str(msg.get("partner", ""))
						tt.show_chat_toast(toast_head(pid), line_text(msg, _state, _d), toast_avatar(pid))
			elif not _open and str(msg.get("type", "")) == "brawl":
				# the brawl freezes two rows until "צאו החוצה" (a button inside T3 only): with the
				# chat closed, say so on the stage (a tap opens T3), and the tab badge counts it
				_audio("chatBrawl")   # Audio v1.3: the brawl's own ping (two voices at once)
				if host != null and "toasts" in host and host.get("toasts") != null:
					(host.get("toasts") as Toasts).show_toast(sys_text({"key": "chat.sys.brawl", "a": msg.get("a", ""), "b": msg.get("b", "")}), "chat")
		"partnerPaid":
			if host != null and host.has_method("on_partner_paid"):
				host.call("on_partner_paid", str(e.get("partner", "")), str(e.get("payable", "")))
		"partnerLeft":
			var pid := str(e.get("partner", e.get("id", "")))
			if _ultimatum_ran_out(pid):
				_audio("ultimatumZero")
			else:
				_audio("chatLeft", pid)


## True when the partner's newest ultimatum just ran out (its timer hit 0:00).
func _ultimatum_ran_out(pid: String) -> bool:
	var chat := _chat(_state)
	for i in range(chat.size() - 1, -1, -1):
		var m: Dictionary = chat[i]
		if m.get("type", "") == "ultimatum" and str(m.get("partner", "")) == pid:
			return m.get("state", "") == "expired" and float(m.get("leftSec", 1.0)) <= 0.001
	return false


func _audio(name: String, arg: Variant = null) -> void:
	if host != null and host.has_method("audio_event"):
		host.call("audio_event", name, arg)


# ------------------------------------------------------------------ seat pips (motion seat-pip-flight)

func _launch_pips(seq: int, pid: String) -> void:
	if reduced_motion or host == null or not "_top_y" in host:
		return
	var pill := _pill_of(seq)
	if pill.is_empty():
		return
	var row := _row_of(seq)
	var p0 := Vector2(0, THREAD_Y + _content.position.y + float(row.get("y", 0.0))) + (pill["rect"] as Rect2).get_center()
	var tr: Rect2 = TopBar.track_rect()
	var si := Coalition.seat_info(_state)
	var frac := clampf(float(si["effective"]) / maxf(1.0, float(si["gateSeats"])), 0.0, 1.0)
	var head_x := tr.end.x - 4.0 - (tr.size.x - 8.0) * frac
	var top_to_tall := float(host.get("_top_y")) - (float(host.get("_lower_y")) - L.stage_h)
	var p2 := Vector2(head_x, tr.get_center().y + top_to_tall)
	var seats := int(Coalition.partner(pid).get("seats", 0))
	var k := mini(maxi(1, seats), int(mc("seatPipMax")))
	if seats <= 0:
		return
	var ctrl := Vector2(p0.x + 0.3 * (p2.x - p0.x), minf(p0.y, p2.y) - 160.0)
	for i in k:
		var n := Ui.rect(_fx, Rect2(0, 0, 12, 12), C_SKY)
		n.visible = false
		_pips.append({"node": n, "t0": _now + mc("stampSlamMs") + i * mc("seatPipStaggerMs"), "p0": p0, "c": ctrl, "p2": p2})


func _update_pips() -> void:
	for i in range(_pips.size() - 1, -1, -1):
		var pp: Dictionary = _pips[i]
		var n: ColorRect = pp["node"]
		var t := (_now - float(pp["t0"])) / mc("seatPipFlightMs")
		if t < 0.0:
			continue
		if t >= 1.0:
			n.queue_free()
			_pips.remove_at(i)
			continue
		var u := Ui.quad_in(t)
		var a: Vector2 = pp["p0"]
		var c: Vector2 = pp["c"]
		var b: Vector2 = pp["p2"]
		var q := a.lerp(c, u).lerp(c.lerp(b, u), u)
		n.visible = true
		n.position = (q - Vector2(6, 6) - _panel.position).snapped(Vector2(4, 4))


func _pill_of(seq: int) -> Dictionary:
	for r: Dictionary in _rows:
		for p: Dictionary in r["pills"]:
			if int(p["seq"]) == seq:
				return p
	return {}


func _row_of(seq: int) -> Dictionary:
	for r: Dictionary in _rows:
		if int(r.get("seq", -1)) == seq:
			return r
	return {}


# ------------------------------------------------------------------ scroll

func _max_scroll() -> float:
	return maxf(0.0, _content_h + bottom_pad() - thread_h())


## rtl-map §6.4 "Depth" (review R21): while the court card is expanded over T3 the thread pads its
## bottom by the part of the card above the composer, so the newest bubble and its pill scroll
## clear of the card.
func bottom_pad() -> float:
	var c := CourtView.of(host)
	return maxf(0.0, c.pad_height() - COMPOSER_H) if c != null and _open else 0.0


func _set_scroll(v: float) -> void:
	_scroll = clampf(v, 0.0, _max_scroll())


func _scroll_bottom(animate: bool) -> void:
	var target := _max_scroll()
	_stick = true
	if _scroll_tw:
		_scroll_tw.kill()
	if not animate or reduced_motion or not is_inside_tree():
		_scroll = target
		return
	_scroll_tw = create_tween()
	_scroll_tw.tween_method(func(v: float) -> void: _set_scroll(v), _scroll, target, mc("chatScrollMs") / 1000.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)


func _scroll_to_seq(seq: int) -> void:
	_rebuild_if_needed(false)
	var r := _row_of(seq)
	if r.is_empty():
		return
	_stick = false
	_set_scroll(float(r["y"]) + float(r["h"]) - thread_h() + 24.0)


func _update_scroll(dt: float) -> void:
	if _press.is_empty() and _vel != 0.0:
		_set_scroll(_scroll + _vel * (dt / Tune.FRAME_MS))
		_vel *= pow(float(Tune.MC.get("listMomentumDecay", 0.92)), dt / Tune.FRAME_MS)
		if absf(_vel) < float(Tune.MC.get("listMomentumStop", 0.1)):
			_vel = 0.0
	var pad := bottom_pad()
	if pad != _last_pad:
		_last_pad = pad
		if _stick and _press.is_empty():
			_scroll = _max_scroll()   # the card came or went: the newest stays in view
		else:
			_set_scroll(_scroll)
	# B11 (mobile-first §5.5.1): content shorter than the thread starts under the header (the day
	# chip first), like a new conversation; once it overflows, the newest stays at the bottom (the
	# stick-to-bottom scroll, rtl-map §6.3), above the court card when it is expanded over the tab
	_content.position.y = Ui.snap(-_scroll, 4)
	var th := thread_h()
	var scrollable := _content_h + pad > th
	_thumb.visible = scrollable
	if scrollable:
		var tl := maxf(48.0, th * th / (_content_h + pad))
		_thumb.size.y = Ui.snap(tl, 4)
		_thumb.position.y = Ui.snap(THREAD_Y + (th - tl) * (_scroll / maxf(1.0, _max_scroll())), 4)
		var dragging: bool = not _press.is_empty() and _press.get("dragging", false)
		_thumb.modulate.a = 1.0 if (dragging or _vel != 0.0) else 0.35


func wheel(dy: float) -> void:
	_stick = false
	_set_scroll(_scroll + signf(dy) * float(Tune.MC.get("wheelNotchPx", 104)))
	if _scroll >= _max_scroll() - 4.0:
		_stick = true


# ------------------------------------------------------------------ input (MainController routes `_lower`-local points)

## A `_lower`-local point in tall-local space (the panel's open/close slide included).
func _tall(p: Vector2) -> Vector2:
	return p - position - (_panel.position if _open else Vector2.ZERO)


## The thread point (content-local) under a tall-local point, or (-1, -1) outside the thread.
func _content_pt(q: Vector2) -> Vector2:
	if q.y < THREAD_Y or q.y >= THREAD_Y + thread_h():
		return Vector2(-1, -1)
	return Vector2(q.x, q.y - THREAD_Y - _content.position.y)


## True when the chat (or the cameo) takes this press.
func pointer_down(p: Vector2) -> bool:
	var q := _tall(p)
	if not _open:
		if _cameo.visible and Ui.in_rect(_cameo_rect, q):
			_press = {"kind": "cameo"}
			return true
		if _brawl_cue.visible and Ui.in_rect(BRAWL_CUE_HIT, q):
			_press = {"kind": "brawlCue"}
			return true
		return false
	if q.y < 0.0 or q.y >= _h:
		return false
	_vel = 0.0
	if _scroll_tw:
		_scroll_tw.kill()
	var ready := _now - _open_ms >= INPUT_AFTER_OPEN_MS
	_press = {"kind": "thread", "y0": q.y, "x0": q.x, "scroll0": _scroll, "dragging": false, "lastY": q.y, "lastT": _now, "vel": 0.0, "hit": {}}
	if Ui.in_rect(chevron_hit(), q):
		_press["kind"] = "chevron"
		return true
	if Ui.in_rect(pinned_hit(), q) and q.y < THREAD_Y:
		_press["kind"] = "pinned"
		return true
	if _pending_root.visible and ready and Ui.in_rect(pending_hit(), q):
		_press["kind"] = "pending"
		return true
	var c := _content_pt(q)
	if c.y < 0.0 or not ready:
		return true
	for h: Dictionary in _hits:
		if Ui.in_rect(h["rect"], c):
			_press["hit"] = h
			if h["kind"] == "pay":
				(h["pill"] as Dictionary)["pressed"] = true
			elif h["kind"] == "brawl" or h["kind"] == "decline":
				(h["button"] as PxButton).down()
			break
	return true


func pointer_move(p: Vector2) -> void:
	if _press.is_empty() or _press["kind"] != "thread":
		return
	var q := _tall(p)
	var dt := maxf(1.0, _now - float(_press["lastT"]))
	if not _press["dragging"] and q.distance_to(Vector2(_press["x0"], _press["y0"])) > float(L.SHOP["moveCancelPx"]):
		_press["dragging"] = true
		_release_hit(false)
	if _press["dragging"]:
		var s0 := _scroll
		_set_scroll(float(_press["scroll0"]) - (q.y - float(_press["y0"])))
		_press["vel"] = (_scroll - s0) / (dt / Tune.FRAME_MS)
		_stick = _scroll >= _max_scroll() - 4.0
	_press["lastY"] = q.y
	_press["lastT"] = _now


func pointer_up(p: Vector2) -> void:
	var pr := _press
	_press = {}
	if pr.is_empty():
		return
	var q := _tall(p)
	match String(pr["kind"]):
		"cameo":
			if Ui.in_rect(_cameo_rect, q):
				open(_cameo_seq)
		"brawlCue":
			if Ui.in_rect(BRAWL_CUE_HIT, q):
				_audio("uiClick")
				open(_brawl_seq)
		"pending":
			if Ui.in_rect(pending_hit(), q):
				_audio("uiClick")
				scroll_to_pending()
		"chevron":
			if Ui.in_rect(chevron_hit(), q):
				close()
		"pinned":
			if Ui.in_rect(pinned_hit(), q) and _state != null and _state.evolutions >= 1 and host != null and host.has_method("_open_perks"):
				host.call("_open_perks")   # rtl-map §7.3: the agreement's home after the first election
		"thread":
			if pr["dragging"]:
				_vel = float(pr["vel"]) if absf(float(pr["vel"])) > float(Tune.MC.get("listMomentumStop", 0.1)) else 0.0
				return
			var h: Dictionary = pr["hit"]
			if h.is_empty():
				return
			var inside := Ui.in_rect(h["rect"], _content_pt(q))
			_press = {"hit": h}
			_release_hit(inside)
			_press = {}


func _release_hit(commit: bool) -> void:
	var h: Dictionary = _press.get("hit", {})
	if h.is_empty():
		return
	_press["hit"] = {}
	match String(h["kind"]):
		"pay":
			(h["pill"] as Dictionary)["pressed"] = false
			if commit:
				pay(int(h["seq"]))
		"brawl":
			(h["button"] as PxButton).up(commit)
			if commit:
				resolve_brawl(int(h["seq"]))
		"decline":
			(h["button"] as PxButton).up(false)
			if commit:
				decline(int(h["seq"]))
		"merge":
			(h["button"] as PxButton).up(false)
			if commit and (h["button"] as PxButton).is_enabled():
				var a := str(h["a"])
				var b := str(h["b"])
				if not Coalition.can_merge(_state, a, b):
					var pair := merge_ready_pair(_state)
					if pair.is_empty():
						return
					a = str(pair[0])
					b = str(pair[1])
				open_merge_card(a, b)
		"partner":
			if commit:
				open_partner_card(str(h["partner"]))


## The partner card (rtl-map §6.3): a modal over T3 through the overlay stack.
func open_partner_card(pid: String) -> void:
	if host == null or not "overlays" in host or pid == "":
		return
	var mgr: OverlayManager = host.get("overlays")
	if mgr == null or mgr.is_open():
		return
	_audio("panelOpen")
	var chat := self
	mgr.request(func() -> Overlay:
		var o := PartnerCard.new()
		o.setup(host, mgr)
		o.chat = chat
		o.partner_id = pid
		return o.build())


## Golan's pair prompt (rule.copy.pickPrompt "לאחד עם…"): one button per partner `a` can merge
## with now (Coalition.merge_candidates); a pick merges them.
func open_merge_card(a: String, first: String = "") -> void:
	if host == null or not "overlays" in host:
		return
	var mgr: OverlayManager = host.get("overlays")
	if mgr == null or mgr.is_open():
		return
	var chat := self
	mgr.request(func() -> Overlay:
		var o := MergeCard.new()
		o.setup(host, mgr)
		o.chat = chat
		o.partner_id = a
		o.first = first
		return o.build())


## Test / key hook: the hit rects of the current thread (content-local).
func hits() -> Array[Dictionary]:
	return _hits


func rows() -> Array[Dictionary]:
	return _rows


## A tall-local point on the screen for a content-local point (tests aim taps with it).
func content_to_tall(c: Vector2) -> Vector2:
	return Vector2(c.x, c.y + THREAD_Y + _content.position.y)


# ------------------------------------------------------------------ the pending chip

func _build_pending_chip() -> void:
	_panel.add_child(_pending_root)
	_pending_root.visible = false
	_pending_bg = Ui.nine(_pending_root, Rect2(0, 0, PENDING_W, PENDING_H), Art.sprite_or("button_secondary_default"))
	_pending_text = PxText.make(_pending_root, Vector2(0, 12), "", L.TEXT, "plain", Color.WHITE)
	_pending_text.fit_width = 216.0   # chat.pending (rtl-map §0.2 step-down)
	_pending_arrow = Sprite2D.new()
	_pending_arrow.texture = up_arrow_texture()
	_pending_arrow.centered = false
	_pending_arrow.scale = Vector2(4, 4)
	_pending_arrow.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_pending_root.add_child(_pending_arrow)


## The ↑ as a 7×9 pixel icon (the font has no U+2191), white like the chip's text. An engine
## stand-in until the kit ships `chat_icon_up`.
const UP_ARROW := ["...w...", "..www..", ".wwwww.", "wwwwwww", "..www..", "..www..", "..www..", "..www..", "..www.."]


static func up_arrow_texture() -> Texture2D:
	if Art.has_sprite("chat_icon_up"):
		return Art.tex("chat_icon_up", 0)
	var img := Image.create(7, 9, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in UP_ARROW.size():
		for x in 7:
			if UP_ARROW[y][x] == "w":
				img.set_pixel(x, y, Color("#f7f4ec"))
	return ImageTexture.create_from_image(img)


## The open items (the pay pills of open lines, the brawl's "צאו החוצה") whose whole hit lies above
## `top` (content-local), nearest first: [{y (the item's top), seq, kind}]. Pure.
static func pending_above(hits: Array, top: float) -> Array:
	var out: Array = []
	for h: Dictionary in hits:
		if h.get("kind", "") != "pay" and h.get("kind", "") != "brawl":
			continue
		var r: Rect2 = h["rect"]
		if r.end.y <= top + 0.5:
			out.append({"y": r.position.y, "seq": int(h.get("seq", -1)), "kind": str(h["kind"])})
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["y"]) > float(b["y"]))
	return out


## The content-local y of the thread viewport's top edge.
func view_top() -> float:
	return -_content.position.y


func _update_pending() -> void:
	_pend_items = pending_above(_hits, view_top()) if _open and _anim.is_empty() else []
	var show := not _pend_items.is_empty()
	_pending_root.visible = show
	if not show:
		_pending_rect = Rect2()
		_pending_t = -1.0
		return
	# the entry: 120 ms Quad.Out, a 1-ap drop into place with the fade (reduced motion: the fade only);
	# the exit is a cut: it goes the moment nothing is left above
	_pending_t = maxf(0.0, _pending_t) + _dt_ms
	var pin := Ui.quad_out(minf(1.0, _pending_t / PENDING_IN_MS))
	_pending_root.modulate.a = pin
	var n := _pend_items.size()
	var t := Strings.plural("CHAT_PENDING", n, {"n": str(n)})
	if _pending_text.text != t:
		_pending_text.text = t
	var tw := float(_pending_text.width())
	var w := Ui.snap(maxf(PENDING_W, tw + 28.0 + 12.0 + 48.0), 4)
	var x := Ui.snap((L.cw - w) / 2.0, 4)
	_pending_rect = Rect2(x, THREAD_Y + PENDING_Y, w, PENDING_H)
	Ui.set_nine_rect(_pending_bg, Rect2(Vector2.ZERO, _pending_rect.size))
	_pending_root.position = _pending_rect.position - Vector2(0, 0.0 if reduced_motion else Ui.snap(4.0 * (1.0 - pin), 4))
	# RTL: the text at the right, the ↑ (the string's end) at its left, the pair centred
	var x1 := Ui.snap((w + tw + 12.0 + 28.0) / 2.0, 4)
	_pending_text.right_at(x1)
	_pending_arrow.position = Vector2(Ui.snap(x1 - tw - 12.0 - 28.0, 4), 8.0)


## The chip's hit (tall-local): its visual grown to 88 tall and 16 wider.
func pending_hit() -> Rect2:
	if _pending_rect.size == Vector2.ZERO:
		return Rect2()
	return Rect2(_pending_rect.position.x - 8.0, _pending_rect.position.y - 16.0, _pending_rect.size.x + 16.0, 88.0)


## Test / driver hook: {visible, n, rect (tall-local), seq of the nearest}.
func pending_info() -> Dictionary:
	return {"visible": _pending_root.visible, "n": _pend_items.size(), "rect": _pending_rect,
		"seq": int(_pend_items[0]["seq"]) if not _pend_items.is_empty() else -1}


## The chip's tap: the nearest item above slides in just under the chip (the chip goes away once
## nothing is left above).
func scroll_to_pending() -> void:
	if _pend_items.is_empty():
		return
	var target := clampf(float(_pend_items[0]["y"]) - PENDING_Y - PENDING_H - PENDING_MARGIN, 0.0, _max_scroll())
	_stick = false
	_vel = 0.0
	if _scroll_tw:
		_scroll_tw.kill()
	if reduced_motion or not is_inside_tree():
		_set_scroll(target)
		return
	_scroll_tw = create_tween()
	_scroll_tw.tween_method(func(v: float) -> void: _set_scroll(v), _scroll, target, mc("chatScrollMs") / 1000.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)


# ------------------------------------------------------------------ the brawl stage cue

## While a brawl is open and T3 is closed, the brawl cloud (kit brawl_cloud, its 4-frame loop at
## 150 ms, frame 0 under reduced motion) in a chat bubble (kit chat_bubble_in: "it is in the chat")
## stands under Row B at the stage's top-left: the seats it
## froze are Row B's, and a tap opens T3 at the brawl. It yields to the toast dock (a toast over it
## hides it) and to any modal. ×2 (104×80) is a stated deviation from the ×4 grid: the kit cloud is
## 52×40 art, and ×4 would take a third of the stage (→ 2d-artist: a 26×20 cut drawn at ×4).
func _update_brawl_cue(allowed: bool) -> void:
	var m := Coalition.open_brawl(_state) if _state != null and Coalition.active() else {}
	var toast := Rect2()
	if host != null and "toasts" in host and host.get("toasts") != null:
		toast = (host.get("toasts") as Toasts).covered_rect()
	var cue_stage := Rect2(BRAWL_CUE.position + Vector2(-L.sox(), float(L.STAGE["y"])), BRAWL_CUE.size)   # the toast dock is stage-local
	var show := allowed and not _open and not _panel.visible and not m.is_empty() and not toast.intersects(cue_stage)
	_brawl_cue.visible = show
	_brawl_seq = int(m.get("seq", -1)) if show else -1
	# the entry: a 150 ms fade (Quad.Out); the exit is a cut (the brawl resolved or T3 opened on it)
	_brawl_cue_t = (maxf(0.0, _brawl_cue_t) + _dt_ms) if show else -1.0
	_brawl_cue.modulate.a = Ui.quad_out(minf(1.0, _brawl_cue_t / CUE_IN_MS)) if show else 1.0
	if show:
		# the ring steps one STAGE art px (4 logical), not one of the ×2 cloud's: 2 logical is 1.5
		# device px at k 3, and the cloud would shimmer between texel phases
		_boil(_brawl_cloud, BRAWL_CLOUD, 4.0)


func brawl_cue_visible() -> bool:
	return _brawl_cue.visible


# ------------------------------------------------------------------ the ultimatum cameo (rtl-map §4.2)

## The newest open ultimatum's partner stands in the stage's right column with the timer chip
## above the head while the chat is closed. Tap → T3 at that ultimatum. Deviation, stated: the
## body draws at art ×3 when it fits (the spec's Magician − 1), else ×2, else it is skipped; the
## spec reserves ×2 for S < 560, but at ×3 the chip no longer fits under the toast dock at S 640.
func _update_cameo(dt: float, allowed: bool) -> void:
	var m := _newest_open_ultimatum()
	var show := allowed and not _open and not _panel.visible and not m.is_empty() and _state != null
	if show:
		var pid := str(m["partner"])
		var slug := char_for(pid)
		if slug == "":
			show = false
		elif _cameo_id != slug:
			if _cameo_strip != null:
				_cameo_strip.queue_free()
			_cameo_strip = SpriteStrip.make(_cameo, slug, Vector2.ZERO, "idle")
			_cameo_id = slug
			_cameo.move_child(_cameo_chip, -1)
			_cameo.move_child(_cameo_clock, -1)
			_cameo.move_child(_cameo_timer, -1)
		if show and _cameo_strip != null:
			var feet := Vector2(644, L.stage_h - 140.0)
			var fh := float(_cameo_strip._c.get("frameH", 0)) / float(_cameo_strip.density)   # art px
			var room := feet.y - 140.0 - CHIP_H - 8.0    # between the toast dock bottom and S − 140
			# ×3 / ×2, each lowered to the largest scale that stays whole device px on one of the
			# figure's densities (SpriteStrip.crisp_art_px: ×3 at k 6 is 4.5 dp, so 8/3 = 4 dp on the d 2)
			var dens := SpriteStrip.densities_of(slug)
			var a3 := SpriteStrip.crisp_art_px(3.0, dens)
			var a2 := SpriteStrip.crisp_art_px(2.0, dens)
			var art := a3 if fh * a3 <= room else (a2 if fh * a2 <= room else 0.0)
			if art <= 0.0:
				show = false
			else:
				if not is_equal_approx(_cameo_strip.art_px, art):
					_cameo_strip.set_art_px(art)   # re-picks the density variant for art ×art
				_cameo_strip.position = feet
				_cameo_strip.update_view(dt)
				var h := fh * art
				_cameo_rect = Rect2(568.0 + L.sox(), feet.y - h, 152, h)   # tall-local (the node sits at the stage column)
				_cameo_seq = int(m["seq"])
				var chip_pos := Vector2(Ui.snap(644.0 - CHIP_W / 2.0, 4), Ui.snap(feet.y - h - CHIP_H - 8.0, 4))
				Ui.set_nine_rect(_cameo_chip, Rect2(chip_pos, Vector2(CHIP_W, CHIP_H)))
				_cameo_clock.position = chip_pos + Vector2(CHIP_W - 48.0, 8)
				var secs := int(ceilf(float(m.get("leftSec", 0.0)) - 0.001))
				_cameo_timer.text = Strings.s("CHAT_ULT_TIMER", {"mmss": mmss(float(secs))})
				_cameo_timer.position = chip_pos + Vector2(12, 8)
				Ui.set_frame(_cameo_clock, _cameo_clock.get_meta("sprite"), 0 if reduced_motion else posmod(-secs, maxi(1, Art.frame_count(_cameo_clock.get_meta("sprite")))))
	_cameo.visible = show
	if not show:
		_cameo_rect = Rect2()


func _newest_open_ultimatum() -> Dictionary:
	if _state == null or not Coalition.active():
		return {}
	var chat := _chat(_state)
	for i in range(chat.size() - 1, -1, -1):
		var m: Dictionary = chat[i]
		if m.get("type", "") == "ultimatum" and m.get("state", "") == "open":
			return m
	return {}


func cameo_visible() -> bool:
	return _cameo.visible


func cameo_rect() -> Rect2:
	return _cameo_rect


# =============================================================================================
# The partner card: a modal over T3 (depth 2), 624 wide: the figure idling at an integer scale,
# the name, seats, and the partner's open demand pill if any. ✕ top-left + "סגור". A partner who
# left shows greyed at f0 (the Animator's `gone` state).
# =============================================================================================

class PartnerCard:
	extends Overlay
	var chat: ChatView
	var partner_id := ""
	var _strip: SpriteStrip
	var _pay: PxButton
	var _merge: PxButton
	var _seq := -1
	## The card's pay pill (a ChatView pill dictionary) and the rows' value texts (tests read them).
	var pill: Dictionary = {}
	## The figure's art scale (×4 / ×3 / ×2, picked per device k; tests read it).
	var fig_scale := 3
	var row_value: Array = []

	func build() -> PartnerCard:
		id = "PARTNER_CARD"
		var th := Art.theme
		var p := Coalition.partner(partner_id)
		var slug := ChatView.char_for(partner_id)
		var s: GameState = chat._state
		var st := Coalition.status(s, partner_id) if s != null else "absent"
		var gone := ["left", "removed", "transferred", "absent"].has(st)
		var fig_h := 0.0
		var dens := 1
		if slug != "":
			var c: Dictionary = SpriteStrip.manifest()["chars"][slug]
			dens = maxi(1, int(c.get("density", SpriteStrip.manifest().get("density", 1))))
			# the figure's art scale as the flash picks Dubi's (FlashCard.pick_art_scale): of ×4/×3/×2
			# the largest that fits the card and draws whole device px on one of the char's densities
			# (k 4 and k 6: ×4, exact 2×2 blocks on d 2 / d 3), else the largest that fits
			var all_dens: Array = [dens]
			for dk: Variant in c.get("densities", {}):
				all_dens.append(int(str(dk)))
			var art_h := float(c.get("frameH", 0)) / float(dens)
			var art_w := float(c.get("frameW", 0)) / float(dens)
			fig_scale = FlashCard.pick_art_scale(Display.k, all_dens, func(sc: int) -> bool:
				return art_w * sc <= 560.0 and 104.0 + art_h * sc + 24.0 + 104.0 + 208.0 + 120.0 <= float(L.H) - 32.0, [4, 3, 2])
			fig_h = art_h * float(fig_scale)
		var om := Coalition.open_msg(s, partner_id) if s != null else {}
		var mergeable := s != null and Coalition.merge_cooldown(s) >= 0.0 and st == "member"
		var h := 104.0 + fig_h + 24.0 + 52.0 + 52.0 + (104.0 if not om.is_empty() else 0.0) + (104.0 if mergeable else 0.0) + 120.0
		var y := Ui.snap((L.H - h) / 2.0, 4)
		var pr := Rect2(48, y, 624, h)
		make_panel(pr)
		var close := close_button(Rect2(pr.position.x + 16, pr.position.y + 16, 64, 64), Rect2(pr.position.x, pr.position.y, 104, 104), func() -> void: cancel("close"))
		var title := text(Vector2(0, y + 32.0), ChatView.partner_name(partner_id), L.TEXT, th["modal"]["title"])
		title.wrap_width = 432.0
		title.max_lines = 1
		title.center_in(pr.position.x + 96.0, 432.0)
		var cy := y + 104.0
		if slug != "":
			_strip = SpriteStrip.make(panel, slug, Vector2(360, cy + fig_h), "idle")
			if _strip != null:
				_strip.set_art_px(float(fig_scale))   # the density variant picked for this card's device px per art px
				if gone:
					_strip.paused = true
					_strip.play("idle")
					_strip.modulate = Color(0.45, 0.45, 0.5)
		cy += fig_h + 24.0
		# rtl-map §6.3 rows (review R12): the label right-aligned at the card's right − 32, its value
		# 16 px left of it, both in the body colour
		var seats := str(Coalition.row_seats(s, partner_id) if s != null else int(p.get("seats", 0)))
		row_value = []
		row_value.append(_row(cy, Strings.s("HUD_SEATS"), seats, pr, th["modal"]["body"]))
		cy += 52.0
		var up_label := Strings.s("PARTNER_UPKEEP") if Strings.has("PARTNER_UPKEEP") else ""
		row_value.append(_row(cy, up_label, "−%d%%" % int(roundf(float(p.get("upkeepPct", 0.0)))), pr, th["modal"]["body"]))
		cy += 52.0
		if not om.is_empty():
			_seq = int(om["seq"])
			# the thread's own pill (ChatView._make_pill / _update_pill): the same states, the
			# ceremony's "לגזור סרט ✂" → "גוזרים…" and its ribbon fill; a ghost button takes the input
			var vis := Rect2(Ui.snap(360.0 - ChatView.PILL_W / 2.0, 4), cy + 16.0, ChatView.PILL_W, ChatView.PILL_H)
			pill = chat._make_pill(panel, vis, _seq, false)
			pill["key"] = "CHAT_CEREMONY" if str(om.get("kind", "")) == "ceremony" else ""
			_pay = PxButton.make(panel, vis, {"hit": vis.grow_individual(12, 10, 12, 10), "ghost": true, "on_commit": func() -> void:
				# a ceremony only starts its ribbon here: the card stays open and its pill fills
				if chat.pay(_seq):
					cancel("close")})
			focusables.append(_pay)
			cy += 104.0
		if mergeable:
			# Golan's "לאחד" (spec §5.1 mergeMembers; rule.copy): opens the pair prompt
			var mv := Rect2(Ui.snap(360.0 - ChatView.PILL_W / 2.0, 4), cy + 16.0, ChatView.PILL_W, ChatView.PILL_H)
			_merge = PxButton.make(panel, mv, {"hit": mv.grow_individual(12, 10, 12, 10), "kind": "kit_secondary",
				"label": Strings.s("CHAT_PILL_MERGE"), "label_box": ChatView.PILL_W - 32.0, "on_commit": func() -> void:
					var who := partner_id
					var c := chat
					cancel("close")
					c.open_merge_card(who)})
			focusables.append(_merge)
			cy += 104.0
		button(Rect2(88, pr.end.y - 112.0, 544, 96), Rect2(88, pr.end.y - 112.0, 544, 96), Strings.s("SYS_CLOSE"),
			func() -> void: cancel("close"), "kit_secondary", L.TEXT)
		focusables.append(close)
		_sync_pay()
		return self

	## A row: the label right-aligned at the card's right − 32, the value right-aligned 16 px left
	## of the label's left edge (a missing label keeps the value at the label's place). Returns
	## the value's text node.
	func _row(y: float, label: String, value: String, pr: Rect2, col: Variant) -> PxText:
		var right := pr.end.x - 32.0
		if label != "":
			var l := text(Vector2(0, y), label, L.TEXT, col)
			l.wrap_width = 400.0   # string-budgets partner.label
			l.max_lines = 1
			l.right_at(right)
			right = l.position.x - float(l.width()) - 16.0
		var v := text(Vector2(0, y), value, L.TEXT, col)
		v.right_at(right)
		return v

	func _sync_pay() -> void:
		if _pay == null or chat == null or chat._state == null:
			return
		var m := Coalition.message(chat._state, _seq)
		if not pill.is_empty():
			pill["pressed"] = _pay._pressed
			chat._update_pill(pill, 0.0)
		_pay.set_enabled(str(m.get("state", "")) == "open")

	func update_view(dt_ms: float) -> void:
		if _strip != null and not _strip.paused:
			_strip.update_view(dt_ms)
		_sync_pay()
		_sync_merge()

	## The merge pill: disabled with the seconds during the cooldown, or when nobody can merge yet.
	func _sync_merge() -> void:
		if _merge == null or chat == null or chat._state == null:
			return
		var cd := Coalition.merge_cooldown(chat._state)
		var t := Strings.s("CHAT_PILL_MERGE_CD", {"s": str(int(ceilf(cd)))}) if cd > 0.0 else Strings.s("CHAT_PILL_MERGE")
		if _merge.label != null and _merge.label.text != t:
			_merge.set_label(t)
		_merge.set_enabled(cd <= 0.0 and not Coalition.merge_candidates(chat._state, partner_id).is_empty())

	func cancel(via: String) -> void:
		host.audio_event("panelClose")
		mgr.close(self, via)


## Golan's pair prompt (a SheetCard): "לאחד עם…", then one full-width button per candidate.
class MergeCard extends SheetCard:
	var chat: ChatView
	var partner_id := ""
	var picked := ""
	## The pair's other member to list first (the thread's merge-ready line, mobile-first §5.5).
	var first := ""

	func build() -> MergeCard:
		id = "MERGE_CARD"
		_begin()
		title(Strings.s("MERGE_PICK_TITLE"))
		para(ChatView.partner_name(partner_id), C_MUTED, true, 1)
		close_x(func() -> void: cancel("close"))
		var cands: Array = Coalition.merge_candidates(chat._state, partner_id) if chat != null and chat._state != null else []
		if first != "" and cands.has(first):
			cands.erase(first)
			cands.push_front(first)
		_y = Ui.snap(_y - PARA_GAP + PAD, 4)
		for b: Variant in cands:
			var bid := str(b)
			_specs.append([Rect2(88, _y, 544, BTN_H), ChatView.partner_name(bid), "kit_primary", func() -> void:
				picked = bid
				if chat.merge(partner_id, bid):
					mgr.close(self, "merge")])
			_y += BTN_H + BTN_GAP
		_specs.append([Rect2(88, _y, 544, BTN_H), Strings.s("SYS_CLOSE"), "kit_secondary", func() -> void: cancel("close")])
		_y += BTN_H
		finish()
		focus_index = 0
		return self

	func cancel(via: String) -> void:
		host.audio_event("panelClose")
		mgr.close(self, via)
