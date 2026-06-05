extends Node3D
class_name DamagePopup3D

@onready var label: Label3D = $Label3D

func setup(text: String, color: Color = Color.WHITE):
	label.text = text
	label.modulate = color

	var tween := create_tween()
	tween.tween_property(self, "position", position + Vector3(0, 0.8, 0), 0.45)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.45)

	await tween.finished
	queue_free()
