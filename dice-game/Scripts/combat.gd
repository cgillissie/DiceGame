extends Control

const SETTINGS_SAVE_PATH := "user://settings.cfg"
const RUN_SAVE_PATH := "user://run_save.cfg"

@export var dice_scene: PackedScene
@export var starting_dice: Array[DiceData]
@export var enemy_3d_scene: PackedScene
@export var inventory_face_button_scene: PackedScene
@export var miss_face_template: DiceFace
@export var dodge_face_template: DiceFace
@export var reversal_face_template: DiceFace
@export var break_focus_face_template: DiceFace
@export var twist_knife_face_template: DiceFace

var enemy_3d_nodes: Array[Enemy3D] = []

var reserve_slots: int = 2
var damage_by_enemy := {}
var crit_by_enemy := {}
var combat_log_entries: Array[String] = []
var selected_dice_order: Array[DiceNode] = []

var combat_camera: Camera3D
var enemy_positions: Node3D
var player_position: Node3D

@export var player_character_data: PlayerCharacterData


var camera_original_position: Vector3


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
@onready var end_round_button: Button = $DiceArea/EndRoundButton
@export var enemy_dice: Array[DiceData]
@onready var combat_log_label: Label = $LeftMarginContainer/VBoxContainer/CombatLogLabel
@onready var combat_number_label: Label = $TopMarginContainer/CenterContainer/VBoxContainer/CombatNumberLabel
@onready var gold_label: Label = $ShopPanel/VBoxContainer/GoldLabel
@onready var enemy_buttons_container: VBoxContainer = $RightMarginContainer/VBoxContainer/EnemyButtonsContainer
@export var player_3d_scene: PackedScene
@onready var player_health_bar: TextureProgressBar = $PlayerHealthBar
@onready var player_health_label: Label = $PlayerHealthBar/PlayerHealthLabel

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
@onready var reserve_slots_label: Label = $DiceArea/ReserveHBox/ReserveSlotsLabel

# AUTO WIN BUTTON FOR TESTING
@onready var debug_win_button: Button = $DebugWinButton
@onready var debug_gold_button: Button = $DebugGoldButton

@export var hit_2_face: DiceFace

var combat_max_player_hp: int = 30
var face_inventory: Array[DiceFace] = []
var face_cost: int = 8
var dodge_targets: Array[int] = []
var reversal_targets: Array[int] = []
var break_focus_targets: Array[int] = []

@export var basic_d6: DiceData

# Encounter
@export var encounter_pool: Array[EncounterData]
var current_encounter: EncounterData
var active_enemies: Array = []
var defeated_enemies: Array[EnemyData]
var selected_enemy_index: int = -1
var assigned_enemy_containers: Array[GridContainer] = []
@onready var status_tooltip_panel: Panel = $StatusTooltipPanel
@onready var status_tooltip_label: Label = $StatusTooltipPanel/StatusTooltipLabel

@export var damage_popup_scene: PackedScene
@export var reserve_icon_texture: Texture2D

var run_encounters_completed: int = 0

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
@onready var die_faces_container: GridContainer = $EditDicePanel/MarginContainer/MainVBox/ColumnsHBox/DiceFacesVBox/DieFacesContainer
@onready var close_edit_button: Button = $EditDicePanel/MarginContainer/MainVBox/BottomButtonsHBox/CloseEditButton
@onready var fuse_faces_button: Button = $EditDicePanel/MarginContainer/MainVBox/BottomButtonsHBox/FuseFacesButton
@onready var apply_volatile_core_button = $EditDicePanel/MarginContainer/MainVBox/ApplyVolatileCoreButton
@onready var owned_dice_container: VBoxContainer = $EditDicePanel/MarginContainer/MainVBox/ColumnsHBox/OwnedDiceVbox/ScrollContainer/OwnedDiceContainer
@export var owned_die_button_scene: PackedScene
@export var equipped_face_button_scene: PackedScene
@onready var inventory_faces_container: VBoxContainer = $EditDicePanel/MarginContainer/MainVBox/ColumnsHBox/InventoryFacesVBox/ScrollContainer/InventoryFacesContainer
@onready var die_crafting_panel: Panel = $EditDicePanel/MarginContainer/MainVBox/DieCraftingPanel
@onready var fragment_label: Label = $EditDicePanel/MarginContainer/MainVBox/DieCraftingPanel/VBoxContainer/FragmentLabel

var die_fragments: int = 0
var last_die_fragments_gained: int = 0

@onready var d4_button: TextureButton = $EditDicePanel/MarginContainer/MainVBox/DieCraftingPanel/VBoxContainer/CraftButtonsHBox/D4Button
@onready var d6_button: TextureButton = $EditDicePanel/MarginContainer/MainVBox/DieCraftingPanel/VBoxContainer/CraftButtonsHBox/D6Button
@onready var d8_button: TextureButton = $EditDicePanel/MarginContainer/MainVBox/DieCraftingPanel/VBoxContainer/CraftButtonsHBox/D8Button
@onready var d10_button: TextureButton = $EditDicePanel/MarginContainer/MainVBox/DieCraftingPanel/VBoxContainer/CraftButtonsHBox/D10Button
@onready var d12_button: TextureButton = $EditDicePanel/MarginContainer/MainVBox/DieCraftingPanel/VBoxContainer/CraftButtonsHBox/D12Button
@onready var d20_button: TextureButton = $EditDicePanel/MarginContainer/MainVBox/DieCraftingPanel/VBoxContainer/CraftButtonsHBox/D20Button

@export var bleed_icon_texture: Texture2D
@export var status_icon_scene: PackedScene

var selected_inventory_face_indices: Array[int] = []
var fusion_mode: bool = false
var selected_die_face_index: int = -1
var selected_die_face_index_2: int = -1
var selected_edit_die: DiceData = null
var edit_dice_return_context: String = ""

# Loot panel
@onready var loot_panel: Panel = $LootPanel
@onready var loot_continue_button: Button = $LootPanel/LootVBox/LootContinueButton
@onready var loot_rich_text_label: RichTextLabel = $LootPanel/LootVBox/RichTextLabel

var last_dropped_faces: Array[DiceFace] = []
var last_dropped_face: DiceFace = null
var last_dropped_die: DiceData = null
var last_dropped_foods: Array[ConsumableItem] = []

# Town Screen #################################

var is_in_town: bool = true

@onready var town_panel: Panel = $TownPanel
@onready var bounty_board_button: Button = $TownPanel/VBoxContainer/BountyBoardButton
@onready var town_edit_dice_button: Button = $TownPanel/VBoxContainer/EditDiceButtonTown
@onready var trophy_button: Button = $TownPanel/VBoxContainer/TrophyButton
@onready var start_expedition_button: Button = $TownPanel/VBoxContainer/StartExpeditionButton

@export var bounty_button_scene: PackedScene
@onready var trophy_panel: Panel = $TrophyPanel
@onready var trophy_list_label: Label = $TrophyPanel/VBoxContainer/TrophyListLabel
@onready var close_trophy_button: Button = $TrophyPanel/VBoxContainer/CloseTrophyButton

# Prepare Expedition ##########################
@onready var prepare_expedition_panel: Panel = $PrepareExpeditionPanel
@onready var prepare_selected_bounty_label: Label = $PrepareExpeditionPanel/MarginContainer/VBoxContainer/SelectedBountyLabel
@onready var prepare_start_expedition_button: Button = $PrepareExpeditionPanel/MarginContainer/VBoxContainer/CookFoodButton
@onready var prepare_cancel_button: Button = $PrepareExpeditionPanel/MarginContainer/VBoxContainer/CancelButton
@onready var begin_expedition_button: Button = $BeginExpeditionButton
@onready var selected_bounty_label: Label = $PrepareExpeditionPanel/MarginContainer/VBoxContainer/SelectedBountyLabel
@onready var prepare_expedition_label: Label = $PrepareExpeditionPanel/MarginContainer/VBoxContainer/PrepareExpeditionLabel
# Camp Screen #################################

@onready var expedition_camp_panel: Panel = $ExpeditionCampPanel
@onready var camp_status_label: Label = $ExpeditionCampPanel/MarginContainer/VBoxContainer/CampStatusLabel
@onready var camp_edit_dice_button: Button = $ExpeditionCampPanel/MarginContainer/VBoxContainer/CampEditDiceButton
@onready var camp_items_button: Button = $ExpeditionCampPanel/MarginContainer/VBoxContainer/CampItemsButton
@onready var camp_continue_button: Button = $ExpeditionCampPanel/MarginContainer/VBoxContainer/CampContinueButton
@onready var camp_craft_food_button: Button = $ExpeditionCampPanel/MarginContainer/VBoxContainer/CraftFoodButton
@onready var camp_hp_label: Label = $ExpeditionCampPanel/MarginContainer/VBoxContainer/CampHPLabel
@onready var camp_progress_title_label: Label = $ExpeditionCampPanel/MarginContainer/VBoxContainer/CampProgressTitleLabel
@onready var camp_progress_value_label: Label = $ExpeditionCampPanel/MarginContainer/VBoxContainer/CampProgressValueLabel

# Bounty Tracking #############################

@export var bounty_pool: Array[BountyData]
var current_bounty: BountyData = null
var expedition_progress: int = 0
var expedition_required_encounters: int = 0
var expedition_is_boss_fight: bool = false
@onready var bounty_board_panel: Panel = $BountyBoardPanel
@onready var bounty_buttons_container: VBoxContainer = $BountyBoardPanel/MarginContainer/VBoxContainer/BountyButtonsContainer
@onready var close_bounty_board_button: Button = $BountyBoardPanel/MarginContainer/VBoxContainer/CloseBountyBoardButton
@onready var final_boss_button: Button = $BountyBoardPanel/MarginContainer/VBoxContainer/FinalBossButton
var completed_bounties: Array[BountyData] = []
var final_boss_unlocked: bool = false
@export var required_bounties_for_final_boss: int = 3
@export var final_boss_bounty: BountyData

# AUDIO STUFF #################################
@onready var dice_roll_sfx: AudioStreamPlayer = $DiceRollSFX
@export var ui_click_sound: AudioStream
@export var roll_all_sound: AudioStream
@export var dice_select_sound: AudioStream
@export var dice_select_all: AudioStream
@export var hit_damage_sound: AudioStream
@export var hit_blocked_sound: AudioStream
@export var enemy_death_sound: AudioStream
@export var critical_hit_sound: AudioStream
@export var critical_roll_sound: AudioStream
@export var food_eat_sound: AudioStream
@export var dice_smith_crafting_sound: AudioStream
@export var graft_face_sound: AudioStream
@export var coin_purchase_sound: AudioStream

# Encounter choice panel

@onready var encounter_panel: Panel = $EncounterPanel

@onready var choice_button_1: Button = $EncounterPanel/VBoxContainer/ChoiceButton1
@onready var choice_button_2: Button = $EncounterPanel/VBoxContainer/ChoiceButton2
@onready var choice_button_3: Button = $EncounterPanel/VBoxContainer/ChoiceButton3

var encounter_choices: Array[EncounterData] = []
@onready var enemies_label: Label = $RightMarginContainer/VBoxContainer/EnemiesLabel

# RELICS ##############################################################
@onready var relic_container: HBoxContainer = $RelicPanel/HBoxContainer
@export var relic_icon_scene: PackedScene
@onready var relic_label: Label = $RelicLabel

var last_unlocked_relics: Array[RelicData] = []
var owned_relics: Array[RelicData] = []
var has_meditation_charm: bool = false

var volatile_cores: int = 0
var volatile_core_cost: int = 35
var last_volatile_cores_gained: int = 0

var owned_dice: Array[DiceData] = []
@export var combat_relic_drop_pool: Array[RelicData]
@export var combat_relic_drop_chance: float = 0.05

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
var prepare_return_context: String = "town"
var food_crafting_return_context: String = ""
@export var active_buff_icon_scene: PackedScene
var unlocked_food_tier: int = 1
@export var food_recipes: Array[FoodRecipe]


# Merchant #####################################
@onready var merchant_panel: Panel = $MerchantPanel
@onready var close_merchant_button: Button = $MerchantPanel/MarginContainer/VBoxContainer/CloseMerchantButton
@onready var merchant_button: Button = $TownPanel/VBoxContainer/MerchantButton
@onready var merchant_stock_container: GridContainer = $MerchantPanel/MarginContainer/VBoxContainer/MerchantStockContainer
@onready var prepare_consumables_container: GridContainer = $PrepareExpeditionPanel/MarginContainer/VBoxContainer/PrepareConsumablesContainer
@onready var merchant_gold_label: Label = $MerchantPanel/MarginContainer/VBoxContainer/MerchantGoldLabel
@export var merchant_food_pool: Array[ConsumableItem]
@export var merchant_relic_pool: Array[RelicData]
@onready var merchant_relic_button: Button = $MerchantPanel/MarginContainer/VBoxContainer/BuyRelicButton

var current_merchant_relic: RelicData = null
var merchant_relic_cost: int = 175
var merchant_food_stock: Array[ConsumableItem] = []
var merchant_unlocked_faces: Array[DiceFace] = []
var merchant_face_cost: int = 12
var last_unlocked_merchant_faces: Array[DiceFace] = []

var selected_sell_face: DiceFace = null
var sell_face_value: int = 2

# Food Crafting Panel ############################
@onready var food_craft_panel: Panel = $FoodCraftPanel
@onready var food_craft_items_container: GridContainer = $FoodCraftPanel/MarginContainer/VBoxContainer/FoodCraftItemsContainer
@onready var craft_result_label: Label = $FoodCraftPanel/MarginContainer/VBoxContainer/CraftResultLabel
@onready var craft_button: Button = $FoodCraftPanel/MarginContainer/VBoxContainer/CraftButton
@onready var close_craft_button: Button = $FoodCraftPanel/MarginContainer/VBoxContainer/CloseCraftButton

# TRAITS ########################################
@export var regenerating_icon_texture: Texture2D
@export var random_enemy_trait_pool: Array[EnemyTrait] = []
@export var random_trait_scaling_threshold: int = 5
@export var random_trait_chance: float = 0.20

