extends Control

const SAVE_DIRECTORY := "user://SaveData/"
const SETTINGS_SAVE_PATH := SAVE_DIRECTORY + "settings.cfg"
const RUN_SAVE_PATH := SAVE_DIRECTORY + "run_save.cfg"
const STEAM_STORE_URL := (
	"https://store.steampowered.com/app/4832350/"
)

@export var dice_scene: PackedScene
@export var starting_dice: Array[DiceData]
@export var enemy_3d_scene: PackedScene
@export var inventory_face_button_scene: PackedScene
@export var miss_face_template: DiceFace
@export var dodge_face_template: DiceFace
@export var reversal_face_template: DiceFace
@export var break_focus_face_template: DiceFace
@export var twist_knife_face_template: DiceFace
@export var pain_face_template: DiceFace
@export var shield_bash_face_template: DiceFace

@onready var top_ui_background: TextureRect = $TopUIBackground
@onready var bottom_ui_background: TextureRect = $BottomUIBackground

var enemy_3d_nodes: Array[Enemy3D] = []

var reserve_slots: int = 2
var damage_by_enemy := {}
var crit_by_enemy := {}
var combat_log_entries: Array[String] = []
var selected_dice_order: Array[DiceNode] = []

var last_echoable_effect: Dictionary = {}
var resolving_mind_echo: bool = false

var dragged_die: DiceNode = null
var dragged_die_original_parent: Node = null
var dragged_die_original_index: int = -1

var endless_choice_pending: bool = false

var combat_camera: Camera3D
var enemy_positions: Node3D
var player_position: Node3D
var combat_camera_home_transform: Transform3D
var combat_camera_home_size: float
var combat_camera_home_saved: bool = false
@export var player_character_data: PlayerCharacterData

var beastmaster_phase: int = 0
@export var boss_phase_one_encounter: EncounterData
@export var boss_phase_two_encounter: EncounterData
signal beastmaster_phase_two_requested

var camera_original_position: Vector3
var shatter_camera_running: bool = false
var shatter_camera_original_transform: Transform3D
var shatter_camera_original_size: float

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
@onready var combat_log_panel: Panel = $CombatLogPanel
@onready var combat_log_button: Button = $CombatLogButton
@onready var combat_log_text: RichTextLabel = $CombatLogPanel/MarginContainer/VBoxContainer/CombatLogScroll/CombatLogText
@onready var combat_log_scroll: ScrollContainer = $CombatLogPanel/MarginContainer/VBoxContainer/CombatLogScroll
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
@onready var reserve_locks_container: HBoxContainer = $DiceArea/ReserveHBox/ReserveLocksCenter/ReserveLocksContainer
@export var reserve_unlocked_texture: Texture2D
@export var reserve_locked_texture: Texture2D

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
@export_range(0.0, 1.0, 0.01)
var mulligem_drop_chance: float = 0.05
@onready var restart_run_button: Button = $TopMarginContainer/CenterContainer/VBoxContainer/RestartRunButton

# Dice Editing panel
@onready var edit_dice_button: Button = $ShopPanel/VBoxContainer/EditDiceButton
@onready var edit_dice_panel: Panel = $EditDicePanel
@onready var die_faces_container: GridContainer = $EditDicePanel/MarginContainer/MainVBox/ColumnsHBox/DiceFacesVBox/DieFacesContainer
@onready var undo_fusion_button: Button = $EditDicePanel/MarginContainer/MainVBox/BottomButtonsHBox/UndoFusionButton
@onready var close_edit_button: Button = $EditDicePanel/MarginContainer/MainVBox/BottomButtonsHBox/CloseEditButton
@onready var apply_volatile_core_button = $EditDicePanel/MarginContainer/MainVBox/ApplyVolatileCoreButton
@onready var owned_dice_container: VBoxContainer = $EditDicePanel/MarginContainer/MainVBox/ColumnsHBox/OwnedDiceVbox/ScrollContainer/OwnedDiceContainer
@export var owned_die_button_scene: PackedScene
@export var equipped_face_button_scene: PackedScene
@onready var inventory_faces_container: VBoxContainer = $EditDicePanel/MarginContainer/MainVBox/ColumnsHBox/InventoryFacesVBox/ScrollContainer/InventoryFacesContainer
@onready var die_crafting_panel: Panel = $EditDicePanel/MarginContainer/MainVBox/DieCraftingPanel
@onready var fragment_label: Label = $EditDicePanel/MarginContainer/MainVBox/DieCraftingPanel/VBoxContainer/FragmentLabel
@onready var sell_face_panel: Control = $EditDicePanel/MarginContainer/MainVBox/SellFacePanel
@onready var sell_drop_area: Control = $EditDicePanel/MarginContainer/MainVBox/SellFacePanel/SellDropArea
@onready var sell_value_label: Label = $EditDicePanel/MarginContainer/MainVBox/SellFacePanel/SellValueLabel
@onready var edit_dice_title_label: Label = $EditDicePanel/MarginContainer/MainVBox/EditTitleLabel
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
@export var heal_icon_texture: Texture2D

@onready var edit_warning_label: Label = $EditDicePanel/MarginContainer/EditWarningLabel
@export var ui_fail_sound: AudioStream

var selected_inventory_face_indices: Array[int] = []
var fusion_mode: bool = false
var fusion_undo_inventory: Array[DiceFace] = []
var fusion_undo_die_faces: Dictionary = {}
var fusion_undo_available: bool = false
var selected_die_face_index: int = -1
var selected_die_face_index_2: int = -1
var selected_edit_die: DiceData = null
var edit_dice_return_context: String = ""

# Loot panel
@onready var loot_panel: Panel = $LootPanel
@onready var loot_continue_button: Button = $LootPanel/MarginContainer/LootVBox/LootContinueButton
@onready var loot_rich_text_label: RichTextLabel = $LootPanel/MarginContainer/LootVBox/RichTextLabel

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
@onready var prepare_hp_label: Label = $PrepareExpeditionPanel/MarginContainer/VBoxContainer/PrepareHPLabel
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
@export var cooking_sound: AudioStream
@export var beastmaster_wind_sound: AudioStream
@export var beastmaster_pant_sound: AudioStream
@export var beastmaster_inhale_sound: AudioStream
@export var beastmaster_horn_sound: AudioStream
@export var beastmaster_phase2_music: AudioStream
@export var fireball_sound: AudioStream

signal request_music_fade_out

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
@export var witch_charm_relic: RelicData
var volatile_cores: int = 0
var volatile_core_cost: int = 35
var last_volatile_cores_gained: int = 0

var owned_dice: Array[DiceData] = []
@export var combat_relic_drop_pool: Array[RelicData]
@export var combat_relic_drop_chance: float = 0.05

@onready var relic_reward_overlay: ColorRect = $RelicRewardOverlay
@onready var relic_reward_glow: TextureRect = $RelicRewardOverlay/CenterContainer/RewardVBox/GlowContainer/GlowBack
@onready var relic_reward_icon: TextureRect = $RelicRewardOverlay/CenterContainer/RewardVBox/GlowContainer/RewardIcon
@onready var relic_reward_name_label: Label = $RelicRewardOverlay/CenterContainer/RewardVBox/RewardNameLabel
@onready var relic_reward_description_label: RichTextLabel = $RelicRewardOverlay/CenterContainer/RewardVBox/RewardDescriptionLabel
@onready var relic_reward_continue_button: Button = $RelicRewardOverlay/CenterContainer/RewardVBox/ContinueButton

var relic_reward_pending: RelicData = null
var relic_reward_acknowledged: bool = false
signal relic_reward_finished

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

# Dice Bag ###################################
@onready var dice_bag_button: Button = $DiceBagButton
@onready var dice_bag_panel: Panel = $DiceBagPanel
@onready var dice_bag_close_button: Button = $DiceBagPanel/MarginContainer/VBoxContainer/HeaderHBox/CloseButton
@onready var dice_bag_list: VBoxContainer = $DiceBagPanel/MarginContainer/VBoxContainer/ScrollContainer/DiceBagList
var dice_panel_read_only: bool = false

# Merchant #####################################
@onready var merchant_panel: Panel = $MerchantPanel
@onready var close_merchant_button: Button = $MerchantPanel/MarginContainer/VBoxContainer/CloseMerchantButton
@onready var merchant_button: Button = $TownPanel/VBoxContainer/MerchantButton
@onready var merchant_stock_container: GridContainer = $MerchantPanel/MarginContainer/VBoxContainer/MerchantStockContainer
@onready var prepare_consumables_container: GridContainer = $PrepareExpeditionPanel/MarginContainer/VBoxContainer/PrepareConsumablesContainer
@onready var merchant_gold_label: Label = $MerchantPanel/MarginContainer/VBoxContainer/MerchantGoldLabel
@export var merchant_food_pool: Array[ConsumableItem]
@export var merchant_relic_pool: Array[RelicData]

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
@onready var discord_button: Button = $OptionsOverlay/OptionsPanel/MarginContainer/VBoxContainer/DiscordButton
@onready var options_wishlist_button: Button = (
	$OptionsOverlay/OptionsPanel/MarginContainer/VBoxContainer/WishlistButton
)

# Death Overlay ###################################
@onready var death_overlay: ColorRect = $DeathOverlay
@onready var death_restart_button: Button = $DeathOverlay/CenterContainer/VBoxContainer/RestartButton

@onready var endless_choice_overlay: ColorRect = $EndlessChoiceOverlay
@onready var end_demo_button: Button = $EndlessChoiceOverlay/Panel/MarginContainer/VBoxContainer/EndDemoButton
@onready var continue_endless_button: Button = $EndlessChoiceOverlay/Panel/MarginContainer/VBoxContainer/ContinueEndlessButton
@onready var endless_wishlist_button: Button = (
	$EndlessChoiceOverlay/Panel/MarginContainer/VBoxContainer/WishlistButton
)

# Combat Stuff ################################
@export var freeze_sound: AudioStream
@export var shatter_death_sound: AudioStream
@export var victory_sound: AudioStream
@export var player_death_sound: AudioStream
@export var shatter_particles_scene: PackedScene
@onready var fireball_flash: ColorRect = $FireballFlash

# Beast Master stuff ############################
@export var beastmaster_exvellus_enemy: EnemyData
@export var beastmaster_nigel_enemy: EnemyData
@export var beastmaster_noir_enemy: EnemyData
@export var beastmaster_phase2_support_die: DiceData
var beastmaster_transition_running: bool = false

const AVAILABLE_RESOLUTIONS := [
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440)
]

signal expedition_started(event_type: String)
signal return_to_town_requested
signal town_menu_closed
signal request_music_change(track: AudioStream)

const PLAN_COMBAT := "combat"
const PLAN_WITCH := "witch"
const PLAN_WELL := "well"

var beastmaster_camera_original_transform: Transform3D
var beastmaster_camera_original_size: float

var expedition_encounter_plan: Array = []
var loaded_pending_encounter: bool = false
var expedition_active: bool = false

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

var witch_seen_this_run: bool = false
var well_seen_this_run: bool = false

var combat_number: int = 0
var base_enemy_hp: int = 20

var max_player_hp: int = 30
var player_hp: int = 30
var player_hp_at_combat_start: int = 30

var player_statuses := {
	"bleed": 0,
	"regenerating": 0,
	"berserker": 0
}

var dice_nodes: Array[DiceNode] = []
var enemy_hp: int = 20

var player_block: int = 0
var dodged_enemy_crits := false
var combat_over: bool = false

var mulligems: int = 0
var mulligem_used_this_turn: bool = false
var last_mulligems_gained: int = 0

@onready var mulligem_button: Button = $DiceArea/MulligemButton
@onready var mulligem_icons_container: HBoxContainer = $DiceArea/MulligemButton/CenterContainer/MulligemIconsContainer
@export var mulligem_icon_texture: Texture2D
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
	fireball_flash.visible = false
	fireball_flash.modulate.a = 0.0
	combat_log_panel.visible = false
	combat_log_text.bbcode_enabled = false
	combat_log_text.add_theme_color_override("default_color", Color.WHITE)
	combat_log_text.add_theme_color_override("font_outline_color", Color.BLACK)
	combat_log_text.add_theme_constant_override("outline_size", 2)
	combat_log_button.pressed.connect(toggle_combat_log)
	relic_reward_overlay.visible = false
	relic_reward_continue_button.pressed.connect(_on_relic_reward_continue_pressed)
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
	
	assigned_dice_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	enemy_roll_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	options_panel.visible = false
	options_button.pressed.connect(open_options_menu)
	close_options_button.pressed.connect(close_options_menu)
	options_restart_button.pressed.connect(restart_run)
	options_quit_button.pressed.connect(quit_game)
	
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
	

	music_volume_slider.min_value = 0.0
	music_volume_slider.max_value = 1.0
	music_volume_slider.step = 0.01
	

	sfx_volume_slider.min_value = 0.0
	sfx_volume_slider.max_value = 1.0
	sfx_volume_slider.step = 0.01
	
	options_wishlist_button.pressed.connect(
		open_steam_store_page
	)

	endless_wishlist_button.pressed.connect(
		open_steam_store_page
	)

	load_settings()
	if dice_bag_button.pressed.is_connected(open_dice_bag_read_only):
		dice_bag_button.pressed.disconnect(open_dice_bag_read_only)

	dice_bag_button.pressed.connect(open_dice_bag_read_only)
	dice_bag_close_button.pressed.connect(close_dice_bag)
	dice_bag_panel.visible = false
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
	update_player_status_icons()
	update_reserve_slots_display()
	# spawn_dice()
	# await roll_all_dice()
	regroup_dice()
	update_group_visibility()
	# roll_enemy_intents()
	discord_button.pressed.connect(_on_discord_button_pressed)
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
	undo_fusion_button.pressed.connect(undo_last_fusion)
	close_edit_button.pressed.connect(close_edit_dice_panel)
	update_fusion_undo_button()
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
	if mulligem_icons_container != null:
		for child in mulligem_icons_container.get_children():
			child.queue_free()

		var visible_icon_count: int = min(mulligems, 8)

		for i in visible_icon_count:
			var icon := TextureRect.new()

			icon.texture = mulligem_icon_texture
			icon.custom_minimum_size = Vector2(30, 30)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE

			mulligem_icons_container.add_child(icon)
		if mulligems > visible_icon_count:
			var overflow_label := Label.new()

			overflow_label.text = (
				"+"
				+ str(mulligems - visible_icon_count)
			)

			overflow_label.vertical_alignment = (
				VERTICAL_ALIGNMENT_CENTER
			)

			overflow_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

			mulligem_icons_container.add_child(
				overflow_label
			)
	mulligem_button.text = ""

	mulligem_button.disabled = (
		mulligems <= 0
		or mulligem_used_this_turn
		or combat_over
		or is_rolling_dice
		or is_resolving_turn
	)

	if mulligem_used_this_turn:
		mulligem_button.tooltip_text = (
			"You have already used a Mulligem this turn."
		)
	elif mulligems <= 0:
		mulligem_button.tooltip_text = (
			"You do not have any Mulligems."
		)
	else:
		mulligem_button.tooltip_text = (
			"Reroll every available die.\n"
			+ "Can be used once per turn.\n"
			+ "Mulligems owned: "
			+ str(mulligems)
		)
	var icon_modulate := Color.WHITE

	if mulligem_button.disabled:
		icon_modulate = Color(0.45, 0.45, 0.45, 1.0)

	mulligem_icons_container.modulate = icon_modulate
	
func has_mulligem_reroll_targets() -> bool:
	for die in dice_nodes:
		if !is_instance_valid(die):
			continue

		if die.used:
			continue

		if die.reserved:
			continue

		if die.assigned_enemy_index != -1:
			continue

		return true

	return false
	
func use_mulligem():
	if mulligems <= 0:
		return

	if mulligem_used_this_turn:
		return

	if is_rolling_dice or is_resolving_turn:
		return

	if !has_mulligem_reroll_targets():
		update_mulligem_button()
		return

	mulligems -= 1
	mulligem_used_this_turn = true
	add_combat_log_entry(
		"Used a Mulligem to reroll all available dice."
	)
	update_mulligem_button()
	save_run()

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

	is_rolling_dice = true
	end_round_button.disabled = true
	update_mulligem_button()

	# Move every eligible die into the roll area first.
	for die in dice_to_reroll:
		die.selected = false
		die.assigned_enemy_index = -1
		selected_dice_order.erase(die)

		die.set_compact_mode(false)
		die.set_base_visual_scale(
			Vector2.ONE * get_combat_die_scale()
		)

		if die.get_parent() != roll_animation_area:
			die.reparent(roll_animation_area)

		die.position = Vector2.ZERO
		die.visible = true

	update_group_visibility()

	# Reroll and return each die one at a time.
	for die in dice_to_reroll:
		if !is_instance_valid(die):
			continue

		dice_roll_sfx.pitch_scale = randf_range(0.9, 1.1)
		dice_roll_sfx.play()

		await die.roll_animated(
			roll_animation_area,
			0,
			1
		)

		var final_container: GridContainer = get_container_for_die(die)

		if final_container == null:
			continue

		# The destination group may currently be hidden because it was empty.
		# Reveal it before calculating and playing the return tween.
		final_container.get_parent().visible = true

		await get_tree().process_frame

		await die.fly_to_container(final_container)

		die.set_compact_mode(false)
		die.set_base_visual_scale(
			Vector2.ONE * get_combat_die_scale()
		)

		update_group_visibility()

		await get_tree().create_timer(0.04).timeout

	apply_damage_bonus_to_dice_visuals()
	calculate_auto_block()
	update_group_visibility()

	is_rolling_dice = false
	end_round_button.disabled = false
	update_mulligem_button()
	
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
	begin_expedition_button.visible = (
		is_in_town
		and !expedition_active
		and !beastmaster_transition_running
		and !is_resolving_turn
		and !merchant_panel.visible
		and !food_craft_panel.visible
		and !edit_dice_panel.visible
		and !bounty_board_panel.visible
		and !prepare_expedition_panel.visible
		and !expedition_camp_panel.visible
	)

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
	if dice_panel_read_only:
		return

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

	AudioManager.play_one_shot(
		dice_smith_crafting_sound
	)

	update_volatile_core_button()
	refresh_edit_dice_panel()
	save_run()
	
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
	
func create_enemy_instance(
	enemy_data: EnemyData
) -> Dictionary:
	if enemy_data == null:
		push_error(
			"create_enemy_instance received null EnemyData."
		)
		return {}

	var scaled_max_hp: int = enemy_data.max_hp
	var bonus_traits: Array[EnemyTrait] = []

	if (
		!expedition_is_boss_fight
		and run_encounters_completed
		>= random_trait_scaling_threshold
		and randf() <= random_trait_chance
	):

		var valid_traits: Array[EnemyTrait] = []

		for possible_trait in random_enemy_trait_pool:
			if possible_trait == null:
				continue

			var already_has_trait: bool = false

			for existing_trait in enemy_data.traits:
				if existing_trait == null:
					continue

				if (
					existing_trait.trait_id
					== possible_trait.trait_id
				):
					already_has_trait = true
					break

			if !already_has_trait:
				valid_traits.append(
					possible_trait
				)

		if !valid_traits.is_empty():
			var chosen_trait: EnemyTrait = (
				valid_traits.pick_random()
			)

			if chosen_trait != null:
				bonus_traits.append(
					chosen_trait
				)

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
		"bonus_traits": bonus_traits,
		"phase_two_started": false,
		"agile_used": false,
		"downed": false
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
		
func rebuild_enemy_3d_nodes() -> bool:
	if enemy_positions == null:
		push_error("Cannot rebuild enemies: enemy_positions is null.")
		return false

	if enemy_positions.get_child_count() < active_enemies.size():
		push_error(
			"Not enough enemy positions. Need "
			+ str(active_enemies.size())
			+ ", have "
			+ str(enemy_positions.get_child_count())
			+ "."
		)
		return false

	# Remove every existing enemy immediately.
	# Using free() here avoids queue_free timing races during cinematics.
	for enemy_node in enemy_3d_nodes:
		if is_instance_valid(enemy_node):
			enemy_node.free()

	enemy_3d_nodes.clear()

	# Also clear anything left directly inside the spawn slots.
	for slot in enemy_positions.get_children():
		for child in slot.get_children():
			if child is Enemy3D and is_instance_valid(child):
				child.free()

	await get_tree().process_frame

	for i in active_enemies.size():
		var enemy: Dictionary = active_enemies[i]
		var enemy_data: EnemyData = enemy.get("data", null)

		if enemy_data == null:
			push_error(
				"Enemy at index "
				+ str(i)
				+ " has no EnemyData."
			)
			return false

		var slot: Node3D = enemy_positions.get_child(i)
		var enemy_node: Enemy3D = enemy_3d_scene.instantiate()

		slot.add_child(enemy_node)
		enemy_node.position = Vector3.ZERO
		enemy_node.visible = true

		enemy_node.setup(i, enemy)

		enemy_node.selected.connect(
			select_enemy_target
		)

		enemy_node.status_hovered.connect(
			show_status_tooltip
		)

		enemy_node.status_unhovered.connect(
			hide_status_tooltip
		)

		enemy_3d_nodes.append(enemy_node)

	await get_tree().process_frame

	if enemy_3d_nodes.size() != active_enemies.size():
		push_error(
			"Enemy visual rebuild mismatch. Data: "
			+ str(active_enemies.size())
			+ ", visuals: "
			+ str(enemy_3d_nodes.size())
		)
		return false

	return true
	
