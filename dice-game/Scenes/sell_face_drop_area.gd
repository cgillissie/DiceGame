extends Panel
class_name SellFaceDropArea

func _can_drop_data(_position, data):
	return data is Dictionary and data.has("face") and data.has("source_type")


func _drop_data(_position, data):
	var combat = get_tree().current_scene.get_node_or_null("CombatUI")

	if combat == null:
		return

	combat.handle_sell_face_drop(data)
