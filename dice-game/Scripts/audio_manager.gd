extends Node

var ui_player: AudioStreamPlayer
var dice_player: AudioStreamPlayer
var dice_all_select_player: AudioStreamPlayer

func _ready():
	ui_player = AudioStreamPlayer.new()
	dice_player = AudioStreamPlayer.new()
	dice_all_select_player = AudioStreamPlayer.new()

	add_child(ui_player)
	add_child(dice_player)
	add_child(dice_all_select_player)

func play_ui(sound: AudioStream):
	ui_player.stream = sound
	ui_player.pitch_scale = randf_range(0.98, 1.02)
	ui_player.play()

func play_dice(sound: AudioStream):
	dice_player.stream = sound
	dice_player.pitch_scale = randf_range(0.95, 1.05)
	dice_player.play()

func play_select_all_dice(sound: AudioStream):
	dice_all_select_player.stream = sound
	dice_all_select_player.pitch_scale = randf_range(0.98, 1.02)
	dice_all_select_player.play()

func play_one_shot(sound: AudioStream, min_pitch := 0.95, max_pitch := 1.05):
	if sound == null:
		return

	var player := AudioStreamPlayer.new()
	add_child(player)

	player.stream = sound
	player.pitch_scale = randf_range(min_pitch, max_pitch)
	player.play()

	player.finished.connect(player.queue_free)
