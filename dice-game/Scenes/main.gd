extends Node

var AppID = "4832350"

var town_camera: Camera3D
var camera_tween: Tween
var hovered_building: TownBuilding = null

@export var town_scene: PackedScene
@export var combat_scene: PackedScene

@onready var current_world_3d: Node3D = $CurrentWorld3D
@onready var combat = $CombatUI

var active_world: Node3D = null

func _init():
	OS.set_environment("SteamAppID", AppID)
	OS.set_environment("SteamGameID", AppID)

func _ready():
	load_town()
	init_steam()

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
	town_camera.current = true
	
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
		"merchant":
			focus_town_camera("MerchantBuilding")
			combat.open_merchant()

		"cookfire":
			focus_town_camera("CookfireBuilding")
			combat.open_food_crafting_from_town()

		"dice_smith":
			focus_town_camera("DiceSmithBuilding")
			combat.open_edit_dice_panel_from_town()

		"bounty_board":
			focus_town_camera("TownHallBuilding")
			combat.open_bounty_board()

func focus_town_camera(target_name: String):
	if town_camera == null:
		return

	var target: Node3D = active_world.find_child(target_name, true, false)

	if target == null:
		return

	if camera_tween != null and camera_tween.is_valid():
		camera_tween.kill()

	camera_tween = create_tween()

	var target_pos := town_camera.position

	match target_name:
		"MerchantBuilding":
			target_pos = Vector3(-3.0, 3.0, 6.0)

		"DiceSmithBuilding":
			target_pos = Vector3(3.0, 3.0, 6.0)

		"CookfireBuilding":
			target_pos = Vector3(0.0, 2.5, 5.0)

		"TownHallBuilding":
			target_pos = Vector3(0.0, 4.0, 7.0)

	camera_tween.tween_property(town_camera, "position", target_pos, 0.45)
	
func check_town_hover():
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
			
func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if hovered_building != null:
				hovered_building.force_select()
				_on_town_building_clicked(hovered_building.building_id)
