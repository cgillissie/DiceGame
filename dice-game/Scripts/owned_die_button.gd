extends Button
class_name OwnedDieButton

@onready var die_size_label: Label = $DieSizeLabel
@onready var index_label: Label = $IndexLabel

func setup(die_data: DiceData, category_index: int, is_selected: bool = false):
	die_size_label.text = "D" + str(die_data.sides)
	index_label.text = "#" + str(category_index)

	modulate = Color.YELLOW if is_selected else Color.WHITE
