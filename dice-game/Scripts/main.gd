extends Node

var AppID = "4832350"

var town_camera_rig: Node3D
var town_camera: Camera3D
var town_camera_default_local_position: Vector3
var town_camera_rig_default_transform: Transform3D
var camera_tween: Tween
var hovered_building: TownBuilding = null


var town_camera_default_size: float
var selected_building: TownBuilding = null
var town_shake_strength := 0.015
var town_shake_speed := 1.5
var town_shake_time := 0.0

var town_camera_is_tweening := false


@export var town_scene: PackedScene
@export var combat_scene: PackedScene

@export var camera_zoom_sound: AudioStream
@export var critical_hit_sound: AudioStream
@export var critical_roll_sound: AudioStream
@export var food_eat_sound: AudioStream
@export var dice_smith_crafting_sound: AudioStream
@export var graft_face_sound: AudioStream
@export var dice_smith_anvil_sound: AudioStream

@onready var current_world_3d: Node3D = $CurrentWorld3D
@onready var combat = $CombatUI
@onready var fade_rect: ColorRect = $FadeRect
@onready var music_player: AudioStreamPlayer = $MusicPlayer

@export var town_music: AudioStream
@export var boss_music: AudioStream
@export var expedition_music: Array[AudioStream]

var active_world: Node3D = null

func _init():
	OS.set_environment("SteamAppID", AppID)
	OS.set_environment("SteamGameID", AppID)

func _ready():
	

	load_town()
	init_steam()
	
	
	combat.town_menu_closed.connect(reset_town_interaction)
	combat.expedition_started.connect(start_expedition_world)
	combat.return_to_town_requested.connect(return_to_town)
	music_player.bus = "Music"

	if !music_player.finished.is_connected(_on_music_finished):
		music_player.finished.connect(_on_music_finished)
	
func init_steam():
	Steam.steamInit()
	var isRunning = Steam.isSteamRunning()

	if !isRunning:
		print("ERROR: Steam is not running!")
		return

	print("Steam is running")

	var id = Steam.getSteamID()
	var name = Steam.getFriendPersonaName(id)
	print("Username: ", str(name))

func _process(delta):
	check_town_hover()
	apply_town_camera_shake(delta)
	
func load_world(scene: PackedScene):
	if active_world != null and is_instance_valid(active_world):
		active_world.queue_free()

	active_world = scene.instantiate()
	current_world_3d.add_child(active_world)
	
func play_music(track: AudioStream):
	if track == null:
		return

	if music_player.stream == track and music_player.playing:
		return

	music_player.stream = track
	music_player.play()
	
func _on_music_finished():
	if music_player == null:
		return

	if music_player.stream == null:
		return

	music_player.play()
	
func apply_town_camera_shake(delta):
	if town_camera == null:
		return

	if town_camera_is_tweening:
		return

	town_shake_time += delta * town_shake_speed

	var offset := Vector3(
		sin(town_shake_time * 1.7),
		cos(town_shake_time * 1.3),
		0.0
	) * get_current_town_shake_strength()

	town_camera.position = town_camera_default_local_position + offset
	
func get_current_town_shake_strength() -> float:
	if town_camera == null:
		return town_shake_strength

	var zoom_ratio := town_camera.size / town_camera_default_size

	return town_shake_strength * zoom_ratio * 0.5
	
func load_town():
	load_world(town_scene)

	town_camera_rig = active_world.find_child("TownCameraRig", true, false)
	town_camera = active_world.find_child("Camera3D", true, false)

	if town_camera_rig == null:
		push_error("Town scene is missing TownCameraRig.")
		return

	if town_camera == null:
		push_error("Town scene is missing Camera3D.")
		return

	town_camera.current = true

	town_camera_default_local_position = town_camera.position
	town_camera_rig_default_transform = town_camera_rig.global_transform
	town_camera_default_size = town_camera.size

	var merchant: TownBuilding = active_world.find_child("MerchantBuilding", true, false)
	var cookfire: TownBuilding = active_world.find_child("CookfireBuilding", true, false)
	var dice_smith: TownBuilding = active_world.find_child("DiceSmithBuilding", true, false)
	var bounty_board: TownBuilding = active_world.find_child("TownHallBuilding", true, false)

	if merchant == null or cookfire == null or dice_smith == null or bounty_board == null:
		print("Missing town building node.")
		print("Merchant: ", merchant)
		print("Cookfire: ", cookfire)
		print("DiceSmith: ", dice_smith)
		print("TownHall: ", bounty_board)
		return

	merchant.building_clicked.connect(_on_town_building_clicked)
	cookfire.building_clicked.connect(_on_town_building_clicked)
	dice_smith.building_clicked.connect(_on_town_building_clicked)
	bounty_board.building_clicked.connect(_on_town_building_clicked)

	await get_tree().process_frame

	combat.set_combat_ui_enabled(false)

	await play_music_fade(town_music)
	
func _on_town_building_clicked(building_id: String):
	match building_id:
		"MerchantBuilding", "merchant":
			focus_camera_anchor("MerchantCameraAnchor")
			combat.open_merchant()

		"DiceSmithBuilding", "dice_smith":
			focus_camera_anchor("DiceSmithCameraAnchor")
			combat.open_edit_dice_panel_from_town()

		"CookfireBuilding", "cookfire":
			focus_camera_anchor("CookfireCameraAnchor")
			combat.open_food_crafting_from_town()

		"TownHallBuilding", "bounty_board":
			focus_camera_anchor("TownHallCameraAnchor")
			combat.open_bounty_board()
			
