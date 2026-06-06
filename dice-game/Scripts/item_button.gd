extends Button
class_name ItemButton

@onready var icon_texture: TextureRect = $IconTextureRect
@onready var count_label: Label = $CountLabel
@onready var cost_label: Label = $CostLabel

func setup(item: ConsumableItem, count_text: String = "", cost_text: String = ""):
	text = ""
	custom_minimum_size = Vector2(64, 64)

	icon_texture.texture = item.icon
	count_label.text = count_text
	cost_label.text = cost_text
