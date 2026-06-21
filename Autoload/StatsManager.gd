extends Node

var _plinks_log: Dictionary = {}
var _plinks_total: Dictionary = {} 
var custom_stats: Dictionary = {}

const WINDOW_SECONDS: float = 10.0

func record_plinks(plonk_id: String, amount: float) -> void:
	if not _plinks_log.has(plonk_id):
		_plinks_log[plonk_id] = []
	var plog: Array = _plinks_log[plonk_id]
	plog.append({"time": Time.get_ticks_msec() / 1000.0, "amount": amount})
	_trim_log(plog)

	_plinks_total[plonk_id] = _plinks_total.get(plonk_id, 0.0) + amount

func _trim_log(plog: Array) -> void:
	var now: float = Time.get_ticks_msec() / 1000.0
	while plog.size() > 0 and now - plog[0].time > WINDOW_SECONDS:
		plog.pop_front()

func get_plinks_per_window(plonk_id: String) -> float:
	if not _plinks_log.has(plonk_id):
		return 0.0
	var plog: Array = _plinks_log[plonk_id]
	_trim_log(plog)
	var total: float = 0.0
	for entry in plog:
		total += entry.amount
	return total

func get_plinks_total(plonk_id: String) -> float:
	return _plinks_total.get(plonk_id, 0.0)

func set_custom_stat(plonk_id: String, stat_name: String, value: Variant) -> void:
	if not custom_stats.has(plonk_id):
		custom_stats[plonk_id] = {}
	custom_stats[plonk_id][stat_name] = value

# only for numerical
func change_custom_stat(plonk_id: String, stat_name: String, value: Variant) -> void:
	if not custom_stats.has(plonk_id):
		custom_stats[plonk_id] = {}
	var current: float = float(custom_stats[plonk_id].get(stat_name, 0.0))
	custom_stats[plonk_id][stat_name] = current + float(value)

func get_custom_stats(plonk_id: String) -> Dictionary:
	return custom_stats.get(plonk_id, {})
