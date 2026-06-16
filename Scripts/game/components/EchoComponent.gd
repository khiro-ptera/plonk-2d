class_name EchoComponent extends Node

var _body: RigidBody2D
var _detection_area: Area2D
var _cooldown: bool = false
var _projectile_scene: PackedScene = preload("res://Scenes/plonks/projectiles/EchoWave.tscn")
var _burst_remaining: int = 0
var _burst_target: RigidBody2D = null
var _burst_timer: Timer
var _cooldown_timer: Timer

func activate(body: RigidBody2D) -> void:
	_body = body
	_detection_area = _body.get_node("DetectionArea")
	_detection_area.top_level = true
	_detection_area.global_position = _body.global_position
	_detection_area.collision_layer = 2
	_detection_area.collision_mask = 1
	_detection_area.monitoring = true
	_detection_area.monitorable = false
	_detection_area.body_entered.connect(_on_body_entered_range)

	_burst_timer = Timer.new()
	_burst_timer.one_shot = true
	_burst_timer.timeout.connect(_on_burst_timer)
	add_child(_burst_timer)

	_cooldown_timer = Timer.new()
	_cooldown_timer.one_shot = true
	_cooldown_timer.timeout.connect(_on_cooldown_timer)
	add_child(_cooldown_timer)

func _physics_process(_delta: float) -> void:
	if _body == null or _detection_area == null:
		return
	_detection_area.global_position = _body.global_position

func _on_body_entered_range(other: Node) -> void:
	if _cooldown:
		return
	if not other is RigidBody2D:
		return
	if other == _body:
		return
	_cooldown = true
	_burst_target = other as RigidBody2D
	_burst_remaining = randi_range(3, 5)
	_fire_next()

func _fire_next() -> void:
	if _burst_remaining <= 0 or not is_instance_valid(_burst_target):
		_burst_target = null
		_cooldown_timer.start(2.0)
		return
	_fire_at(_burst_target)
	_burst_remaining -= 1
	_burst_timer.start(0.15)

func _on_burst_timer() -> void:
	_fire_next()

func _on_cooldown_timer() -> void:
	_cooldown = false

func _fire_at(target: RigidBody2D) -> void:
	if not is_instance_valid(target) or not is_instance_valid(_body):
		return
	var container := _body.get_node_or_null("/root/Main/GameWorld/PlonkContainer")
	if not container:
		return
	var projectile := _projectile_scene.instantiate()
	container.add_child(projectile)
	var dir: Vector2 = (target.global_position - _body.global_position).normalized()
	projectile.global_position = _body.global_position + dir * (_body.definition.radius + 12.0)
	var plinks_value: float = _body.definition.base_plinks_per_bounce * 0.1
	Callable(projectile, "launch").bind(dir, plinks_value).call_deferred()