# Options Menu ####################################
@onready var options_overlay: ColorRect = $OptionsOverlay
@onready var options_button: Button = $OptionsButton
@onready var options_panel: Panel = $OptionsOverlay/OptionsPanel
@onready var close_options_button: Button = $OptionsOverlay/OptionsPanel/MarginContainer/VBoxContainer/CloseOptionsButton
@onready var options_restart_button: Button = $OptionsOverlay/OptionsPanel/MarginContainer/VBoxContainer/RestartRunButton
@onready var options_quit_button: Button = $OptionsOverlay/OptionsPanel/MarginContainer/VBoxContainer/QuitGameButton
@onready var master_volume_slider: HSlider = $OptionsOverlay/OptionsPanel/MarginContainer/VBoxContainer/MasterVolumeSlider
@onready var music_volume_slider: HSlider = $OptionsOverlay/OptionsPanel/MarginContainer/VBoxContainer/MusicVolumeSlider
@onready var sfx_volume_slider: HSlider = $OptionsOverlay/OptionsPanel/MarginContainer/VBoxContainer/SFXVolumeSlider
@onready var fullscreen_check_box = $OptionsOverlay/OptionsPanel/MarginContainer/VBoxContainer/FullscreenCheckBox
@onready var resolution_option: OptionButton = $OptionsOverlay/OptionsPanel/MarginContainer/VBoxContainer/ResolutionOptionButton
@onready var continue_run_button: Button = $OptionsOverlay/OptionsPanel/MarginContainer/VBoxContainer/ContinueRunButton

# Death Overlay ###################################
@onready var death_overlay: ColorRect = $DeathOverlay
@onready var death_restart_button: Button = $DeathOverlay/CenterContainer/VBoxContainer/RestartButton

@onready var endless_choice_overlay: ColorRect = $EndlessChoiceOverlay
@onready var end_demo_button: Button = $EndlessChoiceOverlay/Panel/MarginContainer/VBoxContainer/EndDemoButton
@onready var continue_endless_button: Button = $EndlessChoiceOverlay/Panel/MarginContainer/VBoxContainer/ContinueEndlessButton

const AVAILABLE_RESOLUTIONS := [
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440)
]

signal expedition_started
signal return_to_town_requested
signal town_menu_closed

var selected_food_craft_names: Array[String] = []

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

var player_statuses := {
	"bleed": 0,
	"regenerating": 0
}

var dice_nodes: Array[DiceNode] = []
var enemy_hp: int = 20

var player_block: int = 0
var dodged_enemy_crits := false
var combat_over: bool = false

var mulligems: int = 0
const MAX_MULLIGEMS := 3
var mulligem_used_this_turn: bool = false
var last_mulligems_gained: int = 0

@onready var mulligem_button: Button = $DiceArea/MulligemButton

var random_die_cost: int = 40
var reserve_slot_cost: int = 20
var heal_cost: int = 10
var money_d6_cost: int = 20

var is_resolving_turn: bool = false

func _ready():
	
	end_round_button.visible = false
	hide_all_groups()
	owned_dice.clear()

	print("Starting dice count: ", starting_dice.size())

	for die in starting_dice:
		print("Starting die: ", die.die_name)
		owned_dice.append(die.duplicate(true))

	print("Owned dice after setup: ", owned_dice.size())
		

	hits_button.pressed.connect(select_group.bind(hits_container))
	crits_button.pressed.connect(select_group.bind(crits_container))
	blocks_button.pressed.connect(select_group.bind(blocks_container))
	gold_button.pressed.connect(select_group.bind(gold_container))
	healing_button.pressed.connect(select_group.bind(healing_container))
	misses_button.pressed.connect(select_group.bind(misses_container))
	apply_volatile_core_button.pressed.connect(apply_volatile_core)
	restart_run_button.pressed.connect(restart_run)
	bounty_board_button.pressed.connect(open_bounty_board)
	town_edit_dice_button.pressed.connect(open_edit_dice_panel_from_town)
	final_boss_button.pressed.connect(select_final_boss_bounty)
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
	camp_items_button.pressed.connect(open_camp_items)
	camp_craft_food_button.pressed.connect(open_food_crafting)
	craft_button.pressed.connect(craft_selected_food)
	close_craft_button.pressed.connect(close_food_crafting)
	begin_expedition_button.pressed.connect(open_prepare_expedition)
	actions_button.pressed.connect(select_group.bind(actions_container))
	endless_choice_overlay.visible = false
	end_demo_button.pressed.connect(end_demo)
	continue_endless_button.pressed.connect(continue_endless_mode)
	mulligem_button.pressed.connect(use_mulligem)
	update_mulligem_button()
	d4_button.pressed.connect(craft_empty_die.bind(4))
	d6_button.pressed.connect(craft_empty_die.bind(6))
	d8_button.pressed.connect(craft_empty_die.bind(8))
	d10_button.pressed.connect(craft_empty_die.bind(10))
	d12_button.pressed.connect(craft_empty_die.bind(12))
	d20_button.pressed.connect(craft_empty_die.bind(20))
	if current_encounter == null:
		if encounter_pool.size() > 0:
			current_encounter = encounter_pool.pick_random()
	assigned_dice_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	enemy_roll_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	options_panel.visible = false
	options_button.pressed.connect(open_options_menu)
	close_options_button.pressed.connect(close_options_menu)
	options_restart_button.pressed.connect(restart_run)
	options_quit_button.pressed.connect(quit_game)
	continue_run_button.pressed.connect(continue_run)
	fullscreen_check_box.toggled.connect(_on_fullscreen_toggled)
	resolution_option.item_selected.connect(_on_resolution_selected)
	resolution_option.add_item("1280 x 720")
	resolution_option.add_item("1600 x 900")
	resolution_option.add_item("1920 x 1080")
	resolution_option.add_item("2560 x 1440")
	master_volume_slider.value_changed.connect(_on_master_volume_changed)
	music_volume_slider.value_changed.connect(_on_music_volume_changed)
	sfx_volume_slider.value_changed.connect(_on_sfx_volume_changed)
	master_volume_slider.min_value = 0.0
	master_volume_slider.max_value = 1.0
	master_volume_slider.step = 0.01
	master_volume_slider.value = 1.0

	music_volume_slider.min_value = 0.0
	music_volume_slider.max_value = 1.0
	music_volume_slider.step = 0.01
	music_volume_slider.value = 1.0

	sfx_volume_slider.min_value = 0.0
	sfx_volume_slider.max_value = 1.0
	sfx_volume_slider.step = 0.01
	sfx_volume_slider.value = 1.0
	# load_encounter(current_encounter)
	death_overlay.visible = false
	death_restart_button.pressed.connect(restart_run)
	town_panel.visible = false
	set_combat_ui_enabled(false)
	# refresh_relic_panel()
	roll_merchant_stock()
	combat_max_player_hp = max_player_hp + next_combat_bonus_max_hp
	update_player_hp_label()
	update_player_block_label()
	update_incoming_damage_label()
	update_player_status_icons()
	# spawn_dice()
	# await roll_all_dice()
	regroup_dice()
	update_group_visibility()
	# roll_enemy_intents()
	
	# reserve_button.pressed.connect(reserve_selected_dice)
	end_round_button.pressed.connect(_on_end_turn_pressed)
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
	connect_ui_click_sounds(self)
	update_gold_label()
	town_panel.visible = false
	
func _process(delta):
	update_assigned_dice_panel_positions()
	update_enemy_hover_preview()
	update_player_health_bar_position()
	
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
	
func update_player_health_bar_position():
	if player_3d_node == null or !is_instance_valid(player_3d_node):
		player_health_bar.visible = false
		return
	if combat_over or is_in_town:
		player_health_bar.visible = false
		player_health_label.visible = false
		return
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		player_health_bar.visible = false
		return
	
	var player_health_bar_size := Vector2(135, 140)
	var player_health_bar_world_offset := Vector3(-0.30, -0.10, 0)
	var player_health_label_offset := Vector2(10, -1)
	var world_pos := player_3d_node.global_position + player_health_bar_world_offset
	var screen_pos := camera.unproject_position(world_pos)

	player_health_bar.size = player_health_bar_size
	player_health_bar.global_position = screen_pos - player_health_bar_size * 0.5
	
	player_health_label.position = player_health_label_offset
	player_health_label.size = player_health_bar_size
	player_health_label.scale = Vector2.ONE
	player_health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_health_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	player_health_bar.visible = true
	player_health_label.visible = true
func update_mulligem_button():
	mulligem_button.text = "Mulligem (" + str(mulligems) + ")"

	mulligem_button.disabled = mulligems <= 0 \
		or mulligem_used_this_turn \
		or combat_over \
		or is_rolling_dice \
		or is_resolving_turn
		
func use_mulligem():
	if mulligems <= 0:
		return

	if mulligem_used_this_turn:
		return

	if is_rolling_dice or is_resolving_turn:
		return

	mulligems -= 1
	mulligem_used_this_turn = true

	await reroll_available_dice()

	update_mulligem_button()
	
func reroll_available_dice():
	var dice_to_reroll: Array[DiceNode] = []

	for die in dice_nodes:
		if !is_instance_valid(die):
			continue
		if die.used:
			continue
		if die.reserved:
			continue
		if die.assigned_enemy_index != -1:
			continue

		dice_to_reroll.append(die)

	if dice_to_reroll.is_empty():
		return

	for die in dice_to_reroll:
		die.selected = false
		selected_dice_order.erase(die)
		die.assigned_enemy_index = -1
		die.scale = Vector2.ONE * get_combat_die_scale()

		if die.get_parent() != roll_animation_area:
			die.reparent(roll_animation_area)

		die.position = Vector2.ZERO
		die.visible = true

	update_group_visibility()

	for die in dice_to_reroll:
		dice_roll_sfx.pitch_scale = randf_range(0.9, 1.1)
		dice_roll_sfx.play()

		await die.roll_animated(roll_animation_area, 0, 1)

		var final_container := get_container_for_die(die)
		await die.fly_to_container(final_container)

		die.set_compact_mode(false)
		die.scale = Vector2.ONE * get_combat_die_scale()

	apply_damage_bonus_to_dice_visuals()
	calculate_auto_block()
	update_incoming_damage_label()
	update_group_visibility()
	
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

func update_begin_expedition_button_visibility():
	begin_expedition_button.visible = is_in_town \
		and !merchant_panel.visible \
		and !food_craft_panel.visible \
		and !edit_dice_panel.visible \
		and !bounty_board_panel.visible \
		and !prepare_expedition_panel.visible \
		and !expedition_camp_panel.visible

func update_enemy_hover_preview():
	if is_menu_blocking_input():
		hide_status_tooltip()
		hide_enemy_roll_preview()
		hovered_enemy_index = -1
		return
	var hovering_status_tooltip
	var camera := get_viewport().get_camera_3d()

	if camera == null:
		hide_status_tooltip()
		hide_enemy_roll_preview()
		hovered_enemy_index = -1
		hovering_status_tooltip = false
		return

	var mouse_pos := get_viewport().get_mouse_position()
	var from := camera.project_ray_origin(mouse_pos)
	var to := from + camera.project_ray_normal(mouse_pos) * 1000.0

	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 2 | 4
	query.collide_with_areas = true
	query.collide_with_bodies = false

	var result: Dictionary = get_viewport().world_3d.direct_space_state.intersect_ray(query)

	if result.is_empty():
		hide_status_tooltip()
		hide_enemy_roll_preview()
		hovered_enemy_index = -1
		hovering_status_tooltip = false
		return

	var collider = result["collider"]

	if collider.has_meta("status_tooltip"):
		show_status_tooltip(collider.get_meta("status_tooltip"))
		hide_enemy_roll_preview()
		hovered_enemy_index = -1
		hovering_status_tooltip = true
		return

	hide_status_tooltip()
	hovering_status_tooltip = false

	var enemy_node = collider.get_parent()

	while enemy_node != null and !(enemy_node is Enemy3D):
		enemy_node = enemy_node.get_parent()

	if !(enemy_node is Enemy3D):
		hide_enemy_roll_preview()
		hovered_enemy_index = -1
		return

	if enemy_node.enemy_index != hovered_enemy_index:
		hide_enemy_roll_preview()
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
	var scaled_max_hp = enemy_data.max_hp + (run_encounters_completed * 3)

	var bonus_traits: Array[EnemyTrait] = []

	if run_encounters_completed >= random_trait_scaling_threshold:
		if randf() <= random_trait_chance:
			var valid_traits: Array[EnemyTrait] = []

			for possible_trait in random_enemy_trait_pool:
				var already_has_trait := false

				for existing_trait in enemy_data.traits:
					if existing_trait.trait_id == possible_trait.trait_id:
						already_has_trait = true
						break

				if !already_has_trait:
					valid_traits.append(possible_trait)

			if valid_traits.size() > 0:
				bonus_traits.append(valid_traits.pick_random())

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
		"frozen": false,
		"freeze_stacks": 0,
		"bleed": 0,
		"roll_text": "",
		"rolled_faces": [],
		"bonus_traits": bonus_traits
	}
	
func spawn_enemy_3d_nodes():
	if enemy_positions == null:
		push_error("enemy_positions is null.")
		return

	if enemy_positions.get_child_count() < active_enemies.size():
		push_error("Not enough enemy positions. Need " + str(active_enemies.size()) + ", have " + str(enemy_positions.get_child_count()))
		return
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
		enemy_node.status_hovered.connect(show_status_tooltip)
		enemy_node.status_unhovered.connect(hide_status_tooltip)
		
func roll_enemy_intents():
	var rolled_hit := false
	for enemy in active_enemies:
		enemy["attack"] = 0
		enemy["crit"] = 0
		enemy["block"] = 0
		enemy["heal"] = 0
		enemy["crit_rolls"] = []
		enemy["rolled_faces"] = []
	
		if enemy["frozen"]:
			enemy["roll_text"] = "Frozen"
			continue

		enemy["roll_text"] = ""
		
		var data: EnemyData = enemy["data"]

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
					rolled_hit = true
					
				"crit":
					enemy["crit"] += face.value
					enemy["crit_rolls"].append(face.value)
				"block":
					enemy["block"] += face.value
				"heal":
					enemy["heal"] += face.value
		var berserker_value := get_active_berserker_bonus(enemy)

		if berserker_value > 0 and rolled_hit:
			enemy["attack"] += berserker_value
			enemy["roll_text"] += "Berserker +" + str(berserker_value) + " "
		var armored_value := get_enemy_trait_value(enemy, "armored")

		if armored_value > 0:
			enemy["block"] += armored_value

		if has_relic("Ice Crystal") and enemy["freeze_stacks"] > 0:
			enemy["attack"] = max(enemy["attack"] - 1, 0)
			enemy["crit"] = max(enemy["crit"] - 1, 0)
			enemy["roll_text"] += "Ice Crystal -1 "

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

