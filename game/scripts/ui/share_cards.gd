class_name ShareCards
extends RefCounted
## The share platform's cards (Bar 2026-10-02): pure node builders on the share grid, 5 card px per
## art px (ShareSheet.S), like O4 / O5. Formats: "sq" 1080×1350 (216×270 art), "story" 1080×1920
## (216×384), "og" 1200×630 (240×126, the link previews of the /s/ stubs, tools/og.sh).
##
## Every card carries the hook, the URL and the satire stamp IN THE IMAGE (iOS WhatsApp drops the
## caption when an image is shared), and only preset lines: the model never holds free text from a
## player. A model is ShareKit's (`ShareKit.model(kind, ...)`); `neutral` in it is the family-safe
## variant (no leader's face or name; partners become "שותף א׳"), `quiet` the election silence (no 61).
##
## kinds: leak (a crop of the round's coalition chat), breaking (a news card), term (the round's
## summary), career (every round), challenge / daily (the challenge agent's models), and the old
## receipt / result (ShareSheet's builders; their story format centres the 216×270 card on a band).

const S := 5
const W := 216
const H_SQ := 270
const H_STORY := 384
const OG_W := 240
const OG_H := 126
const M := 10                         # the side margin, art px
const FOOT := 28.0                    # the footer band (the URL, the stamp)
const FOOT_TALL := 40.0               # + the disclaimer (a story)

const C_WHITE := Color("#f7f4ec")
const C_INK := Color("#061029")
const C_NAVY := Color("#072a7a")      # ui_panel (the chat's thread)
const C_NIGHT := Color("#00237a")
const C_DEEP := Color("#00143d")
const C_FLAG := Color("#0038b8")
const C_RED := Color("#d02a36")       # the ticker's "מבזק" plate
const C_GOLD := Color("#ffd23f")
const C_GOLD_HI := Color("#fff1a6")
const C_MUTE := Color("#c9d6f2")
const C_SKY := Color("#8fc0ff")
const C_PAPER := Color("#f4f1e8")
const C_BUBBLE := Color("#1045b5")
const C_OUT := Color("#0f5132")
const C_YELLOW := Color("#ffe066")
const C_GREEN := Color("#8fe052")

## The daily grid's emoji → a colour (the challenge agent's emoji grid; the pixel font has no emoji).
const GRID_COLORS := {"🟩": Color("#5fbf3a"), "🟨": Color("#f2c230"), "🟥": Color("#d02a36"), "🟦": Color("#3f74e6"),
	"🟧": Color("#f08a24"), "🟪": Color("#8a4fd8"), "⬛": Color("#061029"), "⬜": Color("#f7f4ec"), "🟫": Color("#8a5a2b")}


static func size_of(fmt: String) -> Vector2i:
	match fmt:
		"story":
			return Vector2i(W * S, H_STORY * S)
		"og":
			return Vector2i(OG_W * S, OG_H * S)
	return Vector2i(W * S, H_SQ * S)


static func art_h(fmt: String) -> int:
	return H_STORY if fmt == "story" else (OG_H if fmt == "og" else H_SQ)


## The kinds this module draws (receipt / result go through ShareSheet's builders).
const KINDS := ["leak", "breaking", "term", "career", "challenge", "daily"]


## Builds the card's nodes under `root` (origin = the card's top-left, card px). `m` is the kind's
## model (ShareKit), `fmt` "sq" | "story" | "og".
static func build(root: Node2D, kind: String, m: Dictionary, fmt: String = "sq") -> void:
	if fmt == "og":
		_og(root, kind, m)
		return
	var h := art_h(fmt)
	match kind:
		"leak":
			_leak(root, m, h)
		"breaking":
			_breaking(root, m, h)
		"term":
			_term(root, m, h)
		"career":
			_career(root, m, h)
		"challenge":
			_challenge(root, m, h)
		"daily":
			_daily(root, m, h)
	root.set_meta("kind", kind)
	root.set_meta("fmt", fmt)


## O4 / O5 in the story format: the 216×270 card centred on a 216×384 band, the wordmark over it and
## the URL + the stamp under it.
static func wrap_story(root: Node2D, inner_bg: Color) -> Node2D:
	box(root, 0, 0, W, H_STORY, inner_bg)
	var top := (H_STORY - H_SQ) / 2
	_wordmark(root, (top - 29) / 2 + 2)
	var inner := Node2D.new()
	inner.position = Vector2(0, top * S)
	root.add_child(inner)
	_footer(root, H_STORY, false, true)
	return inner


