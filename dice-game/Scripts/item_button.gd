extends Button
class_name ItemButton

@onready var icon_texture: TextureRect = $IconTextureRect
@onready var count_label: Label = $CountLabel
@onready var cost_label: Label = $CostLabel

var food_drag_enabled: bool = false
var food_item_name: String = ""


func setup(
	icon: Texture2D,
	count_text: String = "",
	cost_text: String = ""
):
	text = ""
	custom_minimum_size = Vector2(64, 64)

	icon_texture.texture = icon
	count_label.text = count_text
	cost_label.text = cost_text


func enable_food_crafting_drag(
	item_name: String
):
	food_drag_enabled = true
	food_item_name = item_name


func disable_food_crafting_drag():
	food_drag_enabled = false
	food_item_name = ""


func _get_drag_data(
	_position: Vector2
):
	if !food_drag_enabled:
		return null

	if food_item_name.is_empty():
		return null

	var preview := TextureRect.new()
	preview.texture = icon_texture.texture
	preview.custom_minimum_size = Vector2(64, 64)
	preview.expand_mode = (
		TextureRect.EXPAND_IGNORE_SIZE
	)
	preview.stretch_mode = (
		TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	)

	set_drag_preview(preview)

	return {
		"type": "food_ingredient",
		"food_item_name": food_item_name
	}
