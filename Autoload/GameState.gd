extends Node

signal plinks_changed(new_amount: float)

var plinks: float = 15.0
var max_plonks: int = 10
var unlocked_plonk_ids: Array[String] = []

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
