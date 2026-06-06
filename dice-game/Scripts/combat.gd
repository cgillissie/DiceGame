extends Control


@export var dice_scene: PackedScene
@export var starting_dice: Array[DiceData]
@export var enemy_3d_scene: PackedScene
@export var inventory_face_button_scene: PackedScene

var enemy_3d_nodes: Array[Enemy3D] = []

var reserve_slots: int = 2
var damage_by_enemy := {}
var crit_by_enemy := {}
var combat_log_entries: Array[String] = []


@export var player_character_data: PlayerCharacterData

@onready var combat_camera: Camera3D = $"../World3D/Camera3D"
var camera_original_position: Vector3
@onready var enemy_positions: Node3D = $"../World3D/EnemyPositions"

@onready var actions_button: Button = $DiceArea/CenterContainer/DiceGroupsContainer/ActionsGroup/ActionsButton
@onready var hits_button: Button = $DiceArea/CenterContainer/DiceGroupsContainer/HitsGroup/HitsButton
@onready var crits_button: Button = $DiceArea/CenterContainer/DiceGroupsContainer/CritsGroup/CritsButton
@onready var blocks_button: Button = $LeftMarginContainer/VBoxContainer/BlocksGroup/BlocksButton
@onready var gold_button: Button = $LeftMarginContainer/VBoxContainer/GoldGroup/GoldButton
@onready var healing_button: Button = $LeftMarginContainer/VBoxContainer/HealingGroup/HealingButton
@onready var misses_button: Button = $DiceArea/CenterContainer/DiceGroupsContainer/MissesGroup/MissesButton
@onready var actions_container: GridContainer = $DiceArea/CenterContainer/DiceGroupsContainer/ActionsGroup/ActionsDiceContainer
@onready var hits_container: GridContainer = $DiceArea/CenterContainer/DiceGroupsContainer/HitsGroup/HitsDiceContainer
@onready var crits_container: GridContainer = $DiceArea/CenterContainer/DiceGroupsContainer/CritsGroup/CritsDiceContainer
@onready var blocks_container: GridContainer = $LeftMarginContainer/VBoxContainer/BlocksGroup/BlocksDiceContainer
@onready var gold_container: GridContainer = $LeftMarginContainer/VBoxContainer/GoldGroup/GoldDiceContainer
@onready var healing_container: GridContainer = $LeftMarginContainer/VBoxContainer/HealingGroup/HealingDiceContainer
@onready var misses_container: GridContainer = $DiceArea/CenterContainer/DiceGroupsContainer/MissesGroup/MissesDiceContainer
@onready var defeat_label: Label = $TopMarginContainer/CenterContainer/VBoxContainer/DefeatLabel
@onready var player_hp_label: Label = $LeftMarginContainer/VBoxContainer/PlayerHPLabel
@onready var end_round_button: Button = $TopMarginContainer/CenterContainer/VBoxContainer/EndRoundButton
@export var enemy_dice: Array[DiceData]
@onready var combat_log_label: Label = $LeftMarginContainer/VBoxContainer/CombatLogLabel
@onready var combat_number_label: Label = $TopMarginContainer/CenterContainer/VBoxContainer/CombatNumberLabel
@onready var gold_label: Label = $ShopPanel/VBoxContainer/GoldLabel
@onready var enemy_buttons_container: VBoxContainer = $RightMarginContainer/VBoxContainer/EnemyButtonsContainer

@export var player_3d_scene: PackedScene
@onready var player_position: Node3D = $"../World3D/Player3D/PlayerPosition"

var player_3d_node: Player3D = null

#Roll animation area
@onready var roll_animation_area: CenterContainer = $RollAnimationArea
@onready var rolling_hidden_area: Control = $RollingHiddenArea
var is_rolling_dice: bool = false

@onready var assigned_dice_overlay: Control = $AssignedDiceOverlay
@onready var enemy_roll_overlay: Control = $EnemyRollOverlay
var enemy_roll_preview_panel: Control = null

@onready var player_block_label: Label = $LeftMarginContainer/VBoxContainer/PlayerBlockLabel
@onready var incoming_damage_label: Label = $LeftMarginContainer/VBoxContainer/IncomingDamageLabel
@onready var reserve_slots_label: Label = $LeftMarginContainer/VBoxContainer/ReserveSlotsLabel

# AUTO WIN BUTTON FOR TESTING
@onready var debug_win_button: Button = $DebugWinButton
@onready var debug_gold_button: Button = $DebugGoldButton

@export var hit_2_face: DiceFace

var combat_max_player_hp: int = 30
var face_inventory: Array[DiceFace] = []
var face_cost: int = 8

@export var basic_d6: DiceData

# Encounter
@export var encounter_pool: Array[EncounterData]
var current_encounter: EncounterData
var active_enemies: Array = []
var defeated_enemies: Array[EnemyData]
var selected_enemy_index: int = -1
var assigned_enemy_containers: Array[GridContainer] = []

@export var damage_popup_scene: PackedScene

# Enemy loot drops
@export var enemy_face_drop_pool: Array[DiceFace]
var dropped_face: DiceFace

# Reward panel and choices
@onready var shop_panel: Panel = $ShopPanel
@onready var buy_random_die_button: Button = $ShopPanel/VBoxContainer/ItemGrid/BuyD6Button
@onready var buy_face_button: Button = $ShopPanel/VBoxContainer/ItemGrid/BuyFaceButton
@onready var buy_reserve_slot_button: Button = $ShopPanel/VBoxContainer/ItemGrid/BuyReserveSlotButton
@onready var buy_heal_button: Button = $ShopPanel/VBoxContainer/ItemGrid/BuyHealButton
@onready var next_fight_button: Button = $ShopPanel/VBoxContainer/NextFightButton
@export var random_die_pool: Array[DiceData]

@onready var restart_run_button: Button = $TopMarginContainer/CenterContainer/VBoxContainer/RestartRunButton

# Dice Editing panel
@onready var edit_dice_button: Button = $ShopPanel/VBoxContainer/EditDiceButton
@onready var edit_dice_panel: Panel = $EditDicePanel
@onready var die_faces_container: VBoxContainer = $EditDicePanel/MainVBox/ColumnsHBox/DiceFacesVBox/DieFacesContainer
@onready var close_edit_button: Button = $EditDicePanel/CloseEditButton
@onready var fuse_faces_button: Button = $EditDicePanel/MainVBox/ColumnsHBox/InventoryFacesVBox/FuseFacesButton
@onready var apply_volatile_core_button = $EditDicePanel/MainVBox/ApplyVolatileCoreButton
@onready var owned_dice_container: VBoxContainer = $EditDicePanel/MainVBox/ColumnsHBox/OwnedDiceVbox/ScrollContainer/OwnedDiceContainer
@export var owned_die_button_scene: PackedScene
@export var equipped_face_button_scene: PackedScene
@onready var inventory_faces_container: VBoxContainer = $EditDicePanel/MainVBox/ColumnsHBox/InventoryFacesVBox/ScrollContainer/InventoryFacesContainer

var selected_inventory_face_indices: Array[int] = []
var fusion_mode: bool = false
var selected_die_face_index: int = -1
var selected_die_face_index_2: int = -1
var selected_edit_die: DiceData = null
var edit_dice_return_context: String = ""

# Loot panel
@onready var loot_panel: Panel = $LootPanel
@onready var loot_gold_label: Label = $LootPanel/LootVBox/LootGoldLabel
@onready var loot_face_label: Label = $LootPanel/LootVBox/LootFaceLabel
@onready var loot_continue_button: Button = $LootPanel/LootVBox/LootContinueButton
@onready var loot_bonus_drop_label: Label = $LootPanel/LootVBox/LootBonusDropLabel

var last_dropped_faces: Array[DiceFace] = []
var last_dropped_face: DiceFace = null
var last_dropped_die: DiceData = null

# Town Screen #################################

@onready var town_panel: Panel = $TownPanel
@onready var bounty_board_button: Button = $TownPanel/VBoxContainer/BountyBoardButton
@onready var town_edit_dice_button: Button = $TownPanel/VBoxContainer/EditDiceButtonTown
@onready var trophy_button: Button = $TownPanel/VBoxContainer/TrophyButton
@onready var start_expedition_button: Button = $TownPanel/VBoxContainer/StartExpeditionButton
@onready var selected_bounty_label: Label = $TownPanel/VBoxContainer/SelectedBountyLabel
@export var bounty_button_scene: PackedScene
@onready var trophy_panel: Panel = $TrophyPanel
@onready var trophy_list_label: Label = $TrophyPanel/VBoxContainer/TrophyListLabel
@onready var close_trophy_button: Button = $TrophyPanel/VBoxContainer/CloseTrophyButton

# Prepare Expedition ##########################
@onready var prepare_expedition_panel: Panel = $PrepareExpeditionPanel
@onready var prepare_selected_bounty_label: Label = $PrepareExpeditionPanel/VBoxContainer/SelectedBountyLabel
@onready var prepare_start_expedition_button: Button = $PrepareExpeditionPanel/VBoxContainer/StartExpeditionButton
@onready var prepare_cancel_button: Button = $PrepareExpeditionPanel/VBoxContainer/CancelButton



# Camp Screen #################################

@onready var expedition_camp_panel: Panel = $ExpeditionCampPanel
@onready var camp_status_label: Label = $ExpeditionCampPanel/VBoxContainer/CampStatusLabel
@onready var camp_edit_dice_button: Button = $ExpeditionCampPanel/VBoxContainer/CampEditDiceButton
@onready var camp_items_button: Button = $ExpeditionCampPanel/VBoxContainer/CampItemsButton
@onready var camp_continue_button: Button = $ExpeditionCampPanel/VBoxContainer/CampContinueButton


# Bounty Tracking #############################

@export var bounty_pool: Array[BountyData]
var current_bounty: BountyData = null
var expedition_progress: int = 0
var expedition_required_encounters: int = 0
var expedition_is_boss_fight: bool = false
@onready var bounty_board_panel: Panel = $BountyBoardPanel
@onready var bounty_buttons_container: VBoxContainer = $BountyBoardPanel/VBoxContainer/BountyButtonsContainer
@onready var close_bounty_board_button: Button = $BountyBoardPanel/VBoxContainer/CloseBountyBoardButton

# AUDIO STUFF #################################
@onready var dice_roll_sfx: AudioStreamPlayer = $DiceRollSFX
@export var ui_click_sound: AudioStream
@export var roll_all_sound: AudioStream
@export var dice_select_sound: AudioStream
@export var dice_select_all: AudioStream
@export var hit_damage_sound: AudioStream
@export var hit_blocked_sound: AudioStream
@export var enemy_death_sound: AudioStream

# Encounter choice panel

@onready var encounter_panel: Panel = $EncounterPanel

@onready var choice_button_1: Button = $EncounterPanel/VBoxContainer/ChoiceButton1
@onready var choice_button_2: Button = $EncounterPanel/VBoxContainer/ChoiceButton2
@onready var choice_button_3: Button = $EncounterPanel/VBoxContainer/ChoiceButton3

var encounter_choices: Array[EncounterData] = []
@onready var enemies_label: Label = $RightMarginContainer/VBoxContainer/EnemiesLabel

# RELICS ##############################################################
@onready var loot_volatile_core_label: Label = $LootPanel/LootVBox/LootVolatileCoreLabel
@onready var relic_label: Label = $RelicLabel
var has_meditation_charm: bool = false

