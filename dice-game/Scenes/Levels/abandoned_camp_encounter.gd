extends Node3D

signal camp_choice_made(choice: String)

@onready var camp_panel: Control = (
	$CanvasLayer/CampPanel
)

@onready var rest_button: Button = (
	$CanvasLayer/CampPanel/MarginContainer
	/VBoxContainer/HBoxContainer/RestButton
)

@onready var search_button: Button = (
	$CanvasLayer/CampPanel/MarginContainer
	/VBoxContainer/HBoxContainer/SearchButton
)

@onready var leave_button: Button = (
	$CanvasLayer/CampPanel/MarginContainer
	/VBoxContainer/HBoxContainer/LeaveButton
)

@export var ambience_sound: AudioStream

@onready var ambience_player: AudioStreamPlayer = (
	$CampAmbiencePlayer
)


func _ready():
	rest_button.pressed.connect(
		_on_rest_pressed
	)

	search_button.pressed.connect(
		_on_search_pressed
	)

	leave_button.pressed.connect(
		_on_leave_pressed
	)

	if ambience_player == null:
		push_error(
			"Abandoned campsite is missing CampAmbiencePlayer."
		)
		return

	ambience_player.bus = "SFX"

	if ambience_sound == null:
		push_error(
			"Abandoned campsite ambience_sound is not assigned."
		)
		return

	ambience_player.stream = ambience_sound
	ambience_player.play()

func _on_rest_pressed():
	hide_event_ui()
	camp_choice_made.emit("rest")


func _on_search_pressed():
	hide_event_ui()
	camp_choice_made.emit("search")


func _on_leave_pressed():
	hide_event_ui()
	camp_choice_made.emit("leave")


func hide_event_ui():
	if camp_panel != null:
		camp_panel.visible = false
