extends Button
class_name BountyMapNodeButton

signal node_selected(node_id: int)

var node_data: BountyMapNodeData = null

@onready var node_icon: TextureRect = $Icon
@onready var event_label: Label = $EventLabel

@export var combat_icon: Texture2D
@export var merchant_icon: Texture2D

var hover_tween: Tween = null

const HOVER_SCALE := Vector2(1.15, 1.15)
const NORMAL_SCALE := Vector2.ONE
const HOVER_DURATION := 0.08

func _ready():
	custom_minimum_size = Vector2.ZERO
	size = Vector2(64, 64)

	mouse_entered.connect(
		_on_mouse_entered
	)

	mouse_exited.connect(
		_on_mouse_exited
	)
func setup(data: BountyMapNodeData):
	node_data = data

	set_anchors_and_offsets_preset(
		Control.PRESET_TOP_LEFT
	)

	custom_minimum_size = Vector2.ZERO

	if (
		node_data.node_type
		== BountyMapNodeData.NodeType.BOSS
	):
		size = Vector2(88, 88)
		node_icon.size = Vector2(72, 72)
		node_icon.position = Vector2(8, 8)
	else:
		size = Vector2(64, 64)
		node_icon.size = Vector2(44, 44)
		node_icon.position = Vector2(10, 10)

	position = (
		data.position
		- size * 0.5
	)
		
	pivot_offset = size * 0.5
	scale = NORMAL_SCALE
	
	update_visual()
	update_tooltip()
	
func update_visual():
	if node_data == null:
		return
	if (
		node_data.state
		!= BountyMapNodeData.NodeState.AVAILABLE
	):
		scale = NORMAL_SCALE
	update_node_content()

	match node_data.state:
		BountyMapNodeData.NodeState.HIDDEN:
			visible = false
			disabled = true

		BountyMapNodeData.NodeState.LOCKED:
			visible = true
			disabled = true
			modulate = Color(0.4, 0.4, 0.4)

		BountyMapNodeData.NodeState.AVAILABLE:
			visible = true
			disabled = false
			modulate = Color(0.55, 0.85, 1.0)

		BountyMapNodeData.NodeState.COMPLETED:
			visible = true
			disabled = true
			modulate = Color(0.9, 0.82, 0.55)

		BountyMapNodeData.NodeState.ABANDONED:
			visible = true
			disabled = true
			modulate = Color(0.22, 0.22, 0.24)
	if (
		node_data.node_type
		== BountyMapNodeData.NodeType.BOSS
	):
		node_icon.texture = node_data.boss_icon
		node_icon.visible = true

func update_node_content():
	if node_data == null:
		return

	text = ""

	node_icon.texture = null
	node_icon.visible = false

	event_label.visible = false

	if !node_data.revealed:
		event_label.text = "?"
		event_label.visible = true
		return

	match node_data.node_type:
		BountyMapNodeData.NodeType.START:
			event_label.text = "S"
			event_label.visible = true

		BountyMapNodeData.NodeType.COMBAT:
			node_icon.texture = combat_icon
			node_icon.visible = true

		BountyMapNodeData.NodeType.EVENT:
			event_label.text = "?"
			event_label.visible = true

		BountyMapNodeData.NodeType.MERCHANT:
			node_icon.texture = merchant_icon
			node_icon.visible = true

		BountyMapNodeData.NodeType.BOSS:
			node_icon.texture = node_data.boss_icon
			node_icon.visible = true
			
func get_node_symbol() -> String:
	if node_data == null:
		return "?"

	if !node_data.revealed:
		return "?"

	match node_data.node_type:
		BountyMapNodeData.NodeType.START:
			return "S"

		BountyMapNodeData.NodeType.COMBAT:
			return "C"

		BountyMapNodeData.NodeType.EVENT:
			return "?"

		BountyMapNodeData.NodeType.MERCHANT:
			return "M"

		BountyMapNodeData.NodeType.BOSS:
			return "B"

	return "?"


func _pressed():
	if node_data == null:
		return

	if (
		node_data.state
		!= BountyMapNodeData.NodeState.AVAILABLE
	):
		return

	node_selected.emit(
		node_data.node_id
	)

func update_tooltip():
	tooltip_text = ""

	if node_data == null:
		return

	if (
		node_data.state
		!= BountyMapNodeData.NodeState.AVAILABLE
	):
		return

	if node_data.encounter == null:
		return

	match node_data.node_type:
		BountyMapNodeData.NodeType.COMBAT:
			tooltip_text = "Combat\n\n"

			for enemy in node_data.encounter.enemies:
				if enemy == null:
					continue

				tooltip_text += (
					"• "
					+ enemy.enemy_name
					+ "\n"
				)

		BountyMapNodeData.NodeType.BOSS:
			tooltip_text = "Boss\n\n"

			for enemy in node_data.encounter.enemies:
				if enemy == null:
					continue

				tooltip_text += (
					"• "
					+ enemy.enemy_name
					+ "\n"
				)
		BountyMapNodeData.NodeType.EVENT:
			tooltip_text = "Unknown Event"
			
			
func _on_mouse_entered():
	if node_data == null:
		return

	if (
		node_data.state
		!= BountyMapNodeData.NodeState.AVAILABLE
	):
		return

	if hover_tween != null:
		hover_tween.kill()

	hover_tween = create_tween()

	hover_tween.set_trans(
		Tween.TRANS_QUAD
	)

	hover_tween.set_ease(
		Tween.EASE_OUT
	)

	hover_tween.tween_property(
		self,
		"scale",
		HOVER_SCALE,
		HOVER_DURATION
	)


func _on_mouse_exited():
	if hover_tween != null:
		hover_tween.kill()

	hover_tween = create_tween()

	hover_tween.set_trans(
		Tween.TRANS_QUAD
	)

	hover_tween.set_ease(
		Tween.EASE_OUT
	)

	hover_tween.tween_property(
		self,
		"scale",
		NORMAL_SCALE,
		HOVER_DURATION
	)