func roll_enemy_intents():
	for enemy in active_enemies:
		var rolled_hit := false

		enemy["attack"] = 0
		enemy["crit"] = 0
		enemy["block"] = 0
		enemy["heal"] = 0
		enemy["crit_rolls"] = []
		enemy["rolled_faces"] = []

		if enemy.has("downed") and enemy["downed"]:
			enemy["roll_text"] = "Downed"
			continue

		if enemy["frozen"]:
			enemy["roll_text"] = "Frozen"
			continue

		enemy["roll_text"] = ""

		var data: EnemyData = enemy["data"]

		for die_data in data.dice_pool:
			var face: DiceFace = die_data.faces.pick_random()
			var face_index: int = die_data.faces.find(face)

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

		if enemy.has("phase_two_support_die") and enemy["phase_two_support_die"] != null:
			var support_die: DiceData = enemy["phase_two_support_die"]

			for die_data in [support_die]:
				var face: DiceFace = die_data.faces.pick_random()
				var face_index: int = die_data.faces.find(face)

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

	return die.current_face.result_type in [
		"hit",
		"crit",
		"dodge",
		"reversal",
		"freeze",
		"bleed",
		"twist_knife",
		"break_focus",
		"shield_bash",
		"fireball",
		"mind_echo",
		"blizzard",
		"chain_lightning"
	]
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

		var enemy_node: Enemy3D = enemy_3d_nodes[i]

		if !is_instance_valid(enemy_node):
			continue

		enemy_node.setup(
			i,
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
	calculate_auto_block()
	update_reserve_slots_display()
	
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

		"dodge", \
		"reversal", \
		"freeze", \
		"bleed", \
		"twist_knife", \
		"break_focus", \
		"pain", \
		"shield_bash", \
		"fireball", \
		"mana_shield", \
		"mind_echo", \
		"blizzard", \
		"chain_lightning":
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
		die.set_base_visual_scale(
			Vector2.ONE * get_combat_die_scale()
		)

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
func connect_combat_die_signals(die: DiceNode):
	if die == null:
		return

	if !die.clicked.is_connected(handle_die_click):
		die.clicked.connect(handle_die_click)

	if !die.reserve_requested.is_connected(handle_reserve_request):
		die.reserve_requested.connect(handle_reserve_request)

	if !die.drag_started.is_connected(handle_die_drag_started):
		die.drag_started.connect(handle_die_drag_started)

	if !die.drag_finished.is_connected(handle_die_drag_finished):
		die.drag_finished.connect(handle_die_drag_finished)
		
func spawn_dice():
	print("Spawning dice count: ", owned_dice.size())

	for die_data in owned_dice:
		print("Spawning die: ", die_data.die_name)
		var die_node: DiceNode = dice_scene.instantiate()
		connect_combat_die_signals(die_node)
		misses_container.add_child(die_node)
		die_node.setup(die_data)
		die_node.set_base_visual_scale(
			Vector2.ONE * get_combat_die_scale()
		)
		dice_nodes.append(die_node)
	update_combat_dice_spacing()
	update_group_visibility()
	
func handle_die_click(die: DiceNode):
	print("Individual die clicked")

	if die == null or !is_instance_valid(die):
		return

	if die.used:
		return
		
	AudioManager.play_ui(dice_select_sound)

	# Clicking an assigned die returns it to its normal group.
	if die.assigned_enemy_index != -1:
		die.assigned_enemy_index = -1
		die.selected = false
		die.reserved = false

		selected_dice_order.erase(die)

		die.update_visual()
		regroup_dice()
		calculate_auto_block()
		update_enemy_button_texts()
		update_assigned_panel_visibility()
		update_reserve_slots_display()
		return

	# Clicking a reserved die unreserves it.
	if die.reserved:
		die.reserved = false
		die.selected = false

		selected_dice_order.erase(die)

		die.update_visual()
		regroup_dice()
		calculate_auto_block()
		update_enemy_button_texts()
		update_assigned_panel_visibility()
		update_reserve_slots_display()
		return

	# Normal selection toggle.
	die.selected = !die.selected

	# A selected die may never simultaneously be reserved.
	die.reserved = false

	if die.selected:
		selected_dice_order.erase(die)
		selected_dice_order.append(die)
	else:
		selected_dice_order.erase(die)

	die.update_visual()

	calculate_auto_block()
	update_enemy_button_texts()
	update_assigned_panel_visibility()
	update_reserve_slots_display()
	
func handle_die_drag_started(die: DiceNode):
	if die == null or !is_instance_valid(die):
		return

	if combat_over or is_rolling_dice or is_resolving_turn:
		die.cancel_drag_interaction()
		return

	if die.used or die.reserved:
		die.cancel_drag_interaction()
		return

	if !is_offensive_die(die):
		die.cancel_drag_interaction()
		return

	dragged_die = die
	dragged_die_original_parent = die.get_parent()
	dragged_die_original_index = die.get_index()

	die.selected = false
	selected_dice_order.erase(die)

	# An assigned die can be dragged again to retarget it.
	die.assigned_enemy_index = -1
	die.reserved = false

	var current_global_position := die.global_position

	die.reparent(assigned_dice_overlay)
	die.global_position = current_global_position

	die.set_compact_mode(false)
	die.apply_current_visual_scale()
	die.mouse_filter = Control.MOUSE_FILTER_IGNORE

	die.update_visual()
	update_assigned_panel_visibility()
	
func handle_die_drag_finished(
	die: DiceNode,
	screen_position: Vector2
):
	if die == null or !is_instance_valid(die):
		clear_dragged_die_state()
		return

	die.mouse_filter = Control.MOUSE_FILTER_STOP
	die.apply_current_visual_scale()

	var enemy_index := get_enemy_index_at_screen_position(
		screen_position
	)

	if enemy_index != -1:
		assign_single_die_to_enemy(
			die,
			enemy_index
		)
	else:
		die.assigned_enemy_index = -1
		die.selected = false
		die.reserved = false
		die.update_visual()

		regroup_dice()
		calculate_auto_block()
		update_enemy_button_texts()
		update_assigned_panel_visibility()

	clear_dragged_die_state()
	
func get_enemy_index_at_screen_position(
	screen_position: Vector2
) -> int:
	var camera := get_viewport().get_camera_3d()

	if camera == null:
		return -1

	var ray_origin := camera.project_ray_origin(screen_position)
	var ray_end := ray_origin + (
		camera.project_ray_normal(screen_position) * 1000.0
	)

	var query := PhysicsRayQueryParameters3D.create(
		ray_origin,
		ray_end
	)

	query.collision_mask = 2
	query.collide_with_areas = true
	query.collide_with_bodies = false

	var result: Dictionary = (
		get_viewport()
		.world_3d
		.direct_space_state
		.intersect_ray(query)
	)

	if result.is_empty():
		return -1

	var collider = result.get("collider")

	if collider == null:
		return -1

	var enemy_node: Node = collider

	while enemy_node != null and !(enemy_node is Enemy3D):
		enemy_node = enemy_node.get_parent()

	if !(enemy_node is Enemy3D):
		return -1

	var enemy_index: int = enemy_node.enemy_index

	if enemy_index < 0 or enemy_index >= active_enemies.size():
		return -1

	return enemy_index
	
func assign_single_die_to_enemy(
	die: DiceNode,
	enemy_index: int
):
	if die == null or !is_instance_valid(die):
		return

	if enemy_index < 0 or enemy_index >= active_enemies.size():
		regroup_dice()
		return

	if assigned_enemy_containers.size() != active_enemies.size():
		refresh_enemy_buttons()

	if !is_offensive_die(die):
		regroup_dice()
		return

	if die.used or die.reserved:
		regroup_dice()
		return

	die.assigned_enemy_index = enemy_index
	die.selected = false
	die.reserved = false

	selected_dice_order.erase(die)

	move_die_to_assigned_enemy(die)
	die.update_visual()

	selected_enemy_index = -1

	calculate_auto_block()
	update_enemy_button_texts()
	update_assigned_panel_visibility()
	
func clear_dragged_die_state():
	dragged_die = null
	dragged_die_original_parent = null
	dragged_die_original_index = -1
	
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
		update_reserve_slots_display()
		return

	if die.reserved:
		die.reserved = false
		die.selected = false
		die.update_visual()
		regroup_dice()
		calculate_auto_block()
		update_reserve_slots_display()
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
	update_reserve_slots_display()
	
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
		var final_container: GridContainer = (
			get_container_for_die(die)
		)

		if final_container == null:
			continue

		# The group was hidden when all dice were moved into the
		# rolling area. Reveal it before returning the die.
		final_container.get_parent().visible = true

		await get_tree().process_frame
		await die.fly_to_container(final_container)

		die.visible = true

		die.set_compact_mode(false)
		die.set_base_visual_scale(
			Vector2.ONE * get_combat_die_scale()
		)

		# Refresh now, before awaiting the explosion chain.
		update_group_visibility()

		if die.dice_data.can_explode:
			if (
				die.current_face_index
				== die.dice_data.faces.size() - 1
			):
				if !die.has_exploded:
					die.has_exploded = true
					await spawn_exploded_die(die)

		update_group_visibility()
		await get_tree().create_timer(0.04).timeout

	calculate_auto_block()
	update_reserve_slots_display()

	print("Dice count after roll: ", dice_nodes.size())

	for die in dice_nodes:
		if is_instance_valid(die):
			print(die, " parent: ", die.get_parent().name)

	is_rolling_dice = false
	
func add_combat_log_entry(message: String):
	if message.strip_edges().is_empty():
		return

	combat_log_entries.append(message)

	while combat_log_entries.size() > 50:
		combat_log_entries.pop_front()

	refresh_combat_log()

func refresh_combat_log():
	if combat_log_text == null:
		return

	combat_log_text.text = "\n".join(combat_log_entries)

	await get_tree().process_frame

	if combat_log_scroll != null:
		var scroll_bar: VScrollBar = combat_log_scroll.get_v_scroll_bar()
		scroll_bar.value = scroll_bar.max_value
		
func resolve_player_dice():
	dice_nodes = dice_nodes.filter(func(die):
		return is_instance_valid(die)
	)
	last_echoable_effect.clear()
	resolving_mind_echo = false
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
				var hp_before_heal: int = player_hp

				player_hp += die.current_face.value

				if player_hp > combat_max_player_hp:
					player_hp = combat_max_player_hp

				var actual_healing: int = player_hp - hp_before_heal

				if actual_healing > 0:
					show_popup_text(
						player_3d_node,
						"+" + str(actual_healing),
						1.8,
						Color.GREEN
					)

					add_combat_log_entry(
						"Heal restored "
							+ str(actual_healing)
							+ " HP to the player."
					)
				else:
					add_combat_log_entry(
						"Heal had no effect because the player was already at full HP."
					)

				update_player_hp_label()

			"vitality":
				var vitality_value: int = die.current_face.value

				max_player_hp += vitality_value
				combat_max_player_hp += vitality_value
				player_hp += vitality_value

				if player_hp > combat_max_player_hp:
					player_hp = combat_max_player_hp

				show_popup_text(
					player_3d_node,
					"+" + str(vitality_value),
					1.8,
					Color.GREEN
				)

				add_combat_log_entry(
					"Vitality permanently increased Max HP by "
						+ str(vitality_value)
						+ " and restored "
						+ str(vitality_value)
						+ " HP."
				)

				update_player_hp_label()

			"dodge":
				dodged_enemy_crits = true

				add_combat_log_entry(
					"Dodge prepared the player to avoid enemy Crit damage this turn."
				)
				
			"mana_shield":
				var block_gained: int = get_mana_shield_block(
					die
				)

				if block_gained <= 0:
					add_combat_log_entry(
						"Mana Shield gained no Block because "
						+ "the die had no Miss faces."
					)

					show_popup_text(
						player_3d_node,
						"No Misses",
						1.2,
						Color.GRAY
					)
				else:
					player_block += block_gained

					show_popup_text(
						player_3d_node,
						"+" + str(block_gained) + " Block",
						1.4,
						Color.DEEP_SKY_BLUE
					)

					add_combat_log_entry(
						"Mana Shield gained "
						+ str(block_gained)
						+ " Block from "
						+ str(block_gained)
						+ " Miss faces."
					)

				update_player_block_label()
				update_player_3d_node()
					
			"pain":
				var pain_damage: int = die.current_face.value

				await tween_face_icon_to_player(
					die,
					die.current_face
				)

				var hp_before_pain: int = player_hp

				player_hp -= pain_damage

				if player_hp < 0:
					player_hp = 0

				var actual_pain_damage: int = hp_before_pain - player_hp
				last_damage_taken += actual_pain_damage

				show_popup_text(
					player_3d_node,
					str(pain_damage),
					1.8,
					Color(0.95, 0.45, 0.85)
				)

				show_damage_popup(
					player_3d_node,
					actual_pain_damage
				)

				add_combat_log_entry(
					"Pain dealt "
						+ str(actual_pain_damage)
						+ " damage to the player."
				)

				update_player_hp_label()

				if player_hp <= 0:
					add_combat_log_entry(
						"The player was defeated by Pain."
					)

					lose_combat()
					return
			_:
				pass

		if die.current_face.result_type in [
			"block",
			"gold",
			"heal",
			"vitality",
			"dodge",
			"pain",
			"mana_shield"
		]:
			die.reserved = false
			die.used = true
			die.selected = false
			die.update_visual()

	if gold_gained_this_turn > 0:
		gold += gold_gained_this_turn

		add_combat_log_entry(
			"Total Gold gained this turn: "
				+ str(gold_gained_this_turn)
				+ "."
		)
	apply_damage_bonus_to_dice_visuals()
	update_gold_label()
	update_player_block_label()
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

func resolve_targeted_blizzard(
	primary_index: int,
	freeze_amount: int,
	effect_name: String = "Blizzard"
):
	if !is_valid_living_echo_target(primary_index):
		return

	if freeze_amount <= 0:
		show_popup_text(
			enemy_3d_nodes[primary_index],
			"Not Enough Misses",
			1.2,
			Color.GRAY
		)

		add_combat_log_entry(
			effect_name
			+ " had no effect because the die had fewer "
			+ "than 2 Miss faces."
		)

		return

	var secondary_freeze: int = int(
		floor(float(freeze_amount) / 2.0)
	)

	var affected_count: int = 0

	AudioManager.play_one_shot(freeze_sound)

	# Primary target receives the full amount.
	if apply_blizzard_freeze_to_enemy(
		primary_index,
		freeze_amount
	):
		affected_count += 1

	# Every other enemy receives half, rounded down.
	if secondary_freeze > 0:
		for enemy_index in active_enemies.size():
			if enemy_index == primary_index:
				continue

			if apply_blizzard_freeze_to_enemy(
				enemy_index,
				secondary_freeze
			):
				affected_count += 1

	add_combat_log_entry(
		effect_name
		+ " applied "
		+ str(freeze_amount)
		+ " Freeze to the primary target and "
		+ str(secondary_freeze)
		+ " Freeze to other valid enemies."
	)

	update_enemy_3d_nodes()

	await get_tree().create_timer(0.35).timeout
	
func apply_blizzard_freeze_to_enemy(
	enemy_index: int,
	freeze_amount: int
) -> bool:
	if freeze_amount <= 0:
		return false

	if !is_valid_living_echo_target(enemy_index):
		return false

	var enemy: Dictionary = active_enemies[enemy_index]
	var enemy_node: Enemy3D = enemy_3d_nodes[enemy_index]
	var enemy_name: String = enemy["data"].enemy_name

	if enemy["data"].crowd_control_immune:
		show_popup_text(
			enemy_node,
			"Immune",
			1.2,
			Color.ORANGE_RED
		)

		add_combat_log_entry(
			enemy_name + " is immune to Blizzard."
		)

		return false

	enemy["frozen"] = true
	enemy["freeze_stacks"] += freeze_amount

	show_popup_text(
		enemy_node,
		"Freeze +" + str(freeze_amount),
		1.3,
		Color.CYAN
	)

	return true
	
func resolve_targeted_chain_lightning(
	primary_index: int,
	raw_damage: int,
	effect_name: String = "Chain Lightning"
):
	if !is_valid_living_echo_target(primary_index):
		return

	if raw_damage <= 0:
		show_popup_text(
			enemy_3d_nodes[primary_index],
			"Not Enough Misses",
			1.2,
			Color.GRAY
		)

		add_combat_log_entry(
			effect_name
			+ " dealt no damage because the die had fewer "
			+ "than 2 Miss faces."
		)

		return

	var total_actual_damage: int = 0

	# Primary target always receives full damage.
	total_actual_damage += await apply_chain_damage_to_enemy(
		primary_index,
		raw_damage,
		effect_name
	)

	# Build secondary target list. The primary target is excluded,
	# so it can never be struck again by the same chain.
	var secondary_targets: Array[int] = []

	for enemy_index in active_enemies.size():
		if enemy_index == primary_index:
			continue

		if !is_valid_living_echo_target(enemy_index):
			continue

		secondary_targets.append(enemy_index)

	secondary_targets.shuffle()

	var next_damage: int = int(
		floor(float(raw_damage) / 2.0)
	)

	for enemy_index in secondary_targets:
		if next_damage <= 0:
			break

		total_actual_damage += await apply_chain_damage_to_enemy(
			enemy_index,
			next_damage,
			effect_name
		)

		# Each jump halves the previous jump's damage.
		next_damage = int(
			floor(float(next_damage) / 2.0)
		)

		await get_tree().create_timer(0.10).timeout

	add_combat_log_entry(
		effect_name
		+ " dealt "
		+ str(total_actual_damage)
		+ " total damage."
	)

	update_enemy_3d_nodes()

	await shake_combat_camera(
		0.18,
		0.07
	)
	
func apply_chain_damage_to_enemy(
	enemy_index: int,
	raw_damage: int,
	effect_name: String
) -> int:
	if raw_damage <= 0:
		return 0

	if !is_valid_living_echo_target(enemy_index):
		return 0

	var enemy: Dictionary = active_enemies[enemy_index]
	var enemy_node: Enemy3D = enemy_3d_nodes[enemy_index]
	var enemy_name: String = enemy["data"].enemy_name

	var blocked_amount: int = min(
		raw_damage,
		int(enemy["block"])
	)

	enemy["block"] -= blocked_amount

	if enemy["block"] < 0:
		enemy["block"] = 0

	var hp_damage: int = raw_damage - blocked_amount

	if blocked_amount > 0:
		show_popup_text(
			enemy_node,
			"Blocked " + str(blocked_amount),
			1.0,
			Color.GRAY
		)

	var hp_before: int = enemy["hp"]

	if hp_damage > 0:
		enemy["hp"] -= hp_damage

		if enemy["hp"] < 0:
			enemy["hp"] = 0

	var actual_damage: int = hp_before - enemy["hp"]

	if actual_damage > 0:
		last_player_damage += actual_damage

		show_damage_popup(
			enemy_node,
			actual_damage
		)

		enemy_node.hit_flash()
		enemy_node.hurt_bump()

	add_combat_log_entry(
		effect_name
		+ " struck "
		+ enemy_name
		+ " for "
		+ str(actual_damage)
		+ " HP damage."
	)

	return actual_damage
	
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

	last_damage_taken = 0

	await resolve_player_dice()

	if combat_over:
		is_resolving_turn = false
		end_round_button.disabled = false
		return

	if active_enemies.is_empty():
		await get_tree().create_timer(0.5).timeout
		win_combat()
		is_resolving_turn = false
		return

	# ---------------------------------------------------------
	# ENEMY HEALING
	# ---------------------------------------------------------
	for healer_index in active_enemies.size():
		if healer_index < 0 or healer_index >= active_enemies.size():
			continue

		var healer: Dictionary = active_enemies[healer_index]
		var healer_name: String = healer["data"].enemy_name

		if healer["frozen"]:
			continue

		if healer["heal"] <= 0:
			continue

		if break_focus_targets.has(healer_index):
			add_combat_log_entry(
				"Break Focus cancelled "
				+ healer_name
				+ "'s healing."
			)

			if healer_index < enemy_3d_nodes.size():
				if is_instance_valid(enemy_3d_nodes[healer_index]):
					show_popup_text(
						enemy_3d_nodes[healer_index],
						"Healing Broken!",
						1.2,
						Color.PURPLE
					)

			continue

		var lowest_enemy = get_lowest_health_enemy()

		if lowest_enemy == null:
			continue

		var target_name: String = lowest_enemy["data"].enemy_name
		var hp_before: int = lowest_enemy["hp"]
		var target_max_hp: int = lowest_enemy["max_hp"]

		lowest_enemy["hp"] += healer["heal"]

		if lowest_enemy["hp"] > target_max_hp:
			lowest_enemy["hp"] = target_max_hp

		var actual_healing: int = lowest_enemy["hp"] - hp_before
		var healed_index: int = active_enemies.find(lowest_enemy)

		update_enemy_3d_nodes()

		if actual_healing > 0:
			add_combat_log_entry(
				healer_name
					+ " restored "
					+ str(actual_healing)
					+ " HP to "
					+ target_name
					+ "."
			)

			if healed_index != -1 and healed_index < enemy_3d_nodes.size():
				if is_instance_valid(enemy_3d_nodes[healed_index]):
					show_popup_text(
						enemy_3d_nodes[healed_index],
						"+" + str(actual_healing),
						1.8,
						Color.GREEN
					)

					spawn_enemy_heal_icon_particles(
						enemy_3d_nodes[healed_index]
					)

					await get_tree().create_timer(1.5).timeout

	# ---------------------------------------------------------
	# ENEMY ATTACKS
	# ---------------------------------------------------------
	for enemy_index in active_enemies.size():
		if enemy_index < 0 or enemy_index >= active_enemies.size():
			continue

		var enemy: Dictionary = active_enemies[enemy_index]
		var enemy_name: String = enemy["data"].enemy_name

		# Freeze skips this enemy's turn unless it resists the skip.
		if enemy["frozen"]:
			if enemy["data"].immune_to_freeze_skip:
				if enemy_index < enemy_3d_nodes.size():
					if is_instance_valid(enemy_3d_nodes[enemy_index]):
						show_popup_text(
							enemy_3d_nodes[enemy_index],
							"Chilled!",
							1.2,
							Color.CYAN
						)

				add_combat_log_entry(
					enemy_name + " resisted the Freeze turn skip."
				)

				enemy["frozen"] = false
				update_enemy_3d_nodes()
			else:
				if enemy_index < enemy_3d_nodes.size():
					if is_instance_valid(enemy_3d_nodes[enemy_index]):
						show_popup_text(
							enemy_3d_nodes[enemy_index],
							"Frozen!",
							1.2,
							Color.CYAN
						)

				add_combat_log_entry(
					enemy_name + " was Frozen and skipped its turn."
				)

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

			var should_reflect_die: bool = (
				face.result_type == "crit"
				and reversal_targets.has(enemy_index)
			)

			await launch_enemy_die_at_player(
				enemy_index,
				face,
				should_reflect_die
			)

			var damage: int = face.value

			# -------------------------------------------------
			# ENEMY CRIT
			# -------------------------------------------------
			if face.result_type == "crit":
				AudioManager.play_one_shot(critical_hit_sound)

				if reversal_targets.has(enemy_index):
					var hp_before_reversal: int = enemy["hp"]

					enemy["hp"] -= damage

					if enemy["hp"] < 0:
						enemy["hp"] = 0

					var actual_reversal_damage: int = (
						hp_before_reversal - enemy["hp"]
					)

					last_player_damage += actual_reversal_damage

					show_damage_popup(
						enemy_3d_nodes[enemy_index],
						actual_reversal_damage
					)

					add_combat_log_entry(
						"Reversal reflected "
							+ str(actual_reversal_damage)
							+ " Crit damage to "
							+ enemy_name
							+ "."
					)

					update_enemy_3d_nodes()
					await hit_stop(0.035)

					if enemy["hp"] <= 0:
						await remove_defeated_enemies()

						if active_enemies.is_empty():
							await get_tree().create_timer(0.5).timeout
							win_combat()
							is_resolving_turn = false
							return

					continue

				if dodge_targets.has(enemy_index):
					add_combat_log_entry(
						"The player dodged "
							+ enemy_name
							+ "'s "
							+ str(damage)
							+ "-damage Crit."
					)

					show_popup_text(
						player_3d_node,
						"Dodged!",
						1.0,
						Color.CORNFLOWER_BLUE
					)

					await hit_stop(0.02)
					continue

			# -------------------------------------------------
			# NORMAL ENEMY HIT AND PLAYER BLOCK
			# -------------------------------------------------
			if face.result_type == "hit":
				var berserker_bonus: int = get_active_berserker_bonus(enemy)

				if berserker_bonus > 0:
					damage += berserker_bonus

					add_combat_log_entry(
						enemy_name
							+ "'s Berserker trait added "
							+ str(berserker_bonus)
							+ " damage."
					)

				var blocked_amount: int = min(damage, player_block)

				if blocked_amount > 0:
					player_block -= blocked_amount

					if player_block < 0:
						player_block = 0

					add_combat_log_entry(
						"Player Block absorbed "
							+ str(blocked_amount)
							+ " damage from "
							+ enemy_name
							+ "."
					)

					if has_relic("Spiked Shield"):
						enemy["bleed"] += 1

						show_popup_text(
							enemy_3d_nodes[enemy_index],
							"Bleed +1",
							1.2,
							Color.RED
						)

						add_combat_log_entry(
							"Spiked Shield applied 1 Bleed to "
								+ enemy_name
								+ "."
						)

						update_enemy_3d_nodes()

					AudioManager.play_one_shot(
						hit_blocked_sound,
						0.95,
						1.05
					)

					show_popup_text(
						player_3d_node,
						"Block -" + str(blocked_amount),
						1.0,
						Color.CORNFLOWER_BLUE
					)

					update_player_block_label()
					await hit_stop(0.015)

				damage -= blocked_amount

			# -------------------------------------------------
			# PLAYER TAKES HP DAMAGE
			# -------------------------------------------------
			if damage > 0:
				player_hp -= damage

				if player_hp < 0:
					player_hp = 0

				last_damage_taken += damage

				if face.result_type == "crit":
					add_combat_log_entry(
						enemy_name
							+ " dealt "
							+ str(damage)
							+ " Crit damage to the player."
					)
				else:
					add_combat_log_entry(
						enemy_name
							+ " dealt "
							+ str(damage)
							+ " damage to the player."
					)

				# Venom only triggers when a Hit reaches player HP.
				if face.result_type == "hit":
					var venom_value: int = get_enemy_trait_value(
						enemy,
						"venomous"
					)

					if venom_value > 0:
						player_statuses["bleed"] += venom_value

						show_popup_text(
							player_3d_node,
							"Bleed +" + str(venom_value),
							1.2,
							Color.RED
						)

						add_combat_log_entry(
							enemy_name
								+ "'s Venomous trait applied "
								+ str(venom_value)
								+ " Bleed to the player."
						)

						update_player_status_icons()

				AudioManager.play_one_shot(
					hit_damage_sound,
					0.9,
					1.1
				)

				show_damage_popup(player_3d_node, damage)
				player_3d_node.hit_flash()
				player_3d_node.hurt_bump()
				screen_shake(0.08, 0.12)

				combat_max_player_hp = (
					max_player_hp + next_combat_bonus_max_hp
				)

				update_player_hp_label()
				await hit_stop(0.035)
			
			if player_hp <= 0:
				add_combat_log_entry("The player was defeated.")
				lose_combat()
				is_resolving_turn = false
				return
	
	# ---------------------------------------------------------
	# END-OF-ROUND EFFECTS
	# ---------------------------------------------------------
	await apply_enemy_bleed()
	apply_player_regeneration()
	await remove_defeated_enemies()

	# Only stop the old Phase 1 coroutine while the world transition
	# is actively taking place. Phase 2 itself must resolve normally.
	if beastmaster_transition_running:
		return

	if active_enemies.is_empty():
		await get_tree().create_timer(0.5).timeout
		win_combat()
		is_resolving_turn = false
		return

	clear_used_assigned_dice()

	dodge_targets.clear()
	reversal_targets.clear()
	break_focus_targets.clear()

	combat_max_player_hp = (
		max_player_hp + next_combat_bonus_max_hp
	)

	update_player_hp_label()
	update_player_block_label()

	apply_player_bleed()

	if combat_over:
		is_resolving_turn = false
		return

	apply_enemy_end_round_traits()
	update_enemy_3d_nodes()
	apply_end_round_relics()
	decay_enemy_statuses()
	update_combat_log()
	selected_enemy_index = -1

	reset_dice_for_next_roll()
	await roll_all_dice()

	apply_damage_bonus_to_dice_visuals()
	calculate_auto_block()

	roll_enemy_intents()
	refresh_enemy_buttons()
	update_player_3d_node()

	mulligem_used_this_turn = false


	add_combat_log_entry(
		"────────── New Round ──────────"
	)

	is_resolving_turn = false
	end_round_button.disabled = false
	update_mulligem_button()
	
func apply_player_bleed():
	var bleed_value: int = player_statuses.get("bleed", 0)

	if bleed_value <= 0:
		return

	var hp_before_bleed: int = player_hp

	player_hp -= bleed_value

	if player_hp < 0:
		player_hp = 0

	var actual_bleed_damage: int = hp_before_bleed - player_hp
	last_damage_taken += actual_bleed_damage

	AudioManager.play_one_shot(
		hit_damage_sound,
		0.9,
		1.1
	)

	show_damage_popup(
		player_3d_node,
		actual_bleed_damage
	)

	add_combat_log_entry(
		"Bleed dealt "
			+ str(actual_bleed_damage)
			+ " damage to the player."
	)

	player_statuses["bleed"] = max(
		bleed_value - 1,
		0
	)

	update_player_hp_label()
	update_player_status_icons()

	if player_hp <= 0:
		add_combat_log_entry(
			"The player was defeated by Bleed."
		)

		lose_combat()
		
func get_active_berserker_bonus(enemy: Dictionary) -> int:
	var value := get_enemy_trait_value(enemy, "berserker")

	if value <= 0:
		return 0

	if enemy["hp"] > enemy["max_hp"] / 2:
		return 0

	return value
	
func reset_dice_for_next_roll():
	for enemy in active_enemies:
		enemy["agile_used"] = false
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
		if index < 0 or index >= active_enemies.size():
			continue

		var enemy: Dictionary = active_enemies[index]
		var data: EnemyData = enemy["data"]

		# Ignore already-downed Beastmaster until all phase 1 allies are dead.
		if data.is_beastmaster_boss and !enemy["phase_two_started"] and enemy.has("downed") and enemy["downed"]:
			continue

		# First time Beastmaster hits 0 HP.
		if data.is_beastmaster_boss and !enemy["phase_two_started"]:
			enemy["hp"] = 1
			enemy["attack"] = 0
			enemy["crit"] = 0
			enemy["block"] = 0
			enemy["heal"] = 0
			enemy["rolled_faces"] = []

			clear_beastmaster_phase_one_statuses(enemy)
			clear_assignments_for_enemy(index)

			if beastmaster_has_living_phase1_allies(index):
				enemy["downed"] = true
				enemy["roll_text"] = "Downed"

				if (
					index < enemy_3d_nodes.size()
					and is_instance_valid(enemy_3d_nodes[index])
					and enemy_3d_nodes[index].sprite.sprite_frames.has_animation(
						"downed"
					)
				):
					enemy_3d_nodes[index].sprite.play("downed")
			else:
				enemy["downed"] = true
				enemy["roll_text"] = "Downed"

			continue

		apply_shatter_from_enemy(index)

		var defeated_name: String = data.enemy_name
		add_combat_log_entry(defeated_name + " defeated!")

		clear_assignments_for_enemy(index)
		defeated_enemies.append(data)

		if index < enemy_3d_nodes.size() and is_instance_valid(enemy_3d_nodes[index]):
			var enemy_node: Enemy3D = enemy_3d_nodes[index]
			var shattered: bool = false

			if enemy.has("freeze_stacks"):
				shattered = int(enemy["freeze_stacks"]) > 0

			if shattered:
				var camera_focused: bool = await cinematic_shatter_focus(
					enemy_node
				)

				await enemy_node.play_shatter_death(
					shatter_death_sound
				)

				if camera_focused:
					await shatter_camera_shake(
						combat_camera,
						0.32,
						0.22
					)

					await restore_shatter_camera()
			else:
				AudioManager.play_one_shot(
					enemy_death_sound,
					1.05,
					1.4
				)

				await enemy_node.death_animation()

		active_enemies.remove_at(index)

		if index < enemy_3d_nodes.size():
			enemy_3d_nodes.remove_at(index)

	# If Beastmaster is downed and all phase 1 allies are gone, start phase 2 now.
	# All Phase 1 death cleanup is now complete.
	refresh_enemy_buttons()
	update_enemy_3d_nodes()
	
	await get_tree().process_frame

	for i in active_enemies.size():
		var enemy: Dictionary = active_enemies[i]
		var data: EnemyData = enemy["data"]

		if !data.is_beastmaster_boss:
			continue

		if enemy["phase_two_started"]:
			continue

		if !enemy.get("downed", false):
			continue

		if beastmaster_has_living_phase1_allies(i):
			continue

		enemy["hp"] = 1

		await beastmaster_phase_transition(i)
		return

	refresh_enemy_buttons()
	update_enemy_3d_nodes()
	
func clear_beastmaster_phase_one_statuses(
	enemy: Dictionary
):
	enemy["bleed"] = 0
	enemy["exposed"] = false
	enemy["frozen"] = false
	enemy["freeze_stacks"] = 0
	
func beastmaster_has_living_phase1_allies(beastmaster_index: int) -> bool:
	for i in active_enemies.size():
		if i == beastmaster_index:
			continue

		if active_enemies[i]["hp"] > 0:
			return true

	return false
	
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
		"Round Summary — Damage dealt: "
			+ str(last_player_damage)
			+ " | Damage taken: "
			+ str(last_damage_taken)
	)

