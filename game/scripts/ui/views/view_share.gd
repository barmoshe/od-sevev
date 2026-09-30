class_name ShareSheet
extends Overlay
## O4 "הקבלה החודשית" and O5 "כרטיס התוצאה" (ux/rtl-map.md §7.2 "sheet 0.8 · vs.y", review R25;
## ux/first-minute.md §5.1-5.3; the 2D Artist's share kit, art/od-sevev/src/ui_share.py). Opened
## from T4's full-width rows SHARE_RECEIPT_TITLE / SHARE_RESULT_BTN (DossierView.buttons()).
##
## The card is rendered ONCE, when the sheet opens (engine review U9): the kit piece
## (share_receipt_bg / share_result_frame, 216×270 art) plus the engine's text, built at 5 card px
## per art px into a 1080×1350 SubViewport, read back to a PNG. That keeps the "לשתף" tap inside
## Safari's user-activation window: the tap only hands ready bytes to navigator.share. While it
## renders the preview is a blank paper with "מדפיס…" and the image buttons are disabled.
##
## The preview IS the rendered image, drawn at `a` logical px per art px (the largest a that fits,
## with a · Display.f a whole number of device px), so every art px of the card lands on whole
## device px (the card's own grid is 5 card px per art px, sampled nearest).
##
## Layout, sheet-local (Rect2(0, vs.y − inset − h, 720, h + inset), h = min(content, 0.8 · vs.y)):
##   ✕ top-left (visual 64 at +16, hit 104), the title centred in the 432 box, y 24
##   the preview centred under the 104 header
##   a status line (SHARE_SAVED / SHARE_COPIED / SHARE_FAIL) under it, one line; after a share
##   went out, the envelope (§5.14.3 E2, "sent") leads it
##   "לשתף" (primary, LEFT Rect2(88, y, 256, 96)) beside "לשמור תמונה" (RIGHT Rect2(376, y, 256, 96))
##   "לשתף בוואטסאפ" full width Rect2(24, y + 112, 672, 96), the label only (review U11, U14;
##   Bar 2026-09-29: WhatsApp is the main channel; wa.me takes text only, the link preview (OG)
##   carries the picture)
##   "סגור" full width Rect2(24, h − 112, 672, 88), fixed

const S := 5                                  # card px per art px (the export grid)
const ART := Vector2i(216, 270)
const CARD := Vector2i(1080, 1350)
const HEADER := 104.0
const PAD := 24.0
const BTN_H := 96.0
const GAP := 16.0
const CLOSE_AREA := 112.0
const STATUS_H := 48.0

const C_INK := Color("#1a1a1a")               # receipt ink on #f4f1e8 paper (15.4:1)
const C_PAPER := Color("#f4f1e8")
const C_WHITE := Color("#f7f4ec")
const C_NIGHT := Color("#00237a")
## The status line sits on the sheet's cream notice (#fff4e0), not on blue: the v4 map's ui_mute was
## 1.3:1 there; flag blue is 8.3:1 (UX review 2026-09-30, U5).
const C_STATUS := Color("#0038b8")
## mobile-first §5.14.3: the envelope (kit `envelope_blue`, 14×10) on the result card's stage floor
## (E1, card-art px) and, ×4 (56×40), leading the status line after a share went out (E2, "sent").
const ENVELOPE_AT := Vector2(38, 197)
const ENVELOPE_GAP := 16.0

var kind := "receipt"                         # "receipt" (O4) | "result" (O5)
var art_px := 2.0                             # the preview's logical px per art px
var png := PackedByteArray()
var text_to_share := ""
var rendered := false
var failed := false
var preview_rect := Rect2()
var share_btn: PxButton
var save_btn: PxButton
var wa_btn: PxButton
var status: PxText
var sent_mark: Sprite2D                       # E2: the envelope on the status line (shared only)
var _vp: SubViewport
var _preview: Sprite2D
var _printing: Node2D
var _card_root: Node2D


