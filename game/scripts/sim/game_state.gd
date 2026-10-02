class_name GameState
extends RefCounted
## Everything that is saved. Run fields reset on Evolve (content.prestige.resets); the rest
## persists. Producer counts are keyed by id (save v2), so adding or reordering producers in
## content.json never scrambles a save.

# ---- run (reset on Evolve) ----
var bananas := 0.0
var run_bananas := 0.0
var owned: Dictionary = {}          # producer id -> int
var upgrades: PackedStringArray = []
var run_taps := 0
var buff_frenzy := 0.0              # seconds left
var buff_tap_frenzy := 0.0
var golden_timer_sec := 0.0
var evolve_ready_announced := false
var run_time_sec := 0.0

# ---- persistent ----
var thumbs_owned := 0               # lifetime Thumbs earned: drives the prestige multiplier
var thumbs_spent := 0               # spent in the Thumbs shop (never lowers the multiplier)
var shop: Dictionary = {}           # thumbs-shop node id -> level
var all_time_bananas := 0.0
var evolutions := 0
var golden_caught_lifetime := 0
var taps_lifetime := 0
var crits_lifetime := 0
var upgrades_bought_lifetime := 0
var headlines_seen: PackedStringArray = []
var achievements: PackedStringArray = []
var story_seen: PackedStringArray = []
var buy_mode: Variant = 1           # 1, 10 or "max"
var ftue: Dictionary = {}
var ui: Dictionary = {}
var stats: Dictionary = {}

# ---- od-sevev politics (save v3). Each module owns its dictionary's shape: fresh_state() for
# defaults, sanitize() at the load boundary, on_election() for what resets with the round. ----
var coalition: Dictionary = {}      # Coalition: the group chat, partners, price levels
var investigation: Dictionary = {}  # Investigation: suspicion, court, postponements, aide drops
var events: Dictionary = {}         # Events: scheduler, cooldowns, live effects
var album: Dictionary = {}          # Events: the photobomb album (lifetime)
var calendar: Dictionary = {}       # Calendar: the clock's high-water mark, mode, notices
var spins: Dictionary = {}          # Spins: consumable buys and live timers, line levels, flights (round)
var missions: Dictionary = {}       # Missions: rank, the 3 slots, claimed ids (meta: persists across elections)

# ---- leader select (save v4; Leaders owns the shape: fresh_into, sanitize_into, to_dict) ----
var leader := ""                    # the round's leader (fixed for the round; "" without leader content)
var leader_pick_pending := false    # the picker is open (after an election, on a new game) until the first tap
var leader_history: PackedStringArray = []   # the last 10 rounds' leaders; the fresh face reads the previous one
var leaders: Dictionary = {}        # id -> {rounds, elections, taps, crits, declines, bestRunSec, playSec}
var seat_deal: Dictionary = {}      # this round's slot per partner (a reload can't reroll it)
var leader_round: Dictionary = {}   # {prev, switched, fresh, freshPct, lastPlayed, begun, salt}
## Not saved: bumped whenever the leader or the deal changes (Leaders.ensure's cache key).
var leader_ver := 0

## Not saved: the lifetime tap count Politics.tick last saw (tapsAt2to4 counts the difference).
var taps_seen := -1


static func fresh() -> GameState:
	var s := GameState.new()
	for id in Content.producer_ids():
		s.owned[id] = 0
	s.golden_timer_sec = float(Content.data()["golden"]["firstSpawnDelaySec"])
	s.ftue = new_ftue()
	# perksHinted: the one F_PERKS_HINT nudge; partnerCardSeen: the chat avatars stop hinting (rev 5)
	s.ui = {"buyModeRevealed": false, "evolveRevealed": false, "tabsTouched": false, "perksHinted": false, "partnerCardSeen": false}
	s.stats = {"playtimeSec": 0.0, "bestBps": 0.0, "fastestRunSec": 0.0, "goldenMissed": 0.0, "streakUnder240sNow": 0.0}
	for k: String in Meta.STATS:
		s.stats[k] = 0.0
	s.coalition = Coalition.fresh_state()
	s.investigation = Investigation.fresh_state()
	s.events = Events.fresh_state()
	s.album = Events.fresh_album()
	s.calendar = Calendar.fresh_state()
	s.spins = Spins.fresh_state()
	s.missions = Missions.fresh_state()
	Leaders.fresh_into(s)
	return s


