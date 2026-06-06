extends Resource
class_name BountyData

@export var bounty_name: String
@export_multiline var description: String
@export var boss_encounter: EncounterData
@export var expedition_encounter_pool: Array[EncounterData]
@export var required_encounters_before_boss: int = 3
@export var completed: bool = false
