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

func setup(bounty: BountyData):
	bounty_data = bounty

	text = ""
	bounty_label.text = bounty.bounty_name

	clear_rewards()

	if bounty.mulligem_reward > 0:
		add_reward(mulligem_icon, str(bounty.mulligem_reward))

	if bounty.reward_gold > 0:
		add_reward(gold_icon, str(bounty.reward_gold))

	if bounty.reward_volatile_cores > 0:
		add_reward(
			volatile_core_icon,
			str(bounty.reward_volatile_cores)
		)

	if bounty.reward_reserve_slots > 0:
		add_reward(
			reserve_icon,
			str(bounty.reward_reserve_slots)
		)

	for face in bounty.unlocked_merchant_faces:
		add_reward(face.icon, "")

	for relic in bounty.unlocked_relics:
		add_reward(relic.icon, "")

	for recipe in bounty.unlocked_recipes:
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