static func new_ftue() -> Dictionary:
	return {"p1": "", "p2": "", "p3": "", "p5": "", "p6": "", "p7": "", "p4": {"shown": 0, "state": ""}}


func owned_of(id: String) -> int:
	return int(owned.get(id, 0))


func thumbs_available() -> int:
	return maxi(0, thumbs_owned - thumbs_spent)


func duplicate_state() -> GameState:
	return GameState.from_dict(to_dict())


func to_dict() -> Dictionary:
	return {
		"bananas": bananas, "runBananas": run_bananas, "owned": owned.duplicate(),
		"upgrades": Array(upgrades), "runTaps": run_taps,
		"buffs": {"frenzy": buff_frenzy, "tapFrenzy": buff_tap_frenzy},
		"goldenTimerSec": golden_timer_sec, "evolveReadyAnnounced": evolve_ready_announced,
		"runTimeSec": run_time_sec,
		"thumbsOwned": thumbs_owned, "thumbsSpent": thumbs_spent, "shop": shop.duplicate(),
		"allTimeBananas": all_time_bananas, "evolutions": evolutions,
		"goldenCaughtLifetime": golden_caught_lifetime, "tapsLifetime": taps_lifetime,
		"critsLifetime": crits_lifetime, "upgradesBoughtLifetime": upgrades_bought_lifetime,
		"headlinesSeen": Array(headlines_seen), "achievements": Array(achievements),
		"storySeen": Array(story_seen), "buyMode": buy_mode,
		"ftue": ftue.duplicate(true), "ui": ui.duplicate(), "stats": stats.duplicate(),
		"coalition": coalition.duplicate(true), "investigation": investigation.duplicate(true),
		"events": events.duplicate(true), "album": album.duplicate(), "calendar": calendar.duplicate(),
		"spins": spins.duplicate(true), "missions": missions.duplicate(true),
	}.merged(Leaders.to_dict(self))


