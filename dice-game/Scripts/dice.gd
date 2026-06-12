extends Control
class_name DiceNode

signal dice_selected(dice_node)
signal clicked(dice_node)

@export var dice_data: DiceData

var reserve_slots: int = 2

@onready var sprite: TextureRect = $BorderPanel/Panel/TextureRect
@onready var result_label: Label = $BorderPanel/Panel/ResultLabel
@onready var panel: Panel = $BorderPanel/Panel
@onready var border_panel = $BorderPanel
@onready var reserve_lock_icon = $BorderPanel/Panel/ReserveLockIcon
@onready var face_index_label: Label = $BorderPanel/Panel/FaceIndexLabel
@onready var face_icon: TextureRect = $BorderPanel/Panel/FaceIcon
@onready var exploding_icon: TextureRect = $BorderPanel/Panel/ExplodingIcon
@onready var temporary_icon: TextureRect = $BorderPanel/Panel/TemporaryIcon


var current_face_index: int = -1

signal reserve_requested(dice_node)

var current_face: DiceFace
var selected: bool = false
var used: bool = false
var reserved: bool = false
var reserved_turns_remaining: int = 0
var came_from_reserve: bool = false
var assigned_enemy_index: int = -1
var temporary: bool = false
var has_exploded: bool = false
var temporary_value_bonus: int = 0


	
func _ready():
	reserve_lock_icon.visible = false


func setup(data: DiceData):
	dice_data = data
	
	if dice_data != null and dice_data.sprite != null:
		sprite.texture = dice_data.sprite
	
	roll()


func roll():
	if dice_data == null:
		return

	if reserved:
		return

	came_from_reserve = false
	used = false
	selected = false
	has_exploded = false
	current_face_index = randi_range(0, dice_data.faces.size() - 1)
	current_face = dice_data.faces[current_face_index]
	result_label.text = get_face_text(current_face)
	face_index_label.text = str(current_face_index + 1) + "/" + str(dice_data.faces.size())
	update_visual()


func _gui_input(event):
	if used:
		return

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			clicked.emit(self)

		elif event.button_index == MOUSE_BUTTON_RIGHT:
			reserve_requested.emit(self)


func update_visual():
	var face = dice_data.faces[current_face_index]

	face_icon.texture = face.icon
	result_label.text = str(get_display_value())
	
	face_index_label.text = str(current_face_index + 1) + "/" + str(dice_data.faces.size())
	reserve_lock_icon.visible = came_from_reserve
	if used:
		panel.modulate = Color(0.4, 0.4, 0.4)
	else:
		panel.modulate = Color(1, 1, 1)

	if selected:
		border_panel.modulate = Color.YELLOW

	elif reserved:
		border_panel.modulate = Color.CYAN

	elif came_from_reserve:
		border_panel.modulate = Color.RED

	else:
		border_panel.modulate = Color.WHITE
		
	exploding_icon.visible = false
	temporary_icon.visible = temporary
	if dice_data != null and dice_data.can_explode:
		if current_face_index == dice_data.faces.size() - 1:
			exploding_icon.visible = true

func get_face_text(face: DiceFace) -> String:
	match face.result_type:
		"miss":
			return ""
		"hit":
			return str(face.value)
		"crit":
			return str(face.value)
		"block":
			return str(face.value)
		"heal":
			return str(face.value)
		"buff":
			return face.label
		"gold":
			return str(face.value)
		"dodge":
			return ""
		"reversal":
			return ""
		"freeze":
			return "Freeze " + str(face.value)
		_:
			return face.result_type


func get_display_value() -> int:
	if current_face == null:
		return 0

	if current_face.result_type == "hit":
		return current_face.value + temporary_value_bonus

	return current_face.value
	
func set_compact_mode(enabled: bool):
	if enabled:
		custom_minimum_size = Vector2(55, 55)
		panel.custom_minimum_size = Vector2(55, 55)
		face_icon.custom_minimum_size = Vector2(28, 28)
		result_label.add_theme_font_size_override("font_size", 14)
		face_index_label.add_theme_font_size_override("font_size", 8)
		exploding_icon.custom_minimum_size = Vector2(10, 10)
		temporary_icon.custom_minimum_size = Vector2(10, 10)
	else:
		custom_minimum_size = Vector2(90, 90)
		panel.custom_minimum_size = Vector2(90, 90)
		face_icon.custom_minimum_size = Vector2(56, 56)
		result_label.add_theme_font_size_override("font_size", 20)
		face_index_label.add_theme_font_size_override("font_size", 16)
		exploding_icon.custom_minimum_size = Vector2(18, 18)
		temporary_icon.custom_minimum_size = Vector2(18, 18)

func roll_animated(roll_area: Control, roll_index: int = 0, total_rolls: int = 1, final_container: Control = null):
	if dice_data == null:
		return

	if reserved:
		return

	reparent(roll_area)

	var spacing := 70
	var total_width := (total_rolls - 1) * spacing
	var start_x := -total_width / 2.0
	var offset_x := start_x + (roll_index * spacing)

	global_position = roll_area.global_position + (roll_area.size / 2.0) - (size / 2.0)
	global_position.x += offset_x
	
	has_exploded = false
	came_from_reserve = false
	used = false
	selected = false

	var start_pos := global_position

	for i in 8:
		var preview_index := randi_range(0, dice_data.faces.size() - 1)
		var preview_face := dice_data.faces[preview_index]

		result_label.text = get_face_text(preview_face)
		face_index_label.text = str(preview_index + 1) + "/" + str(dice_data.faces.size())

		global_position = start_pos + Vector2(randf_range(-5, 5), randf_range(-5, 5))

		await get_tree().create_timer(0.035).timeout

	current_face_index = randi_range(0, dice_data.faces.size() - 1)
	current_face = dice_data.faces[current_face_index]

	result_label.text = get_face_text(current_face)
	face_index_label.text = str(current_face_index + 1) + "/" + str(dice_data.faces.size())

	global_position = start_pos
	update_visual()

	if final_container != null:
		await fly_to_container(final_container)
		
func fly_to_container(final_container: Control):
	var target_position := final_container.global_position + Vector2(
		8 + final_container.get_child_count() * 60,
		8
	)

	var tween := create_tween()
	tween.tween_property(self, "global_position", target_position, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	await tween.finished

	reparent(final_container)
	position = Vector2.ZERO
	visible = true