## mobile-first §5.12 (D44): a full-bleed sheet that may use the whole safe height (sharing is a
## focused task and the preview is the product): the preview scale `a` is the largest with a·f
## whole, 216a ≤ cw − 32 and 270a ≤ sheet − 520; the buttons bottom-up: "סגור" (fixed), WhatsApp
## full width (the main channel, nearest the thumb), "לשתף" / "לשמור תמונה" side by side, the
## status line; every row stretches with the canvas (anchor S), the preview is centred.
func build() -> ShareSheet:
	id = "SHARE_RECEIPT" if kind == "receipt" else "SHARE_RESULT"
	full_bleed = true
	var th := Art.theme
	var vs := Vector2(L.W, L.H)
	var ovl_y := 0.0
	var inset := 0.0
	var top := 0.0
	if host != null and "_vs" in host:
		vs = host.get("_vs")
		ovl_y = float(host.get("_ovl_y"))
		inset = float(host.call("bottom_inset")) if host.has_method("bottom_inset") else 0.0
		top = float(host.get("_top_y")) if "_top_y" in host else 0.0
	var h := L.floor4(vs.y) - top - inset
	var room := h - HEADER - PAD - STATUS_H - (BTN_H + GAP + BTN_H) - PAD - CLOSE_AREA
	art_px = preview_scale(room, L.cw - 32.0)
	var content := HEADER + Ui.snap(float(ART.y) * art_px, 4) + PAD + STATUS_H + BTN_H + GAP + BTN_H + PAD + CLOSE_AREA
	h = minf(h, Ui.snap(content, 4))
	var pr := Rect2(0, vs.y - inset - h - ovl_y, L.cw, h + inset)
	make_panel(pr)
	var title := text(Vector2(0, pr.position.y + 24.0), Strings.s("SHARE_RECEIPT_TITLE" if kind == "receipt" else "SHARE_RESULT_TITLE"), L.TEXT, th["modal"]["title"])
	title.fit_width = 432.0   # sheet.title
	title.center_in(pr.position.x + 144.0, pr.size.x - 288.0)
	var close := close_button(Rect2(pr.position.x + 16, pr.position.y + 16, 64, 64), Rect2(pr.position.x, pr.position.y, 104, 104), func() -> void: cancel("close"))
	# the preview (its size in logical px snapped to the 4 grid from the top-left)
	var psz := Vector2(ART) * art_px
	var px0 := Ui.snap((L.cw - psz.x) / 2.0, 4)
	var py0 := pr.position.y + HEADER
	preview_rect = Rect2(px0, py0, psz.x, psz.y)
	_printing = Node2D.new()
	panel.add_child(_printing)
	Ui.rect(_printing, preview_rect, C_PAPER if kind == "receipt" else C_NIGHT)
	var pt := PxText.make(_printing, Vector2(0, preview_rect.get_center().y - 24.0), Strings.s("SHARE_PRINTING"), L.TEXT, "plain", C_INK if kind == "receipt" else C_WHITE)
	pt.center_in(preview_rect.position.x, preview_rect.size.x)
	_preview = Sprite2D.new()
	_preview.centered = false
	_preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_preview.position = preview_rect.position
	_preview.scale = Vector2(art_px / S, art_px / S)
	_preview.visible = false
	panel.add_child(_preview)
	var y := py0 + psz.y + PAD
	status = PxText.make(panel, Vector2(0, y), "", L.TEXT, "plain", C_STATUS)
	status.reading = true
	status.wrap_width = 640.0 + L.dx
	status.max_lines = 1
	if Art.has_sprite("envelope_blue"):
		sent_mark = Ui.img(panel, Vector2(0, y + Ui.snap((STATUS_H - float(Art.sprite_size("envelope_blue").y) * 4.0) / 2.0, 4)), "envelope_blue", 0, 4)
		sent_mark.visible = false
	y += STATUS_H
	var hw := L.floor4((544.0 + L.dx - 32.0) / 2.0)
	share_btn = button(Rect2(88, y, hw, BTN_H), Rect2(80, y - 4.0, hw + 16.0, BTN_H + 8.0), Strings.s("SHARE_BTN"), func() -> void: share(), "kit_primary", L.TEXT)
	save_btn = button(Rect2(88.0 + hw + 32.0, y, hw, BTN_H), Rect2(80.0 + hw + 32.0, y - 4.0, hw + 16.0, BTN_H + 8.0), Strings.s("SHARE_SAVE"), func() -> void: save(), "kit_secondary", L.TEXT)
	for b: PxButton in [share_btn, save_btn]:
		if b.label != null:
			b.label.wrap_width = 224.0
			b.label.max_lines = 1
			b.label.center_in(b.visual.position.x, b.visual.size.x)
	y += BTN_H + GAP
	# review U14: full width like "סגור" below it (§5.12), hit + 8 on every side; U11: the label
	# only, centred (no speech-bubble-with-tick icon: WhatsApp's mark under another name)
	wa_btn = button(Rect2(24, y, 672.0 + L.dx, BTN_H), Rect2(16, y - 8.0, 688.0 + L.dx, BTN_H + 16.0), Strings.s("SHARE_WA"), func() -> void: whatsapp(), "kit_secondary", L.TEXT)
	if wa_btn.label != null:
		wa_btn.label.wrap_width = 672.0 + L.dx - 32.0
		wa_btn.label.max_lines = 1
		wa_btn.label.center_in(wa_btn.visual.position.x, wa_btn.visual.size.x)
	var cy := pr.end.y - CLOSE_AREA - inset
	button(Rect2(24, cy, 672.0 + L.dx, 88), Rect2(24, cy, 672.0 + L.dx, 88), Strings.s("SHARE_CLOSE"), func() -> void: cancel("close"), "kit_secondary", L.TEXT)
	focusables.append(close)
	share_btn.set_enabled(false)
	save_btn.set_enabled(false)
	var st: GameState = host.get("state") if host != null else GameState.fresh()
	var d: Economy.Derived = host.get("d") if host != null else null
	var now := now_ms()
	text_to_share = ShareKit.share_text(kind, st, d, now)
	_start_render(st, d, now)
	return self


