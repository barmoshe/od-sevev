class_name L
extends RefCounted
## od-sevev layout: ux/rtl-map.md (engine-concrete, RTL values given directly, not a runtime flip)
## with the mobile-first amendments of ux/mobile-first-layout.md. Every rect keeps its 720-design
## numbers (1 art px = 4 logical px); the canvas is `cw` wide (whole art columns, 720-860 on the
## phone matrix) and each element applies one of five anchors to `dx = cw - 720` (§4):
##   R (right)  x + dx            first in RTL reading order: labels, plates, icons at the right edge
##   L (left)   x                 trailing items: pills, numerals, the gear/mute, the date chip
##   C (centre) x + floor4(dx/2)  the counter, titles, modal cards, the stage column
##   S (stretch) x, w + dx        panels, tracks, clips, text boxes between an L and an R item
##   F (full bleed) 0 … vs.x      background fills, the ticker panel, the tab bar plate, the lane
## Sections, top to bottom (screen-logical y; chrome sections sit at the canvas origin, the stage
## column at sox()):
##   _top    Row A (0-96: counter, rate, mute, gear, cottage) + Row B (96-180: seats bar)
##   _stage  the stage, height S; its node sits at screen y - STAGE.y, so stage-local design y runs
##           STAGE.y .. STAGE.y + S (the fork's coordinates stay valid)
##   _lower  ticker (0-84), card pane (84 .. 84+P), tab bar (84+P .. 188+P, pinned to the safe
##           bottom; before C1 the pane runs under its slot)
## S and P come from the bottom-up split (mobile-first §3.2), set by MainController._relayout.

const W := 720
const H := 1280
## The game is Hebrew-only (ux A3): one switch (Bidi.UI_RTL).
const RTL := Bidi.UI_RTL
## Text scale: body ×4 on the art grid (rtl-map §0, D11); large-text mode draws ×5.
const TEXT := 4

## mobile-first §3.1: the fixed rows
const ROW_A_H := 96
const ROW_B_H := 84
const TICKER_H := 84
const TABS_H := 104
const FIXED_H := ROW_A_H + ROW_B_H + TICKER_H + TABS_H
## mobile-first §3.2: the split
const CARD := 120
const PEEK := 40
const S_PREF := 640
const S_FULL := 560
const S_MIN := 460
## kept names (rtl-map §1): the stage's designed and minimum heights
const STAGE_PREF := S_PREF
const STAGE_MIN := S_MIN

static var stage_h := 640.0     # S
static var panel_h := 400.0     # P (whole cards + the peek)
static var rows_whole := 3      # n: whole card rows in P
## The canvas width (mobile-first §2): >= 720, whole art columns; dx = cw - 720.
static var cw := 720.0
static var dx := 0.0
## ux/ftue.md C1: false until the tab bar is revealed; the pane then runs under its slot (§3.3).
static var tabs_up := true


static func floor4(v: float) -> float:
	return floorf(v / 4.0) * 4.0


## mobile-first §3.2: {S, P, n} for R = floor4(vs.y) - insets - FIXED_H. The stage keeps its
## 160-art composition (S_PREF) and every further CARD of height buys a whole card row, ending in
## a PEEK-px peek; the reach guard keeps the leader's hit bottom (stage bottom - 140) >= 40% of the
## height; the floor viewport (S < S_MIN) shrinks the peek. top = the safe top inset, vh =
## floor4(vs.y) (0 skips the reach guard).
static func split(r: float, top: float = 0.0, vh: float = 0.0) -> Dictionary:
	var n := 2
	if r - (3.0 * CARD + PEEK) >= S_MIN:
		n = maxi(3, int(floorf((r - S_PREF - PEEK) / CARD)))
	while vh > 0.0 and n > 3 and top + ROW_A_H + ROW_B_H + (r - n * CARD - PEEK) - 140.0 < 0.40 * vh:
		n -= 1
	var p := float(n * CARD + PEEK)
	var s := r - p
	if s < S_MIN:
		s = S_MIN
		p = r - s
	return {"S": s, "P": maxf(0.0, p), "n": n}


