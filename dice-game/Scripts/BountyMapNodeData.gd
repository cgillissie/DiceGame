extends Resource
class_name BountyMapNodeData

enum NodeType {
	START,
	COMBAT,
	EVENT,
	MERCHANT,
	BOSS
}

enum NodeState {
	HIDDEN,
	LOCKED,
	AVAILABLE,
	COMPLETED,
	ABANDONED
}

var node_id: int = -1
var node_type: NodeType = NodeType.COMBAT
var position: Vector2 = Vector2.ZERO
var connected_node_ids: Array[int] = []
var state: NodeState = NodeState.LOCKED
var encounter_id: String = ""
var revealed: bool = false
var encounter: EncounterData = null
var event_type: String = ""
var boss_icon: Texture2D = null
