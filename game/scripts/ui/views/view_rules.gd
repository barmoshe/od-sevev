class_name ViewRules
extends RefCounted
## The views' pure rules (no nodes): what the thermometer, the cottage cup, the court card, the
## dossier, the Dubi flash and the desktop phone frame show for a given state. Every view reads
## these, and tests/unit/test_views.gd pins them. Numbers come from content (content.json) and the
## Animator's motion constants (motion/motion-spec.yaml, read through mc() so Tune.MC wins once the
## engine mirrors them); layout numbers are ux/rtl-map.md's.


## A motion constant: Tune.MC when the engine has mirrored it, else motion-spec.yaml's value.
const MC_DEFAULTS := {
	"courtCardInMs": 280, "courtTintAlpha": 0.18, "courtTintMs": 400, "courtCardOutMs": 180,
	"excuseReadMsPerChar": 60, "excuseReadMinMs": 2000, "stampSlamMs": 90,
	"tallTabOpenMs": 280, "tallTabCloseMs": 200, "tallTabOpenReducedMs": 150, "tallTabCloseReducedMs": 120,
	"thermoRevealMs": 280, "thermoFillMs": 300, "thermoOpacityMs": 200, "thermoDimAfterMs": 3000,
	"thermoBubbleRiseMs": 900, "thermoBubbleRiseBoilMs": 450, "thermoBubbleStaggerMs": 300,
	"cottageAppearMs": 200, "cottageHoldMs": 3000, "cottageSettleMs": 300, "cottageParticleMs": 500,
	"cottageMinusMs": 600,
	"sweatEveryMs": 1200, "sweatEveryBoilMs": 600, "sweatFallMs": 400,
	"flashLineStaggerMs": 150, "flashLineInMs": 120,
}


static func mc(key: String) -> float:
	if Tune.MC.has(key):
		return float(Tune.MC[key])
	return float(MC_DEFAULTS.get(key, 0.0))


# ---------------------------------------------------------------------------------------------
# Suspicion thermometer (ux/first-minute.md §3.2 #3, rtl-map §4, motion-spec suspicion-thermometer)
# ---------------------------------------------------------------------------------------------

const HOT_PCT := 75.0
const BOIL_PCT := 95.0
const DIM_BELOW_PCT := 50.0


## The thermometer's state word key: "חשד" / "מבעבע" (≥ 75) / "רותח!" (≥ 95).
static func thermo_word_key(pct: float) -> String:
	if pct >= BOIL_PCT:
		return "HUD_SUSP_BOIL"
	if pct >= HOT_PCT:
		return "HUD_SUSP_HOT"
	return "HUD_SUSP"


## The icon swap (magnifier → gavel at ≥ 75%, the non-colour channel).
static func thermo_icon(pct: float) -> String:
	return "thermo_icon_gavel" if pct >= HOT_PCT else "thermo_icon_magnifier"


## Bubbles: 0 none, 1 bubbling (≥ 75), 2 boiling (≥ 95, twice the rate).
static func thermo_bubble_level(pct: float) -> int:
	return 2 if pct >= BOIL_PCT else (1 if pct >= HOT_PCT else 0)


## Liquid height in whole art px for a 0-100 value in a column `col_ap` tall.
static func liquid_ap(pct: float, col_ap: int) -> int:
	return clampi(int(roundf(clampf(pct, 0.0, 100.0) / 100.0 * float(col_ap))), 0, col_ap)


## UX fade rule: 60% while under 50% and unchanged for 3 s, 100% on any change or at ≥ 50%.
static func thermo_alpha(pct: float, ms_since_change: float) -> float:
	if pct >= DIM_BELOW_PCT or ms_since_change < mc("thermoDimAfterMs"):
		return 1.0
	return 0.6


# ---------------------------------------------------------------------------------------------
# Cottage Index (rtl-map §2, ux/ftue.md Q1, motion-spec cottage-pixel-loss)
# ---------------------------------------------------------------------------------------------

## The content's cottage thresholds: headlines carrying `cottagePixel` k, as [[k, trigger], …]
## sorted by k. The cup shows state k once trigger k holds (13 kit states: 0 full … 12 empty).
static func cottage_steps() -> Array:
	var out: Array = []
	for h: Variant in Content.data().get("headlines", []):
		if h is Dictionary and (h as Dictionary).has("cottagePixel"):
			out.append([int((h as Dictionary)["cottagePixel"]), (h as Dictionary).get("trigger", {})])
	out.sort_custom(func(a: Array, b: Array) -> bool: return int(a[0]) < int(b[0]))
	return out


