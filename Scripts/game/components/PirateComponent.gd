class_name PirateComponent extends Node

var _body: RigidBody2D
var _cooldown_timer: Timer
var _failsafe_timer: Timer
var _hook: Area2D = null
var _line: Line2D = null
var _target: RigidBody2D = null
var _is_active: bool = false
var _phase: String = ""  # "homing" or "pulling"

const HOOK_SCENE: PackedScene = preload("res://Scenes/plonks/projectiles/Hook.tscn")

func activate(body: RigidBody2D) -> void:
	_body = body
	_cooldown_timer = Timer.new()
	_cooldown_timer.one_shot = true
	_cooldown_timer.timeout.connect(_try_hook)
	add_child(_cooldown_timer)
	
	_failsafe_timer = Timer.new()
	_failsafe_timer.one_shot = true
	_failsafe_timer.timeout.connect(_on_failsafe)
	add_child(_failsafe_timer)
	
	_schedule_next()

func _schedule_next() -> void:
	_cooldown_timer.start(4.0)

func _try_hook() -> void:
	if not is_instance_valid(_body):
		return
	var target := _pick_target()
	if target == null:
		_schedule_next()
		return
	_start_hook(target)

func _pick_target() -> RigidBody2D:
	var candidates: Array[RigidBody2D] = []
	for ap in PlonkManager.active:
		var node: RigidBody2D = ap.node
		if node == _body:
			continue
		if node.is_clone:
			continue
		candidates.append(node)
	if candidates.size() == 0:
		return null
	return candidates[randi() % candidates.size()]

func _start_hook(target: RigidBody2D) -> void:
	_is_active = true
	_target = target
	_phase = "homing"
	_body.animation_locked = true
	_failsafe_timer.start(3.0)

	var sprite := _body.get_node("AnimatedSprite2D") as AnimatedSprite2D
	sprite.play("effect")

	_hook = HOOK_SCENE.instantiate()
	var container := _body.get_node("/root/Main/GameWorld/PlonkContainer")
	container.add_child(_hook)
	_hook.global_position = _body.global_position

	_line = Line2D.new()
	_line.width = 1.5
	_line.default_color = Color.BLACK
	_line.top_level = true
	_line.z_index = -1
	_line.add_point(_body.global_position)
	_line.add_point(_hook.global_position)
	container.add_child(_line)

func _physics_process(delta: float) -> void:
	if not _is_active:
		return
	if not is_instance_valid(_target) or not is_instance_valid(_body):
		_end_hook()
		return
	if _phase == "homing":
		_process_homing(delta)
	elif _phase == "pulling":
		_process_pulling(delta)

	if not _is_active:
		return 

	if _line and is_instance_valid(_hook):
		_line.clear_points()
		_line.add_point(_body.global_position)
		_line.add_point(_hook.global_position)

func _process_homing(delta: float) -> void:
	if not is_instance_valid(_hook):
		_end_hook()
		return
	var speed: float = _body.linear_velocity.length()
	if speed < 1.0:
		speed = _body.definition.spawn_linear_speed
	var hook_speed: float = minf(maxf(speed * 5.0, 1000.0), 2500.0)
	var dir: Vector2 = (_target.global_position - _hook.global_position)
	var dist: float = dir.length()
	dir = dir.normalized()
	var travel: float = hook_speed * delta
	if travel >= dist:
		_hook.global_position = _target.global_position
		_on_hook_landed()
	else:
		_hook.global_position += dir * travel
	_hook.rotation = dir.angle()

func _on_hook_landed() -> void:
	_phase = "pulling"

func _process_pulling(delta: float) -> void:
	if not is_instance_valid(_body):
		_end_hook()
		return
	
	var dist_to_body: float = _target.global_position.distance_to(_body.global_position)
	var collision_dist: float = _body.definition.radius + _target.definition.radius
	if dist_to_body <= collision_dist:
		_end_hook()
		return

	var speed: float = _body.linear_velocity.length()
	if speed < 1.0:
		speed = _body.definition.spawn_linear_speed
	var pull_speed: float = minf(maxf(speed * 10.0, 1400.0), 3200.0)
	var dir: Vector2 = (_body.global_position - _target.global_position)
	var dist: float = dir.length()
	dir = dir.normalized()
	var travel: float = pull_speed * delta
	if travel >= dist:
		_end_hook(true)
	else:
		_target.global_position += dir * travel
		if is_instance_valid(_hook):
			_hook.global_position = _target.global_position

func _end_hook(needs_eject: bool = false) -> void:
	_is_active = false
	_phase = ""
	_failsafe_timer.stop()

	if needs_eject and is_instance_valid(_target) and is_instance_valid(_body):
		var speed: float = _body.linear_velocity.length()
		if speed < 1.0:
			speed = _body.definition.spawn_linear_speed
		var eject_speed: float = minf(maxf(speed * 1.0, 200.0), 300.0)
		var away: Vector2 = (_target.global_position - _body.global_position).normalized()
		if away == Vector2.ZERO:
			away = Vector2.RIGHT  # exactly overlapping
		_target.linear_velocity = away * eject_speed
		_body.linear_velocity = -away * eject_speed

	if is_instance_valid(_hook):
		_hook.queue_free()
	_hook = null
	if is_instance_valid(_line):
		_line.queue_free()
	_line = null
	_target = null
	if is_instance_valid(_body):
		_body.animation_locked = false
	StatsManager.change_custom_stat(_body.definition.id, "plonks_hooked", 1)
	_schedule_next()
	
func _on_failsafe() -> void:
	if _is_active:
		_end_hook(true)
		
		