var volatile_cores: int = 0
var volatile_core_cost: int = 35
var last_volatile_cores_gained: int = 0

var owned_dice: Array[DiceData] = []

# Consumable Items #############################################
var consumable_inventory: Array[ConsumableItem] = []
var next_combat_bonus_damage := 0
var next_combat_bonus_block := 0
var next_combat_heal := 0
@export var item_button_scene: PackedScene
var next_combat_bonus_max_hp := 0
var active_food_items: Array[ConsumableItem] = []
var active_combat_bonus_block := 0
var active_combat_bonus_damage := 0
@onready var active_food_container: HBoxContainer = $TopMarginContainer/CenterContainer/VBoxContainer/ActiveFoodContainer

# Merchant #####################################
@onready var merchant_panel: Panel = $MerchantPanel
@onready var close_merchant_button: Button = $MerchantPanel/VBoxContainer/CloseMerchantButton
@onready var merchant_button: Button = $TownPanel/VBoxContainer/MerchantButton
@onready var merchant_stock_container: GridContainer = $MerchantPanel/VBoxContainer/MerchantStockContainer
@onready var prepare_consumables_container: GridContainer = $PrepareExpeditionPanel/VBoxContainer/PrepareConsumablesContainer
@onready var merchant_gold_label: Label = $MerchantPanel/VBoxContainer/MerchantGoldLabel
@export var merchant_food_pool: Array[ConsumableItem]
var merchant_food_stock: Array[ConsumableItem] = []

var hovered_enemy_index: int = -1

var gold: int = 100
var gold_reward: int = 10

var last_player_damage: int = 0
var last_damage_taken: int = 0

var enemy_roll_text: String = ""
var enemy_attack: int = 0
var enemy_block: int = 0
var enemy_crit_damage: int = 0
var enemy_heal: int = 0

var combat_number: int = 0
var base_enemy_hp: int = 20

var max_player_hp: int = 30
var player_hp: int = 30
var dice_nodes: Array[DiceNode] = []
var enemy_hp: int = 20

var player_block: int = 0
var dodged_enemy_crits := false
var combat_over: bool = false

var random_die_cost: int = 40
var reserve_slot_cost: int = 20
var heal_cost: int = 10
var money_d6_cost: int = 20

var is_resolving_turn: bool = false

func _ready():
	
	hide_all_groups()
	for die in starting_dice:
		owned_dice.append(die.duplicate(true))
	fuse_faces_button.pressed.connect(toggle_fusion_mode)
	hits_button.pressed.connect(select_group.bind(hits_container))
	crits_button.pressed.connect(select_group.bind(crits_container))
	blocks_button.pressed.connect(select_group.bind(blocks_container))
	gold_button.pressed.connect(select_group.bind(gold_container))
	healing_button.pressed.connect(select_group.bind(healing_container))
	misses_button.pressed.connect(select_group.bind(misses_container))
	camera_original_position = combat_camera.position
	apply_volatile_core_button.pressed.connect(apply_volatile_core)
	restart_run_button.pressed.connect(restart_run)
	bounty_board_button.pressed.connect(open_bounty_board)
	town_edit_dice_button.pressed.connect(open_edit_dice_panel_from_town)

	trophy_button.pressed.connect(open_trophies)
	start_expedition_button.pressed.connect(open_prepare_expedition)
	close_bounty_board_button.pressed.connect(close_bounty_board)
	camp_edit_dice_button.pressed.connect(open_edit_dice_panel_from_camp)
	camp_continue_button.pressed.connect(continue_expedition)
	selected_bounty_label.text = "No Bounty Selected"
	trophy_button.pressed.connect(open_trophies)
	close_trophy_button.pressed.connect(close_trophies)
	prepare_start_expedition_button.pressed.connect(confirm_start_expedition)
	prepare_cancel_button.pressed.connect(cancel_prepare_expedition)
	merchant_button.pressed.connect(open_merchant)
	close_merchant_button.pressed.connect(close_merchant)
	
	if current_encounter == null:
		if encounter_pool.size() > 0:
			current_encounter = encounter_pool.pick_random()
	assigned_dice_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	enemy_roll_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# load_encounter(current_encounter)
	
	roll_merchant_stock()
	spawn_player_3d_node()
	update_player_hp_label()
	update_player_block_label()
	update_incoming_damage_label()
	update_player_3d_node()
	
	# spawn_dice()
	# await roll_all_dice()
	regroup_dice()
	update_group_visibility()
	# roll_enemy_intents()
	update_enemy_3d_nodes()
	
	# reserve_button.pressed.connect(reserve_selected_dice)
	end_round_button.pressed.connect(_on_end_turn_pressed)
	update_player_hp_label()
	buy_random_die_button.pressed.connect(buy_random_die)
	buy_reserve_slot_button.pressed.connect(buy_reserve_slot)
	buy_heal_button.pressed.connect(buy_heal)
	# buy_face_button.pressed.connect(buy_face)
	debug_win_button.pressed.connect(debug_win)
	debug_gold_button.pressed.connect(debug_gold)
	next_fight_button.pressed.connect(next_fight)
	edit_dice_button.pressed.connect(open_edit_dice_panel)
	close_edit_button.pressed.connect(close_edit_dice_panel)
	loot_continue_button.pressed.connect(open_shop_after_loot)
	choice_button_1.pressed.connect(select_encounter.bind(0))
	choice_button_2.pressed.connect(select_encounter.bind(1))
	choice_button_3.pressed.connect(select_encounter.bind(2))
	
	update_gold_label()
	
func _process(delta):
	update_assigned_dice_panel_positions()
	update_enemy_hover_preview()
	
func spawn_player_3d_node():
	if player_3d_node != null and is_instance_valid(player_3d_node):
		player_3d_node.queue_free()

	player_3d_node = player_3d_scene.instantiate()
	player_position.add_child(player_3d_node)
	player_3d_node.position = Vector3.ZERO

	player_3d_node.set_character_data(player_character_data)

	update_player_3d_node()
	
func update_player_3d_node():
	if player_3d_node == null:
		return

	if !is_instance_valid(player_3d_node):
		return

	var incoming := get_current_incoming_damage()
	player_3d_node.setup(player_hp, combat_max_player_hp, player_block, incoming)
	
func get_current_incoming_damage() -> int:
	var total_attack := 0
	var total_crit := 0

	for enemy in active_enemies:
		total_attack += enemy["attack"]
		total_crit += enemy["crit"]

	var incoming := total_attack - player_block

	if incoming < 0:
		incoming = 0

	if !dodged_enemy_crits:
		incoming += total_crit

	return incoming
	
func update_enemy_hover_preview():
	var camera := get_viewport().get_camera_3d()

	if camera == null:
		return

	var mouse_pos := get_viewport().get_mouse_position()
	var from := camera.project_ray_origin(mouse_pos)
	var to := from + camera.project_ray_normal(mouse_pos) * 1000.0

	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 2
	query.collide_with_areas = true
	query.collide_with_bodies = false

	var result: Dictionary = get_viewport().world_3d.direct_space_state.intersect_ray(query)

	if result.is_empty():
		if hovered_enemy_index != -1:
			hide_enemy_roll_preview()
			hovered_enemy_index = -1
		return

	var collider = result["collider"]
	var enemy_node = collider.get_parent()

	while enemy_node != null and !(enemy_node is Enemy3D):
		enemy_node = enemy_node.get_parent()

	if !(enemy_node is Enemy3D):
		if hovered_enemy_index != -1:
			hide_enemy_roll_preview()
			hovered_enemy_index = -1
		return

	if enemy_node.enemy_index != hovered_enemy_index:
		hovered_enemy_index = enemy_node.enemy_index
		show_enemy_roll_preview(hovered_enemy_index)
	else:
		update_enemy_roll_preview_position(hovered_enemy_index)
# RELIC INVENTORY VARIABLES ####################

func apply_volatile_core():
	if volatile_cores <= 0:
		return

	if selected_edit_die == null:
		return

	if selected_edit_die.can_explode:
		return

	if selected_edit_die.sides <= 4:
		return

	selected_edit_die.can_explode = true
	volatile_cores -= 1

	update_volatile_core_button()
	refresh_edit_dice_panel()
	
	# ENCOUNTER CHOICE FUNCTIONS ##################################################
func generate_encounter_choices():
	encounter_choices.clear()

	for i in 3:
		encounter_choices.append(encounter_pool.pick_random())

	update_encounter_buttons()
	
func select_encounter(index: int):
	current_encounter = encounter_choices[index]
	encounter_panel.visible = false
	start_new_combat()

func get_encounter_text(encounter: EncounterData) -> String:
	return encounter.encounter_name
	
func create_enemy_instance(enemy_data: EnemyData) -> Dictionary:
	var scaled_max_hp = enemy_data.max_hp + ((combat_number - 1) * 5)

	return {
		"data": enemy_data,
		"hp": scaled_max_hp,
		"max_hp": scaled_max_hp,
		"attack": 0,
		"crit": 0,
		"crit_rolls": [],
		"block": 0,
		"heal": 0,
		"exposed": false,
		"roll_text": "",
		"rolled_faces": []
	}
	
func spawn_enemy_3d_nodes():
	for enemy_node in enemy_3d_nodes:
		if is_instance_valid(enemy_node):
			enemy_node.queue_free()

	enemy_3d_nodes.clear()

	for i in active_enemies.size():
		var enemy_node: Enemy3D = enemy_3d_scene.instantiate()
		var slot: Node3D = enemy_positions.get_child(i)

		slot.add_child(enemy_node)
		enemy_node.position = Vector3.ZERO
		enemy_node.setup(i, active_enemies[i])
		enemy_node.selected.connect(select_enemy_target)

		enemy_3d_nodes.append(enemy_node)

func roll_enemy_intents():
	for enemy in active_enemies:
		var data: EnemyData = enemy["data"]

		enemy["attack"] = 0
		enemy["crit"] = 0
		enemy["block"] = 0
		enemy["heal"] = 0
		enemy["roll_text"] = ""
		enemy["crit_rolls"] = []
		enemy["rolled_faces"] = []

		for die_data in data.dice_pool:
			var face: DiceFace = die_data.faces.pick_random()
			var face_index := die_data.faces.find(face)

			enemy["roll_text"] += get_face_text(face) + " "

			enemy["rolled_faces"].append({
				"face": face,
				"face_index": face_index,
				"sides": die_data.faces.size()
			})

			match face.result_type:
				"hit":
					enemy["attack"] += face.value
				"crit":
					enemy["crit"] += face.value
					enemy["crit_rolls"].append(face.value)
				"block":
					enemy["block"] += face.value
				"heal":
					enemy["heal"] += face.value

	calculate_auto_block()
	update_incoming_damage_label()
	refresh_enemy_buttons()
	update_enemy_3d_nodes()
	update_player_3d_node()
	
