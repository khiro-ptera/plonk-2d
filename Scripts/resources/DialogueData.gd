class_name DialogueData
extends Resource

@export var id: String = ""
@export var character_shape: String = "Circle"
@export var character_radius: float = 40.0
@export var character_sprite_frames: SpriteFrames
@export var lines: Array[DialogueLine] = []
@export var trigger_condition: Dictionary = {}
# examples:
#   { "type": "plinks", "amount": 100.0 }
#   { "type": "plonk_unlocked", "plonk_id": "plonk1" }
#   { "type": "legendary_unlocked", "plonk_id": "plonkl0" }
#   { "type": "manual" }  (fired by code directly)