## The largest preview scale ≤ what fits `room` × `max_w` whose device px per art px is whole
## (a · Display.f an integer; at least 1 device px per art px).
static func preview_scale(room: float, max_w: float) -> float:
	var fit := minf(room / float(ART.y), max_w / float(ART.x))
	var f := Display.f if Display.integer else 1.0
	var dp := int(floorf(fit * f + 1e-4))
	return maxf(1.0, float(dp)) / f


func now_ms() -> float:
	var s: GameState = host.get("state") if host != null else null
	var dev := SaveStore.now_ms()
	return maxf(dev, float(s.calendar.get("hwm", 0.0))) if s != null and s.calendar is Dictionary else dev


# ------------------------------------------------------------------ the card (pure node builders)

## Builds the card's nodes under `root` at S card px per art px (origin = the card's top-left).
static func build_card(root: Node2D, kind_: String, s: GameState, d: Economy.Derived, now: float) -> void:
	if kind_ == "receipt":
		_build_receipt(root, ShareKit.receipt(s, d, now))
	else:
		_build_result(root, ShareKit.result(s))


## One text line on the card: `x`/`w` the column in art px, `y` the line's top row in art px;
## align "right" (RTL start), "left" or "center". Returns the PxText (exact scale S).
static func card_text(root: Node2D, t: String, x: float, w: float, y: float, align: String, col: Color, lines: int = 1) -> PxText:
	var p := PxText.make(root, Vector2.ZERO, t, S, "plain", col)
	p.exact = true
	p.wrap_width = w * S
	p.max_lines = lines
	p.line_pitch = 10 * S
	var bw := ceilf(float(p.width()) / S)      # the text box in art px
	match align:
		"right":
			p.align = 2
			p.h_anchor = 0
			p.position.x = (x + w - bw) * S
		"left":
			p.align = 0
			p.h_anchor = 0
			p.position.x = x * S
		_:
			p.align = 1
			p.h_anchor = 0
			p.position.x = (x + floorf((w - bw) / 2.0)) * S
	# PxText lifts a line by (ascent − 6) font px (the fork's 7-row box): put the line box's top at y
	p.position.y = (y + float(maxi(0, HeFont.ascent() - 6))) * S
	return p


