extends Area3D
class_name TownBuilding

signal building_clicked(building_id: String)

@export var building_id: String = ""
@export var idle_animation: String = "idle"
@export var hover_animation: String = "hover"
@export var selected_animation: String = "selected"

@onready var sprite: AnimatedSprite3D = get_parent() as AnimatedSprite3D

func _ready():
	input_event.connect(_on_input_event)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

	if sprite != null and sprite.sprite_frames.has_animation(idle_animation):
		sprite.play(idle_animation)

func _on_mouse_entered():
	print("Hovered: ", building_id)
	if sprite != null and sprite.sprite_frames.has_animation(hover_animation):
		sprite.play(hover_animation)

func _on_mouse_exited():
	if sprite != null and sprite.sprite_frames.has_animation(idle_animation):
		sprite.play(idle_animation)

func _on_input_event(camera, event, position, normal, shape_idx):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if sprite != null and sprite.sprite_frames.has_animation(selected_animation):
				sprite.play(selected_animation)

			building_clicked.emit(building_id)

func force_hover():
	print("Hovered: ", building_id)
	if sprite != null and sprite.sprite_frames.has_animation(hover_animation):
		sprite.play(hover_animation)

func force_unhover():
	if sprite != null and sprite.sprite_frames.has_animation(idle_animation):
		sprite.play(idle_animation)

func force_select():
	print("Clicked: ", building_id)
	if sprite != null and sprite.sprite_frames.has_animation(selected_animation):
		sprite.play(selected_animation)
