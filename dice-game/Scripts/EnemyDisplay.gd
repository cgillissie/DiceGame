extends Control
class_name EnemyDisplay

signal selected(enemy_index)

@onready var enemy_button: Button = $MarginContainer/VBoxContainer/EnemyButton
@onready var hp_label: Label = $MarginContainer/VBoxContainer/HPLabel
@onready var intent_label: Label = $MarginContainer/VBoxContainer/IntentLabel
@onready var incoming_label: Label = $MarginContainer/VBoxContainer/IncomingLabel
@onready var roll_preview_container: HBoxContainer = $MarginContainer/VBoxContainer/RollPreviewContainer
@onready var assigned_dice_container: HBoxContainer = $MarginContainer/VBoxContainer/AssignedDiceContainer

var enemy_index: int = -1

func setup(index: int, enemy: Dictionary):
	enemy_index = index
	var data: EnemyData = enemy["data"]

	enemy_button.text = data.enemy_name
	hp_label.text = "HP: " + str(enemy["hp"])
	intent_label.text = "Intent: Attack " + str(enemy["attack"]) + " | Crit " + str(enemy["crit"]) + " | Block " + str(enemy["block"]) + " | Heal " + str(enemy["heal"])

func _ready():
	enemy_button.pressed.connect(_on_pressed)

func _on_pressed():
	selected.emit(enemy_index)
