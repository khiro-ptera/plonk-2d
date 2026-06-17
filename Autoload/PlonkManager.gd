extends Node

class ActivePlonk:
	var node: RigidBody2D
	var definition: PlonkData
	var paid: float

var definitions: Dictionary = {}   # id -> PlonkData
var active: Array[ActivePlonk] = []

func _ready() -> void:
	_load_definitions()

func _load_definitions() -> void:
	var dir := DirAccess.open("res://data/plonks/")
	if not dir:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var res := load("res://data/plonks/" + file_name) as PlonkData
			if res:
				definitions[res.id] = res
				if res.unlock_plinks_threshold == 0.0:
					GameState.unlock_plonk(res.id)  # available from start
		file_name = dir.get_next()

func get_unlocked_definitions() -> Array:
	var unlocked := []
	for id in definitions:
		if GameState.unlocked_plonk_ids.has(id):
			unlocked.append(definitions[id])
	unlocked.sort_custom(func(a, b): return a.unlock_plinks_threshold < b.unlock_plinks_threshold)
	return unlocked

func get_count_in_play(plonk_id: String) -> int:
	var count := 0
	for p in active:
		if p.definition.id == plonk_id:
			count += 1
	return count

func get_current_price(data: PlonkData) -> float:
	return snapped(data.base_price * pow(data.price_exponent, get_count_in_play(data.id) - 0), 0.1)

func spawn_plonk(plonk_id: String, position: Vector2) -> void:
	if active.size() >= GameState.max_plonks:
		return
	var data := definitions.get(plonk_id) as PlonkData
	if not data or not data.scene:
		push_error("PlonkManager: missing scene for " + plonk_id)
		return
	var node := data.scene.instantiate() as RigidBody2D
	get_tree().get_root().get_node("Main/GameWorld/PlonkContainer").add_child(node)
	node.position = position
	node.setup(data)
	node.linear_velocity *= GameState.plonk_speed_multiplier
	var ap := ActivePlonk.new()
	ap.node = node
	ap.definition = data
	ap.paid = get_current_price(data)
	active.append(ap)
	GameState.emit_plonk_count()

func sell_plonk(plonk_id: String) -> void:
	for i in range(active.size() - 1, -1, -1):
		var ap: ActivePlonk = active[i]
		if ap.definition.id == plonk_id:
			GameState.add_plinks(ap.paid * ap.definition.sell_value_fraction)
			ap.node.queue_free()
			active.remove_at(i)
			GameState.emit_plonk_count()
			return