## §5.1 the household receipt: the torn paper (share_receipt_bg), the print column x 32-184,
## 21 text rows at a 10 px pitch and 3 dashed rules (string-budgets receipt boxes).
static func _build_receipt(root: Node2D, m: Dictionary) -> void:
	Ui.img(root, Vector2.ZERO, Art.sprite_or("share_receipt_bg"), 0, S)
	var x0 := 32.0
	var w := 152.0
	var y := 20.0
	y = _row(root, Strings.s("RECEIPT_BRAND"), y, "center")
	y = _row(root, Strings.s("RECEIPT_KIND"), y, "center")
	y = _row(root, str(m["round"]), y, "center")
	y = _rule(root, x0, w, y)
	y = _row(root, Strings.s("RECEIPT_HEAD"), y, "center", 2)
	y = _row(root, Strings.s("RECEIPT_TOTAL_LINE", {"xr": str(m["totalText"])}), y, "center")
	y = _rule(root, x0, w, y)
	for ln: Dictionary in m["lines"]:
		card_text(root, Strings.s(str(ln["key"])), x0, w, y, "right", C_INK)
		if str(ln["amount"]) != "":
			card_text(root, Strings.s("RECEIPT_AMOUNT", {"xr": str(ln["amount"])}), x0, 56.0, y, "left", C_INK)
		y += 10.0
	y = _rule(root, x0, w, y)
	card_text(root, Strings.s("RECEIPT_SUM"), x0, w, y, "right", C_INK)
	card_text(root, Strings.s("RECEIPT_AMOUNT", {"xr": str(m["totalText"])}), x0, 72.0, y, "left", C_INK)
	y += 10.0
	y = _row(root, Strings.s("RECEIPT_PAID_BY"), y, "right")
	if str(m["countdown"]) != "":
		y = _row(root, str(m["countdown"]), y, "right")
	y = _row(root, Strings.s("RECEIPT_FOOT_REAL"), y, "right")
	y = _row(root, Strings.s("RECEIPT_FOOT_DISC"), y, "right", 2)
	y = _row(root, Strings.s("RECEIPT_FOOT_URL", {"url": ShareKit.display_host(ShareKit.site_url())}), y, "center")
	y = _row(root, Strings.s("RECEIPT_THANKS"), y, "center")
	root.set_meta("bottom", y)


## A receipt row in the print column (x 32-184) at y; returns the next row's y.
static func _row(root: Node2D, t: String, y: float, align: String, lines: int = 1) -> float:
	var p := card_text(root, t, 32.0, 152.0, y, align, C_INK, lines)
	return y + 10.0 * maxf(1.0, float(p.line_count()))


## A dashed rule (kit receipt_rule, tiled across the column) in a 6-px row.
static func _rule(root: Node2D, x0: float, w: float, y: float) -> float:
	var id := Art.sprite_or("receipt_rule")
	var tw := float(Art.sprite_size(id).x)
	var x := x0
	while x < x0 + w - 0.5:
		Ui.img(root, Vector2(x * S, (y + 2.0) * S), id, 0, S)
		x += tw
	return y + 6.0


