class_name ReturnCard
extends SheetCard
## O1, the return card (ux/rtl-map.md §7.2 "OfflineOverlay → O1, modal, one full button";
## first-minute §7.1), replacing the fork's "WELCOME BACK!" card (review R8). The money was
## credited and saved before the card opened (screen-graph §5 "credit, then receipt"), so every
## exit, the button, the backdrop, Esc and back, is a collect.
##
##   title + body   by the absence band: 1-15 min RET_*_SHORT, 15 min-8 h RET_*_MID, 8-48 h
##                  RET_*_LONG, > 48 h RET_TITLE_GONE_{TWO,OTHER} {n days} + RET_BODY_GONE
##   the number     RET_GAIN "+{x} ₪", money gold, centred; counts up on an in-session return, shown
##                  whole on a cold load (the fork's v2 rule)
##   chat line      RET_CHAT_{ONE,OTHER} when the chat has unread messages (ultimatums were paused)
##   cap line       RET_CAP {h} only when the offline cap was reached
##   button         RET_BTN "לאסוף" (kit gold: money)

var award := 0.0
var away_sec := 0.0
var capped := false
var cold := false
## {capHours} from the controller (Meta.away_cap_sec); older callers' note keys are ignored.
var info: Dictionary = {}
var amount_text: PxText
var _rolling := false
var _roll_t := 0.0
var _rolled := false
var _cue_played := false
var _beat_t := -1.0
var _close_in := -1.0


## The absence band's [title, body] for `sec` seconds away.
static func band_texts(sec: float) -> Array:
	var mins := sec / 60.0
	if mins < 15.0:
		return [Strings.s("RET_TITLE_SHORT"), Strings.s("RET_BODY_SHORT")]
	if sec < 8.0 * 3600.0:
		return [Strings.s("RET_TITLE_MID"), Strings.s("RET_BODY_MID")]
	if sec < 48.0 * 3600.0:
		return [Strings.s("RET_TITLE_LONG"), Strings.s("RET_BODY_LONG")]
	var days := maxi(2, int(floorf(sec / 86400.0)))
	return [Strings.plural("RET_TITLE_GONE", days, {"n": str(days)}), Strings.s("RET_BODY_GONE")]


func build() -> ReturnCard:
	id = "OFFLINE"
	var s: GameState = host.state if host != null and "state" in host else null
	_begin()
	var bt := band_texts(away_sec)
	title(str(bt[0]))
	para(str(bt[1]))
	amount_text = para(_gain(award if cold else 0.0), C_GOLD, true, 1)
	if cold:
		_rolled = true
	var unread := int(s.coalition.get("unread", 0)) if s != null and s.coalition is Dictionary else 0
	if unread > 0:
		para(Strings.plural("RET_CHAT", unread, {"n": str(unread)}))
	if capped:
		para(Strings.s("RET_CAP", {"h": str(int(info.get("capHours", 8)))}), C_MUTED)
	one_button(Strings.s("RET_BTN"), "kit_gold", _collect)
	finish()
	return self


func _gain(x: float) -> String:
	return Strings.s("RET_GAIN", {"x": Fmt.amount(x)})


func _set_amount(x: float) -> void:
	amount_text.text = _gain(x)
	amount_text.center_in(CARD_X + (CARD_W - TEXT_W) / 2.0, TEXT_W)


func on_opened() -> void:
	publish_web()
	if not cold:
		_start_roll()


func _start_roll() -> void:
	if _rolling or _rolled:
		return
	_rolling = true
	_roll_t = 0.0


func _collect() -> void:
	host.audio_event("uiClick")
	if cold:
		_play_cue()
	if not _rolled:
		_finish_roll()
	_close_now("close")


func _finish_roll() -> void:
	_rolling = false
	_rolled = true
	_set_amount(award)
	_play_cue()


func _play_cue() -> void:
	if _cue_played:
		return
	_cue_played = true
	host.audio_event("offlineCollect")


func update_view(dt_ms: float) -> void:
	if _rolling:
		_roll_t += dt_ms
		var p := minf(1.0, _roll_t / float(Tune.T["offlineRollMs"]))
		_set_amount(floorf(award * Ui.cubic_out(p)))
		if p >= 1.0:
			_finish_roll()
			_beat_t = 0.0
			if cold:
				_close_in = float(Tune.MC["offlineCloseAfterRollMs"])
	if _beat_t >= 0.0:
		_beat_t += dt_ms
		if _beat_t >= float(Tune.MC["offlineEndBeatMs"]):
			_beat_t = -1.0
	if _close_in >= 0.0:
		_close_in -= dt_ms
		if _close_in < 0.0 and not closing:
			_close_now("close")


func _close_now(via: String, silent: bool = false) -> void:
	_close_in = -1.0
	if not silent:
		host.audio_event("panelClose")
	host.offline_collected()
	mgr.close(self, via)


## Backdrop / Esc / back: every exit collects (the money is already in the bank). A cold-load Esc
## or back is silent: neither grants the user activation the audio needs (screen-graph §5).
func cancel(via: String) -> void:
	if closing:
		return
	var silent := cold and not _rolling and not _rolled and (via == "esc" or via == "back")
	if not _rolled:
		_rolling = false
		_rolled = true
		_set_amount(award)
		if not silent:
			_play_cue()
	_close_now(via, silent)
