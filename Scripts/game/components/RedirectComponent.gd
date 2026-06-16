class_name RedirectComponent extends Node

var _body: RigidBody2D
var _base_speed: float
var _redirecting: bool = false
var _current_angle: float = 0.0  # class level, not local

func activate(body: RigidBody2D) -> void:
	_body = body
	_base_speed = body.definition.spawn_linear_speed
	_body.body_entered.connect(_on_body_entered)

func _physics_process(_delta: float) -> void:
	if _body == null:
		return
	if _redirecting:
		_body.linear_velocity = Vector2.ZERO
		_body.angular_velocity = 0.0
		return
	var current_speed := _body.linear_velocity.length()
	if current_speed > _base_speed * 2.0:
		_body.linear_velocity = _body.linear_velocity.normalized() * _base_speed * 2.0
	if current_speed < _base_speed * 0.5:
		_start_redirect()

func _on_body_entered(_other: Node) -> void:
	if _redirecting:
		_body.linear_velocity = Vector2.ZERO
		_body.angular_velocity = 0.0

func _start_redirect() -> void:
	_redirecting = true
	_body.linear_velocity = Vector2.ZERO
	_body.angular_velocity = 0.0
	_body.override_rotation = true

	var sprite := _body.get_node("AnimatedSprite2D") as AnimatedSprite2D
	sprite.stop()
	sprite.sprite_frames.set_animation_loop("bounce", true)
	_body._bouncing = true
	sprite.play("bounce")

	var start_angle: float = sprite.rotation
	_current_angle = start_angle
	var target_angle := start_angle + randf_range(PI * 0.5, PI * 1.5)

	var tween := _body.create_tween()
	tween.tween_method(
		func(a: float):
			_current_angle = a
			_body.linear_velocity = Vector2.ZERO
			sprite.rotation = a
			_body.get_node("ShapeSprite").rotation = a,
		start_angle,
		target_angle,
		0.5
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	tween.tween_interval(1.0)

	tween.tween_callback(func():
		sprite.sprite_frames.set_animation_loop("bounce", false)
		_body.linear_velocity = Vector2(cos(_current_angle), sin(_current_angle)) * _base_speed
		_body._bouncing = false
		_body.override_rotation = false
		_redirecting = false
	)
	
