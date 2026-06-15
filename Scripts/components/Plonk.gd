extends RigidBody2D

var definition: PlonkData
var _bouncing: bool = false

func setup(data: PlonkData) -> void:
	definition = data
	mass = data.mass
	if data.physics_material:
		physics_material_override = data.physics_material
	# collision shape
	var shape := CircleShape2D.new()
	shape.radius = data.radius
	$CollisionShape2D.shape = shape
	# sprite
	if data.sprite_frames:
		$AnimatedSprite2D.sprite_frames = data.sprite_frames
		$AnimatedSprite2D.play("mid")
	# random direction fixed speed
	var angle := randf() * TAU
	linear_velocity = Vector2(cos(angle), sin(angle)) * data.spawn_linear_speed

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
	$AnimatedSprite2D.play("bounce")
	_bouncing = true
	# plinks
	if definition:
		GameState.add_plinks(definition.base_plinks_per_bounce)

func _on_animated_sprite_2d_animation_finished() -> void:
	if $AnimatedSprite2D.animation == "bounce":
		_bouncing = false