func refresh_enemy_buttons():
	rescue_assigned_dice()
	for container in assigned_enemy_containers:
		if !is_instance_valid(container):
			continue

		for child in container.get_children():
			if child is DiceNode:
				child.assigned_enemy_index = -1
				child.selected = false
				child.visible = false
				child.reparent(rolling_hidden_area)

	assigned_enemy_containers.clear()

	for child in assigned_dice_overlay.get_children():
		child.queue_free()

	for child in enemy_buttons_container.get_children():
		enemy_buttons_container.remove_child(child)
		child.queue_free()

	for i in active_enemies.size():
		var enemy_box := VBoxContainer.new()
		enemy_box.add_theme_constant_override("separation", 8)

		var button := Button.new()
		button.visible = false
		button.name = "EnemyButton"
		button.custom_minimum_size = Vector2(0, 0)
		button.pressed.connect(select_enemy_target.bind(i))

		var assigned_anchor := Control.new()
		assigned_anchor.custom_minimum_size = Vector2(130, 80)
		assigned_anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var center_container := CenterContainer.new()
		center_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		center_container.set_anchors_preset(Control.PRESET_FULL_RECT)

		var assigned_container := GridContainer.new()
		assigned_container.name = "AssignedDiceContainer_" + str(i)
		assigned_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		assigned_container.columns = 3
		assigned_container.add_theme_constant_override("h_separation", 8)
		assigned_container.add_theme_constant_override("v_separation", 6)

		center_container.add_child(assigned_container)
		assigned_anchor.add_child(center_container)
		assigned_dice_overlay.add_child(assigned_anchor)

		assigned_enemy_containers.append(assigned_container)

		enemy_box.add_child(button)
		enemy_buttons_container.add_child(enemy_box)

	update_enemy_button_texts()
	update_assigned_panel_visibility()

func rescue_assigned_dice():
	for container in assigned_enemy_containers:
		if !is_instance_valid(container):
			continue

		for child in container.get_children():
			if child is DiceNode:
				child.assigned_enemy_index = -1
				child.selected = false
				child.visible = false
				child.reparent(rolling_hidden_area)

func populate_enemy_roll_popup(enemy_index: int, roll_container: HBoxContainer):
	for child in roll_container.get_children():
		roll_container.remove_child(child)
		child.queue_free()

	if enemy_index < 0 or enemy_index >= active_enemies.size():
		return

	for face in active_enemies[enemy_index]["rolled_faces"]:
		var die_visual: DiceNode = dice_scene.instantiate()
		die_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE

		roll_container.add_child(die_visual)

		var temp_die_data := DiceData.new()
		temp_die_data.die_name = "Enemy Roll"
		temp_die_data.sides = 1
		temp_die_data.faces = [face]

		die_visual.setup(temp_die_data)
		die_visual.current_face = face
		die_visual.result_label.text = die_visual.get_face_text(face)
		die_visual.face_index_label.text = ""
		die_visual.used = true
		die_visual.set_compact_mode(true)
		die_visual.update_visual()
	
func show_enemy_roll_popup(enemy_index: int):
	var enemy_box = enemy_buttons_container.get_child(enemy_index)
	var popup = enemy_box.get_node_or_null("RollPopup")

	if popup == null:
		return

	var roll_container = popup.get_node_or_null("RollDiceContainer")

	if roll_container != null:
		populate_enemy_roll_popup(enemy_index, roll_container)

	popup.visible = true

func hide_enemy_roll_popup(enemy_index: int):
	var enemy_box = enemy_buttons_container.get_child(enemy_index)
	var popup = enemy_box.get_node_or_null("RollPopup")

	if popup == null:
		return

	popup.visible = false

func select_enemy_target(index: int):
	var selected_dice := get_selected_offensive_dice()
	if assigned_enemy_containers.size() != active_enemies.size():
		refresh_enemy_buttons()
	if selected_dice.size() == 0:
		return

	for die in selected_dice:
		die.assigned_enemy_index = index
		die.selected = true
		die.reserved = false
		move_die_to_assigned_enemy(die)
		die.update_visual()

	selected_enemy_index = -1
	update_enemy_button_texts()
	regroup_dice()

func update_enemy_button_texts():
	for i in enemy_buttons_container.get_child_count():
		var enemy_box = enemy_buttons_container.get_child(i)

		if i >= active_enemies.size():
			continue

		var button: Button = enemy_box.get_node_or_null("EnemyButton")

		if button == null:
			continue

		var enemy = active_enemies[i]
		var data: EnemyData = enemy["data"]
		var incoming_damage = get_incoming_damage_for_enemy(i)

	
		button.text = data.enemy_name + "\n"
		button.text += "HP: " + str(enemy["hp"]) + "\n"
		button.text += "Roll: " + enemy["roll_text"] + "\n"
		button.text += "Intent: Attack " + str(enemy["attack"])
		button.text += " | Crit " + str(enemy["crit"])
		button.text += " | Block " + str(enemy["block"])
		button.text += " | Heal " + str(enemy["heal"])
		if incoming_damage > 0:
			button.text += "\nIncoming: " + str(incoming_damage)
		if i == selected_enemy_index:
			button.text = "> TARGET <\n" + button.text
			
func get_assigned_container(enemy_index: int) -> GridContainer:
	if enemy_index < 0 or enemy_index >= assigned_enemy_containers.size():
		return null

	return assigned_enemy_containers[enemy_index]
	
func is_offensive_die(die: DiceNode) -> bool:
	if die.current_face == null:
		return false

	return die.current_face.result_type == "hit" \
		or die.current_face.result_type == "crit" \
		or die.current_face.result_type == "dodge" \
		or die.current_face.result_type == "reversal"
	
	##############################################################################
	
func load_encounter(encounter_data: EncounterData):
	if encounter_data == null:
		return

	current_encounter = encounter_data
	active_enemies.clear()
	selected_enemy_index = -1

	for enemy_data in encounter_data.enemies:
		active_enemies.append(create_enemy_instance(enemy_data))
	print("Encounter enemies: ", encounter_data.enemies.size())
	print("Active enemies: ", active_enemies.size())
	roll_enemy_intents()
	refresh_enemy_buttons()
	update_enemy_3d_nodes()
	spawn_enemy_3d_nodes()
	
func update_enemy_3d_nodes():
	for i in enemy_3d_nodes.size():
		if i >= active_enemies.size():
			continue

		if is_instance_valid(enemy_3d_nodes[i]):
			enemy_3d_nodes[i].setup(i, active_enemies[i])
	
func get_selected_offensive_dice() -> Array[DiceNode]:
	var selected_dice: Array[DiceNode] = []

	for die in dice_nodes:
		if !is_instance_valid(die):
			continue

		if die.used:
			continue

		if die.reserved:
			continue

		if die.selected and is_offensive_die(die):
			selected_dice.append(die)

	return selected_dice
	
func deselect_assigned_dice():
	for other_die in dice_nodes:
		if !is_instance_valid(other_die):
			continue

		if other_die.assigned_enemy_index != -1:
			other_die.selected = false
			other_die.update_visual()

func debug_gold():
	gold += 100
	update_gold_label()
func debug_win():
	enemy_hp = 0
	win_combat()
	
func update_encounter_buttons():
	if encounter_choices.size() < 3:
		return

	choice_button_1.text = get_encounter_text(encounter_choices[0])
	choice_button_2.text = get_encounter_text(encounter_choices[1])
	choice_button_3.text = get_encounter_text(encounter_choices[2])
	
	# DICE HANDLING #############################################
func select_group(container: GridContainer):
	deselect_assigned_dice()
	AudioManager.play_select_all_dice(dice_select_all)
	var all_selected := true

	for child in container.get_children():
		if child is DiceNode:
			if child.used:
				continue

			if !child.selected:
				all_selected = false
				break

	if all_selected:
		for child in container.get_children():
			if child is DiceNode:
				child.selected = false
				child.reserved = false
				child.update_visual()
	else:
		for child in container.get_children():
			if child is DiceNode:
				if child.used:
					continue

				child.reserved = false
				child.selected = true
				child.update_visual()
func get_container_for_die(die: DiceNode) -> GridContainer:
	if die.current_face == null:
		return misses_container

	match die.current_face.result_type:
		"hit":
			return hits_container

		"crit":
			return crits_container

		"block":
			return blocks_container

		"gold":
			return gold_container

		"heal", "vitality":
			return healing_container

		"dodge", "reversal":
			return actions_container

		_:
			return misses_container
			
func regroup_dice():
	dice_nodes = dice_nodes.filter(func(die):
		return is_instance_valid(die)
	)

	for die in dice_nodes:
		if die.assigned_enemy_index != -1:
			continue

		die.set_compact_mode(false)

		var target_container = get_container_for_die(die)

		if die.get_parent() != target_container:
			die.reparent(target_container)

	update_group_visibility()
func has_visible_dice(container: GridContainer) -> bool:
	for child in container.get_children():
		if child is DiceNode:
			return true

	return false


func update_group_visibility():
	hits_container.get_parent().visible = has_visible_dice(hits_container)
	crits_container.get_parent().visible = has_visible_dice(crits_container)
	blocks_container.get_parent().visible = has_visible_dice(blocks_container)
	gold_container.get_parent().visible = has_visible_dice(gold_container)
	healing_container.get_parent().visible = has_visible_dice(healing_container)
	misses_container.get_parent().visible = has_visible_dice(misses_container)
	
################################################################
func spawn_dice():

	for die_data in owned_dice:
		var die_node: DiceNode = dice_scene.instantiate()
		if !die_node.clicked.is_connected(handle_die_click):
			die_node.clicked.connect(handle_die_click)
		if !die_node.reserve_requested.is_connected(handle_reserve_request):
			die_node.reserve_requested.connect(handle_reserve_request)
		misses_container.add_child(die_node)
		die_node.setup(die_data)
		dice_nodes.append(die_node)
	update_group_visibility()
func handle_die_click(die: DiceNode):
	print("Individual die clicked")
	AudioManager.play_ui(dice_select_sound)
	if die.used:
		return

	if die.assigned_enemy_index != -1:
		die.assigned_enemy_index = -1
		die.selected = false
		die.update_visual()
		regroup_dice()
		update_enemy_button_texts()
		return

	if die.reserved:
		die.reserved = false
		die.selected = false
		die.update_visual()
		regroup_dice()
		return
	if die.assigned_enemy_index == -1:
		deselect_assigned_dice()
	die.selected = !die.selected
	die.reserved = false
	die.update_visual()
	update_enemy_button_texts()
	update_assigned_panel_visibility()
	
func move_die_to_assigned_enemy(die: DiceNode):
	var container := get_assigned_container(die.assigned_enemy_index)
	AudioManager.play_ui(dice_select_sound)
	if container == null:
		return

	die.set_compact_mode(true)
	die.reparent(container)

	update_assigned_panel_visibility()
	
func handle_reserve_request(die: DiceNode):
	if die.used:
		return

	if die.assigned_enemy_index != -1:
		die.assigned_enemy_index = -1
		die.selected = false
		die.update_visual()
		regroup_dice()
		calculate_auto_block()
		update_incoming_damage_label()
		update_reserve_slots_label()
		return

	if die.reserved:
		die.reserved = false
		die.selected = false
		die.update_visual()
		regroup_dice()
		calculate_auto_block()
		update_incoming_damage_label()
		update_reserve_slots_label()
		return

	if die.came_from_reserve:
		return

	if get_reserved_die_count() >= reserve_slots:
		return

	die.reserved = true
	die.selected = false
	die.reserved_turns_remaining = 1
	die.update_visual()
	regroup_dice()
	calculate_auto_block()
	update_incoming_damage_label()
	update_reserve_slots_label()
	