func get_enemy_trait_value(enemy: Dictionary, trait_id: String) -> int:
	var data: EnemyData = enemy["data"]

	# Built-in enemy traits
	for enemy_trait in data.traits:
		if enemy_trait.trait_id == trait_id:
			return enemy_trait.value

	# Random bonus traits
	if enemy.has("bonus_traits"):
		for enemy_trait in enemy["bonus_traits"]:
			if enemy_trait.trait_id == trait_id:
				return enemy_trait.value

	return 0
	
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
		die.selected = false
		die.reserved = false

		selected_dice_order.erase(die)

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
		var trait_text := get_enemy_trait_text(enemy)

		if trait_text != "":
			button.text += "\nTraits: " + trait_text
	
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
		or die.current_face.result_type == "reversal" \
		or die.current_face.result_type == "freeze" \
		or die.current_face.result_type == "bleed" \
		or die.current_face.result_type == "twist_knife" \
		or die.current_face.result_type == "break_focus"
	
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
			enemy_3d_nodes[i].setup(i, active_enemies[i])
			enemy_3d_nodes[i].update_status_icons(
	active_enemies[i]["data"],
	active_enemies[i]
)
func get_selected_offensive_dice() -> Array[DiceNode]:
	var selected_dice: Array[DiceNode] = []

	for die in selected_dice_order:
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
	selected_dice_order.clear()
	
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
				selected_dice_order.erase(child)
				child.update_visual()
	else:
		for child in container.get_children():
			if child is DiceNode:
				if child.used:
					continue

				child.reserved = false
				child.selected = true
				selected_dice_order.erase(child)
				selected_dice_order.append(child)
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

		"dodge", "reversal", "freeze", "bleed", "twist_knife", "break_focus":
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
			
		die.scale = Vector2.ONE * get_combat_die_scale()
		die.set_compact_mode(false)

		var target_container = get_container_for_die(die)

		if die.get_parent() != target_container:
			die.reparent(target_container)
	update_combat_dice_spacing()
	update_group_visibility()
func has_visible_dice(container: GridContainer) -> bool:
	for child in container.get_children():
		if child is DiceNode:
			return true

	return false

func update_combat_dice_spacing():
	var count := owned_dice.size()
	var spacing := 8

	if count > 8:
		spacing = 6
	if count > 12:
		spacing = 4
	if count > 16:
		spacing = 2

	var containers := [
		actions_container,
		hits_container,
		crits_container,
		blocks_container,
		gold_container,
		healing_container,
		misses_container
	]

	for container in containers:
		container.add_theme_constant_override("h_separation", spacing)
		container.add_theme_constant_override("v_separation", spacing)
		
func update_group_visibility():
	actions_container.get_parent().visible = has_visible_dice(actions_container)
	hits_container.get_parent().visible = has_visible_dice(hits_container)
	crits_container.get_parent().visible = has_visible_dice(crits_container)
	blocks_container.get_parent().visible = has_visible_dice(blocks_container)
	gold_container.get_parent().visible = has_visible_dice(gold_container)
	healing_container.get_parent().visible = has_visible_dice(healing_container)
	misses_container.get_parent().visible = has_visible_dice(misses_container)
	
################################################################
func spawn_dice():
	print("Spawning dice count: ", owned_dice.size())

	for die_data in owned_dice:
		print("Spawning die: ", die_data.die_name)
		var die_node: DiceNode = dice_scene.instantiate()
		if !die_node.clicked.is_connected(handle_die_click):
			die_node.clicked.connect(handle_die_click)
		if !die_node.reserve_requested.is_connected(handle_reserve_request):
			die_node.reserve_requested.connect(handle_reserve_request)
		misses_container.add_child(die_node)
		die_node.setup(die_data)
		die_node.scale = Vector2.ONE * get_combat_die_scale()
		dice_nodes.append(die_node)
	update_combat_dice_spacing()
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

	die.selected = !die.selected

	if die.selected:
		selected_dice_order.erase(die)
		selected_dice_order.append(die)
	else:
		selected_dice_order.erase(die)

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
	player_block = active_combat_bonus_block
	update_player_block_label()
	is_rolling_dice = true
	end_round_button.disabled = true
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

		die.used = false
		die.selected = false
		die.assigned_enemy_index = -1
		die.update_visual()

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
		if die.current_face != null and die.current_face.result_type == "crit":
			AudioManager.play_one_shot(critical_roll_sound)
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
	# player_block = 0
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
			#"block":
				#player_block += die.current_face.value

			"gold":
				gold_gained_this_turn += die.current_face.value

			"heal":
				player_hp += die.current_face.value

				if player_hp > max_player_hp:
					player_hp = max_player_hp

				show_popup_text(player_3d_node, "+" + str(die.current_face.value), 1.8, Color.GREEN)
				combat_max_player_hp = max_player_hp + next_combat_bonus_max_hp
				update_player_hp_label()

			"vitality":
				max_player_hp += die.current_face.value
				player_hp += die.current_face.value

				show_popup_text(player_3d_node, "+" + str(die.current_face.value), 1.8, Color.GREEN)
				combat_max_player_hp = max_player_hp + next_combat_bonus_max_hp
				update_player_hp_label()
				add_combat_log_entry("Vitality increased max HP by " + str(die.current_face.value) + ".")

			"dodge":
				dodged_enemy_crits = true

			_:
				pass

		if die.current_face.result_type in ["block", "gold", "heal", "vitality", "dodge"]:
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
	await remove_defeated_enemies()

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
	
	mulligem_used_this_turn = false
	update_mulligem_button()
	
	if active_enemies.is_empty():
		await get_tree().create_timer(0.5).timeout
		win_combat()
		is_resolving_turn = false
		return

	for healer_index in active_enemies.size():
		var healer = active_enemies[healer_index]
		if healer["frozen"]:
			continue
		if healer["heal"] <= 0:
			continue

		if break_focus_targets.has(healer_index):
			add_combat_log_entry(healer["data"].enemy_name + "'s healing was broken.")
			show_popup_text(enemy_3d_nodes[healer_index], "Healing Broken!", 1.2, Color.PURPLE)
			continue

		var lowest_enemy = get_lowest_health_enemy()

		if lowest_enemy == null:
			continue

		lowest_enemy["hp"] += healer["heal"]

		var healed_index := active_enemies.find(lowest_enemy)

		var max_hp = lowest_enemy["max_hp"]
		if lowest_enemy["hp"] > max_hp:
			lowest_enemy["hp"] = max_hp

		update_enemy_3d_nodes()

		if healed_index != -1 and healed_index < enemy_3d_nodes.size():
			if is_instance_valid(enemy_3d_nodes[healed_index]):
				show_popup_text(
					enemy_3d_nodes[healed_index],
					"+" + str(healer["heal"]),
					1.8,
					Color.GREEN
				)

				await get_tree().create_timer(1.50).timeout
	last_damage_taken = 0

	for enemy_index in active_enemies.size():
		if enemy_index < 0 or enemy_index >= active_enemies.size():
			continue

		var enemy = active_enemies[enemy_index]
		if enemy["frozen"]:
			if enemy["data"].immune_to_freeze_skip:
				show_popup_text(
					enemy_3d_nodes[enemy_index],
					"Chilled!",
					1.2,
					Color.CYAN
				)

				add_combat_log_entry(enemy["data"].enemy_name + " resists being frozen.")
				enemy["frozen"] = false
			else:
				show_popup_text(
					enemy_3d_nodes[enemy_index],
					"Frozen!",
					1.2,
					Color.CYAN
				)

				add_combat_log_entry(enemy["data"].enemy_name + " is frozen and skips their turn.")
				enemy["frozen"] = false

				update_enemy_3d_nodes()
				continue
			
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
			
			if face.result_type == "crit":
				AudioManager.play_one_shot(critical_hit_sound)
				if reversal_targets.has(enemy_index):
					active_enemies[enemy_index]["hp"] -= damage

					show_damage_popup(enemy_3d_nodes[enemy_index], damage)
					add_combat_log_entry("Reversed " + str(damage) + " crit damage.")

					if active_enemies[enemy_index]["hp"] < 0:
						active_enemies[enemy_index]["hp"] = 0

					update_enemy_3d_nodes()
					await hit_stop(0.035)

					if active_enemies[enemy_index]["hp"] <= 0:
						await remove_defeated_enemies()

						if active_enemies.is_empty():
							await get_tree().create_timer(0.5).timeout
							win_combat()
							is_resolving_turn = false
							return

					continue

				if dodge_targets.has(enemy_index):
					add_combat_log_entry("Dodged " + str(damage) + " crit damage.")
					show_popup_text(player_3d_node, "Dodged!", 1.0, Color.CORNFLOWER_BLUE)
					await hit_stop(0.02)
					continue
			if face.result_type == "hit":
				damage += get_active_berserker_bonus(enemy)
				var blocked_amount = min(damage, player_block)

				if blocked_amount > 0:
					player_block -= blocked_amount

					if player_block < 0:
						player_block = 0
					if has_relic("Spiked Shield"):
						enemy["bleed"] += 1
						show_popup_text(enemy_3d_nodes[enemy_index], "Bleed +1", 1.2, Color.RED)
						add_combat_log_entry("Spiked Shield inflicted 1 Bleed.")
						update_enemy_3d_nodes()
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
				if face.result_type == "hit":
					var venom_value := get_enemy_trait_value(enemy, "venomous")
					print("VENOM CHECK: ", enemy["data"].enemy_name, " value=", venom_value)

					if venom_value > 0:
						player_statuses["bleed"] += venom_value
						show_popup_text(player_3d_node, "Bleed +" + str(venom_value), 1.2, Color.RED)
						add_combat_log_entry(enemy["data"].enemy_name + " applied Bleed " + str(venom_value) + ".")
						update_player_status_icons()
												
				if player_hp < 0:
					player_hp = 0

				last_damage_taken += damage

				AudioManager.play_one_shot(hit_damage_sound, 0.9, 1.1)
				show_damage_popup(player_3d_node, damage)
				player_3d_node.hit_flash()
				player_3d_node.hurt_bump()
				screen_shake(0.08, 0.12)
				combat_max_player_hp = max_player_hp + next_combat_bonus_max_hp
				update_player_hp_label()
				await hit_stop(0.035)

			if player_hp <= 0:
				lose_combat()
				is_resolving_turn = false
				return
	await apply_enemy_bleed()
	apply_player_regeneration()
	await remove_defeated_enemies()

	if active_enemies.is_empty():
		await get_tree().create_timer(0.5).timeout
		win_combat()
		is_resolving_turn = false
		return
	clear_used_assigned_dice()
	dodge_targets.clear()
	reversal_targets.clear()
	break_focus_targets.clear()
	combat_max_player_hp = max_player_hp + next_combat_bonus_max_hp
	update_player_hp_label()
	update_player_block_label()
	apply_player_bleed()
	update_combat_log()
	apply_enemy_end_round_traits()
	update_enemy_3d_nodes()
	apply_end_round_relics()
	decay_enemy_statuses()
	selected_enemy_index = -1
	reset_dice_for_next_roll()
	await roll_all_dice()
	apply_damage_bonus_to_dice_visuals()
	calculate_auto_block()
	
	roll_enemy_intents()
	refresh_enemy_buttons()
	update_player_3d_node()

	is_resolving_turn = false
	end_round_button.disabled = false
	
func apply_player_bleed():
	var bleed_value: int = player_statuses.get("bleed", 0)

	if bleed_value <= 0:
		return

	player_hp -= bleed_value
	AudioManager.play_one_shot(hit_damage_sound, 0.9, 1.1)
	if player_hp < 0:
		player_hp = 0

	show_damage_popup(player_3d_node, bleed_value)
	add_combat_log_entry("Bleed dealt " + str(bleed_value) + " damage.")

	player_statuses["bleed"] = max(bleed_value - 1, 0)

	update_player_hp_label()
	update_player_status_icons()

	if player_hp <= 0:
		lose_combat()
		
func get_active_berserker_bonus(enemy: Dictionary) -> int:
	var value := get_enemy_trait_value(enemy, "berserker")

	if value <= 0:
		return 0

	if enemy["hp"] > enemy["max_hp"] / 2:
		return 0

	return value
	
func reset_dice_for_next_roll():
	for die in dice_nodes:
		if !is_instance_valid(die):
			continue

		die.used = false
		die.selected = false
		die.assigned_enemy_index = -1

		if !die.reserved:
			die.visible = true

		die.update_visual()
		
func remove_defeated_enemies():
	var defeated_indices: Array[int] = []

	for i in active_enemies.size():
		if active_enemies[i]["hp"] <= 0:
			defeated_indices.append(i)

	defeated_indices.sort()
	defeated_indices.reverse()

	for index in defeated_indices:
		apply_shatter_from_enemy(index)
		var defeated_name = active_enemies[index]["data"].enemy_name
		add_combat_log_entry(defeated_name + " defeated!")
		
		clear_assignments_for_enemy(index)
		defeated_enemies.append(active_enemies[index]["data"])

		if index < enemy_3d_nodes.size() and is_instance_valid(enemy_3d_nodes[index]):
			AudioManager.play_one_shot(enemy_death_sound, 1.05, 1.4)
			await enemy_3d_nodes[index].death_animation()

		active_enemies.remove_at(index)
		enemy_3d_nodes.remove_at(index)
	var chained_death := false

	for i in active_enemies.size():
		if active_enemies[i]["hp"] <= 0:
			chained_death = true
			break

	if chained_death:
		await remove_defeated_enemies()
		return
	refresh_enemy_buttons()
	update_enemy_3d_nodes()	

