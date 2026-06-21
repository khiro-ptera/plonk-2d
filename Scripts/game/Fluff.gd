extends Area2D

var _velocity: Vector2 = Vector2.ZERO
var _plinks_per_bounce: float = 0.0
var _source_plonk_id: String = ""
var _lifetime: float = 4.0
var _elapsed: float = 0.0
var _rotation_speed: float = 0.0

func setup(velocity: Vector2, texture: Texture2D, plinks_per_bounce: float, source_plonk_id: String) -> void:
	_velocity = velocity
	_plinks_per_bounce = plinks_per_bounce
	_source_plonk_id = source_plonk_id
	$Sprite2D.texture = texture
	_rotation_speed = randf_range(-3.0, 3.0)
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	_elapsed += delta
	position += _velocity * delta
	rotation += _rotation_speed * delta
	modulate.a = clampf(1.0 - (_elapsed / _lifetime), 0.0, 1.0)
	if _elapsed >= _lifetime:
		queue_free()

func _on_body_entered(other: Node) -> void:
	if other is StaticBody2D:
		return
	if not other is RigidBody2D:
		return
	var plonk: RigidBody2D = other
	if plonk.get_node_or_null("HibernateComponent") != null:
		return  # teddybinks dont collect their own fluff

	var speed_before: float = plonk.linear_velocity.length()
	var speed_lost: float = speed_before * 0.2
	var new_speed: float = speed_before - speed_lost
	plonk.linear_velocity = plonk.linear_velocity.normalized() * new_speed

	var plinks_gained: float = _plinks_per_bounce * (speed_lost / 50.0)
	GameState.add_plinks(plinks_gained)
	if _source_plonk_id != "":
		StatsManager.record_plinks(_source_plonk_id, plinks_gained)
		StatsManager.change_custom_stat(_source_plonk_id, "fluff_collected", 1)


	queue_free()
