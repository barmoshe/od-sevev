class_name FlashCard
extends Overlay
## O3b, Dubi's news flash after each election (ux/rtl-map.md §7.2 "StoryOverlay → O3b Dubi flash",
## first-minute §1.1, copy deck §B; motion state-graph-dubi.md §5 "O3b"). It replaces the fork's
## 560-px story card, which could not hold the mic Dubi (`chars["dubi-mic"]`, 96 art px tall, d 3).
##
## The card (modal space, 624 wide at x 48, centred in the visible band):
##   header band   the kit `sheet_modal` title band (22 art = 88): the beat title (story.titles),
##                 or STORY_EVOLUTION for the encore rounds
##   news screen   576 wide, a crop of the round's stage art behind Dubi at an integer art scale,
##                 feet under a lower third: kit `ticker_bar` + the red `ticker_flash_plate` with
##                 HEADLINE_TITLE "מבזק", and TITLE_ROUND "סבב בחירות מס׳ n" (copy deck §B header)
##   body          the beat's lines, right-aligned in the modal.body box (560, ≤ 4 lines each),
##                 revealed one by one (motion flashLineStaggerMs / flashLineInMs)
##   buttons       §7.1 stacked: FLASH_NEXT (primary) over FLASH_SKIP (secondary); an archive
##                 replay (T4) has SYS_CLOSE only. Backdrop / Esc / back = FLASH_SKIP.
##
## Dubi's scale: ×4, ×3 or ×2 art px (always an integer art scale). Of the ones that fit the band,
## the largest that makes one sprite px a whole number of device px wins (k 4 → ×3 = 1 dp, k 6 →
## ×4 = 2 dp, k 8 → ×3 = 2 dp); with none (k 2, 7) the largest that fits, on SpriteStrip's "aa"
## filter. The size and density come from the manifest (sprites.json), never from here.
##
## Talk: the beak follows the Audio's `dubi_blip` (state-graph-dubi §3): talk.f1 for 60 ms per
## blip, then talk.f0; idle again 250 ms after the last blip.
## Audio: `storyCard` (the dubiFlash head) and `babble(text)` with the lines shown, when the card
## is built (= when it is actually on screen; a queued card waits). `babble` is the Audio's
## flash kind (after the head, a 'down' squawk), not `headline`, which is the ticker's rationed
## kind (≤ 1 per 20 s, an 'up' squawk) and would drop a flash that follows a milestone headline.
## Word salad: every Dubi talking point shown goes through `dubi_says()`, which asks the sim
## (`Story.roll_word_salad`, which counts `wordSaladSeen`) and may scramble it (live flashes only;
## an archive replay shows the beat as broadcast).

const CARD_X := 48.0
const CARD_W := 624.0
const HEADER_H := 88.0               # sheet_modal title band (slice top 22 art)
const SCREEN_X := 72.0
const SCREEN_W := 576.0
const SCREEN_FRAME := 4.0            # 1 art px of ink around the screen
const HEADROOM := 16.0               # screen top → Dubi's head
const FEET_UP := 12.0                # Dubi's feet above the screen bottom (under the lower third)
const LOWER_H := 56.0                # kit ticker_flash_plate 14 art
const PLATE_W := 128.0               # kit ticker_flash_plate 32 art
const TEXT_RIGHT := 640.0            # modal.body box x 80-640 (560)
const TEXT_W := 560.0
const TEXT_LINES := 4
const LINE_GAP := 8.0
const BTN := Rect2(88, 0, 544, 96)   # §7.1 stacked, full width
const BTN_GAP := 16.0
const PAD := 24.0
const BAND_MARGIN := 16.0
const ART_SCALES := [4, 3, 2]
const TALK_OPEN_MS := 60.0           # state-graph-dubi §3
const TALK_IDLE_MS := 250.0
const C_BODY := Color("#f7f4ec")     # white label on the sheet (kit note)
const C_TITLE := Color("#f7f4ec")
const C_LOWER := Color("#d6d0e6")    # silver on the ticker bar

var evolutions := 1
var archive := false
## The audio events this card sent, [[name, arg], …] (tests read it).
var sent: Array = []
var art_scale := 3
var strip: SpriteStrip
var lines: Array[PxText] = []
var line_texts: PackedStringArray = []
var next_button: PxButton
var skip_button: PxButton
var screen_rect := Rect2()
var _stage: Sprite2D
var _t := 0.0
var _talk_open := 0.0
var _talk_idle := 0.0
var _k := 0

## Word-salad dice (Story.roll_word_salad / word_salad); tests pin it.
static var rng: Callable = randf
## Dubi's talking points this session, oldest first (the salad shuffles his last three).
static var recent_points: Array[String] = []


