extends Button
class_name InventoryFaceButton

@onready var face_icon: TextureRect = $FaceIcon
@onready var value_label: Label = $ValueLabel

var face_data: DiceFace

func setup(face: DiceFace, is_selected: bool = false):
	face_data = face

	custom_minimum_size = Vector2(56, 56)
	text = ""

	face_icon.texture = face.icon
	value_label.text = str(face.value) if face.value > 0 else ""

	modulate = Color.YELLOW if is_selected else Color.WHITE

func _notification(what):
	if what == NOTIFICATION_DRAG_END:
		var combat = get_tree().current_scene.get_node_or_null("CombatUI")

		if combat != null:
			combat.clear_drag_fusion_preview()
			
func _get_drag_data(_position):
	if face_data == null:
		return null

	var preview := TextureRect.new()
	preview.texture = face_data.icon
	preview.custom_minimum_size = Vector2(56, 56)
	preview.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var combat = get_tree().current_scene.get_node_or_null("CombatUI")
	if combat != null:
		combat.update_drag_fusion_preview(face_data)
	set_drag_preview(preview)

	return {
		"source_type": "inventory",
		"source_button": self,
		"face": face_data
	}
	
func _can_drop_data(_position, data):
	return data is Dictionary and data.has("face") and data.has("source_type")


func _drop_data(_position, data):
	var combat = get_tree().current_scene.get_node_or_null("CombatUI")

	if combat == null:
		return

	combat.handle_inventory_face_drop(data, face_data)
