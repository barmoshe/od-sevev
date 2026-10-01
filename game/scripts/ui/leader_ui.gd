class_name LeaderUi
extends RefCounted
## The views' one boundary to the round's leader (design/leader-select-spec.md §5, §10.1;
## ux/rtl-map.md §4.3). Every view that draws a word, a sprite or a surface that differs per leader
## asks here, so "is this Bibi's round?" is answered in one place. It reads the sim's installed
## round (`Leaders.installed()`, which Economy.derive keeps in step with the state every frame), so
## it needs no state. Content without leader select (the fork's, the fixtures) is always the
## default round: Bibi, the court, the hat.
##
## - `id()`, `art()`, `short()`, `party()`, `g()`: who plays this round.
## - `court()`: the court skin (Bibi) vs the press skin (everyone else). Bibi-only surfaces (the
##   aide button, the pardon row, the DOHA sticker) are hidden, not disabled, when it is false.
## - `s(key, params)`: a UI string through the hazard skin: COURT_* / HUD_SUSP* / TOAST_DOSSIER /
##   TOAST_COURT_END map to their PRESS_* twins, and the postpone verb, prefix and excuses come
##   from the leader's kit. Any other key is Strings.s.
## - `tap()`: the tap kit {prop, anim, critAnim, critEvent, critProp, verb, verbPlural, critName,
##   critPlural, frenzyBanner} with Bibi's words as the fallback.
## - `producer_art(id)` / `spin_icon(id)`: the per-leader source sprite and spin icon (spec §5.3-5.4).

## The press twins of the court keys (ux/rtl-map.md §4.3 "Hazard skin").
const PRESS := {
	"HUD_SUSP": "PRESS_SUSP", "HUD_SUSP_HOT": "PRESS_SUSP_HOT", "HUD_SUSP_BOIL": "PRESS_SUSP_BOIL",
	"TOAST_DOSSIER": "PRESS_REVEAL", "TOAST_COURT_END": "PRESS_END",
	"COURT_SUMMONS_TITLE": "PRESS_SUMMONS_TITLE", "COURT_SUMMONS_BODY": "PRESS_SUMMONS_BODY",
	"COURT_SUMMONS_EFFECT": "PRESS_SUMMONS_EFFECT", "COURT_SUMMONS_TIMER": "PRESS_SUMMONS_TIMER",
	"COURT_CHIP_SUMMONS": "PRESS_CHIP_SUMMONS", "COURT_TITLE": "PRESS_TITLE", "COURT_EFFECT": "PRESS_EFFECT",
	"COURT_TIMER": "PRESS_TIMER", "COURT_CHIP_TITLE": "PRESS_CHIP_TITLE", "COURT_TESTIFY": "PRESS_TESTIFY",
	"COURT_CHIP": "PRESS_CHIP", "DOS_COURT_DAYS": "PRESS_DAYS", "DOS_SUSP_FLOOR": "PRESS_SUSP_FLOOR",
}
## Bibi's tap words (the shipped build's), used when the content has no leader select.
const BIBI_TAP := {"prop": "prop_hat", "anim": "tap", "critAnim": "crit", "critEvent": "rabbit", "critProp": "prop_rabbit",
	"verb": "שליפה", "verbPlural": "שליפות", "critName": "ארנב", "critPlural": "ארנבים", "frenzyBanner": "טורבו בכובע!"}


## The round's leader id ("" on content without leader select: the default round).
static func id() -> String:
	return Leaders.installed() if Leaders.active() else ""


## The default leader's round (Bibi): the shipped game, the court and the hat.
static func is_default() -> bool:
	return Leaders.is_default(id())


## The court skin: Bibi's trial, the aide drop and the pardon desk. False = the press skin.
static func court() -> bool:
	return Leaders.has_court()


