extends Node3D
class_name Player3D

@onready var sprite: AnimatedSprite3D = $AnimatedSprite3D
@onready var hp_label: Label3D = $HPLabel3D
@onready var block_icon: Sprite3D = $BlockIcon3D
@onready var block_value: Label3D = $BlockValue3D
@onready var incoming_label: Label3D = $IncomingLabel3D
@onready var status_icons_3d: Node3D = $StatusIcons3D
@onready var popup_anchor: Node3D = $PopupAnchor

var active_status_icons: Array[Sprite3D] = []
var character_data: PlayerCharacterData
var is_bleeding := false
	
	
func setup(player_hp: int, max_player_hp: int, block: int, incoming: int):
	block_icon.visible = block > 0
	block_value.visible = block > 0
	block_value.text = str(block)

	incoming_label.visible = incoming > 0
	incoming_label.text = str(incoming)
	
func set_character_data(data: PlayerCharacterData):
	character_data = data

	if character_data == null:
		return

	sprite.sprite_frames = character_data.sprite_frames
	sprite.scale = character_data.sprite_scale
	sprite.position = character_data.sprite_offset

	print(sprite.sprite_frames.get_animation_names())

	sprite.play(character_data.idle_animation)
	
	print("Idle exists: ", sprite.sprite_frames.has_animation("idle"))
	print("Idle speed: ", sprite.sprite_frames.get_animation_speed("idle"))
	print("Idle frames: ", sprite.sprite_frames.get_frame_count("idle"))
	
func play_attack_animation():
	if character_data == null:
		return

	var start_pos := position

	var tween := create_tween()
	tween.tween_property(self, "position", start_pos + Vector3(0.35, 0, 0), 0.08)
	tween.tween_property(self, "position", start_pos, 0.12)

	sprite.play(character_data.attack_animation)

	await get_tree().create_timer(0.30).timeout

	sprite.play(character_data.idle_animation)

	if tween.is_valid():
		await tween.finished
		
func get_popup_position() -> Vector3:
	return popup_anchor.global_position

func hurt_bump():
	var start_pos := position

	position = start_pos + Vector3(-0.30, 0, 0)

	var tween := create_tween()
	tween.tween_property(self, "position", start_pos, 0.08)
	
func set_bleeding(active: bool):
	is_bleeding = active
	_apply_status_tint()

func _apply_status_tint():
	if is_bleeding:
		sprite.modulate = Color(1.0, 0.35, 0.35)
	else:
		sprite.modulate = Color.WHITE

func hit_flash():
	sprite.modulate = Color.RED

	var tween := create_tween()
	tween.tween_callback(_apply_status_tint).set_delay(0.15)

func clear_status_icons():
	for icon in active_status_icons:
		if is_instance_valid(icon):
			icon.queue_free()

	active_status_icons.clear()


func update_status_icons(
	bleed_texture: Texture2D,
	bleed_value: int,
	regenerating_texture: Texture2D,
	regenerating_value: int
):
	clear_status_icons()

	var icon_index := 0

	if bleed_value > 0:
		add_status_icon(
			bleed_texture,
			icon_index,
			"Bleed " + str(bleed_value) + "\nTake damage at end of round, then Bleed reduces by 1.",
			bleed_value
		)
		icon_index += 1

	if regenerating_value > 0:
		add_status_icon(
			regenerating_texture,
			icon_index,
			"Regenerating " + str(regenerating_value) + "\nHeal at the end of each round.",
			regenerating_value
		)
		icon_index += 1


func add_status_icon(texture: Texture2D, index: int, tooltip: String, value: int = 0):
	if texture == null:
		return

	var icon := Sprite3D.new()
	icon.texture = texture
	icon.pixel_size = 0.0055
	icon.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	icon.no_depth_test = true
	icon.render_priority = 0
	icon.position = Vector3(index * 0.18, 0.05, 0)

	var value_label := Label3D.new()
	value_label.text = str(value)
	value_label.pixel_size = 0.0045
	value_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	value_label.no_depth_test = true
	value_label.modulate = Color.WHITE
	value_label.outline_modulate = Color.BLACK
	value_label.outline_size = 4
	value_label.render_priority = 10
	value_label.outline_render_priority = 11
	value_label.position = Vector3(0.04, -0.04, 0.08)

	if hp_label.font != null:
		value_label.font = hp_label.font

	if value <= 0:
		value_label.visible = false

	icon.add_child(value_label)

	var area := Area3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()

	box.size = Vector3(0.18, 0.18, 0.02)
	shape.shape = box

	area.add_child(shape)
	area.collision_layer = 4
	area.collision_mask = 0
	area.input_ray_pickable = true
	area.set_meta("status_tooltip", tooltip)

	icon.add_child(area)

	status_icons_3d.add_child(icon)
	active_status_icons.append(icon)
