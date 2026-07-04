extends Node3D
class_name WitchEncounter

signal witch_choice_made(accepted: bool)

@onready var witch_panel: Control = $CanvasLayer/WitchPanel
@onready var witch_text_label: RichTextLabel = $CanvasLayer/WitchPanel/MarginContainer/VBoxContainer/WitchTextLabel
@onready var accept_button: Button = $CanvasLayer/WitchPanel/MarginContainer/VBoxContainer/HBoxContainer/AcceptButton
@onready var ignore_button: Button = $CanvasLayer/WitchPanel/MarginContainer/VBoxContainer/HBoxContainer/IgnoreButton
@onready var player_sprite: AnimatedSprite3D = $PlayerSprite
@onready var witch_sprite: AnimatedSprite3D = $WitchSprite
@onready var camera: Camera3D = $Camera3D
var camera_base_position: Vector3
var camera_time := 0.0

@export var sway_speed := 0.35
@export var sway_amount := 0.025

func _ready():
	camera_base_position = camera.position
	if player_sprite.sprite_frames.has_animation("idle"):
		player_sprite.play("idle")

	if witch_sprite.sprite_frames.has_animation("idle"):
		witch_sprite.play("idle")

	witch_panel.visible = true
	witch_panel.modulate.a = 0

	var tween := create_tween()
	tween.tween_property(witch_panel, "modulate:a", 1.0, 0.35)
	witch_panel.visible = true

	witch_text_label.text = "The witch smiles from beside her hut.\n\n\"I offer you protection... but power always leaves a mark.\"\n\nGain a relic and a cursed die?"

	accept_button.text = "Accept"
	ignore_button.text = "Ignore"

	accept_button.pressed.connect(_on_accept_pressed)
	ignore_button.pressed.connect(_on_ignore_pressed)

func _process(delta):
	camera_time += delta
	
	var offset := Vector3(
		sin(camera_time * sway_speed) * sway_amount,
		cos(camera_time * sway_speed * 0.8) * sway_amount * 0.5,
		0.0
	)

	camera.position = camera_base_position + offset
func _on_accept_pressed():
	witch_choice_made.emit(true)


func _on_ignore_pressed():
	witch_choice_made.emit(false)
