extends PanelContainer
class_name FaceInventoryDropArea

signal equipped_face_dropped(data: Dictionary)

func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP

	remove_theme_stylebox_override(
		"panel"
	)

	var empty_style := StyleBoxEmpty.new()

	add_theme_stylebox_override(
		"panel",
		empty_style
	)
	
func _can_drop_data(
	_position: Vector2,
	data: Variant
) -> bool:
	if !(data is Dictionary):
		return false

	return (
		String(data.get("source_type", "")) == "equipped"
		and data.has("slot")
		and data.has("face")
	)


func _drop_data(
	position: Vector2,
	data: Variant
):
	if !_can_drop_data(position, data):
		return

	equipped_face_dropped.emit(data)
