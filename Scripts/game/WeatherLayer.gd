extends CanvasLayer

var _rain_effect: RainEffect = null
var _snow_effect: SnowEffect = null
var _flood_rect: ColorRect = null
var _earthquake_active: bool = false
var _earthquake_timer: float = 0.0
var _earthquake_duration: float = 4.0
var _shake_intensity: float = 4.0
var _original_offset: Vector2 = Vector2.ZERO
@onready var _ui_layer: CanvasLayer = get_tree().get_root().get_node("Main/UI")
var _ui_original_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	WeatherManager.weather_started.connect(_on_weather_started)
	WeatherManager.weather_ended.connect(_on_weather_ended)
	_original_offset = offset
	_ui_original_offset = _ui_layer.offset

func _on_weather_started(weather_id: String) -> void:
	match weather_id:
		"rain":
			_start_rain()
		"snow":
			_start_snow()
		"earthquake":
			_start_earthquake()

func _on_weather_ended(weather_id: String) -> void:
	match weather_id:
		"rain":
			_end_rain()
		"snow":
			_end_snow()
		"earthquake":
			_end_earthquake()

# rain

func _start_rain() -> void:
	_rain_effect = RainEffect.new()
	add_child(_rain_effect)
	_flood_rect = ColorRect.new()
	_flood_rect.color = Color(0.6, 0.6, 0.6, 0.7)
	var pa: Node2D = GameState.play_area
	var box_size: Vector2 = pa.get("box_size")
	_flood_rect.size = Vector2(box_size.x, 0.0)
	_flood_rect.position = Vector2(pa.position.x, pa.position.y + box_size.y)
	get_tree().get_root().get_node("Main/GameWorld").add_child(_flood_rect)
	var tween := create_tween()
	tween.tween_method(
		func(h: float):
			_flood_rect.size.y = h
			_flood_rect.position.y = pa.position.y + box_size.y - h,
		0.0,
		box_size.y * 0.15,
		5.0
	)
	tween.tween_callback(func():
		if _rain_effect:
			_rain_effect.stop()  
	)
	tween.tween_method(
		func(h: float):
			_flood_rect.size.y = h
			_flood_rect.position.y = pa.position.y + box_size.y - h,
		box_size.y * 0.15,
		0.0,
		10.0
	)

func _end_rain() -> void:
	if _rain_effect:
		_rain_effect.stop()
		_rain_effect.queue_free()
		_rain_effect = null

# snow

func _start_snow() -> void:
	_snow_effect = SnowEffect.new()
	add_child(_snow_effect)
	GameState.production_multiplier *= 0.5
	GameState.plonk_speed_multiplier *= 0.5
	for ap in PlonkManager.active:
		ap.node.linear_velocity *= 0.5

func _end_snow() -> void:
	if _snow_effect:
		_snow_effect.stop()
		_snow_effect.fade_out_and_free()
		_snow_effect = null
	GameState.production_multiplier /= 0.5
	GameState.plonk_speed_multiplier /= 0.5
	for ap in PlonkManager.active:
		ap.node.linear_velocity *= 2.0

# quake

func _start_earthquake() -> void:
	_earthquake_active = true
	_earthquake_timer = 0.0
	_randomize_plonk_velocities()

func _randomize_plonk_velocities() -> void:
	for ap in PlonkManager.active:
		var body: RigidBody2D = ap.node
		var base_speed: float = ap.definition.spawn_linear_speed
		var angle := randf() * TAU
		var speed := base_speed * randf_range(0.6, 2.0)
		body.linear_velocity = Vector2(cos(angle), sin(angle)) * speed

func _end_earthquake() -> void:
	_earthquake_active = false
	offset = _original_offset
	_ui_layer.offset = _ui_original_offset

func _process(delta: float) -> void:
	if _earthquake_active:
		_earthquake_timer += delta
		if _earthquake_timer >= _earthquake_duration:
			_end_earthquake()
			return
		offset = Vector2(
			randf_range(-_shake_intensity, _shake_intensity),
			randf_range(-_shake_intensity, _shake_intensity)
		)
		_ui_layer.offset = _ui_original_offset + offset

func _physics_process(delta: float) -> void:
	if _flood_rect and _flood_rect.size.y > 0.0:
		_apply_flood_drag(delta)

func _apply_flood_drag(delta: float) -> void:
	var flood_top: float = _flood_rect.position.y
	var flood_bottom: float = flood_top + _flood_rect.size.y
	var drag_rate: float = 0.35  # fraction of speed lost per second
	for ap in PlonkManager.active:
		var body: RigidBody2D = ap.node
		if body.global_position.y > flood_top and body.global_position.y < flood_bottom:
			body.linear_velocity *= pow(1.0 - drag_rate, delta)