func win_combat():
	expedition_is_boss_fight = (
		expedition_is_boss_fight
		or is_current_encounter_boss()
	)

	combat_over = true
	AudioManager.play_one_shot(victory_sound)
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

	# A combat may award only one relic.
	# Guaranteed bounty relics take priority over random drops.
	if expedition_is_boss_fight and current_bounty != null:
		for relic in current_bounty.unlocked_relics:
			if relic == null:
				continue

			if owned_relics.has(relic):
				continue

			owned_relics.append(relic)
			last_unlocked_relics.append(relic)

			# Stop after awarding one guaranteed relic.
			break
	for enemy_data in defeated_enemies:
		total_gold_reward += enemy_data.gold_reward
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
	if randf() <= mulligem_drop_chance:
		add_mulligems(1)
		last_mulligems_gained += 1
	if last_dropped_faces.size() > 0:
		last_dropped_face = last_dropped_faces[0]
	if expedition_is_boss_fight:
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

	# Only roll a random relic if this combat has not already
	# awarded a guaranteed relic.
	if (
		last_unlocked_relics.is_empty()
		and !combat_relic_drop_pool.is_empty()
		and randf() <= combat_relic_drop_chance
	):
		var valid_relics: Array[RelicData] = []

		for relic in combat_relic_drop_pool:
			if relic == null:
				continue

			if owned_relics.has(relic):
				continue

			valid_relics.append(relic)

		if !valid_relics.is_empty():
			var dropped_relic: RelicData = (
				valid_relics.pick_random()
			)

			owned_relics.append(dropped_relic)
			last_unlocked_relics.append(dropped_relic)
			update_active_food_icons()
	run_encounters_completed += 1

	# Only normal encounters advance expedition progress here.
	# Boss completion happens after the player closes the loot panel.
	if !expedition_is_boss_fight:
		expedition_progress += 1

	save_run()
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
	if last_unlocked_relics.size() > 0:
		var relic: RelicData = last_unlocked_relics[0]
		await show_relic_acquisition(relic)
	
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
		
func update_prepare_hp_label():
	if prepare_hp_label == null:
		return

	prepare_hp_label.text = (
		"HP: "
		+ str(player_hp)
		+ "/"
		+ str(combat_max_player_hp)
	)
	
func open_shop_after_loot():
	loot_panel.visible = false

	var defeated_boss := (
		expedition_is_boss_fight
		or is_current_encounter_boss()
	)

	if defeated_boss:
		expedition_is_boss_fight = true
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
	combat_log_panel.visible = false
	screen_shake(0.15, 0.3)
	request_music_fade_out.emit()
	AudioManager.play_one_shot(player_death_sound)
	if has_relic("Witch's Charm"):
		consume_relic("Witch's Charm")
		player_hp = max_player_hp
		combat_max_player_hp = max_player_hp
		update_player_hp_label()
		expedition_active = false
		clear_all_combat_dice_state()
		is_in_town = true
		current_bounty = null
		current_encounter = null
		expedition_encounter_plan.clear()
		save_run()
		return_to_town_requested.emit()
		return
	clear_all_combat_dice_state()
	hide_all_combat_ui()
	show_death_screen()

	clear_food_buffs()
	
func restart_run():
	delete_run_save()
	get_tree().reload_current_scene()
	completed_bounties.clear()
	combat_log_entries.clear()
	combat_log_button.visible = false
	final_boss_unlocked = false
	current_bounty = null
	owned_relics.clear()
	last_unlocked_relics.clear()
	for bounty in bounty_pool:
		bounty.completed = false

	if final_boss_bounty != null:
		final_boss_bounty.completed = false
	witch_seen_this_run = false
	well_seen_this_run = false
	endless_choice_pending = false
	endless_choice_overlay.visible = false
	if FileAccess.file_exists(RUN_SAVE_PATH):
		DirAccess.remove_absolute(RUN_SAVE_PATH)
	rebuild_bounty_board()
	run_encounters_completed = 0
	# refresh_relic_panel()
	
func clear_food_buffs():
	next_combat_bonus_damage = 0
	next_combat_bonus_block = 0
	next_combat_heal = 0
	next_combat_bonus_max_hp = 0
	active_combat_bonus_block = 0
	active_combat_bonus_damage = 0

	for item in active_food_items:
		if item == null:
			continue

		if item.grants_trait == null:
			continue

		var trait_id: String = item.grants_trait.trait_id

		if trait_id.is_empty():
			continue

		player_statuses[trait_id] = 0

	active_food_items.clear()
	update_active_food_icons()
	update_player_status_icons()
	
func apply_consumable_trait(item: ConsumableItem):
	if item == null:
		return

	if item.grants_trait == null:
		return

	var trait_id: String = item.grants_trait.trait_id
	var trait_value: int = item.grants_trait.value

	if trait_id.is_empty():
		return

	player_statuses[trait_id] = trait_value

	update_player_status_icons()
	
func start_new_combat():
	expedition_is_boss_fight = is_current_encounter_boss()
	last_echoable_effect.clear()
	resolving_mind_echo = false
	combat_over = false
	is_resolving_turn = false
	is_in_town = false
	combat_log_entries.clear()
	combat_log_text.clear()
	refresh_combat_log()
	combat_log_panel.visible = false
	combat_log_button.visible = true
	shop_panel.visible = false
	loot_panel.visible = false
	encounter_panel.visible = false
	expedition_camp_panel.visible = false
	prepare_expedition_panel.visible = false
	town_panel.visible = false
	player_health_bar.visible = true
	player_health_label.visible = true
	set_combat_ui_enabled(true)

	begin_expedition_button.visible = false
	end_round_button.visible = true
	mulligem_button.visible = true

	$DiceArea.visible = true
	$DiceArea/ReserveHBox.visible = true

	dodge_targets.clear()
	reversal_targets.clear()
	defeated_enemies.clear()
	active_enemies.clear()
	selected_enemy_index = -1
	selected_dice_order.clear()
	break_focus_targets.clear()

	actions_container.get_parent().visible = true
	hits_container.get_parent().visible = true
	crits_container.get_parent().visible = true
	blocks_container.get_parent().visible = true
	gold_container.get_parent().visible = true
	healing_container.get_parent().visible = true
	misses_container.get_parent().visible = true
	last_player_damage = 0
	last_damage_taken = 0
	clear_all_combat_dice_state()
	for die in dice_nodes:
		if is_instance_valid(die):
			die.queue_free()

	dice_nodes.clear()
	clear_all_dice_groups()
	hide_all_groups()

	await get_tree().process_frame

	combat_number += 1
	update_combat_number_label()
	combat_max_player_hp = (
		max_player_hp
		+ next_combat_bonus_max_hp
	)

	player_hp = min(
		player_hp + next_combat_heal,
		combat_max_player_hp
	)

	# Save the fully prepared HP state used when restarting
	# this encounter after quitting.
	player_hp_at_combat_start = player_hp
	save_run()
	active_combat_bonus_block = next_combat_bonus_block
	active_combat_bonus_damage = next_combat_bonus_damage
	player_block = active_combat_bonus_block
	if has_relic("Iron Charm"):
		active_combat_bonus_block += 2
		player_block += 2
	update_player_block_label()
	update_player_hp_label()
	print("START NEW COMBAT current_encounter: ", current_encounter.encounter_name if current_encounter != null else "NULL")
	load_encounter(current_encounter)

	spawn_dice()
	for die in dice_nodes:
		if is_instance_valid(die):
			die.visible = true
	await roll_all_dice()
	
	mulligem_used_this_turn = false
	update_mulligem_button()
	apply_damage_bonus_to_dice_visuals()
	calculate_auto_block()
	regroup_dice()
	update_group_visibility()
	update_player_status_icons()
	update_reserve_slots_display()
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
	if is_in_town or !expedition_active:
		combat_number_label.visible = false
		return

	var total_encounters: int = expedition_required_encounters + 1
	var current_encounter_number: int = expedition_progress + 1

	if expedition_is_boss_fight or is_current_encounter_boss():
		current_encounter_number = total_encounters

	current_encounter_number = clamp(
		current_encounter_number,
		1,
		total_encounters
	)

	combat_number_label.text = (
		"Encounter: "
		+ str(current_encounter_number)
		+ "/"
		+ str(total_encounters)
	)

	if expedition_is_boss_fight or is_current_encounter_boss():
		combat_number_label.text += " — Boss"

	combat_number_label.visible = true
	
func clear_all_combat_dice_state():
	selected_dice_order.clear()
	selected_enemy_index = -1

	for die in dice_nodes:
		if !is_instance_valid(die):
			continue

		die.assigned_enemy_index = -1
		die.selected = false
		die.reserved = false
		die.came_from_reserve = false
		die.visible = false
		die.set_compact_mode(false)
		die.update_visual()

		if die.get_parent() != rolling_hidden_area:
			die.reparent(rolling_hidden_area)

	for container in assigned_enemy_containers:
		if !is_instance_valid(container):
			continue

		for child in container.get_children():
			if child is DiceNode:
				child.assigned_enemy_index = -1
				child.selected = false
				child.reserved = false
				child.visible = false

	for child in assigned_dice_overlay.get_children():
		child.queue_free()

	assigned_enemy_containers.clear()

	update_assigned_panel_visibility()
	update_group_visibility()
	
func buy_reserve_slot():
	if gold < reserve_slot_cost:
		return

	gold -= reserve_slot_cost
	reserve_slots += 1
	reserve_slot_cost += 10
	AudioManager.play_ui(ui_click_sound)
	update_gold_label()
	update_reserve_slots_display()
	
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
	face_inventory.append(
		hit_2_face.duplicate(true)
	)
	AudioManager.play_ui(ui_click_sound)
	update_gold_label()
	
func make_inventory_faces_unique():
	for i in face_inventory.size():
		var face: DiceFace = face_inventory[i]

		if face == null:
			continue

		face_inventory[i] = face.duplicate(true)
		
	# DIE GRAFTING ######################################################################

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
	clear_fusion_undo_state()
	reset_edit_panel_to_normal_mode()
	if shop_panel.visible == false:
		return
		
	edit_dice_title_label.text = "Edit Faces"
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
	update_volatile_core_button()


func close_edit_dice_panel():
	clear_fusion_undo_state()
	if edit_dice_return_context == "dice_bag":
		dice_panel_read_only = false
		edit_dice_panel.visible = false
		edit_dice_return_context = ""
		assigned_dice_overlay.visible = true
		edit_dice_title_label.text = "Edit Faces"
		return
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
	dice_panel_read_only = false
	apply_volatile_core_button.visible = true
	die_crafting_panel.visible = true
	sell_face_panel.visible = true
	inventory_faces_container.get_parent().get_parent().visible = true
	close_edit_button.text = "Close"
	update_begin_expedition_button_visibility()
	
func refresh_edit_dice_panel():
	print("Refreshing editor. Dice:", owned_dice.size(), " Faces:", face_inventory.size())
	rebuild_owned_dice_grid()
	var town_only := edit_dice_return_context == "town"
	
	sell_value_label.text = "Drop a face here to sell"
	sell_face_panel.visible = town_only
	die_crafting_panel.visible = town_only
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
		var face: DiceFace = selected_edit_die.faces[i]

		var face_button: EquippedFaceButton = (
			equipped_face_button_scene.instantiate()
		)

		die_faces_container.add_child(face_button)

		face_button.setup(
			face,
			i,
			i == selected_die_face_index
		)

		face_button.face_dropped.connect(
			handle_face_drop
		)
		
	
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
		"break_focus",
		"shield_bash",
		"fireball",
		"mana_shield",
		"mind_echo",
		"blizzard",
		"chain_lightning"
	]

	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override(
		"h_separation",
		8
	)
	grid.add_theme_constant_override(
		"v_separation",
		8
	)

	inventory_faces_container.add_child(grid)

	var displayed_indices: Array[int] = []

	# Display all recognized face types in the chosen order.
	for result_type in face_order:
		for i in face_inventory.size():
			var face: DiceFace = face_inventory[i]

			if face == null:
				continue

			if face.result_type != result_type:
				continue

			add_inventory_face_button(
				grid,
				face,
				i
			)

			displayed_indices.append(i)

	# Display any new or unrecognized result types afterward.
	for i in face_inventory.size():
		if displayed_indices.has(i):
			continue

		var face: DiceFace = face_inventory[i]

		if face == null:
			continue

		push_warning(
			"Inventory face type is missing from face_order: "
			+ face.result_type
		)

		add_inventory_face_button(
			grid,
			face,
			i
		)
		
func add_inventory_face_button(
	grid: GridContainer,
	face: DiceFace,
	inventory_index: int
):
	var button: InventoryFaceButton = (
		inventory_face_button_scene.instantiate()
	)

	grid.add_child(button)

	button.setup(
		face,
		inventory_index,
		selected_inventory_face_indices.has(
			inventory_index
		)
	)

	button.face_dropped.connect(
		handle_face_drop
	)

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

			button.set_cursed(!owned_dice[global_index].editable)

			button.pressed.connect(select_edit_die.bind(owned_dice[global_index]))

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

	if new_face == null:
		end_fusion_mode()
		refresh_edit_dice_panel()
		return

	selected_inventory_face_indices.sort()
	selected_inventory_face_indices.reverse()

	for index in selected_inventory_face_indices:
		face_inventory.remove_at(index)

	face_inventory.append(new_face)
	AudioManager.play_one_shot(graft_face_sound)
	end_fusion_mode()
	refresh_edit_dice_panel()
	
func select_edit_die(die: DiceData):
	selected_edit_die = die
	selected_die_face_index = -1
	selected_die_face_index_2 = -1

	AudioManager.play_ui(ui_click_sound)

	refresh_edit_dice_panel()
	update_volatile_core_button()

	if !die.editable:
		edit_warning_label.text = "Cursed Die\nThis die cannot be edited."
	elif dice_panel_read_only:
		edit_warning_label.text = "Dice Bag - View your dice."
	else:
		edit_warning_label.text = ""
	
func update_volatile_core_button():
	var core_count_text: String = (
		" (" + str(volatile_cores) + ")"
	)

	var explanation: String = (
		"Volatile Core\n"
		+ "Permanently makes the selected die Exploding.\n\n"
		+ "When an Exploding die lands on its final face, "
		+ "it creates and rolls a temporary copy of itself.\n"
		+ "Temporary copies can continue exploding.\n\n"
	)

	apply_volatile_core_button.text = (
		"Apply Volatile Core"
		+ core_count_text
	)

	apply_volatile_core_button.tooltip_text = explanation
	apply_volatile_core_button.disabled = true

	# Neutral disabled appearance.
	apply_volatile_core_button.modulate = Color.WHITE

	if selected_edit_die == null:
		apply_volatile_core_button.text = (
			"Select a Die"
			+ core_count_text
		)

		apply_volatile_core_button.tooltip_text = (
			explanation
			+ "\n\nSelect a die first."
		)
		return

	if selected_edit_die.sides <= 4:
		apply_volatile_core_button.text = (
			"D4 Cannot Explode"
			+ core_count_text
		)

		apply_volatile_core_button.tooltip_text = (
			explanation
			+ "\n\nThe selected D4 cannot accept a Volatile Core."
		)

		apply_volatile_core_button.modulate = Color(
			0.55,
			0.55,
			0.55,
			1.0
		)
		return

	if selected_edit_die.can_explode:
		apply_volatile_core_button.text = (
			"Already Exploding"
			+ core_count_text
		)

		apply_volatile_core_button.tooltip_text = (
			explanation
			+ "\n\nThe selected die is already Exploding."
		)

		# Orange instead of the ordinary unavailable gray.
		apply_volatile_core_button.modulate = Color(
			1.0,
			0.62,
			0.28,
			1.0
		)
		return

	if volatile_cores <= 0:
		apply_volatile_core_button.text = (
			"No Volatile Cores"
		)

		apply_volatile_core_button.tooltip_text = (
			explanation
			+ "\n\nYou do not currently own a Volatile Core."
		)

		apply_volatile_core_button.modulate = Color(
			0.45,
			0.45,
			0.45,
			1.0
		)
		return

	apply_volatile_core_button.disabled = false
	apply_volatile_core_button.modulate = Color.WHITE
	
func get_max_face_value_for_die(die_data: DiceData, face: DiceFace) -> int:
	if face.result_type in [
		"fireball",
		"shield_bash",
		"dodge",
		"reversal",
		"twist_knife",
		"break_focus",
		"mana_shield",
		"mind_echo",
		"blizzard",
		"chain_lightning"
	]:
		return 0

	if face.result_type == "crit":
		return die_data.sides

	return int(die_data.sides / 2)
	
func face_fits_die(die_data: DiceData, face: DiceFace) -> bool:
	if die_data == null or face == null:
		return false

	return face.value <= get_max_face_value_for_die(die_data, face)
	
func can_fuse_faces(
	face_a: DiceFace,
	face_b: DiceFace
) -> bool:
	if face_a == null or face_b == null:
		return false

	var type_a: String = face_a.result_type
	var type_b: String = face_b.result_type

	# ---------------------------------------------------------
	# Explicit special recipes
	# ---------------------------------------------------------

	if (
		(type_a == "dodge" and type_b == "crit")
		or
		(type_a == "crit" and type_b == "dodge")
	):
		return true

	if (
		(type_a == "crit" and type_b == "bleed")
		or
		(type_a == "bleed" and type_b == "crit")
	):
		return true

	if (
		(type_a == "crit" and type_b == "heal")
		or
		(type_a == "heal" and type_b == "crit")
	):
		return true

	# ---------------------------------------------------------
	# Faces that cannot use generic fusion
	# ---------------------------------------------------------

	var non_fusible_types: Array[String] = [
		"miss",
		"dodge",
		"reversal",
		"twist_knife",
		"break_focus",
		"shield_bash",
		"fireball",
		"mana_shield",
		"mind_echo",
		"blizzard",
		"chain_lightning"
	]

	if type_a in non_fusible_types:
		return false

	if type_b in non_fusible_types:
		return false

	# ---------------------------------------------------------
	# Normal fusion requires identical types and values
	# ---------------------------------------------------------

	if type_a != type_b:
		return false

	if face_a.value != face_b.value:
		return false

	return true

func create_fused_face(
	face_a: DiceFace,
	face_b: DiceFace
) -> DiceFace:
	if !can_fuse_faces(face_a, face_b):
		show_edit_message("These faces cannot be fused.")
		AudioManager.play_ui(ui_fail_sound)
		return null

	var type_a: String = face_a.result_type
	var type_b: String = face_b.result_type

	if (
		(type_a == "dodge" and type_b == "crit")
		or
		(type_a == "crit" and type_b == "dodge")
	):
		return reversal_face_template.duplicate(true)

	if (
		(type_a == "crit" and type_b == "bleed")
		or
		(type_a == "bleed" and type_b == "crit")
	):
		return create_twist_knife_face()

	if (
		(type_a == "crit" and type_b == "heal")
		or
		(type_a == "heal" and type_b == "crit")
	):
		return create_break_focus_face()

	# Generic fusion is only reachable for identical types
	# with identical values because can_fuse_faces validated it.
	var new_face: DiceFace = face_a.duplicate(true)

	new_face.value = face_a.value + 1
	new_face.face_name = get_face_display_name(new_face)

	return new_face


func create_upgraded_face(face: DiceFace) -> DiceFace:
	if face == null:
		return null

	if face.result_type == "miss":
		return null

	var new_face: DiceFace = face.duplicate(true)
	new_face.value += 1
	new_face.face_name = get_face_display_name(new_face)

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
	if dice_panel_read_only:
		return
	if die_fragments < sides:
		show_edit_message(
			"Need %d Die Fragments (%d/%d)"
			% [sides, die_fragments, sides]
		)
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
	if twist_knife_face_template != null:
		return twist_knife_face_template.duplicate(true)

	var face := DiceFace.new()
	face.face_name = "Twist Knife"
	face.result_type = "twist_knife"
	face.value = 0
	return face
	
