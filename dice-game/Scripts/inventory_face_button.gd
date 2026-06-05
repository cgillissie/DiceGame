extends Button
class_name InventoryFaceButton

@onready var face_icon: TextureRect = $FaceIcon
@onready var value_label: Label = $ValueLabel

func setup(face: DiceFace, is_selected: bool = false):
	custom_minimum_size = Vector2(56, 56)
	text = ""

	face_icon.texture = face.icon
	value_label.text = str(face.value) if face.value > 0 else ""

	modulate = Color.YELLOW if is_selected else Color.WHITE
