extends Node
## Autoload `Juice`: the v1.1 UI juice runtime (motion/ui-juice.yaml `_juice_globals`). Every entry
## is a time-sampled table of whole-pixel values: frame i = floor(elapsedMs / 16.667) and
## value = table[min(i, last)], so nothing is eased between entries and every value is on its grid.
## MainController ticks it once per frame after the views.

var reduced := false
var _items: Dictionary = {}   # key (Object or String) -> {t, dur, step, done, fresh}


static func frame_index(elapsed_ms: float) -> int:
	return int(floorf(elapsed_ms / Tune.FRAME_MS))


## table[min(floor(t / 16.667), last)]
static func sample(table: Array, elapsed_ms: float) -> Variant:
	return table[clampi(frame_index(elapsed_ms), 0, table.size() - 1)]


## Starts (or restarts) the entry under `key`. step(t) runs now at t = 0 and every frame after.
func play(key: Variant, dur_ms: float, step: Callable, done: Callable = Callable()) -> void:
	_items[key] = {"t": 0.0, "dur": dur_ms, "step": step, "done": done, "fresh": true}
	step.call(0.0)


func has(key: Variant) -> bool:
	return _items.has(key)


## Stops an entry. `finish` runs its done() (the rest pose); otherwise the caller owns the cut.
func cancel(key: Variant, finish: bool = false) -> void:
	if not _items.has(key):
		return
	var e: Dictionary = _items[key]
	_items.erase(key)
	if finish and (e["done"] as Callable).is_valid():
		(e["done"] as Callable).call()


func tick(dt_ms: float) -> void:
	for key: Variant in _items.keys():
		if not _items.has(key):
			continue
		var e: Dictionary = _items[key]
		# The owner of an entry can be freed mid-animation (an overlay closing during a rebound):
		# drop the entry instead of calling into a freed object.
		if (typeof(key) == TYPE_OBJECT and not is_instance_valid(key)) or not (e["step"] as Callable).is_valid():
			_items.erase(key)
			continue
		if e["fresh"]:
			e["fresh"] = false
			continue
		e["t"] = float(e["t"]) + dt_ms
		if float(e["t"]) >= float(e["dur"]):
			_items.erase(key)
			if (e["done"] as Callable).is_valid():
				(e["done"] as Callable).call()
		else:
			(e["step"] as Callable).call(e["t"])
