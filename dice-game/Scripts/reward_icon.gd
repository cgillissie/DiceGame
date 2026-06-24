extends Control

@onready var icon: TextureRect = $HBoxContainer/TextureRect
@onready var value_label: Label = $HBoxContainer/ValueLabel

func setup(texture: Texture2D, value_text: String):
	icon.texture = texture
	value_label.text = value_text

	if value_text == "":
		value_label.visible = false
		value_label.custom_minimum_size = Vector2.ZERO
		custom_minimum_size = Vector2(16, 16)
	else:
		value_label.visible = true
		value_label.custom_minimum_size = Vector2(12, 16)
		custom_minimum_size = Vector2(48, 16)
