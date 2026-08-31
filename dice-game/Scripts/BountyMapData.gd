extends Resource
class_name BountyMapData

var nodes: Array[BountyMapNodeData] = []
var current_node_id: int = -1
var selected_node_id: int = -1
var completed: bool = false


func get_node_by_id(
	wanted_id: int
) -> BountyMapNodeData:
	for node in nodes:
		if node.node_id == wanted_id:
			return node

	return null
