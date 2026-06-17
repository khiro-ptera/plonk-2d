extends Node

func _ready() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var bg := $GameWorld/Background
	bg.color = Color(0.5, 0.5, 0.5, 1.0)
	bg.position = Vector2.ZERO
	bg.size = viewport_size
	bg.z_index = -1
	
	var play_area := $GameWorld/PlayArea
	GameState.play_area = play_area
	play_area.position = (viewport_size - play_area.box_size) / 2.0
	
	var label := $GameWorld/CountLabel
	label.position = Vector2(play_area.position.x, play_area.position.y + play_area.box_size.y + 8.0)
	label.size = Vector2(play_area.box_size.x, 24.0)
	GameState.plonk_count_changed.connect(_on_plonk_count_changed)

	# PlonkManager.spawn_plonk("plonk0", play_area.position + play_area.box_size / 2.0)
	$UI._populate_shop()
	
func _on_plonk_count_changed(current: int, maximum: int) -> void:
	var label := $GameWorld/CountLabel
	label.text = str(current) + " / " + str(maximum) + " plonks"

# REMOVE IN PROD: CHEAT
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_D:
			GameState.add_plinks(GameState.plinks)
		if event.keycode == KEY_W:
			WeatherManager._roll_weather()