# =============================================================================================
# Pure rules
# =============================================================================================

## The art scale for the mic Dubi (see the header): `fits(s)` says whether the card fits at ×s.
static func pick_art_scale(k: int, density: int, fits: Callable, scales: Array = ART_SCALES) -> int:
	for s: int in scales:
		if fits.call(s) and (s * k) % (4 * maxi(1, density)) == 0:
			return s
	for s: int in scales:
		if fits.call(s):
			return s
	return int(scales[scales.size() - 1])


## The span [start, end) of Dubi's quoted talking point in a beat line ("דובי: \"…\""), or
## (-1, -1) when the line is not his.
static func dubi_quote(line: String) -> Vector2i:
	var nm := String(Content.data().get("dubi", {}).get("name", Story.narrator_name()))
	if nm == "" or not line.begins_with(nm):
		return Vector2i(-1, -1)
	var rest := line.substr(nm.length()).strip_edges(true, false)
	if not rest.begins_with(":"):
		return Vector2i(-1, -1)
	var q1 := line.find("\"", nm.length())
	var q2 := line.rfind("\"")
	if q1 < 0 or q2 <= q1 + 1:
		return Vector2i(-1, -1)
	return Vector2i(q1 + 1, q2)


## His last three talking points, padded from the content's list when he has said fewer.
static func last_three() -> Array:
	var out: Array = recent_points.slice(maxi(0, recent_points.size() - 3))
	var pool: Array = Content.data().get("dubi", {}).get("talkingPoints", [])
	var i := 0
	while out.size() < 3 and i < pool.size():
		out.push_front(String(pool[i]))
		i += 1
	return out


static func remember(point: String) -> void:
	recent_points.append(point)
	while recent_points.size() > 8:
		recent_points.pop_front()


## Dubi is about to say a talking point: the sim rolls the word salad (and counts wordSaladSeen
## when it hits); the result is what he says. The point itself enters his memory either way.
static func dubi_says(s: GameState, point: String, dice: Callable = Callable()) -> String:
	var r := dice if dice.is_valid() else rng
	var out := point
	if s != null and point.strip_edges() != "" and Story.roll_word_salad(s, r):
		var salad := Story.word_salad(last_three(), r)
		if salad != "":
			out = salad
	remember(point)
	return out


## A beat line as Dubi broadcasts it: his quoted talking point goes through dubi_says().
static func broadcast_line(s: GameState, line: String, dice: Callable = Callable()) -> String:
	var q := dubi_quote(line)
	if q.x < 0:
		return line
	return line.substr(0, q.x) + dubi_says(s, line.substr(q.x, q.y - q.x), dice) + line.substr(q.y)


## The card's header: the beat's title, or "סבב n: era" for the encore rounds.
static func header_text(n: int) -> String:
	var titles: Array = Content.data().get("story", {}).get("titles", [])
	if n >= 1 and n <= titles.size() and String(titles[n - 1]) != "":
		return String(titles[n - 1])
	return Strings.s("STORY_EVOLUTION", {"n": n, "era": Story.era_for(n).get("name", "")})


# =============================================================================================
# The card
# =============================================================================================

