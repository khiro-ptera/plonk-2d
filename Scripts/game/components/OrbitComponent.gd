class_name OrbitComponent extends Node

var _body: RigidBody2D
var _transition_time: float = 1.0
var _elapsed: float = 0.0
var _transitioning: bool = true

func activate(body: RigidBody2D) -> void:
	_body = body
	_reposition_spawn()

func _reposition_spawn() -> void:
	var pa: Node2D = GameState.play_area
	var box_size: Vector2 = pa.get("box_size")
	var center: Vector2 = pa.position + box_size / 2.0
	var max_dim: float = minf(box_size.x, box_size.y)
	var min_dist: float = 50.0
	var max_dist: float = max_dim / 4.0
	if max_dist < min_dist:
		max_dist = min_dist + 1.0  # safety fallback for small play areas

	var dist := randf_range(min_dist, max_dist)
	var angle := randf() * TAU
	var spawn_pos: Vector2 = center + Vector2(cos(angle), sin(angle)) * dist
	_body.global_position = spawn_pos

func _physics_process(delta: float) -> void:
	if not is_instance_valid(_body):
		return
	if not _transitioning:
		_maintain_orbit_direction()
		return

	_elapsed += delta
	var t: float = clampf(_elapsed / _transition_time, 0.0, 1.0)

	var pa: Node2D = GameState.play_area
	var box_size: Vector2 = pa.get("box_size")
	var center: Vector2 = pa.position + box_size / 2.0

	var to_center: Vector2 = (center - _body.global_position).normalized()
	var perpendicular: Vector2 = Vector2(-to_center.y, to_center.x)  # rotate 90 degrees
	var speed: float = _body.linear_velocity.length()
	if speed < 1.0:
		speed = _body.definition.spawn_linear_speed

	var target_velocity: Vector2 = perpendicular * speed
	_body.linear_velocity = _body.linear_velocity.lerp(target_velocity, t)

	if t >= 1.0:
		_transitioning = false

func _maintain_orbit_direction() -> void:
	# keep correcting velocity to stay perpendicular as the plonk moves around the orbit
	var pa: Node2D = GameState.play_area
	var box_size: Vector2 = pa.get("box_size")
	var center: Vector2 = pa.position + box_size / 2.0

	var to_center: Vector2 = (center - _body.global_position).normalized()
	var perpendicular: Vector2 = Vector2(-to_center.y, to_center.x)
	var speed: float = _body.linear_velocity.length()
	_body.linear_velocity = perpendicular * speed