func clear_used_assigned_dice():
	for die in dice_nodes:
		if !is_instance_valid(die):
			continue

		if die.used:
			die.assigned_enemy_index = -1
			die.selected = false
			die.reserved = false
			die.visible = true
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

	player_health_bar.max_value = combat_max_player_hp
	player_health_bar.value = player_hp
	player_health_label.text = str(player_hp) + "/" + str(combat_max_player_hp)
	update_camp_hp_label()
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
	run_encounters_completed += 1
	player_health_bar.visible = false
	player_health_label.visible = false
	end_round_button.disabled = true
	last_volatile_cores_gained = 0
	var total_gold_reward := 0
	last_dropped_faces.clear()
	last_dropped_face = null
	last_dropped_die = null
	last_dropped_foods.clear()
	last_die_fragments_gained = randi_range(1, 3)
	die_fragments += last_die_fragments_gained
	last_mulligems_gained = 0
	last_unlocked_relics.clear()
	if expedition_is_boss_fight and current_bounty != null:
		for relic in current_bounty.unlocked_relics:
			if !owned_relics.has(relic):
				owned_relics.append(relic)
				last_unlocked_relics.append(relic)

		# refresh_relic_panel()
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
		if randf() <= enemy_data.food_drop_chance:
			if enemy_data.food_drop_pool.size() > 0:
				var food_drop: ConsumableItem = enemy_data.food_drop_pool.pick_random()
				consumable_inventory.append(food_drop)
				last_dropped_foods.append(food_drop)
	clear_food_buffs()
	if has_relic("Lucky Coin"):
		gold += 5
		gold_reward += 5
	gold += total_gold_reward
	gold_reward = total_gold_reward
	if mulligems < MAX_MULLIGEMS:
		if randf() <= 0.05:
			add_mulligems(1)
			last_mulligems_gained += 1
	if last_dropped_faces.size() > 0:
		last_dropped_face = last_dropped_faces[0]
	if expedition_is_boss_fight:
		if mulligems < MAX_MULLIGEMS:
			add_mulligems(1)
			last_mulligems_gained += 1
	
	next_combat_bonus_damage = 0
	next_combat_bonus_block = 0
	next_combat_heal = 0
	combat_max_player_hp = max_player_hp
	next_combat_bonus_max_hp = 0

	if player_hp > max_player_hp:
		player_hp = max_player_hp
	update_gold_label()
	apply_end_combat_relics()
	last_unlocked_relics.clear()

	if combat_relic_drop_pool.size() > 0:
		if randf() <= combat_relic_drop_chance:
			var valid_relics := []

			for relic in combat_relic_drop_pool:
				if !owned_relics.has(relic):
					valid_relics.append(relic)

			if valid_relics.size() > 0:
				var dropped_relic: RelicData = valid_relics.pick_random()
				owned_relics.append(dropped_relic)
				last_unlocked_relics.append(dropped_relic)
				update_active_food_icons()
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
	save_run()
	
	# Functions for combat rewards
	
func show_loot_panel():
	loot_panel.visible = true
	shop_panel.visible = false

	var loot_text := ""

	loot_text += "[center][b]Loot Claimed![/b][/center]\n\n"
	loot_text += "[center]Gold: +" + str(gold_reward) + "[/center]\n\n"

	# Faces
	if last_dropped_faces.size() > 0:
		loot_text += "[center][color=gold]Faces[/color]\n"

		for face in last_dropped_faces:
			loot_text += get_face_display_name(face) + "\n"

		loot_text += "\n"

	# Food
	if last_dropped_foods.size() > 0:
		loot_text += "[color=green]Food[/color]\n"

		for food in last_dropped_foods:
			loot_text += food.item_name + "\n"

		loot_text += "\n"
		
	if last_unlocked_relics.size() > 0:
		loot_text += "[center][color=yellow]Relics[/color]\n"

		for relic in last_unlocked_relics:
			loot_text += relic.relic_name + "\n"

		loot_text += "\n"
		
	# Volatile Cores
	if last_volatile_cores_gained > 0:
		loot_text += "[center][color=orange]Volatile Cores: +" + str(last_volatile_cores_gained) + "[/color]\n\n"

	# Die Fragments
	if last_die_fragments_gained > 0:
		loot_text += "[center][color=cyan]Die Fragments: +" + str(last_die_fragments_gained) + "[/color]\n\n"

	# Bonus Dice
	if last_dropped_die != null:
		loot_text += "[center][color=lightblue]BONUS DROP![/color][/center]\n"
		loot_text += "[center]" + last_dropped_die.die_name + "[/center]\n"
		
	if last_unlocked_merchant_faces.size() > 0:
		loot_text += "\n[center][color=yellow]New Merchant Stock![/color][/center]\n"

		for face in last_unlocked_merchant_faces:
			loot_text += "[center]" + get_face_display_name(face) + "[/center]\n"
	if last_mulligems_gained > 0:
		loot_text += "[center][color=violet]Mulligems: +" + str(last_mulligems_gained) + "[/color]\n\n"
	loot_rich_text_label.clear()
	loot_rich_text_label.append_text(loot_text)
		
func update_camp_hp_label():
	if camp_hp_label != null:
		camp_hp_label.text = "HP: " + str(player_hp) + "/" + str(max_player_hp)
		
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
	is_resolving_turn = false

	hide_all_combat_ui()
	show_death_screen()

	clear_food_buffs()
	
func restart_run():
	delete_run_save()
	get_tree().reload_current_scene()
	rebuild_bounty_board()
	run_encounters_completed = 0
	# refresh_relic_panel()
	
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
	is_resolving_turn = false
	is_in_town = false
	
	shop_panel.visible = false
	loot_panel.visible = false
	encounter_panel.visible = false
	expedition_camp_panel.visible = false
	prepare_expedition_panel.visible = false
	town_panel.visible = false
	player_health_bar.visible = true
	player_health_label.visible = true
	dodge_targets.clear()
	reversal_targets.clear()
	combat_log_entries.clear()
	combat_log_label.text = ""
	defeated_enemies.clear()
	active_enemies.clear()
	selected_enemy_index = -1
	selected_dice_order.clear()
	break_focus_targets.clear()
	$DiceArea/ReserveHBox.visible = true
	last_player_damage = 0
	last_damage_taken = 0

	for die in dice_nodes:
		if is_instance_valid(die):
			die.queue_free()

	dice_nodes.clear()
	clear_all_dice_groups()
	hide_all_groups()

	await get_tree().process_frame

	combat_number += 1
	update_combat_number_label()
	
	combat_max_player_hp = max_player_hp + next_combat_bonus_max_hp
	player_hp = min(player_hp + next_combat_heal, combat_max_player_hp)

	active_combat_bonus_block = next_combat_bonus_block
	active_combat_bonus_damage = next_combat_bonus_damage
	player_block = active_combat_bonus_block
	if has_relic("Iron Charm"):
		active_combat_bonus_block += 2
		player_block += 2
	update_player_block_label()
	update_player_hp_label()

	load_encounter(current_encounter)

	spawn_dice()
	await roll_all_dice()
	
	mulligem_used_this_turn = false
	update_mulligem_button()
	apply_damage_bonus_to_dice_visuals()
	calculate_auto_block()
	regroup_dice()
	update_group_visibility()
	update_player_status_icons()
	update_incoming_damage_label()
	update_reserve_slots_label()
	refresh_enemy_buttons()
	update_enemy_3d_nodes()
	update_player_3d_node()

	end_round_button.disabled = false
	
func get_combat_die_scale() -> float:
	var count := owned_dice.size()

	if count <= 4:
		return 1.0
	elif count <= 6:
		return 0.90
	elif count <= 8:
		return 0.80
	elif count <= 10:
		return 0.70
	elif count <= 12:
		return 0.62
	elif count <= 16:
		return 0.55

	return 0.48
	
func hide_all_groups():
	hits_container.get_parent().visible = false
	crits_container.get_parent().visible = false
	blocks_container.get_parent().visible = false
	gold_container.get_parent().visible = false
	healing_container.get_parent().visible = false
	misses_container.get_parent().visible = false
	actions_container.get_parent().visible = false
	
func update_combat_number_label():
	if expedition_is_boss_fight:
		combat_number_label.text = "Boss Encounter"
	else:
		combat_number_label.text = "Encounter: %d/%d" % [
			expedition_progress + 1,
			expedition_required_encounters
		]

	combat_number_label.visible = !is_in_town
	

	
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

	combat_max_player_hp = max_player_hp + next_combat_bonus_max_hp
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
	edit_dice_panel.set_anchors_preset(Control.PRESET_CENTER)
	edit_dice_panel.position = Vector2.ZERO
	edit_dice_panel.anchor_left = 0.5
	edit_dice_panel.anchor_top = 0.5
	edit_dice_panel.anchor_right = 0.5
	edit_dice_panel.anchor_bottom = 0.5
	edit_dice_panel.offset_left = -550
	edit_dice_panel.offset_top = -350
	edit_dice_panel.offset_right = 550
	edit_dice_panel.offset_bottom = 350
	shop_panel.visible = false
	edit_dice_panel.visible = true
	AudioManager.play_ui(ui_click_sound)
	refresh_edit_dice_panel()
	fusion_mode = false
	selected_inventory_face_indices.clear()
	update_begin_expedition_button_visibility()
	update_fuse_button_text()
	update_volatile_core_button()


func close_edit_dice_panel():
	edit_dice_panel.visible = false

	if edit_dice_return_context == "camp":
		expedition_camp_panel.visible = true
	else:
		town_menu_closed.emit()

	edit_dice_return_context = ""
	AudioManager.play_ui(ui_click_sound)
	selected_edit_die = null
	selected_die_face_index = -1
	selected_inventory_face_indices.clear()
	fusion_mode = false
	update_begin_expedition_button_visibility()
	update_fuse_button_text()
	
func refresh_edit_dice_panel():
	print("Refreshing editor. Dice:", owned_dice.size(), " Faces:", face_inventory.size())
	rebuild_owned_dice_grid()

	clear_container(die_faces_container)
	clear_container(inventory_faces_container)

	update_volatile_core_button()
	rebuild_face_inventory_grid()

	if selected_edit_die == null:
		return

	if selected_edit_die.sides >= 20:
		die_faces_container.columns = 3
	elif selected_edit_die.sides >= 10:
		die_faces_container.columns = 2
	else:
		die_faces_container.columns = 1

	for i in selected_edit_die.faces.size():
		var face := selected_edit_die.faces[i]

		var face_button = equipped_face_button_scene.instantiate()
		die_faces_container.add_child(face_button)

		face_button.setup(face, i, i == selected_die_face_index)
		
	
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
		"miss",
		"freeze",
		"bleed",
		"twist_knife",
		"break_focus"
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

	
func clear_container(container: Control):
	if container == null:
		push_error("clear_container received null.")
		return

	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
		
func fuse_selected_faces():
	# Equipped face + inventory face.
	if selected_edit_die != null and selected_die_face_index != -1 and selected_inventory_face_indices.size() == 1:
		var inventory_index: int = selected_inventory_face_indices[0]

		if inventory_index < 0 or inventory_index >= face_inventory.size():
			end_fusion_mode()
			refresh_edit_dice_panel()
			return

		var equipped_face: DiceFace = selected_edit_die.faces[selected_die_face_index]
		var inventory_face: DiceFace = face_inventory[inventory_index]

		if !can_fuse_faces(equipped_face, inventory_face):
			end_fusion_mode()
			refresh_edit_dice_panel()
			return

		var new_face := create_fused_face(equipped_face, inventory_face)
		var max_allowed_value := get_max_face_value_for_die(selected_edit_die, new_face)

		if new_face.value > max_allowed_value:
			end_fusion_mode()
			refresh_edit_dice_panel()
			return

		selected_edit_die.faces[selected_die_face_index] = new_face
		face_inventory.remove_at(inventory_index)

		end_fusion_mode()
		refresh_edit_dice_panel()
		return

	# Inventory face + inventory face.
	if selected_inventory_face_indices.size() != 2:
		end_fusion_mode()
		refresh_edit_dice_panel()
		return

	var index_a: int = selected_inventory_face_indices[0]
	var index_b: int = selected_inventory_face_indices[1]

	if index_a == index_b:
		end_fusion_mode()
		refresh_edit_dice_panel()
		return

	if index_a < 0 or index_a >= face_inventory.size():
		end_fusion_mode()
		refresh_edit_dice_panel()
		return

	if index_b < 0 or index_b >= face_inventory.size():
		end_fusion_mode()
		refresh_edit_dice_panel()
		return

	var face_a: DiceFace = face_inventory[index_a]
	var face_b: DiceFace = face_inventory[index_b]

	if !can_fuse_faces(face_a, face_b):
		end_fusion_mode()
		refresh_edit_dice_panel()
		return

	var new_face: DiceFace = create_fused_face(face_a, face_b)

	selected_inventory_face_indices.sort()
	selected_inventory_face_indices.reverse()

	for index in selected_inventory_face_indices:
		face_inventory.remove_at(index)

	face_inventory.append(new_face)
	AudioManager.play_one_shot(graft_face_sound)
	end_fusion_mode()
	refresh_edit_dice_panel()
	
func select_edit_die(die_data: DiceData):
	selected_edit_die = die_data
	AudioManager.play_ui(ui_click_sound)
	refresh_edit_dice_panel()
	update_volatile_core_button()
	
func update_volatile_core_button():
	var base_text := "Apply Volatile Core (" + str(volatile_cores) + ")"
	apply_volatile_core_button.text = base_text

	if selected_edit_die == null:
		apply_volatile_core_button.disabled = true
		return

	if selected_edit_die.sides <= 4:
		apply_volatile_core_button.disabled = true
		apply_volatile_core_button.text = "D4 Cannot Explode (" + str(volatile_cores) + ")"
		return

	if selected_edit_die.can_explode:
		apply_volatile_core_button.disabled = true
		apply_volatile_core_button.text = "Already Exploding (" + str(volatile_cores) + ")"
		return

	if volatile_cores <= 0:
		apply_volatile_core_button.disabled = true
		return

	apply_volatile_core_button.disabled = false
	
func get_max_face_value_for_die(die_data: DiceData, face: DiceFace) -> int:
	if face.result_type == "crit":
		return die_data.sides

	return int(die_data.sides / 2)
	
