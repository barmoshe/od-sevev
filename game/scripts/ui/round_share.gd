class_name RoundShare
extends RefCounted
## The seeded rounds' thin share adapter. The share platform (another slice, not merged yet) exposes
## `ShareKit.request(kind, model)` (its drawer, the generic "challenge" / "daily" card templates and
## the OG stubs /s/<leader>-challenge and /s/daily); until it lands the rounds share their text
## through the shell's existing window.odShare.file(kind, "", "", text): navigator.share({text}), else
## the clipboard (the result comes back on window.odShareDone, ShareKit.listen's path).
##
## The model handed to ShareKit.request (every value ready to print; nothing to recompute):
##   kind      "challenge" | "daily"
##   text      the share prose (the URL at the end), url, hash (challenge: the link's hash)
##   challenge leader, seed, t, ref, vs (−1 none), result ("" | win | lose | tie), mine, theirs
##   daily     n, key, leader, sec, mmss, cells ("BBYRW…"), grid (the emoji lines), court, press, streak

## True once the platform's request(kind, model) exists.
static func platform() -> bool:
	var sk := ShareKit.new()
	return sk.has_method("request")


## Hands the model over: the platform's drawer when it exists, else the text share. Returns the path
## taken: "platform" | "text" | "clipboard" (a desktop run without the web shell).
static func share(kind: String, model: Dictionary) -> String:
	var m := model.duplicate()
	m["kind"] = kind
	if platform():
		ShareKit.new().call("request", kind, m)
		return "platform"
	var text := str(m.get("text", ""))
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.odShare && window.odShare.file(%s, '', '', %s)" % [JSON.stringify(kind), JSON.stringify(text)], true)
		return "text"
	DisplayServer.clipboard_set(text)
	return "clipboard"
