class_name QuakeComponent extends Node

var _body: RigidBody2D
var _cooldown_timer: Timer
var _spinning: bool = false
var _spin_timer: Timer
var _aftershock_timer: Timer
var _visual_spin_speed: float = 15.0

const AFTERSHOCK_TEXTURES: Array[String] = [
	"res://Assets/projectiles/aftershock/1.png",
	"res://Assets/projectiles/aftershock/2.png",
	"res://Assets/projectiles/aftershock/3.png",
	"res://Assets/projectiles/aftershock/4.png",
]

func activate(body: RigidBody2D) -> void:
	_body = body

	_cooldown_timer = Timer.new()
	_cooldown_timer.one_shot = true
	_cooldown_timer.timeout.connect(_try_trigger)
	add_child(_cooldown_timer)

	_spin_timer = Timer.new()
	_spin_timer.one_shot = true
	_spin_timer.timeout.connect(_end_spin)
	add_child(_spin_timer)

	_aftershock_timer = Timer.new()
	_aftershock_timer.one_shot = false
	_aftershock_timer.wait_time = 1.0
	_aftershock_timer.timeout.connect(_spawn_aftershock)
	add_child(_aftershock_timer)

	_schedule_next()

func _schedule_next() -> void:
	_cooldown_timer.start(randf_range(23.0, 30.0))

func _try_trigger() -> void:
	if not is_instance_valid(_body):
		return
	if WeatherManager._active_weather != "":
		if not WeatherManager.weather_ended.is_connected(_on_weather_ended_retry):
			WeatherManager.weather_ended.connect(_on_weather_ended_retry)
		return
	_trigger_earthquake()

func _on_weather_ended_retry(_weather_id: String) -> void:
	if WeatherManager.weather_ended.is_connected(_on_weather_ended_retry):
		WeatherManager.weather_ended.disconnect(_on_weather_ended_retry)
	if WeatherManager._active_weather == "":
		_trigger_earthquake()
	else:
		WeatherManager.weather_ended.connect(_on_weather_ended_retry)

func _trigger_earthquake() -> void:
	WeatherManager._active_weather = "earthquake"
	WeatherManager.weather_started.emit("earthquake")
	var eq_timer := _body.get_tree().create_timer(10.0)
	eq_timer.timeout.connect(func():
		WeatherManager.weather_ended.emit("earthquake")
		WeatherManager._active_weather = ""
		WeatherManager._schedule_next()
	)
	_start_spin()

func _start_spin() -> void:
	_spinning = true
	_body.animation_locked = true
	_body.override_rotation = true
	var sprite := _body.get_node("AnimatedSprite2D") as AnimatedSprite2D
	sprite.stop()
	sprite.play("effect")
	_spin_timer.start(5.0)
	_aftershock_timer.start()

func _end_spin() -> void:
	_spinning = false
	_body.animation_locked = false
	_body.override_rotation = false
	_aftershock_timer.stop()
	_schedule_next()

func _physics_process(delta: float) -> void:
	if not is_instance_valid(_body):
		return
	if _spinning:
		var sprite := _body.get_node("AnimatedSprite2D") as AnimatedSprite2D
		sprite.rotation += _visual_spin_speed * delta
		# print("sprite rotation: ", sprite.rotation)
		sprite.global_position = _body.global_position
		_body.get_node("ShapeSprite").global_position = _body.global_position
		_body.get_node("ShapeSprite").rotation = _body.rotation

func _spawn_aftershock() -> void:
	if not is_instance_valid(_body):
		return
	var texture_path: String = AFTERSHOCK_TEXTURES[randi() % AFTERSHOCK_TEXTURES.size()]
	var texture: Texture2D = load(texture_path)

	var source_id: String = _body.definition.id if _body.definition else ""
	var aftershock := Aftershock.new(_body, texture, source_id)
	var container := _body.get_node("/root/Main/GameWorld")
	container.add_child(aftershock)
	aftershock.global_position = _body.global_position

class Aftershock extends Area2D:
	var _body_ref: RigidBody2D
	var _elapsed: float = 0.0
	var _lifetime: float = 1.0
	var _hit_bodies: Array = []
	var _source_id: String = ""

	func _init(body: RigidBody2D, texture: Texture2D, source_id: String) -> void:
		_body_ref = body
		_source_id = source_id
		top_level = true
		monitoring = true
		monitorable = false
		collision_layer = 0
		collision_mask = 1
		var sprite := Sprite2D.new()
		sprite.texture = texture
		add_child(sprite)
		var col := CollisionShape2D.new()
		var shape := CircleShape2D.new()
		shape.radius = 60.0
		col.shape = shape
		add_child(col)

	func _ready() -> void:
		body_entered.connect(_on_body_entered)

	func _process(delta: float) -> void:
		_elapsed += delta
		modulate.a = clampf(1.0 - (_elapsed / _lifetime), 0.0, 1.0)
		if _elapsed >= _lifetime:
			queue_free()

	func _on_body_entered(other: Node) -> void:
		if not other is RigidBody2D:
			return
		if other == _body_ref:
			return
		if _hit_bodies.has(other):
			return
		_hit_bodies.append(other)
		var plonk: RigidBody2D = other
		var angle := randf() * TAU
		var base_speed: float = plonk.definition.spawn_linear_speed if plonk.definition else 200.0
		var speed := base_speed * randf_range(0.6, 2.0)
		plonk.linear_velocity = Vector2(cos(angle), sin(angle)) * speed
		StatsManager.change_custom_stat(_source_id, "plonks_aftershocked", 1)
