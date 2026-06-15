extends Area3D
class_name TownBuilding

signal building_clicked(building_id: String)

@export var building_id: String = ""
@export var idle_animation: String = "idle"
@export var hover_animation: String = "hover"
@export var selected_animation: String = "selected"
@export var idle_loop_sound: AudioStream
@export var idle_loop_volume_db: float = -8.0

@export var anvil_sound: AudioStream
@export var anvil_frame: int = 0
var last_frame := -1

@onready var sprite: AnimatedSprite3D = get_parent() as AnimatedSprite3D

@export var hover_sound: AudioStream
@export var select_sound: AudioStream

@onready var idle_audio_player := AudioStreamPlayer3D.new()
@onready var audio_player := AudioStreamPlayer3D.new()

var is_selected := false

func _ready():
	input_event.connect(_on_input_event)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	if sprite != null:
		sprite.frame_changed.connect(_on_sprite_frame_changed)
	add_child(audio_player)
	audio_player.max_distance = 50.0
	audio_player.unit_size = 10.0
	add_child(idle_audio_player)
	idle_audio_player.max_distance = 50.0
	idle_audio_player.unit_size = 6.0
	idle_audio_player.volume_db = idle_loop_volume_db

	if idle_loop_sound != null:
		idle_audio_player.stream = idle_loop_sound
		idle_audio_player.play()
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
	if sprite != null:
		sprite.play(hover_animation)

	if hover_sound:
		audio_player.stream = hover_sound
		audio_player.play()
	if idle_audio_player.playing:
		idle_audio_player.stop()
func force_unhover():
	if is_selected:
		return

	if sprite != null and sprite.sprite_frames.has_animation(idle_animation):
		sprite.play(idle_animation)
	if idle_loop_sound != null and !idle_audio_player.playing:
		idle_audio_player.play()
		
func force_select():
	is_selected = true
	print("Clicked: ", building_id)

	if sprite != null and sprite.sprite_frames.has_animation(selected_animation):
		sprite.play(selected_animation)
	if select_sound:
		audio_player.stream = select_sound
		audio_player.play()

func force_deselect():
	is_selected = false
	if sprite != null and sprite.sprite_frames.has_animation(idle_animation):
		sprite.play(idle_animation)
	if idle_loop_sound != null and !idle_audio_player.playing:
		idle_audio_player.play()
		
func _on_sprite_frame_changed():
	if sprite == null:
		return

	if anvil_sound == null:
		return

	if sprite.animation == hover_animation:
		return

	if sprite.frame != anvil_frame:
		return

	audio_player.stream = anvil_sound
	audio_player.pitch_scale = randf_range(0.95, 1.05)
	audio_player.play()
