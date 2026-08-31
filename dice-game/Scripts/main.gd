extends Node

var AppID = "4832350"

var town_camera_rig: Node3D
var town_camera: Camera3D
var town_camera_default_local_position: Vector3
var town_camera_rig_default_transform: Transform3D
var camera_tween: Tween
var hovered_building: TownBuilding = null

var combat_camera_home_transform: Transform3D
var combat_camera_home_size: float
var combat_camera_home_saved: bool = false

var town_camera_default_size: float
var selected_building: TownBuilding = null
var town_shake_strength := 0.015
var town_shake_speed := 1.5
var town_shake_time := 0.0

var town_camera_is_tweening := false
var town_camera_tween_version: int = 0

@export var town_scene: PackedScene
@export var combat_scenes: Array[PackedScene]
@export var beastmaster_combat_scene: PackedScene
@export var witch_encounter_scene: PackedScene
@export var water_well_scene: PackedScene
@export var forest_bounty_map_scene: PackedScene
@export var forest_merchant_scene: PackedScene

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
@export var witch_music: AudioStream

var active_world: Node = null
var pending_well_relic: RelicData = null

func _init():
	OS.set_environment("SteamAppID", AppID)
	OS.set_environment("SteamGameID", AppID)

func _ready():
	
	load_town()
	
	init_steam()
	combat.forest_merchant_requested.connect(start_forest_merchant_world)
	combat.request_music_change.connect(_on_request_music_change)
	combat.request_music_fade_out.connect(_on_request_music_fade_out)
	combat.town_menu_closed.connect(reset_town_interaction)
	combat.expedition_started.connect(start_expedition_world)
	combat.bounty_map_requested.connect(load_bounty_map_world)
	combat.bounty_map_camp_closed.connect(_on_bounty_map_camp_closed)
	combat.return_to_town_requested.connect(return_to_town)
	combat.beastmaster_phase_two_requested.connect(
	start_beastmaster_phase_two_world
)
	await get_tree().process_frame

	if FileAccess.file_exists(combat.RUN_SAVE_PATH):
		var loaded : bool = combat.load_run()

		if loaded and combat.expedition_active:
			await load_saved_expedition()
	await get_tree().process_frame

	if combat.is_in_town and !combat.expedition_active:
		combat.try_show_welcome_tutorial()
	music_player.bus = "Music"
	
	combat.request_music_change.connect(
		_on_request_music_change
	)

	combat.request_music_fade_out.connect(
		_on_request_music_fade_out
	)

	combat.town_menu_closed.connect(
		reset_town_interaction
	)

	combat.expedition_started.connect(
		start_expedition_world
	)

	if !combat.bounty_map_requested.is_connected(
		load_bounty_map_world
	):
		combat.bounty_map_requested.connect(
			load_bounty_map_world
		)

	combat.return_to_town_requested.connect(
		return_to_town
	)
	
	if !music_player.finished.is_connected(_on_music_finished):
		music_player.finished.connect(_on_music_finished)
	
func init_steam():
	if OS.has_feature("web"):
		print("Web build detected. Skipping Steam initialization.")
		return

	if !Engine.has_singleton("Steam"):
		print("Steam singleton is unavailable.")
		return

	var steam_api: Object = Engine.get_singleton("Steam")

	steam_api.call("steamInit")

	var is_running: bool = bool(
		steam_api.call("isSteamRunning")
	)

	if !is_running:
		print("ERROR: Steam is not running!")
		return

	print("Steam is running")

	var steam_id = steam_api.call("getSteamID")
	var username = steam_api.call(
		"getFriendPersonaName",
		steam_id
	)

	print("Username: ", str(username))

func _process(delta):
	check_town_hover()
	apply_town_camera_shake(delta)
	
func load_saved_expedition():
	await fade_to_black()

	var scene_to_load := get_combat_scene_for_current_encounter()

	if scene_to_load == null:
		push_error("No combat scene found for saved expedition.")
		await fade_from_black()
		return

	load_world(scene_to_load)

	combat.bind_world(active_world)
	combat.capture_combat_camera_home()
	combat.set_combat_ui_enabled(false)
	combat.show_expedition_camp()
	
	await play_music_fade(expedition_music.pick_random())
	await fade_from_black()
	
