class_name ClickComponent extends Node

var _body: RigidBody2D

func activate(body: RigidBody2D) -> void:
	_body = body
	GameState.register_click_listener(self)

func _on_global_click() -> void:
	if not is_instance_valid(_body):
		return
	var reward: float = maxf(GameState.plinks * 0.0001, 50.0)
	GameState.add_plinks(reward)
	if _body.definition:
		StatsManager.record_plinks(_body.definition.id, reward)
		StatsManager.change_custom_stat(_body.definition.id, "times clicked", 1)

func _exit_tree() -> void:
	GameState.unregister_click_listener(self)