static func set_split(r: float, top: float = 0.0, vh: float = 0.0) -> void:
	var v := split(r, top, vh)
	stage_h = v["S"]
	panel_h = v["P"]
	rows_whole = v["n"]


## The chrome's width for a logical viewport `vs` and the art grid's width `grid_w` (Display.cw()):
## the whole grid, never wider than the viewport; a landscape window (out of the matrix, §2) keeps a
## portrait-proportioned canvas (≤ 0.75 · height), centred by the controller.
static func canvas_w(grid_w: float, vs: Vector2) -> float:
	return maxf(float(W), minf(minf(grid_w, floor4(vs.x)), maxf(float(W), floor4(0.75 * vs.y))))


## The canvas width (>= 720, on the 4-px grid) and dx.
static func set_width(w: float) -> void:
	cw = maxf(float(W), floor4(w))
	dx = cw - float(W)


## The stage column's x in the canvas (anchor C): floor4(dx / 2).
static func sox() -> float:
	return floor4(dx / 2.0)


## Anchors (§4): R, C and S for a rect, R and C for one x.
static func ra(r: Rect2) -> Rect2:
	return Rect2(r.position.x + dx, r.position.y, r.size.x, r.size.y)


static func ca(r: Rect2) -> Rect2:
	return Rect2(r.position.x + sox(), r.position.y, r.size.x, r.size.y)


static func sa(r: Rect2) -> Rect2:
	return Rect2(r.position.x, r.position.y, r.size.x + dx, r.size.y)


static func rx(x: float) -> float:
	return x + dx


static func cx(x: float) -> float:
	return x + sox()


## x of a box of width w at LTR x, mirrored across the canvas when RTL.
static func mx(x: float, w: float = 0.0) -> float:
	return W - x - w if RTL else x


static func mr(r: Rect2) -> Rect2:
	return Rect2(mx(r.position.x, r.size.x), r.position.y, r.size.x, r.size.y) if RTL else r


## Left x of a bar fill of width w inside `bar`: anchored right in RTL ("bars fill from the right").
static func bar_x(bar: Rect2, w: float) -> float:
	return bar.end.x - w if RTL else bar.position.x


## Stage-local design y of the stage bottom (STAGE.y + S).
static func stage_bottom() -> float:
	return float(STAGE["y"]) + stage_h


## Row A / Row B, `_top`-local (rtl-map §2, §3).
const TOP := {
	"counterBox": Rect2(196, 12, 328, 40),
	"rateBox": Rect2(188, 56, 344, 36),
	"muteHit": Rect2(100, 4, 88, 88),
	"gearHit": Rect2(8, 4, 88, 88),
	"cottageHit": Rect2(624, 4, 88, 88),
	"seatsHit": Rect2(0, 96, 720, 88),
	"seatsLabelRight": 704,
	"seatsY": 120,
	"seatsTrack": Rect2(144, 120, 424, 36),
	"seatsValueX": 16,
}

## Ticker row, `_lower`-local (rtl-map §5.1).
const TICKER := {
	"panel": Rect2(0, 0, 720, 84),
	"anchor": Rect2(560, 0, 160, 84),
	"tag": Rect2(616, 18, 96, 48),   # y and height; x and width follow the measured tag (Ticker.anchor_layout)
	"dubiFeet": Vector2(580, 84),    # y = the row floor; x is placed left of the plate
	"tagRight": 700,                  # rtl-map §5.1: TICKER_TAG right-aligned at x 700
	"tagPad": 8,
	"anchorGap": 4,
	"textY": 24,
	"clipX0": 192,
	"clipX1": 552,
	"chip": Rect2(8, 12, 176, 60),
	"hit": Rect2(0, 0, 720, 88),
}

## Card panel and tab bar, `_lower`-local (rtl-map §6). The list height is P; the tab bar sits
## under it (tabsY() = 84 + P).
const SHOP := {
	"listX": 16,
	"listW": 688,
	"listY": 84,
	"rowPitch": 120,
	"rowVisualTop": 0,
	"rowVisualH": 120,
	"scrollTrackX": 4,
	"tabW": 180,
	"moveCancelPx": 18,      # first-minute §3.3: 10 CSS px = 18 logical: beyond it a press scrolls
}


