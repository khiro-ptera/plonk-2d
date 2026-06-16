@tool
class_name PlayArea extends Node2D

@export var box_size: Vector2 = Vector2(400, 400):
	set(value):
		box_size = value
		if Engine.is_editor_hint():
			_build_visuals()
@export var wall_thickness: float = 50.0

func _ready() -> void:
	_build_visuals()
	if not Engine.is_editor_hint():
		_build_walls()

func _build_walls() -> void:
	var w := box_size.x
	var h := box_size.y
	var t := wall_thickness
	var walls := [
		[Vector2(w / 2, -t / 2), Vector2(w + t * 2, t)],
		[Vector2(w / 2, h + t / 2), Vector2(w + t * 2, t)],
		[Vector2(-t / 2, h / 2), Vector2(t, h)],
		[Vector2(w + t / 2, h / 2), Vector2(t, h)],
	]
	for wall_data in walls:
		var shape := RectangleShape2D.new()
		shape.size = wall_data[1]
		var col := CollisionShape2D.new()
		col.shape = shape
		var body := StaticBody2D.new()
		body.position = wall_data[0]
		body.add_child(col)  # add shape to body BEFORE adding body to scene
		add_child(body)
	# _build_visuals()

func _build_visuals() -> void:
	for child in get_children():
		if child is ColorRect:
			child.queue_free()
	
	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 1.0)
	bg.size = box_size
	bg.position = Vector2.ZERO
	bg.z_index = -1
	add_child(bg)
	move_child(bg, 0)

	var border_color := Color(1.0, 1.0, 1.0, 1.0)
	var t := 6.0
	var borders := [
		[Vector2(-t, -t),             Vector2(box_size.x + t * 2, t)],
		[Vector2(-t, box_size.y),     Vector2(box_size.x + t * 2, t)],
		[Vector2(-t, -t),             Vector2(t, box_size.y + t * 2)],
		[Vector2(box_size.x, -t),     Vector2(t, box_size.y + t * 2)],
	]
	for b in borders:
		var rect := ColorRect.new()
		rect.color = border_color
		rect.position = b[0]
		rect.size = b[1]
		rect.z_index = -1
		add_child(rect)