## What takes a leader's mark while he or she is off on the hazard day (Bar, 2026-10-01: every leader
## leaves the stage, not only Bibi): "court" (Bibi's hat), else kit.hazard.stage ("podium" | "bench").
static func stage_skin(leader_id: String = "") -> String:
	var lid := leader_id if leader_id != "" else id()
	if Leaders.is_default(lid):
		return "court"
	var h := Leaders.hazard(lid)
	if str(h.get("skin", "press")) == "court":
		return "court"
	return "bench" if str(h.get("stage", "podium")) == "bench" else "podium"


## stage_skin for a manifest slug (BigBanana knows the figure, not the leader): the round's leader
## when the slug is theirs, else the first playable leader drawn with it.
static func stage_skin_for_art(slug: String) -> String:
	if slug == art():
		return stage_skin()
	for lid: String in Leaders.pickable():
		if art(lid) == slug:
			return stage_skin(lid)
	return "court" if slug == "bibi" else "podium"


## The toast on a paused tap (courtPausesTaps): Bibi's court line, else the leader's own
## kit.hazard.tapPaused, else the generic press line by gender.
static func tap_paused_line(s: GameState = null) -> String:
	if s != null and Ability.walked_out(s) and str(Ability.copy(s).get("tapPaused", "")) != "":
		return str(Ability.copy(s)["tapPaused"])   # Ben Gvir's walkout (leaders v3)
	if court():
		return Strings.s("COURT_TAP_PAUSED")
	var own := str(Leaders.hazard(id()).get("tapPaused", ""))
	if own != "":
		return own
	return Strings.gendered("PRESS_TAP_PAUSED", g(), {"short": short()})


## The manifest slug of a leader's figure (the round's by default): leaders[].art, then the
## content's hero.char, then "bibi".
static func art(leader_id: String = "") -> String:
	var lid := leader_id if leader_id != "" else id()
	var a := str(Leaders.leader(lid).get("art", "")) if lid != "" else ""
	if a == "":
		a = str(Content.data().get("hero", {}).get("char", "bibi")) if Content.data().get("hero") is Dictionary else "bibi"
	var slug := SpriteStrip.resolve(a)
	return slug if slug != "" else a


static func short(leader_id: String = "") -> String:
	var lid := leader_id if leader_id != "" else id()
	return str(Leaders.leader(lid).get("short", "")) if lid != "" else ""


static func party(leader_id: String = "") -> String:
	var lid := leader_id if leader_id != "" else id()
	return str(Leaders.leader(lid).get("party", "")) if lid != "" else ""


static func g(leader_id: String = "") -> String:
	var lid := leader_id if leader_id != "" else id()
	return str(Leaders.leader(lid).get("g", "m")) if lid != "" else "m"


## The tap kit of a leader (the round's by default), over Bibi's words.
static func tap(leader_id: String = "") -> Dictionary:
	var lid := leader_id if leader_id != "" else id()
	var t: Dictionary = BIBI_TAP.duplicate() if Leaders.is_default(lid) else {}
	if lid != "":
		t.merge(Leaders.tap_kit(lid), true)
	for k: String in BIBI_TAP:
		if not t.has(k) or t[k] == null:   # a kit field left null (anim) reads as missing
			t[k] = BIBI_TAP[k] if k in ["anim"] else ""
	return t


## A UI string through the round's hazard skin (see the header). The press body names the leader
## by gender ({short}); the press postpone verb / prefix are the leader's kit words.
static func s(key: String, params: Dictionary = {}) -> String:
	if court():
		return Strings.s(key, params)
	var h := Leaders.hazard(id())
	match key:
		"COURT_BODY":
			var p := params.duplicate()
			p["short"] = short()
			return Strings.gendered("PRESS_BODY", g(), p)
		"COURT_POSTPONE_VERB":
			var v := str(h.get("postponeVerb", ""))
			return v if v != "" else Strings.s(key, params)
		"COURT_POSTPONED_PREFIX":
			var pf := str(h.get("postponePrefix", ""))
			return pf if pf != "" else Strings.s(key, params)
	var twin := str(PRESS.get(key, ""))
	if twin != "" and Strings.has(twin):
		return Strings.s(twin, params)
	return Strings.s(key, params)