func roll_all_dice():
	if is_rolling_dice:
		return
	for die in dice_nodes:
		print(die, " temporary: ", die.temporary, " name: ", die.dice_data.die_name)
	is_rolling_dice = true
	
	dice_nodes = dice_nodes.filter(func(die):
		return is_instance_valid(die)
	)

	for die in dice_nodes.duplicate():
		if !is_instance_valid(die):
			continue

		if die.temporary:
			dice_nodes.erase(die)
			die.queue_free()
			continue

	var dice_to_roll: Array[DiceNode] = []

	for die in dice_nodes:
		if !is_instance_valid(die):
			continue

		if die.reserved:
			die.reserved_turns_remaining -= 1

			if die.reserved_turns_remaining <= 0:
				die.reserved = false
				die.came_from_reserve = true
				die.used = false
				die.selected = false
				die.update_visual()

			continue

		dice_to_roll.append(die)

	for die in dice_to_roll:
		if !is_instance_valid(die):
			continue

		die.visible = false
		die.reparent(rolling_hidden_area)

	update_group_visibility()

	for die in dice_to_roll:
		if !is_instance_valid(die):
			continue

		die.visible = true
		dice_roll_sfx.pitch_scale = randf_range(0.9, 1.1)
		dice_roll_sfx.play()
		await die.roll_animated(roll_animation_area, 0, 1)

		var final_container := get_container_for_die(die)
		await die.fly_to_container(final_container)
		die.set_compact_mode(false)
		if die.dice_data.can_explode:
			if die.current_face_index == die.dice_data.faces.size() - 1:
				if !die.has_exploded:
					die.has_exploded = true
					await spawn_exploded_die(die)

		update_group_visibility()
		await get_tree().create_timer(0.04).timeout

	calculate_auto_block()
	update_incoming_damage_label()
	update_reserve_slots_label()

	print("Dice count after roll: ", dice_nodes.size())

	for die in dice_nodes:
		if is_instance_valid(die):
			print(die, " parent: ", die.get_parent().name)

	is_rolling_dice = false
	
func add_combat_log_entry(text: String):
	combat_log_entries.append(text)

	while combat_log_entries.size() > 10:
		combat_log_entries.pop_front()

	combat_log_label.text = "\n".join(combat_log_entries)

func resolve_player_dice():
	dice_nodes = dice_nodes.filter(func(die):
		return is_instance_valid(die)
	)

	var gold_gained_this_turn := 0
	player_block = 0
	dodged_enemy_crits = false
	last_player_damage = 0

	update_player_block_label()

	# First resolve unassigned utility dice.
	for die in dice_nodes:
		if !is_instance_valid(die):
			continue

		if die.current_face == null:
			continue

		if die.reserved:
			continue

		if die.assigned_enemy_index != -1:
			continue

		match die.current_face.result_type:
			"block":
				player_block += die.current_face.value

			"gold":
				gold_gained_this_turn += die.current_face.value

			"heal":
				player_hp += die.current_face.value

				if player_hp > max_player_hp:
					player_hp = max_player_hp

				show_popup_text(player_3d_node, "+" + str(die.current_face.value), 1.8, Color.GREEN)
				update_player_hp_label()

			"vitality":
				max_player_hp += die.current_face.value
				player_hp += die.current_face.value

				show_popup_text(player_3d_node, "+" + str(die.current_face.value), 1.8, Color.GREEN)
				update_player_hp_label()
				add_combat_log_entry("Vitality increased max HP by " + str(die.current_face.value) + ".")

			"dodge":
				dodged_enemy_crits = true

			_:
				pass

		die.reserved = false
		die.used = true
		die.selected = false
		die.update_visual()

	gold += gold_gained_this_turn
	update_gold_label()
	update_player_block_label()

	# Then resolve assigned dice enemy by enemy.
	for enemy_index in active_enemies.size():
		if enemy_index < 0 or enemy_index >= active_enemies.size():
			continue

		var assigned_dice := get_assigned_dice_for_enemy(enemy_index)

		if assigned_dice.is_empty():
			continue

		if player_3d_node != null and is_instance_valid(player_3d_node):
			await player_3d_node.play_attack_animation()

		for die in assigned_dice:
			if !is_instance_valid(die):
				continue

			if die.current_face == null:
				continue

			if die.assigned_enemy_index != enemy_index:
				continue

			if enemy_index < 0 or enemy_index >= active_enemies.size():
				break

			var enemy = active_enemies[enemy_index]

			await resolve_single_die_impact(enemy_index, die)

			die.assigned_enemy_index = -1
			die.reserved = false
			die.used = true
			die.selected = false
			die.update_visual()

			update_enemy_3d_nodes()

			if enemy["hp"] <= 0:
				break

	# Then remove defeated enemies.
	var defeated_indices: Array[int] = []

	for i in active_enemies.size():
		if active_enemies[i]["hp"] <= 0:
			defeated_indices.append(i)

	defeated_indices.sort()
	defeated_indices.reverse()

	for index in defeated_indices:
		var defeated_name = active_enemies[index]["data"].enemy_name
		add_combat_log_entry(defeated_name + " defeated!")

		clear_assignments_for_enemy(index)
		defeated_enemies.append(active_enemies[index]["data"])

		if index < enemy_3d_nodes.size() and is_instance_valid(enemy_3d_nodes[index]):
			AudioManager.play_one_shot(enemy_death_sound, 1.05, 1.4)
			await enemy_3d_nodes[index].death_animation()

		active_enemies.remove_at(index)
		enemy_3d_nodes.remove_at(index)

	selected_enemy_index = -1

	refresh_enemy_buttons()
	update_enemy_3d_nodes()
	
func reserve_selected_dice():
	var current_reserved := 0

	for die in dice_nodes:
		if die.reserved:
			current_reserved += 1

	for die in dice_nodes:
		if die.selected == false:
			continue

		if die.came_from_reserve:
			print("Cannot reserve this die again yet")
			die.selected = false
			die.update_visual()
			continue

		if current_reserved >= reserve_slots:
			return

		die.reserved = true
		die.reserved_turns_remaining = 0
		die.selected = false
		die.update_visual()
		current_reserved += 1

func end_round():
	if combat_over:
		return

	if is_resolving_turn:
		return

	if has_unassigned_selected_offense():
		add_combat_log_entry("Assign selected attack dice to an enemy first.")
		return

	is_resolving_turn = true
	end_round_button.disabled = true

	await resolve_player_dice()

	if active_enemies.is_empty():
		await get_tree().create_timer(0.5).timeout
		win_combat()
		is_resolving_turn = false
		return

	for healer in active_enemies:
		if healer["heal"] <= 0:
			continue

		var lowest_enemy = get_lowest_health_enemy()

		if lowest_enemy == null:
			continue

		lowest_enemy["hp"] += healer["heal"]

		var healed_index := active_enemies.find(lowest_enemy)

		if healed_index != -1 and healed_index < enemy_3d_nodes.size():
			if is_instance_valid(enemy_3d_nodes[healed_index]):
				show_popup_text(
					enemy_3d_nodes[healed_index],
					"+" + str(healer["heal"]),
					1.8,
					Color.GREEN
				)

		var max_hp = lowest_enemy["data"].max_hp + ((combat_number - 1) * 5)

		if lowest_enemy["hp"] > max_hp:
			lowest_enemy["hp"] = max_hp

	update_enemy_3d_nodes()

	last_damage_taken = 0

	for enemy_index in active_enemies.size():
		if enemy_index < 0 or enemy_index >= active_enemies.size():
			continue

		var enemy = active_enemies[enemy_index]

		if enemy_index >= enemy_3d_nodes.size():
			continue

		if !is_instance_valid(enemy_3d_nodes[enemy_index]):
			continue

		for roll in enemy["rolled_faces"]:
			var face: DiceFace = roll["face"]

			if face.result_type != "hit" and face.result_type != "crit":
				continue

			await enemy_3d_nodes[enemy_index].play_attack_animation()
			await launch_enemy_die_at_player(enemy_index, face)

			var damage := face.value

			if face.result_type == "hit":
				var blocked_amount = min(damage, player_block)

				if blocked_amount > 0:
					player_block -= blocked_amount

					if player_block < 0:
						player_block = 0

					AudioManager.play_one_shot(hit_blocked_sound, 0.95, 1.05)
					show_popup_text(
						player_3d_node,
						"Block -" + str(blocked_amount),
						1.0,
						Color.CORNFLOWER_BLUE
					)
					update_player_block_label()
					await hit_stop(0.015)

				damage -= blocked_amount

			if damage > 0:
				player_hp -= damage

				if player_hp < 0:
					player_hp = 0

				last_damage_taken += damage

				AudioManager.play_one_shot(hit_damage_sound, 0.9, 1.1)
				show_damage_popup(player_3d_node, damage)
				player_3d_node.hit_flash()
				player_3d_node.hurt_bump()
				screen_shake(0.08, 0.12)
				update_player_hp_label()
				await hit_stop(0.035)

			if player_hp <= 0:
				lose_combat()
				is_resolving_turn = false
				return

	clear_used_assigned_dice()

	update_player_hp_label()
	update_player_block_label()
	update_combat_log()

	apply_end_round_relics()

	selected_enemy_index = -1

	await roll_all_dice()
	roll_enemy_intents()
	refresh_enemy_buttons()
	update_enemy_3d_nodes()
	update_player_3d_node()

	is_resolving_turn = false
	end_round_button.disabled = false
	
func clear_used_assigned_dice():
	for die in dice_nodes:
		if !is_instance_valid(die):
			continue

		if die.used and die.assigned_enemy_index != -1:
			die.assigned_enemy_index = -1
			die.selected = false
			die.update_visual()
			
func get_lowest_health_enemy():
	if active_enemies.is_empty():
		return null

	var lowest_enemy = active_enemies[0]
	var lowest_percent = float(lowest_enemy["hp"]) / float(lowest_enemy["data"].max_hp)

	for enemy in active_enemies:
		var percent = float(enemy["hp"]) / float(enemy["data"].max_hp)

		if percent < lowest_percent:
			lowest_enemy = enemy
			lowest_percent = percent

	return lowest_enemy

func update_player_hp_label():
	player_hp_label.text = "Player HP: " + str(player_hp) + "/" + str(combat_max_player_hp)
	update_shop_buttons()
	update_player_3d_node()
func get_incoming_damage_for_enemy(enemy_index: int) -> int:
	var normal_damage := 0
	var crit_damage := 0

	for die in dice_nodes:
		if !is_instance_valid(die):
			continue

		if die.assigned_enemy_index != enemy_index:
			continue

		if die.current_face == null:
			continue

		match die.current_face.result_type:
			"hit":
				normal_damage += die.current_face.value
			"crit":
				crit_damage += die.current_face.value

	var enemy = active_enemies[enemy_index]
	var damage_after_block = normal_damage - enemy["block"]

	if damage_after_block < 0:
		damage_after_block = 0

	return damage_after_block + crit_damage
	
func get_face_text(face: DiceFace) -> String:
	match face.result_type:
		"miss":
			return "Miss"
		"hit":
			return "Hit " + str(face.value)
		"crit":
			return "Crit " + str(face.value)
		"block":
			return "Block " + str(face.value)
		"gold":
			return "Gold " + str(face.value)
		"heal":
			return "Heal " + str(face.value)
		"vitality":
			return "Vitality +" + str(face.value)
		"dodge":
			return "Dodge"
		_:
			return face.result_type
		

func update_combat_log():
	add_combat_log_entry(
		"You dealt " + str(last_player_damage) +
		" damage. You took " + str(last_damage_taken) + " damage."
	)