## The trigger kinds the cottage thresholds use (content: allTimeBananas; the treasury kinds are
## accepted too so the designer can switch the cup to the live treasury as data).
static func _trigger_met(s: GameState, t: Variant) -> bool:
	if not t is Dictionary:
		return false
	var v := float((t as Dictionary).get("value", INF))
	match String((t as Dictionary).get("type", "")):
		"allTimeBananas":
			return s.all_time_bananas >= v
		"bananasAtOnce", "treasury":
			return s.bananas >= v
		"runBananas":
			return s.run_bananas >= v
	return false


## The cup's frame (0 full … frames-1): the highest cottagePixel whose trigger holds.
static func cottage_frame(s: GameState, frames: int = 13) -> int:
	var k := 0
	for st: Array in cottage_steps():
		if _trigger_met(s, st[1]):
			k = maxi(k, int(st[0]))
	return clampi(k, 0, maxi(0, frames - 1))


## Q1: the cup appears with the first threshold (content: 1,000 ₪ lifetime).
static func cottage_revealed(s: GameState) -> bool:
	var steps := cottage_steps()
	return not steps.is_empty() and _trigger_met(s, (steps[0] as Array)[1])


# ---------------------------------------------------------------------------------------------
# Court card (rtl-map §6.4, copy deck §H through content.court.postpone.copy)
# ---------------------------------------------------------------------------------------------

## "m:ss" for a seconds count (ceil, so 0:01 shows until the last frame).
static func mmss(sec: float) -> String:
	var s := maxi(0, int(ceilf(sec - 0.001)))
	return "%d:%02d" % [s / 60, s % 60]


## The excuse sentences for ladder step n (1-based, clamped to the content's ladder): the step's
## full line split after each full stop, so the view reveals one sentence at a time.
static func excuse_sentences(step: int) -> PackedStringArray:
	var ex: Array = Investigation.cfg().get("postpone", {}).get("copy", {}).get("excuses", [])
	if ex.is_empty():
		return PackedStringArray()
	var line := String(ex[clampi(step, 1, ex.size()) - 1])
	var out := PackedStringArray()
	var cur := ""
	for i in line.length():
		cur += line[i]
		if line[i] == "." and (i + 1 >= line.length() or line[i + 1] == " "):
			out.append(cur.strip_edges())
			cur = ""
	if cur.strip_edges() != "":
		out.append(cur.strip_edges())
	return out


## The reading hold after the excuse lands: max(excuseReadMinMs, excuseReadMsPerChar × chars).
static func excuse_hold_ms(sentences: PackedStringArray) -> float:
	var n := 0
	for s_: String in sentences:
		n += s_.length()
	return maxf(mc("excuseReadMinMs"), mc("excuseReadMsPerChar") * float(n))


## The court card's model for the current state: {phase, show, timerSec, canPostpone, cost,
## canTestify, aide}. `show` false = no card (idle).
static func court_model(s: GameState, d: Economy.Derived) -> Dictionary:
	var ph := Investigation.phase(s) if Investigation.active() else "idle"
	var st: Dictionary = s.investigation
	var m := {"phase": ph, "show": ph == "summons" or ph == "court", "timerSec": 0.0,
		"canPostpone": false, "cost": -1.0, "affordable": false, "canTestify": ph == "summons",
		"aide": Investigation.can_drop_aide(s) if Investigation.active() else false}
	match ph:
		"summons":
			var auto := float(Investigation.cfg().get("summonsAutoTestifySec", 0.0))
			m["timerSec"] = maxf(0.0, auto - float(st.get("summonsSec", 0.0))) if auto > 0.0 else 0.0
			var c := Investigation.postpone_cost(s, d)
			m["cost"] = c
			m["canPostpone"] = c >= 0.0
			m["affordable"] = Investigation.can_postpone(s, d)
		"court":
			m["timerSec"] = float(st.get("leftSec", 0.0))
	return m


# ---------------------------------------------------------------------------------------------
# Dossier "תיקים" (T4, rtl-map §6.3) and its trophies ("תיק הישגים")
# ---------------------------------------------------------------------------------------------

## K2: the dossier exists once a case was ever opened. Derived from persisted sim state only
## (GameState.ui keeps just its fresh() keys across a save), so a reload agrees with the session.
static func dossier_revealed(s: GameState) -> bool:
	if s.evolutions >= 1:
		return true
	if not Investigation.active():
		return false
	var st: Dictionary = s.investigation
	return Investigation.suspicion(s) > 0.0 or int(st.get("courtDays", 0)) > 0 or int(st.get("aideDrops", 0)) > 0 \
		or int(st.get("pardons", 0)) > 0 or int(st.get("postponementsLifetime", 0)) > 0


## The kit art for a content trophy icon ("icon_folder" → "trophy_folder"), earned or locked.
static func trophy_icon(icon: String, earned: bool) -> String:
	var base := "trophy_" + icon.trim_prefix("icon_")
	return base if earned else base + "_locked"


