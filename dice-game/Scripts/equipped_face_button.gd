extends Button
class_name EquippedFaceButton

@onready var face_icon: TextureRect = $FaceIcon
@onready var value_label: Label = $ValueLabel
@onready var slot_label: Label = $SlotLabel

var face_data: DiceFace
var slot_index: int = -1

func setup(face: DiceFace, new_slot_index: int, is_selected: bool = false):
	face_data = face
	slot_index = new_slot_index

	custom_minimum_size = Vector2(140, 36)
	text = ""
	tooltip_text = get_face_tooltip(face)
	slot_label.text = str(slot_index + 1)
	face_icon.texture = face.icon
	value_label.text = str(face.value) if face.value > 0 else ""

	modulate = Color.YELLOW if is_selected else Color.WHITE

func _notification(what):
	if what == NOTIFICATION_DRAG_END:
		var combat = get_tree().current_scene.get_node_or_null("CombatUI")

		if combat != null:
			combat.clear_drag_fusion_preview()
			
func _can_drop_data(_position, data):
	return data is Dictionary and data.has("face") and data.has("source_type")


func _drop_data(_position, data):
	var combat = get_tree().current_scene.get_node_or_null("CombatUI")

	if combat == null:
		return

	combat.handle_face_drop(data, face_data, "equipped", slot_index)

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
		combat.update_sell_face_preview(face_data)
	set_drag_preview(preview)

	return {
		"source_type": "equipped",
		"slot": slot_index,
		"face": face_data
	}

func set_drop_state(state: String):
	match state:
		"fuse":
			modulate = Color(0.5, 1.0, 0.5)
		"invalid":
			modulate = Color(0.35, 0.35, 0.35)
		"swap":
			modulate = Color.WHITE
		_:
			modulate = Color.WHITE
			
			
func get_face_tooltip(face: DiceFace) -> String:
	var title := get_face_display_name(face)
	if title == "":
		title = face.result_type.capitalize()

	var text := title

	match face.result_type:
		"hit":
			text += "\nDeals " + str(face.value) + " damage. Block reduces this damage."
		"crit":
			text += "\nDeals " + str(face.value) + " damage that ignores Block. Applies Exposed."
		"block":
			text += "\nAdds " + str(face.value) + " Block this round."
		"heal":
			text += "\nRestores " + str(face.value) + " HP."
		"gold":
			text += "\nGain " + str(face.value) + " Gold."
		"miss":
			text += "\nDoes nothing. Can be used in crafting."
		"bleed":
			text += "\nApplies " + str(face.value) + " Bleed. Bleed damages at end of round. Prevented by Block."
		"freeze":
			text += "\nApplies " + str(face.value) + " Freeze. Enemies skip the turn it's applied. Frozen enemies can shatter."
		"twist_knife":
			text += "\nConsumes enemy Bleed and deals that much damage."
		"dodge":
			text += "\nDodges enemy Crit damage from the chosen enemy."
		"reversal":
			text += "\nReflects enemy Crit damage back at the chosen enemy."
		"break_focus":
			text += "\nCancels the chosen enemy's healing."
		"vitality":
			text += "\nPermanently increases max HP."
		"shield_bash":
			text += "\nConsumes all Block and deals that much damage to the target."
		_:
			text += "\n" + face.result_type

	return text

func get_face_display_name(face: DiceFace) -> String:
	match face.result_type:
		"hit":
			return "Hit " + str(face.value)
		"crit":
			return "Crit " + str(face.value)
		"block":
			return "Block " + str(face.value)
		"heal":
			return "Heal " + str(face.value)
		"gold":
			return "Gold " + str(face.value)
		"bleed":
			return "Bleed " + str(face.value)
		"freeze":
			return "Freeze " + str(face.value)
		"shield_bash":
			return "Shield Bash"
		"miss":
			return "Miss"
		_:
			return face.result_type.capitalize()
