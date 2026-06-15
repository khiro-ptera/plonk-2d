extends Node

signal plinks_changed(new_amount: float)

var plinks: float = 0.0
var max_plonks: int = 10

func add_plinks(amount: float) -> void:
	plinks += amount
	plinks_changed.emit(plinks)