func win_combat():
	combat_over = true

	end_round_button.disabled = true
	last_volatile_cores_gained = 0
	var total_gold_reward := 0
	last_dropped_faces.clear()
	last_dropped_face = null
	last_dropped_die = null

	for enemy_data in defeated_enemies:
		total_gold_reward += enemy_data.gold_reward
		if randf() <= enemy_data.volatile_core_drop_chance:
			volatile_cores += 1
		if enemy_data.face_drop_pool.size() > 0:
			var face_drop: DiceFace = enemy_data.face_drop_pool.pick_random()
			var face_copy := face_drop.duplicate(true)

			face_inventory.append(face_copy)
			last_dropped_faces.append(face_copy)
		if randf() <= enemy_data.volatile_core_drop_chance:
			volatile_cores += 1
			last_volatile_cores_gained += 1
		if randf() <= enemy_data.dice_drop_chance:
			if enemy_data.dice_drop_pool.size() > 0:
				if last_dropped_die == null:
					last_dropped_die = enemy_data.dice_drop_pool.pick_random()
					owned_dice.append(last_dropped_die.duplicate(true))
	clear_food_buffs()

	gold += total_gold_reward
	gold_reward = total_gold_reward

	if last_dropped_faces.size() > 0:
		last_dropped_face = last_dropped_faces[0]
	next_combat_bonus_damage = 0
	next_combat_bonus_block = 0
	next_combat_heal = 0
	combat_max_player_hp = max_player_hp
	next_combat_bonus_max_hp = 0

	if player_hp > max_player_hp:
		player_hp = max_player_hp
	update_gold_label()
	show_loot_panel()
	update_volatile_core_button()
	
	active_food_items.clear()
	update_active_food_icons()
	combat_max_player_hp = max_player_hp
	next_combat_bonus_damage = 0
	next_combat_bonus_block = 0
	next_combat_heal = 0
	next_combat_bonus_max_hp = 0
	active_combat_bonus_block = 0
	active_combat_bonus_damage = 0
	combat_max_player_hp = max_player_hp
	# Functions for combat rewards
	
func show_loot_panel():
	loot_panel.visible = true
	shop_panel.visible = false

	loot_gold_label.text = "Gold: +" + str(gold_reward)

	if last_dropped_faces.size() > 0:
		loot_face_label.text = "Faces:"

		for face in last_dropped_faces:
			loot_face_label.text += "\n" + get_face_display_name(face)
	else:
		loot_face_label.text = "Faces: None"
	if last_dropped_die != null:
		loot_bonus_drop_label.visible = true
		loot_bonus_drop_label.text = "BONUS DROP!\n" + last_dropped_die.die_name
	else:
		loot_bonus_drop_label.visible = false
		
	if last_volatile_cores_gained > 0:
		loot_volatile_core_label.visible = true
		loot_volatile_core_label.text = "Volatile Cores: +" + str(last_volatile_cores_gained)
	else:
		loot_volatile_core_label.visible = false

	combat_log_label.text = "Enemy defeated!"
	
func open_shop_after_loot():
	loot_panel.visible = false

	if expedition_is_boss_fight:
		complete_current_bounty()
		return

	show_expedition_camp()
	
func add_d6_reward():
	owned_dice.append(basic_d6)
	start_new_combat()
	
func add_volatile_core_reward():
	volatile_cores += 1
	update_volatile_core_button()
func add_reserve_slot_reward():
	reserve_slots += 1
	start_new_combat()

func heal_reward():
	player_hp += 10

	if player_hp > max_player_hp:
		player_hp = max_player_hp
	start_new_combat()
	
func lose_combat():
	combat_over = true
	combat_log_label.text = "You were defeated."

	end_round_button.disabled = true
	defeat_label.visible = true
	restart_run_button.visible = true

	clear_food_buffs()
	
func restart_run():
	get_tree().reload_current_scene()
	
func clear_food_buffs():
	active_food_items.clear()
	update_active_food_icons()

	next_combat_bonus_damage = 0
	next_combat_bonus_block = 0
	next_combat_heal = 0
	next_combat_bonus_max_hp = 0

	active_combat_bonus_block = 0
	active_combat_bonus_damage = 0
	combat_max_player_hp = max_player_hp
	
func start_new_combat():
	combat_over = false
	shop_panel.visible = false
	loot_panel.visible = false
	encounter_panel.visible = false

	combat_log_entries.clear()
	combat_log_label.text = ""
	defeated_enemies.clear()
	active_enemies.clear()
	
	combat_number += 1

	combat_max_player_hp = max_player_hp + next_combat_bonus_max_hp

	player_hp += next_combat_heal
	if player_hp > combat_max_player_hp:
		player_hp = combat_max_player_hp

	active_combat_bonus_block = next_combat_bonus_block
	active_combat_bonus_damage = next_combat_bonus_damage
	player_block = next_combat_bonus_block
	update_player_block_label()
	last_player_damage = 0
	last_damage_taken = 0

	hide_all_groups()
	clear_all_dice_groups()
	dice_nodes.clear()

	await get_tree().process_frame

	load_encounter(current_encounter)
	selected_enemy_index = -1
	spawn_dice()
	await roll_all_dice()
	calculate_auto_block()
	regroup_dice()
	update_group_visibility()

	end_round_button.disabled = false

	update_combat_number_label()
	update_player_hp_label()
	update_reserve_slots_label()
	refresh_enemy_buttons()
	update_enemy_3d_nodes()
	
func hide_all_groups():
	hits_container.get_parent().visible = false
	crits_container.get_parent().visible = false
	blocks_container.get_parent().visible = false
	gold_container.get_parent().visible = false
	healing_container.get_parent().visible = false
	misses_container.get_parent().visible = false
	
func update_combat_number_label():
	combat_number_label.text = "Fight: " + str(combat_number)
	

	
func buy_reserve_slot():
	if gold < reserve_slot_cost:
		return

	gold -= reserve_slot_cost
	reserve_slots += 1
	reserve_slot_cost += 10
	AudioManager.play_ui(ui_click_sound)
	update_gold_label()
	update_reserve_slots_label()
	
func buy_heal():
	if gold < heal_cost:
		return
	AudioManager.play_ui(ui_click_sound)
	gold -= heal_cost
	player_hp += 10

	if player_hp > max_player_hp:
		player_hp = max_player_hp

	update_player_hp_label()
	update_gold_label()
	update_shop_buttons()
	
func update_gold_label():
	gold_label.text = "Gold: " + str(gold)
	update_shop_buttons()
	
func next_fight():
	shop_panel.visible = false
	AudioManager.play_ui(ui_click_sound)
	generate_encounter_choices()

	encounter_panel.visible = true
	
func update_shop_buttons():
	buy_random_die_button.text = "Buy Random Die (" + str(random_die_cost) + "g)"
	buy_reserve_slot_button.text = "+1 Reserve Slot (" + str(reserve_slot_cost) + "g)"

	if player_hp >= max_player_hp:
		buy_heal_button.text = "Heal 10 HP (FULL)"
	else:
		buy_heal_button.text = "Heal 10 HP (" + str(heal_cost) + "g)"

	buy_random_die_button.disabled = gold < random_die_cost
	buy_reserve_slot_button.disabled = gold < reserve_slot_cost
	buy_heal_button.disabled = gold < heal_cost or player_hp >= max_player_hp
	
	
func buy_volatile_core():
	if gold < 35:
		return

	gold -= 35

	volatile_cores += 1
	update_volatile_core_button()
	AudioManager.play_ui(ui_click_sound)
	update_gold_label()
	
func buy_random_die():
	if gold < random_die_cost:
		return
	
	if random_die_pool.is_empty():
		print("Random die pool is empty")
		return
	
	var chosen_die: DiceData = random_die_pool.pick_random()

	if chosen_die == null:
		print("Chosen die is null. Check Random Die Pool in Inspector.")
		return

	gold -= random_die_cost
	owned_dice.append(chosen_die.duplicate(true))
	AudioManager.play_ui(ui_click_sound)
	update_gold_label()

func buy_face():
	if gold < face_cost:
		return

	gold -= face_cost
	face_inventory.append(hit_2_face)
	AudioManager.play_ui(ui_click_sound)
	update_gold_label()
	# DIE GRAFTING ######################################################################
func toggle_fusion_mode():
	if fusion_mode:
		fuse_selected_faces()
		fusion_mode = false
	else:
		fusion_mode = true
	AudioManager.play_ui(ui_click_sound)
	selected_inventory_face_indices.clear()
	update_fuse_button_text()
	refresh_edit_dice_panel()
	
func handle_inventory_face_click(index: int):
	AudioManager.play_ui(ui_click_sound)

	if selected_die_face_index != -1 and !fusion_mode:
		install_inventory_face(index)
		selected_inventory_face_indices.clear()
		refresh_edit_dice_panel()
		return

	select_inventory_face(index)
	refresh_edit_dice_panel()
func open_edit_dice_panel():
	if shop_panel.visible == false:
		return

	shop_panel.visible = false
	edit_dice_panel.visible = true
	AudioManager.play_ui(ui_click_sound)
	refresh_edit_dice_panel()
	fusion_mode = false
	selected_inventory_face_indices.clear()
	update_fuse_button_text()
	update_volatile_core_button()

func close_edit_dice_panel():
	edit_dice_panel.visible = false

	if edit_dice_return_context == "camp":
		expedition_camp_panel.visible = true
	elif edit_dice_return_context == "town":
		town_panel.visible = true
	else:
		shop_panel.visible = true

	edit_dice_return_context = ""

	AudioManager.play_ui(ui_click_sound)
	selected_edit_die = null
	selected_die_face_index = -1
	selected_inventory_face_indices.clear()
	fusion_mode = false
	update_fuse_button_text()
	
func refresh_edit_dice_panel():
	rebuild_owned_dice_grid()

	clear_container(die_faces_container)
	clear_container(inventory_faces_container)
	update_volatile_core_button()
	rebuild_face_inventory_grid()

	if selected_edit_die != null:
		for i in selected_edit_die.faces.size():
			var face := selected_edit_die.faces[i]

			var face_button = equipped_face_button_scene.instantiate()
			die_faces_container.add_child(face_button)

			face_button.setup(face, i, i == selected_die_face_index)
			face_button.pressed.connect(select_die_face.bind(i))
	
func rebuild_face_inventory_grid():
	clear_container(inventory_faces_container)

	var face_order := [
		"hit",
		"crit",
		"block",
		"heal",
		"vitality",
		"gold",
		"dodge",
		"reversal",
		"miss"
	]

	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	inventory_faces_container.add_child(grid)

	for result_type in face_order:
		for i in face_inventory.size():
			var face := face_inventory[i]

			if face.result_type != result_type:
				continue

			var button: InventoryFaceButton = inventory_face_button_scene.instantiate()
			grid.add_child(button)

			button.setup(face, selected_inventory_face_indices.has(i))
			button.pressed.connect(handle_inventory_face_click.bind(i))
			
func rebuild_owned_dice_grid():
	clear_container(owned_dice_container)

	var die_sizes := [4, 6, 8, 10, 12, 20]

	for sides in die_sizes:
		var dice_of_size: Array[int] = []

		for i in owned_dice.size():
			if owned_dice[i].sides == sides:
				dice_of_size.append(i)

		if dice_of_size.is_empty():
			continue

		var label := Label.new()
		label.text = "D" + str(sides)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		owned_dice_container.add_child(label)

		var grid := GridContainer.new()
		grid.columns = 3
		grid.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		grid.custom_minimum_size = Vector2(240, 0)
		grid.add_theme_constant_override("h_separation", 8)
		grid.add_theme_constant_override("v_separation", 8)
		owned_dice_container.add_child(grid)

		var category_index := 1

		for global_index in dice_of_size:
			var button: OwnedDieButton = owned_die_button_scene.instantiate()
			grid.add_child(button)

			button.setup(
				owned_dice[global_index],
				category_index,
				owned_dice[global_index] == selected_edit_die
			)

			button.pressed.connect(select_edit_die.bind(owned_dice[global_index]))

			button.custom_minimum_size = Vector2(64, 64)
			button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			button.size_flags_vertical = Control.SIZE_SHRINK_CENTER

			category_index += 1
			
