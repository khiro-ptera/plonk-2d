extends Node

func _ready() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var play_area := $GameWorld/PlayArea
	play_area.position = (viewport_size - play_area.box_size) / 2.0
	PlonkManager.spawn_plonk("plonk0", play_area.position + play_area.box_size / 2.0)