func load_world(scene: PackedScene):
	if scene == null:
		push_error(
			"load_world() received a null scene."
		)
		return

	clear_town_world_references()

	if active_world != null:
		if is_instance_valid(active_world):
			active_world.free()

	active_world = scene.instantiate()

	if active_world == null:
		push_error(
			"Failed to instantiate world scene."
		)
		return

	current_world_3d.add_child(
		active_world
	)

	print(
		"Loaded world scene: ",
		active_world.name
	)
	
func _on_bounty_map_camp_closed():
	if active_world is BountyMapScreen:
		(
			active_world as BountyMapScreen
		).set_map_interaction_enabled(true)
		
func clear_town_world_references():
	if camera_tween != null:
		if camera_tween.is_valid():
			camera_tween.kill()

	camera_tween = null
	town_camera_is_tweening = false

	town_camera_rig = null
	town_camera = null
	hovered_building = null
	selected_building = null
	
func start_forest_merchant_world():
	await fade_to_black()

	load_world(
		forest_merchant_scene
	)

	if active_world == null:
		push_error(
			"Failed to load forest merchant scene."
		)

		await fade_from_black()
		return

	if active_world is ForestMerchantEncounter:
		var merchant_world := (
			active_world as ForestMerchantEncounter
		)

		merchant_world.leave_requested.connect(
			_on_forest_merchant_leave_requested
		)

	combat.visible = true
	combat.open_forest_merchant()

	await fade_from_black()
	
func _on_forest_merchant_leave_requested():
	combat.close_forest_merchant_and_complete_node()
	
func get_combat_scene_for_current_encounter() -> PackedScene:
	if combat.current_encounter != null and combat.current_encounter.override_combat_scene != null:
		return combat.current_encounter.override_combat_scene

	if combat_scenes.size() > 0:
		return combat_scenes.pick_random()

	return null

func start_beastmaster_phase_two_world():
	await fade_to_black()

	if combat.boss_phase_two_encounter == null:
		push_error(
			"Beast Master Phase 2 encounter is not assigned."
		)

		await fade_from_black()
		return

	combat.current_encounter = (
		combat.boss_phase_two_encounter
	)

	var phase_two_world: PackedScene = (
		get_combat_scene_for_current_encounter()
	)

	if phase_two_world == null:
		push_error(
			"No world was found for the Beast Master "
			+ "Phase 2 encounter."
		)

		await fade_from_black()
		return

	load_world(phase_two_world)

	await get_tree().process_frame

	combat.bind_world(active_world)

	# Build the world and enemies while the screen is black.
	await combat.start_beastmaster_phase_two()

	await play_music_fade(
		combat.beastmaster_phase2_music
	)

	# Reveal the completed Phase 2 scene.
	await fade_from_black()

	# Roll only after the player can see the new world.
	await combat.begin_beastmaster_phase_two_combat()

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

	var options_overlay := combat_scene.get_node_or_null(
		"OptionsOverlay"
	)

	var tutorial_panel := combat_scene.get_node_or_null(
		"TutorialHintPanel"
	)

	return (
		(
			options_overlay != null
			and options_overlay.visible
		)
		or
		(
			tutorial_panel != null
			and tutorial_panel.visible
		)
	)
	
func check_town_hover():
	if !combat.is_in_town:
		if hovered_building != null:
			hovered_building = null

		return
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
	if !combat.is_in_town:
		return
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

func start_expedition_world(
	event_type: String = "combat"
):
	if event_type == "witch":
		combat.witch_seen_this_run = true
		combat.save_run()

		await start_witch_encounter_world()
		return

	if event_type == "well":
		combat.well_seen_this_run = true
		combat.save_run()

		await start_water_well_world()
		return

	await fade_to_black()

	await play_music_fade(
		expedition_music.pick_random()
	)

	var scene_to_load := (
		get_combat_scene_for_current_encounter()
	)

	if scene_to_load == null:
		push_error(
			"No combat scene found for current encounter."
		)

		await fade_from_black()
		return

	load_world(scene_to_load)

	combat.visible = true
	combat.bind_world(active_world)
	combat.capture_combat_camera_home()
	combat.set_combat_ui_enabled(true)

	# Set up the encounter while still black.
	await combat.prepare_new_combat()

	# Reveal the completed combat scene.
	await fade_from_black()

	# Only roll after the player can see the world.
	await combat.begin_new_combat()
	
func return_to_town():
	await fade_to_black()

	load_town()

	combat.visible = true
	combat.set_combat_ui_enabled(false)

	await fade_from_black()

	combat.show_pending_endless_choice()

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
	
