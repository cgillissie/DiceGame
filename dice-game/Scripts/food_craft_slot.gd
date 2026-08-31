extends PanelContainer
class_name FoodCraftSlot

signal ingredient_dropped(
	slot_index: int,
	item_name: String
)

signal ingredient_removed(slot_index: int)

@export var slot_index: int = 0

@onready var ingredient_icon: TextureRect = (
	$MarginContainer/VBoxContainer/IngredientIcon
)

@onready var ingredient_name_label: Label = (
	$MarginContainer/VBoxContainer/IngredientNameLabel
)

var current_item_name: String = ""


func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP
	ingredient_icon.visible = false
	refresh_visual()


func _can_drop_data(
	_at_position: Vector2,
	data: Variant
) -> bool:
	if !(data is Dictionary):
		return false

	return data.has("food_item_name")


func _drop_data(
	at_position: Vector2,
	data: Variant
):
	if !_can_drop_data(at_position, data):
		return

	var item_name: String = String(
		data.get("food_item_name", "")
	)

	if item_name.is_empty():
		return

	ingredient_dropped.emit(
		slot_index,
		item_name
	)


func _gui_input(event: InputEvent):
	if (
		event is InputEventMouseButton
		and event.button_index == MOUSE_BUTTON_RIGHT
		and event.pressed
	):
		ingredient_removed.emit(slot_index)
		accept_event()


func set_ingredient(
	item_name: String,
	icon: Texture2D
):
	current_item_name = item_name
	ingredient_icon.texture = icon
	ingredient_icon.visible = true
	refresh_visual()


func clear_ingredient():
	current_item_name = ""
	ingredient_icon.texture = null
	ingredient_icon.visible = false
	refresh_visual()


func refresh_visual():
	if current_item_name.is_empty():
		ingredient_name_label.text = "Empty"
	else:
		ingredient_name_label.text = current_item_name
