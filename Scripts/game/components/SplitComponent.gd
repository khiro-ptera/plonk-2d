class_name SplitComponent
extends Node

var _body: RigidBody2D
var _is_clone: bool = false

func activate(body: RigidBody2D) -> void:
	_body = body
	if _body.is_clone:
		set_as_clone(_body)
		return
	_body.body_entered.connect(_on_body_entered)

func set_as_clone(body: RigidBody2D) -> void:
	_body = body
	_is_clone = true
	if _body.body_entered.is_connected(_on_body_entered):
		_body.body_entered.disconnect(_on_body_entered)
	_body.get_node("ShapeSprite").modulate.a = 0.5
	_body.get_node("AnimatedSprite2D").modulate.a = 0.5
	_body.body_entered.connect(_on_clone_body_entered)

func _on_clone_body_entered(_other: Node) -> void:
	_body.call_deferred("queue_free")

func _on_body_entered(other: Node) -> void:
	if _is_clone:
		return
	_spawn_clones()
	_body.linear_velocity *= 0.5
	_body.angular_velocity *= 0.5
	if other is StaticBody2D:
		var push_dir: Vector2 = (_body.global_position - other.global_position).normalized()
		_body.linear_velocity += push_dir * _body.definition.spawn_linear_speed * 0.3

func _spawn_clones() -> void:
	var current_speed := _body.linear_velocity.length()
	var clone_speed := current_speed * 0.5
	for i in range(2):
		var spawn_pos := _find_clear_position()
		if spawn_pos == Vector2.INF:
			continue
		var angle := randf() * TAU
		var velocity := Vector2(cos(angle), sin(angle)) * clone_speed
		_spawn_single_clone(spawn_pos, velocity)

func _find_clear_position() -> Vector2:
	var space := _body.get_world_2d().direct_space_state
	var radius: float = _body.definition.radius * 0.75 
	var pa: Node2D = GameState.play_area
	var bounds_min: Vector2 = pa.position + Vector2.ONE * (radius + 2.0)
	var bounds_max: Vector2 = pa.position + Vector2(pa.get("box_size")) - Vector2.ONE * (radius + 2.0)

	for attempt in range(10):
		var angle := randf() * TAU
		var dist: float = _body.definition.radius * 2.5 + randf() * _body.definition.radius * 2.0
		var candidate: Vector2 = _body.global_position + Vector2(cos(angle), sin(angle)) * dist
		candidate.x = clampf(candidate.x, bounds_min.x, bounds_max.x)
		candidate.y = clampf(candidate.y, bounds_min.y, bounds_max.y)
		var query := PhysicsShapeQueryParameters2D.new()
		var shape := CircleShape2D.new()
		shape.radius = radius
		query.shape = shape
		query.transform = Transform2D(0.0, candidate)
		query.collision_mask = _body.collision_mask
		var results := space.intersect_shape(query, 1)
		if results.size() == 0:
			return candidate
	return Vector2.INF

func _spawn_single_clone(spawn_pos: Vector2, velocity: Vector2) -> void:
	var clone := _body.definition.scene.instantiate() as RigidBody2D
	var container := _body.get_node("/root/Main/GameWorld/PlonkContainer")
	container.add_child(clone)
	clone.global_position = spawn_pos
	clone.is_clone = true
	clone.linear_velocity = velocity
	Callable(clone, "setup").bind(_body.definition, 0.5).call_deferred()
	