func focus_camera_anchor(
	anchor_name: String
):
	if town_camera == null:
		return

	if town_camera_rig == null:
		return

	var anchor: Node3D = active_world.find_child(
		anchor_name,
		true,
		false
	)

	if anchor == null:
		push_warning(
			"Could not find town camera anchor: "
			+ anchor_name
		)
		return

	# This becomes the newest camera request.
	town_camera_tween_version += 1
	var request_version: int = town_camera_tween_version

	# Interrupt any zoom-in or zoom-out currently running.
	if camera_tween != null:
		if camera_tween.is_valid():
			camera_tween.kill()

	town_camera_is_tweening = true

	if camera_zoom_sound != null:
		AudioManager.play_one_shot(
			camera_zoom_sound
		)

	camera_tween = create_tween()
	camera_tween.set_parallel(true)
	camera_tween.set_trans(Tween.TRANS_QUAD)
	camera_tween.set_ease(Tween.EASE_IN_OUT)

	camera_tween.tween_property(
		town_camera_rig,
		"global_transform",
		anchor.global_transform,
		0.5
	)

	camera_tween.tween_property(
		town_camera,
		"size",
		2.0,
		0.5
	)

	await camera_tween.finished

	# An older interrupted request must not change the state
	# belonging to a newer camera tween.
	if request_version != town_camera_tween_version:
		return

	town_camera_is_tweening = false
	camera_tween = null
	
func reset_town_camera():
	if town_camera == null:
		return

	if town_camera_rig == null:
		return

	town_camera_tween_version += 1
	var request_version: int = town_camera_tween_version

	if camera_tween != null:
		if camera_tween.is_valid():
			camera_tween.kill()

	town_camera_is_tweening = true

	if camera_zoom_sound != null:
		AudioManager.play_one_shot(
			camera_zoom_sound
		)

	camera_tween = create_tween()
	camera_tween.set_parallel(true)
	camera_tween.set_trans(Tween.TRANS_QUAD)
	camera_tween.set_ease(Tween.EASE_IN_OUT)

	camera_tween.tween_property(
		town_camera_rig,
		"global_transform",
		town_camera_rig_default_transform,
		0.5
	)

	camera_tween.tween_property(
		town_camera,
		"size",
		town_camera_default_size,
		0.5
	)

	await camera_tween.finished

	if request_version != town_camera_tween_version:
		return

	# Force exact final values to avoid accumulated drift.
	town_camera_rig.global_transform = (
		town_camera_rig_default_transform
	)

	town_camera.size = town_camera_default_size

	town_camera_is_tweening = false
	camera_tween = null

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

func start_witch_encounter_world():
	await fade_to_black()
	await play_music_fade(witch_music)
	load_world(witch_encounter_scene)

	combat.hide_all_major_panels()
	combat.visible = false

	if active_world.has_signal("witch_choice_made"):
		active_world.witch_choice_made.connect(_on_witch_choice_made)

	await fade_from_black()

func _on_witch_choice_made(accepted: bool):
	var awarded_relic: RelicData = null

	if accepted:
		awarded_relic = combat.accept_witch_offer()
	else:
		combat.ignore_witch_offer()

	if awarded_relic != null:
		combat.visible = true
		await combat.show_relic_acquisition(awarded_relic)

	await fade_to_black()

	combat.visible = true

	await play_music_fade(expedition_music.pick_random())

	var scene_to_load := get_combat_scene_for_current_encounter()

	if scene_to_load == null:
		push_error("No combat scene found after Witch encounter.")
		await fade_from_black()
		return

	load_world(scene_to_load)
	combat.bind_world(active_world)
	combat.capture_combat_camera_home()
	combat.set_combat_ui_enabled(false)
	combat.show_expedition_camp()
	combat.expedition_progress += 1
	combat.save_run()

	await fade_from_black()
	
func start_water_well_world():
	await fade_to_black()
	await fade_audio_out(music_player, 0.75)

	load_world(water_well_scene)

	combat.hide_all_major_panels()
	combat.visible = false

	if active_world.has_signal("well_choice_made"):
		active_world.well_choice_made.connect(_on_well_choice_made)

	await fade_from_black()
	
func _on_well_choice_made(pulled_bucket: bool):
	if !pulled_bucket:
		await finish_water_well_event()
		return

	var relic: RelicData = combat.claim_well_relic()

	if relic == null:
		print("The Well had no available relic.")
		await finish_water_well_event()
		return

	# CombatUI was hidden while displaying the Well world.
	# Make it visible so its RelicRewardOverlay can appear.
	combat.visible = true

	await combat.show_relic_acquisition(relic)

	await finish_water_well_event()

	
