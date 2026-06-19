extends Area2D

var _plinks_value: float = 0.0
var _speed: float = 150.0
var _direction: Vector2 = Vector2.ZERO
var _lifetime: float = 2.0
var _elapsed: float = 0.0
var _start_radius: float = 8.0
var _end_radius: float = 40.0

var _source_plonk_id: String = ""

func _ready() -> void:
	set_physics_process(false)

func launch(direction: Vector2, plinks_value: float, source_plonk_id: String = "") -> void:
	_direction = direction
	_plinks_value = plinks_value
	_source_plonk_id = source_plonk_id
	var shape := CircleShape2D.new()
	shape.radius = _start_radius
	$CollisionShape2D.shape = shape
	$AnimatedSprite2D.modulate.a = 0.5
	$AnimatedSprite2D.scale = Vector2(_start_radius / 50.0, _start_radius / 50.0)
	$AnimatedSprite2D.rotation = direction.angle()
	if $AnimatedSprite2D.sprite_frames:
		$AnimatedSprite2D.play("default")
	body_entered.connect(_on_body_entered)
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	_elapsed += delta
	var t := clampf(_elapsed / _lifetime, 0.0, 1.0)
	position += _direction * _speed * delta
	var current_radius := lerpf(_start_radius, _end_radius, t)
	($CollisionShape2D.shape as CircleShape2D).radius = current_radius
	$AnimatedSprite2D.scale = Vector2(current_radius / 50.0, current_radius / 50.0)
	$AnimatedSprite2D.rotation = _direction.angle()
	if _elapsed >= _lifetime:
		queue_free()

func _on_body_entered(other: Node) -> void:
	if other is StaticBody2D:
		return
	if other == get_parent().get_parent():
		return
	GameState.add_plinks(_plinks_value)
	if _source_plonk_id != "":
		StatsManager.record_plinks(_source_plonk_id, _plinks_value)
	queue_free()
	# reflect direction off the surface normal from the hit plonk
	var to_other: Vector2 = (other.global_position - global_position).normalized()
	_direction = _direction.bounce(to_other)
	# reset lifetime so it doesn't immediately expire after bouncing
	_elapsed = 0.0
