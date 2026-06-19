class_name RandomPointComponent extends Node

var _body: RigidBody2D
var _current_points: int = 5

func activate(body: RigidBody2D) -> void:
	_body = body
	_current_points = body.definition.star_points
	_body.body_entered.connect(_on_body_entered)

func _on_body_entered(_other: Node) -> void:
	if not is_instance_valid(_body) or _body.definition == null:
		return
	_current_points = randi_range(3, 10)
	_rebuild_star_shape.call_deferred()

func _rebuild_star_shape() -> void:
	for child in _body.get_children():
		if child is CollisionShape2D and child.name != "CollisionShape2D":
			child.queue_free()

	var data: PlonkData = _body.definition
	var verts: PackedVector2Array = _make_star_polygon(data.radius, data.inner_radius, _current_points)
	_body.get_node("ShapeSprite").polygon = verts

	for i in range(verts.size()):
		var tri := ConvexPolygonShape2D.new()
		tri.points = PackedVector2Array([
			Vector2.ZERO,
			verts[i],
			verts[(i + 1) % verts.size()]
		])
		var col := CollisionShape2D.new()
		col.shape = tri
		_body.add_child(col)

func _make_star_polygon(outer_radius: float, inner_radius: float, points: int) -> PackedVector2Array:
	var verts := PackedVector2Array()
	var total_verts := points * 2
	for i in range(total_verts):
		var a := (float(i) / total_verts) * TAU - PI / 2.0
		var r := outer_radius if i % 2 == 0 else inner_radius
		verts.append(Vector2(cos(a), sin(a)) * r)
	return verts
