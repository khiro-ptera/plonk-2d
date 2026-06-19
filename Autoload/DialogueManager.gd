extends Node

signal dialogue_started(data: DialogueData)
signal dialogue_line_changed(line: DialogueLine, line_index: int, total_lines: int)
signal dialogue_ended(data: DialogueData)
signal all_dialogue_finished

var definitions: Dictionary = {}  # id of DialogueData
var triggered_ids: Array[String] = []  # already shown

var _queue: Array[DialogueData] = []
var _current: DialogueData = null
var _current_line: int = 0
var _is_active: bool = false

func _ready() -> void:
	_load_definitions()
	GameState.plinks_changed.connect(_on_plinks_changed)
	GameState.plonk_unlocked.connect(_on_plonk_unlocked)
	GameState.legendary_unlocked.connect(_on_legendary_unlocked)

func _load_definitions() -> void:
	var dir := DirAccess.open("res://Data/dialogue/")
	if not dir:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var res := load("res://Data/dialogue/" + file_name) as DialogueData
			if res:
				definitions[res.id] = res
		file_name = dir.get_next()

func _on_plinks_changed(amount: float) -> void:
	_check_triggers("plinks", amount)

func _on_plonk_unlocked(plonk_id: String) -> void:
	_check_triggers("plonk_unlocked", plonk_id)

func _on_legendary_unlocked(plonk_id: String) -> void:
	_check_triggers("legendary_unlocked", plonk_id)

func _check_triggers(trigger_type: String, value: Variant) -> void:
	for id in definitions:
		if triggered_ids.has(id):
			continue
		var data: DialogueData = definitions[id]
		var cond: Dictionary = data.trigger_condition
		if cond.get("type", "") != trigger_type:
			continue
		var matched := false
		match trigger_type:
			"plinks":
				matched = value >= cond.get("amount", 0.0)
			"plonk_unlocked", "legendary_unlocked":
				matched = value == cond.get("plonk_id", "")
		if matched:
			trigger_dialogue(id)

func trigger_dialogue(id: String) -> void:
	if triggered_ids.has(id):
		print("no dialogue id found")
		return
	var data := definitions.get(id) as DialogueData
	if not data:
		print("not data")
		return
	triggered_ids.append(id)
	_queue.append(data)
	if not _is_active:
		_start_next()

func _start_next() -> void:
	if _queue.size() == 0:
		_is_active = false
		all_dialogue_finished.emit()
		return
	_current = _queue.pop_front()
	_current_line = 0
	_is_active = true
	dialogue_started.emit(_current)
	_show_current_line()

func _show_current_line() -> void:
	var line: DialogueLine = _current.lines[_current_line]
	dialogue_line_changed.emit(line, _current_line, _current.lines.size())
	
func advance() -> void:
	if not _is_active or _current == null:
		return
	_current_line += 1
	if _current_line >= _current.lines.size():
		var finished := _current
		_current = null
		_is_active = false
		dialogue_ended.emit(finished)
		_start_next()
	else:
		_show_current_line()