## The press excuse for postponement step n (1-6; the leader's kit.hazard.excuses), or "" for the
## court (the view keeps its own excuse ladder).
static func press_excuse(step: int) -> String:
	if court():
		return ""
	var ex: Variant = Leaders.hazard(id()).get("excuses", [])
	if not ex is Array or (ex as Array).is_empty():
		return ""
	return str((ex as Array)[clampi(step - 1, 0, (ex as Array).size() - 1)])


## The thermometer / chip icon of the round's skin: the magnifier, or on court day the gavel for
## the court; the folded newspaper for the press (rtl-map §4.3: no gavel outside the court).
static func press_icon(which: String) -> String:
	var want := "thermo_icon_press" if which == "thermo" else "chip_icon_press"
	return want if Art.has_sprite(want) else ""


## The round's money-source art for a producer: the leader's skin sprite (spec §5.3: a kit's own
## or the shared generic set) as {sprite, icon, silhouette, source}; {} for Bibi and the shared
## tiers (the producer's own art).
static func producer_art(producer_id: String) -> Dictionary:
	var lid := id()
	if Leaders.is_default(lid):
		return {}
	var sk := Leaders.source_skin(lid, producer_id)
	var sp := str(sk.get("sprite", ""))
	if sp == "":
		return {}
	var src_id := sp.trim_prefix("source_")
	var e := Art.source(src_id, false)
	if e.is_empty():
		return {}
	return {"source": src_id, "sprite": str(e.get("sprite", sp)), "icon": str(e.get("icon", "")), "silhouette": str(e.get("silhouette", ""))}


## The round's name / flavor / level-up line for a producer ("" = the shipped one).
static func producer_word(producer_id: String, field: String) -> String:
	var lid := id()
	if Leaders.is_default(lid):
		return ""
	return str(Leaders.source_skin(lid, producer_id).get(field, ""))


## The round's spin skin field ("" = the shipped one).
static func spin_word(upgrade_id: String, field: String) -> String:
	var lid := id()
	if Leaders.is_default(lid):
		return ""
	return str(Leaders.spin_skin(lid, upgrade_id).get(field, ""))


## The round's spin icon: the skin's own, else spin_slot_<slot> (when the kit has it), else "".
static func spin_icon(upgrade_id: String) -> String:
	var ic := spin_word(upgrade_id, "icon")
	return ic if ic != "" and Art.has_sprite(ic) else ""


## The effect line of a skinned spin: the _LEADER key of slots A, B and E (rtl-map §4.3), filled
## with the round's verb / crit name; "" = the shipped upgradeEffects line.
static func spin_effect(upgrade_id: String) -> String:
	if not Leaders.active():
		return ""
	var key: String = {"s01": "SPIN_EFFECT_S01_LEADER", "s02": "SPIN_EFFECT_S02_LEADER", "s11": "SPIN_EFFECT_S11_LEADER"}.get(upgrade_id, "")
	if key == "" or not Strings.has(key):
		return ""
	var t := tap()
	return Strings.s(key, {"verb": str(t["verb"]), "critName": str(t["critName"])})


## Dubi's first-tap squawk for a leader (ux/ftue.md H1 / H1L): Bibi's DUBI_FIRSTTAP, else the
## kit's dubi.squawks.firsttap.
static func firsttap(leader_id: String = "") -> String:
	var lid := leader_id if leader_id != "" else id()
	if Leaders.is_default(lid):
		return Strings.s("DUBI_FIRSTTAP")
	var sq: Variant = Leaders.dubi(lid).get("squawks")
	var t := str((sq as Dictionary).get("firsttap", "")) if sq is Dictionary else ""
	return t if t != "" else Strings.s("DUBI_FIRSTTAP")