# ------------------------------------------------------------------ primitives (art px)

static func box(root: Node, x: float, y: float, w: float, h: float, c: Color) -> ColorRect:
	return Ui.rect(root, Rect2(x * S, y * S, w * S, h * S), c)


## A text line on the card: `x`/`w` its column, `y` its top row (art px); align "right" (RTL
## start), "left" or "center"; `sc` the scale (1 = 1 font px per art px); returns the PxText.
static func txt(root: Node, t: String, x: float, y: float, w: float, align: String = "center", col: Color = C_WHITE, sc: int = 1, lines: int = 1) -> PxText:
	var p := PxText.make(root, Vector2.ZERO, t, S * sc, "plain", col)
	p.exact = true
	p.wrap_width = w * S
	p.max_lines = lines
	p.line_pitch = 10 * S * sc
	var bw := ceilf(float(p.width()) / S)
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
	p.position.y = (y + float(maxi(0, HeFont.ascent() - 6) * sc)) * S
	return p


## The art px a text block takes (its lines × the pitch).
static func text_h(p: PxText, sc: int = 1) -> float:
	return 10.0 * sc * maxf(1.0, float(p.line_count()))


## A sprite at an integer card-px scale (`sc` card px per sprite px), its top-left at art (x, y).
static func sprite(root: Node, id: String, x: float, y: float, sc: int) -> Sprite2D:
	if not Art.has_sprite(id):
		return null
	var s := Ui.img(root, Vector2(x * S, y * S), id, 0, sc)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return s


## The leader's dense pick head (avatar_pick_<c>_d3, 96 px) or its 32-px head, drawn `size` art px
## square with its top-left at (x, y); a framed medallion. Nothing for "" (neutral).
static func portrait(root: Node, leader: String, x: float, y: float, size: float, ring: Color = C_WHITE) -> bool:
	var id := portrait_id(leader)
	if id == "":
		return false
	var px := int(size) * S
	var sz := Art.sprite_size(id)
	var sc := maxi(1, int(roundf(float(px) / float(maxi(1, sz.x)))))
	var drawn := float(sz.x * sc) / S
	var ox := x + (size - drawn) / 2.0
	var oy := y + (size - drawn) / 2.0
	box(root, ox - 2, oy - 2, drawn + 4, drawn + 4, ring)
	box(root, ox - 1, oy - 1, drawn + 2, drawn + 2, C_DEEP)
	sprite(root, id, ox, oy, sc)
	return true


static func portrait_id(leader: String) -> String:
	if leader == "":
		return ""
	var art := LeaderUi.art(leader)
	var ch: Dictionary = SpriteStrip.manifest().get("chars", {}).get(art, {})
	for id: String in [str(ch.get("avatarPickXL", "avatar_pick_%s_d3" % art)), "avatar_pick_%s_d2" % art, str(ch.get("avatarPick", "avatar_pick_" + art)), "avatar_" + art]:
		if id != "" and Art.has_sprite(id):
			return id
	return ""


## A partner's (or anyone's) chat head, `size` art px, or a neutral silhouette disc.
static func head(root: Node, char_id: String, x: float, y: float, size: float) -> void:
	var id := "avatar_" + char_id if char_id != "" else ""
	if id != "" and Art.has_sprite(id):
		var sz := Art.sprite_size(id)
		var sc := maxi(1, int(floorf(size * S / float(maxi(1, sz.x)))))
		var drawn := float(sz.x * sc) / S
		sprite(root, id, x + (size - drawn) / 2.0, y + (size - drawn) / 2.0, sc)
	else:
		box(root, x + 2, y + 2, size - 4, size - 4, C_MUTE)
		box(root, x + size / 2.0 - 3, y + 5, 6, 6, C_NAVY)
		box(root, x + size / 2.0 - 6, y + 12, 12, size - 15, C_NAVY)


static func _wordmark(root: Node, y: float, sc: int = S) -> void:
	if Art.has_sprite("wordmark"):
		var sz := Art.sprite_size("wordmark")
		var w := float(sz.x * sc) / S
		sprite(root, "wordmark", floorf((W - w) / 2.0), y, sc)


