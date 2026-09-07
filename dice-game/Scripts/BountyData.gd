extends Resource
class_name BountyData

@export var bounty_name: String
@export_multiline var description: String
@export var boss_encounter: EncounterData
@export var expedition_encounter_pool: Array[EncounterData]
@export var min_encounters_before_boss: int
@export var max_encounters_before_boss: int
@export var completed: bool = false
@export var reward_food_tier_unlock: int = 0
@export var reward_volatile_cores: int = 0
@export var reward_gold: int = 0
@export var reward_reserve_slots: int = 0
@export var unlocked_merchant_faces: Array[DiceFace]
@export var mulligem_reward: int = 1
@export var unlocked_relics: Array[RelicData]
@export var unlocked_recipes: Array[FoodRecipe]
@export var reward_max_hp: int = 2
@export var prerequisite_bounty: BountyData
@export_range(2, 20, 1) var bounty_map_route_length: int = 6
@export var boss_icon: Texture2D
