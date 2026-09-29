class_name ResetCard
extends SheetCard
## O10, the reset confirm (ux/rtl-map.md §7.1-7.2 "ResetOverlay → O10, modal, side-by-side
## buttons"; first-minute §7.2 "Reset confirm"), over the settings sheet. It replaces the fork's
## overlay (review R7): ×3 text on a 553 card that ellipsised the consequences and the punchline,
## the destructive button first in RTL reading order, fork green and red.
##
##   title    RST_TITLE "בטוח?"
##   body     RST_BODY_1 (the joke), RST_BODY_2 (what is lost), RST_NOTE (muted): ×4 wrapping in the
##            modal.body box, the card grows
##   buttons  §7.1: side by side while both labels fit 224 px (×4): "התחרטתי" (cancel) on the RIGHT
##            Rect2(376, y, 256, 96), "למחוק הכול" (commit) on the LEFT Rect2(88, y, 256, 96);
##            stacked under large text (×5 "למחוק הכול" is 260 > 224), commit on top
##   look     cancel = kit button_secondary; commit = the 2D Artist's `button_danger` kit when it is
##            in the atlas, else button_secondary (never the fork's red)
##   focus    starts on cancel; the backdrop does not close it; Esc / back = cancel (back to O7)

var cancel_button: PxButton
var commit_button: PxButton


## The commit button's kind: the kit danger variant when the 2D Artist's sprites are in, else
## the kit secondary.
static func danger_kind() -> String:
	return "kit_danger" if Art.has_sprite("button_danger_default") else "kit_secondary"


func build() -> ResetCard:
	id = "RESET_CONFIRM"
	backdrop_closes = false
	_begin()
	title(Strings.s("RST_TITLE"))
	para(Strings.s("RST_BODY_1"))
	para(Strings.s("RST_BODY_2"))
	if Strings.has("RST_BODY_3"):
		para(Strings.s("RST_BODY_3"))
	para(Strings.s("RST_NOTE"), C_MUTED)
	two_buttons(Strings.s("RST_CONFIRM"), danger_kind(), func() -> void: host.confirm_reset(),
		Strings.s("RST_CANCEL"), func() -> void:
			host.audio_event("uiClick")
			cancel("close"))
	finish()
	commit_button = buttons[0]
	cancel_button = buttons[1]
	focus_index = default_focus()
	return self


func default_focus() -> int:
	return 1   # "התחרטתי"


func on_opened() -> void:
	publish_web()


func cancel(via: String) -> void:
	host.audio_event("panelClose")
	mgr.close(self, via)