## The bottom band every card ends with: the URL and the satire stamp (+ the disclaimer when `tall`).
static func _footer(root: Node, h: float, light: bool = false, tall: bool = false) -> void:
	var y := h - (FOOT_TALL if tall else FOOT)
	var bg := C_PAPER if light else C_INK
	var fg := C_INK if light else C_WHITE
	box(root, 0, y, W, h - y, bg)
	box(root, 0, y, W, 1, C_GOLD)
	txt(root, Strings.s("CARD_URL", {"url": ShareKit.display_host(ShareKit.site_url())}), M, y + 4, W - 2 * M, "center", fg)
	_stamp(root, y + 15)
	if tall:
		txt(root, Strings.s("RESULT_DISC"), M, y + 28, W - 2 * M, "center", C_MUTE if not light else C_INK)


## "סאטירה · עוד סבב": a ruled red stamp centred on the card's width, its box y .. y + 11.
static func _stamp(root: Node, y: float) -> void:
	var col := C_RED
	var p := txt(root, Strings.s("CARD_SATIRE"), 0, y + 2, W, "center", col)
	var bw := ceilf(float(p.width()) / S) + 8.0
	var bx := floorf((W - bw) / 2.0)
	box(root, bx, y, bw, 1, col)
	box(root, bx, y + 11, bw, 1, col)
	box(root, bx, y, 1, 12, col)
	box(root, bx + bw - 1, y, 1, 12, col)


## A stack of centred lines (stats), built at y 0 under a holder node; returns [holder, height].
static func _stack(root: Node, lines: Array, col: Color, gap: float) -> Array:
	var holder := Node2D.new()
	root.add_child(holder)
	var y := 0.0
	for ln: String in lines:
		var p := txt(holder, ln, M, y, W - 2 * M, "center", col, 1, 2)
		y += text_h(p) + gap
	return [holder, maxf(0.0, y - gap)]


## The gold title plate (TERM_TITLE_LABEL / CAREER_RANK over the title at ×2, up to 2 lines),
## its bottom at `bottom`. Returns its top.
static func _plate(root: Node, label: String, title: String, bottom: float) -> float:
	var probe := Node2D.new()
	var tp := txt(probe, title, M + 4, 0, W - 2 * M - 8, "center", C_INK, 2, 2)
	var th := text_h(tp, 2)
	probe.free()
	var hh := 4.0 + 10.0 + 2.0 + th + 4.0
	var top := bottom - hh
	box(root, M, top, W - 2 * M, hh, C_GOLD)
	box(root, M, top + hh, W - 2 * M, 2, C_INK)
	txt(root, label, M + 4, top + 4, W - 2 * M - 8, "center", C_INK)
	txt(root, title, M + 4, top + 16, W - 2 * M - 8, "center", C_INK, 2, 2)
	return top


# ------------------------------------------------------------------ הדלפה (the leak)

## A crop of the round's coalition chat: the red "הודלף מ: עוד סבב" band, the group's header, 3-5
## of the round's juiciest real lines (ShareKit.leak_lines), the footer.
static func _leak(root: Node2D, m: Dictionary, h: int) -> void:
	box(root, 0, 0, W, h, C_NAVY)
	var story := h > H_SQ
	var y := 0.0
	if story:
		box(root, 0, 0, W, 50, C_DEEP)
		_wordmark(root, 6)
		y = 44.0
	box(root, 0, y, W, 16, C_RED)
	txt(root, Strings.s("LEAK_CARD_TOP"), M, y + 3, W - 2 * M, "center", C_WHITE)
	y += 16.0
	# the group's header (kit chat_header: navy with a light rule)
	if Art.has_sprite("chat_header"):
		Ui.nine(root, Rect2(0, y * S, W * S, 26 * S), "chat_header", 0, S)
	else:
		box(root, 0, y, W, 26, C_DEEP)
	txt(root, Strings.s("CHAT_TITLE"), M, y + 4, W - 2 * M - 12, "right", C_WHITE)
	if Art.has_sprite("chat_icon_lock"):
		sprite(root, "chat_icon_lock", W - M - 7, y + 4, S)
	txt(root, Strings.s("LEAK_CARD_MEMBERS", {"n": str(int(m.get("members", 0)))}), M, y + 14, W - 2 * M, "right", C_MUTE)
	y += 30.0
	var bottom := float(h) - FOOT - 14.0
	var lines: Array = m.get("lines", [])
	var max_n := 6 if story else 5
	var shown := lines.slice(maxi(0, lines.size() - max_n))
	# lay out bottom-up so the newest line sits over the footer (a phone screenshot's crop)
	var blocks: Array = []
	for ln: Dictionary in shown:
		blocks.append(ln)
	var heights: Array = []
	var total := 0.0
	var probe := Node2D.new()
	for ln: Dictionary in blocks:
		var hh := _bubble(probe, ln, 0.0, true)
		heights.append(hh)
		total += hh + 4.0
	probe.free()
	var avail := bottom - y
	while total > avail and not blocks.is_empty():
		total -= float(heights[0]) + 4.0
		blocks.pop_front()
		heights.pop_front()
	var cy := y + floorf(maxf(0.0, (avail - total) / 2.0))
	for i in blocks.size():
		_bubble(root, blocks[i], cy, false)
		cy += float(heights[i]) + 4.0
	txt(root, Strings.s("LEAK_CARD_FOOT"), M, bottom + 3, W - 2 * M, "center", C_MUTE)
	_footer(root, h)


