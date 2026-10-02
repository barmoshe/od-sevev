class_name RoundShare
extends RefCounted
## The seeded rounds' share adapter: hands a round's model to the share platform's drawer
## (`ShareKit.request`, its "challenge" / "daily" cards and the OG stubs /s/<leader>-challenge and
## /s/daily). Without a desk (a tool scene) the text goes through the shell's window.odShare.file
## (navigator.share({text}), else the clipboard), or the clipboard on a desktop run.
##
## The round's model (every value ready to print; nothing to recompute):
##   kind      "challenge" | "daily"
##   text      the share prose (the URL at the end), url, hash (challenge: the link's hash)
##   challenge leader, seed, t, ref, vs (−1 none), result ("" | win | lose | tie), mine, theirs
##   daily     n, key, leader, sec, mmss, cells ("BBYRW…"), grid (the emoji lines), court, press, streak

## True when the drawer is there (main built its ShareDesk).
static func platform() -> bool:
	return ShareKit.desk != null and is_instance_valid(ShareKit.desk)


## The drawer's model of a round's: challenge {leader, secs, seed, url_hash[, text]}, daily {n,
## grid_text, url_hash, text}. url_hash is the round's hash without k= and r= (the drawer's link adds
## its own r=<ref>&k=<kind>). `text` (no URL: the drawer puts the link on the last line) keeps the
## round's own copy where the platform's would say less: a return link's win / lose / tie, and the
## daily's whole grid with its time and court line. A first challenge takes the platform's copy.
static func platform_model(kind: String, model: Dictionary) -> Dictionary:
	var url := str(model.get("url", ""))
	var text := str(model.get("text", ""))
	if url != "":
		text = text.replace(url, "")
	text = text.strip_edges()
	var out := {"leader": str(model.get("leader", ""))}
	if kind == "daily":
		out["n"] = int(model.get("n", 1))
		out["grid_text"] = "\n".join(PackedStringArray(Array(model.get("grid", [])).map(func(x: Variant) -> String: return str(x))))
		out["url_hash"] = ""
		out["text"] = text
		return out
	var returning := str(model.get("result", "")) != ""
	out["secs"] = float(model.get("mine", model.get("t", 0))) if returning else float(model.get("t", 0))
	out["seed"] = int(model.get("seed", 0))
	var keep := PackedStringArray()
	for part: String in str(model.get("hash", "")).split("&", false):
		if not part.begins_with("k=") and not part.begins_with("r="):
			keep.append(part)
	out["url_hash"] = "&".join(keep)
	if returning:
		out["text"] = text
	return out


## Hands the model over: the drawer when it is there, else the text share. Returns the path taken:
## "platform" | "text" | "clipboard" (a desktop run without the web shell).
static func share(kind: String, model: Dictionary) -> String:
	if platform() and ShareKit.request(kind, platform_model(kind, model)):
		return "platform"
	var text := str(model.get("text", ""))
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.odShare && window.odShare.file(%s, '', '', %s)" % [JSON.stringify(kind), JSON.stringify(text)], true)
		return "text"
	DisplayServer.clipboard_set(text)
	return "clipboard"
