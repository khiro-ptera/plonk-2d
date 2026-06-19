class_name RookComponent extends Node

var _body: RigidBody2D
var _cooldown_timer: Timer
var _stored_velocity: Vector2 = Vector2.ZERO
var _is_teleporting: bool = false
var _sprite_base_scale: Vector2 = Vector2.ONE

func activate(body: RigidBody2D) -> void:
	_body = body
	_sprite_base_scale = _body.get_node("AnimatedSprite2D").scale
	_cooldown_timer = Timer.new()
	_cooldown_timer.one_shot = true
	_cooldown_timer.timeout.connect(_start_teleport)
	add_child(_cooldown_timer)
	_schedule_next()

func _schedule_next() -> void:
	_cooldown_timer.start(randf_range(4.0, 8.0))

func _start_teleport() -> void:
	if not is_instance_valid(_body):
		return
	_is_teleporting = true
	_stored_velocity = _body.linear_velocity
	_body.linear_velocity = Vector2.ZERO
	_body.angular_velocity = 0.0
	_body.override_rotation = true
	_body._bouncing = true

	var sprite := _body.get_node("AnimatedSprite2D") as AnimatedSprite2D
	var shape_sprite := _body.get_node("ShapeSprite") as Polygon2D

	sprite.stop()
	sprite.play("effect")
	
	var start_pos: Vector2 = _body.global_position

	var tween := _body.create_tween()

	tween.tween_method(
		func(t: float):
			var scale_factor: float = lerpf(1.0, 0.0, t)
			shape_sprite.scale = Vector2(scale_factor, scale_factor)
			sprite.scale = _sprite_base_scale * scale_factor
			sprite.rotation = t * TAU * 3.0,
		0.0,
		1.0,
		1.0
	)

	tween.tween_callback(func():
		var end_pos := _pick_teleport_point(start_pos)
		_body.global_position = end_pos
		_show_teleport_line(start_pos, end_pos)
	)

	tween.tween_method(
		func(t: float):
			var scale_factor: float = lerpf(0.0, 1.0, t)
			shape_sprite.scale = Vector2(scale_factor, scale_factor)
			sprite.scale = _sprite_base_scale * scale_factor
			sprite.rotation = (1.0 - t) * TAU * 3.0,
		0.0,
		1.0,
		1.0
	)

	tween.tween_callback(func():
		sprite.sprite_frames.set_animation_loop("bounce", false)
		shape_sprite.scale = Vector2.ONE
		sprite.scale = _sprite_base_scale
		sprite.rotation = 0.0
		_body._bouncing = false
		_body.override_rotation = false
		_body.linear_velocity = _stored_velocity
		_is_teleporting = false
		_schedule_next()
	)

func _pick_teleport_point(start_pos: Vector2) -> Vector2:
	var pa: Node2D = GameState.play_area
	var box_size: Vector2 = pa.get("box_size")
	var bounds_min: Vector2 = pa.position
	var bounds_max: Vector2 = pa.position + box_size
	var min_length: float = 144.0

	var horizontal := randf() < 0.5

	if horizontal:
		var y: float = start_pos.y
		var x: float = start_pos.x
		var attempts := 0
		while attempts < 10:
			x = randf_range(bounds_min.x, bounds_max.x)
			if absf(x - start_pos.x) >= min_length:
				break
			attempts += 1
		return Vector2(x, y)
	else:
		var x: float = start_pos.x
		var y: float = start_pos.y
		var attempts := 0
		while attempts < 10:
			y = randf_range(bounds_min.y, bounds_max.y)
			if absf(y - start_pos.y) >= min_length:
				break
			attempts += 1
		return Vector2(x, y)

func _show_teleport_line(start_pos: Vector2, end_pos: Vector2) -> void:
	var line := Line2D.new()
	line.width = 32.0
	line.default_color = Color(1.0, 1.0, 1.0, 0.5)
	line.add_point(start_pos)
	line.add_point(end_pos)
	line.top_level = true
	var container := _body.get_node("/root/Main/GameWorld/PlonkContainer")
	container.add_child(line)

	var hit_count := 0
	for ap in PlonkManager.active:
		var other_body: RigidBody2D = ap.node
		if other_body == _body:
			continue
		if _segment_hits_circle(start_pos, end_pos, other_body.global_position, ap.definition.radius):
			other_body.linear_velocity *= 1.5
			hit_count += 1

	if hit_count > 0 and _body.definition:
		GameState.add_plinks(hit_count * _body.definition.base_plinks_per_bounce)
	
	StatsManager.set_custom_stat(_body.definition.id, "plonks_hit_by_line", hit_count)

	var timer := _body.get_tree().create_timer(1.0)
	timer.timeout.connect(func():
		if is_instance_valid(line):
			line.queue_free()
	)

func _segment_hits_circle(a: Vector2, b: Vector2, center: Vector2, radius: float) -> bool:
	var closest: Vector2 = Geometry2D.get_closest_point_to_segment(center, a, b)
	return closest.distance_to(center) <= radius

func _physics_process(_delta: float) -> void:
	if _is_teleporting and is_instance_valid(_body):
		_body.linear_velocity = Vector2.ZERO
		_body.angular_velocity = 0.0