## One chat row at art y: an incoming bubble (head at the right, the name over the text), the
## player's reply (left, green), or a centred system pill. Returns its height (art px).
static func _bubble(root: Node, ln: Dictionary, y: float, measure_only: bool) -> float:
	var kind := str(ln.get("kind", "in"))
	var text := str(ln.get("text", ""))
	if kind == "sys":
		var p := txt(root, text, M + 14, y + 3, W - 2 * M - 28, "center", C_MUTE, 1, 2)
		var hh := text_h(p) + 5.0
		if not measure_only:
			var bw := ceilf(float(p.width()) / S) + 10.0
			var pill := box(root, floorf((W - bw) / 2.0), y, bw, hh, C_DEEP)
			pill.get_parent().move_child(pill, p.get_index())
		return hh
	var tw := 136.0
	var cont := bool(ln.get("cont", false))
	var name_h := 10.0 if str(ln.get("who", "")) != "" and not cont else 0.0
	var head_sz := 22.0
	if kind == "out":
		var po := txt(root, text, M + 4, y + 3 + name_h, tw, "left", C_WHITE, 1, 3)
		var ho := text_h(po) + 6.0 + name_h
		if not measure_only:
			var bw := ceilf(float(po.width()) / S) + 8.0
			var b := box(root, M, y, bw, ho, C_OUT)
			b.get_parent().move_child(b, po.get_index())
			if name_h > 0.0:
				txt(root, str(ln["who"]), M + 4, y + 2, tw, "left", C_GREEN)
		return ho
	var right := W - M - head_sz - 4.0
	var p2 := txt(root, text, right - 4 - tw, y + 3 + name_h, tw, "right", C_WHITE, 1, 3)
	var h2 := text_h(p2) + 6.0 + name_h
	if not measure_only:
		var tw2 := ceilf(float(p2.width()) / S)
		var nm: PxText = null
		if name_h > 0.0:
			nm = txt(root, str(ln["who"]), right - 4 - tw, y + 2, tw, "right", C_GOLD if bool(ln.get("hot", false)) else C_SKY)
			tw2 = maxf(tw2, ceilf(float(nm.width()) / S))
		var bw2 := tw2 + 8.0
		var b2 := box(root, right - bw2, y, bw2, h2, C_RED.darkened(0.35) if bool(ln.get("hot", false)) else C_BUBBLE)
		b2.get_parent().move_child(b2, p2.get_index())
		if not cont:
			head(root, str(ln.get("char", "")), W - M - head_sz, y, head_sz)
	return h2


# ------------------------------------------------------------------ מבזק (breaking news)