func build() -> FlashCard:
	id = "STORY"
	backdrop_closes = true
	var s: GameState = host.get("state") if host != null and "state" in host else null
	# the lines (the live broadcast rolls Dubi's word salad)
	line_texts = PackedStringArray()
	for l: String in Story.beat_for(evolutions):
		line_texts.append(l if archive else broadcast_line(s, l))
	# measure the body first: the figure's scale depends on what is left of the band
	var body := Node2D.new()
	var body_h := 0.0
	for t: String in line_texts:
		var p := PxText.make(body, Vector2.ZERO, t, L.TEXT, "plain", C_BODY)
		p.wrap_width = TEXT_W
		p.max_lines = TEXT_LINES
		p.right_at(TEXT_RIGHT)
		p.position.y = body_h
		lines.append(p)
		body_h += Ui.snap(_lh(p) * float(p.line_count()), 4) + LINE_GAP
	body_h = maxf(0.0, body_h - LINE_GAP)
	var btn_h := BTN.size.y if archive else BTN.size.y * 2.0 + BTN_GAP
	var band := _band()
	var fixed := HEADER_H + PAD + 2.0 * SCREEN_FRAME + PAD + body_h + PAD + btn_h + PAD
	var c: Dictionary = SpriteStrip.manifest().get("chars", {}).get(SpriteStrip.resolve("dubi-mic"), {})
	var dens := SpriteStrip.density_of(c) if not c.is_empty() else 1
	var fig_art_h := float(c.get("frameH", 0)) / float(dens)
	var avail := band.y - band.x - 2.0 * BAND_MARGIN
	art_scale = pick_art_scale(Display.k, dens,
		func(sc: int) -> bool: return fixed + _screen_h(fig_art_h * sc) <= avail)
	var screen_h := _screen_h(fig_art_h * art_scale)
	var h := fixed + screen_h
	var y := Ui.snap((band.x + band.y) / 2.0 - h / 2.0, 4)
	# the panel: the kit's dark sheet (white labels), title band on top
	panel_rect = Rect2(CARD_X, y, CARD_W, h)
	frame = Ui.nine(panel, panel_rect, Art.sprite_or("sheet_modal"))
	var head := text(Vector2(0, y + 24.0), header_text(evolutions), L.TEXT, C_TITLE)
	head.wrap_width = TEXT_W
	head.max_lines = 1
	head.center_in(CARD_X, CARD_W)
	# the news screen
	var sy := y + HEADER_H + PAD
	screen_rect = Rect2(SCREEN_X, sy + SCREEN_FRAME, SCREEN_W, screen_h)
	Ui.rect(panel, screen_rect.grow(SCREEN_FRAME), Color("#1b1426"))
	_build_screen(s)
	# the body, revealed line by line
	var by := screen_rect.end.y + SCREEN_FRAME + PAD
	panel.add_child(body)
	body.position.y = by
	for p in lines:
		p.modulate.a = 0.0 if not mgr.reduced else 1.0
	# the buttons
	var bt := by + body_h + PAD
	if archive:
		next_button = button(Rect2(BTN.position.x, bt, BTN.size.x, BTN.size.y), Rect2(BTN.position.x, bt, BTN.size.x, BTN.size.y),
			Strings.s("SYS_CLOSE"), func() -> void: cancel("close"), "kit_secondary", L.TEXT)
	else:
		next_button = button(Rect2(BTN.position.x, bt, BTN.size.x, BTN.size.y), Rect2(BTN.position.x, bt, BTN.size.x, BTN.size.y),
			Strings.s("FLASH_NEXT"), func() -> void: _close("next"), "kit_primary", L.TEXT)
		var bt2 := bt + BTN.size.y + BTN_GAP
		skip_button = button(Rect2(BTN.position.x, bt2, BTN.size.x, BTN.size.y), Rect2(BTN.position.x, bt2, BTN.size.x, BTN.size.y),
			Strings.s("FLASH_SKIP"), func() -> void: _close("skip"), "kit_secondary", L.TEXT)
	# audio: the dubiFlash head, then Dubi reads what is on the card
	_audio("storyCard")
	_audio("babble", " ".join(line_texts))
	var a := host.get_node_or_null("/root/Audio") if host != null else null
	if a != null and a.has_signal("dubi_blip"):
		a.connect("dubi_blip", _on_blip)
	return self


## The screen: the round's stage (d 1, ×4) cropped behind Dubi, his feet on the stage's floor
## line, and the lower third over his feet.
func _build_screen(_s: GameState) -> void:
	var clip := Control.new()
	clip.clip_contents = true
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip.position = screen_rect.position
	clip.size = screen_rect.size
	panel.add_child(clip)
	var feet_y := screen_rect.size.y - FEET_UP                       # screen-local
	var era: Dictionary = Story.era_for(evolutions)
	var man := SpriteStrip.manifest()
	var st_id := String(man.get("stages", {}).get(String(era.get("id", "")), {}).get("sprite", era.get("background", "")))
	if st_id != "" and Art.has_sprite(st_id):
		var tex := Art.tex(st_id)
		var tsz := Vector2(tex.get_size())
		var feet: Array = man.get("magicianFeet", [94, 219])
		var rw := floorf(SCREEN_W / 4.0)
		var rh := ceilf(screen_rect.size.y / 4.0)
		var rx := clampf(floorf((tsz.x - rw) / 2.0), 0.0, maxf(0.0, tsz.x - rw))
		var ry := clampf(float(feet[1]) - floorf(feet_y / 4.0), 0.0, maxf(0.0, tsz.y - rh))
		_stage = Sprite2D.new()
		_stage.texture = tex
		_stage.centered = false
		_stage.region_enabled = true
		_stage.region_rect = Rect2(rx, ry, rw, rh)
		_stage.scale = Vector2(4, 4)
		clip.add_child(_stage)
	# Dubi: the left third of the screen, looking into the frame (the ref faces screen-right)
	strip = SpriteStrip.make(clip, "dubi-mic", Vector2.ZERO, "idle")
	if strip != null:
		strip.remove_from_group("spritestrip")   # its scale is the card's, not artScale/d
		strip.scale_px = float(art_scale) / float(strip.density)
		strip._setup_filter()
		var fw := strip.frame_size().x
		strip.position = Vector2(Ui.snap(maxf(fw / 2.0 + 24.0, SCREEN_W * 0.3), 4), feet_y)
		strip.queue_redraw()
		_k = Display.k
	# the lower third: the bar across, the red plate at the right (reading start), the round
	var ly := screen_rect.size.y - LOWER_H
	Ui.nine(clip, Rect2(0, ly, SCREEN_W, LOWER_H), Art.sprite_or("ticker_bar"))
	Ui.nine(clip, Rect2(SCREEN_W - PLATE_W, ly, PLATE_W, LOWER_H), Art.sprite_or("ticker_flash_plate"))
	var tag := PxText.make(clip, Vector2(0, ly + 8.0), Strings.s("HEADLINE_TITLE"), L.TEXT, "plain", "w")
	tag.wrap_width = PLATE_W - 24.0
	tag.max_lines = 1
	tag.right_at(SCREEN_W - 12.0)
	var rnd := PxText.make(clip, Vector2(0, ly + 8.0), Strings.s("TITLE_ROUND", {"n": evolutions}), L.TEXT, "plain", C_LOWER)
	rnd.wrap_width = SCREEN_W - PLATE_W - 32.0
	rnd.max_lines = 1
	rnd.right_at(SCREEN_W - PLATE_W - 16.0)