## The tab bar's top, `_lower`-local: under the pane, pinned to the safe bottom; before C1 the pane
## runs under the unrevealed slot, so the bar's top is the safe bottom (mobile-first §3.1, §3.3).
static func tabs_y() -> float:
	return float(SHOP["listY"]) + panel_h + (0.0 if tabs_up else float(TABS_H))


## One tab slot's width (mobile-first §5.3): floor4(cw / 4).
static func tab_w() -> float:
	return floor4(cw / 4.0)


## The tab slot rect (1-4, reading order right → left), `_lower`-local: slot i at x = cw - i·w;
## the remainder of cw goes to slot 4 (the leftmost).
static func tab_rect(slot: int) -> Rect2:
	var w := tab_w()
	var x := cw - slot * w
	if slot >= 4:
		return Rect2(0, tabs_y(), x + w, TABS_H)
	return Rect2(x, tabs_y(), w, TABS_H)


## Card internals, card-local (rtl-map §6.1).
const ROW := {
	"plate": Rect2(588, 8, 104, 104),
	"iconCenter": Vector2(640, 60),
	# string-budgets card.name 360 (x 220-580), card.line2 348 (x 220-568, beside the owned badge),
	# card.line2wide 360 (no badge)
	"nameRight": 580, "nameY": 16, "nameW": 360,
	"line2Right": 568, "line2WideRight": 580, "line2Y": 64, "line2W": 348, "line2WideW": 360,
	# rtl-map §6.1 "Owned" (D4): a dark chip on the plate's bottom-left corner, PxText centred
	"owned": Rect2(572, 72, 104, 44),
	"pill": Rect2(28, 16, 168, 88), "pillLine1Y": 22, "pillLine2Y": 58,
	"buyModeBtn": Rect2(28, 12, 168, 80), "buyModeHitW": 196,
}


const STAGE := {"y": 160, "h": 504}

const BB := {
	"pivotX": 360,
	"pivotY": 536,
	"scale": 5,
	"sprite": Rect2(240, 296, 240, 240),
	"center": Vector2(360, 416),
}

## The Magician (SpriteStrip "bibi", rtl-map §4): feet at stage-local (x, S-156), hit
## Rect2(x-188, S-556, 376, 416). x is the stage art's magicianFeet column (94 art px = 376), so
## the era backdrop needs no horizontal shift (rtl-map says 360; the art slot wins by 16 px).
const MAGICIAN := {"feetX": 376, "feetFromBottom": 156, "hitW": 376, "hitH": 416, "hitFromBottom": 140}


static func magician_feet() -> Vector2:
	return Vector2(float(MAGICIAN["feetX"]), stage_bottom() - float(MAGICIAN["feetFromBottom"]))


static func magician_hit() -> Rect2:
	var w := float(MAGICIAN["hitW"])
	var h := float(MAGICIAN["hitH"])
	return Rect2(float(MAGICIAN["feetX"]) - w / 2.0, stage_bottom() - float(MAGICIAN["hitFromBottom"]) - h, w, h)


## The Suitcase band (rtl-map §4.1): centre y S-60, hit 136x120 around the sprite.
static func suitcase_y() -> float:
	return stage_bottom() - 60.0


const SUITCASE_HIT := Vector2(136, 120)

## Floaters rise inside the stage.
static func floater_clamp() -> Dictionary:
	return {"x0": 24, "x1": 696, "y0": float(STAGE["y"]) + 8.0, "y1": stage_bottom() - 120.0}


## Stage-local design rects (rtl-map §4: chip y 104, banner y 168 from the stage top).
const BUFF := {
	"chip": Rect2(160, 264, 400, 56),
	"chipText": Vector2(176, 272),
	"chipBar": Rect2(176, 308, 368, 8),
	"banner": Rect2(96, 328, 528, 72),
	"bannerTextY": 344,
}

const DIORAMA := {
	"rows": {"S": 168, "B": 536, "F": 584},
	"xs": {
		"S": [40, 112, 184, 256, 328, 400, 472, 544, 616],
		"B": [88, 168, 248, 328, 408, 488, 568],
		"F": [48, 128, 208, 288, 368, 448, 528, 608],
	},
	"thresholds": [1, 10, 25],
}

