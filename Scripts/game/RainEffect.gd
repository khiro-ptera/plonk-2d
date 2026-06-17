class_name RainEffect
extends Control

var _particles: Array = []
var _active: bool = true
var _viewport_size: Vector2

func _ready() -> void:
	_viewport_size = get_viewport().get_visible_rect().size
	# make control fill the viewport
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	if _active and randf() < 0.4:
		_spawn_drop()
	for i in range(_particles.size() - 1, -1, -1):
		var p: Dictionary = _particles[i]
		p.pos.y += p.speed * delta
		p.pos.x += p.drift * delta
		if p.pos.y > _viewport_size.y:
			_particles.remove_at(i)
	queue_redraw()

func _draw() -> void:
	for p in _particles:
		draw_line(p.pos, p.pos + Vector2(p.drift * 0.05, 8.0), Color(0.7, 0.7, 0.7, 0.85), 1.0)

func _spawn_drop() -> void:
	_particles.append({
		"pos": Vector2(randf() * _viewport_size.x, -10.0),
		"speed": randf_range(400.0, 700.0),
		"drift": randf_range(-20.0, 20.0)
	})

func stop() -> void:
	_active = false
