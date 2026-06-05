extends Button
class_name EquippedFaceButton

@onready var face_icon: TextureRect = $FaceIcon
@onready var value_label: Label = $ValueLabel
@onready var slot_label: Label = $SlotLabel

func setup(face: DiceFace, slot_index: int, is_selected: bool = false):
	custom_minimum_size = Vector2(140, 36)
	text = ""

	slot_label.text = str(slot_index + 1)
	face_icon.texture = face.icon
	value_label.text = str(face.value) if face.value > 0 else ""

	modulate = Color.YELLOW if is_selected else Color.WHITE
	