## An invented channel's breaking card (never a real channel's name or logo): the channel bug and
## "שידור חי", the leader's head in the studio frame, the red "מבזק" tag over the white lower third
## (the headline at ×2), a sub-line, the crawl, the footer.
static func _breaking(root: Node2D, m: Dictionary, h: int) -> void:
	box(root, 0, 0, W, h, C_DEEP)
	var story := h > H_SQ
	var y := 8.0
	if story:
		_wordmark(root, 8)
		y = 46.0
	# the studio: light beams
	for i in 5:
		box(root, 20 + i * 44, y + 14, 20, 120 if story else 92, C_NIGHT)
	# the channel bug (top right) and the live tag (top left)
	var ch := txt(root, Strings.s("BREAK_CHANNEL_QUIET" if bool(m.get("quiet", false)) else "BREAK_CHANNEL"), M, y + 2, 100, "right", C_WHITE)
	var cw := ceilf(float(ch.width()) / S) + 8.0
	var bug := box(root, W - M - cw, y, cw, 13, C_RED)
	bug.get_parent().move_child(bug, ch.get_index())
	ch.position.x = (W - M - cw + 4) * S
	var lv := txt(root, Strings.s("BREAK_LIVE"), M + 8, y + 2, 80, "left", C_WHITE)
	box(root, M, y + 4, 5, 5, C_RED)
	lv.position.x = (M + 8) * S
	y += 18.0
	var pr_size := 110.0 if story else 82.0
	var px := floorf((W - pr_size) / 2.0)
	if not portrait(root, str(m.get("leader", "")), px, y, pr_size, C_MUTE):
		_wordmark(root, y + pr_size / 2.0 - 15)
	y += pr_size + 8.0
	# the lower third: the red tag, the white plate, the headline
	var tag := txt(root, Strings.s("TICKER_TAG"), M + 4, y + 2, 60, "right", C_WHITE)
	var tgw := ceilf(float(tag.width()) / S) + 8.0
	var tg := box(root, W - M - tgw, y, tgw, 13, C_RED)
	tg.get_parent().move_child(tg, tag.get_index())
	tag.position.x = (W - M - tgw + 4) * S
	y += 13.0
	var head_t := str(m.get("head", ""))
	var probe := Node2D.new()
	var hp := txt(probe, head_t, M + 4, 0, W - 2 * M - 8, "right", C_INK, 2, 2)
	var hh := text_h(hp, 2) + 6.0
	probe.free()
	box(root, M, y, W - 2 * M, hh, C_WHITE)
	txt(root, head_t, M + 4, y + 3, W - 2 * M - 8, "right", C_INK, 2, 2)
	y += hh
	box(root, M, y, W - 2 * M, 13, C_FLAG)
	txt(root, str(m.get("sub", "")), M + 4, y + 2, W - 2 * M - 8, "right", C_WHITE)
	y += 13.0
	# the crawl band over the footer
	var cy := float(h) - FOOT - 13.0
	box(root, 0, cy, W, 13, C_YELLOW)
	txt(root, Strings.s("BREAK_CRAWL"), M, cy + 2, W - 2 * M, "right", C_INK)
	if story:
		# the story's extra room: the round's clock as a studio graphic
		var t := str(m.get("time", ""))
		if t != "":
			var my := y + floorf((cy - y - 40.0) / 2.0)
			txt(root, t, M, my, W - 2 * M, "center", C_GOLD, 4)
	_footer(root, h)


# ------------------------------------------------------------------ סיכום קדנציה (the term)

## The round in numbers, Wrapped-style: the title, the round line, the big time to the gate, the
## top source's share, the stat lines (zeros dropped), the run's title plate, the footer.
static func _term(root: Node2D, m: Dictionary, h: int) -> void:
	box(root, 0, 0, W, h, C_FLAG)
	var story := h > H_SQ
	for i in 8:
		box(root, 0, 40 + i * (44 if story else 32), W, 2, C_NIGHT)
	var y := 8.0
	if story:
		_wordmark(root, 12)
		y = 54.0
	var leader := str(m.get("leader", ""))
	if leader != "" and not bool(m.get("neutral", false)):
		portrait(root, leader, W - M - 30, y, 30, C_GOLD)
		txt(root, Strings.s("TERM_HEAD"), M, y + 2, W - 2 * M - 38, "right", C_WHITE, 2)
		txt(root, str(m.get("round", "")), M, y + 22, W - 2 * M - 38, "right", C_MUTE)
		y += 38.0
	else:
		txt(root, Strings.s("TERM_HEAD"), M, y, W - 2 * M, "center", C_WHITE, 2)
		txt(root, str(m.get("round", "")), M, y + 20, W - 2 * M, "center", C_MUTE)
		y += 34.0
	var plate_top := _plate(root, Strings.s("TERM_TITLE_LABEL"), str(m.get("title", "")), float(h) - FOOT - (14.0 if story else 8.0))
	# the middle block (the big time, its label, the stats) centred between the head and the plate
	var mid := Node2D.new()
	root.add_child(mid)
	var my := 0.0
	var t := str(m.get("time", ""))
	if t != "":
		txt(mid, t, M, 0, W - 2 * M, "center", C_GOLD, 5 if story else 4)
		my += 48.0 if story else 38.0
		txt(mid, Strings.s("TERM_GATE"), M, my, W - 2 * M, "center", C_GOLD_HI)
		my += 18.0 if story else 14.0
	var st: Array = _stack(mid, m.get("stats", []), C_WHITE, 8.0 if story else 3.0)
	(st[0] as Node2D).position.y = my * S
	my += float(st[1])
	mid.position.y = floorf(y + maxf(0.0, (plate_top - y - my) / 2.0)) * S
	_footer(root, h)


