class_name TapLimiter
extends RefCounted
## Global tap-rate cap across every pointer and key (mechanic rule 2 / E9). Excess taps are
## dropped with no award and no feedback, so feedback never lies about income.

var max_per_sec: int
var _times: Array[float] = []


func _init(max_per_sec_: int = -1) -> void:
	max_per_sec = max_per_sec_ if max_per_sec_ > 0 else int(Content.data()["tap"]["maxRegisteredTapsPerSec"])


## true = register this tap; false = drop it silently.
func try_register(now_ms: float) -> bool:
	while not _times.is_empty() and now_ms - _times[0] >= 1000.0:
		_times.pop_front()
	if _times.size() >= max_per_sec:
		return false
	_times.append(now_ms)
	return true