## od-sevev: a producer's diorama slots come from content (producers[].slot: up to three slot
## codes, row letter S | B | F + index into DIORAMA.xs, one per threshold 1/10/25). Content
## without `slot` keeps the fork's placement (FORK_SLOTS), and any other producer gets three
## free slots in tier order, so a new id never crashes the stage.
const FORK_SLOTS := {
	"intern": ["F4", "F3", "B3"],
	"tree": ["B1", "B6", "B0"],
	"hardhat": ["F2", "F5", "B2"],
	"bureaucrat": ["F6", "F1", "B4"],
	"catapult": ["F7", "F0", "B5"],
	"rocket": ["S1", "S0", "S2"],
	"timechimp": ["S4", "S3", "S5"],
	"moon": ["S7", "S8", "S6"],
}


static func slots_for(id: String) -> Array:
	return slot_table().get(id, [])


## Every producer's slots: content `slot` first, then FORK_SLOTS, then the first free slots in
## producer order (front row, back row, sky).
static func slot_table() -> Dictionary:
	var out := {}
	var used := {}
	var pending: Array = []
	for id: String in Content.producer_ids():
		var v: Variant = Content.producer(id).get("slot", FORK_SLOTS.get(id))
		if v is String:
			v = [v]
		elif v is int or v is float:
			# a tier index: that tier's fork placement (0 = the first tier's three slots)
			var sets: Array = FORK_SLOTS.values()
			v = sets[clampi(int(v), 0, sets.size() - 1)]
		if v is Array:
			var codes: Array = (v as Array).map(func(x: Variant) -> String: return str(x)).filter(_valid_slot)
			out[id] = codes
			for c: String in codes:
				used[c] = true
		else:
			pending.append(id)
	for id: String in pending:
		var codes: Array = []
		for row: String in ["F", "B", "S"]:
			for i in (DIORAMA["xs"][row] as Array).size():
				var code := "%s%d" % [row, i]
				if codes.size() < 3 and not used.has(code):
					codes.append(code)
					used[code] = true
		out[id] = codes
	return out


static func _valid_slot(code: String) -> bool:
	if code.length() < 2 or not DIORAMA["xs"].has(code.substr(0, 1)):
		return false
	var i := int(code.substr(1))
	return code.substr(1).is_valid_int() and i >= 0 and i < (DIORAMA["xs"][code.substr(0, 1)] as Array).size()


const TITLE := {
	"wordmark1": Vector2(220, 64),
	"wordmark2": Vector2(196, 136),
	"tagline": Vector2(108, 224),
	"cta": Vector2(192, 584),
	"keyhint": Vector2(232, 632),
	"footer": Vector2(100, 1180),
}

const OVERLAY := {
	"settings": {
		"panelFs": Rect2(48, 192, 624, 880),
		"panelNoFs": Rect2(48, 192, 624, 776),
		"title": Vector2(264, 224),
		"closeVisual": Rect2(592, 220, 64, 64),
		"closeHit": Rect2(568, 200, 104, 104),
	},
	"reset": {
		"panel": Rect2(80, 400, 560, 448),
		"title": Vector2(228, 440),
		"bodyY": [512, 540, 568],
		"noteY": 616,
		"cancel": Rect2(112, 720, 232, 96),
		"cancelHit": Rect2(112, 716, 232, 104),
		"confirm": Rect2(376, 720, 232, 96),
		"confirmHit": Rect2(376, 716, 232, 104),
	},
	"evolution": {
		"panel": Rect2(48, 160, 624, 952),
		"title": Vector2(252, 200),
		"closeVisual": Rect2(592, 176, 64, 64),
		"closeHit": Rect2(568, 168, 104, 104),
		"back": Rect2(80, 984, 264, 96),
		"backHit": Rect2(80, 980, 264, 104),
		"confirm": Rect2(376, 984, 264, 96),
		"confirmHit": Rect2(376, 980, 264, 104),
		"bar": Rect2(112, 432, 496, 16),
	},
	"offline": {
		"panel": Rect2(48, 320, 624, 528),
		"title": Vector2(204, 360),
		"collect": Rect2(212, 720, 296, 96),
		"collectHit": Rect2(212, 716, 296, 104),
	},
}
