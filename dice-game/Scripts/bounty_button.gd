extends Button
class_name BountyButton

@onready var bounty_label: Label = $MarginContainer/VBoxContainer/BountyLabel
@onready var rewards_grid: GridContainer = $MarginContainer/VBoxContainer/RewardsGrid

@export var reward_icon_scene: PackedScene

@export var gold_icon: Texture2D
@export var mulligem_icon: Texture2D
@export var volatile_core_icon: Texture2D
@export var reserve_icon: Texture2D

var bounty_data: BountyData
var bounty_unlocked: bool = true


func _ready():
	if bounty_data != null:
		refresh_button()

func setup(
	bounty: BountyData,
	unlocked: bool = true
):
	bounty_data = bounty
	bounty_unlocked = unlocked
	text = ""

	if !is_node_ready():
		return

	refresh_button()

func refresh_button():
	if bounty_data == null:
		return

	if bounty_label == null:
		return

	if rewards_grid == null:
		return

	disabled = !bounty_unlocked
	text = ""

	if bounty_unlocked:
		bounty_label.text = bounty_data.bounty_name
	else:
		bounty_label.text = (
			bounty_data.bounty_name
			+ " — Locked"
		)

	clear_rewards()

	if bounty_data.mulligem_reward > 0:
		add_reward(
			mulligem_icon,
			str(bounty_data.mulligem_reward)
		)

	if bounty_data.reward_gold > 0:
		add_reward(
			gold_icon,
			str(bounty_data.reward_gold)
		)

	if bounty_data.reward_volatile_cores > 0:
		add_reward(
			volatile_core_icon,
			str(
				bounty_data.reward_volatile_cores
			)
		)

	if bounty_data.reward_reserve_slots > 0:
		add_reward(
			reserve_icon,
			str(
				bounty_data.reward_reserve_slots
			)
		)

	for face in bounty_data.unlocked_merchant_faces:
		add_reward(face.icon, "")

	for relic in bounty_data.unlocked_relics:
		add_reward(relic.icon, "")

	for recipe in bounty_data.unlocked_recipes:
		add_reward(recipe.icon, "")

func clear_rewards():
	for child in rewards_grid.get_children():
		child.queue_free()
		
func add_reward(texture: Texture2D, value_text: String):
	if reward_icon_scene == null:
		push_error("reward_icon_scene is null")
		return

	var reward = reward_icon_scene.instantiate()
	rewards_grid.add_child(reward)

	if reward.has_method("setup"):
		reward.setup(texture, value_text)
	else:
		push_error("Reward icon scene does not have setup()")