# ------------------------------------------------------------------ סיכום כל הסבבים (the career)

static func _career(root: Node2D, m: Dictionary, h: int) -> void:
	box(root, 0, 0, W, h, C_NIGHT)
	var story := h > H_SQ
	for i in 9:
		box(root, 6 + i * 24, 0, 1, h, C_DEEP)
	var y := 8.0
	if story:
		_wordmark(root, 12)
		y = 54.0
	txt(root, Strings.s("CAREER_HEAD"), M, y, W - 2 * M, "center", C_WHITE, 2)
	y += 24.0
	var plate_top := _plate(root, Strings.s("CAREER_RANK"), str(m.get("title", "")), float(h) - FOOT - (14.0 if story else 8.0))
	var mid := Node2D.new()
	root.add_child(mid)
	var my := 0.0
	var leader := str(m.get("leader", ""))
	var psz := 64.0 if story else 40.0
	if leader != "" and not bool(m.get("neutral", false)):
		portrait(mid, leader, floorf((W - psz) / 2.0), 2, psz, C_GOLD)
		my += psz + 8.0
	var sv := txt(mid, str(m.get("survived", "")), M, my, W - 2 * M, "center", C_GOLD, 2, 2)
	my += text_h(sv, 2)
	if str(m.get("as", "")) != "":
		txt(mid, str(m["as"]), M, my, W - 2 * M, "center", C_GOLD_HI)
		my += 12.0
	my += 8.0 if story else 4.0
	var st: Array = _stack(mid, m.get("stats", []), C_WHITE, 8.0 if story else 2.0)
	(st[0] as Node2D).position.y = my * S
	my += float(st[1])
	mid.position.y = floorf(y + maxf(0.0, (plate_top - y - my) / 2.0)) * S
	_footer(root, h)


# ------------------------------------------------------------------ אתגר / יומי (the challenge agent's)

## The challenge: the leader's head, "X הרכיב קואליציה ב:", the big time, "תעבור אותי?".
static func _challenge(root: Node2D, m: Dictionary, h: int) -> void:
	box(root, 0, 0, W, h, C_DEEP)
	var story := h > H_SQ
	var y := 8.0
	if story:
		_wordmark(root, 10)
		y = 52.0
	var tag := txt(root, Strings.s("CHAL_HEAD"), M, y + 1, W - 2 * M, "center", C_INK, 2)
	var tw := ceilf(float(tag.width()) / S) + 12.0
	var tb := box(root, floorf((W - tw) / 2.0), y - 2, tw, 24, C_GOLD)
	tb.get_parent().move_child(tb, tag.get_index())
	y += 30.0
	var psz := 100.0 if story else 76.0
	if not portrait(root, str(m.get("leader", "")) if not bool(m.get("neutral", false)) else "", floorf((W - psz) / 2.0), y, psz, C_GOLD):
		_wordmark(root, y + psz / 2.0 - 15)
	y += psz + 8.0
	txt(root, str(m.get("line", "")), M, y, W - 2 * M, "center", C_MUTE)
	y += 12.0
	txt(root, str(m.get("time", "")), M, y, W - 2 * M, "center", C_GOLD, 5)
	y += 50.0
	txt(root, Strings.s("CHAL_DARE"), M, y, W - 2 * M, "center", C_WHITE, 2)
	_footer(root, h)


