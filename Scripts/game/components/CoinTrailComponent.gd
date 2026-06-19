class_name CoinTrailComponent
extends Node

var _body: RigidBody2D
var _drop_timer: float = 0.0
var _drop_interval: float = 0.15  # time between coin drops
const COIN_SCENE: PackedScene = preload("res://Scenes/plonks/projectiles/PosiCoin.tscn")

func activate(body: RigidBody2D) -> void:
	_body = body

func _physics_process(delta: float) -> void:
	if not is_instance_valid(_body):
		return
	if _body.linear_velocity.length() < 1.0:
		return  # dont drop coins while stationary
	_drop_timer += delta
	if _drop_timer >= _drop_interval:
		_drop_timer = 0.0
		_drop_coin()

func _drop_coin() -> void:
	var coin := COIN_SCENE.instantiate()
	var container := _body.get_node("/root/Main/GameWorld/PlonkContainer")
	container.add_child(coin)
	coin.global_position = _body.global_position

	# trail direction is opposite of travel direction, with +-30 degree spread
	var travel_dir: Vector2 = _body.linear_velocity.normalized()
	var base_angle: float = (-travel_dir).angle()
	var spread: float = randf_range(-PI / 6.0, PI / 6.0)  # +-30 degrees
	var final_angle: float = base_angle + spread
	var trail_velocity: Vector2 = Vector2(cos(final_angle), sin(final_angle)) * 20.0  # slow speed

	var plinks_value: float = _body.definition.base_plinks_per_bounce
	coin.setup(trail_velocity, plinks_value, _body.definition.id)
