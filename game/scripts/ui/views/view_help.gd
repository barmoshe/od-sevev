class_name HelpCard
extends SheetCard
## "איך זה עובד" (2026-10-03, the overwhelm report: the game explained nothing past its first
## minute and had no help). One sheet, from the settings row and the dossier: the loop in three
## lines, then one line per system the player has met (Reveal), the round's leader rule, and that
## a menu stops the clock. Systems not yet open stay unsaid.

func build() -> HelpCard:
	id = "HELP"
	_begin()
	title(Strings.s("HELP_TITLE"))
	close_x(func() -> void: cancel("close"))
	for line: String in lines(host.state if host != null else null):
		para(line)
	one_button(Strings.s("SYS_CLOSE"), "kit_secondary", func() -> void:
		host.audio_event("uiClick")
		cancel("close"))
	finish()
	return self


## The sheet's lines for this save (tests read them).
static func lines(s: GameState) -> PackedStringArray:
	var out := PackedStringArray([Strings.s("HELP_TAP"), Strings.s("HELP_61"), Strings.s("HELP_ELECT")])
	if Reveal.on(s, "spins"):
		out.append(Strings.s("HELP_SPINS"))
	if Reveal.on(s, "picker"):
		out.append(Strings.s("HELP_PICKER"))
	if s != null:
		var r: Dictionary = Leaders.rule(Leaders.current(s))
		if str(r.get("summary", "")) != "":
			out.append(Strings.s("HELP_RULE", {"rule": str(r.get("name", "")), "summary": str(r["summary"])}))
	if Reveal.on(s, "suspicion"):
		out.append(Strings.s("HELP_SUSP"))
	if Reveal.on(s, "ultimatums"):
		out.append(Strings.s("HELP_ULT"))
	if Reveal.on(s, "missions"):
		out.append(Strings.s("HELP_MISSIONS"))
	out.append(Strings.s("HELP_PAUSE"))
	return out


func cancel(via: String) -> void:
	host.audio_event("panelClose")
	mgr.close(self, via)
