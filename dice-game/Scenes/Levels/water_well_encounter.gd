extends Node3D

signal well_choice_made(pulled_bucket: bool)
signal reward_acknowledged

@onready var well_panel: Control = $CanvasLayer/WellPanel
@onready var pull_bucket_button: Button = $CanvasLayer/WellPanel/MarginContainer/VBoxContainer/HBoxContainer/PullBucketButton
@onready var leave_button: Button = $CanvasLayer/WellPanel/MarginContainer/VBoxContainer/HBoxContainer/LeaveButton
@onready var event_panel: Control = $CanvasLayer/WellPanel
@export var wind_sound: AudioStream
@onready var wind_player: AudioStreamPlayer = $WindPlayer

func _ready():

	pull_bucket_button.pressed.connect(_on_pull_bucket_pressed)
	leave_button.pressed.connect(_on_leave_pressed)

	if wind_player == null:
		push_error("Well scene is missing WindPlayer.")
		return

	wind_player.bus = "SFX"

	if wind_sound == null:
		push_error("Well wind_sound is not assigned in the Inspector.")
		return

	wind_player.stream = wind_sound
	wind_player.play()

	print("Well wind started: ", wind_player.playing)



func _on_pull_bucket_pressed():
	hide_event_ui()
	well_choice_made.emit(true)


func _on_leave_pressed():
	hide_event_ui()
	well_choice_made.emit(false)
	
func hide_event_ui():
	if event_panel != null:
		event_panel.visible = false