func can_fuse_faces(face_a: DiceFace, face_b: DiceFace) -> bool:
	if face_a.result_type == "dodge" and face_b.result_type == "dodge":
		return false
	
	
	if face_a.result_type == "reversal" and face_b.result_type == "reversal":
		return false
		
	if face_a.result_type == "twist_knife" and face_b.result_type == "twist_knife":
		return false	
		
	if face_a.result_type == "miss" and face_b.result_type == "miss":
		if selected_edit_die != null:
			for face in selected_edit_die.faces:
				if face.result_type == "dodge":
					print("This die already has a Dodge face.")
					return false

		return true
		
	if face_a.result_type == "break_focus" and face_b.result_type == "break_focus":
		return false
		
	if (face_a.result_type == "dodge" and face_b.result_type == "crit") or (face_a.result_type == "crit" and face_b.result_type == "dodge"):
		return true

	if face_a.result_type == "miss" or face_b.result_type == "miss":
		return false
		
	if (face_a.result_type == "crit" and face_b.result_type == "bleed") \
		or (face_a.result_type == "bleed" and face_b.result_type == "crit"):
			return true
	
	if (face_a.result_type == "crit" and face_b.result_type == "heal") \
		or (face_a.result_type == "heal" and face_b.result_type == "crit"):
			return true
			
	if (face_a.result_type == "crit" and face_b.result_type == "heal") \
	or (face_a.result_type == "heal" and face_b.result_type == "crit"):
		return true
		
	if face_a.result_type != face_b.result_type:
		return false

	if face_a.value != face_b.value:
		return false
	
	return true

func create_fused_face(face_a: DiceFace, face_b: DiceFace) -> DiceFace:
	if face_a.result_type == "miss" and face_b.result_type == "miss":
		return create_dodge_face()

	if (face_a.result_type == "dodge" and face_b.result_type == "crit") \
	or (face_a.result_type == "crit" and face_b.result_type == "dodge"):
		return create_reversal_face()

	if (face_a.result_type == "crit" and face_b.result_type == "bleed") \
	or (face_a.result_type == "bleed" and face_b.result_type == "crit"):
		return create_twist_knife_face()

	var new_face: DiceFace = face_a.duplicate(true)
	new_face.value += 1
	new_face.face_name = "Face"
	
	if (face_a.result_type == "crit" and face_b.result_type == "heal") \
	or (face_a.result_type == "heal" and face_b.result_type == "crit"):
		return create_break_focus_face()
	
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
	
func refresh_die_crafting_panel():
	fragment_label.text = "Die Fragments: " + str(die_fragments)

	update_craft_button(d4_button, 4)
	update_craft_button(d6_button, 6)
	update_craft_button(d8_button, 8)
	update_craft_button(d10_button, 10)
	update_craft_button(d12_button, 12)
	update_craft_button(d20_button, 20)
	
func update_craft_button(button: TextureButton, cost: int):
	var affordable := die_fragments >= cost

	button.disabled = !affordable

	if affordable:
		button.modulate = Color(1, 1, 1)
	else:
		button.modulate = Color(0.35, 0.35, 0.35)
		
		
func craft_empty_die(sides: int):
	if die_fragments < sides:
		return

	die_fragments -= sides

	var new_die := DiceData.new()
	new_die.die_name = "Empty D" + str(sides)
	new_die.sides = sides

	for i in sides:
		new_die.faces.append(miss_face_template.duplicate(true))

	owned_dice.append(new_die)

	refresh_die_crafting_panel()
	refresh_edit_dice_panel()
	
func create_twist_knife_face() -> DiceFace:
	return twist_knife_face_template.duplicate(true)
	var face := DiceFace.new()
	
func create_break_focus_face() -> DiceFace:
	var face := DiceFace.new()
	face.face_name = "Break Focus"
	face.result_type = "break_focus"
	face.value = 0
	face.icon = break_focus_face_template.icon
	return face

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
# Different equipped face selected.
	selected_die_face_index_2 = face_index

	var face_a: DiceFace = selected_edit_die.faces[selected_die_face_index]
	var face_b: DiceFace = selected_edit_die.faces[selected_die_face_index_2]

	if fusion_mode and can_fuse_faces(face_a, face_b):
		var fused_face := create_fused_face(face_a, face_b)
		var max_allowed_value := get_max_face_value_for_die(selected_edit_die, fused_face)

		if fused_face.value <= max_allowed_value:
			selected_edit_die.faces[selected_die_face_index] = fused_face
			selected_edit_die.faces[selected_die_face_index_2] = create_miss_face()

		end_fusion_mode()
		refresh_edit_dice_panel()
		return

	# Normal behavior: swap equipped faces.
	var temp_face: DiceFace = selected_edit_die.faces[selected_die_face_index]
	selected_edit_die.faces[selected_die_face_index] = selected_edit_die.faces[selected_die_face_index_2]
	selected_edit_die.faces[selected_die_face_index_2] = temp_face

	selected_die_face_index = -1
	selected_die_face_index_2 = -1

	refresh_edit_dice_panel()


func install_inventory_face(inventory_index: int):
	if selected_edit_die == null:
		return

	if selected_die_face_index == -1:
		return

	if inventory_index < 0 or inventory_index >= face_inventory.size():
		return

	var new_face: DiceFace = face_inventory[inventory_index]

	if new_face.result_type == "dodge":
		if die_has_dodge(selected_edit_die):
			return

	var max_allowed_value := get_max_face_value_for_die(selected_edit_die, new_face)

	if new_face.value > max_allowed_value:
		return

	var old_face: DiceFace = selected_edit_die.faces[selected_die_face_index]

	selected_edit_die.faces[selected_die_face_index] = new_face
	face_inventory[inventory_index] = old_face

	AudioManager.play_one_shot(graft_face_sound)

	selected_die_face_index = -1

	call_deferred("refresh_edit_dice_panel")
	
func die_has_dodge(die: DiceData) -> bool:
	for face in die.faces:
		if face.result_type == "dodge":
			return true

	return false
	
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
		misses_container,
		actions_container
	]

	for container in containers:
		for child in container.get_children():
			container.remove_child(child)
			child.queue_free()

	dice_nodes.clear()

# RELIC FUNCTIONALITY ###################################################
func apply_end_round_relics():
	if has_relic("Meditation Beads"):
		var heal_amount := get_reserved_die_count()

		if heal_amount <= 0:
			return

		player_hp = min(player_hp + heal_amount, combat_max_player_hp)

		show_popup_text(
			player_3d_node,
			"+" + str(heal_amount),
			1.2,
			Color.GREEN
		)

		add_combat_log_entry(
			"Meditation Beads restored " +
			str(heal_amount) +
			" HP."
		)

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
	var reserved := get_reserved_die_count()
	reserve_slots_label.text = str(reserved) + "/" + str(reserve_slots)
	
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

		var offset := Vector2(-85, 140)
		panel.global_position = screen_pos + offset
		

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

	if die.current_face == null:
		return

	var enemy = active_enemies[enemy_index]
	var enemy_node = enemy_3d_nodes[enemy_index]

	if !is_instance_valid(enemy_node):
		return

	await launch_die_at_enemy(die, enemy_index)

	match die.current_face.result_type:
		"dodge":
			if !dodge_targets.has(enemy_index):
				dodge_targets.append(enemy_index)

			add_combat_log_entry("Dodging crits from " + enemy["data"].enemy_name + ".")
			return

		"reversal":
			if !reversal_targets.has(enemy_index):
				reversal_targets.append(enemy_index)

			add_combat_log_entry("Reversing crits from " + enemy["data"].enemy_name + ".")
			return

		"break_focus":
			if !break_focus_targets.has(enemy_index):
				break_focus_targets.append(enemy_index)

			show_popup_text(enemy_node, "Break Focus", 1.2, Color.PURPLE)
			add_combat_log_entry("Break Focus will cancel " + enemy["data"].enemy_name + "'s healing.")
			return

		"freeze":
			enemy["frozen"] = true
			enemy["freeze_stacks"] += die.current_face.value

			show_popup_text(enemy_node, "Frozen +" + str(die.current_face.value), 1.2, Color.CYAN)
			add_combat_log_entry(enemy["data"].enemy_name + " gains " + str(die.current_face.value) + " Freeze stacks.")

			update_enemy_3d_nodes()
			return

		"bleed":
			if enemy["block"] > 0:
				show_popup_text(enemy_node, "Blocked Bleed", 1.0, Color.GRAY)
				add_combat_log_entry(enemy["data"].enemy_name + "'s block stopped Bleed.")
				AudioManager.play_one_shot(hit_blocked_sound, 0.9, 1.1)
				update_enemy_3d_nodes()
				return
			AudioManager.play_one_shot(hit_damage_sound, 0.9, 1.1)
			enemy["bleed"] += die.current_face.value

			show_popup_text(enemy_node, "Bleed +" + str(die.current_face.value), 1.2, Color.RED)
			add_combat_log_entry(enemy["data"].enemy_name + " gains " + str(die.current_face.value) + " bleed.")

			update_enemy_3d_nodes()
			return

		"twist_knife":
			var bleed_value: int = enemy.get("bleed", 0)

			if bleed_value <= 0:
				show_popup_text(enemy_node, "No Bleed", 1.0, Color.GRAY)
				return
			
			enemy["bleed"] = 0
			enemy["hp"] -= bleed_value
			last_player_damage += bleed_value
			AudioManager.play_one_shot(hit_damage_sound, 0.9, 1.1)
			if enemy["hp"] < 0:
				enemy["hp"] = 0

			show_damage_popup(enemy_node, bleed_value)
			add_combat_log_entry("Twist Knife consumed " + str(bleed_value) + " bleed.")

			update_enemy_3d_nodes()
			return

		"crit":
			var damage := die.current_face.value

			enemy["hp"] -= damage
			enemy["exposed"] = true
			last_player_damage += damage

			if enemy["hp"] < 0:
				enemy["hp"] = 0

			AudioManager.play_one_shot(critical_hit_sound, 0.85, 1.15)
			show_popup_text(enemy_node, "-" + str(damage), 1.7, Color.GOLD)
			show_popup_text(enemy_node, "EXPOSED", 2.2, Color.YELLOW)
			enemy_node.hit_flash()
			enemy_node.hurt_bump()
			screen_shake(0.07, 0.1)
			await hit_stop(0.03)

			update_enemy_3d_nodes()
			return

		"hit":
			var hit_value: int = die.current_face.value + active_combat_bonus_damage
			var exposed_bonus := 0

			if enemy["exposed"]:
				exposed_bonus = 1
				enemy["exposed"] = false
				show_popup_text(enemy_node, "EXPOSED +1", 2.2, Color.YELLOW)
			if has_relic("Bloodstone"):
				enemy["bleed"] += 1
			if has_relic("Frozen Heart"):
				enemy["freeze_stacks"] += 1
			var blocked_amount: int = min(hit_value, enemy["block"])
			var normal_damage_after_block: int = hit_value - blocked_amount
			var total_damage_to_hp: int = normal_damage_after_block + exposed_bonus
			var damage := hit_value

			if has_relic("Executioner's Axe") and enemy["bleed"] > 0:
				damage += 2
			enemy["block"] -= blocked_amount
			if enemy["block"] < 0:
				enemy["block"] = 0

			if blocked_amount > 0:
				await show_enemy_hit_sequence(enemy_index, blocked_amount, 0)

			if total_damage_to_hp > 0:
				enemy["hp"] -= total_damage_to_hp
				last_player_damage += total_damage_to_hp

				if enemy["hp"] < 0:
					enemy["hp"] = 0

				await show_enemy_hit_sequence(enemy_index, 0, total_damage_to_hp)

				if normal_damage_after_block > 0:
					var spiked_value := get_enemy_trait_value(enemy, "spiked")

					if spiked_value > 0:
						player_hp -= spiked_value

						if player_hp < 0:
							player_hp = 0

						show_damage_popup(player_3d_node, spiked_value)
						add_combat_log_entry(enemy["data"].enemy_name + "'s spikes dealt " + str(spiked_value) + " damage.")
						update_player_hp_label()

						if player_hp <= 0:
							lose_combat()
							return

			update_enemy_3d_nodes()
			return

		_:
			update_enemy_3d_nodes()
			return
			
func apply_enemy_bleed():
	for i in active_enemies.size():
		var enemy = active_enemies[i]

		if enemy["bleed"] <= 0:
			continue
		if enemy["block"] > 0:
			AudioManager.play_one_shot(hit_blocked_sound, 0.95, 1.05)

			if i < enemy_3d_nodes.size() and is_instance_valid(enemy_3d_nodes[i]):
				show_popup_text(enemy_3d_nodes[i], "Blocked Bleed", 1.0, Color.CORNFLOWER_BLUE)

			enemy["bleed"] -= 1
			if enemy["bleed"] < 0:
				enemy["bleed"] = 0

			update_enemy_3d_nodes()
			await get_tree().create_timer(0.35).timeout
			continue
		var bleed_damage: int = enemy["bleed"]
		enemy["hp"] -= bleed_damage
		AudioManager.play_one_shot(hit_damage_sound, 0.9, 1.1)
		if enemy["hp"] < 0:
			enemy["hp"] = 0

		if i < enemy_3d_nodes.size() and is_instance_valid(enemy_3d_nodes[i]):
			show_damage_popup(enemy_3d_nodes[i], bleed_damage)

		add_combat_log_entry(enemy["data"].enemy_name + " takes " + str(bleed_damage) + " bleed damage.")

		enemy["bleed"] -= 1

		if enemy["bleed"] < 0:
			enemy["bleed"] = 0
		await get_tree().create_timer(0.35).timeout
		
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
	die_crafting_panel.visible = true
	refresh_die_crafting_panel()
	update_begin_expedition_button_visibility()
	refresh_edit_dice_panel()

func rest_at_town():
	player_statuses["bleed"] = 0
	update_player_status_icons()

	player_hp = max_player_hp
	update_player_hp_label()
	

func start_expedition():
	if current_bounty == null:
		return

	combat_number = 0
	expedition_progress = 0
	expedition_is_boss_fight = false
	expedition_required_encounters = randi_range(
		current_bounty.min_encounters_before_boss,
		current_bounty.max_encounters_before_boss
	)
	print("Rolled required encounters: ", expedition_required_encounters)
	current_encounter = current_bounty.expedition_encounter_pool.pick_random()
	start_new_combat()

func open_bounty_board():
	town_panel.visible = false
	bounty_board_panel.visible = true
	rebuild_bounty_board()
	update_begin_expedition_button_visibility()
	
func close_bounty_board():
	bounty_board_panel.visible = false
	town_menu_closed.emit()
	update_begin_expedition_button_visibility()
	
func rebuild_bounty_board():
	clear_container(bounty_buttons_container)

	for bounty in bounty_pool:
		if bounty.completed:
			continue

		var button: BountyButton = bounty_button_scene.instantiate()
		bounty_buttons_container.add_child(button)

		button.setup(bounty)
		button.pressed.connect(select_bounty.bind(bounty))
		if final_boss_unlocked:
			final_boss_button.text = "Final Boss"
			final_boss_button.disabled = false
		else:
			final_boss_button.text = "Final Boss Locked (" + str(completed_bounties.size()) + "/" + str(required_bounties_for_final_boss) + ")"
			final_boss_button.disabled = true
			
