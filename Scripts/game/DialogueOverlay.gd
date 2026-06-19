extends Control

@onready var dialogue_text: Label = $DialogueBox/DialogueText
@onready var character_viewport: SubViewport = $CharacterContainer/CharacterViewport
@onready var character_shape: Polygon2D = $CharacterContainer/CharacterViewport/CharacterShape
@onready var character_sprite: AnimatedSprite2D = $CharacterContainer/CharacterViewport/CharacterSprite
@onready var advance_arrow: AnimatedSprite2D = $ArrowContainer/AdvanceArrow
@onready var character_display: TextureRect = $CharacterContainer/CharacterDisplay

func _ready() -> void:
	visible = false
	character_display.texture = character_viewport.get_texture()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	# gui_input.connect(_on_gui_input)
	
	for child in get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_PASS
	
	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.dialogue_line_changed.connect(_on_line_changed)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)
	
	advance_arrow.play("default")

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		# print("Next")
		DialogueManager.advance()

func _on_dialogue_started(data: DialogueData) -> void:
	visible = true
	_setup_character(data)

func _setup_character(data: DialogueData) -> void:
	var center := Vector2(character_viewport.size) / 2.0
	character_shape.position = center
	character_sprite.position = center
	character_shape.color = Color.WHITE
	if data.character_sprite_frames:
		character_sprite.sprite_frames = data.character_sprite_frames
	_apply_character_radius(data, data.character_radius)

func _make_circle_polygon(radius: float, points: int) -> PackedVector2Array:
	var verts := PackedVector2Array()
	for i in range(points):
		var a := (float(i) / points) * TAU
		verts.append(Vector2(cos(a), sin(a)) * radius)
	return verts

func _on_line_changed(line: DialogueLine, _index: int, _total: int) -> void:
	dialogue_text.text = line.text

	var data: DialogueData = DialogueManager._current
	var radius: float = line.radius if line.radius > 0.0 else data.character_radius
	_apply_character_radius(data, radius)

	if line.animation != "" and character_sprite.sprite_frames and character_sprite.sprite_frames.has_animation(line.animation):
		character_sprite.play(line.animation)

func _apply_character_radius(data: DialogueData, radius: float) -> void:
	match data.character_shape:
		"Circle":
			character_shape.polygon = _make_circle_polygon(radius, 32)
		"Star":
			character_shape.polygon = _make_circle_polygon(radius, 32)
	var sprite_scale: float = radius / 50.0
	character_sprite.scale = Vector2(sprite_scale, sprite_scale)

func _on_dialogue_ended(_data: DialogueData) -> void:
	if not DialogueManager._is_active:
		visible = false

func _on_all_dialogue_finished() -> void:
	visible = false
