class_name PlonkData extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var base_currency_per_bounce: float = 1.0
@export var speed: float = 200.0
@export var radius: float = 16.0
@export var sell_value: float = 0.0
@export var scene: PackedScene

# ex. { "type": "currency", "amount": 500 }
# or { "type": "stat", "stat": "total_bounces", "amount": 100 }
@export var unlock_condition: Dictionary = {}

# ex. ["GravityComponent", "SuckComponent"]
@export var components: Array[String] = []
