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

@onready var trait_icons_container: HBoxContainer = $TraitIcons/HBoxContainer
@export var enemy_trait_icon_scene: PackedScene
var active_status_icons: Array[Sprite3D] = []
@onready var status_icons_3d: Node3D = $StatusIcons3D
@export var exposed_icon_texture: Texture2D
@export var freeze_icon_texture: Texture2D
@export var bleed_icon_texture: Texture2D
@export var shatter_particles_scene: PackedScene

@export var ui_font: Font

var status_icon_tooltips := {}
var enemy_index: int = -1
var enemy_data: EnemyData

var home_position: Vector3
var hurt_tween: Tween

signal status_hovered(text: String)
signal status_unhovered

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
	var hp_percent :float = clamp(float(enemy["hp"]) / float(enemy["max_hp"]), 0.0, 1.0)

	health_bar_fill.scale.x = hp_percent
	health_bar_fill.position.x = -(1.0 - hp_percent) * 0.16
	name_label.outline_size = 2
	name_label.outline_modulate = Color.BLACK
	intent_label.outline_size = 2
	intent_label.outline_modulate = Color.BLACK
	hp_label.outline_size = 2
	hp_label.outline_modulate = Color.BLACK
	
	apply_enemy_modulate(enemy)
	update_status_icons(data, enemy)
	
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
	
func clear_trait_icons():
	for child in trait_icons_container.get_children():
		trait_icons_container.remove_child(child)
		child.queue_free()
		
func apply_enemy_modulate(enemy: Dictionary):
	sprite.modulate = Color.WHITE

	if enemy.has("bleed") and enemy["bleed"] > 0:
		sprite.modulate = Color(1.0, 0.3, 0.3)

	if enemy.has("freeze_stacks") and enemy["freeze_stacks"] > 0:
		sprite.modulate = Color(0.55, 0.85, 1.0)
		
		
func update_status_icons(data: EnemyData, enemy: Dictionary):
	clear_status_icons()
	
	var icon_index := 0
	for enemy_trait in data.traits:
		var display_name := enemy_trait.trait_name

		if display_name == "":
			display_name = enemy_trait.trait_id.capitalize()

		add_status_icon(
			enemy_trait.icon,
			icon_index,
			display_name + " " + str(enemy_trait.value) + "\n" + enemy_trait.description,
			enemy_trait.value
		)

		icon_index += 1
	if enemy.has("bonus_traits"):
		for enemy_trait in enemy["bonus_traits"]:
			var display_name: String = enemy_trait.trait_name

			if display_name == "":
				display_name = enemy_trait.trait_id.capitalize()

			add_status_icon(
				enemy_trait.icon,
				icon_index,
				display_name + " " + str(enemy_trait.value) + "\n" + enemy_trait.description,
				enemy_trait.value
			)

			icon_index += 1
	if enemy.has("exposed") and enemy["exposed"]:
		add_status_icon(
			exposed_icon_texture,
			icon_index,
			"Exposed\nThe next hit deals +1 bonus damage.",
			1
		)
		icon_index += 1

	if enemy.has("freeze_stacks") and enemy["freeze_stacks"] > 0:
		add_status_icon(
			freeze_icon_texture,
			icon_index,
			"Freeze " + str(enemy["freeze_stacks"]) + "\nShatter damage if killed while frozen.",
			enemy["freeze_stacks"]
		)
		icon_index += 1

	if enemy.has("bleed") and enemy["bleed"] > 0:
		add_status_icon(
			bleed_icon_texture,
			icon_index,
			"Bleed " + str(enemy["bleed"]) + "\nTakes damage at end of turn, then reduces by 1.",
			enemy["bleed"]
		)
		icon_index += 1
		sprite.modulate = Color.WHITE

		

		if enemy.has("bleed") and enemy["bleed"] > 0:
			sprite.modulate = Color(1.0, 0.3, 0.3)

		if enemy.has("freeze_stacks") and enemy["freeze_stacks"] > 0:
			sprite.modulate = Color(0.55, 0.85, 1.0)
			
func add_status_icon(texture: Texture2D, index: int, tooltip: String, value: int = 0):
	if texture == null:
		return

	var icon := Sprite3D.new()
	icon.texture = texture
	icon.pixel_size = 0.009
	icon.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	icon.position = Vector3(index * 0.26, -0.08, 0)

	var value_label := Label3D.new()
	value_label.font = ui_font
	value_label.font_size = 24
	value_label.text = str(value)
	value_label.pixel_size = 0.008
	value_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	value_label.no_depth_test = true

	value_label.modulate = Color.WHITE

	value_label.outline_modulate = Color.BLACK
	value_label.outline_size = 4

	value_label.render_priority = 10
	value_label.outline_render_priority = 11

	value_label.position = Vector3(0.055, -0.055, 0.08)

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
func clear_status_icons():
	for icon in active_status_icons:
		if is_instance_valid(icon):
			icon.queue_free()

	active_status_icons.clear()
	status_icon_tooltips.clear()
	
func play_shatter_death(shatter_sound: AudioStream):
	AudioManager.play_one_shot(shatter_sound)

	sprite.modulate = Color(0.45, 0.85, 1.0)

	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color(0.8, 1.0, 1.0), 0.65)

	await get_tree().create_timer(0.75).timeout

	spawn_shatter_particles()

	sprite.visible = false

	await get_tree().create_timer(0.25).timeout
	queue_free()

func spawn_shatter_particles():
	if shatter_particles_scene == null:
		return

	var particles := shatter_particles_scene.instantiate()
	get_parent().add_child(particles)
	particles.global_position = global_position + Vector3(0, 0.8, 0)
	
	