func select_final_boss_bounty():
	if !final_boss_unlocked:
		return

	if final_boss_bounty == null:
		print("Final boss bounty is not assigned.")
		return

	select_bounty(final_boss_bounty)
	town_menu_closed.emit()
	
func select_bounty(bounty: BountyData):
	current_bounty = bounty

	selected_bounty_label.text = "(" + bounty.bounty_name + ")"
	prepare_selected_bounty_label.text = "Bounty: " + bounty.bounty_name

	bounty_board_panel.visible = false
	town_panel.visible = false
	town_menu_closed.emit()
	print("Selected bounty: ", bounty.bounty_name)
	update_begin_expedition_button_visibility()
	
func complete_current_bounty():
	if current_bounty != null and !completed_bounties.has(current_bounty):
		completed_bounties.append(current_bounty)
	if completed_bounties.size() >= required_bounties_for_final_boss:
		final_boss_unlocked = true
	apply_bounty_reward(current_bounty)
	roll_merchant_stock()
	current_bounty.completed = true
	for face in current_bounty.unlocked_merchant_faces:
		if !merchant_unlocked_faces.has(face):
			merchant_unlocked_faces.append(face)
	for relic in current_bounty.unlocked_relics:
		if !owned_relics.has(relic):
			owned_relics.append(relic)
			last_unlocked_relics.append(relic)
	if all_bounties_completed():
		show_endless_choice()
	# refresh_relic_panel()
	current_bounty = null
	expedition_is_boss_fight = false
	expedition_progress = 0

	player_hp = max_player_hp
	update_player_hp_label()

	shop_panel.visible = false
	loot_panel.visible = false
	edit_dice_panel.visible = false
	selected_bounty_label.text = "No Bounty Selected"
	
	print("Bounty completed. Returned to town.")
	return_to_town_requested.emit()
	
func apply_bounty_reward(bounty: BountyData):
	if bounty.reward_food_tier_unlock > unlocked_food_tier:
		unlocked_food_tier = bounty.reward_food_tier_unlock
		print("Food tier unlocked: ", unlocked_food_tier)

	if bounty.reward_volatile_cores > 0:
		volatile_cores += bounty.reward_volatile_cores
		update_volatile_core_button()

	if bounty.reward_gold > 0:
		gold += bounty.reward_gold
		update_gold_label()

	if bounty.reward_reserve_slots > 0:
		reserve_slots += bounty.reward_reserve_slots
		update_reserve_slots_label()
		
	for relic in current_bounty.unlocked_relics:
		if !owned_relics.has(relic):
			owned_relics.append(relic)
			# refresh_relic_panel()
func show_expedition_camp():
	expedition_camp_panel.visible = true
	$DiceArea/ReserveHBox.visible = false
	update_expedition_progress_labels()
	camp_hp_label.text = "HP: " + str(player_hp) + "/" + str(combat_max_player_hp)
	hide_combat_dice()
	update_camp_hp_label()
	
func hide_combat_dice():
	for die in dice_nodes:
		if is_instance_valid(die):
			die.visible = false

	hide_all_groups()
	
func open_edit_dice_panel_from_camp():
	edit_dice_return_context = "camp"
	expedition_camp_panel.visible = false
	edit_dice_panel.visible = true
	die_crafting_panel.visible = false
	refresh_edit_dice_panel()
	
func continue_expedition():
	expedition_camp_panel.visible = false
	expedition_progress += 1

	if expedition_progress < expedition_required_encounters:
		current_encounter = current_bounty.expedition_encounter_pool.pick_random()
	else:
		expedition_is_boss_fight = true
		current_encounter = current_bounty.boss_encounter

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
	update_begin_expedition_button_visibility()
func close_trophies():
	trophy_panel.visible = false
	town_panel.visible = true
	update_begin_expedition_button_visibility()
	
func open_prepare_expedition():
	if current_bounty == null:
		print("No bounty selected.")
		return

	prepare_return_context = "town"
	town_panel.visible = false
	prepare_selected_bounty_label.visible = true
	prepare_expedition_panel.visible = true
	prepare_cancel_button.visible = true
	prepare_start_expedition_button.text = "Start Expedition"
	prepare_selected_bounty_label.text = "Bounty: " + current_bounty.bounty_name
	prepare_expedition_label.text = "Prepare Expedition"
	prepare_selected_bounty_label.text = \
		"Bounty: " + current_bounty.bounty_name + \
		"\nEncounters: " + str(current_bounty.min_encounters_before_boss) + "-" + str(current_bounty.max_encounters_before_boss)
	rebuild_prepare_consumables()
	update_begin_expedition_button_visibility()
	
func cancel_prepare_expedition():
	prepare_expedition_panel.visible = false

	if prepare_return_context == "camp":
		expedition_camp_panel.visible = true

	prepare_return_context = "town"
	update_begin_expedition_button_visibility()
	
func confirm_start_expedition():
	prepare_expedition_panel.visible = false

	if prepare_return_context == "camp":
		expedition_camp_panel.visible = true
		prepare_return_context = "town"
		return

	prepare_return_context = "town"
	expedition_started.emit()
	
func roll_merchant_stock():
	merchant_food_stock.clear()

	var available_foods: Array[ConsumableItem] = []
	current_merchant_relic = null

	if merchant_relic_pool.size() > 0:
		if randf() <= 0.20:
			current_merchant_relic = merchant_relic_pool.pick_random()
	for item in merchant_food_pool:
		if item.food_tier <= unlocked_food_tier:
			available_foods.append(item)

	available_foods.shuffle()

	for i in min(4, available_foods.size()):
		merchant_food_stock.append(available_foods[i])

func open_merchant():
	town_panel.visible = false
	merchant_panel.visible = true
	merchant_gold_label.text = "Gold: " + str(gold)
	update_begin_expedition_button_visibility()
	rebuild_merchant()

func close_merchant():
	merchant_panel.visible = false
	update_begin_expedition_button_visibility()
	town_menu_closed.emit()

func rebuild_merchant():
	clear_container(merchant_stock_container)

	merchant_gold_label.text = "Gold: " + str(gold)

	var merchant_entries := []

	for item in merchant_food_stock:
		merchant_entries.append(item)

	if current_merchant_relic != null:
		merchant_entries.append(current_merchant_relic)

	for entry in merchant_entries:
		if entry is ConsumableItem:
			var owned_count := get_consumable_count(entry)

			var button = item_button_scene.instantiate()
			merchant_stock_container.add_child(button)

			button.setup(
				entry.icon,
				"x" + str(owned_count),
				str(entry.cost) + "g"
			)

			button.tooltip_text = entry.item_name + "\n" + entry.description
			button.disabled = gold < entry.cost
			button.pressed.connect(buy_consumable.bind(entry))

		elif entry is RelicData:
			var button = item_button_scene.instantiate()
			merchant_stock_container.add_child(button)
			
			button.setup(
				entry.icon,
				"",
				str(merchant_relic_cost) + "g"
			)

			button.tooltip_text = entry.relic_name + "\n" + entry.description
			button.disabled = gold < merchant_relic_cost
			button.pressed.connect(buy_merchant_relic)
			print("Merchant relic: ", entry.relic_name)
			print("Merchant relic icon: ", entry.icon)
	for face in merchant_unlocked_faces:
		var button = inventory_face_button_scene.instantiate()
		merchant_stock_container.add_child(button)

		button.setup(face, false)

		var price_label := button.get_node_or_null("PriceLabel")
		if price_label != null:
			price_label.text = str(merchant_face_cost) + "g"

		button.tooltip_text = get_face_display_name(face) + "\nCost: " + str(merchant_face_cost) + "g"
		button.pressed.connect(buy_merchant_face.bind(face))
		
func buy_merchant_relic():
	if current_merchant_relic == null:
		return

	if gold < merchant_relic_cost:
		return

	gold -= merchant_relic_cost

	if !has_relic_name(current_merchant_relic.relic_name):
		owned_relics.append(current_merchant_relic)

	current_merchant_relic = null

	AudioManager.play_ui(coin_purchase_sound)
	update_gold_label()
	update_active_food_icons()
	rebuild_merchant()
	save_run()
	
func has_relic_name(relic_name: String) -> bool:
	for relic in owned_relics:
		if relic != null and relic.relic_name == relic_name:
			return true

	return false
	
func buy_merchant_face(face: DiceFace):
	if gold < merchant_face_cost:
		return
	
	gold -= merchant_face_cost
	face_inventory.append(face.duplicate(true))

	AudioManager.play_ui(coin_purchase_sound)
	update_gold_label()
	rebuild_merchant()

func sell_face(face: DiceFace):
	if face == null:
		return

	if !face_inventory.has(face):
		return

	face_inventory.erase(face)
	gold += get_face_sell_value(face)

	update_gold_label()
	refresh_edit_dice_panel()
	save_run()
	
func get_face_sell_value(face: DiceFace) -> int:
	match face.result_type:
		"miss":
			return 1
		"hit", "block", "heal", "gold":
			return max(2, face.value)
		"crit", "bleed", "freeze":
			return max(3, face.value)
		"dodge", "reversal", "twist_knife", "break_focus":
			return 8
		_:
			return 2
			
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
	play_purchase_sound()
	consumable_inventory.append(item.duplicate(true))

	AudioManager.play_ui(ui_click_sound)
	merchant_gold_label.text = "Gold: " + str(gold)
	update_gold_label()
	rebuild_merchant()
	
func rebuild_prepare_consumables():
	clear_container(prepare_consumables_container)

	var item_counts := {}
	var item_lookup := {}

	for item in consumable_inventory:
		if !item_counts.has(item.item_name):
			item_counts[item.item_name] = 0
			item_lookup[item.item_name] = item

		item_counts[item.item_name] += 1

	for item_name in item_counts.keys():
		var item: ConsumableItem = item_lookup[item_name]

		var button = item_button_scene.instantiate()
		prepare_consumables_container.add_child(button)

		button.setup(
			item.icon,
			"x" + str(item_counts[item_name]),
			""
		)

		button.tooltip_text = item.item_name + "\n" + item.description
		button.pressed.connect(use_consumable_item.bind(item))
		
func use_consumable(index: int):
	if index < 0 or index >= consumable_inventory.size():
		return

	var item := consumable_inventory[index]

	player_hp += item.heal_amount
	if player_hp > max_player_hp:
		player_hp = max_player_hp
	camp_hp_label.text = "HP: " + str(player_hp) + "/" + str(combat_max_player_hp)
	next_combat_bonus_block += item.next_combat_block
	next_combat_bonus_damage += item.next_combat_damage

	consumable_inventory.remove_at(index)
	update_camp_hp_label()
	update_player_hp_label()
	rebuild_prepare_consumables()
	
func use_consumable_item(item: ConsumableItem):
	var index := find_consumable_index_by_name(item.item_name)

	if index == -1:
		return
	AudioManager.play_one_shot(food_eat_sound)
	# Instant heal food: can be used multiple times, does not become an active buff.
	if item.heal_amount > 0 and item.next_combat_block == 0 and item.next_combat_damage == 0 and item.next_combat_max_hp == 0:
		player_hp += item.heal_amount

		if player_hp > combat_max_player_hp:
			player_hp = combat_max_player_hp

		consumable_inventory.remove_at(index)
		update_player_hp_label()
		rebuild_prepare_consumables()
		return

	# Buff food: only one of each active at a time.
	if is_food_already_active(item):
		return

	active_food_items.append(item)
	if item.grants_trait != null:
		player_statuses[item.grants_trait.trait_id] = item.grants_trait.value
		update_player_status_icons()
	next_combat_bonus_block += item.next_combat_block
	next_combat_bonus_damage += item.next_combat_damage
	next_combat_bonus_max_hp += item.next_combat_max_hp
	player_hp += item.next_combat_max_hp
	combat_max_player_hp = max_player_hp + next_combat_bonus_max_hp
	update_player_hp_label()
	var temporary_max_hp := max_player_hp + next_combat_bonus_max_hp

	if player_hp > temporary_max_hp:
		player_hp = temporary_max_hp

	consumable_inventory.remove_at(index)

	rebuild_prepare_consumables()
	update_active_food_icons()

func find_consumable_index_by_name(item_name: String) -> int:
	for i in consumable_inventory.size():
		if consumable_inventory[i].item_name == item_name:
			return i

	return -1
	
func is_food_already_active(item: ConsumableItem) -> bool:
	for active_item in active_food_items:
		if active_item.item_name == item.item_name:
			return true

	return false
	
func handle_face_drop(data: Dictionary, target_slot_index: int):
	clear_drag_fusion_preview()

	if selected_edit_die == null:
		return

	if !data.has("source_type") or !data.has("face"):
		return

	if target_slot_index < 0 or target_slot_index >= selected_edit_die.faces.size():
		return

	var source_type: String = data["source_type"]

	match source_type:
		"inventory":
			var dragged_face: DiceFace = data["face"]

			if dragged_face == null:
				return

			if !face_inventory.has(dragged_face):
				return

			var target_face: DiceFace = selected_edit_die.faces[target_slot_index]

			if target_face == null:
				target_face = create_basic_miss_face()

			if can_fuse_faces(dragged_face, target_face):
				var fused_face: DiceFace = create_fused_face(dragged_face, target_face)

				if fused_face == null:
					return

				selected_edit_die.faces[target_slot_index] = fused_face
				face_inventory.erase(dragged_face)

				AudioManager.play_one_shot(graft_face_sound)
			else:
				selected_edit_die.faces[target_slot_index] = dragged_face
				face_inventory.erase(dragged_face)
				face_inventory.append(target_face)

				AudioManager.play_one_shot(graft_face_sound)

		"equipped":
			if !data.has("slot"):
				return

			var source_slot: int = data["slot"]

			if source_slot < 0 or source_slot >= selected_edit_die.faces.size():
				return

			if source_slot == target_slot_index:
				return

			var source_face: DiceFace = selected_edit_die.faces[source_slot]
			var target_face: DiceFace = selected_edit_die.faces[target_slot_index]

			if source_face == null:
				source_face = create_basic_miss_face()

			if target_face == null:
				target_face = create_basic_miss_face()

			if can_fuse_faces(source_face, target_face):
				var fused_face: DiceFace = create_fused_face(source_face, target_face)

				if fused_face == null:
					return

				selected_edit_die.faces[target_slot_index] = fused_face
				selected_edit_die.faces[source_slot] = create_basic_miss_face()

				AudioManager.play_one_shot(graft_face_sound)
			else:
				selected_edit_die.faces[source_slot] = target_face
				selected_edit_die.faces[target_slot_index] = source_face

	refresh_edit_dice_panel()
	save_run()
	