func _screen_h(fig_h: float) -> float:
	return ceilf((fig_h + HEADROOM + FEET_UP) / 4.0) * 4.0


## The visible band of the modal space (y top, y bottom): MainController centres the 1280-tall
## modal space between the insets (_ovl_y), so the band is symmetric around 640.
func _band() -> Vector2:
	if host == null or not ("_ovl_y" in host and "_top_y" in host):
		return Vector2(0.0, float(L.H))
	var over := float(host.get("_ovl_y")) - float(host.get("_top_y"))
	return Vector2(-over, float(L.H) + over)


func _lh(t: PxText) -> float:
	return float(HeFont.line_height()) * t.eff_px()


func _audio(name: String, arg: Variant = null) -> void:
	sent.append([name, arg])
	if host != null and host.has_method("audio_event"):
		host.audio_event(name, arg)


func default_focus() -> int:
	return 0


## Web debug (like window.odDisplay): the buttons' centres in viewport logical px, for the
## browser view checks (tools/web/views_web.mjs).
func on_opened() -> void:
	if not OS.has_feature("web") or host == null or not ("_ox" in host and "_ovl_y" in host):
		return
	var o := Vector2(float(host.get("_ox")), float(host.get("_ovl_y")))
	var nx := next_button.visual.get_center() + o
	var sk := skip_button.visual.get_center() + o if skip_button else Vector2(-1, -1)
	JavaScriptBridge.eval("window.odFlash = %s" % JSON.stringify({"open": true, "artScale": art_scale,
		"next": [nx.x, nx.y], "skip": [sk.x, sk.y]}), true)


# ------------------------------------------------------------------ per frame

func update_view(dt_ms: float) -> void:
	_t += dt_ms
	var stagger := ViewRules.mc("flashLineStaggerMs")
	var fade := maxf(1.0, ViewRules.mc("flashLineInMs"))
	for i in lines.size():
		lines[i].modulate.a = 1.0 if mgr.reduced else clampf((_t - stagger * float(i)) / fade, 0.0, 1.0)
	if strip == null:
		return
	if Display.k != _k:
		_k = Display.k
		strip._setup_filter()
	if strip.anim == "talk":
		if _talk_open > 0.0:
			_talk_open -= dt_ms
			if _talk_open <= 0.0:
				strip.frame = 0             # beak shut until the next blip
				strip.queue_redraw()
		_talk_idle -= dt_ms
		if _talk_idle <= 0.0:
			strip.paused = false
			strip.play("idle")
	else:
		strip.update_view(dt_ms)


## One babble syllable (the Audio's dubi_blip): the beak opens for 60 ms.
func on_blip() -> void:
	if strip == null or not strip.has_anim("talk") or closing:
		return
	strip.play("talk", true, 1)
	strip.paused = true
	_talk_open = TALK_OPEN_MS
	_talk_idle = TALK_IDLE_MS


func _on_blip(_bank: String) -> void:
	on_blip()


func _close(via: String) -> void:
	if host != null and host.has_method("stop_babble"):
		host.stop_babble()
	_audio("panelClose")
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.odFlash = {open: false}", true)
	mgr.close(self, via)


## Esc / back / backdrop: the same as "דלג".
func cancel(via: String) -> void:
	_close(via)


func _exit_tree() -> void:
	var a := get_node_or_null("/root/Audio")
	if a != null and a.is_connected("dubi_blip", _on_blip):
		a.disconnect("dubi_blip", _on_blip)
