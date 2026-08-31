extends Control
class_name BountyMapScreen

signal node_selected(node_id: int)
signal camp_requested

@export var node_button_scene: PackedScene

@onready var camp_button: Button = $CampButton
@onready var title_label: Label = $TitleLabel
@onready var connection_layer: BountyMapConnectionLayer = (
	$ConnectionLayer
)
@onready var node_layer: Control = $NodeLayer

var map_data: BountyMapData = null
var selection_locked: bool = false



func _ready():
	set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	mouse_filter = Control.MOUSE_FILTER_STOP

	camp_button.pressed.connect(
		_on_camp_button_pressed
	)
	
func setup(
	data: BountyMapData,
	bounty_name: String
):
	map_data = data
	title_label.text = bounty_name
	connection_layer.setup(map_data)
	rebuild_map()
	
func _on_camp_button_pressed():
	camp_requested.emit()
	
func _on_node_selected(node_id: int):
	if selection_locked:
		return

	selection_locked = true
	mouse_filter = Control.MOUSE_FILTER_STOP

	node_selected.emit(node_id)
	
func rebuild_map():
	clear_map_visuals()

	if map_data == null:
		push_error(
			"BountyMapScreen received null map data."
		)
		return

	if node_button_scene == null:
		push_error(
			"BountyMapScreen has no node button scene assigned."
		)
		return

	for node_data in map_data.nodes:
		var button: BountyMapNodeButton = (
			node_button_scene.instantiate()
		)

		node_layer.add_child(button)
		button.setup(node_data)

		button.node_selected.connect(
			_on_node_selected
		)


func clear_map_visuals():
	for child in node_layer.get_children():
		child.free()

	for child in connection_layer.get_children():
		child.free()




func _gui_input(event: InputEvent):
	if event is InputEventMouse:
		accept_event()
		
func set_map_interaction_enabled(
	enabled: bool
):
	camp_button.disabled = !enabled

	for child in node_layer.get_children():
		if child is BountyMapNodeButton:
			if enabled:
				child.update_visual()
			else:
				child.disabled = true