func select_inventory_face(index: int):
	if selected_inventory_face_indices.has(index):
		selected_inventory_face_indices.erase(index)
	else:
		if selected_inventory_face_indices.size() >= 2:
			selected_inventory_face_indices.clear()

		selected_inventory_face_indices.append(index)
	AudioManager.play_ui(ui_click_sound)
	update_inventory_face_buttons()
	
func update_inventory_face_buttons():
	for i in inventory_faces_container.get_child_count():
		var button = inventory_faces_container.get_child(i)

		if button is Button:
			var face = face_inventory[i]
			button.text = get_face_display_name(face)

			if selected_inventory_face_indices.has(i):
				button.text = "> " + button.text + " <"

	
func clear_container(container: Container):
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
		
func fuse_selected_faces():
	if selected_edit_die != null and selected_die_face_index != -1 and selected_inventory_face_indices.size() == 1:
		var equipped_face: DiceFace = selected_edit_die.faces[selected_die_face_index]
		var inventory_index: int = selected_inventory_face_indices[0]
		var inventory_face: DiceFace = face_inventory[inventory_index]

		if !can_fuse_faces(equipped_face, inventory_face):
			return

		var new_face := create_fused_face(equipped_face, inventory_face)

		selected_edit_die.faces[selected_die_face_index] = new_face
		face_inventory.remove_at(inventory_index)

		selected_die_face_index = -1
		selected_inventory_face_indices.clear()

		refresh_edit_dice_panel()
		return

	if fusion_mode:
		fuse_faces_button.text = "Fuse Selected"
	else:
		fuse_faces_button.text = "Fuse Faces"
		
	if selected_inventory_face_indices.size() != 2:
		return

	var index_a = selected_inventory_face_indices[0]
	var index_b = selected_inventory_face_indices[1]

	if index_a == index_b:
		return

	var face_a: DiceFace = face_inventory[index_a]
	var face_b: DiceFace = face_inventory[index_b]

	if !can_fuse_faces(face_a, face_b):
		return

	var new_face = create_fused_face(face_a, face_b)

	selected_inventory_face_indices.sort()
	selected_inventory_face_indices.reverse()

	for index in selected_inventory_face_indices:
		face_inventory.remove_at(index)

	face_inventory.append(new_face)

	selected_inventory_face_indices.clear()
	call_deferred("refresh_edit_dice_panel")
func select_edit_die(die_data: DiceData):
	selected_edit_die = die_data
	AudioManager.play_ui(ui_click_sound)
	refresh_edit_dice_panel()
	update_volatile_core_button()
	
func update_volatile_core_button():
	if selected_edit_die == null:
		apply_volatile_core_button.disabled = true
		apply_volatile_core_button.text = "Apply Volatile Core"
		return

	if selected_edit_die.sides <= 4:
		apply_volatile_core_button.disabled = true
		apply_volatile_core_button.text = "D4 Cannot Explode"
		return

	if selected_edit_die.can_explode:
		apply_volatile_core_button.disabled = true
		apply_volatile_core_button.text = "Already Exploding"
		return

	if volatile_cores <= 0:
		apply_volatile_core_button.disabled = true
		apply_volatile_core_button.text = "No Volatile Core"
		return

	apply_volatile_core_button.disabled = false
	apply_volatile_core_button.text = "Apply Volatile Core"
	
func get_max_face_value_for_die(die_data: DiceData) -> int:
	return int(die_data.sides / 2)
	
func can_fuse_faces(face_a: DiceFace, face_b: DiceFace) -> bool:
	if face_a.result_type == "miss" and face_b.result_type == "miss":
		return true

	if (face_a.result_type == "dodge" and face_b.result_type == "crit") or (face_a.result_type == "crit" and face_b.result_type == "dodge"):
		return true

	if face_a.result_type == "miss" or face_b.result_type == "miss":
		return false

	if face_a.result_type != face_b.result_type:
		return false

	if face_a.value != face_b.value:
		return false

	return true

func create_fused_face(face_a: DiceFace, face_b: DiceFace) -> DiceFace:
	if face_a.result_type == "miss" and face_b.result_type == "miss":
		var dodge := DiceFace.new()
		dodge.face_name = "Dodge"
		dodge.result_type = "dodge"
		dodge.value = 0
		return dodge

	if (face_a.result_type == "dodge" and face_b.result_type == "crit") or (face_a.result_type == "crit" and face_b.result_type == "dodge"):
		var reversal := DiceFace.new()
		reversal.face_name = "Reversal"
		reversal.result_type = "reversal"
		reversal.value = 0
		return reversal

	var new_face: DiceFace = face_a.duplicate(true)
	new_face.value += 1
	new_face.face_name = "Face"
	return new_face

func create_upgraded_face(face: DiceFace) -> DiceFace:
	if face.result_type == "miss":
		var dodge := DiceFace.new()
		dodge.face_name = "Dodge"
		dodge.result_type = "dodge"
		dodge.value = 0
		return dodge

	var new_face: DiceFace = face.duplicate(true)
	new_face.value += 1
	new_face.face_name = "Face"
	return new_face
	
func update_fuse_button_text():
	if fusion_mode:
		fuse_faces_button.text = "Fuse Selected"
	else:
		fuse_faces_button.text = "Fuse Faces"
		
func select_die_face(face_index: int):
	if selected_edit_die == null:
		return

	var face = selected_edit_die.faces[face_index]

	if face.result_type == "miss" and count_misses(selected_edit_die) <= 1:
		return

	AudioManager.play_ui(ui_click_sound)

	# Inventory face already selected → swap inventory with equipped.
	if selected_inventory_face_indices.size() > 0 and !fusion_mode:
		var inventory_index := selected_inventory_face_indices[0]
		selected_die_face_index = face_index
		install_inventory_face(inventory_index)
		selected_inventory_face_indices.clear()
		selected_die_face_index_2 = -1
		refresh_edit_dice_panel()
		return

	# No equipped face selected yet.
	if selected_die_face_index == -1:
		selected_die_face_index = face_index
		selected_die_face_index_2 = -1
		refresh_edit_dice_panel()
		return

	# Clicking same equipped face deselects it.
	if selected_die_face_index == face_index:
		selected_die_face_index = -1
		selected_die_face_index_2 = -1
		refresh_edit_dice_panel()
		return

	# Different equipped face selected → swap them.
	selected_die_face_index_2 = face_index

	var temp_face: DiceFace = selected_edit_die.faces[selected_die_face_index]
	selected_edit_die.faces[selected_die_face_index] = selected_edit_die.faces[selected_die_face_index_2]
	selected_edit_die.faces[selected_die_face_index_2] = temp_face

	selected_die_face_index = -1
	selected_die_face_index_2 = -1

	refresh_edit_dice_panel()


func install_inventory_face(inventory_index: int):
	if selected_edit_die == null:
		return
	var max_allowed_value := get_max_face_value_for_die(selected_edit_die)
	var new_face: DiceFace = face_inventory[inventory_index]
	if new_face.value > max_allowed_value:
		return
	if selected_die_face_index == -1:
		return

	if inventory_index < 0 or inventory_index >= face_inventory.size():
		return
	

	if new_face.result_type == "dodge" or new_face.result_type == "reversal":
		if selected_edit_die.sides != 8:
			return

		var count := 0

		for face in selected_edit_die.faces:
			if face.result_type == "dodge" or face.result_type == "reversal":
				count += 1

		if count >= 1:
			return
	var old_face: DiceFace = selected_edit_die.faces[selected_die_face_index]

	selected_edit_die.faces[selected_die_face_index] = new_face
	face_inventory[inventory_index] = old_face

	selected_die_face_index = -1

	call_deferred("refresh_edit_dice_panel")
	

	
#######################################################################

func get_face_display_name(face: DiceFace) -> String:
	if face.face_name != "" and face.face_name != "Face":
		return face.face_name
	
	return get_face_text(face)
	
func count_misses(die_data: DiceData) -> int:
	var count := 0

	for face in die_data.faces:
		if face.result_type == "miss":
			count += 1

	return count

func get_reserved_die_count() -> int:
	
	dice_nodes = dice_nodes.filter(func(die):
		return is_instance_valid(die)
	)

	var count := 0

	for die in dice_nodes:
		if die.reserved:
			count += 1

	return count
	
func clear_all_dice_groups():
	var containers = [
		hits_container,
		crits_container,
		blocks_container,
		gold_container,
		healing_container,
		misses_container
	]

	for container in containers:
		for child in container.get_children():
			container.remove_child(child)
			child.queue_free()

	dice_nodes.clear()

# RELIC FUNCTIONALITY ###################################################
func apply_end_round_relics():
	if has_meditation_charm:
		var reserved_count := get_reserved_die_count()
		var heal_amount := reserved_count

		player_hp += heal_amount

		if player_hp > max_player_hp:
			player_hp = max_player_hp

		update_player_hp_label()

func update_relic_label():
	if has_meditation_charm:
		relic_label.text = "Relics: Meditation Charm"
	else:
		relic_label.text = "Relics: None"


######################################################################

func count_faces_of_type(die_data: DiceData, result_type: String) -> int:
	var count := 0

	for face in die_data.faces:
		if face.result_type == result_type:
			count += 1

	return count
	
func update_player_block_label():
	player_block_label.text = "Block: " + str(player_block)
	update_player_3d_node()
func calculate_auto_block():
	player_block = active_combat_bonus_block

	for die in dice_nodes:
		if !is_instance_valid(die):
			continue

		if die.reserved:
			continue

		if die.used:
			continue

		if die.current_face == null:
			continue

		if die.current_face.result_type == "block":
			player_block += die.current_face.value

	update_player_block_label()
	
func update_incoming_damage_label():
	var total_attack := 0
	var total_crit := 0

	for enemy in active_enemies:
		total_attack += enemy["attack"]
		total_crit += enemy["crit"]

	var incoming = total_attack - player_block

	if incoming < 0:
		incoming = 0

	if !dodged_enemy_crits:
		incoming += total_crit

	incoming_damage_label.text = "Incoming: " + str(incoming)
	update_player_3d_node()
	
func update_reserve_slots_label():
	reserve_slots_label.text = "Reserve: " + str(get_reserved_die_count()) + "/" + str(reserve_slots)
	
func clear_assignments_for_enemy(enemy_index: int):
	for die in dice_nodes:
		if !is_instance_valid(die):
			continue

		if die.assigned_enemy_index == enemy_index:
			die.assigned_enemy_index = -1
			die.selected = false
			die.update_visual()
			
func has_unassigned_selected_offense() -> bool:
	for die in dice_nodes:
		if !is_instance_valid(die):
			continue

		if die.used:
			continue

		if die.selected and die.assigned_enemy_index == -1 and is_offensive_die(die):
			return true

	return false
	