func handle_inventory_face_drop(data: Dictionary, target_inventory_face: DiceFace):
	clear_drag_fusion_preview()

	if selected_edit_die == null:
		return

	if !data.has("source_type") or !data.has("face"):
		return

	if String(data["source_type"]) != "equipped":
		return

	if !data.has("slot"):
		return

	var source_slot: int = data["slot"]

	if source_slot < 0 or source_slot >= selected_edit_die.faces.size():
		return

	var equipped_face: DiceFace = selected_edit_die.faces[source_slot]

	if equipped_face == null:
		equipped_face = create_basic_miss_face()

	if target_inventory_face == null:
		return

	if !face_inventory.has(target_inventory_face):
		return

	if can_fuse_faces(equipped_face, target_inventory_face):
		var fused_face: DiceFace = create_fused_face(equipped_face, target_inventory_face)

		if fused_face == null:
			return

		selected_edit_die.faces[source_slot] = fused_face
		face_inventory.erase(target_inventory_face)

		AudioManager.play_one_shot(graft_face_sound)
	else:
		selected_edit_die.faces[source_slot] = target_inventory_face
		face_inventory.erase(target_inventory_face)
		face_inventory.append(equipped_face)

		AudioManager.play_one_shot(graft_face_sound)

	refresh_edit_dice_panel()
	save_run()
	
func create_basic_miss_face() -> DiceFace:
	if miss_face_template != null:
		return miss_face_template.duplicate(true)

	var face := DiceFace.new()
	face.face_name = "Miss"
	face.result_type = "miss"
	face.value = 0
	face.label = "Miss"
	return face
	
func update_drag_fusion_preview(dragged_face: DiceFace):
	for child in die_faces_container.get_children():
		if !(child is EquippedFaceButton):
			continue

		if child.face_data == null:
			child.set_drop_state("swap")
			continue

		if can_fuse_faces(dragged_face, child.face_data):
			child.set_drop_state("fuse")
		else:
			child.set_drop_state("invalid")
	
func clear_drag_fusion_preview():
	for child in die_faces_container.get_children():
		if child is EquippedFaceButton:
			child.set_drop_state("normal")
			
func update_active_food_icons():
	for child in active_food_container.get_children():
		child.queue_free()

	# Food buffs
	for food in active_food_items:
		var icon = active_buff_icon_scene.instantiate()
		icon.setup(
			food.icon,
			food.item_name + "\n" + food.description
		)
		active_food_container.add_child(icon)

	# Relics
	for relic in owned_relics:
		var icon = active_buff_icon_scene.instantiate()
		icon.setup(
			relic.icon,
			relic.relic_name + "\n" + relic.description
		)
		active_food_container.add_child(icon)
		
func open_camp_items():
	prepare_return_context = "camp"
	prepare_selected_bounty_label.visible = false
	expedition_camp_panel.visible = false
	prepare_expedition_panel.visible = true
	prepare_cancel_button.visible = false
	prepare_start_expedition_button.text = "Return to Camp"
	prepare_expedition_label.text = "Use Items"
	if current_bounty != null:
		prepare_selected_bounty_label.text = "Bounty: " + current_bounty.bounty_name
	else:
		prepare_selected_bounty_label.text = "Expedition Items"

	rebuild_prepare_consumables()

func apply_damage_bonus_to_dice_visuals():
	for die in dice_nodes:
		if !is_instance_valid(die):
			continue

		die.temporary_value_bonus = active_combat_bonus_damage
		die.update_visual()


func get_enemy_trait_text(enemy: Dictionary) -> String:
	var data: EnemyData = enemy["data"]
	var parts := []

	for enemy_trait in data.traits:
		parts.append(enemy_trait.trait_name + " " + str(enemy_trait.value))

	return ", ".join(parts)
	
func apply_enemy_end_round_traits():
	for enemy in active_enemies:
		var regen_value := get_enemy_trait_value(enemy, "regenerating")

		if regen_value <= 0:
			continue

		enemy["hp"] += regen_value

		if enemy["hp"] > enemy["max_hp"]:
			enemy["hp"] = enemy["max_hp"]

		var enemy_index := active_enemies.find(enemy)

		if enemy_index != -1 and enemy_index < enemy_3d_nodes.size():
			if is_instance_valid(enemy_3d_nodes[enemy_index]):
				show_popup_text(
					enemy_3d_nodes[enemy_index],
					"+" + str(regen_value),
					1.8,
					Color.GREEN
				)

func show_status_tooltip(text: String):
	status_tooltip_label.text = text
	status_tooltip_panel.visible = true
	status_tooltip_panel.global_position = get_viewport().get_mouse_position() + Vector2(16, 16)

	status_tooltip_label.custom_minimum_size = Vector2(240, 0)
	status_tooltip_panel.custom_minimum_size = Vector2(260, 0)

func hide_status_tooltip():
	status_tooltip_panel.visible = false

func open_food_crafting():
	food_crafting_return_context = "camp"
	expedition_camp_panel.visible = false
	food_craft_panel.visible = true
	selected_food_craft_names.clear()
	update_begin_expedition_button_visibility()
	rebuild_food_crafting_grid()
	update_craft_result_label()
	
func close_food_crafting():
	food_craft_panel.visible = false
	selected_food_craft_names.clear()

	match food_crafting_return_context:
		"camp":
			expedition_camp_panel.visible = true

		"town":
			town_menu_closed.emit()

		_:
			town_menu_closed.emit()

	food_crafting_return_context = ""
	update_begin_expedition_button_visibility()
	
func rebuild_food_crafting_grid():
	clear_container(food_craft_items_container)

	var item_counts := {}
	var item_lookup := {}

	for item in consumable_inventory:
		if !item_counts.has(item.item_name):
			item_counts[item.item_name] = 0
			item_lookup[item.item_name] = item

		item_counts[item.item_name] += 1

	for item_name in item_counts.keys():
		var item: ConsumableItem = item_lookup[item_name]

		var button = item_button_scene.instantiate()
		food_craft_items_container.add_child(button)

		button.setup(item.icon, "x" + str(item_counts[item_name]), "")
		button.tooltip_text = item.item_name + "\n" + item.description
		if selected_food_craft_names.has(item_name):
			button.modulate = Color.YELLOW
		else:
			button.modulate = Color.WHITE

		button.pressed.connect(select_food_name_for_crafting.bind(item_name))

func select_food_for_crafting(index: int):
	if selected_food_craft_names.has(index):
		selected_food_craft_names.erase(index)
	else:
		if selected_food_craft_names.size() >= 2:
			selected_food_craft_names.clear()

		selected_food_craft_names.append(index)

	rebuild_food_crafting_grid()
	update_craft_result_label()

func update_craft_result_label():
	if selected_food_craft_names.size() != 2:
		craft_result_label.text = "Select 2 food items."
		craft_button.disabled = true
		return

	var recipe = get_matching_food_recipe()

	if recipe == null:
		craft_result_label.text = "No matching recipe."
		craft_button.disabled = true
		return

	craft_result_label.text = "Creates: " + recipe.result_item.item_name

	if recipe.result_item.description != "":
		craft_result_label.text += "\n" + recipe.result_item.description

	craft_button.disabled = false
	
func get_matching_food_recipe():
	if selected_food_craft_names.size() != 2:
		return null

	var name_a := selected_food_craft_names[0]
	var name_b := selected_food_craft_names[1]

	for recipe in food_recipes:
		if recipe == null:
			continue

		if recipe.ingredient_a == null or recipe.ingredient_b == null or recipe.result_item == null:
			continue

		var recipe_a := recipe.ingredient_a.item_name
		var recipe_b := recipe.ingredient_b.item_name

		var match_forward := recipe_a == name_a and recipe_b == name_b
		var match_reverse := recipe_a == name_b and recipe_b == name_a

		if match_forward or match_reverse:
			return recipe
	print("Selected:", name_a, " + ", name_b)

	for recipe in food_recipes:
		if recipe == null:
			continue

		print(
			"Recipe:",
			recipe.ingredient_a.item_name,
			"+",
			recipe.ingredient_b.item_name
		)
	return null
	
func craft_selected_food():
	var recipe = get_matching_food_recipe()

	if recipe == null:
		return

	remove_consumable_by_name(selected_food_craft_names[0])
	remove_consumable_by_name(selected_food_craft_names[1])

	consumable_inventory.append(recipe.result_item.duplicate(true))

	selected_food_craft_names.clear()
	selected_food_craft_names.clear()

	rebuild_food_crafting_grid()
	update_craft_result_label()
	rebuild_prepare_consumables()
	
func open_food_crafting_from_prepare():
	food_crafting_return_context = "camp"
	food_crafting_return_context = "prepare"

	prepare_expedition_panel.visible = false
	food_craft_panel.visible = true

	selected_food_craft_names.clear()
	update_begin_expedition_button_visibility()
	rebuild_food_crafting_grid()
	update_craft_result_label()

func select_food_name_for_crafting(item_name: String):
	if selected_food_craft_names.has(item_name):
		selected_food_craft_names.erase(item_name)
	else:
		if selected_food_craft_names.size() >= 2:
			selected_food_craft_names.clear()

		selected_food_craft_names.append(item_name)

	rebuild_food_crafting_grid()
	update_craft_result_label()
	
func remove_consumable_by_name(item_name: String):
	for i in consumable_inventory.size():
		if consumable_inventory[i].item_name == item_name:
			consumable_inventory.remove_at(i)
			return

func create_miss_face() -> DiceFace:
	if miss_face_template != null:
		return miss_face_template.duplicate(true)

	var miss := DiceFace.new()
	miss.face_name = "Miss"
	miss.result_type = "miss"
	miss.value = 0
	return miss
	
func create_dodge_face() -> DiceFace:
	if dodge_face_template != null:
		return dodge_face_template.duplicate(true)

	var dodge := DiceFace.new()
	dodge.face_name = "Dodge"
	dodge.result_type = "dodge"
	dodge.value = 0
	return dodge
	
func create_reversal_face() -> DiceFace:
	if reversal_face_template != null:
		return reversal_face_template.duplicate(true)

	var reversal := DiceFace.new()
	reversal.face_name = "Reversal"
	reversal.result_type = "reversal"
	reversal.value = 0
	return reversal

func end_fusion_mode():
	fusion_mode = false
	selected_inventory_face_indices.clear()
	selected_die_face_index = -1
	selected_die_face_index_2 = -1
	update_fuse_button_text()

func decay_enemy_statuses():
	for enemy in active_enemies:
		if enemy["freeze_stacks"] > 0:
			enemy["freeze_stacks"] -= 1

			if enemy["freeze_stacks"] < 0:
				enemy["freeze_stacks"] = 0
				

func apply_shatter_from_enemy(defeated_index: int):
	if defeated_index < 0 or defeated_index >= active_enemies.size():
		return

	var shatter_damage: int = active_enemies[defeated_index]["freeze_stacks"]

	if shatter_damage <= 0:
		return

	var defeated_name = active_enemies[defeated_index]["data"].enemy_name
	add_combat_log_entry(defeated_name + " shattered for " + str(shatter_damage) + " damage!")

	for i in active_enemies.size():
		if i == defeated_index:
			continue

		active_enemies[i]["hp"] -= shatter_damage

		if active_enemies[i]["hp"] < 0:
			active_enemies[i]["hp"] = 0

		if i < enemy_3d_nodes.size() and is_instance_valid(enemy_3d_nodes[i]):
			show_damage_popup(enemy_3d_nodes[i], shatter_damage)

func open_food_crafting_from_town():
	food_crafting_return_context = "town"
	food_craft_panel.visible = true
	selected_food_craft_names.clear()
	update_begin_expedition_button_visibility()
	rebuild_food_crafting_grid()
	update_craft_result_label()

func bind_world(world: Node3D):
	combat_camera = world.find_child("Camera3D", true, false)
	enemy_positions = world.find_child("EnemyPositions", true, false)
	player_position = world.find_child("PlayerPosition", true, false)
	print("World: ", world.name)
	print("EnemyPositions: ", enemy_positions)
	if combat_camera == null:
		push_error("Combat world is missing Camera3D.")
		return

	if enemy_positions == null:
		push_error("Combat world is missing EnemyPositions.")
		return

	if player_position == null:
		push_error("Combat world is missing PlayerPosition.")
		return

	combat_camera.current = true
	camera_original_position = combat_camera.position
	spawn_player_3d_node()

func set_combat_ui_enabled(enabled: bool):
	is_in_town = !enabled

	$DiceArea.visible = enabled
	$LeftMarginContainer.visible = enabled
	$RightMarginContainer.visible = enabled

	combat_number_label.visible = enabled
	end_round_button.visible = enabled
	end_round_button.disabled = !enabled

	begin_expedition_button.visible = !enabled

func connect_ui_click_sounds(root: Node):
	for child in root.get_children():
		if child is Button:
			if !child.pressed.is_connected(_on_any_ui_button_pressed):
				child.pressed.connect(_on_any_ui_button_pressed)

		connect_ui_click_sounds(child)
	
func _on_any_ui_button_pressed():
	AudioManager.play_ui(ui_click_sound)
	
func play_purchase_sound():
	AudioManager.play_one_shot(coin_purchase_sound)

func add_mulligems(amount: int):
	mulligems = min(mulligems + amount, MAX_MULLIGEMS)
	update_mulligem_button()

func update_player_status_icons():
	var bleed_value: int = player_statuses.get("bleed", 0)
	
	if player_3d_node != null and is_instance_valid(player_3d_node):
		player_3d_node.set_bleeding(bleed_value > 0)
		var regenerating_value: int = player_statuses.get("regenerating", 0)


		player_3d_node.update_status_icons(
			bleed_icon_texture,
			bleed_value,
			regenerating_icon_texture,
			regenerating_value
		)