func create_break_focus_face() -> DiceFace:
	var face := DiceFace.new()
	face.face_name = "Break Focus"
	face.result_type = "break_focus"
	face.value = 0
	face.icon = break_focus_face_template.icon
	return face

		
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
			capture_fusion_undo_state()

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
	if face == null:
		return ""

	return face.get_display_name()
	
func count_misses(die_data: DiceData) -> int:
	var count := 0

	for face in die_data.faces:
		if face.result_type == "miss":
			count += 1

	return count

func get_mana_shield_block(die: DiceNode) -> int:
	if die == null or die.dice_data == null:
		return 0

	return count_misses(die.dice_data)


func get_blizzard_freeze(die: DiceNode) -> int:
	if die == null or die.dice_data == null:
		return 0

	return int(
		floor(
			float(count_misses(die.dice_data)) / 2.0
		)
	)


func get_chain_lightning_damage(die: DiceNode) -> int:
	if die == null or die.dice_data == null:
		return 0

	return int(
		floor(
			float(count_misses(die.dice_data)) / 2.0
		)
	)
	
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

######################################################################

func count_faces_of_type(die_data: DiceData, result_type: String) -> int:
	var count := 0

	for face in die_data.faces:
		if face.result_type == result_type:
			count += 1

	return count
	
func get_fireball_damage(die: DiceNode) -> int:
	if die == null or !is_instance_valid(die):
		return 0

	if die.dice_data == null:
		return 0

	return count_faces_of_type(
		die.dice_data,
		"miss"
	)
	
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

func update_reserve_slots_display():
	if reserve_locks_container == null:
		return

	for die in dice_nodes:
		if !is_instance_valid(die):
			continue

		if die.selected or die.assigned_enemy_index != -1:
			if die.reserved:
				die.reserved = false
				die.update_visual()

	var reserved_count: int = get_reserved_die_count()

	for child in reserve_locks_container.get_children():
		child.queue_free()

	for slot_index in reserve_slots:
		var lock_icon := TextureRect.new()

		lock_icon.custom_minimum_size = Vector2(76, 76)
		lock_icon.size = Vector2(76, 76)
		lock_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		lock_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		lock_icon.mouse_filter = Control.MOUSE_FILTER_PASS

		if slot_index < reserved_count:
			lock_icon.texture = reserve_locked_texture
			lock_icon.tooltip_text = (
				"Reserved slot "
				+ str(slot_index + 1)
				+ ": occupied"
			)
		else:
			lock_icon.texture = reserve_unlocked_texture
			lock_icon.tooltip_text = (
				"Reserved slot "
				+ str(slot_index + 1)
				+ ": available"
			)

		reserve_locks_container.add_child(lock_icon)
			
func clear_assignments_for_enemy(enemy_index: int):
	for die in dice_nodes:
		if !is_instance_valid(die):
			continue

		if die.assigned_enemy_index != enemy_index:
			continue

		die.assigned_enemy_index = -1
		die.selected = false
		die.reserved = false

		selected_dice_order.erase(die)

		die.update_visual()

	regroup_dice()
	calculate_auto_block()
	update_reserve_slots_display()
	update_assigned_panel_visibility()
	
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

	connect_combat_die_signals(die_node)

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

	var final_container: GridContainer = (
		get_container_for_die(die_node)
	)

	if final_container == null:
		return

	final_container.get_parent().visible = true

	await get_tree().process_frame
	await die_node.fly_to_container(final_container)

	die_node.visible = true
	update_group_visibility()

	die_node.set_compact_mode(false)
	die_node.set_base_visual_scale(
		Vector2.ONE * get_combat_die_scale()
	)

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
	if !event.is_action_pressed("ui_cancel"):
		return

	if close_topmost_popup():
		get_viewport().set_input_as_handled()
	var mouse_pos := get_viewport().get_mouse_position()
	var from := camera.project_ray_origin(mouse_pos)
	var to := from + camera.project_ray_normal(mouse_pos) * 1000.0

	var query := PhysicsRayQueryParameters3D.create(from, to)
	var result: Dictionary = get_viewport().world_3d.direct_space_state.intersect_ray(query)
	
	if event.is_action_pressed("ui_cancel"):
		if options_overlay.visible:
			close_options_menu()
		else:
			open_options_menu()
			
	if result.is_empty():
		return
	
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
		
func close_topmost_popup() -> bool:
	# These overlays should not be dismissible with Escape because
	# they require the player to make or acknowledge a choice.
	if beastmaster_transition_running:
		return false

	if is_resolving_turn:
		return false
		
	if death_overlay.visible:
		return false

	if endless_choice_overlay.visible:
		return false

	if relic_reward_overlay.visible:
		return false

	# Options should always close first because it may be opened
	# over another menu.
	if options_overlay.visible:
		close_options_menu()
		return true

	# Dice Bag currently uses the Edit Dice panel in read-only mode.
	if (
		edit_dice_panel.visible
		and edit_dice_return_context == "dice_bag"
	):
		close_edit_dice_panel()
		return true

	if edit_dice_panel.visible:
		close_edit_dice_panel()
		return true

	if food_craft_panel.visible:
		close_food_crafting()
		return true

	if merchant_panel.visible:
		close_merchant()
		return true

	if bounty_board_panel.visible:
		close_bounty_board()
		return true

	if prepare_expedition_panel.visible:
		close_prepare_expedition_with_escape()
		return true

	if trophy_panel.visible:
		close_trophies()
		return true

	if loot_panel.visible:
		# Loot represents a required progression step.
		# Do not let Escape skip it.
		return false

	if expedition_camp_panel.visible:
		# Camp is a full screen rather than a popup.
		return false

	return false
	
func close_prepare_expedition_with_escape():
	prepare_expedition_panel.visible = false

	match prepare_return_context:
		"camp":
			expedition_camp_panel.visible = true

		"town":
			town_menu_closed.emit()

		_:
			if expedition_active:
				expedition_camp_panel.visible = true
			else:
				town_menu_closed.emit()

	prepare_return_context = ""
	update_begin_expedition_button_visibility()
	
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

