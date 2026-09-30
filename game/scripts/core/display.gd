class_name Display
extends RefCounted
## Integer art scaling (Bar's resolution decision, 2026-09-29): 1 art px (= 4 logical px, the
## 180-wide art grid) is always a whole number k of DEVICE pixels, so no art pixel is drawn 4 px
## wide next to one 5 px wide. The leftover width and height go to the aspect-`expand` area (the
## column is centred; the stage's padTop / padBottom and the extended backdrops fill the rest).
##
##   fit = min(floor(W / 180), floor(H / MIN_ART_H))    W, H = the backing store, DPR included
##   k   = crisp(fit): the largest k ≤ fit that is a multiple of 2 or 3 (1 stays 1)
##   f   = k / 4   device px per logical px
##
## The crisp rule (Bar, "sharp characters on every phone", 2026-09-29): every rendered character and
## money source ships a d 3 render and a d 2 alternate (CONTRACT.md §3), and SpriteStrip picks the
## largest density dividing k, so a sprite px is a whole number of device px exactly when k is a
## multiple of 2 or 3. k 5 → 4, 7 → 6, 11 → 10, 13 → 12; the remainder is letterboxed like any
## other leftover (the aspect-`expand` area). k 1 (a sub-360-px surface) has no crisp alternative
## and stays 1 (it is the unit tests' smallest integer surface, never a phone).
##
## The logical viewport becomes W/f × H/f: at least 720 wide and at least MIN_ART_H·4 tall, the
## smallest height the rtl-map flex rule lays out (Row A + Row B + ticker + tabs + the minimum
## stage and list = 1068 logical). The height bound only bites on landscape windows (desktop).
## Examples: 390×844 @2 (780×1688) → k 4; @3 (1170×2532) → k 6; 375×812 @2 → k 4; 428×926 @3
## (fit 7) → k 6; 412×915 @3.5 (fit 8) → k 8; 390×844 @1 → k 2; a 1280×800 desktop window → k 2
## (height-bound); 1440×900 @1 → k 3; 1440×900 @2 (fit 6) → k 6.
##
## Fallback: a surface too small for k = 1 (under 180×267 device px: the 64×64 headless window of
## the unit tests, a thumbnail) cannot hold the layout at any integer scale, so it keeps the fork's
## fractional stretch (canvas_items + expand at 720×1280): `integer` is false and f = min(W/720,
## H/1280). No phone reaches it.
##
## Where the scale is applied is the controller's call (main.gd `_apply_display`): the window's
## own content scale, or a SubViewport's size_2d_override when the scene renders into one.
## Text: PxText snaps its scale so a font px is also a whole number of device px (text_scale()).
## Sprites: SpriteStrip draws a density-d texture at 4/d logical px per sprite px, crisp when
## k % d == 0 and through SpriteStrip.fractional_filter otherwise.

const ART_W := 180
const ART_PX := 4             # logical px per art px (L.W / ART_W)
const MIN_ART_H := 267        # ceil(1068 / 4)
const FORK_W := 720           # the fork's design canvas (project.godot), for the fallback
const FORK_H := 1280

static var k := 4
static var f := 1.0
static var integer := true
## The art grid (ux/mobile-first-layout.md §0.1, §2): whole art columns and rows of the device
## surface at k. Two phones with the same k (390@3 and 430@3 are both k 6) differ only here: the
## layout fills this grid instead of centring a 180 × 267 column in it. The fallback (no integer
## scale) keeps 180 × 320.
static var cols := ART_W
static var rows := 320


## The integer art scale for a device size (crisp_k of the largest that fits); 0 when not even
## k = 1 fits.
static func art_px_for(win: Vector2) -> int:
	return crisp_k(fit_k(win))


## The largest integer art scale that fits a device size, before the crisp rule; 0 when none.
static func fit_k(win: Vector2) -> int:
	if win.x <= 0.0 or win.y <= 0.0:
		return 0
	return maxi(0, mini(int(floorf(win.x / ART_W)), int(floorf(win.y / MIN_ART_H))))


## The crisp rule: the largest k' ≤ k that is a multiple of 2 or 3, where every density the art
## ships (d 1, d 2, d 3) has a variant drawing whole device px per sprite px. 0 and 1 pass through.
static func crisp_k(k: int) -> int:
	if k <= 1:
		return maxi(0, k)
	var c := k
	while c % 2 != 0 and c % 3 != 0:
		c -= 1
	return c


## True when k is on the crisp set (a multiple of 2 or 3).
static func is_crisp(k: int) -> bool:
	return k >= 2 and (k % 2 == 0 or k % 3 == 0)


## The fork's fractional stretch factor (canvas_items + expand): device px per logical px.
static func fork_f(win: Vector2) -> float:
	if win.x <= 0.0 or win.y <= 0.0:
		return 1.0
	return minf(win.x / FORK_W, win.y / FORK_H)


## Sets k, f and `integer` for a device size; true when they changed. `force_fractional` keeps the
## fork's stretch (the --fork-scale "before" shots).
static func update(win: Vector2, force_fractional: bool = false) -> bool:
	var nk := 0 if force_fractional else art_px_for(win)
	var ni := nk >= 1
	var nf := nk / float(ART_PX) if ni else fork_f(win)
	nk = maxi(1, nk)
	# the grid first: it changes with the size even when k does not (before the early return)
	cols = int(floorf(win.x / nk)) if ni else ART_W
	rows = int(floorf(win.y / nk)) if ni else 320
	if nk == k and ni == integer and is_equal_approx(nf, f):
		return false
	k = nk
	f = nf
	integer = ni
	return true


## The layout width in logical px (mobile-first §2): whole art columns on the 4-px grid, 720 at
## 180 columns. The chrome spans it; only the stage art stays a centred 720 column.
static func cw() -> float:
	return float(cols * ART_PX)


## The logical viewport size for a device size at the current f.
static func logical_size(win: Vector2) -> Vector2:
	return win / f


## Device px per art px at the current scale (a whole number when `integer`).
static func device_per_art() -> float:
	return f * ART_PX


## A text scale in logical px per font px, snapped so it is a whole number of device px (the
## fractional fallback has no device grid to snap to: the scale passes through).
static func text_scale(s: float) -> float:
	if not integer:
		return s
	return maxf(1.0, roundf(s * f)) / f


## A logical position snapped to the nearest whole device px (unchanged in the fallback).
static func snap(v: Vector2) -> Vector2:
	if not integer:
		return v
	return (v * f).round() / f