## §5.2 the result card: the kit frame (curtains, follow-spot, stage floor, the wordmark), ביבי on
## the stage at castAnchor, the headline plate (2 lines + the sub-line), the stat strip, and the
## footer band with the URL and the disclaimer (the kit's zones). No seat numbers.
static func _build_result(root: Node2D, m: Dictionary) -> void:
	var fid := Art.sprite_or("share_result_frame")
	Ui.img(root, Vector2.ZERO, fid, 0, S)
	var z: Dictionary = Art.kit(fid).get("zones", {})
	var anchor: Array = z.get("castAnchor", [108, 198])
	# mobile-first §5.14.3 E1: a blank ballot envelope left on the stage floor, left of the leader's
	# feet, after the floor and before the cast (no number, no party; not on the receipt)
	if Art.has_sprite("envelope_blue"):
		var env := Ui.img(root, ENVELOPE_AT * float(S), "envelope_blue", 0, S)
		env.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		env.name = "Envelope"
	_place_figure(root, Vector2(float(anchor[0]), float(anchor[1])))
	var hz: Array = z.get("headline", [28, 43, 160, 20])
	card_text(root, str(m["head"]), float(hz[0]), float(hz[2]), float(hz[1]), "center", C_WHITE, 2)
	var sz: Array = z.get("sub", [24, 67, 168, 10])
	card_text(root, str(m["sub"]), float(sz[0]), float(sz[2]), float(sz[1]), "center", C_WHITE)
	var st: Array = z.get("stats", [24, 215, 168, 10])
	card_text(root, str(m["stats"]), float(st[0]), float(st[2]), float(st[1]), "center", C_WHITE)
	var fz: Array = z.get("footer", [8, 238, 200, 10])
	card_text(root, Strings.s("RESULT_FOOT", {"url": ShareKit.display_host(ShareKit.site_url())}), float(fz[0]), float(fz[2]), float(fz[1]), "center", C_WHITE)
	var dz: Array = z.get("disclaimer", [8, 251, 200, 10])
	card_text(root, Strings.s("RESULT_DISC"), float(dz[0]), float(dz[2]), float(dz[1]), "center", C_WHITE)


## The round's leader's idle frame 0 (ביבי in his round) with its feet on `feet` (art px). The card is 5 card px per art px, which no
## render density divides, so the figure draws its d 2 render at 2 card px per sprite px (whole
## pixels in the exported PNG, the figure 0.8 of its stage size); the main render (d 3) at 2 when
## there is no d 2. Nothing when the manifest lacks the character (the frame still reads).
static func _place_figure(root: Node2D, feet: Vector2) -> void:
	var slug := SpriteStrip.resolve(LeaderUi.art())   # the round's leader (spec §10.1)
	if slug == "":
		return
	var c: Dictionary = SpriteStrip.manifest()["chars"][slug]
	var v: Dictionary = c
	if (c.get("densities", {}) as Dictionary).has("2"):
		v = c.duplicate()
		v.merge(c["densities"]["2"], true)
	var a: Dictionary = (v.get("anims", {}) as Dictionary).get("idle", {})
	var path := String(SpriteStrip.manifest().get("root", "res://assets/sprites/")) + String(a.get("texture", ""))
	if a.is_empty() or not ResourceLoader.exists(path):
		return
	var at := AtlasTexture.new()
	at.atlas = load(path)
	at.region = Rect2(0, 0, float(v["frameW"]), float(v["frameH"]))
	var spr := Sprite2D.new()
	spr.texture = at
	spr.centered = false
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.scale = Vector2(2, 2)
	var anc: Array = v.get("anchor", [0, 0])
	spr.position = feet * S - Vector2(float(anc[0]), float(anc[1])) * 2.0
	spr.name = "Figure"
	root.add_child(spr)


# ------------------------------------------------------------------ render → PNG

func _start_render(s: GameState, d: Economy.Derived, now: float) -> void:
	_vp = SubViewport.new()
	_vp.size = CARD
	_vp.transparent_bg = false
	_vp.disable_3d = true
	_vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	_vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	_card_root = Node2D.new()
	_vp.add_child(_card_root)
	build_card(_card_root, kind, s, d, now)
	add_child(_vp)
	_capture.call_deferred()


## Waits for the SubViewport's frame, reads it back and swaps the "מדפיס…" paper for it. Without a
## renderer (the headless tests) the read-back is empty: the sheet stays usable with text-only
## sharing (WhatsApp, and "לשתף" sends the text).
func _capture() -> void:
	if not is_inside_tree() or not is_instance_valid(_vp):
		return
	if DisplayServer.get_name() == "headless":
		_finish_render(null)
		return
	RenderingServer.frame_post_draw.connect(_on_post_draw, CONNECT_ONE_SHOT)


func _on_post_draw() -> void:
	if not is_instance_valid(_vp):
		return
	_finish_render(_vp.get_texture().get_image())


