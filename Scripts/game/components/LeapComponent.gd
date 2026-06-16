class_name LeapComponent
extends Node

var _body: RigidBody2D
var _base_speed: float
var _leaping: bool = false
var _bottom_wall: StaticBody2D = null

func activate(body: RigidBody2D) -> void:
	_body = body
	_base_speed = body.definition.spawn_linear_speed
	_body.body_entered.connect(_on_body_entered)

func _on_body_entered(other: Node) -> void:
	if _leaping:
		return
	if _is_bottom_wall(other):
		_start_leap()

func _is_bottom_wall(other: Node) -> bool:
	if not other is StaticBody2D:
		return false
	# bottom wall is below the play area center
	var play_area := GameState.play_area
	var area_center_y: float = play_area.position.y + play_area.get("box_size").y / 2.0
	return other.global_position.y > area_center_y

func _start_leap() -> void:
	_leaping = true
	_body.linear_velocity = Vector2.ZERO
	_body.angular_velocity = 0.0
	_body.override_rotation = true
	_body._bouncing = true

	var sprite := _body.get_node("AnimatedSprite2D") as AnimatedSprite2D
	sprite.stop()
	sprite.sprite_frames.set_animation_loop("bounce", true)
	sprite.play("bounce")

	var timer := _body.create_tween()
	timer.tween_interval(0.5)
	timer.tween_callback(_do_leap)

func _do_leap() -> void:
	# random angle within 30 degrees of straight up (-PI/2)
	var angle := -PI / 2.0 + randf_range(-PI / 6.0, PI / 6.0)
	var speed := randf_range(_base_speed * 0.4, _base_speed * 4.4)
	_body.linear_velocity = Vector2(cos(angle), sin(angle)) * speed

	var sprite := _body.get_node("AnimatedSprite2D") as AnimatedSprite2D
	sprite.sprite_frames.set_animation_loop("bounce", false)
	_body._bouncing = false
	_body.override_rotation = false
	_leaping = false

func _physics_process(_delta: float) -> void:
	if _leaping and _body != null:
		_body.linear_velocity = Vector2.ZERO
		_body.angular_velocity = 0.0
