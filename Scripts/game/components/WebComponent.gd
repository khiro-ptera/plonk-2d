class_name WebComponent extends Node

var _body: RigidBody2D
var _last_wall_point: Vector2 = Vector2.ZERO
var _has_last_point: bool = false
var _webs: Array = []  # each entry: {line: Line2D, area: Area2D, bounces_since_spawn: int}
var _live_line: Line2D = null

func activate(body: RigidBody2D) -> void:
	_body = body
	_body.body_entered.connect(_on_body_entered)
	_create_live_line()

func _get_container() -> Node:
	return _body.get_node("/root/Main/GameWorld")

func _create_live_line() -> void:
	_live_line = Line2D.new()
	_live_line.width = 2.0
	_live_line.default_color = Color(1.0, 1.0, 1.0, 0.7)
	_live_line.z_index = -1
	_get_container().add_child(_live_line)

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(_body) or not is_instance_valid(_live_line):
		return
	if _has_last_point:
		_live_line.clear_points()
		_live_line.add_point(_last_wall_point)
		_live_line.add_point(_body.global_position)
	else:
		_live_line.clear_points()

func _on_body_entered(other: Node) -> void:
	if not other is StaticBody2D:
		return
	var travel_dir: Vector2 = _body.linear_velocity.normalized()
	if travel_dir == Vector2.ZERO:
		travel_dir = Vector2.RIGHT
	var collision_point: Vector2 = _body.global_position - travel_dir * _body.definition.radius
	if _has_last_point:
		_spawn_web.call_deferred(_last_wall_point, collision_point)
	_last_wall_point = collision_point
	_has_last_point = true
	_age_webs()

func _spawn_web(point_a: Vector2, point_b: Vector2) -> void:
	var container := _get_container()

	var line := Line2D.new()
	line.width = 2.0
	line.default_color = Color(1.0, 1.0, 1.0, 0.7)
	line.z_index = -1
	line.add_point(point_a)
	line.add_point(point_b)
	container.add_child(line)

	var area := Area2D.new()
	area.monitoring = true
	area.monitorable = false
	area.collision_layer = 0
	area.collision_mask = 1
	var col := CollisionShape2D.new()
	var shape := SegmentShape2D.new()
	shape.a = point_a
	shape.b = point_b
	col.shape = shape
	area.add_child(col)
	container.add_child(area)
	area.body_entered.connect(_on_web_touched.bind(area))

	_webs.append({"line": line, "area": area, "bounces_since_spawn": 0})

func _age_webs() -> void:
	for i in range(_webs.size() - 1, -1, -1):
		var web: Dictionary = _webs[i]
		web.bounces_since_spawn += 1
		if web.bounces_since_spawn >= 5:
			if is_instance_valid(web.line):
				web.line.queue_free()
			if is_instance_valid(web.area):
				web.area.queue_free()
			_webs.remove_at(i)

func _on_web_touched(other: Node, _area: Area2D) -> void:
	if other == _body:
		return
	if not other is RigidBody2D:
		return
	var plonk: RigidBody2D = other
	plonk.linear_velocity *= 0.5
	_body.linear_velocity += plonk.linear_velocity * 0.5
	if _body.definition:
		var amount: float = _body.definition.base_plinks_per_bounce
		GameState.add_plinks(amount)
		StatsManager.record_plinks(_body.definition.id, amount)
		StatsManager.change_custom_stat(_body.definition.id, "prey_tangled", 1)

func _exit_tree() -> void:
	if is_instance_valid(_live_line):
		_live_line.queue_free()
	for web in _webs:
		if is_instance_valid(web.line):
			web.line.queue_free()
		if is_instance_valid(web.area):
			web.area.queue_free()
