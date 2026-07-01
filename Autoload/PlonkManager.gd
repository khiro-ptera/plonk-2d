extends Node

class ActivePlonk:
	var node: RigidBody2D
	var definition: PlonkData
	var paid: float

var definitions: Dictionary = {}   # id -> PlonkData
var active: Array[ActivePlonk] = []


const PLONK_PATHS: Array[String] = [
	"res://Data/plonks/basic_plonk.tres",
	"res://Data/plonks/bighornk.tres",
	"res://Data/plonks/bunk.tres",
	"res://Data/plonks/castlink.tres",
	"res://Data/plonks/chonk.tres",
	"res://Data/plonks/clink.tres",
	"res://Data/plonks/foxbomk.tres",
	"res://Data/plonks/newtonk.tres",
	"res://Data/plonks/positronk.tres",
	"res://Data/plonks/pteronk.tres",
	"res://Data/plonks/purrrank.tres",
	"res://Data/plonks/satellink.tres",
	"res://Data/plonks/splink.tres",
	"res://Data/plonks/spoonk.tres",
	"res://Data/plonks/starplunk.tres",
	"res://Data/plonks/teddybink.tres",
	"res://Data/plonks/terachonk.tres",
	"res://Data/plonks/spidonk.tres",
	"res://Data/plonks/krokoronk.tres",
]

func _ready() -> void:
	_load_definitions()
	GameState.total_clicks_changed.connect(func(_count): _check_legendary_unlocks())

func _load_definitions() -> void:
	for path in PLONK_PATHS:
		var res := load(path) as PlonkData
		if res:
			definitions[res.id] = res
			if res.unlock_plinks_threshold == 0.0:
				GameState.unlock_plonk(res.id)  # available from start
		else:
			push_error("PlonkManager: failed to load " + path)

func get_unlocked_definitions() -> Array:
	var unlocked := []
	for id in definitions:
		var data: PlonkData = definitions[id]
		if data.is_legendary:
			continue
		if GameState.unlocked_plonk_ids.has(id):
			unlocked.append(data)
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
	if data.is_legendary and GameState.owned_legendary_ids.has(plonk_id):
		return
	if data.is_legendary:
		GameState.owned_legendary_ids.append(plonk_id)
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
	_check_legendary_unlocks()

func sell_plonk(plonk_id: String) -> void:
	for i in range(active.size() - 1, -1, -1):
		var ap: ActivePlonk = active[i]
		if ap.definition.id == plonk_id:
			GameState.add_plinks(ap.paid * ap.definition.sell_value_fraction)
			ap.node.queue_free()
			active.remove_at(i)
			if ap.definition.is_legendary:
				GameState.owned_legendary_ids.erase(plonk_id)
			GameState.emit_plonk_count()
			_check_legendary_unlocks()
			return

func _check_legendary_unlocks() -> void:
	for id in definitions:
		var data: PlonkData = definitions[id]
		if not data.is_legendary:
			continue
		if GameState.unlocked_legendary_ids.has(id):
			continue
		if _meets_condition(data.unlock_condition):
			GameState.unlock_legendary(id)

func _meets_condition(condition: Dictionary) -> bool:
	match condition.get("type", ""):
		"plinks":
			return GameState.plinks >= condition.get("amount", 0.0)
		"simultaneous_count":
			var target_id: String = condition.get("plonk_id", "")
			var amount: int = condition.get("amount", 0)
			return get_count_in_play(target_id) >= amount
		"total_clicks":
			return GameState.total_clicks >= condition.get("amount", 0)
		_:
			return false
