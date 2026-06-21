class_name ExplodeComponent extends Node

var _body: RigidBody2D
var _is_exploding: bool = false
var _on_cooldown: bool = false
var _explosion_radius: float = 300.0
var _max_push_speed: float = 1000.0 

func activate(body: RigidBody2D) -> void:
	_body = body

func _physics_process(_delta: float) -> void:
	if _is_exploding and is_instance_valid(_body):
		_body.linear_velocity = Vector2.ZERO
		_body.angular_velocity = 0.0
		return
	if _on_cooldown or not is_instance_valid(_body) or _body.definition == null:
		return
	var speed_ratio: float = _body.linear_velocity.length() / _body.definition.spawn_linear_speed
	if speed_ratio >= 2.0:
		_start_explosion()

func _start_explosion() -> void:
	_is_exploding = true
	var stored_speed: float = _body.linear_velocity.length()

	_body.linear_velocity = Vector2.ZERO
	_body.angular_velocity = 0.0
	_body.override_rotation = true
	_body.animation_locked = true

	var sprite := _body.get_node("AnimatedSprite2D") as AnimatedSprite2D
	sprite.stop()
	sprite.play("effect1")

	var timer := _body.get_tree().create_timer(2.0)
	timer.timeout.connect(func(): _trigger_burst(stored_speed))

func _trigger_burst(stored_speed: float) -> void:
	if not is_instance_valid(_body):
		return

	_spawn_particles()
	_push_nearby_plonks(stored_speed)

	var sprite := _body.get_node("AnimatedSprite2D") as AnimatedSprite2D
	sprite.play("effect2")

	var recovery_speed: float = _body.definition.spawn_linear_speed * 0.3
	var angle := randf() * TAU
	_body.linear_velocity = Vector2(cos(angle), sin(angle)) * recovery_speed

	_body.override_rotation = false
	_is_exploding = false
	_on_cooldown = true

	var cooldown_timer := _body.get_tree().create_timer(3.0)
	cooldown_timer.timeout.connect(_on_cooldown_finished)

func _on_cooldown_finished() -> void:
	_on_cooldown = false
	if is_instance_valid(_body):
		_body.animation_locked = false

func _spawn_particles() -> void:
	var particles := CPUParticles2D.new()
	particles.position = Vector2.ZERO
	particles.emitting = false
	particles.one_shot = true
	particles.amount = 75
	particles.lifetime = 0.8
	particles.explosiveness = 1.0
	particles.direction = Vector2.UP
	particles.spread = 360.0
	particles.gravity = Vector2.ZERO
	particles.initial_velocity_min = 350.0
	particles.initial_velocity_max = 500.0
	particles.scale_amount_min = 3.0
	particles.scale_amount_max = 6.0

	var ramp := Gradient.new()
	var shade_a := randf_range(0.2, 0.5)
	var shade_b := randf_range(0.5, 0.9)
	ramp.set_color(0, Color(shade_a, shade_a, shade_a))
	ramp.set_color(1, Color(shade_b, shade_b, shade_b))
	particles.color_ramp = ramp

	_body.add_child(particles)
	particles.top_level = true
	particles.global_position = _body.global_position
	particles.emitting = true

	var cleanup_timer := _body.get_tree().create_timer(particles.lifetime + 0.2)
	cleanup_timer.timeout.connect(func():
		if is_instance_valid(particles):
			particles.queue_free()
	)

func _push_nearby_plonks(stored_speed: float) -> void:
	var push_strength: float = minf(stored_speed, _max_push_speed)
	var counter = 0
	for ap in PlonkManager.active:
		var other: RigidBody2D = ap.node
		if other == _body:
			continue
		var diff: Vector2 = other.global_position - _body.global_position
		var dist: float = diff.length()
		if dist > _explosion_radius or dist <= 0.0:
			continue
		var falloff: float = 1.0 - (dist / _explosion_radius)  # closer = stronger push
		var push_dir: Vector2 = diff.normalized()
		other.linear_velocity += push_dir * push_strength * falloff
		counter += 1
		
	StatsManager.change_custom_stat(_body.definition.id, "plonks_exploded", counter)
