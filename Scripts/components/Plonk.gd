extends RigidBody2D

var definition: PlonkData
var _bouncing: bool = false

func setup(data: PlonkData) -> void:
	definition = data
	mass = data.mass
	gravity_scale = 0.0
	linear_damp = 0.0
	linear_damp_mode = RigidBody2D.DAMP_MODE_REPLACE
	angular_damp = 0.0
	angular_damp_mode = RigidBody2D.DAMP_MODE_REPLACE

	if data.physics_material:
		physics_material_override = data.physics_material

	var shape := CircleShape2D.new()
	shape.radius = data.radius
	$CollisionShape2D.shape = shape

	$ShapeSprite.color = Color.WHITE
	$ShapeSprite.polygon = _make_circle_polygon(data.radius, 32)

	if data.sprite_frames:
		$AnimatedSprite2D.sprite_frames = data.sprite_frames
		$AnimatedSprite2D.play("mid")
	_fit_sprite_to_collider(data.radius)

	var angle := randf() * TAU
	linear_velocity = Vector2(cos(angle), sin(angle)) * data.spawn_linear_speed

func _make_circle_polygon(radius: float, points: int) -> PackedVector2Array:
	var verts := PackedVector2Array()
	for i in range(points):
		var a := (float(i) / points) * TAU
		verts.append(Vector2(cos(a), sin(a)) * radius)
	return verts

func _fit_sprite_to_collider(radius: float) -> void:
	var diameter := radius * 2.0
	var scale_factor := diameter / 100.0
	$AnimatedSprite2D.scale = Vector2(scale_factor, scale_factor)

func _physics_process(_delta: float) -> void:
	if _bouncing or definition == null:
		return
	var ratio := linear_velocity.length() / definition.spawn_linear_speed
	if ratio < 0.5:
		_play("slow")
	elif ratio <= 1.5:
		_play("mid")
	else:
		_play("fast")

func _play(anim: String) -> void:
	if $AnimatedSprite2D.animation != anim:
		$AnimatedSprite2D.play(anim)

func _on_body_entered(_body: Node) -> void:
	print("bonk")
	$AnimatedSprite2D.play("bounce")
	_bouncing = true
	if definition:
		GameState.add_plinks(definition.base_plinks_per_bounce)

func _on_animated_sprite_2d_animation_finished() -> void:
	if $AnimatedSprite2D.animation == "bounce":
		_bouncing = false
