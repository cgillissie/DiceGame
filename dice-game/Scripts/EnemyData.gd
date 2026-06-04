extends Resource

class_name EnemyData

@export var enemy_name: String = "Enemy"
@export var max_hp: int = 20
@export var dice_pool: Array[DiceData]
@export var face_drop_pool: Array[DiceFace]
@export var dice_drop_pool: Array[DiceData]
@export var dice_drop_chance: float = 0.0
@export var gold_reward: int = 10
@export var volatile_core_drop_chance: float = 0.0
@export var sprite_frames: SpriteFrames
@export var idle_animation_name: String = "idle"
@export var sprite_scale: Vector3 = Vector3.ONE
@export var sprite_offset: Vector3 = Vector3.ZERO
@export var idle_animation: String = "idle"
@export var attack_animation: String = "attack"
