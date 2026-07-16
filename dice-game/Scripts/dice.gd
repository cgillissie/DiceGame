extends Control
class_name DiceNode

signal dice_selected(dice_node)
signal clicked(dice_node)
signal drag_started(dice_node)
signal drag_finished(dice_node, screen_position: Vector2)

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
@onready var buff_glow: TextureRect = $BorderPanel/Panel/BuffGlow


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
var buff_glow_tween: Tween = null
var display_value_override: int = -1
var base_visual_scale := Vector2.ONE

var left_mouse_held: bool = false
var is_dragging: bool = false
var invalid_drag_attempted: bool = false
var mouse_is_hovering: bool = false
var drag_start_mouse_position: Vector2 = Vector2.ZERO
var drag_threshold: float = 10.0
	
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

func can_drag_to_enemy() -> bool:
	if current_face == null:
		return false

	if used:
		return false

	if reserved:
		return false

	return current_face.result_type in [
		"hit",
		"crit",
		"dodge",
		"reversal",
		"freeze",
		"bleed",
		"twist_knife",
		"break_focus",
		"shield_bash",
		"fireball"
	]
	
func _gui_input(event):
	if used:
		return

	if !(event is InputEventMouseButton):
		return

	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			left_mouse_held = true
			is_dragging = false
			invalid_drag_attempted = false
			drag_start_mouse_position = get_global_mouse_position()
			accept_event()
		else:
			finish_left_mouse_interaction()

	elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		reserve_requested.emit(self)
		accept_event()
			
func _input(event):
	if !left_mouse_held:
		return

	if used:
		cancel_drag_interaction()
		return

	if event is InputEventMouseMotion:
		var current_mouse_position := get_global_mouse_position()

		if !is_dragging:
			var drag_distance := drag_start_mouse_position.distance_to(
				current_mouse_position
			)

			if drag_distance >= drag_threshold:
				if !can_drag_to_enemy():
					invalid_drag_attempted = true
					return

				is_dragging = true
				drag_started.emit(self)

		if is_dragging:
			global_position = current_mouse_position - size * 0.5
			get_viewport().set_input_as_handled()

	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and !event.pressed:
			finish_left_mouse_interaction()
			
func finish_left_mouse_interaction():
	if !left_mouse_held:
		return

	left_mouse_held = false

	if is_dragging:
		is_dragging = false

		drag_finished.emit(
			self,
			get_global_mouse_position()
		)

	elif !invalid_drag_attempted:
		clicked.emit(self)

	invalid_drag_attempted = false

func apply_current_visual_scale():
	scale = base_visual_scale

	if is_dragging:
		z_index = 1000
	elif mouse_is_hovering:
		z_index = 100
	else:
		z_index = 0
		
func cancel_drag_interaction():
	left_mouse_held = false
	is_dragging = false
	invalid_drag_attempted = false
	apply_current_visual_scale()
	
func set_base_visual_scale(new_scale: Vector2):
	base_visual_scale = new_scale
	apply_current_visual_scale()
	
func _on_mouse_entered():
	mouse_is_hovering = true

	if is_dragging:
		return

	apply_current_visual_scale()

func _on_mouse_exited():
	mouse_is_hovering = false

	if is_dragging:
		return

	apply_current_visual_scale()
	
func update_tooltip():
	if current_face == null:
		tooltip_text = ""
		return

	tooltip_text = get_face_tooltip(current_face)

	if (
		current_face.result_type == "hit"
		and temporary_value_bonus > 0
	):
		tooltip_text += (
			"\nCurrent total: "
			+ str(current_face.value + temporary_value_bonus)
			+ " damage."
			+ "\nBuff bonus: +"
			+ str(temporary_value_bonus)
			+ "."
		)
	
func get_face_tooltip(face: DiceFace) -> String:
	if face == null:
		return ""

	return face.get_tooltip(dice_data)
		
func update_visual():
	if dice_data == null:
		return

	if current_face == null:
		return

	var face = current_face

	face_icon.texture = face.icon
	face_index_label.text = str(current_face_index + 1) + "/" + str(dice_data.faces.size())
	reserve_lock_icon.visible = came_from_reserve

	if face_should_show_value(face):
		var value_to_show: int = face.value

		if face.result_type == "hit":
			value_to_show += temporary_value_bonus

		result_label.text = str(value_to_show)
		result_label.visible = true
	else:
		result_label.text = ""
		result_label.visible = false

	if used:
		panel.modulate = Color(0.4, 0.4, 0.4)
	else:
		panel.modulate = Color(1, 1, 1)

	if reserved:
		border_panel.modulate = Color.CYAN
	elif selected:
		border_panel.modulate = Color.YELLOW
	elif came_from_reserve:
		border_panel.modulate = Color.RED
	else:
		border_panel.modulate = Color.WHITE

	exploding_icon.visible = false
	temporary_icon.visible = temporary

	if dice_data != null and dice_data.can_explode:
		if current_face_index == dice_data.faces.size() - 1:
			exploding_icon.visible = true
	
	update_tooltip()
	update_buff_glow()
	
func face_should_show_value(face: DiceFace) -> bool:
	if face == null:
		return false

	return face.result_type in [
		"hit",
		"crit",
		"block",
		"gold",
		"heal",
		"vitality",
		"bleed",
		"freeze",
		"pain"
	]
	
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
		"bleed":
			return "Bleed " + str(face.value)
		"freeze":
			return "Freeze " + str(face.value)
		"vitality":
			return "Vitality " + str(face.value)
		"twist_knife":
			return ""
		"pain":
			return "Pain " + str(face.value)
		"shield_bash":
			return "Shield Bash"
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

		result_label.add_theme_font_size_override(
			"font_size",
			14
		)

		face_index_label.add_theme_font_size_override(
			"font_size",
			8
		)

		exploding_icon.custom_minimum_size = Vector2(10, 10)
		temporary_icon.custom_minimum_size = Vector2(10, 10)
	else:
		custom_minimum_size = Vector2(90, 90)
		panel.custom_minimum_size = Vector2(90, 90)
		face_icon.custom_minimum_size = Vector2(56, 56)

		result_label.add_theme_font_size_override(
			"font_size",
			20
		)

		face_index_label.add_theme_font_size_override(
			"font_size",
			16
		)

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

func update_buff_glow():
	if buff_glow == null:
		return

	var should_glow := (
		current_face != null
		and current_face.result_type == "hit"
		and temporary_value_bonus > 0
		and !used
	)

	buff_glow.visible = should_glow

	if !should_glow:
		if buff_glow_tween != null:
			if buff_glow_tween.is_valid():
				buff_glow_tween.kill()

		buff_glow.scale = Vector2.ONE
		buff_glow.modulate.a = 0.0
		return

	buff_glow.pivot_offset = buff_glow.size * 0.5
	buff_glow.scale = Vector2.ONE
	buff_glow.modulate = Color(
		0.35,
		1.0,
		0.75,
		0.65
	)

	if buff_glow_tween != null:
		if buff_glow_tween.is_valid():
			buff_glow_tween.kill()

	buff_glow_tween = create_tween()
	buff_glow_tween.set_loops()

	buff_glow_tween.tween_property(
		buff_glow,
		"scale",
		Vector2(1.10, 1.10),
		0.7
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	buff_glow_tween.tween_property(
		buff_glow,
		"scale",
		Vector2.ONE,
		0.7
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
