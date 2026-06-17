class_name SpookComponent extends Node

var _body: RigidBody2D

func activate(body: RigidBody2D) -> void:
	_body = body
	# put spoonks on layer 2, mask 2 so they only collide with each other
	# layer 1 is regular plonks, layer 2 is spoonks
	_body.collision_layer = 2
	_body.collision_mask = 2
	_body.get_node("ShapeSprite").modulate.a = 0.4
	_body.get_node("AnimatedSprite2D").modulate.a = 0.4
	# use an Area2D to detect regular plonks without physically colliding
	var detect_area := Area2D.new()
	detect_area.name = "SpookDetectArea"
	detect_area.collision_layer = 0
	detect_area.collision_mask = 1  # detect regular plonks on layer 1
	detect_area.monitoring = true
	detect_area.monitorable = false
	detect_area.top_level = true
	var shape := CircleShape2D.new()
	shape.radius = _body.definition.radius
	var col := CollisionShape2D.new()
	col.shape = shape
	detect_area.add_child(col)
	_body.add_child(detect_area)
	detect_area.body_entered.connect(_on_plonk_entered)

func _physics_process(_delta: float) -> void:
	if _body == null:
		return
	var detect_area := _body.get_node_or_null("SpookDetectArea") as Area2D
	if detect_area:
		detect_area.global_position = _body.global_position

func _on_plonk_entered(other: Node) -> void:
	if not other is RigidBody2D:
		return
	if not is_instance_valid(other):
		return
	if other.get_node_or_null("SpookComponent") != null:
		return
	var other_body := other as RigidBody2D
	var speed_boost: float = _body.linear_velocity.length() * 0.5
	var current_speed: float = other_body.linear_velocity.length()
	# add speed in the direction the other plonk is already moving
	if other_body.linear_velocity.length() > 0.0:
		other_body.linear_velocity = other_body.linear_velocity.normalized() * (current_speed + speed_boost)
	else:
		# if the other plonk is stationary give it a push in spoonk's direction
		other_body.linear_velocity = _body.linear_velocity.normalized() * speed_boost