## Validates an untrusted dictionary into a clean state. Never throws; unknown or broken
## fields fall back to fresh defaults. Returns null when `raw` is not a dictionary.
static func from_dict(raw: Variant) -> GameState:
	if not raw is Dictionary:
		return null
	var r: Dictionary = raw
	var s := GameState.fresh()
	s.bananas = _num(r.get("bananas"))
	s.run_bananas = maxf(_num(r.get("runBananas")), s.bananas)
	var o: Variant = r.get("owned")
	if o is Dictionary:
		for id in Content.producer_ids():
			s.owned[id] = int(_num((o as Dictionary).get(id)))
	s.upgrades = _str_arr(r.get("upgrades"), func(id: String) -> bool: return not Content.upgrade(id).is_empty())
	s.run_taps = int(_num(r.get("runTaps")))
	var b: Variant = r.get("buffs")
	if b is Dictionary:
		s.buff_frenzy = _num((b as Dictionary).get("frenzy"))
		s.buff_tap_frenzy = _num((b as Dictionary).get("tapFrenzy"))
	s.golden_timer_sec = _num(r.get("goldenTimerSec"), s.golden_timer_sec)
	s.evolve_ready_announced = r.get("evolveReadyAnnounced") == true
	s.run_time_sec = _num(r.get("runTimeSec"))
	s.all_time_bananas = maxf(_num(r.get("allTimeBananas")), s.run_bananas)
	# The base can never exceed what the all-time total could have paid (a hand-edited save).
	s.thumbs_owned = mini(int(_num(r.get("thumbsOwned"))), Economy.base_cap(s.all_time_bananas, int(_num(r.get("evolutions")))))
	s.thumbs_spent = mini(int(_num(r.get("thumbsSpent"))), s.thumbs_owned)
	var sh: Variant = r.get("shop")
	if sh is Dictionary:
		for k: Variant in sh:
			if k is String:
				s.shop[k] = int(_num((sh as Dictionary)[k]))
	s.evolutions = int(_num(r.get("evolutions")))
	s.golden_caught_lifetime = int(_num(r.get("goldenCaughtLifetime")))
	s.taps_lifetime = int(_num(r.get("tapsLifetime")))
	s.crits_lifetime = int(_num(r.get("critsLifetime")))
	s.upgrades_bought_lifetime = int(_num(r.get("upgradesBoughtLifetime")))
	s.headlines_seen = _str_arr(r.get("headlinesSeen"))
	s.achievements = _str_arr(r.get("achievements"))
	s.story_seen = _str_arr(r.get("storySeen"))
	var bm: Variant = r.get("buyMode")
	s.buy_mode = bm if (bm is String and bm == "max") else (int(bm) if (bm is float or bm is int) and int(bm) in [1, 10] else 1)
	var f: Variant = r.get("ftue")
	if f is Dictionary:
		for k in ["p1", "p2", "p3", "p5", "p6", "p7"]:
			s.ftue[k] = str((f as Dictionary).get(k, "")) if (f as Dictionary).get(k) is String else ""
		var p4: Variant = (f as Dictionary).get("p4")
		if p4 is Dictionary:
			s.ftue["p4"] = {"shown": int(_num((p4 as Dictionary).get("shown"))), "state": str((p4 as Dictionary).get("state", ""))}
	var u: Variant = r.get("ui")
	if u is Dictionary:
		for k in s.ui.keys():
			s.ui[k] = (u as Dictionary).get(k) == true
	var st: Variant = r.get("stats")
	if st is Dictionary:
		for k in s.stats.keys():
			s.stats[k] = _num((st as Dictionary).get(k), s.stats[k])
		# Counters the engine adds by name (bestTapFrenzyTaps, evolvedNoInterns, ...) persist too:
		# any plain key with a valid number, at most MAX_EXTRA_STATS of them.
		var extra := 0
		for k: Variant in st:
			if extra >= MAX_EXTRA_STATS:
				break
			if k is String and not s.stats.has(k) and _STAT_KEY.search(k) != null and _num((st as Dictionary)[k], -1.0) >= 0.0:
				s.stats[k] = _num((st as Dictionary)[k])
				extra += 1
	Leaders.sanitize_into(s, r)   # first: the coalition's partner ids are the round's lineup
	s.coalition = Coalition.sanitize(r.get("coalition"))
	s.investigation = Investigation.sanitize(r.get("investigation"))
	s.events = Events.sanitize(r.get("events"))
	s.album = Events.sanitize_album(r.get("album"))
	s.calendar = Calendar.sanitize(r.get("calendar"))
	s.spins = Spins.sanitize(r.get("spins"))
	s.missions = Missions.sanitize(r.get("missions"))   # an older save: rank 1, fresh slots
	Meta.seed_stats(s)
	return s


const MAX_EXTRA_STATS := 64
static var _STAT_KEY := RegEx.create_from_string("^[A-Za-z][A-Za-z0-9_]{0,47}$")


static func _num(v: Variant, dflt: float = 0.0) -> float:
	if (v is float or v is int) and is_finite(float(v)) and float(v) >= 0.0:
		return float(v)
	return dflt


static func _str_arr(v: Variant, keep: Callable = Callable()) -> PackedStringArray:
	var out := PackedStringArray()
	if v is Array:
		for x: Variant in v:
			if x is String and not out.has(x) and (not keep.is_valid() or keep.call(x)):
				out.append(x)
	return out
