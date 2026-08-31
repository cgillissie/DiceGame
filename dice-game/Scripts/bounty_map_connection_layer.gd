extends Control
class_name BountyMapConnectionLayer

var map_data: BountyMapData = null


func setup(data: BountyMapData):
	map_data = data
	queue_redraw()


func _draw():
	if map_data == null:
		return

	for node in map_data.nodes:
		for connected_id in node.connected_node_ids:
			var connected_node: BountyMapNodeData = (
				map_data.get_node_by_id(
					connected_id
				)
			)

			if connected_node == null:
				continue

			var start_pos := node.position
			var end_pos := connected_node.position

			var line_color := Color(
				0.28,
				0.28,
				0.30,
				0.65
			)

			var line_width := 3.0

			if (
				node.state
				== BountyMapNodeData.NodeState.COMPLETED
			):
				if (
					connected_node.state
					== BountyMapNodeData.NodeState.AVAILABLE
				):
					line_color = Color(
						0.45,
						0.75,
						1.0,
						0.95
					)

					line_width = 5.0

				elif (
					connected_node.state
					== BountyMapNodeData.NodeState.COMPLETED
				):
					line_color = Color(
						0.85,
						0.8,
						0.55,
						0.9
					)

					line_width = 4.0

				elif (
					connected_node.state
					== BountyMapNodeData.NodeState.ABANDONED
				):
					line_color = Color(
						0.15,
						0.15,
						0.17,
						0.45
					)

			draw_line(
				start_pos,
				end_pos,
				line_color,
				line_width,
				true
			)
