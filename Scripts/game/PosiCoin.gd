extends Area2D

var _plinks_value: float = 0.0
var _velocity: Vector2 = Vector2.ZERO
var _lifetime: float = 6.0
var _elapsed: float = 0.0

var _source_plonk_id: String = ""

func setup(velocity: Vector2, plinks_value: float, source_plonk_id: String = "") -> void:
	_velocity = velocity
	_plinks_value = plinks_value
	_source_plonk_id = source_plonk_id
	if $AnimatedSprite2D.sprite_frames:
		$AnimatedSprite2D.play("default")
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	_elapsed += delta
	position += _velocity * delta
	# fade out near end of life
	if _elapsed > _lifetime - 1.0:
		modulate.a = clampf(_lifetime - _elapsed, 0.0, 1.0)
	if _elapsed >= _lifetime:
		queue_free()

func _on_body_entered(other: Node) -> void:
	if other is StaticBody2D:
		return
	if not other is RigidBody2D:
		return
	# dont let Positronk-type plonks (or any with CoinTrailComponent) pick up coins
	if other.get_node_or_null("CoinTrailComponent") != null:
		return
	if _source_plonk_id != "":
		StatsManager.record_plinks(_source_plonk_id, _plinks_value)
	GameState.add_plinks(_plinks_value)
	queue_free()