func _finish_render(img: Image) -> void:
	if img != null and not img.is_empty():
		img.convert(Image.FORMAT_RGB8)
		png = img.save_png_to_buffer()
		_preview.texture = ImageTexture.create_from_image(img)
		_preview.visible = true
		_printing.visible = false
	else:
		failed = true
	rendered = true
	if is_instance_valid(_vp):
		_vp.queue_free()
	_vp = null
	share_btn.set_enabled(true)
	save_btn.set_enabled(not png.is_empty())
	publish_web()


## Test hook: the card's node tree (before the read-back frees the viewport), or null.
func card_root() -> Node2D:
	return _card_root if is_instance_valid(_card_root) else null


# ------------------------------------------------------------------ actions

func file_name() -> String:
	return ShareKit.FILE_RECEIPT if kind == "receipt" else ShareKit.FILE_RESULT


func share() -> void:
	host.audio_event("uiClick")
	ShareKit.share_png(kind, png, file_name(), text_to_share)


func save() -> void:
	host.audio_event("uiClick")
	ShareKit.save_png(kind, png, file_name())


func whatsapp() -> void:
	host.audio_event("uiClick")
	ShareKit.whatsapp(kind, text_to_share)


## The shell's answer (ShareKit.listen → MainController): one status line in the sheet.
func on_share_result(result: String) -> void:
	var key := ""
	match result:
		"fallback":
			key = "SHARE_COPIED" if png.is_empty() else "SHARE_SAVED"
		"saved":
			key = "SHARE_SAVED"
		"copied":
			key = "SHARE_COPIED"
		"fail":
			key = "SHARE_FAIL"
	if result == "shared" and Strings.has("SHARE_SENT"):
		key = "SHARE_SENT"
	status.text = Strings.s(key) if key != "" else ""
	status.center_in(0, L.cw)
	if result == "fallback" and not png.is_empty():
		status.text = Strings.s("SHARE_SAVED") + " " + Strings.s("SHARE_COPIED")
		status.center_in(0, L.cw)
	_place_sent(result == "shared")


## §5.14.3 E2: on `shared` only, the envelope at ×4 leads the status line (at its right end, RTL
## leading, 16 before the text; alone and centred when the line has no text). saved / copied /
## fail: none.
func _place_sent(on: bool) -> void:
	if sent_mark == null:
		return
	sent_mark.visible = on
	if not on:
		return
	var ew := float(Art.sprite_size("envelope_blue").x) * 4.0
	var tw := float(status.width()) if status.text != "" else 0.0
	var total := ew + (ENVELOPE_GAP + tw if tw > 0.0 else 0.0)
	var x0 := Ui.snap((L.cw - total) / 2.0, 4)
	if tw > 0.0:
		status.h_anchor = 0
		status.position.x = x0
	sent_mark.position.x = x0 + total - ew


func cancel(via: String) -> void:
	host.audio_event("panelClose")
	mgr.close(self, via)


# ------------------------------------------------------------------ web debug

## window.odModal (the browser driver): the buttons' centres in viewport logical px, `ready` once
## the PNG exists, and the preview rect.
func publish_web() -> void:
	if not OS.has_feature("web") or host == null:
		return
	var o := Vector2(float(host.get("_ox")) + position.x, float(host.get("_ovl_y")))
	var bs: Array = []
	for b: PxButton in focusables:
		var c := b.visual.get_center() + o
		bs.append([c.x, c.y, b.label.text if b.label != null else "x"])
	var pr := Rect2(preview_rect.position + o, preview_rect.size)
	var info := {"open": true, "id": id, "buttons": bs, "ready": rendered, "png": png.size(), "artPx": art_px,
		"preview": [pr.position.x, pr.position.y, pr.size.x, pr.size.y], "text": text_to_share}
	JavaScriptBridge.eval("window.odModal = %s" % JSON.stringify(info), true)


func on_opened() -> void:
	publish_web()


func _exit_tree() -> void:
	if RenderingServer.frame_post_draw.is_connected(_on_post_draw):
		RenderingServer.frame_post_draw.disconnect(_on_post_draw)
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.odModal = {open: false}", true)
