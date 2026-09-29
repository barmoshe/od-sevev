class_name LayerHistory
extends RefCounted
## Browser history for the game's layers (ux/rtl-map.md §7.1 "History", review R9): one history
## entry per open layer (every overlay, the partner card, T3/T4, the expanded court card), so the
## browser's back button (and Android's back in a WhatsApp in-app browser) closes the top layer
## exactly as ✕/Esc does instead of leaving the game. With no layer open, back leaves the page as a
## browser expects: the root is never trapped.
##
## Pure bookkeeping, no JavaScript: the controller feeds it the open-layer count every frame
## (sync) and every popstate the shell forwards (on_pop), and runs the returned actions through
## JavaScriptBridge (history.pushState / history.go). A layer closed in the game (✕, Esc, a tap)
## rewinds the extra entries with one history.go(-n), whose own popstate must not close another
## layer: that is `_ignore`.

## Entries this page has pushed above the root (= layers the browser knows about).
var pushed := 0
var _ignore := 0


## The game now has `depth` layers open. Returns {"push": n} (history.pushState n times) or
## {"back": n} (history.go(-n)), or {} when the browser already agrees.
func sync(depth: int) -> Dictionary:
	depth = maxi(0, depth)
	if depth > pushed:
		var n := depth - pushed
		pushed = depth
		return {"push": n}
	if depth < pushed:
		var k := pushed - depth
		pushed = depth
		_ignore += 1   # history.go(-k) fires one popstate
		return {"back": k}
	return {}


## A popstate arrived. True when it is the player's back (close the top layer now); false when it
## is the echo of our own history.go, or there is no layer entry left (the root: nothing to close).
func on_pop() -> bool:
	if _ignore > 0:
		_ignore -= 1
		return false
	if pushed <= 0:
		return false
	pushed -= 1
	return true


## The JavaScript for one sync() result ("" when there is nothing to do).
static func js_for(action: Dictionary) -> String:
	if action.has("push"):
		var js := ""
		for i in int(action["push"]):
			js += "history.pushState({od: 1}, '');"
		return "try { %s } catch (e) {}" % js
	if action.has("back"):
		return "try { history.go(-%d); } catch (e) {}" % int(action["back"])
	return ""
