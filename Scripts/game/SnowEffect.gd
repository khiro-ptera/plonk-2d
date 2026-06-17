class_name SnowEffect
extends Control

var _particles: Array = []
var _active: bool = true
var _viewport_size: Vector2
var _fade_zone: float = 80.0  # pixels above bottom where fade begins

func _ready() -> void:
	_viewport_size = get_viewport().get_visible_rect().size
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	if _active and randf() < 0.15:
		_spawn_flake()
	for i in range(_particles.size() - 1, -1, -1):
		var p: Dictionary = _particles[i]
		p.pos.y += p.speed * delta
		p.pos.x += sin(p.wobble + p.pos.y * 0.02) * 20.0 * delta
		# fade as it nears the bottom
		var dist_to_bottom: float = _viewport_size.y - p.pos.y
		if dist_to_bottom < _fade_zone:
			p.alpha = clampf(dist_to_bottom / _fade_zone, 0.0, 1.0)
		if p.pos.y > _viewport_size.y:
			_check_plonk_hit(p)
			_particles.remove_at(i)
	queue_redraw()

func _draw() -> void:
	for p in _particles:
		draw_circle(p.pos, p.radius, Color(1.0, 1.0, 1.0, 0.8 * p.alpha))

func _spawn_flake() -> void:
	_particles.append({
		"pos": Vector2(randf() * _viewport_size.x, -10.0),
		"speed": randf_range(90.0, 180.0),
		"radius": randf_range(3.0, 8.0),
		"wobble": randf() * TAU,
		"alpha": 1.0
	})

func _check_plonk_hit(p: Dictionary) -> void:
	for ap in PlonkManager.active:
		var body: RigidBody2D = ap.node
		var dist: float = body.global_position.distance_to(p.pos)
		if dist < ap.definition.radius + p.radius:
			body.linear_velocity *= 0.85

func stop() -> void:
	_active = false

func fade_out_and_free() -> void:
	_active = false
	# wait until all particles have fallen and faded before freeing
	await get_tree().create_timer(10.0).timeout
	queue_free()
