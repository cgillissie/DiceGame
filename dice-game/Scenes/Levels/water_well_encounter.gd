extends Node3D

signal well_choice_made(pulled_bucket: bool)

@onready var description_label: RichTextLabel = $CanvasLayer/WellPanel/MarginContainer/VBoxContainer/DescriptionLabel
@onready var pull_bucket_button: Button = $CanvasLayer/WellPanel/MarginContainer/VBoxContainer/HBoxContainer/PullBucketButton
@onready var leave_button: Button = $CanvasLayer/WellPanel/MarginContainer/VBoxContainer/HBoxContainer/LeaveButton
@export var wind_sound: AudioStream
@onready var wind_player: AudioStreamPlayer = $WindPlayer

func _ready():
	description_label.text = "An old abandoned well rests under the moonlight.\nSomething glimmers far below, calling you by name..."

	pull_bucket_button.text = "Pull up the bucket"
	leave_button.text = "Leave"

	pull_bucket_button.pressed.connect(_on_pull_bucket_pressed)
	leave_button.pressed.connect(_on_leave_pressed)
	if wind_sound != null:
		wind_player.stream = wind_sound
		wind_player.play()
func _on_pull_bucket_pressed():
	well_choice_made.emit(true)

func _on_leave_pressed():
	well_choice_made.emit(false)
