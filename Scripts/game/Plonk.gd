extends RigidBody2D

var definition: PlonkData
var _bouncing: bool = false
var _visual_rotation: float = 0.0
var override_rotation: bool = false
var animation_locked: bool = false
var is_clone: bool = false
var _out_of_bounds_timer: float = 0.0
var _is_out_of_bounds: bool = false
@export var max_visual_spin: float = 1.5

func setup(data: PlonkData, radius_scale: float = 1.0) -> void:
	$ShapeSprite.top_level = true
	$AnimatedSprite2D.top_level = true
	
	definition = data
	mass = data.mass * (radius_scale * radius_scale)
	gravity_scale = 0.0
	linear_damp = 0.0
	linear_damp_mode = RigidBody2D.DAMP_MODE_REPLACE
	angular_damp = 0.0
	angular_damp_mode = RigidBody2D.DAMP_MODE_REPLACE

	if data.physics_material:
		physics_material_override = data.physics_material

	var scaled_radius := data.radius * radius_scale
	var verts: PackedVector2Array
	match data.shape_type:
		"Circle":
			var shape := CircleShape2D.new()
			shape.radius = scaled_radius
			$CollisionShape2D.shape = shape
			verts = _make_circle_polygon(scaled_radius, 32)
		"Star":
			var scaled_inner := data.inner_radius * radius_scale
			verts = _make_star_polygon(scaled_radius, scaled_inner, data.star_points)
			$ShapeSprite.polygon = verts
			for i in range(verts.size()):
				var tri := ConvexPolygonShape2D.new()
				tri.points = PackedVector2Array([
					Vector2.ZERO,
					verts[i],
					verts[(i + 1) % verts.size()]
				])
				var col := CollisionShape2D.new()
				col.shape = tri
				add_child(col)
			$CollisionShape2D.disabled = true
		"Custom":
			pass

	$ShapeSprite.color = Color.WHITE
	$ShapeSprite.polygon = verts

	if data.sprite_frames:
		$AnimatedSprite2D.sprite_frames = data.sprite_frames
		$AnimatedSprite2D.play("mid")
	_fit_sprite_to_collider(data, radius_scale)

	var angle := randf() * TAU
	linear_velocity = Vector2(cos(angle), sin(angle)) * data.spawn_linear_speed
	
	for component_name in data.components:
		var component := get_node_or_null(component_name)
		if component and component.has_method("activate"):
			component.activate(self)

func _make_circle_polygon(radius: float, points: int) -> PackedVector2Array:
	var verts := PackedVector2Array()
	for i in range(points):
		var a := (float(i) / points) * TAU
		verts.append(Vector2(cos(a), sin(a)) * radius)
	return verts

func _make_star_polygon(outer_radius: float, inner_radius: float, points: int) -> PackedVector2Array:
	var verts := PackedVector2Array()
	var total_verts := points * 2
	for i in range(total_verts):
		var a := (float(i) / total_verts) * TAU - PI / 2.0
		var r := outer_radius if i % 2 == 0 else inner_radius
		verts.append(Vector2(cos(a), sin(a)) * r)
	return verts

func _fit_sprite_to_collider(data: PlonkData, radius_scale: float = 1.0) -> void:
	var fit_radius: float
	match data.shape_type:
		"Star":
			fit_radius = data.inner_radius * radius_scale * 1.5
		_:
			fit_radius = data.radius * radius_scale
	var scale_factor := (fit_radius * 2.0) / 100.0
	$AnimatedSprite2D.scale = Vector2(scale_factor, scale_factor)

func _physics_process(delta: float) -> void:
	_check_bounds(delta)
	if not override_rotation:
		var clamped_spin := clampf(angular_velocity, -max_visual_spin, max_visual_spin)
		_visual_rotation += clamped_spin * delta
		$ShapeSprite.global_position = global_position
		$ShapeSprite.rotation = rotation
		$AnimatedSprite2D.global_position = global_position
		$AnimatedSprite2D.rotation = _visual_rotation
	else:
		$ShapeSprite.global_position = global_position
		$AnimatedSprite2D.global_position = global_position
		return

	if _bouncing or animation_locked or definition == null:
		return
	var ratio := linear_velocity.length() / definition.spawn_linear_speed
	if ratio < 0.7:
		_play("slow")
	elif ratio <= 1.3:
		_play("mid")
	else:
		_play("fast")

func _play(anim: String) -> void:
	if $AnimatedSprite2D.animation != anim:
		$AnimatedSprite2D.play(anim)

func _on_body_entered(_body: Node) -> void:
	# print("bonk")
	$AnimatedSprite2D.play("bounce")
	_bouncing = true
	if definition:
		var amount: float = definition.base_plinks_per_bounce * GameState.production_multiplier
		GameState.add_plinks(amount)
		StatsManager.record_plinks(definition.id, amount)

func _on_animated_sprite_2d_animation_finished() -> void:
	if $AnimatedSprite2D.animation == "bounce":
		_bouncing = false

func _check_bounds(delta: float) -> void:
	if GameState.play_area == null:
		return
	var pa: Node2D = GameState.play_area
	var bounds_min: Vector2 = pa.position
	var bounds_max: Vector2 = pa.position + Vector2(pa.get("box_size"))
	var inside := (
		global_position.x > bounds_min.x and
		global_position.x < bounds_max.x and
		global_position.y > bounds_min.y and
		global_position.y < bounds_max.y
	)
	if not inside:
		_out_of_bounds_timer += delta
		if not _is_out_of_bounds:
			_is_out_of_bounds = true
			_out_of_bounds_timer = 0.0
		if _out_of_bounds_timer >= 3.0:
			_return_to_center()
	else:
		_is_out_of_bounds = false
		_out_of_bounds_timer = 0.0

func _return_to_center() -> void:
	var pa: Node2D = GameState.play_area
	var center: Vector2 = pa.position + Vector2(pa.get("box_size")) / 2.0
	global_position = center
	var angle := randf() * TAU
	linear_velocity = Vector2(cos(angle), sin(angle)) * definition.spawn_linear_speed
	angular_velocity = 0.0
	_is_out_of_bounds = false
	_out_of_bounds_timer = 0.0
