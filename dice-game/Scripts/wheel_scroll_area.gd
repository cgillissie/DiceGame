extends Control
class_name WheelScrollArea

@export var target_scroll_container: ScrollContainer
@export var scroll_speed := 64

func _unhandled_input(event):
	if target_scroll_container == null:
		return

	if !get_global_rect().has_point(get_global_mouse_position()):
		return

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_scroll_container.scroll_vertical -= scroll_speed
			get_viewport().set_input_as_handled()

		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_scroll_container.scroll_vertical += scroll_speed
			get_viewport().set_input_as_handled()
