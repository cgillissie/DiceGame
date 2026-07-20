extends Button
class_name OwnedDieButton

@onready var die_size_label: Label = $DieSizeLabel
@onready var index_label: Label = $IndexLabel
@onready var exploding_glow: TextureRect = $ExplodingGlow

var die_data: DiceData = null
var exploding_glow_tween: Tween = null
var is_cursed: bool = false


func setup(
	new_die_data: DiceData,
	category_index: int,
	is_selected: bool = false
):
	die_data = new_die_data

	if die_data == null:
		die_size_label.text = "D?"
		index_label.text = "#" + str(category_index)
		exploding_glow.visible = false
		tooltip_text = ""
		return

	die_size_label.text = "D" + str(die_data.sides)
	index_label.text = "#" + str(category_index)

	modulate = (
		Color.YELLOW
		if is_selected
		else Color.WHITE
	)

	exploding_glow.set_anchors_preset(
		Control.PRESET_FULL_RECT
	)

	exploding_glow.offset_left = -14.0
	exploding_glow.offset_top = -14.0
	exploding_glow.offset_right = 14.0
	exploding_glow.offset_bottom = 14.0
	exploding_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	exploding_glow.show_behind_parent = false
	exploding_glow.z_index = 1

	die_size_label.z_index = 2
	index_label.z_index = 2

	update_exploding_visual()
	update_die_tooltip()


func set_cursed(cursed: bool):
	is_cursed = cursed

	if cursed:
		var style := StyleBoxFlat.new()
		style.bg_color = Color.WHITE

		style.border_width_left = 3
		style.border_width_top = 3
		style.border_width_right = 3
		style.border_width_bottom = 3

		style.border_color = Color(
			0.75,
			0.25,
			1.0
		)

		add_theme_stylebox_override(
			"normal",
			style
		)
	else:
		remove_theme_stylebox_override(
			"normal"
		)

	update_die_tooltip()


func update_exploding_visual():
	if exploding_glow == null:
		print("ExplodingGlow node is null.")
		return

	var is_exploding: bool = (
		die_data != null
		and die_data.can_explode
	)

	print(
		"Owned die: ",
		die_data.die_name if die_data != null else "NULL",
		" can_explode=",
		is_exploding
	)

	exploding_glow.visible = is_exploding

	if !is_exploding:
		stop_exploding_glow()
		return

	start_exploding_glow()


func start_exploding_glow():
	if exploding_glow_tween != null:
		if exploding_glow_tween.is_valid():
			exploding_glow_tween.kill()

	exploding_glow.modulate.a = 0.55

	exploding_glow_tween = create_tween()
	exploding_glow_tween.set_loops()
	exploding_glow_tween.set_trans(
		Tween.TRANS_SINE
	)
	exploding_glow_tween.set_ease(
		Tween.EASE_IN_OUT
	)

	exploding_glow_tween.tween_property(
		exploding_glow,
		"modulate:a",
		1.0,
		0.7
	)

	exploding_glow_tween.tween_property(
		exploding_glow,
		"modulate:a",
		0.55,
		0.7
	)


func stop_exploding_glow():
	if exploding_glow_tween != null:
		if exploding_glow_tween.is_valid():
			exploding_glow_tween.kill()

	exploding_glow_tween = null

	if exploding_glow != null:
		exploding_glow.modulate.a = 0.85


func update_die_tooltip():
	tooltip_text = build_die_tooltip()


func build_die_tooltip() -> String:
	if die_data == null:
		return ""

	var tooltip: String = (
		die_data.die_name
		+ "\nD"
		+ str(die_data.sides)
	)

	if die_data.can_explode:
		tooltip += (
			"\n\nExploding\n"
			+ "Landing on the final face creates "
			+ "and rolls a temporary copy of this die."
		)

	if is_cursed:
		tooltip += (
			"\n\nCursed Die\n"
			+ "This die cannot be modified."
		)

	return tooltip
