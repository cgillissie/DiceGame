extends Button
class_name BountyMapNodeButton

signal node_selected(node_id: int)

var node_data: BountyMapNodeData = null

func _ready():
	custom_minimum_size = Vector2.ZERO
	size = Vector2(64, 64)
	
func setup(data: BountyMapNodeData):
	node_data = data

	set_anchors_and_offsets_preset(
		Control.PRESET_TOP_LEFT
	)

	custom_minimum_size = Vector2.ZERO
	size = Vector2(64, 64)

	position = (
		data.position
		- size * 0.5
	)

	update_visual()
	update_tooltip()
	
func update_visual():
	if node_data == null:
		return

	text = get_node_symbol()

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
		modulate = Color(1.0, 0.35, 0.35)

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
			
			
