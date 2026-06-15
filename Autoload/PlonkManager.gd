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
		file_name = dir.get_next()

func get_count_in_play(plonk_id: String) -> int:
	var count := 0
	for p in active:
		if p.definition.id == plonk_id:
			count += 1
	return count

func get_current_price(data: PlonkData) -> float:
	return data.base_price * pow(data.price_exponent, get_count_in_play(data.id))

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
	var ap := ActivePlonk.new()
	ap.node = node
	ap.definition = data
	ap.paid = get_current_price(data)
	active.append(ap)
