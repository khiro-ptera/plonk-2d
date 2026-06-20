class_name HibernateComponent extends Node

var _body: RigidBody2D
var _cooldown_timer: Timer
var _hibernating: bool = false
var _fluff_spawn_timer: float = 0.0
const FLUFF_SCENE: PackedScene = preload("res://Scenes/plonks/projectiles/Fluff.tscn")
const FLUFF_TEXTURES: Array[String] = [
	"res://Assets/projectiles/fluff/1.png",
	"res://Assets/projectiles/fluff/2.png",
	"res://Assets/projectiles/fluff/3.png",
	"res://Assets/projectiles/fluff/4.png",
]

func activate(body: RigidBody2D) -> void:
	_body = body
	_cooldown_timer = Timer.new()
	_cooldown_timer.one_shot = true
	_cooldown_timer.timeout.connect(_start_hibernate)
	add_child(_cooldown_timer)
	_cooldown_timer.start(10.0)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(_body):
		return
	if _hibernating:
		var cap: float = _body.definition.spawn_linear_speed * 0.1
		if _body.linear_velocity.length() > cap:
			_body.linear_velocity = _body.linear_velocity.normalized() * cap

		_fluff_spawn_timer += delta
		if _fluff_spawn_timer >= 0.2:
			_fluff_spawn_timer = 0.0
			_spawn_fluff()

func _start_hibernate() -> void:
	_hibernating = true
	_body.animation_locked = true

	var sprite := _body.get_node("AnimatedSprite2D") as AnimatedSprite2D
	sprite.stop()
	sprite.play("effect")

	var duration_timer := _body.get_tree().create_timer(5.0)
	duration_timer.timeout.connect(_end_hibernate)

func _end_hibernate() -> void:
	_hibernating = false
	if is_instance_valid(_body):
		_body.animation_locked = false
	_body.linear_velocity = _body.linear_velocity.normalized() * _body.definition.spawn_linear_speed
	_cooldown_timer.start(10.0)

func _spawn_fluff() -> void:
	if not is_instance_valid(_body):
		return
	var fluff := FLUFF_SCENE.instantiate()
	var container := _body.get_node("/root/Main/GameWorld/PlonkContainer")
	container.add_child(fluff)
	fluff.global_position = _body.global_position

	var angle := randf() * TAU
	var outward_speed := randf_range(15.0, 35.0)
	var velocity := Vector2(cos(angle), sin(angle)) * outward_speed

	var texture_path: String = FLUFF_TEXTURES[randi() % FLUFF_TEXTURES.size()]
	var texture: Texture2D = load(texture_path)

	var plinks_per_bounce: float = _body.definition.base_plinks_per_bounce
	var source_id: String = _body.definition.id

	fluff.setup(velocity, texture, plinks_per_bounce, source_id)
