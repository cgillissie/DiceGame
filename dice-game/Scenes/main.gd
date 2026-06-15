extends Node

var AppID = "4832350"

var town_camera: Camera3D
var camera_tween: Tween
var hovered_building: TownBuilding = null

var town_camera_default_position: Vector3
var town_camera_default_transform: Transform3D
var town_camera_default_size: float
var selected_building: TownBuilding = null

@export var town_scene: PackedScene
@export var combat_scene: PackedScene

@onready var current_world_3d: Node3D = $CurrentWorld3D
@onready var combat = $CombatUI
@onready var fade_rect: ColorRect = $FadeRect

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

func load_world(scene: PackedScene):
	if active_world != null and is_instance_valid(active_world):
		active_world.queue_free()

	active_world = scene.instantiate()
	current_world_3d.add_child(active_world)

func load_town():
	load_world(town_scene)
	town_camera = active_world.get_node("Camera3D")
	town_camera_default_position = town_camera.position
	town_camera.current = true
	town_camera_default_transform = town_camera.global_transform
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

	var target_position := town_camera_default_position

	match building_id:
		"MerchantBuilding":
			target_position = Vector3(-3.0, 2.5, 5.0)

		"DiceSmithBuilding":
			target_position = Vector3(3.0, 2.5, 5.0)

	camera_tween = create_tween()
	camera_tween.tween_property(town_camera, "position", target_position, 0.45)
	
func check_town_hover():
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
	load_world(combat_scene)
	combat.bind_world(active_world)
	combat.set_combat_ui_enabled(true)
	combat.start_new_combat()
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

func focus_camera_anchor(anchor_name: String):
	if town_camera == null:
		return

	var anchor: Node3D = active_world.find_child(anchor_name, true, false)

	if anchor == null:
		return

	if camera_tween != null and camera_tween.is_valid():
		camera_tween.kill()

	camera_tween = create_tween()

	camera_tween.tween_property(town_camera, "global_position", anchor.global_position, 0.45)
	camera_tween.parallel().tween_property(town_camera, "global_rotation", anchor.global_rotation, 0.45)
	camera_tween.parallel().tween_property(town_camera, "size", 2.0, 0.45)
	
func reset_town_camera():
	if town_camera == null:
		return

	if camera_tween != null and camera_tween.is_valid():
		camera_tween.kill()

	camera_tween = create_tween()

	camera_tween.tween_property(
		town_camera,
		"global_position",
		town_camera_default_transform.origin,
		0.5
	)

	camera_tween.parallel().tween_property(
		town_camera,
		"global_rotation",
		town_camera_default_transform.basis.get_euler(),
		0.5
	)

	camera_tween.parallel().tween_property(
		town_camera,
		"size",
		town_camera_default_size,
		0.5
	)


func reset_town_interaction():
	if selected_building != null:
		selected_building.force_deselect()
		selected_building = null

	if hovered_building != null:
		hovered_building.force_unhover()
		hovered_building = null

	reset_town_camera()
	