func apply_player_regeneration():
	var regen_value: int = player_statuses.get("regenerating", 0)

	if regen_value <= 0:
		return

	player_hp += regen_value

	if player_hp > combat_max_player_hp:
		player_hp = combat_max_player_hp

	show_popup_text(player_3d_node, "+" + str(regen_value), 1.2, Color.GREEN)
	add_combat_log_entry("Regenerating healed " + str(regen_value) + " HP.")

	update_player_hp_label()
	update_player_status_icons()

func has_relic(name: String) -> bool:
	for relic in owned_relics:
		if relic.relic_name == name:
			return true
	return false


func get_relic(name: String) -> RelicData:
	for relic in owned_relics:
		if relic.relic_name == name:
			return relic
	return null
	
func apply_end_combat_relics():
	pass

func is_menu_blocking_input() -> bool:
	return options_overlay.visible \
		or shop_panel.visible \
		or loot_panel.visible \
		or edit_dice_panel.visible \
		or bounty_board_panel.visible \
		or expedition_camp_panel.visible \
		or prepare_expedition_panel.visible \
		or merchant_panel.visible \
		or food_craft_panel.visible
		
func open_options_menu():
	options_overlay.visible = true
	options_panel.visible = true

func close_options_menu():
	options_overlay.visible = false
	options_panel.visible = false

func quit_game():
	save_settings()
	save_run()
	get_tree().quit()

func _on_master_volume_changed(value: float):
	set_bus_volume("Master", value)
	save_settings()


func _on_music_volume_changed(value: float):
	set_bus_volume("Music", value)
	save_settings()

func _on_sfx_volume_changed(value: float):
	set_bus_volume("SFX", value)
	save_settings()

func set_bus_volume(bus_name: String, value: float):
	var bus_index := AudioServer.get_bus_index(bus_name)

	if bus_index == -1:
		push_error("Audio bus not found: " + bus_name)
		return

	if value <= 0.0:
		AudioServer.set_bus_mute(bus_index, true)
	else:
		AudioServer.set_bus_mute(bus_index, false)
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(value))

func _on_fullscreen_toggled(enabled: bool):
	if enabled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	save_settings()
func _on_resolution_selected(index: int):
	print("Resolution selected: ", index)

	if index < 0 or index >= AVAILABLE_RESOLUTIONS.size():
		return

	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(AVAILABLE_RESOLUTIONS[index])

	var screen_size := DisplayServer.screen_get_size()
	var window_size : Vector2i = AVAILABLE_RESOLUTIONS[index]
	DisplayServer.window_set_position((screen_size - window_size) / 2)
	save_settings()
	
func save_settings():
	var config := ConfigFile.new()

	config.set_value("audio", "master", master_volume_slider.value)
	config.set_value("audio", "music", music_volume_slider.value)
	config.set_value("audio", "sfx", sfx_volume_slider.value)

	config.set_value("display", "fullscreen", fullscreen_check_box.button_pressed)
	config.set_value("display", "resolution_index", resolution_option.selected)

	config.save(SETTINGS_SAVE_PATH)

func save_run():
	var config := ConfigFile.new()
	
	config.set_value("run", "encounters_completed", run_encounters_completed)
	config.set_value("run", "gold", gold)
	config.set_value("run", "mulligems", mulligems)
	config.set_value("run", "volatile_cores", volatile_cores)
	config.set_value("run", "die_fragments", die_fragments)

	config.set_value("player", "hp", player_hp)
	config.set_value("player", "max_hp", max_player_hp)
	config.set_value("run", "reserve_slots", reserve_slots)
	config.set_value("expedition", "progress", expedition_progress)
	config.set_value("expedition", "required_encounters", expedition_required_encounters)
	config.set_value("expedition", "is_boss_fight", expedition_is_boss_fight)
	config.set_value("expedition", "current_bounty", current_bounty.bounty_name if current_bounty != null else "")
	var merchant_face_save := []

	for face in merchant_unlocked_faces:
		merchant_face_save.append(serialize_face(face))

	config.set_value("merchant", "unlocked_faces", merchant_face_save)
	var completed_bounty_names := []
	for bounty in completed_bounties:
		if bounty != null:
			completed_bounty_names.append(bounty.bounty_name)

	config.set_value("progress", "completed_bounties", completed_bounty_names)

	var dice_save := []
	for die in owned_dice:
		if die != null:
			dice_save.append(serialize_die(die))

	config.set_value("inventory", "owned_dice", dice_save)

	var face_save := []
	for face in face_inventory:
		if face != null:
			face_save.append(serialize_face(face))

	config.set_value("inventory", "face_inventory", face_save)

	var consumable_save := []
	for item in consumable_inventory:
		if item != null:
			consumable_save.append(serialize_consumable(item))

	config.set_value("inventory", "consumables", consumable_save)

	var owned_relic_names := []
	for relic in owned_relics:
		if relic != null:
			owned_relic_names.append(relic.relic_name)

	config.set_value("unlock", "owned_relics", owned_relic_names)
	config.set_value("unlock", "unlocked_food_tier", unlocked_food_tier)

	var err := config.save(RUN_SAVE_PATH)

	if err == OK:
		print("Run saved.")
		print("Run save path: ", ProjectSettings.globalize_path(RUN_SAVE_PATH))
	else:
		push_error("Failed to save run.")
	
func serialize_die(die: DiceData) -> Dictionary:
	var faces := []

	for face in die.faces:
		faces.append(serialize_face(face))

	return {
		"die_name": die.die_name,
		"sides": die.sides,
		"can_explode": die.can_explode,
		"sprite_path": die.sprite.resource_path if die.sprite != null else "",
		"faces": faces
	}
	
func serialize_face(face: DiceFace) -> Dictionary:
	return {
		"face_name": face.face_name,
		"result_type": face.result_type,
		"value": face.value,
		"label": face.label,
		"icon_path": face.icon.resource_path if face.icon != null else ""
	}
	
func serialize_consumable(item: ConsumableItem) -> Dictionary:
	return {
		"item_name": item.item_name,
		"description": item.description,
		"icon_path": item.icon.resource_path if item.icon != null else "",
		"cost": item.cost,
		"heal_amount": item.heal_amount,
		"next_combat_block": item.next_combat_block,
		"next_combat_damage": item.next_combat_damage,
		"increase_max_hp": item.increase_max_hp,
		"next_combat_max_hp": item.next_combat_max_hp,
		"food_tier": item.food_tier,
		"grants_trait_path": item.grants_trait.resource_path if item.grants_trait != null else ""
	}



func deserialize_face(data: Dictionary) -> DiceFace:
	var face := DiceFace.new()

	face.face_name = data.get("face_name", "Face")
	face.result_type = data.get("result_type", "miss")
	face.value = data.get("value", 0)
	face.label = data.get("label", "")

	var icon_path: String = data.get("icon_path", "")
	if icon_path != "":
		face.icon = load(icon_path)

	return face
	
func deserialize_die(data: Dictionary) -> DiceData:
	var die := DiceData.new()

	die.die_name = data.get("die_name", "Basic Die")
	die.sides = data.get("sides", 6)
	die.can_explode = data.get("can_explode", false)

	var sprite_path: String = data.get("sprite_path", "")
	if sprite_path != "":
		die.sprite = load(sprite_path)

	die.faces.clear()

	for face_data in data.get("faces", []):
		die.faces.append(deserialize_face(face_data))

	return die
	
func deserialize_consumable(data: Dictionary) -> ConsumableItem:
	var item := ConsumableItem.new()

	item.item_name = data.get("item_name", "")
	item.description = data.get("description", "")

	var icon_path: String = data.get("icon_path", "")
	if icon_path != "":
		item.icon = load(icon_path)

	item.cost = data.get("cost", 5)
	item.heal_amount = data.get("heal_amount", 0)
	item.next_combat_block = data.get("next_combat_block", 0)
	item.next_combat_damage = data.get("next_combat_damage", 0)
	item.increase_max_hp = data.get("increase_max_hp", 0)
	item.next_combat_max_hp = data.get("next_combat_max_hp", 0)
	item.food_tier = data.get("food_tier", 1)

	var trait_path: String = data.get("grants_trait_path", "")
	if trait_path != "":
		item.grants_trait = load(trait_path)

	return item
	
func get_resource_path(resource: Resource) -> String:
	if resource == null:
		return ""

	return resource.resource_path

func load_run():
	var config := ConfigFile.new()
	var err := config.load(RUN_SAVE_PATH)

	if err != OK:
		print("No run save found.")
		return false
	
	gold = config.get_value("run", "gold", gold)
	mulligems = config.get_value("run", "mulligems", mulligems)
	volatile_cores = config.get_value("run", "volatile_cores", volatile_cores)
	die_fragments = config.get_value("run", "die_fragments", die_fragments)

	player_hp = config.get_value("player", "hp", player_hp)
	max_player_hp = config.get_value("player", "max_hp", max_player_hp)
	combat_max_player_hp = max_player_hp
	run_encounters_completed = config.get_value("run", "encounters_completed", run_encounters_completed)
	expedition_progress = config.get_value("expedition", "progress", expedition_progress)
	expedition_required_encounters = config.get_value("expedition", "required_encounters", expedition_required_encounters)
	expedition_is_boss_fight = config.get_value("expedition", "is_boss_fight", expedition_is_boss_fight)
	reserve_slots = config.get_value("run", "reserve_slots", reserve_slots)
	update_reserve_slots_label()
	var saved_bounty_name: String = config.get_value("expedition", "current_bounty", "")
	if saved_bounty_name != "":
		for bounty in completed_bounties:
			if bounty.bounty_name == saved_bounty_name:
				current_bounty = bounty
				break

	completed_bounties.clear()
	var completed_bounty_names: Array = config.get_value("progress", "completed_bounties", [])

	for bounty in completed_bounties:
		bounty.completed = bounty.bounty_name in completed_bounty_names

		if bounty.completed:
			completed_bounties.append(bounty)

	owned_dice.clear()
	for die_data in config.get_value("inventory", "owned_dice", []):
		if die_data is Dictionary:
			owned_dice.append(deserialize_die(die_data))

	face_inventory.clear()
	for face_data in config.get_value("inventory", "face_inventory", []):
		if face_data is Dictionary:
			face_inventory.append(deserialize_face(face_data))

	consumable_inventory.clear()
	for item_data in config.get_value("inventory", "consumables", []):
		if item_data is Dictionary:
			consumable_inventory.append(deserialize_consumable(item_data))
	merchant_unlocked_faces.clear()

	for face_data in config.get_value("merchant", "unlocked_faces", []):
		if face_data is Dictionary:
			merchant_unlocked_faces.append(deserialize_face(face_data))
			
	owned_relics.clear()

	var owned_relic_names: Array = config.get_value("unlock", "owned_relics", [])

	for relic_name in owned_relic_names:
		var relic := find_relic_by_name(relic_name)
		if relic != null and !has_relic_name(relic.relic_name):
			owned_relics.append(relic)

	update_active_food_icons()
			# refresh_relic_panel()
	unlocked_food_tier = config.get_value("unlock", "unlocked_food_tier", unlocked_food_tier)

	selected_edit_die = null

	update_gold_label()
	update_player_hp_label()
	update_mulligem_button()
	update_volatile_core_button()

	print("Loaded dice count: ", owned_dice.size())
	print("Loaded face inventory count: ", face_inventory.size())
	print("Loaded consumable count: ", consumable_inventory.size())
	print("Loaded relic count: ", owned_relics.size())
	print("Run loaded.")

	return true
	
func load_settings():
	var config := ConfigFile.new()
	var err := config.load(SETTINGS_SAVE_PATH)

	if err != OK:
		return

	master_volume_slider.value = config.get_value("audio", "master", 1.0)
	music_volume_slider.value = config.get_value("audio", "music", 1.0)
	sfx_volume_slider.value = config.get_value("audio", "sfx", 1.0)

	fullscreen_check_box.button_pressed = config.get_value("display", "fullscreen", false)
	resolution_option.selected = config.get_value("display", "resolution_index", 0)

	_on_master_volume_changed(master_volume_slider.value)
	_on_music_volume_changed(music_volume_slider.value)
	_on_sfx_volume_changed(sfx_volume_slider.value)
	_on_fullscreen_toggled(fullscreen_check_box.button_pressed)
	_on_resolution_selected(resolution_option.selected)
	
func continue_run():

	if !load_run():
		return

	refresh_edit_dice_panel()
	update_gold_label()
	update_player_hp_label()
	update_mulligem_button()
	update_volatile_core_button()

func delete_run_save():
	if FileAccess.file_exists(RUN_SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(RUN_SAVE_PATH))
		
		
func update_expedition_progress_labels():
	camp_progress_title_label.text = "Bounty Progress"

	if expedition_is_boss_fight:
		camp_progress_value_label.text = "Boss Encounter"
	else:
		camp_progress_value_label.text = "Encounter %d/%d" % [
			expedition_progress + 1,
			expedition_required_encounters
		]
		
func find_relic_by_name(relic_name: String) -> RelicData:
	for relic in merchant_relic_pool:
		if relic.relic_name == relic_name:
			return relic

	for relic in combat_relic_drop_pool:
		if relic.relic_name == relic_name:
			return relic

	return null
func hide_all_combat_ui():
	end_round_button.visible = false
	mulligem_button.visible = false
	player_health_bar.visible = false
	player_health_label.visible = false
	assigned_dice_overlay.visible = false
	enemy_roll_overlay.visible = false
	reserve_slots_label.visible = false
	combat_number_label.visible = false
	player_hp_label.visible = false
	player_block_label.visible = false
	incoming_damage_label.visible = false

	hide_all_groups()
	hide_status_tooltip()
	hide_enemy_roll_preview()


func show_death_screen():
	death_overlay.modulate.a = 0.0
	death_overlay.visible = true
	$DiceArea/ReserveHBox.visible = false
	var tween := create_tween()
	tween.tween_property(death_overlay, "modulate:a", 1.0, 0.75)
	
func all_bounties_completed() -> bool:
	for bounty in bounty_pool:
		if !bounty.completed:
			return false

	return true
	
func reset_bounties_for_endless_mode():
	for bounty in completed_bounties:
		bounty.completed = false

	completed_bounties.clear()
	rebuild_bounty_board()
	save_run()

func show_endless_choice():
	endless_choice_overlay.visible = true

func end_demo():
	endless_choice_overlay.visible = false
	quit_game()

func continue_endless_mode():
	endless_choice_overlay.visible = false
	reset_bounties_for_endless_mode()
