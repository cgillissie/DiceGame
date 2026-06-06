extends Resource
class_name ConsumableItem

@export var item_name: String
@export_multiline var description: String
@export var icon: Texture2D

@export var cost: int = 5

@export var heal_amount: int = 0
@export var next_combat_block: int = 0
@export var next_combat_damage: int = 0
@export var increase_max_hp: int = 0
@export var next_combat_max_hp: int = 0