## The daily: "עוד סבב #N", "האתגר היומי", the emoji grid as pixel squares, "מה התוצאה שלך?".
static func _daily(root: Node2D, m: Dictionary, h: int) -> void:
	box(root, 0, 0, W, h, C_NIGHT)
	var story := h > H_SQ
	var y := 10.0
	if story:
		_wordmark(root, 10)
		y = 56.0
	txt(root, Strings.s("DAILY_HEAD", {"n": str(int(m.get("n", 1)))}), M, y, W - 2 * M, "center", C_WHITE, 2)
	y += 22.0
	txt(root, Strings.s("DAILY_SUB"), M, y, W - 2 * M, "center", C_GOLD_HI)
	y += 16.0
	var rows := grid_rows(str(m.get("grid", "")))
	var cols := 0
	for r: Array in rows:
		cols = maxi(cols, r.size())
	if cols > 0:
		var avail_h := float(h) - FOOT - 26.0 - y
		var cell := floorf(minf((W - 2 * M) / float(cols), avail_h / float(maxi(1, rows.size()))))
		cell = clampf(cell, 6.0, 28.0)
		var gw := cell * cols
		var gx := floorf((W - gw) / 2.0)
		var gy := y + floorf((avail_h - cell * rows.size()) / 2.0)
		for ri in rows.size():
			var r: Array = rows[ri]
			for ci in r.size():
				# RTL reading order: the first cell at the right
				var cx := gx + gw - cell * (ci + 1)
				box(root, cx + 1, gy + ri * cell + 1, cell - 2, cell - 2, r[ci])
		y = gy + cell * rows.size() + 6.0
	txt(root, Strings.s("DAILY_DARE"), M, float(h) - FOOT - 16.0, W - 2 * M, "center", C_WHITE)
	_footer(root, h)


## The grid text's rows of colours (unknown glyphs, digits and spaces are dropped).
static func grid_rows(t: String) -> Array:
	var out: Array = []
	for line in t.split("\n"):
		var row: Array = []
		for i in line.length():
			var ch := line[i]
			if GRID_COLORS.has(ch):
				row.append(GRID_COLORS[ch])
		if not row.is_empty():
			out.append(row)
	return out


# ------------------------------------------------------------------ the link preview (OG 1200×630)

## The /s/<variant>/ stub's og:image: the wordmark (top right) and the satire stamp (top left), the
## leader's head in the centre square (WhatsApp crops to it), the headline at ×2 on a red band (up
## to 2 lines). 240×126 art.
static func _og(root: Node2D, _kind: String, m: Dictionary) -> void:
	box(root, 0, 0, OG_W, OG_H, C_FLAG)
	for i in 4:
		box(root, 0, 10 + i * 20, OG_W, 2, C_NIGHT)
	var hy := 80.0
	if Art.has_sprite("wordmark"):
		var sz := Art.sprite_size("wordmark")
		var w := float(sz.x * 3) / S
		sprite(root, "wordmark", OG_W - 6 - w, 4, 3)
	var st := txt(root, Strings.s("CARD_SATIRE"), 6, 7, 110, "center", C_WHITE)
	var bw := ceilf(float(st.width()) / S) + 8.0
	var sx := 6.0 + floorf((110.0 - bw) / 2.0)
	box(root, sx, 5, bw, 1, C_WHITE)
	box(root, sx, 16, bw, 1, C_WHITE)
	box(root, sx, 5, 1, 12, C_WHITE)
	box(root, sx + bw - 1, 5, 1, 12, C_WHITE)
	var psz := 54.0
	var px := floorf((OG_W - psz) / 2.0)
	if not portrait(root, str(m.get("leader", "")), px, 22, psz, C_GOLD):
		box(root, px, 22, psz, psz, C_NIGHT)
		txt(root, Strings.s("TICKER_TAG"), px, 22 + psz / 2.0 - 10, psz, "center", C_GOLD, 2)
	box(root, 0, hy, OG_W, OG_H - hy, C_RED)
	box(root, 0, hy, OG_W, 1, C_GOLD)
	var probe := Node2D.new()
	var hp := txt(probe, str(m.get("head", "")), 6, 0, OG_W - 12, "center", C_WHITE, 2, 2)
	var th := text_h(hp, 2)
	probe.free()
	txt(root, str(m.get("head", "")), 6, hy + floorf((OG_H - hy - th) / 2.0) + 1, OG_W - 12, "center", C_WHITE, 2, 2)