func tween_face_icon_to_player(
	die: DiceNode,
	face: DiceFace
):
	if die == null or !is_instance_valid(die):
		return

	if face == null or face.icon == null:
		return

	if player_3d_node == null or !is_instance_valid(player_3d_node):
		return

	var camera := get_viewport().get_camera_3d()

	if camera == null:
		return

	var flying_icon := TextureRect.new()

	flying_icon.texture = face.icon
	flying_icon.custom_minimum_size = Vector2(64, 64)
	flying_icon.size = Vector2(64, 64)
	flying_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	flying_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	flying_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flying_icon.z_index = 1000

	add_child(flying_icon)

	var start_position := (
		die.global_position
		+ die.size * 0.5
		- flying_icon.size * 0.5
	)

	var target_position := camera.unproject_position(
		player_3d_node.global_position + Vector3(0, 1.0, 0)
	)

	target_position -= flying_icon.size * 0.5

	flying_icon.global_position = start_position
	flying_icon.pivot_offset = flying_icon.size * 0.5
	flying_icon.scale = Vector2(0.8, 0.8)

	var tween := create_tween()
	tween.set_parallel(true)

	tween.tween_property(
		flying_icon,
		"global_position",
		target_position,
		0.28
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	tween.tween_property(
		flying_icon,
		"rotation",
		TAU,
		0.28
	)

	tween.tween_property(
		flying_icon,
		"scale",
		Vector2(1.15, 1.15),
		0.20
	)

	await tween.finished

	var fade_tween := create_tween()
	fade_tween.set_parallel(true)

	fade_tween.tween_property(
		flying_icon,
		"scale",
		Vector2(0.35, 0.35),
		0.10
	)

	fade_tween.tween_property(
		flying_icon,
		"modulate:a",
		0.0,
		0.10
	)

	await fade_tween.finished

	flying_icon.queue_free()
		
func tween_face_icon_to_enemy(
	die: DiceNode,
	face: DiceFace,
	enemy_index: int
):
	if die == null or !is_instance_valid(die):
		return

	if face == null or face.icon == null:
		return

	if enemy_index < 0 or enemy_index >= enemy_3d_nodes.size():
		return

	var enemy_node: Enemy3D = enemy_3d_nodes[enemy_index]

	if enemy_node == null or !is_instance_valid(enemy_node):
		return

	var camera := get_viewport().get_camera_3d()

	if camera == null:
		return

	var flying_icon := TextureRect.new()

	flying_icon.texture = face.icon
	flying_icon.custom_minimum_size = Vector2(72, 72)
	flying_icon.size = Vector2(72, 72)
	flying_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	flying_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	flying_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flying_icon.z_index = 1000

	add_child(flying_icon)

	var start_position := (
		die.global_position
		+ die.size * 0.5
		- flying_icon.size * 0.5
	)

	var target_position := camera.unproject_position(
		enemy_node.global_position + Vector3(0, 1.0, 0)
	)

	target_position -= flying_icon.size * 0.5

	flying_icon.global_position = start_position
	flying_icon.pivot_offset = flying_icon.size * 0.5
	flying_icon.scale = Vector2(0.7, 0.7)

	var tween := create_tween()
	tween.set_parallel(true)

	tween.tween_property(
		flying_icon,
		"global_position",
		target_position,
		0.34
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	tween.tween_property(
		flying_icon,
		"rotation",
		TAU * 1.25,
		0.34
	)

	tween.tween_property(
		flying_icon,
		"scale",
		Vector2(1.2, 1.2),
		0.28
	)

	await tween.finished

	var impact_tween := create_tween()
	impact_tween.set_parallel(true)

	impact_tween.tween_property(
		flying_icon,
		"scale",
		Vector2(1.5, 1.5),
		0.08
	)

	impact_tween.tween_property(
		flying_icon,
		"modulate:a",
		0.0,
		0.08
	)

	await impact_tween.finished

	flying_icon.queue_free()
	
func spawn_enemy_heal_icon_particles(
	target_node: Node3D,
	particle_count: int = 7
):
	if heal_icon_texture == null:
		return

	if target_node == null or !is_instance_valid(target_node):
		return

	var camera := get_viewport().get_camera_3d()

	if camera == null:
		return

	var center_position := camera.unproject_position(
		target_node.global_position + Vector3(0, 1.0, 0)
	)

	for i in particle_count:
		var icon := TextureRect.new()

		icon.texture = heal_icon_texture
		icon.custom_minimum_size = Vector2(30, 30)
		icon.size = Vector2(30, 30)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.z_index = 900
		icon.modulate.a = 0.0

		add_child(icon)

		var start_offset := Vector2(
			randf_range(-25.0, 25.0),
			randf_range(-5.0, 20.0)
		)

		var end_offset := Vector2(
			randf_range(-60.0, 60.0),
			randf_range(-80.0, -45.0)
		)

		icon.global_position = (
			center_position
			+ start_offset
			- icon.size * 0.5
		)

		icon.pivot_offset = icon.size * 0.5
		icon.scale = Vector2(0.45, 0.45)
		icon.rotation = randf_range(-0.3, 0.3)

		var delay := float(i) * 0.035
		var tween := create_tween()

		tween.tween_interval(delay)

		tween.tween_property(
			icon,
			"modulate:a",
			1.0,
			0.10
		)

		tween.set_parallel(true)

		tween.tween_property(
			icon,
			"global_position",
			center_position
				+ end_offset
				- icon.size * 0.5,
			0.55
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

		tween.tween_property(
			icon,
			"scale",
			Vector2(0.85, 0.85),
			0.35
		)

		tween.tween_property(
			icon,
			"rotation",
			icon.rotation + randf_range(-0.6, 0.6),
			0.55
		)

		tween.chain().tween_property(
			icon,
			"modulate:a",
			0.0,
			0.20
		)

		tween.finished.connect(icon.queue_free)
		
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

func resolve_single_die_impact(
	enemy_index: int,
	die: DiceNode
):
	if enemy_index < 0 or enemy_index >= active_enemies.size():
		return

	if enemy_index >= enemy_3d_nodes.size():
		return

	if die.current_face == null:
		return

	var enemy: Dictionary = active_enemies[enemy_index]
	var enemy_node: Enemy3D = enemy_3d_nodes[enemy_index]
	var enemy_name: String = enemy["data"].enemy_name
	var face: DiceFace = die.current_face

	if enemy.has("downed") and enemy["downed"]:
		show_popup_text(
			enemy_node,
			"Downed",
			1.2,
			Color.GRAY
		)

		add_combat_log_entry(
			enemy_name + " is already downed."
		)
		return

	if !is_instance_valid(enemy_node):
		return

	await launch_die_at_enemy(die, enemy_index)

	match face.result_type:
		# -----------------------------------------------------
		# MIND ECHO
		# -----------------------------------------------------
		"mind_echo":
			if last_echoable_effect.is_empty():
				show_popup_text(
					enemy_node,
					"No Previous Effect",
					1.2,
					Color.GRAY
				)

				add_combat_log_entry(
					"Mind Echo failed because no previous die "
					+ "result had resolved."
				)

				return

			var copied_effect: Dictionary = (
				last_echoable_effect.duplicate(false)
			)

			await resolve_mind_echo_effect(
				copied_effect,
				die,
				enemy_index
			)

			return
		# -----------------------------------------------------
		# DODGE
		# -----------------------------------------------------
		"dodge":
			if !dodge_targets.has(enemy_index):
				dodge_targets.append(enemy_index)

			add_combat_log_entry(
				"Dodge will prevent "
					+ enemy_name
					+ "'s Crit damage this turn."
			)
			return

		# -----------------------------------------------------
		# REVERSAL
		# -----------------------------------------------------
		"reversal":
			if !reversal_targets.has(enemy_index):
				reversal_targets.append(enemy_index)

			add_combat_log_entry(
				"Reversal will reflect "
					+ enemy_name
					+ "'s Crit damage this turn."
			)
			return

		# -----------------------------------------------------
		# BREAK FOCUS
		# -----------------------------------------------------
		"break_focus":
			if !break_focus_targets.has(enemy_index):
				break_focus_targets.append(enemy_index)

			show_popup_text(
				enemy_node,
				"Break Focus",
				1.2,
				Color.PURPLE
			)

			add_combat_log_entry(
				"Break Focus will cancel "
					+ enemy_name
					+ "'s healing this turn."
			)
			return

		# -----------------------------------------------------
		# FREEZE
		# -----------------------------------------------------
		"freeze":
			if enemy["data"].crowd_control_immune:
				show_popup_text(
					enemy_node,
					"Immune",
					1.2,
					Color.ORANGE_RED
				)

				add_combat_log_entry(
					enemy_name + " is immune to Freeze."
				)

				update_enemy_3d_nodes()
				
				return

			enemy["frozen"] = true
			enemy["freeze_stacks"] += face.value

			AudioManager.play_one_shot(freeze_sound)

			show_popup_text(
				enemy_node,
				"Frozen +" + str(face.value),
				1.2,
				Color.CYAN
			)

			add_combat_log_entry(
				enemy_name
					+ " gained "
					+ str(face.value)
					+ " Freeze."
			)
			record_echoable_effect(
					"freeze",
					face.value,
					die,
					enemy_index
				)
			update_enemy_3d_nodes()
			return

		# -----------------------------------------------------
		# BLEED
		# -----------------------------------------------------
		"bleed":
			if enemy["block"] > 0:
				show_popup_text(
					enemy_node,
					"Blocked Bleed",
					1.0,
					Color.GRAY
				)

				add_combat_log_entry(
					enemy_name
						+ "'s Block prevented "
						+ str(face.value)
						+ " Bleed."
				)

				AudioManager.play_one_shot(
					hit_blocked_sound,
					0.9,
					1.1
				)
				record_echoable_effect(
					"bleed",
					face.value,
					die,
					enemy_index
				)
				update_enemy_3d_nodes()
				return

			enemy["bleed"] += face.value

			AudioManager.play_one_shot(
				hit_damage_sound,
				0.9,
				1.1
			)

			show_popup_text(
				enemy_node,
				"Bleed +" + str(face.value),
				1.2,
				Color.RED
			)

			add_combat_log_entry(
				enemy_name
					+ " gained "
					+ str(face.value)
					+ " Bleed."
			)

			update_enemy_3d_nodes()
			return

		# -----------------------------------------------------
		# TWIST KNIFE
		# -----------------------------------------------------
		"twist_knife":
			var bleed_value: int = enemy.get("bleed", 0)

			if bleed_value <= 0:
				show_popup_text(
					enemy_node,
					"No Bleed",
					1.0,
					Color.GRAY
				)

				add_combat_log_entry(
					"Twist Knife failed because "
						+ enemy_name
						+ " had no Bleed."
				)
				return

			enemy["bleed"] = 0
			enemy["hp"] -= bleed_value
			last_player_damage += bleed_value

			if enemy["hp"] < 0:
				enemy["hp"] = 0

			AudioManager.play_one_shot(
				hit_damage_sound,
				0.9,
				1.1
			)

			show_damage_popup(enemy_node, bleed_value)

			add_combat_log_entry(
				"Twist Knife consumed "
					+ str(bleed_value)
					+ " Bleed and dealt "
					+ str(bleed_value)
					+ " damage to "
					+ enemy_name
					+ "."
			)

			update_enemy_3d_nodes()
			return
		# -----------------------------------------------------
		# BLIZZARD
		# -----------------------------------------------------
		"blizzard":
			var freeze_amount: int = get_blizzard_freeze(
				die
			)

			await resolve_targeted_blizzard(
				enemy_index,
				freeze_amount
			)

			if freeze_amount > 0:
				record_echoable_effect(
					"blizzard",
					freeze_amount,
					die,
					enemy_index
				)

			return

		# -----------------------------------------------------
		# CHAIN LIGHTNING
		# -----------------------------------------------------
		"chain_lightning":
			var raw_damage: int = (
				get_chain_lightning_damage(die)
			)

			await resolve_targeted_chain_lightning(
				enemy_index,
				raw_damage
			)

			if raw_damage > 0:
				record_echoable_effect(
					"chain_lightning",
					raw_damage,
					die,
					enemy_index
				)

			return
		# -----------------------------------------------------
		# CRIT
		# -----------------------------------------------------
		"crit":
			var damage: int = face.value

			if (
				get_enemy_trait_value(enemy, "agile") > 0
				and !enemy["agile_used"]
			):
				enemy["agile_used"] = true

				show_popup_text(
					enemy_node,
					"Dodged Crit!",
					1.3,
					Color.CORNFLOWER_BLUE
				)

				add_combat_log_entry(
					enemy_name
						+ "'s Agile trait avoided a "
						+ str(damage)
						+ "-damage Crit."
				)
				record_echoable_effect(
					"crit",
					face.value,
					die,
					enemy_index
				)
				update_enemy_3d_nodes()
				return

			damage = apply_guardian_split(
				enemy_index,
				damage,
				true
			)

			enemy["hp"] -= damage
			enemy["exposed"] = true
			last_player_damage += damage

			if enemy["hp"] < 0:
				enemy["hp"] = 0

			AudioManager.play_one_shot(
				critical_hit_sound,
				0.85,
				1.15
			)

			show_popup_text(
				enemy_node,
				"-" + str(damage),
				1.7,
				Color.GOLD
			)

			show_popup_text(
				enemy_node,
				"EXPOSED",
				2.2,
				Color.YELLOW
			)

			add_combat_log_entry(
				"Crit dealt "
					+ str(damage)
					+ " damage to "
					+ enemy_name
					+ " and applied Exposed."
			)

			enemy_node.hit_flash()
			enemy_node.hurt_bump()
			screen_shake(0.07, 0.1)

			await hit_stop(0.03)

			update_enemy_3d_nodes()
			return

		# -----------------------------------------------------
		# SHIELD BASH
		# -----------------------------------------------------
		"shield_bash":
			var starting_block: int = player_block
			var raw_damage: int = starting_block

			if raw_damage <= 0:
				show_popup_text(
					enemy_node,
					"No Block",
					1.2,
					Color.GRAY
				)

				add_combat_log_entry(
					"Shield Bash failed because the player had no Block."
				)
				return

			player_block = int(
				ceil(float(player_block) / 2.0)
			)

			if starting_block == 1:
				player_block = 0

			update_player_block_label()
			update_player_3d_node()

			var damage: int = apply_guardian_split(
				enemy_index,
				raw_damage,
				false
			)

			var blocked_amount: int = min(
				damage,
				int(enemy["block"])
			)

			enemy["block"] -= blocked_amount
			damage -= blocked_amount

			if enemy["block"] < 0:
				enemy["block"] = 0

			if blocked_amount > 0:
				add_combat_log_entry(
					enemy_name
						+ " blocked "
						+ str(blocked_amount)
						+ " Shield Bash damage."
				)

				await show_enemy_hit_sequence(
					enemy_index,
					blocked_amount,
					0
				)

			if damage > 0:
				enemy["hp"] -= damage
				last_player_damage += damage

				if enemy["hp"] < 0:
					enemy["hp"] = 0

				await show_enemy_hit_sequence(
					enemy_index,
					0,
					damage
				)

			show_popup_text(
				player_3d_node,
				"Block "
					+ str(starting_block)
					+ " → "
					+ str(player_block),
				1.4,
				Color.CORNFLOWER_BLUE
			)

			add_combat_log_entry(
				"Shield Bash dealt "
					+ str(damage)
					+ " HP damage to "
					+ enemy_name
					+ " and reduced player Block from "
					+ str(starting_block)
					+ " to "
					+ str(player_block)
					+ "."
			)

			update_enemy_3d_nodes()
			return
		# -----------------------------------------------------
		# FIREBALL
		# -----------------------------------------------------
		"fireball":
			var raw_damage: int = get_fireball_damage(die)

			await play_fireball_cinematic(
				die,
				enemy_index
			)

			if raw_damage <= 0:
				show_popup_text(
					enemy_node,
					"No Misses",
					1.2,
					Color.GRAY
				)

				add_combat_log_entry(
					"Fireball dealt no damage because the die had no Miss faces."
				)

				update_enemy_3d_nodes()
				return

			var damage: int = apply_guardian_split(
				enemy_index,
				raw_damage,
				false
			)

			var blocked_amount: int = min(
				damage,
				int(enemy["block"])
			)

			enemy["block"] -= blocked_amount
			damage -= blocked_amount

			if enemy["block"] < 0:
				enemy["block"] = 0

			if blocked_amount > 0:
				add_combat_log_entry(
					enemy_name
						+ " blocked "
						+ str(blocked_amount)
						+ " Fireball damage."
				)

				await show_enemy_hit_sequence(
					enemy_index,
					blocked_amount,
					0
				)

			if damage > 0:
				var hp_before_fireball: int = enemy["hp"]

				enemy["hp"] -= damage

				if enemy["hp"] < 0:
					enemy["hp"] = 0

				var actual_damage: int = (
					hp_before_fireball - enemy["hp"]
				)

				last_player_damage += actual_damage

				show_damage_popup(
					enemy_3d_nodes[enemy_index],
					actual_damage
				)

				var fireball_shake_strength: float = clamp(
					0.045 + float(actual_damage) * 0.004,
					0.05,
					0.12
				)

				var fireball_shake_duration: float = clamp(
					0.12 + float(actual_damage) * 0.008,
					0.14,
					0.24
				)

				await shake_combat_camera(
					fireball_shake_duration,
					fireball_shake_strength
				)

				await get_tree().create_timer(0.25).timeout

				add_combat_log_entry(
					"Fireball dealt "
						+ str(actual_damage)
						+ " damage to "
						+ enemy_name
						+ " using "
						+ str(raw_damage)
						+ " Miss "
						+ (
							"face."
							if raw_damage == 1
							else "faces."
						)
				)
			else:
				add_combat_log_entry(
					enemy_name
						+ " blocked all "
						+ str(raw_damage)
						+ " Fireball damage."
				)
			record_echoable_effect(
				"fireball",
				raw_damage,
				die,
				enemy_index
			)
			update_enemy_3d_nodes()
			return
		# -----------------------------------------------------
		# NORMAL HIT
		# -----------------------------------------------------
		"hit":
			var base_damage: int = (
				face.value + active_combat_bonus_damage
			)

			var berserker_bonus: int = (
				get_player_berserker_bonus()
			)

			if berserker_bonus > 0:
				base_damage += berserker_bonus

				add_combat_log_entry(
					"Player Berserker added "
						+ str(berserker_bonus)
						+ " damage to the Hit."
				)

				show_popup_text(
					player_3d_node,
					"Berserker +" + str(berserker_bonus),
					1.1,
					Color.ORANGE_RED
				)

			var exposed_bonus: int = 0
			var axe_bonus: int = 0

			if enemy["exposed"]:
				exposed_bonus = 1
				enemy["exposed"] = false

				show_popup_text(
					enemy_node,
					"EXPOSED +1",
					2.2,
					Color.YELLOW
				)

			if (
				has_relic("Executioner's Axe")
				and enemy["bleed"] > 0
			):
				axe_bonus = 2
				base_damage += axe_bonus

				add_combat_log_entry(
					"Executioner's Axe added 2 damage against "
						+ enemy_name
						+ "."
				)

			if has_relic("Bloodstone"):
				enemy["bleed"] += 1

				add_combat_log_entry(
					"Bloodstone applied 1 Bleed to "
						+ enemy_name
						+ "."
				)

			if has_relic("Frozen Heart"):
				enemy["freeze_stacks"] += 1

				add_combat_log_entry(
					"Frozen Heart applied 1 Freeze to "
						+ enemy_name
						+ "."
				)

			base_damage = apply_guardian_split(
				enemy_index,
				base_damage,
				false
			)

			var blocked_amount: int = min(
				base_damage,
				int(enemy["block"])
			)

			enemy["block"] -= blocked_amount
			base_damage -= blocked_amount

			if enemy["block"] < 0:
				enemy["block"] = 0

			if blocked_amount > 0:
				add_combat_log_entry(
					enemy_name
						+ " blocked "
						+ str(blocked_amount)
						+ " Hit damage."
				)

				await show_enemy_hit_sequence(
					enemy_index,
					blocked_amount,
					0
				)

			var hp_damage: int = base_damage + exposed_bonus

			if exposed_bonus > 0:
				add_combat_log_entry(
					"Exposed dealt 1 damage to "
						+ enemy_name
						+ " through Block."
				)

			if hp_damage > 0:
				enemy["hp"] -= hp_damage
				last_player_damage += hp_damage

				if enemy["hp"] < 0:
					enemy["hp"] = 0

				await show_enemy_hit_sequence(
					enemy_index,
					0,
					hp_damage
				)

				add_combat_log_entry(
					"Hit dealt "
						+ str(hp_damage)
						+ " HP damage to "
						+ enemy_name
						+ "."
				)

				var spiked_value: int = get_enemy_trait_value(
					enemy,
					"spiked"
				)

				# Spikes only trigger if normal Hit damage reached HP.
				# The Exposed guaranteed point alone does not trigger it.
				if spiked_value > 0 and base_damage > 0:
					var hp_before_spikes: int = player_hp

					player_hp -= spiked_value

					if player_hp < 0:
						player_hp = 0

					var actual_spiked_damage: int = (
						hp_before_spikes - player_hp
					)

					last_damage_taken += actual_spiked_damage

					show_damage_popup(
						player_3d_node,
						actual_spiked_damage
					)

					add_combat_log_entry(
						enemy_name
							+ "'s Spiked trait dealt "
							+ str(actual_spiked_damage)
							+ " damage to the player."
					)

					update_player_hp_label()

					if player_hp <= 0:
						add_combat_log_entry(
							"The player was defeated by Spiked damage."
						)

						lose_combat()
						return
			record_echoable_effect(
				"hit",
				face.value + active_combat_bonus_damage,
				die,
				enemy_index
			)
			update_enemy_3d_nodes()
			return

		_:
			update_enemy_3d_nodes()
			return
			
func resolve_mind_echo_effect(
	effect: Dictionary,
	echo_die: DiceNode,
	echo_target_index: int
):
	if effect.is_empty():
		return

	var copied_type: String = String(
		effect.get("type", "")
	)

	var copied_value: int = int(
		effect.get("value", 0)
	)

	add_combat_log_entry(
		"Mind Echo repeated "
		+ copied_type.replace("_", " ").capitalize()
		+ "."
	)

	match copied_type:
		"hit":
			await resolve_echo_hit(
				echo_target_index,
				copied_value
			)

		"crit":
			await resolve_echo_crit(
				echo_target_index,
				copied_value
			)

		"freeze":
			await resolve_echo_freeze(
				echo_target_index,
				copied_value
			)

		"bleed":
			await resolve_echo_bleed(
				echo_target_index,
				copied_value
			)

		"fireball":
			await resolve_echo_area_or_target_damage(
				echo_target_index,
				copied_value,
				"Fireball"
			)

		"mana_shield":
			player_block += copied_value
			update_player_block_label()
			update_player_3d_node()

			show_popup_text(
				player_3d_node,
				"+" + str(copied_value) + " Block",
				1.3,
				Color.DEEP_SKY_BLUE
			)

		"blizzard":
			await resolve_targeted_blizzard(
				echo_target_index,
				copied_value,
				"Mind Echo Blizzard"
			)

		"chain_lightning":
			await resolve_targeted_chain_lightning(
				echo_target_index,
				copied_value,
				"Mind Echo Chain Lightning"
			)

		_:
			show_popup_text(
				player_3d_node,
				"Cannot Echo",
				1.2,
				Color.GRAY
			)

			return

	# Store the copied effect, not "mind_echo".
	# Therefore another Mind Echo repeats the same result.
	record_echoable_effect(
		copied_type,
		copied_value,
		echo_die,
		echo_target_index
	)
	
func resolve_echo_hit(
	enemy_index: int,
	damage: int
):
	if !is_valid_living_echo_target(enemy_index):
		return

	var enemy: Dictionary = active_enemies[enemy_index]
	var enemy_node: Enemy3D = enemy_3d_nodes[enemy_index]
	var enemy_name: String = enemy["data"].enemy_name

	damage = apply_guardian_split(
		enemy_index,
		damage,
		false
	)

	var blocked_amount: int = min(
		damage,
		int(enemy["block"])
	)

	enemy["block"] -= blocked_amount
	damage -= blocked_amount

	if enemy["block"] < 0:
		enemy["block"] = 0

	if blocked_amount > 0:
		await show_enemy_hit_sequence(
			enemy_index,
			blocked_amount,
			0
		)

		add_combat_log_entry(
			enemy_name
			+ " blocked "
			+ str(blocked_amount)
			+ " echoed Hit damage."
		)

	if damage > 0:
		var hp_before: int = enemy["hp"]

		enemy["hp"] -= damage

		if enemy["hp"] < 0:
			enemy["hp"] = 0

		var actual_damage: int = hp_before - enemy["hp"]

		last_player_damage += actual_damage

		await show_enemy_hit_sequence(
			enemy_index,
			0,
			actual_damage
		)

		add_combat_log_entry(
			"Mind Echo dealt "
			+ str(actual_damage)
			+ " Hit damage to "
			+ enemy_name
			+ "."
		)

	update_enemy_3d_nodes()
	
func resolve_echo_crit(
	enemy_index: int,
	damage: int
):
	if !is_valid_living_echo_target(enemy_index):
		return

	var enemy: Dictionary = active_enemies[enemy_index]
	var enemy_node: Enemy3D = enemy_3d_nodes[enemy_index]
	var enemy_name: String = enemy["data"].enemy_name

	if (
		get_enemy_trait_value(enemy, "agile") > 0
		and !enemy["agile_used"]
	):
		enemy["agile_used"] = true

		show_popup_text(
			enemy_node,
			"Dodged Crit!",
			1.3,
			Color.CORNFLOWER_BLUE
		)

		add_combat_log_entry(
			enemy_name + " dodged the echoed Crit."
		)

		return

	damage = apply_guardian_split(
		enemy_index,
		damage,
		true
	)

	var hp_before: int = enemy["hp"]

	enemy["hp"] -= damage
	enemy["exposed"] = true

	if enemy["hp"] < 0:
		enemy["hp"] = 0

	var actual_damage: int = hp_before - enemy["hp"]

	last_player_damage += actual_damage

	AudioManager.play_one_shot(
		critical_hit_sound,
		0.85,
		1.15
	)

	show_damage_popup(
		enemy_node,
		actual_damage
	)

	show_popup_text(
		enemy_node,
		"EXPOSED",
		2.2,
		Color.YELLOW
	)

	enemy_node.hit_flash()
	enemy_node.hurt_bump()

	screen_shake(0.07, 0.1)
	await hit_stop(0.03)

	add_combat_log_entry(
		"Mind Echo dealt "
		+ str(actual_damage)
		+ " Crit damage to "
		+ enemy_name
		+ " and applied Exposed."
	)

	update_enemy_3d_nodes()
	
func resolve_echo_freeze(
	enemy_index: int,
	freeze_amount: int
):
	if !is_valid_living_echo_target(enemy_index):
		return

	var enemy: Dictionary = active_enemies[enemy_index]
	var enemy_node: Enemy3D = enemy_3d_nodes[enemy_index]
	var enemy_name: String = enemy["data"].enemy_name

	if enemy["data"].crowd_control_immune:
		show_popup_text(
			enemy_node,
			"Immune",
			1.2,
			Color.ORANGE_RED
		)

		add_combat_log_entry(
			enemy_name + " is immune to echoed Freeze."
		)

		return

	enemy["frozen"] = true
	enemy["freeze_stacks"] += freeze_amount

	AudioManager.play_one_shot(freeze_sound)

	show_popup_text(
		enemy_node,
		"Freeze +" + str(freeze_amount),
		1.2,
		Color.CYAN
	)

	add_combat_log_entry(
		"Mind Echo applied "
		+ str(freeze_amount)
		+ " Freeze to "
		+ enemy_name
		+ "."
	)

	update_enemy_3d_nodes()
	
func resolve_echo_bleed(
	enemy_index: int,
	bleed_amount: int
):
	if !is_valid_living_echo_target(enemy_index):
		return

	var enemy: Dictionary = active_enemies[enemy_index]
	var enemy_node: Enemy3D = enemy_3d_nodes[enemy_index]
	var enemy_name: String = enemy["data"].enemy_name

	if enemy["block"] > 0:
		show_popup_text(
			enemy_node,
			"Blocked Bleed",
			1.0,
			Color.GRAY
		)

		AudioManager.play_one_shot(
			hit_blocked_sound,
			0.9,
			1.1
		)

		add_combat_log_entry(
			enemy_name
			+ "'s Block prevented the echoed Bleed."
		)

		return

	enemy["bleed"] += bleed_amount

	AudioManager.play_one_shot(
		hit_damage_sound,
		0.9,
		1.1
	)

	show_popup_text(
		enemy_node,
		"Bleed +" + str(bleed_amount),
		1.2,
		Color.RED
	)

	add_combat_log_entry(
		"Mind Echo applied "
		+ str(bleed_amount)
		+ " Bleed to "
		+ enemy_name
		+ "."
	)

	update_enemy_3d_nodes()
	
func resolve_echo_area_or_target_damage(
	enemy_index: int,
	raw_damage: int,
	effect_name: String
):
	if !is_valid_living_echo_target(enemy_index):
		return

	var enemy: Dictionary = active_enemies[enemy_index]
	var enemy_node: Enemy3D = enemy_3d_nodes[enemy_index]
	var enemy_name: String = enemy["data"].enemy_name

	var damage: int = apply_guardian_split(
		enemy_index,
		raw_damage,
		false
	)

	var blocked_amount: int = min(
		damage,
		int(enemy["block"])
	)

	enemy["block"] -= blocked_amount
	damage -= blocked_amount

	if enemy["block"] < 0:
		enemy["block"] = 0

	if blocked_amount > 0:
		await show_enemy_hit_sequence(
			enemy_index,
			blocked_amount,
			0
		)

	if damage > 0:
		var hp_before: int = enemy["hp"]

		enemy["hp"] -= damage

		if enemy["hp"] < 0:
			enemy["hp"] = 0

		var actual_damage: int = hp_before - enemy["hp"]

		last_player_damage += actual_damage

		show_damage_popup(
			enemy_node,
			actual_damage
		)

		enemy_node.hit_flash()
		enemy_node.hurt_bump()

		await shake_combat_camera(
			0.16,
			0.06
		)

		add_combat_log_entry(
			"Mind Echo repeated "
			+ effect_name
			+ " for "
			+ str(actual_damage)
			+ " damage to "
			+ enemy_name
			+ "."
		)
	else:
		add_combat_log_entry(
			enemy_name
			+ " blocked all echoed "
			+ effect_name
			+ " damage."
		)

	update_enemy_3d_nodes()
	

	

func is_valid_living_echo_target(
	enemy_index: int
) -> bool:
	if enemy_index < 0:
		return false

	if enemy_index >= active_enemies.size():
		return false

	if enemy_index >= enemy_3d_nodes.size():
		return false

	var enemy: Dictionary = active_enemies[enemy_index]
	var enemy_node: Enemy3D = enemy_3d_nodes[enemy_index]

	if !is_instance_valid(enemy_node):
		return false

	if enemy["hp"] <= 0:
		return false

	if enemy.has("downed") and enemy["downed"]:
		return false

	return true
	

func apply_guardian_split(
	target_index: int,
	damage: int,
	ignores_block: bool
) -> int:
	if damage <= 0:
		return damage

	var guardian_index: int = get_living_guardian_index(target_index)

	if guardian_index == -1:
		return damage

	var target_enemy: Dictionary = active_enemies[target_index]
	var guardian_enemy: Dictionary = active_enemies[guardian_index]

	var target_name: String = target_enemy["data"].enemy_name
	var guardian_name: String = guardian_enemy["data"].enemy_name

	var redirected_damage: int = int(ceil(float(damage) / 2.0))
	var remaining_damage: int = damage - redirected_damage

	var guardian_damage: int = redirected_damage
	var blocked_damage: int = 0

	if !ignores_block:
		var guardian_block: int = guardian_enemy["block"]

		blocked_damage = min(
			guardian_damage,
			guardian_block
		)

		guardian_enemy["block"] -= blocked_damage
		guardian_damage -= blocked_damage

		if guardian_enemy["block"] < 0:
			guardian_enemy["block"] = 0

		if blocked_damage > 0:
			show_popup_text(
				enemy_3d_nodes[guardian_index],
				"Block -" + str(blocked_damage),
				1.2,
				Color.CORNFLOWER_BLUE
			)

			add_combat_log_entry(
				guardian_name
					+ "'s Guardian Block absorbed "
					+ str(blocked_damage)
					+ " redirected damage."
			)

	if guardian_damage > 0:
		guardian_enemy["hp"] -= guardian_damage
		last_player_damage += guardian_damage

		if guardian_enemy["hp"] < 0:
			guardian_enemy["hp"] = 0

		show_damage_popup(
			enemy_3d_nodes[guardian_index],
			guardian_damage
		)

		add_combat_log_entry(
			guardian_name
				+ "'s Guardian trait redirected "
				+ str(guardian_damage)
				+ " damage away from "
				+ target_name
				+ "."
		)
	else:
		add_combat_log_entry(
			guardian_name
				+ "'s Guardian trait redirected the attack away from "
				+ target_name
				+ ", but its Block absorbed all redirected damage."
		)

	show_popup_text(
		enemy_3d_nodes[guardian_index],
		"Guardian",
		1.4,
		Color.CORNFLOWER_BLUE
	)

	update_enemy_3d_nodes()

	return remaining_damage
	
func get_living_guardian_index(target_index: int) -> int:
	for i in active_enemies.size():
		if i == target_index:
			continue

		if active_enemies[i]["hp"] <= 0:
			continue

		if get_enemy_trait_value(active_enemies[i], "guardian") > 0:
			return i

	return -1

func shake_combat_camera(
	duration: float = 0.18,
	strength: float = 0.08
):
	var camera: Camera3D = combat_camera

	if camera == null:
		camera = get_viewport().get_camera_3d()

	if camera == null:
		return

	var original_position: Vector3 = camera.position
	var elapsed: float = 0.0

	while elapsed < duration:
		var shake_falloff: float = 1.0 - (
			elapsed / duration
		)

		camera.position = original_position + Vector3(
			randf_range(-strength, strength),
			randf_range(-strength, strength),
			0.0
		) * shake_falloff

		await get_tree().process_frame
		elapsed += get_process_delta_time()

	camera.position = original_position
	
func apply_enemy_bleed():
	for i in active_enemies.size():
		if i < 0 or i >= active_enemies.size():
			continue

		var enemy: Dictionary = active_enemies[i]

		if enemy.get("downed", false):
			continue

		var enemy_name: String = (
			enemy["data"].enemy_name
		)

		var bleed_value: int = enemy.get(
			"bleed",
			0
		)

		if bleed_value <= 0:
			continue

		var hp_before_bleed: int = enemy["hp"]

		# Existing Bleed bypasses Block.
		enemy["hp"] -= bleed_value

		if enemy["hp"] < 0:
			enemy["hp"] = 0

		var actual_bleed_damage: int = (
			hp_before_bleed - enemy["hp"]
		)

		last_player_damage += actual_bleed_damage

		AudioManager.play_one_shot(
			hit_damage_sound,
			0.9,
			1.1
		)

		if (
			i < enemy_3d_nodes.size()
			and is_instance_valid(enemy_3d_nodes[i])
		):
			show_damage_popup(
				enemy_3d_nodes[i],
				actual_bleed_damage
			)

		add_combat_log_entry(
			"Bleed dealt "
			+ str(actual_bleed_damage)
			+ " damage to "
			+ enemy_name
			+ "."
		)

		enemy["bleed"] = max(
			bleed_value - 1,
			0
		)

		update_enemy_3d_nodes()

		await get_tree().create_timer(
			0.35
		).timeout
		
func launch_enemy_die_at_player(
	enemy_index: int,
	face: DiceFace,
	reflect_back: bool = false
):
	if enemy_index < 0 or enemy_index >= enemy_3d_nodes.size():
		return

	if player_3d_node == null or !is_instance_valid(player_3d_node):
		return

	var enemy_node: Enemy3D = enemy_3d_nodes[enemy_index]

	if !is_instance_valid(enemy_node):
		return

	var camera := get_viewport().get_camera_3d()

	if camera == null:
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
	flying_die.z_index = 1000

	var enemy_screen_position := camera.unproject_position(
		enemy_node.global_position + Vector3(0, 1.0, 0)
	)

	var player_screen_position := camera.unproject_position(
		player_3d_node.global_position + Vector3(0, 1.0, 0)
	)

	# Center the die on its source and destination points.
	var half_die_size: Vector2 = flying_die.size * 0.5

	var start_position: Vector2 = (
		enemy_screen_position - half_die_size
	)

	var player_target_position: Vector2 = (
		player_screen_position - half_die_size
	)

	flying_die.global_position = start_position
	flying_die.pivot_offset = half_die_size

	# Enemy die travels toward the player.
	var attack_tween := create_tween()
	attack_tween.set_parallel(true)

	attack_tween.tween_property(
		flying_die,
		"global_position",
		player_target_position,
		0.16
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	attack_tween.tween_property(
		flying_die,
		"rotation",
		TAU * 1.25,
		0.16
	)

	await attack_tween.finished

	if reflect_back:
		# Brief pause at the player so the reversal reads clearly.
		await get_tree().create_timer(0.06).timeout

		# Recalculate the enemy's screen position in case the camera moved.
		enemy_screen_position = camera.unproject_position(
			enemy_node.global_position + Vector3(0, 1.0, 0)
		)

		var reflected_target_position: Vector2 = (
			enemy_screen_position - half_die_size
		)

		var reversal_tween := create_tween()
		reversal_tween.set_parallel(true)

		reversal_tween.tween_property(
			flying_die,
			"global_position",
			reflected_target_position,
			0.22
		).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)

		reversal_tween.tween_property(
			flying_die,
			"rotation",
			flying_die.rotation + TAU * 1.5,
			0.22
		)

		reversal_tween.tween_property(
			flying_die,
			"scale",
			Vector2(1.15, 1.15),
			0.16
		)

		await reversal_tween.finished

		var impact_tween := create_tween()
		impact_tween.set_parallel(true)

		impact_tween.tween_property(
			flying_die,
			"scale",
			Vector2(1.4, 1.4),
			0.07
		)

		impact_tween.tween_property(
			flying_die,
			"modulate:a",
			0.0,
			0.07
		)

		await impact_tween.finished

	flying_die.queue_free()

func open_edit_dice_panel_from_town():
	clear_fusion_undo_state()
	reset_edit_panel_to_normal_mode()
	edit_dice_return_context = "town"
	town_panel.visible = false
	edit_dice_panel.visible = true
	sell_face_panel.visible = true
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
	var first_node: Dictionary = get_current_plan_node()

	if first_node.is_empty():
		push_error("Cannot start expedition. No plan node was found.")
		return

	match first_node.get("type", PLAN_COMBAT):
		PLAN_COMBAT:
			current_encounter = first_node.get("encounter", null)

			if current_encounter == null:
				push_error("Combat plan node has no encounter.")
				return

			combat_log_entries.clear()
			refresh_combat_log()
			combat_log_panel.visible = false

			start_new_combat()

		PLAN_WITCH:
			expedition_started.emit(PLAN_WITCH)

		PLAN_WELL:
			expedition_started.emit(PLAN_WELL)

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
	print("Bounty pool size: ", bounty_pool.size())

	for bounty in bounty_pool:
		print("Bounty: ", bounty.bounty_name, " completed=", bounty.completed)
	
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
	combat_log_panel.visible = false
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
	if current_bounty.reward_max_hp > 0:
		max_player_hp += current_bounty.reward_max_hp
		player_hp += current_bounty.reward_max_hp

		if player_hp > max_player_hp:
			player_hp = max_player_hp

		show_edit_message(
			"Maximum HP permanently increased by "
			+ str(current_bounty.reward_max_hp)
			+ "!"
		)
	for face in current_bounty.unlocked_merchant_faces:
		if !merchant_unlocked_faces.has(face):
			merchant_unlocked_faces.append(face)

	if all_bounties_completed():
		endless_choice_pending = true
	# refresh_relic_panel()
	current_bounty = null
	expedition_is_boss_fight = false
	expedition_progress = 0

	player_hp = max_player_hp
	update_player_hp_label()
	combat_log_button.visible = false
	shop_panel.visible = false
	loot_panel.visible = false
	edit_dice_panel.visible = false
	selected_bounty_label.text = "No Bounty Selected"
	
	print("Bounty completed. Returned to town.")
	
	clear_all_combat_dice_state()

	expedition_active = false
	is_in_town = true
	expedition_is_boss_fight = false
	expedition_progress = 0

	current_bounty = null
	current_encounter = null
	expedition_encounter_plan.clear()

	save_run()
	return_to_town_requested.emit()
	
func show_pending_endless_choice():
	if !endless_choice_pending:
		return

	endless_choice_pending = false
	show_endless_choice()
	
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
		update_reserve_slots_display()
		
	for relic in current_bounty.unlocked_relics:
		if !owned_relics.has(relic):
			owned_relics.append(relic)
			# refresh_relic_panel()
			
func show_expedition_camp():
	await get_tree().current_scene.fade_to_black()
	is_in_town = false
	combat_over = true
	is_resolving_turn = false
	is_rolling_dice = false
	combat_log_panel.visible = false
	set_combat_ui_enabled(false)
	
	expedition_camp_panel.visible = true
	town_panel.visible = false
	shop_panel.visible = false
	loot_panel.visible = false
	encounter_panel.visible = false
	prepare_expedition_panel.visible = false
	edit_dice_panel.visible = false
	food_craft_panel.visible = false
	merchant_panel.visible = false
	begin_expedition_button.visible = false
	end_round_button.visible = false
	mulligem_button.visible = false
	$DiceArea/ReserveHBox.visible = false
	player_health_bar.visible = false
	player_health_label.visible = false
	top_ui_background.visible = true
	bottom_ui_background.visible = true
	hide_combat_dice()
	hide_all_groups()

	selected_enemy_index = -1
	selected_dice_order.clear()

	update_expedition_progress_labels()
	update_camp_hp_label()
	update_mulligem_button()
	await get_tree().current_scene.fade_from_black()
	
func hide_combat_dice():
	for die in dice_nodes:
		if is_instance_valid(die):
			die.visible = false

	hide_all_groups()
	
func open_edit_dice_panel_from_camp():
	clear_fusion_undo_state()
	reset_edit_panel_to_normal_mode()
	edit_dice_return_context = "camp"
	expedition_camp_panel.visible = false
	edit_dice_panel.visible = true
	die_crafting_panel.visible = false
	sell_face_panel.visible = false
	refresh_edit_dice_panel()
	
func continue_expedition():
	if current_bounty == null:
		show_edit_message("No bounty loaded. Returning to town.")
		return_to_town_requested.emit()
		return

	expedition_camp_panel.visible = false
	if expedition_progress >= expedition_required_encounters:
		current_encounter = current_bounty.boss_encounter
		expedition_is_boss_fight = true

		save_run()
		start_new_combat()
		return
	var node := get_current_plan_node()

	if node.is_empty():
		show_edit_message("No expedition event found.")
		return

	match node.get("type", PLAN_COMBAT):
		PLAN_COMBAT:
			current_encounter = node["encounter"]
			expedition_is_boss_fight = expedition_progress >= expedition_required_encounters
			start_new_combat()

		PLAN_WITCH:
			expedition_started.emit("witch")
		PLAN_WELL:
			expedition_started.emit("well")
			
func is_current_encounter_boss() -> bool:
	if current_bounty == null:
		return false

	if current_bounty.boss_encounter == null:
		return false

	if current_encounter == null:
		return false

	if current_encounter == current_bounty.boss_encounter:
		return true

	var current_path: String = current_encounter.resource_path
	var boss_path: String = current_bounty.boss_encounter.resource_path

	return (
		current_path != ""
		and boss_path != ""
		and current_path == boss_path
	)
	
func claim_well_relic() -> RelicData:
	var valid_relics: Array[RelicData] = []

	for relic in combat_relic_drop_pool:
		if relic == null:
			continue

		if has_relic_name(relic.relic_name):
			continue

		valid_relics.append(relic)

	if valid_relics.is_empty():
		print("Well reward failed: no unowned relics remain.")
		return null

	var relic: RelicData = valid_relics.pick_random()

	owned_relics.append(relic)
	last_unlocked_relics.clear()
	last_unlocked_relics.append(relic)

	update_active_food_icons()
	save_run()

	return relic
	
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
	prepare_hp_label.visible = false
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

	if current_bounty == null:
		print("Cannot start expedition. current_bounty is null.")
		return

	combat_number = 0
	expedition_progress = 0
	expedition_is_boss_fight = false
	expedition_active = true
	is_in_town = false
	loaded_pending_encounter = false

	var extra_encounters := get_scaled_bounty_extra_encounters()

	expedition_required_encounters = randi_range(
		current_bounty.min_encounters_before_boss + extra_encounters,
		current_bounty.max_encounters_before_boss + extra_encounters
	)

	build_expedition_plan()
	var first_node := get_current_plan_node()

	if first_node.get("type", PLAN_COMBAT) == PLAN_COMBAT:
		current_encounter = first_node["encounter"]
	else:
		current_encounter = null

	print("Starting bounty: ", current_bounty.bounty_name)
	print("Required encounters: ", expedition_required_encounters)
	print("First encounter: ", current_encounter.encounter_name if current_encounter != null else "NULL")

	save_run()

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

	var purchased_relic: RelicData = current_merchant_relic

	if has_relic_name(purchased_relic.relic_name):
		current_merchant_relic = null
		rebuild_merchant()
		return

	gold -= merchant_relic_cost
	owned_relics.append(purchased_relic)
	current_merchant_relic = null

	AudioManager.play_ui(coin_purchase_sound)

	update_gold_label()
	update_active_food_icons()
	rebuild_merchant()
	save_run()

	merchant_panel.visible = false

	await show_relic_acquisition(purchased_relic)

	merchant_panel.visible = true
	merchant_gold_label.text = "Gold: " + str(gold)
	rebuild_merchant()
	
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
	if dice_panel_read_only:
		return
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
			
func update_sell_face_preview(face: DiceFace):
	if face == null:
		return

	var value := get_face_sell_value(face)
	sell_value_label.text = "Sell " + get_face_text(face) + "\n+" + str(value) + " Gold"

func clear_drag_fusion_preview():
	for child in die_faces_container.get_children():
		if child is EquippedFaceButton:
			child.set_drop_state("normal")

	if sell_value_label != null:
		sell_value_label.text = "Drop a face here to sell"
		
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

	var item_counts: Dictionary = {}
	var item_lookup: Dictionary = {}

	for item in consumable_inventory:
		if item == null:
			continue

		if !item_counts.has(item.item_name):
			item_counts[item.item_name] = 0
			item_lookup[item.item_name] = item

		item_counts[item.item_name] += 1

	var sorted_names: Array[String] = (
		get_sorted_consumable_names(item_lookup)
	)

	for item_name in sorted_names:
		var item: ConsumableItem = item_lookup[item_name]
		var count: int = item_counts[item_name]

		var button = item_button_scene.instantiate()
		prepare_consumables_container.add_child(button)

		button.setup(
			item.icon,
			"x" + str(count),
			""
		)

		button.tooltip_text = (
			item.item_name
			+ "\n"
			+ item.description
		)

		button.pressed.connect(
			use_consumable_item.bind(item)
		)
		
func handle_food_crafting_drop(
	dragged_item_name: String,
	target_item_name: String
):
	if dragged_item_name.is_empty():
		return

	if target_item_name.is_empty():
		return

	if dragged_item_name == target_item_name:
		if (
			get_consumable_count_by_name(
				dragged_item_name
			) < 2
		):
			show_food_crafting_message(
				"You need 2 "
				+ dragged_item_name
				+ " to use both as ingredients."
			)
			return

	selected_food_craft_names.clear()
	selected_food_craft_names.append(
		dragged_item_name
	)

	selected_food_craft_names.append(
		target_item_name
	)

	AudioManager.play_ui(ui_click_sound)

	rebuild_food_crafting_grid()
	update_craft_result_label()
	
func get_consumable_count_by_name(
	item_name: String
) -> int:
	var count: int = 0

	for item in consumable_inventory:
		if item == null:
			continue

		if item.item_name == item_name:
			count += 1

	return count
	
func show_food_crafting_message(
	message: String
):
	craft_result_label.text = message
	
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
	if (
		item.heal_amount > 0
		and item.next_combat_block == 0
		and item.next_combat_damage == 0
		and item.next_combat_max_hp == 0
	):
		player_hp += item.heal_amount

		if player_hp > combat_max_player_hp:
			player_hp = combat_max_player_hp

		consumable_inventory.remove_at(index)

		update_player_hp_label()
		update_camp_hp_label()
		update_prepare_hp_label()
		rebuild_prepare_consumables()
		save_run()
		return

	# Buff food: only one of each active at a time.
	if is_food_already_active(item):
		return

	active_food_items.append(item)
	apply_consumable_trait(item)
	next_combat_bonus_block += item.next_combat_block
	next_combat_bonus_damage += item.next_combat_damage
	next_combat_bonus_max_hp += item.next_combat_max_hp
	player_hp += item.next_combat_max_hp
	combat_max_player_hp = max_player_hp + next_combat_bonus_max_hp

	update_player_hp_label()
	update_camp_hp_label()
	update_prepare_hp_label()

	var temporary_max_hp := max_player_hp + next_combat_bonus_max_hp

	if player_hp > temporary_max_hp:
		player_hp = temporary_max_hp

	consumable_inventory.remove_at(index)

	rebuild_prepare_consumables()
	update_active_food_icons()
	update_prepare_hp_label()
	save_run()

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
	
func handle_face_drop(
	data: Dictionary,
	target_face: DiceFace,
	target_source_type: String,
	target_slot_index: int = -1,
	target_inventory_index: int = -1
):
	if dice_panel_read_only:
		return

	if !data.has("source_type") or !data.has("face"):
		return

	var dragged_face: DiceFace = data["face"]
	var source_type: String = String(
		data.get("source_type", "")
	)

	var source_inventory_index: int = int(
		data.get("inventory_index", -1)
	)

	if dragged_face == null:
		return

	clear_drag_fusion_preview()

	# ---------------------------------------------------------
	# INVENTORY -> INVENTORY
	# ---------------------------------------------------------
	if (
		source_type == "inventory"
		and target_source_type == "inventory"
	):
		try_fuse_inventory_faces_by_index(
			source_inventory_index,
			target_inventory_index
		)
		return

	# Anything involving an equipped face requires a selected die.
	if selected_edit_die == null:
		show_edit_message("Select a die first.")
		return

	if !selected_edit_die.editable:
		show_edit_message("Cursed dice cannot be edited.")
		return

	if (
		target_slot_index < 0
		or target_slot_index >= selected_edit_die.faces.size()
	):
		return

	if target_face == null:
		target_face = create_basic_miss_face()

	match source_type:
		# -----------------------------------------------------
		# INVENTORY -> EQUIPPED
		# -----------------------------------------------------
		"inventory":
			if (
				source_inventory_index < 0
				or source_inventory_index >= face_inventory.size()
			):
				return

			if (
				face_inventory[source_inventory_index]
				!= dragged_face
			):
				push_warning(
					"Dragged inventory face no longer matches "
					+ "its stored index."
				)
				return

			# Prevent replacing the final required Miss.
			if is_last_miss_slot(
				selected_edit_die,
				target_slot_index
			):
				if dragged_face.result_type != "miss":
					show_edit_message(
						"Every die must keep at least 1 Miss."
					)
					return

			if !face_fits_die(
				selected_edit_die,
				dragged_face
			):
				var max_value: int = (
					get_max_face_value_for_die(
						selected_edit_die,
						dragged_face
					)
				)

				show_edit_message(
					get_face_display_name(dragged_face)
					+ " is too strong for a D"
					+ str(selected_edit_die.sides)
					+ ".\nD"
					+ str(selected_edit_die.sides)
					+ " non-Crit faces can be value "
					+ str(max_value)
					+ " or lower."
				)
				return

			# Valid fusion.
			if can_fuse_faces(
				dragged_face,
				target_face
			):
				var fused_face: DiceFace = (
					create_fused_face(
						dragged_face,
						target_face
					)
				)

				if fused_face == null:
					return

				if !face_fits_die(
					selected_edit_die,
					fused_face
				):
					var max_value: int = (
						get_max_face_value_for_die(
							selected_edit_die,
							fused_face
						)
					)

					show_edit_message(
						get_face_display_name(fused_face)
						+ " is too strong for a D"
						+ str(selected_edit_die.sides)
						+ ".\nD"
						+ str(selected_edit_die.sides)
						+ " non-Crit faces can be value "
						+ str(max_value)
						+ " or lower."
					)
					return

				if would_remove_last_miss(
					selected_edit_die,
					target_slot_index
				):
					show_edit_message(
						"Every die must keep at least 1 Miss."
					)
					return

				capture_fusion_undo_state()

				selected_edit_die.faces[
					target_slot_index
				] = fused_face

				face_inventory.remove_at(
					source_inventory_index
				)

				AudioManager.play_one_shot(
					graft_face_sound
				)

			# Invalid fusion means swap.
			else:
				selected_edit_die.faces[
					target_slot_index
				] = dragged_face

				# Replace the exact inventory entry instead of
				# removing and appending it.
				face_inventory[
					source_inventory_index
				] = target_face

				AudioManager.play_one_shot(
					graft_face_sound
				)

		# -----------------------------------------------------
		# EQUIPPED -> EQUIPPED
		# -----------------------------------------------------
		"equipped":
			if !data.has("slot"):
				return

			var source_slot: int = int(
				data["slot"]
			)

			if (
				source_slot < 0
				or source_slot >= selected_edit_die.faces.size()
			):
				return

			if source_slot == target_slot_index:
				return

			var source_face: DiceFace = (
				selected_edit_die.faces[source_slot]
			)

			if source_face == null:
				source_face = create_basic_miss_face()

			# Valid equipped-to-equipped fusion.
			if can_fuse_faces(
				source_face,
				target_face
			):
				var fused_face: DiceFace = (
					create_fused_face(
						source_face,
						target_face
					)
				)

				if fused_face == null:
					return

				if !face_fits_die(
					selected_edit_die,
					fused_face
				):
					var max_value: int = (
						get_max_face_value_for_die(
							selected_edit_die,
							fused_face
						)
					)

					show_edit_message(
						get_face_display_name(fused_face)
						+ " is too strong for a D"
						+ str(selected_edit_die.sides)
						+ ".\nD"
						+ str(selected_edit_die.sides)
						+ " non-Crit faces can be value "
						+ str(max_value)
						+ " or lower."
					)
					return

				if would_remove_last_miss(
					selected_edit_die,
					target_slot_index
				):
					show_edit_message(
						"Every die must keep at least 1 Miss."
					)
					return

				capture_fusion_undo_state()

				selected_edit_die.faces[
					target_slot_index
				] = fused_face

				selected_edit_die.faces[
					source_slot
				] = create_basic_miss_face()

				AudioManager.play_one_shot(
					graft_face_sound
				)

			# Invalid fusion means swap the equipped slots.
			else:
				selected_edit_die.faces[
					source_slot
				] = target_face

				selected_edit_die.faces[
					target_slot_index
				] = source_face

		_:
			return

	selected_inventory_face_indices.clear()
	refresh_edit_dice_panel()
	save_run()
	
func try_fuse_inventory_faces_by_index(
	index_a: int,
	index_b: int
):
	if dice_panel_read_only:
		return

	if index_a < 0 or index_a >= face_inventory.size():
		return

	if index_b < 0 or index_b >= face_inventory.size():
		return

	if index_a == index_b:
		show_edit_message(
			"A face cannot be fused with itself."
		)
		return

	var face_a: DiceFace = face_inventory[index_a]
	var face_b: DiceFace = face_inventory[index_b]

	if face_a == null or face_b == null:
		return

	if !can_fuse_faces(face_a, face_b):
		show_edit_message(
			"Those faces cannot be fused."
		)
		AudioManager.play_ui(ui_fail_sound)
		return

	var fused_face: DiceFace = create_fused_face(
		face_a,
		face_b
	)

	if fused_face == null:
		return

	capture_fusion_undo_state()

	var high_index: int = max(
		index_a,
		index_b
	)

	var low_index: int = min(
		index_a,
		index_b
	)

	face_inventory.remove_at(high_index)
	face_inventory.remove_at(low_index)
	face_inventory.append(fused_face)

	selected_inventory_face_indices.clear()

	AudioManager.play_one_shot(
		graft_face_sound
	)

	refresh_edit_dice_panel()
	save_run()
	
func capture_fusion_undo_state():
	fusion_undo_inventory.clear()

	for face in face_inventory:
		fusion_undo_inventory.append(face)

	fusion_undo_die_faces.clear()

	for die_data in owned_dice:
		if die_data == null:
			continue

		var saved_faces: Array[DiceFace] = []

		for face in die_data.faces:
			saved_faces.append(face)

		fusion_undo_die_faces[die_data] = saved_faces

	fusion_undo_available = true
	update_fusion_undo_button()


func undo_last_fusion():
	if !fusion_undo_available:
		return

	face_inventory.clear()

	for face in fusion_undo_inventory:
		face_inventory.append(face)

	for die_data in fusion_undo_die_faces.keys():
		if die_data == null:
			continue

		var saved_faces: Array = fusion_undo_die_faces[die_data]

		die_data.faces.clear()

		for face in saved_faces:
			die_data.faces.append(face)

	fusion_undo_inventory.clear()
	fusion_undo_die_faces.clear()
	fusion_undo_available = false

	selected_die_face_index = -1
	selected_die_face_index_2 = -1
	selected_inventory_face_indices.clear()

	update_fusion_undo_button()
	refresh_edit_dice_panel()
	save_run()

	show_edit_message("Last fusion undone.")


func update_fusion_undo_button():
	if undo_fusion_button == null:
		return

	undo_fusion_button.disabled = (
		!fusion_undo_available
		or dice_panel_read_only
	)

	if fusion_undo_available:
		undo_fusion_button.tooltip_text = (
			"Restore the inventory and dice to their state "
			+ "before the most recent fusion."
		)
	else:
		undo_fusion_button.tooltip_text = (
			"No fusion is available to undo."
		)
	
func clear_fusion_undo_state():
	fusion_undo_inventory.clear()
	fusion_undo_die_faces.clear()
	fusion_undo_available = false
	update_fusion_undo_button()
	
func try_fuse_inventory_faces(
	face_a: DiceFace,
	face_b: DiceFace
):
	if dice_panel_read_only:
		return

	if face_a == null or face_b == null:
		show_edit_message("One of those faces is invalid.")
		return

	var index_a: int = face_inventory.find(face_a)
	var index_b: int = face_inventory.find(face_b)

	# Two inventory slots can occasionally reference the same resource.
	# In that case, locate the second occurrence manually.
	if index_a != -1 and index_b == index_a:
		index_b = -1

		for i in range(index_a + 1, face_inventory.size()):
			if face_inventory[i] == face_b:
				index_b = i
				break

	if index_a == -1 or index_b == -1:
		show_edit_message(
			"Could not find two separate inventory faces."
		)
		return

	if index_a == index_b:
		show_edit_message(
			"A face cannot be fused with itself."
		)
		return

	var actual_face_a: DiceFace = face_inventory[index_a]
	var actual_face_b: DiceFace = face_inventory[index_b]

	if !can_fuse_faces(actual_face_a, actual_face_b):
		show_edit_message("Those faces cannot be fused.")
		AudioManager.play_ui(ui_fail_sound)
		return

	var fused_face: DiceFace = create_fused_face(
		actual_face_a,
		actual_face_b
	)

	if fused_face == null:
		return

	var high_index: int = max(index_a, index_b)
	var low_index: int = min(index_a, index_b)

	capture_fusion_undo_state()

	face_inventory.remove_at(high_index)
	face_inventory.remove_at(low_index)
	face_inventory.append(fused_face)

	AudioManager.play_one_shot(
		graft_face_sound
	)

	selected_inventory_face_indices.clear()

	refresh_edit_dice_panel()
	save_run()
	
func would_remove_last_miss(die_data: DiceData, slot_index: int) -> bool:
	if die_data == null:
		return false

	if slot_index < 0 or slot_index >= die_data.faces.size():
		return false

	var face := die_data.faces[slot_index]

	if face == null or face.result_type != "miss":
		return false

	var miss_count := 0

	for die_face in die_data.faces:
		if die_face != null and die_face.result_type == "miss":
			miss_count += 1

	return miss_count <= 1
	
func handle_inventory_face_drop(
	data: Dictionary,
	target_inventory_face: DiceFace
):
	clear_drag_fusion_preview()

	if dice_panel_read_only:
		return

	if !data.has("source_type") or !data.has("face"):
		return

	var source_type: String = String(data["source_type"])
	var dragged_face: DiceFace = data["face"]

	if dragged_face == null or target_inventory_face == null:
		return

	# Inventory -> Inventory fusion does not require a selected die.
	if source_type == "inventory":
		try_fuse_inventory_faces(
			dragged_face,
			target_inventory_face
		)
		return

		var dragged_index: int = face_inventory.find(dragged_face)
		var target_index: int = face_inventory.find(target_inventory_face)

		if dragged_index == -1 or target_index == -1:
			return

		if dragged_index == target_index:
			return

		if !can_fuse_faces(dragged_face, target_inventory_face):
			show_edit_message("Those faces cannot be fused.")
			AudioManager.play_ui(ui_fail_sound)
			return

		var fused_face: DiceFace = create_fused_face(
			dragged_face,
			target_inventory_face
		)

		if fused_face == null:
			return

		# Remove the higher index first so the lower index remains valid.
		var high_index: int = max(dragged_index, target_index)
		var low_index: int = min(dragged_index, target_index)

		face_inventory.remove_at(high_index)
		face_inventory.remove_at(low_index)
		face_inventory.append(fused_face)

		AudioManager.play_one_shot(graft_face_sound)
		refresh_edit_dice_panel()
		save_run()
		return

	# Everything below this point involves an equipped face.
	if source_type != "equipped":
		return

	if selected_edit_die == null:
		show_edit_message("Select a die first.")
		return

	if !selected_edit_die.editable:
		show_edit_message("Cursed dice cannot be edited.")
		return

	if !data.has("slot"):
		return

	var source_slot: int = int(data["slot"])

	if source_slot < 0 or source_slot >= selected_edit_die.faces.size():
		return

	var equipped_face: DiceFace = selected_edit_die.faces[source_slot]

	if equipped_face == null:
		equipped_face = create_basic_miss_face()

	var target_inventory_index: int = face_inventory.find(
		target_inventory_face
	)

	if target_inventory_index == -1:
		return

	# Fuse equipped face with inventory face.
	if can_fuse_faces(equipped_face, target_inventory_face):
		var fused_face: DiceFace = create_fused_face(
			equipped_face,
			target_inventory_face
		)

		if fused_face == null:
			return

		if !face_fits_die(selected_edit_die, fused_face):
			var max_value: int = get_max_face_value_for_die(
				selected_edit_die,
				fused_face
			)

			show_edit_message(
				get_face_display_name(fused_face)
				+ " is too strong for a D"
				+ str(selected_edit_die.sides)
				+ ".\nD"
				+ str(selected_edit_die.sides)
				+ " non-Crit faces can be value "
				+ str(max_value)
				+ " or lower."
			)
			return

		if is_last_miss_slot(selected_edit_die, source_slot):
			show_edit_message("Every die must keep at least 1 Miss.")
			return

		capture_fusion_undo_state()

		selected_edit_die.faces[source_slot] = fused_face
		face_inventory.remove_at(target_inventory_index)

		AudioManager.play_one_shot(graft_face_sound)

	# Invalid fusion means swap the two faces.
	else:
		# Prevent removing the final Miss from a normal die.
		if is_last_miss_slot(selected_edit_die, source_slot):
			if target_inventory_face.result_type != "miss":
				show_edit_message("Every die must keep at least 1 Miss.")
				return

		if !face_fits_die(selected_edit_die, target_inventory_face):
			var max_value: int = get_max_face_value_for_die(
				selected_edit_die,
				target_inventory_face
			)

			show_edit_message(
				get_face_display_name(target_inventory_face)
				+ " is too strong for a D"
				+ str(selected_edit_die.sides)
				+ ".\nD"
				+ str(selected_edit_die.sides)
				+ " non-Crit faces can be value "
				+ str(max_value)
				+ " or lower."
			)
			return

		selected_edit_die.faces[source_slot] = target_inventory_face
		face_inventory[target_inventory_index] = equipped_face

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
	
func handle_sell_face_drop(data: Dictionary):
	clear_drag_fusion_preview()

	if edit_dice_return_context != "town":
		return

	if !data.has("face"):
		return

	var face: DiceFace = data["face"]
	var source_type: String = data.get("source_type", "")

	if face == null:
		return

	if source_type != "inventory":
		show_edit_message("Only inventory faces can be sold.")
		return

	if !face_inventory.has(face):
		return

	face_inventory.erase(face)

	var value := get_face_sell_value(face)
	gold += value

	AudioManager.play_one_shot(coin_purchase_sound)

	update_gold_label()
	refresh_edit_dice_panel()
	save_run()
	
var edit_warning_tween: Tween = null

func show_edit_message(text: String):
	if edit_warning_label == null:
		push_error("edit_warning_label is null.")
		return

	if edit_warning_tween != null and edit_warning_tween.is_valid():
		edit_warning_tween.kill()

	edit_warning_label.text = text
	edit_warning_label.visible = true
	edit_warning_label.modulate = Color.RED
	edit_warning_label.z_index = 1000

	AudioManager.play_one_shot(ui_fail_sound)

	edit_warning_tween = create_tween()
	edit_warning_tween.tween_interval(1.0)
	edit_warning_tween.tween_property(edit_warning_label, "modulate:a", 0.0, 1.0)
	edit_warning_tween.tween_callback(func():
		edit_warning_label.visible = false
		edit_warning_label.text = ""
		edit_warning_label.modulate = Color.RED
	)
	
func is_last_miss_slot(die_data: DiceData, slot_index: int) -> bool:
	if die_data == null:
		return false

	if slot_index < 0 or slot_index >= die_data.faces.size():
		return false

	var slot_face: DiceFace = die_data.faces[slot_index]

	if slot_face == null or slot_face.result_type != "miss":
		return false

	var miss_count := 0

	for face in die_data.faces:
		if face != null and face.result_type == "miss":
			miss_count += 1

	return miss_count <= 1

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
		prepare_selected_bounty_label.text = (
			"Bounty: "
			+ current_bounty.bounty_name
		)
	else:
		prepare_selected_bounty_label.text = "Expedition Items"

	prepare_hp_label.visible = true
	update_prepare_hp_label()
	rebuild_prepare_consumables()

func apply_damage_bonus_to_dice_visuals():
	var berserker_bonus: int = get_player_berserker_bonus()

	for die in dice_nodes:
		if !is_instance_valid(die):
			continue

		var total_visual_bonus: int = 0

		if (
			die.current_face != null
			and die.current_face.result_type == "hit"
		):
			total_visual_bonus += active_combat_bonus_damage
			total_visual_bonus += berserker_bonus

		die.temporary_value_bonus = total_visual_bonus
		die.update_visual()


func get_enemy_trait_text(enemy: Dictionary) -> String:
	var data: EnemyData = enemy["data"]
	var parts := []

	for enemy_trait in data.traits:
		parts.append(enemy_trait.trait_name + " " + str(enemy_trait.value))

	return ", ".join(parts)
	
func apply_enemy_end_round_traits():
	for enemy in active_enemies:
		var regen_value := get_enemy_trait_value(
			enemy,
			"regenerating"
		)

		if regen_value <= 0:
			continue

		var hp_before_regen: int = enemy["hp"]

		enemy["hp"] += regen_value

		if enemy["hp"] > enemy["max_hp"]:
			enemy["hp"] = enemy["max_hp"]

		var actual_healing: int = (
			enemy["hp"] - hp_before_regen
		)

		if actual_healing <= 0:
			continue

		var enemy_index := active_enemies.find(enemy)

		if (
			enemy_index != -1
			and enemy_index < enemy_3d_nodes.size()
			and is_instance_valid(enemy_3d_nodes[enemy_index])
		):
			show_popup_text(
				enemy_3d_nodes[enemy_index],
				"+" + str(actual_healing),
				1.8,
				Color.GREEN
			)

			spawn_enemy_heal_icon_particles(
				enemy_3d_nodes[enemy_index],
				5
			)

			add_combat_log_entry(
				enemy["data"].enemy_name
					+ "'s Regenerating trait restored "
					+ str(actual_healing)
					+ " HP."
			)

func show_status_tooltip(text: String):
	status_tooltip_label.text = text
	status_tooltip_panel.visible = true
	status_tooltip_panel.global_position = get_viewport().get_mouse_position() + Vector2(16, 16)
	status_tooltip_panel.z_index = 500
	status_tooltip_panel.top_level = true
	status_tooltip_label.custom_minimum_size = Vector2(240, 0)
	status_tooltip_panel.custom_minimum_size = Vector2(260, 0)

func hide_status_tooltip():
	status_tooltip_panel.visible = false

func open_food_crafting():
	food_crafting_return_context = "camp"
	expedition_camp_panel.visible = false
	food_craft_panel.visible = true
	selected_food_craft_names.clear()
	camp_hp_label.visible = true
	update_camp_hp_label()
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
	update_camp_hp_label()
	update_begin_expedition_button_visibility()
	
func rebuild_food_crafting_grid():
	clear_container(food_craft_items_container)

	var item_counts: Dictionary = {}
	var item_lookup: Dictionary = {}

	for item in consumable_inventory:
		if item == null:
			continue

		if !item_counts.has(item.item_name):
			item_counts[item.item_name] = 0
			item_lookup[item.item_name] = item

		item_counts[item.item_name] += 1

	var sorted_names: Array[String] = (
		get_sorted_consumable_names(item_lookup)
	)

	for item_name in sorted_names:
		var item: ConsumableItem = item_lookup[item_name]
		var count: int = item_counts[item_name]

		var button = item_button_scene.instantiate()
		food_craft_items_container.add_child(button)

		button.setup(
			item.icon,
			"x" + str(count),
			""
		)
		button.enable_food_crafting_drag(
			item_name
		)

		button.food_dropped.connect(
			handle_food_crafting_drop
		)
		button.tooltip_text = (
			item.item_name
			+ "\n"
			+ item.description
		)

		if selected_food_craft_names.has(item_name):
			button.modulate = Color.YELLOW
		else:
			button.modulate = Color.WHITE

		button.pressed.connect(
			select_food_name_for_crafting.bind(
				item_name
			)
		)

func select_food_for_crafting(index: int):
	if selected_food_craft_names.has(index):
		selected_food_craft_names.erase(index)
	else:
		if selected_food_craft_names.size() >= 2:
			selected_food_craft_names.clear()

		selected_food_craft_names.append(index)

	rebuild_food_crafting_grid()
	update_craft_result_label()

func get_sorted_consumable_names(
	item_lookup: Dictionary
) -> Array[String]:
	var names: Array[String] = []

	for key in item_lookup.keys():
		names.append(String(key))

	names.sort_custom(
		func(name_a: String, name_b: String) -> bool:
			var item_a: ConsumableItem = item_lookup[name_a]
			var item_b: ConsumableItem = item_lookup[name_b]

			if item_a.food_tier != item_b.food_tier:
				return item_a.food_tier < item_b.food_tier

			return (
				item_a.item_name.naturalnocasecmp_to(
					item_b.item_name
				) < 0
			)
	)

	return names
	
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
	AudioManager.play_one_shot(cooking_sound, randf_range(0.96, 1.04), 1.0)
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

func would_exceed_dodge_limit(die_data: DiceData, incoming_face: DiceFace, replacing_slot_index: int = -1) -> bool:
	if die_data == null or incoming_face == null:
		return false

	if incoming_face.result_type != "dodge":
		return false

	var dodge_count := 0

	for i in die_data.faces.size():
		var face := die_data.faces[i]

		if i == replacing_slot_index:
			continue

		if face != null and face.result_type == "dodge":
			dodge_count += 1

	return dodge_count >= 1
	
func open_food_crafting_from_town():
	food_crafting_return_context = "town"
	food_craft_panel.visible = true
	selected_food_craft_names.clear()
	update_begin_expedition_button_visibility()
	rebuild_food_crafting_grid()
	update_craft_result_label()

func bind_world(world: Node3D):
	combat_camera = world.find_child(
		"Camera3D",
		true,
		false
	)

	enemy_positions = world.find_child(
		"EnemyPositions",
		true,
		false
	)

	player_position = world.find_child(
		"PlayerPosition",
		true,
		false
	)

	print("World: ", world.name)
	print("EnemyPositions: ", enemy_positions)

	if combat_camera == null:
		push_error(
			"Combat world is missing Camera3D."
		)
		return

	if enemy_positions == null:
		push_error(
			"Combat world is missing EnemyPositions."
		)
		return

	if player_position == null:
		push_error(
			"Combat world is missing PlayerPosition."
		)
		return

	combat_camera.current = true
	camera_original_position = combat_camera.position

	# Every loaded combat world has its own camera home.
	# Never reuse camera information from a previous encounter or run.
	combat_camera_home_saved = false

	combat_camera_home_transform = (
		combat_camera.global_transform
	)

	combat_camera_home_size = combat_camera.size
	combat_camera_home_saved = true

	# Clear cinematic state inherited from the previous world.
	shatter_camera_running = false
	beastmaster_transition_running = false

	print(
		"Captured camera home for ",
		world.name,
		": ",
		combat_camera_home_transform.origin,
		" size=",
		combat_camera_home_size
	)

	spawn_player_3d_node()

func set_combat_ui_enabled(enabled: bool):
	top_ui_background.visible = enabled
	bottom_ui_background.visible = enabled
	$DiceArea.visible = enabled
	$LeftMarginContainer.visible = enabled
	$RightMarginContainer.visible = enabled

	combat_number_label.visible = enabled
	end_round_button.visible = enabled
	end_round_button.disabled = !enabled
	mulligem_button.visible = enabled

	# This function only controls combat UI.
	# It should not change whether the player is in town.
	update_begin_expedition_button_visibility()

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
	if amount <= 0:
		return

	mulligems += amount
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
	var regen_value: int = player_statuses.get(
		"regenerating",
		0
	)

	if regen_value <= 0:
		return

	var hp_before: int = player_hp

	player_hp += regen_value

	if player_hp > combat_max_player_hp:
		player_hp = combat_max_player_hp

	var actual_healing: int = player_hp - hp_before

	if actual_healing > 0:
		show_popup_text(
			player_3d_node,
			"+" + str(actual_healing),
			1.2,
			Color.GREEN
		)

		add_combat_log_entry(
			"Regeneration restored "
				+ str(actual_healing)
				+ " HP."
		)
	else:
		add_combat_log_entry(
			"Regeneration triggered, but the player was already at full HP."
		)

	update_player_hp_label()
	update_player_status_icons()

func has_relic(name: String) -> bool:
	for relic in owned_relics:
		if relic == null:
			continue

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
	if index < 0 or index >= AVAILABLE_RESOLUTIONS.size():
		return

	var resolution: Vector2i = AVAILABLE_RESOLUTIONS[index]

	if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_size(resolution)

	save_settings()
	
func save_settings():
	if !ensure_save_directory():
		return

	var config := ConfigFile.new()

	config.set_value(
		"audio",
		"master",
		master_volume_slider.value
	)

	config.set_value(
		"audio",
		"music",
		music_volume_slider.value
	)

	config.set_value(
		"audio",
		"sfx",
		sfx_volume_slider.value
	)

	config.set_value(
		"display",
		"fullscreen",
		fullscreen_check_box.button_pressed
	)

	config.set_value(
		"display",
		"resolution_index",
		resolution_option.selected
	)

	var err := config.save(SETTINGS_SAVE_PATH)

	if err == OK:
		print(
			"Settings saved to: ",
			ProjectSettings.globalize_path(
				SETTINGS_SAVE_PATH
			)
		)
	else:
		push_error(
			"Failed to save settings. Error: "
			+ str(err)
		)

func ensure_save_directory() -> bool:
	var absolute_path: String = (
		ProjectSettings.globalize_path(
			SAVE_DIRECTORY
		)
	)

	var err := DirAccess.make_dir_recursive_absolute(
		absolute_path
	)

	if err != OK and err != ERR_ALREADY_EXISTS:
		push_error(
			"Failed to create save directory: "
			+ absolute_path
			+ " Error: "
			+ str(err)
		)

		return false

	return true

func save_run():
	if !ensure_save_directory():
		return

	var config := ConfigFile.new()
	
	config.set_value("run", "encounters_completed", run_encounters_completed)
	config.set_value("run", "gold", gold)
	config.set_value("run", "mulligems", mulligems)
	config.set_value("run", "volatile_cores", volatile_cores)
	config.set_value("run", "die_fragments", die_fragments)
	var should_save_pending_encounter := expedition_active \
		and !expedition_camp_panel.visible \
		and current_encounter != null
	config.set_value(
		"expedition",
		"current_encounter",
		get_resource_path(current_encounter) if should_save_pending_encounter else ""
	)
	config.set_value("expedition", "is_in_town", is_in_town)
	
	if is_in_town or expedition_camp_panel.visible:
		player_hp_at_combat_start = player_hp
	config.set_value("player", "hp", player_hp)
	config.set_value("player", "max_hp", max_player_hp)
	config.set_value("player", "hp_at_combat_start", player_hp_at_combat_start)
	config.set_value("run", "reserve_slots", reserve_slots)
	config.set_value("expedition", "required_encounters", expedition_required_encounters)
	config.set_value("expedition", "is_boss_fight", expedition_is_boss_fight)
	config.set_value("run", "witch_seen", witch_seen_this_run)
	config.set_value("run", "well_seen", well_seen_this_run)
	var saved_plan: Array = []

	for node in expedition_encounter_plan:
		var node_type: String = node.get("type", PLAN_COMBAT)

		if node_type == PLAN_COMBAT:
			saved_plan.append({
				"type": PLAN_COMBAT,
				"encounter_path": get_resource_path(
					node["encounter"]
				)
			})

		elif node_type == PLAN_WITCH:
			saved_plan.append({
				"type": PLAN_WITCH,
				"encounter_path": ""
			})

		elif node_type == PLAN_WELL:
			saved_plan.append({
				"type": PLAN_WELL,
				"encounter_path": ""
			})

	config.set_value("expedition", "encounter_plan", saved_plan)

	config.set_value("expedition", "expedition_active", expedition_active)
	config.set_value("expedition", "progress", expedition_progress)
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

	var owned_relic_names: Array[String] = []

	for relic in owned_relics:
		if relic == null:
			continue

		if relic.relic_name.is_empty():
			continue

		owned_relic_names.append(relic.relic_name)

	config.set_value(
		"relics",
		"owned_relics",
		owned_relic_names
	)
	var active_food_save_data: Array = []

	for item in active_food_items:
		active_food_save_data.append(serialize_consumable(item))

	config.set_value("inventory", "active_food_items", active_food_save_data)
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
		"faces": faces,
		"editable": die.editable,
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
	die.editable = data.get("editable", true)
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
	expedition_active = config.get_value("expedition", "expedition_active", false)
	is_in_town = config.get_value("expedition", "is_in_town", true)
	max_player_hp = int(
		config.get_value(
			"player",
			"max_hp",
			max_player_hp
		)
	)

	player_hp = int(
		config.get_value(
			"player",
			"hp",
			max_player_hp
		)
	)

	player_hp_at_combat_start = int(
		config.get_value(
			"player",
			"hp_at_combat_start",
			player_hp
		)
	)

	combat_max_player_hp = max_player_hp

	player_hp = clamp(
		player_hp,
		0,
		combat_max_player_hp
	)

	player_hp_at_combat_start = clamp(
		player_hp_at_combat_start,
		0,
		combat_max_player_hp
	)
	run_encounters_completed = config.get_value("run", "encounters_completed", run_encounters_completed)
	expedition_progress = config.get_value("expedition", "progress", expedition_progress)
	expedition_required_encounters = config.get_value("expedition", "required_encounters", expedition_required_encounters)
	expedition_is_boss_fight = config.get_value("expedition", "is_boss_fight", expedition_is_boss_fight)
	reserve_slots = config.get_value("run", "reserve_slots", reserve_slots)
	witch_seen_this_run = config.get_value("run", "witch_seen", false)
	well_seen_this_run = config.get_value("run", "well_seen", false)
	update_reserve_slots_display()
	var encounter_path: String = config.get_value("expedition", "current_encounter", "")
	if encounter_path != "":
		var loaded_encounter = load(encounter_path)
		if loaded_encounter is EncounterData:
			current_encounter = loaded_encounter

	is_in_town = config.get_value("expedition", "is_in_town", true)

	var saved_bounty_name: String = config.get_value("expedition", "current_bounty", "")

	current_bounty = null
	expedition_active = config.get_value("expedition", "expedition_active", false)
	expedition_progress = config.get_value("expedition", "progress", expedition_progress)

	expedition_encounter_plan.clear()

	var saved_plan: Array = config.get_value("expedition", "encounter_plan", [])

	for saved_node in saved_plan:
		if !(saved_node is Dictionary):
			continue

		var node_type: String = saved_node.get("type", PLAN_COMBAT)

		if node_type == PLAN_COMBAT:
			var path: String = saved_node.get("encounter_path", "")
			var encounter = load(path)

			if encounter is EncounterData:
				expedition_encounter_plan.append({
					"type": PLAN_COMBAT,
					"encounter": encounter
				})

		elif node_type == PLAN_WITCH:
			expedition_encounter_plan.append({
				"type": PLAN_WITCH,
				"encounter": null
			})

		elif node_type == PLAN_WELL:
			expedition_encounter_plan.append({
				"type": PLAN_WELL,
				"encounter": null
			})

	var node := get_current_plan_node()

	if !node.is_empty() and node.get("type") == PLAN_COMBAT:
		current_encounter = node["encounter"]
	else:
		current_encounter = null
	if saved_bounty_name != "":
		for bounty in bounty_pool:
			if bounty.bounty_name == saved_bounty_name:
				current_bounty = bounty
				break
	if expedition_active and current_encounter != null:
		loaded_pending_encounter = true
		is_in_town = false
		player_hp = player_hp_at_combat_start
	completed_bounties.clear()
	var completed_bounty_names: Array = config.get_value("progress", "completed_bounties", [])

	for bounty in bounty_pool:
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
			make_inventory_faces_unique()

	consumable_inventory.clear()
	for item_data in config.get_value("inventory", "consumables", []):
		if item_data is Dictionary:
			consumable_inventory.append(deserialize_consumable(item_data))
	merchant_unlocked_faces.clear()
	active_food_items.clear()

	for item_data in config.get_value("inventory", "active_food_items", []):
		if item_data is Dictionary:
			active_food_items.append(deserialize_consumable(item_data))
	recalculate_active_food_bonuses()
	update_active_food_icons()
	for face_data in config.get_value("merchant", "unlocked_faces", []):
		if face_data is Dictionary:
			merchant_unlocked_faces.append(deserialize_face(face_data))

	owned_relics.clear()

	var saved_relic_names: Array = config.get_value(
		"relics",
		"owned_relics",
		[]
	)

	for relic_name_value in saved_relic_names:
		var relic_name: String = String(relic_name_value)
		var relic: RelicData = find_relic_by_name(relic_name)

		if relic == null:
			push_warning("Could not load relic: " + relic_name)
			continue

		if !has_relic_name(relic.relic_name):
			owned_relics.append(relic)

	
			# refresh_relic_panel()
	unlocked_food_tier = config.get_value("unlock", "unlocked_food_tier", unlocked_food_tier)
	has_meditation_charm = has_relic_name("Meditation Beads")
	selected_edit_die = null
	update_camp_hp_label()
	update_prepare_hp_label()
	update_active_food_icons()
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
		fullscreen_check_box.button_pressed = false
		resolution_option.selected = 0
		_on_master_volume_changed(master_volume_slider.value)
		_on_music_volume_changed(music_volume_slider.value)
		_on_sfx_volume_changed(sfx_volume_slider.value)
		return

	var saved_fullscreen: bool = config.get_value("display", "fullscreen", false)
	var resolution_index: int = config.get_value("display", "resolution_index", 0)

	resolution_index = clamp(resolution_index, 0, AVAILABLE_RESOLUTIONS.size() - 1)
	var saved_resolution: Vector2i = AVAILABLE_RESOLUTIONS[resolution_index]

	DisplayServer.window_set_size(saved_resolution)

	if saved_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

	fullscreen_check_box.button_pressed = saved_fullscreen
	resolution_option.selected = resolution_index

	master_volume_slider.value = config.get_value("audio", "master", 1.0)
	music_volume_slider.value = config.get_value("audio", "music", 1.0)
	sfx_volume_slider.value = config.get_value("audio", "sfx", 1.0)

	_on_master_volume_changed(master_volume_slider.value)
	_on_music_volume_changed(music_volume_slider.value)
	_on_sfx_volume_changed(sfx_volume_slider.value)
	
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

	var total_encounters: int = (
		expedition_required_encounters + 1
	)

	var current_encounter_number: int = (
		expedition_progress + 1
	)

	if expedition_is_boss_fight:
		current_encounter_number = total_encounters

	current_encounter_number = clamp(
		current_encounter_number,
		1,
		total_encounters
	)

	camp_progress_value_label.text = (
		"Encounter "
		+ str(current_encounter_number)
		+ "/"
		+ str(total_encounters)
	)

	if expedition_is_boss_fight:
		camp_progress_value_label.text += " — Boss"
		
func find_relic_by_name(relic_name: String) -> RelicData:
	if relic_name.is_empty():
		return null

	if (
		witch_charm_relic != null
		and witch_charm_relic.relic_name == relic_name
	):
		return witch_charm_relic

	for relic in merchant_relic_pool:
		if relic == null:
			continue

		if relic.relic_name == relic_name:
			return relic

	for relic in combat_relic_drop_pool:
		if relic == null:
			continue

		if relic.relic_name == relic_name:
			return relic

	# Boss and bounty completion relics.
	for bounty in bounty_pool:
		if bounty == null:
			continue

		for relic in bounty.unlocked_relics:
			if relic == null:
				continue

			if relic.relic_name == relic_name:
				return relic

	# The final boss may be stored separately from bounty_pool.
	if final_boss_bounty != null:
		for relic in final_boss_bounty.unlocked_relics:
			if relic == null:
				continue

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
	combat_number_label.visible = false
	player_hp_label.visible = false
	player_block_label.visible = false

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

func build_expedition_plan():
	expedition_encounter_plan.clear()

	if current_bounty == null:
		return

	if current_bounty.expedition_encounter_pool.is_empty():
		push_error(
			"Current bounty has no normal encounters."
		)
		return

	if expedition_required_encounters <= 0:
		push_error(
			"Expedition required encounter count is invalid."
		)
		return

	var available_events: Array[String] = []

	if !well_seen_this_run:
		available_events.append(PLAN_WELL)

	if !witch_seen_this_run:
		available_events.append(PLAN_WITCH)

	var previous_node_was_event: bool = false

	# Build every pre-boss node.
	for node_index in expedition_required_encounters:
		# The first node must always be combat because expedition
		# startup expects an EncounterData resource.
		if node_index == 0:
			append_random_combat_to_expedition_plan()
			previous_node_was_event = false
			continue

		# An event can only be placed after a combat.
		var should_use_event: bool = (
			!previous_node_was_event
			and !available_events.is_empty()
			and randf() < 0.5
		)

		if should_use_event:
			var event_type: String = (
				available_events.pick_random()
			)

			available_events.erase(event_type)

			expedition_encounter_plan.append({
				"type": event_type,
				"encounter": null
			})

			previous_node_was_event = true
		else:
			append_random_combat_to_expedition_plan()
			previous_node_was_event = false

	# The boss always follows all required pre-boss nodes.
	expedition_encounter_plan.append({
		"type": PLAN_COMBAT,
		"encounter": current_bounty.boss_encounter
	})

	print_expedition_plan()

func append_random_combat_to_expedition_plan():
	expedition_encounter_plan.append({
		"type": PLAN_COMBAT,
		"encounter":
			current_bounty.expedition_encounter_pool.pick_random()
	})
	
func print_expedition_plan():
	print("===== EXPEDITION PLAN =====")

	for i in expedition_encounter_plan.size():
		var node: Dictionary = expedition_encounter_plan[i]
		var node_type: String = node.get(
			"type",
			PLAN_COMBAT
		)

		if node_type == PLAN_COMBAT:
			var encounter: EncounterData = node.get(
				"encounter",
				null
			)

			var encounter_name: String = (
				encounter.encounter_name
				if encounter != null
				else "Missing Combat"
			)

			print(
				i + 1,
				": COMBAT — ",
				encounter_name
			)
		else:
			print(
				i + 1,
				": EVENT — ",
				node_type
			)

	print("===========================")
	
func get_current_plan_node() -> Dictionary:
	if expedition_encounter_plan.is_empty():
		return {}

	if expedition_progress < 0:
		expedition_progress = 0

	if expedition_progress >= expedition_encounter_plan.size():
		return expedition_encounter_plan.back()

	return expedition_encounter_plan[expedition_progress]
	
func get_scaled_bounty_extra_encounters() -> int:
	return completed_bounties.size()
	
func create_cursed_d6() -> DiceData:
	var die := DiceData.new()
	die.die_name = "Cursed D6"
	die.sides = 6
	die.editable = false

	for i in 3:
		die.faces.append(miss_face_template.duplicate(true))

	for i in 3:
		die.faces.append(pain_face_template.duplicate(true))

	return die

func consume_relic(relic_name: String):
	for relic in owned_relics:
		if relic.relic_name == relic_name:
			owned_relics.erase(relic)
			update_active_food_icons()
			save_run()
			return

func accept_witch_offer() -> RelicData:
	print("Accepting witch offer")

	var awarded_relic: RelicData = null

	if witch_charm_relic == null:
		push_warning("Witch offer failed: witch_charm_relic is null.")
	else:
		print("Witch relic: ", witch_charm_relic.relic_name)

		if !has_relic_name(witch_charm_relic.relic_name):
			owned_relics.append(witch_charm_relic)
			awarded_relic = witch_charm_relic

			print(
				"Added Witch relic. Owned relic count: ",
				owned_relics.size()
			)

	owned_dice.append(create_cursed_d6())

	update_active_food_icons()
	save_run()

	return awarded_relic


func ignore_witch_offer():
	save_run()
	
func hide_all_major_panels():
	town_panel.visible = false
	merchant_panel.visible = false
	food_craft_panel.visible = false
	edit_dice_panel.visible = false
	bounty_board_panel.visible = false
	prepare_expedition_panel.visible = false
	expedition_camp_panel.visible = false
	shop_panel.visible = false
	loot_panel.visible = false
	encounter_panel.visible = false
	death_overlay.visible = false
	endless_choice_overlay.visible = false
	begin_expedition_button.visible = false
	end_round_button.visible = false
	mulligem_button.visible = false
	dice_bag_panel.visible = false

func cinematic_shatter_focus(
	enemy_node: Node3D
) -> bool:
	while shatter_camera_running:
		await get_tree().process_frame

	var camera: Camera3D = combat_camera

	if camera == null:
		camera = get_viewport().get_camera_3d()

	if (
		camera == null
		or enemy_node == null
		or !is_instance_valid(enemy_node)
	):
		return false

	shatter_camera_running = true

	shatter_camera_original_transform = (
		camera.global_transform
	)

	shatter_camera_original_size = camera.size
	camera.current = true

	var direction_to_enemy: Vector3 = (
		enemy_node.global_position
		- camera.global_position
	).normalized()

	var target_transform: Transform3D = (
		camera.global_transform
	)

	target_transform.origin += (
		direction_to_enemy * 18.0
	)

	var target_size: float = max(
		shatter_camera_original_size * 0.60,
		0.1
	)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(
		camera,
		"global_transform",
		target_transform,
		0.22
	)

	tween.tween_property(
		camera,
		"size",
		target_size,
		0.22
	)

	await tween.finished

	return true
func restore_shatter_camera():
	var camera: Camera3D = combat_camera

	if camera == null:
		camera = get_viewport().get_camera_3d()

	if camera == null:
		shatter_camera_running = false
		return

	camera.current = true

	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(
		camera,
		"global_transform",
		shatter_camera_original_transform,
		0.22
	)

	tween.tween_property(
		camera,
		"size",
		shatter_camera_original_size,
		0.22
	)

	await tween.finished

	# Force exact restoration so repeated camera effects cannot drift.
	camera.global_transform = (
		shatter_camera_original_transform
	)

	camera.size = shatter_camera_original_size
	camera.current = true

	shatter_camera_running = false

	# Ensure anything waiting to start a new cinematic gets
	# one fully restored frame.
	await get_tree().process_frame
	
func shatter_camera_shake(camera: Camera3D, duration: float = 0.28, strength: float = 0.18):
	if camera == null:
		return

	var original_position := camera.global_position
	var time := 0.0

	while time < duration:
		var falloff := 1.0 - (time / duration)
		var offset := Vector3(
			randf_range(-strength, strength) * falloff,
			randf_range(-strength, strength) * falloff,
			0.0
		)

		camera.global_position = original_position + offset

		await get_tree().process_frame
		time += get_process_delta_time()

	camera.global_position = original_position

func recalculate_active_food_bonuses():
	next_combat_bonus_damage = 0
	next_combat_bonus_block = 0
	next_combat_heal = 0
	next_combat_bonus_max_hp = 0

	for item in active_food_items:
		next_combat_bonus_damage += item.next_combat_damage
		next_combat_bonus_block += item.next_combat_block
		next_combat_heal += item.heal_amount
		next_combat_bonus_max_hp += item.next_combat_max_hp

func beastmaster_phase_transition(enemy_index: int):
	if beastmaster_transition_running:
		return

	beastmaster_transition_running = true
	begin_expedition_button.visible = false

	is_resolving_turn = true
	end_round_button.disabled = true
	mulligem_button.disabled = true
	set_combat_ui_enabled(false)

	if enemy_index < 0 or enemy_index >= active_enemies.size():
		push_error(
			"Invalid Beast Master enemy index: "
			+ str(enemy_index)
		)

		finish_failed_beastmaster_transition()
		return

	if enemy_index >= enemy_3d_nodes.size():
		push_error(
			"Beast Master has no matching Enemy3D node at index "
			+ str(enemy_index)
		)

		finish_failed_beastmaster_transition()
		return

	var beastmaster_enemy: Dictionary = active_enemies[enemy_index]
	var beastmaster_node: Enemy3D = enemy_3d_nodes[enemy_index]

	if !is_instance_valid(beastmaster_node):
		push_error("Beast Master Enemy3D node is invalid.")

		finish_failed_beastmaster_transition()
		return

	beastmaster_enemy["downed"] = false
	beastmaster_enemy["phase_two_started"] = true

	add_combat_log_entry(
		"The Beast Master called his pack."
	)

	await reset_all_dice_assignments_for_phase_transition()

	request_music_fade_out.emit()

	var focus_succeeded: bool = await cinematic_beastmaster_focus(
		beastmaster_node
	)

	if !focus_succeeded:
		push_warning(
			"Beast Master camera focus failed. "
			+ "Continuing the phase transition."
		)

	var sprite: AnimatedSprite3D = beastmaster_node.sprite

	if (
		sprite != null
		and sprite.sprite_frames.has_animation("cutscene")
	):
		sprite.play("cutscene")

		if beastmaster_pant_sound != null:
			AudioManager.play_one_shot(
				beastmaster_pant_sound
			)

		if beastmaster_wind_sound != null:
			AudioManager.play_one_shot(
				beastmaster_wind_sound
			)

		await wait_until_sprite_frame(
			sprite,
			32,
			3.0
		)

		if beastmaster_inhale_sound != null:
			AudioManager.play_one_shot(
				beastmaster_inhale_sound
			)

		await wait_until_sprite_frame(
			sprite,
			38,
			3.0
		)

		if beastmaster_horn_sound != null:
			AudioManager.play_one_shot(
				beastmaster_horn_sound
			)

		await shatter_camera_shake(
			combat_camera,
			0.35,
			0.28
		)

		await wait_for_sprite_animation(
			sprite,
			4.0
		)
	else:
		push_warning(
			"Beast Master has no cutscene animation. "
			+ "Skipping directly to Phase Two."
		)

	await get_tree().create_timer(0.25).timeout

	# Phase 1 is finished. Main.gd will load the separate
	# Phase 2 world and encounter.
	beastmaster_phase = 2
	beastmaster_phase_two_requested.emit()

func start_beastmaster_phase_two():
	beastmaster_phase = 2
	combat_over = false
	is_resolving_turn = false
	beastmaster_transition_running = false

	active_enemies.clear()
	defeated_enemies.clear()
	enemy_3d_nodes.clear()

	selected_enemy_index = -1
	selected_dice_order.clear()
	assigned_enemy_containers.clear()

	player_block = 0
	dodge_targets.clear()
	reversal_targets.clear()
	break_focus_targets.clear()
	mulligem_used_this_turn = false

	for enemy_data in current_encounter.enemies:
		if enemy_data == null:
			continue

		active_enemies.append(
			create_enemy_instance(enemy_data)
		)

	spawn_enemy_3d_nodes()
	refresh_enemy_buttons()
	update_enemy_3d_nodes()

	await clear_all_combat_dice_state()

	# Keep combat controls hidden until the new world fades in.
	set_combat_ui_enabled(false)

	update_player_hp_label()
	update_player_block_label()
	update_player_status_icons()

func finish_failed_beastmaster_transition():
	is_resolving_turn = false
	end_round_button.disabled = false
	beastmaster_transition_running = false

	set_combat_ui_enabled(true)

	update_mulligem_button()
	update_begin_expedition_button_visibility()
	
func begin_beastmaster_phase_two_combat():
	# start_new_combat() already spawned and rolled the player's dice.
	# This function only finishes Phase 2-specific initialization.

	set_combat_ui_enabled(true)

	roll_enemy_intents()
	refresh_enemy_buttons()
	update_enemy_3d_nodes()
	update_player_3d_node()

	mulligem_used_this_turn = false
	is_resolving_turn = false
	beastmaster_transition_running = false
	end_round_button.disabled = false

	update_mulligem_button()
	update_player_hp_label()
	update_player_block_label()
	update_player_status_icons()
	update_begin_expedition_button_visibility()

	add_combat_log_entry(
		"Beast Master Phase Two began."
	)
	
func clear_all_enemy_3d_nodes():
	for enemy_node in enemy_3d_nodes:
		if !is_instance_valid(enemy_node):
			continue

		enemy_node.queue_free()

	enemy_3d_nodes.clear()

	# Allow queued nodes to leave the scene tree before rebuilding.
	await get_tree().process_frame
	await get_tree().process_frame
	
func cinematic_beastmaster_focus(
	enemy_node: Node3D
) -> bool:
	var camera: Camera3D = combat_camera

	if camera == null:
		camera = get_viewport().get_camera_3d()

	if camera == null:
		push_error(
			"Beast Master cutscene could not find a camera."
		)

		return false

	if enemy_node == null or !is_instance_valid(enemy_node):
		push_error(
			"Beast Master cutscene received an invalid enemy node."
		)

		return false

	if !combat_camera_home_saved:
		capture_combat_camera_home()

	if !combat_camera_home_saved:
		return false

	beastmaster_camera_original_transform = (
		combat_camera_home_transform
	)

	beastmaster_camera_original_size = (
		combat_camera_home_size
	)

	camera.current = true

	var zoom_size: float = max(
		beastmaster_camera_original_size * 0.65,
		0.1
	)

	var direction_to_enemy: Vector3 = (
		enemy_node.global_position
		- camera.global_position
	).normalized()

	var target_transform: Transform3D = (
		camera.global_transform
	)

	target_transform.origin = (
		camera.global_position
		+ direction_to_enemy * 1.4
	)

	var tween := create_tween()

	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_parallel(true)

	tween.tween_property(
		camera,
		"global_transform",
		target_transform,
		0.35
	)

	tween.tween_property(
		camera,
		"size",
		zoom_size,
		0.35
	)

	await tween.finished

	return true
	
func capture_combat_camera_home():
	var camera: Camera3D = combat_camera

	if camera == null:
		camera = get_viewport().get_camera_3d()

	if camera == null:
		push_error("Could not capture combat camera.")
		return

	combat_camera = camera

	combat_camera_home_transform = camera.global_transform
	combat_camera_home_size = camera.size
	combat_camera_home_saved = true

	print(
		"Captured combat camera home: ",
		combat_camera_home_transform.origin
	)
	
func restore_beastmaster_camera():
	var camera: Camera3D = combat_camera

	if camera == null:
		camera = get_viewport().get_camera_3d()

	if camera == null:
		push_error(
			"Could not restore the Beast Master camera."
		)

		return

	camera.current = true

	var tween := create_tween()

	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_parallel(true)

	tween.tween_property(
		camera,
		"global_transform",
		beastmaster_camera_original_transform,
		0.35
	)

	tween.tween_property(
		camera,
		"size",
		beastmaster_camera_original_size,
		0.35
	)

	await tween.finished

	camera.global_transform = (
		beastmaster_camera_original_transform
	)

	camera.size = beastmaster_camera_original_size
	camera.current = true
	
func wait_until_sprite_frame(
	sprite: AnimatedSprite3D,
	target_frame: int,
	timeout_seconds: float = 3.0
):
	if sprite == null or !is_instance_valid(sprite):
		return

	var elapsed: float = 0.0

	while (
		is_instance_valid(sprite)
		and sprite.is_playing()
		and sprite.animation == "cutscene"
		and sprite.frame < target_frame
		and elapsed < timeout_seconds
	):
		await get_tree().process_frame
		elapsed += get_process_delta_time()

	if elapsed >= timeout_seconds:
		push_warning(
			"Timed out waiting for Beast Master cutscene frame "
			+ str(target_frame)
			+ "."
		)

func wait_for_sprite_animation(
	sprite: AnimatedSprite3D,
	timeout_seconds: float = 4.0
):
	if sprite == null or !is_instance_valid(sprite):
		return

	var elapsed: float = 0.0

	while (
		is_instance_valid(sprite)
		and sprite.is_playing()
		and elapsed < timeout_seconds
	):
		await get_tree().process_frame
		elapsed += get_process_delta_time()

	if elapsed >= timeout_seconds:
		push_warning(
			"Beast Master cutscene animation timed out."
		)

		if is_instance_valid(sprite):
			sprite.stop()
			
func cinematic_beastmaster_zoom_out():
	var camera: Camera3D = combat_camera

	if camera == null:
		camera = get_viewport().get_camera_3d()

	if camera == null:
		push_error(
			"Could not restore the Beast Master camera."
		)

		return

	camera.current = true

	var tween := create_tween()

	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_parallel(true)

	tween.tween_property(
		camera,
		"global_transform",
		beastmaster_camera_original_transform,
		0.55
	)

	tween.tween_property(
		camera,
		"size",
		beastmaster_camera_original_size,
		0.55
	)

	await tween.finished

	camera.global_transform = (
		beastmaster_camera_original_transform
	)

	camera.size = beastmaster_camera_original_size
	camera.current = true
	
func spawn_beastmaster_phase2_pack(
	beastmaster_index: int
) -> bool:
	if (
		beastmaster_index < 0
		or beastmaster_index >= active_enemies.size()
	):
		push_error(
			"Invalid Beast Master index: "
			+ str(beastmaster_index)
		)
		return false

	if beastmaster_exvellus_enemy == null:
		push_error("Exvellus is not assigned.")
		return false

	if beastmaster_nigel_enemy == null:
		push_error("Nigel is not assigned.")
		return false

	if beastmaster_noir_enemy == null:
		push_error("Noir is not assigned.")
		return false

	if beastmaster_phase2_support_die == null:
		push_error("Beast Master support die is not assigned.")
		return false

	var beastmaster_enemy: Dictionary = (
		active_enemies[beastmaster_index]
	)

	beastmaster_enemy["downed"] = false
	beastmaster_enemy["phase_two_started"] = true
	beastmaster_enemy["phase_two_support_die"] = (
		beastmaster_phase2_support_die
	)

	beastmaster_enemy["attack"] = 0
	beastmaster_enemy["crit"] = 0
	beastmaster_enemy["block"] = 0
	beastmaster_enemy["heal"] = 0
	beastmaster_enemy["rolled_faces"] = []
	beastmaster_enemy["roll_text"] = "Recovering"

	var exvellus: Dictionary = create_enemy_instance(
		beastmaster_exvellus_enemy
	)

	var nigel: Dictionary = create_enemy_instance(
		beastmaster_nigel_enemy
	)

	var noir: Dictionary = create_enemy_instance(
		beastmaster_noir_enemy
	)

	if exvellus.is_empty():
		push_error(
			"Failed to create the Phase Two Exvellus instance."
		)
		return false

	if nigel.is_empty():
		push_error(
			"Failed to create the Phase Two Nigel instance."
		)
		return false

	if noir.is_empty():
		push_error(
			"Failed to create the Phase Two Noir instance."
		)
		return false

	active_enemies.clear()

	active_enemies.append(exvellus)
	active_enemies.append(nigel)
	active_enemies.append(beastmaster_enemy)
	active_enemies.append(noir)

	print("Phase-two roster built:")

	for i in active_enemies.size():
		print(
			i,
			": ",
			active_enemies[i]["data"].enemy_name
		)

	return active_enemies.size() == 4
	
func reset_all_dice_assignments_for_phase_transition():
	selected_dice_order.clear()
	selected_enemy_index = -1

	for die in dice_nodes:
		if !is_instance_valid(die):
			continue

		die.assigned_enemy_index = -1
		die.selected = false
		die.reserved = false
		die.visible = true

		die.set_compact_mode(false)
		die.update_visual()

		if die.get_parent() != rolling_hidden_area:
			die.reparent(rolling_hidden_area)

	for child in assigned_dice_overlay.get_children():
		child.queue_free()

	assigned_enemy_containers.clear()

	await get_tree().process_frame

	regroup_dice()
	calculate_auto_block()
	update_reserve_slots_display()
	update_group_visibility()
	update_assigned_panel_visibility()
	
func clear_enemy_3d_nodes_immediately():
	for enemy_node in enemy_3d_nodes:
		if is_instance_valid(enemy_node):
			enemy_node.queue_free()

	enemy_3d_nodes.clear()

	# Allow the queued phase-one nodes to actually leave the tree
	# before adding the phase-two nodes to the same positions.
	await get_tree().process_frame
	
func clear_assigned_dice_ui():
	rescue_assigned_dice()

	for child in assigned_dice_overlay.get_children():
		child.queue_free()

	assigned_enemy_containers.clear()
	update_assigned_panel_visibility()

func open_dice_bag_read_only():
	print("Dice Bag button clicked")

	dice_panel_read_only = true
	edit_dice_panel.z_index = 100
	edit_dice_panel.move_to_front()
	edit_dice_return_context = "dice_bag"
	edit_dice_title_label.text = "Dice Bag"
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

	edit_dice_panel.visible = true
	shop_panel.visible = false
	
	refresh_edit_dice_panel()
	assigned_dice_overlay.visible = false
	apply_volatile_core_button.visible = false
	die_crafting_panel.visible = false
	sell_face_panel.visible = false
	inventory_faces_container.get_parent().get_parent().visible = false

	edit_warning_label.text = "Dice Bag - View your dice."
	close_edit_button.text = "Close"
	
func close_dice_bag():
	dice_bag_panel.visible = false
	assigned_dice_overlay.visible = true
	if edit_dice_return_context == "dice_bag":
		edit_dice_panel.visible = false
		edit_dice_return_context = ""
		reset_edit_panel_to_normal_mode()
		assigned_dice_overlay.visible = true
		edit_dice_title_label.text = "Edit Faces"
		return
func populate_dice_bag():
	print("Owned dice:", owned_dice.size())
	for child in dice_bag_list.get_children():
		child.queue_free()

	for die in owned_dice:
		print("Adding", die.die_name)
		var die_box := VBoxContainer.new()
		die_box.add_theme_constant_override("separation", 4)

		var title := Label.new()
		title.text = die.die_name + "  D" + str(die.sides)

		if !die.editable:
			title.text += "  [Cursed]"

		die_box.add_child(title)

		var face_row := HBoxContainer.new()
		face_row.add_theme_constant_override("separation", 6)
		print("Children:", dice_bag_list.get_child_count())
		for face in die.faces:
			var face_box := VBoxContainer.new()
			face_box.custom_minimum_size = Vector2(56, 70)

			var icon := TextureRect.new()
			icon.texture = face.icon
			icon.custom_minimum_size = Vector2(40, 40)
			icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.tooltip_text = get_face_tooltip_text(
				face,
				die
			)

			var value := Label.new()
			value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			value.text = str(face.value) if face.value > 0 else ""

			face_box.add_child(icon)
			face_box.add_child(value)
			face_row.add_child(face_box)

		die_box.add_child(face_row)

		var separator := HSeparator.new()
		die_box.add_child(separator)
		
		dice_bag_list.add_child(die_box)
		await get_tree().process_frame
		dice_bag_list.queue_sort()
		
func get_face_tooltip_text(
	face: DiceFace,
	die_data: DiceData = null
) -> String:
	if face == null:
		return ""

	return face.get_tooltip(die_data)

func reset_edit_panel_to_normal_mode():
	dice_panel_read_only = false

	apply_volatile_core_button.visible = true
	die_crafting_panel.visible = true
	sell_face_panel.visible = true
	inventory_faces_container.get_parent().get_parent().visible = true

	edit_warning_label.text = ""
	close_edit_button.text = "Close"
	
func _on_discord_button_pressed():
	OS.shell_open("https://discord.gg/vrhvAe5GPa")
	
func open_steam_store_page():
	var error: Error = OS.shell_open(
		STEAM_STORE_URL
	)

	if error != OK:
		push_warning(
			"Could not open the Steam store page. Error: "
			+ str(error)
		)
func show_relic_acquisition(relic: RelicData):
	if relic == null:
		return

	relic_reward_pending = relic
	relic_reward_acknowledged = false

	relic_reward_icon.texture = relic.icon
	relic_reward_name_label.text = relic.relic_name
	relic_reward_description_label.text = relic.description

	relic_reward_overlay.visible = true
	relic_reward_overlay.modulate.a = 0.0

	relic_reward_icon.scale = Vector2(0.25, 0.25)
	relic_reward_icon.modulate.a = 0.0

	relic_reward_glow.scale = Vector2(0.4, 0.4)
	relic_reward_glow.modulate.a = 0.0
	relic_reward_glow.rotation = 0.0

	relic_reward_continue_button.disabled = true

	var tween := create_tween()
	tween.set_parallel(true)

	tween.tween_property(
		relic_reward_overlay,
		"modulate:a",
		1.0,
		0.25
	)

	tween.tween_property(
		relic_reward_icon,
		"scale",
		Vector2.ONE,
		0.45
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	tween.tween_property(
		relic_reward_icon,
		"modulate:a",
		1.0,
		0.25
	)

	tween.tween_property(
		relic_reward_glow,
		"scale",
		Vector2.ONE,
		0.55
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	tween.tween_property(
		relic_reward_glow,
		"modulate:a",
		0.85,
		0.35
	)

	tween.tween_property(
		relic_reward_glow,
		"rotation",
		0.35,
		1.2
	)

	await tween.finished

	relic_reward_continue_button.disabled = false

	# Start the pulse without blocking this function.
	_pulse_relic_glow()

	# Wait immediately so the Continue signal cannot be missed.
	await relic_reward_finished
	
func _pulse_relic_glow():
	while relic_reward_overlay.visible:
		var pulse := create_tween()
		pulse.set_parallel(true)

		pulse.tween_property(
			relic_reward_glow,
			"scale",
			Vector2(1.08, 1.08),
			0.7
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

		pulse.tween_property(
			relic_reward_glow,
			"modulate:a",
			0.55,
			0.7
		)

		await pulse.finished

		if !relic_reward_overlay.visible:
			break

		var reverse := create_tween()
		reverse.set_parallel(true)

		reverse.tween_property(
			relic_reward_glow,
			"scale",
			Vector2.ONE,
			0.7
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

		reverse.tween_property(
			relic_reward_glow,
			"modulate:a",
			0.85,
			0.7
		)

		await reverse.finished

func _on_relic_reward_continue_pressed():
	if relic_reward_acknowledged:
		return

	relic_reward_acknowledged = true
	relic_reward_continue_button.disabled = true

	await animate_relic_reward_to_active_area()

	relic_reward_overlay.visible = false
	relic_reward_pending = null

	relic_reward_finished.emit()
	
func animate_relic_reward_to_active_area():
	if relic_reward_pending == null:
		return

	var target: Control = active_food_container

	if target == null:
		return

	var flying_icon := TextureRect.new()
	flying_icon.texture = relic_reward_pending.icon
	flying_icon.size = Vector2(160, 160)
	flying_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	flying_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	flying_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flying_icon.z_index = 1000

	add_child(flying_icon)

	var start_position := relic_reward_icon.global_position
	flying_icon.global_position = start_position
	flying_icon.scale = Vector2.ONE

	update_active_food_icons()
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
		Vector2(0.22, 0.22),
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

func toggle_combat_log():
	combat_log_panel.visible = !combat_log_panel.visible

	if combat_log_panel.visible:
		refresh_combat_log()
		
func add_colored_combat_log_entry(text: String, color: Color):
	var color_hex := color.to_html(false)
	combat_log_entries.append("[color=#" + color_hex + "]" + text + "[/color]")
	refresh_combat_log()

func play_fireball_cinematic(
	die: DiceNode,
	enemy_index: int
):
	if die == null or !is_instance_valid(die):
		return

	if enemy_index < 0 or enemy_index >= enemy_3d_nodes.size():
		return

	var enemy_node: Enemy3D = enemy_3d_nodes[enemy_index]

	if enemy_node == null or !is_instance_valid(enemy_node):
		return

	var camera: Camera3D = combat_camera

	if camera == null:
		camera = get_viewport().get_camera_3d()

	if camera == null:
		return

	var original_transform: Transform3D = camera.global_transform
	var original_size: float = camera.size

	var cinematic_die: DiceNode = dice_scene.instantiate()
	add_child(cinematic_die)

	cinematic_die.setup(die.dice_data)
	cinematic_die.current_face_index = die.current_face_index
	cinematic_die.current_face = die.current_face
	cinematic_die.used = true
	cinematic_die.selected = false
	cinematic_die.reserved = false
	cinematic_die.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cinematic_die.z_index = 1900

	cinematic_die.set_compact_mode(false)
	cinematic_die.update_visual()

	var viewport_size: Vector2 = get_viewport_rect().size
	var viewport_center: Vector2 = viewport_size * 0.5

	cinematic_die.pivot_offset = cinematic_die.size * 0.5
	cinematic_die.global_position = (
		die.global_position
		+ die.size * 0.5
		- cinematic_die.size * 0.5
	)

	cinematic_die.scale = Vector2(0.75, 0.75)
	cinematic_die.modulate.a = 1.0

	if fireball_sound != null:
		AudioManager.play_one_shot(
			fireball_sound,
			1.0,
			1.0
		)

	# ---------------------------------------------------------
	# 0.00–0.18: quick zoom onto the Fireball die.
	# ---------------------------------------------------------
	var die_zoom := create_tween()
	die_zoom.set_parallel(true)

	die_zoom.tween_property(
		cinematic_die,
		"global_position",
		viewport_center - cinematic_die.size * 0.5,
		0.18
	).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)

	die_zoom.tween_property(
		cinematic_die,
		"scale",
		Vector2(2.0, 2.0),
		0.18
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	await die_zoom.finished

	# ---------------------------------------------------------
	# 0.18–0.62: dramatic hold with a small slow-motion pulse.
	# ---------------------------------------------------------
	var hold_tween := create_tween()
	hold_tween.set_parallel(true)

	hold_tween.tween_property(
		cinematic_die,
		"scale",
		Vector2(2.18, 2.18),
		0.44
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	hold_tween.tween_property(
		cinematic_die,
		"rotation",
		0.10,
		0.22
	).set_trans(Tween.TRANS_SINE)

	await hold_tween.finished

	# ---------------------------------------------------------
	# 0.62–0.76: snap the die away.
	# ---------------------------------------------------------
	var die_exit := create_tween()
	die_exit.set_parallel(true)

	die_exit.tween_property(
		cinematic_die,
		"scale",
		Vector2(0.25, 0.25),
		0.14
	).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)

	die_exit.tween_property(
		cinematic_die,
		"modulate:a",
		0.0,
		0.14
	)

	await die_exit.finished

	if is_instance_valid(cinematic_die):
		cinematic_die.queue_free()

	# ---------------------------------------------------------
	# 0.76–1.00: rapid camera push toward the target.
	# ---------------------------------------------------------
	var direction_to_enemy: Vector3 = (
		enemy_node.global_position - camera.global_position
	).normalized()

	var impact_transform: Transform3D = camera.global_transform
	impact_transform.origin += direction_to_enemy * 1.0

	var impact_size: float = max(
		original_size * 0.72,
		0.1
	)

	var target_zoom := create_tween()
	target_zoom.set_parallel(true)

	target_zoom.tween_property(
		camera,
		"global_transform",
		impact_transform,
		0.24
	).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)

	target_zoom.tween_property(
		camera,
		"size",
		impact_size,
		0.24
	).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)

	await target_zoom.finished

	# ---------------------------------------------------------
	# 1.00: flash exactly when the audio explosion occurs.
	# ---------------------------------------------------------
	if fireball_flash != null:
		fireball_flash.visible = true
		fireball_flash.modulate.a = 0.9

		var flash_tween := create_tween()

		flash_tween.tween_property(
			fireball_flash,
			"modulate:a",
			0.0,
			0.12
		)

		await flash_tween.finished

		fireball_flash.visible = false
		fireball_flash.modulate.a = 0.0

	# Restore the camera quickly after impact.
	var restore_tween := create_tween()
	restore_tween.set_parallel(true)

	restore_tween.tween_property(
		camera,
		"global_transform",
		original_transform,
		0.16
	).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)

	restore_tween.tween_property(
		camera,
		"size",
		original_size,
		0.16
	).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)

	await restore_tween.finished

	camera.global_transform = original_transform
	camera.size = original_size
	camera.current = true
	
func get_player_berserker_bonus() -> int:
	var value: int = player_statuses.get(
		"berserker",
		0
	)

	if value <= 0:
		return 0

	if player_hp > combat_max_player_hp / 2:
		return 0

	return value

func record_echoable_effect(
	result_type: String,
	value: int,
	source_die: DiceNode,
	target_index: int = -1
):
	last_echoable_effect = {
		"type": result_type,
		"value": value,
		"source_die": source_die,
		"target_index": target_index
	}
	
