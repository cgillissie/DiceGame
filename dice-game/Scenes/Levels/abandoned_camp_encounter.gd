extends Node3D

signal camp_choice_made(choice: String)
signal camp_finished(start_ambush: bool)

var pending_ambush: bool = false

@onready var choice_container: HBoxContainer = (
	$CanvasLayer/CampPanel/MarginContainer
	/VBoxContainer/HBoxContainer
)

@onready var result_label: Label = (
	$CanvasLayer/CampPanel/MarginContainer
	/VBoxContainer/ResultLabel
)

@onready var continue_button: Button = (
	$CanvasLayer/CampPanel/MarginContainer
	/VBoxContainer/ContinueButton
)

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
	$ShrineAmbiencePlayer
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
	
	continue_button.pressed.connect(
		_on_continue_pressed
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
	disable_choices()
	camp_choice_made.emit("rest")


func _on_search_pressed():
	disable_choices()
	camp_choice_made.emit("search")


func _on_leave_pressed():
	hide_event_ui()
	camp_choice_made.emit("leave")

func disable_choices():
	choice_container.visible = false


func show_result(
	message: String,
	starts_ambush: bool = false
):
	pending_ambush = starts_ambush

	result_label.text = message
	result_label.visible = true
	continue_button.visible = true


func _on_continue_pressed():
	hide_event_ui()
	camp_finished.emit(
		pending_ambush
	)
	
func hide_event_ui():
	if camp_panel != null:
		camp_panel.visible = false
