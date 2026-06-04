extends Resource
class_name DiceData

@export var can_explode: bool = false
@export var die_name: String = "Basic Die"
@export var sides: int = 6
@export var sprite: Texture2D
@export var faces: Array[DiceFace] = []
