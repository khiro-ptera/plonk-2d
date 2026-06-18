extends Node

signal plinks_changed(new_amount: float)
signal plonk_unlocked(id: String)

var plinks: float = 15.0
var max_plonks: int = 10
var production_multiplier: float = 1.0
var plonk_speed_multiplier: float = 1.0
var unlocked_plonk_ids: Array[String] = []
var owned_legendary_ids: Array[String] = []

var play_area: Node2D = null

func add_plinks(amount: float) -> void:
	plinks += amount
	plinks_changed.emit(plinks)

func spend_plinks(amount: float) -> void:
	plinks -= amount
	plinks_changed.emit(plinks)

signal plonk_count_changed(current: int, maximum: int)

func emit_plonk_count() -> void:
	plonk_count_changed.emit(PlonkManager.active.size(), max_plonks)

func unlock_plonk(id: String) -> void:
	if not unlocked_plonk_ids.has(id):
		max_plonks += 2
		unlocked_plonk_ids.append(id)
		emit_plonk_count()
		plonk_unlocked.emit(id)

func format_number(value: float) -> String:
	if value >= 1_000_000_000.0:
		var expo: float = floor(log(value) / log(10))
		var mantissa := value / pow(10, expo)
		return str(snappedf(mantissa, 0.01)) + "e" + str(int(expo))
	elif value >= 1_000_000.0:
		return str(snappedf(value / 1_000_000.0, 0.01)) + "M"
	elif value >= 1_000.0:
		return str(snappedf(value / 1_000.0, 0.01)) + "K"
	else:
		return str(snappedf(value, 0.01))

var unlocked_legendary_ids: Array[String] = []
signal legendary_unlocked(id: String)

func unlock_legendary(id: String) -> void:
	if not unlocked_legendary_ids.has(id):
		unlocked_legendary_ids.append(id)
		legendary_unlocked.emit(id)