func get_enemy_crit_after_dodge(enemy_index: int) -> int:
	var crits = active_enemies[enemy_index]["crit_rolls"].duplicate()
	crits.sort()
	crits.reverse()

	var dodges := get_dodge_count_assigned_to_enemy(enemy_index)
	var reversals := get_reversal_count_assigned_to_enemy(enemy_index)

	var cancels := dodges + reversals

	for i in cancels:
		if crits.size() > 0:
			crits.pop_front()

	var total := 0
	for crit in crits:
		total += crit

	return total
	
func get_dodge_count_assigned_to_enemy(enemy_index: int) -> int:
	var count := 0

	for die in dice_nodes:
		if !is_instance_valid(die):
			continue

		if die.assigned_enemy_index == enemy_index:
			if die.current_face != null and die.current_face.result_type == "dodge":
				count += 1

	return count
	
func get_reversal_count_assigned_to_enemy(enemy_index: int) -> int:
	var count := 0

	for die in dice_nodes:
		if !is_instance_valid(die):
			continue

		if die.assigned_enemy_index == enemy_index:
			if die.current_face != null and die.current_face.result_type == "reversal":
				count += 1

	return count
	
func get_reversal_damage_for_enemy(enemy_index: int) -> int:
	var crits = active_enemies[enemy_index]["crit_rolls"].duplicate()
	crits.sort()
	crits.reverse()

	var dodge_count := get_dodge_count_assigned_to_enemy(enemy_index)
	var reversal_count := get_reversal_count_assigned_to_enemy(enemy_index)

	for i in dodge_count:
		if crits.size() > 0:
			crits.pop_front()

	var reflected_damage := 0

	for i in reversal_count:
		if crits.size() > 0:
			reflected_damage += crits.pop_front()

	return reflected_damage


# EXPLODING DICE ##############################
func spawn_exploded_die(source_die: DiceNode):
	var die_node: DiceNode = dice_scene.instantiate()

	die_node.clicked.connect(handle_die_click)
	die_node.reserve_requested.connect(handle_reserve_request)

	rolling_hidden_area.add_child(die_node)

	die_node.setup(source_die.dice_data.duplicate(true))
	die_node.temporary = true
	die_node.has_exploded = false
	die_node.visible = true
	die_node.update_visual()

	dice_nodes.append(die_node)
	dice_roll_sfx.pitch_scale = randf_range(0.9, 1.1)
	dice_roll_sfx.play()
	await die_node.roll_animated(roll_animation_area, 0, 1)

	var final_container := get_container_for_die(die_node)
	await die_node.fly_to_container(final_container)

	die_node.set_compact_mode(false)
	update_group_visibility()

	if die_node.dice_data.can_explode:
		if die_node.current_face_index == die_node.dice_data.faces.size() - 1:
			if !die_node.has_exploded:
				die_node.has_exploded = true
				await spawn_exploded_die(die_node)
	

func _unhandled_input(event):
	if !(event is InputEventMouseButton):
		return

	if !event.pressed:
		return

	if event.button_index != MOUSE_BUTTON_LEFT:
		return

	var camera := get_viewport().get_camera_3d()

	if camera == null:
		print("No current Camera3D found.")
		return

	var mouse_pos := get_viewport().get_mouse_position()
	var from := camera.project_ray_origin(mouse_pos)
	var to := from + camera.project_ray_normal(mouse_pos) * 1000.0

	var query := PhysicsRayQueryParameters3D.create(from, to)
	var result: Dictionary = get_viewport().world_3d.direct_space_state.intersect_ray(query)

	if result.is_empty():
		print("Ray hit nothing.")
		return

	print("Ray hit: ", result["collider"])
	
func _input(event):
	if !(event is InputEventMouseButton):
		return

	if !event.pressed:
		return

	if event.button_index != MOUSE_BUTTON_LEFT:
		return

	var camera := get_viewport().get_camera_3d()

	if camera == null:
		print("No current Camera3D found.")
		return

	var mouse_pos := get_viewport().get_mouse_position()
	var from := camera.project_ray_origin(mouse_pos)
	var to := from + camera.project_ray_normal(mouse_pos) * 1000.0

	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 2
	query.collide_with_areas = true
	query.collide_with_bodies = false
	var result: Dictionary = get_viewport().world_3d.direct_space_state.intersect_ray(query)

	if result.is_empty():
		print("Ray hit nothing.")
		return

	var collider = result["collider"]
	print("Ray hit: ", collider)

	var enemy_node = collider.get_parent()

	while enemy_node != null and !(enemy_node is Enemy3D):
		enemy_node = enemy_node.get_parent()

	if enemy_node is Enemy3D:
		select_enemy_target(enemy_node.enemy_index)
	if enemy_node is Enemy3D:
		select_enemy_target(enemy_node.enemy_index)
		
func remove_enemy_3d_node(enemy_index: int):
	if enemy_index < 0 or enemy_index >= enemy_3d_nodes.size():
		return

	var enemy_node = enemy_3d_nodes[enemy_index]

	if is_instance_valid(enemy_node):
		enemy_node.queue_free()

	enemy_3d_nodes.remove_at(enemy_index)

func update_assigned_dice_panel_positions():
	var camera := get_viewport().get_camera_3d()

	if camera == null:
		return

	for i in assigned_enemy_containers.size():
		if i >= enemy_3d_nodes.size():
			continue

		var enemy_node = enemy_3d_nodes[i]

		if !is_instance_valid(enemy_node):
			continue

		var screen_pos := camera.unproject_position(enemy_node.global_position)

		var container := assigned_enemy_containers[i]
		var panel := container.get_parent().get_parent()

		panel.global_position = screen_pos + Vector2(-80, 210)

func update_assigned_panel_visibility():
	for container in assigned_enemy_containers:
		if !is_instance_valid(container):
			continue

		var panel := container.get_parent().get_parent()
		panel.visible = container.get_child_count() > 0

func show_enemy_roll_preview(enemy_index: int):
	if enemy_roll_preview_panel != null:
		enemy_roll_preview_panel.queue_free()

	var panel := Control.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 8)

	panel.add_child(row)
	enemy_roll_overlay.add_child(panel)

	enemy_roll_preview_panel = panel

	for roll in active_enemies[enemy_index]["rolled_faces"]:
		var face: DiceFace = roll["face"]

		var die_visual: DiceNode = dice_scene.instantiate()
		die_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var temp_die_data := DiceData.new()
		temp_die_data.die_name = "Enemy Roll"
		temp_die_data.sides = roll["sides"]
		temp_die_data.faces = [face]

		row.add_child(die_visual)

		die_visual.setup(temp_die_data)
		die_visual.current_face = face
		die_visual.result_label.text = die_visual.get_face_text(face)
		die_visual.face_index_label.text = str(roll["face_index"] + 1) + "/" + str(roll["sides"])
		die_visual.used = true
		die_visual.set_compact_mode(true)
		die_visual.update_visual()
		die_visual.face_index_label.text = str(roll["face_index"] + 1) + "/" + str(roll["sides"])

	update_enemy_roll_preview_position(enemy_index)
	
func hide_enemy_roll_preview():
	if enemy_roll_preview_panel != null:
		enemy_roll_preview_panel.queue_free()
		enemy_roll_preview_panel = null
		
func update_enemy_roll_preview_position(enemy_index: int):
	if enemy_roll_preview_panel == null:
		return

	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return

	if enemy_index < 0 or enemy_index >= enemy_3d_nodes.size():
		return

	var enemy_node = enemy_3d_nodes[enemy_index]
	if !is_instance_valid(enemy_node):
		return

	var screen_pos := camera.unproject_position(enemy_node.global_position)
	enemy_roll_preview_panel.global_position = screen_pos + Vector2(-80, -130)

func _on_end_turn_pressed():
	AudioManager.play_ui(ui_click_sound)
	end_round()

func show_damage_popup(target_node: Node3D, amount: int):
	if amount <= 0:
		return

	var popup_position: Vector3

	if target_node.has_method("get_popup_position"):
		popup_position = target_node.get_popup_position()
	else:
		popup_position = target_node.global_position + Vector3(0, 1.5, 0)

	show_popup_text_at_position("-" + str(amount), popup_position, Color.RED)
	
func show_popup_text_at_position(text: String, position: Vector3, color: Color = Color.WHITE):
	if damage_popup_scene == null:
		return

	var popup: DamagePopup3D = damage_popup_scene.instantiate()
	get_tree().current_scene.add_child(popup)
	popup.global_position = position
	popup.setup(text, color)

func show_popup_text(target_node: Node3D, text: String, y_offset: float = 1.2, color: Color = Color.WHITE):
	if damage_popup_scene == null:
		return

	var popup: DamagePopup3D = damage_popup_scene.instantiate()
	get_tree().current_scene.add_child(popup)
	popup.global_position = target_node.global_position + Vector3(0, y_offset, 0)
	popup.setup(text, color)

func show_enemy_hit_sequence(enemy_index: int, blocked_amount: int, damage_amount: int):
	if enemy_index < 0 or enemy_index >= enemy_3d_nodes.size():
		return

	var enemy_node = enemy_3d_nodes[enemy_index]

	if !is_instance_valid(enemy_node):
		return

	for i in blocked_amount:
		AudioManager.play_one_shot(hit_blocked_sound, 0.95, 1.05)

		if active_enemies[enemy_index]["block"] < 0:
			active_enemies[enemy_index]["block"] = 0

		update_enemy_3d_nodes()

		show_popup_text(enemy_node, "Block -" + str(i + 1), 1.0, Color.CORNFLOWER_BLUE)
		screen_shake(0.02, 0.04)
		await hit_stop(0.01)
		await get_tree().create_timer(0.035).timeout

	for i in damage_amount:
		AudioManager.play_one_shot(hit_damage_sound, 0.9, 1.1)
		show_damage_popup(enemy_node, i + 1)
		enemy_node.hit_flash()
		enemy_node.hurt_bump()
		screen_shake(0.04, 0.08)
		await hit_stop(0.02)
		await get_tree().create_timer(0.035).timeout

func show_enemy_crit_sequence(enemy_index: int, damage_amount: int):
	if enemy_index < 0 or enemy_index >= enemy_3d_nodes.size():
		return

	var enemy_node = enemy_3d_nodes[enemy_index]

	if !is_instance_valid(enemy_node):
		return

	show_popup_text(enemy_node, "EXPOSED", 2.2, Color.YELLOW)

	for i in damage_amount:
		AudioManager.play_one_shot(hit_damage_sound, 0.85, 1.15)
		show_popup_text(enemy_node, "-" + str(i + 1), 1.7, Color.GOLD)
		enemy_node.hit_flash()
		enemy_node.hurt_bump()
		screen_shake(0.07, 0.1)
		await hit_stop(0.03)
		await get_tree().create_timer(0.035).timeout

func screen_shake(amount: float = 0.08, duration: float = 0.12):
	if combat_camera == null:
		return

	var timer := 0.0

	while timer < duration:
		combat_camera.position = camera_original_position + Vector3(
			randf_range(-amount, amount),
			randf_range(-amount, amount),
			0
		)

		timer += get_process_delta_time()
		await get_tree().process_frame

	combat_camera.position = camera_original_position

func hit_stop(duration: float = 0.05):
	Engine.time_scale = 0.0
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0
	
