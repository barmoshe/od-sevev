class_name Display
extends RefCounted
## Integer art scaling (Bar's resolution request): 1 art px (= 4 logical px, the 180-wide art grid)
## is always a whole number k of DEVICE pixels, so no pixel is drawn 4 px wide next to one 5 px
## wide. The leftover width and height go to the aspect-`expand` area, as before.
##
##   k = max(1, min(floor(W / 180), floor(H / MIN_ART_H)))      W, H = the backing store, DPR included
##   f = k / 4   device px per logical px (Window.content_scale_factor, stretch mode disabled)
##
## The logical viewport becomes W/f × H/f: at least 720 wide (the column is centred, as the fork
## did for wide screens) and at least MIN_ART_H·4 tall, the smallest height the rtl-map flex rule
## lays out (Row A + Row B + ticker + tabs + the minimum stage and list = 1068 logical).
## Examples: 375×812 @2 (750×1624) → k 4; @3 (1125×2436) → k 6; 428×926 @3 → k 7;
## 390×844 @1 → k 2; a 1280×800 desktop window → k 2 (height-bound).
## Text: PxText snaps its scale so a font px is also a whole number of device px (text_scale()).

const ART_W := 180
const MIN_ART_H := 267       # ceil(1068 / 4)

static var k := 4
static var f := 1.0


static func art_px_for(win: Vector2) -> int:
	if win.x <= 0.0 or win.y <= 0.0:
		return 4
	return maxi(1, mini(int(floorf(win.x / ART_W)), int(floorf(win.y / MIN_ART_H))))


## Sets k and f for a window size; true when they changed.
static func update(win: Vector2) -> bool:
	var nk := art_px_for(win)
	if nk == k:
		return false
	k = nk
	f = k / 4.0
	return true


## A text scale in logical px per font px, snapped so it is a whole number of device px.
static func text_scale(s: float) -> float:
	return maxf(1.0, roundf(s * f)) / f
