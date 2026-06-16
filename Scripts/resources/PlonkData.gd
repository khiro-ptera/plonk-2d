class_name PlonkData extends Resource

# id
@export var id: String = ""
@export var display_name: String = ""
@export var unlock_plinks_threshold: float = 0.0  # 0 = available from start

# econ
@export var base_price: float = 10.0
@export var price_exponent: float = 1.15  # price = base_price * exponent^(count_in_play - 1)
@export var sell_value_fraction: float = 0.5  # sell returns this fraction of what you paid
@export var base_plinks_per_bounce: float = 1.0  # sell returns this fraction of what you paid

# physics
@export var mass: float = 1.0
@export var physics_material: PhysicsMaterial
@export var spawn_linear_speed: float = 200.0
@export var max_angular_velocity: float = 10.0
@export_enum("Circle", "Star", "Custom") var shape_type: String = "Circle"
@export var radius: float = 16.0  # only used for Circle shape_type

# vis
@export var scene: PackedScene
@export var sprite_frames: SpriteFrames
@export var animation_fps: float = 3.0  # 3 frames over 1 second = 3 fps

# component
@export var components: Array[String] = []

# shop display
@export var description: String = ""
@export var shop_icon: Texture2D  # small icon for the shop tile, separate from spritesheet

# unlock ex. { "type": "plinks", "amount": 500 }
# or { "type": "stat", "stat": "total_bounces", "amount": 100 }

# compontnents ex. ["GravityComponent", "SuckComponent"]
