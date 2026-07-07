extends Button
class_name OwnedDieButton

@onready var die_size_label: Label = $DieSizeLabel
@onready var index_label: Label = $IndexLabel

func setup(die_data: DiceData, category_index: int, is_selected: bool = false):
	die_size_label.text = "D" + str(die_data.sides)
	index_label.text = "#" + str(category_index)

	modulate = Color.YELLOW if is_selected else Color.WHITE

func set_cursed(cursed: bool):
	if cursed:
		var style := StyleBoxFlat.new()
		style.bg_color = Color.WHITE
		style.border_width_left = 3
		style.border_width_top = 3
		style.border_width_right = 3
		style.border_width_bottom = 3
		style.border_color = Color(0.75, 0.25, 1.0)

		add_theme_stylebox_override("normal", style)

		tooltip_text = "Cursed Die\n\nThis die cannot be modified."
	else:
		remove_theme_stylebox_override("normal")
		tooltip_text = ""
