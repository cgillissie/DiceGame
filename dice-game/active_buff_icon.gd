extends Control
class_name ActiveBuffIcon

@onready var icon: TextureRect = $Icon

func setup(texture: Texture2D, tooltip: String = ""):
	custom_minimum_size = Vector2(64, 64)

	if icon == null:
		await ready

	icon.texture = texture
	tooltip_text = tooltip
