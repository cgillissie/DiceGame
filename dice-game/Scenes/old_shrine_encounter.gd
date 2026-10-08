extends Node3D

signal shrine_choice_made(choice: String)

@onready var shrine_panel: Control = (
	$CanvasLayer/ShrinePanel
)

@onready var gold_offering_button: Button = (
	$CanvasLayer/ShrinePanel/MarginContainer
	/VBoxContainer/HBoxContainer/GoldOfferingButton
)

@onready var blood_offering_button: Button = (
	$CanvasLayer/ShrinePanel/MarginContainer
	/VBoxContainer/HBoxContainer/BloodOfferingButton
)

@onready var leave_button: Button = (
	$CanvasLayer/ShrinePanel/MarginContainer
	/VBoxContainer/HBoxContainer/LeaveButton
)
@export var ambience_sound: AudioStream

@onready var ambience_player: AudioStreamPlayer = (
	$CampAmbiencePlayer
)

func _ready():
	gold_offering_button.pressed.connect(
		_on_gold_offering_pressed
	)

	blood_offering_button.pressed.connect(
		_on_blood_offering_pressed
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
	
func setup_offering_availability(
	current_gold: int,
	current_hp: int
):
	gold_offering_button.disabled = (
		current_gold < 20
	)

	blood_offering_button.disabled = (
		current_hp <= 10
	)
	
func _on_gold_offering_pressed():
	hide_event_ui()
	shrine_choice_made.emit("gold")


func _on_blood_offering_pressed():
	hide_event_ui()
	shrine_choice_made.emit("blood")


func _on_leave_pressed():
	hide_event_ui()
	shrine_choice_made.emit("leave")


func hide_event_ui():
	if shrine_panel != null:
		shrine_panel.visible = false
