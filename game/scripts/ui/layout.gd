class_name L
extends RefCounted
## od-sevev layout: ux/rtl-map.md (engine-concrete, RTL values given directly, not a runtime flip)
## on the 720-logical canvas (1 art px = 4 logical px). Sections, top to bottom:
##   _top    Row A (0-96: counter, rate, mute, gear, cottage) + Row B (96-180: seats bar)
##   _stage  the stage, height S (flex); its node sits at screen y - STAGE.y, so stage-local
##           design y runs STAGE.y .. STAGE.y + S (the fork's coordinates stay valid)
##   _lower  ticker (0-84), card panel (84 .. 84+P, flex), tab bar (84+P .. 188+P)
## S and P come from the flex rule (rtl-map §1), set by MainController._relayout via set_flex().

const W := 720
const H := 1280
## The game is Hebrew-only (ux A3): one switch (Bidi.UI_RTL).
const RTL := Bidi.UI_RTL
## Text scale: body ×4 on the art grid (rtl-map §0, D11); large-text mode draws ×5.
const TEXT := 4

## rtl-map §1 flex rule
const ROW_A_H := 96
const ROW_B_H := 84
const TICKER_H := 84
const TABS_H := 104
const FIXED_H := ROW_A_H + ROW_B_H + TICKER_H + TABS_H
const STAGE_PREF := 640
const STAGE_MIN := 460
const LIST_MIN := 240

static var stage_h := 640.0     # S
static var panel_h := 378.0     # P


## S and P for R = vs.y - insets - FIXED_H.
static func flex(r: float) -> Vector2:
	var s: float
	if r >= 1018.0:
		s = STAGE_PREF + floorf(0.4 * (r - 1018.0) / 4.0) * 4.0
	else:
		s = clampf(floorf((r - LIST_MIN) / 4.0) * 4.0, STAGE_MIN, STAGE_PREF)
	return Vector2(s, maxf(0.0, r - s))


static func set_flex(r: float) -> void:
	var v := flex(r)
	stage_h = v.x
	panel_h = v.y


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
	"tag": Rect2(616, 18, 96, 48),
	"dubiFeet": Vector2(580, 84),
	"tagRight": 696,
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


static func tabs_y() -> float:
	return float(SHOP["listY"]) + panel_h


## The tab slot rect (1-4, reading order right → left), `_lower`-local.
static func tab_rect(slot: int) -> Rect2:
	return Rect2(540.0 - 180.0 * (slot - 1), tabs_y(), 180, TABS_H)


## Card internals, card-local (rtl-map §6.1).
const ROW := {
	"plate": Rect2(588, 8, 104, 104),
	"iconCenter": Vector2(640, 60),
	"nameRight": 580, "nameY": 16, "nameW": 384,
	"line2Right": 580, "line2Y": 64, "line2W": 288, "line2WideW": 384,
	"ownedX": 204, "ownedY": 64,
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
