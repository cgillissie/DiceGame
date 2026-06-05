extends Node3D
class_name Player3D

@onready var sprite: AnimatedSprite3D = $AnimatedSprite3D
@onready var hp_label: Label3D = $HPLabel3D
@onready var block_value: Label3D = $BlockValue3D
@onready var incoming_label: Label3D = $IncomingLabel3D

@onready var block_icon: Sprite3D = $BlockIcon3D
@onready var popup_anchor: Node3D = $PopupAnchor

var character_data: PlayerCharacterData

func setup(player_hp: int, max_player_hp: int, block: int, incoming: int):
	
	hp_label.text = str(player_hp) + "/" + str(max_player_hp)
	block_value.text = str(block)
	incoming_label.text = "I" + str(incoming)

	block_icon.visible = block > 0
	block_value.visible = block > 0

func hit_flash():
	sprite.modulate = Color.RED

	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.15)
	
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
