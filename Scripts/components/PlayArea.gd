extends Node2D

@export var box_size: Vector2 = Vector2(400, 400)
@export var wall_thickness: float = 20.0

func _ready() -> void:
	_build_walls()

func _build_walls() -> void:
	var w := box_size.x
	var h := box_size.y
	var t := wall_thickness
	# [position, size]
	var walls := [
		[Vector2(w / 2, -t / 2),       Vector2(w + t * 2, t)],  # top
		[Vector2(w / 2, h + t / 2),    Vector2(w + t * 2, t)],  # bottom
		[Vector2(-t / 2, h / 2),       Vector2(t, h)],           # left
		[Vector2(w + t / 2, h / 2),    Vector2(t, h)],           # right
	]
	for i in range(4):
		var body := StaticBody2D.new()
		var col := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = walls[i][1]
		col.shape = shape
		body.add_child(col)
		add_child(body)
		body.position = walls[i][0]
