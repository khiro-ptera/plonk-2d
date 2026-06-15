class_name PlonkData extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var base_currency_per_bounce: float = 1.0
@export var cost: float = 10.0
@export var scene: PackedScene
@export var unlock_condition: Dictionary = {}
@export var components: Array[String] = []

@export var mass: float = 1.0
@export var physics_material: PhysicsMaterial
@export var linear_speed: float = 200.0
@export var max_angular_velocity: float = 10.0
@export var moment_of_inertia_scale: float = 1.0  

@export_enum("Circle", "Star", "Custom") var shape_type: String = "Circle"
@export var radius: float = 16.0

# unlock ex. { "type": "currency", "amount": 500 }
# or { "type": "stat", "stat": "total_bounces", "amount": 100 }

# compontnents ex. ["GravityComponent", "SuckComponent"]
