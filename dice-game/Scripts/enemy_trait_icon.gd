extends Control
class_name EnemyTraitIcon

@onready var icon: TextureRect = $Icon

func setup(enemy_trait: EnemyTrait):
	if icon == null:
		await ready

	icon.texture = enemy_trait.icon
	tooltip_text = enemy_trait.trait_name + " " + str(enemy_trait.value) + "\n" + enemy_trait.description