## One trophy's display model: {id, earned, secret, plate, icon, name, desc, progress}.
## A secret trophy shows the secret plate and no icon until earned; a neverAwarded one (Gantz's
## rotation) is never earned and shows its fakeProgress.
static func trophy_model(s: GameState, a: Dictionary) -> Dictionary:
	var earned := s.achievements.has(a.get("id", "")) and not a.get("neverAwarded", false)
	var secret: bool = a.get("secret", false) == true and not earned
	var m := {"id": a.get("id", ""), "earned": earned, "secret": secret,
		"plate": "trophy_plate_earned" if earned else ("trophy_plate_secret" if secret else "trophy_plate_locked"),
		"icon": "" if secret else trophy_icon(String(a.get("icon", "icon_folder")), earned),
		"name": Strings.s("TROPHY_SECRET") if secret else String(a.get("name", "")),
		"desc": Strings.s("TROPHY_LOCKED") if secret else String(a.get("desc", "")),
		"progress": -1.0}
	if a.has("fakeProgress") and not earned:
		m["progress"] = clampf(float(a["fakeProgress"]), 0.0, 1.0)
	return m


## The trophies that count (neverAwarded ones never do): earned / total.
static func trophy_counts(s: GameState) -> Vector2i:
	var n := 0
	var total := 0
	for a: Dictionary in Meta.achievements():
		if a.get("neverAwarded", false):
			continue
		total += 1
		if s.achievements.has(a["id"]):
			n += 1
	return Vector2i(n, total)


## The trophy bonus in % (TROPHY_SUMMARY {pct}), without a trailing ".0".
static func trophy_bonus_pct(s: GameState) -> String:
	var pct := Meta.achievement_pct(s) * float(trophy_counts(s).x) * 100.0
	return Fmt.mult(pct).trim_suffix(".0")


## The dossier's stat rows, in order: [[key, params], …] (DOS_* strings).
static func dossier_stats(s: GameState, d: Economy.Derived) -> Array:
	var st: Dictionary = s.investigation if s.investigation is Dictionary else {}
	var base_pct := maxf(0.0, (d.prestige_mult - 1.0) * 100.0)
	var rows: Array = [
		["DOS_ROUNDS", {"n": s.evolutions}],
		["DOS_COURT_DAYS", {"n": int(st.get("courtDays", 0))}],
		["DOS_POSTPONES", {"n": int(st.get("postponementsLifetime", 0))}],
		["DOS_TOTAL", {"x": Fmt.amount(s.all_time_bananas)}],
		["DOS_CAUGHT", {"n": s.golden_caught_lifetime}],
		["DOS_ARRIVED", {"n": int(float(s.stats.get("goldenMissed", 0.0)))}],
		["DOS_BASE", {"n": Fmt.thumbs(s.thumbs_owned), "pct": Fmt.mult(base_pct).trim_suffix(".0")}],
	]
	if Investigation.active():
		rows.append(["DOS_SUSP_FLOOR", {"pct": int(roundf(Investigation.floor_pct(s)))}])
	return rows


## Dubi's news-flash rounds a player has seen: n = evolutions … 1 (newest first).
static func archive_rounds(s: GameState) -> Array:
	var out: Array = []
	for n in range(s.evolutions, 0, -1):
		out.append(n)
	return out


## The flash's beat title for round n (story.titles[n-1]); "" for the encore rounds.
static func flash_title(n: int) -> String:
	var titles: Array = Content.data().get("story", {}).get("titles", [])
	return String(titles[n - 1]) if n >= 1 and n <= titles.size() else ""


## The album slot ("Always in the Frame") shows only while its content flag is on.
static func album_enabled() -> bool:
	var pb: Dictionary = Events.cfg().get("photobomb", {}) if Events.cfg() is Dictionary else {}
	var flag := String(pb.get("flag", "postLaunch"))
	return Events.flag_on(flag)


# ---------------------------------------------------------------------------------------------
# Desktop phone frame (first-minute §1.3: desktop = the same game inside a centred phone column)
# ---------------------------------------------------------------------------------------------

## Side panels appear once the viewport is wider than a phone: the column (720 logical) plus at
## least MIN_SIDE on each side.
const FRAME_MIN_SIDE := 48.0


## [left, right] side-panel rects in `_root` space (the column spans ox .. ox + 720), or [] on a
## phone-shaped viewport.
static func frame_sides(vs: Vector2, ox: float) -> Array:
	if ox < FRAME_MIN_SIDE:
		return []
	var right_x := ox + float(L.W)
	return [Rect2(-8.0, -8.0, ox + 8.0, vs.y + 16.0), Rect2(right_x, -8.0, maxf(0.0, vs.x - right_x) + 8.0, vs.y + 16.0)]
