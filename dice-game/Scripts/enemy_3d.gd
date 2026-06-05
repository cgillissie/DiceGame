extends Node3D
class_name Enemy3D

signal selected(enemy_index)

@onready var sprite: AnimatedSprite3D = $AnimatedSprite3D
@onready var area: Area3D = $Area3D
@onready var name_label: Label3D = $NameLabel3D
@onready var hp_label: Label3D = $HPLabel3D
@onready var intent_label: Label3D = $IntentLabel3D
@onready var health_bar_fill: Sprite3D = $HealthBar3D/HealthBarFill

@onready var attack_icon: Sprite3D = $IntentIcons3D/AttackIcon3D
@onready var attack_value: Label3D = $IntentIcons3D/AttackValue3D
@onready var crit_icon: Sprite3D = $IntentIcons3D/CritIcon3D
@onready var crit_value: Label3D = $IntentIcons3D/CritValue3D
@onready var block_icon: Sprite3D = $IntentIcons3D/BlockIcon3D
@onready var block_value: Label3D = $IntentIcons3D/BlockValue3D
@onready var heal_icon: Sprite3D = $IntentIcons3D/HealIcon3D
@onready var heal_value: Label3D = $IntentIcons3D/HealValue3D
@onready var exposed_icon: Sprite3D = $ExposedIcon3D

var enemy_index: int = -1
var enemy_data: EnemyData

var home_position: Vector3
var hurt_tween: Tween

func _ready():
	area.input_event.connect(_on_area_input_event)
	home_position = position
	
func setup(index: int, enemy: Dictionary):
	enemy_index = index
	
	var data: EnemyData = enemy["data"]
	enemy_data = data
	if data.sprite_frames != null:
		sprite.scale = data.sprite_scale
		sprite.position = data.sprite_offset
		sprite.sprite_frames = data.sprite_frames
		sprite.play(data.idle_animation_name)
		
	
	name_label.text = data.enemy_name
	hp_label.text = str(enemy["hp"]) + "/" + str(enemy["max_hp"])
	set_intent_pair(attack_icon, attack_value, enemy["attack"])
	set_intent_pair(crit_icon, crit_value, enemy["crit"])
	set_intent_pair(block_icon, block_value, enemy["block"])
	set_intent_pair(heal_icon, heal_value, enemy["heal"])
	var hp_percent = float(enemy["hp"]) / float(enemy["max_hp"])
	health_bar_fill.scale.x = clamp(hp_percent, 0.0, 1.0)
	exposed_icon.visible = enemy["exposed"]
	
	
func _on_area_input_event(camera, event, position, normal, shape_idx):
	print("Enemy clicked area event")

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			print("Selected enemy index: ", enemy_index)
			selected.emit(enemy_index)
	
func hit_flash():
	sprite.modulate = Color.RED

	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.15)
	
func death_animation():
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3.ZERO, 0.25)
	await tween.finished
	queue_free()
	
func hurt_bump():
	if hurt_tween != null and hurt_tween.is_valid():
		hurt_tween.kill()

	position = home_position + Vector3(0.30, 0, 0)

	hurt_tween = create_tween()
	hurt_tween.tween_property(self, "position", home_position, 0.08)
	
func play_attack_animation():
	if enemy_data == null:
		return

	if sprite.sprite_frames == null:
		return

	var start_pos := position

	var tween := create_tween()
	tween.tween_property(self, "position", start_pos + Vector3(-0.35, 0, 0), 0.08)
	tween.tween_property(self, "position", start_pos, 0.12)

	if sprite.sprite_frames.has_animation(enemy_data.attack_animation):
		sprite.play(enemy_data.attack_animation)

	await get_tree().create_timer(0.30).timeout

	if sprite.sprite_frames.has_animation(enemy_data.idle_animation):
		sprite.play(enemy_data.idle_animation)

	if tween.is_valid():
		await tween.finished

func set_intent_pair(icon: Sprite3D, label: Label3D, value: int):
	var should_show := value > 0

	icon.visible = should_show
	label.visible = should_show
	label.text = str(value)