func launch_die_at_enemy(die: DiceNode, enemy_index: int):
	if enemy_index < 0 or enemy_index >= enemy_3d_nodes.size():
		return

	var enemy_node := enemy_3d_nodes[enemy_index]

	if !is_instance_valid(enemy_node):
		return

	var flying_die: DiceNode = dice_scene.instantiate()
	get_tree().current_scene.add_child(flying_die)

	flying_die.setup(die.dice_data)
	flying_die.current_face_index = die.current_face_index
	flying_die.current_face = die.current_face
	flying_die.set_compact_mode(false)
	flying_die.update_visual()
	flying_die.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var camera := get_viewport().get_camera_3d()
	var start_pos := die.global_position
	var target_pos := camera.unproject_position(enemy_node.global_position + Vector3(0, 1.0, 0))

	flying_die.global_position = start_pos
	flying_die.rotation = 0.0
	flying_die.scale = Vector2(0.8, 0.8)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(flying_die, "global_position", target_pos, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(flying_die, "rotation", TAU * 1.5, 0.22)
	tween.tween_property(flying_die, "scale", Vector2(1.15, 1.15), 0.12)
	tween.chain().tween_property(flying_die, "scale", Vector2(0.7, 0.7), 0.08)

	await tween.finished
	flying_die.queue_free()
	
func get_assigned_dice_for_enemy(enemy_index: int) -> Array[DiceNode]:
	var result: Array[DiceNode] = []

	var container = get_assigned_container(enemy_index)

	if container == null:
		return result

	for child in container.get_children():
		if child is DiceNode:
			if child.assigned_enemy_index == enemy_index:
				result.append(child)

	return result

func resolve_single_die_impact(enemy_index: int, die: DiceNode):
	if enemy_index < 0 or enemy_index >= active_enemies.size():
		return

	if enemy_index >= enemy_3d_nodes.size():
		return

	var enemy = active_enemies[enemy_index]
	var enemy_node = enemy_3d_nodes[enemy_index]

	if !is_instance_valid(enemy_node):
		return

	await launch_die_at_enemy(die, enemy_index)

	match die.current_face.result_type:
		"hit":
			var hit_value: int = die.current_face.value + active_combat_bonus_damage
			var blocked_amount: int = min(hit_value, enemy["block"])
			var damage_after_block: int = hit_value - blocked_amount
			hit_value += next_combat_bonus_damage
			if enemy["exposed"]:
				damage_after_block += 1
				enemy["exposed"] = false
				show_popup_text(enemy_node, "EXPOSED +1", 2.2, Color.YELLOW)

			enemy["block"] -= blocked_amount
			if enemy["block"] < 0:
				enemy["block"] = 0

			if blocked_amount > 0:
				await show_enemy_hit_sequence(enemy_index, blocked_amount, 0)

			if damage_after_block > 0:
				enemy["hp"] -= damage_after_block
				last_player_damage += damage_after_block
				await show_enemy_hit_sequence(enemy_index, 0, damage_after_block)

		"crit":
			enemy["hp"] -= die.current_face.value
			enemy["exposed"] = true
			last_player_damage += die.current_face.value

			AudioManager.play_one_shot(hit_damage_sound, 0.85, 1.15)
			show_popup_text(enemy_node, "-" + str(die.current_face.value), 1.7, Color.GOLD)
			show_popup_text(enemy_node, "EXPOSED", 2.2, Color.YELLOW)
			enemy_node.hit_flash()
			enemy_node.hurt_bump()
			screen_shake(0.07, 0.1)
			await hit_stop(0.03)

	update_enemy_3d_nodes()

func launch_enemy_die_at_player(enemy_index: int, face: DiceFace):
	if enemy_index < 0 or enemy_index >= enemy_3d_nodes.size():
		return

	if player_3d_node == null or !is_instance_valid(player_3d_node):
		return

	var enemy_node = enemy_3d_nodes[enemy_index]

	if !is_instance_valid(enemy_node):
		return

	var flying_die: DiceNode = dice_scene.instantiate()
	get_tree().current_scene.add_child(flying_die)

	var temp_die_data := DiceData.new()
	temp_die_data.die_name = "Enemy Attack"
	temp_die_data.sides = 1
	temp_die_data.faces = [face]

	flying_die.setup(temp_die_data)
	flying_die.current_face = face
	flying_die.current_face_index = 0
	flying_die.set_compact_mode(false)
	flying_die.update_visual()
	flying_die.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var camera := get_viewport().get_camera_3d()
	var start_pos := camera.unproject_position(enemy_node.global_position + Vector3(0, 1.0, 0))
	var target_pos := camera.unproject_position(player_3d_node.global_position + Vector3(0, 1.0, 0))

	flying_die.global_position = start_pos

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(flying_die, "global_position", target_pos, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(flying_die, "rotation", TAU * 1.25, 0.16)

	await tween.finished
	flying_die.queue_free()

func open_edit_dice_panel_from_town():
	edit_dice_return_context = "town"
	town_panel.visible = false
	edit_dice_panel.visible = true
	refresh_edit_dice_panel()

func rest_at_town():
	player_hp = max_player_hp
	update_player_hp_label()


func start_expedition():
	if current_bounty == null:
		print("No bounty selected.")
		return

	player_hp = max_player_hp
	update_player_hp_label()

	expedition_progress = 0
	expedition_is_boss_fight = false
	expedition_required_encounters = current_bounty.required_encounters_before_boss

	town_panel.visible = false
	bounty_board_panel.visible = false

	current_encounter = current_bounty.expedition_encounter_pool.pick_random()
	start_new_combat()

func open_bounty_board():
	town_panel.visible = false
	bounty_board_panel.visible = true
	rebuild_bounty_board()

func close_bounty_board():
	bounty_board_panel.visible = false
	town_panel.visible = true
	
func rebuild_bounty_board():
	clear_container(bounty_buttons_container)

	for bounty in bounty_pool:
		if bounty.completed:
			continue

		var button: BountyButton = bounty_button_scene.instantiate()
		bounty_buttons_container.add_child(button)
		button.setup(bounty)
		button.pressed.connect(select_bounty.bind(bounty))
		
func select_bounty(bounty: BountyData):
	current_bounty = bounty

	selected_bounty_label.text = "(" + bounty.bounty_name + ")"

	bounty_board_panel.visible = false
	town_panel.visible = true

	print("Selected bounty: ", bounty.bounty_name)

func complete_current_bounty():
	if current_bounty == null:
		return

	current_bounty.completed = true
	current_bounty = null
	expedition_is_boss_fight = false
	expedition_progress = 0

	player_hp = max_player_hp
	update_player_hp_label()

	town_panel.visible = true
	shop_panel.visible = false
	loot_panel.visible = false
	edit_dice_panel.visible = false
	selected_bounty_label.text = "No Bounty Selected"
	print("Bounty completed. Returned to town.")
	
func show_expedition_camp():
	expedition_camp_panel.visible = true
	camp_status_label.text = "Encounter " + str(expedition_progress + 1) + "/" + str(expedition_required_encounters)

func open_edit_dice_panel_from_camp():
	edit_dice_return_context = "camp"
	expedition_camp_panel.visible = false
	edit_dice_panel.visible = true
	refresh_edit_dice_panel()
	
func continue_expedition():
	expedition_camp_panel.visible = false

	expedition_progress += 1

	if expedition_progress >= expedition_required_encounters:
		expedition_is_boss_fight = true
		current_encounter = current_bounty.boss_encounter
	else:
		current_encounter = current_bounty.expedition_encounter_pool.pick_random()

	start_new_combat()

func open_trophies():
	town_panel.visible = false
	trophy_panel.visible = true

	var text := ""

	for bounty in bounty_pool:
		if bounty.completed:
			text += "✓ " + bounty.bounty_name + "\n"
		else:
			text += "✗ " + bounty.bounty_name + "\n"

	trophy_list_label.text = text

func close_trophies():
	trophy_panel.visible = false
	town_panel.visible = true

func open_prepare_expedition():
	if current_bounty == null:
		print("No bounty selected.")
		return

	town_panel.visible = false
	prepare_expedition_panel.visible = true
	prepare_selected_bounty_label.text = "Bounty: " + current_bounty.bounty_name
	rebuild_prepare_consumables()
	prepare_selected_bounty_label.text = "Bounty: " + current_bounty.bounty_name

func cancel_prepare_expedition():
	prepare_expedition_panel.visible = false
	town_panel.visible = true

func confirm_start_expedition():
	prepare_expedition_panel.visible = false
	start_expedition()
	
func roll_merchant_stock():
	merchant_food_stock.clear()

	var pool := merchant_food_pool.duplicate()
	pool.shuffle()

	for i in min(4, pool.size()):
		merchant_food_stock.append(pool[i])

func open_merchant():
	town_panel.visible = false
	merchant_panel.visible = true
	merchant_gold_label.text = "Gold: " + str(gold)
	rebuild_merchant()

func close_merchant():
	merchant_panel.visible = false
	town_panel.visible = true

func rebuild_merchant():
	clear_container(merchant_stock_container)

	merchant_gold_label.text = "Gold: " + str(gold)

	for item in merchant_food_stock:
		var owned_count := get_consumable_count(item)

		var button = item_button_scene.instantiate()
		merchant_stock_container.add_child(button)

		button.setup(
			item,
			"x" + str(owned_count),
			str(item.cost) + "g"
		)

		button.pressed.connect(buy_consumable.bind(item))
		
func get_consumable_count(item: ConsumableItem) -> int:
	var count := 0

	for owned_item in consumable_inventory:
		if owned_item.item_name == item.item_name:
			count += 1

	return count
		
func buy_consumable(item: ConsumableItem):
	if gold < item.cost:
		return

	gold -= item.cost
	consumable_inventory.append(item.duplicate(true))

	AudioManager.play_ui(ui_click_sound)
	merchant_gold_label.text = "Gold: " + str(gold)
	update_gold_label()
	rebuild_merchant()
	
func rebuild_prepare_consumables():
	clear_container(prepare_consumables_container)

	var item_counts := {}

	for item in consumable_inventory:
		if !item_counts.has(item):
			item_counts[item] = 0

		item_counts[item] += 1

	for item in item_counts.keys():
		var button = item_button_scene.instantiate()
		prepare_consumables_container.add_child(button)

		button.setup(item, "x" + str(item_counts[item]), "")
		button.pressed.connect(use_consumable_item.bind(item))
		
func use_consumable(index: int):
	if index < 0 or index >= consumable_inventory.size():
		return

	var item := consumable_inventory[index]

	player_hp += item.heal_amount
	if player_hp > max_player_hp:
		player_hp = max_player_hp

	next_combat_bonus_block += item.next_combat_block
	next_combat_bonus_damage += item.next_combat_damage

	consumable_inventory.remove_at(index)

	update_player_hp_label()
	rebuild_prepare_consumables()
	
func use_consumable_item(item: ConsumableItem):
	var index := consumable_inventory.find(item)

	if index == -1:
		return

	if is_food_already_active(item):
		return

	active_food_items.append(item)

	next_combat_heal += item.heal_amount
	next_combat_bonus_block += item.next_combat_block
	next_combat_bonus_damage += item.next_combat_damage
	next_combat_bonus_max_hp += item.next_combat_max_hp

	consumable_inventory.remove_at(index)

	update_player_hp_label()
	rebuild_prepare_consumables()
	update_active_food_icons()

func is_food_already_active(item: ConsumableItem) -> bool:
	for active_item in active_food_items:
		if active_item.item_name == item.item_name:
			return true

	return false
	
func update_active_food_icons():
	clear_container(active_food_container)

	for item in active_food_items:
		var icon := TextureRect.new()
		icon.texture = item.icon
		icon.custom_minimum_size = Vector2(32, 32)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		active_food_container.add_child(icon)
		