func focus_town_camera(building_id: String):
	if town_camera == null:
		return

	if camera_tween != null and camera_tween.is_valid():
		camera_tween.kill()

	var target_position := town_camera_default_local_position

	match building_id:
		"MerchantBuilding":
			target_position = Vector3(-3.0, 2.5, 5.0)

		"DiceSmithBuilding":
			target_position = Vector3(3.0, 2.5, 5.0)

	camera_tween = create_tween()
	camera_tween.tween_property(town_camera, "position", target_position, 0.45)
	
func is_menu_blocking_input() -> bool:
	var combat_scene := get_node_or_null("CombatUI")
	if combat_scene == null:
		return false

	var options_overlay := combat_scene.get_node_or_null("OptionsOverlay")
	return options_overlay != null and options_overlay.visible
	
func check_town_hover():
	if is_menu_blocking_input():
		return
	if town_menu_is_open():
		if hovered_building != null:
			hovered_building.force_unhover()
			hovered_building = null
		return

	if town_camera == null:
		return

	var mouse_pos := get_viewport().get_mouse_position()
	var from := town_camera.project_ray_origin(mouse_pos)
	var to := from + town_camera.project_ray_normal(mouse_pos) * 1000.0

	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = true
	query.collide_with_bodies = false

	var result := get_viewport().world_3d.direct_space_state.intersect_ray(query)

	var found_building: TownBuilding = null

	if !result.is_empty():
		var collider = result["collider"]

		if collider is TownBuilding:
			found_building = collider

	if found_building != hovered_building:
		if hovered_building != null:
			hovered_building.force_unhover()

		hovered_building = found_building

		if hovered_building != null:
			hovered_building.force_hover()
			
func _input(event):
	if is_menu_blocking_input():
		return

	if town_menu_is_open():
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if hovered_building != null:
				print("Town clicked: ", hovered_building.building_id)

				selected_building = hovered_building
				selected_building.force_select()

				_on_town_building_clicked(selected_building.building_id)

func town_menu_is_open() -> bool:
	return combat.merchant_panel.visible \
		or combat.food_craft_panel.visible \
		or combat.edit_dice_panel.visible \
		or combat.bounty_board_panel.visible \
		or combat.prepare_expedition_panel.visible

func start_expedition_world():
	await fade_to_black()
	await play_music_fade(
	expedition_music.pick_random()
)

	load_world(combat_scene)
	combat.bind_world(active_world)
	combat.set_combat_ui_enabled(true)
	combat.start_expedition()
	
	await fade_from_black()
	
func return_to_town():
	await fade_to_black()
	load_town()
	combat.set_combat_ui_enabled(false)
	await fade_from_black()

func fade_to_black():
	fade_rect.visible = true
	var tween := create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, 0.35)
	await tween.finished

func fade_from_black():
	var tween := create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, 0.35)
	await tween.finished
	fade_rect.visible = false
func play_music_fade(track: AudioStream):
	if track == null:
		return

	if music_player.stream == track and music_player.playing:
		return

	if music_player.playing:
		var out := create_tween()
		out.tween_property(music_player, "volume_db", -40.0, 0.5)
		await out.finished

	music_player.stop()
	music_player.stream = track
	music_player.volume_db = -40.0
	music_player.play()

	var fade := create_tween()
	fade.tween_property(music_player, "volume_db", 0.0, 0.5)
	await fade.finished
	
func focus_camera_anchor(anchor_name: String):
	if town_camera == null:
		return

	if town_camera_rig == null:
		return

	if town_camera_is_tweening:
		return

	var anchor: Node3D = active_world.find_child(anchor_name, true, false)

	if anchor == null:
		return

	if camera_tween != null and camera_tween.is_valid():
		camera_tween.kill()

	town_camera_is_tweening = true
	AudioManager.play_one_shot(camera_zoom_sound)

	camera_tween = create_tween()

	camera_tween.tween_property(
		town_camera_rig,
		"global_transform",
		anchor.global_transform,
		0.5
	)

	camera_tween.parallel().tween_property(
		town_camera,
		"size",
		2.0,
		0.5
	)

	await camera_tween.finished

	town_camera_is_tweening = false
	
func reset_town_camera():
	if town_camera == null:
		return

	if camera_tween != null and camera_tween.is_valid():
		camera_tween.kill()

	town_camera_is_tweening = true

	AudioManager.play_one_shot(camera_zoom_sound)

	camera_tween = create_tween()

	camera_tween.tween_property(
		town_camera_rig,
		"global_transform",
		town_camera_rig_default_transform,
		0.5
	)

	camera_tween.parallel().tween_property(
		town_camera,
		"size",
		town_camera_default_size,
		0.5
	)

	await camera_tween.finished

	town_camera_is_tweening = false

func reset_town_interaction():
	if selected_building != null:
		selected_building.force_deselect()
		selected_building = null

	if hovered_building != null:
		hovered_building.force_unhover()
		hovered_building = null

	reset_town_camera()
	
func fade_audio_out(player: AudioStreamPlayer, duration: float = 0.5):
	if player == null or !player.playing:
		return

	var tween := create_tween()
	tween.tween_property(player, "volume_db", -40.0, duration)
	await tween.finished
	player.stop()
	player.volume_db = 0.0
	
func fade_audio_in(player: AudioStreamPlayer, duration: float = 0.5):
	if player == null:
		return

	player.volume_db = -40.0
	player.play()

	var tween := create_tween()
	tween.tween_property(player, "volume_db", 0.0, duration)
	await tween.finished