func _on_well_reward_acknowledged():
	await animate_well_relic_to_ui()
	await finish_water_well_event()
	
func animate_well_relic_to_ui():
	if pending_well_relic == null:
		return

	var target: Control = combat.relic_container

	if target == null:
		return

	var flying_icon := TextureRect.new()
	flying_icon.texture = pending_well_relic.icon
	flying_icon.custom_minimum_size = Vector2(160, 160)
	flying_icon.size = Vector2(160, 160)
	flying_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	flying_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	flying_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flying_icon.z_index = 500

	add_child(flying_icon)

	var viewport_size := get_viewport().get_visible_rect().size
	flying_icon.global_position = viewport_size * 0.5 - flying_icon.size * 0.5

	combat.visible = true
	combat.update_active_food_icons()

	await get_tree().process_frame

	var target_position := target.global_position + target.size * 0.5
	target_position -= flying_icon.size * 0.5

	var tween := create_tween()
	tween.set_parallel(true)

	tween.tween_property(
		flying_icon,
		"global_position",
		target_position,
		0.65
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(
		flying_icon,
		"scale",
		Vector2(0.25, 0.25),
		0.65
	)

	tween.tween_property(
		flying_icon,
		"modulate:a",
		0.0,
		0.65
	)

	await tween.finished
	flying_icon.queue_free()
	
func finish_water_well_event():
	await fade_to_black()

	combat.visible = true
	pending_well_relic = null

	await play_music_fade(expedition_music.pick_random())

	var scene_to_load := get_combat_scene_for_current_encounter()

	if scene_to_load == null:
		push_error("No combat scene found after Well encounter.")
		await fade_from_black()
		return

	load_world(scene_to_load)
	combat.bind_world(active_world)
	combat.capture_combat_camera_home()
	combat.set_combat_ui_enabled(false)
	combat.show_expedition_camp()

	combat.expedition_progress += 1
	combat.save_run()

	await fade_from_black()
	
func _on_request_music_fade_out():
	await fade_audio_out(music_player, 1.0)

func _on_request_music_change(track: AudioStream):
	await play_music_fade(track)

	
func load_bounty_map_world(
	map_data: BountyMapData,
	bounty_name: String
):
	print(
		"STEP 5: main.gd received bounty-map request."
	)

	if map_data == null:
		push_error(
			"load_bounty_map_world received null map data."
		)

		combat.is_in_town = true
		combat.visible = true
		return

	if forest_bounty_map_scene == null:
		push_error(
			"Forest Bounty Map Scene is not assigned "
			+ "on the Main node."
		)

		combat.is_in_town = true
		combat.visible = true
		return

	await fade_to_black()

	print("STEP 6: Loading forest map world.")

	combat.hide_all_major_panels()
	combat.set_combat_ui_enabled(false)
	combat.visible = false

	load_world(
		forest_bounty_map_scene
	)

	if active_world == null:
		push_error(
			"Forest bounty map failed to instantiate."
		)

		combat.visible = true
		combat.is_in_town = true
		await fade_from_black()
		return

	if !(active_world is BountyMapScreen):
		push_error(
			"ForestBountyMap root does not have "
			+ "bounty_map_screen.gd attached."
		)

		combat.visible = true
		combat.is_in_town = true
		await fade_from_black()
		return

	var map_screen := (
		active_world as BountyMapScreen
	)

	map_screen.setup(
		map_data,
		bounty_name
	)

	if !map_screen.node_selected.is_connected(
		_on_bounty_map_node_selected
	):
		map_screen.node_selected.connect(
			_on_bounty_map_node_selected
		)
		map_screen.camp_requested.connect(
			_on_bounty_map_camp_requested
		)
	print("STEP 7: Forest bounty map loaded.")

	await fade_from_black()
	
func _on_bounty_map_node_selected(
	node_id: int
):
	if combat == null:
		return

	# Do not manually unload the map here.
	# The next world loader will replace it.
	combat.select_bounty_map_node(
		node_id
	)
	
func _on_bounty_map_camp_requested():
	if combat == null:
		return

	if active_world is BountyMapScreen:
		(
			active_world as BountyMapScreen
		).set_map_interaction_enabled(false)

	combat.visible = true
	combat.open_expedition_camp_from_map()
